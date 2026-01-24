-- =====================================================
-- Access Token Server-Side Operations
-- Backend-only procedures for mobile client access
-- =====================================================

-- Get card data by access token (for mobile client)
-- Returns card info and token-specific settings
CREATE OR REPLACE FUNCTION get_card_by_access_token_server(
    p_access_token TEXT,
    p_language TEXT DEFAULT 'en'
)
RETURNS TABLE (
    -- Card fields
    card_id UUID,
    card_name TEXT,
    card_description TEXT,
    card_image_url TEXT,
    card_content_mode TEXT,
    card_is_grouped BOOLEAN,
    card_group_display TEXT,
    card_ai_enabled BOOLEAN,
    card_ai_instruction TEXT,
    card_ai_knowledge_base TEXT,
    card_ai_welcome_general TEXT,
    card_ai_welcome_item TEXT,
    card_owner_id UUID,
    card_billing_type TEXT,
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
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.id AS card_id,
        COALESCE(c.translations->p_language->>'name', c.name)::TEXT AS card_name,
        COALESCE(c.translations->p_language->>'description', c.description)::TEXT AS card_description,
        c.image_url AS card_image_url,
        c.content_mode AS card_content_mode,
        c.is_grouped AS card_is_grouped,
        c.group_display AS card_group_display,
        c.conversation_ai_enabled AS card_ai_enabled,
        COALESCE(c.translations->p_language->>'ai_instruction', c.ai_instruction)::TEXT AS card_ai_instruction,
        COALESCE(c.translations->p_language->>'ai_knowledge_base', c.ai_knowledge_base)::TEXT AS card_ai_knowledge_base,
        COALESCE(c.translations->p_language->>'ai_welcome_general', c.ai_welcome_general)::TEXT AS card_ai_welcome_general,
        COALESCE(c.translations->p_language->>'ai_welcome_item', c.ai_welcome_item)::TEXT AS card_ai_welcome_item,
        c.user_id AS card_owner_id,
        c.billing_type AS card_billing_type,
        -- Token fields
        t.id AS token_id,
        t.name AS token_name,
        t.is_enabled AS token_is_enabled,
        t.daily_session_limit AS token_daily_session_limit,
        t.daily_sessions AS token_daily_sessions,
        t.monthly_sessions AS token_monthly_sessions,
        t.total_sessions AS token_total_sessions,
        -- Template check
        EXISTS(SELECT 1 FROM content_templates ct WHERE ct.card_id = c.id) AS is_template
    FROM card_access_tokens t
    JOIN cards c ON c.id = t.card_id
    WHERE t.access_token = p_access_token;
END;
$$;

-- Update token session counters (called from backend after successful access)
CREATE OR REPLACE FUNCTION update_token_session_counters_server(
    p_token_id UUID,
    p_daily_sessions INTEGER,
    p_monthly_sessions INTEGER,
    p_total_sessions INTEGER
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_current_month_start DATE;
BEGIN
    v_current_month_start := date_trunc('month', CURRENT_DATE)::DATE;
    
    UPDATE card_access_tokens
    SET 
        daily_sessions = p_daily_sessions,
        monthly_sessions = p_monthly_sessions,
        total_sessions = total_sessions + 1,
        last_session_date = CURRENT_DATE,
        current_month = v_current_month_start,
        updated_at = NOW()
    WHERE id = p_token_id;
END;
$$;

-- Reset daily counters for tokens where date has changed
CREATE OR REPLACE FUNCTION reset_daily_token_counters_server()
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_reset_count INTEGER;
BEGIN
    UPDATE card_access_tokens
    SET 
        daily_sessions = 0,
        updated_at = NOW()
    WHERE last_session_date IS NOT NULL 
    AND last_session_date < CURRENT_DATE;
    
    GET DIAGNOSTICS v_reset_count = ROW_COUNT;
    RETURN v_reset_count;
END;
$$;

-- Reset monthly counters for tokens where month has changed
CREATE OR REPLACE FUNCTION reset_monthly_token_counters_server()
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_reset_count INTEGER;
    v_current_month_start DATE;
BEGIN
    v_current_month_start := date_trunc('month', CURRENT_DATE)::DATE;
    
    UPDATE card_access_tokens
    SET 
        monthly_sessions = 0,
        current_month = v_current_month_start,
        updated_at = NOW()
    WHERE current_month IS NOT NULL 
    AND current_month < v_current_month_start;
    
    GET DIAGNOSTICS v_reset_count = ROW_COUNT;
    RETURN v_reset_count;
END;
$$;

-- Get token daily limit (for Redis cache)
CREATE OR REPLACE FUNCTION get_token_daily_limit_server(p_token_id UUID)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_limit INTEGER;
BEGIN
    SELECT daily_session_limit INTO v_limit
    FROM card_access_tokens
    WHERE id = p_token_id;
    
    RETURN v_limit;
END;
$$;

-- Revoke public access (server-side only via service role)
REVOKE ALL ON FUNCTION get_card_by_access_token_server(TEXT, TEXT) FROM PUBLIC, authenticated, anon;
REVOKE ALL ON FUNCTION update_token_session_counters_server(UUID, INTEGER, INTEGER, INTEGER) FROM PUBLIC, authenticated, anon;
REVOKE ALL ON FUNCTION reset_daily_token_counters_server() FROM PUBLIC, authenticated, anon;
REVOKE ALL ON FUNCTION reset_monthly_token_counters_server() FROM PUBLIC, authenticated, anon;
REVOKE ALL ON FUNCTION get_token_daily_limit_server(UUID) FROM PUBLIC, authenticated, anon;

