# Deploy Translation Fixes - Complete Guide

## ✅ Issues Fixed

1. **Import shows "Outdated"** - Fixed in frontend (`CardBulkImport.vue`)
2. **Update doesn't show "Outdated"** - Fixed in source files (triggers already correct)

## 🚀 Deployment Steps

### Step 1: Frontend Deployment

Build and deploy the frontend with the import fix:

```bash
# Build for production
npm run build:production

# Deploy dist/ folder to your hosting service
```

### Step 2: Database Deployment

The triggers and stored procedures are already correctly defined in the source files. You just need to deploy them to your production database.

#### Option A: Deploy via Supabase Dashboard (Recommended)

**Execute in this order**:

1. **Triggers** (`sql/triggers.sql`)
   - Navigate to: Supabase Dashboard → SQL Editor → New Query
   - Copy entire contents of `sql/triggers.sql`
   - Paste and click "Run"

2. **Stored Procedures** (`sql/all_stored_procedures.sql`)
   - Navigate to: Supabase Dashboard → SQL Editor → New Query
   - Copy entire contents of `sql/all_stored_procedures.sql`
   - Paste and click "Run"

**Note**: You can also deploy `sql/schema.sql` and `sql/policy.sql` if you haven't already, but they're not required for this specific fix.

#### Option B: Deploy via Command Line

If you have psql access to your database:

```bash
# Deploy triggers
psql "$DATABASE_URL" -f sql/triggers.sql

# Deploy stored procedures  
psql "$DATABASE_URL" -f sql/all_stored_procedures.sql
```

### Step 3: Verification

After deployment, verify the triggers are installed:

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

### Step 4: Testing

#### Test Issue 1 (Import Fix)
1. Export a card with translations
2. Import the Excel file
3. ✅ **Expected**: Translations show "Up to Date"
4. ❌ **Not**: Translations show "Outdated" immediately

#### Test Issue 2 (Update Fix)
1. Open a card with translations
2. Edit the card name or description
3. Save changes
4. ✅ **Expected**: Translations show "Outdated"
5. ❌ **Not**: Translations remain "Up to Date"

## 📝 What Was Fixed

### Frontend Fix (Issue 1)

**File**: `src/components/Card/Import/CardBulkImport.vue` (line ~1134)

Added automatic hash synchronization after import:

```javascript
// CRITICAL: Recalculate all translation hashes to sync with newly created card
try {
  importStatus.value = 'Synchronizing translation hashes...';
  const { error: hashError } = await supabase.rpc('recalculate_all_translation_hashes', {
    p_card_id: cardId
  });
  // ... error handling
}
```

### Source Files (Issue 2)

**Files Already Correct** - Just need deployment:

1. **`sql/triggers.sql`** (lines 73-150)
   - `update_card_content_hash()` function
   - `trigger_update_card_content_hash` trigger
   - `update_content_item_content_hash()` function
   - `trigger_update_content_item_content_hash` trigger

2. **`sql/storeproc/client-side/12_translation_management.sql`** (lines 658-694)
   - `recalculate_all_translation_hashes()` function
   - Proper GRANT permissions

3. **`sql/all_stored_procedures.sql`** (GENERATED)
   - Regenerated from source files via `./scripts/combine-storeproc.sh`

## 🔍 How It Works

### Normal Workflow
```
Create card → content_hash calculated (trigger)
    ↓
Translate → translations stored with current hash
    ↓
Update content → content_hash recalculated (trigger) ← Issue 2 Fix
    ↓
Frontend refreshes → detects hash mismatch
    ↓
Shows "Outdated" ✅
```

### Import Workflow
```
Import Excel → new card created with new hash
    ↓
recalculate_all_translation_hashes() runs ← Issue 1 Fix
    ↓
Embedded hashes updated to match new card
    ↓
Shows "Up to Date" ✅
```

## 🛠 Troubleshooting

### Triggers not found after deployment

**Debug**:
```sql
-- Check if trigger functions exist
SELECT proname FROM pg_proc 
WHERE proname LIKE '%content_hash%';
```

**Solution**: Re-run `sql/triggers.sql` in Supabase Dashboard

### Triggers exist but status not updating

**Debug**:
```sql
-- Test trigger manually
SELECT id, name, content_hash, last_content_update 
FROM cards WHERE id = '<your_card_id>';

-- Update the card
UPDATE cards SET name = name || ' ' WHERE id = '<your_card_id>';

-- Check if hash changed
SELECT id, name, content_hash, last_content_update 
FROM cards WHERE id = '<your_card_id>';
```

If `content_hash` didn't change, the trigger is not firing. Check:
1. Trigger is enabled (`SELECT * FROM pg_trigger WHERE tgname = 'trigger_update_card_content_hash';`)
2. No errors in Supabase logs

### Frontend not refreshing

**Debug**:
- Open browser DevTools → Console
- Update a card and save
- Look for RPC call to `get_card_translation_status`
- Response should show `status: 'outdated'`

If status is correct but UI not updating:
- Hard refresh browser (Cmd+Shift+R / Ctrl+Shift+R)
- Clear browser cache

## 📚 Related Documentation

- **Full Technical Details**: `TRANSLATION_ISSUES_COMPLETE_FIX.md`
- **Issue 1 Explanation**: `IMPORT_TRANSLATION_HASH_FIX.md`
- **Issue 2 Explanation**: `TRANSLATION_OUTDATED_NOT_SHOWING_FIX.md`
- **Source Files**: 
  - `sql/triggers.sql`
  - `sql/storeproc/client-side/12_translation_management.sql`
  - `sql/all_stored_procedures.sql` (generated)
- **Frontend Fix**: `src/components/Card/Import/CardBulkImport.vue`

## 🎯 Quick Checklist

### Pre-Deployment
- [x] Frontend code updated
- [x] Source files already correct
- [x] all_stored_procedures.sql regenerated
- [ ] Ready to deploy

### Deployment
- [ ] Build frontend: `npm run build:production`
- [ ] Deploy frontend (upload dist/)
- [ ] Execute `sql/triggers.sql` in Supabase
- [ ] Execute `sql/all_stored_procedures.sql` in Supabase

### Verification
- [ ] Triggers exist (verification query)
- [ ] Triggers enabled (enabled = 'O')
- [ ] Test import → translations "Up to Date"
- [ ] Test update → translations "Outdated"

## ✅ Success Criteria

After deployment, both workflows should work correctly:

1. **Import**: Cards with translations import and show "Up to Date" ✅
2. **Update**: Editing content marks translations as "Outdated" ✅
3. **No errors**: Browser console and Supabase logs clean ✅

You're all set! 🚀


