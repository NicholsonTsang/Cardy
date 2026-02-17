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
    CREATE TYPE public."UserRole" AS ENUM (
        'user',
        'cardIssuer',
        'admin'
    );
EXCEPTION
    WHEN duplicate_object THEN NULL;
    WHEN insufficient_privilege THEN NULL;
END $$;

-- ProfileStatus enum removed - verification feature was never implemented
-- No frontend components or routes use verification functionality

-- Simple audit system - no complex enums, just practical logging

-- Drop tables if they exist (in dependency order)
DROP TABLE IF EXISTS content_templates CASCADE;
DROP TABLE IF EXISTS content_items CASCADE;
DROP TABLE IF EXISTS cards CASCADE;
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
    realtime_voice_enabled BOOLEAN DEFAULT FALSE, -- Whether realtime voice conversations are enabled (requires voice credits)
    ai_instruction TEXT DEFAULT '' NOT NULL, -- AI role and guidelines (max 100 words) - defines AI's role, personality, and restrictions
    ai_knowledge_base TEXT DEFAULT '' NOT NULL, -- Background knowledge for AI conversations (max 2000 words) - detailed domain knowledge, facts, specifications
    ai_welcome_general TEXT DEFAULT '' NOT NULL, -- Custom welcome message for General AI Assistant (card-level)
    ai_welcome_item TEXT DEFAULT '' NOT NULL, -- Custom welcome message for Content Item AI Assistant. Use {name} for item name
    -- Content mode for rendering (determines mobile layout)
    content_mode TEXT DEFAULT 'list' CHECK (content_mode IN ('single', 'grid', 'list', 'cards')), -- single = one page, grid = 2-col gallery, list = vertical rows, cards = full-width cards
    is_grouped BOOLEAN DEFAULT false, -- Whether content is organized into categories
    group_display TEXT DEFAULT 'expanded' CHECK (group_display IN ('expanded', 'collapsed')), -- expanded = items shown inline, collapsed = navigate to see items
    -- Digital Access Configuration
    -- Note: conversation_ai_enabled (above) determines session billing rate (AI vs non-AI)
    -- Billing: Monthly subscription budget per user (tracked in Redis), not per-project limits
    billing_type TEXT DEFAULT 'digital' CHECK (billing_type = 'digital'), -- digital = per-session subscription
    -- Default daily limit for new QR codes created under this project
    default_daily_session_limit INTEGER DEFAULT 500, -- Default daily session limit for new QR codes (NULL = unlimited)
    -- Note: Session tracking is now per-QR-code in card_access_tokens table
    -- Translation system columns
    -- translations JSONB structure for cards:
    -- {
    --   "zh-Hans": {
    --     "name": "...",
    --     "description": "...",
    --     "ai_instruction": "...",
    --     "ai_knowledge_base": "...",
    --     "ai_welcome_general": "...",
    --     "ai_welcome_item": "...",
    --     "content_hash": "...",
    --     "translated_at": "..."
    --   }
    -- }
    translations JSONB DEFAULT '{}'::JSONB,
    original_language VARCHAR(10) DEFAULT 'en', -- ISO 639-1 language code
    content_hash TEXT, -- MD5 hash for detecting content changes
    last_content_update TIMESTAMPTZ DEFAULT NOW(), -- Last update to translatable fields
    metadata JSONB DEFAULT '{}'::JSONB, -- Extensible metadata for future features (avoids schema changes)
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

-- Card Access Tokens table (Multiple QR codes per project)
-- Each project can have multiple QR codes with individual settings
DROP TABLE IF EXISTS card_access_tokens CASCADE;
CREATE TABLE card_access_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    card_id UUID NOT NULL REFERENCES cards(id) ON DELETE CASCADE,
    name TEXT DEFAULT 'Default', -- Display name for the QR code (e.g., "Front Entrance", "Table 5", "Menu QR")
    access_token TEXT UNIQUE NOT NULL, -- 12-char URL-safe token for access URL
    is_enabled BOOLEAN DEFAULT true, -- Toggle to enable/disable this specific QR code
    daily_session_limit INTEGER DEFAULT NULL, -- Daily session limit for this QR (NULL = unlimited)
    -- Session counters (display purposes - Redis is source of truth for billing)
    total_sessions INTEGER DEFAULT 0, -- All-time sessions for this QR code
    daily_sessions INTEGER DEFAULT 0, -- Today's session count
    monthly_sessions INTEGER DEFAULT 0, -- Current month's session count (resets on 1st)
    last_session_date DATE DEFAULT NULL, -- Date of last session (for daily reset)
    current_month DATE DEFAULT NULL, -- Month being tracked (for monthly reset, stores 1st of month)
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for card_access_tokens
CREATE INDEX IF NOT EXISTS idx_card_access_tokens_card_id ON card_access_tokens(card_id);
CREATE INDEX IF NOT EXISTS idx_card_access_tokens_access_token ON card_access_tokens(access_token);
CREATE INDEX IF NOT EXISTS idx_card_access_tokens_enabled ON card_access_tokens(is_enabled) WHERE is_enabled = true;

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
    -- translations JSONB structure for content_items:
    -- {
    --   "zh-Hans": {
    --     "name": "...",
    --     "content": "...",
    --     "ai_knowledge_base": "...",
    --     "content_hash": "...",
    --     "translated_at": "..."
    --   }
    -- }
    translations JSONB DEFAULT '{}'::JSONB,
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
    reference_type VARCHAR(50), -- 'stripe_purchase', 'session_budget_topup', 'admin_adjustment', etc.
    reference_id UUID, -- ID of the related record (purchase_id, etc.)
    description TEXT,
    metadata JSONB,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
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
-- Note: Session budget top-ups are tracked simply as 'session_budget_topup' type
-- Redis is source of truth for actual budget tracking; this is just for audit/history
CREATE TABLE IF NOT EXISTS credit_consumptions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    card_id UUID REFERENCES cards(id) ON DELETE SET NULL,
    consumption_type VARCHAR(50) NOT NULL DEFAULT 'session_budget_topup', -- 'translation', 'session_budget_topup', 'digital_scan'
    quantity INTEGER NOT NULL DEFAULT 1, -- Number of languages or sessions
    credits_per_unit DECIMAL(10, 2) NOT NULL DEFAULT 1.00, -- Credits per unit
    total_credits DECIMAL(10, 2) NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
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

-- Indexes for credit system (DROP first to ensure updates)
DROP INDEX IF EXISTS idx_user_credits_user_id;
DROP INDEX IF EXISTS idx_credit_transactions_user_id;
DROP INDEX IF EXISTS idx_credit_transactions_created_at;
DROP INDEX IF EXISTS idx_credit_transactions_type;
DROP INDEX IF EXISTS idx_credit_purchases_user_id;
DROP INDEX IF EXISTS idx_credit_purchases_status;
DROP INDEX IF EXISTS idx_credit_purchases_created_at;
DROP INDEX IF EXISTS idx_credit_consumptions_user_id;
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
CREATE INDEX idx_credit_consumptions_created_at ON credit_consumptions(created_at DESC);
CREATE INDEX idx_translation_history_card_id ON translation_history(card_id);
CREATE INDEX idx_translation_history_user_id ON translation_history(translated_by);
CREATE INDEX idx_translation_history_created_at ON translation_history(translated_at DESC);
CREATE INDEX idx_translation_history_status ON translation_history(status);

-- =================================================================
-- VOICE CREDIT SYSTEM TABLES
-- =================================================================

-- Voice credit balance per user (integer-based, not decimal like general credits)
CREATE TABLE IF NOT EXISTS voice_credits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    balance INTEGER NOT NULL DEFAULT 0,  -- number of voice calls remaining
    total_purchased INTEGER NOT NULL DEFAULT 0,
    total_consumed INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id)
);

-- Voice credit transaction log
CREATE TABLE IF NOT EXISTS voice_credit_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    amount INTEGER NOT NULL,  -- positive = purchase, negative = usage
    balance_before INTEGER NOT NULL,
    balance_after INTEGER NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('purchase', 'usage', 'refund', 'admin_adjustment')),
    description TEXT,
    stripe_session_id TEXT,  -- for purchases
    card_id UUID REFERENCES cards(id) ON DELETE SET NULL,  -- for usage
    session_id TEXT,  -- visitor session for usage tracking
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Voice call log for analytics
CREATE TABLE IF NOT EXISTS voice_call_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    card_id UUID NOT NULL REFERENCES cards(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,  -- card owner
    session_id TEXT,  -- visitor session
    started_at TIMESTAMPTZ DEFAULT NOW(),
    ended_at TIMESTAMPTZ,
    duration_seconds INTEGER,
    credit_deducted BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS policies (all access via stored procedures with service_role)
ALTER TABLE voice_credits ENABLE ROW LEVEL SECURITY;
ALTER TABLE voice_credit_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE voice_call_log ENABLE ROW LEVEL SECURITY;

-- Indexes for voice credit system
CREATE INDEX IF NOT EXISTS idx_voice_credits_user_id ON voice_credits(user_id);
CREATE INDEX IF NOT EXISTS idx_voice_credit_transactions_user_id ON voice_credit_transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_voice_credit_transactions_created_at ON voice_credit_transactions(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_voice_credit_transactions_type ON voice_credit_transactions(type);
CREATE INDEX IF NOT EXISTS idx_voice_call_log_card_id ON voice_call_log(card_id);
CREATE INDEX IF NOT EXISTS idx_voice_call_log_user_id ON voice_call_log(user_id);
CREATE INDEX IF NOT EXISTS idx_voice_call_log_session_id ON voice_call_log(session_id);
CREATE INDEX IF NOT EXISTS idx_voice_call_log_started_at ON voice_call_log(started_at DESC);

COMMENT ON TABLE voice_credits IS 'Voice call credit balance per user (integer-based, 1 credit = 1 voice call)';
COMMENT ON TABLE voice_credit_transactions IS 'Audit log of all voice credit movements';
COMMENT ON TABLE voice_call_log IS 'Log of all voice calls for analytics and billing';

-- =================================================================
-- CONTENT TEMPLATES LIBRARY
-- =================================================================
-- Template library for users to browse and import pre-built content templates
-- Templates link to actual cards records - allowing full reuse of card/content item components
-- When users import a template, the card and its content items are copied to a new card

-- Content Templates Table (links to cards table)
CREATE TABLE IF NOT EXISTS content_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    slug TEXT UNIQUE NOT NULL, -- URL-friendly identifier (e.g., 'art-gallery-grid')
    
    -- Link to actual card record (contains all card data and content items)
    card_id UUID NOT NULL REFERENCES cards(id) ON DELETE CASCADE,
    
    -- Admin management fields only
    -- Venue types: museum, restaurant, event, retail, hospitality, gallery, conference, tour,
    --              auction, spa, entertainment, education, winery, sports, realestate, automotive, general
    venue_type TEXT, -- Optional category for filtering
    is_featured BOOLEAN DEFAULT false, -- Show in featured section
    is_active BOOLEAN DEFAULT true, -- Can be imported by users
    sort_order INTEGER DEFAULT 0, -- Display order
    import_count INTEGER DEFAULT 0, -- Track how many times imported
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for efficient querying
CREATE INDEX IF NOT EXISTS idx_content_templates_slug ON content_templates(slug);
CREATE INDEX IF NOT EXISTS idx_content_templates_card_id ON content_templates(card_id);
CREATE INDEX IF NOT EXISTS idx_content_templates_venue_type ON content_templates(venue_type);
CREATE INDEX IF NOT EXISTS idx_content_templates_is_featured ON content_templates(is_featured);
CREATE INDEX IF NOT EXISTS idx_content_templates_is_active ON content_templates(is_active);
CREATE INDEX IF NOT EXISTS idx_content_templates_sort_order ON content_templates(sort_order);

COMMENT ON TABLE content_templates IS 'Pre-built content templates that link to actual cards records';
COMMENT ON COLUMN content_templates.slug IS 'URL-friendly unique identifier for the template';
COMMENT ON COLUMN content_templates.card_id IS 'Reference to the actual card record containing all card data and content items';

-- =================================================================
-- SUBSCRIPTIONS TABLE
-- =================================================================
DROP TYPE IF EXISTS public."SubscriptionTier" CASCADE;
CREATE TYPE public."SubscriptionTier" AS ENUM (
    'free',        -- Free tier: limited projects, monthly session pool, no translations
    'starter',     -- Starter: $40/month, more projects, session budget, max 2 languages, FunTell branding
    'premium',     -- Premium: $280/month, more projects, larger budget, unlimited languages, white-label
    'enterprise'   -- Enterprise: $1000/month, 100 projects, lowest session rates, white-label, custom domain
);

DROP TYPE IF EXISTS public.subscription_status CASCADE;
CREATE TYPE public.subscription_status AS ENUM (
    'active',
    'canceled',
    'past_due',
    'trialing'
);

DROP TABLE IF EXISTS subscriptions CASCADE;
CREATE TABLE subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE,
    
    -- Subscription status
    tier "SubscriptionTier" NOT NULL DEFAULT 'free',
    status subscription_status NOT NULL DEFAULT 'active',
    
    -- Stripe integration
    stripe_customer_id TEXT,
    stripe_subscription_id TEXT UNIQUE,
    stripe_price_id TEXT,
    
    -- Note: Session-based billing pricing is configured via environment variables
    -- Redis is the source of truth for budget tracking (key: budget:user:${userId}:month:${month})
    -- All numerical values (monthly budget, session costs, limits) come from backend .env
    
    -- Billing cycle
    current_period_start TIMESTAMPTZ,
    current_period_end TIMESTAMPTZ,
    cancel_at_period_end BOOLEAN DEFAULT false,
    canceled_at TIMESTAMPTZ,
    
    -- Scheduled tier change (for downgrades - keeps current tier privileges until period end)
    -- When cancel_at_period_end=true and scheduled_tier is set, user keeps current tier
    -- privileges until period end, then switches to scheduled_tier
    scheduled_tier "SubscriptionTier" DEFAULT NULL,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_subscriptions_user_id ON subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_tier ON subscriptions(tier);
CREATE INDEX IF NOT EXISTS idx_subscriptions_stripe_customer ON subscriptions(stripe_customer_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_stripe_subscription ON subscriptions(stripe_subscription_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_status ON subscriptions(status);
CREATE INDEX IF NOT EXISTS idx_subscriptions_period_end ON subscriptions(current_period_end);

COMMENT ON TABLE subscriptions IS 'User subscription status and Stripe integration';
COMMENT ON COLUMN subscriptions.tier IS 'free or premium - limits configured via backend environment';

-- =================================================================
-- ACCESS LOG TABLE (for detailed tracking and deduplication)
-- =================================================================
DROP TABLE IF EXISTS card_access_log CASCADE;
CREATE TABLE card_access_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    card_id UUID NOT NULL REFERENCES cards(id) ON DELETE CASCADE,
    visitor_hash TEXT NOT NULL,  -- Hash of IP + User-Agent / session ID for deduplication
    accessed_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Billing info
    credit_charged BOOLEAN DEFAULT FALSE,
    card_owner_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    subscription_tier TEXT, -- 'free', 'starter', or 'premium' at time of access
    
    -- Session-based billing info
    session_id TEXT, -- Visitor session ID for deduplication
    session_cost_usd DECIMAL(10, 4) DEFAULT 0, -- Actual cost charged for this session
    is_ai_enabled BOOLEAN DEFAULT FALSE, -- Whether the card had AI enabled at access time
    
    -- Access tracking
    is_owner_access BOOLEAN DEFAULT FALSE, -- True if card owner accessed their own card
    was_overage BOOLEAN DEFAULT FALSE      -- True if this access was beyond monthly limit
);

CREATE INDEX IF NOT EXISTS idx_access_log_card_id ON card_access_log(card_id);
CREATE INDEX IF NOT EXISTS idx_access_log_accessed_at ON card_access_log(accessed_at);
CREATE INDEX IF NOT EXISTS idx_access_log_visitor ON card_access_log(card_id, visitor_hash);
CREATE INDEX IF NOT EXISTS idx_access_log_owner ON card_access_log(card_owner_id);
CREATE INDEX IF NOT EXISTS idx_access_log_dedup ON card_access_log(card_id, visitor_hash, accessed_at);
CREATE INDEX IF NOT EXISTS idx_access_log_session ON card_access_log(session_id);

COMMENT ON TABLE card_access_log IS 'Detailed log of all card accesses for analytics and billing';
COMMENT ON COLUMN card_access_log.visitor_hash IS 'Hash of visitor fingerprint for deduplication';
COMMENT ON COLUMN card_access_log.session_id IS 'Visitor session ID for deduplication';
COMMENT ON COLUMN card_access_log.session_cost_usd IS 'Actual USD cost charged for this session';
COMMENT ON COLUMN card_access_log.was_overage IS 'True if access exceeded monthly limit and used credits';