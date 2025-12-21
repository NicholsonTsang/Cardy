# Content Description UX Optimization - December 7, 2025

## Problem Statement

Content item descriptions were rendered inconsistently across different content modes:
- Some modes had fixed-height containers with forced scrolling (ContentDetail: 45vh)
- Some modes showed no description at all (Grid)
- Truncation lengths varied without clear rationale

This created poor UX:
1. **ContentDetail**: Users couldn't read full content without scrolling inside a fixed container
2. **Grid**: Users had no context about what they'd see after clicking
3. **Inconsistent**: Different modes behaved differently for similar content

## UI/UX Best Practices Applied

### 1. Progressive Disclosure Pattern
- **Preview modes** (List, Grouped, Grid, Inline): Show truncated previews to entice clicks
- **Detail modes** (Single, ContentDetail): Show full content for reading

### 2. Smart Expand/Collapse
Instead of forcing scroll for all content, use "Show More/Less" pattern:
- Short content: Displays fully without any constraints
- Long content: Shows 200px preview with "Show More" button
- User controls when to expand, better for reading flow

### 3. Consistent Truncation Strategy
Truncation lengths proportional to available space:
| Mode | Truncation | Lines | Rationale |
|------|------------|-------|-----------|
| Grid | 40 chars | 1 | Compact cards, minimal space |
| Grouped | 60 chars | 1 | Medium list items |
| List | 60 chars | 1 | Medium list items |
| Inline | 100 chars | 2 | Larger cards with more space |

## Changes Made

### 1. ContentDetail.vue - Smart Expand/Collapse

**Before**:
```css
.content-description {
  max-height: 45vh;
  overflow-y: auto;
}
```

**After**:
```vue
<div 
  ref="descriptionRef"
  class="content-description"
  :class="{ 
    'is-collapsed': isLongContent && !isExpanded,
    'is-expanded': isLongContent && isExpanded
  }"
  v-html="renderMarkdown(content.content_item_content)"
></div>

<button v-if="isLongContent" @click="toggleExpand" class="expand-toggle">
  <span>{{ isExpanded ? $t('mobile.show_less') : $t('mobile.show_more') }}</span>
  <i :class="isExpanded ? 'pi pi-chevron-up' : 'pi pi-chevron-down'" />
</button>
```

**Logic**:
- Measures content height on mount and content change
- If content > 300px (COLLAPSE_THRESHOLD), shows "Show More" button
- Collapsed state: 200px max-height with fade gradient
- Expanded state: Full content visible

### 2. LayoutGrid.vue - Added Preview Text

**Before**: Only image and name displayed
**After**: Optional 1-line preview (40 chars) below name

```vue
<span v-if="item.content_item_content" class="item-preview">
  {{ truncateText(item.content_item_content, 40) }}
</span>
```

### 3. i18n Keys Added

**English** (`en.json`):
```json
"show_more": "Show more",
"show_less": "Show less"
```

**Traditional Chinese** (`zh-Hant.json`):
```json
"show_more": "顯示更多",
"show_less": "顯示較少"
```

**Simplified Chinese** (`zh-Hans.json`):
```json
"show_more": "显示更多",
"show_less": "显示较少"
```

## Files Modified

1. `src/views/MobileClient/components/ContentDetail.vue`
   - Replaced fixed scroll with smart expand/collapse
   - Added descriptionRef, isExpanded, isLongContent refs
   - Added checkContentLength() and toggleExpand() functions
   - Added watcher for content changes
   - Updated CSS with .is-collapsed, .is-expanded, .expand-toggle

2. `src/views/MobileClient/components/LayoutGrid.vue`
   - Added item-preview span with truncated description
   - Added truncateText() function
   - Added .item-preview CSS styles

3. `src/i18n/locales/en.json` - Added show_more, show_less keys
4. `src/i18n/locales/zh-Hant.json` - Added show_more, show_less keys
5. `src/i18n/locales/zh-Hans.json` - Added show_more, show_less keys

## Final Content Mode Summary

| Mode | View Type | Description Display | Behavior |
|------|-----------|---------------------|----------|
| **Single** | Full page | Full content, no limits | Natural scroll |
| **Grouped** | Category list | 60 char preview | Click for detail |
| **List** | Vertical list | 60 char preview | Click for detail/URL |
| **Grid** | 2-column grid | 40 char preview | Click for detail |
| **Inline** | Full-width cards | 100 char (2 lines) | Click for detail |
| **Detail** | Item detail page | Smart expand/collapse | Show more/less button |

## Benefits

1. **Better Reading Experience**: Users control content expansion
2. **More Context**: Grid mode now shows preview text
3. **Consistent Pattern**: All modes follow progressive disclosure
4. **Mobile Optimized**: No forced scrolling inside fixed containers
5. **Accessibility**: Show more/less is screen reader friendly

## Testing Checklist

- [ ] Single mode: Content displays fully without constraints
- [ ] Grouped mode: Preview shows 60 chars, truncates with ellipsis
- [ ] List mode: Preview shows 60 chars, truncates with ellipsis
- [ ] Grid mode: Preview shows 40 chars (new feature)
- [ ] Inline mode: Preview shows 100 chars, 2-line clamp
- [ ] ContentDetail short content: No "Show more" button
- [ ] ContentDetail long content: "Show more" button appears
- [ ] ContentDetail expand/collapse: Smooth animation
- [ ] ContentDetail language switch: Reset expand state
- [ ] All languages: show_more/show_less translations display correctly

---

**Status**: ✅ Implemented  
**Impact**: Improved reading UX across all content modes  
**Breaking Changes**: None - visual improvements only







