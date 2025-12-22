## Bulk Import

Save time by importing multiple content items at once using Excel spreadsheets. Bulk import supports full project creation with all settings, content, and translations.

## Excel Template

Download our Excel template to get started:

1. Navigate to My Projects
2. Click "Bulk Import"
3. Download the template file

![Bulk Import Button](/Image/docs/bulk-import-button.png "Bulk Import")

## Template Structure

The Excel template includes multiple sheets:

### Card (Project) Sheet

| Column | Description | Required |
|--------|-------------|----------|
| Name | Project name | Yes |
| Description | Project overview | Yes |
| Content Mode | single/list/grid/grouped/inline | Yes |
| Original Language | Source language code | No |
| AI Instruction | AI behavior guidelines | No |
| AI Knowledge Base | General AI context | No |
| AI Welcome General | Project-level greeting | No |
| AI Welcome Item | Item-level greeting template | No |
| Is Grouped | Enable grouped display | No |
| Group Display | collapsed/expanded | No |
| Max Scans | Total scan limit | No |
| Daily Scan Limit | Per-day limit | No |

### Content Sheet

| Column | Description | Required |
|--------|-------------|----------|
| Name | Item title | Yes |
| Description | Item description | Yes |
| Parent Name | For sub-items, name of parent | No |
| Image URL | Link to image | No |
| AI Knowledge Base | Item-specific AI context | No |
| Order | Display order (number) | No |
| Translations JSON | Pre-translated content | No |

:::tip Image URLs
Images must be publicly accessible URLs. Upload images to a hosting service first, then include the URLs in your spreadsheet.
:::

## Import Process

### Step 1: Prepare Your Data

Fill in the Excel template with your content:

- One row per content item
- Keep text concise and clear
- Ensure image URLs are valid
- Include parent names for hierarchical content

### Step 2: Upload File

1. Click "Bulk Import" on My Projects page
2. Select your completed Excel file
3. Review the import preview

![Import Preview](/Image/docs/bulk-import-preview.png "Import Preview")

### Preview Information

The preview shows:
- Project settings (mode, language, AI status)
- Content item count
- Translations included
- Grouped structure status

### Step 3: Confirm Import

Review the import preview:

- Check settings badges (mode, language, AI enabled)
- Verify content item count
- See included translations (if any)
- Resolve any validation errors

### Step 4: Complete Import

Click "Import" to create your project. Large imports may take a few moments.

:::warning Subscription Limits
Bulk import respects subscription limits. Free tier users can have up to 3 projects total. The import will fail if it would exceed your limit.
:::

## Exporting Projects

You can export existing projects to Excel:

1. Open your project
2. Click "Export to Excel"
3. Download the generated file

Exports include:
- All project settings
- Content items with hierarchy
- AI configuration
- Translations (if any)

## Handling Errors

Common import errors and solutions:

### Missing Required Fields
- Ensure Name and Description columns are filled
- Remove empty rows from the spreadsheet

### Invalid Image URLs
- Verify URLs are publicly accessible
- Check for typos in URLs
- Ensure images are in supported formats (JPG, PNG, WebP)

### Duplicate Names
- Each item name must be unique within a project
- Add distinguishing details to duplicate names

### Invalid Content Mode
- Use exact values: single, list, grid, grouped, inline
- Case-sensitive matching

## Preserving Translations

When importing Excel files that were previously exported:

- **Translations JSON** column preserves all translated content
- All languages included in the export will be imported
- Translation status will be preserved

:::tip Round-Trip Editing
Export → Edit in Excel → Re-import preserves all your translations and settings. Great for bulk text updates.
:::

## Best Practices

1. **Start Small** - Test with a few items first
2. **Validate URLs** - Check all image links before import
3. **Consistent Formatting** - Keep descriptions similar in length and style
4. **Backup Original** - Keep a copy of your Excel file
5. **Review After Import** - Verify all content imported correctly
6. **Check AI Fields** - Ensure AI knowledge base content is accurate

## Updating Imported Content

After import, you can edit items individually:

- Click any item to open the editor
- Make changes and save
- Changes apply immediately
- Re-export to update your Excel backup
