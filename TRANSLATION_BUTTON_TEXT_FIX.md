# Translation Button Text Fix

## Issue
The translate button in the Translation Dialog was displaying weird/incorrect text due to improper pluralization format.

## Root Cause
The translation key used an incorrect format with parentheses:
```json
"translate": "Translate ({count} language | {count} languages)"
```

This format was not being parsed correctly by Vue I18n v9 (Composition API mode with `legacy: false`), resulting in the literal string being displayed instead of the correct pluralized form.

## Solution
Updated the translation key to use the proper pipe syntax without parentheses:
```json
"translate": "Translate {count} Language | Translate {count} Languages"
```

## Format
The pipe `|` separates singular and plural forms:
- **Singular (count === 1)**: "Translate 1 Language"
- **Plural (count > 1)**: "Translate 2 Languages"

## Files Modified
1. **`src/i18n/locales/en.json`**
   - Line 1052: Updated `translation.dialog.translate` key

## Usage
The button in `TranslationDialog.vue` uses this translation:
```vue
<Button
  :label="$t('translation.dialog.translate', { count: selectedLanguages.length })"
  icon="pi pi-language"
  @click="showConfirmation"
/>
```

## Testing
1. Open Translation Dialog
2. Select 1 language → Button should show "Translate 1 Language"
3. Select 2+ languages → Button should show "Translate 2 Languages" (or appropriate count)

## Note
This follows the established pipe syntax pattern used elsewhere in the project (e.g., `sub_items_count`).

