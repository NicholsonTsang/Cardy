# Batch URL Filtering Feature

## Overview
Added batch filtering support to the QR & Access tab via URL parameters. Users can now share direct links to specific batch views, and the selected batch persists in the URL for easy bookmarking and navigation.

## Feature Description

### What Changed
The QR & Access tab now supports a `batchId` URL parameter that:
- Automatically selects a specific batch when present in the URL
- Updates the URL when users change batches in the dropdown
- Shows all cards for the selected batch
- If no `batchId` is specified, shows the first available batch (default behavior)

### URL Format
```
http://localhost:5173/cms/mycards?cardId={card-id}&tab=access&batchId={batch-id}
```

**Parameters:**
- `cardId` (required): The card ID to view
- `tab` (required): Must be `access` to show the QR & Access tab
- `batchId` (optional): The specific batch to display
  - If provided: Shows only cards from that batch
  - If omitted: Shows first available batch (auto-selected)

### Example URLs

#### With Batch Selected
```
http://localhost:5173/cms/mycards?cardId=f0f2318c-90b0-4eee-9f68-0daa6e2f30a5&tab=access&batchId=abc123
```
Shows the QR codes and access URLs for batch `abc123` only.

#### Without Batch (Default)
```
http://localhost:5173/cms/mycards?cardId=f0f2318c-90b0-4eee-9f68-0daa6e2f30a5&tab=access
```
Shows the first available batch (auto-selected).

## Implementation Details

### 1. MyCards.vue (Parent Component)

**State Management:**
```javascript
const selectedBatchId = ref(null)
```

**URL Management:**
- Reads `batchId` from query params on mount
- Updates URL when batch changes
- Clears `batchId` when switching cards
- Only includes `batchId` when on access tab (index 3)

**Event Handling:**
```javascript
const handleBatchChange = (batchId) => {
  selectedBatchId.value = batchId
  updateURL(null, activeTab.value, batchId)
}
```

**URL Update Logic:**
```javascript
const updateURL = (cardId = null, tab = 0, batchId = null) => {
  // ... existing code ...
  
  // Only include batchId if we're on the access tab
  if (currentBatchId && tab === 3) {
    query.batchId = currentBatchId
  }
  
  // Update URL
  router.replace({ name: route.name, query: query })
}
```

### 2. CardDetailPanel.vue (Middle Layer)

**Props:**
```javascript
selectedBatchId: {
  type: String,
  default: null
}
```

**Event Pass-Through:**
```vue
<CardAccessQR 
  :selectedBatchId="selectedBatchId"
  @batch-changed="$emit('batch-changed', $event)"
/>
```

**Emits:**
```javascript
const emit = defineEmits(['batch-changed', ...])
```

### 3. CardAccessQR.vue (Access Tab Component)

**Props:**
```javascript
selectedBatchId: {
  type: String,
  default: null
}
```

**Watcher:**
```javascript
watch(() => props.selectedBatchId, (newBatchId) => {
  if (newBatchId && selectedBatch.value !== newBatchId) {
    const batchExists = availableBatches.value.some(b => b.id === newBatchId)
    if (batchExists) {
      selectedBatch.value = newBatchId
      loadIssuedCards(newBatchId)
    }
  }
})
```

**Initialization Priority:**
1. **URL Parameter** (Highest): If `selectedBatchId` prop is provided and valid
2. **Auto-Select**: First available batch if no URL parameter
3. **Update URL**: Emit event to update URL with selected batch

**Emit on Change:**
```javascript
const onBatchChange = async () => {
  if (selectedBatch.value) {
    await loadIssuedCards(selectedBatch.value)
    emit('batch-changed', selectedBatch.value) // Updates URL
  }
}
```

## Data Flow

### User Changes Batch in Dropdown
```
CardAccessQR (dropdown change)
    ↓ emit('batch-changed', batchId)
CardDetailPanel (pass-through)
    ↓ @batch-changed="$emit('batch-changed', $event)"
MyCards.vue (handle event)
    ↓ handleBatchChange(batchId)
    ↓ selectedBatchId.value = batchId
    ↓ updateURL(null, activeTab, batchId)
Router (URL updated)
    ↓ query.batchId = abc123
URL: /cms/mycards?cardId=...&tab=access&batchId=abc123
```

### User Opens URL with batchId
```
URL: /cms/mycards?cardId=...&tab=access&batchId=abc123
    ↓ route.query.batchId
MyCards.vue (initializeFromURL)
    ↓ selectedBatchId.value = route.query.batchId
    ↓ Pass to CardDetailPanel via prop
CardDetailPanel
    ↓ Pass to CardAccessQR via prop
CardAccessQR (onMounted)
    ↓ await loadBatches()
    ↓ if (props.selectedBatchId && batchExists)
    ↓ selectedBatch.value = props.selectedBatchId
    ↓ await loadIssuedCards(props.selectedBatchId)
Display: QR codes for specified batch
```

### User Switches Cards
```
MyCards.vue (handleSelectCard)
    ↓ selectedBatchId.value = null  // Clear batch selection
    ↓ updateURL(cardId, activeTab, null)
Router (URL updated)
    ↓ query.batchId removed
URL: /cms/mycards?cardId=new-card&tab=access
    ↓
CardAccessQR (onMounted for new card)
    ↓ No selectedBatchId prop
    ↓ Auto-select first batch
    ↓ Emit batch-changed to update URL
```

## User Experience

### Scenario 1: Normal Navigation
1. User opens card
2. Clicks "QR & Access" tab
3. First batch auto-selected
4. **URL updates**: `?cardId=xxx&tab=access&batchId=first-batch`
5. User changes batch in dropdown
6. **URL updates**: `?cardId=xxx&tab=access&batchId=new-batch`

### Scenario 2: Direct Link
1. User receives link: `?cardId=xxx&tab=access&batchId=specific-batch`
2. Opens link in browser
3. Page loads with specified card and tab
4. **Specific batch automatically selected**
5. Shows QR codes for that batch only

### Scenario 3: Card Switching
1. User on access tab with batch selected
2. Switches to different card
3. **Batch selection cleared**
4. First batch of new card auto-selected
5. URL updated with new batch

### Scenario 4: Tab Switching
1. User on access tab: `?tab=access&batchId=xxx`
2. Switches to content tab
3. **batchId removed from URL**: `?tab=content`
4. Returns to access tab
5. First batch auto-selected again

## Benefits

### For Users
1. ✅ **Shareable Links**: Send specific batch views to colleagues
2. ✅ **Bookmarkable**: Save frequently accessed batches
3. ✅ **Direct Access**: Skip navigation steps with URL
4. ✅ **Context Preserved**: Browser back/forward maintains batch selection

### For Workflows
1. ✅ **Print Team**: Direct links to batches needing printing
2. ✅ **QA Testing**: Quickly access specific batch QR codes
3. ✅ **Customer Support**: Share exact batch views with users
4. ✅ **Reporting**: Link to batches in documentation/reports

## Edge Cases Handled

### Invalid batchId
- If `batchId` in URL doesn't exist or isn't available
- Falls back to first available batch
- No error shown (graceful degradation)

### No Batches Available
- Shows "No batches found" message
- batchId parameter ignored
- Prompt to create batch in issuance tab

### Batch Not Paid/Generated
- Only paid/completed batches shown in dropdown
- Invalid batches filtered out
- URL parameter has no effect if batch unavailable

### Card Switch
- Batch selection cleared (batches are card-specific)
- Prevents showing wrong batch for new card
- Clean slate for each card

### Tab Switch
- batchId only persists on access tab
- Removed when switching to other tabs
- Re-initialized when returning to access tab

## Files Modified

1. **`src/views/Dashboard/CardIssuer/MyCards.vue`**
   - Added `selectedBatchId` state
   - Added `handleBatchChange()` method
   - Updated `updateURL()` to include batchId
   - Updated `initializeFromURL()` to read batchId
   - Added watcher for batchId in route.query
   - Clear batchId when switching cards

2. **`src/components/Card/CardDetailPanel.vue`**
   - Added `selectedBatchId` prop
   - Added `'batch-changed'` to emits
   - Pass prop to CardAccessQR
   - Pass through batch-changed event

3. **`src/components/CardComponents/CardAccessQR.vue`**
   - Added `selectedBatchId` prop
   - Added `'batch-changed'` emit
   - Added watcher for prop changes
   - Emit event on batch change
   - Prioritize URL batch on mount
   - Import `watch` from vue

## Testing Checklist

- [x] URL includes batchId when batch selected
- [x] Specific batch loads when opening URL with batchId
- [x] Changing batch in dropdown updates URL
- [x] Invalid batchId falls back gracefully
- [x] First batch auto-selected when no batchId
- [x] batchId cleared when switching cards
- [x] batchId removed when switching away from access tab
- [x] Browser back/forward maintains batch selection
- [x] Direct link with batchId works correctly
- [x] No linter errors

## Future Enhancements (Optional)

1. **Batch Filters in URL**: Add more filters (active/inactive cards)
2. **Batch Name in URL**: Use human-readable batch names
3. **Multiple Batches**: Support comparing multiple batches
4. **Analytics**: Track which batches are accessed most
5. **Batch History**: Remember last viewed batch per card

## Summary

This feature adds URL-based batch filtering to the QR & Access tab, enabling:
- 🔗 **Shareable batch links**
- 📌 **Bookmarkable views**
- ⚡ **Direct access to specific batches**
- 🔄 **Persistent batch selection**

**Status**: ✅ **Production Ready**

