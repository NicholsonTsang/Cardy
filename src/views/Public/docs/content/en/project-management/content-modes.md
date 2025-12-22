## Understanding Content Modes

Content modes determine how your content is displayed to visitors. Choose the mode that best fits your venue type and content structure.

## Available Modes

### Single Mode

Perfect for focused experiences with one main piece of content.

- **Best for**: Product showcases, special exhibits, event information
- **Layout**: Full-screen content with maximum detail
- **AI Behavior**: Deep-dive conversations about the featured item

### List Mode

Vertical scrolling list of content items.

- **Best for**: Menus, service lists, simple catalogs
- **Layout**: Clean list with images and descriptions
- **AI Behavior**: Help browse and filter options

### Grid Mode

Visual gallery layout with thumbnail grid.

- **Best for**: Art galleries, photo collections, product catalogs
- **Layout**: Responsive grid with image previews
- **AI Behavior**: Explore the gallery, suggest items based on interests

### Grouped Mode

Content organized into expandable categories.

- **Best for**: Museums, multi-floor venues, categorized menus
- **Layout**: Collapsible sections with nested items
- **AI Behavior**: Navigate categories, compare items, give overviews

### Inline Mode

Continuous scrolling with all content visible.

- **Best for**: Timeline experiences, story-driven content, tours
- **Layout**: Seamless vertical flow
- **AI Behavior**: Guide through the continuous experience

## Choosing the Right Mode

| Venue Type | Recommended Mode | Why |
|------------|-----------------|-----|
| Museum | Grouped | Natural gallery/floor organization |
| Restaurant | List | Easy menu scanning |
| Gallery | Grid | Visual browsing experience |
| Event | Single | Focused information |
| Tour | Inline | Sequential storytelling |
| Hotel | List | Service directory format |
| Conference | Grouped | Sessions by track/day |

:::tip Preview Before Publishing
Use the Preview function to see how each mode displays your content before making a final decision.
:::

## AI Assistant in Different Modes

The AI assistant adapts its behavior based on the current content mode:

### Navigation Pages
- **General Assistant** appears (floating button)
- Helps with browsing, recommendations, general questions
- Available on all list/grid/grouped views

### Detail Pages
- **Item Assistant** appears (inline button)
- Provides deep information about the specific item
- Uses item-specific knowledge base and welcome message

## Changing Content Mode

To change your project's content mode:

1. Open your project settings
2. Navigate to Display Settings
3. Select a new Content Mode
4. Preview the changes
5. Save if satisfied

:::warning Content Reorganization
When switching to Grouped mode, you may need to reorganize items into categories. When switching away from Grouped mode, sub-items will become top-level items.
:::

## Grouped vs Flat Layouts

### Grouped Display (`is_grouped: true`)
- Shows parent items as expandable category headers
- Child items nested under their parents
- Great for hierarchical content

### Flat Display (`is_grouped: false`)
- All items at the same visual level
- Parent items hidden, only children shown
- Better for browsing without category structure

:::info Hierarchy Detection
If your content has parent-child relationships but you use a flat layout, the system automatically shows only leaf items (actual content) and hides parent containers.
:::
