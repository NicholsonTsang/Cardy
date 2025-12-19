-- Migration: Add digital access control fields
-- Purpose: Enable/disable QR code access and allow refreshable access tokens

-- Add is_access_enabled field (defaults to true for existing cards)
ALTER TABLE cards 
ADD COLUMN IF NOT EXISTS is_access_enabled BOOLEAN DEFAULT true;

-- Add access_token field without DEFAULT first
ALTER TABLE cards 
ADD COLUMN IF NOT EXISTS access_token TEXT;

-- Update existing cards to have a token
UPDATE cards 
SET access_token = replace(replace(encode(gen_random_bytes(9), 'base64'), '+', '-'), '/', '_')
WHERE access_token IS NULL;

-- Create unique index on access_token for fast lookups and uniqueness
CREATE UNIQUE INDEX IF NOT EXISTS idx_cards_access_token ON cards(access_token);

-- Add comment for documentation
COMMENT ON COLUMN cards.is_access_enabled IS 'Toggle to enable/disable QR code access for digital cards';
COMMENT ON COLUMN cards.access_token IS 'Short 12-char URL-safe token for access URL - can be regenerated to invalidate old links';
