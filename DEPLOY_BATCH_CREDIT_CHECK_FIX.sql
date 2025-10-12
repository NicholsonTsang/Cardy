-- Fix: Batch Issuance Credit Check Type Error
-- Date: October 12, 2025
-- Issue: "argument of NOT must be type boolean, not type numeric"
-- Root Cause: check_credit_balance() returns DECIMAL, not BOOLEAN

-- Drop existing function
DROP FUNCTION IF EXISTS issue_card_batch_with_credits(UUID, INTEGER, BOOLEAN);

-- Recreate function with fixed credit check
CREATE OR REPLACE FUNCTION issue_card_batch_with_credits(
    p_card_id UUID,
    p_quantity INTEGER,
    p_print_request BOOLEAN DEFAULT FALSE
) RETURNS UUID LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_batch_id UUID;
    v_batch_number INTEGER;
    v_batch_name TEXT;
    v_card_owner_id UUID;
    v_credits_per_card DECIMAL := 2.00;
    v_total_credits DECIMAL;
    v_current_balance DECIMAL;
    v_consumption_result JSONB;
    i INTEGER;
BEGIN
    -- Validate inputs
    IF p_quantity <= 0 OR p_quantity > 1000 THEN
        RAISE EXCEPTION 'Quantity must be between 1 and 1000';
    END IF;
    
    -- Check if the user owns the card
    SELECT user_id INTO v_card_owner_id
    FROM cards
    WHERE id = p_card_id;
    
    IF v_card_owner_id IS NULL THEN
        RAISE EXCEPTION 'Card not found.';
    END IF;

    IF v_card_owner_id != auth.uid() THEN
        RAISE EXCEPTION 'Not authorized to issue cards for this card.';
    END IF;
    
    v_total_credits := p_quantity * v_credits_per_card;
    
    -- Check credit balance (check_credit_balance returns the actual balance as DECIMAL)
    v_current_balance := check_credit_balance(v_total_credits);
    IF v_current_balance < v_total_credits THEN
        RAISE EXCEPTION 'Insufficient credits. Required: %, Available: %. Please purchase more credits.', 
            v_total_credits, v_current_balance;
    END IF;
    
    -- Get next batch number
    SELECT get_next_batch_number(p_card_id) INTO v_batch_number;
    v_batch_name := 'batch-' || v_batch_number;
    
    -- Create the batch with credits payment
    INSERT INTO card_batches (
        card_id,
        batch_name,
        batch_number,
        cards_count,
        created_by,
        payment_required,
        payment_completed,
        payment_amount_cents,
        payment_waived,
        cards_generated,
        payment_method,
        credit_cost
    ) VALUES (
        p_card_id,
        v_batch_name,
        v_batch_number,
        p_quantity,
        auth.uid(),
        FALSE, -- No payment required (using credits)
        TRUE,  -- Payment completed (via credits)
        0,     -- No Stripe payment
        FALSE, -- Not waived
        TRUE,  -- Cards will be generated immediately
        'credits',
        v_total_credits
    )
    RETURNING id INTO v_batch_id;
    
    -- Consume credits
    SELECT consume_credits_for_batch(v_batch_id, p_quantity) INTO v_consumption_result;
    
    IF NOT (v_consumption_result->>'success')::boolean THEN
        -- Rollback batch creation if credit consumption fails
        DELETE FROM card_batches WHERE id = v_batch_id;
        RAISE EXCEPTION 'Failed to consume credits for batch';
    END IF;
    
    -- Generate the issued cards immediately (since payment is done via credits)
    FOR i IN 1..p_quantity LOOP
        INSERT INTO issue_cards (
            card_id,
            batch_id,
            active,
            issue_at
        ) VALUES (
            p_card_id,
            v_batch_id,
            false,
            NOW()
        );
    END LOOP;
    
    -- Update batch to mark cards as generated
    UPDATE card_batches 
    SET 
        cards_generated_at = NOW(),
        payment_completed_at = NOW()
    WHERE id = v_batch_id;
    
    -- Create print request if requested
    IF p_print_request THEN
        INSERT INTO print_requests (
            batch_id,
            status,
            created_by
        ) VALUES (
            v_batch_id,
            'SUBMITTED',
            auth.uid()
        );
    END IF;
    
    -- Log operation
    PERFORM log_operation(format('Issued batch "%s" with %s cards using credits', v_batch_name, p_quantity));
    
    RETURN v_batch_id;
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION issue_card_batch_with_credits(UUID, INTEGER, BOOLEAN) TO authenticated;

