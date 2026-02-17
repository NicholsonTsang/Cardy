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
-- Modified to accept optional content_hash and translations for import
CREATE OR REPLACE FUNCTION create_content_item(
    p_card_id UUID,
    p_name TEXT,
    p_parent_id UUID DEFAULT NULL,
    p_content TEXT DEFAULT '',
    p_image_url TEXT DEFAULT NULL,
    p_original_image_url TEXT DEFAULT NULL,
    p_crop_parameters JSONB DEFAULT NULL,
    p_ai_knowledge_base TEXT DEFAULT '',
    p_content_hash TEXT DEFAULT NULL,  -- For import: preserve original hash
    p_translations JSONB DEFAULT NULL  -- For import: restore translations
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
    
    -- If parent_id is provided, check if it exists and belongs to the same project
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
        sort_order,
        content_hash,  -- May be NULL (trigger calculates) or provided (import)
        translations   -- May be NULL (normal) or provided (import)
    ) VALUES (
        p_card_id,
        p_parent_id,
        p_name,
        p_content,
        p_image_url,
        p_original_image_url,
        p_crop_parameters,
        p_ai_knowledge_base,
        v_next_sort_order,
        p_content_hash,  -- Trigger will calculate if NULL
        COALESCE(p_translations, '{}'::JSONB)  -- Default to empty object
    )
    RETURNING id INTO v_content_item_id;
    
    -- Log operation
    IF p_translations IS NOT NULL AND p_translations != '{}'::JSONB THEN
        PERFORM log_operation(format('Imported content item with translations: %s', p_name));
    ELSE
        PERFORM log_operation(format('Created content item: %s', p_name));
    END IF;
    
    RETURN v_content_item_id;
END;
$$;
GRANT EXECUTE ON FUNCTION create_content_item(UUID, TEXT, UUID, TEXT, TEXT, TEXT, JSONB, TEXT, TEXT, JSONB) TO authenticated;

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

-- =================================================================
-- BULK OPERATIONS (P0 Features - Platform Optimization Roadmap)
-- =================================================================

-- Bulk create content items
-- Purpose: Efficiently create multiple content items in a single transaction
-- Used by: Card duplication
CREATE OR REPLACE FUNCTION bulk_create_content_items(
  p_card_id UUID,
  p_items JSONB
) RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_item JSONB;
  v_result JSONB := '[]'::JSONB;
  v_new_id UUID;
  v_user_id UUID;
  v_max_sort_order INT;
BEGIN
  -- Get authenticated user
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  -- Verify user owns this card
  IF NOT EXISTS (
    SELECT 1 FROM cards
    WHERE id = p_card_id AND user_id = v_user_id
  ) THEN
    RAISE EXCEPTION 'Card not found or access denied';
  END IF;

  -- Get current max sort_order
  SELECT COALESCE(MAX(sort_order), 0) INTO v_max_sort_order
  FROM content_items
  WHERE card_id = p_card_id;

  -- Create each item
  FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
  LOOP
    -- Increment sort order
    v_max_sort_order := v_max_sort_order + 1;

    INSERT INTO content_items (
      card_id,
      name,
      content,
      parent_id,
      image_url,
      ai_knowledge_base,
      sort_order,
      created_at,
      updated_at
    ) VALUES (
      p_card_id,
      v_item->>'name',
      v_item->>'content',
      CASE
        WHEN v_item->>'parent_id' IS NOT NULL AND v_item->>'parent_id' != ''
        THEN (v_item->>'parent_id')::UUID
        ELSE NULL
      END,
      v_item->>'image_url',
      v_item->>'ai_knowledge_base',
      COALESCE((v_item->>'sort_order')::INT, v_max_sort_order),
      NOW(),
      NOW()
    )
    RETURNING id INTO v_new_id;

    -- Add to result
    v_result := v_result || jsonb_build_object(
      'id', v_new_id,
      'name', v_item->>'name',
      'sort_order', v_max_sort_order
    );
  END LOOP;

  -- Update card's last_content_update timestamp
  UPDATE cards
  SET updated_at = NOW(),
      last_content_update = NOW()
  WHERE id = p_card_id;

  -- Log operation
  PERFORM log_operation(format('Bulk created %s content items', jsonb_array_length(v_result)));

  RETURN jsonb_build_object(
    'success', true,
    'count', jsonb_array_length(v_result),
    'items', v_result
  );

EXCEPTION
  WHEN OTHERS THEN
    RAISE EXCEPTION 'Bulk create failed: %', SQLERRM;
END;
$$;
GRANT EXECUTE ON FUNCTION bulk_create_content_items(UUID, JSONB) TO authenticated;

-- Bulk delete content items
-- Purpose: Delete multiple content items in a single transaction
-- Used by: Bulk operations
CREATE OR REPLACE FUNCTION bulk_delete_content_items(
  p_item_ids UUID[]
) RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id UUID;
  v_card_id UUID;
  v_deleted_count INT := 0;
  v_item_id UUID;
BEGIN
  -- Get authenticated user
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  -- Verify all items belong to user's cards
  FOR v_item_id IN SELECT UNNEST(p_item_ids)
  LOOP
    SELECT ci.card_id INTO v_card_id
    FROM content_items ci
    JOIN cards c ON c.id = ci.card_id
    WHERE ci.id = v_item_id AND c.user_id = v_user_id;

    IF v_card_id IS NULL THEN
      RAISE EXCEPTION 'Content item % not found or access denied', v_item_id;
    END IF;
  END LOOP;

  -- Delete all items (cascading will handle children if any)
  DELETE FROM content_items
  WHERE id = ANY(p_item_ids);

  GET DIAGNOSTICS v_deleted_count = ROW_COUNT;

  -- Update affected cards' last_content_update timestamp
  UPDATE cards
  SET updated_at = NOW(),
      last_content_update = NOW()
  WHERE id IN (
    SELECT DISTINCT c.id
    FROM cards c
    WHERE EXISTS (
      SELECT 1 FROM content_items ci
      WHERE ci.card_id = c.id AND ci.id = ANY(p_item_ids)
    )
  );

  -- Log operation
  PERFORM log_operation(format('Bulk deleted %s content items', v_deleted_count));

  RETURN jsonb_build_object(
    'success', true,
    'deleted_count', v_deleted_count
  );

EXCEPTION
  WHEN OTHERS THEN
    RAISE EXCEPTION 'Bulk delete failed: %', SQLERRM;
END;
$$;
GRANT EXECUTE ON FUNCTION bulk_delete_content_items(UUID[]) TO authenticated;
