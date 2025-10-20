# Mobile Client Language Availability Feature

## Overview
This feature disables unavailable languages in the mobile client language selector, showing users only languages that have been translated for the current card.

## Problem Solved
**Before:**
- All 10 languages were always enabled in the selector
- Users could select languages without translations
- Content would fall back to original language (confusing UX)
- No indication which languages are actually available

**After:**
- Only translated languages are enabled
- Unavailable languages are visually disabled with lock icon
- Clear indication of which languages have translations
- Better user experience and expectations management

## Implementation

### 1. Database Changes

#### Updated Stored Procedures
Added `card_available_languages TEXT[]` column to both functions:
- `get_public_card_content(p_issue_card_id, p_language)`
- `get_card_preview_content(p_card_id, p_language)`

**How Available Languages are Determined:**
```sql
-- Original language + languages with translations
ARRAY[c.original_language] || 
ARRAY(SELECT jsonb_object_keys(c.translations))
```

**Example Result:**
- Card with English original + Chinese translation → `{en, zh-Hant}`
- Card with English original only → `{en}`
- Card with English original + 5 translations → `{en, zh-Hant, zh-Hans, ja, ko, es}`

#### Files Modified:
- `sql/storeproc/client-side/07_public_access.sql`
- `sql/all_stored_procedures.sql` (regenerated)

### 2. Frontend Changes

#### A. PublicCardView.vue
Added state to track available languages:
```typescript
const availableLanguages = ref<string[]>([])

// Extract from API response
availableLanguages.value = firstRow.card_available_languages || 
                          [firstRow.card_original_language || 'en']
```

Passes to CardOverview:
```vue
<CardOverview 
  :card="cardData"
  :available-languages="availableLanguages"
/>
```

#### B. CardOverview.vue
Updated props to receive available languages:
```typescript
interface Props {
  card: { ... }
  availableLanguages?: string[]
}
```

Passes to LanguageSelectorModal:
```vue
<LanguageSelectorModal
  :available-languages="availableLanguages"
/>
```

#### C. LanguageSelectorModal.vue
**Key Logic:**
```typescript
// Check if language is available
const isLanguageAvailable = (langCode: string) => {
  if (!props.availableLanguages || props.availableLanguages.length === 0) {
    return true // No restriction
  }
  return props.availableLanguages.includes(langCode)
}

// Prevent selection of unavailable languages
function selectLanguage(language: Language) {
  if (!isLanguageAvailable(language.code)) {
    return // Blocked!
  }
  // ... normal selection
}
```

**Visual Changes:**
- Added `disabled` class for unavailable languages
- Added lock icon (`pi-lock`) for disabled languages
- Reduced opacity (0.5) for disabled languages
- Grayed out flag (opacity-30)
- Disabled hover effects

**CSS:**
```css
.language-option.disabled {
  opacity: 0.5;
  cursor: not-allowed;
  background: #f3f4f6;
}

.disabled-icon {
  position: absolute;
  top: 0.5rem;
  right: 0.5rem;
  color: #9ca3af;
}
```

#### Files Modified:
- `src/views/MobileClient/PublicCardView.vue`
- `src/views/MobileClient/components/CardOverview.vue`
- `src/views/MobileClient/components/LanguageSelectorModal.vue`

## User Experience

### Language Selector UI

**Available Language:**
```
┌──────────────┐
│   🇬🇧 ✓     │  <- Active (blue border, check mark)
│   English    │
└──────────────┘

┌──────────────┐
│   🇨🇳       │  <- Available (normal, clickable)
│   中文       │
└──────────────┘
```

**Unavailable Language:**
```
┌──────────────┐
│  🇯🇵 🔒     │  <- Disabled (grayed out, lock icon)
│  日本語      │  (opacity reduced, can't click)
└──────────────┘
```

### User Flow

1. **User scans QR code** → Loads card
2. **Backend returns** available languages: `{en, zh-Hant}`
3. **Mobile client** stores available languages
4. **User opens** language selector
5. **Languages shown:**
   - ✅ English - Active (currently selected)
   - ✅ 繁體中文 - Available (can select)
   - 🔒 简体中文 - Disabled (no translation)
   - 🔒 日本語 - Disabled (no translation)
   - 🔒 한국어 - Disabled (no translation)
   - ... (other unavailable languages)
6. **User clicks** available language → Switches successfully
7. **User clicks** disabled language → Nothing happens

## Testing

### Test Scenario 1: Card with Single Language (Original Only)
1. Create a card in English, **don't translate** it
2. Issue batch and scan QR code
3. Open language selector
4. ✅ **Expected**: Only English enabled, all others disabled with lock icons

### Test Scenario 2: Card with Multiple Translations
1. Create a card in English
2. Translate to Chinese (zh-Hant) and Japanese (ja)
3. Scan QR code
4. Open language selector
5. ✅ **Expected**: English, Chinese, Japanese enabled; others disabled

### Test Scenario 3: Language Switching
1. Card has EN and ZH translations
2. Currently viewing in English
3. Open selector → ZH enabled, click it
4. ✅ **Expected**: Content switches to Chinese
5. Open selector again → EN enabled, click it
6. ✅ **Expected**: Content switches back to English

### Test Scenario 4: Disabled Language Click
1. Card has only English
2. Open language selector
3. Try clicking Japanese (disabled)
4. ✅ **Expected**: Nothing happens, modal stays open, language doesn't change

### Test Scenario 5: Preview Mode
1. Go to Dashboard → Preview card
2. Card has EN + ZH translations
3. Open language selector
4. ✅ **Expected**: Same behavior as public mode (EN, ZH enabled; others disabled)

## Database Deployment

### Deployment Steps:
1. Navigate to Supabase Dashboard > SQL Editor
2. Execute `DEPLOY_LANGUAGE_AVAILABILITY_FEATURE.sql`
3. Verify with test query:
```sql
SELECT DISTINCT
    card_name,
    card_original_language,
    card_available_languages
FROM get_public_card_content('YOUR_ISSUE_CARD_ID', 'en');
```

### Rollback:
If needed, remove the `card_available_languages` column from both functions and redeploy old versions.

## Frontend Deployment

No special deployment steps needed - changes are backward compatible:
- If DB hasn't been updated: `availableLanguages` will be undefined → All languages enabled (backward compatible)
- If DB updated: `availableLanguages` will be array → Proper filtering applied

## Technical Details

### Why Array Instead of Object?
We return `TEXT[]` (string array) instead of JSONB for simplicity:
- Smaller payload
- Easier to check with `includes()`
- No need for complex object structure
- Just need language codes: `['en', 'zh-Hant', 'ja']`

### Performance Impact
**Database:**
- Minimal - `jsonb_object_keys()` is fast
- Only extracts keys from translations JSONB
- No additional table joins needed

**Frontend:**
- Negligible - Simple array lookup
- `includes()` check is O(n) where n = ~10 languages max
- Runs only when opening language selector

### Edge Cases Handled

1. **No translations:** Returns `[original_language]`
2. **Undefined availableLanguages:** All languages enabled (backward compatible)
3. **Empty array:** All languages enabled (fail-safe)
4. **User on disabled language:** Can still select (already viewing that language)
5. **Translation deleted:** Next fetch will update available languages

## Files Changed

### Database:
- ✅ `sql/storeproc/client-side/07_public_access.sql` - Added available_languages field
- ✅ `sql/all_stored_procedures.sql` - Regenerated combined file

### Frontend:
- ✅ `src/views/MobileClient/PublicCardView.vue` - Extract and pass available languages
- ✅ `src/views/MobileClient/components/CardOverview.vue` - Pass to selector modal
- ✅ `src/views/MobileClient/components/LanguageSelectorModal.vue` - Disable unavailable languages

### Documentation:
- ✅ `DEPLOY_LANGUAGE_AVAILABILITY_FEATURE.sql` - SQL deployment script
- ✅ `MOBILE_LANGUAGE_AVAILABILITY_FEATURE.md` - This file

## Future Enhancements

### Possible Improvements:
1. **Show translation quality** - "Professional" vs "Machine translated"
2. **Show translation date** - "Updated 2 days ago"
3. **Request translation button** - For disabled languages
4. **Language coverage percentage** - "90% translated"
5. **Toast notification** - "This language is not available for this card"

### Current Limitations:
- No indication of partial translations (some content items not translated)
- All-or-nothing approach (language either available or not)
- No fallback language indication in UI

## Related Features
- Translation Management System (Dashboard)
- Multi-language Translation (GPT-4 powered)
- Mobile Language Selection
- Content Translation Preview

## Conclusion

This feature provides a better user experience by:
- ✅ Setting clear expectations about language availability
- ✅ Preventing confusion from non-translated content
- ✅ Providing visual feedback (lock icon)
- ✅ Maintaining consistency with translation system

The implementation is clean, performant, and backward compatible with existing cards and deployments.

