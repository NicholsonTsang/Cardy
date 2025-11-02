-- Deploy updated admin credit management functions
-- Execute this in Supabase SQL Editor
--
-- Changes:
-- 1. admin_get_user_credits: Added pagination and search
-- 2. admin_get_credit_statistics: Removed top_credit_users (UI simplified)

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

-- Admin: Get credit system statistics (without top users)
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

