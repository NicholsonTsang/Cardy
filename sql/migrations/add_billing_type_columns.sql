-- Migration: Add content_mode and billing_type columns to cards table
-- This migration adds support for:
-- 1. Content modes (solo, stack, catalog, guide) for different mobile layouts
-- 2. Dual pricing models (Physical vs Digital)
-- Run this on existing databases to enable the new features

-- Add content_mode column for rendering layout
ALTER TABLE cards ADD COLUMN IF NOT EXISTS content_mode TEXT DEFAULT 'catalog' CHECK (content_mode IN ('solo', 'stack', 'catalog', 'guide'));

-- Add billing_type column
ALTER TABLE cards ADD COLUMN IF NOT EXISTS billing_type TEXT DEFAULT 'physical' CHECK (billing_type IN ('physical', 'digital'));

-- Add max_scans column (NULL = Unlimited for Physical, Integer for Digital)
ALTER TABLE cards ADD COLUMN IF NOT EXISTS max_scans INTEGER DEFAULT NULL;

-- Add current_scans counter for Digital billing
ALTER TABLE cards ADD COLUMN IF NOT EXISTS current_scans INTEGER DEFAULT 0;

-- Create index for content_mode queries
CREATE INDEX IF NOT EXISTS idx_cards_content_mode ON cards(content_mode);

-- Create index for billing_type queries
CREATE INDEX IF NOT EXISTS idx_cards_billing_type ON cards(billing_type);

-- Create index for traffic monitoring (Digital cards)
CREATE INDEX IF NOT EXISTS idx_cards_current_scans ON cards(current_scans) WHERE billing_type = 'digital';

-- Update existing cards to explicitly set defaults (all existing cards are catalog/physical)
UPDATE cards SET content_mode = 'catalog' WHERE content_mode IS NULL;
UPDATE cards SET billing_type = 'physical' WHERE billing_type IS NULL;

COMMENT ON COLUMN cards.content_mode IS 'Rendering mode: solo = profile, stack = links, catalog = grid, guide = tour';
COMMENT ON COLUMN cards.billing_type IS 'Pricing model: physical = per-card fee ($2/card), digital = per-access credits';
COMMENT ON COLUMN cards.max_scans IS 'Traffic limit for Digital billing. NULL = Unlimited (Physical default)';
COMMENT ON COLUMN cards.current_scans IS 'Current scan count for Digital billing metering';

