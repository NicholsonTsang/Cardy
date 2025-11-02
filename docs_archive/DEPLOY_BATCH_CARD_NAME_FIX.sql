-- =====================================================================
-- FIX: Batch Issuance Credit Consumption Missing Card Name
-- =====================================================================
-- This fixes the consume_credits_for_batch stored procedure to store 
-- the card_id when consuming credits for batch issuance, so that the
-- card name appears in the consumption history.
-- 
-- DEPLOYMENT INSTRUCTIONS:
-- 1. Go to Supabase Dashboard > SQL Editor
-- 2. Create a new query
-- 3. Copy and paste this entire file
-- 4. Click "Run" to execute
-- =====================================================================

-- Drop and recreate the function with card_id support
DROP FUNCTION IF EXISTS consume_credits_for_batch(UUID, INTEGER);

-- Consume credits for batch issuance (now includes card_id)
CREATE OR REPLACE FUNCTION consume_credits_for_batch(
    p_batch_id UUID,
    p_card_count INTEGER
)
RETURNS JSONB AS $$
DECLARE
    v_user_id UUID;
    v_card_id UUID;
    v_credits_per_card DECIMAL := 2.00; -- 2 credits per card
    v_total_credits DECIMAL;
    v_current_balance DECIMAL;
    v_new_balance DECIMAL;
    v_consumption_id UUID;
    v_transaction_id UUID;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    v_total_credits := p_card_count * v_credits_per_card;

    -- Get card_id from the batch
    SELECT card_id INTO v_card_id
    FROM card_batches
    WHERE id = p_batch_id;

    IF v_card_id IS NULL THEN
        RAISE EXCEPTION 'Batch not found: %', p_batch_id;
    END IF;

    -- Lock the user credits row for update
    SELECT balance INTO v_current_balance
    FROM user_credits
    WHERE user_id = v_user_id
    FOR UPDATE;

    IF v_current_balance IS NULL OR v_current_balance < v_total_credits THEN
        RAISE EXCEPTION 'Insufficient credits. Required: %, Available: %', 
            v_total_credits, COALESCE(v_current_balance, 0);
    END IF;

    v_new_balance := v_current_balance - v_total_credits;

    -- Update user credits
    UPDATE user_credits
    SET 
        balance = v_new_balance,
        total_consumed = total_consumed + v_total_credits,
        updated_at = CURRENT_TIMESTAMP
    WHERE user_id = v_user_id;

    -- Record consumption (now includes card_id)
    INSERT INTO credit_consumptions (
        user_id, card_id, batch_id, consumption_type, quantity, 
        credits_per_unit, total_credits, description
    ) VALUES (
        v_user_id, v_card_id, p_batch_id, 'batch_issuance', p_card_count,
        v_credits_per_card, v_total_credits,
        format('Batch issuance: %s cards', p_card_count)
    ) RETURNING id INTO v_consumption_id;

    -- Record transaction
    INSERT INTO credit_transactions (
        user_id, type, amount, balance_before, balance_after,
        reference_type, reference_id, description
    ) VALUES (
        v_user_id, 'consumption', v_total_credits, v_current_balance, v_new_balance,
        'batch_issuance', p_batch_id,
        format('Batch issuance: %s cards @ %s credits each', p_card_count, v_credits_per_card)
    ) RETURNING id INTO v_transaction_id;

    -- Update batch with credit cost and payment method
    UPDATE card_batches
    SET 
        credit_cost = v_total_credits,
        payment_method = 'credits'
    WHERE id = p_batch_id;

    -- Log the operation
    PERFORM log_operation(
        format('Consumed %s credits for batch issuance: %s cards (Batch ID: %s)',
            v_total_credits, p_card_count, p_batch_id)
    );

    RETURN jsonb_build_object(
        'success', true,
        'consumption_id', v_consumption_id,
        'transaction_id', v_transaction_id,
        'credits_consumed', v_total_credits,
        'new_balance', v_new_balance
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION consume_credits_for_batch(UUID, INTEGER) TO authenticated;

-- =====================================================================
-- Verification Query
-- =====================================================================
-- After deployment, run this to verify the fix worked:
-- 
-- SELECT 
--     cc.created_at,
--     cc.consumption_type,
--     c.name AS card_name,
--     b.batch_name,
--     cc.quantity,
--     cc.total_credits
-- FROM credit_consumptions cc
-- LEFT JOIN cards c ON c.id = cc.card_id
-- LEFT JOIN card_batches b ON b.id = cc.batch_id
-- WHERE cc.consumption_type = 'batch_issuance'
-- ORDER BY cc.created_at DESC
-- LIMIT 10;
-- 
-- Expected result: card_name should now show for batch issuance records
-- =====================================================================

