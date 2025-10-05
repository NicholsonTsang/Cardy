# AI Metadata to Instruction & Knowledge Base Migration

## Overview

This document describes the comprehensive update that replaced the single `ai_prompt` field in the cards table with two distinct fields: `ai_instruction` and `ai_knowledge_base`, along with replacing `ai_metadata` in content items with a more structured approach.

## Changes Summary

### Database Schema Changes

**Cards Table (`sql/schema.sql`)**
- **Removed**: `ai_prompt TEXT DEFAULT '' NOT NULL`
- **Added**:
  - `ai_instruction TEXT DEFAULT '' NOT NULL` - AI role and guidelines (max 100 words)
  - `ai_knowledge_base TEXT DEFAULT '' NOT NULL` - Background knowledge for AI conversations (max 2000 words)

### Stored Procedures Updated

**1. Client-Side Card Management (`sql/storeproc/client-side/02_card_management.sql`)**
- `get_user_cards()` - Now returns `ai_instruction` and `ai_knowledge_base`
- `create_card()` - Accepts `p_ai_instruction` and `p_ai_knowledge_base` parameters
- `get_card_by_id()` - Returns both new fields
- `update_card()` - Updates both fields with change tracking in audit logs
- `delete_card()` - Logs both fields in deletion audit

**2. Public Access (`sql/storeproc/client-side/07_public_access.sql`)**
- `get_public_card_content()` - Returns `card_ai_instruction` and `card_ai_knowledge_base`
- `get_card_preview_content()` - Returns both fields for preview mode

**3. Admin Functions (`sql/storeproc/client-side/11_admin_functions.sql`)**
- `admin_get_user_cards()` - Returns both new fields for admin viewing

### Frontend TypeScript Interfaces

**Card Interfaces (`src/stores/card.ts`)**
```typescript
export interface Card {
  // ... other fields
  ai_instruction: string; // AI role and guidelines (max 100 words)
  ai_knowledge_base: string; // Background knowledge for AI (max 2000 words)
}

export interface CardFormData {
  // ... other fields
  ai_instruction: string;
  ai_knowledge_base: string;
}
```

**Public Card Interfaces (`src/stores/publicCard.ts`)**
```typescript
export interface PublicCardData {
  // ... other fields
  card_ai_instruction: string;
  card_ai_knowledge_base: string;
}
```

**AI Assistant Types (`src/views/MobileClient/components/AIAssistant/types/index.ts`)**
```typescript
export interface CardData {
  card_name: string;
  card_description: string;
  ai_instruction?: string;
  ai_knowledge_base?: string;
}
```

### UI Components Updated

**1. Card Create/Edit Form (`src/components/CardComponents/CardCreateEditForm.vue`)**

**New Features:**
- Two separate fields for AI configuration:
  - **AI Instruction** (Role & Guidelines) - Max 100 words
  - **AI Knowledge Base** - Max 2000 words
- Real-time word count display for each field
- Visual feedback when word limits are exceeded (red border)
- Color-coded sections (blue for instruction, amber for knowledge base)
- Helpful tooltips and purpose descriptions

**UI Structure:**
```vue
<!-- AI Instruction (Role & Guidelines) -->
<div class="bg-gradient-to-r from-blue-50 to-indigo-50 border border-blue-200 rounded-lg p-4">
  <label class="flex items-center gap-2">
    <i class="pi pi-user"></i>
    AI Instruction (Role & Guidelines)
    <span class="text-xs text-blue-600 ml-auto">{{ aiInstructionWordCount }}/100 words</span>
  </label>
  <Textarea v-model="formData.ai_instruction" :class="{ 'border-red-500': aiInstructionWordCount > 100 }" />
</div>

<!-- AI Knowledge Base -->
<div class="bg-gradient-to-r from-amber-50 to-orange-50 border border-amber-200 rounded-lg p-4">
  <label class="flex items-center gap-2">
    <i class="pi pi-database"></i>
    AI Knowledge Base
    <span class="text-xs text-amber-600 ml-auto">{{ aiKnowledgeBaseWordCount }}/2000 words</span>
  </label>
  <Textarea v-model="formData.ai_knowledge_base" :class="{ 'border-red-500': aiKnowledgeBaseWordCount > 2000 }" />
</div>
```

**2. Admin Card Views**

**AdminCardGeneral.vue:**
- Displays AI Instruction with blue-themed styling
- Displays AI Knowledge Base with amber-themed styling (scrollable for long content)
- Includes appropriate icons for visual distinction

**AdminCardDetailPanel.vue:**
- Updated interface to include both new fields

**3. Mobile AI Assistant (`src/views/MobileClient/components/MobileAIAssistant.vue`)**

**Updated System Instructions:**
```typescript
const systemInstructions = computed(() => {
  let instructions = `Base content details...`
  
  // Add content item specific knowledge (ai_metadata)
  if (props.aiMetadata) {
    instructions += `\n\nAdditional Content Knowledge:\n${props.aiMetadata}`
  }
  
  // Add card-level instruction (role & guidelines)
  if (props.cardData.ai_instruction) {
    instructions += `\n\nAI Role & Guidelines:\n${props.cardData.ai_instruction}`
  }
  
  // Add card-level knowledge base (background knowledge)
  if (props.cardData.ai_knowledge_base) {
    instructions += `\n\nBackground Knowledge:\n${props.cardData.ai_knowledge_base}`
  }
  
  // Add communication guidelines
  instructions += `\n\nCommunication Guidelines...`
  
  return instructions
})
```

## Field Purposes & Usage Guidelines

### AI Instruction (100 words max)
**Purpose:** Define the AI's role, personality, tone, and restrictions

**Examples:**
- "You are a knowledgeable museum curator. Provide educational explanations in a friendly, conversational tone. Keep responses concise."
- "You are an expert travel guide. Help visitors plan their adventures and understand safety requirements."
- "You are a helpful art gallery assistant. Explain artworks using accessible language. Encourage curiosity and deeper appreciation."

**Best Practices:**
- Keep it concise and focused
- Define the AI's role clearly
- Specify desired tone and personality
- Include any important restrictions or guidelines

### AI Knowledge Base (2000 words max)
**Purpose:** Supply detailed domain knowledge, facts, specifications, or context

**Examples:**
- Historical context and timeline of events
- Technical specifications and features
- Detailed background information
- Facts, figures, and research data
- Cultural or artistic significance
- Expert domain knowledge

**Best Practices:**
- Be comprehensive and detailed
- Include factual information
- Provide context and background
- Add relevant specifications or data
- Include multiple aspects of the subject

### Content Item AI Metadata (unchanged)
**Purpose:** Provide supplemental information specific to individual content items

**Usage:**
- Keywords and topics related to the specific item
- Additional facts about this particular exhibit/artifact
- Contextual information for this content piece

## Database Deployment

### Step 1: Update Schema
```bash
# Manually execute in Supabase SQL Editor:
# 1. Open sql/schema.sql
# 2. Copy the cards table definition
# 3. Execute: DROP TABLE IF EXISTS cards CASCADE;
# 4. Execute the CREATE TABLE statement with new fields
```

### Step 2: Deploy Stored Procedures
```bash
# The all_stored_procedures.sql has been regenerated
# Manually execute in Supabase SQL Editor:
# 1. Open sql/all_stored_procedures.sql
# 2. Copy all contents
# 3. Execute in SQL Editor
```

### Migration Notes
- Existing `ai_prompt` data will be lost during schema update
- Consider exporting existing data before migration if needed
- Test in development environment first
- Update environment-specific configurations

## Word Count Implementation

**Client-Side Validation:**
```typescript
const aiInstructionWordCount = computed(() => {
  return formData.ai_instruction.trim().split(/\s+/).filter(word => word.length > 0).length;
});

const aiKnowledgeBaseWordCount = computed(() => {
  return formData.ai_knowledge_base.trim().split(/\s+/).filter(word => word.length > 0).length;
});
```

**Visual Feedback:**
- Word count displayed next to field labels
- Red border when limit exceeded
- No hard validation block (soft limit guidance)

## Benefits of This Approach

1. **Clear Separation of Concerns**
   - Instructions define HOW the AI should behave
   - Knowledge base defines WHAT the AI knows

2. **Better Organization**
   - Easier to manage and update each aspect independently
   - Clear purpose for each field

3. **Improved AI Performance**
   - Structured instructions lead to more consistent AI behavior
   - Comprehensive knowledge base enables more accurate responses

4. **Enhanced User Experience**
   - Clear guidance on what to enter in each field
   - Word limits prevent overly long configurations
   - Visual feedback helps users stay within limits

5. **Scalability**
   - Easier to extend with additional AI configuration options
   - Clearer structure for future enhancements

## Testing Checklist

- [ ] Create new card with AI enabled
- [ ] Verify word count updates in real-time
- [ ] Test word limit visual feedback (red borders)
- [ ] Update existing card with new AI fields
- [ ] Verify mobile AI assistant receives correct instructions
- [ ] Test admin view displays both fields correctly
- [ ] Verify public card access includes new fields
- [ ] Test card preview mode with AI enabled
- [ ] Validate stored procedures return correct data
- [ ] Check audit logs include new field changes

## Files Modified

### Database
- `sql/schema.sql`
- `sql/storeproc/client-side/02_card_management.sql`
- `sql/storeproc/client-side/07_public_access.sql`
- `sql/storeproc/client-side/11_admin_functions.sql`
- `sql/all_stored_procedures.sql` (regenerated)

### Frontend Stores
- `src/stores/card.ts`
- `src/stores/publicCard.ts`

### Components
- `src/components/CardComponents/CardCreateEditForm.vue`
- `src/components/Admin/AdminCardGeneral.vue`
- `src/components/Admin/AdminCardDetailPanel.vue`

### Mobile Client
- `src/views/MobileClient/components/MobileAIAssistant.vue`
- `src/views/MobileClient/components/AIAssistant/types/index.ts`

## Backward Compatibility

⚠️ **Breaking Change**: This is a breaking change that requires database schema update.

**Migration Path:**
1. Export existing `ai_prompt` data if needed
2. Update database schema
3. Deploy updated stored procedures
4. Deploy frontend updates
5. Manually migrate/re-enter AI configuration for existing cards

## Related Documentation

- See `CLAUDE.md` for overall project architecture
- See `DUAL_IMAGE_STORAGE_FRONTEND_GUIDE.md` for image handling
- See `EDGE_FUNCTIONS_CONFIG.md` for AI integration details

