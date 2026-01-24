-- =================================================================
-- CARD SESSION OPERATIONS - SERVER-SIDE STORED PROCEDURES
-- =================================================================
-- Lightweight card queries for session-based billing.
-- Called by backend Express server with service_role permissions.
-- 
-- NOTE: All pricing (session costs, budgets, limits) comes from environment variables.
-- Redis is the source of truth for budget tracking.
-- Daily session limits are per-QR-code (card_access_tokens table).
-- =================================================================

-- Get card AI-enabled status and billing info
DROP FUNCTION IF EXISTS get_card_billing_info_server CASCADE;
CREATE OR REPLACE FUNCTION get_card_billing_info_server(
    p_card_id UUID
)
RETURNS TABLE (
    card_id UUID,
    user_id UUID,
    ai_enabled BOOLEAN,
    billing_type TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.id AS card_id,
        c.user_id,
        COALESCE(c.conversation_ai_enabled, FALSE) AS ai_enabled,
        c.billing_type
    FROM cards c
    WHERE c.id = p_card_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get card AI-enabled status only (lightweight query)
-- Returns TRUE if conversation_ai_enabled is true
DROP FUNCTION IF EXISTS get_card_ai_status_server CASCADE;
CREATE OR REPLACE FUNCTION get_card_ai_status_server(
    p_card_id UUID
)
RETURNS BOOLEAN AS $$
DECLARE
    v_ai_enabled BOOLEAN;
BEGIN
    SELECT COALESCE(c.conversation_ai_enabled, FALSE)
    INTO v_ai_enabled
    FROM cards c
    WHERE c.id = p_card_id;
    
    RETURN COALESCE(v_ai_enabled, FALSE);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- NOTE: Daily session limits are now per-QR-code in card_access_tokens table
-- Use get_card_by_access_token_server to get token-specific daily limits
-- The old get_card_daily_limit_server function has been removed

-- =================================================================
-- GRANTS - Only service_role can execute these
-- =================================================================
REVOKE ALL ON FUNCTION get_card_billing_info_server FROM PUBLIC, authenticated, anon;
GRANT EXECUTE ON FUNCTION get_card_billing_info_server TO service_role;

REVOKE ALL ON FUNCTION get_card_ai_status_server FROM PUBLIC, authenticated, anon;
GRANT EXECUTE ON FUNCTION get_card_ai_status_server TO service_role;
