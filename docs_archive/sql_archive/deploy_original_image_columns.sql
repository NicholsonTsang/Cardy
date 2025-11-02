-- =================================================================
-- DEPLOY ORIGINAL IMAGE URL COLUMNS
-- Adds original_image_url columns without dropping existing data
-- =================================================================

BEGIN;

-- Add original_image_url column to cards table
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'cards' 
        AND column_name = 'original_image_url'
    ) THEN
        ALTER TABLE cards ADD COLUMN original_image_url TEXT;
        RAISE NOTICE '✅ Added original_image_url to cards table';
    ELSE
        RAISE NOTICE 'ℹ️  Column original_image_url already exists in cards table';
    END IF;
END $$;

-- Add original_image_url column to content_items table
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'content_items' 
        AND column_name = 'original_image_url'
    ) THEN
        ALTER TABLE content_items ADD COLUMN original_image_url TEXT;
        RAISE NOTICE '✅ Added original_image_url to content_items table';
    ELSE
        RAISE NOTICE 'ℹ️  Column original_image_url already exists in content_items table';
    END IF;
END $$;

COMMIT;

