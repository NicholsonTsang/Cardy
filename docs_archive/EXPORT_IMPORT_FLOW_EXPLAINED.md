# 📊 Complete Export/Import Flow & Logic

## 🎯 Overview

The export/import system preserves **100% of card data** including translations, using a combination of:
- **Stored Procedures** (RPCs) for database operations
- **Excel files** with embedded images and hidden JSONB columns
- **Automatic hash recalculation** to maintain translation freshness

---

## 📤 EXPORT FLOW

### Step 1: Fetch Card Data
**Component**: `CardExport.vue`  
**Source**: Card data comes from parent component

```javascript
const card = props.card  // Already fetched by parent via get_user_cards()
```

**Stored Procedure Used**: `get_user_cards()`  
**What it returns**:
```javascript
{
  id: UUID,
  name: string,
  description: string,
  image_url: string,
  original_image_url: string,
  crop_parameters: JSONB,
  conversation_ai_enabled: boolean,
  ai_instruction: string,
  ai_knowledge_base: string,
  qr_code_position: string,
  translations: JSONB,           // ← ALL translations
  original_language: string,      // ← Original language
  content_hash: string,           // ← Current hash
  last_content_update: timestamp,
  created_at: timestamp,
  updated_at: timestamp
}
```

### Step 2: Fetch Content Items
**Stored Procedure**: `get_card_content_items(p_card_id)`

```javascript
const { data: contentData } = await supabase.rpc('get_card_content_items', { 
  p_card_id: props.card.id 
})
```

**What it returns** (for each content item):
```javascript
{
  id: UUID,
  card_id: UUID,
  parent_id: UUID,
  name: string,
  content: string,
  image_url: string,
  original_image_url: string,
  crop_parameters: JSONB,
  ai_knowledge_base: string,
  sort_order: integer,
  translations: JSONB,           // ← ALL translations
  content_hash: string,          // ← Current hash
  last_content_update: timestamp,
  created_at: timestamp,
  updated_at: timestamp
}
```

### Step 3: Generate Excel File
**Utility**: `exportCardToExcel(card, contentItems, options)`  
**Location**: `src/utils/excelHandler.js`

**Excel Structure Created**:

#### Sheet 1: "Card Information"
```
┌────────────────────────────────────────────────────────────────┐
│ Name | Description | AI Instruction | AI Knowledge Base |     │
│ Original Language | AI Enabled | QR Position | Card Image |  │
│ [HIDDEN: Crop Data] | [HIDDEN: Translations JSONB] |          │
└────────────────────────────────────────────────────────────────┘
```

**Column J (Hidden)**: `translations` JSONB
```json
{
  "zh-Hant": {
    "name": "翻譯的名稱",
    "description": "翻譯的描述",
    "translated_at": "2025-01-13T10:30:00Z",
    "content_hash": "abc123def456"
  },
  "ja": { ... }
}
```

#### Sheet 2: "Content Items"
```
┌──────────────────────────────────────────────────────────────┐
│ Name | Content | AI Knowledge Base | Sort Order | Layer |   │
│ Parent Reference | Image | [HIDDEN: Crop Data] |            │
│ [HIDDEN: Translations JSONB] |                               │
└──────────────────────────────────────────────────────────────┘
```

**Column I (Hidden)**: `translations` JSONB
```json
{
  "zh-Hant": {
    "name": "展品名稱",
    "content": "展品內容",
    "ai_knowledge_base": "知識庫",
    "translated_at": "2025-01-13T10:30:00Z",
    "content_hash": "xyz789abc123"
  }
}
```

### Step 4: Download
Blob created and downloaded to user's computer.

---

## 📥 IMPORT FLOW

### Step 1: Parse Excel File
**Component**: `CardBulkImport.vue`  
**Utility**: `importExcelToCardData(file)`

**Reads from Excel**:
- Card data (including `original_language`)
- Content items (all fields)
- **Hidden columns**: `crop_parameters`, `translations` JSONB
- Embedded images (extracted as binary data)

### Step 2: Create Card (WITHOUT Translations)
**Stored Procedure**: `create_card(...)`

```javascript
const { data: cardId } = await supabase.rpc('create_card', {
  p_name: importData.cardData.name,
  p_description: importData.cardData.description,
  p_ai_instruction: importData.cardData.ai_instruction,
  p_ai_knowledge_base: importData.cardData.ai_knowledge_base,
  p_conversation_ai_enabled: importData.cardData.conversation_ai_enabled,
  p_qr_code_position: qrPosition,
  p_image_url: cardImageUrl,
  p_original_image_url: cardOriginalImageUrl,
  p_crop_parameters: cardCropParams,
  p_original_language: importData.cardData.original_language || 'en'
})
```

**What happens in database**:
1. Card created with basic data
2. **Trigger fires**: `update_card_content_hash_trigger`
3. Calculates NEW hash: `md5(name || description)` → `NEW_HASH_123`
4. Card now has `content_hash = 'NEW_HASH_123'`

### Step 3: Restore Translations
**Stored Procedure**: `update_card_translations_bulk(p_card_id, p_translations)`

```javascript
const translationsData = JSON.parse(importData.cardData.translations_json)
// translationsData contains OLD hashes from exported card

await supabase.rpc('update_card_translations_bulk', {
  p_card_id: cardId,
  p_translations: translationsData
})
```

**What happens in database**:
```sql
UPDATE cards
SET translations = '{
  "zh-Hant": {
    "name": "翻譯的名稱",
    "description": "翻譯的描述",
    "translated_at": "2025-01-13T10:30:00Z",
    "content_hash": "OLD_HASH_789"  ← MISMATCH!
  }
}'
WHERE id = p_card_id;
```

**Problem**: `card.content_hash = 'NEW_HASH_123'` but translation has `'OLD_HASH_789'`

### Step 4: ⭐ Recalculate Translation Hashes (THE FIX!)
**Stored Procedure**: `recalculate_card_translation_hashes(p_card_id)`

```javascript
await supabase.rpc('recalculate_card_translation_hashes', {
  p_card_id: cardId
})
```

**What happens in database**:
```sql
-- Get current card hash
v_current_hash := 'NEW_HASH_123';  -- From newly created card

-- Get translations
v_translations := card.translations;

-- FOR EACH language in translations:
FOR v_lang_code IN ('zh-Hant', 'ja', 'ko', ...)
LOOP
  -- Update embedded hash to match current card
  v_updated_translations := v_updated_translations || 
    jsonb_build_object(
      v_lang_code,
      v_translations[v_lang_code] || {
        'content_hash': 'NEW_HASH_123'  ← UPDATED!
      }
    );
END LOOP;

-- Save updated translations
UPDATE cards 
SET translations = v_updated_translations
WHERE id = p_card_id;
```

**After fix**:
```json
{
  "zh-Hant": {
    "name": "翻譯的名稱",
    "description": "翻譯的描述",
    "translated_at": "2025-01-13T10:30:00Z",
    "content_hash": "NEW_HASH_123"  ← NOW MATCHES!
  }
}
```

**Result**: Translation now shows as "Up to Date" ✅

### Step 5: Create Content Items
**Stored Procedure**: `create_content_item(...)`

For each content item (Layer 1, then Layer 2):

```javascript
const { data: itemId } = await supabase.rpc('create_content_item', {
  p_card_id: cardId,
  p_parent_id: parentId,  // null for Layer 1
  p_name: item.name,
  p_content: item.content,
  p_ai_knowledge_base: item.ai_knowledge_base,
  p_image_url: contentImageUrl,
  p_original_image_url: contentOriginalImageUrl,
  p_crop_parameters: contentCropParams
})
```

**Trigger fires**: `update_content_item_content_hash_trigger`  
Calculates: `md5(name || content)` → `ITEM_NEW_HASH_456`

### Step 6: Restore Content Item Translations
**Stored Procedure**: `update_content_item_translations_bulk(p_content_item_id, p_translations)`

```javascript
const itemTranslations = JSON.parse(item.translations_json)

await supabase.rpc('update_content_item_translations_bulk', {
  p_content_item_id: itemId,
  p_translations: itemTranslations
})
```

Same problem: OLD hashes from export.

### Step 7: ⭐ Recalculate Content Item Hashes
**Stored Procedure**: `recalculate_content_item_translation_hashes(p_content_item_id)`

```javascript
await supabase.rpc('recalculate_content_item_translation_hashes', {
  p_content_item_id: itemId
})
```

Updates embedded hashes to match newly created content item.

---

## 🔄 Translation Freshness Detection Logic

### How Status is Determined

**Function**: `get_card_translation_status(p_card_id)`

```sql
-- For each language:
CASE 
  WHEN lang = card.original_language 
    THEN 'original'
  
  WHEN card.translations ? lang THEN
    CASE
      -- Check if translation hash matches current card hash
      WHEN card.translations->lang->>'content_hash' = card.content_hash 
           AND all_content_items_up_to_date
        THEN 'up_to_date'  ✅
      ELSE 
        'outdated'  ⚠️
    END
  
  ELSE 
    'not_translated'
END
```

### Why Hash Recalculation is Critical

**Without recalculation**:
```
Import → New card hash: 'ABC'
         Translation hash: 'XYZ' (from old card)
         ABC ≠ XYZ → "Outdated" ❌
```

**With recalculation**:
```
Import → New card hash: 'ABC'
Restore translations → Hash still 'XYZ'
Recalculate → Update translation hash to 'ABC'
         ABC == ABC → "Up to Date" ✅
```

---

## 📋 Complete Stored Procedures Summary

### Export Phase
| Procedure | Purpose | Returns |
|-----------|---------|---------|
| `get_user_cards()` | Fetch all user's cards | Card data with translations |
| `get_card_content_items(card_id)` | Fetch content items | Items with translations |

### Import Phase
| Procedure | Purpose | When Called |
|-----------|---------|-------------|
| `create_card(...)` | Create new card | Step 2 - Basic card creation |
| `update_card_translations_bulk(card_id, translations)` | Restore card translations | Step 3 - After card created |
| `recalculate_card_translation_hashes(card_id)` | ⭐ Fix hash mismatch | Step 4 - After translations restored |
| `create_content_item(...)` | Create content item | Step 5 - For each item |
| `update_content_item_translations_bulk(item_id, translations)` | Restore item translations | Step 6 - After item created |
| `recalculate_content_item_translation_hashes(item_id)` | ⭐ Fix item hash mismatch | Step 7 - After item translations restored |

### Translation Status
| Procedure | Purpose | Used By |
|-----------|---------|---------|
| `get_card_translation_status(card_id)` | Get status for all languages | Translation Management UI |
| `get_card_translations(card_id, language)` | Get actual translations | Preview functionality |
| `delete_card_translation(card_id, language)` | Remove translation | User action |
| `get_translation_history(card_id)` | Audit trail | History view |
| `get_outdated_translations(card_id)` | List outdated languages | UI filtering |

---

## 🎯 Key Design Decisions

### 1. Two-Step Translation Import
**Why not import translations directly with card creation?**

- Card triggers need to run first to calculate base hash
- Cleaner separation of concerns
- Allows validation between steps
- Enables hash recalculation logic

### 2. JSONB Hidden Columns in Excel
**Why not separate sheets?**

- Single source of truth per entity
- Easier to maintain data relationships
- Hidden columns preserve technical data without confusing users
- Excel already handles JSONB serialization

### 3. Hash Recalculation Instead of Hash Preservation
**Why not export/import the content_hash directly?**

- Triggers auto-calculate hashes on INSERT/UPDATE
- Bypassing triggers is risky and complex
- Hash should reflect CURRENT content, not old content
- Recalculation is safer and follows database patterns

### 4. Per-Item Hash Recalculation
**Why not batch recalculate all at once?**

- Better error isolation (one item fails, others succeed)
- Progress tracking per item
- Easier debugging
- Matches granular import flow

---

## 🧪 Testing the Flow

### Verify Export
```sql
-- Check what get_user_cards returns
SELECT 
  name, 
  original_language,
  jsonb_object_keys(translations) as languages,
  content_hash
FROM cards 
WHERE id = 'your-card-id';
```

### Verify Import
```sql
-- After import, check hash alignment
SELECT 
  c.name,
  c.content_hash as card_hash,
  jsonb_object_keys(c.translations) as lang,
  c.translations->>'content_hash' as translation_hash
FROM cards c
WHERE c.id = 'newly-imported-card-id';

-- Should match!
```

---

## 💡 Summary

**Export**: Simple RPC calls → Excel with hidden JSONB  
**Import**: Create entities → Restore translations → **Recalculate hashes** ⭐  
**Result**: Perfect data preservation with correct translation status

The hash recalculation is the **critical innovation** that makes this work!

