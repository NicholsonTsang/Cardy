# Translation Preview Feature

## Overview

Added translation preview functionality to the dashboard, allowing card issuers to review their translated content directly in the card view and content detail sections without needing to access the mobile client.

## Implementation Summary

### Components Modified

#### 1. **CardView.vue** (Card Details View)
- **Location**: `/src/components/CardComponents/CardView.vue`
- **Changes**:
  - Added a language dropdown selector in the "Basic Information" section header
  - Dropdown shows all available translations for the card
  - Displays flag emoji and language name for each option
  - Original language option labeled as "(Original)"
  - Updates displayed card name and description based on selected language

#### 2. **CardContentView.vue** (Content Item Details)
- **Location**: `/src/components/CardContent/CardContentView.vue`
- **Changes**:
  - Added a language dropdown selector in the "Basic Information" section header
  - Dropdown shows all available translations for the content item
  - Updates displayed item name and content based on selected language
  - Falls back to original language if translation is not available

#### 3. **Translation Keys** (i18n)
- **Location**: `/src/i18n/locales/en.json`
- **Changes**:
  - Added `"previewLanguage": "Preview Translation"` - Dropdown placeholder text
  - Added `"original": "Original"` - Label for original language option

## Features

### Card View Translation Preview
1. **Language Selector**:
   - Located in top-right of "Basic Information" section
   - Only appears when translations exist for the card
   - Dropdown width: 48 units (w-48)
   - Small size for compact display

2. **Language Options**:
   - First option: Original language (e.g., "English (Original)")
   - Subsequent options: Translated languages (e.g., "繁體中文", "日本語")
   - Each option displays flag emoji + language name

3. **Dynamic Content Display**:
   - Card name updates based on selected language
   - Card description updates based on selected language
   - Markdown rendering preserved for translated content
   - Falls back to original if translation unavailable

### Content Item Translation Preview
1. **Language Selector**:
   - Located in top-right of "Basic Information" section
   - Only appears when translations exist for the content item
   - Same UI pattern as card view for consistency

2. **Language Options**:
   - First option: "Original"
   - Subsequent options: All translated languages

3. **Dynamic Content Display**:
   - Content item name updates based on selected language
   - Content item content (description) updates based on selected language
   - Markdown rendering preserved for translated content
   - Falls back to original if translation unavailable

## Data Structure

### Card Translations (from database)
```typescript
// props.cardProp.translations
{
  "zh-Hans": {
    "name": "卡片名称",
    "description": "卡片描述",
    "translated_at": "2025-01-10T12:00:00Z",
    "content_hash": "abc123"
  },
  "ja": {
    "name": "カード名",
    "description": "カードの説明",
    "translated_at": "2025-01-10T12:00:00Z",
    "content_hash": "abc123"
  }
  // ... other languages
}
```

### Content Item Translations (from database)
```typescript
// props.contentItem.translations
{
  "zh-Hans": {
    "name": "内容项名称",
    "content": "内容项描述",
    "translated_at": "2025-01-10T12:00:00Z",
    "content_hash": "def456"
  },
  "ja": {
    "name": "コンテンツ項目名",
    "content": "コンテンツ項目の説明",
    "translated_at": "2025-01-10T12:00:00Z",
    "content_hash": "def456"
  }
  // ... other languages
}
```

## Technical Implementation

### State Management
Both components use local Vue `ref` for selected language:
```typescript
const selectedPreviewLanguage = ref(null); // null = original language
```

### Computed Properties
1. **availableTranslations**: Parses `translations` JSONB object to extract language codes
2. **languageOptions**: Generates dropdown options with labels and values
3. **displayedCardName** / **displayedItemName**: Returns translated name or falls back to original
4. **displayedCardDescription** / **displayedItemContent**: Returns translated content or falls back to original

### Helper Functions
- **getLanguageName(langCode)**: Returns language name from `SUPPORTED_LANGUAGES`
- **getLanguageFlag(langCode)**: Returns flag emoji from `SUPPORTED_LANGUAGES`

### Import Dependencies
- `Dropdown` from PrimeVue
- `SUPPORTED_LANGUAGES` from `@/stores/translation`
- Standard Vue composition API (`computed`, `ref`)

## UI/UX Details

### Dropdown Styling
- **Template**: Custom value and option templates with flag + name
- **Size**: `small` size for compact appearance
- **Width**: `w-48` (192px) for adequate space
- **Placeholder**: `"Preview Translation"`

### Visual Consistency
- Same design pattern in both CardView and CardContentView
- Positioned in section headers next to title
- Only visible when translations exist
- Seamless integration with existing UI

### Behavior
- **Default State**: Shows original language (selectedPreviewLanguage = null)
- **Language Change**: Immediately updates displayed content
- **No Translations**: Dropdown hidden, always shows original
- **Missing Translation**: Falls back to original language content

## Use Cases

### 1. Review Translations Before Publishing
Card issuers can:
- Switch between languages to verify translation quality
- Check if all fields are properly translated
- Identify missing translations
- Compare original vs. translated content side-by-side (by switching)

### 2. Quality Assurance
- Verify markdown formatting is preserved
- Check for translation accuracy
- Ensure cultural context is appropriate
- Validate character encoding and display

### 3. Debug Translation Issues
- Identify which languages are translated
- Check if translation data is correctly stored
- Verify fallback behavior works
- Test edge cases (missing translations, special characters)

## Future Enhancements (Optional)

### Potential Improvements
1. **Side-by-Side View**: Show original and translated content simultaneously
2. **Translation Status Badge**: Indicate if current translation is outdated
3. **Inline Editing**: Edit translations directly in preview mode
4. **Translation Diff**: Highlight differences between versions
5. **Export Preview**: Generate PDF with selected language
6. **Mobile Preview**: Show how it will appear on mobile client

## Related Files

### Core Components
- `/src/components/CardComponents/CardView.vue`
- `/src/components/CardContent/CardContentView.vue`

### State Management
- `/src/stores/translation.ts` (SUPPORTED_LANGUAGES export)

### Localization
- `/src/i18n/locales/en.json` (translation keys)
- All other language files (should be synced)

### Database Schema
- `/sql/schema.sql` (cards.translations, content_items.translations)
- `/sql/storeproc/server-side/translation_management.sql` (store_card_translations)

## Testing Checklist

### Card View Tests
- [ ] Dropdown appears only when translations exist
- [ ] Dropdown hidden when no translations
- [ ] Original language option works correctly
- [ ] Switching to translated language updates name
- [ ] Switching to translated language updates description
- [ ] Markdown rendering works in translated content
- [ ] Flag emojis display correctly
- [ ] Language names display correctly
- [ ] Falls back to original if translation missing

### Content Item View Tests
- [ ] Dropdown appears only when translations exist
- [ ] Dropdown hidden when no translations
- [ ] Original language option works correctly
- [ ] Switching to translated language updates name
- [ ] Switching to translated language updates content
- [ ] Markdown rendering works in translated content
- [ ] Flag emojis display correctly
- [ ] Language names display correctly
- [ ] Falls back to original if translation missing

### Edge Cases
- [ ] Card with partial translations (some fields missing)
- [ ] Content item with no translations
- [ ] Special characters in translations
- [ ] Empty translation fields
- [ ] Very long translated content
- [ ] Languages with RTL scripts (Arabic)
- [ ] Languages with complex scripts (Chinese, Japanese, Thai)

## Documentation Status

✅ **Implementation Complete**
- Card view translation preview implemented
- Content item translation preview implemented
- Translation keys added to i18n
- No linter errors
- Documentation created

## Deployment Notes

### ⚠️ Database Update Required
The stored procedures need to be updated to return translation fields. 

**Steps to Deploy:**

1. **Update Stored Procedures** (via Supabase Dashboard SQL Editor):
   ```bash
   # Execute this file in Supabase Dashboard > SQL Editor
   sql/DEPLOY_TRANSLATION_PREVIEW_FUNCTIONS.sql
   ```
   
   This updates three functions:
   - `get_user_cards()` - now returns `translations`, `original_language`, `content_hash`, `last_content_update`
   - `get_card_content_items()` - now returns `translations`, `content_hash`, `last_content_update`
   - `get_content_item_by_id()` - now returns `translations`, `content_hash`, `last_content_update`

2. **Deploy Frontend Changes**:
   - `src/components/CardComponents/CardView.vue` (updated)
   - `src/components/CardContent/CardContentView.vue` (updated)
   - `src/stores/card.ts` (Card interface updated)
   - `src/i18n/locales/en.json` (translation keys added)

3. **Restart Application**:
   ```bash
   npm run dev
   ```

### Database Requirements
- Requires existing translation data in `cards.translations` JSONB column
- Requires existing translation data in `content_items.translations` JSONB column
- No database schema changes needed (uses existing structure)
- **Stored procedures must be updated** (see deployment steps above)

### Frontend Requirements
- PrimeVue Dropdown component
- Vue 3 Composition API
- `SUPPORTED_LANGUAGES` from translation store
- i18n setup with translation keys
- Updated Card interface in TypeScript

## Success Metrics

### Usability
- Card issuers can preview translations without leaving dashboard
- Reduces need to generate QR codes for testing
- Faster iteration on translation quality
- Better user confidence in translated content

### Technical
- Clean integration with existing components
- Reusable pattern for future translation features
- No performance impact (translations already loaded in card/content data)
- Maintains consistency with mobile client translation display

---

**Status**: ✅ Complete and Ready for Testing
**Date**: 2025-01-11
**Version**: 1.0

