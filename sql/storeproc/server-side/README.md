# 🔴 Server-Side Stored Procedures

## Overview

This folder contains stored procedures that are called **from Edge Functions using service_role credentials** or **from webhooks** that require privileged database operations.

---

## 🔑 Key Characteristics

### Authentication Pattern
- ✅ Accepts explicit `p_user_id UUID` parameter
- ✅ Called with SERVICE_ROLE_KEY (not user JWT)
- ✅ PostgreSQL executes as `service_role` role
- ✅ Can bypass Row-Level Security (RLS) with SECURITY DEFINER
- ❌ `auth.uid()` returns NULL (no JWT context)

### Security Model
```sql
-- Typical server-side function structure
CREATE OR REPLACE FUNCTION my_server_function(
    p_user_id UUID,  -- ✅ Explicit parameter (REQUIRED!)
    p_card_id UUID,
    ...
)
RETURNS JSONB
SECURITY DEFINER AS $$
DECLARE
    v_card_owner UUID;
BEGIN
    -- Always validate user exists
    IF p_user_id IS NULL THEN
        RAISE EXCEPTION 'User ID required';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM auth.users WHERE id = p_user_id) THEN
        RAISE EXCEPTION 'Invalid user ID';
    END IF;
    
    -- Always verify ownership against parameter
    SELECT user_id INTO v_card_owner FROM cards WHERE id = p_card_id;
    IF v_card_owner != p_user_id THEN
        RAISE EXCEPTION 'Unauthorized: User does not own resource';
    END IF;
    
    -- Your privileged logic here...
END;
$$ LANGUAGE plpgsql;

-- ✅ Grant ONLY to service_role
GRANT EXECUTE ON FUNCTION my_server_function(UUID, UUID, ...) TO service_role;
```

---

## 📂 Files in This Folder

### Payment & Credits
- `credit_purchase_completion.sql` - Stripe webhook credit completion
  - `complete_credit_purchase()` - Process successful credit purchase
  - `refund_credit_purchase()` - Handle credit refunds

### Content Management
- ~~`translation_management.sql`~~ - Removed, translations now saved via direct Supabase updates
  - ~~`store_card_translations()`~~ - Removed, see `backend-server/src/routes/translation.routes.direct.ts`

---

## ✅ When to Use Server-Side

Put functions in this folder when:

1. **Edge Function uses SERVICE_ROLE_KEY**
   ```typescript
   // Edge Function with SERVICE_ROLE
   const supabaseAdmin = createClient(
     SUPABASE_URL,
     SUPABASE_SERVICE_ROLE_KEY  // ← Service role
   );

   // Validate JWT manually
   const token = req.headers.get('Authorization')?.replace('Bearer ', '');
   const { data: { user } } = await supabaseAdmin.auth.getUser(token);

   // Call with explicit user ID
   const { data, error } = await supabaseAdmin.rpc('my_server_function', {
     p_user_id: user.id,  // ← Explicit parameter
     p_card_id: cardId
   });
   ```

2. **Webhook-triggered operations**
   ```typescript
   // Stripe webhook (no user context)
   const { error } = await supabase.rpc('complete_credit_purchase', {
     p_user_id: userId,  // From webhook metadata
     p_stripe_session_id: sessionId,
     ...
   });
   ```

3. **Privileged operations**
   - Credit consumption
   - Payment processing
   - Refund handling
   - Bypassing RLS for legitimate reasons

4. **Function needs full control**
   - Atomic multi-table operations
   - Cross-user operations (admin)
   - System-level operations

---

## ❌ When NOT to Use Server-Side

Don't put functions here when:

1. **Called from frontend with user JWT**
   - → Use `client-side/` folder instead

2. **Edge Function uses ANON_KEY**
   - → Use `client-side/` folder instead

3. **Function uses `auth.uid()`**
   - → Use `client-side/` folder instead

4. **Standard user operations**
   - → Use `client-side/` folder instead

---

## 🔒 Security Checklist

Every server-side function MUST:

- [ ] Accept explicit `p_user_id UUID` parameter (first parameter)
- [ ] Validate `p_user_id` is not NULL
- [ ] Verify user exists in `auth.users` table
- [ ] Validate user authorization against database records
- [ ] Use `SECURITY DEFINER` clause
- [ ] Have `GRANT EXECUTE TO service_role` ONLY
- [ ] Explicitly revoke public/authenticated access if needed
- [ ] Validate all input parameters
- [ ] Use `FOR UPDATE` locks for critical operations
- [ ] Return structured JSONB results
- [ ] Log operations for audit trail

---

## 📝 Template

```sql
-- =====================================================================
-- Function Name
-- =====================================================================
-- Description: What this function does
-- Called by: Edge Function with SERVICE_ROLE_KEY
-- Security: Validates user explicitly, bypasses RLS
-- =====================================================================

CREATE OR REPLACE FUNCTION function_name(
    p_user_id UUID,  -- REQUIRED: Explicit user ID
    p_param1 TYPE,
    p_param2 TYPE
)
RETURNS JSONB
SECURITY DEFINER
SET search_path = public, pg_temp  -- Prevent search_path attacks
AS $$
DECLARE
    v_owner_id UUID;
    v_result JSONB;
BEGIN
    -- 1. Validate user ID
    IF p_user_id IS NULL THEN
        RAISE EXCEPTION 'User ID required';
    END IF;

    -- 2. Verify user exists
    IF NOT EXISTS (SELECT 1 FROM auth.users WHERE id = p_user_id) THEN
        RAISE EXCEPTION 'Invalid user ID: %', p_user_id;
    END IF;

    -- 3. Authorization check (verify against database)
    SELECT user_id INTO v_owner_id
    FROM your_table
    WHERE id = p_param1
    FOR UPDATE;  -- Lock if needed

    IF v_owner_id IS NULL THEN
        RAISE EXCEPTION 'Resource not found';
    END IF;

    IF v_owner_id != p_user_id THEN
        RAISE EXCEPTION 'Unauthorized: User % does not own resource', p_user_id;
    END IF;

    -- 4. Input validation
    IF p_param1 IS NULL OR p_param2 IS NULL THEN
        RAISE EXCEPTION 'Invalid parameters';
    END IF;

    -- 5. Privileged business logic
    -- (Can bypass RLS, access multiple users' data, etc.)
    -- ...

    -- 6. Build result
    v_result := jsonb_build_object(
        'success', true,
        'user_id', p_user_id,
        'data', ...
    );

    RETURN v_result;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Operation failed: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- Grant ONLY to service_role
GRANT EXECUTE ON FUNCTION function_name(UUID, TYPE, TYPE) TO service_role;

-- Explicitly revoke from others (optional but recommended)
REVOKE ALL ON FUNCTION function_name(UUID, TYPE, TYPE) FROM PUBLIC, authenticated, anon;

-- Add documentation
COMMENT ON FUNCTION function_name IS 
    'SERVER-SIDE ONLY: Called by Edge Functions with service_role. Accepts explicit p_user_id.';
```

---

## 🧪 Testing

### Test from Edge Function
```typescript
// In Edge Function
import { createClient } from '@supabase/supabase-js';

const supabaseAdmin = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
);

// Validate user from JWT
const token = req.headers.get('Authorization')?.replace('Bearer ', '');
const { data: { user }, error: authError } = await supabaseAdmin.auth.getUser(token);

if (authError || !user) {
  throw new Error('Unauthorized');
}

// Call function with explicit user ID
const { data, error } = await supabaseAdmin.rpc('function_name', {
  p_user_id: user.id,  // Explicit
  p_param1: 'value1',
  p_param2: 'value2'
});

console.log('Result:', data);
```

### Verify Security
```javascript
// Should fail: Frontend with user JWT
const { data, error } = await supabase.rpc('function_name', {
  p_user_id: userId,
  p_param1: 'value1'
});

// Should get: "permission denied for function function_name"
// Because GRANT is only to service_role, not authenticated
```

---

## 📚 See Also

- `../client-side/README.md` - Client-side pattern guide
- `/FOLDER_STRUCTURE_DECISION.md` - Why separate folders?
- `/CLIENT_VS_SERVER_SIDE_EXPLAINED.md` - Pattern comparison
- `/SERVER_SIDE_SECURITY_GUIDE.md` - Security deep dive
- `/CLAUDE.md` - Project documentation

---

## ⚠️ Common Mistakes

### ❌ DON'T: Use auth.uid()
```sql
-- ❌ WRONG! auth.uid() returns NULL with service_role
CREATE FUNCTION bad_function(p_card_id UUID)
RETURNS JSONB AS $$
DECLARE
    v_user_id UUID := auth.uid();  -- Returns NULL!
```

### ✅ DO: Accept p_user_id parameter
```sql
-- ✅ CORRECT! Explicit parameter
CREATE FUNCTION good_function(
    p_user_id UUID,  -- Explicit parameter
    p_card_id UUID
)
```

### ❌ DON'T: Trust parameter without validation
```sql
-- ❌ INSECURE! No validation
UPDATE credits SET balance = balance + 100 WHERE user_id = p_user_id;
```

### ✅ DO: Validate user and ownership
```sql
-- ✅ SECURE! Validates user exists and owns resource
IF NOT EXISTS (SELECT 1 FROM auth.users WHERE id = p_user_id) THEN
    RAISE EXCEPTION 'Invalid user ID';
END IF;

SELECT user_id INTO v_owner FROM resource WHERE id = p_resource_id;
IF v_owner != p_user_id THEN
    RAISE EXCEPTION 'Unauthorized';
END IF;
```

### ❌ DON'T: Grant to authenticated
```sql
-- ❌ WRONG! Allows frontend to call
GRANT EXECUTE ON FUNCTION server_function(...) TO authenticated;
```

### ✅ DO: Grant ONLY to service_role
```sql
-- ✅ CORRECT! Only Edge Functions can call
GRANT EXECUTE ON FUNCTION server_function(...) TO service_role;
```

---

## 🔐 Security Principles

### Defense in Depth

1. **PostgreSQL Grants** - Primary defense (service_role only)
2. **User ID Validation** - Verify user exists
3. **Authorization Checks** - Verify ownership/permissions
4. **Input Validation** - Validate all parameters
5. **Amount Verification** - For payments, verify amounts
6. **Status Checks** - Prevent duplicate operations
7. **Row Locking** - Prevent race conditions (`FOR UPDATE`)
8. **Audit Logging** - Track all operations

### Example: Multi-Layer Security

```sql
CREATE OR REPLACE FUNCTION complete_purchase(
    p_user_id UUID,
    p_session_id VARCHAR,
    p_amount_cents INTEGER
)
RETURNS JSONB AS $$
BEGIN
    -- Layer 1: GRANT (only service_role can call) ✅
    
    -- Layer 2: User validation
    IF NOT EXISTS (SELECT 1 FROM auth.users WHERE id = p_user_id) THEN
        RAISE EXCEPTION 'Invalid user';  -- ✅
    END IF;
    
    -- Layer 3: Resource locking
    SELECT user_id INTO v_purchase_user
    FROM purchases
    WHERE session_id = p_session_id
    FOR UPDATE;  -- ✅ Prevents race conditions
    
    -- Layer 4: Authorization
    IF v_purchase_user != p_user_id THEN
        RAISE EXCEPTION 'Unauthorized';  -- ✅
    END IF;
    
    -- Layer 5: Amount verification
    IF p_amount_cents != v_expected_amount THEN
        RAISE EXCEPTION 'Amount mismatch';  -- ✅
    END IF;
    
    -- Layer 6: Status check
    IF v_status != 'pending' THEN
        RAISE EXCEPTION 'Already processed';  -- ✅
    END IF;
    
    -- Now safe to proceed...
END;
$$ LANGUAGE plpgsql;
```

---

**Pattern**: Server-Side (Edge Functions/Service Role)  
**Folder**: `sql/storeproc/server-side/`  
**Grant**: `TO service_role`  
**Auth**: `p_user_id UUID` parameter
