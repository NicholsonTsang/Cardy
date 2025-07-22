-- =================================================================
-- UPDATE EXISTING STORED PROCEDURES FOR NEW AUDIT SYSTEM
-- This file updates all existing stored procedures to use the new
-- standardized audit logging system
-- =================================================================

-- 1. Update card management functions

-- Enhanced create_card with new audit logging
CREATE OR REPLACE FUNCTION create_card(
    p_name TEXT,
    p_description TEXT DEFAULT NULL,
    p_image_url TEXT DEFAULT NULL,
    p_conversation_ai_enabled BOOLEAN DEFAULT FALSE,
    p_ai_prompt TEXT DEFAULT NULL,
    p_qr_code_position "QRCodePosition" DEFAULT 'BR',
    p_content_render_mode "ContentRenderMode" DEFAULT 'SINGLE_SERIES_MULTI_ITEMS'
) RETURNS UUID LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_card_id UUID;
    v_user_id UUID;
BEGIN
    v_user_id := auth.uid();
    
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Authentication required';
    END IF;

    INSERT INTO cards (
        user_id,
        name,
        description,
        image_url,
        conversation_ai_enabled,
        ai_prompt,
        qr_code_position,
        content_render_mode
    ) VALUES (
        v_user_id,
        p_name,
        p_description,
        p_image_url,
        p_conversation_ai_enabled,
        p_ai_prompt,
        p_qr_code_position,
        p_content_render_mode
    ) RETURNING id INTO v_card_id;

    -- New audit logging
    PERFORM log_admin_action(
        p_admin_user_id := v_user_id,
        p_target_user_id := v_user_id,
        p_target_entity_type := 'card',
        p_target_entity_id := v_card_id,
        p_action_type := 'CARD_CREATION',
        p_action_severity := 'LOW',
        p_action_summary := 'Created new card: ' || p_name,
        p_reason := 'User created new card design',
        p_new_values := jsonb_build_object(
            'name', p_name,
            'description', p_description,
            'conversation_ai_enabled', p_conversation_ai_enabled,
            'content_render_mode', p_content_render_mode
        ),
        p_metadata := jsonb_build_object(
            'card_features', jsonb_build_object(
                'has_ai', p_conversation_ai_enabled,
                'has_description', p_description IS NOT NULL,
                'has_image', p_image_url IS NOT NULL
            )
        )
    );

    RETURN v_card_id;
END;
$$;

-- Enhanced update_card with new audit logging
CREATE OR REPLACE FUNCTION update_card(
    p_card_id UUID,
    p_name TEXT DEFAULT NULL,
    p_description TEXT DEFAULT NULL,
    p_image_url TEXT DEFAULT NULL,
    p_conversation_ai_enabled BOOLEAN DEFAULT NULL,
    p_ai_prompt TEXT DEFAULT NULL,
    p_qr_code_position "QRCodePosition" DEFAULT NULL,
    p_content_render_mode "ContentRenderMode" DEFAULT NULL
) RETURNS BOOLEAN LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_user_id UUID;
    v_old_record cards%ROWTYPE;
    v_changes JSONB := '{}';
    v_change_summary TEXT := '';
BEGIN
    v_user_id := auth.uid();
    
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Authentication required';
    END IF;

    -- Get current card data for audit trail
    SELECT * INTO v_old_record FROM cards WHERE id = p_card_id AND user_id = v_user_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Card not found or access denied';
    END IF;

    -- Build change tracking
    IF p_name IS NOT NULL AND p_name != v_old_record.name THEN
        v_changes := v_changes || jsonb_build_object('name', jsonb_build_object('old', v_old_record.name, 'new', p_name));
        v_change_summary := v_change_summary || 'name, ';
    END IF;
    
    IF p_description IS NOT NULL AND p_description != COALESCE(v_old_record.description, '') THEN
        v_changes := v_changes || jsonb_build_object('description', jsonb_build_object('old', v_old_record.description, 'new', p_description));
        v_change_summary := v_change_summary || 'description, ';
    END IF;
    
    IF p_conversation_ai_enabled IS NOT NULL AND p_conversation_ai_enabled != v_old_record.conversation_ai_enabled THEN
        v_changes := v_changes || jsonb_build_object('conversation_ai_enabled', jsonb_build_object('old', v_old_record.conversation_ai_enabled, 'new', p_conversation_ai_enabled));
        v_change_summary := v_change_summary || 'AI settings, ';
    END IF;

    -- Update card
    UPDATE cards SET
        name = COALESCE(p_name, name),
        description = COALESCE(p_description, description),
        image_url = COALESCE(p_image_url, image_url),
        conversation_ai_enabled = COALESCE(p_conversation_ai_enabled, conversation_ai_enabled),
        ai_prompt = COALESCE(p_ai_prompt, ai_prompt),
        qr_code_position = COALESCE(p_qr_code_position, qr_code_position),
        content_render_mode = COALESCE(p_content_render_mode, content_render_mode),
        updated_at = NOW()
    WHERE id = p_card_id AND user_id = v_user_id;

    -- Log changes if any were made
    IF jsonb_object_keys(v_changes) IS NOT NULL THEN
        -- Remove trailing comma and space
        v_change_summary := rtrim(v_change_summary, ', ');
        
        PERFORM log_admin_action(
            p_admin_user_id := v_user_id,
            p_target_user_id := v_user_id,
            p_target_entity_type := 'card',
            p_target_entity_id := p_card_id,
            p_action_type := 'CARD_UPDATE',
            p_action_severity := 'LOW',
            p_action_summary := 'Updated card "' || v_old_record.name || '": ' || v_change_summary,
            p_reason := 'User updated card properties',
            p_old_values := row_to_json(v_old_record)::jsonb,
            p_new_values := v_changes,
            p_metadata := jsonb_build_object(
                'fields_changed', string_to_array(v_change_summary, ', '),
                'change_count', jsonb_object_keys(v_changes)
            )
        );
    END IF;

    RETURN FOUND;
END;
$$;

-- Enhanced delete_card with new audit logging
CREATE OR REPLACE FUNCTION delete_card(p_card_id UUID)
RETURNS BOOLEAN LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_user_id UUID;
    v_card_record cards%ROWTYPE;
    v_related_counts JSONB;
BEGIN
    v_user_id := auth.uid();
    
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Authentication required';
    END IF;

    -- Get full card data before deletion for audit
    SELECT * INTO v_card_record FROM cards WHERE id = p_card_id AND user_id = v_user_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Card not found or access denied';
    END IF;

    -- Get related data counts for audit metadata
    SELECT jsonb_build_object(
        'content_items', (SELECT COUNT(*) FROM content_items WHERE card_id = p_card_id),
        'batches', (SELECT COUNT(*) FROM card_batches WHERE card_id = p_card_id),
        'issued_cards', (
            SELECT COUNT(*) FROM issue_cards ic
            JOIN card_batches cb ON ic.batch_id = cb.id 
            WHERE cb.card_id = p_card_id
        )
    ) INTO v_related_counts;

    -- Delete the card (cascading will handle related records)
    DELETE FROM cards WHERE id = p_card_id AND user_id = v_user_id;

    -- Log the deletion
    PERFORM log_admin_action(
        p_admin_user_id := v_user_id,
        p_target_user_id := v_user_id,
        p_target_entity_type := 'card',
        p_target_entity_id := p_card_id,
        p_action_type := 'CARD_DELETION',
        p_action_severity := 'MEDIUM',
        p_action_summary := 'Deleted card: ' || v_card_record.name,
        p_reason := 'User requested card deletion',
        p_old_values := row_to_json(v_card_record)::jsonb,
        p_metadata := jsonb_build_object(
            'deleted_related_data', v_related_counts,
            'card_features', jsonb_build_object(
                'had_ai', v_card_record.conversation_ai_enabled,
                'had_description', v_card_record.description IS NOT NULL,
                'had_image', v_card_record.image_url IS NOT NULL
            ),
            'deletion_impact', CASE 
                WHEN (v_related_counts->>'issued_cards')::int > 0 THEN 'high'
                WHEN (v_related_counts->>'batches')::int > 0 THEN 'medium'
                ELSE 'low'
            END
        )
    );

    RETURN FOUND;
END;
$$;

-- 2. Update batch management functions

-- Enhanced issue_card_batch with new audit logging
CREATE OR REPLACE FUNCTION issue_card_batch(
    p_card_id UUID,
    p_batch_name TEXT,
    p_cards_count INTEGER
) RETURNS UUID LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_batch_id UUID;
    v_user_id UUID;
    v_card_name TEXT;
BEGIN
    v_user_id := auth.uid();
    
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Authentication required';
    END IF;

    -- Validate card ownership
    SELECT name INTO v_card_name FROM cards WHERE id = p_card_id AND user_id = v_user_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Card not found or access denied';
    END IF;

    -- Create batch
    INSERT INTO card_batches (
        card_id,
        created_by,
        batch_name,
        cards_count,
        payment_required,
        payment_amount_cents
    ) VALUES (
        p_card_id,
        v_user_id,
        p_batch_name,
        p_cards_count,
        TRUE,
        p_cards_count * 200 -- $2.00 per card
    ) RETURNING id INTO v_batch_id;

    -- Log batch creation
    PERFORM log_admin_action(
        p_admin_user_id := v_user_id,
        p_target_user_id := v_user_id,
        p_target_entity_type := 'card_batch',
        p_target_entity_id := v_batch_id,
        p_action_type := 'BATCH_CREATION',
        p_action_severity := 'MEDIUM',
        p_action_summary := 'Created batch "' || p_batch_name || '" with ' || p_cards_count || ' cards',
        p_reason := 'User created new card batch',
        p_new_values := jsonb_build_object(
            'batch_name', p_batch_name,
            'cards_count', p_cards_count,
            'payment_amount_cents', p_cards_count * 200,
            'card_name', v_card_name
        ),
        p_metadata := jsonb_build_object(
            'card_id', p_card_id,
            'cost_per_card_cents', 200,
            'batch_size_category', CASE 
                WHEN p_cards_count <= 10 THEN 'small'
                WHEN p_cards_count <= 100 THEN 'medium'
                WHEN p_cards_count <= 1000 THEN 'large'
                ELSE 'enterprise'
            END
        )
    );

    RETURN v_batch_id;
END;
$$;

-- 3. Update payment management functions

-- Enhanced admin_waive_batch_payment with new audit logging
CREATE OR REPLACE FUNCTION admin_waive_batch_payment(
    p_batch_id UUID,
    p_waiver_reason TEXT
) RETURNS UUID LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_batch_record RECORD;
    caller_role TEXT;
    v_admin_user_id UUID;
BEGIN
    -- Get caller info
    SELECT id, raw_user_meta_data->>'role' 
    INTO v_admin_user_id, caller_role
    FROM auth.users WHERE id = auth.uid();

    IF caller_role != 'admin' THEN
        RAISE EXCEPTION 'Only admins can waive batch payments.';
    END IF;

    -- Get batch information
    SELECT cb.*, c.name as card_name, u.email as creator_email
    INTO v_batch_record
    FROM card_batches cb
    JOIN cards c ON cb.card_id = c.id
    JOIN auth.users u ON cb.created_by = u.id
    WHERE cb.id = p_batch_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Batch not found.';
    END IF;
    
    -- Check if payment can be waived
    IF v_batch_record.payment_completed = TRUE THEN
        RAISE EXCEPTION 'Cannot waive payment for a batch that has already been paid.';
    END IF;
    
    IF v_batch_record.payment_waived = TRUE THEN
        RAISE EXCEPTION 'Payment has already been waived for this batch.';
    END IF;
    
    -- Update batch to mark payment as waived
    UPDATE card_batches 
    SET 
        payment_waived = TRUE,
        payment_waived_by = v_admin_user_id,
        payment_waived_at = NOW(),
        payment_waiver_reason = p_waiver_reason,
        updated_at = NOW()
    WHERE id = p_batch_id;
    
    -- Generate cards using the new function
    PERFORM generate_batch_cards(p_batch_id);
    
    -- Log the waiver with enhanced audit
    PERFORM log_admin_action(
        p_admin_user_id := v_admin_user_id,
        p_target_user_id := v_batch_record.created_by,
        p_target_entity_type := 'card_batch',
        p_target_entity_id := p_batch_id,
        p_action_type := 'PAYMENT_WAIVER',
        p_action_severity := 'HIGH',
        p_action_summary := 'Waived payment for batch "' || v_batch_record.batch_name || '" ($' || (v_batch_record.payment_amount_cents / 100.0) || ')',
        p_reason := p_waiver_reason,
        p_old_values := jsonb_build_object(
            'payment_waived', false,
            'cards_generated', false,
            'payment_amount_cents', v_batch_record.payment_amount_cents
        ),
        p_new_values := jsonb_build_object(
            'payment_waived', true,
            'payment_waived_by', v_admin_user_id,
            'payment_waived_at', NOW(),
            'payment_waiver_reason', p_waiver_reason,
            'cards_generated', true
        ),
        p_metadata := jsonb_build_object(
            'batch_name', v_batch_record.batch_name,
            'card_name', v_batch_record.card_name,
            'creator_email', v_batch_record.creator_email,
            'cards_count', v_batch_record.cards_count,
            'waived_amount_cents', v_batch_record.payment_amount_cents,
            'financial_impact', 'revenue_loss'
        )
    );
    
    RETURN p_batch_id;
END;
$$;

-- 4. Update print request functions

-- Enhanced admin_update_print_request_status with new audit logging
CREATE OR REPLACE FUNCTION admin_update_print_request_status(
    p_request_id UUID,
    p_new_status "PrintRequestStatus",
    p_admin_notes TEXT DEFAULT NULL
) RETURNS BOOLEAN LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_request_record RECORD;
    caller_role TEXT;
    v_admin_user_id UUID;
    v_old_status "PrintRequestStatus";
BEGIN
    -- Get caller info
    SELECT id, raw_user_meta_data->>'role' 
    INTO v_admin_user_id, caller_role
    FROM auth.users WHERE id = auth.uid();

    IF caller_role != 'admin' THEN
        RAISE EXCEPTION 'Only admins can update print request status.';
    END IF;

    -- Get current request details
    SELECT pr.*, c.name as card_name, cb.batch_name, au.email as user_email
    INTO v_request_record
    FROM print_requests pr
    JOIN card_batches cb ON pr.batch_id = cb.id
    JOIN cards c ON cb.card_id = c.id
    JOIN auth.users au ON pr.user_id = au.id
    WHERE pr.id = p_request_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Print request not found.';
    END IF;

    v_old_status := v_request_record.status;

    -- Update the print request
    UPDATE print_requests
    SET 
        status = p_new_status,
        admin_notes = CASE 
            WHEN p_admin_notes IS NULL THEN admin_notes
            WHEN admin_notes IS NULL OR admin_notes = '' THEN p_admin_notes
            ELSE admin_notes || E'\n\n[' || NOW()::DATE || '] ' || p_admin_notes
        END,
        updated_at = NOW()
    WHERE id = p_request_id;

    -- Log the status change with enhanced audit
    PERFORM log_admin_action(
        p_admin_user_id := v_admin_user_id,
        p_target_user_id := v_request_record.user_id,
        p_target_entity_type := 'print_request',
        p_target_entity_id := p_request_id,
        p_action_type := 'PRINT_REQUEST_STATUS_UPDATE',
        p_action_severity := CASE 
            WHEN p_new_status IN ('COMPLETED', 'CANCELLED') THEN 'MEDIUM'
            ELSE 'LOW'
        END,
        p_action_summary := 'Updated print request status from ' || v_old_status || ' to ' || p_new_status,
        p_reason := COALESCE(p_admin_notes, 'Print request status updated'),
        p_old_values := jsonb_build_object(
            'status', v_old_status,
            'admin_notes', v_request_record.admin_notes
        ),
        p_new_values := jsonb_build_object(
            'status', p_new_status,
            'admin_notes', p_admin_notes
        ),
        p_metadata := jsonb_build_object(
            'card_name', v_request_record.card_name,
            'batch_name', v_request_record.batch_name,
            'user_email', v_request_record.user_email,
            'shipping_address', v_request_record.shipping_address,
            'status_progression', jsonb_build_array(v_old_status, p_new_status),
            'processing_stage', CASE 
                WHEN p_new_status = 'PROCESSING' THEN 'production'
                WHEN p_new_status = 'SHIPPING' THEN 'logistics'
                WHEN p_new_status = 'COMPLETED' THEN 'delivered'
                WHEN p_new_status = 'CANCELLED' THEN 'terminated'
                ELSE 'pending'
            END
        )
    );
    
    RETURN FOUND;
END;
$$;

-- 5. Update user management functions (already done above, but ensure consistency)

-- Update the user registration trigger
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
    user_role TEXT;
    registration_method TEXT;
    email_domain TEXT;
BEGIN
    user_role := COALESCE(NEW.raw_user_meta_data->>'role', 'card_issuer');
    
    -- Determine registration method
    registration_method := CASE 
        WHEN NEW.is_anonymous THEN 'anonymous'
        WHEN NEW.app_metadata->>'provider' = 'google' THEN 'google_oauth'
        WHEN NEW.app_metadata->>'provider' = 'github' THEN 'github_oauth'
        ELSE 'email_password'
    END;
    
    -- Extract email domain for analysis
    email_domain := split_part(NEW.email, '@', 2);
    
    -- Log user registration with enhanced audit
    PERFORM log_admin_action(
        p_admin_user_id := NEW.id, -- Self-registration
        p_target_user_id := NEW.id,
        p_target_entity_type := 'user_account',
        p_target_entity_id := NEW.id,
        p_action_type := 'USER_REGISTRATION',
        p_action_severity := 'LOW',
        p_action_summary := 'New user registered: ' || NEW.email,
        p_reason := 'User self-registration',
        p_new_values := jsonb_build_object(
            'email', NEW.email,
            'role', user_role,
            'registration_method', registration_method,
            'email_confirmed', NEW.email_confirmed_at IS NOT NULL
        ),
        p_metadata := jsonb_build_object(
            'registration_method', registration_method,
            'email_domain', email_domain,
            'user_agent', NEW.raw_user_meta_data->>'user_agent',
            'ip_address', NEW.raw_user_meta_data->>'ip_address',
            'email_domain_category', CASE 
                WHEN email_domain IN ('gmail.com', 'yahoo.com', 'hotmail.com', 'outlook.com') THEN 'consumer'
                WHEN email_domain LIKE '%.edu' THEN 'education'
                WHEN email_domain LIKE '%.gov' THEN 'government'
                ELSE 'business'
            END,
            'security_context', jsonb_build_object(
                'requires_verification', user_role = 'card_issuer',
                'risk_level', CASE 
                    WHEN registration_method = 'anonymous' THEN 'high'
                    WHEN registration_method IN ('google_oauth', 'github_oauth') THEN 'low'
                    ELSE 'medium'
                END
            )
        )
    );
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. Create migration script to update schema.sql
CREATE OR REPLACE FUNCTION update_schema_references()
RETURNS TEXT AS $$
BEGIN
    -- This function helps track what needs to be updated in schema.sql
    RETURN 'Schema updates needed:
1. Replace admin_audit_log table definition with new structure
2. Replace admin_feedback_history table with admin_feedback table  
3. Update triggers to use new log_admin_action function
4. Add new enum types: AdminActionType, ActionSeverity, FeedbackStatus
5. Update indexes to match new schema
6. Update RLS policies if needed';
END;
$$ LANGUAGE plpgsql;

-- Display the update checklist
SELECT update_schema_references();

COMMENT ON FUNCTION log_admin_action IS 'Centralized audit logging used by all administrative functions';
COMMENT ON FUNCTION create_card IS 'Updated to use new audit logging system';
COMMENT ON FUNCTION update_card IS 'Enhanced with detailed change tracking and audit logging';
COMMENT ON FUNCTION delete_card IS 'Enhanced with comprehensive deletion audit trail';
COMMENT ON FUNCTION issue_card_batch IS 'Updated with batch creation audit logging';
COMMENT ON FUNCTION admin_waive_batch_payment IS 'Enhanced with financial impact audit logging';
COMMENT ON FUNCTION admin_update_print_request_status IS 'Updated with print workflow audit logging';
COMMENT ON FUNCTION handle_new_user IS 'Enhanced user registration audit logging with security context';