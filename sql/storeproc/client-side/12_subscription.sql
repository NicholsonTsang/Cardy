-- =================================================================
-- SUBSCRIPTION MANAGEMENT - CLIENT-SIDE STORED PROCEDURES
-- =================================================================
-- These functions are accessible by authenticated users
-- Usage tracking is handled by Redis (source of truth)
--
-- NOTE: All pricing/budget values come from environment variables
-- passed as parameters. The database only stores tier/status.
-- Redis tracks actual budget usage.
-- =================================================================

-- =================================================================
-- FUNCTION: Get or create subscription
-- Creates free tier subscription if none exists
-- =================================================================
CREATE OR REPLACE FUNCTION get_or_create_subscription(
    p_user_id UUID DEFAULT NULL
)
RETURNS subscriptions AS $$
DECLARE
    v_user_id UUID := COALESCE(p_user_id, auth.uid());
    v_subscription subscriptions%ROWTYPE;
BEGIN
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;
    
    -- Try to get existing subscription
    SELECT * INTO v_subscription 
    FROM subscriptions 
    WHERE user_id = v_user_id;
    
    -- Create free tier if none exists
    IF NOT FOUND THEN
        INSERT INTO subscriptions (user_id, tier, status)
        VALUES (v_user_id, 'free', 'active')
        RETURNING * INTO v_subscription;
    END IF;
    
    RETURN v_subscription;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =================================================================
-- FUNCTION: Can create project
-- Business parameters passed from calling application
-- Supports Free, Starter, and Premium tiers
-- =================================================================
CREATE OR REPLACE FUNCTION can_create_experience(
    p_user_id UUID DEFAULT NULL,
    p_free_limit INTEGER DEFAULT 3,
    p_starter_limit INTEGER DEFAULT 5,
    p_premium_limit INTEGER DEFAULT 35
)
RETURNS JSONB AS $$
DECLARE
    v_user_id UUID := COALESCE(p_user_id, auth.uid());
    v_subscription subscriptions%ROWTYPE;
    v_experience_count INTEGER;
    v_limit INTEGER;
    v_user_role TEXT;
BEGIN
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;
    
    -- Check if user is admin
    v_user_role := get_user_role(v_user_id);
    IF v_user_role = 'admin' THEN
        RETURN jsonb_build_object(
            'can_create', TRUE,
            'current_count', (SELECT COUNT(*) FROM cards WHERE user_id = v_user_id),
            'limit', 999999,
            'tier', 'admin',
            'message', 'Admin bypass'
        );
    END IF;
    
    -- Get subscription
    v_subscription := get_or_create_subscription(v_user_id);
    
    -- Count existing experiences
    SELECT COUNT(*) INTO v_experience_count FROM cards WHERE user_id = v_user_id;
    
    -- Determine limit based on tier (Free, Starter, Premium)
    IF v_subscription.tier = 'premium' THEN
        v_limit := p_premium_limit;
    ELSIF v_subscription.tier = 'starter' THEN
        v_limit := p_starter_limit;
    ELSE
        v_limit := p_free_limit;
    END IF;
    
    RETURN jsonb_build_object(
        'can_create', v_experience_count < v_limit,
        'current_count', v_experience_count,
        'limit', v_limit,
        'tier', v_subscription.tier::TEXT,
        'message', CASE 
            WHEN v_experience_count < v_limit THEN 'OK'
            WHEN v_subscription.tier = 'free' THEN 'Upgrade to Starter or Premium to create more projects'
            WHEN v_subscription.tier = 'starter' THEN 'Upgrade to Premium to create more projects'
            ELSE 'Project limit reached'
        END
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =================================================================
-- FUNCTION: Can use translations
-- Starter and Premium tiers can use translations
-- Starter: max 2 languages, Premium: unlimited
-- =================================================================
CREATE OR REPLACE FUNCTION can_use_translations(
    p_user_id UUID DEFAULT NULL,
    p_starter_max_languages INTEGER DEFAULT 2
)
RETURNS JSONB AS $$
DECLARE
    v_user_id UUID := COALESCE(p_user_id, auth.uid());
    v_subscription subscriptions%ROWTYPE;
    v_user_role TEXT;
BEGIN
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;
    
    -- Check if user is admin (admins always have translation access)
    v_user_role := get_user_role(v_user_id);
    IF v_user_role = 'admin' THEN
        RETURN jsonb_build_object(
            'can_translate', TRUE,
            'tier', 'admin',
            'max_languages', -1,
            'message', 'Admin bypass - unlimited translations'
        );
    END IF;
    
    -- Get subscription
    v_subscription := get_or_create_subscription(v_user_id);
    
    RETURN jsonb_build_object(
        'can_translate', v_subscription.tier IN ('starter', 'premium'),
        'tier', v_subscription.tier::TEXT,
        'max_languages', CASE
            WHEN v_subscription.tier = 'premium' THEN -1
            WHEN v_subscription.tier = 'starter' THEN p_starter_max_languages
            ELSE 0
        END,
        'message', CASE 
            WHEN v_subscription.tier = 'premium' THEN 'Unlimited translations available'
            WHEN v_subscription.tier = 'starter' THEN 'Max ' || p_starter_max_languages || ' language translations available'
            ELSE 'Upgrade to Starter or Premium to access multi-language translations'
        END
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =================================================================
-- FUNCTION: Get subscription details
-- All pricing/budget values come from parameters (environment variables)
-- NOTE: Usage stats come from Redis (source of truth), not from DB
-- Supports Free, Starter, and Premium tiers
-- =================================================================
CREATE OR REPLACE FUNCTION get_subscription_details(
    p_user_id UUID DEFAULT NULL,
    p_free_experience_limit INTEGER DEFAULT 3,
    p_starter_experience_limit INTEGER DEFAULT 5,
    p_premium_experience_limit INTEGER DEFAULT 35,
    p_free_monthly_sessions INTEGER DEFAULT 50,  -- Free tier session limit
    p_starter_monthly_budget DECIMAL DEFAULT 40.00,  -- Starter monthly budget USD
    p_premium_monthly_budget DECIMAL DEFAULT 280.00,  -- Premium monthly budget USD
    p_starter_ai_session_cost DECIMAL DEFAULT 0.05,  -- Starter AI session cost
    p_starter_non_ai_session_cost DECIMAL DEFAULT 0.025,  -- Starter non-AI session cost
    p_premium_ai_session_cost DECIMAL DEFAULT 0.04,  -- Premium AI session cost
    p_premium_non_ai_session_cost DECIMAL DEFAULT 0.02,  -- Premium non-AI session cost
    p_overage_credits_per_batch INTEGER DEFAULT 5  -- Credits per auto top-up
)
RETURNS JSONB AS $$
DECLARE
    v_user_id UUID := COALESCE(p_user_id, auth.uid());
    v_subscription subscriptions%ROWTYPE;
    v_experience_count INTEGER;
    v_monthly_budget DECIMAL;
    v_ai_session_cost DECIMAL;
    v_non_ai_session_cost DECIMAL;
BEGIN
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;
    
    -- Get subscription
    v_subscription := get_or_create_subscription(v_user_id);
    
    -- Count experiences
    SELECT COUNT(*) INTO v_experience_count FROM cards WHERE user_id = v_user_id;
    
    -- Set tier-specific values
    IF v_subscription.tier = 'premium' THEN
        v_monthly_budget := p_premium_monthly_budget;
        v_ai_session_cost := p_premium_ai_session_cost;
        v_non_ai_session_cost := p_premium_non_ai_session_cost;
    ELSIF v_subscription.tier = 'starter' THEN
        v_monthly_budget := p_starter_monthly_budget;
        v_ai_session_cost := p_starter_ai_session_cost;
        v_non_ai_session_cost := p_starter_non_ai_session_cost;
    ELSE
        v_monthly_budget := 0;
        v_ai_session_cost := 0;
        v_non_ai_session_cost := 0;
    END IF;
    
    RETURN jsonb_build_object(
        'tier', v_subscription.tier::TEXT,
        'status', v_subscription.status,
        'is_premium', v_subscription.tier = 'premium',
        'is_starter', v_subscription.tier = 'starter',
        'is_paid', v_subscription.tier IN ('starter', 'premium'),
        
        -- Stripe info
        'stripe_subscription_id', v_subscription.stripe_subscription_id,
        'current_period_start', v_subscription.current_period_start,
        'current_period_end', v_subscription.current_period_end,
        'cancel_at_period_end', v_subscription.cancel_at_period_end,
        'scheduled_tier', v_subscription.scheduled_tier::TEXT,  -- Tier to switch to after period ends
        
        -- Session-based billing (from parameters/env vars)
        -- NOTE: Actual budget tracking is in Redis, these are just for display
        'monthly_budget_usd', v_monthly_budget,
        'budget_consumed_usd', 0,  -- Redis is source of truth, backend fills this
        'budget_remaining_usd', v_monthly_budget,
        
        -- Session costs (tier-specific)
        'ai_session_cost_usd', v_ai_session_cost,
        'non_ai_session_cost_usd', v_non_ai_session_cost,
        
        -- Calculated session limits
        'ai_sessions_included', CASE 
            WHEN v_subscription.tier IN ('starter', 'premium') THEN FLOOR(v_monthly_budget / v_ai_session_cost) 
            ELSE 0 
        END,
        'non_ai_sessions_included', CASE 
            WHEN v_subscription.tier IN ('starter', 'premium') THEN FLOOR(v_monthly_budget / v_non_ai_session_cost) 
            ELSE 0 
        END,
        
        -- Free tier (session count based)
        'monthly_session_limit', CASE WHEN v_subscription.tier = 'free' THEN p_free_monthly_sessions ELSE NULL END,
        
        -- Experience limits
        'experience_count', v_experience_count,
        'experience_limit', CASE 
            WHEN v_subscription.tier = 'premium' THEN p_premium_experience_limit
            WHEN v_subscription.tier = 'starter' THEN p_starter_experience_limit
            ELSE p_free_experience_limit 
        END,
        
        -- Features
        'features', jsonb_build_object(
            'translations_enabled', v_subscription.tier IN ('starter', 'premium'),
            'max_languages', CASE
                WHEN v_subscription.tier = 'premium' THEN -1
                WHEN v_subscription.tier = 'starter' THEN 2
                ELSE 0
            END,
            'can_buy_overage', v_subscription.tier IN ('starter', 'premium'),
            'white_label', v_subscription.tier = 'premium'
        ),
        
        -- Pricing info (all from parameters/env vars)
        'pricing', jsonb_build_object(
            'monthly_fee_usd', v_monthly_budget,
            'ai_session_cost_usd', v_ai_session_cost,
            'non_ai_session_cost_usd', v_non_ai_session_cost,
            'ai_sessions_included', CASE WHEN v_subscription.tier IN ('starter', 'premium') THEN FLOOR(v_monthly_budget / v_ai_session_cost) ELSE 0 END,
            'non_ai_sessions_included', CASE WHEN v_subscription.tier IN ('starter', 'premium') THEN FLOOR(v_monthly_budget / v_non_ai_session_cost) ELSE 0 END,
            'overage_credits_per_batch', p_overage_credits_per_batch,
            'overage_ai_sessions_per_batch', CASE WHEN v_ai_session_cost > 0 THEN FLOOR(p_overage_credits_per_batch / v_ai_session_cost) ELSE 0 END,
            'overage_non_ai_sessions_per_batch', CASE WHEN v_non_ai_session_cost > 0 THEN FLOOR(p_overage_credits_per_batch / v_non_ai_session_cost) ELSE 0 END
        )
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =================================================================
-- GRANTS
-- =================================================================
GRANT EXECUTE ON FUNCTION get_or_create_subscription(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION can_create_experience(UUID, INTEGER, INTEGER, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION can_use_translations(UUID, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION get_subscription_details(UUID, INTEGER, INTEGER, INTEGER, INTEGER, DECIMAL, DECIMAL, DECIMAL, DECIMAL, DECIMAL, DECIMAL, INTEGER) TO authenticated;
