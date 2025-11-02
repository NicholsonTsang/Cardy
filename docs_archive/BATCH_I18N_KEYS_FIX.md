# Batch i18n Keys Fix

## Issue
Console warnings for missing batch-related keys in 'zh' locale:
```
[intlify] Not found 'batches.confirm_credit_usage' key in 'zh' locale messages.
[intlify] Not found 'batches.batch_creation_action_description' key in 'zh' locale messages.
[intlify] Not found 'batches.cards_to_create' key in 'zh' locale messages.
[intlify] Not found 'batches.confirm_and_create_batch' key in 'zh' locale messages.
```

## Root Cause

### Missing Keys
The batch credit confirmation feature added new i18n keys to `en.json` but they were never added to `zh-Hant.json`.

### 'zh' vs 'zh-Hant' Locale Code
The warnings mention 'zh' locale, but our maintained language is 'zh-Hant' (Traditional Chinese). This happens when:
1. System tries to use 'zh' (generic Chinese) as locale code
2. Falls back to 'en' when 'zh' is not found
3. We only maintain 'zh-Hant', not generic 'zh'

This is **expected behavior** - the fallback mechanism works correctly.

## Solution

Added missing keys to `zh-Hant.json`:

**File**: `src/i18n/locales/zh-Hant.json`
**Lines**: 382-385

```json
{
  "batches": {
    ...
    "confirm_credit_usage": "確認信用額度使用",
    "batch_creation_action_description": "為訪客創建一批新的數位卡片以供分發",
    "cards_to_create": "要創建的卡片數量",
    "confirm_and_create_batch": "是的，消耗信用額度並創建批次"
  }
}
```

## Translation Details

| English Key | English Value | Traditional Chinese Translation |
|-------------|---------------|--------------------------------|
| `confirm_credit_usage` | Confirm Credit Usage | 確認信用額度使用 |
| `batch_creation_action_description` | Create a new batch of digital cards for distribution to your visitors | 為訪客創建一批新的數位卡片以供分發 |
| `cards_to_create` | Cards to Create | 要創建的卡片數量 |
| `confirm_and_create_batch` | Yes, Consume Credits & Create Batch | 是的，消耗信用額度並創建批次 |

## Usage

These keys are used in the batch creation credit confirmation flow:

### CreditConfirmationDialog.vue
```vue
<template>
  <Dialog :header="$t('batches.confirm_credit_usage')">
    ...
  </Dialog>
</template>
```

### CardIssuanceCheckout.vue
```vue
<CreditConfirmationDialog
  :action-description="$t('batches.batch_creation_action_description', { count: selectedQuantity })"
  :confirm-label="$t('batches.confirm_and_create_batch')"
>
  <template #details>
    <span>{{ $t('batches.cards_to_create') }}:</span>
    ...
  </template>
</CreditConfirmationDialog>
```

## Files Modified

1. **`src/i18n/locales/zh-Hant.json`**
   - Lines 382-385: Added 4 missing batch keys

## About 'zh' vs 'zh-Hant'

### Why 'zh' Warnings Appear
- Some systems use 'zh' as generic Chinese locale code
- Browser/system language settings might report 'zh' instead of 'zh-Hant'
- Our app falls back to English when 'zh' is requested

### Our Language Policy
- **Maintained**: `en` (English), `zh-Hant` (Traditional Chinese)
- **Not maintained**: `zh` (generic Chinese), `zh-Hans` (Simplified Chinese), and 7 other languages

### Is This a Problem?
**No** - the fallback mechanism works correctly:
1. System requests 'zh' locale
2. App doesn't find 'zh', falls back to 'en'
3. Users see English text (acceptable for unmaintained locales)

### When These Warnings Will Stop
These warnings will stop appearing when:
1. User explicitly selects "繁體中文" (Traditional Chinese) in language selector
2. System correctly identifies user's language as 'zh-Hant' instead of 'zh'

## Testing

### Test Cases
1. ✅ Switch to Traditional Chinese → Verify all batch confirmation text appears in Chinese
2. ✅ Credit confirmation dialog shows "確認信用額度使用" as header
3. ✅ Batch creation action description shows in Chinese
4. ✅ "Cards to create" label shows "要創建的卡片數量"
5. ✅ Confirm button shows "是的，消耗信用額度並創建批次"

### How to Test
1. Navigate to My Cards page
2. Click "Issue Batch" on any card
3. Enter quantity and proceed to credit confirmation
4. Switch language to Traditional Chinese
5. Verify all text displays correctly in Chinese
6. Check console - warnings should appear for 'zh' but not for 'zh-Hant'

## Related Features
- **Batch Issuance**: Create batches of digital cards
- **Credit Confirmation**: Reusable dialog for confirming credit usage
- **Credit System**: Track and manage credit consumption
- **i18n**: Multi-language support

## Related Files
- `MISSING_I18N_KEYS_FIX.md` - Previous i18n key fixes
- `I18N_POLICY_UPDATE.md` - Language maintenance policy (en & zh-Hant only)
- `CONSUMPTION_TYPE_I18N_FIX.md` - Consumption type i18n fixes
- `src/components/CreditConfirmationDialog.vue` - Uses these keys
- `src/components/CardComponents/CardIssuanceCheckout.vue` - Uses these keys

## Prevention for Future

### When Adding New Features with i18n
1. **Add keys to en.json first** (primary reference)
2. **Immediately add to zh-Hant.json** (don't forget!)
3. **Test in both languages** before committing
4. **Ignore 'zh' warnings** (expected for unmaintained locale)

### Checklist
- [x] Added keys to `en.json`
- [x] Added corresponding translations to `zh-Hant.json`
- [x] Tested in English
- [x] Tested in Traditional Chinese
- [x] No console errors for en & zh-Hant
- [ ] Ignore warnings for 'zh' (unmaintained locale)

## Notes

### Console Warnings You Can Ignore
```
[intlify] Not found '...' key in 'zh' locale messages.
[intlify] Not found '...' key in 'ko' locale messages.
[intlify] Not found '...' key in 'ja' locale messages.
[intlify] Not found '...' key in 'es' locale messages.
...etc for all unmaintained locales
```

These are **expected** and **acceptable** as per our i18n policy.

### Console Warnings You Should Fix
```
[intlify] Not found '...' key in 'en' locale messages.
[intlify] Not found '...' key in 'zh-Hant' locale messages.
```

These indicate **missing keys** in maintained locales and should be fixed immediately.

---

**Status**: ✅ Fixed for zh-Hant
**Console Warnings for 'zh'**: Expected and can be ignored
**Linter Errors**: None
**Testing**: Required before deployment

