# ProfileStatus Enum Fix

**Date**: November 17, 2025  
**Type**: CRITICAL FIX  
**Status**: ✅ FIXED

## Issue

```
ERROR: 42704: type ProfileStatus does not exist
```

## Root Cause

The `ProfileStatus` enum type was being used in stored procedures (`sql/storeproc/client-side/11_admin_functions.sql`) but was **not defined** in the database schema (`sql/schema.sql`).

### Where It Was Used

The enum was referenced in multiple admin functions:
- `get_all_verifications()` - User verification listing
- `get_verification_by_id()` - Single verification details
- `get_all_users_with_details()` - User management with verification status
- `admin_manual_verification()` - Manual verification approval

## Solution

Added the missing enum definition to `sql/schema.sql`:

```sql
DO $$ BEGIN
    -- Profile/Verification Status enum
    -- Used for user verification and profile approval status
    CREATE TYPE public."ProfileStatus" AS ENUM (
        'pending',     -- Verification pending review
        'verified',    -- User verified and approved
        'rejected'     -- Verification rejected
    );
EXCEPTION
    WHEN duplicate_object THEN NULL;
    WHEN insufficient_privilege THEN NULL;
END $$;
```

## Deployment

### Option 1: Fresh Database
If starting fresh, just run:
```bash
psql "$DATABASE_URL" -f sql/schema.sql
psql "$DATABASE_URL" -f sql/all_stored_procedures.sql
```

### Option 2: Existing Database
Add the enum type manually:
```sql
CREATE TYPE public."ProfileStatus" AS ENUM (
    'pending',
    'verified',
    'rejected'
);
```

Then run stored procedures:
```bash
psql "$DATABASE_URL" -f sql/all_stored_procedures.sql
```

## Files Modified

- `sql/schema.sql` - Added ProfileStatus enum definition (lines 44-55)

## Related Enums

The schema now defines 4 enum types:
1. `QRCodePosition` - QR code placement on cards
2. `PrintRequestStatus` - Print request workflow statuses
3. `UserRole` - User role types (user, cardIssuer, admin)
4. **`ProfileStatus`** - User verification status ✅ (newly added)

## Status

✅ **FIXED** - Enum definition added to schema.sql

---

**Fixed By**: AI Assistant  
**Date**: November 17, 2025

