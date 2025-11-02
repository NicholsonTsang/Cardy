-- Fix audit logging action_details to distinguish between approval and rejection
-- This replaces the generic 'review_verification': true with specific action details

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

    -- Log in audit table with specific action details
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