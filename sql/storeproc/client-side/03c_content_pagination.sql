-- =================================================================
-- CONTENT ITEM PAGINATION & LAZY LOADING
-- Optimizes performance for cards with many/large content items
-- =================================================================

-- -----------------------------------------------------------------
-- Get paginated content items with PREVIEW (truncated content)
-- For list views - reduces payload by ~90%
-- -----------------------------------------------------------------
CREATE OR REPLACE FUNCTION get_card_content_items_paginated(
    p_card_id UUID,
    p_limit INTEGER DEFAULT 20,
    p_offset INTEGER DEFAULT 0,
    p_preview_length INTEGER DEFAULT 200  -- Characters to include in preview
)
RETURNS TABLE (
    id UUID,
    card_id UUID,
    parent_id UUID,
    name TEXT,
    content_preview TEXT,          -- Truncated content for list view
    content_length INTEGER,        -- Full content length (for "read more" indicator)
    image_url TEXT,
    ai_knowledge_base_length INTEGER, -- Length only (not full content)
    sort_order INTEGER,
    created_at TIMESTAMPTZ,
    total_count BIGINT             -- Total items for pagination UI
) LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_total BIGINT;
BEGIN
    -- Get total count first
    SELECT COUNT(*) INTO v_total
    FROM content_items ci
    JOIN cards c ON ci.card_id = c.id
    WHERE ci.card_id = p_card_id AND c.user_id = auth.uid();
    
    RETURN QUERY
    SELECT 
        ci.id, 
        ci.card_id,
        ci.parent_id,
        ci.name, 
        -- Truncate content for preview
        CASE 
            WHEN LENGTH(ci.content) > p_preview_length 
            THEN LEFT(ci.content, p_preview_length) || '...'
            ELSE ci.content
        END AS content_preview,
        LENGTH(ci.content)::INTEGER AS content_length,
        ci.image_url,
        LENGTH(ci.ai_knowledge_base)::INTEGER AS ai_knowledge_base_length,
        ci.sort_order,
        ci.created_at,
        v_total AS total_count
    FROM content_items ci
    JOIN cards c ON ci.card_id = c.id
    WHERE ci.card_id = p_card_id AND c.user_id = auth.uid()
    ORDER BY 
        CASE WHEN ci.parent_id IS NULL THEN ci.sort_order ELSE 999999 END,
        ci.parent_id NULLS FIRST,
        ci.sort_order ASC,
        ci.created_at ASC
    LIMIT p_limit
    OFFSET p_offset;
END;
$$;
GRANT EXECUTE ON FUNCTION get_card_content_items_paginated(UUID, INTEGER, INTEGER, INTEGER) TO authenticated;

-- -----------------------------------------------------------------
-- Get FULL content item details (for detail view / lazy loading)
-- Called when user taps on an item to see full content
-- -----------------------------------------------------------------
CREATE OR REPLACE FUNCTION get_content_item_full(p_content_item_id UUID)
RETURNS TABLE (
    id UUID,
    card_id UUID,
    parent_id UUID,
    name TEXT,
    content TEXT,                  -- Full content
    image_url TEXT,
    original_image_url TEXT,
    crop_parameters JSONB,
    ai_knowledge_base TEXT,        -- Full AI knowledge base
    sort_order INTEGER,
    translations JSONB,
    content_hash TEXT,
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
        ci.created_at,
        ci.updated_at
    FROM content_items ci
    JOIN cards c ON ci.card_id = c.id
    WHERE ci.id = p_content_item_id AND c.user_id = auth.uid();
END;
$$;
GRANT EXECUTE ON FUNCTION get_content_item_full(UUID) TO authenticated;

-- -----------------------------------------------------------------
-- PUBLIC: Get card info only (no content items)
-- First call for mobile client - minimal payload (~5KB)
-- SECURITY: Credit rate is hardcoded to prevent bypass attacks
-- -----------------------------------------------------------------
CREATE OR REPLACE FUNCTION get_public_card_info(
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
    card_ai_welcome_general TEXT,
    card_ai_welcome_item TEXT,
    card_original_language VARCHAR(10),
    card_has_translation BOOLEAN,
    card_available_languages TEXT[],
    card_content_mode TEXT,
    card_is_grouped BOOLEAN,
    card_group_display TEXT,
    card_billing_type TEXT,
    card_max_scans INTEGER,
    card_current_scans INTEGER,
    card_daily_scan_limit INTEGER,
    card_daily_scans INTEGER,
    card_scan_limit_reached BOOLEAN,
    card_daily_limit_exceeded BOOLEAN,
    card_credits_insufficient BOOLEAN,
    card_id UUID,
    content_item_count BIGINT,
    is_activated BOOLEAN
) LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    -- SECURITY: Hardcoded credit rate to prevent bypass attacks
    CREDIT_RATE CONSTANT DECIMAL := 0.03;
    
    v_card_design_id UUID;
    v_is_card_active BOOLEAN;
    v_card_owner_id UUID;
    v_caller_id UUID;
    v_is_owner_access BOOLEAN := FALSE;
    v_billing_type TEXT;
    v_max_scans INTEGER;
    v_current_scans INTEGER;
    v_daily_scan_limit INTEGER;
    v_daily_scans INTEGER;
    v_last_scan_date DATE;
    v_scan_limit_reached BOOLEAN := FALSE;
    v_daily_limit_exceeded BOOLEAN := FALSE;
    v_credits_insufficient BOOLEAN := FALSE;
    v_credit_result JSONB;
    v_content_count BIGINT;
BEGIN
    v_caller_id := auth.uid();
    
    -- Get card information
    SELECT ic.card_id, ic.active, c.user_id, c.billing_type, c.max_scans, c.current_scans,
           c.daily_scan_limit, c.daily_scans, c.last_scan_date
    INTO v_card_design_id, v_is_card_active, v_card_owner_id, v_billing_type, v_max_scans, v_current_scans,
         v_daily_scan_limit, v_daily_scans, v_last_scan_date
    FROM issue_cards ic
    JOIN cards c ON ic.card_id = c.id
    WHERE ic.id = p_issue_card_id;

    IF NOT FOUND THEN
        RETURN;
    END IF;

    -- Check owner access
    IF v_caller_id IS NOT NULL AND v_caller_id = v_card_owner_id THEN
        v_is_owner_access := TRUE;
        v_is_card_active := TRUE;
    END IF;

    -- Handle digital card billing (same logic as get_public_card_content)
    IF v_billing_type = 'digital' AND NOT v_is_owner_access THEN
        IF v_last_scan_date IS NULL OR v_last_scan_date < CURRENT_DATE THEN
            UPDATE cards SET daily_scans = 0, last_scan_date = CURRENT_DATE WHERE id = v_card_design_id;
            v_daily_scans := 0;
        END IF;
        
        IF v_max_scans IS NOT NULL AND v_current_scans >= v_max_scans THEN
            v_scan_limit_reached := TRUE;
        ELSIF v_daily_scan_limit IS NOT NULL AND v_daily_scans >= v_daily_scan_limit THEN
            v_daily_limit_exceeded := TRUE;
        ELSE
            -- Using hardcoded credit rate for security
            SELECT consume_credit_for_digital_scan(v_card_design_id, v_card_owner_id, CREDIT_RATE)
            INTO v_credit_result;
            
            IF (v_credit_result->>'success')::BOOLEAN = FALSE THEN
                v_credits_insufficient := TRUE;
            ELSE
                UPDATE cards SET current_scans = current_scans + 1, daily_scans = daily_scans + 1, last_scan_date = CURRENT_DATE
                WHERE id = v_card_design_id;
                v_current_scans := v_current_scans + 1;
                v_daily_scans := v_daily_scans + 1;
            END IF;
        END IF;
    END IF;

    -- Auto-activate if needed
    IF NOT v_is_card_active THEN
        UPDATE issue_cards SET active = true, activated_at = NOW() WHERE id = p_issue_card_id;
        v_is_card_active := TRUE;
    END IF;
    
    -- Get content item count
    SELECT COUNT(*) INTO v_content_count FROM content_items WHERE card_id = v_card_design_id;

    RETURN QUERY
    SELECT 
        COALESCE(c.translations->p_language->>'name', c.name)::TEXT,
        COALESCE(c.translations->p_language->>'description', c.description)::TEXT,
        c.image_url,
        c.crop_parameters,
        c.conversation_ai_enabled,
        c.ai_instruction,
        c.ai_knowledge_base,
        c.ai_welcome_general,
        c.ai_welcome_item,
        c.original_language::VARCHAR(10),
        (c.translations ? p_language)::BOOLEAN,
        (ARRAY[c.original_language] || ARRAY(SELECT jsonb_object_keys(c.translations)))::TEXT[],
        COALESCE(c.content_mode, 'list')::TEXT,
        COALESCE(c.is_grouped, FALSE)::BOOLEAN,
        COALESCE(c.group_display, 'expanded')::TEXT,
        COALESCE(c.billing_type, 'physical')::TEXT,
        c.max_scans,
        v_current_scans,
        c.daily_scan_limit,
        v_daily_scans,
        v_scan_limit_reached,
        v_daily_limit_exceeded,
        v_credits_insufficient,
        v_card_design_id,
        v_content_count,
        v_is_card_active
    FROM cards c
    WHERE c.id = v_card_design_id;
END;
$$;
GRANT EXECUTE ON FUNCTION get_public_card_info(UUID, VARCHAR) TO anon, authenticated;

-- -----------------------------------------------------------------
-- PUBLIC: Get paginated content items with PREVIEW
-- For mobile list views - reduces initial payload significantly
-- -----------------------------------------------------------------
CREATE OR REPLACE FUNCTION get_public_content_items_paginated(
    p_card_id UUID,
    p_language VARCHAR(10) DEFAULT 'en',
    p_limit INTEGER DEFAULT 20,
    p_offset INTEGER DEFAULT 0,
    p_preview_length INTEGER DEFAULT 200
)
RETURNS TABLE (
    content_item_id UUID,
    content_item_parent_id UUID,
    content_item_name TEXT,
    content_preview TEXT,
    content_length INTEGER,
    content_item_image_url TEXT,
    content_item_sort_order INTEGER,
    crop_parameters JSONB,
    total_count BIGINT
) LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_total BIGINT;
BEGIN
    -- Get total count
    SELECT COUNT(*) INTO v_total FROM content_items WHERE card_id = p_card_id;
    
    RETURN QUERY
    SELECT 
        ci.id AS content_item_id,
        ci.parent_id AS content_item_parent_id,
        COALESCE(ci.translations->p_language->>'name', ci.name)::TEXT AS content_item_name,
        CASE 
            WHEN LENGTH(COALESCE(ci.translations->p_language->>'content', ci.content)) > p_preview_length 
            THEN LEFT(COALESCE(ci.translations->p_language->>'content', ci.content), p_preview_length) || '...'
            ELSE COALESCE(ci.translations->p_language->>'content', ci.content)
        END AS content_preview,
        LENGTH(COALESCE(ci.translations->p_language->>'content', ci.content))::INTEGER AS content_length,
        ci.image_url AS content_item_image_url,
        ci.sort_order AS content_item_sort_order,
        ci.crop_parameters,
        v_total AS total_count
    FROM content_items ci
    WHERE ci.card_id = p_card_id
    ORDER BY 
        CASE WHEN ci.parent_id IS NULL THEN ci.sort_order ELSE 999999 END,
        ci.parent_id NULLS FIRST,
        ci.sort_order ASC,
        ci.created_at ASC
    LIMIT p_limit
    OFFSET p_offset;
END;
$$;
GRANT EXECUTE ON FUNCTION get_public_content_items_paginated(UUID, VARCHAR, INTEGER, INTEGER, INTEGER) TO anon, authenticated;

-- -----------------------------------------------------------------
-- PUBLIC: Get FULL content item details (for detail view)
-- Called when user taps on an item
-- -----------------------------------------------------------------
CREATE OR REPLACE FUNCTION get_public_content_item_full(
    p_content_item_id UUID,
    p_language VARCHAR(10) DEFAULT 'en'
)
RETURNS TABLE (
    content_item_id UUID,
    content_item_parent_id UUID,
    content_item_name TEXT,
    content_item_content TEXT,       -- Full content
    content_item_image_url TEXT,
    content_item_ai_knowledge_base TEXT,
    content_item_sort_order INTEGER,
    crop_parameters JSONB,
    -- Include parent info for breadcrumb/navigation
    parent_name TEXT,
    -- Include sibling info for next/prev navigation
    prev_item_id UUID,
    next_item_id UUID
) LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_card_id UUID;
    v_parent_id UUID;
    v_sort_order INTEGER;
BEGIN
    -- Get item's card_id, parent_id, and sort_order for navigation
    SELECT ci.card_id, ci.parent_id, ci.sort_order 
    INTO v_card_id, v_parent_id, v_sort_order
    FROM content_items ci 
    WHERE ci.id = p_content_item_id;
    
    IF NOT FOUND THEN
        RETURN;
    END IF;
    
    RETURN QUERY
    SELECT 
        ci.id AS content_item_id,
        ci.parent_id AS content_item_parent_id,
        COALESCE(ci.translations->p_language->>'name', ci.name)::TEXT AS content_item_name,
        COALESCE(ci.translations->p_language->>'content', ci.content)::TEXT AS content_item_content,
        ci.image_url AS content_item_image_url,
        COALESCE(ci.translations->p_language->>'ai_knowledge_base', ci.ai_knowledge_base)::TEXT AS content_item_ai_knowledge_base,
        ci.sort_order AS content_item_sort_order,
        ci.crop_parameters,
        -- Get parent name
        (SELECT COALESCE(p.translations->p_language->>'name', p.name)::TEXT 
         FROM content_items p WHERE p.id = ci.parent_id) AS parent_name,
        -- Get previous sibling
        (SELECT prev.id FROM content_items prev 
         WHERE prev.card_id = v_card_id 
         AND ((v_parent_id IS NULL AND prev.parent_id IS NULL) OR prev.parent_id = v_parent_id)
         AND prev.sort_order < v_sort_order
         ORDER BY prev.sort_order DESC LIMIT 1) AS prev_item_id,
        -- Get next sibling
        (SELECT next.id FROM content_items next 
         WHERE next.card_id = v_card_id 
         AND ((v_parent_id IS NULL AND next.parent_id IS NULL) OR next.parent_id = v_parent_id)
         AND next.sort_order > v_sort_order
         ORDER BY next.sort_order ASC LIMIT 1) AS next_item_id
    FROM content_items ci
    WHERE ci.id = p_content_item_id;
END;
$$;
GRANT EXECUTE ON FUNCTION get_public_content_item_full(UUID, VARCHAR) TO anon, authenticated;

-- -----------------------------------------------------------------
-- Get content items count by card (utility function)
-- -----------------------------------------------------------------
CREATE OR REPLACE FUNCTION get_content_items_count(p_card_id UUID)
RETURNS TABLE (
    total_count BIGINT,
    parent_count BIGINT,
    child_count BIGINT
) LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*)::BIGINT AS total_count,
        COUNT(*) FILTER (WHERE parent_id IS NULL)::BIGINT AS parent_count,
        COUNT(*) FILTER (WHERE parent_id IS NOT NULL)::BIGINT AS child_count
    FROM content_items
    WHERE card_id = p_card_id;
END;
$$;
GRANT EXECUTE ON FUNCTION get_content_items_count(UUID) TO anon, authenticated;

