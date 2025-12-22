/**
 * Unified Excel Handler for FunTell
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
 * Sanitize string to remove invalid XML characters
 * @param {string} str - Input string
 * @returns {string} Sanitized string
 */
function sanitizeString(str) {
  if (typeof str !== 'string') return str;
  // Remove control characters (ASCII 0-31) except newline (10), carriage return (13), and tab (9)
  // Also remove delete (127)
  let clean = str.replace(/[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]/g, '');
  
  // Truncate to safe Excel limit (32767 chars)
  // We use 32000 to be safe
  if (clean.length > 32000) {
    clean = clean.substring(0, 32000);
  }
  
  return clean;
}

/**
 * Export card data to Excel with embedded images
 * @param {Object} cardData - Card information
 * @param {Array} contentItems - Content items array
 * @param {Object} options - Export options
 * @returns {Buffer} Excel file buffer
 */
export async function exportCardToExcel(cardData, contentItems = [], options = {}) {
  const workbook = new ExcelJS.Workbook();
  workbook.creator = 'FunTell';
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
 * Export multiple cards to Excel
 * @param {Array} cardsData - Array of { card, contentItems }
 * @param {Object} options - Export options
 * @param {boolean} options.singleFile - If true, export all cards to one file; if false, separate files
 * @param {string} options.filename - Base filename
 */
export async function exportCardsToExcel(cardsData, options = {}) {
  const { singleFile = true, filename = 'cards_export.xlsx' } = options;
  
  if (singleFile) {
    // Export all cards to a single file
    await exportMultipleCardsToSingleFile(cardsData, filename);
  } else {
    // Export each card as a separate file
    await exportCardsToSeparateFiles(cardsData);
  }
}

/**
 * Export multiple cards to a single Excel file
 * Uses indexed sheets: "Card 1", "Content 1", "Card 2", "Content 2", etc.
 */
async function exportMultipleCardsToSingleFile(cardsData, filename) {
  const workbook = new ExcelJS.Workbook();
  workbook.creator = 'FunTell';
  workbook.created = new Date();
  
  // Create index/summary sheet
  const indexSheet = workbook.addWorksheet('Index');
  indexSheet.columns = [
    { header: '#', key: 'index', width: 5 },
    { header: 'Card Name', key: 'name', width: 30 },
    { header: 'Description', key: 'description', width: 40 },
    { header: 'Content Mode', key: 'content_mode', width: 15 },
    { header: 'Billing Type', key: 'billing_type', width: 15 },
    { header: 'Content Items', key: 'item_count', width: 15 },
    { header: 'Card Sheet', key: 'card_sheet', width: 15 },
    { header: 'Content Sheet', key: 'content_sheet', width: 15 }
  ];
  
  // Style header row
  indexSheet.getRow(1).font = { bold: true, color: { argb: 'FFFFFFFF' } };
  indexSheet.getRow(1).fill = {
    type: 'pattern',
    pattern: 'solid',
    fgColor: { argb: 'FF4472C4' }
  };
  
  // Add each card
  for (let i = 0; i < cardsData.length; i++) {
    const { card, contentItems } = cardsData[i];
    const cardIndex = i + 1;
    const cardSheetName = `Card ${cardIndex}`;
    const contentSheetName = `Content ${cardIndex}`;
    
    // Add to index
    indexSheet.addRow({
      index: cardIndex,
      name: card.name || '',
      description: (card.description || '').substring(0, 50),
      content_mode: card.content_mode || 'list',
      billing_type: card.billing_type || 'physical',
      item_count: contentItems?.length || 0,
      card_sheet: cardSheetName,
      content_sheet: contentItems?.length > 0 ? contentSheetName : 'N/A'
    });
    
    // Create card sheet
    await createCardSheet(workbook, card, { sheetName: cardSheetName });
    
    // Create content sheet if has content
    if (contentItems && contentItems.length > 0) {
      await createContentSheet(workbook, contentItems, { sheetName: contentSheetName });
    }
  }
  
  // Download the file
  const buffer = await workbook.xlsx.writeBuffer();
  downloadExcelFile(buffer, filename);
}

/**
 * Export each card as a separate file
 */
async function exportCardsToSeparateFiles(cardsData) {
  for (let i = 0; i < cardsData.length; i++) {
    const { card, contentItems } = cardsData[i];
    
    // Generate filename based on card name
    const safeName = (card.name || 'card').replace(/[^a-zA-Z0-9]/g, '_').substring(0, 30);
    const filename = `${safeName}_${new Date().toISOString().split('T')[0]}.xlsx`;
    
    // Use the standard single-card export (with proper sheet names for re-import)
    const buffer = await exportCardToExcel(card, contentItems || []);
    downloadExcelFile(buffer, filename);
    
    // Small delay between downloads to prevent browser blocking
    if (i < cardsData.length - 1) {
      await new Promise(resolve => setTimeout(resolve, 500));
    }
  }
}

/**
 * Helper to download Excel buffer as file
 */
function downloadExcelFile(buffer, filename) {
  const blob = new Blob([buffer], { type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' });
  const url = URL.createObjectURL(blob);
  const link = document.createElement('a');
  link.href = url;
  link.download = filename;
  link.click();
  URL.revokeObjectURL(url);
}

/**
 * Import Excel file(s) and extract card data with images
 * Supports: single card file, multi-card file, or array of files
 * @param {File|File[]} files - Excel file(s)
 * @returns {Object} Parsed data with validation
 */
export async function importExcelToCardData(files) {
  // Handle array of files
  const fileArray = Array.isArray(files) ? files : [files];
  
  // If multiple files, process each and combine results
  if (fileArray.length > 1) {
    return await importMultipleFiles(fileArray);
  }
  
  // Single file - check if it contains multiple cards
  const file = fileArray[0];
  const workbook = new ExcelJS.Workbook();
  const buffer = await file.arrayBuffer();
  await workbook.xlsx.load(buffer);
  
  // Check for multi-card format (has "Index" sheet or "Card 1" sheet)
  const indexSheet = workbook.getWorksheet('Index');
  const card1Sheet = workbook.getWorksheet('Card 1');
  
  if (indexSheet || card1Sheet) {
    return await parseMultiCardWorkbook(workbook);
  }
  
  // Standard single-card format
  const result = {
    isValid: true,
    errors: [],
    warnings: [],
    cards: [], // Array of { cardData, contentItems, images }
    cardData: null, // Backward compatibility
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
  
  // Add to cards array for consistency with multi-card format
  if (result.cardData) {
    result.cards.push({
      cardData: result.cardData,
      contentItems: result.contentItems,
      images: result.images
    });
  }
  
  return result;
}

/**
 * Import multiple Excel files
 * @param {File[]} files - Array of Excel files
 * @returns {Object} Combined parsed data
 */
async function importMultipleFiles(files) {
  const combinedResult = {
    isValid: true,
    errors: [],
    warnings: [],
    cards: [],
    cardData: null,
    contentItems: [],
    images: new Map()
  };
  
  for (let i = 0; i < files.length; i++) {
    const file = files[i];
    try {
      const fileResult = await importExcelToCardData(file);
      
      // Add all cards from this file
      if (fileResult.cards && fileResult.cards.length > 0) {
        combinedResult.cards.push(...fileResult.cards);
      }
      
      // Collect errors/warnings with file context
      fileResult.errors.forEach(err => {
        combinedResult.errors.push(`[${file.name}] ${err}`);
      });
      fileResult.warnings.forEach(warn => {
        combinedResult.warnings.push(`[${file.name}] ${warn}`);
      });
    } catch (error) {
      combinedResult.errors.push(`[${file.name}] Failed to parse: ${error.message}`);
    }
  }
  
  // Set backward compatibility fields from first card
  if (combinedResult.cards.length > 0) {
    combinedResult.cardData = combinedResult.cards[0].cardData;
    combinedResult.contentItems = combinedResult.cards[0].contentItems;
    combinedResult.images = combinedResult.cards[0].images;
  }
  
  combinedResult.isValid = combinedResult.errors.length === 0;
  return combinedResult;
}

/**
 * Parse a workbook with multiple cards (Card 1, Card 2, etc.)
 * @param {ExcelJS.Workbook} workbook
 * @returns {Object} Parsed data with multiple cards
 */
async function parseMultiCardWorkbook(workbook) {
  const result = {
    isValid: true,
    errors: [],
    warnings: [],
    cards: [],
    cardData: null,
    contentItems: [],
    images: new Map()
  };
  
  // Find all card sheets (Card 1, Card 2, etc.)
  let cardIndex = 1;
  while (true) {
    const cardSheet = workbook.getWorksheet(`Card ${cardIndex}`);
    if (!cardSheet) break;
    
    const cardResult = {
      errors: [],
      warnings: [],
      images: new Map()
    };
    
    // Parse card sheet
    const cardData = await parseCardSheet(cardSheet, cardResult);
    
    // Parse corresponding content sheet
    let contentItems = [];
    const contentSheet = workbook.getWorksheet(`Content ${cardIndex}`);
    if (contentSheet) {
      const contentResult = await parseContentSheet(contentSheet, cardResult);
      contentItems = contentResult.contentItems || [];
      
      // Merge images
      if (contentResult.images) {
        contentResult.images.forEach((value, key) => {
          cardResult.images.set(key, value);
        });
      }
    }
    
    // Add to cards array
    result.cards.push({
      cardData,
      contentItems,
      images: cardResult.images
    });
    
    // Collect errors/warnings with card context
    cardResult.errors.forEach(err => {
      result.errors.push(`[Card ${cardIndex}] ${err}`);
    });
    cardResult.warnings.forEach(warn => {
      result.warnings.push(`[Card ${cardIndex}] ${warn}`);
    });
    
    cardIndex++;
  }
  
  if (result.cards.length === 0) {
    result.errors.push('No valid cards found in workbook');
  }
  
  // Set backward compatibility fields from first card
  if (result.cards.length > 0) {
    result.cardData = result.cards[0].cardData;
    result.contentItems = result.cards[0].contentItems;
    result.images = result.cards[0].images;
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
  workbook.creator = 'FunTell';
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
async function createCardSheet(workbook, cardData, options = {}) {
  const sheetName = options.sheetName || EXCEL_CONFIG.CARD_SHEET.NAME;
  const worksheet = workbook.addWorksheet(sheetName);
  
  // Row 1: Branded title with icons (span to column S = 19 columns)
  const titleCell = worksheet.getCell('A1');
  titleCell.value = `${EXCEL_CONFIG.ICONS.CARD} FunTell - Card Export Data`;
  styleTitle(titleCell);
  worksheet.mergeCells('A1:S1');
  worksheet.getRow(1).height = 30;
  
  // Row 2: Clear user instructions (span to column S = 19 columns)
  const instructionCell = worksheet.getCell('A2');
  instructionCell.value = `${EXCEL_CONFIG.ICONS.INSTRUCTIONS} Fill in your experience details below. Required fields marked with *. Use dropdowns for validation.`;
  styleInstructions(instructionCell);
  worksheet.mergeCells('A2:S2');
  worksheet.getRow(2).height = 25;
  
  // Row 3: Headers with icons (same as template)
  const headers = EXCEL_CONFIG.COLUMNS.CARD.map(h => {
    if (h.includes('AI')) return `${EXCEL_CONFIG.ICONS.AI} ${h}*`;
    if (h.includes('Image')) return `${EXCEL_CONFIG.ICONS.IMAGE} ${h}`;
    if (h === 'Name') return `${h}*`;
    if (h.includes('Mode') || h.includes('Position') || h.includes('Language')) return `${h}*`;
    return h;
  });
  const headerRow = worksheet.getRow(EXCEL_CONFIG.CARD_SHEET.HEADERS_ROW);
  headerRow.values = headers;
  headerRow.eachCell(cell => styleHeader(cell));
  headerRow.height = 25;
  
  // Row 4: Enhanced descriptions with examples (same as template)
  // IMPORTANT: Keep in sync with EXCEL_CONFIG.COLUMNS.CARD (19 columns)
  const descriptions = [
    'Enter card title (e.g., "Museum Experience")',
    'Brief description of card purpose',
    'AI instructions (e.g., "You are a helpful guide...")',
    'Background knowledge for AI conversations',
    'Welcome message for general assistant',
    'Welcome message for item assistant ({name} placeholder)',
    'Original content language (en, zh-Hant, etc.)',
    'Select true/false from dropdown',
    'Select QR position: TL/TR/BL/BR',
    'Content mode: single/list/grid/cards',
    'Group content into categories (true/false)',
    'Group display: expanded/collapsed',
    'Access mode: physical/digital',
    'Total scan limit (null = unlimited)',
    'Daily scan limit (null = unlimited)',
    'Paste image or leave blank',
    'Auto-generated crop data (do not edit)',
    'Translation data in JSON format (auto-managed)',
    'Content hash for translation tracking (auto-managed)'
  ];
  const descriptionRow = worksheet.getRow(EXCEL_CONFIG.CARD_SHEET.DESCRIPTIONS_ROW);
  descriptionRow.values = descriptions;
  descriptionRow.eachCell(cell => styleInstruction(cell));
  descriptionRow.height = 25;
  
  // Row 5+: Actual data with validation
  // IMPORTANT: Keep in sync with EXCEL_CONFIG.COLUMNS.CARD (19 columns)
  const dataRow = worksheet.getRow(EXCEL_CONFIG.CARD_SHEET.DATA_START_ROW);
  dataRow.values = [
    sanitizeString(cardData.name || ''),
    sanitizeString(cardData.description || ''),
    sanitizeString(cardData.ai_instruction || ''),
    sanitizeString(cardData.ai_knowledge_base || ''),
    sanitizeString(cardData.ai_welcome_general || ''), // AI Welcome (General)
    sanitizeString(cardData.ai_welcome_item || ''), // AI Welcome (Item)
    sanitizeString(cardData.original_language || 'en'),
    cardData.conversation_ai_enabled,
    sanitizeString(cardData.qr_code_position || 'BR'),
    sanitizeString(cardData.content_mode || 'list'), // Content rendering mode
    cardData.is_grouped ? true : false, // Is Grouped
    sanitizeString(cardData.group_display || 'expanded'), // Group Display
    sanitizeString(cardData.billing_type || 'physical'), // Access mode
    cardData.max_scans !== null && cardData.max_scans !== undefined ? cardData.max_scans : '', // Total scan limit
    cardData.daily_scan_limit !== null && cardData.daily_scan_limit !== undefined ? cardData.daily_scan_limit : '', // Daily scan limit
    '', // Placeholder for image
    sanitizeString(cardData.crop_parameters ? JSON.stringify(cardData.crop_parameters) : ''), // Hidden crop parameters
    sanitizeString(cardData.translations ? JSON.stringify(cardData.translations) : '{}'), // Hidden translations data
    sanitizeString(cardData.content_hash || '') // Hidden content hash for import preservation
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
  
  // Embed card image with proper sizing (use original image if available, otherwise use cropped)
  const imageToEmbed = cardData.original_image_url || cardData.image_url;
  if (imageToEmbed) {
    await embedImages(workbook, worksheet, [imageToEmbed], EXCEL_CONFIG.CARD_SHEET.DATA_START_ROW, 16); // Column P (Card Image) - adjusted for new columns
  }
  
  // Professional column widths (19 columns matching EXCEL_CONFIG.COLUMNS.CARD)
  worksheet.columns = [
    { width: 25 }, // Name
    { width: 40 }, // Description
    { width: 30 }, // AI Instruction
    { width: 45 }, // AI Knowledge Base
    { width: 35 }, // AI Welcome (General)
    { width: 35 }, // AI Welcome (Item)
    { width: 15 }, // Original Language
    { width: 12 }, // AI Enabled
    { width: 12 }, // QR Position
    { width: 15 }, // Content Mode
    { width: 12 }, // Is Grouped
    { width: 15 }, // Group Display
    { width: 12 }, // Access Mode
    { width: 12 }, // Max Scans
    { width: 15 }, // Daily Scan Limit
    { width: 25 }, // Card Image
    { width: 0 },  // Crop Data (hidden)
    { width: 0 },  // Translations (hidden)
    { width: 0 }   // Content Hash (hidden)
  ];
  
  // Add helpful cell comments (adjusted for new column positions)
  dataRow.getCell(1).note = 'This will be the main title displayed on your experience';
  dataRow.getCell(3).note = 'Define the AI\'s role, personality, and restrictions (max 100 words)';
  dataRow.getCell(4).note = 'Provide detailed background knowledge for the AI (max 2000 words)';
  dataRow.getCell(5).note = 'Custom welcome message for the general AI assistant';
  dataRow.getCell(6).note = 'Custom welcome message for item assistant. Use {name} for item name';
  dataRow.getCell(7).note = 'ISO 639-1 language code (en, zh-Hant, zh-Hans, ja, ko, etc.)';
  dataRow.getCell(8).note = 'Enable voice conversations with visitors';
  dataRow.getCell(9).note = 'Where QR code appears on physical card';
  dataRow.getCell(10).note = 'Content mode: single, list, grid, or cards';
  dataRow.getCell(11).note = 'Group content into categories (true/false)';
  dataRow.getCell(12).note = 'How grouped items display: expanded or collapsed';
  dataRow.getCell(13).note = 'Access mode: physical (printed card) or digital (QR only)';
  dataRow.getCell(14).note = 'Total scan limit for digital access (leave empty for unlimited)';
  dataRow.getCell(15).note = 'Daily scan limit for digital access (leave empty for unlimited)';
  dataRow.getCell(16).note = 'Right-click and paste image, or drag and drop';
  
  // Freeze headers
  worksheet.views = [{ state: 'frozen', ySplit: EXCEL_CONFIG.CARD_SHEET.DESCRIPTIONS_ROW }];
  
  // No zebra striping or background colors for data rows
}

/**
 * Create Content Items sheet with embedded images
 */
async function createContentSheet(workbook, contentItems, options = {}) {
  const sheetName = options.sheetName || EXCEL_CONFIG.CONTENT_SHEET.NAME;
  const worksheet = workbook.addWorksheet(sheetName);
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
    'AI knowledge for this specific content (max 500 words)',
    'Auto-generated from row order',
    'Layer 1 = Main items, Layer 2 = Sub-items',
    'Cell reference for parent (e.g., A5)',
    'Paste image or provide URL',
    'Auto-generated crop data (do not edit)',
    'Translation data in JSON format (auto-managed)',
    'Content hash for translation tracking (auto-managed)'
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
      sanitizeString(item.name || ''),
      sanitizeString(item.content || ''),
      sanitizeString(item.ai_knowledge_base || ''),
      item.sort_order || i + 1,
      layer,
      parentReference,
      '', // Placeholder for image
      sanitizeString(item.crop_parameters ? JSON.stringify(item.crop_parameters) : ''), // Hidden crop parameters
      sanitizeString(item.translations ? JSON.stringify(item.translations) : '{}'), // Hidden translations data
      sanitizeString(item.content_hash || '') // Hidden content hash for import preservation
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
    
    // Embed images with proper sizing (use original image if available, otherwise use cropped)
    const contentImageToEmbed = item.original_image_url || item.image_url;
    if (contentImageToEmbed) {
      await embedImages(workbook, worksheet, [contentImageToEmbed], rowNum, 7); // Column G (Image)
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
    { width: 35 }, // AI Knowledge Base
    { width: 12 }, // Sort Order
    { width: 12 }, // Layer
    { width: 18 }, // Parent Reference
    { width: 25 }, // Image
    { width: 0 },  // Crop Data (hidden)
    { width: 0 },  // Translations (hidden)
    { width: 0 }   // Content Hash (hidden)
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
  
  // Row 1: Branded title with icons (span to column S = 19 columns)
  const titleCell = worksheet.getCell('A1');
  titleCell.value = `${EXCEL_CONFIG.ICONS.CARD} FunTell - Card Import Template`;
  styleTitle(titleCell);
  worksheet.mergeCells('A1:S1');
  worksheet.getRow(1).height = 30;
  
  // Row 2: Clear user instructions (span to column S = 19 columns)
  const instructionCell = worksheet.getCell('A2');
  instructionCell.value = `${EXCEL_CONFIG.ICONS.INSTRUCTIONS} Fill in your experience details below. Required fields marked with *. Use dropdowns for validation.`;
  styleInstructions(instructionCell);
  worksheet.mergeCells('A2:S2');
  worksheet.getRow(2).height = 25;
  
  // Row 3: Headers with icons
  const headers = EXCEL_CONFIG.COLUMNS.CARD.map(h => {
    if (h.includes('AI')) return `${EXCEL_CONFIG.ICONS.AI} ${h}*`;
    if (h.includes('Image')) return `${EXCEL_CONFIG.ICONS.IMAGE} ${h}`;
    if (h === 'Name') return `${h}*`;
    if (h.includes('Mode') || h.includes('Position') || h.includes('Language')) return `${h}*`;
    return h;
  });
  const headerRow = worksheet.getRow(EXCEL_CONFIG.CARD_SHEET.HEADERS_ROW);
  headerRow.values = headers;
  headerRow.eachCell(cell => styleHeader(cell));
  headerRow.height = 25;
  
  // Row 4: Enhanced descriptions with examples (19 columns)
  const descriptions = [
    'Enter card title (e.g., "Museum Experience")',
    'Brief description of card purpose',
    'AI instructions (e.g., "You are a helpful guide...")',
    'Background knowledge for AI conversations',
    'Welcome message for general assistant',
    'Welcome message for item assistant ({name} placeholder)',
    'Original content language (en, zh-Hant, etc.)',
    'Select true/false from dropdown',
    'Select QR position: TL/TR/BL/BR',
    'Content mode: single/list/grid/cards',
    'Group content into categories (true/false)',
    'Group display: expanded/collapsed',
    'Access mode: physical/digital',
    'Total scan limit (null = unlimited)',
    'Daily scan limit (null = unlimited)',
    'Paste image or leave blank',
    'Auto-generated crop data (do not edit)',
    'Translation data in JSON format (auto-managed)',
    'Content hash for translation tracking (auto-managed)'
  ];
  const descriptionRow = worksheet.getRow(EXCEL_CONFIG.CARD_SHEET.DESCRIPTIONS_ROW);
  descriptionRow.values = descriptions;
  descriptionRow.eachCell(cell => styleInstruction(cell));
  descriptionRow.height = 25;
  
  // Row 5: Empty data row for import (19 columns)
  const emptyData = [
    '', // Name
    '', // Description
    '', // AI Instruction
    '', // AI Knowledge Base
    '', // AI Welcome (General)
    '', // AI Welcome (Item)
    '', // Original Language
    '', // AI Enabled
    '', // QR Position
    '', // Content Mode
    '', // Is Grouped
    '', // Group Display
    '', // Access Mode
    '', // Max Scans
    '', // Daily Scan Limit
    '', // Card Image
    '', // Crop Data (hidden)
    '', // Translations (hidden)
    ''  // Content Hash (hidden)
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
  
  // Add helpful cell comments (adjusted for 19-column layout)
  dataRow.getCell(1).note = 'This will be the main title displayed on your experience';
  dataRow.getCell(3).note = 'Define the AI\'s role, personality, and restrictions (max 100 words)';
  dataRow.getCell(4).note = 'Provide detailed background knowledge for the AI (max 2000 words)';
  dataRow.getCell(5).note = 'Custom welcome message for the general AI assistant';
  dataRow.getCell(6).note = 'Custom welcome message for item assistant. Use {name} for item name';
  dataRow.getCell(7).note = 'ISO 639-1 language code (en, zh-Hant, zh-Hans, ja, ko, etc.)';
  dataRow.getCell(8).note = 'Enable voice conversations with visitors';
  dataRow.getCell(9).note = 'Where QR code appears on physical card';
  dataRow.getCell(10).note = 'Content mode: single, list, grid, or cards';
  dataRow.getCell(11).note = 'Group content into categories (true/false)';
  dataRow.getCell(12).note = 'How grouped items display: expanded or collapsed';
  dataRow.getCell(13).note = 'Access mode: physical (printed card) or digital (QR only)';
  dataRow.getCell(14).note = 'Total scan limit for digital access (leave empty for unlimited)';
  dataRow.getCell(15).note = 'Daily scan limit for digital access (leave empty for unlimited)';
  dataRow.getCell(16).note = 'Right-click and paste image, or drag and drop';
  
  dataRow.height = 35; // Larger row for better readability
  
  // Professional column sizing (19 columns)
  worksheet.columns = [
    { width: 25 }, // Name
    { width: 40 }, // Description
    { width: 30 }, // AI Instruction
    { width: 45 }, // AI Knowledge Base
    { width: 35 }, // AI Welcome (General)
    { width: 35 }, // AI Welcome (Item)
    { width: 15 }, // Original Language
    { width: 12 }, // AI Enabled
    { width: 12 }, // QR Position
    { width: 15 }, // Content Mode
    { width: 12 }, // Is Grouped
    { width: 15 }, // Group Display
    { width: 12 }, // Access Mode
    { width: 12 }, // Max Scans
    { width: 15 }, // Daily Scan Limit
    { width: 25 }, // Card Image
    { width: 0 },  // Crop Data (hidden)
    { width: 0 },  // Translations (hidden)
    { width: 0 }   // Content Hash (hidden)
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
    'AI knowledge for this specific content (max 500 words)',
    'Auto-generated from row order',
    'Layer 1 = Main items, Layer 2 = Sub-items',
    'Cell reference for parent (e.g., A5)',
    'Paste image or provide URL',
    'Auto-generated crop data (do not edit)',
    'Translation data in JSON format (auto-managed)',
    'Content hash for translation tracking (auto-managed)'
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
    row.values = ['', '', '', '', '', '', '', '', '', '']; // 10 columns including hidden ones
    
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
    { width: 35 }, // AI Knowledge Base
    { width: 12 }, // Sort Order
    { width: 12 }, // Layer
    { width: 18 }, // Parent Reference
    { width: 25 }, // Image
    { width: 0 },  // Crop Data (hidden)
    { width: 0 },  // Translations (hidden)
    { width: 0 }   // Content Hash (hidden)
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
      
      // IMPORTANT: Keep in sync with EXCEL_CONFIG.COLUMNS.CARD (19 columns)
      const fieldMapping = {
        'Name': 'name',
        'Description': 'description',
        'AI Instruction': 'ai_instruction',
        'AI Knowledge Base': 'ai_knowledge_base',
        'AI Welcome (General)': 'ai_welcome_general',
        'AI Welcome (Item)': 'ai_welcome_item',
        'Original Language': 'original_language',
        'AI Enabled': 'conversation_ai_enabled',
        'QR Position': 'qr_code_position',
        'Content Mode': 'content_mode',
        'Is Grouped': 'is_grouped',
        'Group Display': 'group_display',
        'Access Mode': 'billing_type',
        'Max Scans': 'max_scans',
        'Daily Scan Limit': 'daily_scan_limit',
        'Crop Data': 'crop_parameters_json',
        'Translations': 'translations_json',
        'Content Hash': 'content_hash'
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
        } else if (dbField === 'content_mode') {
          // Validate content mode
          // 'cards' is legacy DB value, 'inline' is the modern UI term (maps to 'cards' in DB)
          const validModes = ['single', 'grouped', 'list', 'grid', 'inline', 'cards'];
          const lowerValue = processedValue.toString().toLowerCase();
          if (validModes.includes(lowerValue)) {
            // Map 'inline' to 'cards' for DB storage (schema constraint)
            cardData[dbField] = lowerValue === 'inline' ? 'cards' : lowerValue;
          } else {
            console.warn(`Invalid content mode '${processedValue}', defaulting to 'list'`);
            cardData[dbField] = 'list';
            result.warnings.push(`Invalid Content Mode '${processedValue}' - using default 'list'. Valid options: single, grouped, list, grid, cards (inline)`);
          }
        } else if (dbField === 'billing_type') {
          // Validate access mode (billing_type)
          const validTypes = ['physical', 'digital'];
          const lowerValue = processedValue.toString().toLowerCase();
          if (validTypes.includes(lowerValue)) {
            cardData[dbField] = lowerValue;
          } else {
            console.warn(`Invalid access mode '${processedValue}', defaulting to 'physical'`);
            cardData[dbField] = 'physical';
            result.warnings.push(`Invalid Access Mode '${processedValue}' - using default 'physical'. Valid options: physical, digital`);
          }
        } else if (dbField === 'max_scans' || dbField === 'daily_scan_limit') {
          // Handle scan limits - can be null/empty or a number
          if (processedValue === '' || processedValue === null || processedValue === undefined) {
            cardData[dbField] = null;
          } else {
            const numValue = parseInt(processedValue, 10);
            if (!isNaN(numValue) && numValue >= 0) {
              cardData[dbField] = numValue;
            } else {
              console.warn(`Invalid ${dbField} '${processedValue}', setting to null (unlimited)`);
              cardData[dbField] = null;
              result.warnings.push(`Invalid ${dbField} '${processedValue}' - setting to null (unlimited). Expected a positive number.`);
            }
          }
        } else if (dbField === 'is_grouped') {
          // Handle is_grouped boolean
          cardData[dbField] = ['true', 'yes', '1', true].includes(processedValue.toString().toLowerCase());
        } else if (dbField === 'group_display') {
          // Validate group display
          const validDisplays = ['expanded', 'collapsed'];
          const lowerValue = processedValue.toString().toLowerCase();
          if (validDisplays.includes(lowerValue)) {
            cardData[dbField] = lowerValue;
          } else {
            console.warn(`Invalid group display '${processedValue}', defaulting to 'expanded'`);
            cardData[dbField] = 'expanded';
            result.warnings.push(`Invalid Group Display '${processedValue}' - using default 'expanded'. Valid options: expanded, collapsed`);
          }
        } else {
          cardData[dbField] = processedValue;
        }
      }
    }
    
    // Extract card image if embedded
    const cardImageRow = EXCEL_CONFIG.CARD_SHEET.DATA_START_ROW;
    const cardImageCol = 16; // Column P (Card Image) - updated for 19-column layout
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
    ai_knowledge_base: 3, // Column C
    sort_order: 4,     // Column D
    layer: 5,          // Column E
    parent_reference: 6, // Column F
    image: 7,          // Column G
    crop_data: 8,      // Column H (hidden)
    translations: 9,   // Column I (hidden)
    content_hash: 10   // Column J (hidden)
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
        ai_knowledge_base: worksheet.getCell(currentRowNum, colMap.ai_knowledge_base).value?.toString() || '',
        sort_order: worksheet.getCell(currentRowNum, colMap.sort_order).value || (currentRowNum - EXCEL_CONFIG.CONTENT_SHEET.DATA_START_ROW) + 1,
        layer: layerValue,
        parent_reference: parentRefValue,
        image_url: worksheet.getCell(currentRowNum, colMap.image).value?.toString() || '',
        crop_parameters_json: worksheet.getCell(currentRowNum, colMap.crop_data).value?.toString() || '',
        translations_json: worksheet.getCell(currentRowNum, colMap.translations).value?.toString() || '{}',
        content_hash: worksheet.getCell(currentRowNum, colMap.content_hash).value?.toString() || ''
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
      // Use integer column and offset (avoid floats in 'col')
      // For multiple images, we place them in subsequent columns if available, or just stack them slightly offset
      // Since we have hidden columns after image column, we can use them safely
      const colOffset = Math.floor(i * 1.2); 
      
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