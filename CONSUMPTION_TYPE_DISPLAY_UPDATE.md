# Consumption Type Display Update

## Overview
Updated the credit consumption history tables to properly display and distinguish between different consumption types (batch issuance vs translation) instead of showing all consumptions as "Batch Issuance".

## Problem
The consumption history tables in both `CreditManagement.vue` (user-facing) and `AdminCreditManagement.vue` (admin-facing) were hardcoded to display "Batch Issuance" for all consumption records, even though the database already tracks different consumption types like:
- `batch_issuance` - Card batch issuance (2 credits per card)
- `translation` - AI-powered translation (1 credit per language)
- `single_card` - Single card issuance (if applicable)

## Solution
Implemented dynamic consumption type display with appropriate icons, labels, and color coding.

---

## Changes Made

### 1. Updated CreditManagement.vue (User-Facing)

**File**: `src/views/Dashboard/CardIssuer/CreditManagement.vue`

#### A. Dynamic Consumption Type Column
**Before**:
```vue
<Column field="consumption_type" :header="$t('common.type')" style="min-width: 150px">
  <template #body="{ data }">
    <Tag value="Batch Issuance" icon="pi pi-box" severity="info" />
  </template>
</Column>
```

**After**:
```vue
<Column field="consumption_type" :header="$t('common.type')" sortable style="min-width: 180px">
  <template #body="{ data }">
    <Tag 
      :value="getConsumptionTypeLabel(data.consumption_type)" 
      :icon="getConsumptionTypeIcon(data.consumption_type)" 
      :severity="getConsumptionTypeSeverity(data.consumption_type)" 
    />
  </template>
</Column>
```

#### B. Context-Aware Quantity Column
**Before**:
```vue
<Column field="quantity" :header="$t('batch.quantity')" sortable style="min-width: 120px">
  <template #body="{ data }">
    <Chip :label="String(data.quantity)" icon="pi pi-hashtag" />
  </template>
</Column>
```

**After**:
```vue
<Column field="quantity" :header="$t('common.quantity')" sortable style="min-width: 140px">
  <template #body="{ data }">
    <Chip 
      :label="`${data.quantity} ${getQuantityUnit(data.consumption_type)}`" 
      icon="pi pi-hashtag" 
    />
  </template>
</Column>
```

#### C. Updated Empty State Message
**Before**:
```html
<p class="text-slate-600">Credit consumption records will appear here after issuing batches</p>
```

**After**:
```html
<p class="text-slate-600">Credit consumption records will appear here after issuing batches or translating cards</p>
```

#### D. Added Helper Functions
```typescript
function getConsumptionTypeLabel(type: string) {
  switch (type) {
    case 'batch_issuance': return 'Batch Issuance'
    case 'translation': return 'Translation'
    case 'single_card': return 'Single Card'
    default: return type || 'Unknown'
  }
}

function getConsumptionTypeIcon(type: string) {
  switch (type) {
    case 'batch_issuance': return 'pi-box'
    case 'translation': return 'pi-language'
    case 'single_card': return 'pi-id-card'
    default: return 'pi-circle'
  }
}

function getConsumptionTypeSeverity(type: string) {
  switch (type) {
    case 'batch_issuance': return 'info'
    case 'translation': return 'success'
    case 'single_card': return 'warn'
    default: return undefined
  }
}

function getQuantityUnit(type: string) {
  switch (type) {
    case 'batch_issuance': return 'cards'
    case 'translation': return 'languages'
    case 'single_card': return 'card'
    default: return 'units'
  }
}
```

---

### 2. Updated AdminCreditManagement.vue (Admin-Facing)

**File**: `src/views/Dashboard/Admin/AdminCreditManagement.vue`

#### A. Added Consumption Type Column
Added a new column before the "Card" column to display the consumption type:

```vue
<Column field="consumption_type" :header="$t('common.type')" sortable style="min-width: 180px">
  <template #body="{ data }">
    <Tag 
      :value="getConsumptionTypeLabel(data.consumption_type)" 
      :icon="getConsumptionTypeIcon(data.consumption_type)" 
      :severity="getConsumptionTypeSeverity(data.consumption_type)" 
    />
  </template>
</Column>
```

#### B. Updated Quantity Column
Same as CreditManagement.vue - now shows context-aware units (cards/languages).

#### C. Added Helper Functions
Same helper functions as CreditManagement.vue.

---

## Visual Design

### Consumption Type Tags

| Type | Label | Icon | Color |
|------|-------|------|-------|
| `batch_issuance` | Batch Issuance | `pi-box` | Blue (info) |
| `translation` | Translation | `pi-language` | Green (success) |
| `single_card` | Single Card | `pi-id-card` | Amber (warn) |

### Quantity Display

| Type | Example Display |
|------|----------------|
| `batch_issuance` | "10 cards" |
| `translation` | "3 languages" |
| `single_card` | "1 card" |

---

## Database Schema

The `credit_consumptions` table already has the necessary fields:

```sql
CREATE TABLE IF NOT EXISTS credit_consumptions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    batch_id UUID REFERENCES card_batches(id) ON DELETE SET NULL,
    card_id UUID REFERENCES cards(id) ON DELETE SET NULL,
    consumption_type VARCHAR(50) NOT NULL DEFAULT 'batch_issuance', -- 'batch_issuance', 'single_card', 'translation', etc.
    quantity INTEGER NOT NULL DEFAULT 1, -- Number of cards or languages
    credits_per_unit DECIMAL(10, 2) NOT NULL DEFAULT 2.00, -- Credits per card (2.00) or per language (1.00)
    total_credits DECIMAL(10, 2) NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);
```

---

## Stored Procedures

Both stored procedures already return the `consumption_type` field:

### User-Facing: `get_credit_consumptions()`
```sql
RETURNS TABLE (
    id UUID,
    batch_id UUID,
    card_id UUID,
    consumption_type VARCHAR,
    quantity INTEGER,
    credits_per_unit DECIMAL,
    total_credits DECIMAL,
    description TEXT,
    created_at TIMESTAMPTZ,
    batch_name TEXT,
    card_name TEXT
)
```

### Admin-Facing: `admin_get_credit_consumptions()`
```sql
RETURNS TABLE (
    id UUID,
    user_id UUID,
    user_email TEXT,
    user_name TEXT,
    batch_id UUID,
    batch_name TEXT,
    card_id UUID,
    card_name TEXT,
    consumption_type VARCHAR,
    quantity INTEGER,
    credits_per_unit DECIMAL,
    total_credits DECIMAL,
    description TEXT,
    created_at TIMESTAMPTZ
)
```

**No database changes needed** - the field was already being returned but not displayed properly.

---

## User Experience Improvements

### Before
- ❌ All consumptions showed as "Batch Issuance"
- ❌ No way to distinguish between batch and translation consumptions
- ❌ Quantity always showed as generic number
- ❌ Empty state only mentioned batch issuance

### After
- ✅ Clear visual distinction between consumption types
- ✅ Color-coded tags for quick identification
- ✅ Context-aware quantity labels (cards vs languages)
- ✅ Appropriate icons for each consumption type
- ✅ Empty state mentions both batch and translation
- ✅ Sortable type column for easy filtering

---

## Testing Checklist

### User-Facing (CreditManagement.vue)
- [ ] Create a card batch → Verify shows as "Batch Issuance" with blue tag
- [ ] Translate a card → Verify shows as "Translation" with green tag
- [ ] Check quantity shows "X cards" for batches
- [ ] Check quantity shows "X languages" for translations
- [ ] Verify empty state message mentions both operations
- [ ] Test column sorting by type

### Admin-Facing (AdminCreditManagement.vue)
- [ ] Open admin credit management page
- [ ] Click "View Consumptions" for a user
- [ ] Verify type column appears with correct tags
- [ ] Verify quantity shows appropriate units
- [ ] Check that all consumption types display correctly
- [ ] Test column sorting by type

---

## Files Modified

1. **`src/views/Dashboard/CardIssuer/CreditManagement.vue`**
   - Lines 271-278: Updated consumption_type column
   - Lines 293-299: Updated quantity column
   - Line 262: Updated empty state message
   - Lines 546-583: Added helper functions

2. **`src/views/Dashboard/Admin/AdminCreditManagement.vue`**
   - Lines 385-393: Added consumption_type column
   - Lines 407-414: Updated quantity column
   - Lines 788-822: Added helper functions

---

## Future Enhancements

### Potential Additions
1. **Filter by Consumption Type**: Add dropdown filter to show only batches or translations
2. **Usage Analytics**: Charts showing breakdown of consumption by type
3. **Cost Comparison**: Show average cost per consumption type
4. **Export Options**: Export consumption history with type filtering

### Additional Consumption Types
If new consumption types are added in the future (e.g., `ai_training`, `api_calls`), simply:
1. Add new case to helper functions
2. Choose appropriate icon, label, and color
3. Add corresponding unit in `getQuantityUnit()`

---

## Related Features

- **Credit System**: Core credit management functionality
- **Translation System**: AI-powered translation (1 credit per language)
- **Batch Issuance**: Card batch creation (2 credits per card)
- **Audit Trail**: All operations logged in `credit_transactions` table

---

## Deployment

### No Database Changes Needed ✅
The `consumption_type` field already exists and is being populated correctly.

### Frontend Only ✅
Simply deploy the updated Vue components:
```bash
npm run build
# Deploy dist/ to hosting
```

### Verification
After deployment:
1. Check existing consumption records display correctly
2. Create new batch → Verify shows as "Batch Issuance"
3. Create new translation → Verify shows as "Translation"
4. Verify both user and admin views work correctly

---

## Impact

- **User Clarity**: Users can now distinguish between different credit usage types
- **Admin Oversight**: Admins can better track and understand credit consumption patterns
- **Data Accuracy**: Display now matches the actual database records
- **Future Scalability**: Easy to add new consumption types as system evolves

---

**Status**: ✅ Complete and Ready for Testing
**Complexity**: Low (UI-only changes)
**Risk**: Very Low (no database changes, backward compatible)
**Testing**: Required before production deployment

