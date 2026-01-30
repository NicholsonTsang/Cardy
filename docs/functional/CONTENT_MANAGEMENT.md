# Content Management

This guide covers adding, organizing, and managing content within your ExperienceQR projects.

## Understanding Content Items

**Content items** are the individual pieces of information visitors see when they access your project. Each item can include:

- **Title** - The headline visitors see
- **Description** - Detailed text content (supports formatting)
- **Image** - Visual media
- **Link** - External URL for more information
- **AI Knowledge** - Context for the AI assistant

## Adding Content Items

### Basic Steps

1. Open your project
2. Go to the **Content** tab
3. Click **+ Add Item**
4. Fill in the details
5. Click **Save**

### Content Item Fields

| Field | Required | Description |
|-------|----------|-------------|
| **Title** | Yes | Item headline (keep concise) |
| **Description** | No | Main content text |
| **Image** | No | Visual for this item |
| **Link URL** | No | External link |
| **Link Label** | No | Text for the link button |

### Writing Good Content

**Titles:**
- Keep under 50 characters
- Be specific and descriptive
- Front-load important words

**Descriptions:**
- Use short paragraphs
- Break up text with line breaks
- Focus on what visitors need to know
- Mobile-friendly (visitors read on phones)

## Content Formatting

Descriptions support **Markdown** formatting:

### Basic Formatting

```markdown
**Bold text** for emphasis
*Italic text* for subtle emphasis
~~Strikethrough~~ for corrections

# Heading 1
## Heading 2
### Heading 3
```

### Lists

```markdown
Bullet list:
- First item
- Second item
- Third item

Numbered list:
1. Step one
2. Step two
3. Step three
```

### Links

```markdown
[Link text](https://example.com)
```

### Best Practices

- Don't overuse formatting
- Keep paragraphs short
- Use headings to organize long content
- Test how it looks on mobile

## Managing Images

### Image Guidelines

| Aspect | Recommendation |
|--------|----------------|
| **Format** | JPG, PNG, WebP |
| **Max Size** | 5MB |
| **Aspect Ratio** | Varies by display mode |
| **Resolution** | At least 800px wide |

### Images by Display Mode

| Mode | Recommended Size | Notes |
|------|------------------|-------|
| **Single** | 1200×800 | Large, prominent |
| **List** | 400×300 | Thumbnail size |
| **Grid** | 600×600 | Square works well |
| **Cards** | 1200×600 | Wide format |

### Uploading Images

1. Click the image upload area
2. Select file from your device
3. Wait for upload to complete
4. Adjust cropping if needed

### Image Tips

- **Compress images** before uploading for faster loading
- **Use consistent style** across items
- **Avoid text in images** (doesn't translate)
- **Check mobile preview** to ensure visibility

## Organizing Content

### Reordering Items

1. Go to the Content tab
2. Drag items using the handle (⋮⋮)
3. Drop in new position
4. Order saves automatically

### Content Grouping

Enable grouping in project settings to organize items into categories.

**Creating Groups:**

1. Enable **Grouped Content** in settings
2. Create parent items (categories)
3. Nest child items under parents

**Example Structure:**
```
📁 First Floor
   └── Lobby Exhibit
   └── Gift Shop
   └── Information Desk
📁 Second Floor
   └── Main Gallery
   └── Special Exhibition
📁 Third Floor
   └── Education Center
   └── Library
```

### Group Display Options

| Option | Behavior |
|--------|----------|
| **Expanded** | All items visible under categories |
| **Collapsed** | Tap category to reveal items |

## Adding Links

### External Links

Add links to direct visitors to external resources:

1. Enter the **Link URL** (full URL including https://)
2. Enter a **Link Label** (button text)
3. Save the item

**Example:**
- URL: `https://tickets.museum.com`
- Label: "Buy Tickets"

### Link Best Practices

- Use descriptive labels ("View Full Menu" not "Click Here")
- Ensure links work on mobile
- Test links before going live
- Consider link relevance (don't link to competitors)

## Bulk Operations

### Selecting Multiple Items

1. Enable selection mode (checkbox appears)
2. Click items to select
3. Perform bulk action

### Available Bulk Actions

| Action | Description |
|--------|-------------|
| **Delete** | Remove selected items |
| **Move** | Change parent group |
| **Reorder** | Adjust positions |

## Content Templates

### Using Templates

If your plan includes template access:

1. Click **Use Template** when adding content
2. Browse available templates
3. Select and customize

### Creating from Templates

Templates provide pre-structured content for common use cases:
- Museum exhibits
- Restaurant menus
- Event schedules
- Hotel services

## Importing Content

### From Spreadsheet

For bulk content import:

1. Download the template spreadsheet
2. Fill in your content
3. Upload the completed file
4. Review and confirm import

### Import Format

| Column | Description |
|--------|-------------|
| title | Item title |
| description | Content text |
| image_url | Image URL (optional) |
| link_url | External link (optional) |
| position | Order number |

## Exporting Content

### Export to Excel

Download your project content:

1. Open project settings
2. Click **Export**
3. Choose format (Excel with images)
4. Download file

### Export Includes

- All content items
- Embedded images
- Metadata (dates, positions)
- Translations (if applicable)

## Content for AI Assistant

### Adding AI Context

Each item can have knowledge for the AI assistant:

1. Edit the content item
2. Find **AI Knowledge** section
3. Add relevant information
4. Save

### What to Include

**Good AI knowledge:**
- Facts not in the description
- Historical context
- Fun trivia
- Frequently asked questions
- Related information

**Example:**
```
The Mona Lisa was painted between 1503-1519.
It measures 77cm × 53cm.
The painting was stolen in 1911 and recovered in 1914.
Common questions: Why is she smiling? Who was she?
```

## Best Practices

### Content Quality

- **Proofread** all text before publishing
- **Use real photos** (not stock when possible)
- **Keep it current** - update outdated information
- **Be concise** - mobile visitors want quick info

### Accessibility

- **Alt text** for images (describe the image)
- **Clear language** - avoid jargon
- **Sufficient contrast** - readable text
- **Logical order** - sensible item sequence

### Maintenance

- **Regular reviews** - check content quarterly
- **Update seasonal info** - hours, events, specials
- **Remove outdated items** - keep content fresh
- **Monitor feedback** - what do visitors ask about?

## Troubleshooting

### Content Not Saving

- Check internet connection
- Ensure no validation errors (red fields)
- Try a shorter description
- Refresh and try again

### Images Not Uploading

- Check file size (under 5MB)
- Verify format (JPG, PNG, WebP)
- Try a different browser
- Compress the image and retry

### Formatting Not Displaying

- Check Markdown syntax
- Ensure blank lines between paragraphs
- Preview before saving
- Some special characters may need escaping
