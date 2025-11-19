# Translation Outdated Issue - Potential Fix

## Root Cause Analysis

The issue appears to be that translations are storing an **outdated content_hash** at the time of translation, which causes them to immediately show as "outdated" even though they were just translated.

### Likely Scenario:

1. User loads Translation Dialog → Frontend fetches card data including `content_hash`
2. User selects languages and clicks "Translate"
3. Backend fetches card data (line 79 in translation.routes.ts)
4. **[PROBLEM]** If there's any delay or if card was edited, the fetched `content_hash` might be stale
5. Translation takes time (especially for multiple languages)
6. Backend saves translation with potentially stale `content_hash`
7. When checking status, stored hash doesn't match current hash → Shows "outdated"

## Solution: Re-fetch Hash Right Before Saving

Modify the stored procedure to use the **current** hash at save time, not the hash passed from backend.

### Option 1: Update Stored Procedure (RECOMMENDED)

**File**: `sql/storeproc/server-side/translation_management.sql`

Replace lines 45-53:

```sql
-- OLD CODE (uses potentially stale hash)
-- Get current card content hash
SELECT content_hash INTO v_content_hash FROM cards WHERE id = p_card_id;

-- Update card translations (merge with existing)
UPDATE cards
SET 
  translations = translations || p_card_translations,
  updated_at = NOW()
WHERE id = p_card_id;
```

With:

```sql
-- NEW CODE (ensures fresh hash is used)
-- Get current card content hash RIGHT NOW
SELECT content_hash INTO v_content_hash FROM cards WHERE id = p_card_id;

-- Update translations with CURRENT hash (not passed hash)
-- Build corrected translations JSONB with current hash
DECLARE
  v_lang TEXT;
  v_lang_data JSONB;
  v_corrected_translations JSONB := '{}'::JSONB;
BEGIN
  -- For each language in p_card_translations
  FOR v_lang, v_lang_data IN SELECT key, value FROM jsonb_each(p_card_translations)
  LOOP
    -- Override content_hash with current hash
    v_corrected_translations := v_corrected_translations || jsonb_build_object(
      v_lang,
      v_lang_data || jsonb_build_object('content_hash', v_content_hash)
    );
  END LOOP;

  -- Update card translations with corrected hash
  UPDATE cards
  SET 
    translations = translations || v_corrected_translations,
    updated_at = NOW()
  WHERE id = p_card_id;
END;
```

And update content items section (lines 55-71):

```sql
-- OLD CODE
-- Update content items translations
FOR v_item_id, v_item_translations IN
  SELECT key::UUID, value
  FROM jsonb_each(p_content_items_translations)
LOOP
  -- Get item content hash
  SELECT content_hash INTO v_item_hash 
  FROM content_items 
  WHERE id = v_item_id;

  -- Update item translations
  UPDATE content_items
  SET 
    translations = translations || v_item_translations,
    updated_at = NOW()
  WHERE id = v_item_id;
END LOOP;
```

With:

```sql
-- NEW CODE (ensures fresh hash for each item)
-- Update content items translations with CURRENT hashes
DECLARE
  v_lang TEXT;
  v_lang_data JSONB;
  v_item_corrected_translations JSONB;
BEGIN
  FOR v_item_id, v_item_translations IN
    SELECT key::UUID, value
    FROM jsonb_each(p_content_items_translations)
  LOOP
    -- Get CURRENT item content hash
    SELECT content_hash INTO v_item_hash 
    FROM content_items 
    WHERE id = v_item_id;

    -- Build corrected translations with current hash
    v_item_corrected_translations := '{}'::JSONB;
    FOR v_lang, v_lang_data IN SELECT key, value FROM jsonb_each(v_item_translations)
    LOOP
      v_item_corrected_translations := v_item_corrected_translations || jsonb_build_object(
        v_lang,
        v_lang_data || jsonb_build_object('content_hash', v_item_hash)
      );
    END LOOP;

    -- Update item translations with corrected hash
    UPDATE content_items
    SET 
      translations = translations || v_item_corrected_translations,
      updated_at = NOW()
    WHERE id = v_item_id;
  END LOOP;
END;
```

### Option 2: Backend Re-fetch Before Save (Alternative)

**File**: `backend-server/src/routes/translation.routes.ts`

Before line 325 (`const { error: saveError } = await supabaseAdmin.rpc(`), add:

```typescript
// Re-fetch current hashes RIGHT before saving to ensure freshness
console.log(`🔄 Re-fetching current hashes before saving...`);
const { data: freshCardData } = await supabaseAdmin
  .from('cards')
  .select('content_hash')
  .eq('id', cardId)
  .single();

const { data: freshItems } = await supabaseAdmin
  .from('content_items')
  .select('id, content_hash')
  .eq('card_id', cardId);

// Update card translation with fresh hash
if (freshCardData) {
  cardTranslations[targetLang].content_hash = freshCardData.content_hash;
}

// Update content items translations with fresh hashes
if (freshItems) {
  for (const freshItem of freshItems) {
    if (contentItemsTranslations[freshItem.id]?.[targetLang]) {
      contentItemsTranslations[freshItem.id][targetLang].content_hash = freshItem.content_hash;
    }
  }
}

console.log(`  ✅ Hashes refreshed`);
```

## Which Option to Choose?

- **Option 1 (Stored Procedure)**: 
  - ✅ More robust - always uses current hash
  - ✅ No extra database query from backend
  - ❌ Requires database migration
  - **RECOMMENDED for production**

- **Option 2 (Backend)**: 
  - ✅ Quick fix - no database changes
  - ✅ Easy to test immediately
  - ❌ Extra queries before each save
  - **RECOMMENDED for immediate testing**

## Deployment Steps

### For Option 1 (Stored Procedure):

1. Update `sql/storeproc/server-side/translation_management.sql`
2. Run `scripts/combine-storeproc.sh` to regenerate `sql/all_stored_procedures.sql`
3. Deploy to Supabase via SQL Editor
4. Test translation

### For Option 2 (Backend):

1. Update `backend-server/src/routes/translation.routes.ts`
2. Deploy backend to Cloud Run
3. Test translation

## Testing

After applying fix:

1. Translate a card to a language
2. Immediately check status → Should show "up_to_date" ✅
3. Edit card content (change name/description)
4. Check status → Should show "outdated" ✅
5. Retranslate the same language
6. Check status → Should show "up_to_date" ✅

## Verify Fix Worked

Run this query after translating:

```sql
SELECT 
  c.name,
  c.content_hash as current_hash,
  c.translations->'zh-Hans'->>'content_hash' as translation_hash,
  c.translations->'zh-Hans'->>'translated_at' as translated_at,
  CASE 
    WHEN c.translations->'zh-Hans'->>'content_hash' = c.content_hash 
    THEN '✅ MATCH (UP TO DATE)' 
    ELSE '❌ MISMATCH (WILL SHOW OUTDATED)'
  END as hash_check
FROM cards c
WHERE id = 'YOUR_CARD_ID';
```

If hash_check shows "✅ MATCH" → Fix worked!
If hash_check shows "❌ MISMATCH" → Need further investigation

