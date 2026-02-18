-- =====================================================
-- Access Token Management Stored Procedures
-- Client-side procedures for managing QR codes per project
-- =====================================================

-- Generate a unique 12-character URL-safe access token
CREATE OR REPLACE FUNCTION generate_access_token()
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
    v_token TEXT;
    v_exists BOOLEAN;
BEGIN
    LOOP
        -- Generate 12 character alphanumeric token from UUID (URL-safe, no extension required)
        v_token := substring(replace(gen_random_uuid()::text, '-', ''), 1, 12);
        
        -- Check if token already exists
        SELECT EXISTS(SELECT 1 FROM card_access_tokens WHERE access_token = v_token) INTO v_exists;
        
        IF NOT v_exists THEN
            RETURN v_token;
        END IF;
    END LOOP;
END;
$$;

-- Create a new access token (QR code) for a card
CREATE OR REPLACE FUNCTION create_access_token(
    p_card_id UUID,
    p_name TEXT DEFAULT 'Default',
    p_daily_session_limit INTEGER DEFAULT NULL,
    p_monthly_session_limit INTEGER DEFAULT NULL,
    p_daily_voice_limit INTEGER DEFAULT NULL,
    p_monthly_voice_limit INTEGER DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_card_owner_id UUID;
    v_new_token TEXT;
    v_token_id UUID;
    v_default_session_limit INTEGER;
    v_default_voice_limit INTEGER;
BEGIN
    -- Get current user
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    -- Verify card ownership and get default limits
    SELECT user_id, default_daily_session_limit, default_daily_voice_limit
    INTO v_card_owner_id, v_default_session_limit, v_default_voice_limit
    FROM cards
    WHERE id = p_card_id;

    IF v_card_owner_id IS NULL THEN
        RAISE EXCEPTION 'Card not found';
    END IF;

    IF v_card_owner_id != v_user_id THEN
        RAISE EXCEPTION 'Not authorized';
    END IF;

    -- Generate unique token
    v_new_token := generate_access_token();

    -- Use provided limit or fall back to card defaults
    IF p_daily_session_limit IS NULL THEN
        p_daily_session_limit := v_default_session_limit;
    END IF;

    IF p_daily_voice_limit IS NULL THEN
        p_daily_voice_limit := v_default_voice_limit;
    END IF;

    -- Create the access token
    INSERT INTO card_access_tokens (
        card_id,
        name,
        access_token,
        daily_session_limit,
        monthly_session_limit,
        daily_voice_limit,
        monthly_voice_limit
    ) VALUES (
        p_card_id,
        COALESCE(p_name, 'Default'),
        v_new_token,
        p_daily_session_limit,
        p_monthly_session_limit,
        p_daily_voice_limit,
        p_monthly_voice_limit
    )
    RETURNING id INTO v_token_id;

    RETURN jsonb_build_object(
        'success', true,
        'token_id', v_token_id,
        'access_token', v_new_token,
        'name', COALESCE(p_name, 'Default')
    );
END;
$$;

-- Get all access tokens for a card
CREATE OR REPLACE FUNCTION get_card_access_tokens(p_card_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_card_owner_id UUID;
    v_tokens JSONB;
BEGIN
    -- Get current user
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;
    
    -- Verify card ownership
    SELECT user_id INTO v_card_owner_id
    FROM cards 
    WHERE id = p_card_id;
    
    IF v_card_owner_id IS NULL THEN
        RAISE EXCEPTION 'Card not found';
    END IF;
    
    IF v_card_owner_id != v_user_id THEN
        -- Check if user is admin
        IF NOT EXISTS (
            SELECT 1 FROM auth.users 
            WHERE id = v_user_id 
            AND (raw_app_meta_data->>'role' = 'admin' OR raw_user_meta_data->>'role' = 'admin')
        ) THEN
            RAISE EXCEPTION 'Not authorized';
        END IF;
    END IF;
    
    -- Get all tokens for the card
    SELECT COALESCE(jsonb_agg(
        jsonb_build_object(
            'id', t.id,
            'name', t.name,
            'access_token', t.access_token,
            'is_enabled', t.is_enabled,
            'daily_session_limit', t.daily_session_limit,
            'monthly_session_limit', t.monthly_session_limit,
            'daily_voice_limit', t.daily_voice_limit,
            'monthly_voice_limit', t.monthly_voice_limit,
            'total_sessions', t.total_sessions,
            'daily_sessions', t.daily_sessions,
            'monthly_sessions', t.monthly_sessions,
            'last_session_date', t.last_session_date,
            'current_month', t.current_month,
            'created_at', t.created_at,
            'updated_at', t.updated_at
        ) ORDER BY t.created_at ASC
    ), '[]'::jsonb) INTO v_tokens
    FROM card_access_tokens t
    WHERE t.card_id = p_card_id;
    
    RETURN v_tokens;
END;
$$;

-- Update an access token's settings
CREATE OR REPLACE FUNCTION update_access_token(
    p_token_id UUID,
    p_name TEXT DEFAULT NULL,
    p_is_enabled BOOLEAN DEFAULT NULL,
    p_daily_session_limit INTEGER DEFAULT NULL,
    p_monthly_session_limit INTEGER DEFAULT NULL,
    p_daily_voice_limit INTEGER DEFAULT NULL,
    p_monthly_voice_limit INTEGER DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_card_owner_id UUID;
    v_card_id UUID;
BEGIN
    -- Get current user
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    -- Get card_id and verify ownership
    SELECT t.card_id, c.user_id
    INTO v_card_id, v_card_owner_id
    FROM card_access_tokens t
    JOIN cards c ON c.id = t.card_id
    WHERE t.id = p_token_id;

    IF v_card_id IS NULL THEN
        RAISE EXCEPTION 'Token not found';
    END IF;

    IF v_card_owner_id != v_user_id THEN
        RAISE EXCEPTION 'Not authorized';
    END IF;

    -- Update the token (-1 sentinel = set to NULL/unlimited)
    UPDATE card_access_tokens
    SET
        name = COALESCE(p_name, name),
        is_enabled = COALESCE(p_is_enabled, is_enabled),
        daily_session_limit = CASE
            WHEN p_daily_session_limit = -1 THEN NULL
            WHEN p_daily_session_limit IS NOT NULL THEN p_daily_session_limit
            ELSE daily_session_limit
        END,
        monthly_session_limit = CASE
            WHEN p_monthly_session_limit = -1 THEN NULL
            WHEN p_monthly_session_limit IS NOT NULL THEN p_monthly_session_limit
            ELSE monthly_session_limit
        END,
        daily_voice_limit = CASE
            WHEN p_daily_voice_limit = -1 THEN NULL
            WHEN p_daily_voice_limit IS NOT NULL THEN p_daily_voice_limit
            ELSE daily_voice_limit
        END,
        monthly_voice_limit = CASE
            WHEN p_monthly_voice_limit = -1 THEN NULL
            WHEN p_monthly_voice_limit IS NOT NULL THEN p_monthly_voice_limit
            ELSE monthly_voice_limit
        END,
        updated_at = NOW()
    WHERE id = p_token_id;

    RETURN jsonb_build_object('success', true);
END;
$$;

-- Delete an access token
CREATE OR REPLACE FUNCTION delete_access_token(p_token_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_card_owner_id UUID;
    v_token_count INTEGER;
    v_card_id UUID;
BEGIN
    -- Get current user
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;
    
    -- Get card_id and verify ownership
    SELECT t.card_id, c.user_id 
    INTO v_card_id, v_card_owner_id
    FROM card_access_tokens t
    JOIN cards c ON c.id = t.card_id
    WHERE t.id = p_token_id;
    
    IF v_card_id IS NULL THEN
        RAISE EXCEPTION 'Token not found';
    END IF;
    
    IF v_card_owner_id != v_user_id THEN
        RAISE EXCEPTION 'Not authorized';
    END IF;
    
    -- Check if this is the last token (prevent deleting all tokens)
    SELECT COUNT(*) INTO v_token_count
    FROM card_access_tokens
    WHERE card_id = v_card_id;
    
    IF v_token_count <= 1 THEN
        RAISE EXCEPTION 'Cannot delete the last QR code. Each project must have at least one QR code.';
    END IF;
    
    -- Delete the token
    DELETE FROM card_access_tokens WHERE id = p_token_id;
    
    RETURN jsonb_build_object('success', true);
END;
$$;

-- Refresh (regenerate) an access token
CREATE OR REPLACE FUNCTION refresh_access_token(p_token_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_card_owner_id UUID;
    v_new_token TEXT;
BEGIN
    -- Get current user
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;
    
    -- Verify ownership
    SELECT c.user_id INTO v_card_owner_id
    FROM card_access_tokens t
    JOIN cards c ON c.id = t.card_id
    WHERE t.id = p_token_id;
    
    IF v_card_owner_id IS NULL THEN
        RAISE EXCEPTION 'Token not found';
    END IF;
    
    IF v_card_owner_id != v_user_id THEN
        RAISE EXCEPTION 'Not authorized';
    END IF;
    
    -- Generate new token
    v_new_token := generate_access_token();
    
    -- Update the token
    UPDATE card_access_tokens
    SET 
        access_token = v_new_token,
        updated_at = NOW()
    WHERE id = p_token_id;
    
    RETURN jsonb_build_object(
        'success', true,
        'access_token', v_new_token
    );
END;
$$;

-- Get monthly session stats for all tokens of a card
-- Returns data for the current billing month (1st to end of month)
CREATE OR REPLACE FUNCTION get_card_monthly_stats(p_card_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_card_owner_id UUID;
    v_current_month_start DATE;
    v_stats JSONB;
BEGIN
    -- Get current user
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;
    
    -- Verify card ownership
    SELECT user_id INTO v_card_owner_id
    FROM cards 
    WHERE id = p_card_id;
    
    IF v_card_owner_id IS NULL THEN
        RAISE EXCEPTION 'Card not found';
    END IF;
    
    IF v_card_owner_id != v_user_id THEN
        RAISE EXCEPTION 'Not authorized';
    END IF;
    
    -- Get current month start (1st of this month)
    v_current_month_start := date_trunc('month', CURRENT_DATE)::DATE;
    
    -- Aggregate stats
    SELECT jsonb_build_object(
        'month_start', v_current_month_start,
        'month_end', (v_current_month_start + INTERVAL '1 month' - INTERVAL '1 day')::DATE,
        'total_monthly_sessions', COALESCE(SUM(
            CASE WHEN current_month = v_current_month_start THEN monthly_sessions ELSE 0 END
        ), 0),
        'total_daily_sessions', COALESCE(SUM(
            CASE WHEN last_session_date = CURRENT_DATE THEN daily_sessions ELSE 0 END
        ), 0),
        'total_all_time_sessions', COALESCE(SUM(total_sessions), 0),
        'active_qr_codes', COUNT(*) FILTER (WHERE is_enabled = true),
        'total_qr_codes', COUNT(*)
    ) INTO v_stats
    FROM card_access_tokens
    WHERE card_id = p_card_id;
    
    RETURN v_stats;
END;
$$;

-- Note: Access token auto-creation is handled in create_card function
-- No trigger needed since all card creation goes through create_card
-- The delete_access_token function prevents deleting the last QR code

-- Drop legacy trigger if exists (cleanup)
DROP TRIGGER IF EXISTS trigger_ensure_access_token ON cards;
DROP FUNCTION IF EXISTS ensure_card_has_access_token() CASCADE;
DROP FUNCTION IF EXISTS migrate_legacy_access_tokens() CASCADE;

-- Grant permissions
GRANT EXECUTE ON FUNCTION generate_access_token() TO authenticated;
GRANT EXECUTE ON FUNCTION create_access_token(UUID, TEXT, INTEGER, INTEGER, INTEGER, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION get_card_access_tokens(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION update_access_token(UUID, TEXT, BOOLEAN, INTEGER, INTEGER, INTEGER, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION delete_access_token(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION refresh_access_token(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_card_monthly_stats(UUID) TO authenticated;

