# 🔒 Payment Management Functions - Security Analysis

## The Problem

Functions in `sql/storeproc/server-side/05_payment_management.sql` are:
- ❌ In the **server-side** folder
- ❌ But use `auth.uid()` (client-side pattern)
- ❌ Missing `GRANT` statements
- ⚠️ Called by Edge Functions but with **user credentials**

---

## Root Cause Analysis

### How the Edge Function Calls These Functions

**File**: `supabase/functions/create-checkout-session/index.ts`

```typescript
// ❌ ISSUE: Using ANON_KEY + User JWT, NOT service_role!
const supabaseClient = createClient(
  Deno.env.get('SUPABASE_URL') ?? '',
  Deno.env.get('SUPABASE_ANON_KEY') ?? '',  // ← ANON KEY!
  {
    global: {
      headers: { Authorization: req.headers.get('Authorization')! },  // ← User JWT!
    },
  }
);

// This means the RPC calls execute as 'authenticated' role, not 'service_role'!
await supabaseClient.rpc('get_batch_for_checkout', { ... });
```

**What This Means**:
- ✅ `auth.uid()` **WILL work** (returns user ID from JWT)
- ✅ Functions execute as `authenticated` role
- ❌ Functions are in the **wrong folder** (should be client-side)
- ❌ Anyone can call these functions directly from frontend!

---

## Security Implications

### Current State (VULNERABLE):

```sql
-- Function is in server-side/ folder
-- But has NO GRANT statement
-- Uses auth.uid() (client-side pattern)

CREATE OR REPLACE FUNCTION create_batch_checkout_payment(...)
RETURNS UUID LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
    IF v_batch_owner_id != auth.uid() THEN  -- ✅ Works
        RAISE EXCEPTION 'Not authorized';
    END IF;
    -- ...
END;
$$;
-- ❌ NO GRANT STATEMENT!
-- Default PostgreSQL behavior might grant to PUBLIC or authenticated
```

**Attack Vector**:
1. User calls Edge Function → Works ✅
2. **User calls function directly from frontend** → Also works! ❌
3. User bypasses Edge Function logic (Stripe validation, etc.)
4. User creates payments without going through Stripe!

---

## ✅ Solution

### Option 1: Keep Edge Function Pattern (Recommended)

**Keep** functions as client-side (since Edge Function uses user credentials):

1. **Move** `05_payment_management.sql` to `client-side/` folder
2. **Add** proper GRANT statements
3. **Keep** `auth.uid()` (it works correctly)
4. **Rely** on RLS policies + stored procedure validation

```sql
-- sql/storeproc/client-side/05_payment_management.sql

CREATE OR REPLACE FUNCTION create_batch_checkout_payment(
    p_batch_id UUID,
    p_stripe_payment_intent_id TEXT,
    p_stripe_checkout_session_id TEXT,
    p_amount_cents INTEGER,
    p_metadata JSONB DEFAULT '{}'::jsonb
) RETURNS UUID LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_batch_owner_id UUID;
    v_user_id UUID;
BEGIN
    -- Get current user
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    -- Verify batch ownership
    SELECT cb.created_by INTO v_batch_owner_id
    FROM card_batches cb 
    WHERE cb.id = p_batch_id;
    
    IF v_batch_owner_id IS NULL THEN
        RAISE EXCEPTION 'Batch not found';
    END IF;
    
    IF v_batch_owner_id != v_user_id THEN
        RAISE EXCEPTION 'Not authorized';
    END IF;
    
    -- Rest of logic...
END;
$$ LANGUAGE plpgsql;

-- ✅ Grant to authenticated users
GRANT EXECUTE ON FUNCTION create_batch_checkout_payment(UUID, TEXT, TEXT, INTEGER, JSONB) TO authenticated;
```

**Pros**:
- ✅ Simpler - no need to change Edge Function
- ✅ `auth.uid()` works naturally
- ✅ Direct frontend calls are OK (validation still happens)

**Cons**:
- ⚠️ Users can call directly (but validation prevents abuse)

---

### Option 2: True Server-Side Pattern

**Convert** to true server-side (Edge Function uses service_role):

1. **Change** Edge Function to use service_role
2. **Update** functions to accept `p_user_id`
3. **Remove** `auth.uid()` calls
4. **Add** `GRANT TO service_role`

```typescript
// Edge Function - Use service_role
const supabaseAdmin = createClient(
  Deno.env.get('SUPABASE_URL') ?? '',
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',  // ← Service role key
);

// Validate user with JWT first
const token = req.headers.get('Authorization')?.replace('Bearer ', '');
const { data: { user }, error } = await supabaseAdmin.auth.getUser(token);

if (!user) {
  throw new Error('Unauthorized');
}

// Call stored procedure with explicit user ID
await supabaseAdmin.rpc('create_batch_checkout_payment', {
  p_user_id: user.id,  // ← Explicit parameter
  p_batch_id: batchId,
  // ...
});
```

```sql
-- Server-side stored procedure
CREATE OR REPLACE FUNCTION create_batch_checkout_payment(
    p_user_id UUID,  -- ← Explicit parameter
    p_batch_id UUID,
    p_stripe_payment_intent_id TEXT,
    p_stripe_checkout_session_id TEXT,
    p_amount_cents INTEGER,
    p_metadata JSONB DEFAULT '{}'::jsonb
) RETURNS UUID LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
    -- Verify batch ownership against p_user_id
    SELECT cb.created_by INTO v_batch_owner_id
    FROM card_batches cb 
    WHERE cb.id = p_batch_id;
    
    IF v_batch_owner_id != p_user_id THEN  -- ← Use parameter
        RAISE EXCEPTION 'Not authorized';
    END IF;
    
    -- Rest of logic...
END;
$$ LANGUAGE plpgsql;

-- ✅ Grant ONLY to service_role
GRANT EXECUTE ON FUNCTION create_batch_checkout_payment(UUID, UUID, TEXT, TEXT, INTEGER, JSONB) TO service_role;
```

**Pros**:
- ✅ Users **cannot** call directly (only Edge Functions can)
- ✅ More secure isolation
- ✅ Follows true server-side pattern

**Cons**:
- ⚠️ Requires changing Edge Function code
- ⚠️ More complex authentication flow

---

## 📊 Comparison

| Aspect | Option 1: Client-Side | Option 2: True Server-Side |
|--------|----------------------|---------------------------|
| **Functions location** | `client-side/` | `server-side/` |
| **Uses auth.uid()** | ✅ Yes | ❌ No (p_user_id param) |
| **Edge Function key** | Anon key + user JWT | Service role key |
| **Frontend can call** | ✅ Yes (validation blocks abuse) | ❌ No (permission denied) |
| **Code changes needed** | Minimal (move files, add GRANT) | Major (Edge Function + SQL) |
| **Security level** | Good (validation in SQL) | Better (isolation) |

---

## 🎯 Recommendation

**Use Option 1: Client-Side Pattern**

**Reasons**:
1. Edge Function already uses user credentials
2. Less code to change
3. Validation in stored procedures is sufficient
4. Direct calls from frontend are OK (business logic still enforced)
5. Credit system already works this way
6. Consistent with rest of codebase

**Implementation**:
1. Move `05_payment_management.sql` to `client-side/`
2. Add `GRANT TO authenticated` for each function
3. Keep `auth.uid()` as-is (it works correctly)
4. No Edge Function changes needed

---

## 🔒 Security Validation

Even with client-side pattern, security is maintained by:

### 1. **Stored Procedure Validation**
```sql
-- Ownership check
IF v_batch_owner_id != auth.uid() THEN
    RAISE EXCEPTION 'Not authorized';
END IF;

-- Amount validation
IF p_amount_cents != v_expected_amount THEN
    RAISE EXCEPTION 'Amount mismatch';
END IF;

-- Duplicate check
IF EXISTS (SELECT 1 FROM batch_payments WHERE batch_id = p_batch_id) THEN
    RAISE EXCEPTION 'Payment already exists';
END IF;
```

### 2. **Database Constraints**
- Foreign key constraints
- Unique constraints on checkout sessions
- Check constraints on amounts

### 3. **Stripe Validation**
- Edge Function verifies with Stripe
- Webhook confirms actual payment
- Amount verification in multiple places

### 4. **RLS Policies**
- Users can only see their own batches
- Users can only modify their own records

---

## 📋 Action Items

### Immediate (Option 1 - Client-Side)

1. **Move file**:
   ```bash
   mv sql/storeproc/server-side/05_payment_management.sql \
      sql/storeproc/client-side/06_payment_management.sql
   ```

2. **Add GRANT statements** at end of file:
   ```sql
   GRANT EXECUTE ON FUNCTION create_batch_checkout_payment(UUID, TEXT, TEXT, INTEGER, JSONB) TO authenticated;
   GRANT EXECUTE ON FUNCTION get_batch_for_checkout(UUID) TO authenticated;
   GRANT EXECUTE ON FUNCTION get_existing_batch_payment(UUID) TO authenticated;
   GRANT EXECUTE ON FUNCTION confirm_batch_payment_by_session(TEXT, TEXT) TO authenticated;
   GRANT EXECUTE ON FUNCTION create_pending_batch_payment(INTEGER, TEXT, UUID, INTEGER, JSONB, TEXT, TEXT) TO authenticated;
   GRANT EXECUTE ON FUNCTION confirm_pending_batch_payment(TEXT, TEXT) TO authenticated;
   ```

3. **Regenerate combined file**:
   ```bash
   ./scripts/combine-storeproc.sh
   ```

4. **Deploy to database**:
   ```sql
   -- In Supabase SQL Editor
   -- Execute the combined file or just the GRANT statements
   ```

5. **Test**:
   - Test Edge Function flow
   - Test that users can only access their own batches
   - Test amount validation
   - Test duplicate prevention

---

## 🔍 How to Verify

### Test 1: Check GRANT Permissions
```sql
SELECT 
    p.proname,
    array_agg(pr.rolname) AS granted_to
FROM pg_proc p
LEFT JOIN pg_proc_acl a ON p.oid = a.objoid
LEFT JOIN pg_roles pr ON a.grantee = pr.oid
WHERE p.proname LIKE '%batch%payment%'
GROUP BY p.proname;
```

**Expected**: All functions should show `{authenticated}` in granted_to.

### Test 2: Call from Frontend
```typescript
// Should work (if user owns the batch)
const { data, error } = await supabase.rpc('get_batch_for_checkout', {
  p_batch_id: myBatchId
});
```

### Test 3: Call from Edge Function
```typescript
// Should still work (uses user's JWT)
const { data, error } = await supabaseClient.rpc('create_batch_checkout_payment', {
  // ... 
});
```

---

## ✅ Summary

**Current State**:
- ❌ Functions in wrong folder (server-side)
- ❌ Missing GRANT statements
- ❌ Unclear security model

**After Fix**:
- ✅ Functions in correct folder (client-side)
- ✅ Proper GRANT statements
- ✅ Clear security model
- ✅ Validation in stored procedures
- ✅ Works with Edge Functions
- ✅ Protected against abuse

**Security Level**: **Good** (validation-based, consistent with credit system)

---

Ready to implement Option 1? Let me know and I'll generate the fix!

