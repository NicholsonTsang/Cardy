# Translation Failed Language Handling - November 8, 2025

**Date:** November 8, 2025  
**Status:** ✅ IMPLEMENTED  
**Impact:** Major UX Improvement - Users can now see which languages succeeded/failed and retry failed ones

---

## Feature Overview

Enhanced Translation Dialog to accurately show which languages succeeded and which failed during translation, with a one-click retry button for failed languages.

### Before ❌
- Dialog showed all selected languages as "success" even if some failed
- No way to tell which languages actually translated
- No easy way to retry failed languages
- Users had to manually re-select failed languages

### After ✅
- Step 3 shows separate lists for successful and failed languages
- Clear visual distinction (green for success, red for failure, yellow for partial)
- One-click "Retry Failed Languages" button
- Automatic pre-selection of failed languages for retry

---

## Implementation

### 1. Backend Response (Already Correct)

The backend `/api/translations/translate-card` endpoint already returns:

```typescript
{
  success: true,
  message: 'Translation completed',
  translated_languages: ['zh-Hant', 'zh-Hans', 'ko'],  // ✅ Success
  failed_languages: ['ja'],  // ❌ Failed
  credits_used: 3,
  duration: 35.4
}
```

### 2. Frontend Interface Update

**File:** `src/stores/translation.ts`

Updated `TranslateCardResponse` interface to match backend response:

```typescript
export interface TranslateCardResponse {
  success: boolean;
  message: string;
  job_id?: string | null;  // Optional for backward compatibility
  status?: 'pending' | 'processing' | 'completed' | 'failed' | 'cancelled';
  languages?: string[];  // Optional for backward compatibility
  credits_reserved?: number;  // Optional for backward compatibility
  translated_languages: string[];  // ✅ Successfully translated languages
  failed_languages: string[];  // ❌ Failed translations
  credits_used: number;
  duration: number;
}
```

### 3. Dialog State Management

**File:** `src/components/Card/TranslationDialog.vue`

Added new state variables:

```typescript
const completedLanguages = ref<LanguageCode[]>([]);
const failedLanguages = ref<LanguageCode[]>([]);
```

Updated `startTranslation()` to store results:

```typescript
const result = await translationStore.translateCard(props.cardId, selectedLanguages.value);

// Store successful and failed languages
completedLanguages.value = (result.translated_languages || []) as LanguageCode[];
failedLanguages.value = (result.failed_languages || []) as LanguageCode[];
```

### 4. Enhanced Step 3 UI

**Conditional Icons & Titles:**

```typescript
// Icon color based on results
'bg-green-100': failedLanguages.length === 0,           // All success
'bg-yellow-100': failedLanguages.length > 0 && completedLanguages.length > 0,  // Partial
'bg-red-100': failedLanguages.length > 0 && completedLanguages.length === 0    // All failed

// Title text
- All success: "Translation Complete!"
- Partial: "Partially Complete"
- All failed: "Translation Failed"
```

**Success Section (Green):**

```vue
<div v-if="completedLanguages.length > 0" class="bg-green-50 border border-green-200">
  <h4 class="font-semibold text-green-900">
    <i class="pi pi-check-circle mr-2"></i>
    {{ $t('translation.dialog.successfullyTranslated', { count: completedLanguages.length }) }}
  </h4>
  <Tag v-for="lang in completedLanguages" severity="success" />
</div>
```

**Failure Section (Red with Retry Button):**

```vue
<div v-if="failedLanguages.length > 0" class="bg-red-50 border border-red-200">
  <h4 class="font-semibold text-red-900">
    <i class="pi pi-times-circle mr-2"></i>
    {{ $t('translation.dialog.failedTranslations', { count: failedLanguages.length }) }}
  </h4>
  <Tag v-for="lang in failedLanguages" severity="danger" />
  <Button
    :label="$t('translation.dialog.retryFailed')"
    icon="pi pi-refresh"
    severity="warning"
    @click="retryFailedLanguages"
  />
</div>
```

### 5. Retry Functionality

```typescript
const retryFailedLanguages = () => {
  // Reset to step 1 with failed languages selected
  currentStep.value = 1;
  viewMode.value = 'translate';
  selectedLanguages.value = [...failedLanguages.value];
  // Clear the failed list
  failedLanguages.value = [];
  // Show confirmation
  showConfirmation();
};
```

### 6. i18n Keys Added

**File:** `src/i18n/locales/en.json`

```json
{
  "translation": {
    "dialog": {
      "partialSuccessTitle": "Partially Complete",
      "failureTitle": "Translation Failed",
      "partialSuccessMessage": "{completed} language(s) translated successfully, {failed} language(s) failed.",
      "failureMessage": "Failed to translate {count} language(s). Please try again.",
      "successfullyTranslated": "{count} Successfully Translated",
      "failedTranslations": "{count} Failed",
      "retryFailed": "Retry Failed Languages"
    }
  }
}
```

---

## User Scenarios

### Scenario 1: All Languages Success ✅

**User translates to:** Chinese (Traditional), Chinese (Simplified), Japanese  
**Result:** All 3 succeed

**Step 3 Shows:**
- ✅ Green icon with "Translation Complete!"
- "Successfully translated to 3 languages"
- Green box with all 3 languages
- Credits used: 3

### Scenario 2: Partial Failure ⚠️

**User translates to:** Chinese (Traditional), Chinese (Simplified), Japanese, Korean  
**Result:** 3 succeed, 1 fails (Japanese failed due to invalid JSON)

**Step 3 Shows:**
- ⚠️ Yellow icon with "Partially Complete"
- "3 language(s) translated successfully, 1 language(s) failed"
- Green box with 3 successful languages
- Red box with 1 failed language + "Retry Failed Languages" button
- Credits used: 3 (only charged for successful)

**User clicks "Retry Failed Languages":**
- Dialog returns to Step 1
- Japanese is pre-selected
- User clicks "Translate 1 Language"
- Retries only the failed language

### Scenario 3: All Languages Failed ❌

**User translates to:** Japanese, Korean  
**Result:** Both fail

**Step 3 Shows:**
- ❌ Red icon with "Translation Failed"
- "Failed to translate 2 language(s). Please try again."
- Red box with 2 failed languages + "Retry Failed Languages" button
- No credit summary (no credits consumed)

---

## Benefits

1. **Transparency**: Users know exactly which languages succeeded/failed
2. **Efficiency**: One-click retry instead of manual re-selection
3. **Cost Clarity**: Credits only charged for successful translations
4. **Better UX**: Clear visual feedback with color-coded results
5. **Error Recovery**: Easy path to retry without losing context

---

## Technical Details

### Why Translations Fail:

1. **Gemini API Errors**: Invalid JSON response, timeout, rate limiting
2. **Network Issues**: Connection failures, DNS resolution
3. **Content Issues**: Extremely large content, special characters
4. **API Quotas**: Google Cloud project quota exceeded

### Error Handling:

- Each language processes independently
- Failures don't block other languages
- Failed languages logged in backend
- Frontend receives accurate status for each language

---

## Testing

### Test Cases:

1. ✅ All languages succeed
2. ⚠️ Some languages fail (partial success)
3. ❌ All languages fail
4. ✅ Retry failed languages
5. ✅ Credits only consumed for successful translations

### Backend Logs:

```
🌐 [1/3] Translating to Traditional Chinese...
   ✅ Traditional Chinese completed in 30.1s
🌐 [2/3] Translating to Simplified Chinese...
   ✅ Simplified Chinese completed in 28.4s
🌐 [3/3] Translating to Japanese...
   ❌ Japanese failed: Unexpected token '大', ..."*概要**\n\n\大英博物館にEA61"... is not valid JSON

✅ Translation completed in 35.4s
   Completed: 2, Failed: 1
```

---

## Related Files

- `backend-server/src/routes/translation.routes.direct.ts` - Backend endpoint (already correct)
- `src/stores/translation.ts` - Translation store interface update
- `src/components/Card/TranslationDialog.vue` - UI implementation
- `src/i18n/locales/en.json` - i18n keys

---

## Future Enhancements

1. Show error messages for each failed language
2. Auto-retry failed languages with exponential backoff
3. Email notification for async failures
4. Detailed error logs in translation history

---

## Deployment

### Frontend
```bash
cd /Users/nicholsontsang/coding/Cardy
npm run build  # or npm run dev
```

### Backend
Already deployed - no changes needed

---

## Conclusion

✅ **Feature Complete**: Users can now accurately see which languages succeeded/failed and easily retry failures  
✅ **UX Improved**: Clear visual feedback with color-coded results  
✅ **Cost Transparent**: Credits only charged for successful translations  

**Status:** Production ready 🚀

