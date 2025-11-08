# Translation Progress Bar Updates After Batch Completion

**Date:** November 5, 2025  
**Status:** ✅ Fixed

## Problem

The translation progress bar needed to update **after** each batch completes, not during processing. Users wanted to see:
- Progress bar at 0% when translation starts
- Progress bar moves to 10% (1/10) after first batch **completes**
- Progress bar moves to 20% (2/10) after second batch **completes**
- And so on...

## Root Cause

While the backend was already emitting `batch:progress` events **after** batch completion, there were two issues:

1. **Missing totalBatches information**: When `language:started` was emitted, it didn't include the total number of batches. The frontend only learned this when the first `batch:progress` event arrived, which could cause the progress bar to display incorrectly initially.

2. **Confusing progress message**: The message said "Processing batch X" when it should have said "Completed batch X" since the event is emitted after completion.

## Solution

### Backend Changes (`backend-server/src/routes/translation.routes.ts`)

Added `totalBatches` to the `language:started` event so the frontend knows the denominator from the start:

```typescript
// Emit language started event with totalBatches information
emitTranslationProgress(userId, cardId, {
  type: 'language:started',
  cardId,
  language: targetLang,
  languageIndex: langIndex + 1,
  totalLanguages: languagesToTranslate.length,
  totalBatches: numBatches,  // ← Added this field
  timestamp: new Date().toISOString(),
});
```

### Frontend Changes (`src/composables/useTranslationProgress.ts`)

1. **Updated type definition** to include `totalBatches`:
```typescript
export interface LanguageStartedEvent {
  type: 'language:started';
  cardId: string;
  language: string;
  languageIndex: number;
  totalLanguages: number;
  totalBatches: number;  // ← Added this field
  timestamp: string;
}
```

2. **Updated event handler** to use the totalBatches from the start:
```typescript
case 'language:started':
  currentLanguage.value = event.language;
  currentLanguageIndex.value = event.languageIndex;
  totalLanguages.value = event.totalLanguages;
  currentBatch.value = 0;
  totalBatches.value = event.totalBatches;  // ← Now known from start
  
  // Update language progress with known totalBatches
  if (languageProgress.value[event.language]) {
    languageProgress.value[event.language].status = 'in_progress';
    languageProgress.value[event.language].currentBatch = 0;
    languageProgress.value[event.language].totalBatches = event.totalBatches;
    languageProgress.value[event.language].batchProgress = 0;  // Starts at 0%
  }
  break;
```

3. **Clarified progress message**:
```typescript
case 'batch:progress':
  progressMessage.value = `Completed batch ${event.batchIndex}/${event.totalBatches} for ${LANGUAGE_NAMES[event.language]}`;
  // Changed from "Processing batch" to "Completed batch"
```

## Timeline

### When language starts:
1. ✅ Frontend receives `language:started` event
2. ✅ Progress bar shows **0%** (0/10 batches)
3. ✅ Frontend knows totalBatches = 10 from the start
4. ✅ Message shows: "Translating to Japanese (1/3)..."

### When first batch completes:
5. ✅ Backend emits `batch:progress` with batchIndex=1
6. ✅ Progress bar moves to **10%** (1/10 batches)
7. ✅ Message shows: "Completed batch 1/10 for Japanese (10 items)"

### When second batch completes:
8. ✅ Backend emits `batch:progress` with batchIndex=2
9. ✅ Progress bar moves to **20%** (2/10 batches)
10. ✅ Message shows: "Completed batch 2/10 for Japanese (10 items)"

And so on until all batches complete.

## Benefits

1. **Accurate progress from the start**: Progress bar knows the total number of batches immediately when translation starts
2. **Clear visual feedback**: Progress bar only moves after work completes, not during processing
3. **Better UX**: Users can see exactly which batch just finished (e.g., "Completed batch 3/10")
4. **Consistent behavior**: Same pattern across all languages and all batches

## Files Modified

- `backend-server/src/routes/translation.routes.ts` - Added totalBatches to language:started event
- `backend-server/src/services/socket.service.ts` - Type already had totalBatches field (good!)
- `src/composables/useTranslationProgress.ts` - Updated to handle totalBatches from start
- `backend-server/SOCKET_IO_TRANSLATION_PROGRESS.md` - Updated documentation

## Testing

To verify the fix works:

1. Start a translation with multiple languages
2. Observe that progress bar starts at **0%** when each language begins
3. Observe that progress bar moves to **10%** after first batch **completes**
4. Observe that progress bar moves to **20%** after second batch **completes**
5. Verify the message says "**Completed** batch X/Y" not "Processing batch X/Y"
6. Confirm progress bar reaches **100%** when all batches complete

## Notes

- The backend was already emitting `batch:progress` events **after** batch completion (this was correct)
- The main improvement was adding `totalBatches` to the `language:started` event
- Progress calculation remains the same: `(completedBatches / totalBatches) * 100`
- Each language has 10 items per batch (configurable via `BATCH_SIZE` constant)

