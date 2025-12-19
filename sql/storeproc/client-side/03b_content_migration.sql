-- =================================================================
-- CONTENT ITEM MIGRATION FUNCTIONS
-- Functions for migrating content between flat and grouped modes
-- =================================================================

-- Migrate content from flat mode to grouped mode
-- Creates a default category and moves all top-level items under it
CREATE OR REPLACE FUNCTION migrate_content_to_grouped(
    p_card_id UUID,
    p_default_category_name TEXT DEFAULT 'Default Category'
) RETURNS JSON LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_user_id UUID;
    v_category_id UUID;
    v_items_moved INTEGER := 0;
BEGIN
    -- Check if the user owns the card
    SELECT user_id INTO v_user_id
    FROM cards
    WHERE id = p_card_id;
    
    IF v_user_id != auth.uid() THEN
        RAISE EXCEPTION 'Not authorized to migrate content for this card';
    END IF;
    
    -- Count top-level items (potential items to move)
    SELECT COUNT(*) INTO v_items_moved
    FROM content_items
    WHERE card_id = p_card_id AND parent_id IS NULL;
    
    -- If no items to migrate, return early
    IF v_items_moved = 0 THEN
        RETURN json_build_object(
            'success', true,
            'message', 'No items to migrate',
            'category_id', NULL,
            'items_moved', 0
        );
    END IF;
    
    -- Create the default category
    INSERT INTO content_items (
        card_id,
        parent_id,
        name,
        content,
        sort_order
    ) VALUES (
        p_card_id,
        NULL,
        p_default_category_name,
        '',
        1
    )
    RETURNING id INTO v_category_id;
    
    -- Move all existing top-level items under the new category
    -- (except the category we just created)
    UPDATE content_items
    SET 
        parent_id = v_category_id,
        updated_at = now()
    WHERE card_id = p_card_id 
    AND parent_id IS NULL 
    AND id != v_category_id;
    
    -- Re-number sort orders for moved items
    WITH numbered AS (
        SELECT id, ROW_NUMBER() OVER (ORDER BY sort_order, created_at) as new_order
        FROM content_items
        WHERE card_id = p_card_id AND parent_id = v_category_id
    )
    UPDATE content_items ci
    SET sort_order = numbered.new_order
    FROM numbered
    WHERE ci.id = numbered.id;
    
    -- Log operation
    PERFORM log_operation(format('Migrated %s items to grouped mode with category: %s', v_items_moved, p_default_category_name));
    
    RETURN json_build_object(
        'success', true,
        'message', format('Migrated %s items to grouped mode', v_items_moved),
        'category_id', v_category_id,
        'items_moved', v_items_moved
    );
END;
$$;
GRANT EXECUTE ON FUNCTION migrate_content_to_grouped(UUID, TEXT) TO authenticated;

-- Migrate content from grouped mode to flat mode
-- Moves all child items to top level, optionally removes empty categories
CREATE OR REPLACE FUNCTION migrate_content_to_flat(
    p_card_id UUID,
    p_remove_empty_categories BOOLEAN DEFAULT true
) RETURNS JSON LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_user_id UUID;
    v_items_moved INTEGER := 0;
    v_categories_removed INTEGER := 0;
BEGIN
    -- Check if the user owns the card
    SELECT user_id INTO v_user_id
    FROM cards
    WHERE id = p_card_id;
    
    IF v_user_id != auth.uid() THEN
        RAISE EXCEPTION 'Not authorized to migrate content for this card';
    END IF;
    
    -- Count items that will be moved (items with parent_id)
    SELECT COUNT(*) INTO v_items_moved
    FROM content_items
    WHERE card_id = p_card_id AND parent_id IS NOT NULL;
    
    -- Move all child items to top level
    UPDATE content_items
    SET 
        parent_id = NULL,
        updated_at = now()
    WHERE card_id = p_card_id AND parent_id IS NOT NULL;
    
    -- Optionally remove categories (items that had children but now are empty parents)
    -- We identify categories as items that have no content and were originally parents
    IF p_remove_empty_categories THEN
        -- Delete categories (items with empty content that don't have images)
        WITH deleted AS (
            DELETE FROM content_items
            WHERE card_id = p_card_id 
            AND parent_id IS NULL
            AND (content IS NULL OR content = '')
            AND image_url IS NULL
            RETURNING id
        )
        SELECT COUNT(*) INTO v_categories_removed FROM deleted;
    END IF;
    
    -- Re-number sort orders for all remaining top-level items
    WITH numbered AS (
        SELECT id, ROW_NUMBER() OVER (ORDER BY sort_order, created_at) as new_order
        FROM content_items
        WHERE card_id = p_card_id AND parent_id IS NULL
    )
    UPDATE content_items ci
    SET sort_order = numbered.new_order
    FROM numbered
    WHERE ci.id = numbered.id;
    
    -- Log operation
    PERFORM log_operation(format('Migrated to flat mode: %s items moved, %s categories removed', v_items_moved, v_categories_removed));
    
    RETURN json_build_object(
        'success', true,
        'message', format('Migrated to flat mode'),
        'items_moved', v_items_moved,
        'categories_removed', v_categories_removed
    );
END;
$$;
GRANT EXECUTE ON FUNCTION migrate_content_to_flat(UUID, BOOLEAN) TO authenticated;

-- Move a content item to a different parent (for cross-parent drag & drop)
-- new_parent_id can be NULL to move to top level
CREATE OR REPLACE FUNCTION move_content_item_to_parent(
    p_content_item_id UUID,
    p_new_parent_id UUID DEFAULT NULL,
    p_new_sort_order INTEGER DEFAULT NULL
) RETURNS JSON LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_user_id UUID;
    v_card_id UUID;
    v_old_parent_id UUID;
    v_next_sort_order INTEGER;
    v_item_name TEXT;
BEGIN
    -- Get content item details and check ownership
    SELECT c.user_id, ci.card_id, ci.parent_id, ci.name 
    INTO v_user_id, v_card_id, v_old_parent_id, v_item_name
    FROM content_items ci
    JOIN cards c ON ci.card_id = c.id
    WHERE ci.id = p_content_item_id;
    
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Content item not found';
    END IF;
    
    IF v_user_id != auth.uid() THEN
        RAISE EXCEPTION 'Not authorized to move this content item';
    END IF;
    
    -- Prevent moving to self
    IF p_content_item_id = p_new_parent_id THEN
        RAISE EXCEPTION 'Cannot move an item to itself';
    END IF;
    
    -- If new parent specified, verify it exists and belongs to the same card
    IF p_new_parent_id IS NOT NULL THEN
        IF NOT EXISTS (
            SELECT 1 FROM content_items 
            WHERE id = p_new_parent_id 
            AND card_id = v_card_id
            AND parent_id IS NULL  -- Parent must be a top-level item (category)
        ) THEN
            RAISE EXCEPTION 'New parent must be a top-level category in the same card';
        END IF;
    END IF;
    
    -- Prevent circular references (moving a parent under its own child)
    IF p_new_parent_id IS NOT NULL THEN
        IF EXISTS (
            WITH RECURSIVE descendants AS (
                SELECT id, parent_id FROM content_items WHERE id = p_content_item_id
                UNION ALL
                SELECT ci.id, ci.parent_id 
                FROM content_items ci
                JOIN descendants d ON ci.parent_id = d.id
            )
            SELECT 1 FROM descendants WHERE id = p_new_parent_id
        ) THEN
            RAISE EXCEPTION 'Cannot create circular reference';
        END IF;
    END IF;
    
    -- Calculate next sort order if not provided
    IF p_new_sort_order IS NULL THEN
        SELECT COALESCE(MAX(sort_order), 0) + 1 INTO v_next_sort_order
        FROM content_items
        WHERE card_id = v_card_id 
        AND (
            (p_new_parent_id IS NULL AND parent_id IS NULL) OR 
            (p_new_parent_id IS NOT NULL AND parent_id = p_new_parent_id)
        );
    ELSE
        v_next_sort_order := p_new_sort_order;
    END IF;
    
    -- Update the content item's parent and sort order
    UPDATE content_items
    SET 
        parent_id = p_new_parent_id,
        sort_order = v_next_sort_order,
        updated_at = now()
    WHERE id = p_content_item_id;
    
    -- Re-number sort orders in the old parent's children (if old parent existed)
    IF v_old_parent_id IS NOT NULL THEN
        WITH numbered AS (
            SELECT id, ROW_NUMBER() OVER (ORDER BY sort_order, created_at) as new_order
            FROM content_items
            WHERE card_id = v_card_id AND parent_id = v_old_parent_id
        )
        UPDATE content_items ci
        SET sort_order = numbered.new_order
        FROM numbered
        WHERE ci.id = numbered.id;
    END IF;
    
    -- Log operation
    PERFORM log_operation(format('Moved content item "%s" to new parent', v_item_name));
    
    RETURN json_build_object(
        'success', true,
        'message', 'Item moved successfully',
        'item_id', p_content_item_id,
        'old_parent_id', v_old_parent_id,
        'new_parent_id', p_new_parent_id,
        'new_sort_order', v_next_sort_order
    );
END;
$$;
GRANT EXECUTE ON FUNCTION move_content_item_to_parent(UUID, UUID, INTEGER) TO authenticated;

