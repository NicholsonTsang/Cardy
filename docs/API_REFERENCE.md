# API Reference

This document lists all backend API endpoints.

## Base URL

- **Local**: `http://localhost:3001`
- **Production**: Configured via `VITE_BACKEND_URL`

## Authentication

Most endpoints require JWT authentication via the `Authorization` header:

```
Authorization: Bearer <supabase-jwt-token>
```

Public endpoints (mobile card access) use access tokens in the URL path.

---

## Subscriptions

### GET /api/subscriptions

Get current user's subscription status.

**Auth**: Required

**Response**:
```json
{
  "subscription": {
    "tier": "starter",
    "status": "active",
    "current_period_end": "2024-02-15T00:00:00Z"
  }
}
```

### POST /api/subscriptions/create-checkout

Create Stripe checkout session for new subscription.

**Auth**: Required

**Body**:
```json
{
  "tier": "starter" | "premium",
  "successUrl": "https://...",
  "cancelUrl": "https://..."
}
```

**Response**:
```json
{
  "checkoutUrl": "https://checkout.stripe.com/..."
}
```

### POST /api/subscriptions/cancel

Cancel current subscription.

**Auth**: Required

**Response**:
```json
{
  "success": true,
  "cancelAt": "2024-02-15T00:00:00Z"
}
```

### POST /api/subscriptions/reactivate

Reactivate a cancelled subscription.

**Auth**: Required

**Response**:
```json
{
  "success": true
}
```

### GET /api/subscriptions/portal

Get Stripe customer portal URL.

**Auth**: Required

**Response**:
```json
{
  "portalUrl": "https://billing.stripe.com/..."
}
```

### GET /api/subscriptions/usage

Get current usage stats.

**Auth**: Required

**Response**:
```json
{
  "budget": 40.00,
  "used": 12.50,
  "remaining": 27.50,
  "sessions": {
    "ai": 150,
    "nonAi": 200
  }
}
```

### POST /api/subscriptions/buy-credits

Purchase additional credits.

**Auth**: Required

**Body**:
```json
{
  "amount": 50,
  "successUrl": "https://...",
  "cancelUrl": "https://..."
}
```

---

## Payments

### POST /api/payments/create-credit-checkout

Create checkout for physical card credits.

**Auth**: Required

**Body**:
```json
{
  "credits": 100,
  "successUrl": "https://...",
  "cancelUrl": "https://..."
}
```

**Response**:
```json
{
  "checkoutUrl": "https://checkout.stripe.com/..."
}
```

---

## AI / Chat

### POST /api/ai/chat/stream

Stream AI chat response (SSE).

**Auth**: Required

**Body**:
```json
{
  "messages": [
    { "role": "user", "content": "Hello" }
  ],
  "cardId": "uuid",
  "itemId": "uuid" | null,
  "language": "en"
}
```

**Response**: Server-Sent Events stream

```
data: {"content": "Hello"}
data: {"content": "! How"}
data: {"content": " can I help?"}
data: [DONE]
```

### POST /api/ai/generate-tts

Generate text-to-speech audio.

**Auth**: Required

**Body**:
```json
{
  "text": "Hello, welcome!",
  "voice": "alloy"
}
```

**Response**: Audio stream (MP3)

### POST /api/ai/realtime-token

Get ephemeral token for OpenAI realtime API.

**Auth**: Required

**Body**:
```json
{
  "cardId": "uuid"
}
```

**Response**:
```json
{
  "token": "ephemeral-token",
  "expiresAt": "2024-01-15T10:35:00Z"
}
```

---

## Translations

### POST /api/translations/translate-card

Translate card content to target languages.

**Auth**: Required (Premium or Admin)

**Body**:
```json
{
  "cardId": "uuid",
  "targetLanguages": ["zh-Hans", "ja", "ko"]
}
```

**Response**:
```json
{
  "success": true,
  "translatedLanguages": ["zh-Hans", "ja", "ko"],
  "creditsConsumed": 15
}
```

---

## Mobile Client

### GET /api/mobile/card/digital/:accessToken

Get card data by digital access token.

**Auth**: None (public)

**Params**:
- `accessToken`: 12-character access token

**Response**:
```json
{
  "card": {
    "id": "uuid",
    "name": "Museum Guide",
    "description": "...",
    "contentMode": "list",
    "aiEnabled": true
  },
  "content": [
    {
      "id": "uuid",
      "name": "Exhibit 1",
      "content": "..."
    }
  ],
  "translations": {
    "zh-Hans": { "name": "博物馆指南" }
  }
}
```

### GET /api/mobile/card/physical/:issueCardId

Get card data by physical card ID.

**Auth**: None (public)

**Params**:
- `issueCardId`: Physical card identifier

**Response**: Same as digital endpoint

### POST /api/mobile/card/:cardId/invalidate-cache

Clear cached content for a card.

**Auth**: Required (card owner)

**Params**:
- `cardId`: Card UUID

**Response**:
```json
{
  "success": true
}
```

---

## Webhooks

### POST /api/webhooks/stripe

Handle Stripe webhook events.

**Auth**: Stripe signature verification

**Events Handled**:
- `checkout.session.completed`
- `customer.subscription.updated`
- `customer.subscription.deleted`
- `invoice.paid`
- `invoice.payment_failed`

**Response**:
```json
{
  "received": true
}
```

---

## Health Check

### GET /health

Check API server status.

**Auth**: None

**Response**:
```json
{
  "status": "ok",
  "timestamp": "2024-01-15T10:30:00Z"
}
```

### GET /api

Get API information and available endpoints.

**Auth**: None

**Response**:
```json
{
  "service": "FunTell Backend API",
  "version": "2.0.0",
  "endpoints": { ... }
}
```

---

## Error Responses

All endpoints return errors in this format:

```json
{
  "error": "Error message",
  "code": "ERROR_CODE",
  "details": { ... }
}
```

### Common Error Codes

| Code | Status | Description |
|------|--------|-------------|
| `UNAUTHORIZED` | 401 | Missing or invalid auth token |
| `FORBIDDEN` | 403 | Insufficient permissions |
| `NOT_FOUND` | 404 | Resource not found |
| `INVALID_PARAMS` | 400 | Invalid request parameters |
| `RATE_LIMITED` | 429 | Too many requests |
| `INSUFFICIENT_CREDITS` | 400 | Not enough credits |
| `USAGE_LIMIT_EXCEEDED` | 400 | Monthly usage exceeded |
| `SUBSCRIPTION_REQUIRED` | 403 | Feature requires subscription |
