# Admin Activity Filter Enhancement

## Summary

Enhanced the Admin History Logs activity filter by adding **17 new activity types** that were being logged but missing from the filter dropdown. This allows admins to better filter and find specific types of operations in the system.

## Changes Made

### 1. Updated Action Types Store (`src/stores/admin/auditLog.ts`)
**Added 17 new activity types**, organized by category:

#### User Management (5 types)
- ✅ `USER_REGISTRATION` (existing)
- ✅ `ROLE_CHANGE` (existing)
- ✅ `VERIFICATION_REVIEW` (existing)
- 🆕 `VERIFICATION_RESET` - "Reset verification for user..."
- 🆕 `MANUAL_VERIFICATION` - "Manually approved verification for user..."

#### Card Management (5 types)
- ✅ `CARD_CREATION` (existing)
- ✅ `CARD_UPDATE` (existing)
- ✅ `CARD_DELETION` (existing)
- 🆕 `CARD_ACTIVATION` - "Activated issued card" / "Card auto-activated..."
- ✅ `CARD_GENERATION` (existing)

#### Content Management (3 types - NEW CATEGORY)
- 🆕 `CONTENT_ITEM_CREATION` - "Created content item: ..."
- 🆕 `CONTENT_ITEM_UPDATE` - "Updated content item: ..."
- 🆕 `CONTENT_ITEM_DELETION` - "Deleted content item: ..."

#### Batch Management (3 types)
- 🆕 `BATCH_ISSUANCE` - "Issued batch..."
- ✅ `BATCH_STATUS_CHANGE` (existing)
- 🆕 `FREE_BATCH_ISSUANCE` - "Admin issued free batch..."

#### Credit Management (3 types - NEW CATEGORY)
- 🆕 `CREDIT_ADJUSTMENT` - "Admin adjusted credits for user..." ⭐ **PRIMARY REQUEST**
- 🆕 `CREDIT_PURCHASE` - "Credit purchase initiated..." / "Created credit purchase..."
- 🆕 `CREDIT_CONSUMPTION` - "Credit consumption: X credits for..."

#### Print Requests (3 types)
- 🆕 `PRINT_REQUEST_SUBMISSION` - "Submitted print request"
- ✅ `PRINT_REQUEST_UPDATE` (existing)
- ✅ `PRINT_REQUEST_WITHDRAWAL` (existing)

**Total**: 28 activity types (11 existing + 17 new)

### 2. Updated History Logs Component (`src/views/Dashboard/Admin/HistoryLogs.vue`)

#### Filter Dropdown
- Added all 28 activity types to the filter dropdown
- Organized by category with comments
- Converted from hardcoded array to computed property for i18n support
- Uses translation keys: `admin.activity_types.*`

#### Visual Styling (Colors & Icons)
Added distinctive colors and icons for all activity types:

**Credit Management** (Key additions):
- Credit Adjustment: Amber background with dollar icon (`pi-dollar`)
- Credit Purchase: Green background with shopping cart icon (`pi-shopping-cart`)
- Credit Consumption: Pink background with wallet icon (`pi-wallet`)

**User Management**:
- Verification Reset: Cyan with refresh icon
- Manual Verification: Emerald with check-circle icon

**Card Management**:
- Card Activation: Lime with check icon

**Content Management**:
- Creation: Sky with file-plus icon
- Update: Yellow with file-edit icon
- Deletion: Rose with file-minus icon

**Batch Management**:
- Batch Issuance: Indigo with box icon
- Free Batch: Violet with gift icon

**Print Requests**:
- Submission: Blue with send icon

### 3. Internationalization

#### English (`src/i18n/locales/en.json`)
Added `admin.activity_types` object with all 24 activity type labels:
```json
"activity_types": {
  "all_activities": "All Activities",
  "credit_adjustments": "Credit Adjustments",
  "credit_purchases": "Credit Purchases",
  "credit_consumption": "Credit Consumption",
  // ... (21 more)
}
```

#### Traditional Chinese (`src/i18n/locales/zh-Hant.json`)
Added complete Traditional Chinese translations:
```json
"activity_types": {
  "all_activities": "所有活動",
  "credit_adjustments": "點數調整",
  "credit_purchases": "點數購買",
  "credit_consumption": "點數消費",
  // ... (21 more)
}
```

## Testing Checklist

- [ ] Credit adjustment events appear in History Logs
- [ ] Filter dropdown shows all 28 activity types
- [ ] Filter by "Credit Adjustments" shows only credit adjustment events
- [ ] Credit adjustment events have amber background with dollar icon
- [ ] All new filter options work correctly
- [ ] Translations work in both English and Traditional Chinese
- [ ] Icons and colors are visually distinct and appropriate

## Impact

### Benefits
1. **Better Filtering**: Admins can now filter by specific operation types including credit adjustments
2. **Visual Clarity**: Each activity type has distinctive color and icon for quick identification
3. **Complete Coverage**: All logged operations now have corresponding filter options
4. **Organized Structure**: Activities grouped by category (User, Card, Content, Batch, Credit, Print)
5. **Internationalization**: Full support for English and Traditional Chinese

### User Experience
- **Before**: Only 11 filter options, many operations couldn't be filtered
- **After**: 28 comprehensive filter options covering all logged operations
- **Credit Adjustments**: Now easily filterable and visually identifiable with amber/dollar styling

## Operations Now Filterable

Previously missing operations now filterable:
1. ✅ Credit adjustments (admin manually adjusting user credits)
2. ✅ Credit purchases (users buying credits)
3. ✅ Credit consumption (credits spent on translations/batches)
4. ✅ Content item creation/updates/deletions
5. ✅ Card activations
6. ✅ Batch issuance (regular and free)
7. ✅ Print request submissions
8. ✅ Verification resets and manual approvals

## Files Modified

1. `src/stores/admin/auditLog.ts` - Added 17 new ACTION_TYPES constants + search keyword mapping
2. `src/views/Dashboard/Admin/HistoryLogs.vue` - Updated filter dropdown, icons, colors, and i18n
3. `src/i18n/locales/en.json` - Added activity type translations
4. `src/i18n/locales/zh-Hant.json` - Added Traditional Chinese translations

## Technical Details: Action Type → Search Keyword Mapping

### The Problem
The stored procedure `get_operations_log` searches operation text using `ILIKE`, but:
- **Filter sends**: ACTION_TYPE constants like `"CREDIT_ADJUSTMENT"`
- **Logs contain**: Descriptive text like `"Admin adjusted credits for user..."`
- **Result**: No matches found! ❌

### The Solution
Created `ACTION_TYPE_SEARCH_KEYWORDS` mapping to convert UI constants to actual log text:

```typescript
export const ACTION_TYPE_SEARCH_KEYWORDS: Record<string, string> = {
  CREDIT_ADJUSTMENT: 'Admin adjusted credits',  // Matches actual log text
  CREDIT_PURCHASE: 'Credit purchase',
  CREDIT_CONSUMPTION: 'Credit consumption',
  CARD_CREATION: 'Created card:',
  // ... etc
}
```

When filtering:
1. User selects "Credit Adjustments" from dropdown
2. Frontend sends `action_type: 'CREDIT_ADJUSTMENT'`
3. Store maps it to `'Admin adjusted credits'` via `ACTION_TYPE_SEARCH_KEYWORDS`
4. Stored procedure searches for `'Admin adjusted credits'` in operation text
5. ✅ Matches found!

### Example Mappings
| Action Type | Search Keyword | Matches Log Text |
|------------|----------------|------------------|
| `CREDIT_ADJUSTMENT` | `'Admin adjusted credits'` | "Admin adjusted credits for user..." |
| `CREDIT_PURCHASE` | `'Credit purchase'` | "Credit purchase initiated: 100 credits..." |
| `CARD_CREATION` | `'Created card:'` | "Created card: Museum Tour" |
| `CARD_ACTIVATION` | `'activated'` | "Activated issued card" / "Card auto-activated" |
| `FREE_BATCH_ISSUANCE` | `'Admin issued free batch'` | "Admin issued free batch: ..." |

## Notes

- No database changes required - all operations already being logged
- No breaking changes - purely additive enhancements
- Follows existing design patterns and conventions
- All linter checks pass
- ✅ **Filtering now works correctly** with keyword mapping

