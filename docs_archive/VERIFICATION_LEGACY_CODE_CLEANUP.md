# Verification & Profile Legacy Code Cleanup

**Date**: November 17, 2025  
**Type**: CRITICAL CLEANUP NEEDED  
**Status**: 🔴 INCOMPLETE - Requires manual cleanup

## Problem

The `ProfileStatus` enum error revealed a much larger issue: **multiple unused verification/profile functions referencing non-existent tables**.

### Evidence of Unused Code

✅ **Frontend**: Zero usage
- No verification views/components
- No verification routes
- No calls to verification RPC functions
- Only legacy references in empty state configs and audit log constants

❌ **Backend**: Multiple functions reference non-existent `user_profiles` table
- These functions will **fail at runtime** because the table doesn't exist
- Complete verification feature was planned but never implemented

---

## Non-Existent Tables Referenced

These tables are referenced in stored procedures but **don't exist** in `schema.sql`:

1. **`user_profiles`** - User verification and profile data
   - Would contain: `verification_status`, `public_name`, `bio`, `company_name`, `full_name`, `supporting_documents`, `verified_at`
   
2. **`verification_feedbacks`** - Admin feedback on verification requests

---

## Functions to DELETE (Not Implemented)

These functions reference non-existent tables and are never called:

### 1. ❌ `admin_get_pending_verifications()`
- Lines: ~457-496
- References: `user_profiles` table
- Purpose: Get pending verification requests
- **Action**: DELETE

### 2. ❌ `get_verification_feedbacks()`
- Lines: ~813-847
- References: `verification_feedbacks` table  
- Purpose: Get admin feedback on verifications
- **Action**: DELETE

### 3. ❌ `reset_user_verification()`
- Lines: ~885-926
- References: `user_profiles` table
- Purpose: Reset user verification status
- **Action**: DELETE

### 4. ❌ `admin_manual_verification()`
- Lines: ~928-1005
- References: `user_profiles`, `verification_feedbacks` tables
- Purpose: Manually approve user verification
- **Action**: DELETE

---

## Functions to FIX (Partially Implemented)

These functions are actually used but have verification fields that should be removed:

### 1. ⚠️ `get_all_users_with_details()`
- Lines: ~510-581
- **Used by**: `src/views/Dashboard/Admin/UserManagement.vue` (likely)
- **Problem**: Returns verification_status fields from non-existent `user_profiles` table
- **Action**: Remove these fields from RETURNS TABLE and SELECT:
  ```sql
  -- REMOVE:
  public_name TEXT,
  bio TEXT,
  company_name TEXT,
  full_name TEXT,
  verification_status "ProfileStatus",
  supporting_documents TEXT[],
  verified_at TIMESTAMPTZ,
  ```
- **Action**: Remove LEFT JOIN to `user_profiles`

---

## Frontend Cleanup

### Files with Legacy References

#### 1. `src/utils/emptyStateConfigs.js` (lines 27-43)
```javascript
verifications: {
    noData: { ... },      // DELETE this entire section
    filtered: { ... }     // Never used
}
```

#### 2. `src/stores/admin/auditLog.ts` (lines 32-34, 71-72, 217-219, 229-231)
```typescript
// DELETE these action types:
VERIFICATION_REVIEW: 'VERIFICATION_REVIEW',
VERIFICATION_RESET: 'Reset verification',
MANUAL_VERIFICATION: 'Manually approved verification',
```

---

## Cleanup Steps

### Step 1: Remove Enum from Schema ✅ DONE
```sql
-- ProfileStatus enum removed from sql/schema.sql
```

### Step 2: Delete Unused Functions (TODO)
Remove these from `sql/storeproc/client-side/11_admin_functions.sql`:
- [ ] `admin_get_pending_verifications()`
- [ ] `get_verification_feedbacks()`
- [ ] `reset_user_verification()`
- [ ] `admin_manual_verification()`

### Step 3: Fix Used Functions (TODO)
Clean up `get_all_users_with_details()`:
- [ ] Remove verification fields from RETURNS TABLE
- [ ] Remove LEFT JOIN to user_profiles
- [ ] Remove COALESCE for profile fields

### Step 4: Frontend Cleanup (TODO)
- [ ] Remove `verifications` section from `emptyStateConfigs.js`
- [ ] Remove verification action types from `auditLog.ts`

### Step 5: Regenerate all_stored_procedures.sql (TODO)
```bash
bash scripts/combine-storeproc.sh
```

### Step 6: Deploy (TODO)
```bash
psql "$DATABASE_URL" -f sql/all_stored_procedures.sql
```

---

## Quick Fix (Temporary)

If you need the database working NOW, just comment out the problematic enum:

```sql
-- DO $$ BEGIN
--     CREATE TYPE public."ProfileStatus" AS ENUM (...);
-- EXCEPTION
--     WHEN duplicate_object THEN NULL;
-- END $$;
```

This will cause verification functions to fail, but they're **never called** anyway.

---

## Why This Happened

This is classic **"planned but never implemented"** code:
1. Developer planned a user verification feature
2. Created database schema and stored procedures
3. Never built frontend components
4. Code remained but was never cleaned up
5. Caused errors when trying to deploy stored procedures

---

## Recommendation

**COMPLETE REMOVAL** - Delete all verification code:
1. ❌ No frontend uses it
2. ❌ Tables don't exist
3. ❌ Functions will fail at runtime
4. ❌ Adds complexity for no value

Clean codebase = Happy developers! 🎉

---

**Documented By**: AI Assistant  
**Date**: November 17, 2025  
**Status**: 🔴 NEEDS CLEANUP - Functions reference non-existent tables

