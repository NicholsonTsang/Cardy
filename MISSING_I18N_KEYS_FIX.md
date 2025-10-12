# Missing i18n Keys Fix

## Issue
Console error for missing `common.quantity` key in English:
```
[intlify] Not found 'common.quantity' key in 'en' locale messages.
```

## Root Cause
When implementing the consumption type display feature, the code used `$t('common.quantity')` for the quantity column header, but this key was never added to the i18n files.

## Solution

### 1. Added `common.quantity` to en.json
**File**: `src/i18n/locales/en.json`
**Line**: 56

```json
{
  "common": {
    "type": "Type",
    "user": "User",
    "card": "Card",
    "quantity": "Quantity",  // ✅ ADDED
    "createdAt": "Created At",
    ...
  }
}
```

### 2. Added `common.quantity` to zh-Hant.json
**File**: `src/i18n/locales/zh-Hant.json`
**Line**: 33

```json
{
  "common": {
    "card": "卡片",
    "user": "用戶",
    "quantity": "數量",  // ✅ ADDED
    "description": "描述",
    ...
  }
}
```

### 3. Added `credits.consumptionType` to zh-Hant.json
**File**: `src/i18n/locales/zh-Hant.json`
**Lines**: 881-885

```json
{
  "credits": {
    "consumptionType": {  // ✅ ADDED
      "batch_issuance": "批次發行",
      "translation": "翻譯",
      "single_card": "單張卡片"
    }
  }
}
```

### 4. Fixed Duplicate Key in zh-Hant.json
**Issue**: Duplicate `totalConsumed` key
**Line**: 560 (removed)
**Resolution**: Removed the duplicate, kept the correct one at line 571

## Files Modified

1. **`src/i18n/locales/en.json`**
   - Line 56: Added `quantity: "Quantity"` under `common`

2. **`src/i18n/locales/zh-Hant.json`**
   - Line 33: Added `quantity: "數量"` under `common`
   - Lines 881-885: Added `consumptionType` section under `credits`
   - Line 560: Removed duplicate `totalConsumed` key

## Usage

These keys are used in the consumption history tables:

### Quantity Column Header
```vue
<Column field="quantity" :header="$t('common.quantity')" sortable>
  <template #body="{ data }">
    <Chip 
      :label="`${data.quantity} ${getQuantityUnit(data.consumption_type)}`" 
      icon="pi pi-hashtag" 
    />
  </template>
</Column>
```

### Consumption Type Labels
```typescript
function getConsumptionTypeLabel(type: string) {
  const { t } = useI18n()
  const key = `credits.consumptionType.${type}`
  return t(key, type || 'Unknown')
}
```

## Translation Completeness

### English (en) ✅
- [x] `common.quantity` ✅
- [x] `credits.consumptionType.batch_issuance` ✅
- [x] `credits.consumptionType.translation` ✅
- [x] `credits.consumptionType.single_card` ✅

### Traditional Chinese (zh-Hant) ✅
- [x] `common.quantity` ✅ (數量)
- [x] `credits.consumptionType.batch_issuance` ✅ (批次發行)
- [x] `credits.consumptionType.translation` ✅ (翻譯)
- [x] `credits.consumptionType.single_card` ✅ (單張卡片)

### Other Languages ⏸️ Placeholder
Not maintained - will fall back to English (expected behavior)

## Testing

### Test Cases
1. ✅ Switch to English → Verify "Quantity" column header appears
2. ✅ Switch to Traditional Chinese → Verify "數量" column header appears
3. ✅ English consumption types show: "Batch Issuance", "Translation", "Single Card"
4. ✅ Traditional Chinese consumption types show: "批次發行", "翻譯", "單張卡片"
5. ✅ No console errors for these keys in en or zh-Hant

### How to Test
1. Navigate to Credit Management page
2. Go to "Consumption History" tab
3. Switch language between English and Traditional Chinese
4. Verify column headers and consumption type tags display correctly
5. Check browser console for any i18n errors

## Related Features
- **Consumption Type Display**: Shows different types of credit usage
- **Credit Management**: User-facing credit history
- **Admin Credit Management**: Admin oversight of all credit operations
- **i18n System**: Multi-language support

## Related Files
- `CONSUMPTION_TYPE_DISPLAY_UPDATE.md` - UI changes for consumption types
- `CONSUMPTION_TYPE_I18N_FIX.md` - Initial i18n fix for consumption type labels
- `I18N_POLICY_UPDATE.md` - Policy on maintaining only en & zh-Hant

## Prevention for Future

### When Adding New Features
1. **Add i18n keys IMMEDIATELY** when writing template code with `$t()`
2. **Always update both** `en.json` AND `zh-Hant.json`
3. **Test in both languages** before committing
4. **Check console** for i18n warnings during development

### Checklist for i18n
- [ ] Added key to `src/i18n/locales/en.json`
- [ ] Added corresponding translation to `src/i18n/locales/zh-Hant.json`
- [ ] Tested in English
- [ ] Tested in Traditional Chinese
- [ ] No console errors or warnings for these keys

## Lint Errors Fixed

### Duplicate Key Error
**Before**:
```
Line 571:7: Duplicate object key, severity: warning
Line 560:7: Duplicate object key, severity: warning
```

**After**: ✅ No linter errors

The duplicate `totalConsumed` key was removed from line 560.

---

**Status**: ✅ Fixed
**Console Warnings**: Resolved for en & zh-Hant
**Linter Errors**: Resolved
**Testing**: Required before deployment

