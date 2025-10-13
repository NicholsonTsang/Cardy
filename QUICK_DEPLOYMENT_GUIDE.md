# Quick Deployment Guide - Export/Import Fix

## 🎯 What Was Fixed
- ✅ Added **Original Language** field preservation
- ✅ Added **Translations** data preservation  
- ✅ Enhanced image embedding reliability
- ✅ 100% data integrity through export/import cycles

## 🚀 Deployment Steps (IN ORDER)

### Step 1: Deploy Database Functions (CRITICAL - DO FIRST!)
```sql
-- Execute in Supabase Dashboard > SQL Editor
-- Copy and run the entire contents of DEPLOY_TRANSLATION_BULK_UPDATE.sql
```

This creates two new stored procedures:
- `update_card_translations_bulk()`
- `update_content_item_translations_bulk()`

**Verify Success:**
```sql
-- Check if functions exist
SELECT proname FROM pg_proc WHERE proname LIKE '%translations_bulk%';
-- Should return 2 rows
```

### Step 2: Deploy Frontend Code
Already done in your local files. Just commit and deploy:
```bash
git add src/utils/excelConstants.js
git add src/utils/excelHandler.js
git add src/components/Card/Import/CardBulkImport.vue
git commit -m "fix: preserve original_language and translations in export/import"
git push
```

### Step 3: Verify Deployment
1. Open your application
2. Navigate to a card with translations
3. Export the card
4. Check Excel file has 10 columns (Cards) and 9 columns (Content)
5. Delete the card
6. Import the Excel file
7. Verify all data restored including translations

## 📋 Files Changed

### Backend (SQL)
- ✅ `DEPLOY_TRANSLATION_BULK_UPDATE.sql` (new file - deploy first!)

### Frontend (Auto-deployed)
- ✅ `src/utils/excelConstants.js`
- ✅ `src/utils/excelHandler.js`
- ✅ `src/components/Card/Import/CardBulkImport.vue`

## ⚠️ Important Notes

1. **MUST deploy database functions BEFORE frontend**
   - Without them, import will fail when restoring translations
   
2. **Old Excel files still work**
   - They just won't have translations/original_language data
   
3. **New Excel format has more columns**
   - Card sheet: 8 → 10 columns
   - Content sheet: 8 → 9 columns
   
4. **Hidden columns are crucial**
   - Columns I & J (Cards): Crop Data, Translations
   - Columns H & I (Content): Crop Data, Translations
   - These are width=0 (invisible to users)

## 🧪 Quick Test

```bash
# Test the complete cycle
1. Go to card with translations
2. Click Export button
3. Download Excel file
4. Open in Excel - verify 10 columns visible + hidden
5. Delete the original card
6. Import the Excel file
7. Check card restored with:
   - Same name, description ✓
   - Same original_language ✓
   - Same translations (check zh-Hant) ✓
   - Same images ✓
```

## 🔍 Troubleshooting

**Problem:** Import fails with "function does not exist"
- **Solution:** Deploy `DEPLOY_TRANSLATION_BULK_UPDATE.sql` first

**Problem:** Translations not restored after import
- **Solution:** Check browser console for errors, verify stored procedures exist

**Problem:** Excel has wrong number of columns
- **Solution:** Clear browser cache and reload

**Problem:** Old Excel files show errors
- **Solution:** This is expected - old format missing new columns. Data still imports, just without translations.

## ✅ Success Criteria

- [ ] Database functions deployed successfully
- [ ] Frontend code deployed
- [ ] Export creates 10-column Excel (Cards)
- [ ] Export creates 9-column Excel (Content)  
- [ ] Import preserves original_language
- [ ] Import restores all translations
- [ ] Images embed and extract correctly
- [ ] No console errors during import

## 📞 Support

If deployment fails, check:
1. Database migration logs in Supabase Dashboard
2. Browser console for JavaScript errors
3. Network tab for failed RPC calls
4. `EXPORT_IMPORT_COMPLETE_FIX.md` for detailed technical info

---

*Last Updated: October 2025*  
*Status: Ready for Production* ✅

