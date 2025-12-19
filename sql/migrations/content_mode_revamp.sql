-- Content Mode Revamp Migration
-- 
-- Changes content_mode from 5 values to 4 base layouts:
--   OLD: single, grouped, list, grid, inline
--   NEW: single, grid, list, cards
--
-- Adds grouping support:
--   is_grouped: BOOLEAN (default false)
--   group_display: TEXT ('expanded' or 'collapsed')
--
-- Migration preserves existing data:
--   'inline' → 'cards'
--   'grouped' → 'list' with is_grouped=true, group_display='expanded'

-- Step 1: Add new columns
ALTER TABLE cards 
ADD COLUMN IF NOT EXISTS is_grouped BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS group_display TEXT DEFAULT 'expanded' CHECK (group_display IN ('expanded', 'collapsed'));

-- Step 2: Migrate existing 'grouped' mode to list + is_grouped
UPDATE cards 
SET content_mode = 'list', 
    is_grouped = true, 
    group_display = 'expanded'
WHERE content_mode = 'grouped';

-- Step 3: Migrate 'inline' to 'cards'
UPDATE cards 
SET content_mode = 'cards'
WHERE content_mode = 'inline';

-- Step 4: Update the CHECK constraint for content_mode
-- First, drop the old constraint
ALTER TABLE cards DROP CONSTRAINT IF EXISTS cards_content_mode_check;

-- Then add the new constraint
ALTER TABLE cards ADD CONSTRAINT cards_content_mode_check 
CHECK (content_mode IN ('single', 'grid', 'list', 'cards'));

-- Step 5: Add comment for documentation
COMMENT ON COLUMN cards.content_mode IS 'Base layout type: single (full page), grid (2-column gallery), list (vertical rows), cards (full-width cards)';
COMMENT ON COLUMN cards.is_grouped IS 'Whether content is organized into categories (parent items are category headers)';
COMMENT ON COLUMN cards.group_display IS 'How grouped items are displayed: expanded (inline under category) or collapsed (navigate to see items)';

-- Verify migration
DO $$
DECLARE
    old_grouped_count INTEGER;
    old_inline_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO old_grouped_count FROM cards WHERE content_mode = 'grouped';
    SELECT COUNT(*) INTO old_inline_count FROM cards WHERE content_mode = 'inline';
    
    IF old_grouped_count > 0 OR old_inline_count > 0 THEN
        RAISE EXCEPTION 'Migration incomplete: % grouped and % inline records remain', old_grouped_count, old_inline_count;
    END IF;
    
    RAISE NOTICE 'Migration successful: content_mode revamp complete';
END $$;

