-- Migration: Add preview mode functionality for cards
-- Date: 2024-12-01
-- Description: Allow card owners to preview their cards without requiring issued cards

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

-- Grant execute permission for the new preview access function
GRANT EXECUTE ON FUNCTION get_card_preview_access(UUID) TO authenticated;

-- Enhanced get_public_card_content to support preview mode
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
    content_item_conversation_ai_enabled BOOLEAN,
    content_item_ai_prompt TEXT,
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
        ci.conversation_ai_enabled AS content_item_conversation_ai_enabled,
        ci.ai_prompt AS content_item_ai_prompt,
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