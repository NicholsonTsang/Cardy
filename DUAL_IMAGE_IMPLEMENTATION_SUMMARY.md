# Dual Image Storage Implementation - Summary

## What Was Implemented

A comprehensive dual image storage system that allows storing both original (raw) and cropped images for cards and content items, with crop parameters to enable re-editing of crops.

## Changes Made

### ✅ Database Layer (Complete)

#### 1. Schema Updates (`sql/schema.sql`)
- Added `original_image_url TEXT` column to `cards` table
- Added `original_image_url TEXT` column to `content_items` table
- Both columns store the raw, uncropped uploaded images
- Existing `image_url` columns now store cropped/processed images
- Existing `crop_parameters JSONB` columns store crop state for re-editing

#### 2. Stored Procedures Updated
**`sql/storeproc/client-side/02_card_management.sql`**:
- `get_user_cards()` - Returns both `image_url` and `original_image_url`
- `create_card()` - Accepts `p_original_image_url` parameter
- `update_card()` - Accepts `p_original_image_url` parameter

**`sql/storeproc/client-side/03_content_management.sql`**:
- `get_card_content_items()` - Returns both `image_url` and `original_image_url`
- `get_content_item_by_id()` - Returns both URLs
- `create_content_item()` - Accepts `p_original_image_url` parameter
- `update_content_item()` - Accepts `p_original_image_url` parameter

#### 3. Generated Files
- ✅ Regenerated `sql/all_stored_procedures.sql` with updated functions
- ✅ Created `sql/deploy_original_image_columns.sql` for safe deployment

**Deployment**: You'll manually deploy `schema.sql` and `all_stored_procedures.sql`

### ✅ Frontend Layer (Stores Complete, Components Require Updates)

#### 1. TypeScript Interfaces Updated

**`src/stores/card.ts`**:
```typescript
export interface Card {
  image_url: string | null; // Cropped/processed image for display
  original_image_url: string | null; // Original uploaded image
  crop_parameters?: any; // Crop state
  // ... other fields
}

export interface CardFormData {
  imageFile?: File | null; // New uploaded file (raw)
  croppedImageFile?: File | null; // Cropped version
  image_url?: string; // Cropped image URL
  original_image_url?: string; // Original image URL
  cropParameters?: any; // Crop parameters
  // ... other fields
}
```

**`src/stores/contentItem.ts`**:
- Same structure as Card interfaces, adapted for content items

#### 2. Store Functions Updated

**Card Store (`src/stores/card.ts`)**:
- `addCard()` - Uploads both original and cropped images to separate files
  - Original: `{uuid}_original.{ext}`
  - Cropped: `{uuid}_cropped.{ext}`
- `updateCard()` - Conditionally uploads new images if files provided
- Both functions pass `p_original_image_url` to stored procedures

**Content Item Store (`src/stores/contentItem.ts`)**:
- `createContentItem()` - Uploads both original and cropped images
- `updateContentItem()` - Conditionally uploads new images
- `uploadContentItemImage()` - Updated to accept `imageType` parameter ('original' | 'cropped')
- All functions pass `p_original_image_url` to stored procedures

#### 3. Components Requiring Updates

**Three components need updates to implement the full workflow**:

1. **`src/components/CardComponents/CardCreateEditForm.vue`**
   - Separate `originalImageFile` and `croppedImageFile` refs
   - Update image upload flow to store both files
   - Update crop handler to save crop parameters
   - Implement "Edit Crop" to load original + parameters
   - Update form submission to pass both files

2. **`src/components/CardContent/CardContentCreateEditForm.vue`**
   - Same changes as CardCreateEditForm
   - Adapted for content items instead of cards

3. **`src/components/ImageCropper.vue`**
   - Update `crop-applied` emit to include crop parameters
   - Already has `applyCropParameters()` method (works)
   - Minimal changes needed

**See `DUAL_IMAGE_STORAGE_FRONTEND_GUIDE.md` for detailed implementation guide.**

## Architecture

### Image Flow

```
┌─────────────────────────────────────────────────────────────┐
│                      User Uploads Image                      │
└────────────────────────────┬────────────────────────────────┘
                             │
                             ▼
                    ┌─────────────────┐
                    │  Original File  │◄──── Stored for re-editing
                    └────────┬────────┘
                             │
                             ▼
                    ┌─────────────────┐
                    │  Image Cropper  │
                    │   (User Crops)  │
                    └────────┬────────┘
                             │
                             ▼
              ┌──────────────┴──────────────┐
              │                             │
              ▼                             ▼
     ┌─────────────────┐          ┌─────────────────┐
     │  Cropped File   │          │ Crop Parameters │
     │ (Display Image) │          │   (JSONB Data)  │
     └────────┬────────┘          └────────┬────────┘
              │                             │
              └──────────────┬──────────────┘
                             │
                             ▼
                    ┌─────────────────┐
                    │   Upload Both   │
                    │  Files + Params │
                    └────────┬────────┘
                             │
                             ▼
                    ┌─────────────────┐
                    │    Database     │
                    │  3 Fields Saved │
                    └─────────────────┘
                    • original_image_url
                    • image_url
                    • crop_parameters
```

### Re-Editing Flow

```
┌──────────────────────────────────────────────────────────────┐
│              User Clicks "Edit Crop" Button                  │
└────────────────────────────┬─────────────────────────────────┘
                             │
                             ▼
              ┌──────────────────────────────────┐
              │  Load from Database:             │
              │  • original_image_url (raw)      │
              │  • crop_parameters (zoom/pos)    │
              └───────────────┬──────────────────┘
                              │
                              ▼
                     ┌─────────────────┐
                     │  Image Cropper  │
                     │ (Restore State) │
                     └────────┬────────┘
                              │
                              ▼
              ┌───────────────────────────────┐
              │  User Adjusts Crop            │
              │  (Zoom, Position, Rotation)   │
              └───────────────┬───────────────┘
                              │
                              ▼
              ┌───────────────────────────────┐
              │  Generate New Cropped Image   │
              │  Update Crop Parameters       │
              └───────────────┬───────────────┘
                              │
                              ▼
                     ┌─────────────────┐
                     │  Save Changes:  │
                     │  • Keep original│
                     │  • New cropped  │
                     │  • New params   │
                     └─────────────────┘
```

## Benefits

1. **Re-editable Crops**: Users can adjust crops without re-uploading images
2. **Non-Destructive**: Original images are preserved
3. **Flexible**: Users can reset crops to original at any time
4. **Optimized Display**: Cropped images used for previews/displays (smaller size)
5. **Future-Proof**: Original images available for different aspect ratios later

## File Storage Structure

```
Storage Bucket: userfiles
└── {user_id}/
    ├── card-images/
    │   ├── {uuid}_original.jpg    ← Original uploaded image
    │   └── {uuid}_cropped.jpg     ← Cropped/processed image
    └── {card_id}/
        └── content-item-images/
            ├── {uuid}_original.jpg
            └── {uuid}_cropped.jpg
```

## Backward Compatibility

- Existing data: Only `image_url` is populated, `original_image_url` is NULL
- Frontend handles NULL `original_image_url` gracefully
- "Edit Crop" falls back to `image_url` if `original_image_url` is NULL
- All existing functionality continues to work
- Feature works going forward for new/updated items

## Next Steps

1. **Deploy Database Changes** (You will do manually)
   - Run updated `schema.sql` OR `deploy_original_image_columns.sql`
   - Run `all_stored_procedures.sql`

2. **Update Vue Components** (Remaining Work)
   - Update `CardCreateEditForm.vue` per guide
   - Update `CardContentCreateEditForm.vue` per guide
   - Update `ImageCropper.vue` to emit crop parameters

3. **Testing** (After component updates)
   - Test new card creation with crop
   - Test editing existing card's crop
   - Test content item creation with crop
   - Test re-editing crops
   - Test image changes
   - Test reset crop functionality

## Documentation Files Created

1. `DUAL_IMAGE_STORAGE_IMPLEMENTATION.md` - Technical architecture overview
2. `DUAL_IMAGE_STORAGE_FRONTEND_GUIDE.md` - Detailed component update guide
3. `DUAL_IMAGE_IMPLEMENTATION_SUMMARY.md` - This file (high-level summary)

## Status

| Component | Status |
|-----------|--------|
| Database Schema | ✅ Complete |
| Stored Procedures | ✅ Complete |
| SQL Generation | ✅ Complete |
| Card Store | ✅ Complete |
| Content Item Store | ✅ Complete |
| Deployment | ⏳ Manual (You) |
| CardCreateEditForm | 📋 Needs Update |
| CardContentCreateEditForm | 📋 Needs Update |
| ImageCropper | 📋 Needs Minor Update |
| Testing | 📋 After Components |

---

**Ready for:** Database deployment (manual) + Frontend component updates

