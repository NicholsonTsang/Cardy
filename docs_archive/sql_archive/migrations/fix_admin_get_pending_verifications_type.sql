-- Fix admin_get_pending_verifications return type mismatch
-- The function was declaring email as TEXT but auth.users.email is VARCHAR(255)

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