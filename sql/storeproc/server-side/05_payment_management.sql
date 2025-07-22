-- =================================================================
-- PAYMENT MANAGEMENT FUNCTIONS (SERVER-SIDE)
-- Functions called by Edge Functions for Stripe Checkout processing
-- =================================================================

-- Create Stripe checkout session payment record
CREATE OR REPLACE FUNCTION create_batch_checkout_payment(
    p_batch_id UUID,
    p_stripe_payment_intent_id TEXT,
    p_stripe_checkout_session_id TEXT,
    p_amount_cents INTEGER,
    p_metadata JSONB DEFAULT '{}'::jsonb
) RETURNS UUID LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_batch_owner_id UUID;
    v_batch_payment_amount INTEGER;
    v_payment_id UUID;
BEGIN
    -- Verify batch ownership and get expected amount
    SELECT cb.created_by, cb.payment_amount_cents 
    INTO v_batch_owner_id, v_batch_payment_amount
    FROM card_batches cb 
    WHERE cb.id = p_batch_id;
    
    IF v_batch_owner_id IS NULL THEN
        RAISE EXCEPTION 'Batch not found.';
    END IF;
    
    IF v_batch_owner_id != auth.uid() THEN
        RAISE EXCEPTION 'Not authorized to create payment for this batch.';
    END IF;
    
    -- Verify amount matches expected
    IF p_amount_cents != v_batch_payment_amount THEN
        RAISE EXCEPTION 'Payment amount mismatch. Expected: %, Provided: %', v_batch_payment_amount, p_amount_cents;
    END IF;
    
    -- Check if payment already exists for this batch
    IF EXISTS (SELECT 1 FROM batch_payments WHERE batch_id = p_batch_id) THEN
        RAISE EXCEPTION 'Payment already exists for this batch.';
    END IF;
    
    -- Validate required checkout session ID
    IF p_stripe_checkout_session_id IS NULL THEN
        RAISE EXCEPTION 'Checkout session ID is required.';
    END IF;
    
    -- Create payment record for checkout session
    INSERT INTO batch_payments (
        batch_id,
        user_id,
        stripe_payment_intent_id,
        stripe_checkout_session_id,
        amount_cents,
        currency,
        payment_status,
        metadata
    ) VALUES (
        p_batch_id,
        auth.uid(),
        p_stripe_payment_intent_id, -- Can be null in test mode
        p_stripe_checkout_session_id,
        p_amount_cents,
        'usd',
        'pending',
        p_metadata
    ) RETURNING id INTO v_payment_id;
    
    -- Log payment creation in audit table
    INSERT INTO admin_audit_log (
        admin_user_id,
        admin_email,
        target_user_id,
        target_user_email,
        action_type,
        description,
        details
    ) VALUES (
        auth.uid(),
        (SELECT email FROM auth.users WHERE id = auth.uid()),
        auth.uid(),
        (SELECT email FROM auth.users WHERE id = auth.uid()),
        'PAYMENT_CREATION',
        'Stripe checkout session payment created',
        jsonb_build_object(
            'payment_id', v_payment_id,
            'payment_status', 'pending',
            'amount_cents', p_amount_cents,
            'currency', 'usd',
            'action', 'payment_session_created',
            'stripe_checkout_session_id', p_stripe_checkout_session_id,
            'stripe_payment_intent_id', p_stripe_payment_intent_id,
            'batch_id', p_batch_id,
            'metadata', p_metadata
        )
    );
    
    RETURN v_payment_id;
END;
$$;


-- Get batch information for checkout session
CREATE OR REPLACE FUNCTION get_batch_for_checkout(p_batch_id UUID)
RETURNS TABLE (
    id UUID,
    card_id UUID,
    created_by UUID,
    batch_name TEXT,
    card_name TEXT,
    card_description TEXT,
    card_image_url TEXT
) LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
    RETURN QUERY
    SELECT 
        cb.id,
        cb.card_id,
        cb.created_by,
        cb.batch_name,
        c.name as card_name,
        c.description as card_description,
        c.image_url as card_image_url
    FROM card_batches cb
    JOIN cards c ON cb.card_id = c.id
    WHERE cb.id = p_batch_id 
    AND cb.created_by = auth.uid();
END;
$$;

-- Check existing payment for batch
CREATE OR REPLACE FUNCTION get_existing_batch_payment(p_batch_id UUID)
RETURNS TABLE (
    id UUID,
    payment_status TEXT,
    stripe_checkout_session_id TEXT,
    amount_cents INTEGER,
    created_at TIMESTAMPTZ
) LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
    RETURN QUERY
    SELECT 
        bp.id,
        bp.payment_status,
        bp.stripe_checkout_session_id,
        bp.amount_cents,
        bp.created_at
    FROM batch_payments bp
    WHERE bp.batch_id = p_batch_id 
    AND bp.user_id = auth.uid()
    ORDER BY bp.created_at DESC
    LIMIT 1;
END;
$$;

-- Confirm batch payment by checkout session ID (alternative method)
CREATE OR REPLACE FUNCTION confirm_batch_payment_by_session(
    p_stripe_checkout_session_id TEXT,
    p_payment_method TEXT DEFAULT NULL
) RETURNS UUID LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_payment_record RECORD;
    v_batch_record RECORD;
BEGIN
    -- Get payment and batch information by checkout session ID
    SELECT bp.*, cb.card_id, cb.cards_count 
    INTO v_payment_record
    FROM batch_payments bp
    JOIN card_batches cb ON bp.batch_id = cb.id
    WHERE bp.stripe_checkout_session_id = p_stripe_checkout_session_id
    AND bp.user_id = auth.uid();
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Payment not found or not authorized.';
    END IF;
    
    -- Check if already confirmed
    IF v_payment_record.payment_status = 'succeeded' THEN
        RAISE EXCEPTION 'Payment already confirmed.';
    END IF;
    
    -- Update payment status
    UPDATE batch_payments 
    SET 
        payment_status = 'succeeded',
        payment_method = p_payment_method,
        updated_at = NOW()
    WHERE stripe_checkout_session_id = p_stripe_checkout_session_id;
    
    -- Update batch payment status
    UPDATE card_batches 
    SET 
        payment_completed = TRUE,
        payment_completed_at = NOW(),
        updated_at = NOW()
    WHERE id = v_payment_record.batch_id;
    
    -- Generate cards using the new function
    PERFORM generate_batch_cards(v_payment_record.batch_id);
    
    -- Log payment confirmation in audit table
    INSERT INTO admin_audit_log (
        admin_user_id,
        admin_email,
        target_user_id,
        target_user_email,
        action_type,
        description,
        details
    ) VALUES (
        auth.uid(),
        (SELECT email FROM auth.users WHERE id = auth.uid()),
        v_payment_record.user_id,
        (SELECT email FROM auth.users WHERE id = v_payment_record.user_id),
        'PAYMENT_CONFIRMATION',
        'Batch payment confirmed via Stripe checkout session',
        jsonb_build_object(
            'old_status', jsonb_build_object(
                'payment_status', v_payment_record.payment_status,
                'payment_completed', false,
                'cards_generated', false
            ),
            'new_status', jsonb_build_object(
                'payment_status', 'succeeded',
                'payment_completed', true,
                'payment_completed_at', NOW(),
                'payment_method', p_payment_method,
                'cards_generated', true
            ),
            'action', 'payment_confirmed',
            'payment_method', p_payment_method,
            'stripe_checkout_session_id', p_stripe_checkout_session_id,
            'batch_id', v_payment_record.batch_id,
            'amount_cents', v_payment_record.amount_cents,
            'currency', v_payment_record.currency,
            'cards_count', v_payment_record.cards_count,
            'automated_card_generation', true
        )
    );
    
    RETURN v_payment_record.batch_id;
END;
$$;

 