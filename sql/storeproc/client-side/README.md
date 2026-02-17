# 🔵 Client-Side Stored Procedures

## Overview

This folder contains stored procedures that are called **from the frontend** (Vue.js) or **from Edge Functions using user credentials** (ANON_KEY + JWT).

---

## 🔑 Key Characteristics

### Authentication Pattern
- ✅ Uses `auth.uid()` to get user context from JWT
- ✅ Called with ANON_KEY + User JWT token
- ✅ PostgreSQL executes as `authenticated` role
- ✅ Subject to Row-Level Security (RLS) policies

### Security Model
```sql
-- Typical client-side function structure
CREATE OR REPLACE FUNCTION my_function(p_card_id UUID)
RETURNS JSONB
SECURITY DEFINER AS $$
DECLARE
    v_user_id UUID := auth.uid();  -- ✅ Gets user from JWT
BEGIN
    -- Always check authentication
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;
    
    -- Always verify ownership
    IF NOT EXISTS (
        SELECT 1 FROM cards 
        WHERE id = p_card_id AND user_id = v_user_id
    ) THEN
        RAISE EXCEPTION 'Unauthorized';
    END IF;
    
    -- Your logic here...
END;
$$ LANGUAGE plpgsql;

-- ✅ Grant to authenticated users
GRANT EXECUTE ON FUNCTION my_function(UUID) TO authenticated;
```

---

## 📂 Files in This Folder

### Infrastructure
- `00_logging.sql` - Operation logging

### Core Management
- `01_auth_functions.sql` - User authentication and role management
- `02_card_management.sql` - Card CRUD operations
- `03_content_management.sql` - Content item management
- `03b_content_migration.sql` - Content migration utilities
- `03c_content_pagination.sql` - Content pagination

### Features
- `credit_management.sql` - Credit balance and transactions
- `07_public_access.sql` - Public card viewing (mobile)
- `10_template_library.sql` - Template library management
- `11_admin_functions.sql` - Admin operations
- `12_subscription.sql` - Subscription management
- `12_translation_management.sql` - Translation status and history
- `13_access_tokens.sql` - Access token management
- `admin_credit_management.sql` - Admin credit management

---

## ✅ When to Use Client-Side

Put functions in this folder when:

1. **Called by frontend JavaScript**
   ```javascript
   // Frontend code
   const { data, error } = await supabase.rpc('my_function', {
     p_card_id: cardId
   });
   ```

2. **Edge Function uses user credentials**
   ```typescript
   // Edge Function with ANON_KEY
   const supabaseClient = createClient(
     SUPABASE_URL,
     SUPABASE_ANON_KEY,  // ← User credentials
     {
       global: {
         headers: { Authorization: req.headers.get('Authorization')! }
       }
     }
   );
   ```

3. **Function uses `auth.uid()`**
   - User context is available from JWT
   - No need for explicit `p_user_id` parameter

4. **Standard authorization checks**
   - Ownership validation
   - Role checks
   - RLS policies apply

---

## ❌ When NOT to Use Client-Side

Don't put functions here when:

1. **Edge Function uses SERVICE_ROLE_KEY**
   - → Use `server-side/` folder instead

2. **Function needs to bypass RLS**
   - → Use `server-side/` folder instead

3. **Privileged operations** (credits, payments, webhooks)
   - → Use `server-side/` folder instead

4. **Function accepts `p_user_id` parameter**
   - → Use `server-side/` folder instead

---

## 🔒 Security Checklist

Every client-side function MUST:

- [ ] Check `auth.uid()` is not NULL
- [ ] Validate user ownership of resources
- [ ] Use proper input validation
- [ ] Use `SECURITY DEFINER` clause
- [ ] Have `GRANT EXECUTE TO authenticated`
- [ ] NOT accept `p_user_id` as parameter (security risk!)
- [ ] Have descriptive error messages
- [ ] Return structured JSONB results

---

## 📝 Template

```sql
-- =====================================================================
-- Function Name
-- =====================================================================
-- Description: What this function does
-- Called by: Frontend / Edge Function with user JWT
-- =====================================================================

CREATE OR REPLACE FUNCTION function_name(
    p_param1 TYPE,
    p_param2 TYPE
)
RETURNS JSONB
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_result JSONB;
BEGIN
    -- 1. Authentication check
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    -- 2. Authorization check (ownership, role, etc.)
    IF NOT EXISTS (
        SELECT 1 FROM your_table 
        WHERE id = p_param1 AND user_id = v_user_id
    ) THEN
        RAISE EXCEPTION 'Unauthorized';
    END IF;

    -- 3. Input validation
    IF p_param1 IS NULL OR p_param2 IS NULL THEN
        RAISE EXCEPTION 'Invalid parameters';
    END IF;

    -- 4. Business logic
    -- ...

    -- 5. Build result
    v_result := jsonb_build_object(
        'success', true,
        'data', ...
    );

    RETURN v_result;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Operation failed: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- Grant to authenticated users
GRANT EXECUTE ON FUNCTION function_name(TYPE, TYPE) TO authenticated;

-- Optional: Add comment
COMMENT ON FUNCTION function_name IS 
    'CLIENT-SIDE: Called by frontend with user JWT. Uses auth.uid() for user context.';
```

---

## 🧪 Testing

### Test with User JWT
```javascript
// In browser console or frontend code
const { data, error } = await supabase.rpc('function_name', {
  p_param1: 'value1',
  p_param2: 'value2'
});

console.log('Result:', data);
console.log('Error:', error);
```

### Verify Security
```javascript
// Should fail: Try to access another user's resource
const { data, error } = await supabase.rpc('function_name', {
  p_param1: 'someone_elses_id'
});

// Should get: "Unauthorized" error
```

---

## 📚 See Also

- `../server-side/README.md` - Server-side pattern guide
- `/FOLDER_STRUCTURE_DECISION.md` - Why separate folders?
- `/CLIENT_VS_SERVER_SIDE_EXPLAINED.md` - Pattern comparison
- `/CLAUDE.md` - Project documentation

---

## ⚠️ Common Mistakes

### ❌ DON'T: Accept user_id as parameter
```sql
-- ❌ INSECURE! Allows user impersonation
CREATE FUNCTION bad_function(p_user_id UUID, p_card_id UUID)
-- User can pass ANY user_id!
```

### ✅ DO: Use auth.uid()
```sql
-- ✅ SECURE! Gets user from JWT
CREATE FUNCTION good_function(p_card_id UUID)
RETURNS JSONB AS $$
DECLARE
    v_user_id UUID := auth.uid();  -- From JWT token
```

### ❌ DON'T: Skip ownership checks
```sql
-- ❌ INSECURE! No authorization check
UPDATE cards SET name = p_name WHERE id = p_card_id;
```

### ✅ DO: Always verify ownership
```sql
-- ✅ SECURE! Checks user owns the card
IF NOT EXISTS (
    SELECT 1 FROM cards 
    WHERE id = p_card_id AND user_id = v_user_id
) THEN
    RAISE EXCEPTION 'Unauthorized';
END IF;
```

---

**Pattern**: Client-Side (Frontend/User JWT)  
**Folder**: `sql/storeproc/client-side/`  
**Grant**: `TO authenticated`  
**Auth**: `auth.uid()`
