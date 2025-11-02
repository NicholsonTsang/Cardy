-- Add bulk translation update functions for import/export
-- These functions allow restoring translations from Excel import

-- Update card translations in bulk (for import)
CREATE OR REPLACE FUNCTION update_card_translations_bulk(
    p_card_id UUID,
    p_translations JSONB
) RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_user_id UUID;
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
    
    -- Update translations
    UPDATE cards
    SET 
        translations = p_translations,
        updated_at = NOW()
    WHERE id = p_card_id;
    
    -- Log operation
    PERFORM log_operation(format('Bulk restored translations for card: %s', p_card_id));
END;
$$;

GRANT EXECUTE ON FUNCTION update_card_translations_bulk(UUID, JSONB) TO authenticated;


-- Update content item translations in bulk (for import)
CREATE OR REPLACE FUNCTION update_content_item_translations_bulk(
    p_content_item_id UUID,
    p_translations JSONB
) RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_user_id UUID;
    v_card_id UUID;
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
    
    -- Update translations
    UPDATE content_items
    SET 
        translations = p_translations,
        updated_at = NOW()
    WHERE id = p_content_item_id;
    
    -- Log operation
    PERFORM log_operation(format('Bulk restored translations for content item: %s', p_content_item_id));
END;
$$;

GRANT EXECUTE ON FUNCTION update_content_item_translations_bulk(UUID, JSONB) TO authenticated;

-- Note: These functions are specifically for import operations
-- They allow restoring previously exported translations during card import
-- Security is enforced through ownership verification

