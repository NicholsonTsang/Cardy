-- =================================================================
-- PUBLIC CARD ACCESS FUNCTIONS
-- Functions for public card access and mobile preview
-- =================================================================

-- Get public card content by issue card ID
-- Updated to support translations via p_language parameter
CREATE OR REPLACE FUNCTION get_public_card_content(
    p_issue_card_id UUID,
    p_language VARCHAR(10) DEFAULT 'en'
)
RETURNS TABLE (
    card_name TEXT,
    card_description TEXT,
    card_image_url TEXT,
    card_crop_parameters JSONB,
    card_conversation_ai_enabled BOOLEAN,
    card_ai_instruction TEXT,
    card_ai_knowledge_base TEXT,
    card_original_language VARCHAR(10),
    card_has_translation BOOLEAN,
    card_available_languages TEXT[], -- Array of available language codes
    content_item_id UUID,
    content_item_parent_id UUID,
    content_item_name TEXT,
    content_item_content TEXT,
    content_item_image_url TEXT,
    content_item_ai_knowledge_base TEXT,
    content_item_sort_order INTEGER,
    crop_parameters JSONB,
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
        BEGIN
            UPDATE issue_cards SET active = true, activated_at = NOW() WHERE id = p_issue_card_id;
            -- Log the auto-activation
            PERFORM log_operation('Card auto-activated on first access');
        EXCEPTION
            WHEN others THEN
                -- Log any error during activation but don't fail the main query
        END;
        
        v_is_card_active := TRUE; -- Mark as active for current request
    END IF;

    RETURN QUERY
    SELECT 
        -- Use translation if available, fallback to original
        COALESCE(c.translations->p_language->>'name', c.name)::TEXT AS card_name,
        COALESCE(c.translations->p_language->>'description', c.description)::TEXT AS card_description,
        c.image_url AS card_image_url,
        c.crop_parameters AS card_crop_parameters,
        c.conversation_ai_enabled AS card_conversation_ai_enabled,
        c.ai_instruction AS card_ai_instruction,
        c.ai_knowledge_base AS card_ai_knowledge_base,
        c.original_language::VARCHAR(10) AS card_original_language,
        (c.translations ? p_language)::BOOLEAN AS card_has_translation,
        -- Get array of available translation languages (original + translated languages)
        (
            ARRAY[c.original_language] || 
            ARRAY(SELECT jsonb_object_keys(c.translations))
        )::TEXT[] AS card_available_languages,
        ci.id AS content_item_id,
        ci.parent_id AS content_item_parent_id,
        COALESCE(ci.translations->p_language->>'name', ci.name)::TEXT AS content_item_name,
        COALESCE(ci.translations->p_language->>'content', ci.content)::TEXT AS content_item_content,
        ci.image_url AS content_item_image_url,
        -- Note: ai_knowledge_base is translated but not exposed to mobile client
        COALESCE(ci.translations->p_language->>'ai_knowledge_base', ci.ai_knowledge_base)::TEXT AS content_item_ai_knowledge_base,
        ci.sort_order AS content_item_sort_order,
        ci.crop_parameters,
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
    v_caller_role TEXT;
BEGIN
    -- Get caller's role
    SELECT raw_user_meta_data->>'role' INTO v_caller_role
    FROM auth.users
    WHERE auth.users.id = auth.uid();
    
    -- Check if the card exists
    SELECT user_id INTO v_user_id FROM cards WHERE id = p_card_id;
    
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Card not found.';
    END IF;
    
    -- Allow access if user owns the card OR if user is admin
    IF v_user_id != auth.uid() AND v_caller_role != 'admin' THEN
        RAISE EXCEPTION 'Not authorized to preview this card.';
    END IF;
    
    -- Return preview access with special preview mode flag
    RETURN QUERY
    SELECT 
        TRUE as preview_mode,
        p_card_id as card_id;
END;
$$;

-- Get card content for preview mode (card owner or admin)
-- Updated to support translations via p_language parameter
CREATE OR REPLACE FUNCTION get_card_preview_content(
    p_card_id UUID,
    p_language VARCHAR(10) DEFAULT 'en'
)
RETURNS TABLE (
    card_name TEXT,
    card_description TEXT,
    card_image_url TEXT,
    card_crop_parameters JSONB,
    card_conversation_ai_enabled BOOLEAN,
    card_ai_instruction TEXT,
    card_ai_knowledge_base TEXT,
    card_original_language VARCHAR(10),
    card_has_translation BOOLEAN,
    card_available_languages TEXT[], -- Array of available language codes
    content_item_id UUID,
    content_item_parent_id UUID,
    content_item_name TEXT,
    content_item_content TEXT,
    content_item_image_url TEXT,
    content_item_ai_knowledge_base TEXT,
    content_item_sort_order INTEGER,
    crop_parameters JSONB,
    is_preview BOOLEAN
) LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_user_id UUID;
    v_caller_id UUID;
    v_caller_role TEXT;
BEGIN
    -- Get the caller's user ID and role
    v_caller_id := auth.uid();
    
    -- Verify the user is authenticated
    IF v_caller_id IS NULL THEN
        RAISE EXCEPTION 'Authentication required for card preview.';
    END IF;
    
    -- Get caller's role
    SELECT raw_user_meta_data->>'role' INTO v_caller_role
    FROM auth.users
    WHERE auth.users.id = v_caller_id;
    
    -- Check if the card exists
    SELECT user_id INTO v_user_id FROM cards WHERE id = p_card_id;
    
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Card not found.';
    END IF;
    
    -- Allow access if user owns the card OR if user is admin
    IF v_user_id != v_caller_id AND v_caller_role != 'admin' THEN
        RAISE EXCEPTION 'Not authorized to preview this card.';
    END IF;
    
    -- Return card content directly (no issued card needed)
    RETURN QUERY
    SELECT 
        -- Use translation if available, fallback to original
        COALESCE(c.translations->p_language->>'name', c.name)::TEXT AS card_name,
        COALESCE(c.translations->p_language->>'description', c.description)::TEXT AS card_description,
        c.image_url AS card_image_url,
        c.crop_parameters AS card_crop_parameters,
        c.conversation_ai_enabled AS card_conversation_ai_enabled,
        c.ai_instruction AS card_ai_instruction,
        c.ai_knowledge_base AS card_ai_knowledge_base,
        c.original_language::VARCHAR(10) AS card_original_language,
        (c.translations ? p_language)::BOOLEAN AS card_has_translation,
        -- Get array of available translation languages (original + translated languages)
        (
            ARRAY[c.original_language] || 
            ARRAY(SELECT jsonb_object_keys(c.translations))
        )::TEXT[] AS card_available_languages,
        ci.id AS content_item_id,
        ci.parent_id AS content_item_parent_id,
        COALESCE(ci.translations->p_language->>'name', ci.name)::TEXT AS content_item_name,
        COALESCE(ci.translations->p_language->>'content', ci.content)::TEXT AS content_item_content,
        ci.image_url AS content_item_image_url,
        COALESCE(ci.translations->p_language->>'ai_knowledge_base', ci.ai_knowledge_base)::TEXT AS content_item_ai_knowledge_base,
        ci.sort_order AS content_item_sort_order,
        ci.crop_parameters,
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