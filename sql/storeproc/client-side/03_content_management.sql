-- =================================================================
-- CONTENT ITEM MANAGEMENT FUNCTIONS
-- Functions for managing content items within cards
-- =================================================================

-- Get all content items for a card (updated with ordering)
CREATE OR REPLACE FUNCTION get_card_content_items(p_card_id UUID)
RETURNS TABLE (
    id UUID,
    card_id UUID,
    parent_id UUID,
    name TEXT,
    content TEXT,
    image_url TEXT,
    original_image_url TEXT,
    crop_parameters JSONB,
    ai_knowledge_base TEXT,
    sort_order INTEGER,
    translations JSONB,
    content_hash TEXT,
    last_content_update TIMESTAMPTZ,
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
        ci.image_url, 
        ci.original_image_url,
        ci.crop_parameters,
        ci.ai_knowledge_base,
        ci.sort_order,
        ci.translations,
        ci.content_hash,
        ci.last_content_update,
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
GRANT EXECUTE ON FUNCTION get_card_content_items(UUID) TO authenticated;

-- Get a content item by ID (updated with ordering)
CREATE OR REPLACE FUNCTION get_content_item_by_id(p_content_item_id UUID)
RETURNS TABLE (
    id UUID,
    card_id UUID,
    parent_id UUID,
    name TEXT,
    content TEXT,
    image_url TEXT,
    original_image_url TEXT,
    crop_parameters JSONB,
    ai_knowledge_base TEXT,
    sort_order INTEGER,
    translations JSONB,
    content_hash TEXT,
    last_content_update TIMESTAMPTZ,
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
        ci.image_url, 
        ci.original_image_url,
        ci.crop_parameters,
        ci.ai_knowledge_base,
        ci.sort_order,
        ci.translations,
        ci.content_hash,
        ci.last_content_update,
        ci.created_at,
        ci.updated_at
    FROM content_items ci
    JOIN cards c ON ci.card_id = c.id
    WHERE ci.id = p_content_item_id AND c.user_id = auth.uid();
END;
$$;
GRANT EXECUTE ON FUNCTION get_content_item_by_id(UUID) TO authenticated;

-- Create a new content item (updated with ordering)
CREATE OR REPLACE FUNCTION create_content_item(
    p_card_id UUID,
    p_name TEXT,
    p_parent_id UUID DEFAULT NULL,
    p_content TEXT DEFAULT '',
    p_image_url TEXT DEFAULT NULL,
    p_original_image_url TEXT DEFAULT NULL,
    p_crop_parameters JSONB DEFAULT NULL,
    p_ai_knowledge_base TEXT DEFAULT ''
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
        image_url,
        original_image_url,
        crop_parameters,
        ai_knowledge_base,
        sort_order
    ) VALUES (
        p_card_id,
        p_parent_id,
        p_name,
        p_content,
        p_image_url,
        p_original_image_url,
        p_crop_parameters,
        p_ai_knowledge_base,
        v_next_sort_order
    )
    RETURNING id INTO v_content_item_id;
    
    -- Log operation
    PERFORM log_operation(format('Created content item: %s', p_name));
    
    RETURN v_content_item_id;
END;
$$;

-- Update an existing content item (updated with ordering)
CREATE OR REPLACE FUNCTION update_content_item(
    p_content_item_id UUID,
    p_name TEXT DEFAULT NULL,
    p_content TEXT DEFAULT NULL,
    p_image_url TEXT DEFAULT NULL,
    p_original_image_url TEXT DEFAULT NULL,
    p_crop_parameters JSONB DEFAULT NULL,
    p_ai_knowledge_base TEXT DEFAULT NULL
) RETURNS BOOLEAN LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_user_id UUID;
    v_item_name TEXT;
BEGIN
    -- Check if the user owns the card that contains this content item
    SELECT c.user_id, ci.name INTO v_user_id, v_item_name
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
        image_url = COALESCE(p_image_url, image_url),
        original_image_url = COALESCE(p_original_image_url, original_image_url),
        crop_parameters = COALESCE(p_crop_parameters, crop_parameters),
        ai_knowledge_base = COALESCE(p_ai_knowledge_base, ai_knowledge_base),
        updated_at = now()
    WHERE id = p_content_item_id;
    
    -- Log operation
    PERFORM log_operation(format('Updated content item: %s', COALESCE(p_name, v_item_name)));
    
    RETURN TRUE;
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
    
    -- Log operation
    PERFORM log_operation(format('Reordered content item to position %s', p_new_sort_order));
    
    RETURN TRUE;
END;
$$;

-- Delete a content item
CREATE OR REPLACE FUNCTION delete_content_item(p_content_item_id UUID)
RETURNS BOOLEAN LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_user_id UUID;
    v_item_name TEXT;
BEGIN
    -- Check if the user owns the card that contains this content item
    SELECT c.user_id, ci.name INTO v_user_id, v_item_name
    FROM content_items ci
    JOIN cards c ON ci.card_id = c.id
    WHERE ci.id = p_content_item_id;
    
    IF v_user_id != auth.uid() THEN
        RAISE EXCEPTION 'Not authorized to delete this content item';
    END IF;
    
    -- Delete the content item (cascade will handle children)
    DELETE FROM content_items WHERE id = p_content_item_id;
    
    -- Log operation
    PERFORM log_operation(format('Deleted content item: %s', v_item_name));

    RETURN TRUE;
END;
$$; 