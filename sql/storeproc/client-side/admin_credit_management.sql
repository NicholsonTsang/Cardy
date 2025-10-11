-- Admin Credit Management Stored Procedures
-- Admin functions for credit system auditing and management

-- Admin: Get all credit purchases
CREATE OR REPLACE FUNCTION admin_get_credit_purchases(
    p_limit INTEGER DEFAULT 50,
    p_offset INTEGER DEFAULT 0,
    p_user_id UUID DEFAULT NULL,
    p_status VARCHAR DEFAULT NULL
)
RETURNS TABLE (
    id UUID,
    user_id UUID,
    user_email TEXT,
    user_name TEXT,
    amount_usd DECIMAL,
    credits_amount DECIMAL,
    status VARCHAR,
    stripe_session_id VARCHAR,
    payment_method JSONB,
    receipt_url TEXT,
    created_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ
) AS $$
DECLARE
    v_user_id UUID;
    v_role VARCHAR;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    -- Check if user is admin
    SELECT raw_user_meta_data->>'role' INTO v_role
    FROM auth.users
    WHERE auth.users.id = v_user_id;

    IF v_role != 'admin' THEN
        RAISE EXCEPTION 'Unauthorized: Admin access required';
    END IF;

    RETURN QUERY
    SELECT 
        cp.id,
        cp.user_id,
        u.email::TEXT AS user_email,
        COALESCE(u.raw_user_meta_data->>'full_name', u.email)::TEXT AS user_name,
        cp.amount_usd,
        cp.credits_amount,
        cp.status,
        cp.stripe_session_id,
        cp.payment_method,
        cp.receipt_url,
        cp.created_at,
        cp.completed_at
    FROM credit_purchases cp
    JOIN auth.users u ON u.id = cp.user_id
    WHERE (p_user_id IS NULL OR cp.user_id = p_user_id)
        AND (p_status IS NULL OR cp.status = p_status)
    ORDER BY cp.created_at DESC
    LIMIT p_limit
    OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Admin: Get all credit consumptions
CREATE OR REPLACE FUNCTION admin_get_credit_consumptions(
    p_limit INTEGER DEFAULT 50,
    p_offset INTEGER DEFAULT 0,
    p_user_id UUID DEFAULT NULL,
    p_date_from TIMESTAMPTZ DEFAULT NULL,
    p_date_to TIMESTAMPTZ DEFAULT NULL
)
RETURNS TABLE (
    id UUID,
    user_id UUID,
    user_email TEXT,
    user_name TEXT,
    batch_id UUID,
    batch_name TEXT,
    card_id UUID,
    card_name TEXT,
    consumption_type VARCHAR,
    quantity INTEGER,
    credits_per_unit DECIMAL,
    total_credits DECIMAL,
    description TEXT,
    created_at TIMESTAMPTZ
) AS $$
DECLARE
    v_user_id UUID;
    v_role VARCHAR;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    -- Check if user is admin
    SELECT raw_user_meta_data->>'role' INTO v_role
    FROM auth.users
    WHERE auth.users.id = v_user_id;

    IF v_role != 'admin' THEN
        RAISE EXCEPTION 'Unauthorized: Admin access required';
    END IF;

    RETURN QUERY
    SELECT 
        cc.id,
        cc.user_id,
        u.email::TEXT AS user_email,
        COALESCE(u.raw_user_meta_data->>'full_name', u.email)::TEXT AS user_name,
        cc.batch_id,
        b.batch_name AS batch_name,
        cc.card_id,
        c.name AS card_name,
        cc.consumption_type,
        cc.quantity,
        cc.credits_per_unit,
        cc.total_credits,
        cc.description,
        cc.created_at
    FROM credit_consumptions cc
    JOIN auth.users u ON u.id = cc.user_id
    LEFT JOIN card_batches b ON b.id = cc.batch_id
    LEFT JOIN cards c ON c.id = cc.card_id
    WHERE (p_user_id IS NULL OR cc.user_id = p_user_id)
        AND (p_date_from IS NULL OR cc.created_at >= p_date_from)
        AND (p_date_to IS NULL OR cc.created_at <= p_date_to)
    ORDER BY cc.created_at DESC
    LIMIT p_limit
    OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Admin: Get all credit transactions
CREATE OR REPLACE FUNCTION admin_get_credit_transactions(
    p_limit INTEGER DEFAULT 50,
    p_offset INTEGER DEFAULT 0,
    p_user_id UUID DEFAULT NULL,
    p_type VARCHAR DEFAULT NULL
)
RETURNS TABLE (
    id UUID,
    user_id UUID,
    user_email TEXT,
    user_name TEXT,
    type VARCHAR,
    amount DECIMAL,
    balance_before DECIMAL,
    balance_after DECIMAL,
    reference_type VARCHAR,
    reference_id UUID,
    description TEXT,
    metadata JSONB,
    created_at TIMESTAMPTZ
) AS $$
DECLARE
    v_user_id UUID;
    v_role VARCHAR;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    -- Check if user is admin
    SELECT raw_user_meta_data->>'role' INTO v_role
    FROM auth.users
    WHERE auth.users.id = v_user_id;

    IF v_role != 'admin' THEN
        RAISE EXCEPTION 'Unauthorized: Admin access required';
    END IF;

    RETURN QUERY
    SELECT 
        ct.id,
        ct.user_id,
        u.email::TEXT AS user_email,
        COALESCE(u.raw_user_meta_data->>'full_name', u.email)::TEXT AS user_name,
        ct.type,
        ct.amount,
        ct.balance_before,
        ct.balance_after,
        ct.reference_type,
        ct.reference_id,
        ct.description,
        ct.metadata,
        ct.created_at
    FROM credit_transactions ct
    JOIN auth.users u ON u.id = ct.user_id
    WHERE (p_user_id IS NULL OR ct.user_id = p_user_id)
        AND (p_type IS NULL OR ct.type = p_type)
    ORDER BY ct.created_at DESC
    LIMIT p_limit
    OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Admin: Get user credit balances with search and pagination
CREATE OR REPLACE FUNCTION admin_get_user_credits(
    p_limit INTEGER DEFAULT 20,
    p_offset INTEGER DEFAULT 0,
    p_search TEXT DEFAULT NULL,
    p_sort_field TEXT DEFAULT 'balance',
    p_sort_order TEXT DEFAULT 'DESC'
)
RETURNS TABLE (
    user_id UUID,
    user_email TEXT,
    user_name TEXT,
    balance DECIMAL,
    total_purchased DECIMAL,
    total_consumed DECIMAL,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ,
    total_count BIGINT
) AS $$
DECLARE
    v_user_id UUID;
    v_role VARCHAR;
    v_total_count BIGINT;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    -- Check if user is admin
    SELECT raw_user_meta_data->>'role' INTO v_role
    FROM auth.users
    WHERE auth.users.id = v_user_id;

    IF v_role != 'admin' THEN
        RAISE EXCEPTION 'Unauthorized: Admin access required';
    END IF;

    -- Get total count for pagination
    SELECT COUNT(*) INTO v_total_count
    FROM user_credits uc
    JOIN auth.users u ON u.id = uc.user_id
    WHERE (p_search IS NULL OR p_search = '' OR 
           LOWER(u.email) LIKE '%' || LOWER(p_search) || '%' OR
           LOWER(COALESCE(u.raw_user_meta_data->>'full_name', '')) LIKE '%' || LOWER(p_search) || '%');

    -- Return paginated results with total count
    RETURN QUERY EXECUTE format(
        'SELECT 
            uc.user_id,
            u.email::TEXT AS user_email,
            COALESCE(u.raw_user_meta_data->>''full_name'', u.email)::TEXT AS user_name,
            uc.balance,
            uc.total_purchased,
            uc.total_consumed,
            uc.created_at,
            uc.updated_at,
            $1 AS total_count
        FROM user_credits uc
        JOIN auth.users u ON u.id = uc.user_id
        WHERE ($2 IS NULL OR $2 = '''' OR 
               LOWER(u.email) LIKE ''%%'' || LOWER($2) || ''%%'' OR
               LOWER(COALESCE(u.raw_user_meta_data->>''full_name'', '''')) LIKE ''%%'' || LOWER($2) || ''%%'')
        ORDER BY %s %s
        LIMIT $3
        OFFSET $4',
        CASE 
            WHEN p_sort_field IN ('user_email', 'user_name') THEN 'u.email'
            WHEN p_sort_field IN ('balance', 'total_purchased', 'total_consumed', 'created_at', 'updated_at') THEN 'uc.' || p_sort_field
            ELSE 'uc.balance'
        END,
        CASE WHEN UPPER(p_sort_order) = 'ASC' THEN 'ASC' ELSE 'DESC' END
    )
    USING v_total_count, p_search, p_limit, p_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Admin: Adjust user credits (for refunds, corrections, etc.)
CREATE OR REPLACE FUNCTION admin_adjust_user_credits(
    p_target_user_id UUID,
    p_amount DECIMAL,
    p_reason TEXT
)
RETURNS JSONB AS $$
DECLARE
    v_admin_id UUID;
    v_role VARCHAR;
    v_current_balance DECIMAL;
    v_new_balance DECIMAL;
    v_transaction_id UUID;
    v_adjustment_type VARCHAR;
BEGIN
    v_admin_id := auth.uid();
    IF v_admin_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    -- Check if user is admin
    SELECT raw_user_meta_data->>'role' INTO v_role
    FROM auth.users
    WHERE auth.users.id = v_admin_id;

    IF v_role != 'admin' THEN
        RAISE EXCEPTION 'Unauthorized: Admin access required';
    END IF;

    -- Initialize credits if not exists
    INSERT INTO user_credits (user_id, balance)
    VALUES (p_target_user_id, 0)
    ON CONFLICT (user_id) DO NOTHING;

    -- Lock the user credits row for update
    SELECT balance INTO v_current_balance
    FROM user_credits
    WHERE user_id = p_target_user_id
    FOR UPDATE;

    v_new_balance := v_current_balance + p_amount;

    IF v_new_balance < 0 THEN
        RAISE EXCEPTION 'Adjustment would result in negative balance';
    END IF;

    -- Update user credits
    UPDATE user_credits
    SET 
        balance = v_new_balance,
        total_purchased = CASE 
            WHEN p_amount > 0 THEN total_purchased + p_amount
            ELSE total_purchased
        END,
        updated_at = CURRENT_TIMESTAMP
    WHERE user_id = p_target_user_id;

    -- Determine adjustment type
    IF p_amount > 0 THEN
        v_adjustment_type := 'adjustment';
    ELSIF p_amount < 0 THEN
        v_adjustment_type := 'consumption';
    ELSE
        RAISE EXCEPTION 'Adjustment amount cannot be zero';
    END IF;

    -- Record transaction
    INSERT INTO credit_transactions (
        user_id, type, amount, balance_before, balance_after,
        reference_type, description, metadata
    ) VALUES (
        p_target_user_id, v_adjustment_type, ABS(p_amount), 
        v_current_balance, v_new_balance,
        'admin_adjustment', p_reason,
        jsonb_build_object('admin_id', v_admin_id, 'admin_action', true)
    ) RETURNING id INTO v_transaction_id;

    -- Log the operation
    PERFORM log_operation(
        format('Admin adjusted credits for user %s: %s%s credits - %s',
            p_target_user_id,
            CASE WHEN p_amount > 0 THEN '+' ELSE '' END,
            p_amount, p_reason)
    );

    RETURN jsonb_build_object(
        'success', true,
        'transaction_id', v_transaction_id,
        'amount_adjusted', p_amount,
        'new_balance', v_new_balance,
        'previous_balance', v_current_balance
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Admin: Get credit system statistics
CREATE OR REPLACE FUNCTION admin_get_credit_statistics()
RETURNS JSONB AS $$
DECLARE
    v_user_id UUID;
    v_role VARCHAR;
    v_stats JSONB;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    -- Check if user is admin
    SELECT raw_user_meta_data->>'role' INTO v_role
    FROM auth.users
    WHERE auth.users.id = v_user_id;

    IF v_role != 'admin' THEN
        RAISE EXCEPTION 'Unauthorized: Admin access required';
    END IF;

    SELECT jsonb_build_object(
        'total_credits_in_circulation', COALESCE(SUM(balance), 0),
        'total_credits_purchased', COALESCE(SUM(total_purchased), 0),
        'total_credits_consumed', COALESCE(SUM(total_consumed), 0),
        'total_users_with_credits', COUNT(*),
        'total_revenue_usd', (
            SELECT COALESCE(SUM(amount_usd), 0)
            FROM credit_purchases
            WHERE status = 'completed'
        ),
        'monthly_purchases', (
            SELECT COALESCE(SUM(amount_usd), 0)
            FROM credit_purchases
            WHERE status = 'completed'
                AND created_at >= date_trunc('month', CURRENT_DATE)
        ),
        'monthly_consumption', (
            SELECT COALESCE(SUM(total_credits), 0)
            FROM credit_consumptions
            WHERE created_at >= date_trunc('month', CURRENT_DATE)
        ),
        'pending_purchases', (
            SELECT COUNT(*)
            FROM credit_purchases
            WHERE status = 'pending'
        )
    ) INTO v_stats
    FROM user_credits;

    RETURN v_stats;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
