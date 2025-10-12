# Translation Preview Fix - Why the Dropdown Wasn't Showing

## Problem
The language dropdown selector wasn't appearing in the card view or content detail sections.

## Root Cause
The stored procedures `get_user_cards()` and `get_card_content_items()` were NOT returning the translation fields from the database. Without this data, the frontend code couldn't detect if translations existed, so the dropdown never appeared.

## What Was Missing
The stored procedures were returning:
- ❌ Card name, description, images, AI settings
- ❌ NO `translations` field
- ❌ NO `original_language` field  
- ❌ NO `content_hash` field

The frontend code checks `if (availableTranslations.length > 0)` to show the dropdown, but `availableTranslations` was always empty because the data wasn't being fetched!

## Solution Applied

### 1. Updated Stored Procedures (Backend)
Modified three functions to include translation fields:

**`get_user_cards()`** - Now returns:
- ✅ `translations` JSONB
- ✅ `original_language` VARCHAR(10)
- ✅ `content_hash` TEXT
- ✅ `last_content_update` TIMESTAMPTZ

**`get_card_content_items()`** - Now returns:
- ✅ `translations` JSONB
- ✅ `content_hash` TEXT
- ✅ `last_content_update` TIMESTAMPTZ

**`get_content_item_by_id()`** - Now returns:
- ✅ `translations` JSONB
- ✅ `content_hash` TEXT
- ✅ `last_content_update` TIMESTAMPTZ

### 2. Updated TypeScript Interface (Frontend)
Modified `Card` interface in `src/stores/card.ts` to include:
```typescript
translations?: Record<string, any>;
original_language?: string;
content_hash?: string;
last_content_update?: string;
```

## How to Deploy the Fix

### Step 1: Update Database (REQUIRED)
Go to Supabase Dashboard > SQL Editor and execute:

```sql
-- Copy and paste the contents of DEPLOY_TRANSLATION_PREVIEW_FUNCTIONS.sql
```

Or manually run this file: `sql/DEPLOY_TRANSLATION_PREVIEW_FUNCTIONS.sql`

### Step 2: Restart Development Server
```bash
npm run dev
```

### Step 3: Test
1. Open a card that has translations
2. Go to the "General" tab
3. You should now see a language dropdown selector in the top-right of the "Basic Information" section
4. Select a translated language
5. The card name and description should update to show the translation

## Files Changed

### Backend (Database)
- ✅ `sql/storeproc/client-side/02_card_management.sql` (updated `get_user_cards`)
- ✅ `sql/storeproc/client-side/03_content_management.sql` (updated `get_card_content_items` and `get_content_item_by_id`)
- ✅ `sql/all_stored_procedures.sql` (regenerated)
- ✅ `DEPLOY_TRANSLATION_PREVIEW_FUNCTIONS.sql` (deployment script)

### Frontend
- ✅ `src/components/CardComponents/CardView.vue` (already had translation preview code)
- ✅ `src/components/CardContent/CardContentView.vue` (already had translation preview code)
- ✅ `src/stores/card.ts` (updated Card interface)
- ✅ `src/i18n/locales/en.json` (already had translation keys)

## Why This Happened
The translation preview UI components were implemented correctly, but they were trying to access data that wasn't being fetched from the database. It's like building a beautiful display case but forgetting to put anything inside it!

## Verification Checklist
After deploying the fix:

- [ ] Dropdown appears for cards with translations
- [ ] Dropdown hidden for cards without translations
- [ ] Can switch between original and translated languages
- [ ] Card name updates when language changed
- [ ] Card description updates when language changed
- [ ] Content item name updates when language changed (in content detail view)
- [ ] Content item content updates when language changed (in content detail view)

## Additional Fix Applied

### JavaScript Error
After the database fix, encountered:
```
TypeError: SUPPORTED_LANGUAGES.find is not a function
```

**Root Cause**: `SUPPORTED_LANGUAGES` is an object, not an array. The code was trying to use `.find()` which doesn't exist on objects.

**Solution**: Updated helper functions in both components:
```typescript
// Before (WRONG - treating object as array)
const getLanguageName = (langCode) => {
    const lang = SUPPORTED_LANGUAGES.find(l => l.code === langCode);
    return lang ? lang.name : langCode;
};

// After (CORRECT - accessing object by key)
const getLanguageName = (langCode) => {
    return SUPPORTED_LANGUAGES[langCode] || langCode;
};
```

**Files Fixed**:
- ✅ `src/components/CardComponents/CardView.vue`
- ✅ `src/components/CardContent/CardContentView.vue`

## Next Steps
1. Deploy the database update (Step 1 above) ⚠️ **REQUIRED**
2. Restart your development server (already running? Just refresh the page)
3. Test with a translated card
4. If you still don't see the dropdown, check:
   - Does the card actually have translations? (Check `translations` column in database)
   - Are you looking at the "General" tab of CardView?
   - Are you looking at the "Basic Information" section of CardContentView?
   - Check browser console for any errors

## Summary
**Problem**: Stored procedures weren't returning translation data  
**Solution**: Updated 3 stored procedures + TypeScript interface  
**Status**: ✅ Fixed and ready to deploy  
**Action Required**: Run `DEPLOY_TRANSLATION_PREVIEW_FUNCTIONS.sql` in Supabase

---

**Need Help?**
If the dropdown still doesn't appear after deployment:
1. Check if the card has actual translation data in the database
2. Verify the stored procedure was updated (run `SELECT get_user_cards();` and check the columns)
3. Check browser console for JavaScript errors
4. Verify the Card interface includes the new fields

