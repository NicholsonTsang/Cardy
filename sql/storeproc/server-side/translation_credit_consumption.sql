-- =====================================================================
-- TRANSLATION CREDIT CONSUMPTION (SERVER-SIDE)
-- =====================================================================
-- Server-side procedures for consuming credits during direct translations
-- Called by backend Express server with service_role permissions
-- =====================================================================

-- =====================================================================
-- 1. Consume Translation Credits
-- =====================================================================
-- Consumes credits for successful translations
-- Called after each language is successfully translated
-- =====================================================================

CREATE OR REPLACE FUNCTION consume_translation_credits(
  p_user_id UUID,
  p_card_id UUID,
  p_language VARCHAR(10),
  p_credit_cost DECIMAL DEFAULT 1.0
)
RETURNS JSONB
SECURITY DEFINER
AS $$
DECLARE
  v_current_balance DECIMAL;
  v_new_balance DECIMAL;
  v_card_name TEXT;
BEGIN
  -- Get current balance
  SELECT balance INTO v_current_balance
  FROM user_credits
  WHERE user_id = p_user_id;

  IF NOT FOUND THEN
    -- Create credit account with 0 balance
    INSERT INTO user_credits (user_id, balance)
    VALUES (p_user_id, 0)
    RETURNING balance INTO v_current_balance;
  END IF;

  -- Check if sufficient credits
  IF v_current_balance < p_credit_cost THEN
    RAISE EXCEPTION 'Insufficient credits. Required: %, Available: %', p_credit_cost, v_current_balance;
  END IF;

  -- Calculate new balance
  v_new_balance := v_current_balance - p_credit_cost;

  -- Update user balance
  UPDATE user_credits
  SET balance = v_new_balance,
      updated_at = NOW()
  WHERE user_id = p_user_id;

  -- Log credit consumption
  INSERT INTO credit_transactions (
    user_id,
    type,
    amount,
    balance_before,
    balance_after,
    description,
    metadata
  ) VALUES (
    p_user_id,
    'consumption',
    p_credit_cost,
    v_current_balance,
    v_new_balance,
    format('Translation to %s', p_language),
    jsonb_build_object(
      'card_id', p_card_id,
      'language', p_language,
      'consumption_type', 'translation'
    )
  );

  -- Log credit consumption detail
  SELECT name INTO v_card_name FROM cards WHERE id = p_card_id;
  
  INSERT INTO credit_consumptions (
    user_id,
    consumption_type,
    quantity,
    credits_per_unit,
    total_credits,
    metadata
  ) VALUES (
    p_user_id,
    'translation',
    1,
    p_credit_cost,
    p_credit_cost,
    jsonb_build_object(
      'card_id', p_card_id,
      'card_name', v_card_name,
      'language', p_language
    )
  );

  RETURN jsonb_build_object(
    'success', true,
    'user_id', p_user_id,
    'credits_consumed', p_credit_cost,
    'balance_before', v_current_balance,
    'balance_after', v_new_balance,
    'language', p_language
  );
END;
$$ LANGUAGE plpgsql;

-- =====================================================================
-- 2. Record Translation Completion
-- =====================================================================
-- Records translation in translation_history table
-- Called after translation completes (success or failure)
-- =====================================================================

CREATE OR REPLACE FUNCTION record_translation_completion(
  p_user_id UUID,
  p_card_id UUID,
  p_target_languages TEXT[],
  p_credit_cost DECIMAL,
  p_status VARCHAR DEFAULT 'completed',
  p_error_message TEXT DEFAULT NULL,
  p_metadata JSONB DEFAULT '{}'::JSONB
)
RETURNS UUID
SECURITY DEFINER
AS $$
DECLARE
  v_history_id UUID;
BEGIN
  INSERT INTO translation_history (
    card_id,
    target_languages,
    credit_cost,
    translated_by,
    translated_at,
    status,
    error_message,
    metadata
  ) VALUES (
    p_card_id,
    p_target_languages,
    p_credit_cost,
    p_user_id,
    NOW(),
    p_status,
    p_error_message,
    p_metadata
  )
  RETURNING id INTO v_history_id;

  RETURN v_history_id;
END;
$$ LANGUAGE plpgsql;

-- =====================================================================
-- Grant permissions to service_role (backend server)
-- =====================================================================

GRANT EXECUTE ON FUNCTION consume_translation_credits(UUID, UUID, VARCHAR, DECIMAL) TO service_role;
GRANT EXECUTE ON FUNCTION record_translation_completion(UUID, UUID, TEXT[], DECIMAL, VARCHAR, TEXT, JSONB) TO service_role;

