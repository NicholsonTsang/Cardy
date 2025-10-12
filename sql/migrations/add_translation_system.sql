-- =====================================================================
-- MULTI-LANGUAGE TRANSLATION SYSTEM MIGRATION
-- =====================================================================
-- This migration adds support for AI-powered translation of card content
-- to the 10 supported languages. Translations are stored in JSONB columns
-- with content hash tracking to detect when originals become outdated.
--
-- Cost: 1 credit per language per card
-- Supported languages: en, zh-Hant, zh-Hans, ja, ko, es, fr, ru, ar, th
-- =====================================================================

-- =====================================================================
-- 1. Add translation columns to cards table
-- =====================================================================
ALTER TABLE cards 
  ADD COLUMN IF NOT EXISTS translations JSONB DEFAULT '{}'::JSONB,
  ADD COLUMN IF NOT EXISTS original_language VARCHAR(10) DEFAULT 'en',
  ADD COLUMN IF NOT EXISTS content_hash TEXT,
  ADD COLUMN IF NOT EXISTS last_content_update TIMESTAMPTZ DEFAULT NOW();

-- Add GIN index for efficient JSONB translation queries
CREATE INDEX IF NOT EXISTS idx_cards_translations ON cards USING GIN (translations);

-- Add index for original_language for analytics
CREATE INDEX IF NOT EXISTS idx_cards_original_language ON cards(original_language);

-- Update content_hash for existing cards (initial population)
UPDATE cards 
SET content_hash = md5(COALESCE(name, '') || '|' || COALESCE(description, ''))
WHERE content_hash IS NULL;

-- =====================================================================
-- 2. Add translation columns to content_items table
-- =====================================================================
ALTER TABLE content_items 
  ADD COLUMN IF NOT EXISTS translations JSONB DEFAULT '{}'::JSONB,
  ADD COLUMN IF NOT EXISTS content_hash TEXT,
  ADD COLUMN IF NOT EXISTS last_content_update TIMESTAMPTZ DEFAULT NOW();

-- Add GIN index for efficient JSONB translation queries
CREATE INDEX IF NOT EXISTS idx_content_items_translations ON content_items USING GIN (translations);

-- Update content_hash for existing content items (initial population)
UPDATE content_items 
SET content_hash = md5(
  COALESCE(name, '') || '|' || 
  COALESCE(content, '') || '|' ||
  COALESCE(ai_knowledge_base, '')
)
WHERE content_hash IS NULL;

-- =====================================================================
-- 3. Create translation_history table
-- =====================================================================
CREATE TABLE IF NOT EXISTS translation_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  card_id UUID NOT NULL REFERENCES cards(id) ON DELETE CASCADE,
  target_languages TEXT[] NOT NULL, -- Array of language codes translated
  credit_cost DECIMAL(10, 2) NOT NULL,
  translated_by UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  translated_at TIMESTAMPTZ DEFAULT NOW(),
  status VARCHAR(20) DEFAULT 'completed' CHECK (status IN ('pending', 'processing', 'completed', 'failed', 'partial')),
  error_message TEXT,
  metadata JSONB DEFAULT '{}'::JSONB -- Additional metadata (e.g., model used, token count)
);

-- Indexes for translation_history
CREATE INDEX IF NOT EXISTS idx_translation_history_card_id ON translation_history(card_id);
CREATE INDEX IF NOT EXISTS idx_translation_history_user_id ON translation_history(translated_by);
CREATE INDEX IF NOT EXISTS idx_translation_history_created_at ON translation_history(translated_at DESC);
CREATE INDEX IF NOT EXISTS idx_translation_history_status ON translation_history(status);

-- =====================================================================
-- 4. Update credit_consumptions table to support translation type
-- =====================================================================
-- Add translation consumption type to existing enum constraint
ALTER TABLE credit_consumptions 
  DROP CONSTRAINT IF EXISTS credit_consumptions_consumption_type_check;

ALTER TABLE credit_consumptions
  ADD CONSTRAINT credit_consumptions_consumption_type_check
  CHECK (consumption_type IN ('batch_issuance', 'single_card', 'translation'));

-- Add translation_history reference
ALTER TABLE credit_consumptions
  ADD COLUMN IF NOT EXISTS translation_history_id UUID REFERENCES translation_history(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_credit_consumptions_translation_history 
  ON credit_consumptions(translation_history_id);

-- =====================================================================
-- 5. Create triggers for automatic content hash updates
-- =====================================================================

-- Trigger function for cards table
CREATE OR REPLACE FUNCTION update_card_content_hash()
RETURNS TRIGGER AS $$
BEGIN
  -- On INSERT: Always calculate hash
  IF TG_OP = 'INSERT' THEN
    NEW.content_hash := md5(COALESCE(NEW.name, '') || '|' || COALESCE(NEW.description, ''));
    NEW.last_content_update := NOW();
  -- On UPDATE: Only recalculate if name or description changed
  ELSIF TG_OP = 'UPDATE' THEN
    IF (NEW.name IS DISTINCT FROM OLD.name) OR 
       (NEW.description IS DISTINCT FROM OLD.description) THEN
      NEW.content_hash := md5(COALESCE(NEW.name, '') || '|' || COALESCE(NEW.description, ''));
      NEW.last_content_update := NOW();
      -- Note: We don't clear translations here - they're marked as outdated via hash comparison
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop existing trigger if exists
DROP TRIGGER IF EXISTS trigger_update_card_content_hash ON cards;

-- Create trigger for cards (both INSERT and UPDATE)
CREATE TRIGGER trigger_update_card_content_hash
  BEFORE INSERT OR UPDATE ON cards
  FOR EACH ROW
  EXECUTE FUNCTION update_card_content_hash();

-- Trigger function for content_items table
CREATE OR REPLACE FUNCTION update_content_item_content_hash()
RETURNS TRIGGER AS $$
BEGIN
  -- On INSERT: Always calculate hash
  IF TG_OP = 'INSERT' THEN
    NEW.content_hash := md5(
      COALESCE(NEW.name, '') || '|' || 
      COALESCE(NEW.content, '') || '|' ||
      COALESCE(NEW.ai_knowledge_base, '')
    );
    NEW.last_content_update := NOW();
  -- On UPDATE: Only recalculate if any translatable field changed
  ELSIF TG_OP = 'UPDATE' THEN
    IF (NEW.name IS DISTINCT FROM OLD.name) OR 
       (NEW.content IS DISTINCT FROM OLD.content) OR
       (NEW.ai_knowledge_base IS DISTINCT FROM OLD.ai_knowledge_base) THEN
      NEW.content_hash := md5(
        COALESCE(NEW.name, '') || '|' || 
        COALESCE(NEW.content, '') || '|' ||
        COALESCE(NEW.ai_knowledge_base, '')
      );
      NEW.last_content_update := NOW();
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop existing trigger if exists
DROP TRIGGER IF EXISTS trigger_update_content_item_content_hash ON content_items;

-- Create trigger for content_items (both INSERT and UPDATE)
CREATE TRIGGER trigger_update_content_item_content_hash
  BEFORE INSERT OR UPDATE ON content_items
  FOR EACH ROW
  EXECUTE FUNCTION update_content_item_content_hash();

-- =====================================================================
-- 6. Add helper function to check translation freshness
-- =====================================================================

CREATE OR REPLACE FUNCTION is_translation_fresh(
  p_translation_hash TEXT,
  p_current_hash TEXT
)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN p_translation_hash IS NOT NULL 
    AND p_current_hash IS NOT NULL 
    AND p_translation_hash = p_current_hash;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- =====================================================================
-- 7. Create view for easy translation status checking
-- =====================================================================

CREATE OR REPLACE VIEW card_translation_status AS
SELECT 
  c.id AS card_id,
  c.name AS card_name,
  c.user_id,
  c.original_language,
  c.content_hash,
  c.last_content_update,
  c.translations,
  -- Count translated languages (excluding original)
  (SELECT COUNT(*) 
   FROM jsonb_object_keys(c.translations) 
   WHERE jsonb_object_keys != c.original_language) AS translated_languages_count,
  -- Check if any translations are outdated
  EXISTS (
    SELECT 1 
    FROM jsonb_each(c.translations) t
    WHERE t.value->>'content_hash' != c.content_hash
  ) AS has_outdated_translations
FROM cards c;

-- Grant SELECT permission on view (RLS will be handled by underlying table)
GRANT SELECT ON card_translation_status TO authenticated;

-- =====================================================================
-- 8. Add comments for documentation
-- =====================================================================

COMMENT ON COLUMN cards.translations IS 'JSONB object storing translations: {"zh-Hans": {"name": "...", "description": "...", "translated_at": "...", "content_hash": "..."}}';
COMMENT ON COLUMN cards.original_language IS 'ISO 639-1 language code of the original content (default: en)';
COMMENT ON COLUMN cards.content_hash IS 'MD5 hash of name + description for detecting changes';
COMMENT ON COLUMN cards.last_content_update IS 'Timestamp of last update to translatable fields';

COMMENT ON COLUMN content_items.translations IS 'JSONB object storing translations: {"zh-Hans": {"name": "...", "content": "...", "ai_knowledge_base": "...", "translated_at": "...", "content_hash": "..."}}';
COMMENT ON COLUMN content_items.content_hash IS 'MD5 hash of name + content + ai_knowledge_base for detecting changes';
COMMENT ON COLUMN content_items.last_content_update IS 'Timestamp of last update to translatable fields';

COMMENT ON TABLE translation_history IS 'Audit trail of all translation operations with credit tracking';

-- =====================================================================
-- MIGRATION COMPLETE
-- =====================================================================
-- Next steps:
-- 1. Deploy stored procedures for translation management
-- 2. Create Edge Function for GPT-4 translation
-- 3. Update frontend to display and manage translations
-- =====================================================================

