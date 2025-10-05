/**
 * Unified Excel Handler for CardStudio
 * Handles both import and export with embedded images using ExcelJS
 */

import ExcelJS from 'exceljs';
import { 
  EXCEL_CONFIG,
  styleTitle,
  styleHeader,
  styleInstruction,
  styleInstructions,
  getColumnLetter,
} from './excelConstants';

/**
 * Export card data to Excel with embedded images
 * @param {Object} cardData - Card information
 * @param {Array} contentItems - Content items array
 * @param {Object} options - Export options
 * @returns {Buffer} Excel file buffer
 */
export async function exportCardToExcel(cardData, contentItems = [], options = {}) {
  const workbook = new ExcelJS.Workbook();
  workbook.creator = 'CardStudio';
  workbook.created = new Date();
  
  // Create Card Information sheet
  await createCardSheet(workbook, cardData, options);
  
  // Create Content Items sheet with embedded images
  if (options.includeContent !== false && contentItems.length > 0) {
    await createContentSheet(workbook, contentItems);
  }
  
  return await workbook.xlsx.writeBuffer();
}

/**
 * Import Excel file and extract card data with images
 * @param {File} file - Excel file
 * @returns {Object} Parsed data with validation
 */
export async function importExcelToCardData(file) {
  const workbook = new ExcelJS.Workbook();
  const buffer = await file.arrayBuffer();
  await workbook.xlsx.load(buffer);
  
  const result = {
    isValid: true,
    errors: [],
    warnings: [],
    cardData: null,
    contentItems: [],
    images: new Map()
  };
  
  // Parse Card Information sheet
  const cardSheet = workbook.getWorksheet(EXCEL_CONFIG.CARD_SHEET.NAME);
  if (cardSheet) {
    result.cardData = await parseCardSheet(cardSheet, result);
  } else {
    result.errors.push('Missing "Card Information" sheet');
  }
  
  // Parse Content Items sheet
  const contentSheet = workbook.getWorksheet(EXCEL_CONFIG.CONTENT_SHEET.NAME);
  if (contentSheet) {
    const { contentItems, images } = await parseContentSheet(contentSheet, result);
    result.contentItems = contentItems;
    
    // Merge images from content sheet with any existing images from card sheet
    if (images && images.size > 0) {
      images.forEach((value, key) => {
        result.images.set(key, value);
      });
    }
  } else {
    result.errors.push('Missing "Content Items" sheet');
  }
  
  result.isValid = result.errors.length === 0;
  return result;
}

/**
 * Generate Excel template for import
 * @returns {Buffer} Excel template buffer
 */
export async function generateImportTemplate() {
  const workbook = new ExcelJS.Workbook();
  workbook.creator = 'CardStudio';
  workbook.created = new Date();
  
  // Create template card sheet
  await createTemplateCardSheet(workbook);
  
  // Create template content sheet
  await createTemplateContentSheet(workbook);
  
  return await workbook.xlsx.writeBuffer();
}

// ===========================================
// SHEET CREATION FUNCTIONS
// ===========================================

/**
 * Create Card Information sheet
 */
async function createCardSheet(workbook, cardData, options) {
  const worksheet = workbook.addWorksheet(EXCEL_CONFIG.CARD_SHEET.NAME);
  
  // Row 1: Branded title with icons
  const titleCell = worksheet.getCell('A1');
  titleCell.value = `${EXCEL_CONFIG.ICONS.CARD} CardStudio - Card Export Data`;
  styleTitle(titleCell);
  worksheet.mergeCells('A1:F1');
  worksheet.getRow(1).height = 30;
  
  // Row 2: Clear user instructions
  const instructionCell = worksheet.getCell('A2');
  instructionCell.value = `${EXCEL_CONFIG.ICONS.INSTRUCTIONS} Fill in your card details below. Required fields marked with *. Use dropdowns for validation.`;
  styleInstructions(instructionCell);
  worksheet.mergeCells('A2:F2');
  worksheet.getRow(2).height = 25;
  
  // Row 3: Headers with icons (same as template)
  const headers = EXCEL_CONFIG.COLUMNS.CARD.map(h => {
    if (h.includes('AI')) return `${EXCEL_CONFIG.ICONS.AI} ${h}*`;
    if (h.includes('Image')) return `${EXCEL_CONFIG.ICONS.IMAGE} ${h}`;
    if (h === 'Name') return `${h}*`;
    if (h.includes('Mode') || h.includes('Position')) return `${h}*`;
    return h;
  });
  const headerRow = worksheet.getRow(EXCEL_CONFIG.CARD_SHEET.HEADERS_ROW);
  headerRow.values = headers;
  headerRow.eachCell(cell => styleHeader(cell));
  headerRow.height = 25;
  
  // Row 4: Enhanced descriptions with examples (same as template)
  const descriptions = [
    'Enter card title (e.g., "Museum Experience")',
    'Brief description of card purpose',
    'AI instructions (e.g., "You are a helpful guide...")',
    'Select true/false from dropdown',
    'Select QR position: TL/TR/BL/BR',
    'Paste image or leave blank'
  ];
  const descriptionRow = worksheet.getRow(EXCEL_CONFIG.CARD_SHEET.DESCRIPTIONS_ROW);
  descriptionRow.values = descriptions;
  descriptionRow.eachCell(cell => styleInstruction(cell));
  descriptionRow.height = 25;
  
  // Row 5+: Actual data with validation
  const dataRow = worksheet.getRow(EXCEL_CONFIG.CARD_SHEET.DATA_START_ROW);
  dataRow.values = [
    cardData.name || '',
    cardData.description || '',
    cardData.ai_instruction || '',
    cardData.ai_knowledge_base || '',
    cardData.conversation_ai_enabled,
    cardData.qr_code_position || 'BR',
    '' // Placeholder for image
  ];
  
  // Apply text wrapping for all cells
  dataRow.eachCell((cell) => {
    cell.alignment = { wrapText: true, vertical: 'top', horizontal: 'left' };
    cell.border = {
      top: { style: 'thin', color: { argb: 'FFD1D5DB' } },
      bottom: { style: 'thin', color: { argb: 'FFD1D5DB' } },
      left: { style: 'thin', color: { argb: 'FFD1D5DB' } },
      right: { style: 'thin', color: { argb: 'FFD1D5DB' } }
    };
  });
  
  // No data validation for simplicity
  
  // Set row height to fit content with text wrapping
  const combinedContent = (cardData.description || '') + ' ' + (cardData.ai_instruction || '') + ' ' + (cardData.ai_knowledge_base || '');
  const cardDataHeight = calculateRowHeight(combinedContent, 80, 35);
  dataRow.height = cardDataHeight;
  
  // Embed card image with proper sizing
  if (cardData.image_url) {
    await embedImages(workbook, worksheet, [cardData.image_url], EXCEL_CONFIG.CARD_SHEET.DATA_START_ROW, 6);
  }
  
  // Professional column widths (same as template)
  worksheet.columns = [
    { width: 25 }, // Name
    { width: 40 }, // Description
    { width: 30 }, // AI Instruction
    { width: 45 }, // AI Knowledge Base
    { width: 15 }, // AI Enabled
    { width: 15 }, // QR Position
    { width: 25 }  // Card Image
  ];
  
  // Add helpful cell comments (same as template)
  dataRow.getCell(1).note = 'This will be the main title displayed on your card';
  dataRow.getCell(3).note = 'Define the AI\'s role, personality, and restrictions (max 100 words)';
  dataRow.getCell(4).note = 'Provide detailed background knowledge for the AI (max 2000 words)';
  dataRow.getCell(5).note = 'Enable voice conversations with visitors';
  dataRow.getCell(6).note = 'Where QR code appears on physical card';
  dataRow.getCell(7).note = 'Right-click and paste image, or drag and drop';
  
  // Freeze headers
  worksheet.views = [{ state: 'frozen', ySplit: EXCEL_CONFIG.CARD_SHEET.DESCRIPTIONS_ROW }];
  
  // No zebra striping or background colors for data rows
}

/**
 * Create Content Items sheet with embedded images
 */
async function createContentSheet(workbook, contentItems) {
  const worksheet = workbook.addWorksheet(EXCEL_CONFIG.CONTENT_SHEET.NAME);
  const layer1Items = contentItems.filter(item => !item.parent_id);
  const layer1ItemNames = layer1Items.map(item => item.name || 'Unnamed Item');
  
  // Row 1: Branded title with icons
  const titleCell = worksheet.getCell('A1');
  titleCell.value = `${EXCEL_CONFIG.ICONS.CONTENT} Content Items - Hierarchical Structure`;
  styleTitle(titleCell);
  worksheet.mergeCells(`A1:${getColumnLetter(EXCEL_CONFIG.COLUMNS.CONTENT.length)}1`);
  worksheet.getRow(1).height = 30;
  
  // Row 2: Clear instructions (same as template)
  const instructionCell = worksheet.getCell('A2');
  instructionCell.value = `${EXCEL_CONFIG.ICONS.INSTRUCTIONS} Create hierarchy: Layer 1 (main items) → Layer 2 (sub-items). Parent references use cell format (A5, A8, etc.)`;
  styleInstructions(instructionCell);
  worksheet.mergeCells(`A2:${getColumnLetter(EXCEL_CONFIG.COLUMNS.CONTENT.length)}2`);
  worksheet.getRow(2).height = 25;
  
  // Row 3: Headers with icons (same as template)
  const headers = EXCEL_CONFIG.COLUMNS.CONTENT.map(h => {
    if (h.includes('AI')) return `${EXCEL_CONFIG.ICONS.AI} ${h}`;
    if (h.includes('Image')) return `${EXCEL_CONFIG.ICONS.IMAGE} ${h}`;
    if (h.includes('Layer')) return `${EXCEL_CONFIG.ICONS.LAYER} ${h}*`;
    if (h === 'Name') return `${h}*`;
    return h;
  });
  const headerRow = worksheet.getRow(EXCEL_CONFIG.CONTENT_SHEET.HEADERS_ROW);
  headerRow.values = headers;
  headerRow.eachCell(cell => styleHeader(cell));
  headerRow.height = 25;
  
  // Row 4: Descriptions (same as template)
  const descriptions = [
    'Descriptive title for exhibit/artifact',
    'Main content text visitors will see',
    'AI context keywords (history, art, science)',
    'Auto-generated from row order',
    'Layer 1 = Main items, Layer 2 = Sub-items',
    'Cell reference for parent (e.g., A5)',
    'Paste image or provide URL'
  ];
  const descriptionRow = worksheet.getRow(EXCEL_CONFIG.CONTENT_SHEET.DESCRIPTIONS_ROW);
  descriptionRow.values = descriptions;
  descriptionRow.eachCell(cell => styleInstruction(cell));
  descriptionRow.height = 25;
  
  // Row 5+: Content items with smart features
  for (let i = 0; i < contentItems.length; i++) {
    const item = contentItems[i];
    const rowNum = EXCEL_CONFIG.CONTENT_SHEET.DATA_START_ROW + i;
    const row = worksheet.getRow(rowNum);
    
    const layer = item.parent_id ? 'Layer 2' : 'Layer 1';
    let parentReference = '';
    
    if (item.parent_id) {
      const parentItem = contentItems.find(p => p.id === item.parent_id);
      if (parentItem) {
        const parentIndex = contentItems.indexOf(parentItem);
        const parentRowNum = EXCEL_CONFIG.CONTENT_SHEET.DATA_START_ROW + parentIndex;
        parentReference = `A${parentRowNum}`; // Excel cell reference format
      }
    }
    
    row.values = [
      item.name || '',
      item.content || '',
      item.ai_metadata || '',
      item.sort_order || i + 1,
      layer,
      parentReference,
      '' // Placeholder for image
    ];
    
    // Apply text wrapping for all cells
    row.eachCell((cell) => {
      cell.alignment = { wrapText: true, vertical: 'top', horizontal: 'left' };
      cell.border = {
        top: { style: 'thin', color: { argb: 'FFD1D5DB' } },
        bottom: { style: 'thin', color: { argb: 'FFD1D5DB' } },
        left: { style: 'thin', color: { argb: 'FFD1D5DB' } },
        right: { style: 'thin', color: { argb: 'FFD1D5DB' } }
      };
    });
    
    // No data validation for simplicity
    
    // Set row height to fit content with text wrapping
    const contentHeight = calculateRowHeight(item.content || '', 50, 30);
    row.height = contentHeight;
    
    // Embed images with proper sizing
    if (item.image_url) {
      await embedImages(workbook, worksheet, [item.image_url], rowNum, 7);
    }
    
    // Add helpful comments for guidance (same as template)
    if (i === 0) {
      row.getCell(1).note = 'Give each content item a clear, descriptive name';
      row.getCell(3).note = 'Provide content-specific knowledge for AI assistance (max 500 words)';
      row.getCell(5).note = 'Layer 1 = Main categories, Layer 2 = Items within categories';
      row.getCell(6).note = 'For Layer 2 items, enter the Excel cell reference of the parent item';
    }
  }
  
  // No conditional formatting or zebra striping for data rows
  
  // Professional column widths (same as template)
  worksheet.columns = [
    { width: 30 }, // Name
    { width: 50 }, // Content
    { width: 35 }, // AI Metadata
    { width: 12 }, // Sort Order
    { width: 12 }, // Layer
    { width: 18 }, // Parent Reference
    { width: 25 }  // Image
  ];
  
  // No summary section for consistency with template
  
  // Freeze headers
  worksheet.views = [{ state: 'frozen', ySplit: EXCEL_CONFIG.CONTENT_SHEET.DESCRIPTIONS_ROW }];
}

// ===========================================
// TEMPLATE CREATION FUNCTIONS
// ===========================================

/**
 * Create template Card Information sheet
 */
async function createTemplateCardSheet(workbook) {
  const worksheet = workbook.addWorksheet(EXCEL_CONFIG.CARD_SHEET.NAME);
  
  // Row 1: Branded title with icons
  const titleCell = worksheet.getCell('A1');
  titleCell.value = `${EXCEL_CONFIG.ICONS.CARD} CardStudio - Card Import Template`;
  styleTitle(titleCell);
  worksheet.mergeCells('A1:F1');
  worksheet.getRow(1).height = 30;
  
  // Row 2: Clear user instructions
  const instructionCell = worksheet.getCell('A2');
  instructionCell.value = `${EXCEL_CONFIG.ICONS.INSTRUCTIONS} Fill in your card details below. Required fields marked with *. Use dropdowns for validation.`;
  styleInstructions(instructionCell);
  worksheet.mergeCells('A2:F2');
  worksheet.getRow(2).height = 25;
  
  // Row 3: Headers with icons
  const headers = EXCEL_CONFIG.COLUMNS.CARD.map(h => {
    if (h.includes('AI')) return `${EXCEL_CONFIG.ICONS.AI} ${h}*`;
    if (h.includes('Image')) return `${EXCEL_CONFIG.ICONS.IMAGE} ${h}`;
    if (h === 'Name') return `${h}*`;
    if (h.includes('Mode') || h.includes('Position')) return `${h}*`;
    return h;
  });
  const headerRow = worksheet.getRow(EXCEL_CONFIG.CARD_SHEET.HEADERS_ROW);
  headerRow.values = headers;
  headerRow.eachCell(cell => styleHeader(cell));
  headerRow.height = 25;
  
  // Row 4: Enhanced descriptions with examples
  const descriptions = [
    'Enter card title (e.g., "Museum Experience")',
    'Brief description of card purpose',
    'AI instructions (e.g., "You are a helpful guide...")',
    'Select true/false from dropdown',
    'Select QR position: TL/TR/BL/BR',
    'Paste image or leave blank'
  ];
  const descriptionRow = worksheet.getRow(EXCEL_CONFIG.CARD_SHEET.DESCRIPTIONS_ROW);
  descriptionRow.values = descriptions;
  descriptionRow.eachCell(cell => styleInstruction(cell));
  descriptionRow.height = 25;
  
  // Row 5: Empty data row for import
  const emptyData = [
    '', // Name
    '', // Description
    '', // AI Instruction
    '', // AI Knowledge Base
    '', // AI Enabled
    '', // QR Position
    ''  // Card Image
  ];
  
  const dataRow = worksheet.getRow(EXCEL_CONFIG.CARD_SHEET.DATA_START_ROW);
  dataRow.values = emptyData;
  
  // Apply text wrapping for all cells
  dataRow.eachCell((cell) => {
    cell.alignment = { wrapText: true, vertical: 'top', horizontal: 'left' };
    cell.border = {
      top: { style: 'thin', color: { argb: 'FFD1D5DB' } },
      bottom: { style: 'thin', color: { argb: 'FFD1D5DB' } },
      left: { style: 'thin', color: { argb: 'FFD1D5DB' } },
      right: { style: 'thin', color: { argb: 'FFD1D5DB' } }
    };
  });
  
  // No data validation for simplicity
  
  // Add helpful cell comments
  dataRow.getCell(1).note = 'This will be the main title displayed on your card';
  dataRow.getCell(3).note = 'Define the AI\'s role, personality, and restrictions (max 100 words)';
  dataRow.getCell(4).note = 'Provide detailed background knowledge for the AI (max 2000 words)';
  dataRow.getCell(5).note = 'Enable voice conversations with visitors';
  dataRow.getCell(6).note = 'Where QR code appears on physical card';
  dataRow.getCell(7).note = 'Right-click and paste image, or drag and drop';
  
  dataRow.height = 35; // Larger row for better readability
  
  // Professional column sizing
  worksheet.columns = [
    { width: 25 }, // Name
    { width: 40 }, // Description
    { width: 30 }, // AI Instruction
    { width: 45 }, // AI Knowledge Base
    { width: 15 }, // AI Enabled
    { width: 15 }, // QR Position
    { width: 25 }  // Card Image
  ];
  
  // Freeze headers for easy navigation
  worksheet.views = [{ state: 'frozen', ySplit: EXCEL_CONFIG.CARD_SHEET.DESCRIPTIONS_ROW }];
}

/**
 * Create template Content Items sheet
 */
async function createTemplateContentSheet(workbook) {
  const worksheet = workbook.addWorksheet(EXCEL_CONFIG.CONTENT_SHEET.NAME);
  
  // Row 1: Professional branded title
  const titleCell = worksheet.getCell('A1');
  titleCell.value = `${EXCEL_CONFIG.ICONS.CONTENT} Content Items - Import Template`;
  styleTitle(titleCell);
  worksheet.mergeCells(`A1:${getColumnLetter(EXCEL_CONFIG.COLUMNS.CONTENT.length)}1`);
  worksheet.getRow(1).height = 30;
  
  // Row 2: Clear guidance (same as export)
  const instructionCell = worksheet.getCell('A2');
  instructionCell.value = `${EXCEL_CONFIG.ICONS.INSTRUCTIONS} Create hierarchy: Layer 1 (main items) → Layer 2 (sub-items). Parent references use cell format (A5, A8, etc.)`;
  styleInstructions(instructionCell);
  worksheet.mergeCells(`A2:${getColumnLetter(EXCEL_CONFIG.COLUMNS.CONTENT.length)}2`);
  worksheet.getRow(2).height = 25;
  
  // Row 3: Professional headers with icons (same as export)
  const headers = EXCEL_CONFIG.COLUMNS.CONTENT.map(h => {
    if (h.includes('AI')) return `${EXCEL_CONFIG.ICONS.AI} ${h}`;
    if (h.includes('Image')) return `${EXCEL_CONFIG.ICONS.IMAGE} ${h}`;
    if (h.includes('Layer')) return `${EXCEL_CONFIG.ICONS.LAYER} ${h}*`;
    if (h === 'Name') return `${h}*`;
    return h;
  });
  const headerRow = worksheet.getRow(EXCEL_CONFIG.CONTENT_SHEET.HEADERS_ROW);
  headerRow.values = headers;
  headerRow.eachCell(cell => styleHeader(cell));
  headerRow.height = 25;
  
  // Row 4: Detailed guidance (same as export)
  const descriptions = [
    'Descriptive title for exhibit/artifact',
    'Main content text visitors will see',
    'AI context keywords (history, art, science)',
    'Auto-generated from row order',
    'Layer 1 = Main items, Layer 2 = Sub-items',
    'Cell reference for parent (e.g., A5)',
    'Paste image or provide URL'
  ];
  const descriptionRow = worksheet.getRow(EXCEL_CONFIG.CONTENT_SHEET.DESCRIPTIONS_ROW);
  descriptionRow.values = descriptions;
  descriptionRow.eachCell(cell => styleInstruction(cell));
  descriptionRow.height = 25;
  
  // Row 5+: Create empty rows for import template
  const emptyRowsCount = 10; // Provide 10 empty rows for user input
  
  for (let i = 0; i < emptyRowsCount; i++) {
    const rowNum = EXCEL_CONFIG.CONTENT_SHEET.DATA_START_ROW + i;
    const row = worksheet.getRow(rowNum);
    
    // Empty data row
    row.values = ['', '', '', '', '', '', ''];
    
    // Apply text wrapping for all cells
    row.eachCell((cell) => {
      cell.alignment = { wrapText: true, vertical: 'top', horizontal: 'left' };
      cell.border = {
        top: { style: 'thin', color: { argb: 'FFD1D5DB' } },
        bottom: { style: 'thin', color: { argb: 'FFD1D5DB' } },
        left: { style: 'thin', color: { argb: 'FFD1D5DB' } },
        right: { style: 'thin', color: { argb: 'FFD1D5DB' } }
      };
    });
    
    // No data validation for simplicity
    
    // Set row height to fit content with text wrapping (expandable for user input)
    row.height = 40; // Slightly larger for user input
    
    // Add helpful comments for first row
    if (i === 0) {
      row.getCell(1).note = 'Give each content item a clear, descriptive name';
      row.getCell(3).note = 'Provide content-specific knowledge for AI assistance (max 500 words)';
      row.getCell(5).note = 'Layer 1 = Main categories, Layer 2 = Items within categories';
      row.getCell(6).note = 'For Layer 2 items, enter the Excel cell reference of the parent item';
    }
  }
  
  // Optimized column widths for professional appearance (same as export)
  worksheet.columns = [
    { width: 30 }, // Name
    { width: 50 }, // Content
    { width: 35 }, // AI Metadata
    { width: 12 }, // Sort Order
    { width: 12 }, // Layer
    { width: 18 }, // Parent Reference
    { width: 25 }  // Image
  ];
  
  // Freeze headers for easy navigation
  worksheet.views = [{ state: 'frozen', ySplit: EXCEL_CONFIG.CONTENT_SHEET.DESCRIPTIONS_ROW }];
}

// ===========================================
// PARSING FUNCTIONS
// ===========================================

/**
 * Parse Card Information sheet
 */
async function parseCardSheet(worksheet, result) {
  const cardData = {};
  
  try {
    // Use the new structure: Row 3 = Headers, Row 5 = Data
    const headerRow = worksheet.getRow(EXCEL_CONFIG.CARD_SHEET.HEADERS_ROW).values;
    const dataRow = worksheet.getRow(EXCEL_CONFIG.CARD_SHEET.DATA_START_ROW).values;
    
    // Read field-value pairs using the exact column structure
    const expectedHeaders = EXCEL_CONFIG.COLUMNS.CARD;
    
    for (let i = 0; i < expectedHeaders.length; i++) {
      const header = expectedHeaders[i];
      const value = dataRow[i + 1] || ''; // Excel is 1-indexed
      
      if (!value) continue;
      
      // Clean header for mapping (remove icons and asterisks)
      const cleanHeader = header.replace(/[\u{1F000}-\u{1F9FF}]/gu, '').replace(/[*]/g, '').trim();
      
      const fieldMapping = {
        'Name': 'name',
        'Description': 'description',
        'AI Instruction': 'ai_instruction',
        'AI Knowledge Base': 'ai_knowledge_base',
        'AI Enabled': 'conversation_ai_enabled',
        'QR Position': 'qr_code_position'
      };
      
      const dbField = fieldMapping[cleanHeader];
      if (dbField) {
        let processedValue = value;
        
        // Handle rich text values
        if (value.richText) {
          processedValue = value.richText[0].text;
        } else if (typeof value === 'object' && value.toString) {
          processedValue = value.toString();
        }
        
        // Convert boolean fields
        if (dbField === 'conversation_ai_enabled') {
          cardData[dbField] = ['true', 'yes', '1', true].includes(processedValue.toString().toLowerCase());
        } else if (dbField === 'qr_code_position') {
          // Validate QR code position
          const validPositions = ['TL', 'TR', 'BL', 'BR'];
          const upperValue = processedValue.toString().toUpperCase();
          if (validPositions.includes(upperValue)) {
            cardData[dbField] = upperValue;
          } else {
            console.warn(`Invalid QR position '${processedValue}', defaulting to 'BR'`);
            cardData[dbField] = 'BR';
            result.warnings.push(`Invalid QR Position '${processedValue}' - using default 'BR' (Bottom Right). Valid options: TL, TR, BL, BR`);
          }
        } else {
          cardData[dbField] = processedValue;
        }
      }
    }
    
    // Extract card image if embedded
    const cardImageRow = EXCEL_CONFIG.CARD_SHEET.DATA_START_ROW;
    const cardImageCol = 7; // Column G (Card Image)
    const extractedImages = await extractImagesFromRow(worksheet, cardImageRow, cardImageCol);
    if (extractedImages.length > 0) {
      result.images = result.images || new Map();
      result.images.set('card_image', extractedImages);
    }
    
  } catch (error) {
    result.errors.push(`Error parsing card data: ${error.message}`);
  }
  
  return cardData;
}

/**
 * Parse Content Items sheet with embedded images
 */
async function parseContentSheet(worksheet, result) {
  const contentItems = [];
  const images = new Map();
  
  // Use the exact column structure from EXCEL_CONFIG
  const expectedHeaders = EXCEL_CONFIG.COLUMNS.CONTENT;
  const colMap = {
    name: 1,           // Column A
    content: 2,        // Column B
    ai_metadata: 3,    // Column C
    sort_order: 4,     // Column D
    layer: 5,          // Column E
    parent_reference: 6, // Column F
    image: 7           // Column G
  };

  try {
    let currentRowNum = EXCEL_CONFIG.CONTENT_SHEET.DATA_START_ROW;
    
    while (true) {
      const nameCell = worksheet.getCell(currentRowNum, colMap.name);
      if (!nameCell.value) break;
      
      const layerValue = worksheet.getCell(currentRowNum, colMap.layer).value?.toString() || 'Layer 1';
      const parentRefValue = worksheet.getCell(currentRowNum, colMap.parent_reference).value?.toString() || '';
      
      const item = {
        name: nameCell.value.toString(),
        content: worksheet.getCell(currentRowNum, colMap.content).value?.toString() || '',
        ai_metadata: worksheet.getCell(currentRowNum, colMap.ai_metadata).value?.toString() || '',
        sort_order: worksheet.getCell(currentRowNum, colMap.sort_order).value || (currentRowNum - EXCEL_CONFIG.CONTENT_SHEET.DATA_START_ROW) + 1,
        layer: layerValue,
        parent_reference: parentRefValue,
        image_url: worksheet.getCell(currentRowNum, colMap.image).value?.toString() || ''
      };
      
      // Convert parent reference from cell format (A6) to parent name
      let parentName = '';
      if (item.layer === 'Layer 2' && parentRefValue) {
        // Parse cell reference like "A6" to find parent item
        const cellMatch = parentRefValue.match(/^([A-Z]+)(\d+)$/i);
        if (cellMatch) {
          const parentRowNum = parseInt(cellMatch[2]);
          const parentCell = worksheet.getCell(parentRowNum, colMap.name);
          if (parentCell.value) {
            parentName = parentCell.value.toString();
          }
        } else {
          // If not cell reference format, treat as direct parent name
          parentName = parentRefValue;
        }
      }
      
      item.parent_item = parentName;
      
      // Extract embedded images
      const extractedImages = await extractImagesFromRow(worksheet, currentRowNum, colMap.image);
      if (extractedImages.length > 0) {
        images.set(`item_${currentRowNum}`, extractedImages);
        item.has_images = true;
        item.image_count = extractedImages.length;
      }
      
      // Validate parent reference
      if (item.layer === 'Layer 2' && !item.parent_item) {
        result.warnings.push(`Layer 2 item "${item.name}" is missing a parent reference.`);
      }
      
      contentItems.push(item);
      currentRowNum++;
    }
    
  } catch (error) {
    result.errors.push(`Error parsing content items: ${error.message}`);
  }
  
  return { contentItems, images };
}

// ===========================================
// IMAGE HANDLING FUNCTIONS
// ===========================================

/**
 * Embed images in Excel worksheet
 */
async function embedImages(workbook, worksheet, imageUrls, rowNum, colNum) {
  if (!imageUrls || imageUrls.length === 0) return;
  
  for (let i = 0; i < imageUrls.length; i++) {
      const imageUrl = imageUrls[i];
    try {
      console.log(`Processing image: ${imageUrl}`);
      
      // Handle both external URLs and relative paths
      let response;
      if (imageUrl.startsWith('http')) {
        response = await fetch(imageUrl, {
          mode: 'cors',
          headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
          }
        });
      } else {
        // For relative paths, construct full URL
        const baseUrl = window.location.origin;
        response = await fetch(`${baseUrl}${imageUrl}`);
      }
      
      if (!response.ok) {
        console.warn(`Failed to fetch image: ${imageUrl} - Status: ${response.status}`);
        continue;
      }
      
      const arrayBuffer = await response.arrayBuffer();
      console.log(`Image downloaded successfully: ${imageUrl}, size: ${arrayBuffer.byteLength} bytes`);
      
      // Determine image extension from URL or content type
      const contentType = response.headers.get('content-type') || '';
      let extension = 'png';
      if (contentType.includes('jpeg') || contentType.includes('jpg') || imageUrl.match(/\.jpe?g$/i)) {
        extension = 'jpeg';
      } else if (contentType.includes('png') || imageUrl.match(/\.png$/i)) {
        extension = 'png';
      } else if (contentType.includes('gif') || imageUrl.match(/\.gif$/i)) {
        extension = 'gif';
      }
      
      // Add image to workbook
      const imageId = workbook.addImage({
        buffer: arrayBuffer,
        extension: extension,
      });
      
      console.log(`Image added to workbook with ID: ${imageId}`);
      
      // Calculate position with offset for multiple images
      const colOffset = i * 1.2; // Horizontal offset for multiple images
      
      // Add image to worksheet with standardized size
      worksheet.addImage(imageId, {
        tl: { col: colNum - 1 + colOffset, row: rowNum - 1 },
        ext: { width: 120, height: 90 } // Standardized aspect ratio
      });
      
      console.log(`Image embedded at position: col ${colNum - 1 + colOffset}, row ${rowNum - 1}`);
      
      // Add placeholder text if this is the image cell
      const imageCell = worksheet.getCell(rowNum, colNum);
      if (!imageCell.value) {
        imageCell.value = `${EXCEL_CONFIG.ICONS.IMAGE} Image embedded`;
        imageCell.font = { color: { argb: 'FF6B7280' }, italic: true };
        imageCell.alignment = { horizontal: 'center', vertical: 'middle' };
      }
      
    } catch (error) {
      console.error(`Error embedding image ${i + 1} from ${imageUrl}:`, error);
      // Add error text in cell with styling
      const imageCell = worksheet.getCell(rowNum, colNum + i);
      imageCell.value = `[Image Error: ${error.message}]`;
      imageCell.font = { color: { argb: EXCEL_CONFIG.COLORS.REQUIRED }, italic: true };
      imageCell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: EXCEL_CONFIG.COLORS.VALIDATION_ERROR } };
    }
  }
}

/**
 * Extract embedded images from worksheet row
 */
async function extractImagesFromRow(worksheet, rowNum, colNum) {
  const images = [];
  
  try {
    // Get all images in the worksheet
    const worksheetImages = worksheet.getImages();
    
    worksheetImages.forEach((image) => {
      const range = image.range;
      
      // Check if image is in the target cell area
      const imageRow = range.tl.row + 1; // Convert to 1-based
      const imageCol = range.tl.col + 1;
      
      if (Math.abs(imageRow - rowNum) < 1 && Math.abs(imageCol - colNum) < 3) {
        // This image is in our target cell area
        const workbook = worksheet.workbook;
        const imageData = workbook.getImage(image.imageId);
        
        images.push({
          buffer: imageData.buffer,
          extension: imageData.extension,
          filename: `image_${rowNum}_${images.length + 1}.${imageData.extension}`
        });
      }
    });
    
  } catch (error) {
    console.warn('Error extracting images from row:', error);
  }
  
  return images;
}

// ===========================================
// STYLING FUNCTIONS
// ===========================================

// Functions styleTitle, styleHeader, styleInstruction, applyZebraStriping were moved to excelConstants.js

// ===========================================
// UTILITY FUNCTIONS
// ===========================================

/**
 * Calculate appropriate row height based on content length
 * @param {string} content - Text content
 * @param {number} columnWidth - Column width in characters
 * @param {number} minHeight - Minimum row height
 * @returns {number} Calculated row height
 */
function calculateRowHeight(content, columnWidth = 50, minHeight = 30) {
  if (!content) return minHeight;
  
  // Estimate lines based on content length and column width
  const estimatedLines = Math.ceil(content.length / columnWidth);
  
  // Calculate height (base + line height * number of lines)
  const calculatedHeight = Math.max(minHeight, 20 + (estimatedLines * 15));
  
  // Cap at reasonable maximum
  return Math.min(calculatedHeight, 150);
}

/**
 * Convert column number to Excel letter
 */
// Functions getColumnLetter, getColumnNumber were moved to excelConstants.js

export default {
  exportCardToExcel,
  importExcelToCardData,
  generateImportTemplate
};