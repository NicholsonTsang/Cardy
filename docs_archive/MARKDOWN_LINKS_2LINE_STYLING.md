# Markdown Links - 2-Line Display with Ellipsis

## Summary

Enhanced markdown link styling across **all markdown preview areas** (mobile client, dashboard, and markdown editors) to display links with a maximum of 2 lines, showing ellipsis (...) for text overflow. This prevents long URLs from breaking the layout and improves readability across the entire application.

**Scope**: Mobile client views + Dashboard preview components + Markdown editor previews

## Changes Made

### Files Modified

**Mobile Client:**
1. **`src/views/MobileClient/components/ContentDetail.vue`**
   - Added 2-line clamp CSS to `.content-description :deep(a)`

2. **`src/views/MobileClient/components/CardOverview.vue`**
   - Added 2-line clamp CSS to `.markdown-content :deep(a)`

**Dashboard Components:**
3. **`src/components/CardComponents/CardView.vue`**
   - Updated to use centralized `renderMarkdown` utility
   - Removed duplicate markdown rendering function
   - Added 2-line clamp CSS to `.prose a`

4. **`src/components/CardContent/CardContentView.vue`**
   - Updated to use centralized `renderMarkdown` utility
   - Removed duplicate markdown rendering function
   - Added 2-line clamp CSS to `.prose :deep(a)`

5. **`src/components/Admin/AdminCardContent.vue`**
   - Updated to use centralized `renderMarkdown` utility
   - Removed duplicate markdown rendering function
   - Added new style section with `.prose :deep(a)` styling

**Markdown Editor Components:**
6. **`src/components/CardContent/CardContentCreateEditForm.vue`**
   - Added `onHtmlChanged` handler to post-process preview HTML
   - Added target="_blank" to links in editor preview
   - Added 2-line clamp CSS to `:deep(.md-editor-preview-wrapper) a`

7. **`src/components/CardComponents/CardCreateEditForm.vue`**
   - Added `onHtmlChanged` handler to post-process preview HTML
   - Added target="_blank" to links in editor preview
   - Added 2-line clamp CSS to `:deep(.md-editor-preview-wrapper) a`

### CSS Implementation

```css
.markdown-content :deep(a) {
  color: #60a5fa; /* or #93c5fd depending on component */
  text-decoration: underline;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
  text-overflow: ellipsis;
  word-break: break-word;
}
```

## Visual Behavior

### Before
```
[This is a very long link text that wraps across
multiple lines and can break the layout or make the
content difficult to read especially on mobile devices]
```

### After
```
[This is a very long link text that wraps across
multiple lines and can break the layout or make t...]
```

## Technical Details

### CSS Properties Explained

- **`display: -webkit-box`**: Enables flexbox container for line clamping
- **`-webkit-line-clamp: 2`**: Limits content to 2 lines
- **`-webkit-box-orient: vertical`**: Sets vertical stacking for line clamping
- **`overflow: hidden`**: Hides overflow content
- **`text-overflow: ellipsis`**: Shows ellipsis (...) for truncated text
- **`word-break: break-word`**: Allows long words to break for better wrapping

## Benefits

1. **Layout Protection**: Long URLs no longer break the mobile layout
2. **Improved Readability**: Clean, consistent link display
3. **Mobile-Optimized**: Better use of limited screen space
4. **Professional Appearance**: Polished, production-ready look
5. **User Experience**: Links remain fully clickable despite truncation

## Browser Compatibility

- ✅ Chrome/Edge (all versions)
- ✅ Safari (all versions)  
- ✅ Firefox (requires `-moz-` prefix fallback in some older versions)
- ✅ Mobile browsers (iOS Safari, Chrome Mobile)

### Legacy Browser Support

For older Firefox versions, you may need to add:
```css
-moz-box-orient: vertical;
```

However, this is already well-supported in modern browsers.

## Testing Scenarios

### Short Links (Normal Display)
```markdown
Visit [our website](https://example.com) for more info.
```
**Result**: Displays normally on one line

### Long Link Text (Truncated)
```markdown
[This is a very long descriptive link text that provides detailed information about where this link will take you and what you will find there](https://example.com)
```
**Result**: Displays 2 lines with ellipsis at the end

### Long URLs (Truncated)
```markdown
[Click here](https://example.com/very/long/url/path/that/contains/many/segments/and/query/parameters)
```
**Result**: Displays 2 lines with ellipsis, URL text truncated

## Visual Examples

### Card Description Link
```
┌─────────────────────────────────┐
│ Welcome to the Museum           │
│                                 │
│ For more information, visit our │
│ website for opening hours and...│  ← Truncated at 2 lines
│                                 │
│ [Explore Content]               │
└─────────────────────────────────┘
```

### Content Item Link
```
┌─────────────────────────────────┐
│ Egyptian Mysteries              │
│                                 │
│ Learn more about ancient Egypt  │
│ at https://wikipedia.org/wiki...│  ← URL truncated
│                                 │
│ • Related Content               │
└─────────────────────────────────┘
```

## Components Affected

### Mobile Client (Public View)
- ✅ `CardOverview.vue` - Card descriptions with links
- ✅ `ContentDetail.vue` - Content item details with links

### Dashboard (Preview/View Components)
- ✅ `CardView.vue` - Card preview with description (card issuer)
- ✅ `CardContentView.vue` - Content item preview (card issuer)
- ✅ `AdminCardContent.vue` - Content moderation view (admin)

### Markdown Editor (Create/Edit Forms)
- ✅ `CardCreateEditForm.vue` - Card description editor preview
- ✅ `CardContentCreateEditForm.vue` - Content item description editor preview

**Total**: 7 components updated with consistent 2-line link styling

## User Interaction

**Important**: Links remain fully functional despite visual truncation:
- ✅ **Click/Tap**: Opens full URL in new tab
- ✅ **Hover** (desktop): Browser shows full URL in status bar
- ✅ **Long press** (mobile): Shows full URL in context menu

## Related Features

This styling enhancement works together with:
- **Target="_blank"**: Links open in new tabs
- **rel="noopener noreferrer"**: Security attributes
- **Markdown rendering**: Via `renderMarkdown()` utility

## Documentation Updated

- ✅ `MOBILE_MARKDOWN_LINKS_NEW_TAB.md` - Added styling section
- ✅ `TEST_MARKDOWN_LINKS.md` - Added truncation test case
- ✅ `MARKDOWN_LINKS_2LINE_STYLING.md` - This document

## Additional Improvements

### Code Consolidation
As part of this enhancement, all dashboard components were refactored to use the centralized `renderMarkdown()` utility from `@/utils/markdownRenderer.ts` instead of maintaining duplicate markdown rendering logic in each component.

**Benefits:**
- ✅ Single source of truth for markdown configuration
- ✅ Consistent link behavior across all components
- ✅ Easier maintenance and future updates
- ✅ All links automatically open in new tabs with security attributes

### Removed Duplicate Code
Eliminated 3 duplicate `renderMarkdown` functions from:
- `CardView.vue` (was using `marked.setOptions()`)
- `CardContentView.vue` (was using `marked()` directly)
- `AdminCardContent.vue` (was using `marked.parse()`)

### Enhanced Markdown Editor
Added HTML post-processing to markdown editor previews:
- `onHtmlChanged` callback intercepts rendered HTML
- Automatically adds `target="_blank"` and security attributes
- Applies 2-line truncation via CSS to preview pane
- Consistent behavior between preview and final rendered output

## Status

✅ **Complete** - All markdown links across the entire application (mobile + dashboard + editors) now display with 2-line maximum and ellipsis for overflow.

## Future Enhancements (Optional)

Consider these potential improvements:
- [ ] Add tooltip showing full link text on hover/long-press
- [ ] Make line count configurable via CSS variable
- [ ] Add subtle fade effect before ellipsis
- [ ] Add copy-to-clipboard button for long URLs

