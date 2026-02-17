-- =================================================================
-- VOICE CREDIT OPERATIONS - SERVER-SIDE STORED PROCEDURES
-- =================================================================
-- Voice credit billing for realtime voice conversations.
-- Separate from general credits - integer-based (1 credit = 1 voice call).
-- Called by backend Express server with service_role permissions.
-- =================================================================

-- 1. Get voice credit balance
DROP FUNCTION IF EXISTS get_voice_credit_balance_server CASCADE;
CREATE OR REPLACE FUNCTION get_voice_credit_balance_server(
    p_user_id UUID
)
RETURNS INTEGER AS $$
DECLARE
    v_balance INTEGER;
BEGIN
    SELECT balance INTO v_balance
    FROM voice_credits
    WHERE user_id = p_user_id;

    RETURN COALESCE(v_balance, 0);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Deduct voice credit and create call log (atomic)
DROP FUNCTION IF EXISTS deduct_voice_credit_server CASCADE;
CREATE OR REPLACE FUNCTION deduct_voice_credit_server(
    p_user_id UUID,
    p_card_id UUID,
    p_session_id TEXT
)
RETURNS JSONB AS $$
DECLARE
    v_current_balance INTEGER;
    v_new_balance INTEGER;
    v_call_id UUID;
BEGIN
    -- Initialize credits if not exists
    INSERT INTO voice_credits (user_id, balance, total_purchased, total_consumed)
    VALUES (p_user_id, 0, 0, 0)
    ON CONFLICT (user_id) DO NOTHING;

    -- Get current balance with lock
    SELECT balance INTO v_current_balance
    FROM voice_credits
    WHERE user_id = p_user_id
    FOR UPDATE;

    IF v_current_balance IS NULL OR v_current_balance <= 0 THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'error', 'No voice credits remaining',
            'balance', COALESCE(v_current_balance, 0)
        );
    END IF;

    v_new_balance := v_current_balance - 1;

    -- Update balance
    UPDATE voice_credits
    SET balance = v_new_balance,
        total_consumed = total_consumed + 1,
        updated_at = NOW()
    WHERE user_id = p_user_id;

    -- Record transaction
    INSERT INTO voice_credit_transactions (
        user_id, amount, balance_before, balance_after, type,
        card_id, session_id, description
    ) VALUES (
        p_user_id, -1, v_current_balance, v_new_balance, 'usage',
        p_card_id, p_session_id,
        format('Voice call on card %s', p_card_id)
    );

    -- Create call log entry
    INSERT INTO voice_call_log (
        card_id, user_id, session_id, credit_deducted
    ) VALUES (
        p_card_id, p_user_id, p_session_id, TRUE
    ) RETURNING id INTO v_call_id;

    RETURN jsonb_build_object(
        'success', TRUE,
        'balance_before', v_current_balance,
        'balance_after', v_new_balance,
        'call_id', v_call_id
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Log voice call end (update duration)
-- Uses subquery instead of ORDER BY/LIMIT in UPDATE (PostgreSQL requirement)
DROP FUNCTION IF EXISTS log_voice_call_end_server CASCADE;
CREATE OR REPLACE FUNCTION log_voice_call_end_server(
    p_card_id UUID,
    p_session_id TEXT,
    p_duration_seconds INTEGER
)
RETURNS BOOLEAN AS $$
BEGIN
    UPDATE voice_call_log
    SET ended_at = NOW(),
        duration_seconds = p_duration_seconds
    WHERE id = (
        SELECT id FROM voice_call_log
        WHERE card_id = p_card_id
            AND session_id = p_session_id
            AND ended_at IS NULL
        ORDER BY started_at DESC
        LIMIT 1
    );

    RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Get voice usage stats
DROP FUNCTION IF EXISTS get_voice_usage_stats_server CASCADE;
CREATE OR REPLACE FUNCTION get_voice_usage_stats_server(
    p_user_id UUID,
    p_start_date TIMESTAMPTZ DEFAULT NULL,
    p_end_date TIMESTAMPTZ DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
    v_total_calls BIGINT;
    v_total_duration BIGINT;
    v_credits_used BIGINT;
    v_balance INTEGER;
BEGIN
    -- Get balance
    SELECT COALESCE(balance, 0) INTO v_balance
    FROM voice_credits
    WHERE user_id = p_user_id;

    -- Get call stats
    SELECT
        COUNT(*),
        COALESCE(SUM(duration_seconds), 0)
    INTO v_total_calls, v_total_duration
    FROM voice_call_log
    WHERE user_id = p_user_id
        AND (p_start_date IS NULL OR started_at >= p_start_date)
        AND (p_end_date IS NULL OR started_at <= p_end_date);

    -- Get credits used
    SELECT COALESCE(SUM(ABS(amount)), 0) INTO v_credits_used
    FROM voice_credit_transactions
    WHERE user_id = p_user_id
        AND type = 'usage'
        AND (p_start_date IS NULL OR created_at >= p_start_date)
        AND (p_end_date IS NULL OR created_at <= p_end_date);

    RETURN jsonb_build_object(
        'balance', COALESCE(v_balance, 0),
        'total_calls', v_total_calls,
        'total_duration_seconds', v_total_duration,
        'credits_used', v_credits_used
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. Get card voice enabled status
DROP FUNCTION IF EXISTS get_card_voice_enabled_server CASCADE;
CREATE OR REPLACE FUNCTION get_card_voice_enabled_server(
    p_card_id UUID
)
RETURNS JSONB AS $$
DECLARE
    v_voice_enabled BOOLEAN;
    v_owner_id UUID;
BEGIN
    SELECT realtime_voice_enabled, user_id
    INTO v_voice_enabled, v_owner_id
    FROM cards
    WHERE id = p_card_id;

    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'found', FALSE,
            'voice_enabled', FALSE,
            'owner_id', NULL
        );
    END IF;

    RETURN jsonb_build_object(
        'found', TRUE,
        'voice_enabled', COALESCE(v_voice_enabled, FALSE),
        'owner_id', v_owner_id
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. Purchase voice credits using credit balance (NOT Stripe)
-- Atomically deducts from user_credits and adds to voice_credits
DROP FUNCTION IF EXISTS purchase_voice_credits_with_credits_server CASCADE;
CREATE OR REPLACE FUNCTION purchase_voice_credits_with_credits_server(
    p_user_id UUID,
    p_package_size INTEGER,   -- number of voice credits to add
    p_credit_cost DECIMAL     -- cost in USD credits to deduct from user_credits balance
)
RETURNS JSONB AS $$
DECLARE
    v_credit_balance DECIMAL;
    v_new_credit_balance DECIMAL;
    v_voice_balance INTEGER;
    v_new_voice_balance INTEGER;
BEGIN
    -- Validate parameters
    IF p_package_size <= 0 THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'error', 'Package size must be greater than 0'
        );
    END IF;

    IF p_credit_cost <= 0 THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'error', 'Credit cost must be greater than 0'
        );
    END IF;

    -- Get current credit balance with lock
    SELECT balance INTO v_credit_balance
    FROM user_credits
    WHERE user_id = p_user_id
    FOR UPDATE;

    IF v_credit_balance IS NULL THEN
        v_credit_balance := 0;
    END IF;

    -- Check sufficient credit balance
    IF v_credit_balance < p_credit_cost THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'error', 'Insufficient credit balance',
            'current_balance', v_credit_balance,
            'required', p_credit_cost
        );
    END IF;

    -- Deduct from user_credits
    v_new_credit_balance := v_credit_balance - p_credit_cost;

    UPDATE user_credits
    SET balance = v_new_credit_balance,
        total_consumed = total_consumed + p_credit_cost,
        updated_at = NOW()
    WHERE user_id = p_user_id;

    -- Record credit consumption
    INSERT INTO credit_consumptions (
        user_id, card_id, quantity, credits_per_unit, total_credits,
        consumption_type, description
    ) VALUES (
        p_user_id, NULL, p_package_size,
        p_credit_cost / p_package_size, p_credit_cost,
        'voice_call',
        format('Purchased %s voice credits for $%s from credit balance', p_package_size, p_credit_cost)
    );

    -- Record credit transaction (debit side)
    INSERT INTO credit_transactions (
        user_id, amount, balance_before, balance_after, type,
        reference_type, description
    ) VALUES (
        p_user_id, -p_credit_cost, v_credit_balance, v_new_credit_balance,
        'consumption', 'voice_credit_purchase',
        format('Voice credit purchase: %s credits for $%s (credit balance: $%s -> $%s)',
               p_package_size, p_credit_cost, v_credit_balance, v_new_credit_balance)
    );

    -- Initialize voice credits if not exists
    INSERT INTO voice_credits (user_id, balance, total_purchased, total_consumed)
    VALUES (p_user_id, 0, 0, 0)
    ON CONFLICT (user_id) DO NOTHING;

    -- Lock and get current voice credit balance
    SELECT balance INTO v_voice_balance
    FROM voice_credits
    WHERE user_id = p_user_id
    FOR UPDATE;

    v_new_voice_balance := v_voice_balance + p_package_size;

    -- Add voice credits
    UPDATE voice_credits
    SET balance = v_new_voice_balance,
        total_purchased = total_purchased + p_package_size,
        updated_at = NOW()
    WHERE user_id = p_user_id;

    -- Record voice credit transaction (credit side)
    INSERT INTO voice_credit_transactions (
        user_id, amount, balance_before, balance_after, type,
        description
    ) VALUES (
        p_user_id, p_package_size, v_voice_balance, v_new_voice_balance, 'purchase',
        format('Purchased %s voice credits using $%s from credit balance', p_package_size, p_credit_cost)
    );

    RETURN jsonb_build_object(
        'success', TRUE,
        'credits_deducted', p_credit_cost,
        'credit_balance_before', v_credit_balance,
        'credit_balance_after', v_new_credit_balance,
        'voice_credits_added', p_package_size,
        'voice_balance_before', v_voice_balance,
        'voice_balance_after', v_new_voice_balance
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =================================================================
-- GRANTS - Only service_role can execute these
-- =================================================================
REVOKE ALL ON FUNCTION get_voice_credit_balance_server FROM PUBLIC, authenticated, anon;
GRANT EXECUTE ON FUNCTION get_voice_credit_balance_server TO service_role;

REVOKE ALL ON FUNCTION deduct_voice_credit_server FROM PUBLIC, authenticated, anon;
GRANT EXECUTE ON FUNCTION deduct_voice_credit_server TO service_role;

REVOKE ALL ON FUNCTION log_voice_call_end_server FROM PUBLIC, authenticated, anon;
GRANT EXECUTE ON FUNCTION log_voice_call_end_server TO service_role;

REVOKE ALL ON FUNCTION get_voice_usage_stats_server FROM PUBLIC, authenticated, anon;
GRANT EXECUTE ON FUNCTION get_voice_usage_stats_server TO service_role;

REVOKE ALL ON FUNCTION get_card_voice_enabled_server FROM PUBLIC, authenticated, anon;
GRANT EXECUTE ON FUNCTION get_card_voice_enabled_server TO service_role;

REVOKE ALL ON FUNCTION purchase_voice_credits_with_credits_server FROM PUBLIC, authenticated, anon;
GRANT EXECUTE ON FUNCTION purchase_voice_credits_with_credits_server TO service_role;
