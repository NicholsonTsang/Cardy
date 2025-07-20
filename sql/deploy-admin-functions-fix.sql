-- Force drop and recreate admin functions to fix ambiguity errors
-- Run this script in your Supabase SQL Editor

-- First, drop the existing functions
DROP FUNCTION IF EXISTS get_admin_audit_logs CASCADE;
DROP FUNCTION IF EXISTS get_recent_admin_activity CASCADE;
DROP FUNCTION IF EXISTS get_all_users_with_details CASCADE;
DROP FUNCTION IF EXISTS get_admin_batches_requiring_attention CASCADE;
DROP FUNCTION IF EXISTS get_all_print_requests CASCADE;
DROP FUNCTION IF EXISTS admin_get_all_print_requests CASCADE;
DROP FUNCTION IF EXISTS get_admin_feedback_history CASCADE;

-- Wait a moment for the drops to complete, then create the fixed versions

-- (Admin) Get admin audit logs - WITH PROPER ALIASES
CREATE OR REPLACE FUNCTION get_admin_audit_logs(
    p_action_type TEXT DEFAULT NULL,
    p_admin_user_id UUID DEFAULT NULL,
    p_target_user_id UUID DEFAULT NULL,
    p_start_date TIMESTAMPTZ DEFAULT NULL,
    p_end_date TIMESTAMPTZ DEFAULT NULL,
    p_limit INTEGER DEFAULT 50,
    p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
    id UUID,
    admin_user_id UUID,
    admin_email TEXT,
    target_user_id UUID,
    target_email TEXT,
    action_type TEXT,
    action_details JSONB,
    reason TEXT,
    old_values JSONB,
    new_values JSONB,
    created_at TIMESTAMPTZ
) LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    caller_role TEXT;
BEGIN
    -- Check if the caller is an admin
    SELECT raw_user_meta_data->>'role' INTO caller_role
    FROM auth.users
    WHERE id = auth.uid();

    IF caller_role != 'admin' THEN
        RAISE EXCEPTION 'Only admins can view audit logs.';
    END IF;

    RETURN QUERY
    SELECT 
        aal.id AS id,
        aal.admin_user_id AS admin_user_id,
        au_admin.email AS admin_email,
        aal.target_user_id AS target_user_id,
        au_target.email AS target_email,
        aal.action_type AS action_type,
        aal.action_details AS action_details,
        aal.reason AS reason,
        aal.old_values AS old_values,
        aal.new_values AS new_values,
        aal.created_at AS created_at
    FROM admin_audit_log aal
    LEFT JOIN auth.users au_admin ON aal.admin_user_id = au_admin.id
    LEFT JOIN auth.users au_target ON aal.target_user_id = au_target.id
    WHERE 
        (p_action_type IS NULL OR aal.action_type = p_action_type)
        AND (p_admin_user_id IS NULL OR aal.admin_user_id = p_admin_user_id)
        AND (p_target_user_id IS NULL OR aal.target_user_id = p_target_user_id)
        AND (p_start_date IS NULL OR aal.created_at >= p_start_date)
        AND (p_end_date IS NULL OR aal.created_at <= p_end_date)
    ORDER BY aal.created_at DESC
    LIMIT p_limit
    OFFSET p_offset;
END;
$$;

-- (Admin) Get recent admin activity - WITH PROPER ALIASES
CREATE OR REPLACE FUNCTION get_recent_admin_activity(
    p_limit INTEGER DEFAULT 50
)
RETURNS TABLE (
    activity_type TEXT,
    activity_date TIMESTAMPTZ,
    user_email TEXT,
    user_public_name TEXT,
    description TEXT,
    details JSONB
) LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    caller_role TEXT;
BEGIN
    -- Check if the caller is an admin
    SELECT raw_user_meta_data->>'role' INTO caller_role
    FROM auth.users
    WHERE id = auth.uid();

    IF caller_role != 'admin' THEN
        RAISE EXCEPTION 'Only admins can view recent activity.';
    END IF;

    RETURN QUERY
    SELECT 
        aal.action_type AS activity_type,
        aal.created_at AS activity_date,
        au.email AS user_email,
        up.public_name AS user_public_name,
        CASE 
            WHEN aal.action_type = 'PAYMENT_WAIVER' THEN 'Payment waived for batch'
            WHEN aal.action_type = 'PRINT_REQUEST_STATUS_UPDATE' THEN 'Print request status updated'
            WHEN aal.action_type = 'ROLE_CHANGE' THEN 'User role changed'
            WHEN aal.action_type = 'VERIFICATION_STATUS_UPDATE' THEN 'Verification status updated'
            ELSE aal.action_type
        END AS description,
        aal.action_details AS details
    FROM admin_audit_log aal
    LEFT JOIN auth.users au ON aal.target_user_id = au.id
    LEFT JOIN user_profiles up ON aal.target_user_id = up.user_id
    ORDER BY aal.created_at DESC
    LIMIT p_limit;
END;
$$;

-- (Admin) Get all users with detailed information including activity stats
CREATE OR REPLACE FUNCTION get_all_users_with_details()
RETURNS TABLE (
    user_id UUID,
    user_email VARCHAR(255),
    role TEXT,
    public_name TEXT,
    bio TEXT,
    company_name TEXT,
    full_name TEXT,
    verification_status "ProfileStatus",
    supporting_documents TEXT[],
    admin_feedback TEXT,
    verified_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ,
    last_sign_in_at TIMESTAMPTZ,
    cards_count INTEGER,
    issued_cards_count INTEGER,
    print_requests_count INTEGER
) LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    caller_role TEXT;
BEGIN
    -- Check if caller is admin
    SELECT raw_user_meta_data->>'role' INTO caller_role
    FROM auth.users
    WHERE auth.users.id = auth.uid();

    IF caller_role != 'admin' THEN
        RAISE EXCEPTION 'Only admins can view all users.';
    END IF;

    RETURN QUERY
    SELECT 
        au.id AS user_id,
        au.email AS user_email,
        au.raw_user_meta_data->>'role' AS role,
        COALESCE(up.public_name, '') AS public_name,
        COALESCE(up.bio, '') AS bio,
        COALESCE(up.company_name, '') AS company_name,
        COALESCE(up.full_name, '') AS full_name,
        COALESCE(up.verification_status, 'NOT_SUBMITTED') AS verification_status,
        COALESCE(up.supporting_documents, ARRAY[]::TEXT[]) AS supporting_documents,
        COALESCE(up.admin_feedback, '') AS admin_feedback,
        up.verified_at,
        COALESCE(up.created_at, au.created_at) AS created_at,
        up.updated_at,
        au.last_sign_in_at,
        COALESCE(card_stats.cards_count, 0)::INTEGER AS cards_count,
        COALESCE(issued_stats.issued_cards_count, 0)::INTEGER AS issued_cards_count,
        COALESCE(print_stats.print_requests_count, 0)::INTEGER AS print_requests_count
    FROM auth.users au
    LEFT JOIN public.user_profiles up ON au.id = up.user_id
    LEFT JOIN (
        SELECT user_id, COUNT(*) AS cards_count
        FROM public.cards
        GROUP BY user_id
    ) card_stats ON au.id = card_stats.user_id
    LEFT JOIN (
        SELECT cb.created_by, COUNT(ic.*) AS issued_cards_count
        FROM public.card_batches cb
        LEFT JOIN public.issue_cards ic ON cb.id = ic.batch_id
        GROUP BY cb.created_by
    ) issued_stats ON au.id = issued_stats.created_by
    LEFT JOIN (
        SELECT user_id, COUNT(*) AS print_requests_count
        FROM public.print_requests
        GROUP BY user_id
    ) print_stats ON au.id = print_stats.user_id
    ORDER BY au.created_at DESC;
END;
$$;

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
    creator_email VARCHAR(255),
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
        au.email AS creator_email,
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

-- Grant necessary permissions
GRANT EXECUTE ON FUNCTION get_admin_audit_logs TO authenticated;
GRANT EXECUTE ON FUNCTION get_recent_admin_activity TO authenticated;
GRANT EXECUTE ON FUNCTION get_all_users_with_details TO authenticated;
GRANT EXECUTE ON FUNCTION get_admin_batches_requiring_attention TO authenticated;

-- (Admin) Get all print requests for review - WITH PROPER ALIASES
CREATE OR REPLACE FUNCTION admin_get_all_print_requests(
    p_status "PrintRequestStatus" DEFAULT NULL,
    p_limit INTEGER DEFAULT 100
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
    admin_notes TEXT,
    requested_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ
) LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    caller_role TEXT;
BEGIN
    -- Check if the caller is an admin
    SELECT raw_user_meta_data->>'role' INTO caller_role
    FROM auth.users
    WHERE id = auth.uid();

    IF caller_role != 'admin' THEN
        RAISE EXCEPTION 'Only admins can view all print requests.';
    END IF;

    RETURN QUERY
    SELECT 
        pr.id AS id,
        pr.batch_id AS batch_id,
        pr.user_id AS user_id,
        au.email AS user_email,
        up.public_name AS user_public_name,
        c.name AS card_name,
        cb.batch_name AS batch_name,
        cb.cards_count AS cards_count,
        pr.status AS status,
        pr.shipping_address AS shipping_address,
        pr.admin_notes AS admin_notes,
        pr.requested_at AS requested_at,
        pr.updated_at AS updated_at
    FROM print_requests pr
    JOIN card_batches cb ON pr.batch_id = cb.id
    JOIN cards c ON cb.card_id = c.id
    LEFT JOIN auth.users au ON pr.user_id = au.id
    LEFT JOIN user_profiles up ON pr.user_id = up.user_id
    WHERE (p_status IS NULL OR pr.status = p_status)
    ORDER BY pr.requested_at DESC
    LIMIT p_limit;
END;
$$;

-- Alias function for backward compatibility
CREATE OR REPLACE FUNCTION get_all_print_requests(
    p_status "PrintRequestStatus" DEFAULT NULL
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
    admin_notes TEXT,
    requested_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ
) LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
    RETURN QUERY
    SELECT 
        apr.id,
        apr.batch_id,
        apr.user_id,
        apr.user_email,
        apr.user_public_name,
        apr.card_name,
        apr.batch_name,
        apr.cards_count,
        apr.status,
        apr.shipping_address,
        apr.admin_notes,
        apr.requested_at,
        apr.updated_at
    FROM admin_get_all_print_requests(p_status, 100) apr;
END;
$$;

GRANT EXECUTE ON FUNCTION admin_get_all_print_requests TO authenticated;
GRANT EXECUTE ON FUNCTION get_all_print_requests TO authenticated;

-- (Admin) Get admin feedback history
CREATE OR REPLACE FUNCTION get_admin_feedback_history(
    p_target_entity_type TEXT DEFAULT NULL,
    p_target_entity_id UUID DEFAULT NULL,
    p_feedback_type TEXT DEFAULT NULL
)
RETURNS TABLE (
    id UUID,
    admin_user_id UUID,
    admin_email TEXT,
    target_entity_type TEXT,
    target_entity_id UUID,
    feedback_type TEXT,
    content TEXT,
    is_current BOOLEAN,
    version_number INTEGER,
    action_context JSONB,
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
        RAISE EXCEPTION 'Only admins can view feedback history.';
    END IF;

    RETURN QUERY
    SELECT 
        afh.id AS id,
        afh.admin_user_id AS admin_user_id,
        au.email AS admin_email,
        afh.target_entity_type AS target_entity_type,
        afh.target_entity_id AS target_entity_id,
        afh.feedback_type AS feedback_type,
        afh.content AS content,
        afh.is_current AS is_current,
        afh.version_number AS version_number,
        afh.action_context AS action_context,
        afh.created_at AS created_at,
        afh.updated_at AS updated_at
    FROM admin_feedback_history afh
    LEFT JOIN auth.users au ON afh.admin_user_id = au.id
    WHERE 
        (p_target_entity_type IS NULL OR afh.target_entity_type = p_target_entity_type)
        AND (p_target_entity_id IS NULL OR afh.target_entity_id = p_target_entity_id)
        AND (p_feedback_type IS NULL OR afh.feedback_type = p_feedback_type)
    ORDER BY afh.created_at DESC;
END;
$$;

GRANT EXECUTE ON FUNCTION get_admin_feedback_history TO authenticated;

-- Verify the functions were created
SELECT 
    p.proname as function_name,
    pg_get_functiondef(p.oid) as function_definition
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public' 
AND p.proname IN ('get_admin_audit_logs', 'get_recent_admin_activity', 'get_all_users_with_details', 'get_admin_batches_requiring_attention', 'admin_get_all_print_requests', 'get_all_print_requests', 'get_admin_feedback_history');