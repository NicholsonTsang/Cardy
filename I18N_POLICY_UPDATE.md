# i18n Policy Update - Active Languages

## Decision
**Only English (en) and Traditional Chinese (zh-Hant) are actively maintained.**

Other 8 language files (zh-Hans, ja, ko, es, fr, ru, ar, th) exist as placeholders for future expansion but are **NOT maintained** and contain incomplete/outdated translations.

## Impact

### Console Warnings
i18n fallback warnings for placeholder languages are **expected and should be ignored**:
```
[intlify] Not found 'credits.title' key in 'ko' locale messages.
[intlify] Fall back to translate 'credits.title' key with 'en' locale.
```

These warnings are **normal** and **acceptable**. They indicate the fallback mechanism is working correctly.

### User Experience
- **English users**: Full translation coverage ✅
- **Traditional Chinese users**: Full translation coverage ✅
- **Other language users**: Mixed experience
  - Some keys show in selected language (old/partial translations)
  - Missing keys fall back to English automatically
  - No crashes or broken functionality

## Development Guidelines

### When Adding New Features

#### ✅ DO
1. **Always update en.json** (primary reference)
2. **Always update zh-Hant.json** (actively maintained)
3. Test in both English and Traditional Chinese
4. Ignore console warnings for ko, ja, es, fr, ru, ar, th

#### ❌ DON'T
1. Don't update other 8 placeholder language files
2. Don't worry about missing keys in placeholder languages
3. Don't try to fix all placeholder language warnings

### Translation Key Pattern

**Example**: Adding a new feature "Credit Management"

#### Step 1: Add to en.json
```json
{
  "credits": {
    "title": "Credit Management",
    "description": "Manage your credits",
    "consumptionType": {
      "batch_issuance": "Batch Issuance",
      "translation": "Translation"
    }
  }
}
```

#### Step 2: Add to zh-Hant.json
```json
{
  "credits": {
    "title": "信用管理",
    "description": "管理您的信用額度",
    "consumptionType": {
      "batch_issuance": "批次發行",
      "translation": "翻譯"
    }
  }
}
```

#### Step 3: Done! ✅
- Skip ko.json, ja.json, es.json, fr.json, ru.json, ar.json, th.json, zh-Hans.json
- Console warnings for these languages are expected

## CLAUDE.md Updates

Updated multiple sections to reflect this policy:

### 1. Core Overview
- ✅ Changed "10 languages" to "multiple languages, active: en & zh-Hant"

### 2. Project Structure
- ✅ Updated i18n folder description to mention "en.json, zh-Hant.json (actively maintained), + 8 placeholder languages"

### 3. Internationalization Section
- ✅ Added "Active Languages" subsection highlighting en & zh-Hant
- ✅ Added "Placeholder Languages" explanation
- ✅ Added note about console warnings being expected

### 4. Card Issuer Flow
- ✅ Updated card creation to mention "actively maintained: en, zh-Hant"

### 5. Visitor Flow
- ✅ Updated language selection to clarify active languages

### 6. Notes & Best Practices
- ✅ Updated i18n guideline: "Always update both locales/en.json AND locales/zh-Hant.json"

### 7. Deep Archive Summaries
- ✅ Updated i18n notes to mention active languages

## Language File Status

| Language | Code | Status | Action Required |
|----------|------|--------|-----------------|
| English | `en` | ✅ **Active** | Always update |
| Traditional Chinese | `zh-Hant` | ✅ **Active** | Always update |
| Simplified Chinese | `zh-Hans` | ⏸️ Placeholder | Ignore |
| Japanese | `ja` | ⏸️ Placeholder | Ignore |
| Korean | `ko` | ⏸️ Placeholder | Ignore |
| Spanish | `es` | ⏸️ Placeholder | Ignore |
| French | `fr` | ⏸️ Placeholder | Ignore |
| Russian | `ru` | ⏸️ Placeholder | Ignore |
| Arabic | `ar` | ⏸️ Placeholder | Ignore |
| Thai | `th` | ⏸️ Placeholder | Ignore |

## Fallback Mechanism

Vue i18n's fallback system works as follows:

1. User selects language (e.g., Korean)
2. App tries to load translation from `ko.json`
3. If key not found → falls back to `en.json`
4. Console warning logged (this is normal!)
5. User sees English text for that key

This ensures the app **never breaks** due to missing translations.

## Future Expansion

### When to Add Languages

Consider adding/maintaining additional languages when:
1. Significant user base in that region (e.g., >100 active users)
2. Business expansion to new markets
3. Partnership with institutions in specific regions
4. Translation resources available (native speakers or professional translation service)

### How to Activate a Placeholder Language

Example: Activating Japanese

1. **Update CLAUDE.md**: Add `ja` to active languages list
2. **Translate all keys**: Update `src/i18n/locales/ja.json` with all keys from `en.json`
3. **Test thoroughly**: Switch to Japanese, test all pages/features
4. **Update guidelines**: Add `ja.json` to "always update" list
5. **Monitor**: Track completion/maintenance going forward

## Benefits of This Approach

### ✅ Advantages
1. **Reduced maintenance burden**: Only 2 languages to keep updated
2. **No broken functionality**: Fallback ensures app always works
3. **Clear expectations**: Developers know exactly which files to update
4. **Future flexibility**: Placeholder files ready when needed
5. **Better quality**: Focus on 2 languages = higher quality translations

### ⚠️ Trade-offs
1. **Mixed UX for placeholder languages**: Some English, some in selected language
2. **Console warnings**: Need to ignore/filter noise in development
3. **User confusion**: Users might wonder why some text isn't translated

### 💡 Mitigation
- Language selector could show badges: "English ✓", "繁體中文 ✓", "한국어 (部分)" (Partial)
- Or hide placeholder languages entirely from the selector
- Add disclaimer in settings: "Only English and Traditional Chinese are fully supported"

## Developer Checklist

When adding/modifying features:

- [ ] Add all new translation keys to `en.json`
- [ ] Add corresponding translations to `zh-Hant.json`
- [ ] Test feature in English
- [ ] Test feature in Traditional Chinese
- [ ] Verify fallback works (optional: test in Korean to see fallback)
- [ ] Ignore console warnings for placeholder languages

## Console Warning Filter (Optional)

To reduce noise in development, you can filter i18n warnings in browser DevTools:

**Chrome DevTools Console Filters**:
```
-[intlify] Not found
-[intlify] Fall back to translate
```

This hides the expected fallback warnings while keeping other console logs visible.

## Related Files

### Updated
- ✅ `CLAUDE.md` - Multiple sections updated to reflect policy
- ✅ `src/i18n/locales/en.json` - Added `credits.consumptionType` keys
- ✅ `src/views/Dashboard/CardIssuer/CreditManagement.vue` - Updated to use i18n keys
- ✅ `src/views/Dashboard/Admin/AdminCreditManagement.vue` - Updated to use i18n keys

### Reference
- `CONSUMPTION_TYPE_I18N_FIX.md` - Details of consumption type i18n implementation
- `CONSUMPTION_TYPE_DISPLAY_UPDATE.md` - UI changes for consumption types
- `scripts/sync-i18n-keys.js` - Helper script to sync keys (optional tool, not needed for daily dev)

---

**Status**: ✅ Policy defined and documented
**Last Updated**: Session completion
**Maintainers**: Focus on en.json and zh-Hant.json only
**Console Warnings**: Expected and acceptable for 8 placeholder languages

