-- =============================================
-- Logging Helper Functions
-- Simple unified logging for all write operations
-- =============================================

-- Helper function to log operations
-- This should be called from any stored procedure that performs write operations
CREATE OR REPLACE FUNCTION log_operation(
    p_operation TEXT
) RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_user_id UUID;
    v_user_role "UserRole";
BEGIN
    -- Get current user ID
    v_user_id := auth.uid();
    
    -- Skip logging if no authenticated user (shouldn't happen in normal operations)
    IF v_user_id IS NULL THEN
        RETURN;
    END IF;
    
    -- Get user role from auth.users metadata
    SELECT COALESCE(
        (raw_user_meta_data->>'role')::"UserRole",
        'user'::"UserRole" -- Default to 'user' if role not set
    ) INTO v_user_role
    FROM auth.users
    WHERE id = v_user_id;
    
    -- Insert log entry
    INSERT INTO operations_log (user_id, user_role, operation)
    VALUES (v_user_id, v_user_role, p_operation);
    
EXCEPTION
    WHEN OTHERS THEN
        -- Silently fail logging to not break the main operation
        -- This ensures logging failures don't affect core functionality
        RAISE WARNING 'Failed to log operation: %', SQLERRM;
END;
$$;

-- Function to get recent operations log (admin only)
-- PERFORMANCE: Hard limit cap prevents runaway queries
CREATE OR REPLACE FUNCTION get_operations_log(
    p_limit INTEGER DEFAULT 100,
    p_offset INTEGER DEFAULT 0,
    p_user_id UUID DEFAULT NULL,
    p_user_role "UserRole" DEFAULT NULL,
    p_search_query TEXT DEFAULT NULL,
    p_start_date TIMESTAMPTZ DEFAULT NULL,
    p_end_date TIMESTAMPTZ DEFAULT NULL
)
RETURNS TABLE (
    id UUID,
    user_id UUID,
    user_email TEXT,
    user_role "UserRole",
    operation TEXT,
    created_at TIMESTAMPTZ
) LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    caller_role TEXT;
    -- PERFORMANCE: Maximum allowed limit to prevent abuse
    MAX_LIMIT CONSTANT INTEGER := 1000;
    v_effective_limit INTEGER;
BEGIN
    -- Check if the caller is an admin
    SELECT raw_user_meta_data->>'role' INTO caller_role
    FROM auth.users
    WHERE auth.users.id = auth.uid();

    IF caller_role != 'admin' THEN
        RAISE EXCEPTION 'Only admins can view operations log.';
    END IF;

    -- SECURITY: Cap the limit to prevent excessive data retrieval
    v_effective_limit := LEAST(COALESCE(p_limit, 100), MAX_LIMIT);

    RETURN QUERY
    SELECT 
        ol.id,
        ol.user_id,
        au.email::TEXT AS user_email,  -- Cast to TEXT to match return type
        ol.user_role,
        ol.operation,
        ol.created_at
    FROM operations_log ol
    LEFT JOIN auth.users au ON ol.user_id = au.id
    WHERE 
        (p_user_id IS NULL OR ol.user_id = p_user_id)
        AND (p_user_role IS NULL OR ol.user_role = p_user_role)
        AND (p_search_query IS NULL OR 
             ol.operation ILIKE '%' || p_search_query || '%' OR
             au.email ILIKE '%' || p_search_query || '%')
        AND (p_start_date IS NULL OR ol.created_at >= p_start_date)
        AND (p_end_date IS NULL OR ol.created_at <= p_end_date)
    ORDER BY ol.created_at DESC
    LIMIT v_effective_limit OFFSET p_offset;
END;
$$;

-- Function to get operations log summary statistics (admin only)
CREATE OR REPLACE FUNCTION get_operations_log_stats()
RETURNS TABLE (
    total_operations BIGINT,
    operations_today BIGINT,
    operations_this_week BIGINT,
    operations_this_month BIGINT,
    admin_operations BIGINT,
    card_issuer_operations BIGINT,
    user_operations BIGINT
) LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    caller_role TEXT;
BEGIN
    -- Check if the caller is an admin
    SELECT raw_user_meta_data->>'role' INTO caller_role
    FROM auth.users
    WHERE auth.users.id = auth.uid();

    IF caller_role != 'admin' THEN
        RAISE EXCEPTION 'Only admins can view operations log statistics.';
    END IF;

    RETURN QUERY
    SELECT 
        (SELECT COUNT(*) FROM operations_log) as total_operations,
        (SELECT COUNT(*) FROM operations_log WHERE created_at >= CURRENT_DATE) as operations_today,
        (SELECT COUNT(*) FROM operations_log WHERE created_at >= CURRENT_DATE - INTERVAL '7 days') as operations_this_week,
        (SELECT COUNT(*) FROM operations_log WHERE created_at >= CURRENT_DATE - INTERVAL '30 days') as operations_this_month,
        (SELECT COUNT(*) FROM operations_log WHERE user_role = 'admin') as admin_operations,
        (SELECT COUNT(*) FROM operations_log WHERE user_role = 'cardIssuer') as card_issuer_operations,
        (SELECT COUNT(*) FROM operations_log WHERE user_role = 'user') as user_operations;
END;
$$;

