# System Architecture

This document describes the high-level architecture of FunTell.

## Overview

FunTell is an AI-powered content experience platform connecting creators (B2B), administrators, and visitors (B2C). Creators turn any information into multilingual, AI-enhanced experiences that audiences access via QR codes, links, or embeds.

```
┌─────────────────────────────────────────────────────────────────┐
│                        Frontend (Vue 3)                         │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐  │
│  │   Dashboard  │  │ Mobile Client│  │    Public Pages      │  │
│  │  (Creators)  │  │  (Visitors)  │  │  (Landing, Docs)     │  │
│  └──────┬───────┘  └──────┬───────┘  └──────────┬───────────┘  │
└─────────┼─────────────────┼─────────────────────┼──────────────┘
          │                 │                     │
          ▼                 ▼                     ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Backend (Express.js)                         │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────────────┐    │
│  │   AI    │  │ Payment │  │ Mobile  │  │  Subscriptions  │    │
│  │ Routes  │  │ Routes  │  │ Routes  │  │     Routes      │    │
│  └────┬────┘  └────┬────┘  └────┬────┘  └────────┬────────┘    │
│       │            │            │                │              │
│       ▼            ▼            ▼                ▼              │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                     Services Layer                       │   │
│  │  (OpenAI, Stripe, Gemini, Supabase, Redis)              │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
          │                 │                     │
          ▼                 ▼                     ▼
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────┐
│    Supabase     │  │  Upstash Redis  │  │  External Services  │
│   PostgreSQL    │  │   (Caching)     │  │ (Stripe, OpenAI)    │
└─────────────────┘  └─────────────────┘  └─────────────────────┘
```

## Technology Stack

| Layer | Technology | Purpose |
|-------|------------|---------|
| Frontend | Vue 3, TypeScript | SPA with creator dashboard, mobile client |
| UI Framework | PrimeVue, Tailwind CSS | Components and styling |
| State | Pinia | Client-side state management |
| Backend | Express.js, TypeScript | API server, business logic |
| Database | Supabase PostgreSQL | Primary data storage |
| Cache | Upstash Redis | Session tracking, rate limiting, content caching |
| Auth | Supabase Auth | Authentication and authorization |
| Payments | Stripe | Subscriptions and credit purchases |
| AI | OpenAI (Realtime Voice, TTS), Google Gemini (Chat, Translations) | Voice conversations, text-to-speech, chat, translations |

## Data Flow Patterns

### Creator Dashboard Flow

1. User authenticates via Supabase Auth
2. Dashboard fetches data via Supabase client (stored procedures)
3. Sensitive operations route through backend API
4. Backend validates auth and calls service-role procedures

### Mobile Client Flow

1. Visitor scans QR code → access token URL
2. Frontend calls backend `/api/mobile/card/:accessToken`
3. Backend validates token, tracks session in Redis
4. Returns card content with proper caching

### AI Conversation Flow

1. User initiates chat or voice in mobile client
2. Frontend calls backend `/api/ai/chat/stream`
3. Backend validates session, checks usage limits
4. Streams response from Google Gemini via SSE

## Key Design Decisions

### Database Access via Stored Procedures Only

All database operations use `.rpc()` stored procedures, not direct table queries:

- **Security**: Row-level security enforced at procedure level
- **Auditability**: Centralized data access logic
- **Performance**: Optimized queries in PostgreSQL
- **Maintainability**: Database logic separate from application

### Redis as Source of Truth for Usage

Real-time usage tracking (sessions, budget) uses Redis:

- **Speed**: Sub-millisecond reads/writes
- **Accuracy**: Atomic operations prevent race conditions
- **Persistence**: Upstash provides durability

Database stores subscription metadata; Redis tracks consumption.

### Dual Language Selector Strategy

Separate language selectors for different contexts:

- **LandingLanguageSelector**: Public pages (10 languages)
- **DashboardLanguageSelector**: Creator dashboard (2 languages)

Prevents unnecessary complexity in translation maintenance.

### Content Mode System

Four rendering modes for different use cases:

| Mode | Layout | Use Case |
|------|--------|----------|
| Single | One item | Articles, announcements |
| List | Vertical | Link-in-bio, resources |
| Grid | 2-column | Galleries, products |
| Cards | Full-width | Featured items, news |

## Security Model

### Authentication Layers

1. **Supabase Auth**: JWT tokens for all authenticated requests
2. **Backend Verification**: Service validates JWTs before sensitive operations
3. **Stored Procedure Security**:
   - Client-side: Uses `auth.uid()` for user context
   - Server-side: Revokes public access, requires service role

### Data Protection

- All user content sanitized via `renderMarkdown()` utility
- Environment variables never committed
- Access tokens use cryptographically secure generation

## Scaling Considerations

### Current Architecture Supports

- Multiple concurrent users via stateless API
- Redis caching reduces database load
- CDN-ready static assets (Vite build)

### Future Scaling Paths

- Horizontal API scaling via Cloud Run
- Read replicas for database (Supabase Pro)
- Edge functions for global latency
