# Excel Export/Import Field Audit

## Database Schema vs Excel Columns

### CARDS Table Fields

| DB Field | Exported? | Excel Column | Import Handled? | Notes |
|----------|-----------|--------------|-----------------|-------|
| `id` | ❌ No | - | ❌ No | UUID, auto-generated |
| `user_id` | ❌ No | - | ❌ No | Set by auth, not exported |
| `name` | ✅ Yes | A (Name) | ✅ Yes | Required |
| `description` | ✅ Yes | B (Description) | ✅ Yes | Required |
| `qr_code_position` | ✅ Yes | G (QR Position) | ✅ Yes | Enum: TL/TR/BL/BR |
| `image_url` | ✅ Yes | H (Card Image) | ✅ Yes | Embedded image |
| `original_image_url` | ✅ Yes | H (Card Image) | ✅ Yes | Embedded image |
| `crop_parameters` | ✅ Yes | I (Crop Data) | ✅ Yes | Hidden JSONB |
| `conversation_ai_enabled` | ✅ Yes | F (AI Enabled) | ✅ Yes | Boolean |
| `ai_instruction` | ✅ Yes | C (AI Instruction) | ✅ Yes | Required |
| `ai_knowledge_base` | ✅ Yes | D (AI Knowledge Base) | ✅ Yes | Required |
| `translations` | ✅ Yes | J (Translations) | ✅ Yes | Hidden JSONB |
| `original_language` | ✅ Yes | E (Original Language) | ✅ Yes | ISO 639-1 code |
| `content_hash` | ✅ Yes | K (Content Hash) | ✅ Yes | Hidden TEXT |
| `last_content_update` | ❌ No | - | ❌ No | Auto-generated timestamp |
| `created_at` | ❌ No | - | ❌ No | Auto-generated timestamp |
| `updated_at` | ❌ No | - | ❌ No | Auto-generated timestamp |

**✅ ALL EXPORTABLE FIELDS COVERED**

### CONTENT_ITEMS Table Fields

| DB Field | Exported? | Excel Column | Import Handled? | Notes |
|----------|-----------|--------------|-----------------|-------|
| `id` | ❌ No | - | ❌ No | UUID, auto-generated |
| `card_id` | ❌ No | - | ✅ Yes | Set during import |
| `parent_id` | ✅ Indirect | F (Parent Reference) | ✅ Yes | Cell reference (A5) |
| `name` | ✅ Yes | A (Name) | ✅ Yes | Required |
| `content` | ✅ Yes | B (Content) | ✅ Yes | Markdown text |
| `image_url` | ✅ Yes | G (Image) | ✅ Yes | Embedded image |
| `original_image_url` | ✅ Yes | G (Image) | ✅ Yes | Embedded image |
| `crop_parameters` | ✅ Yes | H (Crop Data) | ✅ Yes | Hidden JSONB |
| `ai_knowledge_base` | ✅ Yes | C (AI Knowledge Base) | ✅ Yes | Item-specific knowledge |
| `sort_order` | ✅ Yes | D (Sort Order) | ✅ Yes | Integer |
| `translations` | ✅ Yes | I (Translations) | ✅ Yes | Hidden JSONB |
| `content_hash` | ✅ Yes | J (Content Hash) | ✅ Yes | Hidden TEXT |
| `last_content_update` | ❌ No | - | ❌ No | Auto-generated timestamp |
| `created_at` | ❌ No | - | ❌ No | Auto-generated timestamp |
| `updated_at` | ❌ No | - | ❌ No | Auto-generated timestamp |

**✅ ALL EXPORTABLE FIELDS COVERED**

---

## Issues Found

### 1. ❌ Missing Description for Content Hash Column (Cards)
**File**: `src/utils/excelHandler.js`
**Line**: ~152
**Issue**: `descriptions` array has 10 items but should have 11 (Content Hash missing)

```javascript
// Current (10 items)
const descriptions = [
  'Enter card title (e.g., "Museum Experience")',
  'Brief description of card purpose',
  'AI instructions (e.g., "You are a helpful guide...")',
  'Background knowledge for AI conversations',
  'Original content language (en, zh-Hant, etc.)',
  'Select true/false from dropdown',
  'Select QR position: TL/TR/BL/BR',
  'Paste image or leave blank',
  'Auto-generated crop data (do not edit)',
  'Translation data in JSON format (auto-managed)'
];
// Missing: Content Hash description!
```

**Should be** (11 items):
```javascript
const descriptions = [
  'Enter card title (e.g., "Museum Experience")',
  'Brief description of card purpose',
  'AI instructions (e.g., "You are a helpful guide...")',
  'Background knowledge for AI conversations',
  'Original content language (en, zh-Hant, etc.)',
  'Select true/false from dropdown',
  'Select QR position: TL/TR/BL/BR',
  'Paste image or leave blank',
  'Auto-generated crop data (do not edit)',
  'Translation data in JSON format (auto-managed)',
  'Content hash for translation tracking (auto-managed)' // NEW
];
```

### 2. ❌ Missing Description for Content Hash Column (Content Items)
**File**: `src/utils/excelHandler.js`
**Line**: ~265 (content sheet descriptions)

Similar issue for content items sheet.

### 3. ⚠️ Layer Column Not Exported (But Should Be?)
**File**: `src/utils/excelHandler.js`
**Issue**: Column "Layer" is defined in EXCEL_CONFIG but the actual value is calculated during import, not exported

**Current behavior**: Layer is derived from parent_id during import
- Layer 1 = parent_id is NULL
- Layer 2 = parent_id is not NULL

**Should we export it?** Probably YES for clarity, even though it's redundant with Parent Reference.

---

## Summary

### Cards Sheet
- ✅ 11 data columns defined
- ✅ 11 values exported
- ❌ Only 10 descriptions (missing Content Hash)
- ✅ All fields imported correctly

### Content Items Sheet  
- ✅ 10 data columns defined
- ✅ 10 values exported
- ❌ Only 9 descriptions (missing Content Hash)
- ✅ All fields imported correctly

---

## Fix Required

1. Add Content Hash description to cards sheet (index 10)
2. Add Content Hash description to content items sheet (index 9)
3. Verify all hidden columns are properly documented
4. Update template generation to match

**Priority**: HIGH (causes Excel header misalignment)

