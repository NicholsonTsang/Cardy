# Translation Debug Checklist
**Date:** November 2, 2025  
**Issue:** Content items showing original language instead of translated language

---

## 🔍 **Problem Description**

User reports that:
- ✅ Content item **titles/names** ARE translated correctly
- ❌ Content item **descriptions/content** are NOT translated (showing original language)

---

## 📊 **Code Review Results**

### ✅ Backend Translation (Correct)
**File:** `backend-server/src/routes/translation.routes.ts`

**Lines 367-371** - Translation prompt includes BOTH fields:
```typescript
${data.contentItems.map((item, idx) => `
Item ${idx + 1} (ID: ${item.id}):
- Name: ${item.name}          // ✅ Included
- Content: ${item.content}     // ✅ Included
`).join('\n')}
```

**Lines 244-246** - Storage includes BOTH fields:
```typescript
contentItemsTranslations[item.id][targetLang] = {
  name: item.name,         // ✅ Stored
  content: item.content,   // ✅ Stored
  translated_at: new Date().toISOString(),
  content_hash: originalItem?.content_hash || '',
};
```

### ✅ Database Storage (Correct)
**File:** `sql/all_stored_procedures.sql`

**Lines 5605-5609** - Content items translations merged:
```sql
UPDATE content_items
SET 
  translations = translations || v_item_translations,  -- ✅ Merges all translation fields
  updated_at = NOW()
WHERE id = v_item_id;
```

### ✅ Mobile Client Fetching (Correct)
**File:** `sql/storeproc/client-side/07_public_access.sql`

**Lines 96-97** - Both fields fetched with translation fallback:
```sql
COALESCE(ci.translations->p_language->>'name', ci.name)::TEXT AS content_item_name,      -- ✅ Translated
COALESCE(ci.translations->p_language->>'content', ci.content)::TEXT AS content_item_content,  -- ✅ Translated
```

---

## 🧪 **Debug Steps**

### Step 1: Check Backend Response
Add logging to verify translation response:

```typescript
// In translation.routes.ts after line 227
console.log('✅ Translation result sample:', {
  language: targetLang,
  firstItem: translationResponse.contentItems[0] ? {
    id: translationResponse.contentItems[0].id,
    name: translationResponse.contentItems[0].name.substring(0, 50),
    content: translationResponse.contentItems[0].content.substring(0, 100),
  } : null
});
```

### Step 2: Check Database Storage
After translation, query the database:

```sql
SELECT 
  id,
  name,
  content,
  translations->'zh-Hans'->>'name' as translated_name,
  translations->'zh-Hans'->>'content' as translated_content,
  translations->'zh-Hans'->>'content_hash' as trans_hash,
  content_hash as current_hash
FROM content_items
WHERE card_id = 'YOUR_CARD_ID'
LIMIT 1;
```

**Expected:**
- `translated_name` should have Chinese text
- `translated_content` should have Chinese text
- Both hashes should match

### Step 3: Check Mobile Client API Response
Add console log in PublicCardView.vue or check network tab:

```javascript
// Check what the mobile receives
console.log('Content item sample:', {
  name: items[0].content_item_name,
  content: items[0].content_item_content,
  language: currentLanguage
});
```

---

## 🎯 **Possible Root Causes**

### 1. Translation Response is Empty
**Symptom:** `content` field in translation is empty string  
**Check:** Look for debug logs showing `contentLength: 0`  
**Fix:** Already applied - added `reasoning_effort: 'low'` and 120K tokens

### 2. JSON Parsing Issue
**Symptom:** Translation succeeds but content field gets lost during parsing  
**Check:** Look for parsing errors in logs  
**Fix:** Check JSON structure returned by GPT

### 3. Database Column Name Mismatch
**Symptom:** Wrong field being stored  
**Check:** Verify column names in stored procedure  
**Status:** ✅ Checked - column names are correct

### 4. Language Selection Issue
**Symptom:** Mobile requesting wrong language or defaulting to original  
**Check:** Verify `p_language` parameter in mobile API call  
**Fix:** Check language selector state

---

## 🔬 **Quick Test Script**

Run this to check if translations are actually in database:

```sql
-- Replace with your card ID
DO $$
DECLARE
  v_card_id UUID := '12345678-1234-1234-1234-123456789012';
  v_language TEXT := 'zh-Hans';
  v_item RECORD;
BEGIN
  RAISE NOTICE 'Checking translations for card %', v_card_id;
  
  FOR v_item IN 
    SELECT 
      id,
      name as original_name,
      content as original_content,
      translations->v_language->>'name' as trans_name,
      translations->v_language->>'content' as trans_content,
      length(content) as orig_length,
      length(translations->v_language->>'content') as trans_length
    FROM content_items
    WHERE card_id = v_card_id
    LIMIT 3
  LOOP
    RAISE NOTICE '---';
    RAISE NOTICE 'Item ID: %', v_item.id;
    RAISE NOTICE 'Original name: %', left(v_item.original_name, 50);
    RAISE NOTICE 'Translated name: %', left(v_item.trans_name, 50);
    RAISE NOTICE 'Original content length: %', v_item.orig_length;
    RAISE NOTICE 'Translated content length: %', v_item.trans_length;
    RAISE NOTICE 'Trans content preview: %', left(v_item.trans_content, 100);
  END LOOP;
END $$;
```

---

## ✅ **Expected Behavior**

When translation works correctly:

1. **Backend logs show:**
   ```
   ✅ Completed translation to Traditional Chinese
   OpenAI Response structure: {
     "contentLength": 25000  // > 0
     "finishReason": "stop"   // not "length"
   }
   ```

2. **Database contains:**
   ```json
   {
     "zh-Hans": {
       "name": "翻译的标题",
       "content": "翻译的内容...",
       "content_hash": "abc123",
       "translated_at": "2025-11-02T..."
     }
   }
   ```

3. **Mobile receives:**
   ```json
   {
     "content_item_name": "翻译的标题",
     "content_item_content": "翻译的内容..."
   }
   ```

---

## 🚨 **If Issue Persists**

### Check 1: Verify Translation Actually Happened
```bash
# Check backend logs for successful translation
grep "Completed translation" logs.txt
grep "contentLength" logs.txt
```

### Check 2: Verify Database Has Translations
```sql
-- Count how many items have translations
SELECT 
  card_id,
  COUNT(*) as total_items,
  COUNT(CASE WHEN translations ? 'zh-Hans' THEN 1 END) as translated_items
FROM content_items
WHERE card_id = 'YOUR_CARD_ID'
GROUP BY card_id;
```

### Check 3: Verify Mobile Is Getting Translations
```javascript
// In browser console on mobile view
fetch('/api/card/YOUR_CARD_ID?language=zh-Hans')
  .then(r => r.json())
  .then(data => {
    console.log('First item:', {
      name: data[0].content_item_name,
      content: data[0].content_item_content.substring(0, 100),
      language: data[0].card_original_language
    });
  });
```

---

## 📋 **Action Items**

1. [ ] Check if translation completed successfully (backend logs)
2. [ ] Query database to verify translations are stored
3. [ ] Check mobile API response to see what's being fetched
4. [ ] Verify language selection on mobile client
5. [ ] Check for any caching issues (clear browser cache)
6. [ ] Verify content_hash matching (translation not marked as outdated)

---

**Status:** Waiting for debugging information  
**Next Steps:** Deploy latest fixes and run debug checks



