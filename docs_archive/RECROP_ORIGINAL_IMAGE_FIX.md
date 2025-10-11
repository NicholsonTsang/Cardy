# Re-Crop Using Original Image Fix

## Problem

When users clicked "Edit Crop" to re-adjust the crop area, the cropper was loading the **already-cropped image** instead of the **original image**. This caused:
1. Loss of image quality (cropping a cropped image)
2. Unable to expand crop area beyond previous crop
3. Degraded image each time crop was re-edited

## Root Cause

In both `CardCreateEditForm.vue` and `CardContentCreateEditForm.vue`, the `handleReCrop()` function was using the wrong image source:

```javascript
// BEFORE (INCORRECT)
const handleReCrop = () => {
    // Using cropped image (image_url) ❌
    const imageSrc = props.cardProp.image_url;
    imageToCrop.value = imageSrc;
};
```

The code was loading:
- `image_url` → The cropped/processed image
- NOT `original_image_url` → The raw uploaded image

## Solution

Updated both components to use the correct image priority:

```javascript
// AFTER (CORRECT)
const handleReCrop = () => {
    // Priority: imageFile > original_image_url > image_url (fallback)
    const originalImage = imageFile.value || 
                          props.cardProp?.original_image_url || 
                          props.cardProp?.image_url;
    
    const imageSrc = imageFile.value ? 
                     URL.createObjectURL(imageFile.value) : 
                     originalImage;
    imageToCrop.value = imageSrc;
    
    // Restore previous crop state
    cropParameters.value = formData.cropParameters || 
                          props.cardProp.crop_parameters;
};
```

## Image Source Priority

### 1. `imageFile` (Highest Priority)
**When**: User just uploaded a new image in current session
**Why**: Use the in-memory file object for best quality
**Source**: Local File object

### 2. `original_image_url` (Primary)
**When**: Editing existing card/content with saved original
**Why**: Use the stored original image, not the cropped version
**Source**: Database field (newly added)

### 3. `image_url` (Fallback)
**When**: Old data created before dual-image system
**Why**: Backward compatibility for existing cards
**Source**: Database field (legacy)

## Visual Flow

### Before Fix ❌
```
Original Upload: 2000x3000px
     ↓
First Crop: 1000x1500px → Saved as image_url
     ↓
User clicks "Edit Crop"
     ↓
Loads 1000x1500px cropped image ❌
     ↓
Second Crop: 800x1200px (quality loss)
     ↓
Can't expand beyond 1000x1500px boundary ❌
```

### After Fix ✅
```
Original Upload: 2000x3000px → Saved as original_image_url
     ↓
First Crop: 1000x1500px → Saved as image_url
     ↓
User clicks "Edit Crop"
     ↓
Loads 2000x3000px original image ✅
Applies previous crop parameters (zoom, position)
     ↓
Second Crop: Can adjust to any area of 2000x3000px ✅
     ↓
No quality loss - always using original
```

## Changes Made

### CardCreateEditForm.vue

**1. Updated `handleReCrop()`**:
```javascript
const handleReCrop = () => {
    // Use original_image_url instead of image_url
    const originalImage = imageFile.value || 
                          props.cardProp?.original_image_url || 
                          props.cardProp?.image_url; // Fallback
    
    if (originalImage) {
        const imageSrc = imageFile.value ? 
                         URL.createObjectURL(imageFile.value) : 
                         originalImage;
        imageToCrop.value = imageSrc;
        
        // Restore crop parameters
        cropParameters.value = formData.cropParameters || 
                              props.cardProp.crop_parameters;
        showCropDialog.value = true;
    } else {
        console.warn('No original image available for re-cropping');
    }
};
```

### CardContentCreateEditForm.vue

**1. Updated `formData` to include `originalImageUrl`**:
```javascript
const formData = ref({
    // ... other fields
    imageUrl: null,          // Cropped image
    originalImageUrl: null,  // Original image (NEW)
    cropParameters: null
});
```

**2. Updated watch to load `original_image_url`**:
```javascript
watch(() => props.contentItem, (newVal) => {
    if (newVal) {
        formData.value = {
            // ... other fields
            imageUrl: newVal.image_url || null,
            originalImageUrl: newVal.original_image_url || null, // NEW
            cropParameters: newVal.crop_parameters || null
        };
    }
});
```

**3. Updated `handleReCrop()`**: Same pattern as CardCreateEditForm

**4. Updated `handleResetCrop()`**: Also uses original image

**5. Updated `resetForm()`**: Includes originalImageUrl field

## Benefits

### 1. No Quality Loss ✅
- Always crop from original high-resolution image
- Each re-crop maintains original quality
- No generational degradation

### 2. Full Flexibility ✅
- Can expand crop area to any part of original image
- Not limited by previous crop boundaries
- True re-cropping experience

### 3. Restored Crop State ✅
- Previous crop parameters loaded automatically
- User sees their last crop position
- Can make small adjustments easily

### 4. Backward Compatible ✅
- Falls back to `image_url` for old data
- Works with cards created before dual-image system
- No breaking changes

## Example Scenarios

### Scenario 1: Re-crop after saving
```
1. User uploads 2000x3000 image
2. Crops to center 1000x1500
3. Saves card
4. Later clicks "Edit Crop"
   ✅ Loads original 2000x3000 image
   ✅ Shows previous crop area (center 1000x1500)
   ✅ User can expand to edges or re-position
```

### Scenario 2: Multiple re-crops
```
1. First crop: Top portion
2. Save
3. Edit crop: Move to middle portion
4. Save  
5. Edit crop again: Move to bottom portion
   ✅ Each time uses original 2000x3000 image
   ✅ No quality loss across multiple edits
```

### Scenario 3: Expand crop area
```
1. Initial crop: 800x1200 (tight crop)
2. Edit crop: Want to expand to 1200x1800
   ✅ Can expand because using original 2000x3000
   ❌ Would fail if using previous 800x1200 cropped image
```

### Scenario 4: Old card (backward compatibility)
```
Card created before dual-image system:
- Has: image_url (cropped)
- Missing: original_image_url

Edit crop:
  ✅ Falls back to image_url
  ⚠️ Limited by cropped dimensions (expected for old data)
  ✅ No errors or breaking behavior
```

## Testing Checklist

### Cards
- [x] Create card with crop
- [x] Click "Edit Crop" - loads original image
- [x] Crop parameters restored correctly
- [x] Can expand crop beyond previous boundaries
- [x] Save and re-edit multiple times - no quality loss
- [x] Old cards without original_image_url still work

### Content Items
- [x] Create content with crop
- [x] Click "Edit Crop" - loads original image
- [x] Crop parameters restored correctly
- [x] Can expand crop beyond previous boundaries
- [x] Save and re-edit multiple times - no quality loss
- [x] Old content without original_image_url still work

## Files Modified

1. **`src/components/CardComponents/CardCreateEditForm.vue`**
   - Updated `handleReCrop()` to use `original_image_url`
   - Added priority logic for image source selection

2. **`src/components/CardContent/CardContentCreateEditForm.vue`**
   - Added `originalImageUrl` to formData
   - Updated watch to load `original_image_url`
   - Updated `handleReCrop()` to use `original_image_url`
   - Updated `handleResetCrop()` to use `original_image_url`
   - Updated `resetForm()` to include `originalImageUrl`

## Technical Details

### Image Source Selection Logic
```javascript
// Priority cascade
const originalImage = 
    imageFile.value ||              // 1. New upload in memory
    formData.originalImageUrl ||    // 2. Saved original from DB
    formData.imageUrl;              // 3. Fallback (old data)
```

### Crop Parameters Restoration
```javascript
// Load previous crop state
cropParameters.value = 
    formData.cropParameters ||      // From local form state
    props.contentItem.crop_parameters;  // From DB
```

The ImageCropper component's `applyCropParameters()` method then:
1. Restores zoom level
2. Restores image position
3. Restores crop frame dimensions
4. User sees their previous crop exactly as they left it

## Status

✅ **FIXED** - "Edit Crop" now correctly loads the original image with restored crop parameters, allowing users to re-crop without quality loss and with full flexibility.

## Related Documentation

- `DUAL_IMAGE_STORAGE_IMPLEMENTATION.md` - Overview of dual image system
- `IMAGE_UPLOAD_NULL_FIX.md` - Fix for image upload issues
- `OUT_OF_BOUNDARY_CROP_FIX.md` - Crop rendering fixes

