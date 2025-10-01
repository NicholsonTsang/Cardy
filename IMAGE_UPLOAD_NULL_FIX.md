# Image Upload NULL Fix - Summary

## Problem Identified

After creating or editing cards/content items with photo uploads:
- **Cards**: `image_url` was NULL (cropped image not being uploaded)
- **Content Items**: `original_image_url` was NULL (original image not being uploaded)

## Root Cause

The frontend components were only saving **crop parameters** but NOT generating the **cropped image file**. The updated stores expected both:
1. `imageFile` - Original uploaded image
2. `croppedImageFile` - Cropped version of the image

But the components were only providing `imageFile` without `croppedImageFile`.

## Solution Implemented

### 1. Updated `CardCreateEditForm.vue`

**Changes Made**:
- Added `croppedImageFile` ref to store the cropped image
- Updated `handleCropConfirm()` to call both:
  - `getCropParameters()` - Get crop state
  - `getCroppedImage()` - Generate cropped image dataURL
- Convert cropped dataURL to File object and store in `croppedImageFile`
- Updated `getPayload()` to include both `imageFile` and `croppedImageFile`

**Key Code Changes**:
```javascript
// Added ref
const croppedImageFile = ref(null);

// Updated crop confirm handler
const handleCropConfirm = async () => {
    const cropParams = imageCropperRef.value.getCropParameters();
    const croppedDataURL = imageCropperRef.value.getCroppedImage();
    
    // Convert dataURL to File
    const arr = croppedDataURL.split(',');
    const mime = arr[0].match(/:(.*?);/)[1];
    const bstr = atob(arr[1]);
    let n = bstr.length;
    const u8arr = new Uint8Array(n);
    while (n--) {
        u8arr[n] = bstr.charCodeAt(n);
    }
    croppedImageFile.value = new File([u8arr], 'cropped-image.jpg', { type: mime });
};

// Updated payload
const getPayload = () => {
    return {
        ...formData,
        imageFile: imageFile.value, // Original
        croppedImageFile: croppedImageFile.value, // Cropped
        cropParameters: cropParameters.value
    };
};
```

### 2. Updated `CardContentCreateEditForm.vue`

**Changes Made** (identical pattern to Card form):
- Added `croppedImageFile` ref
- Updated `handleCropConfirm()` to generate cropped image file
- Updated `getFormData()` to return both files

### 3. Updated `CardContent.vue`

**Changes Made**:
Updated three handler functions to destructure and pass both files to the store:

```javascript
// handleAddContentItem
const { formData, imageFile, croppedImageFile } = cardContentCreateFormRef.value.getFormData();
finalFormData.imageFile = imageFile;
finalFormData.croppedImageFile = croppedImageFile;

// handleAddSubItem
const { formData, imageFile, croppedImageFile } = cardContentSubItemCreateFormRef.value.getFormData();
finalFormData.imageFile = imageFile;
finalFormData.croppedImageFile = croppedImageFile;

// handleEditContentItem
const { formData, imageFile, croppedImageFile } = cardContentEditFormRef.value.getFormData();
finalFormData.imageFile = imageFile;
finalFormData.croppedImageFile = croppedImageFile;
```

## How It Works Now

### Card Creation/Update Flow:
```
1. User uploads image
   → Stored in `imageFile` (original)
   
2. User crops image
   → getCropParameters() → Save zoom/position
   → getCroppedImage() → Generate cropped dataURL
   → Convert to File → Store in `croppedImageFile`
   
3. User saves
   → Upload `imageFile` → `original_image_url`
   → Upload `croppedImageFile` → `image_url`
   → Save `cropParameters` → `crop_parameters`
```

### Content Item Creation/Update Flow:
```
1. User uploads image
   → Stored in `imageFile` (original)
   
2. User crops image
   → Generate both parameters and cropped file
   → Stored in `croppedImageFile`
   
3. Parent component submits
   → Pass both files to store
   → Store uploads both files
   → `imageFile` → `original_image_url`
   → `croppedImageFile` → `image_url`
```

## Files Modified

1. **`src/components/CardComponents/CardCreateEditForm.vue`**
   - Added `croppedImageFile` ref
   - Updated `handleCropConfirm()`
   - Updated `getPayload()`

2. **`src/components/CardContent/CardContentCreateEditForm.vue`**
   - Added `croppedImageFile` ref
   - Updated `handleCropConfirm()`
   - Updated `getFormData()`

3. **`src/components/CardContent/CardContent.vue`**
   - Updated `handleAddContentItem()`
   - Updated `handleAddSubItem()`
   - Updated `handleEditContentItem()`

## Testing Checklist

- [x] Card creation with image crop
- [x] Card update with new image crop
- [x] Content item creation with image crop
- [x] Content item update with new image crop
- [x] Sub-item creation with image crop

## Expected Database State After Fix

**Cards Table**:
- `image_url` - Cropped image URL (display) ✅
- `original_image_url` - Original image URL (for re-editing) ✅
- `crop_parameters` - Crop state JSONB ✅

**Content Items Table**:
- `image_url` - Cropped image URL (display) ✅
- `original_image_url` - Original image URL (for re-editing) ✅
- `crop_parameters` - Crop state JSONB ✅

## Storage Bucket Structure

```
userfiles/
├── {user_id}/
│   └── card-images/
│       ├── {uuid}_original.jpg  ← Original image
│       └── {uuid}_cropped.jpg   ← Cropped image
└── {user_id}/
    └── {card_id}/
        └── content-item-images/
            ├── {uuid}_original.jpg
            └── {uuid}_cropped.jpg
```

## Status

✅ **FIXED** - Both `image_url` (cropped) and `original_image_url` (raw) are now properly uploaded and stored for cards and content items.

