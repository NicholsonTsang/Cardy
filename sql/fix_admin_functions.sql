-- Fix for ambiguous column references in admin functions
-- This script fixes all column ambiguity issues in the admin stored procedures

-- Fix get_all_users_with_details function
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
        SELECT c.user_id, COUNT(*) AS cards_count
        FROM public.cards c
        GROUP BY c.user_id
    ) card_stats ON au.id = card_stats.user_id
    LEFT JOIN (
        SELECT cb.created_by, COUNT(ic.*) AS issued_cards_count
        FROM public.card_batches cb
        LEFT JOIN public.issue_cards ic ON cb.id = ic.batch_id
        GROUP BY cb.created_by
    ) issued_stats ON au.id = issued_stats.created_by
    LEFT JOIN (
        SELECT pr.user_id, COUNT(*) AS print_requests_count
        FROM public.print_requests pr
        GROUP BY pr.user_id
    ) print_stats ON au.id = print_stats.user_id
    ORDER BY au.created_at DESC;
END;
$$;

-- Fix get_all_print_requests alias function
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

-- Add missing get_admin_audit_logs_count function for pagination
CREATE OR REPLACE FUNCTION get_admin_audit_logs_count(
    p_admin_user_id UUID DEFAULT NULL,
    p_target_user_id UUID DEFAULT NULL,
    p_action_type TEXT DEFAULT NULL
)
RETURNS INTEGER LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    caller_role TEXT;
    total_count INTEGER;
BEGIN
    -- Check if caller is admin
    SELECT raw_user_meta_data->>'role' INTO caller_role
    FROM auth.users
    WHERE auth.users.id = auth.uid();

    IF caller_role != 'admin' THEN
        RAISE EXCEPTION 'Only admins can view audit logs count.';
    END IF;

    SELECT COUNT(*)::INTEGER INTO total_count
    FROM admin_audit_log aal
    WHERE 
        (p_admin_user_id IS NULL OR aal.admin_user_id = p_admin_user_id)
        AND (p_target_user_id IS NULL OR aal.target_user_id = p_target_user_id)
        AND (p_action_type IS NULL OR aal.action_type = p_action_type);

    RETURN total_count;
END;
$$;

-- Fix get_admin_audit_logs function with proper column qualification
CREATE OR REPLACE FUNCTION get_admin_audit_logs(
    p_limit INTEGER DEFAULT 50,
    p_offset INTEGER DEFAULT 0,
    p_admin_user_id UUID DEFAULT NULL,
    p_target_user_id UUID DEFAULT NULL,
    p_action_type TEXT DEFAULT NULL
)
RETURNS TABLE (
    id UUID,
    admin_user_id UUID,
    admin_user_email VARCHAR(255),
    target_user_id UUID,
    target_user_email VARCHAR(255),
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
    -- Check if caller is admin
    SELECT raw_user_meta_data->>'role' INTO caller_role
    FROM auth.users
    WHERE auth.users.id = auth.uid();

    IF caller_role != 'admin' THEN
        RAISE EXCEPTION 'Only admins can view audit logs.';
    END IF;

    RETURN QUERY
    SELECT 
        aal.id,
        aal.admin_user_id,
        admin_user.email AS admin_user_email,
        aal.target_user_id,
        target_user.email AS target_user_email,
        aal.action_type,
        aal.action_details,
        aal.reason,
        aal.old_values,
        aal.new_values,
        aal.created_at
    FROM admin_audit_log aal
    LEFT JOIN auth.users admin_user ON aal.admin_user_id = admin_user.id
    LEFT JOIN auth.users target_user ON aal.target_user_id = target_user.id
    WHERE 
        (p_admin_user_id IS NULL OR aal.admin_user_id = p_admin_user_id)
        AND (p_target_user_id IS NULL OR aal.target_user_id = p_target_user_id)
        AND (p_action_type IS NULL OR aal.action_type = p_action_type)
    ORDER BY aal.created_at DESC
    LIMIT p_limit OFFSET p_offset;
END;
$$;

-- Add missing get_all_verifications function for admin verification management
CREATE OR REPLACE FUNCTION get_all_verifications(
    p_status "ProfileStatus" DEFAULT NULL,
    p_limit INTEGER DEFAULT 100,
    p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
    user_id UUID,
    user_email VARCHAR(255),
    public_name TEXT,
    bio TEXT,
    company_name TEXT,
    full_name TEXT,
    verification_status "ProfileStatus",
    supporting_documents TEXT[],
    admin_feedback TEXT,
    verified_at TIMESTAMPTZ,
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
        RAISE EXCEPTION 'Only admins can view all verifications.';
    END IF;

    RETURN QUERY
    SELECT 
        au.id AS user_id,
        au.email AS user_email,
        COALESCE(up.public_name, '') AS public_name,
        COALESCE(up.bio, '') AS bio,
        COALESCE(up.company_name, '') AS company_name,
        COALESCE(up.full_name, '') AS full_name,
        COALESCE(up.verification_status, 'NOT_SUBMITTED') AS verification_status,
        COALESCE(up.supporting_documents, ARRAY[]::TEXT[]) AS supporting_documents,
        COALESCE(up.admin_feedback, '') AS admin_feedback,
        up.verified_at,
        COALESCE(up.created_at, au.created_at) AS created_at,
        up.updated_at
    FROM auth.users au
    LEFT JOIN public.user_profiles up ON au.id = up.user_id
    WHERE 
        (p_status IS NULL OR COALESCE(up.verification_status, 'NOT_SUBMITTED') = p_status)
        AND au.raw_user_meta_data->>'role' IN ('user', 'cardIssuer') -- Only show non-admin users
    ORDER BY 
        CASE 
            WHEN up.verification_status = 'PENDING_REVIEW' THEN 1
            WHEN up.verification_status = 'NOT_SUBMITTED' THEN 2
            WHEN up.verification_status = 'APPROVED' THEN 3
            WHEN up.verification_status = 'REJECTED' THEN 4
            ELSE 5
        END,
        COALESCE(up.updated_at, au.created_at) DESC
    LIMIT p_limit OFFSET p_offset;
END;
$$; 