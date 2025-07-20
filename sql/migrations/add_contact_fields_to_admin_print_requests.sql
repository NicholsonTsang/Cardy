-- Migration: Add contact fields to print_requests table and admin functions
-- Description: Add contact_email and contact_whatsapp columns to print_requests table and update functions

-- First, add the missing columns to the print_requests table
ALTER TABLE print_requests 
ADD COLUMN IF NOT EXISTS contact_email TEXT,
ADD COLUMN IF NOT EXISTS contact_whatsapp TEXT;

-- Add comments for documentation
COMMENT ON COLUMN print_requests.contact_email IS 'Email address for print request communication';
COMMENT ON COLUMN print_requests.contact_whatsapp IS 'WhatsApp number for print request communication (including country code)';

-- Update admin_get_all_print_requests function
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

-- Update alias function for backward compatibility
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