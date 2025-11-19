# Debug Instructions for Translation Outdated Issue

## Step 1: Run Diagnostic Queries

1. Open Supabase Dashboard
2. Go to SQL Editor
3. Copy and paste the queries from `debug_translation_hashes.sql`
4. Run each query one by one
5. Take screenshots or copy the results

## Step 2: Key Things to Check

### A. Are Hashes Being Stored?
From Query 1 and 2, check if `stored_hash_in_translation` has a value:
- ✅ If it has a value like "a1b2c3d4..." → Hash is being stored
- ❌ If it's NULL → Backend is not sending hash or DB is not saving it

### B. Do Hashes Match?
From Query 1 and 2, check the `hash_status`:
- ✅ If it shows "MATCH" → Should show "up_to_date" (if not, frontend issue)
- ❌ If it shows "MISMATCH" → Need to investigate why hashes differ

### C. Are Triggers Working?
From Query 4, check the trigger test results:
- ✅ If hash changed → Triggers are working
- ❌ If hash didn't change → Triggers not deployed or not working

## Step 3: Common Issues and Solutions

### Issue 1: Stored Hash is NULL
**Symptom**: `stored_hash_in_translation` column shows NULL or "HASH IS NULL!"
**Cause**: Backend not sending hash, or it's being stripped

**Fix**: Add debug logging to backend at line 340:
```typescript
console.log('🔍 Translation object being saved:', JSON.stringify(cardTranslations[targetLang], null, 2));
```

### Issue 2: Current Hash is NULL  
**Symptom**: `current_card_hash` column shows NULL
**Cause**: Triggers not deployed or not firing

**Fix**: Deploy triggers from `sql/triggers.sql` to Supabase

### Issue 3: Hashes Don't Match
**Symptom**: Both hashes exist but are different
**Possible Causes**:
a) Content was edited after translation
b) Hash calculation inconsistency
c) Race condition (hash changed between fetch and save)

**Fix**: Check `last_content_update` vs `translation_date`
- If `last_content_update` > `translation_date` → Content was edited (expected outdated)
- If `translation_date` > `last_content_update` → Should match (unexpected outdated)

### Issue 4: Frontend Shows Wrong Status
**Symptom**: Hashes match in DB but frontend shows "outdated"
**Cause**: Frontend caching or status calculation issue

**Fix**: Clear frontend cache, reload translation status

## Step 4: Backend Debug Logging

Add these console.logs to `backend-server/src/routes/translation.routes.ts`:

### At line 273 (when capturing card hash):
```typescript
console.log('🔍 DEBUG - Card hash captured:', cardData.content_hash);
```

### At line 340 (after refreshing hash):
```typescript
console.log('🔍 DEBUG - Fresh card hash:', freshCardData?.content_hash);
console.log('🔍 DEBUG - Updated translation object:', JSON.stringify(cardTranslations[targetLang], null, 2));
```

### At line 355 (before DB save):
```typescript
console.log('🔍 DEBUG - Sending to DB:', {
  card_translations: cardTranslations,
  sample_content_item: Object.values(contentItemsTranslations)[0]
});
```

## Step 5: Report Back

Please provide:
1. Results from Query 1 (card hash status)
2. Results from Query 2 (content items hash status)
3. Results from Query 4 (trigger test)
4. Backend console logs showing:
   - "🔍 DEBUG - Card hash captured"
   - "🔍 DEBUG - Fresh card hash"
   - "🔍 DEBUG - Updated translation object"
5. Any specific card ID that's having the issue

## Quick Test Procedure

1. **Before Translation**:
   ```sql
   SELECT content_hash FROM cards WHERE id = 'YOUR_CARD_ID';
   ```
   Note the hash value (e.g., "abc123...")

2. **Translate the card** to Chinese (or any language)

3. **After Translation**:
   ```sql
   SELECT 
     content_hash as current,
     translations->'zh-Hans'->>'content_hash' as stored
   FROM cards WHERE id = 'YOUR_CARD_ID';
   ```
   
4. **Compare**:
   - If `current` = `stored` → Fix is working! ✅
   - If `current` ≠ `stored` → Need more investigation ❌

## Emergency Fix: Manual Hash Sync

If you need translations to show correctly RIGHT NOW while we debug:

```sql
-- Sync all translation hashes for a specific card
SELECT recalculate_all_translation_hashes('YOUR_CARD_ID');

-- Check if function exists first:
SELECT routine_name 
FROM information_schema.routines 
WHERE routine_name = 'recalculate_all_translation_hashes';
```

This will update all stored hashes to match current hashes.

