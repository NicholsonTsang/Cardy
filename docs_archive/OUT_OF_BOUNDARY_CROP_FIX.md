# Out-of-Boundary Cropping Fix

## Problem

When the crop area extended beyond the image boundaries, there was a mismatch between:
- **What users saw in the cropper** - Image with white background filling empty space
- **What got saved** - Image stretched to fill the entire crop area

### Example Scenario
```
User crops a 1000x1000 image with crop frame partially outside:
┌─────────────┐
│   Image     │
│  1000x1000  │
│        ┌────┼──┐
│        │Crop│  │  ← Crop extends 200px beyond image
│        │    │  │
└────────┴────┘  │
         │  Area │
         └───────┘
```

**Expected Result**: Image in top-left, white background on right/bottom
**Actual Result (BEFORE FIX)**: Image stretched to fill entire crop area ❌

## Root Cause

In `ImageCropper.vue`, the `getCroppedImage()` function had logic that:
1. ✅ Clamped source coordinates to stay within image bounds
2. ❌ But then drew the clamped area to fill the ENTIRE canvas

```javascript
// BEFORE (INCORRECT)
const clampedSourceX = Math.max(0, sourceX);
const clampedSourceWidth = Math.min(sourceWidth, naturalWidth - clampedSourceX);

// Drew to fill entire canvas - STRETCHING the image
ctx.drawImage(
    imageRef.value,
    clampedSourceX, clampedSourceY,
    clampedSourceWidth, clampedSourceHeight,
    0, 0, canvasWidth, canvasHeight  // ❌ Always fills full canvas
);
```

This caused the image to be stretched because:
- **Source**: Smaller area (clamped to image bounds)
- **Destination**: Full canvas size
- **Result**: Image stretched to fill canvas

## Solution

Updated `getCroppedImage()` to match the correct implementation in `cropUtils.js`:

1. **Calculate actual source area** (clamped to image bounds)
2. **Calculate destination offsets** (where image should be drawn on canvas)
3. **Draw only the visible portion** at the correct position

```javascript
// AFTER (CORRECT)

// 1. Calculate actual source rectangle (what part of image we can use)
const actualSourceX = Math.max(0, sourceX);
const actualSourceY = Math.max(0, sourceY);
const actualSourceRight = Math.min(sourceX + sourceWidth, naturalWidth);
const actualSourceBottom = Math.min(sourceY + sourceHeight, naturalHeight);
const actualSourceWidth = Math.max(0, actualSourceRight - actualSourceX);
const actualSourceHeight = Math.max(0, actualSourceBottom - actualSourceY);

// 2. Calculate destination position (where to draw on canvas)
// If sourceX is negative, image starts partway into crop frame
const destOffsetX = Math.max(0, -sourceX) / sourceWidth;
const destOffsetY = Math.max(0, -sourceY) / sourceHeight;
const destScaleX = actualSourceWidth / sourceWidth;
const destScaleY = actualSourceHeight / sourceHeight;

const destX = destOffsetX * canvasWidth;
const destY = destOffsetY * canvasHeight;
const destWidth = destScaleX * canvasWidth;
const destHeight = destScaleY * canvasHeight;

// 3. Draw with white background + image at correct position
ctx.fillStyle = '#ffffff';
ctx.fillRect(0, 0, canvasWidth, canvasHeight);

if (actualSourceWidth > 0 && actualSourceHeight > 0) {
    ctx.drawImage(
        imageRef.value,
        actualSourceX, actualSourceY,
        actualSourceWidth, actualSourceHeight,
        destX, destY, destWidth, destHeight  // ✅ Correct position and size
    );
}
```

## How It Works

### Case 1: Crop Entirely Within Image Bounds
```
sourceX = 100, sourceY = 100
sourceWidth = 400, sourceHeight = 600

actualSource = (100, 100, 400, 600) - same as source
destOffset = (0, 0) - no offset needed
destScale = (1, 1) - full scale
dest = (0, 0, canvasWidth, canvasHeight) - fills canvas

Result: Normal crop, fills canvas ✅
```

### Case 2: Crop Extends Beyond Right/Bottom
```
sourceX = 800, sourceY = 600
sourceWidth = 400, sourceHeight = 600
imageSize = 1000x1000

actualSource = (800, 600, 200, 400) - clamped to image edge
destOffset = (0, 0) - image starts at top-left
destScale = (0.5, 0.667) - image covers partial canvas
dest = (0, 0, canvasWidth*0.5, canvasHeight*0.667)

Result: Image in top-left, white space on right/bottom ✅
```

### Case 3: Crop Extends Beyond Left/Top
```
sourceX = -100, sourceY = -50
sourceWidth = 400, sourceHeight = 600

actualSource = (0, 0, 300, 550) - starts from image edge
destOffset = (100/400, 50/600) = (0.25, 0.083) - offset from edge
destScale = (0.75, 0.917) - partial canvas
dest = (canvasWidth*0.25, canvasHeight*0.083, ...)

Result: White space on left/top, image in bottom-right ✅
```

### Case 4: Crop Extends Beyond All Sides
```
sourceX = -50, sourceY = -50
sourceWidth = 1100, sourceHeight = 1100
imageSize = 1000x1000

actualSource = (0, 0, 1000, 1000) - entire image
destOffset = (50/1100, 50/1100) = (0.045, 0.045)
destScale = (1000/1100, 1000/1100) = (0.909, 0.909)
dest = centered with white border around

Result: Image centered with white padding on all sides ✅
```

## Visual Comparison

### Before Fix (Incorrect)
```
Crop extends 200px beyond right edge of 1000px image:

┌───────────────────┐
│                   │
│  Image stretched  │
│   to fill full    │
│   crop area       │  ← Image STRETCHED
│                   │
└───────────────────┘
```

### After Fix (Correct)
```
Crop extends 200px beyond right edge of 1000px image:

┌──────────┬────────┐
│          │        │
│  Image   │ White  │
│  at      │ back-  │  ← Image NOT stretched
│  correct │ ground │
│  size    │        │
└──────────┴────────┘
```

## Testing Scenarios

### ✅ Test Cases
1. **Normal crop** (entirely within bounds) - Should fill canvas
2. **Crop extends right** - White space on right
3. **Crop extends bottom** - White space on bottom
4. **Crop extends left** - White space on left
5. **Crop extends top** - White space on top
6. **Crop extends all sides** - White border around image
7. **Crop with zoom > 1** - Zoomed portion with correct boundaries
8. **Crop with image dragged** - Correct position maintained

### Verification
Compare:
1. **Cropper preview** (what you see during cropping)
2. **Saved image** (generated by `getCroppedImage()`)
3. **Re-loaded preview** (generated by `cropUtils.generateCroppedImage()`)

All three should match perfectly! ✅

## Files Modified

1. **`src/components/ImageCropper.vue`**
   - Updated `getCroppedImage()` function (lines 413-456)
   - Now matches logic from `cropUtils.js`

2. **`src/utils/cropUtils.js`**
   - Already had correct implementation (no changes needed)
   - Used as reference for the fix

## Technical Details

### Destination Calculations

**destOffsetX/Y**: Where to start drawing on canvas
```javascript
destOffsetX = Math.max(0, -sourceX) / sourceWidth;
```
- If `sourceX >= 0`: No offset, start at canvas edge (0)
- If `sourceX < 0`: Offset proportional to how far outside bounds

**destScaleX/Y**: How much of canvas to fill
```javascript
destScaleX = actualSourceWidth / sourceWidth;
```
- If crop fully inside: Scale = 1.0 (fill canvas)
- If crop partially outside: Scale < 1.0 (partial fill)

**destX/Y/Width/Height**: Final draw position
```javascript
destX = destOffsetX * canvasWidth;
destWidth = destScaleX * canvasWidth;
```
- Converts proportions to pixel values
- Maintains correct aspect ratio

### Canvas Drawing

```javascript
ctx.drawImage(
    image,
    sx, sy, sWidth, sHeight,  // Source rectangle
    dx, dy, dWidth, dHeight   // Destination rectangle
);
```

**Source**: The part of the image to copy
**Destination**: Where to paste it on canvas

By calculating both correctly, we preserve:
- ✅ Image proportions (no stretching)
- ✅ Relative positioning (what was left/right/center stays that way)
- ✅ White background in empty areas

## Benefits

1. **WYSIWYG** - What You See Is What You Get
   - Cropper preview matches saved image
   
2. **No distortion** - Images never stretched or squashed

3. **Consistent** - Same logic used for:
   - Initial crop generation
   - Preview generation  
   - Re-loading saved crops

4. **Professional** - Matches behavior of professional image editors

## Status

✅ **FIXED** - Out-of-boundary cropping now renders correctly with proper positioning and white background instead of stretching the image.

