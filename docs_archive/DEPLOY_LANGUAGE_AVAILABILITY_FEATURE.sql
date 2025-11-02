-- =====================================================================
-- DEPLOY: Language Availability Feature for Mobile Client
-- =====================================================================
-- This deployment updates the public card access functions to return
-- which languages are available for a card, allowing the mobile client
-- to disable unavailable languages in the language selector.
--
-- Changes:
-- 1. get_public_card_content: Added card_available_languages column
-- 2. get_card_preview_content: Added card_available_languages column
--
-- The available languages are determined by:
-- - Original language (always available)
-- - Languages with translations (extracted from translations JSONB)
--
-- DEPLOYMENT INSTRUCTIONS:
-- 1. Navigate to Supabase Dashboard > SQL Editor
-- 2. Execute this file OR manually execute the functions below
-- 3. Test by scanning a QR code and opening language selector
-- =====================================================================

-- =====================================================================
-- 1. Update get_public_card_content
-- =====================================================================

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
    card_available_languages TEXT[], -- ✅ NEW: Array of available language codes
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
    SELECT 
        c.id, 
        ic.active, 
        c.user_id
    INTO 
        v_card_design_id, 
        v_is_card_active, 
        v_card_owner_id
    FROM issued_cards ic
    INNER JOIN cards c ON ic.card_design_id = c.id
    WHERE ic.id = p_issue_card_id;
    
    -- Check if card exists
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Card not found';
    END IF;
    
    -- Check if current user is the card owner (allows inactive card access)
    IF v_caller_id = v_card_owner_id THEN
        v_is_owner_access := TRUE;
        v_is_card_active := TRUE; -- Owner can always access
    END IF;
    
    -- If not owner and card is inactive, deny access
    IF NOT v_is_owner_access AND NOT v_is_card_active THEN
        RAISE EXCEPTION 'Card is not activated';
    END IF;
    
    -- Auto-activate card on first access (if not already active)
    IF NOT v_is_card_active THEN
        UPDATE issued_cards 
        SET 
            active = TRUE,
            first_activated_at = COALESCE(first_activated_at, NOW()),
            last_accessed_at = NOW()
        WHERE id = p_issue_card_id;
        
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
        -- ✅ Get array of available translation languages (original + translated languages)
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
        v_is_card_active AS is_activated
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

-- =====================================================================
-- 2. Update get_card_preview_content
-- =====================================================================

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
    card_available_languages TEXT[], -- ✅ NEW: Array of available language codes
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
    -- Get caller information
    v_caller_id := auth.uid();
    
    IF v_caller_id IS NULL THEN
        RAISE EXCEPTION 'Authentication required for preview access';
    END IF;
    
    -- Get caller role and card owner
    SELECT 
        au.raw_user_meta_data->>'role',
        c.user_id
    INTO 
        v_caller_role,
        v_user_id
    FROM cards c
    CROSS JOIN auth.users au
    WHERE c.id = p_card_id AND au.id = v_caller_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Card not found';
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
        -- ✅ Get array of available translation languages (original + translated languages)
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
        TRUE AS is_preview
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

-- =====================================================================
-- VERIFICATION QUERIES
-- =====================================================================

-- Test the function returns available languages
-- Replace with your own issue_card_id for testing
/*
SELECT DISTINCT
    card_name,
    card_original_language,
    card_has_translation,
    card_available_languages
FROM get_public_card_content('YOUR_ISSUE_CARD_ID_HERE', 'en');
*/

-- Expected result:
-- card_available_languages should be an array like: {en,zh-Hant,ja}
-- where 'en' is the original language and others are translated languages

