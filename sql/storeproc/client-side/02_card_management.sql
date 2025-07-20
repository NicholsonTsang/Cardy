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
    p_qr_code_position TEXT DEFAULT 'BR',
    p_content_render_mode TEXT DEFAULT 'SINGLE_SERIES_MULTI_ITEMS'
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
        qr_code_position,
        content_render_mode
    ) VALUES (
        auth.uid(),
        p_name,
        p_description,
        p_image_url,
        p_conversation_ai_enabled,
        p_ai_prompt,
        p_qr_code_position::"QRCodePosition",
        p_content_render_mode::"ContentRenderMode"
    )
    RETURNING id INTO v_card_id;
    
    -- Get caller role for audit context
    SELECT raw_user_meta_data->>'role' INTO caller_role
    FROM auth.users
    WHERE id = auth.uid();
    
    -- Log card creation in audit table
    INSERT INTO admin_audit_log (
        admin_user_id,
        target_user_id,
        action_type,
        reason,
        old_values,
        new_values,
        action_details
    ) VALUES (
        auth.uid(),
        auth.uid(),
        'CARD_CREATION',
        'User created new card design',
        jsonb_build_object(
            'card_exists', false
        ),
        jsonb_build_object(
            'card_id', v_card_id,
            'name', p_name,
            'description', p_description,
            'image_url', p_image_url,
            'conversation_ai_enabled', p_conversation_ai_enabled,
            'ai_prompt', p_ai_prompt,
            'qr_code_position', p_qr_code_position,
            'content_render_mode', p_content_render_mode,
            'created_at', NOW()
        ),
        jsonb_build_object(
            'action', 'card_created',
            'card_id', v_card_id,
            'card_name', p_name,
            'is_admin_action', (caller_role = 'admin'),
            'has_ai_features', p_conversation_ai_enabled,
            'has_custom_image', (p_image_url IS NOT NULL),
            'content_mode', p_content_render_mode,
            'qr_position', p_qr_code_position,
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
    content_render_mode TEXT,
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
        c.content_render_mode::TEXT,
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
        target_user_id,
        action_type,
        reason,
        old_values,
        new_values,
        action_details
    ) VALUES (
        auth.uid(),
        v_old_record.user_id,
        'CARD_UPDATE',
        'User updated card design',
        jsonb_build_object(
            'card_id', v_old_record.id,
            'name', v_old_record.name,
            'description', v_old_record.description,
            'image_url', v_old_record.image_url,
            'conversation_ai_enabled', v_old_record.conversation_ai_enabled,
            'ai_prompt', v_old_record.ai_prompt,
            'qr_code_position', v_old_record.qr_code_position,
            'updated_at', v_old_record.updated_at
        ),
        jsonb_build_object(
            'card_id', p_card_id,
            'name', COALESCE(p_name, v_old_record.name),
            'description', COALESCE(p_description, v_old_record.description),
            'image_url', COALESCE(p_image_url, v_old_record.image_url),
            'conversation_ai_enabled', COALESCE(p_conversation_ai_enabled, v_old_record.conversation_ai_enabled),
            'ai_prompt', COALESCE(p_ai_prompt, v_old_record.ai_prompt),
            'qr_code_position', COALESCE(p_qr_code_position, v_old_record.qr_code_position::TEXT),
            'updated_at', NOW()
        ),
        jsonb_build_object(
            'action', 'card_updated',
            'card_id', p_card_id,
            'card_name', COALESCE(p_name, v_old_record.name),
            'is_admin_action', (caller_role = 'admin'),
            'changes_made', v_changes_made,
            'fields_changed', ARRAY(SELECT jsonb_object_keys(v_changes_made)),
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
        c.content_render_mode,
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
        target_user_id,
        action_type,
        reason,
        old_values,
        new_values,
        action_details
    ) VALUES (
        auth.uid(),
        v_card_record.user_id,
        'CARD_DELETION',
        'User deleted card design',
        jsonb_build_object(
            'card_id', v_card_record.id,
            'name', v_card_record.name,
            'description', v_card_record.description,
            'image_url', v_card_record.image_url,
            'conversation_ai_enabled', v_card_record.conversation_ai_enabled,
            'ai_prompt', v_card_record.ai_prompt,
            'qr_code_position', v_card_record.qr_code_position,
            'content_render_mode', v_card_record.content_render_mode,
            'created_at', v_card_record.created_at,
            'updated_at', v_card_record.updated_at,
            'associated_batches', v_batches_count,
            'issued_cards_affected', v_issued_cards_count
        ),
        jsonb_build_object(
            'deleted_at', NOW(),
            'card_exists', false
        ),
        jsonb_build_object(
            'action', 'card_deleted',
            'card_id', p_card_id,
            'card_name', v_card_record.name,
            'is_admin_action', (caller_role = 'admin'),
            'data_impact', CASE 
                WHEN v_issued_cards_count > 0 THEN 'high'
                WHEN v_batches_count > 0 THEN 'medium'
                ELSE 'low'
            END,
            'batches_affected', v_batches_count,
            'issued_cards_affected', v_issued_cards_count,
            'had_ai_features', v_card_record.conversation_ai_enabled,
            'security_impact', 'medium'
        )
    );
    
    RETURN FOUND;
END;
$$; 