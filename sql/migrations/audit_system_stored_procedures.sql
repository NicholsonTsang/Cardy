-- =================================================================
-- AUDIT SYSTEM STORED PROCEDURES - NEW SCHEMA
-- Updated stored procedures for the revamped audit and feedback system
-- =================================================================

-- 1. Enhanced audit logging function with standardized format
CREATE OR REPLACE FUNCTION log_admin_action(
    p_admin_user_id UUID,
    p_target_user_id UUID DEFAULT NULL,
    p_target_entity_type VARCHAR(50) DEFAULT NULL,
    p_target_entity_id UUID DEFAULT NULL,
    p_action_type "AdminActionType",
    p_action_severity "ActionSeverity" DEFAULT 'MEDIUM',
    p_action_summary VARCHAR(500),
    p_reason TEXT DEFAULT NULL,
    p_old_values JSONB DEFAULT NULL,
    p_new_values JSONB DEFAULT NULL,
    p_metadata JSONB DEFAULT '{}'
) RETURNS UUID LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_audit_id UUID;
    v_admin_email VARCHAR(255);
    v_target_email VARCHAR(255);
BEGIN
    -- Get admin email for denormalization
    SELECT email INTO v_admin_email FROM auth.users WHERE id = p_admin_user_id;
    
    -- Get target user email if provided
    IF p_target_user_id IS NOT NULL THEN
        SELECT email INTO v_target_email FROM auth.users WHERE id = p_target_user_id;
    END IF;
    
    -- Insert audit log entry
    INSERT INTO admin_audit_log (
        admin_user_id,
        admin_email,
        target_user_id,
        target_user_email,
        target_entity_type,
        target_entity_id,
        action_type,
        action_severity,
        action_summary,
        reason,
        old_values,
        new_values,
        metadata
    ) VALUES (
        p_admin_user_id,
        v_admin_email,
        p_target_user_id,
        v_target_email,
        p_target_entity_type,
        p_target_entity_id,
        p_action_type,
        p_action_severity,
        p_action_summary,
        p_reason,
        p_old_values,
        p_new_values,
        p_metadata
    ) RETURNING id INTO v_audit_id;
    
    RETURN v_audit_id;
END;
$$;

-- 2. Admin feedback management functions
CREATE OR REPLACE FUNCTION create_admin_feedback(
    p_admin_user_id UUID,
    p_target_user_id UUID,
    p_context_type VARCHAR(50),
    p_context_entity_id UUID DEFAULT NULL,
    p_subject VARCHAR(200),
    p_content TEXT,
    p_priority VARCHAR(20) DEFAULT 'normal',
    p_is_internal BOOLEAN DEFAULT FALSE,
    p_reply_to_id UUID DEFAULT NULL,
    p_tags TEXT[] DEFAULT ARRAY[]::TEXT[]
) RETURNS UUID LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_feedback_id UUID;
    v_admin_name VARCHAR(255);
    v_thread_id UUID;
    caller_role TEXT;
BEGIN
    -- Check if the caller is an admin
    SELECT raw_user_meta_data->>'role' INTO caller_role
    FROM auth.users WHERE id = auth.uid();

    IF caller_role != 'admin' THEN
        RAISE EXCEPTION 'Only admins can create feedback.';
    END IF;
    
    -- Get admin name
    SELECT COALESCE(up.public_name, au.email) INTO v_admin_name
    FROM auth.users au
    LEFT JOIN user_profiles up ON au.id = up.user_id
    WHERE au.id = p_admin_user_id;
    
    -- Determine thread ID
    IF p_reply_to_id IS NOT NULL THEN
        -- This is a reply, use the same thread
        SELECT thread_id INTO v_thread_id 
        FROM admin_feedback 
        WHERE id = p_reply_to_id;
    ELSE
        -- New conversation thread
        v_thread_id := gen_random_uuid();
    END IF;
    
    -- Insert feedback
    INSERT INTO admin_feedback (
        admin_user_id,
        admin_name,
        target_user_id,
        context_type,
        context_entity_id,
        subject,
        content,
        priority,
        is_internal,
        thread_id,
        reply_to_id,
        tags,
        status
    ) VALUES (
        p_admin_user_id,
        v_admin_name,
        p_target_user_id,
        p_context_type,
        p_context_entity_id,
        p_subject,
        p_content,
        p_priority,
        p_is_internal,
        v_thread_id,
        p_reply_to_id,
        p_tags,
        CASE WHEN p_is_internal THEN 'DRAFT' ELSE 'SENT' END
    ) RETURNING id INTO v_feedback_id;
    
    -- Log the feedback creation
    PERFORM log_admin_action(
        p_admin_user_id := p_admin_user_id,
        p_target_user_id := p_target_user_id,
        p_target_entity_type := 'admin_feedback',
        p_target_entity_id := v_feedback_id,
        p_action_type := 'SYSTEM_CONFIGURATION', -- Using available enum value
        p_action_severity := 'LOW',
        p_action_summary := 'Created admin feedback: ' || p_subject,
        p_reason := 'Admin feedback communication',
        p_metadata := jsonb_build_object(
            'context_type', p_context_type,
            'priority', p_priority,
            'is_internal', p_is_internal
        )
    );
    
    RETURN v_feedback_id;
END;
$$;

-- 3. Get audit logs with enhanced filtering
CREATE OR REPLACE FUNCTION get_admin_audit_logs_enhanced(
    p_action_types TEXT[] DEFAULT NULL, -- Array of action types
    p_action_severity "ActionSeverity" DEFAULT NULL,
    p_admin_user_id UUID DEFAULT NULL,
    p_target_user_id UUID DEFAULT NULL,
    p_target_entity_type VARCHAR(50) DEFAULT NULL,
    p_start_date TIMESTAMPTZ DEFAULT NULL,
    p_end_date TIMESTAMPTZ DEFAULT NULL,
    p_search_term TEXT DEFAULT NULL, -- Search in action_summary and reason
    p_limit INTEGER DEFAULT 50,
    p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
    id UUID,
    admin_user_id UUID,
    admin_email VARCHAR(255),
    target_user_id UUID,
    target_user_email VARCHAR(255),
    target_entity_type VARCHAR(50),
    target_entity_id UUID,
    action_type "AdminActionType",
    action_severity "ActionSeverity",
    action_summary VARCHAR(500),
    reason TEXT,
    old_values JSONB,
    new_values JSONB,
    metadata JSONB,
    created_at TIMESTAMPTZ
) LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    caller_role TEXT;
BEGIN
    -- Check if the caller is an admin
    SELECT raw_user_meta_data->>'role' INTO caller_role
    FROM auth.users WHERE id = auth.uid();

    IF caller_role != 'admin' THEN
        RAISE EXCEPTION 'Only admins can view audit logs.';
    END IF;

    RETURN QUERY
    SELECT 
        aal.id,
        aal.admin_user_id,
        aal.admin_email,
        aal.target_user_id,
        aal.target_user_email,
        aal.target_entity_type,
        aal.target_entity_id,
        aal.action_type,
        aal.action_severity,
        aal.action_summary,
        aal.reason,
        aal.old_values,
        aal.new_values,
        aal.metadata,
        aal.created_at
    FROM admin_audit_log aal
    WHERE 
        (p_action_types IS NULL OR aal.action_type = ANY(p_action_types))
        AND (p_action_severity IS NULL OR aal.action_severity = p_action_severity)
        AND (p_admin_user_id IS NULL OR aal.admin_user_id = p_admin_user_id)
        AND (p_target_user_id IS NULL OR aal.target_user_id = p_target_user_id)
        AND (p_target_entity_type IS NULL OR aal.target_entity_type = p_target_entity_type)
        AND (p_start_date IS NULL OR aal.created_at >= p_start_date)
        AND (p_end_date IS NULL OR aal.created_at <= p_end_date)
        AND (p_search_term IS NULL OR 
             aal.action_summary ILIKE '%' || p_search_term || '%' OR
             aal.reason ILIKE '%' || p_search_term || '%')
    ORDER BY aal.created_at DESC
    LIMIT p_limit
    OFFSET p_offset;
END;
$$;

-- 4. Get audit logs count with same filtering
CREATE OR REPLACE FUNCTION get_admin_audit_logs_count_enhanced(
    p_action_types TEXT[] DEFAULT NULL,
    p_action_severity "ActionSeverity" DEFAULT NULL,
    p_admin_user_id UUID DEFAULT NULL,
    p_target_user_id UUID DEFAULT NULL,
    p_target_entity_type VARCHAR(50) DEFAULT NULL,
    p_start_date TIMESTAMPTZ DEFAULT NULL,
    p_end_date TIMESTAMPTZ DEFAULT NULL,
    p_search_term TEXT DEFAULT NULL
)
RETURNS INTEGER LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    caller_role TEXT;
    v_count INTEGER;
BEGIN
    -- Check if caller is admin
    SELECT raw_user_meta_data->>'role' INTO caller_role
    FROM auth.users WHERE id = auth.uid();

    IF caller_role != 'admin' THEN
        RAISE EXCEPTION 'Only admins can view audit logs.';
    END IF;

    SELECT COUNT(*)::INTEGER INTO v_count
    FROM admin_audit_log aal
    WHERE 
        (p_action_types IS NULL OR aal.action_type = ANY(p_action_types))
        AND (p_action_severity IS NULL OR aal.action_severity = p_action_severity)
        AND (p_admin_user_id IS NULL OR aal.admin_user_id = p_admin_user_id)
        AND (p_target_user_id IS NULL OR aal.target_user_id = p_target_user_id)
        AND (p_target_entity_type IS NULL OR aal.target_entity_type = p_target_entity_type)
        AND (p_start_date IS NULL OR aal.created_at >= p_start_date)
        AND (p_end_date IS NULL OR aal.created_at <= p_end_date)
        AND (p_search_term IS NULL OR 
             aal.action_summary ILIKE '%' || p_search_term || '%' OR
             aal.reason ILIKE '%' || p_search_term || '%');

    RETURN v_count;
END;
$$;

-- 5. Get admin feedback with conversation threading
CREATE OR REPLACE FUNCTION get_admin_feedback_conversation(
    p_target_user_id UUID,
    p_context_type VARCHAR(50) DEFAULT NULL,
    p_context_entity_id UUID DEFAULT NULL,
    p_include_internal BOOLEAN DEFAULT FALSE,
    p_limit INTEGER DEFAULT 50
)
RETURNS TABLE (
    id UUID,
    admin_user_id UUID,
    admin_name VARCHAR(255),
    target_user_id UUID,
    context_type VARCHAR(50),
    context_entity_id UUID,
    subject VARCHAR(200),
    content TEXT,
    status "FeedbackStatus",
    thread_id UUID,
    reply_to_id UUID,
    is_internal BOOLEAN,
    priority VARCHAR(20),
    tags TEXT[],
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ,
    sent_at TIMESTAMPTZ,
    read_at TIMESTAMPTZ
) LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    caller_role TEXT;
BEGIN
    -- Check if the caller is an admin or the target user
    SELECT raw_user_meta_data->>'role' INTO caller_role
    FROM auth.users WHERE id = auth.uid();

    IF caller_role != 'admin' AND auth.uid() != p_target_user_id THEN
        RAISE EXCEPTION 'Access denied to feedback conversation.';
    END IF;

    RETURN QUERY
    SELECT 
        af.id,
        af.admin_user_id,
        af.admin_name,
        af.target_user_id,
        af.context_type,
        af.context_entity_id,
        af.subject,
        af.content,
        af.status,
        af.thread_id,
        af.reply_to_id,
        af.is_internal,
        af.priority,
        af.tags,
        af.created_at,
        af.updated_at,
        af.sent_at,
        af.read_at
    FROM admin_feedback af
    WHERE 
        af.target_user_id = p_target_user_id
        AND (p_context_type IS NULL OR af.context_type = p_context_type)
        AND (p_context_entity_id IS NULL OR af.context_entity_id = p_context_entity_id)
        AND (p_include_internal = TRUE OR af.is_internal = FALSE)
    ORDER BY af.thread_id, af.created_at ASC
    LIMIT p_limit;
END;
$$;

-- 6. Update existing review_verification function to use new audit system
CREATE OR REPLACE FUNCTION review_verification(
    p_user_id UUID,
    p_action TEXT,
    p_feedback TEXT DEFAULT NULL
) RETURNS BOOLEAN LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_user_profile RECORD;
    v_new_status "ProfileStatus";
    caller_role TEXT;
    v_admin_user_id UUID;
    v_old_status "ProfileStatus";
    v_feedback_id UUID;
BEGIN
    -- Get caller info
    SELECT id, raw_user_meta_data->>'role' 
    INTO v_admin_user_id, caller_role
    FROM auth.users WHERE id = auth.uid();

    IF caller_role != 'admin' THEN
        RAISE EXCEPTION 'Only admins can review verifications.';
    END IF;

    -- Validate action
    IF p_action NOT IN ('approve', 'reject') THEN
        RAISE EXCEPTION 'Invalid action. Must be "approve" or "reject".';
    END IF;

    -- Get current user profile
    SELECT * INTO v_user_profile
    FROM user_profiles WHERE user_id = p_user_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'User profile not found.';
    END IF;

    v_old_status := v_user_profile.verification_status;

    -- Determine new status
    v_new_status := CASE 
        WHEN p_action = 'approve' THEN 'APPROVED'::ProfileStatus
        WHEN p_action = 'reject' THEN 'REJECTED'::ProfileStatus
    END;

    -- Update user profile
    UPDATE user_profiles SET
        verification_status = v_new_status,
        admin_feedback = p_feedback,
        verified_at = CASE WHEN p_action = 'approve' THEN NOW() ELSE NULL END,
        updated_at = NOW()
    WHERE user_id = p_user_id;

    -- Create admin feedback if provided
    IF p_feedback IS NOT NULL THEN
        SELECT create_admin_feedback(
            p_admin_user_id := v_admin_user_id,
            p_target_user_id := p_user_id,
            p_context_type := 'verification',
            p_context_entity_id := p_user_id,
            p_subject := 'Verification ' || CASE 
                WHEN p_action = 'approve' THEN 'Approved' 
                ELSE 'Rejected' 
            END,
            p_content := p_feedback,
            p_priority := 'high'
        ) INTO v_feedback_id;
    END IF;

    -- Log the verification review
    PERFORM log_admin_action(
        p_admin_user_id := v_admin_user_id,
        p_target_user_id := p_user_id,
        p_target_entity_type := 'user_profile',
        p_target_entity_id := p_user_id,
        p_action_type := 'VERIFICATION_REVIEW',
        p_action_severity := 'MEDIUM',
        p_action_summary := 'Verification ' || p_action || ' for user',
        p_reason := COALESCE(p_feedback, 'Verification review action'),
        p_old_values := jsonb_build_object(
            'verification_status', v_old_status,
            'admin_feedback', v_user_profile.admin_feedback
        ),
        p_new_values := jsonb_build_object(
            'verification_status', v_new_status,
            'admin_feedback', p_feedback,
            'verified_at', CASE WHEN p_action = 'approve' THEN NOW() ELSE NULL END
        ),
        p_metadata := jsonb_build_object(
            'action', p_action,
            'feedback_id', v_feedback_id,
            'verification_documents_count', array_length(v_user_profile.supporting_documents, 1)
        )
    );

    RETURN TRUE;
END;
$$;

-- 7. Enhanced admin role change function
CREATE OR REPLACE FUNCTION admin_change_user_role_enhanced(
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
    v_admin_user_id UUID;
BEGIN
    -- Get caller info
    SELECT id, raw_user_meta_data->>'role' 
    INTO v_admin_user_id, caller_role
    FROM auth.users WHERE id = auth.uid();

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

    -- Log role change with enhanced audit
    PERFORM log_admin_action(
        p_admin_user_id := v_admin_user_id,
        p_target_user_id := p_target_user_id,
        p_target_entity_type := 'user_account',
        p_target_entity_id := p_target_user_id,
        p_action_type := 'ROLE_CHANGE',
        p_action_severity := CASE 
            WHEN p_new_role = 'admin' OR current_role = 'admin' THEN 'CRITICAL'
            ELSE 'HIGH'
        END,
        p_action_summary := 'Changed user role from ' || current_role || ' to ' || p_new_role,
        p_reason := p_reason,
        p_old_values := jsonb_build_object('role', current_role),
        p_new_values := jsonb_build_object('role', p_new_role),
        p_metadata := jsonb_build_object(
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
                WHEN p_new_role = 'admin' OR current_role = 'admin' THEN 'critical'
                ELSE 'medium'
            END
        )
    );
    
    RETURN TRUE;
END;
$$;

-- 8. Get recent admin activity with enhanced data
CREATE OR REPLACE FUNCTION get_recent_admin_activity_enhanced(
    p_limit INTEGER DEFAULT 50,
    p_severity_filter "ActionSeverity" DEFAULT NULL
)
RETURNS TABLE (
    id UUID,
    admin_email VARCHAR(255),
    target_user_email VARCHAR(255),
    action_type "AdminActionType",
    action_severity "ActionSeverity",
    action_summary VARCHAR(500),
    target_entity_type VARCHAR(50),
    created_at TIMESTAMPTZ,
    reason TEXT
) LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    caller_role TEXT;
BEGIN
    -- Check if the caller is an admin
    SELECT raw_user_meta_data->>'role' INTO caller_role
    FROM auth.users WHERE id = auth.uid();

    IF caller_role != 'admin' THEN
        RAISE EXCEPTION 'Only admins can view recent activity.';
    END IF;

    RETURN QUERY
    SELECT 
        aal.id,
        aal.admin_email,
        aal.target_user_email,
        aal.action_type,
        aal.action_severity,
        aal.action_summary,
        aal.target_entity_type,
        aal.created_at,
        aal.reason
    FROM admin_audit_log aal
    WHERE 
        aal.created_at > NOW() - INTERVAL '30 days'
        AND (p_severity_filter IS NULL OR aal.action_severity = p_severity_filter)
    ORDER BY aal.created_at DESC
    LIMIT p_limit;
END;
$$;

-- 9. System statistics with audit metrics
CREATE OR REPLACE FUNCTION admin_get_system_stats_enhanced()
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
    -- New audit-related metrics
    total_audit_entries BIGINT,
    critical_actions_today BIGINT,
    high_severity_actions_week BIGINT,
    unique_admin_users_month BIGINT,
    -- Existing revenue metrics
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
    FROM auth.users WHERE id = auth.uid();

    IF caller_role != 'admin' THEN
        RAISE EXCEPTION 'Only admins can view system statistics.';
    END IF;

    RETURN QUERY
    SELECT 
        -- Existing metrics
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
        
        -- New audit metrics
        (SELECT COUNT(*) FROM admin_audit_log) as total_audit_entries,
        (SELECT COUNT(*) FROM admin_audit_log WHERE action_severity = 'CRITICAL' AND created_at >= CURRENT_DATE) as critical_actions_today,
        (SELECT COUNT(*) FROM admin_audit_log WHERE action_severity IN ('HIGH', 'CRITICAL') AND created_at >= CURRENT_DATE - INTERVAL '7 days') as high_severity_actions_week,
        (SELECT COUNT(DISTINCT admin_user_id) FROM admin_audit_log WHERE created_at >= CURRENT_DATE - INTERVAL '30 days') as unique_admin_users_month,
        
        -- Existing revenue metrics
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

-- 10. Create maintenance functions
CREATE OR REPLACE FUNCTION cleanup_old_audit_logs()
RETURNS TABLE (
    archived_count INTEGER,
    deleted_count INTEGER
) LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_archived_count INTEGER := 0;
    v_deleted_count INTEGER := 0;
    retention_cutoff TIMESTAMP WITH TIME ZONE;
BEGIN
    -- Archive logs older than 2 years to archive table
    retention_cutoff := NOW() - INTERVAL '2 years';
    
    CREATE TABLE IF NOT EXISTS admin_audit_log_archive (
        LIKE admin_audit_log INCLUDING ALL
    );
    
    WITH moved_rows AS (
        DELETE FROM admin_audit_log 
        WHERE created_at < retention_cutoff
        RETURNING *
    )
    INSERT INTO admin_audit_log_archive 
    SELECT * FROM moved_rows;
    
    GET DIAGNOSTICS v_archived_count = ROW_COUNT;
    
    -- Delete very old archive data (older than 7 years)
    DELETE FROM admin_audit_log_archive 
    WHERE created_at < NOW() - INTERVAL '7 years';
    
    GET DIAGNOSTICS v_deleted_count = ROW_COUNT;
    
    RETURN QUERY SELECT v_archived_count, v_deleted_count;
END;
$$;

COMMENT ON FUNCTION log_admin_action IS 'Centralized function for creating standardized audit log entries';
COMMENT ON FUNCTION create_admin_feedback IS 'Creates admin feedback with automatic threading and audit logging';
COMMENT ON FUNCTION get_admin_audit_logs_enhanced IS 'Enhanced audit log retrieval with comprehensive filtering';
COMMENT ON FUNCTION get_admin_feedback_conversation IS 'Retrieves threaded admin feedback conversations';
COMMENT ON FUNCTION cleanup_old_audit_logs IS 'Automated maintenance for audit log archival and cleanup';