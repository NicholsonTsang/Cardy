# Server-Side Pagination Implementation for Admin Credit Management

## Overview
Implemented server-side pagination, searching, and sorting for the User Balances tab in the Admin Credit Management page. This improves performance significantly when dealing with large datasets by offloading filtering, pagination, and sorting to the database.

## Changes Made

### 1. Database Layer (Stored Procedure)

**File:** `sql/storeproc/client-side/admin_credit_management.sql`

Updated `admin_get_user_credits` function to support:
- **Search**: Full-text search across user name and email
- **Pagination**: Limit and offset parameters
- **Sorting**: Dynamic sorting by any column (balance, email, name, purchased, consumed, created_at)
- **Total Count**: Returns total matching records for pagination UI

#### New Function Signature:
```sql
CREATE OR REPLACE FUNCTION admin_get_user_credits(
    p_limit INTEGER DEFAULT 20,
    p_offset INTEGER DEFAULT 0,
    p_search TEXT DEFAULT NULL,
    p_sort_field TEXT DEFAULT 'balance',
    p_sort_order TEXT DEFAULT 'DESC'
)
RETURNS TABLE (
    user_id UUID,
    user_email TEXT,
    user_name TEXT,
    balance DECIMAL,
    total_purchased DECIMAL,
    total_consumed DECIMAL,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ,
    total_count BIGINT  -- NEW: Total matching records
)
```

#### Key Features:
- **SQL Injection Protection**: Uses parameterized queries with format() and USING clause
- **Case-Insensitive Search**: LOWER() function for both search term and fields
- **Flexible Sorting**: Safe column name injection using `%s` format specifier with CASE-validated values
  - ⚠️ **Important**: Uses `%s` instead of `%I` to allow table-qualified column names (e.g., `uc.balance`)
  - The `%I` identifier format would quote `uc.balance` as `"uc.balance"` (single identifier), not `uc.balance` (table + column)
  - Safe from SQL injection because all column names come from a CASE statement with hardcoded values
- **Performance**: Single query returns both data and total count

### 2. Store Layer (Pinia)

**File:** `src/stores/admin/credits.ts`

#### New State:
```typescript
const totalRecords = ref(0)  // Total matching records for pagination
```

#### Updated `fetchUserCredits` Function:
```typescript
async function fetchUserCredits(
    limit = 20,
    offset = 0,
    search = '',
    sortField = 'balance',
    sortOrder = 'DESC'
)
```

**Features:**
- Passes all pagination/search/sort parameters to stored procedure
- Extracts `total_count` from first result row
- Updates `totalRecords` state for DataTable pagination

### 3. Component Layer (Vue)

**File:** `src/views/Dashboard/Admin/AdminCreditManagement.vue`

#### New State Variables:
```typescript
const first = ref(0)                          // Current page offset
const rowsPerPage = ref(20)                   // Rows per page
const sortField = ref('balance')              // Current sort field
const sortOrder = ref<'ASC' | 'DESC'>('DESC') // Current sort order
```

#### DataTable Configuration:
```vue
<DataTable 
  :value="adminCreditStore.userCredits" 
  :loading="adminCreditStore.loading"
  lazy                                      <!-- Enable server-side mode -->
  paginator 
  :rows="rowsPerPage" 
  :totalRecords="adminCreditStore.totalRecords"  <!-- Total for pagination -->
  :rowsPerPageOptions="[10, 20, 50, 100]"
  @page="onPageChange"                      <!-- Page change handler -->
  @sort="onSort"                            <!-- Sort handler -->
  :first="first"                            <!-- Current page offset -->
  sortMode="single"                         <!-- Single column sorting -->
  removableSort                             <!-- Allow clearing sort -->
/>
```

#### New Functions:

**1. Load User Credits:**
```typescript
async function loadUserCredits() {
  await adminCreditStore.fetchUserCredits(
    rowsPerPage.value,
    first.value,
    userFilter.value,
    sortField.value,
    sortOrder.value
  )
}
```

**2. Page Change Handler:**
```typescript
function onPageChange(event: any) {
  first.value = event.first
  rowsPerPage.value = event.rows
  loadUserCredits()
}
```

**3. Sort Handler:**
```typescript
function onSort(event: any) {
  sortField.value = event.sortField || 'balance'
  sortOrder.value = event.sortOrder === 1 ? 'ASC' : 'DESC'
  loadUserCredits()
}
```

**4. Debounced Search:**
```typescript
let searchTimeout: NodeJS.Timeout | null = null
watch(userFilter, (newValue) => {
  if (searchTimeout) clearTimeout(searchTimeout)
  searchTimeout = setTimeout(async () => {
    first.value = 0 // Reset to first page when searching
    await loadUserCredits()
  }, 500)  // 500ms debounce
})
```

#### Updated Columns:
All columns now support server-side sorting:
```vue
<Column field="balance" :sortable="true" ... />
<Column field="user_name" :sortable="true" ... />
<Column field="user_email" :sortable="true" ... />
<Column field="total_purchased" :sortable="true" ... />
<Column field="total_consumed" :sortable="true" ... />
<Column field="created_at" :sortable="true" ... />
```

## Deployment Instructions

### 1. Deploy Database Changes
Execute the stored procedure update in Supabase SQL Editor:
```bash
# Option A: Deploy single function
psql "$DATABASE_URL" -f deploy-admin-user-credits-pagination.sql

# Option B: Deploy all stored procedures
./scripts/combine-storeproc.sh
psql "$DATABASE_URL" -f sql/all_stored_procedures.sql
```

### 2. Frontend Changes
Frontend changes are already in place. No additional deployment needed.

## Performance Benefits

### Before (Client-Side Filtering):
- ❌ Loads ALL user records on page load
- ❌ Filters/sorts in browser memory
- ❌ Slow with 1000+ users
- ❌ High memory usage
- ❌ Poor mobile performance

### After (Server-Side Filtering):
- ✅ Loads only 20 records per page
- ✅ Filters/sorts in PostgreSQL
- ✅ Fast with any number of users
- ✅ Low memory usage
- ✅ Excellent mobile performance

## Testing Checklist

- [ ] Search by user name
- [ ] Search by user email  
- [ ] Search with partial matches
- [ ] Search with no results (shows "No users found")
- [ ] Clear search filter
- [ ] Sort by Balance (ascending/descending)
- [ ] Sort by User Name
- [ ] Sort by Email
- [ ] Sort by Total Purchased
- [ ] Sort by Total Consumed
- [ ] Sort by Created At
- [ ] Change rows per page (10, 20, 50, 100)
- [ ] Navigate between pages
- [ ] Search + Sort combination
- [ ] Search + Pagination combination
- [ ] Results counter shows correct numbers
- [ ] Adjust credits refreshes data correctly
- [ ] Initial load shows correct default sort (by balance DESC)

## User Experience Improvements

1. **Search**
   - ✅ 500ms debounce prevents excessive queries
   - ✅ Searches both name and email simultaneously
   - ✅ Case-insensitive matching
   - ✅ Real-time results counter
   - ✅ Clear filter button

2. **Pagination**
   - ✅ Server-side pagination for large datasets
   - ✅ Flexible rows per page options
   - ✅ Maintains current page during sort
   - ✅ Resets to page 1 when searching

3. **Sorting**
   - ✅ Click column header to sort
   - ✅ Click again to reverse order
   - ✅ Click third time to remove sort
   - ✅ Visual indicator of current sort
   - ✅ Maintains search filter during sort

4. **Loading States**
   - ✅ Spinner during data fetch
   - ✅ Table remains visible during reload
   - ✅ Smooth transitions

## Security Notes

- ✅ Admin role check in stored procedure
- ✅ Parameterized queries prevent SQL injection
- ✅ Column name validation for sorting
- ✅ RLS policies still enforced
- ✅ No sensitive data exposed

## Troubleshooting

### Error: `column "uc.balance" does not exist`

**Problem**: PostgreSQL treats `"uc.balance"` as a single identifier instead of table + column.

**Cause**: Using `%I` format specifier with table-qualified column names in `format()`.

**Solution**: Use `%s` instead of `%I` for table-qualified columns. This is safe when:
- Column names come from a validated CASE statement (not user input)
- All possible values are hardcoded and known-safe

**Example:**
```sql
-- ❌ Wrong: %I quotes as single identifier
format('ORDER BY %I', 'uc.balance')  -- Results in: ORDER BY "uc.balance"

-- ✅ Correct: %s allows table qualification
format('ORDER BY %s', 'uc.balance')  -- Results in: ORDER BY uc.balance
```

### Error: Search not working

**Check:**
1. Verify debounce is working (wait 500ms after typing)
2. Check browser console for errors
3. Verify stored procedure is deployed correctly
4. Test search directly in database:
   ```sql
   SELECT * FROM admin_get_user_credits(20, 0, 'test@example.com', 'balance', 'DESC');
   ```

### Error: Pagination shows wrong total

**Check:**
1. Verify `total_count` is being returned from stored procedure
2. Check if store is extracting count correctly: `data[0].total_count`
3. Ensure DataTable `:totalRecords` is bound to store value

## Future Enhancements

Potential improvements for future iterations:
- [ ] Export filtered results to CSV
- [ ] Advanced filters (balance range, date range)
- [ ] Bulk operations on filtered users
- [ ] Save search/filter preferences
- [ ] Column visibility toggle
- [ ] Multi-column sorting

## Files Modified

1. `sql/storeproc/client-side/admin_credit_management.sql`
2. `sql/all_stored_procedures.sql` (regenerated)
3. `src/stores/admin/credits.ts`
4. `src/views/Dashboard/Admin/AdminCreditManagement.vue`

## Files Created

1. `deploy-admin-user-credits-pagination.sql` (deployment script)
2. `SERVER_SIDE_PAGINATION_IMPLEMENTATION.md` (this document)

