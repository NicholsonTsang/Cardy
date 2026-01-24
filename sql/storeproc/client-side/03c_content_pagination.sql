-- =================================================================
-- CONTENT ITEM PAGINATION & LAZY LOADING
-- Optimizes performance for cards with many/large content items
-- =================================================================
-- NOTE (Dec 2025): Legacy credit-based access functions have been removed.
-- Mobile client now uses Express backend (mobile.routes.ts) with Redis-first
-- usage tracking (usage-tracker.ts) for both monthly and daily limits.
-- 
-- Removed functions:
-- - get_public_card_info (legacy credit model, replaced by mobile API)
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
-- PUBLIC: Get paginated content items with PREVIEW
-- For mobile list views - reduces initial payload significantly
-- NOTE: Access control is handled by Express backend (usage-tracker.ts)
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
-- NOTE: Access control is handled by Express backend (usage-tracker.ts)
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
    -- Get item's project_id, parent_id, and sort_order for navigation
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
         FROM content_items p WHERE c.id = ci.parent_id) AS parent_name,
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
-- Get content items count by project (utility function)
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
