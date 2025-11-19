# Card Tab Reset Fix

**Date**: November 9, 2025  
**Type**: UX Bug Fix

## Issue

When switching between cards in the card list (Card Issuer > My Cards), the previously selected tab would persist. For example, if you were viewing the "Content" tab on Card A, then switched to Card B, you would still be on the "Content" tab instead of the "General" tab.

## Expected Behavior

When selecting a new card from the card list, the selected tab should **always reset to the "General" tab** (tab 0), regardless of which tab was previously active.

## Root Cause

The `handleSelectCard()` function in `MyCards.vue` was not resetting the `activeTab` value when switching cards. It only cleared the batch selection and updated the URL.

### Before (Problematic Code)
```javascript
const handleSelectCard = (cardId) => {
    selectedCardId.value = cardId;
    // Clear batch selection when switching cards
    selectedBatchId.value = null;
    updateURL(cardId, activeTab.value, null);  // ❌ Uses current tab value
};
```

## Solution

Updated `handleSelectCard()` to explicitly reset `activeTab` to `0` (General tab) when switching cards.

### After (Fixed Code)
```javascript
const handleSelectCard = (cardId) => {
    selectedCardId.value = cardId;
    // Clear batch selection when switching cards
    selectedBatchId.value = null;
    // Reset to General tab (tab 0) when switching cards
    activeTab.value = 0;  // ✅ Reset to tab 0
    updateURL(cardId, 0, null);  // ✅ Update URL with tab 0
};
```

## Changes Made

### File: `src/views/Dashboard/CardIssuer/MyCards.vue`
- **Line 189**: Added `activeTab.value = 0;` to reset tab when card is selected
- **Line 190**: Updated `updateURL()` call to use `0` instead of `activeTab.value`
- **Added comment**: Explaining the tab reset behavior

## Verification

### Admin View (UserCardsView.vue)
✅ **Already correct** - The admin's User Cards View was already implementing this correctly:
```javascript
const handleSelectCard = async (cardId: string) => {
  selectedCardId.value = cardId
  activeTab.value = 0  // Already resetting to General tab
  // ... rest of implementation
}
```

### Card Issuer View (MyCards.vue)
✅ **Now fixed** - Updated to match the admin implementation

## User Experience Impact

**Before:**
1. User viewing "Content" tab on Card A
2. User clicks Card B in the list
3. User sees "Content" tab for Card B (confusing)
4. User has to manually click "General" tab

**After:**
1. User viewing "Content" tab on Card A
2. User clicks Card B in the list
3. User immediately sees "General" tab for Card B (expected)
4. Clean, predictable experience

## Testing Checklist

- [ ] Switch between cards and verify General tab is always shown
- [ ] Verify URL updates correctly (should show tab=0)
- [ ] Switch to different tabs, then switch cards - should reset to General
- [ ] Test in both Card Issuer view and Admin User Cards view
- [ ] Verify batch selection is also cleared when switching cards

## Related Files

- `src/views/Dashboard/CardIssuer/MyCards.vue` - Fixed
- `src/views/Dashboard/Admin/UserCardsView.vue` - Already correct
- `src/components/Card/CardListPanel.vue` - Emits select-card event
- `src/components/Card/CardDetailPanel.vue` - Receives activeTab prop

## Side Effects

**None** - This is a pure UX improvement with no breaking changes:
- URL routing remains functional
- All tabs still accessible
- Batch selection clearing behavior unchanged
- Admin view behavior unchanged (already correct)

