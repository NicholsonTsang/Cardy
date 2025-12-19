-- =================================================================
-- CARD CONTENT - SERVER-SIDE STORED PROCEDURES
-- =================================================================
-- All card and content item retrieval from Express backend.
-- Called by backend Express server with service_role permissions.
-- Used primarily for mobile client access and translation operations.
-- =================================================================

-- Get card by access token (for digital access)
DROP FUNCTION IF EXISTS get_card_by_access_token_server CASCADE;
CREATE OR REPLACE FUNCTION get_card_by_access_token_server(
    p_access_token TEXT
)
RETURNS TABLE (
    id UUID,
    user_id UUID,
    is_access_enabled BOOLEAN,
    billing_type TEXT,
    max_scans INTEGER,
    current_scans INTEGER,
    daily_scan_limit INTEGER,
    daily_scans INTEGER,
    last_scan_date DATE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.id,
        c.user_id,
        c.is_access_enabled,
        c.billing_type::TEXT,
        c.max_scans,
        c.current_scans,
        c.daily_scan_limit,
        c.daily_scans,
        c.last_scan_date
    FROM cards c
    WHERE c.access_token = p_access_token;
    -- Note: Removed billing_type = 'digital' filter to allow
    -- any card with an access_token to be accessed via QR code
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get full card content
DROP FUNCTION IF EXISTS get_card_content_server CASCADE;
CREATE OR REPLACE FUNCTION get_card_content_server(
    p_card_id UUID
)
RETURNS TABLE (
    name TEXT,
    description TEXT,
    image_url TEXT,
    crop_parameters JSONB,
    conversation_ai_enabled BOOLEAN,
    ai_instruction TEXT,
    ai_knowledge_base TEXT,
    ai_welcome_general TEXT,
    ai_welcome_item TEXT,
    original_language TEXT,
    translations JSONB,
    content_mode TEXT,
    is_grouped BOOLEAN,
    group_display TEXT,
    billing_type TEXT,
    max_scans INTEGER,
    current_scans INTEGER,
    daily_scan_limit INTEGER,
    daily_scans INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.name,
        c.description,
        c.image_url,
        c.crop_parameters,
        c.conversation_ai_enabled,
        c.ai_instruction,
        c.ai_knowledge_base,
        c.ai_welcome_general,
        c.ai_welcome_item,
        c.original_language::TEXT,  -- Cast to TEXT (column is varchar(10))
        c.translations,
        c.content_mode::TEXT,
        c.is_grouped,
        c.group_display::TEXT,
        c.billing_type::TEXT,
        c.max_scans,
        c.current_scans,
        c.daily_scan_limit,
        c.daily_scans
    FROM cards c
    WHERE c.id = p_card_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get content items for card
DROP FUNCTION IF EXISTS get_content_items_server CASCADE;
CREATE OR REPLACE FUNCTION get_content_items_server(
    p_card_id UUID
)
RETURNS TABLE (
    id UUID,
    parent_id UUID,
    name TEXT,
    content TEXT,
    image_url TEXT,
    ai_knowledge_base TEXT,
    sort_order INTEGER,
    crop_parameters JSONB,
    translations JSONB
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ci.id,
        ci.parent_id,
        ci.name,
        ci.content,
        ci.image_url,
        ci.ai_knowledge_base,
        ci.sort_order,
        ci.crop_parameters,
        ci.translations
    FROM content_items ci
    WHERE ci.card_id = p_card_id
    ORDER BY ci.sort_order ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get issue card by ID (for physical card access)
DROP FUNCTION IF EXISTS get_issue_card_server CASCADE;
CREATE OR REPLACE FUNCTION get_issue_card_server(
    p_issue_card_id UUID
)
RETURNS TABLE (
    card_id UUID,
    active BOOLEAN,
    activated_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT ic.card_id, ic.active, ic.activated_at
    FROM issue_cards ic
    WHERE ic.id = p_issue_card_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Activate issue card
DROP FUNCTION IF EXISTS activate_issue_card_server CASCADE;
CREATE OR REPLACE FUNCTION activate_issue_card_server(
    p_issue_card_id UUID
)
RETURNS VOID AS $$
BEGIN
    UPDATE issue_cards
    SET active = TRUE, activated_at = NOW()
    WHERE id = p_issue_card_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =================================================================
-- GRANTS - Only service_role can execute these
-- =================================================================
REVOKE ALL ON FUNCTION get_card_by_access_token_server FROM PUBLIC, authenticated, anon;
GRANT EXECUTE ON FUNCTION get_card_by_access_token_server TO service_role;

REVOKE ALL ON FUNCTION get_card_content_server FROM PUBLIC, authenticated, anon;
GRANT EXECUTE ON FUNCTION get_card_content_server TO service_role;

REVOKE ALL ON FUNCTION get_content_items_server FROM PUBLIC, authenticated, anon;
GRANT EXECUTE ON FUNCTION get_content_items_server TO service_role;

REVOKE ALL ON FUNCTION get_issue_card_server FROM PUBLIC, authenticated, anon;
GRANT EXECUTE ON FUNCTION get_issue_card_server TO service_role;

REVOKE ALL ON FUNCTION activate_issue_card_server FROM PUBLIC, authenticated, anon;
GRANT EXECUTE ON FUNCTION activate_issue_card_server TO service_role;

