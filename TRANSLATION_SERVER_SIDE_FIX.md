# Translation System Server-Side Fix

## Problem

The translation feature was failing with database errors:

1. **`metadata` column doesn't exist**: `consume_credits()` was trying to INSERT into a non-existent `metadata` column in `credit_consumptions` table.
2. **Wrong stored procedure location**: `store_card_translations()` was in client-side folder but should be server-side since it's called by Edge Functions.

## Root Cause

### Issue 1: Metadata Column
The `credit_consumptions` table schema only has these columns:
```sql
CREATE TABLE credit_consumptions (
    id, user_id, batch_id, card_id, 
    consumption_type, quantity, credits_per_unit, 
    total_credits, description, created_at
);
```

But `consume_credits()` was trying to insert into a `metadata` column that doesn't exist.

### Issue 2: Server-Side vs Client-Side
Edge Functions use **service role** permissions and need stored procedures with:
- `SECURITY DEFINER` clause
- Explicit `p_user_id` parameter (since `auth.uid()` returns NULL with service role)
- `GRANT EXECUTE TO service_role` permission

Client-side procedures rely on `auth.uid()` from the user's JWT token, which doesn't work for Edge Function calls.

## Solution

### 1. Fixed `consume_credits()` Function
**File**: `sql/storeproc/client-side/credit_management.sql`

**Change**: Removed `metadata` from INSERT statement:
```sql
INSERT INTO credit_consumptions (
    user_id, card_id, consumption_type, quantity, 
    credits_per_unit, total_credits, description  -- No metadata
) VALUES (...)
```

**Note**: The `metadata` parameter is still accepted and stored in `credit_transactions` table, which **does** have a metadata column.

### 2. Moved `store_card_translations()` to Server-Side
**From**: `sql/storeproc/client-side/12_translation_management.sql`  
**To**: `sql/storeproc/server-side/translation_management.sql`

**Key Features**:
- Accepts explicit `p_user_id UUID` parameter
- Uses `SECURITY DEFINER`
- Has `GRANT EXECUTE TO service_role`
- Validates card ownership against `p_user_id`
- Calls other functions with explicit user ID

**Permissions**:
```sql
GRANT EXECUTE ON FUNCTION store_card_translations(UUID, UUID, TEXT[], JSONB, JSONB, DECIMAL) TO service_role;
```

## Files Changed

### Database
- ✅ `sql/storeproc/client-side/credit_management.sql` - Fixed `consume_credits()`
- ✅ `sql/storeproc/server-side/translation_management.sql` - New server-side function
- ✅ `sql/storeproc/client-side/12_translation_management.sql` - Removed duplicate
- ✅ `sql/all_stored_procedures.sql` - Regenerated with fixes
- ✅ `DEPLOY_TRANSLATION_FIX.sql` - Deployment script

### Documentation
- ✅ `CLAUDE.md` - Added client-side vs server-side guidance
- ✅ `TRANSLATION_SERVER_SIDE_FIX.md` - This document

## Architecture: Client-Side vs Server-Side Stored Procedures

### Client-Side (`sql/storeproc/client-side/`)
**Called by**: Frontend JavaScript via `supabase.rpc()`  
**Authentication**: Uses `auth.uid()` from user's JWT token  
**Security**: Row-Level Security (RLS) policies  
**Examples**: `get_card_translation_status`, `delete_card_translation`

```sql
CREATE OR REPLACE FUNCTION get_card_translation_status(p_card_id UUID)
RETURNS JSONB
SECURITY DEFINER AS $$
DECLARE
  v_user_id UUID := auth.uid(); -- Gets from JWT
BEGIN
  -- Verify ownership via RLS or explicit check
  ...
END;
$$ LANGUAGE plpgsql;
```

### Server-Side (`sql/storeproc/server-side/`)
**Called by**: Edge Functions (Deno) with service role  
**Authentication**: Explicit `p_user_id` parameter  
**Security**: `SECURITY DEFINER` + explicit permission grants  
**Examples**: `store_card_translations`, `handle_credit_purchase_success`

```sql
CREATE OR REPLACE FUNCTION store_card_translations(
  p_user_id UUID,  -- EXPLICIT parameter
  p_card_id UUID,
  ...
)
RETURNS JSONB
SECURITY DEFINER AS $$
BEGIN
  -- Verify ownership against p_user_id
  SELECT user_id INTO v_card_owner FROM cards WHERE id = p_card_id;
  IF v_card_owner != p_user_id THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;
  ...
END;
$$ LANGUAGE plpgsql;

-- IMPORTANT: Grant to service_role only
GRANT EXECUTE ON FUNCTION store_card_translations(...) TO service_role;
```

### Edge Function Pattern
```typescript
// 1. Validate JWT token
const authHeader = req.headers.get('Authorization');
const token = authHeader.replace('Bearer ', '');
const { data: { user }, error } = await supabaseAdmin.auth.getUser(token);

// 2. Call server-side stored procedure with explicit user ID
const { data, error } = await supabaseAdmin.rpc('store_card_translations', {
  p_user_id: user.id,  // Explicit parameter
  p_card_id: cardId,
  ...
});
```

## Deployment

### Manual Deployment (Required)
Run this in [Supabase SQL Editor](https://supabase.com/dashboard/project/mzgusshseqxrdrkvamrg/sql):

```sql
-- See DEPLOY_TRANSLATION_FIX.sql for complete script
```

Or execute the entire file:
1. Open `DEPLOY_TRANSLATION_FIX.sql`
2. Copy all contents
3. Paste into Supabase SQL Editor
4. Execute

### Verification
After deployment:
1. Open a card in the dashboard (`/cms/mycards`)
2. Go to **General** tab
3. Scroll to **Multi-Language Support** section
4. Click **Manage Translations**
5. Select a language (e.g., Traditional Chinese)
6. Click **Start Translation**
7. Translation should complete successfully

## Best Practices (Updated)

### When to Use Server-Side Stored Procedures
Use server-side procedures when:
- ✅ Called from Edge Functions (Deno)
- ✅ Need service role permissions
- ✅ Performing privileged operations (credit consumption, payment processing)
- ✅ Bypassing RLS policies with explicit validation

### When to Use Client-Side Stored Procedures
Use client-side procedures when:
- ✅ Called from frontend JavaScript
- ✅ User context from JWT token (`auth.uid()`)
- ✅ RLS policies sufficient for authorization
- ✅ Read-only or user-scoped operations

### Common Pitfalls
❌ **Don't**: Call client-side procedures from Edge Functions  
✅ **Do**: Use server-side procedures with explicit `p_user_id`

❌ **Don't**: Use `auth.uid()` in server-side procedures  
✅ **Do**: Accept and validate explicit `p_user_id` parameter

❌ **Don't**: Forget `GRANT EXECUTE TO service_role`  
✅ **Do**: Always add permission grants for server-side functions

❌ **Don't**: Insert into non-existent columns  
✅ **Do**: Verify table schema before writing INSERT statements

## Status

- [x] Fixed `consume_credits()` (removed metadata column)
- [x] Moved `store_card_translations()` to server-side
- [x] Regenerated `all_stored_procedures.sql`
- [x] Created deployment script
- [x] Updated documentation
- [ ] **Manual deployment required** (user action)

## Next Steps

1. **Deploy database fixes**: Run `DEPLOY_TRANSLATION_FIX.sql` in Supabase SQL Editor
2. **Test translation**: Try translating a card to verify the fix
3. **Monitor**: Check Edge Function logs for any remaining errors

---

**Related Files**:
- `DEPLOY_TRANSLATION_FIX.sql` - Deployment script
- `sql/storeproc/server-side/translation_management.sql` - New server-side function
- `supabase/functions/translate-card-content/index.ts` - Edge Function
- `CLAUDE.md` - Updated best practices section

