-- =====================================================================
-- DEPLOYMENT SCRIPT: Payment Management Security Fix
-- =====================================================================
-- This fixes missing GRANT statements for payment management functions
-- Functions moved from server-side to client-side (correct location)
-- =====================================================================
-- Run this in Supabase SQL Editor: https://supabase.com/dashboard/project/mzgusshseqxrdrkvamrg/sql
-- =====================================================================

-- Grant permissions to authenticated users for payment management functions
-- These functions are called by Edge Functions using user JWT (not service_role)

GRANT EXECUTE ON FUNCTION create_batch_checkout_payment(UUID, TEXT, TEXT, INTEGER, JSONB) TO authenticated;
GRANT EXECUTE ON FUNCTION get_batch_for_checkout(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_existing_batch_payment(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION confirm_batch_payment_by_session(TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION create_pending_batch_payment(INTEGER, TEXT, UUID, INTEGER, JSONB, TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION confirm_pending_batch_payment(TEXT, TEXT) TO authenticated;

-- Verify grants were applied
SELECT 
    p.proname AS function_name,
    array_agg(DISTINCT pr.rolname) AS granted_to
FROM pg_proc p
LEFT JOIN pg_proc_acl a ON p.oid = a.objoid
LEFT JOIN pg_roles pr ON a.grantee = pr.oid
WHERE p.proname IN (
    'create_batch_checkout_payment',
    'get_batch_for_checkout',
    'get_existing_batch_payment',
    'confirm_batch_payment_by_session',
    'create_pending_batch_payment',
    'confirm_pending_batch_payment'
)
GROUP BY p.proname;

-- =====================================================================
-- DEPLOYMENT COMPLETE
-- =====================================================================
-- Expected output: Each function should show {authenticated} in granted_to
-- =====================================================================

