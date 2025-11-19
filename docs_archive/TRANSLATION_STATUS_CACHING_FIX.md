# Translation Status Caching Fix

**Date:** November 3, 2025  
**Status:** ✅ Fixed

## Problem

All cards were displaying the same translation status (original language, translated count, outdated count) regardless of which card was being viewed. For example:
- Original Language: English
- Translated: 3/9 languages
- Outdated: 1 needs update

This same status was shown for **all cards**, even though each card should have different translation statistics.

## Root Cause

The translation status is stored in a **Pinia store** (`translation.ts`) which caches the data globally. The translation components (`CardTranslationSection.vue` and `TranslationManagement.vue`) were:

1. ✅ Fetching translation status on initial mount
2. ❌ **NOT resetting cached data** when switching between cards
3. ❌ CardTranslationSection.vue had **no watcher** for `cardId` changes

**Result:** When viewing Card A, its translation status was cached. When switching to Card B, the cached status from Card A was still displayed.

## Solution

Added proper watchers with state reset logic to both translation components:

### CardTranslationSection.vue

**Before (❌ No watcher):**
```typescript
// Lifecycle
onMounted(() => {
  loadTranslationStatus();
});
```

**After (✅ With watcher and reset):**
```typescript
// Lifecycle
onMounted(() => {
  loadTranslationStatus();
});

// Watch for card ID changes and reload translation status
watch(() => props.cardId, (newCardId, oldCardId) => {
  if (newCardId && newCardId !== oldCardId) {
    // Reset store state to clear previous card's data
    translationStore.reset();
    // Load new card's translation status
    loadTranslationStatus();
  }
}, { immediate: false });
```

### TranslationManagement.vue

**Before (❌ Watcher without reset):**
```typescript
watch(() => props.cardId, () => {
  loadTranslationStatus();
});
```

**After (✅ With proper reset):**
```typescript
watch(() => props.cardId, (newCardId, oldCardId) => {
  if (newCardId && newCardId !== oldCardId) {
    // Reset store state to clear previous card's data
    translationStore.reset();
    // Load new card's translation status
    loadTranslationStatus();
  }
}, { immediate: false });
```

## Store Reset Method

The translation store already has a `reset()` method that clears all cached data:

```typescript
reset() {
  this.translationStatus = {};
  this.translationHistory = [];
  this.isTranslating = false;
  this.translationProgress = 0;
  this.translationError = null;
  this.currentCardId = null;
}
```

## Benefits

1. ✅ **Card-specific status**: Each card now shows its own translation statistics
2. ✅ **No stale data**: Cached data is properly cleared when switching cards
3. ✅ **Responsive UI**: Translation status updates immediately when navigating
4. ✅ **Consistent behavior**: Both translation components handle card changes the same way

## Files Modified

- `src/components/Card/CardTranslationSection.vue` (lines 153, 264-272)
- `src/components/Card/TranslationManagement.vue` (lines 334-342)

## Testing Verification

After this fix:
1. View Card A with 2 translated languages
2. Switch to Card B with 5 translated languages
3. Card B should correctly show "5/9 languages" (not Card A's "2/9")
4. Switch back to Card A
5. Card A should correctly show "2/9 languages" again

## Related Components

The translation store (`src/stores/translation.ts`) is used by:
- ✅ `CardTranslationSection.vue` - Fixed
- ✅ `TranslationManagement.vue` - Fixed
- `TranslationDialog.vue` - Dialog component (doesn't need watcher, only used temporarily)

## Prevention

For future components that use the translation store:
1. Always watch for `cardId` prop changes
2. Always call `translationStore.reset()` before fetching new card data
3. Use `immediate: false` to avoid double-loading on mount
4. Check `newCardId !== oldCardId` to avoid unnecessary refetches


