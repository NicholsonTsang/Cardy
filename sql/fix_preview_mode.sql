-- Fix for preview mode functionality
-- This adds the get_card_preview_access function to enable card previews without issued cards

-- Get card preview URL without requiring issued cards (for card owners)
CREATE OR REPLACE FUNCTION get_card_preview_access(p_card_id UUID)
RETURNS TABLE (
    preview_mode BOOLEAN,
    card_id UUID,
    activation_code TEXT
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
    
    -- Return preview access with special preview mode flag and the card_id as the "issue_card_id"
    -- Using a special preview activation code that will be recognized by the backend
    RETURN QUERY
    SELECT 
        TRUE as preview_mode,
        p_card_id as card_id,
        'PREVIEW_' || p_card_id::TEXT as activation_code;
END;
$$;

-- Grant execute permission for the new preview access function
GRANT EXECUTE ON FUNCTION get_card_preview_access(UUID) TO authenticated; 