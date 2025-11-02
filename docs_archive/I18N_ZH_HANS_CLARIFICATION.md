# i18n zh-Hans Clarification

## Issue
Console warnings showing missing i18n keys in `zh-Hans` locale:
- `content.content_item`
- `content.basic_information`
- `content.description`
- `content.ai_knowledge_info`

These warnings appear when users select Simplified Chinese in the Dashboard.

## Root Cause
`zh-Hans` (Simplified Chinese) is a **placeholder language** with incomplete translations. While it was recently integrated for the Chinese voice selection feature (to differentiate Simplified vs Traditional text script), the Dashboard UI translations remain incomplete.

## Current Behavior (Expected)
1. **Mobile Client**: Chinese voice selection uses `zh-Hans` and `zh-Hant` for text script differentiation
2. **Dashboard UI**: When Dashboard language is set to Simplified Chinese (`zh-Hans`):
   - Missing keys fall back to English (configured via i18n fallback chain)
   - Console warnings appear for missing translations
   - This is **expected behavior** as per the i18n policy

## Translation Policy
- **Actively Maintained**: Only `en` (English) and `zh-Hant` (Traditional Chinese)
- **Placeholder Languages**: `zh-Hans`, `ja`, `ko`, `es`, `fr`, `ru`, `ar`, `th` - exist for future expansion but are NOT maintained
- **New Features**: When adding new i18n keys, only update `en.json` and `zh-Hant.json`

## Why zh-Hans Exists Despite Being Incomplete
The Chinese voice selection feature requires differentiation between:
- **Text Script**: Simplified (`zh-Hans`) vs Traditional (`zh-Hant`)
- **Voice Dialect**: Mandarin vs Cantonese

This is necessary because:
1. Simplified text can be spoken in Mandarin or Cantonese
2. Traditional text can be spoken in Mandarin or Cantonese
3. Users need independent control over text script and voice dialect

The `zh-Hans` locale provides the infrastructure for this differentiation, even though Dashboard translations are incomplete.

## CLAUDE.md Updates
Updated the "Internationalization" section to clarify:
- `zh-Hans` remains a placeholder language with incomplete translations
- Dashboard UI for Simplified Chinese users will fall back to English for missing keys
- Console warnings for placeholder languages (including zh-Hans) are expected and can be ignored
- This does not affect the Chinese voice selection feature, which works correctly

## For Future Development
If Simplified Chinese Dashboard UI becomes a priority:
1. Copy all keys from `zh-Hant.json` to `zh-Hans.json` as a baseline
2. Update Simplified Chinese-specific terms and characters
3. Update the i18n policy in CLAUDE.md to reflect that zh-Hans is actively maintained
4. Update translation workflows to include zh-Hans alongside en and zh-Hant

Until then, the current fallback behavior is acceptable and documented.

## Related Files
- `/src/i18n/locales/zh-Hans.json` - Incomplete Simplified Chinese translations
- `/src/i18n/locales/en.json` - Complete English translations (fallback)
- `/src/i18n/locales/zh-Hant.json` - Complete Traditional Chinese translations
- `/src/stores/language.ts` - Language store with Chinese voice selection logic
- `CLAUDE.md` - Updated internationalization documentation
- `CHINESE_VOICE_SELECTION_FEATURE.md` - Chinese voice selection implementation details

