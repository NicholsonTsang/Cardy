-- ================================================================
-- DEPLOYMENT: Admin Dashboard Revenue Metrics Update
-- ================================================================
-- Date: 2025-10-15
-- Purpose: Update admin dashboard revenue metrics to use credit purchases
--          instead of legacy batch payments
-- 
-- Background:
-- The system has migrated from direct batch payments to a credit-based system:
-- - Old system: batch_payments table (direct Stripe checkout per batch)
-- - New system: credit_purchases table (users buy credits, then use them)
-- 
-- This update changes the revenue calculation in admin_get_system_stats_enhanced()
-- to accurately reflect credit purchase revenue instead of legacy batch payments.
--
-- Deployment: Copy and execute this entire file in Supabase Dashboard > SQL Editor
-- ================================================================

-- Drop and recreate the function with updated revenue metrics
DROP FUNCTION IF EXISTS admin_get_system_stats_enhanced CASCADE;

CREATE OR REPLACE FUNCTION admin_get_system_stats_enhanced()
RETURNS TABLE (
    total_users BIGINT,
    total_cards BIGINT,
    total_batches BIGINT,
    total_issued_cards BIGINT,
    total_activated_cards BIGINT,
    pending_payment_batches BIGINT,
    paid_batches BIGINT,
    waived_batches BIGINT,
    print_requests_submitted BIGINT,
    print_requests_processing BIGINT,
    print_requests_shipping BIGINT,
    daily_revenue_cents BIGINT,
    weekly_revenue_cents BIGINT,
    monthly_revenue_cents BIGINT,
    total_revenue_cents BIGINT,
    daily_new_users BIGINT,
    weekly_new_users BIGINT,
    monthly_new_users BIGINT,
    daily_new_cards BIGINT,
    weekly_new_cards BIGINT,
    monthly_new_cards BIGINT,
    daily_issued_cards BIGINT,
    weekly_issued_cards BIGINT,
    monthly_issued_cards BIGINT,
    -- AUDIT METRICS
    total_audit_entries BIGINT,
    critical_actions_today BIGINT,
    high_severity_actions_week BIGINT,
    unique_admin_users_month BIGINT
) LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
    caller_role TEXT;
BEGIN
    -- Check if the caller is an admin
    SELECT raw_user_meta_data->>'role' INTO caller_role
    FROM auth.users
    WHERE auth.users.id = auth.uid();

    IF caller_role != 'admin' THEN
        RAISE EXCEPTION 'Only admins can view system statistics.';
    END IF;

    RETURN QUERY
    SELECT 
        -- User and content metrics
        (SELECT COUNT(*) FROM auth.users) as total_users,
        (SELECT COUNT(*) FROM cards) as total_cards,
        (SELECT COUNT(*) FROM card_batches) as total_batches,
        (SELECT COUNT(*) FROM issue_cards) as total_issued_cards,
        (SELECT COUNT(*) FROM issue_cards WHERE active = true) as total_activated_cards,
        -- Payment metrics
        (SELECT COUNT(*) FROM card_batches WHERE payment_required = true AND payment_completed = false AND payment_waived = false) as pending_payment_batches,
        (SELECT COUNT(*) FROM card_batches WHERE payment_completed = true) as paid_batches,
        (SELECT COUNT(*) FROM card_batches WHERE payment_waived = true) as waived_batches,
        -- Print request metrics
        (SELECT COUNT(*) FROM print_requests WHERE status = 'SUBMITTED') as print_requests_submitted,
        (SELECT COUNT(*) FROM print_requests WHERE status = 'PROCESSING') as print_requests_processing,
        (SELECT COUNT(*) FROM print_requests WHERE status = 'SHIPPED') as print_requests_shipping,
        -- Revenue metrics (based on credit purchases, not legacy batch payments)
        -- Note: amount_usd is in dollars, so multiply by 100 to get cents for consistency with old system
        (SELECT COALESCE(SUM(amount_usd * 100), 0)::BIGINT FROM credit_purchases WHERE status = 'completed' AND created_at >= CURRENT_DATE) as daily_revenue_cents,
        (SELECT COALESCE(SUM(amount_usd * 100), 0)::BIGINT FROM credit_purchases WHERE status = 'completed' AND created_at >= CURRENT_DATE - INTERVAL '7 days') as weekly_revenue_cents,
        (SELECT COALESCE(SUM(amount_usd * 100), 0)::BIGINT FROM credit_purchases WHERE status = 'completed' AND created_at >= CURRENT_DATE - INTERVAL '30 days') as monthly_revenue_cents,
        (SELECT COALESCE(SUM(amount_usd * 100), 0)::BIGINT FROM credit_purchases WHERE status = 'completed') as total_revenue_cents,
        -- Growth metrics
        (SELECT COUNT(*) FROM auth.users WHERE created_at >= CURRENT_DATE) as daily_new_users,
        (SELECT COUNT(*) FROM auth.users WHERE created_at >= CURRENT_DATE - INTERVAL '7 days') as weekly_new_users,
        (SELECT COUNT(*) FROM auth.users WHERE created_at >= CURRENT_DATE - INTERVAL '30 days') as monthly_new_users,
        (SELECT COUNT(*) FROM cards WHERE created_at >= CURRENT_DATE) as daily_new_cards,
        (SELECT COUNT(*) FROM cards WHERE created_at >= CURRENT_DATE - INTERVAL '7 days') as weekly_new_cards,
        (SELECT COUNT(*) FROM cards WHERE created_at >= CURRENT_DATE - INTERVAL '30 days') as monthly_new_cards,
        (SELECT COUNT(*) FROM issue_cards WHERE created_at >= CURRENT_DATE) as daily_issued_cards,
        (SELECT COUNT(*) FROM issue_cards WHERE created_at >= CURRENT_DATE - INTERVAL '7 days') as weekly_issued_cards,
        (SELECT COUNT(*) FROM issue_cards WHERE created_at >= CURRENT_DATE - INTERVAL '30 days') as monthly_issued_cards,
        -- Operations log metrics
        (SELECT COUNT(*) FROM operations_log) as total_audit_entries,
        (SELECT COUNT(*) FROM operations_log WHERE operation LIKE '%Waived payment%' AND created_at >= CURRENT_DATE) as payment_waivers_today,
        (SELECT COUNT(*) FROM operations_log WHERE operation LIKE '%Changed user role%' AND created_at >= CURRENT_DATE - INTERVAL '7 days') as role_changes_week,
        (SELECT COUNT(DISTINCT user_id) FROM operations_log WHERE user_role = 'admin' AND created_at >= CURRENT_DATE - INTERVAL '30 days') as unique_admin_users_month;
END;
$$;

-- Grant necessary permissions
GRANT EXECUTE ON FUNCTION admin_get_system_stats_enhanced() TO authenticated;

-- ================================================================
-- VERIFICATION QUERIES
-- ================================================================
-- Run these queries to verify the update worked correctly:

-- 1. Check that the function was created successfully
SELECT proname, pronargs, proretset 
FROM pg_proc 
WHERE proname = 'admin_get_system_stats_enhanced';

-- 2. Check credit_purchases table has data
SELECT 
    COUNT(*) as total_purchases,
    COUNT(*) FILTER (WHERE status = 'completed') as completed_purchases,
    COALESCE(SUM(amount_usd) FILTER (WHERE status = 'completed'), 0) as total_revenue_usd
FROM credit_purchases;

-- 3. Test the function (admin only - will fail for non-admin users)
-- SELECT * FROM admin_get_system_stats_enhanced();

-- ================================================================
-- ROLLBACK (if needed)
-- ================================================================
-- If you need to rollback to the old batch_payments-based calculation:
-- 
-- DROP FUNCTION IF EXISTS admin_get_system_stats_enhanced CASCADE;
-- Then re-run the old version from your backup or git history
-- ================================================================


