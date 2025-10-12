# Original Language Field Fix

## Issue
When creating or editing a card, the `original_language` field was not being saved to the database. Users could select a language in the dropdown, but it wouldn't persist after save.

## Root Cause
The `card.ts` store was **missing the `p_original_language` parameter** when calling both `create_card` and `update_card` stored procedures via `supabase.rpc()`.

### What Was Working:
- ✅ UI form (`CardCreateEditForm.vue`) had the dropdown and `v-model` binding
- ✅ Form data included `original_language` field (line 415)
- ✅ `getPayload()` returned the `original_language` value
- ✅ Stored procedures accepted `p_original_language` parameter
- ✅ Database schema had `original_language` column

### What Was Broken:
- ❌ `addCard()` in `card.ts` didn't pass `p_original_language` to `create_card` RPC
- ❌ `updateCard()` in `card.ts` didn't pass `p_original_language` to `update_card` RPC

## Fix Applied

### File: `/Users/nicholsontsang/coding/Cardy/src/stores/card.ts`

#### 1. Added `original_language` to `CardFormData` interface (line 27-41)
**Before:**
```typescript
export interface CardFormData {
    name: string;
    description: string;
    imageFile?: File | null;
    croppedImageFile?: File | null;
    image_url?: string;
    original_image_url?: string;
    cropParameters?: any;
    conversation_ai_enabled: boolean;
    ai_instruction: string;
    ai_knowledge_base: string;
    qr_code_position: string;
    id?: string;
    // Missing original_language
}
```

**After:**
```typescript
export interface CardFormData {
    name: string;
    description: string;
    imageFile?: File | null;
    croppedImageFile?: File | null;
    image_url?: string;
    original_image_url?: string;
    cropParameters?: any;
    conversation_ai_enabled: boolean;
    ai_instruction: string;
    ai_knowledge_base: string;
    qr_code_position: string;
    original_language?: string; // ✅ Added
    id?: string;
}
```

#### 2. `addCard` function (line 149-161)
**Before:**
```typescript
const { data, error: createError } = await supabase
    .rpc('create_card', {
        p_name: cardData.name,
        p_description: cardData.description,
        p_image_url: croppedImageUrl,
        p_original_image_url: originalImageUrl,
        p_crop_parameters: cardData.cropParameters || null,
        p_conversation_ai_enabled: cardData.conversation_ai_enabled,
        p_ai_instruction: cardData.ai_instruction,
        p_ai_knowledge_base: cardData.ai_knowledge_base,
        p_qr_code_position: cardData.qr_code_position
        // Missing p_original_language
    });
```

**After:**
```typescript
const { data, error: createError } = await supabase
    .rpc('create_card', {
        p_name: cardData.name,
        p_description: cardData.description,
        p_image_url: croppedImageUrl,
        p_original_image_url: originalImageUrl,
        p_crop_parameters: cardData.cropParameters || null,
        p_conversation_ai_enabled: cardData.conversation_ai_enabled,
        p_ai_instruction: cardData.ai_instruction,
        p_ai_knowledge_base: cardData.ai_knowledge_base,
        p_qr_code_position: cardData.qr_code_position,
        p_original_language: cardData.original_language || 'en' // ✅ Added
    });
```

#### 3. `updateCard` function (line 251-264)
**Before:**
```typescript
const payload = {
    p_card_id: cardId,
    p_name: updateData.name,
    p_description: updateData.description,
    p_image_url: croppedImageUrl || null,
    p_original_image_url: originalImageUrl || null,
    p_crop_parameters: updateData.cropParameters || null,
    p_conversation_ai_enabled: updateData.conversation_ai_enabled,
    p_ai_instruction: updateData.ai_instruction,
    p_ai_knowledge_base: updateData.ai_knowledge_base,
    p_qr_code_position: updateData.qr_code_position
    // Missing p_original_language
};
```

**After:**
```typescript
const payload = {
    p_card_id: cardId,
    p_name: updateData.name,
    p_description: updateData.description,
    p_image_url: croppedImageUrl || null,
    p_original_image_url: originalImageUrl || null,
    p_crop_parameters: updateData.cropParameters || null,
    p_conversation_ai_enabled: updateData.conversation_ai_enabled,
    p_ai_instruction: updateData.ai_instruction,
    p_ai_knowledge_base: updateData.ai_knowledge_base,
    p_qr_code_position: updateData.qr_code_position,
    p_original_language: updateData.original_language || 'en' // ✅ Added
};
```

## Testing
After this fix:
1. Create a new card and select a language other than English → Language should be saved
2. Edit an existing card and change the language → Language should be updated
3. View card details → `original_language` field should display the correct value
4. Translation feature → Should use the saved `original_language` for determining source language

## Impact
- **Low Risk**: Only adds a missing parameter to existing RPC calls
- **No Breaking Changes**: Default value is 'en' (English) if not provided
- **Backward Compatible**: Existing cards without `original_language` will still work

## Related Files
- `src/stores/card.ts` - Fixed RPC parameter passing
- `src/components/CardComponents/CardCreateEditForm.vue` - UI form (already working)
- `sql/storeproc/client-side/02_card_management.sql` - Stored procedures (already correct)

## Notes
This fix ensures that the "Original Language" feature works correctly for:
- Translation management system
- AI language detection
- Content organization by source language
- Translation status tracking

The `original_language` field is critical for the translation feature, as it tells the system which language is the "source of truth" for content translations.

---

**Status**: ✅ Fixed
**Date**: 2025-01-12

