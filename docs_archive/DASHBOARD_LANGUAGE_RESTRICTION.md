# Dashboard Language Restriction

## Overview
Limited the dashboard language selector to show only **3 languages** (English, Simplified Chinese, Traditional Chinese) while keeping all 10 languages available for the mobile client.

## Rationale
- **Dashboard Users** (card issuers/admins): Primarily English and Chinese speakers who manage content
- **Mobile Users** (visitors): International tourists worldwide who need access to all 10 languages

## Changes Made

### 1. Language Store (`src/stores/language.ts`)

**New Constant Added:**
```typescript
// Available languages for dashboard (only English and Chinese variants for card issuers/admins)
export const DASHBOARD_LANGUAGES: Language[] = [
  { code: 'en', name: 'English', flag: '🇺🇸' },
  { code: 'zh-Hans', name: '简体中文', flag: '🇨🇳' },  // Simplified Chinese
  { code: 'zh-Hant', name: '繁體中文', flag: '🇭🇰' }   // Traditional Chinese
]
```

**`AVAILABLE_LANGUAGES` (unchanged):**
- Still contains all 10 languages
- Used by `useMobileLanguageStore` for mobile client
- Languages: en, zh-Hans, zh-Hant, ja, ko, th, es, fr, ru, ar

**`detectBrowserLanguage()` Enhanced:**
- Now accepts optional `availableLanguages` parameter
- Dashboard store passes `DASHBOARD_LANGUAGES` to limit browser detection
- Mobile store uses default `AVAILABLE_LANGUAGES` (all 10)

**Dashboard Store Updated:**
```typescript
export const useDashboardLanguageStore = defineStore('dashboardLanguage', () => {
  // Uses DASHBOARD_LANGUAGES for initial detection and language list
  const detected = detectBrowserLanguage(DASHBOARD_LANGUAGES)
  
  return {
    languages: DASHBOARD_LANGUAGES,  // Only 3 languages
    // ... rest of store
  }
})
```

**Mobile Store (unchanged):**
```typescript
export const useMobileLanguageStore = defineStore('mobileLanguage', () => {
  return {
    languages: AVAILABLE_LANGUAGES,  // All 10 languages
    // ... rest of store
  }
})
```

### 2. Dashboard Language Selector Component

**Component:** `src/components/DashboardLanguageSelector.vue`

**No code changes needed** - component automatically uses `useDashboardLanguageStore()` which now returns only 3 languages via `languageStore.languages`.

### 3. Mobile Language Selectors

**Components:**
- `src/views/MobileClient/components/LanguageSelector.vue`
- `src/views/MobileClient/components/LanguageSelectorModal.vue`
- `src/views/MobileClient/components/AIAssistant/components/LanguageSelector.vue`

**No changes needed** - all use `useMobileLanguageStore()` which still returns all 10 languages.

### 4. Documentation Updates

**File:** `CLAUDE.md`

Added new section bullets:
```markdown
- **Dashboard Languages**: Dashboard language selector shows only **3 languages** (en, zh-Hans, zh-Hant) for card issuers/admins.
- **Mobile Client Languages**: Mobile language selector shows **all 10 languages** for visitors worldwide (en, zh-Hans, zh-Hant, ja, ko, th, es, fr, ru, ar).
```

## Impact Analysis

### Dashboard
✅ **Language selector now shows 3 languages:**
- English (🇺🇸)
- 简体中文 (🇨🇳)
- 繁體中文 (🇭🇰)

✅ **Browser language detection:**
- Only matches against these 3 languages
- Falls back to English if browser language is not en/zh-Hans/zh-Hant
- Example: Japanese browser → Falls back to English

✅ **Saved preferences:**
- If user previously selected ja/ko/th/etc., will reset to English
- New selections limited to 3 languages only

### Mobile Client
✅ **No changes:**
- Still shows all 10 languages
- Browser detection uses all languages
- Card original language detection works across all 10 languages

## Testing Checklist

### Dashboard Testing
- [ ] Language selector shows only 3 languages (en, zh-Hans, zh-Hant)
- [ ] Browser language detection works (test with Chinese and English browsers)
- [ ] Language switching updates UI correctly
- [ ] localStorage saves selected language
- [ ] i18n locale updates correctly

### Mobile Client Testing
- [ ] Language selector shows all 10 languages
- [ ] Language selection works for all languages
- [ ] Card original language sets correctly
- [ ] Translation display works across all languages
- [ ] AI assistant language switching works

### Edge Cases
- [ ] User with saved preference for removed language (ja/ko/etc.) resets to English
- [ ] Browser with unsupported language (e.g., Italian) falls back correctly
- [ ] Language persistence between dashboard and mobile contexts

## Notes

1. **Simplified Chinese Note**: While `zh-Hans` is now available in dashboard selector, its translation file remains incomplete (placeholder status). Users selecting Simplified Chinese will see English fallback for missing keys.

2. **Translation Maintenance**: Only `en` and `zh-Hant` are actively maintained. Adding new i18n keys should update these two locales only.

3. **Grid Layout**: Dashboard language selector grid changed from 10 items (3-column) to 3 items. The 3-column grid layout remains unchanged for visual consistency.

4. **Backward Compatibility**: No breaking changes. Existing code using either store continues to work as expected.

## Deployment

No database changes required. Frontend-only update.

**Files to deploy:**
- `src/stores/language.ts`
- `CLAUDE.md`

**Post-deployment:**
- Clear localStorage for users (optional, will auto-reset on invalid language)
- Monitor for any console warnings about missing language keys

