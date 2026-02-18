# CLAUDE.md

AI assistant guidance for the FunTell codebase. For developer onboarding, see **[README.md](README.md)**.

## Project Overview

FunTell is a **digital-only, AI-powered content experience platform**. Creators build structured, multilingual content experiences with AI conversational assistants. Content is distributed via links, QR codes, or embeds. Visitors access content for free with optional AI-powered voice and text conversations.

**Three-Tier Ecosystem:**
1. **Creators** (B2B) -- Businesses, educators, organizations building interactive content
2. **Administrators** -- Platform operators managing users and templates
3. **Visitors** (B2C) -- Anyone accessing content via links, QR codes, or embeds

## Tech Stack

| Layer | Technology | Purpose |
|-------|------------|---------|
| **Frontend** | Vue 3, TypeScript, PrimeVue 4, Tailwind CSS | Creator dashboard, mobile client |
| **Backend** | Express.js, TypeScript | API, payments, AI features, translations |
| **Database** | Supabase PostgreSQL | Data storage via stored procedures only |
| **Cache** | Upstash Redis | Session tracking, rate limiting, content caching |
| **AI** | OpenAI (Realtime Voice, TTS), Google Gemini (Chat, Translations) | AI assistants |
| **Payments** | Stripe | Subscriptions, credits, voice credit purchases |

## Key Files and Directories

```
src/                              # Vue.js frontend
  components/                     # Reusable components
  composables/                    # Vue composables (useContentSearch, useFavorites, useSEO, useShare)
  views/                          # Page components
    Dashboard/CardIssuer/         # Creator pages (MyCards, CreditManagement, SubscriptionManagement)
    Dashboard/Admin/              # Admin pages (AdminDashboard, UserManagement, TemplateManagement, etc.)
    MobileClient/                 # Public visitor experience (PublicCardView)
    Public/                       # Landing page, documentation
  stores/                         # Pinia stores (card, contentItem, credits, subscription, translation, voiceCredits, etc.)
    admin/                        # Admin stores (auditLog, credits, dashboard, operationsLog, userCards)
  services/mobileApi.ts           # Mobile client API service
  router/index.ts                 # Vue Router (/:lang prefix for all routes)
  router/languageRouting.ts       # Language detection, validation, URL helpers
  layouts/                        # AppLayout.vue, Dashboard.vue
  lib/supabase.ts                 # Supabase client initialization
  utils/                          # Utilities (projectArchive, markdownRenderer, stripeCheckout, etc.)
  i18n/locales/                   # Translation files (en, zh-Hant, zh-Hans, ja, ko, es, fr, ru, ar, th)

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
  migrations/                     # Migration scripts
  storeproc/
    client-side/                  # Frontend-accessible procedures
    server-side/                  # Backend-only procedures (service role)

content_templates/                # Sample content templates by venue type
scripts/                          # Deployment and build scripts
```

## Coding Standards

### Styling

1. **Use Tailwind CSS** -- Prefer utility classes over custom CSS
2. **Do NOT override PrimeVue styles** -- Use built-in props, presets, and theming
3. **Use PrimeVue component props** -- `severity`, `outlined`, `size`, etc.
4. **Minimal scoped CSS** -- Only for styles that cannot be achieved with Tailwind or PrimeVue
5. **Dialog widths** -- Use `{ width: '90vw', maxWidth: 'Xrem' }` pattern for responsive dialogs

### Backend Database Access (CRITICAL)

**All backend database operations MUST use stored procedures (`.rpc()`).**

```typescript
// BAD -- Direct query
const { data } = await supabaseAdmin.from('subscriptions').select('*').eq('user_id', userId);

// GOOD -- Stored procedure
const { data } = await supabaseAdmin.rpc('get_subscription_by_user_server', { p_user_id: userId });
```

**Server-side stored procedures** (`sql/storeproc/server-side/`):
- Must include `REVOKE ALL ... FROM PUBLIC, authenticated, anon;`
- Only accessible by backend with `service_role`

### Database Schema Changes

**Always update raw SQL files, NOT migration scripts:**

1. **Schema changes** -- `sql/schema.sql` (note: `cards` table has `metadata JSONB DEFAULT '{}'::JSONB`)
2. **Client-side procedures** -- `sql/storeproc/client-side/`
3. **Server-side procedures** -- `sql/storeproc/server-side/`
4. Run `scripts/combine-storeproc.sh` to regenerate the combined file
5. **Manual deployment** -- Copy SQL to Supabase Dashboard SQL Editor

### Frontend Patterns

- **WebRTC composable**: `useWebRTCConnection.ts` manages RTCPeerConnection, data channel, audio
- **Cost safeguards**: `useCostSafeguards.ts` handles visibilitychange, beforeunload, blur, onBeforeUnmount
- **Route-level disconnect**: PublicCardView provides `aiDisconnectRegistry` via provide/inject
- **Prompt optimization**: Use ref + watch (not computed) for system instructions to enable OpenAI prompt caching
- **i18n minimum**: Always update en.json, zh-Hant.json, zh-Hans.json (other locales also exist)

### Lessons Learned

- WebRTC `ontrack` can fire multiple times from ICE reconnections -- use generation counter to invalidate stale animation frame loops
- Composable-level visibility listeners conflict with component-level safeguards -- keep one source of truth (useCostSafeguards)
- `cleanup()` must reset ALL state including callbacks and greeting flags, not just connection objects
- Vue reuses PublicCardView on card-to-card navigation (same component), so child components do not unmount -- need provide/inject registry for disconnect
- `e.preventDefault()` / `e.returnValue` in beforeunload is disruptive on mobile -- just run cleanup synchronously
- Cost safeguards must activate during 'connecting' phase too, not just after isConnected becomes true

## Subscription and Pricing Model

| Tier | Price | Projects | Sessions | Translations | Branding |
|------|-------|----------|----------|--------------|----------|
| **Free** | $0 | 3 | 50/month | None | Powered by FunTell |
| **Starter** | $40/mo | 5 | $40 budget | Max 2 languages | Powered by FunTell |
| **Premium** | $280/mo | 35 | $280 budget | Unlimited | White label |
| **Enterprise** | $1,000/mo | 100 | $1,000 budget | Unlimited | White label |

**Session Costs:**
- AI-enabled: $0.05 (Starter), $0.04 (Premium), $0.02 (Enterprise)
- Non-AI: $0.025 (Starter), $0.02 (Premium), $0.01 (Enterprise)

**Voice Credits:** Separate from session billing. 35 credits for $5. Each credit = 1 voice call with 180s hard time limit. Tables: `voice_credits`, `voice_credit_transactions`, `voice_call_log`.

**Architecture:** Redis is source of truth for usage tracking. Database stores subscription metadata only. Auto top-up: $5 credit batch when budget runs out.

## Content Modes

| Mode | Description | Best For |
|------|-------------|----------|
| **Single** | 1 content item | Articles, announcements |
| **List** | Vertical list | Menus, directories, resources |
| **Grid** | 2-column grid | Galleries, product catalogs |
| **Cards** | Full-width cards | Featured items, news |

**Grouping:** `is_grouped: true` enables hierarchical categories (`group_display: 'expanded'` or `'collapsed'`); `false` shows flat item list.

## URL-Based Language Routing

All routes include language prefix: `/:lang/...`
- **10 languages** for landing and mobile: en, zh-Hant, zh-Hans, ja, ko, es, fr, ru, ar, th
- **2 languages** for dashboard: en, zh-Hant
- Default: `/en` with localStorage preference override
- **Public card access:** `/:lang/c/:issue_card_id` with children `/list` and `/item/:content_item_id`
- **Preview mode:** `/:lang/preview/:card_id` (requires auth)
- **Source of truth:** `SUPPORTED_LANGUAGES` in `src/stores/translation.ts`, `DASHBOARD_LANGUAGES` in `src/router/languageRouting.ts`

## AI Models

| Purpose | Model | Config Location |
|---------|-------|-----------------|
| Text Chat | Google Gemini (`gemini-2.5-flash-lite`) | `backend-server/.env` (`GEMINI_CHAT_MODEL`) |
| Translation | Google Gemini (`gemini-2.5-flash-lite`) | `backend-server/.env` (`GEMINI_TRANSLATION_MODEL`) |
| Realtime Voice | OpenAI (`gpt-realtime-mini-2025-12-15`) | `backend-server/.env` (`OPENAI_REALTIME_MODEL`) |
| Text-to-Speech | OpenAI (`tts-1`) | `backend-server/.env` (`OPENAI_TTS_MODEL`) |
| AI Settings Generation | OpenAI (`gpt-4o-mini`) | `backend-server/.env` (`OPENAI_TEXT_MODEL`) |

## Backend API Routes

All mounted under `/api/`:

| Route Group | Mount Point | Key Endpoints |
|-------------|-------------|---------------|
| Subscriptions | `/api/subscriptions` | GET `/`, POST `/create-checkout`, `/cancel`, `/reactivate`, GET `/portal`, `/usage`, POST `/buy-credits` |
| Translations | `/api/translations` | POST `/translate-card` |
| Payments | `/api/payments` | POST `/create-credit-checkout` |
| AI | `/api/ai` | POST `/chat/stream`, `/generate-tts`, `/realtime-token`, `/generate-ai-settings` |
| Webhooks | `/api/webhooks` | POST `/stripe` |
| Mobile | `/api/mobile` | GET `/card/digital/:accessToken`, POST `/card/:cardId/invalidate-cache` |

## Redis Key Patterns

| Pattern | Purpose |
|---------|---------|
| `budget:user:{userId}:month:{YYYY-MM}` | Available budget |
| `session:dedup:{sessionId}:{cardId}` | Deduplication (30 min TTL) |
| `access:card:{cardId}:date:{date}:scans` | Daily scan count |
| `card:ai:{cardId}` | AI-enabled status cache |

## Database Tables

Core tables in `sql/schema.sql`:
- `cards` -- Projects with AI settings, content mode, translations, metadata JSONB
- `content_items` -- Hierarchical content (parent_id for categories, translations JSONB)
- `card_access_tokens` -- Multiple QR codes per project with per-token session limits
- `card_access_log` -- Visitor session tracking for billing and analytics
- `subscriptions` -- User subscription tier, Stripe integration, scheduled downgrades
- `content_templates` -- Template library linked to actual card records
- `operations_log` -- Audit trail for write operations
- `user_credits`, `credit_transactions`, `credit_purchases`, `credit_consumptions` -- Credit system
- `voice_credits`, `voice_credit_transactions`, `voice_call_log` -- Voice credit system
- `translation_history` -- Translation audit trail

## Common Tasks

### Adding i18n Translations
Update files in `src/i18n/locales/`: en.json, zh-Hant.json, zh-Hans.json (minimum). Other locale files: ja, ko, es, fr, ru, ar, th.

### Updating Stored Procedures
1. Edit files in `sql/storeproc/`
2. Run `./scripts/combine-storeproc.sh`
3. Deploy via Supabase Dashboard SQL Editor

### Deploying Backend
```bash
./scripts/deploy-cloud-run.sh
```

## Security Notes

- HTML sanitization: Use `renderMarkdown()` from `src/utils/markdownRenderer.ts`
- Never commit `.env` files
- All database access via stored procedures (no direct table access)
- Admin role check: `authStore.getUserRole() === 'admin'`
- User roles: `cardIssuer` (default for creators), `admin`
