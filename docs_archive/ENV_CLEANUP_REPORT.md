# 🧹 Environment Variables Cleanup Report

## Analysis Summary

I've audited all environment variables in `.env` and `.env.example` to identify which are actually used in the source code.

## Variables Status

### ✅ USED in Frontend Source Code

| Variable | Used In | Purpose |
|----------|---------|---------|
| `VITE_SUPABASE_URL` | lib/supabase.ts | Supabase connection |
| `VITE_SUPABASE_ANON_KEY` | lib/supabase.ts | Supabase authentication |
| `VITE_SUPABASE_USER_FILES_BUCKET` | stores/card.ts, stores/contentItem.ts | File uploads |
| `VITE_STRIPE_PUBLISHABLE_KEY` | utils/stripeCheckout.js | Payment processing |
| `VITE_DEFAULT_CARD_IMAGE_URL` | views/Public/LandingPage.vue | Demo card image |
| `VITE_SAMPLE_QR_URL` | views/Public/LandingPage.vue | Demo QR code |
| `VITE_DEFAULT_CURRENCY` | utils/stripeCheckout.js | Payment currency |
| `VITE_CARD_ASPECT_RATIO_WIDTH` | utils/cardConfig.ts | Card image cropping |
| `VITE_CARD_ASPECT_RATIO_HEIGHT` | utils/cardConfig.ts | Card image cropping |
| `VITE_CONTENT_ASPECT_RATIO_WIDTH` | utils/cardConfig.ts | Content image cropping |
| `VITE_CONTENT_ASPECT_RATIO_HEIGHT` | utils/cardConfig.ts | Content image cropping |
| `VITE_STRIPE_SUCCESS_URL` | utils/stripeCheckout.js | Payment redirect |
| `VITE_DEFAULT_AI_INSTRUCTION` | CardComponents/CardCreateEditForm.vue | AI template |
| `VITE_OPENAI_REALTIME_MODEL` | composables/useWebRTCConnection.ts | Realtime API |
| `VITE_OPENAI_RELAY_URL` | *Optional* - Used when present | Relay proxy |

### ❌ NOT USED in Source Code (Only in docs/backups/types)

| Variable | Found Only In | Reason to Remove |
|----------|---------------|------------------|
| `VITE_APP_BASE_URL` | docs, env.d.ts | Never referenced in actual code |
| `VITE_CARD_PRICE_CENTS` | docs, env.d.ts | Not used (now credit-based) |
| `VITE_CONTACT_EMAIL` | LandingPage.backup.vue | Only in backup file, not current code |
| `VITE_CONTACT_WHATSAPP_URL` | LandingPage.backup.vue | Only in backup file |
| `VITE_CONTACT_PHONE` | LandingPage.backup.vue | Only in backup file |
| `VITE_OPENAI_MODEL` | docs only | Never referenced in code |
| `VITE_ENV` | Not found | Completely unused |
| `NODE_ENV` | N/A | System variable, shouldn't be in .env |

### 🔒 Server-Side Only (Edge Functions - Not frontend)

| Variable | Purpose | Action |
|----------|---------|--------|
| `STRIPE_SECRET_KEY` | Edge Functions only | Keep but document as server-side |
| `OPENAI_API_KEY` | Edge Functions only | Remove from .env (use Supabase secrets) |
| `OPENAI_AUDIO_MODEL` | Edge Functions only | Remove from .env (use Supabase secrets) |
| `OPENAI_TTS_VOICE` | Edge Functions only | Remove from .env (use Supabase secrets) |
| `OPENAI_AUDIO_FORMAT` | Edge Functions only | Remove from .env (use Supabase secrets) |

### ⚠️ MISSING Variables (Used but not in .env)

| Variable | Used In | Should Add |
|----------|---------|------------|
| `VITE_DEMO_CARD_TITLE` | LandingPage.vue | ✅ Yes |
| `VITE_DEMO_CARD_SUBTITLE` | LandingPage.vue | ✅ Yes |

## Recommendations

### 1. Variables to REMOVE from .env
```bash
# Remove these - not used in source code
VITE_APP_BASE_URL
VITE_CARD_PRICE_CENTS
VITE_CONTACT_EMAIL
VITE_CONTACT_WHATSAPP_URL
VITE_CONTACT_PHONE
VITE_OPENAI_MODEL
VITE_ENV
NODE_ENV

# Remove these - Edge Function secrets (use Supabase dashboard)
OPENAI_API_KEY
OPENAI_AUDIO_MODEL
OPENAI_TTS_VOICE
OPENAI_AUDIO_FORMAT
```

### 2. Variables to ADD to .env
```bash
# Add these - used but missing
VITE_DEMO_CARD_TITLE=Ancient Mysteries
VITE_DEMO_CARD_SUBTITLE=AI-Powered Museum Guide
```

### 3. Keep STRIPE_SECRET_KEY?
**Decision:** Remove from frontend .env
- It's server-side only
- Should be in Supabase Edge Function secrets
- Keeping it in .env is a security risk if committed

## Final Cleaned .env Structure

```bash
# Supabase Configuration
VITE_SUPABASE_URL=https://mzgusshseqxrdrkvamrg.supabase.co
VITE_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
VITE_SUPABASE_USER_FILES_BUCKET=userfiles

# Stripe Configuration (Frontend)
VITE_STRIPE_PUBLISHABLE_KEY=pk_test_51RM1qBEJC0XcJrVg...

# Stripe Return URLs
VITE_STRIPE_SUCCESS_URL=http://localhost:5173/cms/mycards
VITE_STRIPE_CANCEL_URL=http://localhost:5173/cms/mycards

# Landing Page Demo Card
VITE_DEFAULT_CARD_IMAGE_URL=https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=600&q=80
VITE_SAMPLE_QR_URL=https://cardstudio.org/c/cd9e2a12-066d-4b1f-8585-73f7807118db
VITE_DEMO_CARD_TITLE=Ancient Mysteries
VITE_DEMO_CARD_SUBTITLE=AI-Powered Museum Guide

# Currency
VITE_DEFAULT_CURRENCY=USD

# Card Aspect Ratio Configuration
VITE_CARD_ASPECT_RATIO_WIDTH=2
VITE_CARD_ASPECT_RATIO_HEIGHT=3

# Content Item Aspect Ratio Configuration  
VITE_CONTENT_ASPECT_RATIO_WIDTH=4
VITE_CONTENT_ASPECT_RATIO_HEIGHT=3

# Default AI Assistant Instruction Template
VITE_DEFAULT_AI_INSTRUCTION="You are a knowledgeable and friendly AI assistant for museum and exhibition visitors. Provide accurate, engaging, and educational explanations about exhibits and artifacts. Keep responses conversational and easy to understand. If you don't know something, politely say so rather than making up information."

# OpenAI Realtime Model (must match Supabase Edge Function setting)
VITE_OPENAI_REALTIME_MODEL=gpt-realtime-mini-2025-10-06

# OpenAI Realtime API Relay Server (Optional)
# Leave empty to connect directly to OpenAI
# Set to relay URL if direct connection is blocked in your region
VITE_OPENAI_RELAY_URL=ws://136.114.213.182:8080
```

## Impact

### Lines Removed: 13
- Unused frontend variables: 8
- Server-side variables: 5
- System variables: 1 (NODE_ENV)

### Lines Added: 2
- Missing demo card variables

### Net Result: -11 lines, cleaner configuration

## Security Improvements

✅ Removed server-side secrets from frontend .env  
✅ Cleaner configuration  
✅ Only variables actually used by frontend  
✅ Better documentation of optional variables  

## Next Steps

1. Apply the cleaned .env file
2. Update .env.example to match
3. Update env.d.ts to remove unused type definitions
4. Document Edge Function secrets separately

---

**All unused variables identified and ready to remove!** 🎉
