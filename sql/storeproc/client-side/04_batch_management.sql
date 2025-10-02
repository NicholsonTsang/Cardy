-- =================================================================
-- CARD BATCH MANAGEMENT FUNCTIONS
-- Functions for managing card batches and issued cards
-- =================================================================

-- Get next batch number for a card
CREATE OR REPLACE FUNCTION get_next_batch_number(p_card_id UUID)
RETURNS INTEGER LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_max_batch_number INTEGER;
    v_user_id UUID;
BEGIN
    -- Check if the user owns the card
    SELECT user_id INTO v_user_id FROM cards WHERE id = p_card_id;
    
    IF v_user_id != auth.uid() THEN
        RAISE EXCEPTION 'Not authorized to access this card';
    END IF;
    
    -- Get the maximum batch number for this card
    SELECT COALESCE(MAX(batch_number), 0) INTO v_max_batch_number
    FROM card_batches
    WHERE card_id = p_card_id;
    
    RETURN v_max_batch_number + 1;
END;
$$;

-- Create a new card batch and issue cards
CREATE OR REPLACE FUNCTION issue_card_batch(
    p_card_id UUID,
    p_quantity INTEGER
) RETURNS UUID LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_batch_id UUID;
    v_batch_number INTEGER;
    v_batch_name TEXT;
    v_card_owner_id UUID;
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
    
    -- Get next batch number
    SELECT get_next_batch_number(p_card_id) INTO v_batch_number;
    v_batch_name := 'batch-' || v_batch_number;
    
    -- Create the batch (Step 1: Batch creation only)
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
        cards_generated
    ) VALUES (
        p_card_id,
        v_batch_name,
        v_batch_number,
        p_quantity,
        auth.uid(),
        TRUE,
        FALSE,
        p_quantity * 200, -- $2 USD per card = 200 cents per card
        FALSE,
        FALSE -- Cards not generated yet
    )
    RETURNING id INTO v_batch_id;
    
    -- NOTE: Cards are NOT created here in the two-step process
    -- Cards will only be created after payment is confirmed via confirm_batch_payment()
    -- OR when admin waives payment via admin_waive_batch_payment()
    
    -- Log operation
    PERFORM log_operation('Issued batch: ' || p_quantity || ' cards for card ' || p_card_id);
    
    RETURN v_batch_id;
END;
$$;

-- Get card batches for a card
CREATE OR REPLACE FUNCTION get_card_batches(p_card_id UUID)
RETURNS TABLE (
    id UUID,
    card_id UUID,
    batch_name TEXT,
    batch_number INTEGER,
    cards_count INTEGER,
    active_cards_count BIGINT,
    is_disabled BOOLEAN,
    payment_required BOOLEAN,
    payment_completed BOOLEAN,
    payment_amount_cents INTEGER,
    payment_completed_at TIMESTAMPTZ,
    payment_waived BOOLEAN,
    payment_waived_by UUID,
    payment_waived_at TIMESTAMPTZ,
    payment_waiver_reason TEXT,
    cards_generated BOOLEAN,
    cards_generated_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ
) LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_caller_role TEXT;
BEGIN
    -- Get caller's role
    SELECT raw_user_meta_data->>'role' INTO v_caller_role
    FROM auth.users
    WHERE auth.users.id = auth.uid();
    
    RETURN QUERY
    SELECT 
        cb.id,
        cb.card_id,
        cb.batch_name,
        cb.batch_number,
        cb.cards_count,
        COUNT(ic.id) FILTER (WHERE ic.active = true) as active_cards_count,
        cb.is_disabled,
        cb.payment_required,
        cb.payment_completed,
        cb.payment_amount_cents,
        cb.payment_completed_at,
        cb.payment_waived,
        cb.payment_waived_by,
        cb.payment_waived_at,
        cb.payment_waiver_reason,
        cb.cards_generated,
        cb.cards_generated_at,
        cb.created_at,
        cb.updated_at
    FROM card_batches cb
    LEFT JOIN issue_cards ic ON cb.id = ic.batch_id
    JOIN cards c ON cb.card_id = c.id
    -- Allow access if user owns the card OR if user is admin
    WHERE cb.card_id = p_card_id 
      AND (c.user_id = auth.uid() OR v_caller_role = 'admin')
    GROUP BY cb.id, cb.card_id, cb.batch_name, cb.batch_number, cb.cards_count, cb.is_disabled, 
             cb.payment_required, cb.payment_completed, cb.payment_amount_cents, cb.payment_completed_at, 
             cb.payment_waived, cb.payment_waived_by, cb.payment_waived_at, cb.payment_waiver_reason,
             cb.cards_generated, cb.cards_generated_at, cb.created_at, cb.updated_at
    ORDER BY cb.batch_number ASC;
END;
$$;

-- Get issued cards with batch information (including batch disabled status)
CREATE OR REPLACE FUNCTION get_issued_cards_with_batch(p_card_id UUID)
RETURNS TABLE (
    id UUID,
    card_id UUID,
    active BOOLEAN,
    issue_at TIMESTAMPTZ,
    active_at TIMESTAMPTZ,
    activated_by UUID,
    batch_id UUID,
    batch_name TEXT,
    batch_number INTEGER,
    batch_is_disabled BOOLEAN
) LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_caller_role TEXT;
BEGIN
    -- Get caller's role
    SELECT raw_user_meta_data->>'role' INTO v_caller_role
    FROM auth.users
    WHERE auth.users.id = auth.uid();
    
    RETURN QUERY
    SELECT 
        ic.id,
        c.id as card_id,
        ic.active,
        ic.issue_at,
        ic.active_at,
        ic.activated_by,
        cb.id as batch_id,
        cb.batch_name,
        cb.batch_number,
        cb.is_disabled as batch_is_disabled
    FROM issue_cards ic
    JOIN card_batches cb ON ic.batch_id = cb.id
    JOIN cards c ON ic.card_id = c.id
    -- Allow access if user owns the card OR if user is admin
    WHERE ic.card_id = p_card_id 
      AND (c.user_id = auth.uid() OR v_caller_role = 'admin')
    ORDER BY ic.issue_at DESC;
END;
$$;

-- Toggle disable status of a card batch
CREATE OR REPLACE FUNCTION toggle_card_batch_disabled_status(p_batch_id UUID, p_disable_status BOOLEAN)
RETURNS BOOLEAN LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_user_id UUID;
    v_card_id UUID;
BEGIN
    -- Check if the user owns the card that contains this batch
    SELECT c.user_id, cb.card_id INTO v_user_id, v_card_id
    FROM card_batches cb
    JOIN cards c ON cb.card_id = c.id
    WHERE cb.id = p_batch_id;
    
    IF v_user_id != auth.uid() THEN
        RAISE EXCEPTION 'Not authorized to modify this batch.';
    END IF;

    -- Check if there is an active print request for this batch if attempting to disable
    IF p_disable_status = TRUE THEN
        IF EXISTS (
            SELECT 1 FROM print_requests pr
            WHERE pr.batch_id = p_batch_id AND pr.status NOT IN ('COMPLETED', 'CANCELLED')
        ) THEN
            RAISE EXCEPTION 'Cannot disable a batch with an active print request. Please cancel or complete the print request first.';
        END IF;
    END IF;
    
    UPDATE card_batches
    SET is_disabled = p_disable_status,
        updated_at = now()
    WHERE id = p_batch_id;
    
    -- Log operation
    DECLARE
        batch_name TEXT;
    BEGIN
        SELECT cb.batch_name INTO batch_name
        FROM card_batches cb
        WHERE cb.id = p_batch_id;
        
        PERFORM log_operation(
            CASE 
                WHEN p_disable_status THEN 'Disabled batch: ' || batch_name || ' (ID: ' || p_batch_id || ')'
                ELSE 'Enabled batch: ' || batch_name || ' (ID: ' || p_batch_id || ')'
            END
        );
    END;
    
    RETURN FOUND;
END;
$$;

-- Activate an issued card by ID (simplified without activation code)
CREATE OR REPLACE FUNCTION activate_issued_card(p_card_id UUID)
RETURNS BOOLEAN LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
    UPDATE issue_cards
    SET 
        active = true,
        active_at = NOW(),
        activated_by = auth.uid()
    WHERE id = p_card_id AND active = false;
    
    -- Log operation
    PERFORM log_operation('Activated issued card (ID: ' || p_card_id || ')');
    
    RETURN FOUND;
END;
$$;

-- Get card issuance statistics
CREATE OR REPLACE FUNCTION get_card_issuance_stats(p_card_id UUID)
RETURNS TABLE (
    total_issued BIGINT,
    total_activated BIGINT,
    activation_rate NUMERIC,
    total_batches BIGINT
) LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(ic.id) as total_issued,
        COUNT(ic.id) FILTER (WHERE ic.active = true) as total_activated,
        CASE 
            WHEN COUNT(ic.id) > 0 THEN 
                ROUND((COUNT(ic.id) FILTER (WHERE ic.active = true) * 100.0 / COUNT(ic.id)), 2)
            ELSE 0 
        END as activation_rate,
        COUNT(DISTINCT cb.id) as total_batches
    FROM issue_cards ic
    JOIN card_batches cb ON ic.batch_id = cb.id
    JOIN cards c ON ic.card_id = c.id
    WHERE ic.card_id = p_card_id AND c.user_id = auth.uid();
END;
$$;

-- Delete an issued card (secure replacement for direct table access)
CREATE OR REPLACE FUNCTION delete_issued_card(p_issued_card_id UUID)
RETURNS BOOLEAN LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_card_owner_id UUID;
BEGIN
    -- Check if the user owns the card that contains this issued card
    SELECT c.user_id INTO v_card_owner_id
    FROM issue_cards ic
    JOIN cards c ON ic.card_id = c.id
    WHERE ic.id = p_issued_card_id;
    
    IF v_card_owner_id IS NULL THEN
        RAISE EXCEPTION 'Issued card not found';
    END IF;
    
    IF v_card_owner_id != auth.uid() THEN
        RAISE EXCEPTION 'Not authorized to delete this issued card';
    END IF;
    
    -- Delete the issued card
    DELETE FROM issue_cards WHERE id = p_issued_card_id;
    
    -- Log operation
    PERFORM log_operation('Deleted issued card (ID: ' || p_issued_card_id || ')');
    
    RETURN FOUND;
END;
$$;

-- Generate cards for a paid or waived batch
CREATE OR REPLACE FUNCTION generate_batch_cards(
    p_batch_id UUID
) RETURNS UUID LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_batch_record RECORD;
    v_batch_owner_id UUID;
    i INTEGER;
BEGIN
    -- Get batch information and check ownership
    SELECT cb.*, c.user_id as card_owner INTO v_batch_record
    FROM card_batches cb
    JOIN cards c ON cb.card_id = c.id
    WHERE cb.id = p_batch_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Batch not found.';
    END IF;
    
    -- Check if user owns the batch or is admin
    IF v_batch_record.card_owner != auth.uid() THEN
        -- Check if caller is admin
        DECLARE
            caller_role TEXT;
        BEGIN
            SELECT raw_user_meta_data->>'role' INTO caller_role
            FROM auth.users
            WHERE auth.users.id = auth.uid();
            
            IF caller_role != 'admin' THEN
                RAISE EXCEPTION 'Not authorized to generate cards for this batch.';
            END IF;
        END;
    END IF;
    
    -- Check if cards can be generated
    IF v_batch_record.cards_generated = TRUE THEN
        RAISE EXCEPTION 'Cards have already been generated for this batch.';
    END IF;
    
    IF v_batch_record.payment_completed = FALSE AND v_batch_record.payment_waived = FALSE THEN
        RAISE EXCEPTION 'Payment required or must be waived before generating cards.';
    END IF;
    
    -- Generate the issued cards
    FOR i IN 1..v_batch_record.cards_count LOOP
        INSERT INTO issue_cards (
            card_id,
            batch_id,
            active,
            issue_at
        ) VALUES (
            v_batch_record.card_id,
            p_batch_id,
            false,
            NOW()
        );
    END LOOP;
    
    -- Update batch to mark cards as generated
    UPDATE card_batches 
    SET 
        cards_generated = TRUE,
        cards_generated_at = NOW(),
        updated_at = NOW()
    WHERE id = p_batch_id;
    
    -- Log operation
    PERFORM log_operation('Generated ' || v_batch_record.cards_count || ' cards for batch: ' || v_batch_record.batch_name || ' (ID: ' || p_batch_id || ')');
    
    RETURN p_batch_id;
END;
$$; 