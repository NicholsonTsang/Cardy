-- =================================================================
-- TEMPLATE LIBRARY STORED PROCEDURES
-- =================================================================
-- Templates link to actual cards records in the database
-- This allows full reuse of card/content item components
-- When users import a template, the linked card and its content items are copied

-- -----------------------------------------------------------------
-- List all available templates with filtering
-- Joins with cards table to get card data
-- All fields included for consistency with Excel export/import
-- -----------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.list_content_templates(
    p_scenario_category TEXT DEFAULT NULL,
    p_content_mode TEXT DEFAULT NULL,
    p_search TEXT DEFAULT NULL,
    p_featured_only BOOLEAN DEFAULT FALSE,
    p_language TEXT DEFAULT NULL  -- Display templates in this language if translation available
)
RETURNS TABLE (
    id UUID,
    slug TEXT,
    card_id UUID,
    name TEXT,
    description TEXT,
    scenario_category TEXT,
    thumbnail_url TEXT,
    content_mode TEXT,
    is_grouped BOOLEAN,
    group_display TEXT,
    billing_type TEXT,
    default_daily_session_limit INTEGER,
    original_language TEXT,
    qr_code_position TEXT,
    item_count BIGINT,
    is_featured BOOLEAN,
    created_at TIMESTAMPTZ,
    translation_languages TEXT[]
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ct.id,
        ct.slug,
        ct.card_id,
        -- Use translated name if language specified and translation exists, else original
        CASE 
            WHEN p_language IS NOT NULL AND c.translations ? p_language 
            THEN COALESCE(c.translations->p_language->>'name', c.name)
            ELSE c.name
        END AS name,
        -- Use translated description if language specified and translation exists, else original
        CASE 
            WHEN p_language IS NOT NULL AND c.translations ? p_language 
            THEN COALESCE(c.translations->p_language->>'description', c.description, '')
            ELSE COALESCE(c.description, '')
        END::TEXT AS description,
        ct.scenario_category,
        COALESCE(c.image_url, '')::TEXT AS thumbnail_url,
        COALESCE(c.content_mode, 'list')::TEXT,
        COALESCE(c.is_grouped, false),
        COALESCE(c.group_display, 'expanded')::TEXT,
        COALESCE(c.billing_type, 'digital')::TEXT,
        c.default_daily_session_limit,
        COALESCE(c.original_language, 'en')::TEXT,
        COALESCE(c.qr_code_position::TEXT, 'BR'),
        (SELECT COUNT(*) FROM content_items ci WHERE ci.card_id = c.id)::BIGINT AS item_count,
        ct.is_featured,
        ct.created_at,
        -- Extract translation language keys from JSONB
        COALESCE(ARRAY(SELECT jsonb_object_keys(c.translations)), ARRAY[]::TEXT[]) AS translation_languages
    FROM content_templates ct
    JOIN cards c ON ct.card_id = c.id
    WHERE ct.is_active = true
        AND (p_scenario_category IS NULL OR ct.scenario_category = p_scenario_category)
        AND (p_content_mode IS NULL OR c.content_mode = p_content_mode)
        AND (p_featured_only = FALSE OR ct.is_featured = true)
        AND (
            p_search IS NULL 
            OR c.name ILIKE '%' || p_search || '%'
            OR c.description ILIKE '%' || p_search || '%'
            -- Also search in translated fields if language specified
            OR (p_language IS NOT NULL AND c.translations ? p_language AND (
                c.translations->p_language->>'name' ILIKE '%' || p_search || '%'
                OR c.translations->p_language->>'description' ILIKE '%' || p_search || '%'
            ))
        )
    ORDER BY 
        ct.is_featured DESC,
        ct.sort_order ASC,
        c.name ASC;
END;
$$;

-- -----------------------------------------------------------------
-- Get single template by ID or slug with full details
-- Returns card data and content items
-- Supports multilingual preview via p_language parameter
-- -----------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_content_template(
    p_template_id UUID DEFAULT NULL,
    p_slug TEXT DEFAULT NULL,
    p_language TEXT DEFAULT NULL  -- Display template in this language if translation available
)
RETURNS TABLE (
    id UUID,
    slug TEXT,
    card_id UUID,
    name TEXT,
    description TEXT,
    scenario_category TEXT,
    thumbnail_url TEXT,
    content_mode TEXT,
    is_grouped BOOLEAN,
    group_display TEXT,
    billing_type TEXT,
    conversation_ai_enabled BOOLEAN,
    ai_instruction TEXT,
    ai_knowledge_base TEXT,
    ai_welcome_general TEXT,
    ai_welcome_item TEXT,
    original_language TEXT,
    qr_code_position TEXT,
    default_daily_session_limit INTEGER,
    crop_parameters JSONB,
    translations JSONB,
    content_hash TEXT,
    item_count BIGINT,
    is_featured BOOLEAN,
    created_at TIMESTAMPTZ,
    content_items JSONB,
    translation_languages TEXT[]
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ct.id,
        ct.slug,
        ct.card_id,
        -- Use translated name if language specified and translation exists, else original
        CASE 
            WHEN p_language IS NOT NULL AND c.translations ? p_language 
            THEN COALESCE(c.translations->p_language->>'name', c.name)
            ELSE c.name
        END AS name,
        -- Use translated description if language specified and translation exists, else original
        CASE 
            WHEN p_language IS NOT NULL AND c.translations ? p_language 
            THEN COALESCE(c.translations->p_language->>'description', c.description, '')
            ELSE COALESCE(c.description, '')
        END::TEXT AS description,
        ct.scenario_category,
        COALESCE(c.image_url, '')::TEXT AS thumbnail_url,
        COALESCE(c.content_mode, 'list')::TEXT,
        COALESCE(c.is_grouped, false),
        COALESCE(c.group_display, 'expanded')::TEXT,
        COALESCE(c.billing_type, 'digital')::TEXT,
        COALESCE(c.conversation_ai_enabled, true),
        -- Use translated AI fields if language specified and translation exists
        CASE 
            WHEN p_language IS NOT NULL AND c.translations ? p_language 
            THEN COALESCE(c.translations->p_language->>'ai_instruction', c.ai_instruction, '')
            ELSE COALESCE(c.ai_instruction, '')
        END::TEXT AS ai_instruction,
        CASE 
            WHEN p_language IS NOT NULL AND c.translations ? p_language 
            THEN COALESCE(c.translations->p_language->>'ai_knowledge_base', c.ai_knowledge_base, '')
            ELSE COALESCE(c.ai_knowledge_base, '')
        END::TEXT AS ai_knowledge_base,
        CASE 
            WHEN p_language IS NOT NULL AND c.translations ? p_language 
            THEN COALESCE(c.translations->p_language->>'ai_welcome_general', c.ai_welcome_general, '')
            ELSE COALESCE(c.ai_welcome_general, '')
        END::TEXT AS ai_welcome_general,
        CASE 
            WHEN p_language IS NOT NULL AND c.translations ? p_language 
            THEN COALESCE(c.translations->p_language->>'ai_welcome_item', c.ai_welcome_item, '')
            ELSE COALESCE(c.ai_welcome_item, '')
        END::TEXT AS ai_welcome_item,
        COALESCE(c.original_language, 'en')::TEXT,
        COALESCE(c.qr_code_position::TEXT, 'BR'),
        c.default_daily_session_limit,
        c.crop_parameters,
        COALESCE(c.translations, '{}'::JSONB),
        c.content_hash,
        (SELECT COUNT(*) FROM content_items ci WHERE ci.card_id = c.id)::BIGINT AS item_count,
        ct.is_featured,
        ct.created_at,
        -- Get content items as JSON array with translated content if language specified
        COALESCE(
            (SELECT jsonb_agg(
                jsonb_build_object(
                    'id', ci.id,
                    'parent_id', ci.parent_id,
                    'name', CASE 
                        WHEN p_language IS NOT NULL AND ci.translations ? p_language 
                        THEN COALESCE(ci.translations->p_language->>'name', ci.name)
                        ELSE ci.name
                    END,
                    'content', CASE 
                        WHEN p_language IS NOT NULL AND ci.translations ? p_language 
                        THEN COALESCE(ci.translations->p_language->>'content', ci.content)
                        ELSE ci.content
                    END,
                    'image_url', ci.image_url,
                    'original_image_url', ci.original_image_url,
                    'ai_knowledge_base', CASE 
                        WHEN p_language IS NOT NULL AND ci.translations ? p_language 
                        THEN COALESCE(ci.translations->p_language->>'ai_knowledge_base', ci.ai_knowledge_base)
                        ELSE ci.ai_knowledge_base
                    END,
                    'sort_order', ci.sort_order,
                    'crop_parameters', ci.crop_parameters,
                    'translations', COALESCE(ci.translations, '{}'::JSONB),
                    'content_hash', ci.content_hash
                ) ORDER BY ci.sort_order
            )
            FROM content_items ci 
            WHERE ci.card_id = c.id),
            '[]'::JSONB
        ) AS content_items,
        -- Extract translation language keys from JSONB
        COALESCE(ARRAY(SELECT jsonb_object_keys(c.translations)), ARRAY[]::TEXT[]) AS translation_languages
    FROM content_templates ct
    JOIN cards c ON ct.card_id = c.id
    WHERE ct.is_active = true
        AND (
            (p_template_id IS NOT NULL AND ct.id = p_template_id)
            OR (p_slug IS NOT NULL AND ct.slug = p_slug)
        );
END;
$$;

-- -----------------------------------------------------------------
-- Get available scenario categories for filtering
-- -----------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_template_scenario_categories()
RETURNS TABLE (
    scenario_category TEXT,
    template_count BIGINT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ct.scenario_category,
        COUNT(*)::BIGINT as template_count
    FROM content_templates ct
    WHERE ct.is_active = true AND ct.scenario_category IS NOT NULL
    GROUP BY ct.scenario_category
    ORDER BY template_count DESC, ct.scenario_category ASC;
END;
$$;

-- -----------------------------------------------------------------
-- Import a template to create a new card
-- Copies the linked card and all its content items to a new card owned by the user
-- PERFORMANCE: Uses bulk insert with CTE for better performance
-- -----------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.import_content_template(
    p_user_id UUID,
    p_template_id UUID,
    p_card_name TEXT DEFAULT NULL,
    p_import_language TEXT DEFAULT NULL  -- Language to import content in (uses translated version if available)
)
RETURNS TABLE (
    success BOOLEAN,
    card_id UUID,
    message TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_template RECORD;
    v_new_card_id UUID;
    v_final_name TEXT;
    v_final_language TEXT;
    v_check JSONB;
    v_use_translation BOOLEAN;
    v_lang_data JSONB;
BEGIN
    -- Check subscription limit
    v_check := can_create_project(p_user_id);
    IF NOT (v_check->>'can_create')::BOOLEAN THEN
        RETURN QUERY SELECT FALSE, NULL::UUID, (v_check->>'message')::TEXT;
        RETURN;
    END IF;

    -- Get the template and its linked card
    SELECT ct.*, c.*
    INTO v_template
    FROM content_templates ct
    JOIN cards c ON ct.card_id = c.id
    WHERE ct.id = p_template_id AND ct.is_active = true;
    
    IF NOT FOUND THEN
        RETURN QUERY SELECT FALSE, NULL::UUID, 'Template not found or inactive'::TEXT;
        RETURN;
    END IF;
    
    -- Determine if we should use translated content
    -- Use translation if: import_language is specified AND differs from original AND translation exists
    v_final_language := COALESCE(NULLIF(p_import_language, ''), v_template.original_language);
    v_use_translation := (v_final_language IS DISTINCT FROM v_template.original_language) 
                         AND (v_template.translations ? v_final_language);
    
    IF v_use_translation THEN
        v_lang_data := v_template.translations->v_final_language;
    END IF;
    
    -- Use custom name, or translated name, or original name
    v_final_name := COALESCE(
        NULLIF(p_card_name, ''),
        CASE WHEN v_use_translation THEN v_lang_data->>'name' ELSE NULL END,
        v_template.name
    );
    
    -- Create the new card by copying the template's card
    -- If importing in a different language, use translated content and set original_language to that language
    -- DO NOT copy translations - user starts fresh without any translations
    INSERT INTO cards (
        user_id,
        name,
        description,
        content_mode,
        is_grouped,
        group_display,
        billing_type,
        default_daily_session_limit,
        conversation_ai_enabled,
        ai_instruction,
        ai_knowledge_base,
        ai_welcome_general,
        ai_welcome_item,
        original_language,
        qr_code_position,
        image_url,
        original_image_url,
        crop_parameters,
        translations,  -- Always NULL - no translations copied
        content_hash   -- NULL since content is new
    ) VALUES (
        p_user_id,
        v_final_name,
        CASE WHEN v_use_translation THEN COALESCE(v_lang_data->>'description', v_template.description) ELSE v_template.description END,
        v_template.content_mode,
        v_template.is_grouped,
        v_template.group_display,
        'digital',
        v_template.default_daily_session_limit,
        v_template.conversation_ai_enabled,
        CASE WHEN v_use_translation THEN COALESCE(v_lang_data->>'ai_instruction', v_template.ai_instruction) ELSE v_template.ai_instruction END,
        CASE WHEN v_use_translation THEN COALESCE(v_lang_data->>'ai_knowledge_base', v_template.ai_knowledge_base) ELSE v_template.ai_knowledge_base END,
        CASE WHEN v_use_translation THEN COALESCE(v_lang_data->>'ai_welcome_general', v_template.ai_welcome_general) ELSE v_template.ai_welcome_general END,
        CASE WHEN v_use_translation THEN COALESCE(v_lang_data->>'ai_welcome_item', v_template.ai_welcome_item) ELSE v_template.ai_welcome_item END,
        v_final_language,  -- Set to selected language
        v_template.qr_code_position,
        v_template.image_url,
        v_template.original_image_url,
        v_template.crop_parameters,
        NULL,  -- No translations - start fresh
        NULL   -- No content_hash - will be calculated on first edit
    ) RETURNING id INTO v_new_card_id;
    
    -- Create a default enabled access token (QR code) for the new card
    -- Every project must have at least one QR code
    INSERT INTO card_access_tokens (
        card_id,
        name,
        access_token,
        is_enabled,
        daily_session_limit
    ) VALUES (
        v_new_card_id,
        'Default',
        substring(replace(gen_random_uuid()::text, '-', ''), 1, 12),
        true,
        v_template.default_daily_session_limit
    );
    
    -- PERFORMANCE: Bulk copy content items using CTE with ID mapping
    -- This avoids N+1 individual INSERT statements
    -- If importing in different language, use translated content for name/content/ai_knowledge_base
    -- DO NOT copy translations - user starts fresh
    WITH 
    -- Step 1: Insert parent items (no parent_id) with bulk insert
    parent_items AS (
        INSERT INTO content_items (card_id, parent_id, name, content, image_url, original_image_url, crop_parameters, ai_knowledge_base, sort_order, translations, content_hash)
        SELECT 
            v_new_card_id,
            NULL,
            CASE WHEN v_use_translation AND ci.translations ? v_final_language 
                THEN COALESCE(ci.translations->v_final_language->>'name', ci.name) 
                ELSE ci.name 
            END,
            CASE WHEN v_use_translation AND ci.translations ? v_final_language 
                THEN COALESCE(ci.translations->v_final_language->>'content', ci.content) 
                ELSE ci.content 
            END,
            ci.image_url,
            ci.original_image_url,
            ci.crop_parameters,
            CASE WHEN v_use_translation AND ci.translations ? v_final_language 
                THEN COALESCE(ci.translations->v_final_language->>'ai_knowledge_base', ci.ai_knowledge_base) 
                ELSE ci.ai_knowledge_base 
            END,
            ci.sort_order,
            NULL,  -- No translations - start fresh
            NULL   -- No content_hash
        FROM content_items ci
        WHERE ci.card_id = v_template.card_id AND ci.parent_id IS NULL
        ORDER BY ci.sort_order
        RETURNING id, sort_order
    ),
    -- Step 2: Build mapping from original parent items to new ones (by sort_order since we preserve it)
    parent_mapping AS (
        SELECT 
            orig.id AS old_id,
            new_item.id AS new_id
        FROM content_items orig
        JOIN parent_items new_item ON orig.sort_order = new_item.sort_order
        WHERE orig.card_id = v_template.card_id AND orig.parent_id IS NULL
    )
    -- Step 3: Insert child items with mapped parent_ids
    INSERT INTO content_items (card_id, parent_id, name, content, image_url, original_image_url, crop_parameters, ai_knowledge_base, sort_order, translations, content_hash)
    SELECT 
        v_new_card_id,
        pm.new_id,
        CASE WHEN v_use_translation AND ci.translations ? v_final_language 
            THEN COALESCE(ci.translations->v_final_language->>'name', ci.name) 
            ELSE ci.name 
        END,
        CASE WHEN v_use_translation AND ci.translations ? v_final_language 
            THEN COALESCE(ci.translations->v_final_language->>'content', ci.content) 
            ELSE ci.content 
        END,
        ci.image_url,
        ci.original_image_url,
        ci.crop_parameters,
        CASE WHEN v_use_translation AND ci.translations ? v_final_language 
            THEN COALESCE(ci.translations->v_final_language->>'ai_knowledge_base', ci.ai_knowledge_base) 
            ELSE ci.ai_knowledge_base 
        END,
        ci.sort_order,
        NULL,  -- No translations - start fresh
        NULL   -- No content_hash
    FROM content_items ci
    JOIN parent_mapping pm ON ci.parent_id = pm.old_id
    WHERE ci.card_id = v_template.card_id AND ci.parent_id IS NOT NULL
    ORDER BY ci.sort_order;
    
    -- Update import count
    UPDATE content_templates 
    SET import_count = import_count + 1
    WHERE id = p_template_id;
    
    -- Log the operation
    INSERT INTO operations_log (user_id, user_role, operation)
    SELECT 
        p_user_id,
        COALESCE((au.raw_user_meta_data->>'role')::"UserRole", 'user'::"UserRole"),
        'Imported template: ' || v_template.name || ' as card: ' || v_final_name
    FROM auth.users au
    WHERE au.id = p_user_id;
    
    RETURN QUERY SELECT TRUE, v_new_card_id, 'Template imported successfully'::TEXT;
    
EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT FALSE, NULL::UUID, ('Import failed: ' || SQLERRM)::TEXT;
END;
$$;

-- =================================================================
-- ADMIN FUNCTIONS (require admin role)
-- =================================================================

-- -----------------------------------------------------------------
-- Create a new template by linking to an existing card (admin only)
-- The card should already exist (created via normal card creation flow)
-- -----------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.create_template_from_card(
    p_admin_user_id UUID,
    p_card_id UUID,
    p_slug TEXT,
    p_scenario_category TEXT DEFAULT NULL,
    p_is_featured BOOLEAN DEFAULT FALSE,
    p_sort_order INTEGER DEFAULT 0
)
RETURNS TABLE (
    success BOOLEAN,
    template_id UUID,
    message TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_user_role TEXT;
    v_card_exists BOOLEAN;
    v_slug_exists BOOLEAN;
    v_result_id UUID;
    v_card_name TEXT;
BEGIN
    -- Check if user is admin
    SELECT raw_user_meta_data->>'role' INTO v_user_role
    FROM auth.users
    WHERE auth.users.id = p_admin_user_id;
    
    IF v_user_role IS NULL OR v_user_role != 'admin' THEN
        RETURN QUERY SELECT FALSE, NULL::UUID, 'Unauthorized: Admin access required'::TEXT;
        RETURN;
    END IF;
    
    -- Check if card exists
    SELECT EXISTS(SELECT 1 FROM cards WHERE id = p_card_id), name
    INTO v_card_exists, v_card_name
    FROM cards WHERE id = p_card_id;
    
    IF NOT v_card_exists THEN
        RETURN QUERY SELECT FALSE, NULL::UUID, 'Card not found'::TEXT;
        RETURN;
    END IF;
    
    -- Check if slug is already taken
    SELECT EXISTS(SELECT 1 FROM content_templates WHERE slug = p_slug)
    INTO v_slug_exists;
    
    IF v_slug_exists THEN
        RETURN QUERY SELECT FALSE, NULL::UUID, 'Slug already exists'::TEXT;
        RETURN;
    END IF;
    
    -- Create the template linking to the card
    INSERT INTO content_templates (
        slug, card_id, scenario_category, is_featured, sort_order
    ) VALUES (
        p_slug, p_card_id, p_scenario_category, p_is_featured, p_sort_order
    ) RETURNING id INTO v_result_id;
    
    -- Log the operation
    INSERT INTO operations_log (user_id, user_role, operation)
    VALUES (p_admin_user_id, 'admin', 'Created template: ' || v_card_name || ' (slug: ' || p_slug || ')');
    
    RETURN QUERY SELECT TRUE, v_result_id, 'Template created successfully'::TEXT;
    
EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT FALSE, NULL::UUID, ('Error: ' || SQLERRM)::TEXT;
END;
$$;

-- -----------------------------------------------------------------
-- Update template admin fields (admin only)
-- Card data is updated via normal card update flow
-- -----------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.update_template_settings(
    p_admin_user_id UUID,
    p_template_id UUID,
    p_slug TEXT DEFAULT NULL,
    p_scenario_category TEXT DEFAULT NULL,
    p_is_featured BOOLEAN DEFAULT NULL,
    p_is_active BOOLEAN DEFAULT NULL,
    p_sort_order INTEGER DEFAULT NULL
)
RETURNS TABLE (
    success BOOLEAN,
    message TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_user_role TEXT;
    v_template_name TEXT;
    v_slug_exists BOOLEAN;
BEGIN
    -- Check if user is admin
    SELECT raw_user_meta_data->>'role' INTO v_user_role
    FROM auth.users
    WHERE auth.users.id = p_admin_user_id;
    
    IF v_user_role IS NULL OR v_user_role != 'admin' THEN
        RETURN QUERY SELECT FALSE, 'Unauthorized: Admin access required'::TEXT;
        RETURN;
    END IF;
    
    -- Get template name for logging
    SELECT c.name INTO v_template_name
    FROM content_templates ct
    JOIN cards c ON ct.card_id = c.id
    WHERE ct.id = p_template_id;
    
    IF v_template_name IS NULL THEN
        RETURN QUERY SELECT FALSE, 'Template not found'::TEXT;
        RETURN;
    END IF;
    
    -- Check if new slug is already taken (if changing slug)
    IF p_slug IS NOT NULL THEN
        SELECT EXISTS(
            SELECT 1 FROM content_templates 
            WHERE slug = p_slug AND id != p_template_id
        ) INTO v_slug_exists;
        
        IF v_slug_exists THEN
            RETURN QUERY SELECT FALSE, 'Slug already exists'::TEXT;
            RETURN;
        END IF;
    END IF;
    
    -- Update template settings
    UPDATE content_templates SET
        slug = COALESCE(p_slug, slug),
        scenario_category = COALESCE(p_scenario_category, scenario_category),
        is_featured = COALESCE(p_is_featured, is_featured),
        is_active = COALESCE(p_is_active, is_active),
        sort_order = COALESCE(p_sort_order, sort_order),
        updated_at = NOW()
    WHERE id = p_template_id;
    
    -- Log the operation
    INSERT INTO operations_log (user_id, user_role, operation)
    VALUES (p_admin_user_id, 'admin', 'Updated template settings: ' || v_template_name);
    
    RETURN QUERY SELECT TRUE, 'Template settings updated successfully'::TEXT;
    
EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT FALSE, ('Error: ' || SQLERRM)::TEXT;
END;
$$;

-- -----------------------------------------------------------------
-- Delete a content template (admin only)
-- Optionally delete the linked card as well
-- -----------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.delete_content_template(
    p_admin_user_id UUID,
    p_template_id UUID,
    p_delete_card BOOLEAN DEFAULT FALSE
)
RETURNS TABLE (
    success BOOLEAN,
    message TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_user_role TEXT;
    v_template_name TEXT;
    v_card_id UUID;
BEGIN
    -- Check if user is admin
    SELECT raw_user_meta_data->>'role' INTO v_user_role
    FROM auth.users
    WHERE auth.users.id = p_admin_user_id;
    
    IF v_user_role IS NULL OR v_user_role != 'admin' THEN
        RETURN QUERY SELECT FALSE, 'Unauthorized: Admin access required'::TEXT;
        RETURN;
    END IF;
    
    -- Get template details
    SELECT c.name, ct.card_id INTO v_template_name, v_card_id
    FROM content_templates ct
    JOIN cards c ON ct.card_id = c.id
    WHERE ct.id = p_template_id;
    
    IF v_template_name IS NULL THEN
        RETURN QUERY SELECT FALSE, 'Template not found'::TEXT;
        RETURN;
    END IF;
    
    -- Delete the template
    DELETE FROM content_templates WHERE id = p_template_id;
    
    -- Optionally delete the linked card
    IF p_delete_card AND v_card_id IS NOT NULL THEN
        DELETE FROM cards WHERE id = v_card_id;
    END IF;
    
    -- Log the operation
    INSERT INTO operations_log (user_id, user_role, operation)
    VALUES (
        p_admin_user_id, 
        'admin', 
        'Deleted template: ' || v_template_name || 
        CASE WHEN p_delete_card THEN ' (with card)' ELSE '' END
    );
    
    RETURN QUERY SELECT TRUE, 'Template deleted successfully'::TEXT;
    
EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT FALSE, ('Error: ' || SQLERRM)::TEXT;
END;
$$;

-- -----------------------------------------------------------------
-- Toggle template active status (admin only)
-- -----------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.toggle_template_status(
    p_admin_user_id UUID,
    p_template_id UUID,
    p_is_active BOOLEAN
)
RETURNS TABLE (
    success BOOLEAN,
    message TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_user_role TEXT;
    v_template_name TEXT;
BEGIN
    -- Check if user is admin
    SELECT raw_user_meta_data->>'role' INTO v_user_role
    FROM auth.users
    WHERE auth.users.id = p_admin_user_id;
    
    IF v_user_role IS NULL OR v_user_role != 'admin' THEN
        RETURN QUERY SELECT FALSE, 'Unauthorized: Admin access required'::TEXT;
        RETURN;
    END IF;
    
    -- Get template name for logging
    SELECT c.name INTO v_template_name
    FROM content_templates ct
    JOIN cards c ON ct.card_id = c.id
    WHERE ct.id = p_template_id;
    
    IF v_template_name IS NULL THEN
        RETURN QUERY SELECT FALSE, 'Template not found'::TEXT;
        RETURN;
    END IF;
    
    -- Update status
    UPDATE content_templates 
    SET is_active = p_is_active, updated_at = NOW()
    WHERE id = p_template_id;
    
    -- Log the operation
    INSERT INTO operations_log (user_id, user_role, operation)
    VALUES (
        p_admin_user_id, 
        'admin', 
        CASE WHEN p_is_active 
            THEN 'Activated template: ' 
            ELSE 'Deactivated template: ' 
        END || v_template_name
    );
    
    RETURN QUERY SELECT TRUE, 
        CASE WHEN p_is_active 
            THEN 'Template activated' 
            ELSE 'Template deactivated' 
        END::TEXT;
    
EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT FALSE, ('Error: ' || SQLERRM)::TEXT;
END;
$$;

-- -----------------------------------------------------------------
-- List all templates including inactive (admin only)
-- -----------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.admin_list_all_templates(
    p_admin_user_id UUID
)
RETURNS TABLE (
    id UUID,
    slug TEXT,
    card_id UUID,
    name TEXT,
    description TEXT,
    scenario_category TEXT,
    thumbnail_url TEXT,
    content_mode TEXT,
    is_grouped BOOLEAN,
    group_display TEXT,
    billing_type TEXT,
    item_count BIGINT,
    is_featured BOOLEAN,
    is_active BOOLEAN,
    sort_order INTEGER,
    import_count INTEGER,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_user_role TEXT;
BEGIN
    -- Check if user is admin
    SELECT raw_user_meta_data->>'role' INTO v_user_role
    FROM auth.users
    WHERE auth.users.id = p_admin_user_id;
    
    IF v_user_role IS NULL OR v_user_role != 'admin' THEN
        RAISE EXCEPTION 'Unauthorized: Admin access required';
    END IF;
    
    RETURN QUERY
    SELECT 
        ct.id,
        ct.slug,
        ct.card_id,
        c.name,
        COALESCE(c.description, '')::TEXT,
        ct.scenario_category,
        COALESCE(c.image_url, '')::TEXT AS thumbnail_url,
        COALESCE(c.content_mode, 'list')::TEXT,
        COALESCE(c.is_grouped, false),
        COALESCE(c.group_display, 'expanded')::TEXT,
        COALESCE(c.billing_type, 'digital')::TEXT,
        (SELECT COUNT(*) FROM content_items ci WHERE ci.card_id = c.id)::BIGINT AS item_count,
        ct.is_featured,
        ct.is_active,
        ct.sort_order,
        ct.import_count,
        ct.created_at,
        ct.updated_at
    FROM content_templates ct
    JOIN cards c ON ct.card_id = c.id
    ORDER BY ct.sort_order ASC, c.name ASC;
END;
$$;

-- -----------------------------------------------------------------
-- Batch update template sort_order (admin only)
-- Used for drag-and-drop reordering
-- -----------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.batch_update_template_order(
    p_admin_user_id UUID,
    p_updates JSONB -- Array of {id: uuid, sort_order: int}
)
RETURNS TABLE (
    success BOOLEAN,
    message TEXT,
    updated_count INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_user_role TEXT;
    v_update JSONB;
    v_count INTEGER := 0;
BEGIN
    -- Check if user is admin
    SELECT raw_user_meta_data->>'role' INTO v_user_role
    FROM auth.users
    WHERE auth.users.id = p_admin_user_id;
    
    IF v_user_role IS NULL OR v_user_role != 'admin' THEN
        RETURN QUERY SELECT FALSE, 'Unauthorized: Admin access required'::TEXT, 0;
        RETURN;
    END IF;
    
    -- Update each template's sort_order
    FOR v_update IN SELECT * FROM jsonb_array_elements(p_updates)
    LOOP
        UPDATE content_templates 
        SET sort_order = (v_update->>'sort_order')::INTEGER,
            updated_at = NOW()
        WHERE id = (v_update->>'id')::UUID;
        
        IF FOUND THEN
            v_count := v_count + 1;
        END IF;
    END LOOP;
    
    -- Log the operation
    INSERT INTO operations_log (user_id, user_role, operation)
    VALUES (p_admin_user_id, 'admin', 'Reordered ' || v_count || ' templates');
    
    RETURN QUERY SELECT TRUE, 'Order updated successfully'::TEXT, v_count;
    
EXCEPTION WHEN OTHERS THEN
    RETURN QUERY SELECT FALSE, ('Error: ' || SQLERRM)::TEXT, 0;
END;
$$;

-- -----------------------------------------------------------------
-- Get admin's template cards (cards owned by admin that are linked to templates)
-- Helps admin manage which cards are templates
-- -----------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_admin_template_cards(
    p_admin_user_id UUID
)
RETURNS TABLE (
    card_id UUID,
    card_name TEXT,
    is_template BOOLEAN,
    template_id UUID,
    template_slug TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_user_role TEXT;
BEGIN
    -- Check if user is admin
    SELECT raw_user_meta_data->>'role' INTO v_user_role
    FROM auth.users
    WHERE auth.users.id = p_admin_user_id;
    
    IF v_user_role IS NULL OR v_user_role != 'admin' THEN
        RAISE EXCEPTION 'Unauthorized: Admin access required';
    END IF;
    
    RETURN QUERY
    SELECT 
        c.id AS card_id,
        c.name AS card_name,
        (ct.id IS NOT NULL) AS is_template,
        ct.id AS template_id,
        ct.slug AS template_slug
    FROM cards c
    LEFT JOIN content_templates ct ON c.id = ct.card_id
    WHERE c.user_id = p_admin_user_id
    ORDER BY c.name ASC;
END;
$$;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION public.list_content_templates(TEXT, TEXT, TEXT, BOOLEAN, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.list_content_templates(TEXT, TEXT, TEXT, BOOLEAN, TEXT) TO anon;
GRANT EXECUTE ON FUNCTION public.get_content_template(UUID, TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_content_template(UUID, TEXT, TEXT) TO anon;
GRANT EXECUTE ON FUNCTION public.get_template_scenario_categories() TO authenticated;
GRANT EXECUTE ON FUNCTION public.import_content_template(UUID, UUID, TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_template_from_card(UUID, UUID, TEXT, TEXT, BOOLEAN, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION public.update_template_settings(UUID, UUID, TEXT, TEXT, BOOLEAN, BOOLEAN, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION public.delete_content_template(UUID, UUID, BOOLEAN) TO authenticated;
GRANT EXECUTE ON FUNCTION public.toggle_template_status(UUID, UUID, BOOLEAN) TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_list_all_templates(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.batch_update_template_order(UUID, JSONB) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_admin_template_cards(UUID) TO authenticated;

-- -----------------------------------------------------------------
-- Get featured demo templates for landing page (public access)
-- Returns templates with their public access URLs
-- Supports multilingual display via p_language parameter
-- Uses card_access_tokens to get the first enabled QR code
-- -----------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_demo_templates(
    p_limit INTEGER DEFAULT 100,
    p_language VARCHAR(10) DEFAULT 'en'
)
RETURNS TABLE (
    id UUID,
    slug TEXT,
    name TEXT,
    description TEXT,
    scenario_category TEXT,
    thumbnail_url TEXT,
    content_mode TEXT,
    item_count BIGINT,
    access_url TEXT,
    is_featured BOOLEAN
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RETURN QUERY
    SELECT
        ct.id,
        ct.slug,
        -- Use translation if available, fallback to original
        COALESCE(c.translations->p_language->>'name', c.name)::TEXT AS name,
        COALESCE(c.translations->p_language->>'description', c.description, '')::TEXT AS description,
        ct.scenario_category,
        COALESCE(c.image_url, '')::TEXT AS thumbnail_url,
        COALESCE(c.content_mode, 'list')::TEXT,
        (SELECT COUNT(*) FROM content_items ci WHERE ci.card_id = c.id)::BIGINT AS item_count,
        -- Get first enabled access token for this card
        (
            SELECT t.access_token
            FROM card_access_tokens t
            WHERE t.card_id = c.id AND t.is_enabled = true
            ORDER BY t.created_at ASC
            LIMIT 1
        )::TEXT AS access_url,
        ct.is_featured
    FROM content_templates ct
    JOIN cards c ON ct.card_id = c.id
    WHERE ct.is_active = true
      -- Only include templates that have at least one enabled access token
      AND EXISTS (
          SELECT 1 FROM card_access_tokens t
          WHERE t.card_id = c.id AND t.is_enabled = true
      )
    ORDER BY ct.is_featured DESC, ct.sort_order ASC, c.name ASC
    LIMIT p_limit;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_demo_templates(INTEGER, VARCHAR) TO anon;
GRANT EXECUTE ON FUNCTION public.get_demo_templates(INTEGER, VARCHAR) TO authenticated;
