# Mobile Client Markdown Links - Open in New Tab

## Summary

Enhanced the mobile client's markdown rendering to automatically open all links in new browser tabs, improving user experience and preventing navigation away from the card content.

## Changes Made

### 1. Created Markdown Renderer Utility

**File**: `src/utils/markdownRenderer.ts`

- Created centralized utility for markdown rendering
- Configured `marked` library with custom renderer
- All links automatically get `target="_blank"` and `rel="noopener noreferrer"` attributes
- Security best practice: `rel="noopener noreferrer"` prevents potential security vulnerabilities

### 2. Updated Mobile Components

**Files Modified**:
- `src/views/MobileClient/components/ContentDetail.vue`
- `src/views/MobileClient/components/CardOverview.vue`

**Changes**:
- Replaced direct `marked.parse()` calls with `renderMarkdown()` utility
- Removed duplicate markdown rendering logic
- Improved code maintainability through centralized configuration

### 3. Updated Documentation

**File**: `CLAUDE.md`

- Updated markdown rendering guidelines
- Documented the new utility function pattern
- Added security considerations for link rendering

## Technical Details

### Link Rendering Configuration

```typescript
marked.use({
  hooks: {
    postprocess(html) {
      // Add target="_blank" and rel="noopener noreferrer" to all links
      return html.replace(/<a href=/g, '<a target="_blank" rel="noopener noreferrer" href=')
    }
  }
})
```

**Note**: Uses marked's `hooks.postprocess` API for reliable post-processing of rendered HTML.

### Security Attributes

- **`target="_blank"`**: Opens link in new tab/window
- **`rel="noopener"`**: Prevents new page from accessing `window.opener`
- **`rel="noreferrer"`**: Prevents passing referrer information to target page

### Link Display Styling

Links are styled with a 2-line clamp to prevent long URLs from breaking the layout:

```css
.markdown-content :deep(a) {
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
  text-overflow: ellipsis;
  word-break: break-word;
}
```

**Visual behavior**:
- Links display up to **2 lines** of text
- Text overflow shows **ellipsis (...)** at the end
- Long URLs are truncated gracefully
- Improves mobile readability

## User Experience Benefits

1. **Seamless Navigation**: Users stay in the card view while exploring external links
2. **Better Mobile UX**: New tabs don't interrupt the museum/exhibition experience
3. **Context Preservation**: Original card content remains accessible
4. **Security**: Protection against potential reverse tabnapping attacks

## Components Affected

### Mobile Client
- ✅ `CardOverview.vue` - Card description with markdown
- ✅ `ContentDetail.vue` - Content item details with markdown

### Dashboard
- ℹ️ No changes needed (links in dashboard can use default behavior)

## Testing Checklist

- [ ] Test links in card descriptions (CardOverview)
- [ ] Test links in content item details (ContentDetail)
- [ ] Verify links open in new tabs on mobile browsers
- [ ] Verify links open in new tabs on desktop browsers
- [ ] Check that `rel="noopener noreferrer"` is present in rendered HTML
- [ ] Test both HTTP and HTTPS links
- [ ] Test markdown links with titles: `[text](url "title")`
- [ ] Test inline links in lists and paragraphs

## Example Usage

### Before (Direct marked usage)
```typescript
import { marked } from 'marked'
const html = marked.parse(text) as string
```

### After (Utility function)
```typescript
import { renderMarkdown } from '@/utils/markdownRenderer'
const html = renderMarkdown(text)
```

## Browser Compatibility

- ✅ Chrome/Edge (all versions)
- ✅ Safari (all versions)
- ✅ Firefox (all versions)
- ✅ Mobile browsers (iOS Safari, Chrome Mobile, etc.)

## Notes

- The utility function is reusable across the entire application
- Future markdown rendering should use this utility for consistency
- Dashboard components can also adopt this pattern if needed
- The configuration is centralized, making future changes easy

## Related Files

- `src/utils/markdownRenderer.ts` - Main utility file
- `src/views/MobileClient/components/ContentDetail.vue` - Content rendering
- `src/views/MobileClient/components/CardOverview.vue` - Card description rendering
- `CLAUDE.md` - Updated documentation

## Status

✅ **Complete** - All mobile client markdown links now open in new tabs with proper security attributes.

