-- Drop existing functions first to avoid conflicts
DROP FUNCTION IF EXISTS get_user_cards();
DROP FUNCTION IF EXISTS create_card(TEXT, TEXT, TEXT[], BOOLEAN, TEXT, BOOLEAN, TEXT);
DROP FUNCTION IF EXISTS get_card_by_id(UUID);
DROP FUNCTION IF EXISTS update_card(UUID, TEXT, TEXT, TEXT[], BOOLEAN, TEXT, BOOLEAN, TEXT);
DROP FUNCTION IF EXISTS delete_card(UUID);
DROP FUNCTION IF EXISTS get_card_content_items(UUID);
DROP FUNCTION IF EXISTS get_content_item_by_id(UUID);
DROP FUNCTION IF EXISTS create_content_item(UUID, TEXT, UUID, TEXT, TEXT[], BOOLEAN, TEXT);
DROP FUNCTION IF EXISTS update_content_item(UUID, TEXT, TEXT, TEXT[], BOOLEAN, TEXT);
DROP FUNCTION IF EXISTS update_content_item_order(UUID, INTEGER);
DROP FUNCTION IF EXISTS delete_content_item(UUID);
DROP FUNCTION IF EXISTS get_next_batch_number(UUID);
DROP FUNCTION IF EXISTS issue_card_batch(UUID, INTEGER);
DROP FUNCTION IF EXISTS get_card_batches(UUID);
DROP FUNCTION IF EXISTS get_issued_cards_with_batch(UUID);
DROP FUNCTION IF EXISTS toggle_card_batch_disabled_status(UUID, BOOLEAN);
DROP FUNCTION IF EXISTS activate_issued_card(UUID, TEXT);
DROP FUNCTION IF EXISTS get_card_issuance_stats(UUID);
DROP FUNCTION IF EXISTS request_card_printing(UUID, TEXT);
DROP FUNCTION IF EXISTS get_print_requests_for_batch(UUID);
DROP FUNCTION IF EXISTS get_public_card_content(UUID, TEXT);
-- User-level functions
DROP FUNCTION IF EXISTS get_user_all_issued_cards();
DROP FUNCTION IF EXISTS get_user_issuance_stats();
DROP FUNCTION IF EXISTS get_user_all_card_batches();
DROP FUNCTION IF EXISTS get_user_recent_activity(INTEGER);
-- Admin-specific functions
DROP FUNCTION IF EXISTS get_all_pending_verifications();
DROP FUNCTION IF EXISTS get_all_verifications();
DROP FUNCTION IF EXISTS get_verification_by_id(UUID);
DROP FUNCTION IF EXISTS get_all_print_requests();
DROP FUNCTION IF EXISTS get_all_print_requests("PrintRequestStatus");
DROP FUNCTION IF EXISTS update_print_request_status(UUID, TEXT, TEXT, TEXT);
DROP FUNCTION IF EXISTS update_print_request_status(UUID, "PrintRequestStatus", TEXT, TEXT);
DROP FUNCTION IF EXISTS update_print_request_status(UUID, "PrintRequestStatus", TEXT);
DROP FUNCTION IF EXISTS get_admin_dashboard_stats();
DROP FUNCTION IF EXISTS get_recent_admin_activity(INTEGER);

-- Get all cards for the current user (more secure)
CREATE OR REPLACE FUNCTION get_user_cards()
RETURNS TABLE (
    id UUID,
    name TEXT,
    description TEXT,
    image_urls TEXT[],
    published BOOLEAN,
    conversation_ai_enabled BOOLEAN,
    ai_prompt TEXT,
    qr_code_position TEXT,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ
) LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.id, 
        c.name, 
        c.description, 
        c.image_urls, 
        c.published, 
        c.conversation_ai_enabled,
        c.ai_prompt,
        c.qr_code_position::TEXT,
        c.created_at,
        c.updated_at
    FROM cards c
    WHERE c.user_id = auth.uid()
    ORDER BY c.created_at DESC;
END;
$$;

-- Create a new card (more secure)
CREATE OR REPLACE FUNCTION create_card(
    p_name TEXT,
    p_description TEXT,
    p_image_urls TEXT[] DEFAULT ARRAY[]::TEXT[],
    p_conversation_ai_enabled BOOLEAN DEFAULT FALSE,
    p_ai_prompt TEXT DEFAULT '',
    p_published BOOLEAN DEFAULT FALSE,
    p_qr_code_position TEXT DEFAULT 'BR'
) RETURNS UUID LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_card_id UUID;
BEGIN
    INSERT INTO cards (
        user_id,
        name,
        description,
        image_urls,
        conversation_ai_enabled,
        ai_prompt,
        published,
        qr_code_position
    ) VALUES (
        auth.uid(),
        p_name,
        p_description,
        p_image_urls,
        p_conversation_ai_enabled,
        p_ai_prompt,
        p_published,
        p_qr_code_position::"QRCodePosition"
    )
    RETURNING id INTO v_card_id;
    
    RETURN v_card_id;
END;
$$;

-- Get a card by ID (more secure, relies on RLS policy)
CREATE OR REPLACE FUNCTION get_card_by_id(p_card_id UUID)
RETURNS TABLE (
    id UUID,
    user_id UUID,
    name TEXT,
    description TEXT,
    content_render_mode TEXT,
    qr_code_position TEXT,
    image_urls TEXT[],
    published BOOLEAN,
    conversation_ai_enabled BOOLEAN,
    ai_prompt TEXT,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ
) LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.id, 
        c.user_id,
        c.name, 
        c.description, 
        c.content_render_mode::TEXT,
        c.qr_code_position::TEXT,
        c.image_urls, 
        c.published, 
        c.conversation_ai_enabled,
        c.ai_prompt,
        c.created_at, 
        c.updated_at
    FROM cards c
    WHERE c.id = p_card_id;
    -- No need to check user_id = auth.uid() as RLS policy will handle this
END;
$$;

-- Update an existing card (more secure)
CREATE OR REPLACE FUNCTION update_card(
    p_card_id UUID,
    p_name TEXT DEFAULT NULL,
    p_description TEXT DEFAULT NULL,
    p_image_urls TEXT[] DEFAULT NULL,
    p_conversation_ai_enabled BOOLEAN DEFAULT NULL,
    p_ai_prompt TEXT DEFAULT NULL,
    p_published BOOLEAN DEFAULT NULL,
    p_qr_code_position TEXT DEFAULT NULL
) RETURNS BOOLEAN LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
    UPDATE cards
    SET 
        name = COALESCE(p_name, name),
        description = COALESCE(p_description, description),
        image_urls = COALESCE(p_image_urls, image_urls),
        conversation_ai_enabled = COALESCE(p_conversation_ai_enabled, conversation_ai_enabled),
        ai_prompt = COALESCE(p_ai_prompt, ai_prompt),
        published = COALESCE(p_published, published),
        qr_code_position = COALESCE(p_qr_code_position::"QRCodePosition", qr_code_position),
        updated_at = now()
    WHERE id = p_card_id AND user_id = auth.uid();
    
    RETURN FOUND;
END;
$$;

-- Delete a card (more secure)
CREATE OR REPLACE FUNCTION delete_card(p_card_id UUID)
RETURNS BOOLEAN LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
    DELETE FROM cards WHERE id = p_card_id AND user_id = auth.uid();
    RETURN FOUND;
END;
$$;

-- Get all content items for a card (updated with ordering)
CREATE OR REPLACE FUNCTION get_card_content_items(p_card_id UUID)
RETURNS TABLE (
    id UUID,
    card_id UUID,
    parent_id UUID,
    name TEXT,
    content TEXT,
    image_urls TEXT[],
    ai_metadata TEXT,
    sort_order INTEGER,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ
) LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ci.id, 
        ci.card_id,
        ci.parent_id,
        ci.name, 
        ci.content, 
        ci.image_urls, 
        ci.ai_metadata,
        ci.sort_order,
        ci.created_at,
        ci.updated_at
    FROM content_items ci
    JOIN cards c ON ci.card_id = c.id
    WHERE ci.card_id = p_card_id AND c.user_id = auth.uid()
    ORDER BY 
        CASE WHEN ci.parent_id IS NULL THEN ci.sort_order ELSE 999999 END,
        ci.parent_id NULLS FIRST,
        ci.sort_order ASC,
        ci.created_at ASC;
END;
$$;

-- Get a content item by ID (updated with ordering)
CREATE OR REPLACE FUNCTION get_content_item_by_id(p_content_item_id UUID)
RETURNS TABLE (
    id UUID,
    card_id UUID,
    parent_id UUID,
    name TEXT,
    content TEXT,
    image_urls TEXT[],
    ai_metadata TEXT,
    sort_order INTEGER,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ
) LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ci.id, 
        ci.card_id,
        ci.parent_id,
        ci.name, 
        ci.content, 
        ci.image_urls, 
        ci.ai_metadata,
        ci.sort_order,
        ci.created_at,
        ci.updated_at
    FROM content_items ci
    JOIN cards c ON ci.card_id = c.id
    WHERE ci.id = p_content_item_id AND c.user_id = auth.uid();
END;
$$;

-- Create a new content item (updated with ordering)
CREATE OR REPLACE FUNCTION create_content_item(
    p_card_id UUID,
    p_name TEXT,
    p_parent_id UUID DEFAULT NULL,
    p_content TEXT DEFAULT '',
    p_image_urls TEXT[] DEFAULT ARRAY[]::TEXT[],
    p_ai_metadata TEXT DEFAULT ''
) RETURNS UUID LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_content_item_id UUID;
    v_user_id UUID;
    v_next_sort_order INTEGER;
BEGIN
    -- Check if the user owns the card
    SELECT user_id INTO v_user_id
    FROM cards
    WHERE id = p_card_id;
    
    IF v_user_id != auth.uid() THEN
        RAISE EXCEPTION 'Not authorized to add content to this card';
    END IF;
    
    -- If parent_id is provided, check if it exists and belongs to the same card
    IF p_parent_id IS NOT NULL THEN
        IF NOT EXISTS (
            SELECT 1 FROM content_items 
            WHERE id = p_parent_id AND card_id = p_card_id
        ) THEN
            RAISE EXCEPTION 'Parent content item not found or does not belong to this card';
        END IF;
    END IF;
    
    -- Get the next sort order for this level
    SELECT COALESCE(MAX(sort_order), 0) + 1 INTO v_next_sort_order
    FROM content_items
    WHERE card_id = p_card_id 
    AND (
        (p_parent_id IS NULL AND parent_id IS NULL) OR 
        (p_parent_id IS NOT NULL AND parent_id = p_parent_id)
    );
    
    -- Insert the content item
    INSERT INTO content_items (
        card_id,
        parent_id,
        name,
        content,
        image_urls,
        ai_metadata,
        sort_order
    ) VALUES (
        p_card_id,
        p_parent_id,
        p_name,
        p_content,
        p_image_urls,
        p_ai_metadata,
        v_next_sort_order
    )
    RETURNING id INTO v_content_item_id;
    
    RETURN v_content_item_id;
END;
$$;

-- Update an existing content item (updated with ordering)
CREATE OR REPLACE FUNCTION update_content_item(
    p_content_item_id UUID,
    p_name TEXT DEFAULT NULL,
    p_content TEXT DEFAULT NULL,
    p_image_urls TEXT[] DEFAULT NULL,
    p_ai_metadata TEXT DEFAULT NULL
) RETURNS BOOLEAN LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_user_id UUID;
BEGIN
    -- Check if the user owns the card that contains this content item
    SELECT c.user_id INTO v_user_id
    FROM content_items ci
    JOIN cards c ON ci.card_id = c.id
    WHERE ci.id = p_content_item_id;
    
    IF v_user_id != auth.uid() THEN
        RAISE EXCEPTION 'Not authorized to update this content item';
    END IF;
    
    -- Update the content item
    UPDATE content_items
    SET 
        name = COALESCE(p_name, name),
        content = COALESCE(p_content, content),
        image_urls = COALESCE(p_image_urls, image_urls),
        ai_metadata = COALESCE(p_ai_metadata, ai_metadata),
        updated_at = now()
    WHERE id = p_content_item_id;
    
    RETURN FOUND;
END;
$$;

-- Update content item order
CREATE OR REPLACE FUNCTION update_content_item_order(
    p_content_item_id UUID,
    p_new_sort_order INTEGER
) RETURNS BOOLEAN LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_user_id UUID;
    v_card_id UUID;
    v_parent_id UUID;
    v_old_sort_order INTEGER;
BEGIN
    -- Get content item details and check ownership
    SELECT c.user_id, ci.card_id, ci.parent_id, ci.sort_order 
    INTO v_user_id, v_card_id, v_parent_id, v_old_sort_order
    FROM content_items ci
    JOIN cards c ON ci.card_id = c.id
    WHERE ci.id = p_content_item_id;
    
    IF v_user_id != auth.uid() THEN
        RAISE EXCEPTION 'Not authorized to reorder this content item';
    END IF;
    
    -- Update sort orders for items in the same level
    IF v_old_sort_order < p_new_sort_order THEN
        -- Moving down: shift items up
        UPDATE content_items 
        SET sort_order = sort_order - 1
        WHERE card_id = v_card_id 
        AND (
            (v_parent_id IS NULL AND parent_id IS NULL) OR 
            (v_parent_id IS NOT NULL AND parent_id = v_parent_id)
        )
        AND sort_order > v_old_sort_order 
        AND sort_order <= p_new_sort_order;
    ELSE
        -- Moving up: shift items down
        UPDATE content_items 
        SET sort_order = sort_order + 1
        WHERE card_id = v_card_id 
        AND (
            (v_parent_id IS NULL AND parent_id IS NULL) OR 
            (v_parent_id IS NOT NULL AND parent_id = v_parent_id)
        )
        AND sort_order >= p_new_sort_order 
        AND sort_order < v_old_sort_order;
    END IF;
    
    -- Update the target item's sort order
    UPDATE content_items
    SET sort_order = p_new_sort_order
    WHERE id = p_content_item_id;
    
    RETURN FOUND;
END;
$$;

-- Delete a content item
CREATE OR REPLACE FUNCTION delete_content_item(p_content_item_id UUID)
RETURNS BOOLEAN LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_user_id UUID;
BEGIN
    -- Check if the user owns the card that contains this content item
    SELECT c.user_id INTO v_user_id
    FROM content_items ci
    JOIN cards c ON ci.card_id = c.id
    WHERE ci.id = p_content_item_id;
    
    IF v_user_id != auth.uid() THEN
        RAISE EXCEPTION 'Not authorized to delete this content item';
    END IF;
    
    -- Delete the content item (cascade will handle children)
    DELETE FROM content_items WHERE id = p_content_item_id;
    
    RETURN FOUND;
END;
$$;

-- ===============================
-- CARD BATCH MANAGEMENT FUNCTIONS
-- ===============================

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
    v_card_published BOOLEAN;
BEGIN
    -- Validate inputs
    IF p_quantity <= 0 OR p_quantity > 1000 THEN
        RAISE EXCEPTION 'Quantity must be between 1 and 1000';
    END IF;
    
    -- Check if the user owns the card and if the card is published
    SELECT user_id, published INTO v_card_owner_id, v_card_published
    FROM cards
    WHERE id = p_card_id;
    
    IF v_card_owner_id IS NULL THEN
        RAISE EXCEPTION 'Card not found.';
    END IF;

    IF v_card_owner_id != auth.uid() THEN
        RAISE EXCEPTION 'Not authorized to issue cards for this card.';
    END IF;

    IF v_card_published = FALSE THEN
        RAISE EXCEPTION 'Cannot issue batches for an unpublished card. Please publish the card design first.';
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
    
    RETURN v_batch_id;
END;
$$;

-- Create Stripe payment intent for batch issuance
CREATE OR REPLACE FUNCTION create_batch_payment_intent(
    p_batch_id UUID,
    p_stripe_payment_intent_id TEXT,
    p_stripe_client_secret TEXT,
    p_amount_cents INTEGER
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
    
    -- Create payment record
    INSERT INTO batch_payments (
            batch_id,
        user_id,
        stripe_payment_intent_id,
        stripe_client_secret,
        amount_cents,
        payment_status
        ) VALUES (
        p_batch_id,
        auth.uid(),
        p_stripe_payment_intent_id,
        p_stripe_client_secret,
        p_amount_cents,
        'pending'
    ) RETURNING id INTO v_payment_id;
    
    RETURN v_payment_id;
END;
$$;

-- Confirm batch payment and create issued cards
CREATE OR REPLACE FUNCTION confirm_batch_payment(
    p_stripe_payment_intent_id TEXT,
    p_payment_method TEXT DEFAULT NULL
) RETURNS UUID LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_payment_record RECORD;
    v_batch_record RECORD;
BEGIN
    -- Get payment and batch information
    SELECT bp.*, cb.card_id, cb.cards_count 
    INTO v_payment_record
    FROM batch_payments bp
    JOIN card_batches cb ON bp.batch_id = cb.id
    WHERE bp.stripe_payment_intent_id = p_stripe_payment_intent_id
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
    WHERE stripe_payment_intent_id = p_stripe_payment_intent_id;
    
    -- Update batch payment status
    UPDATE card_batches 
    SET 
        payment_completed = TRUE,
        payment_completed_at = NOW(),
        updated_at = NOW()
    WHERE id = v_payment_record.batch_id;
    
    -- Generate cards using the new function
    PERFORM generate_batch_cards(v_payment_record.batch_id);
    
    RETURN v_payment_record.batch_id;
END;
$$;

-- Handle failed payment
CREATE OR REPLACE FUNCTION handle_failed_batch_payment(
    p_stripe_payment_intent_id TEXT,
    p_failure_reason TEXT DEFAULT NULL
) RETURNS BOOLEAN LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
    -- Update payment status to failed
    UPDATE batch_payments 
    SET 
        payment_status = 'failed',
        failure_reason = p_failure_reason,
        updated_at = NOW()
    WHERE stripe_payment_intent_id = p_stripe_payment_intent_id
    AND user_id = auth.uid();
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Payment not found or not authorized.';
    END IF;
    
    RETURN TRUE;
END;
$$;

-- Get batch payment information
CREATE OR REPLACE FUNCTION get_batch_payment_info(p_batch_id UUID)
RETURNS TABLE (
    payment_id UUID,
    stripe_payment_intent_id TEXT,
    stripe_client_secret TEXT,
    amount_cents INTEGER,
    currency TEXT,
    payment_status TEXT,
    payment_method TEXT,
    failure_reason TEXT,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ
) LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_batch_owner_id UUID;
BEGIN
    -- Check batch ownership
    SELECT created_by INTO v_batch_owner_id
    FROM card_batches 
    WHERE id = p_batch_id;
    
    IF v_batch_owner_id IS NULL THEN
        RAISE EXCEPTION 'Batch not found.';
    END IF;
    
    IF v_batch_owner_id != auth.uid() THEN
        RAISE EXCEPTION 'Not authorized to view payment info for this batch.';
    END IF;
    
    RETURN QUERY
    SELECT 
        bp.id as payment_id,
        bp.stripe_payment_intent_id,
        bp.stripe_client_secret,
        bp.amount_cents,
        bp.currency,
        bp.payment_status,
        bp.payment_method,
        bp.failure_reason,
        bp.created_at,
        bp.updated_at
    FROM batch_payments bp
    WHERE bp.batch_id = p_batch_id;
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
BEGIN
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
    WHERE cb.card_id = p_card_id AND c.user_id = auth.uid()
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
    activation_code TEXT,
    active BOOLEAN,
    issue_at TIMESTAMPTZ,
    active_at TIMESTAMPTZ,
    activated_by UUID,
    batch_id UUID,
    batch_name TEXT,
    batch_number INTEGER,
    batch_is_disabled BOOLEAN
) LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ic.id,
        c.id as card_id,
        ic.activation_code,
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
    WHERE ic.card_id = p_card_id AND c.user_id = auth.uid()
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
    
    RETURN FOUND;
END;
$$;

-- Activate an issued card
CREATE OR REPLACE FUNCTION activate_issued_card(p_card_id UUID, p_activation_code TEXT)
RETURNS BOOLEAN LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
    UPDATE issue_cards
    SET 
        active = true,
        active_at = NOW(),
        activated_by = auth.uid()
    WHERE id = p_card_id AND activation_code = p_activation_code AND active = false;
    
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

-- ===============================
-- PRINT REQUEST FUNCTIONS
-- ===============================

-- Request card printing for a batch
CREATE OR REPLACE FUNCTION request_card_printing(p_batch_id UUID, p_shipping_address TEXT)
RETURNS UUID LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_print_request_id UUID;
    v_user_id UUID;
    v_batch_is_disabled BOOLEAN;
    v_payment_completed BOOLEAN;
    v_payment_waived BOOLEAN;
    v_cards_generated BOOLEAN;
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

    INSERT INTO print_requests (
        batch_id,
        user_id,
        shipping_address,
        status
    ) VALUES (
        p_batch_id,
        auth.uid(),
        p_shipping_address,
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
GRANT EXECUTE ON FUNCTION request_card_printing_with_address(UUID, UUID) TO authenticated;

-- Get print requests for a batch
CREATE OR REPLACE FUNCTION get_print_requests_for_batch(p_batch_id UUID)
RETURNS TABLE (
    id UUID,
    batch_id UUID,
    user_id UUID,
    status TEXT, -- "PrintRequestStatus"
    shipping_address TEXT,
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
GRANT EXECUTE ON FUNCTION withdraw_print_request(UUID, TEXT) TO authenticated;

-- Get public card content and activate if necessary
CREATE OR REPLACE FUNCTION get_public_card_content(p_issue_card_id UUID, p_activation_code TEXT)
RETURNS TABLE (
    card_name TEXT,
    card_description TEXT,
    card_image_urls TEXT[],
    card_conversation_ai_enabled BOOLEAN,
    card_ai_prompt TEXT,
    content_item_id UUID,
    content_item_parent_id UUID,
    content_item_name TEXT,
    content_item_content TEXT,
    content_item_image_urls TEXT[],
    content_item_ai_metadata TEXT,
    content_item_sort_order INTEGER,
    is_activated BOOLEAN
) LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_card_design_id UUID;
    v_is_card_active BOOLEAN;
    v_card_owner_id UUID;
    v_caller_id UUID;
    v_activation_attempted BOOLEAN := FALSE;
    v_is_owner_access BOOLEAN := FALSE;
    v_is_preview_mode BOOLEAN := FALSE;
BEGIN
    -- Get the caller's user ID
    v_caller_id := auth.uid();
    
    -- Check if this is preview mode (activation code starts with 'PREVIEW_')
    IF p_activation_code LIKE 'PREVIEW_%' THEN
        v_is_preview_mode := TRUE;
        -- Extract card_id from the activation code
        BEGIN
            v_card_design_id := SUBSTRING(p_activation_code FROM 9)::UUID;
        EXCEPTION WHEN OTHERS THEN
            -- Invalid preview code format
            RETURN;
        END;
        
        -- Verify the caller owns this card
        SELECT user_id INTO v_card_owner_id FROM cards WHERE id = v_card_design_id;
        
        IF v_card_owner_id IS NULL OR v_card_owner_id != v_caller_id THEN
            -- Card not found or user doesn't own it
            RETURN;
        END IF;
        
        -- Set preview mode flags
        v_is_card_active := TRUE; -- Always "active" in preview mode
        v_is_owner_access := TRUE;
    ELSE
        -- Normal issued card mode
        -- Check if the issued card exists and get its card_id (design_id), current active status, and owner
        SELECT ic.card_id, ic.active, c.user_id 
        INTO v_card_design_id, v_is_card_active, v_card_owner_id
    FROM issue_cards ic
        JOIN cards c ON ic.card_id = c.id
        WHERE ic.id = p_issue_card_id;

    IF NOT FOUND THEN
            -- If no card matches ID, return empty
            RETURN;
        END IF;

        -- Check if the caller is the card owner
        IF v_caller_id IS NOT NULL AND v_caller_id = v_card_owner_id THEN
            v_is_owner_access := TRUE;
            -- For owner access, we don't need to validate activation code
            -- and we consider the card as "activated" for preview purposes
            v_is_card_active := TRUE;
        ELSE
            -- For non-owner access, validate activation code
            IF NOT EXISTS (
                SELECT 1 FROM issue_cards 
                WHERE id = p_issue_card_id AND activation_code = p_activation_code
            ) THEN
                -- If activation code doesn't match, return empty
        RETURN;
    END IF;

    -- If the card is not active, attempt to activate it
    IF NOT v_is_card_active THEN
        UPDATE issue_cards
        SET 
            active = true,
            active_at = NOW()
            -- activated_by could be NULL for public activation or a generic system user ID
        WHERE id = p_issue_card_id AND activation_code = p_activation_code AND active = false;
        
        v_activation_attempted := TRUE;
        v_is_card_active := TRUE; -- Assume activation was successful for the current request
            END IF;
        END IF;
    END IF;

    RETURN QUERY
    SELECT 
        c.name AS card_name,
        c.description AS card_description,
        c.image_urls AS card_image_urls,
        c.conversation_ai_enabled AS card_conversation_ai_enabled,
        c.ai_prompt AS card_ai_prompt,
        ci.id AS content_item_id,
        ci.parent_id AS content_item_parent_id,
        ci.name AS content_item_name,
        ci.content AS content_item_content,
        ci.image_urls AS content_item_image_urls,
        ci.ai_metadata AS content_item_ai_metadata,
        ci.sort_order AS content_item_sort_order,
        v_is_card_active AS is_activated -- Return the current/newly activated status
    FROM cards c
    LEFT JOIN content_items ci ON c.id = ci.card_id
    WHERE c.id = v_card_design_id 
    AND (c.published = TRUE OR v_is_owner_access = TRUE) -- Show published cards or allow owner access
    ORDER BY 
        CASE WHEN ci.parent_id IS NULL THEN ci.sort_order ELSE 999999 END,
        ci.parent_id NULLS FIRST,
        ci.sort_order ASC,
        ci.created_at ASC;
END;
$$;

-- Get a sample issued card for mobile preview (card issuer only)
CREATE OR REPLACE FUNCTION get_sample_issued_card_for_preview(p_card_id UUID)
RETURNS TABLE (
    issue_card_id UUID,
    activation_code TEXT
) LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_user_id UUID;
BEGIN
    -- Check if the user owns the card
    SELECT user_id INTO v_user_id FROM cards WHERE id = p_card_id;
    
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Card not found.';
    END IF;
    
    IF v_user_id != auth.uid() THEN
        RAISE EXCEPTION 'Not authorized to preview this card.';
    END IF;
    
    -- Get the first available issued card for this card design
    -- Prefer active cards, but fall back to inactive ones if needed
    RETURN QUERY
    SELECT 
        ic.id as issue_card_id,
        ic.activation_code
    FROM issue_cards ic
    JOIN card_batches cb ON ic.batch_id = cb.id
    WHERE ic.card_id = p_card_id 
    AND cb.is_disabled = FALSE -- Only from enabled batches
    ORDER BY 
        ic.active DESC, -- Active cards first
        ic.issue_at DESC -- Most recent first
    LIMIT 1;
END;
$$;

-- Get card preview URL without requiring issued cards (for card owners)
CREATE OR REPLACE FUNCTION get_card_preview_access(p_card_id UUID)
RETURNS TABLE (
    preview_mode BOOLEAN,
    card_id UUID,
    activation_code TEXT
) LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_user_id UUID;
BEGIN
    -- Check if the user owns the card
    SELECT user_id INTO v_user_id FROM cards WHERE id = p_card_id;
    
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Card not found.';
    END IF;
    
    IF v_user_id != auth.uid() THEN
        RAISE EXCEPTION 'Not authorized to preview this card.';
    END IF;
    
    -- Return preview access with special preview mode flag and the card_id as the "issue_card_id"
    -- Using a special preview activation code that will be recognized by the backend
    RETURN QUERY
    SELECT 
        TRUE as preview_mode,
        p_card_id as card_id,
        'PREVIEW_' || p_card_id::TEXT as activation_code;
END;
$$;

-- =================================================================
-- MOVED FROM TRIGGERS.SQL / AUTH_TRIGGERS.SQL
-- =================================================================

-- Function to set default role for new users (from triggers.sql)
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER -- Required to modify auth.users table
SET search_path = public
AS $$
BEGIN
  UPDATE auth.users
  SET raw_user_meta_data = raw_user_meta_data || jsonb_build_object('role', 'cardIssuer')
  WHERE id = NEW.id;
  RETURN NEW;
END;
$$;

-- Grant execute permission for handle_new_user (from triggers.sql)
GRANT EXECUTE ON FUNCTION public.handle_new_user() TO supabase_auth_admin;

-- Function to get user role (from auth_triggers.sql)
CREATE OR REPLACE FUNCTION public.get_user_role(user_id UUID)
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
  role TEXT;
BEGIN
  SELECT raw_user_meta_data->>'role' INTO role FROM auth.users WHERE id = user_id;
  RETURN role;
END;
$$;

-- Grant execute permission for get_user_role (from auth_triggers.sql)
GRANT EXECUTE ON FUNCTION public.get_user_role(UUID) TO postgres, anon, authenticated, service_role;

-- =================================================================
-- USER PROFILE FUNCTIONS
-- =================================================================

-- Drop existing function first to avoid return type conflicts
DROP FUNCTION IF EXISTS public.get_user_profile();

-- Get the profile for the currently authenticated user
CREATE OR REPLACE FUNCTION public.get_user_profile()
RETURNS TABLE (
    user_id UUID,
    public_name TEXT,
    bio TEXT,
    company_name TEXT,
    full_name TEXT,
    verification_status "ProfileStatus",
    supporting_documents TEXT[],
    admin_feedback TEXT,
    verified_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ
)
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
    RETURN QUERY
    SELECT 
        up.user_id,
        up.public_name,
        up.bio,
        up.company_name,
        up.full_name,
        up.verification_status,
        up.supporting_documents,
        up.admin_feedback,
        up.verified_at,
        up.created_at,
        up.updated_at
    FROM public.user_profiles up
    WHERE up.user_id = auth.uid();
END;
$$;
GRANT EXECUTE ON FUNCTION public.get_user_profile() TO authenticated;


-- Drop existing function first to avoid parameter conflicts
DROP FUNCTION IF EXISTS public.create_or_update_user_profile(TEXT, TEXT, TEXT, TEXT[]);
DROP FUNCTION IF EXISTS public.create_or_update_user_profile(TEXT, TEXT, TEXT, TEXT, TEXT[]);

-- Create or Update basic user profile (no verification)
CREATE OR REPLACE FUNCTION public.create_or_update_basic_profile(
    p_public_name TEXT,
    p_bio TEXT,
    p_company_name TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_user_id UUID := auth.uid();
BEGIN
    INSERT INTO public.user_profiles (user_id, public_name, bio, company_name)
    VALUES (v_user_id, p_public_name, p_bio, p_company_name)
    ON CONFLICT (user_id) DO UPDATE 
    SET 
        public_name = EXCLUDED.public_name,
        bio = EXCLUDED.bio,
        company_name = EXCLUDED.company_name,
        updated_at = NOW();
    
    RETURN v_user_id;
END;
$$;
GRANT EXECUTE ON FUNCTION public.create_or_update_basic_profile(TEXT, TEXT, TEXT) TO authenticated;


-- Submit verification application
CREATE OR REPLACE FUNCTION public.submit_verification(
    p_full_name TEXT,
    p_supporting_documents TEXT[]
)
RETURNS UUID
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_user_id UUID := auth.uid();
BEGIN
    -- Update the profile with verification info
    UPDATE public.user_profiles 
    SET 
        full_name = p_full_name,
        supporting_documents = p_supporting_documents,
        verification_status = 'PENDING_REVIEW',
        admin_feedback = NULL, -- Clear previous feedback
        updated_at = NOW()
    WHERE user_id = v_user_id;
    
    -- If no profile exists yet, create one (shouldn't happen in normal flow)
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Profile must be created before submitting verification';
    END IF;
    
    RETURN v_user_id;
END;
$$;
GRANT EXECUTE ON FUNCTION public.submit_verification(TEXT, TEXT[]) TO authenticated;

-- (Admin) Function to review a verification
CREATE OR REPLACE FUNCTION public.review_verification(
    p_target_user_id UUID,
    p_new_status "ProfileStatus",
    p_admin_feedback TEXT
)
RETURNS BOOLEAN
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    caller_role TEXT;
BEGIN
    -- Check if the caller is an admin
    SELECT raw_user_meta_data->>'role' INTO caller_role
    FROM auth.users
    WHERE id = auth.uid();

    IF caller_role != 'admin' THEN
        RAISE EXCEPTION 'Only admins can review verifications.';
    END IF;

    -- Ensure status is only set to APPROVED or REJECTED
    IF p_new_status NOT IN ('APPROVED', 'REJECTED') THEN
        RAISE EXCEPTION 'Review status must be APPROVED or REJECTED.';
    END IF;

    UPDATE public.user_profiles
    SET 
        verification_status = p_new_status,
        admin_feedback = p_admin_feedback,
        verified_at = CASE WHEN p_new_status = 'APPROVED' THEN NOW() ELSE NULL END,
        updated_at = NOW()
    WHERE user_id = p_target_user_id;

    -- Create feedback history entry with full traceability
    PERFORM create_or_update_admin_feedback(
        'user_verification',
        p_target_user_id,
        p_target_user_id,
        'verification_feedback',
        p_admin_feedback,
        jsonb_build_object(
            'action', 'verification_review',
            'new_status', p_new_status,
            'timestamp', NOW()
        )
    );

    -- Log in audit table
    INSERT INTO admin_audit_log (
        admin_user_id,
        target_user_id,
        action_type,
        reason,
        new_values,
        action_details
    ) VALUES (
        auth.uid(),
        p_target_user_id,
        'VERIFICATION_REVIEW',
        p_admin_feedback,
        jsonb_build_object(
            'verification_status', p_new_status,
            'verified_at', CASE WHEN p_new_status = 'APPROVED' THEN NOW() ELSE NULL END
        ),
        jsonb_build_object('review_verification', true)
    );
    
    RETURN FOUND;
END;
$$;
GRANT EXECUTE ON FUNCTION public.review_verification(UUID, "ProfileStatus", TEXT) TO authenticated;

-- (User) Function to withdraw verification submission
CREATE OR REPLACE FUNCTION public.withdraw_verification()
RETURNS BOOLEAN
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_current_status "ProfileStatus";
BEGIN
    -- Get current verification status
    SELECT verification_status INTO v_current_status
    FROM public.user_profiles
    WHERE user_id = v_user_id;
    
    -- Only allow withdrawal if status is PENDING_REVIEW
    IF v_current_status != 'PENDING_REVIEW' THEN
        RAISE EXCEPTION 'Verification can only be withdrawn when status is PENDING_REVIEW. Current status: %', v_current_status;
    END IF;

    -- Reset verification status and clear verification data
    UPDATE public.user_profiles
    SET 
        verification_status = 'NOT_SUBMITTED',
        full_name = NULL,
        supporting_documents = NULL,
        admin_feedback = NULL,
        verified_at = NULL,
        updated_at = NOW()
    WHERE user_id = v_user_id;
    
    RETURN FOUND;
END;
$$;
GRANT EXECUTE ON FUNCTION public.withdraw_verification() TO authenticated;

-- ===============================
-- USER-LEVEL ISSUED CARDS FUNCTIONS (across all cards)
-- ===============================

-- Get all issued cards for the current user across all their card designs
CREATE OR REPLACE FUNCTION get_user_all_issued_cards()
RETURNS TABLE (
    id UUID,
    card_id UUID,
    card_name TEXT,
    card_image_urls TEXT[],
    activation_code TEXT,
    active BOOLEAN,
    issue_at TIMESTAMPTZ,
    active_at TIMESTAMPTZ,
    activated_by UUID,
    batch_id UUID,
    batch_name TEXT,
    batch_number INTEGER,
    batch_is_disabled BOOLEAN
) LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ic.id,
        c.id as card_id,
        c.name as card_name,
        c.image_urls as card_image_urls,
        ic.activation_code,
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
    WHERE c.user_id = auth.uid()
    ORDER BY ic.issue_at DESC;
END;
$$;

-- Get aggregated statistics for all cards of the current user
CREATE OR REPLACE FUNCTION get_user_issuance_stats()
RETURNS TABLE (
    total_issued BIGINT,
    total_activated BIGINT,
    activation_rate NUMERIC,
    total_batches BIGINT,
    total_cards BIGINT,
    pending_cards BIGINT,
    disabled_batches BIGINT,
    active_print_requests BIGINT
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
        COUNT(DISTINCT cb.id) as total_batches,
        COUNT(DISTINCT c.id) as total_cards,
        COUNT(ic.id) FILTER (WHERE ic.active = false) as pending_cards,
        COUNT(DISTINCT cb.id) FILTER (WHERE cb.is_disabled = true) as disabled_batches,
        COUNT(DISTINCT pr.id) FILTER (WHERE pr.status NOT IN ('COMPLETED', 'CANCELLED')) as active_print_requests
    FROM cards c
    LEFT JOIN card_batches cb ON c.id = cb.card_id
    LEFT JOIN issue_cards ic ON cb.id = ic.batch_id
    LEFT JOIN print_requests pr ON cb.id = pr.batch_id
    WHERE c.user_id = auth.uid();
END;
$$;

-- Get all card batches for the current user across all their card designs
CREATE OR REPLACE FUNCTION get_user_all_card_batches()
RETURNS TABLE (
    id UUID,
    card_id UUID,
    card_name TEXT,
    card_published BOOLEAN,
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
BEGIN
    RETURN QUERY
    SELECT 
        cb.id,
        cb.card_id,
        c.name as card_name,
        c.published as card_published,
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
    WHERE c.user_id = auth.uid()
    GROUP BY cb.id, cb.card_id, c.name, c.published, cb.batch_name, cb.batch_number, cb.cards_count, cb.is_disabled, 
             cb.payment_required, cb.payment_completed, cb.payment_amount_cents, cb.payment_completed_at,
             cb.payment_waived, cb.payment_waived_by, cb.payment_waived_at, cb.payment_waiver_reason,
             cb.cards_generated, cb.cards_generated_at, cb.created_at, cb.updated_at
    ORDER BY cb.created_at DESC;
END;
$$;

-- Get recent issuance activity across all cards
CREATE OR REPLACE FUNCTION get_user_recent_activity(p_limit INTEGER DEFAULT 50)
RETURNS TABLE (
    activity_type TEXT,
    activity_date TIMESTAMPTZ,
    card_name TEXT,
    batch_name TEXT,
    description TEXT,
    count INTEGER
) LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
    RETURN QUERY
    (
        -- Recent batch creations
        SELECT 
            'batch_created'::TEXT as activity_type,
            cb.created_at as activity_date,
            c.name as card_name,
            cb.batch_name,
            'Batch created with ' || cb.cards_count || ' cards' as description,
            cb.cards_count as count
        FROM card_batches cb
        JOIN cards c ON cb.card_id = c.id
        WHERE c.user_id = auth.uid()
        
        UNION ALL
        
        -- Recent card activations
        SELECT 
            'card_activated'::TEXT as activity_type,
            ic.active_at as activity_date,
            c.name as card_name,
            cb.batch_name,
            'Card activated' as description,
            1 as count
        FROM issue_cards ic
        JOIN card_batches cb ON ic.batch_id = cb.id
        JOIN cards c ON ic.card_id = c.id
        WHERE c.user_id = auth.uid() AND ic.active_at IS NOT NULL
        
        UNION ALL
        
        -- Recent print requests
        SELECT 
            'print_requested'::TEXT as activity_type,
            pr.requested_at as activity_date,
            c.name as card_name,
            cb.batch_name,
            'Print request submitted' as description,
            cb.cards_count as count
        FROM print_requests pr
        JOIN card_batches cb ON pr.batch_id = cb.id
        JOIN cards c ON cb.card_id = c.id
        WHERE c.user_id = auth.uid()
    )
    ORDER BY activity_date DESC
    LIMIT p_limit;
END;
$$;

-- ===============================
-- ADMIN-SPECIFIC FUNCTIONS
-- ===============================

-- Get all pending verifications for admin review
CREATE OR REPLACE FUNCTION get_all_pending_verifications()
RETURNS TABLE (
    user_id UUID,
    user_email TEXT,
    public_name TEXT,
    bio TEXT,
    company_name TEXT,
    full_name TEXT,
    verification_status "ProfileStatus",
    supporting_documents TEXT[],
    admin_feedback TEXT,
    verified_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ
) LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    caller_role TEXT;
BEGIN
    -- Check if caller is admin
    SELECT raw_user_meta_data->>'role' INTO caller_role
    FROM auth.users
    WHERE auth.users.id = auth.uid();

    IF caller_role != 'admin' THEN
        RAISE EXCEPTION 'Only admins can view pending verifications.';
    END IF;

    RETURN QUERY
    SELECT 
        up.user_id,
        au.email::TEXT as user_email,
        up.public_name,
        up.bio,
        up.company_name,
        up.full_name,
        up.verification_status,
        up.supporting_documents,
        up.admin_feedback,
        up.verified_at,
        up.created_at,
        up.updated_at
    FROM public.user_profiles up
    JOIN auth.users au ON up.user_id = au.id
    WHERE up.verification_status = 'PENDING_REVIEW'
    ORDER BY up.updated_at ASC; -- Oldest first for fair processing
END;
$$;
GRANT EXECUTE ON FUNCTION get_all_pending_verifications() TO authenticated;

-- Get all verifications with optional status filter
CREATE OR REPLACE FUNCTION get_all_verifications(p_status "ProfileStatus" DEFAULT NULL)
RETURNS TABLE (
    user_id UUID,
    user_email TEXT,
    public_name TEXT,
    bio TEXT,
    company_name TEXT,
    full_name TEXT,
    verification_status "ProfileStatus",
    supporting_documents TEXT[],
    admin_feedback TEXT,
    verified_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ
) LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    caller_role TEXT;
BEGIN
    -- Check if caller is admin
    SELECT raw_user_meta_data->>'role' INTO caller_role
    FROM auth.users
    WHERE auth.users.id = auth.uid();

    IF caller_role != 'admin' THEN
        RAISE EXCEPTION 'Only admins can view all verifications.';
    END IF;

    RETURN QUERY
    SELECT 
        up.user_id,
        au.email::TEXT as user_email,
        up.public_name,
        up.bio,
        up.company_name,
        up.full_name,
        up.verification_status,
        up.supporting_documents,
        up.admin_feedback,
        up.verified_at,
        up.created_at,
        up.updated_at
    FROM public.user_profiles up
    JOIN auth.users au ON up.user_id = au.id
    WHERE (p_status IS NULL OR up.verification_status = p_status)
    AND up.verification_status != 'NOT_SUBMITTED' -- Only show submitted verifications
    ORDER BY up.updated_at DESC;
END;
$$;
GRANT EXECUTE ON FUNCTION get_all_verifications("ProfileStatus") TO authenticated;

-- Get specific verification by user ID
CREATE OR REPLACE FUNCTION get_verification_by_id(p_user_id UUID)
RETURNS TABLE (
    user_id UUID,
    user_email TEXT,
    public_name TEXT,
    bio TEXT,
    company_name TEXT,
    full_name TEXT,
    verification_status "ProfileStatus",
    supporting_documents TEXT[],
    admin_feedback TEXT,
    verified_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ
) LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    caller_role TEXT;
BEGIN
    -- Check if caller is admin
    SELECT raw_user_meta_data->>'role' INTO caller_role
    FROM auth.users
    WHERE auth.users.id = auth.uid();

    IF caller_role != 'admin' THEN
        RAISE EXCEPTION 'Only admins can view verification details.';
    END IF;

    RETURN QUERY
    SELECT 
        up.user_id,
        au.email::TEXT as user_email,
        up.public_name,
        up.bio,
        up.company_name,
        up.full_name,
        up.verification_status,
        up.supporting_documents,
        up.admin_feedback,
        up.verified_at,
        up.created_at,
        up.updated_at
    FROM public.user_profiles up
    JOIN auth.users au ON up.user_id = au.id
    WHERE up.user_id = p_user_id;
END;
$$;
GRANT EXECUTE ON FUNCTION get_verification_by_id(UUID) TO authenticated;

-- Get all print requests for admin management
CREATE OR REPLACE FUNCTION get_all_print_requests(p_status "PrintRequestStatus" DEFAULT NULL)
RETURNS TABLE (
    id UUID,
    batch_id UUID,
    batch_name TEXT,
    batch_number INTEGER,
    card_name TEXT,
    cards_count INTEGER,
    user_id UUID,
    user_email TEXT,
    user_public_name TEXT,
    status "PrintRequestStatus",
    shipping_address TEXT,
    admin_notes TEXT,
    requested_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ
) LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    caller_role TEXT;
BEGIN
    -- Check if caller is admin
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
        cb.batch_name,
        cb.batch_number,
        c.name as card_name,
        cb.cards_count,
        pr.user_id,
        au.email::TEXT as user_email,
        up.public_name as user_public_name,
        pr.status,
        pr.shipping_address,
        pr.admin_notes,
        pr.requested_at,
        pr.updated_at
    FROM 
        public.print_requests pr
    JOIN 
        public.card_batches cb ON pr.batch_id = cb.id
    JOIN 
        public.cards c ON cb.card_id = c.id
    JOIN 
        auth.users au ON pr.user_id = au.id
    LEFT JOIN 
        public.user_profiles up ON pr.user_id = up.user_id
    WHERE 
        (p_status IS NULL OR pr.status = p_status)
    ORDER BY 
        pr.requested_at DESC;
END;
$$;
GRANT EXECUTE ON FUNCTION get_all_print_requests("PrintRequestStatus") TO authenticated;

-- Update print request status and details (admin only)
CREATE OR REPLACE FUNCTION update_print_request_status(
    p_request_id UUID,
    p_new_status "PrintRequestStatus",
    p_admin_notes TEXT DEFAULT NULL
)
RETURNS BOOLEAN LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    caller_role TEXT;
    old_status "PrintRequestStatus";
    old_notes TEXT;
    request_user_id UUID;
BEGIN
    -- Check if caller is admin
    SELECT raw_user_meta_data->>'role' INTO caller_role
    FROM auth.users
    WHERE auth.users.id = auth.uid();

    IF caller_role != 'admin' THEN
        RAISE EXCEPTION 'Only admins can update print request status.';
    END IF;

    -- Get current status and notes for audit
    SELECT status, admin_notes, user_id INTO old_status, old_notes, request_user_id
    FROM print_requests
    WHERE id = p_request_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Print request not found.';
    END IF;

    UPDATE print_requests
    SET 
        status = p_new_status,
        admin_notes = COALESCE(p_admin_notes, admin_notes),
        updated_at = NOW()
    WHERE id = p_request_id;

    -- Create feedback history entry for admin notes if provided
    IF p_admin_notes IS NOT NULL THEN
        PERFORM create_or_update_admin_feedback(
            'print_request',
            p_request_id,
            request_user_id,
            'print_notes',
            p_admin_notes,
            jsonb_build_object(
                'action', 'status_update',
                'old_status', old_status,
                'new_status', p_new_status,
                'timestamp', NOW()
            )
        );
    END IF;

    -- Log in audit table
    INSERT INTO admin_audit_log (
        admin_user_id,
        target_user_id,
        action_type,
        reason,
        old_values,
        new_values,
        action_details
    ) VALUES (
        auth.uid(),
        request_user_id,
        'PRINT_REQUEST_UPDATE',
        COALESCE(p_admin_notes, 'Status update'),
        jsonb_build_object(
            'status', old_status,
            'admin_notes', old_notes
        ),
        jsonb_build_object(
            'status', p_new_status,
            'admin_notes', p_admin_notes
        ),
        jsonb_build_object('request_id', p_request_id)
    );
    
    RETURN FOUND;
END;
$$;
GRANT EXECUTE ON FUNCTION update_print_request_status(UUID, "PrintRequestStatus", TEXT) TO authenticated;

-- Get admin dashboard statistics
CREATE OR REPLACE FUNCTION get_admin_dashboard_stats()
RETURNS TABLE (
    total_users BIGINT,
    total_card_designs BIGINT,
    total_issued_cards BIGINT,
    total_activated_cards BIGINT,
    pending_verifications BIGINT,
    approved_verifications BIGINT,
    rejected_verifications BIGINT,
    pending_print_requests BIGINT,
    active_print_requests BIGINT,
    completed_print_requests BIGINT,
    total_batches BIGINT,
    paid_batches BIGINT,
    unpaid_batches BIGINT,
    waived_batches BIGINT,
    pending_payment_batches BIGINT,
    total_revenue_cents BIGINT,
    total_waived_amount_cents BIGINT
) LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    caller_role TEXT;
BEGIN
    -- Check if caller is admin
    SELECT raw_user_meta_data->>'role' INTO caller_role
    FROM auth.users
    WHERE auth.users.id = auth.uid();

    IF caller_role != 'admin' THEN
        RAISE EXCEPTION 'Only admins can view dashboard statistics.';
    END IF;

    RETURN QUERY
    SELECT 
        (SELECT COUNT(*) FROM auth.users WHERE raw_user_meta_data->>'role' = 'cardIssuer') as total_users,
        (SELECT COUNT(*) FROM cards) as total_card_designs,
        (SELECT COUNT(*) FROM issue_cards) as total_issued_cards,
        (SELECT COUNT(*) FROM issue_cards WHERE active = true) as total_activated_cards,
        (SELECT COUNT(*) FROM user_profiles WHERE verification_status = 'PENDING_REVIEW') as pending_verifications,
        (SELECT COUNT(*) FROM user_profiles WHERE verification_status = 'APPROVED') as approved_verifications,
        (SELECT COUNT(*) FROM user_profiles WHERE verification_status = 'REJECTED') as rejected_verifications,
        (SELECT COUNT(*) FROM print_requests WHERE status = 'SUBMITTED') as pending_print_requests,
        (SELECT COUNT(*) FROM print_requests WHERE status IN ('PAYMENT_PENDING', 'PROCESSING', 'SHIPPED')) as active_print_requests,
        (SELECT COUNT(*) FROM print_requests WHERE status = 'COMPLETED') as completed_print_requests,
        (SELECT COUNT(*) FROM card_batches) as total_batches,
        (SELECT COUNT(*) FROM card_batches WHERE payment_completed = true) as paid_batches,
        (SELECT COUNT(*) FROM card_batches WHERE payment_required = true AND payment_completed = false AND payment_waived = false) as unpaid_batches,
        (SELECT COUNT(*) FROM card_batches WHERE payment_waived = true) as waived_batches,
        (SELECT COUNT(*) FROM card_batches WHERE payment_required = true AND payment_completed = false AND payment_waived = false AND cards_generated = false) as pending_payment_batches,
        (SELECT COALESCE(SUM(payment_amount_cents), 0) FROM card_batches WHERE payment_completed = true) as total_revenue_cents,
        (SELECT COALESCE(SUM(payment_amount_cents), 0) FROM card_batches WHERE payment_waived = true) as total_waived_amount_cents;
END;
$$;
GRANT EXECUTE ON FUNCTION get_admin_dashboard_stats() TO authenticated;

-- Get recent admin activity
CREATE OR REPLACE FUNCTION get_recent_admin_activity(p_limit INTEGER DEFAULT 50)
RETURNS TABLE (
    activity_type TEXT,
    activity_date TIMESTAMPTZ,
    user_email TEXT,
    user_public_name TEXT,
    description TEXT,
    details JSONB
) LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    caller_role TEXT;
BEGIN
    -- Check if caller is admin
    SELECT raw_user_meta_data->>'role' INTO caller_role
    FROM auth.users
    WHERE auth.users.id = auth.uid();

    IF caller_role != 'admin' THEN
        RAISE EXCEPTION 'Only admins can view admin activity.';
    END IF;

    RETURN QUERY
    (
        -- Recent verification updates
        SELECT 
            'verification_updated'::TEXT as activity_type,
            up.updated_at as activity_date,
            au.email::TEXT as user_email,
            up.public_name as user_public_name,
            'Verification status: ' || up.verification_status::TEXT as description,
            jsonb_build_object(
                'status', up.verification_status,
                'verified_at', up.verified_at,
                'admin_feedback', up.admin_feedback
            ) as details
        FROM public.user_profiles up
        JOIN auth.users au ON up.user_id = au.id
        WHERE up.verification_status IN ('APPROVED', 'REJECTED')
        AND up.updated_at > NOW() - INTERVAL '30 days'
        
        UNION ALL
        
        -- Recent print request updates
        SELECT 
            'print_request_updated'::TEXT as activity_type,
            pr.updated_at as activity_date,
            au.email::TEXT as user_email,
            up.public_name as user_public_name,
            'Print request: ' || pr.status::TEXT as description,
            jsonb_build_object(
                'request_id', pr.id,
                'status', pr.status,
                'card_name', c.name,
                'batch_name', cb.batch_name,
                'cards_count', cb.cards_count
            ) as details
        FROM print_requests pr
        JOIN card_batches cb ON pr.batch_id = cb.id
        JOIN cards c ON cb.card_id = c.id
        JOIN auth.users au ON pr.user_id = au.id
        LEFT JOIN public.user_profiles up ON pr.user_id = up.user_id
        WHERE pr.updated_at > NOW() - INTERVAL '30 days'
        
        UNION ALL
        
        -- Recent user registrations
        SELECT 
            'user_registered'::TEXT as activity_type,
            au.created_at as activity_date,
            au.email::TEXT as user_email,
            up.public_name as user_public_name,
            'New user registered' as description,
            jsonb_build_object(
                'user_id', au.id,
                'role', au.raw_user_meta_data->>'role'
            ) as details
        FROM auth.users au
        LEFT JOIN public.user_profiles up ON au.id = up.user_id
        WHERE au.raw_user_meta_data->>'role' = 'cardIssuer'
        AND au.created_at > NOW() - INTERVAL '30 days'
    )
    ORDER BY activity_date DESC
    LIMIT p_limit;
END;
$$;
GRANT EXECUTE ON FUNCTION get_recent_admin_activity(INTEGER) TO authenticated;

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
    
    RETURN FOUND;
END;
$$;
GRANT EXECUTE ON FUNCTION delete_issued_card(UUID) TO authenticated;

-- Get all users with detailed information (admin only)
CREATE OR REPLACE FUNCTION get_all_users_with_details()
RETURNS TABLE (
    user_id UUID,
    user_email TEXT,
    role TEXT,
    public_name TEXT,
    bio TEXT,
    company_name TEXT,
    full_name TEXT,
    verification_status "ProfileStatus",
    supporting_documents TEXT[],
    admin_feedback TEXT,
    verified_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ,
    last_sign_in_at TIMESTAMPTZ,
    cards_count BIGINT,
    issued_cards_count BIGINT,
    print_requests_count BIGINT
) LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    caller_role TEXT;
BEGIN
    -- Check if caller is admin
    SELECT raw_user_meta_data->>'role' INTO caller_role
    FROM auth.users
    WHERE auth.users.id = auth.uid();

    IF caller_role != 'admin' THEN
        RAISE EXCEPTION 'Only admins can view all user details.';
    END IF;

    RETURN QUERY
    SELECT 
        au.id as user_id,
        au.email::TEXT as user_email,
        au.raw_user_meta_data->>'role' as role,
        up.public_name,
        up.bio,
        up.company_name,
        up.full_name,
        up.verification_status,
        up.supporting_documents,
        up.admin_feedback,
        up.verified_at,
        au.created_at,
        up.updated_at,
        au.last_sign_in_at,
        COALESCE(cards_stats.card_count, 0) as cards_count,
        COALESCE(issued_stats.issued_count, 0) as issued_cards_count,
        COALESCE(print_stats.print_count, 0) as print_requests_count
    FROM auth.users au
    LEFT JOIN public.user_profiles up ON au.id = up.user_id
    LEFT JOIN (
        SELECT c.user_id, COUNT(c.id) as card_count
        FROM public.cards c
        GROUP BY c.user_id
    ) cards_stats ON au.id = cards_stats.user_id
    LEFT JOIN (
        SELECT c.user_id, COUNT(ic.id) as issued_count
        FROM public.cards c
        JOIN public.issue_cards ic ON c.id = ic.card_id
        GROUP BY c.user_id
    ) issued_stats ON au.id = issued_stats.user_id
    LEFT JOIN (
        SELECT c.user_id, COUNT(pr.id) as print_count
        FROM public.cards c
        JOIN public.card_batches cb ON c.id = cb.card_id
        JOIN public.print_requests pr ON cb.id = pr.batch_id
        GROUP BY c.user_id
    ) print_stats ON au.id = print_stats.user_id
    WHERE au.raw_user_meta_data->>'role' IN ('cardIssuer', 'admin', 'user')
    ORDER BY au.created_at DESC;
END;
$$;
GRANT EXECUTE ON FUNCTION get_all_users_with_details() TO authenticated;

-- Update user role (admin only)
CREATE OR REPLACE FUNCTION update_user_role(
    p_user_email TEXT,
    p_new_role TEXT,
    p_reason TEXT
)
RETURNS BOOLEAN LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    caller_role TEXT;
    target_user_id UUID;
    old_role TEXT;
BEGIN
    -- Check if caller is admin
    SELECT raw_user_meta_data->>'role' INTO caller_role
    FROM auth.users
    WHERE auth.users.id = auth.uid();

    IF caller_role != 'admin' THEN
        RAISE EXCEPTION 'Only admins can update user roles.';
    END IF;

    -- Validate new role
    IF p_new_role NOT IN ('user', 'cardIssuer', 'admin') THEN
        RAISE EXCEPTION 'Invalid role. Must be user, cardIssuer, or admin.';
    END IF;

    -- Find the target user and get current role
    SELECT id, raw_user_meta_data->>'role' INTO target_user_id, old_role
    FROM auth.users
    WHERE email = p_user_email;

    IF target_user_id IS NULL THEN
        RAISE EXCEPTION 'User not found with email: %', p_user_email;
    END IF;

    -- Update the user role
    UPDATE auth.users
    SET raw_user_meta_data = 
        COALESCE(raw_user_meta_data, '{}'::jsonb) || jsonb_build_object('role', p_new_role)
    WHERE id = target_user_id;

    -- Log the role change in audit table
    INSERT INTO admin_audit_log (
        admin_user_id,
        target_user_id,
        action_type,
        reason,
        old_values,
        new_values,
        action_details
    ) VALUES (
        auth.uid(),
        target_user_id,
        'ROLE_CHANGE',
        p_reason,
        jsonb_build_object('role', COALESCE(old_role, 'cardIssuer')),
        jsonb_build_object('role', p_new_role),
        jsonb_build_object('user_email', p_user_email)
    );

    -- Create feedback history entry for role change reason
    PERFORM create_or_update_admin_feedback(
        'user_role',
        target_user_id,
        target_user_id,
        'role_change_reason',
        p_reason,
        jsonb_build_object(
            'action', 'role_change',
            'old_role', COALESCE(old_role, 'cardIssuer'),
            'new_role', p_new_role,
            'user_email', p_user_email,
            'timestamp', NOW()
        )
    );
    
    RETURN FOUND;
END;
$$;
GRANT EXECUTE ON FUNCTION update_user_role(TEXT, TEXT, TEXT) TO authenticated;

-- Admin manual verification (allow verification without submission)
CREATE OR REPLACE FUNCTION admin_manual_verification(
    p_target_user_id UUID,
    p_new_status "ProfileStatus",
    p_admin_feedback TEXT,
    p_full_name TEXT DEFAULT NULL
)
RETURNS BOOLEAN LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    caller_role TEXT;
BEGIN
    -- Check if the caller is an admin
    SELECT raw_user_meta_data->>'role' INTO caller_role
    FROM auth.users
    WHERE auth.users.id = auth.uid();

    IF caller_role != 'admin' THEN
        RAISE EXCEPTION 'Only admins can manually manage verifications.';
    END IF;

    -- Ensure status is valid for manual verification
    IF p_new_status NOT IN ('APPROVED', 'REJECTED', 'NOT_SUBMITTED') THEN
        RAISE EXCEPTION 'Manual verification status must be APPROVED, REJECTED, or NOT_SUBMITTED.';
    END IF;

    -- Create or update user profile if it doesn't exist
    INSERT INTO public.user_profiles (user_id, verification_status, admin_feedback, full_name, verified_at, updated_at)
    VALUES (
        p_target_user_id,
        p_new_status,
        p_admin_feedback,
        p_full_name,
        CASE WHEN p_new_status = 'APPROVED' THEN NOW() ELSE NULL END,
        NOW()
    )
    ON CONFLICT (user_id) DO UPDATE 
    SET 
        verification_status = EXCLUDED.verification_status,
        admin_feedback = EXCLUDED.admin_feedback,
        full_name = CASE 
            WHEN EXCLUDED.full_name IS NOT NULL THEN EXCLUDED.full_name 
            ELSE user_profiles.full_name 
        END,
        verified_at = EXCLUDED.verified_at,
        updated_at = EXCLUDED.updated_at;

    -- Create feedback history entry with full traceability
    PERFORM create_or_update_admin_feedback(
        'user_verification',
        p_target_user_id,
        p_target_user_id,
        'verification_feedback',
        p_admin_feedback,
        jsonb_build_object(
            'action', 'manual_verification',
            'new_status', p_new_status,
            'full_name', p_full_name,
            'timestamp', NOW()
        )
    );

    -- Log in audit table
    INSERT INTO admin_audit_log (
        admin_user_id,
        target_user_id,
        action_type,
        reason,
        new_values,
        action_details
    ) VALUES (
        auth.uid(),
        p_target_user_id,
        'MANUAL_VERIFICATION',
        p_admin_feedback,
        jsonb_build_object(
            'verification_status', p_new_status,
            'full_name', p_full_name,
            'verified_at', CASE WHEN p_new_status = 'APPROVED' THEN NOW() ELSE NULL END
        ),
        jsonb_build_object('manual_verification', true)
    );
    
    RETURN TRUE;
END;
$$;
GRANT EXECUTE ON FUNCTION admin_manual_verification(UUID, "ProfileStatus", TEXT, TEXT) TO authenticated;

-- Reset user verification status (admin only)
CREATE OR REPLACE FUNCTION reset_user_verification(p_user_id UUID)
RETURNS BOOLEAN LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    caller_role TEXT;
BEGIN
    -- Check if caller is admin
    SELECT raw_user_meta_data->>'role' INTO caller_role
    FROM auth.users
    WHERE auth.users.id = auth.uid();

    IF caller_role != 'admin' THEN
        RAISE EXCEPTION 'Only admins can reset user verification status.';
    END IF;

    -- Reset verification status and clear verification data
    UPDATE public.user_profiles
    SET 
        verification_status = 'NOT_SUBMITTED',
        full_name = NULL,
        supporting_documents = NULL,
        admin_feedback = NULL,
        verified_at = NULL,
        updated_at = NOW()
    WHERE user_id = p_user_id;
    
    RETURN FOUND;
END;
$$;
GRANT EXECUTE ON FUNCTION reset_user_verification(UUID) TO authenticated;

-- Get user activity summary (admin only)
CREATE OR REPLACE FUNCTION get_user_activity_summary(p_user_id UUID)
RETURNS TABLE (
    total_cards BIGINT,
    published_cards BIGINT,
    total_batches BIGINT,
    total_issued_cards BIGINT,
    activated_cards BIGINT,
    total_print_requests BIGINT,
    completed_print_requests BIGINT,
    last_card_created TIMESTAMPTZ,
    last_batch_created TIMESTAMPTZ,
    last_print_request TIMESTAMPTZ
) LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    caller_role TEXT;
BEGIN
    -- Check if caller is admin
    SELECT raw_user_meta_data->>'role' INTO caller_role
    FROM auth.users
    WHERE auth.users.id = auth.uid();

    IF caller_role != 'admin' THEN
        RAISE EXCEPTION 'Only admins can view user activity summaries.';
    END IF;

    RETURN QUERY
    SELECT 
        COALESCE(card_stats.total_cards, 0) as total_cards,
        COALESCE(card_stats.published_cards, 0) as published_cards,
        COALESCE(batch_stats.total_batches, 0) as total_batches,
        COALESCE(issued_stats.total_issued, 0) as total_issued_cards,
        COALESCE(issued_stats.activated, 0) as activated_cards,
        COALESCE(print_stats.total_requests, 0) as total_print_requests,
        COALESCE(print_stats.completed, 0) as completed_print_requests,
        card_stats.last_created as last_card_created,
        batch_stats.last_created as last_batch_created,
        print_stats.last_requested as last_print_request
    FROM (
        SELECT 
            COUNT(*) as total_cards,
            COUNT(*) FILTER (WHERE published = true) as published_cards,
            MAX(created_at) as last_created
        FROM cards
        WHERE user_id = p_user_id
    ) card_stats
    CROSS JOIN (
        SELECT 
            COUNT(cb.*) as total_batches,
            MAX(cb.created_at) as last_created
        FROM cards c
        LEFT JOIN card_batches cb ON c.id = cb.card_id
        WHERE c.user_id = p_user_id
    ) batch_stats
    CROSS JOIN (
        SELECT 
            COUNT(ic.*) as total_issued,
            COUNT(ic.*) FILTER (WHERE ic.active = true) as activated
        FROM cards c
        LEFT JOIN issue_cards ic ON c.id = ic.card_id
        WHERE c.user_id = p_user_id
    ) issued_stats
    CROSS JOIN (
        SELECT 
            COUNT(pr.*) as total_requests,
            COUNT(pr.*) FILTER (WHERE pr.status = 'COMPLETED') as completed,
            MAX(pr.requested_at) as last_requested
        FROM cards c
        LEFT JOIN card_batches cb ON c.id = cb.card_id
        LEFT JOIN print_requests pr ON cb.id = pr.batch_id
        WHERE c.user_id = p_user_id
    ) print_stats;
END;
$$;
GRANT EXECUTE ON FUNCTION get_user_activity_summary(UUID) TO authenticated;

-- ===============================
-- ADMIN FEEDBACK HISTORY MANAGEMENT FUNCTIONS
-- ===============================

-- Create or update admin feedback with full history tracking
CREATE OR REPLACE FUNCTION create_or_update_admin_feedback(
    p_target_entity_type TEXT,
    p_target_entity_id UUID,
    p_target_user_id UUID,
    p_feedback_type TEXT,
    p_content TEXT,
    p_action_context JSONB DEFAULT NULL
)
RETURNS UUID LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    caller_role TEXT;
    current_feedback_id UUID;
    new_feedback_id UUID;
    current_version INTEGER := 1;
BEGIN
    -- Check if caller is admin
    SELECT raw_user_meta_data->>'role' INTO caller_role
    FROM auth.users
    WHERE auth.users.id = auth.uid();

    IF caller_role != 'admin' THEN
        RAISE EXCEPTION 'Only admins can manage feedback.';
    END IF;

    -- Validate feedback type
    IF p_feedback_type NOT IN ('verification_feedback', 'print_notes', 'role_change_reason', 'admin_notes') THEN
        RAISE EXCEPTION 'Invalid feedback type.';
    END IF;

    -- Check if there's existing current feedback
    SELECT id, version_number INTO current_feedback_id, current_version
    FROM admin_feedback_history
    WHERE target_entity_type = p_target_entity_type
    AND target_entity_id = p_target_entity_id
    AND feedback_type = p_feedback_type
    AND is_current = TRUE;

    -- If existing feedback found, mark it as not current
    IF current_feedback_id IS NOT NULL THEN
        UPDATE admin_feedback_history
        SET is_current = FALSE
        WHERE id = current_feedback_id;
        
        current_version := current_version + 1;
    END IF;

    -- Create new feedback entry
    INSERT INTO admin_feedback_history (
        admin_user_id,
        target_user_id,
        target_entity_type,
        target_entity_id,
        feedback_type,
        content,
        version_number,
        parent_feedback_id,
        action_context,
        is_current
    ) VALUES (
        auth.uid(),
        p_target_user_id,
        p_target_entity_type,
        p_target_entity_id,
        p_feedback_type,
        p_content,
        current_version,
        current_feedback_id, -- Links to previous version
        p_action_context,
        TRUE
    ) RETURNING id INTO new_feedback_id;

    -- Update the legacy fields for backward compatibility
    IF p_feedback_type = 'verification_feedback' THEN
        UPDATE user_profiles
        SET admin_feedback = p_content,
            updated_at = NOW()
        WHERE user_id = p_target_user_id;
    ELSIF p_feedback_type = 'print_notes' THEN
        UPDATE print_requests
        SET admin_notes = p_content,
            updated_at = NOW()
        WHERE id = p_target_entity_id;
    END IF;

    RETURN new_feedback_id;
END;
$$;
GRANT EXECUTE ON FUNCTION create_or_update_admin_feedback(TEXT, UUID, UUID, TEXT, TEXT, JSONB) TO authenticated;

-- Get current admin feedback for an entity
CREATE OR REPLACE FUNCTION get_current_admin_feedback(
    p_target_entity_type TEXT,
    p_target_entity_id UUID,
    p_feedback_type TEXT
)
RETURNS TABLE (
    id UUID,
    admin_user_id UUID,
    admin_email TEXT,
    content TEXT,
    version_number INTEGER,
    action_context JSONB,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ
) LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    caller_role TEXT;
BEGIN
    -- Check if caller is admin or the target user (for verification feedback)
    SELECT raw_user_meta_data->>'role' INTO caller_role
    FROM auth.users
    WHERE auth.users.id = auth.uid();

    IF caller_role != 'admin' AND p_feedback_type = 'verification_feedback' THEN
        -- Allow users to see their own verification feedback
        IF NOT EXISTS (
            SELECT 1 FROM admin_feedback_history afh
            WHERE afh.target_entity_type = p_target_entity_type
            AND afh.target_entity_id = p_target_entity_id
            AND afh.feedback_type = p_feedback_type
            AND afh.target_user_id = auth.uid()
        ) THEN
            RAISE EXCEPTION 'Access denied.';
        END IF;
    ELSIF caller_role != 'admin' THEN
        RAISE EXCEPTION 'Only admins can access this feedback.';
    END IF;

    RETURN QUERY
    SELECT 
        afh.id,
        afh.admin_user_id,
        au.email::TEXT as admin_email,
        afh.content,
        afh.version_number,
        afh.action_context,
        afh.created_at,
        afh.updated_at
    FROM admin_feedback_history afh
    JOIN auth.users au ON afh.admin_user_id = au.id
    WHERE afh.target_entity_type = p_target_entity_type
    AND afh.target_entity_id = p_target_entity_id
    AND afh.feedback_type = p_feedback_type
    AND afh.is_current = TRUE;
END;
$$;
GRANT EXECUTE ON FUNCTION get_current_admin_feedback(TEXT, UUID, TEXT) TO authenticated;

-- Get full feedback history for an entity
CREATE OR REPLACE FUNCTION get_admin_feedback_history(
    p_target_entity_type TEXT,
    p_target_entity_id UUID,
    p_feedback_type TEXT
)
RETURNS TABLE (
    id UUID,
    admin_user_id UUID,
    admin_email TEXT,
    content TEXT,
    version_number INTEGER,
    is_current BOOLEAN,
    action_context JSONB,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ
) LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    caller_role TEXT;
BEGIN
    -- Check if caller is admin
    SELECT raw_user_meta_data->>'role' INTO caller_role
    FROM auth.users
    WHERE auth.users.id = auth.uid();

    IF caller_role != 'admin' THEN
        RAISE EXCEPTION 'Only admins can access feedback history.';
    END IF;

    RETURN QUERY
    SELECT 
        afh.id,
        afh.admin_user_id,
        au.email::TEXT as admin_email,
        afh.content,
        afh.version_number,
        afh.is_current,
        afh.action_context,
        afh.created_at,
        afh.updated_at
    FROM admin_feedback_history afh
    JOIN auth.users au ON afh.admin_user_id = au.id
    WHERE afh.target_entity_type = p_target_entity_type
    AND afh.target_entity_id = p_target_entity_id
    AND afh.feedback_type = p_feedback_type
    ORDER BY afh.version_number DESC, afh.created_at DESC;
END;
$$;
GRANT EXECUTE ON FUNCTION get_admin_feedback_history(TEXT, UUID, TEXT) TO authenticated;

-- Get all feedback for a user (verification + role changes)
CREATE OR REPLACE FUNCTION get_user_feedback_summary(
    p_target_user_id UUID
)
RETURNS TABLE (
    feedback_type TEXT,
    content TEXT,
    admin_email TEXT,
    version_number INTEGER,
    action_context JSONB,
    created_at TIMESTAMPTZ,
    is_current BOOLEAN
) LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    caller_role TEXT;
BEGIN
    -- Check if caller is admin or the target user
    SELECT raw_user_meta_data->>'role' INTO caller_role
    FROM auth.users
    WHERE auth.users.id = auth.uid();

    IF caller_role != 'admin' AND auth.uid() != p_target_user_id THEN
        RAISE EXCEPTION 'Access denied.';
    END IF;

    RETURN QUERY
    SELECT 
        afh.feedback_type,
        afh.content,
        au.email::TEXT as admin_email,
        afh.version_number,
        afh.action_context,
        afh.created_at,
        afh.is_current
    FROM admin_feedback_history afh
    JOIN auth.users au ON afh.admin_user_id = au.id
    WHERE afh.target_user_id = p_target_user_id
    ORDER BY afh.created_at DESC;
END;
$$;
GRANT EXECUTE ON FUNCTION get_user_feedback_summary(UUID) TO authenticated;

-- Admin function to waive batch payment and generate cards
CREATE OR REPLACE FUNCTION admin_waive_batch_payment(
    p_batch_id UUID,
    p_waiver_reason TEXT
) RETURNS UUID LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    caller_role TEXT;
    v_batch_record RECORD;
    i INTEGER;
BEGIN
    -- Check if caller is admin
    SELECT raw_user_meta_data->>'role' INTO caller_role
    FROM auth.users
    WHERE auth.users.id = auth.uid();

    IF caller_role != 'admin' THEN
        RAISE EXCEPTION 'Only admins can waive batch payments.';
    END IF;

    -- Get batch information
    SELECT * INTO v_batch_record
    FROM card_batches
    WHERE id = p_batch_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Batch not found.';
    END IF;
    
    -- Check if payment is already completed or waived
    IF v_batch_record.payment_completed = TRUE THEN
        RAISE EXCEPTION 'Payment for this batch has already been completed.';
    END IF;
    
    IF v_batch_record.payment_waived = TRUE THEN
        RAISE EXCEPTION 'Payment for this batch has already been waived.';
    END IF;
    
    IF v_batch_record.cards_generated = TRUE THEN
        RAISE EXCEPTION 'Cards for this batch have already been generated.';
    END IF;
    
    -- Update batch with waiver information
    UPDATE card_batches 
    SET 
        payment_waived = TRUE,
        payment_waived_by = auth.uid(),
        payment_waived_at = NOW(),
        payment_waiver_reason = p_waiver_reason,
        cards_generated = TRUE,
        cards_generated_at = NOW(),
        updated_at = NOW()
    WHERE id = p_batch_id;
    
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

    -- Log the waiver action in audit table
    INSERT INTO admin_audit_log (
        admin_user_id,
        target_user_id,
        action_type,
        reason,
        new_values,
        action_details
    ) VALUES (
        auth.uid(),
        v_batch_record.created_by,
        'BATCH_PAYMENT_WAIVER',
        p_waiver_reason,
        jsonb_build_object(
            'batch_id', p_batch_id,
            'cards_count', v_batch_record.cards_count,
            'payment_amount_waived_cents', v_batch_record.payment_amount_cents
        ),
        jsonb_build_object('batch_name', v_batch_record.batch_name)
    );
    
    RETURN p_batch_id;
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
    
    RETURN p_batch_id;
END;
$$;

-- Admin function to get all batches requiring payment or attention
CREATE OR REPLACE FUNCTION get_admin_batches_requiring_attention()
RETURNS TABLE (
    id UUID,
    card_id UUID,
    card_name TEXT,
    user_id UUID,
    user_email TEXT,
    batch_name TEXT,
    batch_number INTEGER,
    cards_count INTEGER,
    payment_amount_cents INTEGER,
    payment_required BOOLEAN,
    payment_completed BOOLEAN,
    payment_waived BOOLEAN,
    cards_generated BOOLEAN,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ
) LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    caller_role TEXT;
BEGIN
    -- Check if caller is admin
    SELECT raw_user_meta_data->>'role' INTO caller_role
    FROM auth.users
    WHERE auth.users.id = auth.uid();

    IF caller_role != 'admin' THEN
        RAISE EXCEPTION 'Only admins can view batch attention list.';
    END IF;

    RETURN QUERY
    SELECT 
        cb.id,
        cb.card_id,
        c.name as card_name,
        c.user_id,
        au.email::TEXT as user_email,
        cb.batch_name,
        cb.batch_number,
        cb.cards_count,
        cb.payment_amount_cents,
        cb.payment_required,
        cb.payment_completed,
        cb.payment_waived,
        cb.cards_generated,
        cb.created_at,
        cb.updated_at
    FROM card_batches cb
    JOIN cards c ON cb.card_id = c.id
    JOIN auth.users au ON c.user_id = au.id
    WHERE 
        cb.payment_required = TRUE 
        AND cb.payment_completed = FALSE 
        AND cb.payment_waived = FALSE
        AND cb.cards_generated = FALSE
    ORDER BY cb.created_at ASC;
END;
$$;
GRANT EXECUTE ON FUNCTION get_admin_batches_requiring_attention() TO authenticated;

-- Admin function to waive batch payment and generate cards (GRANT already included above)
GRANT EXECUTE ON FUNCTION admin_waive_batch_payment(UUID, TEXT) TO authenticated;

-- Generate cards for a paid or waived batch (GRANT already included above) 
GRANT EXECUTE ON FUNCTION generate_batch_cards(UUID) TO authenticated;

-- Grant execute permission for the mobile preview function
GRANT EXECUTE ON FUNCTION get_sample_issued_card_for_preview(UUID) TO authenticated;

-- Grant execute permission for the new preview access function
GRANT EXECUTE ON FUNCTION get_card_preview_access(UUID) TO authenticated;

-- ===============================
-- SHIPPING ADDRESS MANAGEMENT FUNCTIONS
-- ===============================

-- Get all shipping addresses for the current user
CREATE OR REPLACE FUNCTION get_user_shipping_addresses()
RETURNS TABLE (
    id UUID,
    user_id UUID,
    label TEXT,
    recipient_name TEXT,
    address_line1 TEXT,
    address_line2 TEXT,
    city TEXT,
    state_province TEXT,
    postal_code TEXT,
    country TEXT,
    phone TEXT,
    is_default BOOLEAN,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ
) LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
    RETURN QUERY
    SELECT 
        sa.id,
        sa.user_id,
        sa.label,
        sa.recipient_name,
        sa.address_line1,
        sa.address_line2,
        sa.city,
        sa.state_province,
        sa.postal_code,
        sa.country,
        sa.phone,
        sa.is_default,
        sa.created_at,
        sa.updated_at
    FROM shipping_addresses sa
    WHERE sa.user_id = auth.uid()
    ORDER BY sa.is_default DESC, sa.created_at DESC;
END;
$$;
GRANT EXECUTE ON FUNCTION get_user_shipping_addresses() TO authenticated;

-- Create a new shipping address
CREATE OR REPLACE FUNCTION create_shipping_address(
    p_label TEXT,
    p_recipient_name TEXT,
    p_address_line1 TEXT,
    p_city TEXT,
    p_state_province TEXT,
    p_postal_code TEXT,
    p_country TEXT,
    p_address_line2 TEXT DEFAULT NULL,
    p_phone TEXT DEFAULT NULL,
    p_is_default BOOLEAN DEFAULT FALSE
) RETURNS UUID LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_address_id UUID;
    v_user_id UUID := auth.uid();
BEGIN
    -- If this is set as default, remove default from other addresses
    IF p_is_default = TRUE THEN
        UPDATE shipping_addresses 
        SET is_default = FALSE 
        WHERE user_id = v_user_id;
    END IF;
    
    -- If this is the user's first address, make it default
    IF NOT EXISTS (SELECT 1 FROM shipping_addresses WHERE user_id = v_user_id) THEN
        p_is_default := TRUE;
    END IF;
    
    INSERT INTO shipping_addresses (
        user_id,
        label,
        recipient_name,
        address_line1,
        address_line2,
        city,
        state_province,
        postal_code,
        country,
        phone,
        is_default
    ) VALUES (
        v_user_id,
        p_label,
        p_recipient_name,
        p_address_line1,
        p_address_line2,
        p_city,
        p_state_province,
        p_postal_code,
        p_country,
        p_phone,
        p_is_default
    )
    RETURNING id INTO v_address_id;
    
    RETURN v_address_id;
END;
$$;
GRANT EXECUTE ON FUNCTION create_shipping_address(TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, BOOLEAN) TO authenticated;

-- Update an existing shipping address
CREATE OR REPLACE FUNCTION update_shipping_address(
    p_address_id UUID,
    p_label TEXT DEFAULT NULL,
    p_recipient_name TEXT DEFAULT NULL,
    p_address_line1 TEXT DEFAULT NULL,
    p_address_line2 TEXT DEFAULT NULL,
    p_city TEXT DEFAULT NULL,
    p_state_province TEXT DEFAULT NULL,
    p_postal_code TEXT DEFAULT NULL,
    p_country TEXT DEFAULT NULL,
    p_phone TEXT DEFAULT NULL,
    p_is_default BOOLEAN DEFAULT NULL
) RETURNS BOOLEAN LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_current_user_id UUID;
BEGIN
    -- Check if the address belongs to the current user
    SELECT user_id INTO v_current_user_id
    FROM shipping_addresses
    WHERE id = p_address_id;
    
    IF v_current_user_id IS NULL THEN
        RAISE EXCEPTION 'Shipping address not found.';
    END IF;
    
    IF v_current_user_id != v_user_id THEN
        RAISE EXCEPTION 'Not authorized to update this shipping address.';
    END IF;
    
    -- If setting as default, remove default from other addresses
    IF p_is_default = TRUE THEN
        UPDATE shipping_addresses 
        SET is_default = FALSE 
        WHERE user_id = v_user_id AND id != p_address_id;
    END IF;
    
    UPDATE shipping_addresses
    SET 
        label = COALESCE(p_label, label),
        recipient_name = COALESCE(p_recipient_name, recipient_name),
        address_line1 = COALESCE(p_address_line1, address_line1),
        address_line2 = COALESCE(p_address_line2, address_line2),
        city = COALESCE(p_city, city),
        state_province = COALESCE(p_state_province, state_province),
        postal_code = COALESCE(p_postal_code, postal_code),
        country = COALESCE(p_country, country),
        phone = COALESCE(p_phone, phone),
        is_default = COALESCE(p_is_default, is_default),
        updated_at = NOW()
    WHERE id = p_address_id;
    
    RETURN FOUND;
END;
$$;
GRANT EXECUTE ON FUNCTION update_shipping_address(UUID, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, BOOLEAN) TO authenticated;

-- Delete a shipping address
CREATE OR REPLACE FUNCTION delete_shipping_address(p_address_id UUID)
RETURNS BOOLEAN LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_current_user_id UUID;
    v_is_default BOOLEAN;
    v_replacement_address_id UUID;
BEGIN
    -- Check if the address belongs to the current user
    SELECT user_id, is_default INTO v_current_user_id, v_is_default
    FROM shipping_addresses
    WHERE id = p_address_id;
    
    IF v_current_user_id IS NULL THEN
        RAISE EXCEPTION 'Shipping address not found.';
    END IF;
    
    IF v_current_user_id != v_user_id THEN
        RAISE EXCEPTION 'Not authorized to delete this shipping address.';
    END IF;
    
    -- Delete the address
    DELETE FROM shipping_addresses WHERE id = p_address_id;
    
    -- If we deleted the default address, set another one as default
    IF v_is_default = TRUE THEN
        SELECT id INTO v_replacement_address_id
        FROM shipping_addresses 
        WHERE user_id = v_user_id 
        ORDER BY created_at ASC 
        LIMIT 1;
        
        IF v_replacement_address_id IS NOT NULL THEN
            UPDATE shipping_addresses 
            SET is_default = TRUE 
            WHERE id = v_replacement_address_id;
        END IF;
    END IF;
    
    RETURN FOUND;
END;
$$;
GRANT EXECUTE ON FUNCTION delete_shipping_address(UUID) TO authenticated;

-- Set an address as default
CREATE OR REPLACE FUNCTION set_default_shipping_address(p_address_id UUID)
RETURNS BOOLEAN LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_current_user_id UUID;
BEGIN
    -- Check if the address belongs to the current user
    SELECT user_id INTO v_current_user_id
    FROM shipping_addresses
    WHERE id = p_address_id;
    
    IF v_current_user_id IS NULL THEN
        RAISE EXCEPTION 'Shipping address not found.';
    END IF;
    
    IF v_current_user_id != v_user_id THEN
        RAISE EXCEPTION 'Not authorized to modify this shipping address.';
    END IF;
    
    -- Remove default from all addresses for this user
    UPDATE shipping_addresses 
    SET is_default = FALSE 
    WHERE user_id = v_user_id;
    
    -- Set the specified address as default
    UPDATE shipping_addresses 
    SET is_default = TRUE 
    WHERE id = p_address_id;
    
    RETURN FOUND;
END;
$$;
GRANT EXECUTE ON FUNCTION set_default_shipping_address(UUID) TO authenticated;

-- Get default shipping address for the current user
CREATE OR REPLACE FUNCTION get_default_shipping_address()
RETURNS TABLE (
    id UUID,
    user_id UUID,
    label TEXT,
    recipient_name TEXT,
    address_line1 TEXT,
    address_line2 TEXT,
    city TEXT,
    state_province TEXT,
    postal_code TEXT,
    country TEXT,
    phone TEXT,
    is_default BOOLEAN,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ
) LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
    RETURN QUERY
    SELECT 
        sa.id,
        sa.user_id,
        sa.label,
        sa.recipient_name,
        sa.address_line1,
        sa.address_line2,
        sa.city,
        sa.state_province,
        sa.postal_code,
        sa.country,
        sa.phone,
        sa.is_default,
        sa.created_at,
        sa.updated_at
    FROM shipping_addresses sa
    WHERE sa.user_id = auth.uid() AND sa.is_default = TRUE
    LIMIT 1;
END;
$$;
GRANT EXECUTE ON FUNCTION get_default_shipping_address() TO authenticated;

-- Format shipping address for display/printing
CREATE OR REPLACE FUNCTION format_shipping_address(p_address_id UUID)
RETURNS TEXT LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_current_user_id UUID;
    v_formatted_address TEXT;
    v_address RECORD;
BEGIN
    -- Check if the address belongs to the current user
    SELECT user_id INTO v_current_user_id
    FROM shipping_addresses
    WHERE id = p_address_id;
    
    IF v_current_user_id IS NULL THEN
        RAISE EXCEPTION 'Shipping address not found.';
    END IF;
    
    IF v_current_user_id != v_user_id THEN
        RAISE EXCEPTION 'Not authorized to access this shipping address.';
    END IF;
    
    -- Get the address details
    SELECT * INTO v_address
    FROM shipping_addresses
    WHERE id = p_address_id;
    
    -- Format the address
    v_formatted_address := v_address.recipient_name || E'\n' ||
                          v_address.address_line1;
    
    IF v_address.address_line2 IS NOT NULL AND v_address.address_line2 != '' THEN
        v_formatted_address := v_formatted_address || E'\n' || v_address.address_line2;
    END IF;
    
    v_formatted_address := v_formatted_address || E'\n' ||
                          v_address.city || ', ' || v_address.state_province || ' ' || v_address.postal_code || E'\n' ||
                          v_address.country;
    
    IF v_address.phone IS NOT NULL AND v_address.phone != '' THEN
        v_formatted_address := v_formatted_address || E'\n' || 'Phone: ' || v_address.phone;
    END IF;
    
    RETURN v_formatted_address;
END;
$$;
GRANT EXECUTE ON FUNCTION format_shipping_address(UUID) TO authenticated;

-- ===============================
-- USER-LEVEL ISSUED CARDS FUNCTIONS (across all cards)
-- ===============================

-- Get admin audit logs with filtering
CREATE OR REPLACE FUNCTION get_admin_audit_logs(
    p_action_type TEXT DEFAULT NULL,
    p_admin_user_id UUID DEFAULT NULL,
    p_target_user_id UUID DEFAULT NULL,
    p_start_date TIMESTAMPTZ DEFAULT NULL,
    p_end_date TIMESTAMPTZ DEFAULT NULL,
    p_limit INTEGER DEFAULT 50,
    p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
    id UUID,
    admin_user_id UUID,
    admin_email TEXT,
    target_user_id UUID,
    target_user_email TEXT,
    action_type TEXT,
    reason TEXT,
    old_values JSONB,
    new_values JSONB,
    action_details JSONB,
    created_at TIMESTAMPTZ
) LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    caller_role TEXT;
BEGIN
    -- Check if caller is admin
    SELECT raw_user_meta_data->>'role' INTO caller_role
    FROM auth.users
    WHERE auth.users.id = auth.uid();

    IF caller_role != 'admin' THEN
        RAISE EXCEPTION 'Only admins can view audit logs.';
    END IF;

    RETURN QUERY
    SELECT 
        aal.id,
        aal.admin_user_id,
        admin_user.email::TEXT as admin_email,
        aal.target_user_id,
        target_user.email::TEXT as target_user_email,
        aal.action_type,
        aal.reason,
        aal.old_values,
        aal.new_values,
        aal.action_details,
        aal.created_at
    FROM admin_audit_log aal
    LEFT JOIN auth.users admin_user ON admin_user.id = aal.admin_user_id
    LEFT JOIN auth.users target_user ON target_user.id = aal.target_user_id
    WHERE (p_action_type IS NULL OR aal.action_type = p_action_type)
    AND (p_admin_user_id IS NULL OR aal.admin_user_id = p_admin_user_id)
    AND (p_target_user_id IS NULL OR aal.target_user_id = p_target_user_id)
    AND (p_start_date IS NULL OR aal.created_at >= p_start_date)
    AND (p_end_date IS NULL OR aal.created_at <= p_end_date)
    ORDER BY aal.created_at DESC
    LIMIT p_limit
    OFFSET p_offset;
END;
$$;

GRANT EXECUTE ON FUNCTION get_admin_audit_logs(TEXT, UUID, UUID, TIMESTAMPTZ, TIMESTAMPTZ, INTEGER, INTEGER) TO authenticated;

-- Get count of admin audit logs with filtering
CREATE OR REPLACE FUNCTION get_admin_audit_logs_count(
    p_action_type TEXT DEFAULT NULL,
    p_admin_user_id UUID DEFAULT NULL,
    p_target_user_id UUID DEFAULT NULL,
    p_start_date TIMESTAMPTZ DEFAULT NULL,
    p_end_date TIMESTAMPTZ DEFAULT NULL
)
RETURNS INTEGER LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    caller_role TEXT;
    v_count INTEGER;
BEGIN
    -- Check if caller is admin
    SELECT raw_user_meta_data->>'role' INTO caller_role
    FROM auth.users
    WHERE auth.users.id = auth.uid();

    IF caller_role != 'admin' THEN
        RAISE EXCEPTION 'Only admins can view audit logs.';
    END IF;

    SELECT COUNT(*)::INTEGER INTO v_count
    FROM admin_audit_log aal
    WHERE (p_action_type IS NULL OR aal.action_type = p_action_type)
    AND (p_admin_user_id IS NULL OR aal.admin_user_id = p_admin_user_id)
    AND (p_target_user_id IS NULL OR aal.target_user_id = p_target_user_id)
    AND (p_start_date IS NULL OR aal.created_at >= p_start_date)
    AND (p_end_date IS NULL OR aal.created_at <= p_end_date);

    RETURN v_count;
END;
$$;

GRANT EXECUTE ON FUNCTION get_admin_audit_logs_count(TEXT, UUID, UUID, TIMESTAMPTZ, TIMESTAMPTZ) TO authenticated;