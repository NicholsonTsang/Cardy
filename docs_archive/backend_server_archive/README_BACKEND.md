# CardStudio Backend Server

## Overview

Unified Express/Node.js backend server for CardStudio, consolidating all Supabase Edge Functions into a single, maintainable codebase.

---

## 🚀 Quick Start

```bash
# Install dependencies
npm install

# Configure environment
cp .env.example .env
# Edit .env with your API keys

# Development
npm run dev

# Production build
npm run build
npm start
```

Server runs on `http://localhost:8080` (or configured PORT).

---

## 📡 API Endpoints

### Health & Info
- `GET /health` - Server health check
- `GET /api` - API documentation

### Translation (Auth Required)
- `POST /api/translations/translate-card` - Translate card content to multiple languages (1 credit/language)

### Payment (Auth Required)
- `POST /api/payments/create-credit-checkout` - Create Stripe checkout session for credit purchase

### AI (Optional Auth)
- `POST /api/ai/chat/stream` - Streaming AI chat responses via SSE
- `POST /api/ai/generate-tts` - Generate audio from text (OpenAI TTS)
- `POST /api/ai/realtime-token` - Get ephemeral token for WebRTC voice

### Webhooks (Signature Verification)
- `POST /api/webhooks/stripe-credit` - Handle Stripe webhook events

### Relay (Original Feature)
- `POST /offer` - WebRTC SDP relay for OpenAI Realtime API

---

## 🏗️ Architecture

```
src/
├── config/
│   └── supabase.ts          # Supabase admin client
├── middleware/
│   └── auth.ts              # JWT authentication
├── routes/
│   ├── index.ts             # Route aggregator
│   ├── translation.routes.ts
│   ├── payment.routes.ts
│   ├── ai.routes.ts
│   └── webhook.routes.ts
└── index.ts                 # Main server
```

### Middleware

- **authenticateUser** - Required JWT authentication
- **optionalAuth** - Optional authentication (enhances public endpoints)
- **CORS** - Configurable origin whitelist
- **Rate Limiting** - Abuse prevention
- **Helmet** - Security headers

---

## 🔐 Security

### Authentication Flow
1. Frontend gets JWT from Supabase Auth
2. Request includes `Authorization: Bearer <token>` header
3. Backend validates JWT with Supabase service role client
4. User info attached to request, operations validated

### Best Practices
- ✅ JWT validation for protected routes
- ✅ Explicit user_id in database calls (no client trust)
- ✅ Stripe signature verification for webhooks
- ✅ CORS origin whitelist
- ✅ Rate limiting per endpoint
- ✅ Comprehensive error logging

---

## 🔧 Configuration

### Required Environment Variables

```bash
# OpenAI
OPENAI_API_KEY=sk-...
OPENAI_TEXT_MODEL=gpt-4o-mini
OPENAI_TTS_MODEL=tts-1
OPENAI_TTS_VOICE=alloy
OPENAI_REALTIME_MODEL=gpt-realtime-mini-2025-10-06

# Supabase
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=eyJhbGc...

# Stripe
STRIPE_SECRET_KEY=sk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...

# Server
PORT=8080
NODE_ENV=production
ALLOWED_ORIGINS=https://your-app.com,https://admin.your-app.com
```

---

## 🧪 Testing

### Manual Testing

```bash
# Health check
curl http://localhost:8080/health

# Protected endpoint (requires JWT)
curl -X POST http://localhost:8080/api/translations/translate-card \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"cardId": "uuid", "targetLanguages": ["zh-Hant"]}'

# Public endpoint
curl -X POST http://localhost:8080/api/ai/generate-tts \
  -H "Content-Type: application/json" \
  -d '{"text": "Hello world"}' \
  --output test.wav

# Webhook testing (Stripe CLI)
stripe listen --forward-to http://localhost:8080/api/webhooks/stripe-credit
```

---

## 🚀 Deployment

### PM2 (Recommended for VPS)

```bash
npm run build
pm2 start ecosystem.config.js
pm2 save
pm2 startup
```

### Docker

```bash
docker build -t cardstudio-backend .
docker run -d -p 8080:8080 --env-file .env cardstudio-backend
```

### Cloud Run (GCP)

```bash
./deploy-cloud-run.sh
```

**Requirements:**
- Public HTTPS endpoint for Stripe webhooks
- SSL certificate (auto-provisioned by Cloud Run)
- Health check endpoint: `/health`
- Graceful shutdown handling (included)

---

## 📊 Monitoring

### Health Check Response

```json
{
  "status": "healthy",
  "timestamp": "2025-10-31T12:00:00.000Z",
  "uptime": 3600,
  "version": "1.0.0",
  "services": {
    "openai": true,
    "supabase": true
  }
}
```

### Logging

All operations are logged with structured format:
- ✅ Request details (endpoint, method, user)
- ✅ Response time and status
- ✅ Error details with stack traces
- ✅ Database operation results

---

## 🔄 Migration from Edge Functions

See `MIGRATION_GUIDE.md` for:
- Complete API reference
- Frontend code migration examples
- Step-by-step migration checklist
- Testing procedures

---

## 📚 API Documentation

### Translation API

**Endpoint:** `POST /api/translations/translate-card`

**Auth:** Required (JWT token)

**Request:**
```json
{
  "cardId": "uuid",
  "targetLanguages": ["zh-Hant", "ja", "ko"],
  "forceRetranslate": false
}
```

**Response:**
```json
{
  "success": true,
  "translated_languages": ["zh-Hant", "ja", "ko"],
  "credits_used": 3,
  "remaining_balance": 97,
  "message": "Translation completed successfully"
}
```

**Features:**
- Parallel translation (all languages simultaneously)
- Automatic freshness detection (outdated vs up-to-date)
- Credit consumption only for actually translated languages
- Comprehensive error handling

### Payment API

**Endpoint:** `POST /api/payments/create-credit-checkout`

**Auth:** Required (JWT token)

**Request:**
```json
{
  "creditAmount": 100,
  "amountUsd": 100,
  "baseUrl": "https://your-app.com/credits",
  "metadata": {}
}
```

**Response:**
```json
{
  "sessionId": "cs_test_...",
  "url": "https://checkout.stripe.com/...",
  "purchaseId": "uuid"
}
```

### AI Chat Stream API

**Endpoint:** `POST /api/ai/chat/stream`

**Auth:** Optional

**Request:**
```json
{
  "messages": [
    { "role": "user", "content": "Tell me about this artifact" }
  ],
  "systemPrompt": "You are a museum guide",
  "language": "en"
}
```

**Response:** Server-Sent Events (SSE)
```
data: {"content": "This "}
data: {"content": "artifact "}
data: {"content": "is..."}
data: [DONE]
```

---

## 💡 Best Practices

### Development
- Use `ALLOWED_ORIGINS=*` for easy CORS
- Monitor logs with `npm run dev`
- Test endpoints with curl/Postman
- Use Stripe CLI for webhook testing

### Production
- Set specific `ALLOWED_ORIGINS`
- Use `NODE_ENV=production`
- Enable monitoring (PM2, Cloud Run logs)
- Configure health checks
- Set up auto-scaling
- Implement request logging
- Use HTTPS only

### Database Operations
- Always pass explicit `p_user_id` to stored procedures
- Never trust client-provided user IDs
- Verify ownership before operations
- Log all operations for audit trail

---

## 🐛 Troubleshooting

### Server won't start
- Check `.env` file exists and has all required variables
- Verify port 8080 is not in use: `lsof -i :8080`
- Check logs for missing environment variables

### Authentication errors
- Ensure JWT token is valid (not expired)
- Verify `SUPABASE_SERVICE_ROLE_KEY` is correct
- Check user exists in database

### Stripe webhook errors
- Verify `STRIPE_WEBHOOK_SECRET` is correct
- Use Stripe CLI for local testing
- Check webhook signature verification

### CORS errors
- Update `ALLOWED_ORIGINS` in `.env`
- For development: `ALLOWED_ORIGINS=*`
- For production: specific domains

---

## 📞 Support

Check these resources:
1. `MIGRATION_GUIDE.md` - Complete migration guide
2. Server logs - `npm run dev` (real-time logs)
3. Health endpoint - `GET /health`
4. API info - `GET /api`

---

## 📝 Version

**Version:** 1.0.0

**Status:** Production Ready ✅

**Last Updated:** October 31, 2025

---

**All Edge Functions successfully migrated! 🎉**

