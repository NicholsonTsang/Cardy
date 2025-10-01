# Image File Usage Scenarios

## Overview
The system stores TWO image files for every uploaded image:
1. **`imageFile`** (original) - Raw uploaded image, never modified
2. **`croppedImageFile`** - Cropped/processed version for display

## Detailed Scenario Breakdown

### Scenario 1: New Upload Without Crop
**User Action**: Upload image but skip cropping (if allowed)

**Files Generated**:
- ❌ `imageFile` - Original upload
- ❌ `croppedImageFile` - None (no crop performed)

**Database Result**:
- `original_image_url` - NULL (or same as image_url)
- `image_url` - Original upload URL
- `crop_parameters` - NULL

**Status**: ⚠️ Currently NOT SUPPORTED - cropping is mandatory in current UI flow

---

### Scenario 2: New Upload With Crop ✅ MAIN FLOW
**User Action**: Upload image → Crop → Save

**Files Generated**:
1. **`imageFile`** ← Original file from upload
2. **`croppedImageFile`** ← Generated from cropper

**Process Flow**:
```
User uploads file.jpg (1920x1080)
  ↓
imageFile = file.jpg (stored in memory)
  ↓
User crops to 800x1200
  ↓
ImageCropper.getCroppedImage() generates cropped dataURL
  ↓
Convert dataURL to File object
  ↓
croppedImageFile = cropped-image.jpg (800x1200)
  ↓
BOTH files uploaded to storage:
  - imageFile → {uuid}_original.jpg → original_image_url
  - croppedImageFile → {uuid}_cropped.jpg → image_url
```

**Database Result**:
- `original_image_url` - Points to original 1920x1080 image
- `image_url` - Points to cropped 800x1200 image
- `crop_parameters` - {zoom: 1.2, position: {x: 50, y: 30}, ...}

**Used In**:
- ✅ Card creation
- ✅ Card update (new image)
- ✅ Content item creation
- ✅ Content item update (new image)
- ✅ Sub-item creation

---

### Scenario 3: Edit Existing Card/Content Without Changing Image
**User Action**: Edit name/description but don't touch image

**Files Generated**:
- ❌ `imageFile` - None (no new upload)
- ❌ `croppedImageFile` - None (no new crop)

**Database Result**:
- `original_image_url` - Unchanged (existing URL)
- `image_url` - Unchanged (existing URL)
- `crop_parameters` - Unchanged (existing parameters)

**Code Behavior**:
```javascript
// In store update functions
if (updateData.imageFile) {
    // Upload new original
}
if (updateData.croppedImageFile) {
    // Upload new cropped
}
// If both are undefined, keep existing URLs
```

**Used In**:
- ✅ Card update (text only)
- ✅ Content item update (text only)

---

### Scenario 4: Re-Crop Existing Image (FUTURE)
**User Action**: Click "Edit Crop" → Adjust crop → Save

**Expected Flow** (currently partially implemented):
```
Load original_image_url
  ↓
imageFile = null (reusing existing original)
  ↓
ImageCropper loads original + crop_parameters
  ↓
User adjusts crop
  ↓
getCroppedImage() generates NEW cropped version
  ↓
croppedImageFile = new cropped version
  ↓
Upload ONLY croppedImageFile:
  - croppedImageFile → {new-uuid}_cropped.jpg → image_url
  - original_image_url stays unchanged (reuse existing)
```

**Database Result**:
- `original_image_url` - Unchanged (reuse existing)
- `image_url` - NEW cropped URL
- `crop_parameters` - NEW parameters

**Status**: ⚠️ Partially implemented - needs frontend "Edit Crop" button to be wired

---

### Scenario 5: Replace Image Entirely
**User Action**: Click "Change Photo" → Upload new image → Crop → Save

**Files Generated**:
1. **`imageFile`** ← NEW original file
2. **`croppedImageFile`** ← NEW cropped version

**Process** (same as Scenario 2):
```
Clear old files
  ↓
User uploads new-file.jpg
  ↓
imageFile = new-file.jpg
  ↓
User crops
  ↓
croppedImageFile = new-cropped.jpg
  ↓
BOTH uploaded as new files
```

**Database Result**:
- `original_image_url` - NEW original URL
- `image_url` - NEW cropped URL
- `crop_parameters` - NEW parameters

**Used In**:
- ✅ Card update (change photo)
- ✅ Content item update (change photo)

---

## File Usage Matrix

| Scenario | imageFile Used? | croppedImageFile Used? | Upload Count |
|----------|----------------|----------------------|--------------|
| New upload + crop | ✅ Original | ✅ Generated | 2 files |
| Edit without image change | ❌ | ❌ | 0 files |
| Re-crop existing | ❌ (reuse DB) | ✅ Generated | 1 file |
| Replace image entirely | ✅ New original | ✅ Generated | 2 files |

---

## Upload Patterns in Store

### Card Store (`addCard`, `updateCard`)
```javascript
// Upload original if provided
if (cardData.imageFile) {
    const originalFileName = `${uuidv4()}_original.${ext}`;
    upload(originalFileName) → original_image_url
}

// Upload cropped if provided  
if (cardData.croppedImageFile) {
    const croppedFileName = `${uuidv4()}_cropped.${ext}`;
    upload(croppedFileName) → image_url
}

// Both, one, or neither can be provided
```

### Content Item Store (`createContentItem`, `updateContentItem`)
```javascript
// Upload original if provided
if (itemData.imageFile) {
    upload('original') → original_image_url
}

// Upload cropped if provided
if (itemData.croppedImageFile) {
    upload('cropped') → image_url
}
```

---

## Component Responsibilities

### `CardCreateEditForm.vue` / `CardContentCreateEditForm.vue`

**When user uploads NEW image**:
```javascript
imageFile = uploadedFile;  // Store original
showCropDialog = true;     // Open cropper
```

**When user completes crop**:
```javascript
croppedImageFile = getCroppedImage();  // Generate cropped
cropParameters = getCropParameters();   // Save state
```

**When user clicks "Edit Crop" button** (future):
```javascript
imageFile = null;                      // Don't re-upload original
loadExisting(original_image_url);      // Load from DB
applyCropParameters(crop_parameters);  // Restore state
// User adjusts...
croppedImageFile = getCroppedImage();  // Generate NEW cropped only
```

**When user saves**:
```javascript
payload = {
    imageFile: imageFile.value,           // null or File
    croppedImageFile: croppedImageFile.value,  // null or File
    cropParameters: cropParameters.value
};
```

---

## Storage Bucket File Naming

### Cards
```
userfiles/
└── {user_id}/
    └── card-images/
        ├── abc123_original.jpg    ← imageFile upload
        └── abc123_cropped.jpg     ← croppedImageFile upload
```

### Content Items
```
userfiles/
└── {user_id}/
    └── {card_id}/
        └── content-item-images/
            ├── def456_original.jpg    ← imageFile upload
            └── def456_cropped.jpg     ← croppedImageFile upload
```

---

## Key Takeaways

1. **`imageFile` is ALWAYS the raw, unmodified upload** - used for:
   - First-time uploads
   - Complete image replacements
   - Storing the "source of truth" for future re-crops

2. **`croppedImageFile` is ALWAYS the display version** - used for:
   - Every crop operation (new or re-crop)
   - What users see in cards/content
   - Optimized for aspect ratio and size

3. **Both files can be independently uploaded**:
   - New upload: Both files uploaded
   - Re-crop: Only `croppedImageFile` uploaded
   - Text edit: Neither file uploaded

4. **The store handles conditional uploads**:
   - Checks if file exists before uploading
   - Allows partial updates (e.g., only cropped)
   - Preserves existing URLs if no new file provided

5. **Current implementation**:
   - ✅ New uploads with crop (both files)
   - ✅ Text-only edits (no files)
   - ✅ Complete image replacement (both files)
   - ⚠️ Re-crop existing needs UI wiring ("Edit Crop" button)

