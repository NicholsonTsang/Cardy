# Environment Configuration Audit & Fix

## Issue Found
The `cardConfig.ts` file was referencing environment variables that were **not defined** in the `.env` files, causing the application to always use hardcoded defaults.

## Variables Added

### Card Aspect Ratio Configuration
These variables control the aspect ratio of card images (the main digital card design):

```bash
VITE_CARD_ASPECT_RATIO_WIDTH=2    # Width component of aspect ratio
VITE_CARD_ASPECT_RATIO_HEIGHT=3   # Height component of aspect ratio
```

**Result:** Cards maintain a **2:3 portrait aspect ratio** (e.g., 240px × 360px)

### Content Aspect Ratio Configuration  
These variables control the aspect ratio of content item images (exhibit/artifact photos):

```bash
VITE_CONTENT_ASPECT_RATIO_WIDTH=4    # Width component of aspect ratio
VITE_CONTENT_ASPECT_RATIO_HEIGHT=3   # Height component of aspect ratio
```

**Result:** Content images maintain a **4:3 landscape aspect ratio** (e.g., 400px × 300px)

## Files Updated

### 1. `.env` (Development/Local)
✅ Added all 4 card configuration variables
- Used by local development server
- Located at project root

### 2. `.env.production` (Production)
✅ Added all 4 card configuration variables
- Used when building for production
- Same values as development for consistency

## How cardConfig.ts Uses These Variables

```typescript
// Card aspect ratio (2:3 portrait)
export const getCardAspectRatioNumber = (): number => {
  const width = parseFloat(import.meta.env.VITE_CARD_ASPECT_RATIO_WIDTH || '2');
  const height = parseFloat(import.meta.env.VITE_CARD_ASPECT_RATIO_HEIGHT || '3');
  return width / height; // Returns 0.6667 (2/3)
};

// Content aspect ratio (4:3 landscape)
export const getContentAspectRatioNumber = (): number => {
  const width = parseFloat(import.meta.env.VITE_CONTENT_ASPECT_RATIO_WIDTH || '4');
  const height = parseFloat(import.meta.env.VITE_CONTENT_ASPECT_RATIO_HEIGHT || '3');
  return width / height; // Returns 1.3333 (4/3)
};
```

## Where These Are Used

### Card Aspect Ratio (2:3)
- `CardCreateEditForm.vue` - Card design upload and cropping
- `ImageCropper.vue` - Image cropping with correct aspect ratio
- Card preview components - Display cards with correct proportions
- QR code positioning - Ensures proper placement on card

### Content Aspect Ratio (4:3)  
- `CardContentCreateEditForm.vue` - Content item image upload
- Content preview components - Display exhibit/artifact photos
- Image cropping for content items - Maintains consistent ratios

## Benefits of This Configuration

✅ **Flexible Design**: Change aspect ratios without code changes
✅ **Consistent Behavior**: Development and production use same ratios
✅ **Easy Testing**: Can test different aspect ratios by changing env vars
✅ **Documentation**: Clear what aspect ratios the system expects

## Current Values Explained

### Why 2:3 for Cards?
- **Portrait orientation** - Natural for vertical card designs
- **Standard card ratio** - Similar to trading cards, business cards (vertical)
- **Mobile-friendly** - Works well on mobile screens in portrait mode
- **Professional appearance** - Common ratio for ID cards, membership cards

### Why 4:3 for Content?
- **Landscape orientation** - Natural for photos of exhibits, artifacts
- **Camera standard** - Many cameras default to 4:3 ratio
- **Display-friendly** - Works well in content grids and galleries
- **Balanced composition** - Good for showcasing objects and scenes

## Customizing Aspect Ratios

If you need different aspect ratios in the future:

### For Cards (e.g., square cards):
```bash
VITE_CARD_ASPECT_RATIO_WIDTH=1
VITE_CARD_ASPECT_RATIO_HEIGHT=1
```

### For Content (e.g., widescreen 16:9):
```bash
VITE_CONTENT_ASPECT_RATIO_WIDTH=16
VITE_CONTENT_ASPECT_RATIO_HEIGHT=9
```

## Testing

After changing these values:
1. Restart the development server
2. Upload a new card image - should crop to new aspect ratio
3. Upload content images - should crop to new aspect ratio
4. Verify all previews display correctly

## Related Files
- `/src/utils/cardConfig.ts` - Configuration utility functions
- `/src/components/ImageCropper.vue` - Image cropping component
- `/src/components/CardComponents/CardCreateEditForm.vue` - Card upload
- `/src/components/CardContent/CardContentCreateEditForm.vue` - Content upload

