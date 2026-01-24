-- Add 'starter' tier to SubscriptionTier enum
-- Must be run outside of transaction block if possible, but PG 12+ supports it in transaction
ALTER TYPE public."SubscriptionTier" ADD VALUE IF NOT EXISTS 'starter' AFTER 'free';
