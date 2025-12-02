-- Migration: Update Content Modes
-- Date: 2025-11-29
-- Description: Updates content_mode values from old (solo, stack, catalog, guide) to new (single, grouped, list, grid, inline)

-- Step 1: Update existing cards with old content_mode values to new values
-- Mapping:
--   solo -> single (closest equivalent: single item display)
--   stack -> list (vertical list of items)
--   catalog -> grid (visual grid display)
--   guide -> grouped (hierarchical with categories)

UPDATE cards SET content_mode = 'single' WHERE content_mode = 'solo';
UPDATE cards SET content_mode = 'list' WHERE content_mode = 'stack';
UPDATE cards SET content_mode = 'grid' WHERE content_mode = 'catalog';
UPDATE cards SET content_mode = 'grouped' WHERE content_mode = 'guide';

-- Step 2: Update the CHECK constraint to allow new values
ALTER TABLE cards DROP CONSTRAINT IF EXISTS cards_content_mode_check;
ALTER TABLE cards ADD CONSTRAINT cards_content_mode_check 
    CHECK (content_mode IN ('single', 'grouped', 'list', 'grid', 'inline'));

-- Step 3: Set default to 'list' for new cards
ALTER TABLE cards ALTER COLUMN content_mode SET DEFAULT 'list';

-- Verify the migration
SELECT content_mode, COUNT(*) as count FROM cards GROUP BY content_mode;

