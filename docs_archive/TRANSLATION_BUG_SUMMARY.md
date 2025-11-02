# Translation "Outdated" Bug - Summary

## What You're Experiencing

After translating your card, you immediately see:
- ❌ "Outdated - 2 needs update" warning
- ❌ Translation status showing as outdated even though nothing changed

## Root Cause

The database triggers that calculate `content_hash` only fire on **UPDATE**, not **INSERT**. This means:

1. When you create a new card → `content_hash` is `NULL`
2. When you translate immediately → Translation stores `content_hash: NULL`
3. When system checks freshness → Compares `NULL == NULL` → Fails → Shows "Outdated"

## The Fix

I've created a complete fix that adds **INSERT triggers** so `content_hash` is calculated when cards are created.

### Files Created

1. **`DEPLOY_TRANSLATION_HASH_FIX.sql`** - Ready-to-deploy SQL script (⭐ USE THIS)
2. **`TRANSLATION_FRESHNESS_BUG_FIX.md`** - Detailed technical explanation
3. **`DEPLOY_INSTRUCTIONS_TRANSLATION_FIX.md`** - Step-by-step deployment guide

### Files Updated

1. **`sql/migrations/add_translation_system.sql`** - Fixed for future deployments
2. **`CLAUDE.md`** - Updated with fix notes in Common Issues section

## How to Fix (Quick Steps)

### 1. Deploy the Fix

```
1. Open Supabase Dashboard → SQL Editor
2. Copy entire contents of: DEPLOY_TRANSLATION_HASH_FIX.sql
3. Paste and click "Run"
4. Verify: Run verification queries (see DEPLOY_INSTRUCTIONS)
```

### 2. What Happens

- ✅ All existing cards get valid `content_hash` values
- ✅ All new cards will automatically get `content_hash` on creation
- ✅ New translations will work correctly
- ⚠️  Existing translations (translated before fix) will still show "outdated"

### 3. Re-translate Affected Cards

Cards that were translated before the fix will need to be re-translated once:
- The stored translation has `content_hash: NULL`
- After backfill, card has valid hash
- Comparison fails → Shows "outdated"
- **Solution**: Re-translate those cards once

### 4. Going Forward

After deployment:
- ✅ All new cards automatically get hash on creation
- ✅ All new translations store valid hash
- ✅ Translation freshness detection works correctly
- ✅ No more false "outdated" warnings

## Technical Details (Optional Reading)

### Before Fix
```sql
CREATE TRIGGER trigger_update_card_content_hash
  BEFORE UPDATE ON cards  -- ❌ Only UPDATE
```

### After Fix
```sql
CREATE TRIGGER trigger_update_card_content_hash
  BEFORE INSERT OR UPDATE ON cards  -- ✅ Both INSERT and UPDATE
```

The trigger function now checks the operation type:
- **INSERT**: Always calculate hash
- **UPDATE**: Calculate only if content changed

## Impact Assessment

### Positive
- ✅ Fix is safe and instant (no downtime)
- ✅ No breaking changes to application code
- ✅ All future translations will work correctly
- ✅ Backfill ensures existing data is valid

### Negative
- ⚠️  Users need to re-translate cards translated before fix
- ⚠️  One-time manual deployment required

### Risk Level
**LOW** - Simple trigger update with automatic backfill

## Next Steps

1. **Review**: Read `DEPLOY_INSTRUCTIONS_TRANSLATION_FIX.md` (5 min)
2. **Deploy**: Execute `DEPLOY_TRANSLATION_HASH_FIX.sql` (2 min)
3. **Verify**: Run verification queries (2 min)
4. **Test**: Create new card and translate (5 min)
5. **Communicate**: Notify users about re-translation need

## Questions?

- **"Will this affect existing cards?"** - No, they get valid hashes via backfill script
- **"Do I need to change application code?"** - No, this is database-only
- **"What about cards being edited right now?"** - Safe, triggers run atomically
- **"Can I rollback if needed?"** - Yes, see DEPLOY_INSTRUCTIONS (emergency only)

## Success Criteria

After deployment, verify:
- [ ] No NULL hashes in database
- [ ] New cards get hash on creation
- [ ] New translations show as "up_to_date" immediately
- [ ] Editing content changes status to "outdated"
- [ ] Re-translating fixes the "outdated" status

## Files to Read (Priority Order)

1. **`DEPLOY_INSTRUCTIONS_TRANSLATION_FIX.md`** ⭐ Start here
2. **`DEPLOY_TRANSLATION_HASH_FIX.sql`** ⭐ Deploy this
3. **`TRANSLATION_FRESHNESS_BUG_FIX.md`** - Deep dive (optional)

---

**TL;DR**: Deploy `DEPLOY_TRANSLATION_HASH_FIX.sql` in Supabase SQL Editor. All new translations will work correctly. Re-translate any cards that were translated before the fix.

