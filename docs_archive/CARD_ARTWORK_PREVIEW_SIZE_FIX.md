# Card Artwork Preview Size Fix

## Problem

The card artwork preview image in the Card Create/Edit form appeared smaller than expected within the card image container, not utilizing the full available space.

## Root Causes

### 1. Padding on Wrong Element
```html
<!-- BEFORE -->
<div class="card-artwork-container p-4">  <!-- Padding here -->
    <div class="relative w-full h-full">
        <img class="object-cover h-full w-full" />
    </div>
</div>
```

**Issue**: Padding was on the outer container, which:
- Reduced the effective height of the container
- Made `h-full` on the image fill a smaller area
- Container aspect ratio applied to padded box, but image was inside that

**Result**: Image was smaller than container dimensions

### 2. Small Max Width
```css
.card-artwork-container {
    max-width: 240px;  /* Too small */
}
```

**Issue**: 240px max width meant:
- Outer container: 240px
- With padding (1rem = 16px × 2): 240px - 32px = 208px effective width
- Image only 208px wide at most

### 3. Object-fit: cover
```html
<img class="object-cover" />
```

**Issue**: `object-cover` crops the image to fill the container, which:
- May cut off parts of the card artwork
- Not ideal for preview where you want to see the full card design

## Solution

### 1. Moved Padding to Inner Element ✅
```html
<!-- AFTER -->
<div class="card-artwork-container">  <!-- No padding here -->
    <div class="relative w-full h-full p-4">  <!-- Padding here -->
        <img class="object-contain h-full w-full" />
    </div>
</div>
```

**Benefit**:
- Container maintains full aspect ratio dimensions
- Image fills the container height/width properly
- Padding provides visual spacing without affecting image size

### 2. Increased Max Width ✅
```css
.card-artwork-container {
    max-width: 300px;  /* Increased from 240px */
}
```

**Benefit**:
- 25% larger preview (240px → 300px)
- Better visibility of card details
- Still reasonable size for the sidebar

### 3. Changed to Object-contain ✅
```html
<img class="object-contain h-full w-full" />
```

**Benefit**:
- Shows the entire card design without cropping
- Maintains aspect ratio
- Better for preview purposes

## Visual Comparison

### Before Fix
```
Container: 240px × 360px (2:3 ratio)
├─ Border + Padding: 4px + 16px inset
└─ Image effective area: ~208px × ~328px

Image appears small within the dashed border box
```

### After Fix
```
Container: 300px × 450px (2:3 ratio)
├─ Border: 4px (no inner padding on container)
├─ Inner wrapper: Full 300px × 450px with padding
└─ Image effective area: ~268px × ~418px

Image fills most of the container properly
```

## Code Changes

### CardCreateEditForm.vue

**Template Change**:
```vue
<!-- Before -->
<div class="card-artwork-container ... p-4">
    <div class="relative w-full h-full">
        <img class="object-cover h-full w-full" />

<!-- After -->
<div class="card-artwork-container ...">
    <div class="relative w-full h-full p-4">
        <img class="object-contain h-full w-full" />
```

**CSS Change**:
```css
/* Before */
.card-artwork-container {
    max-width: 240px;
}
.card-artwork-container img {
    object-fit: cover;  /* Redundant with template */
}
.card-artwork-container:hover img {
    transform: scale(1.02);
}

/* After */
.card-artwork-container {
    max-width: 300px;  /* Increased */
}
.card-artwork-container img {
    /* object-fit set in template */
}
.card-artwork-container:hover img {
    transform: scale(1.01);  /* Subtler effect */
}
```

## Benefits

1. **Better Preview** ✅
   - 25% larger display area
   - Full card design visible
   - Better for reviewing artwork

2. **Proper Aspect Ratio** ✅
   - Image uses full container dimensions
   - Aspect ratio properly maintained
   - No unexpected cropping

3. **Better UX** ✅
   - Users can see card details clearly
   - QR code overlay properly visible
   - Visual feedback on hover is subtler

4. **Consistent Behavior** ✅
   - Works with all card aspect ratios
   - Responsive to container size changes
   - Padding doesn't affect image sizing

## Testing Checklist

- [x] Card artwork preview displays at proper size
- [x] Image fills most of the container area
- [x] Aspect ratio maintained (2:3 for cards)
- [x] Padding provides visual spacing
- [x] QR code overlay positioned correctly
- [x] Hover effect works smoothly
- [x] Works in create mode
- [x] Works in edit mode
- [x] Responsive to different screen sizes

## Technical Details

### Container Structure
```
.card-artwork-container (aspect-ratio: 2/3, max-width: 300px)
  └─ .relative.w-full.h-full.p-4 (padding wrapper)
      ├─ <img> (object-contain, fills wrapper minus padding)
      └─ QR overlay (absolute positioned)
```

### Sizing Calculation
```
Container max dimensions: 300px × 450px
Inner padding: 16px on all sides
Effective image area: ~268px × ~418px
Border space: 4px around outer container
```

### Object-fit Comparison
- **object-cover**: Fills container, may crop image ❌
- **object-contain**: Shows full image, may have letterboxing ✅ (Better for preview)

## Files Modified

1. **`src/components/CardComponents/CardCreateEditForm.vue`**
   - Moved `p-4` from container to inner wrapper
   - Changed `object-cover` to `object-contain`
   - Increased max-width from 240px to 300px
   - Updated CSS comments

## Status

✅ **FIXED** - Card artwork preview now properly utilizes the container space and displays at the expected size.

## Notes

- The cropped image is already at the correct 2:3 aspect ratio
- Using `object-contain` ensures the full card design is visible
- Padding on the inner element maintains visual spacing without affecting sizing calculations
- The 300px max width provides a good balance between visibility and layout

