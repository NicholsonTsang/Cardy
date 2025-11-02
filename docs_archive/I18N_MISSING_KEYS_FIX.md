# Missing i18n Keys Fix

## Issue

Console warning: `[intlify] Not found 'batches.credit' key in 'en' locale messages.`

**Location:** `TranslationDialog.vue:321` in `CreditConfirmationDialog` component

## Root Cause

The `TranslationDialog.vue` component uses `$t('batches.credit')` (singular form) but only `batches.credits` (plural form) existed in the locale files.

**Code Reference:**
```vue
<!-- TranslationDialog.vue line 321 -->
<span class="font-semibold text-slate-900">1 {{ $t('batches.credit') }}</span>
```

## Solution

Added missing singular `credit` key to both locale files in the `batches` section.

### Files Modified

1. **`src/i18n/locales/en.json`**
   - Added `"credit": "credit"` in `batches` section
   - Line 370: Right after `credits_required` and before `credits`

2. **`src/i18n/locales/zh-Hant.json`**
   - Added `"credit": "積分"` in `batches` section  
   - Line 392: Right after `confirm_credit_usage`

### Changes Made

#### English (en.json)
```json
"batches": {
  // ...
  "credits_required": "Credits Required",
  "credit": "credit",           // ← Added
  "credits": "credits",
  // ...
}
```

#### Traditional Chinese (zh-Hant.json)
```json
"batches": {
  // ...
  "confirm_credit_usage": "確認信用額度使用",
  "credit": "積分",              // ← Added
  "credits": "積分",
  // ...
}
```

## Additional Fix

Also added `credit` key to the `credits` section (different section) in zh-Hant.json for consistency:

```json
"credits": {
  // ...
  "balance": "餘額",
  "credit": "積分",              // ← Added for consistency
  "credits": "積分",
  // ...
}
```

## Usage

The singular `credit` form is used when displaying "1 credit" in the UI:

**Examples:**
- Translation dialog: "1 credit per language"
- Credit confirmation: "1 credit will be consumed"
- Pricing info: "Costs 1 credit"

The plural `credits` form is used for multiple credits:
- "10 credits required"
- "You have 50 credits"

## Verification

✅ No linting errors  
✅ Both locale files updated  
✅ Consistent across en and zh-Hant  
✅ Console warning resolved

## Related Components

- `src/components/Card/TranslationDialog.vue` - Uses the key
- `src/components/CreditConfirmationDialog.vue` - Renders the value
- `src/components/CardIssuanceCheckout.vue` - Uses plural form

## Testing

To verify the fix:

1. Open Translation Dialog in a card
2. Select languages to translate
3. Check credit confirmation display
4. Should see: "1 credit" (not "1 credits")
5. No console warnings

---

**Date:** January 2025  
**Status:** ✅ Fixed  
**Impact:** Resolves console warning, improves grammar accuracy


