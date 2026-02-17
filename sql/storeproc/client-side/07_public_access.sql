-- =================================================================
-- PUBLIC CARD ACCESS FUNCTIONS
-- Functions for public card access and mobile preview
-- =================================================================
-- NOTE (Dec 2025): Legacy credit-based access functions have been removed.
-- Mobile client now uses Express backend (mobile.routes.ts) with Redis-first
-- usage tracking (usage-tracker.ts) for both monthly and daily limits.
--
-- Removed functions:
-- - get_public_card_content (legacy credit model, replaced by mobile API)
-- - get_digital_card_content (legacy credit model, replaced by mobile API)
-- =================================================================

-- Drop functions first to allow return type changes
DROP FUNCTION IF EXISTS get_card_preview_access CASCADE;
DROP FUNCTION IF EXISTS get_card_preview_content CASCADE;

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
-- Updated to include billing_type and daily limit fields for preview
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
    card_realtime_voice_enabled BOOLEAN,
    card_ai_instruction TEXT,
    card_ai_knowledge_base TEXT,
    card_ai_welcome_general TEXT,
    card_ai_welcome_item TEXT,
    card_original_language VARCHAR(10),
    card_has_translation BOOLEAN,
    card_available_languages TEXT[], -- Array of available language codes
    card_content_mode TEXT, -- Content rendering mode (single, grid, list, cards)
    card_is_grouped BOOLEAN, -- Whether content is organized into categories
    card_group_display TEXT, -- How grouped items display: expanded or collapsed
    card_billing_type TEXT, -- Billing model: digital
    card_metadata JSONB, -- Extensible metadata
    -- Note: Session tracking is now per-QR-code in card_access_tokens (not needed for preview)
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
        c.realtime_voice_enabled AS card_realtime_voice_enabled,
        -- Card AI fields with translation support
        COALESCE(c.translations->p_language->>'ai_instruction', c.ai_instruction)::TEXT AS card_ai_instruction,
        COALESCE(c.translations->p_language->>'ai_knowledge_base', c.ai_knowledge_base)::TEXT AS card_ai_knowledge_base,
        COALESCE(c.translations->p_language->>'ai_welcome_general', c.ai_welcome_general)::TEXT AS card_ai_welcome_general,
        COALESCE(c.translations->p_language->>'ai_welcome_item', c.ai_welcome_item)::TEXT AS card_ai_welcome_item,
        c.original_language::VARCHAR(10) AS card_original_language,
        (c.translations ? p_language)::BOOLEAN AS card_has_translation,
        -- Get array of available translation languages (original + translated languages)
        (
            ARRAY[c.original_language] || 
            ARRAY(SELECT jsonb_object_keys(c.translations))
        )::TEXT[] AS card_available_languages,
        COALESCE(c.content_mode, 'list')::TEXT AS card_content_mode, -- Content rendering mode
        COALESCE(c.is_grouped, FALSE)::BOOLEAN AS card_is_grouped, -- Grouping mode
        COALESCE(c.group_display, 'expanded')::TEXT AS card_group_display, -- Group display
        COALESCE(c.billing_type, 'digital')::TEXT AS card_billing_type, -- Billing model
        c.metadata AS card_metadata,
        ci.id AS content_item_id,
        ci.parent_id AS content_item_parent_id,
        COALESCE(ci.translations->p_language->>'name', ci.name)::TEXT AS content_item_name,
        COALESCE(ci.translations->p_language->>'content', ci.content)::TEXT AS content_item_content,
        ci.image_url AS content_item_image_url,
        -- Content item AI knowledge base with translation support
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

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION get_card_preview_access(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_card_preview_content(UUID, VARCHAR) TO authenticated;
