-- Create enum type for content render modes
DO $$ BEGIN
    CREATE TYPE "ContentRenderMode" AS ENUM (
        'SINGLE_SERIES_MULTI_ITEMS',
        'MULTI_SERIES_NO_ITEMS',
        'MULTI_SERIES_MULTI_ITEMS'
    );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Create enum type for QR Code Position
DO $$ BEGIN
    CREATE TYPE "QRCodePosition" AS ENUM (
        'TL', -- Top Left
        'TR', -- Top Right
        'BL', -- Bottom Left
        'BR'  -- Bottom Right
    );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Create enum type for Print Request Status
DO $$ BEGIN
    CREATE TYPE "PrintRequestStatus" AS ENUM (
        'SUBMITTED',
        'PROCESSING',
        'SHIPPING',
        'COMPLETED',
        'CANCELLED'
    );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Create enum type for Profile Status
DO $$ BEGIN
    CREATE TYPE "ProfileStatus" AS ENUM (
        'NOT_SUBMITTED',
        'PENDING_REVIEW',
        'APPROVED',
        'REJECTED'
    );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Create enum type for UserRole
DO $$ BEGIN
    CREATE TYPE "UserRole" AS ENUM (
        'user',
        'cardIssuer',
        'admin'
    );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Drop tables if they exist
DROP TABLE IF EXISTS print_requests CASCADE;
DROP TABLE IF EXISTS issue_cards CASCADE;
DROP TABLE IF EXISTS card_batches CASCADE;
DROP TABLE IF EXISTS content_items CASCADE;
DROP TABLE IF EXISTS cards CASCADE;
DROP TABLE IF EXISTS user_profiles CASCADE;
DROP TABLE IF EXISTS admin_audit_log CASCADE;
DROP TABLE IF EXISTS admin_feedback_history CASCADE;
DROP TABLE IF EXISTS batch_payments CASCADE;
DROP TABLE IF EXISTS shipping_addresses CASCADE;

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
    admin_feedback TEXT,
    verified_at TIMESTAMP WITH TIME ZONE, -- When verification was completed
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Shipping Addresses table
CREATE TABLE shipping_addresses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    label TEXT NOT NULL, -- e.g., "Home", "Office", "Warehouse"
    recipient_name TEXT NOT NULL,
    address_line1 TEXT NOT NULL,
    address_line2 TEXT,
    city TEXT NOT NULL,
    state_province TEXT NOT NULL,
    postal_code TEXT NOT NULL,
    country TEXT NOT NULL,
    phone TEXT,
    is_default BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Ensure only one default address per user
CREATE UNIQUE INDEX idx_shipping_addresses_default_per_user 
ON shipping_addresses(user_id) 
WHERE is_default = true;

-- Add indexes for efficient querying
CREATE INDEX IF NOT EXISTS idx_shipping_addresses_user_id ON shipping_addresses(user_id);
CREATE INDEX IF NOT EXISTS idx_shipping_addresses_is_default ON shipping_addresses(is_default);

-- Cards table
CREATE TABLE cards (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL, -- REFERENCES auth.users(id) if you have auth schema users table
    name TEXT NOT NULL,
    description TEXT DEFAULT '' NOT NULL,
    content_render_mode "ContentRenderMode" DEFAULT 'SINGLE_SERIES_MULTI_ITEMS',
    qr_code_position "QRCodePosition" DEFAULT 'BR',
    image_url TEXT,
    conversation_ai_enabled BOOLEAN DEFAULT false,
    ai_prompt TEXT DEFAULT '' NOT NULL, -- Instructions for AI assistance when answering content item questions
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add index on user_id for faster user-specific queries
CREATE INDEX IF NOT EXISTS idx_cards_user_id ON cards(user_id);

-- Content items table
CREATE TABLE content_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    card_id UUID NOT NULL REFERENCES cards(id) ON DELETE CASCADE,
    parent_id UUID REFERENCES content_items(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    content TEXT DEFAULT '' NOT NULL, 
    image_url TEXT,
    ai_metadata TEXT DEFAULT '' NOT NULL,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT content_items_parent_not_self CHECK (parent_id != id)
);

CREATE INDEX IF NOT EXISTS idx_content_items_card_id ON content_items(card_id);
CREATE INDEX IF NOT EXISTS idx_content_items_parent_id ON content_items(parent_id);
CREATE INDEX IF NOT EXISTS idx_content_items_sort_order ON content_items(card_id, parent_id, sort_order);

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
    admin_notes TEXT,
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

-- Admin Audit Log table for tracking administrative actions
CREATE TABLE admin_audit_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    admin_user_id UUID NOT NULL, -- REFERENCES auth.users(id) - who performed the action
    target_user_id UUID, -- REFERENCES auth.users(id) - who was affected (nullable for system-wide actions)
    action_type TEXT NOT NULL, -- e.g., 'ROLE_CHANGE', 'MANUAL_VERIFICATION', 'RESET_VERIFICATION', 'STATUS_UPDATE'
    action_details JSONB, -- Flexible field for action-specific data
    reason TEXT NOT NULL, -- The reason provided by the admin
    old_values JSONB, -- Previous state (for changes)
    new_values JSONB, -- New state (for changes)
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for efficient querying
CREATE INDEX IF NOT EXISTS idx_admin_audit_admin_user ON admin_audit_log(admin_user_id);
CREATE INDEX IF NOT EXISTS idx_admin_audit_target_user ON admin_audit_log(target_user_id);
CREATE INDEX IF NOT EXISTS idx_admin_audit_action_type ON admin_audit_log(action_type);
CREATE INDEX IF NOT EXISTS idx_admin_audit_created_at ON admin_audit_log(created_at);

-- Admin Feedback History table for tracking all admin feedback/notes with full editability
CREATE TABLE admin_feedback_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    admin_user_id UUID NOT NULL, -- REFERENCES auth.users(id) - who created/edited the feedback
    target_user_id UUID, -- REFERENCES auth.users(id) - who this feedback is about (for verification feedback)
    target_entity_type TEXT NOT NULL, -- 'user_verification', 'print_request', 'role_change', 'general_admin_action'
    target_entity_id UUID, -- ID of the specific entity (print_request.id, verification target user, etc.)
    feedback_type TEXT NOT NULL, -- 'verification_feedback', 'print_notes', 'role_change_reason', 'admin_notes'
    content TEXT NOT NULL, -- The actual feedback/notes content
    is_current BOOLEAN DEFAULT TRUE, -- Whether this is the current version
    version_number INTEGER DEFAULT 1, -- Version number for this feedback thread
    parent_feedback_id UUID REFERENCES admin_feedback_history(id), -- Links to previous version if edited
    action_context JSONB, -- Additional context (status changes, etc.)
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for efficient querying
CREATE INDEX IF NOT EXISTS idx_admin_feedback_admin_user ON admin_feedback_history(admin_user_id);
CREATE INDEX IF NOT EXISTS idx_admin_feedback_target_user ON admin_feedback_history(target_user_id);
CREATE INDEX IF NOT EXISTS idx_admin_feedback_target_entity ON admin_feedback_history(target_entity_type, target_entity_id);
CREATE INDEX IF NOT EXISTS idx_admin_feedback_current ON admin_feedback_history(is_current);
CREATE INDEX IF NOT EXISTS idx_admin_feedback_type ON admin_feedback_history(feedback_type);
CREATE INDEX IF NOT EXISTS idx_admin_feedback_created ON admin_feedback_history(created_at);

-- Constraint to ensure only one current version per feedback thread
CREATE UNIQUE INDEX idx_admin_feedback_current_unique 
ON admin_feedback_history(target_entity_type, target_entity_id, feedback_type) 
WHERE is_current = TRUE;

-- Batch Payments table for tracking Stripe Checkout sessions
CREATE TABLE batch_payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    batch_id UUID REFERENCES card_batches(id) ON DELETE CASCADE,
    user_id UUID NOT NULL, -- REFERENCES auth.users(id)
    stripe_checkout_session_id TEXT UNIQUE NOT NULL, -- Primary identifier for Stripe Checkout
    stripe_payment_intent_id TEXT UNIQUE, -- May be null in test mode
    amount_cents INTEGER NOT NULL, -- $2 per card = 200 cents per card
    currency TEXT DEFAULT 'usd' NOT NULL,
    payment_status TEXT DEFAULT 'pending' NOT NULL, -- pending, succeeded, failed, canceled
    payment_method TEXT, -- card type from Stripe (e.g., 'visa', 'mastercard')
    failure_reason TEXT, -- Stripe failure reason if payment fails
    metadata JSONB, -- Additional metadata for payment tracking
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for efficient querying
CREATE INDEX IF NOT EXISTS idx_batch_payments_batch_id ON batch_payments(batch_id);
CREATE INDEX IF NOT EXISTS idx_batch_payments_user_id ON batch_payments(user_id);
CREATE INDEX IF NOT EXISTS idx_batch_payments_stripe_intent ON batch_payments(stripe_payment_intent_id);
CREATE INDEX IF NOT EXISTS idx_batch_payments_checkout_session ON batch_payments(stripe_checkout_session_id);
CREATE INDEX IF NOT EXISTS idx_batch_payments_status ON batch_payments(payment_status);