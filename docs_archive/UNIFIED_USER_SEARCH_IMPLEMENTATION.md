# Unified User Search Across All Tabs - Admin Credit Management

## Overview
Implemented a unified user search system that filters ALL tabs (User Balances, Purchases, Consumptions, and All Transactions) to show records for a single selected user. This makes it easy for admins to view all credit-related activity for any specific user.

## How It Works

### User Workflow
1. **Use the global search bar** above all tabs to search for a user (by name or email)
2. **Click on a user row** in the User Balances tab to select them
3. **All tabs automatically filter** to show only that user's records
4. **Visual confirmation**:
   - Selected user row is highlighted in blue
   - Banner appears at the top showing who is being filtered
   - Each tab shows an info message confirming the filter
   - Search bar shows result count
5. **Click the selected user again** or **"Clear Filter" button** to deselect and show all data

## Features Implemented

### 1. **Global Search Bar (Above All Tabs)**
- ✅ Prominent search input at the top
- ✅ Clear label: "Search User (applies to all tabs)"
- ✅ Large input field for better visibility
- ✅ Shows result count when searching
- ✅ Helpful hint text when not searching
- ✅ "Adjust Credits" button positioned next to search
- ✅ Quick "Clear Filter" button when results are shown

### 2. **User Balances Tab**
- ✅ Server-side search by name or email
- ✅ Clickable rows to select a user
- ✅ Selected row highlighted in blue
- ✅ Hover effect on all rows
- ✅ Server-side pagination and sorting

### 3. **Active Filter Banner**
- ✅ Appears at the top when a user is selected
- ✅ Shows the selected user's name
- ✅ "Clear Filter" button to reset
- ✅ Smooth slide-fade animation

### 4. **Filtered Tabs**
All three data tabs (Purchases, Consumptions, Transactions) now:
- ✅ Auto-reload when a user is selected
- ✅ Display info message showing who is filtered
- ✅ Show contextual empty states
- ✅ Pass `user_id` filter to stored procedures

### 5. **Visual Feedback**
- ✅ Blue banner at top when filtering
- ✅ Blue row highlight for selected user
- ✅ Info messages in each tab
- ✅ Contextual empty state messages
- ✅ Hover effects on clickable rows

## Technical Implementation

### Component State
```typescript
const selectedUserId = ref<string | null>(null)      // ID of selected user
const selectedUserName = ref<string | null>(null)    // Name for display
const isFilteringByUser = computed(() => !!selectedUserId.value)
```

### User Selection Handler
```typescript
function onUserRowClick(event: any) {
  const user = event.data
  if (selectedUserId.value === user.user_id) {
    clearUserFilter()  // Deselect if clicking same user
  } else {
    selectedUserId.value = user.user_id
    selectedUserName.value = user.user_name
  }
}
```

### Auto-Reload on Filter Change
```typescript
watch(selectedUserId, async () => {
  await loadAllTabsData()  // Reload all tabs with new filter
})
```

### Load All Tabs Data
```typescript
async function loadAllTabsData() {
  await Promise.all([
    adminCreditStore.fetchCreditPurchases(100, 0, selectedUserId.value || undefined),
    adminCreditStore.fetchCreditConsumptions(100, 0, selectedUserId.value || undefined),
    adminCreditStore.fetchCreditTransactions(100, 0, selectedUserId.value || undefined)
  ])
}
```

### Row Highlighting
```typescript
function getUserRowClass(data: any) {
  return selectedUserId.value === data.user_id ? 'bg-blue-100 font-semibold' : ''
}
```

### DataTable Configuration
```vue
<DataTable 
  selectionMode="single"
  @row-click="onUserRowClick"
  :rowClass="getUserRowClass"
  :pt="{
    row: {
      class: 'cursor-pointer hover:bg-blue-50 transition-colors'
    }
  }"
/>
```

## Layout Design

### Global Search Bar Positioning
The search bar is positioned **above all tabs** for several UX benefits:

1. **Visibility**: Immediately visible when the page loads
2. **Context**: Clear label indicates it applies to all tabs
3. **Accessibility**: Always accessible regardless of active tab
4. **Logic Flow**: Search → Select User → View Filtered Data
5. **Consistency**: Matches common admin dashboard patterns

### Layout Structure
```
┌─────────────────────────────────────────────┐
│  Active Filter Banner (when user selected)  │
├─────────────────────────────────────────────┤
│  System Statistics Cards                    │
├─────────────────────────────────────────────┤
│  🔍 Global Search Bar                       │
│  Search User (applies to all tabs)          │
│  [Search Input] [Adjust Credits Button]     │
│  Result count / Hint text                   │
├─────────────────────────────────────────────┤
│  [User Balances] [Purchases] [Consumptions] [Transactions]
│  ───────────────────────────────────────────
│  Tab Content (filtered by search/selection) │
└─────────────────────────────────────────────┘
```

**Note**: Top Credit Users table has been removed for a cleaner, more focused interface.

## UI Components Used

### Global Search Bar
```vue
<div class="bg-white rounded-xl shadow-lg border border-slate-200 p-6">
  <div class="space-y-3">
    <div class="flex justify-between items-center gap-4">
      <div class="flex-1 max-w-2xl">
        <label class="block text-sm font-semibold text-slate-700 mb-2">
          Search User (applies to all tabs)
        </label>
        <InputText 
          v-model="userFilter" 
          placeholder="Search by name or email"
          class="w-full"
          size="large"
        />
      </div>
      <div class="flex flex-col gap-2 pt-6">
        <Button
          icon="pi pi-plus"
          label="Adjust Credits"
          @click="showAdjustDialog = true"
          severity="success"
        />
      </div>
    </div>
    <!-- Result count when searching -->
    <div v-if="userFilter && filteredUsersCount !== null">
      <i class="pi pi-filter"></i>
      Showing {{ filteredUsersCount }} of {{ adminCreditStore.totalRecords }} users
      <Button label="Clear" @click="userFilter = ''" />
    </div>
    <!-- Hint text when not searching -->
    <div v-if="!userFilter" class="text-sm text-slate-500 italic">
      <i class="pi pi-info-circle mr-1"></i>
      Search for a user by name or email, then click on their row to filter all tabs
    </div>
  </div>
</div>
```

**Note**: The search input is now cleaner without the redundant search icon.

### Filter Banner
```vue
<Transition name="slide-fade">
  <div v-if="isFilteringByUser" class="bg-blue-50 border-2 border-blue-200 rounded-xl p-4">
    <div class="flex items-center justify-between">
      <div class="flex items-center gap-3">
        <div class="w-10 h-10 rounded-full bg-blue-500">
          <i class="pi pi-filter text-white"></i>
        </div>
        <div>
          <p class="text-sm font-medium text-blue-900">Filtering all tabs for user:</p>
          <p class="text-lg font-bold text-blue-700">{{ selectedUserName }}</p>
        </div>
      </div>
      <Button label="Clear Filter" @click="clearUserFilter" />
    </div>
  </div>
</Transition>
```

### Tab Info Messages
```vue
<Message v-if="isFilteringByUser" severity="info" :closable="false" class="mb-4">
  <i class="pi pi-info-circle mr-2"></i>
  Showing purchases for <strong>{{ selectedUserName }}</strong> only
</Message>
```

### Contextual Empty States
```vue
<template #empty>
  <div class="text-center py-12">
    <i class="pi pi-shopping-bag text-6xl text-slate-400 mb-4"></i>
    <p class="text-lg font-medium text-slate-900 mb-2">
      {{ isFilteringByUser ? 'No purchases for this user' : 'No purchases yet' }}
    </p>
    <p class="text-slate-600">
      {{ isFilteringByUser ? 'This user has not made any credit purchases' : 'Credit purchases will appear here' }}
    </p>
  </div>
</template>
```

## Stored Procedure Updates

### User Balances (Pagination + Search)
```sql
CREATE OR REPLACE FUNCTION admin_get_user_credits(
    p_limit INTEGER DEFAULT 20,
    p_offset INTEGER DEFAULT 0,
    p_search TEXT DEFAULT NULL,
    p_sort_field TEXT DEFAULT 'balance',
    p_sort_order TEXT DEFAULT 'DESC'
)
```
- ✅ Server-side search by email/name
- ✅ Server-side pagination
- ✅ Server-side sorting
- ✅ Returns total count for pagination

### Other Tabs (Simple Filtering)
```sql
CREATE OR REPLACE FUNCTION admin_get_credit_purchases(
    p_limit INTEGER DEFAULT 50,
    p_offset INTEGER DEFAULT 0,
    p_user_id UUID DEFAULT NULL,  -- Filter by user
    p_status VARCHAR DEFAULT NULL
)
```
- ✅ Filter by `p_user_id` when provided
- ✅ Show all records when `p_user_id` is NULL

## CSS Animations

```css
/* Filter Banner Animation */
.slide-fade-enter-active {
  transition: all 0.3s ease-out;
}

.slide-fade-leave-active {
  transition: all 0.2s ease-in;
}

.slide-fade-enter-from,
.slide-fade-leave-to {
  transform: translateY(-10px);
  opacity: 0;
}

/* Selected Row Highlight */
:deep(.bg-blue-100) {
  background-color: rgb(219, 234, 254) !important;
}
```

## User Experience Improvements

### Before
- ❌ No way to view all records for a specific user
- ❌ Had to manually search in each tab
- ❌ Difficult to track user activity across tabs
- ❌ No visual indication of which user you're viewing

### After
- ✅ One-click user selection
- ✅ All tabs auto-filter simultaneously
- ✅ Clear visual feedback (banner + highlights)
- ✅ Easy to switch between users
- ✅ Quick clear filter option
- ✅ Contextual empty states
- ✅ Smooth animations

## Testing Checklist

- [ ] Search for a user by name
- [ ] Search for a user by email
- [ ] Click on a user row to select them
- [ ] Verify banner appears at top
- [ ] Check User Balances tab shows selected row highlighted
- [ ] Check Purchases tab filters to show only that user's purchases
- [ ] Check Consumptions tab filters to show only that user's consumptions
- [ ] Check All Transactions tab filters to show only that user's transactions
- [ ] Click the selected user row again to deselect
- [ ] Verify banner disappears
- [ ] Verify all tabs show all data again
- [ ] Click "Clear Filter" button on banner
- [ ] Try selecting different users
- [ ] Check empty states when user has no records in a tab
- [ ] Verify info messages appear in each tab when filtering
- [ ] Test pagination still works in User Balances tab
- [ ] Test sorting still works in User Balances tab

## Performance Considerations

1. **Lazy Loading**: Tabs only load when user is selected or on initial mount
2. **Efficient Queries**: Stored procedures use indexed columns for filtering
3. **Debounced Search**: 500ms debounce prevents excessive queries during typing
4. **Batch Loading**: All tabs load in parallel with `Promise.all()`
5. **Reasonable Limits**: Non-paginated tabs limited to 100 records per query

## Files Modified

1. **Component**: `src/views/Dashboard/Admin/AdminCreditManagement.vue`
   - Added user selection state
   - Added row click handlers
   - Added filter banner
   - Added info messages to tabs
   - Added contextual empty states
   - Added CSS animations
   - Removed Top Credit Users table
   - Removed search icon from input
   - Moved search bar above all tabs

2. **Stored Procedure**: `sql/storeproc/client-side/admin_credit_management.sql`
   - Updated `admin_get_user_credits` with pagination and search
   - Updated `admin_get_credit_statistics` - removed `top_credit_users` field

3. **Store**: `src/stores/admin/credits.ts`
   - Updated `fetchUserCredits` to support pagination and search
   - Updated `CreditSystemStatistics` interface - removed `top_credit_users` field
   - Other fetch methods already support `user_id` filtering

## Future Enhancements

- [ ] Add keyboard shortcuts (ESC to clear filter)
- [ ] Add URL query params to preserve filter on page reload
- [ ] Add "View all records" link in filtered tabs
- [ ] Add user profile quick view on hover
- [ ] Add export filtered data option
- [ ] Add bookmark/favorite users
- [ ] Add recent searches history

## Deployment

No additional deployment steps needed beyond the standard:
1. Deploy updated stored procedures (already done with previous deployment)
2. Deploy frontend changes (already in place)

The system is backward compatible - works with both old and new stored procedure signatures.

