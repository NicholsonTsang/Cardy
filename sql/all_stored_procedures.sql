-- Combined Stored Procedures
-- Generated: Sun Oct 12 16:16:07 HKT 2025

-- Drop all existing functions first
-- Simple version: Drop all CardStudio CMS functions
-- Add this at the beginning of your deployment to ensure clean state

DO $$
DECLARE
    r RECORD;
BEGIN
    -- Drop all functions that are likely from CardStudio CMS
    FOR r IN 
        SELECT format('DROP FUNCTION IF EXISTS %I(%s) CASCADE', 
                     p.proname, 
                     pg_get_function_identity_arguments(p.oid)) as drop_cmd
        FROM pg_proc p
        JOIN pg_namespace n ON p.pronamespace = n.oid
        WHERE n.nspname = 'public'
        AND p.prokind = 'f'
        AND p.proname IN (
            -- Card management functions
            'create_card', 'update_card', 'delete_card', 'get_card_by_id',
            'get_user_cards', 'duplicate_card',
            
            -- Content management functions
            'create_content_item', 'update_content_item', 'delete_content_item',
            'get_content_items', 'reorder_content_items', 'update_content_item_parent',
            
            -- User management functions
            'get_or_create_user_profile', 'update_user_profile', 'get_user_profile_status',
            'submit_user_verification', 'upload_verification_document',
            
            -- Batch management functions
            'get_next_batch_number', 'issue_card_batch', 'get_card_batches',
            'get_issued_cards_with_batch', 'toggle_card_batch_disabled_status',
            'activate_issued_card', 'get_card_issuance_stats', 'delete_issued_card',
            'generate_batch_cards',
            
            -- Payment management functions
            'create_batch_payment', 'update_batch_payment_status', 'get_batch_payment_info',
            'confirm_batch_payment', 'process_stripe_payment',
            
            -- Print request functions
            'request_card_printing', 'get_print_requests_for_batch', 'withdraw_print_request',
            'get_user_print_requests',
            
            -- Public access functions
            'get_public_card_content', 'get_sample_issued_card_for_preview',
            'get_card_preview_access',
            
            -- Admin functions
            'admin_confirm_batch_payment', 'admin_waive_batch_payment',
            'admin_update_user_role', 'admin_update_verification_status',
            'admin_get_user_verification_details', 'admin_reset_user_verification',
            'admin_get_platform_stats', 'admin_get_pending_verifications',
            'admin_get_all_users', 'admin_update_print_request_status',
            'admin_get_all_print_requests', 'admin_add_print_notes',
            'admin_get_batch_details', 'admin_get_all_batches',
            'admin_disable_batch', 'admin_generate_cards_for_batch',
            'admin_get_user_by_email', 'admin_get_user_cards', 'admin_get_card_content',
            'admin_get_card_batches', 'admin_get_batch_issued_cards',
            
            -- Logging functions
            'log_operation', 'get_operations_log', 'get_operations_log_stats',
            
            -- Auth and utility functions
            'handle_new_user', 'get_card_content_items', 'get_content_item_by_id',
            'get_public_card_preview_content', 'create_batch_checkout_payment',
            'confirm_batch_payment_by_session', 'create_pending_batch_payment',
            'confirm_pending_batch_payment', 'get_card_preview_content',
            'admin_get_system_stats_enhanced', 'admin_change_user_role',
            'admin_manual_verification'
        )
    LOOP
        EXECUTE r.drop_cmd;
    END LOOP;
    
    RAISE NOTICE 'All CardStudio CMS functions dropped';
END $$;
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
BEGIN
    -- Check if the caller is an admin
    SELECT raw_user_meta_data->>'role' INTO caller_role
    FROM auth.users
    WHERE auth.users.id = auth.uid();

    IF caller_role != 'admin' THEN
        RAISE EXCEPTION 'Only admins can view operations log.';
    END IF;

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
    LIMIT p_limit OFFSET p_offset;
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

-- =================================================================
-- CARD MANAGEMENT FUNCTIONS
-- Functions for managing card designs (CRUD operations)
-- =================================================================

-- Get all cards for the current user (more secure)
CREATE OR REPLACE FUNCTION get_user_cards()
RETURNS TABLE (
    id UUID,
    name TEXT,
    description TEXT,
    image_url TEXT,
    original_image_url TEXT,
    crop_parameters JSONB,
    conversation_ai_enabled BOOLEAN,
    ai_instruction TEXT,
    ai_knowledge_base TEXT,
    qr_code_position TEXT,
    translations JSONB,
    original_language VARCHAR(10),
    content_hash TEXT,
    last_content_update TIMESTAMPTZ,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ
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
        c.ai_instruction,
        c.ai_knowledge_base,
        c.qr_code_position::TEXT,
        c.translations,
        c.original_language,
        c.content_hash,
        c.last_content_update,
        c.created_at,
        c.updated_at
    FROM cards c
    WHERE c.user_id = auth.uid()
    ORDER BY c.created_at DESC;
END;
$$;
GRANT EXECUTE ON FUNCTION get_user_cards() TO authenticated;

-- Create a new card (more secure)
CREATE OR REPLACE FUNCTION create_card(
    p_name TEXT,
    p_description TEXT,
    p_image_url TEXT DEFAULT NULL,
    p_original_image_url TEXT DEFAULT NULL,
    p_crop_parameters JSONB DEFAULT NULL,
    p_conversation_ai_enabled BOOLEAN DEFAULT FALSE,
    p_ai_instruction TEXT DEFAULT '',
    p_ai_knowledge_base TEXT DEFAULT '',
    p_qr_code_position TEXT DEFAULT 'BR',
    p_original_language VARCHAR(10) DEFAULT 'en'
) RETURNS UUID LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_card_id UUID;
BEGIN
    INSERT INTO cards (
        user_id,
        name,
        description,
        image_url,
        original_image_url,
        crop_parameters,
        conversation_ai_enabled,
        ai_instruction,
        ai_knowledge_base,
        qr_code_position,
        original_language
    ) VALUES (
        auth.uid(),
        p_name,
        p_description,
        p_image_url,
        p_original_image_url,
        p_crop_parameters,
        p_conversation_ai_enabled,
        p_ai_instruction,
        p_ai_knowledge_base,
        p_qr_code_position::"QRCodePosition",
        p_original_language
    )
    RETURNING id INTO v_card_id;
    
    -- Log operation
    PERFORM log_operation(format('Created card: %s', p_name));
    
    RETURN v_card_id;
END;
$$;
GRANT EXECUTE ON FUNCTION create_card(TEXT, TEXT, TEXT, TEXT, JSONB, BOOLEAN, TEXT, TEXT, TEXT, VARCHAR) TO authenticated;

-- Get a card by ID (more secure, relies on RLS policy)
CREATE OR REPLACE FUNCTION get_card_by_id(p_card_id UUID)
RETURNS TABLE (
    id UUID,
    user_id UUID,
    name TEXT,
    description TEXT,
    qr_code_position TEXT,
    image_url TEXT,
    conversation_ai_enabled BOOLEAN,
    ai_instruction TEXT,
    ai_knowledge_base TEXT,
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
        c.conversation_ai_enabled,
        c.ai_instruction,
        c.ai_knowledge_base,
        c.created_at, 
        c.updated_at
    FROM cards c
    WHERE c.id = p_card_id;
    -- No need to check user_id = auth.uid() as RLS policy will handle this
END;
$$;

-- Update an existing card (more secure)
CREATE OR REPLACE FUNCTION update_card(
    p_card_id UUID,
    p_name TEXT DEFAULT NULL,
    p_description TEXT DEFAULT NULL,
    p_image_url TEXT DEFAULT NULL,
    p_original_image_url TEXT DEFAULT NULL,
    p_crop_parameters JSONB DEFAULT NULL,
    p_conversation_ai_enabled BOOLEAN DEFAULT NULL,
    p_ai_instruction TEXT DEFAULT NULL,
    p_ai_knowledge_base TEXT DEFAULT NULL,
    p_qr_code_position TEXT DEFAULT NULL,
    p_original_language VARCHAR(10) DEFAULT NULL
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
        ai_instruction,
        ai_knowledge_base,
        qr_code_position,
        original_language,
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
    
    IF p_ai_instruction IS NOT NULL AND p_ai_instruction != v_old_record.ai_instruction THEN
        v_changes_made := v_changes_made || jsonb_build_object('ai_instruction', jsonb_build_object('from', v_old_record.ai_instruction, 'to', p_ai_instruction));
        has_changes := TRUE;
    END IF;
    
    IF p_ai_knowledge_base IS NOT NULL AND p_ai_knowledge_base != v_old_record.ai_knowledge_base THEN
        v_changes_made := v_changes_made || jsonb_build_object('ai_knowledge_base', jsonb_build_object('from', v_old_record.ai_knowledge_base, 'to', p_ai_knowledge_base));
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
    
    -- Only proceed if there are actual changes
    IF NOT has_changes THEN
        RETURN TRUE; -- No changes to make
END IF;
    
    -- Perform the update
    UPDATE cards
    SET 
        name = COALESCE(p_name, name),
        description = COALESCE(p_description, description),
        image_url = COALESCE(p_image_url, image_url),
        original_image_url = COALESCE(p_original_image_url, original_image_url),
        crop_parameters = COALESCE(p_crop_parameters, crop_parameters),
        conversation_ai_enabled = COALESCE(p_conversation_ai_enabled, conversation_ai_enabled),
        ai_instruction = COALESCE(p_ai_instruction, ai_instruction),
        ai_knowledge_base = COALESCE(p_ai_knowledge_base, ai_knowledge_base),
        qr_code_position = COALESCE(p_qr_code_position::"QRCodePosition", qr_code_position),
        original_language = COALESCE(p_original_language, original_language),
        updated_at = now()
    WHERE id = p_card_id AND user_id = auth.uid();
    
    -- Log operation
    PERFORM log_operation(format('Updated card: %s', COALESCE(p_name, v_old_record.name)));
    
    RETURN TRUE;
END;
$$;
GRANT EXECUTE ON FUNCTION update_card(UUID, TEXT, TEXT, TEXT, TEXT, JSONB, BOOLEAN, TEXT, TEXT, TEXT, VARCHAR) TO authenticated;

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

-- File: 03_content_management.sql
-- -----------------------------------------------------------------
DROP FUNCTION IF EXISTS get_card_content_items CASCADE;
DROP FUNCTION IF EXISTS get_content_item_by_id CASCADE;
DROP FUNCTION IF EXISTS create_content_item CASCADE;
DROP FUNCTION IF EXISTS update_content_item CASCADE;
DROP FUNCTION IF EXISTS update_content_item_order CASCADE;
DROP FUNCTION IF EXISTS delete_content_item CASCADE;

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
CREATE OR REPLACE FUNCTION create_content_item(
    p_card_id UUID,
    p_name TEXT,
    p_parent_id UUID DEFAULT NULL,
    p_content TEXT DEFAULT '',
    p_image_url TEXT DEFAULT NULL,
    p_original_image_url TEXT DEFAULT NULL,
    p_crop_parameters JSONB DEFAULT NULL,
    p_ai_knowledge_base TEXT DEFAULT ''
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
    
    -- If parent_id is provided, check if it exists and belongs to the same card
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
        sort_order
    ) VALUES (
        p_card_id,
        p_parent_id,
        p_name,
        p_content,
        p_image_url,
        p_original_image_url,
        p_crop_parameters,
        p_ai_knowledge_base,
        v_next_sort_order
    )
    RETURNING id INTO v_content_item_id;
    
    -- Log operation
    PERFORM log_operation(format('Created content item: %s', p_name));
    
    RETURN v_content_item_id;
END;
$$;

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

-- File: 04_batch_management.sql
-- -----------------------------------------------------------------
DROP FUNCTION IF EXISTS get_next_batch_number CASCADE;
DROP FUNCTION IF EXISTS issue_card_batch CASCADE;
DROP FUNCTION IF EXISTS issue_card_batch_with_credits CASCADE;
DROP FUNCTION IF EXISTS get_card_batches CASCADE;
DROP FUNCTION IF EXISTS get_issued_cards_with_batch CASCADE;
DROP FUNCTION IF EXISTS toggle_card_batch_disabled_status CASCADE;
DROP FUNCTION IF EXISTS activate_issued_card CASCADE;
DROP FUNCTION IF EXISTS get_card_issuance_stats CASCADE;
DROP FUNCTION IF EXISTS delete_issued_card CASCADE;
DROP FUNCTION IF EXISTS generate_batch_cards CASCADE;

-- =================================================================
-- CARD BATCH MANAGEMENT FUNCTIONS
-- Functions for managing card batches and issued cards
-- =================================================================

-- Get next batch number for a card
CREATE OR REPLACE FUNCTION get_next_batch_number(p_card_id UUID)
RETURNS INTEGER LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_max_batch_number INTEGER;
    v_user_id UUID;
BEGIN
    -- Check if the user owns the card
    SELECT user_id INTO v_user_id FROM cards WHERE id = p_card_id;
    
    IF v_user_id != auth.uid() THEN
        RAISE EXCEPTION 'Not authorized to access this card';
    END IF;
    
    -- Get the maximum batch number for this card
    SELECT COALESCE(MAX(batch_number), 0) INTO v_max_batch_number
    FROM card_batches
    WHERE card_id = p_card_id;
    
    RETURN v_max_batch_number + 1;
END;
$$;

-- Create a new card batch and issue cards (Legacy - Stripe payment)
-- This function is kept for backward compatibility
CREATE OR REPLACE FUNCTION issue_card_batch(
    p_card_id UUID,
    p_quantity INTEGER
) RETURNS UUID LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_batch_id UUID;
    v_batch_number INTEGER;
    v_batch_name TEXT;
    v_card_owner_id UUID;
BEGIN
    -- Validate inputs
    IF p_quantity <= 0 OR p_quantity > 1000 THEN
        RAISE EXCEPTION 'Quantity must be between 1 and 1000';
    END IF;
    
    -- Check if the user owns the card
    SELECT user_id INTO v_card_owner_id
    FROM cards
    WHERE id = p_card_id;
    
    IF v_card_owner_id IS NULL THEN
        RAISE EXCEPTION 'Card not found.';
    END IF;

    IF v_card_owner_id != auth.uid() THEN
        RAISE EXCEPTION 'Not authorized to issue cards for this card.';
    END IF;
    
    -- Get next batch number
    SELECT get_next_batch_number(p_card_id) INTO v_batch_number;
    v_batch_name := 'batch-' || v_batch_number;
    
    -- Create the batch (Step 1: Batch creation only)
    INSERT INTO card_batches (
        card_id,
        batch_name,
        batch_number,
        cards_count,
        created_by,
        payment_required,
        payment_completed,
        payment_amount_cents,
        payment_waived,
        cards_generated
    ) VALUES (
        p_card_id,
        v_batch_name,
        v_batch_number,
        p_quantity,
        auth.uid(),
        TRUE,
        FALSE,
        p_quantity * 200, -- $2 USD per card = 200 cents per card
        FALSE,
        FALSE -- Cards not generated yet
    )
    RETURNING id INTO v_batch_id;
    
    -- NOTE: Cards are NOT created here in the two-step process
    -- Cards will only be created after payment is confirmed via confirm_batch_payment()
    -- OR when admin waives payment via admin_waive_batch_payment()
    
    -- Log operation
    PERFORM log_operation(format('Issued batch "%s" with %s cards', v_batch_name, p_quantity));
    
    RETURN v_batch_id;
END;
$$;

-- Issue card batch using credits (New credit system)
CREATE OR REPLACE FUNCTION issue_card_batch_with_credits(
    p_card_id UUID,
    p_quantity INTEGER,
    p_print_request BOOLEAN DEFAULT FALSE
) RETURNS UUID LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_batch_id UUID;
    v_batch_number INTEGER;
    v_batch_name TEXT;
    v_card_owner_id UUID;
    v_credits_per_card DECIMAL := 2.00;
    v_total_credits DECIMAL;
    v_current_balance DECIMAL;
    v_consumption_result JSONB;
    i INTEGER;
BEGIN
    -- Validate inputs
    IF p_quantity <= 0 OR p_quantity > 1000 THEN
        RAISE EXCEPTION 'Quantity must be between 1 and 1000';
    END IF;
    
    -- Check if the user owns the card
    SELECT user_id INTO v_card_owner_id
    FROM cards
    WHERE id = p_card_id;
    
    IF v_card_owner_id IS NULL THEN
        RAISE EXCEPTION 'Card not found.';
    END IF;

    IF v_card_owner_id != auth.uid() THEN
        RAISE EXCEPTION 'Not authorized to issue cards for this card.';
    END IF;
    
    v_total_credits := p_quantity * v_credits_per_card;
    
    -- Check credit balance (check_credit_balance returns the actual balance as DECIMAL)
    v_current_balance := check_credit_balance(v_total_credits);
    IF v_current_balance < v_total_credits THEN
        RAISE EXCEPTION 'Insufficient credits. Required: %, Available: %. Please purchase more credits.', 
            v_total_credits, v_current_balance;
    END IF;
    
    -- Get next batch number
    SELECT get_next_batch_number(p_card_id) INTO v_batch_number;
    v_batch_name := 'batch-' || v_batch_number;
    
    -- Create the batch with credits payment
    INSERT INTO card_batches (
        card_id,
        batch_name,
        batch_number,
        cards_count,
        created_by,
        payment_required,
        payment_completed,
        payment_amount_cents,
        payment_waived,
        cards_generated,
        payment_method,
        credit_cost
    ) VALUES (
        p_card_id,
        v_batch_name,
        v_batch_number,
        p_quantity,
        auth.uid(),
        FALSE, -- No payment required (using credits)
        TRUE,  -- Payment completed (via credits)
        0,     -- No Stripe payment
        FALSE, -- Not waived
        TRUE,  -- Cards will be generated immediately
        'credits',
        v_total_credits
    )
    RETURNING id INTO v_batch_id;
    
    -- Consume credits
    SELECT consume_credits_for_batch(v_batch_id, p_quantity) INTO v_consumption_result;
    
    IF NOT (v_consumption_result->>'success')::boolean THEN
        -- Rollback batch creation if credit consumption fails
        DELETE FROM card_batches WHERE id = v_batch_id;
        RAISE EXCEPTION 'Failed to consume credits for batch';
    END IF;
    
    -- Generate the issued cards immediately (since payment is done via credits)
    FOR i IN 1..p_quantity LOOP
        INSERT INTO issue_cards (
            card_id,
            batch_id,
            active,
            issue_at
        ) VALUES (
            p_card_id,
            v_batch_id,
            false,
            NOW()
        );
    END LOOP;
    
    -- Update batch to mark cards as generated
    UPDATE card_batches 
    SET 
        cards_generated_at = NOW(),
        payment_completed_at = NOW()
    WHERE id = v_batch_id;
    
    -- Create print request if requested
    IF p_print_request THEN
        INSERT INTO print_requests (
            batch_id,
            status,
            created_by
        ) VALUES (
            v_batch_id,
            'SUBMITTED',
            auth.uid()
        );
    END IF;
    
    -- Log operation
    PERFORM log_operation(format('Issued batch "%s" with %s cards using credits', v_batch_name, p_quantity));
    
    RETURN v_batch_id;
END;
$$;

-- Get card batches for a card
CREATE OR REPLACE FUNCTION get_card_batches(p_card_id UUID)
RETURNS TABLE (
    id UUID,
    card_id UUID,
    batch_name TEXT,
    batch_number INTEGER,
    cards_count INTEGER,
    active_cards_count BIGINT,
    is_disabled BOOLEAN,
    payment_required BOOLEAN,
    payment_completed BOOLEAN,
    payment_amount_cents INTEGER,
    payment_completed_at TIMESTAMPTZ,
    payment_waived BOOLEAN,
    payment_waived_by UUID,
    payment_waived_at TIMESTAMPTZ,
    payment_waiver_reason TEXT,
    cards_generated BOOLEAN,
    cards_generated_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ
) LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_caller_role TEXT;
BEGIN
    -- Get caller's role
    SELECT raw_user_meta_data->>'role' INTO v_caller_role
    FROM auth.users
    WHERE auth.users.id = auth.uid();
    
    RETURN QUERY
    SELECT 
        cb.id,
        cb.card_id,
        cb.batch_name,
        cb.batch_number,
        cb.cards_count,
        COUNT(ic.id) FILTER (WHERE ic.active = true) as active_cards_count,
        cb.is_disabled,
        cb.payment_required,
        cb.payment_completed,
        cb.payment_amount_cents,
        cb.payment_completed_at,
        cb.payment_waived,
        cb.payment_waived_by,
        cb.payment_waived_at,
        cb.payment_waiver_reason,
        cb.cards_generated,
        cb.cards_generated_at,
        cb.created_at,
        cb.updated_at
    FROM card_batches cb
    LEFT JOIN issue_cards ic ON cb.id = ic.batch_id
    JOIN cards c ON cb.card_id = c.id
    -- Allow access if user owns the card OR if user is admin
    WHERE cb.card_id = p_card_id 
      AND (c.user_id = auth.uid() OR v_caller_role = 'admin')
    GROUP BY cb.id, cb.card_id, cb.batch_name, cb.batch_number, cb.cards_count, cb.is_disabled, 
             cb.payment_required, cb.payment_completed, cb.payment_amount_cents, cb.payment_completed_at, 
             cb.payment_waived, cb.payment_waived_by, cb.payment_waived_at, cb.payment_waiver_reason,
             cb.cards_generated, cb.cards_generated_at, cb.created_at, cb.updated_at
    ORDER BY cb.batch_number ASC;
END;
$$;

-- Get issued cards with batch information (including batch disabled status)
CREATE OR REPLACE FUNCTION get_issued_cards_with_batch(p_card_id UUID)
RETURNS TABLE (
    id UUID,
    card_id UUID,
    active BOOLEAN,
    issue_at TIMESTAMPTZ,
    active_at TIMESTAMPTZ,
    activated_by UUID,
    batch_id UUID,
    batch_name TEXT,
    batch_number INTEGER,
    batch_is_disabled BOOLEAN
) LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_caller_role TEXT;
BEGIN
    -- Get caller's role
    SELECT raw_user_meta_data->>'role' INTO v_caller_role
    FROM auth.users
    WHERE auth.users.id = auth.uid();
    
    RETURN QUERY
    SELECT 
        ic.id,
        c.id as card_id,
        ic.active,
        ic.issue_at,
        ic.active_at,
        ic.activated_by,
        cb.id as batch_id,
        cb.batch_name,
        cb.batch_number,
        cb.is_disabled as batch_is_disabled
    FROM issue_cards ic
    JOIN card_batches cb ON ic.batch_id = cb.id
    JOIN cards c ON ic.card_id = c.id
    -- Allow access if user owns the card OR if user is admin
    WHERE ic.card_id = p_card_id 
      AND (c.user_id = auth.uid() OR v_caller_role = 'admin')
    ORDER BY ic.issue_at DESC;
END;
$$;

-- Toggle disable status of a card batch
CREATE OR REPLACE FUNCTION toggle_card_batch_disabled_status(p_batch_id UUID, p_disable_status BOOLEAN)
RETURNS BOOLEAN LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_user_id UUID;
    v_card_id UUID;
BEGIN
    -- Check if the user owns the card that contains this batch
    SELECT c.user_id, cb.card_id INTO v_user_id, v_card_id
    FROM card_batches cb
    JOIN cards c ON cb.card_id = c.id
    WHERE cb.id = p_batch_id;
    
    IF v_user_id != auth.uid() THEN
        RAISE EXCEPTION 'Not authorized to modify this batch.';
    END IF;

    -- Check if there is an active print request for this batch if attempting to disable
    IF p_disable_status = TRUE THEN
        IF EXISTS (
            SELECT 1 FROM print_requests pr
            WHERE pr.batch_id = p_batch_id AND pr.status NOT IN ('COMPLETED', 'CANCELLED')
        ) THEN
            RAISE EXCEPTION 'Cannot disable a batch with an active print request. Please cancel or complete the print request first.';
        END IF;
    END IF;
    
    UPDATE card_batches
    SET is_disabled = p_disable_status,
        updated_at = now()
    WHERE id = p_batch_id;
    
    -- Log operation
    DECLARE
        batch_name TEXT;
    BEGIN
        SELECT cb.batch_name INTO batch_name
        FROM card_batches cb
        WHERE cb.id = p_batch_id;
        
        PERFORM log_operation(
            CASE 
                WHEN p_disable_status THEN 'Disabled batch: ' || batch_name || ' (ID: ' || p_batch_id || ')'
                ELSE 'Enabled batch: ' || batch_name || ' (ID: ' || p_batch_id || ')'
            END
        );
    END;
    
    RETURN FOUND;
END;
$$;

-- Activate an issued card by ID (simplified without activation code)
CREATE OR REPLACE FUNCTION activate_issued_card(p_card_id UUID)
RETURNS BOOLEAN LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
    UPDATE issue_cards
    SET 
        active = true,
        active_at = NOW(),
        activated_by = auth.uid()
    WHERE id = p_card_id AND active = false;
    
    -- Log operation
    PERFORM log_operation('Activated issued card');
    
    RETURN FOUND;
END;
$$;

-- Get card issuance statistics
CREATE OR REPLACE FUNCTION get_card_issuance_stats(p_card_id UUID)
RETURNS TABLE (
    total_issued BIGINT,
    total_activated BIGINT,
    activation_rate NUMERIC,
    total_batches BIGINT
) LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(ic.id) as total_issued,
        COUNT(ic.id) FILTER (WHERE ic.active = true) as total_activated,
        CASE 
            WHEN COUNT(ic.id) > 0 THEN 
                ROUND((COUNT(ic.id) FILTER (WHERE ic.active = true) * 100.0 / COUNT(ic.id)), 2)
            ELSE 0 
        END as activation_rate,
        COUNT(DISTINCT cb.id) as total_batches
    FROM issue_cards ic
    JOIN card_batches cb ON ic.batch_id = cb.id
    JOIN cards c ON ic.card_id = c.id
    WHERE ic.card_id = p_card_id AND c.user_id = auth.uid();
END;
$$;

-- Delete an issued card (secure replacement for direct table access)
CREATE OR REPLACE FUNCTION delete_issued_card(p_issued_card_id UUID)
RETURNS BOOLEAN LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_card_owner_id UUID;
BEGIN
    -- Check if the user owns the card that contains this issued card
    SELECT c.user_id INTO v_card_owner_id
    FROM issue_cards ic
    JOIN cards c ON ic.card_id = c.id
    WHERE ic.id = p_issued_card_id;
    
    IF v_card_owner_id IS NULL THEN
        RAISE EXCEPTION 'Issued card not found';
    END IF;
    
    IF v_card_owner_id != auth.uid() THEN
        RAISE EXCEPTION 'Not authorized to delete this issued card';
    END IF;
    
    -- Delete the issued card
    DELETE FROM issue_cards WHERE id = p_issued_card_id;
    
    -- Log operation
    PERFORM log_operation('Deleted issued card');
    
    RETURN FOUND;
END;
$$;

-- Generate cards for a paid or waived batch
CREATE OR REPLACE FUNCTION generate_batch_cards(
    p_batch_id UUID
) RETURNS UUID LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_batch_record RECORD;
    v_batch_owner_id UUID;
    i INTEGER;
BEGIN
    -- Get batch information and check ownership
    SELECT cb.*, c.user_id as card_owner INTO v_batch_record
    FROM card_batches cb
    JOIN cards c ON cb.card_id = c.id
    WHERE cb.id = p_batch_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Batch not found.';
    END IF;
    
    -- Check if user owns the batch or is admin
    IF v_batch_record.card_owner != auth.uid() THEN
        -- Check if caller is admin
        DECLARE
            caller_role TEXT;
        BEGIN
            SELECT raw_user_meta_data->>'role' INTO caller_role
            FROM auth.users
            WHERE auth.users.id = auth.uid();
            
            IF caller_role != 'admin' THEN
                RAISE EXCEPTION 'Not authorized to generate cards for this batch.';
            END IF;
        END;
    END IF;
    
    -- Check if cards can be generated
    IF v_batch_record.cards_generated = TRUE THEN
        RAISE EXCEPTION 'Cards have already been generated for this batch.';
    END IF;
    
    IF v_batch_record.payment_completed = FALSE AND v_batch_record.payment_waived = FALSE THEN
        RAISE EXCEPTION 'Payment required or must be waived before generating cards.';
    END IF;
    
    -- Generate the issued cards
    FOR i IN 1..v_batch_record.cards_count LOOP
        INSERT INTO issue_cards (
            card_id,
            batch_id,
            active,
            issue_at
        ) VALUES (
            v_batch_record.card_id,
            p_batch_id,
            false,
            NOW()
        );
    END LOOP;
    
    -- Update batch to mark cards as generated
    UPDATE card_batches 
    SET 
        cards_generated = TRUE,
        cards_generated_at = NOW(),
        updated_at = NOW()
    WHERE id = p_batch_id;
    
    -- Log operation
    PERFORM log_operation(format('Generated %s cards for batch "%s"', v_batch_record.cards_count, v_batch_record.batch_name));
    
    RETURN p_batch_id;
END;
$$; 

-- File: 05_payment_management_client.sql
-- -----------------------------------------------------------------
DROP FUNCTION IF EXISTS get_batch_payment_info CASCADE;
DROP FUNCTION IF EXISTS get_pending_batch_payment_info CASCADE;

-- =================================================================
-- PAYMENT MANAGEMENT FUNCTIONS (CLIENT-SIDE)
-- Functions called by Vue.js frontend application
-- =================================================================

-- Get batch payment information (Used by frontend)
CREATE OR REPLACE FUNCTION get_batch_payment_info(p_batch_id UUID)
RETURNS TABLE (
    payment_id UUID,
    stripe_checkout_session_id TEXT,
    stripe_payment_intent_id TEXT,
    amount_cents INTEGER,
    currency TEXT,
    payment_status TEXT,
    payment_method TEXT,
    failure_reason TEXT,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ
) LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_batch_owner_id UUID;
BEGIN
    -- Check batch ownership
    SELECT created_by INTO v_batch_owner_id
    FROM card_batches 
    WHERE id = p_batch_id;
    
    IF v_batch_owner_id IS NULL THEN
        RAISE EXCEPTION 'Batch not found.';
    END IF;
    
    IF v_batch_owner_id != auth.uid() THEN
        RAISE EXCEPTION 'Not authorized to view payment info for this batch.';
    END IF;
    
    RETURN QUERY
    SELECT 
        bp.id as payment_id,
        bp.stripe_checkout_session_id,
        bp.stripe_payment_intent_id,
        bp.amount_cents,
        bp.currency,
        bp.payment_status,
        bp.payment_method,
        bp.failure_reason,
        bp.created_at,
        bp.updated_at
    FROM batch_payments bp
    WHERE bp.batch_id = p_batch_id;
END;
$$;

-- Get pending batch payment information by session ID (Used by frontend for payment-first flow)
CREATE OR REPLACE FUNCTION get_pending_batch_payment_info(p_session_id TEXT)
RETURNS TABLE (
    payment_id UUID,
    card_id UUID,
    stripe_checkout_session_id TEXT,
    stripe_payment_intent_id TEXT,
    amount_cents INTEGER,
    currency TEXT,
    payment_status TEXT,
    payment_method TEXT,
    batch_name TEXT,
    cards_count INTEGER,
    failure_reason TEXT,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ
) LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
    RETURN QUERY
    SELECT 
        bp.id as payment_id,
        bp.card_id,
        bp.stripe_checkout_session_id,
        bp.stripe_payment_intent_id,
        bp.amount_cents,
        bp.currency,
        bp.payment_status,
        bp.payment_method,
        bp.batch_name,
        bp.cards_count,
        bp.failure_reason,
        bp.created_at,
        bp.updated_at
    FROM batch_payments bp
    WHERE bp.stripe_checkout_session_id = p_session_id
    AND bp.user_id = auth.uid();
END;
$$;

-- File: 06_print_requests.sql
-- -----------------------------------------------------------------
DROP FUNCTION IF EXISTS request_card_printing CASCADE;
DROP FUNCTION IF EXISTS get_print_requests_for_batch CASCADE;
DROP FUNCTION IF EXISTS withdraw_print_request CASCADE;

-- =================================================================
-- PRINT REQUEST FUNCTIONS
-- Functions for managing physical card printing requests
-- =================================================================

-- Request card printing for a batch
CREATE OR REPLACE FUNCTION request_card_printing(
    p_batch_id UUID, 
    p_shipping_address TEXT,
    p_contact_email TEXT DEFAULT NULL,
    p_contact_whatsapp TEXT DEFAULT NULL
)
RETURNS UUID LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_print_request_id UUID;
    v_user_id UUID;
    v_batch_is_disabled BOOLEAN;
    v_payment_completed BOOLEAN;
    v_payment_waived BOOLEAN;
    v_cards_generated BOOLEAN;
    v_user_email TEXT;
BEGIN
    -- Check if the user owns the card associated with the batch and get payment status
    SELECT c.user_id, cb.is_disabled, cb.payment_completed, cb.payment_waived, cb.cards_generated
    INTO v_user_id, v_batch_is_disabled, v_payment_completed, v_payment_waived, v_cards_generated
    FROM card_batches cb
    JOIN cards c ON cb.card_id = c.id
    WHERE cb.id = p_batch_id;

    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Batch not found.';
    END IF;

    IF v_user_id != auth.uid() THEN
        RAISE EXCEPTION 'Not authorized to request printing for this batch.';
    END IF;

    IF v_batch_is_disabled THEN
        RAISE EXCEPTION 'Cannot request printing for a disabled batch.';
    END IF;

    -- NEW: Validate payment status
    IF NOT v_payment_completed AND NOT v_payment_waived THEN
        RAISE EXCEPTION 'Payment must be completed or waived before requesting card printing.';
    END IF;

    -- NEW: Validate cards are generated
    IF NOT v_cards_generated THEN
        RAISE EXCEPTION 'Cards must be generated before requesting printing. Please contact support if payment was completed but cards are not generated.';
    END IF;

    -- Check if there is already an active print request for this batch
    IF EXISTS (
        SELECT 1 FROM print_requests pr
        WHERE pr.batch_id = p_batch_id AND pr.status NOT IN ('COMPLETED', 'CANCELLED')
    ) THEN
        RAISE EXCEPTION 'An active print request already exists for this batch.';
    END IF;

    -- Get user email for fallback if no contact email provided
    SELECT email INTO v_user_email 
    FROM auth.users 
    WHERE id = auth.uid();

    INSERT INTO print_requests (
        batch_id,
        user_id,
        shipping_address,
        contact_email,
        contact_whatsapp,
        status
    ) VALUES (
        p_batch_id,
        auth.uid(),
        p_shipping_address,
        COALESCE(p_contact_email, v_user_email),
        p_contact_whatsapp,
        'SUBMITTED'
    )
    RETURNING id INTO v_print_request_id;

    -- Log operation
    PERFORM log_operation('Submitted print request');

    RETURN v_print_request_id;
END;
$$;


-- Get print requests for a batch
CREATE OR REPLACE FUNCTION get_print_requests_for_batch(p_batch_id UUID)
RETURNS TABLE (
    id UUID,
    batch_id UUID,
    user_id UUID,
    status TEXT, -- "PrintRequestStatus"
    shipping_address TEXT,
    contact_email TEXT,
    contact_whatsapp TEXT,
    cards_count INTEGER,
    requested_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ
) LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_user_id_check UUID;
BEGIN
    -- Check if the user owns the card associated with the batch
    SELECT c.user_id INTO v_user_id_check
    FROM card_batches cb
    JOIN cards c ON cb.card_id = c.id
    WHERE cb.id = p_batch_id;

    IF v_user_id_check IS NULL THEN
        RAISE EXCEPTION 'Batch not found.';
    END IF;

    IF v_user_id_check != auth.uid() THEN
        RAISE EXCEPTION 'Not authorized to view print requests for this batch.';
    END IF;

    RETURN QUERY
    SELECT 
        pr.id,
        pr.batch_id,
        pr.user_id,
        pr.status::TEXT, -- Cast ENUM to TEXT for broader client compatibility if needed
        pr.shipping_address,
        pr.contact_email,
        pr.contact_whatsapp,
        cb.cards_count,
        pr.requested_at,
        pr.updated_at
    FROM print_requests pr
    JOIN card_batches cb ON pr.batch_id = cb.id
    WHERE pr.batch_id = p_batch_id
    ORDER BY pr.requested_at DESC;
END;
$$;

-- Withdraw/Cancel a print request (card issuer only)
CREATE OR REPLACE FUNCTION withdraw_print_request(
    p_request_id UUID,
    p_withdrawal_reason TEXT DEFAULT NULL
)
RETURNS BOOLEAN LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_user_id UUID;
    v_current_status "PrintRequestStatus";
    v_batch_id UUID;
    v_card_name TEXT;
    v_batch_name TEXT;
BEGIN
    -- Get print request details and verify ownership
    SELECT pr.user_id, pr.status, pr.batch_id, c.name, cb.batch_name
    INTO v_user_id, v_current_status, v_batch_id, v_card_name, v_batch_name
    FROM print_requests pr
    JOIN card_batches cb ON pr.batch_id = cb.id
    JOIN cards c ON cb.card_id = c.id
    WHERE pr.id = p_request_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Print request not found.';
    END IF;

    -- Check authorization
    IF v_user_id != auth.uid() THEN
        RAISE EXCEPTION 'Not authorized to withdraw this print request.';
    END IF;

    -- Check if withdrawal is allowed based on current status
    IF v_current_status != 'SUBMITTED' THEN
        RAISE EXCEPTION 'Print request can only be withdrawn when status is SUBMITTED. Current status: %', v_current_status;
    END IF;

    -- Update the print request status to CANCELLED
    UPDATE print_requests
    SET 
        status = 'CANCELLED',
        updated_at = NOW()
    WHERE id = p_request_id;

    -- Log operation
    PERFORM log_operation(format('Withdrew print request for batch "%s"', v_batch_name));
    
    RETURN TRUE;
END;
$$; 

-- File: 07_public_access.sql
-- -----------------------------------------------------------------
DROP FUNCTION IF EXISTS get_public_card_content CASCADE;
DROP FUNCTION IF EXISTS get_card_preview_access CASCADE;
DROP FUNCTION IF EXISTS get_card_preview_content CASCADE;

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

-- File: 11_admin_functions.sql
-- -----------------------------------------------------------------
DROP FUNCTION IF EXISTS admin_issue_free_batch CASCADE;
DROP FUNCTION IF EXISTS create_admin_feedback CASCADE;
DROP FUNCTION IF EXISTS get_admin_feedback_history CASCADE;
DROP FUNCTION IF EXISTS admin_get_system_stats_enhanced CASCADE;
DROP FUNCTION IF EXISTS admin_get_all_print_requests CASCADE;
DROP FUNCTION IF EXISTS admin_update_print_request_status CASCADE;
DROP FUNCTION IF EXISTS admin_get_pending_verifications CASCADE;
DROP FUNCTION IF EXISTS get_all_verifications CASCADE;
DROP FUNCTION IF EXISTS get_verification_by_id CASCADE;
DROP FUNCTION IF EXISTS get_all_users_with_details CASCADE;
DROP FUNCTION IF EXISTS get_admin_batches_requiring_attention CASCADE;
DROP FUNCTION IF EXISTS get_admin_all_batches CASCADE;
DROP FUNCTION IF EXISTS get_all_print_requests CASCADE;
DROP FUNCTION IF EXISTS admin_change_user_role CASCADE;
DROP FUNCTION IF EXISTS get_verification_feedbacks CASCADE;
DROP FUNCTION IF EXISTS get_print_request_feedbacks CASCADE;
DROP FUNCTION IF EXISTS reset_user_verification CASCADE;
DROP FUNCTION IF EXISTS admin_manual_verification CASCADE;
DROP FUNCTION IF EXISTS get_user_activity_summary CASCADE;
DROP FUNCTION IF EXISTS admin_get_all_users CASCADE;
DROP FUNCTION IF EXISTS admin_update_user_role CASCADE;
DROP FUNCTION IF EXISTS admin_get_user_by_email CASCADE;
DROP FUNCTION IF EXISTS admin_get_user_cards CASCADE;
DROP FUNCTION IF EXISTS admin_get_card_content CASCADE;
DROP FUNCTION IF EXISTS admin_get_card_batches CASCADE;
DROP FUNCTION IF EXISTS admin_get_batch_issued_cards CASCADE;

-- =================================================================
-- ADMIN FUNCTIONS
-- Functions for admin-only operations and system management
-- =================================================================

-- (Admin) Issue a free batch to a user
CREATE OR REPLACE FUNCTION admin_issue_free_batch(
    p_user_email TEXT,
    p_card_id UUID,
    p_cards_count INTEGER,
    p_reason TEXT DEFAULT 'Admin issued batch'
) RETURNS UUID LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_user_id UUID;
    v_card_record RECORD;
    v_batch_id UUID;
    v_batch_number INTEGER;
    v_batch_name TEXT;
    caller_role TEXT;
BEGIN
    -- Check if the caller is an admin
    SELECT raw_user_meta_data->>'role' INTO caller_role
    FROM auth.users
    WHERE auth.users.id = auth.uid();

    IF caller_role != 'admin' THEN
        RAISE EXCEPTION 'Only admins can issue free batches.';
    END IF;

    -- Validate cards count
    IF p_cards_count < 1 OR p_cards_count > 10000 THEN
        RAISE EXCEPTION 'Cards count must be between 1 and 10,000.';
    END IF;

    -- Get user by email
    SELECT id INTO v_user_id
    FROM auth.users
    WHERE email = p_user_email;
    
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'User with email % not found.', p_user_email;
    END IF;

    -- Get card information and verify ownership
    SELECT c.* INTO v_card_record
    FROM cards c
    WHERE c.id = p_card_id AND c.user_id = v_user_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Card not found or does not belong to user %.', p_user_email;
    END IF;

    -- Get next batch number for this card
    SELECT COALESCE(MAX(batch_number), 0) + 1 INTO v_batch_number
    FROM card_batches
    WHERE card_id = p_card_id;

    -- Auto-generate batch name
    v_batch_name := 'Batch #' || v_batch_number || ' - Issued by Admin';

    -- Generate new batch ID
    v_batch_id := gen_random_uuid();

    -- Create the batch with payment_required = FALSE (free batch)
    INSERT INTO card_batches (
        id,
        card_id,
        batch_name,
        batch_number,
        cards_count,
        created_by,
        payment_required,
        payment_completed,
        payment_waived,
        payment_waived_by,
        payment_waived_at,
        payment_waiver_reason,
        cards_generated,
        created_at,
        updated_at
    ) VALUES (
        v_batch_id,
        p_card_id,
        v_batch_name, -- Auto-generated name
        v_batch_number,
        p_cards_count,
        v_user_id, -- Batch owned by the target user
        FALSE, -- No payment required (free batch)
        FALSE, -- Not paid
        TRUE, -- Mark as waived so cards can be generated
        auth.uid(), -- Admin who issued it
        NOW(),
        p_reason,
        FALSE, -- Cards not yet generated
        NOW(),
        NOW()
    );

    -- Generate cards immediately
    PERFORM generate_batch_cards(v_batch_id);

    -- Log operation
    PERFORM log_operation(
        'Admin issued free batch: ' || v_batch_name || 
        ' to user ' || p_user_email || 
        ' (' || p_cards_count || ' cards) - Reason: ' || p_reason
    );

    RETURN v_batch_id;
END;
$$;

-- =================================================================
-- LEGACY ADMIN AUDIT FUNCTIONS (DEPRECATED - Use operations_log instead)
-- These functions are kept for backward compatibility but redirect to operations_log
-- =================================================================

-- Simple feedback creation for verification and print requests
CREATE OR REPLACE FUNCTION create_admin_feedback(
    p_target_user_id UUID,
    p_entity_type VARCHAR(20), -- 'verification' or 'print_request'
    p_entity_id UUID,
    p_message TEXT
) RETURNS UUID LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_feedback_id UUID;
    v_admin_email VARCHAR(255);
    caller_role TEXT;
BEGIN
    -- Check if the caller is an admin
    SELECT raw_user_meta_data->>'role' INTO caller_role
    FROM auth.users
    WHERE auth.users.id = auth.uid();

    IF caller_role != 'admin' THEN
        RAISE EXCEPTION 'Only admins can create feedback entries.';
    END IF;

    -- Validate entity type
    IF p_entity_type NOT IN ('verification', 'print_request') THEN
        RAISE EXCEPTION 'Invalid entity type. Must be verification or print_request.';
    END IF;

    -- Get admin email
    SELECT email INTO v_admin_email FROM auth.users WHERE auth.users.id = auth.uid();

    -- Insert into appropriate feedback table
    IF p_entity_type = 'verification' THEN
        INSERT INTO verification_feedbacks (
            user_id,
            admin_user_id,
            admin_email,
            message
        ) VALUES (
            p_entity_id, -- For verification, entity_id is the user_id
            auth.uid(),
            v_admin_email,
            p_message
        )
        RETURNING id INTO v_feedback_id;
    ELSE -- print_request
        INSERT INTO print_request_feedbacks (
            print_request_id,
            admin_user_id,
            admin_email,
            message
        ) VALUES (
            p_entity_id,
            auth.uid(),
            v_admin_email,
            p_message
        )
        RETURNING id INTO v_feedback_id;
    END IF;
    
    RETURN v_feedback_id;
END;
$$;

-- Get feedback history for verification or print request
CREATE OR REPLACE FUNCTION get_admin_feedback_history(
    p_entity_type VARCHAR(20),
    p_entity_id UUID
) RETURNS TABLE (
    id UUID,
    admin_user_id UUID,
    admin_email VARCHAR(255),
    message TEXT,
    created_at TIMESTAMPTZ
) LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    caller_role TEXT;
BEGIN
    -- Check if the caller is an admin
    SELECT raw_user_meta_data->>'role' INTO caller_role
    FROM auth.users
    WHERE auth.users.id = auth.uid();

    IF caller_role != 'admin' THEN
        RAISE EXCEPTION 'Only admins can view feedback history.';
    END IF;

    IF p_entity_type = 'verification' THEN
        RETURN QUERY
        SELECT 
            vf.id,
            vf.admin_user_id,
            vf.admin_email,
            vf.message,
            vf.created_at
        FROM verification_feedbacks vf
        WHERE vf.user_id = p_entity_id
        ORDER BY vf.created_at ASC; -- Chronological order for conversation flow
    ELSIF p_entity_type = 'print_request' THEN
        RETURN QUERY
        SELECT 
            pf.id,
            pf.admin_user_id,
            pf.admin_email,
            pf.message,
            pf.created_at
        FROM print_request_feedbacks pf
        WHERE pf.print_request_id = p_entity_id
        ORDER BY pf.created_at ASC; -- Chronological order for conversation flow
    ELSE
        RAISE EXCEPTION 'Invalid entity type. Must be verification or print_request.';
    END IF;
END;
$$;

-- Enhanced system statistics function
CREATE OR REPLACE FUNCTION admin_get_system_stats_enhanced()
RETURNS TABLE (
    total_users BIGINT,
    total_cards BIGINT,
    total_batches BIGINT,
    total_issued_cards BIGINT,
    total_activated_cards BIGINT,
    pending_payment_batches BIGINT,
    paid_batches BIGINT,
    waived_batches BIGINT,
    print_requests_submitted BIGINT,
    print_requests_processing BIGINT,
    print_requests_shipping BIGINT,
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
    daily_issued_cards BIGINT,
    weekly_issued_cards BIGINT,
    monthly_issued_cards BIGINT,
    -- AUDIT METRICS
    total_audit_entries BIGINT,
    critical_actions_today BIGINT,
    high_severity_actions_week BIGINT,
    unique_admin_users_month BIGINT
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
        (SELECT COUNT(*) FROM card_batches) as total_batches,
        (SELECT COUNT(*) FROM issue_cards) as total_issued_cards,
        (SELECT COUNT(*) FROM issue_cards WHERE active = true) as total_activated_cards,
        -- Payment metrics
        (SELECT COUNT(*) FROM card_batches WHERE payment_required = true AND payment_completed = false AND payment_waived = false) as pending_payment_batches,
        (SELECT COUNT(*) FROM card_batches WHERE payment_completed = true) as paid_batches,
        (SELECT COUNT(*) FROM card_batches WHERE payment_waived = true) as waived_batches,
        -- Print request metrics
        (SELECT COUNT(*) FROM print_requests WHERE status = 'SUBMITTED') as print_requests_submitted,
        (SELECT COUNT(*) FROM print_requests WHERE status = 'PROCESSING') as print_requests_processing,
        (SELECT COUNT(*) FROM print_requests WHERE status = 'SHIPPED') as print_requests_shipping,
        -- Revenue metrics
        (SELECT COALESCE(SUM(amount_cents), 0) FROM batch_payments WHERE payment_status = 'succeeded' AND created_at >= CURRENT_DATE) as daily_revenue_cents,
        (SELECT COALESCE(SUM(amount_cents), 0) FROM batch_payments WHERE payment_status = 'succeeded' AND created_at >= CURRENT_DATE - INTERVAL '7 days') as weekly_revenue_cents,
        (SELECT COALESCE(SUM(amount_cents), 0) FROM batch_payments WHERE payment_status = 'succeeded' AND created_at >= CURRENT_DATE - INTERVAL '30 days') as monthly_revenue_cents,
        (SELECT COALESCE(SUM(amount_cents), 0) FROM batch_payments WHERE payment_status = 'succeeded') as total_revenue_cents,
        -- Growth metrics
        (SELECT COUNT(*) FROM auth.users WHERE created_at >= CURRENT_DATE) as daily_new_users,
        (SELECT COUNT(*) FROM auth.users WHERE created_at >= CURRENT_DATE - INTERVAL '7 days') as weekly_new_users,
        (SELECT COUNT(*) FROM auth.users WHERE created_at >= CURRENT_DATE - INTERVAL '30 days') as monthly_new_users,
        (SELECT COUNT(*) FROM cards WHERE created_at >= CURRENT_DATE) as daily_new_cards,
        (SELECT COUNT(*) FROM cards WHERE created_at >= CURRENT_DATE - INTERVAL '7 days') as weekly_new_cards,
        (SELECT COUNT(*) FROM cards WHERE created_at >= CURRENT_DATE - INTERVAL '30 days') as monthly_new_cards,
        (SELECT COUNT(*) FROM issue_cards WHERE created_at >= CURRENT_DATE) as daily_issued_cards,
        (SELECT COUNT(*) FROM issue_cards WHERE created_at >= CURRENT_DATE - INTERVAL '7 days') as weekly_issued_cards,
        (SELECT COUNT(*) FROM issue_cards WHERE created_at >= CURRENT_DATE - INTERVAL '30 days') as monthly_issued_cards,
        -- Operations log metrics
        (SELECT COUNT(*) FROM operations_log) as total_audit_entries,
        (SELECT COUNT(*) FROM operations_log WHERE operation LIKE '%Waived payment%' AND created_at >= CURRENT_DATE) as payment_waivers_today,
        (SELECT COUNT(*) FROM operations_log WHERE operation LIKE '%Changed user role%' AND created_at >= CURRENT_DATE - INTERVAL '7 days') as role_changes_week,
        (SELECT COUNT(DISTINCT user_id) FROM operations_log WHERE user_role = 'admin' AND created_at >= CURRENT_DATE - INTERVAL '30 days') as unique_admin_users_month;
END;
$$;

-- =================================================================
-- UPDATED EXISTING FUNCTIONS
-- =================================================================

-- (Admin) Get all print requests for review
CREATE OR REPLACE FUNCTION admin_get_all_print_requests(
    p_status "PrintRequestStatus" DEFAULT NULL,
    p_search_query TEXT DEFAULT NULL,
    p_limit INTEGER DEFAULT 100,
    p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
    request_id UUID,
    batch_id UUID,
    user_id UUID,
    user_email TEXT,
    user_public_name TEXT,
    card_name TEXT,
    batch_name TEXT,
    cards_count INTEGER,
    status "PrintRequestStatus",
    shipping_address TEXT,
    contact_email TEXT,
    contact_whatsapp TEXT,
    requested_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ
) LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    caller_role TEXT;
BEGIN
    -- Check if the caller is an admin
    SELECT raw_user_meta_data->>'role' INTO caller_role
    FROM auth.users
    WHERE auth.users.id = auth.uid();

    IF caller_role != 'admin' THEN
        RAISE EXCEPTION 'Only admins can view all print requests.';
    END IF;

    RETURN QUERY
    SELECT 
        pr.id AS request_id,
        pr.batch_id AS batch_id,
        pr.user_id AS user_id,
        au.email::text AS user_email,
        SPLIT_PART(au.email, '@', 1)::text AS user_public_name, -- Use email username as display name
        c.name AS card_name,
        cb.batch_name AS batch_name,
        cb.cards_count AS cards_count,
        pr.status AS status,
        pr.shipping_address AS shipping_address,
        pr.contact_email AS contact_email,
        pr.contact_whatsapp AS contact_whatsapp,
        pr.requested_at AS requested_at,
        pr.updated_at AS updated_at
    FROM print_requests pr
    JOIN card_batches cb ON pr.batch_id = cb.id
    JOIN cards c ON cb.card_id = c.id
    LEFT JOIN auth.users au ON pr.user_id = au.id
    WHERE 
        (p_status IS NULL OR pr.status = p_status)
        AND (p_search_query IS NULL OR (
            au.email ILIKE '%' || p_search_query || '%' OR
            c.name ILIKE '%' || p_search_query || '%' OR
            cb.batch_name ILIKE '%' || p_search_query || '%' OR
            pr.shipping_address ILIKE '%' || p_search_query || '%'
        ))
    ORDER BY pr.requested_at DESC
    LIMIT p_limit OFFSET p_offset;
END;
$$;

-- (Admin) Update print request status
CREATE OR REPLACE FUNCTION admin_update_print_request_status(
    p_request_id UUID,
    p_new_status "PrintRequestStatus",
    p_admin_notes TEXT DEFAULT NULL
)
RETURNS BOOLEAN LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_request_record RECORD;
    caller_role TEXT;
BEGIN
    -- Check if the caller is an admin
    SELECT raw_user_meta_data->>'role' INTO caller_role
    FROM auth.users
    WHERE auth.users.id = auth.uid();

    IF caller_role != 'admin' THEN
        RAISE EXCEPTION 'Only admins can update print request status.';
    END IF;

    -- Get current request details
    SELECT pr.*, c.name as card_name, cb.batch_name
    INTO v_request_record
    FROM print_requests pr
    JOIN card_batches cb ON pr.batch_id = cb.id
    JOIN cards c ON cb.card_id = c.id
    WHERE pr.id = p_request_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Print request not found.';
    END IF;

    -- Update the print request (no more admin_notes field)
    UPDATE print_requests
    SET 
        status = p_new_status,
        updated_at = NOW()
    WHERE id = p_request_id;

    -- Create feedback entry if admin provided notes
    IF p_admin_notes IS NOT NULL AND LENGTH(TRIM(p_admin_notes)) > 0 THEN
        DECLARE
            v_admin_email VARCHAR(255);
        BEGIN
            SELECT email INTO v_admin_email FROM auth.users WHERE auth.users.id = auth.uid();
            
            INSERT INTO print_request_feedbacks (
                print_request_id,
                admin_user_id,
                admin_email,
                message
            ) VALUES (
                p_request_id,
                auth.uid(),
                v_admin_email,
                p_admin_notes
            );
        END;
    END IF;

    -- Log operation
    PERFORM log_operation('Updated print request status to ' || p_new_status || ' for batch: ' || v_request_record.batch_name || ' (Request ID: ' || p_request_id || ')');
    
    RETURN FOUND;
END;
$$;


-- (Admin) Get pending verification requests
CREATE OR REPLACE FUNCTION admin_get_pending_verifications(p_limit INTEGER DEFAULT 50)
RETURNS TABLE (
    user_id UUID,
    email VARCHAR(255),
    public_name TEXT,
    company_name TEXT,
    full_name TEXT,
    supporting_documents TEXT[],
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ
) LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    caller_role TEXT;
BEGIN
    -- Check if the caller is an admin
    SELECT raw_user_meta_data->>'role' INTO caller_role
    FROM auth.users
    WHERE auth.users.id = auth.uid();

    IF caller_role != 'admin' THEN
        RAISE EXCEPTION 'Only admins can view pending verifications.';
    END IF;

    RETURN QUERY
    SELECT 
        up.user_id,
        au.email,
        up.public_name,
        up.company_name,
        up.full_name,
        up.supporting_documents,
        up.created_at,
        up.updated_at
    FROM user_profiles up
    JOIN auth.users au ON up.user_id = au.id
    WHERE up.verification_status = 'PENDING_REVIEW'
    ORDER BY up.updated_at ASC
    LIMIT p_limit;
END;
$$;



-- Legacy functions removed - Use operations_log functions instead:
-- - Use get_operations_log() instead of get_admin_audit_logs()
-- - Use get_operations_log_stats() instead of get_admin_audit_logs_count()
-- See 00_logging.sql for new functions

-- (Admin) Get all verifications with comprehensive filtering
CREATE OR REPLACE FUNCTION get_all_verifications(
    p_status "ProfileStatus" DEFAULT NULL,
    p_search_query TEXT DEFAULT NULL,
    p_start_date TIMESTAMPTZ DEFAULT NULL,
    p_end_date TIMESTAMPTZ DEFAULT NULL,
    p_limit INTEGER DEFAULT 100,
    p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
    user_id UUID,
    user_email VARCHAR(255),
    public_name TEXT,
    bio TEXT,
    company_name TEXT,
    full_name TEXT,
    verification_status "ProfileStatus",
    supporting_documents TEXT[],
    verified_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ
) LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    caller_role TEXT;
BEGIN
    -- Check if caller is admin
    SELECT raw_user_meta_data->>'role' INTO caller_role
    FROM auth.users
    WHERE auth.users.id = auth.uid();

    IF caller_role != 'admin' THEN
        RAISE EXCEPTION 'Only admins can view all verifications.';
    END IF;

    RETURN QUERY
    SELECT 
        up.user_id,
        au.email,
        up.public_name,
        up.bio,
        up.company_name,
        up.full_name,
        up.verification_status,
        up.supporting_documents,
        up.verified_at,
        up.created_at,
        up.updated_at
    FROM public.user_profiles up
    JOIN auth.users au ON up.user_id = au.id
    WHERE 
        (p_status IS NULL OR up.verification_status = p_status)
        AND (p_search_query IS NULL OR (
            au.email ILIKE '%' || p_search_query || '%' OR
            up.public_name ILIKE '%' || p_search_query || '%' OR
            up.company_name ILIKE '%' || p_search_query || '%' OR
            up.full_name ILIKE '%' || p_search_query || '%'
        ))
        AND (p_start_date IS NULL OR up.updated_at >= p_start_date)
        AND (p_end_date IS NULL OR up.updated_at <= p_end_date)
        AND up.verification_status != 'NOT_SUBMITTED' -- Only show submitted verifications
    ORDER BY up.updated_at DESC
    LIMIT p_limit OFFSET p_offset;
END;
$$;

-- (Admin) Get verification by user ID
CREATE OR REPLACE FUNCTION get_verification_by_id(p_user_id UUID)
RETURNS TABLE (
    user_id UUID,
    user_email VARCHAR(255),
    public_name TEXT,
    bio TEXT,
    company_name TEXT,
    full_name TEXT,
    verification_status "ProfileStatus",
    supporting_documents TEXT[],
    verified_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ
) LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    caller_role TEXT;
BEGIN
    -- Check if caller is admin
    SELECT raw_user_meta_data->>'role' INTO caller_role
    FROM auth.users
    WHERE auth.users.id = auth.uid();

    IF caller_role != 'admin' THEN
        RAISE EXCEPTION 'Only admins can view verifications.';
    END IF;

    RETURN QUERY
    SELECT 
        up.user_id,
        au.email,
        up.public_name,
        up.bio,
        up.company_name,
        up.full_name,
        up.verification_status,
        up.supporting_documents,
        up.verified_at,
        up.created_at,
        up.updated_at
    FROM public.user_profiles up
    JOIN auth.users au ON up.user_id = au.id
    WHERE up.user_id = p_user_id
    AND up.verification_status != 'NOT_SUBMITTED'; -- Only show submitted verifications
END;
$$;

-- (Admin) Get all users with detailed information including activity stats
CREATE OR REPLACE FUNCTION get_all_users_with_details()
RETURNS TABLE (
    user_id UUID,
    user_email VARCHAR(255),
    role TEXT,
    public_name TEXT,
    bio TEXT,
    company_name TEXT,
    full_name TEXT,
    verification_status "ProfileStatus",
    supporting_documents TEXT[],
    verified_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ,
    last_sign_in_at TIMESTAMPTZ,
    cards_count INTEGER,
    issued_cards_count INTEGER,
    print_requests_count INTEGER
) LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    caller_role TEXT;
BEGIN
    -- Check if caller is admin
    SELECT raw_user_meta_data->>'role' INTO caller_role
    FROM auth.users
    WHERE auth.users.id = auth.uid();

    IF caller_role != 'admin' THEN
        RAISE EXCEPTION 'Only admins can view all users.';
    END IF;

    RETURN QUERY
    SELECT 
        au.id AS user_id,
        au.email AS user_email,
        au.raw_user_meta_data->>'role' AS role,
        COALESCE(up.public_name, '') AS public_name,
        COALESCE(up.bio, '') AS bio,
        COALESCE(up.company_name, '') AS company_name,
        COALESCE(up.full_name, '') AS full_name,
        COALESCE(up.verification_status, 'NOT_SUBMITTED') AS verification_status,
        COALESCE(up.supporting_documents, ARRAY[]::TEXT[]) AS supporting_documents,
        up.verified_at,
        COALESCE(up.created_at, au.created_at) AS created_at,
        up.updated_at,
        au.last_sign_in_at,
        COALESCE(card_stats.cards_count, 0)::INTEGER AS cards_count,
        COALESCE(issued_stats.issued_cards_count, 0)::INTEGER AS issued_cards_count,
        COALESCE(print_stats.print_requests_count, 0)::INTEGER AS print_requests_count
    FROM auth.users au
    LEFT JOIN public.user_profiles up ON au.id = up.user_id
    LEFT JOIN (
        SELECT c.user_id, COUNT(*) AS cards_count
        FROM public.cards c
        GROUP BY c.user_id
    ) card_stats ON au.id = card_stats.user_id
    LEFT JOIN (
        SELECT cb.created_by, COUNT(ic.*) AS issued_cards_count
        FROM public.card_batches cb
        LEFT JOIN public.issue_cards ic ON cb.id = ic.batch_id
        GROUP BY cb.created_by
    ) issued_stats ON au.id = issued_stats.created_by
    LEFT JOIN (
        SELECT pr.user_id, COUNT(*) AS print_requests_count
        FROM public.print_requests pr
        GROUP BY pr.user_id
    ) print_stats ON au.id = print_stats.user_id
    ORDER BY au.created_at DESC;
END;
$$;

-- (Admin) Get batches requiring attention
CREATE OR REPLACE FUNCTION get_admin_batches_requiring_attention()
RETURNS TABLE (
    id UUID,
    card_id UUID,
    card_name TEXT,
    batch_name TEXT,
    batch_number INTEGER,
    cards_count INTEGER,
    created_by UUID,
    user_email VARCHAR(255),
    payment_required BOOLEAN,
    payment_completed BOOLEAN,
    payment_amount_cents INTEGER,
    payment_waived BOOLEAN,
    cards_generated BOOLEAN,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ
) LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    caller_role TEXT;
BEGIN
    -- Check if caller is admin
    SELECT raw_user_meta_data->>'role' INTO caller_role
    FROM auth.users
    WHERE auth.users.id = auth.uid();

    IF caller_role != 'admin' THEN
        RAISE EXCEPTION 'Only admins can view batches requiring attention.';
    END IF;

    RETURN QUERY
    SELECT 
        cb.id,
        cb.card_id,
        c.name AS card_name,
        cb.batch_name,
        cb.batch_number,
        cb.cards_count,
        cb.created_by,
        au.email AS user_email,
        cb.payment_required,
        cb.payment_completed,
        cb.payment_amount_cents,
        cb.payment_waived,
        cb.cards_generated,
        cb.created_at,
        cb.updated_at
    FROM public.card_batches cb
    JOIN public.cards c ON cb.card_id = c.id
    JOIN auth.users au ON cb.created_by = au.id
    WHERE 
        -- Batches that need payment
        (cb.payment_required = true AND cb.payment_completed = false AND cb.payment_waived = false)
        OR
        -- Batches that are paid but cards not generated
        ((cb.payment_completed = true OR cb.payment_waived = true) AND cb.cards_generated = false)
        OR
        -- Batches that have been inactive for more than 7 days
        (cb.updated_at < NOW() - INTERVAL '7 days' AND cb.payment_completed = false AND cb.payment_waived = false)
    ORDER BY cb.created_at DESC;
END;
$$;

-- (Admin) Get all batches with filtering
CREATE OR REPLACE FUNCTION get_admin_all_batches(
    p_email_search TEXT DEFAULT NULL,
    p_payment_status TEXT DEFAULT NULL,
    p_limit INTEGER DEFAULT 100,
    p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
    id UUID,
    batch_number INTEGER,
    user_email VARCHAR(255),
    payment_status TEXT,
    cards_count INTEGER,
    created_at TIMESTAMPTZ
) LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    caller_role TEXT;
BEGIN
    -- Check if caller is admin
    SELECT raw_user_meta_data->>'role' INTO caller_role
    FROM auth.users
    WHERE auth.users.id = auth.uid();

    IF caller_role != 'admin' THEN
        RAISE EXCEPTION 'Only admins can view all batches.';
    END IF;

    RETURN QUERY
    SELECT 
        cb.id,
        cb.batch_number,
        au.email AS user_email,
        CASE 
            WHEN cb.payment_waived = true THEN 'WAIVED'
            WHEN cb.payment_completed = true THEN 'PAID'
            WHEN cb.payment_required = true THEN 'PENDING'
            ELSE 'FREE'
        END AS payment_status,
        cb.cards_count,
        cb.created_at
    FROM public.card_batches cb
    JOIN auth.users au ON cb.created_by = au.id
    WHERE 
        (p_email_search IS NULL OR au.email ILIKE '%' || p_email_search || '%')
        AND
        (p_payment_status IS NULL OR 
         (p_payment_status = 'WAIVED' AND cb.payment_waived = true) OR
         (p_payment_status = 'PAID' AND cb.payment_completed = true AND cb.payment_waived = false) OR
         (p_payment_status = 'PENDING' AND cb.payment_required = true AND cb.payment_completed = false AND cb.payment_waived = false) OR
         (p_payment_status = 'FREE' AND cb.payment_required = false))
    ORDER BY cb.created_at DESC
    LIMIT p_limit OFFSET p_offset;
END;
$$;

-- Alias function for backward compatibility
CREATE OR REPLACE FUNCTION get_all_print_requests(
    p_status "PrintRequestStatus" DEFAULT NULL,
    p_search_query TEXT DEFAULT NULL,
    p_limit INTEGER DEFAULT 100,
    p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
    id UUID,
    batch_id UUID,
    user_id UUID,
    user_email TEXT,
    user_public_name TEXT,
    card_name TEXT,
    batch_name TEXT,
    cards_count INTEGER,
    status "PrintRequestStatus",
    shipping_address TEXT,
    contact_email TEXT,
    contact_whatsapp TEXT,
    requested_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ
) LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
    -- This function simply calls the admin version with search support.
    -- This provides a consistent, simplified interface for clients.
    RETURN QUERY
    SELECT
        apr.request_id as id,
        apr.batch_id,
        apr.user_id,
        apr.user_email,
        apr.user_public_name,
        apr.card_name,
        apr.batch_name,
        apr.cards_count,
        apr.status,
        apr.shipping_address,
        apr.contact_email,
        apr.contact_whatsapp,
        apr.requested_at,
        apr.updated_at
    FROM admin_get_all_print_requests(p_status, p_search_query, p_limit, p_offset) apr;
END;
$$;

-- (Admin) Change user role with comprehensive audit logging
CREATE OR REPLACE FUNCTION admin_change_user_role(
    p_target_user_id UUID,
    p_new_role TEXT,
    p_reason TEXT
)
RETURNS BOOLEAN LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    caller_role TEXT;
    current_role TEXT;
    target_user_email TEXT;
    valid_roles TEXT[] := ARRAY['card_issuer', 'admin'];
BEGIN
    -- Check if the caller is an admin
    SELECT raw_user_meta_data->>'role' INTO caller_role
    FROM auth.users
    WHERE auth.users.id = auth.uid();

    IF caller_role != 'admin' THEN
        RAISE EXCEPTION 'Only admins can change user roles.';
    END IF;

    -- Validate new role
    IF p_new_role != ALL(valid_roles) THEN
        RAISE EXCEPTION 'Invalid role. Valid roles are: %', array_to_string(valid_roles, ', ');
    END IF;

    -- Get current role and email of target user
    SELECT 
        raw_user_meta_data->>'role',
        email
    INTO current_role, target_user_email
    FROM auth.users
    WHERE id = p_target_user_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Target user not found.';
    END IF;

    -- Check if role is actually changing
    IF current_role = p_new_role THEN
        RAISE EXCEPTION 'User already has role: %', p_new_role;
    END IF;

    -- Prevent self-demotion from admin
    IF auth.uid() = p_target_user_id AND current_role = 'admin' AND p_new_role != 'admin' THEN
        RAISE EXCEPTION 'Admins cannot demote themselves. Another admin must perform this action.';
    END IF;

    -- Update user role
    UPDATE auth.users
    SET 
        raw_user_meta_data = COALESCE(raw_user_meta_data, '{}'::jsonb) || jsonb_build_object('role', p_new_role),
        updated_at = NOW()
    WHERE id = p_target_user_id;

    -- Log role change
    PERFORM log_operation(
        format('Changed user role from %s to %s for user: %s', 
            COALESCE(current_role, 'none'), p_new_role, target_user_email)
    );
    
    RETURN FOUND;
END;
$$;

-- (Admin) Get feedbacks for a verification user
CREATE OR REPLACE FUNCTION get_verification_feedbacks(
    p_user_id UUID
)
RETURNS TABLE (
    id UUID,
    admin_user_id UUID,
    admin_email VARCHAR(255),
    message TEXT,
    created_at TIMESTAMPTZ
) LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    caller_role TEXT;
BEGIN
    -- Check if the caller is an admin
    SELECT raw_user_meta_data->>'role' INTO caller_role
    FROM auth.users
    WHERE auth.users.id = auth.uid();

    IF caller_role != 'admin' THEN
        RAISE EXCEPTION 'Only admins can view verification feedbacks.';
    END IF;

    RETURN QUERY
    SELECT 
        vf.id,
        vf.admin_user_id,
        vf.admin_email,
        vf.message,
        vf.created_at
    FROM verification_feedbacks vf
    WHERE vf.user_id = p_user_id
    ORDER BY vf.created_at ASC;
END;
$$;

-- (Admin) Get feedbacks for a print request
CREATE OR REPLACE FUNCTION get_print_request_feedbacks(
    p_request_id UUID
)
RETURNS TABLE (
    id UUID,
    admin_user_id UUID,
    admin_email VARCHAR(255),
    message TEXT,
    created_at TIMESTAMPTZ
) LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    caller_role TEXT;
BEGIN
    -- Check if the caller is an admin
    SELECT raw_user_meta_data->>'role' INTO caller_role
    FROM auth.users
    WHERE auth.users.id = auth.uid();

    IF caller_role != 'admin' THEN
        RAISE EXCEPTION 'Only admins can view print request feedbacks.';
    END IF;

    RETURN QUERY
    SELECT 
        pf.id,
        pf.admin_user_id,
        pf.admin_email,
        pf.message,
        pf.created_at
    FROM print_request_feedbacks pf
    WHERE pf.print_request_id = p_request_id
    ORDER BY pf.created_at ASC;
END;
$$;

-- (Admin) Reset user verification status
CREATE OR REPLACE FUNCTION reset_user_verification(
    p_user_id UUID
)
RETURNS BOOLEAN LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    caller_role TEXT;
    v_user_email TEXT;
BEGIN
    -- Check if the caller is an admin
    SELECT raw_user_meta_data->>'role' INTO caller_role
    FROM auth.users
    WHERE auth.users.id = auth.uid();

    IF caller_role != 'admin' THEN
        RAISE EXCEPTION 'Only admins can reset user verification.';
    END IF;

    -- Get target user email for audit logging
    SELECT email INTO v_user_email
    FROM auth.users
    WHERE id = p_user_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'User not found.';
    END IF;

    -- Reset verification status
    UPDATE user_profiles
    SET 
        verification_status = 'NOT_SUBMITTED',
        supporting_documents = NULL,
        verified_at = NULL,
        updated_at = NOW()
    WHERE user_id = p_user_id;

    -- Log operation
    PERFORM log_operation(format('Reset verification for user: %s', v_user_email));
    
    RETURN FOUND;
END;
$$;

-- (Admin) Manual verification approval
CREATE OR REPLACE FUNCTION admin_manual_verification(
    p_user_id UUID,
    p_reason TEXT
)
RETURNS BOOLEAN LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    caller_role TEXT;
    v_user_email TEXT;
    v_current_status "ProfileStatus";
BEGIN
    -- Check if the caller is an admin
    SELECT raw_user_meta_data->>'role' INTO caller_role
    FROM auth.users
    WHERE auth.users.id = auth.uid();

    IF caller_role != 'admin' THEN
        RAISE EXCEPTION 'Only admins can manually verify users.';
    END IF;

    -- Get target user details for audit logging
    SELECT au.email, up.verification_status 
    INTO v_user_email, v_current_status
    FROM auth.users au
    LEFT JOIN user_profiles up ON au.id = up.user_id
    WHERE au.id = p_user_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'User not found.';
    END IF;

    -- Create or update user profile if not exists
    INSERT INTO user_profiles (
        user_id,
        verification_status,
        verified_at,
        created_at,
        updated_at
    ) VALUES (
        p_user_id,
        'APPROVED',
        NOW(),
        NOW(),
        NOW()
    )
    ON CONFLICT (user_id) DO UPDATE SET
        verification_status = 'APPROVED',
        verified_at = NOW(),
        updated_at = NOW();
    
    -- Create feedback entry if admin provided reason
    IF p_reason IS NOT NULL AND LENGTH(TRIM(p_reason)) > 0 THEN
        DECLARE
            v_admin_email VARCHAR(255);
        BEGIN
            SELECT email INTO v_admin_email FROM auth.users WHERE auth.users.id = auth.uid();
            
            INSERT INTO verification_feedbacks (
                user_id,
                admin_user_id,
                admin_email,
                message
            ) VALUES (
                p_user_id,
                auth.uid(),
                v_admin_email,
                p_reason
            );
        END;
    END IF;

    -- Log the manual verification
    PERFORM log_operation(format('Manually approved verification for user: %s', v_user_email));
    
    RETURN TRUE;
END;
$$;

-- (Admin) Get user activity summary
CREATE OR REPLACE FUNCTION get_user_activity_summary(
    p_user_id UUID
)
RETURNS TABLE (
    cards_count INTEGER,
    batches_count INTEGER,
    issued_cards_count INTEGER,
    print_requests_count INTEGER,
    total_revenue_cents BIGINT,
    last_activity_date TIMESTAMPTZ,
    account_age_days INTEGER
) LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    caller_role TEXT;
    v_user_created_at TIMESTAMPTZ;
BEGIN
    -- Check if the caller is an admin
    SELECT raw_user_meta_data->>'role' INTO caller_role
    FROM auth.users
    WHERE auth.users.id = auth.uid();

    IF caller_role != 'admin' THEN
        RAISE EXCEPTION 'Only admins can view user activity summary.';
    END IF;

    -- Get user creation date
    SELECT created_at INTO v_user_created_at
    FROM auth.users
    WHERE id = p_user_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'User not found.';
    END IF;

    RETURN QUERY
    SELECT 
        COALESCE((SELECT COUNT(*)::INTEGER FROM cards WHERE user_id = p_user_id), 0) as cards_count,
        COALESCE((SELECT COUNT(*)::INTEGER FROM card_batches WHERE created_by = p_user_id), 0) as batches_count,
        COALESCE((
            SELECT COUNT(ic.*)::INTEGER 
            FROM card_batches cb
            LEFT JOIN issue_cards ic ON cb.id = ic.batch_id
            WHERE cb.created_by = p_user_id
        ), 0) as issued_cards_count,
        COALESCE((SELECT COUNT(*)::INTEGER FROM print_requests WHERE user_id = p_user_id), 0) as print_requests_count,
        COALESCE((
            SELECT SUM(bp.amount_cents)
            FROM card_batches cb
            LEFT JOIN batch_payments bp ON cb.id = bp.batch_id
            WHERE cb.created_by = p_user_id AND bp.payment_status = 'succeeded'
        ), 0) as total_revenue_cents,
        GREATEST(
            (SELECT MAX(updated_at) FROM cards WHERE user_id = p_user_id),
            (SELECT MAX(updated_at) FROM card_batches WHERE created_by = p_user_id),
            (SELECT MAX(updated_at) FROM print_requests WHERE user_id = p_user_id)
        ) as last_activity_date,
        EXTRACT(DAY FROM NOW() - v_user_created_at)::INTEGER as account_age_days;
END;
$$;

-- =================================================================
-- USER MANAGEMENT FUNCTIONS (without profile/verification)
-- =================================================================

-- Get all users with basic info and activity stats
CREATE OR REPLACE FUNCTION admin_get_all_users()
RETURNS TABLE (
    user_id UUID,
    user_email VARCHAR(255),
    role TEXT,
    cards_count INTEGER,
    issued_cards_count INTEGER,
    created_at TIMESTAMP WITH TIME ZONE,
    last_sign_in_at TIMESTAMP WITH TIME ZONE,
    email_confirmed_at TIMESTAMP WITH TIME ZONE
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
        COUNT(DISTINCT ic.id)::INTEGER as issued_cards_count,
        au.created_at,
        au.last_sign_in_at,
        au.email_confirmed_at
    FROM auth.users au
    LEFT JOIN cards c ON c.user_id = au.id
    LEFT JOIN card_batches cb ON cb.created_by = au.id
    LEFT JOIN issue_cards ic ON ic.batch_id = cb.id
    GROUP BY au.id, au.email, au.raw_user_meta_data, au.created_at, au.last_sign_in_at, au.email_confirmed_at
    ORDER BY au.created_at DESC;
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
    created_at TIMESTAMPTZ
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
        au.created_at
    FROM auth.users au
    WHERE LOWER(au.email) = LOWER(p_email);
END;
$$;

-- Get all cards for a specific user (admin view)
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
    qr_code_position TEXT,
    batches_count BIGINT,
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
        c.qr_code_position::TEXT,
        COUNT(cb.id)::BIGINT AS batches_count,
        c.created_at,
        c.updated_at,
        au.email::TEXT AS user_email
    FROM cards c
    JOIN auth.users au ON c.user_id = au.id
    LEFT JOIN card_batches cb ON c.id = cb.card_id
    WHERE c.user_id = p_user_id
    GROUP BY c.id, c.name, c.description, c.image_url, c.original_image_url,
             c.crop_parameters, c.conversation_ai_enabled, c.ai_instruction, c.ai_knowledge_base,
             c.qr_code_position, c.created_at, c.updated_at, au.email
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

-- Get card batches for admin viewing
CREATE OR REPLACE FUNCTION admin_get_card_batches(p_card_id UUID)
RETURNS TABLE (
    id UUID,
    card_id UUID,
    batch_name TEXT,
    batch_number INTEGER,
    payment_status TEXT,
    is_disabled BOOLEAN,
    cards_count BIGINT,
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
        cb.id,
        cb.card_id,
        cb.batch_name,
        cb.batch_number,
        CASE
            WHEN cb.payment_waived THEN 'WAIVED'
            WHEN cb.payment_completed THEN 'PAID'
            WHEN cb.payment_required THEN 'PENDING'
            ELSE 'PENDING'
        END AS payment_status,
        cb.is_disabled,
        COUNT(ic.id) AS cards_count,
        cb.created_at,
        cb.updated_at
    FROM card_batches cb
    LEFT JOIN issue_cards ic ON cb.id = ic.batch_id
    WHERE cb.card_id = p_card_id
    GROUP BY cb.id, cb.card_id, cb.batch_name, cb.batch_number, 
             cb.payment_waived, cb.payment_completed, cb.payment_required, 
             cb.is_disabled, cb.created_at, cb.updated_at
    ORDER BY cb.created_at DESC;
END;
$$;

-- Get issued cards for a batch (admin view)
CREATE OR REPLACE FUNCTION admin_get_batch_issued_cards(p_batch_id UUID)
RETURNS TABLE (
    id UUID,
    batch_id UUID,
    card_id UUID,
    active BOOLEAN,
    issue_at TIMESTAMPTZ,
    active_at TIMESTAMPTZ
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
        ic.id,
        ic.batch_id,
        ic.card_id,
        ic.active,
        ic.issue_at,
        ic.active_at
    FROM issue_cards ic
    WHERE ic.batch_id = p_batch_id
    ORDER BY ic.issue_at DESC;
END;
$$;

-- File: 12_translation_management.sql
-- -----------------------------------------------------------------
DROP FUNCTION IF EXISTS get_card_translation_status CASCADE;
DROP FUNCTION IF EXISTS get_card_translations CASCADE;
DROP FUNCTION IF EXISTS delete_card_translation CASCADE;
DROP FUNCTION IF EXISTS get_translation_history CASCADE;
DROP FUNCTION IF EXISTS get_outdated_translations CASCADE;

-- =====================================================================
-- TRANSLATION MANAGEMENT STORED PROCEDURES
-- =====================================================================
-- These procedures handle AI-powered multi-language translation
-- for card content. Translation costs 1 credit per language.
--
-- Client-side procedures (called from dashboard frontend):
-- - get_card_translation_status: Get translation status for all languages
-- - get_card_translations: Get full translations for a card
-- - store_card_translations: Store GPT-translated content (called by Edge Function)
-- - delete_card_translation: Remove a specific language translation
-- - get_translation_history: Get audit trail of translations
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
-- Stores GPT-generated translations for a card and its content items
-- This is called by the Edge Function after successful translation
-- =====================================================================

-- NOTE: store_card_translations has been moved to server-side/translation_management.sql
-- This function is called by Edge Functions and requires service_role permissions

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
-- Grant permissions
-- =====================================================================

GRANT EXECUTE ON FUNCTION get_card_translation_status(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_card_translations(UUID, VARCHAR) TO authenticated;
GRANT EXECUTE ON FUNCTION store_card_translations(UUID, UUID, TEXT[], JSONB, JSONB, DECIMAL) TO service_role;
GRANT EXECUTE ON FUNCTION delete_card_translation(UUID, VARCHAR) TO authenticated;
GRANT EXECUTE ON FUNCTION get_translation_history(UUID, INTEGER, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION get_outdated_translations(UUID) TO authenticated;



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
    batch_id UUID,
    batch_name TEXT,
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
        cc.batch_id,
        b.batch_name AS batch_name,
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
    LEFT JOIN card_batches b ON b.id = cc.batch_id
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


-- File: credit_management.sql
-- -----------------------------------------------------------------
DROP FUNCTION IF EXISTS initialize_user_credits CASCADE;
DROP FUNCTION IF EXISTS get_user_credits CASCADE;
DROP FUNCTION IF EXISTS check_credit_balance CASCADE;
DROP FUNCTION IF EXISTS create_credit_purchase_record CASCADE;
DROP FUNCTION IF EXISTS consume_credits CASCADE;
DROP FUNCTION IF EXISTS consume_credits_for_batch CASCADE;
DROP FUNCTION IF EXISTS get_credit_transactions CASCADE;
DROP FUNCTION IF EXISTS get_credit_purchases CASCADE;
DROP FUNCTION IF EXISTS get_credit_consumptions CASCADE;
DROP FUNCTION IF EXISTS create_credit_purchase CASCADE;
DROP FUNCTION IF EXISTS get_credit_statistics CASCADE;

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

-- Create a pending credit purchase record
CREATE OR REPLACE FUNCTION create_credit_purchase_record(
    p_stripe_session_id VARCHAR,
    p_amount_usd DECIMAL,
    p_credits_amount DECIMAL,
    p_metadata JSONB DEFAULT NULL,
    p_user_id UUID DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_user_id UUID;
    v_purchase_id UUID;
BEGIN
    -- Use provided user_id or fall back to auth.uid()
    v_user_id := COALESCE(p_user_id, auth.uid());
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    -- Insert pending purchase record
    INSERT INTO credit_purchases (
        user_id,
        stripe_session_id,
        amount_usd,
        credits_amount,
        status,
        metadata
    ) VALUES (
        v_user_id,
        p_stripe_session_id,
        p_amount_usd,
        p_credits_amount,
        'pending',
        p_metadata
    )
    RETURNING id INTO v_purchase_id;

    -- Log operation
    PERFORM log_operation(
        format('Credit purchase initiated: %s credits ($%s USD) - Session: %s', 
            p_credits_amount, p_amount_usd, p_stripe_session_id)
    );

    RETURN v_purchase_id;
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

-- Consume credits for batch issuance
CREATE OR REPLACE FUNCTION consume_credits_for_batch(
    p_batch_id UUID,
    p_card_count INTEGER
)
RETURNS JSONB AS $$
DECLARE
    v_user_id UUID;
    v_credits_per_card DECIMAL := 2.00; -- 2 credits per card
    v_total_credits DECIMAL;
    v_current_balance DECIMAL;
    v_new_balance DECIMAL;
    v_consumption_id UUID;
    v_transaction_id UUID;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    v_total_credits := p_card_count * v_credits_per_card;

    -- Lock the user credits row for update
    SELECT balance INTO v_current_balance
    FROM user_credits
    WHERE user_id = v_user_id
    FOR UPDATE;

    IF v_current_balance IS NULL OR v_current_balance < v_total_credits THEN
        RAISE EXCEPTION 'Insufficient credits. Required: %, Available: %', 
            v_total_credits, COALESCE(v_current_balance, 0);
    END IF;

    v_new_balance := v_current_balance - v_total_credits;

    -- Update user credits
    UPDATE user_credits
    SET 
        balance = v_new_balance,
        total_consumed = total_consumed + v_total_credits,
        updated_at = CURRENT_TIMESTAMP
    WHERE user_id = v_user_id;

    -- Record consumption
    INSERT INTO credit_consumptions (
        user_id, batch_id, consumption_type, quantity, 
        credits_per_unit, total_credits, description
    ) VALUES (
        v_user_id, p_batch_id, 'batch_issuance', p_card_count,
        v_credits_per_card, v_total_credits,
        format('Batch issuance: %s cards', p_card_count)
    ) RETURNING id INTO v_consumption_id;

    -- Record transaction
    INSERT INTO credit_transactions (
        user_id, type, amount, balance_before, balance_after,
        reference_type, reference_id, description
    ) VALUES (
        v_user_id, 'consumption', v_total_credits, v_current_balance, v_new_balance,
        'batch_issuance', p_batch_id,
        format('Batch issuance: %s cards @ %s credits each', p_card_count, v_credits_per_card)
    ) RETURNING id INTO v_transaction_id;

    -- Update batch with credit cost and payment method
    UPDATE card_batches
    SET 
        credit_cost = v_total_credits,
        payment_method = 'credits'
    WHERE id = p_batch_id;

    -- Log the operation
    PERFORM log_operation(
        format('Consumed %s credits for batch issuance: %s cards (Batch ID: %s)',
            v_total_credits, p_card_count, p_batch_id)
    );

    RETURN jsonb_build_object(
        'success', true,
        'consumption_id', v_consumption_id,
        'transaction_id', v_transaction_id,
        'credits_consumed', v_total_credits,
        'new_balance', v_new_balance
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
    batch_id UUID,
    card_id UUID,
    consumption_type VARCHAR,
    quantity INTEGER,
    credits_per_unit DECIMAL,
    total_credits DECIMAL,
    description TEXT,
    created_at TIMESTAMPTZ,
    batch_name TEXT,
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
        cc.batch_id,
        cc.card_id,
        cc.consumption_type,
        cc.quantity,
        cc.credits_per_unit,
        cc.total_credits,
        cc.description,
        cc.created_at,
        b.batch_name AS batch_name,
        c.name AS card_name
    FROM credit_consumptions cc
    LEFT JOIN card_batches b ON b.id = cc.batch_id
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
-- GRANT PERMISSIONS
-- =====================================================================
-- NOTE: Some functions use a "dual-use pattern" with COALESCE(p_user_id, auth.uid())
-- These can be called from:
--   - Frontend: Without p_user_id, uses auth.uid() from JWT
--   - Edge Functions: With explicit p_user_id parameter using SERVICE_ROLE_KEY
-- =====================================================================

-- Dual-use functions (called from frontend AND Edge Functions with SERVICE_ROLE_KEY)
GRANT EXECUTE ON FUNCTION check_credit_balance(DECIMAL, UUID) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION create_credit_purchase_record(VARCHAR, DECIMAL, DECIMAL, JSONB, UUID) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION consume_credits(DECIMAL, UUID, VARCHAR, JSONB) TO authenticated, service_role;

-- Client-only functions
GRANT EXECUTE ON FUNCTION initialize_user_credits() TO authenticated;
GRANT EXECUTE ON FUNCTION get_credit_statistics() TO authenticated;
GRANT EXECUTE ON FUNCTION get_user_credits() TO authenticated;

-- Add documentation comments
COMMENT ON FUNCTION check_credit_balance(DECIMAL, UUID) IS 
  'DUAL-USE PATTERN: Accepts optional p_user_id (for Edge Functions with SERVICE_ROLE_KEY) or falls back to auth.uid() (for frontend with user JWT). Granted to both authenticated and service_role roles.';
  
COMMENT ON FUNCTION create_credit_purchase_record(VARCHAR, DECIMAL, DECIMAL, JSONB, UUID) IS 
  'DUAL-USE PATTERN: Accepts optional p_user_id (for Edge Functions with SERVICE_ROLE_KEY) or falls back to auth.uid() (for frontend with user JWT). Granted to both authenticated and service_role roles. Called by create-credit-checkout-session Edge Function.';
  
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

-- File: credit_purchase_completion.sql
-- -----------------------------------------------------------------
DROP FUNCTION IF EXISTS complete_credit_purchase CASCADE;
DROP FUNCTION IF EXISTS refund_credit_purchase CASCADE;

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
    VALUES (v_user_id, 0, 0, 0)
    ON CONFLICT (user_id) DO NOTHING;

    -- Lock the user credits row for update
    SELECT balance INTO v_current_balance
    FROM user_credits
    WHERE user_id = v_user_id
    FOR UPDATE;

    v_new_balance := v_current_balance + v_credits_amount;

    -- Update user credits
    UPDATE user_credits
    SET 
        balance = v_new_balance,
        total_purchased = total_purchased + v_credits_amount,
        updated_at = CURRENT_TIMESTAMP
    WHERE user_id = v_user_id;

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
        v_user_id, 'purchase', v_credits_amount, v_current_balance, v_new_balance,
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
        'user_id', v_user_id
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
    WHERE user_id = v_user_id
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
    WHERE user_id = v_user_id;

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
        v_user_id, 'refund', p_refund_amount, v_current_balance, v_new_balance,
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

-- Grant execution permissions to service_role only (called by webhooks)
GRANT EXECUTE ON FUNCTION complete_credit_purchase(UUID, VARCHAR, VARCHAR, INTEGER, TEXT, JSONB) TO service_role;
GRANT EXECUTE ON FUNCTION refund_credit_purchase(UUID, UUID, DECIMAL, TEXT) TO service_role;


-- File: translation_management.sql
-- -----------------------------------------------------------------
DROP FUNCTION IF EXISTS store_card_translations CASCADE;

-- =====================================================================
-- SERVER-SIDE TRANSLATION STORED PROCEDURES
-- =====================================================================
-- These procedures are called by Edge Functions and require service_role permissions
-- =====================================================================

-- Store translated content from Edge Function
-- This function is called after GPT-4 has translated the content
CREATE OR REPLACE FUNCTION store_card_translations(
  p_user_id UUID, -- Explicit user ID from Edge Function
  p_card_id UUID,
  p_target_languages TEXT[],
  p_card_translations JSONB, -- {"zh-Hans": {"name": "...", "description": "..."}, ...}
  p_content_items_translations JSONB, -- {"item_id_1": {"zh-Hans": {"name": "...", "content": "..."}}, ...}
  p_credit_cost DECIMAL
)
RETURNS JSONB
SECURITY DEFINER
AS $$
DECLARE
  v_card_owner UUID;
  v_current_balance DECIMAL;
  v_translation_history_id UUID;
  v_content_hash TEXT;
  v_item_id UUID;
  v_item_translations JSONB;
  v_item_hash TEXT;
  v_result JSONB;
BEGIN
  -- Verify card ownership
  SELECT user_id INTO v_card_owner FROM cards WHERE id = p_card_id;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Card not found';
  END IF;

  IF v_card_owner != p_user_id THEN
    RAISE EXCEPTION 'Unauthorized: Card does not belong to user';
  END IF;

  -- Check credit balance
  SELECT check_credit_balance(p_credit_cost, p_user_id) INTO v_current_balance;

  -- Start transaction for atomic operation
  -- Get current card content hash
  SELECT content_hash INTO v_content_hash FROM cards WHERE id = p_card_id;

  -- Update card translations (merge with existing)
  UPDATE cards
  SET 
    translations = translations || p_card_translations,
    updated_at = NOW()
  WHERE id = p_card_id;

  -- Update content items translations
  FOR v_item_id, v_item_translations IN
    SELECT key::UUID, value
    FROM jsonb_each(p_content_items_translations)
  LOOP
    -- Get item content hash
    SELECT content_hash INTO v_item_hash 
    FROM content_items 
    WHERE id = v_item_id;

    -- Update item translations
    UPDATE content_items
    SET 
      translations = translations || v_item_translations,
      updated_at = NOW()
    WHERE id = v_item_id;
  END LOOP;

  -- Consume credits
  PERFORM consume_credits(
    p_credit_cost,
    p_user_id,
    'translation',
    jsonb_build_object(
      'card_id', p_card_id,
      'languages', p_target_languages,
      'language_count', array_length(p_target_languages, 1)
    )
  );

  -- Log to translation history
  INSERT INTO translation_history (
    card_id, 
    target_languages, 
    credit_cost, 
    translated_by,
    status,
    metadata
  )
  VALUES (
    p_card_id, 
    p_target_languages, 
    p_credit_cost, 
    p_user_id,
    'completed',
    jsonb_build_object(
      'model', 'gpt-4.1-nano',
      'language_count', array_length(p_target_languages, 1)
    )
  )
  RETURNING id INTO v_translation_history_id;

  -- Build result
  v_result := jsonb_build_object(
    'success', true,
    'card_id', p_card_id,
    'translated_languages', p_target_languages,
    'credits_used', p_credit_cost,
    'remaining_balance', v_current_balance - p_credit_cost,
    'translation_history_id', v_translation_history_id
  );

  RETURN v_result;
EXCEPTION
  WHEN OTHERS THEN
    RAISE EXCEPTION 'Failed to store translations: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- Grant execution permission to service_role only
GRANT EXECUTE ON FUNCTION store_card_translations(UUID, UUID, TEXT[], JSONB, JSONB, DECIMAL) TO service_role;



