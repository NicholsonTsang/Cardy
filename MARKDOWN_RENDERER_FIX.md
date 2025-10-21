# Markdown Renderer Fix - TypeError Resolution

## Issue

When implementing the markdown link enhancement, the initial implementation caused a runtime error:

```
TypeError: Cannot read properties of undefined (reading 'parseInline')
    at renderer.link (markdownRenderer.ts:11:16)
```

## Root Cause

The initial implementation attempted to override the `marked.Renderer.link` method by storing a reference to the original method and calling it:

```typescript
// ❌ BROKEN: Context is lost
const renderer = new marked.Renderer()
const originalLinkRenderer = renderer.link.bind(renderer)
renderer.link = (href, title, text) => {
  const html = originalLinkRenderer(href, title, text)
  return html.replace('<a', '<a target="_blank" rel="noopener noreferrer"')
}
```

The problem: The `link` method internally calls `this.parser.parseInline`, but when we create a new function and assign it to `renderer.link`, the context (`this`) is not properly maintained, causing `this.parser` to be undefined.

## Solution

Use marked's `hooks.postprocess` API instead, which is the modern and recommended way to post-process rendered HTML:

```typescript
// ✅ CORRECT: Use hooks API
marked.use({
  hooks: {
    postprocess(html) {
      // Add target="_blank" and rel="noopener noreferrer" to all links
      return html.replace(/<a href=/g, '<a target="_blank" rel="noopener noreferrer" href=')
    }
  }
})
```

## Why This Works

1. **No context issues**: The `postprocess` hook receives the fully rendered HTML string
2. **Simple regex replacement**: Uses string replacement to add attributes to all anchor tags
3. **Modern API**: Uses the current marked.js recommended approach for customization
4. **Reliable**: No dependency on internal marked.js implementation details

## File Changed

**`src/utils/markdownRenderer.ts`** - Complete rewrite using hooks API

## Testing

After the fix:
- ✅ No TypeScript errors
- ✅ No runtime errors
- ✅ Links render correctly with `target="_blank"`
- ✅ Links include `rel="noopener noreferrer"` for security

## Verification Steps

1. **Type check**: `npm run type-check` - Passes ✅
2. **Runtime test**: Navigate to card with markdown links
3. **Inspect HTML**: Verify links have correct attributes
4. **Click test**: Verify links open in new tabs

## Related Files

- `src/utils/markdownRenderer.ts` - Fixed implementation
- `src/views/MobileClient/components/ContentDetail.vue` - Uses renderMarkdown()
- `src/views/MobileClient/components/CardOverview.vue` - Uses renderMarkdown()
- `MOBILE_MARKDOWN_LINKS_NEW_TAB.md` - Updated documentation

## Lessons Learned

1. **Use official APIs**: When customizing third-party libraries, prefer official hooks/APIs over method override
2. **Context matters**: Overriding class methods requires careful attention to `this` binding
3. **Post-processing is simpler**: For attribute additions, post-processing HTML is more reliable than renderer override
4. **Test runtime behavior**: TypeScript may pass but runtime context issues can still occur

## marked.js API Reference

For future reference, the correct ways to customize marked:

**✅ Recommended: Hooks API**
```typescript
marked.use({
  hooks: {
    preprocess(markdown) { /* modify markdown before parsing */ },
    postprocess(html) { /* modify HTML after rendering */ }
  }
})
```

**✅ Alternative: Extensions API**
```typescript
marked.use({
  extensions: [
    {
      name: 'link',
      level: 'inline',
      renderer(token) { /* custom rendering */ }
    }
  ]
})
```

**❌ Not Recommended: Direct renderer override** (context issues)

## Status

✅ **Fixed** - Markdown links now open in new tabs without runtime errors.

