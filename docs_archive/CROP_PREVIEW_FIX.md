# Image Crop Preview Fix

## Issue
After applying crop in the ImageCropper dialog, the card artwork photo was not showing the cropped area correctly.

## Root Cause
The crop calculation in `getCroppedImage()` was not properly accounting for how `object-fit: contain` displays images within the container. The previous calculation assumed the image filled the entire container, but `object-fit: contain` maintains aspect ratio and may leave empty space.

## Solution

### 1. Fixed Crop Coordinate Calculation
Updated `getCroppedImage()` in `ImageCropper.vue` to properly calculate crop coordinates:

```javascript
// Calculate how object-fit: contain displays the image
let displayedImageWidth, displayedImageHeight;
let imageDisplayLeft, imageDisplayTop;

if (imageAspectRatio > containerAspectRatio) {
    // Image is wider - fits by width
    displayedImageWidth = containerWidth;
    displayedImageHeight = containerWidth / imageAspectRatio;
    imageDisplayLeft = 0;
    imageDisplayTop = (containerHeight - displayedImageHeight) / 2;
} else {
    // Image is taller - fits by height
    displayedImageHeight = containerHeight;
    displayedImageWidth = containerHeight * imageAspectRatio;
    imageDisplayLeft = (containerWidth - displayedImageWidth) / 2;
    imageDisplayTop = 0;
}
```

### 2. Proper Zoom and Position Handling
```javascript
// Apply zoom and position to the displayed image
const scaledDisplayWidth = displayedImageWidth * zoom.value;
const scaledDisplayHeight = displayedImageHeight * zoom.value;

const finalImageLeft = imageDisplayLeft + (displayedImageWidth - scaledDisplayWidth) / 2 + imagePosition.value.x;
const finalImageTop = imageDisplayTop + (displayedImageHeight - scaledDisplayHeight) / 2 + imagePosition.value.y;

// Calculate crop coordinates relative to the scaled displayed image
const cropLeft = frameLeft - finalImageLeft;
const cropTop = frameTop - finalImageTop;

// Convert back to natural image coordinates
const scaleToNatural = naturalWidth / scaledDisplayWidth;
const sourceX = cropLeft * scaleToNatural;
const sourceY = cropTop * scaleToNatural;
```

### 3. Enhanced Error Handling and Debugging
- Added console logging to track crop data flow
- Added white background fill to prevent transparency issues
- Proper coordinate clamping to image bounds

```javascript
// Clamp source coordinates to image bounds
const clampedSourceX = Math.max(0, Math.min(sourceX, naturalWidth));
const clampedSourceY = Math.max(0, Math.min(sourceY, naturalHeight));
const clampedSourceWidth = Math.min(sourceWidth, naturalWidth - clampedSourceX);
const clampedSourceHeight = Math.min(sourceHeight, naturalHeight - clampedSourceY);

// Draw cropped image with white background
ctx.fillStyle = '#ffffff';
ctx.fillRect(0, 0, canvasWidth, canvasHeight);
```

## Testing Steps

1. **Upload an image** in CardCreateEditForm
2. **Open crop dialog** (should appear if image aspect ratio doesn't match target)
3. **Position and zoom** the image as desired
4. **Click Apply** 
5. **Verify** the preview image shows the exact cropped area
6. **Check console** for debug logs confirming successful crop processing

## Expected Behavior

- ✅ Cropped image preview shows exactly what was selected in the crop frame
- ✅ Image maintains proper aspect ratio
- ✅ No distortion or incorrect positioning
- ✅ Console logs confirm successful processing
- ✅ High-quality output (800px max dimension)

## Debug Information

The fix includes console logging to help verify the process:

```javascript
// In ImageCropper.vue
console.log('Crop applied successfully, dataURL length:', croppedDataURL.length);
console.log('Emitting crop-applied with file size:', file.size, 'bytes');

// In CardCreateEditForm.vue  
console.log('Received cropped data:', {
    hasFile: !!croppedData.file,
    fileSize: croppedData.file?.size,
    hasDataURL: !!croppedData.dataURL,
    dataURLLength: croppedData.dataURL?.length
});
console.log('Updated preview image:', previewImage.value ? 'Set to dataURL' : 'Still null');
```

This ensures the crop data is properly generated and received by the form component.
