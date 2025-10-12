# 🔍 Edge Function Stored Procedure Audit

**Date**: October 11, 2025  
**Audit**: Which stored procedures are called by Edge Functions and where they're located

---

## 📊 Audit Summary

| Edge Function | API Key | RPC Calls | Location | Status |
|--------------|---------|-----------|----------|--------|
| `stripe-credit-webhook` | SERVICE_ROLE | `complete_credit_purchase`<br>`refund_credit_purchase` | ✅ server-side | ✅ CORRECT |
| `translate-card-content` | SERVICE_ROLE | `check_credit_balance`<br>`store_card_translations` | ⚠️ Mixed | ⚠️ ISSUE |
| `create-credit-checkout-session` | SERVICE_ROLE | `create_credit_purchase_record` | ❌ client-side | ❌ WRONG |
| `handle-credit-purchase-success` | SERVICE_ROLE | `complete_credit_purchase` | ✅ server-side | ✅ CORRECT |

---

## 🔴 Critical Issues Found

### Issue 1: Missing GRANT Statements in `credit_management.sql`

**File**: `sql/storeproc/client-side/credit_management.sql`

**Problem**: No GRANT statements at end of file

**Functions affected**:
- `check_credit_balance()` - Called by `translate-card-content`
- `create_credit_purchase_record()` - Called by `create-credit-checkout-session`
- `consume_credits()` - Called by server-side `store_card_translations()`
- `initialize_user_credits()` - Called internally
- `get_user_credit_stats()` - Called by frontend

**Impact**: Functions may not be executable by intended roles

**Recommended Fix**: Add GRANT statements for dual-use functions:
```sql
-- Dual-use functions (called by both frontend and Edge Functions)
GRANT EXECUTE ON FUNCTION check_credit_balance(DECIMAL, UUID) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION create_credit_purchase_record(VARCHAR, DECIMAL, DECIMAL, JSONB, UUID) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION consume_credits(DECIMAL, UUID, VARCHAR, JSONB) TO authenticated, service_role;

-- Client-only functions
GRANT EXECUTE ON FUNCTION initialize_user_credits() TO authenticated;
GRANT EXECUTE ON FUNCTION get_user_credit_stats() TO authenticated;
```

---

### Issue 2: Dual-Use Pattern (Less Clear)

**Functions using `COALESCE(p_user_id, auth.uid())`**:
- `check_credit_balance()` in client-side
- `create_credit_purchase_record()` in client-side
- `consume_credits()` in client-side

**Pattern**:
```sql
CREATE OR REPLACE FUNCTION check_credit_balance(
    p_required_credits DECIMAL,
    p_user_id UUID DEFAULT NULL  -- ⚠️ Dual-use pattern
)
RETURNS DECIMAL AS $$
DECLARE
    v_user_id UUID;
BEGIN
    -- Use provided user_id or fall back to auth.uid()
    v_user_id := COALESCE(p_user_id, auth.uid());
    -- ...
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

**Pros**:
- ✅ Single function serves both purposes
- ✅ Less code duplication

**Cons**:
- ❌ Folder location doesn't clearly indicate usage
- ❌ Less obvious which security pattern applies
- ❌ Harder to audit (which API key should call this?)
- ❌ Violates our established security model

**Recommendation**: 
Two options:
1. **Keep as-is** but add GRANT to both roles and document clearly
2. **Split into separate functions** following pure client-side/server-side patterns

---

## 📋 Detailed Analysis

### ✅ CORRECT: stripe-credit-webhook

**Edge Function**: `supabase/functions/stripe-credit-webhook/index.ts`
```typescript
const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
const supabase = createClient(supabaseUrl, supabaseServiceKey)
```

**RPC Calls**:
1. `complete_credit_purchase` → `sql/storeproc/server-side/credit_purchase_completion.sql` ✅
2. `refund_credit_purchase` → `sql/storeproc/server-side/credit_purchase_completion.sql` ✅

**Status**: ✅ **CORRECT** - Server-side functions in server-side folder

---

### ⚠️ MIXED: translate-card-content

**Edge Function**: `supabase/functions/translate-card-content/index.ts`
```typescript
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
const supabaseAdmin = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
```

**RPC Calls**:
1. `check_credit_balance` → `sql/storeproc/client-side/credit_management.sql` ⚠️
   - Uses dual-use pattern: `COALESCE(p_user_id, auth.uid())`
   - Called with explicit `p_user_id`
   - **Missing GRANT statement**
   
2. `store_card_translations` → `sql/storeproc/server-side/translation_management.sql` ✅
   - Pure server-side pattern
   - Has proper GRANT TO service_role

**Status**: ⚠️ **MIXED** - One function in wrong location/pattern

---

### ❌ WRONG: create-credit-checkout-session

**Edge Function**: `supabase/functions/create-credit-checkout-session/index.ts`
```typescript
const supabaseAdmin = createClient(
  Deno.env.get('SUPABASE_URL') ?? '',
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? Deno.env.get('SUPABASE_ANON_KEY') ?? '',
)
```

**RPC Calls**:
1. `create_credit_purchase_record` → `sql/storeproc/client-side/credit_management.sql` ❌
   - Uses dual-use pattern: `COALESCE(p_user_id, auth.uid())`
   - Called with explicit `p_user_id` from Edge Function
   - **Missing GRANT statement**
   - Should be in server-side folder OR have proper GRANT

**Status**: ❌ **WRONG** - Server-side Edge Function calling client-side procedure

---

### ✅ CORRECT: handle-credit-purchase-success

**Edge Function**: `supabase/functions/handle-credit-purchase-success/index.ts`
```typescript
const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
const supabase = createClient(supabaseUrl, supabaseServiceKey)
```

**RPC Calls**:
1. `complete_credit_purchase` → `sql/storeproc/server-side/credit_purchase_completion.sql` ✅

**Status**: ✅ **CORRECT** - Server-side function in server-side folder

---

## 🎯 Recommended Actions

### Option 1: Keep Dual-Use Pattern (Simpler)

**Add GRANT statements to `credit_management.sql`**:

```sql
-- =====================================================================
-- GRANT PERMISSIONS
-- =====================================================================
-- These functions support dual-use pattern with COALESCE(p_user_id, auth.uid())
-- Can be called from frontend (auth.uid()) or Edge Functions (explicit p_user_id)

-- Dual-use credit functions
GRANT EXECUTE ON FUNCTION check_credit_balance(DECIMAL, UUID) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION create_credit_purchase_record(VARCHAR, DECIMAL, DECIMAL, JSONB, UUID) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION consume_credits(DECIMAL, UUID, VARCHAR, JSONB) TO authenticated, service_role;

-- Client-only functions
GRANT EXECUTE ON FUNCTION initialize_user_credits() TO authenticated;
GRANT EXECUTE ON FUNCTION get_user_credit_stats() TO authenticated;

-- Add comments to document dual-use pattern
COMMENT ON FUNCTION check_credit_balance IS 
  'DUAL-USE: Can be called from frontend (auth.uid()) or Edge Functions (explicit p_user_id)';
COMMENT ON FUNCTION create_credit_purchase_record IS 
  'DUAL-USE: Can be called from frontend (auth.uid()) or Edge Functions (explicit p_user_id)';
COMMENT ON FUNCTION consume_credits IS 
  'DUAL-USE: Can be called from frontend (auth.uid()) or Edge Functions (explicit p_user_id)';
```

**Pros**:
- ✅ Quick fix (just add GRANTs)
- ✅ No code changes needed
- ✅ Functions already work correctly

**Cons**:
- ⚠️ Violates our folder structure convention
- ⚠️ Less clear security model
- ⚠️ Harder to maintain consistency

---

### Option 2: Split Into Pure Patterns (More Consistent)

**Create pure server-side versions in `server-side/` folder**:

```sql
-- sql/storeproc/server-side/credit_operations.sql

CREATE OR REPLACE FUNCTION check_credit_balance_server(
    p_user_id UUID,
    p_required_credits DECIMAL
)
RETURNS DECIMAL AS $$
-- Pure server-side pattern
-- No auth.uid(), only p_user_id
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION check_credit_balance_server(UUID, DECIMAL) TO service_role;
```

**Update Edge Functions to use new names**.

**Pros**:
- ✅ Clear folder structure
- ✅ Consistent security model
- ✅ Easy to audit

**Cons**:
- ❌ More code (duplicate functions)
- ❌ Requires Edge Function updates
- ❌ More maintenance overhead

---

## 💡 Recommendation

**Choose Option 1**: Keep dual-use pattern with proper GRANT statements

**Rationale**:
1. Functions already work correctly
2. Minimal code changes
3. No Edge Function updates needed
4. Document the pattern clearly
5. Add comprehensive comments

**Update Documentation**:
- Add note in CLAUDE.md about dual-use pattern
- Update `sql/storeproc/client-side/README.md` to explain dual-use functions
- Add comments to functions explaining the pattern

---

## 📝 Deployment Script

```sql
-- =====================================================================
-- DEPLOYMENT: Add GRANT Statements to Credit Management Functions
-- =====================================================================
-- Run in Supabase SQL Editor
-- =====================================================================

-- Dual-use functions (called from frontend AND Edge Functions)
GRANT EXECUTE ON FUNCTION check_credit_balance(DECIMAL, UUID) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION create_credit_purchase_record(VARCHAR, DECIMAL, DECIMAL, JSONB, UUID) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION consume_credits(DECIMAL, UUID, VARCHAR, JSONB) TO authenticated, service_role;

-- Client-only functions
GRANT EXECUTE ON FUNCTION initialize_user_credits() TO authenticated;
GRANT EXECUTE ON FUNCTION get_user_credit_stats() TO authenticated;

-- Add documentation comments
COMMENT ON FUNCTION check_credit_balance(DECIMAL, UUID) IS 
  'DUAL-USE: Accepts optional p_user_id (Edge Functions) or uses auth.uid() (frontend). Granted to both authenticated and service_role.';
  
COMMENT ON FUNCTION create_credit_purchase_record(VARCHAR, DECIMAL, DECIMAL, JSONB, UUID) IS 
  'DUAL-USE: Accepts optional p_user_id (Edge Functions) or uses auth.uid() (frontend). Granted to both authenticated and service_role.';
  
COMMENT ON FUNCTION consume_credits(DECIMAL, UUID, VARCHAR, JSONB) IS 
  'DUAL-USE: Accepts optional p_user_id (Edge Functions) or uses auth.uid() (frontend). Granted to both authenticated and service_role.';

-- Verify grants
SELECT 
    p.proname as function_name,
    array_agg(pr.rolname) as granted_to
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
LEFT JOIN pg_proc_acl_explode(p.proacl) acl ON true
LEFT JOIN pg_roles pr ON acl.grantee = pr.oid
WHERE n.nspname = 'public'
  AND p.proname IN ('check_credit_balance', 'create_credit_purchase_record', 'consume_credits', 'initialize_user_credits', 'get_user_credit_stats')
GROUP BY p.proname
ORDER BY p.proname;

-- Expected results:
-- check_credit_balance: {authenticated, service_role}
-- create_credit_purchase_record: {authenticated, service_role}
-- consume_credits: {authenticated, service_role}
-- initialize_user_credits: {authenticated}
-- get_user_credit_stats: {authenticated}
```

---

## 📊 Summary

**Total Edge Functions Checked**: 4 (plus 4 others with no RPC calls)

**Stored Procedures Called**: 5 unique functions

**Issues Found**: 
- ❌ 3 functions missing GRANT statements
- ⚠️ 2 functions in "wrong" folder (but using dual-use pattern)

**Recommendation**: Add GRANT statements, document dual-use pattern

**Priority**: 🔴 **HIGH** - Missing GRANT statements could cause runtime errors

---

**Next Steps**: 
1. Add GRANT statements to `credit_management.sql`
2. Update CLAUDE.md with dual-use pattern explanation
3. Deploy SQL script
4. Test all Edge Functions

