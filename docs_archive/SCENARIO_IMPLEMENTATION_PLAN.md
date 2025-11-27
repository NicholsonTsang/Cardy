# Implementation Plan: Enriched Content Scenarios

This document outlines the strategy to evolve CardStudio's "Master-Detail" architecture into a multi-modal platform capable of serving diverse business scenarios.

## 1. The "Enriched" Scenario Models

We will formalize the following display modes to adapt to different content volumes and use cases.

### Mode A: "The Explorer" (Current Standard)
*   **Structure:** Cover Card $\to$ Grid View $\to$ Detail View $\to$ Sub-items.
*   **Use Case:** Museums, Exhibitions, Multi-room Galleries.
*   **Behavior:** Users land on the branded cover, click "Explore" to see the full catalog (Grid), and drill down into topics.

### Mode B: "The Guide" (Single Asset / Guidance)
*   **Structure:** Cover Card $\to$ Detail View (Auto-skip Grid).
*   **Use Case:** Single Product Manual, Restaurant Menu, specific artifact guide, "Guidance" scenario.
*   **Behavior:**
    *   If the card contains **only one** top-level content item.
    *   Clicking "Explore" skips the `ContentList` grid entirely.
    *   Directly opens the `ContentDetail` view for that item.
    *   *Benefit:* Removes friction. Users get straight to the content.

### Mode C: "The Portal" (Direct Directory)
*   **Structure:** Grid View (Skip Cover).
*   **Use Case:** Event Directory, Staff List, Product Catalog.
*   **Behavior:**
    *   Useful when the branding is already established (e.g., via QR context) and speed is the priority.
    *   The app loads directly into the `ContentList` view.

### Mode D: "The Concierge" (AI First)
*   **Structure:** Cover Card $\to$ Auto-Open AI Chat.
*   **Use Case:** Hotel Front Desk, Conference Help Desk.
*   **Behavior:**
    *   The primary value is the AI.
    *   On load, the AI Assistant modal opens automatically (or is the main view).

---

## 2. Technical Implementation Plan

### Phase 1: Smart Auto-Detection (Immediate)
**Goal:** Implement "The Guide" (Mode B) without database schema changes by detecting content shape.

**Logic in `PublicCardView.vue`:**
1.  **Analyze Content:** In `fetchCardData`, calculate `topLevelContent.length`.
2.  **Modify Navigation:** Update `openContentList()` function:
    ```typescript
    function openContentList() {
      if (topLevelContent.value.length === 1) {
        // Smart Skip: Go directly to detail
        selectContent(topLevelContent.value[0]);
      } else {
        // Standard: Go to grid
        pushNavigation();
        currentView.value = 'content-list';
      }
    }
    ```
3.  **Back Navigation:** Ensure the "Back" button in `ContentDetail` correctly returns to `CardOverview` (skipping the non-existent `ContentList` step) if there was only one item.

### Phase 2: Configuration Control (Future)
**Goal:** Give Card Issuers explicit control over the experience via CMS.

1.  **Database Schema:**
    *   Add `display_mode` column to `cards` table.
    *   Type: Enum (`standard`, `direct_detail`, `direct_grid`, `ai_first`).
    *   Default: `standard`.

2.  **CMS Update:**
    *   Add a "Display Settings" section in `CardEdit.vue`.
    *   Dropdown to select the mode.

3.  **Frontend Adaptation:**
    *   Update `PublicCardView.vue` to respect `cardData.display_mode`.
    *   **Direct Grid:** `onMounted` $\to$ set `currentView = 'content-list'`.
    *   **AI First:** `onMounted` $\to$ trigger `openAIAssistant()`.

---

## 3. Detailed Logic for "The Guide" (Phase 1)

This specific implementation addresses the "Guidance" scenario requested.

**Scenario:** A user scans a QR code on a specific machine to see its "User Manual".
**Data:** 1 Content Item ("How to Operate").

**Flow:**
1.  **Load:** User sees the Cover Card ("Machine X Manual") $\to$ builds trust/branding.
2.  **Action:** User clicks "Start" / "Explore".
3.  **Transition:** System detects `count === 1`.
    *   **SKIP:** `ContentList` (Grid).
    *   **LOAD:** `ContentDetail` (The Manual).
4.  **Result:** User is reading the manual in 1 click, not 2.

**Refinement for Sub-items:**
If the Single Item has sub-items (e.g., "Chapters"), they appear naturally at the bottom of the Detail View (as currently implemented), effectively acting as a "Table of Contents". This perfectly suits the "Guidance" model.

