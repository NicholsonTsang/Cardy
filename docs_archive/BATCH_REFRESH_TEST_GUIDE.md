# Batch Refresh Fix - Test Guide

## What Was Fixed
The QR & Access tab now automatically refreshes when you create a new batch, showing the newly created batch immediately.

## How to Test

### Test Scenario 1: Create batch and manually switch tabs
1. Open a card in MyCards
2. Go to **Issuance** tab
3. Click "Issue Batch" and create a batch (e.g., 10 cards)
4. Wait for success dialog to appear
5. **Close the success dialog** (click X or Close button)
6. Manually click on **QR & Access** tab
7. ✅ **Expected**: New batch should appear in the dropdown list
8. ✅ **Expected**: If it's the first batch, it should be auto-selected

### Test Scenario 2: Create batch and use "View Cards" button
1. Open a card in MyCards
2. Go to **Issuance** tab
3. Create a new batch
4. In the success dialog, click **"View Digital Cards"** button
5. ✅ **Expected**: Navigates to Access tab
6. ✅ **Expected**: New batch is visible and selected
7. ✅ **Expected**: QR codes load correctly

### Test Scenario 3: Multiple batches
1. Create first batch
2. Switch to Access tab - verify it appears
3. Switch back to Issuance tab
4. Create second batch
5. Switch to Access tab again
6. ✅ **Expected**: Both batches visible in dropdown
7. ✅ **Expected**: Can switch between batches

### Test Scenario 4: Console verification
1. Open browser DevTools (F12)
2. Go to Console tab
3. Create a new batch
4. Switch to Access tab
5. ✅ **Expected**: Should see network request to `get_card_batches`
6. ✅ **Expected**: No errors in console

## Technical Details

### How It Works
When you create a batch:
1. `CardIssuanceCheckout` emits a `'batch-created'` event
2. `CardDetailPanel` catches it and increments a reactive counter
3. The Access tab's component key changes
4. When you switch to the Access tab, Vue creates a **fresh component instance**
5. The fresh instance loads the latest data from the database
6. New batch appears! 🎉

### Why This Approach?
The Access tab uses `v-if`, which means it's completely destroyed when you're on other tabs. You can't call methods on a destroyed component, so we use Vue's reactivity system instead:
- Changing the `:key` prop tells Vue "this is a different component now"
- Vue destroys the old instance and creates a new one
- The new instance loads fresh data automatically

## Files Modified
- ✅ `src/components/CardIssuanceCheckout.vue` - Emits event after batch creation
- ✅ `src/components/Card/CardDetailPanel.vue` - Handles event with reactive key

## Rollback Instructions
If you need to undo this change:

```bash
git checkout src/components/CardIssuanceCheckout.vue
git checkout src/components/Card/CardDetailPanel.vue
```

## Notes
- This fix works for **all batch creation scenarios**
- No manual refresh needed
- No page reload required
- Clean, minimal implementation using Vue 3 reactivity

