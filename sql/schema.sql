-- ContentRenderMode enum removed - not used in frontend

DO $$ BEGIN
    CREATE TYPE public."QRCodePosition" AS ENUM (
        'TL', -- Top Left
        'TR', -- Top Right
        'BL', -- Bottom Left
        'BR'  -- Bottom Right
    );
EXCEPTION
    WHEN duplicate_object THEN NULL;
    WHEN insufficient_privilege THEN NULL;
END $$;

DO $$ BEGIN
    CREATE TYPE public."PrintRequestStatus" AS ENUM (
        'SUBMITTED',
        'PAYMENT_PENDING',
        'PROCESSING',
        'SHIPPED',
        'COMPLETED',
        'CANCELLED'
    );
EXCEPTION
    WHEN duplicate_object THEN NULL;
    WHEN insufficient_privilege THEN NULL;
END $$;

DO $$ BEGIN
    CREATE TYPE public."UserRole" AS ENUM (
        'user',
        'cardIssuer',
        'admin'
    );
EXCEPTION
    WHEN duplicate_object THEN NULL;
    WHEN insufficient_privilege THEN NULL;
END $$;

-- Simple audit system - no complex enums, just practical logging

-- Drop tables if they exist
DROP TABLE IF EXISTS print_request_feedbacks CASCADE;
DROP TABLE IF EXISTS print_requests CASCADE;
DROP TABLE IF EXISTS issue_cards CASCADE;
DROP TABLE IF EXISTS card_batches CASCADE;
DROP TABLE IF EXISTS content_items CASCADE;
DROP TABLE IF EXISTS cards CASCADE;
DROP TABLE IF EXISTS admin_feedback_history CASCADE;
DROP TABLE IF EXISTS batch_payments CASCADE;
DROP TABLE IF EXISTS operations_log CASCADE;

-- Cards table
CREATE TABLE cards (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL, -- REFERENCES auth.users(id) if you have auth schema users table
    name TEXT NOT NULL,
    description TEXT DEFAULT '' NOT NULL,
    qr_code_position "QRCodePosition" DEFAULT 'BR',
    image_url TEXT, -- Cropped/processed image for display
    original_image_url TEXT, -- Original uploaded image (raw, uncropped)
    crop_parameters JSONB, -- JSON object containing crop parameters for dynamic image cropping (position, zoom, dimensions, etc.)
    conversation_ai_enabled BOOLEAN DEFAULT false,
    ai_instruction TEXT DEFAULT '' NOT NULL, -- AI role and guidelines (max 100 words) - defines AI's role, personality, and restrictions
    ai_knowledge_base TEXT DEFAULT '' NOT NULL, -- Background knowledge for AI conversations (max 2000 words) - detailed domain knowledge, facts, specifications
    -- Translation system columns
    translations JSONB DEFAULT '{}'::JSONB, -- AI-powered translations: {"zh-Hans": {"name": "...", "description": "...", "translated_at": "...", "content_hash": "..."}}
    original_language VARCHAR(10) DEFAULT 'en', -- ISO 639-1 language code
    content_hash TEXT, -- MD5 hash for detecting content changes
    last_content_update TIMESTAMPTZ DEFAULT NOW(), -- Last update to translatable fields
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add index on user_id for faster user-specific queries
CREATE INDEX IF NOT EXISTS idx_cards_user_id ON cards(user_id);

-- Add GIN index for crop_parameters JSONB column for efficient querying
CREATE INDEX IF NOT EXISTS idx_cards_crop_parameters ON cards USING GIN (crop_parameters);

-- Add GIN index for translations JSONB column
CREATE INDEX IF NOT EXISTS idx_cards_translations ON cards USING GIN (translations);

-- Add index for original_language for analytics
CREATE INDEX IF NOT EXISTS idx_cards_original_language ON cards(original_language);

-- Content items table
CREATE TABLE content_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    card_id UUID NOT NULL REFERENCES cards(id) ON DELETE CASCADE,
    parent_id UUID REFERENCES content_items(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    content TEXT DEFAULT '' NOT NULL, 
    image_url TEXT, -- Cropped/processed image for display
    original_image_url TEXT, -- Original uploaded image (raw, uncropped)
    crop_parameters JSONB, -- JSON object containing crop parameters for dynamic image cropping (position, zoom, dimensions, etc.)
    ai_knowledge_base TEXT DEFAULT '' NOT NULL, -- Content-specific knowledge for AI (max 500 words)
    sort_order INTEGER DEFAULT 0,
    -- Translation system columns
    translations JSONB DEFAULT '{}'::JSONB, -- AI-powered translations: {"zh-Hans": {"name": "...", "content": "...", "ai_knowledge_base": "...", "translated_at": "...", "content_hash": "..."}}
    content_hash TEXT, -- MD5 hash for detecting content changes
    last_content_update TIMESTAMPTZ DEFAULT NOW(), -- Last update to translatable fields
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT content_items_parent_not_self CHECK (parent_id != id)
);

CREATE INDEX IF NOT EXISTS idx_content_items_card_id ON content_items(card_id);
CREATE INDEX IF NOT EXISTS idx_content_items_parent_id ON content_items(parent_id);
CREATE INDEX IF NOT EXISTS idx_content_items_sort_order ON content_items(card_id, parent_id, sort_order);

-- Add GIN index for crop_parameters JSONB column for efficient querying
CREATE INDEX IF NOT EXISTS idx_content_items_crop_parameters ON content_items USING GIN (crop_parameters);

-- Add GIN index for translations JSONB column
CREATE INDEX IF NOT EXISTS idx_content_items_translations ON content_items USING GIN (translations);

-- Card batches table
CREATE TABLE card_batches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    card_id UUID NOT NULL REFERENCES cards(id) ON DELETE CASCADE,
    batch_name TEXT NOT NULL,
    batch_number INTEGER NOT NULL,
    cards_count INTEGER NOT NULL DEFAULT 0,
    is_disabled BOOLEAN DEFAULT FALSE NOT NULL,
    created_by UUID NOT NULL, -- REFERENCES auth.users(id)
    -- Payment tracking fields
    payment_required BOOLEAN DEFAULT TRUE NOT NULL,
    payment_completed BOOLEAN DEFAULT FALSE NOT NULL,
    payment_amount_cents INTEGER, -- Total payment amount in cents ($2 per card = 200 cents per card)
    payment_completed_at TIMESTAMP WITH TIME ZONE,
    -- Admin fee waiver fields
    payment_waived BOOLEAN DEFAULT FALSE NOT NULL,
    payment_waived_by UUID, -- REFERENCES auth.users(id) - admin who waived the fee
    payment_waived_at TIMESTAMP WITH TIME ZONE,
    payment_waiver_reason TEXT, -- Reason for waiving the payment
    -- Cards generation status
    cards_generated BOOLEAN DEFAULT FALSE NOT NULL,
    cards_generated_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT unique_batch_name_per_card UNIQUE (card_id, batch_name),
    CONSTRAINT unique_batch_number_per_card UNIQUE (card_id, batch_number)
);

CREATE INDEX IF NOT EXISTS idx_card_batches_card_id ON card_batches(card_id);
CREATE INDEX IF NOT EXISTS idx_card_batches_created_by ON card_batches(created_by);
CREATE INDEX IF NOT EXISTS idx_card_batches_batch_number ON card_batches(card_id, batch_number);
CREATE INDEX IF NOT EXISTS idx_card_batches_is_disabled ON card_batches(is_disabled);
CREATE INDEX IF NOT EXISTS idx_card_batches_payment_status ON card_batches(payment_completed);
CREATE INDEX IF NOT EXISTS idx_card_batches_payment_waived ON card_batches(payment_waived);
CREATE INDEX IF NOT EXISTS idx_card_batches_waived_by ON card_batches(payment_waived_by);
CREATE INDEX IF NOT EXISTS idx_card_batches_cards_generated ON card_batches(cards_generated);

-- Issued cards table
CREATE TABLE issue_cards (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    card_id UUID NOT NULL REFERENCES cards(id) ON DELETE CASCADE,
    batch_id UUID NOT NULL REFERENCES card_batches(id) ON DELETE CASCADE,
    active BOOLEAN DEFAULT false,
    issue_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    active_at TIMESTAMP WITH TIME ZONE,
    activated_by UUID, -- REFERENCES auth.users(id)
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_issue_cards_card_id ON issue_cards(card_id);
CREATE INDEX IF NOT EXISTS idx_issue_cards_batch_id ON issue_cards(batch_id);
CREATE INDEX IF NOT EXISTS idx_issue_cards_active ON issue_cards(active);

-- Print requests table
CREATE TABLE print_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    batch_id UUID NOT NULL REFERENCES card_batches(id) ON DELETE CASCADE,
    user_id UUID NOT NULL, -- REFERENCES auth.users(id)
    status "PrintRequestStatus" DEFAULT 'SUBMITTED' NOT NULL,
    shipping_address TEXT,
    contact_email TEXT,
    contact_whatsapp TEXT,
    requested_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_print_requests_batch_id ON print_requests(batch_id);
CREATE INDEX IF NOT EXISTS idx_print_requests_user_id ON print_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_print_requests_status ON print_requests(status);

-- Create partial unique index for active print requests only
-- This allows multiple CANCELLED and COMPLETED requests per batch
DROP INDEX IF EXISTS unique_active_print_request_per_batch;
CREATE UNIQUE INDEX unique_active_print_request_per_batch 
ON print_requests(batch_id) 
WHERE status NOT IN ('COMPLETED', 'CANCELLED');

-- Create function for updating timestamps
CREATE OR REPLACE FUNCTION public.update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers for updating the updated_at timestamp
-- MOVED TO sql/triggers.sql

-- Print request feedbacks table
CREATE TABLE print_request_feedbacks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    print_request_id UUID NOT NULL REFERENCES print_requests(id) ON DELETE CASCADE,
    admin_user_id UUID NOT NULL, -- REFERENCES auth.users(id)
    admin_email VARCHAR(255), -- Denormalized for performance
    message TEXT NOT NULL,
    is_internal BOOLEAN DEFAULT FALSE, -- Internal notes vs user-visible feedback
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for print request feedbacks
CREATE INDEX IF NOT EXISTS idx_print_feedbacks_request ON print_request_feedbacks(print_request_id);
CREATE INDEX IF NOT EXISTS idx_print_feedbacks_admin ON print_request_feedbacks(admin_user_id);
CREATE INDEX IF NOT EXISTS idx_print_feedbacks_created ON print_request_feedbacks(created_at DESC);

-- No triggers or views needed - emails handled directly in stored procedures

-- Batch Payments table for tracking Stripe Checkout sessions
-- Supports both existing batch payments and pending batch payments (payment-first flow)
CREATE TABLE batch_payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    batch_id UUID REFERENCES card_batches(id) ON DELETE CASCADE, -- NULL for pending batch payments
    card_id UUID REFERENCES cards(id) ON DELETE CASCADE, -- Required for pending payments
    user_id UUID NOT NULL, -- REFERENCES auth.users(id)
    stripe_checkout_session_id TEXT UNIQUE NOT NULL, -- Primary identifier for Stripe Checkout
    stripe_payment_intent_id TEXT UNIQUE, -- May be null in test mode
    amount_cents INTEGER NOT NULL, -- $2 per card = 200 cents per card
    currency TEXT DEFAULT 'usd' NOT NULL,
    payment_status TEXT DEFAULT 'pending' NOT NULL, -- pending, succeeded, failed, canceled
    payment_method TEXT, -- card type from Stripe (e.g., 'visa', 'mastercard')
    failure_reason TEXT, -- Stripe failure reason if payment fails
    -- Fields for pending batch payments (when batch_id is NULL)
    batch_name TEXT, -- Intended batch name for pending payments
    cards_count INTEGER, -- Number of cards for pending payments
    metadata JSONB, -- Additional metadata for payment tracking
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    -- Ensure either batch exists OR pending batch info is provided
    CONSTRAINT batch_payments_batch_or_pending_check 
    CHECK (
        (batch_id IS NOT NULL) OR 
        (card_id IS NOT NULL AND batch_name IS NOT NULL AND cards_count IS NOT NULL)
    )
);

-- Indexes for efficient querying
CREATE INDEX IF NOT EXISTS idx_batch_payments_batch_id ON batch_payments(batch_id);
CREATE INDEX IF NOT EXISTS idx_batch_payments_user_id ON batch_payments(user_id);
CREATE INDEX IF NOT EXISTS idx_batch_payments_card_id ON batch_payments(card_id);
CREATE INDEX IF NOT EXISTS idx_batch_payments_stripe_intent ON batch_payments(stripe_payment_intent_id);
CREATE INDEX IF NOT EXISTS idx_batch_payments_checkout_session ON batch_payments(stripe_checkout_session_id);
CREATE INDEX IF NOT EXISTS idx_batch_payments_status ON batch_payments(payment_status);
-- Index for pending payments (where batch_id is null)
CREATE INDEX IF NOT EXISTS idx_batch_payments_pending ON batch_payments(card_id, user_id) WHERE batch_id IS NULL;

-- Operations Log table - Simple unified logging for all write operations
CREATE TABLE operations_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL, -- REFERENCES auth.users(id)
    user_role "UserRole" NOT NULL, -- User's role at time of operation
    operation TEXT NOT NULL, -- Simple description of what happened
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for operations log
CREATE INDEX IF NOT EXISTS idx_operations_log_user_id ON operations_log(user_id);
CREATE INDEX IF NOT EXISTS idx_operations_log_user_role ON operations_log(user_role);
CREATE INDEX IF NOT EXISTS idx_operations_log_created_at ON operations_log(created_at DESC);

-- =================================================================
-- CREDIT SYSTEM TABLES
-- =================================================================

-- User Credits Wallet Table
CREATE TABLE IF NOT EXISTS user_credits (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    balance DECIMAL(10, 2) NOT NULL DEFAULT 0 CHECK (balance >= 0),
    total_purchased DECIMAL(10, 2) NOT NULL DEFAULT 0,
    total_consumed DECIMAL(10, 2) NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id)
);

-- Credit Transactions Table (All credit movements)
CREATE TABLE IF NOT EXISTS credit_transactions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    type VARCHAR(20) NOT NULL CHECK (type IN ('purchase', 'consumption', 'refund', 'adjustment')),
    amount DECIMAL(10, 2) NOT NULL,
    balance_before DECIMAL(10, 2) NOT NULL,
    balance_after DECIMAL(10, 2) NOT NULL,
    reference_type VARCHAR(50), -- 'stripe_purchase', 'batch_issuance', 'admin_adjustment', etc.
    reference_id UUID, -- ID of the related record (purchase_id, batch_id, etc.)
    description TEXT,
    metadata JSONB,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Credit Purchases Table (Stripe payment records)
CREATE TABLE IF NOT EXISTS credit_purchases (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    stripe_session_id VARCHAR(255) UNIQUE,
    stripe_payment_intent_id VARCHAR(255),
    amount_usd DECIMAL(10, 2) NOT NULL,
    credits_amount DECIMAL(10, 2) NOT NULL, -- Same as amount_usd (1 credit = 1 USD)
    status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'failed', 'refunded')),
    payment_method JSONB,
    receipt_url TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMPTZ,
    metadata JSONB
);

-- Credit Consumption Table (Track what credits were used for)
CREATE TABLE IF NOT EXISTS credit_consumptions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    batch_id UUID REFERENCES card_batches(id) ON DELETE SET NULL,
    card_id UUID REFERENCES cards(id) ON DELETE SET NULL,
    consumption_type VARCHAR(50) NOT NULL DEFAULT 'batch_issuance', -- 'batch_issuance', 'single_card', 'translation', etc.
    quantity INTEGER NOT NULL DEFAULT 1, -- Number of cards or languages
    credits_per_unit DECIMAL(10, 2) NOT NULL DEFAULT 2.00, -- Credits per card (2.00) or per language (1.00)
    total_credits DECIMAL(10, 2) NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Translation History Table (Track AI-powered translations)
CREATE TABLE IF NOT EXISTS translation_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    card_id UUID NOT NULL REFERENCES cards(id) ON DELETE CASCADE,
    target_languages TEXT[] NOT NULL, -- Array of language codes translated (e.g., ['zh-Hans', 'ja', 'ko'])
    credit_cost DECIMAL(10, 2) NOT NULL, -- Total credits consumed (1 credit per language)
    translated_by UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    translated_at TIMESTAMPTZ DEFAULT NOW(),
    status VARCHAR(20) DEFAULT 'completed' CHECK (status IN ('pending', 'processing', 'completed', 'failed', 'partial')),
    error_message TEXT, -- Error details if translation fails
    metadata JSONB DEFAULT '{}'::JSONB -- Additional metadata (model used, token count, etc.)
);

-- Add credit cost columns to card_batches table (if not exists)
ALTER TABLE card_batches ADD COLUMN IF NOT EXISTS credit_cost DECIMAL(10, 2);
ALTER TABLE card_batches ADD COLUMN IF NOT EXISTS payment_method VARCHAR(20) DEFAULT 'stripe' CHECK (payment_method IN ('stripe', 'credits'));

-- Update existing batches to mark them as stripe payments
UPDATE card_batches SET payment_method = 'stripe' WHERE payment_method IS NULL;

-- Indexes for credit system (DROP first to ensure updates)
DROP INDEX IF EXISTS idx_user_credits_user_id;
DROP INDEX IF EXISTS idx_credit_transactions_user_id;
DROP INDEX IF EXISTS idx_credit_transactions_created_at;
DROP INDEX IF EXISTS idx_credit_transactions_type;
DROP INDEX IF EXISTS idx_credit_purchases_user_id;
DROP INDEX IF EXISTS idx_credit_purchases_status;
DROP INDEX IF EXISTS idx_credit_purchases_created_at;
DROP INDEX IF EXISTS idx_credit_consumptions_user_id;
DROP INDEX IF EXISTS idx_credit_consumptions_batch_id;
DROP INDEX IF EXISTS idx_credit_consumptions_created_at;
DROP INDEX IF EXISTS idx_translation_history_card_id;
DROP INDEX IF EXISTS idx_translation_history_user_id;
DROP INDEX IF EXISTS idx_translation_history_created_at;
DROP INDEX IF EXISTS idx_translation_history_status;

CREATE INDEX idx_user_credits_user_id ON user_credits(user_id);
CREATE INDEX idx_credit_transactions_user_id ON credit_transactions(user_id);
CREATE INDEX idx_credit_transactions_created_at ON credit_transactions(created_at DESC);
CREATE INDEX idx_credit_transactions_type ON credit_transactions(type);
CREATE INDEX idx_credit_purchases_user_id ON credit_purchases(user_id);
CREATE INDEX idx_credit_purchases_status ON credit_purchases(status);
CREATE INDEX idx_credit_purchases_created_at ON credit_purchases(created_at DESC);
CREATE INDEX idx_credit_consumptions_user_id ON credit_consumptions(user_id);
CREATE INDEX idx_credit_consumptions_batch_id ON credit_consumptions(batch_id);
CREATE INDEX idx_credit_consumptions_created_at ON credit_consumptions(created_at DESC);
CREATE INDEX idx_translation_history_card_id ON translation_history(card_id);
CREATE INDEX idx_translation_history_user_id ON translation_history(translated_by);
CREATE INDEX idx_translation_history_created_at ON translation_history(translated_at DESC);
CREATE INDEX idx_translation_history_status ON translation_history(status);

-- Trigger to update user_credits updated_at
CREATE OR REPLACE FUNCTION update_user_credits_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_user_credits_updated_at ON user_credits;
CREATE TRIGGER trigger_update_user_credits_updated_at
    BEFORE UPDATE ON user_credits
    FOR EACH ROW
    EXECUTE FUNCTION update_user_credits_updated_at();