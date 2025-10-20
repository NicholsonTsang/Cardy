# Language Selector Sync Fix

## Problem

**Symptom:** Language selector shows English, but website text displays in Traditional Chinese.

**Root Cause:** Mismatch between i18n locale and language store initialization.

### What Was Happening

1. **i18n initialization** (`src/i18n/index.ts`):
   - Reads `localStorage.userLocale` → finds `zh-Hant`
   - Sets i18n locale to Traditional Chinese
   - UI text renders in Traditional Chinese ✅

2. **Language store initialization** (`src/stores/language.ts`):
   - Runs `detectBrowserLanguage()` → returns English (for English browsers)
   - Sets `selectedLanguage` to English
   - Language selector shows English ❌

**Result:** UI text and language selector were out of sync.

## Solution

Updated both language stores to check localStorage **BEFORE** running browser detection.

### Priority Order (Fixed)
1. **Saved preference** (`localStorage.userLocale`) - highest priority
2. **Browser detection** - only if no saved preference
3. **English fallback** - if detection fails

### Code Changes

#### Before (Broken)
```typescript
export const useMobileLanguageStore = defineStore('mobileLanguage', () => {
  const initialLanguage = detectBrowserLanguage()  // Always detects
  const selectedLanguage = ref<Language>(initialLanguage)
  
  if (!localStorage.getItem('userLocale')) {
    setLocale(initialLanguage.code)  // Too late
  }
  // ...
})
```

#### After (Fixed)
```typescript
export const useMobileLanguageStore = defineStore('mobileLanguage', () => {
  function getInitialLanguage(): Language {
    const savedLocale = localStorage.getItem('userLocale')
    if (savedLocale) {
      const savedLang = AVAILABLE_LANGUAGES.find(lang => lang.code === savedLocale)
      if (savedLang) {
        console.log('📱 Mobile client loaded saved language:', savedLocale)
        return savedLang  // Use saved preference
      }
    }
    
    // No saved preference, detect browser language
    const detected = detectBrowserLanguage()
    setLocale(detected.code)
    console.log('📱 Mobile client initialized with browser language:', detected.code)
    return detected
  }

  const initialLanguage = getInitialLanguage()
  const selectedLanguage = ref<Language>(initialLanguage)
  // ...
})
```

## Verification

### Before Fix
```javascript
// localStorage has: userLocale = "zh-Hant"
// Browser language: en-US

// Console logs:
🌐 Browser languages: ['en-US', 'en']
✅ Exact language match found: en English
📱 Mobile client initialized with browser language: en

// Result:
// - i18n locale: zh-Hant (from localStorage)
// - selectedLanguage: en (from detection)
// - Language selector: Shows English ❌
// - UI text: Traditional Chinese ✅
```

### After Fix
```javascript
// localStorage has: userLocale = "zh-Hant"
// Browser language: en-US

// Console logs:
📱 Mobile client loaded saved language: zh-Hant

// Result:
// - i18n locale: zh-Hant (from localStorage)
// - selectedLanguage: zh-Hant (from localStorage)
// - Language selector: Shows 繁體中文 ✅
// - UI text: Traditional Chinese ✅
```

## Testing

### Test Case 1: Returning User with Saved Preference
```javascript
// Setup
localStorage.setItem('userLocale', 'zh-Hant')

// Reload page
location.reload()

// Expected:
// - Language selector shows: 繁體中文 (🇭🇰 ZH-HANT)
// - UI text in: Traditional Chinese
// - Console: "📱 Mobile client loaded saved language: zh-Hant"
```

### Test Case 2: First-Time User (No Saved Preference)
```javascript
// Setup
localStorage.removeItem('userLocale')

// Reload page with English browser
location.reload()

// Expected:
// - Language selector shows: English (🇺🇸 EN)
// - UI text in: English
// - Console: "✅ Exact language match found: en English"
// - Console: "📱 Mobile client initialized with browser language: en"
```

### Test Case 3: First-Time User (Chinese Browser)
```javascript
// Setup
localStorage.removeItem('userLocale')

// Reload page with Chinese browser (zh-HK, zh-TW)
location.reload()

// Expected:
// - Language selector shows: 繁體中文 (🇭🇰 ZH-HANT)
// - UI text in: Traditional Chinese
// - Console: "✅ Exact language match found: zh-Hant 繁體中文"
// - Console: "📱 Mobile client initialized with browser language: zh-Hant"
```

### Quick Verification in Console
```javascript
// Check current state
console.log('Saved locale:', localStorage.getItem('userLocale'))
console.log('i18n locale:', document.documentElement.lang)

// They should match!
```

## Files Modified

1. **`src/stores/language.ts`**
   - Updated `useMobileLanguageStore` initialization
   - Updated `useDashboardLanguageStore` initialization
   - Added `getInitialLanguage()` helper function to both stores
   - Ensures saved preference takes priority over browser detection

## Impact

### ✅ Fixed
- Language selector now shows correct language
- UI text and selector are synchronized
- Saved preferences work correctly
- Browser detection works for new users

### ✅ Preserved
- Auto-detection for first-time users
- Manual language selection
- localStorage persistence
- Chinese voice preferences

## Related Issues

This fix ensures the following flow works correctly:

1. **User visits site for first time:**
   - Browser language detected (e.g., Spanish)
   - Language selector shows Spanish ✅
   - UI text in Spanish ✅

2. **User manually changes language:**
   - Selects Traditional Chinese
   - Language saved to localStorage
   - Language selector shows Traditional Chinese ✅
   - UI text in Traditional Chinese ✅

3. **User returns later:**
   - Saved preference loaded (Traditional Chinese)
   - Language selector shows Traditional Chinese ✅
   - UI text in Traditional Chinese ✅
   - Browser language ignored (English) ✅

## Additional Notes

### Why This Happened

The initial implementation had a race condition where:
1. i18n initialized first (read localStorage correctly)
2. Language stores initialized second (ran detection, ignored localStorage)
3. Two systems ended up with different language values

### The Fix

Now both systems check localStorage first, ensuring they're always in sync.

### Console Logs

You'll now see clearer logs:
- **With saved preference:** `"📱 Mobile client loaded saved language: zh-Hant"`
- **Without saved preference:** `"📱 Mobile client initialized with browser language: en"`

This makes debugging much easier.

---

**Date:** January 2025  
**Status:** ✅ Fixed and tested  
**Impact:** Critical - fixes language selector synchronization bug

