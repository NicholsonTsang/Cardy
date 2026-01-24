-- Migration: Add AI Welcome Message Fields
-- Description: Allows card creators to customize the welcome messages for both General and Item AI assistants
-- Date: 2025-12-07

-- Add ai_welcome_general column for General/Card-Level AI Assistant welcome message
ALTER TABLE cards ADD COLUMN IF NOT EXISTS ai_welcome_general TEXT DEFAULT '' NOT NULL;

-- Add ai_welcome_item column for Content Item AI Assistant welcome message  
ALTER TABLE cards ADD COLUMN IF NOT EXISTS ai_welcome_item TEXT DEFAULT '' NOT NULL;

-- Add comments for documentation
COMMENT ON COLUMN cards.ai_welcome_general IS 'Custom welcome message for General AI Assistant (card-level). Max ~100 words. Shown when user opens the general AI chat.';
COMMENT ON COLUMN cards.ai_welcome_item IS 'Custom welcome message for Content Item AI Assistant. Max ~100 words. Shown when user opens AI chat for specific content items. Use {name} placeholder for item name.';











