# Deploy Profile Removal Changes

## Overview
This guide will help you deploy all the profile removal changes to your Supabase database.

## ⚠️ Important - Read Before Deploying

**THIS WILL PERMANENTLY DELETE:**
- All user profile data
- All verification submissions
- All verification feedback records

**BACKUP YOUR DATABASE FIRST!**

## Deployment Steps

### Option 1: Using Supabase Dashboard (Recommended for Production)

1. **Backup your database:**
   ```bash
   # Go to Supabase Dashboard > Database > Backups
   # Or use pg_dump if you have direct access
   ```

2. **Deploy schema changes:**
   - Go to Supabase Dashboard > SQL Editor
   - Copy and paste contents of `sql/schema.sql`
   - Click "Run"
   - Wait for completion

3. **Deploy stored procedures:**
   - Go to Supabase Dashboard > SQL Editor
   - Copy and paste contents of `sql/all_stored_procedures.sql`
   - Click "Run"
   - Wait for completion

### Option 2: Using psql Command Line

```bash
cd /Users/nicholsontsang/coding/Cardy

# 1. Backup first!
pg_dump "$DATABASE_URL" > backup_$(date +%Y%m%d_%H%M%S).sql

# 2. Deploy schema (will drop profile tables)
psql "$DATABASE_URL" -f sql/schema.sql

# 3. Deploy stored procedures (without profile functions)
psql "$DATABASE_URL" -f sql/all_stored_procedures.sql
```

### Option 3: Using Supabase CLI (Local Development)

```bash
cd /Users/nicholsontsang/coding/Cardy

# For local development
supabase db reset

# For production
supabase db push
```

## Verification Steps

After deployment, verify everything works:

### 1. Check Tables Were Dropped
```sql
-- These should return "relation does not exist"
SELECT * FROM user_profiles LIMIT 1;
SELECT * FROM verification_feedbacks LIMIT 1;
```

### 2. Check Functions Exist
```sql
-- These should return results
SELECT proname FROM pg_proc WHERE proname IN (
  'admin_get_all_users',
  'admin_update_user_role',
  'admin_get_system_stats_enhanced'
);
```

### 3. Test Admin Dashboard
- Navigate to: `http://localhost:5173/cms/admin`
- Should load without errors
- Statistics should display correctly

### 4. Test User Management
- Navigate to: `http://localhost:5173/cms/users`
- Should show user list
- Should allow role changes

## Troubleshooting

### Error: "PrintRequestStatus enum doesn't have SHIPPING"

This means the enum wasn't updated. Run this SQL first:

```sql
-- Add SHIPPING to the enum if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_enum 
    WHERE enumlabel = 'SHIPPING' 
    AND enumtypid = (
      SELECT oid FROM pg_type WHERE typname = 'PrintRequestStatus'
    )
  ) THEN
    ALTER TYPE "PrintRequestStatus" ADD VALUE 'SHIPPING' AFTER 'PROCESSING';
  END IF;
END $$;
```

Then redeploy schema.sql and all_stored_procedures.sql.

### Error: "relation user_profiles does not exist"

This is expected after profile removal. If you still see this error in the frontend:
1. Clear browser cache
2. Hard refresh (Cmd+Shift+R / Ctrl+Shift+R)
3. Check that all_stored_procedures.sql was deployed

### Error: "function admin_get_all_users does not exist"

Deploy the stored procedures:
```bash
psql "$DATABASE_URL" -f sql/all_stored_procedures.sql
```

## Rollback Plan

If you need to rollback:

```bash
# Restore from backup
psql "$DATABASE_URL" < backup_YYYYMMDD_HHMMSS.sql
```

## Files Changed

### Database Files:
- ✅ `sql/schema.sql` - Profile tables and enum removed
- ✅ `sql/all_stored_procedures.sql` - Profile functions removed, new user management functions added
- ✅ `sql/storeproc/client-side/08_user_profiles.sql` - Deleted
- ✅ `sql/storeproc/client-side/11_admin_functions.sql` - Updated with new functions

### Frontend Files:
- ✅ All profile components deleted
- ✅ All verification stores deleted
- ✅ Router updated
- ✅ Admin dashboard updated
- ✅ AppHeader navigation updated
- ✅ UserManagement completely rewritten

## Post-Deployment Checklist

- [ ] Database backup created
- [ ] schema.sql deployed successfully
- [ ] all_stored_procedures.sql deployed successfully
- [ ] Admin dashboard loads without errors
- [ ] User management page loads without errors
- [ ] Can view user list
- [ ] Can change user roles
- [ ] Print requests page works (no profile references)
- [ ] No console errors in browser
- [ ] All navigation links work

## Support

If you encounter issues:
1. Check browser console for errors
2. Check Supabase logs for SQL errors
3. Verify all files were deployed correctly
4. Review PROFILE_FEATURES_REMOVAL.md for complete details

