-- =====================================================================
-- DEPLOYMENT SCRIPT: Translation System Fix
-- =====================================================================
-- This fixes two critical issues:
-- 1. Removes 'metadata' column from credit_consumptions INSERT (doesn't exist)
-- 2. Moves store_card_translations to server-side with proper permissions
-- =====================================================================
-- Run this in Supabase SQL Editor: https://supabase.com/dashboard/project/mzgusshseqxrdrkvamrg/sql
-- =====================================================================

-- 1. Update consume_credits function (remove metadata column)
CREATE OR REPLACE FUNCTION consume_credits(
    p_credits_to_consume DECIMAL,
    p_user_id UUID DEFAULT NULL,
    p_consumption_type VARCHAR DEFAULT 'other',
    p_metadata JSONB DEFAULT '{}'::jsonb
)
RETURNS VOID AS $$
DECLARE
    v_user_id UUID;
    v_current_balance DECIMAL;
    v_new_balance DECIMAL;
    v_consumption_id UUID;
    v_transaction_id UUID;
BEGIN
    v_user_id := COALESCE(p_user_id, auth.uid());
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    -- Lock and get current balance
    SELECT balance INTO v_current_balance
    FROM user_credits
    WHERE user_id = v_user_id
    FOR UPDATE;

    IF v_current_balance IS NULL OR v_current_balance < p_credits_to_consume THEN
        RAISE EXCEPTION 'Insufficient credits. Required: %, Available: %',
            p_credits_to_consume, COALESCE(v_current_balance, 0);
    END IF;

    -- Calculate new balance
    v_new_balance := v_current_balance - p_credits_to_consume;

    -- Update balance
    UPDATE user_credits
    SET
        balance = v_new_balance,
        total_consumed = total_consumed + p_credits_to_consume,
        updated_at = CURRENT_TIMESTAMP
    WHERE user_id = v_user_id;

    -- Record consumption (NO metadata column)
    INSERT INTO credit_consumptions (
        user_id, card_id, consumption_type, quantity, 
        credits_per_unit, total_credits, description
    ) VALUES (
        v_user_id, 
        (p_metadata->>'card_id')::UUID,
        p_consumption_type, 
        (p_metadata->>'language_count')::INTEGER,
        1.00, -- 1 credit per language for translations
        p_credits_to_consume,
        format('%s: %s credits', p_consumption_type, p_credits_to_consume)
    ) RETURNING id INTO v_consumption_id;

    -- Record transaction
    INSERT INTO credit_transactions (
        user_id, type, amount, balance_before, balance_after,
        reference_type, reference_id, description, metadata
    ) VALUES (
        v_user_id, 'consumption', -p_credits_to_consume,
        v_current_balance, v_new_balance,
        p_consumption_type, v_consumption_id,
        format('Credit consumption: %s', p_consumption_type),
        p_metadata
    ) RETURNING id INTO v_transaction_id;

    -- Log operation
    PERFORM log_operation(
        v_user_id,
        'credit_consumption',
        'credit_consumptions',
        v_consumption_id,
        jsonb_build_object(
            'consumption_type', p_consumption_type,
            'credits_consumed', p_credits_to_consume,
            'new_balance', v_new_balance,
            'transaction_id', v_transaction_id,
            'metadata', p_metadata
        )
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Create server-side translation function
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

-- 3. Grant execution permission to service_role only
GRANT EXECUTE ON FUNCTION store_card_translations(UUID, UUID, TEXT[], JSONB, JSONB, DECIMAL) TO service_role;

-- =====================================================================
-- DEPLOYMENT COMPLETE
-- =====================================================================
-- Test the translation feature:
-- 1. Open a card in the dashboard
-- 2. Go to General tab
-- 3. Scroll to "Multi-Language Support" section
-- 4. Click "Manage Translations"
-- 5. Select a language and translate
-- =====================================================================

