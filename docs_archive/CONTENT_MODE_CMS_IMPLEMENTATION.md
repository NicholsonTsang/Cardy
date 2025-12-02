# Content Mode CMS & Mobile Client Implementation

## Overview

This document describes the implementation of contextual CMS forms and mobile client rendering for the 5 content modes.

## 5 Content Modes

| Mode | Icon | CMS Form | Mobile Rendering |
|------|------|----------|------------------|
| **Single** | `pi-file` | Full-page content with title, description, optional image | `LayoutSingle.vue` - Full-page display |
| **Grouped** | `pi-folder` | Category headers (parent) + items (children) | `LayoutGrouped.vue` - Category sections with sub-items |
| **List** | `pi-list` | Simple title + link/description | `LayoutList.vue` - Vertical list |
| **Grid** | `pi-th-large` | Visual item with required image + title + description | `LayoutGrid.vue` - 2-column grid |
| **Inline** | `pi-clone` | Full-width card with recommended 16:9 image | `LayoutInline.vue` - Stacked full-width cards |

---

## CMS Implementation

### CardContentCreateEditForm.vue

The form adapts based on `contentMode` prop:

#### Single Mode
- Purple color theme
- Optional 16:9 cover image
- Title (required)
- Full content with markdown editor (350px height)
- AI knowledge base (if enabled)

#### Grouped Mode
**Category (no parent):**
- Orange color theme
- Category name only (no description)
- AI context for category

**Sub-item (has parent):**
- Amber color theme
- Optional item image
- Item name + description
- AI knowledge for item

#### List Mode
- Blue color theme
- Simple form: Title + Link/Description
- Smart icon for URL detection
- AI context

#### Grid Mode
- Green color theme
- Required 1:1 square image
- Title + description
- AI knowledge

#### Inline Mode
- Cyan color theme
- Recommended 16:9 image
- Title + description
- AI knowledge

### CardContent.vue

Content list panel adapts based on mode:

| Mode | List Item Display |
|------|-------------------|
| Single | Page icon + title + preview |
| Grouped | Folder icon + category name + item count (expandable) |
| List | Smart icon (link detection) + title + URL |
| Grid | Square thumbnail + title + preview |
| Inline | 16:9 thumbnail + title + preview |

---

## Mobile Client Implementation

### SmartContentRenderer.vue

Detects `content_mode` from card data and renders appropriate layout:

```typescript
const detectedLayout = computed(() => {
  // Priority 1: Use explicit content_mode from CMS
  if (props.card?.content_mode) {
    return props.card.content_mode
  }
  
  // Priority 2: Heuristic detection (fallback)
  // ...
})
```

### Layout Components

| Component | Description |
|-----------|-------------|
| `LayoutSingle.vue` | Full-page content with optional image, title, markdown content |
| `LayoutGrouped.vue` | Category sections with uppercase headers, child items listed below |
| `LayoutList.vue` | Simple vertical list with smart icons |
| `LayoutGrid.vue` | 2-column visual grid with square thumbnails |
| `LayoutInline.vue` | Full-width stacked cards with 16:9 images |

---

## i18n Keys Added

### English (`en.json`)

**Form labels:**
- `form.single_*` - Single mode form labels
- `form.category_*` - Category (grouped parent) form labels
- `form.grouped_item_*` - Grouped sub-item form labels
- `form.list_item_*` - List mode form labels
- `form.grid_*` - Grid mode form labels
- `form.inline_*` - Inline mode form labels

**Content panel:**
- `content.single_*` - Single mode empty states
- `content.grouped_*` - Grouped mode empty states
- `content.list_*` - List mode empty states
- `content.grid_*` - Grid mode empty states
- `content.inline_*` - Inline mode empty states

### Traditional Chinese (`zh-Hant.json`)

All corresponding translations added.

---

## Color Themes

| Mode | Primary | Secondary | Border |
|------|---------|-----------|--------|
| Single | Purple-600 | Purple-100 | Purple-200 |
| Grouped | Orange-600 | Orange-100 | Orange-200 |
| List | Blue-600 | Blue-100 | Blue-200 |
| Grid | Green-600 | Green-100 | Green-200 |
| Inline | Cyan-600 | Cyan-100 | Cyan-200 |

---

## Files Modified

### CMS Components
- `src/components/CardContent/CardContentCreateEditForm.vue` - Complete rewrite for mode-specific forms
- `src/components/CardContent/CardContent.vue` - Updated list rendering and header/empty state configs

### Mobile Client
- `src/views/MobileClient/components/SmartContentRenderer.vue` - Mode detection and routing
- `src/views/MobileClient/components/LayoutSingle.vue` - Single page layout
- `src/views/MobileClient/components/LayoutGrouped.vue` - Grouped list layout
- `src/views/MobileClient/components/LayoutList.vue` - Simple list layout
- `src/views/MobileClient/components/LayoutGrid.vue` - Grid gallery layout
- `src/views/MobileClient/components/LayoutInline.vue` - Full-width cards layout

### i18n
- `src/i18n/locales/en.json` - English translations
- `src/i18n/locales/zh-Hant.json` - Traditional Chinese translations

---

## Testing Checklist

### CMS Testing
- [ ] Create card with each content mode
- [ ] Verify form fields match mode requirements
- [ ] Test mode switching during card edit
- [ ] Verify content item forms adapt to mode
- [ ] Test sub-item creation for Grouped mode

### Mobile Client Testing
- [ ] Single mode: Full-page content display
- [ ] Grouped mode: Category headers with expandable items
- [ ] List mode: Simple list with link icons
- [ ] Grid mode: 2-column image grid
- [ ] Inline mode: Full-width stacked cards
- [ ] Verify navigation to detail view
- [ ] Test AI assistant integration
- [ ] Test language selector

---

## Date

December 1, 2025

