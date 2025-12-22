-- =================================================================
-- ACCESS LOGGING - SERVER-SIDE STORED PROCEDURES
-- =================================================================
-- All access log related database operations from Express backend.
-- Called by backend Express server with service_role permissions.
-- =================================================================

-- Get recent access logs for user
DROP FUNCTION IF EXISTS get_recent_access_logs_server CASCADE;
CREATE OR REPLACE FUNCTION get_recent_access_logs_server(
    p_user_id UUID,
    p_limit INTEGER DEFAULT 10
)
RETURNS TABLE (
    id UUID,
    card_id UUID,
    visitor_hash TEXT,
    accessed_at TIMESTAMPTZ,
    subscription_tier TEXT,
    was_overage BOOLEAN,
    is_owner_access BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        cal.id,
        cal.card_id,
        cal.visitor_hash,
        cal.accessed_at,
        cal.subscription_tier::TEXT,
        cal.was_overage,
        cal.is_owner_access
    FROM card_access_log cal
    WHERE cal.card_owner_id = p_user_id
    ORDER BY cal.accessed_at DESC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get daily access stats for chart
DROP FUNCTION IF EXISTS get_daily_access_stats_server CASCADE;
CREATE OR REPLACE FUNCTION get_daily_access_stats_server(
    p_user_id UUID,
    p_start_date TIMESTAMPTZ,
    p_end_date TIMESTAMPTZ
)
RETURNS TABLE (
    accessed_at TIMESTAMPTZ,
    was_overage BOOLEAN,
    is_ai_enabled BOOLEAN,
    session_cost_usd DECIMAL(10, 4)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        cal.accessed_at, 
        cal.was_overage,
        COALESCE(cal.is_ai_enabled, FALSE) AS is_ai_enabled,
        COALESCE(cal.session_cost_usd, 0) AS session_cost_usd
    FROM card_access_log cal
    WHERE cal.card_owner_id = p_user_id
      AND cal.is_owner_access = FALSE
      AND cal.accessed_at >= p_start_date
      AND cal.accessed_at <= p_end_date
    ORDER BY cal.accessed_at ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Insert access log (with session-based billing fields)
DROP FUNCTION IF EXISTS insert_access_log_server CASCADE;
CREATE OR REPLACE FUNCTION insert_access_log_server(
    p_card_id UUID,
    p_visitor_hash TEXT,
    p_card_owner_id UUID,
    p_subscription_tier TEXT,
    p_is_owner_access BOOLEAN,
    p_was_overage BOOLEAN,
    p_credit_charged BOOLEAN,
    -- Optional session-based billing fields (default to legacy values if not provided)
    p_session_id TEXT DEFAULT NULL,
    p_session_cost_usd DECIMAL DEFAULT 0,
    p_is_ai_enabled BOOLEAN DEFAULT FALSE
)
RETURNS UUID AS $$
DECLARE
    v_id UUID;
BEGIN
    INSERT INTO card_access_log (
        card_id, visitor_hash, card_owner_id,
        subscription_tier, is_owner_access, was_overage, credit_charged,
        session_id, session_cost_usd, is_ai_enabled
    ) VALUES (
        p_card_id, p_visitor_hash, p_card_owner_id,
        p_subscription_tier, p_is_owner_access, p_was_overage, p_credit_charged,
        COALESCE(p_session_id, p_visitor_hash), -- Use visitor_hash as session_id if not provided
        p_session_cost_usd,
        p_is_ai_enabled
    )
    RETURNING id INTO v_id;
    
    RETURN v_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =================================================================
-- GRANTS - Only service_role can execute these
-- =================================================================
REVOKE ALL ON FUNCTION get_recent_access_logs_server FROM PUBLIC, authenticated, anon;
GRANT EXECUTE ON FUNCTION get_recent_access_logs_server TO service_role;

REVOKE ALL ON FUNCTION get_daily_access_stats_server FROM PUBLIC, authenticated, anon;
GRANT EXECUTE ON FUNCTION get_daily_access_stats_server TO service_role;

REVOKE ALL ON FUNCTION insert_access_log_server FROM PUBLIC, authenticated, anon;
GRANT EXECUTE ON FUNCTION insert_access_log_server TO service_role;

