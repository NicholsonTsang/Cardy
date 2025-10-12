# Multi-Language Translation Feature - Design Document

## Overview
Enable card issuers to translate their card content into any of the 10 supported languages with one-click AI-powered translation, charged at 1 credit per language per card.

## Current State
- **Content Input**: Single language (user's input language)
- **Mobile Language Selection**: Visitors can select from 10 languages, but content remains in original language
- **Supported Languages**: en, zh-Hant, zh-Hans, ja, ko, es, fr, ru, ar, th

## Requirements
1. One-click translation to selected languages
2. Cost: 1 credit per language per card
3. Handle translation staleness (original content updated but translations not synced)
4. Seamless UX integration with existing dashboard
5. Automatic display of translated content on mobile client

---

## 1. UX/UI Design

### 1.1 New "Translations" Tab in MyCards

**Location**: Add 5th tab after "Details", "Content", "Issue", "Access"

**Layout**:
```
┌─────────────────────────────────────────────────────────┐
│  Translations Tab                                       │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  Original Language: [English (Auto-detected)]          │
│                                                         │
│  ┌────────────────────────────────────────────────┐   │
│  │  Translation Status                            │   │
│  ├────────────────────────────────────────────────┤   │
│  │  Language    Status        Last Updated  Action│   │
│  │  ────────────────────────────────────────────  │   │
│  │  🇬🇧 English   Original      -           -     │   │
│  │  🇨🇳 简体中文   ✓ Up to date  2 hrs ago   🔄    │   │
│  │  🇹🇼 繁體中文   ⚠ Outdated    1 day ago   🔄    │   │
│  │  🇯🇵 日本語    - Not translated  -         ➕    │   │
│  │  🇰🇷 한국어     - Not translated  -         ➕    │   │
│  │  ... (more languages)                          │   │
│  └────────────────────────────────────────────────┘   │
│                                                         │
│  [Translate to New Languages] [Update Outdated (2)]   │
│                                                         │
│  Content Summary:                                      │
│  • Card: name, description (2 fields)                 │
│  • Content Items: 5 items × 3 fields = 15 fields     │
│  • Total: 17 translatable fields                      │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

**Status Indicators**:
- ✓ **Up to date** (green): Translation is current
- ⚠ **Outdated** (yellow): Original content changed since last translation
- ➕ **Not translated** (gray): Language not yet translated

**Actions**:
- 🔄 **Update**: Re-translate this specific language
- ➕ **Translate**: Translate to this language for the first time

### 1.2 Translation Dialog Flow

#### Step 1: Select Languages Dialog
```
┌─────────────────────────────────────────────────────────┐
│  Translate Card Content                          [×]    │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  Select target languages for translation:              │
│                                                         │
│  ☐ Select All    ☐ Select Popular (中文,日本語,한국어) │
│                                                         │
│  ☑ 简体中文 (Simplified Chinese)                       │
│  ☑ 繁體中文 (Traditional Chinese)                      │
│  ☑ 日本語 (Japanese)                                   │
│  ☐ 한국어 (Korean)                                     │
│  ☐ Español (Spanish)                                   │
│  ☐ Français (French)                                   │
│  ☐ Русский (Russian)                                   │
│  ☐ العربية (Arabic)                                    │
│  ☐ ไทย (Thai)                                          │
│                                                         │
│  ─────────────────────────────────────────────────────  │
│                                                         │
│  Translation Preview:                                  │
│  • Card name and description                           │
│  • 5 content items (names, descriptions, content)      │
│                                                         │
│  Cost Calculation:                                     │
│  3 languages × 1 credit = 3 credits                   │
│  Current balance: 50 credits                           │
│  After translation: 47 credits                         │
│                                                         │
│  ⚠ Note: This will use GPT-4 for high-quality         │
│     context-aware translation.                         │
│                                                         │
│            [Cancel]  [Translate (3 credits)]           │
└─────────────────────────────────────────────────────────┘
```

#### Step 2: Translation Progress
```
┌─────────────────────────────────────────────────────────┐
│  Translating Content...                          [×]    │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ⏳ Translating card content to 3 languages...         │
│                                                         │
│  Progress:                                             │
│  ✓ 简体中文 (Simplified Chinese) - Complete            │
│  ⏳ 繁體中文 (Traditional Chinese) - Translating...    │
│  ⏸ 日本語 (Japanese) - Pending                         │
│                                                         │
│  [████████░░░░░░] 60%                                  │
│                                                         │
│  Estimated time remaining: 30 seconds                  │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

#### Step 3: Success Confirmation
```
┌─────────────────────────────────────────────────────────┐
│  Translation Complete!                           [×]    │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ✓ Successfully translated to 3 languages              │
│                                                         │
│  Translated Languages:                                 │
│  • 简体中文 (Simplified Chinese)                       │
│  • 繁體中文 (Traditional Chinese)                      │
│  • 日本語 (Japanese)                                   │
│                                                         │
│  Credits Used: 3                                       │
│  Remaining Balance: 47 credits                         │
│                                                         │
│  Your card content is now available in these languages │
│  for all visitors!                                     │
│                                                         │
│  [Preview Translations]  [Done]                        │
└─────────────────────────────────────────────────────────┘
```

### 1.3 Outdated Translation Warning

When editing card/content in Details or Content tabs:
```
┌─────────────────────────────────────────────────────────┐
│  ⚠ Translation Update Notice                           │
├─────────────────────────────────────────────────────────┤
│  You have modified the original content. The following │
│  translations are now outdated:                        │
│  • 简体中文, 繁體中文, 日本語 (3 languages)             │
│                                                         │
│  [Update Translations Now (3 credits)]  [Later]        │
└─────────────────────────────────────────────────────────┘
```

### 1.4 Mobile Client - Language Selector Enhancement

**Current**: Language selector in mobile header
**Enhancement**: Show availability indicator
```
Language Selector:
  🇬🇧 English (Original)
  🇨🇳 简体中文 ✓ (Translated available)
  🇹🇼 繁體中文 ✓ (Translated available)
  🇯🇵 日本語 (Auto-translate) ← Falls back to on-the-fly translation
```

---

## 2. Database Schema Design

### 2.1 Schema Changes

#### Add to `cards` table:
```sql
ALTER TABLE cards ADD COLUMN IF NOT EXISTS translations JSONB DEFAULT '{}';
ALTER TABLE cards ADD COLUMN IF NOT EXISTS original_language VARCHAR(10) DEFAULT 'en';
ALTER TABLE cards ADD COLUMN IF NOT EXISTS content_hash TEXT; -- MD5 of original content
ALTER TABLE cards ADD COLUMN IF NOT EXISTS last_content_update TIMESTAMPTZ DEFAULT NOW();

-- Translation structure in JSONB:
{
  "zh-Hans": {
    "name": "博物馆卡片",
    "description": "欢迎来到博物馆...",
    "translated_at": "2025-10-11T10:30:00Z",
    "content_hash": "abc123..." -- Hash when translated
  },
  "zh-Hant": { ... },
  "ja": { ... }
}
```

#### Add to `content_items` table:
```sql
ALTER TABLE content_items ADD COLUMN IF NOT EXISTS translations JSONB DEFAULT '{}';
ALTER TABLE content_items ADD COLUMN IF NOT EXISTS content_hash TEXT;
ALTER TABLE content_items ADD COLUMN IF NOT EXISTS last_content_update TIMESTAMPTZ DEFAULT NOW();

-- Translation structure:
{
  "zh-Hans": {
    "name": "文物名称",
    "description": "文物描述",
    "content": "详细内容markdown",
    "translated_at": "2025-10-11T10:30:00Z",
    "content_hash": "def456..."
  }
}
```

#### New table: `translation_history`
```sql
CREATE TABLE translation_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  card_id UUID NOT NULL REFERENCES cards(id) ON DELETE CASCADE,
  languages TEXT[] NOT NULL, -- Array of language codes translated
  credit_cost INTEGER NOT NULL,
  translated_by UUID REFERENCES auth.users(id),
  translated_at TIMESTAMPTZ DEFAULT NOW(),
  status VARCHAR(20) DEFAULT 'completed' -- completed, failed, partial
);
```

### 2.2 Triggers for Content Change Detection

```sql
-- Auto-update content_hash and last_content_update on cards
CREATE OR REPLACE FUNCTION update_card_content_hash()
RETURNS TRIGGER AS $$
BEGIN
  -- Only update if name or description changed
  IF (NEW.name IS DISTINCT FROM OLD.name) OR 
     (NEW.description IS DISTINCT FROM OLD.description) THEN
    NEW.content_hash := md5(COALESCE(NEW.name, '') || COALESCE(NEW.description, ''));
    NEW.last_content_update := NOW();
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_card_content_hash
  BEFORE UPDATE ON cards
  FOR EACH ROW
  EXECUTE FUNCTION update_card_content_hash();

-- Similar trigger for content_items
CREATE OR REPLACE FUNCTION update_content_item_content_hash()
RETURNS TRIGGER AS $$
BEGIN
  IF (NEW.name IS DISTINCT FROM OLD.name) OR 
     (NEW.description IS DISTINCT FROM OLD.description) OR
     (NEW.content IS DISTINCT FROM OLD.content) THEN
    NEW.content_hash := md5(
      COALESCE(NEW.name, '') || 
      COALESCE(NEW.description, '') || 
      COALESCE(NEW.content, '')
    );
    NEW.last_content_update := NOW();
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_content_item_content_hash
  BEFORE UPDATE ON content_items
  FOR EACH ROW
  EXECUTE FUNCTION update_content_item_content_hash();
```

---

## 3. Backend Implementation

### 3.1 New Edge Function: `translate-card-content`

**Endpoint**: `/functions/v1/translate-card-content`

**Input**:
```typescript
{
  cardId: string;
  targetLanguages: string[]; // ['zh-Hans', 'ja', 'ko']
  forceRetranslate?: boolean; // Re-translate even if up-to-date
}
```

**Process**:
1. Authenticate user via JWT
2. Verify card ownership
3. Check credit balance (1 credit per language)
4. Fetch card and all content items
5. For each target language:
   - Check if translation exists and is up-to-date (compare content_hash)
   - If outdated or missing, translate via GPT-4
   - Store translation in JSONB column
6. Consume credits atomically
7. Log to translation_history
8. Return success with translation status

**GPT-4 Translation Prompt**:
```typescript
const systemPrompt = `You are a professional translator specializing in museum, cultural, and tourism content. 
Translate the following content from ${sourceLanguage} to ${targetLanguage}.

Guidelines:
- Maintain cultural sensitivity and proper terminology
- Preserve markdown formatting in content fields
- Keep proper nouns and names when appropriate
- Ensure translations are natural and engaging for visitors
- Maintain the tone and style of the original content

Output format: JSON with translated fields only.`;

const userPrompt = `
Card Content:
{
  "name": "Museum Card",
  "description": "Welcome to our museum...",
  "contentItems": [
    {
      "name": "Ancient Vase",
      "description": "A beautiful artifact...",
      "content": "# Detailed History\n\nThis vase dates back..."
    }
  ]
}

Translate all text fields to ${targetLanguage}.
`;
```

### 3.2 New Stored Procedures

#### `get_card_translation_status`
```sql
CREATE OR REPLACE FUNCTION get_card_translation_status(p_card_id UUID)
RETURNS TABLE (
  language VARCHAR(10),
  status VARCHAR(20), -- 'original', 'up_to_date', 'outdated', 'not_translated'
  translated_at TIMESTAMPTZ,
  needs_update BOOLEAN
) AS $$
BEGIN
  -- Return translation status for all supported languages
  RETURN QUERY
  WITH supported_languages AS (
    SELECT unnest(ARRAY['en', 'zh-Hant', 'zh-Hans', 'ja', 'ko', 'es', 'fr', 'ru', 'ar', 'th']) AS lang
  ),
  card_info AS (
    SELECT c.original_language, c.translations, c.content_hash, c.last_content_update
    FROM cards c
    WHERE c.id = p_card_id
  )
  SELECT 
    sl.lang,
    CASE 
      WHEN sl.lang = ci.original_language THEN 'original'
      WHEN ci.translations->sl.lang IS NULL THEN 'not_translated'
      WHEN ci.translations->sl.lang->>'content_hash' = ci.content_hash THEN 'up_to_date'
      ELSE 'outdated'
    END,
    (ci.translations->sl.lang->>'translated_at')::TIMESTAMPTZ,
    CASE 
      WHEN sl.lang != ci.original_language AND 
           (ci.translations->sl.lang IS NULL OR 
            ci.translations->sl.lang->>'content_hash' != ci.content_hash)
      THEN TRUE
      ELSE FALSE
    END
  FROM supported_languages sl
  CROSS JOIN card_info ci;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

#### `translate_card_content` (server-side, called by Edge Function)
```sql
CREATE OR REPLACE FUNCTION translate_card_content(
  p_user_id UUID,
  p_card_id UUID,
  p_target_languages TEXT[],
  p_translations JSONB -- Translations from GPT
)
RETURNS JSONB AS $$
DECLARE
  v_credit_cost INTEGER;
  v_current_balance INTEGER;
  v_card_owner UUID;
  v_result JSONB;
BEGIN
  -- Verify ownership
  SELECT owner_id INTO v_card_owner FROM cards WHERE id = p_card_id;
  IF v_card_owner != p_user_id THEN
    RAISE EXCEPTION 'Unauthorized: Card does not belong to user';
  END IF;

  -- Calculate cost
  v_credit_cost := array_length(p_target_languages, 1);
  
  -- Check balance
  SELECT check_credit_balance(p_user_id, v_credit_cost) INTO v_current_balance;
  
  -- Consume credits
  PERFORM consume_credits(
    p_user_id,
    v_credit_cost,
    'translation',
    jsonb_build_object(
      'card_id', p_card_id,
      'languages', p_target_languages
    )
  );
  
  -- Store translations
  UPDATE cards
  SET translations = translations || p_translations,
      updated_at = NOW()
  WHERE id = p_card_id;
  
  -- Log to history
  INSERT INTO translation_history (card_id, languages, credit_cost, translated_by)
  VALUES (p_card_id, p_target_languages, v_credit_cost, p_user_id);
  
  v_result := jsonb_build_object(
    'success', true,
    'translated_languages', p_target_languages,
    'credits_used', v_credit_cost,
    'remaining_balance', v_current_balance - v_credit_cost
  );
  
  RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

#### Update `get_public_card_content` to return translations
```sql
-- Add language parameter to existing function
CREATE OR REPLACE FUNCTION get_public_card_content(
  p_issued_card_id UUID,
  p_language VARCHAR(10) DEFAULT 'en'
)
RETURNS JSONB AS $$
DECLARE
  v_result JSONB;
  v_card_data JSONB;
BEGIN
  -- Existing logic to fetch card...
  
  -- Apply translations if available
  v_result := jsonb_build_object(
    'card', jsonb_build_object(
      'name', COALESCE(
        c.translations->p_language->>'name',
        c.name
      ),
      'description', COALESCE(
        c.translations->p_language->>'description',
        c.description
      ),
      'image_url', c.image_url,
      'original_language', c.original_language,
      'has_translation', (c.translations ? p_language)
    ),
    'content_items', (
      SELECT jsonb_agg(
        jsonb_build_object(
          'id', ci.id,
          'name', COALESCE(ci.translations->p_language->>'name', ci.name),
          'description', COALESCE(ci.translations->p_language->>'description', ci.description),
          'content', COALESCE(ci.translations->p_language->>'content', ci.content),
          'image_url', ci.image_url,
          'order_index', ci.order_index
        )
      )
      FROM content_items ci
      WHERE ci.card_id = v_card_id
      ORDER BY ci.order_index
    )
  );
  
  RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

---

## 4. Frontend Implementation

### 4.1 New Components

#### `TranslationManagement.vue`
- Location: `src/components/Card/TranslationManagement.vue`
- Features:
  - Display translation status table
  - "Translate to New Languages" button → opens dialog
  - "Update Outdated" button
  - Individual language action buttons

#### `TranslationDialog.vue`
- Location: `src/components/Card/TranslationDialog.vue`
- Multi-step dialog:
  - Step 1: Language selection with checkboxes
  - Step 2: Progress indicator
  - Step 3: Success confirmation
- Credit calculation and confirmation
- Uses `CreditConfirmationDialog.vue` pattern

#### `TranslationStatusBadge.vue`
- Small component showing translation status icon
- Used in language selector on mobile

### 4.2 Store Updates

#### New: `src/stores/translation.ts`
```typescript
import { defineStore } from 'pinia';
import { supabase } from '@/lib/supabase';

export const useTranslationStore = defineStore('translation', {
  state: () => ({
    translationStatus: {} as Record<string, TranslationStatus>,
    translationHistory: [] as TranslationHistory[],
    isTranslating: false,
    translationProgress: 0
  }),
  
  actions: {
    async fetchTranslationStatus(cardId: string) {
      const { data, error } = await supabase.rpc('get_card_translation_status', {
        p_card_id: cardId
      });
      if (!error) {
        this.translationStatus = data.reduce((acc, item) => {
          acc[item.language] = item;
          return acc;
        }, {});
      }
    },
    
    async translateCard(cardId: string, targetLanguages: string[]) {
      this.isTranslating = true;
      this.translationProgress = 0;
      
      try {
        // Call Edge Function
        const response = await fetch(
          `${import.meta.env.VITE_SUPABASE_URL}/functions/v1/translate-card-content`,
          {
            method: 'POST',
            headers: {
              'Authorization': `Bearer ${session.access_token}`,
              'Content-Type': 'application/json'
            },
            body: JSON.stringify({ cardId, targetLanguages })
          }
        );
        
        const result = await response.json();
        
        // Refresh status
        await this.fetchTranslationStatus(cardId);
        
        return result;
      } finally {
        this.isTranslating = false;
      }
    }
  }
});
```

### 4.3 Update MyCards.vue

Add new tab:
```vue
<TabView v-model:activeIndex="activeTab">
  <!-- Existing tabs -->
  <TabPanel header="Details">...</TabPanel>
  <TabPanel header="Content">...</TabPanel>
  <TabPanel header="Issue">...</TabPanel>
  <TabPanel header="Access">...</TabPanel>
  
  <!-- NEW TAB -->
  <TabPanel header="Translations">
    <TranslationManagement :card-id="currentCard.id" />
  </TabPanel>
</TabView>
```

---

## 5. Cost Model & Pricing

### Pricing Structure:
- **Base Cost**: 1 credit per language per card
- **What's Translated**:
  - Card: name + description
  - All content items: name + description + content (markdown)
- **Simplified Billing**: Flat 1 credit per language regardless of content item count

### Credit Consumption Flow:
1. User selects N languages → Cost = N credits
2. System checks balance via `check_credit_balance(user_id, N)`
3. If sufficient, proceed with translation
4. After successful translation, consume credits via `consume_credits()`
5. Transaction is atomic (all-or-nothing)

### Cost Safeguards:
- Show credit cost preview before translation
- Confirm dialog with balance check
- Prevent translation if insufficient credits
- Log all translation operations to audit trail

---

## 6. Translation Quality & Context

### GPT-4 Translation Strategy:

**Model**: `gpt-4` (not mini) for high-quality cultural/museum content

**Context Preservation**:
- System prompt explains content type (museum/tourism/cultural)
- Include card context in translation request
- Batch translate all content items together for consistency
- Preserve markdown formatting
- Handle proper nouns appropriately

**Quality Assurance**:
- Post-translation validation (check JSON structure)
- Fallback to original if translation fails
- Store error logs for failed translations

---

## 7. Migration Plan

### Phase 1: Database Schema (Week 1)
1. Add translation columns to `cards` and `content_items`
2. Create `translation_history` table
3. Add triggers for content hash tracking
4. Deploy schema changes to production

### Phase 2: Backend (Week 1-2)
1. Create `translate-card-content` Edge Function
2. Add stored procedures for translation management
3. Update existing RPCs to support language parameter
4. Test translation quality and performance

### Phase 3: Dashboard UI (Week 2)
1. Create `TranslationManagement.vue` component
2. Create `TranslationDialog.vue` with multi-step flow
3. Add "Translations" tab to MyCards
4. Implement outdated translation warnings

### Phase 4: Mobile Client (Week 3)
1. Update `PublicCardView` to pass language parameter
2. Update language selector to show translation availability
3. Test translated content display
4. Add fallback handling

### Phase 5: Testing & Polish (Week 3)
1. End-to-end testing of translation flow
2. Credit consumption testing
3. Performance optimization (batch translations)
4. UI/UX refinements

---

## 8. Open Questions & Decisions Needed

1. **Translation Scope**: Should we translate:
   - ✅ Card name, description
   - ✅ Content item name, description, content
   - ❓ AI instructions / knowledge base? (Probably NO - keep in original)
   
2. **Auto-Translation Option**: Should we offer real-time translation for untranslated languages?
   - Pro: Visitors always see content in their language
   - Con: Quality may be lower, cost concerns
   - **Recommendation**: Manual translation only, fallback to original language

3. **Batch Limits**: Max languages per translation request?
   - **Recommendation**: Allow all 9 languages (excluding original)

4. **Re-translation Policy**: When content updates, should we:
   - a) Auto-mark all translations as outdated (current design) ✅
   - b) Show diff and let user decide which languages to update
   - **Recommendation**: Option (a) for simplicity

5. **Preview Translations**: Should users be able to preview translations before confirming?
   - Pro: Quality control
   - Con: Delays workflow, more complexity
   - **Recommendation**: No preview, but allow re-translation if unsatisfied

---

## 9. Success Metrics

### User Adoption:
- % of cards with at least 1 translation
- Average number of languages per card
- Translation feature usage rate

### Revenue:
- Credits spent on translations
- Translation revenue vs batch issuance revenue

### Quality:
- Re-translation rate (indicates dissatisfaction)
- User feedback on translation quality

### Visitor Engagement:
- Language selection distribution on mobile
- Engagement metrics for translated vs non-translated cards

---

## Next Steps

1. **Review & Approve** this design document
2. **Prioritize** features (MVP vs nice-to-have)
3. **Begin Implementation** following the phase plan
4. **Iterate** based on testing and feedback

---

**Document Version**: 1.0  
**Last Updated**: 2025-10-11  
**Status**: Pending Review

