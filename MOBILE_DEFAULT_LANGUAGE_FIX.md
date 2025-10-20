# Mobile Client Default Language Fix

## Issue
The mobile client was defaulting to the browser's language instead of the card's original language, creating inconsistent experiences across visitors.

## Problem
**Before:**
- Mobile client detected browser language on page load (e.g., Chinese browser → Chinese interface)
- Card might be in English (original language)
- If no Chinese translation exists → Content fallbacks to English
- **Result:** Mixed language experience (Chinese UI with English content)

**Root Cause:**
The `useMobileLanguageStore` used `detectBrowserLanguage()` on initialization, same as the dashboard. But mobile clients should respect the card creator's language choice, not the visitor's browser.

## Solution

### 1. Mobile Language Store Changes
**File:** `src/stores/language.ts`

Changed mobile language store to:
- ✅ Default to English (not browser detection)
- ✅ Check for user-selected language in session storage
- ✅ Wait for card to set its original language

**Key Changes:**
```typescript
// OLD: Used browser detection
const detected = detectBrowserLanguage()
console.log('📱 Mobile client initialized with browser language:', detected.code)

// NEW: Default to English, let card set original language
console.log('📱 Mobile client initialized with English (will be set to card original language)')
return AVAILABLE_LANGUAGES[0] // English
```

**Note:** Dashboard language store unchanged - still uses browser detection as intended.

### 2. PublicCardView Changes
**File:** `src/views/MobileClient/PublicCardView.vue`

Added logic to set language to card's original language on first load:

```typescript
// After fetching card data
const cardOriginalLang = firstRow.card_original_language || 'en'
const hasUserSelectedLanguage = sessionStorage.getItem('userSelectedLanguage') === 'true'

if (!hasUserSelectedLanguage) {
  if (mobileLanguageStore.selectedLanguage.code !== cardOriginalLang) {
    // Switch to card's original language
    mobileLanguageStore.setLanguage(originalLanguage)
    return // Triggers watcher to re-fetch with correct language
  }
}
```

### 3. Language Selector Changes
**File:** `src/views/MobileClient/components/LanguageSelectorModal.vue`

Added session storage marker when user manually selects a language:

```typescript
function selectLanguage(language: Language) {
  // Mark that user has manually selected a language
  sessionStorage.setItem('userSelectedLanguage', 'true')
  languageStore.setLanguage(language)
}
```

## Behavior Flow

### First Visit (No User Preference)

**Scenario A: Card original language = English**
1. Page loads → Mobile store initializes with English
2. `fetchCardData()` → Fetches with `p_language: 'en'`
3. Card original language detected: `en`
4. Current language matches (`en === en`) ✅
5. Content displays in English
6. **API Calls:** 1

**Scenario B: Card original language = Chinese**
1. Page loads → Mobile store initializes with English  
2. `fetchCardData()` → Fetches with `p_language: 'en'`
3. Card original language detected: `zh-Hant`
4. Current language doesn't match (`en !== zh-Hant`)
5. Set language to `zh-Hant` → Triggers watcher
6. Watcher calls `fetchCardData()` again → Fetches with `p_language: 'zh-Hant'`
7. Content displays in Chinese
8. **API Calls:** 2 (acceptable on first load)

### User Manually Selects Language

1. User opens language selector
2. User selects different language (e.g., Spanish)
3. `sessionStorage.setItem('userSelectedLanguage', 'true')` is set
4. Language changes → Content re-fetches in Spanish
5. **Next visit:** Will skip auto-detection and use Spanish immediately

### Subsequent Visits (Same Session)

1. Page loads → Check `sessionStorage.getItem('userSelectedLanguage')`
2. If `'true'` → Use `localStorage.getItem('userLocale')` (last selection)
3. If not `'true'` → Reset to English, then detect card's original language
4. **Note:** sessionStorage clears when browser tab closes

## Key Design Decisions

### Why Not Use Browser Language at All?
- **Card creator's intent:** The original language represents the creator's choice
- **Consistency:** All visitors see the same default language
- **Translation quality:** Original language ensures professional content
- **Expectations:** Visitors expect to see card in creator's language first

### Why Two API Calls on First Load?
- **Simplicity:** Stored procedure requires a language parameter
- **Minimal impact:** Only happens on very first load of a card
- **Clean separation:** Language detection happens in frontend, not database
- **Alternative considered:** Modify stored procedure to return original language first, then data → Adds complexity

### Why sessionStorage Instead of localStorage?
- **Per-session:** User preference resets when they close the browser
- **Fresh start:** Each new scan starts with card's original language
- **User control:** Manual selection persists during session but doesn't override future cards

## User Experience

### English Card (Original)
1. ✅ Visitor scans QR code
2. ✅ Card displays in English (original)
3. ✅ Visitor can switch to other languages if translated

### Chinese Card (Original)
1. ✅ Visitor scans QR code  
2. ✅ Card displays in Chinese (original)
3. ✅ Visitor can switch to English or other languages

### Visitor Manually Switches
1. ✅ Visitor views English card
2. ✅ Visitor switches to Chinese
3. ✅ `sessionStorage` marks user selection
4. ✅ Content switches to Chinese
5. ✅ **Next card scan in same session:** Remembers Chinese preference
6. ✅ **New browser session:** Resets to card's original language

## Comparison with Dashboard

| Feature | Mobile Client | Dashboard |
|---------|--------------|-----------|
| **Default Language** | Card's original language | Browser language |
| **Detection Method** | From card data | `navigator.languages` |
| **User Override** | Session-based | Persistent (localStorage) |
| **Purpose** | Respect card creator | User convenience |
| **Store Used** | `useMobileLanguageStore` | `useDashboardLanguageStore` |

## Testing

### Test Scenario 1: English Card, English Browser
1. Create card in English (no translations)
2. Use English browser to scan QR
3. ✅ **Expected:** Card displays in English
4. ✅ **Expected:** 1 API call

### Test Scenario 2: Chinese Card, English Browser
1. Create card in Chinese (original)
2. Use English browser to scan QR
3. ✅ **Expected:** Card displays in Chinese (not English!)
4. ✅ **Expected:** 2 API calls (first with en, then with zh-Hant)

### Test Scenario 3: English Card, Chinese Browser
1. Create card in English (original)
2. Use Chinese browser to scan QR
3. ✅ **Expected:** Card displays in English (not Chinese!)
4. ✅ **Expected:** 1 API call

### Test Scenario 4: User Switches Language
1. Scan English card
2. Manually switch to Chinese
3. ✅ **Expected:** Content re-fetches in Chinese
4. ✅ **Expected:** Language selector marks user selection
5. Navigate to different page within same session
6. ✅ **Expected:** Still shows Chinese (session persists)

### Test Scenario 5: New Session
1. Complete Test Scenario 4
2. Close browser tab
3. Open new tab and scan same card
4. ✅ **Expected:** Resets to English (original language)

### Test Scenario 6: Multiple Cards in Session
1. Scan English card (displays in English)
2. Manually switch to Chinese
3. Scan different Chinese card in same session
4. ✅ **Expected:** Shows in Chinese (user preference)

## Files Modified

- ✅ `src/stores/language.ts` - Removed browser detection from mobile store
- ✅ `src/views/MobileClient/PublicCardView.vue` - Added original language detection
- ✅ `src/views/MobileClient/components/LanguageSelectorModal.vue` - Added session marker

## Performance Impact

- **First Load:** +1 API call if card's original language ≠ English (~10% of cases)
- **Subsequent Loads:** No impact (uses correct language immediately)
- **User Switches:** No change (same as before)
- **Overall:** Minimal - trade-off for better UX

## Migration Notes

### Existing Users
- No migration needed - sessionStorage is empty on first visit
- Will see card in original language (as intended)

### Developers
- Dashboard language behavior unchanged
- Mobile client now respects card's original language
- Two separate stores provide clean separation of concerns

## Related Features
- Mobile Language Selector (showing available languages)
- Translation System (original_language field)
- Browser Language Detection (dashboard only)
- Session Management (sessionStorage)

## Future Enhancements

### Possible Improvements:
1. **Smart caching:** Cache original language by card ID to skip second fetch
2. **URL parameter:** Support `?lang=zh-Hant` to override default
3. **GeoIP detection:** Suggest language based on visitor location
4. **Analytics:** Track which languages visitors prefer

### Not Recommended:
- ❌ Always use browser language (defeats creator's intent)
- ❌ Remove two-API-call pattern (adds complexity)
- ❌ Use localStorage for mobile (prevents per-session reset)

## Conclusion

This fix ensures mobile visitors see cards in the language intended by the creator, while still allowing manual language switching. The implementation is clean, maintains separation between mobile and dashboard stores, and provides a better user experience aligned with the platform's multilingual vision.

