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
        'PROCESSING',
        'SHIPPING',
        'COMPLETED',
        'CANCELLED'
    );
EXCEPTION
    WHEN duplicate_object THEN NULL;
    WHEN insufficient_privilege THEN NULL;
END $$;

DO $$ BEGIN
    CREATE TYPE public."ProfileStatus" AS ENUM (
        'NOT_SUBMITTED',
        'PENDING_REVIEW',
        'APPROVED',
        'REJECTED'
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
DROP TABLE IF EXISTS verification_feedbacks CASCADE;
DROP TABLE IF EXISTS print_requests CASCADE;
DROP TABLE IF EXISTS issue_cards CASCADE;
DROP TABLE IF EXISTS card_batches CASCADE;
DROP TABLE IF EXISTS content_items CASCADE;
DROP TABLE IF EXISTS cards CASCADE;
DROP TABLE IF EXISTS user_profiles CASCADE;
DROP TABLE IF EXISTS admin_audit_log CASCADE;
DROP TABLE IF EXISTS admin_feedback_history CASCADE;
DROP TABLE IF EXISTS batch_payments CASCADE;

-- User Profiles table
CREATE TABLE user_profiles (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    public_name TEXT, -- Display name for public use (required for basic profile)
    bio TEXT, -- User description (required for basic profile)
    company_name TEXT, -- Optional company info
    -- Verification fields (only filled during verification process)
    full_name TEXT, -- Legal name for verification (only required during verification)
    verification_status "ProfileStatus" DEFAULT 'NOT_SUBMITTED' NOT NULL,
    supporting_documents TEXT[],
    verified_at TIMESTAMP WITH TIME ZONE, -- When verification was completed
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);


-- Cards table
CREATE TABLE cards (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL, -- REFERENCES auth.users(id) if you have auth schema users table
    name TEXT NOT NULL,
    description TEXT DEFAULT '' NOT NULL,
    qr_code_position "QRCodePosition" DEFAULT 'BR',
    image_url TEXT,
    crop_parameters JSONB, -- JSON object containing crop parameters for dynamic image cropping (position, zoom, dimensions, etc.)
    conversation_ai_enabled BOOLEAN DEFAULT false,
    ai_prompt TEXT DEFAULT '' NOT NULL, -- Instructions for AI assistance when answering content item questions
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add index on user_id for faster user-specific queries
CREATE INDEX IF NOT EXISTS idx_cards_user_id ON cards(user_id);

-- Add GIN index for crop_parameters JSONB column for efficient querying
CREATE INDEX IF NOT EXISTS idx_cards_crop_parameters ON cards USING GIN (crop_parameters);

-- Content items table
CREATE TABLE content_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    card_id UUID NOT NULL REFERENCES cards(id) ON DELETE CASCADE,
    parent_id UUID REFERENCES content_items(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    content TEXT DEFAULT '' NOT NULL, 
    image_url TEXT,
    crop_parameters JSONB, -- JSON object containing crop parameters for dynamic image cropping (position, zoom, dimensions, etc.)
    ai_metadata TEXT DEFAULT '' NOT NULL,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT content_items_parent_not_self CHECK (parent_id != id)
);

CREATE INDEX IF NOT EXISTS idx_content_items_card_id ON content_items(card_id);
CREATE INDEX IF NOT EXISTS idx_content_items_parent_id ON content_items(parent_id);
CREATE INDEX IF NOT EXISTS idx_content_items_sort_order ON content_items(card_id, parent_id, sort_order);

-- Add GIN index for crop_parameters JSONB column for efficient querying
CREATE INDEX IF NOT EXISTS idx_content_items_crop_parameters ON content_items USING GIN (crop_parameters);

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
DROP TRIGGER IF EXISTS update_user_profiles_updated_at ON user_profiles;
CREATE TRIGGER update_user_profiles_updated_at
    BEFORE UPDATE ON user_profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();

-- =================================================================
-- SIMPLIFIED AUDIT SYSTEM
-- Simple admin action logging and feedback
-- =================================================================

-- Simple admin audit log - just track what admins do
CREATE TABLE admin_audit_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    admin_user_id UUID NOT NULL,
    admin_email VARCHAR(255),
    target_user_id UUID,
    target_user_email VARCHAR(255),
    action_type VARCHAR(50) NOT NULL, -- Simple text field
    description TEXT NOT NULL, -- What happened
    details JSONB, -- Any additional data
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Verification feedbacks table (best practice: separate tables for different entities)
CREATE TABLE verification_feedbacks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES user_profiles(user_id) ON DELETE CASCADE,
    admin_user_id UUID NOT NULL, -- REFERENCES auth.users(id)
    admin_email VARCHAR(255), -- Denormalized for performance
    message TEXT NOT NULL,
    is_internal BOOLEAN DEFAULT FALSE, -- Internal notes vs user-visible feedback
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

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

-- Simple indexes for audit system
CREATE INDEX IF NOT EXISTS idx_audit_admin_user ON admin_audit_log(admin_user_id);
CREATE INDEX IF NOT EXISTS idx_audit_action_type ON admin_audit_log(action_type);
CREATE INDEX IF NOT EXISTS idx_audit_created_at ON admin_audit_log(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_target_user ON admin_audit_log(target_user_id);

-- Indexes for verification feedbacks
CREATE INDEX IF NOT EXISTS idx_verification_feedbacks_user ON verification_feedbacks(user_id);
CREATE INDEX IF NOT EXISTS idx_verification_feedbacks_admin ON verification_feedbacks(admin_user_id);
CREATE INDEX IF NOT EXISTS idx_verification_feedbacks_created ON verification_feedbacks(created_at DESC);

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