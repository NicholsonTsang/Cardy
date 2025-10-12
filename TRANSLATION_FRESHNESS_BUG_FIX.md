# Translation Freshness Bug Fix

## Issue Summary

**Problem**: After translating a card, translations immediately show as "Outdated" with "2 needs update" warning, even though the content hasn't changed.

**Root Cause**: The `content_hash` column is `NULL` when cards and content items are first created because there were only `BEFORE UPDATE` triggers, not `BEFORE INSERT` triggers.

## How It Happened

### The Translation Freshness System

The translation system tracks whether translations are up-to-date by:
1. Calculating an MD5 hash of the original content (name + description for cards, name + content + ai_knowledge_base for items)
2. Storing this hash alongside each translation
3. Comparing the stored hash with the current hash to detect changes

### The Bug Flow

1. **Card Creation**: User creates a new card
   - Card is inserted with `content_hash = NULL` (no INSERT trigger)
   - Content items are inserted with `content_hash = NULL`

2. **Translation**: User immediately translates the card
   - Edge Function fetches card: `content_hash = NULL`
   - GPT-4 translates the content successfully
   - Translation is stored with `content_hash: NULL` for each language

3. **Status Check**: Frontend checks translation status
   - Current card `content_hash = NULL`
   - Stored translation `content_hash = NULL`
   - Comparison `NULL == NULL` evaluates as "not equal" or fails
   - Result: Shows as "Outdated"

4. **After First Update**: When user edits card name/description
   - UPDATE trigger fires and calculates hash for the first time
   - Now current hash is not NULL, but stored translation hash is NULL
   - Comparison fails → Shows as "Outdated"

## The Fix

### Changes Made

1. **Modified `update_card_content_hash()` function** (`sql/migrations/add_translation_system.sql`)
   - Added `IF TG_OP = 'INSERT'` branch to calculate hash on creation
   - Kept `ELSIF TG_OP = 'UPDATE'` branch for updates
   - Now works for both INSERT and UPDATE operations

2. **Modified `update_content_item_content_hash()` function**
   - Same pattern: handles both INSERT and UPDATE
   - Calculates hash immediately when content item is created

3. **Updated Triggers**
   - Changed from `BEFORE UPDATE` to `BEFORE INSERT OR UPDATE`
   - Both `trigger_update_card_content_hash` and `trigger_update_content_item_content_hash`

4. **Backfill Script** (`DEPLOY_TRANSLATION_HASH_FIX.sql`)
   - Updates any existing cards/items with NULL hash
   - Ensures all historical data has valid hashes

### Technical Details

**Before (Bug):**
```sql
CREATE TRIGGER trigger_update_card_content_hash
  BEFORE UPDATE ON cards  -- ❌ Only UPDATE
  FOR EACH ROW
  EXECUTE FUNCTION update_card_content_hash();
```

**After (Fixed):**
```sql
CREATE TRIGGER trigger_update_card_content_hash
  BEFORE INSERT OR UPDATE ON cards  -- ✅ Both INSERT and UPDATE
  FOR EACH ROW
  EXECUTE FUNCTION update_card_content_hash();
```

**Function Logic:**
```sql
CREATE OR REPLACE FUNCTION update_card_content_hash()
RETURNS TRIGGER AS $$
BEGIN
  -- On INSERT: Always calculate hash
  IF TG_OP = 'INSERT' THEN
    NEW.content_hash := md5(COALESCE(NEW.name, '') || '|' || COALESCE(NEW.description, ''));
    NEW.last_content_update := NOW();
  -- On UPDATE: Only recalculate if name or description changed
  ELSIF TG_OP = 'UPDATE' THEN
    IF (NEW.name IS DISTINCT FROM OLD.name) OR 
       (NEW.description IS DISTINCT FROM OLD.description) THEN
      NEW.content_hash := md5(COALESCE(NEW.name, '') || '|' || COALESCE(NEW.description, ''));
      NEW.last_content_update := NOW();
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

## Deployment Instructions

### Option 1: Quick Deploy (Recommended)

Execute the deployment script in Supabase Dashboard > SQL Editor:

```bash
# Copy and execute: DEPLOY_TRANSLATION_HASH_FIX.sql
```

This script:
- ✅ Drops old triggers
- ✅ Updates trigger functions to handle INSERT
- ✅ Creates new triggers for INSERT OR UPDATE
- ✅ Backfills NULL hashes for existing cards/items

### Option 2: Manual Steps

If you prefer to understand each step:

1. **Navigate to Supabase Dashboard > SQL Editor**

2. **Drop existing triggers:**
   ```sql
   DROP TRIGGER IF EXISTS trigger_update_card_content_hash ON cards;
   DROP TRIGGER IF EXISTS trigger_update_content_item_content_hash ON content_items;
   ```

3. **Update trigger functions** (see `DEPLOY_TRANSLATION_HASH_FIX.sql` for full code)

4. **Create new triggers:**
   ```sql
   CREATE TRIGGER trigger_update_card_content_hash
     BEFORE INSERT OR UPDATE ON cards
     FOR EACH ROW
     EXECUTE FUNCTION update_card_content_hash();
   
   CREATE TRIGGER trigger_update_content_item_content_hash
     BEFORE INSERT OR UPDATE ON content_items
     FOR EACH ROW
     EXECUTE FUNCTION update_content_item_content_hash();
   ```

5. **Backfill existing records:**
   ```sql
   UPDATE cards 
   SET content_hash = md5(COALESCE(name, '') || '|' || COALESCE(description, ''))
   WHERE content_hash IS NULL;
   
   UPDATE content_items 
   SET content_hash = md5(
     COALESCE(name, '') || '|' || 
     COALESCE(content, '') || '|' ||
     COALESCE(ai_knowledge_base, '')
   )
   WHERE content_hash IS NULL;
   ```

## Verification

After deployment, verify the fix:

1. **Check triggers exist:**
   ```sql
   SELECT 
     trigger_name, 
     event_manipulation, 
     event_object_table
   FROM information_schema.triggers
   WHERE trigger_name LIKE '%content_hash%';
   ```
   
   Expected output:
   - `trigger_update_card_content_hash` on `cards` for `INSERT, UPDATE`
   - `trigger_update_content_item_content_hash` on `content_items` for `INSERT, UPDATE`

2. **Check no NULL hashes:**
   ```sql
   SELECT COUNT(*) FROM cards WHERE content_hash IS NULL;
   SELECT COUNT(*) FROM content_items WHERE content_hash IS NULL;
   ```
   
   Both should return `0`.

3. **Test new card creation:**
   - Create a new card via the dashboard
   - Check that `content_hash` is populated immediately:
     ```sql
     SELECT id, name, content_hash FROM cards ORDER BY created_at DESC LIMIT 1;
     ```

4. **Test translation:**
   - Create a new card
   - Translate to any language
   - Check translation status → Should show as "up_to_date", not "outdated"

## Impact on Existing Translations

### Cards Translated Before Fix

Cards that were translated when `content_hash` was NULL will still show as outdated because:
- Their stored translation has `content_hash: NULL`
- After backfill, their current `content_hash` is not NULL
- Comparison fails: `NULL != <valid-hash>`

**Solution**: Users will need to re-translate these cards. The re-translation will store the correct hash and work properly going forward.

### Cards Created After Fix

All new cards will automatically get valid `content_hash` values:
- On creation → INSERT trigger calculates hash
- On translation → Valid hash is stored
- On status check → Comparison works correctly ✅

## Files Modified

1. **`sql/migrations/add_translation_system.sql`** - Updated migration for future deployments
2. **`DEPLOY_TRANSLATION_HASH_FIX.sql`** - One-time deployment script for production
3. **`TRANSLATION_FRESHNESS_BUG_FIX.md`** - This documentation

## Testing Checklist

- [ ] Deploy `DEPLOY_TRANSLATION_HASH_FIX.sql` to production database
- [ ] Verify both triggers exist and fire on INSERT
- [ ] Verify no NULL hashes remain
- [ ] Create a new card and check hash is populated
- [ ] Create a new content item and check hash is populated
- [ ] Translate a new card and verify status shows "up_to_date"
- [ ] Edit translated card content and verify status changes to "outdated"
- [ ] Re-translate and verify status returns to "up_to_date"

## Rollback Plan

If issues arise, you can rollback by reverting to UPDATE-only triggers:

```sql
-- Revert to old behavior (UPDATE only)
DROP TRIGGER IF EXISTS trigger_update_card_content_hash ON cards;
CREATE TRIGGER trigger_update_card_content_hash
  BEFORE UPDATE ON cards
  FOR EACH ROW
  EXECUTE FUNCTION update_card_content_hash();

DROP TRIGGER IF EXISTS trigger_update_content_item_content_hash ON content_items;
CREATE TRIGGER trigger_update_content_item_content_hash
  BEFORE UPDATE ON content_items
  FOR EACH ROW
  EXECUTE FUNCTION update_content_item_content_hash();
```

**Note**: This would bring back the bug, so only use for emergency rollback.

## Related Issues

- Translation freshness detection not working
- "Outdated" status showing immediately after translation
- NULL content_hash values causing comparison failures

## Future Improvements

1. **Migration Script**: Consider adding this fix to the main `sql/schema.sql` for new deployments
2. **Monitoring**: Add database monitoring to alert if content_hash columns start having NULL values
3. **Frontend Warning**: Display a message to users if their translations need re-translation due to NULL hash issue

## Questions?

For questions or issues with this fix, please refer to:
- `CLAUDE.md` - Project documentation and architecture
- `sql/migrations/add_translation_system.sql` - Full migration code
- `DEPLOY_TRANSLATION_HASH_FIX.sql` - Deployment script

