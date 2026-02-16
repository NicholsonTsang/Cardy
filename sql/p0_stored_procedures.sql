-- =============================================================================
-- P0 FEATURE STORED PROCEDURES - DEPLOYMENT FILE
-- =============================================================================
-- Platform Optimization Roadmap - Phase 0 (Foundation)
--
-- This file deploys UPDATED stored procedures that contain P0 features:
-- 1. Duplicate Card functionality (get_card_with_content)
-- 2. CSV Bulk Import (bulk_create_content_items)
-- 3. Bulk Delete Content Items (bulk_delete_content_items)
--
-- These procedures have been ADDED to existing files, not created as new files.
-- This maintains the existing codebase organization.
--
-- Deploy: Copy this file to Supabase Dashboard → SQL Editor → Run
-- Or: supabase db execute --file sql/p0_stored_procedures.sql
-- =============================================================================

-- Load Card Management (includes get_card_with_content)
\i sql/storeproc/client-side/02_card_management.sql

-- Load Content Management (includes bulk_create_content_items and bulk_delete_content_items)
\i sql/storeproc/client-side/03_content_management.sql

-- =============================================================================
-- DEPLOYMENT COMPLETE
-- =============================================================================
-- ✅ Updated 2 files with 3 new stored procedures:
--    - 02_card_management.sql: get_card_with_content()
--    - 03_content_management.sql: bulk_create_content_items(), bulk_delete_content_items()
--
-- Next steps:
-- 1. Test Duplicate Card feature in creator portal
-- 2. Test CSV Bulk Import with sample file
-- 3. Test Bulk Delete with multiple content items
-- =============================================================================
