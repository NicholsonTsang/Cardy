# CardStudio: Access Modes & Content Modes

## Overview

CardStudio supports two distinct access modes and five content rendering modes, allowing flexible configuration for different use cases.

> **Important:** Access Mode is **immutable** after card creation. Once a card is created as Physical Card or Digital Access, it cannot be changed. This ensures billing and content structure consistency.

---

## 1. Access Modes

### 1.1 Physical Card (`billing_type: 'physical'`)

**Description:** Traditional printed souvenir cards with embedded QR codes.

| Aspect | Details |
|--------|---------|
| **Billing Model** | Per-card (one-time charge at print) |
| **Scan Limit** | Unlimited (`max_scans: NULL`) |
| **Mobile UX Flow** | QR Scan → Card Overview → Explore Content → Content Detail |
| **Card Image** | **Required** (displayed on overview page) |
| **Card Description** | **Recommended** (displayed on overview page) |
| **Use Cases** | Museums, tourist attractions, exhibitions, events, hotels |

**Mobile Client Behavior:**
1. User scans QR code on physical card
2. **Card Overview page** displays card image, name, description
3. User taps "Explore" to see content
4. Content renders based on `content_mode`

### 1.2 Digital Access (`billing_type: 'digital'`)

**Description:** QR-code-only access without physical card printing.

| Aspect | Details |
|--------|---------|
| **Billing Model** | Per-scan (charged each access) |
| **Scan Limit** | Configurable (`max_scans: INTEGER` or `NULL` for unlimited) |
| **Mobile UX Flow** | QR Scan → **Welcome Page** (3D visual, no image) → Explore Content → Content Detail |
| **Card Image** | **Not displayed** (welcome page shows 3D QR icon animation instead) |
| **Card Description** | **Available** (displayed on welcome page - input available in CMS for all digital modes) |
| **Use Cases** | Link-in-bio, digital menus, quick access portals, temporary campaigns |

**Mobile Client Behavior:**
1. User scans QR code
2. **Welcome page** displays:
   - 3D animated background with floating cubes, prisms, spheres, and light beams
   - 3D rotating QR icon cube with glowing rings
   - Card title with 3D shadow effects
   - Card description in glassmorphism container (if provided)
   - "Explore" button to proceed
3. User taps "Explore" to see content
4. Content renders based on `content_mode`
5. If `scan_limit_reached`, shows "Access Limit Reached" message

**Scan Tracking:**
- Each non-owner access increments `current_scans`
- When `current_scans >= max_scans`, card becomes inaccessible
- Owner access does NOT count toward limit

---

## 2. Content Modes (5 Modes)

### 2.1 Single Mode (`content_mode: 'single'`)

**Layout:** One full-page content item

| Requirement | Value |
|-------------|-------|
| Content Items | **1 parent item** |
| Sub-items | None |
| Images | Optional (displayed if present) |

**Mobile Rendering:** `LayoutSingle.vue`
- Full-page display of single content item
- Large image (if present)
- Title prominently displayed
- Full content with markdown support
- AI Assistant (if enabled)

**Use Cases:**
- Single article or announcement
- Product detail page
- Event information
- About page

---

### 2.2 Grouped Mode (`content_mode: 'grouped'`)

**Layout:** Categories (parent items) with sub-items listed below

| Requirement | Value |
|-------------|-------|
| Parent Items | **N items** (category headers, no description shown) |
| Child Items | **N items per category** |
| Images | Optional on child items |

**Mobile Rendering:** `LayoutGrouped.vue`
- Category title as section header (uppercase, subtle styling)
- Child items listed below each category
- Each child shows: thumbnail (if image), name, preview text
- Tapping child navigates to detail view

**Use Cases:**
- Restaurant menus with categories (Appetizers, Mains, Desserts)
- Product catalogs with categories
- Service directories
- Organized resource lists

---

### 2.3 List Mode (`content_mode: 'list'`) - **DEFAULT**

**Layout:** Simple vertical list of items

| Requirement | Value |
|-------------|-------|
| Content Items | **N parent items** |
| Sub-items | None (flat structure) |
| Images | Optional (shows icon if no image) |

**Mobile Rendering:** `LayoutList.vue`
- Card header with title and description
- Vertical list of clickable items
- Each item shows: thumbnail/icon, name, preview text
- Smart icon detection for URLs (Instagram, YouTube, etc.)
- Direct URL opening for link items

**Use Cases:**
- Link-in-bio pages
- Resource lists
- Simple menus
- Contact lists
- Quick links

---

### 2.4 Grid Mode (`content_mode: 'grid'`)

**Layout:** 2-column visual grid

| Requirement | Value |
|-------------|-------|
| Content Items | **N items** |
| Sub-items | Optional |
| Images | **Recommended** (placeholder shown if missing) |

**Mobile Rendering:** `LayoutGrid.vue`
- Card header with title
- 2-column grid layout
- Square image thumbnails
- Item name below each image
- Tapping opens detail view

**Use Cases:**
- Photo galleries
- Product catalogs
- Portfolio showcases
- Team member grids
- Menu with photos

---

### 2.5 Inline Mode (`content_mode: 'inline'`)

**Layout:** Full-width cards, one per row

| Requirement | Value |
|-------------|-------|
| Content Items | **N items** |
| Sub-items | Optional |
| Images | **Recommended** (16:9 aspect ratio) |

**Mobile Rendering:** `LayoutInline.vue`
- Card header with title and description
- Full-width vertical card layout
- Each card: 16:9 image, title, preview text, "View Details" action
- One content item per row

**Use Cases:**
- Featured items / highlights
- Articles / blog posts
- Announcements
- Product showcase
- News feed

---

## 3. Content Mode Summary Table

| Mode | Structure | Layout | Best For |
|------|-----------|--------|----------|
| **Single** | 1 parent, 0 children | Full page | Articles, announcements |
| **Grouped** | N parents (categories), N children | Category headers + list | Menus, catalogs |
| **List** | N parents only | Vertical list | Links, resources |
| **Grid** | N items | 2-column grid | Galleries, portfolios |
| **Inline** | N items | Full-width cards | Featured, articles |

---

## 4. Database Schema

```sql
-- cards table columns for access and content modes
content_mode TEXT DEFAULT 'list' CHECK (content_mode IN ('single', 'grouped', 'list', 'grid', 'inline')),
billing_type TEXT DEFAULT 'physical' CHECK (billing_type IN ('physical', 'digital')),
max_scans INTEGER DEFAULT NULL,  -- NULL = unlimited
current_scans INTEGER DEFAULT 0
```

---

## 5. CMS Form Behavior

### Access Mode Selection (First Step)
- **Physical Card:** Shows card artwork upload, QR position, description field
- **Digital Access:** Hides artwork section, hides description (not displayed)

### Content Mode Selection
All 5 modes available for both access types:
- Single Page
- Grouped List
- Simple List (default)
- Grid Gallery
- Inline Cards

Each mode shows:
- Icon and label
- Short description
- Guidance text
- Requirements checklist

---

## 6. Mobile Client Routing

```
Physical Card:
  QR Scan → CardOverview (with card image) → SmartContentRenderer → ContentDetail

Digital Access:
  QR Scan → CardOverview (welcome page, no image) → SmartContentRenderer → ContentDetail
```

Both access modes now follow the same flow pattern. The `CardOverview` component adapts its layout:
- **Physical Card**: Shows hero section with card image
- **Digital Access**: Shows welcome section with QR icon (no image)

The `SmartContentRenderer` component detects `content_mode` and renders the appropriate layout component.
