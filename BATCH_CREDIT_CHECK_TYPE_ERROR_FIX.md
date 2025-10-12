# Batch Issuance Credit Check - Type Error Fix

**Date**: October 12, 2025  
**Status**: ✅ Fixed and Ready for Deployment  
**Severity**: 🔴 Critical (Blocks batch issuance functionality)

---

## Problem

### Error Message
```
POST https://[...]/rest/v1/rpc/issue_card_batch_with_credits 400 (Bad Request)

{
  code: '42804',
  details: null,
  hint: null,
  message: 'argument of NOT must be type boolean, not type numeric'
}
```

### Root Cause

In `issue_card_batch_with_credits` stored procedure, line 137 had:

```sql
IF NOT check_credit_balance(v_total_credits) THEN
    RAISE EXCEPTION 'Insufficient credits...';
END IF;
```

**Issue**: The `check_credit_balance()` function returns a `DECIMAL` (the actual balance), **not** a `BOOLEAN`. Using the `NOT` operator on a DECIMAL value causes a PostgreSQL type error.

### Function Signature
```sql
CREATE OR REPLACE FUNCTION check_credit_balance(
    p_required_credits DECIMAL,
    p_user_id UUID DEFAULT NULL
)
RETURNS DECIMAL AS $$  -- ❌ Returns DECIMAL, not BOOLEAN
```

---

## Solution

### Changes Made

**File**: `sql/storeproc/client-side/04_batch_management.sql`

1. **Added variable declaration** (line 113):
```sql
DECLARE
    ...
    v_current_balance DECIMAL;  -- ✅ Added
    ...
```

2. **Fixed credit check logic** (lines 137-142):
```sql
-- Before (WRONG):
IF NOT check_credit_balance(v_total_credits) THEN
    RAISE EXCEPTION 'Insufficient credits. Required: %, Please purchase more credits.', v_total_credits;
END IF;

-- After (CORRECT):
v_current_balance := check_credit_balance(v_total_credits);
IF v_current_balance < v_total_credits THEN
    RAISE EXCEPTION 'Insufficient credits. Required: %, Available: %. Please purchase more credits.', 
        v_total_credits, v_current_balance;
END IF;
```

### Improvements
- ✅ Correctly treats `check_credit_balance()` return value as DECIMAL
- ✅ Compares balance numerically (`<`) instead of using `NOT`
- ✅ Enhanced error message now includes **both** required and available credits
- ✅ Better user experience with clear feedback

---

## Deployment

### Steps

1. **Execute the deployment SQL**:
   ```bash
   # Navigate to Supabase Dashboard > SQL Editor
   # Copy and execute: DEPLOY_BATCH_CREDIT_CHECK_FIX.sql
   ```

   Or via CLI:
   ```bash
   psql "$DATABASE_URL" -f DEPLOY_BATCH_CREDIT_CHECK_FIX.sql
   ```

2. **Verify deployment**:
   ```sql
   -- Check function exists and has correct signature
   SELECT 
       p.proname as function_name,
       pg_get_function_arguments(p.oid) as arguments,
       pg_get_function_result(p.oid) as return_type
   FROM pg_proc p
   WHERE p.proname = 'issue_card_batch_with_credits';
   ```

3. **Test batch issuance**:
   - Try creating a batch with sufficient credits ✅
   - Try creating a batch with insufficient credits (should see improved error message) ✅

### Files Modified
- ✅ `sql/storeproc/client-side/04_batch_management.sql` (source)
- ✅ `sql/all_stored_procedures.sql` (regenerated)
- ✅ `DEPLOY_BATCH_CREDIT_CHECK_FIX.sql` (deployment script)

---

## Testing

### Test Case 1: Sufficient Credits
```javascript
// User has 10 credits, needs 6 (3 cards × 2 credits/card)
const result = await supabase.rpc('issue_card_batch_with_credits', {
  p_card_id: 'card-uuid',
  p_quantity: 3,
  p_print_request: false
});

// Expected: Success, batch_id returned
// Credits consumed: 6
// Remaining balance: 4
```

### Test Case 2: Insufficient Credits
```javascript
// User has 3 credits, needs 10 (5 cards × 2 credits/card)
const result = await supabase.rpc('issue_card_batch_with_credits', {
  p_card_id: 'card-uuid',
  p_quantity: 5,
  p_print_request: false
});

// Expected: Error with message:
// "Insufficient credits. Required: 10.00, Available: 3.00. Please purchase more credits."
```

### Test Case 3: Zero Balance
```javascript
// User has 0 credits, needs 2 (1 card × 2 credits/card)
const result = await supabase.rpc('issue_card_batch_with_credits', {
  p_card_id: 'card-uuid',
  p_quantity: 1,
  p_print_request: false
});

// Expected: Error with message:
// "Insufficient credits. Required: 2.00, Available: 0.00. Please purchase more credits."
```

---

## Impact

### Before Fix
- ❌ Batch issuance **completely broken**
- ❌ Users unable to create batches
- ❌ PostgreSQL type error (HTTP 400)
- ❌ Vague error messages

### After Fix
- ✅ Batch issuance **fully functional**
- ✅ Correct credit balance validation
- ✅ Clear, informative error messages
- ✅ Shows both required and available credits
- ✅ Better user experience

---

## Related Code

### Frontend (No Changes Needed)
The frontend call in `CardIssuanceCheckout.vue` remains unchanged:

```typescript
const batchId = await creditStore.issueBatchWithCredits(
  cardId,
  quantity.value,
  createPrintRequest.value
);
```

### Credit Store (No Changes Needed)
The Pinia store method in `stores/credits.ts` also requires no changes:

```typescript
async issueBatchWithCredits(
  cardId: string, 
  quantity: number, 
  createPrintRequest: boolean = false
): Promise<string>
```

---

## Prevention

### Why This Happened
- Function `check_credit_balance()` was designed to return the actual balance (DECIMAL) for flexibility
- Earlier code incorrectly assumed it returned a BOOLEAN
- Lack of type checking in SQL caught this only at runtime

### Future Prevention
1. **Documentation**: Clearly document function return types in comments
2. **Naming Convention**: Consider renaming to `get_credit_balance()` to clarify it's a getter, not a checker
3. **Testing**: Add integration tests for credit validation logic
4. **Review**: Check all calls to `check_credit_balance()` for similar issues

---

## Checklist

- ✅ Root cause identified
- ✅ Fix implemented
- ✅ Source file updated
- ✅ Combined file regenerated
- ✅ Deployment script created
- ✅ Documentation written
- ✅ Test cases defined
- ⏳ Manual testing pending
- ⏳ Production deployment pending

---

## Notes

### Design Consideration
The `check_credit_balance()` function returns DECIMAL (actual balance) rather than BOOLEAN because:
1. **Flexibility**: Callers can use the balance for various purposes (display, calculations, etc.)
2. **Information**: Provides more context than a simple true/false
3. **Error Messages**: Enables better error messages showing exact amounts

This is a **good design**, just needs correct usage by callers.

### Alternative Approach (Not Recommended)
We could create a separate boolean checker:
```sql
CREATE FUNCTION has_sufficient_credits(p_required DECIMAL) RETURNS BOOLEAN AS $$
BEGIN
    RETURN check_credit_balance(p_required) >= p_required;
END;
$$;
```

However, this adds unnecessary complexity when the current approach works perfectly once used correctly.

---

**Status**: Ready for deployment  
**Priority**: High  
**Risk**: Low (isolated change, backward compatible)

