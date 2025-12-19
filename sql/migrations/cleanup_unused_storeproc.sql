-- Migration: Cleanup unused stored procedures
-- Run this in Supabase SQL Editor
-- Date: December 2025

-- ============================================================================
-- 1. DROP UNUSED FUNCTIONS (Verification/Feedback system removed)
-- ============================================================================

-- Verification system (never implemented)
DROP FUNCTION IF EXISTS admin_get_pending_verifications(INTEGER);
DROP FUNCTION IF EXISTS get_verification_feedbacks(UUID);
DROP FUNCTION IF EXISTS reset_user_verification(UUID);

-- Feedback system (never implemented)
DROP FUNCTION IF EXISTS create_admin_feedback(UUID, VARCHAR, UUID, TEXT);
DROP FUNCTION IF EXISTS create_admin_feedback(UUID, VARCHAR, TEXT);
DROP FUNCTION IF EXISTS get_admin_feedback_history(VARCHAR, UUID);
DROP FUNCTION IF EXISTS get_admin_feedback_history(VARCHAR, UUID, INTEGER, INTEGER);
DROP FUNCTION IF EXISTS get_print_request_feedbacks(UUID);

-- ============================================================================
-- 2. DROP DUPLICATE/REPLACED FUNCTIONS
-- ============================================================================

-- Replaced by admin_update_user_role
DROP FUNCTION IF EXISTS admin_change_user_role(UUID, TEXT, TEXT);

-- Replaced by get_all_print_requests (same functionality)
DROP FUNCTION IF EXISTS admin_get_all_print_requests("PrintRequestStatus", TEXT, INTEGER, INTEGER);
DROP FUNCTION IF EXISTS admin_get_all_print_requests("PrintRequestStatus", INTEGER, INTEGER);

-- Replaced by admin_get_all_users
DROP FUNCTION IF EXISTS get_all_users_with_details();

-- Replaced by issue_card_batch_with_credits
DROP FUNCTION IF EXISTS issue_card_batch(UUID, INTEGER);
DROP FUNCTION IF EXISTS issue_card_batch(UUID, INTEGER, DATE);

-- Replaced by create_credit_purchase
DROP FUNCTION IF EXISTS create_credit_purchase_record(VARCHAR, DECIMAL, DECIMAL, JSONB, UUID);
DROP FUNCTION IF EXISTS create_credit_purchase_record(VARCHAR, DECIMAL, DECIMAL, DECIMAL, VARCHAR);

-- ============================================================================
-- 3. DROP UNUSED UTILITY FUNCTIONS
-- ============================================================================

-- Not used anywhere
DROP FUNCTION IF EXISTS get_batch_payment_info(UUID);
DROP FUNCTION IF EXISTS get_pending_batch_payment_info(UUID);
DROP FUNCTION IF EXISTS get_template_stats();
DROP FUNCTION IF EXISTS get_user_activity_summary(UUID);

-- ============================================================================
-- 4. ADD MISSING FUNCTIONS
-- ============================================================================

-- can_issue_batch: Check if user has enough credits to issue a batch
CREATE OR REPLACE FUNCTION can_issue_batch(p_quantity INTEGER)
RETURNS JSONB AS $$
DECLARE
    v_user_id UUID;
    v_balance DECIMAL;
    v_cost_per_card DECIMAL := 1.00; -- Cost per physical card
    v_total_cost DECIMAL;
    v_can_issue BOOLEAN;
BEGIN
    v_user_id := auth.uid();
    
    IF v_user_id IS NULL THEN
        RETURN jsonb_build_object(
            'can_issue', false,
            'reason', 'Not authenticated'
        );
    END IF;
    
    -- Get current balance
    SELECT balance INTO v_balance
    FROM user_credits
    WHERE user_id = v_user_id;
    
    IF v_balance IS NULL THEN
        v_balance := 0;
    END IF;
    
    -- Calculate cost
    v_total_cost := p_quantity * v_cost_per_card;
    v_can_issue := v_balance >= v_total_cost;
    
    RETURN jsonb_build_object(
        'can_issue', v_can_issue,
        'current_balance', v_balance,
        'required_credits', v_total_cost,
        'quantity', p_quantity,
        'cost_per_card', v_cost_per_card
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION can_issue_batch(INTEGER) TO authenticated;

-- get_admin_audit_logs: Get audit logs for admin dashboard
-- Note: operations_log has simple structure: user_id, user_role, operation, created_at
CREATE OR REPLACE FUNCTION get_admin_audit_logs(
    p_action_type TEXT DEFAULT NULL,
    p_admin_user_id UUID DEFAULT NULL,
    p_limit INTEGER DEFAULT 50,
    p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
    id UUID,
    user_id UUID,
    user_email TEXT,
    user_role "UserRole",
    operation TEXT,
    created_at TIMESTAMPTZ
) AS $$
DECLARE
    v_caller_role TEXT;
BEGIN
    -- Check if caller is admin
    SELECT raw_user_meta_data->>'role' INTO v_caller_role
    FROM auth.users
    WHERE auth.users.id = auth.uid();
    
    IF v_caller_role != 'admin' THEN
        RAISE EXCEPTION 'Only admins can view audit logs';
    END IF;
    
    -- Return from operations_log table
    RETURN QUERY
    SELECT 
        ol.id,
        ol.user_id,
        au.email::TEXT AS user_email,
        ol.user_role,
        ol.operation,
        ol.created_at
    FROM operations_log ol
    LEFT JOIN auth.users au ON ol.user_id = au.id
    WHERE (p_action_type IS NULL OR ol.operation ILIKE '%' || p_action_type || '%')
      AND (p_admin_user_id IS NULL OR ol.user_id = p_admin_user_id)
    ORDER BY ol.created_at DESC
    LIMIT p_limit
    OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION get_admin_audit_logs(TEXT, UUID, INTEGER, INTEGER) TO authenticated;

-- ============================================================================
-- 5. VERIFY CLEANUP
-- ============================================================================

-- This should return empty if all unused functions are dropped
-- SELECT routine_name FROM information_schema.routines 
-- WHERE routine_schema = 'public' 
-- AND routine_name IN (
--     'admin_get_pending_verifications',
--     'get_verification_feedbacks', 
--     'reset_user_verification',
--     'create_admin_feedback',
--     'get_admin_feedback_history',
--     'get_print_request_feedbacks',
--     'admin_change_user_role',
--     'admin_get_all_print_requests',
--     'get_all_users_with_details',
--     'issue_card_batch',
--     'create_credit_purchase_record',
--     'get_batch_payment_info',
--     'get_pending_batch_payment_info',
--     'get_template_stats',
--     'get_user_activity_summary'
-- );

