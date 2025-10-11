# Frontend-Backend Alignment Check

## Issue Reported
Error when saving card: "Card not found or not authorized to update."

## Root Cause Analysis

The error occurs at line 162 of `update_card` stored procedure:
```sql
IF NOT FOUND THEN
    RAISE EXCEPTION 'Card not found or not authorized to update.';
END IF;
```

This suggests one of two issues:
1. **Database schema not deployed** - The `cards` table doesn't have the new `ai_instruction` and `ai_knowledge_base` columns
2. **Authorization issue** - The user_id check is failing

## Verification Checklist

### 1. Database Schema Verification

**Check if columns exist in `cards` table:**
```sql
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'cards' 
AND column_name IN ('ai_instruction', 'ai_knowledge_base', 'ai_prompt');
```

**Expected Result:**
- `ai_instruction` (TEXT) - should exist
- `ai_knowledge_base` (TEXT) - should exist  
- `ai_prompt` (TEXT) - should NOT exist (removed)

### 2. Stored Procedures Verification

**Check if `update_card` function has correct signature:**
```sql
SELECT routine_name, parameter_name, data_type
FROM information_schema.parameters
WHERE routine_name = 'update_card'
ORDER BY ordinal_position;
```

**Expected Parameters:**
- p_card_id (UUID)
- p_name (TEXT)
- p_description (TEXT)
- p_image_url (TEXT)
- p_original_image_url (TEXT)
- p_crop_parameters (JSONB)
- p_conversation_ai_enabled (BOOLEAN)
- p_ai_instruction (TEXT) ← NEW
- p_ai_knowledge_base (TEXT) ← NEW
- p_qr_code_position (TEXT)

### 3. Frontend Payload Verification

**Card Store (`src/stores/card.ts`) - updateCard function:**
```typescript
const payload = {
    p_card_id: cardId,
    p_name: updateData.name,
    p_description: updateData.description,
    p_image_url: croppedImageUrl || null,
    p_original_image_url: originalImageUrl || null,
    p_crop_parameters: updateData.cropParameters || null,
    p_conversation_ai_enabled: updateData.conversation_ai_enabled,
    p_ai_instruction: updateData.ai_instruction,  ← NEW
    p_ai_knowledge_base: updateData.ai_knowledge_base,  ← NEW
    p_qr_code_position: updateData.qr_code_position
};
```

**Form Data (`src/components/CardComponents/CardCreateEditForm.vue`):**
```typescript
const formData = reactive({
    id: null,
    name: '',
    description: '',
    qr_code_position: 'BR',
    ai_instruction: '',  ← NEW
    ai_knowledge_base: '',  ← NEW
    conversation_ai_enabled: false,
    cropParameters: null
});
```

## Deployment Steps Required

### Step 1: Deploy Schema Changes
```bash
# Execute in Supabase SQL Editor
# File: sql/schema.sql (lines 58-70 for cards table)
```

**Cards table should have:**
```sql
CREATE TABLE cards (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    name TEXT NOT NULL,
    description TEXT DEFAULT '' NOT NULL,
    qr_code_position "QRCodePosition" DEFAULT 'BR',
    image_url TEXT,
    original_image_url TEXT,
    crop_parameters JSONB,
    conversation_ai_enabled BOOLEAN DEFAULT false,
    ai_instruction TEXT DEFAULT '' NOT NULL,  ← NEW
    ai_knowledge_base TEXT DEFAULT '' NOT NULL,  ← NEW
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

**Content items table should have:**
```sql
CREATE TABLE content_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    card_id UUID NOT NULL REFERENCES cards(id) ON DELETE CASCADE,
    parent_id UUID REFERENCES content_items(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    content TEXT DEFAULT '' NOT NULL,
    image_url TEXT,
    original_image_url TEXT,
    crop_parameters JSONB,
    ai_knowledge_base TEXT DEFAULT '' NOT NULL,  ← NEW (was ai_metadata)
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT content_items_parent_not_self CHECK (parent_id != id)
);
```

### Step 2: Deploy Stored Procedures
```bash
# Execute in Supabase SQL Editor
# File: sql/all_stored_procedures.sql
```

This includes:
- `get_user_cards()` - updated to return new fields
- `create_card()` - updated to accept new parameters
- `get_card_by_id()` - updated to return new fields
- `update_card()` - updated to accept and process new parameters
- `delete_card()` - updated logging
- `get_card_content_items()` - updated for content items
- `create_content_item()` - updated for content items
- `update_content_item()` - updated for content items
- `get_public_card_content()` - updated for mobile client
- `get_card_preview_content()` - updated for preview mode
- `admin_get_user_cards()` - updated for admin views
- `admin_get_card_content()` - updated for admin views

### Step 3: Verify Deployment

**Test Query 1: Check card schema**
```sql
SELECT 
    id, 
    name, 
    ai_instruction, 
    ai_knowledge_base,
    conversation_ai_enabled
FROM cards 
LIMIT 1;
```

**Test Query 2: Check content items schema**
```sql
SELECT 
    id, 
    name, 
    ai_knowledge_base
FROM content_items 
LIMIT 1;
```

**Test Query 3: Try updating a card**
```sql
SELECT update_card(
    p_card_id := 'your-card-id-here',
    p_name := 'Test Update',
    p_ai_instruction := 'Test instruction',
    p_ai_knowledge_base := 'Test knowledge'
);
```

## Frontend Components Alignment

### ✅ Already Updated Components

**Card Management:**
- ✅ `src/stores/card.ts` - Card and CardFormData interfaces
- ✅ `src/stores/card.ts` - createCard() function
- ✅ `src/stores/card.ts` - updateCard() function
- ✅ `src/components/CardComponents/CardCreateEditForm.vue` - Form fields and validation

**Content Item Management:**
- ✅ `src/stores/contentItem.ts` - ContentItem and ContentItemFormData interfaces
- ✅ `src/stores/contentItem.ts` - createContentItem() function
- ✅ `src/stores/contentItem.ts` - updateContentItem() function
- ✅ `src/components/CardContent/CardContentCreateEditForm.vue` - Form fields and validation

**Mobile Client:**
- ✅ `src/stores/publicCard.ts` - PublicCardData and PublicContentItem interfaces
- ✅ `src/views/MobileClient/PublicCardView.vue` - Field mappings
- ✅ `src/views/MobileClient/components/ContentDetail.vue` - Props and interfaces
- ✅ `src/views/MobileClient/components/MobileAIAssistant.vue` - System instructions
- ✅ `src/views/MobileClient/components/AIAssistant/types/index.ts` - Type definitions

**Admin Views:**
- ✅ `src/components/Admin/AdminCardGeneral.vue` - Display fields
- ✅ `src/components/Admin/AdminCardDetailPanel.vue` - Interface definitions
- ✅ `src/components/Admin/AdminCardContent.vue` - ContentItem interface and display

**Environment Configuration:**
- ✅ `.env` - VITE_DEFAULT_AI_INSTRUCTION added
- ✅ `.env.production` - VITE_DEFAULT_AI_INSTRUCTION added

## Migration Impact

### Breaking Changes
1. **Cards table:**
   - Removed: `ai_prompt`
   - Added: `ai_instruction`, `ai_knowledge_base`

2. **Content items table:**
   - Removed: `ai_metadata`
   - Added: `ai_knowledge_base`

### Data Migration Required
⚠️ **Existing data will be lost unless migrated:**

**Option 1: Manual Migration (Recommended for small datasets)**
```sql
-- Backup existing data
CREATE TEMP TABLE cards_backup AS SELECT * FROM cards;
CREATE TEMP TABLE content_items_backup AS SELECT * FROM content_items;

-- After schema update, manually re-enter AI configurations
```

**Option 2: Migration Script (For larger datasets)**
```sql
-- If you want to preserve ai_prompt as ai_instruction:
-- (Run BEFORE schema update)

-- 1. Add new columns temporarily
ALTER TABLE cards ADD COLUMN ai_instruction_temp TEXT;
ALTER TABLE cards ADD COLUMN ai_knowledge_base_temp TEXT;

-- 2. Copy data
UPDATE cards SET ai_instruction_temp = ai_prompt WHERE ai_prompt IS NOT NULL;

-- 3. Drop old column
ALTER TABLE cards DROP COLUMN ai_prompt;

-- 4. Rename temp columns
ALTER TABLE cards RENAME COLUMN ai_instruction_temp TO ai_instruction;
ALTER TABLE cards RENAME COLUMN ai_knowledge_base_temp TO ai_knowledge_base;

-- Similar process for content_items
ALTER TABLE content_items ADD COLUMN ai_knowledge_base_temp TEXT;
UPDATE content_items SET ai_knowledge_base_temp = ai_metadata WHERE ai_metadata IS NOT NULL;
ALTER TABLE content_items DROP COLUMN ai_metadata;
ALTER TABLE content_items RENAME COLUMN ai_knowledge_base_temp TO ai_knowledge_base;
```

## Quick Fix Commands

```bash
# 1. Open Supabase Dashboard
# 2. Go to SQL Editor
# 3. Execute schema.sql (cards and content_items table sections)
# 4. Execute all_stored_procedures.sql
# 5. Verify with test queries above
# 6. Clear browser cache and reload frontend
```

## Summary

The error "Card not found or not authorized to update" is most likely caused by:

**🎯 Root Cause:** Database schema has not been updated with the new column names.

**✅ Solution:** 
1. Deploy `sql/schema.sql` to update table structures
2. Deploy `sql/all_stored_procedures.sql` to update functions
3. Verify deployment with test queries
4. Frontend is already aligned and ready to use the new structure

**📝 Note:** All frontend code is already updated and aligned with the new schema. The issue is purely on the database side.

