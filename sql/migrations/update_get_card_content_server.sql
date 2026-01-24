-- Update get_card_content_server to return subscription tier
-- This is needed for white-labeling logic in mobile client

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
    daily_scans INTEGER,
    subscription_tier TEXT -- New field
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
        c.original_language::TEXT,
        c.translations,
        c.content_mode::TEXT,
        c.is_grouped,
        c.group_display::TEXT,
        c.billing_type::TEXT,
        c.max_scans,
        c.current_scans,
        c.daily_scan_limit,
        c.daily_scans,
        COALESCE(s.tier::TEXT, 'free') as subscription_tier
    FROM cards c
    LEFT JOIN subscriptions s ON s.user_id = c.user_id
    WHERE c.id = p_card_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

REVOKE ALL ON FUNCTION get_card_content_server FROM PUBLIC, authenticated, anon;
GRANT EXECUTE ON FUNCTION get_card_content_server TO service_role;
