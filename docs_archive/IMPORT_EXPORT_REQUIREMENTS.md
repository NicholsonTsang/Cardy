# Card Import/Export Requirements

## Overview
The Card Import/Export functionality allows users to bulk manage their card data through Excel files, providing an intuitive way to create, update, and transfer card information with embedded images.

## Core Features

### 1. Export Functionality

#### 1.1 Export Trigger
- **Location**: Import/Export tab in card detail panel
- **Button**: "Export Card Data" with download icon
- **Filename**: `{CardName}_Export_{YYYY-MM-DD}.xlsx`

#### 1.2 Export Content
- **Two Worksheets**:
  1. "Card Information" - Card metadata
  2. "Content Items" - Hierarchical content structure

#### 1.3 Export Data Mapping
**Card Information Sheet:**
- Card Name
- Description  
- AI Prompt
- Conversation AI Enabled (true/false)
- Content Render Mode (dropdown values)
- QR Code Position (TL/TR/BL/BR)
- Card Image (embedded image, not URL)

**Content Items Sheet:**
- Name
- Content Description
- AI Metadata
- Sort Order
- Layer (Layer 1/Layer 2)
- Parent Reference (cell reference for Layer 2 items)
- Image (embedded image, not URL)

### 2. Import Functionality

#### 2.1 Import Trigger
- **Location**: Card list panel
- **Button**: "Import Cards" button that opens dialog
- **Dialog**: Drag-and-drop file upload interface

#### 2.2 Import Process
1. File validation
2. Data extraction and validation
3. Image processing
4. Preview with validation results
5. Confirmation and import execution

## Excel Format Requirements

### 3. User Experience Design

#### 3.1 Professional Layout
```
Row 1: Title with card name and branded styling
Row 2: Instructions for users
Row 3: Field headers with clear names
Row 4: Field descriptions/examples
Row 5+: Data rows
```

#### 3.2 Visual Design Elements
- **Color Scheme**: Blue theme matching CardStudio branding
- **Typography**: Bold headers, clear descriptions
- **Cell Styling**: Borders, alternating row colors (zebra striping)
- **Icons**: Use Unicode icons where possible (🎴, 📝, 🤖, 📷)

#### 3.3 Data Validation
- **Dropdowns**: Pre-populated for enum fields
- **Input Validation**: Data type restrictions
- **Required Fields**: Visual indicators (red highlighting)
- **Error Prevention**: Template with examples

### 4. Content Hierarchy Management

#### 4.1 Layer System
- **Layer 1**: Top-level content items (parents)
- **Layer 2**: Sub-items that reference Layer 1 parents

#### 4.2 Parent Reference System
- **Method**: Excel cell references (e.g., A8, A11)
- **Validation**: Dropdown populated with Layer 1 item names
- **Visual Clarity**: Clear labeling and examples

#### 4.3 Sort Order
- **Automatic**: System generates if not provided
- **Manual**: Users can specify custom ordering
- **Validation**: Numeric values only

### 5. Image Handling

#### 5.1 Export Image Requirements
- **Format**: Embedded images in Excel cells
- **Size**: Standardized thumbnail size (100x80px)
- **Quality**: Optimized for file size
- **Fallback**: Placeholder for missing images

#### 5.2 Import Image Requirements
- **Input Methods**:
  - Paste images directly into cells
  - Drag and drop images into cells
  - URL references (automatically downloaded)
- **Supported Formats**: PNG, JPG, GIF
- **Size Limits**: Maximum 5MB per image
- **Processing**: Automatic optimization and validation

### 6. Excel Template Structure

#### 6.1 Card Information Sheet
```
A1: 🎴 Card Information - [Card Name]
A2: 📝 Instructions: Fill in the data below. Required fields are marked with *

Headers (Row 3):
- Name*
- Description  
- AI Prompt
- AI Enabled*
- Render Mode*
- QR Position*
- Card Image

Descriptions (Row 4):
- "The main title of your card"
- "Brief description of the card's purpose"
- "Instructions for AI assistant"
- "true or false"
- "Select from dropdown"
- "Select position: TL/TR/BL/BR"
- "Paste image here or leave blank"
```

#### 6.2 Content Items Sheet
```
A1: 📋 Content Items - Hierarchical Structure
A2: 📝 Instructions: Create Layer 1 items first, then Layer 2 items that reference them

Headers (Row 3):
- Name*
- Content
- AI Metadata
- Sort Order
- Layer*
- Parent Reference
- Image

Smart Features:
- Layer dropdown (Layer 1/Layer 2)
- Parent reference dropdown (populated from Layer 1 items)
- Automatic sort order calculation
- Image embedding area
```

### 7. Data Validation Rules

#### 7.1 Required Field Validation
- **Visual Indicators**: Red cell borders for empty required fields
- **Error Messages**: Clear descriptions of what's needed
- **Prevention**: Template with examples to guide users

#### 7.2 Data Type Validation
- **Boolean Fields**: Dropdown with true/false only
- **Enum Fields**: Dropdown with valid options only
- **Numeric Fields**: Number validation with ranges
- **Text Fields**: Length limits where applicable

#### 7.3 Relationship Validation
- **Parent References**: Must point to valid Layer 1 items
- **Circular References**: Prevention and detection
- **Orphaned Items**: Warning for Layer 2 items without parents

### 8. Smart Excel Features

#### 8.1 Formulas and Calculations
- **Item Counts**: `=COUNTA(range)` for statistics
- **Layer Counts**: `=COUNTIF(range, "Layer 1")` for summaries
- **Validation**: `=INDIRECT()` for dynamic references

#### 8.2 Conditional Formatting
- **Required Fields**: Highlight empty required cells
- **Layer Identification**: Color coding for Layer 1 vs Layer 2
- **Status Indicators**: Green/red for valid/invalid data

#### 8.3 Data Types and Features
- **Tables**: Convert ranges to Excel tables for better UX
- **Comments**: Help text in cell comments
- **Protection**: Lock template areas, allow data entry only

### 9. Error Handling and User Feedback

#### 9.1 Import Validation
- **Pre-import Checks**: Validate before processing
- **Error Reporting**: Clear list of issues with row numbers
- **Warning System**: Non-blocking issues with recommendations
- **Success Metrics**: Summary of imported items

#### 9.2 User Guidance
- **Progress Indicators**: Step-by-step import progress
- **Help Text**: Contextual guidance throughout process
- **Examples**: Sample data in templates
- **Recovery**: Ability to fix and retry failed imports

### 10. Performance Considerations

#### 10.1 File Size Management
- **Image Optimization**: Compress images during processing
- **Batch Processing**: Handle large imports efficiently
- **Memory Management**: Stream processing for large files
- **Progress Feedback**: Real-time progress updates

#### 10.2 Network Optimization
- **Image Downloads**: Parallel processing for URL-based images
- **Chunked Uploads**: Split large files for reliability
- **Error Recovery**: Retry mechanisms for failed operations

## Technical Implementation Notes

### 11. Excel Library Requirements
- **ExcelJS**: For advanced Excel features
- **Image Processing**: Built-in image embedding
- **Styling Support**: Rich formatting capabilities
- **Formula Support**: Excel formula generation

### 12. Browser Compatibility
- **Modern Browsers**: Chrome, Firefox, Safari, Edge
- **File API**: Drag and drop support
- **Memory Limits**: Handle browser limitations gracefully
- **Mobile Considerations**: Touch-friendly interfaces

## Success Criteria

### 13. User Experience Goals
- **Intuitive**: Non-technical users can use without training
- **Reliable**: Consistent results across different scenarios
- **Flexible**: Supports various content structures
- **Professional**: Output looks polished and branded

### 14. Technical Goals
- **Performance**: Import/export completes within reasonable time
- **Accuracy**: No data loss during round-trip operations
- **Scalability**: Handles cards with 100+ content items
- **Robustness**: Graceful handling of edge cases and errors