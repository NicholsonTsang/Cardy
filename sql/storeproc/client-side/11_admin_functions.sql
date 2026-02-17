-- =================================================================
-- ADMIN FUNCTIONS
-- Functions for admin-only operations and system management
-- =================================================================

-- Enhanced system statistics function
CREATE OR REPLACE FUNCTION admin_get_system_stats_enhanced()
RETURNS TABLE (
    total_users BIGINT,
    total_cards BIGINT,
    daily_revenue_cents BIGINT,
    weekly_revenue_cents BIGINT,
    monthly_revenue_cents BIGINT,
    total_revenue_cents BIGINT,
    daily_new_users BIGINT,
    weekly_new_users BIGINT,
    monthly_new_users BIGINT,
    daily_new_cards BIGINT,
    weekly_new_cards BIGINT,
    monthly_new_cards BIGINT,
    -- AUDIT METRICS
    total_audit_entries BIGINT,
    critical_actions_today BIGINT,
    high_severity_actions_week BIGINT,
    unique_admin_users_month BIGINT,
    -- CARDS COUNT
    digital_cards_count BIGINT,
    -- ACCESS METRICS (from card_access_tokens and card_access_log)
    total_digital_scans BIGINT,
    daily_digital_scans BIGINT,
    weekly_digital_scans BIGINT,
    monthly_digital_scans BIGINT,
    digital_credits_consumed NUMERIC,
    -- CONTENT MODE DISTRIBUTION
    content_mode_single BIGINT,
    content_mode_list BIGINT,
    content_mode_grid BIGINT,
    content_mode_cards BIGINT,
    is_grouped_count BIGINT,
    -- SUBSCRIPTION METRICS (4 tiers: free, starter, premium, enterprise)
    total_free_users BIGINT,
    total_starter_users BIGINT,
    total_premium_users BIGINT,
    total_enterprise_users BIGINT,
    active_subscriptions BIGINT,
    estimated_mrr_cents BIGINT,
    -- ACCESS LOG METRICS
    monthly_total_accesses BIGINT,
    monthly_overage_accesses BIGINT,
    -- QR CODE METRICS (Multi-QR system)
    total_qr_codes BIGINT,
    active_qr_codes BIGINT
) LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    caller_role TEXT;
BEGIN
    -- Check if the caller is an admin
    SELECT raw_user_meta_data->>'role' INTO caller_role
    FROM auth.users
    WHERE auth.users.id = auth.uid();

    IF caller_role != 'admin' THEN
        RAISE EXCEPTION 'Only admins can view system statistics.';
    END IF;

    RETURN QUERY
    SELECT
        -- User and content metrics
        (SELECT COUNT(*) FROM auth.users) as total_users,
        (SELECT COUNT(*) FROM cards) as total_cards,
        -- Revenue metrics (based on credit purchases + estimated MRR)
        -- Note: credit_purchases amount_usd is in dollars, so multiply by 100 to get cents
        (SELECT COALESCE(SUM(amount_usd * 100), 0)::BIGINT FROM credit_purchases WHERE status = 'completed' AND created_at >= CURRENT_DATE) as daily_revenue_cents,
        (SELECT COALESCE(SUM(amount_usd * 100), 0)::BIGINT FROM credit_purchases WHERE status = 'completed' AND created_at >= CURRENT_DATE - INTERVAL '7 days') as weekly_revenue_cents,
        (SELECT COALESCE(SUM(amount_usd * 100), 0)::BIGINT FROM credit_purchases WHERE status = 'completed' AND created_at >= CURRENT_DATE - INTERVAL '30 days') as monthly_revenue_cents,
        (SELECT COALESCE(SUM(amount_usd * 100), 0)::BIGINT FROM credit_purchases WHERE status = 'completed') as total_revenue_cents,
        -- Growth metrics
        (SELECT COUNT(*) FROM auth.users WHERE created_at >= CURRENT_DATE) as daily_new_users,
        (SELECT COUNT(*) FROM auth.users WHERE created_at >= CURRENT_DATE - INTERVAL '7 days') as weekly_new_users,
        (SELECT COUNT(*) FROM auth.users WHERE created_at >= CURRENT_DATE - INTERVAL '30 days') as monthly_new_users,
        (SELECT COUNT(*) FROM cards WHERE created_at >= CURRENT_DATE) as daily_new_cards,
        (SELECT COUNT(*) FROM cards WHERE created_at >= CURRENT_DATE - INTERVAL '7 days') as weekly_new_cards,
        (SELECT COUNT(*) FROM cards WHERE created_at >= CURRENT_DATE - INTERVAL '30 days') as monthly_new_cards,
        -- Operations log metrics
        (SELECT COUNT(*) FROM operations_log) as total_audit_entries,
        (SELECT COUNT(*) FROM operations_log WHERE operation LIKE '%Waived payment%' AND created_at >= CURRENT_DATE) as payment_waivers_today,
        (SELECT COUNT(*) FROM operations_log WHERE operation LIKE '%Changed user role%' AND created_at >= CURRENT_DATE - INTERVAL '7 days') as role_changes_week,
        (SELECT COUNT(DISTINCT user_id) FROM operations_log WHERE user_role = 'admin' AND created_at >= CURRENT_DATE - INTERVAL '30 days') as unique_admin_users_month,
        -- CARDS COUNT
        (SELECT COUNT(*) FROM cards) as digital_cards_count,
        -- ACCESS METRICS (from card_access_tokens and card_access_log)
        -- Note: Session counters now live in card_access_tokens table (Multi-QR refactor Dec 2025)
        (SELECT COALESCE(SUM(cat.total_sessions), 0)::BIGINT FROM card_access_tokens cat) as total_digital_scans,
        (SELECT COALESCE(SUM(cat.daily_sessions), 0)::BIGINT FROM card_access_tokens cat WHERE cat.last_session_date = CURRENT_DATE) as daily_digital_scans,
        -- Weekly/Monthly from card_access_log for consistency (source of truth for billing)
        (SELECT COUNT(*) FROM card_access_log WHERE accessed_at >= CURRENT_DATE - INTERVAL '7 days') as weekly_digital_scans,
        (SELECT COUNT(*) FROM card_access_log WHERE accessed_at >= CURRENT_DATE - INTERVAL '30 days') as monthly_digital_scans,
        -- Total session cost from access log (ai_enabled costs more)
        (SELECT COALESCE(SUM(session_cost_usd), 0)::NUMERIC FROM card_access_log) as digital_credits_consumed,
        -- CONTENT MODE DISTRIBUTION
        (SELECT COUNT(*) FROM cards WHERE content_mode = 'single') as content_mode_single,
        (SELECT COUNT(*) FROM cards WHERE content_mode = 'list') as content_mode_list,
        (SELECT COUNT(*) FROM cards WHERE content_mode = 'grid') as content_mode_grid,
        (SELECT COUNT(*) FROM cards WHERE content_mode = 'cards') as content_mode_cards,
        (SELECT COUNT(*) FROM cards WHERE is_grouped = true) as is_grouped_count,
        -- SUBSCRIPTION METRICS (4 tiers: free, starter, premium, enterprise)
        -- Free = users with no subscription record OR tier = 'free'
        (SELECT COUNT(*) FROM auth.users u WHERE NOT EXISTS (SELECT 1 FROM subscriptions s WHERE s.user_id = u.id AND s.tier IN ('starter', 'premium', 'enterprise'))) as total_free_users,
        (SELECT COUNT(*) FROM subscriptions WHERE tier = 'starter') as total_starter_users,
        (SELECT COUNT(*) FROM subscriptions WHERE tier = 'premium') as total_premium_users,
        (SELECT COUNT(*) FROM subscriptions WHERE tier = 'enterprise') as total_enterprise_users,
        (SELECT COUNT(*) FROM subscriptions WHERE tier IN ('starter', 'premium', 'enterprise') AND status = 'active') as active_subscriptions,
        -- MRR: Starter=$40/month (4000 cents) + Premium=$280/month (28000 cents) + Enterprise=$1000/month (100000 cents)
        (
            (SELECT COUNT(*) * 4000 FROM subscriptions WHERE tier = 'starter' AND status = 'active') +
            (SELECT COUNT(*) * 28000 FROM subscriptions WHERE tier = 'premium' AND status = 'active') +
            (SELECT COUNT(*) * 100000 FROM subscriptions WHERE tier = 'enterprise' AND status = 'active')
        )::BIGINT as estimated_mrr_cents,
        -- ACCESS LOG METRICS
        (SELECT COUNT(*) FROM card_access_log WHERE accessed_at >= date_trunc('month', CURRENT_DATE)) as monthly_total_accesses,
        (SELECT COUNT(*) FROM card_access_log WHERE accessed_at >= date_trunc('month', CURRENT_DATE) AND was_overage = true) as monthly_overage_accesses,
        -- QR CODE METRICS (Multi-QR system)
        (SELECT COUNT(*) FROM card_access_tokens) as total_qr_codes,
        (SELECT COUNT(*) FROM card_access_tokens WHERE is_enabled = true) as active_qr_codes;
END;
$$;

-- =================================================================
-- USER MANAGEMENT FUNCTIONS
-- =================================================================

-- Get all users with basic info, activity stats, and subscription data
CREATE OR REPLACE FUNCTION admin_get_all_users()
RETURNS TABLE (
    user_id UUID,
    user_email VARCHAR(255),
    role TEXT,
    cards_count INTEGER,
    created_at TIMESTAMP WITH TIME ZONE,
    last_sign_in_at TIMESTAMP WITH TIME ZONE,
    email_confirmed_at TIMESTAMP WITH TIME ZONE,
    -- Subscription fields
    subscription_tier TEXT,
    subscription_status TEXT,
    stripe_subscription_id TEXT,
    current_period_start TIMESTAMPTZ,
    current_period_end TIMESTAMPTZ,
    cancel_at_period_end BOOLEAN
)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    caller_role TEXT;
BEGIN
    -- Check if the caller is an admin
    SELECT raw_user_meta_data->>'role' INTO caller_role
    FROM auth.users
    WHERE auth.users.id = auth.uid();

    IF caller_role != 'admin' THEN
        RAISE EXCEPTION 'Only admins can view all users.';
    END IF;

    RETURN QUERY
    SELECT
        au.id as user_id,
        au.email as user_email,
        COALESCE(au.raw_user_meta_data->>'role', 'cardIssuer') as role,
        COUNT(DISTINCT c.id)::INTEGER as cards_count,
        au.created_at,
        au.last_sign_in_at,
        au.email_confirmed_at,
        -- Subscription data (default to 'free' if no subscription)
        COALESCE(s.tier::TEXT, 'free') as subscription_tier,
        COALESCE(s.status::TEXT, 'active') as subscription_status,
        s.stripe_subscription_id,
        s.current_period_start,
        s.current_period_end,
        COALESCE(s.cancel_at_period_end, false) as cancel_at_period_end
    FROM auth.users au
    LEFT JOIN cards c ON c.user_id = au.id
    LEFT JOIN subscriptions s ON s.user_id = au.id
    GROUP BY au.id, au.email, au.raw_user_meta_data, au.created_at, au.last_sign_in_at,
             au.email_confirmed_at, s.tier, s.status, s.stripe_subscription_id,
             s.current_period_start, s.current_period_end, s.cancel_at_period_end
    ORDER BY au.created_at DESC;
END;
$$;

-- Update user subscription tier (admin only)
-- This creates or updates a subscription record for manual tier management
CREATE OR REPLACE FUNCTION admin_update_user_subscription(
    p_user_id UUID,
    p_new_tier TEXT,
    p_reason TEXT,
    p_duration_months INTEGER DEFAULT NULL  -- NULL = permanent, number = specific months
)
RETURNS BOOLEAN
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    caller_role TEXT;
    v_user_email VARCHAR(255);
    v_old_tier TEXT;
    v_subscription_exists BOOLEAN;
    v_period_end TIMESTAMPTZ;
    v_duration_text TEXT;
BEGIN
    -- Check if the caller is an admin
    SELECT raw_user_meta_data->>'role' INTO caller_role
    FROM auth.users
    WHERE auth.users.id = auth.uid();

    IF caller_role != 'admin' THEN
        RAISE EXCEPTION 'Only admins can update user subscriptions.';
    END IF;

    -- Validate new tier
    IF p_new_tier NOT IN ('free', 'starter', 'premium', 'enterprise') THEN
        RAISE EXCEPTION 'Invalid tier. Must be: free, starter, premium, or enterprise.';
    END IF;

    -- Validate duration (must be positive if provided)
    IF p_duration_months IS NOT NULL AND p_duration_months <= 0 THEN
        RAISE EXCEPTION 'Duration must be a positive number of months.';
    END IF;

    -- Get current user info
    SELECT email INTO v_user_email
    FROM auth.users
    WHERE id = p_user_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'User not found.';
    END IF;

    -- Check if subscription exists
    SELECT EXISTS(SELECT 1 FROM subscriptions WHERE user_id = p_user_id) INTO v_subscription_exists;
    
    -- Block if user has active Stripe subscription (mutually exclusive with admin grants)
    IF v_subscription_exists THEN
        PERFORM 1 FROM subscriptions 
        WHERE user_id = p_user_id 
        AND stripe_subscription_id IS NOT NULL;
        
        IF FOUND THEN
            RAISE EXCEPTION 'Cannot grant privilege to user with active Stripe subscription. Please cancel their Stripe subscription first via Stripe Dashboard.';
        END IF;
    END IF;
    
    -- Get old tier if exists
    IF v_subscription_exists THEN
        SELECT tier::TEXT INTO v_old_tier
        FROM subscriptions
        WHERE user_id = p_user_id;
    ELSE
        v_old_tier := 'free';
    END IF;

    -- Calculate period end based on duration
    -- For paid tiers (starter/premium): use duration or NULL for permanent
    -- For free tier: always NULL (no period)
    IF p_new_tier = 'free' THEN
        v_period_end := NULL;
    ELSIF p_duration_months IS NULL THEN
        -- Permanent subscription (far future date)
        v_period_end := NOW() + INTERVAL '100 years';
    ELSE
        -- Specific duration
        v_period_end := NOW() + (p_duration_months || ' months')::INTERVAL;
    END IF;

    -- Create or update subscription (Stripe users already blocked above)
    IF v_subscription_exists THEN
        UPDATE subscriptions
        SET 
            tier = p_new_tier::"SubscriptionTier",
            status = 'active'::subscription_status,
            -- stripe_subscription_id stays NULL (admin-managed only)
            current_period_start = CASE 
                WHEN p_new_tier IN ('starter', 'premium', 'enterprise') THEN NOW()
                ELSE NULL
            END,
            current_period_end = CASE 
                WHEN p_new_tier IN ('starter', 'premium', 'enterprise') THEN v_period_end
                ELSE NULL
            END,
            cancel_at_period_end = false,
            updated_at = NOW()
        WHERE user_id = p_user_id;
    ELSE
        INSERT INTO subscriptions (
            user_id,
            tier,
            status,
            current_period_start,
            current_period_end,
            cancel_at_period_end
        ) VALUES (
            p_user_id,
            p_new_tier::"SubscriptionTier",
            'active'::subscription_status,
            CASE WHEN p_new_tier IN ('starter', 'premium', 'enterprise') THEN NOW() ELSE NULL END,
            CASE WHEN p_new_tier IN ('starter', 'premium', 'enterprise') THEN v_period_end ELSE NULL END,
            false
        );
    END IF;

    -- Build duration text for log
    IF p_new_tier = 'free' THEN
        v_duration_text := '';
    ELSIF p_duration_months IS NULL THEN
        v_duration_text := ' (permanent)';
    ELSE
        v_duration_text := ' (' || p_duration_months || ' months)';
    END IF;

    -- Log operation
    IF v_old_tier = p_new_tier THEN
        -- Same tier - just updating duration
        PERFORM log_operation(
            'Admin updated ' || p_new_tier || ' subscription duration' || v_duration_text || 
            ' for user: ' || v_user_email || ' - Reason: ' || p_reason
        );
    ELSE
        -- Tier change
        PERFORM log_operation(
            'Admin changed subscription tier from ' || COALESCE(v_old_tier, 'none') || 
            ' to ' || p_new_tier || v_duration_text || ' for user: ' || v_user_email || 
            ' - Reason: ' || p_reason
        );
    END IF;

    RETURN TRUE;
END;
$$;

-- Get subscription statistics for admin dashboard
CREATE OR REPLACE FUNCTION admin_get_subscription_stats()
RETURNS TABLE (
    total_users BIGINT,
    free_users BIGINT,
    premium_users BIGINT,
    active_premium BIGINT,
    canceled_pending BIGINT,
    past_due BIGINT,
    estimated_mrr_cents BIGINT
)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    caller_role TEXT;
BEGIN
    -- Check if the caller is an admin
    SELECT raw_user_meta_data->>'role' INTO caller_role
    FROM auth.users
    WHERE auth.users.id = auth.uid();

    IF caller_role != 'admin' THEN
        RAISE EXCEPTION 'Only admins can view subscription statistics.';
    END IF;

    RETURN QUERY
    SELECT 
        (SELECT COUNT(*) FROM auth.users) as total_users,
        (SELECT COUNT(*) FROM auth.users) - (SELECT COUNT(*) FROM subscriptions WHERE tier = 'premium') as free_users,
        (SELECT COUNT(*) FROM subscriptions WHERE tier = 'premium') as premium_users,
        (SELECT COUNT(*) FROM subscriptions WHERE tier = 'premium' AND status = 'active' AND cancel_at_period_end = false) as active_premium,
        (SELECT COUNT(*) FROM subscriptions WHERE tier = 'premium' AND cancel_at_period_end = true) as canceled_pending,
        (SELECT COUNT(*) FROM subscriptions WHERE status = 'past_due') as past_due,
        (SELECT COUNT(*) * 5000 FROM subscriptions WHERE tier = 'premium' AND status = 'active') as estimated_mrr_cents;
END;
$$;

-- Update user role
CREATE OR REPLACE FUNCTION admin_update_user_role(
    p_user_id UUID,
    p_new_role TEXT,
    p_reason TEXT
)
RETURNS BOOLEAN
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    caller_role TEXT;
    v_user_email VARCHAR(255);
    v_old_role TEXT;
BEGIN
    -- Check if the caller is an admin
    SELECT raw_user_meta_data->>'role' INTO caller_role
    FROM auth.users
    WHERE auth.users.id = auth.uid();

    IF caller_role != 'admin' THEN
        RAISE EXCEPTION 'Only admins can update user roles.';
    END IF;

    -- Validate new role
    IF p_new_role NOT IN ('admin', 'cardIssuer', 'user') THEN
        RAISE EXCEPTION 'Invalid role. Must be: admin, cardIssuer, or user.';
    END IF;

    -- Get current user info
    SELECT email, raw_user_meta_data->>'role' 
    INTO v_user_email, v_old_role
    FROM auth.users
    WHERE id = p_user_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'User not found.';
    END IF;

    -- Update user role in auth.users metadata
    UPDATE auth.users
    SET raw_user_meta_data = jsonb_set(
        COALESCE(raw_user_meta_data, '{}'::jsonb),
        '{role}',
        to_jsonb(p_new_role)
    ),
    updated_at = NOW()
    WHERE id = p_user_id;

    -- Log operation
    PERFORM log_operation('Changed user role from ' || COALESCE(v_old_role, 'none') || ' to ' || p_new_role || ' for user: ' || v_user_email);

    RETURN TRUE;
END;
$$;

-- =================================================================
-- ADMIN USER CARD VIEWING FUNCTIONS
-- Functions for admins to view user cards (read-only)
-- =================================================================

-- Get user ID by email
CREATE OR REPLACE FUNCTION admin_get_user_by_email(p_email TEXT)
RETURNS TABLE (
    user_id UUID,
    email TEXT,
    role TEXT,
    created_at TIMESTAMPTZ,
    subscription_tier TEXT,
    subscription_status TEXT
) LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_caller_role TEXT;
BEGIN
    -- Check if caller is admin
    SELECT raw_user_meta_data->>'role' INTO v_caller_role
    FROM auth.users
    WHERE auth.users.id = auth.uid();
    
    IF v_caller_role != 'admin' THEN
        RAISE EXCEPTION 'Admin access required';
    END IF;

    RETURN QUERY
    SELECT 
        au.id AS user_id,
        au.email::TEXT,
        COALESCE(au.raw_user_meta_data->>'role', 'user')::TEXT AS role,
        au.created_at,
        COALESCE(s.tier::TEXT, 'free') as subscription_tier,
        COALESCE(s.status::TEXT, 'active') as subscription_status
    FROM auth.users au
    LEFT JOIN subscriptions s ON s.user_id = au.id
    WHERE LOWER(au.email) = LOWER(p_email);
END;
$$;

-- Get all cards for a specific user (admin view)
-- Updated to aggregate session data from card_access_tokens
CREATE OR REPLACE FUNCTION admin_get_user_cards(p_user_id UUID)
RETURNS TABLE (
    id UUID,
    card_name TEXT,
    name TEXT,
    description TEXT,
    image_url TEXT,
    original_image_url TEXT,
    crop_parameters JSONB,
    conversation_ai_enabled BOOLEAN,
    ai_instruction TEXT,
    ai_knowledge_base TEXT,
    ai_welcome_general TEXT,
    ai_welcome_item TEXT,
    qr_code_position TEXT,
    content_mode TEXT,
    is_grouped BOOLEAN,
    group_display TEXT,
    default_daily_session_limit INT,
    metadata JSONB,
    -- Aggregated from access tokens
    total_sessions BIGINT,
    daily_sessions BIGINT,
    active_qr_codes BIGINT,
    total_qr_codes BIGINT,
    translations JSONB,
    original_language VARCHAR(10),
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ,
    user_email TEXT
) LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_caller_role TEXT;
BEGIN
    -- Check if caller is admin
    SELECT raw_user_meta_data->>'role' INTO v_caller_role
    FROM auth.users
    WHERE auth.users.id = auth.uid();
    
    IF v_caller_role != 'admin' THEN
        RAISE EXCEPTION 'Admin access required';
    END IF;

    RETURN QUERY
    SELECT 
        c.id, 
        c.name AS card_name,
        c.name, 
        c.description, 
        c.image_url, 
        c.original_image_url,
        c.crop_parameters,
        c.conversation_ai_enabled,
        c.ai_instruction,
        c.ai_knowledge_base,
        c.ai_welcome_general,
        c.ai_welcome_item,
        c.qr_code_position::TEXT,
        c.content_mode::TEXT,
        c.is_grouped,
        c.group_display::TEXT,
        c.default_daily_session_limit,
        c.metadata,
        -- Aggregate from access tokens
        COALESCE(SUM(t.total_sessions), 0)::BIGINT AS total_sessions,
        COALESCE(SUM(t.daily_sessions), 0)::BIGINT AS daily_sessions,
        COALESCE(COUNT(t.id) FILTER (WHERE t.is_enabled), 0)::BIGINT AS active_qr_codes,
        COALESCE(COUNT(t.id), 0)::BIGINT AS total_qr_codes,
        c.translations,
        c.original_language,
        c.created_at,
        c.updated_at,
        au.email::TEXT AS user_email
    FROM cards c
    JOIN auth.users au ON c.user_id = au.id
    LEFT JOIN card_access_tokens t ON t.card_id = c.id
    WHERE c.user_id = p_user_id
    GROUP BY c.id, c.name, c.description, c.image_url, c.original_image_url,
             c.crop_parameters, c.conversation_ai_enabled, c.ai_instruction, c.ai_knowledge_base,
             c.ai_welcome_general, c.ai_welcome_item, c.qr_code_position, c.content_mode,
             c.is_grouped, c.group_display, c.default_daily_session_limit, c.metadata,
             c.translations, c.original_language, c.created_at, c.updated_at, au.email
    ORDER BY c.created_at DESC;
END;
$$;

-- Get card content items for admin viewing
CREATE OR REPLACE FUNCTION admin_get_card_content(p_card_id UUID)
RETURNS TABLE (
    id UUID,
    card_id UUID,
    parent_id UUID,
    name TEXT,
    content TEXT,
    image_url TEXT,
    original_image_url TEXT,
    crop_parameters JSONB,
    ai_knowledge_base TEXT,
    sort_order INTEGER,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ
) LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_caller_role TEXT;
BEGIN
    -- Check if caller is admin
    SELECT raw_user_meta_data->>'role' INTO v_caller_role
    FROM auth.users
    WHERE auth.users.id = auth.uid();
    
    IF v_caller_role != 'admin' THEN
        RAISE EXCEPTION 'Admin access required';
    END IF;

    RETURN QUERY
    SELECT 
        ci.id, 
        ci.card_id,
        ci.parent_id,
        ci.name, 
        ci.content, 
        ci.image_url, 
        ci.original_image_url,
        ci.crop_parameters,
        ci.ai_knowledge_base,
        ci.sort_order,
        ci.created_at,
        ci.updated_at
    FROM content_items ci
    WHERE ci.card_id = p_card_id
    ORDER BY 
        CASE WHEN ci.parent_id IS NULL THEN ci.sort_order ELSE 999999 END,
        ci.parent_id NULLS FIRST,
        ci.sort_order ASC,
        ci.created_at ASC;
END;
$$;

-- =================================================================
-- AUDIT LOG FUNCTIONS
-- =================================================================

-- Get admin audit logs (wraps operations_log for admin dashboard)
-- Note: operations_log has simple structure: user_id, user_role, operation, created_at
CREATE OR REPLACE FUNCTION get_admin_audit_logs(
    p_action_type TEXT DEFAULT NULL,
    p_admin_user_id UUID DEFAULT NULL,
    p_limit INTEGER DEFAULT 50,
    p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
    id UUID,
    user_id UUID,
    user_email TEXT,
    user_role "UserRole",
    operation TEXT,
    created_at TIMESTAMPTZ
) AS $$
DECLARE
    v_caller_role TEXT;
BEGIN
    -- Check if caller is admin
    SELECT raw_user_meta_data->>'role' INTO v_caller_role
    FROM auth.users
    WHERE auth.users.id = auth.uid();
    
    IF v_caller_role != 'admin' THEN
        RAISE EXCEPTION 'Only admins can view audit logs';
    END IF;
    
    -- Return from operations_log table
    RETURN QUERY
    SELECT 
        ol.id,
        ol.user_id,
        au.email::TEXT AS user_email,
        ol.user_role,
        ol.operation,
        ol.created_at
    FROM operations_log ol
    LEFT JOIN auth.users au ON ol.user_id = au.id
    WHERE (p_action_type IS NULL OR ol.operation ILIKE '%' || p_action_type || '%')
      AND (p_admin_user_id IS NULL OR ol.user_id = p_admin_user_id)
    ORDER BY ol.created_at DESC
    LIMIT p_limit
    OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =================================================================
-- GRANT STATEMENTS FOR ADMIN FUNCTIONS
-- =================================================================
-- All admin functions use SECURITY DEFINER and check role internally
-- They must be callable by authenticated users, but actual admin check
-- happens inside each function via auth.uid() role lookup

GRANT EXECUTE ON FUNCTION admin_get_system_stats_enhanced() TO authenticated;
GRANT EXECUTE ON FUNCTION admin_get_all_users() TO authenticated;
GRANT EXECUTE ON FUNCTION admin_update_user_subscription(UUID, TEXT, TEXT, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION admin_get_subscription_stats() TO authenticated;
GRANT EXECUTE ON FUNCTION admin_update_user_role(UUID, TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION admin_get_user_by_email(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION admin_get_user_cards(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION admin_get_card_content(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_admin_audit_logs(TEXT, UUID, INTEGER, INTEGER) TO authenticated;