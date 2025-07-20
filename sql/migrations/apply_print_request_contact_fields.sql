-- Migration: Apply print request contact fields and update functions
-- Description: Ensure print_requests table has contact fields and functions are updated

-- First, add contact fields to print_requests table if they don't exist
ALTER TABLE print_requests 
ADD COLUMN IF NOT EXISTS contact_email TEXT,
ADD COLUMN IF NOT EXISTS contact_whatsapp TEXT;

-- Add comments for documentation
COMMENT ON COLUMN print_requests.contact_email IS 'Email address for print request communication';
COMMENT ON COLUMN print_requests.contact_whatsapp IS 'WhatsApp number for print request communication (including country code)';

-- Drop the old function signature if it exists
DROP FUNCTION IF EXISTS request_card_printing(UUID, TEXT) CASCADE;

-- Create the new function with contact information parameters
CREATE OR REPLACE FUNCTION request_card_printing(
    p_batch_id UUID, 
    p_shipping_address TEXT,
    p_contact_email TEXT DEFAULT NULL,
    p_contact_whatsapp TEXT DEFAULT NULL
)
RETURNS UUID LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_print_request_id UUID;
    v_user_id UUID;
    v_batch_is_disabled BOOLEAN;
    v_payment_completed BOOLEAN;
    v_payment_waived BOOLEAN;
    v_cards_generated BOOLEAN;
    v_user_email TEXT;
BEGIN
    -- Check if the user owns the card associated with the batch and get payment status
    SELECT c.user_id, cb.is_disabled, cb.payment_completed, cb.payment_waived, cb.cards_generated
    INTO v_user_id, v_batch_is_disabled, v_payment_completed, v_payment_waived, v_cards_generated
    FROM card_batches cb
    JOIN cards c ON cb.card_id = c.id
    WHERE cb.id = p_batch_id;

    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Batch not found.';
    END IF;

    IF v_user_id != auth.uid() THEN
        RAISE EXCEPTION 'Not authorized to request printing for this batch.';
    END IF;

    IF v_batch_is_disabled THEN
        RAISE EXCEPTION 'Cannot request printing for a disabled batch.';
    END IF;

    -- Validate payment status
    IF NOT (v_payment_completed OR v_payment_waived) THEN
        RAISE EXCEPTION 'Payment must be completed or waived before requesting card printing.';
    END IF;

    -- Validate cards are generated
    IF NOT v_cards_generated THEN
        RAISE EXCEPTION 'Cards must be generated before requesting printing. Please contact support if payment was completed but cards are not generated.';
    END IF;

    -- Check if an active print request already exists
    IF EXISTS (
        SELECT 1 FROM print_requests pr
        WHERE pr.batch_id = p_batch_id 
        AND pr.status NOT IN ('COMPLETED', 'CANCELLED')
    ) THEN
        RAISE EXCEPTION 'An active print request already exists for this batch.';
    END IF;

    -- Get user email for fallback if no contact email provided
    SELECT email INTO v_user_email 
    FROM auth.users 
    WHERE id = auth.uid();

    INSERT INTO print_requests (
        batch_id,
        user_id,
        shipping_address,
        contact_email,
        contact_whatsapp,
        status
    ) VALUES (
        p_batch_id,
        auth.uid(),
        p_shipping_address,
        COALESCE(p_contact_email, v_user_email),
        p_contact_whatsapp,
        'SUBMITTED'
    )
    RETURNING id INTO v_print_request_id;

    RETURN v_print_request_id;
END;
$$;

-- Also update the get_print_requests_for_batch function to return contact fields
DROP FUNCTION IF EXISTS get_print_requests_for_batch(UUID) CASCADE;

CREATE OR REPLACE FUNCTION get_print_requests_for_batch(p_batch_id UUID)
RETURNS TABLE (
    id UUID,
    batch_id UUID,
    user_id UUID,
    status "PrintRequestStatus",
    shipping_address TEXT,
    contact_email TEXT,
    contact_whatsapp TEXT,
    admin_notes TEXT,
    requested_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ,
    batch_name TEXT,
    batch_number INTEGER,
    cards_count INTEGER,
    card_name TEXT,
    user_email TEXT,
    user_public_name TEXT
) LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
    -- Verify user has access to this batch
    IF NOT EXISTS (
        SELECT 1 
        FROM card_batches cb
        JOIN cards c ON cb.card_id = c.id
        WHERE cb.id = p_batch_id AND c.user_id = auth.uid()
    ) THEN
        RAISE EXCEPTION 'Access denied or batch not found.';
    END IF;

    RETURN QUERY
    SELECT 
        pr.id,
        pr.batch_id,
        pr.user_id,
        pr.status,
        pr.shipping_address,
        pr.contact_email,
        pr.contact_whatsapp,
        pr.admin_notes,
        pr.requested_at,
        pr.updated_at,
        cb.batch_name,
        cb.batch_number,
        cb.cards_count,
        c.name as card_name,
        u.email as user_email,
        up.public_name as user_public_name
    FROM print_requests pr
    JOIN card_batches cb ON pr.batch_id = cb.id
    JOIN cards c ON cb.card_id = c.id
    LEFT JOIN auth.users u ON pr.user_id = u.id
    LEFT JOIN user_profiles up ON pr.user_id = up.user_id
    WHERE pr.batch_id = p_batch_id
    ORDER BY pr.requested_at DESC;
END;
$$;

-- Grant permissions
GRANT EXECUTE ON FUNCTION request_card_printing TO authenticated;
GRANT EXECUTE ON FUNCTION get_print_requests_for_batch TO authenticated;

-- Verify the function exists with correct signature
SELECT routine_name, routine_type, data_type 
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name = 'request_card_printing';