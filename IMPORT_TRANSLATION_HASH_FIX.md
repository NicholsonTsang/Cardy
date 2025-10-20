# Import Translation Hash Synchronization Fix

## Problem

When importing cards with translations via Excel:

1. **Export** creates Excel with translations JSON containing content hashes from the original card
2. **Import** creates a new card with new IDs and calculates new content hashes
3. **Mismatch**: Imported translations still contain old hashes from export
4. **Result**: All translations immediately show as "Outdated" even though content is identical

## Root Cause

The import process was preserving translation data (correct) but not synchronizing the embedded `content_hash` values within each translation object. The system compares:
- `translations.{lang}.content_hash` (old hash from export)
- `cards.content_hash` (new hash from newly created card)

When these don't match → "Outdated" status.

## Solution

**File**: `src/components/Card/Import/CardBulkImport.vue` (line ~1134)

Added automatic hash recalculation after import:

```javascript
// CRITICAL: Recalculate all translation hashes to sync with newly created card
// When importing, translations contain hashes from the OLD card
// We need to update them to match the NEW card's content hashes
try {
  importStatus.value = 'Synchronizing translation hashes...';
  const { error: hashError } = await supabase.rpc('recalculate_all_translation_hashes', {
    p_card_id: cardId
  });
  
  if (hashError) {
    console.warn('Failed to recalculate translation hashes:', hashError);
    results.warnings++;
    results.errors.push(`Warning: Translation freshness may not be accurate. Please re-translate if needed.`);
  } else {
    console.log('✓ Translation hashes synchronized successfully');
  }
} catch (hashRecalcError) {
  console.warn('Failed to recalculate translation hashes:', hashRecalcError);
  results.warnings++;
}
```

## Database Function Used

**Function**: `recalculate_all_translation_hashes(p_card_id UUID)`  
**Location**: `sql/storeproc/client-side/12_translation_management.sql`

This function:
1. Recalculates card translation hashes (updates `cards.translations` JSONB)
2. Recalculates all content item translation hashes (updates `content_items.translations` JSONB)
3. Ensures all embedded `content_hash` values match current content

**Implementation**:
- For each translation language in the JSONB
- Updates `translations.{lang}.content_hash` to match current `content_hash`
- Preserves all other translation data (name, description, content, timestamp)

## Impact

**Before Fix**:
```
Import card → All translations show "Outdated" → User confused → Unnecessary re-translation
```

**After Fix**:
```
Import card → Hash sync runs → Translations show "Up to Date" → Perfect ✅
```

## Testing

1. **Export** a card with translations
2. **Import** the Excel file
3. **Verify** translations show as "Up to Date" (not "Outdated")
4. **Check** console logs for: `✓ Translation hashes synchronized successfully`

## Deployment Status

✅ **Fixed** - No database changes required  
✅ Frontend change in `CardBulkImport.vue`  
✅ Uses existing `recalculate_all_translation_hashes()` stored procedure  
✅ Ready for production deployment

## Related Issues

- **Translation Shows "Outdated" Immediately**: Different issue (NULL hash triggers) - See `TRANSLATION_FRESHNESS_BUG_FIX.md`
- **Export/Import Flow**: Full explanation in `EXPORT_IMPORT_FLOW_EXPLAINED.md`
- **Hash Calculation Design**: Analysis in `HASH_CALCULATION_DESIGN_ANALYSIS.md`

## Notes

- This fix is **automatic** - no user action required
- If hash sync fails (rare), import still succeeds with warning
- Failed sync can be manually fixed by re-translating
- Console logs provide clear feedback on sync status


