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
-- 7. Bulk Update Card Translations (For Import)
-- =====================================================================
-- Updates card translations JSONB in bulk during import
-- Used to restore translations from exported Excel files
-- =====================================================================

CREATE OR REPLACE FUNCTION update_card_translations_bulk(
    p_card_id UUID,
    p_translations JSONB
) RETURNS VOID 
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_card_owner UUID;
BEGIN
    v_user_id := auth.uid();
    
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;
    
    -- Verify ownership
    SELECT user_id INTO v_card_owner FROM cards WHERE id = p_card_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Card not found';
    END IF;
    
    IF v_card_owner != v_user_id THEN
        RAISE EXCEPTION 'Unauthorized: Card does not belong to user';
    END IF;
    
    UPDATE public.cards
    SET translations = p_translations,
        updated_at = NOW()
    WHERE id = p_card_id;
END;
$$ LANGUAGE plpgsql;

-- =====================================================================
-- 8. Bulk Update Content Item Translations (For Import)
-- =====================================================================
-- Updates content item translations JSONB in bulk during import
-- Used to restore translations from exported Excel files
-- =====================================================================

CREATE OR REPLACE FUNCTION update_content_item_translations_bulk(
    p_content_item_id UUID,
    p_translations JSONB
) RETURNS VOID 
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_card_id UUID;
    v_card_owner UUID;
BEGIN
    v_user_id := auth.uid();
    
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;
    
    -- Get card_id and verify ownership
    SELECT ci.card_id INTO v_card_id
    FROM content_items ci
    WHERE ci.id = p_content_item_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Content item not found';
    END IF;
    
    SELECT user_id INTO v_card_owner FROM cards WHERE id = v_card_id;
    
    IF v_card_owner != v_user_id THEN
        RAISE EXCEPTION 'Unauthorized: Content item does not belong to user';
    END IF;
    
    UPDATE public.content_items
    SET translations = p_translations,
        updated_at = NOW()
    WHERE id = p_content_item_id;
END;
$$ LANGUAGE plpgsql;

-- =====================================================================
-- 9. Recalculate Card Translation Hashes (For Import)
-- =====================================================================
-- After importing translations, recalculates the content_hash inside
-- each translation to match the newly imported card's content_hash.
-- This prevents translations from appearing "Outdated" after import.
-- =====================================================================

CREATE OR REPLACE FUNCTION recalculate_card_translation_hashes(
    p_card_id UUID
) RETURNS VOID 
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_current_hash TEXT;
    v_translations JSONB;
    v_lang_code TEXT;
    v_updated_translations JSONB := '{}'::JSONB;
    v_translation_obj JSONB;
BEGIN
    v_user_id := auth.uid();
    
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;
    
    -- Verify ownership
    IF NOT EXISTS (
        SELECT 1 FROM cards 
        WHERE id = p_card_id AND user_id = v_user_id
    ) THEN
        RAISE EXCEPTION 'Unauthorized: Card not found or access denied';
    END IF;
    
    -- Get current card content hash
    SELECT content_hash, translations 
    INTO v_current_hash, v_translations 
    FROM cards 
    WHERE id = p_card_id;
    
    -- If no content hash yet, calculate it
    IF v_current_hash IS NULL THEN
        v_current_hash := md5(
            COALESCE((SELECT name FROM cards WHERE id = p_card_id), '') || 
            COALESCE((SELECT description FROM cards WHERE id = p_card_id), '')
        );
        
        UPDATE cards SET content_hash = v_current_hash WHERE id = p_card_id;
    END IF;
    
    -- Update each translation's content_hash to match current card
    IF v_translations IS NOT NULL AND v_translations != '{}'::JSONB THEN
        FOR v_lang_code IN SELECT jsonb_object_keys(v_translations)
        LOOP
            v_translation_obj := v_translations->v_lang_code;
            
            -- Update the content_hash within this translation
            v_updated_translations := v_updated_translations || 
                jsonb_build_object(
                    v_lang_code,
                    v_translation_obj || jsonb_build_object('content_hash', v_current_hash)
                );
        END LOOP;
        
        -- Update card with recalculated hashes
        UPDATE cards 
        SET translations = v_updated_translations,
            updated_at = NOW()
        WHERE id = p_card_id;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- =====================================================================
-- 10. Recalculate Content Item Translation Hashes (For Import)
-- =====================================================================
-- After importing translations, recalculates the content_hash inside
-- each translation to match the newly imported content item's content_hash.
-- This prevents translations from appearing "Outdated" after import.
-- =====================================================================

CREATE OR REPLACE FUNCTION recalculate_content_item_translation_hashes(
    p_content_item_id UUID
) RETURNS VOID 
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_card_id UUID;
    v_current_hash TEXT;
    v_translations JSONB;
    v_lang_code TEXT;
    v_updated_translations JSONB := '{}'::JSONB;
    v_translation_obj JSONB;
BEGIN
    v_user_id := auth.uid();
    
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;
    
    -- Get card_id and verify ownership
    SELECT card_id INTO v_card_id
    FROM content_items
    WHERE id = p_content_item_id;
    
    IF v_card_id IS NULL THEN
        RAISE EXCEPTION 'Content item not found';
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM cards 
        WHERE id = v_card_id AND user_id = v_user_id
    ) THEN
        RAISE EXCEPTION 'Unauthorized: Access denied';
    END IF;
    
    -- Get current content item hash
    SELECT content_hash, translations 
    INTO v_current_hash, v_translations 
    FROM content_items 
    WHERE id = p_content_item_id;
    
    -- If no content hash yet, calculate it
    IF v_current_hash IS NULL THEN
        v_current_hash := md5(
            COALESCE((SELECT name FROM content_items WHERE id = p_content_item_id), '') || 
            COALESCE((SELECT content FROM content_items WHERE id = p_content_item_id), '')
        );
        
        UPDATE content_items SET content_hash = v_current_hash WHERE id = p_content_item_id;
    END IF;
    
    -- Update each translation's content_hash to match current content
    IF v_translations IS NOT NULL AND v_translations != '{}'::JSONB THEN
        FOR v_lang_code IN SELECT jsonb_object_keys(v_translations)
        LOOP
            v_translation_obj := v_translations->v_lang_code;
            
            -- Update the content_hash within this translation
            v_updated_translations := v_updated_translations || 
                jsonb_build_object(
                    v_lang_code,
                    v_translation_obj || jsonb_build_object('content_hash', v_current_hash)
                );
        END LOOP;
        
        -- Update content item with recalculated hashes
        UPDATE content_items 
        SET translations = v_updated_translations,
            updated_at = NOW()
        WHERE id = p_content_item_id;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- =====================================================================
-- 11. Recalculate All Translation Hashes (Batch Operation)
-- =====================================================================
-- Recalculates translation hashes for a card and all its content items
-- Used after bulk import to ensure all translations show correct status
-- =====================================================================

CREATE OR REPLACE FUNCTION recalculate_all_translation_hashes(
    p_card_id UUID
) RETURNS VOID 
SECURITY DEFINER
AS $$
DECLARE
    v_content_item_id UUID;
BEGIN
    -- Recalculate card translation hashes
    PERFORM recalculate_card_translation_hashes(p_card_id);
    
    -- Recalculate all content item translation hashes
    FOR v_content_item_id IN 
        SELECT id FROM content_items WHERE card_id = p_card_id
    LOOP
        PERFORM recalculate_content_item_translation_hashes(v_content_item_id);
    END LOOP;
    
    PERFORM log_operation(format('Recalculated all translation hashes for card: %s', p_card_id));
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
GRANT EXECUTE ON FUNCTION update_card_translations_bulk(UUID, JSONB) TO authenticated;
GRANT EXECUTE ON FUNCTION update_content_item_translations_bulk(UUID, JSONB) TO authenticated;
GRANT EXECUTE ON FUNCTION recalculate_card_translation_hashes(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION recalculate_content_item_translation_hashes(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION recalculate_all_translation_hashes(UUID) TO authenticated;

