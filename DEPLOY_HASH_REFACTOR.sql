-- ============================================================================
-- HASH REFACTOR DEPLOYMENT
-- ============================================================================
-- This script deploys the hash calculation refactor that enables 1-step import
-- 
-- Changes:
-- 1. Triggers only calculate hash if NULL (allows override during import)
-- 2. create_card() accepts optional p_content_hash and p_translations
-- 3. create_content_item() accepts optional p_content_hash and p_translations
-- 
-- Deploy Order:
-- 1. This file (triggers + stored procedures)
-- 2. Frontend changes (automatic via deployment)
-- ============================================================================

-- STEP 1: Update Triggers
-- ============================================================================

-- Trigger function for cards table
-- Modified to allow hash override during import: only calculates if NULL
CREATE OR REPLACE FUNCTION update_card_content_hash()
RETURNS TRIGGER AS $$
BEGIN
  -- On INSERT: Only calculate hash if not already provided
  IF TG_OP = 'INSERT' THEN
    IF NEW.content_hash IS NULL THEN
      NEW.content_hash := md5(COALESCE(NEW.name, '') || '|' || COALESCE(NEW.description, ''));
      NEW.last_content_update := NOW();
    END IF;
  -- On UPDATE: Only recalculate if name or description changed AND hash wasn't manually set
  ELSIF TG_OP = 'UPDATE' THEN
    IF (NEW.name IS DISTINCT FROM OLD.name OR NEW.description IS DISTINCT FROM OLD.description) THEN
      -- Only recalculate if hash hasn't been manually updated
      IF NEW.content_hash = OLD.content_hash THEN
        NEW.content_hash := md5(COALESCE(NEW.name, '') || '|' || COALESCE(NEW.description, ''));
        NEW.last_content_update := NOW();
      END IF;
      -- Note: We don't clear translations here - they're marked as outdated via hash comparison
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger function for content_items table
-- Modified to allow hash override during import: only calculates if NULL
CREATE OR REPLACE FUNCTION update_content_item_content_hash()
RETURNS TRIGGER AS $$
BEGIN
  -- On INSERT: Only calculate hash if not already provided
  IF TG_OP = 'INSERT' THEN
    IF NEW.content_hash IS NULL THEN
      NEW.content_hash := md5(
        COALESCE(NEW.name, '') || '|' || 
        COALESCE(NEW.content, '') || '|' ||
        COALESCE(NEW.ai_knowledge_base, '')
      );
      NEW.last_content_update := NOW();
    END IF;
  -- On UPDATE: Only recalculate if any translatable field changed AND hash wasn't manually set
  ELSIF TG_OP = 'UPDATE' THEN
    IF (NEW.name IS DISTINCT FROM OLD.name OR 
        NEW.content IS DISTINCT FROM OLD.content OR
        NEW.ai_knowledge_base IS DISTINCT FROM OLD.ai_knowledge_base) THEN
      -- Only recalculate if hash hasn't been manually updated
      IF NEW.content_hash = OLD.content_hash THEN
        NEW.content_hash := md5(
          COALESCE(NEW.name, '') || '|' || 
          COALESCE(NEW.content, '') || '|' ||
          COALESCE(NEW.ai_knowledge_base, '')
        );
        NEW.last_content_update := NOW();
      END IF;
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- STEP 2: Update Stored Procedures
-- ============================================================================

-- Create a new card (more secure)
-- Modified to accept optional content_hash and translations for import
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
    p_original_language VARCHAR(10) DEFAULT 'en',
    p_content_hash TEXT DEFAULT NULL,  -- For import: preserve original hash
    p_translations JSONB DEFAULT NULL  -- For import: restore translations
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
        translations   -- May be NULL (normal) or provided (import)
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
        COALESCE(p_translations, '{}'::JSONB)  -- Default to empty object
    )
    RETURNING id INTO v_card_id;
    
    -- Log operation
    IF p_translations IS NOT NULL AND p_translations != '{}'::JSONB THEN
        PERFORM log_operation(format('Imported card with translations: %s', p_name));
    ELSE
        PERFORM log_operation(format('Created card: %s', p_name));
    END IF;
    
    RETURN v_card_id;
END;
$$;
GRANT EXECUTE ON FUNCTION create_card(TEXT, TEXT, TEXT, TEXT, JSONB, BOOLEAN, TEXT, TEXT, TEXT, VARCHAR, TEXT, JSONB) TO authenticated;

-- Modified to accept optional content_hash and translations for import
CREATE OR REPLACE FUNCTION create_content_item(
    p_card_id UUID,
    p_name TEXT,
    p_parent_id UUID DEFAULT NULL,
    p_content TEXT DEFAULT '',
    p_image_url TEXT DEFAULT NULL,
    p_original_image_url TEXT DEFAULT NULL,
    p_crop_parameters JSONB DEFAULT NULL,
    p_ai_knowledge_base TEXT DEFAULT '',
    p_content_hash TEXT DEFAULT NULL,  -- For import: preserve original hash
    p_translations JSONB DEFAULT NULL  -- For import: restore translations
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
        sort_order,
        content_hash,  -- May be NULL (trigger calculates) or provided (import)
        translations   -- May be NULL (normal) or provided (import)
    ) VALUES (
        p_card_id,
        p_parent_id,
        p_name,
        p_content,
        p_image_url,
        p_original_image_url,
        p_crop_parameters,
        p_ai_knowledge_base,
        v_next_sort_order,
        p_content_hash,  -- Trigger will calculate if NULL
        COALESCE(p_translations, '{}'::JSONB)  -- Default to empty object
    )
    RETURNING id INTO v_content_item_id;
    
    -- Log operation
    IF p_translations IS NOT NULL AND p_translations != '{}'::JSONB THEN
        PERFORM log_operation(format('Imported content item with translations: %s', p_name));
    ELSE
        PERFORM log_operation(format('Created content item: %s', p_name));
    END IF;
    
    RETURN v_content_item_id;
END;
$$;
GRANT EXECUTE ON FUNCTION create_content_item(UUID, TEXT, UUID, TEXT, TEXT, TEXT, JSONB, TEXT, TEXT, JSONB) TO authenticated;

-- ============================================================================
-- DEPLOYMENT COMPLETE
-- ============================================================================
-- Verify deployment:
-- 
-- SELECT proname, pronargs FROM pg_proc WHERE proname = 'create_card';
-- -- Should show 12 args (was 10)
-- 
-- SELECT proname, pronargs FROM pg_proc WHERE proname = 'create_content_item';
-- -- Should show 10 args (was 8)
-- 
-- SELECT tgname FROM pg_trigger WHERE tgname LIKE '%content_hash%';
-- -- Should show both triggers exist
-- ============================================================================

