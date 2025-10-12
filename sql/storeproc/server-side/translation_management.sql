-- =====================================================================
-- SERVER-SIDE TRANSLATION STORED PROCEDURES
-- =====================================================================
-- These procedures are called by Edge Functions and require service_role permissions
-- =====================================================================

-- Store translated content from Edge Function
-- This function is called after GPT-4 has translated the content
CREATE OR REPLACE FUNCTION store_card_translations(
  p_user_id UUID, -- Explicit user ID from Edge Function
  p_card_id UUID,
  p_target_languages TEXT[],
  p_card_translations JSONB, -- {"zh-Hans": {"name": "...", "description": "..."}, ...}
  p_content_items_translations JSONB, -- {"item_id_1": {"zh-Hans": {"name": "...", "content": "..."}}, ...}
  p_credit_cost DECIMAL
)
RETURNS JSONB
SECURITY DEFINER
AS $$
DECLARE
  v_card_owner UUID;
  v_current_balance DECIMAL;
  v_translation_history_id UUID;
  v_content_hash TEXT;
  v_item_id UUID;
  v_item_translations JSONB;
  v_item_hash TEXT;
  v_result JSONB;
BEGIN
  -- Verify card ownership
  SELECT user_id INTO v_card_owner FROM cards WHERE id = p_card_id;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Card not found';
  END IF;

  IF v_card_owner != p_user_id THEN
    RAISE EXCEPTION 'Unauthorized: Card does not belong to user';
  END IF;

  -- Check credit balance
  SELECT check_credit_balance(p_credit_cost, p_user_id) INTO v_current_balance;

  -- Start transaction for atomic operation
  -- Get current card content hash
  SELECT content_hash INTO v_content_hash FROM cards WHERE id = p_card_id;

  -- Update card translations (merge with existing)
  UPDATE cards
  SET 
    translations = translations || p_card_translations,
    updated_at = NOW()
  WHERE id = p_card_id;

  -- Update content items translations
  FOR v_item_id, v_item_translations IN
    SELECT key::UUID, value
    FROM jsonb_each(p_content_items_translations)
  LOOP
    -- Get item content hash
    SELECT content_hash INTO v_item_hash 
    FROM content_items 
    WHERE id = v_item_id;

    -- Update item translations
    UPDATE content_items
    SET 
      translations = translations || v_item_translations,
      updated_at = NOW()
    WHERE id = v_item_id;
  END LOOP;

  -- Consume credits
  PERFORM consume_credits(
    p_credit_cost,
    p_user_id,
    'translation',
    jsonb_build_object(
      'card_id', p_card_id,
      'languages', p_target_languages,
      'language_count', array_length(p_target_languages, 1)
    )
  );

  -- Log to translation history
  INSERT INTO translation_history (
    card_id, 
    target_languages, 
    credit_cost, 
    translated_by,
    status,
    metadata
  )
  VALUES (
    p_card_id, 
    p_target_languages, 
    p_credit_cost, 
    p_user_id,
    'completed',
    jsonb_build_object(
      'model', 'gpt-4.1-nano',
      'language_count', array_length(p_target_languages, 1)
    )
  )
  RETURNING id INTO v_translation_history_id;

  -- Build result
  v_result := jsonb_build_object(
    'success', true,
    'card_id', p_card_id,
    'translated_languages', p_target_languages,
    'credits_used', p_credit_cost,
    'remaining_balance', v_current_balance - p_credit_cost,
    'translation_history_id', v_translation_history_id
  );

  RETURN v_result;
EXCEPTION
  WHEN OTHERS THEN
    RAISE EXCEPTION 'Failed to store translations: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- Grant execution permission to service_role only
GRANT EXECUTE ON FUNCTION store_card_translations(UUID, UUID, TEXT[], JSONB, JSONB, DECIMAL) TO service_role;

