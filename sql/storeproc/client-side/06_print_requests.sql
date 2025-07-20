-- =================================================================
-- PRINT REQUEST FUNCTIONS
-- Functions for managing physical card printing requests
-- =================================================================

-- Request card printing for a batch
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

    -- NEW: Validate payment status
    IF NOT v_payment_completed AND NOT v_payment_waived THEN
        RAISE EXCEPTION 'Payment must be completed or waived before requesting card printing.';
    END IF;

    -- NEW: Validate cards are generated
    IF NOT v_cards_generated THEN
        RAISE EXCEPTION 'Cards must be generated before requesting printing. Please contact support if payment was completed but cards are not generated.';
    END IF;

    -- Check if there is already an active print request for this batch
    IF EXISTS (
        SELECT 1 FROM print_requests pr
        WHERE pr.batch_id = p_batch_id AND pr.status NOT IN ('COMPLETED', 'CANCELLED')
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

-- Request card printing for a batch with shipping address ID
CREATE OR REPLACE FUNCTION request_card_printing_with_address(
    p_batch_id UUID, 
    p_shipping_address_id UUID
)
RETURNS UUID LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_print_request_id UUID;
    v_user_id UUID;
    v_batch_is_disabled BOOLEAN;
    v_payment_completed BOOLEAN;
    v_payment_waived BOOLEAN;
    v_cards_generated BOOLEAN;
    v_formatted_address TEXT;
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

    -- NEW: Validate payment status
    IF NOT v_payment_completed AND NOT v_payment_waived THEN
        RAISE EXCEPTION 'Payment must be completed or waived before requesting card printing.';
    END IF;

    -- NEW: Validate cards are generated
    IF NOT v_cards_generated THEN
        RAISE EXCEPTION 'Cards must be generated before requesting printing. Please contact support if payment was completed but cards are not generated.';
    END IF;

    -- Check if there is already an active print request for this batch
    IF EXISTS (
        SELECT 1 FROM print_requests pr
        WHERE pr.batch_id = p_batch_id AND pr.status NOT IN ('COMPLETED', 'CANCELLED')
    ) THEN
        RAISE EXCEPTION 'An active print request already exists for this batch.';
    END IF;

    -- Get formatted address
    SELECT format_shipping_address(p_shipping_address_id) INTO v_formatted_address;

    INSERT INTO print_requests (
        batch_id,
        user_id,
        shipping_address,
        status
    ) VALUES (
        p_batch_id,
        auth.uid(),
        v_formatted_address,
        'SUBMITTED'
    )
    RETURNING id INTO v_print_request_id;

    RETURN v_print_request_id;
END;
$$;

-- Get print requests for a batch
CREATE OR REPLACE FUNCTION get_print_requests_for_batch(p_batch_id UUID)
RETURNS TABLE (
    id UUID,
    batch_id UUID,
    user_id UUID,
    status TEXT, -- "PrintRequestStatus"
    shipping_address TEXT,
    contact_email TEXT,
    contact_whatsapp TEXT,
    admin_notes TEXT,
    requested_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ
) LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_user_id_check UUID;
BEGIN
    -- Check if the user owns the card associated with the batch
    SELECT c.user_id INTO v_user_id_check
    FROM card_batches cb
    JOIN cards c ON cb.card_id = c.id
    WHERE cb.id = p_batch_id;

    IF v_user_id_check IS NULL THEN
        RAISE EXCEPTION 'Batch not found.';
    END IF;

    IF v_user_id_check != auth.uid() THEN
        RAISE EXCEPTION 'Not authorized to view print requests for this batch.';
    END IF;

    RETURN QUERY
    SELECT 
        pr.id,
        pr.batch_id,
        pr.user_id,
        pr.status::TEXT, -- Cast ENUM to TEXT for broader client compatibility if needed
        pr.shipping_address,
        pr.contact_email,
        pr.contact_whatsapp,
        pr.admin_notes,
        pr.requested_at,
        pr.updated_at
    FROM print_requests pr
    WHERE pr.batch_id = p_batch_id
    ORDER BY pr.requested_at DESC;
END;
$$;

-- Withdraw/Cancel a print request (card issuer only)
CREATE OR REPLACE FUNCTION withdraw_print_request(
    p_request_id UUID,
    p_withdrawal_reason TEXT DEFAULT NULL
)
RETURNS BOOLEAN LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_user_id UUID;
    v_current_status "PrintRequestStatus";
    v_batch_id UUID;
    v_card_name TEXT;
    v_batch_name TEXT;
BEGIN
    -- Get print request details and verify ownership
    SELECT pr.user_id, pr.status, pr.batch_id, c.name, cb.batch_name
    INTO v_user_id, v_current_status, v_batch_id, v_card_name, v_batch_name
    FROM print_requests pr
    JOIN card_batches cb ON pr.batch_id = cb.id
    JOIN cards c ON cb.card_id = c.id
    WHERE pr.id = p_request_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Print request not found.';
    END IF;

    -- Check authorization
    IF v_user_id != auth.uid() THEN
        RAISE EXCEPTION 'Not authorized to withdraw this print request.';
    END IF;

    -- Check if withdrawal is allowed based on current status
    IF v_current_status != 'SUBMITTED' THEN
        RAISE EXCEPTION 'Print request can only be withdrawn when status is SUBMITTED. Current status: %', v_current_status;
    END IF;

    -- Update the print request status to CANCELLED
    UPDATE print_requests
    SET 
        status = 'CANCELLED',
        admin_notes = CASE 
            WHEN admin_notes IS NULL OR admin_notes = '' THEN 
                'Withdrawn by card issuer' || COALESCE(': ' || p_withdrawal_reason, '')
            ELSE 
                admin_notes || E'\n\n[WITHDRAWN] ' || COALESCE(p_withdrawal_reason, 'Withdrawn by card issuer')
        END,
        updated_at = NOW()
    WHERE id = p_request_id;

    -- Log the withdrawal in audit table for admin visibility
    INSERT INTO admin_audit_log (
        admin_user_id,
        target_user_id,
        action_type,
        reason,
        old_values,
        new_values,
        action_details
    ) VALUES (
        auth.uid(), -- The card issuer is performing this action
        auth.uid(), -- They are the target user as well
        'PRINT_REQUEST_WITHDRAWAL',
        COALESCE(p_withdrawal_reason, 'Print request withdrawn by card issuer'),
        jsonb_build_object(
            'status', 'SUBMITTED'
        ),
        jsonb_build_object(
            'status', 'CANCELLED',
            'withdrawal_reason', p_withdrawal_reason
        ),
        jsonb_build_object(
            'request_id', p_request_id,
            'batch_id', v_batch_id,
            'card_name', v_card_name,
            'batch_name', v_batch_name,
            'self_withdrawal', true
        )
    );
    
    RETURN FOUND;
END;
$$; 