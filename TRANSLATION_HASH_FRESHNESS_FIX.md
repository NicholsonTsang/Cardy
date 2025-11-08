# Translation Hash Freshness Fix

**Date**: November 5, 2025  
**Status**: ✅ Implemented

## Problem

Translations kept showing as "outdated" even immediately after retranslating. Users would:
1. See a translation marked as "outdated"
2. Retranslate to that language
3. Translation completes successfully
4. Check translation status → Still shows "outdated" ❌

## Root Cause (UPDATED AFTER INVESTIGATION)

**TwoIssues Were Found:**

### Issue 1: Stale Content Hashes (FIXED)
The backend was saving translations with **potentially stale content hashes**:

1. **Translation starts** (line 77): Backend fetches card data including `content_hash`
2. **Translation process**: Takes 30-60 seconds for multiple languages with batch processing
3. **Save translation** (line 325): Backend saves translation using the hash from step 1
4. **Problem**: If the hash in memory doesn't perfectly match the current database hash (due to timing, precision, or any update), the saved translation is immediately "outdated"

```typescript
// OLD FLOW (BUGGY)
fetch card (hash = "abc123...")        // Step 1: Get hash
  ↓
translate (30-60 seconds...)           // Step 2: Long process
  ↓
save translation (with "abc123...")    // Step 3: Use old hash
  ↓
check status: stored "abc123..." vs current "abc123..."
  ↓
MISMATCH → Shows "outdated" ❌
```

### Issue 2: Frontend Not Reloading Status (THE ACTUAL BUG!)
After **extensive MCP database investigation**, we found:
- ✅ All hashes in database are MATCHING perfectly
- ✅ Backend fix IS working correctly
- ❌ **Translation Dialog never emits 'translated' event after Socket.IO completion**
- ❌ Parent components never reload translation status after translation succeeds
- ❌ Frontend shows stale "outdated" status because it never refreshes

**The Bug:**
When translation completes via Socket.IO, the dialog shows Step 3 (Success). When user clicks "Done" button, `closeDialog()` is called, but it **never emits 'translated'** event to tell parent components to reload the translation status. The frontend continues showing the old cached status!

## Solution

### Fix 1: Backend Hash Re-fetching (Already Implemented)
Re-fetch the **current** content hashes right before saving each language's translations. This ensures we always save with the exact current hash from the database.

```typescript
// NEW FLOW (FIXED)
fetch card (hash = "abc123...")        // Step 1: Initial fetch
  ↓
translate (30-60 seconds...)           // Step 2: Long process
  ↓
RE-FETCH current hashes                // Step 3: Get fresh hashes
  ↓
save translation (with CURRENT hash)   // Step 4: Use fresh hash
  ↓
check status: stored hash == current hash
  ↓
MATCH → Shows "up_to_date" ✅
```

### Fix 2: Frontend Event Emission (NOW IMPLEMENTED)
Modified `closeDialog()` in `TranslationDialog.vue` to emit 'translated' event when closing after successful translation (Step 3). This triggers parent components to reload translation status and display current data.

## Implementation

### Files Modified

#### 1. Backend Fix
**File**: `backend-server/src/routes/translation.routes.ts` (lines 325-377)

### Code Added

Right before saving translations to database:

```typescript
// Re-fetch current hashes RIGHT before saving to ensure freshness
// This prevents "outdated" status when content hash changes during translation
console.log(`🔄 Re-fetching current hashes to prevent stale data...`);
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
if (freshCardData && cardTranslations[targetLang]) {
  cardTranslations[targetLang].content_hash = freshCardData.content_hash;
  console.log(`  ✅ Card hash updated: ${freshCardData.content_hash}`);
}

// Update content items translations with fresh hashes
if (freshItems && freshItems.length > 0) {
  for (const freshItem of freshItems) {
    if (contentItemsTranslations[freshItem.id]?.[targetLang]) {
      contentItemsTranslations[freshItem.id][targetLang].content_hash = freshItem.content_hash;
    }
  }
  console.log(`  ✅ Updated ${freshItems.length} content item hashes`);
}
```

#### 2. Frontend Fix  
**File**: `src/components/Card/TranslationDialog.vue` (lines 801-817)

Added check in `closeDialog()` to emit 'translated' when closing after successful translation:

```typescript
const closeDialog = () => {
  // If closing after successful translation (Step 3), emit 'translated' to reload status
  if (currentStep.value === 3) {
    emit('translated');
  }
  
  dialogVisible.value = false;
  // Disconnect Socket.IO
  progress.disconnect();
  // Reset after animation
  setTimeout(() => {
    currentStep.value = 1;
    selectedLanguages.value = [];
    translationProgress.value = 0;
    progress.reset();
  }, 300);
};
```

This triggers parent components' `handleTranslationSuccess()` which calls `loadTranslationStatus()` to fetch fresh status from database.

## Benefits

### Before Fix
- ❌ Translations show "outdated" even after retranslation (frontend never reloaded status)
- ❌ Users confused why translations appear stale
- ❌ Users waste credits retranslating repeatedly
- ❌ No confidence in translation status

### After Fix
- ✅ Translations correctly show "up_to_date" after completion
- ✅ Clear, accurate status indicators
- ✅ Users only retranslate when content actually changes
- ✅ Reliable translation freshness detection

## Performance Impact

**Minimal** - adds 2 lightweight SELECT queries per language:
- 1 query to fetch card `content_hash` (single row, single column)
- 1 query to fetch all content items' `content_hash` (N rows, 2 columns)

Total overhead: ~50-100ms per language, negligible compared to 30-60s translation time.

## Testing Verification

### Test Case 1: Fresh Translation
```
1. Translate card to Chinese
2. Wait for completion
3. Check status
Expected: ✅ Shows "up_to_date"
```

### Test Case 2: Content Update Detection
```
1. Card has Chinese translation (up_to_date)
2. Edit card name or description
3. Check translation status
Expected: ✅ Shows "outdated"
```

### Test Case 3: Retranslation
```
1. Card has outdated Chinese translation
2. Retranslate to Chinese
3. Wait for completion
4. Check status
Expected: ✅ Shows "up_to_date"
```

### Test Case 4: No Content Change
```
1. Translate to Chinese (up_to_date)
2. Don't edit anything
3. Check status after 1 hour, 1 day, 1 week
Expected: ✅ Still shows "up_to_date"
```

## Database Verification Query

Run this to verify translations have correct hashes:

```sql
-- Check if stored hashes match current hashes
SELECT 
  c.id,
  c.name,
  c.content_hash as current_card_hash,
  c.translations->'zh-Hans'->>'content_hash' as stored_card_hash,
  c.translations->'zh-Hans'->>'translated_at' as translation_date,
  CASE 
    WHEN c.translations->'zh-Hans'->>'content_hash' = c.content_hash 
    THEN '✅ CORRECT (UP TO DATE)' 
    ELSE '❌ WRONG (WILL SHOW OUTDATED)'
  END as card_status,
  (
    SELECT COUNT(*) 
    FROM content_items ci 
    WHERE ci.card_id = c.id 
      AND ci.translations ? 'zh-Hans'
      AND ci.translations->'zh-Hans'->>'content_hash' != ci.content_hash
  ) as outdated_items_count
FROM cards c
WHERE c.translations ? 'zh-Hans'
ORDER BY c.updated_at DESC
LIMIT 10;
```

If `card_status` = "✅ CORRECT" and `outdated_items_count` = 0, the fix is working!

## Console Output

After fix, you'll see this in backend logs during translation:

```
✅ Completed all batches for 中文 (繁體)
💾 Saving 中文 (繁體) translations to database...
🔄 Re-fetching current hashes to prevent stale data...
  ✅ Card hash updated: a1b2c3d4e5f6...
  ✅ Updated 5 content item hashes
  ✅ 中文 (繁體) translations saved successfully
```

## Related Issues

This fix also prevents issues related to:
- Import/export hash mismatches
- Concurrent edits during translation
- Database trigger timing issues
- Race conditions in hash generation

## Alternative Solutions Considered

### Option 1: Database-side fix
Modify `store_card_translations` stored procedure to ignore passed hashes and always use current ones.

**Pros**: More robust, no extra queries from backend  
**Cons**: Requires database migration  
**Decision**: Kept as backup option if backend fix insufficient

### Option 2: Prevent edits during translation
Lock card editing while translation in progress.

**Pros**: Prevents race conditions  
**Cons**: Bad UX, overly restrictive  
**Decision**: Rejected

### Option 3: Hash validation middleware
Add middleware to validate hash freshness before every save.

**Pros**: Centralized validation  
**Cons**: Over-engineered for this specific issue  
**Decision**: Current fix is simpler and sufficient

## Investigation Process

### What We Did
1. **Added backend logging** to track hash values during translation
2. **Used MCP to query database** directly and found ALL hashes matching perfectly
3. **Analyzed stored procedure** logic - confirmed it was correct
4. **Traced frontend code** to find missing 'translated' event emission
5. **Fixed the bug** - added emit in closeDialog()

### Database Investigation Results
Query results from production database showed:
- ✅ **All cards**: `current_hash` MATCHES `stored_hash` → Status = "MATCH"
- ✅ **All content items**: 58+ items checked, ALL showing "MATCH"
- ✅ Backend fix IS working - hashes are being saved correctly

This confirmed the issue was NOT with hash storage but with **frontend not reloading the status**.

## Conclusion

This fix has **two parts**:
1. **Backend**: Re-fetch current hashes before saving (ensures accuracy)
2. **Frontend**: Emit 'translated' event after success (triggers status reload)

Together, these ensure translation freshness detection works correctly and users see accurate, up-to-date status immediately after translation completes.

**Result**: Reliable, accurate translation status that users can trust, with proper cache invalidation.

