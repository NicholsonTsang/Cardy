# Card Import/Export Integration Guide

## Overview

The Card Import/Export functionality provides comprehensive tools for backing up, migrating, and bulk managing card data in XLSX format. This includes both general card information and all associated content items.

## Features

### Export Capabilities
- **Single Card Export**: Export individual card with all content items
- **Multiple Card Export**: Bulk export selected cards
- **All Cards Export**: Export entire card library
- **Multi-sheet Structure**: Separate sheets for card info, content items, and instructions

### Import Capabilities
- **Template Generation**: Download structured import template
- **Data Validation**: Comprehensive validation before import
- **Preview System**: Review changes before applying
- **Batch Processing**: Create and update multiple cards simultaneously
- **Error Handling**: Detailed error reporting and recovery

## File Structure

### Export Format (3 Sheets)

#### Sheet 1: Card Info
```
Field               | Value
--------------------|------------------
Card ID             | auto-generated
Card Name           | Museum Exhibition
Card Description    | Interactive museum experience
Card Type           | museum
AI Prompt           | You are a museum guide...
Tags                | history,art,culture
Business Name       | Sample Museum
Business Address    | 123 Museum St
Business Email      | info@museum.com
Business Phone      | +1234567890
Business Website    | www.museum.com
```

#### Sheet 2: Content Items
```
ID | Parent ID | Type  | Title        | Content              | AI Metadata | Order | Media URL | Media Type
---|-----------|-------|--------------|---------------------|-------------|-------|-----------|------------
   |           | text  | Welcome      | Welcome to museum   | greeting    | 1     |           |
   |           | image | Gallery      | Main gallery view   | gallery     | 2     | url.jpg   | image/jpeg
```

#### Sheet 3: Instructions
- Import guidelines
- Field descriptions
- Best practices

### Import Template Format

The import template provides a structured format for creating new cards:

- **Cards Sheet**: Basic card information
- **Content Sheet**: Associated content items
- **Instructions Sheet**: Detailed import guidelines

## Integration Examples

### 1. MyCards View Integration

```vue
<template>
  <div class="my-cards-view">
    <!-- Existing card list -->
    <DataTable :value="cards">
      <!-- columns -->
    </DataTable>
    
    <!-- Import/Export Panel -->
    <Accordion class="mt-6">
      <AccordionTab header="Import / Export Cards">
        <CardImportExport 
          :single-card-mode="false"
          @imported="refreshCards"
        />
      </AccordionTab>
    </Accordion>
  </div>
</template>

<script setup>
import CardImportExport from '@/components/Card/CardImportExport.vue'

async function refreshCards() {
  // Reload cards after import
  await cardStore.fetchCards()
}
</script>
```

### 2. Single Card View Integration

```vue
<template>
  <div class="card-detail-view">
    <!-- Card editing interface -->
    
    <!-- Export/Import for current card -->
    <Card class="mt-6">
      <template #title>Backup & Import</template>
      <template #content>
        <CardImportExport 
          :single-card-mode="true"
          :current-card-id="cardId"
          @imported="refreshCardData"
        />
      </template>
    </Card>
  </div>
</template>
```

### 3. Admin Panel Integration

```vue
<template>
  <div class="admin-panel">
    <!-- System-wide import/export -->
    <TabView>
      <TabPanel header="Card Management">
        <CardImportExport 
          :single-card-mode="false"
          @imported="handleSystemImport"
        />
      </TabPanel>
    </TabView>
  </div>
</template>
```

## Usage Workflows

### Export Workflow
1. **Select Cards**: Choose single card or multiple cards
2. **Export Format**: System generates XLSX with 3 sheets
3. **Download**: File automatically downloads
4. **External Editing**: Edit in Excel/Google Sheets
5. **Backup**: Store for backup or migration

### Import Workflow
1. **Download Template**: Get structured import template
2. **Prepare Data**: Fill in card and content information
3. **Upload File**: Drag and drop XLSX file
4. **Validation**: System validates data structure
5. **Preview**: Review changes before applying
6. **Confirmation**: Execute import with detailed results

## Data Validation Rules

### Card Validation
- **Required Fields**: `card_name`
- **Unique Constraints**: Card names must be unique
- **Format Validation**: Email and URL format checking
- **Existence Checks**: Verify card IDs for updates

### Content Validation
- **Required Fields**: `card_name`, `title`
- **Type Validation**: Valid content types (text, image, video, audio, link)
- **Relationship Checks**: Ensure card exists for content items
- **Media Validation**: Require URLs for media content types

## Error Handling

### Import Errors
- **Missing Required Fields**: Clear field-level validation
- **Invalid References**: Card or content ID not found
- **Format Errors**: Invalid email, URL, or data types
- **Duplicate Names**: Conflict resolution guidance

### Recovery Options
- **Partial Success**: Continue with valid items, report errors
- **Rollback Capability**: Version control for safety
- **Error Export**: Download error report for correction

## Performance Considerations

### Large Data Sets
- **Chunk Processing**: Handle large imports in batches
- **Progress Indicators**: Show import/export progress
- **Memory Management**: Stream processing for large files
- **Background Jobs**: Async processing for bulk operations

### File Size Limits
- **Maximum File Size**: 10MB upload limit
- **Content Optimization**: Compress large content
- **Media References**: Use URLs instead of embedded media

## Security Features

### Data Protection
- **User Isolation**: Only access own cards
- **Permission Checks**: Verify ownership before operations
- **Input Sanitization**: Clean all imported data
- **Audit Logging**: Track import/export activities

### File Validation
- **File Type Checking**: Only accept .xlsx/.xls files
- **Content Scanning**: Validate file structure
- **Size Limits**: Prevent resource exhaustion
- **Virus Scanning**: Future integration capability

## Installation Requirements

### Dependencies
```bash
npm install xlsx
```

### File Registration
```javascript
// In main.js or component
import CardImportExport from '@/components/Card/CardImportExport.vue'
```

## API Requirements

The import/export functionality requires these stored procedures:

### Existing Procedures
- `get_card_by_id(p_card_id)`
- `get_card_content_items(p_card_id)`
- `create_card(...)` 
- `update_card(...)`
- `create_content_item(...)`
- `update_content_item(...)`

### New Procedures (if needed)
```sql
-- Batch card operations
CREATE OR REPLACE FUNCTION bulk_create_cards(p_cards jsonb)
RETURNS jsonb AS $$
-- Implementation for efficient bulk operations
$$;

-- Content item batch operations  
CREATE OR REPLACE FUNCTION bulk_create_content_items(p_items jsonb)
RETURNS jsonb AS $$
-- Implementation for efficient bulk content creation
$$;
```

## Best Practices

### Export Best Practices
1. **Regular Backups**: Schedule periodic exports
2. **Version Control**: Include timestamps in filenames
3. **Documentation**: Use instruction sheets for team members
4. **Validation**: Test exports with re-import

### Import Best Practices
1. **Template Usage**: Always start with downloaded template
2. **Data Validation**: Validate in Excel before import
3. **Incremental Updates**: Import in small batches
4. **Backup First**: Export existing data before major imports

### Content Management
1. **Hierarchical Structure**: Use parent_id for content organization
2. **Order Management**: Use order_position for display sequence
3. **Media Management**: Host media externally, reference URLs
4. **Metadata Usage**: Leverage ai_metadata for enhanced AI responses

This comprehensive import/export system enables efficient card data management, backup, and migration workflows while maintaining data integrity and user experience.