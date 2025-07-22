-- Combined Stored Procedures
-- Generated: Tue Jul 22 21:37:02 HKT 2025

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
            'get_user_all_issued_cards', 'get_user_issuance_stats',
            'get_user_all_card_batches', 'get_user_recent_activity',
            'admin_update_user_role', 'admin_update_verification_status',
            'admin_get_user_verification_details', 'admin_reset_user_verification',
            'admin_get_platform_stats', 'admin_get_pending_verifications',
            'admin_get_all_users', 'admin_update_print_request_status',
            'admin_get_all_print_requests', 'admin_add_print_notes',
            'admin_get_batch_details', 'admin_get_all_batches',
            'admin_disable_batch', 'admin_generate_cards_for_batch'
        )
    LOOP
        EXECUTE r.drop_cmd;
    END LOOP;
    
    RAISE NOTICE 'All CardStudio CMS functions dropped';
END $$;
-- =================================================================
-- CLIENT-SIDE PROCEDURES
-- =================================================================

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
  
  -- Log new user registration in simplified audit table (self-registration)
  INSERT INTO admin_audit_log (
    admin_user_id,
    admin_email,
    target_user_id,
    target_user_email,
    action_type,
    description,
    details
  ) VALUES (
    NEW.id, -- Self-registration
    NEW.email, -- Admin email = user email for self-registration
    NEW.id,
    NEW.email, -- Target email = user email
    'USER_REGISTRATION',
    'New user account created: ' || NEW.email,
    jsonb_build_object(
      'email', NEW.email,
      'role', default_role,
      'registration_method', CASE 
        WHEN NEW.is_anonymous THEN 'anonymous'
        WHEN NEW.app_metadata->>'provider' = 'google' THEN 'google_oauth'
        WHEN NEW.app_metadata->>'provider' = 'github' THEN 'github_oauth'
        ELSE 'email_password'
      END,
      'email_domain', SPLIT_PART(NEW.email, '@', 2)
    )
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
    conversation_ai_enabled BOOLEAN,
    ai_prompt TEXT,
    qr_code_position TEXT,
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
        c.conversation_ai_enabled,
        c.ai_prompt,
        c.qr_code_position::TEXT,
        c.created_at,
        c.updated_at
    FROM cards c
    WHERE c.user_id = auth.uid()
    ORDER BY c.created_at DESC;
END;
$$;

-- Create a new card (more secure)
CREATE OR REPLACE FUNCTION create_card(
    p_name TEXT,
    p_description TEXT,
    p_image_url TEXT DEFAULT NULL,
    p_conversation_ai_enabled BOOLEAN DEFAULT FALSE,
    p_ai_prompt TEXT DEFAULT '',
    p_qr_code_position TEXT DEFAULT 'BR'
) RETURNS UUID LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_card_id UUID;
    caller_role TEXT;
BEGIN
    INSERT INTO cards (
        user_id,
        name,
        description,
        image_url,
        conversation_ai_enabled,
        ai_prompt,
        qr_code_position
    ) VALUES (
        auth.uid(),
        p_name,
        p_description,
        p_image_url,
        p_conversation_ai_enabled,
        p_ai_prompt,
        p_qr_code_position::"QRCodePosition"
    )
    RETURNING id INTO v_card_id;
    
    -- Get caller role for audit context
    SELECT raw_user_meta_data->>'role' INTO caller_role
    FROM auth.users
    WHERE id = auth.uid();
    
    -- Log card creation in audit table
    INSERT INTO admin_audit_log (
        admin_user_id,
        admin_email,
        target_user_id,
        target_user_email,
        action_type,
        description,
        details
    ) VALUES (
        auth.uid(),
        (SELECT email FROM auth.users WHERE id = auth.uid()),
        auth.uid(),
        (SELECT email FROM auth.users WHERE id = auth.uid()),
        'CARD_CREATION',
        'User created new card design: ' || p_name,
        jsonb_build_object(
            'card_id', v_card_id,
            'name', p_name,
            'description', p_description,
            'image_url', p_image_url,
            'conversation_ai_enabled', p_conversation_ai_enabled,
            'ai_prompt', p_ai_prompt,
            'qr_code_position', p_qr_code_position,
            'is_admin_action', (caller_role = 'admin'),
            'has_ai_features', p_conversation_ai_enabled,
            'has_custom_image', (p_image_url IS NOT NULL),
            'security_impact', 'low',
            'business_impact', 'medium'
        )
    );
    
    RETURN v_card_id;
END;
$$;

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
    ai_prompt TEXT,
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
        c.ai_prompt,
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
    p_conversation_ai_enabled BOOLEAN DEFAULT NULL,
    p_ai_prompt TEXT DEFAULT NULL,
    p_qr_code_position TEXT DEFAULT NULL
) RETURNS BOOLEAN LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_old_record RECORD;
    v_changes_made JSONB := '{}';
    caller_role TEXT;
    has_changes BOOLEAN := FALSE;
BEGIN
    -- Get existing card data before update for audit logging
    SELECT 
        id,
        name,
        description,
        image_url,
        conversation_ai_enabled,
        ai_prompt,
        qr_code_position,
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
    
    IF p_conversation_ai_enabled IS NOT NULL AND p_conversation_ai_enabled != v_old_record.conversation_ai_enabled THEN
        v_changes_made := v_changes_made || jsonb_build_object('conversation_ai_enabled', jsonb_build_object('from', v_old_record.conversation_ai_enabled, 'to', p_conversation_ai_enabled));
        has_changes := TRUE;
    END IF;
    
    IF p_ai_prompt IS NOT NULL AND p_ai_prompt != v_old_record.ai_prompt THEN
        v_changes_made := v_changes_made || jsonb_build_object('ai_prompt', jsonb_build_object('from', v_old_record.ai_prompt, 'to', p_ai_prompt));
        has_changes := TRUE;
    END IF;
    
    IF p_qr_code_position IS NOT NULL AND p_qr_code_position != v_old_record.qr_code_position::TEXT THEN
        v_changes_made := v_changes_made || jsonb_build_object('qr_code_position', jsonb_build_object('from', v_old_record.qr_code_position, 'to', p_qr_code_position));
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
        conversation_ai_enabled = COALESCE(p_conversation_ai_enabled, conversation_ai_enabled),
        ai_prompt = COALESCE(p_ai_prompt, ai_prompt),
        qr_code_position = COALESCE(p_qr_code_position::"QRCodePosition", qr_code_position),
        updated_at = now()
    WHERE id = p_card_id AND user_id = auth.uid();
    
    -- Get caller role for audit context
    SELECT raw_user_meta_data->>'role' INTO caller_role
    FROM auth.users
    WHERE id = auth.uid();
    
    -- Log card update in audit table
    INSERT INTO admin_audit_log (
        admin_user_id,
        admin_email,
        target_user_id,
        target_user_email,
        action_type,
        description,
        details
    ) VALUES (
        auth.uid(),
        (SELECT email FROM auth.users WHERE id = auth.uid()),
        v_old_record.user_id,
        (SELECT email FROM auth.users WHERE id = v_old_record.user_id),
        'CARD_UPDATE',
        'User updated card design: ' || COALESCE(p_name, v_old_record.name),
        jsonb_build_object(
            'card_id', p_card_id,
            'old_values', jsonb_build_object(
                'name', v_old_record.name,
                'description', v_old_record.description,
                'image_url', v_old_record.image_url,
                'conversation_ai_enabled', v_old_record.conversation_ai_enabled,
                'ai_prompt', v_old_record.ai_prompt,
                'qr_code_position', v_old_record.qr_code_position
            ),
            'new_values', jsonb_build_object(
                'name', COALESCE(p_name, v_old_record.name),
                'description', COALESCE(p_description, v_old_record.description),
                'image_url', COALESCE(p_image_url, v_old_record.image_url),
                'conversation_ai_enabled', COALESCE(p_conversation_ai_enabled, v_old_record.conversation_ai_enabled),
                'ai_prompt', COALESCE(p_ai_prompt, v_old_record.ai_prompt),
                'qr_code_position', COALESCE(p_qr_code_position, v_old_record.qr_code_position::TEXT)
            ),
            'changes_made', v_changes_made,
            'fields_changed', ARRAY(SELECT jsonb_object_keys(v_changes_made)),
            'is_admin_action', (caller_role = 'admin'),
            'ai_features_changed', (
                (p_conversation_ai_enabled IS NOT NULL AND p_conversation_ai_enabled != v_old_record.conversation_ai_enabled) OR
                (p_ai_prompt IS NOT NULL AND p_ai_prompt != v_old_record.ai_prompt)
            ),
            'security_impact', CASE 
                WHEN (p_conversation_ai_enabled IS NOT NULL AND p_conversation_ai_enabled != v_old_record.conversation_ai_enabled) OR
                     (p_ai_prompt IS NOT NULL AND p_ai_prompt != v_old_record.ai_prompt) THEN 'medium'
                ELSE 'low'
            END,
            'business_impact', 'medium'
        )
    );
    
    RETURN FOUND;
END;
$$;

-- Delete a card (more secure)
CREATE OR REPLACE FUNCTION delete_card(p_card_id UUID)
RETURNS BOOLEAN LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_card_record RECORD;
    v_batches_count INTEGER;
    v_issued_cards_count INTEGER;
    caller_role TEXT;
BEGIN
    -- Get card information before deletion for audit logging
    SELECT 
        c.id,
        c.name,
        c.description,
        c.image_url,
        c.conversation_ai_enabled,
        c.ai_prompt,
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
    
    -- Get associated data counts for audit logging
    SELECT COUNT(*) INTO v_batches_count
    FROM card_batches cb
    WHERE cb.card_id = p_card_id;
    
    SELECT COUNT(ic.*) INTO v_issued_cards_count
    FROM card_batches cb
    LEFT JOIN issue_cards ic ON cb.id = ic.batch_id
    WHERE cb.card_id = p_card_id;
    
    -- Get caller role for audit context
    SELECT raw_user_meta_data->>'role' INTO caller_role
    FROM auth.users
    WHERE id = auth.uid();
    
    -- Perform the deletion
    DELETE FROM cards WHERE id = p_card_id AND user_id = auth.uid();
    
    -- Log card deletion in audit table (CRITICAL for compliance)
    INSERT INTO admin_audit_log (
        admin_user_id,
        admin_email,
        target_user_id,
        target_user_email,
        action_type,
        description,
        details
    ) VALUES (
        auth.uid(),
        (SELECT email FROM auth.users WHERE id = auth.uid()),
        v_card_record.user_id,
        (SELECT email FROM auth.users WHERE id = v_card_record.user_id),
        'CARD_DELETION',
        'User deleted card design: ' || v_card_record.name,
        jsonb_build_object(
            'card_id', v_card_record.id,
            'card_name', v_card_record.name,
            'deleted_card_data', jsonb_build_object(
                'name', v_card_record.name,
                'description', v_card_record.description,
                'image_url', v_card_record.image_url,
                'conversation_ai_enabled', v_card_record.conversation_ai_enabled,
                'ai_prompt', v_card_record.ai_prompt,
                'qr_code_position', v_card_record.qr_code_position,
                'created_at', v_card_record.created_at,
                'updated_at', v_card_record.updated_at
            ),
            'is_admin_action', (caller_role = 'admin'),
            'data_impact', CASE 
                WHEN v_issued_cards_count > 0 THEN 'high'
                WHEN v_batches_count > 0 THEN 'medium'
                ELSE 'low'
            END,
            'batches_affected', v_batches_count,
            'issued_cards_affected', v_issued_cards_count,
            'had_ai_features', v_card_record.conversation_ai_enabled,
            'security_impact', 'medium',
            'deleted_at', NOW()
        )
    );
    
    RETURN FOUND;
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
    ai_metadata TEXT,
    sort_order INTEGER,
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
        ci.ai_metadata,
        ci.sort_order,
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

-- Get a content item by ID (updated with ordering)
CREATE OR REPLACE FUNCTION get_content_item_by_id(p_content_item_id UUID)
RETURNS TABLE (
    id UUID,
    card_id UUID,
    parent_id UUID,
    name TEXT,
    content TEXT,
    image_url TEXT,
    ai_metadata TEXT,
    sort_order INTEGER,
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
        ci.ai_metadata,
        ci.sort_order,
        ci.created_at,
        ci.updated_at
    FROM content_items ci
    JOIN cards c ON ci.card_id = c.id
    WHERE ci.id = p_content_item_id AND c.user_id = auth.uid();
END;
$$;

-- Create a new content item (updated with ordering)
CREATE OR REPLACE FUNCTION create_content_item(
    p_card_id UUID,
    p_name TEXT,
    p_parent_id UUID DEFAULT NULL,
    p_content TEXT DEFAULT '',
    p_image_url TEXT DEFAULT NULL,
    p_ai_metadata TEXT DEFAULT ''
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
        ai_metadata,
        sort_order
    ) VALUES (
        p_card_id,
        p_parent_id,
        p_name,
        p_content,
        p_image_url,
        p_ai_metadata,
        v_next_sort_order
    )
    RETURNING id INTO v_content_item_id;
    
    RETURN v_content_item_id;
END;
$$;

-- Update an existing content item (updated with ordering)
CREATE OR REPLACE FUNCTION update_content_item(
    p_content_item_id UUID,
    p_name TEXT DEFAULT NULL,
    p_content TEXT DEFAULT NULL,
    p_image_url TEXT DEFAULT NULL,
    p_ai_metadata TEXT DEFAULT NULL
) RETURNS BOOLEAN LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_user_id UUID;
BEGIN
    -- Check if the user owns the card that contains this content item
    SELECT c.user_id INTO v_user_id
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
        ai_metadata = COALESCE(p_ai_metadata, ai_metadata),
        updated_at = now()
    WHERE id = p_content_item_id;
    
    RETURN FOUND;
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
    
    RETURN FOUND;
END;
$$;

-- Delete a content item
CREATE OR REPLACE FUNCTION delete_content_item(p_content_item_id UUID)
RETURNS BOOLEAN LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_user_id UUID;
BEGIN
    -- Check if the user owns the card that contains this content item
    SELECT c.user_id INTO v_user_id
    FROM content_items ci
    JOIN cards c ON ci.card_id = c.id
    WHERE ci.id = p_content_item_id;
    
    IF v_user_id != auth.uid() THEN
        RAISE EXCEPTION 'Not authorized to delete this content item';
    END IF;
    
    -- Delete the content item (cascade will handle children)
    DELETE FROM content_items WHERE id = p_content_item_id;
    
    RETURN FOUND;
END;
$$; 

-- File: 04_batch_management.sql
-- -----------------------------------------------------------------
DROP FUNCTION IF EXISTS get_next_batch_number CASCADE;
DROP FUNCTION IF EXISTS issue_card_batch CASCADE;
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

-- Create a new card batch and issue cards
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
BEGIN
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
    WHERE cb.card_id = p_card_id AND c.user_id = auth.uid()
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
BEGIN
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
    WHERE ic.card_id = p_card_id AND c.user_id = auth.uid()
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
    
    -- Log batch status change in audit table
    DECLARE
        caller_role TEXT;
        batch_name TEXT;
        is_admin_action BOOLEAN := FALSE;
    BEGIN
        SELECT raw_user_meta_data->>'role' INTO caller_role
        FROM auth.users
        WHERE auth.users.id = auth.uid();
        
        SELECT cb.batch_name INTO batch_name
        FROM card_batches cb
        WHERE cb.id = p_batch_id;
        
        IF caller_role = 'admin' THEN
            is_admin_action := TRUE;
        END IF;
        
        INSERT INTO admin_audit_log (
            admin_user_id,
            admin_email,
            target_user_id,
            target_user_email,
            action_type,
            description,
            details
        ) VALUES (
            auth.uid(),
            (SELECT email FROM auth.users WHERE id = auth.uid()),
            v_user_id,
            (SELECT email FROM auth.users WHERE id = v_user_id),
            'BATCH_STATUS_CHANGE',
            CASE 
                WHEN p_disable_status THEN 'Batch disabled by user: ' || batch_name
                ELSE 'Batch enabled by user: ' || batch_name
            END,
            jsonb_build_object(
                'batch_id', p_batch_id,
                'card_id', v_card_id,
                'batch_name', batch_name,
                'action', CASE 
                    WHEN p_disable_status THEN 'batch_disabled'
                    ELSE 'batch_enabled'
                END,
                'old_status', jsonb_build_object('is_disabled', NOT p_disable_status),
                'new_status', jsonb_build_object('is_disabled', p_disable_status),
                'is_admin_action', is_admin_action,
                'status_change', CASE 
                    WHEN p_disable_status THEN 'enabled_to_disabled'
                    ELSE 'disabled_to_enabled'
                END
            )
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
    
    -- Log card generation in audit table
    DECLARE
        caller_role TEXT;
        is_admin_action BOOLEAN := FALSE;
    BEGIN
        SELECT raw_user_meta_data->>'role' INTO caller_role
        FROM auth.users
        WHERE auth.users.id = auth.uid();
        
        IF caller_role = 'admin' THEN
            is_admin_action := TRUE;
        END IF;
        
        INSERT INTO admin_audit_log (
            admin_user_id,
            admin_email,
            target_user_id,
            target_user_email,
            action_type,
            description,
            details
        ) VALUES (
            auth.uid(),
            (SELECT email FROM auth.users WHERE id = auth.uid()),
            v_batch_record.card_owner,
            (SELECT email FROM auth.users WHERE id = v_batch_record.card_owner),
            'CARD_GENERATION',
            CASE 
                WHEN is_admin_action THEN 'Admin generated cards for batch: ' || v_batch_record.batch_name
                WHEN v_batch_record.payment_waived THEN 'Cards generated after payment waiver: ' || v_batch_record.batch_name
                ELSE 'Cards generated after payment confirmation: ' || v_batch_record.batch_name
            END,
            jsonb_build_object(
                'batch_id', p_batch_id,
                'card_id', v_batch_record.card_id,
                'batch_name', v_batch_record.batch_name,
                'cards_count', v_batch_record.cards_count,
                'action', 'cards_generated',
                'old_status', jsonb_build_object('cards_generated', false, 'cards_count', 0),
                'new_status', jsonb_build_object(
                    'cards_generated', true,
                    'cards_generated_at', NOW(),
                    'cards_count', v_batch_record.cards_count
                ),
                'is_admin_action', is_admin_action,
                'payment_method', CASE 
                    WHEN v_batch_record.payment_waived THEN 'waived'
                    WHEN v_batch_record.payment_completed THEN 'stripe'
                    ELSE 'unknown'
                END
            )
        );
    END;
    
    RETURN p_batch_id;
END;
$$; 

-- File: 05_payment_management_client.sql
-- -----------------------------------------------------------------
DROP FUNCTION IF EXISTS get_batch_payment_info CASCADE;

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
        pr.requested_at,
        pr.updated_at
    FROM print_requests pr
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

    -- Log the withdrawal in audit table for admin visibility
    INSERT INTO admin_audit_log (
        admin_user_id,
        admin_email,
        target_user_id,
        target_user_email,
        action_type,
        description,
        details
    ) VALUES (
        auth.uid(), -- The card issuer is performing this action
        (SELECT email FROM auth.users WHERE id = auth.uid()),
        auth.uid(), -- They are the target user as well
        (SELECT email FROM auth.users WHERE id = auth.uid()),
        'PRINT_REQUEST_WITHDRAWAL',
        'Print request withdrawn by card issuer for ' || v_card_name || ' - ' || v_batch_name || COALESCE(': ' || p_withdrawal_reason, ''),
        jsonb_build_object(
            'request_id', p_request_id,
            'batch_id', v_batch_id,
            'card_name', v_card_name,
            'batch_name', v_batch_name,
            'old_status', 'SUBMITTED',
            'new_status', 'CANCELLED',
            'self_withdrawal', true,
            'withdrawal_reason', p_withdrawal_reason
        )
    );
    
    RETURN FOUND;
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
CREATE OR REPLACE FUNCTION get_public_card_content(p_issue_card_id UUID)
RETURNS TABLE (
    card_name TEXT,
    card_description TEXT,
    card_image_url TEXT,
    card_conversation_ai_enabled BOOLEAN,
    card_ai_prompt TEXT,
    content_item_id UUID,
    content_item_parent_id UUID,
    content_item_name TEXT,
    content_item_content TEXT,
    content_item_image_url TEXT,
    content_item_ai_metadata TEXT,
    content_item_sort_order INTEGER,
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
        UPDATE issue_cards
        SET 
            active = true,
            active_at = NOW(),
            activated_by = auth.uid() -- Set to current user ID if authenticated, NULL if not
        WHERE id = p_issue_card_id AND active = false;
        
        v_is_card_active := TRUE; -- Mark as active for current request
    END IF;

    RETURN QUERY
    SELECT 
        c.name AS card_name,
        c.description AS card_description,
        c.image_url AS card_image_url,
        c.conversation_ai_enabled AS card_conversation_ai_enabled,
        c.ai_prompt AS card_ai_prompt,
        ci.id AS content_item_id,
        ci.parent_id AS content_item_parent_id,
        ci.name AS content_item_name,
        ci.content AS content_item_content,
        ci.image_url AS content_item_image_url,
        ci.ai_metadata AS content_item_ai_metadata,
        ci.sort_order AS content_item_sort_order,
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
BEGIN
    -- Check if the user owns the card
    SELECT user_id INTO v_user_id FROM cards WHERE id = p_card_id;
    
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Card not found.';
    END IF;
    
    IF v_user_id != auth.uid() THEN
        RAISE EXCEPTION 'Not authorized to preview this card.';
    END IF;
    
    -- Return preview access with special preview mode flag
    RETURN QUERY
    SELECT 
        TRUE as preview_mode,
        p_card_id as card_id;
END;
$$;

-- Get card content for preview mode (card owner only)
CREATE OR REPLACE FUNCTION get_card_preview_content(p_card_id UUID)
RETURNS TABLE (
    card_name TEXT,
    card_description TEXT,
    card_image_url TEXT,
    card_conversation_ai_enabled BOOLEAN,
    card_ai_prompt TEXT,
    content_item_id UUID,
    content_item_parent_id UUID,
    content_item_name TEXT,
    content_item_content TEXT,
    content_item_image_url TEXT,
    content_item_ai_metadata TEXT,
    content_item_sort_order INTEGER,
    is_preview BOOLEAN
) LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_user_id UUID;
    v_caller_id UUID;
BEGIN
    -- Get the caller's user ID
    v_caller_id := auth.uid();
    
    -- Verify the user is authenticated
    IF v_caller_id IS NULL THEN
        RAISE EXCEPTION 'Authentication required for card preview.';
    END IF;
    
    -- Check if the user owns the card
    SELECT user_id INTO v_user_id FROM cards WHERE id = p_card_id;
    
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Card not found.';
    END IF;
    
    IF v_user_id != v_caller_id THEN
        RAISE EXCEPTION 'Not authorized to preview this card.';
    END IF;
    
    -- Return card content directly (no issued card needed)
    RETURN QUERY
    SELECT 
        c.name AS card_name,
        c.description AS card_description,
        c.image_url AS card_image_url,
        c.conversation_ai_enabled AS card_conversation_ai_enabled,
        c.ai_prompt AS card_ai_prompt,
        ci.id AS content_item_id,
        ci.parent_id AS content_item_parent_id,
        ci.name AS content_item_name,
        ci.content AS content_item_content,
        ci.image_url AS content_item_image_url,
        ci.ai_metadata AS content_item_ai_metadata,
        ci.sort_order AS content_item_sort_order,
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

-- File: 08_user_profiles.sql
-- -----------------------------------------------------------------
DROP FUNCTION IF EXISTS get_user_profile CASCADE;
DROP FUNCTION IF EXISTS create_or_update_basic_profile CASCADE;
DROP FUNCTION IF EXISTS submit_verification CASCADE;
DROP FUNCTION IF EXISTS review_verification CASCADE;
DROP FUNCTION IF EXISTS withdraw_verification CASCADE;

-- =================================================================
-- USER PROFILE FUNCTIONS
-- Functions for user profile management and verification
-- =================================================================

-- Get the profile for the currently authenticated user
CREATE OR REPLACE FUNCTION public.get_user_profile()
RETURNS TABLE (
    user_id UUID,
    public_name TEXT,
    bio TEXT,
    company_name TEXT,
    full_name TEXT,
    verification_status "ProfileStatus",
    supporting_documents TEXT[],
    verified_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ
)
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
    RETURN QUERY
    SELECT 
        up.user_id,
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
    WHERE up.user_id = auth.uid();
END;
$$;

-- Create or Update basic user profile (no verification)
CREATE OR REPLACE FUNCTION public.create_or_update_basic_profile(
    p_public_name TEXT,
    p_bio TEXT,
    p_company_name TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_user_id UUID := auth.uid();
BEGIN
    INSERT INTO public.user_profiles (user_id, public_name, bio, company_name)
    VALUES (v_user_id, p_public_name, p_bio, p_company_name)
    ON CONFLICT (user_id) DO UPDATE 
    SET 
        public_name = EXCLUDED.public_name,
        bio = EXCLUDED.bio,
        company_name = EXCLUDED.company_name,
        updated_at = NOW();
    
    RETURN v_user_id;
END;
$$;

-- Submit verification application
CREATE OR REPLACE FUNCTION public.submit_verification(
    p_full_name TEXT,
    p_supporting_documents TEXT[]
)
RETURNS UUID
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_user_id UUID := auth.uid();
BEGIN
    -- Update the profile with verification info
    UPDATE public.user_profiles 
    SET 
        full_name = p_full_name,
        supporting_documents = p_supporting_documents,
        verification_status = 'PENDING_REVIEW',
        updated_at = NOW()
    WHERE user_id = v_user_id;
    
    -- If no profile exists yet, create one (shouldn't happen in normal flow)
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Profile must be created before submitting verification';
    END IF;
    
    RETURN v_user_id;
END;
$$;

-- (Admin) Function to review a verification
CREATE OR REPLACE FUNCTION public.review_verification(
    p_target_user_id UUID,
    p_new_status "ProfileStatus",
    p_admin_feedback TEXT
)
RETURNS BOOLEAN
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    caller_role TEXT;
BEGIN
    -- Check if the caller is an admin
    SELECT raw_user_meta_data->>'role' INTO caller_role
    FROM auth.users
    WHERE id = auth.uid();

    IF caller_role != 'admin' THEN
        RAISE EXCEPTION 'Only admins can review verifications.';
    END IF;

    -- Ensure status is only set to APPROVED or REJECTED
    IF p_new_status NOT IN ('APPROVED', 'REJECTED') THEN
        RAISE EXCEPTION 'Review status must be APPROVED or REJECTED.';
    END IF;

    UPDATE public.user_profiles
    SET 
        verification_status = p_new_status,
        verified_at = CASE WHEN p_new_status = 'APPROVED' THEN NOW() ELSE NULL END,
        updated_at = NOW()
    WHERE user_id = p_target_user_id;

    -- Create feedback entry if admin provided feedback
    IF p_admin_feedback IS NOT NULL AND LENGTH(TRIM(p_admin_feedback)) > 0 THEN
        DECLARE
            v_admin_email VARCHAR(255);
        BEGIN
            SELECT email INTO v_admin_email FROM auth.users WHERE id = auth.uid();
            
            INSERT INTO verification_feedbacks (
                user_id,
                admin_user_id,
                admin_email,
                message
            ) VALUES (
                p_target_user_id,
                auth.uid(),
                v_admin_email,
                p_admin_feedback
            );
        END;
    END IF;

    -- Log using the centralized audit function (emails handled automatically)
    PERFORM log_admin_action(
        auth.uid(),
        'VERIFICATION_REVIEW',
        CASE 
            WHEN p_new_status = 'APPROVED' THEN 'Verification approved'
            WHEN p_new_status = 'REJECTED' THEN 'Verification rejected'
            ELSE 'Verification reviewed'
        END || CASE WHEN p_admin_feedback IS NOT NULL THEN ': ' || p_admin_feedback ELSE '' END,
        p_target_user_id,
        jsonb_build_object(
            'verification_status', p_new_status,
            'review_type', p_new_status::TEXT,
            'has_feedback', (p_admin_feedback IS NOT NULL AND LENGTH(TRIM(p_admin_feedback)) > 0)
        )
    );
    
    RETURN FOUND;
END;
$$;

-- (User) Function to withdraw verification submission
CREATE OR REPLACE FUNCTION public.withdraw_verification()
RETURNS BOOLEAN
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_current_status "ProfileStatus";
BEGIN
    -- Get current verification status
    SELECT verification_status INTO v_current_status
    FROM public.user_profiles
    WHERE user_id = v_user_id;
    
    -- Only allow withdrawal if status is PENDING_REVIEW
    IF v_current_status != 'PENDING_REVIEW' THEN
        RAISE EXCEPTION 'Verification can only be withdrawn when status is PENDING_REVIEW. Current status: %', v_current_status;
    END IF;

    -- Reset verification status and clear verification data
    UPDATE public.user_profiles
    SET 
        verification_status = 'NOT_SUBMITTED',
        full_name = NULL,
        supporting_documents = NULL,
        verified_at = NULL,
        updated_at = NOW()
    WHERE user_id = v_user_id;
    
    RETURN FOUND;
END;
$$; 

-- File: 09_user_analytics.sql
-- -----------------------------------------------------------------
DROP FUNCTION IF EXISTS get_user_all_issued_cards CASCADE;
DROP FUNCTION IF EXISTS get_user_issuance_stats CASCADE;
DROP FUNCTION IF EXISTS get_user_all_card_batches CASCADE;
DROP FUNCTION IF EXISTS get_user_recent_activity CASCADE;

-- =================================================================
-- USER-LEVEL ANALYTICS FUNCTIONS
-- Functions for user analytics and statistics across all cards
-- =================================================================

-- Get all issued cards for the current user across all their card designs
CREATE OR REPLACE FUNCTION get_user_all_issued_cards()
RETURNS TABLE (
    id UUID,
    card_id UUID,
    card_name TEXT,
    card_image_url TEXT,
    active BOOLEAN,
    issue_at TIMESTAMPTZ,
    active_at TIMESTAMPTZ,
    activated_by UUID,
    batch_id UUID,
    batch_name TEXT,
    batch_number INTEGER,
    batch_is_disabled BOOLEAN
) LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ic.id,
        c.id as card_id,
        c.name as card_name,
        c.image_url as card_image_url,
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
    WHERE c.user_id = auth.uid()
    ORDER BY ic.issue_at DESC;
END;
$$;

-- Get aggregated statistics for all cards of the current user
CREATE OR REPLACE FUNCTION get_user_issuance_stats()
RETURNS TABLE (
    total_issued BIGINT,
    total_activated BIGINT,
    activation_rate NUMERIC,
    total_batches BIGINT,
    total_cards BIGINT,
    pending_cards BIGINT,
    disabled_batches BIGINT,
    active_print_requests BIGINT
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
        COUNT(DISTINCT cb.id) as total_batches,
        COUNT(DISTINCT c.id) as total_cards,
        COUNT(ic.id) FILTER (WHERE ic.active = false) as pending_cards,
        COUNT(DISTINCT cb.id) FILTER (WHERE cb.is_disabled = true) as disabled_batches,
        COUNT(DISTINCT pr.id) FILTER (WHERE pr.status NOT IN ('COMPLETED', 'CANCELLED')) as active_print_requests
    FROM cards c
    LEFT JOIN card_batches cb ON c.id = cb.card_id
    LEFT JOIN issue_cards ic ON cb.id = ic.batch_id
    LEFT JOIN print_requests pr ON cb.id = pr.batch_id
    WHERE c.user_id = auth.uid();
END;
$$;

-- Get all card batches for the current user across all their card designs
CREATE OR REPLACE FUNCTION get_user_all_card_batches()
RETURNS TABLE (
    id UUID,
    card_id UUID,
    card_name TEXT,
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
BEGIN
    RETURN QUERY
    SELECT 
        cb.id,
        cb.card_id,
        c.name as card_name,
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
    WHERE c.user_id = auth.uid()
    GROUP BY cb.id, cb.card_id, c.name, cb.batch_name, cb.batch_number, cb.cards_count, cb.is_disabled, 
             cb.payment_required, cb.payment_completed, cb.payment_amount_cents, cb.payment_completed_at,
             cb.payment_waived, cb.payment_waived_by, cb.payment_waived_at, cb.payment_waiver_reason,
             cb.cards_generated, cb.cards_generated_at, cb.created_at, cb.updated_at
    ORDER BY cb.created_at DESC;
END;
$$;

-- Get recent issuance activity across all cards
CREATE OR REPLACE FUNCTION get_user_recent_activity(p_limit INTEGER DEFAULT 50)
RETURNS TABLE (
    activity_type TEXT,
    activity_date TIMESTAMPTZ,
    card_name TEXT,
    batch_name TEXT,
    description TEXT,
    count INTEGER
) LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
    RETURN QUERY
    (
        -- Recent batch creations
        SELECT 
            'batch_created'::TEXT as activity_type,
            cb.created_at as activity_date,
            c.name as card_name,
            cb.batch_name,
            'Batch created with ' || cb.cards_count || ' cards' as description,
            cb.cards_count as count
        FROM card_batches cb
        JOIN cards c ON cb.card_id = c.id
        WHERE c.user_id = auth.uid()
        
        UNION ALL
        
        -- Recent card activations
        SELECT 
            'card_activated'::TEXT as activity_type,
            ic.active_at as activity_date,
            c.name as card_name,
            cb.batch_name,
            'Card activated' as description,
            1 as count
        FROM issue_cards ic
        JOIN card_batches cb ON ic.batch_id = cb.id
        JOIN cards c ON ic.card_id = c.id
        WHERE c.user_id = auth.uid() AND ic.active_at IS NOT NULL
        
        UNION ALL
        
        -- Recent print requests
        SELECT 
            'print_requested'::TEXT as activity_type,
            pr.requested_at as activity_date,
            c.name as card_name,
            cb.batch_name,
            'Print request submitted' as description,
            cb.cards_count as count
        FROM print_requests pr
        JOIN card_batches cb ON pr.batch_id = cb.id
        JOIN cards c ON cb.card_id = c.id
        WHERE c.user_id = auth.uid()
    )
    ORDER BY activity_date DESC
    LIMIT p_limit;
END;
$$; 

-- File: 11_admin_functions.sql
-- -----------------------------------------------------------------
DROP FUNCTION IF EXISTS admin_waive_batch_payment CASCADE;
DROP FUNCTION IF EXISTS log_admin_action CASCADE;
DROP FUNCTION IF EXISTS get_admin_audit_logs CASCADE;
DROP FUNCTION IF EXISTS create_admin_feedback CASCADE;
DROP FUNCTION IF EXISTS get_admin_feedback_history CASCADE;
DROP FUNCTION IF EXISTS admin_get_system_stats_enhanced CASCADE;
DROP FUNCTION IF EXISTS admin_get_all_print_requests CASCADE;
DROP FUNCTION IF EXISTS admin_update_print_request_status CASCADE;
DROP FUNCTION IF EXISTS admin_get_pending_verifications CASCADE;
DROP FUNCTION IF EXISTS get_recent_admin_activity CASCADE;
DROP FUNCTION IF EXISTS get_admin_audit_logs_count CASCADE;
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

-- =================================================================
-- ADMIN FUNCTIONS
-- Functions for admin-only operations and system management
-- =================================================================

-- (Admin) Waive payment for a batch and generate cards
CREATE OR REPLACE FUNCTION admin_waive_batch_payment(
    p_batch_id UUID,
    p_waiver_reason TEXT
) RETURNS UUID LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_batch_record RECORD;
    caller_role TEXT;
BEGIN
    -- Check if the caller is an admin
    SELECT raw_user_meta_data->>'role' INTO caller_role
    FROM auth.users
    WHERE id = auth.uid();

    IF caller_role != 'admin' THEN
        RAISE EXCEPTION 'Only admins can waive batch payments.';
    END IF;

    -- Get batch information
    SELECT * INTO v_batch_record
    FROM card_batches
    WHERE id = p_batch_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Batch not found.';
    END IF;
    
    -- Check if payment can be waived
    IF v_batch_record.payment_completed = TRUE THEN
        RAISE EXCEPTION 'Cannot waive payment for a batch that has already been paid.';
    END IF;
    
    IF v_batch_record.payment_waived = TRUE THEN
        RAISE EXCEPTION 'Payment has already been waived for this batch.';
    END IF;
    
    -- Update batch to mark payment as waived
    UPDATE card_batches 
    SET 
        payment_waived = TRUE,
        payment_waived_by = auth.uid(),
        payment_waived_at = NOW(),
        payment_waiver_reason = p_waiver_reason,
        updated_at = NOW()
    WHERE id = p_batch_id;
    
    -- Generate cards using the new function
    PERFORM generate_batch_cards(p_batch_id);
    
    -- Log the waiver
    PERFORM log_admin_action(
        auth.uid(),
        'PAYMENT_WAIVER',
        'Payment waived for batch ' || v_batch_record.batch_name || ' (' || v_batch_record.cards_count || ' cards): ' || p_waiver_reason,
        v_batch_record.created_by,
        jsonb_build_object(
            'batch_id', p_batch_id,
            'batch_name', v_batch_record.batch_name,
            'cards_count', v_batch_record.cards_count,
            'waived_amount_cents', v_batch_record.cards_count * 200
        )
    );
    
    RETURN p_batch_id;
END;
$$;

-- =================================================================
-- SIMPLIFIED AUDIT SYSTEM FUNCTIONS
-- =================================================================

-- Simple audit logging function with direct email lookup
CREATE OR REPLACE FUNCTION log_admin_action(
    p_admin_user_id UUID,
    p_action_type VARCHAR(50),
    p_description TEXT,
    p_target_user_id UUID DEFAULT NULL,
    p_details JSONB DEFAULT NULL
) RETURNS UUID LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_admin_email VARCHAR(255);
    v_target_email VARCHAR(255);
    v_audit_id UUID;
BEGIN
    -- Get admin email
    SELECT email INTO v_admin_email FROM auth.users WHERE id = p_admin_user_id;
    
    -- Get target user email if target user is specified
    IF p_target_user_id IS NOT NULL THEN
        SELECT email INTO v_target_email FROM auth.users WHERE id = p_target_user_id;
    END IF;
    
    INSERT INTO admin_audit_log (
        admin_user_id,
        admin_email,
        target_user_id,
        target_user_email,
        action_type,
        description,
        details
    ) VALUES (
        p_admin_user_id,
        v_admin_email,
        p_target_user_id,
        v_target_email,
        p_action_type,
        p_description,
        p_details
    )
    RETURNING id INTO v_audit_id;
    
    RETURN v_audit_id;
END;
$$;

-- Simple audit log retrieval function
CREATE OR REPLACE FUNCTION get_admin_audit_logs(
    p_action_type TEXT DEFAULT NULL,
    p_admin_user_id UUID DEFAULT NULL,
    p_target_user_id UUID DEFAULT NULL,
    p_start_date TIMESTAMPTZ DEFAULT NULL,
    p_end_date TIMESTAMPTZ DEFAULT NULL,
    p_limit INTEGER DEFAULT 50,
    p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
    id UUID,
    admin_user_id UUID,
    admin_email VARCHAR(255),
    target_user_id UUID,
    target_user_email VARCHAR(255),
    action_type VARCHAR(50),
    description TEXT,
    details JSONB,
    created_at TIMESTAMPTZ
) LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    caller_role TEXT;
    v_action_types TEXT[];
BEGIN
    -- Check if the caller is an admin
    SELECT raw_user_meta_data->>'role' INTO caller_role
    FROM auth.users
    WHERE auth.users.id = auth.uid();

    IF caller_role != 'admin' THEN
        RAISE EXCEPTION 'Only admins can view audit logs.';
    END IF;

    -- Handle comma-separated action types for compatibility
    IF p_action_type IS NOT NULL THEN
        IF p_action_type LIKE '%,%' THEN
            v_action_types := string_to_array(p_action_type, ',');
        ELSE
            v_action_types := ARRAY[p_action_type];
        END IF;
    END IF;

    RETURN QUERY
    SELECT 
        aal.id,
        aal.admin_user_id,
        aal.admin_email,
        aal.target_user_id,
        aal.target_user_email,
        aal.action_type,
        aal.description,
        aal.details,
        aal.created_at
    FROM admin_audit_log aal
    WHERE 
        (v_action_types IS NULL OR aal.action_type = ANY(v_action_types))
        AND (p_admin_user_id IS NULL OR aal.admin_user_id = p_admin_user_id)
        AND (p_target_user_id IS NULL OR aal.target_user_id = p_target_user_id)
        AND (p_start_date IS NULL OR aal.created_at >= p_start_date)
        AND (p_end_date IS NULL OR aal.created_at <= p_end_date)
    ORDER BY aal.created_at DESC
    LIMIT p_limit
    OFFSET p_offset;
END;
$$;

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
    WHERE id = auth.uid();

    IF caller_role != 'admin' THEN
        RAISE EXCEPTION 'Only admins can create feedback entries.';
    END IF;

    -- Validate entity type
    IF p_entity_type NOT IN ('verification', 'print_request') THEN
        RAISE EXCEPTION 'Invalid entity type. Must be verification or print_request.';
    END IF;

    -- Get admin email
    SELECT email INTO v_admin_email FROM auth.users WHERE id = auth.uid();

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
    WHERE id = auth.uid();

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
    total_verified_users BIGINT,
    total_cards BIGINT,
    total_batches BIGINT,
    total_issued_cards BIGINT,
    total_activated_cards BIGINT,
    pending_verifications BIGINT,
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
    -- NEW AUDIT METRICS
    total_audit_entries BIGINT,
    critical_actions_today BIGINT,
    high_severity_actions_week BIGINT,
    unique_admin_users_month BIGINT,
    recent_feedback_count BIGINT,
    total_feedback_count BIGINT
) LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    caller_role TEXT;
BEGIN
    -- Check if the caller is an admin
    SELECT raw_user_meta_data->>'role' INTO caller_role
    FROM auth.users
    WHERE id = auth.uid();

    IF caller_role != 'admin' THEN
        RAISE EXCEPTION 'Only admins can view system statistics.';
    END IF;

    RETURN QUERY
    SELECT 
        -- Existing metrics
        (SELECT COUNT(*) FROM auth.users) as total_users,
        (SELECT COUNT(*) FROM user_profiles WHERE verification_status = 'APPROVED') as total_verified_users,
        (SELECT COUNT(*) FROM cards) as total_cards,
        (SELECT COUNT(*) FROM card_batches) as total_batches,
        (SELECT COUNT(*) FROM issue_cards) as total_issued_cards,
        (SELECT COUNT(*) FROM issue_cards WHERE active = true) as total_activated_cards,
        (SELECT COUNT(*) FROM user_profiles WHERE verification_status = 'PENDING_REVIEW') as pending_verifications,
        (SELECT COUNT(*) FROM card_batches WHERE payment_required = true AND payment_completed = false AND payment_waived = false) as pending_payment_batches,
        (SELECT COUNT(*) FROM card_batches WHERE payment_completed = true) as paid_batches,
        (SELECT COUNT(*) FROM card_batches WHERE payment_waived = true) as waived_batches,
        (SELECT COUNT(*) FROM print_requests WHERE status = 'SUBMITTED') as print_requests_submitted,
        (SELECT COUNT(*) FROM print_requests WHERE status = 'PROCESSING') as print_requests_processing,
        (SELECT COUNT(*) FROM print_requests WHERE status = 'SHIPPING') as print_requests_shipping,
        (SELECT COALESCE(SUM(amount_cents), 0) FROM batch_payments WHERE payment_status = 'succeeded' AND created_at >= CURRENT_DATE) as daily_revenue_cents,
        (SELECT COALESCE(SUM(amount_cents), 0) FROM batch_payments WHERE payment_status = 'succeeded' AND created_at >= CURRENT_DATE - INTERVAL '7 days') as weekly_revenue_cents,
        (SELECT COALESCE(SUM(amount_cents), 0) FROM batch_payments WHERE payment_status = 'succeeded' AND created_at >= CURRENT_DATE - INTERVAL '30 days') as monthly_revenue_cents,
        (SELECT COALESCE(SUM(amount_cents), 0) FROM batch_payments WHERE payment_status = 'succeeded') as total_revenue_cents,
        (SELECT COUNT(*) FROM auth.users WHERE created_at >= CURRENT_DATE) as daily_new_users,
        (SELECT COUNT(*) FROM auth.users WHERE created_at >= CURRENT_DATE - INTERVAL '7 days') as weekly_new_users,
        (SELECT COUNT(*) FROM auth.users WHERE created_at >= CURRENT_DATE - INTERVAL '30 days') as monthly_new_users,
        (SELECT COUNT(*) FROM cards WHERE created_at >= CURRENT_DATE) as daily_new_cards,
        (SELECT COUNT(*) FROM cards WHERE created_at >= CURRENT_DATE - INTERVAL '7 days') as weekly_new_cards,
        (SELECT COUNT(*) FROM cards WHERE created_at >= CURRENT_DATE - INTERVAL '30 days') as monthly_new_cards,
        (SELECT COUNT(*) FROM issue_cards WHERE created_at >= CURRENT_DATE) as daily_issued_cards,
        (SELECT COUNT(*) FROM issue_cards WHERE created_at >= CURRENT_DATE - INTERVAL '7 days') as weekly_issued_cards,
        (SELECT COUNT(*) FROM issue_cards WHERE created_at >= CURRENT_DATE - INTERVAL '30 days') as monthly_issued_cards,
        -- SIMPLIFIED AUDIT METRICS
        (SELECT COUNT(*) FROM admin_audit_log) as total_audit_entries,
        (SELECT COUNT(*) FROM admin_audit_log WHERE action_type = 'PAYMENT_WAIVER' AND created_at >= CURRENT_DATE) as payment_waivers_today,
        (SELECT COUNT(*) FROM admin_audit_log WHERE action_type = 'ROLE_CHANGE' AND created_at >= CURRENT_DATE - INTERVAL '7 days') as role_changes_week,
        (SELECT COUNT(DISTINCT admin_user_id) FROM admin_audit_log WHERE created_at >= CURRENT_DATE - INTERVAL '30 days') as unique_admin_users_month,
        (SELECT COUNT(*) FROM verification_feedbacks WHERE created_at >= CURRENT_DATE - INTERVAL '7 days') + 
         (SELECT COUNT(*) FROM print_request_feedbacks WHERE created_at >= CURRENT_DATE - INTERVAL '7 days') as recent_feedback_count,
        (SELECT COUNT(*) FROM verification_feedbacks) + (SELECT COUNT(*) FROM print_request_feedbacks) as total_feedback_count;
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
    WHERE id = auth.uid();

    IF caller_role != 'admin' THEN
        RAISE EXCEPTION 'Only admins can view all print requests.';
    END IF;

    RETURN QUERY
    SELECT 
        pr.id AS request_id,
        pr.batch_id AS batch_id,
        pr.user_id AS user_id,
        au.email::text AS user_email,
        up.public_name AS user_public_name,
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
    LEFT JOIN user_profiles up ON pr.user_id = up.user_id
    WHERE 
        (p_status IS NULL OR pr.status = p_status)
        AND (p_search_query IS NULL OR (
            au.email ILIKE '%' || p_search_query || '%' OR
            up.public_name ILIKE '%' || p_search_query || '%' OR
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
    WHERE id = auth.uid();

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
            SELECT email INTO v_admin_email FROM auth.users WHERE id = auth.uid();
            
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

    -- Log the status change
    PERFORM log_admin_action(
        auth.uid(),
        'PRINT_REQUEST_UPDATE',
        'Print request status changed from ' || v_request_record.status || ' to ' || p_new_status || ' for ' || v_request_record.card_name,
        v_request_record.user_id,
        jsonb_build_object(
            'request_id', p_request_id,
            'old_status', v_request_record.status,
            'new_status', p_new_status,
            'card_name', v_request_record.card_name,
            'batch_name', v_request_record.batch_name
        )
    );
    
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
    WHERE id = auth.uid();

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



-- (Admin) Get recent admin activity
CREATE OR REPLACE FUNCTION get_recent_admin_activity(
    p_limit INTEGER DEFAULT 50
)
RETURNS TABLE (
    activity_type TEXT,
    activity_date TIMESTAMPTZ,
    user_email VARCHAR(255),
    user_public_name TEXT,
    description TEXT,
    details JSONB
) LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    caller_role TEXT;
BEGIN
    -- Check if the caller is an admin
    SELECT raw_user_meta_data->>'role' INTO caller_role
    FROM auth.users
    WHERE auth.users.id = auth.uid();

    IF caller_role != 'admin' THEN
        RAISE EXCEPTION 'Only admins can view recent activity.';
    END IF;

    RETURN QUERY
    SELECT 
        aal.action_type AS activity_type,
        aal.created_at AS activity_date,
        aal.target_user_email AS user_email,
        up.public_name AS user_public_name,
        aal.description AS description,
        aal.details AS details
    FROM admin_audit_log aal
    LEFT JOIN user_profiles up ON aal.target_user_id = up.user_id
    ORDER BY aal.created_at DESC
    LIMIT p_limit;
END;
$$;

-- (Admin) Get count of admin audit logs with filtering
CREATE OR REPLACE FUNCTION get_admin_audit_logs_count(
    p_action_type TEXT DEFAULT NULL,
    p_admin_user_id UUID DEFAULT NULL,
    p_target_user_id UUID DEFAULT NULL,
    p_start_date TIMESTAMPTZ DEFAULT NULL,
    p_end_date TIMESTAMPTZ DEFAULT NULL
)
RETURNS INTEGER LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    caller_role TEXT;
    v_count INTEGER;
    v_action_types TEXT[];
BEGIN
    -- Check if caller is admin
    SELECT raw_user_meta_data->>'role' INTO caller_role
    FROM auth.users
    WHERE auth.users.id = auth.uid();

    IF caller_role != 'admin' THEN
        RAISE EXCEPTION 'Only admins can view audit logs.';
    END IF;

    -- Convert comma-separated string to array for compatibility
    IF p_action_type IS NOT NULL THEN
        IF p_action_type LIKE '%,%' THEN
            v_action_types := string_to_array(p_action_type, ',');
        ELSE
            v_action_types := ARRAY[p_action_type];
        END IF;
    END IF;

    SELECT COUNT(*)::INTEGER INTO v_count
    FROM admin_audit_log aal
    WHERE (v_action_types IS NULL OR aal.action_type = ANY(v_action_types))
    AND (p_admin_user_id IS NULL OR aal.admin_user_id = p_admin_user_id)
    AND (p_target_user_id IS NULL OR aal.target_user_id = p_target_user_id)
    AND (p_start_date IS NULL OR aal.created_at >= p_start_date)
    AND (p_end_date IS NULL OR aal.created_at <= p_end_date);

    RETURN v_count;
END;
$$;

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
    WHERE id = auth.uid();

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
    PERFORM log_admin_action(
        auth.uid(),
        'ROLE_CHANGE',
        'User role changed from ' || current_role || ' to ' || p_new_role || ' for ' || target_user_email || ': ' || p_reason,
        p_target_user_id,
        jsonb_build_object(
            'target_email', target_user_email,
            'from_role', current_role,
            'to_role', p_new_role,
            'is_admin_promotion', (p_new_role = 'admin'),
            'is_admin_demotion', (current_role = 'admin' AND p_new_role != 'admin')
        )
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
    WHERE id = auth.uid();

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
    WHERE id = auth.uid();

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
    WHERE id = auth.uid();

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

    -- Log the verification reset
    PERFORM log_admin_action(
        auth.uid(),
        'VERIFICATION_RESET',
        'Verification status reset for user ' || v_user_email,
        p_user_id,
        jsonb_build_object(
            'target_email', v_user_email,
            'reset_reason', 'admin_initiated'
        )
    );
    
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
    WHERE id = auth.uid();

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
            SELECT email INTO v_admin_email FROM auth.users WHERE id = auth.uid();
            
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
    PERFORM log_admin_action(
        auth.uid(),
        'MANUAL_VERIFICATION',
        'Manual verification approved for user ' || v_user_email || ': ' || p_reason,
        p_user_id,
        jsonb_build_object(
            'target_email', v_user_email,
            'approval_method', 'admin_override',
            'previous_status', COALESCE(v_current_status, 'NOT_SUBMITTED')
        )
    );
    
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
    WHERE id = auth.uid();

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
-- SERVER-SIDE PROCEDURES
-- =================================================================

-- File: 05_payment_management.sql
-- -----------------------------------------------------------------
DROP FUNCTION IF EXISTS create_batch_checkout_payment CASCADE;
DROP FUNCTION IF EXISTS get_batch_for_checkout CASCADE;
DROP FUNCTION IF EXISTS get_existing_batch_payment CASCADE;
DROP FUNCTION IF EXISTS confirm_batch_payment_by_session CASCADE;

-- =================================================================
-- PAYMENT MANAGEMENT FUNCTIONS (SERVER-SIDE)
-- Functions called by Edge Functions for Stripe Checkout processing
-- =================================================================

-- Create Stripe checkout session payment record
CREATE OR REPLACE FUNCTION create_batch_checkout_payment(
    p_batch_id UUID,
    p_stripe_payment_intent_id TEXT,
    p_stripe_checkout_session_id TEXT,
    p_amount_cents INTEGER,
    p_metadata JSONB DEFAULT '{}'::jsonb
) RETURNS UUID LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_batch_owner_id UUID;
    v_batch_payment_amount INTEGER;
    v_payment_id UUID;
BEGIN
    -- Verify batch ownership and get expected amount
    SELECT cb.created_by, cb.payment_amount_cents 
    INTO v_batch_owner_id, v_batch_payment_amount
    FROM card_batches cb 
    WHERE cb.id = p_batch_id;
    
    IF v_batch_owner_id IS NULL THEN
        RAISE EXCEPTION 'Batch not found.';
    END IF;
    
    IF v_batch_owner_id != auth.uid() THEN
        RAISE EXCEPTION 'Not authorized to create payment for this batch.';
    END IF;
    
    -- Verify amount matches expected
    IF p_amount_cents != v_batch_payment_amount THEN
        RAISE EXCEPTION 'Payment amount mismatch. Expected: %, Provided: %', v_batch_payment_amount, p_amount_cents;
    END IF;
    
    -- Check if payment already exists for this batch
    IF EXISTS (SELECT 1 FROM batch_payments WHERE batch_id = p_batch_id) THEN
        RAISE EXCEPTION 'Payment already exists for this batch.';
    END IF;
    
    -- Validate required checkout session ID
    IF p_stripe_checkout_session_id IS NULL THEN
        RAISE EXCEPTION 'Checkout session ID is required.';
    END IF;
    
    -- Create payment record for checkout session
    INSERT INTO batch_payments (
        batch_id,
        user_id,
        stripe_payment_intent_id,
        stripe_checkout_session_id,
        amount_cents,
        currency,
        payment_status,
        metadata
    ) VALUES (
        p_batch_id,
        auth.uid(),
        p_stripe_payment_intent_id, -- Can be null in test mode
        p_stripe_checkout_session_id,
        p_amount_cents,
        'usd',
        'pending',
        p_metadata
    ) RETURNING id INTO v_payment_id;
    
    -- Log payment creation in audit table
    INSERT INTO admin_audit_log (
        admin_user_id,
        admin_email,
        target_user_id,
        target_user_email,
        action_type,
        description,
        details
    ) VALUES (
        auth.uid(),
        (SELECT email FROM auth.users WHERE id = auth.uid()),
        auth.uid(),
        (SELECT email FROM auth.users WHERE id = auth.uid()),
        'PAYMENT_CREATION',
        'Stripe checkout session payment created',
        jsonb_build_object(
            'payment_id', v_payment_id,
            'payment_status', 'pending',
            'amount_cents', p_amount_cents,
            'currency', 'usd',
            'action', 'payment_session_created',
            'stripe_checkout_session_id', p_stripe_checkout_session_id,
            'stripe_payment_intent_id', p_stripe_payment_intent_id,
            'batch_id', p_batch_id,
            'metadata', p_metadata
        )
    );
    
    RETURN v_payment_id;
END;
$$;


-- Get batch information for checkout session
CREATE OR REPLACE FUNCTION get_batch_for_checkout(p_batch_id UUID)
RETURNS TABLE (
    id UUID,
    card_id UUID,
    created_by UUID,
    batch_name TEXT,
    card_name TEXT,
    card_description TEXT,
    card_image_url TEXT
) LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
    RETURN QUERY
    SELECT 
        cb.id,
        cb.card_id,
        cb.created_by,
        cb.batch_name,
        c.name as card_name,
        c.description as card_description,
        c.image_url as card_image_url
    FROM card_batches cb
    JOIN cards c ON cb.card_id = c.id
    WHERE cb.id = p_batch_id 
    AND cb.created_by = auth.uid();
END;
$$;

-- Check existing payment for batch
CREATE OR REPLACE FUNCTION get_existing_batch_payment(p_batch_id UUID)
RETURNS TABLE (
    id UUID,
    payment_status TEXT,
    stripe_checkout_session_id TEXT,
    amount_cents INTEGER,
    created_at TIMESTAMPTZ
) LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
    RETURN QUERY
    SELECT 
        bp.id,
        bp.payment_status,
        bp.stripe_checkout_session_id,
        bp.amount_cents,
        bp.created_at
    FROM batch_payments bp
    WHERE bp.batch_id = p_batch_id 
    AND bp.user_id = auth.uid()
    ORDER BY bp.created_at DESC
    LIMIT 1;
END;
$$;

-- Confirm batch payment by checkout session ID (alternative method)
CREATE OR REPLACE FUNCTION confirm_batch_payment_by_session(
    p_stripe_checkout_session_id TEXT,
    p_payment_method TEXT DEFAULT NULL
) RETURNS UUID LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_payment_record RECORD;
    v_batch_record RECORD;
BEGIN
    -- Get payment and batch information by checkout session ID
    SELECT bp.*, cb.card_id, cb.cards_count 
    INTO v_payment_record
    FROM batch_payments bp
    JOIN card_batches cb ON bp.batch_id = cb.id
    WHERE bp.stripe_checkout_session_id = p_stripe_checkout_session_id
    AND bp.user_id = auth.uid();
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Payment not found or not authorized.';
    END IF;
    
    -- Check if already confirmed
    IF v_payment_record.payment_status = 'succeeded' THEN
        RAISE EXCEPTION 'Payment already confirmed.';
    END IF;
    
    -- Update payment status
    UPDATE batch_payments 
    SET 
        payment_status = 'succeeded',
        payment_method = p_payment_method,
        updated_at = NOW()
    WHERE stripe_checkout_session_id = p_stripe_checkout_session_id;
    
    -- Update batch payment status
    UPDATE card_batches 
    SET 
        payment_completed = TRUE,
        payment_completed_at = NOW(),
        updated_at = NOW()
    WHERE id = v_payment_record.batch_id;
    
    -- Generate cards using the new function
    PERFORM generate_batch_cards(v_payment_record.batch_id);
    
    -- Log payment confirmation in audit table
    INSERT INTO admin_audit_log (
        admin_user_id,
        admin_email,
        target_user_id,
        target_user_email,
        action_type,
        description,
        details
    ) VALUES (
        auth.uid(),
        (SELECT email FROM auth.users WHERE id = auth.uid()),
        v_payment_record.user_id,
        (SELECT email FROM auth.users WHERE id = v_payment_record.user_id),
        'PAYMENT_CONFIRMATION',
        'Batch payment confirmed via Stripe checkout session',
        jsonb_build_object(
            'old_status', jsonb_build_object(
                'payment_status', v_payment_record.payment_status,
                'payment_completed', false,
                'cards_generated', false
            ),
            'new_status', jsonb_build_object(
                'payment_status', 'succeeded',
                'payment_completed', true,
                'payment_completed_at', NOW(),
                'payment_method', p_payment_method,
                'cards_generated', true
            ),
            'action', 'payment_confirmed',
            'payment_method', p_payment_method,
            'stripe_checkout_session_id', p_stripe_checkout_session_id,
            'batch_id', v_payment_record.batch_id,
            'amount_cents', v_payment_record.amount_cents,
            'currency', v_payment_record.currency,
            'cards_count', v_payment_record.cards_count,
            'automated_card_generation', true
        )
    );
    
    RETURN v_payment_record.batch_id;
END;
$$;

 

