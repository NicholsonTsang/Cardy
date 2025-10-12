# Table Style Audit & Standardization Plan

## Overview
Comprehensive audit of all DataTable components in the project to standardize visual layout, fonts, and styling based on the **Credit Purchase History table** in Card Issuer Dashboard as the reference standard.

---

## Reference Standard

**File**: `src/views/Dashboard/CardIssuer/CreditManagement.vue`  
**Table**: Purchase History / All Transactions tabs

### Key Style Characteristics
```vue
<DataTable 
  :value="data"
  :loading="loading"
  paginator 
  :rows="10" 
  :rowsPerPageOptions="[10, 20, 50]"
  showGridlines
  responsiveLayout="scroll"
>
  <!-- Empty State -->
  <template #empty>
    <div class="text-center py-12">
      <i class="pi pi-inbox text-6xl text-slate-400 mb-4"></i>
      <p class="text-lg font-medium text-slate-900 mb-2">Title</p>
      <p class="text-slate-600">Description</p>
    </div>
  </template>
  
  <!-- Loading State -->
  <template #loading>
    <div class="flex items-center justify-center py-12">
      <ProgressSpinner style="width: 50px; height: 50px" strokeWidth="4" />
    </div>
  </template>
  
  <!-- Date Column -->
  <Column field="created_at" :header="$t('common.date')" sortable style="min-width: 180px">
    <template #body="{ data }">
      <span class="text-sm text-slate-600">{{ formatDate(data.created_at) }}</span>
    </template>
  </Column>
  
  <!-- Status Column -->
  <Column field="type" :header="$t('common.type')" sortable style="min-width: 140px">
    <template #body="{ data }">
      <Tag 
        :severity="getTypeSeverity(data.type)" 
        :value="$t(`credits.type.${data.type}`)"
        :icon="getTypeIcon(data.type)"
      />
    </template>
  </Column>
  
  <!-- Amount Column -->
  <Column field="amount" :header="$t('credits.amount')" sortable style="min-width: 130px">
    <template #body="{ data }">
      <div class="flex items-center gap-2 font-semibold text-base">
        <i class="pi pi-plus-circle text-green-600"></i>
        <span class="text-green-600">+{{ data.amount.toFixed(2) }}</span>
      </div>
    </template>
  </Column>
  
  <!-- Chip Column -->
  <Column field="balance" :header="$t('credits.balance')" sortable style="min-width: 140px">
    <template #body="{ data }">
      <Chip :label="data.balance.toFixed(2)" icon="pi pi-wallet" />
    </template>
  </Column>
  
  <!-- Description Column -->
  <Column field="description" :header="$t('common.description')" style="min-width: 250px">
    <template #body="{ data }">
      <span class="text-slate-600">{{ data.description || '-' }}</span>
    </template>
  </Column>
</DataTable>
```

---

## Audit Results

### ✅ 1. CreditManagement.vue (Card Issuer)
**File**: `src/views/Dashboard/CardIssuer/CreditManagement.vue`  
**Tables**: 3 (All Transactions, Purchase History, Consumption History)

**Status**: ✅ **REFERENCE STANDARD - Perfect**

**Characteristics**:
- ✅ showGridlines
- ✅ responsiveLayout="scroll"
- ✅ :rowsPerPageOptions="[10, 20, 50]"
- ✅ min-width on all columns
- ✅ Empty state: text-6xl icon, py-12 padding
- ✅ Loading state: ProgressSpinner 50px
- ✅ Date columns: text-sm text-slate-600
- ✅ Tags with severity and icons
- ✅ Amount columns: font-semibold text-base with icons
- ✅ Chip components for numeric values
- ✅ Description columns: text-slate-600

---

### ⚠️ 2. AdminCreditManagement.vue
**File**: `src/views/Dashboard/Admin/AdminCreditManagement.vue`  
**Tables**: 4 (User Balances, Purchases, Consumptions, Transactions)

**Issues Found**:
1. ❌ Missing `responsiveLayout="scroll"` on main table
2. ❌ Empty state icon size: `text-4xl` → should be `text-6xl`
3. ⚠️ Empty state padding: `py-8` → should be `py-12`

**Recommendations**:
```vue
<!-- BEFORE -->
<DataTable 
  :value="data"
  showGridlines
  stripedRows
>
  <template #empty>
    <div class="text-center py-8">
      <i class="pi pi-inbox text-4xl text-slate-400 mb-4"></i>
      ...
    </div>
  </template>
</DataTable>

<!-- AFTER -->
<DataTable 
  :value="data"
  showGridlines
  stripedRows
  responsiveLayout="scroll"
>
  <template #empty>
    <div class="text-center py-12">
      <i class="pi pi-inbox text-6xl text-slate-400 mb-4"></i>
      ...
    </div>
  </template>
</DataTable>
```

---

### ⚠️ 3. BatchManagement.vue
**File**: `src/views/Dashboard/Admin/BatchManagement.vue`  
**Tables**: 1 (All Batches)

**Issues Found**:
1. ❌ Missing `responsiveLayout="scroll"`
2. ❌ Missing `:rowsPerPageOptions` (defaults are not clear)
3. ❌ Empty state icon size: `text-4xl` → should be `text-6xl`
4. ⚠️ Empty state padding: `py-8` → should be `py-12`
5. ❌ No `min-width` on columns
6. ⚠️ :rows="25" (inconsistent - should be 10 or 20 with options)

**Recommendations**:
```vue
<!-- BEFORE -->
<DataTable 
  :value="batchesStore.allBatches"
  paginator 
  :rows="25"
  dataKey="id"
  showGridlines
  stripedRows
>
  <Column field="batch_number" header="Batch #" sortable>
    ...
  </Column>

<!-- AFTER -->
<DataTable 
  :value="batchesStore.allBatches"
  paginator 
  :rows="20"
  :rowsPerPageOptions="[10, 20, 50]"
  dataKey="id"
  showGridlines
  stripedRows
  responsiveLayout="scroll"
>
  <Column field="batch_number" header="Batch #" sortable style="min-width: 140px">
    ...
  </Column>
```

---

### ⚠️ 4. PrintRequestManagement.vue
**File**: `src/views/Dashboard/Admin/PrintRequestManagement.vue`  
**Tables**: 1 (Print Requests)

**Issues Found**:
1. ❌ Missing `showGridlines`
2. ❌ Empty state icon size: `text-4xl` → should be `text-6xl`
3. ⚠️ Empty state padding: `py-8` → should be `py-12`

**Recommendations**:
```vue
<!-- BEFORE -->
<DataTable 
  :value="printRequestsStore.printRequests"
  :paginator="true" 
  :rows="20"
  :rowsPerPageOptions="[10, 20, 50]"
  responsiveLayout="scroll"
  class="border-0"
  dataKey="id"
>

<!-- AFTER -->
<DataTable 
  :value="printRequestsStore.printRequests"
  :paginator="true" 
  :rows="20"
  :rowsPerPageOptions="[10, 20, 50]"
  responsiveLayout="scroll"
  showGridlines
  class="border-0"
  dataKey="id"
>
```

---

### ⚠️ 5. UserManagement.vue
**File**: `src/views/Dashboard/Admin/UserManagement.vue`  
**Tables**: 1 (Users)

**Issues Found**:
1. ⚠️ Date column font size: `text-xs` → should be `text-sm` for consistency
2. ℹ️ Has advanced features (frozen columns, scrollable) - acceptable
3. ℹ️ Custom styling with avatars - acceptable

**Recommendations**:
```vue
<!-- BEFORE -->
<Column field="created_at" :header="$t('admin.registered')" sortable>
  <template #body="{ data }">
    <span class="text-slate-600 text-xs whitespace-nowrap">{{ formatDate(data.created_at) }}</span>
  </template>
</Column>

<!-- AFTER -->
<Column field="created_at" :header="$t('admin.registered')" sortable>
  <template #body="{ data }">
    <span class="text-slate-600 text-sm whitespace-nowrap">{{ formatDate(data.created_at) }}</span>
  </template>
</Column>
```

---

## Standardization Checklist

### DataTable Component Props
- [ ] `showGridlines` - Always include for visual clarity
- [ ] `responsiveLayout="scroll"` - Essential for mobile/small screens
- [ ] `:rowsPerPageOptions="[10, 20, 50]"` - Consistent pagination options
- [ ] `stripedRows` - Optional but recommended for readability
- [ ] `:rows="10"` or `:rows="20"` - Consistent default page size

### Empty State Template
```vue
<template #empty>
  <div class="text-center py-12">  <!-- py-12 not py-8 -->
    <i class="pi pi-[icon] text-6xl text-slate-400 mb-4"></i>  <!-- text-6xl not text-4xl -->
    <p class="text-lg font-medium text-slate-900 mb-2">{{ title }}</p>
    <p class="text-slate-600">{{ description }}</p>
  </div>
</template>
```

### Loading State Template
```vue
<template #loading>
  <div class="flex items-center justify-center py-12">
    <ProgressSpinner style="width: 50px; height: 50px" strokeWidth="4" />
  </div>
</template>
```

### Column Styling Standards

#### 1. Date Columns
```vue
<Column field="created_at" :header="$t('common.date')" sortable style="min-width: 180px">
  <template #body="{ data }">
    <span class="text-sm text-slate-600">{{ formatDate(data.created_at) }}</span>
  </template>
</Column>
```

#### 2. Status/Type Columns
```vue
<Column field="status" :header="$t('common.status')" sortable style="min-width: 140px">
  <template #body="{ data }">
    <Tag 
      :severity="getStatusSeverity(data.status)" 
      :value="$t(`path.${data.status}`)"
      :icon="getStatusIcon(data.status)"
    />
  </template>
</Column>
```

#### 3. Amount/Number Columns
```vue
<Column field="amount" :header="$t('common.amount')" sortable style="min-width: 130px">
  <template #body="{ data }">
    <div class="flex items-center gap-2 font-semibold text-base">
      <i class="pi pi-icon text-color"></i>
      <span class="text-color">{{ data.amount.toFixed(2) }}</span>
    </div>
  </template>
</Column>
```

#### 4. Badge/Chip Columns
```vue
<Column field="balance" :header="$t('common.balance')" sortable style="min-width: 140px">
  <template #body="{ data }">
    <Chip :label="data.balance.toFixed(2)" icon="pi pi-wallet" severity="success" />
  </template>
</Column>
```

#### 5. Text/Description Columns
```vue
<Column field="description" :header="$t('common.description')" style="min-width: 250px">
  <template #body="{ data }">
    <span class="text-slate-600">{{ data.description || '-' }}</span>
  </template>
</Column>
```

#### 6. ID/Reference Columns
```vue
<Column field="id" header="ID" sortable style="min-width: 120px">
  <template #body="{ data }">
    <span class="font-mono text-sm font-medium text-slate-900">
      #{{ data.id.toString().padStart(6, '0') }}
    </span>
  </template>
</Column>
```

#### 7. Name/Title Columns
```vue
<Column field="name" :header="$t('common.name')" sortable style="min-width: 200px">
  <template #body="{ data }">
    <span class="font-medium text-slate-900">{{ data.name }}</span>
  </template>
</Column>
```

---

## Color & Typography Standards

### Text Colors
- **Primary text**: `text-slate-900` - For names, titles, IDs
- **Secondary text**: `text-slate-600` - For dates, descriptions, emails
- **Placeholder**: `text-slate-400` - For empty state icons
- **Success**: `text-green-600` - For positive amounts, completed status
- **Danger**: `text-red-600` - For negative amounts, failed status
- **Warning**: `text-amber-600` - For pending, warnings

### Font Sizes
- **Small**: `text-xs` - Only for secondary labels within cells (12px)
- **Normal**: `text-sm` - Standard for all cell content (14px) ✅
- **Medium**: `text-base` - For emphasized amounts (16px)
- **Large**: `text-lg` - For empty state titles (18px)

### Font Weights
- **Regular**: No class - Default text
- **Medium**: `font-medium` - For names, titles
- **Semibold**: `font-semibold` - For amounts, emphasis
- **Bold**: `font-bold` - Rarely used

### Icon Sizes
- **Empty state**: `text-6xl` (96px) ✅
- **Regular icons**: `text-base` or inherit from parent

---

## Implementation Priority

### 🔴 High Priority (Inconsistent with Reference)
1. **BatchManagement.vue**
   - Add `responsiveLayout="scroll"`
   - Add `:rowsPerPageOptions="[10, 20, 50]"`
   - Update empty state icon to `text-6xl`
   - Update empty state padding to `py-12`
   - Add `min-width` to all columns

2. **AdminCreditManagement.vue**
   - Add `responsiveLayout="scroll"` to main table
   - Update empty state icons to `text-6xl`
   - Update empty state padding to `py-12`

3. **PrintRequestManagement.vue**
   - Add `showGridlines`
   - Update empty state icon to `text-6xl`
   - Update empty state padding to `py-12`

### 🟡 Medium Priority (Minor Inconsistencies)
4. **UserManagement.vue**
   - Update date column from `text-xs` to `text-sm`

---

## Testing Checklist

After implementing changes, verify:

- [ ] All tables have consistent visual appearance
- [ ] Gridlines are visible on all tables
- [ ] Tables scroll horizontally on small screens
- [ ] Empty states have large icons (text-6xl)
- [ ] Empty states have proper padding (py-12)
- [ ] Date columns use text-sm text-slate-600
- [ ] Status columns use Tag components consistently
- [ ] All columns have appropriate min-width
- [ ] Pagination options are consistent [10, 20, 50]
- [ ] Loading spinners are consistent (50px × 50px)

---

## Benefits of Standardization

1. **Visual Consistency**: All tables look like they belong to the same application
2. **Better UX**: Users know what to expect when they see a table
3. **Easier Maintenance**: Changes to table styling can be applied consistently
4. **Professional Appearance**: Consistent styling = polished product
5. **Accessibility**: Standard patterns are easier to navigate
6. **Responsive**: All tables will work well on mobile devices
7. **Brand Cohesion**: Consistent design language throughout the application

---

## Files to Modify

1. `src/views/Dashboard/Admin/BatchManagement.vue` - 8 changes
2. `src/views/Dashboard/Admin/AdminCreditManagement.vue` - 5 changes (1 main table + 4 dialog tables)
3. `src/views/Dashboard/Admin/PrintRequestManagement.vue` - 3 changes
4. `src/views/Dashboard/Admin/UserManagement.vue` - 1 change

**Total**: 4 files, ~17 specific changes

---

## Next Steps

1. Review this audit with the team
2. Approve standardization approach
3. Implement changes file by file
4. Test each table after changes
5. Create a shared DataTable wrapper component (optional future enhancement)

---

**Status**: 📋 Audit Complete - Ready for Implementation  
**Priority**: High - Visual consistency is important for professional product  
**Estimated Time**: 2-3 hours for all changes  
**Risk**: Low - Changes are primarily styling, no logic changes

