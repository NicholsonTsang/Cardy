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

-- =================================================================
-- PENDING BATCH PAYMENT FUNCTIONS (PAYMENT-FIRST FLOW)
-- Functions for handling payments before batch creation
-- =================================================================

-- Create payment record for pending batch (payment-first flow)
-- Parameters ordered to match Supabase's expected alphabetical order
CREATE OR REPLACE FUNCTION create_pending_batch_payment(
    p_amount_cents INTEGER,
    p_batch_name TEXT,
    p_card_id UUID,
    p_cards_count INTEGER,
    p_metadata JSONB,
    p_stripe_checkout_session_id TEXT,
    p_stripe_payment_intent_id TEXT
) RETURNS UUID LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_card_owner_id UUID;
    v_payment_id UUID;
    v_expected_amount INTEGER;
    v_batch_name TEXT;
    v_next_batch_number INTEGER;
BEGIN
    -- Verify card ownership
    SELECT user_id INTO v_card_owner_id
    FROM cards 
    WHERE id = p_card_id;
    
    IF v_card_owner_id IS NULL THEN
        RAISE EXCEPTION 'Card not found.';
    END IF;
    
    IF v_card_owner_id != auth.uid() THEN
        RAISE EXCEPTION 'Not authorized to create payment for this card.';
    END IF;
    
    -- Calculate expected amount ($2 per card = 200 cents per card)
    v_expected_amount := p_cards_count * 200;
    
    -- Verify amount matches expected
    IF p_amount_cents != v_expected_amount THEN
        RAISE EXCEPTION 'Payment amount mismatch. Expected: %, Provided: %', v_expected_amount, p_amount_cents;
    END IF;
    
    -- Validate required checkout session ID
    IF p_stripe_checkout_session_id IS NULL THEN
        RAISE EXCEPTION 'Checkout session ID is required.';
    END IF;
    
    -- Check if payment already exists for this session
    IF EXISTS (SELECT 1 FROM batch_payments WHERE stripe_checkout_session_id = p_stripe_checkout_session_id) THEN
        RAISE EXCEPTION 'Payment already exists for this checkout session.';
    END IF;
    
    -- Generate batch name if not provided
    IF p_batch_name IS NULL OR TRIM(p_batch_name) = '' THEN
        SELECT get_next_batch_number(p_card_id) INTO v_next_batch_number;
        v_batch_name := 'batch-' || v_next_batch_number;
    ELSE
        v_batch_name := p_batch_name;
    END IF;
    
    -- Create pending payment record
    INSERT INTO batch_payments (
        batch_id,        -- NULL for pending batch
        card_id,
        user_id,
        stripe_checkout_session_id,
        stripe_payment_intent_id,
        amount_cents,
        currency,
        payment_status,
        batch_name,
        cards_count,
        metadata,
        created_at,
        updated_at
    ) VALUES (
        NULL,            -- No batch exists yet
        p_card_id,
        auth.uid(),
        p_stripe_checkout_session_id,
        p_stripe_payment_intent_id,
        p_amount_cents,
        'usd',
        'pending',
        v_batch_name,
        p_cards_count,
        p_metadata,
        NOW(),
        NOW()
    )
    RETURNING id INTO v_payment_id;
    
    RETURN v_payment_id;
END;
$$;

-- Confirm pending batch payment and create batch (payment-first flow)
CREATE OR REPLACE FUNCTION confirm_pending_batch_payment(
    p_stripe_checkout_session_id TEXT,
    p_payment_method TEXT DEFAULT NULL
) RETURNS UUID LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_payment_record RECORD;
    v_batch_id UUID;
    v_batch_number INTEGER;
    v_generated_batch_name TEXT;
BEGIN
    -- Get pending payment record
    SELECT * INTO v_payment_record
    FROM batch_payments 
    WHERE stripe_checkout_session_id = p_stripe_checkout_session_id
    AND user_id = auth.uid()
    AND batch_id IS NULL;  -- Must be pending payment
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Pending payment not found or not authorized.';
    END IF;
    
    -- Check if already confirmed
    IF v_payment_record.payment_status = 'succeeded' THEN
        RAISE EXCEPTION 'Payment already confirmed.';
    END IF;
    
    -- Get next batch number for this card
    SELECT get_next_batch_number(v_payment_record.card_id) INTO v_batch_number;
    v_generated_batch_name := 'batch-' || v_batch_number;
    
    -- Create the batch now that payment is confirmed
    INSERT INTO card_batches (
        card_id,
        batch_name,
        batch_number,
        cards_count,
        created_by,
        payment_required,
        payment_completed,
        payment_amount_cents,
        payment_completed_at,
        payment_waived,
        cards_generated
    ) VALUES (
        v_payment_record.card_id,
        v_generated_batch_name,
        v_batch_number,
        v_payment_record.cards_count,
        auth.uid(),
        TRUE,
        TRUE,  -- Payment already confirmed
        v_payment_record.amount_cents,
        NOW(),
        FALSE,
        FALSE  -- Cards not generated yet
    )
    RETURNING id INTO v_batch_id;
    
    -- Update payment record to link to the new batch
    UPDATE batch_payments 
    SET 
        batch_id = v_batch_id,
        payment_status = 'succeeded',
        payment_method = p_payment_method,
        updated_at = NOW()
    WHERE stripe_checkout_session_id = p_stripe_checkout_session_id;
    
    -- Generate cards for the new batch
    PERFORM generate_batch_cards(v_batch_id);
    
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
        'PENDING_BATCH_PAYMENT_CONFIRMATION',
        'Pending batch payment confirmed and batch created: ' || v_generated_batch_name,
        jsonb_build_object(
            'old_status', jsonb_build_object(
                'payment_status', v_payment_record.payment_status,
                'batch_exists', false,
                'cards_generated', false
            ),
            'new_status', jsonb_build_object(
                'payment_status', 'succeeded',
                'batch_created', true,
                'batch_id', v_batch_id,
                'batch_name', v_generated_batch_name,
                'payment_completed_at', NOW(),
                'payment_method', p_payment_method,
                'cards_generated', true
            ),
            'action', 'pending_payment_confirmed_batch_created',
            'payment_method', p_payment_method,
            'stripe_checkout_session_id', p_stripe_checkout_session_id,
            'batch_id', v_batch_id,
            'card_id', v_payment_record.card_id,
            'amount_cents', v_payment_record.amount_cents,
            'currency', v_payment_record.currency,
            'cards_count', v_payment_record.cards_count,
            'automated_batch_creation', true,
            'automated_card_generation', true
        )
    );
    
    RETURN v_batch_id;
END;
$$;

 