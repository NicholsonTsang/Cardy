# Dual Image Storage - Frontend Implementation Guide

## Overview
This guide explains how to implement dual image storage (original + cropped) for cards and content items in the frontend.

## Database Changes (Already Complete)
✅ Added `original_image_url` columns to `cards` and `content_items` tables  
✅ Updated all stored procedures to handle both image URLs  
✅ Regenerated `all_stored_procedures.sql`

## Frontend Changes

### 1. Stores Updated ✅
- **`src/stores/card.ts`** - Updated to handle both image URLs
- **`src/stores/contentItem.ts`** - Updated to handle both image URLs

### 2. Vue Components Requiring Updates

#### A. `CardCreateEditForm.vue`
**Current Location**: `src/components/CardComponents/CardCreateEditForm.vue`

**Required Changes**:
1. **Store both raw file AND cropped file**:
```typescript
// Current single file storage
const selectedFile = ref<File | null>(null);

// NEW: Separate storage for original and cropped
const originalImageFile = ref<File | null>(null);
const croppedImageFile = ref<File | null>(null);
```

2. **Update image upload flow**:
```typescript
// When user uploads new image
const handleFileSelect = (event) => {
  const file = event.target.files[0];
  if (file) {
    // Store original file
    originalImageFile.value = file;
    
    // Create preview URL for cropper
    previewImageSrc.value = URL.createObjectURL(file);
    
    // Open cropper dialog
    showCropperDialog.value = true;
  }
};
```

3. **Handle crop completion**:
```typescript
const handleCropApplied = (cropResult) => {
  // Store cropped file
  croppedImageFile.value = cropResult.file;
  
  // Store crop parameters
  formData.value.cropParameters = cropResult.parameters;
  
  // Update preview with cropped image
  previewImage.value = cropResult.dataURL;
  
  // Close dialog
  showCropperDialog.value = false;
};
```

4. **Handle "Edit Crop" button**:
```typescript
const handleReCrop = () => {
  // Load ORIGINAL image for re-cropping
  const imageToEdit = formData.value.original_image_url || previewImage.value;
  
  if (imageToEdit) {
    previewImageSrc.value = imageToEdit;
    
    // Pass existing crop parameters to cropper
    existingCropParams.value = formData.value.cropParameters;
    
    showCropperDialog.value = true;
  }
};
```

5. **Update form submission**:
```typescript
const handleSave = async () => {
  const cardData = {
    name: formData.value.name,
    description: formData.value.description,
    imageFile: originalImageFile.value, // NEW: Original image
    croppedImageFile: croppedImageFile.value, // NEW: Cropped image
    cropParameters: formData.value.cropParameters,
    conversation_ai_enabled: formData.value.conversation_ai_enabled,
    ai_prompt: formData.value.ai_prompt,
    qr_code_position: formData.value.qr_code_position,
    image_url: formData.value.image_url, // For updates without new crop
    original_image_url: formData.value.original_image_url // For updates
  };
  
  if (isEditMode.value && props.cardId) {
    await cardStore.updateCard(props.cardId, cardData);
  } else {
    await cardStore.addCard(cardData);
  }
};
```

6. **Initialize form for editing**:
```typescript
const initializeForm = async () => {
  if (props.cardId) {
    const card = await cardStore.getCardById(props.cardId);
    if (card) {
      formData.value = {
        name: card.name,
        description: card.description,
        image_url: card.image_url, // Cropped URL
        original_image_url: card.original_image_url, // Original URL
        cropParameters: card.crop_parameters,
        conversation_ai_enabled: card.conversation_ai_enabled,
        ai_prompt: card.ai_prompt,
        qr_code_position: card.qr_code_position
      };
      
      // Show cropped image in preview
      previewImage.value = card.image_url;
    }
  }
};
```

#### B. `CardContentCreateEditForm.vue`
**Current Location**: `src/components/CardContent/CardContentCreateEditForm.vue`

**Apply the SAME changes as CardCreateEditForm.vue**, adapted for content items:
- Separate `originalImageFile` and `croppedImageFile` refs
- Update `handleFileSelect`, `handleCropApplied`, `handleReCrop`
- Update form submission to pass both files and URLs
- Update initialization to load both image URLs

#### C. `ImageCropper.vue`
**Current Location**: `src/components/ImageCropper.vue`

**Required Changes**:
1. **Update emit to include crop parameters**:
```typescript
const handleApply = () => {
  const croppedDataURL = getCroppedImage();
  const cropParams = getCropParameters();
  
  if (croppedDataURL && cropParams) {
    // Convert to File
    const arr = croppedDataURL.split(',');
    const mime = arr[0].match(/:(.*?);/)[1];
    const bstr = atob(arr[1]);
    let n = bstr.length;
    const u8arr = new Uint8Array(n);
    while (n--) {
      u8arr[n] = bstr.charCodeAt(n);
    }
    const file = new File([u8arr], 'cropped-image.jpg', { type: mime });
    
    emit('crop-applied', {
      file: file,
      dataURL: croppedDataURL,
      parameters: cropParams // NEW: Include crop parameters
    });
  } else {
    console.error('Failed to generate cropped image or parameters');
  }
};
```

2. **Ensure `applyCropParameters` works correctly** (already implemented):
   - Component already has `applyCropParameters(cropParams)` method
   - This method is called when `cropParameters` prop is provided
   - Restores zoom, position, and crop frame from saved parameters

### 3. Implementation Workflow

#### Scenario A: New Card/Content Creation
```
1. User uploads image (original)
   → Store in originalImageFile
   → Create preview URL
   
2. User crops image
   → Generate cropped version
   → Store in croppedImageFile
   → Save crop parameters
   
3. User saves
   → Upload originalImageFile → original_image_url
   → Upload croppedImageFile → image_url
   → Save crop_parameters to DB
```

#### Scenario B: Editing Existing Card/Content
```
1. Load card/content
   → Display image_url (cropped) in preview
   → Store original_image_url and crop_parameters
   
2. User clicks "Edit Crop"
   → Load original_image_url into cropper
   → Apply saved crop_parameters to restore previous crop
   
3. User adjusts crop
   → Generate new cropped version
   → Update croppedImageFile
   → Update crop_parameters
   
4. User saves
   → Upload new croppedImageFile if changed
   → Keep original_image_url unchanged
   → Update crop_parameters in DB
```

#### Scenario C: Changing Image Entirely
```
1. User clicks "Change Photo"
   → Upload new image (original)
   → Store in originalImageFile
   → Clear old images
   
2. User crops new image
   → Generate cropped version
   → Store in croppedImageFile
   → Save new crop_parameters
   
3. User saves
   → Upload new originalImageFile → original_image_url
   → Upload new croppedImageFile → image_url
   → Save new crop_parameters to DB
```

### 4. Key Implementation Points

#### Display Logic
```typescript
// ALWAYS show cropped image for display/preview
const displayImage = computed(() => formData.value.image_url);

// Use original for editing crop
const editingImage = computed(() => formData.value.original_image_url);
```

#### State Management
```typescript
// Track which image files need uploading
const needsOriginalUpload = computed(() => originalImageFile.value !== null);
const needsCroppedUpload = computed(() => croppedImageFile.value !== null);

// Only upload what changed
if (needsOriginalUpload.value) {
  // Upload original
}
if (needsCroppedUpload.value) {
  // Upload cropped
}
```

#### Reset Crop Functionality
```typescript
const handleResetCrop = () => {
  // Clear cropped image and parameters
  croppedImageFile.value = null;
  formData.value.cropParameters = null;
  
  // Show original image
  previewImage.value = formData.value.original_image_url;
};
```

### 5. Testing Checklist

- [ ] Create new card with image crop
- [ ] Edit existing card's crop
- [ ] Change card image entirely
- [ ] Reset crop to original
- [ ] Create content item with image crop
- [ ] Edit content item's crop
- [ ] Verify original and cropped images are both stored
- [ ] Verify crop parameters allow re-editing
- [ ] Test without cropping (upload only)
- [ ] Test image removal

### 6. Component File Paths

**Files Requiring Updates**:
1. `src/components/CardComponents/CardCreateEditForm.vue` - Card image handling
2. `src/components/CardContent/CardContentCreateEditForm.vue` - Content item image handling
3. `src/components/ImageCropper.vue` - Crop parameters emission

**Files Already Updated**:
- ✅ `src/stores/card.ts` - Card store with dual image support
- ✅ `src/stores/contentItem.ts` - Content item store with dual image support

### 7. Migration Notes

**Existing Data**:
- Existing cards/content items only have `image_url` populated
- `original_image_url` will be NULL for old data
- When users edit old items and crop again:
  - If they upload a new image: both URLs get populated
  - If they just save without re-cropping: original_image_url stays NULL
- This is acceptable - the feature works going forward

**Backward Compatibility**:
- Frontend handles NULL `original_image_url` gracefully
- If `original_image_url` is NULL, "Edit Crop" can use existing `image_url` as fallback
- All existing functionality continues to work

## Summary

The implementation requires updating 3 Vue components to:
1. Store both original and cropped image files separately
2. Pass crop parameters when saving
3. Load original image + parameters when re-editing crop
4. Handle all edge cases (new upload, edit crop, change image, reset)

The store layer is already updated and ready to accept both image files and parameters.

