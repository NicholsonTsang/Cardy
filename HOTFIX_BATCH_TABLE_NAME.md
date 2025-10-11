# HOTFIX: Batch Table Name Bug

## Issue
The `consume_credits_for_batch()` stored procedure was using the wrong table name:
- ❌ Used: `batches`
- ✅ Should be: `card_batches`

This caused a 404 error when trying to create batches with credits:
```
Error: relation "batches" does not exist
```

## Fix Applied
**File**: `sql/storeproc/client-side/credit_management.sql`

**Line 199**: Changed `UPDATE batches` to `UPDATE card_batches`

## Deployment Required

### Option 1: Deploy via Supabase Dashboard (Recommended)

1. **Navigate to Supabase Dashboard**
   - Go to: https://supabase.com/dashboard/project/mzgusshseqxrdrkvamrg
   - Click: SQL Editor

2. **Execute the Updated Stored Procedures**
   - Open: `sql/all_stored_procedures.sql`
   - Copy the entire file contents
   - Paste into SQL Editor
   - Click "Run"

### Option 2: Deploy via Command Line (If you have direct DB access)

```bash
# Make sure you have the DATABASE_URL set
psql "$DATABASE_URL" -f sql/all_stored_procedures.sql
```

## Verification

After deployment, test the batch creation:

1. Go to any card in your dashboard
2. Click "Issue Batch"
3. Enter a card count (ensure you have enough credits)
4. Click "Create Batch"
5. Batch should be created successfully! ✅

## Files Modified

- ✅ `sql/storeproc/client-side/credit_management.sql` - Fixed table name
- ✅ `sql/all_stored_procedures.sql` - Regenerated with fix

## Status

- [x] Bug identified
- [x] Fix applied to source file
- [x] Combined stored procedures regenerated
- [ ] **Deployed to database** ← YOU ARE HERE
- [ ] Verified in production

## Note

This was a typo in the stored procedure. The table has always been named `card_batches` in the schema, but the `consume_credits_for_batch()` function was incorrectly referencing it as `batches`.

