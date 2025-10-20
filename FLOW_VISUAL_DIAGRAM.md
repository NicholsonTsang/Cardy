# 🎨 Export/Import Visual Flow Diagram

## 📤 EXPORT FLOW

```
┌─────────────────────────────────────────────────────────────┐
│                     USER CLICKS EXPORT                      │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│  STEP 1: Get Card Data                                      │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ │
│  Component: CardExport.vue                                  │
│  Source: props.card (from parent)                           │
│                                                             │
│  Parent already called:                                     │
│  ┌─────────────────────────────────────────┐               │
│  │ RPC: get_user_cards()                   │               │
│  │ Returns: {                               │               │
│  │   id, name, description,                 │               │
│  │   original_language,                     │               │
│  │   translations: {                        │               │
│  │     "zh-Hant": {...},                    │               │
│  │     "ja": {...}                          │               │
│  │   },                                     │               │
│  │   content_hash,                          │               │
│  │   ... all other fields                   │               │
│  │ }                                        │               │
│  └─────────────────────────────────────────┘               │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│  STEP 2: Get Content Items                                  │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ │
│  ┌─────────────────────────────────────────┐               │
│  │ RPC: get_card_content_items(card_id)    │               │
│  │ Returns: [                               │               │
│  │   {                                      │               │
│  │     id, name, content,                   │               │
│  │     translations: {                      │               │
│  │       "zh-Hant": {...},                  │               │
│  │       "ja": {...}                        │               │
│  │     },                                   │               │
│  │     content_hash,                        │               │
│  │     parent_id, sort_order                │               │
│  │   },                                     │               │
│  │   ...more items                          │               │
│  │ ]                                        │               │
│  └─────────────────────────────────────────┘               │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│  STEP 3: Generate Excel File                                │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ │
│  Function: exportCardToExcel(card, contentItems)            │
│                                                             │
│  Creates Excel with 2 sheets:                               │
│                                                             │
│  📄 Sheet 1: "Card Information"                            │
│  ┌───────────────────────────────────────────────────┐     │
│  │ Col A-H: Visible fields                           │     │
│  │   Name | Description | AI Instruction |           │     │
│  │   Original Language | AI Enabled | QR | Image     │     │
│  │                                                    │     │
│  │ Col I: 🔒 HIDDEN - crop_parameters (JSONB)        │     │
│  │ Col J: 🔒 HIDDEN - translations (JSONB)           │     │
│  │   {                                                │     │
│  │     "zh-Hant": {                                   │     │
│  │       "name": "翻譯名稱",                          │     │
│  │       "description": "翻譯描述",                   │     │
│  │       "translated_at": "2025-01-13...",            │     │
│  │       "content_hash": "abc123def456" ← OLD HASH    │     │
│  │     }                                              │     │
│  │   }                                                │     │
│  └───────────────────────────────────────────────────┘     │
│                                                             │
│  📄 Sheet 2: "Content Items"                               │
│  ┌───────────────────────────────────────────────────┐     │
│  │ Col A-G: Visible fields                           │     │
│  │   Name | Content | AI Knowledge | Sort |          │     │
│  │   Layer | Parent | Image                          │     │
│  │                                                    │     │
│  │ Col H: 🔒 HIDDEN - crop_parameters (JSONB)        │     │
│  │ Col I: 🔒 HIDDEN - translations (JSONB)           │     │
│  │   {                                                │     │
│  │     "zh-Hant": {                                   │     │
│  │       "name": "展品名稱",                          │     │
│  │       "content": "展品內容",                       │     │
│  │       "translated_at": "2025-01-13...",            │     │
│  │       "content_hash": "xyz789abc" ← OLD HASH       │     │
│  │     }                                              │     │
│  │   }                                                │     │
│  └───────────────────────────────────────────────────┘     │
│                                                             │
│  Images embedded as binary data                             │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│  STEP 4: Download Excel File                                │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ │
│  💾 card_name_export_2025-01-13.xlsx                        │
└─────────────────────────────────────────────────────────────┘
```

---

## 📥 IMPORT FLOW

```
┌─────────────────────────────────────────────────────────────┐
│                    USER UPLOADS EXCEL                       │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│  STEP 1: Parse Excel File                                   │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ │
│  Function: importExcelToCardData(file)                      │
│                                                             │
│  Reads all data including hidden columns:                   │
│  ✓ Card fields                                             │
│  ✓ Content items                                           │
│  ✓ Embedded images (binary)                                │
│  ✓ crop_parameters (JSONB from hidden col)                 │
│  ✓ translations (JSONB from hidden col)                    │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│  STEP 2: Create Card (WITHOUT Translations)                 │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ │
│  ┌─────────────────────────────────────────┐               │
│  │ RPC: create_card(...)                   │               │
│  │ Args:                                    │               │
│  │   p_name,                                │               │
│  │   p_description,                         │               │
│  │   p_original_language,                   │               │
│  │   p_ai_instruction,                      │               │
│  │   p_image_url,                           │               │
│  │   p_crop_parameters,                     │               │
│  │   ... all fields EXCEPT translations     │               │
│  │                                          │               │
│  │ Database Actions:                        │               │
│  │ 1. INSERT card                           │               │
│  │ 2. 🔥 Trigger fires:                     │               │
│  │    update_card_content_hash_trigger      │               │
│  │ 3. Calculates hash:                      │               │
│  │    md5(name || description)              │               │
│  │    → "NEW_HASH_123" 🆕                   │               │
│  │                                          │               │
│  │ Returns: card_id (UUID)                  │               │
│  └─────────────────────────────────────────┘               │
│                                                             │
│  Card now exists with:                                      │
│  • content_hash = "NEW_HASH_123" 🆕                         │
│  • translations = {} (empty)                                │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│  STEP 3: Restore Card Translations                          │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ │
│  Parse translations JSON from Excel:                        │
│  ┌─────────────────────────────────────────┐               │
│  │ translationsData = {                    │               │
│  │   "zh-Hant": {                          │               │
│  │     "name": "翻譯名稱",                 │               │
│  │     "description": "翻譯描述",          │               │
│  │     "translated_at": "2025-01-13...",   │               │
│  │     "content_hash": "OLD_HASH_789" ⚠️   │               │
│  │   }                                     │               │
│  │ }                                       │               │
│  └─────────────────────────────────────────┘               │
│                                                             │
│  ┌─────────────────────────────────────────┐               │
│  │ RPC: update_card_translations_bulk(     │               │
│  │   card_id, translationsData             │               │
│  │ )                                       │               │
│  │                                          │               │
│  │ Database Actions:                        │               │
│  │ UPDATE cards                             │               │
│  │ SET translations = translationsData      │               │
│  │ WHERE id = card_id                       │               │
│  └─────────────────────────────────────────┘               │
│                                                             │
│  ⚠️  PROBLEM: Hash Mismatch!                                │
│  Card: content_hash = "NEW_HASH_123"                        │
│  Translation: content_hash = "OLD_HASH_789"                 │
│  NEW ≠ OLD → Would show "Outdated" ❌                       │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│  STEP 4: ⭐ Recalculate Translation Hashes (THE FIX!)       │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ │
│  ┌─────────────────────────────────────────┐               │
│  │ RPC: recalculate_card_translation_hashes│               │
│  │      (card_id)                          │               │
│  │                                          │               │
│  │ Logic in Stored Procedure:               │               │
│  │ 1. Get current card hash:                │               │
│  │    v_current_hash = "NEW_HASH_123"       │               │
│  │                                          │               │
│  │ 2. Get translations:                     │               │
│  │    v_translations = card.translations    │               │
│  │                                          │               │
│  │ 3. FOR EACH language:                    │               │
│  │    - Keep name, description, timestamp   │               │
│  │    - REPLACE content_hash with current:  │               │
│  │      "OLD_HASH_789" → "NEW_HASH_123" ✅  │               │
│  │                                          │               │
│  │ 4. UPDATE card with new translations     │               │
│  └─────────────────────────────────────────┘               │
│                                                             │
│  ✅ FIXED: Hashes Now Match!                                │
│  Card: content_hash = "NEW_HASH_123"                        │
│  Translation: content_hash = "NEW_HASH_123"                 │
│  NEW == NEW → Shows "Up to Date" ✅                         │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│  STEP 5-7: Same Process for Content Items                   │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ │
│                                                             │
│  For each content item (Layer 1, then Layer 2):             │
│                                                             │
│  5. RPC: create_content_item(...)                           │
│     → Trigger calculates NEW hash                           │
│                                                             │
│  6. RPC: update_content_item_translations_bulk(...)         │
│     → Restores translations with OLD hashes                 │
│                                                             │
│  7. RPC: recalculate_content_item_translation_hashes(...)   │
│     → Updates to NEW hashes ✅                              │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│  ✅ IMPORT COMPLETE                                         │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ │
│  Result:                                                    │
│  ✓ Card created with all data                              │
│  ✓ Translations preserved perfectly                        │
│  ✓ Content hashes synchronized                             │
│  ✓ Translation status shows "Up to Date" ✅                │
│  ✓ Content items created with translations                 │
│  ✓ All hashes aligned                                      │
│                                                             │
│  💯 ZERO DATA LOSS!                                         │
└─────────────────────────────────────────────────────────────┘
```

---

## 🔍 Hash Comparison Visual

### Before Fix (Broken):
```
EXPORT:
┌─────────────────────────────────────┐
│ Card in Database                    │
├─────────────────────────────────────┤
│ content_hash: "ABC123"              │
│ translations: {                     │
│   "zh-Hant": {                      │
│     "name": "翻譯",                 │
│     "content_hash": "ABC123" ✅     │
│   }                                 │
│ }                                   │
└─────────────────────────────────────┘
         │
         │ Export to Excel
         ▼
┌─────────────────────────────────────┐
│ Excel File (Hidden Column)          │
├─────────────────────────────────────┤
│ translations: {                     │
│   "zh-Hant": {                      │
│     "name": "翻譯",                 │
│     "content_hash": "ABC123"        │
│   }                                 │
│ }                                   │
└─────────────────────────────────────┘
         │
         │ Import
         ▼
┌─────────────────────────────────────┐
│ Newly Created Card                  │
├─────────────────────────────────────┤
│ content_hash: "XYZ789" (NEW!)       │
│ translations: {                     │
│   "zh-Hant": {                      │
│     "name": "翻譯",                 │
│     "content_hash": "ABC123" (OLD!) │
│   }                                 │
│ }                                   │
├─────────────────────────────────────┤
│ ❌ XYZ789 ≠ ABC123                  │
│ Status: "Outdated" 💔               │
└─────────────────────────────────────┘
```

### After Fix (Working):
```
IMPORT WITH RECALCULATION:

Step 1: Create Card
┌─────────────────────────────────────┐
│ Newly Created Card                  │
├─────────────────────────────────────┤
│ content_hash: "XYZ789" (NEW!)       │
│ translations: {}                    │
└─────────────────────────────────────┘

Step 2: Restore Translations
┌─────────────────────────────────────┐
│ Card After Translation Restore      │
├─────────────────────────────────────┤
│ content_hash: "XYZ789"              │
│ translations: {                     │
│   "zh-Hant": {                      │
│     "name": "翻譯",                 │
│     "content_hash": "ABC123" ⚠️     │
│   }                                 │
│ }                                   │
└─────────────────────────────────────┘

Step 3: ⭐ Recalculate Hashes
┌─────────────────────────────────────┐
│ Card After Hash Recalculation       │
├─────────────────────────────────────┤
│ content_hash: "XYZ789"              │
│ translations: {                     │
│   "zh-Hant": {                      │
│     "name": "翻譯",                 │
│     "content_hash": "XYZ789" ✅     │
│   }                                 │
│ }                                   │
├─────────────────────────────────────┤
│ ✅ XYZ789 == XYZ789                 │
│ Status: "Up to Date" 💚             │
└─────────────────────────────────────┘
```

---

## 📊 Stored Procedure Call Sequence

```
EXPORT:
  get_user_cards()
      ↓
  [Returns card with all data including translations]
      ↓
  get_card_content_items(card_id)
      ↓
  [Returns content items with translations]
      ↓
  exportCardToExcel() → Excel file


IMPORT:
  importExcelToCardData(file)
      ↓
  [Parse all data including hidden JSONB]
      ↓
  create_card(...)                                  ← Creates card, trigger sets NEW hash
      ↓
  update_card_translations_bulk(card_id, trans)     ← Restores translations with OLD hashes
      ↓
  recalculate_card_translation_hashes(card_id)      ← ⭐ Fixes hashes to NEW
      ↓
  FOR EACH content item:
    create_content_item(...)                        ← Creates item, trigger sets NEW hash
        ↓
    update_content_item_translations_bulk(...)      ← Restores translations with OLD hashes
        ↓
    recalculate_content_item_translation_hashes(...)← ⭐ Fixes hashes to NEW
      ↓
  [All hashes aligned, translations show "Up to Date"]
```

---

## 🎯 Key Takeaway

The **two-step import process** is essential:

1. **First**: Create entity (card/item) → Gets NEW hash from trigger
2. **Second**: Restore translations → Contains OLD hashes from export
3. **Third**: **⭐ Recalculate hashes** → Updates OLD → NEW

Without step 3, all translations would appear "Outdated" after import!

