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
    image_urls TEXT[],
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
        c.image_urls, 
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
    p_image_urls TEXT[] DEFAULT ARRAY[]::TEXT[],
    p_conversation_ai_enabled BOOLEAN DEFAULT FALSE,
    p_ai_prompt TEXT DEFAULT '',
    p_qr_code_position TEXT DEFAULT 'BR'
) RETURNS UUID LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_card_id UUID;
BEGIN
    INSERT INTO cards (
        user_id,
        name,
        description,
        image_urls,
        conversation_ai_enabled,
        ai_prompt,
        qr_code_position
    ) VALUES (
        auth.uid(),
        p_name,
        p_description,
        p_image_urls,
        p_conversation_ai_enabled,
        p_ai_prompt,
        p_qr_code_position::"QRCodePosition"
    )
    RETURNING id INTO v_card_id;
    
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
    image_urls TEXT[],
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
        c.image_urls, 
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
    p_image_urls TEXT[] DEFAULT NULL,
    p_conversation_ai_enabled BOOLEAN DEFAULT NULL,
    p_ai_prompt TEXT DEFAULT NULL,
    p_qr_code_position TEXT DEFAULT NULL
) RETURNS BOOLEAN LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
    UPDATE cards
    SET 
        name = COALESCE(p_name, name),
        description = COALESCE(p_description, description),
        image_urls = COALESCE(p_image_urls, image_urls),
        conversation_ai_enabled = COALESCE(p_conversation_ai_enabled, conversation_ai_enabled),
        ai_prompt = COALESCE(p_ai_prompt, ai_prompt),
        qr_code_position = COALESCE(p_qr_code_position::"QRCodePosition", qr_code_position),
        updated_at = now()
    WHERE id = p_card_id AND user_id = auth.uid();
    
    RETURN FOUND;
END;
$$;

-- Delete a card (more secure)
CREATE OR REPLACE FUNCTION delete_card(p_card_id UUID)
RETURNS BOOLEAN LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
    DELETE FROM cards WHERE id = p_card_id AND user_id = auth.uid();
    RETURN FOUND;
END;
$$; 