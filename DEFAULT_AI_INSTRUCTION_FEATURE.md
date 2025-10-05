# Default AI Instruction Feature

## Overview
Added a configurable default AI instruction template that auto-populates when users enable AI assistance for their cards.

## Implementation

### 1. Environment Configuration

**Files Updated:**
- `.env`
- `.env.production`

**New Environment Variable:**
```bash
VITE_DEFAULT_AI_INSTRUCTION="You are a knowledgeable and friendly AI assistant for museum and exhibition visitors. Provide accurate, engaging, and educational explanations about exhibits and artifacts. Keep responses conversational and easy to understand. If you don't know something, politely say so rather than making up information."
```

### 2. Frontend Integration

**File:** `src/components/CardComponents/CardCreateEditForm.vue`

**Features Implemented:**
1. **Default Instruction Constant**: Reads from `VITE_DEFAULT_AI_INSTRUCTION` environment variable
2. **Auto-Population**: When AI is enabled (checkbox toggled on), automatically fills the instruction field with the default template if the field is empty
3. **Placeholder Text**: Shows "Recommended: [default instruction]" as placeholder text
4. **Smart Behavior**: Only populates when:
   - AI is being enabled (not disabled)
   - The instruction field is empty (doesn't overwrite existing content)

### 3. User Experience

**Workflow:**
1. User creates a new card
2. User enables "AI Assistance" checkbox
3. AI Instruction field automatically populates with recommended template
4. User can:
   - Keep the recommended template as-is
   - Edit/customize the template
   - Clear and write their own from scratch

**Benefits:**
- Provides guidance for users unfamiliar with prompt engineering
- Ensures consistent, high-quality AI behavior across cards
- Saves time for users who want to use best practices
- Easy to customize the default via environment variables

### 4. Customization

**For Deployment Environments:**

You can customize the default instruction for different environments:

```bash
# Development (.env)
VITE_DEFAULT_AI_INSTRUCTION="You are a friendly AI assistant..."

# Production (.env.production)
VITE_DEFAULT_AI_INSTRUCTION="You are a professional AI curator..."
```

**For Different Use Cases:**

Update the environment variable to match your specific domain:

```bash
# For Art Museums
VITE_DEFAULT_AI_INSTRUCTION="You are an expert art historian and curator..."

# For Science Museums
VITE_DEFAULT_AI_INSTRUCTION="You are a knowledgeable science educator..."

# For Historical Sites
VITE_DEFAULT_AI_INSTRUCTION="You are a passionate historian and tour guide..."
```

## Technical Details

### Code Implementation

```typescript
// Get default AI instruction from environment
const DEFAULT_AI_INSTRUCTION = import.meta.env.VITE_DEFAULT_AI_INSTRUCTION || 
  "You are a knowledgeable and friendly AI assistant...";

// Watch for AI being enabled - populate default instruction if empty
watch(() => formData.conversation_ai_enabled, (newValue, oldValue) => {
  if (newValue && !oldValue && !formData.ai_instruction.trim()) {
    formData.ai_instruction = DEFAULT_AI_INSTRUCTION;
  }
});
```

### Placeholder Implementation

```vue
<Textarea 
  v-model="formData.ai_instruction"
  :placeholder="'Recommended: ' + DEFAULT_AI_INSTRUCTION"
  ...
/>
```

## Testing Checklist

- [x] Environment variable loads correctly
- [x] Default instruction populates when AI is enabled
- [x] Placeholder shows recommended instruction
- [x] Doesn't overwrite existing instructions when editing a card
- [x] User can clear and write custom instructions
- [x] Word count validation still works (100 words max)

## Deployment Notes

1. **Environment Variables**: Ensure `VITE_DEFAULT_AI_INSTRUCTION` is set in both development and production environments
2. **Fallback**: If the environment variable is not set, the component has a hardcoded fallback
3. **Character Encoding**: The quotes in the .env file should handle special characters properly
4. **Restart Required**: After changing `.env` files, restart the dev server for changes to take effect

## Future Enhancements

Potential improvements:
1. Add multiple templates for different card types (museums, galleries, landmarks, etc.)
2. Allow administrators to customize default templates via admin panel
3. Provide template library with examples for various use cases
4. Add "Reset to default" button to restore the recommended instruction
5. Show word count for the default template in the UI

## Related Files

- `.env` - Development environment configuration
- `.env.production` - Production environment configuration
- `src/components/CardComponents/CardCreateEditForm.vue` - Card creation/edit form
- `CLAUDE.md` - Updated to document this feature
