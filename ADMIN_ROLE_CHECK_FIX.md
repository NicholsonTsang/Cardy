# Admin Role Check Fix - User Cards Viewer Functions

## 🐛 **Issue**

**Error:**
```
POST /rest/v1/rpc/admin_get_user_by_email 400 (Bad Request)
{code: 'P0001', details: null, hint: null, message: 'Admin access required'}
```

**Root Cause:**
The 5 new admin user card viewing functions were using an incorrect method to check for admin role:

```sql
-- ❌ WRONG - This doesn't work in Supabase
v_caller_role := auth.jwt() ->> 'role';
```

The role is stored in `auth.users.raw_user_meta_data`, not directly in the JWT claims accessible via `auth.jwt()`.

---

## ✅ **Solution**

### **Fixed All 5 Functions:**

1. `admin_get_user_by_email`
2. `admin_get_user_cards`
3. `admin_get_card_content`
4. `admin_get_card_batches`
5. `admin_get_batch_issued_cards`

### **Correct Admin Check Pattern:**

**Before (WRONG):**
```sql
DECLARE
    v_caller_role TEXT;
BEGIN
    -- ❌ This doesn't work
    v_caller_role := auth.jwt() ->> 'role';
    IF v_caller_role != 'admin' THEN
        RAISE EXCEPTION 'Admin access required';
    END IF;
```

**After (CORRECT):**
```sql
DECLARE
    v_caller_role TEXT;
BEGIN
    -- ✅ This is the correct way
    SELECT raw_user_meta_data->>'role' INTO v_caller_role
    FROM auth.users
    WHERE id = auth.uid();
    
    IF v_caller_role != 'admin' THEN
        RAISE EXCEPTION 'Admin access required';
    END IF;
```

---

## 📋 **What Changed**

### **File:** `sql/storeproc/client-side/11_admin_functions.sql`

**Lines Updated:** 1270-1456 (all 5 new admin functions)

**Pattern Applied:**
```sql
-- Query auth.users table to get role from raw_user_meta_data
SELECT raw_user_meta_data->>'role' INTO v_caller_role
FROM auth.users
WHERE id = auth.uid();
```

This matches the pattern used by all other admin functions in the codebase (18 existing functions).

---

## 🔍 **Why This is Correct**

### **How Supabase Stores User Roles:**

1. **User signs up** → Role is set in `auth.users.raw_user_meta_data`
   ```json
   {
     "role": "admin"  // or "cardIssuer" or "user"
   }
   ```

2. **Database function** → Must query `auth.users` to get role
   ```sql
   SELECT raw_user_meta_data->>'role' FROM auth.users WHERE id = auth.uid()
   ```

3. **JWT Claims** → `auth.jwt()` returns JWT payload, which may not include custom metadata by default

### **Verified Pattern:**

All existing admin functions use this exact pattern:
- `admin_waive_batch_payment` (line 15-20)
- `admin_get_system_stats_enhanced` (line 81-86)
- `admin_get_all_print_requests` (line 145-150)
- `admin_update_print_request_status` (line 218-223)
- And 14 more functions...

---

## 🚀 **Deployment**

### **Step 1: Regenerate** ✅
```bash
bash scripts/combine-storeproc.sh
```
**Status:** Already completed

### **Step 2: Deploy to Database**
```bash
psql "$DATABASE_URL" -f sql/all_stored_procedures.sql
```

Or via Supabase Dashboard:
1. Open SQL Editor
2. Paste contents of `sql/all_stored_procedures.sql`
3. Execute

---

## ✅ **Verification**

### **Test User Search:**

After deployment, test in browser console:

```javascript
// This should now work for admin users
const { data, error } = await supabase.rpc('admin_get_user_by_email', {
  p_email: 'test@example.com'
})

if (error) {
  console.error('Error:', error)
} else {
  console.log('User found:', data)
}
```

**Expected Result:** User data returned (if user exists) ✅

---

### **Test All Admin Functions:**

```sql
-- 1. Search user by email
SELECT * FROM admin_get_user_by_email('user@example.com');

-- 2. Get user's cards
SELECT * FROM admin_get_user_cards('user-uuid-here');

-- 3. Get card content
SELECT * FROM admin_get_card_content('card-uuid-here');

-- 4. Get card batches
SELECT * FROM admin_get_card_batches('card-uuid-here');

-- 5. Get batch issued cards
SELECT * FROM admin_get_batch_issued_cards('batch-uuid-here');
```

**All should work for admin users** ✅

---

## 📊 **Comparison**

### **All Admin Functions Role Check Methods:**

| Functions | Method | Status |
|-----------|--------|--------|
| 18 existing functions | `SELECT raw_user_meta_data->>'role' FROM auth.users` | ✅ Correct |
| 5 new functions (before fix) | `auth.jwt() ->> 'role'` | ❌ Wrong |
| 5 new functions (after fix) | `SELECT raw_user_meta_data->>'role' FROM auth.users` | ✅ Correct |

**Result:** All 23 admin functions now use the same correct pattern ✅

---

## 🎯 **Files Modified**

1. ✅ `sql/storeproc/client-side/11_admin_functions.sql`
   - Fixed lines 1270-1456
   - All 5 new admin functions updated

2. ✅ `sql/all_stored_procedures.sql`
   - Regenerated with fixes
   - Ready for deployment

---

## 📝 **Summary**

**Issue:** Admin role check failing in new functions  
**Cause:** Used `auth.jwt() ->> 'role'` instead of querying `auth.users`  
**Fix:** Updated all 5 functions to use correct pattern  
**Status:** ✅ Fixed and regenerated  
**Next:** Deploy `sql/all_stored_procedures.sql`

---

## ✨ **Expected Behavior After Fix**

**Before:**
```
❌ Error: "Admin access required" (even for admin users)
❌ Cannot search users
❌ Cannot view user cards
❌ Admin User Cards Viewer page unusable
```

**After:**
```
✅ Admin users authenticated correctly
✅ User search works
✅ User cards display
✅ Admin User Cards Viewer fully functional
```

---

## 🎊 **Deploy Now**

Your `sql/all_stored_procedures.sql` is ready with all fixes:
- ✅ Admin role checks corrected
- ✅ Operations log ambiguity resolved
- ✅ All 5 new admin functions included
- ✅ All existing functions preserved

**Deploy command:**
```bash
psql "$DATABASE_URL" -f sql/all_stored_procedures.sql
```

**Then test the Admin User Cards Viewer page!** 🚀

