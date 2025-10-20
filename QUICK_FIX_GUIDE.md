# Quick Fix Guide - Outdated Languages Not Retranslating

## ✅ What We've Done

1. ✅ **Fixed import hash issue** - `CardBulkImport.vue` updated
2. ✅ **Verified source files** - Triggers and stored procedures correct
3. ✅ **Fixed edge function** - Filtering logic corrected
4. ✅ **Deployed edge function** - `translate-card-content` deployed to Supabase

## ⚠️ What You Need To Do

### **Most Likely Issue: Database Triggers Not Deployed**

The edge function is now deployed, but if the database triggers aren't deployed to your production database, the system won't detect when content becomes outdated.

## 🚀 Quick Fix (2 Minutes)

### Step 1: Deploy Database Files

Open **Supabase Dashboard** → **SQL Editor** → **New Query**

**Execute these in order:**

1. **Copy and paste entire contents of `sql/triggers.sql`** → Click "Run"
2. **Copy and paste entire contents of `sql/all_stored_procedures.sql`** → Click "Run"

### Step 2: Verify Triggers Installed

In SQL Editor, run:

```sql
SELECT tgname FROM pg_trigger WHERE tgname LIKE '%content_hash%';
```

**Expected result**: 2 rows
- `trigger_update_card_content_hash`
- `trigger_update_content_item_content_hash`

If you don't see 2 triggers, repeat Step 1.

### Step 3: Test the Fix

1. **Edit a card** with translations (change name or description)
2. **Save changes**
3. **Check Multi-Language Support section** → Outdated count should increase
4. **Click "Manage Translations"** → Select outdated language(s)
5. **Click "Translate"** → Should process and deduct credits ✅

## 🔍 Still Not Working?

### Use the Verification Script

Open `VERIFY_TRANSLATION_SYSTEM.sql` in Supabase SQL Editor and run each section:

1. **Check triggers** (should find 2)
2. **Check functions** (should find 5)
3. **Test hash update** (use your card ID)
4. **Check translation status** (use your card ID)
5. **Verify hashes match** (use your card ID)
6. **Check credit balance** (use your user ID)

### Debug with Edge Function Logs

```bash
# In terminal:
npx supabase functions logs translate-card-content --follow

# Then try translating in the browser
# Watch for logs showing:
# "Translating X languages in parallel..."
```

## 📋 Complete Verification Checklist

- [ ] **Edge Function Deployed**: ✅ Already done
- [ ] **Triggers Deployed**: Run `sql/triggers.sql` in Supabase
- [ ] **Stored Procedures Deployed**: Run `sql/all_stored_procedures.sql` in Supabase
- [ ] **Triggers Verified**: SQL query shows 2 triggers
- [ ] **Content Update Test**: Edit card → hash changes
- [ ] **Status Update Test**: Edit card → shows "Outdated"
- [ ] **Retranslation Test**: Select outdated → translates successfully
- [ ] **Credit Deduction**: Credits deducted correctly
- [ ] **Final Status**: After translation → shows "Up to Date"

## 💡 Common Scenarios

### Scenario A: Triggers Missing
**Symptom**: Edit card but translations never show "Outdated"  
**Fix**: Deploy `sql/triggers.sql`

### Scenario B: Functions Missing
**Symptom**: Edge function fails with "function does not exist"  
**Fix**: Deploy `sql/all_stored_procedures.sql`

### Scenario C: Frontend Cache
**Symptom**: Everything deployed but UI not updating  
**Fix**: Hard refresh browser (Cmd+Shift+R or Ctrl+Shift+R)

### Scenario D: No Credits
**Symptom**: Translation fails with "Insufficient credits"  
**Fix**: Purchase credits via `/cms/credits` page

## 📞 Still Stuck?

If you've completed all steps and it's still not working:

1. Run the verification script (`VERIFY_TRANSLATION_SYSTEM.sql`)
2. Share the output from each section
3. Check browser console for JavaScript errors
4. Check edge function logs for errors

The most common issue is **Step 1 not completed** - make sure you've deployed both SQL files to Supabase!


