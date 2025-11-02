-- Fix review_verification function - remove call to non-existent admin_feedback table
-- Also fix create_or_update_admin_feedback function to use correct table

CREATE OR REPLACE FUNCTION public.review_verification(
    p_target_user_id UUID,
    p_new_status "ProfileStatus",
    p_admin_feedback TEXT
)
RETURNS BOOLEAN
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    caller_role TEXT;
BEGIN
    -- Check if the caller is an admin
    SELECT raw_user_meta_data->>'role' INTO caller_role
    FROM auth.users
    WHERE id = auth.uid();

    IF caller_role != 'admin' THEN
        RAISE EXCEPTION 'Only admins can review verifications.';
    END IF;

    -- Ensure status is only set to APPROVED or REJECTED
    IF p_new_status NOT IN ('APPROVED', 'REJECTED') THEN
        RAISE EXCEPTION 'Review status must be APPROVED or REJECTED.';
    END IF;

    UPDATE public.user_profiles
    SET 
        verification_status = p_new_status,
        admin_feedback = p_admin_feedback,
        verified_at = CASE WHEN p_new_status = 'APPROVED' THEN NOW() ELSE NULL END,
        updated_at = NOW()
    WHERE user_id = p_target_user_id;

    -- Feedback is stored in admin_feedback column of user_profiles
    -- and logged in admin_audit_log table below

    -- Log in audit table
    INSERT INTO admin_audit_log (
        admin_user_id,
        target_user_id,
        action_type,
        reason,
        new_values,
        action_details
    ) VALUES (
        auth.uid(),
        p_target_user_id,
        'VERIFICATION_REVIEW',
        p_admin_feedback,
        jsonb_build_object(
            'verification_status', p_new_status,
            'verified_at', CASE WHEN p_new_status = 'APPROVED' THEN NOW() ELSE NULL END
        ),
        jsonb_build_object(
            'action', CASE 
                WHEN p_new_status = 'APPROVED' THEN 'verification_approved'
                WHEN p_new_status = 'REJECTED' THEN 'verification_rejected'
                ELSE 'verification_reviewed'
            END,
            'review_type', p_new_status::TEXT,
            'has_feedback', (p_admin_feedback IS NOT NULL AND LENGTH(TRIM(p_admin_feedback)) > 0)
        )
    );
    
    RETURN FOUND;
END;
$$;

-- Fix create_or_update_admin_feedback function to use admin_feedback_history table
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

-- Add missing get_verification_by_id function
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