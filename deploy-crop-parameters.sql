-- Deploy crop parameters support to database
-- This script adds crop_parameters columns and updates stored procedures

-- First, add the columns to existing tables
ALTER TABLE cards ADD COLUMN IF NOT EXISTS crop_parameters JSONB;
ALTER TABLE content_items ADD COLUMN IF NOT EXISTS crop_parameters JSONB;

-- Add comments for documentation
COMMENT ON COLUMN cards.crop_parameters IS 'JSON object containing crop parameters for dynamic image cropping (position, zoom, dimensions, etc.)';
COMMENT ON COLUMN content_items.crop_parameters IS 'JSON object containing crop parameters for dynamic image cropping (position, zoom, dimensions, etc.)';

-- Create indexes for better query performance on crop_parameters
CREATE INDEX IF NOT EXISTS idx_cards_crop_parameters ON cards USING GIN (crop_parameters);
CREATE INDEX IF NOT EXISTS idx_content_items_crop_parameters ON content_items USING GIN (crop_parameters);

-- Now deploy the updated stored procedures
-- (The actual stored procedure definitions will be applied from all_stored_procedures.sql)
