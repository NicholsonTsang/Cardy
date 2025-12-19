-- =================================================================
-- PUBLIC CARD ACCESS FUNCTIONS
-- Functions for public card access and mobile preview
-- =================================================================

-- Get public card content by issue card ID
-- Updated to support translations via p_language parameter
-- Updated to include billing_type for routing and scan tracking
-- Updated to include daily limit checking and real-time credit consumption for digital access
-- SECURITY: Credit rate is hardcoded to prevent bypass attacks
CREATE OR REPLACE FUNCTION get_public_card_content(
    p_issue_card_id UUID,
    p_language VARCHAR(10) DEFAULT 'en'
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
    card_available_languages TEXT[], -- Array of available language codes
    card_content_mode TEXT, -- Content rendering mode (single, grid, list, cards)
    card_is_grouped BOOLEAN, -- Whether content is organized into categories
    card_group_display TEXT, -- How grouped items display: expanded or collapsed
    card_billing_type TEXT, -- Billing model: physical or digital
    card_max_scans INTEGER, -- NULL for physical (unlimited), Integer for digital (total limit)
    card_current_scans INTEGER, -- Current total scan count
    card_daily_scan_limit INTEGER, -- Daily scan limit (NULL = unlimited)
    card_daily_scans INTEGER, -- Today's scan count
    card_scan_limit_reached BOOLEAN, -- TRUE if digital card has reached total scan limit
    card_daily_limit_exceeded BOOLEAN, -- TRUE if digital card has reached daily limit
    card_credits_insufficient BOOLEAN, -- TRUE if card owner has insufficient credits
    content_item_id UUID,
    content_item_parent_id UUID,
    content_item_name TEXT,
    content_item_content TEXT,
    content_item_image_url TEXT,
    content_item_ai_knowledge_base TEXT,
    content_item_sort_order INTEGER,
    crop_parameters JSONB,
    is_activated BOOLEAN
) LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    -- SECURITY: Hardcoded credit rate to prevent bypass attacks
    CREDIT_RATE CONSTANT DECIMAL := 0.03;
    
    v_card_design_id UUID;
    v_is_card_active BOOLEAN;
    v_card_owner_id UUID;
    v_caller_id UUID;
    v_is_owner_access BOOLEAN := FALSE;
    v_billing_type TEXT;
    v_max_scans INTEGER;
    v_current_scans INTEGER;
    v_daily_scan_limit INTEGER;
    v_daily_scans INTEGER;
    v_last_scan_date DATE;
    v_scan_limit_reached BOOLEAN := FALSE;
    v_daily_limit_exceeded BOOLEAN := FALSE;
    v_credits_insufficient BOOLEAN := FALSE;
    v_credit_result JSONB;
BEGIN
    -- Get the caller's user ID
    v_caller_id := auth.uid();
    
    -- Get card information by issue card ID
    SELECT ic.card_id, ic.active, c.user_id, c.billing_type, c.max_scans, c.current_scans,
           c.daily_scan_limit, c.daily_scans, c.last_scan_date
    INTO v_card_design_id, v_is_card_active, v_card_owner_id, v_billing_type, v_max_scans, v_current_scans,
         v_daily_scan_limit, v_daily_scans, v_last_scan_date
    FROM issue_cards ic
    JOIN cards c ON ic.card_id = c.id
    WHERE ic.id = p_issue_card_id;

    IF NOT FOUND THEN
        -- If no card matches, return empty
        RETURN;
    END IF;

    -- Check if the caller is the card owner
    IF v_caller_id IS NOT NULL AND v_caller_id = v_card_owner_id THEN
        v_is_owner_access := TRUE;
        -- For owner access, we consider the card as "activated" for preview purposes
        v_is_card_active := TRUE;
    END IF;

    -- For digital cards, handle daily reset, limits, and credit consumption (only for non-owner access)
    IF v_billing_type = 'digital' AND NOT v_is_owner_access THEN
        -- Reset daily counter if it's a new day
        IF v_last_scan_date IS NULL OR v_last_scan_date < CURRENT_DATE THEN
            UPDATE cards 
            SET daily_scans = 0, last_scan_date = CURRENT_DATE 
            WHERE id = v_card_design_id;
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
            SELECT consume_credit_for_digital_scan(v_card_design_id, v_card_owner_id, CREDIT_RATE)
            INTO v_credit_result;
            
            IF (v_credit_result->>'success')::BOOLEAN = FALSE THEN
                -- Credit consumption failed
                v_credits_insufficient := TRUE;
            ELSE
                -- Credit consumed successfully, increment counters
                BEGIN
                    UPDATE cards 
                    SET current_scans = current_scans + 1,
                        daily_scans = daily_scans + 1,
                        last_scan_date = CURRENT_DATE
                    WHERE id = v_card_design_id;
                    v_current_scans := v_current_scans + 1;
                    v_daily_scans := v_daily_scans + 1;
                EXCEPTION
                    WHEN others THEN NULL;
                END;
            END IF;
        END IF;
    END IF;

    -- If the card is not active, activate it automatically (regardless of owner status)
    -- This ensures all first-time accesses are tracked, including owner previews
    IF NOT v_is_card_active THEN
        BEGIN
            UPDATE issue_cards SET active = true, activated_at = NOW() WHERE id = p_issue_card_id;
            -- Log the auto-activation
            PERFORM log_operation('Card auto-activated on first access');
        EXCEPTION
            WHEN others THEN
                -- Log any error during activation but don't fail the main query
        END;
        
        v_is_card_active := TRUE; -- Mark as active for current request
    END IF;

    RETURN QUERY
    SELECT 
        -- Use translation if available, fallback to original
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
        -- Get array of available translation languages (original + translated languages)
        (
            ARRAY[c.original_language] || 
            ARRAY(SELECT jsonb_object_keys(c.translations))
        )::TEXT[] AS card_available_languages,
        COALESCE(c.content_mode, 'list')::TEXT AS card_content_mode, -- Content rendering mode
        COALESCE(c.is_grouped, FALSE)::BOOLEAN AS card_is_grouped, -- Grouping mode
        COALESCE(c.group_display, 'expanded')::TEXT AS card_group_display, -- Group display
        COALESCE(c.billing_type, 'physical')::TEXT AS card_billing_type, -- Billing model
        c.max_scans AS card_max_scans,
        v_current_scans AS card_current_scans,
        c.daily_scan_limit AS card_daily_scan_limit,
        v_daily_scans AS card_daily_scans,
        v_scan_limit_reached AS card_scan_limit_reached,
        v_daily_limit_exceeded AS card_daily_limit_exceeded,
        v_credits_insufficient AS card_credits_insufficient,
        ci.id AS content_item_id,
        ci.parent_id AS content_item_parent_id,
        COALESCE(ci.translations->p_language->>'name', ci.name)::TEXT AS content_item_name,
        COALESCE(ci.translations->p_language->>'content', ci.content)::TEXT AS content_item_content,
        ci.image_url AS content_item_image_url,
        -- Note: ai_knowledge_base is translated but not exposed to mobile client
        COALESCE(ci.translations->p_language->>'ai_knowledge_base', ci.ai_knowledge_base)::TEXT AS content_item_ai_knowledge_base,
        ci.sort_order AS content_item_sort_order,
        ci.crop_parameters,
        v_is_card_active AS is_activated -- Return the current/newly activated status
    FROM cards c
    LEFT JOIN content_items ci ON c.id = ci.card_id
    WHERE c.id = v_card_design_id 
    ORDER BY 
        CASE WHEN ci.parent_id IS NULL THEN ci.sort_order ELSE 999999 END,
        ci.parent_id NULLS FIRST,
        ci.sort_order ASC,
        ci.created_at ASC;
END;
$$;


-- Get digital card content by access token (for digital cards with refreshable URLs)
-- This function validates access_token and is_access_enabled
-- SECURITY: Credit rate is hardcoded to prevent bypass attacks
-- DEDUPLICATION: p_visitor_hash prevents multiple charges for same visitor within 5 min
CREATE OR REPLACE FUNCTION get_digital_card_content(
    p_access_token TEXT,
    p_language VARCHAR(10) DEFAULT 'en',
    p_visitor_hash TEXT DEFAULT NULL  -- Optional: visitor identifier for deduplication
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
    -- DEDUPLICATION: Same visitor within 5 minutes = 1 scan
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
        -- Generate effective visitor hash for deduplication
        v_effective_visitor_hash := COALESCE(
            p_visitor_hash, 
            COALESCE(v_caller_id::TEXT, 'anon-' || md5(random()::TEXT))
        );
        
        -- Check for recent access from same visitor (deduplication)
        SELECT EXISTS(
            SELECT 1 FROM card_access_log
            WHERE card_id = v_card_id
              AND visitor_hash = v_effective_visitor_hash
              AND accessed_at > NOW() - DEDUP_WINDOW
        ) INTO v_recent_access_exists;
        
        -- Log this access (if table exists)
        BEGIN
            INSERT INTO card_access_log (card_id, visitor_hash, credit_charged, is_owner_access)
            VALUES (v_card_id, v_effective_visitor_hash, NOT v_recent_access_exists, FALSE);
        EXCEPTION
            WHEN undefined_table THEN 
                -- Table doesn't exist yet, skip logging
                NULL;
        END;
        
        -- If recent access exists, skip credit consumption (deduplication)
        IF NOT v_recent_access_exists THEN
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
        -- If recent access exists (v_recent_access_exists = TRUE), just return content without charging
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
        COALESCE(ci.translations->p_language->>'ai_knowledge_base', ci.ai_knowledge_base)::TEXT AS content_item_ai_knowledge_base,
        ci.sort_order AS content_item_sort_order,
        ci.crop_parameters
    FROM cards c
    LEFT JOIN content_items ci ON c.id = ci.card_id
    WHERE c.id = v_card_id 
    ORDER BY 
        CASE WHEN ci.parent_id IS NULL THEN ci.sort_order ELSE 999999 END,
        ci.parent_id NULLS FIRST,
        ci.sort_order ASC,
        ci.created_at ASC;
END;
$$;
GRANT EXECUTE ON FUNCTION get_digital_card_content(TEXT, VARCHAR, TEXT) TO anon, authenticated;

-- Get card preview URL without requiring issued cards (for card owners)
CREATE OR REPLACE FUNCTION get_card_preview_access(p_card_id UUID)
RETURNS TABLE (
    preview_mode BOOLEAN,
    card_id UUID
) LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_user_id UUID;
    v_caller_role TEXT;
BEGIN
    -- Get caller's role
    SELECT raw_user_meta_data->>'role' INTO v_caller_role
    FROM auth.users
    WHERE auth.users.id = auth.uid();
    
    -- Check if the card exists
    SELECT user_id INTO v_user_id FROM cards WHERE id = p_card_id;
    
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Card not found.';
    END IF;
    
    -- Allow access if user owns the card OR if user is admin
    IF v_user_id != auth.uid() AND v_caller_role != 'admin' THEN
        RAISE EXCEPTION 'Not authorized to preview this card.';
    END IF;
    
    -- Return preview access with special preview mode flag
    RETURN QUERY
    SELECT 
        TRUE as preview_mode,
        p_card_id as card_id;
END;
$$;

-- Get card content for preview mode (card owner or admin)
-- Updated to support translations via p_language parameter
-- Updated to include billing_type and daily limit fields for preview
CREATE OR REPLACE FUNCTION get_card_preview_content(
    p_card_id UUID,
    p_language VARCHAR(10) DEFAULT 'en'
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
    card_available_languages TEXT[], -- Array of available language codes
    card_content_mode TEXT, -- Content rendering mode (single, grid, list, cards)
    card_is_grouped BOOLEAN, -- Whether content is organized into categories
    card_group_display TEXT, -- How grouped items display: expanded or collapsed
    card_billing_type TEXT, -- Billing model: physical or digital
    card_max_scans INTEGER, -- NULL for physical (unlimited), Integer for digital
    card_current_scans INTEGER, -- Current total scan count
    card_daily_scan_limit INTEGER, -- Daily scan limit (NULL = unlimited)
    card_daily_scans INTEGER, -- Today's scan count
    content_item_id UUID,
    content_item_parent_id UUID,
    content_item_name TEXT,
    content_item_content TEXT,
    content_item_image_url TEXT,
    content_item_ai_knowledge_base TEXT,
    content_item_sort_order INTEGER,
    crop_parameters JSONB,
    is_preview BOOLEAN
) LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_user_id UUID;
    v_caller_id UUID;
    v_caller_role TEXT;
BEGIN
    -- Get the caller's user ID and role
    v_caller_id := auth.uid();
    
    -- Verify the user is authenticated
    IF v_caller_id IS NULL THEN
        RAISE EXCEPTION 'Authentication required for card preview.';
    END IF;
    
    -- Get caller's role
    SELECT raw_user_meta_data->>'role' INTO v_caller_role
    FROM auth.users
    WHERE auth.users.id = v_caller_id;
    
    -- Check if the card exists
    SELECT user_id INTO v_user_id FROM cards WHERE id = p_card_id;
    
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Card not found.';
    END IF;
    
    -- Allow access if user owns the card OR if user is admin
    IF v_user_id != v_caller_id AND v_caller_role != 'admin' THEN
        RAISE EXCEPTION 'Not authorized to preview this card.';
    END IF;
    
    -- Return card content directly (no issued card needed)
    RETURN QUERY
    SELECT 
        -- Use translation if available, fallback to original
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
        -- Get array of available translation languages (original + translated languages)
        (
            ARRAY[c.original_language] || 
            ARRAY(SELECT jsonb_object_keys(c.translations))
        )::TEXT[] AS card_available_languages,
        COALESCE(c.content_mode, 'list')::TEXT AS card_content_mode, -- Content rendering mode
        COALESCE(c.is_grouped, FALSE)::BOOLEAN AS card_is_grouped, -- Grouping mode
        COALESCE(c.group_display, 'expanded')::TEXT AS card_group_display, -- Group display
        COALESCE(c.billing_type, 'physical')::TEXT AS card_billing_type, -- Billing model
        c.max_scans AS card_max_scans,
        c.current_scans AS card_current_scans,
        c.daily_scan_limit AS card_daily_scan_limit,
        c.daily_scans AS card_daily_scans,
        ci.id AS content_item_id,
        ci.parent_id AS content_item_parent_id,
        COALESCE(ci.translations->p_language->>'name', ci.name)::TEXT AS content_item_name,
        COALESCE(ci.translations->p_language->>'content', ci.content)::TEXT AS content_item_content,
        ci.image_url AS content_item_image_url,
        COALESCE(ci.translations->p_language->>'ai_knowledge_base', ci.ai_knowledge_base)::TEXT AS content_item_ai_knowledge_base,
        ci.sort_order AS content_item_sort_order,
        ci.crop_parameters,
        TRUE AS is_preview -- Indicate this is preview mode
    FROM cards c
    LEFT JOIN content_items ci ON c.id = ci.card_id
    WHERE c.id = p_card_id 
    ORDER BY 
        CASE WHEN ci.parent_id IS NULL THEN ci.sort_order ELSE 999999 END,
        ci.parent_id NULLS FIRST,
        ci.sort_order ASC,
        ci.created_at ASC;
END;
$$; 