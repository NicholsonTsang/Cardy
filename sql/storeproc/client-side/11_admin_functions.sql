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
        pr.id,
        pr.batch_id,
        pr.user_id,
        au.email as user_email,
        up.public_name as user_public_name,
        c.name as card_name,
        cb.batch_name,
        cb.cards_count,
        pr.status,
        pr.shipping_address,
        pr.admin_notes,
        pr.requested_at,
        pr.updated_at
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
        p_admin_notes,
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
    pending_print_requests BIGINT,
    total_revenue_cents BIGINT,
    pending_verifications BIGINT
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
        (SELECT COUNT(*) FROM print_requests WHERE status NOT IN ('COMPLETED', 'CANCELLED')) as pending_print_requests,
        (SELECT COALESCE(SUM(amount_cents), 0) FROM batch_payments WHERE payment_status = 'succeeded') as total_revenue_cents,
        (SELECT COUNT(*) FROM user_profiles WHERE verification_status = 'PENDING_REVIEW') as pending_verifications;
END;
$$;

-- (Admin) Get pending verification requests
CREATE OR REPLACE FUNCTION admin_get_pending_verifications(p_limit INTEGER DEFAULT 50)
RETURNS TABLE (
    user_id UUID,
    email TEXT,
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

    INSERT INTO admin_feedback (
        admin_user_id,
        target_user_id,
        related_entity_id,
        feedback_type,
        feedback_category,
        feedback_text,
        metadata
    ) VALUES (
        auth.uid(),
        p_target_user_id,
        p_related_entity_id,
        p_feedback_type,
        p_feedback_category,
        p_feedback_text,
        p_metadata
    )
    RETURNING id INTO v_feedback_id;
    
    RETURN v_feedback_id;
END;
$$; 