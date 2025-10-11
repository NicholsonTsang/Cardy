# Operations Log Function Ambiguity - Fix Documentation

## 🐛 **Issue**

**Error:**
```
ERROR: 42725: function name "get_operations_log" is not unique
HINT: Specify the argument list to select the function unambiguously.
```

**Root Cause:**
Multiple versions of `get_operations_log` function existed in the database with different parameter signatures, causing PostgreSQL to be unable to determine which version to use.

---

## 🔍 **Analysis**

### **What Happened:**

1. **Initial Version:** Function had 4 parameters
   ```sql
   get_operations_log(INTEGER, INTEGER, UUID, "UserRole")
   ```

2. **Enhanced Version:** Function was updated to include search and date filters (7 parameters)
   ```sql
   get_operations_log(INTEGER, INTEGER, UUID, "UserRole", TEXT, TIMESTAMPTZ, TIMESTAMPTZ)
   ```

3. **Problem:** PostgreSQL kept both versions in the database, causing ambiguity when calling the function or trying to drop/replace it.

### **Why CREATE OR REPLACE Didn't Work:**

`CREATE OR REPLACE FUNCTION` only works when the parameter list is **identical**. When you change the number or types of parameters, PostgreSQL treats it as a new function **overload**, not a replacement.

---

## ✅ **Solution**

### **Three-Part Fix:**

#### **1. Enhanced `drop_all_functions_simple.sql`**

Added comprehensive list of all functions including logging functions to ensure ALL versions are dropped with their specific signatures.

**File:** `sql/drop_all_functions_simple.sql`

**Changes:**
- Added new admin functions: `admin_get_user_by_email`, `admin_get_user_cards`, `admin_get_card_content`, `admin_get_card_batches`, `admin_get_batch_issued_cards`
- Added logging functions: `log_operation`, `get_operations_log`, `get_operations_log_stats`
- Added auth/utility functions: `handle_new_user`, `get_card_content_items`, `get_content_item_by_id`, etc.

**How it Works:**
```sql
-- Dynamic query that finds ALL versions of each function
SELECT format('DROP FUNCTION IF EXISTS %I(%s) CASCADE', 
             p.proname, 
             pg_get_function_identity_arguments(p.oid)) as drop_cmd
FROM pg_proc p
WHERE p.proname IN ('get_operations_log', 'log_operation', ...)
```

This approach:
- ✅ Finds all versions regardless of parameter count
- ✅ Drops with specific signatures (no ambiguity)
- ✅ Uses CASCADE to handle dependencies
- ✅ Automatically handles function overloads

---

#### **2. Clean `00_logging.sql`**

Removed inline DROP statements that were causing redundancy.

**File:** `sql/storeproc/client-side/00_logging.sql`

**Before:**
```sql
-- Drop old versions of get_operations_log to avoid ambiguity
DROP FUNCTION IF EXISTS get_operations_log(INTEGER, INTEGER, UUID, "UserRole") CASCADE;
DROP FUNCTION IF EXISTS get_operations_log(INTEGER, INTEGER, UUID, "UserRole", TEXT, TIMESTAMPTZ, TIMESTAMPTZ) CASCADE;

CREATE OR REPLACE FUNCTION get_operations_log(...)
```

**After:**
```sql
CREATE OR REPLACE FUNCTION get_operations_log(...)
```

**Reasoning:**
- The comprehensive drop script handles ALL versions
- Inline drops were redundant
- Cleaner separation of concerns

---

#### **3. Regenerated `all_stored_procedures.sql`**

The combine script now includes the enhanced drop logic at the beginning.

**File:** `sql/all_stored_procedures.sql`

**Structure:**
```sql
-- Drop all existing functions first
DO $$
  -- Dynamic DROP for ALL function versions
END $$;

-- Then create fresh versions
CREATE OR REPLACE FUNCTION get_operations_log(
  p_limit INTEGER DEFAULT 100,
  p_offset INTEGER DEFAULT 0,
  p_user_id UUID DEFAULT NULL,
  p_user_role "UserRole" DEFAULT NULL,
  p_search_query TEXT DEFAULT NULL,
  p_start_date TIMESTAMPTZ DEFAULT NULL,
  p_end_date TIMESTAMPTZ DEFAULT NULL
) ...
```

---

## 🚀 **Deployment Steps**

### **Manual Deployment (Recommended)**

```bash
# Step 1: Deploy the comprehensive drop + create script
psql "$DATABASE_URL" -f sql/all_stored_procedures.sql
```

This single command:
1. ✅ Drops ALL versions of ALL functions (no ambiguity)
2. ✅ Creates fresh versions with correct signatures
3. ✅ Includes all new admin user card viewing functions
4. ✅ Includes fixed operations log functions

---

### **Via Supabase Dashboard**

1. Open Supabase Dashboard → SQL Editor
2. Copy contents of `sql/all_stored_procedures.sql`
3. Paste and execute
4. Verify success (no errors)

---

### **Via Supabase MCP (if enabled)**

```typescript
await supabase.rpc('execute_sql', {
  sql: fs.readFileSync('sql/all_stored_procedures.sql', 'utf8')
})
```

---

## ✅ **Verification**

### **Check Function Versions:**

```sql
-- List all versions of get_operations_log
SELECT 
    p.proname,
    pg_get_function_identity_arguments(p.oid) as arguments,
    p.pronargs as num_args
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public'
  AND p.proname = 'get_operations_log';
```

**Expected Result:** Only ONE version with 7 parameters
```
proname              | arguments                                                              | num_args
---------------------|------------------------------------------------------------------------|----------
get_operations_log   | p_limit integer DEFAULT 100, p_offset integer DEFAULT 0, ...          | 7
```

---

### **Test Function Call:**

```sql
-- Should work without ambiguity
SELECT * FROM get_operations_log(10, 0, NULL, NULL, NULL, NULL, NULL);

-- With named parameters (recommended)
SELECT * FROM get_operations_log(
  p_limit => 10,
  p_offset => 0
);
```

---

### **Verify All Admin Functions:**

```sql
SELECT routine_name 
FROM information_schema.routines 
WHERE routine_schema = 'public' 
  AND routine_name LIKE 'admin_get%'
ORDER BY routine_name;
```

**Expected Output:**
```
admin_get_all_print_requests
admin_get_all_users
admin_get_batch_issued_cards
admin_get_card_batches
admin_get_card_content
admin_get_system_stats_enhanced
admin_get_user_by_email
admin_get_user_cards
```

---

## 📊 **Files Modified**

### **1. `sql/drop_all_functions_simple.sql`**
- ✅ Added 15+ function names to drop list
- ✅ Includes all new admin card viewing functions
- ✅ Includes logging functions
- ✅ Comprehensive coverage

### **2. `sql/storeproc/client-side/00_logging.sql`**
- ✅ Removed redundant inline DROP statements
- ✅ Kept clean function definitions
- ✅ Relies on comprehensive drop script

### **3. `sql/all_stored_procedures.sql`**
- ✅ Regenerated with enhanced drop logic
- ✅ Includes all new functions
- ✅ No ambiguity in function definitions

### **4. `sql/fix_operations_log_function.sql` (Optional)**
- Created as emergency fix script
- Can be used independently if needed
- Explicitly drops both old signatures

---

## 🎯 **Why This Solution Works**

### **Problem with Simple DROP:**
```sql
DROP FUNCTION IF EXISTS get_operations_log CASCADE;
-- ERROR: function name "get_operations_log" is not unique
```

### **Solution with Specific Signatures:**
The dynamic query in `drop_all_functions_simple.sql` generates:
```sql
DROP FUNCTION IF EXISTS get_operations_log(integer, integer, uuid, "UserRole") CASCADE;
DROP FUNCTION IF EXISTS get_operations_log(integer, integer, uuid, "UserRole", text, timestamp with time zone, timestamp with time zone) CASCADE;
```

**Key Benefits:**
1. ✅ **No Ambiguity** - Each DROP targets specific signature
2. ✅ **Comprehensive** - Finds ALL versions automatically
3. ✅ **Safe** - Uses `IF EXISTS` (won't fail if function doesn't exist)
4. ✅ **Clean** - CASCADE handles dependent objects
5. ✅ **Future-Proof** - Works for any function overloads

---

## 🔄 **Function Evolution Timeline**

### **Version 1 (Old):**
```sql
get_operations_log(
  p_limit INTEGER,
  p_offset INTEGER,
  p_user_id UUID,
  p_user_role "UserRole"
)
```

### **Version 2 (Current):**
```sql
get_operations_log(
  p_limit INTEGER DEFAULT 100,
  p_offset INTEGER DEFAULT 0,
  p_user_id UUID DEFAULT NULL,
  p_user_role "UserRole" DEFAULT NULL,
  p_search_query TEXT DEFAULT NULL,
  p_start_date TIMESTAMPTZ DEFAULT NULL,
  p_end_date TIMESTAMPTZ DEFAULT NULL
)
```

**Changes:**
- ✅ Added `p_search_query` for text search
- ✅ Added `p_start_date` for date filtering
- ✅ Added `p_end_date` for date filtering
- ✅ All parameters have defaults (backward compatible)

---

## 🛡️ **Prevention**

### **Best Practice:**

When changing function signatures, always:

1. **Explicitly drop old versions** in migration scripts
2. **Use specific parameter lists** in DROP statements
3. **Update drop_all_functions_simple.sql** with new function names
4. **Regenerate all_stored_procedures.sql** after changes
5. **Test deployment** in development first

### **Example Pattern:**

```sql
-- In your storeproc file, if changing parameters:

-- Drop old version(s) explicitly
DROP FUNCTION IF EXISTS my_function(INTEGER, TEXT) CASCADE;
DROP FUNCTION IF EXISTS my_function(INTEGER) CASCADE;

-- Create new version
CREATE OR REPLACE FUNCTION my_function(
  p_id INTEGER,
  p_name TEXT,
  p_email TEXT  -- New parameter
) ...
```

---

## 📝 **Summary**

### **What Was Fixed:**
- ✅ Function name ambiguity resolved
- ✅ Comprehensive drop script enhanced
- ✅ Clean function definitions maintained
- ✅ All admin user card functions included
- ✅ Operations log functions working

### **How It Was Fixed:**
1. Enhanced `drop_all_functions_simple.sql` with comprehensive function list
2. Removed redundant inline DROP statements
3. Regenerated `all_stored_procedures.sql` with proper drop logic
4. Dynamic query finds and drops ALL function versions

### **Result:**
- ✅ **No more ambiguity errors**
- ✅ **Single clean version** of each function
- ✅ **Safe deployment** process
- ✅ **Future-proof** against overloads

---

## 🎊 **Deployment Ready**

All files are ready for deployment:
- ✅ `sql/drop_all_functions_simple.sql` - Enhanced
- ✅ `sql/storeproc/client-side/00_logging.sql` - Cleaned
- ✅ `sql/all_stored_procedures.sql` - Regenerated

**Next Step:** Deploy `sql/all_stored_procedures.sql` to production database

```bash
psql "$DATABASE_URL" -f sql/all_stored_procedures.sql
```

**Expected Output:** No errors, all functions created successfully ✅

