-- Migration: Add scan deduplication to prevent multiple credit charges for same visitor
-- Run this in Supabase SQL Editor

-- ============================================================================
-- 1. CREATE ACCESS LOG TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS card_access_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    card_id UUID NOT NULL REFERENCES cards(id) ON DELETE CASCADE,
    visitor_hash TEXT NOT NULL, -- Hash of IP or session identifier
    accessed_at TIMESTAMPTZ DEFAULT NOW(),
    credit_charged BOOLEAN DEFAULT FALSE,
    is_owner_access BOOLEAN DEFAULT FALSE
);

-- Index for fast deduplication lookups
CREATE INDEX IF NOT EXISTS idx_card_access_log_dedup 
ON card_access_log(card_id, visitor_hash, accessed_at DESC);

-- Index for cleanup job
CREATE INDEX IF NOT EXISTS idx_card_access_log_cleanup 
ON card_access_log(accessed_at);

-- Enable RLS
ALTER TABLE card_access_log ENABLE ROW LEVEL SECURITY;

-- Policy: Only service role can access (used by stored procedures with SECURITY DEFINER)
CREATE POLICY "Service role only" ON card_access_log
    FOR ALL USING (false);

-- ============================================================================
-- 2. CLEANUP FUNCTION (run periodically)
-- ============================================================================
CREATE OR REPLACE FUNCTION cleanup_old_access_logs()
RETURNS INTEGER AS $$
DECLARE
    v_deleted INTEGER;
BEGIN
    -- Delete access logs older than 24 hours
    DELETE FROM card_access_log 
    WHERE accessed_at < NOW() - INTERVAL '24 hours';
    
    GET DIAGNOSTICS v_deleted = ROW_COUNT;
    RETURN v_deleted;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- 3. DEDUPLICATION WINDOW CONSTANT
-- ============================================================================
-- 5 minutes = same visitor accessing same card within 5 min = 1 scan
-- Adjust this value as needed

-- ============================================================================
-- 4. UPDATED get_digital_card_content WITH DEDUPLICATION
-- ============================================================================
CREATE OR REPLACE FUNCTION get_digital_card_content(
    p_access_token TEXT,
    p_language VARCHAR(10) DEFAULT 'en',
    p_visitor_hash TEXT DEFAULT NULL  -- NEW: Optional visitor identifier
)
RETURNS TABLE (
    card_name TEXT,
    card_description TEXT,
    card_image_url TEXT,
    card_crop_parameters JSONB,
    card_conversation_ai_enabled BOOLEAN,
    card_ai_instruction TEXT,
    card_ai_knowledge_base TEXT,
    card_ai_welcome_general TEXT,
    card_ai_welcome_item TEXT,
    card_original_language VARCHAR(10),
    card_has_translation BOOLEAN,
    card_available_languages TEXT[],
    card_content_mode TEXT,
    card_is_grouped BOOLEAN,
    card_group_display TEXT,
    card_billing_type TEXT,
    card_max_scans INTEGER,
    card_current_scans INTEGER,
    card_daily_scan_limit INTEGER,
    card_daily_scans INTEGER,
    card_scan_limit_reached BOOLEAN,
    card_daily_limit_exceeded BOOLEAN,
    card_credits_insufficient BOOLEAN,
    card_access_disabled BOOLEAN,
    content_item_id UUID,
    content_item_parent_id UUID,
    content_item_name TEXT,
    content_item_content TEXT,
    content_item_image_url TEXT,
    content_item_ai_knowledge_base TEXT,
    content_item_sort_order INTEGER,
    crop_parameters JSONB
) LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    -- SECURITY: Hardcoded credit rate to prevent bypass attacks
    CREDIT_RATE CONSTANT DECIMAL := 0.03;
    -- Deduplication window: 5 minutes
    DEDUP_WINDOW CONSTANT INTERVAL := INTERVAL '5 minutes';
    
    v_card_id UUID;
    v_card_owner_id UUID;
    v_caller_id UUID;
    v_is_owner_access BOOLEAN := FALSE;
    v_is_access_enabled BOOLEAN;
    v_max_scans INTEGER;
    v_current_scans INTEGER;
    v_daily_scan_limit INTEGER;
    v_daily_scans INTEGER;
    v_last_scan_date DATE;
    v_scan_limit_reached BOOLEAN := FALSE;
    v_daily_limit_exceeded BOOLEAN := FALSE;
    v_credits_insufficient BOOLEAN := FALSE;
    v_access_disabled BOOLEAN := FALSE;
    v_credit_result JSONB;
    v_recent_access_exists BOOLEAN := FALSE;
    v_effective_visitor_hash TEXT;
BEGIN
    -- Get caller's user ID
    v_caller_id := auth.uid();
    
    -- Find card by access token (must be a digital card)
    SELECT id, user_id, is_access_enabled, max_scans, current_scans,
           daily_scan_limit, daily_scans, last_scan_date
    INTO v_card_id, v_card_owner_id, v_is_access_enabled, v_max_scans, v_current_scans,
         v_daily_scan_limit, v_daily_scans, v_last_scan_date
    FROM cards
    WHERE access_token = p_access_token AND billing_type = 'digital';
    
    IF NOT FOUND THEN
        -- Invalid or expired token
        RETURN;
    END IF;
    
    -- Check if caller is the card owner
    IF v_caller_id IS NOT NULL AND v_caller_id = v_card_owner_id THEN
        v_is_owner_access := TRUE;
    END IF;
    
    -- Check if access is enabled (owners can always access)
    IF NOT v_is_access_enabled AND NOT v_is_owner_access THEN
        v_access_disabled := TRUE;
        -- Return with access_disabled flag but no content
        RETURN QUERY
        SELECT 
            NULL::TEXT, NULL::TEXT, NULL::TEXT, NULL::JSONB, NULL::BOOLEAN, 
            NULL::TEXT, NULL::TEXT, NULL::TEXT, NULL::TEXT, NULL::VARCHAR(10), 
            NULL::BOOLEAN, NULL::TEXT[], NULL::TEXT, NULL::BOOLEAN, NULL::TEXT,
            NULL::TEXT, NULL::INTEGER, NULL::INTEGER, NULL::INTEGER, NULL::INTEGER,
            FALSE, FALSE, FALSE, TRUE,
            NULL::UUID, NULL::UUID, NULL::TEXT, NULL::TEXT, NULL::TEXT, NULL::TEXT,
            NULL::INTEGER, NULL::JSONB;
        RETURN;
    END IF;
    
    -- For non-owner access, handle scan counting and credit consumption
    IF NOT v_is_owner_access THEN
        -- Generate effective visitor hash (use provided hash or generate from caller_id)
        v_effective_visitor_hash := COALESCE(
            p_visitor_hash, 
            COALESCE(v_caller_id::TEXT, 'anon-' || md5(random()::TEXT))
        );
        
        -- ============================================================
        -- DEDUPLICATION CHECK: Has this visitor accessed recently?
        -- ============================================================
        SELECT EXISTS(
            SELECT 1 FROM card_access_log
            WHERE card_id = v_card_id
              AND visitor_hash = v_effective_visitor_hash
              AND accessed_at > NOW() - DEDUP_WINDOW
        ) INTO v_recent_access_exists;
        
        -- Log this access attempt (regardless of dedup result)
        INSERT INTO card_access_log (card_id, visitor_hash, credit_charged, is_owner_access)
        VALUES (v_card_id, v_effective_visitor_hash, NOT v_recent_access_exists, FALSE);
        
        -- If recent access exists, skip credit consumption but still return content
        IF v_recent_access_exists THEN
            -- No credit charge, just return content
            NULL; -- Continue to RETURN QUERY below
        ELSE
            -- Reset daily counter if it's a new day
            IF v_last_scan_date IS NULL OR v_last_scan_date < CURRENT_DATE THEN
                UPDATE cards 
                SET daily_scans = 0, last_scan_date = CURRENT_DATE 
                WHERE id = v_card_id;
                v_daily_scans := 0;
            END IF;
            
            -- Check total scan limit
            IF v_max_scans IS NOT NULL AND v_current_scans >= v_max_scans THEN
                v_scan_limit_reached := TRUE;
            -- Check daily scan limit
            ELSIF v_daily_scan_limit IS NOT NULL AND v_daily_scans >= v_daily_scan_limit THEN
                v_daily_limit_exceeded := TRUE;
            ELSE
                -- Try to consume credit from card owner (using hardcoded rate)
                SELECT consume_credit_for_digital_scan(v_card_id, v_card_owner_id, CREDIT_RATE)
                INTO v_credit_result;
                
                IF (v_credit_result->>'success')::BOOLEAN = FALSE THEN
                    v_credits_insufficient := TRUE;
                ELSE
                    -- Credit consumed successfully, increment counters
                    BEGIN
                        UPDATE cards 
                        SET current_scans = current_scans + 1,
                            daily_scans = daily_scans + 1,
                            last_scan_date = CURRENT_DATE
                        WHERE id = v_card_id;
                        v_current_scans := v_current_scans + 1;
                        v_daily_scans := v_daily_scans + 1;
                    EXCEPTION
                        WHEN others THEN NULL;
                    END;
                END IF;
            END IF;
        END IF;
    END IF;
    
    -- Return card content
    RETURN QUERY
    SELECT 
        COALESCE(c.translations->p_language->>'name', c.name)::TEXT AS card_name,
        COALESCE(c.translations->p_language->>'description', c.description)::TEXT AS card_description,
        c.image_url AS card_image_url,
        c.crop_parameters AS card_crop_parameters,
        c.conversation_ai_enabled AS card_conversation_ai_enabled,
        c.ai_instruction AS card_ai_instruction,
        c.ai_knowledge_base AS card_ai_knowledge_base,
        c.ai_welcome_general AS card_ai_welcome_general,
        c.ai_welcome_item AS card_ai_welcome_item,
        c.original_language::VARCHAR(10) AS card_original_language,
        (c.translations ? p_language)::BOOLEAN AS card_has_translation,
        (ARRAY[c.original_language] || ARRAY(SELECT jsonb_object_keys(c.translations)))::TEXT[] AS card_available_languages,
        COALESCE(c.content_mode, 'list')::TEXT AS card_content_mode,
        COALESCE(c.is_grouped, FALSE)::BOOLEAN AS card_is_grouped,
        COALESCE(c.group_display, 'expanded')::TEXT AS card_group_display,
        'digital'::TEXT AS card_billing_type,
        c.max_scans AS card_max_scans,
        v_current_scans AS card_current_scans,
        c.daily_scan_limit AS card_daily_scan_limit,
        v_daily_scans AS card_daily_scans,
        v_scan_limit_reached AS card_scan_limit_reached,
        v_daily_limit_exceeded AS card_daily_limit_exceeded,
        v_credits_insufficient AS card_credits_insufficient,
        v_access_disabled AS card_access_disabled,
        ci.id AS content_item_id,
        ci.parent_id AS content_item_parent_id,
        COALESCE(ci.translations->p_language->>'name', ci.name)::TEXT AS content_item_name,
        COALESCE(ci.translations->p_language->>'content', ci.content)::TEXT AS content_item_content,
        ci.image_url AS content_item_image_url,
        ci.ai_knowledge_base AS content_item_ai_knowledge_base,
        ci.sort_order AS content_item_sort_order,
        ci.crop_parameters
    FROM cards c
    LEFT JOIN content_items ci ON ci.card_id = c.id
    WHERE c.id = v_card_id
    ORDER BY 
        CASE WHEN ci.parent_id IS NULL THEN 0 ELSE 1 END,
        ci.sort_order;
END;
$$;

-- Grant execute to both anon and authenticated users
GRANT EXECUTE ON FUNCTION get_digital_card_content(TEXT, VARCHAR, TEXT) TO anon, authenticated;
-- Keep backward compatibility for calls without visitor_hash
GRANT EXECUTE ON FUNCTION get_digital_card_content(TEXT, VARCHAR) TO anon, authenticated;

-- ============================================================================
-- 5. SCHEDULED CLEANUP (optional - run via Supabase Edge Function or cron)
-- ============================================================================
-- Call cleanup_old_access_logs() daily to remove old records
-- Example: SELECT cleanup_old_access_logs();


