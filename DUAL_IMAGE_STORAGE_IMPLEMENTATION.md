# Dual Image Storage Implementation

## Overview
Implemented support for storing both cropped and original images for cards and content items, with crop parameters for re-editing.

## Architecture

### Database Schema Changes

#### Cards Table
```sql
CREATE TABLE cards (
    ...
    image_url TEXT,              -- Cropped/processed image for display
    original_image_url TEXT,     -- Original uploaded image (raw, uncropped)
    crop_parameters JSONB,       -- Crop parameters for re-editing
    ...
);
```

#### Content Items Table
```sql
CREATE TABLE content_items (
    ...
    image_url TEXT,              -- Cropped/processed image for display  
    original_image_url TEXT,     -- Original uploaded image (raw, uncropped)
    crop_parameters JSONB,       -- Crop parameters for re-editing
    ...
);
```

### Crop Parameters Format
```json
{
  "zoom": 1.5,
  "position": {"x": 100, "y": 50},
  "cropArea": {
    "width": 400,
    "height": 600,
    "x": 50,
    "y": 100
  },
  "naturalSize": {
    "width": 1920,
    "height": 1080
  }
}
```

## Workflow

### 1. Initial Upload & Crop
```
User uploads image
  ↓
Store as original_image_url
  ↓
User crops image
  ↓
Generate cropped version → image_url
Store crop parameters → crop_parameters
```

### 2. Re-Editing Crop
```
User clicks "Edit Crop"
  ↓
Load original_image_url
Apply crop_parameters to show previous crop
  ↓
User adjusts crop
  ↓
Generate new cropped version → update image_url
Update crop_parameters
```

### 3. Display
```
For preview/display: Use image_url (cropped)
For editing: Use original_image_url + crop_parameters
```

## Files Modified

### Database
- ✅ `sql/schema.sql` - Added `original_image_url` columns
- ✅ `sql/storeproc/client-side/02_card_management.sql` - Updated card functions
- ⏳ `sql/storeproc/client-side/03_content_management.sql` - Needs update
- ⏳ Regenerate `sql/all_stored_procedures.sql`
- ⏳ Deploy to database

### Frontend (To Do)
- ⏳ Update card upload/crop logic
- ⏳ Update content item upload/crop logic
- ⏳ Modify ImageCropper to support loading existing crop
- ⏳ Update stores to handle both image URLs

## Implementation Status

### Completed ✅
1. Schema updated with `original_image_url` columns
2. Card management stored procedures updated:
   - `get_user_cards()` - Returns both URLs
   - `create_card()` - Accepts both URLs
   - `update_card()` - Updates both URLs

### In Progress ⏳
3. Content item stored procedures (similar updates needed)
4. Generate combined SQL file
5. Deploy to database

### Pending 📋
6. Frontend implementation
7. Testing

## Next Steps

See continuation in implementation...

