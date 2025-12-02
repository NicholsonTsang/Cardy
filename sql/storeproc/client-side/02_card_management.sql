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
    content_mode TEXT,
    billing_type TEXT,
    max_scans INTEGER,
    current_scans INTEGER,
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
        c.content_mode,
        c.billing_type,
        c.max_scans,
        c.current_scans,
        c.created_at,
        c.updated_at
    FROM cards c
    WHERE c.user_id = auth.uid()
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
    p_ai_instruction TEXT DEFAULT '',
    p_ai_knowledge_base TEXT DEFAULT '',
    p_qr_code_position TEXT DEFAULT 'BR',
    p_original_language VARCHAR(10) DEFAULT 'en',
    p_content_hash TEXT DEFAULT NULL,  -- For import: preserve original hash
    p_translations JSONB DEFAULT NULL,  -- For import: restore translations
    p_content_mode TEXT DEFAULT 'list',  -- Content rendering mode: single, grouped, list, grid, inline
    p_billing_type TEXT DEFAULT 'physical',  -- Billing model: physical or digital
    p_max_scans INTEGER DEFAULT NULL  -- NULL = unlimited (physical), Integer = limit (digital)
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
        original_language,
        content_hash,  -- May be NULL (trigger calculates) or provided (import)
        translations,  -- May be NULL (normal) or provided (import)
        content_mode,
        billing_type,
        max_scans,
        current_scans
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
        p_original_language,
        p_content_hash,  -- Trigger will calculate if NULL
        COALESCE(p_translations, '{}'::JSONB),  -- Default to empty object
        COALESCE(p_content_mode, 'list'),
        COALESCE(p_billing_type, 'physical'),
        p_max_scans,  -- NULL for physical (unlimited), set for digital
        0  -- Start with 0 scans
    )
    RETURNING id INTO v_card_id;
    
    -- Log operation
    IF p_translations IS NOT NULL AND p_translations != '{}'::JSONB THEN
        PERFORM log_operation(format('Imported card with translations: %s', p_name));
    ELSE
        PERFORM log_operation(format('Created %s card: %s', p_billing_type, p_name));
    END IF;
    
    RETURN v_card_id;
END;
$$;
GRANT EXECUTE ON FUNCTION create_card(TEXT, TEXT, TEXT, TEXT, JSONB, BOOLEAN, TEXT, TEXT, TEXT, VARCHAR, TEXT, JSONB, TEXT, TEXT, INTEGER) TO authenticated;

-- Get a card by ID (more secure, relies on RLS policy)
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
    ai_instruction TEXT,
    ai_knowledge_base TEXT,
    translations JSONB,
    original_language VARCHAR(10),
    content_hash TEXT,
    last_content_update TIMESTAMPTZ,
    content_mode TEXT,
    billing_type TEXT,
    max_scans INTEGER,
    current_scans INTEGER,
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
        c.ai_instruction,
        c.ai_knowledge_base,
        c.translations,
        c.original_language,
        c.content_hash,
        c.last_content_update,
        c.content_mode,
        c.billing_type,
        c.max_scans,
        c.current_scans,
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
    p_original_language VARCHAR(10) DEFAULT NULL,
    p_content_mode TEXT DEFAULT NULL,
    p_billing_type TEXT DEFAULT NULL,
    p_max_scans INTEGER DEFAULT NULL
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
        content_mode,
        billing_type,
        max_scans,
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
    
    IF p_content_mode IS NOT NULL AND p_content_mode != v_old_record.content_mode THEN
        v_changes_made := v_changes_made || jsonb_build_object('content_mode', jsonb_build_object('from', v_old_record.content_mode, 'to', p_content_mode));
        has_changes := TRUE;
    END IF;
    
    -- NOTE: billing_type cannot be changed after card creation
    -- Silently ignore any attempt to change billing_type
    -- IF p_billing_type IS NOT NULL AND p_billing_type != v_old_record.billing_type THEN
    --     RAISE EXCEPTION 'Access mode (billing_type) cannot be changed after card creation.';
    -- END IF;
    
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
        ai_instruction = COALESCE(p_ai_instruction, ai_instruction),
        ai_knowledge_base = COALESCE(p_ai_knowledge_base, ai_knowledge_base),
        qr_code_position = COALESCE(p_qr_code_position::"QRCodePosition", qr_code_position),
        original_language = COALESCE(p_original_language, original_language),
        content_mode = COALESCE(p_content_mode, content_mode),
        -- billing_type is immutable - not updated here
        max_scans = CASE WHEN billing_type = 'digital' THEN COALESCE(p_max_scans, max_scans) ELSE NULL END,
        updated_at = now()
    WHERE id = p_card_id AND user_id = auth.uid();
    
    -- Log operation
    PERFORM log_operation(format('Updated card: %s', COALESCE(p_name, v_old_record.name)));
    
    RETURN TRUE;
END;
$$;
GRANT EXECUTE ON FUNCTION update_card(UUID, TEXT, TEXT, TEXT, TEXT, JSONB, BOOLEAN, TEXT, TEXT, TEXT, VARCHAR, TEXT, TEXT, INTEGER) TO authenticated;

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