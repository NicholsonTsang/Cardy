# Export/Import Option C - Implementation Status

## ✅ COMPLETED STEPS

### 1. Excel Export Updates ✅
- [x] Added hidden "Crop Data" column to CARD and CONTENT sheets
- [x] Updated excelConstants.js to include new column
- [x] Export now includes original images (not cropped)
- [x] Export serializes crop_parameters as JSON in hidden column
- [x] Updated column widths (hidden column = 0 width)
- [x] Updated descriptions for all sheets

### 2. Utility Functions Created ✅
- [x] Created src/utils/imageCropUtils.js
  - `applyCropParametersToImage()` - Apply crop params to generate cropped image
  - `isValidCropParameters()` - Validate crop params
  - `parseCropParameters()` - Parse JSON string to object

### 3. Excel Import Parsing ✅
- [x] Updated parseCardSheet() to read crop_parameters_json
- [x] Updated parseContentSheet() to read crop_parameters_json
- [x] Field mappings updated

## 🔧 REMAINING WORK

### 4. Import Logic Update (In Progress)
- [ ] Update CardBulkImport.vue `importDataToDatabase()` function:
  1. Read crop_parameters_json from importData
  2. For cards with crop parameters:
     - Upload original image → original_image_url
     - Apply crop parameters to generate cropped image
     - Upload cropped image → image_url
     - Pass crop_parameters as JSONB
  3. For content items with crop parameters:
     - Same dual image upload process

### 5. Testing
- [ ] Test export with cropped images
- [ ] Test import with crop parameters
- [ ] Verify cropped images match original
- [ ] Test edge cases (no crop params, invalid JSON)

## 📋 IMPLEMENTATION PLAN FOR STEP 4

Update `importDataToDatabase()` in CardBulkImport.vue:

```javascript
import { applyCropParametersToImage, parseCropParameters } from '@/utils/imageCropUtils'

async function importDataToDatabase(importData) {
  // ... existing code ...
  
  // For card import:
  let cardImageUrl = null;
  let cardOriginalImageUrl = null;
  let cardCropParams = null;
  
  if (importData.images && importData.images.has('card_image')) {
    const cardImages = importData.images.get('card_image');
    if (cardImages && cardImages.length > 0) {
      const originalImageFile = cardImages[0];
      
      // Parse crop parameters
      const cropParamsJson = importData.cardData.crop_parameters_json;
      const parsedCropParams = parseCropParameters(cropParamsJson);
      
      if (parsedCropParams) {
        // Has crop parameters - generate cropped image
        try {
          const croppedImageFile = await applyCropParametersToImage(
            originalImageFile,
            parsedCropParams,
            2/3 // Card aspect ratio
          );
          
          // Upload both images
          cardOriginalImageUrl = await uploadImageToSupabase(originalImageFile, 'card-images');
          cardImageUrl = await uploadImageToSupabase(croppedImageFile, 'card-images');
          cardCropParams = parsedCropParams;
          results.imagesProcessed += 2;
        } catch (error) {
          results.errors.push(`Failed to apply crop: ${error.message}`);
          // Fallback: use original as both
          cardImageUrl = await uploadImageToSupabase(originalImageFile, 'card-images');
          cardOriginalImageUrl = cardImageUrl;
        }
      } else {
        // No crop parameters - use original for both
        cardImageUrl = await uploadImageToSupabase(originalImageFile, 'card-images');
        cardOriginalImageUrl = cardImageUrl;
      }
    }
  }
  
  // Create card with proper parameters
  const { data, error } = await supabase.rpc('create_card', {
    p_name: importData.cardData.name,
    p_description: importData.cardData.description,
    p_ai_instruction: importData.cardData.ai_instruction || '',
    p_ai_knowledge_base: importData.cardData.ai_knowledge_base || '',
    p_conversation_ai_enabled: importData.cardData.conversation_ai_enabled,
    p_qr_code_position: qrPosition,
    p_image_url: cardImageUrl,
    p_original_image_url: cardOriginalImageUrl,
    p_crop_parameters: cardCropParams
  });
  
  // Similar logic for content items...
}
```

## 🎯 NEXT STEPS

1. Implement the import logic update in CardBulkImport.vue
2. Add error handling and fallbacks
3. Test with real Excel files
4. Update user documentation

## ⚠️ IMPORTANT NOTES

- Crop parameters must be valid JSON
- If crop fails, fallback to using original as both images
- Aspect ratio for cards: 2/3
- Aspect ratio for content items: Check cardConfig.ts
- User sees uncropped images in Excel (by design)
- Import regenerates cropped images (slower but full fidelity)
