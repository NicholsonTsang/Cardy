# Content Structure Matrix

This document maps the technical structure of a card (Description + Parent Items + Sub-Items) to the Functional Content Modes. This logic helps the frontend determine the best layout (Grid vs. List vs. Profile) and helps the user understand how to build their desired experience.

## The Matrix

| Card Description | Parent Items (L1) | Sub-Items (L2) | **Content Mode** | **User Scenario** | **UI Layout** |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **YES** | **0** | **0** | **SOLO**<br>*(Profile)* | **Digital Business Card**<br>User wants to share contact info, bio, and social links only. | **Profile View**<br>Large Header, Bio text, Sticky "Save Contact" button. No content grid. |
| **NO** | **1** | **0** | **SOLO**<br>*(Focus)* | **Single Asset Drop**<br>Marketing campaign pointing to a *single* promo video or PDF download. | **Hero View**<br>Full-screen media/content. No distraction. |
| **NO** | **N** | **0** | **STACK**<br>*(Links)* | **Link-in-Bio / Resources**<br>A list of external links (Website, YouTube, Store). No context needed. | **List View**<br>Compact rows. Small icons. Text-heavy. |
| **YES** | **N** | **0** | **CATALOG**<br>*(Flat)* | **Simple Gallery / Portfolio**<br>An artist showing 10 paintings. A restaurant showing 5 daily specials. | **Grid View** (Masonry)<br>Large images. Card Description acts as the "Intro". |
| **YES** | **1** | **N** | **GUIDE**<br>*(Manual)* | **Instruction Manual**<br>One product (Parent) with multiple steps/parts (Sub-items). | **Book View**<br>Parent is the "Cover/Overview". Sub-items are "Chapters" listed below. |
| **YES** | **N** | **N** | **GUIDE**<br>*(Tour)* | **Museum Tour / Exhibition**<br>Multiple Rooms (Parents), each containing specific Artifacts (Sub-items). | **Collection View**<br>Grid of Parent cards. Clicking a Parent opens a detail page listing its Sub-items. |
| **YES** | **N** | **N** | **CATALOG**<br>*(Complex)* | **Full Menu / E-Commerce**<br>Categories (Parents: "Appetizers", "Mains") containing Products (Sub-items). | **Categorized List**<br>Parent items act as Section Headers. Sub-items displayed in grids/lists under them. |

---

## 2. The "Agent" Overlay

**AGENT Mode** (AI Chat) is not a structural layout but an **functional overlay** that can be applied to *any* of the above structures.

| Structure | + AI Enabled | Resulting Experience |
| :--- | :--- | :--- |
| **SOLO (Profile)** | **+ AI** | **Interactive Resume:** "Ask me about my work history." |
| **GUIDE (Manual)** | **+ AI** | **Smart Support:** "How do I fix error 404?" (AI searches the sub-items). |
| **GUIDE (Tour)** | **+ AI** | **Museum Docent:** "Tell me more about the dinosaur in the hall." |
| **CATALOG** | **+ AI** | **Sales Assistant:** "Do you have any vegan options?" |

## 3. Implementation Logic (Frontend)

The frontend should automatically adapt the layout based on these counts if no explicit mode is selected:

```javascript
// Pseudo-code for Layout Detection
if (itemCount === 0) {
    return 'LAYOUT_PROFILE'; // Focus on Description/Bio
} 
else if (itemCount === 1 && !hasDescription) {
    return 'LAYOUT_HERO'; // Focus on the single content item
} 
else if (subItemCount === 0) {
    // Decision: Is it visual (Catalog) or utilitarian (Stack)?
    // Usually default to Grid (Catalog) as it's more engaging
    return 'LAYOUT_GRID'; 
} 
else {
    // Has sub-items, needs hierarchical view
    return 'LAYOUT_COLLECTION'; 
}
```

