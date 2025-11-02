# Translation Shows "Outdated" After Import - Root Cause Analysis

## Problem Description

**Scenario**: User imports a card → Translates it immediately → Translations show as "Outdated" 

**Expected**: Translations should show as "Up to Date"

## Diagnostic Steps

Let me help you diagnose the exact cause. Please check the following:

### Step 1: Check Database Content Hash Values

Run this query in Supabase SQL Editor:

```sql
-- Replace 'YOUR_CARD_ID' with the actual card ID
SELECT 
  c.id,
  c.name,
  c.content_hash as card_current_hash,
  c.translations->'zh-Hant'->>'content_hash' as zh_hant_stored_hash,
  c.translations->'zh-Hant'->>'content_hash' = c.content_hash as zh_hant_matches,
  c.last_content_update
FROM cards c
WHERE c.id = 'YOUR_CARD_ID';
```

**What to look for**:
- `card_current_hash`: The card's current content hash
- `zh_hant_stored_hash`: The hash stored in the translation
- `zh_hant_matches`: Should be TRUE if up-to-date

### Step 2: Check Content Items

```sql
-- Replace 'YOUR_CARD_ID' with the actual card ID
SELECT 
  ci.id,
  ci.name,
  ci.content_hash as item_current_hash,
  ci.translations->'zh-Hant'->>'content_hash' as zh_hant_stored_hash,
  ci.translations->'zh-Hant'->>'content_hash' = ci.content_hash as zh_hant_matches,
  ci.last_content_update
FROM content_items ci
WHERE ci.card_id = 'YOUR_CARD_ID'
ORDER BY ci.sort_order;
```

**What to look for**:
- ALL items should have `zh_hant_matches = TRUE`
- If any item has FALSE, that item is causing the "Outdated" status

## Possible Root Causes

Based on the code analysis, here are the possible causes:

### Cause 1: Hash Mismatch During Import ❌

**What happens**:
1. Card is imported with `content_hash = NULL` (not in Excel)
2. Trigger calculates hash on INSERT
3. User translates immediately
4. Translation stores the calculated hash
5. BUT - hash doesn't match for some reason

**Check**: Was the card imported WITH translations or WITHOUT?

**If WITH translations** (translations in Excel):
- Excel had old hash values
- Import preserved old hashes in translations
- New card got NEW hash from trigger
- Mismatch!

**If WITHOUT translations** (fresh translation):
- Should work correctly
- Hash should match

### Cause 2: Content Changed After Import ❌

**What happens**:
1. Card imported successfully
2. Content hash calculated
3. User made edits (name, description, content items)
4. Content hash updated
5. User clicked "Translate"
6. Translation stored with NEW hash
7. But content hash changed AGAIN somehow

**Check**: Did you edit ANY content after import but before translating?

### Cause 3: Trigger Recalculating Hash During Translation Storage ⚠️

**What happens**:
1. Translation Edge Function fetches card with `content_hash = "abc123"`
2. Translation created with hash `"abc123"`
3. `store_card_translations()` updates the card:
   ```sql
   UPDATE cards 
   SET translations = ..., updated_at = NOW()
   ```
4. UPDATE trigger fires!
5. **IF** name/description somehow changed, trigger recalculates hash
6. New hash = `"def456"`
7. Stored translation hash = `"abc123"` ≠ current hash `"def456"`

**This is the MOST LIKELY cause!**

### Cause 4: Content Items Hash Mismatch ⚠️

**Even if card translation is up-to-date**, if ANY content item has a hash mismatch, the entire translation shows as "Outdated".

The function checks:
```sql
bool_and(
  ci.translations ? sl.lang AND
  ci.translations->sl.lang->>'content_hash' = ci.content_hash
)
```

**If even ONE item fails this check, all_items_translated = FALSE → Outdated**

## Most Likely Scenario (Based on Import Flow)

### Scenario A: Card Imported WITHOUT Existing Translations

```
Step 1: Import Card
  ├─ Card data imported
  ├─ content_hash = NULL (not in Excel or not provided)
  ├─ Trigger calculates: content_hash = md5("CardName|CardDescription")
  └─ Card saved with calculated hash

Step 2: Import Content Items
  ├─ Item 1: content_hash = NULL
  ├─ Trigger calculates: hash1 = md5("Item1Name|Item1Content|...")
  ├─ Item 2: content_hash = NULL
  ├─ Trigger calculates: hash2 = md5("Item2Name|Item2Content|...")
  └─ All items saved

Step 3: User Clicks "Translate" (no edits made)
  ├─ Edge Function fetches card: content_hash = hash_A
  ├─ Edge Function fetches items: hash1, hash2, hash3
  ├─ Translation happens
  ├─ store_card_translations() called
  └─ Translations stored with hash_A, hash1, hash2, hash3

Step 4: Check Status
  ├─ Query card current hash: Should be hash_A
  ├─ Query translation stored hash: hash_A
  ├─ Should match! ✓
  
  🤔 But it shows "Outdated" - WHY?
```

## Debug Commands

### Command 1: Check Translation Storage Time vs Content Update Time

```sql
SELECT 
  c.id,
  c.name,
  c.last_content_update as content_last_modified,
  (c.translations->'zh-Hant'->>'translated_at')::timestamp as translation_created,
  (c.translations->'zh-Hant'->>'translated_at')::timestamp > c.last_content_update as translation_is_newer
FROM cards c
WHERE c.id = 'YOUR_CARD_ID';
```

**Expected**: `translation_is_newer = TRUE`  
**If FALSE**: Content was modified AFTER translation!

### Command 2: Manually Calculate Hash and Compare

```sql
SELECT 
  c.id,
  c.name,
  c.description,
  c.content_hash as stored_hash,
  md5(COALESCE(c.name, '') || '|' || COALESCE(c.description, '')) as calculated_hash,
  c.content_hash = md5(COALESCE(c.name, '') || '|' || COALESCE(c.description, '')) as hashes_match
FROM cards c
WHERE c.id = 'YOUR_CARD_ID';
```

**Expected**: `hashes_match = TRUE`  
**If FALSE**: Hash is corrupted or calculation is wrong!

### Command 3: Check Each Content Item

```sql
SELECT 
  ci.id,
  ci.name,
  ci.content_hash as stored_hash,
  md5(COALESCE(ci.name, '') || '|' || COALESCE(ci.content, '') || '|' || COALESCE(ci.ai_knowledge_base, '')) as calculated_hash,
  ci.translations->'zh-Hant'->>'content_hash' as translation_stored_hash,
  ci.content_hash = md5(COALESCE(ci.name, '') || '|' || COALESCE(ci.content, '') || '|' || COALESCE(ci.ai_knowledge_base, '')) as hash_valid,
  ci.translations->'zh-Hant'->>'content_hash' = ci.content_hash as translation_matches
FROM content_items ci
WHERE ci.card_id = 'YOUR_CARD_ID'
ORDER BY ci.sort_order;
```

**Check ALL rows**: If ANY row has `translation_matches = FALSE`, that's the culprit!

### Command 4: View Edge Function Logs

```bash
# Check what hashes the Edge Function used
npx supabase functions logs translate-card-content --project-ref YOUR_PROJECT_REF
```

Look for log entries showing the translation process.

## Quick Fix: Retranslate

The fastest solution is to simply retranslate:

1. Go to the card
2. Click "Manage Translations"
3. Select the language showing as "Outdated"
4. Click "Translate"
5. It should now show "Up to Date"

## Permanent Fix: Ensure Hash Consistency

### Fix 1: Update Import to Include Content Hash

**File**: `src/components/Card/Import/CardBulkImport.vue`

Ensure that when exporting/importing:
1. Export includes `content_hash` in hidden column ✓ (already done)
2. Import reads `content_hash` and passes to `create_card()` ✓ (already done)
3. Trigger respects provided hash ✓ (already done)

### Fix 2: Verify Trigger Logic

**File**: `sql/triggers.sql`

The triggers should:
- On INSERT: Only calculate if hash is NULL ✓
- On UPDATE: Only recalculate if content changed AND hash wasn't manually set ✓

**Current implementation looks correct!**

### Fix 3: Add Logging to Edge Function

Add logging to see what hashes are being used:

```typescript
// In translate-card-content/index.ts
console.log('Card content_hash:', cardData.content_hash);
console.log('Content items hashes:', contentItems?.map(i => ({
  id: i.id,
  name: i.name,
  hash: i.content_hash
})));

// After storing
console.log('Stored translations with card hash:', cardData.content_hash);
console.log('Stored translations with item hashes:', contentItemsTranslations);
```

## Action Plan

1. **Run the diagnostic queries above** to identify the exact mismatch
2. **Share the results** - which query shows FALSE or mismatched hashes?
3. **Check timing** - did content update after translation?
4. **Verify import source** - did Excel have old translation hashes?

## Expected Results from Queries

If everything is working correctly:

**Query 1 (Card)**:
```
zh_hant_matches: TRUE
```

**Query 2 (Content Items)**:
```
ALL rows: translation_matches = TRUE
```

**Query 3 (Timing)**:
```
translation_is_newer: TRUE
```

**Query 4 (Hash Validation)**:
```
Card: hashes_match = TRUE
ALL items: hash_valid = TRUE
```

## Please Run These Queries

Can you run the diagnostic queries above and share:
1. The card ID you're testing with
2. The results of Query 1 (card hash check)
3. The results of Query 2 (content items hash check)
4. Whether you edited anything after import but before translating

This will help us pinpoint the exact cause!

---

**Status**: Awaiting diagnostic results  
**Next Steps**: Based on query results, we'll implement the specific fix needed


