-- Rollback Migration: Revert image_url back to image_urls array
-- Date: 2025-01-13
-- Description: This rollback script reverts the image_url field back to image_urls array

-- Start transaction
BEGIN;

-- 1. Add back the image_urls columns
ALTER TABLE cards ADD COLUMN IF NOT EXISTS image_urls TEXT[];
ALTER TABLE content_items ADD COLUMN IF NOT EXISTS image_urls TEXT[];

-- 2. Migrate data from image_url back to image_urls array
UPDATE cards 
SET image_urls = ARRAY[image_url]
WHERE image_url IS NOT NULL 
  AND image_urls IS NULL;

UPDATE content_items 
SET image_urls = ARRAY[image_url]
WHERE image_url IS NOT NULL 
  AND image_urls IS NULL;

-- 3. Drop the image_url columns
ALTER TABLE cards DROP COLUMN IF EXISTS image_url;
ALTER TABLE content_items DROP COLUMN IF EXISTS image_url;

-- 4. Restore comments
COMMENT ON COLUMN cards.image_urls IS 'Array of image URLs for the card';
COMMENT ON COLUMN content_items.image_urls IS 'Array of image URLs for the content item';

-- Commit transaction
COMMIT;

-- Note: After running this rollback, you'll need to restore the original stored procedures