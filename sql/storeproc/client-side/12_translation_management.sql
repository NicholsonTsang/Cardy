-- =====================================================================
-- TRANSLATION MANAGEMENT STORED PROCEDURES
-- =====================================================================
-- These procedures handle AI-powered multi-language translation
-- for card content. Translation costs 1 credit per language.
--
-- Client-side procedures (called from dashboard frontend):
-- - get_card_translation_status: Get translation status for all languages
-- - get_card_translations: Get full translations for a card
-- - store_card_translations: Store GPT-translated content (called by Edge Function)
-- - delete_card_translation: Remove a specific language translation
-- - get_translation_history: Get audit trail of translations
-- =====================================================================

-- =====================================================================
-- 1. Get Translation Status for a Card
-- =====================================================================
-- Returns status of translations for all supported languages
-- Status types: 'original', 'up_to_date', 'outdated', 'not_translated'
-- =====================================================================

CREATE OR REPLACE FUNCTION get_card_translation_status(p_card_id UUID)
RETURNS TABLE (
  language VARCHAR(10),
  language_name TEXT,
  status VARCHAR(20),
  translated_at TIMESTAMPTZ,
  needs_update BOOLEAN,
  content_fields_count INTEGER
) 
SECURITY DEFINER
AS $$
DECLARE
  v_user_id UUID;
  v_card_owner UUID;
  v_original_language VARCHAR(10);
  v_content_hash TEXT;
  v_content_items_count INTEGER;
BEGIN
  -- Get current user
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Unauthorized: No authenticated user';
  END IF;

  -- Verify card ownership
  SELECT c.user_id, c.original_language, c.content_hash
  INTO v_card_owner, v_original_language, v_content_hash
  FROM cards c
  WHERE c.id = p_card_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Card not found';
  END IF;

  IF v_card_owner != v_user_id THEN
    -- Allow admins to view any card
    IF NOT EXISTS (
      SELECT 1 FROM auth.users 
      WHERE id = v_user_id 
      AND raw_user_meta_data->>'role' = 'admin'
    ) THEN
      RAISE EXCEPTION 'Unauthorized: Card does not belong to user';
    END IF;
  END IF;

  -- Get content items count
  SELECT COUNT(*) INTO v_content_items_count
  FROM content_items ci
  WHERE ci.card_id = p_card_id;

  -- Return translation status for all supported languages
  RETURN QUERY
  WITH supported_languages AS (
    SELECT 
      unnest(ARRAY['en', 'zh-Hant', 'zh-Hans', 'ja', 'ko', 'es', 'fr', 'ru', 'ar', 'th']) AS lang,
      unnest(ARRAY[
        'English', 
        'Traditional Chinese', 
        'Simplified Chinese', 
        'Japanese', 
        'Korean', 
        'Spanish', 
        'French', 
        'Russian', 
        'Arabic', 
        'Thai'
      ]) AS lang_name
  ),
  card_info AS (
    SELECT 
      c.original_language, 
      c.translations, 
      c.content_hash
    FROM cards c
    WHERE c.id = p_card_id
  ),
  content_items_status AS (
    -- Compute per-language freshness across all content items.
    -- Treat the no-content-items case as up-to-date (TRUE).
    SELECT
      sl.lang AS lang,
      CASE 
        WHEN COUNT(ci.id) = 0 THEN TRUE
        ELSE bool_and(
          ci.translations ? sl.lang AND
          ci.translations->sl.lang->>'content_hash' = ci.content_hash
        )
      END AS all_items_translated
    FROM supported_languages sl
    LEFT JOIN content_items ci
      ON ci.card_id = p_card_id
    GROUP BY sl.lang
  )
  SELECT 
    sl.lang::VARCHAR(10),
    sl.lang_name::TEXT,
    CASE 
      WHEN sl.lang = ci.original_language THEN 'original'
      WHEN ci.translations ? sl.lang THEN
        CASE
          WHEN ci.translations->sl.lang->>'content_hash' = ci.content_hash 
               AND COALESCE(cis.all_items_translated, TRUE)
          THEN 'up_to_date'
          ELSE 'outdated'
        END
      ELSE 'not_translated'
    END::VARCHAR(20),
    (ci.translations->sl.lang->>'translated_at')::TIMESTAMPTZ,
    CASE 
      WHEN sl.lang != ci.original_language AND 
           (NOT (ci.translations ? sl.lang) OR 
            ci.translations->sl.lang->>'content_hash' != ci.content_hash OR
            NOT COALESCE(cis.all_items_translated, TRUE))
      THEN TRUE
      ELSE FALSE
    END::BOOLEAN,
    (2 + v_content_items_count * 3)::INTEGER -- 2 card fields + N items × 3 fields each
  FROM supported_languages sl
  CROSS JOIN card_info ci
  LEFT JOIN content_items_status cis ON cis.lang = sl.lang;
END;
$$ LANGUAGE plpgsql;

-- =====================================================================
-- 2. Get Full Translations for a Card
-- =====================================================================
-- Returns all translations for a card and its content items
-- =====================================================================

CREATE OR REPLACE FUNCTION get_card_translations(
  p_card_id UUID,
  p_language VARCHAR(10) DEFAULT NULL -- If NULL, return all languages
)
RETURNS JSONB
SECURITY DEFINER
AS $$
DECLARE
  v_user_id UUID;
  v_card_owner UUID;
  v_result JSONB;
BEGIN
  -- Get current user
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Unauthorized: No authenticated user';
  END IF;

  -- Verify card ownership
  SELECT user_id INTO v_card_owner FROM cards WHERE id = p_card_id;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Card not found';
  END IF;

  IF v_card_owner != v_user_id THEN
    -- Allow admins to view any card
    IF NOT EXISTS (
      SELECT 1 FROM auth.users 
      WHERE id = v_user_id 
      AND raw_user_meta_data->>'role' = 'admin'
    ) THEN
      RAISE EXCEPTION 'Unauthorized: Card does not belong to user';
    END IF;
  END IF;

  -- Build result
  SELECT jsonb_build_object(
    'card', jsonb_build_object(
      'id', c.id,
      'name', c.name,
      'description', c.description,
      'original_language', c.original_language,
      'content_hash', c.content_hash,
      'translations', CASE 
        WHEN p_language IS NULL THEN c.translations
        ELSE jsonb_build_object(p_language, c.translations->p_language)
      END
    ),
    'content_items', (
      SELECT COALESCE(jsonb_agg(
        jsonb_build_object(
          'id', ci.id,
          'name', ci.name,
          'content', ci.content,
          'ai_knowledge_base', ci.ai_knowledge_base,
          'content_hash', ci.content_hash,
          'translations', CASE 
            WHEN p_language IS NULL THEN ci.translations
            ELSE jsonb_build_object(p_language, ci.translations->p_language)
          END
        ) ORDER BY ci.sort_order
      ), '[]'::jsonb)
      FROM content_items ci
      WHERE ci.card_id = p_card_id
    )
  ) INTO v_result
  FROM cards c
  WHERE c.id = p_card_id;

  RETURN v_result;
END;
$$ LANGUAGE plpgsql;

-- =====================================================================
-- 3. Store Card Translations (Called by Edge Function)
-- =====================================================================
-- Stores GPT-generated translations for a card and its content items
-- This is called by the Edge Function after successful translation
-- =====================================================================

-- NOTE: store_card_translations has been moved to server-side/translation_management.sql
-- This function is called by Edge Functions and requires service_role permissions

-- =====================================================================
-- 4. Delete Card Translation
-- =====================================================================
-- Removes a specific language translation from a card
-- Does not refund credits
-- =====================================================================

CREATE OR REPLACE FUNCTION delete_card_translation(
  p_card_id UUID,
  p_language VARCHAR(10)
)
RETURNS JSONB
SECURITY DEFINER
AS $$
DECLARE
  v_user_id UUID;
  v_card_owner UUID;
BEGIN
  -- Get current user
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Unauthorized: No authenticated user';
  END IF;

  -- Verify card ownership
  SELECT user_id INTO v_card_owner FROM cards WHERE id = p_card_id;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Card not found';
  END IF;

  IF v_card_owner != v_user_id THEN
    RAISE EXCEPTION 'Unauthorized: Card does not belong to user';
  END IF;

  -- Remove translation from card
  UPDATE cards
  SET translations = translations - p_language
  WHERE id = p_card_id;

  -- Remove translations from all content items
  UPDATE content_items
  SET translations = translations - p_language
  WHERE card_id = p_card_id;

  RETURN jsonb_build_object(
    'success', true,
    'card_id', p_card_id,
    'deleted_language', p_language
  );
END;
$$ LANGUAGE plpgsql;

-- =====================================================================
-- 5. Get Translation History
-- =====================================================================
-- Returns audit trail of translation operations for a card
-- =====================================================================

CREATE OR REPLACE FUNCTION get_translation_history(
  p_card_id UUID,
  p_limit INTEGER DEFAULT 50,
  p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
  id UUID,
  card_id UUID,
  target_languages TEXT[],
  credit_cost DECIMAL,
  translated_by UUID,
  translator_email TEXT,
  translated_at TIMESTAMPTZ,
  status VARCHAR,
  error_message TEXT,
  metadata JSONB
)
SECURITY DEFINER
AS $$
DECLARE
  v_user_id UUID;
  v_card_owner UUID;
BEGIN
  -- Get current user
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Unauthorized: No authenticated user';
  END IF;

  -- Verify card ownership or admin
  SELECT c.user_id INTO v_card_owner FROM cards c WHERE c.id = p_card_id;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Card not found';
  END IF;

  IF v_card_owner != v_user_id THEN
    -- Allow admins to view any card
    IF NOT EXISTS (
      SELECT 1 FROM auth.users 
      WHERE id = v_user_id 
      AND raw_user_meta_data->>'role' = 'admin'
    ) THEN
      RAISE EXCEPTION 'Unauthorized: Card does not belong to user';
    END IF;
  END IF;

  -- Return translation history
  RETURN QUERY
  SELECT 
    th.id,
    th.card_id,
    th.target_languages,
    th.credit_cost,
    th.translated_by,
    au.email::TEXT AS translator_email,
    th.translated_at,
    th.status::VARCHAR,
    th.error_message,
    th.metadata
  FROM translation_history th
  LEFT JOIN auth.users au ON au.id = th.translated_by
  WHERE th.card_id = p_card_id
  ORDER BY th.translated_at DESC
  LIMIT p_limit
  OFFSET p_offset;
END;
$$ LANGUAGE plpgsql;

-- =====================================================================
-- 6. Get Outdated Translations for a Card
-- =====================================================================
-- Returns list of languages that need re-translation
-- =====================================================================

CREATE OR REPLACE FUNCTION get_outdated_translations(p_card_id UUID)
RETURNS TABLE (
  language VARCHAR(10),
  last_translated_at TIMESTAMPTZ
)
SECURITY DEFINER
AS $$
DECLARE
  v_user_id UUID;
  v_card_owner UUID;
BEGIN
  -- Get current user
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Unauthorized: No authenticated user';
  END IF;

  -- Verify card ownership
  SELECT user_id INTO v_card_owner FROM cards WHERE id = p_card_id;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Card not found';
  END IF;

  IF v_card_owner != v_user_id THEN
    RAISE EXCEPTION 'Unauthorized: Card does not belong to user';
  END IF;

  -- Return outdated translations from the status function
  RETURN QUERY
  SELECT 
    ts.language::VARCHAR(10),
    ts.translated_at
  FROM get_card_translation_status(p_card_id) ts
  WHERE ts.status = 'outdated';
END;
$$ LANGUAGE plpgsql;

-- =====================================================================
-- Grant permissions
-- =====================================================================

GRANT EXECUTE ON FUNCTION get_card_translation_status(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_card_translations(UUID, VARCHAR) TO authenticated;
GRANT EXECUTE ON FUNCTION store_card_translations(UUID, UUID, TEXT[], JSONB, JSONB, DECIMAL) TO service_role;
GRANT EXECUTE ON FUNCTION delete_card_translation(UUID, VARCHAR) TO authenticated;
GRANT EXECUTE ON FUNCTION get_translation_history(UUID, INTEGER, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION get_outdated_translations(UUID) TO authenticated;

