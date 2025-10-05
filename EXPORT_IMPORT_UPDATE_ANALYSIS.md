# Card Export/Import Update Analysis

## Current Schema vs Implementation Gap

### Cards Table Schema (Current):
```sql
- id UUID
- user_id UUID
- name TEXT
- description TEXT
- qr_code_position "QRCodePosition"
- image_url TEXT                    -- Cropped/processed image
- original_image_url TEXT           -- **NEW** Original uploaded image
- crop_parameters JSONB             -- **NEW** Crop parameters
- conversation_ai_enabled BOOLEAN
- ai_instruction TEXT               -- **CHANGED** from ai_prompt (max 100 words)
- ai_knowledge_base TEXT            -- **NEW** (max 2000 words)
```

### Content Items Table Schema (Current):
```sql
- id UUID
- card_id UUID
- parent_id UUID
- name TEXT
- content TEXT (description/markdown)
- image_url TEXT                    -- Cropped/processed image
- original_image_url TEXT           -- **NEW** Original uploaded image
- crop_parameters JSONB             -- **NEW** Crop parameters
- ai_knowledge_base TEXT            -- **CHANGED** from ai_metadata (max 500 words)
- sort_order INTEGER
```

## Issues Found

### 1. Excel Export (excelHandler.js)
**STATUS**: ✅ Already Updated Correctly
- ✅ Exports `ai_instruction` (not ai_prompt)
- ✅ Exports `ai_knowledge_base`
- ❌ Does NOT export `original_image_url` or `crop_parameters`
- ❌ Only exports single `image_url`

### 2. Excel Import (CardBulkImport.vue)
**STATUS**: ⚠️ Partially Correct, Missing Fields
- ✅ Uses `p_ai_instruction` parameter
- ✅ Uses `p_ai_knowledge_base` parameter
- ❌ Only passes `p_image_url` (single image)
- ❌ Does NOT pass `p_original_image_url`
- ❌ Does NOT pass `p_crop_parameters`

### 3. Validation (excelValidation.js)
**STATUS**: ⚠️ Needs Updates
- ❌ Still references `ai_metadata` in cleanContentData()
- ❌ AI instruction validation checks length, not word count
- ❌ AI knowledge base has character limit, should be word limit
- ✅ Field names in validateCardData() are correct

### 4. RPC Calls (create_card, create_content_item)
**STATUS**: Need to verify stored procedures support new fields
- Need to check if stored procedures accept:
  - `p_original_image_url`
  - `p_crop_parameters`

## Required Updates

### Priority 1: Critical (Breaks Functionality)
1. Update `excelValidation.js`:
   - Change `ai_metadata` to `ai_knowledge_base` in `cleanContentData()`
   - Fix AI instruction validation (100 words, not 100 chars)
   - Fix AI knowledge base validation (2000 words for cards, 500 words for content)

2. Verify stored procedures support new parameters
   
### Priority 2: Important (Missing Features)
3. Update CardBulkImport.vue to handle dual image storage:
   - For now, use uploaded image as BOTH original and cropped
   - Pass `p_original_image_url` = same as `p_image_url`
   - Pass `p_crop_parameters` = null (no cropping on import)

4. Document limitation:
   - Excel import does NOT preserve crop parameters
   - All imported images are treated as uncropped
   - Users must re-crop after import if needed

### Priority 3: Nice-to-Have (Future Enhancement)
5. Consider adding crop_parameters to Excel export (as JSON string)
6. Consider allowing crop_parameters in Excel import

## Implementation Notes

### Image Handling Strategy for Import:
Since Excel doesn't support crop parameters, we'll:
1. Upload image once
2. Set `original_image_url` = uploaded URL
3. Set `image_url` = same URL (no cropping)
4. Set `crop_parameters` = null
5. User can manually crop after import

### Validation Word Count vs Character Count:
- AI Instruction: 100 WORDS (not characters)
- AI Knowledge Base (Card): 2000 WORDS (not characters) 
- AI Knowledge Base (Content): 500 WORDS (not characters)

Current validation incorrectly checks character length!
