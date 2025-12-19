-- Migration: Add rate limiting at database level (alternative to Cloudflare)
-- Run this in Supabase SQL Editor

-- ============================================================================
-- 1. RATE LIMIT TRACKING TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS rate_limits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    identifier TEXT NOT NULL,        -- IP address or visitor hash
    endpoint TEXT NOT NULL,          -- e.g., 'digital_card_access'
    request_count INTEGER DEFAULT 1,
    window_start TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Composite index for fast lookups
CREATE INDEX IF NOT EXISTS idx_rate_limits_lookup 
ON rate_limits(identifier, endpoint, window_start);

-- Enable RLS (only service role can access)
ALTER TABLE rate_limits ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Service role only" ON rate_limits
    FOR ALL USING (false);

-- ============================================================================
-- 2. RATE LIMIT CHECK FUNCTION
-- ============================================================================
CREATE OR REPLACE FUNCTION check_rate_limit(
    p_identifier TEXT,           -- Visitor hash or IP
    p_endpoint TEXT,             -- Endpoint name
    p_max_requests INTEGER DEFAULT 30,  -- Max requests per window
    p_window_minutes INTEGER DEFAULT 1  -- Window size in minutes
)
RETURNS JSONB AS $$
DECLARE
    v_window_start TIMESTAMPTZ;
    v_current_count INTEGER;
    v_is_limited BOOLEAN := FALSE;
BEGIN
    v_window_start := NOW() - (p_window_minutes || ' minutes')::INTERVAL;
    
    -- Get or create rate limit record
    SELECT request_count INTO v_current_count
    FROM rate_limits
    WHERE identifier = p_identifier 
      AND endpoint = p_endpoint
      AND window_start > v_window_start
    ORDER BY window_start DESC
    LIMIT 1;
    
    IF v_current_count IS NULL THEN
        -- First request in this window
        INSERT INTO rate_limits (identifier, endpoint, request_count, window_start)
        VALUES (p_identifier, p_endpoint, 1, NOW());
        v_current_count := 1;
    ELSIF v_current_count >= p_max_requests THEN
        -- Rate limit exceeded
        v_is_limited := TRUE;
    ELSE
        -- Increment counter
        UPDATE rate_limits
        SET request_count = request_count + 1
        WHERE identifier = p_identifier 
          AND endpoint = p_endpoint
          AND window_start > v_window_start;
        v_current_count := v_current_count + 1;
    END IF;
    
    RETURN jsonb_build_object(
        'allowed', NOT v_is_limited,
        'current_count', v_current_count,
        'max_requests', p_max_requests,
        'remaining', GREATEST(0, p_max_requests - v_current_count)
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION check_rate_limit(TEXT, TEXT, INTEGER, INTEGER) TO anon, authenticated;

-- ============================================================================
-- 3. CLEANUP FUNCTION (run periodically)
-- ============================================================================
CREATE OR REPLACE FUNCTION cleanup_rate_limits()
RETURNS INTEGER AS $$
DECLARE
    v_deleted INTEGER;
BEGIN
    -- Delete rate limit records older than 1 hour
    DELETE FROM rate_limits 
    WHERE window_start < NOW() - INTERVAL '1 hour';
    
    GET DIAGNOSTICS v_deleted = ROW_COUNT;
    RETURN v_deleted;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- 4. INTEGRATE INTO get_digital_card_content
-- ============================================================================
-- Update the stored procedure to check rate limit before processing
-- (Already handled by deduplication, but this adds extra protection)

-- Example usage in stored procedure:
-- DECLARE v_rate_check JSONB;
-- SELECT check_rate_limit(p_visitor_hash, 'digital_card_access', 30, 1) INTO v_rate_check;
-- IF NOT (v_rate_check->>'allowed')::BOOLEAN THEN
--     RAISE EXCEPTION 'Rate limit exceeded. Please try again later.';
-- END IF;

