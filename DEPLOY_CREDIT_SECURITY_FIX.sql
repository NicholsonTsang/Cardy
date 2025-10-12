-- =====================================================================
-- DEPLOYMENT SCRIPT: Credit System Security Fixes
-- =====================================================================
-- This fixes CRITICAL security vulnerabilities in credit purchase completion
-- =====================================================================
-- SECURITY ISSUES ADDRESSED:
-- 1. Missing user ID validation in complete_credit_purchase()
-- 2. Missing payment amount verification
-- 3. Race condition prevention with FOR UPDATE locks
-- 4. Missing user ID validation in refund_credit_purchase()
-- 5. Proper GRANT permissions to service_role
-- =====================================================================
-- Run this in Supabase SQL Editor: https://supabase.com/dashboard/project/mzgusshseqxrdrkvamrg/sql
-- =====================================================================

-- 1. Fix complete_credit_purchase() with security enhancements
CREATE OR REPLACE FUNCTION complete_credit_purchase(
    p_user_id UUID,  -- User ID from webhook metadata for validation
    p_stripe_session_id VARCHAR,
    p_stripe_payment_intent_id VARCHAR DEFAULT NULL,
    p_amount_paid_cents INTEGER DEFAULT NULL,  -- Actual amount paid from Stripe
    p_receipt_url TEXT DEFAULT NULL,
    p_payment_method JSONB DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
    v_purchase_id UUID;
    v_user_id_from_db UUID;
    v_credits_amount DECIMAL;
    v_expected_amount_cents INTEGER;
    v_purchase_status VARCHAR;
    v_current_balance DECIMAL;
    v_new_balance DECIMAL;
    v_transaction_id UUID;
BEGIN
    -- Lock and get the pending purchase record (prevents race conditions)
    SELECT id, user_id, credits_amount, status
    INTO v_purchase_id, v_user_id_from_db, v_credits_amount, v_purchase_status
    FROM credit_purchases
    WHERE stripe_session_id = p_stripe_session_id
    FOR UPDATE;  -- Lock to prevent concurrent processing

    IF v_purchase_id IS NULL THEN
        RAISE EXCEPTION 'Credit purchase not found: %', p_stripe_session_id;
    END IF;

    -- SECURITY: Verify user ID matches (prevent user A completing user B's purchase)
    IF v_user_id_from_db != p_user_id THEN
        RAISE EXCEPTION 'User ID mismatch. Expected: %, Provided: %', v_user_id_from_db, p_user_id;
    END IF;

    -- SECURITY: Check if already processed (prevent duplicate processing)
    IF v_purchase_status != 'pending' THEN
        RAISE EXCEPTION 'Purchase already processed with status: %', v_purchase_status;
    END IF;

    -- SECURITY: Verify payment amount (1 credit = $1 = 100 cents)
    IF p_amount_paid_cents IS NOT NULL THEN
        v_expected_amount_cents := (v_credits_amount * 100)::INTEGER;
        IF p_amount_paid_cents != v_expected_amount_cents THEN
            RAISE EXCEPTION 'Amount mismatch. Expected: % cents (% credits), Paid: % cents', 
                v_expected_amount_cents, v_credits_amount, p_amount_paid_cents;
        END IF;
    END IF;

    -- Initialize credits if not exists
    INSERT INTO user_credits (user_id, balance, total_purchased, total_consumed)
    VALUES (v_user_id_from_db, 0, 0, 0)
    ON CONFLICT (user_id) DO NOTHING;

    -- Lock the user credits row for update
    SELECT balance INTO v_current_balance
    FROM user_credits
    WHERE user_id = v_user_id_from_db
    FOR UPDATE;

    v_new_balance := v_current_balance + v_credits_amount;

    -- Update user credits
    UPDATE user_credits
    SET 
        balance = v_new_balance,
        total_purchased = total_purchased + v_credits_amount,
        updated_at = CURRENT_TIMESTAMP
    WHERE user_id = v_user_id_from_db;

    -- Update purchase record
    UPDATE credit_purchases
    SET 
        status = 'completed',
        stripe_payment_intent_id = p_stripe_payment_intent_id,
        receipt_url = p_receipt_url,
        payment_method = p_payment_method,
        completed_at = CURRENT_TIMESTAMP
    WHERE id = v_purchase_id;

    -- Record transaction
    INSERT INTO credit_transactions (
        user_id, type, amount, balance_before, balance_after,
        reference_type, reference_id, description, metadata
    ) VALUES (
        v_user_id_from_db, 'purchase', v_credits_amount, v_current_balance, v_new_balance,
        'stripe_purchase', v_purchase_id,
        format('Credit purchase: %s credits', v_credits_amount),
        jsonb_build_object(
            'stripe_session_id', p_stripe_session_id,
            'stripe_payment_intent_id', p_stripe_payment_intent_id
        )
    ) RETURNING id INTO v_transaction_id;

    -- Note: This is called by webhooks without auth context, so we don't log to operations_log
    -- The credit_transactions table serves as the complete audit log for these operations

    RETURN jsonb_build_object(
        'success', true,
        'purchase_id', v_purchase_id,
        'transaction_id', v_transaction_id,
        'credits_added', v_credits_amount,
        'new_balance', v_new_balance,
        'user_id', v_user_id_from_db
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Fix refund_credit_purchase() with security enhancements
CREATE OR REPLACE FUNCTION refund_credit_purchase(
    p_user_id UUID,  -- User ID for authorization validation
    p_purchase_id UUID,
    p_refund_amount DECIMAL,
    p_reason TEXT DEFAULT 'Customer requested refund'
)
RETURNS JSONB AS $$
DECLARE
    v_user_id_from_db UUID;
    v_credits_amount DECIMAL;
    v_current_balance DECIMAL;
    v_new_balance DECIMAL;
    v_transaction_id UUID;
    v_purchase_status VARCHAR;
BEGIN
    -- Lock and get the purchase record (prevents race conditions)
    SELECT user_id, credits_amount, status
    INTO v_user_id_from_db, v_credits_amount, v_purchase_status
    FROM credit_purchases
    WHERE id = p_purchase_id
    FOR UPDATE;  -- Lock to prevent concurrent refunds

    IF v_user_id_from_db IS NULL THEN
        RAISE EXCEPTION 'Credit purchase not found: %', p_purchase_id;
    END IF;

    -- SECURITY: Verify user ID matches (prevent refunding other users' purchases)
    IF v_user_id_from_db != p_user_id THEN
        RAISE EXCEPTION 'User ID mismatch. Expected: %, Provided: %', v_user_id_from_db, p_user_id;
    END IF;

    IF v_purchase_status != 'completed' THEN
        RAISE EXCEPTION 'Cannot refund purchase with status: %', v_purchase_status;
    END IF;

    IF p_refund_amount > v_credits_amount THEN
        RAISE EXCEPTION 'Refund amount exceeds original purchase amount';
    END IF;

    -- Lock the user credits row for update
    SELECT balance INTO v_current_balance
    FROM user_credits
    WHERE user_id = v_user_id_from_db
    FOR UPDATE;

    IF v_current_balance < p_refund_amount THEN
        RAISE EXCEPTION 'Insufficient credits for refund. Current balance: %, Refund amount: %', 
            v_current_balance, p_refund_amount;
    END IF;

    v_new_balance := v_current_balance - p_refund_amount;

    -- Update user credits
    UPDATE user_credits
    SET 
        balance = v_new_balance,
        total_purchased = total_purchased - p_refund_amount,
        updated_at = CURRENT_TIMESTAMP
    WHERE user_id = v_user_id_from_db;

    -- Update purchase record
    UPDATE credit_purchases
    SET 
        status = CASE 
            WHEN p_refund_amount = credits_amount THEN 'refunded'
            ELSE 'completed' -- Partial refund
        END,
        metadata = COALESCE(metadata, '{}'::jsonb) || jsonb_build_object(
            'refund_amount', p_refund_amount,
            'refund_reason', p_reason,
            'refund_at', CURRENT_TIMESTAMP
        )
    WHERE id = p_purchase_id;

    -- Record transaction
    INSERT INTO credit_transactions (
        user_id, type, amount, balance_before, balance_after,
        reference_type, reference_id, description, metadata
    ) VALUES (
        v_user_id_from_db, 'refund', p_refund_amount, v_current_balance, v_new_balance,
        'stripe_refund', p_purchase_id,
        format('Credit refund: %s credits - %s', p_refund_amount, p_reason),
        jsonb_build_object(
            'original_purchase_id', p_purchase_id,
            'refund_reason', p_reason
        )
    ) RETURNING id INTO v_transaction_id;

    -- Note: This is called by webhooks without auth context, so we don't log to operations_log  
    -- The credit_transactions table serves as the complete audit log for these operations

    RETURN jsonb_build_object(
        'success', true,
        'purchase_id', p_purchase_id,
        'transaction_id', v_transaction_id,
        'credits_refunded', p_refund_amount,
        'new_balance', v_new_balance
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Grant execution permissions to service_role only (called by webhooks)
GRANT EXECUTE ON FUNCTION complete_credit_purchase(UUID, VARCHAR, VARCHAR, INTEGER, TEXT, JSONB) TO service_role;
GRANT EXECUTE ON FUNCTION refund_credit_purchase(UUID, UUID, DECIMAL, TEXT) TO service_role;

-- =====================================================================
-- DEPLOYMENT COMPLETE
-- =====================================================================
-- NEXT STEPS:
-- 1. Deploy updated Edge Function: npx supabase functions deploy stripe-credit-webhook
-- 2. Ensure Stripe session metadata includes 'user_id' field
-- 3. Test credit purchase flow
-- 4. Test refund flow
-- =====================================================================

