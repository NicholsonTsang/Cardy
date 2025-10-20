# 📊 Excel Translations - Where Are They?

## ✅ You're Correct! Translations ARE in Excel

The translated content **IS exported and imported** successfully. You just can't see it because it's in **HIDDEN columns**!

---

## 🔍 Where Translated Content is Stored

### Cards Sheet

| Column | Letter | Field Name | Width | Visible? | Contains |
|--------|--------|------------|-------|----------|----------|
| 1 | A | Name | 25 | ✅ Visible | **Original language** name only |
| 2 | B | Description | 40 | ✅ Visible | **Original language** description only |
| 3 | C | AI Instruction | 30 | ✅ Visible | Original language only |
| 4 | D | AI Knowledge Base | 45 | ✅ Visible | Original language only |
| 5 | E | Original Language | 15 | ✅ Visible | Language code (en, zh-Hant, etc.) |
| 6 | F | AI Enabled | 15 | ✅ Visible | true/false |
| 7 | G | QR Position | 15 | ✅ Visible | TL/TR/BL/BR |
| 8 | H | Card Image | 25 | ✅ Visible | Embedded image |
| 9 | I | Crop Data | **0** | ❌ HIDDEN | Crop parameters JSON |
| 10 | **J** | **Translations** | **0** | ❌ **HIDDEN** | **ALL translations for ALL languages!** |
| 11 | K | Content Hash | **0** | ❌ HIDDEN | MD5 hash for tracking |

**👉 Translated content is in Column J (Hidden)**

---

### Content Items Sheet

| Column | Letter | Field Name | Width | Visible? | Contains |
|--------|--------|------------|-------|----------|----------|
| 1 | A | Name | 30 | ✅ Visible | **Original language** name only |
| 2 | B | Content | 50 | ✅ Visible | **Original language** content only |
| 3 | C | AI Knowledge Base | 35 | ✅ Visible | Original language only |
| 4 | D | Sort Order | 12 | ✅ Visible | Integer |
| 5 | E | Layer | 12 | ✅ Visible | Layer 1/Layer 2 |
| 6 | F | Parent Reference | 18 | ✅ Visible | Cell reference (A5, etc.) |
| 7 | G | Image | 25 | ✅ Visible | Embedded image |
| 8 | H | Crop Data | **0** | ❌ HIDDEN | Crop parameters JSON |
| 9 | **I** | **Translations** | **0** | ❌ **HIDDEN** | **ALL translations for ALL languages!** |
| 10 | J | Content Hash | **0** | ❌ HIDDEN | MD5 hash for tracking |

**👉 Translated content is in Column I (Hidden)**

---

## 🎯 Why You Can't See Translations

### Design Decision: Hidden Columns
We hide these columns because:
1. **JSON format** - Not human-readable in cells
2. **Too wide** - Would make Excel unwieldy
3. **Technical data** - Users shouldn't manually edit
4. **Automatic management** - System handles these fields

### What Visible Columns Show
The **visible columns (A, B, etc.) ONLY show the ORIGINAL language content**:
- Column A (Name) = Card name in **original language only**
- Column B (Description) = Description in **original language only**
- Column B (Content) = Content in **original language only**

**Translations are NOT duplicated as separate visible columns!**

---

## 📋 Translation Data Format

### Example: Card with English + Chinese Translations

**Visible Columns:**
- Column A (Name): "Museum Card" ← Original language (en)
- Column E (Original Language): "en"

**Hidden Column J (Translations):**
```json
{
  "zh-Hant": {
    "name": "博物館卡片",
    "description": "這是一張博物館導覽卡片",
    "translated_at": "2024-01-15T10:30:00Z",
    "content_hash": "abc123def456"
  },
  "ja": {
    "name": "博物館カード",
    "description": "これは博物館ガイドカードです",
    "translated_at": "2024-01-15T10:35:00Z",
    "content_hash": "abc123def456"
  }
}
```

**This JSON contains:**
- ✅ Translated name in Chinese
- ✅ Translated description in Chinese
- ✅ Translated name in Japanese
- ✅ Translated description in Japanese
- ✅ Translation timestamps
- ✅ Content hashes for freshness tracking

---

## 🔓 How to View Hidden Translations

### Method 1: Unhide Columns in Excel

**For Cards Sheet:**
1. Open exported Excel file
2. Right-click on column header **I**
3. Select column **I**, **J**, and **K** (hold Shift)
4. Right-click → **Unhide**
5. Column J will appear showing translations JSON

**For Content Items Sheet:**
1. Open exported Excel file
2. Right-click on column header **H**
3. Select column **H**, **I**, and **J** (hold Shift)
4. Right-click → **Unhide**
5. Column I will appear showing translations JSON

### Method 2: Change Column Width Programmatically
Edit `src/utils/excelHandler.js`:

**Cards:**
```javascript
{ width: 0 },  // Crop Data (hidden)
{ width: 0 },  // Translations (hidden) ← Change to 50
{ width: 0 }   // Content Hash (hidden)
```

**Content Items:**
```javascript
{ width: 0 },  // Crop Data (hidden)
{ width: 0 },  // Translations (hidden) ← Change to 50
{ width: 0 }   // Content Hash (hidden)
```

---

## ✅ Import Process Confirmation

### How Translations are Restored

**Cards Import (`CardBulkImport.vue`):**
```javascript
// 1. Parse translations JSON from Column J
let translationsData = null;
if (importData.cardData.translations_json) {
  translationsData = JSON.parse(importData.cardData.translations_json);
}

// 2. Pass to create_card stored procedure
await supabase.rpc('create_card', {
  p_name: importData.cardData.name,
  p_description: importData.cardData.description,
  p_translations: translationsData,  // ← Translations restored here!
  ...
})
```

**Content Items Import:**
```javascript
// 1. Parse translations JSON from Column I
let itemTranslations = null;
if (item.translations_json) {
  itemTranslations = JSON.parse(item.translations_json);
}

// 2. Pass to create_content_item stored procedure
await supabase.rpc('create_content_item', {
  p_name: item.name,
  p_content: item.content,
  p_translations: itemTranslations,  // ← Translations restored here!
  ...
})
```

---

## 🎨 Visual Example

### What You See in Excel (Default)

```
┌─────────────┬──────────────┬────────┬─────┬────────┐
│ A: Name     │ B: Desc      │ C: AI  │ ... │ H: Img │
├─────────────┼──────────────┼────────┼─────┼────────┤
│ Museum Card │ Welcome to...│ You... │ ... │ [IMG]  │
└─────────────┴──────────────┴────────┴─────┴────────┘
                                          ^
                                          |
                    Columns I, J, K are HIDDEN here!
                    (width: 0, not visible)
```

### What's Actually There (After Unhide)

```
┌─────────────┬──────────┬────┬────────┬──────────────────┬────────┐
│ A: Name     │ B: Desc  │... │ H: Img │ J: Translations  │ K:Hash │
├─────────────┼──────────┼────┼────────┼──────────────────┼────────┤
│ Museum Card │ Welcome..│... │ [IMG]  │ {"zh-Hant":{...}}│ abc123 │
└─────────────┴──────────┴────┴────────┴──────────────────┴────────┘
                                        ^                    ^
                                        |                    |
                               ALL translations here!    Content hash
```

---

## 🤔 Why Not Show Translations as Separate Columns?

### Option 1: Current Design (Hidden JSON) ✅
**Pros:**
- Compact file
- All languages in one column
- Easy to add new languages without schema changes
- Preserves all metadata (timestamps, hashes)

**Cons:**
- Not human-readable without unhiding
- JSON format in cell

### Option 2: Separate Columns for Each Language ❌
```
| Name (en) | Name (zh-Hant) | Name (ja) | Description (en) | Description (zh-Hant) | ...
```

**Cons:**
- File becomes HUGE (8+ visible columns → 80+ columns with 10 languages!)
- Adding new language requires schema change
- Loses metadata (timestamps, hashes)
- Complex to maintain

**We chose Option 1 for efficiency and maintainability.**

---

## 📊 Summary

### Question: "Why I don't see translated content?"
**Answer**: Translations ARE there, but in **HIDDEN columns**!

### Cards Sheet:
- **Column J** (Hidden) = All translations in JSON format
- **Column A-H** (Visible) = Original language content only

### Content Items Sheet:
- **Column I** (Hidden) = All translations in JSON format
- **Column A-G** (Visible) = Original language content only

### To View Translations:
1. **Unhide Column J** (Cards) or **Column I** (Content Items)
2. See JSON with ALL language translations
3. Import automatically reads and restores this JSON

### Import Confirmation:
✅ Translations ARE imported correctly via `p_translations` parameter
✅ All language versions restored to database
✅ Translation freshness preserved via content_hash

---

## 🎯 You Were Right!

Your observation was correct:
- ✅ You **don't see** translated content in visible columns
- ✅ But import **still has** translated content
- ✅ Because translations are in **HIDDEN Column J (Cards) / Column I (Content Items)**

The system is working as designed! Just unhide the columns to see the JSON data. 👍

