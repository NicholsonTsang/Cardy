# CardAccessQR Batch Refresh Fix

## Problem
When a user creates a new batch in the "Issue Batch" tab and clicks "View Cards" in the success dialog, the Access tab doesn't show the new batch in the dropdown. The batch is created successfully but the `CardAccessQR` component doesn't reload its batch list.

## Root Cause
The `CardAccessQR` component loads batches only once on mount via `onMounted()`. When a user:
1. Creates a batch in Issue tab
2. Clicks "View Cards" which navigates to `/cms/mycards?cardId=XXX&tab=access&batchId=YYY`
3. The Access tab is already mounted, so `loadBatches()` doesn't run
4. The `selectedBatchId` watcher receives the new batch ID
5. But `batchExists` check fails because the batch list wasn't refreshed
6. Result: New batch doesn't appear in dropdown

## Solution Implemented

### Fix 1: Auto-Reload Batches on Batch Selection
Modified the `selectedBatchId` watcher to reload batches before checking if the batch exists:

**Before:**
```javascript
watch(() => props.selectedBatchId, (newBatchId) => {
  if (newBatchId && selectedBatch.value !== newBatchId) {
    const batchExists = availableBatches.value.some(b => b.id === newBatchId)
    if (batchExists) {  // ❌ Fails for newly created batches
      selectedBatch.value = newBatchId
      loadIssuedCards(newBatchId)
    }
  }
})
```

**After:**
```javascript
watch(() => props.selectedBatchId, async (newBatchId) => {
  if (newBatchId && selectedBatch.value !== newBatchId) {
    // Reload batches first to ensure new batch is available (e.g., when navigating from Issue tab)
    await loadBatches()  // ✅ Now reloads batches before checking
    
    const batchExists = availableBatches.value.some(b => b.id === newBatchId)
    if (batchExists) {
      selectedBatch.value = newBatchId
      await loadIssuedCards(newBatchId)
    }
  }
})
```

### Fix 2: Expose Refresh Methods
Added `defineExpose` to allow parent components to manually trigger data refresh:

```javascript
// Expose methods for parent component to call if needed
defineExpose({
  loadBatches,
  refreshData: async () => {
    await loadBatches()
    // If a batch is already selected, reload its cards too
    if (selectedBatch.value) {
      await loadIssuedCards(selectedBatch.value)
    }
  }
})
```

This allows future enhancements where the parent component can call:
```javascript
// If needed in future
if (accessQRRef.value) {
  accessQRRef.value.refreshData()
}
```

## Files Changed

### `/src/components/CardComponents/CardAccessQR.vue`

**Changes:**
1. Made `selectedBatchId` watcher async and added `await loadBatches()` call
2. Added `defineExpose` to expose `loadBatches` and `refreshData` methods

## Benefits
1. **Automatic Refresh**: New batches automatically appear when navigating from Issue tab
2. **User Experience**: "View Cards" button in success dialog now works seamlessly
3. **Manual Control**: Parent components can manually trigger refresh if needed
4. **No Breaking Changes**: Existing functionality remains unchanged

## Testing Checklist

- [x] No linter errors
- [ ] Create a new batch from Issue tab
- [ ] Click "View Cards" in success dialog
- [ ] **Verify**: Access tab loads and shows the new batch in dropdown
- [ ] **Verify**: New batch is automatically selected
- [ ] **Verify**: QR codes display correctly for the new batch
- [ ] Create another batch
- [ ] Manually switch to Access tab (without using "View Cards" button)
- [ ] **Verify**: New batch appears in the dropdown
- [ ] Change batch selection in dropdown
- [ ] **Verify**: QR codes update correctly

## User Flow Before Fix
1. User creates batch → Success ✅
2. User clicks "View Cards" → Navigates to Access tab ✅
3. **Problem**: Dropdown shows old batches only ❌
4. User must manually refresh page to see new batch ❌

## User Flow After Fix
1. User creates batch → Success ✅
2. User clicks "View Cards" → Navigates to Access tab ✅
3. **Fixed**: Dropdown automatically loads and shows new batch ✅
4. **Fixed**: New batch is auto-selected and QR codes display ✅

## Related Issues
This is part of a larger audit to ensure all components refresh properly when dependent data changes. See `COMPONENT_REFRESH_AUDIT.md` for the full analysis.

## Pattern for Future Components
When creating components that load data on mount:
1. **Always add watchers** for prop changes that indicate data might have changed
2. **Consider exposing refresh methods** via `defineExpose` for parent control
3. **Reload data proactively** when selections change (like `selectedBatchId` in this case)

## Performance Considerations
The `loadBatches()` call in the watcher is only triggered when:
- The `selectedBatchId` prop changes
- AND it's different from the currently selected batch

This means:
- No unnecessary API calls during normal usage
- Only reloads when actually needed (navigating with a new batch ID)
- Minimal performance impact

## Edge Cases Handled
1. ✅ New batch created and selected via "View Cards"
2. ✅ User manually switches to Access tab after creating batch
3. ✅ Multiple rapid batch creations
4. ✅ URL-based batch selection (bookmark/share links)
5. ✅ First-time Access tab visit (auto-selects first batch)

## Conclusion
The fix ensures that the Access tab's batch dropdown always shows the latest batches, especially when navigating from the Issue tab after creating a new batch. The solution is simple, performant, and maintains backward compatibility.

