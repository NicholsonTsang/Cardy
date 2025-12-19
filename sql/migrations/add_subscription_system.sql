-- =================================================================
-- SUBSCRIPTION SYSTEM MIGRATION
-- Run this in Supabase SQL Editor to add subscription support
-- =================================================================
-- NOTE: All business parameters (limits, rates) are passed from the 
-- Express backend or frontend, NOT hardcoded in stored procedures.
-- =================================================================

-- =================================================================
-- SUBSCRIPTION TIER ENUM
-- =================================================================
DO $$ BEGIN
    CREATE TYPE public."SubscriptionTier" AS ENUM (
        'free',      -- Free tier: limited experiences, daily access, no translations
        'premium'    -- Premium: monthly fee, more experiences, pooled monthly access, translations
    );
EXCEPTION
    WHEN duplicate_object THEN NULL;
    WHEN insufficient_privilege THEN NULL;
END $$;

-- =================================================================
-- SUBSCRIPTIONS TABLE
-- =================================================================
CREATE TABLE IF NOT EXISTS subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE,
    
    -- Subscription status
    tier "SubscriptionTier" NOT NULL DEFAULT 'free',
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'canceled', 'past_due', 'trialing')),
    
    -- Stripe integration
    stripe_customer_id TEXT,
    stripe_subscription_id TEXT UNIQUE,
    stripe_price_id TEXT,
    
    -- Billing cycle
    current_period_start TIMESTAMPTZ,
    current_period_end TIMESTAMPTZ,
    cancel_at_period_end BOOLEAN DEFAULT false,
    canceled_at TIMESTAMPTZ,
    
    -- Usage limits for current period
    monthly_access_limit INTEGER DEFAULT 0, -- 0 for free (uses daily per-experience), configurable for premium
    monthly_access_used INTEGER DEFAULT 0,  -- Counter reset at period start
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_subscriptions_user_id ON subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_tier ON subscriptions(tier);
CREATE INDEX IF NOT EXISTS idx_subscriptions_stripe_customer ON subscriptions(stripe_customer_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_stripe_subscription ON subscriptions(stripe_subscription_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_status ON subscriptions(status);
CREATE INDEX IF NOT EXISTS idx_subscriptions_period_end ON subscriptions(current_period_end);

COMMENT ON TABLE subscriptions IS 'User subscription status and Stripe integration';
COMMENT ON COLUMN subscriptions.tier IS 'free or premium - limits configured via backend environment';
COMMENT ON COLUMN subscriptions.monthly_access_limit IS '0 for free tier (uses per-experience daily), configurable for premium';
COMMENT ON COLUMN subscriptions.monthly_access_used IS 'Resets at each billing period start';

-- =================================================================
-- SUBSCRIPTION USAGE HISTORY (for analytics and billing)
-- =================================================================
CREATE TABLE IF NOT EXISTS subscription_usage_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    subscription_id UUID REFERENCES subscriptions(id) ON DELETE SET NULL,
    
    -- Period info
    period_start TIMESTAMPTZ NOT NULL,
    period_end TIMESTAMPTZ NOT NULL,
    
    -- Usage stats
    included_access_used INTEGER DEFAULT 0,    -- Access within monthly limit
    overage_access_count INTEGER DEFAULT 0,    -- Access beyond monthly limit
    overage_credits_charged DECIMAL(10, 2) DEFAULT 0, -- Credits charged for overage
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_usage_history_user_id ON subscription_usage_history(user_id);
CREATE INDEX IF NOT EXISTS idx_usage_history_period ON subscription_usage_history(period_start, period_end);

-- =================================================================
-- ACCESS LOG TABLE (for detailed tracking)
-- =================================================================
CREATE TABLE IF NOT EXISTS card_access_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    card_id UUID NOT NULL REFERENCES cards(id) ON DELETE CASCADE,
    visitor_hash TEXT NOT NULL,  -- Hash of IP + User-Agent for deduplication
    accessed_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Billing info
    credit_charged BOOLEAN DEFAULT FALSE,
    is_owner_access BOOLEAN DEFAULT FALSE,
    subscription_tier "SubscriptionTier",
    was_overage BOOLEAN DEFAULT FALSE,  -- True if counted as overage access
    
    -- For free tier daily tracking
    card_owner_id UUID REFERENCES auth.users(id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_card_access_log_dedup ON card_access_log(card_id, visitor_hash, accessed_at DESC);
CREATE INDEX IF NOT EXISTS idx_card_access_log_owner ON card_access_log(card_owner_id, accessed_at);
CREATE INDEX IF NOT EXISTS idx_card_access_log_date ON card_access_log(accessed_at);

-- Enable RLS but restrict to service role only
ALTER TABLE card_access_log ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Service role only for card_access_log" ON card_access_log;
CREATE POLICY "Service role only for card_access_log" ON card_access_log FOR ALL USING (false);

-- =================================================================
-- HELPER FUNCTION: Get or create subscription for user
-- =================================================================
CREATE OR REPLACE FUNCTION get_or_create_subscription(p_user_id UUID)
RETURNS subscriptions AS $$
DECLARE
    v_subscription subscriptions%ROWTYPE;
BEGIN
    -- Try to get existing subscription
    SELECT * INTO v_subscription FROM subscriptions WHERE user_id = p_user_id;
    
    -- If not found, create free tier subscription
    IF NOT FOUND THEN
        INSERT INTO subscriptions (user_id, tier, status, monthly_access_limit, monthly_access_used)
        VALUES (p_user_id, 'free', 'active', 0, 0)
        RETURNING * INTO v_subscription;
    END IF;
    
    RETURN v_subscription;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =================================================================
-- FUNCTION: Check if user can create more experiences
-- Parameters are passed from the calling application (backend/frontend)
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
    v_max_experiences INTEGER;
BEGIN
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;
    
    -- Get subscription
    v_subscription := get_or_create_subscription(v_user_id);
    
    -- Count current experiences
    SELECT COUNT(*) INTO v_experience_count 
    FROM cards 
    WHERE user_id = v_user_id;
    
    -- Set limits based on tier (using parameters)
    IF v_subscription.tier = 'premium' THEN
        v_max_experiences := p_premium_limit;
    ELSE
        v_max_experiences := p_free_limit;
    END IF;
    
    RETURN jsonb_build_object(
        'can_create', v_experience_count < v_max_experiences,
        'current_count', v_experience_count,
        'max_allowed', v_max_experiences,
        'tier', v_subscription.tier::TEXT,
        'is_premium', v_subscription.tier = 'premium'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =================================================================
-- FUNCTION: Check if user can use translations
-- =================================================================
CREATE OR REPLACE FUNCTION can_use_translations(p_user_id UUID DEFAULT NULL)
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
        
        -- Usage (both tiers now use monthly limits)
        'monthly_access_limit', v_monthly_limit,
        'monthly_access_used', v_subscription.monthly_access_used,
        'monthly_access_remaining', GREATEST(0, v_monthly_limit - v_subscription.monthly_access_used),
        
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
