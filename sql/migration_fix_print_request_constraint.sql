-- Migration: Fix print request constraint to allow multiple CANCELLED/COMPLETED requests
-- Date: 2024-12-22
-- Issue: unique_active_print_request_per_batch constraint prevents multiple cancelled requests

-- Drop the existing constraint
ALTER TABLE print_requests DROP CONSTRAINT IF EXISTS unique_active_print_request_per_batch;

-- Create partial unique index for active print requests only
-- This allows multiple CANCELLED and COMPLETED requests per batch
CREATE UNIQUE INDEX IF NOT EXISTS unique_active_print_request_per_batch 
ON print_requests(batch_id) 
WHERE status NOT IN ('COMPLETED', 'CANCELLED');

-- Verify the change
SELECT 
    indexname, 
    indexdef 
FROM pg_indexes 
WHERE tablename = 'print_requests' 
AND indexname = 'unique_active_print_request_per_batch'; 