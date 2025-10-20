# Debug Translation Issue - Step by Step

## 🔍 Issue: Outdated Languages Not Retranslating, Credits Not Deducted

The edge function has been deployed, but translations aren't working. Let's debug systematically.

## Step 1: Check Database Triggers (CRITICAL)

Run this in **Supabase Dashboard → SQL Editor**:

```sql
-- Check if triggers exist
SELECT 
    tgname AS trigger_name,
    tgenabled AS enabled,
    tgrelid::regclass AS table_name
FROM pg_trigger 
WHERE tgname LIKE '%content_hash%';
```

### Expected Result:
```
trigger_name                             | enabled | table_name
-----------------------------------------|---------|-----------------
trigger_update_card_content_hash         | O       | cards
trigger_update_content_item_content_hash | O       | content_items
```

### If You Get 0 Rows:
**This is the problem!** Triggers haven't been deployed.

**Fix**:
1. Open Supabase Dashboard → SQL Editor
2. Copy entire contents of `sql/triggers.sql`
3. Paste and click "Run"
4. Copy entire contents of `sql/all_stored_procedures.sql`
5. Paste and click "Run"
6. Re-run the check query above

---

## Step 2: Verify Content Hash Changes

**Pick a card ID** from your database and run these queries:

```sql
-- Replace YOUR_CARD_ID with actual card ID
SET @card_id = 'YOUR_CARD_ID';

-- 1. Check current state
SELECT 
    id,
    name,
    content_hash,
    translations->'zh-Hant'->>'content_hash' as zh_translation_hash,
    CASE 
        WHEN translations->'zh-Hant'->>'content_hash' = content_hash 
        THEN 'UP_TO_DATE' 
        ELSE 'OUTDATED' 
    END as status
FROM cards 
WHERE id = 'YOUR_CARD_ID';
```

**What to look for**:
- `content_hash`: Current hash of the card
- `zh_translation_hash`: Hash stored in the translation
- `status`: Should be `OUTDATED` if they don't match

### If status is OUTDATED but retranslation doesn't work:
This means triggers are working, but the edge function has an issue.

### If status is UP_TO_DATE even though you edited the card:
This means triggers are NOT working or not deployed.

---

## Step 3: Test Hash Update Manually

```sql
-- Get current hash
SELECT id, name, content_hash 
FROM cards 
WHERE id = 'YOUR_CARD_ID';

-- Update the card (this should trigger hash recalculation)
UPDATE cards 
SET name = TRIM(name) || ' TEST'
WHERE id = 'YOUR_CARD_ID';

-- Check if hash changed
SELECT id, name, content_hash 
FROM cards 
WHERE id = 'YOUR_CARD_ID';
```

**Expected**: The `content_hash` value should be DIFFERENT after the update.

**If hash didn't change**: Triggers are not working → Deploy `sql/triggers.sql`

---

## Step 4: Check Edge Function Response

1. Open browser **DevTools** → **Network** tab
2. Try to translate an outdated language
3. Find the request to: `translate-card-content`
4. Check the **Response** tab

### Expected Response (Working):
```json
{
  "success": true,
  "translated_languages": ["zh-Hant"],
  "credits_used": 1,
  "remaining_balance": 99
}
```

### Problem Response (Not Working):
```json
{
  "success": true,
  "message": "All selected languages are already up-to-date",
  "translated_languages": [],
  "credits_used": 0,
  "remaining_balance": 100
}
```

**If you see the "problem response"**:
The edge function thinks the languages are up-to-date. This means:
1. Either the hash comparison is wrong
2. Or the database data is wrong

---

## Step 5: Check Edge Function Logs

### Option A: Supabase Dashboard
1. Go to Supabase Dashboard
2. Click on your project
3. Go to **Edge Functions** → **translate-card-content**
4. Click on **Logs** tab
5. Try translation again
6. Look for log messages

### Option B: Browser Console
The edge function console.logs should appear in browser console in some cases.

**Look for these messages**:
- ✅ `Translating 1 languages in parallel...` → Good, working
- ❌ `All selected languages are already up-to-date` → Problem, filtering wrong
- ❌ `Translation for zh-Hant is up-to-date, skipping...` → Hash comparison wrong

---

## Step 6: Manual Hash Comparison

Run this query to see exactly what's being compared:

```sql
SELECT 
    c.id,
    c.name,
    c.content_hash as card_current_hash,
    jsonb_pretty(c.translations) as translations_full,
    c.translations->'zh-Hant'->>'content_hash' as zh_hant_stored_hash,
    c.translations->'zh-Hant'->>'translated_at' as zh_hant_translated_at,
    CASE 
        WHEN c.translations->'zh-Hant'->>'content_hash' = c.content_hash 
        THEN 'MATCH (up-to-date)' 
        ELSE 'MISMATCH (outdated)' 
    END as hash_comparison
FROM cards c
WHERE id = 'YOUR_CARD_ID';
```

**What this tells you**:
- `card_current_hash`: What the edge function will compare against
- `zh_hant_stored_hash`: What's stored in the translation
- `hash_comparison`: Whether they match

**If MISMATCH but still not translating**:
The edge function isn't seeing the right data. Possible causes:
1. Frontend is caching old data
2. Database read is stale
3. Edge function is looking at wrong field

---

## 🎯 Most Likely Scenarios

### Scenario A: Triggers Not Deployed (90% likely)
**Symptoms**:
- Edit card but translations never show "Outdated"
- Content hash doesn't change after update
- Step 1 query returns 0 rows

**Fix**: Deploy `sql/triggers.sql` in Supabase Dashboard

### Scenario B: Triggers Deployed But Not Firing
**Symptoms**:
- Step 1 shows 2 triggers
- But hash doesn't change in Step 3

**Fix**: 
```sql
-- Drop and recreate triggers
DROP TRIGGER IF EXISTS trigger_update_card_content_hash ON cards;
DROP TRIGGER IF EXISTS trigger_update_content_item_content_hash ON content_items;

-- Then re-run sql/triggers.sql
```

### Scenario C: Frontend Cache Issue
**Symptoms**:
- Everything works in SQL queries
- But frontend doesn't show outdated status

**Fix**: Hard refresh browser (Cmd+Shift+R or Ctrl+Shift+R)

---

## 📋 Debugging Checklist

Run these in order and note the results:

- [ ] Step 1: Triggers exist? (Should be 2)
  - Result: _____________

- [ ] Step 2: Hash comparison shows OUTDATED?
  - Result: _____________

- [ ] Step 3: Hash changes after manual update?
  - Before: _____________
  - After: _____________

- [ ] Step 4: Edge function response?
  - Result: _____________

- [ ] Step 5: Edge function logs?
  - Message: _____________

- [ ] Step 6: Manual hash comparison?
  - card_current_hash: _____________
  - zh_hant_stored_hash: _____________
  - Match?: _____________

---

## 🚨 Quick Diagnostic

Run this ALL-IN-ONE diagnostic query:

```sql
-- Replace with your card ID
WITH card_info AS (
  SELECT 
    id,
    name,
    content_hash,
    translations,
    updated_at
  FROM cards 
  WHERE id = 'YOUR_CARD_ID'
)
SELECT 
  'Card Info' as check_type,
  json_build_object(
    'card_id', ci.id,
    'card_name', ci.name,
    'current_hash', ci.content_hash,
    'has_translations', ci.translations IS NOT NULL,
    'translation_count', jsonb_object_keys(ci.translations),
    'last_updated', ci.updated_at
  ) as result
FROM card_info ci

UNION ALL

SELECT 
  'Trigger Check',
  json_build_object(
    'triggers_found', COUNT(*),
    'trigger_names', array_agg(tgname)
  )
FROM pg_trigger 
WHERE tgname LIKE '%content_hash%'

UNION ALL

SELECT 
  'Translation Status',
  json_build_object(
    'language', lang_key,
    'translation_hash', ci.translations->lang_key->>'content_hash',
    'current_hash', ci.content_hash,
    'matches', ci.translations->lang_key->>'content_hash' = ci.content_hash
  )
FROM card_info ci,
     jsonb_object_keys(ci.translations) as lang_key;
```

This will show you:
1. Card info
2. Trigger count
3. Translation status for each language

Share these results if you need more help!


