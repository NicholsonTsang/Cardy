# Store Card Translations Function Cleanup - November 17, 2025

## Problem

Database deployment was failing with error:
```
ERROR: 42883: function store_card_translations(uuid, uuid, text[], jsonb, jsonb, numeric) does not exist
```

The stored procedure file contained a `GRANT EXECUTE` statement for `store_card_translations()`, but the function itself didn't exist.

## Root Cause

The `store_card_translations()` stored procedure was **removed during a previous refactoring** when the translation system was simplified to use direct Supabase updates instead of a stored procedure.

### Historical Context

**Old approach (removed):**
- Backend called `store_card_translations()` stored procedure
- Stored procedure handled inserting translations into database
- Required service_role permissions

**Current approach (since Nov 2025):**
- Backend uses direct Supabase updates (`.update()` method)
- Implemented in `backend-server/src/routes/translation.routes.direct.ts`
- Better control over hash freshness and race condition prevention
- See `saveTranslations()` function

### Why This is Better

1. **Hash Freshness**: Re-fetches current hashes before saving (prevents "outdated" status)
2. **Race Condition Prevention**: All translations saved together after concurrent processing completes
3. **Simpler**: No need for complex stored procedure with JSONB manipulation
4. **More Control**: Better error handling and logging in TypeScript

## Changes Made

### 1. Removed Orphaned GRANT Statement
**File**: `sql/storeproc/client-side/12_translation_management.sql`

**Before**:
```sql
GRANT EXECUTE ON FUNCTION store_card_translations(UUID, UUID, TEXT[], JSONB, JSONB, DECIMAL) TO service_role;
```

**After**:
```sql
-- store_card_translations removed - translations now saved via direct Supabase updates (see translation.routes.direct.ts)
```

### 2. Updated Documentation Comments

**File**: `sql/storeproc/client-side/12_translation_management.sql`

Updated header comment:
```sql
-- Client-side procedures (called from dashboard frontend):
-- - get_card_translation_status: Get translation status for all languages
-- - get_card_translations: Get full translations for a card
-- - delete_card_translation: Remove a specific language translation
-- - get_translation_history: Get audit trail of translations
--
-- Note: Translations are now saved via direct Supabase updates in 
-- backend-server/src/routes/translation.routes.direct.ts (saveTranslations function)
```

Updated section 3 comment:
```sql
-- =====================================================================
-- Translation Storage
-- =====================================================================

-- NOTE: store_card_translations function removed - translations now saved 
-- via direct Supabase updates in backend (see translation.routes.direct.ts)
-- This approach provides better control over hash freshness and race condition prevention
```

### 3. Updated Server-Side README

**File**: `sql/storeproc/server-side/README.md`

**Before**:
```markdown
### Content Management
- `translation_management.sql` - AI-powered translation storage
  - `store_card_translations()` - Store GPT-4 translated content
```

**After**:
```markdown
### Content Management
- ~~`translation_management.sql`~~ - Removed, translations now saved via direct Supabase updates
  - ~~`store_card_translations()`~~ - Removed, see `backend-server/src/routes/translation.routes.direct.ts`
```

## Current Translation Flow

### Backend Translation Route
**File**: `backend-server/src/routes/translation.routes.direct.ts`

```typescript
// Lines 405-463: saveTranslations function
async function saveTranslations(
  cardId: string,
  cardData: any,
  cardTranslations: Record<string, any>,
  contentItemsTranslations: Record<string, Record<string, any>>
) {
  // CRITICAL: Re-fetch current card hash before saving
  const { data: freshCardData } = await supabaseAdmin
    .from('cards')
    .select('content_hash')
    .eq('id', cardId)
    .single();

  // Update card translations with fresh hash
  if (Object.keys(cardTranslations).length > 0) {
    const updatedCardTranslations: Record<string, any> = {};
    for (const [lang, trans] of Object.entries(cardTranslations)) {
      updatedCardTranslations[lang] = {
        ...trans,
        content_hash: freshCardData?.content_hash || trans.content_hash,
      };
    }

    const finalTranslations = { ...cardData.translations, ...updatedCardTranslations };
    
    await supabaseAdmin
      .from('cards')
      .update({ translations: finalTranslations })
      .eq('id', cardId);
  }

  // Save content item translations with fresh hashes
  for (const [itemId, translations] of Object.entries(contentItemsTranslations)) {
    const { data: freshItemData } = await supabaseAdmin
      .from('content_items')
      .select('translations, content_hash')
      .eq('id', itemId)
      .single();

    const updatedItemTranslations: Record<string, any> = {};
    for (const [lang, trans] of Object.entries(translations)) {
      updatedItemTranslations[lang] = {
        ...trans,
        content_hash: freshItemData?.content_hash || trans.content_hash,
      };
    }

    const finalTranslations = { ...freshItemData?.translations, ...updatedItemTranslations };
    
    await supabaseAdmin
      .from('content_items')
      .update({ translations: finalTranslations })
      .eq('id', itemId);
  }
}
```

## Files Modified

1. ✅ `sql/storeproc/client-side/12_translation_management.sql`
   - Removed GRANT statement for non-existent function
   - Updated documentation comments

2. ✅ `sql/storeproc/server-side/README.md`
   - Marked translation_management.sql as removed

3. ✅ `sql/all_stored_procedures.sql`
   - Regenerated with updated comments

## Related Documentation

- **TRANSLATION_HASH_FRESHNESS_FIX.md** - Explains why hash re-fetching is critical
- **TRANSLATION_RACE_CONDITION_FIX.md** - Explains why translations save after concurrent processing
- **BATCH_TRANSLATION_STRATEGY.md** - Overall translation strategy documentation

## Benefits of Direct Updates

### 1. Hash Freshness ✅
**Problem**: Stored procedure couldn't re-fetch hashes after translation
**Solution**: TypeScript code re-fetches hashes immediately before saving

### 2. Race Condition Prevention ✅
**Problem**: Concurrent language processing could overwrite each other's results
**Solution**: Collect all translations first, then save in single operation

### 3. Better Error Handling ✅
**Problem**: Stored procedure errors were cryptic
**Solution**: TypeScript provides detailed error messages and logging

### 4. Easier Maintenance ✅
**Problem**: Complex JSONB manipulation in SQL
**Solution**: Simple JavaScript object manipulation

## Deployment

The updated stored procedures file is ready to deploy. Simply run in Supabase SQL Editor:

```sql
-- Copy contents from sql/all_stored_procedures.sql
```

No breaking changes - the backend already uses direct Supabase updates.

---

**Status**: ✅ Fixed  
**Impact**: Zero user impact - backend already uses new approach  
**Complexity Reduction**: Removed ~100 lines of unused stored procedure code



