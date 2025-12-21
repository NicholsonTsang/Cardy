-- =================================================================
-- TRANSLATION OPERATIONS - SERVER-SIDE STORED PROCEDURES
-- =================================================================
-- All translation-related database operations from Express backend.
-- Called by backend Express server with service_role permissions.
-- Used for fetching content for translation and saving results.
-- =================================================================

-- Get card for translation (includes ALL translatable text fields)
DROP FUNCTION IF EXISTS get_card_for_translation_server CASCADE;
CREATE OR REPLACE FUNCTION get_card_for_translation_server(
    p_card_id UUID
)
RETURNS TABLE (
    id UUID,
    name TEXT,
    description TEXT,
    ai_instruction TEXT,
    ai_knowledge_base TEXT,
    ai_welcome_general TEXT,
    ai_welcome_item TEXT,
    content_hash TEXT,
    translations JSONB,
    user_id UUID,
    original_language TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.id, c.name, c.description,
        c.ai_instruction, c.ai_knowledge_base, c.ai_welcome_general, c.ai_welcome_item,
        c.content_hash, c.translations, c.user_id, c.original_language::TEXT
    FROM cards c
    WHERE c.id = p_card_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get content items for translation (includes ALL translatable text fields)
DROP FUNCTION IF EXISTS get_content_items_for_translation_server CASCADE;
CREATE OR REPLACE FUNCTION get_content_items_for_translation_server(
    p_card_id UUID
)
RETURNS TABLE (
    id UUID,
    name TEXT,
    content TEXT,
    ai_knowledge_base TEXT,
    content_hash TEXT,
    translations JSONB
) AS $$
BEGIN
    RETURN QUERY
    SELECT ci.id, ci.name, ci.content, ci.ai_knowledge_base, ci.content_hash, ci.translations
    FROM content_items ci
    WHERE ci.card_id = p_card_id
    ORDER BY ci.sort_order;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get fresh card content hash
DROP FUNCTION IF EXISTS get_card_content_hash_server CASCADE;
CREATE OR REPLACE FUNCTION get_card_content_hash_server(
    p_card_id UUID
)
RETURNS TEXT AS $$
DECLARE
    v_hash TEXT;
BEGIN
    SELECT content_hash INTO v_hash
    FROM cards
    WHERE id = p_card_id;
    
    RETURN v_hash;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update card translations
DROP FUNCTION IF EXISTS update_card_translations_server CASCADE;
CREATE OR REPLACE FUNCTION update_card_translations_server(
    p_card_id UUID,
    p_translations JSONB
)
RETURNS VOID AS $$
BEGIN
    UPDATE cards
    SET translations = p_translations
    WHERE id = p_card_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get content item for translation update
DROP FUNCTION IF EXISTS get_content_item_for_update_server CASCADE;
CREATE OR REPLACE FUNCTION get_content_item_for_update_server(
    p_item_id UUID
)
RETURNS TABLE (
    translations JSONB,
    content_hash TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT ci.translations, ci.content_hash
    FROM content_items ci
    WHERE ci.id = p_item_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update content item translations
DROP FUNCTION IF EXISTS update_content_item_translations_server CASCADE;
CREATE OR REPLACE FUNCTION update_content_item_translations_server(
    p_item_id UUID,
    p_translations JSONB
)
RETURNS VOID AS $$
BEGIN
    UPDATE content_items
    SET translations = p_translations
    WHERE id = p_item_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Insert translation history
DROP FUNCTION IF EXISTS insert_translation_history_server CASCADE;
CREATE OR REPLACE FUNCTION insert_translation_history_server(
    p_card_id UUID,
    p_user_id UUID,
    p_target_languages TEXT[],
    p_credit_cost DECIMAL,
    p_status TEXT,
    p_error_message TEXT,
    p_metadata JSONB
)
RETURNS UUID AS $$
DECLARE
    v_id UUID;
BEGIN
    INSERT INTO translation_history (
        card_id, translated_by, target_languages, credit_cost,
        translated_at, status, error_message, metadata
    ) VALUES (
        p_card_id, p_user_id, p_target_languages, p_credit_cost,
        NOW(), p_status, p_error_message, p_metadata
    )
    RETURNING id INTO v_id;
    
    RETURN v_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =================================================================
-- GRANTS - Only service_role can execute these
-- =================================================================
REVOKE ALL ON FUNCTION get_card_for_translation_server FROM PUBLIC, authenticated, anon;
GRANT EXECUTE ON FUNCTION get_card_for_translation_server TO service_role;

REVOKE ALL ON FUNCTION get_content_items_for_translation_server FROM PUBLIC, authenticated, anon;
GRANT EXECUTE ON FUNCTION get_content_items_for_translation_server TO service_role;

REVOKE ALL ON FUNCTION get_card_content_hash_server FROM PUBLIC, authenticated, anon;
GRANT EXECUTE ON FUNCTION get_card_content_hash_server TO service_role;

REVOKE ALL ON FUNCTION update_card_translations_server FROM PUBLIC, authenticated, anon;
GRANT EXECUTE ON FUNCTION update_card_translations_server TO service_role;

REVOKE ALL ON FUNCTION get_content_item_for_update_server FROM PUBLIC, authenticated, anon;
GRANT EXECUTE ON FUNCTION get_content_item_for_update_server TO service_role;

REVOKE ALL ON FUNCTION update_content_item_translations_server FROM PUBLIC, authenticated, anon;
GRANT EXECUTE ON FUNCTION update_content_item_translations_server TO service_role;

REVOKE ALL ON FUNCTION insert_translation_history_server FROM PUBLIC, authenticated, anon;
GRANT EXECUTE ON FUNCTION insert_translation_history_server TO service_role;

