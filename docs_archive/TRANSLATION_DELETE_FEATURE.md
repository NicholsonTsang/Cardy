# Translation Delete Feature

**Date:** November 5, 2025  
**Status:** ✅ Implemented

## Overview

Added the ability to delete existing translations directly from the Translation Dialog. Users can now manage their translations more effectively by removing languages they no longer need without leaving the dialog.

## Feature Details

### Location

The delete functionality is integrated into **Step 1 (Language Selection)** of the Translation Dialog, appearing as a new "Existing Translations" section.

### UI Components

#### Existing Translations Section

```vue
<div class="bg-slate-50 border-2 border-slate-200 rounded-lg p-4">
  <div class="flex items-center justify-between mb-3">
    <div class="flex items-center gap-2">
      <div class="w-8 h-8 bg-slate-200 rounded-lg flex items-center justify-center">
        <i class="pi pi-database text-slate-600"></i>
      </div>
      <h4 class="font-semibold text-slate-900">Existing Translations</h4>
    </div>
    <span class="text-xs text-slate-500">3 languages</span>
  </div>
  
  <!-- List of existing translations -->
</div>
```

#### Translation Cards

Each existing translation is displayed as a card with:
- **Language flag and name** (e.g., 🇯🇵 Japanese)
- **Status tag** (Up to Date / Outdated)
- **Last translated date** (e.g., "2 hours ago", "3 days ago")
- **Delete button** (trash icon, danger color)

```vue
<div class="flex items-center justify-between p-3 bg-white border border-slate-200 rounded-lg hover:border-slate-300 transition-all">
  <div class="flex items-center gap-3">
    <span class="text-xl">🇯🇵</span>
    <div>
      <div class="flex items-center gap-2">
        <span class="text-sm font-medium text-slate-900">Japanese</span>
        <Tag value="Up to Date" severity="success" class="text-xs" />
      </div>
      <span class="text-xs text-slate-500">2 hours ago</span>
    </div>
  </div>
  
  <Button
    icon="pi pi-trash"
    severity="danger"
    text
    rounded
    @click="confirmDeleteTranslation(lang)"
    v-tooltip.left="Delete this translation"
  />
</div>
```

### Functionality

#### 1. Display Existing Translations

```typescript
const existingTranslations = computed(() => {
  return props.availableLanguages.filter(
    lang => lang.status === 'up_to_date' || lang.status === 'outdated'
  );
});
```

Shows only languages that have been translated (either up-to-date or outdated), excluding:
- Original language
- Not translated languages

#### 2. Confirmation Dialog

Uses PrimeVue's `ConfirmDialog` component with:
- Warning icon
- Language-specific message
- Danger-styled confirm button
- Cancel button

```typescript
const confirmDeleteTranslation = (translation: TranslationStatus) => {
  confirm.require({
    message: t('translation.delete.confirm', { language: translation.language_name }),
    header: t('translation.delete.title'),
    icon: 'pi pi-exclamation-triangle',
    acceptClass: 'p-button-danger',
    accept: () => handleDeleteTranslation(translation.language as LanguageCode),
  });
};
```

#### 3. Delete Process

```typescript
const handleDeleteTranslation = async (language: LanguageCode) => {
  deletingLanguage.value = language; // Show loading state
  
  try {
    // Call translation store method
    await translationStore.deleteTranslation(props.cardId, language);
    
    // Show success toast
    toast.add({
      severity: 'success',
      summary: t('translation.delete.success'),
      detail: t('translation.delete.successMessage'),
      life: 3000,
    });
    
    // Notify parent to reload translation status
    emit('translated');
  } catch (error: any) {
    // Show error toast
    toast.add({
      severity: 'error',
      summary: t('translation.delete.error'),
      detail: error.message,
      life: 5000,
    });
  } finally {
    deletingLanguage.value = null; // Clear loading state
  }
};
```

#### 4. Loading State

While deleting, the specific delete button shows a loading spinner:
```vue
<Button
  :disabled="deletingLanguage === lang.language"
  :loading="deletingLanguage === lang.language"
/>
```

### User Flow

1. **User opens Translation Dialog**
   - Sees "Existing Translations" section if any languages have been translated
   
2. **User clicks delete button on a language**
   - Confirmation dialog appears with warning
   - Message: "Are you sure you want to delete the Japanese translation? This action cannot be undone."

3. **User confirms deletion**
   - Delete button shows loading spinner
   - Translation is deleted from database
   - Success toast appears: "Translation Deleted"
   - Dialog refreshes to show updated translations
   - "Existing Translations" section hides if no translations remain

4. **User cancels deletion**
   - Confirmation dialog closes
   - No changes made

### Design System Alignment

The delete feature follows the harmonized design system:

1. **Colors**
   - Slate for neutral elements
   - Red (danger) for delete button
   - Green for success tags
   - Amber for outdated tags

2. **Components**
   - Icon container: `w-8 h-8 bg-slate-200 rounded-lg`
   - Emphasized border: `border-2 border-slate-200`
   - Hover states: `hover:border-slate-300`
   - Transitions: `transition-all`

3. **Typography**
   - Heading: `font-semibold text-slate-900`
   - Labels: `text-sm font-medium text-slate-900`
   - Secondary text: `text-xs text-slate-500`

4. **Interactive Elements**
   - Rounded delete button with tooltip
   - Text button (no background until hover)
   - Hover: `hover:bg-red-50`

## Files Modified

### 1. `src/components/Card/TranslationDialog.vue`

**Added:**
- `existingTranslations` computed property
- `deletingLanguage` state
- `confirmDeleteTranslation` method
- `handleDeleteTranslation` method
- `formatDate` helper method
- Import `useConfirm` from PrimeVue
- Import `ConfirmDialog` component
- "Existing Translations" section in template
- `<ConfirmDialog />` component in template

### 2. `src/i18n/locales/en.json`

**Added translation keys:**
```json
{
  "translation": {
    "dialog": {
      "existingTranslations": "Existing Translations",
      "deleteTranslation": "Delete this translation"
    }
  }
}
```

**Existing keys used:**
- `translation.delete.title`: "Delete Translation"
- `translation.delete.confirm`: "Are you sure you want to delete the {language} translation? This action cannot be undone."
- `translation.delete.success`: "Translation Deleted"
- `translation.delete.successMessage`: "Translation deleted successfully"
- `translation.delete.error`: "Failed to Delete"
- `translation.status.up_to_date`: "Up to Date"
- `translation.status.outdated`: "Outdated"
- `translation.time.justNow`: "Just now"
- `translation.time.hoursAgo`: "{hours} hours ago"
- `translation.time.daysAgo`: "{days} days ago"

## Backend Integration

Uses existing `translationStore.deleteTranslation()` method which calls:
- Stored procedure: `delete_card_translation`
- Parameters: `p_card_id`, `p_language`
- Automatically refreshes translation status after deletion

## Benefits

### 1. **Convenience**
- Delete translations without leaving the dialog
- No need to navigate to separate management view
- Quick cleanup of unwanted translations

### 2. **User Control**
- Users can manage their translations efficiently
- See all existing translations in one place
- Clear status indicators (up-to-date vs outdated)

### 3. **Design Consistency**
- Follows the harmonized design system
- Matches other components' styling
- Professional, polished appearance

### 4. **Safety**
- Confirmation dialog prevents accidental deletions
- Clear warning message
- Shows which language will be deleted
- Loading states prevent double-clicks

### 5. **Feedback**
- Success/error toasts provide clear feedback
- Loading states show operation in progress
- Immediate UI update after deletion

## Edge Cases Handled

1. **No Existing Translations**
   - Section doesn't show if no translations exist
   - Graceful handling with `v-if="existingTranslations.length > 0"`

2. **Multiple Deletions**
   - Loading state prevents clicking multiple delete buttons
   - Each deletion is independent

3. **Delete During Translation**
   - Dialog locks during translation (Step 2)
   - Delete only available in Step 1

4. **Error Handling**
   - Shows error toast with error message
   - Clears loading state on error
   - Doesn't close dialog on error

5. **Date Formatting**
   - Relative dates for recent translations ("2 hours ago")
   - Absolute dates for older translations
   - Handles missing dates gracefully

## User Experience

### Before
- ❌ Had to close Translation Dialog
- ❌ Navigate to Translation Management page
- ❌ Find the specific translation
- ❌ Click delete button there

### After
- ✅ See all existing translations in the dialog
- ✅ Delete with one click (+ confirmation)
- ✅ Stay in the same workflow
- ✅ Continue with other translation tasks

## Visual Design

The "Existing Translations" section:
- Clearly separated from language selection
- Emphasized with `border-2` for importance
- Icon container matches other sections
- Cards have subtle hover effect
- Status tags provide at-a-glance info
- Delete button is clearly danger-styled

## Future Enhancements

Potential improvements:
1. Batch delete (select multiple to delete)
2. Undo deletion (with time limit)
3. Export translation before delete
4. Delete history/audit log
5. Keyboard shortcuts (Delete key)
6. Drag-to-delete gesture (mobile)

## Testing Checklist

- [x] Section shows only when translations exist
- [x] Section hides when no translations exist
- [x] Delete button shows tooltip on hover
- [x] Confirmation dialog appears on delete click
- [x] Confirmation dialog has correct language name
- [x] Delete button shows loading state during deletion
- [x] Success toast appears after successful deletion
- [x] Error toast appears if deletion fails
- [x] Dialog refreshes after deletion
- [x] Parent component reloads translation status
- [x] Multiple translations can be deleted sequentially
- [x] No linter errors
- [x] Design matches harmonized system
- [x] Responsive on mobile/tablet
- [x] Date formatting works correctly

## Documentation

- Added: `TRANSLATION_DELETE_FEATURE.md` (this file)
- Updated: `CLAUDE.md` with feature reference

