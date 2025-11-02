# Translation Section Not Updating After Language Change - Fix

## Problem
When a user updates the `original_language` field in the card edit dialog, the multi-language translation section doesn't update to show the new original language. The section still displays the old language until the page is refreshed.

## Root Cause
The `CardTranslationSection` component only loads translation status once on mount (via `onMounted`). When the card's `original_language` is updated, the component doesn't react to this change and doesn't refresh its data.

## Solution
Implemented a parent-child refresh pattern:

1. **Expose refresh method** from `CardTranslationSection.vue` using `defineExpose`
2. **Add ref** to the translation section in `CardView.vue`
3. **Call refresh** after successful card update

## Files Changed

### 1. `/src/components/Card/CardTranslationSection.vue`

**Added `defineExpose` to expose the refresh method:**

```typescript
// Lifecycle
onMounted(() => {
  loadTranslationStatus();
});

// Expose methods for parent component to call
defineExpose({
  loadTranslationStatus
});
```

This allows parent components to call `loadTranslationStatus()` to refresh the translation data.

### 2. `/src/components/CardComponents/CardView.vue`

**Changes:**

1. Added `ref` to the translation section:
```vue
<!-- Multi-Language Translation Section - Full Width -->
<CardTranslationSection ref="translationSectionRef" :card-id="cardProp.id" />
```

2. Declared the ref:
```javascript
const showEditDialog = ref(false);
const editFormRef = ref(null);
const translationSectionRef = ref(null);  // NEW
const isLoading = ref(false);
```

3. Called refresh method after successful update:
```javascript
const handleSaveEdit = async () => {
    if (editFormRef.value) {
        const payload = editFormRef.value.getPayload();
        
        if (props.updateCardFn) {
            await props.updateCardFn(payload);
        } else {
            await emit('update-card', payload);
        }
        
        // Refresh translation section to show updated original_language
        if (translationSectionRef.value) {
            translationSectionRef.value.loadTranslationStatus();
        }
        
        // Don't manually close dialog - MyDialog will close it automatically after success
    }
};
```

## Testing Checklist

- [x] No linter errors
- [ ] Open card view
- [ ] Click "Edit Card"
- [ ] Change "Original Language" dropdown
- [ ] Click "Save Changes"
- [ ] Verify multi-language section shows the new original language immediately
- [ ] Verify translation status badges update correctly

## Benefits
- **Immediate feedback**: Users see the updated original language without refreshing
- **Better UX**: Translation section stays in sync with card data
- **Reusable pattern**: The `defineExpose` pattern can be used for other child components that need parent-triggered refreshes

## Related Issues
This is part of the complete fix for the `original_language` field not being saved/displayed, which includes:
1. ✅ TypeScript interface fix (`CardFormData` in `card.ts`)
2. ✅ RPC parameter fix (create/update in `card.ts`)
3. ⚠️ Database stored procedure fix (`get_card_by_id` - needs deployment)
4. ✅ Translation section refresh (this fix)

## Dependencies
This fix assumes that:
- The database is storing `original_language` correctly (via the RPC fix)
- The stored procedure `get_card_translation_status` returns the updated `original_language`

