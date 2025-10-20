# How to Check Edge Function Logs - DEBUG MODE ACTIVE

## ✅ Debugging Edge Function Deployed

I've deployed a version with extensive logging. Now you can see exactly what's happening!

## 🔍 How to View Logs

### Method 1: Supabase Dashboard (Recommended)

1. Go to: https://supabase.com/dashboard/project/mzgusshseqxrdrkvamrg/functions
2. Click on **`translate-card-content`**
3. Click on **Logs** or **Invocations** tab
4. Now try to translate an outdated language in your app
5. Refresh the logs page to see the new logs

### Method 2: Real-time Logs (If Available)

Some versions of Supabase CLI support:
```bash
# Try this (might not work with your CLI version):
supabase functions logs translate-card-content
```

If that doesn't work, use Dashboard (Method 1)

## 📊 What to Look For in Logs

When you try to translate, you should see logs like this:

### Expected Debug Output:

```
=== TRANSLATION FILTER DEBUG ===
Target languages requested: [ 'zh-Hant' ]
Force retranslate: false
Card current hash: abc123def456...
Card translations: { zh-Hant: { name: '...', description: '...', content_hash: 'xyz789...' } }

--- Checking language: zh-Hant ---
zh-Hant: Has existing translation
zh-Hant: Stored hash = xyz789...
zh-Hant: Current hash = abc123def456...
zh-Hant: Hashes match? false
zh-Hant: INCLUDE (outdated - hash mismatch)

=== FILTER RESULT ===
Languages to translate: [ 'zh-Hant' ]
Count: 1
=== END DEBUG ===

Translating 1 languages in parallel...
Starting translation to Traditional Chinese...
```

### Problem Scenarios:

#### Scenario A: Hashes Match (Incorrectly Shows Up-to-Date)
```
zh-Hant: Stored hash = abc123...
zh-Hant: Current hash = abc123...
zh-Hant: Hashes match? true
zh-Hant: SKIP (up-to-date)

=== FILTER RESULT ===
Languages to translate: []
Count: 0

All selected languages are already up-to-date
```

**This means**: The database triggers haven't updated the card's content_hash after you edited it!

**Fix**: Deploy `sql/triggers.sql` to Supabase Dashboard

#### Scenario B: No Existing Translation Found
```
zh-Hant: INCLUDE (no existing translation)
```

**This means**: The language doesn't have a translation record at all.

**This is OK** if you're translating for the first time.

#### Scenario C: Card Has No Translations
```
Card translations: null
```

or

```
Card translations: {}
```

**This means**: The card has no translations at all.

**This is OK** if this is the first translation.

## 🎯 Action Steps Based on Logs

### If Logs Show "Hashes match? true" But They Shouldn't:

1. Check if card was actually updated:
```sql
SELECT id, name, content_hash, updated_at 
FROM cards 
WHERE id = 'YOUR_CARD_ID';
```

2. Update it manually and check if hash changes:
```sql
UPDATE cards SET name = name || ' TEST' WHERE id = 'YOUR_CARD_ID';
SELECT id, name, content_hash FROM cards WHERE id = 'YOUR_CARD_ID';
```

3. If hash didn't change → **Triggers not working** → Deploy `sql/triggers.sql`

### If Logs Show "Languages to translate: []" (Empty Array):

All selected languages were filtered out as up-to-date.

**Check**:
1. Are the languages actually outdated in the database?
2. Run this query:
```sql
SELECT 
    content_hash as current,
    translations->'zh-Hant'->>'content_hash' as stored,
    content_hash = translations->'zh-Hant'->>'content_hash' as match
FROM cards WHERE id = 'YOUR_CARD_ID';
```

If `match = true`, then the database thinks they're up-to-date.

### If Logs Show "Translating X languages..." But No Credits Deducted:

This is a different issue - the translation is running but credit deduction failed.

**Check**:
1. Do you have credits? Run:
```sql
SELECT balance FROM user_credits WHERE user_id = 'YOUR_USER_ID';
```

2. Is the stored procedure working?

## 📋 Quick Diagnostic Checklist

After trying translation, check these in order:

1. **Logs show what?**
   - [ ] "=== TRANSLATION FILTER DEBUG ===" appears
   - [ ] Shows target languages requested
   - [ ] Shows card current hash
   - [ ] Shows stored hash for each language
   - [ ] Shows "Hashes match?" comparison

2. **Hash comparison**:
   - [ ] Stored hash is different from current hash
   - [ ] Language is marked as "INCLUDE (outdated)"
   - [ ] Final count > 0

3. **Translation starts?**:
   - [ ] Sees "Translating X languages in parallel..."
   - [ ] Sees "Starting translation to..."
   - [ ] Sees "Completed translation to..."

4. **Credits deducted?**:
   - [ ] Check credit balance before and after

## 🚨 Most Common Issue

**If you see "Hashes match? true" but you edited the card:**

The database triggers are NOT deployed or NOT working!

**SOLUTION**:
1. Open Supabase Dashboard → SQL Editor
2. Copy and paste ENTIRE contents of `sql/triggers.sql`
3. Click "Run"
4. Try editing card again
5. Hash should change

## 📞 Share Debug Info

If still not working, share these from the logs:
1. The "=== TRANSLATION FILTER DEBUG ===" section
2. The "Hashes match?" value
3. The "=== FILTER RESULT ===" section

This will tell us exactly what's happening!


