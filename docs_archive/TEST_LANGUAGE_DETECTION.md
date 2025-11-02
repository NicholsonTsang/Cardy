# Browser Language Detection Testing Guide

## Quick Test in Browser Console

### 1. Check Current State
```javascript
// Check current language
console.log('Current locale:', localStorage.getItem('userLocale'))
console.log('Browser languages:', navigator.languages)
console.log('Browser language:', navigator.language)

// Check i18n state (if available)
console.log('Active locale:', document.documentElement.lang)
```

### 2. Test Auto-Detection
```javascript
// Clear saved preference and reload
localStorage.removeItem('userLocale')
location.reload()

// After reload, check what was detected
console.log('Detected locale:', localStorage.getItem('userLocale'))
```

### 3. Simulate Different Browser Languages

#### English
```javascript
// Manually set English (for testing only)
localStorage.setItem('userLocale', 'en')
location.reload()
```

#### Simplified Chinese
```javascript
// Manually set Simplified Chinese
localStorage.setItem('userLocale', 'zh-Hans')
location.reload()
```

#### Traditional Chinese
```javascript
// Manually set Traditional Chinese
localStorage.setItem('userLocale', 'zh-Hant')
location.reload()
```

#### Spanish
```javascript
// Manually set Spanish
localStorage.setItem('userLocale', 'es')
location.reload()
```

### 4. Test Fallback Behavior
```javascript
// Clear preference to test auto-detection
localStorage.removeItem('userLocale')

// Check what the browser would detect
const browserLang = (navigator.languages || [navigator.language])[0]
console.log('Browser would detect:', browserLang)

// Reload to see actual detection
location.reload()
```

## Browser Settings Testing

### Chrome/Edge
1. Go to `chrome://settings/languages`
2. Add/reorder languages
3. Clear `localStorage.userLocale`
4. Reload the app
5. Verify correct language displays

### Firefox
1. Go to `about:preferences#general`
2. Click "Set Alternatives" under Language
3. Reorder languages
4. Clear `localStorage.userLocale`
5. Reload the app
6. Verify correct language displays

### Safari
1. Go to System Preferences → Language & Region
2. Modify Preferred Languages order
3. Restart Safari
4. Clear `localStorage.userLocale` in Web Inspector
5. Reload the app
6. Verify correct language displays

## Expected Behaviors

### Scenario 1: First-Time User (English Browser)
- **Browser Language:** `en` or `en-US`
- **Expected Result:** App displays in English
- **Language Selector:** Shows English (🇺🇸 EN)
- **Console Log:** `"✅ Exact language match found: en English"`

### Scenario 2: First-Time User (Chinese - Simplified)
- **Browser Language:** `zh-CN`, `zh`, or `zh-Hans`
- **Expected Result:** App displays in Simplified Chinese
- **Language Selector:** Shows 简体中文 (🇨🇳 ZH-HANS)
- **Console Log:** `"✅ Exact language match found: zh-Hans 简体中文"`

### Scenario 3: First-Time User (Chinese - Traditional)
- **Browser Language:** `zh-TW`, `zh-HK`, or `zh-Hant`
- **Expected Result:** App displays in Traditional Chinese
- **Language Selector:** Shows 繁體中文 (🇭🇰 ZH-HANT)
- **Console Log:** `"✅ Exact language match found: zh-Hant 繁體中文"`
- **Voice Preference:** Cantonese (for mobile client)

### Scenario 4: First-Time User (Unsupported Language)
- **Browser Language:** `de` (German), `pt` (Portuguese), etc.
- **Expected Result:** App displays in English (fallback)
- **Language Selector:** Shows English (🇺🇸 EN)
- **Console Log:** `"ℹ️ No language match found, defaulting to English"`

### Scenario 5: Returning User
- **Browser Language:** Any
- **Saved Preference:** `zh-Hant` (from previous visit)
- **Expected Result:** App displays in Traditional Chinese (saved preference wins)
- **Language Selector:** Shows 繁體中文 (🇭🇰 ZH-HANT)
- **Console Log:** No detection log (saved preference loaded directly)

### Scenario 6: User Changes Language Manually
1. **Initial:** Auto-detected to Spanish
2. **User Action:** Selects Japanese from language selector
3. **Expected Result:** 
   - App switches to Japanese immediately
   - Preference saved to `localStorage`
   - Future visits show Japanese (no auto-detection)

## Verification Checklist

### ✅ Auto-Detection
- [ ] English browser → English UI
- [ ] Simplified Chinese browser → Simplified Chinese UI
- [ ] Traditional Chinese browser → Traditional Chinese UI
- [ ] Japanese browser → Japanese UI
- [ ] Korean browser → Korean UI
- [ ] Unsupported language → English fallback

### ✅ User Preference
- [ ] Manual selection saves to localStorage
- [ ] Saved preference persists across refreshes
- [ ] Saved preference takes priority over browser language

### ✅ Language Selector
- [ ] Shows correct language after auto-detection
- [ ] Shows correct language after manual selection
- [ ] All 10 languages are selectable
- [ ] Selected language has checkmark

### ✅ Chinese Language Features
- [ ] Simplified Chinese → Mandarin voice (mobile)
- [ ] Traditional Chinese → Cantonese voice (mobile)
- [ ] Voice selector only appears for Chinese languages

### ✅ i18n Integration
- [ ] UI text changes to selected language
- [ ] Document `lang` attribute updates
- [ ] RTL support for Arabic
- [ ] Fallback to English for incomplete translations

### ✅ Console Logs
- [ ] Detection logs appear on first load
- [ ] Initialization logs show detected language
- [ ] No errors in console

## Edge Cases to Test

### Multiple Browser Languages
```javascript
// If browser has: ['zh-HK', 'en-US', 'ja']
// Expected: zh-Hant (first match wins)
```

### Legacy Language Codes
```javascript
// Browser sends: 'zh-CN'
// Expected: Normalized to 'zh-Hans'
```

### Case Variations
```javascript
// Browser sends: 'EN-US', 'En', 'en'
// Expected: All match to 'en'
```

### Missing `navigator.languages`
```javascript
// Some browsers only have `navigator.language`
// Expected: Falls back gracefully
```

## Debugging Tools

### Check Detection Logic
```javascript
// Paste this in console to see what would be detected
function testDetection() {
  const languages = navigator.languages || [navigator.language]
  console.log('Browser languages:', languages)
  
  const supported = ['en', 'zh-Hant', 'zh-Hans', 'ja', 'ko', 'th', 'es', 'fr', 'ru', 'ar']
  
  for (const lang of languages) {
    const normalized = lang.toLowerCase()
    const match = supported.find(s => s.toLowerCase() === normalized.split('-')[0])
    if (match) {
      console.log(`✅ Would detect: ${match}`)
      return
    }
  }
  
  console.log('ℹ️ Would default to: en')
}

testDetection()
```

### Reset to Fresh State
```javascript
// Complete reset
localStorage.clear()
location.reload()
```

### Force Specific Language (Testing Only)
```javascript
// Force a specific language for testing
function forceLanguage(locale) {
  localStorage.setItem('userLocale', locale)
  location.reload()
}

// Examples:
forceLanguage('zh-Hant')  // Traditional Chinese
forceLanguage('ja')       // Japanese
forceLanguage('en')       // English
```

## Performance Checks

### Timing
- Language detection should complete < 10ms
- No noticeable delay in page load
- No flash of wrong language

### Memory
- No memory leaks from detection logic
- Stores clean up properly
- No lingering references

## Accessibility

- [ ] Screen readers announce correct language
- [ ] Language selector keyboard accessible
- [ ] Focus states visible
- [ ] ARIA labels in correct language

## Mobile Testing

### iOS Safari
- Test with different system languages
- Verify language selector works (bottom sheet)
- Check voice preferences for Chinese

### Android Chrome
- Test with different system languages
- Verify language selector works
- Check mobile responsive behavior

---

**Last Updated:** January 2025  
**Status:** Ready for testing  
**Next:** Production deployment

