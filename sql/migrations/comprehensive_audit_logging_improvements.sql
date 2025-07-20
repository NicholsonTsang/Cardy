-- Comprehensive Audit Logging Improvements
-- This migration adds audit logging to critical admin functions and standardizes action_details

-- 1. Update payment confirmation function with audit logging
CREATE OR REPLACE FUNCTION confirm_batch_payment_by_session(
    p_stripe_checkout_session_id TEXT,
    p_payment_method TEXT DEFAULT NULL
) RETURNS UUID LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    v_payment_record RECORD;
    v_batch_record RECORD;
BEGIN
    -- Get payment and batch information by checkout session ID
    SELECT bp.*, cb.card_id, cb.cards_count 
    INTO v_payment_record
    FROM batch_payments bp
    JOIN card_batches cb ON bp.batch_id = cb.id
    WHERE bp.stripe_checkout_session_id = p_stripe_checkout_session_id
    AND bp.user_id = auth.uid();
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Payment not found or not authorized.';
    END IF;
    
    -- Check if already confirmed
    IF v_payment_record.payment_status = 'succeeded' THEN
        RAISE EXCEPTION 'Payment already confirmed.';
    END IF;
    
    -- Update payment status
    UPDATE batch_payments 
    SET 
        payment_status = 'succeeded',
        payment_method = p_payment_method,
        updated_at = NOW()
    WHERE stripe_checkout_session_id = p_stripe_checkout_session_id;
    
    -- Update batch payment status
    UPDATE card_batches 
    SET 
        payment_completed = TRUE,
        payment_completed_at = NOW(),
        updated_at = NOW()
    WHERE id = v_payment_record.batch_id;
    
    -- Generate cards using the new function
    PERFORM generate_batch_cards(v_payment_record.batch_id);
    
    -- Log payment confirmation in audit table
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
        v_payment_record.user_id,
        'PAYMENT_CONFIRMATION',
        'Batch payment confirmed via Stripe checkout session',
        jsonb_build_object(
            'payment_status', v_payment_record.payment_status,
            'payment_completed', false,
            'cards_generated', false
        ),
        jsonb_build_object(
            'payment_status', 'succeeded',
            'payment_completed', true,
            'payment_completed_at', NOW(),
            'payment_method', p_payment_method,
            'cards_generated', true
        ),
        jsonb_build_object(
            'action', 'payment_confirmed',
            'payment_method', p_payment_method,
            'stripe_checkout_session_id', p_stripe_checkout_session_id,
            'batch_id', v_payment_record.batch_id,
            'amount_cents', v_payment_record.amount_cents,
            'currency', v_payment_record.currency,
            'cards_count', v_payment_record.cards_count,
            'automated_card_generation', true
        )
    );
    
    RETURN v_payment_record.batch_id;
END;
$$;

-- 2. Add admin function for user role changes
CREATE OR REPLACE FUNCTION admin_change_user_role(
    p_target_user_id UUID,
    p_new_role TEXT,
    p_reason TEXT
)
RETURNS BOOLEAN LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    caller_role TEXT;
    current_role TEXT;
    target_user_email TEXT;
    valid_roles TEXT[] := ARRAY['card_issuer', 'admin'];
BEGIN
    -- Check if the caller is an admin
    SELECT raw_user_meta_data->>'role' INTO caller_role
    FROM auth.users
    WHERE id = auth.uid();

    IF caller_role != 'admin' THEN
        RAISE EXCEPTION 'Only admins can change user roles.';
    END IF;

    -- Validate new role
    IF p_new_role != ALL(valid_roles) THEN
        RAISE EXCEPTION 'Invalid role. Valid roles are: %', array_to_string(valid_roles, ', ');
    END IF;

    -- Get current role and email of target user
    SELECT 
        raw_user_meta_data->>'role',
        email
    INTO current_role, target_user_email
    FROM auth.users
    WHERE id = p_target_user_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Target user not found.';
    END IF;

    -- Check if role is actually changing
    IF current_role = p_new_role THEN
        RAISE EXCEPTION 'User already has role: %', p_new_role;
    END IF;

    -- Prevent self-demotion from admin
    IF auth.uid() = p_target_user_id AND current_role = 'admin' AND p_new_role != 'admin' THEN
        RAISE EXCEPTION 'Admins cannot demote themselves. Another admin must perform this action.';
    END IF;

    -- Update user role
    UPDATE auth.users
    SET 
        raw_user_meta_data = COALESCE(raw_user_meta_data, '{}'::jsonb) || jsonb_build_object('role', p_new_role),
        updated_at = NOW()
    WHERE id = p_target_user_id;

    -- Log role change in audit table
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
        p_target_user_id,
        'ROLE_CHANGE',
        p_reason,
        jsonb_build_object(
            'role', current_role
        ),
        jsonb_build_object(
            'role', p_new_role,
            'changed_at', NOW()
        ),
        jsonb_build_object(
            'action', 'role_changed',
            'from_role', current_role,
            'to_role', p_new_role,
            'target_email', target_user_email,
            'is_promotion', CASE 
                WHEN current_role = 'card_issuer' AND p_new_role = 'admin' THEN true
                ELSE false
            END,
            'is_demotion', CASE 
                WHEN current_role = 'admin' AND p_new_role = 'card_issuer' THEN true
                ELSE false
            END,
            'security_impact', CASE 
                WHEN p_new_role = 'admin' THEN 'high'
                WHEN current_role = 'admin' THEN 'high'
                ELSE 'medium'
            END
        )
    );
    
    RETURN FOUND;
END;
$$;