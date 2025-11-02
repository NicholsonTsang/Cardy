# Batch Issuance Auto-Refresh Fix

## Issue
After creating a new batch in the Issuance tab, the QR & Access tab didn't automatically refresh to show the newly created batch. Users had to manually refresh or navigate away and back to see the new batch.

## Root Cause
The `CardIssuanceCheckout` component (Issuance tab) and `CardAccessQR` component (Access tab) are sibling components that don't communicate directly. When a batch was created:

1. `CardIssuanceCheckout` would reload its own data (`loadData()` at line 1250)
2. But `CardAccessQR` had no way to know a new batch was created
3. `CardAccessQR` only refreshed when:
   - Component mounted (initial load)
   - `selectedBatchId` prop changed (URL parameter change)

Since neither of these conditions were met when creating a batch while staying on the Issuance tab, the Access tab remained stale.

## Solution
Implemented a reactive key-based refresh pattern to force component remount with fresh data:

### 1. CardIssuanceCheckout.vue
- Added `emit('batch-created', batchId)` after successful batch creation
- Emits the new batch ID to the parent component

```vue
// Emits
const emit = defineEmits(['batch-created'])

// After successful batch creation
emit('batch-created', batchId)
```

### 2. CardDetailPanel.vue  
- Added `accessQRRefreshKey` reactive counter
- Created `handleBatchCreated()` method to increment the key
- Connected the `@batch-created` event from CardIssuanceCheckout
- **Important**: Uses reactive `:key` prop to force component remount

```vue
<!-- Issuance Tab -->
<CardIssuanceCheckout 
    @batch-created="handleBatchCreated"
/>

<!-- Access Tab with dynamic key -->
<CardAccessQR 
    :key="`${selectedCard.id}-access-qr-${accessQRRefreshKey}`"
/>

// Reactive counter
const accessQRRefreshKey = ref(0);

// Handler increments key to force remount
const handleBatchCreated = async (batchId) => {
    accessQRRefreshKey.value++;
};
```

### 3. CardAccessQR.vue
- No changes needed
- Component uses `onMounted()` to load fresh data when created
- Reactive key change forces remount → fresh data load

## Why Key-Based Refresh?

The `CardAccessQR` component uses `v-if="index === 3"` in the parent, which means:
- Component is **completely destroyed** when on other tabs
- Component is **newly created** when switching to Access tab
- Cannot call methods on a destroyed component (ref would be null)

By changing the `:key` prop when a batch is created:
- Vue recognizes it as a "different" component
- When user switches to Access tab, Vue creates a fresh instance
- Fresh instance runs `onMounted()` and loads latest data including new batch

## User Experience Impact

**Before:**
1. User creates batch in Issuance tab ✅
2. Success message shows ✅
3. User clicks "View Cards" button
4. Navigates to Access tab
5. ❌ New batch not visible in dropdown
6. User has to manually reload page

**After:**
1. User creates batch in Issuance tab ✅
2. Success message shows ✅
3. **Access tab automatically refreshes** ✅
4. User clicks "View Cards" button
5. Navigates to Access tab
6. ✅ New batch immediately visible and auto-selected

## Files Modified
- `src/components/CardIssuanceCheckout.vue` - Added event emission
- `src/components/Card/CardDetailPanel.vue` - Added event handler and ref

## Testing Checklist
- [x] Create a new batch from Issuance tab
- [x] Verify success dialog shows
- [x] Navigate to Access tab
- [x] Verify new batch appears in dropdown
- [x] Verify batch is auto-selected (via URL parameter)
- [x] Verify QR codes load correctly
- [x] No console errors
- [x] No linter errors

## Related Components
- `CardIssuanceCheckout.vue` - Batch creation UI
- `CardAccessQR.vue` - QR code display and batch selection
- `CardDetailPanel.vue` - Parent component coordinating tabs
- `MyCards.vue` - Top-level page managing card selection and URL state

## Alternative Approaches Considered

### ❌ Calling refreshData() via ref
```vue
// This doesn't work!
const cardAccessQRRef = ref(null);
cardAccessQRRef.value.refreshData(); // ref is null when component destroyed by v-if
```
**Problem**: With `v-if`, component is destroyed when not visible, so ref is null.

### ❌ Using v-show instead of v-if
```vue
<!-- This would work but has performance issues -->
<CardAccessQR v-show="index === 3" />
```
**Problem**: All tab components would remain mounted, wasting memory and resources.

### ✅ Reactive key (chosen solution)
```vue
<CardAccessQR :key="`${cardId}-${refreshKey}`" />
```
**Benefits**: 
- Works with v-if (component destroyed when not visible)
- Minimal performance impact (only remounts when needed)
- No need to track component lifecycle or call methods
- Vue handles everything automatically

## Additional Notes
This fix uses Vue's reactivity system to trigger component remount at the right time. The key-based approach is a common Vue pattern for forcing fresh data loads, especially with `v-if` components. The implementation is clean, minimal, and follows Vue 3 best practices.

