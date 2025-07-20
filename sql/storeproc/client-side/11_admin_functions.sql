-- =================================================================
-- ADMIN FUNCTIONS
-- Functions for admin-only operations and system management
-- =================================================================

-- (Admin) Waive payment for a batch and generate cards
CREATE OR REPLACE FUNCTION admin_waive_batch_payment(
    p_batch_id UUID,
    p_waiver_reason TEXT
) RETURNS UUID LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_batch_record RECORD;
    caller_role TEXT;
BEGIN
    -- Check if the caller is an admin
    SELECT raw_user_meta_data->>'role' INTO caller_role
    FROM auth.users
    WHERE id = auth.uid();

    IF caller_role != 'admin' THEN
        RAISE EXCEPTION 'Only admins can waive batch payments.';
    END IF;

    -- Get batch information
    SELECT * INTO v_batch_record
    FROM card_batches
    WHERE id = p_batch_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Batch not found.';
    END IF;
    
    -- Check if payment can be waived
    IF v_batch_record.payment_completed = TRUE THEN
        RAISE EXCEPTION 'Cannot waive payment for a batch that has already been paid.';
    END IF;
    
    IF v_batch_record.payment_waived = TRUE THEN
        RAISE EXCEPTION 'Payment has already been waived for this batch.';
    END IF;
    
    -- Update batch to mark payment as waived
    UPDATE card_batches 
    SET 
        payment_waived = TRUE,
        payment_waived_by = auth.uid(),
        payment_waived_at = NOW(),
        payment_waiver_reason = p_waiver_reason,
        updated_at = NOW()
    WHERE id = p_batch_id;
    
    -- Generate cards using the new function
    PERFORM generate_batch_cards(p_batch_id);
    
    -- Log the waiver in audit table
    INSERT INTO admin_audit_log (
        admin_user_id,
        target_user_id,
        action_type,
        reason,
        old_values,
        new_values,
        action_details
    ) VALUES (
        auth.uid(),
        v_batch_record.created_by,
        'PAYMENT_WAIVER',
        p_waiver_reason,
        jsonb_build_object(
            'payment_waived', false,
            'cards_generated', false
        ),
        jsonb_build_object(
            'payment_waived', true,
            'payment_waived_by', auth.uid(),
            'payment_waived_at', NOW(),
            'payment_waiver_reason', p_waiver_reason,
            'cards_generated', true
        ),
        jsonb_build_object(
            'batch_id', p_batch_id,
            'cards_count', v_batch_record.cards_count
        )
    );
    
    RETURN p_batch_id;
END;
$$;

-- (Admin) Get all print requests for review
CREATE OR REPLACE FUNCTION admin_get_all_print_requests(
    p_status "PrintRequestStatus" DEFAULT NULL,
    p_limit INTEGER DEFAULT 100
)
RETURNS TABLE (
    request_id UUID,
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
        pr.id AS request_id,
        pr.batch_id AS batch_id,
        pr.user_id AS user_id,
        au.email::text AS user_email,
        up.public_name AS user_public_name,
        c.name AS card_name,
        cb.batch_name AS batch_name,
        cb.cards_count AS cards_count,
        pr.status AS status,
        pr.shipping_address AS shipping_address,
        pr.contact_email AS contact_email,
        pr.contact_whatsapp AS contact_whatsapp,
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
    WHERE id = auth.uid();

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

    -- Update the print request
    UPDATE print_requests
    SET 
        status = p_new_status,
        admin_notes = CASE 
            WHEN p_admin_notes IS NULL THEN admin_notes
            WHEN admin_notes IS NULL OR admin_notes = '' THEN p_admin_notes
            ELSE admin_notes || E'\n\n[' || NOW()::DATE || '] ' || p_admin_notes
        END,
        updated_at = NOW()
    WHERE id = p_request_id;

    -- Log the status change in audit table
    INSERT INTO admin_audit_log (
        admin_user_id,
        target_user_id,
        action_type,
        reason,
        old_values,
        new_values,
        action_details
    ) VALUES (
        auth.uid(),
        v_request_record.user_id,
        'PRINT_REQUEST_STATUS_UPDATE',
        COALESCE(p_admin_notes, 'Print request status updated to ' || p_new_status),
        jsonb_build_object(
            'status', v_request_record.status
        ),
        jsonb_build_object(
            'status', p_new_status,
            'admin_notes', p_admin_notes
        ),
        jsonb_build_object(
            'request_id', p_request_id,
            'batch_id', v_request_record.batch_id,
            'card_name', v_request_record.card_name,
            'batch_name', v_request_record.batch_name
        )
    );
    
    RETURN FOUND;
END;
$$;

-- (Admin) Get system statistics
CREATE OR REPLACE FUNCTION admin_get_system_stats()
RETURNS TABLE (
    total_users BIGINT,
    total_verified_users BIGINT,
    total_cards BIGINT,
    total_batches BIGINT,
    total_issued_cards BIGINT,
    total_activated_cards BIGINT,
    pending_verifications BIGINT,
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
    monthly_issued_cards BIGINT
) LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    caller_role TEXT;
BEGIN
    -- Check if the caller is an admin
    SELECT raw_user_meta_data->>'role' INTO caller_role
    FROM auth.users
    WHERE id = auth.uid();

    IF caller_role != 'admin' THEN
        RAISE EXCEPTION 'Only admins can view system statistics.';
    END IF;

    RETURN QUERY
    SELECT 
        (SELECT COUNT(*) FROM auth.users) as total_users,
        (SELECT COUNT(*) FROM user_profiles WHERE verification_status = 'APPROVED') as total_verified_users,
        (SELECT COUNT(*) FROM cards) as total_cards,
        (SELECT COUNT(*) FROM card_batches) as total_batches,
        (SELECT COUNT(*) FROM issue_cards) as total_issued_cards,
        (SELECT COUNT(*) FROM issue_cards WHERE active = true) as total_activated_cards,
        (SELECT COUNT(*) FROM user_profiles WHERE verification_status = 'PENDING_REVIEW') as pending_verifications,
        (SELECT COUNT(*) FROM card_batches WHERE payment_required = true AND payment_completed = false AND payment_waived = false) as pending_payment_batches,
        (SELECT COUNT(*) FROM card_batches WHERE payment_completed = true) as paid_batches,
        (SELECT COUNT(*) FROM card_batches WHERE payment_waived = true) as waived_batches,
        (SELECT COUNT(*) FROM print_requests WHERE status = 'SUBMITTED') as print_requests_submitted,
        (SELECT COUNT(*) FROM print_requests WHERE status = 'PROCESSING') as print_requests_processing,
        (SELECT COUNT(*) FROM print_requests WHERE status = 'SHIPPING') as print_requests_shipping,
        (SELECT COALESCE(SUM(amount_cents), 0) FROM batch_payments WHERE payment_status = 'succeeded' AND created_at >= CURRENT_DATE) as daily_revenue_cents,
        (SELECT COALESCE(SUM(amount_cents), 0) FROM batch_payments WHERE payment_status = 'succeeded' AND created_at >= CURRENT_DATE - INTERVAL '7 days') as weekly_revenue_cents,
        (SELECT COALESCE(SUM(amount_cents), 0) FROM batch_payments WHERE payment_status = 'succeeded' AND created_at >= CURRENT_DATE - INTERVAL '30 days') as monthly_revenue_cents,
        (SELECT COALESCE(SUM(amount_cents), 0) FROM batch_payments WHERE payment_status = 'succeeded') as total_revenue_cents,
        (SELECT COUNT(*) FROM auth.users WHERE created_at >= CURRENT_DATE) as daily_new_users,
        (SELECT COUNT(*) FROM auth.users WHERE created_at >= CURRENT_DATE - INTERVAL '7 days') as weekly_new_users,
        (SELECT COUNT(*) FROM auth.users WHERE created_at >= CURRENT_DATE - INTERVAL '30 days') as monthly_new_users,
        (SELECT COUNT(*) FROM cards WHERE created_at >= CURRENT_DATE) as daily_new_cards,
        (SELECT COUNT(*) FROM cards WHERE created_at >= CURRENT_DATE - INTERVAL '7 days') as weekly_new_cards,
        (SELECT COUNT(*) FROM cards WHERE created_at >= CURRENT_DATE - INTERVAL '30 days') as monthly_new_cards,
        (SELECT COUNT(*) FROM issue_cards WHERE created_at >= CURRENT_DATE) as daily_issued_cards,
        (SELECT COUNT(*) FROM issue_cards WHERE created_at >= CURRENT_DATE - INTERVAL '7 days') as weekly_issued_cards,
        (SELECT COUNT(*) FROM issue_cards WHERE created_at >= CURRENT_DATE - INTERVAL '30 days') as monthly_issued_cards;
END;
$$;

-- (Admin) Get pending verification requests
CREATE OR REPLACE FUNCTION admin_get_pending_verifications(p_limit INTEGER DEFAULT 50)
RETURNS TABLE (
    user_id UUID,
    email VARCHAR(255),
    public_name TEXT,
    company_name TEXT,
    full_name TEXT,
    supporting_documents TEXT[],
    created_at TIMESTAMPTZ,
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
        RAISE EXCEPTION 'Only admins can view pending verifications.';
    END IF;

    RETURN QUERY
    SELECT 
        up.user_id,
        au.email,
        up.public_name,
        up.company_name,
        up.full_name,
        up.supporting_documents,
        up.created_at,
        up.updated_at
    FROM user_profiles up
    JOIN auth.users au ON up.user_id = au.id
    WHERE up.verification_status = 'PENDING_REVIEW'
    ORDER BY up.updated_at ASC
    LIMIT p_limit;
END;
$$;

-- Create or update admin feedback (helper function)
CREATE OR REPLACE FUNCTION create_or_update_admin_feedback(
    p_feedback_type TEXT,
    p_target_user_id UUID,
    p_related_entity_id UUID,
    p_feedback_category TEXT,
    p_feedback_text TEXT,
    p_metadata JSONB DEFAULT NULL
) RETURNS UUID LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_feedback_id UUID;
    caller_role TEXT;
BEGIN
    -- Check if the caller is an admin
    SELECT raw_user_meta_data->>'role' INTO caller_role
    FROM auth.users
    WHERE id = auth.uid();

    IF caller_role != 'admin' THEN
        RAISE EXCEPTION 'Only admins can create feedback entries.';
    END IF;

    INSERT INTO admin_feedback_history (
        admin_user_id,
        target_user_id,
        target_entity_id,
        target_entity_type,
        feedback_type,
        content,
        action_context,
        is_current,
        version_number
    ) VALUES (
        auth.uid(),
        p_target_user_id,
        p_related_entity_id,
        p_feedback_type,
        p_feedback_category,
        p_feedback_text,
        p_metadata,
        true,
        1
    )
    RETURNING id INTO v_feedback_id;
    
    RETURN v_feedback_id;
END;
$$;

-- (Admin) Get admin audit logs
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
    admin_email VARCHAR(255),
    target_user_id UUID,
    target_email VARCHAR(255),
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
    WHERE auth.users.id = auth.uid();

    IF caller_role != 'admin' THEN
        RAISE EXCEPTION 'Only admins can view audit logs.';
    END IF;

    RETURN QUERY
    SELECT 
        aal.id,
        aal.admin_user_id,
        au_admin.email,
        aal.target_user_id,
        au_target.email,
        aal.action_type,
        aal.action_details,
        aal.reason,
        aal.old_values,
        aal.new_values,
        aal.created_at
    FROM admin_audit_log aal
    LEFT JOIN auth.users au_admin ON aal.admin_user_id = au_admin.id
    LEFT JOIN auth.users au_target ON aal.target_user_id = au_target.id
    WHERE 
        (p_action_type IS NULL OR 
         (CASE 
            WHEN p_action_type LIKE '%,%' THEN aal.action_type = ANY(string_to_array(p_action_type, ','))
            ELSE aal.action_type = p_action_type
         END))
        AND (p_admin_user_id IS NULL OR aal.admin_user_id = p_admin_user_id)
        AND (p_target_user_id IS NULL OR aal.target_user_id = p_target_user_id)
        AND (p_start_date IS NULL OR aal.created_at >= p_start_date)
        AND (p_end_date IS NULL OR aal.created_at <= p_end_date)
    ORDER BY aal.created_at DESC
    LIMIT p_limit
    OFFSET p_offset;
END;
$$;

-- (Admin) Get recent admin activity
CREATE OR REPLACE FUNCTION get_recent_admin_activity(
    p_limit INTEGER DEFAULT 50
)
RETURNS TABLE (
    activity_type TEXT,
    activity_date TIMESTAMPTZ,
    user_email VARCHAR(255),
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
    WHERE auth.users.id = auth.uid();

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

-- (Admin) Get count of admin audit logs with filtering
CREATE OR REPLACE FUNCTION get_admin_audit_logs_count(
    p_action_type TEXT DEFAULT NULL,
    p_admin_user_id UUID DEFAULT NULL,
    p_target_user_id UUID DEFAULT NULL,
    p_start_date TIMESTAMPTZ DEFAULT NULL,
    p_end_date TIMESTAMPTZ DEFAULT NULL
)
RETURNS INTEGER LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    caller_role TEXT;
    v_count INTEGER;
BEGIN
    -- Check if caller is admin
    SELECT raw_user_meta_data->>'role' INTO caller_role
    FROM auth.users
    WHERE auth.users.id = auth.uid();

    IF caller_role != 'admin' THEN
        RAISE EXCEPTION 'Only admins can view audit logs.';
    END IF;

    SELECT COUNT(*)::INTEGER INTO v_count
    FROM admin_audit_log aal
    WHERE (p_action_type IS NULL OR 
           (CASE 
              WHEN p_action_type LIKE '%,%' THEN aal.action_type = ANY(string_to_array(p_action_type, ','))
              ELSE aal.action_type = p_action_type
           END))
    AND (p_admin_user_id IS NULL OR aal.admin_user_id = p_admin_user_id)
    AND (p_target_user_id IS NULL OR aal.target_user_id = p_target_user_id)
    AND (p_start_date IS NULL OR aal.created_at >= p_start_date)
    AND (p_end_date IS NULL OR aal.created_at <= p_end_date);

    RETURN v_count;
END;
$$;

-- (Admin) Get all verifications with optional status filter
CREATE OR REPLACE FUNCTION get_all_verifications(p_status "ProfileStatus" DEFAULT NULL)
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
        up.user_id,
        au.email,
        up.public_name,
        up.bio,
        up.company_name,
        up.full_name,
        up.verification_status,
        up.supporting_documents,
        up.admin_feedback,
        up.verified_at,
        up.created_at,
        up.updated_at
    FROM public.user_profiles up
    JOIN auth.users au ON up.user_id = au.id
    WHERE (p_status IS NULL OR up.verification_status = p_status)
    AND up.verification_status != 'NOT_SUBMITTED' -- Only show submitted verifications
    ORDER BY up.updated_at DESC;
END;
$$;

-- (Admin) Get verification by user ID
CREATE OR REPLACE FUNCTION get_verification_by_id(p_user_id UUID)
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
        RAISE EXCEPTION 'Only admins can view verifications.';
    END IF;

    RETURN QUERY
    SELECT 
        up.user_id,
        au.email,
        up.public_name,
        up.bio,
        up.company_name,
        up.full_name,
        up.verification_status,
        up.supporting_documents,
        up.admin_feedback,
        up.verified_at,
        up.created_at,
        up.updated_at
    FROM public.user_profiles up
    JOIN auth.users au ON up.user_id = au.id
    WHERE up.user_id = p_user_id
    AND up.verification_status != 'NOT_SUBMITTED'; -- Only show submitted verifications
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
    contact_email TEXT,
    contact_whatsapp TEXT,
    admin_notes TEXT,
    requested_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ
) LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
    -- This function simply calls the admin version with a default limit.
    -- This provides a consistent, simplified interface for clients.
    RETURN QUERY
    SELECT
        apr.request_id as id,
        apr.batch_id,
        apr.user_id,
        apr.user_email,
        apr.user_public_name,
        apr.card_name,
        apr.batch_name,
        apr.cards_count,
        apr.status,
        apr.shipping_address,
        apr.contact_email,
        apr.contact_whatsapp,
        apr.admin_notes,
        apr.requested_at,
        apr.updated_at
    FROM admin_get_all_print_requests(p_status, 100) apr;
END;
$$;

-- (Admin) Change user role with comprehensive audit logging
CREATE OR REPLACE FUNCTION admin_change_user_role(
    p_target_user_id UUID,
    p_new_role TEXT,
    p_reason TEXT
)
RETURNS BOOLEAN LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    caller_role TEXT;
    current_role TEXT;
    target_user_email TEXT;
    valid_roles TEXT[] := ARRAY['card_issuer', 'admin'];
BEGIN
    -- Check if the caller is an admin
    SELECT raw_user_meta_data->>'role' INTO caller_role
    FROM auth.users
    WHERE id = auth.uid();

    IF caller_role != 'admin' THEN
        RAISE EXCEPTION 'Only admins can change user roles.';
    END IF;

    -- Validate new role
    IF p_new_role != ALL(valid_roles) THEN
        RAISE EXCEPTION 'Invalid role. Valid roles are: %', array_to_string(valid_roles, ', ');
    END IF;

    -- Get current role and email of target user
    SELECT 
        raw_user_meta_data->>'role',
        email
    INTO current_role, target_user_email
    FROM auth.users
    WHERE id = p_target_user_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Target user not found.';
    END IF;

    -- Check if role is actually changing
    IF current_role = p_new_role THEN
        RAISE EXCEPTION 'User already has role: %', p_new_role;
    END IF;

    -- Prevent self-demotion from admin
    IF auth.uid() = p_target_user_id AND current_role = 'admin' AND p_new_role != 'admin' THEN
        RAISE EXCEPTION 'Admins cannot demote themselves. Another admin must perform this action.';
    END IF;

    -- Update user role
    UPDATE auth.users
    SET 
        raw_user_meta_data = COALESCE(raw_user_meta_data, '{}'::jsonb) || jsonb_build_object('role', p_new_role),
        updated_at = NOW()
    WHERE id = p_target_user_id;

    -- Log role change in audit table
    INSERT INTO admin_audit_log (
        admin_user_id,
        target_user_id,
        action_type,
        reason,
        old_values,
        new_values,
        action_details
    ) VALUES (
        auth.uid(),
        p_target_user_id,
        'ROLE_CHANGE',
        p_reason,
        jsonb_build_object(
            'role', current_role
        ),
        jsonb_build_object(
            'role', p_new_role,
            'changed_at', NOW()
        ),
        jsonb_build_object(
            'action', 'role_changed',
            'from_role', current_role,
            'to_role', p_new_role,
            'target_email', target_user_email,
            'is_promotion', CASE 
                WHEN current_role = 'card_issuer' AND p_new_role = 'admin' THEN true
                ELSE false
            END,
            'is_demotion', CASE 
                WHEN current_role = 'admin' AND p_new_role = 'card_issuer' THEN true
                ELSE false
            END,
            'security_impact', CASE 
                WHEN p_new_role = 'admin' THEN 'high'
                WHEN current_role = 'admin' THEN 'high'
                ELSE 'medium'
            END
        )
    );
    
    RETURN FOUND;
END;
$$;

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
        au.email::text AS admin_email,
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

-- (Admin) Get current admin feedback
CREATE OR REPLACE FUNCTION get_current_admin_feedback(
    p_target_entity_type TEXT,
    p_target_entity_id UUID,
    p_feedback_type TEXT
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
        RAISE EXCEPTION 'Only admins can view current feedback.';
    END IF;

    RETURN QUERY
    SELECT 
        afh.id AS id,
        afh.admin_user_id AS admin_user_id,
        au.email::text AS admin_email,
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
        afh.target_entity_type = p_target_entity_type
        AND afh.target_entity_id = p_target_entity_id
        AND afh.feedback_type = p_feedback_type
        AND afh.is_current = true
    ORDER BY afh.created_at DESC;
END;
$$;

-- (Admin) Get user feedback summary
CREATE OR REPLACE FUNCTION get_user_feedback_summary(
    p_target_user_id UUID
)
RETURNS TABLE (
    feedback_type TEXT,
    feedback_count INTEGER,
    latest_feedback TEXT,
    latest_feedback_date TIMESTAMPTZ,
    admin_email TEXT
) LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    caller_role TEXT;
BEGIN
    -- Check if caller is admin
    SELECT raw_user_meta_data->>'role' INTO caller_role
    FROM auth.users
    WHERE auth.users.id = auth.uid();

    IF caller_role != 'admin' THEN
        RAISE EXCEPTION 'Only admins can view user feedback summary.';
    END IF;

    RETURN QUERY
    SELECT 
        afh.feedback_type AS feedback_type,
        COUNT(*)::INTEGER AS feedback_count,
        (ARRAY_AGG(afh.content ORDER BY afh.created_at DESC))[1] AS latest_feedback,
        MAX(afh.created_at) AS latest_feedback_date,
        (ARRAY_AGG(au.email ORDER BY afh.created_at DESC))[1]::text AS admin_email
    FROM admin_feedback_history afh
    LEFT JOIN auth.users au ON afh.admin_user_id = au.id
    WHERE afh.target_user_id = p_target_user_id
    GROUP BY afh.feedback_type
    ORDER BY latest_feedback_date DESC;
END;
$$;

-- (Admin) Reset user verification status
CREATE OR REPLACE FUNCTION reset_user_verification(
    p_user_id UUID
)
RETURNS BOOLEAN LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    caller_role TEXT;
    v_user_email TEXT;
BEGIN
    -- Check if the caller is an admin
    SELECT raw_user_meta_data->>'role' INTO caller_role
    FROM auth.users
    WHERE id = auth.uid();

    IF caller_role != 'admin' THEN
        RAISE EXCEPTION 'Only admins can reset user verification.';
    END IF;

    -- Get target user email for audit logging
    SELECT email INTO v_user_email
    FROM auth.users
    WHERE id = p_user_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'User not found.';
    END IF;

    -- Reset verification status
    UPDATE user_profiles
    SET 
        verification_status = 'NOT_SUBMITTED',
        supporting_documents = NULL,
        admin_feedback = NULL,
        verified_at = NULL,
        updated_at = NOW()
    WHERE user_id = p_user_id;

    -- Log the verification reset in audit table
    INSERT INTO admin_audit_log (
        admin_user_id,
        target_user_id,
        action_type,
        reason,
        old_values,
        new_values,
        action_details
    ) VALUES (
        auth.uid(),
        p_user_id,
        'VERIFICATION_RESET',
        'Verification status reset by admin',
        jsonb_build_object(
            'verification_status', 'PENDING_REVIEW'
        ),
        jsonb_build_object(
            'verification_status', 'NOT_SUBMITTED',
            'supporting_documents', NULL,
            'admin_feedback', NULL,
            'verified_at', NULL
        ),
        jsonb_build_object(
            'action', 'verification_reset',
            'target_email', v_user_email,
            'reset_reason', 'admin_initiated'
        )
    );
    
    RETURN FOUND;
END;
$$;

-- (Admin) Manual verification approval
CREATE OR REPLACE FUNCTION admin_manual_verification(
    p_user_id UUID,
    p_reason TEXT
)
RETURNS BOOLEAN LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    caller_role TEXT;
    v_user_email TEXT;
    v_current_status "ProfileStatus";
BEGIN
    -- Check if the caller is an admin
    SELECT raw_user_meta_data->>'role' INTO caller_role
    FROM auth.users
    WHERE id = auth.uid();

    IF caller_role != 'admin' THEN
        RAISE EXCEPTION 'Only admins can manually verify users.';
    END IF;

    -- Get target user details for audit logging
    SELECT au.email, up.verification_status 
    INTO v_user_email, v_current_status
    FROM auth.users au
    LEFT JOIN user_profiles up ON au.id = up.user_id
    WHERE au.id = p_user_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'User not found.';
    END IF;

    -- Create or update user profile if not exists
    INSERT INTO user_profiles (
        user_id,
        verification_status,
        admin_feedback,
        verified_at,
        created_at,
        updated_at
    ) VALUES (
        p_user_id,
        'APPROVED',
        p_reason,
        NOW(),
        NOW(),
        NOW()
    )
    ON CONFLICT (user_id) DO UPDATE SET
        verification_status = 'APPROVED',
        admin_feedback = p_reason,
        verified_at = NOW(),
        updated_at = NOW();

    -- Log the manual verification in audit table
    INSERT INTO admin_audit_log (
        admin_user_id,
        target_user_id,
        action_type,
        reason,
        old_values,
        new_values,
        action_details
    ) VALUES (
        auth.uid(),
        p_user_id,
        'MANUAL_VERIFICATION',
        p_reason,
        jsonb_build_object(
            'verification_status', COALESCE(v_current_status, 'NOT_SUBMITTED')
        ),
        jsonb_build_object(
            'verification_status', 'APPROVED',
            'admin_feedback', p_reason,
            'verified_at', NOW()
        ),
        jsonb_build_object(
            'action', 'manual_verification_approved',
            'target_email', v_user_email,
            'approval_method', 'admin_override'
        )
    );
    
    RETURN TRUE;
END;
$$;

-- (Admin) Get user activity summary
CREATE OR REPLACE FUNCTION get_user_activity_summary(
    p_user_id UUID
)
RETURNS TABLE (
    cards_count INTEGER,
    batches_count INTEGER,
    issued_cards_count INTEGER,
    print_requests_count INTEGER,
    total_revenue_cents BIGINT,
    last_activity_date TIMESTAMPTZ,
    account_age_days INTEGER
) LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    caller_role TEXT;
    v_user_created_at TIMESTAMPTZ;
BEGIN
    -- Check if the caller is an admin
    SELECT raw_user_meta_data->>'role' INTO caller_role
    FROM auth.users
    WHERE id = auth.uid();

    IF caller_role != 'admin' THEN
        RAISE EXCEPTION 'Only admins can view user activity summary.';
    END IF;

    -- Get user creation date
    SELECT created_at INTO v_user_created_at
    FROM auth.users
    WHERE id = p_user_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'User not found.';
    END IF;

    RETURN QUERY
    SELECT 
        COALESCE((SELECT COUNT(*)::INTEGER FROM cards WHERE user_id = p_user_id), 0) as cards_count,
        COALESCE((SELECT COUNT(*)::INTEGER FROM card_batches WHERE created_by = p_user_id), 0) as batches_count,
        COALESCE((
            SELECT COUNT(ic.*)::INTEGER 
            FROM card_batches cb
            LEFT JOIN issue_cards ic ON cb.id = ic.batch_id
            WHERE cb.created_by = p_user_id
        ), 0) as issued_cards_count,
        COALESCE((SELECT COUNT(*)::INTEGER FROM print_requests WHERE user_id = p_user_id), 0) as print_requests_count,
        COALESCE((
            SELECT SUM(bp.amount_cents)
            FROM card_batches cb
            LEFT JOIN batch_payments bp ON cb.id = bp.batch_id
            WHERE cb.created_by = p_user_id AND bp.payment_status = 'succeeded'
        ), 0) as total_revenue_cents,
        GREATEST(
            (SELECT MAX(updated_at) FROM cards WHERE user_id = p_user_id),
            (SELECT MAX(updated_at) FROM card_batches WHERE created_by = p_user_id),
            (SELECT MAX(updated_at) FROM print_requests WHERE user_id = p_user_id)
        ) as last_activity_date,
        EXTRACT(DAY FROM NOW() - v_user_created_at)::INTEGER as account_age_days;
END;
$$;