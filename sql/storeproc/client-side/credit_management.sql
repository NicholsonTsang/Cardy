-- Credit Management Stored Procedures
-- Client-side functions for credit purchase, consumption, and management

-- Initialize user credits (called when user first needs credits)
CREATE OR REPLACE FUNCTION initialize_user_credits()
RETURNS user_credits AS $$
DECLARE
    v_user_id UUID;
    v_credits user_credits;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    -- Insert or get existing credits record
    INSERT INTO user_credits (user_id, balance, total_purchased, total_consumed)
    VALUES (v_user_id, 0, 0, 0)
    ON CONFLICT (user_id) DO NOTHING
    RETURNING * INTO v_credits;

    IF v_credits.id IS NULL THEN
        SELECT * INTO v_credits FROM user_credits WHERE user_id = v_user_id;
    END IF;

    RETURN v_credits;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get user credit balance
CREATE OR REPLACE FUNCTION get_user_credits()
RETURNS TABLE (
    balance DECIMAL,
    total_purchased DECIMAL,
    total_consumed DECIMAL,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ
) AS $$
DECLARE
    v_user_id UUID;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    -- Initialize credits if not exists
    PERFORM initialize_user_credits();

    RETURN QUERY
    SELECT 
        uc.balance,
        uc.total_purchased,
        uc.total_consumed,
        uc.created_at,
        uc.updated_at
    FROM user_credits uc
    WHERE uc.user_id = v_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Check if user has sufficient credits
CREATE OR REPLACE FUNCTION check_credit_balance(
    p_required_credits DECIMAL,
    p_user_id UUID DEFAULT NULL
)
RETURNS DECIMAL AS $$
DECLARE
    v_user_id UUID;
    v_balance DECIMAL;
BEGIN
    -- Use provided user_id or fall back to auth.uid()
    v_user_id := COALESCE(p_user_id, auth.uid());
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    SELECT balance INTO v_balance
    FROM user_credits
    WHERE user_id = v_user_id;

    IF v_balance IS NULL THEN
        -- Initialize credits if not exists
        PERFORM initialize_user_credits();
        v_balance := 0;
    END IF;

    -- Return the actual balance (not a boolean check)
    RETURN v_balance;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create a pending credit purchase record
CREATE OR REPLACE FUNCTION create_credit_purchase_record(
    p_stripe_session_id VARCHAR,
    p_amount_usd DECIMAL,
    p_credits_amount DECIMAL,
    p_metadata JSONB DEFAULT NULL,
    p_user_id UUID DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_user_id UUID;
    v_purchase_id UUID;
BEGIN
    -- Use provided user_id or fall back to auth.uid()
    v_user_id := COALESCE(p_user_id, auth.uid());
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    -- Insert pending purchase record
    INSERT INTO credit_purchases (
        user_id,
        stripe_session_id,
        amount_usd,
        credits_amount,
        status,
        metadata
    ) VALUES (
        v_user_id,
        p_stripe_session_id,
        p_amount_usd,
        p_credits_amount,
        'pending',
        p_metadata
    )
    RETURNING id INTO v_purchase_id;

    -- Log operation
    PERFORM log_operation(
        format('Credit purchase initiated: %s credits ($%s USD) - Session: %s', 
            p_credits_amount, p_amount_usd, p_stripe_session_id)
    );

    RETURN v_purchase_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Generic function to consume credits
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
    -- Use provided user_id or fall back to auth.uid()
    v_user_id := COALESCE(p_user_id, auth.uid());
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    -- Lock the user credits row for update
    SELECT balance INTO v_current_balance
    FROM user_credits
    WHERE user_id = v_user_id
    FOR UPDATE;

    IF v_current_balance IS NULL OR v_current_balance < p_credits_to_consume THEN
        RAISE EXCEPTION 'Insufficient credits. Required: %, Available: %', 
            p_credits_to_consume, COALESCE(v_current_balance, 0);
    END IF;

    v_new_balance := v_current_balance - p_credits_to_consume;

    -- Update user credits
    UPDATE user_credits
    SET 
        balance = v_new_balance,
        total_consumed = total_consumed + p_credits_to_consume,
        updated_at = CURRENT_TIMESTAMP
    WHERE user_id = v_user_id;

    -- Record consumption (card_id from metadata if available)
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
        format('Credit consumption: %s credits for %s - New balance: %s (Transaction ID: %s)',
            p_credits_to_consume, p_consumption_type, v_new_balance, v_transaction_id)
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Consume credits for batch issuance
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

-- Get credit transaction history
CREATE OR REPLACE FUNCTION get_credit_transactions(
    p_limit INTEGER DEFAULT 50,
    p_offset INTEGER DEFAULT 0,
    p_type VARCHAR DEFAULT NULL
)
RETURNS TABLE (
    id UUID,
    type VARCHAR,
    amount DECIMAL,
    balance_before DECIMAL,
    balance_after DECIMAL,
    reference_type VARCHAR,
    reference_id UUID,
    description TEXT,
    metadata JSONB,
    created_at TIMESTAMPTZ
) AS $$
DECLARE
    v_user_id UUID;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    RETURN QUERY
    SELECT 
        ct.id,
        ct.type,
        ct.amount,
        ct.balance_before,
        ct.balance_after,
        ct.reference_type,
        ct.reference_id,
        ct.description,
        ct.metadata,
        ct.created_at
    FROM credit_transactions ct
    WHERE ct.user_id = v_user_id
        AND (p_type IS NULL OR ct.type = p_type)
    ORDER BY ct.created_at DESC
    LIMIT p_limit
    OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get credit purchase history
CREATE OR REPLACE FUNCTION get_credit_purchases(
    p_limit INTEGER DEFAULT 50,
    p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
    id UUID,
    amount_usd DECIMAL,
    credits_amount DECIMAL,
    status VARCHAR,
    payment_method JSONB,
    receipt_url TEXT,
    created_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ
) AS $$
DECLARE
    v_user_id UUID;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    RETURN QUERY
    SELECT 
        cp.id,
        cp.amount_usd,
        cp.credits_amount,
        cp.status,
        cp.payment_method,
        cp.receipt_url,
        cp.created_at,
        cp.completed_at
    FROM credit_purchases cp
    WHERE cp.user_id = v_user_id
    ORDER BY cp.created_at DESC
    LIMIT p_limit
    OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get credit consumption history
CREATE OR REPLACE FUNCTION get_credit_consumptions(
    p_limit INTEGER DEFAULT 50,
    p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
    id UUID,
    batch_id UUID,
    card_id UUID,
    consumption_type VARCHAR,
    quantity INTEGER,
    credits_per_unit DECIMAL,
    total_credits DECIMAL,
    description TEXT,
    created_at TIMESTAMPTZ,
    batch_name TEXT,
    card_name TEXT
) AS $$
DECLARE
    v_user_id UUID;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    RETURN QUERY
    SELECT 
        cc.id,
        cc.batch_id,
        cc.card_id,
        cc.consumption_type,
        cc.quantity,
        cc.credits_per_unit,
        cc.total_credits,
        cc.description,
        cc.created_at,
        b.batch_name AS batch_name,
        c.name AS card_name
    FROM credit_consumptions cc
    LEFT JOIN card_batches b ON b.id = cc.batch_id
    LEFT JOIN cards c ON c.id = cc.card_id
    WHERE cc.user_id = v_user_id
    ORDER BY cc.created_at DESC
    LIMIT p_limit
    OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create credit purchase record (called from Edge Function after Stripe checkout)
CREATE OR REPLACE FUNCTION create_credit_purchase(
    p_stripe_session_id VARCHAR,
    p_amount_usd DECIMAL,
    p_credits_amount DECIMAL,
    p_metadata JSONB DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_user_id UUID;
    v_purchase_id UUID;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    INSERT INTO credit_purchases (
        user_id, stripe_session_id, amount_usd, credits_amount, 
        status, metadata
    ) VALUES (
        v_user_id, p_stripe_session_id, p_amount_usd, p_credits_amount,
        'pending', p_metadata
    ) RETURNING id INTO v_purchase_id;

    -- Log the operation
    PERFORM log_operation(
        format('Created credit purchase: %s credits ($%s USD) - Session: %s',
            p_credits_amount, p_amount_usd, p_stripe_session_id)
    );

    RETURN v_purchase_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get credit statistics for dashboard
CREATE OR REPLACE FUNCTION get_credit_statistics()
RETURNS JSONB AS $$
DECLARE
    v_user_id UUID;
    v_stats JSONB;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    SELECT jsonb_build_object(
        'current_balance', COALESCE(uc.balance, 0),
        'total_purchased', COALESCE(uc.total_purchased, 0),
        'total_consumed', COALESCE(uc.total_consumed, 0),
        'recent_transactions', (
            SELECT jsonb_agg(
                jsonb_build_object(
                    'id', ct.id,
                    'type', ct.type,
                    'amount', ct.amount,
                    'description', ct.description,
                    'created_at', ct.created_at
                ) ORDER BY ct.created_at DESC
            )
            FROM (
                SELECT * FROM credit_transactions
                WHERE user_id = v_user_id
                ORDER BY created_at DESC
                LIMIT 5
            ) ct
        ),
        'monthly_consumption', (
            SELECT COALESCE(SUM(total_credits), 0)
            FROM credit_consumptions
            WHERE user_id = v_user_id
                AND created_at >= date_trunc('month', CURRENT_DATE)
        ),
        'monthly_purchases', (
            SELECT COALESCE(SUM(credits_amount), 0)
            FROM credit_purchases
            WHERE user_id = v_user_id
                AND status = 'completed'
                AND created_at >= date_trunc('month', CURRENT_DATE)
        )
    ) INTO v_stats
    FROM user_credits uc
    WHERE uc.user_id = v_user_id;

    RETURN COALESCE(v_stats, jsonb_build_object(
        'current_balance', 0,
        'total_purchased', 0,
        'total_consumed', 0,
        'recent_transactions', '[]'::jsonb,
        'monthly_consumption', 0,
        'monthly_purchases', 0
    ));
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================================
-- GRANT PERMISSIONS
-- =====================================================================
-- NOTE: Some functions use a "dual-use pattern" with COALESCE(p_user_id, auth.uid())
-- These can be called from:
--   - Frontend: Without p_user_id, uses auth.uid() from JWT
--   - Edge Functions: With explicit p_user_id parameter using SERVICE_ROLE_KEY
-- =====================================================================

-- Dual-use functions (called from frontend AND Edge Functions with SERVICE_ROLE_KEY)
GRANT EXECUTE ON FUNCTION check_credit_balance(DECIMAL, UUID) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION create_credit_purchase_record(VARCHAR, DECIMAL, DECIMAL, JSONB, UUID) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION consume_credits(DECIMAL, UUID, VARCHAR, JSONB) TO authenticated, service_role;

-- Client-only functions
GRANT EXECUTE ON FUNCTION initialize_user_credits() TO authenticated;
GRANT EXECUTE ON FUNCTION get_credit_statistics() TO authenticated;
GRANT EXECUTE ON FUNCTION get_user_credits() TO authenticated;

-- Add documentation comments
COMMENT ON FUNCTION check_credit_balance(DECIMAL, UUID) IS 
  'DUAL-USE PATTERN: Accepts optional p_user_id (for Edge Functions with SERVICE_ROLE_KEY) or falls back to auth.uid() (for frontend with user JWT). Granted to both authenticated and service_role roles.';
  
COMMENT ON FUNCTION create_credit_purchase_record(VARCHAR, DECIMAL, DECIMAL, JSONB, UUID) IS 
  'DUAL-USE PATTERN: Accepts optional p_user_id (for Edge Functions with SERVICE_ROLE_KEY) or falls back to auth.uid() (for frontend with user JWT). Granted to both authenticated and service_role roles. Called by create-credit-checkout-session Edge Function.';
  
COMMENT ON FUNCTION consume_credits(DECIMAL, UUID, VARCHAR, JSONB) IS 
  'DUAL-USE PATTERN: Accepts optional p_user_id (for server-side stored procedures) or falls back to auth.uid() (for direct frontend calls). Granted to both authenticated and service_role roles.';

COMMENT ON FUNCTION initialize_user_credits() IS 
  'CLIENT-ONLY: Uses auth.uid() from user JWT. Creates initial credit record for authenticated user.';

COMMENT ON FUNCTION get_credit_statistics() IS 
  'CLIENT-ONLY: Uses auth.uid() from user JWT. Returns credit statistics for authenticated user including balance, purchases, consumptions.';

COMMENT ON FUNCTION get_user_credits() IS 
  'CLIENT-ONLY: Uses auth.uid() from user JWT. Returns current credit balance for authenticated user.';

