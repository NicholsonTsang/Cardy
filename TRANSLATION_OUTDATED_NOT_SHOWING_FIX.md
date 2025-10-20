# Translation "Outdated" Status Not Showing After Content Update

## Problem

When you update card content (name or description), the translation management section does not show translations as "Outdated". The status remains "Up to Date" even though the original content has changed.

## Root Cause

The database triggers that update `content_hash` when content changes are either:
1. Not deployed to your production database, OR
2. Were overwritten by a previous migration

These triggers are essential for the translation freshness detection system:
- **Trigger**: `trigger_update_card_content_hash` on `cards` table
- **Trigger**: `trigger_update_content_item_content_hash` on `content_items` table

When content changes → trigger updates `content_hash` → `get_card_translation_status()` compares embedded translation hashes with current hash → detects mismatch → shows "Outdated"

Without these triggers: content_hash doesn't update → no mismatch detected → always shows "Up to Date" ❌

## Solution

Deploy the content hash update triggers to your database. The triggers are already correctly defined in the source files - you just need to deploy them.

## Deployment Steps

### Step 1: Deploy Source Files

The triggers are already correctly defined in `sql/triggers.sql`. Deploy them to your database:

```bash
# Navigate to Supabase Dashboard > SQL Editor > New Query
# Copy entire contents of: sql/triggers.sql
# Paste and click "Run"

# Or via command line (if you have psql access):
psql "$DATABASE_URL" -f sql/triggers.sql
```

### Step 2: Verify Triggers Are Installed

Run this query in Supabase SQL Editor:

```sql
SELECT 
    tgname AS trigger_name,
    tgenabled AS enabled,
    tgrelid::regclass AS table_name
FROM pg_trigger 
WHERE tgname LIKE '%content_hash%';
```

**Expected output**:
```
trigger_name                             | enabled | table_name
-----------------------------------------|---------|-----------------
trigger_update_card_content_hash         | O       | cards
trigger_update_content_item_content_hash | O       | content_items
```

('O' means trigger is enabled)

### Step 3: Test the Fix

1. **Go to your dashboard** → Open a card with translations
2. **Note the current translation status** (should be "Up to Date")
3. **Edit the card** → Change the name or description
4. **Save the card**
5. **Check translation status** → Should now show "Outdated" ✅

## Technical Details

### How It Works

**Update Flow**:
```
User edits card
  ↓
Frontend calls update_card() stored procedure
  ↓
Database UPDATE statement executed
  ↓
BEFORE UPDATE trigger fires: trigger_update_card_content_hash()
  ↓
Trigger recalculates content_hash = md5(name || '|' || description)
  ↓
Trigger updates last_content_update = NOW()
  ↓
Frontend refreshes translation section
  ↓
get_card_translation_status() compares:
  - translations.zh-Hant.content_hash (old hash)
  - cards.content_hash (new hash)
  ↓
Hashes don't match → status = 'outdated' ✅
```

### Trigger Logic

**For Cards**:
- Monitors changes to: `name`, `description`
- Calculates hash: `md5(name || '|' || description)`
- Only updates if hash wasn't manually set (important for import)

**For Content Items**:
- Monitors changes to: `name`, `content`, `ai_knowledge_base`
- Calculates hash: `md5(name || '|' || content || '|' || ai_knowledge_base)`
- Only updates if hash wasn't manually set (important for import)

### Frontend Refresh Mechanism

Already implemented in `CardView.vue` (lines 371-372):

```javascript
// Refresh translation section to show updated original_language
if (translationSectionRef.value) {
    translationSectionRef.value.loadTranslationStatus();
}
```

This calls `get_card_translation_status()` which detects the hash mismatch and returns 'outdated' status.

## Verification Checklist

After deployment:

- [ ] Triggers exist in database (verification query shows both triggers)
- [ ] Triggers are enabled (enabled = 'O')
- [ ] Update card name → content_hash changes
- [ ] Update card description → content_hash changes  
- [ ] Translation status shows "Outdated" after update
- [ ] "Outdated" count increases in stats box
- [ ] Language tags show amber warning icon
- [ ] TranslationDialog shows languages as "Outdated" (can re-translate)

## Troubleshooting

### Issue: Triggers not found after deployment

**Solution**: 
- Check if you're connected to the correct database (production vs local)
- Re-run the deployment script
- Check for error messages in SQL Editor

### Issue: Triggers exist but status still not updating

**Possible causes**:
1. **Cache issue**: Hard refresh the browser (Cmd+Shift+R on Mac, Ctrl+Shift+R on Windows)
2. **Translation section not refreshing**: Check browser console for errors
3. **Database connection**: Check Supabase project status

**Debug query**:
```sql
-- Check current hash and translation hashes for a card
SELECT 
    id,
    name,
    content_hash as current_hash,
    translations->'zh-Hant'->>'content_hash' as translation_hash,
    last_content_update
FROM cards 
WHERE id = '<your_card_id>';
```

If `current_hash` ≠ `translation_hash` but status still shows "Up to Date", the frontend is not refreshing properly.

### Issue: Triggers firing but frontend not showing "Outdated"

**Solution**:
1. Open browser DevTools → Network tab
2. Edit card and save
3. Look for RPC call to `get_card_translation_status`
4. Check response - should show `status: 'outdated'`
5. If response is correct but UI not updating, check Vue component reactivity

## Related Files

- **Trigger SQL**: `sql/triggers.sql` (lines 73-150)
- **Deployment Script**: `DEPLOY_TRANSLATION_HASH_TRIGGER_FIX.sql` (this fix)
- **Frontend Refresh**: `src/components/CardComponents/CardView.vue` (lines 371-372)
- **Status Function**: `sql/storeproc/client-side/12_translation_management.sql` (lines 22-143)
- **Translation Section**: `src/components/Card/CardTranslationSection.vue`

## Prevention

**Going forward**:
- Always include `sql/triggers.sql` when deploying database updates
- Verify triggers exist after each deployment
- Add trigger verification to deployment checklist

## Notes

- Triggers are **essential** for translation freshness detection
- Without triggers, translations will never show as outdated
- Triggers are designed to work with import (skip hash calculation if hash provided)
- Frontend refresh mechanism is already implemented and working
- The issue is purely on the database trigger side

