# Testing Guide: Markdown Links Open in New Tab

## Quick Test Instructions

### Prerequisites
1. Start the development server: `npm run dev` or `npm run dev:local`
2. Have a card with markdown links in either:
   - Card description (shown in CardOverview)
   - Content item content (shown in ContentDetail)

### Test Case 1: Card Description Links

1. **Navigate to a card** via QR code or preview mode
2. **Create test content** with a link in the card description:
   ```markdown
   Visit our [website](https://example.com) for more information.
   
   Check out [Google](https://google.com) or [Wikipedia](https://wikipedia.org)
   ```
3. **Expected behavior**:
   - Click any link
   - Link should open in a **new browser tab**
   - Original card view should remain open and unchanged

### Test Case 2: Content Item Links

1. **Navigate to a content item detail** by tapping on a content item
2. **Create test content** with links in the content item:
   ```markdown
   # Learn More
   
   - Visit the [museum website](https://museum.com)
   - Read about [the artist](https://example.com/artist)
   - Book tickets [here](https://tickets.example.com)
   ```
3. **Expected behavior**:
   - Click any link
   - Link should open in a **new browser tab**
   - Content detail view should remain open

### Test Case 3: Verify HTML Attributes

1. **Open browser DevTools** (F12 or Cmd+Opt+I)
2. **Inspect a rendered link** in the card description or content
3. **Expected HTML**:
   ```html
   <a href="https://example.com" target="_blank" rel="noopener noreferrer">text</a>
   ```
4. **Verify attributes**:
   - ✅ `target="_blank"` is present
   - ✅ `rel="noopener noreferrer"` is present
5. **Verify styling** (check Computed styles in DevTools):
   - ✅ `display: -webkit-box`
   - ✅ `-webkit-line-clamp: 2`
   - ✅ `text-overflow: ellipsis`
   - Links should display maximum 2 lines with ellipsis (...) for overflow

### Test Case 4: Long Link Text Truncation

1. **Create test content** with very long link text:
   ```markdown
   [This is a very long link text that should be truncated to two lines with an ellipsis at the end when it overflows the container width](https://example.com)
   
   [https://example.com/very/long/url/path/that/should/be/truncated/to/two/lines/maximum](https://example.com/very/long/url/path)
   ```
2. **Expected behavior**:
   - Link text displays a maximum of **2 lines**
   - Overflow text is hidden with **ellipsis (...)**
   - Link remains clickable
   - Opens in new tab when clicked
3. **Visual verification**:
   - No broken layout from long URLs
   - Clean, professional appearance
   - Mobile-friendly display

### Test Case 5: Mobile Browser Testing

**iOS Safari:**
1. Open card on iPhone/iPad
2. Tap a link in markdown content
3. Should open in new Safari tab
4. Swipe to return to original card view

**Chrome Mobile:**
1. Open card on Android device
2. Tap a link in markdown content
3. Should open in new Chrome tab
4. Use tab switcher to return to card view

**Expected behavior on all mobile browsers:**
- Link opens in new tab
- Original card remains accessible
- No navigation away from card view

## Browser Compatibility Test

Test on the following browsers to ensure consistent behavior:

- [ ] Chrome (Desktop)
- [ ] Safari (Desktop)
- [ ] Firefox (Desktop)
- [ ] Edge (Desktop)
- [ ] Safari (iOS)
- [ ] Chrome (Android)
- [ ] Samsung Internet (Android)

## Troubleshooting

### Links don't open in new tab
- Check browser console for errors
- Verify `renderMarkdown` is imported correctly
- Check that markdown content has valid link syntax

### Links have wrong attributes
- Inspect HTML in DevTools
- Verify `marked` library is using custom renderer
- Check that `markdownRenderer.ts` is correctly configured

## Manual Test Data

### Sample Markdown with Links

```markdown
# Welcome to the Exhibition

Visit [our website](https://example.com) for opening hours.

## Learn More

- [Artist biography](https://example.com/artist)
- [Exhibition catalog](https://example.com/catalog)
- [Book tickets](https://tickets.example.com)

For more information, see [Wikipedia](https://wikipedia.org) or contact us at our [contact page](https://example.com/contact).
```

## Automated Testing (Future Enhancement)

Consider adding unit tests for the markdown renderer:

```typescript
import { renderMarkdown } from '@/utils/markdownRenderer'

describe('markdownRenderer', () => {
  it('should add target="_blank" to links', () => {
    const markdown = '[Link](https://example.com)'
    const html = renderMarkdown(markdown)
    expect(html).toContain('target="_blank"')
  })

  it('should add rel="noopener noreferrer" to links', () => {
    const markdown = '[Link](https://example.com)'
    const html = renderMarkdown(markdown)
    expect(html).toContain('rel="noopener noreferrer"')
  })
})
```

## Success Criteria

✅ All links in card descriptions open in new tabs  
✅ All links in content items open in new tabs  
✅ Links have `target="_blank"` attribute  
✅ Links have `rel="noopener noreferrer"` attribute  
✅ Links display maximum 2 lines with ellipsis for overflow  
✅ Long URLs don't break layout  
✅ Works on all tested browsers  
✅ Works on mobile devices  
✅ Original card view remains accessible  

## Notes

- The change is backward compatible
- No database changes required
- No API changes required
- Works with existing card content
- Security enhanced with `rel="noopener noreferrer"`

