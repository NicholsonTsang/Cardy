-- =================================================================
-- ADD ORIGINAL IMAGE URL COLUMNS
-- Adds original_image_url columns to cards and content_items tables
-- =================================================================

-- Add original_image_url column to cards table if it doesn't exist
ALTER TABLE cards ADD COLUMN IF NOT EXISTS original_image_url TEXT;

-- Add original_image_url column to content_items table if it doesn't exist
ALTER TABLE content_items ADD COLUMN IF NOT EXISTS original_image_url TEXT;

-- Verify the columns were added
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'cards' 
        AND column_name = 'original_image_url'
    ) THEN
        RAISE NOTICE 'Column original_image_url added to cards table';
    END IF;
    
    IF EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'content_items' 
        AND column_name = 'original_image_url'
    ) THEN
        RAISE NOTICE 'Column original_image_url added to content_items table';
    END IF;
END $$;

