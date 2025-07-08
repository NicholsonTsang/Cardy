-- =================================================================
-- USER PROFILE FUNCTIONS
-- Functions for user profile management and verification
-- =================================================================

-- Get the profile for the currently authenticated user
CREATE OR REPLACE FUNCTION public.get_user_profile()
RETURNS TABLE (
    user_id UUID,
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
)
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
    RETURN QUERY
    SELECT 
        up.user_id,
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
    WHERE up.user_id = auth.uid();
END;
$$;

-- Create or Update basic user profile (no verification)
CREATE OR REPLACE FUNCTION public.create_or_update_basic_profile(
    p_public_name TEXT,
    p_bio TEXT,
    p_company_name TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_user_id UUID := auth.uid();
BEGIN
    INSERT INTO public.user_profiles (user_id, public_name, bio, company_name)
    VALUES (v_user_id, p_public_name, p_bio, p_company_name)
    ON CONFLICT (user_id) DO UPDATE 
    SET 
        public_name = EXCLUDED.public_name,
        bio = EXCLUDED.bio,
        company_name = EXCLUDED.company_name,
        updated_at = NOW();
    
    RETURN v_user_id;
END;
$$;

-- Submit verification application
CREATE OR REPLACE FUNCTION public.submit_verification(
    p_full_name TEXT,
    p_supporting_documents TEXT[]
)
RETURNS UUID
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_user_id UUID := auth.uid();
BEGIN
    -- Update the profile with verification info
    UPDATE public.user_profiles 
    SET 
        full_name = p_full_name,
        supporting_documents = p_supporting_documents,
        verification_status = 'PENDING_REVIEW',
        admin_feedback = NULL, -- Clear previous feedback
        updated_at = NOW()
    WHERE user_id = v_user_id;
    
    -- If no profile exists yet, create one (shouldn't happen in normal flow)
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Profile must be created before submitting verification';
    END IF;
    
    RETURN v_user_id;
END;
$$;

-- (Admin) Function to review a verification
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

    -- Create feedback history entry with full traceability
    PERFORM create_or_update_admin_feedback(
        'user_verification',
        p_target_user_id,
        p_target_user_id,
        'verification_feedback',
        p_admin_feedback,
        jsonb_build_object(
            'action', 'verification_review',
            'new_status', p_new_status,
            'timestamp', NOW()
        )
    );

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
        jsonb_build_object('review_verification', true)
    );
    
    RETURN FOUND;
END;
$$;

-- (User) Function to withdraw verification submission
CREATE OR REPLACE FUNCTION public.withdraw_verification()
RETURNS BOOLEAN
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_current_status "ProfileStatus";
BEGIN
    -- Get current verification status
    SELECT verification_status INTO v_current_status
    FROM public.user_profiles
    WHERE user_id = v_user_id;
    
    -- Only allow withdrawal if status is PENDING_REVIEW
    IF v_current_status != 'PENDING_REVIEW' THEN
        RAISE EXCEPTION 'Verification can only be withdrawn when status is PENDING_REVIEW. Current status: %', v_current_status;
    END IF;

    -- Reset verification status and clear verification data
    UPDATE public.user_profiles
    SET 
        verification_status = 'NOT_SUBMITTED',
        full_name = NULL,
        supporting_documents = NULL,
        admin_feedback = NULL,
        verified_at = NULL,
        updated_at = NOW()
    WHERE user_id = v_user_id;
    
    RETURN FOUND;
END;
$$; 