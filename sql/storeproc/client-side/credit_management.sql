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
    card_id UUID,
    consumption_type VARCHAR,
    quantity INTEGER,
    credits_per_unit DECIMAL,
    total_credits DECIMAL,
    description TEXT,
    created_at TIMESTAMPTZ,
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
        cc.card_id,
        cc.consumption_type,
        cc.quantity,
        cc.credits_per_unit,
        cc.total_credits,
        cc.description,
        cc.created_at,
        c.name AS card_name
    FROM credit_consumptions cc
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
-- DIGITAL ACCESS CREDIT CONSUMPTION
-- =====================================================================
-- Consume credits for digital access scan with DAILY AGGREGATION
-- Called internally by get_public_card_content when a non-owner accesses a digital card
-- 
-- BEST PRACTICE: Instead of creating a new record per scan (fragmented),
-- we aggregate all scans for the same card on the same day into ONE record.
-- This reduces 1000 scans/day from 2000 records to just 2 records!
--
-- Daily Aggregation Logic:
-- 1. First scan of day for a card → INSERT new consumption record
-- 2. Subsequent scans → UPDATE existing record (increment quantity & total)
-- 3. Transaction log: One entry per day per card (updated in place)
--
-- Returns JSONB with success status and error details
CREATE OR REPLACE FUNCTION consume_credit_for_digital_scan(
    p_card_id UUID,
    p_owner_id UUID,
    p_credit_rate DECIMAL DEFAULT 0.03
)
RETURNS JSONB AS $$
DECLARE
    v_current_balance DECIMAL;
    v_new_balance DECIMAL;
    v_consumption_id UUID;
    v_transaction_id UUID;
    v_card_name TEXT;
    v_today DATE := CURRENT_DATE;
    v_existing_consumption_id UUID;
    v_existing_transaction_id UUID;
    v_existing_quantity INT;
    v_existing_total_credits DECIMAL;
    v_balance_before_today DECIMAL;
BEGIN
    -- Get card name for logging
    SELECT name INTO v_card_name FROM cards WHERE id = p_card_id;

    -- Lock the owner's credits row for update
    SELECT balance INTO v_current_balance
    FROM user_credits
    WHERE user_id = p_owner_id
    FOR UPDATE;

    -- Check if owner has credits initialized
    IF v_current_balance IS NULL THEN
        -- Try to initialize credits for owner
        INSERT INTO user_credits (user_id, balance, total_purchased, total_consumed)
        VALUES (p_owner_id, 0, 0, 0)
        ON CONFLICT (user_id) DO NOTHING;
        
        SELECT balance INTO v_current_balance
        FROM user_credits
        WHERE user_id = p_owner_id;
        
        IF v_current_balance IS NULL THEN
            v_current_balance := 0;
        END IF;
    END IF;

    -- Check if owner has sufficient credits
    IF v_current_balance < p_credit_rate THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'credits_insufficient',
            'message', 'Card owner has insufficient credits',
            'required', p_credit_rate,
            'available', v_current_balance
        );
    END IF;

    v_new_balance := v_current_balance - p_credit_rate;

    -- Update owner's credits (real-time balance update)
    UPDATE user_credits
    SET 
        balance = v_new_balance,
        total_consumed = total_consumed + p_credit_rate,
        updated_at = CURRENT_TIMESTAMP
    WHERE user_id = p_owner_id;

    -- ===== DAILY AGGREGATION FOR CONSUMPTIONS =====
    -- Check if there's already a consumption record for this card today
    SELECT id, quantity, total_credits INTO v_existing_consumption_id, v_existing_quantity, v_existing_total_credits
    FROM credit_consumptions
    WHERE user_id = p_owner_id 
      AND card_id = p_card_id 
      AND consumption_type = 'digital_scan'
      AND DATE(created_at) = v_today
    LIMIT 1;

    IF v_existing_consumption_id IS NOT NULL THEN
        -- UPDATE existing record (aggregate scans)
        UPDATE credit_consumptions
        SET 
            quantity = v_existing_quantity + 1,
            total_credits = v_existing_total_credits + p_credit_rate,
            description = format('Digital access: %s (%s scans today)', 
                                 COALESCE(v_card_name, p_card_id::TEXT), 
                                 v_existing_quantity + 1),
            updated_at = CURRENT_TIMESTAMP
        WHERE id = v_existing_consumption_id;
        
        v_consumption_id := v_existing_consumption_id;
    ELSE
        -- INSERT new record for today (first scan)
        INSERT INTO credit_consumptions (
            user_id, card_id, consumption_type, quantity, 
            credits_per_unit, total_credits, description
        ) VALUES (
            p_owner_id, p_card_id, 'digital_scan', 1,
            p_credit_rate, p_credit_rate,
            format('Digital access: %s (1 scan today)', COALESCE(v_card_name, p_card_id::TEXT))
        ) RETURNING id INTO v_consumption_id;
    END IF;

    -- ===== DAILY AGGREGATION FOR TRANSACTIONS =====
    -- Check if there's already a transaction record for this card today
    SELECT id, amount, balance_before INTO v_existing_transaction_id, v_existing_total_credits, v_balance_before_today
    FROM credit_transactions
    WHERE user_id = p_owner_id 
      AND reference_type = 'digital_scan'
      AND reference_id = p_card_id
      AND DATE(created_at) = v_today
      AND type = 'consumption'
    LIMIT 1;

    IF v_existing_transaction_id IS NOT NULL THEN
        -- UPDATE existing transaction (aggregate daily spend)
        UPDATE credit_transactions
        SET 
            amount = v_existing_total_credits + p_credit_rate,
            balance_after = v_new_balance,
            description = format('Digital access: %s (%s credits today)', 
                                 COALESCE(v_card_name, 'Card'), 
                                 ROUND(v_existing_total_credits + p_credit_rate, 2)::TEXT),
            updated_at = CURRENT_TIMESTAMP
        WHERE id = v_existing_transaction_id;
        
        v_transaction_id := v_existing_transaction_id;
    ELSE
        -- INSERT new transaction for today (first scan)
        INSERT INTO credit_transactions (
            user_id, type, amount, balance_before, balance_after,
            reference_type, reference_id, description
        ) VALUES (
            p_owner_id, 'consumption', p_credit_rate, v_current_balance, v_new_balance,
            'digital_scan', p_card_id,
            format('Digital access: %s (%s credits today)', COALESCE(v_card_name, 'Card'), ROUND(p_credit_rate, 2)::TEXT)
        ) RETURNING id INTO v_transaction_id;
    END IF;

    RETURN jsonb_build_object(
        'success', true,
        'consumption_id', v_consumption_id,
        'transaction_id', v_transaction_id,
        'credits_consumed', p_credit_rate,
        'new_balance', v_new_balance,
        'aggregation', 'daily'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute to service_role (called internally by get_public_card_content)
GRANT EXECUTE ON FUNCTION consume_credit_for_digital_scan(UUID, UUID, DECIMAL) TO service_role, authenticated;

COMMENT ON FUNCTION consume_credit_for_digital_scan(UUID, UUID, DECIMAL) IS 
  'Consumes credits from card owner for digital access scan with DAILY AGGREGATION. 
   Instead of creating one record per scan, aggregates all scans for the same card 
   on the same day into a single record. This prevents table fragmentation and keeps 
   the credit management UI clean. Called internally by get_public_card_content.';

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
GRANT EXECUTE ON FUNCTION consume_credits(DECIMAL, UUID, VARCHAR, JSONB) TO authenticated, service_role;
-- Note: create_credit_purchase_record is server-side only (see server-side/credit_purchase_completion.sql)

-- Client-only functions
GRANT EXECUTE ON FUNCTION initialize_user_credits() TO authenticated;
GRANT EXECUTE ON FUNCTION get_credit_statistics() TO authenticated;
GRANT EXECUTE ON FUNCTION get_user_credits() TO authenticated;

-- Add documentation comments
COMMENT ON FUNCTION check_credit_balance(DECIMAL, UUID) IS 
  'DUAL-USE PATTERN: Accepts optional p_user_id (for Edge Functions with SERVICE_ROLE_KEY) or falls back to auth.uid() (for frontend with user JWT). Granted to both authenticated and service_role roles.';

-- Note: create_credit_purchase_record is server-side only (see server-side/credit_purchase_completion.sql)
-- It requires explicit p_user_id and is only accessible via service_role (backend)
  
COMMENT ON FUNCTION consume_credits(DECIMAL, UUID, VARCHAR, JSONB) IS 
  'DUAL-USE PATTERN: Accepts optional p_user_id (for server-side stored procedures) or falls back to auth.uid() (for direct frontend calls). Granted to both authenticated and service_role roles.';

COMMENT ON FUNCTION initialize_user_credits() IS 
  'CLIENT-ONLY: Uses auth.uid() from user JWT. Creates initial credit record for authenticated user.';

COMMENT ON FUNCTION get_credit_statistics() IS 
  'CLIENT-ONLY: Uses auth.uid() from user JWT. Returns credit statistics for authenticated user including balance, purchases, consumptions.';

COMMENT ON FUNCTION get_user_credits() IS 
  'CLIENT-ONLY: Uses auth.uid() from user JWT. Returns current credit balance for authenticated user.';


