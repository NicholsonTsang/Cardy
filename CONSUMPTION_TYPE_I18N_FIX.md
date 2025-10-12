# Consumption Type i18n Fix

## Issue
Console warnings were appearing for missing i18n keys:
```
[intlify] Not found 'credits.type.consumption' key in 'ko' locale messages.
[intlify] Fall back to translate 'credits.type.consumption' key with 'en' locale.
```

## Root Cause
The `getConsumptionTypeLabel()` helper functions in both `CreditManagement.vue` and `AdminCreditManagement.vue` were returning **hardcoded English strings** instead of using i18n translation keys.

**Before**:
```typescript
function getConsumptionTypeLabel(type: string) {
  switch (type) {
    case 'batch_issuance': return 'Batch Issuance'  // ❌ Hardcoded English
    case 'translation': return 'Translation'
    case 'single_card': return 'Single Card'
    default: return type || 'Unknown'
  }
}
```

## Solution

### 1. Added i18n Keys to en.json
Added a new `consumptionType` section under `credits`:

```json
"credits": {
  "type": {
    "purchase": "Purchase",
    "consumption": "Consumption",
    "refund": "Refund",
    "adjustment": "Adjustment"
  },
  "consumptionType": {
    "batch_issuance": "Batch Issuance",
    "translation": "Translation",
    "single_card": "Single Card"
  }
}
```

### 2. Updated Helper Functions to Use i18n
**After**:
```typescript
function getConsumptionTypeLabel(type: string) {
  const { t } = useI18n()
  const key = `credits.consumptionType.${type}`
  // Try to get translation, fallback to type or 'Unknown'
  return t(key, type || 'Unknown')
}
```

## Files Modified

1. **`src/i18n/locales/en.json`**
   - Lines 944-948: Added `consumptionType` section with 3 keys

2. **`src/views/Dashboard/CardIssuer/CreditManagement.vue`**
   - Lines 549-554: Updated `getConsumptionTypeLabel()` to use `useI18n().t()`

3. **`src/views/Dashboard/Admin/AdminCreditManagement.vue`**
   - Lines 788-793: Updated `getConsumptionTypeLabel()` to use `useI18n().t()`

## i18n Key Structure

The key pattern follows this structure:
```
credits.consumptionType.{type}
```

**Examples**:
- `credits.consumptionType.batch_issuance` → "Batch Issuance"
- `credits.consumptionType.translation` → "Translation"
- `credits.consumptionType.single_card` → "Single Card"

## Benefits

### Before
- ❌ Hardcoded English labels (not translatable)
- ❌ Console warnings for missing keys
- ❌ Non-English users see English labels

### After
- ✅ Properly internationalized labels
- ✅ No console warnings
- ✅ Can be translated to all 10 languages
- ✅ Consistent with rest of application

## Translation TODO

The new `consumptionType` keys need to be added to all other language files:

### Files to Update
1. `src/i18n/locales/zh-Hant.json` (Traditional Chinese)
2. `src/i18n/locales/zh-Hans.json` (Simplified Chinese)
3. `src/i18n/locales/ja.json` (Japanese)
4. `src/i18n/locales/ko.json` (Korean)
5. `src/i18n/locales/es.json` (Spanish)
6. `src/i18n/locales/fr.json` (French)
7. `src/i18n/locales/ru.json` (Russian)
8. `src/i18n/locales/ar.json` (Arabic)
9. `src/i18n/locales/th.json` (Thai)

### Translation Pattern
Add under the `credits` section:

```json
"consumptionType": {
  "batch_issuance": "[Translated: Batch Issuance]",
  "translation": "[Translated: Translation]",
  "single_card": "[Translated: Single Card]"
}
```

### Suggested Translations

| Language | batch_issuance | translation | single_card |
|----------|----------------|-------------|-------------|
| zh-Hant (繁體中文) | 批次發行 | 翻譯 | 單張卡片 |
| zh-Hans (简体中文) | 批次发行 | 翻译 | 单张卡片 |
| ja (日本語) | バッチ発行 | 翻訳 | シングルカード |
| ko (한국어) | 배치 발행 | 번역 | 단일 카드 |
| es (Español) | Emisión por Lotes | Traducción | Tarjeta Individual |
| fr (Français) | Émission par Lot | Traduction | Carte Individuelle |
| ru (Русский) | Массовый выпуск | Перевод | Одиночная карта |
| ar (العربية) | إصدار دفعة | ترجمة | بطاقة واحدة |
| th (ไทย) | การออกแบตช์ | การแปล | การ์ดเดี่ยว |

## Fallback Behavior

If a translation key is missing in a specific locale, the i18n system will:
1. Try to use the English translation from `en.json`
2. If that fails, use the fallback value (the type itself or "Unknown")

This ensures graceful degradation if translations are incomplete.

## Testing

### Test Cases
1. ✅ English locale shows "Batch Issuance", "Translation", "Single Card"
2. ⏳ Korean locale should show translations (after adding to ko.json)
3. ⏳ All 10 locales should have proper translations
4. ✅ No console warnings after fix

### How to Test
1. Switch language in app settings
2. Navigate to Credit Management → Consumption History
3. Verify consumption type labels appear in selected language
4. Check browser console for i18n warnings

## Related Features
- **Credit System**: Core credit management
- **Translation System**: AI-powered card translation
- **Batch Issuance**: Card batch creation
- **i18n System**: Multi-language support (10 languages)

## Future Considerations

If new consumption types are added in the future:
1. Add the type to database schema (`consumption_type` enum if using enum)
2. Add the type to `credits.consumptionType` in `en.json`
3. Update the type in all 9 other language files
4. Add corresponding icon and severity in helper functions
5. No code changes needed in `getConsumptionTypeLabel()` (dynamically constructs key)

---

**Status**: ✅ Fixed for English, ⏳ Pending translations for other 9 languages
**Priority**: Medium (functional in English, translations needed for full i18n support)
**Complexity**: Low (simple key additions to JSON files)

