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
        'PAYMENT_PENDING',
        'PROCESSING',
        'SHIPPED',
        'COMPLETED',
        'CANCELLED'
    );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Function for updating timestamps
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop tables if they exist
DROP TABLE IF EXISTS print_requests CASCADE;
DROP TABLE IF EXISTS issue_cards CASCADE;
DROP TABLE IF EXISTS card_batches CASCADE;
DROP TABLE IF EXISTS content_items CASCADE;
DROP TABLE IF EXISTS cards CASCADE;

-- Cards table
CREATE TABLE cards (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL, -- REFERENCES auth.users(id) if you have auth schema users table
    name TEXT NOT NULL,
    description TEXT DEFAULT '' NOT NULL,
    content_render_mode "ContentRenderMode" DEFAULT 'SINGLE_SERIES_MULTI_ITEMS',
    qr_code_position "QRCodePosition" DEFAULT 'BR',
    image_urls TEXT[],
    published BOOLEAN DEFAULT false,
    conversation_ai_enabled BOOLEAN DEFAULT false,
    ai_prompt TEXT DEFAULT '' NOT NULL,
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
    image_urls TEXT[],
    conversation_ai_enabled BOOLEAN DEFAULT false,
    ai_prompt TEXT DEFAULT '' NOT NULL,
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
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT unique_batch_name_per_card UNIQUE (card_id, batch_name),
    CONSTRAINT unique_batch_number_per_card UNIQUE (card_id, batch_number)
);

CREATE INDEX IF NOT EXISTS idx_card_batches_card_id ON card_batches(card_id);
CREATE INDEX IF NOT EXISTS idx_card_batches_created_by ON card_batches(created_by);
CREATE INDEX IF NOT EXISTS idx_card_batches_batch_number ON card_batches(card_id, batch_number);
CREATE INDEX IF NOT EXISTS idx_card_batches_is_disabled ON card_batches(is_disabled);

-- Issued cards table
CREATE TABLE issue_cards (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    card_id UUID NOT NULL REFERENCES cards(id) ON DELETE CASCADE,
    batch_id UUID NOT NULL REFERENCES card_batches(id) ON DELETE CASCADE,
    activation_code TEXT UNIQUE DEFAULT encode(gen_random_bytes(16), 'hex'),
    active BOOLEAN DEFAULT false,
    issue_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    active_at TIMESTAMP WITH TIME ZONE,
    activated_by UUID, -- REFERENCES auth.users(id)
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_issue_cards_card_id ON issue_cards(card_id);
CREATE INDEX IF NOT EXISTS idx_issue_cards_batch_id ON issue_cards(batch_id);
CREATE INDEX IF NOT EXISTS idx_issue_cards_activation_code ON issue_cards(activation_code);
CREATE INDEX IF NOT EXISTS idx_issue_cards_active ON issue_cards(active);

-- Print requests table
CREATE TABLE print_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    batch_id UUID NOT NULL REFERENCES card_batches(id) ON DELETE CASCADE,
    user_id UUID NOT NULL, -- REFERENCES auth.users(id)
    status "PrintRequestStatus" DEFAULT 'SUBMITTED' NOT NULL,
    shipping_address TEXT,
    admin_notes TEXT,
    payment_details TEXT,
    requested_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT unique_active_print_request_per_batch UNIQUE (batch_id, status) 
);

CREATE INDEX IF NOT EXISTS idx_print_requests_batch_id ON print_requests(batch_id);
CREATE INDEX IF NOT EXISTS idx_print_requests_user_id ON print_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_print_requests_status ON print_requests(status);

-- Create triggers for updating the updated_at timestamp
DROP TRIGGER IF EXISTS update_cards_updated_at ON cards;
CREATE TRIGGER update_cards_updated_at
    BEFORE UPDATE ON cards
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();

DROP TRIGGER IF EXISTS update_content_items_updated_at ON content_items;
CREATE TRIGGER update_content_items_updated_at
    BEFORE UPDATE ON content_items
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();

DROP TRIGGER IF EXISTS update_card_batches_updated_at ON card_batches;
CREATE TRIGGER update_card_batches_updated_at
    BEFORE UPDATE ON card_batches
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();

DROP TRIGGER IF EXISTS update_issue_cards_updated_at ON issue_cards;
CREATE TRIGGER update_issue_cards_updated_at
    BEFORE UPDATE ON issue_cards
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();

DROP TRIGGER IF EXISTS update_print_requests_updated_at ON print_requests;
CREATE TRIGGER update_print_requests_updated_at
    BEFORE UPDATE ON print_requests
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();