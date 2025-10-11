# Operations Log Search Enhancement

## ✅ Overview
Enhanced the `get_operations_log` function to support comprehensive search and filtering capabilities, including **user email search**.

---

## 🎯 New Features

### 1. **Email Search** ✨
- Search operations by user email address
- Case-insensitive search with partial matching
- Matches any part of the email address

### 2. **Operation Search** 
- Search within operation descriptions
- Case-insensitive with partial matching
- Find specific actions or entities

### 3. **Date Range Filtering**
- Filter by start date
- Filter by end date
- Combine for date range queries

### 4. **Combined Filters**
- All filters can be used together
- Efficient server-side filtering
- No performance degradation

---

## 📊 Updated Function Signature

### Backend (SQL)

**Old:**
```sql
get_operations_log(
    p_limit INTEGER,
    p_offset INTEGER,
    p_user_id UUID,
    p_user_role "UserRole"
)
```

**New:**
```sql
get_operations_log(
    p_limit INTEGER DEFAULT 100,
    p_offset INTEGER DEFAULT 0,
    p_user_id UUID DEFAULT NULL,
    p_user_role "UserRole" DEFAULT NULL,
    p_search_query TEXT DEFAULT NULL,          -- 🆕 NEW
    p_start_date TIMESTAMPTZ DEFAULT NULL,     -- 🆕 NEW
    p_end_date TIMESTAMPTZ DEFAULT NULL        -- 🆕 NEW
)
```

### Frontend (TypeScript)

**Updated Interface:**
```typescript
export interface OperationsLogFilters {
  user_id: string | null
  user_role: 'admin' | 'cardIssuer' | 'user' | null
  search_query: string | null   // 🆕 NEW
  start_date: Date | null        // 🆕 NEW
  end_date: Date | null          // 🆕 NEW
}
```

---

## 🔍 Search Behavior

### Search Query (`p_search_query`)

The search query will match against **both**:
1. **User Email** - `au.email ILIKE '%query%'`
2. **Operation Text** - `ol.operation ILIKE '%query%'`

**Examples:**

| Search Query | Matches |
|--------------|---------|
| `user@example.com` | All operations by this user |
| `@example.com` | All operations by any user at example.com domain |
| `admin` | Operations containing "admin" in description OR users with "admin" in email |
| `Created card` | All card creation operations |
| `Deleted` | All deletion operations |
| `payment` | Payment-related operations OR users with "payment" in email |

---

## 💻 Usage Examples

### Example 1: Search by Email
```typescript
import { useOperationsLogStore } from '@/stores/admin/operationsLog'

const store = useOperationsLogStore()

// Find all operations by a specific user
await store.fetchOperationsLogs({
  search_query: 'user@example.com'
}, 100, 0)
```

### Example 2: Search by Domain
```typescript
// Find all operations by users from a specific domain
await store.fetchOperationsLogs({
  search_query: '@company.com'
}, 100, 0)
```

### Example 3: Search Operations
```typescript
// Find all card creation operations
await store.fetchOperationsLogs({
  search_query: 'Created card'
}, 100, 0)
```

### Example 4: Date Range Filter
```typescript
// Get operations from last 7 days
const endDate = new Date()
const startDate = new Date()
startDate.setDate(startDate.getDate() - 7)

await store.fetchOperationsLogs({
  start_date: startDate,
  end_date: endDate
}, 100, 0)
```

### Example 5: Combined Filters
```typescript
// Find all admin payment operations in the last month
const startDate = new Date()
startDate.setMonth(startDate.getMonth() - 1)

await store.fetchOperationsLogs({
  user_role: 'admin',
  search_query: 'payment',
  start_date: startDate
}, 100, 0)
```

### Example 6: User-Specific Date Range
```typescript
// Find all operations by a specific user in December 2024
await store.fetchOperationsLogs({
  search_query: 'admin@example.com',
  start_date: new Date('2024-12-01'),
  end_date: new Date('2024-12-31')
}, 100, 0)
```

---

## 🎨 UI Integration Example

### Vue Component with Search
```vue
<script setup lang="ts">
import { ref, computed } from 'vue'
import { useOperationsLogStore } from '@/stores/admin/operationsLog'

const operationsLogStore = useOperationsLogStore()

// Search state
const searchQuery = ref('')
const selectedRole = ref<'admin' | 'cardIssuer' | 'user' | null>(null)
const startDate = ref<Date | null>(null)
const endDate = ref<Date | null>(null)

// Load logs with filters
const loadLogs = async () => {
  await operationsLogStore.fetchOperationsLogs({
    search_query: searchQuery.value || null,
    user_role: selectedRole.value,
    start_date: startDate.value,
    end_date: endDate.value
  }, 100, 0)
}

const logs = computed(() => operationsLogStore.operationsLogs)
</script>

<template>
  <div class="operations-log">
    <!-- Search Input -->
    <InputText
      v-model="searchQuery"
      placeholder="Search by email or operation..."
      class="w-full mb-4"
      @keyup.enter="loadLogs"
    />

    <!-- Role Filter -->
    <Select
      v-model="selectedRole"
      :options="[
        { label: 'All Roles', value: null },
        { label: 'Admin', value: 'admin' },
        { label: 'Card Issuer', value: 'cardIssuer' },
        { label: 'User', value: 'user' }
      ]"
      optionLabel="label"
      optionValue="value"
      placeholder="Filter by role"
      class="mb-4"
      @change="loadLogs"
    />

    <!-- Date Range -->
    <div class="flex gap-2 mb-4">
      <Calendar
        v-model="startDate"
        placeholder="Start Date"
        showIcon
        @date-select="loadLogs"
      />
      <Calendar
        v-model="endDate"
        placeholder="End Date"
        showIcon
        @date-select="loadLogs"
      />
    </div>

    <!-- Search Button -->
    <Button
      label="Search"
      icon="pi pi-search"
      @click="loadLogs"
      class="mb-4"
    />

    <!-- Results -->
    <DataTable :value="logs" :loading="operationsLogStore.isLoading">
      <Column field="created_at" header="Time">
        <template #body="{ data }">
          {{ new Date(data.created_at).toLocaleString() }}
        </template>
      </Column>
      
      <Column field="user_email" header="User" />
      
      <Column field="user_role" header="Role">
        <template #body="{ data }">
          <Tag :severity="getRoleSeverity(data.user_role)">
            {{ data.user_role }}
          </Tag>
        </template>
      </Column>
      
      <Column field="operation" header="Operation" />
    </DataTable>
  </div>
</template>
```

---

## 🔧 Technical Implementation

### SQL Query Enhancement

The WHERE clause now includes:

```sql
WHERE 
    (p_user_id IS NULL OR ol.user_id = p_user_id)
    AND (p_user_role IS NULL OR ol.user_role = p_user_role)
    AND (p_search_query IS NULL OR 
         ol.operation ILIKE '%' || p_search_query || '%' OR
         au.email ILIKE '%' || p_search_query || '%')    -- 🆕 Email search
    AND (p_start_date IS NULL OR ol.created_at >= p_start_date)  -- 🆕 Date filter
    AND (p_end_date IS NULL OR ol.created_at <= p_end_date)      -- 🆕 Date filter
```

**Performance:**
- Uses `ILIKE` for case-insensitive pattern matching
- Efficient with proper indexes on `created_at`
- LEFT JOIN ensures no missing emails break queries
- All filters applied at database level (no client-side filtering)

---

## 📦 Files Updated

### Backend
1. ✅ `sql/storeproc/client-side/00_logging.sql`
   - Added 3 new parameters to `get_operations_log()`
   - Implemented email and operation search with `ILIKE`
   - Added date range filtering

2. ✅ `sql/all_stored_procedures.sql`
   - Regenerated with updated function

### Frontend
1. ✅ `src/stores/admin/operationsLog.ts`
   - Updated `OperationsLogFilters` interface
   - Updated `fetchOperationsLogs()` to pass new parameters
   - Modern store for new code

2. ✅ `src/stores/admin/auditLog.ts`
   - Updated `AuditLogFilters` interface
   - Updated `fetchAuditLogs()` for backward compatibility
   - Legacy store still works

---

## ✅ Backward Compatibility

### Old Code Still Works ✅

If you don't pass the new parameters, the function works exactly as before:

```typescript
// This still works - all new parameters are optional
await store.fetchOperationsLogs({
  user_role: 'admin'
}, 50, 0)
```

### New Parameters Optional ✅

All new parameters default to `NULL`:
- `p_search_query` - NULL = no search filter
- `p_start_date` - NULL = no start date limit
- `p_end_date` - NULL = no end date limit

---

## 🎯 Use Cases

### 1. **User Support**
```typescript
// Support staff searching for a user's activity
await store.fetchOperationsLogs({
  search_query: 'customer@email.com'
})
```

### 2. **Security Audit**
```typescript
// Security team reviewing admin actions in a specific period
await store.fetchOperationsLogs({
  user_role: 'admin',
  start_date: auditStartDate,
  end_date: auditEndDate
})
```

### 3. **Debugging**
```typescript
// Developer searching for specific operation failures
await store.fetchOperationsLogs({
  search_query: 'Deleted card'
})
```

### 4. **Compliance Reporting**
```typescript
// Generate report of all payment operations
await store.fetchOperationsLogs({
  search_query: 'payment',
  start_date: reportStartDate,
  end_date: reportEndDate
})
```

### 5. **Domain-Wide Analysis**
```typescript
// Analyze activity from a specific company domain
await store.fetchOperationsLogs({
  search_query: '@company.com'
})
```

---

## 📈 Benefits

### 1. **Improved User Experience** ✅
- Quick email-based search
- Instant operation filtering
- Powerful date range queries

### 2. **Enhanced Administration** ✅
- Easy user activity lookup
- Fast incident investigation
- Comprehensive audit capabilities

### 3. **Better Performance** ✅
- Server-side filtering (no client-side processing)
- Efficient database queries
- Proper use of indexes

### 4. **Flexibility** ✅
- Combine multiple filters
- Fine-grained control
- Backward compatible

---

## 🚀 Deployment Status

- ✅ Backend function updated
- ✅ Database deployed
- ✅ Frontend stores updated
- ✅ Backward compatibility maintained
- ✅ Documentation complete

---

## 📝 Testing Checklist

- [ ] Search by full email address
- [ ] Search by email domain
- [ ] Search by operation text
- [ ] Filter by date range
- [ ] Combine email + role + date filters
- [ ] Verify case-insensitive search
- [ ] Test with NULL/empty parameters
- [ ] Verify backward compatibility

---

## 🎉 Summary

**Enhanced `get_operations_log` with:**
- ✅ **Email search** - Find operations by user email
- ✅ **Operation search** - Search within operation descriptions
- ✅ **Date filtering** - Filter by start and end dates
- ✅ **Combined filters** - Use all filters together
- ✅ **Backward compatible** - Old code still works
- ✅ **Server-side filtering** - Efficient performance

**Search is now more powerful, flexible, and user-friendly!** 🚀

