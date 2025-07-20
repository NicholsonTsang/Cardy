-- Migration: Add contact fields to print_requests table
-- Description: Add contact_email and contact_whatsapp fields for better communication with print request submitters

-- Add contact fields to print_requests table
ALTER TABLE print_requests 
ADD COLUMN IF NOT EXISTS contact_email TEXT,
ADD COLUMN IF NOT EXISTS contact_whatsapp TEXT;

-- Add comments for documentation
COMMENT ON COLUMN print_requests.contact_email IS 'Email address for print request communication';
COMMENT ON COLUMN print_requests.contact_whatsapp IS 'WhatsApp number for print request communication (including country code)';

-- Update existing records with user email from auth.users if available
-- This is a safe operation as it only adds data where none exists
UPDATE print_requests 
SET contact_email = (
    SELECT email 
    FROM auth.users 
    WHERE auth.users.id = print_requests.user_id
)
WHERE contact_email IS NULL 
  AND EXISTS (
    SELECT 1 
    FROM auth.users 
    WHERE auth.users.id = print_requests.user_id
  );