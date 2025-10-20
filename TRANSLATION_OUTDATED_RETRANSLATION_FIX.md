# Translation Edge Function Fix - Outdated Languages Not Retranslating

## ✅ Issue Fixed

When selecting outdated languages for re-translation, the edge function was not processing them correctly.

## 🐛 Root Cause

The edge function had a logic bug in `supabase/functions/translate-card-content/index.ts`:

1. ✅ **Correctly** filtered languages to translate (lines 164-175)
   - Skipped up-to-date languages (unless forceRetranslate=true)
   - **Included** outdated languages (hash mismatch)
   - **Included** not-translated languages

2. ❌ **Incorrectly** passed ALL selected languages to stored procedure (line 264)
   - Used `targetLanguages` (all selected) instead of `languagesToTranslate` (filtered)
   - Charged credits for all selected languages, not just translated ones
   - Caused mismatch between what was translated and what was stored

## 🔧 Fix Applied

### Change 1: Early Return for Up-to-Date Languages

**Lines 177-193**: Added early return if no languages need translation

```typescript
// If no languages need translation, return early
if (languagesToTranslate.length === 0) {
  console.log('All selected languages are already up-to-date');
  return new Response(
    JSON.stringify({
      success: true,
      message: 'All selected languages are already up-to-date',
      translated_languages: [],
      credits_used: 0,
      remaining_balance: 0,
    }),
    {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    }
  );
}
```

### Change 2: Moved Credit Check After Filtering

**Lines 197-212**: Moved credit calculation and check to AFTER filtering

- Now calculates credits based on `languagesToTranslate.length` (filtered)
- Not `targetLanguages.length` (all selected)
- Only charges for languages that will actually be translated

### Change 3: Use Filtered List in Stored Procedure

**Lines 265-268**: Changed stored procedure call to use filtered list

```typescript
const { data: result, error: storeError } = await supabaseAdmin.rpc(
  'store_card_translations',
  {
    p_user_id: user.id,
    p_card_id: cardId,
    p_target_languages: languagesToTranslate, // ✅ Use filtered list
    p_card_translations: cardTranslations,
    p_content_items_translations: contentItemsTranslations,
    p_credit_cost: languagesToTranslate.length, // ✅ Charge only for translated languages
  }
);
```

**Before**: `p_target_languages: targetLanguages` (all selected)  
**After**: `p_target_languages: languagesToTranslate` (only outdated/not-translated)

## 📝 What This Fixes

### Before Fix:
```
User selects: [outdated: zh-Hant, up-to-date: ja, not-translated: ko]
  ↓
Edge function filters: languagesToTranslate = [zh-Hant, ko]
  ↓
Edge function translates: zh-Hant ✅, ko ✅
  ↓
Edge function stores with: targetLanguages = [zh-Hant, ja, ko] ❌
  ↓
Stored procedure tries to process 'ja' but no translation data ❌
  ↓
Result: Error or incomplete storage ❌
```

### After Fix:
```
User selects: [outdated: zh-Hant, up-to-date: ja, not-translated: ko]
  ↓
Edge function filters: languagesToTranslate = [zh-Hant, ko]
  ↓
Edge function returns early if empty ✅
  ↓
Edge function checks credits for 2 languages (not 3) ✅
  ↓
Edge function translates: zh-Hant ✅, ko ✅
  ↓
Edge function stores with: languagesToTranslate = [zh-Hant, ko] ✅
  ↓
Stored procedure processes only translated languages ✅
  ↓
Result: Success, charged 2 credits (not 3) ✅
```

## 🧪 Testing

### Test Case 1: Select Outdated Languages
1. Update card content (makes existing translations outdated)
2. Open translation dialog
3. Select 1-2 outdated languages
4. Click "Translate"
5. ✅ **Expected**: Languages are retranslated and show "Up to Date"
6. ✅ **Expected**: Credits charged = number of outdated languages selected

### Test Case 2: Mix of Statuses
1. Select mix: 1 outdated, 1 not-translated, 1 up-to-date (checkbox disabled)
2. Click "Translate"
3. ✅ **Expected**: Only outdated and not-translated are processed
4. ✅ **Expected**: Credits charged = 2 (not 3)

### Test Case 3: All Up-to-Date
1. Try to select only up-to-date languages (should be disabled)
2. If somehow selected (shouldn't be possible):
3. ✅ **Expected**: Early return with message "All selected languages are already up-to-date"
4. ✅ **Expected**: No credits charged

## 📂 Files Modified

- ✅ **Modified**: `supabase/functions/translate-card-content/index.ts`
  - Lines 163-217: Reorganized filtering and credit check logic
  - Lines 265-268: Use filtered list in stored procedure call
  - Lines 177-193: Added early return for empty filtered list

## 🚀 Deployment

This is an **Edge Function** fix, so you need to deploy the Edge Function:

```bash
# Option 1: Deploy just this function
npx supabase functions deploy translate-card-content

# Option 2: Deploy all functions
./scripts/deploy-edge-functions.sh
```

### Verify Deployment

After deploying, test by:
1. Updating a card to make translations outdated
2. Selecting outdated languages in translation dialog
3. Verifying they retranslate successfully

Check Edge Function logs:
```bash
npx supabase functions logs translate-card-content --follow
```

Should see:
```
Translating 2 languages in parallel...
Starting translation to Traditional Chinese...
Starting translation to Korean...
Completed translation to Traditional Chinese
Completed translation to Korean
```

## 🎯 Impact

### Before Fix:
- ❌ Outdated languages couldn't be retranslated
- ❌ Credit calculation was wrong
- ❌ Users charged for languages that weren't translated
- ❌ Confusing errors in edge function logs

### After Fix:
- ✅ Outdated languages retranslate correctly
- ✅ Credits charged accurately (only for translated languages)
- ✅ No wasteful API calls for up-to-date languages
- ✅ Clear logging and early return for edge cases

## 📚 Related

- **Issue**: Outdated languages not processing in edge function
- **Related Fix**: See `DEPLOY_TRANSLATION_FIXES.md` for database trigger deployment
- **Documentation**: Updated `CLAUDE.md` Common Issues section


