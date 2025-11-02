-- =====================================================================
-- DEPLOYMENT SCRIPT: Remove Legacy Batch Payment System
-- =====================================================================
-- This removes unused legacy batch payment functions
-- The system now uses credit-based batch issuance instead
-- =====================================================================
-- Run this in Supabase SQL Editor: https://supabase.com/dashboard/project/mzgusshseqxrdrkvamrg/sql
-- =====================================================================

-- Drop legacy batch payment stored procedures
DROP FUNCTION IF EXISTS create_batch_checkout_payment(UUID, TEXT, TEXT, INTEGER, JSONB);
DROP FUNCTION IF EXISTS get_batch_for_checkout(UUID);
DROP FUNCTION IF EXISTS get_existing_batch_payment(UUID);
DROP FUNCTION IF EXISTS confirm_batch_payment_by_session(TEXT, TEXT);
DROP FUNCTION IF EXISTS create_pending_batch_payment(INTEGER, TEXT, UUID, INTEGER, JSONB, TEXT, TEXT);
DROP FUNCTION IF EXISTS confirm_pending_batch_payment(TEXT, TEXT);

-- Verify functions are removed
SELECT 
    proname AS function_name,
    pg_get_function_identity_arguments(oid) AS arguments
FROM pg_proc
WHERE proname LIKE '%batch%payment%'
    AND proname NOT LIKE '%credit%';

-- Expected: 0 rows (all legacy functions removed)

-- =====================================================================
-- NOTES
-- =====================================================================
-- Tables NOT removed (still used by webhooks and credit system):
-- - batch_payments (keep for audit trail)
-- - card_batches (core functionality)
--
-- Edge Functions already deleted:
-- - create-checkout-session
-- - handle-checkout-success
--
-- Current system:
-- - Users purchase credits via create-credit-checkout-session
-- - Users issue batches via issue_card_batch_with_credits()
-- - Instant batch creation (no Stripe redirect)
-- =====================================================================

