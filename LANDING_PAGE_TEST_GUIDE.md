# Landing Page i18n - Testing Guide

## 🧪 Quick Test (5 Minutes)

### Step 1: Clear Browser State
```javascript
// Open browser console (F12) and run:
localStorage.removeItem('userLocale')
location.reload()
```

### Step 2: Visit Landing Page
1. Navigate to `http://localhost:5173` (or your dev URL)
2. The page should load in your browser's default language

### Step 3: Test Language Selector
1. Look at the top-right navigation
2. You should see a language selector button (flag + language code)
3. Click it to open the language modal

### Step 4: Switch to Traditional Chinese
1. Select "繁體中文 🇭🇰" (Traditional Chinese)
2. Modal should close
3. Observe the changes:

**Navigation Bar:**
```
Before: About | Demo | Pricing | Contact | Sign In | Start Free Trial
After:  關於 | 演示 | 價格 | 聯絡 | 登入 | 開始免費試用
```

**Hero Section:**
```
Before: "Trusted by 500+ Museums Worldwide"
After:  "全球 500+ 博物館信賴之選"

Before: "Transform Visits Into Unforgettable Experiences"
After:  "將參觀體驗轉化為難忘的回憶"
```

**Stats Bar:**
```
Before: Museums & Venues | Cards Issued | Visitor Satisfaction | Global Support
After:  博物館及場館 | 已發行卡片 | 訪客滿意度 | 全球支援
```

**Footer:**
```
Before: Privacy | Terms | Contact | All rights reserved
After:  隱私 | 條款 | 聯絡 | 版權所有
```

### Step 5: Switch Back to English
1. Click language selector again
2. Select "English 🇺🇸"
3. Everything should switch back to English

### Step 6: Test Persistence
1. Refresh the page (F5)
2. Language should remain as you last selected
3. No flashing or language switching on load

### Step 7: Test Mobile Menu
1. Resize browser to mobile width (< 1024px)
2. Click hamburger menu (☰)
3. Verify menu items are in the selected language
4. Try switching language from mobile view

## ✅ Expected Results

### What Should Work:
- ✅ Language selector visible in navigation
- ✅ Language modal opens and closes smoothly
- ✅ Switching language updates all translated sections instantly
- ✅ No page reload when switching languages
- ✅ Language preference persists after refresh
- ✅ Mobile menu displays in correct language
- ✅ No console errors or warnings

### What Sections Are Translated:
- ✅ Navigation (About, Demo, Pricing, Contact)
- ✅ Buttons (Sign In, Start Free Trial)
- ✅ Hero section (badge, title, subtitle, CTAs, trust indicators)
- ✅ Stats bar (all 4 labels)
- ✅ Footer (links and copyright)

### What's Still in English:
- ⏸️ About section body
- ⏸️ Demo section body
- ⏸️ Features section
- ⏸️ Other body sections

## 🐛 Troubleshooting

### Issue: Language selector doesn't appear
**Solution**: Make sure you've saved the LandingPage.vue file with the DashboardLanguageSelector import

### Issue: Console error about missing translation key
**Solution**: Check that you've saved both locale files (en.json and zh-Hant.json)

### Issue: Some text doesn't switch
**Solution**: That's expected - only navigation, hero, stats, and footer are currently translated

### Issue: Language doesn't persist after refresh
**Solution**: Check browser console for localStorage errors. Clear cache and try again.

### Issue: Chinese characters show as boxes
**Solution**: This is a font issue. Modern browsers should handle this automatically.

## 📱 Mobile Testing

### iPhone/Safari:
1. Open in Safari on iPhone
2. Tap language selector
3. Bottom sheet should appear
4. Select language
5. Verify text updates

### Android/Chrome:
1. Open in Chrome on Android
2. Tap language selector  
3. Modal should appear centered
4. Select language
5. Verify text updates

## 🎯 Advanced Testing

### Test Browser Language Auto-Detection:
```javascript
// 1. Clear localStorage
localStorage.clear()

// 2. Reload page
location.reload()

// 3. Check what language was detected
console.log('Detected language:', localStorage.getItem('userLocale'))
console.log('Browser languages:', navigator.languages)
```

### Test All Language Combinations:
1. English → Traditional Chinese → English
2. Clear localStorage → Visit page → Should detect browser language
3. Select language → Refresh → Should persist
4. Desktop view → Mobile view → Language should stay consistent

## ✨ Success Criteria

You can consider the landing page i18n successful if:

1. ✅ Language selector is visible and clickable
2. ✅ Clicking selector shows language options  
3. ✅ Selecting a language updates the UI instantly
4. ✅ Navigation, hero, stats, footer all switch languages
5. ✅ No console errors appear
6. ✅ Language choice persists after refresh
7. ✅ Mobile menu works in both languages
8. ✅ Layout looks good in both languages
9. ✅ Chinese characters display correctly
10. ✅ User experience feels smooth and professional

## 🎓 What to Look For

### Good Signs:
- Smooth language transitions
- No page flicker or reload
- Consistent styling in both languages
- Professional translations
- Clean, modern language selector UI

### Red Flags (report if you see these):
- Console errors about missing keys
- Text staying in wrong language
- Layout breaking in Chinese
- Language selector not appearing
- Language not persisting

## 📊 Performance Check

The i18n system should be very lightweight:

```javascript
// Check performance in console
performance.mark('language-switch-start')
// Switch language
performance.mark('language-switch-end')
performance.measure('language-switch', 'language-switch-start', 'language-switch-end')
console.log(performance.getEntriesByName('language-switch'))
// Should be < 50ms
```

## 🎉 You're Done!

If all tests pass, congratulations! You now have a professional bilingual landing page ready for international users.

---

**Test Duration**: 5-10 minutes  
**Difficulty**: Easy  
**Browser**: Chrome, Safari, Firefox (all should work)  
**Mobile**: iOS Safari, Android Chrome (both should work)

**Happy Testing!** 🚀


