# 🚀 Quick Deploy Instructions - Translation Preservation Fix

## ✅ What Changed

**Source File Updated**: `sql/storeproc/client-side/12_translation_management.sql`  
**Combined File Regenerated**: `sql/all_stored_procedures.sql`  
**Frontend Updated**: `src/components/Card/Import/CardBulkImport.vue`

---

## 📝 Deploy Steps

### 1️⃣ Deploy Database Functions (REQUIRED)

**Option A: Deploy All Functions (Recommended)**
```sql
-- In Supabase Dashboard > SQL Editor
-- Copy entire contents of: sql/all_stored_procedures.sql
-- Execute
```

**Option B: Deploy Only New Functions**
```sql
-- In Supabase Dashboard > SQL Editor
-- Copy entire contents of: DEPLOY_TRANSLATION_HASH_RECALCULATION.sql
-- Execute
```

**Verify Deployment:**
```sql
SELECT proname, prokind FROM pg_proc 
WHERE proname IN (
  'update_card_translations_bulk',
  'update_content_item_translations_bulk',
  'recalculate_card_translation_hashes',
  'recalculate_content_item_translation_hashes',
  'recalculate_all_translation_hashes'
);

-- Should return 5 rows
```

### 2️⃣ Deploy Frontend Code

```bash
git add sql/storeproc/client-side/12_translation_management.sql
git add sql/all_stored_procedures.sql
git add src/components/Card/Import/CardBulkImport.vue
git add src/utils/excelConstants.js
git add src/utils/excelHandler.js
git add CLAUDE.md
git commit -m "fix: preserve translations and content hash on import"
git push
```

---

## 🧪 Quick Test

1. Create card with translation
2. Export
3. Delete card
4. Import Excel
5. Check Translation Management → Should show "Up to Date" ✓

---

## 📚 Files You Can Archive/Delete

These were temporary deployment files, now superseded:

```bash
# Can delete or move to docs_archive/
DEPLOY_TRANSLATION_BULK_UPDATE.sql
DEPLOY_TRANSLATION_HASH_RECALCULATION.sql
DEPLOY_NOW_CRITICAL_FIX.md
CRITICAL_EXPORT_IMPORT_ISSUES_FOUND.md
COMPLETE_EXPORT_IMPORT_FIX_FINAL.md
```

**Keep for reference:**
```
EXPORT_IMPORT_TRANSLATION_FIX_FINAL.md  ← Main documentation
```

---

## ⚠️ Important Notes

1. **Database FIRST**: Deploy database functions before frontend
2. **Both files work**: Either deploy `all_stored_procedures.sql` (all functions) OR `DEPLOY_TRANSLATION_HASH_RECALCULATION.sql` (just new ones)
3. **Source is truth**: The real source is `sql/storeproc/client-side/12_translation_management.sql` - future changes go there
4. **Run combine script**: After editing source files, always run `./scripts/combine-storeproc.sh`

---

*Ready to deploy? Follow steps 1️⃣ and 2️⃣ above!*

