# CLAUDE.md

This file provides guidance for AI assistants working on this repository. For detailed documentation, refer to **[README.md](README.md)**.

## Project Overview

FunTell is a **digital-only, AI-powered content experience platform** that turns any information into structured, multilingual content with AI conversational assistants. Creators build interactive content experiences for products, venues, education, storytelling, knowledge bases, and more. Content is distributed via links, QR codes, or embeds, and visitors access it for free with optional AI-powered voice conversations.

**Three-Tier Ecosystem:**
1. **Creators** (B2B) - Businesses, educators, and organizations creating interactive content experiences
2. **Administrators** - Platform operators
3. **Visitors** (B2C) - Anyone accessing content via links, QR codes, or embeds

## Core Architecture

| Layer | Technology | Purpose |
|-------|------------|---------|
| **Frontend** | Vue 3, TypeScript, PrimeVue, Tailwind CSS | Creator dashboard, mobile client |
| **Backend** | Express.js, TypeScript | API, payments, AI features, translations |
| **Database** | Supabase PostgreSQL | Data storage via stored procedures only |
| **Cache** | Upstash Redis | Session tracking, rate limiting, content caching |
| **AI** | OpenAI (Realtime Voice, TTS), Google Gemini (Chat, Translations) | AI assistants |
| **Payments** | Stripe | Subscriptions, credits, voice credit purchases |

## Key Files & Directories

```
├── src/                          # Vue.js frontend
│   ├── components/               # Reusable components
│   ├── views/                    # Page components
│   ├── stores/                   # Pinia stores
│   ├── services/mobileApi.ts     # Mobile client API service
│   ├── router/index.ts           # Vue Router (lang-prefixed routes, /:lang/c/:issue_card_id public access)
│   ├── utils/projectArchive.ts   # ZIP-based project import/export
│   └── i18n/locales/             # Translation files (en, zh-Hant, zh-Hans, etc.)
├── backend-server/               # Express.js backend
│   ├── src/routes/               # API routes
│   ├── src/services/             # Business logic (gemini-client, usage-tracker)
│   └── src/config/               # Redis, Stripe, subscription config
├── sql/                          # Database
│   ├── schema.sql                # Tables, enums, indexes (cards table includes metadata JSONB)
│   ├── all_stored_procedures.sql # GENERATED - don't edit directly
│   └── storeproc/
│       ├── client-side/          # Frontend-accessible procedures
│       └── server-side/          # Backend-only procedures (service role)
└── scripts/                      # Deployment scripts
```

**Removed files (physical card feature deleted -- platform is digital-only):**
- `sql/storeproc/client-side/04_batch_management.sql`, `06_print_requests.sql`
- `src/composables/usePhysicalCards.ts`
- `src/stores/admin/batches.ts`, `src/stores/admin/printRequests.ts`

## Coding Standards

### Styling Guidelines

1. **Use Tailwind CSS** - Prefer utility classes over custom CSS
2. **Do NOT override PrimeVue styles** - Use built-in props, presets, and theming
3. **Use PrimeVue component props** - `severity`, `outlined`, `size`, etc.
4. **Minimal scoped CSS** - Only for styles that can't be achieved with Tailwind/PrimeVue

### Backend Database Access (CRITICAL)

**All backend database operations MUST use stored procedures (`.rpc()`).**

```typescript
// ❌ BAD - Direct query
const { data } = await supabaseAdmin.from('subscriptions').select('*').eq('user_id', userId);

// ✅ GOOD - Stored procedure
const { data } = await supabaseAdmin.rpc('get_subscription_by_user_server', { p_user_id: userId });
```

**Server-side stored procedures:** `sql/storeproc/server-side/`
- Must include `REVOKE ALL ... FROM PUBLIC, authenticated, anon;`
- Only accessible by backend with `service_role`

### Database Schema Changes

**Always update raw SQL files, NOT migration scripts:**

1. **Schema changes** → `sql/schema.sql` (note: `cards` table has `metadata JSONB DEFAULT '{}'::JSONB`)
2. **Client-side procedures** → `sql/storeproc/client-side/`
3. **Server-side procedures** → `sql/storeproc/server-side/`
4. Run `scripts/combine-stored-procedures.sh` to regenerate combined file
5. **Manual deployment** → Copy SQL to Supabase Dashboard → SQL Editor

## Subscription & Pricing Model

| Tier | Price | Projects | Sessions | Translations |
|------|-------|----------|----------|--------------|
| **Free** | $0 | 3 | 50/month | ❌ |
| **Starter** | $40/mo | 5 | $40 budget | Max 2 languages |
| **Premium** | $280/mo | 35 | $280 budget | Unlimited |
| **Enterprise** | $1,000/mo | 100 | $1,000 budget | Unlimited |

**Session Costs:**
- AI-enabled: $0.05 (Starter), $0.04 (Premium), $0.02 (Enterprise)
- Non-AI: $0.025 (Starter), $0.02 (Premium), $0.01 (Enterprise)

**Voice Credits:** Separate from session billing. 1 credit = 1 voice call with hard time limit (180s). Purchased via Stripe. Tables: `voice_credits`, `voice_credit_transactions`, `voice_call_log`.

**Architecture:** Redis is source of truth for usage tracking. Database stores subscription metadata only.

## Content Modes

| Mode | Description | Best For |
|------|-------------|----------|
| **Single** | 1 content item | Articles, announcements |
| **List** | Vertical list | Link-in-bio, resources |
| **Grid** | 2-column grid | Galleries, products |
| **Cards** | Full-width cards | Featured items, news |

**Grouping:** `is_grouped: true` enables hierarchical categories; `false` shows only leaf items.

## Mobile Client AI Assistants

| Assistant | Purpose | Entry Point |
|-----------|---------|-------------|
| **General** | Experience-level questions | Overview page, floating button |
| **Item** | Specific content item questions | Content detail page |

Both support text chat, voice recording, and real-time WebRTC conversations.

## Translation System

- **Engine:** Google Gemini 2.5 Flash-Lite
- **Languages:** en, zh-Hant, zh-Hans, ja, ko, es, fr, ru, ar, th
- **Access:** Admins always, Premium users, Free users cannot translate
- **Source of truth:** `SUPPORTED_LANGUAGES` in `src/stores/translation.ts`

## URL-Based Language Routing

All routes include language prefix: `/:lang/...`
- Landing & Mobile: 10 languages
- Dashboard: 2 languages (en, zh-Hant)
- Default: `/en` with localStorage preference override
- **Public card access:** `/:lang/c/:issue_card_id` with children `/list` and `/item/:content_item_id`

## Environment Variables

**Backend (`backend-server/.env`):**
- `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`
- `OPENAI_API_KEY`, `STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET`
- `UPSTASH_REDIS_REST_URL`, `UPSTASH_REDIS_REST_TOKEN`
- Pricing config: `STARTER_*`, `PREMIUM_*`, `ENTERPRISE_*`, `FREE_TIER_*`

**Frontend (`.env`):**
- `VITE_BACKEND_URL`, `VITE_SUPABASE_URL`, `VITE_SUPABASE_ANON_KEY`
- `VITE_STRIPE_PUBLISHABLE_KEY`
- Display pricing: `VITE_*` versions of pricing config

## Common Tasks

### Project Import/Export
- Uses ZIP archive format (`src/utils/projectArchive.ts`)
- Multi-project exports produce nested ZIPs (one ZIP per project inside an outer ZIP)
- Import handles both single-project and nested multi-project ZIPs

### Adding i18n Translations
Update files in `src/i18n/locales/`: en.json, zh-Hant.json, zh-Hans.json (minimum)

### Updating Stored Procedures
1. Edit files in `sql/storeproc/`
2. Run `./scripts/combine-stored-procedures.sh`
3. Deploy via Supabase Dashboard SQL Editor

### Deploying Backend
```bash
./scripts/deploy-cloud-run.sh
```

## Redis Key Patterns

| Pattern | Purpose |
|---------|---------|
| `budget:user:{userId}:month:{YYYY-MM}` | Available budget |
| `session:dedup:{sessionId}:{cardId}` | Deduplication (30 min TTL) |
| `access:card:{cardId}:date:{date}:scans` | Daily scan count |
| `card:ai:{cardId}` | AI-enabled status cache |

## Security Notes

- HTML sanitization: Use `renderMarkdown()` from `src/utils/markdownRenderer.ts`
- Never commit `.env` files
- All database access via stored procedures (no direct table access)
- Admin role check: `authStore.getUserRole() === 'admin'`
