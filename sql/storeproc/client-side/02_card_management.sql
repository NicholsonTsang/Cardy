-- =================================================================
-- CARD MANAGEMENT FUNCTIONS
-- Functions for managing card designs (CRUD operations)
-- =================================================================

-- Drop functions first to allow return type changes
DROP FUNCTION IF EXISTS get_user_cards() CASCADE;
DROP FUNCTION IF EXISTS create_card CASCADE;
DROP FUNCTION IF EXISTS get_card_by_id(UUID) CASCADE;
DROP FUNCTION IF EXISTS update_card CASCADE;
DROP FUNCTION IF EXISTS delete_card CASCADE;
DROP FUNCTION IF EXISTS get_card_with_content(UUID) CASCADE;

-- Get all cards for the current user (more secure)
-- Includes is_template flag to indicate if card is linked to a template
-- Session stats are computed from card_access_tokens table
CREATE OR REPLACE FUNCTION get_user_cards()
RETURNS TABLE (
    id UUID,
    name TEXT,
    description TEXT,
    image_url TEXT,
    original_image_url TEXT,
    crop_parameters JSONB,
    conversation_ai_enabled BOOLEAN,
    realtime_voice_enabled BOOLEAN,
    ai_instruction TEXT,
    ai_knowledge_base TEXT,
    ai_welcome_general TEXT,
    ai_welcome_item TEXT,
    qr_code_position TEXT,
    translations JSONB,
    original_language VARCHAR(10),
    content_hash TEXT,
    last_content_update TIMESTAMPTZ,
    content_mode TEXT,
    is_grouped BOOLEAN,
    group_display TEXT,
    billing_type TEXT,
    default_daily_session_limit INTEGER,
    metadata JSONB,
    -- Computed from access tokens
    total_sessions BIGINT,
    monthly_sessions BIGINT,
    daily_sessions BIGINT,
    active_qr_codes BIGINT,
    total_qr_codes BIGINT,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ,
    is_template BOOLEAN,
    template_slug TEXT
) LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
    RETURN QUERY
    SELECT
        c.id,
        c.name,
        c.description,
        c.image_url,
        c.original_image_url,
        c.crop_parameters,
        c.conversation_ai_enabled,
        c.realtime_voice_enabled,
        c.ai_instruction,
        c.ai_knowledge_base,
        c.ai_welcome_general,
        c.ai_welcome_item,
        c.qr_code_position::TEXT,
        c.translations,
        c.original_language,
        c.content_hash,
        c.last_content_update,
        c.content_mode,
        c.is_grouped,
        c.group_display,
        c.billing_type,
        c.default_daily_session_limit,
        c.metadata,
        -- Aggregate stats from access tokens
        COALESCE(SUM(t.total_sessions), 0)::BIGINT AS total_sessions,
        COALESCE(SUM(t.monthly_sessions), 0)::BIGINT AS monthly_sessions,
        COALESCE(SUM(t.daily_sessions), 0)::BIGINT AS daily_sessions,
        COALESCE(COUNT(t.id) FILTER (WHERE t.is_enabled), 0)::BIGINT AS active_qr_codes,
        COALESCE(COUNT(t.id), 0)::BIGINT AS total_qr_codes,
        c.created_at,
        c.updated_at,
        (ct.id IS NOT NULL) AS is_template,
        ct.slug AS template_slug
    FROM cards c
    LEFT JOIN card_access_tokens t ON t.card_id = c.id
    LEFT JOIN content_templates ct ON ct.card_id = c.id
    WHERE c.user_id = auth.uid()
    GROUP BY c.id, ct.id, ct.slug
    ORDER BY c.created_at DESC;
END;
$$;
GRANT EXECUTE ON FUNCTION get_user_cards() TO authenticated;

-- Create a new card (more secure)
-- Modified to accept optional content_hash and translations for import
CREATE OR REPLACE FUNCTION create_card(
    p_name TEXT,
    p_description TEXT DEFAULT '',
    p_image_url TEXT DEFAULT NULL,
    p_original_image_url TEXT DEFAULT NULL,
    p_crop_parameters JSONB DEFAULT NULL,
    p_conversation_ai_enabled BOOLEAN DEFAULT FALSE,
    p_realtime_voice_enabled BOOLEAN DEFAULT FALSE,
    p_ai_instruction TEXT DEFAULT '',
    p_ai_knowledge_base TEXT DEFAULT '',
    p_ai_welcome_general TEXT DEFAULT '',
    p_ai_welcome_item TEXT DEFAULT '',
    p_qr_code_position TEXT DEFAULT 'BR',
    p_original_language VARCHAR(10) DEFAULT 'en',
    p_content_hash TEXT DEFAULT NULL,  -- For import: preserve original hash
    p_translations JSONB DEFAULT NULL,  -- For import: restore translations
    p_content_mode TEXT DEFAULT 'list',  -- Content rendering mode: single, grid, list, cards
    p_is_grouped BOOLEAN DEFAULT FALSE,  -- Whether content is organized into categories
    p_group_display TEXT DEFAULT 'expanded',  -- How grouped items display: expanded or collapsed
    p_billing_type TEXT DEFAULT 'digital',  -- Billing model: digital per-session subscription
    p_default_daily_session_limit INTEGER DEFAULT 500,  -- Default daily session limit for new QR codes (default: 500)
    p_metadata JSONB DEFAULT '{}'  -- Extensible metadata for future features
) RETURNS UUID LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_card_id UUID;
    v_check JSONB;
BEGIN
    -- Check subscription limit
    v_check := can_create_experience(auth.uid());
    IF NOT (v_check->>'can_create')::BOOLEAN THEN
        RAISE EXCEPTION '%', (v_check->>'message');
    END IF;

    INSERT INTO cards (
        user_id,
        name,
        description,
        image_url,
        original_image_url,
        crop_parameters,
        conversation_ai_enabled,
        realtime_voice_enabled,
        ai_instruction,
        ai_knowledge_base,
        ai_welcome_general,
        ai_welcome_item,
        qr_code_position,
        original_language,
        content_hash,  -- May be NULL (trigger calculates) or provided (import)
        translations,  -- May be NULL (normal) or provided (import)
        content_mode,
        is_grouped,
        group_display,
        billing_type,
        default_daily_session_limit,
        metadata
    ) VALUES (
        auth.uid(),
        p_name,
        p_description,
        p_image_url,
        p_original_image_url,
        p_crop_parameters,
        p_conversation_ai_enabled,
        COALESCE(p_realtime_voice_enabled, FALSE),
        p_ai_instruction,
        p_ai_knowledge_base,
        COALESCE(p_ai_welcome_general, ''),
        COALESCE(p_ai_welcome_item, ''),
        p_qr_code_position::"QRCodePosition",
        p_original_language,
        p_content_hash,  -- Trigger will calculate if NULL
        COALESCE(p_translations, '{}'::JSONB),  -- Default to empty object
        COALESCE(p_content_mode, 'list'),
        COALESCE(p_is_grouped, FALSE),
        COALESCE(p_group_display, 'expanded'),
        'digital',
        COALESCE(p_default_daily_session_limit, 500),
        COALESCE(p_metadata, '{}'::JSONB)
    )
    RETURNING id INTO v_card_id;
    
    -- Automatically create a default enabled access token (QR code) for all projects
    -- Every project must have at least one QR code
    INSERT INTO card_access_tokens (
        card_id,
        name,
        access_token,
        is_enabled,
        daily_session_limit
    ) VALUES (
        v_card_id,
        'Default',
        substring(replace(gen_random_uuid()::text, '-', ''), 1, 12),
        true,  -- Enabled by default
        COALESCE(p_default_daily_session_limit, 500)
    );
    
    -- Log operation
    IF p_translations IS NOT NULL AND p_translations != '{}'::JSONB THEN
        PERFORM log_operation(format('Imported card with translations: %s', p_name));
    ELSE
        PERFORM log_operation(format('Created %s card: %s', p_billing_type, p_name));
    END IF;
    
    RETURN v_card_id;
END;
$$;
GRANT EXECUTE ON FUNCTION create_card(TEXT, TEXT, TEXT, TEXT, JSONB, BOOLEAN, BOOLEAN, TEXT, TEXT, TEXT, TEXT, TEXT, VARCHAR, TEXT, JSONB, TEXT, BOOLEAN, TEXT, TEXT, INTEGER, JSONB) TO authenticated;

-- Get a card by ID (more secure, relies on RLS policy)
-- Session stats are computed from card_access_tokens table
CREATE OR REPLACE FUNCTION get_card_by_id(p_card_id UUID)
RETURNS TABLE (
    id UUID,
    user_id UUID,
    name TEXT,
    description TEXT,
    qr_code_position TEXT,
    image_url TEXT,
    original_image_url TEXT,
    crop_parameters JSONB,
    conversation_ai_enabled BOOLEAN,
    realtime_voice_enabled BOOLEAN,
    ai_instruction TEXT,
    ai_knowledge_base TEXT,
    ai_welcome_general TEXT,
    ai_welcome_item TEXT,
    translations JSONB,
    original_language VARCHAR(10),
    content_hash TEXT,
    last_content_update TIMESTAMPTZ,
    content_mode TEXT,
    is_grouped BOOLEAN,
    group_display TEXT,
    billing_type TEXT,
    default_daily_session_limit INTEGER,
    metadata JSONB,
    -- Computed from access tokens
    total_sessions BIGINT,
    monthly_sessions BIGINT,
    daily_sessions BIGINT,
    active_qr_codes BIGINT,
    total_qr_codes BIGINT,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ
) LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
    RETURN QUERY
    SELECT
        c.id,
        c.user_id,
        c.name,
        c.description,
        c.qr_code_position::TEXT,
        c.image_url,
        c.original_image_url,
        c.crop_parameters,
        c.conversation_ai_enabled,
        c.realtime_voice_enabled,
        c.ai_instruction,
        c.ai_knowledge_base,
        c.ai_welcome_general,
        c.ai_welcome_item,
        c.translations,
        c.original_language,
        c.content_hash,
        c.last_content_update,
        c.content_mode,
        c.is_grouped,
        c.group_display,
        c.billing_type,
        c.default_daily_session_limit,
        c.metadata,
        -- Aggregate stats from access tokens
        COALESCE(SUM(t.total_sessions), 0)::BIGINT AS total_sessions,
        COALESCE(SUM(t.monthly_sessions), 0)::BIGINT AS monthly_sessions,
        COALESCE(SUM(t.daily_sessions), 0)::BIGINT AS daily_sessions,
        COALESCE(COUNT(t.id) FILTER (WHERE t.is_enabled), 0)::BIGINT AS active_qr_codes,
        COALESCE(COUNT(t.id), 0)::BIGINT AS total_qr_codes,
        c.created_at,
        c.updated_at
    FROM cards c
    LEFT JOIN card_access_tokens t ON t.card_id = c.id
    WHERE c.id = p_card_id
    GROUP BY c.id;
    -- No need to check user_id = auth.uid() as RLS policy will handle this
END;
$$;
GRANT EXECUTE ON FUNCTION get_card_by_id(UUID) TO authenticated;

-- Update an existing card (more secure)
CREATE OR REPLACE FUNCTION update_card(
    p_card_id UUID,
    p_name TEXT DEFAULT NULL,
    p_description TEXT DEFAULT NULL,
    p_image_url TEXT DEFAULT NULL,
    p_original_image_url TEXT DEFAULT NULL,
    p_crop_parameters JSONB DEFAULT NULL,
    p_conversation_ai_enabled BOOLEAN DEFAULT NULL,
    p_realtime_voice_enabled BOOLEAN DEFAULT NULL,
    p_ai_instruction TEXT DEFAULT NULL,
    p_ai_knowledge_base TEXT DEFAULT NULL,
    p_ai_welcome_general TEXT DEFAULT NULL,
    p_ai_welcome_item TEXT DEFAULT NULL,
    p_qr_code_position TEXT DEFAULT NULL,
    p_original_language VARCHAR(10) DEFAULT NULL,
    p_content_mode TEXT DEFAULT NULL,
    p_is_grouped BOOLEAN DEFAULT NULL,
    p_group_display TEXT DEFAULT NULL,
    p_billing_type TEXT DEFAULT NULL,
    p_default_daily_session_limit INTEGER DEFAULT NULL,
    p_metadata JSONB DEFAULT NULL
) RETURNS BOOLEAN LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_old_record RECORD;
    v_changes_made JSONB := '{}';
    has_changes BOOLEAN := FALSE;
BEGIN
    -- Get existing card data before update for audit logging
    SELECT 
        id,
        name,
        description,
        image_url,
        original_image_url,
        crop_parameters,
        conversation_ai_enabled,
        realtime_voice_enabled,
        ai_instruction,
        ai_knowledge_base,
        ai_welcome_general,
        ai_welcome_item,
        qr_code_position,
        original_language,
        content_mode,
        is_grouped,
        group_display,
        billing_type,
        default_daily_session_limit,
        metadata,
        user_id,
        updated_at
    INTO v_old_record
    FROM cards
    WHERE id = p_card_id AND user_id = auth.uid();
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Card not found or not authorized to update.';
    END IF;
    
    -- Track changes for audit logging
    IF p_name IS NOT NULL AND p_name != v_old_record.name THEN
        v_changes_made := v_changes_made || jsonb_build_object('name', jsonb_build_object('from', v_old_record.name, 'to', p_name));
        has_changes := TRUE;
    END IF;
    
    IF p_description IS NOT NULL AND p_description != v_old_record.description THEN
        v_changes_made := v_changes_made || jsonb_build_object('description', jsonb_build_object('from', v_old_record.description, 'to', p_description));
        has_changes := TRUE;
    END IF;
    
    IF p_image_url IS NOT NULL AND p_image_url != v_old_record.image_url THEN
        v_changes_made := v_changes_made || jsonb_build_object('image_url', jsonb_build_object('from', v_old_record.image_url, 'to', p_image_url));
        has_changes := TRUE;
    END IF;
    
    IF p_original_image_url IS NOT NULL AND p_original_image_url != v_old_record.original_image_url THEN
        v_changes_made := v_changes_made || jsonb_build_object('original_image_url', jsonb_build_object('from', v_old_record.original_image_url, 'to', p_original_image_url));
        has_changes := TRUE;
    END IF;
    
    IF p_crop_parameters IS NOT NULL AND p_crop_parameters != v_old_record.crop_parameters THEN
        v_changes_made := v_changes_made || jsonb_build_object('crop_parameters', jsonb_build_object('from', v_old_record.crop_parameters, 'to', p_crop_parameters));
        has_changes := TRUE;
    END IF;
    
    IF p_conversation_ai_enabled IS NOT NULL AND p_conversation_ai_enabled != v_old_record.conversation_ai_enabled THEN
        v_changes_made := v_changes_made || jsonb_build_object('conversation_ai_enabled', jsonb_build_object('from', v_old_record.conversation_ai_enabled, 'to', p_conversation_ai_enabled));
        has_changes := TRUE;
    END IF;

    IF p_realtime_voice_enabled IS NOT NULL AND p_realtime_voice_enabled IS DISTINCT FROM v_old_record.realtime_voice_enabled THEN
        v_changes_made := v_changes_made || jsonb_build_object('realtime_voice_enabled', jsonb_build_object('from', v_old_record.realtime_voice_enabled, 'to', p_realtime_voice_enabled));
        has_changes := TRUE;
    END IF;

    IF p_ai_instruction IS NOT NULL AND p_ai_instruction != v_old_record.ai_instruction THEN
        v_changes_made := v_changes_made || jsonb_build_object('ai_instruction', jsonb_build_object('from', v_old_record.ai_instruction, 'to', p_ai_instruction));
        has_changes := TRUE;
    END IF;
    
    IF p_ai_knowledge_base IS NOT NULL AND p_ai_knowledge_base != v_old_record.ai_knowledge_base THEN
        v_changes_made := v_changes_made || jsonb_build_object('ai_knowledge_base', jsonb_build_object('from', v_old_record.ai_knowledge_base, 'to', p_ai_knowledge_base));
        has_changes := TRUE;
    END IF;
    
    IF p_ai_welcome_general IS NOT NULL AND p_ai_welcome_general != v_old_record.ai_welcome_general THEN
        v_changes_made := v_changes_made || jsonb_build_object('ai_welcome_general', jsonb_build_object('from', v_old_record.ai_welcome_general, 'to', p_ai_welcome_general));
        has_changes := TRUE;
    END IF;
    
    IF p_ai_welcome_item IS NOT NULL AND p_ai_welcome_item != v_old_record.ai_welcome_item THEN
        v_changes_made := v_changes_made || jsonb_build_object('ai_welcome_item', jsonb_build_object('from', v_old_record.ai_welcome_item, 'to', p_ai_welcome_item));
        has_changes := TRUE;
    END IF;
    
    IF p_qr_code_position IS NOT NULL AND p_qr_code_position != v_old_record.qr_code_position::TEXT THEN
        v_changes_made := v_changes_made || jsonb_build_object('qr_code_position', jsonb_build_object('from', v_old_record.qr_code_position, 'to', p_qr_code_position));
        has_changes := TRUE;
    END IF;
    
    IF p_original_language IS NOT NULL AND p_original_language != v_old_record.original_language THEN
        v_changes_made := v_changes_made || jsonb_build_object('original_language', jsonb_build_object('from', v_old_record.original_language, 'to', p_original_language));
        has_changes := TRUE;
    END IF;
    
    IF p_content_mode IS NOT NULL AND p_content_mode != v_old_record.content_mode THEN
        v_changes_made := v_changes_made || jsonb_build_object('content_mode', jsonb_build_object('from', v_old_record.content_mode, 'to', p_content_mode));
        has_changes := TRUE;
    END IF;
    
    IF p_is_grouped IS NOT NULL AND p_is_grouped != v_old_record.is_grouped THEN
        v_changes_made := v_changes_made || jsonb_build_object('is_grouped', jsonb_build_object('from', v_old_record.is_grouped, 'to', p_is_grouped));
        has_changes := TRUE;
    END IF;
    
    IF p_group_display IS NOT NULL AND p_group_display != v_old_record.group_display THEN
        v_changes_made := v_changes_made || jsonb_build_object('group_display', jsonb_build_object('from', v_old_record.group_display, 'to', p_group_display));
        has_changes := TRUE;
    END IF;
    
    -- NOTE: billing_type cannot be changed after card creation
    -- Silently ignore any attempt to change billing_type
    
    -- Track default_daily_session_limit changes (only for digital cards)
    IF p_default_daily_session_limit IS NOT NULL AND (v_old_record.default_daily_session_limit IS NULL OR p_default_daily_session_limit != v_old_record.default_daily_session_limit) THEN
        v_changes_made := v_changes_made || jsonb_build_object('default_daily_session_limit', jsonb_build_object('from', v_old_record.default_daily_session_limit, 'to', p_default_daily_session_limit));
        has_changes := TRUE;
    END IF;

    IF p_metadata IS NOT NULL AND p_metadata IS DISTINCT FROM v_old_record.metadata THEN
        v_changes_made := v_changes_made || jsonb_build_object('metadata', 'updated');
        has_changes := TRUE;
    END IF;

    -- Only proceed if there are actual changes
    IF NOT has_changes THEN
        RETURN TRUE; -- No changes to make
    END IF;
    
    -- Perform the update
    -- NOTE: billing_type is NOT updated - it's immutable after creation
    UPDATE cards
    SET 
        name = COALESCE(p_name, name),
        description = COALESCE(p_description, description),
        image_url = COALESCE(p_image_url, image_url),
        original_image_url = COALESCE(p_original_image_url, original_image_url),
        crop_parameters = COALESCE(p_crop_parameters, crop_parameters),
        conversation_ai_enabled = COALESCE(p_conversation_ai_enabled, conversation_ai_enabled),
        realtime_voice_enabled = COALESCE(p_realtime_voice_enabled, realtime_voice_enabled),
        ai_instruction = COALESCE(p_ai_instruction, ai_instruction),
        ai_knowledge_base = COALESCE(p_ai_knowledge_base, ai_knowledge_base),
        ai_welcome_general = COALESCE(p_ai_welcome_general, ai_welcome_general),
        ai_welcome_item = COALESCE(p_ai_welcome_item, ai_welcome_item),
        qr_code_position = COALESCE(p_qr_code_position::"QRCodePosition", qr_code_position),
        original_language = COALESCE(p_original_language, original_language),
        content_mode = COALESCE(p_content_mode, content_mode),
        is_grouped = COALESCE(p_is_grouped, is_grouped),
        group_display = COALESCE(p_group_display, group_display),
        -- billing_type is immutable - not updated here
        default_daily_session_limit = COALESCE(p_default_daily_session_limit, default_daily_session_limit),
        metadata = COALESCE(p_metadata, metadata),
        updated_at = now()
    WHERE id = p_card_id AND user_id = auth.uid();
    
    -- Log operation
    PERFORM log_operation(format('Updated card: %s', COALESCE(p_name, v_old_record.name)));
    
    RETURN TRUE;
END;
$$;
GRANT EXECUTE ON FUNCTION update_card(UUID, TEXT, TEXT, TEXT, TEXT, JSONB, BOOLEAN, BOOLEAN, TEXT, TEXT, TEXT, TEXT, TEXT, VARCHAR, TEXT, BOOLEAN, TEXT, TEXT, INTEGER, JSONB) TO authenticated;

-- Delete a card (more secure)
CREATE OR REPLACE FUNCTION delete_card(p_card_id UUID)
RETURNS BOOLEAN LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_card_record RECORD;
BEGIN
    -- Get card information before deletion for audit logging
    SELECT 
        c.id,
        c.name,
        c.description,
        c.image_url,
        c.conversation_ai_enabled,
        c.ai_instruction,
        c.ai_knowledge_base,
        c.qr_code_position,
        c.user_id,
        c.created_at,
        c.updated_at
    INTO v_card_record
    FROM cards c
    WHERE c.id = p_card_id AND c.user_id = auth.uid();
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Card not found or not authorized to delete.';
    END IF;
    
    -- Perform the deletion
    DELETE FROM cards WHERE id = p_card_id AND user_id = auth.uid();
    
    -- Log operation
    PERFORM log_operation(format('Deleted card: %s', v_card_record.name));

    RETURN TRUE;
END;
$$;
GRANT EXECUTE ON FUNCTION delete_card(UUID) TO authenticated;

-- NOTE: toggle_card_access and regenerate_access_token functions have been moved to
-- 13_access_tokens.sql as toggle_access_token and refresh_access_token since
-- access control is now per-QR-code (access token) rather than per-card.

-- =================================================================
-- GET CARD WITH FULL CONTENT (P0 Features - Platform Optimization Roadmap)
-- =================================================================

-- Get card with all content items
-- Purpose: Fetch complete card data with all content items for duplication
-- Used by: Card duplication feature
CREATE OR REPLACE FUNCTION get_card_with_content(
  p_card_id UUID
) RETURNS TABLE (
  -- Card fields
  card_id UUID,
  card_name TEXT,
  card_description TEXT,
  card_image_url TEXT,
  card_original_image_url TEXT,
  card_crop_parameters JSONB,
  card_conversation_ai_enabled BOOLEAN,
  card_realtime_voice_enabled BOOLEAN,
  card_ai_instruction TEXT,
  card_ai_knowledge_base TEXT,
  card_ai_welcome_general TEXT,
  card_ai_welcome_item TEXT,
  card_original_language TEXT,
  card_translations JSONB,
  card_content_mode TEXT,
  card_is_grouped BOOLEAN,
  card_group_display TEXT,
  card_billing_type TEXT,
  card_default_daily_session_limit INT,
  card_qr_code_position TEXT,
  card_metadata JSONB,
  -- Content items array
  content_items JSONB
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id UUID;
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

  -- Return card with content items
  RETURN QUERY
  SELECT
    c.id,
    c.name,
    c.description,
    c.image_url,
    c.original_image_url,
    c.crop_parameters,
    c.conversation_ai_enabled,
    c.realtime_voice_enabled,
    c.ai_instruction,
    c.ai_knowledge_base,
    c.ai_welcome_general,
    c.ai_welcome_item,
    c.original_language::TEXT,  -- Cast VARCHAR(10) to TEXT
    c.translations,
    c.content_mode,
    c.is_grouped,
    c.group_display,
    c.billing_type,
    c.default_daily_session_limit,
    c.qr_code_position::TEXT,  -- Cast enum to TEXT
    c.metadata,
    -- Aggregate content items into JSONB array
    COALESCE(
      (
        SELECT jsonb_agg(
          jsonb_build_object(
            'id', ci.id,
            'name', ci.name,
            'content', ci.content,
            'parent_id', ci.parent_id,
            'image_url', ci.image_url,
            'ai_knowledge_base', ci.ai_knowledge_base,
            'sort_order', ci.sort_order,
            'translations', ci.translations,
            'crop_parameters', ci.crop_parameters
          ) ORDER BY ci.sort_order
        )
        FROM content_items ci
        WHERE ci.card_id = c.id
      ),
      '[]'::JSONB
    ) as content_items
  FROM cards c
  WHERE c.id = p_card_id;

  -- Log operation
  PERFORM log_operation(format('Retrieved card with content for duplication: %s', (SELECT name FROM cards WHERE id = p_card_id)));

END;
$$;
GRANT EXECUTE ON FUNCTION get_card_with_content(UUID) TO authenticated;