# Database Guide

This guide covers the PostgreSQL database schema, stored procedures, and security model.

## Overview

The database is hosted on Supabase PostgreSQL. All application data access uses stored procedures (RPC calls), never direct table queries.

## Schema Location

```
sql/
├── schema.sql                    # Tables, enums, indexes
├── all_stored_procedures.sql     # GENERATED - combined procedures
└── storeproc/
    ├── client-side/              # Frontend-accessible
    │   ├── 00_logging.sql
    │   ├── 01_auth_functions.sql
    │   ├── 02_card_management.sql
    │   ├── 03_content_management.sql
    │   ├── 03b_content_migration.sql
    │   ├── 03c_content_pagination.sql
    │   ├── 07_public_access.sql
    │   ├── 10_template_library.sql
    │   ├── 11_admin_functions.sql
    │   ├── 12_subscription.sql
    │   ├── 12_translation_management.sql
    │   ├── 13_access_tokens.sql
    │   ├── admin_credit_management.sql
    │   └── credit_management.sql
    └── server-side/              # Backend-only
        ├── access_logging.sql
        ├── access_token_operations.sql
        ├── card_content.sql
        ├── card_session.sql
        ├── credit_operations.sql
        ├── credit_purchase_completion.sql
        ├── mobile_access.sql
        ├── subscription_management.sql
        ├── translation_credit_consumption.sql
        ├── translation_operations.sql
        └── voice_credit_operations.sql
```

## Core Tables

### `cards`

Main project/card table:

| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Primary key |
| `user_id` | UUID | Owner (references auth.users) |
| `name` | TEXT | Project name |
| `description` | TEXT | Project description |
| `image_url` | TEXT | Processed display image |
| `original_image_url` | TEXT | Original uploaded image |
| `content_mode` | TEXT | Rendering mode (single/grid/list/cards) |
| `is_grouped` | BOOLEAN | Enable category grouping |
| `conversation_ai_enabled` | BOOLEAN | Enable AI assistant |
| `realtime_voice_enabled` | BOOLEAN | Enable real-time voice conversations |
| `ai_instruction` | TEXT | AI role/personality (max 100 words) |
| `ai_knowledge_base` | TEXT | AI context (max 2000 words) |
| `translations` | JSONB | Translated content by language |
| `billing_type` | TEXT | Billing type (digital) |
| `metadata` | JSONB | Extensible metadata for future features (default `{}`) |

### `content_items`

Content within cards:

| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Primary key |
| `card_id` | UUID | Parent card |
| `parent_id` | UUID | Parent item (for hierarchy) |
| `name` | TEXT | Item title |
| `content` | TEXT | Markdown content |
| `media_url` | TEXT | Image/media URL |
| `link_url` | TEXT | External link |
| `position` | INTEGER | Sort order |
| `translations` | JSONB | Translated content |

### `card_access_tokens`

QR codes for digital access:

| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Primary key |
| `card_id` | UUID | Parent card |
| `name` | TEXT | QR code name |
| `access_token` | TEXT | 12-char URL token |
| `is_enabled` | BOOLEAN | Active status |
| `daily_session_limit` | INTEGER | Daily limit (NULL = unlimited) |
| `total_sessions` | INTEGER | All-time count |
| `daily_sessions` | INTEGER | Today's count |

### `voice_credits`

Voice credit balance per user:

| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Primary key |
| `user_id` | UUID | Owner (references auth.users) |
| `balance` | INTEGER | Current credit balance |
| `updated_at` | TIMESTAMPTZ | Last balance update |

### `voice_credit_transactions`

Voice credit purchase and consumption history:

| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Primary key |
| `user_id` | UUID | Owner |
| `amount` | INTEGER | Credits added or consumed |
| `type` | TEXT | Transaction type (purchase, consumption) |
| `stripe_session_id` | TEXT | Stripe checkout session (for purchases) |
| `created_at` | TIMESTAMPTZ | Transaction timestamp |

### `voice_call_log`

Individual voice call records:

| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Primary key |
| `user_id` | UUID | Card owner |
| `card_id` | UUID | Card used for the call |
| `session_id` | TEXT | Unique session identifier |
| `duration_seconds` | INTEGER | Call duration |
| `created_at` | TIMESTAMPTZ | Call timestamp |

## Enums

```sql
-- QR code position on image
CREATE TYPE "QRCodePosition" AS ENUM ('TL', 'TR', 'BL', 'BR');

-- User roles
CREATE TYPE "UserRole" AS ENUM ('user', 'cardIssuer', 'admin');
```

## Stored Procedure Pattern

### Client-Side Procedure

Accessible from frontend with user authentication:

```sql
CREATE OR REPLACE FUNCTION get_user_cards()
RETURNS TABLE (
    id UUID,
    name TEXT,
    description TEXT,
    created_at TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT c.id, c.name, c.description, c.created_at
    FROM cards c
    WHERE c.user_id = auth.uid()
    ORDER BY c.created_at DESC;
END;
$$;
```

### Server-Side Procedure

Backend-only with permission revocation:

```sql
CREATE OR REPLACE FUNCTION get_card_by_access_token_server(
    p_access_token TEXT
)
RETURNS TABLE (
    card_id UUID,
    card_name TEXT,
    -- ... other columns
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT c.id, c.name, ...
    FROM cards c
    JOIN card_access_tokens cat ON cat.card_id = c.id
    WHERE cat.access_token = p_access_token
      AND cat.is_enabled = true;
END;
$$;

-- CRITICAL: Revoke public access
REVOKE ALL ON FUNCTION get_card_by_access_token_server FROM PUBLIC, authenticated, anon;
```

## Security Model

### Row-Level Security (RLS)

Tables use RLS policies, but primary access control is via stored procedures:

1. **Client procedures** use `auth.uid()` to enforce user ownership
2. **Server procedures** revoke public access entirely
3. **Admin procedures** verify role before operations

### Access Patterns

| Caller | Access Method | Auth |
|--------|---------------|------|
| Frontend (user) | Client-side procedures | JWT via Supabase |
| Frontend (public) | Public access procedures | None (limited data) |
| Backend | Server-side procedures | Service role key |
| Admin | Admin procedures | JWT + role check |

## Updating Procedures

### 1. Edit the Source File

Client-side: `sql/storeproc/client-side/*.sql`
Server-side: `sql/storeproc/server-side/*.sql`

### 2. Regenerate Combined File

```bash
./scripts/combine-stored-procedures.sh
```

### 3. Deploy to Supabase

1. Open Supabase Dashboard → SQL Editor
2. Paste the procedure SQL
3. Execute
4. Verify in Table Editor or via test query

## JSONB Translations Structure

Cards and content items store translations in JSONB:

```jsonb
{
  "zh-Hans": {
    "name": "项目名称",
    "description": "项目描述",
    "content_hash": "abc123",
    "translated_at": "2024-01-15T10:30:00Z"
  },
  "ja": {
    "name": "プロジェクト名",
    "description": "プロジェクトの説明",
    "content_hash": "abc123",
    "translated_at": "2024-01-15T10:35:00Z"
  }
}
```

`content_hash` tracks source content version for invalidation.

## Indexes

Key indexes for performance:

```sql
-- User lookups
CREATE INDEX idx_cards_user_id ON cards(user_id);

-- Access token lookups
CREATE INDEX idx_card_access_tokens_access_token
    ON card_access_tokens(access_token);

-- Content ordering
CREATE INDEX idx_content_items_position
    ON content_items(card_id, position);

-- JSONB searches
CREATE INDEX idx_cards_translations ON cards USING GIN (translations);
```

## Common Queries via Procedures

### Get User's Cards

```typescript
const { data } = await supabase.rpc('get_user_cards')
```

### Get Card with Content

```typescript
const { data } = await supabase.rpc('get_card_with_content', {
  p_card_id: cardId
})
```

### Update Content Item

```typescript
const { data } = await supabase.rpc('update_content_item', {
  p_item_id: itemId,
  p_name: name,
  p_content: content
})
```

### Server: Record Session

```typescript
// Backend only
const { data } = await supabaseAdmin.rpc('record_session_server', {
  p_card_id: cardId,
  p_access_token_id: tokenId,
  p_session_type: 'ai'
})
```

## Migration Approach

This project uses direct SQL file editing rather than migration scripts:

1. Edit `schema.sql` for table changes
2. Edit stored procedure files for function changes
3. Deploy manually via Supabase SQL Editor

For history, check git commits on SQL files.
