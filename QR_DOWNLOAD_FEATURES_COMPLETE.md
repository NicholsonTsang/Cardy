# QR & Access Page - Download Features Implementation

## Summary

Implemented two key download features for the QR & Access page:
1. **Download All QR Codes** - Bulk download of all QR codes as a ZIP file
2. **Download CSV** - Already implemented, now working alongside the new bulk download

## Implementation Details

### 1. Download All QR Codes Feature

**File Modified**: `src/components/CardComponents/CardAccessQR.vue`

**Key Features**:
- Generates QR codes for all filtered cards (respects active/inactive filter)
- Creates a ZIP file with organized structure:
  - `qr_codes/` folder containing all QR code images
  - `README.txt` with detailed batch and card information
- QR code file naming: `card_XXX_active.png` or `card_XXX_inactive.png`
  - XXX is zero-padded card number (e.g., 001, 002, etc.)
- ZIP file naming: `{cardName}_{batchName}_qr_codes_{date}.zip`

**Technical Implementation**:
- Uses JSZip library (already available via ExcelJS dependency)
- Generates high-quality QR codes (512x512px, error correction level M)
- Progress toast notifications:
  - Info: "Generating QR Codes" with count
  - Success: "{count} QR codes downloaded successfully"
  - Error: "Failed to generate QR codes ZIP file"
- README.txt includes:
  - Batch information (name, total cards, active/inactive counts)
  - Card list with IDs, status, and URLs
  - Usage instructions

**User Experience**:
- Button enabled (previously disabled with "coming soon" tooltip)
- Blue outlined button matching design system
- Automatic browser download
- Respects current filter (all/active/inactive cards)
- Handles edge cases (no cards available)

### 2. Download CSV Feature

**Status**: Already implemented, enhanced with new button styling

**Changes**:
- Updated button to use `severity="success"` for visual consistency
- Maintained green color scheme (`border-green-600 text-green-600`)

## Translation Support

### New i18n Keys Added

**English (`src/i18n/locales/en.json`)**:
```json
"batches": {
  "generating_qr_codes": "Generating QR Codes",
  "please_wait_generating": "Please wait while we generate {count} QR codes...",
  "qr_codes_downloaded": "{count} QR codes downloaded successfully",
  "failed_to_generate_qr_zip": "Failed to generate QR codes ZIP file",
  "no_cards_to_download": "No cards available to download"
},
"messages": {
  "no_cards": "No Cards Available",
  "download_complete": "Download Complete",
  "download_failed": "Download Failed"
}
```

**Traditional Chinese (`src/i18n/locales/zh-Hant.json`)**:
```json
"batches": {
  "generating_qr_codes": "生成二維碼",
  "please_wait_generating": "請稍候，正在生成 {count} 個二維碼...",
  "qr_codes_downloaded": "成功下載 {count} 個二維碼",
  "failed_to_generate_qr_zip": "生成二維碼壓縮檔案失敗",
  "no_cards_to_download": "沒有可下載的卡片"
},
"messages": {
  "no_cards": "沒有可用卡片",
  "download_complete": "下載完成",
  "download_failed": "下載失敗"
}
```

## Dependencies

- **JSZip** (v3.10.1) - Already installed via ExcelJS
- **qrcode** - Already installed for QR code generation

## Testing Checklist

### Functional Testing
- [ ] Select a batch with cards
- [ ] Click "Download All QR Codes" button
- [ ] Verify ZIP file downloads with correct naming format
- [ ] Extract ZIP and verify:
  - [ ] All QR codes present in `qr_codes/` folder
  - [ ] File names are correctly formatted (card_XXX_active/inactive.png)
  - [ ] QR codes are high quality (512x512px)
  - [ ] QR codes scan correctly and lead to correct URLs
  - [ ] README.txt contains accurate batch and card information

### Edge Cases
- [ ] Test with 1 card batch
- [ ] Test with large batch (50+ cards)
- [ ] Test with "Active Only" filter
- [ ] Test with "Inactive Only" filter
- [ ] Test with "All Cards" filter
- [ ] Test with no cards (should show warning toast)

### UI/UX Testing
- [ ] Button styling matches design system
- [ ] Toast notifications appear at correct times
- [ ] Button is properly enabled (not disabled)
- [ ] Download works on different browsers (Chrome, Firefox, Safari)
- [ ] File naming is descriptive and includes date

### Localization Testing
- [ ] Test in English (en)
- [ ] Test in Traditional Chinese (zh-Hant)
- [ ] Verify all toast messages are properly translated

## README.txt Example

```
Museum Card - QR Codes
==================================================

Batch Information:
- Batch Name: Winter 2024 Exhibition
- Total Cards: 50
- Active Cards: 48
- Inactive Cards: 2
- Generated: 1/13/2025, 10:30:00 AM

QR Code Files:
- card_001_active.png
  Card ID: 123e4567-e89b-12d3-a456-426614174000
  Status: Active
  URL: https://cardstudio.app/c/123e4567-e89b-12d3-a456-426614174000

- card_002_active.png
  Card ID: 123e4567-e89b-12d3-a456-426614174001
  Status: Active
  URL: https://cardstudio.app/c/123e4567-e89b-12d3-a456-426614174001

...

==================================================
How to Use:
1. Each QR code file is named with its card number and status
2. Scan any QR code to access the digital card
3. Active cards are immediately accessible
4. Inactive cards can be activated via admin panel

For support, contact your CardStudio administrator.
```

## Performance Considerations

- QR code generation is done sequentially to avoid overwhelming the browser
- Each QR code is ~5-10KB in size
- 100 cards = ~500KB-1MB ZIP file
- Progress toast shown during generation
- Async/await used for proper error handling

## Browser Compatibility

**Important**: The `qrcode` library has different APIs for Node.js vs browser:
- ✅ **Browser**: Uses `toDataURL()` (returns base64 data URL) → Convert to Blob via `fetch()`
- ❌ **Node.js**: `toBuffer()` method NOT available in browser

Our implementation uses the browser-compatible approach:
```javascript
const qrDataURL = await QRCodeLib.toDataURL(url, { width: 512 })
const blob = await (await fetch(qrDataURL)).blob()
qrFolder.file(fileName, blob)
```

See `QR_DOWNLOAD_BROWSER_FIX.md` for technical details.

## Benefits

1. **Bulk Distribution**: Download all QR codes at once for offline use
2. **Organization**: Structured folder with numbered files
3. **Documentation**: README included for reference
4. **Quality**: High-resolution QR codes suitable for printing
5. **Flexibility**: Respects filter settings (active/inactive)
6. **User-Friendly**: Clear file naming and comprehensive documentation

## Future Enhancements (Optional)

1. Add QR code customization (color, logo, size)
2. Include card images in ZIP alongside QR codes
3. Generate printable PDF with QR codes and card info
4. Add option to include access credentials in README
5. Support for custom README templates

---

**Status**: ✅ Complete and ready for testing
**Date**: January 13, 2025
**Files Modified**: 3
**New Features**: 1 (Download All QR Codes)
**Enhanced Features**: 1 (Download CSV button styling)

