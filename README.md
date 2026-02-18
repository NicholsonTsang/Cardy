# FunTell - AI-Powered Content Experience Platform

[![Vue.js](https://img.shields.io/badge/Vue.js-3-4FC08D.svg)](https://vuejs.org/)
[![TypeScript](https://img.shields.io/badge/TypeScript-blue.svg)](https://www.typescriptlang.org/)
[![Supabase](https://img.shields.io/badge/Supabase-3ECF8E.svg)](https://supabase.io/)
[![Express.js](https://img.shields.io/badge/Express.js-4.x-000000.svg)](https://expressjs.com/)

FunTell is an **AI-powered content experience platform** that turns any information into structured, multilingual content with AI conversational assistants. Creators build interactive content experiences distributed via links, QR codes, or embeds. Visitors access content for free with optional AI-powered voice conversations -- no app required.

## Three-Tier Ecosystem

1. **Creators** (B2B) -- Businesses, educators, and organizations building interactive content experiences
2. **Administrators** -- Platform operators managing users and templates
3. **Visitors** (B2C) -- Anyone accessing content via links, QR codes, or embeds

## Architecture

| Layer | Technology | Purpose |
|-------|------------|---------|
| **Frontend** | Vue 3, TypeScript, PrimeVue 4, Tailwind CSS | Creator dashboard, mobile client |
| **Backend** | Express.js, TypeScript | API, payments, AI features, translations |
| **Database** | Supabase PostgreSQL | Data storage via stored procedures only |
| **Cache** | Upstash Redis | Session tracking, rate limiting, content caching |
| **AI** | OpenAI (Realtime Voice, TTS), Google Gemini (Chat, Translations) | AI assistants |
| **Payments** | Stripe | Subscriptions, credits, voice credit purchases |

## Key Features

- **Dual AI Assistants** -- Project-level and item-level AI with text chat, voice recording, and real-time WebRTC voice
- **Voice Credits** -- Per-call credits (35 for $5) with 180s hard time limit for real-time voice conversations
- **Auto Translation** -- One-click translation to 10 languages via Google Gemini
- **Multi-QR Codes** -- Multiple QR codes per project with independent settings and tracking
- **Session-Based Billing** -- Pay-per-session with Redis-first budget management and auto top-up
- **Template Library** -- 20+ pre-built templates organized by venue type
- **Import/Export** -- ZIP-based project archive with full content and translations

## Subscription Tiers

| Tier | Price | Projects | Sessions | Translations | Branding |
|------|-------|----------|----------|--------------|----------|
| **Free** | $0 | 3 | 50/month | None | Powered by FunTell |
| **Starter** | $40/mo | 5 | $40 budget (~800-1,600) | Max 2 languages | Powered by FunTell |
| **Premium** | $280/mo | 35 | $280 budget (~7,000-14,000) | Unlimited | White label |
| **Enterprise** | $1,000/mo | 100 | $1,000 budget (~50,000-100,000) | Unlimited | White label |

**Session costs:** AI-enabled $0.05/$0.04/$0.02 (Starter/Premium/Enterprise), Non-AI $0.025/$0.02/$0.01. Auto top-up: $5 credit batch when budget runs out.

## Content Modes

| Mode | Best For |
|------|----------|
| **Single** | Articles, announcements |
| **List** | Menus, directories, resources |
| **Grid** | Galleries, product catalogs |
| **Cards** | Featured items, news |

All modes support optional **content grouping** (expanded or collapsed categories).

## Project Structure

```
src/                              # Vue.js frontend
  components/                     # Reusable components
  composables/                    # Vue composables
  views/                          # Page components
  stores/                         # Pinia stores
  services/mobileApi.ts           # Mobile client API service
  router/index.ts                 # Vue Router (/:lang prefix)
  router/languageRouting.ts       # Language detection and URL helpers
  layouts/                        # AppLayout, Dashboard
  lib/supabase.ts                 # Supabase client
  utils/                          # Utilities (markdownRenderer, projectArchive, stripeCheckout, etc.)
  i18n/locales/                   # 10 language files

backend-server/                   # Express.js backend
  src/routes/                     # API routes (ai, mobile, payment, subscription, translation, webhook)
  src/services/                   # Business logic (gemini-client, usage-tracker)
  src/config/                     # Config (redis, stripe, subscription, supabase)

sql/                              # Database
  schema.sql                      # Tables, enums, indexes
  all_stored_procedures.sql       # GENERATED -- do not edit directly
  p0_stored_procedures.sql        # Priority-0 procedures for initial deploy
  triggers.sql                    # Database triggers
  policy.sql                      # RLS policies
  storage_policies.sql            # Storage bucket policies
  storeproc/
    client-side/                  # Frontend-accessible procedures
    server-side/                  # Backend-only procedures (service role)

content_templates/                # Sample content templates by venue type
scripts/                          # Deployment and build scripts
```

## Quick Start

### Prerequisites

| Service | Purpose | Setup |
|---------|---------|-------|
| **Node.js** | Runtime (>=18.0.0) | [nodejs.org](https://nodejs.org) |
| **Supabase** | Database, auth, storage | [supabase.com](https://supabase.com) |
| **Upstash Redis** | Session tracking, caching | [console.upstash.com](https://console.upstash.com) |
| **Stripe** | Payments, subscriptions | [stripe.com](https://stripe.com) |
| **OpenAI** | Realtime voice, TTS, AI settings | [platform.openai.com](https://platform.openai.com) |
| **Google Cloud** | Gemini API (chat, translations) | Service account with Gemini access |

### Setup

```bash
# Install dependencies
npm install
cd backend-server && npm install && cd ..

# Configure environment
cp .env.example .env
cp backend-server/.env.example backend-server/.env
# Edit both .env files with your credentials

# Apply database schema (in Supabase SQL Editor)
# 1. sql/schema.sql
# 2. sql/triggers.sql
# 3. sql/policy.sql
# 4. sql/storage_policies.sql
# 5. sql/all_stored_procedures.sql (or sql/p0_stored_procedures.sql for minimal setup)
```

### Development

```bash
# Start backend (port 8080)
cd backend-server && npm run dev

# Start frontend (port 5173) -- in a separate terminal
npm run dev
```

### Build

```bash
# Frontend production build
npm run build

# Backend build
cd backend-server && npm run build
```

## Environment Variables

### Frontend (`.env`)

| Variable | Purpose |
|----------|---------|
| `VITE_BACKEND_URL` | Backend API URL (default: `http://localhost:8080`) |
| `VITE_SUPABASE_URL` | Supabase project URL |
| `VITE_SUPABASE_ANON_KEY` | Supabase anonymous key |
| `VITE_SUPABASE_USER_FILES_BUCKET` | Storage bucket name |
| `VITE_STRIPE_PUBLISHABLE_KEY` | Stripe public key |
| `VITE_APP_URL` | Production URL for SEO/sharing |
| `VITE_*_PROJECT_LIMIT`, `VITE_*_MONTHLY_*` | Subscription tier display values |
| `VITE_VOICE_CREDIT_*` | Voice credit display config |
| `VITE_REALTIME_VAD_*` | Voice activity detection tuning |
| `VITE_CONTENT_PAGE_SIZE`, `VITE_LARGE_CARD_THRESHOLD` | Content pagination |

See `.env.example` for the complete list with defaults.

### Backend (`backend-server/.env`)

| Variable | Purpose |
|----------|---------|
| `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY` | Supabase admin access |
| `OPENAI_API_KEY` | OpenAI for voice, TTS, AI settings |
| `GOOGLE_APPLICATION_CREDENTIALS` | Service account JSON for Gemini |
| `STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET` | Stripe server-side |
| `STRIPE_STARTER_PRICE_ID`, `STRIPE_PREMIUM_PRICE_ID`, `STRIPE_ENTERPRISE_PRICE_ID` | Stripe subscription price IDs |
| `UPSTASH_REDIS_REST_URL`, `UPSTASH_REDIS_REST_TOKEN` | Redis connection |
| `ALLOWED_ORIGINS` | CORS config (`*` for dev, specific origins for prod) |
| `FREE_TIER_*`, `STARTER_*`, `PREMIUM_*`, `ENTERPRISE_*` | Subscription pricing config |
| `VOICE_CREDIT_*` | Voice credit pricing |
| `GEMINI_CHAT_MODEL`, `GEMINI_TRANSLATION_MODEL` | AI model selection |
| `OPENAI_REALTIME_MODEL`, `OPENAI_TTS_MODEL` | OpenAI model selection |

See `backend-server/.env.example` for the complete list with defaults. Also see `backend-server/ENVIRONMENT_VARIABLES.md` for detailed documentation.

## Authentication

- **Email and Password** with email verification
- **Google OAuth** (configure in Supabase Dashboard)
- Roles: `cardIssuer` (default for creators), `admin`
- Role stored in `app_metadata.role` or `user_metadata.role`

## URL Routing

All routes use language prefix: `/:lang/...`

| Pattern | Purpose | Languages |
|---------|---------|-----------|
| `/:lang` | Landing page | 10 languages |
| `/:lang/cms/...` | Dashboard (auth required) | en, zh-Hant |
| `/:lang/c/:issue_card_id` | Public card access (visitor) | 10 languages |
| `/:lang/preview/:card_id` | Preview mode (auth required) | 10 languages |
| `/:lang/login`, `/signup`, `/reset-password` | Auth pages | 10 languages |
| `/:lang/docs` | Documentation | 10 languages |

**Dashboard routes:**
- `/:lang/cms/projects` -- Project list
- `/:lang/cms/credits` -- Credit management
- `/:lang/cms/subscription` -- Subscription management
- `/:lang/cms/admin` -- Admin dashboard
- `/:lang/cms/admin/users` -- User management
- `/:lang/cms/admin/templates` -- Template management
- `/:lang/cms/admin/user-projects` -- User project inspection
- `/:lang/cms/admin/history` -- Operations history
- `/:lang/cms/admin/credits` -- Admin credit management

## Deployment

- **Backend**: Google Cloud Run via `./scripts/deploy-cloud-run.sh`
- **Frontend**: Static hosting (Vercel, Netlify, Firebase) -- `npm run build`

## Database

All database access goes through stored procedures. No direct table queries.

**Updating stored procedures:**
1. Edit files in `sql/storeproc/client-side/` or `sql/storeproc/server-side/`
2. Run `./scripts/combine-storeproc.sh` to regenerate the combined file
3. Deploy via Supabase Dashboard SQL Editor

**Server-side procedures** must include `REVOKE ALL ... FROM PUBLIC, authenticated, anon;` and are only accessible by the backend using the `service_role` key.

## Security

- All database access via stored procedures -- no direct table access
- HTML sanitization via `renderMarkdown()` in `src/utils/markdownRenderer.ts`
- Never commit `.env` files
- Admin role check: `authStore.getUserRole() === 'admin'`
- Redis-first usage tracking with database audit trail

## Documentation

| Document | Description |
|----------|-------------|
| **[CLAUDE.md](CLAUDE.md)** | AI assistant guidance and coding standards |
| **[docs/developer/](docs/developer/)** | Architecture, frontend, backend, database, API, billing, AI integration |
| **[docs/functional/](docs/functional/)** | Creator guides: getting started, project management, features, billing |
| **[backend-server/ENVIRONMENT_VARIABLES.md](backend-server/ENVIRONMENT_VARIABLES.md)** | Backend environment configuration |
| **[content_templates/](content_templates/)** | Sample content templates by venue type |
