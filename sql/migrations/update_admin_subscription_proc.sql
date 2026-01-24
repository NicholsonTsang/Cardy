-- Update admin_update_user_subscription to support starter tier
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
    IF p_new_tier NOT IN ('free', 'starter', 'premium') THEN
        RAISE EXCEPTION 'Invalid tier. Must be: free, starter, or premium.';
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
            stripe_subscription_id = CASE 
                WHEN p_new_tier = 'free' THEN NULL 
                ELSE stripe_subscription_id 
            END,
            current_period_start = CASE 
                WHEN p_new_tier IN ('starter', 'premium') AND stripe_subscription_id IS NULL THEN NOW()
                ELSE current_period_start
            END,
            current_period_end = CASE 
                WHEN p_new_tier IN ('starter', 'premium') AND stripe_subscription_id IS NULL THEN NOW() + INTERVAL '1 year'
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
            CASE WHEN p_new_tier IN ('starter', 'premium') THEN NOW() ELSE NULL END,
            CASE WHEN p_new_tier IN ('starter', 'premium') THEN NOW() + INTERVAL '1 year' ELSE NULL END,
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

