# CSV Download - Redundant Column Removal

## Issue

The CSV download feature had **two duplicate columns** containing the exact same data:
- "QR Code URL" 
- "Access URL"

Both columns were populated with `getCardURL(card.id)`, making one of them completely redundant.

## Solution

**Removed the redundant column** and simplified the CSV structure:

### Before (5 columns with duplication)
```
Card Number, Issue Card ID, Status, QR Code URL, Access URL
1, abc-123, Active, https://..., https://...  ← Same URL repeated
```

### After (4 columns - clean and efficient)
```
Card Number, Issue Card ID, Status, Card URL
1, abc-123, Active, https://...  ← Single URL column
```

## Changes Made

### 1. Updated Component Logic
**File**: `src/components/CardComponents/CardAccessQR.vue`

```javascript
// Before
const headers = [
  t('batches.csv_card_number'),
  t('batches.csv_issue_card_id'),
  t('batches.csv_status'),
  t('batches.csv_qr_code_url'),    // Duplicate 1
  t('batches.csv_access_url')      // Duplicate 2
]

// After
const headers = [
  t('batches.csv_card_number'),
  t('batches.csv_issue_card_id'),
  t('batches.csv_status'),
  t('batches.csv_card_url')        // Single, clearer column
]
```

### 2. Updated Translations

**English** (`src/i18n/locales/en.json`):
- Removed: `csv_qr_code_url`, `csv_access_url`
- Added: `csv_card_url` = "Card URL"

**Traditional Chinese** (`src/i18n/locales/zh-Hant.json`):
- Removed: `csv_qr_code_url` ("二維碼連結"), `csv_access_url` ("存取連結")
- Added: `csv_card_url` = "卡片連結"

## Benefits

1. **Cleaner Output**: No redundant columns in exported CSV
2. **Clearer Naming**: "Card URL" is more descriptive than two similar column names
3. **Smaller File Size**: One less column = smaller CSV files
4. **Better UX**: Less confusion for users viewing the CSV
5. **Easier Maintenance**: Fewer translation keys to maintain

## CSV Output Example

```csv
Card Number,Issue Card ID,Status,Card URL
1,a1b2c3d4-e5f6-7890-abcd-ef1234567890,Active,https://cardstudio.app/c/a1b2c3d4-e5f6-7890-abcd-ef1234567890
2,b2c3d4e5-f6a7-8901-bcde-f12345678901,Active,https://cardstudio.app/c/b2c3d4e5-f6a7-8901-bcde-f12345678901
3,c3d4e5f6-a7b8-9012-cdef-123456789012,Inactive,https://cardstudio.app/c/c3d4e5f6-a7b8-9012-cdef-123456789012
```

## Testing

- [x] No linter errors
- [x] Translations updated for en and zh-Hant
- [ ] User testing: Download CSV and verify column count and naming

---

**Status**: ✅ Complete
**Date**: January 13, 2025
**Type**: Code cleanup and UX improvement
**Impact**: Minor - Removes redundancy, improves clarity

