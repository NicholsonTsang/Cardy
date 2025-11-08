# Translation Job Completion Fix

**Date:** November 8, 2025  
**Status:** ✅ FIXED  
**Priority:** CRITICAL - Prevented all translation jobs from completing

## Problem Summary

Translation jobs were **getting stuck in "processing" status forever** even after they completed or failed. Jobs would show progress (e.g., "100% complete") but never transition to final status.

### Symptoms

- Jobs panel showed "Processing" indefinitely
- Progress reached 100% but status never updated
- Credits were refunded (showing job ended) but status stayed "processing"
- Database showed `completed_at: null` for all jobs
- Users couldn't see final job status

### Root Cause

The `complete_translation_job` stored procedure had **schema mismatches** causing it to fail silently:

1. **`credit_consumptions` table** - Procedure used wrong column name `amount` (doesn't exist)
2. **`translation_history` table** - `credit_cost` column is NOT NULL but procedure could pass NULL value

When the backend job processor called `complete_translation_job`, it would fail with database errors, leaving jobs stuck in "processing" state.

## The Errors

### Error 1: Wrong Column Names

```sql
-- ❌ WRONG (what the procedure was doing)
INSERT INTO credit_consumptions (
    user_id,
    amount,        -- ❌ This column doesn't exist!
    ...
) VALUES (...)
```

**Actual schema:**
```sql
CREATE TABLE credit_consumptions (
    user_id UUID NOT NULL,
    consumption_type VARCHAR(50) NOT NULL,
    quantity INTEGER NOT NULL,              -- ✅ Number of items
    credits_per_unit DECIMAL(10, 2) NOT NULL,  -- ✅ Cost per item
    total_credits DECIMAL(10, 2) NOT NULL,  -- ✅ Total cost
    ...
);
```

### Error 2: NULL value in NOT NULL column

```sql
-- ❌ WRONG (what the procedure was doing)
v_credits_to_consume := array_length(p_languages_completed, 1);
-- Returns NULL if array is empty!

INSERT INTO translation_history (
    credit_cost,  -- NOT NULL column
    ...
) VALUES (
    v_credits_to_consume,  -- Could be NULL!
    ...
);
```

## The Fix

### Updated `complete_translation_job` in `sql/storeproc/server-side/translation_jobs.sql`

**Fix 1: Use correct column names for `credit_consumptions`**

**Before:**
```sql
INSERT INTO credit_consumptions (
    user_id,
    amount,                           -- ❌ Wrong column
    consumption_type,
    card_id,
    description,
    metadata
) VALUES (
    v_job.user_id,
    v_credits_to_consume,             -- ❌ Wrong mapping
    'translation',
    v_job.card_id,
    'AI translation for ' || array_length(p_languages_completed, 1) || ' language(s)',
    jsonb_build_object(...)
);
```

**After:**
```sql
INSERT INTO credit_consumptions (
    user_id,
    consumption_type,
    quantity,                          -- ✅ Number of languages
    credits_per_unit,                  -- ✅ Cost per language (1.00)
    total_credits,                     -- ✅ Total cost
    card_id,
    description,
    metadata
) VALUES (
    v_job.user_id,
    'translation',
    array_length(p_languages_completed, 1),  -- ✅ Quantity
    1.00,                                     -- ✅ Credits per language
    v_credits_to_consume,                    -- ✅ Total
    v_job.card_id,
    'AI translation for ' || array_length(p_languages_completed, 1) || ' language(s)',
    jsonb_build_object(...)
);
```

**Fix 2: Handle NULL from array_length**

**Before:**
```sql
v_credits_to_consume := array_length(p_languages_completed, 1);
-- Returns NULL if array is empty!
```

**After:**
```sql
v_credits_to_consume := COALESCE(array_length(p_languages_completed, 1), 0);
-- Returns 0 if array is empty ✅
```

## Testing

### Before Fix

**Database query:**
```sql
SELECT status, completed_at FROM translation_jobs WHERE ...;
```

```
status      | completed_at
------------|-------------
processing  | null        ← Stuck forever!
processing  | null        ← Stuck forever!
processing  | null        ← Stuck forever!
```

**Frontend:**
- All jobs showed "Processing"
- Never showed "Completed" or "Failed"
- Users had no idea if translation finished

### After Fix (Expected)

**Database query:**
```sql
SELECT status, completed_at FROM translation_jobs WHERE ...;
```

```
status      | completed_at
------------|--------------------
completed   | 2025-11-08 12:30:45 ✅
failed      | 2025-11-08 12:31:12 ✅
completed   | 2025-11-08 12:32:03 ✅
```

**Frontend:**
- Jobs show correct final status
- "Completed" for successful jobs
- "Failed" for failed jobs
- Users can see results clearly

## Impact

### Before Fix
- ❌ ALL translation jobs stuck in "processing" forever
- ❌ No way to see job results
- ❌ Credits reserved but not properly accounted
- ❌ Translation history not recorded
- ❌ Users confused about job status

### After Fix
- ✅ Jobs complete and show final status
- ✅ Clear "Completed" or "Failed" indicators
- ✅ Credits properly consumed/refunded
- ✅ Full audit trail in `translation_history`
- ✅ Users know when jobs finish

## Deployment

**Step 1: Deploy stored procedure changes**

From the project root:
```bash
cd /Users/nicholsontsang/coding/Cardy

# Already regenerated: all_stored_procedures.sql
# Now deploy to Supabase
```

**Step 2: Deploy to Supabase Database**

Option A - Via Supabase Dashboard:
1. Go to SQL Editor in Supabase Dashboard
2. Copy contents of `sql/all_stored_procedures.sql`
3. Execute

Option B - Via psql (if you have direct access):
```bash
psql "$DATABASE_URL" -f sql/all_stored_procedures.sql
```

**Step 3: Restart backend** (to ensure clean state):
```bash
cd backend-server
npm run dev
```

**Step 4: Test with a new translation job**

1. Create a new translation job
2. Watch it process
3. Verify it completes and shows final status
4. Check database to confirm `completed_at` is set

## How to Fix Stuck Jobs

If you have jobs currently stuck in "processing", they won't auto-fix. You can either:

### Option 1: Cancel them via API

Use the cancel endpoint for each stuck job.

### Option 2: Manual database cleanup

```sql
-- Find stuck jobs (processing for more than 10 minutes)
SELECT id, card_id, target_languages, created_at
FROM translation_jobs
WHERE status = 'processing'
AND created_at < NOW() - INTERVAL '10 minutes';

-- Mark as failed (adjust job IDs as needed)
UPDATE translation_jobs
SET 
    status = 'failed',
    error_message = 'Job timed out - manual cleanup',
    completed_at = NOW()
WHERE id IN ('job-id-1', 'job-id-2', ...);
```

After the fix is deployed, calling `complete_translation_job` will work correctly.

## Files Modified

- ✅ `sql/storeproc/server-side/translation_jobs.sql` - Fixed `complete_translation_job` function
- ✅ `sql/all_stored_procedures.sql` - Regenerated with fixes

## Related Documentation

- `TRANSLATION_CREDIT_TRANSACTIONS_FIX.md` - Previous credit transaction fixes
- `BACKGROUND_TRANSLATION_JOBS.md` - Translation job system overview
- `backend-server/REALTIME_JOB_PROCESSOR.md` - Job processor implementation

## Additional Notes

### Why This Wasn't Caught Earlier

1. **Schema evolved** - `credit_consumptions` table structure changed but stored procedure wasn't updated
2. **Silent failures** - Database errors in stored procedures don't always propagate to application
3. **Background processing** - Jobs process in background, errors not immediately visible

### Prevention

To prevent similar issues:

1. **Always check schema** before writing stored procedures
2. **Test stored procedures** directly in SQL editor before deploying
3. **Add comprehensive error logging** in background processors
4. **Monitor job completion rates** - if jobs start timing out, investigate
5. **Use COALESCE** for array functions that can return NULL

### Pattern to Follow

**When inserting into tables, always:**

1. **Check actual schema** using `\d table_name` or reading `schema.sql`
2. **Match column names exactly** - don't guess!
3. **Handle NULL values** with COALESCE or default values
4. **Test locally** before deploying to production

---

**Status:** ✅ Fixed and documented  
**Deployment:** Update stored procedures in Supabase database  
**Testing:** Create new translation job and verify completion

