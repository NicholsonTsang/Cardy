# Test Outdated Language Retranslation

## ✅ Edge Function Deployed

The fixed `translate-card-content` edge function has been deployed successfully.

## 🧪 Testing Steps

### Step 1: Create Outdated Translations

1. Open a card that has translations (e.g., English + Chinese)
2. Verify translations show "Up to Date" (green checkmark)
3. Edit the card name or description
4. Save changes
5. **Verify**: Translations should now show "Outdated" (amber warning icon)

### Step 2: Test Retranslation

1. Click "Manage Translations" button
2. You should see the outdated language with an amber warning icon
3. Select the outdated language(s)
4. Click "Translate" button
5. Confirm credit usage
6. **Watch for**:
   - Translation progress dialog
   - Success message after completion
   - Credits should be deducted
   - Languages should show "Up to Date" again

### Step 3: Check Logs (If Issue Persists)

Open a terminal and run:

```bash
# Stream edge function logs in real-time
npx supabase functions logs translate-card-content --follow
```

Then try the retranslation again and watch for these log messages:

**Expected logs** (working correctly):
```
Translating 1 languages in parallel...
Starting translation to Traditional Chinese...
Completed translation to Traditional Chinese
```

**Problem indicators**:
```
All selected languages are already up-to-date
# This means the filtering logic thinks they're up-to-date
```

OR

```
Credit check failed: ...
# This means there's a credit balance issue
```

## 🔍 Debug Information

### Check Translation Status

In browser console, after selecting outdated languages:

```javascript
// Open browser DevTools → Console
// Check what languages are being sent

// When you click Translate, you should see a POST request to:
// https://your-project.supabase.co/functions/v1/translate-card-content

// Check the request body:
{
  "cardId": "...",
  "targetLanguages": ["zh-Hant"], // Should be the outdated languages
  "forceRetranslate": false
}
```

### Check Response

**Success response** (working):
```json
{
  "success": true,
  "translated_languages": ["zh-Hant"],
  "credits_used": 1,
  "remaining_balance": 99
}
```

**Early return** (not working - means filtering removed all languages):
```json
{
  "success": true,
  "message": "All selected languages are already up-to-date",
  "translated_languages": [],
  "credits_used": 0,
  "remaining_balance": 100
}
```

## 🐛 Common Issues

### Issue 1: Database Triggers Not Deployed

**Symptom**: Translations never show as "Outdated" after content update  
**Solution**: Deploy `sql/triggers.sql` to Supabase Dashboard

```sql
-- Check if triggers exist:
SELECT tgname FROM pg_trigger WHERE tgname LIKE '%content_hash%';

-- Should return 2 triggers
```

### Issue 2: Content Hash Not Updating

**Symptom**: Edit card but hash stays the same  
**Test**:

```sql
-- Get current hash
SELECT id, name, content_hash FROM cards WHERE id = 'YOUR_CARD_ID';

-- Update card
UPDATE cards SET name = name || ' ' WHERE id = 'YOUR_CARD_ID';

-- Check hash again - should be different
SELECT id, name, content_hash FROM cards WHERE id = 'YOUR_CARD_ID';
```

### Issue 3: Translation Hash Mismatch

**Symptom**: Card hash changed but still shows "Up to Date"  
**Test**:

```sql
-- Check card and translation hashes
SELECT 
    id,
    name,
    content_hash as card_hash,
    translations->'zh-Hant'->>'content_hash' as translation_hash
FROM cards 
WHERE id = 'YOUR_CARD_ID';

-- If card_hash != translation_hash, it should show "Outdated"
```

### Issue 4: Frontend Not Passing Outdated Languages

**Check**: Open browser Network tab
- Look for POST request to `translate-card-content`
- Check request payload `targetLanguages` array
- Should contain the outdated languages you selected

## 📊 Verification Checklist

After deployment, verify:

- [ ] Edge function deployed: ✅ (Confirmed)
- [ ] Database triggers deployed: ⚠️ (Check with SQL query above)
- [ ] Card update creates outdated status: Test by editing card
- [ ] Outdated languages appear in dialog with amber icon
- [ ] Selecting outdated languages and clicking Translate works
- [ ] Credits are deducted correctly
- [ ] After translation, languages show "Up to Date"
- [ ] Edge function logs show translation happening

## 🔧 Quick Fixes

### Re-deploy Database Triggers

If triggers are missing:

```bash
# In Supabase Dashboard → SQL Editor
# Execute: sql/triggers.sql
# Execute: sql/all_stored_procedures.sql
```

### Force Refresh Translation Status

In browser console:

```javascript
// Force refresh translation status
location.reload();
```

### Clear Browser Cache

Sometimes old JavaScript is cached:
- Chrome/Edge: Cmd+Shift+R (Mac) or Ctrl+Shift+R (Windows)
- Firefox: Cmd+Shift+R (Mac) or Ctrl+F5 (Windows)
- Safari: Cmd+Option+R

## 📞 Need Help?

If still not working:

1. Share the edge function logs
2. Share the SQL query results (translation status check)
3. Share browser console errors (if any)
4. Check if triggers are deployed


