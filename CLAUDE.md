# CLAUDE.md

This file provides guidance for AI assistants working on this repository. For detailed documentation, refer to **[README.md](README.md)**.

## Project Overview

ExperienceQR is an **AI-powered digital experience platform** that transforms venues (museums, restaurants, events, etc.) into interactive guides via QR codes. Visitors scan QR codes for free digital content and AI-powered voice conversations.

**Three-Tier Ecosystem:**
1. **Creators** (B2B) - Venues creating interactive digital projects
2. **Administrators** - Platform operators
3. **Visitors** (B2C) - Anyone scanning QR codes

## Core Architecture

| Layer | Technology | Purpose |
|-------|------------|---------|
| **Frontend** | Vue 3, TypeScript, PrimeVue, Tailwind CSS | Creator dashboard, mobile client |
| **Backend** | Express.js, TypeScript | API, payments, AI features, translations |
| **Database** | Supabase PostgreSQL | Data storage via stored procedures only |
| **Cache** | Upstash Redis | Session tracking, rate limiting, content caching |
| **Services** | Stripe, OpenAI, Google Gemini | Payments, AI voice, translations |

## Key Files & Directories

```
├── src/                          # Vue.js frontend
│   ├── components/               # Reusable components
│   ├── views/                    # Page components
│   ├── stores/                   # Pinia stores
│   ├── services/mobileApi.ts     # Mobile client API service
│   └── i18n/locales/             # Translation files (en, zh-Hant, zh-Hans, etc.)
├── backend-server/               # Express.js backend
│   ├── src/routes/               # API routes
│   ├── src/services/             # Business logic
│   └── src/config/redis.ts       # Redis configuration
├── sql/                          # Database
│   ├── schema.sql                # Tables, enums, indexes
│   ├── all_stored_procedures.sql # GENERATED - don't edit directly
│   └── storeproc/
│       ├── client-side/          # Frontend-accessible procedures
│       └── server-side/          # Backend-only procedures (service role)
└── scripts/                      # Deployment scripts
```

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

1. **Schema changes** → `sql/schema.sql`
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

**Session Costs:**
- AI-enabled: $0.05 (Starter), $0.04 (Premium)
- Non-AI: $0.025 (Starter), $0.02 (Premium)

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

## Environment Variables

**Backend (`backend-server/.env`):**
- `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`
- `OPENAI_API_KEY`, `STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET`
- `UPSTASH_REDIS_REST_URL`, `UPSTASH_REDIS_REST_TOKEN`
- Pricing config: `STARTER_*`, `PREMIUM_*`, `FREE_TIER_*`

**Frontend (`.env`):**
- `VITE_BACKEND_URL`, `VITE_SUPABASE_URL`, `VITE_SUPABASE_ANON_KEY`
- `VITE_STRIPE_PUBLISHABLE_KEY`
- Display pricing: `VITE_*` versions of pricing config

## Common Tasks

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
