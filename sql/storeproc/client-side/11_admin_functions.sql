-- =================================================================
-- ADMIN FUNCTIONS
-- Functions for admin-only operations and system management
-- =================================================================

-- (Admin) Issue a free batch to a user
CREATE OR REPLACE FUNCTION admin_issue_free_batch(
    p_user_email TEXT,
    p_card_id UUID,
    p_cards_count INTEGER,
    p_reason TEXT DEFAULT 'Admin issued batch'
) RETURNS UUID LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_user_id UUID;
    v_card_record RECORD;
    v_batch_id UUID;
    v_batch_number INTEGER;
    v_batch_name TEXT;
    caller_role TEXT;
BEGIN
    -- Check if the caller is an admin
    SELECT raw_user_meta_data->>'role' INTO caller_role
    FROM auth.users
    WHERE auth.users.id = auth.uid();

    IF caller_role != 'admin' THEN
        RAISE EXCEPTION 'Only admins can issue free batches.';
    END IF;

    -- Validate cards count
    IF p_cards_count < 1 OR p_cards_count > 10000 THEN
        RAISE EXCEPTION 'Cards count must be between 1 and 10,000.';
    END IF;

    -- Get user by email
    SELECT id INTO v_user_id
    FROM auth.users
    WHERE email = p_user_email;
    
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'User with email % not found.', p_user_email;
    END IF;

    -- Get card information and verify ownership
    SELECT c.* INTO v_card_record
    FROM cards c
    WHERE c.id = p_card_id AND c.user_id = v_user_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Card not found or does not belong to user %.', p_user_email;
    END IF;

    -- Get next batch number for this card
    SELECT COALESCE(MAX(batch_number), 0) + 1 INTO v_batch_number
    FROM card_batches
    WHERE card_id = p_card_id;

    -- Auto-generate batch name
    v_batch_name := 'Batch #' || v_batch_number || ' - Issued by Admin';

    -- Generate new batch ID
    v_batch_id := gen_random_uuid();

    -- Create the batch with payment_required = FALSE (free batch)
    INSERT INTO card_batches (
        id,
        card_id,
        batch_name,
        batch_number,
        cards_count,
        created_by,
        payment_required,
        payment_completed,
        payment_waived,
        payment_waived_by,
        payment_waived_at,
        payment_waiver_reason,
        cards_generated,
        created_at,
        updated_at
    ) VALUES (
        v_batch_id,
        p_card_id,
        v_batch_name, -- Auto-generated name
        v_batch_number,
        p_cards_count,
        v_user_id, -- Batch owned by the target user
        FALSE, -- No payment required (free batch)
        FALSE, -- Not paid
        TRUE, -- Mark as waived so cards can be generated
        auth.uid(), -- Admin who issued it
        NOW(),
        p_reason,
        FALSE, -- Cards not yet generated
        NOW(),
        NOW()
    );

    -- Generate cards immediately
    PERFORM generate_batch_cards(v_batch_id);

    -- Log operation
    PERFORM log_operation(
        'Admin issued free batch: ' || v_batch_name || 
        ' to user ' || p_user_email || 
        ' (' || p_cards_count || ' cards) - Reason: ' || p_reason
    );

    RETURN v_batch_id;
END;
$$;

-- Enhanced system statistics function
CREATE OR REPLACE FUNCTION admin_get_system_stats_enhanced()
RETURNS TABLE (
    total_users BIGINT,
    total_cards BIGINT,
    total_batches BIGINT,
    total_issued_cards BIGINT,
    total_activated_cards BIGINT,
    pending_payment_batches BIGINT,
    paid_batches BIGINT,
    waived_batches BIGINT,
    print_requests_submitted BIGINT,
    print_requests_processing BIGINT,
    print_requests_shipping BIGINT,
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
    daily_issued_cards BIGINT,
    weekly_issued_cards BIGINT,
    monthly_issued_cards BIGINT,
    -- AUDIT METRICS
    total_audit_entries BIGINT,
    critical_actions_today BIGINT,
    high_severity_actions_week BIGINT,
    unique_admin_users_month BIGINT,
    -- ACCESS MODE METRICS (NEW)
    physical_cards_count BIGINT,
    digital_cards_count BIGINT,
    -- DIGITAL ACCESS METRICS (NEW)
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
    -- SUBSCRIPTION METRICS (NEW)
    total_free_users BIGINT,
    total_premium_users BIGINT,
    active_subscriptions BIGINT,
    estimated_mrr_cents BIGINT,
    -- ACCESS LOG METRICS (NEW)
    monthly_total_accesses BIGINT,
    monthly_overage_accesses BIGINT
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
        (SELECT COUNT(*) FROM card_batches) as total_batches,
        (SELECT COUNT(*) FROM issue_cards) as total_issued_cards,
        (SELECT COUNT(*) FROM issue_cards WHERE active = true) as total_activated_cards,
        -- Payment metrics
        (SELECT COUNT(*) FROM card_batches WHERE payment_required = true AND payment_completed = false AND payment_waived = false) as pending_payment_batches,
        (SELECT COUNT(*) FROM card_batches WHERE payment_completed = true) as paid_batches,
        (SELECT COUNT(*) FROM card_batches WHERE payment_waived = true) as waived_batches,
        -- Print request metrics
        (SELECT COUNT(*) FROM print_requests WHERE status = 'SUBMITTED') as print_requests_submitted,
        (SELECT COUNT(*) FROM print_requests WHERE status = 'PROCESSING') as print_requests_processing,
        (SELECT COUNT(*) FROM print_requests WHERE status = 'SHIPPED') as print_requests_shipping,
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
        (SELECT COUNT(*) FROM issue_cards WHERE created_at >= CURRENT_DATE) as daily_issued_cards,
        (SELECT COUNT(*) FROM issue_cards WHERE created_at >= CURRENT_DATE - INTERVAL '7 days') as weekly_issued_cards,
        (SELECT COUNT(*) FROM issue_cards WHERE created_at >= CURRENT_DATE - INTERVAL '30 days') as monthly_issued_cards,
        -- Operations log metrics
        (SELECT COUNT(*) FROM operations_log) as total_audit_entries,
        (SELECT COUNT(*) FROM operations_log WHERE operation LIKE '%Waived payment%' AND created_at >= CURRENT_DATE) as payment_waivers_today,
        (SELECT COUNT(*) FROM operations_log WHERE operation LIKE '%Changed user role%' AND created_at >= CURRENT_DATE - INTERVAL '7 days') as role_changes_week,
        (SELECT COUNT(DISTINCT user_id) FROM operations_log WHERE user_role = 'admin' AND created_at >= CURRENT_DATE - INTERVAL '30 days') as unique_admin_users_month,
        -- ACCESS MODE METRICS (Physical vs Digital cards)
        (SELECT COUNT(*) FROM cards WHERE billing_type = 'physical') as physical_cards_count,
        (SELECT COUNT(*) FROM cards WHERE billing_type = 'digital') as digital_cards_count,
        -- DIGITAL ACCESS METRICS (Scan counts and credit consumption)
        (SELECT COALESCE(SUM(current_scans), 0)::BIGINT FROM cards WHERE billing_type = 'digital') as total_digital_scans,
        (SELECT COALESCE(SUM(daily_scans), 0)::BIGINT FROM cards WHERE billing_type = 'digital' AND last_scan_date = CURRENT_DATE) as daily_digital_scans,
        (SELECT COALESCE(SUM(cc.quantity), 0)::BIGINT FROM credit_consumptions cc WHERE cc.consumption_type = 'digital_scan' AND cc.created_at >= CURRENT_DATE - INTERVAL '7 days') as weekly_digital_scans,
        (SELECT COALESCE(SUM(cc.quantity), 0)::BIGINT FROM credit_consumptions cc WHERE cc.consumption_type = 'digital_scan' AND cc.created_at >= CURRENT_DATE - INTERVAL '30 days') as monthly_digital_scans,
        (SELECT COALESCE(SUM(cc.total_credits), 0)::NUMERIC FROM credit_consumptions cc WHERE cc.consumption_type = 'digital_scan') as digital_credits_consumed,
        -- CONTENT MODE DISTRIBUTION
        (SELECT COUNT(*) FROM cards WHERE content_mode = 'single') as content_mode_single,
        (SELECT COUNT(*) FROM cards WHERE content_mode = 'list') as content_mode_list,
        (SELECT COUNT(*) FROM cards WHERE content_mode = 'grid') as content_mode_grid,
        (SELECT COUNT(*) FROM cards WHERE content_mode = 'cards') as content_mode_cards,
        (SELECT COUNT(*) FROM cards WHERE is_grouped = true) as is_grouped_count,
        -- SUBSCRIPTION METRICS
        (SELECT COUNT(*) FROM auth.users) - (SELECT COUNT(*) FROM subscriptions WHERE tier = 'premium') as total_free_users,
        (SELECT COUNT(*) FROM subscriptions WHERE tier = 'premium') as total_premium_users,
        (SELECT COUNT(*) FROM subscriptions WHERE tier = 'premium' AND status = 'active') as active_subscriptions,
        (SELECT COUNT(*) * 5000 FROM subscriptions WHERE tier = 'premium' AND status = 'active') as estimated_mrr_cents,
        -- ACCESS LOG METRICS
        (SELECT COUNT(*) FROM card_access_log WHERE accessed_at >= date_trunc('month', CURRENT_DATE)) as monthly_total_accesses,
        (SELECT COUNT(*) FROM card_access_log WHERE accessed_at >= date_trunc('month', CURRENT_DATE) AND was_overage = true) as monthly_overage_accesses;
END;
$$;

-- =================================================================
-- PRINT REQUEST MANAGEMENT
-- =================================================================

-- (Admin) Update print request status
CREATE OR REPLACE FUNCTION admin_update_print_request_status(
    p_request_id UUID,
    p_new_status "PrintRequestStatus",
    p_admin_notes TEXT DEFAULT NULL
)
RETURNS BOOLEAN LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_request_record RECORD;
    caller_role TEXT;
BEGIN
    -- Check if the caller is an admin
    SELECT raw_user_meta_data->>'role' INTO caller_role
    FROM auth.users
    WHERE auth.users.id = auth.uid();

    IF caller_role != 'admin' THEN
        RAISE EXCEPTION 'Only admins can update print request status.';
    END IF;

    -- Get current request details
    SELECT pr.*, c.name as card_name, cb.batch_name
    INTO v_request_record
    FROM print_requests pr
    JOIN card_batches cb ON pr.batch_id = cb.id
    JOIN cards c ON cb.card_id = c.id
    WHERE pr.id = p_request_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Print request not found.';
    END IF;

    -- Update the print request (no more admin_notes field)
    UPDATE print_requests
    SET 
        status = p_new_status,
        updated_at = NOW()
    WHERE id = p_request_id;

    -- Create feedback entry if admin provided notes
    IF p_admin_notes IS NOT NULL AND LENGTH(TRIM(p_admin_notes)) > 0 THEN
        DECLARE
            v_admin_email VARCHAR(255);
        BEGIN
            SELECT email INTO v_admin_email FROM auth.users WHERE auth.users.id = auth.uid();
            
            INSERT INTO print_request_feedbacks (
                print_request_id,
                admin_user_id,
                admin_email,
                message
            ) VALUES (
                p_request_id,
                auth.uid(),
                v_admin_email,
                p_admin_notes
            );
        END;
    END IF;

    -- Log operation
    PERFORM log_operation('Updated print request status to ' || p_new_status || ' for batch: ' || v_request_record.batch_name || ' (Request ID: ' || p_request_id || ')');
    
    RETURN FOUND;
END;
$$;

-- =================================================================
-- BATCH MANAGEMENT
-- =================================================================

-- (Admin) Get batches requiring attention
CREATE OR REPLACE FUNCTION get_admin_batches_requiring_attention()
RETURNS TABLE (
    id UUID,
    card_id UUID,
    card_name TEXT,
    batch_name TEXT,
    batch_number INTEGER,
    cards_count INTEGER,
    created_by UUID,
    user_email VARCHAR(255),
    payment_required BOOLEAN,
    payment_completed BOOLEAN,
    payment_amount_cents INTEGER,
    payment_waived BOOLEAN,
    cards_generated BOOLEAN,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ
) LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    caller_role TEXT;
BEGIN
    -- Check if caller is admin
    SELECT raw_user_meta_data->>'role' INTO caller_role
    FROM auth.users
    WHERE auth.users.id = auth.uid();

    IF caller_role != 'admin' THEN
        RAISE EXCEPTION 'Only admins can view batches requiring attention.';
    END IF;

    RETURN QUERY
    SELECT 
        cb.id,
        cb.card_id,
        c.name AS card_name,
        cb.batch_name,
        cb.batch_number,
        cb.cards_count,
        cb.created_by,
        au.email AS user_email,
        cb.payment_required,
        cb.payment_completed,
        cb.payment_amount_cents,
        cb.payment_waived,
        cb.cards_generated,
        cb.created_at,
        cb.updated_at
    FROM public.card_batches cb
    JOIN public.cards c ON cb.card_id = c.id
    JOIN auth.users au ON cb.created_by = au.id
    WHERE 
        -- Batches that need payment
        (cb.payment_required = true AND cb.payment_completed = false AND cb.payment_waived = false)
        OR
        -- Batches that are paid but cards not generated
        ((cb.payment_completed = true OR cb.payment_waived = true) AND cb.cards_generated = false)
        OR
        -- Batches that have been inactive for more than 7 days
        (cb.updated_at < NOW() - INTERVAL '7 days' AND cb.payment_completed = false AND cb.payment_waived = false)
    ORDER BY cb.created_at DESC;
END;
$$;

-- (Admin) Get all batches with filtering
CREATE OR REPLACE FUNCTION get_admin_all_batches(
    p_email_search TEXT DEFAULT NULL,
    p_payment_status TEXT DEFAULT NULL,
    p_limit INTEGER DEFAULT 100,
    p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
    id UUID,
    batch_number INTEGER,
    user_email VARCHAR(255),
    payment_status TEXT,
    cards_count INTEGER,
    created_at TIMESTAMPTZ
) LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    caller_role TEXT;
BEGIN
    -- Check if caller is admin
    SELECT raw_user_meta_data->>'role' INTO caller_role
    FROM auth.users
    WHERE auth.users.id = auth.uid();

    IF caller_role != 'admin' THEN
        RAISE EXCEPTION 'Only admins can view all batches.';
    END IF;

    RETURN QUERY
    SELECT 
        cb.id,
        cb.batch_number,
        au.email AS user_email,
        CASE 
            WHEN cb.payment_waived = true THEN 'WAIVED'
            WHEN cb.payment_completed = true THEN 'PAID'
            WHEN cb.payment_required = true THEN 'PENDING'
            ELSE 'FREE'
        END AS payment_status,
        cb.cards_count,
        cb.created_at
    FROM public.card_batches cb
    JOIN auth.users au ON cb.created_by = au.id
    WHERE 
        (p_email_search IS NULL OR au.email ILIKE '%' || p_email_search || '%')
        AND
        (p_payment_status IS NULL OR 
         (p_payment_status = 'WAIVED' AND cb.payment_waived = true) OR
         (p_payment_status = 'PAID' AND cb.payment_completed = true AND cb.payment_waived = false) OR
         (p_payment_status = 'PENDING' AND cb.payment_required = true AND cb.payment_completed = false AND cb.payment_waived = false) OR
         (p_payment_status = 'FREE' AND cb.payment_required = false))
    ORDER BY cb.created_at DESC
    LIMIT p_limit OFFSET p_offset;
END;
$$;

-- (Admin) Get all print requests for review
CREATE OR REPLACE FUNCTION get_all_print_requests(
    p_status "PrintRequestStatus" DEFAULT NULL,
    p_search_query TEXT DEFAULT NULL,
    p_limit INTEGER DEFAULT 100,
    p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
    id UUID,
    batch_id UUID,
    user_id UUID,
    user_email TEXT,
    user_public_name TEXT,
    card_name TEXT,
    batch_name TEXT,
    cards_count INTEGER,
    status "PrintRequestStatus",
    shipping_address TEXT,
    contact_email TEXT,
    contact_whatsapp TEXT,
    requested_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ
) LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    caller_role TEXT;
BEGIN
    -- Check if the caller is an admin
    SELECT raw_user_meta_data->>'role' INTO caller_role
    FROM auth.users
    WHERE auth.users.id = auth.uid();

    IF caller_role != 'admin' THEN
        RAISE EXCEPTION 'Only admins can view all print requests.';
    END IF;

    RETURN QUERY
    SELECT 
        pr.id,
        pr.batch_id,
        pr.user_id,
        au.email::text AS user_email,
        SPLIT_PART(au.email, '@', 1)::text AS user_public_name,
        c.name AS card_name,
        cb.batch_name,
        cb.cards_count,
        pr.status,
        pr.shipping_address,
        pr.contact_email,
        pr.contact_whatsapp,
        pr.requested_at,
        pr.updated_at
    FROM print_requests pr
    JOIN card_batches cb ON pr.batch_id = cb.id
    JOIN cards c ON cb.card_id = c.id
    LEFT JOIN auth.users au ON pr.user_id = au.id
    WHERE 
        (p_status IS NULL OR pr.status = p_status)
        AND (p_search_query IS NULL OR (
            au.email ILIKE '%' || p_search_query || '%' OR
            c.name ILIKE '%' || p_search_query || '%' OR
            cb.batch_name ILIKE '%' || p_search_query || '%' OR
            pr.shipping_address ILIKE '%' || p_search_query || '%'
        ))
    ORDER BY pr.requested_at DESC
    LIMIT p_limit OFFSET p_offset;
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
    issued_cards_count INTEGER,
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
        COUNT(DISTINCT ic.id)::INTEGER as issued_cards_count,
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
    LEFT JOIN card_batches cb ON cb.created_by = au.id
    LEFT JOIN issue_cards ic ON ic.batch_id = cb.id
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
    p_reason TEXT
)
RETURNS BOOLEAN
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    caller_role TEXT;
    v_user_email VARCHAR(255);
    v_old_tier TEXT;
    v_subscription_exists BOOLEAN;
BEGIN
    -- Check if the caller is an admin
    SELECT raw_user_meta_data->>'role' INTO caller_role
    FROM auth.users
    WHERE auth.users.id = auth.uid();

    IF caller_role != 'admin' THEN
        RAISE EXCEPTION 'Only admins can update user subscriptions.';
    END IF;

    -- Validate new tier
    IF p_new_tier NOT IN ('free', 'premium') THEN
        RAISE EXCEPTION 'Invalid tier. Must be: free or premium.';
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
    
    -- Get old tier if exists
    IF v_subscription_exists THEN
        SELECT tier::TEXT INTO v_old_tier
        FROM subscriptions
        WHERE user_id = p_user_id;
    ELSE
        v_old_tier := 'free';
    END IF;

    -- Create or update subscription
    IF v_subscription_exists THEN
        UPDATE subscriptions
        SET 
            tier = p_new_tier::"SubscriptionTier",
            status = 'active'::subscription_status,
            -- Clear Stripe fields when admin manually sets tier
            -- (this means it's not a Stripe-managed subscription anymore)
            stripe_subscription_id = CASE 
                WHEN p_new_tier = 'free' THEN NULL 
                ELSE stripe_subscription_id 
            END,
            current_period_start = CASE 
                WHEN p_new_tier = 'premium' AND stripe_subscription_id IS NULL THEN NOW()
                ELSE current_period_start
            END,
            current_period_end = CASE 
                WHEN p_new_tier = 'premium' AND stripe_subscription_id IS NULL THEN NOW() + INTERVAL '1 year'
                ELSE current_period_end
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
            CASE WHEN p_new_tier = 'premium' THEN NOW() ELSE NULL END,
            CASE WHEN p_new_tier = 'premium' THEN NOW() + INTERVAL '1 year' ELSE NULL END,
            false
        );
    END IF;

    -- Log operation
    PERFORM log_operation(
        'Admin changed subscription tier from ' || COALESCE(v_old_tier, 'none') || 
        ' to ' || p_new_tier || ' for user: ' || v_user_email || 
        ' - Reason: ' || p_reason
    );

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
    created_at TIMESTAMPTZ
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
        au.created_at
    FROM auth.users au
    WHERE LOWER(au.email) = LOWER(p_email);
END;
$$;

-- Get all cards for a specific user (admin view)
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
    qr_code_position TEXT,
    content_mode TEXT,
    billing_type TEXT,
    max_scans INT,
    current_scans INT,
    daily_scan_limit INT,
    daily_scans INT,
    batches_count BIGINT,
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
        c.qr_code_position::TEXT,
        c.content_mode::TEXT,
        c.billing_type::TEXT,
        c.max_scans,
        c.current_scans,
        c.daily_scan_limit,
        c.daily_scans,
        COUNT(cb.id)::BIGINT AS batches_count,
        c.created_at,
        c.updated_at,
        au.email::TEXT AS user_email
    FROM cards c
    JOIN auth.users au ON c.user_id = au.id
    LEFT JOIN card_batches cb ON c.id = cb.card_id
    WHERE c.user_id = p_user_id
    GROUP BY c.id, c.name, c.description, c.image_url, c.original_image_url,
             c.crop_parameters, c.conversation_ai_enabled, c.ai_instruction, c.ai_knowledge_base,
             c.qr_code_position, c.content_mode, c.billing_type, c.max_scans, c.current_scans,
             c.daily_scan_limit, c.daily_scans, c.created_at, c.updated_at, au.email
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

-- Get card batches for admin viewing
CREATE OR REPLACE FUNCTION admin_get_card_batches(p_card_id UUID)
RETURNS TABLE (
    id UUID,
    card_id UUID,
    batch_name TEXT,
    batch_number INTEGER,
    payment_status TEXT,
    is_disabled BOOLEAN,
    cards_count BIGINT,
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
        cb.id,
        cb.card_id,
        cb.batch_name,
        cb.batch_number,
        CASE
            WHEN cb.payment_waived THEN 'WAIVED'
            WHEN cb.payment_completed THEN 'PAID'
            WHEN cb.payment_required THEN 'PENDING'
            ELSE 'PENDING'
        END AS payment_status,
        cb.is_disabled,
        COUNT(ic.id) AS cards_count,
        cb.created_at,
        cb.updated_at
    FROM card_batches cb
    LEFT JOIN issue_cards ic ON cb.id = ic.batch_id
    WHERE cb.card_id = p_card_id
    GROUP BY cb.id, cb.card_id, cb.batch_name, cb.batch_number, 
             cb.payment_waived, cb.payment_completed, cb.payment_required, 
             cb.is_disabled, cb.created_at, cb.updated_at
    ORDER BY cb.created_at DESC;
END;
$$;

-- Get issued cards for a batch (admin view)
CREATE OR REPLACE FUNCTION admin_get_batch_issued_cards(p_batch_id UUID)
RETURNS TABLE (
    id UUID,
    batch_id UUID,
    card_id UUID,
    active BOOLEAN,
    issue_at TIMESTAMPTZ,
    active_at TIMESTAMPTZ
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
        ic.id,
        ic.batch_id,
        ic.card_id,
        ic.active,
        ic.issue_at,
        ic.active_at
    FROM issue_cards ic
    WHERE ic.batch_id = p_batch_id
    ORDER BY ic.issue_at DESC;
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

GRANT EXECUTE ON FUNCTION get_admin_audit_logs(TEXT, UUID, INTEGER, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION admin_update_user_subscription(UUID, TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION admin_get_subscription_stats() TO authenticated;