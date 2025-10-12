# Translation Database Storage Architecture

## Summary

Translations are stored using **JSONB columns** in the `cards` and `content_items` tables, providing a flexible, schema-less approach that doesn't require database changes when adding new languages.

## Database Schema

### 1. **Cards Table** - Card-Level Translations

```sql
CREATE TABLE cards (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL,
    name TEXT NOT NULL,                    -- Original name
    description TEXT NOT NULL,             -- Original description
    
    -- Translation System Columns
    translations JSONB DEFAULT '{}'::JSONB,  -- ← Translated content stored here
    original_language VARCHAR(10) DEFAULT 'en',
    content_hash TEXT,                      -- MD5 hash for change detection
    last_content_update TIMESTAMPTZ DEFAULT NOW(),
    
    -- AI fields (not translated)
    conversation_ai_enabled BOOLEAN,
    ai_instruction TEXT,
    ai_knowledge_base TEXT,
    
    -- Other fields...
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- GIN index for efficient JSONB queries
CREATE INDEX idx_cards_translations ON cards USING GIN (translations);
CREATE INDEX idx_cards_original_language ON cards(original_language);
```

#### **translations JSONB Structure:**

```json
{
  "zh-Hans": {
    "name": "紫禁城博物館",
    "description": "明清兩代的皇家宮殿...",
    "translated_at": "2024-01-15T10:30:00Z",
    "content_hash": "a1b2c3d4e5f6..."
  },
  "ja": {
    "name": "故宮博物館",
    "description": "明清時代の皇宮...",
    "translated_at": "2024-01-15T10:31:00Z",
    "content_hash": "a1b2c3d4e5f6..."
  },
  "ko": {
    "name": "고궁 박물관",
    "description": "명청 시대의 황궁...",
    "translated_at": "2024-01-15T10:32:00Z",
    "content_hash": "a1b2c3d4e5f6..."
  }
}
```

**Fields Translated:**
- ✅ `name` (card name)
- ✅ `description` (card description)
- ❌ `ai_instruction` (kept in original language)
- ❌ `ai_knowledge_base` (kept in original language)

### 2. **Content Items Table** - Content-Level Translations

```sql
CREATE TABLE content_items (
    id UUID PRIMARY KEY,
    card_id UUID NOT NULL REFERENCES cards(id),
    parent_id UUID REFERENCES content_items(id),
    name TEXT NOT NULL,                    -- Original name
    content TEXT NOT NULL,                 -- Original content (markdown)
    
    -- Translation System Columns
    translations JSONB DEFAULT '{}'::JSONB,  -- ← Translated content stored here
    content_hash TEXT,                      -- MD5 hash for change detection
    last_content_update TIMESTAMPTZ DEFAULT NOW(),
    
    -- AI field (not translated)
    ai_knowledge_base TEXT,
    
    -- Other fields...
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- GIN index for efficient JSONB queries
CREATE INDEX idx_content_items_translations ON content_items USING GIN (translations);
```

#### **translations JSONB Structure:**

```json
{
  "zh-Hans": {
    "name": "紫禁城建筑",
    "content": "## 建筑特色\n紫禁城占地72万平方米...",
    "translated_at": "2024-01-15T10:30:00Z",
    "content_hash": "x7y8z9a0b1c2..."
  },
  "ja": {
    "name": "故宮建築",
    "content": "## 建築の特徴\n故宮は72万平方メートル...",
    "translated_at": "2024-01-15T10:31:00Z",
    "content_hash": "x7y8z9a0b1c2..."
  }
}
```

**Fields Translated:**
- ✅ `name` (item name)
- ✅ `content` (item content - markdown preserved)
- ❌ `ai_knowledge_base` (kept in original language)

### 3. **Translation History Table** - Audit Trail

```sql
CREATE TABLE translation_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    card_id UUID NOT NULL REFERENCES cards(id) ON DELETE CASCADE,
    target_languages TEXT[] NOT NULL,        -- ['zh-Hans', 'ja', 'ko']
    credit_cost DECIMAL(10, 2) NOT NULL,     -- Total credits consumed
    translated_by UUID NOT NULL REFERENCES auth.users(id),
    translated_at TIMESTAMPTZ DEFAULT NOW(),
    status VARCHAR(20) DEFAULT 'completed',  -- 'pending', 'processing', 'completed', 'failed', 'partial'
    error_message TEXT,                      -- Error details if failed
    metadata JSONB DEFAULT '{}'::JSONB       -- Model used, token count, etc.
);

CREATE INDEX idx_translation_history_card_id ON translation_history(card_id);
CREATE INDEX idx_translation_history_user_id ON translation_history(translated_by);
CREATE INDEX idx_translation_history_created_at ON translation_history(translated_at DESC);
CREATE INDEX idx_translation_history_status ON translation_history(status);
```

#### **Purpose:**
- Audit trail of all translation operations
- Track credit consumption
- Monitor translation success/failure rates
- Debugging and analytics

## Data Flow: How Translations Are Stored

### Step 1: Translation Request (Frontend → Edge Function)

```typescript
// User selects languages to translate
const selectedLanguages = ['zh-Hans', 'ja', 'ko'];
const cardId = 'abc-123-def';

// Frontend calls Edge Function
await fetch('/functions/v1/translate-card-content', {
  method: 'POST',
  headers: { Authorization: `Bearer ${token}` },
  body: JSON.stringify({ cardId, targetLanguages: selectedLanguages })
});
```

### Step 2: GPT-4 Translation (Edge Function)

```typescript
// Edge Function: supabase/functions/translate-card-content/index.ts

// 1. Fetch original content
const card = await supabase.rpc('get_card_for_translation', { p_card_id: cardId });

// 2. Call GPT-4 for translation
const translatedContent = await openai.chat.completions.create({
  model: 'gpt-4-1106-preview',
  messages: [
    {
      role: 'system',
      content: 'You are a professional translator specializing in museum and cultural content...'
    },
    {
      role: 'user',
      content: JSON.stringify({
        targetLanguage: 'zh-Hans',
        card: { name: card.name, description: card.description },
        contentItems: card.content_items
      })
    }
  ]
});

// 3. Parse GPT-4 response
const translations = JSON.parse(translatedContent.choices[0].message.content);
```

### Step 3: Store Translations (Edge Function → Database)

```typescript
// Edge Function calls server-side stored procedure
const result = await supabaseAdmin.rpc('store_card_translations', {
  p_user_id: user.id,
  p_card_id: cardId,
  p_target_languages: ['zh-Hans'],
  p_card_translations: {
    'zh-Hans': {
      name: '紫禁城博物館',
      description: '明清兩代的皇家宮殿...',
      translated_at: new Date().toISOString(),
      content_hash: cardContentHash
    }
  },
  p_content_items_translations: {
    'item-uuid-1': {
      'zh-Hans': {
        name: '紫禁城建筑',
        content: '## 建筑特色\n...',
        translated_at: new Date().toISOString(),
        content_hash: itemContentHash
      }
    }
  },
  p_credit_cost: 1.0
});
```

### Step 4: Database Update (Stored Procedure)

```sql
-- store_card_translations() stored procedure

-- 1. Verify card ownership and credit balance
SELECT user_id INTO v_card_owner FROM cards WHERE id = p_card_id;
SELECT check_credit_balance(p_credit_cost, p_user_id) INTO v_current_balance;

-- 2. Merge translations with existing (|| operator merges JSONB)
UPDATE cards
SET 
  translations = translations || p_card_translations,  -- ← JSONB merge
  updated_at = NOW()
WHERE id = p_card_id;

-- 3. Update each content item
FOR v_item_id, v_item_translations IN
  SELECT key::UUID, value FROM jsonb_each(p_content_items_translations)
LOOP
  UPDATE content_items
  SET 
    translations = translations || v_item_translations,  -- ← JSONB merge
    updated_at = NOW()
  WHERE id = v_item_id;
END LOOP;

-- 4. Consume credits atomically
PERFORM consume_credits(p_credit_cost, p_user_id, 'translation', metadata);

-- 5. Record in translation_history
INSERT INTO translation_history (
  card_id, target_languages, credit_cost, translated_by, status
) VALUES (
  p_card_id, p_target_languages, p_credit_cost, p_user_id, 'completed'
);
```

## Freshness Detection: How Outdated Status Works

### Content Hash Calculation

When original content is created or updated:

```sql
-- Trigger: update_card_content_hash()
-- Runs on INSERT/UPDATE of cards.name or cards.description

CREATE OR REPLACE FUNCTION update_card_content_hash()
RETURNS TRIGGER AS $$
BEGIN
  -- Calculate MD5 hash of translatable fields
  NEW.content_hash = md5(
    COALESCE(NEW.name, '') || '|' || 
    COALESCE(NEW.description, '')
  );
  NEW.last_content_update = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

### Translation Status Check

```sql
-- get_card_translation_status() stored procedure

-- For each language in translations JSONB:
FOR v_language_code IN SELECT jsonb_object_keys(v_translations)
LOOP
  -- Compare stored hash with current hash
  v_stored_hash := v_translations->v_language_code->>'content_hash';
  
  IF v_stored_hash IS NULL OR v_stored_hash != v_current_hash THEN
    v_status := 'outdated';  -- ← Hash mismatch = outdated
  ELSE
    v_status := 'up_to_date';  -- ← Hash match = current
  END IF;
END LOOP;
```

## Querying Translated Content

### Client-Side RPC: Get Translation Status

```typescript
// Frontend: Check which languages are translated
const { data } = await supabase.rpc('get_card_translation_status', {
  p_card_id: cardId
});

// Response:
{
  "original_language": "en",
  "languages": {
    "zh-Hans": {
      "language": "zh-Hans",
      "language_name": "Simplified Chinese",
      "status": "up_to_date",
      "translated_at": "2024-01-15T10:30:00Z",
      "content_hash": "a1b2c3d4e5f6..."
    },
    "ja": {
      "language": "ja",
      "language_name": "Japanese",
      "status": "outdated",
      "translated_at": "2024-01-10T08:00:00Z",
      "content_hash": "old_hash..."  // ← Doesn't match current
    }
  }
}
```

### Client-Side RPC: Get Translated Content

```typescript
// Mobile app: Get card in specific language
const { data } = await supabase.rpc('get_public_card_content', {
  p_card_id: cardId,
  p_language: 'zh-Hans'
});

// Backend automatically returns translated fields if available:
{
  "name": "紫禁城博物館",  // ← From translations JSONB
  "description": "明清兩代的皇家宮殿...",
  "ai_instruction": "You are a knowledgeable guide...",  // ← Original
  "content_items": [
    {
      "name": "紫禁城建筑",  // ← Translated
      "content": "## 建筑特色\n...",  // ← Translated
      "ai_knowledge_base": "The Forbidden City..."  // ← Original
    }
  ]
}
```

## Benefits of JSONB Storage

### 1. **Schema Flexibility** 🔓
- Add new languages without ALTER TABLE
- No fixed column per language
- Easy to extend to 100+ languages if needed

### 2. **Atomic Updates** ⚛️
```sql
-- Merge new translations with existing
UPDATE cards SET translations = translations || '{"ko": {...}}';
-- PostgreSQL handles concurrency and atomicity
```

### 3. **Efficient Querying** 🚀
```sql
-- GIN index makes JSONB queries fast
SELECT * FROM cards WHERE translations ? 'zh-Hans';  -- Has Chinese?
SELECT * FROM cards WHERE translations->'ja'->>'name' = '故宮';  -- Find by translated name
```

### 4. **Version Tracking** 📝
```json
{
  "zh-Hans": {
    "name": "紫禁城",
    "translated_at": "2024-01-15T10:30:00Z",
    "content_hash": "abc123"  // ← Track version
  }
}
```

### 5. **Easy Migration** 🔄
```sql
-- Migrate to new format if needed
UPDATE cards SET translations = jsonb_set(
  translations, 
  '{zh-Hans,version}', 
  '2'
);
```

## Storage Efficiency

### Example Card with 3 Translations

**Original Content (English):**
- Card: name (20 chars) + description (200 chars)
- 5 Content Items: 5 × (name 30 + content 500) = 2,650 chars
- **Total**: ~2,870 characters

**Translated Content (3 languages):**
- Each translation: ~2,870 characters (similar length)
- 3 languages × 2,870 = ~8,610 characters
- JSONB overhead: ~500 characters (metadata, keys)
- **Total**: ~9,110 characters (~9 KB)

**Database Row Size:**
- Original fields: ~3 KB
- translations JSONB: ~9 KB
- Other fields: ~1 KB
- **Total per card**: ~13 KB with 3 translations

**For 1,000 cards with 3 translations each:**
- Storage: ~13 MB
- Very efficient for PostgreSQL

## Performance Characteristics

### Read Performance
- **Direct language lookup**: `O(1)` with GIN index
- **Status check**: Fast hash comparison
- **Typical query**: < 10ms for single card

### Write Performance
- **Translation insert**: ~100ms (JSONB merge)
- **Batch update (5 items)**: ~500ms
- **Credit consumption**: Atomic with row-level locking

### Scalability
- ✅ Handles 10,000+ cards efficiently
- ✅ 10+ languages per card without issues
- ✅ GIN index keeps queries fast
- ✅ JSONB compression reduces storage

## Alternative Approaches (Not Used)

### ❌ Separate Translation Tables

```sql
-- NOT USED: Would require complex joins
CREATE TABLE card_translations (
  id UUID PRIMARY KEY,
  card_id UUID REFERENCES cards(id),
  language VARCHAR(10),
  name TEXT,
  description TEXT
);
```

**Why not:**
- Requires JOINs for every query
- More complex schema
- Harder to maintain atomicity
- More tables to manage

### ❌ Column Per Language

```sql
-- NOT USED: Inflexible schema
CREATE TABLE cards (
  name_en TEXT,
  name_zh_hans TEXT,
  name_ja TEXT,
  -- Need ALTER TABLE for new language
);
```

**Why not:**
- Fixed number of languages
- Schema changes for new languages
- Sparse columns (wasted space)
- Poor scalability

## Summary

**Translation storage uses JSONB columns for maximum flexibility:**

| Table | Column | Content |
|-------|--------|---------|
| `cards` | `translations` | Card name & description translations |
| `content_items` | `translations` | Item name & content translations |
| `translation_history` | Entire table | Audit trail of all translations |

**Key Features:**
- ✅ Schema-less (add languages without migrations)
- ✅ Fast queries (GIN indexes)
- ✅ Atomic updates (JSONB merge)
- ✅ Version tracking (content_hash)
- ✅ Efficient storage (~9 KB per 3 translations)
- ✅ Automatic freshness detection
- ✅ Complete audit trail

**Data Flow:**
1. User selects languages → Frontend
2. GPT-4 translates → Edge Function
3. Store in JSONB → Stored Procedure
4. Consume credits → Atomic transaction
5. Record history → Audit trail
6. Mobile app queries → Translated content returned automatically

