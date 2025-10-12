# Translation Hash Fix - Deployment Instructions

## Quick Summary

**Issue**: Translations show as "Outdated" immediately after creation  
**Cause**: `content_hash` is NULL when cards/items are created (missing INSERT triggers)  
**Fix**: Add INSERT triggers to calculate hash on creation  
**Impact**: Existing translations with NULL hashes will need re-translation

## Deployment Steps

### Step 1: Deploy to Supabase Database

1. Open **Supabase Dashboard** → Navigate to your project
2. Go to **SQL Editor**
3. Copy the entire contents of `DEPLOY_TRANSLATION_HASH_FIX.sql`
4. Paste into SQL Editor
5. Click **Run** to execute

**What this does:**
- ✅ Updates trigger functions to handle INSERT operations
- ✅ Recreates triggers for both INSERT and UPDATE
- ✅ Backfills NULL hashes for all existing cards/items

### Step 2: Verify Deployment

Run these verification queries in SQL Editor:

```sql
-- 1. Check triggers exist
SELECT 
  trigger_name, 
  string_agg(event_manipulation, ', ' ORDER BY event_manipulation) as events,
  event_object_table
FROM information_schema.triggers
WHERE trigger_name LIKE '%content_hash%'
GROUP BY trigger_name, event_object_table;
```

**Expected output:**
| trigger_name | events | event_object_table |
|--------------|--------|-------------------|
| trigger_update_card_content_hash | INSERT, UPDATE | cards |
| trigger_update_content_item_content_hash | INSERT, UPDATE | content_items |

```sql
-- 2. Check no NULL hashes remain
SELECT 
  'cards' as table_name, 
  COUNT(*) as null_count 
FROM cards 
WHERE content_hash IS NULL
UNION ALL
SELECT 
  'content_items' as table_name, 
  COUNT(*) as null_count 
FROM content_items 
WHERE content_hash IS NULL;
```

**Expected output:**
| table_name | null_count |
|------------|-----------|
| cards | 0 |
| content_items | 0 |

### Step 3: Test New Card Creation

1. Create a new card in the dashboard
2. Run this query (replace `YOUR_CARD_ID` with the new card's ID):

```sql
SELECT 
  id, 
  name, 
  content_hash,
  CASE 
    WHEN content_hash IS NULL THEN '❌ FAILED - Hash is NULL'
    WHEN length(content_hash) = 32 THEN '✅ PASSED - Valid MD5 hash'
    ELSE '⚠️  WARNING - Hash format incorrect'
  END as status
FROM cards 
WHERE id = 'YOUR_CARD_ID';
```

**Expected**: Status should be "✅ PASSED - Valid MD5 hash"

### Step 4: Test Translation Flow

1. Create a fresh card (after deployment)
2. Add some content items
3. Translate to any language (e.g., Traditional Chinese)
4. Check translation status in the UI

**Expected**: Translation should show as "✓ Up to date", not "Outdated"

## User Communication

### For Cards Translated BEFORE Fix

**Message to users:**
> Due to a database update, cards that were translated before [DATE] may show as "Outdated" even though the content hasn't changed. This is a one-time issue. Please re-translate these cards, and the status will work correctly going forward. We apologize for the inconvenience.

### For Cards Translated AFTER Fix

All new translations will work correctly. No action needed from users.

## Rollback Procedure (Emergency Only)

If critical issues arise, you can rollback by reverting to UPDATE-only triggers:

```sql
-- Revert trigger functions to old behavior
CREATE OR REPLACE FUNCTION update_card_content_hash()
RETURNS TRIGGER AS $$
BEGIN
  IF (NEW.name IS DISTINCT FROM OLD.name) OR 
     (NEW.description IS DISTINCT FROM OLD.description) THEN
    NEW.content_hash := md5(COALESCE(NEW.name, '') || '|' || COALESCE(NEW.description, ''));
    NEW.last_content_update := NOW();
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_content_item_content_hash()
RETURNS TRIGGER AS $$
BEGIN
  IF (NEW.name IS DISTINCT FROM OLD.name) OR 
     (NEW.content IS DISTINCT FROM OLD.content) OR
     (NEW.ai_knowledge_base IS DISTINCT FROM OLD.ai_knowledge_base) THEN
    NEW.content_hash := md5(
      COALESCE(NEW.name, '') || '|' || 
      COALESCE(NEW.content, '') || '|' ||
      COALESCE(NEW.ai_knowledge_base, '')
    );
    NEW.last_content_update := NOW();
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Revert triggers to UPDATE only
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

**⚠️ WARNING**: Rollback will restore the original bug. Only use in emergency.

## Post-Deployment Monitoring

### Week 1: Monitor for Issues

Check for these potential issues:

1. **NULL hashes appearing again**:
   ```sql
   SELECT COUNT(*) FROM cards WHERE content_hash IS NULL AND created_at > NOW() - INTERVAL '7 days';
   ```
   Should return 0.

2. **Trigger failures** (check Supabase logs):
   - Search for "update_card_content_hash" errors
   - Search for "update_content_item_content_hash" errors

3. **Translation freshness complaints**:
   - Monitor user feedback
   - Check if new translations show as "Outdated" immediately

### Long-term: Database Health Check

Add to monthly database health checks:

```sql
-- Monthly check: Ensure no NULL hashes
SELECT 
  'cards' as table_name,
  COUNT(*) as null_count,
  MAX(created_at) as latest_null_created
FROM cards 
WHERE content_hash IS NULL
UNION ALL
SELECT 
  'content_items' as table_name,
  COUNT(*) as null_count,
  MAX(created_at) as latest_null_created
FROM content_items 
WHERE content_hash IS NULL;
```

All counts should be 0.

## Success Criteria

- [ ] SQL script executes without errors
- [ ] Both triggers exist and fire on INSERT + UPDATE
- [ ] No NULL content_hash values remain
- [ ] New cards get content_hash on creation
- [ ] New translations show as "up_to_date" immediately
- [ ] Editing translated content changes status to "outdated"
- [ ] Re-translating updates status back to "up_to_date"

## Related Documentation

- `TRANSLATION_FRESHNESS_BUG_FIX.md` - Technical details and root cause analysis
- `DEPLOY_TRANSLATION_HASH_FIX.sql` - SQL deployment script
- `CLAUDE.md` - Updated with fix notes in "Common Issues" section
- `sql/migrations/add_translation_system.sql` - Updated migration for future deployments

## Timeline

**Estimated deployment time**: 5 minutes  
**Expected downtime**: None (triggers update is instant)  
**User impact**: Existing translated cards may show as outdated until re-translated

## Questions or Issues?

If you encounter any problems during deployment:

1. Check Supabase logs for trigger/function errors
2. Verify triggers exist with the verification queries above
3. Test with a fresh card creation
4. Review `TRANSLATION_FRESHNESS_BUG_FIX.md` for detailed troubleshooting

---

**Deployment Date**: _____________  
**Deployed By**: _____________  
**Verification Completed**: ☐ Yes ☐ No  
**Issues Encountered**: _____________

