-- ===================================================================
-- SAFE MIGRATION SCRIPT FOR AI FIELDS
-- Run this BEFORE deploying schema.sql to preserve existing data
-- ===================================================================

-- STEP 1: Add new columns to cards table (keeping old ones)
-- ===================================================================
DO $$ 
BEGIN
    -- Add ai_instruction column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'cards' AND column_name = 'ai_instruction'
    ) THEN
        ALTER TABLE cards ADD COLUMN ai_instruction TEXT DEFAULT '' NOT NULL;
        RAISE NOTICE 'Added ai_instruction column to cards table';
    END IF;

    -- Add ai_knowledge_base column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'cards' AND column_name = 'ai_knowledge_base'
    ) THEN
        ALTER TABLE cards ADD COLUMN ai_knowledge_base TEXT DEFAULT '' NOT NULL;
        RAISE NOTICE 'Added ai_knowledge_base column to cards table';
    END IF;
END $$;

-- STEP 2: Migrate data from ai_prompt to ai_instruction
-- ===================================================================
DO $$
BEGIN
    -- Check if ai_prompt column exists
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'cards' AND column_name = 'ai_prompt'
    ) THEN
        -- Copy data from ai_prompt to ai_instruction
        UPDATE cards 
        SET ai_instruction = COALESCE(ai_prompt, '')
        WHERE ai_prompt IS NOT NULL AND ai_prompt != '';
        
        RAISE NOTICE 'Migrated % cards from ai_prompt to ai_instruction', 
            (SELECT COUNT(*) FROM cards WHERE ai_prompt IS NOT NULL AND ai_prompt != '');
        
        -- Drop the old column
        ALTER TABLE cards DROP COLUMN ai_prompt;
        RAISE NOTICE 'Dropped ai_prompt column from cards table';
    ELSE
        RAISE NOTICE 'ai_prompt column does not exist, skipping migration';
    END IF;
END $$;

-- STEP 3: Add new column to content_items table (keeping old one)
-- ===================================================================
DO $$ 
BEGIN
    -- Add ai_knowledge_base column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'content_items' AND column_name = 'ai_knowledge_base'
    ) THEN
        ALTER TABLE content_items ADD COLUMN ai_knowledge_base TEXT DEFAULT '' NOT NULL;
        RAISE NOTICE 'Added ai_knowledge_base column to content_items table';
    END IF;
END $$;

-- STEP 4: Migrate data from ai_metadata to ai_knowledge_base
-- ===================================================================
DO $$
BEGIN
    -- Check if ai_metadata column exists
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'content_items' AND column_name = 'ai_metadata'
    ) THEN
        -- Copy data from ai_metadata to ai_knowledge_base
        UPDATE content_items 
        SET ai_knowledge_base = COALESCE(ai_metadata, '')
        WHERE ai_metadata IS NOT NULL AND ai_metadata != '';
        
        RAISE NOTICE 'Migrated % content items from ai_metadata to ai_knowledge_base', 
            (SELECT COUNT(*) FROM content_items WHERE ai_metadata IS NOT NULL AND ai_metadata != '');
        
        -- Drop the old column
        ALTER TABLE content_items DROP COLUMN ai_metadata;
        RAISE NOTICE 'Dropped ai_metadata column from content_items table';
    ELSE
        RAISE NOTICE 'ai_metadata column does not exist, skipping migration';
    END IF;
END $$;

-- STEP 5: Verification
-- ===================================================================
DO $$
DECLARE
    v_cards_count INT;
    v_content_items_count INT;
BEGIN
    -- Check cards table
    SELECT COUNT(*) INTO v_cards_count
    FROM cards
    WHERE ai_instruction IS NOT NULL OR ai_knowledge_base IS NOT NULL;
    
    -- Check content_items table
    SELECT COUNT(*) INTO v_content_items_count
    FROM content_items
    WHERE ai_knowledge_base IS NOT NULL;
    
    RAISE NOTICE '==========================================';
    RAISE NOTICE 'MIGRATION COMPLETE';
    RAISE NOTICE '==========================================';
    RAISE NOTICE 'Cards with AI configuration: %', v_cards_count;
    RAISE NOTICE 'Content items with AI configuration: %', v_content_items_count;
    RAISE NOTICE '==========================================';
    RAISE NOTICE 'Next steps:';
    RAISE NOTICE '1. Deploy sql/all_stored_procedures.sql';
    RAISE NOTICE '2. Verify with test queries';
    RAISE NOTICE '3. Test frontend functionality';
    RAISE NOTICE '==========================================';
END $$;

-- ===================================================================
-- ROLLBACK SCRIPT (Keep this commented out)
-- Run ONLY if you need to rollback the migration
-- ===================================================================

/*
-- Rollback Step 1: Re-add old columns
ALTER TABLE cards ADD COLUMN ai_prompt TEXT;
ALTER TABLE content_items ADD COLUMN ai_metadata TEXT;

-- Rollback Step 2: Copy data back
UPDATE cards SET ai_prompt = ai_instruction WHERE ai_instruction != '';
UPDATE content_items SET ai_metadata = ai_knowledge_base WHERE ai_knowledge_base != '';

-- Rollback Step 3: Drop new columns
ALTER TABLE cards DROP COLUMN ai_instruction;
ALTER TABLE cards DROP COLUMN ai_knowledge_base;
ALTER TABLE content_items DROP COLUMN ai_knowledge_base;
*/

