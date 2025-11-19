# Translation Credit Transactions Fix

**Date:** November 8, 2025  
**Status:** ✅ FIXED - Awaiting Database Deployment  
**Severity:** CRITICAL - Blocks all translation operations

## Problem Summary

Translation jobs were failing with TWO database constraint violation errors:

**Error 1:**
```
null value in column "balance_before" of relation "credit_transactions" violates not-null constraint
```

**Error 2 (discovered after fixing Error 1):**
```
new row for relation "credit_transactions" violates check constraint "credit_transactions_type_check"
```

### Root Cause

**Issue 1:** The `credit_transactions` table has NOT NULL constraints on the `balance_before` and `balance_after` columns, but two stored procedures were inserting transaction records without these values:

1. **`complete_translation_job`** - When refunding unused credits after partial or failed translations
2. **`cancel_translation_job`** - When refunding all reserved credits for cancelled jobs

**Issue 2:** The stored procedures were using invalid transaction type values (`'debit'` and `'credit'`) which are not in the allowed enum:

The `credit_transactions` table only allows these type values:
- `'purchase'` - When user buys credits
- `'consumption'` - When credits are actually consumed
- `'refund'` - When credits are returned to user
- `'adjustment'` - Manual adjustments or temporary holds

However, the stored procedures were using:
- `'debit'` for credit reservations
- `'credit'` for credit refunds

Both values violated the check constraint.

## The Fix

### Changes Made

Updated three stored procedures to fix both issues:

#### 1. `create_translation_job` Function

**Before:**
```sql
INSERT INTO credit_transactions (
    user_id, amount, type, description, metadata
) VALUES (
    p_user_id, -v_credit_cost, 'debit',  -- ❌ Invalid type
    'Translation job credit reservation', ...
);
```

**After:**
```sql
INSERT INTO credit_transactions (
    user_id, amount, type, description,
    balance_before, balance_after,  -- ✅ Added
    metadata
) VALUES (
    p_user_id, -v_credit_cost, 'adjustment',  -- ✅ Valid type
    'Translation job credit reservation',
    v_balance_before, v_balance_after,  -- ✅ Added
    ...
);
```

#### 2. `complete_translation_job` Function

**Before:**
```sql
-- Refund unused credits
IF v_credits_to_refund > 0 THEN
    UPDATE user_credits
    SET balance = balance + v_credits_to_refund
    WHERE user_id = v_job.user_id;
    
    -- Log the refund
    INSERT INTO credit_transactions (
        user_id, amount, type, description, metadata
    ) VALUES (
        v_job.user_id, v_credits_to_refund, 'credit',  -- ❌ Invalid type
        'Translation job credit refund', ...
    );
END IF;
```

**After:**
```sql
-- Refund unused credits
IF v_credits_to_refund > 0 THEN
    -- Get balance before refund
    SELECT balance INTO v_balance_before
    FROM user_credits
    WHERE user_id = v_job.user_id;
    
    v_balance_after := v_balance_before + v_credits_to_refund;
    
    UPDATE user_credits
    SET balance = v_balance_after
    WHERE user_id = v_job.user_id;
    
    -- Log the refund
    INSERT INTO credit_transactions (
        user_id, amount, type, description,
        balance_before, balance_after,  -- ✅ Added
        metadata
    ) VALUES (
        v_job.user_id, v_credits_to_refund, 'refund',  -- ✅ Valid type
        'Translation job credit refund',
        v_balance_before, v_balance_after,  -- ✅ Added
        ...
    );
END IF;
```

#### 3. `cancel_translation_job` Function

Same pattern applied:
- Changed transaction type from `'credit'` to `'refund'` ✅
- Added balance tracking with `balance_before` and `balance_after` ✅

### Files Modified

- ✅ `sql/storeproc/server-side/translation_jobs.sql` - Source stored procedure file
- ✅ `sql/all_stored_procedures.sql` - Combined/generated file (regenerated via `combine-storeproc.sh`)

## Deployment Instructions

### CRITICAL: Database must be updated before translations will work

1. **Deploy to Supabase:**
   ```bash
   # Navigate to project root
   cd /Users/nicholsontsang/coding/Cardy
   
   # Apply the updated stored procedures to the database
   psql "$DATABASE_URL" -f sql/all_stored_procedures.sql
   ```

2. **Verify the deployment:**
   ```sql
   -- Check that the functions exist and have the correct signature
   SELECT proname, prosrc 
   FROM pg_proc 
   WHERE proname IN ('complete_translation_job', 'cancel_translation_job');
   ```

3. **Test translation:**
   - Create a translation job in the frontend
   - Verify it completes without errors
   - Check that credit transactions have proper balance tracking

## Impact

### Before Fix
- ❌ All translation jobs failed with constraint violations
- ❌ Error 1: Missing `balance_before` and `balance_after` in refund transactions
- ❌ Error 2: Invalid transaction types `'debit'` and `'credit'`
- ❌ Users couldn't translate cards at all
- ❌ No way to refund credits properly

### After Fix
- ✅ Translation jobs can be created and completed successfully
- ✅ All transaction types use valid values from the enum
- ✅ Credit refunds are properly tracked with balance history
- ✅ All credit transactions now have complete audit trail
- ✅ Balance integrity is maintained throughout job lifecycle

## Technical Details

### Transaction Type Enum

The database enforces valid transaction types through a CHECK constraint:

```sql
CREATE TABLE IF NOT EXISTS credit_transactions (
    ...
    type VARCHAR(20) NOT NULL CHECK (type IN ('purchase', 'consumption', 'refund', 'adjustment')),
    ...
);
```

**Usage:**
- `'purchase'` - User buys credits via Stripe
- `'consumption'` - Credits actually used (logged to `credit_consumptions` table)
- `'refund'` - Credits returned to user's balance
- `'adjustment'` - Manual adjustments or temporary holds (like credit reservations)

### Why Balance Tracking Matters

The `balance_before` and `balance_after` columns are critical for:

1. **Audit Trail** - Complete history of every credit balance change
2. **Reconciliation** - Ability to verify credit calculations are correct
3. **Debugging** - Track down any credit discrepancies
4. **Compliance** - Maintain accurate financial records

### Database Constraint

```sql
CREATE TABLE IF NOT EXISTS credit_transactions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    type VARCHAR(20) NOT NULL CHECK (type IN ('purchase', 'consumption', 'refund', 'adjustment')),
    amount DECIMAL(10, 2) NOT NULL,
    balance_before DECIMAL(10, 2) NOT NULL,  -- ⚠️ NOT NULL constraint
    balance_after DECIMAL(10, 2) NOT NULL,   -- ⚠️ NOT NULL constraint
    ...
);
```

## Prevention

### Future Considerations

1. **Code Review** - Always ensure credit transaction inserts:
   - Include `balance_before` and `balance_after` columns
   - Use valid transaction types from the enum
2. **Testing** - Integration tests should verify:
   - Complete transaction records with all required fields
   - Valid transaction types
   - Balance calculations are correct
3. **Consistency** - All credit operations should follow the same pattern:
   - Fetch current balance
   - Calculate new balance
   - Update user_credits
   - Log transaction with both balances and valid type

### Pattern to Follow

```sql
DECLARE
    v_balance_before DECIMAL(10, 2);
    v_balance_after DECIMAL(10, 2);
BEGIN
    -- 1. Get current balance
    SELECT balance INTO v_balance_before
    FROM user_credits
    WHERE user_id = p_user_id;
    
    -- 2. Calculate new balance
    v_balance_after := v_balance_before + amount_change;
    
    -- 3. Update balance
    UPDATE user_credits
    SET balance = v_balance_after
    WHERE user_id = p_user_id;
    
    -- 4. Log transaction with both balances and valid type
    INSERT INTO credit_transactions (
        user_id,
        amount,
        type,  -- ⚠️ Must be: 'purchase', 'consumption', 'refund', or 'adjustment'
        description,
        balance_before,  -- ⚠️ Required (NOT NULL)
        balance_after,   -- ⚠️ Required (NOT NULL)
        metadata
    ) VALUES (
        p_user_id,
        amount_change,
        'refund',  -- ✅ Use appropriate valid type
        'Description of transaction',
        v_balance_before,
        v_balance_after,
        jsonb_build_object('key', 'value')
    );
END;
```

## Related Documentation

- `BACKGROUND_TRANSLATION_JOBS.md` - Background translation system overview
- `CONCURRENCY_FIX_TRANSLATION_JOBS.md` - Job concurrency handling
- `sql/schema.sql` - Database schema including credit_transactions table
- `sql/storeproc/server-side/translation_jobs.sql` - Source stored procedures

## Checklist

- ✅ Identified root causes (2 constraint violations)
- ✅ Updated `create_translation_job` function (changed 'debit' to 'adjustment')
- ✅ Updated `complete_translation_job` function (added balance tracking, changed 'credit' to 'refund')
- ✅ Updated `cancel_translation_job` function (added balance tracking, changed 'credit' to 'refund')
- ✅ Regenerated `all_stored_procedures.sql`
- ⏳ Deploy to database (USER ACTION REQUIRED)
- ⏳ Test translation flow
- ⏳ Verify credit transactions have valid types and balance tracking

---

**Next Steps:** Deploy the updated stored procedures to Supabase, then test a translation to confirm the fix works.

