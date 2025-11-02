-- =====================================================================
-- FIX: get_card_by_id Missing Fields
-- =====================================================================
-- This fixes the get_card_by_id stored procedure to return all card fields
-- including original_language, original_image_url, crop_parameters, etc.
-- 
-- DEPLOYMENT INSTRUCTIONS:
-- 1. Go to Supabase Dashboard > SQL Editor
-- 2. Create a new query
-- 3. Copy and paste this entire file
-- 4. Click "Run" to execute
-- =====================================================================

-- Drop the old function
DROP FUNCTION IF EXISTS get_card_by_id(UUID);

-- Create the updated function with all fields
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
        c.created_at, 
        c.updated_at
    FROM cards c
    WHERE c.id = p_card_id;
    -- No need to check user_id = auth.uid() as RLS policy will handle this
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION get_card_by_id(UUID) TO authenticated;

-- =====================================================================
-- VERIFICATION
-- =====================================================================
-- After running this script, you can verify the fix by:
-- 1. Creating or editing a card with a non-English original language
-- 2. Saving the card
-- 3. Refreshing the page
-- 4. The original language should now persist and display correctly
-- =====================================================================

