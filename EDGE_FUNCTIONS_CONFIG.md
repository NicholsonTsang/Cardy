# Edge Functions Configuration Guide

## 📋 Overview

This document centralizes all Edge Function environment variable configurations for both local development and production deployment.

---

## 🔧 Configuration Files

### **1. Local Development**
**File:** `supabase/config.toml` (section: `[edge_runtime.secrets]`)

### **2. Production**
**Method 1:** Supabase Dashboard → Project Settings → Edge Functions → Secrets  
**Method 2:** Supabase CLI: `supabase secrets set KEY=VALUE`

---

## 📦 All Edge Functions & Their Variables

### **1. create-checkout-session**
**Purpose:** Create Stripe checkout sessions for card batch payments

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `STRIPE_SECRET_KEY` | ✅ Yes | - | Stripe API secret key (test or live) |
| `SUPABASE_URL` | ✅ Yes | - | Auto-provided by Supabase |
| `SUPABASE_ANON_KEY` | ✅ Yes | - | Auto-provided by Supabase |

**Notes:**
- ✅ Success/cancel URLs now passed from frontend (`baseUrl` parameter)
- ❌ No longer uses `STRIPE_SUCCESS_URL` or `STRIPE_CANCEL_URL` environment variables

---

### **2. handle-checkout-success**
**Purpose:** Process successful Stripe payments and confirm batch payments

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `STRIPE_SECRET_KEY` | ✅ Yes | - | Stripe API secret key (test or live) |
| `SUPABASE_URL` | ✅ Yes | - | Auto-provided by Supabase |
| `SUPABASE_ANON_KEY` | ✅ Yes | - | Auto-provided by Supabase |

---

### **3. chat-with-audio**
**Purpose:** Handle AI conversations with audio input/output using OpenAI Chat Completions API

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `OPENAI_API_KEY` | ✅ Yes | - | OpenAI API key |
| `OPENAI_STT_MODE` | ❌ No | `audio-model` | STT mode: `audio-model` or `whisper` |
| `OPENAI_AUDIO_MODEL` | ❌ No | `gpt-4o-mini-audio-preview` | Model for audio-model STT mode |
| `OPENAI_WHISPER_MODEL` | ❌ No | `whisper-1` | Model for whisper STT mode |
| `OPENAI_TEXT_MODEL` | ❌ No | `gpt-4o-mini` | Model for text generation |
| `OPENAI_MAX_TOKENS` | ❌ No | `3500` | Maximum tokens in AI response |
| `OPENAI_TTS_VOICE` | ❌ No | `alloy` | Voice for text-to-speech |
| `OPENAI_AUDIO_FORMAT` | ❌ No | `wav` | Audio output format (`wav` or `mp3`) |

**Available Voices:**
- `alloy` - Neutral, balanced (default)
- `echo` - Clear, professional
- `fable` - Warm, storytelling
- `onyx` - Deep, authoritative
- `nova` - Energetic, young
- `shimmer` - Soft, calming

**Available Models:**
- `gpt-4o-mini-audio-preview` - Cost-effective (recommended for dev)
- `gpt-4o-audio-preview` - Premium quality (recommended for production)

---

### **4. chat-with-audio-stream**
**Purpose:** Stream text responses from OpenAI Chat Completions API (text input only)

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `OPENAI_API_KEY` | ✅ Yes | - | OpenAI API key |
| `OPENAI_TEXT_MODEL` | ❌ No | `gpt-4o-mini` | OpenAI model for text generation |
| `OPENAI_MAX_TOKENS` | ❌ No | `3500` | Maximum tokens in AI response |

**Available Models:**
- `gpt-4o-mini` - Cost-effective, fast (recommended)
- `gpt-4o` - Premium quality, slower

**Note:** This function is used for text-only input with streaming responses.

---

### **5. generate-tts-audio**
**Purpose:** Generate audio from text using OpenAI TTS API

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `OPENAI_API_KEY` | ✅ Yes | - | OpenAI API key |
| `OPENAI_TTS_MODEL` | ❌ No | `tts-1` | OpenAI TTS model |
| `OPENAI_TTS_VOICE` | ❌ No | `alloy` | Voice for text-to-speech |
| `OPENAI_AUDIO_FORMAT` | ❌ No | `wav` | Audio output format (`wav` or `mp3`) |

**Available TTS Models:**
- `tts-1` - Cost-effective, fast (recommended)
- `tts-1-hd` - Premium quality, slower

**Available Voices:**
- `alloy` - Neutral, balanced (default)
- `echo` - Male, clear
- `fable` - British accent
- `onyx` - Deep, authoritative
- `nova` - Female, warm
- `shimmer` - Female, upbeat

---

### **6. get-openai-ephemeral-token**
**Purpose:** Generate ephemeral tokens for OpenAI Realtime API (legacy, may be deprecated)

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `OPENAI_API_KEY` | ✅ Yes | - | OpenAI API key |
| `OPENAI_MODEL` | ❌ No | `gpt-4o-realtime-preview-2025-06-03` | OpenAI Realtime model |

**Note:** This function is used by the old Realtime API implementation. The new `chat-with-audio` function is recommended.

---

### **7. openai-realtime-proxy**
**Purpose:** Proxy WebRTC connections to OpenAI Realtime API (legacy, may be deprecated)

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `OPENAI_API_KEY` | ✅ Yes | - | OpenAI API key |

**Note:** This function is used by the old Realtime API implementation. The new `chat-with-audio` function is recommended.

---

## 🔐 Complete Configuration Templates

### **Local Development (`supabase/config.toml`)**

```toml
[edge_runtime.secrets]
# Stripe Configuration (Test Mode)
STRIPE_SECRET_KEY = "sk_test_..."

# OpenAI Configuration (Cost-effective for development)
OPENAI_API_KEY = "sk-proj-..."
OPENAI_AUDIO_MODEL = "gpt-4o-mini-audio-preview"
OPENAI_MAX_TOKENS = "2000"  # Lower for faster testing
OPENAI_TTS_VOICE = "alloy"
OPENAI_AUDIO_FORMAT = "wav"

# Legacy OpenAI Realtime (if still using)
OPENAI_MODEL = "gpt-4o-realtime-preview-2025-06-03"

# Note: SUPABASE_URL and SUPABASE_ANON_KEY are auto-provided by Supabase CLI
```

### **Production (Supabase Dashboard Secrets)**

**Required Secrets:**
```bash
# Stripe (Live Mode)
STRIPE_SECRET_KEY=sk_live_...

# OpenAI (Premium for production)
OPENAI_API_KEY=sk-proj-...
OPENAI_AUDIO_MODEL=gpt-4o-mini-audio-preview  # or gpt-4o-audio-preview
OPENAI_MAX_TOKENS=3500
OPENAI_TTS_VOICE=alloy
OPENAI_AUDIO_FORMAT=wav
```

**Legacy (if still using Realtime API):**
```bash
OPENAI_MODEL=gpt-4o-realtime-preview-2025-06-03
```

---

## ⚡ Quick Setup Commands

### **Set All Secrets at Once (Production)**

```bash
# Core Stripe Configuration
supabase secrets set STRIPE_SECRET_KEY=sk_live_...

# Core OpenAI Configuration
supabase secrets set OPENAI_API_KEY=sk-proj-...

# Optional OpenAI Overrides (uses defaults if not set)
supabase secrets set OPENAI_AUDIO_MODEL=gpt-4o-mini-audio-preview
supabase secrets set OPENAI_MAX_TOKENS=3500
supabase secrets set OPENAI_TTS_VOICE=alloy
supabase secrets set OPENAI_AUDIO_FORMAT=wav

# Legacy OpenAI Realtime (if needed)
supabase secrets set OPENAI_MODEL=gpt-4o-realtime-preview-2025-06-03
```

### **Verify Secrets**

```bash
# List all configured secrets (names only, values hidden)
supabase secrets list

# Expected output:
# STRIPE_SECRET_KEY
# OPENAI_API_KEY
# OPENAI_AUDIO_MODEL
# OPENAI_MAX_TOKENS
# OPENAI_TTS_VOICE
# OPENAI_AUDIO_FORMAT
```

### **Update a Single Secret**

```bash
supabase secrets set OPENAI_MAX_TOKENS=4000
```

### **Remove a Secret**

```bash
supabase secrets unset OPENAI_MODEL
```

---

## 🚀 Deployment Checklist

### **Before Deployment**

- [ ] Set `STRIPE_SECRET_KEY` (test key for dev, live key for production)
- [ ] Set `OPENAI_API_KEY` (from OpenAI Platform)
- [ ] (Optional) Configure `OPENAI_AUDIO_MODEL` if not using default
- [ ] (Optional) Configure `OPENAI_MAX_TOKENS` if not using default 3500
- [ ] (Optional) Configure `OPENAI_TTS_VOICE` if not using default `alloy`
- [ ] Verify secrets: `supabase secrets list`

### **Deploy All Functions**

```bash
# Deploy all Edge Functions at once
npx supabase functions deploy create-checkout-session
npx supabase functions deploy handle-checkout-success
npx supabase functions deploy chat-with-audio
npx supabase functions deploy get-openai-ephemeral-token
npx supabase functions deploy openai-realtime-proxy
```

Or deploy all at once:
```bash
npx supabase functions deploy
```

### **After Deployment**

- [ ] Test Stripe checkout flow
- [ ] Test AI chat with audio
- [ ] Check function logs for errors: Supabase Dashboard → Edge Functions → Logs
- [ ] Monitor OpenAI API usage: [OpenAI Platform](https://platform.openai.com/usage)
- [ ] Monitor Stripe transactions: [Stripe Dashboard](https://dashboard.stripe.com/)

---

## 🔄 Environment-Specific Configurations

### **Development Environment**

**Goals:** Cost-effective, fast iteration, easy debugging

```toml
[edge_runtime.secrets]
# Test mode Stripe
STRIPE_SECRET_KEY = "sk_test_..."

# Cost-effective OpenAI
OPENAI_API_KEY = "sk-proj-..."
OPENAI_AUDIO_MODEL = "gpt-4o-mini-audio-preview"  # Cheaper
OPENAI_MAX_TOKENS = "2000"  # Lower for speed
OPENAI_TTS_VOICE = "alloy"
OPENAI_AUDIO_FORMAT = "wav"
```

### **Staging Environment**

**Goals:** Production-like, full testing, cost monitoring

```bash
# Test mode but production configuration
STRIPE_SECRET_KEY=sk_test_...
OPENAI_API_KEY=sk-proj-...
OPENAI_AUDIO_MODEL=gpt-4o-audio-preview  # Premium quality
OPENAI_MAX_TOKENS=3500  # Full capacity
OPENAI_TTS_VOICE=alloy
OPENAI_AUDIO_FORMAT=wav
```

### **Production Environment**

**Goals:** Maximum quality, reliability, monitoring

```bash
# Live Stripe
STRIPE_SECRET_KEY=sk_live_...

# Premium OpenAI
OPENAI_API_KEY=sk-proj-...
OPENAI_AUDIO_MODEL=gpt-4o-mini-audio-preview  # or gpt-4o-audio-preview
OPENAI_MAX_TOKENS=3500
OPENAI_TTS_VOICE=alloy
OPENAI_AUDIO_FORMAT=wav
```

---

## 🐛 Troubleshooting

### **Issue: "OPENAI_API_KEY not configured"**

**Solution:**
```bash
# Check if secret exists
supabase secrets list

# If missing, set it
supabase secrets set OPENAI_API_KEY=sk-proj-...

# Verify it's set
supabase secrets list | grep OPENAI_API_KEY
```

### **Issue: "Stripe error: Invalid API Key"**

**Solutions:**
1. Check you're using the right key for the environment (test vs live)
2. Verify key format: `sk_test_...` or `sk_live_...`
3. Check key hasn't been deleted in Stripe Dashboard
4. Update secret:
   ```bash
   supabase secrets set STRIPE_SECRET_KEY=sk_...
   ```

### **Issue: "Model not found"**

**Solution:**
```bash
# Check current model configuration
supabase secrets list | grep OPENAI_AUDIO_MODEL

# Update to correct model
supabase secrets set OPENAI_AUDIO_MODEL=gpt-4o-mini-audio-preview
```

### **Issue: Edge Function returns 500**

**Steps:**
1. Check logs: Supabase Dashboard → Edge Functions → Select function → Logs
2. Look for environment variable errors
3. Verify all required secrets are set: `supabase secrets list`
4. Check API key validity (OpenAI, Stripe)
5. Test function locally: `supabase functions serve`

### **Issue: "SUPABASE_URL not defined"**

**Solution:** These are auto-provided. If missing:
1. Ensure you're using latest Supabase CLI: `supabase --version`
2. Redeploy function: `npx supabase functions deploy <function-name>`
3. These should NOT be manually set as secrets

---

## 📊 Cost Optimization

### **OpenAI Model Pricing (Approximate)**

| Model | Input (per 1M tokens) | Output (per 1M tokens) | Audio (per min) |
|-------|----------------------|------------------------|-----------------|
| `gpt-4o-mini-audio-preview` | $2.50 | $10.00 | ~$0.10 |
| `gpt-4o-audio-preview` | $5.00 | $20.00 | ~$0.20 |

**Recommendation:**
- **Development:** Use `gpt-4o-mini-audio-preview` with `max_tokens=2000`
- **Production:** Use `gpt-4o-mini-audio-preview` for cost efficiency or `gpt-4o-audio-preview` for premium quality

### **Stripe Fees**

- **Per transaction:** 2.9% + $0.30
- **CardStudio pricing:** $2.00 per card
- **Fee per card:** ~$0.36 (includes 2.9% + $0.30)

---

## 🔒 Security Best Practices

### **DO:**
✅ Use test keys in development  
✅ Use live keys only in production  
✅ Rotate API keys periodically  
✅ Set secrets via Supabase CLI or Dashboard  
✅ Never commit secrets to Git  
✅ Use environment-specific keys  

### **DON'T:**
❌ Hardcode API keys in code  
❌ Commit `.env` files with real keys  
❌ Use production keys in development  
❌ Share API keys via email/chat  
❌ Use the same key across all environments  

---

## 📝 Maintenance Schedule

### **Monthly**
- [ ] Review OpenAI API usage and costs
- [ ] Review Stripe transaction volume
- [ ] Check for deprecation notices (OpenAI, Stripe, Supabase)

### **Quarterly**
- [ ] Rotate OpenAI API keys
- [ ] Rotate Stripe API keys (if required by policy)
- [ ] Review and optimize `max_tokens` based on usage

### **Annually**
- [ ] Audit all secrets and remove unused ones
- [ ] Update to latest OpenAI models
- [ ] Review Stripe API version compatibility

---

## 🎯 Summary

**All Edge Functions:**
- create-checkout-session
- handle-checkout-success
- chat-with-audio
- get-openai-ephemeral-token (legacy)
- openai-realtime-proxy (legacy)

**Required Secrets:**
- `STRIPE_SECRET_KEY` (for payment functions)
- `OPENAI_API_KEY` (for AI functions)

**Optional Secrets (with good defaults):**
- `OPENAI_AUDIO_MODEL`
- `OPENAI_MAX_TOKENS`
- `OPENAI_TTS_VOICE`
- `OPENAI_AUDIO_FORMAT`
- `OPENAI_MODEL` (legacy)

**Configuration Location:**
- **Local:** `supabase/config.toml` → `[edge_runtime.secrets]`
- **Production:** Supabase Dashboard or `supabase secrets set`

**Quick Deploy:**
```bash
supabase secrets set STRIPE_SECRET_KEY=sk_... OPENAI_API_KEY=sk-...
npx supabase functions deploy
```

Done! 🚀

