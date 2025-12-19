-- Migration: Add Digital Access Daily Tracking
-- Date: 2025-12-02
-- Purpose: Add columns for daily scan tracking and credit-based charging for digital access

-- Add daily scan limit column (NULL = unlimited, default 500)
ALTER TABLE cards ADD COLUMN IF NOT EXISTS daily_scan_limit INTEGER DEFAULT 500;

-- Add daily scans counter
ALTER TABLE cards ADD COLUMN IF NOT EXISTS daily_scans INTEGER DEFAULT 0;

-- Add last scan date for daily reset
ALTER TABLE cards ADD COLUMN IF NOT EXISTS last_scan_date DATE DEFAULT CURRENT_DATE;

-- Add index for efficient daily reset queries
CREATE INDEX IF NOT EXISTS idx_cards_last_scan_date ON cards(last_scan_date) WHERE billing_type = 'digital';

-- Comment on columns
COMMENT ON COLUMN cards.daily_scan_limit IS 'Maximum scans allowed per day for digital access. NULL = unlimited. Default: 500';
COMMENT ON COLUMN cards.daily_scans IS 'Number of scans today for digital access. Resets daily.';
COMMENT ON COLUMN cards.last_scan_date IS 'Date of last scan, used to reset daily_scans counter.';

