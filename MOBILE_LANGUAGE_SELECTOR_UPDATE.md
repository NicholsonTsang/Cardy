# Mobile Language Selector Update

**Date**: November 9, 2025  
**Type**: UX Enhancement

## Overview

Updated the mobile client's language selector (`UnifiedLanguageModal.vue`) to show all languages as enabled, with visual badges indicating which languages have translated content. This allows users to select any language and view internationalized content, while providing clear visual feedback about translation availability.

## Changes Made

### 1. **Enable All Languages** (`UnifiedLanguageModal.vue`)
- **Before**: Languages without translations were disabled and showed a lock icon
- **After**: All languages are selectable regardless of translation status
- Users can now select any language - they'll see i18n text if no translation exists

### 2. **Translation Status Badge**
- Added green circular badge with checkmark icon to languages with translated content
- Badge appears in bottom-right corner of language option
- Subtle animation on hover (scales up slightly)
- Tooltip shows "Translated content available"

### 3. **Visual Design Updates**
- **Languages with translations**: Light green border (`#d1fae5`)
- **Languages with translations (hover)**: Green border (`#10b981`) with light green background
- **Badge styling**: Gradient green background with shadow
- **Removed**: Lock icon and disabled states
- **Result**: Clean, harmonious design that clearly communicates translation status

### 4. **Code Refactoring**
- Renamed `isLanguageAvailable()` → `hasTranslation()` for clarity
- Updated function logic: returns `false` when no translations, `true` when available
- Removed disabled state checks in `selectLanguage()` function
- All languages now selectable with proper comments explaining behavior

### 5. **Internationalization**
- Added new i18n key: `mobile.translated_content_available`
- Used for badge tooltip to explain status indicator

## User Experience

### Before
- ✗ Languages without translations were grayed out and locked
- ✗ Users couldn't select languages unless card had translations
- ✗ Lock icon was confusing and restrictive

### After
- ✓ All languages available for selection
- ✓ Green badge clearly shows which languages have translated content
- ✓ Users can switch to any language to see i18n interface text
- ✓ Visual hierarchy: translated languages subtly highlighted with green border
- ✓ Smooth, harmonious design with professional polish

## Technical Details

### Component Updates
- **File**: `src/views/MobileClient/components/UnifiedLanguageModal.vue`
- **Lines changed**: ~50 (template, script, styles)
- **New CSS classes**: `.translation-badge`, `.has-translation`
- **Removed CSS classes**: `.disabled`, `.disabled-icon`

### Translation Updates
- **File**: `src/i18n/locales/en.json`
- **New key**: `mobile.translated_content_available`

## Design Specifications

### Translation Badge
- **Size**: 20px × 20px circular
- **Position**: Bottom-right corner (0.5rem from edges)
- **Background**: Linear gradient `#10b981` → `#059669` (green)
- **Icon**: PrimeVue `pi-check-circle` at 0.625rem
- **Shadow**: `0 2px 4px rgba(16, 185, 129, 0.2)`
- **Hover effect**: Scale 1.1

### Border Colors
- **Default**: `#e5e7eb` (light gray)
- **Has translation**: `#d1fae5` (light green)
- **Has translation hover**: `#10b981` (green)
- **Active**: `#3b82f6` (blue)

## Impact

1. **User Flexibility**: Users can now view cards in any UI language, even without translations
2. **Clear Communication**: Badge immediately shows translation availability
3. **Better UX**: No more locked/disabled languages causing confusion
4. **Accessibility**: Maintains proper touch targets and color contrast
5. **Responsive**: Works seamlessly on mobile and desktop

## Testing Checklist

- [ ] All languages appear and are clickable
- [ ] Badge shows only on languages with translations
- [ ] Badge tooltip displays correctly
- [ ] Hover states work smoothly
- [ ] Selected language shows blue checkmark (top-right)
- [ ] Translated languages show green badge (bottom-right)
- [ ] Modal scrolls properly with many languages
- [ ] Works on both mobile and desktop viewports

## Future Considerations

- Could add different badge colors for different translation states (e.g., "partially translated")
- Could show percentage of content translated in tooltip
- Could add animation when translation becomes available

## Files Modified

1. `src/views/MobileClient/components/UnifiedLanguageModal.vue` - Main component
2. `src/i18n/locales/en.json` - Added translation key

## Related Components

- `CardOverview.vue` - Passes `availableLanguages` prop
- `PublicCardView.vue` - Fetches available languages from database
- `useMobileLanguageStore` - Manages language selection state

