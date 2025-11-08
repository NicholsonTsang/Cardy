# Translation Outdated Status Debug Guide

**Issue**: Translations keep showing as "outdated" even after retranslating

## Investigation Steps

### 1. Check Current Hash vs Stored Hash in Translation

Run this query in Supabase SQL Editor to see the actual hash values:

```sql
-- Replace 'YOUR_CARD_ID' with the actual card ID having issues
SELECT 
  id,
  name,
  content_hash as current_card_hash,
  translations->'zh-Hans'->>'content_hash' as stored_translation_hash,
  translations->'zh-Hans'->>'translated_at' as translation_date,
  CASE 
    WHEN translations->'zh-Hans'->>'content_hash' = content_hash 
    THEN 'UP_TO_DATE' 
    ELSE 'OUTDATED'
  END as status_check
FROM cards 
WHERE id = 'YOUR_CARD_ID';
```

### 2. Check Content Items Hashes

```sql
-- Check all content items for a card
SELECT 
  id,
  name,
  content_hash as current_hash,
  translations->'zh-Hans'->>'content_hash' as stored_hash,
  translations->'zh-Hans'->>'translated_at' as translation_date,
  CASE 
    WHEN translations->'zh-Hans'->>'content_hash' = content_hash 
    THEN 'MATCH' 
    ELSE 'MISMATCH'
  END as hash_status
FROM content_items 
WHERE card_id = 'YOUR_CARD_ID'
ORDER BY sort_order;
```

### 3. Check What Backend Sends During Translation

Add temporary logging in `backend-server/src/routes/translation.routes.ts` around line 273:

```typescript
// Before saving
console.log('🔍 DEBUG - Card translation data:');
console.log('  Current card hash:', cardData.content_hash);
console.log('  Saving translation with hash:', cardData.content_hash);
console.log('  Full translation object:', JSON.stringify(cardTranslations, null, 2));
```

And around line 297:

```typescript
console.log('🔍 DEBUG - Content item translation:');
console.log('  Item ID:', originalItem.id);
console.log('  Current item hash:', originalItem.content_hash);
console.log('  Saving with hash:', originalItem.content_hash || 'EMPTY!');
```

## Common Issues and Fixes

### Issue 1: Backend Fetches Stale Hash (Race Condition)

**Symptom**: Hash in translation doesn't match current hash
**Cause**: Card/content updated DURING translation
**Fix**: Use database transaction or re-fetch hash before saving

### Issue 2: Null/Empty Content Hash

**Symptom**: `stored_translation_hash` is NULL or empty string
**Cause**: `originalItem.content_hash` is NULL when fetched
**Fix**: Ensure triggers are deployed and working

### Issue 3: Trigger Not Firing

**Symptom**: Cards/items have NULL `content_hash`
**Cause**: Triggers not deployed or disabled
**Fix**: Deploy triggers from `sql/triggers.sql`

### Issue 4: JSONB Merge Issue

**Symptom**: Hash gets stripped during JSONB merge
**Cause**: Stored procedure merge logic
**Fix**: Verify JSONB structure being sent

## Quick Fix: Recalculate All Hashes

If translations have wrong hashes, run this to sync them:

```sql
-- For a specific card
SELECT recalculate_all_translation_hashes('YOUR_CARD_ID');

-- Check if the function exists
SELECT routine_name 
FROM information_schema.routines 
WHERE routine_name = 'recalculate_all_translation_hashes';
```

## Testing Procedure

1. **Before Translation**:
   - Note current card hash: `SELECT content_hash FROM cards WHERE id = 'X'`
   - Note current item hashes: `SELECT id, content_hash FROM content_items WHERE card_id = 'X'`

2. **Translate**:
   - Translate to a language
   - Check backend logs for hash values being sent

3. **After Translation**:
   - Run hash comparison queries above
   - Compare stored hashes with current hashes
   - They should MATCH if content hasn't changed

4. **Update Content**:
   - Change card name or description
   - Check if `content_hash` updates automatically
   - Old translation hashes should now show as outdated

## Expected Behavior

- ✅ After translation: `stored_hash == current_hash` → status = "up_to_date"
- ✅ After content edit: `stored_hash != current_hash` → status = "outdated"
- ✅ After retranslation: `stored_hash == current_hash` → status = "up_to_date" again

## Report Back

Please run the diagnostic queries and share:
1. Results of the hash comparison queries
2. Backend console logs showing hash values
3. Whether you've recently updated card content
4. When the translations were last done vs when content was last updated

