-- Migration: Convert image_urls array to single image_url
-- Date: 2025-01-13
-- Description: This migration converts the image_urls array field to a single image_url text field
--              for both cards and content_items tables, taking the first element of the array

-- Start transaction
BEGIN;

-- 1. Add new image_url columns
ALTER TABLE cards ADD COLUMN IF NOT EXISTS image_url TEXT;
ALTER TABLE content_items ADD COLUMN IF NOT EXISTS image_url TEXT;

-- 2. Migrate data from image_urls to image_url (take first element of array)
UPDATE cards 
SET image_url = image_urls[1] 
WHERE image_urls IS NOT NULL 
  AND array_length(image_urls, 1) > 0
  AND image_url IS NULL;

UPDATE content_items 
SET image_url = image_urls[1] 
WHERE image_urls IS NOT NULL 
  AND array_length(image_urls, 1) > 0
  AND image_url IS NULL;

-- 3. Drop the old image_urls columns
ALTER TABLE cards DROP COLUMN IF EXISTS image_urls;
ALTER TABLE content_items DROP COLUMN IF EXISTS image_urls;

-- 4. Update all stored procedures to use image_url instead of image_urls
-- Note: Run the updated stored procedure files after this migration

-- 5. Add comments to document the change
COMMENT ON COLUMN cards.image_url IS 'Single image URL for the card (previously image_urls array)';
COMMENT ON COLUMN content_items.image_url IS 'Single image URL for the content item (previously image_urls array)';

-- Commit transaction
COMMIT;

-- Verification queries (run these manually to verify migration success)
-- SELECT id, name, image_url FROM cards WHERE image_url IS NOT NULL LIMIT 10;
-- SELECT id, name, image_url FROM content_items WHERE image_url IS NOT NULL LIMIT 10;