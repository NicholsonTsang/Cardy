-- =============================================
-- Fix: Drop all versions of get_operations_log to resolve ambiguity
-- Then recreate from source files
-- =============================================

-- Drop all versions of get_operations_log function
-- This handles the case where multiple versions with different signatures exist
DROP FUNCTION IF EXISTS get_operations_log(INTEGER, INTEGER, UUID, "UserRole") CASCADE;
DROP FUNCTION IF EXISTS get_operations_log(INTEGER, INTEGER, UUID, "UserRole", TEXT, TIMESTAMPTZ, TIMESTAMPTZ) CASCADE;
DROP FUNCTION IF EXISTS get_operations_log() CASCADE;

-- Drop the stats function too for consistency
DROP FUNCTION IF EXISTS get_operations_log_stats() CASCADE;

-- Now the functions from 00_logging.sql will be created without conflicts
-- Deploy this file BEFORE running all_stored_procedures.sql

