/**
 * Constants and styling configurations for Excel export/import.
 */

export const EXCEL_CONFIG = {
  CARD_SHEET: {
    NAME: 'Card Information',
    TITLE_ROW: 1,
    INSTRUCTIONS_ROW: 2,
    HEADERS_ROW: 3,
    DESCRIPTIONS_ROW: 4,
    DATA_START_ROW: 5
  },
  CONTENT_SHEET: {
    NAME: 'Content Items', 
    TITLE_ROW: 1,
    INSTRUCTIONS_ROW: 2,
    HEADERS_ROW: 3,
    DESCRIPTIONS_ROW: 4,
    DATA_START_ROW: 5
  },
  COLUMNS: {
    CARD: ['Name', 'Description', 'AI Instruction', 'AI Knowledge Base', 'Original Language', 'AI Enabled', 'QR Position', 'Card Image', 'Crop Data', 'Translations'],
    CONTENT: ['Name', 'Content', 'AI Knowledge Base', 'Sort Order', 'Layer', 'Parent Reference', 'Image', 'Crop Data', 'Translations']
  },
  COLORS: {
    // CardStudio blue theme
    PRIMARY: 'FF3B82F6',
    TITLE: 'FF1E40AF',
    TITLE_BG: 'FFDBEAFE',
    HEADER: 'FFFFFFFF',
    HEADER_BG: 'FF3B82F6',
    INSTRUCTION: 'FF6B7280',
    INSTRUCTION_BG: 'FFF1F5F9',
    ZEBRA_LIGHT: 'FFF8FAFC',
    ZEBRA_DARK: 'FFF1F5F9',
    REQUIRED: 'FFEF4444',
    LAYER1: 'FFECFDF5',
    LAYER2: 'FFFEF3C7',
    VALIDATION_ERROR: 'FFFEF2F2'
  },
  ICONS: {
    CARD: '🎴',
    INSTRUCTIONS: '📝',
    AI: '🤖',
    IMAGE: '📷',
    CONTENT: '📚',
    LAYER: '📋',
    VALIDATION: '✅'
  }
};

export function styleTitle(cell) {
  cell.font = { bold: true, size: 18, color: { argb: EXCEL_CONFIG.COLORS.TITLE } };
  cell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: EXCEL_CONFIG.COLORS.TITLE_BG } };
  cell.alignment = { horizontal: 'center', vertical: 'center' };
  cell.border = {
    top: { style: 'medium', color: { argb: EXCEL_CONFIG.COLORS.PRIMARY } },
    bottom: { style: 'medium', color: { argb: EXCEL_CONFIG.COLORS.PRIMARY } },
    left: { style: 'medium', color: { argb: EXCEL_CONFIG.COLORS.PRIMARY } },
    right: { style: 'medium', color: { argb: EXCEL_CONFIG.COLORS.PRIMARY } }
  };
}

export function styleHeader(cell) {
  cell.font = { bold: true, size: 11, color: { argb: EXCEL_CONFIG.COLORS.HEADER } };
  cell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: EXCEL_CONFIG.COLORS.HEADER_BG } };
  cell.alignment = { horizontal: 'center', vertical: 'center', wrapText: true };
  cell.border = {
    top: { style: 'medium', color: { argb: EXCEL_CONFIG.COLORS.PRIMARY } },
    bottom: { style: 'medium', color: { argb: EXCEL_CONFIG.COLORS.PRIMARY } },
    left: { style: 'thin', color: { argb: EXCEL_CONFIG.COLORS.PRIMARY } },
    right: { style: 'thin', color: { argb: EXCEL_CONFIG.COLORS.PRIMARY } }
  };
}

export function styleInstruction(cell) {
  cell.font = { italic: true, size: 10, color: { argb: EXCEL_CONFIG.COLORS.INSTRUCTION } };
  cell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: EXCEL_CONFIG.COLORS.INSTRUCTION_BG } };
  cell.alignment = { horizontal: 'left', vertical: 'top', wrapText: true };
  cell.border = {
    top: { style: 'thin', color: { argb: EXCEL_CONFIG.COLORS.INSTRUCTION } },
    bottom: { style: 'thin', color: { argb: EXCEL_CONFIG.COLORS.INSTRUCTION } },
    left: { style: 'thin', color: { argb: EXCEL_CONFIG.COLORS.INSTRUCTION } },
    right: { style: 'thin', color: { argb: EXCEL_CONFIG.COLORS.INSTRUCTION } }
  };
}

export function styleInstructions(cell) {
  cell.font = { bold: true, size: 12, color: { argb: EXCEL_CONFIG.COLORS.INSTRUCTION } };
  cell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: EXCEL_CONFIG.COLORS.INSTRUCTION_BG } };
  cell.alignment = { horizontal: 'left', vertical: 'center' };
  cell.border = {
    top: { style: 'thin', color: { argb: EXCEL_CONFIG.COLORS.INSTRUCTION } },
    bottom: { style: 'thin', color: { argb: EXCEL_CONFIG.COLORS.INSTRUCTION } },
    left: { style: 'thin', color: { argb: EXCEL_CONFIG.COLORS.INSTRUCTION } },
    right: { style: 'thin', color: { argb: EXCEL_CONFIG.COLORS.INSTRUCTION } }
  };
}

export function styleDataCell(cell, isRequired = false) {
  cell.alignment = { horizontal: 'left', vertical: 'top', wrapText: true };
  cell.border = {
    top: { style: 'thin', color: { argb: 'FFD1D5DB' } },
    bottom: { style: 'thin', color: { argb: 'FFD1D5DB' } },
    left: { style: 'thin', color: { argb: 'FFD1D5DB' } },
    right: { style: 'thin', color: { argb: 'FFD1D5DB' } }
  };
  
  if (isRequired && !cell.value) {
    cell.border = {
      top: { style: 'medium', color: { argb: EXCEL_CONFIG.COLORS.REQUIRED } },
      bottom: { style: 'medium', color: { argb: EXCEL_CONFIG.COLORS.REQUIRED } },
      left: { style: 'medium', color: { argb: EXCEL_CONFIG.COLORS.REQUIRED } },
      right: { style: 'medium', color: { argb: EXCEL_CONFIG.COLORS.REQUIRED } }
    };
  }
}

export function applyZebraStriping(worksheet, startRow, itemCount) {
  for (let i = 0; i < itemCount; i++) {
    const rowNum = startRow + i;
    const row = worksheet.getRow(rowNum);
    const zebraColor = i % 2 === 0 ? EXCEL_CONFIG.COLORS.ZEBRA_LIGHT : EXCEL_CONFIG.COLORS.ZEBRA_DARK;
    
    row.eachCell((cell, colNumber) => {
      if (!cell.fill || !cell.fill.fgColor || cell.fill.fgColor.argb === 'FFFFFFFF') {
        cell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: zebraColor } };
      }
    });
  }
}

export function applyConditionalFormatting(worksheet, startRow, itemCount, layerColumn) {
  for (let i = 0; i < itemCount; i++) {
    const rowNum = startRow + i;
    const layerCell = worksheet.getCell(rowNum, layerColumn);
    
    if (layerCell.value === 'Layer 1') {
      layerCell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: EXCEL_CONFIG.COLORS.LAYER1 } };
    } else if (layerCell.value === 'Layer 2') {
      layerCell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: EXCEL_CONFIG.COLORS.LAYER2 } };
    }
  }
}

export function addDataValidation(cell, type, options = {}) {
  switch (type) {
    case 'boolean':
      cell.dataValidation = {
        type: 'list',
        allowBlank: false,
        formulae: ['"true,false"'],
        showErrorMessage: true,
        errorTitle: 'Invalid Value',
        error: 'Please select either true or false'
      };
      break;
    
    case 'qrPosition':
      cell.dataValidation = {
        type: 'list',
        allowBlank: false,
        formulae: ['"TL,TR,BL,BR"'],
        showErrorMessage: true,
        errorTitle: 'Invalid QR Position',
        error: 'Please select TL (Top Left), TR (Top Right), BL (Bottom Left), or BR (Bottom Right)'
      };
      break;
    
    case 'layer':
      cell.dataValidation = {
        type: 'list',
        allowBlank: false,
        formulae: ['"Layer 1,Layer 2"'],
        showErrorMessage: true,
        errorTitle: 'Invalid Layer',
        error: 'Please select either Layer 1 (top-level) or Layer 2 (child item)'
      };
      break;
    
    case 'parentReference':
      if (options.layer1Items && options.layer1Items.length > 0) {
        const parentList = `"${options.layer1Items.join(',')}"`;
        cell.dataValidation = {
          type: 'list',
          allowBlank: true,
          formulae: [parentList],
          showErrorMessage: true,
          errorTitle: 'Invalid Parent',
          error: 'Please select a valid Layer 1 item as the parent'
        };
      }
      break;
    
    case 'number':
      cell.dataValidation = {
        type: 'whole',
        operator: 'greaterThan',
        formulae: ['0'],
        showErrorMessage: true,
        errorTitle: 'Invalid Number',
        error: 'Please enter a positive number'
      };
      break;
  }
}

export function getColumnLetter(num) {
  let result = '';
  while (num > 0) {
    num--;
    result = String.fromCharCode(65 + (num % 26)) + result;
    num = Math.floor(num / 26);
  }
  return result;
}

export function getColumnNumber(letter) {
  let result = 0;
  for (let i = 0; i < letter.length; i++) {
    result = result * 26 + (letter.charCodeAt(i) - 64);
  }
  return result;
} 