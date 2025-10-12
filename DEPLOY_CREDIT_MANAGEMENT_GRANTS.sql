-- =====================================================================
-- DEPLOYMENT: Add GRANT Statements to Credit Management Functions
-- =====================================================================
-- Run in Supabase SQL Editor: https://supabase.com/dashboard/project/mzgusshseqxrdrkvamrg/sql
-- =====================================================================
-- This fixes missing GRANT statements for credit management functions
-- These functions use a "dual-use pattern" where they can be called
-- from both frontend (with user JWT) and Edge Functions (with SERVICE_ROLE_KEY)
-- =====================================================================

-- Dual-use functions (called from frontend AND Edge Functions)
-- These use COALESCE(p_user_id, auth.uid()) to work in both contexts
GRANT EXECUTE ON FUNCTION check_credit_balance(DECIMAL, UUID) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION create_credit_purchase_record(VARCHAR, DECIMAL, DECIMAL, JSONB, UUID) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION consume_credits(DECIMAL, UUID, VARCHAR, JSONB) TO authenticated, service_role;

-- Client-only functions (only called from frontend with user JWT)
GRANT EXECUTE ON FUNCTION initialize_user_credits() TO authenticated;
GRANT EXECUTE ON FUNCTION get_credit_statistics() TO authenticated;
GRANT EXECUTE ON FUNCTION get_user_credits() TO authenticated;

-- Add documentation comments to explain the dual-use pattern
COMMENT ON FUNCTION check_credit_balance(DECIMAL, UUID) IS 
  'DUAL-USE PATTERN: Accepts optional p_user_id (for Edge Functions with SERVICE_ROLE_KEY) or falls back to auth.uid() (for frontend with user JWT). Granted to both authenticated and service_role roles.';
  
COMMENT ON FUNCTION create_credit_purchase_record(VARCHAR, DECIMAL, DECIMAL, JSONB, UUID) IS 
  'DUAL-USE PATTERN: Accepts optional p_user_id (for Edge Functions with SERVICE_ROLE_KEY) or falls back to auth.uid() (for frontend with user JWT). Granted to both authenticated and service_role roles. Called by create-credit-checkout-session Edge Function.';
  
COMMENT ON FUNCTION consume_credits(DECIMAL, UUID, VARCHAR, JSONB) IS 
  'DUAL-USE PATTERN: Accepts optional p_user_id (for server-side stored procedures) or falls back to auth.uid() (for direct frontend calls). Granted to both authenticated and service_role roles.';

COMMENT ON FUNCTION initialize_user_credits() IS 
  'CLIENT-ONLY: Uses auth.uid() from user JWT. Creates initial credit record for authenticated user.';

COMMENT ON FUNCTION get_credit_statistics() IS 
  'CLIENT-ONLY: Uses auth.uid() from user JWT. Returns credit statistics for authenticated user including balance, purchases, consumptions.';

COMMENT ON FUNCTION get_user_credits() IS 
  'CLIENT-ONLY: Uses auth.uid() from user JWT. Returns current credit balance for authenticated user.';

-- =====================================================================
-- VERIFICATION
-- =====================================================================
-- Check grants were applied correctly
SELECT 
    p.proname as function_name,
    pg_catalog.pg_get_function_arguments(p.oid) as parameters,
    CASE 
        WHEN p.proacl IS NULL THEN ARRAY['PUBLIC (default)']::text[]
        ELSE ARRAY(
            SELECT r.rolname
            FROM pg_catalog.pg_roles r
            WHERE r.oid = ANY(
                SELECT (aclexplode(p.proacl)).grantee
            )
        )
    END as granted_to
FROM pg_catalog.pg_proc p
JOIN pg_catalog.pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public'
  AND p.proname IN (
      'check_credit_balance',
      'create_credit_purchase_record',
      'consume_credits',
      'initialize_user_credits',
      'get_credit_statistics',
      'get_user_credits'
  )
ORDER BY p.proname;

-- Expected results:
-- Function Name                    | Parameters                                             | Granted To
-- ---------------------------------|--------------------------------------------------------|---------------------------
-- check_credit_balance             | p_required_credits numeric, p_user_id uuid DEFAULT NULL | {authenticated, service_role}
-- consume_credits                  | p_credits_to_consume numeric, p_user_id uuid DEFAULT NULL, p_consumption_type character varying DEFAULT 'other'::character varying, p_metadata jsonb DEFAULT '{}'::jsonb | {authenticated, service_role}
-- create_credit_purchase_record    | p_stripe_session_id character varying, p_amount_usd numeric, p_credits_amount numeric, p_metadata jsonb DEFAULT NULL::jsonb, p_user_id uuid DEFAULT NULL | {authenticated, service_role}
-- get_credit_statistics            | (no parameters)                                        | {authenticated}
-- get_user_credits                 | (no parameters)                                        | {authenticated}
-- initialize_user_credits          | (no parameters)                                        | {authenticated}

-- =====================================================================
-- NOTES
-- =====================================================================
-- DUAL-USE PATTERN EXPLANATION:
--
-- Some functions use COALESCE(p_user_id, auth.uid()) to work in two contexts:
--
-- 1. Frontend calls (ANON_KEY + User JWT):
--    - auth.uid() is available from JWT context
--    - Function called without p_user_id parameter
--    - Example: const { data } = await supabase.rpc('check_credit_balance', {
--                 p_required_credits: 10
--               });
--
-- 2. Edge Function calls (SERVICE_ROLE_KEY):
--    - auth.uid() returns NULL (no JWT context)
--    - Function called with explicit p_user_id parameter
--    - Example: const { data } = await supabaseAdmin.rpc('check_credit_balance', {
--                 p_required_credits: 10,
--                 p_user_id: user.id  // Explicit parameter
--               });
--
-- SECURITY:
-- - Both roles (authenticated, service_role) can execute these functions
-- - Functions validate user exists and has permission
-- - Edge Functions must validate JWT manually before calling
--
-- EDGE FUNCTIONS USING THESE:
-- - create-credit-checkout-session: calls create_credit_purchase_record()
-- - translate-card-content: calls check_credit_balance()
-- - (server-side) store_card_translations: calls consume_credits()
-- =====================================================================

