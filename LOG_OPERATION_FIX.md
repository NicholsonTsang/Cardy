# ✅ Fixed: log_operation Function Call

**Error**: `function log_operation(uuid, unknown, unknown, uuid, jsonb) does not exist`  
**Status**: ✅ **FIXED**  
**Date**: October 11, 2025

---

## 🔴 The Problem

**Error message**:
```
Failed to store translations: function log_operation(uuid, unknown, unknown, uuid, jsonb) does not exist
```

**Root cause**: The `consume_credits()` function was calling `log_operation` with **5 parameters**, but the actual function only accepts **1 parameter**.

**Wrong call** (line 209-220 in credit_management.sql):
```sql
PERFORM log_operation(
    v_user_id,                  -- ❌ Extra parameter
    'credit_consumption',       -- ❌ Extra parameter
    'credit_consumptions',      -- ❌ Extra parameter
    v_consumption_id,           -- ❌ Extra parameter
    jsonb_build_object(...)     -- ❌ Extra parameter
);
```

**Actual function signature** (00_logging.sql):
```sql
CREATE OR REPLACE FUNCTION log_operation(
    p_operation TEXT  -- ✅ Only 1 parameter
) RETURNS VOID ...
```

---

## ✅ The Fix

**File**: `sql/storeproc/client-side/credit_management.sql`

**Before** ❌:
```sql
-- Log operation
PERFORM log_operation(
    v_user_id,
    'credit_consumption',
    'credit_consumptions',
    v_consumption_id,
    jsonb_build_object(
        'consumption_type', p_consumption_type,
        'credits_consumed', p_credits_to_consume,
        'new_balance', v_new_balance,
        'transaction_id', v_transaction_id,
        'metadata', p_metadata
    )
);
```

**After** ✅:
```sql
-- Log operation
PERFORM log_operation(
    format('Credit consumption: %s credits for %s - New balance: %s (Transaction ID: %s)',
        p_credits_to_consume, p_consumption_type, v_new_balance, v_transaction_id)
);
```

---

## 📋 What Changed

1. ✅ Fixed `consume_credits()` function in `credit_management.sql`
2. ✅ Changed from 5-parameter call to 1-parameter call
3. ✅ Formatted all information into a single string
4. ✅ Regenerated `sql/all_stored_procedures.sql`

---

## 🚀 Deployment

**Option 1: Quick Fix (Recommended)**

Just redeploy the entire combined file:

1. Open [Supabase SQL Editor](https://supabase.com/dashboard/project/mzgusshseqxrdrkvamrg/sql)
2. Copy **entire contents** of `sql/all_stored_procedures.sql`
3. Paste and Run ▶️

**Option 2: Incremental Fix**

Run just the `consume_credits` function:
```sql
-- Copy lines 4525-4557 from sql/all_stored_procedures.sql
-- (The consume_credits function definition)
```

---

## 🧪 Testing

After deployment, try the translation feature:

1. Dashboard → Card → General tab → "Manage Translations"
2. Select a language
3. Click "Translate"
4. **Should work without log_operation error** ✅

---

## 📊 All Fixes in This Session

1. ✅ Added missing GRANT statements for 6 credit functions
2. ✅ Fixed wrong function name (`get_user_credit_stats` → `get_credit_statistics`)
3. ✅ Fixed `log_operation` call in `consume_credits()` (this fix)

---

## ✅ Status

**Error**: ✅ Fixed  
**Files**: ✅ Updated (2 files)  
**Deployment**: ⏳ **Ready - deploy sql/all_stored_procedures.sql**

---

**Now deploy and try translation again!** 🚀

