# Unified Platform Planning: The "Rendering Mode" Strategy

This document synthesizes the Content Structure Matrix, Scenario Planning, and Technical Architecture into a unified plan. The core philosophy is **"One Data Structure, Multiple Renderers."** We will not create new database tables for "Modes." Instead, we will use the existing hierarchical data to intelligently adapt the frontend UI.

## 1. Validation of Current Architecture

The existing data structure is fully capable of supporting all 5 proposed modes without schema changes (except for the `billing_type` flag for the business model).

### Data Cross-Check
| Proposed Mode | Required Data | Existing DB Column | Status |
| :--- | :--- | :--- | :--- |
| **SOLO** (Profile) | Name, Bio, Image | `cards.name`, `cards.description`, `cards.image_url` | ✅ Ready |
| **STACK** (Links) | Link Name, URL | `content_items.name`, `content_items.content` (Markdown links) | ✅ Ready |
| **CATALOG** (Menu) | Item Name, Desc, Image | `content_items` (Parent) + `image_url` | ✅ Ready |
| **GUIDE** (Tour) | Chapters, Steps | `content_items` (Parent) + `content_items` (Child via `parent_id`) | ✅ Ready |
| **AGENT** (Chat) | AI Knowledge, Personality | `cards.ai_knowledge_base`, `cards.ai_instruction`, `conversation_ai_enabled` | ✅ Ready |

---

## 2. The Rendering Engine (Mobile Client)

The Mobile Client (`src/views/MobileClient/`) will act as a smart rendering engine. Instead of hardcoded "Modes," it will use **Heuristic Layout Detection** to serve the best UI.

### Logic Flow (Pseudo-Code)

This logic runs on `onMounted` in the Card View to select the layout component.

```javascript
// Heuristic Layout Detection
function detectLayout(card, contentItems) {
    const parentItems = contentItems.filter(i => !i.parent_id);
    const hasDescription = card.description && card.description.length > 0;
    
    // 1. AGENT OVERLAY CHECK
    // (This is independent of layout; it just enables the microphone button)
    const showAgent = card.conversation_ai_enabled;

    // 2. LAYOUT SELECTION
    if (parentItems.length === 0) {
        // SCENARIO: Digital Business Card / Personal Profile
        // CONTENT: Only Card Name + Description + Image
        return 'LayoutProfile'; 
    }
    
    if (parentItems.length > 0 && parentItems.every(i => !i.image_url)) {
        // SCENARIO: Link-in-Bio / Resource List
        // CONTENT: List of items without images
        return 'LayoutStack';
    }

    const hasSubItems = contentItems.some(i => i.parent_id);
    if (hasSubItems) {
        // SCENARIO: Museum Tour / Instruction Manual
        // CONTENT: Hierarchy (Chapters -> Steps)
        return 'LayoutGuide';
    }

    // DEFAULT SCENARIO: Menu / Gallery / Portfolio
    // CONTENT: Grid of images (The current default)
    return 'LayoutGrid'; 
}
```

---

## 3. Implementation Plan: The 4 Renderers

We will refactor `ContentList.vue` into a dynamic component loader that chooses one of these 4 sub-components.

### A. `LayoutProfile.vue` (New)
*   **For:** SOLO Mode.
*   **Design:**
    *   **Hero:** Extra-large Card Image (Circle or Portrait).
    *   **Body:** Center-aligned text (Name + Bio).
    *   **Action:** "Save Contact" (VCF) or "Share" button.
    *   **No Grid:** No content items are rendered.

### B. `LayoutStack.vue` (New)
*   **For:** STACK Mode.
*   **Design:**
    *   **Hero:** Small Card Header.
    *   **Body:** Vertical list of clickable buttons/pills.
    *   **Content:** Renders `content_item.name` as the button text. `content_item.content` is parsed for the first URL to make the whole button clickable.

### C. `LayoutGrid.vue` (Current `ContentList.vue`)
*   **For:** CATALOG Mode.
*   **Design:** Masonry/Grid of cards with images.
*   **Status:** **Already Implemented.** This is the current default view.

### D. `LayoutGuide.vue` (Enhanced `ContentDetail.vue`)
*   **For:** GUIDE Mode.
*   **Design:**
    *   **View:** "Collection" style.
    *   **Navigation:** Breadcrumbs (Home > Chapter > Step).
    *   **Status:** **Partially Implemented.** Current system handles 1 level of nesting. We just need to ensure the UI clearly visualizes the "Chapter" vs "Step" relationship.

---

## 4. Strategic Summary

| Scenario | User Action (CMS) | System Data | Rendered Result (Mobile) |
| :--- | :--- | :--- | :--- |
| **Networking** | User fills Name, Bio, Uploads Photo. Adds 0 items. | Desc: Yes<br>Items: 0 | **LayoutProfile**<br>(Big photo, bio, contact btn) |
| **Resources** | User adds 5 items. Names them "Website", "Store". No images. | Desc: Maybe<br>Items: 5 (No Img) | **LayoutStack**<br>(List of buttons) |
| **Menu** | User adds 10 items (Dishes) with photos. | Desc: Yes<br>Items: 10 (Has Img) | **LayoutGrid**<br>(Visual Grid) |
| **Museum** | User adds 3 Rooms (Parents) with artifacts (Children). | Desc: Yes<br>Sub-items: Yes | **LayoutGuide**<br>(Hierarchical View) |

## 5. Implementation Status ✅

### Completed:
1.  ✅ **`LayoutProfile.vue`:** Profile view for SOLO mode (circular image, bio, share/save contact buttons).
2.  ✅ **`LayoutStack.vue`:** Links view for STACK mode (button list with smart icon detection).
3.  ✅ **`SmartContentRenderer.vue`:** Heuristic router that auto-detects layout OR respects explicit `content_mode`.
4.  ✅ **`ContentListGrid.vue`:** Preserved original grid layout for CATALOG/GUIDE modes.
5.  ✅ **CMS Mode Selector:** Added content mode selector to `CardCreateEditForm.vue` with guidance banners.
6.  ✅ **Database Schema:** Added `content_mode` column to `cards` table.
7.  ✅ **i18n:** Added English and Traditional Chinese translations for all mode labels.

### Detection Logic:
- **Priority 1:** If `content_mode` is explicitly set in CMS → Use that mode.
- **Priority 2:** Heuristic detection based on content structure (0 items → Profile, no images → Stack, else → Grid).

