-- Get all cards for the current user (more secure)
CREATE OR REPLACE FUNCTION get_user_cards()
RETURNS TABLE (
    id UUID,
    name TEXT,
    description TEXT,
    image_urls TEXT[],
    published BOOLEAN,
    conversation_ai_enabled BOOLEAN,
    ai_prompt TEXT,
    qr_code_position TEXT,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ
) LANGUAGE plpgsql SECURITY INVOKER AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.id, 
        c.name, 
        c.description, 
        c.image_urls, 
        c.published, 
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
    p_published BOOLEAN DEFAULT FALSE,
    p_qr_code_position TEXT DEFAULT 'BR'
) RETURNS UUID LANGUAGE plpgsql SECURITY INVOKER AS $$
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
        published,
        qr_code_position
    ) VALUES (
        auth.uid(),
        p_name,
        p_description,
        p_image_urls,
        p_conversation_ai_enabled,
        p_ai_prompt,
        p_published,
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
    published BOOLEAN,
    conversation_ai_enabled BOOLEAN,
    ai_prompt TEXT,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ
) LANGUAGE plpgsql SECURITY INVOKER AS $$
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
        c.published, 
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
    p_name TEXT,
    p_description TEXT,
    p_image_urls TEXT[] DEFAULT NULL,
    p_conversation_ai_enabled BOOLEAN DEFAULT NULL,
    p_ai_prompt TEXT DEFAULT NULL,
    p_published BOOLEAN DEFAULT NULL,
    p_qr_code_position TEXT DEFAULT NULL
) RETURNS BOOLEAN LANGUAGE plpgsql SECURITY INVOKER AS $$
BEGIN
    UPDATE cards
    SET 
        name = COALESCE(p_name, name),
        description = COALESCE(p_description, description),
        image_urls = COALESCE(p_image_urls, image_urls),
        conversation_ai_enabled = COALESCE(p_conversation_ai_enabled, conversation_ai_enabled),
        ai_prompt = COALESCE(p_ai_prompt, ai_prompt),
        published = COALESCE(p_published, published),
        qr_code_position = COALESCE(p_qr_code_position::"QRCodePosition", qr_code_position),
        updated_at = now()
    WHERE id = p_card_id AND user_id = auth.uid();
    
    RETURN FOUND;
END;
$$;

-- Delete a card (more secure)
CREATE OR REPLACE FUNCTION delete_card(p_card_id UUID)
RETURNS BOOLEAN LANGUAGE plpgsql SECURITY INVOKER AS $$
BEGIN
    DELETE FROM cards WHERE id = p_card_id AND user_id = auth.uid();
    RETURN FOUND;
END;
$$;

-- Enable Row Level Security
ALTER TABLE cards ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can view their own cards" 
ON cards FOR SELECT 
USING (user_id = auth.uid());

CREATE POLICY "Users can insert their own cards" 
ON cards FOR INSERT 
WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update their own cards" 
ON cards FOR UPDATE 
USING (user_id = auth.uid());

CREATE POLICY "Users can delete their own cards" 
ON cards FOR DELETE 
USING (user_id = auth.uid());
