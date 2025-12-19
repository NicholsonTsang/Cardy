-- Migration: Add updated_at column to credit tables for daily aggregation support
-- This enables the consume_credit_for_digital_scan function to aggregate scans per day

-- Ensure card_id exists in credit_consumptions (might be missing in older schemas)
ALTER TABLE credit_consumptions
ADD COLUMN IF NOT EXISTS card_id UUID REFERENCES cards(id) ON DELETE SET NULL;

-- Add updated_at to credit_transactions
ALTER TABLE credit_transactions 
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP;

-- Add updated_at to credit_consumptions
ALTER TABLE credit_consumptions 
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP;

-- Create indexes for efficient daily aggregation queries
-- Note: Using (created_at::date) requires casting in AT TIME ZONE to be immutable-safe
-- For simplicity, we index the full timestamp and let queries filter by date range
CREATE INDEX IF NOT EXISTS idx_credit_consumptions_daily_lookup 
ON credit_consumptions (user_id, card_id, consumption_type, created_at);

CREATE INDEX IF NOT EXISTS idx_credit_transactions_daily_lookup 
ON credit_transactions (user_id, reference_type, reference_id, created_at);

-- Comment explaining the aggregation strategy
COMMENT ON COLUMN credit_consumptions.quantity IS 
  'For digital_scan type: Number of scans aggregated for this card on this day';

COMMENT ON COLUMN credit_consumptions.total_credits IS 
  'For digital_scan type: Total credits consumed for this card on this day (quantity × credits_per_unit)';
