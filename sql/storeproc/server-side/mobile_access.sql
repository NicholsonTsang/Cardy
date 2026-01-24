-- =================================================================
-- SERVER-SIDE MOBILE ACCESS FUNCTIONS
-- Called by Express backend with service role (not client-callable)
-- =================================================================
-- NOTE: Usage tracking is handled by Redis-first approach in usage-tracker.ts
-- These functions handle card info retrieval and subscription management
-- =================================================================
-- NOTE: get_card_by_access_token_server is defined in card_content.sql
-- to avoid duplication
-- =================================================================


-- =================================================================
-- Update card scan counters (server-side)
-- Still used for total scan tracking
-- =================================================================
CREATE OR REPLACE FUNCTION update_card_scan_counters_server(
    p_card_id UUID,
    p_increment_total BOOLEAN DEFAULT TRUE
)
RETURNS VOID AS $$
BEGIN
    IF p_increment_total THEN
        UPDATE cards
        SET total_sessions = total_sessions + 1
        WHERE id = p_card_id;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

REVOKE ALL ON FUNCTION update_card_scan_counters_server(UUID, BOOLEAN) FROM PUBLIC;
REVOKE ALL ON FUNCTION update_card_scan_counters_server(UUID, BOOLEAN) FROM authenticated;
REVOKE ALL ON FUNCTION update_card_scan_counters_server(UUID, BOOLEAN) FROM anon;
GRANT EXECUTE ON FUNCTION update_card_scan_counters_server(UUID, BOOLEAN) TO service_role;


-- =================================================================
-- SUBSCRIPTION MANAGEMENT FUNCTIONS (Server-side)
-- Usage is tracked in Redis - these just manage subscription metadata
-- =================================================================

-- Reset subscription period (called by Stripe webhook)
-- Redis usage is reset separately by usage-tracker.ts
CREATE OR REPLACE FUNCTION reset_subscription_usage_server(
    p_stripe_subscription_id TEXT,
    p_new_period_start TIMESTAMPTZ,
    p_new_period_end TIMESTAMPTZ
)
RETURNS JSONB AS $$
DECLARE
    v_subscription subscriptions%ROWTYPE;
BEGIN
    -- Get subscription
    SELECT * INTO v_subscription 
    FROM subscriptions 
    WHERE stripe_subscription_id = p_stripe_subscription_id;
    
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', FALSE, 'reason', 'Subscription not found');
    END IF;
    
    -- Update period dates only (usage is tracked in Redis)
    UPDATE subscriptions
    SET current_period_start = p_new_period_start,
        current_period_end = p_new_period_end,
        updated_at = NOW()
    WHERE id = v_subscription.id;
    
    RETURN jsonb_build_object(
        'success', TRUE,
        'user_id', v_subscription.user_id,
        'new_period_start', p_new_period_start,
        'new_period_end', p_new_period_end
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

REVOKE ALL ON FUNCTION reset_subscription_usage_server(TEXT, TIMESTAMPTZ, TIMESTAMPTZ) FROM PUBLIC;
REVOKE ALL ON FUNCTION reset_subscription_usage_server(TEXT, TIMESTAMPTZ, TIMESTAMPTZ) FROM authenticated;
REVOKE ALL ON FUNCTION reset_subscription_usage_server(TEXT, TIMESTAMPTZ, TIMESTAMPTZ) FROM anon;
GRANT EXECUTE ON FUNCTION reset_subscription_usage_server(TEXT, TIMESTAMPTZ, TIMESTAMPTZ) TO service_role;


-- Activate premium subscription (called by Stripe webhook)
-- Modified to support cancel_at_period_end and tier parameter
-- Supports both Starter and Premium subscription activation
DROP FUNCTION IF EXISTS activate_premium_subscription_server(UUID, TEXT, TEXT, TEXT, TIMESTAMPTZ, TIMESTAMPTZ) CASCADE;
DROP FUNCTION IF EXISTS activate_premium_subscription_server(UUID, TEXT, TEXT, TEXT, TIMESTAMPTZ, TIMESTAMPTZ, BOOLEAN) CASCADE;
DROP FUNCTION IF EXISTS activate_premium_subscription_server(UUID, TEXT, TEXT, TEXT, TIMESTAMPTZ, TIMESTAMPTZ, BOOLEAN, TEXT) CASCADE;

CREATE OR REPLACE FUNCTION activate_premium_subscription_server(
    p_user_id UUID,
    p_stripe_customer_id TEXT,
    p_stripe_subscription_id TEXT,
    p_stripe_price_id TEXT,
    p_period_start TIMESTAMPTZ,
    p_period_end TIMESTAMPTZ,
    p_cancel_at_period_end BOOLEAN DEFAULT FALSE,
    p_tier TEXT DEFAULT 'premium'  -- 'starter' or 'premium'
)
RETURNS JSONB AS $$
DECLARE
    v_subscription_id UUID;
    v_tier "SubscriptionTier";
BEGIN
    -- Validate and cast tier
    IF p_tier NOT IN ('starter', 'premium') THEN
        RAISE EXCEPTION 'Invalid tier. Must be: starter or premium.';
    END IF;
    v_tier := p_tier::"SubscriptionTier";
    
    -- Upsert subscription
    INSERT INTO subscriptions (
        user_id, tier, status, stripe_customer_id, 
        stripe_subscription_id, stripe_price_id,
        current_period_start, current_period_end,
        cancel_at_period_end, scheduled_tier
    ) VALUES (
        p_user_id, v_tier, 'active', p_stripe_customer_id,
        p_stripe_subscription_id, p_stripe_price_id,
        p_period_start, p_period_end,
        p_cancel_at_period_end, NULL  -- Clear any scheduled tier
    )
    ON CONFLICT (user_id) DO UPDATE SET
        tier = v_tier,
        status = 'active',
        stripe_customer_id = p_stripe_customer_id,
        stripe_subscription_id = p_stripe_subscription_id,
        stripe_price_id = p_stripe_price_id,
        current_period_start = p_period_start,
        current_period_end = p_period_end,
        cancel_at_period_end = p_cancel_at_period_end,
        scheduled_tier = NULL,  -- Clear any scheduled tier when activating new subscription
        -- Don't clear canceled_at if we're cancelling
        canceled_at = CASE WHEN p_cancel_at_period_end THEN COALESCE(subscriptions.canceled_at, NOW()) ELSE NULL END,
        updated_at = NOW()
    RETURNING id INTO v_subscription_id;
    
    RETURN jsonb_build_object(
        'success', TRUE,
        'subscription_id', v_subscription_id,
        'tier', p_tier,
        'cancel_at_period_end', p_cancel_at_period_end
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

REVOKE ALL ON FUNCTION activate_premium_subscription_server(UUID, TEXT, TEXT, TEXT, TIMESTAMPTZ, TIMESTAMPTZ, BOOLEAN, TEXT) FROM PUBLIC, authenticated, anon;
GRANT EXECUTE ON FUNCTION activate_premium_subscription_server(UUID, TEXT, TEXT, TEXT, TIMESTAMPTZ, TIMESTAMPTZ, BOOLEAN, TEXT) TO service_role;


-- Cancel/downgrade subscription (called by Stripe webhook or cancel endpoint)
-- Supports lookup by stripe_subscription_id or user_id
-- p_scheduled_tier: for downgrades, the tier to switch to after period ends
DROP FUNCTION IF EXISTS cancel_subscription_server(TEXT, BOOLEAN, BOOLEAN) CASCADE;
DROP FUNCTION IF EXISTS cancel_subscription_server(TEXT, BOOLEAN, BOOLEAN, UUID) CASCADE;
DROP FUNCTION IF EXISTS cancel_subscription_server(TEXT, BOOLEAN, BOOLEAN, UUID, TEXT) CASCADE;
CREATE OR REPLACE FUNCTION cancel_subscription_server(
    p_stripe_subscription_id TEXT DEFAULT NULL,
    p_cancel_at_period_end BOOLEAN DEFAULT TRUE,
    p_immediate BOOLEAN DEFAULT FALSE,
    p_user_id UUID DEFAULT NULL,
    p_scheduled_tier TEXT DEFAULT NULL  -- 'free', 'starter', or NULL (defaults to 'free')
)
RETURNS JSONB AS $$
DECLARE
    v_subscription subscriptions%ROWTYPE;
    v_scheduled "SubscriptionTier";
BEGIN
    -- Try to find by stripe_subscription_id first, then by user_id
    IF p_stripe_subscription_id IS NOT NULL THEN
        SELECT * INTO v_subscription 
        FROM subscriptions 
        WHERE stripe_subscription_id = p_stripe_subscription_id;
    END IF;
    
    -- Fallback to user_id if not found by stripe_subscription_id
    IF NOT FOUND AND p_user_id IS NOT NULL THEN
        SELECT * INTO v_subscription 
        FROM subscriptions 
        WHERE user_id = p_user_id;
    END IF;
    
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', FALSE, 'reason', 'Subscription not found');
    END IF;
    
    -- Parse scheduled tier (default to 'free' if not specified)
    IF p_scheduled_tier IS NOT NULL AND p_scheduled_tier IN ('free', 'starter', 'premium') THEN
        v_scheduled := p_scheduled_tier::"SubscriptionTier";
    ELSE
        v_scheduled := 'free'::"SubscriptionTier";
    END IF;
    
    IF p_immediate THEN
        -- Immediate cancellation - switch to scheduled tier now
        UPDATE subscriptions
        SET tier = COALESCE(v_scheduled, 'free'::"SubscriptionTier"),
            status = CASE WHEN v_scheduled = 'free' THEN 'canceled' ELSE 'active' END,
            cancel_at_period_end = FALSE,
            canceled_at = NOW(),
            scheduled_tier = NULL,  -- Clear scheduled tier since we're applying immediately
            stripe_subscription_id = CASE WHEN v_scheduled = 'free' THEN NULL ELSE stripe_subscription_id END,
            updated_at = NOW()
        WHERE id = v_subscription.id;
    ELSE
        -- Cancel at period end - keep current tier privileges until then
        UPDATE subscriptions
        SET cancel_at_period_end = TRUE,
            canceled_at = NOW(),
            scheduled_tier = v_scheduled,  -- Set the tier to switch to at period end
            updated_at = NOW()
        WHERE id = v_subscription.id;
    END IF;
    
    RETURN jsonb_build_object(
        'success', TRUE,
        'user_id', v_subscription.user_id,
        'current_tier', v_subscription.tier,
        'scheduled_tier', v_scheduled,
        'cancel_at_period_end', p_cancel_at_period_end,
        'immediate', p_immediate
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

REVOKE ALL ON FUNCTION cancel_subscription_server(TEXT, BOOLEAN, BOOLEAN, UUID, TEXT) FROM PUBLIC;
REVOKE ALL ON FUNCTION cancel_subscription_server(TEXT, BOOLEAN, BOOLEAN, UUID, TEXT) FROM authenticated;
REVOKE ALL ON FUNCTION cancel_subscription_server(TEXT, BOOLEAN, BOOLEAN, UUID, TEXT) FROM anon;
GRANT EXECUTE ON FUNCTION cancel_subscription_server(TEXT, BOOLEAN, BOOLEAN, UUID, TEXT) TO service_role;


-- Apply scheduled tier change (called by Stripe webhook when subscription ends)
-- This is called when a subscription period ends and there's a scheduled_tier set
DROP FUNCTION IF EXISTS apply_scheduled_tier_change_server(TEXT, UUID) CASCADE;
CREATE OR REPLACE FUNCTION apply_scheduled_tier_change_server(
    p_stripe_subscription_id TEXT DEFAULT NULL,
    p_user_id UUID DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
    v_subscription subscriptions%ROWTYPE;
    v_new_tier "SubscriptionTier";
BEGIN
    -- Try to find by stripe_subscription_id first, then by user_id
    IF p_stripe_subscription_id IS NOT NULL THEN
        SELECT * INTO v_subscription 
        FROM subscriptions 
        WHERE stripe_subscription_id = p_stripe_subscription_id;
    END IF;
    
    -- Fallback to user_id if not found by stripe_subscription_id
    IF NOT FOUND AND p_user_id IS NOT NULL THEN
        SELECT * INTO v_subscription 
        FROM subscriptions 
        WHERE user_id = p_user_id;
    END IF;
    
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', FALSE, 'reason', 'Subscription not found');
    END IF;
    
    -- Check if there's a scheduled tier change
    IF v_subscription.scheduled_tier IS NULL THEN
        RETURN jsonb_build_object(
            'success', FALSE, 
            'reason', 'No scheduled tier change',
            'current_tier', v_subscription.tier
        );
    END IF;
    
    v_new_tier := v_subscription.scheduled_tier;
    
    -- Apply the scheduled tier change
    UPDATE subscriptions
    SET tier = v_new_tier,
        status = CASE WHEN v_new_tier = 'free' THEN 'canceled' ELSE 'active' END,
        cancel_at_period_end = FALSE,
        scheduled_tier = NULL,  -- Clear the scheduled tier
        stripe_subscription_id = CASE WHEN v_new_tier = 'free' THEN NULL ELSE stripe_subscription_id END,
        updated_at = NOW()
    WHERE id = v_subscription.id;
    
    RETURN jsonb_build_object(
        'success', TRUE,
        'user_id', v_subscription.user_id,
        'previous_tier', v_subscription.tier,
        'new_tier', v_new_tier
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

REVOKE ALL ON FUNCTION apply_scheduled_tier_change_server(TEXT, UUID) FROM PUBLIC;
REVOKE ALL ON FUNCTION apply_scheduled_tier_change_server(TEXT, UUID) FROM authenticated;
REVOKE ALL ON FUNCTION apply_scheduled_tier_change_server(TEXT, UUID) FROM anon;
GRANT EXECUTE ON FUNCTION apply_scheduled_tier_change_server(TEXT, UUID) TO service_role;
