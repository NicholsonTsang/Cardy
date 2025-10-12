# 🔒 Server-Side Stored Procedure Security Guide

## How to Ensure Server-Side Functions Are Only Callable by Edge Functions

---

## 🎯 The Problem

**Question**: How do we prevent normal users (with JWT tokens) from calling server-side stored procedures that are meant only for Edge Functions?

**Answer**: PostgreSQL's role-based permission system + Supabase's authentication model.

---

## 🔐 Security Mechanisms

### 1. **Supabase Authentication Model**

Supabase uses **two types of API keys**:

| Key Type | Role | Used By | Permissions |
|----------|------|---------|-------------|
| **Anon Key** | `anon` → `authenticated` | Frontend clients (user JWT) | Limited (RLS enforced) |
| **Service Role Key** | `service_role` | Edge Functions (server-side) | Full access (bypasses RLS) |

**Key Insight**: 
- Frontend clients use **anon key** → Execute as `authenticated` role
- Edge Functions use **service role key** → Execute as `service_role` role
- We control which role can execute which functions via `GRANT`

---

### 2. **PostgreSQL GRANT System**

```sql
-- ❌ BAD: Anyone authenticated can call this
GRANT EXECUTE ON FUNCTION my_function() TO authenticated;

-- ✅ GOOD: Only service_role can call this
GRANT EXECUTE ON FUNCTION my_function() TO service_role;

-- ❌ DANGEROUS: Public access
GRANT EXECUTE ON FUNCTION my_function() TO public;
```

**Default Behavior**:
- Functions created with `SECURITY DEFINER` run with creator's privileges
- **BUT** if no `GRANT` is specified, default grants may apply
- PostgreSQL 15+ defaults to `NO GRANT` for new functions (secure)
- PostgreSQL <15 might grant to `PUBLIC` (insecure!)

---

## ✅ Proper Server-Side Function Template

```sql
-- =====================================================================
-- SERVER-SIDE FUNCTION TEMPLATE
-- =====================================================================

-- Step 1: Revoke all default permissions
REVOKE ALL ON FUNCTION my_server_function(UUID, TEXT) FROM PUBLIC;
REVOKE ALL ON FUNCTION my_server_function(UUID, TEXT) FROM authenticated;
REVOKE ALL ON FUNCTION my_server_function(UUID, TEXT) FROM anon;

-- Step 2: Create function with SECURITY DEFINER
CREATE OR REPLACE FUNCTION my_server_function(
    p_user_id UUID,  -- Explicit user ID (required!)
    p_data TEXT
)
RETURNS JSONB
SECURITY DEFINER  -- Runs with creator's privileges
SET search_path = public, pg_temp  -- Prevent search_path attacks
AS $$
DECLARE
    v_result JSONB;
BEGIN
    -- IMPORTANT: Validate all inputs!
    IF p_user_id IS NULL THEN
        RAISE EXCEPTION 'User ID required';
    END IF;

    -- Verify user exists and is authorized
    IF NOT EXISTS (SELECT 1 FROM auth.users WHERE id = p_user_id) THEN
        RAISE EXCEPTION 'Invalid user ID';
    END IF;

    -- Your logic here
    v_result := jsonb_build_object('success', true);
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql;

-- Step 3: Grant ONLY to service_role
GRANT EXECUTE ON FUNCTION my_server_function(UUID, TEXT) TO service_role;

-- Step 4: Document that this is server-side only
COMMENT ON FUNCTION my_server_function IS 
    'SERVER-SIDE ONLY: Called by Edge Functions. Requires service_role permissions.';
```

---

## 🚨 Current Security Issues Found

### Issue #1: Missing GRANT Statements

**File**: `sql/storeproc/server-side/05_payment_management.sql`

**Problem**: No `GRANT` statements at all! Functions might be publicly accessible.

```sql
-- Current (VULNERABLE)
CREATE OR REPLACE FUNCTION create_batch_checkout_payment(...)
RETURNS UUID LANGUAGE plpgsql SECURITY DEFINER AS $$
...
$$;
-- ❌ No GRANT statement!

-- Fixed (SECURE)
CREATE OR REPLACE FUNCTION create_batch_checkout_payment(...)
RETURNS UUID LANGUAGE plpgsql SECURITY DEFINER AS $$
...
$$;
GRANT EXECUTE ON FUNCTION create_batch_checkout_payment(...) TO service_role;
```

### Issue #2: Functions Using auth.uid()

**File**: `sql/storeproc/server-side/05_payment_management.sql`

**Problem**: Server-side functions calling `auth.uid()` which returns NULL for service_role!

```sql
-- Lines 29, 60, 104, 127, 148, 220, 268, 308, 359
IF v_batch_owner_id != auth.uid() THEN
    RAISE EXCEPTION 'Not authorized';
END IF;
```

**Why This Is Wrong**:
- `auth.uid()` returns NULL when called with service_role
- Edge Functions use service_role
- These checks will always fail!

**Fix**:
```sql
-- Before (BROKEN)
CREATE OR REPLACE FUNCTION create_batch_checkout_payment(
    p_batch_id UUID,
    ...
) AS $$
BEGIN
    IF v_batch_owner_id != auth.uid() THEN  -- ❌ Returns NULL!
        RAISE EXCEPTION 'Not authorized';
    END IF;
END;
$$;

-- After (CORRECT)
CREATE OR REPLACE FUNCTION create_batch_checkout_payment(
    p_user_id UUID,  -- ✅ Explicit parameter
    p_batch_id UUID,
    ...
) AS $$
BEGIN
    IF v_batch_owner_id != p_user_id THEN  -- ✅ Validates against DB
        RAISE EXCEPTION 'Not authorized';
    END IF;
END;
$$;
```

---

## 🔍 How to Verify Security

### Method 1: Check GRANT Permissions (SQL)

```sql
-- List all functions and their permissions
SELECT 
    p.proname AS function_name,
    pg_get_function_identity_arguments(p.oid) AS arguments,
    p.prosecdef AS is_security_definer,
    array_agg(DISTINCT pr.rolname) AS granted_to
FROM pg_proc p
LEFT JOIN pg_namespace n ON p.pronamespace = n.oid
LEFT JOIN pg_proc_acl a ON p.oid = a.objoid
LEFT JOIN pg_roles pr ON a.grantee = pr.oid
WHERE n.nspname = 'public'
    AND p.proname IN (
        'store_card_translations',
        'complete_credit_purchase',
        'refund_credit_purchase',
        'create_batch_checkout_payment'
    )
GROUP BY p.oid, p.proname;
```

**Expected Result**:
| Function | Security Definer | Granted To |
|----------|-----------------|------------|
| `store_card_translations` | true | `{service_role}` |
| `complete_credit_purchase` | true | `{service_role}` |
| Payment functions | true | `{service_role}` |

### Method 2: Test with User JWT (Should Fail)

```typescript
// Frontend client (uses anon key)
const { data, error } = await supabase.rpc('store_card_translations', {
  p_user_id: 'some-uuid',
  // ...
});

// Should get error:
// "permission denied for function store_card_translations"
```

### Method 3: Test with Service Role (Should Succeed)

```typescript
// Edge Function (uses service role key)
const supabaseAdmin = createClient(
  SUPABASE_URL,
  SUPABASE_SERVICE_ROLE_KEY  // Service role key
);

const { data, error } = await supabaseAdmin.rpc('store_card_translations', {
  p_user_id: validUserId,
  // ...
});

// Should succeed (with proper validation)
```

---

## ✅ Security Checklist

For **every** server-side stored procedure:

### Required Elements
- [ ] Function name clearly indicates server-side (e.g., prefix with `srv_` or in server-side folder)
- [ ] `SECURITY DEFINER` clause present
- [ ] `SET search_path = public, pg_temp` to prevent attacks
- [ ] Accepts explicit `p_user_id UUID` parameter (NOT using `auth.uid()`)
- [ ] Validates `p_user_id` against database records
- [ ] Validates all other input parameters
- [ ] Uses `FOR UPDATE` locks on critical operations
- [ ] Has proper error handling with meaningful messages
- [ ] Returns structured JSONB with success/error status
- [ ] **CRITICAL**: Has `GRANT EXECUTE TO service_role` (and ONLY service_role)
- [ ] Has `REVOKE ALL FROM PUBLIC, authenticated, anon`
- [ ] Documented with `COMMENT ON FUNCTION` noting it's server-side only

### Anti-Patterns to Avoid
- ❌ Using `auth.uid()` in server-side functions
- ❌ Missing `GRANT` statements (defaults might be insecure)
- ❌ Granting to `authenticated` or `public` roles
- ❌ Using `SECURITY INVOKER` (runs with caller's privileges)
- ❌ Trusting parameters without validation
- ❌ No explicit user ID parameter
- ❌ Missing amount/payment verification

---

## 🔧 Fix for Payment Management Functions

The functions in `05_payment_management.sql` are **incorrectly** in the server-side folder because:
1. They use `auth.uid()` (client-side pattern)
2. They have no `GRANT` statements
3. They're called by Edge Functions but designed for client access

**Decision Needed**:

### Option A: Move to Client-Side (Recommended if called by frontend)
```sql
-- Move to sql/storeproc/client-side/05_payment_management.sql
-- Keep auth.uid()
-- GRANT TO authenticated
```

### Option B: Convert to Server-Side (Recommended if called by Edge Functions)
```sql
-- Keep in sql/storeproc/server-side/05_payment_management.sql
-- Replace auth.uid() with p_user_id parameter
-- GRANT TO service_role ONLY
```

**Which one depends on**: Are these functions called by **frontend JavaScript** or **Edge Functions**?

---

## 📋 Audit Results

| Function | File | Status | Issue |
|----------|------|--------|-------|
| `store_card_translations` | server-side/translation_management.sql | ✅ Secure | Has GRANT TO service_role |
| `complete_credit_purchase` | server-side/credit_purchase_completion.sql | ✅ Secure | Has GRANT TO service_role |
| `refund_credit_purchase` | server-side/credit_purchase_completion.sql | ✅ Secure | Has GRANT TO service_role |
| `create_batch_checkout_payment` | server-side/05_payment_management.sql | ❌ **CRITICAL** | Missing GRANT, uses auth.uid() |
| `get_batch_for_checkout` | server-side/05_payment_management.sql | ❌ **CRITICAL** | Missing GRANT, uses auth.uid() |
| `get_existing_batch_payment` | server-side/05_payment_management.sql | ❌ **CRITICAL** | Missing GRANT, uses auth.uid() |
| `confirm_batch_payment_by_session` | server-side/05_payment_management.sql | ❌ **CRITICAL** | Missing GRANT, uses auth.uid() |
| `create_pending_batch_payment` | server-side/05_payment_management.sql | ❌ **CRITICAL** | Missing GRANT, uses auth.uid() |
| `confirm_pending_batch_payment` | server-side/05_payment_management.sql | ❌ **CRITICAL** | Missing GRANT, uses auth.uid() |

---

## 🚀 Immediate Action Required

### 1. Determine Usage Pattern

Check which functions are called from where:

```bash
# Search Edge Functions
grep -r "create_batch_checkout_payment\|get_batch_for_checkout\|confirm_batch_payment" supabase/functions/

# Search Frontend
grep -r "create_batch_checkout_payment\|get_batch_for_checkout\|confirm_batch_payment" src/
```

### 2. Apply Fixes Based on Usage

**If called by Edge Functions**:
```sql
-- Add explicit p_user_id parameter
-- Replace auth.uid() with p_user_id
-- Add GRANT TO service_role ONLY
```

**If called by Frontend**:
```sql
-- Move to client-side folder
-- Keep auth.uid()
-- Add GRANT TO authenticated
```

---

## 📚 Best Practices Summary

### Server-Side Functions (Edge Functions)
```sql
✅ Explicit p_user_id parameter
✅ Validate against database
✅ SECURITY DEFINER
✅ SET search_path
✅ GRANT TO service_role ONLY
✅ REVOKE FROM PUBLIC, authenticated, anon
❌ Never use auth.uid()
```

### Client-Side Functions (Frontend)
```sql
✅ Use auth.uid() for user context
✅ SECURITY DEFINER (for RLS bypass if needed)
✅ GRANT TO authenticated
✅ Rely on RLS policies where possible
❌ Don't accept p_user_id parameter (security risk!)
```

---

## 🔒 Defense in Depth

Even with proper GRANTs, implement multiple layers:

1. **PostgreSQL Grants** - Primary defense
2. **Input Validation** - Validate all parameters
3. **Authorization Checks** - Verify ownership/permissions
4. **Amount Verification** - Check payment amounts
5. **Status Checks** - Prevent duplicate operations
6. **Row Locking** - Prevent race conditions
7. **Audit Logging** - Track all operations
8. **Error Messages** - Don't leak sensitive info

---

## 📊 Security Matrix

| Who Calls? | API Key | PostgreSQL Role | Can Call Server-Side? | Can Call Client-Side? |
|-----------|---------|----------------|---------------------|---------------------|
| Frontend User | Anon key | `authenticated` | ❌ NO | ✅ YES |
| Edge Function | Service key | `service_role` | ✅ YES | ✅ YES (but shouldn't) |
| Public (unauthenticated) | Anon key | `anon` | ❌ NO | ❌ NO |

---

**Next Steps**:
1. Review `05_payment_management.sql` usage patterns
2. Decide: Move to client-side OR convert to server-side
3. Apply proper GRANT statements
4. Test with both anon key and service role key
5. Deploy fixes

Would you like me to help determine the usage pattern and apply the appropriate fixes?

