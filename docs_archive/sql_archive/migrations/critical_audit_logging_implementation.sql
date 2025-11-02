-- Critical Audit Logging Implementation
-- This migration adds comprehensive audit logging to the most critical missing functions

-- =================================================================
-- 1. CARD CREATION AUDIT LOGGING
-- =================================================================

CREATE OR REPLACE FUNCTION create_card(
    p_name TEXT,
    p_description TEXT,
    p_image_url TEXT DEFAULT NULL,
    p_conversation_ai_enabled BOOLEAN DEFAULT FALSE,
    p_ai_prompt TEXT DEFAULT '',
    p_qr_code_position TEXT DEFAULT 'BR',
    p_content_render_mode TEXT DEFAULT 'SINGLE_SERIES_MULTI_ITEMS'
) RETURNS UUID LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_card_id UUID;
    caller_role TEXT;
BEGIN
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
        auth.uid(),
        p_name,
        p_description,
        p_image_url,
        p_conversation_ai_enabled,
        p_ai_prompt,
        p_qr_code_position::"QRCodePosition",
        p_content_render_mode::"ContentRenderMode"
    )
    RETURNING id INTO v_card_id;
    
    -- Get caller role for audit context
    SELECT raw_user_meta_data->>'role' INTO caller_role
    FROM auth.users
    WHERE id = auth.uid();
    
    -- Log card creation in audit table
    INSERT INTO admin_audit_log (
        admin_user_id,
        target_user_id,
        action_type,
        reason,
        old_values,
        new_values,
        action_details
    ) VALUES (
        auth.uid(),
        auth.uid(),
        'CARD_CREATION',
        'User created new card design',
        jsonb_build_object(
            'card_exists', false
        ),
        jsonb_build_object(
            'card_id', v_card_id,
            'name', p_name,
            'description', p_description,
            'image_url', p_image_url,
            'conversation_ai_enabled', p_conversation_ai_enabled,
            'ai_prompt', p_ai_prompt,
            'qr_code_position', p_qr_code_position,
            'content_render_mode', p_content_render_mode,
            'created_at', NOW()
        ),
        jsonb_build_object(
            'action', 'card_created',
            'card_id', v_card_id,
            'card_name', p_name,
            'is_admin_action', (caller_role = 'admin'),
            'has_ai_features', p_conversation_ai_enabled,
            'has_custom_image', (p_image_url IS NOT NULL),
            'content_mode', p_content_render_mode,
            'qr_position', p_qr_code_position,
            'security_impact', 'low',
            'business_impact', 'medium'
        )
    );
    
    RETURN v_card_id;
END;
$$;

-- =================================================================
-- 2. PROFILE MANAGEMENT AUDIT LOGGING
-- =================================================================

-- Add audit logging to profile update function
CREATE OR REPLACE FUNCTION create_or_update_basic_profile(
    p_public_name TEXT DEFAULT NULL,
    p_company_name TEXT DEFAULT NULL,
    p_bio TEXT DEFAULT NULL,
    p_full_name TEXT DEFAULT NULL
) RETURNS UUID LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_profile_id UUID;
    v_old_record RECORD;
    v_changes_made JSONB := '{}';
    caller_role TEXT;
    has_changes BOOLEAN := FALSE;
    is_new_profile BOOLEAN := FALSE;
BEGIN
    -- Get existing profile data
    SELECT 
        id,
        public_name,
        company_name,
        bio,
        full_name
    INTO v_old_record
    FROM user_profiles
    WHERE user_id = v_user_id;
    
    IF NOT FOUND THEN
        is_new_profile := TRUE;
        -- Create new profile
        INSERT INTO user_profiles (
            user_id,
            public_name,
            company_name,
            bio,
            full_name
        ) VALUES (
            v_user_id,
            p_public_name,
            p_company_name,
            p_bio,
            p_full_name
        ) RETURNING id INTO v_profile_id;
    ELSE
        v_profile_id := v_old_record.id;
        
        -- Track changes for existing profile
        IF p_public_name IS NOT NULL AND p_public_name != v_old_record.public_name THEN
            v_changes_made := v_changes_made || jsonb_build_object('public_name', jsonb_build_object('from', v_old_record.public_name, 'to', p_public_name));
            has_changes := TRUE;
        END IF;
        
        IF p_company_name IS NOT NULL AND p_company_name != v_old_record.company_name THEN
            v_changes_made := v_changes_made || jsonb_build_object('company_name', jsonb_build_object('from', v_old_record.company_name, 'to', p_company_name));
            has_changes := TRUE;
        END IF;
        
        IF p_bio IS NOT NULL AND p_bio != v_old_record.bio THEN
            v_changes_made := v_changes_made || jsonb_build_object('bio', jsonb_build_object('from', v_old_record.bio, 'to', p_bio));
            has_changes := TRUE;
        END IF;
        
        IF p_full_name IS NOT NULL AND p_full_name != v_old_record.full_name THEN
            v_changes_made := v_changes_made || jsonb_build_object('full_name', jsonb_build_object('from', v_old_record.full_name, 'to', p_full_name));
            has_changes := TRUE;
        END IF;
        
        -- Update if there are changes
        IF has_changes THEN
            UPDATE user_profiles
            SET 
                public_name = COALESCE(p_public_name, public_name),
                company_name = COALESCE(p_company_name, company_name),
                bio = COALESCE(p_bio, bio),
                full_name = COALESCE(p_full_name, full_name),
                updated_at = NOW()
            WHERE user_id = v_user_id;
        END IF;
    END IF;
    
    -- Get caller role for audit context
    SELECT raw_user_meta_data->>'role' INTO caller_role
    FROM auth.users
    WHERE id = v_user_id;
    
    -- Log profile changes in audit table
    IF is_new_profile OR has_changes THEN
        INSERT INTO admin_audit_log (
            admin_user_id,
            target_user_id,
            action_type,
            reason,
            old_values,
            new_values,
            action_details
        ) VALUES (
            v_user_id,
            v_user_id,
            CASE WHEN is_new_profile THEN 'PROFILE_CREATION' ELSE 'PROFILE_UPDATE' END,
            CASE WHEN is_new_profile THEN 'User created profile' ELSE 'User updated profile' END,
            CASE WHEN is_new_profile THEN 
                jsonb_build_object('profile_exists', false)
            ELSE 
                jsonb_build_object(
                    'public_name', v_old_record.public_name,
                    'company_name', v_old_record.company_name,
                    'bio', v_old_record.bio,
                    'full_name', v_old_record.full_name
                )
            END,
            jsonb_build_object(
                'profile_id', v_profile_id,
                'public_name', COALESCE(p_public_name, v_old_record.public_name),
                'company_name', COALESCE(p_company_name, v_old_record.company_name),
                'bio', COALESCE(p_bio, v_old_record.bio),
                'full_name', COALESCE(p_full_name, v_old_record.full_name),
                'updated_at', NOW()
            ),
            jsonb_build_object(
                'action', CASE WHEN is_new_profile THEN 'profile_created' ELSE 'profile_updated' END,
                'profile_id', v_profile_id,
                'is_admin_action', (caller_role = 'admin'),
                'is_new_profile', is_new_profile,
                'changes_made', CASE WHEN is_new_profile THEN NULL ELSE v_changes_made END,
                'fields_changed', CASE WHEN is_new_profile THEN NULL ELSE ARRAY(SELECT jsonb_object_keys(v_changes_made)) END,
                'has_company_info', (COALESCE(p_company_name, v_old_record.company_name) IS NOT NULL),
                'security_impact', 'low',
                'business_impact', 'low'
            )
        );
    END IF;
    
    RETURN v_profile_id;
END;
$$;

-- =================================================================
-- 3. VERIFICATION SUBMISSION AUDIT LOGGING
-- =================================================================

-- Add audit logging to verification submission
CREATE OR REPLACE FUNCTION submit_verification(
    p_public_name TEXT,
    p_bio TEXT DEFAULT NULL,
    p_company_name TEXT DEFAULT NULL,
    p_full_name TEXT DEFAULT NULL,
    p_supporting_documents TEXT[] DEFAULT ARRAY[]::TEXT[]
) RETURNS BOOLEAN LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_previous_status "ProfileStatus";
    caller_role TEXT;
BEGIN
    -- Get current verification status
    SELECT verification_status INTO v_previous_status
    FROM user_profiles
    WHERE user_id = v_user_id;
    
    -- Create or update profile with verification data
    INSERT INTO user_profiles (
        user_id,
        public_name,
        bio,
        company_name,
        full_name,
        verification_status,
        supporting_documents
    ) VALUES (
        v_user_id,
        p_public_name,
        p_bio,
        p_company_name,
        p_full_name,
        'PENDING_REVIEW',
        p_supporting_documents
    )
    ON CONFLICT (user_id) DO UPDATE SET
        public_name = p_public_name,
        bio = p_bio,
        company_name = p_company_name,
        full_name = p_full_name,
        verification_status = 'PENDING_REVIEW',
        supporting_documents = p_supporting_documents,
        updated_at = NOW();
    
    -- Get caller role for audit context
    SELECT raw_user_meta_data->>'role' INTO caller_role
    FROM auth.users
    WHERE id = v_user_id;
    
    -- Log verification submission in audit table
    INSERT INTO admin_audit_log (
        admin_user_id,
        target_user_id,
        action_type,
        reason,
        old_values,
        new_values,
        action_details
    ) VALUES (
        v_user_id,
        v_user_id,
        'VERIFICATION_SUBMISSION',
        'User submitted verification for review',
        jsonb_build_object(
            'verification_status', COALESCE(v_previous_status, 'NOT_SUBMITTED')
        ),
        jsonb_build_object(
            'verification_status', 'PENDING_REVIEW',
            'public_name', p_public_name,
            'bio', p_bio,
            'company_name', p_company_name,
            'full_name', p_full_name,
            'supporting_documents_count', array_length(p_supporting_documents, 1),
            'submitted_at', NOW()
        ),
        jsonb_build_object(
            'action', 'verification_submitted',
            'is_admin_action', (caller_role = 'admin'),
            'is_resubmission', (v_previous_status IS NOT NULL AND v_previous_status != 'NOT_SUBMITTED'),
            'previous_status', COALESCE(v_previous_status, 'NOT_SUBMITTED'),
            'documents_provided', array_length(p_supporting_documents, 1),
            'has_company_info', (p_company_name IS NOT NULL),
            'has_bio', (p_bio IS NOT NULL),
            'has_full_name', (p_full_name IS NOT NULL),
            'security_impact', 'medium',
            'requires_admin_review', true
        )
    );
    
    RETURN TRUE;
END;
$$;

-- =================================================================
-- 4. BATCH CREATION AUDIT LOGGING
-- =================================================================

-- Add audit logging to batch creation
CREATE OR REPLACE FUNCTION issue_card_batch(
    p_card_id UUID,
    p_batch_name TEXT,
    p_cards_count INTEGER,
    p_payment_required BOOLEAN DEFAULT TRUE
) RETURNS UUID LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_batch_id UUID;
    v_batch_number INTEGER;
    v_card_name TEXT;
    caller_role TEXT;
BEGIN
    -- Verify card ownership
    SELECT name INTO v_card_name
    FROM cards 
    WHERE id = p_card_id AND user_id = auth.uid();
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Card not found or not authorized.';
    END IF;
    
    -- Get next batch number
    SELECT COALESCE(MAX(batch_number), 0) + 1 INTO v_batch_number
    FROM card_batches
    WHERE card_id = p_card_id;
    
    -- Create the batch
    INSERT INTO card_batches (
        card_id,
        created_by,
        batch_name,
        batch_number,
        cards_count,
        payment_required,
        payment_amount_cents
    ) VALUES (
        p_card_id,
        auth.uid(),
        p_batch_name,
        v_batch_number,
        p_cards_count,
        p_payment_required,
        CASE WHEN p_payment_required THEN p_cards_count * 200 ELSE 0 END -- $2 per card
    )
    RETURNING id INTO v_batch_id;
    
    -- Get caller role for audit context
    SELECT raw_user_meta_data->>'role' INTO caller_role
    FROM auth.users
    WHERE id = auth.uid();
    
    -- Log batch creation in audit table
    INSERT INTO admin_audit_log (
        admin_user_id,
        target_user_id,
        action_type,
        reason,
        old_values,
        new_values,
        action_details
    ) VALUES (
        auth.uid(),
        auth.uid(),
        'BATCH_CREATION',
        'User created new card batch',
        jsonb_build_object(
            'batch_exists', false
        ),
        jsonb_build_object(
            'batch_id', v_batch_id,
            'card_id', p_card_id,
            'batch_name', p_batch_name,
            'batch_number', v_batch_number,
            'cards_count', p_cards_count,
            'payment_required', p_payment_required,
            'payment_amount_cents', CASE WHEN p_payment_required THEN p_cards_count * 200 ELSE 0 END,
            'created_at', NOW()
        ),
        jsonb_build_object(
            'action', 'batch_created',
            'batch_id', v_batch_id,
            'card_id', p_card_id,
            'card_name', v_card_name,
            'batch_name', p_batch_name,
            'batch_number', v_batch_number,
            'cards_count', p_cards_count,
            'is_admin_action', (caller_role = 'admin'),
            'payment_required', p_payment_required,
            'total_value_cents', CASE WHEN p_payment_required THEN p_cards_count * 200 ELSE 0 END,
            'security_impact', 'low',
            'business_impact', 'high'
        )
    );
    
    RETURN v_batch_id;
END;
$$;