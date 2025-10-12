# Component Data Refresh Audit

## Issue
User requested a review to identify components that load data once on mount and don't refresh when dependent data changes, similar to the `CardTranslationSection` issue.

## Components Audited

### ✅ GOOD: Components That Handle Refreshes Properly

#### 1. `CardTranslationSection.vue` ✅ **NOW FIXED**
**Status**: Fixed in this session
- **Issue**: Loaded translation status only on mount
- **Fix**: Added `defineExpose` to expose `loadTranslationStatus()` method
- **Parent**: `CardView.vue` calls it after successful card update
- **Dependency**: `original_language` field in card data

#### 2. `TranslationManagement.vue` ✅ **ALREADY GOOD**
**Location**: `src/components/Card/TranslationManagement.vue`
- **Loads on**: Mount via `onMounted(() => loadTranslationStatus())`
- **Refresh mechanism**: ✅ Has watcher for `cardId` prop changes
```typescript
watch(() => props.cardId, () => {
  loadTranslationStatus();
});
```
- **Dependency**: Card ID
- **Verdict**: ✅ **No action needed** - properly watches for changes

#### 3. `CardContent.vue` ✅ **ALREADY GOOD**
**Location**: `src/components/CardContent/CardContent.vue`
- **Loads on**: Mount + cardId watcher
- **Refresh mechanism**: ✅ Has watcher for `cardId` prop changes
```javascript
watch(() => props.cardId, async (newCardId) => {
    if (newCardId) {
        await loadContentItems();
        selectedContentItem.value = null;
    }
}, { immediate: true });
```
- **Also refreshes on**: CRUD operations (create, update, delete content items, drag-drop reorder)
- **Dependency**: Card ID
- **Verdict**: ✅ **No action needed** - properly watches for changes

#### 4. `MobilePreview.vue` ✅ **ALREADY GOOD**
**Location**: `src/components/CardComponents/MobilePreview.vue`
- **Loads on**: Mount + prop watcher
- **Refresh mechanism**: ✅ Has watcher for `cardProp.id` changes
```javascript
watch(
    () => props.cardProp?.id,
    (newCardId) => {
        if (newCardId) {
            loadPreview();
        }
    },
    { immediate: true }
);
```
- **Dependency**: Card ID
- **Verdict**: ✅ **No action needed** - properly watches for changes

### ⚠️ NEEDS REVIEW: Potential Issues

#### 5. `CardAccessQR.vue` ⚠️ **POTENTIAL ISSUE**
**Location**: `src/components/CardComponents/CardAccessQR.vue`
- **Loads on**: Mount via `onMounted(() => loadBatches())`
- **Current refresh mechanisms**:
  1. ✅ Has watcher for `selectedBatchId` prop (for URL-based batch selection)
  2. ✅ Has `:key` attribute in `CardDetailPanel` (remounts on card change)
  3. ❌ **NO watcher for when new batches are created**

**Potential Problem**:
When a user creates a new batch in the "Issue Batch" tab (via `CardIssuanceCheckout`), then the success dialog navigates to the Access tab via:
```javascript
router.push(`/cms/mycards?cardId=${props.cardId}&tab=access&batchId=${batch.id}`)
```

**What happens**:
1. User creates batch in Issue tab → Batch created successfully
2. Success dialog shows "View Cards" button
3. Clicks "View Cards" → Navigates to Access tab with `batchId` in URL
4. **Problem**: `CardAccessQR` is already mounted, so `loadBatches()` doesn't run
5. The new batch is NOT in the `batches` array
6. The `selectedBatchId` watcher tries to select the new batch
7. **FAILS**: `batchExists` check returns false because `loadBatches()` hasn't run
```typescript
watch(() => props.selectedBatchId, (newBatchId) => {
  if (newBatchId && selectedBatch.value !== newBatchId) {
    const batchExists = availableBatches.value.some(b => b.id === newBatchId)
    if (batchExists) {  // ❌ This fails for newly created batches
      selectedBatch.value = newBatchId
      loadIssuedCards(newBatchId)
    }
  }
})
```

**Solution**: Similar to `CardTranslationSection`, expose `loadBatches()` method and have parent call it when switching to Access tab, OR add a watcher for tab changes.

### 📊 Summary Table

| Component | Loads Data | Has Watcher | Refresh Method Exposed | Status |
|-----------|-----------|-------------|----------------------|---------|
| CardTranslationSection | ✅ | ❌ → ✅ | ❌ → ✅ | ✅ Fixed |
| TranslationManagement | ✅ | ✅ cardId | ❌ Not needed | ✅ Good |
| CardContent | ✅ | ✅ cardId | ❌ Not needed | ✅ Good |
| MobilePreview | ✅ | ✅ cardProp.id | ❌ Not needed | ✅ Good |
| **CardAccessQR** | ✅ | ⚠️ Partial | ❌ **Needs** | ⚠️ **Needs Fix** |

## Recommended Fix for CardAccessQR

### Option 1: Expose Refresh Method (Recommended)
Similar to the `CardTranslationSection` fix:

**In `CardAccessQR.vue`:**
```javascript
// Expose methods for parent component to call
defineExpose({
  loadBatches,
  refreshData: async () => {
    await loadBatches();
    // If a batch is already selected, reload its cards too
    if (selectedBatch.value) {
      await loadIssuedCards(selectedBatch.value);
    }
  }
});
```

**In `CardDetailPanel.vue`:**
```javascript
// Add ref for CardAccessQR
const accessQRRef = ref(null);

// Watch for tab changes
watch(() => props.selectedTab, (newTab) => {
  if (newTab === 'access' && accessQRRef.value) {
    // Refresh when switching to access tab
    accessQRRef.value.refreshData();
  }
});

// In template:
<CardAccessQR 
    ref="accessQRRef"
    v-if="index === 3" 
    :cardId="selectedCard.id"
    :cardName="selectedCard.name"
    :selectedBatchId="selectedBatchId"
    @batch-changed="$emit('batch-changed', $event)"
    :key="selectedCard.id + '-access-qr'" 
/>
```

### Option 2: Add Watcher for Tab Changes
Watch for when the Access tab becomes active and reload data:

**In `CardAccessQR.vue`:**
```javascript
// Add prop for tab visibility
const props = defineProps({
  cardId: { type: String, required: true },
  cardName: { type: String, required: true },
  selectedBatchId: { type: String, default: null },
  isTabActive: { type: Boolean, default: false } // NEW
})

// Watch for tab becoming active
watch(() => props.isTabActive, (isActive) => {
  if (isActive) {
    loadBatches();
  }
});
```

### Option 3: Always Reload on selectedBatchId Change
Modify the watcher to reload batches when a new batch ID is provided:

**In `CardAccessQR.vue`:**
```javascript
watch(() => props.selectedBatchId, async (newBatchId) => {
  if (newBatchId && selectedBatch.value !== newBatchId) {
    // Reload batches first to ensure new batch is available
    await loadBatches();
    
    const batchExists = availableBatches.value.some(b => b.id === newBatchId)
    if (batchExists) {
      selectedBatch.value = newBatchId
      await loadIssuedCards(newBatchId)
    }
  }
});
```

## Recommendation
**Implement Option 3** (simplest) combined with **Option 1** (most robust):
1. Fix the watcher to reload batches when needed (Option 3)
2. Expose refresh method for parent control (Option 1)

This provides both automatic refresh and manual control when needed.

## Testing Plan
After implementing the fix:
1. Create a new batch from Issue tab
2. Click "View Cards" in success dialog
3. Verify Access tab loads and shows the new batch
4. Verify the new batch is selected in dropdown
5. Verify QR codes display correctly
6. Create another batch and manually switch to Access tab
7. Verify the new batch appears in the dropdown

## Other Components Checked
- `CardView.vue` - No data loading (just displays)
- `CardCreateEditForm.vue` - Form component (no external data loading)
- `CardContentView.vue` - Display only (receives data via props)
- `CardContentCreateEditForm.vue` - Form component (no external data loading)
- `ImageCropper.vue` - Utility component (no external data)
- `CardCreateEditView.vue` - Wrapper component (no data loading)

## Conclusion
Out of all components reviewed, **only `CardAccessQR.vue` has a potential refresh issue** when new batches are created. All other components either:
1. Don't load external data
2. Have proper watchers for their dependencies
3. Are purely display components receiving data via props

