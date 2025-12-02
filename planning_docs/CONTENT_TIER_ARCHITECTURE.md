# Content Tier Architecture Summary

CardStudio employs a flexible **Two-Layer Content Architecture** designed to organize information hierarchically while maintaining a consistent editing and rendering experience. This structure allows Card Issuers to present complex topics (like a museum exhibition) in a digestible, drill-down format.

## 1. Architecture Overview

The content is structured into two distinct tiers:

*   **Layer 1: Content Items (Parent)**
    *   These are the primary entry points displayed in the main card view.
    *   **Usage:** Represents major topics, exhibits, or sections (e.g., "Dinosaur Hall", "Main Stage", "Appetizers").
    *   **Visibility:** Displayed as large cards in the main `ContentList` grid.
    *   **Features:** Can contain their own rich text, images, AI knowledge, and *nested sub-items*.

*   **Layer 2: Sub-Items (Child)**
    *   These are detailed units nested *under* a specific Parent Content Item.
    *   **Usage:** Represents specific details, artifacts, or sub-topics (e.g., "T-Rex Skull" under "Dinosaur Hall").
    *   **Visibility:** Displayed as a "Related Content" list within the Parent Item's detail view.
    *   **Features:** Inherits context from the parent but has its own specific image, text, and AI knowledge base.

---

## 2. Edit Format (CMS)

The Content Management System (`CardContentCreateEditForm.vue`) provides a unified interface for creating both layers, ensuring consistency.

### Key Components:
*   **Rich Text Editor:** Uses a **Markdown Editor (`MdEditor`)** for the content description. This allows issuers to format text with:
    *   **Typography:** Bold, Italic, Headings.
    *   **Structure:** Bullet points, Numbered lists.
    *   **Links:** External hyperlinks (automatically set to open in new tabs).
    *   **Tables:** For structured data.
*   **Image Pipeline:**
    *   **Dual Storage:** Stores both the `original_image_url` (raw upload) and `image_url` (optimized/cropped).
    *   **Integrated Cropper:** Includes an `ImageCropper` tool that enforces the card's specific aspect ratio (e.g., 4:3) to ensure perfect visual presentation on mobile devices.
*   **AI Integration:**
    *   **Knowledge Base Field:** A dedicated text area (max 500 words) for "AI Knowledge Base". This data is *invisible* to the visitor but is fed to the LLM to enable the AI to answer specific questions about that item.

---

## 3. Render Format (Mobile Client)

The mobile client renders this content using a reactive, responsive design optimized for visitor engagement.

### Viewing Modes:
*   **Grid View (`ContentList.vue`):**
    *   Renders Layer 1 items as a masonry-style grid.
    *   Displays: Thumbnail image, Title, Truncated description (3 lines).
    *   **Badges:** Visual indicators for "AI Chat Available" and "X Items Inside" (sub-item count).
*   **Detail View (`ContentDetail.vue`):**
    *   **Hero Section:** Displays the high-resolution cropped image.
    *   **Markdown Renderer:** Converts the stored Markdown into semantic HTML.
        *   Sanitizes input to prevent XSS.
        *   Styles links, lists, and headers to match the glassmorphism UI theme.
    *   **Context-Aware AI:** The `MobileAIAssistant` button is embedded directly in the content flow, pre-loaded with the specific item's name and knowledge base.
    *   **Sub-Item Navigation:** Layer 2 items appear at the bottom as a "Related Content" list, allowing seamless navigation deeper into the content tree.

### Technical Data Flow:
1.  **Fetch:** Content is fetched via `get_card_content_items` RPC call.
2.  **Process:** The frontend separates items into Parents and Children based on `parent_id`.
3.  **Render:** Vue components recursively render the hierarchy, applying CSS variables for dynamic aspect ratios and responsive layouts.

