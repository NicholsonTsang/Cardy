-- Migration: Fix admin print requests to include contact fields and correct column names
-- Description: Update admin print request functions to return contact information and fix column naming

-- Drop existing functions to recreate them
DROP FUNCTION IF EXISTS admin_get_all_print_requests CASCADE;
DROP FUNCTION IF EXISTS get_all_print_requests CASCADE;

-- (Admin) Get all print requests for review with contact information
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
    batch_number INTEGER,
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
    WHERE auth.users.id = auth.uid();

    IF caller_role != 'admin' THEN
        RAISE EXCEPTION 'Only admins can view all print requests.';
    END IF;

    RETURN QUERY
    SELECT 
        pr.id,
        pr.batch_id,
        pr.user_id,
        au.email::text AS user_email,
        up.public_name AS user_public_name,
        c.name AS card_name,
        cb.batch_name,
        cb.batch_number,
        cb.cards_count,
        pr.status,
        pr.shipping_address,
        pr.contact_email,
        pr.contact_whatsapp,
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
    batch_number INTEGER,
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
    RETURN QUERY
    SELECT * FROM admin_get_all_print_requests(p_status, 100);
END;
$$;

-- Update admin stats function to properly count print requests
CREATE OR REPLACE FUNCTION admin_get_system_stats()
RETURNS TABLE (
    total_users BIGINT,
    total_cards BIGINT,
    total_issued_cards BIGINT,
    total_activated_cards BIGINT,
    pending_verifications BIGINT,
    total_verified_users BIGINT,
    pending_print_requests BIGINT,
    total_batches BIGINT,
    total_revenue_cents BIGINT
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
        (SELECT COUNT(*) FROM auth.users)::BIGINT AS total_users,
        (SELECT COUNT(*) FROM cards)::BIGINT AS total_cards,
        (SELECT COUNT(*) FROM issue_cards)::BIGINT AS total_issued_cards,
        (SELECT COUNT(*) FROM issue_cards WHERE active = true)::BIGINT AS total_activated_cards,
        (SELECT COUNT(*) FROM user_profiles WHERE verification_status = 'PENDING_REVIEW')::BIGINT AS pending_verifications,
        (SELECT COUNT(*) FROM user_profiles WHERE verification_status = 'APPROVED')::BIGINT AS total_verified_users,
        (SELECT COUNT(*) FROM print_requests WHERE status IN ('SUBMITTED', 'PROCESSING'))::BIGINT AS pending_print_requests,
        (SELECT COUNT(*) FROM card_batches)::BIGINT AS total_batches,
        (SELECT COALESCE(SUM(payment_amount_cents), 0) FROM card_batches WHERE payment_completed = true)::BIGINT AS total_revenue_cents;
END;
$$;

-- Grant permissions
GRANT EXECUTE ON FUNCTION admin_get_all_print_requests TO authenticated;
GRANT EXECUTE ON FUNCTION get_all_print_requests TO authenticated;
GRANT EXECUTE ON FUNCTION admin_get_system_stats TO authenticated;