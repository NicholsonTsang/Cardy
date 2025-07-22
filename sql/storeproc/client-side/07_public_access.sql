-- =================================================================
-- PUBLIC CARD ACCESS FUNCTIONS
-- Functions for public card access and mobile preview
-- =================================================================

-- Get public card content by issue card ID
CREATE OR REPLACE FUNCTION get_public_card_content(p_issue_card_id UUID)
RETURNS TABLE (
    card_name TEXT,
    card_description TEXT,
    card_image_url TEXT,
    card_conversation_ai_enabled BOOLEAN,
    card_ai_prompt TEXT,
    content_item_id UUID,
    content_item_parent_id UUID,
    content_item_name TEXT,
    content_item_content TEXT,
    content_item_image_url TEXT,
    content_item_ai_metadata TEXT,
    content_item_sort_order INTEGER,
    is_activated BOOLEAN
) LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_card_design_id UUID;
    v_is_card_active BOOLEAN;
    v_card_owner_id UUID;
    v_caller_id UUID;
    v_is_owner_access BOOLEAN := FALSE;
BEGIN
    -- Get the caller's user ID
    v_caller_id := auth.uid();
    
    -- Get card information by issue card ID
    SELECT ic.card_id, ic.active, c.user_id 
    INTO v_card_design_id, v_is_card_active, v_card_owner_id
    FROM issue_cards ic
    JOIN cards c ON ic.card_id = c.id
    WHERE ic.id = p_issue_card_id;

    IF NOT FOUND THEN
        -- If no card matches, return empty
        RETURN;
    END IF;

    -- Check if the caller is the card owner
    IF v_caller_id IS NOT NULL AND v_caller_id = v_card_owner_id THEN
        v_is_owner_access := TRUE;
        -- For owner access, we consider the card as "activated" for preview purposes
        v_is_card_active := TRUE;
    END IF;

    -- If the card is not active, activate it automatically (regardless of owner status)
    -- This ensures all first-time accesses are tracked, including owner previews
    IF NOT v_is_card_active THEN
        UPDATE issue_cards
        SET 
            active = true,
            active_at = NOW(),
            activated_by = auth.uid() -- Set to current user ID if authenticated, NULL if not
        WHERE id = p_issue_card_id AND active = false;
        
        v_is_card_active := TRUE; -- Mark as active for current request
    END IF;

    RETURN QUERY
    SELECT 
        c.name AS card_name,
        c.description AS card_description,
        c.image_url AS card_image_url,
        c.conversation_ai_enabled AS card_conversation_ai_enabled,
        c.ai_prompt AS card_ai_prompt,
        ci.id AS content_item_id,
        ci.parent_id AS content_item_parent_id,
        ci.name AS content_item_name,
        ci.content AS content_item_content,
        ci.image_url AS content_item_image_url,
        ci.ai_metadata AS content_item_ai_metadata,
        ci.sort_order AS content_item_sort_order,
        v_is_card_active AS is_activated -- Return the current/newly activated status
    FROM cards c
    LEFT JOIN content_items ci ON c.id = ci.card_id
    WHERE c.id = v_card_design_id 
    ORDER BY 
        CASE WHEN ci.parent_id IS NULL THEN ci.sort_order ELSE 999999 END,
        ci.parent_id NULLS FIRST,
        ci.sort_order ASC,
        ci.created_at ASC;
END;
$$;


-- Get card preview URL without requiring issued cards (for card owners)
CREATE OR REPLACE FUNCTION get_card_preview_access(p_card_id UUID)
RETURNS TABLE (
    preview_mode BOOLEAN,
    card_id UUID
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
    
    -- Return preview access with special preview mode flag
    RETURN QUERY
    SELECT 
        TRUE as preview_mode,
        p_card_id as card_id;
END;
$$;

-- Get card content for preview mode (card owner only)
CREATE OR REPLACE FUNCTION get_card_preview_content(p_card_id UUID)
RETURNS TABLE (
    card_name TEXT,
    card_description TEXT,
    card_image_url TEXT,
    card_conversation_ai_enabled BOOLEAN,
    card_ai_prompt TEXT,
    content_item_id UUID,
    content_item_parent_id UUID,
    content_item_name TEXT,
    content_item_content TEXT,
    content_item_image_url TEXT,
    content_item_ai_metadata TEXT,
    content_item_sort_order INTEGER,
    is_preview BOOLEAN
) LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_user_id UUID;
    v_caller_id UUID;
BEGIN
    -- Get the caller's user ID
    v_caller_id := auth.uid();
    
    -- Verify the user is authenticated
    IF v_caller_id IS NULL THEN
        RAISE EXCEPTION 'Authentication required for card preview.';
    END IF;
    
    -- Check if the user owns the card
    SELECT user_id INTO v_user_id FROM cards WHERE id = p_card_id;
    
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Card not found.';
    END IF;
    
    IF v_user_id != v_caller_id THEN
        RAISE EXCEPTION 'Not authorized to preview this card.';
    END IF;
    
    -- Return card content directly (no issued card needed)
    RETURN QUERY
    SELECT 
        c.name AS card_name,
        c.description AS card_description,
        c.image_url AS card_image_url,
        c.conversation_ai_enabled AS card_conversation_ai_enabled,
        c.ai_prompt AS card_ai_prompt,
        ci.id AS content_item_id,
        ci.parent_id AS content_item_parent_id,
        ci.name AS content_item_name,
        ci.content AS content_item_content,
        ci.image_url AS content_item_image_url,
        ci.ai_metadata AS content_item_ai_metadata,
        ci.sort_order AS content_item_sort_order,
        TRUE AS is_preview -- Indicate this is preview mode
    FROM cards c
    LEFT JOIN content_items ci ON c.id = ci.card_id
    WHERE c.id = p_card_id 
    ORDER BY 
        CASE WHEN ci.parent_id IS NULL THEN ci.sort_order ELSE 999999 END,
        ci.parent_id NULLS FIRST,
        ci.sort_order ASC,
        ci.created_at ASC;
END;
$$; 