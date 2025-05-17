-- Create enum type for content render modes
create type "ContentRenderMode" as enum (
    'SINGLE_SERIES_MULTI_ITEMS',
    'MULTI_SERIES_NO_ITEMS',
    'MULTI_SERIES_MULTI_ITEMS'
);

-- Create enum type for QR Code Position
create type "QRCodePosition" as enum (
    'TL', -- Top Left
    'TR', -- Top Right
    'BL', -- Bottom Left
    'BR'  -- Bottom Right
);

-- Function for updating timestamps
create or replace function update_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

-- Cards table
create table cards (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null,
    name text not null,
    description text default '' not null,
    content_render_mode "ContentRenderMode" default 'SINGLE_SERIES_MULTI_ITEMS',
    qr_code_position "QRCodePosition" default 'BR',
    image_urls text[],
    published boolean default false,
    conversation_ai_enabled boolean default false,
    created_at timestamp with time zone default now(),
    updated_at timestamp with time zone default now()
);

-- Add index on user_id for faster user-specific queries
create index idx_cards_user_id on cards(user_id);

-- Content items table
create table content_items (
    id uuid primary key default gen_random_uuid(),
    card_id uuid not null references cards(id) on delete cascade,
    parent_id uuid references content_items(id) on delete cascade,
    name text not null,
    content text default '' not null, 
    created_at timestamp with time zone default now(),
    updated_at timestamp with time zone default now(),
    -- Enforce that parent_id can't reference itself
    constraint content_items_parent_not_self check (parent_id != id)
);

-- Add indexes for frequent lookups
create index idx_content_items_card_id on content_items(card_id);
create index idx_content_items_parent_id on content_items(parent_id);

-- Issued cards table
create table issue_cards (
    id uuid primary key default gen_random_uuid(),
    card_id uuid not null references cards(id) on delete cascade,
    active boolean default false,
    issue_at timestamp with time zone default now(),
    active_at timestamp with time zone default now(),
    created_at timestamp with time zone default now(),
    updated_at timestamp with time zone default now()
);

-- Add index for card lookup
create index idx_issue_cards_card_id on issue_cards(card_id);

-- Create triggers for updating the updated_at timestamp
create trigger update_cards_updated_at
before update on cards
for each row
execute function update_updated_at();

create trigger update_content_items_updated_at
before update on content_items
for each row
execute function update_updated_at();

create trigger update_issue_cards_updated_at
before update on issue_cards
for each row
execute function update_updated_at();