# Original Language Field - Complete Fix

## Problem Summary
When creating or editing a card, the `original_language` field was not being saved or displayed correctly. Users could select a language in the dropdown, but after saving and refreshing, it would revert to English.

## Root Cause Analysis

There were **TWO separate issues**:

### Issue 1: Frontend Not Sending the Field ✅ FIXED
**Location**: `src/stores/card.ts`

The card store had three problems:
1. **Missing TypeScript interface field**: `CardFormData` didn't include `original_language`
2. **Missing RPC parameter in create**: `addCard()` didn't pass `p_original_language` to database
3. **Missing RPC parameter in update**: `updateCard()` didn't pass `p_original_language` to database

**Status**: ✅ Fixed in commit (TypeScript + Store methods updated)

### Issue 2: Database Not Returning the Field ⚠️ NEEDS DEPLOYMENT
**Location**: `sql/storeproc/client-side/02_card_management.sql`

The `get_card_by_id` stored procedure was **missing 7 important fields**:
- ❌ `original_language` (the main issue)
- ❌ `original_image_url`
- ❌ `crop_parameters`
- ❌ `translations`
- ❌ `content_hash`
- ❌ `last_content_update`

**Result**: Even though we save `original_language`, when we retrieve the card to display/edit it, the database doesn't return that field, so the form shows the default (English).

**Status**: ⚠️ Fixed in code, **REQUIRES DATABASE DEPLOYMENT**

## Complete Fix

### Part 1: Frontend (Already Applied) ✅

**File**: `src/stores/card.ts`

1. Added `original_language` to `CardFormData` interface:
```typescript
export interface CardFormData {
    // ... other fields
    original_language?: string; // ✅ Added
    id?: string;
}
```

2. Added parameter to `addCard` RPC call:
```typescript
p_original_language: cardData.original_language || 'en'
```

3. Added parameter to `updateCard` RPC call:
```typescript
p_original_language: updateData.original_language || 'en'
```

### Part 2: Database (NEEDS DEPLOYMENT) ⚠️

**File**: `sql/storeproc/client-side/02_card_management.sql`

Updated `get_card_by_id` stored procedure to return all fields:

**Before** (Incomplete):
```sql
RETURNS TABLE (
    id UUID,
    user_id UUID,
    name TEXT,
    description TEXT,
    qr_code_position TEXT,
    image_url TEXT,
    conversation_ai_enabled BOOLEAN,
    ai_instruction TEXT,
    ai_knowledge_base TEXT,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ
)
```

**After** (Complete):
```sql
RETURNS TABLE (
    id UUID,
    user_id UUID,
    name TEXT,
    description TEXT,
    qr_code_position TEXT,
    image_url TEXT,
    original_image_url TEXT,        -- ✅ Added
    crop_parameters JSONB,            -- ✅ Added
    conversation_ai_enabled BOOLEAN,
    ai_instruction TEXT,
    ai_knowledge_base TEXT,
    translations JSONB,               -- ✅ Added
    original_language VARCHAR(10),    -- ✅ Added (main fix)
    content_hash TEXT,                -- ✅ Added
    last_content_update TIMESTAMPTZ,  -- ✅ Added
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ
)
```

## Deployment Instructions

### Step 1: Frontend (No Action Needed)
The frontend changes are already in the codebase and will take effect automatically.

### Step 2: Database (REQUIRED ACTION)
You **MUST** deploy the stored procedure fix to the database:

**Option A: Via Supabase Dashboard (Recommended)**
1. Open Supabase Dashboard
2. Go to SQL Editor
3. Open the file: `DEPLOY_GET_CARD_BY_ID_FIX.sql`
4. Copy all contents
5. Paste into SQL Editor
6. Click "Run"

**Option B: Via CLI**
```bash
# If you have psql installed
psql "$DATABASE_URL" -f DEPLOY_GET_CARD_BY_ID_FIX.sql
```

## Testing After Deployment

1. **Create New Card Test**:
   - Create a new card
   - Select "Traditional Chinese" (or any non-English language) as Original Language
   - Fill in other required fields
   - Save the card
   - Refresh the page
   - Open the card for editing
   - ✅ Original Language dropdown should show "Traditional Chinese"

2. **Edit Existing Card Test**:
   - Open an existing card
   - Change Original Language from "English" to "Japanese"
   - Save changes
   - Refresh the page
   - Open the card again
   - ✅ Original Language should show "Japanese"

3. **Database Verification**:
   ```sql
   -- Run in SQL Editor to check if original_language is saved
   SELECT id, name, original_language FROM cards LIMIT 10;
   ```

## Why Both Fixes Are Needed

```
┌─────────────────────┐
│   User Interface    │
│  (Form Dropdown)    │
└──────────┬──────────┘
           │
           │ Save Event
           ▼
┌─────────────────────┐
│   Frontend Store    │  ◄─── Issue #1: Not passing p_original_language
│   (card.ts)         │       ✅ FIXED
└──────────┬──────────┘
           │
           │ RPC Call: create_card / update_card
           ▼
┌─────────────────────┐
│    Database         │
│  (Stored Procs)     │  
└──────────┬──────────┘
           │
           │ RPC Call: get_card_by_id
           ▼
┌─────────────────────┐
│   Frontend Store    │  ◄─── Issue #2: Not returning original_language
│   (Loads card data) │       ⚠️ NEEDS DB DEPLOYMENT
└──────────┬──────────┘
           │
           │ Data binding
           ▼
┌─────────────────────┐
│   User Interface    │
│  (Shows in form)    │
└─────────────────────┘
```

**Without Fix #1**: Data never reaches database → Always saves as 'en'  
**Without Fix #2**: Data is in database but never retrieved → Always displays 'en'  
**With Both Fixes**: Data is saved AND retrieved correctly → Works as expected ✅

## Impact & Safety

- **Risk Level**: Low
- **Breaking Changes**: None
- **Backward Compatibility**: Full (default to 'en' if field is missing)
- **Data Migration**: Not required (existing cards will use default)
- **Rollback**: Simple (just revert the stored procedure)

## Related Features

This fix is critical for:
- ✅ Translation Management System
- ✅ AI Language Detection
- ✅ Content Organization
- ✅ Translation Status Tracking
- ✅ Multi-language Support

## Files Modified

### Frontend (Git committed)
- `src/stores/card.ts` - Added interface field + RPC parameters
- `ORIGINAL_LANGUAGE_FIELD_FIX.md` - Initial fix documentation

### Database (Deployment pending)
- `sql/storeproc/client-side/02_card_management.sql` - Updated `get_card_by_id`
- `sql/all_stored_procedures.sql` - Regenerated combined file
- `DEPLOY_GET_CARD_BY_ID_FIX.sql` - Deployment script

### Documentation
- `ORIGINAL_LANGUAGE_COMPLETE_FIX.md` - This file

## Status Checklist

- [x] Issue #1: Frontend not sending field → **FIXED** ✅
- [ ] Issue #2: Database not returning field → **NEEDS DEPLOYMENT** ⚠️
- [ ] Deploy `DEPLOY_GET_CARD_BY_ID_FIX.sql` to Supabase
- [ ] Test card creation with non-English language
- [ ] Test card editing and language persistence
- [ ] Verify translation feature uses correct source language

---

## Next Steps for User

**IMPORTANT**: To complete the fix, you must:

1. ✅ Frontend changes are already in place (no action needed)
2. ⚠️ **Run the database deployment script**:
   - Open `DEPLOY_GET_CARD_BY_ID_FIX.sql`
   - Copy to Supabase Dashboard > SQL Editor
   - Execute the script
3. ✅ Test the feature as described above

Once the database script is deployed, the original language feature will work completely!

---

**Fix Date**: 2025-01-12  
**Status**: Frontend ✅ Complete | Database ⚠️ Pending Deployment

