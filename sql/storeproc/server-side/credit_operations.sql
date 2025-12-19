-- =================================================================
-- CREDIT OPERATIONS - SERVER-SIDE STORED PROCEDURES
-- =================================================================
-- All credit-related database operations from Express backend.
-- Called by backend Express server with service_role permissions.
-- These are atomic operations for credit balance management.
-- =================================================================

-- Get user credit balance
DROP FUNCTION IF EXISTS get_user_credit_balance_server CASCADE;
CREATE OR REPLACE FUNCTION get_user_credit_balance_server(
    p_user_id UUID
)
RETURNS DECIMAL AS $$
DECLARE
    v_balance DECIMAL;
BEGIN
    SELECT balance INTO v_balance
    FROM user_credits
    WHERE user_id = p_user_id;
    
    RETURN COALESCE(v_balance, 0);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Deduct credits for overage (atomic operation)
DROP FUNCTION IF EXISTS deduct_overage_credits_server CASCADE;
CREATE OR REPLACE FUNCTION deduct_overage_credits_server(
    p_user_id UUID,
    p_card_id UUID,
    p_credits_amount DECIMAL,
    p_access_granted INTEGER
)
RETURNS JSONB AS $$
DECLARE
    v_current_balance DECIMAL;
    v_new_balance DECIMAL;
BEGIN
    -- Get current balance with lock
    SELECT balance INTO v_current_balance
    FROM user_credits
    WHERE user_id = p_user_id
    FOR UPDATE;
    
    IF v_current_balance IS NULL THEN
        v_current_balance := 0;
    END IF;
    
    -- Check if sufficient balance
    IF v_current_balance < p_credits_amount THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'error', 'Insufficient credits',
            'current_balance', v_current_balance,
            'required', p_credits_amount
        );
    END IF;
    
    -- Calculate new balance
    v_new_balance := v_current_balance - p_credits_amount;
    
    -- Update balance
    UPDATE user_credits
    SET balance = v_new_balance, updated_at = NOW()
    WHERE user_id = p_user_id;
    
    -- Record consumption
    INSERT INTO credit_consumptions (
        user_id, card_id, quantity, credits_per_unit, total_credits,
        consumption_type, description
    ) VALUES (
        p_user_id, p_card_id, p_access_granted, 
        p_credits_amount / p_access_granted, p_credits_amount,
        'subscription_overage_batch',
        format('Purchased %s overage access for %s credits', p_access_granted, p_credits_amount)
    );
    
    -- Record transaction
    INSERT INTO credit_transactions (
        user_id, amount, balance_before, balance_after, type,
        reference_type, description
    ) VALUES (
        p_user_id, -p_credits_amount, v_current_balance, v_new_balance,
        'consumption', 'subscription_overage_batch',
        format('Overage batch: %s access for %s credits', p_access_granted, p_credits_amount)
    );
    
    RETURN jsonb_build_object(
        'success', TRUE,
        'balance_before', v_current_balance,
        'balance_after', v_new_balance,
        'credits_deducted', p_credits_amount,
        'access_granted', p_access_granted
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get credit purchase by payment intent
DROP FUNCTION IF EXISTS get_credit_purchase_by_intent_server CASCADE;
CREATE OR REPLACE FUNCTION get_credit_purchase_by_intent_server(
    p_payment_intent_id TEXT
)
RETURNS TABLE (
    id UUID,
    user_id UUID,
    credits_amount DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT cp.id, cp.user_id, cp.credits_amount
    FROM credit_purchases cp
    WHERE cp.stripe_payment_intent_id = p_payment_intent_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =================================================================
-- GRANTS - Only service_role can execute these
-- =================================================================
REVOKE ALL ON FUNCTION get_user_credit_balance_server FROM PUBLIC, authenticated, anon;
GRANT EXECUTE ON FUNCTION get_user_credit_balance_server TO service_role;

REVOKE ALL ON FUNCTION deduct_overage_credits_server FROM PUBLIC, authenticated, anon;
GRANT EXECUTE ON FUNCTION deduct_overage_credits_server TO service_role;

REVOKE ALL ON FUNCTION get_credit_purchase_by_intent_server FROM PUBLIC, authenticated, anon;
GRANT EXECUTE ON FUNCTION get_credit_purchase_by_intent_server TO service_role;

