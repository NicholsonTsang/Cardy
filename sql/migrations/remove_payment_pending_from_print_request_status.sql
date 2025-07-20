-- Migration: Remove PAYMENT_PENDING from PrintRequestStatus enum
-- Description: Remove the PAYMENT_PENDING status since payment is handled at batch level before print requests

-- First, check if any print requests exist with PAYMENT_PENDING status
-- If any exist, this migration should not proceed
DO $$
DECLARE
    payment_pending_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO payment_pending_count 
    FROM print_requests 
    WHERE status = 'PAYMENT_PENDING';
    
    IF payment_pending_count > 0 THEN
        RAISE EXCEPTION 'Cannot remove PAYMENT_PENDING status: % print requests still have this status. Please update these records first.', payment_pending_count;
    END IF;
END $$;

-- Create new enum type without PAYMENT_PENDING
CREATE TYPE "PrintRequestStatusNew" AS ENUM (
    'SUBMITTED',
    'PROCESSING',
    'SHIPPING',
    'COMPLETED',
    'CANCELLED'
);

-- Update the print_requests table to use the new enum
ALTER TABLE print_requests 
ALTER COLUMN status TYPE "PrintRequestStatusNew" 
USING status::TEXT::"PrintRequestStatusNew";

-- Drop the old enum type
DROP TYPE "PrintRequestStatus";

-- Rename the new enum type to the original name
ALTER TYPE "PrintRequestStatusNew" RENAME TO "PrintRequestStatus";

-- Verify the change by checking the enum values
SELECT enumlabel 
FROM pg_enum 
WHERE enumtypid = (SELECT oid FROM pg_type WHERE typname = 'PrintRequestStatus')
ORDER BY enumsortorder;