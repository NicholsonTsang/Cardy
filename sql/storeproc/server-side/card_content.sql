-- =================================================================
-- CARD CONTENT - SERVER-SIDE STORED PROCEDURES
-- =================================================================
-- All card and content item retrieval from Express backend.
-- Called by backend Express server with service_role permissions.
-- Used primarily for mobile client access and translation operations.
-- =================================================================

-- Get card by access token (for digital access)
-- Uses card_access_tokens table for multi-QR support
DROP FUNCTION IF EXISTS get_card_by_access_token_server CASCADE;
CREATE OR REPLACE FUNCTION get_card_by_access_token_server(
    p_access_token TEXT
)
RETURNS TABLE (
    -- Card info
    id UUID,
    user_id UUID,
    billing_type TEXT,
    -- Token-specific fields
    token_id UUID,
    token_name TEXT,
    token_is_enabled BOOLEAN,
    token_daily_session_limit INTEGER,
    token_daily_sessions INTEGER,
    token_monthly_sessions INTEGER,
    token_total_sessions INTEGER,
    -- Template check
    is_template BOOLEAN
) AS $$
DECLARE
    v_current_month_start DATE;
BEGIN
    v_current_month_start := date_trunc('month', CURRENT_DATE)::DATE;
    
    RETURN QUERY
    SELECT 
        c.id,
        c.user_id,
        c.billing_type::TEXT,
        -- Token fields
        t.id AS token_id,
        t.name AS token_name,
        t.is_enabled AS token_is_enabled,
        t.daily_session_limit AS token_daily_session_limit,
        -- Reset daily counter if date changed
        CASE 
            WHEN t.last_session_date = CURRENT_DATE THEN t.daily_sessions
            ELSE 0
        END AS token_daily_sessions,
        -- Reset monthly counter if month changed
        CASE 
            WHEN t.current_month = v_current_month_start THEN t.monthly_sessions
            ELSE 0
        END AS token_monthly_sessions,
        t.total_sessions AS token_total_sessions,
        -- Template check
        (ct.id IS NOT NULL) AS is_template
    FROM card_access_tokens t
    JOIN cards c ON c.id = t.card_id
    LEFT JOIN content_templates ct ON ct.card_id = c.id
    WHERE t.access_token = p_access_token;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get full card content
-- Returns subscription_tier for white-labeling (show branding for Free/Starter, hide for Premium)
-- Note: Session counters are now per-token in card_access_tokens table
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
    metadata JSONB,
    subscription_tier TEXT
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
        c.metadata,
        COALESCE(s.tier::TEXT, 'free') as subscription_tier
    FROM cards c
    LEFT JOIN subscriptions s ON s.user_id = c.user_id
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

-- =================================================================
-- GRANTS - Only service_role can execute these
-- =================================================================
REVOKE ALL ON FUNCTION get_card_by_access_token_server FROM PUBLIC, authenticated, anon;
GRANT EXECUTE ON FUNCTION get_card_by_access_token_server TO service_role;

REVOKE ALL ON FUNCTION get_card_content_server FROM PUBLIC, authenticated, anon;
GRANT EXECUTE ON FUNCTION get_card_content_server TO service_role;

REVOKE ALL ON FUNCTION get_content_items_server FROM PUBLIC, authenticated, anon;
GRANT EXECUTE ON FUNCTION get_content_items_server TO service_role;

