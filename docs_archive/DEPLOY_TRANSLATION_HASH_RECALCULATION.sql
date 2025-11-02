-- Fix for translation content hash mismatch after import
-- This recalculates the content_hash stored inside each translation
-- to match the newly imported card's content_hash

-- Recalculate translation content hashes for cards
CREATE OR REPLACE FUNCTION recalculate_card_translation_hashes(
    p_card_id UUID
) RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER AS $$
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
        
        RAISE NOTICE 'Recalculated translation hashes for card %', p_card_id;
    END IF;
END;
$$;

GRANT EXECUTE ON FUNCTION recalculate_card_translation_hashes(UUID) TO authenticated;


-- Recalculate translation content hashes for content items
CREATE OR REPLACE FUNCTION recalculate_content_item_translation_hashes(
    p_content_item_id UUID
) RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER AS $$
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
        
        RAISE NOTICE 'Recalculated translation hashes for content item %', p_content_item_id;
    END IF;
END;
$$;

GRANT EXECUTE ON FUNCTION recalculate_content_item_translation_hashes(UUID) TO authenticated;


-- Batch recalculate all translation hashes for a card and its content items
CREATE OR REPLACE FUNCTION recalculate_all_translation_hashes(
    p_card_id UUID
) RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER AS $$
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
$$;

GRANT EXECUTE ON FUNCTION recalculate_all_translation_hashes(UUID) TO authenticated;

-- Note: These functions solve the content_hash mismatch problem after import
-- When translations are imported, their embedded content_hash is from the old card
-- These functions update those embedded hashes to match the newly created card
-- This ensures translations show as "Up to Date" instead of "Outdated"

