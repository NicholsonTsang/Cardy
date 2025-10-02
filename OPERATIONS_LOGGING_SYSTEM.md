# Operations Logging System

## Overview
Simple unified logging system for all write operations in stored procedures. Tracks user ID, user role, operation description, and timestamp.

## Database Schema

### Operations Log Table
```sql
CREATE TABLE operations_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    user_role "UserRole" NOT NULL, -- 'user', 'cardIssuer', or 'admin'
    operation TEXT NOT NULL,        -- Simple description of what happened
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### Indexes
- `idx_operations_log_user_id` - Fast lookups by user
- `idx_operations_log_user_role` - Filter by role
- `idx_operations_log_created_at` - Time-based queries

## Logging Functions

### `log_operation(p_operation TEXT)`
Helper function to be called from any stored procedure that performs write operations.

**Features:**
- Automatically captures user ID from `auth.uid()`
- Automatically gets user role from `auth.users` metadata
- Defaults to 'user' role if not set
- Silently fails to prevent breaking main operations
- Logs warnings on failure without throwing exceptions

**Usage:**
```sql
-- At the end of any CREATE/UPDATE/DELETE operation
PERFORM log_operation('Created card: ' || card_name || ' (ID: ' || card_id || ')');
PERFORM log_operation('Updated batch: ' || batch_name || ' (ID: ' || batch_id || ')');
PERFORM log_operation('Deleted content item: ' || item_name || ' (ID: ' || item_id || ')');
```

### `get_operations_log(...)`
Admin-only function to retrieve operations log with filtering.

**Parameters:**
- `p_limit INTEGER DEFAULT 100` - Number of records to return
- `p_offset INTEGER DEFAULT 0` - Pagination offset
- `p_user_id UUID DEFAULT NULL` - Filter by specific user
- `p_user_role "UserRole" DEFAULT NULL` - Filter by role

**Returns:**
- `id` - Log entry ID
- `user_id` - User who performed the operation
- `user_email` - User's email address
- `user_role` - Role at time of operation
- `operation` - Description of what happened
- `created_at` - Timestamp

**Example:**
```sql
-- Get last 50 operations
SELECT * FROM get_operations_log(50, 0);

-- Get operations by specific user
SELECT * FROM get_operations_log(100, 0, '123e4567-e89b-12d3-a456-426614174000', NULL);

-- Get all admin operations
SELECT * FROM get_operations_log(1000, 0, NULL, 'admin'::"UserRole");
```

### `get_operations_log_stats()`
Admin-only function to get summary statistics.

**Returns:**
- `total_operations` - All time operation count
- `operations_today` - Count for current day
- `operations_this_week` - Count for last 7 days
- `operations_this_month` - Count for last 30 days
- `admin_operations` - Total admin operations
- `card_issuer_operations` - Total card issuer operations
- `user_operations` - Total user operations

## Implementation Guide

### Step 1: Add Logging to Write Operations

For any stored procedure that performs INSERT, UPDATE, or DELETE:

1. **At the end of the operation**, before RETURN
2. **Use `PERFORM`** not `SELECT` (we're calling a VOID function)
3. **Write descriptive messages** with key identifiers

**Example for CREATE operations:**
```sql
CREATE OR REPLACE FUNCTION create_something(p_name TEXT) 
RETURNS UUID AS $$
DECLARE
    v_id UUID;
BEGIN
    INSERT INTO sometable (name) VALUES (p_name) RETURNING id INTO v_id;
    
    -- Log the operation
    PERFORM log_operation('Created something: ' || p_name || ' (ID: ' || v_id || ')');
    
    RETURN v_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

**Example for UPDATE operations:**
```sql
CREATE OR REPLACE FUNCTION update_something(p_id UUID, p_name TEXT)
RETURNS BOOLEAN AS $$
DECLARE
    v_old_name TEXT;
BEGIN
    SELECT name INTO v_old_name FROM sometable WHERE id = p_id;
    UPDATE sometable SET name = p_name WHERE id = p_id;
    
    -- Log the operation
    PERFORM log_operation('Updated something: ' || p_name || ' (ID: ' || p_id || ')');
    
    RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

**Example for DELETE operations:**
```sql
CREATE OR REPLACE FUNCTION delete_something(p_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    v_name TEXT;
BEGIN
    SELECT name INTO v_name FROM sometable WHERE id = p_id;
    DELETE FROM sometable WHERE id = p_id;
    
    -- Log the operation  
    PERFORM log_operation('Deleted something: ' || v_name || ' (ID: ' || p_id || ')');
    
    RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

### Step 2: Logging Message Format

Use this consistent format for logging messages:

- **CREATE**: `'Created <resource>: <name> (ID: <id>)'`
- **UPDATE**: `'Updated <resource>: <name> (ID: <id>)'`
- **DELETE**: `'Deleted <resource>: <name> (ID: <id>)'`
- **CUSTOM**: `'<Action> <resource>: <details>'`

**Examples:**
```sql
'Created card: Museum Tour (ID: 123e4567-...)'
'Updated batch: Spring Collection (ID: 789abc...)'
'Deleted content item: Gallery Photo (ID: def012...)'
'Issued batch: 50 cards for card XYZ'
'Activated issued card: ABC123'
'Waived payment for batch: Summer 2024'
```

### Step 3: Files That Need Logging

Add `PERFORM log_operation(...)` to all write operations in:

#### ✅ Already Updated:
- `02_card_management.sql`
  - `create_card` ✅
  - `update_card` ✅
  - `delete_card` ✅

#### 🔧 Need to Update:
- `03_content_management.sql`
  - `create_content_item`
  - `update_content_item`
  - `delete_content_item`
  - `reorder_content_items`
  - `update_content_item_parent`

- `04_batch_management.sql`
  - `issue_card_batch`
  - `toggle_card_batch_disabled_status`
  - `activate_issued_card`
  - `delete_issued_card`
  - `generate_batch_cards`

- `05_payment_management.sql` (server-side)
  - `create_batch_payment`
  - `update_batch_payment_status`
  - `confirm_batch_payment`

- `06_print_requests.sql`
  - `request_card_printing`
  - `withdraw_print_request`

- `11_admin_functions.sql`
  - `admin_update_user_role`
  - `admin_update_print_request_status`
  - `admin_add_print_request_feedback`
  - `admin_waive_batch_payment`
  - Any other admin write operations

## Deployment Steps

1. **Update `schema.sql`** - Already includes `operations_log` table ✅

2. **Update stored procedure files** - Add logging to write operations

3. **Regenerate combined SQL:**
   ```bash
   cd /Users/nicholsontsang/coding/Cardy
   bash scripts/combine-storeproc.sh
   ```

4. **Deploy to database:**
   ```bash
   # Option 1: Using psql
   psql "$DATABASE_URL" -f sql/all_stored_procedures.sql
   
   # Option 2: Using Supabase Dashboard
   # Copy contents of all_stored_procedures.sql
   # Paste into SQL Editor and Run
   ```

5. **Create the table** (if not already created):
   ```sql
   -- Run this if the table doesn't exist yet
   CREATE TABLE IF NOT EXISTS operations_log (
       id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
       user_id UUID NOT NULL,
       user_role "UserRole" NOT NULL,
       operation TEXT NOT NULL,
       created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
   );
   
   CREATE INDEX IF NOT EXISTS idx_operations_log_user_id ON operations_log(user_id);
   CREATE INDEX IF NOT EXISTS idx_operations_log_user_role ON operations_log(user_role);
   CREATE INDEX IF NOT EXISTS idx_operations_log_created_at ON operations_log(created_at DESC);
   ```

## Frontend Integration (Optional)

### Admin Dashboard - Operations Log Viewer

Create a new admin page to view operations:

```typescript
// stores/admin/operationsLog.ts
export const useAdminOperationsLogStore = defineStore('admin-operations-log', () => {
  const logs = ref<OperationLog[]>([])
  const stats = ref<OperationStats | null>(null)
  
  async function fetchLogs(limit = 100, offset = 0, filters = {}) {
    const { data, error } = await supabase.rpc('get_operations_log', {
      p_limit: limit,
      p_offset: offset,
      p_user_id: filters.userId || null,
      p_user_role: filters.userRole || null
    })
    
    if (error) throw error
    logs.value = data
  }
  
  async function fetchStats() {
    const { data, error } = await supabase.rpc('get_operations_log_stats')
    if (error) throw error
    stats.value = data[0]
  }
  
  return { logs, stats, fetchLogs, fetchStats }
})
```

## Example Log Entries

```
2025-10-02 10:15:23 | user@example.com | cardIssuer | Created card: Museum Tour Guide (ID: 123e4567...)
2025-10-02 10:16:45 | user@example.com | cardIssuer | Updated card: Museum Tour Guide (ID: 123e4567...)
2025-10-02 10:18:12 | user@example.com | cardIssuer | Created content item: Ancient Artifacts (ID: 789abc...)
2025-10-02 10:20:33 | user@example.com | cardIssuer | Issued batch: 50 cards for Museum Tour Guide
2025-10-02 10:25:01 | admin@example.com | admin      | Waived payment for batch: Test Batch (ID: def012...)
2025-10-02 10:30:45 | user@example.com | cardIssuer | Deleted card: Old Design (ID: ghi345...)
```

## Benefits

1. **Simple & Lightweight** - No complex enums or metadata
2. **Unified** - Same table for all users and admins
3. **Non-Breaking** - Logging failures don't affect operations
4. **Queryable** - Easy to filter by user, role, or date
5. **Auditable** - Complete trail of all write operations
6. **Low Overhead** - Single insert per operation

## Security

- Operations log can only be viewed by admins
- User role is captured at time of operation (immutable)
- Function is SECURITY DEFINER but validates admin role
- Logging failures log warnings but don't break operations

## Performance Considerations

- Index on `created_at DESC` for efficient recent operations queries
- Index on `user_id` for per-user operation history
- Index on `user_role` for role-based filtering
- Consider archiving old logs (e.g., > 1 year) if volume is high

## Maintenance

### View Recent Operations
```sql
SELECT * FROM get_operations_log(50, 0) ORDER BY created_at DESC;
```

### Count Operations by Role
```sql
SELECT user_role, COUNT(*) 
FROM operations_log 
GROUP BY user_role;
```

### Find Operations by User
```sql
SELECT ol.*, au.email
FROM operations_log ol
JOIN auth.users au ON ol.user_id = au.id
WHERE au.email = 'specific@user.com'
ORDER BY ol.created_at DESC;
```

### Archive Old Logs
```sql
-- Archive logs older than 1 year (optional)
DELETE FROM operations_log 
WHERE created_at < NOW() - INTERVAL '1 year';
```

## Migration from Old Audit System

The old `admin_audit_log` table had complex structure with:
- Action types (enums)
- Security/business impact levels
- Detailed JSONB metadata
- Admin-specific fields

The new `operations_log` is simpler:
- Plain text descriptions
- User role captured automatically
- Lightweight and easy to query
- Works for all users, not just admins

Both systems can coexist if needed, but `operations_log` is recommended for new operations.

