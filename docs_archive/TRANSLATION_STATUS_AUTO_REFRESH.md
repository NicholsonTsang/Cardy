# Translation Status Auto-Refresh - November 8, 2025

**Date:** November 8, 2025  
**Status:** ✅ IMPLEMENTED  
**Impact:** Major UX Improvement - Translation status automatically updates when content changes

---

## Feature Overview

Automatically refetch translation status whenever card content or content items are updated, ensuring users always see accurate translation status (up_to_date vs outdated).

### Before ❌
- Translation status only updated manually or after page refresh
- Users saw stale status even after editing content
- Translations showed "up_to_date" even when content had changed

### After ✅
- Translation status automatically refreshes after any content change
- Immediate feedback showing "outdated" when content is modified
- Users know exactly when translations need updating

---

## When Status Refreshes

Translation status automatically refetches after:

1. **Content Item Created** (`CardContent.vue` → `handleAddContentItem`)
2. **Content Item Updated** (`CardContent.vue` → `handleEditContentItem`)
3. **Sub-Item Added** (`CardContent.vue` → `handleAddSubItem`)
4. **Content Item Deleted** (`CardContent.vue` → `deleteContentItem`)
5. **Card Name/Description Updated** (`CardView.vue` → `handleSaveEdit`)

All these operations change the `content_hash`, which makes existing translations "outdated".

---

## Implementation

### 1. Import Translation Store

**File:** `src/components/CardContent/CardContent.vue`

```typescript
import { useTranslationStore } from '@/stores/translation';

const translationStore = useTranslationStore();
```

**File:** `src/components/CardComponents/CardView.vue`

```typescript
import { SUPPORTED_LANGUAGES, useTranslationStore } from '@/stores/translation';

const translationStore = useTranslationStore();
```

### 2. Add Refetch After Operations

**Content Item Creation:**

```typescript
if (result) {
    await loadContentItems();
    
    // Refetch translation status (content hash changed)
    await translationStore.fetchTranslationStatus(props.cardId);
    
    cardContentCreateFormRef.value.resetForm();
    return Promise.resolve();
}
```

**Content Item Update:**

```typescript
if (result) {
    await loadContentItems();
    
    // Refetch translation status (content hash changed)
    await translationStore.fetchTranslationStatus(props.cardId);
    
    editingContentItem.value = null;
    return Promise.resolve();
}
```

**Content Item Deletion:**

```typescript
const deleteContentItem = async (itemId) => {
    try {
        await contentItemStore.deleteContentItem(itemId, props.cardId);
        
        if (selectedContentItem.value === itemId) {
            selectedContentItem.value = null;
        }
        
        await loadContentItems();
        
        // Refetch translation status (content hash changed)
        await translationStore.fetchTranslationStatus(props.cardId);
        
    } catch (error) {
        console.error('Error deleting content item:', error);
        toast.add({ severity: 'error', summary: t('messages.operation_failed'), detail: t('content.failed_to_delete_item'), life: 3000 });
    }
};
```

**Card Update:**

```typescript
const handleSaveEdit = async () => {
    if (editFormRef.value) {
        const payload = editFormRef.value.getPayload();
        
        if (props.updateCardFn) {
            await props.updateCardFn(payload);
        } else {
            await emit('update-card', payload);
        }
        
        // Refresh translation section
        if (translationSectionRef.value) {
            translationSectionRef.value.loadTranslationStatus();
        }
        
        // Refetch translation status (card content changed)
        await translationStore.fetchTranslationStatus(props.cardProp.id);
    }
};
```

---

## How It Works

### Backend: `content_hash` Calculation

When content changes, the database automatically recalculates `content_hash`:

```sql
-- Card hash includes: name, description
UPDATE cards SET content_hash = md5(name || description)

-- Content item hash includes: name, content
UPDATE content_items SET content_hash = md5(name || content)
```

### Translation Status Check

The `fetchTranslationStatus` function compares stored hashes with current hashes:

```typescript
// For each language
if (translation.content_hash !== current_hash) {
    status = 'outdated';  // ⚠️ Needs update
} else {
    status = 'up_to_date';  // ✅ Current
}
```

---

## User Flow Example

### Scenario: User Edits Content Item

1. User clicks "Edit" on a content item
2. Changes content from "Old text" → "New text"
3. Clicks "Save"
4. **Automatic refresh sequence:**
   - Content item saved to database ✅
   - Database recalculates `content_hash` ✅
   - Frontend calls `fetchTranslationStatus(cardId)` ✅
   - Translation status updates to "outdated" ⚠️
5. User sees "Update" button appear for outdated translations
6. User clicks "Update" to retranslate

**Before this feature:** Status would still show "up_to_date" ❌  
**After this feature:** Status immediately shows "outdated" ✅

---

## Benefits

1. **Accuracy**: Users always see correct translation status
2. **Immediate Feedback**: No need to refresh page or wait
3. **Better UX**: Clear indication of when translations need updating
4. **Consistency**: Status refreshes automatically across all operations
5. **Developer Friendly**: Single call added to each operation

---

## Technical Details

### `fetchTranslationStatus()` Method

```typescript
async fetchTranslationStatus(cardId: string) {
  try {
    const { data, error } = await supabase.rpc('get_card_translation_status', {
      p_card_id: cardId
    });

    if (error) throw error;

    this.translationStatus = data;
  } catch (error) {
    console.error('Failed to fetch translation status:', error);
    this.translationStatus = null;
  }
}
```

### Performance Considerations

- **Single RPC call** per operation (lightweight)
- **Async/await** doesn't block UI
- **Cached in Pinia store** for component access
- **Only fetches when needed** (after content changes)

---

## Testing

### Test Cases:

1. ✅ Create content item → Status refreshes
2. ✅ Update content item → Status shows "outdated"
3. ✅ Delete content item → Status refreshes
4. ✅ Update card name/description → Status shows "outdated"
5. ✅ Add sub-item → Status refreshes

### Expected Results:

**Before editing:**
```
Chinese (Traditional): ✅ Up to Date
Japanese: ✅ Up to Date
```

**After editing content:**
```
Chinese (Traditional): ⚠️ Outdated (content changed)
Japanese: ⚠️ Outdated (content changed)
```

---

## Related Files

- `src/components/CardContent/CardContent.vue` - Content item operations
- `src/components/CardComponents/CardView.vue` - Card detail updates
- `src/stores/translation.ts` - `fetchTranslationStatus()` method
- `sql/storeproc/client-side/05_translation_status.sql` - `get_card_translation_status` stored procedure

---

## Future Enhancements

1. Debounce rapid edits (avoid excessive API calls)
2. Show loading indicator during status refresh
3. Batch status fetches for multiple cards
4. WebSocket updates for real-time sync across tabs

---

## Deployment

### Frontend
```bash
cd /Users/nicholsontsang/coding/Cardy
npm run build  # or npm run dev
```

### Backend
No backend changes needed - uses existing `fetchTranslationStatus` method

---

## Conclusion

✅ **Feature Complete**: Translation status automatically refreshes after all content operations  
✅ **UX Improved**: Users see accurate status without manual refresh  
✅ **Reliable**: Consistent behavior across all content update operations  

**Status:** Production ready 🚀

