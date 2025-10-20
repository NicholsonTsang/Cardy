# Mobile Client Content Detail Language Refresh Fix

## Issue
In the mobile client, when viewing a content detail page and changing the language via the app bar language selector:
- ❌ The main content description stayed in the old language
- ✅ Sub-items updated to the new language correctly

This created an inconsistent experience where parts of the page showed different languages.

## Root Cause

When the language changes in `PublicCardView.vue`:

1. ✅ The watcher detects the language change (line 263)
2. ✅ `fetchCardData()` is called and fetches translated content
3. ✅ `contentItems` array is updated with translated content (lines 204-217)
4. ❌ **BUT** `selectedContent` still points to the OLD object with OLD translations
5. ❌ `ContentDetail` component receives stale data via `:content="selectedContent"` prop (line 52)

### Why Sub-Items Updated Correctly

The `subContent` computed property (lines 138-143) **filters from the updated `contentItems` array**, so it always has fresh translations:

```typescript
const subContent = computed(() => {
  if (!selectedContent.value) return []
  return contentItems.value.filter(  // ✅ Uses updated contentItems
    item => item.content_item_parent_id === selectedContent.value!.content_item_id
  )
})
```

But the main content (`selectedContent`) was set once when the item was selected and never updated after language changes.

## Solution

Updated the language change watcher to refresh the `selectedContent` reference after re-fetching data:

```typescript
watch(() => mobileLanguageStore.selectedLanguage.code, async () => {
  console.log('📱 Language changed to:', mobileLanguageStore.selectedLanguage.code)
  
  // Store the currently selected content ID to restore selection after reload
  const currentContentId = selectedContent.value?.content_item_id
  
  // Re-fetch data with new language
  await fetchCardData()
  
  // If user was viewing a content detail, update selectedContent to the refreshed version
  if (currentContentId && contentItems.value.length > 0) {
    const updatedContent = contentItems.value.find(item => item.content_item_id === currentContentId)
    if (updatedContent) {
      selectedContent.value = updatedContent  // ✅ Update to fresh translated version
    }
  }
})
```

### How It Works

1. User changes language while viewing content detail
2. Watcher saves the current content item ID
3. `fetchCardData()` fetches all content with new translations
4. Find the same content item in the refreshed `contentItems` array (by ID)
5. Update `selectedContent` to point to the new translated version
6. Vue's reactivity updates `ContentDetail` component with fresh data
7. Both main content and sub-items now show the new language! 🎉

## User Experience Impact

**Before:**
1. User viewing content detail in English
2. User changes language to Chinese in app bar
3. ❌ Main description stays in English
4. ✅ Sub-items change to Chinese
5. Confusing mixed-language page

**After:**
1. User viewing content detail in English
2. User changes language to Chinese in app bar
3. ✅ Main description changes to Chinese
4. ✅ Sub-items change to Chinese
5. Consistent language throughout! 🌐

## Testing

### Test Scenario 1: Content Detail Language Switch
1. Open a card on mobile (scan QR or preview)
2. Navigate to any content detail page with description text
3. Change language using the language selector in app bar
4. ✅ **Expected**: Content title and description update to new language immediately
5. ✅ **Expected**: Sub-items (if any) also show new language
6. ✅ **Expected**: No mixed languages on screen

### Test Scenario 2: Multiple Language Switches
1. Open content detail page
2. Switch language to Chinese → verify content updates
3. Switch to Spanish → verify content updates again
4. Switch back to English → verify returns to English
5. ✅ **Expected**: All switches work smoothly

### Test Scenario 3: Different Views
1. Test language switch on Card Overview → ✅ Should work (already working)
2. Test language switch on Content List → ✅ Should work (already working)
3. Test language switch on Content Detail → ✅ Should work (NOW FIXED!)

### Test Scenario 4: Sub-Items Navigation
1. On content detail with sub-items
2. Change language
3. Click a sub-item to navigate deeper
4. ✅ **Expected**: Sub-item detail shows in the new language
5. Navigate back
6. ✅ **Expected**: Parent content still shows in new language

## Files Modified
- ✅ `src/views/MobileClient/PublicCardView.vue` - Updated language change watcher

## Technical Notes

### Why Not Use Watchers in ContentDetail?

We could have watched `selectedContent` prop changes in `ContentDetail.vue`, but that would add unnecessary complexity. The parent component (`PublicCardView`) is the source of truth for data and language selection, so it makes sense to handle the refresh there.

### Content Item Identity

Content items are identified by `content_item_id` (UUID), which remains constant across translations. This allows us to safely find the updated version of the same item after language changes.

### Performance Considerations

The fix uses `Array.find()` to locate the updated content item. With typical content counts (10-100 items per card), this is negligible. For very large cards (1000+ items), this is still acceptable as it only runs on language changes (user-initiated action).

## Related Components
- `PublicCardView.vue` - Main mobile card view orchestrator
- `ContentDetail.vue` - Content detail display component
- `ContentList.vue` - Content list view (already working)
- `CardOverview.vue` - Card overview (already working)
- `useMobileLanguageStore` - Mobile language state management

## Additional Notes

This fix ensures a consistent multilingual experience for mobile visitors. The pattern of "save ID → re-fetch → restore selection" is a common pattern for handling reference updates after data refresh, and can be applied to similar scenarios where objects need to be refreshed while maintaining user context.

