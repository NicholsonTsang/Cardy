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

-- Get all cards for the current user (more secure)
CREATE FUNCTION get_user_cards()
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
) LANGUAGE plpgsql SECURITY INVOKER AS $$
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
CREATE FUNCTION create_card(
    p_name TEXT,
    p_description TEXT,
    p_image_urls TEXT[] DEFAULT ARRAY[]::TEXT[],
    p_conversation_ai_enabled BOOLEAN DEFAULT FALSE,
    p_ai_prompt TEXT DEFAULT '',
    p_published BOOLEAN DEFAULT FALSE,
    p_qr_code_position TEXT DEFAULT 'BR'
) RETURNS UUID LANGUAGE plpgsql SECURITY INVOKER AS $$
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
CREATE FUNCTION get_card_by_id(p_card_id UUID)
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
) LANGUAGE plpgsql SECURITY INVOKER AS $$
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
CREATE FUNCTION update_card(
    p_card_id UUID,
    p_name TEXT,
    p_description TEXT,
    p_image_urls TEXT[] DEFAULT NULL,
    p_conversation_ai_enabled BOOLEAN DEFAULT NULL,
    p_ai_prompt TEXT DEFAULT NULL,
    p_published BOOLEAN DEFAULT NULL,
    p_qr_code_position TEXT DEFAULT NULL
) RETURNS BOOLEAN LANGUAGE plpgsql SECURITY INVOKER AS $$
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
CREATE FUNCTION delete_card(p_card_id UUID)
RETURNS BOOLEAN LANGUAGE plpgsql SECURITY INVOKER AS $$
BEGIN
    DELETE FROM cards WHERE id = p_card_id AND user_id = auth.uid();
    RETURN FOUND;
END;
$$;

-- Get all content items for a card (updated with ordering)
CREATE FUNCTION get_card_content_items(p_card_id UUID)
RETURNS TABLE (
    id UUID,
    card_id UUID,
    parent_id UUID,
    name TEXT,
    content TEXT,
    image_urls TEXT[],
    conversation_ai_enabled BOOLEAN,
    ai_prompt TEXT,
    sort_order INTEGER,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ
) LANGUAGE plpgsql SECURITY INVOKER AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ci.id, 
        ci.card_id,
        ci.parent_id,
        ci.name, 
        ci.content, 
        ci.image_urls, 
        ci.conversation_ai_enabled,
        ci.ai_prompt,
        ci.sort_order,
        ci.created_at,
        ci.updated_at
    FROM content_items ci
    JOIN cards c ON ci.card_id = c.id
    WHERE ci.card_id = p_card_id AND c.user_id = auth.uid()
    ORDER BY 
        CASE WHEN ci.parent_id IS NULL THEN ci.sort_order ELSE 999999 END,
        ci.sort_order ASC,
        ci.created_at ASC;
END;
$$;

-- Get a content item by ID (updated with ordering)
CREATE FUNCTION get_content_item_by_id(p_content_item_id UUID)
RETURNS TABLE (
    id UUID,
    card_id UUID,
    parent_id UUID,
    name TEXT,
    content TEXT,
    image_urls TEXT[],
    conversation_ai_enabled BOOLEAN,
    ai_prompt TEXT,
    sort_order INTEGER,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ
) LANGUAGE plpgsql SECURITY INVOKER AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ci.id, 
        ci.card_id,
        ci.parent_id,
        ci.name, 
        ci.content, 
        ci.image_urls, 
        ci.conversation_ai_enabled,
        ci.ai_prompt,
        ci.sort_order,
        ci.created_at,
        ci.updated_at
    FROM content_items ci
    JOIN cards c ON ci.card_id = c.id
    WHERE ci.id = p_content_item_id AND c.user_id = auth.uid();
END;
$$;

-- Create a new content item (updated with ordering)
CREATE FUNCTION create_content_item(
    p_card_id UUID,
    p_name TEXT,
    p_parent_id UUID DEFAULT NULL,
    p_content TEXT DEFAULT '',
    p_image_urls TEXT[] DEFAULT ARRAY[]::TEXT[],
    p_conversation_ai_enabled BOOLEAN DEFAULT FALSE,
    p_ai_prompt TEXT DEFAULT ''
) RETURNS UUID LANGUAGE plpgsql SECURITY INVOKER AS $$
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
        conversation_ai_enabled,
        ai_prompt,
        sort_order
    ) VALUES (
        p_card_id,
        p_parent_id,
        p_name,
        p_content,
        p_image_urls,
        p_conversation_ai_enabled,
        p_ai_prompt,
        v_next_sort_order
    )
    RETURNING id INTO v_content_item_id;
    
    RETURN v_content_item_id;
END;
$$;

-- Update an existing content item (updated with ordering)
CREATE FUNCTION update_content_item(
    p_content_item_id UUID,
    p_name TEXT DEFAULT NULL,
    p_content TEXT DEFAULT NULL,
    p_image_urls TEXT[] DEFAULT NULL,
    p_conversation_ai_enabled BOOLEAN DEFAULT NULL,
    p_ai_prompt TEXT DEFAULT NULL
) RETURNS BOOLEAN LANGUAGE plpgsql SECURITY INVOKER AS $$
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
        conversation_ai_enabled = COALESCE(p_conversation_ai_enabled, conversation_ai_enabled),
        ai_prompt = COALESCE(p_ai_prompt, ai_prompt),
        updated_at = now()
    WHERE id = p_content_item_id;
    
    RETURN FOUND;
END;
$$;

-- Update content item order
CREATE FUNCTION update_content_item_order(
    p_content_item_id UUID,
    p_new_sort_order INTEGER
) RETURNS BOOLEAN LANGUAGE plpgsql SECURITY INVOKER AS $$
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
CREATE FUNCTION delete_content_item(p_content_item_id UUID)
RETURNS BOOLEAN LANGUAGE plpgsql SECURITY INVOKER AS $$
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
CREATE FUNCTION get_next_batch_number(p_card_id UUID)
RETURNS INTEGER LANGUAGE plpgsql SECURITY INVOKER AS $$
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
) RETURNS UUID LANGUAGE plpgsql SECURITY INVOKER AS $$
DECLARE
    v_batch_id UUID;
    v_batch_number INTEGER;
    v_batch_name TEXT;
    v_card_owner_id UUID;
    v_card_published BOOLEAN;
    i INTEGER;
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
    
    -- Create the batch
    INSERT INTO card_batches (
        card_id,
        batch_name,
        batch_number,
        cards_count,
        created_by -- This is auth.uid() from the user issuing the batch
    ) VALUES (
        p_card_id,
        v_batch_name,
        v_batch_number,
        p_quantity,
        auth.uid()
    )
    RETURNING id INTO v_batch_id;
    
    -- Create the issued cards
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
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ
) LANGUAGE plpgsql SECURITY INVOKER AS $$
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
        cb.created_at,
        cb.updated_at
    FROM card_batches cb
    LEFT JOIN issue_cards ic ON cb.id = ic.batch_id
    JOIN cards c ON cb.card_id = c.id
    WHERE cb.card_id = p_card_id AND c.user_id = auth.uid()
    GROUP BY cb.id, cb.card_id, cb.batch_name, cb.batch_number, cb.cards_count, cb.is_disabled, cb.created_at, cb.updated_at
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
) LANGUAGE plpgsql SECURITY INVOKER AS $$
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
CREATE FUNCTION toggle_card_batch_disabled_status(p_batch_id UUID, p_disable_status BOOLEAN)
RETURNS BOOLEAN LANGUAGE plpgsql SECURITY INVOKER AS $$
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
CREATE FUNCTION activate_issued_card(p_card_id UUID, p_activation_code TEXT)
RETURNS BOOLEAN LANGUAGE plpgsql SECURITY INVOKER AS $$
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
CREATE FUNCTION get_card_issuance_stats(p_card_id UUID)
RETURNS TABLE (
    total_issued BIGINT,
    total_activated BIGINT,
    activation_rate NUMERIC,
    total_batches BIGINT
) LANGUAGE plpgsql SECURITY INVOKER AS $$
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
CREATE FUNCTION request_card_printing(p_batch_id UUID, p_shipping_address TEXT)
RETURNS UUID LANGUAGE plpgsql SECURITY INVOKER AS $$
DECLARE
    v_print_request_id UUID;
    v_user_id UUID;
    v_batch_is_disabled BOOLEAN;
BEGIN
    -- Check if the user owns the card associated with the batch
    SELECT c.user_id, cb.is_disabled INTO v_user_id, v_batch_is_disabled
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

-- Get print requests for a batch
CREATE FUNCTION get_print_requests_for_batch(p_batch_id UUID)
RETURNS TABLE (
    id UUID,
    batch_id UUID,
    user_id UUID,
    status TEXT, -- "PrintRequestStatus"
    shipping_address TEXT,
    admin_notes TEXT,
    payment_details TEXT,
    requested_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ
) LANGUAGE plpgsql SECURITY INVOKER AS $$
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
        pr.payment_details,
        pr.requested_at,
        pr.updated_at
    FROM print_requests pr
    WHERE pr.batch_id = p_batch_id
    ORDER BY pr.requested_at DESC;
END;
$$;

-- Get public card content and activate if necessary
CREATE OR REPLACE FUNCTION get_public_card_content(p_issue_card_id UUID, p_activation_code TEXT)
RETURNS TABLE (
    card_name TEXT,
    card_description TEXT,
    card_image_urls TEXT[],
    content_item_id UUID,
    content_item_parent_id UUID,
    content_item_name TEXT,
    content_item_content TEXT,
    content_item_image_urls TEXT[],
    content_item_sort_order INTEGER,
    is_activated BOOLEAN
) LANGUAGE plpgsql SECURITY INVOKER AS $$
DECLARE
    v_card_design_id UUID;
    v_is_card_active BOOLEAN;
    v_activation_attempted BOOLEAN := FALSE;
BEGIN
    -- Check if the issued card exists and get its card_id (design_id) and current active status
    SELECT ic.card_id, ic.active INTO v_card_design_id, v_is_card_active
    FROM issue_cards ic
    WHERE ic.id = p_issue_card_id AND ic.activation_code = p_activation_code;

    IF NOT FOUND THEN
        -- If no card matches ID and activation code, return empty
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

    RETURN QUERY
    SELECT 
        c.name AS card_name,
        c.description AS card_description,
        c.image_urls AS card_image_urls,
        ci.id AS content_item_id,
        ci.parent_id AS content_item_parent_id,
        ci.name AS content_item_name,
        ci.content AS content_item_content,
        ci.image_urls AS content_item_image_urls,
        ci.sort_order AS content_item_sort_order,
        v_is_card_active AS is_activated -- Return the current/newly activated status
    FROM cards c
    LEFT JOIN content_items ci ON c.id = ci.card_id
    WHERE c.id = v_card_design_id AND c.published = TRUE -- Only show published cards
    ORDER BY 
        CASE WHEN ci.parent_id IS NULL THEN ci.sort_order ELSE 999999 END,
        ci.parent_id NULLS FIRST,
        ci.sort_order ASC,
        ci.created_at ASC;
END;
$$;