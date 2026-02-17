-- Combined Stored Procedures
-- Generated: Tue Feb 17 20:13:27 HKT 2026

-- =================================================================
-- CLIENT-SIDE PROCEDURES
-- =================================================================

-- File: 00_logging.sql
-- -----------------------------------------------------------------
DROP FUNCTION IF EXISTS log_operation CASCADE;
DROP FUNCTION IF EXISTS get_operations_log CASCADE;
DROP FUNCTION IF EXISTS get_operations_log_stats CASCADE;

-- =============================================
-- Logging Helper Functions
-- Simple unified logging for all write operations
-- =============================================

-- Helper function to log operations
-- This should be called from any stored procedure that performs write operations
CREATE OR REPLACE FUNCTION log_operation(
    p_operation TEXT
) RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_user_id UUID;
    v_user_role "UserRole";
BEGIN
    -- Get current user ID
    v_user_id := auth.uid();
    
    -- Skip logging if no authenticated user (shouldn't happen in normal operations)
    IF v_user_id IS NULL THEN
        RETURN;
    END IF;
    
    -- Get user role from auth.users metadata
    SELECT COALESCE(
        (raw_user_meta_data->>'role')::"UserRole",
        'user'::"UserRole" -- Default to 'user' if role not set
    ) INTO v_user_role
    FROM auth.users
    WHERE id = v_user_id;
    
    -- Insert log entry
    INSERT INTO operations_log (user_id, user_role, operation)
    VALUES (v_user_id, v_user_role, p_operation);
    
EXCEPTION
    WHEN OTHERS THEN
        -- Silently fail logging to not break the main operation
        -- This ensures logging failures don't affect core functionality
        RAISE WARNING 'Failed to log operation: %', SQLERRM;
END;
$$;

-- Function to get recent operations log (admin only)
-- PERFORMANCE: Hard limit cap prevents runaway queries
CREATE OR REPLACE FUNCTION get_operations_log(
    p_limit INTEGER DEFAULT 100,
    p_offset INTEGER DEFAULT 0,
    p_user_id UUID DEFAULT NULL,
    p_user_role "UserRole" DEFAULT NULL,
    p_search_query TEXT DEFAULT NULL,
    p_start_date TIMESTAMPTZ DEFAULT NULL,
    p_end_date TIMESTAMPTZ DEFAULT NULL
)
RETURNS TABLE (
    id UUID,
    user_id UUID,
    user_email TEXT,
    user_role "UserRole",
    operation TEXT,
    created_at TIMESTAMPTZ
) LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    caller_role TEXT;
    -- PERFORMANCE: Maximum allowed limit to prevent abuse
    MAX_LIMIT CONSTANT INTEGER := 1000;
    v_effective_limit INTEGER;
BEGIN
    -- Check if the caller is an admin
    SELECT raw_user_meta_data->>'role' INTO caller_role
    FROM auth.users
    WHERE auth.users.id = auth.uid();

    IF caller_role != 'admin' THEN
        RAISE EXCEPTION 'Only admins can view operations log.';
    END IF;

    -- SECURITY: Cap the limit to prevent excessive data retrieval
    v_effective_limit := LEAST(COALESCE(p_limit, 100), MAX_LIMIT);

    RETURN QUERY
    SELECT 
        ol.id,
        ol.user_id,
        au.email::TEXT AS user_email,  -- Cast to TEXT to match return type
        ol.user_role,
        ol.operation,
        ol.created_at
    FROM operations_log ol
    LEFT JOIN auth.users au ON ol.user_id = au.id
    WHERE 
        (p_user_id IS NULL OR ol.user_id = p_user_id)
        AND (p_user_role IS NULL OR ol.user_role = p_user_role)
        AND (p_search_query IS NULL OR 
             ol.operation ILIKE '%' || p_search_query || '%' OR
             au.email ILIKE '%' || p_search_query || '%')
        AND (p_start_date IS NULL OR ol.created_at >= p_start_date)
        AND (p_end_date IS NULL OR ol.created_at <= p_end_date)
    ORDER BY ol.created_at DESC
    LIMIT v_effective_limit OFFSET p_offset;
END;
$$;

-- Function to get operations log summary statistics (admin only)
CREATE OR REPLACE FUNCTION get_operations_log_stats()
RETURNS TABLE (
    total_operations BIGINT,
    operations_today BIGINT,
    operations_this_week BIGINT,
    operations_this_month BIGINT,
    admin_operations BIGINT,
    card_issuer_operations BIGINT,
    user_operations BIGINT
) LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    caller_role TEXT;
BEGIN
    -- Check if the caller is an admin
    SELECT raw_user_meta_data->>'role' INTO caller_role
    FROM auth.users
    WHERE auth.users.id = auth.uid();

    IF caller_role != 'admin' THEN
        RAISE EXCEPTION 'Only admins can view operations log statistics.';
    END IF;

    RETURN QUERY
    SELECT 
        (SELECT COUNT(*) FROM operations_log) as total_operations,
        (SELECT COUNT(*) FROM operations_log WHERE created_at >= CURRENT_DATE) as operations_today,
        (SELECT COUNT(*) FROM operations_log WHERE created_at >= CURRENT_DATE - INTERVAL '7 days') as operations_this_week,
        (SELECT COUNT(*) FROM operations_log WHERE created_at >= CURRENT_DATE - INTERVAL '30 days') as operations_this_month,
        (SELECT COUNT(*) FROM operations_log WHERE user_role = 'admin') as admin_operations,
        (SELECT COUNT(*) FROM operations_log WHERE user_role = 'cardIssuer') as card_issuer_operations,
        (SELECT COUNT(*) FROM operations_log WHERE user_role = 'user') as user_operations;
END;
$$;



-- File: 01_auth_functions.sql
-- -----------------------------------------------------------------
DROP FUNCTION IF EXISTS handle_new_user CASCADE;
DROP FUNCTION IF EXISTS get_user_role CASCADE;

-- =================================================================
-- AUTH FUNCTIONS
-- Functions for user authentication, role management, and triggers
-- =================================================================

-- Function to set default role for new users (from triggers.sql)
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER -- Required to modify auth.users table
SET search_path = public
AS $$
DECLARE
    default_role TEXT := 'card_issuer';
BEGIN
  -- Update new user with default role
  UPDATE auth.users
  SET raw_user_meta_data = raw_user_meta_data || jsonb_build_object('role', default_role)
  WHERE id = NEW.id;
  
  -- Log new user registration
  INSERT INTO operations_log (user_id, user_role, operation)
  VALUES (
    NEW.id,
    default_role::"UserRole",
    'New user registered: ' || NEW.email
  );
  
  RETURN NEW;
END;
$$;

-- Grant execute permission for handle_new_user (from triggers.sql)
GRANT EXECUTE ON FUNCTION public.handle_new_user() TO supabase_auth_admin;

-- Function to get user role (from auth_triggers.sql)
CREATE OR REPLACE FUNCTION public.get_user_role(user_id UUID)
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
  role TEXT;
BEGIN
  SELECT raw_user_meta_data->>'role' INTO role FROM auth.users WHERE id = user_id;
  RETURN role;
END;
$$;

-- Grant execute permission for get_user_role (from auth_triggers.sql)
GRANT EXECUTE ON FUNCTION public.get_user_role(UUID) TO postgres, anon, authenticated, service_role; 

-- File: 02_card_management.sql
-- -----------------------------------------------------------------
DROP FUNCTION IF EXISTS get_user_cards CASCADE;
DROP FUNCTION IF EXISTS create_card CASCADE;
DROP FUNCTION IF EXISTS get_card_by_id CASCADE;
DROP FUNCTION IF EXISTS update_card CASCADE;
DROP FUNCTION IF EXISTS delete_card CASCADE;
DROP FUNCTION IF EXISTS get_card_with_content CASCADE;

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

-- File: 03_content_management.sql
-- -----------------------------------------------------------------
DROP FUNCTION IF EXISTS get_card_content_items CASCADE;
DROP FUNCTION IF EXISTS get_content_item_by_id CASCADE;
DROP FUNCTION IF EXISTS create_content_item CASCADE;
DROP FUNCTION IF EXISTS update_content_item CASCADE;
DROP FUNCTION IF EXISTS update_content_item_order CASCADE;
DROP FUNCTION IF EXISTS delete_content_item CASCADE;
DROP FUNCTION IF EXISTS bulk_create_content_items CASCADE;
DROP FUNCTION IF EXISTS bulk_delete_content_items CASCADE;

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


-- File: 03b_content_migration.sql
-- -----------------------------------------------------------------
DROP FUNCTION IF EXISTS migrate_content_to_grouped CASCADE;
DROP FUNCTION IF EXISTS migrate_content_to_flat CASCADE;
DROP FUNCTION IF EXISTS move_content_item_to_parent CASCADE;

-- =================================================================
-- CONTENT ITEM MIGRATION FUNCTIONS
-- Functions for migrating content between flat and grouped modes
-- =================================================================

-- Migrate content from flat mode to grouped mode
-- Creates a default category and moves all top-level items under it
CREATE OR REPLACE FUNCTION migrate_content_to_grouped(
    p_card_id UUID,
    p_default_category_name TEXT DEFAULT 'Default Category'
) RETURNS JSON LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_user_id UUID;
    v_category_id UUID;
    v_items_moved INTEGER := 0;
BEGIN
    -- Check if the user owns the card
    SELECT user_id INTO v_user_id
    FROM cards
    WHERE id = p_card_id;
    
    IF v_user_id != auth.uid() THEN
        RAISE EXCEPTION 'Not authorized to migrate content for this card';
    END IF;
    
    -- Count top-level items (potential items to move)
    SELECT COUNT(*) INTO v_items_moved
    FROM content_items
    WHERE card_id = p_card_id AND parent_id IS NULL;
    
    -- If no items to migrate, return early
    IF v_items_moved = 0 THEN
        RETURN json_build_object(
            'success', true,
            'message', 'No items to migrate',
            'category_id', NULL,
            'items_moved', 0
        );
    END IF;
    
    -- Create the default category
    INSERT INTO content_items (
        card_id,
        parent_id,
        name,
        content,
        sort_order
    ) VALUES (
        p_card_id,
        NULL,
        p_default_category_name,
        '',
        1
    )
    RETURNING id INTO v_category_id;
    
    -- Move all existing top-level items under the new category
    -- (except the category we just created)
    UPDATE content_items
    SET 
        parent_id = v_category_id,
        updated_at = now()
    WHERE card_id = p_card_id 
    AND parent_id IS NULL 
    AND id != v_category_id;
    
    -- Re-number sort orders for moved items
    WITH numbered AS (
        SELECT id, ROW_NUMBER() OVER (ORDER BY sort_order, created_at) as new_order
        FROM content_items
        WHERE card_id = p_card_id AND parent_id = v_category_id
    )
    UPDATE content_items ci
    SET sort_order = numbered.new_order
    FROM numbered
    WHERE ci.id = numbered.id;
    
    -- Log operation
    PERFORM log_operation(format('Migrated %s items to grouped mode with category: %s', v_items_moved, p_default_category_name));
    
    RETURN json_build_object(
        'success', true,
        'message', format('Migrated %s items to grouped mode', v_items_moved),
        'category_id', v_category_id,
        'items_moved', v_items_moved
    );
END;
$$;
GRANT EXECUTE ON FUNCTION migrate_content_to_grouped(UUID, TEXT) TO authenticated;

-- Migrate content from grouped mode to flat mode
-- Moves all child items to top level, optionally removes empty categories
CREATE OR REPLACE FUNCTION migrate_content_to_flat(
    p_card_id UUID,
    p_remove_empty_categories BOOLEAN DEFAULT true
) RETURNS JSON LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_user_id UUID;
    v_items_moved INTEGER := 0;
    v_categories_removed INTEGER := 0;
BEGIN
    -- Check if the user owns the card
    SELECT user_id INTO v_user_id
    FROM cards
    WHERE id = p_card_id;
    
    IF v_user_id != auth.uid() THEN
        RAISE EXCEPTION 'Not authorized to migrate content for this card';
    END IF;
    
    -- Count items that will be moved (items with parent_id)
    SELECT COUNT(*) INTO v_items_moved
    FROM content_items
    WHERE card_id = p_card_id AND parent_id IS NOT NULL;
    
    -- Move all child items to top level
    UPDATE content_items
    SET 
        parent_id = NULL,
        updated_at = now()
    WHERE card_id = p_card_id AND parent_id IS NOT NULL;
    
    -- Optionally remove categories (items that had children but now are empty parents)
    -- We identify categories as items that have no content and were originally parents
    IF p_remove_empty_categories THEN
        -- Delete categories (items with empty content that don't have images)
        WITH deleted AS (
            DELETE FROM content_items
            WHERE card_id = p_card_id 
            AND parent_id IS NULL
            AND (content IS NULL OR content = '')
            AND image_url IS NULL
            RETURNING id
        )
        SELECT COUNT(*) INTO v_categories_removed FROM deleted;
    END IF;
    
    -- Re-number sort orders for all remaining top-level items
    WITH numbered AS (
        SELECT id, ROW_NUMBER() OVER (ORDER BY sort_order, created_at) as new_order
        FROM content_items
        WHERE card_id = p_card_id AND parent_id IS NULL
    )
    UPDATE content_items ci
    SET sort_order = numbered.new_order
    FROM numbered
    WHERE ci.id = numbered.id;
    
    -- Log operation
    PERFORM log_operation(format('Migrated to flat mode: %s items moved, %s categories removed', v_items_moved, v_categories_removed));
    
    RETURN json_build_object(
        'success', true,
        'message', format('Migrated to flat mode'),
        'items_moved', v_items_moved,
        'categories_removed', v_categories_removed
    );
END;
$$;
GRANT EXECUTE ON FUNCTION migrate_content_to_flat(UUID, BOOLEAN) TO authenticated;

-- Move a content item to a different parent (for cross-parent drag & drop)
-- new_parent_id can be NULL to move to top level
CREATE OR REPLACE FUNCTION move_content_item_to_parent(
    p_content_item_id UUID,
    p_new_parent_id UUID DEFAULT NULL,
    p_new_sort_order INTEGER DEFAULT NULL
) RETURNS JSON LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_user_id UUID;
    v_card_id UUID;
    v_old_parent_id UUID;
    v_next_sort_order INTEGER;
    v_item_name TEXT;
BEGIN
    -- Get content item details and check ownership
    SELECT c.user_id, ci.card_id, ci.parent_id, ci.name 
    INTO v_user_id, v_card_id, v_old_parent_id, v_item_name
    FROM content_items ci
    JOIN cards c ON ci.card_id = c.id
    WHERE ci.id = p_content_item_id;
    
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Content item not found';
    END IF;
    
    IF v_user_id != auth.uid() THEN
        RAISE EXCEPTION 'Not authorized to move this content item';
    END IF;
    
    -- Prevent moving to self
    IF p_content_item_id = p_new_parent_id THEN
        RAISE EXCEPTION 'Cannot move an item to itself';
    END IF;
    
    -- If new parent specified, verify it exists and belongs to the same project
    IF p_new_parent_id IS NOT NULL THEN
        IF NOT EXISTS (
            SELECT 1 FROM content_items 
            WHERE id = p_new_parent_id 
            AND card_id = v_card_id
            AND parent_id IS NULL  -- Parent must be a top-level item (category)
        ) THEN
            RAISE EXCEPTION 'New parent must be a top-level category in the same project';
        END IF;
    END IF;
    
    -- Prevent circular references (moving a parent under its own child)
    IF p_new_parent_id IS NOT NULL THEN
        IF EXISTS (
            WITH RECURSIVE descendants AS (
                SELECT id, parent_id FROM content_items WHERE id = p_content_item_id
                UNION ALL
                SELECT ci.id, ci.parent_id 
                FROM content_items ci
                JOIN descendants d ON ci.parent_id = d.id
            )
            SELECT 1 FROM descendants WHERE id = p_new_parent_id
        ) THEN
            RAISE EXCEPTION 'Cannot create circular reference';
        END IF;
    END IF;
    
    -- Calculate next sort order if not provided
    IF p_new_sort_order IS NULL THEN
        SELECT COALESCE(MAX(sort_order), 0) + 1 INTO v_next_sort_order
        FROM content_items
        WHERE card_id = v_card_id 
        AND (
            (p_new_parent_id IS NULL AND parent_id IS NULL) OR 
            (p_new_parent_id IS NOT NULL AND parent_id = p_new_parent_id)
        );
    ELSE
        v_next_sort_order := p_new_sort_order;
    END IF;
    
    -- Update the content item's parent and sort order
    UPDATE content_items
    SET 
        parent_id = p_new_parent_id,
        sort_order = v_next_sort_order,
        updated_at = now()
    WHERE id = p_content_item_id;
    
    -- Re-number sort orders in the old parent's children (if old parent existed)
    IF v_old_parent_id IS NOT NULL THEN
        WITH numbered AS (
            SELECT id, ROW_NUMBER() OVER (ORDER BY sort_order, created_at) as new_order
            FROM content_items
            WHERE card_id = v_card_id AND parent_id = v_old_parent_id
        )
        UPDATE content_items ci
        SET sort_order = numbered.new_order
        FROM numbered
        WHERE ci.id = numbered.id;
    END IF;
    
    -- Log operation
    PERFORM log_operation(format('Moved content item "%s" to new parent', v_item_name));
    
    RETURN json_build_object(
        'success', true,
        'message', 'Item moved successfully',
        'item_id', p_content_item_id,
        'old_parent_id', v_old_parent_id,
        'new_parent_id', p_new_parent_id,
        'new_sort_order', v_next_sort_order
    );
END;
$$;
GRANT EXECUTE ON FUNCTION move_content_item_to_parent(UUID, UUID, INTEGER) TO authenticated;



-- File: 03c_content_pagination.sql
-- -----------------------------------------------------------------
DROP FUNCTION IF EXISTS get_card_content_items_paginated CASCADE;
DROP FUNCTION IF EXISTS get_content_item_full CASCADE;
DROP FUNCTION IF EXISTS get_public_content_items_paginated CASCADE;
DROP FUNCTION IF EXISTS get_public_content_item_full CASCADE;
DROP FUNCTION IF EXISTS get_content_items_count CASCADE;

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


-- File: 07_public_access.sql
-- -----------------------------------------------------------------
DROP FUNCTION IF EXISTS get_card_preview_access CASCADE;
DROP FUNCTION IF EXISTS get_card_preview_content CASCADE;

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


-- File: 10_template_library.sql
-- -----------------------------------------------------------------
DROP FUNCTION IF EXISTS list_content_templates CASCADE;
DROP FUNCTION IF EXISTS get_content_template CASCADE;
DROP FUNCTION IF EXISTS get_template_venue_types CASCADE;
DROP FUNCTION IF EXISTS import_content_template CASCADE;
DROP FUNCTION IF EXISTS create_template_from_card CASCADE;
DROP FUNCTION IF EXISTS update_template_settings CASCADE;
DROP FUNCTION IF EXISTS delete_content_template CASCADE;
DROP FUNCTION IF EXISTS toggle_template_status CASCADE;
DROP FUNCTION IF EXISTS admin_list_all_templates CASCADE;
DROP FUNCTION IF EXISTS batch_update_template_order CASCADE;
DROP FUNCTION IF EXISTS get_admin_template_cards CASCADE;
DROP FUNCTION IF EXISTS get_demo_templates CASCADE;

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
    p_venue_type TEXT DEFAULT NULL,
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
    venue_type TEXT,
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
        ct.venue_type,
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
        AND (p_venue_type IS NULL OR ct.venue_type = p_venue_type)
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
    venue_type TEXT,
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
        ct.venue_type,
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
-- Get available venue types for filtering
-- -----------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_template_venue_types()
RETURNS TABLE (
    venue_type TEXT,
    template_count BIGINT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ct.venue_type,
        COUNT(*)::BIGINT as template_count
    FROM content_templates ct
    WHERE ct.is_active = true AND ct.venue_type IS NOT NULL
    GROUP BY ct.venue_type
    ORDER BY template_count DESC, ct.venue_type ASC;
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
    v_check := can_create_experience(p_user_id);
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
    p_venue_type TEXT DEFAULT NULL,
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
        slug, card_id, venue_type, is_featured, sort_order
    ) VALUES (
        p_slug, p_card_id, p_venue_type, p_is_featured, p_sort_order
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
    p_venue_type TEXT DEFAULT NULL,
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
        venue_type = COALESCE(p_venue_type, venue_type),
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
    venue_type TEXT,
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
        ct.venue_type,
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
GRANT EXECUTE ON FUNCTION public.get_template_venue_types() TO authenticated;
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
    venue_type TEXT,
    thumbnail_url TEXT,
    content_mode TEXT,
    item_count BIGINT,
    access_url TEXT
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
        ct.venue_type,
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
        )::TEXT AS access_url
    FROM content_templates ct
    JOIN cards c ON ct.card_id = c.id
    WHERE ct.is_active = true
      AND ct.is_featured = true
      -- Only include templates that have at least one enabled access token
      AND EXISTS (
          SELECT 1 FROM card_access_tokens t 
          WHERE t.card_id = c.id AND t.is_enabled = true
      )
    ORDER BY ct.sort_order ASC, c.name ASC
    LIMIT p_limit;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_demo_templates(INTEGER, VARCHAR) TO anon;
GRANT EXECUTE ON FUNCTION public.get_demo_templates(INTEGER, VARCHAR) TO authenticated;


-- File: 11_admin_functions.sql
-- -----------------------------------------------------------------
DROP FUNCTION IF EXISTS admin_get_system_stats_enhanced CASCADE;
DROP FUNCTION IF EXISTS admin_get_all_users CASCADE;
DROP FUNCTION IF EXISTS admin_update_user_subscription CASCADE;
DROP FUNCTION IF EXISTS admin_get_subscription_stats CASCADE;
DROP FUNCTION IF EXISTS admin_update_user_role CASCADE;
DROP FUNCTION IF EXISTS admin_get_user_by_email CASCADE;
DROP FUNCTION IF EXISTS admin_get_user_cards CASCADE;
DROP FUNCTION IF EXISTS admin_get_card_content CASCADE;
DROP FUNCTION IF EXISTS get_admin_audit_logs CASCADE;

-- =================================================================
-- ADMIN FUNCTIONS
-- Functions for admin-only operations and system management
-- =================================================================

-- Enhanced system statistics function
CREATE OR REPLACE FUNCTION admin_get_system_stats_enhanced()
RETURNS TABLE (
    total_users BIGINT,
    total_cards BIGINT,
    daily_revenue_cents BIGINT,
    weekly_revenue_cents BIGINT,
    monthly_revenue_cents BIGINT,
    total_revenue_cents BIGINT,
    daily_new_users BIGINT,
    weekly_new_users BIGINT,
    monthly_new_users BIGINT,
    daily_new_cards BIGINT,
    weekly_new_cards BIGINT,
    monthly_new_cards BIGINT,
    -- AUDIT METRICS
    total_audit_entries BIGINT,
    critical_actions_today BIGINT,
    high_severity_actions_week BIGINT,
    unique_admin_users_month BIGINT,
    -- CARDS COUNT
    digital_cards_count BIGINT,
    -- ACCESS METRICS (from card_access_tokens and card_access_log)
    total_digital_scans BIGINT,
    daily_digital_scans BIGINT,
    weekly_digital_scans BIGINT,
    monthly_digital_scans BIGINT,
    digital_credits_consumed NUMERIC,
    -- CONTENT MODE DISTRIBUTION
    content_mode_single BIGINT,
    content_mode_list BIGINT,
    content_mode_grid BIGINT,
    content_mode_cards BIGINT,
    is_grouped_count BIGINT,
    -- SUBSCRIPTION METRICS (3 tiers: free, starter, premium)
    total_free_users BIGINT,
    total_starter_users BIGINT,
    total_premium_users BIGINT,
    active_subscriptions BIGINT,
    estimated_mrr_cents BIGINT,
    -- ACCESS LOG METRICS
    monthly_total_accesses BIGINT,
    monthly_overage_accesses BIGINT,
    -- QR CODE METRICS (Multi-QR system)
    total_qr_codes BIGINT,
    active_qr_codes BIGINT
) LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    caller_role TEXT;
BEGIN
    -- Check if the caller is an admin
    SELECT raw_user_meta_data->>'role' INTO caller_role
    FROM auth.users
    WHERE auth.users.id = auth.uid();

    IF caller_role != 'admin' THEN
        RAISE EXCEPTION 'Only admins can view system statistics.';
    END IF;

    RETURN QUERY
    SELECT
        -- User and content metrics
        (SELECT COUNT(*) FROM auth.users) as total_users,
        (SELECT COUNT(*) FROM cards) as total_cards,
        -- Revenue metrics (based on credit purchases + estimated MRR)
        -- Note: credit_purchases amount_usd is in dollars, so multiply by 100 to get cents
        (SELECT COALESCE(SUM(amount_usd * 100), 0)::BIGINT FROM credit_purchases WHERE status = 'completed' AND created_at >= CURRENT_DATE) as daily_revenue_cents,
        (SELECT COALESCE(SUM(amount_usd * 100), 0)::BIGINT FROM credit_purchases WHERE status = 'completed' AND created_at >= CURRENT_DATE - INTERVAL '7 days') as weekly_revenue_cents,
        (SELECT COALESCE(SUM(amount_usd * 100), 0)::BIGINT FROM credit_purchases WHERE status = 'completed' AND created_at >= CURRENT_DATE - INTERVAL '30 days') as monthly_revenue_cents,
        (SELECT COALESCE(SUM(amount_usd * 100), 0)::BIGINT FROM credit_purchases WHERE status = 'completed') as total_revenue_cents,
        -- Growth metrics
        (SELECT COUNT(*) FROM auth.users WHERE created_at >= CURRENT_DATE) as daily_new_users,
        (SELECT COUNT(*) FROM auth.users WHERE created_at >= CURRENT_DATE - INTERVAL '7 days') as weekly_new_users,
        (SELECT COUNT(*) FROM auth.users WHERE created_at >= CURRENT_DATE - INTERVAL '30 days') as monthly_new_users,
        (SELECT COUNT(*) FROM cards WHERE created_at >= CURRENT_DATE) as daily_new_cards,
        (SELECT COUNT(*) FROM cards WHERE created_at >= CURRENT_DATE - INTERVAL '7 days') as weekly_new_cards,
        (SELECT COUNT(*) FROM cards WHERE created_at >= CURRENT_DATE - INTERVAL '30 days') as monthly_new_cards,
        -- Operations log metrics
        (SELECT COUNT(*) FROM operations_log) as total_audit_entries,
        (SELECT COUNT(*) FROM operations_log WHERE operation LIKE '%Waived payment%' AND created_at >= CURRENT_DATE) as payment_waivers_today,
        (SELECT COUNT(*) FROM operations_log WHERE operation LIKE '%Changed user role%' AND created_at >= CURRENT_DATE - INTERVAL '7 days') as role_changes_week,
        (SELECT COUNT(DISTINCT user_id) FROM operations_log WHERE user_role = 'admin' AND created_at >= CURRENT_DATE - INTERVAL '30 days') as unique_admin_users_month,
        -- CARDS COUNT
        (SELECT COUNT(*) FROM cards) as digital_cards_count,
        -- ACCESS METRICS (from card_access_tokens and card_access_log)
        -- Note: Session counters now live in card_access_tokens table (Multi-QR refactor Dec 2025)
        (SELECT COALESCE(SUM(cat.total_sessions), 0)::BIGINT FROM card_access_tokens cat) as total_digital_scans,
        (SELECT COALESCE(SUM(cat.daily_sessions), 0)::BIGINT FROM card_access_tokens cat WHERE cat.last_session_date = CURRENT_DATE) as daily_digital_scans,
        -- Weekly/Monthly from card_access_log for consistency (source of truth for billing)
        (SELECT COUNT(*) FROM card_access_log WHERE accessed_at >= CURRENT_DATE - INTERVAL '7 days') as weekly_digital_scans,
        (SELECT COUNT(*) FROM card_access_log WHERE accessed_at >= CURRENT_DATE - INTERVAL '30 days') as monthly_digital_scans,
        -- Total session cost from access log (ai_enabled costs more)
        (SELECT COALESCE(SUM(session_cost_usd), 0)::NUMERIC FROM card_access_log) as digital_credits_consumed,
        -- CONTENT MODE DISTRIBUTION
        (SELECT COUNT(*) FROM cards WHERE content_mode = 'single') as content_mode_single,
        (SELECT COUNT(*) FROM cards WHERE content_mode = 'list') as content_mode_list,
        (SELECT COUNT(*) FROM cards WHERE content_mode = 'grid') as content_mode_grid,
        (SELECT COUNT(*) FROM cards WHERE content_mode = 'cards') as content_mode_cards,
        (SELECT COUNT(*) FROM cards WHERE is_grouped = true) as is_grouped_count,
        -- SUBSCRIPTION METRICS (3 tiers: free, starter, premium)
        -- Free = users with no subscription record OR tier = 'free'
        (SELECT COUNT(*) FROM auth.users u WHERE NOT EXISTS (SELECT 1 FROM subscriptions s WHERE s.user_id = u.id AND s.tier IN ('starter', 'premium'))) as total_free_users,
        (SELECT COUNT(*) FROM subscriptions WHERE tier = 'starter') as total_starter_users,
        (SELECT COUNT(*) FROM subscriptions WHERE tier = 'premium') as total_premium_users,
        (SELECT COUNT(*) FROM subscriptions WHERE tier IN ('starter', 'premium') AND status = 'active') as active_subscriptions,
        -- MRR: Starter=$40/month (4000 cents) + Premium=$280/month (28000 cents)
        (
            (SELECT COUNT(*) * 4000 FROM subscriptions WHERE tier = 'starter' AND status = 'active') +
            (SELECT COUNT(*) * 28000 FROM subscriptions WHERE tier = 'premium' AND status = 'active')
        )::BIGINT as estimated_mrr_cents,
        -- ACCESS LOG METRICS
        (SELECT COUNT(*) FROM card_access_log WHERE accessed_at >= date_trunc('month', CURRENT_DATE)) as monthly_total_accesses,
        (SELECT COUNT(*) FROM card_access_log WHERE accessed_at >= date_trunc('month', CURRENT_DATE) AND was_overage = true) as monthly_overage_accesses,
        -- QR CODE METRICS (Multi-QR system)
        (SELECT COUNT(*) FROM card_access_tokens) as total_qr_codes,
        (SELECT COUNT(*) FROM card_access_tokens WHERE is_enabled = true) as active_qr_codes;
END;
$$;

-- =================================================================
-- USER MANAGEMENT FUNCTIONS
-- =================================================================

-- Get all users with basic info, activity stats, and subscription data
CREATE OR REPLACE FUNCTION admin_get_all_users()
RETURNS TABLE (
    user_id UUID,
    user_email VARCHAR(255),
    role TEXT,
    cards_count INTEGER,
    created_at TIMESTAMP WITH TIME ZONE,
    last_sign_in_at TIMESTAMP WITH TIME ZONE,
    email_confirmed_at TIMESTAMP WITH TIME ZONE,
    -- Subscription fields
    subscription_tier TEXT,
    subscription_status TEXT,
    stripe_subscription_id TEXT,
    current_period_start TIMESTAMPTZ,
    current_period_end TIMESTAMPTZ,
    cancel_at_period_end BOOLEAN
)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    caller_role TEXT;
BEGIN
    -- Check if the caller is an admin
    SELECT raw_user_meta_data->>'role' INTO caller_role
    FROM auth.users
    WHERE auth.users.id = auth.uid();

    IF caller_role != 'admin' THEN
        RAISE EXCEPTION 'Only admins can view all users.';
    END IF;

    RETURN QUERY
    SELECT
        au.id as user_id,
        au.email as user_email,
        COALESCE(au.raw_user_meta_data->>'role', 'cardIssuer') as role,
        COUNT(DISTINCT c.id)::INTEGER as cards_count,
        au.created_at,
        au.last_sign_in_at,
        au.email_confirmed_at,
        -- Subscription data (default to 'free' if no subscription)
        COALESCE(s.tier::TEXT, 'free') as subscription_tier,
        COALESCE(s.status::TEXT, 'active') as subscription_status,
        s.stripe_subscription_id,
        s.current_period_start,
        s.current_period_end,
        COALESCE(s.cancel_at_period_end, false) as cancel_at_period_end
    FROM auth.users au
    LEFT JOIN cards c ON c.user_id = au.id
    LEFT JOIN subscriptions s ON s.user_id = au.id
    GROUP BY au.id, au.email, au.raw_user_meta_data, au.created_at, au.last_sign_in_at,
             au.email_confirmed_at, s.tier, s.status, s.stripe_subscription_id,
             s.current_period_start, s.current_period_end, s.cancel_at_period_end
    ORDER BY au.created_at DESC;
END;
$$;

-- Update user subscription tier (admin only)
-- This creates or updates a subscription record for manual tier management
CREATE OR REPLACE FUNCTION admin_update_user_subscription(
    p_user_id UUID,
    p_new_tier TEXT,
    p_reason TEXT,
    p_duration_months INTEGER DEFAULT NULL  -- NULL = permanent, number = specific months
)
RETURNS BOOLEAN
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    caller_role TEXT;
    v_user_email VARCHAR(255);
    v_old_tier TEXT;
    v_subscription_exists BOOLEAN;
    v_period_end TIMESTAMPTZ;
    v_duration_text TEXT;
BEGIN
    -- Check if the caller is an admin
    SELECT raw_user_meta_data->>'role' INTO caller_role
    FROM auth.users
    WHERE auth.users.id = auth.uid();

    IF caller_role != 'admin' THEN
        RAISE EXCEPTION 'Only admins can update user subscriptions.';
    END IF;

    -- Validate new tier
    IF p_new_tier NOT IN ('free', 'starter', 'premium') THEN
        RAISE EXCEPTION 'Invalid tier. Must be: free, starter, or premium.';
    END IF;

    -- Validate duration (must be positive if provided)
    IF p_duration_months IS NOT NULL AND p_duration_months <= 0 THEN
        RAISE EXCEPTION 'Duration must be a positive number of months.';
    END IF;

    -- Get current user info
    SELECT email INTO v_user_email
    FROM auth.users
    WHERE id = p_user_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'User not found.';
    END IF;

    -- Check if subscription exists
    SELECT EXISTS(SELECT 1 FROM subscriptions WHERE user_id = p_user_id) INTO v_subscription_exists;
    
    -- Block if user has active Stripe subscription (mutually exclusive with admin grants)
    IF v_subscription_exists THEN
        PERFORM 1 FROM subscriptions 
        WHERE user_id = p_user_id 
        AND stripe_subscription_id IS NOT NULL;
        
        IF FOUND THEN
            RAISE EXCEPTION 'Cannot grant privilege to user with active Stripe subscription. Please cancel their Stripe subscription first via Stripe Dashboard.';
        END IF;
    END IF;
    
    -- Get old tier if exists
    IF v_subscription_exists THEN
        SELECT tier::TEXT INTO v_old_tier
        FROM subscriptions
        WHERE user_id = p_user_id;
    ELSE
        v_old_tier := 'free';
    END IF;

    -- Calculate period end based on duration
    -- For paid tiers (starter/premium): use duration or NULL for permanent
    -- For free tier: always NULL (no period)
    IF p_new_tier = 'free' THEN
        v_period_end := NULL;
    ELSIF p_duration_months IS NULL THEN
        -- Permanent subscription (far future date)
        v_period_end := NOW() + INTERVAL '100 years';
    ELSE
        -- Specific duration
        v_period_end := NOW() + (p_duration_months || ' months')::INTERVAL;
    END IF;

    -- Create or update subscription (Stripe users already blocked above)
    IF v_subscription_exists THEN
        UPDATE subscriptions
        SET 
            tier = p_new_tier::"SubscriptionTier",
            status = 'active'::subscription_status,
            -- stripe_subscription_id stays NULL (admin-managed only)
            current_period_start = CASE 
                WHEN p_new_tier IN ('starter', 'premium') THEN NOW()
                ELSE NULL
            END,
            current_period_end = CASE 
                WHEN p_new_tier IN ('starter', 'premium') THEN v_period_end
                ELSE NULL
            END,
            cancel_at_period_end = false,
            updated_at = NOW()
        WHERE user_id = p_user_id;
    ELSE
        INSERT INTO subscriptions (
            user_id,
            tier,
            status,
            current_period_start,
            current_period_end,
            cancel_at_period_end
        ) VALUES (
            p_user_id,
            p_new_tier::"SubscriptionTier",
            'active'::subscription_status,
            CASE WHEN p_new_tier IN ('starter', 'premium') THEN NOW() ELSE NULL END,
            CASE WHEN p_new_tier IN ('starter', 'premium') THEN v_period_end ELSE NULL END,
            false
        );
    END IF;

    -- Build duration text for log
    IF p_new_tier = 'free' THEN
        v_duration_text := '';
    ELSIF p_duration_months IS NULL THEN
        v_duration_text := ' (permanent)';
    ELSE
        v_duration_text := ' (' || p_duration_months || ' months)';
    END IF;

    -- Log operation
    IF v_old_tier = p_new_tier THEN
        -- Same tier - just updating duration
        PERFORM log_operation(
            'Admin updated ' || p_new_tier || ' subscription duration' || v_duration_text || 
            ' for user: ' || v_user_email || ' - Reason: ' || p_reason
        );
    ELSE
        -- Tier change
        PERFORM log_operation(
            'Admin changed subscription tier from ' || COALESCE(v_old_tier, 'none') || 
            ' to ' || p_new_tier || v_duration_text || ' for user: ' || v_user_email || 
            ' - Reason: ' || p_reason
        );
    END IF;

    RETURN TRUE;
END;
$$;

-- Get subscription statistics for admin dashboard
CREATE OR REPLACE FUNCTION admin_get_subscription_stats()
RETURNS TABLE (
    total_users BIGINT,
    free_users BIGINT,
    premium_users BIGINT,
    active_premium BIGINT,
    canceled_pending BIGINT,
    past_due BIGINT,
    estimated_mrr_cents BIGINT
)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    caller_role TEXT;
BEGIN
    -- Check if the caller is an admin
    SELECT raw_user_meta_data->>'role' INTO caller_role
    FROM auth.users
    WHERE auth.users.id = auth.uid();

    IF caller_role != 'admin' THEN
        RAISE EXCEPTION 'Only admins can view subscription statistics.';
    END IF;

    RETURN QUERY
    SELECT 
        (SELECT COUNT(*) FROM auth.users) as total_users,
        (SELECT COUNT(*) FROM auth.users) - (SELECT COUNT(*) FROM subscriptions WHERE tier = 'premium') as free_users,
        (SELECT COUNT(*) FROM subscriptions WHERE tier = 'premium') as premium_users,
        (SELECT COUNT(*) FROM subscriptions WHERE tier = 'premium' AND status = 'active' AND cancel_at_period_end = false) as active_premium,
        (SELECT COUNT(*) FROM subscriptions WHERE tier = 'premium' AND cancel_at_period_end = true) as canceled_pending,
        (SELECT COUNT(*) FROM subscriptions WHERE status = 'past_due') as past_due,
        (SELECT COUNT(*) * 5000 FROM subscriptions WHERE tier = 'premium' AND status = 'active') as estimated_mrr_cents;
END;
$$;

-- Update user role
CREATE OR REPLACE FUNCTION admin_update_user_role(
    p_user_id UUID,
    p_new_role TEXT,
    p_reason TEXT
)
RETURNS BOOLEAN
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    caller_role TEXT;
    v_user_email VARCHAR(255);
    v_old_role TEXT;
BEGIN
    -- Check if the caller is an admin
    SELECT raw_user_meta_data->>'role' INTO caller_role
    FROM auth.users
    WHERE auth.users.id = auth.uid();

    IF caller_role != 'admin' THEN
        RAISE EXCEPTION 'Only admins can update user roles.';
    END IF;

    -- Validate new role
    IF p_new_role NOT IN ('admin', 'cardIssuer', 'user') THEN
        RAISE EXCEPTION 'Invalid role. Must be: admin, cardIssuer, or user.';
    END IF;

    -- Get current user info
    SELECT email, raw_user_meta_data->>'role' 
    INTO v_user_email, v_old_role
    FROM auth.users
    WHERE id = p_user_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'User not found.';
    END IF;

    -- Update user role in auth.users metadata
    UPDATE auth.users
    SET raw_user_meta_data = jsonb_set(
        COALESCE(raw_user_meta_data, '{}'::jsonb),
        '{role}',
        to_jsonb(p_new_role)
    ),
    updated_at = NOW()
    WHERE id = p_user_id;

    -- Log operation
    PERFORM log_operation('Changed user role from ' || COALESCE(v_old_role, 'none') || ' to ' || p_new_role || ' for user: ' || v_user_email);

    RETURN TRUE;
END;
$$;

-- =================================================================
-- ADMIN USER CARD VIEWING FUNCTIONS
-- Functions for admins to view user cards (read-only)
-- =================================================================

-- Get user ID by email
CREATE OR REPLACE FUNCTION admin_get_user_by_email(p_email TEXT)
RETURNS TABLE (
    user_id UUID,
    email TEXT,
    role TEXT,
    created_at TIMESTAMPTZ,
    subscription_tier TEXT,
    subscription_status TEXT
) LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_caller_role TEXT;
BEGIN
    -- Check if caller is admin
    SELECT raw_user_meta_data->>'role' INTO v_caller_role
    FROM auth.users
    WHERE auth.users.id = auth.uid();
    
    IF v_caller_role != 'admin' THEN
        RAISE EXCEPTION 'Admin access required';
    END IF;

    RETURN QUERY
    SELECT 
        au.id AS user_id,
        au.email::TEXT,
        COALESCE(au.raw_user_meta_data->>'role', 'user')::TEXT AS role,
        au.created_at,
        COALESCE(s.tier::TEXT, 'free') as subscription_tier,
        COALESCE(s.status::TEXT, 'active') as subscription_status
    FROM auth.users au
    LEFT JOIN subscriptions s ON s.user_id = au.id
    WHERE LOWER(au.email) = LOWER(p_email);
END;
$$;

-- Get all cards for a specific user (admin view)
-- Updated to aggregate session data from card_access_tokens
CREATE OR REPLACE FUNCTION admin_get_user_cards(p_user_id UUID)
RETURNS TABLE (
    id UUID,
    card_name TEXT,
    name TEXT,
    description TEXT,
    image_url TEXT,
    original_image_url TEXT,
    crop_parameters JSONB,
    conversation_ai_enabled BOOLEAN,
    ai_instruction TEXT,
    ai_knowledge_base TEXT,
    ai_welcome_general TEXT,
    ai_welcome_item TEXT,
    qr_code_position TEXT,
    content_mode TEXT,
    is_grouped BOOLEAN,
    group_display TEXT,
    default_daily_session_limit INT,
    metadata JSONB,
    -- Aggregated from access tokens
    total_sessions BIGINT,
    daily_sessions BIGINT,
    active_qr_codes BIGINT,
    total_qr_codes BIGINT,
    translations JSONB,
    original_language VARCHAR(10),
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ,
    user_email TEXT
) LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_caller_role TEXT;
BEGIN
    -- Check if caller is admin
    SELECT raw_user_meta_data->>'role' INTO v_caller_role
    FROM auth.users
    WHERE auth.users.id = auth.uid();
    
    IF v_caller_role != 'admin' THEN
        RAISE EXCEPTION 'Admin access required';
    END IF;

    RETURN QUERY
    SELECT 
        c.id, 
        c.name AS card_name,
        c.name, 
        c.description, 
        c.image_url, 
        c.original_image_url,
        c.crop_parameters,
        c.conversation_ai_enabled,
        c.ai_instruction,
        c.ai_knowledge_base,
        c.ai_welcome_general,
        c.ai_welcome_item,
        c.qr_code_position::TEXT,
        c.content_mode::TEXT,
        c.is_grouped,
        c.group_display::TEXT,
        c.default_daily_session_limit,
        c.metadata,
        -- Aggregate from access tokens
        COALESCE(SUM(t.total_sessions), 0)::BIGINT AS total_sessions,
        COALESCE(SUM(t.daily_sessions), 0)::BIGINT AS daily_sessions,
        COALESCE(COUNT(t.id) FILTER (WHERE t.is_enabled), 0)::BIGINT AS active_qr_codes,
        COALESCE(COUNT(t.id), 0)::BIGINT AS total_qr_codes,
        c.translations,
        c.original_language,
        c.created_at,
        c.updated_at,
        au.email::TEXT AS user_email
    FROM cards c
    JOIN auth.users au ON c.user_id = au.id
    LEFT JOIN card_access_tokens t ON t.card_id = c.id
    WHERE c.user_id = p_user_id
    GROUP BY c.id, c.name, c.description, c.image_url, c.original_image_url,
             c.crop_parameters, c.conversation_ai_enabled, c.ai_instruction, c.ai_knowledge_base,
             c.ai_welcome_general, c.ai_welcome_item, c.qr_code_position, c.content_mode,
             c.is_grouped, c.group_display, c.default_daily_session_limit, c.metadata,
             c.translations, c.original_language, c.created_at, c.updated_at, au.email
    ORDER BY c.created_at DESC;
END;
$$;

-- Get card content items for admin viewing
CREATE OR REPLACE FUNCTION admin_get_card_content(p_card_id UUID)
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
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ
) LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_caller_role TEXT;
BEGIN
    -- Check if caller is admin
    SELECT raw_user_meta_data->>'role' INTO v_caller_role
    FROM auth.users
    WHERE auth.users.id = auth.uid();
    
    IF v_caller_role != 'admin' THEN
        RAISE EXCEPTION 'Admin access required';
    END IF;

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
        ci.created_at,
        ci.updated_at
    FROM content_items ci
    WHERE ci.card_id = p_card_id
    ORDER BY 
        CASE WHEN ci.parent_id IS NULL THEN ci.sort_order ELSE 999999 END,
        ci.parent_id NULLS FIRST,
        ci.sort_order ASC,
        ci.created_at ASC;
END;
$$;

-- =================================================================
-- AUDIT LOG FUNCTIONS
-- =================================================================

-- Get admin audit logs (wraps operations_log for admin dashboard)
-- Note: operations_log has simple structure: user_id, user_role, operation, created_at
CREATE OR REPLACE FUNCTION get_admin_audit_logs(
    p_action_type TEXT DEFAULT NULL,
    p_admin_user_id UUID DEFAULT NULL,
    p_limit INTEGER DEFAULT 50,
    p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
    id UUID,
    user_id UUID,
    user_email TEXT,
    user_role "UserRole",
    operation TEXT,
    created_at TIMESTAMPTZ
) AS $$
DECLARE
    v_caller_role TEXT;
BEGIN
    -- Check if caller is admin
    SELECT raw_user_meta_data->>'role' INTO v_caller_role
    FROM auth.users
    WHERE auth.users.id = auth.uid();
    
    IF v_caller_role != 'admin' THEN
        RAISE EXCEPTION 'Only admins can view audit logs';
    END IF;
    
    -- Return from operations_log table
    RETURN QUERY
    SELECT 
        ol.id,
        ol.user_id,
        au.email::TEXT AS user_email,
        ol.user_role,
        ol.operation,
        ol.created_at
    FROM operations_log ol
    LEFT JOIN auth.users au ON ol.user_id = au.id
    WHERE (p_action_type IS NULL OR ol.operation ILIKE '%' || p_action_type || '%')
      AND (p_admin_user_id IS NULL OR ol.user_id = p_admin_user_id)
    ORDER BY ol.created_at DESC
    LIMIT p_limit
    OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =================================================================
-- GRANT STATEMENTS FOR ADMIN FUNCTIONS
-- =================================================================
-- All admin functions use SECURITY DEFINER and check role internally
-- They must be callable by authenticated users, but actual admin check
-- happens inside each function via auth.uid() role lookup

GRANT EXECUTE ON FUNCTION admin_get_system_stats_enhanced() TO authenticated;
GRANT EXECUTE ON FUNCTION admin_get_all_users() TO authenticated;
GRANT EXECUTE ON FUNCTION admin_update_user_subscription(UUID, TEXT, TEXT, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION admin_get_subscription_stats() TO authenticated;
GRANT EXECUTE ON FUNCTION admin_update_user_role(UUID, TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION admin_get_user_by_email(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION admin_get_user_cards(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION admin_get_card_content(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_admin_audit_logs(TEXT, UUID, INTEGER, INTEGER) TO authenticated;

-- File: 12_subscription.sql
-- -----------------------------------------------------------------
DROP FUNCTION IF EXISTS get_or_create_subscription CASCADE;
DROP FUNCTION IF EXISTS can_create_experience CASCADE;
DROP FUNCTION IF EXISTS can_use_translations CASCADE;
DROP FUNCTION IF EXISTS get_subscription_details CASCADE;

-- =================================================================
-- SUBSCRIPTION MANAGEMENT - CLIENT-SIDE STORED PROCEDURES
-- =================================================================
-- These functions are accessible by authenticated users
-- Usage tracking is handled by Redis (source of truth)
--
-- NOTE: All pricing/budget values come from environment variables
-- passed as parameters. The database only stores tier/status.
-- Redis tracks actual budget usage.
-- =================================================================

-- =================================================================
-- FUNCTION: Get or create subscription
-- Creates free tier subscription if none exists
-- =================================================================
CREATE OR REPLACE FUNCTION get_or_create_subscription(
    p_user_id UUID DEFAULT NULL
)
RETURNS subscriptions AS $$
DECLARE
    v_user_id UUID := COALESCE(p_user_id, auth.uid());
    v_subscription subscriptions%ROWTYPE;
BEGIN
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;
    
    -- Try to get existing subscription
    SELECT * INTO v_subscription 
    FROM subscriptions 
    WHERE user_id = v_user_id;
    
    -- Create free tier if none exists
    IF NOT FOUND THEN
        INSERT INTO subscriptions (user_id, tier, status)
        VALUES (v_user_id, 'free', 'active')
        RETURNING * INTO v_subscription;
    END IF;
    
    RETURN v_subscription;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =================================================================
-- FUNCTION: Can create project
-- Business parameters passed from calling application
-- Supports Free, Starter, and Premium tiers
-- =================================================================
CREATE OR REPLACE FUNCTION can_create_experience(
    p_user_id UUID DEFAULT NULL,
    p_free_limit INTEGER DEFAULT 3,
    p_starter_limit INTEGER DEFAULT 5,
    p_premium_limit INTEGER DEFAULT 35
)
RETURNS JSONB AS $$
DECLARE
    v_user_id UUID := COALESCE(p_user_id, auth.uid());
    v_subscription subscriptions%ROWTYPE;
    v_experience_count INTEGER;
    v_limit INTEGER;
    v_user_role TEXT;
BEGIN
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;
    
    -- Check if user is admin
    v_user_role := get_user_role(v_user_id);
    IF v_user_role = 'admin' THEN
        RETURN jsonb_build_object(
            'can_create', TRUE,
            'current_count', (SELECT COUNT(*) FROM cards WHERE user_id = v_user_id),
            'limit', 999999,
            'tier', 'admin',
            'message', 'Admin bypass'
        );
    END IF;
    
    -- Get subscription
    v_subscription := get_or_create_subscription(v_user_id);
    
    -- Count existing experiences
    SELECT COUNT(*) INTO v_experience_count FROM cards WHERE user_id = v_user_id;
    
    -- Determine limit based on tier (Free, Starter, Premium)
    IF v_subscription.tier = 'premium' THEN
        v_limit := p_premium_limit;
    ELSIF v_subscription.tier = 'starter' THEN
        v_limit := p_starter_limit;
    ELSE
        v_limit := p_free_limit;
    END IF;
    
    RETURN jsonb_build_object(
        'can_create', v_experience_count < v_limit,
        'current_count', v_experience_count,
        'limit', v_limit,
        'tier', v_subscription.tier::TEXT,
        'message', CASE 
            WHEN v_experience_count < v_limit THEN 'OK'
            WHEN v_subscription.tier = 'free' THEN 'Upgrade to Starter or Premium to create more projects'
            WHEN v_subscription.tier = 'starter' THEN 'Upgrade to Premium to create more projects'
            ELSE 'Project limit reached'
        END
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =================================================================
-- FUNCTION: Can use translations
-- Starter and Premium tiers can use translations
-- Starter: max 2 languages, Premium: unlimited
-- =================================================================
CREATE OR REPLACE FUNCTION can_use_translations(
    p_user_id UUID DEFAULT NULL,
    p_starter_max_languages INTEGER DEFAULT 2
)
RETURNS JSONB AS $$
DECLARE
    v_user_id UUID := COALESCE(p_user_id, auth.uid());
    v_subscription subscriptions%ROWTYPE;
    v_user_role TEXT;
BEGIN
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;
    
    -- Check if user is admin (admins always have translation access)
    v_user_role := get_user_role(v_user_id);
    IF v_user_role = 'admin' THEN
        RETURN jsonb_build_object(
            'can_translate', TRUE,
            'tier', 'admin',
            'max_languages', -1,
            'message', 'Admin bypass - unlimited translations'
        );
    END IF;
    
    -- Get subscription
    v_subscription := get_or_create_subscription(v_user_id);
    
    RETURN jsonb_build_object(
        'can_translate', v_subscription.tier IN ('starter', 'premium'),
        'tier', v_subscription.tier::TEXT,
        'max_languages', CASE
            WHEN v_subscription.tier = 'premium' THEN -1
            WHEN v_subscription.tier = 'starter' THEN p_starter_max_languages
            ELSE 0
        END,
        'message', CASE 
            WHEN v_subscription.tier = 'premium' THEN 'Unlimited translations available'
            WHEN v_subscription.tier = 'starter' THEN 'Max ' || p_starter_max_languages || ' language translations available'
            ELSE 'Upgrade to Starter or Premium to access multi-language translations'
        END
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =================================================================
-- FUNCTION: Get subscription details
-- All pricing/budget values come from parameters (environment variables)
-- NOTE: Usage stats come from Redis (source of truth), not from DB
-- Supports Free, Starter, and Premium tiers
-- =================================================================
CREATE OR REPLACE FUNCTION get_subscription_details(
    p_user_id UUID DEFAULT NULL,
    p_free_experience_limit INTEGER DEFAULT 3,
    p_starter_experience_limit INTEGER DEFAULT 5,
    p_premium_experience_limit INTEGER DEFAULT 35,
    p_free_monthly_sessions INTEGER DEFAULT 50,  -- Free tier session limit
    p_starter_monthly_budget DECIMAL DEFAULT 40.00,  -- Starter monthly budget USD
    p_premium_monthly_budget DECIMAL DEFAULT 280.00,  -- Premium monthly budget USD
    p_starter_ai_session_cost DECIMAL DEFAULT 0.05,  -- Starter AI session cost
    p_starter_non_ai_session_cost DECIMAL DEFAULT 0.025,  -- Starter non-AI session cost
    p_premium_ai_session_cost DECIMAL DEFAULT 0.04,  -- Premium AI session cost
    p_premium_non_ai_session_cost DECIMAL DEFAULT 0.02,  -- Premium non-AI session cost
    p_overage_credits_per_batch INTEGER DEFAULT 5  -- Credits per auto top-up
)
RETURNS JSONB AS $$
DECLARE
    v_user_id UUID := COALESCE(p_user_id, auth.uid());
    v_subscription subscriptions%ROWTYPE;
    v_experience_count INTEGER;
    v_monthly_budget DECIMAL;
    v_ai_session_cost DECIMAL;
    v_non_ai_session_cost DECIMAL;
BEGIN
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;
    
    -- Get subscription
    v_subscription := get_or_create_subscription(v_user_id);
    
    -- Count experiences
    SELECT COUNT(*) INTO v_experience_count FROM cards WHERE user_id = v_user_id;
    
    -- Set tier-specific values
    IF v_subscription.tier = 'premium' THEN
        v_monthly_budget := p_premium_monthly_budget;
        v_ai_session_cost := p_premium_ai_session_cost;
        v_non_ai_session_cost := p_premium_non_ai_session_cost;
    ELSIF v_subscription.tier = 'starter' THEN
        v_monthly_budget := p_starter_monthly_budget;
        v_ai_session_cost := p_starter_ai_session_cost;
        v_non_ai_session_cost := p_starter_non_ai_session_cost;
    ELSE
        v_monthly_budget := 0;
        v_ai_session_cost := 0;
        v_non_ai_session_cost := 0;
    END IF;
    
    RETURN jsonb_build_object(
        'tier', v_subscription.tier::TEXT,
        'status', v_subscription.status,
        'is_premium', v_subscription.tier = 'premium',
        'is_starter', v_subscription.tier = 'starter',
        'is_paid', v_subscription.tier IN ('starter', 'premium'),
        
        -- Stripe info
        'stripe_subscription_id', v_subscription.stripe_subscription_id,
        'current_period_start', v_subscription.current_period_start,
        'current_period_end', v_subscription.current_period_end,
        'cancel_at_period_end', v_subscription.cancel_at_period_end,
        'scheduled_tier', v_subscription.scheduled_tier::TEXT,  -- Tier to switch to after period ends
        
        -- Session-based billing (from parameters/env vars)
        -- NOTE: Actual budget tracking is in Redis, these are just for display
        'monthly_budget_usd', v_monthly_budget,
        'budget_consumed_usd', 0,  -- Redis is source of truth, backend fills this
        'budget_remaining_usd', v_monthly_budget,
        
        -- Session costs (tier-specific)
        'ai_session_cost_usd', v_ai_session_cost,
        'non_ai_session_cost_usd', v_non_ai_session_cost,
        
        -- Calculated session limits
        'ai_sessions_included', CASE 
            WHEN v_subscription.tier IN ('starter', 'premium') THEN FLOOR(v_monthly_budget / v_ai_session_cost) 
            ELSE 0 
        END,
        'non_ai_sessions_included', CASE 
            WHEN v_subscription.tier IN ('starter', 'premium') THEN FLOOR(v_monthly_budget / v_non_ai_session_cost) 
            ELSE 0 
        END,
        
        -- Free tier (session count based)
        'monthly_session_limit', CASE WHEN v_subscription.tier = 'free' THEN p_free_monthly_sessions ELSE NULL END,
        
        -- Experience limits
        'experience_count', v_experience_count,
        'experience_limit', CASE 
            WHEN v_subscription.tier = 'premium' THEN p_premium_experience_limit
            WHEN v_subscription.tier = 'starter' THEN p_starter_experience_limit
            ELSE p_free_experience_limit 
        END,
        
        -- Features
        'features', jsonb_build_object(
            'translations_enabled', v_subscription.tier IN ('starter', 'premium'),
            'max_languages', CASE
                WHEN v_subscription.tier = 'premium' THEN -1
                WHEN v_subscription.tier = 'starter' THEN 2
                ELSE 0
            END,
            'can_buy_overage', v_subscription.tier IN ('starter', 'premium'),
            'white_label', v_subscription.tier = 'premium'
        ),
        
        -- Pricing info (all from parameters/env vars)
        'pricing', jsonb_build_object(
            'monthly_fee_usd', v_monthly_budget,
            'ai_session_cost_usd', v_ai_session_cost,
            'non_ai_session_cost_usd', v_non_ai_session_cost,
            'ai_sessions_included', CASE WHEN v_subscription.tier IN ('starter', 'premium') THEN FLOOR(v_monthly_budget / v_ai_session_cost) ELSE 0 END,
            'non_ai_sessions_included', CASE WHEN v_subscription.tier IN ('starter', 'premium') THEN FLOOR(v_monthly_budget / v_non_ai_session_cost) ELSE 0 END,
            'overage_credits_per_batch', p_overage_credits_per_batch,
            'overage_ai_sessions_per_batch', CASE WHEN v_ai_session_cost > 0 THEN FLOOR(p_overage_credits_per_batch / v_ai_session_cost) ELSE 0 END,
            'overage_non_ai_sessions_per_batch', CASE WHEN v_non_ai_session_cost > 0 THEN FLOOR(p_overage_credits_per_batch / v_non_ai_session_cost) ELSE 0 END
        )
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =================================================================
-- GRANTS
-- =================================================================
GRANT EXECUTE ON FUNCTION get_or_create_subscription(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION can_create_experience(UUID, INTEGER, INTEGER, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION can_use_translations(UUID, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION get_subscription_details(UUID, INTEGER, INTEGER, INTEGER, INTEGER, DECIMAL, DECIMAL, DECIMAL, DECIMAL, DECIMAL, DECIMAL, INTEGER) TO authenticated;


-- File: 12_translation_management.sql
-- -----------------------------------------------------------------
DROP FUNCTION IF EXISTS get_card_translation_status CASCADE;
DROP FUNCTION IF EXISTS get_card_translations CASCADE;
DROP FUNCTION IF EXISTS delete_card_translation CASCADE;
DROP FUNCTION IF EXISTS get_translation_history CASCADE;
DROP FUNCTION IF EXISTS get_outdated_translations CASCADE;
DROP FUNCTION IF EXISTS update_card_translations_bulk CASCADE;
DROP FUNCTION IF EXISTS update_content_item_translations_bulk CASCADE;
DROP FUNCTION IF EXISTS recalculate_card_translation_hashes CASCADE;
DROP FUNCTION IF EXISTS recalculate_content_item_translation_hashes CASCADE;
DROP FUNCTION IF EXISTS recalculate_all_translation_hashes CASCADE;

-- =====================================================================
-- TRANSLATION MANAGEMENT STORED PROCEDURES
-- =====================================================================
-- These procedures handle AI-powered multi-language translation
-- for card content. Translation costs 1 credit per language.
--
-- Client-side procedures (called from dashboard frontend):
-- - get_card_translation_status: Get translation status for all languages
-- - get_card_translations: Get full translations for a card
-- - delete_card_translation: Remove a specific language translation
-- - get_translation_history: Get audit trail of translations
--
-- Note: Translations are now saved via direct Supabase updates in 
-- backend-server/src/routes/translation.routes.direct.ts (saveTranslations function)
-- =====================================================================

-- =====================================================================
-- 1. Get Translation Status for a Card
-- =====================================================================
-- Returns status of translations for all supported languages
-- Status types: 'original', 'up_to_date', 'outdated', 'not_translated'
-- =====================================================================

CREATE OR REPLACE FUNCTION get_card_translation_status(p_card_id UUID)
RETURNS TABLE (
  language VARCHAR(10),
  language_name TEXT,
  status VARCHAR(20),
  translated_at TIMESTAMPTZ,
  needs_update BOOLEAN,
  content_fields_count INTEGER
) 
SECURITY DEFINER
AS $$
DECLARE
  v_user_id UUID;
  v_card_owner UUID;
  v_original_language VARCHAR(10);
  v_content_hash TEXT;
  v_content_items_count INTEGER;
BEGIN
  -- Get current user
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Unauthorized: No authenticated user';
  END IF;

  -- Verify card ownership
  SELECT c.user_id, c.original_language, c.content_hash
  INTO v_card_owner, v_original_language, v_content_hash
  FROM cards c
  WHERE c.id = p_card_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Card not found';
  END IF;

  IF v_card_owner != v_user_id THEN
    -- Allow admins to view any card
    IF NOT EXISTS (
      SELECT 1 FROM auth.users 
      WHERE id = v_user_id 
      AND raw_user_meta_data->>'role' = 'admin'
    ) THEN
      RAISE EXCEPTION 'Unauthorized: Card does not belong to user';
    END IF;
  END IF;

  -- Get content items count
  SELECT COUNT(*) INTO v_content_items_count
  FROM content_items ci
  WHERE ci.card_id = p_card_id;

  -- Return translation status for all supported languages
  RETURN QUERY
  WITH supported_languages AS (
    SELECT 
      unnest(ARRAY['en', 'zh-Hant', 'zh-Hans', 'ja', 'ko', 'es', 'fr', 'ru', 'ar', 'th']) AS lang,
      unnest(ARRAY[
        'English', 
        'Traditional Chinese', 
        'Simplified Chinese', 
        'Japanese', 
        'Korean', 
        'Spanish', 
        'French', 
        'Russian', 
        'Arabic', 
        'Thai'
      ]) AS lang_name
  ),
  card_info AS (
    SELECT 
      c.original_language, 
      c.translations, 
      c.content_hash
    FROM cards c
    WHERE c.id = p_card_id
  ),
  content_items_status AS (
    -- Compute per-language freshness across all content items.
    -- Treat the no-content-items case as up-to-date (TRUE).
    SELECT
      sl.lang AS lang,
      CASE 
        WHEN COUNT(ci.id) = 0 THEN TRUE
        ELSE bool_and(
          ci.translations ? sl.lang AND
          ci.translations->sl.lang->>'content_hash' = ci.content_hash
        )
      END AS all_items_translated
    FROM supported_languages sl
    LEFT JOIN content_items ci
      ON ci.card_id = p_card_id
    GROUP BY sl.lang
  )
  SELECT 
    sl.lang::VARCHAR(10),
    sl.lang_name::TEXT,
    CASE 
      WHEN sl.lang = ci.original_language THEN 'original'
      WHEN ci.translations ? sl.lang THEN
        CASE
          WHEN ci.translations->sl.lang->>'content_hash' = ci.content_hash 
               AND COALESCE(cis.all_items_translated, TRUE)
          THEN 'up_to_date'
          ELSE 'outdated'
        END
      ELSE 'not_translated'
    END::VARCHAR(20),
    (ci.translations->sl.lang->>'translated_at')::TIMESTAMPTZ,
    CASE 
      WHEN sl.lang != ci.original_language AND 
           (NOT (ci.translations ? sl.lang) OR 
            ci.translations->sl.lang->>'content_hash' != ci.content_hash OR
            NOT COALESCE(cis.all_items_translated, TRUE))
      THEN TRUE
      ELSE FALSE
    END::BOOLEAN,
    (2 + v_content_items_count * 3)::INTEGER -- 2 card fields + N items × 3 fields each
  FROM supported_languages sl
  CROSS JOIN card_info ci
  LEFT JOIN content_items_status cis ON cis.lang = sl.lang;
END;
$$ LANGUAGE plpgsql;

-- =====================================================================
-- 2. Get Full Translations for a Card
-- =====================================================================
-- Returns all translations for a card and its content items
-- =====================================================================

CREATE OR REPLACE FUNCTION get_card_translations(
  p_card_id UUID,
  p_language VARCHAR(10) DEFAULT NULL -- If NULL, return all languages
)
RETURNS JSONB
SECURITY DEFINER
AS $$
DECLARE
  v_user_id UUID;
  v_card_owner UUID;
  v_result JSONB;
BEGIN
  -- Get current user
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Unauthorized: No authenticated user';
  END IF;

  -- Verify card ownership
  SELECT user_id INTO v_card_owner FROM cards WHERE id = p_card_id;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Card not found';
  END IF;

  IF v_card_owner != v_user_id THEN
    -- Allow admins to view any card
    IF NOT EXISTS (
      SELECT 1 FROM auth.users 
      WHERE id = v_user_id 
      AND raw_user_meta_data->>'role' = 'admin'
    ) THEN
      RAISE EXCEPTION 'Unauthorized: Card does not belong to user';
    END IF;
  END IF;

  -- Build result
  SELECT jsonb_build_object(
    'card', jsonb_build_object(
      'id', c.id,
      'name', c.name,
      'description', c.description,
      'original_language', c.original_language,
      'content_hash', c.content_hash,
      'translations', CASE 
        WHEN p_language IS NULL THEN c.translations
        ELSE jsonb_build_object(p_language, c.translations->p_language)
      END
    ),
    'content_items', (
      SELECT COALESCE(jsonb_agg(
        jsonb_build_object(
          'id', ci.id,
          'name', ci.name,
          'content', ci.content,
          'ai_knowledge_base', ci.ai_knowledge_base,
          'content_hash', ci.content_hash,
          'translations', CASE 
            WHEN p_language IS NULL THEN ci.translations
            ELSE jsonb_build_object(p_language, ci.translations->p_language)
          END
        ) ORDER BY ci.sort_order
      ), '[]'::jsonb)
      FROM content_items ci
      WHERE ci.card_id = p_card_id
    )
  ) INTO v_result
  FROM cards c
  WHERE c.id = p_card_id;

  RETURN v_result;
END;
$$ LANGUAGE plpgsql;

-- =====================================================================
-- 3. Store Card Translations (Called by Edge Function)
-- =====================================================================
-- Translation Storage
-- =====================================================================

-- NOTE: store_card_translations function removed - translations now saved 
-- via direct Supabase updates in backend (see translation.routes.direct.ts)
-- This approach provides better control over hash freshness and race condition prevention

-- =====================================================================
-- 4. Delete Card Translation
-- =====================================================================
-- Removes a specific language translation from a card
-- Does not refund credits
-- =====================================================================

CREATE OR REPLACE FUNCTION delete_card_translation(
  p_card_id UUID,
  p_language VARCHAR(10)
)
RETURNS JSONB
SECURITY DEFINER
AS $$
DECLARE
  v_user_id UUID;
  v_card_owner UUID;
BEGIN
  -- Get current user
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Unauthorized: No authenticated user';
  END IF;

  -- Verify card ownership
  SELECT user_id INTO v_card_owner FROM cards WHERE id = p_card_id;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Card not found';
  END IF;

  IF v_card_owner != v_user_id THEN
    RAISE EXCEPTION 'Unauthorized: Card does not belong to user';
  END IF;

  -- Remove translation from card
  UPDATE cards
  SET translations = translations - p_language
  WHERE id = p_card_id;

  -- Remove translations from all content items
  UPDATE content_items
  SET translations = translations - p_language
  WHERE card_id = p_card_id;

  RETURN jsonb_build_object(
    'success', true,
    'card_id', p_card_id,
    'deleted_language', p_language
  );
END;
$$ LANGUAGE plpgsql;

-- =====================================================================
-- 5. Get Translation History
-- =====================================================================
-- Returns audit trail of translation operations for a card
-- =====================================================================

CREATE OR REPLACE FUNCTION get_translation_history(
  p_card_id UUID,
  p_limit INTEGER DEFAULT 50,
  p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
  id UUID,
  card_id UUID,
  target_languages TEXT[],
  credit_cost DECIMAL,
  translated_by UUID,
  translator_email TEXT,
  translated_at TIMESTAMPTZ,
  status VARCHAR,
  error_message TEXT,
  metadata JSONB
)
SECURITY DEFINER
AS $$
DECLARE
  v_user_id UUID;
  v_card_owner UUID;
BEGIN
  -- Get current user
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Unauthorized: No authenticated user';
  END IF;

  -- Verify card ownership or admin
  SELECT c.user_id INTO v_card_owner FROM cards c WHERE c.id = p_card_id;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Card not found';
  END IF;

  IF v_card_owner != v_user_id THEN
    -- Allow admins to view any card
    IF NOT EXISTS (
      SELECT 1 FROM auth.users 
      WHERE id = v_user_id 
      AND raw_user_meta_data->>'role' = 'admin'
    ) THEN
      RAISE EXCEPTION 'Unauthorized: Card does not belong to user';
    END IF;
  END IF;

  -- Return translation history
  RETURN QUERY
  SELECT 
    th.id,
    th.card_id,
    th.target_languages,
    th.credit_cost,
    th.translated_by,
    au.email::TEXT AS translator_email,
    th.translated_at,
    th.status::VARCHAR,
    th.error_message,
    th.metadata
  FROM translation_history th
  LEFT JOIN auth.users au ON au.id = th.translated_by
  WHERE th.card_id = p_card_id
  ORDER BY th.translated_at DESC
  LIMIT p_limit
  OFFSET p_offset;
END;
$$ LANGUAGE plpgsql;

-- =====================================================================
-- 6. Get Outdated Translations for a Card
-- =====================================================================
-- Returns list of languages that need re-translation
-- =====================================================================

CREATE OR REPLACE FUNCTION get_outdated_translations(p_card_id UUID)
RETURNS TABLE (
  language VARCHAR(10),
  last_translated_at TIMESTAMPTZ
)
SECURITY DEFINER
AS $$
DECLARE
  v_user_id UUID;
  v_card_owner UUID;
BEGIN
  -- Get current user
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Unauthorized: No authenticated user';
  END IF;

  -- Verify card ownership
  SELECT user_id INTO v_card_owner FROM cards WHERE id = p_card_id;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Card not found';
  END IF;

  IF v_card_owner != v_user_id THEN
    RAISE EXCEPTION 'Unauthorized: Card does not belong to user';
  END IF;

  -- Return outdated translations from the status function
  RETURN QUERY
  SELECT 
    ts.language::VARCHAR(10),
    ts.translated_at
  FROM get_card_translation_status(p_card_id) ts
  WHERE ts.status = 'outdated';
END;
$$ LANGUAGE plpgsql;

-- =====================================================================
-- 7. Bulk Update Card Translations (For Import)
-- =====================================================================
-- Updates card translations JSONB in bulk during import
-- Used to restore translations from exported Excel files
-- =====================================================================

CREATE OR REPLACE FUNCTION update_card_translations_bulk(
    p_card_id UUID,
    p_translations JSONB
) RETURNS VOID 
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_card_owner UUID;
BEGIN
    v_user_id := auth.uid();
    
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;
    
    -- Verify ownership
    SELECT user_id INTO v_card_owner FROM cards WHERE id = p_card_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Card not found';
    END IF;
    
    IF v_card_owner != v_user_id THEN
        RAISE EXCEPTION 'Unauthorized: Card does not belong to user';
    END IF;
    
    UPDATE public.cards
    SET translations = p_translations,
        updated_at = NOW()
    WHERE id = p_card_id;
END;
$$ LANGUAGE plpgsql;

-- =====================================================================
-- 8. Bulk Update Content Item Translations (For Import)
-- =====================================================================
-- Updates content item translations JSONB in bulk during import
-- Used to restore translations from exported Excel files
-- =====================================================================

CREATE OR REPLACE FUNCTION update_content_item_translations_bulk(
    p_content_item_id UUID,
    p_translations JSONB
) RETURNS VOID 
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_card_id UUID;
    v_card_owner UUID;
BEGIN
    v_user_id := auth.uid();
    
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;
    
    -- Get card_id and verify ownership
    SELECT ci.card_id INTO v_card_id
    FROM content_items ci
    WHERE ci.id = p_content_item_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Content item not found';
    END IF;
    
    SELECT user_id INTO v_card_owner FROM cards WHERE id = v_card_id;
    
    IF v_card_owner != v_user_id THEN
        RAISE EXCEPTION 'Unauthorized: Content item does not belong to user';
    END IF;
    
    UPDATE public.content_items
    SET translations = p_translations,
        updated_at = NOW()
    WHERE id = p_content_item_id;
END;
$$ LANGUAGE plpgsql;

-- =====================================================================
-- 9. Recalculate Card Translation Hashes (For Import)
-- =====================================================================
-- After importing translations, recalculates the content_hash inside
-- each translation to match the newly imported card's content_hash.
-- This prevents translations from appearing "Outdated" after import.
-- =====================================================================

CREATE OR REPLACE FUNCTION recalculate_card_translation_hashes(
    p_card_id UUID
) RETURNS VOID 
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_current_hash TEXT;
    v_translations JSONB;
    v_lang_code TEXT;
    v_updated_translations JSONB := '{}'::JSONB;
    v_translation_obj JSONB;
BEGIN
    v_user_id := auth.uid();
    
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;
    
    -- Verify ownership
    IF NOT EXISTS (
        SELECT 1 FROM cards 
        WHERE id = p_card_id AND user_id = v_user_id
    ) THEN
        RAISE EXCEPTION 'Unauthorized: Card not found or access denied';
    END IF;
    
    -- Get current card content hash
    SELECT content_hash, translations 
    INTO v_current_hash, v_translations 
    FROM cards 
    WHERE id = p_card_id;
    
    -- If no content hash yet, calculate it
    IF v_current_hash IS NULL THEN
        v_current_hash := md5(
            COALESCE((SELECT name FROM cards WHERE id = p_card_id), '') || 
            COALESCE((SELECT description FROM cards WHERE id = p_card_id), '')
        );
        
        UPDATE cards SET content_hash = v_current_hash WHERE id = p_card_id;
    END IF;
    
    -- Update each translation's content_hash to match current card
    IF v_translations IS NOT NULL AND v_translations != '{}'::JSONB THEN
        FOR v_lang_code IN SELECT jsonb_object_keys(v_translations)
        LOOP
            v_translation_obj := v_translations->v_lang_code;
            
            -- Update the content_hash within this translation
            v_updated_translations := v_updated_translations || 
                jsonb_build_object(
                    v_lang_code,
                    v_translation_obj || jsonb_build_object('content_hash', v_current_hash)
                );
        END LOOP;
        
        -- Update card with recalculated hashes
        UPDATE cards 
        SET translations = v_updated_translations,
            updated_at = NOW()
        WHERE id = p_card_id;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- =====================================================================
-- 10. Recalculate Content Item Translation Hashes (For Import)
-- =====================================================================
-- After importing translations, recalculates the content_hash inside
-- each translation to match the newly imported content item's content_hash.
-- This prevents translations from appearing "Outdated" after import.
-- =====================================================================

CREATE OR REPLACE FUNCTION recalculate_content_item_translation_hashes(
    p_content_item_id UUID
) RETURNS VOID 
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_card_id UUID;
    v_current_hash TEXT;
    v_translations JSONB;
    v_lang_code TEXT;
    v_updated_translations JSONB := '{}'::JSONB;
    v_translation_obj JSONB;
BEGIN
    v_user_id := auth.uid();
    
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;
    
    -- Get card_id and verify ownership
    SELECT card_id INTO v_card_id
    FROM content_items
    WHERE id = p_content_item_id;
    
    IF v_card_id IS NULL THEN
        RAISE EXCEPTION 'Content item not found';
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM cards 
        WHERE id = v_card_id AND user_id = v_user_id
    ) THEN
        RAISE EXCEPTION 'Unauthorized: Access denied';
    END IF;
    
    -- Get current content item hash
    SELECT content_hash, translations 
    INTO v_current_hash, v_translations 
    FROM content_items 
    WHERE id = p_content_item_id;
    
    -- If no content hash yet, calculate it
    IF v_current_hash IS NULL THEN
        v_current_hash := md5(
            COALESCE((SELECT name FROM content_items WHERE id = p_content_item_id), '') || 
            COALESCE((SELECT content FROM content_items WHERE id = p_content_item_id), '')
        );
        
        UPDATE content_items SET content_hash = v_current_hash WHERE id = p_content_item_id;
    END IF;
    
    -- Update each translation's content_hash to match current content
    IF v_translations IS NOT NULL AND v_translations != '{}'::JSONB THEN
        FOR v_lang_code IN SELECT jsonb_object_keys(v_translations)
        LOOP
            v_translation_obj := v_translations->v_lang_code;
            
            -- Update the content_hash within this translation
            v_updated_translations := v_updated_translations || 
                jsonb_build_object(
                    v_lang_code,
                    v_translation_obj || jsonb_build_object('content_hash', v_current_hash)
                );
        END LOOP;
        
        -- Update content item with recalculated hashes
        UPDATE content_items 
        SET translations = v_updated_translations,
            updated_at = NOW()
        WHERE id = p_content_item_id;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- =====================================================================
-- 11. Recalculate All Translation Hashes (Batch Operation)
-- =====================================================================
-- Recalculates translation hashes for a card and all its content items
-- Used after bulk import to ensure all translations show correct status
-- =====================================================================

CREATE OR REPLACE FUNCTION recalculate_all_translation_hashes(
    p_card_id UUID
) RETURNS VOID 
SECURITY DEFINER
AS $$
DECLARE
    v_content_item_id UUID;
BEGIN
    -- Recalculate card translation hashes
    PERFORM recalculate_card_translation_hashes(p_card_id);
    
    -- Recalculate all content item translation hashes
    FOR v_content_item_id IN 
        SELECT id FROM content_items WHERE card_id = p_card_id
    LOOP
        PERFORM recalculate_content_item_translation_hashes(v_content_item_id);
    END LOOP;
    
    PERFORM log_operation(format('Recalculated all translation hashes for card: %s', p_card_id));
END;
$$ LANGUAGE plpgsql;

-- =====================================================================
-- Grant permissions
-- =====================================================================

GRANT EXECUTE ON FUNCTION get_card_translation_status(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_card_translations(UUID, VARCHAR) TO authenticated;
-- store_card_translations removed - translations now saved via direct Supabase updates (see translation.routes.direct.ts)
GRANT EXECUTE ON FUNCTION delete_card_translation(UUID, VARCHAR) TO authenticated;
GRANT EXECUTE ON FUNCTION get_translation_history(UUID, INTEGER, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION get_outdated_translations(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION update_card_translations_bulk(UUID, JSONB) TO authenticated;
GRANT EXECUTE ON FUNCTION update_content_item_translations_bulk(UUID, JSONB) TO authenticated;
GRANT EXECUTE ON FUNCTION recalculate_card_translation_hashes(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION recalculate_content_item_translation_hashes(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION recalculate_all_translation_hashes(UUID) TO authenticated;



-- File: 13_access_tokens.sql
-- -----------------------------------------------------------------
DROP FUNCTION IF EXISTS generate_access_token CASCADE;
DROP FUNCTION IF EXISTS create_access_token CASCADE;
DROP FUNCTION IF EXISTS get_card_access_tokens CASCADE;
DROP FUNCTION IF EXISTS update_access_token CASCADE;
DROP FUNCTION IF EXISTS delete_access_token CASCADE;
DROP FUNCTION IF EXISTS refresh_access_token CASCADE;
DROP FUNCTION IF EXISTS get_card_monthly_stats CASCADE;

-- =====================================================
-- Access Token Management Stored Procedures
-- Client-side procedures for managing QR codes per project
-- =====================================================

-- Generate a unique 12-character URL-safe access token
CREATE OR REPLACE FUNCTION generate_access_token()
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
    v_token TEXT;
    v_exists BOOLEAN;
BEGIN
    LOOP
        -- Generate 12 character alphanumeric token from UUID (URL-safe, no extension required)
        v_token := substring(replace(gen_random_uuid()::text, '-', ''), 1, 12);
        
        -- Check if token already exists
        SELECT EXISTS(SELECT 1 FROM card_access_tokens WHERE access_token = v_token) INTO v_exists;
        
        IF NOT v_exists THEN
            RETURN v_token;
        END IF;
    END LOOP;
END;
$$;

-- Create a new access token (QR code) for a card
CREATE OR REPLACE FUNCTION create_access_token(
    p_card_id UUID,
    p_name TEXT DEFAULT 'Default',
    p_daily_session_limit INTEGER DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_card_owner_id UUID;
    v_new_token TEXT;
    v_token_id UUID;
    v_default_limit INTEGER;
BEGIN
    -- Get current user
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;
    
    -- Verify card ownership and get default limit
    SELECT user_id, default_daily_session_limit 
    INTO v_card_owner_id, v_default_limit
    FROM cards 
    WHERE id = p_card_id;
    
    IF v_card_owner_id IS NULL THEN
        RAISE EXCEPTION 'Card not found';
    END IF;
    
    IF v_card_owner_id != v_user_id THEN
        RAISE EXCEPTION 'Not authorized';
    END IF;
    
    -- Generate unique token
    v_new_token := generate_access_token();
    
    -- Use provided limit or fall back to card default
    IF p_daily_session_limit IS NULL THEN
        p_daily_session_limit := v_default_limit;
    END IF;
    
    -- Create the access token
    INSERT INTO card_access_tokens (
        card_id,
        name,
        access_token,
        daily_session_limit
    ) VALUES (
        p_card_id,
        COALESCE(p_name, 'Default'),
        v_new_token,
        p_daily_session_limit
    )
    RETURNING id INTO v_token_id;
    
    RETURN jsonb_build_object(
        'success', true,
        'token_id', v_token_id,
        'access_token', v_new_token,
        'name', COALESCE(p_name, 'Default')
    );
END;
$$;

-- Get all access tokens for a card
CREATE OR REPLACE FUNCTION get_card_access_tokens(p_card_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_card_owner_id UUID;
    v_tokens JSONB;
BEGIN
    -- Get current user
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;
    
    -- Verify card ownership
    SELECT user_id INTO v_card_owner_id
    FROM cards 
    WHERE id = p_card_id;
    
    IF v_card_owner_id IS NULL THEN
        RAISE EXCEPTION 'Card not found';
    END IF;
    
    IF v_card_owner_id != v_user_id THEN
        -- Check if user is admin
        IF NOT EXISTS (
            SELECT 1 FROM auth.users 
            WHERE id = v_user_id 
            AND (raw_app_meta_data->>'role' = 'admin' OR raw_user_meta_data->>'role' = 'admin')
        ) THEN
            RAISE EXCEPTION 'Not authorized';
        END IF;
    END IF;
    
    -- Get all tokens for the card
    SELECT COALESCE(jsonb_agg(
        jsonb_build_object(
            'id', t.id,
            'name', t.name,
            'access_token', t.access_token,
            'is_enabled', t.is_enabled,
            'daily_session_limit', t.daily_session_limit,
            'total_sessions', t.total_sessions,
            'daily_sessions', t.daily_sessions,
            'monthly_sessions', t.monthly_sessions,
            'last_session_date', t.last_session_date,
            'current_month', t.current_month,
            'created_at', t.created_at,
            'updated_at', t.updated_at
        ) ORDER BY t.created_at ASC
    ), '[]'::jsonb) INTO v_tokens
    FROM card_access_tokens t
    WHERE t.card_id = p_card_id;
    
    RETURN v_tokens;
END;
$$;

-- Update an access token's settings
CREATE OR REPLACE FUNCTION update_access_token(
    p_token_id UUID,
    p_name TEXT DEFAULT NULL,
    p_is_enabled BOOLEAN DEFAULT NULL,
    p_daily_session_limit INTEGER DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_card_owner_id UUID;
    v_card_id UUID;
BEGIN
    -- Get current user
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;
    
    -- Get card_id and verify ownership
    SELECT t.card_id, c.user_id 
    INTO v_card_id, v_card_owner_id
    FROM card_access_tokens t
    JOIN cards c ON c.id = t.card_id
    WHERE t.id = p_token_id;
    
    IF v_card_id IS NULL THEN
        RAISE EXCEPTION 'Token not found';
    END IF;
    
    IF v_card_owner_id != v_user_id THEN
        RAISE EXCEPTION 'Not authorized';
    END IF;
    
    -- Update the token
    UPDATE card_access_tokens
    SET
        name = COALESCE(p_name, name),
        is_enabled = COALESCE(p_is_enabled, is_enabled),
        daily_session_limit = CASE 
            WHEN p_daily_session_limit = -1 THEN NULL  -- -1 means unlimited
            WHEN p_daily_session_limit IS NOT NULL THEN p_daily_session_limit
            ELSE daily_session_limit
        END,
        updated_at = NOW()
    WHERE id = p_token_id;
    
    RETURN jsonb_build_object('success', true);
END;
$$;

-- Delete an access token
CREATE OR REPLACE FUNCTION delete_access_token(p_token_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_card_owner_id UUID;
    v_token_count INTEGER;
    v_card_id UUID;
BEGIN
    -- Get current user
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;
    
    -- Get card_id and verify ownership
    SELECT t.card_id, c.user_id 
    INTO v_card_id, v_card_owner_id
    FROM card_access_tokens t
    JOIN cards c ON c.id = t.card_id
    WHERE t.id = p_token_id;
    
    IF v_card_id IS NULL THEN
        RAISE EXCEPTION 'Token not found';
    END IF;
    
    IF v_card_owner_id != v_user_id THEN
        RAISE EXCEPTION 'Not authorized';
    END IF;
    
    -- Check if this is the last token (prevent deleting all tokens)
    SELECT COUNT(*) INTO v_token_count
    FROM card_access_tokens
    WHERE card_id = v_card_id;
    
    IF v_token_count <= 1 THEN
        RAISE EXCEPTION 'Cannot delete the last QR code. Each project must have at least one QR code.';
    END IF;
    
    -- Delete the token
    DELETE FROM card_access_tokens WHERE id = p_token_id;
    
    RETURN jsonb_build_object('success', true);
END;
$$;

-- Refresh (regenerate) an access token
CREATE OR REPLACE FUNCTION refresh_access_token(p_token_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_card_owner_id UUID;
    v_new_token TEXT;
BEGIN
    -- Get current user
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;
    
    -- Verify ownership
    SELECT c.user_id INTO v_card_owner_id
    FROM card_access_tokens t
    JOIN cards c ON c.id = t.card_id
    WHERE t.id = p_token_id;
    
    IF v_card_owner_id IS NULL THEN
        RAISE EXCEPTION 'Token not found';
    END IF;
    
    IF v_card_owner_id != v_user_id THEN
        RAISE EXCEPTION 'Not authorized';
    END IF;
    
    -- Generate new token
    v_new_token := generate_access_token();
    
    -- Update the token
    UPDATE card_access_tokens
    SET 
        access_token = v_new_token,
        updated_at = NOW()
    WHERE id = p_token_id;
    
    RETURN jsonb_build_object(
        'success', true,
        'access_token', v_new_token
    );
END;
$$;

-- Get monthly session stats for all tokens of a card
-- Returns data for the current billing month (1st to end of month)
CREATE OR REPLACE FUNCTION get_card_monthly_stats(p_card_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_card_owner_id UUID;
    v_current_month_start DATE;
    v_stats JSONB;
BEGIN
    -- Get current user
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;
    
    -- Verify card ownership
    SELECT user_id INTO v_card_owner_id
    FROM cards 
    WHERE id = p_card_id;
    
    IF v_card_owner_id IS NULL THEN
        RAISE EXCEPTION 'Card not found';
    END IF;
    
    IF v_card_owner_id != v_user_id THEN
        RAISE EXCEPTION 'Not authorized';
    END IF;
    
    -- Get current month start (1st of this month)
    v_current_month_start := date_trunc('month', CURRENT_DATE)::DATE;
    
    -- Aggregate stats
    SELECT jsonb_build_object(
        'month_start', v_current_month_start,
        'month_end', (v_current_month_start + INTERVAL '1 month' - INTERVAL '1 day')::DATE,
        'total_monthly_sessions', COALESCE(SUM(
            CASE WHEN current_month = v_current_month_start THEN monthly_sessions ELSE 0 END
        ), 0),
        'total_daily_sessions', COALESCE(SUM(
            CASE WHEN last_session_date = CURRENT_DATE THEN daily_sessions ELSE 0 END
        ), 0),
        'total_all_time_sessions', COALESCE(SUM(total_sessions), 0),
        'active_qr_codes', COUNT(*) FILTER (WHERE is_enabled = true),
        'total_qr_codes', COUNT(*)
    ) INTO v_stats
    FROM card_access_tokens
    WHERE card_id = p_card_id;
    
    RETURN v_stats;
END;
$$;

-- Note: Access token auto-creation is handled in create_card function
-- No trigger needed since all card creation goes through create_card
-- The delete_access_token function prevents deleting the last QR code

-- Drop legacy trigger if exists (cleanup)
DROP TRIGGER IF EXISTS trigger_ensure_access_token ON cards;
DROP FUNCTION IF EXISTS ensure_card_has_access_token() CASCADE;
DROP FUNCTION IF EXISTS migrate_legacy_access_tokens() CASCADE;

-- Grant permissions
GRANT EXECUTE ON FUNCTION generate_access_token() TO authenticated;
GRANT EXECUTE ON FUNCTION create_access_token(UUID, TEXT, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION get_card_access_tokens(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION update_access_token(UUID, TEXT, BOOLEAN, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION delete_access_token(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION refresh_access_token(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_card_monthly_stats(UUID) TO authenticated;



-- File: admin_credit_management.sql
-- -----------------------------------------------------------------
DROP FUNCTION IF EXISTS admin_get_credit_purchases CASCADE;
DROP FUNCTION IF EXISTS admin_get_credit_consumptions CASCADE;
DROP FUNCTION IF EXISTS admin_get_credit_transactions CASCADE;
DROP FUNCTION IF EXISTS admin_get_user_credits CASCADE;
DROP FUNCTION IF EXISTS admin_adjust_user_credits CASCADE;
DROP FUNCTION IF EXISTS admin_get_credit_statistics CASCADE;

-- Admin Credit Management Stored Procedures
-- Admin functions for credit system auditing and management

-- Drop functions first to allow return type changes
DROP FUNCTION IF EXISTS admin_get_credit_purchases(INTEGER, INTEGER, UUID, VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS admin_get_credit_consumptions(INTEGER, INTEGER, UUID, TIMESTAMPTZ, TIMESTAMPTZ) CASCADE;
DROP FUNCTION IF EXISTS admin_get_credit_transactions(INTEGER, INTEGER, UUID, VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS admin_get_user_credits(INTEGER, INTEGER, TEXT, TEXT, TEXT) CASCADE;
DROP FUNCTION IF EXISTS admin_adjust_user_credits(UUID, DECIMAL, TEXT) CASCADE;
DROP FUNCTION IF EXISTS admin_get_credit_statistics() CASCADE;

-- Admin: Get all credit purchases
CREATE OR REPLACE FUNCTION admin_get_credit_purchases(
    p_limit INTEGER DEFAULT 50,
    p_offset INTEGER DEFAULT 0,
    p_user_id UUID DEFAULT NULL,
    p_status VARCHAR DEFAULT NULL
)
RETURNS TABLE (
    id UUID,
    user_id UUID,
    user_email TEXT,
    user_name TEXT,
    amount_usd DECIMAL,
    credits_amount DECIMAL,
    status VARCHAR,
    stripe_session_id VARCHAR,
    payment_method JSONB,
    receipt_url TEXT,
    created_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ
) AS $$
DECLARE
    v_user_id UUID;
    v_role VARCHAR;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    -- Check if user is admin
    SELECT raw_user_meta_data->>'role' INTO v_role
    FROM auth.users
    WHERE auth.users.id = v_user_id;

    IF v_role != 'admin' THEN
        RAISE EXCEPTION 'Unauthorized: Admin access required';
    END IF;

    RETURN QUERY
    SELECT 
        cp.id,
        cp.user_id,
        u.email::TEXT AS user_email,
        COALESCE(u.raw_user_meta_data->>'full_name', u.email)::TEXT AS user_name,
        cp.amount_usd,
        cp.credits_amount,
        cp.status,
        cp.stripe_session_id,
        cp.payment_method,
        cp.receipt_url,
        cp.created_at,
        cp.completed_at
    FROM credit_purchases cp
    JOIN auth.users u ON u.id = cp.user_id
    WHERE (p_user_id IS NULL OR cp.user_id = p_user_id)
        AND (p_status IS NULL OR cp.status = p_status)
    ORDER BY cp.created_at DESC
    LIMIT p_limit
    OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Admin: Get all credit consumptions
CREATE OR REPLACE FUNCTION admin_get_credit_consumptions(
    p_limit INTEGER DEFAULT 50,
    p_offset INTEGER DEFAULT 0,
    p_user_id UUID DEFAULT NULL,
    p_date_from TIMESTAMPTZ DEFAULT NULL,
    p_date_to TIMESTAMPTZ DEFAULT NULL
)
RETURNS TABLE (
    id UUID,
    user_id UUID,
    user_email TEXT,
    user_name TEXT,
    card_id UUID,
    card_name TEXT,
    consumption_type VARCHAR,
    quantity INTEGER,
    credits_per_unit DECIMAL,
    total_credits DECIMAL,
    description TEXT,
    created_at TIMESTAMPTZ
) AS $$
DECLARE
    v_user_id UUID;
    v_role VARCHAR;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    -- Check if user is admin
    SELECT raw_user_meta_data->>'role' INTO v_role
    FROM auth.users
    WHERE auth.users.id = v_user_id;

    IF v_role != 'admin' THEN
        RAISE EXCEPTION 'Unauthorized: Admin access required';
    END IF;

    RETURN QUERY
    SELECT
        cc.id,
        cc.user_id,
        u.email::TEXT AS user_email,
        COALESCE(u.raw_user_meta_data->>'full_name', u.email)::TEXT AS user_name,
        cc.card_id,
        c.name AS card_name,
        cc.consumption_type,
        cc.quantity,
        cc.credits_per_unit,
        cc.total_credits,
        cc.description,
        cc.created_at
    FROM credit_consumptions cc
    JOIN auth.users u ON u.id = cc.user_id
    LEFT JOIN cards c ON c.id = cc.card_id
    WHERE (p_user_id IS NULL OR cc.user_id = p_user_id)
        AND (p_date_from IS NULL OR cc.created_at >= p_date_from)
        AND (p_date_to IS NULL OR cc.created_at <= p_date_to)
    ORDER BY cc.created_at DESC
    LIMIT p_limit
    OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Admin: Get all credit transactions
CREATE OR REPLACE FUNCTION admin_get_credit_transactions(
    p_limit INTEGER DEFAULT 50,
    p_offset INTEGER DEFAULT 0,
    p_user_id UUID DEFAULT NULL,
    p_type VARCHAR DEFAULT NULL
)
RETURNS TABLE (
    id UUID,
    user_id UUID,
    user_email TEXT,
    user_name TEXT,
    type VARCHAR,
    amount DECIMAL,
    balance_before DECIMAL,
    balance_after DECIMAL,
    reference_type VARCHAR,
    reference_id UUID,
    description TEXT,
    metadata JSONB,
    created_at TIMESTAMPTZ
) AS $$
DECLARE
    v_user_id UUID;
    v_role VARCHAR;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    -- Check if user is admin
    SELECT raw_user_meta_data->>'role' INTO v_role
    FROM auth.users
    WHERE auth.users.id = v_user_id;

    IF v_role != 'admin' THEN
        RAISE EXCEPTION 'Unauthorized: Admin access required';
    END IF;

    RETURN QUERY
    SELECT 
        ct.id,
        ct.user_id,
        u.email::TEXT AS user_email,
        COALESCE(u.raw_user_meta_data->>'full_name', u.email)::TEXT AS user_name,
        ct.type,
        ct.amount,
        ct.balance_before,
        ct.balance_after,
        ct.reference_type,
        ct.reference_id,
        ct.description,
        ct.metadata,
        ct.created_at
    FROM credit_transactions ct
    JOIN auth.users u ON u.id = ct.user_id
    WHERE (p_user_id IS NULL OR ct.user_id = p_user_id)
        AND (p_type IS NULL OR ct.type = p_type)
    ORDER BY ct.created_at DESC
    LIMIT p_limit
    OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Admin: Get user credit balances with search and pagination
CREATE OR REPLACE FUNCTION admin_get_user_credits(
    p_limit INTEGER DEFAULT 20,
    p_offset INTEGER DEFAULT 0,
    p_search TEXT DEFAULT NULL,
    p_sort_field TEXT DEFAULT 'balance',
    p_sort_order TEXT DEFAULT 'DESC'
)
RETURNS TABLE (
    user_id UUID,
    user_email TEXT,
    user_name TEXT,
    balance DECIMAL,
    total_purchased DECIMAL,
    total_consumed DECIMAL,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ,
    total_count BIGINT
) AS $$
DECLARE
    v_user_id UUID;
    v_role VARCHAR;
    v_total_count BIGINT;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    -- Check if user is admin
    SELECT raw_user_meta_data->>'role' INTO v_role
    FROM auth.users
    WHERE auth.users.id = v_user_id;

    IF v_role != 'admin' THEN
        RAISE EXCEPTION 'Unauthorized: Admin access required';
    END IF;

    -- Get total count for pagination
    SELECT COUNT(*) INTO v_total_count
    FROM user_credits uc
    JOIN auth.users u ON u.id = uc.user_id
    WHERE (p_search IS NULL OR p_search = '' OR 
           LOWER(u.email) LIKE '%' || LOWER(p_search) || '%' OR
           LOWER(COALESCE(u.raw_user_meta_data->>'full_name', '')) LIKE '%' || LOWER(p_search) || '%');

    -- Return paginated results with total count
    RETURN QUERY EXECUTE format(
        'SELECT 
            uc.user_id,
            u.email::TEXT AS user_email,
            COALESCE(u.raw_user_meta_data->>''full_name'', u.email)::TEXT AS user_name,
            uc.balance,
            uc.total_purchased,
            uc.total_consumed,
            uc.created_at,
            uc.updated_at,
            $1 AS total_count
        FROM user_credits uc
        JOIN auth.users u ON u.id = uc.user_id
        WHERE ($2 IS NULL OR $2 = '''' OR 
               LOWER(u.email) LIKE ''%%'' || LOWER($2) || ''%%'' OR
               LOWER(COALESCE(u.raw_user_meta_data->>''full_name'', '''')) LIKE ''%%'' || LOWER($2) || ''%%'')
        ORDER BY %s %s
        LIMIT $3
        OFFSET $4',
        CASE 
            WHEN p_sort_field IN ('user_email', 'user_name') THEN 'u.email'
            WHEN p_sort_field IN ('balance', 'total_purchased', 'total_consumed', 'created_at', 'updated_at') THEN 'uc.' || p_sort_field
            ELSE 'uc.balance'
        END,
        CASE WHEN UPPER(p_sort_order) = 'ASC' THEN 'ASC' ELSE 'DESC' END
    )
    USING v_total_count, p_search, p_limit, p_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Admin: Adjust user credits (for refunds, corrections, etc.)
CREATE OR REPLACE FUNCTION admin_adjust_user_credits(
    p_target_user_id UUID,
    p_amount DECIMAL,
    p_reason TEXT
)
RETURNS JSONB AS $$
DECLARE
    v_admin_id UUID;
    v_role VARCHAR;
    v_current_balance DECIMAL;
    v_new_balance DECIMAL;
    v_transaction_id UUID;
    v_adjustment_type VARCHAR;
BEGIN
    v_admin_id := auth.uid();
    IF v_admin_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    -- Check if user is admin
    SELECT raw_user_meta_data->>'role' INTO v_role
    FROM auth.users
    WHERE auth.users.id = v_admin_id;

    IF v_role != 'admin' THEN
        RAISE EXCEPTION 'Unauthorized: Admin access required';
    END IF;

    -- Initialize credits if not exists
    INSERT INTO user_credits (user_id, balance)
    VALUES (p_target_user_id, 0)
    ON CONFLICT (user_id) DO NOTHING;

    -- Lock the user credits row for update
    SELECT balance INTO v_current_balance
    FROM user_credits
    WHERE user_id = p_target_user_id
    FOR UPDATE;

    v_new_balance := v_current_balance + p_amount;

    IF v_new_balance < 0 THEN
        RAISE EXCEPTION 'Adjustment would result in negative balance';
    END IF;

    -- Update user credits
    UPDATE user_credits
    SET 
        balance = v_new_balance,
        total_purchased = CASE 
            WHEN p_amount > 0 THEN total_purchased + p_amount
            ELSE total_purchased
        END,
        updated_at = CURRENT_TIMESTAMP
    WHERE user_id = p_target_user_id;

    -- Determine adjustment type
    IF p_amount > 0 THEN
        v_adjustment_type := 'adjustment';
    ELSIF p_amount < 0 THEN
        v_adjustment_type := 'consumption';
    ELSE
        RAISE EXCEPTION 'Adjustment amount cannot be zero';
    END IF;

    -- Record transaction
    INSERT INTO credit_transactions (
        user_id, type, amount, balance_before, balance_after,
        reference_type, description, metadata
    ) VALUES (
        p_target_user_id, v_adjustment_type, ABS(p_amount), 
        v_current_balance, v_new_balance,
        'admin_adjustment', p_reason,
        jsonb_build_object('admin_id', v_admin_id, 'admin_action', true)
    ) RETURNING id INTO v_transaction_id;

    -- Log the operation
    PERFORM log_operation(
        format('Admin adjusted credits for user %s: %s%s credits - %s',
            p_target_user_id,
            CASE WHEN p_amount > 0 THEN '+' ELSE '' END,
            p_amount, p_reason)
    );

    RETURN jsonb_build_object(
        'success', true,
        'transaction_id', v_transaction_id,
        'amount_adjusted', p_amount,
        'new_balance', v_new_balance,
        'previous_balance', v_current_balance
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Admin: Get credit system statistics
CREATE OR REPLACE FUNCTION admin_get_credit_statistics()
RETURNS JSONB AS $$
DECLARE
    v_user_id UUID;
    v_role VARCHAR;
    v_stats JSONB;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    -- Check if user is admin
    SELECT raw_user_meta_data->>'role' INTO v_role
    FROM auth.users
    WHERE auth.users.id = v_user_id;

    IF v_role != 'admin' THEN
        RAISE EXCEPTION 'Unauthorized: Admin access required';
    END IF;

    SELECT jsonb_build_object(
        'total_credits_in_circulation', COALESCE(SUM(balance), 0),
        'total_credits_purchased', COALESCE(SUM(total_purchased), 0),
        'total_credits_consumed', COALESCE(SUM(total_consumed), 0),
        'total_users_with_credits', COUNT(*),
        'total_revenue_usd', (
            SELECT COALESCE(SUM(amount_usd), 0)
            FROM credit_purchases
            WHERE status = 'completed'
        ),
        'monthly_purchases', (
            SELECT COALESCE(SUM(amount_usd), 0)
            FROM credit_purchases
            WHERE status = 'completed'
                AND created_at >= date_trunc('month', CURRENT_DATE)
        ),
        'monthly_consumption', (
            SELECT COALESCE(SUM(total_credits), 0)
            FROM credit_consumptions
            WHERE created_at >= date_trunc('month', CURRENT_DATE)
        ),
        'pending_purchases', (
            SELECT COUNT(*)
            FROM credit_purchases
            WHERE status = 'pending'
        )
    ) INTO v_stats
    FROM user_credits;

    RETURN v_stats;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================================
-- GRANT PERMISSIONS - Admin functions require authenticated role
-- =====================================================================
-- Note: Admin check is done inside each function via raw_user_meta_data->>'role'
-- This ensures only users with 'admin' role can access the data even with GRANT

GRANT EXECUTE ON FUNCTION admin_get_credit_purchases(INTEGER, INTEGER, UUID, VARCHAR) TO authenticated;
GRANT EXECUTE ON FUNCTION admin_get_credit_consumptions(INTEGER, INTEGER, UUID, TIMESTAMPTZ, TIMESTAMPTZ) TO authenticated;
GRANT EXECUTE ON FUNCTION admin_get_credit_transactions(INTEGER, INTEGER, UUID, VARCHAR) TO authenticated;
GRANT EXECUTE ON FUNCTION admin_get_user_credits(INTEGER, INTEGER, TEXT, TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION admin_adjust_user_credits(UUID, DECIMAL, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION admin_get_credit_statistics() TO authenticated;


-- File: credit_management.sql
-- -----------------------------------------------------------------
DROP FUNCTION IF EXISTS initialize_user_credits CASCADE;
DROP FUNCTION IF EXISTS get_user_credits CASCADE;
DROP FUNCTION IF EXISTS check_credit_balance CASCADE;
DROP FUNCTION IF EXISTS consume_credits CASCADE;
DROP FUNCTION IF EXISTS get_credit_transactions CASCADE;
DROP FUNCTION IF EXISTS get_credit_purchases CASCADE;
DROP FUNCTION IF EXISTS get_credit_consumptions CASCADE;
DROP FUNCTION IF EXISTS create_credit_purchase CASCADE;
DROP FUNCTION IF EXISTS get_credit_statistics CASCADE;
DROP FUNCTION IF EXISTS consume_credit_for_digital_scan CASCADE;

-- Credit Management Stored Procedures
-- Client-side functions for credit purchase, consumption, and management

-- Initialize user credits (called when user first needs credits)
CREATE OR REPLACE FUNCTION initialize_user_credits()
RETURNS user_credits AS $$
DECLARE
    v_user_id UUID;
    v_credits user_credits;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    -- Insert or get existing credits record
    INSERT INTO user_credits (user_id, balance, total_purchased, total_consumed)
    VALUES (v_user_id, 0, 0, 0)
    ON CONFLICT (user_id) DO NOTHING
    RETURNING * INTO v_credits;

    IF v_credits.id IS NULL THEN
        SELECT * INTO v_credits FROM user_credits WHERE user_id = v_user_id;
    END IF;

    RETURN v_credits;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get user credit balance
CREATE OR REPLACE FUNCTION get_user_credits()
RETURNS TABLE (
    balance DECIMAL,
    total_purchased DECIMAL,
    total_consumed DECIMAL,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ
) AS $$
DECLARE
    v_user_id UUID;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    -- Initialize credits if not exists
    PERFORM initialize_user_credits();

    RETURN QUERY
    SELECT 
        uc.balance,
        uc.total_purchased,
        uc.total_consumed,
        uc.created_at,
        uc.updated_at
    FROM user_credits uc
    WHERE uc.user_id = v_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Check if user has sufficient credits
CREATE OR REPLACE FUNCTION check_credit_balance(
    p_required_credits DECIMAL,
    p_user_id UUID DEFAULT NULL
)
RETURNS DECIMAL AS $$
DECLARE
    v_user_id UUID;
    v_balance DECIMAL;
BEGIN
    -- Use provided user_id or fall back to auth.uid()
    v_user_id := COALESCE(p_user_id, auth.uid());
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    SELECT balance INTO v_balance
    FROM user_credits
    WHERE user_id = v_user_id;

    IF v_balance IS NULL THEN
        -- Initialize credits if not exists
        PERFORM initialize_user_credits();
        v_balance := 0;
    END IF;

    -- Return the actual balance (not a boolean check)
    RETURN v_balance;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Generic function to consume credits
CREATE OR REPLACE FUNCTION consume_credits(
    p_credits_to_consume DECIMAL,
    p_user_id UUID DEFAULT NULL,
    p_consumption_type VARCHAR DEFAULT 'other',
    p_metadata JSONB DEFAULT '{}'::jsonb
)
RETURNS VOID AS $$
DECLARE
    v_user_id UUID;
    v_current_balance DECIMAL;
    v_new_balance DECIMAL;
    v_consumption_id UUID;
    v_transaction_id UUID;
BEGIN
    -- Use provided user_id or fall back to auth.uid()
    v_user_id := COALESCE(p_user_id, auth.uid());
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    -- Lock the user credits row for update
    SELECT balance INTO v_current_balance
    FROM user_credits
    WHERE user_id = v_user_id
    FOR UPDATE;

    IF v_current_balance IS NULL OR v_current_balance < p_credits_to_consume THEN
        RAISE EXCEPTION 'Insufficient credits. Required: %, Available: %', 
            p_credits_to_consume, COALESCE(v_current_balance, 0);
    END IF;

    v_new_balance := v_current_balance - p_credits_to_consume;

    -- Update user credits
    UPDATE user_credits
    SET 
        balance = v_new_balance,
        total_consumed = total_consumed + p_credits_to_consume,
        updated_at = CURRENT_TIMESTAMP
    WHERE user_id = v_user_id;

    -- Record consumption (card_id from metadata if available)
    INSERT INTO credit_consumptions (
        user_id, card_id, consumption_type, quantity, 
        credits_per_unit, total_credits, description
    ) VALUES (
        v_user_id, 
        (p_metadata->>'card_id')::UUID,
        p_consumption_type, 
        (p_metadata->>'language_count')::INTEGER,
        1.00, -- 1 credit per language for translations
        p_credits_to_consume,
        format('%s: %s credits', p_consumption_type, p_credits_to_consume)
    ) RETURNING id INTO v_consumption_id;

    -- Record transaction
    INSERT INTO credit_transactions (
        user_id, type, amount, balance_before, balance_after,
        reference_type, reference_id, description, metadata
    ) VALUES (
        v_user_id, 'consumption', -p_credits_to_consume,
        v_current_balance, v_new_balance,
        p_consumption_type, v_consumption_id,
        format('Credit consumption: %s', p_consumption_type),
        p_metadata
    ) RETURNING id INTO v_transaction_id;

    -- Log operation
    PERFORM log_operation(
        format('Credit consumption: %s credits for %s - New balance: %s (Transaction ID: %s)',
            p_credits_to_consume, p_consumption_type, v_new_balance, v_transaction_id)
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get credit transaction history
CREATE OR REPLACE FUNCTION get_credit_transactions(
    p_limit INTEGER DEFAULT 50,
    p_offset INTEGER DEFAULT 0,
    p_type VARCHAR DEFAULT NULL
)
RETURNS TABLE (
    id UUID,
    type VARCHAR,
    amount DECIMAL,
    balance_before DECIMAL,
    balance_after DECIMAL,
    reference_type VARCHAR,
    reference_id UUID,
    description TEXT,
    metadata JSONB,
    created_at TIMESTAMPTZ
) AS $$
DECLARE
    v_user_id UUID;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    RETURN QUERY
    SELECT 
        ct.id,
        ct.type,
        ct.amount,
        ct.balance_before,
        ct.balance_after,
        ct.reference_type,
        ct.reference_id,
        ct.description,
        ct.metadata,
        ct.created_at
    FROM credit_transactions ct
    WHERE ct.user_id = v_user_id
        AND (p_type IS NULL OR ct.type = p_type)
    ORDER BY ct.created_at DESC
    LIMIT p_limit
    OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get credit purchase history
CREATE OR REPLACE FUNCTION get_credit_purchases(
    p_limit INTEGER DEFAULT 50,
    p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
    id UUID,
    amount_usd DECIMAL,
    credits_amount DECIMAL,
    status VARCHAR,
    payment_method JSONB,
    receipt_url TEXT,
    created_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ
) AS $$
DECLARE
    v_user_id UUID;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    RETURN QUERY
    SELECT 
        cp.id,
        cp.amount_usd,
        cp.credits_amount,
        cp.status,
        cp.payment_method,
        cp.receipt_url,
        cp.created_at,
        cp.completed_at
    FROM credit_purchases cp
    WHERE cp.user_id = v_user_id
    ORDER BY cp.created_at DESC
    LIMIT p_limit
    OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get credit consumption history
CREATE OR REPLACE FUNCTION get_credit_consumptions(
    p_limit INTEGER DEFAULT 50,
    p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
    id UUID,
    card_id UUID,
    consumption_type VARCHAR,
    quantity INTEGER,
    credits_per_unit DECIMAL,
    total_credits DECIMAL,
    description TEXT,
    created_at TIMESTAMPTZ,
    card_name TEXT
) AS $$
DECLARE
    v_user_id UUID;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    RETURN QUERY
    SELECT
        cc.id,
        cc.card_id,
        cc.consumption_type,
        cc.quantity,
        cc.credits_per_unit,
        cc.total_credits,
        cc.description,
        cc.created_at,
        c.name AS card_name
    FROM credit_consumptions cc
    LEFT JOIN cards c ON c.id = cc.card_id
    WHERE cc.user_id = v_user_id
    ORDER BY cc.created_at DESC
    LIMIT p_limit
    OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create credit purchase record (called from Edge Function after Stripe checkout)
CREATE OR REPLACE FUNCTION create_credit_purchase(
    p_stripe_session_id VARCHAR,
    p_amount_usd DECIMAL,
    p_credits_amount DECIMAL,
    p_metadata JSONB DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_user_id UUID;
    v_purchase_id UUID;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    INSERT INTO credit_purchases (
        user_id, stripe_session_id, amount_usd, credits_amount, 
        status, metadata
    ) VALUES (
        v_user_id, p_stripe_session_id, p_amount_usd, p_credits_amount,
        'pending', p_metadata
    ) RETURNING id INTO v_purchase_id;

    -- Log the operation
    PERFORM log_operation(
        format('Created credit purchase: %s credits ($%s USD) - Session: %s',
            p_credits_amount, p_amount_usd, p_stripe_session_id)
    );

    RETURN v_purchase_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get credit statistics for dashboard
CREATE OR REPLACE FUNCTION get_credit_statistics()
RETURNS JSONB AS $$
DECLARE
    v_user_id UUID;
    v_stats JSONB;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    SELECT jsonb_build_object(
        'current_balance', COALESCE(uc.balance, 0),
        'total_purchased', COALESCE(uc.total_purchased, 0),
        'total_consumed', COALESCE(uc.total_consumed, 0),
        'recent_transactions', (
            SELECT jsonb_agg(
                jsonb_build_object(
                    'id', ct.id,
                    'type', ct.type,
                    'amount', ct.amount,
                    'description', ct.description,
                    'created_at', ct.created_at
                ) ORDER BY ct.created_at DESC
            )
            FROM (
                SELECT * FROM credit_transactions
                WHERE user_id = v_user_id
                ORDER BY created_at DESC
                LIMIT 5
            ) ct
        ),
        'monthly_consumption', (
            SELECT COALESCE(SUM(total_credits), 0)
            FROM credit_consumptions
            WHERE user_id = v_user_id
                AND created_at >= date_trunc('month', CURRENT_DATE)
        ),
        'monthly_purchases', (
            SELECT COALESCE(SUM(credits_amount), 0)
            FROM credit_purchases
            WHERE user_id = v_user_id
                AND status = 'completed'
                AND created_at >= date_trunc('month', CURRENT_DATE)
        )
    ) INTO v_stats
    FROM user_credits uc
    WHERE uc.user_id = v_user_id;

    RETURN COALESCE(v_stats, jsonb_build_object(
        'current_balance', 0,
        'total_purchased', 0,
        'total_consumed', 0,
        'recent_transactions', '[]'::jsonb,
        'monthly_consumption', 0,
        'monthly_purchases', 0
    ));
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================================
-- DIGITAL ACCESS CREDIT CONSUMPTION
-- =====================================================================
-- Consume credits for digital access scan with DAILY AGGREGATION
-- Called internally by get_public_card_content when a non-owner accesses a digital card
-- 
-- BEST PRACTICE: Instead of creating a new record per scan (fragmented),
-- we aggregate all scans for the same card on the same day into ONE record.
-- This reduces 1000 scans/day from 2000 records to just 2 records!
--
-- Daily Aggregation Logic:
-- 1. First scan of day for a card → INSERT new consumption record
-- 2. Subsequent scans → UPDATE existing record (increment quantity & total)
-- 3. Transaction log: One entry per day per card (updated in place)
--
-- Returns JSONB with success status and error details
CREATE OR REPLACE FUNCTION consume_credit_for_digital_scan(
    p_card_id UUID,
    p_owner_id UUID,
    p_credit_rate DECIMAL DEFAULT 0.03
)
RETURNS JSONB AS $$
DECLARE
    v_current_balance DECIMAL;
    v_new_balance DECIMAL;
    v_consumption_id UUID;
    v_transaction_id UUID;
    v_card_name TEXT;
    v_today DATE := CURRENT_DATE;
    v_existing_consumption_id UUID;
    v_existing_transaction_id UUID;
    v_existing_quantity INT;
    v_existing_total_credits DECIMAL;
    v_balance_before_today DECIMAL;
BEGIN
    -- Get card name for logging
    SELECT name INTO v_card_name FROM cards WHERE id = p_card_id;

    -- Lock the owner's credits row for update
    SELECT balance INTO v_current_balance
    FROM user_credits
    WHERE user_id = p_owner_id
    FOR UPDATE;

    -- Check if owner has credits initialized
    IF v_current_balance IS NULL THEN
        -- Try to initialize credits for owner
        INSERT INTO user_credits (user_id, balance, total_purchased, total_consumed)
        VALUES (p_owner_id, 0, 0, 0)
        ON CONFLICT (user_id) DO NOTHING;
        
        SELECT balance INTO v_current_balance
        FROM user_credits
        WHERE user_id = p_owner_id;
        
        IF v_current_balance IS NULL THEN
            v_current_balance := 0;
        END IF;
    END IF;

    -- Check if owner has sufficient credits
    IF v_current_balance < p_credit_rate THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'credits_insufficient',
            'message', 'Card owner has insufficient credits',
            'required', p_credit_rate,
            'available', v_current_balance
        );
    END IF;

    v_new_balance := v_current_balance - p_credit_rate;

    -- Update owner's credits (real-time balance update)
    UPDATE user_credits
    SET 
        balance = v_new_balance,
        total_consumed = total_consumed + p_credit_rate,
        updated_at = CURRENT_TIMESTAMP
    WHERE user_id = p_owner_id;

    -- ===== DAILY AGGREGATION FOR CONSUMPTIONS =====
    -- Check if there's already a consumption record for this card today
    SELECT id, quantity, total_credits INTO v_existing_consumption_id, v_existing_quantity, v_existing_total_credits
    FROM credit_consumptions
    WHERE user_id = p_owner_id 
      AND card_id = p_card_id 
      AND consumption_type = 'digital_scan'
      AND DATE(created_at) = v_today
    LIMIT 1;

    IF v_existing_consumption_id IS NOT NULL THEN
        -- UPDATE existing record (aggregate scans)
        UPDATE credit_consumptions
        SET 
            quantity = v_existing_quantity + 1,
            total_credits = v_existing_total_credits + p_credit_rate,
            description = format('Digital access: %s (%s scans today)', 
                                 COALESCE(v_card_name, p_card_id::TEXT), 
                                 v_existing_quantity + 1),
            updated_at = CURRENT_TIMESTAMP
        WHERE id = v_existing_consumption_id;
        
        v_consumption_id := v_existing_consumption_id;
    ELSE
        -- INSERT new record for today (first scan)
        INSERT INTO credit_consumptions (
            user_id, card_id, consumption_type, quantity, 
            credits_per_unit, total_credits, description
        ) VALUES (
            p_owner_id, p_card_id, 'digital_scan', 1,
            p_credit_rate, p_credit_rate,
            format('Digital access: %s (1 scan today)', COALESCE(v_card_name, p_card_id::TEXT))
        ) RETURNING id INTO v_consumption_id;
    END IF;

    -- ===== DAILY AGGREGATION FOR TRANSACTIONS =====
    -- Check if there's already a transaction record for this card today
    SELECT id, amount, balance_before INTO v_existing_transaction_id, v_existing_total_credits, v_balance_before_today
    FROM credit_transactions
    WHERE user_id = p_owner_id 
      AND reference_type = 'digital_scan'
      AND reference_id = p_card_id
      AND DATE(created_at) = v_today
      AND type = 'consumption'
    LIMIT 1;

    IF v_existing_transaction_id IS NOT NULL THEN
        -- UPDATE existing transaction (aggregate daily spend)
        UPDATE credit_transactions
        SET 
            amount = v_existing_total_credits + p_credit_rate,
            balance_after = v_new_balance,
            description = format('Digital access: %s (%s credits today)', 
                                 COALESCE(v_card_name, 'Card'), 
                                 ROUND(v_existing_total_credits + p_credit_rate, 2)::TEXT),
            updated_at = CURRENT_TIMESTAMP
        WHERE id = v_existing_transaction_id;
        
        v_transaction_id := v_existing_transaction_id;
    ELSE
        -- INSERT new transaction for today (first scan)
        INSERT INTO credit_transactions (
            user_id, type, amount, balance_before, balance_after,
            reference_type, reference_id, description
        ) VALUES (
            p_owner_id, 'consumption', p_credit_rate, v_current_balance, v_new_balance,
            'digital_scan', p_card_id,
            format('Digital access: %s (%s credits today)', COALESCE(v_card_name, 'Card'), ROUND(p_credit_rate, 2)::TEXT)
        ) RETURNING id INTO v_transaction_id;
    END IF;

    RETURN jsonb_build_object(
        'success', true,
        'consumption_id', v_consumption_id,
        'transaction_id', v_transaction_id,
        'credits_consumed', p_credit_rate,
        'new_balance', v_new_balance,
        'aggregation', 'daily'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute to service_role (called internally by get_public_card_content)
GRANT EXECUTE ON FUNCTION consume_credit_for_digital_scan(UUID, UUID, DECIMAL) TO service_role, authenticated;

COMMENT ON FUNCTION consume_credit_for_digital_scan(UUID, UUID, DECIMAL) IS 
  'Consumes credits from card owner for digital access scan with DAILY AGGREGATION. 
   Instead of creating one record per scan, aggregates all scans for the same card 
   on the same day into a single record. This prevents table fragmentation and keeps 
   the credit management UI clean. Called internally by get_public_card_content.';

-- =====================================================================
-- GRANT PERMISSIONS
-- =====================================================================
-- NOTE: Some functions use a "dual-use pattern" with COALESCE(p_user_id, auth.uid())
-- These can be called from:
--   - Frontend: Without p_user_id, uses auth.uid() from JWT
--   - Edge Functions: With explicit p_user_id parameter using SERVICE_ROLE_KEY
-- =====================================================================

-- Dual-use functions (called from frontend AND Edge Functions with SERVICE_ROLE_KEY)
GRANT EXECUTE ON FUNCTION check_credit_balance(DECIMAL, UUID) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION consume_credits(DECIMAL, UUID, VARCHAR, JSONB) TO authenticated, service_role;
-- Note: create_credit_purchase_record is server-side only (see server-side/credit_purchase_completion.sql)

-- Client-only functions
GRANT EXECUTE ON FUNCTION initialize_user_credits() TO authenticated;
GRANT EXECUTE ON FUNCTION get_credit_statistics() TO authenticated;
GRANT EXECUTE ON FUNCTION get_user_credits() TO authenticated;

-- Add documentation comments
COMMENT ON FUNCTION check_credit_balance(DECIMAL, UUID) IS 
  'DUAL-USE PATTERN: Accepts optional p_user_id (for Edge Functions with SERVICE_ROLE_KEY) or falls back to auth.uid() (for frontend with user JWT). Granted to both authenticated and service_role roles.';

-- Note: create_credit_purchase_record is server-side only (see server-side/credit_purchase_completion.sql)
-- It requires explicit p_user_id and is only accessible via service_role (backend)
  
COMMENT ON FUNCTION consume_credits(DECIMAL, UUID, VARCHAR, JSONB) IS 
  'DUAL-USE PATTERN: Accepts optional p_user_id (for server-side stored procedures) or falls back to auth.uid() (for direct frontend calls). Granted to both authenticated and service_role roles.';

COMMENT ON FUNCTION initialize_user_credits() IS 
  'CLIENT-ONLY: Uses auth.uid() from user JWT. Creates initial credit record for authenticated user.';

COMMENT ON FUNCTION get_credit_statistics() IS 
  'CLIENT-ONLY: Uses auth.uid() from user JWT. Returns credit statistics for authenticated user including balance, purchases, consumptions.';

COMMENT ON FUNCTION get_user_credits() IS 
  'CLIENT-ONLY: Uses auth.uid() from user JWT. Returns current credit balance for authenticated user.';




-- =================================================================
-- SERVER-SIDE PROCEDURES
-- =================================================================

-- File: access_logging.sql
-- -----------------------------------------------------------------
DROP FUNCTION IF EXISTS get_recent_access_logs_server CASCADE;
DROP FUNCTION IF EXISTS get_daily_access_stats_server CASCADE;
DROP FUNCTION IF EXISTS insert_access_log_server CASCADE;

-- =================================================================
-- ACCESS LOGGING - SERVER-SIDE STORED PROCEDURES
-- =================================================================
-- All access log related database operations from Express backend.
-- Called by backend Express server with service_role permissions.
-- =================================================================

-- Get recent access logs for user
DROP FUNCTION IF EXISTS get_recent_access_logs_server CASCADE;
CREATE OR REPLACE FUNCTION get_recent_access_logs_server(
    p_user_id UUID,
    p_limit INTEGER DEFAULT 10
)
RETURNS TABLE (
    id UUID,
    card_id UUID,
    visitor_hash TEXT,
    accessed_at TIMESTAMPTZ,
    subscription_tier TEXT,
    was_overage BOOLEAN,
    is_owner_access BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        cal.id,
        cal.card_id,
        cal.visitor_hash,
        cal.accessed_at,
        cal.subscription_tier::TEXT,
        cal.was_overage,
        cal.is_owner_access
    FROM card_access_log cal
    WHERE cal.card_owner_id = p_user_id
    ORDER BY cal.accessed_at DESC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get daily access stats for chart
DROP FUNCTION IF EXISTS get_daily_access_stats_server CASCADE;
CREATE OR REPLACE FUNCTION get_daily_access_stats_server(
    p_user_id UUID,
    p_start_date TIMESTAMPTZ,
    p_end_date TIMESTAMPTZ
)
RETURNS TABLE (
    accessed_at TIMESTAMPTZ,
    was_overage BOOLEAN,
    is_ai_enabled BOOLEAN,
    session_cost_usd DECIMAL(10, 4)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        cal.accessed_at, 
        cal.was_overage,
        COALESCE(cal.is_ai_enabled, FALSE) AS is_ai_enabled,
        COALESCE(cal.session_cost_usd, 0) AS session_cost_usd
    FROM card_access_log cal
    WHERE cal.card_owner_id = p_user_id
      AND cal.is_owner_access = FALSE
      AND cal.accessed_at >= p_start_date
      AND cal.accessed_at <= p_end_date
    ORDER BY cal.accessed_at ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Insert access log (with session-based billing fields)
DROP FUNCTION IF EXISTS insert_access_log_server CASCADE;
CREATE OR REPLACE FUNCTION insert_access_log_server(
    p_card_id UUID,
    p_visitor_hash TEXT,
    p_card_owner_id UUID,
    p_subscription_tier TEXT,
    p_is_owner_access BOOLEAN,
    p_was_overage BOOLEAN,
    p_credit_charged BOOLEAN,
    -- Optional session-based billing fields (default to legacy values if not provided)
    p_session_id TEXT DEFAULT NULL,
    p_session_cost_usd DECIMAL DEFAULT 0,
    p_is_ai_enabled BOOLEAN DEFAULT FALSE
)
RETURNS UUID AS $$
DECLARE
    v_id UUID;
BEGIN
    INSERT INTO card_access_log (
        card_id, visitor_hash, card_owner_id,
        subscription_tier, is_owner_access, was_overage, credit_charged,
        session_id, session_cost_usd, is_ai_enabled
    ) VALUES (
        p_card_id, p_visitor_hash, p_card_owner_id,
        p_subscription_tier, p_is_owner_access, p_was_overage, p_credit_charged,
        COALESCE(p_session_id, p_visitor_hash), -- Use visitor_hash as session_id if not provided
        p_session_cost_usd,
        p_is_ai_enabled
    )
    RETURNING id INTO v_id;
    
    RETURN v_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =================================================================
-- GRANTS - Only service_role can execute these
-- =================================================================
REVOKE ALL ON FUNCTION get_recent_access_logs_server FROM PUBLIC, authenticated, anon;
GRANT EXECUTE ON FUNCTION get_recent_access_logs_server TO service_role;

REVOKE ALL ON FUNCTION get_daily_access_stats_server FROM PUBLIC, authenticated, anon;
GRANT EXECUTE ON FUNCTION get_daily_access_stats_server TO service_role;

REVOKE ALL ON FUNCTION insert_access_log_server FROM PUBLIC, authenticated, anon;
GRANT EXECUTE ON FUNCTION insert_access_log_server TO service_role;



-- File: access_token_operations.sql
-- -----------------------------------------------------------------
DROP FUNCTION IF EXISTS get_card_by_access_token_server CASCADE;
DROP FUNCTION IF EXISTS update_token_session_counters_server CASCADE;
DROP FUNCTION IF EXISTS reset_daily_token_counters_server CASCADE;
DROP FUNCTION IF EXISTS reset_monthly_token_counters_server CASCADE;
DROP FUNCTION IF EXISTS get_token_daily_limit_server CASCADE;

-- =====================================================
-- Access Token Server-Side Operations
-- Backend-only procedures for mobile client access
-- =====================================================

-- Get card data by access token (for mobile client)
-- Returns card info and token-specific settings
CREATE OR REPLACE FUNCTION get_card_by_access_token_server(
    p_access_token TEXT,
    p_language TEXT DEFAULT 'en'
)
RETURNS TABLE (
    -- Card fields
    card_id UUID,
    card_name TEXT,
    card_description TEXT,
    card_image_url TEXT,
    card_content_mode TEXT,
    card_is_grouped BOOLEAN,
    card_group_display TEXT,
    card_ai_enabled BOOLEAN,
    card_ai_instruction TEXT,
    card_ai_knowledge_base TEXT,
    card_ai_welcome_general TEXT,
    card_ai_welcome_item TEXT,
    card_owner_id UUID,
    card_billing_type TEXT,
    -- Token-specific fields
    token_id UUID,
    token_name TEXT,
    token_is_enabled BOOLEAN,
    token_daily_session_limit INTEGER,
    token_daily_sessions INTEGER,
    token_monthly_sessions INTEGER,
    token_total_sessions INTEGER,
    -- Template check
    is_template BOOLEAN
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.id AS card_id,
        COALESCE(c.translations->p_language->>'name', c.name)::TEXT AS card_name,
        COALESCE(c.translations->p_language->>'description', c.description)::TEXT AS card_description,
        c.image_url AS card_image_url,
        c.content_mode AS card_content_mode,
        c.is_grouped AS card_is_grouped,
        c.group_display AS card_group_display,
        c.conversation_ai_enabled AS card_ai_enabled,
        COALESCE(c.translations->p_language->>'ai_instruction', c.ai_instruction)::TEXT AS card_ai_instruction,
        COALESCE(c.translations->p_language->>'ai_knowledge_base', c.ai_knowledge_base)::TEXT AS card_ai_knowledge_base,
        COALESCE(c.translations->p_language->>'ai_welcome_general', c.ai_welcome_general)::TEXT AS card_ai_welcome_general,
        COALESCE(c.translations->p_language->>'ai_welcome_item', c.ai_welcome_item)::TEXT AS card_ai_welcome_item,
        c.user_id AS card_owner_id,
        c.billing_type AS card_billing_type,
        -- Token fields
        t.id AS token_id,
        t.name AS token_name,
        t.is_enabled AS token_is_enabled,
        t.daily_session_limit AS token_daily_session_limit,
        t.daily_sessions AS token_daily_sessions,
        t.monthly_sessions AS token_monthly_sessions,
        t.total_sessions AS token_total_sessions,
        -- Template check
        EXISTS(SELECT 1 FROM content_templates ct WHERE ct.card_id = c.id) AS is_template
    FROM card_access_tokens t
    JOIN cards c ON c.id = t.card_id
    WHERE t.access_token = p_access_token;
END;
$$;

-- Update token session counters (called from backend after successful access)
CREATE OR REPLACE FUNCTION update_token_session_counters_server(
    p_token_id UUID,
    p_daily_sessions INTEGER,
    p_monthly_sessions INTEGER,
    p_total_sessions INTEGER
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_current_month_start DATE;
BEGIN
    v_current_month_start := date_trunc('month', CURRENT_DATE)::DATE;
    
    UPDATE card_access_tokens
    SET 
        daily_sessions = p_daily_sessions,
        monthly_sessions = p_monthly_sessions,
        total_sessions = total_sessions + 1,
        last_session_date = CURRENT_DATE,
        current_month = v_current_month_start,
        updated_at = NOW()
    WHERE id = p_token_id;
END;
$$;

-- Reset daily counters for tokens where date has changed
CREATE OR REPLACE FUNCTION reset_daily_token_counters_server()
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_reset_count INTEGER;
BEGIN
    UPDATE card_access_tokens
    SET 
        daily_sessions = 0,
        updated_at = NOW()
    WHERE last_session_date IS NOT NULL 
    AND last_session_date < CURRENT_DATE;
    
    GET DIAGNOSTICS v_reset_count = ROW_COUNT;
    RETURN v_reset_count;
END;
$$;

-- Reset monthly counters for tokens where month has changed
CREATE OR REPLACE FUNCTION reset_monthly_token_counters_server()
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_reset_count INTEGER;
    v_current_month_start DATE;
BEGIN
    v_current_month_start := date_trunc('month', CURRENT_DATE)::DATE;
    
    UPDATE card_access_tokens
    SET 
        monthly_sessions = 0,
        current_month = v_current_month_start,
        updated_at = NOW()
    WHERE current_month IS NOT NULL 
    AND current_month < v_current_month_start;
    
    GET DIAGNOSTICS v_reset_count = ROW_COUNT;
    RETURN v_reset_count;
END;
$$;

-- Get token daily limit (for Redis cache)
CREATE OR REPLACE FUNCTION get_token_daily_limit_server(p_token_id UUID)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_limit INTEGER;
BEGIN
    SELECT daily_session_limit INTO v_limit
    FROM card_access_tokens
    WHERE id = p_token_id;
    
    RETURN v_limit;
END;
$$;

-- Revoke public access (server-side only via service role)
REVOKE ALL ON FUNCTION get_card_by_access_token_server(TEXT, TEXT) FROM PUBLIC, authenticated, anon;
REVOKE ALL ON FUNCTION update_token_session_counters_server(UUID, INTEGER, INTEGER, INTEGER) FROM PUBLIC, authenticated, anon;
REVOKE ALL ON FUNCTION reset_daily_token_counters_server() FROM PUBLIC, authenticated, anon;
REVOKE ALL ON FUNCTION reset_monthly_token_counters_server() FROM PUBLIC, authenticated, anon;
REVOKE ALL ON FUNCTION get_token_daily_limit_server(UUID) FROM PUBLIC, authenticated, anon;



-- File: card_content.sql
-- -----------------------------------------------------------------
DROP FUNCTION IF EXISTS get_card_by_access_token_server CASCADE;
DROP FUNCTION IF EXISTS get_card_content_server CASCADE;
DROP FUNCTION IF EXISTS get_content_items_server CASCADE;

-- =================================================================
-- CARD CONTENT - SERVER-SIDE STORED PROCEDURES
-- =================================================================
-- All card and content item retrieval from Express backend.
-- Called by backend Express server with service_role permissions.
-- Used primarily for mobile client access and translation operations.
-- =================================================================

-- Get card by access token (for digital access)
-- Uses card_access_tokens table for multi-QR support
DROP FUNCTION IF EXISTS get_card_by_access_token_server CASCADE;
CREATE OR REPLACE FUNCTION get_card_by_access_token_server(
    p_access_token TEXT
)
RETURNS TABLE (
    -- Card info
    id UUID,
    user_id UUID,
    billing_type TEXT,
    -- Token-specific fields
    token_id UUID,
    token_name TEXT,
    token_is_enabled BOOLEAN,
    token_daily_session_limit INTEGER,
    token_daily_sessions INTEGER,
    token_monthly_sessions INTEGER,
    token_total_sessions INTEGER,
    -- Template check
    is_template BOOLEAN
) AS $$
DECLARE
    v_current_month_start DATE;
BEGIN
    v_current_month_start := date_trunc('month', CURRENT_DATE)::DATE;
    
    RETURN QUERY
    SELECT 
        c.id,
        c.user_id,
        c.billing_type::TEXT,
        -- Token fields
        t.id AS token_id,
        t.name AS token_name,
        t.is_enabled AS token_is_enabled,
        t.daily_session_limit AS token_daily_session_limit,
        -- Reset daily counter if date changed
        CASE 
            WHEN t.last_session_date = CURRENT_DATE THEN t.daily_sessions
            ELSE 0
        END AS token_daily_sessions,
        -- Reset monthly counter if month changed
        CASE 
            WHEN t.current_month = v_current_month_start THEN t.monthly_sessions
            ELSE 0
        END AS token_monthly_sessions,
        t.total_sessions AS token_total_sessions,
        -- Template check
        (ct.id IS NOT NULL) AS is_template
    FROM card_access_tokens t
    JOIN cards c ON c.id = t.card_id
    LEFT JOIN content_templates ct ON ct.card_id = c.id
    WHERE t.access_token = p_access_token;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get full card content
-- Returns subscription_tier for white-labeling (show branding for Free/Starter, hide for Premium)
-- Note: Session counters are now per-token in card_access_tokens table
DROP FUNCTION IF EXISTS get_card_content_server CASCADE;
CREATE OR REPLACE FUNCTION get_card_content_server(
    p_card_id UUID
)
RETURNS TABLE (
    name TEXT,
    description TEXT,
    image_url TEXT,
    crop_parameters JSONB,
    conversation_ai_enabled BOOLEAN,
    realtime_voice_enabled BOOLEAN,
    ai_instruction TEXT,
    ai_knowledge_base TEXT,
    ai_welcome_general TEXT,
    ai_welcome_item TEXT,
    original_language TEXT,
    translations JSONB,
    content_mode TEXT,
    is_grouped BOOLEAN,
    group_display TEXT,
    billing_type TEXT,
    metadata JSONB,
    subscription_tier TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.name,
        c.description,
        c.image_url,
        c.crop_parameters,
        c.conversation_ai_enabled,
        c.realtime_voice_enabled,
        c.ai_instruction,
        c.ai_knowledge_base,
        c.ai_welcome_general,
        c.ai_welcome_item,
        c.original_language::TEXT,  -- Cast to TEXT (column is varchar(10))
        c.translations,
        c.content_mode::TEXT,
        c.is_grouped,
        c.group_display::TEXT,
        c.billing_type::TEXT,
        c.metadata,
        COALESCE(s.tier::TEXT, 'free') as subscription_tier
    FROM cards c
    LEFT JOIN subscriptions s ON s.user_id = c.user_id
    WHERE c.id = p_card_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get content items for card
DROP FUNCTION IF EXISTS get_content_items_server CASCADE;
CREATE OR REPLACE FUNCTION get_content_items_server(
    p_card_id UUID
)
RETURNS TABLE (
    id UUID,
    parent_id UUID,
    name TEXT,
    content TEXT,
    image_url TEXT,
    ai_knowledge_base TEXT,
    sort_order INTEGER,
    crop_parameters JSONB,
    translations JSONB
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ci.id,
        ci.parent_id,
        ci.name,
        ci.content,
        ci.image_url,
        ci.ai_knowledge_base,
        ci.sort_order,
        ci.crop_parameters,
        ci.translations
    FROM content_items ci
    WHERE ci.card_id = p_card_id
    ORDER BY ci.sort_order ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =================================================================
-- GRANTS - Only service_role can execute these
-- =================================================================
REVOKE ALL ON FUNCTION get_card_by_access_token_server FROM PUBLIC, authenticated, anon;
GRANT EXECUTE ON FUNCTION get_card_by_access_token_server TO service_role;

REVOKE ALL ON FUNCTION get_card_content_server FROM PUBLIC, authenticated, anon;
GRANT EXECUTE ON FUNCTION get_card_content_server TO service_role;

REVOKE ALL ON FUNCTION get_content_items_server FROM PUBLIC, authenticated, anon;
GRANT EXECUTE ON FUNCTION get_content_items_server TO service_role;



-- File: card_session.sql
-- -----------------------------------------------------------------
DROP FUNCTION IF EXISTS get_card_billing_info_server CASCADE;
DROP FUNCTION IF EXISTS get_card_ai_status_server CASCADE;

-- =================================================================
-- CARD SESSION OPERATIONS - SERVER-SIDE STORED PROCEDURES
-- =================================================================
-- Lightweight card queries for session-based billing.
-- Called by backend Express server with service_role permissions.
-- 
-- NOTE: All pricing (session costs, budgets, limits) comes from environment variables.
-- Redis is the source of truth for budget tracking.
-- Daily session limits are per-QR-code (card_access_tokens table).
-- =================================================================

-- Get card AI-enabled status and billing info
DROP FUNCTION IF EXISTS get_card_billing_info_server CASCADE;
CREATE OR REPLACE FUNCTION get_card_billing_info_server(
    p_card_id UUID
)
RETURNS TABLE (
    card_id UUID,
    user_id UUID,
    ai_enabled BOOLEAN,
    billing_type TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.id AS card_id,
        c.user_id,
        COALESCE(c.conversation_ai_enabled, FALSE) AS ai_enabled,
        c.billing_type
    FROM cards c
    WHERE c.id = p_card_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get card AI-enabled status only (lightweight query)
-- Returns TRUE if conversation_ai_enabled is true
DROP FUNCTION IF EXISTS get_card_ai_status_server CASCADE;
CREATE OR REPLACE FUNCTION get_card_ai_status_server(
    p_card_id UUID
)
RETURNS BOOLEAN AS $$
DECLARE
    v_ai_enabled BOOLEAN;
BEGIN
    SELECT COALESCE(c.conversation_ai_enabled, FALSE)
    INTO v_ai_enabled
    FROM cards c
    WHERE c.id = p_card_id;
    
    RETURN COALESCE(v_ai_enabled, FALSE);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- NOTE: Daily session limits are now per-QR-code in card_access_tokens table
-- Use get_card_by_access_token_server to get token-specific daily limits
-- The old get_card_daily_limit_server function has been removed

-- =================================================================
-- GRANTS - Only service_role can execute these
-- =================================================================
REVOKE ALL ON FUNCTION get_card_billing_info_server FROM PUBLIC, authenticated, anon;
GRANT EXECUTE ON FUNCTION get_card_billing_info_server TO service_role;

REVOKE ALL ON FUNCTION get_card_ai_status_server FROM PUBLIC, authenticated, anon;
GRANT EXECUTE ON FUNCTION get_card_ai_status_server TO service_role;


-- File: credit_operations.sql
-- -----------------------------------------------------------------
DROP FUNCTION IF EXISTS get_user_credit_balance_server CASCADE;
DROP FUNCTION IF EXISTS deduct_overage_credits_server CASCADE;
DROP FUNCTION IF EXISTS get_credit_purchase_by_intent_server CASCADE;

-- =================================================================
-- CREDIT OPERATIONS - SERVER-SIDE STORED PROCEDURES
-- =================================================================
-- All credit-related database operations from Express backend.
-- Called by backend Express server with service_role permissions.
-- These are atomic operations for credit balance management.
--
-- NOTE: Session budget tracking is handled in Redis.
-- When credits are deducted for overage, the backend adds 
-- the amount to the Redis budget counter.
-- =================================================================

-- Get user credit balance
DROP FUNCTION IF EXISTS get_user_credit_balance_server CASCADE;
CREATE OR REPLACE FUNCTION get_user_credit_balance_server(
    p_user_id UUID
)
RETURNS DECIMAL AS $$
DECLARE
    v_balance DECIMAL;
BEGIN
    SELECT balance INTO v_balance
    FROM user_credits
    WHERE user_id = p_user_id;
    
    RETURN COALESCE(v_balance, 0);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Deduct credits for session budget top-up (atomic operation)
-- After this succeeds, the backend adds the amount to Redis budget
DROP FUNCTION IF EXISTS deduct_overage_credits_server CASCADE;
CREATE OR REPLACE FUNCTION deduct_overage_credits_server(
    p_user_id UUID,
    p_card_id UUID, -- Can be NULL for budget-based overage
    p_credits_amount DECIMAL,
    p_access_granted INTEGER DEFAULT 0 -- Legacy parameter, kept for backward compatibility
)
RETURNS JSONB AS $$
DECLARE
    v_current_balance DECIMAL;
    v_new_balance DECIMAL;
BEGIN
    -- Get current credit balance with lock
    SELECT balance INTO v_current_balance
    FROM user_credits
    WHERE user_id = p_user_id
    FOR UPDATE;
    
    IF v_current_balance IS NULL THEN
        v_current_balance := 0;
    END IF;
    
    -- Check if sufficient balance
    IF v_current_balance < p_credits_amount THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'error', 'Insufficient credits',
            'current_balance', v_current_balance,
            'required', p_credits_amount
        );
    END IF;
    
    -- Calculate new balance
    v_new_balance := v_current_balance - p_credits_amount;
    
    -- Update credit balance
    UPDATE user_credits
    SET balance = v_new_balance, updated_at = NOW()
    WHERE user_id = p_user_id;
    
    -- Record consumption (simple record, no complex session tracking)
    INSERT INTO credit_consumptions (
        user_id, card_id, quantity, credits_per_unit, total_credits,
        consumption_type, description
    ) VALUES (
        p_user_id, p_card_id, 1, 
        p_credits_amount, p_credits_amount,
        'session_budget_topup',
        format('Session budget top-up: $%s (added to Redis budget)', p_credits_amount)
    );
    
    -- Record transaction
    INSERT INTO credit_transactions (
        user_id, amount, balance_before, balance_after, type,
        reference_type, description
    ) VALUES (
        p_user_id, -p_credits_amount, v_current_balance, v_new_balance,
        'consumption', 'session_budget_topup',
        format('Session budget top-up: $%s (credit balance: $%s -> $%s)', p_credits_amount, v_current_balance, v_new_balance)
    );
    
    -- Return success - backend will add to Redis budget
    RETURN jsonb_build_object(
        'success', TRUE,
        'balance_before', v_current_balance,
        'balance_after', v_new_balance,
        'credits_deducted', p_credits_amount
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get credit purchase by payment intent
DROP FUNCTION IF EXISTS get_credit_purchase_by_intent_server CASCADE;
CREATE OR REPLACE FUNCTION get_credit_purchase_by_intent_server(
    p_payment_intent_id TEXT
)
RETURNS TABLE (
    id UUID,
    user_id UUID,
    credits_amount DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT cp.id, cp.user_id, cp.credits_amount
    FROM credit_purchases cp
    WHERE cp.stripe_payment_intent_id = p_payment_intent_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =================================================================
-- GRANTS - Only service_role can execute these
-- =================================================================
REVOKE ALL ON FUNCTION get_user_credit_balance_server FROM PUBLIC, authenticated, anon;
GRANT EXECUTE ON FUNCTION get_user_credit_balance_server TO service_role;

REVOKE ALL ON FUNCTION deduct_overage_credits_server FROM PUBLIC, authenticated, anon;
GRANT EXECUTE ON FUNCTION deduct_overage_credits_server TO service_role;

REVOKE ALL ON FUNCTION get_credit_purchase_by_intent_server FROM PUBLIC, authenticated, anon;
GRANT EXECUTE ON FUNCTION get_credit_purchase_by_intent_server TO service_role;


-- File: credit_purchase_completion.sql
-- -----------------------------------------------------------------
DROP FUNCTION IF EXISTS complete_credit_purchase CASCADE;
DROP FUNCTION IF EXISTS refund_credit_purchase CASCADE;
DROP FUNCTION IF EXISTS create_credit_purchase_record CASCADE;

-- Server-side Credit Purchase Completion
-- Called by Edge Function after successful Stripe payment

-- Complete credit purchase after Stripe payment
-- SECURITY: Validates user ID and payment amount to prevent fraud
CREATE OR REPLACE FUNCTION complete_credit_purchase(
    p_user_id UUID,  -- User ID from webhook metadata for validation
    p_stripe_session_id VARCHAR,
    p_stripe_payment_intent_id VARCHAR DEFAULT NULL,
    p_amount_paid_cents INTEGER DEFAULT NULL,  -- Actual amount paid from Stripe
    p_receipt_url TEXT DEFAULT NULL,
    p_payment_method JSONB DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
    v_purchase_id UUID;
    v_user_id_from_db UUID;
    v_credits_amount DECIMAL;
    v_expected_amount_cents INTEGER;
    v_purchase_status VARCHAR;
    v_current_balance DECIMAL;
    v_new_balance DECIMAL;
    v_transaction_id UUID;
BEGIN
    -- Lock and get the pending purchase record (prevents race conditions)
    SELECT id, user_id, credits_amount, status
    INTO v_purchase_id, v_user_id_from_db, v_credits_amount, v_purchase_status
    FROM credit_purchases
    WHERE stripe_session_id = p_stripe_session_id
    FOR UPDATE;  -- Lock to prevent concurrent processing

    IF v_purchase_id IS NULL THEN
        RAISE EXCEPTION 'Credit purchase not found: %', p_stripe_session_id;
    END IF;

    -- SECURITY: Verify user ID matches (prevent user A completing user B's purchase)
    IF v_user_id_from_db != p_user_id THEN
        RAISE EXCEPTION 'User ID mismatch. Expected: %, Provided: %', v_user_id_from_db, p_user_id;
    END IF;

    -- SECURITY: Check if already processed (prevent duplicate processing)
    IF v_purchase_status != 'pending' THEN
        RAISE EXCEPTION 'Purchase already processed with status: %', v_purchase_status;
    END IF;

    -- SECURITY: Verify payment amount (1 credit = $1 = 100 cents)
    IF p_amount_paid_cents IS NOT NULL THEN
        v_expected_amount_cents := (v_credits_amount * 100)::INTEGER;
        IF p_amount_paid_cents != v_expected_amount_cents THEN
            RAISE EXCEPTION 'Amount mismatch. Expected: % cents (% credits), Paid: % cents', 
                v_expected_amount_cents, v_credits_amount, p_amount_paid_cents;
        END IF;
    END IF;

    -- Initialize credits if not exists
    INSERT INTO user_credits (user_id, balance, total_purchased, total_consumed)
    VALUES (p_user_id, 0, 0, 0)
    ON CONFLICT (user_id) DO NOTHING;

    -- Lock the user credits row for update
    SELECT balance INTO v_current_balance
    FROM user_credits
    WHERE user_id = p_user_id
    FOR UPDATE;

    v_new_balance := v_current_balance + v_credits_amount;

    -- Update user credits
    UPDATE user_credits
    SET 
        balance = v_new_balance,
        total_purchased = total_purchased + v_credits_amount,
        updated_at = CURRENT_TIMESTAMP
    WHERE user_id = p_user_id;

    -- Update purchase record
    UPDATE credit_purchases
    SET 
        status = 'completed',
        stripe_payment_intent_id = p_stripe_payment_intent_id,
        receipt_url = p_receipt_url,
        payment_method = p_payment_method,
        completed_at = CURRENT_TIMESTAMP
    WHERE id = v_purchase_id;

    -- Record transaction
    INSERT INTO credit_transactions (
        user_id, type, amount, balance_before, balance_after,
        reference_type, reference_id, description, metadata
    ) VALUES (
        p_user_id, 'purchase', v_credits_amount, v_current_balance, v_new_balance,
        'stripe_purchase', v_purchase_id,
        format('Credit purchase: %s credits', v_credits_amount),
        jsonb_build_object(
            'stripe_session_id', p_stripe_session_id,
            'stripe_payment_intent_id', p_stripe_payment_intent_id
        )
    ) RETURNING id INTO v_transaction_id;

    -- Note: This is called by webhooks without auth context, so we don't log to operations_log
    -- The credit_transactions table serves as the complete audit log for these operations

    RETURN jsonb_build_object(
        'success', true,
        'purchase_id', v_purchase_id,
        'transaction_id', v_transaction_id,
        'credits_added', v_credits_amount,
        'new_balance', v_new_balance,
        'user_id', p_user_id
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Refund credit purchase
-- SECURITY: Validates user ID to prevent unauthorized refunds
CREATE OR REPLACE FUNCTION refund_credit_purchase(
    p_user_id UUID,  -- User ID for authorization validation
    p_purchase_id UUID,
    p_refund_amount DECIMAL,
    p_reason TEXT DEFAULT 'Customer requested refund'
)
RETURNS JSONB AS $$
DECLARE
    v_user_id_from_db UUID;
    v_credits_amount DECIMAL;
    v_current_balance DECIMAL;
    v_new_balance DECIMAL;
    v_transaction_id UUID;
    v_purchase_status VARCHAR;
BEGIN
    -- Lock and get the purchase record (prevents race conditions)
    SELECT user_id, credits_amount, status
    INTO v_user_id_from_db, v_credits_amount, v_purchase_status
    FROM credit_purchases
    WHERE id = p_purchase_id
    FOR UPDATE;  -- Lock to prevent concurrent refunds

    IF v_user_id_from_db IS NULL THEN
        RAISE EXCEPTION 'Credit purchase not found: %', p_purchase_id;
    END IF;

    -- SECURITY: Verify user ID matches (prevent refunding other users' purchases)
    IF v_user_id_from_db != p_user_id THEN
        RAISE EXCEPTION 'User ID mismatch. Expected: %, Provided: %', v_user_id_from_db, p_user_id;
    END IF;

    IF v_purchase_status != 'completed' THEN
        RAISE EXCEPTION 'Cannot refund purchase with status: %', v_purchase_status;
    END IF;

    IF p_refund_amount > v_credits_amount THEN
        RAISE EXCEPTION 'Refund amount exceeds original purchase amount';
    END IF;

    -- Lock the user credits row for update
    SELECT balance INTO v_current_balance
    FROM user_credits
    WHERE user_id = p_user_id
    FOR UPDATE;

    IF v_current_balance < p_refund_amount THEN
        RAISE EXCEPTION 'Insufficient credits for refund. Current balance: %, Refund amount: %', 
            v_current_balance, p_refund_amount;
    END IF;

    v_new_balance := v_current_balance - p_refund_amount;

    -- Update user credits
    UPDATE user_credits
    SET 
        balance = v_new_balance,
        total_purchased = total_purchased - p_refund_amount,
        updated_at = CURRENT_TIMESTAMP
    WHERE user_id = p_user_id;

    -- Update purchase record
    UPDATE credit_purchases
    SET 
        status = CASE 
            WHEN p_refund_amount = credits_amount THEN 'refunded'
            ELSE 'completed' -- Partial refund
        END,
        metadata = COALESCE(metadata, '{}'::jsonb) || jsonb_build_object(
            'refund_amount', p_refund_amount,
            'refund_reason', p_reason,
            'refund_at', CURRENT_TIMESTAMP
        )
    WHERE id = p_purchase_id;

    -- Record transaction
    INSERT INTO credit_transactions (
        user_id, type, amount, balance_before, balance_after,
        reference_type, reference_id, description, metadata
    ) VALUES (
        p_user_id, 'refund', p_refund_amount, v_current_balance, v_new_balance,
        'stripe_refund', p_purchase_id,
        format('Credit refund: %s credits - %s', p_refund_amount, p_reason),
        jsonb_build_object(
            'original_purchase_id', p_purchase_id,
            'refund_reason', p_reason
        )
    ) RETURNING id INTO v_transaction_id;

    -- Note: This is called by webhooks without auth context, so we don't log to operations_log  
    -- The credit_transactions table serves as the complete audit log for these operations

    RETURN jsonb_build_object(
        'success', true,
        'purchase_id', p_purchase_id,
        'transaction_id', v_transaction_id,
        'credits_refunded', p_refund_amount,
        'new_balance', v_new_balance
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create credit purchase record (server-side version with explicit user_id)
-- Called by backend Express server when creating Stripe checkout session
CREATE OR REPLACE FUNCTION create_credit_purchase_record(
    p_stripe_session_id VARCHAR,
    p_amount_usd DECIMAL,
    p_credits_amount DECIMAL,
    p_metadata JSONB DEFAULT NULL,
    p_user_id UUID DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_purchase_id UUID;
BEGIN
    -- Validate user_id is provided (required for server-side calls)
    IF p_user_id IS NULL THEN
        RAISE EXCEPTION 'User ID is required for server-side credit purchase creation';
    END IF;

    INSERT INTO credit_purchases (
        user_id, stripe_session_id, amount_usd, credits_amount, 
        status, metadata
    ) VALUES (
        p_user_id, p_stripe_session_id, p_amount_usd, p_credits_amount,
        'pending', p_metadata
    ) RETURNING id INTO v_purchase_id;

    RETURN v_purchase_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =================================================================
-- GRANTS - Only service_role can execute these
-- =================================================================
REVOKE ALL ON FUNCTION complete_credit_purchase(UUID, VARCHAR, VARCHAR, INTEGER, TEXT, JSONB) FROM PUBLIC, authenticated, anon;
GRANT EXECUTE ON FUNCTION complete_credit_purchase(UUID, VARCHAR, VARCHAR, INTEGER, TEXT, JSONB) TO service_role;

REVOKE ALL ON FUNCTION refund_credit_purchase(UUID, UUID, DECIMAL, TEXT) FROM PUBLIC, authenticated, anon;
GRANT EXECUTE ON FUNCTION refund_credit_purchase(UUID, UUID, DECIMAL, TEXT) TO service_role;

REVOKE ALL ON FUNCTION create_credit_purchase_record(VARCHAR, DECIMAL, DECIMAL, JSONB, UUID) FROM PUBLIC, authenticated, anon;
GRANT EXECUTE ON FUNCTION create_credit_purchase_record(VARCHAR, DECIMAL, DECIMAL, JSONB, UUID) TO service_role;


-- File: mobile_access.sql
-- -----------------------------------------------------------------
DROP FUNCTION IF EXISTS update_card_scan_counters_server CASCADE;
DROP FUNCTION IF EXISTS reset_subscription_usage_server CASCADE;
DROP FUNCTION IF EXISTS activate_premium_subscription_server CASCADE;
DROP FUNCTION IF EXISTS cancel_subscription_server CASCADE;
DROP FUNCTION IF EXISTS apply_scheduled_tier_change_server CASCADE;

-- =================================================================
-- SERVER-SIDE MOBILE ACCESS FUNCTIONS
-- Called by Express backend with service role (not client-callable)
-- =================================================================
-- NOTE: Usage tracking is handled by Redis-first approach in usage-tracker.ts
-- These functions handle card info retrieval and subscription management
-- =================================================================
-- NOTE: get_card_by_access_token_server is defined in card_content.sql
-- to avoid duplication
-- =================================================================


-- =================================================================
-- Update card scan counters (server-side)
-- Still used for total scan tracking
-- =================================================================
CREATE OR REPLACE FUNCTION update_card_scan_counters_server(
    p_card_id UUID,
    p_increment_total BOOLEAN DEFAULT TRUE
)
RETURNS VOID AS $$
BEGIN
    IF p_increment_total THEN
        UPDATE cards
        SET total_sessions = total_sessions + 1
        WHERE id = p_card_id;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

REVOKE ALL ON FUNCTION update_card_scan_counters_server(UUID, BOOLEAN) FROM PUBLIC;
REVOKE ALL ON FUNCTION update_card_scan_counters_server(UUID, BOOLEAN) FROM authenticated;
REVOKE ALL ON FUNCTION update_card_scan_counters_server(UUID, BOOLEAN) FROM anon;
GRANT EXECUTE ON FUNCTION update_card_scan_counters_server(UUID, BOOLEAN) TO service_role;


-- =================================================================
-- SUBSCRIPTION MANAGEMENT FUNCTIONS (Server-side)
-- Usage is tracked in Redis - these just manage subscription metadata
-- =================================================================

-- Reset subscription period (called by Stripe webhook)
-- Redis usage is reset separately by usage-tracker.ts
CREATE OR REPLACE FUNCTION reset_subscription_usage_server(
    p_stripe_subscription_id TEXT,
    p_new_period_start TIMESTAMPTZ,
    p_new_period_end TIMESTAMPTZ
)
RETURNS JSONB AS $$
DECLARE
    v_subscription subscriptions%ROWTYPE;
BEGIN
    -- Get subscription
    SELECT * INTO v_subscription 
    FROM subscriptions 
    WHERE stripe_subscription_id = p_stripe_subscription_id;
    
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', FALSE, 'reason', 'Subscription not found');
    END IF;
    
    -- Update period dates only (usage is tracked in Redis)
    UPDATE subscriptions
    SET current_period_start = p_new_period_start,
        current_period_end = p_new_period_end,
        updated_at = NOW()
    WHERE id = v_subscription.id;
    
    RETURN jsonb_build_object(
        'success', TRUE,
        'user_id', v_subscription.user_id,
        'new_period_start', p_new_period_start,
        'new_period_end', p_new_period_end
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

REVOKE ALL ON FUNCTION reset_subscription_usage_server(TEXT, TIMESTAMPTZ, TIMESTAMPTZ) FROM PUBLIC;
REVOKE ALL ON FUNCTION reset_subscription_usage_server(TEXT, TIMESTAMPTZ, TIMESTAMPTZ) FROM authenticated;
REVOKE ALL ON FUNCTION reset_subscription_usage_server(TEXT, TIMESTAMPTZ, TIMESTAMPTZ) FROM anon;
GRANT EXECUTE ON FUNCTION reset_subscription_usage_server(TEXT, TIMESTAMPTZ, TIMESTAMPTZ) TO service_role;


-- Activate premium subscription (called by Stripe webhook)
-- Modified to support cancel_at_period_end and tier parameter
-- Supports both Starter and Premium subscription activation
DROP FUNCTION IF EXISTS activate_premium_subscription_server(UUID, TEXT, TEXT, TEXT, TIMESTAMPTZ, TIMESTAMPTZ) CASCADE;
DROP FUNCTION IF EXISTS activate_premium_subscription_server(UUID, TEXT, TEXT, TEXT, TIMESTAMPTZ, TIMESTAMPTZ, BOOLEAN) CASCADE;
DROP FUNCTION IF EXISTS activate_premium_subscription_server(UUID, TEXT, TEXT, TEXT, TIMESTAMPTZ, TIMESTAMPTZ, BOOLEAN, TEXT) CASCADE;

CREATE OR REPLACE FUNCTION activate_premium_subscription_server(
    p_user_id UUID,
    p_stripe_customer_id TEXT,
    p_stripe_subscription_id TEXT,
    p_stripe_price_id TEXT,
    p_period_start TIMESTAMPTZ,
    p_period_end TIMESTAMPTZ,
    p_cancel_at_period_end BOOLEAN DEFAULT FALSE,
    p_tier TEXT DEFAULT 'premium'  -- 'starter' or 'premium'
)
RETURNS JSONB AS $$
DECLARE
    v_subscription_id UUID;
    v_tier "SubscriptionTier";
BEGIN
    -- Validate and cast tier
    IF p_tier NOT IN ('starter', 'premium') THEN
        RAISE EXCEPTION 'Invalid tier. Must be: starter or premium.';
    END IF;
    v_tier := p_tier::"SubscriptionTier";
    
    -- Upsert subscription
    INSERT INTO subscriptions (
        user_id, tier, status, stripe_customer_id, 
        stripe_subscription_id, stripe_price_id,
        current_period_start, current_period_end,
        cancel_at_period_end, scheduled_tier
    ) VALUES (
        p_user_id, v_tier, 'active', p_stripe_customer_id,
        p_stripe_subscription_id, p_stripe_price_id,
        p_period_start, p_period_end,
        p_cancel_at_period_end, NULL  -- Clear any scheduled tier
    )
    ON CONFLICT (user_id) DO UPDATE SET
        tier = v_tier,
        status = 'active',
        stripe_customer_id = p_stripe_customer_id,
        stripe_subscription_id = p_stripe_subscription_id,
        stripe_price_id = p_stripe_price_id,
        current_period_start = p_period_start,
        current_period_end = p_period_end,
        cancel_at_period_end = p_cancel_at_period_end,
        scheduled_tier = NULL,  -- Clear any scheduled tier when activating new subscription
        -- Don't clear canceled_at if we're cancelling
        canceled_at = CASE WHEN p_cancel_at_period_end THEN COALESCE(subscriptions.canceled_at, NOW()) ELSE NULL END,
        updated_at = NOW()
    RETURNING id INTO v_subscription_id;
    
    RETURN jsonb_build_object(
        'success', TRUE,
        'subscription_id', v_subscription_id,
        'tier', p_tier,
        'cancel_at_period_end', p_cancel_at_period_end
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

REVOKE ALL ON FUNCTION activate_premium_subscription_server(UUID, TEXT, TEXT, TEXT, TIMESTAMPTZ, TIMESTAMPTZ, BOOLEAN, TEXT) FROM PUBLIC, authenticated, anon;
GRANT EXECUTE ON FUNCTION activate_premium_subscription_server(UUID, TEXT, TEXT, TEXT, TIMESTAMPTZ, TIMESTAMPTZ, BOOLEAN, TEXT) TO service_role;


-- Cancel/downgrade subscription (called by Stripe webhook or cancel endpoint)
-- Supports lookup by stripe_subscription_id or user_id
-- p_scheduled_tier: for downgrades, the tier to switch to after period ends
DROP FUNCTION IF EXISTS cancel_subscription_server(TEXT, BOOLEAN, BOOLEAN) CASCADE;
DROP FUNCTION IF EXISTS cancel_subscription_server(TEXT, BOOLEAN, BOOLEAN, UUID) CASCADE;
DROP FUNCTION IF EXISTS cancel_subscription_server(TEXT, BOOLEAN, BOOLEAN, UUID, TEXT) CASCADE;
CREATE OR REPLACE FUNCTION cancel_subscription_server(
    p_stripe_subscription_id TEXT DEFAULT NULL,
    p_cancel_at_period_end BOOLEAN DEFAULT TRUE,
    p_immediate BOOLEAN DEFAULT FALSE,
    p_user_id UUID DEFAULT NULL,
    p_scheduled_tier TEXT DEFAULT NULL  -- 'free', 'starter', or NULL (defaults to 'free')
)
RETURNS JSONB AS $$
DECLARE
    v_subscription subscriptions%ROWTYPE;
    v_scheduled "SubscriptionTier";
BEGIN
    -- Try to find by stripe_subscription_id first, then by user_id
    IF p_stripe_subscription_id IS NOT NULL THEN
        SELECT * INTO v_subscription 
        FROM subscriptions 
        WHERE stripe_subscription_id = p_stripe_subscription_id;
    END IF;
    
    -- Fallback to user_id if not found by stripe_subscription_id
    IF NOT FOUND AND p_user_id IS NOT NULL THEN
        SELECT * INTO v_subscription 
        FROM subscriptions 
        WHERE user_id = p_user_id;
    END IF;
    
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', FALSE, 'reason', 'Subscription not found');
    END IF;
    
    -- Parse scheduled tier (default to 'free' if not specified)
    IF p_scheduled_tier IS NOT NULL AND p_scheduled_tier IN ('free', 'starter', 'premium') THEN
        v_scheduled := p_scheduled_tier::"SubscriptionTier";
    ELSE
        v_scheduled := 'free'::"SubscriptionTier";
    END IF;
    
    IF p_immediate THEN
        -- Immediate cancellation - switch to scheduled tier now
        UPDATE subscriptions
        SET tier = COALESCE(v_scheduled, 'free'::"SubscriptionTier"),
            status = CASE WHEN v_scheduled = 'free' THEN 'canceled' ELSE 'active' END,
            cancel_at_period_end = FALSE,
            canceled_at = NOW(),
            scheduled_tier = NULL,  -- Clear scheduled tier since we're applying immediately
            stripe_subscription_id = CASE WHEN v_scheduled = 'free' THEN NULL ELSE stripe_subscription_id END,
            updated_at = NOW()
        WHERE id = v_subscription.id;
    ELSE
        -- Cancel at period end - keep current tier privileges until then
        UPDATE subscriptions
        SET cancel_at_period_end = TRUE,
            canceled_at = NOW(),
            scheduled_tier = v_scheduled,  -- Set the tier to switch to at period end
            updated_at = NOW()
        WHERE id = v_subscription.id;
    END IF;
    
    RETURN jsonb_build_object(
        'success', TRUE,
        'user_id', v_subscription.user_id,
        'current_tier', v_subscription.tier,
        'scheduled_tier', v_scheduled,
        'cancel_at_period_end', p_cancel_at_period_end,
        'immediate', p_immediate
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

REVOKE ALL ON FUNCTION cancel_subscription_server(TEXT, BOOLEAN, BOOLEAN, UUID, TEXT) FROM PUBLIC;
REVOKE ALL ON FUNCTION cancel_subscription_server(TEXT, BOOLEAN, BOOLEAN, UUID, TEXT) FROM authenticated;
REVOKE ALL ON FUNCTION cancel_subscription_server(TEXT, BOOLEAN, BOOLEAN, UUID, TEXT) FROM anon;
GRANT EXECUTE ON FUNCTION cancel_subscription_server(TEXT, BOOLEAN, BOOLEAN, UUID, TEXT) TO service_role;


-- Apply scheduled tier change (called by Stripe webhook when subscription ends)
-- This is called when a subscription period ends and there's a scheduled_tier set
DROP FUNCTION IF EXISTS apply_scheduled_tier_change_server(TEXT, UUID) CASCADE;
CREATE OR REPLACE FUNCTION apply_scheduled_tier_change_server(
    p_stripe_subscription_id TEXT DEFAULT NULL,
    p_user_id UUID DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
    v_subscription subscriptions%ROWTYPE;
    v_new_tier "SubscriptionTier";
BEGIN
    -- Try to find by stripe_subscription_id first, then by user_id
    IF p_stripe_subscription_id IS NOT NULL THEN
        SELECT * INTO v_subscription 
        FROM subscriptions 
        WHERE stripe_subscription_id = p_stripe_subscription_id;
    END IF;
    
    -- Fallback to user_id if not found by stripe_subscription_id
    IF NOT FOUND AND p_user_id IS NOT NULL THEN
        SELECT * INTO v_subscription 
        FROM subscriptions 
        WHERE user_id = p_user_id;
    END IF;
    
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', FALSE, 'reason', 'Subscription not found');
    END IF;
    
    -- Check if there's a scheduled tier change
    IF v_subscription.scheduled_tier IS NULL THEN
        RETURN jsonb_build_object(
            'success', FALSE, 
            'reason', 'No scheduled tier change',
            'current_tier', v_subscription.tier
        );
    END IF;
    
    v_new_tier := v_subscription.scheduled_tier;
    
    -- Apply the scheduled tier change
    UPDATE subscriptions
    SET tier = v_new_tier,
        status = CASE WHEN v_new_tier = 'free' THEN 'canceled' ELSE 'active' END,
        cancel_at_period_end = FALSE,
        scheduled_tier = NULL,  -- Clear the scheduled tier
        stripe_subscription_id = CASE WHEN v_new_tier = 'free' THEN NULL ELSE stripe_subscription_id END,
        updated_at = NOW()
    WHERE id = v_subscription.id;
    
    RETURN jsonb_build_object(
        'success', TRUE,
        'user_id', v_subscription.user_id,
        'previous_tier', v_subscription.tier,
        'new_tier', v_new_tier
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

REVOKE ALL ON FUNCTION apply_scheduled_tier_change_server(TEXT, UUID) FROM PUBLIC;
REVOKE ALL ON FUNCTION apply_scheduled_tier_change_server(TEXT, UUID) FROM authenticated;
REVOKE ALL ON FUNCTION apply_scheduled_tier_change_server(TEXT, UUID) FROM anon;
GRANT EXECUTE ON FUNCTION apply_scheduled_tier_change_server(TEXT, UUID) TO service_role;


-- File: subscription_management.sql
-- -----------------------------------------------------------------
DROP FUNCTION IF EXISTS get_subscription_by_user_server CASCADE;
DROP FUNCTION IF EXISTS get_subscription_stripe_customer_server CASCADE;
DROP FUNCTION IF EXISTS update_subscription_cancel_status_server CASCADE;
DROP FUNCTION IF EXISTS update_subscription_status_server CASCADE;
DROP FUNCTION IF EXISTS update_subscription_period_server CASCADE;
DROP FUNCTION IF EXISTS count_user_experiences_server CASCADE;
DROP FUNCTION IF EXISTS check_premium_subscription_server CASCADE;

-- =================================================================
-- SUBSCRIPTION MANAGEMENT - SERVER-SIDE STORED PROCEDURES
-- =================================================================
-- All subscription-related database operations from Express backend.
-- Called by backend Express server with service_role permissions.
--
-- NOTE: Session-based billing (budget tracking, session costs) is handled
-- entirely in Redis. These stored procedures only manage subscription metadata.
-- All pricing values come from environment variables.
-- =================================================================

-- Get subscription by user ID (basic info only)
DROP FUNCTION IF EXISTS get_subscription_by_user_server CASCADE;
CREATE OR REPLACE FUNCTION get_subscription_by_user_server(
    p_user_id UUID
)
RETURNS TABLE (
    id UUID,
    user_id UUID,
    tier TEXT,
    status TEXT,
    stripe_customer_id TEXT,
    stripe_subscription_id TEXT,
    current_period_start TIMESTAMPTZ,
    current_period_end TIMESTAMPTZ,
    cancel_at_period_end BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        s.id,
        s.user_id,
        s.tier::TEXT,
        s.status::TEXT,
        s.stripe_customer_id,
        s.stripe_subscription_id,
        s.current_period_start,
        s.current_period_end,
        s.cancel_at_period_end
    FROM subscriptions s
    WHERE s.user_id = p_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get subscription Stripe customer ID
DROP FUNCTION IF EXISTS get_subscription_stripe_customer_server CASCADE;
CREATE OR REPLACE FUNCTION get_subscription_stripe_customer_server(
    p_user_id UUID
)
RETURNS TEXT AS $$
DECLARE
    v_customer_id TEXT;
BEGIN
    SELECT stripe_customer_id INTO v_customer_id
    FROM subscriptions
    WHERE user_id = p_user_id;
    
    RETURN v_customer_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update subscription cancel_at_period_end
DROP FUNCTION IF EXISTS update_subscription_cancel_status_server CASCADE;
CREATE OR REPLACE FUNCTION update_subscription_cancel_status_server(
    p_user_id UUID,
    p_cancel_at_period_end BOOLEAN,
    p_canceled_at TIMESTAMPTZ DEFAULT NULL
)
RETURNS VOID AS $$
BEGIN
    UPDATE subscriptions
    SET 
        cancel_at_period_end = p_cancel_at_period_end,
        canceled_at = p_canceled_at,
        updated_at = NOW()
    WHERE user_id = p_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update subscription status (for payment failures)
DROP FUNCTION IF EXISTS update_subscription_status_server CASCADE;
CREATE OR REPLACE FUNCTION update_subscription_status_server(
    p_stripe_subscription_id TEXT,
    p_status TEXT
)
RETURNS VOID AS $$
BEGIN
    UPDATE subscriptions
    SET 
        status = p_status::subscription_status,
        updated_at = NOW()
    WHERE stripe_subscription_id = p_stripe_subscription_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update subscription period dates (called on period renewal)
DROP FUNCTION IF EXISTS update_subscription_period_server CASCADE;
CREATE OR REPLACE FUNCTION update_subscription_period_server(
    p_user_id UUID,
    p_period_start TIMESTAMPTZ,
    p_period_end TIMESTAMPTZ
)
RETURNS VOID AS $$
BEGIN
    UPDATE subscriptions
    SET 
        current_period_start = p_period_start,
        current_period_end = p_period_end,
        updated_at = NOW()
    WHERE user_id = p_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Count user experiences
DROP FUNCTION IF EXISTS count_user_experiences_server CASCADE;
CREATE OR REPLACE FUNCTION count_user_experiences_server(
    p_user_id UUID
)
RETURNS INTEGER AS $$
DECLARE
    v_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_count
    FROM cards
    WHERE user_id = p_user_id;
    
    RETURN v_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Check if user has paid subscription (Starter or Premium) OR is admin
-- Admins have full translation access without subscription
-- Starter tier: limited to max 2 languages
-- Premium tier: unlimited languages
DROP FUNCTION IF EXISTS check_premium_subscription_server CASCADE;
CREATE OR REPLACE FUNCTION check_premium_subscription_server(
    p_user_id UUID
)
RETURNS BOOLEAN AS $$
DECLARE
    v_tier TEXT;
    v_role TEXT;
BEGIN
    -- First check if user is admin (admins always have translation access)
    SELECT raw_user_meta_data->>'role' INTO v_role
    FROM auth.users
    WHERE id = p_user_id;
    
    IF v_role = 'admin' THEN
        RETURN TRUE;
    END IF;
    
    -- Check if user has paid subscription (Starter or Premium)
    SELECT tier::TEXT INTO v_tier
    FROM subscriptions
    WHERE user_id = p_user_id;
    
    -- Both Starter and Premium can access translations
    RETURN v_tier IN ('starter', 'premium');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =================================================================
-- GRANTS - Only service_role can execute these
-- =================================================================
REVOKE ALL ON FUNCTION get_subscription_by_user_server FROM PUBLIC, authenticated, anon;
GRANT EXECUTE ON FUNCTION get_subscription_by_user_server TO service_role;

REVOKE ALL ON FUNCTION get_subscription_stripe_customer_server FROM PUBLIC, authenticated, anon;
GRANT EXECUTE ON FUNCTION get_subscription_stripe_customer_server TO service_role;

REVOKE ALL ON FUNCTION update_subscription_cancel_status_server FROM PUBLIC, authenticated, anon;
GRANT EXECUTE ON FUNCTION update_subscription_cancel_status_server TO service_role;

REVOKE ALL ON FUNCTION update_subscription_status_server FROM PUBLIC, authenticated, anon;
GRANT EXECUTE ON FUNCTION update_subscription_status_server TO service_role;

REVOKE ALL ON FUNCTION update_subscription_period_server FROM PUBLIC, authenticated, anon;
GRANT EXECUTE ON FUNCTION update_subscription_period_server TO service_role;

REVOKE ALL ON FUNCTION count_user_experiences_server FROM PUBLIC, authenticated, anon;
GRANT EXECUTE ON FUNCTION count_user_experiences_server TO service_role;

REVOKE ALL ON FUNCTION check_premium_subscription_server FROM PUBLIC, authenticated, anon;
GRANT EXECUTE ON FUNCTION check_premium_subscription_server TO service_role;


-- File: translation_credit_consumption.sql
-- -----------------------------------------------------------------
DROP FUNCTION IF EXISTS consume_translation_credits CASCADE;
DROP FUNCTION IF EXISTS record_translation_completion CASCADE;

-- =====================================================================
-- TRANSLATION CREDIT CONSUMPTION (SERVER-SIDE)
-- =====================================================================
-- Server-side procedures for consuming credits during direct translations
-- Called by backend Express server with service_role permissions
-- =====================================================================

-- =====================================================================
-- 1. Consume Translation Credits
-- =====================================================================
-- Consumes credits for successful translations
-- Called after each language is successfully translated
-- =====================================================================

CREATE OR REPLACE FUNCTION consume_translation_credits(
  p_user_id UUID,
  p_card_id UUID,
  p_language VARCHAR(10),
  p_credit_cost DECIMAL DEFAULT 1.0
)
RETURNS JSONB
SECURITY DEFINER
AS $$
DECLARE
  v_current_balance DECIMAL;
  v_new_balance DECIMAL;
  v_card_name TEXT;
BEGIN
  -- Get current balance
  SELECT balance INTO v_current_balance
  FROM user_credits
  WHERE user_id = p_user_id;

  IF NOT FOUND THEN
    -- Create credit account with 0 balance
    INSERT INTO user_credits (user_id, balance)
    VALUES (p_user_id, 0)
    RETURNING balance INTO v_current_balance;
  END IF;

  -- Check if sufficient credits
  IF v_current_balance < p_credit_cost THEN
    RAISE EXCEPTION 'Insufficient credits. Required: %, Available: %', p_credit_cost, v_current_balance;
  END IF;

  -- Calculate new balance
  v_new_balance := v_current_balance - p_credit_cost;

  -- Update user balance
  UPDATE user_credits
  SET balance = v_new_balance,
      updated_at = NOW()
  WHERE user_id = p_user_id;

  -- Log credit consumption
  INSERT INTO credit_transactions (
    user_id,
    type,
    amount,
    balance_before,
    balance_after,
    description,
    metadata
  ) VALUES (
    p_user_id,
    'consumption',
    p_credit_cost,
    v_current_balance,
    v_new_balance,
    format('Translation to %s', p_language),
    jsonb_build_object(
      'card_id', p_card_id,
      'language', p_language,
      'consumption_type', 'translation'
    )
  );

  -- Log credit consumption detail
  SELECT name INTO v_card_name FROM cards WHERE id = p_card_id;
  
  INSERT INTO credit_consumptions (
    user_id,
    consumption_type,
    quantity,
    credits_per_unit,
    total_credits,
    metadata
  ) VALUES (
    p_user_id,
    'translation',
    1,
    p_credit_cost,
    p_credit_cost,
    jsonb_build_object(
      'card_id', p_card_id,
      'card_name', v_card_name,
      'language', p_language
    )
  );

  RETURN jsonb_build_object(
    'success', true,
    'user_id', p_user_id,
    'credits_consumed', p_credit_cost,
    'balance_before', v_current_balance,
    'balance_after', v_new_balance,
    'language', p_language
  );
END;
$$ LANGUAGE plpgsql;

-- =====================================================================
-- 2. Record Translation Completion
-- =====================================================================
-- Records translation in translation_history table
-- Called after translation completes (success or failure)
-- =====================================================================

CREATE OR REPLACE FUNCTION record_translation_completion(
  p_user_id UUID,
  p_card_id UUID,
  p_target_languages TEXT[],
  p_credit_cost DECIMAL,
  p_status VARCHAR DEFAULT 'completed',
  p_error_message TEXT DEFAULT NULL,
  p_metadata JSONB DEFAULT '{}'::JSONB
)
RETURNS UUID
SECURITY DEFINER
AS $$
DECLARE
  v_history_id UUID;
BEGIN
  INSERT INTO translation_history (
    card_id,
    target_languages,
    credit_cost,
    translated_by,
    translated_at,
    status,
    error_message,
    metadata
  ) VALUES (
    p_card_id,
    p_target_languages,
    p_credit_cost,
    p_user_id,
    NOW(),
    p_status,
    p_error_message,
    p_metadata
  )
  RETURNING id INTO v_history_id;

  RETURN v_history_id;
END;
$$ LANGUAGE plpgsql;

-- =====================================================================
-- Grant permissions to service_role (backend server)
-- =====================================================================

GRANT EXECUTE ON FUNCTION consume_translation_credits(UUID, UUID, VARCHAR, DECIMAL) TO service_role;
GRANT EXECUTE ON FUNCTION record_translation_completion(UUID, UUID, TEXT[], DECIMAL, VARCHAR, TEXT, JSONB) TO service_role;



-- File: translation_operations.sql
-- -----------------------------------------------------------------
DROP FUNCTION IF EXISTS get_card_for_translation_server CASCADE;
DROP FUNCTION IF EXISTS get_content_items_for_translation_server CASCADE;
DROP FUNCTION IF EXISTS get_card_content_hash_server CASCADE;
DROP FUNCTION IF EXISTS update_card_translations_server CASCADE;
DROP FUNCTION IF EXISTS get_content_item_for_update_server CASCADE;
DROP FUNCTION IF EXISTS update_content_item_translations_server CASCADE;
DROP FUNCTION IF EXISTS insert_translation_history_server CASCADE;

-- =================================================================
-- TRANSLATION OPERATIONS - SERVER-SIDE STORED PROCEDURES
-- =================================================================
-- All translation-related database operations from Express backend.
-- Called by backend Express server with service_role permissions.
-- Used for fetching content for translation and saving results.
-- =================================================================

-- Get card for translation (includes ALL translatable text fields)
DROP FUNCTION IF EXISTS get_card_for_translation_server CASCADE;
CREATE OR REPLACE FUNCTION get_card_for_translation_server(
    p_card_id UUID
)
RETURNS TABLE (
    id UUID,
    name TEXT,
    description TEXT,
    ai_instruction TEXT,
    ai_knowledge_base TEXT,
    ai_welcome_general TEXT,
    ai_welcome_item TEXT,
    content_hash TEXT,
    translations JSONB,
    user_id UUID,
    original_language TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.id, c.name, c.description,
        c.ai_instruction, c.ai_knowledge_base, c.ai_welcome_general, c.ai_welcome_item,
        c.content_hash, c.translations, c.user_id, c.original_language::TEXT
    FROM cards c
    WHERE c.id = p_card_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get content items for translation (includes ALL translatable text fields)
DROP FUNCTION IF EXISTS get_content_items_for_translation_server CASCADE;
CREATE OR REPLACE FUNCTION get_content_items_for_translation_server(
    p_card_id UUID
)
RETURNS TABLE (
    id UUID,
    name TEXT,
    content TEXT,
    ai_knowledge_base TEXT,
    content_hash TEXT,
    translations JSONB
) AS $$
BEGIN
    RETURN QUERY
    SELECT ci.id, ci.name, ci.content, ci.ai_knowledge_base, ci.content_hash, ci.translations
    FROM content_items ci
    WHERE ci.card_id = p_card_id
    ORDER BY ci.sort_order;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get fresh card content hash
DROP FUNCTION IF EXISTS get_card_content_hash_server CASCADE;
CREATE OR REPLACE FUNCTION get_card_content_hash_server(
    p_card_id UUID
)
RETURNS TEXT AS $$
DECLARE
    v_hash TEXT;
BEGIN
    SELECT content_hash INTO v_hash
    FROM cards
    WHERE id = p_card_id;
    
    RETURN v_hash;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update card translations
DROP FUNCTION IF EXISTS update_card_translations_server CASCADE;
CREATE OR REPLACE FUNCTION update_card_translations_server(
    p_card_id UUID,
    p_translations JSONB
)
RETURNS VOID AS $$
BEGIN
    UPDATE cards
    SET translations = p_translations
    WHERE id = p_card_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get content item for translation update
DROP FUNCTION IF EXISTS get_content_item_for_update_server CASCADE;
CREATE OR REPLACE FUNCTION get_content_item_for_update_server(
    p_item_id UUID
)
RETURNS TABLE (
    translations JSONB,
    content_hash TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT ci.translations, ci.content_hash
    FROM content_items ci
    WHERE ci.id = p_item_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update content item translations
DROP FUNCTION IF EXISTS update_content_item_translations_server CASCADE;
CREATE OR REPLACE FUNCTION update_content_item_translations_server(
    p_item_id UUID,
    p_translations JSONB
)
RETURNS VOID AS $$
BEGIN
    UPDATE content_items
    SET translations = p_translations
    WHERE id = p_item_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Insert translation history
DROP FUNCTION IF EXISTS insert_translation_history_server CASCADE;
CREATE OR REPLACE FUNCTION insert_translation_history_server(
    p_card_id UUID,
    p_user_id UUID,
    p_target_languages TEXT[],
    p_credit_cost DECIMAL,
    p_status TEXT,
    p_error_message TEXT,
    p_metadata JSONB
)
RETURNS UUID AS $$
DECLARE
    v_id UUID;
BEGIN
    INSERT INTO translation_history (
        card_id, translated_by, target_languages, credit_cost,
        translated_at, status, error_message, metadata
    ) VALUES (
        p_card_id, p_user_id, p_target_languages, p_credit_cost,
        NOW(), p_status, p_error_message, p_metadata
    )
    RETURNING id INTO v_id;
    
    RETURN v_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =================================================================
-- GRANTS - Only service_role can execute these
-- =================================================================
REVOKE ALL ON FUNCTION get_card_for_translation_server FROM PUBLIC, authenticated, anon;
GRANT EXECUTE ON FUNCTION get_card_for_translation_server TO service_role;

REVOKE ALL ON FUNCTION get_content_items_for_translation_server FROM PUBLIC, authenticated, anon;
GRANT EXECUTE ON FUNCTION get_content_items_for_translation_server TO service_role;

REVOKE ALL ON FUNCTION get_card_content_hash_server FROM PUBLIC, authenticated, anon;
GRANT EXECUTE ON FUNCTION get_card_content_hash_server TO service_role;

REVOKE ALL ON FUNCTION update_card_translations_server FROM PUBLIC, authenticated, anon;
GRANT EXECUTE ON FUNCTION update_card_translations_server TO service_role;

REVOKE ALL ON FUNCTION get_content_item_for_update_server FROM PUBLIC, authenticated, anon;
GRANT EXECUTE ON FUNCTION get_content_item_for_update_server TO service_role;

REVOKE ALL ON FUNCTION update_content_item_translations_server FROM PUBLIC, authenticated, anon;
GRANT EXECUTE ON FUNCTION update_content_item_translations_server TO service_role;

REVOKE ALL ON FUNCTION insert_translation_history_server FROM PUBLIC, authenticated, anon;
GRANT EXECUTE ON FUNCTION insert_translation_history_server TO service_role;



-- File: voice_credit_operations.sql
-- -----------------------------------------------------------------
DROP FUNCTION IF EXISTS get_voice_credit_balance_server CASCADE;
DROP FUNCTION IF EXISTS deduct_voice_credit_server CASCADE;
DROP FUNCTION IF EXISTS log_voice_call_end_server CASCADE;
DROP FUNCTION IF EXISTS get_voice_usage_stats_server CASCADE;
DROP FUNCTION IF EXISTS get_card_voice_enabled_server CASCADE;
DROP FUNCTION IF EXISTS purchase_voice_credits_with_credits_server CASCADE;

-- =================================================================
-- VOICE CREDIT OPERATIONS - SERVER-SIDE STORED PROCEDURES
-- =================================================================
-- Voice credit billing for realtime voice conversations.
-- Separate from general credits - integer-based (1 credit = 1 voice call).
-- Called by backend Express server with service_role permissions.
-- =================================================================

-- 1. Get voice credit balance
DROP FUNCTION IF EXISTS get_voice_credit_balance_server CASCADE;
CREATE OR REPLACE FUNCTION get_voice_credit_balance_server(
    p_user_id UUID
)
RETURNS INTEGER AS $$
DECLARE
    v_balance INTEGER;
BEGIN
    SELECT balance INTO v_balance
    FROM voice_credits
    WHERE user_id = p_user_id;

    RETURN COALESCE(v_balance, 0);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Deduct voice credit and create call log (atomic)
DROP FUNCTION IF EXISTS deduct_voice_credit_server CASCADE;
CREATE OR REPLACE FUNCTION deduct_voice_credit_server(
    p_user_id UUID,
    p_card_id UUID,
    p_session_id TEXT
)
RETURNS JSONB AS $$
DECLARE
    v_current_balance INTEGER;
    v_new_balance INTEGER;
    v_call_id UUID;
BEGIN
    -- Initialize credits if not exists
    INSERT INTO voice_credits (user_id, balance, total_purchased, total_consumed)
    VALUES (p_user_id, 0, 0, 0)
    ON CONFLICT (user_id) DO NOTHING;

    -- Get current balance with lock
    SELECT balance INTO v_current_balance
    FROM voice_credits
    WHERE user_id = p_user_id
    FOR UPDATE;

    IF v_current_balance IS NULL OR v_current_balance <= 0 THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'error', 'No voice credits remaining',
            'balance', COALESCE(v_current_balance, 0)
        );
    END IF;

    v_new_balance := v_current_balance - 1;

    -- Update balance
    UPDATE voice_credits
    SET balance = v_new_balance,
        total_consumed = total_consumed + 1,
        updated_at = NOW()
    WHERE user_id = p_user_id;

    -- Record transaction
    INSERT INTO voice_credit_transactions (
        user_id, amount, balance_before, balance_after, type,
        card_id, session_id, description
    ) VALUES (
        p_user_id, -1, v_current_balance, v_new_balance, 'usage',
        p_card_id, p_session_id,
        format('Voice call on card %s', p_card_id)
    );

    -- Create call log entry
    INSERT INTO voice_call_log (
        card_id, user_id, session_id, credit_deducted
    ) VALUES (
        p_card_id, p_user_id, p_session_id, TRUE
    ) RETURNING id INTO v_call_id;

    RETURN jsonb_build_object(
        'success', TRUE,
        'balance_before', v_current_balance,
        'balance_after', v_new_balance,
        'call_id', v_call_id
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Log voice call end (update duration)
-- Uses subquery instead of ORDER BY/LIMIT in UPDATE (PostgreSQL requirement)
DROP FUNCTION IF EXISTS log_voice_call_end_server CASCADE;
CREATE OR REPLACE FUNCTION log_voice_call_end_server(
    p_card_id UUID,
    p_session_id TEXT,
    p_duration_seconds INTEGER
)
RETURNS BOOLEAN AS $$
BEGIN
    UPDATE voice_call_log
    SET ended_at = NOW(),
        duration_seconds = p_duration_seconds
    WHERE id = (
        SELECT id FROM voice_call_log
        WHERE card_id = p_card_id
            AND session_id = p_session_id
            AND ended_at IS NULL
        ORDER BY started_at DESC
        LIMIT 1
    );

    RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Get voice usage stats
DROP FUNCTION IF EXISTS get_voice_usage_stats_server CASCADE;
CREATE OR REPLACE FUNCTION get_voice_usage_stats_server(
    p_user_id UUID,
    p_start_date TIMESTAMPTZ DEFAULT NULL,
    p_end_date TIMESTAMPTZ DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
    v_total_calls BIGINT;
    v_total_duration BIGINT;
    v_credits_used BIGINT;
    v_balance INTEGER;
BEGIN
    -- Get balance
    SELECT COALESCE(balance, 0) INTO v_balance
    FROM voice_credits
    WHERE user_id = p_user_id;

    -- Get call stats
    SELECT
        COUNT(*),
        COALESCE(SUM(duration_seconds), 0)
    INTO v_total_calls, v_total_duration
    FROM voice_call_log
    WHERE user_id = p_user_id
        AND (p_start_date IS NULL OR started_at >= p_start_date)
        AND (p_end_date IS NULL OR started_at <= p_end_date);

    -- Get credits used
    SELECT COALESCE(SUM(ABS(amount)), 0) INTO v_credits_used
    FROM voice_credit_transactions
    WHERE user_id = p_user_id
        AND type = 'usage'
        AND (p_start_date IS NULL OR created_at >= p_start_date)
        AND (p_end_date IS NULL OR created_at <= p_end_date);

    RETURN jsonb_build_object(
        'balance', COALESCE(v_balance, 0),
        'total_calls', v_total_calls,
        'total_duration_seconds', v_total_duration,
        'credits_used', v_credits_used
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. Get card voice enabled status
DROP FUNCTION IF EXISTS get_card_voice_enabled_server CASCADE;
CREATE OR REPLACE FUNCTION get_card_voice_enabled_server(
    p_card_id UUID
)
RETURNS JSONB AS $$
DECLARE
    v_voice_enabled BOOLEAN;
    v_owner_id UUID;
BEGIN
    SELECT realtime_voice_enabled, user_id
    INTO v_voice_enabled, v_owner_id
    FROM cards
    WHERE id = p_card_id;

    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'found', FALSE,
            'voice_enabled', FALSE,
            'owner_id', NULL
        );
    END IF;

    RETURN jsonb_build_object(
        'found', TRUE,
        'voice_enabled', COALESCE(v_voice_enabled, FALSE),
        'owner_id', v_owner_id
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. Purchase voice credits using credit balance (NOT Stripe)
-- Atomically deducts from user_credits and adds to voice_credits
DROP FUNCTION IF EXISTS purchase_voice_credits_with_credits_server CASCADE;
CREATE OR REPLACE FUNCTION purchase_voice_credits_with_credits_server(
    p_user_id UUID,
    p_package_size INTEGER,   -- number of voice credits to add
    p_credit_cost DECIMAL     -- cost in USD credits to deduct from user_credits balance
)
RETURNS JSONB AS $$
DECLARE
    v_credit_balance DECIMAL;
    v_new_credit_balance DECIMAL;
    v_voice_balance INTEGER;
    v_new_voice_balance INTEGER;
BEGIN
    -- Validate parameters
    IF p_package_size <= 0 THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'error', 'Package size must be greater than 0'
        );
    END IF;

    IF p_credit_cost <= 0 THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'error', 'Credit cost must be greater than 0'
        );
    END IF;

    -- Get current credit balance with lock
    SELECT balance INTO v_credit_balance
    FROM user_credits
    WHERE user_id = p_user_id
    FOR UPDATE;

    IF v_credit_balance IS NULL THEN
        v_credit_balance := 0;
    END IF;

    -- Check sufficient credit balance
    IF v_credit_balance < p_credit_cost THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'error', 'Insufficient credit balance',
            'current_balance', v_credit_balance,
            'required', p_credit_cost
        );
    END IF;

    -- Deduct from user_credits
    v_new_credit_balance := v_credit_balance - p_credit_cost;

    UPDATE user_credits
    SET balance = v_new_credit_balance,
        total_consumed = total_consumed + p_credit_cost,
        updated_at = NOW()
    WHERE user_id = p_user_id;

    -- Record credit consumption
    INSERT INTO credit_consumptions (
        user_id, card_id, quantity, credits_per_unit, total_credits,
        consumption_type, description
    ) VALUES (
        p_user_id, NULL, p_package_size,
        p_credit_cost / p_package_size, p_credit_cost,
        'voice_call',
        format('Purchased %s voice credits for $%s from credit balance', p_package_size, p_credit_cost)
    );

    -- Record credit transaction (debit side)
    INSERT INTO credit_transactions (
        user_id, amount, balance_before, balance_after, type,
        reference_type, description
    ) VALUES (
        p_user_id, -p_credit_cost, v_credit_balance, v_new_credit_balance,
        'consumption', 'voice_credit_purchase',
        format('Voice credit purchase: %s credits for $%s (credit balance: $%s -> $%s)',
               p_package_size, p_credit_cost, v_credit_balance, v_new_credit_balance)
    );

    -- Initialize voice credits if not exists
    INSERT INTO voice_credits (user_id, balance, total_purchased, total_consumed)
    VALUES (p_user_id, 0, 0, 0)
    ON CONFLICT (user_id) DO NOTHING;

    -- Lock and get current voice credit balance
    SELECT balance INTO v_voice_balance
    FROM voice_credits
    WHERE user_id = p_user_id
    FOR UPDATE;

    v_new_voice_balance := v_voice_balance + p_package_size;

    -- Add voice credits
    UPDATE voice_credits
    SET balance = v_new_voice_balance,
        total_purchased = total_purchased + p_package_size,
        updated_at = NOW()
    WHERE user_id = p_user_id;

    -- Record voice credit transaction (credit side)
    INSERT INTO voice_credit_transactions (
        user_id, amount, balance_before, balance_after, type,
        description
    ) VALUES (
        p_user_id, p_package_size, v_voice_balance, v_new_voice_balance, 'purchase',
        format('Purchased %s voice credits using $%s from credit balance', p_package_size, p_credit_cost)
    );

    RETURN jsonb_build_object(
        'success', TRUE,
        'credits_deducted', p_credit_cost,
        'credit_balance_before', v_credit_balance,
        'credit_balance_after', v_new_credit_balance,
        'voice_credits_added', p_package_size,
        'voice_balance_before', v_voice_balance,
        'voice_balance_after', v_new_voice_balance
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =================================================================
-- GRANTS - Only service_role can execute these
-- =================================================================
REVOKE ALL ON FUNCTION get_voice_credit_balance_server FROM PUBLIC, authenticated, anon;
GRANT EXECUTE ON FUNCTION get_voice_credit_balance_server TO service_role;

REVOKE ALL ON FUNCTION deduct_voice_credit_server FROM PUBLIC, authenticated, anon;
GRANT EXECUTE ON FUNCTION deduct_voice_credit_server TO service_role;

REVOKE ALL ON FUNCTION log_voice_call_end_server FROM PUBLIC, authenticated, anon;
GRANT EXECUTE ON FUNCTION log_voice_call_end_server TO service_role;

REVOKE ALL ON FUNCTION get_voice_usage_stats_server FROM PUBLIC, authenticated, anon;
GRANT EXECUTE ON FUNCTION get_voice_usage_stats_server TO service_role;

REVOKE ALL ON FUNCTION get_card_voice_enabled_server FROM PUBLIC, authenticated, anon;
GRANT EXECUTE ON FUNCTION get_card_voice_enabled_server TO service_role;

REVOKE ALL ON FUNCTION purchase_voice_credits_with_credits_server FROM PUBLIC, authenticated, anon;
GRANT EXECUTE ON FUNCTION purchase_voice_credits_with_credits_server TO service_role;


-- =================================================================
-- TRIGGERS
-- =================================================================

-- File: triggers.sql
-- -----------------------------------------------------------------
-- =================================================================
-- GENERIC TIMESTAMP UPDATE TRIGGER
-- =================================================================
-- Function for updating timestamps
-- MOVED TO sql/schemaStoreProc.sql

-- Triggers for 'updated_at' column
-- Cards
DROP TRIGGER IF EXISTS update_cards_updated_at ON public.cards;
CREATE TRIGGER update_cards_updated_at
    BEFORE UPDATE ON public.cards
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at();

-- Content items
DROP TRIGGER IF EXISTS update_content_items_updated_at ON public.content_items;
CREATE TRIGGER update_content_items_updated_at
    BEFORE UPDATE ON public.content_items
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at();

-- User credits
DROP TRIGGER IF EXISTS update_user_credits_updated_at ON public.user_credits;
CREATE TRIGGER update_user_credits_updated_at
    BEFORE UPDATE ON public.user_credits
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at();

-- Translation jobs trigger removed - translation_jobs table removed (Nov 8, 2025)
-- Job queue system replaced with synchronous translations + Socket.IO progress updates

-- =================================================================
-- AUTH RELATED TRIGGERS
-- =================================================================
-- Function to set default role for new users
-- MOVED TO sql/schemaStoreProc.sql

-- Trigger to call the function upon new user creation
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Grant execute permission on the function to Supabase internal roles
-- MOVED TO sql/schemaStoreProc.sql (with the function)

-- Note: For the trigger to work on auth.users, the database user that Supabase uses for its internal operations
-- (often `supabase_auth_admin` or a similar role) must have permissions to run the trigger function, 
-- and the function itself needs appropriate permissions (SECURITY DEFINER) if it modifies tables like auth.users.
-- The `SECURITY DEFINER` on `handle_new_user` and granting execute to `supabase_auth_admin` addresses this. 
-- (Function and its grant moved to sql/schemaStoreProc.sql)

-- =================================================================
-- TRANSLATION CONTENT HASH TRIGGERS
-- =================================================================
-- These triggers automatically calculate content_hash on INSERT and UPDATE
-- to enable translation freshness detection
-- =================================================================

-- Trigger function for cards table
-- Modified to allow hash override during import: only calculates if NULL
CREATE OR REPLACE FUNCTION update_card_content_hash()
RETURNS TRIGGER AS $$
BEGIN
  -- On INSERT: Only calculate hash if not already provided
  IF TG_OP = 'INSERT' THEN
    IF NEW.content_hash IS NULL THEN
      NEW.content_hash := md5(COALESCE(NEW.name, '') || '|' || COALESCE(NEW.description, ''));
      NEW.last_content_update := NOW();
    END IF;
  -- On UPDATE: Only recalculate if name or description changed AND hash wasn't manually set
  ELSIF TG_OP = 'UPDATE' THEN
    IF (NEW.name IS DISTINCT FROM OLD.name OR NEW.description IS DISTINCT FROM OLD.description) THEN
      -- Only recalculate if hash hasn't been manually updated
      IF NEW.content_hash = OLD.content_hash THEN
        NEW.content_hash := md5(COALESCE(NEW.name, '') || '|' || COALESCE(NEW.description, ''));
        NEW.last_content_update := NOW();
      END IF;
      -- Note: We don't clear translations here - they're marked as outdated via hash comparison
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop existing trigger if exists
DROP TRIGGER IF EXISTS trigger_update_card_content_hash ON cards;

-- Create trigger for cards (both INSERT and UPDATE)
CREATE TRIGGER trigger_update_card_content_hash
  BEFORE INSERT OR UPDATE ON cards
  FOR EACH ROW
  EXECUTE FUNCTION update_card_content_hash();

-- Trigger function for content_items table
-- Modified to allow hash override during import: only calculates if NULL
CREATE OR REPLACE FUNCTION update_content_item_content_hash()
RETURNS TRIGGER AS $$
BEGIN
  -- On INSERT: Only calculate hash if not already provided
  IF TG_OP = 'INSERT' THEN
    IF NEW.content_hash IS NULL THEN
      NEW.content_hash := md5(
        COALESCE(NEW.name, '') || '|' || 
        COALESCE(NEW.content, '') || '|' ||
        COALESCE(NEW.ai_knowledge_base, '')
      );
      NEW.last_content_update := NOW();
    END IF;
  -- On UPDATE: Only recalculate if any translatable field changed AND hash wasn't manually set
  ELSIF TG_OP = 'UPDATE' THEN
    IF (NEW.name IS DISTINCT FROM OLD.name OR 
        NEW.content IS DISTINCT FROM OLD.content OR
        NEW.ai_knowledge_base IS DISTINCT FROM OLD.ai_knowledge_base) THEN
      -- Only recalculate if hash hasn't been manually updated
      IF NEW.content_hash = OLD.content_hash THEN
        NEW.content_hash := md5(
          COALESCE(NEW.name, '') || '|' || 
          COALESCE(NEW.content, '') || '|' ||
          COALESCE(NEW.ai_knowledge_base, '')
        );
        NEW.last_content_update := NOW();
      END IF;
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop existing trigger if exists
DROP TRIGGER IF EXISTS trigger_update_content_item_content_hash ON content_items;

-- Create trigger for content_items (both INSERT and UPDATE)
CREATE TRIGGER trigger_update_content_item_content_hash
  BEFORE INSERT OR UPDATE ON content_items
  FOR EACH ROW
  EXECUTE FUNCTION update_content_item_content_hash();

