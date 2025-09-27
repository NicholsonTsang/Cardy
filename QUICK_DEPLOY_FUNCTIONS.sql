-- =================================================================
-- QUICK DEPLOYMENT: PENDING BATCH PAYMENT FUNCTIONS
-- Run this SQL script in your Supabase SQL Editor or via psql
-- =================================================================

-- First, ensure the batch_payments table has the required columns
ALTER TABLE batch_payments 
ADD COLUMN IF NOT EXISTS card_id UUID REFERENCES cards(id) ON DELETE CASCADE;

ALTER TABLE batch_payments 
ADD COLUMN IF NOT EXISTS batch_name TEXT;

ALTER TABLE batch_payments 
ADD COLUMN IF NOT EXISTS cards_count INTEGER;

-- Make batch_id nullable (this might fail if there's existing data - that's OK)
DO $$ 
BEGIN
    ALTER TABLE batch_payments ALTER COLUMN batch_id DROP NOT NULL;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'batch_id column may already be nullable or have constraints';
END $$;

-- Add constraint (drop first if exists)
ALTER TABLE batch_payments DROP CONSTRAINT IF EXISTS batch_payments_batch_or_pending_check;

ALTER TABLE batch_payments
ADD CONSTRAINT batch_payments_batch_or_pending_check 
CHECK (
    (batch_id IS NOT NULL) OR 
    (card_id IS NOT NULL AND batch_name IS NOT NULL AND cards_count IS NOT NULL)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_batch_payments_card_id ON batch_payments(card_id);
CREATE INDEX IF NOT EXISTS idx_batch_payments_pending ON batch_payments(card_id, user_id) WHERE batch_id IS NULL;

-- =================================================================
-- CREATE THE MISSING FUNCTIONS
-- =================================================================

-- 1. Create pending batch payment function
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
        p_batch_name,
        p_cards_count,
        p_metadata,
        NOW(),
        NOW()
    )
    RETURNING id INTO v_payment_id;
    
    RETURN v_payment_id;
END;
$$;

-- 2. Confirm pending batch payment function
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

-- 3. Get pending batch payment info function
CREATE OR REPLACE FUNCTION get_pending_batch_payment_info(p_session_id TEXT)
RETURNS TABLE (
    payment_id UUID,
    card_id UUID,
    stripe_checkout_session_id TEXT,
    stripe_payment_intent_id TEXT,
    amount_cents INTEGER,
    currency TEXT,
    payment_status TEXT,
    payment_method TEXT,
    batch_name TEXT,
    cards_count INTEGER,
    failure_reason TEXT,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ
) LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
    RETURN QUERY
    SELECT 
        bp.id as payment_id,
        bp.card_id,
        bp.stripe_checkout_session_id,
        bp.stripe_payment_intent_id,
        bp.amount_cents,
        bp.currency,
        bp.payment_status,
        bp.payment_method,
        bp.batch_name,
        bp.cards_count,
        bp.failure_reason,
        bp.created_at,
        bp.updated_at
    FROM batch_payments bp
    WHERE bp.stripe_checkout_session_id = p_session_id
    AND bp.user_id = auth.uid();
END;
$$;

-- =================================================================
-- VERIFICATION QUERIES
-- =================================================================

-- Check if functions were created successfully
SELECT 
    routine_name, 
    routine_type,
    specific_name
FROM information_schema.routines 
WHERE routine_name IN (
    'create_pending_batch_payment',
    'confirm_pending_batch_payment', 
    'get_pending_batch_payment_info'
)
AND routine_schema = 'public'
ORDER BY routine_name;

-- Show success message
DO $$ 
BEGIN
    RAISE NOTICE '✅ Deployment completed successfully!';
    RAISE NOTICE '✅ Functions created: create_pending_batch_payment, confirm_pending_batch_payment, get_pending_batch_payment_info';
    RAISE NOTICE '✅ Schema updated: batch_payments table now supports pending payments';
    RAISE NOTICE '🚀 You can now test the payment-first flow!';
END $$;
