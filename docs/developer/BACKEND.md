# Backend Guide

This guide covers the Express.js backend server architecture and patterns.

## Directory Structure

```
backend-server/
├── src/
│   ├── routes/              # API route handlers
│   │   ├── index.ts         # Route registration
│   │   ├── ai.routes.ts     # AI/chat endpoints
│   │   ├── mobile.routes.ts # Mobile client endpoints
│   │   ├── payment.routes.ts# Payment processing
│   │   ├── subscription.routes.ts
│   │   ├── translation.routes.direct.ts
│   │   └── webhook.routes.ts# Stripe webhooks
│   ├── services/            # Business logic
│   ├── config/              # Configuration
│   │   ├── redis.ts         # Redis client setup
│   │   └── stripe.ts        # Stripe client and shared config
│   └── types/               # TypeScript types
└── ENVIRONMENT_VARIABLES.md # Environment documentation
```

## Route Modules

| Module | Path | Purpose |
|--------|------|---------|
| `ai.routes.ts` | `/api/ai/*` | Chat streaming (Gemini), TTS, realtime tokens, voice call end |
| `mobile.routes.ts` | `/api/mobile/*` | Card data for mobile client |
| `payment.routes.ts` | `/api/payments/*` | Session credit and voice credit purchases |
| `subscription.routes.ts` | `/api/subscriptions/*` | Subscription management, voice credit balance |
| `translation.routes.direct.ts` | `/api/translations/*` | Content translation |
| `webhook.routes.ts` | `/api/webhooks/*` | Stripe webhook handling |

## Database Access Pattern

**Critical**: All database operations must use stored procedures via `.rpc()`.

```typescript
// ❌ BAD - Direct query (never do this)
const { data } = await supabaseAdmin
  .from('subscriptions')
  .select('*')
  .eq('user_id', userId)

// ✅ GOOD - Stored procedure
const { data } = await supabaseAdmin.rpc(
  'get_subscription_by_user_server',
  { p_user_id: userId }
)
```

### Client-Side vs Server-Side Procedures

| Type | Location | Access | Use Case |
|------|----------|--------|----------|
| Client-side | `sql/storeproc/client-side/` | `anon`, `authenticated` | Frontend calls |
| Server-side | `sql/storeproc/server-side/` | `service_role` only | Backend operations |

Server-side procedures include permission revocation:

```sql
-- Always at end of server-side procedures
REVOKE ALL ON FUNCTION function_name FROM PUBLIC, authenticated, anon;
```

## Redis Usage

Redis (Upstash) is the source of truth for usage tracking.

### Configuration

```typescript
// src/config/redis.ts
import { Redis } from '@upstash/redis'

export const redis = new Redis({
  url: process.env.UPSTASH_REDIS_REST_URL,
  token: process.env.UPSTASH_REDIS_REST_TOKEN
})
```

### Key Patterns

| Pattern | Purpose | TTL |
|---------|---------|-----|
| `budget:user:{userId}:month:{YYYY-MM}` | Available monthly budget | End of month |
| `session:dedup:{sessionId}:{cardId}` | Session deduplication | 30 minutes |
| `access:card:{cardId}:date:{date}:scans` | Daily scan count | 24 hours |
| `card:ai:{cardId}` | AI-enabled status cache | 1 hour |
| `card:content:{cardId}` | Content cache | 10 minutes |

### Common Operations

```typescript
// Check budget
const budget = await redis.get(`budget:user:${userId}:month:${month}`)

// Atomic decrement
const remaining = await redis.decrby(
  `budget:user:${userId}:month:${month}`,
  sessionCost
)

// Session deduplication
const dedupKey = `session:dedup:${sessionId}:${cardId}`
const isNew = await redis.setnx(dedupKey, '1')
if (isNew) {
  await redis.expire(dedupKey, 1800) // 30 min TTL
}
```

## External Services

### Google Gemini Integration (Chat)

```typescript
// src/services/gemini-client.ts
import { GoogleGenerativeAI } from '@google/generative-ai'

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY)
const model = genAI.getGenerativeModel({ model: 'gemini-2.5-flash-lite' })

// Chat streaming
const stream = await geminiClient.streamChat(messages)
```

### OpenAI Integration (TTS & Realtime Voice)

```typescript
import OpenAI from 'openai'

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY
})

// Text-to-speech
const audioResponse = await openai.audio.speech.create({
  model: 'tts-1',
  voice: 'alloy',
  input: text
})
```

### Stripe Integration

```typescript
import Stripe from 'stripe'

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY)

// Create checkout session
const session = await stripe.checkout.sessions.create({
  mode: 'subscription',
  line_items: [...],
  success_url: `${baseUrl}/success`,
  cancel_url: `${baseUrl}/cancel`
})
```

### Google Gemini (Translations)

Translations also use Gemini (same client as chat):

```typescript
const result = await model.generateContent(translationPrompt)
```

## Authentication

### Verifying User Auth

```typescript
import { createClient } from '@supabase/supabase-js'

const supabaseAdmin = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
)

// Verify JWT from Authorization header
const authHeader = req.headers.authorization
const token = authHeader?.replace('Bearer ', '')

const { data: { user }, error } = await supabaseAdmin.auth.getUser(token)
if (error || !user) {
  return res.status(401).json({ error: 'Unauthorized' })
}
```

### Admin Verification

```typescript
// Check admin role via stored procedure
const { data: profile } = await supabaseAdmin.rpc(
  'get_user_profile_server',
  { p_user_id: user.id }
)

if (profile?.role !== 'admin') {
  return res.status(403).json({ error: 'Admin access required' })
}
```

## Streaming Responses (SSE)

For AI chat streaming:

```typescript
app.post('/api/ai/chat/stream', async (req, res) => {
  // Set SSE headers
  res.setHeader('Content-Type', 'text/event-stream')
  res.setHeader('Cache-Control', 'no-cache')
  res.setHeader('Connection', 'keep-alive')

  // Uses Google Gemini via gemini-client.ts
  const stream = await geminiClient.streamChat(req.body.messages)

  for await (const chunk of stream) {
    res.write(`data: ${JSON.stringify({ content: chunk })}\n\n`)
  }

  res.write('data: [DONE]\n\n')
  res.end()
})
```

## Error Handling

### Standard Error Response

```typescript
interface ErrorResponse {
  error: string
  code?: string
  details?: unknown
}

// Usage
return res.status(400).json({
  error: 'Invalid request',
  code: 'INVALID_PARAMS',
  details: { field: 'email', reason: 'Invalid format' }
})
```

### Common Status Codes

| Code | Usage |
|------|-------|
| 200 | Success |
| 400 | Bad request (validation) |
| 401 | Unauthorized (no/invalid auth) |
| 403 | Forbidden (insufficient permissions) |
| 404 | Resource not found |
| 429 | Rate limited |
| 500 | Server error |

## Rate Limiting

Rate limiting uses Redis:

```typescript
const rateLimitKey = `ratelimit:${endpoint}:${userId}`
const count = await redis.incr(rateLimitKey)

if (count === 1) {
  await redis.expire(rateLimitKey, 60) // 1 minute window
}

if (count > MAX_REQUESTS) {
  return res.status(429).json({ error: 'Rate limited' })
}
```

## Environment Variables

See [ENVIRONMENT_VARIABLES.md](/backend-server/ENVIRONMENT_VARIABLES.md) for complete list.

Key variables:

```env
# Server
PORT=8080

# Supabase
SUPABASE_URL=
SUPABASE_SERVICE_ROLE_KEY=

# External Services
OPENAI_API_KEY=
STRIPE_SECRET_KEY=
STRIPE_WEBHOOK_SECRET=
GEMINI_API_KEY=

# Redis
UPSTASH_REDIS_REST_URL=
UPSTASH_REDIS_REST_TOKEN=

# Pricing Configuration
STARTER_MONTHLY_PRICE=40
PREMIUM_MONTHLY_PRICE=280
```

## Testing

### Manual Testing

Use curl or Postman:

```bash
# Health check
curl http://localhost:8080/health

# Authenticated request
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:8080/api/subscriptions
```

### Webhook Testing (Stripe)

```bash
# Forward Stripe webhooks locally
stripe listen --forward-to localhost:8080/api/webhooks/stripe
```
