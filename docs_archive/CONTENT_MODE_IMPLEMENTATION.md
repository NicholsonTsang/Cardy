# Content Mode Implementation

This document describes how content modes are implemented across the CMS and Mobile Client.

## Overview

CardStudio supports 4 content rendering modes:

| Mode | CMS Value | Mobile Layout | Use Case |
|------|-----------|---------------|----------|
| **Profile** | `solo` | `LayoutProfile.vue` | Digital business cards, personal profiles |
| **Links** | `stack` | `LayoutStack.vue` | Link-in-bio, resource collections |
| **Gallery** | `catalog` | `ContentListGrid.vue` | Visual portfolios, menus, product catalogs |
| **Tour** | `guide` | `LayoutGuide.vue` | Museum tours, manuals, structured guides |

## Data Flow

```
CMS (CardCreateEditForm.vue)
    ↓ content_mode
Database (cards.content_mode)
    ↓ get_public_card_content() / get_card_preview_content()
Mobile Client (PublicCardView.vue)
    ↓ cardData.content_mode
SmartContentRenderer.vue
    ↓ detectedLayout computed
Layout Component (LayoutProfile/LayoutStack/LayoutGuide/ContentListGrid)
```

## CMS Mode-Specific UX

The CMS provides tailored experiences for each mode:

### Mode Selection (CardCreateEditForm.vue)
- Visual mode selector with icons and descriptions
- Requirements checklist showing what's needed
- Dynamic placeholders and guidance

### Content Management (CardContent.vue)
- **Header**: Mode-specific title, icon, and color scheme
- **Empty State**: Tailored messaging and call-to-action per mode
- **Add Button**: Mode-appropriate label ("Add Link", "Add Chapter", "Add Item")
- **Sub-items**: Only shown for Guide mode (as "Add Step")

### Content Form (CardContentCreateEditForm.vue)
- **Stack Mode**: Simplified form - no image section, URL input instead of Markdown
- **Catalog Mode**: Full form with required image upload
- **Guide Mode**: Contextual labels ("Chapter" vs "Step"), optional images
- **Solo Mode**: Form hidden (uses card description only)

## CMS Requirements per Mode

### Solo/Profile Mode
- **Required:** Card description (bio/intro)
- **Not needed:** Content items (CMS shows info message)
- **CMS UI:** Purple theme, "No items needed" message
- **Renders:** Circular profile image, bio text, Share/Save Contact buttons

### Stack/Links Mode
- **Required:** Content items WITHOUT images
- **Not needed:** Sub-items
- **CMS UI:** Blue theme, simplified URL input form, no image section
- **Renders:** Vertical list of clickable buttons with smart icons

### Catalog/Gallery Mode
- **Required:** Content items WITH images
- **Not needed:** Sub-items
- **CMS UI:** Green theme, full form with required image upload
- **Renders:** Visual grid with image cards

### Guide/Tour Mode
- **Required:** Parent content items (chapters) AND sub-items (steps)
- **CMS UI:** Orange theme, "Add Chapter" / "Add Step" buttons
- **Renders:** Chapter list with numbered badges, clicking opens sub-items

## Detection Logic

The `SmartContentRenderer.vue` uses a two-tier detection system:

### Priority 1: Explicit Mode
If `card.content_mode` is set in the database, use it directly:
```javascript
const modeMap = {
  'solo': 'profile',
  'stack': 'stack', 
  'catalog': 'grid',
  'guide': 'guide'
}
```

### Priority 2: Heuristic Detection
If no explicit mode, detect based on content structure:
1. **0 items** → Profile
2. **Items without images** → Stack
3. **Items with sub-items** → Guide
4. **Items with images (no sub-items)** → Grid

## Database Schema

```sql
ALTER TABLE cards ADD COLUMN content_mode TEXT 
  DEFAULT 'catalog' 
  CHECK (content_mode IN ('solo', 'stack', 'catalog', 'guide'));
```

## Stored Procedures Updated

Both public access functions now return `card_content_mode`:
- `get_public_card_content()` - For issued cards
- `get_card_preview_content()` - For CMS preview

## Files Modified

### CMS
- `src/components/CardComponents/CardCreateEditForm.vue` - Mode selector with requirements checklist
- `src/stores/card.ts` - Added content_mode to Card interface and API calls

### Mobile Client
- `src/views/MobileClient/PublicCardView.vue` - Extracts content_mode from API
- `src/views/MobileClient/components/SmartContentRenderer.vue` - Routes to correct layout
- `src/views/MobileClient/components/LayoutProfile.vue` - Solo mode
- `src/views/MobileClient/components/LayoutStack.vue` - Links mode
- `src/views/MobileClient/components/LayoutGuide.vue` - Tour mode (NEW)
- `src/views/MobileClient/components/ContentListGrid.vue` - Gallery mode

### Database
- `sql/schema.sql` - Added content_mode column
- `sql/storeproc/client-side/02_card_management.sql` - CRUD operations
- `sql/storeproc/client-side/07_public_access.sql` - Public access functions

## Deployment Steps

1. Run database migration:
```sql
\i sql/migrations/add_billing_type_columns.sql
```

2. Update stored procedures:
```bash
psql "$DATABASE_URL" -f sql/all_stored_procedures.sql
```

3. Deploy frontend changes

## Testing Checklist

- [ ] Create card with Solo mode → Renders LayoutProfile
- [ ] Create card with Stack mode + items (no images) → Renders LayoutStack
- [ ] Create card with Catalog mode + items (with images) → Renders ContentListGrid
- [ ] Create card with Guide mode + parent items + sub-items → Renders LayoutGuide
- [ ] Change mode in CMS → Mobile client updates rendering
- [ ] Heuristic detection works when content_mode is NULL

