-- =================================================================
-- UPDATE SUBSCRIPTION PROCEDURES FOR STARTER TIER
-- =================================================================

-- 1. Update get_or_create_subscription (No changes needed, but good to have)

-- 2. Update can_create_experience to handle starter tier limits
CREATE OR REPLACE FUNCTION can_create_experience(
    p_user_id UUID DEFAULT NULL,
    p_free_limit INTEGER DEFAULT 3,
    p_premium_limit INTEGER DEFAULT 35,
    p_starter_limit INTEGER DEFAULT 5
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
            ELSE 'Project limit reached'
        END
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Update can_use_translations to allow starter tier
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
        'can_translate', v_subscription.tier IN ('premium', 'starter'),
        'tier', v_subscription.tier::TEXT,
        'message', CASE 
            WHEN v_subscription.tier IN ('premium', 'starter') THEN 'Translations available'
            ELSE 'Upgrade to Starter or Premium to access multi-language translations'
        END
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Update get_subscription_details to handle starter tier
CREATE OR REPLACE FUNCTION get_subscription_details(
    p_user_id UUID DEFAULT NULL,
    p_free_experience_limit INTEGER DEFAULT 3,
    p_starter_experience_limit INTEGER DEFAULT 5,
    p_premium_experience_limit INTEGER DEFAULT 35,
    p_free_monthly_sessions INTEGER DEFAULT 50,
    p_starter_monthly_budget DECIMAL DEFAULT 40.00,
    p_premium_monthly_budget DECIMAL DEFAULT 280.00,
    p_starter_ai_session_cost DECIMAL DEFAULT 0.05,
    p_starter_non_ai_session_cost DECIMAL DEFAULT 0.025,
    p_premium_ai_session_cost DECIMAL DEFAULT 0.04,
    p_premium_non_ai_session_cost DECIMAL DEFAULT 0.02,
    p_overage_credits_per_batch INTEGER DEFAULT 5
)
RETURNS JSONB AS $$
DECLARE
    v_user_id UUID := COALESCE(p_user_id, auth.uid());
    v_subscription subscriptions%ROWTYPE;
    v_experience_count INTEGER;
    v_tier_details JSONB;
BEGIN
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;
    
    v_subscription := get_or_create_subscription(v_user_id);
    
    SELECT COUNT(*) INTO v_experience_count FROM cards WHERE user_id = v_user_id;
    
    -- Determine tier-specific details (calculated here or passed from params)
    IF v_subscription.tier = 'free' THEN
        v_tier_details := jsonb_build_object(
            'experience_limit', p_free_experience_limit,
            'monthly_budget_usd', 0,
            'ai_session_cost_usd', 0,
            'non_ai_session_cost_usd', 0,
            'ai_sessions_included', 0,
            'non_ai_sessions_included', 0,
            'monthly_session_limit', p_free_monthly_sessions,
            'translations_enabled', FALSE,
            'max_languages', 0,
            'can_buy_overage', FALSE,
            'monthly_fee_usd', 0
        );
    ELSIF v_subscription.tier = 'starter' THEN
        v_tier_details := jsonb_build_object(
            'experience_limit', p_starter_experience_limit,
            'monthly_budget_usd', p_starter_monthly_budget,
            'ai_session_cost_usd', p_starter_ai_session_cost,
            'non_ai_session_cost_usd', p_starter_non_ai_session_cost,
            'ai_sessions_included', FLOOR(p_starter_monthly_budget / p_starter_ai_session_cost),
            'non_ai_sessions_included', FLOOR(p_starter_monthly_budget / p_starter_non_ai_session_cost),
            'monthly_session_limit', NULL,
            'translations_enabled', TRUE,
            'max_languages', 2,
            'can_buy_overage', TRUE,
            'monthly_fee_usd', p_starter_monthly_budget
        );
    ELSIF v_subscription.tier = 'premium' THEN
        v_tier_details := jsonb_build_object(
            'experience_limit', p_premium_experience_limit,
            'monthly_budget_usd', p_premium_monthly_budget,
            'ai_session_cost_usd', p_premium_ai_session_cost,
            'non_ai_session_cost_usd', p_premium_non_ai_session_cost,
            'ai_sessions_included', FLOOR(p_premium_monthly_budget / p_premium_ai_session_cost),
            'non_ai_sessions_included', FLOOR(p_premium_monthly_budget / p_premium_non_ai_session_cost),
            'monthly_session_limit', NULL,
            'translations_enabled', TRUE,
            'max_languages', -1, -- Unlimited
            'can_buy_overage', TRUE,
            'monthly_fee_usd', p_premium_monthly_budget
        );
    END IF;
    
    RETURN jsonb_build_object(
        'id', v_subscription.id,
        'user_id', v_subscription.user_id,
        'tier', v_subscription.tier::TEXT,
        'status', v_subscription.status,
        'stripe_customer_id', v_subscription.stripe_customer_id,
        'stripe_subscription_id', v_subscription.stripe_subscription_id,
        'current_period_start', v_subscription.current_period_start,
        'current_period_end', v_subscription.current_period_end,
        'cancel_at_period_end', v_subscription.cancel_at_period_end,
        'experience_count', v_experience_count,
        'experience_limit', v_tier_details->'experience_limit',
        'monthly_access_limit', COALESCE(v_tier_details->'monthly_session_limit', v_tier_details->'ai_sessions_included'),
        'monthly_access_used', 0, -- Filled by backend/Redis
        'monthly_access_remaining', COALESCE(v_tier_details->'monthly_session_limit', v_tier_details->'ai_sessions_included'),
        'features', jsonb_build_object(
            'translations_enabled', v_tier_details->'translations_enabled',
            'max_languages', v_tier_details->'max_languages',
            'can_buy_overage', v_tier_details->'can_buy_overage'
        ),
        'pricing', jsonb_build_object(
            'monthly_fee_usd', v_tier_details->'monthly_fee_usd',
            'ai_session_cost_usd', v_tier_details->'ai_session_cost_usd',
            'non_ai_session_cost_usd', v_tier_details->'non_ai_session_cost_usd',
            'ai_sessions_included', v_tier_details->'ai_sessions_included',
            'non_ai_sessions_included', v_tier_details->'non_ai_sessions_included',
            'overage_credits_per_batch', p_overage_credits_per_batch,
            'overage_ai_sessions_per_batch', FLOOR(p_overage_credits_per_batch / (v_tier_details->>'ai_session_cost_usd')::DECIMAL),
            'overage_non_ai_sessions_per_batch', FLOOR(p_overage_credits_per_batch / (v_tier_details->>'non_ai_session_cost_usd')::DECIMAL)
        )
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. Update check_premium_subscription_server to include starter
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
    
    -- Check if user has premium OR starter subscription
    SELECT tier::TEXT INTO v_tier
    FROM subscriptions
    WHERE user_id = p_user_id;
    
    RETURN v_tier IN ('premium', 'starter');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grants
GRANT EXECUTE ON FUNCTION can_create_experience(UUID, INTEGER, INTEGER, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION can_use_translations(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_subscription_details(UUID, INTEGER, INTEGER, INTEGER, INTEGER, DECIMAL, DECIMAL, DECIMAL, DECIMAL, DECIMAL, DECIMAL, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION check_premium_subscription_server(UUID) TO service_role;
