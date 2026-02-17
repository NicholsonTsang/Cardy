# FunTell - AI-Powered Content Experience Platform

[![Vue.js](https://img.shields.io/badge/Vue.js-3-4FC08D.svg)](https://vuejs.org/)
[![TypeScript](https://img.shields.io/badge/TypeScript-blue.svg)](https://www.typescriptlang.org/)
[![Supabase](https://img.shields.io/badge/Supabase-3ECF8E.svg)](https://supabase.io/)
[![Express.js](https://img.shields.io/badge/Express.js-4.x-000000.svg)](https://expressjs.com/)

FunTell is an **AI-powered content experience platform** that turns any information into structured, multilingual content with AI conversational assistants. Creators build interactive content experiences distributed via links, QR codes, or embeds. Visitors access content for free with optional AI-powered voice conversations — no app required.

## Three-Tier Ecosystem

1. **Creators** (B2B) — Businesses, educators, and organizations building interactive content experiences
2. **Administrators** — Platform operators managing users and templates
3. **Visitors** (B2C) — Anyone accessing content via links, QR codes, or embeds

## Core Architecture

| Layer | Technology | Purpose |
|-------|------------|---------|
| **Frontend** | Vue 3, TypeScript, PrimeVue 4, Tailwind CSS | Creator dashboard, mobile client |
| **Backend** | Express.js, TypeScript | API, payments, AI features, translations |
| **Database** | Supabase PostgreSQL | Data storage via stored procedures only |
| **Cache** | Upstash Redis | Session tracking, rate limiting, content caching |
| **AI** | OpenAI (Realtime Voice, TTS), Google Gemini (Chat, Translations) | AI assistants |
| **Payments** | Stripe | Subscriptions, credits, voice credit purchases |

## Key Features

- **Dual AI Assistants** — Project-level and item-level AI with text chat, voice recording, and real-time WebRTC voice
- **Voice Credits** — Per-call credits with hard time limits for real-time voice conversations
- **Auto Translation** — One-click translation to 10 languages via Google Gemini
- **Multi-QR Codes** — Multiple QR codes per project with independent settings and tracking
- **Session-Based Billing** — Pay-per-session with Redis-first budget management
- **Template Library** — 20+ pre-built templates organized by venue type
- **Import/Export** — ZIP-based project archive with full content and translations

## Subscription Tiers

| Tier | Price | Projects | Sessions | Translations | Branding |
|------|-------|----------|----------|--------------|----------|
| **Free** | $0 | 3 | 50/month | None | Powered by FunTell |
| **Starter** | $40/mo | 5 | ~800–1,600 | Max 2 languages | Powered by FunTell |
| **Premium** | $280/mo | 35 | ~7,000–14,000 | Unlimited | White-label |

**Session costs:** AI-enabled $0.05/$0.04 (Starter/Premium), Non-AI $0.025/$0.02. Overage credits available at $5 per top-up.

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
├── src/                          # Vue.js frontend
│   ├── components/               # Reusable components
│   ├── views/                    # Page components
│   ├── stores/                   # Pinia stores
│   ├── services/mobileApi.ts     # Mobile client API service
│   ├── router/index.ts           # Vue Router (/:lang prefix)
│   └── i18n/locales/             # Translation files
├── backend-server/               # Express.js backend
│   ├── src/routes/               # API routes
│   ├── src/services/             # Business logic (gemini-client, usage-tracker)
│   └── src/config/               # Supabase, Redis, Stripe, subscription config
├── sql/                          # Database
│   ├── schema.sql                # Tables, enums, indexes
│   ├── all_stored_procedures.sql # GENERATED - don't edit directly
│   └── storeproc/
│       ├── client-side/          # Frontend-accessible procedures
│       └── server-side/          # Backend-only procedures (service role)
├── content_templates/            # Sample content templates by venue type
├── scripts/                      # Deployment scripts
└── docs/                         # Developer and functional documentation
```

## Quick Start

```bash
# Install dependencies
npm install && cd backend-server && npm install && cd ..

# Configure environment
cp .env.example .env
cp backend-server/.env.example backend-server/.env
# Edit both .env files with your credentials

# Apply database schema (in Supabase SQL Editor)
# 1. sql/schema.sql
# 2. sql/all_stored_procedures.sql

# Start development
cd backend-server && npm run dev  # Backend on port 8080
npm run dev                        # Frontend on port 5173
```

### Required Services

| Service | Purpose | Setup |
|---------|---------|-------|
| **Supabase** | Database, auth, storage | [supabase.com](https://supabase.com) |
| **Upstash Redis** | Session tracking, caching | [console.upstash.com](https://console.upstash.com) |
| **Stripe** | Payments, subscriptions | [stripe.com](https://stripe.com) |
| **OpenAI** | Realtime voice, TTS | [platform.openai.com](https://platform.openai.com) |
| **Google Gemini** | Chat AI, translations | Via backend config |

## Authentication

- **Email & Password** with verification
- **Google OAuth** (configure in Supabase Dashboard)
- Roles: `cardIssuer` (default), `admin`

## Deployment

- **Backend**: Google Cloud Run via `./scripts/deploy-cloud-run.sh`
- **Frontend**: Static hosting (Vercel, Netlify, Firebase) — `npm run build`

## Documentation

| Document | Description |
|----------|-------------|
| **[CLAUDE.md](CLAUDE.md)** | Quick reference for AI assistants and coding standards |
| **[docs/developer/](docs/developer/)** | Architecture, frontend, backend, database, API, billing, AI integration |
| **[docs/functional/](docs/functional/)** | Creator guides: getting started, project management, features, billing |
| **[backend-server/ENVIRONMENT_VARIABLES.md](backend-server/ENVIRONMENT_VARIABLES.md)** | Backend environment configuration |
| **[content_templates/](content_templates/)** | Sample content templates by venue type |

## Security

- All database access via stored procedures — no direct table access
- HTML sanitization via `renderMarkdown()` in `src/utils/markdownRenderer.ts`
- Never commit `.env` files
- Admin role check: `authStore.getUserRole() === 'admin'`
