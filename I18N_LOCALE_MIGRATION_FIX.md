# i18n Locale Migration Fix

## Problem

After updating Chinese language codes from `zh-CN`/`zh-HK` to `zh-Hans`/`zh-Hant`, users were seeing i18n warnings:

```
[intlify] Not found 'mobile.items' key in 'zh' locale messages.
[intlify] Fall back to translate 'mobile.items' key with 'en' locale.
```

This was caused by:
1. Old locale codes stored in localStorage (`'zh'`, `'zh-CN'`, `'zh-HK'`)
2. Missing locale aliases in i18n configuration
3. No migration path for legacy locale codes

## Solution

### 1. Added Locale Aliases

**File**: `src/i18n/index.ts`

Added legacy locale codes as aliases in the messages object:
```typescript
messages: {
  en,
  'zh-Hant': zhHant,
  'zh-Hans': zhHans,
  'zh': zhHans,        // Alias 'zh' → Simplified
  'zh-CN': zhHans,     // Alias 'zh-CN' → Simplified
  'zh-HK': zhHant,     // Alias 'zh-HK' → Traditional
  // ... other locales
}
```

### 2. Added Fallback Configuration

Added fallback logic for legacy locales:
```typescript
fallbackLocale: {
  'zh': ['zh-Hans', 'zh-Hant', 'en'],
  'zh-CN': ['zh-Hans', 'en'],
  'zh-HK': ['zh-Hant', 'en'],
  'default': ['en']
}
```

### 3. Added Locale Normalization on Init

Automatically migrates localStorage on app load:
```typescript
const rawSavedLocale = localStorage.getItem('userLocale') || 'en'
const savedLocale = normalizeLocaleInit(rawSavedLocale)

// Update localStorage if we normalized it
if (savedLocale !== rawSavedLocale) {
  localStorage.setItem('userLocale', savedLocale)
  console.log(`🔄 Migrated locale from '${rawSavedLocale}' to '${savedLocale}'`)
}
```

**Normalization Rules**:
- `zh` → `zh-Hans` (Simplified)
- `zh-CN` → `zh-Hans` (Simplified)
- `zh-HK` → `zh-Hant` (Traditional)
- `zh-TW` → `zh-Hant` (Traditional)
- `zh-SG` → `zh-Hans` (Simplified)

### 4. Added Locale Normalization in setLocale()

Prevents setting legacy locale codes:
```typescript
export function setLocale(locale: string) {
  // Normalize legacy locale codes
  const normalizedLocale = normalizeLocale(locale)
  
  i18n.global.locale.value = normalizedLocale
  localStorage.setItem('userLocale', normalizedLocale)
  // ...
}
```

### 5. Added Datetime & Number Formats

Added formats for legacy locale codes to prevent warnings:
```typescript
datetimeFormats: {
  // ... existing formats
  'zh': { /* formats */ },
  'zh-CN': { /* formats */ },
  'zh-HK': { /* formats */ },
}

numberFormats: {
  // ... existing formats
  'zh': { currency: { style: 'currency', currency: 'CNY' } },
  'zh-CN': { currency: { style: 'currency', currency: 'CNY' } },
  'zh-HK': { currency: { style: 'currency', currency: 'HKD' } },
}
```

## Result

✅ **No more i18n warnings**  
✅ **Automatic migration** from legacy locale codes  
✅ **Backward compatibility** maintained  
✅ **Clean localStorage** with new locale codes  

## Console Logs

When a user with old locale opens the app, they'll see:
```
🔄 Migrated locale from 'zh' to 'zh-Hans'
```

## Testing

### Before Fix:
- User has `'zh'` in localStorage
- Opens app → Sees i18n warnings
- Falls back to English for missing keys

### After Fix:
- User has `'zh'` in localStorage
- Opens app → Console shows migration message
- localStorage updated to `'zh-Hans'`
- No warnings, correct translations shown

## Files Modified

1. `src/i18n/index.ts` - Added aliases, fallbacks, and normalization

## Backward Compatibility

The fix maintains full backward compatibility:
- ✅ Old apps with `'zh'` in localStorage work
- ✅ Old code using `'zh-CN'`/`'zh-HK'` works
- ✅ Gradual migration to new locale codes
- ✅ No breaking changes

## Future Considerations

1. **Remove Legacy Aliases** (Optional): After sufficient migration time, legacy aliases can be removed
2. **User Notification** (Optional): Could add UI notification about locale migration
3. **Analytics**: Track how many users were migrated from legacy locales

## Related

- `CHINESE_VOICE_SELECTION_FEATURE.md` - Why we changed locale codes
- `src/stores/language.ts` - Language store using new codes
- `CLAUDE.md` - Project documentation

---

**Status**: ✅ Fixed and deployed  
**Impact**: Eliminates all i18n warnings for Chinese users  
**Compatibility**: 100% backward compatible

