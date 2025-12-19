-- =================================================================
-- SUBSCRIPTION MANAGEMENT - CLIENT-SIDE STORED PROCEDURES
-- =================================================================
-- These functions are accessible by authenticated users
-- Usage tracking is handled by Redis (source of truth)
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
-- =================================================================
CREATE OR REPLACE FUNCTION can_create_experience(
    p_user_id UUID DEFAULT NULL,
    p_free_limit INTEGER DEFAULT 3,
    p_premium_limit INTEGER DEFAULT 15
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
    
    -- Determine limit based on tier
    IF v_subscription.tier = 'premium' THEN
        v_limit := p_premium_limit;
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
            WHEN v_subscription.tier = 'free' THEN 'Upgrade to Premium to create more projects'
            ELSE 'Project limit reached'
        END
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =================================================================
-- FUNCTION: Can use translations
-- Premium-only feature check
-- =================================================================
CREATE OR REPLACE FUNCTION can_use_translations(
    p_user_id UUID DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
    v_user_id UUID := COALESCE(p_user_id, auth.uid());
    v_subscription subscriptions%ROWTYPE;
BEGIN
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;
    
    -- Get subscription
    v_subscription := get_or_create_subscription(v_user_id);
    
    RETURN jsonb_build_object(
        'can_translate', v_subscription.tier = 'premium',
        'tier', v_subscription.tier::TEXT,
        'message', CASE 
            WHEN v_subscription.tier = 'premium' THEN 'Translations available'
            ELSE 'Upgrade to Premium to access multi-language translations'
        END
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =================================================================
-- FUNCTION: Get subscription details
-- All business parameters passed from calling application
-- NOTE: Usage stats (monthly_access_used) returned as 0 here
--       Backend fills in actual values from Redis (source of truth)
-- =================================================================
CREATE OR REPLACE FUNCTION get_subscription_details(
    p_user_id UUID DEFAULT NULL,
    p_free_experience_limit INTEGER DEFAULT 3,
    p_premium_experience_limit INTEGER DEFAULT 15,
    p_free_monthly_access INTEGER DEFAULT 50,
    p_premium_monthly_access INTEGER DEFAULT 3000,
    p_premium_monthly_fee DECIMAL DEFAULT 50,
    p_overage_credits_per_batch INTEGER DEFAULT 5,
    p_overage_access_per_batch INTEGER DEFAULT 100
)
RETURNS JSONB AS $$
DECLARE
    v_user_id UUID := COALESCE(p_user_id, auth.uid());
    v_subscription subscriptions%ROWTYPE;
    v_experience_count INTEGER;
    v_monthly_limit INTEGER;
BEGIN
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;
    
    -- Get subscription
    v_subscription := get_or_create_subscription(v_user_id);
    
    -- Count experiences
    SELECT COUNT(*) INTO v_experience_count FROM cards WHERE user_id = v_user_id;
    
    -- Determine monthly limit based on tier
    IF v_subscription.tier = 'premium' THEN
        v_monthly_limit := p_premium_monthly_access;
    ELSE
        v_monthly_limit := p_free_monthly_access;
    END IF;
    
    RETURN jsonb_build_object(
        'tier', v_subscription.tier::TEXT,
        'status', v_subscription.status,
        'is_premium', v_subscription.tier = 'premium',
        
        -- Stripe info
        'stripe_subscription_id', v_subscription.stripe_subscription_id,
        'current_period_start', v_subscription.current_period_start,
        'current_period_end', v_subscription.current_period_end,
        'cancel_at_period_end', v_subscription.cancel_at_period_end,
        
        -- Usage (returned as 0 - backend fills from Redis)
        'monthly_access_limit', v_monthly_limit,
        'monthly_access_used', 0,  -- Redis is source of truth
        'monthly_access_remaining', v_monthly_limit,  -- Backend recalculates from Redis
        
        -- Experience limits (using parameters)
        'experience_count', v_experience_count,
        'experience_limit', CASE 
            WHEN v_subscription.tier = 'premium' THEN p_premium_experience_limit 
            ELSE p_free_experience_limit 
        END,
        
        -- Features
        'features', jsonb_build_object(
            'translations_enabled', v_subscription.tier = 'premium',
            'can_buy_overage', v_subscription.tier = 'premium'
        ),
        
        -- Pricing info (using parameters)
        'pricing', jsonb_build_object(
            'monthly_fee_usd', CASE WHEN v_subscription.tier = 'premium' THEN p_premium_monthly_fee ELSE 0 END,
            'monthly_access_limit', v_monthly_limit,
            'overage_credits_per_batch', CASE WHEN v_subscription.tier = 'premium' THEN p_overage_credits_per_batch ELSE NULL END,
            'overage_access_per_batch', CASE WHEN v_subscription.tier = 'premium' THEN p_overage_access_per_batch ELSE NULL END,
            'overage_cost_per_access', CASE WHEN v_subscription.tier = 'premium' 
                THEN ROUND(p_overage_credits_per_batch::DECIMAL / p_overage_access_per_batch, 4) 
                ELSE NULL END
        )
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =================================================================
-- GRANTS
-- =================================================================
GRANT EXECUTE ON FUNCTION get_or_create_subscription(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION can_create_experience(UUID, INTEGER, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION can_use_translations(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_subscription_details(UUID, INTEGER, INTEGER, INTEGER, INTEGER, DECIMAL, INTEGER, INTEGER) TO authenticated;

