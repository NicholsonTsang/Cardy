-- =================================================================
-- SUBSCRIPTION MANAGEMENT - SERVER-SIDE STORED PROCEDURES
-- =================================================================
-- All subscription-related database operations from Express backend.
-- Called by backend Express server with service_role permissions.
--
-- NOTE: Session-based billing (budget tracking, session costs) is handled
-- entirely in Redis. These stored procedures only manage subscription metadata.
-- All pricing values come from environment variables.
-- =================================================================

-- Get subscription by user ID (basic info only)
DROP FUNCTION IF EXISTS get_subscription_by_user_server CASCADE;
CREATE OR REPLACE FUNCTION get_subscription_by_user_server(
    p_user_id UUID
)
RETURNS TABLE (
    id UUID,
    user_id UUID,
    tier TEXT,
    status TEXT,
    stripe_customer_id TEXT,
    stripe_subscription_id TEXT,
    current_period_start TIMESTAMPTZ,
    current_period_end TIMESTAMPTZ,
    cancel_at_period_end BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        s.id,
        s.user_id,
        s.tier::TEXT,
        s.status::TEXT,
        s.stripe_customer_id,
        s.stripe_subscription_id,
        s.current_period_start,
        s.current_period_end,
        s.cancel_at_period_end
    FROM subscriptions s
    WHERE s.user_id = p_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get subscription Stripe customer ID
DROP FUNCTION IF EXISTS get_subscription_stripe_customer_server CASCADE;
CREATE OR REPLACE FUNCTION get_subscription_stripe_customer_server(
    p_user_id UUID
)
RETURNS TEXT AS $$
DECLARE
    v_customer_id TEXT;
BEGIN
    SELECT stripe_customer_id INTO v_customer_id
    FROM subscriptions
    WHERE user_id = p_user_id;
    
    RETURN v_customer_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update subscription cancel_at_period_end
DROP FUNCTION IF EXISTS update_subscription_cancel_status_server CASCADE;
CREATE OR REPLACE FUNCTION update_subscription_cancel_status_server(
    p_user_id UUID,
    p_cancel_at_period_end BOOLEAN,
    p_canceled_at TIMESTAMPTZ DEFAULT NULL
)
RETURNS VOID AS $$
BEGIN
    UPDATE subscriptions
    SET 
        cancel_at_period_end = p_cancel_at_period_end,
        canceled_at = p_canceled_at,
        updated_at = NOW()
    WHERE user_id = p_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update subscription status (for payment failures)
DROP FUNCTION IF EXISTS update_subscription_status_server CASCADE;
CREATE OR REPLACE FUNCTION update_subscription_status_server(
    p_stripe_subscription_id TEXT,
    p_status TEXT
)
RETURNS VOID AS $$
BEGIN
    UPDATE subscriptions
    SET 
        status = p_status::subscription_status,
        updated_at = NOW()
    WHERE stripe_subscription_id = p_stripe_subscription_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update subscription period dates (called on period renewal)
DROP FUNCTION IF EXISTS update_subscription_period_server CASCADE;
CREATE OR REPLACE FUNCTION update_subscription_period_server(
    p_user_id UUID,
    p_period_start TIMESTAMPTZ,
    p_period_end TIMESTAMPTZ
)
RETURNS VOID AS $$
BEGIN
    UPDATE subscriptions
    SET 
        current_period_start = p_period_start,
        current_period_end = p_period_end,
        updated_at = NOW()
    WHERE user_id = p_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Count user experiences
DROP FUNCTION IF EXISTS count_user_experiences_server CASCADE;
CREATE OR REPLACE FUNCTION count_user_experiences_server(
    p_user_id UUID
)
RETURNS INTEGER AS $$
DECLARE
    v_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_count
    FROM cards
    WHERE user_id = p_user_id;
    
    RETURN v_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Check if user has paid subscription (Starter or Premium) OR is admin
-- Admins have full translation access without subscription
-- Starter tier: limited to max 2 languages
-- Premium tier: unlimited languages
DROP FUNCTION IF EXISTS check_premium_subscription_server CASCADE;
CREATE OR REPLACE FUNCTION check_premium_subscription_server(
    p_user_id UUID
)
RETURNS BOOLEAN AS $$
DECLARE
    v_tier TEXT;
    v_role TEXT;
BEGIN
    -- First check if user is admin (admins always have translation access)
    SELECT raw_user_meta_data->>'role' INTO v_role
    FROM auth.users
    WHERE id = p_user_id;
    
    IF v_role = 'admin' THEN
        RETURN TRUE;
    END IF;
    
    -- Check if user has paid subscription (Starter or Premium)
    SELECT tier::TEXT INTO v_tier
    FROM subscriptions
    WHERE user_id = p_user_id;
    
    -- Both Starter and Premium can access translations
    RETURN v_tier IN ('starter', 'premium');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =================================================================
-- GRANTS - Only service_role can execute these
-- =================================================================
REVOKE ALL ON FUNCTION get_subscription_by_user_server FROM PUBLIC, authenticated, anon;
GRANT EXECUTE ON FUNCTION get_subscription_by_user_server TO service_role;

REVOKE ALL ON FUNCTION get_subscription_stripe_customer_server FROM PUBLIC, authenticated, anon;
GRANT EXECUTE ON FUNCTION get_subscription_stripe_customer_server TO service_role;

REVOKE ALL ON FUNCTION update_subscription_cancel_status_server FROM PUBLIC, authenticated, anon;
GRANT EXECUTE ON FUNCTION update_subscription_cancel_status_server TO service_role;

REVOKE ALL ON FUNCTION update_subscription_status_server FROM PUBLIC, authenticated, anon;
GRANT EXECUTE ON FUNCTION update_subscription_status_server TO service_role;

REVOKE ALL ON FUNCTION update_subscription_period_server FROM PUBLIC, authenticated, anon;
GRANT EXECUTE ON FUNCTION update_subscription_period_server TO service_role;

REVOKE ALL ON FUNCTION count_user_experiences_server FROM PUBLIC, authenticated, anon;
GRANT EXECUTE ON FUNCTION count_user_experiences_server TO service_role;

REVOKE ALL ON FUNCTION check_premium_subscription_server FROM PUBLIC, authenticated, anon;
GRANT EXECUTE ON FUNCTION check_premium_subscription_server TO service_role;
