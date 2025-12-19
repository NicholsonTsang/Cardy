-- =================================================================
-- CLEANUP: Remove Unused Tables and Fields (Dec 14, 2025)
-- =================================================================
-- This migration removes:
-- 1. batch_payments table (legacy payment-first flow, never used)
-- 2. subscription_usage_history table (broken with Redis-first architecture)
-- 3. monthly_access_used and monthly_access_limit columns from subscriptions
--    (usage now tracked in Redis)
-- 4. process_digital_access_server function (replaced by Redis-first tracking)
-- =================================================================

-- Drop unused stored procedure
DROP FUNCTION IF EXISTS process_digital_access_server(UUID, UUID, TEXT, BOOLEAN, INTEGER, INTEGER, DECIMAL) CASCADE;

-- Drop unused tables
DROP TABLE IF EXISTS batch_payments CASCADE;
DROP TABLE IF EXISTS subscription_usage_history CASCADE;

-- Remove stale columns from subscriptions (usage tracked in Redis now)
ALTER TABLE subscriptions DROP COLUMN IF EXISTS monthly_access_used;
ALTER TABLE subscriptions DROP COLUMN IF EXISTS monthly_access_limit;

-- =================================================================
-- IMPORTANT: After running this migration, deploy updated stored procedures:
-- 1. sql/storeproc/server-side/mobile_access.sql
-- 2. sql/storeproc/server-side/subscription_management.sql  
-- 3. sql/storeproc/client-side/12_subscription.sql (NEW - subscription functions)

-- =================================================================
-- VERIFICATION QUERIES (run these after migration)
-- =================================================================
-- Check tables don't exist:
-- SELECT * FROM pg_tables WHERE tablename IN ('batch_payments', 'subscription_usage_history');
-- 
-- Check columns don't exist:
-- SELECT column_name FROM information_schema.columns WHERE table_name = 'subscriptions';
--
-- Check function doesn't exist:
-- SELECT proname FROM pg_proc WHERE proname = 'process_digital_access_server';

