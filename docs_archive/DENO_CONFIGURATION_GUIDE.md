# Deno Configuration Guide for Supabase Edge Functions

## 📋 **Overview**

There are **three main configuration files** for Deno and Edge Functions:

1. **`supabase/functions/deno.json`** - Deno-specific settings
2. **`supabase/config.toml`** - Supabase & local development config
3. **Supabase Dashboard Secrets** - Production environment variables

---

## 🔧 **1. Deno Configuration (`supabase/functions/deno.json`)**

### **Current Configuration**

```json
{
  "compilerOptions": {
    "allowJs": true,
    "lib": ["deno.window"],
    "strict": true
  },
  "imports": {
    "cors": "../_shared/cors.ts"
  }
}
```

### **What Each Setting Does**

#### **compilerOptions**
```json
{
  "allowJs": true,        // Allow JavaScript files
  "lib": ["deno.window"], // Include browser-like APIs
  "strict": true          // Enable TypeScript strict mode
}
```

#### **imports**
```json
{
  "cors": "../_shared/cors.ts"  // Import shortcut for CORS
}
```

### **Common Additions**

```json
{
  "compilerOptions": {
    "allowJs": true,
    "lib": ["deno.window"],
    "strict": true,
    "jsx": "react",              // If using JSX
    "jsxFactory": "h",           // JSX factory function
    "jsxFragmentFactory": "Fragment"
  },
  "imports": {
    "cors": "../_shared/cors.ts",
    "@supabase/supabase-js": "https://esm.sh/@supabase/supabase-js@2"
  },
  "tasks": {
    "dev": "deno run --watch index.ts"
  }
}
```

---

## ⚙️ **2. Supabase Config (`supabase/config.toml`)**

### **Edge Runtime Section**

```toml
[edge_runtime]
enabled = true
# Configure one of the supported request policies: `oneshot`, `per_worker`.
# Use `oneshot` for hot reload, or `per_worker` for load testing.
policy = "oneshot"
# Port to attach the Chrome inspector for debugging edge functions.
inspector_port = 8083
# The Deno major version to use.
deno_version = 1
```

### **Edge Runtime Secrets (Local Development)**

```toml
[edge_runtime.secrets]
# Add your environment variables here for LOCAL development
OPENAI_API_KEY = "sk-..."
OPENAI_AUDIO_MODEL = "gpt-4o-mini-audio-preview"
OPENAI_MAX_TOKENS = "3500"
OPENAI_TTS_VOICE = "alloy"
OPENAI_AUDIO_FORMAT = "wav"
STRIPE_SUCCESS_URL = "http://localhost:5173/cms/mycards"
STRIPE_CANCEL_URL = "http://localhost:5173/cms/mycards"
```

---

## 🔐 **3. Production Secrets (Supabase Dashboard)**

### **How to Set Production Secrets**

#### **Via Dashboard** (Recommended)

1. Go to [Supabase Dashboard](https://supabase.com/dashboard)
2. Select your project
3. Navigate to **Edge Functions**
4. Click on your function (e.g., `chat-with-audio`)
5. Go to **Secrets** tab
6. Click **Add Secret**
7. Enter:
   - **Name:** `OPENAI_API_KEY`
   - **Value:** `sk-...`
8. Click **Save**

#### **Via CLI**

```bash
# Set a single secret
supabase secrets set OPENAI_API_KEY=sk-...

# Set multiple secrets
supabase secrets set \
  OPENAI_API_KEY=sk-... \
  OPENAI_AUDIO_MODEL=gpt-4o-mini-audio-preview \
  OPENAI_MAX_TOKENS=3500

# List all secrets (names only, values are hidden)
supabase secrets list

# Unset a secret
supabase secrets unset OPENAI_API_KEY
```

---

## 📝 **Complete Configuration Example**

### **For Your AI Assistant (chat-with-audio)**

#### **Local Development** (`supabase/config.toml`)

```toml
[edge_runtime.secrets]
# OpenAI API Configuration
OPENAI_API_KEY = "sk-proj-..."  # Your OpenAI API key
OPENAI_AUDIO_MODEL = "gpt-4o-mini-audio-preview"  # Cost-effective default
OPENAI_MAX_TOKENS = "3500"  # Maximum response length
OPENAI_TTS_VOICE = "alloy"  # Voice for audio output (alloy, echo, fable, onyx, nova, shimmer)
OPENAI_AUDIO_FORMAT = "wav"  # Audio format (wav or mp3)

# Stripe Configuration (for local testing)
STRIPE_PUBLISHABLE_KEY = "pk_test_..."
STRIPE_SECRET_KEY = "sk_test_..."
STRIPE_SUCCESS_URL = "http://localhost:5173/cms/mycards"
STRIPE_CANCEL_URL = "http://localhost:5173/cms/mycards"
```

#### **Production** (Supabase Dashboard → Secrets)

```bash
# Core OpenAI Settings
OPENAI_API_KEY=sk-...
OPENAI_AUDIO_MODEL=gpt-4o-mini-audio-preview
OPENAI_MAX_TOKENS=3500
OPENAI_TTS_VOICE=alloy
OPENAI_AUDIO_FORMAT=wav

# Stripe Settings
STRIPE_SECRET_KEY=sk_live_...
STRIPE_SUCCESS_URL=https://yourapp.com/cms/mycards
STRIPE_CANCEL_URL=https://yourapp.com/cms/mycards
```

---

## 🎯 **Environment Variable Best Practices**

### **1. Never Commit Secrets to Git**

❌ **Bad:**
```toml
[edge_runtime.secrets]
OPENAI_API_KEY = "sk-proj-1234567890"  # NEVER do this!
```

✅ **Good:**
```toml
[edge_runtime.secrets]
OPENAI_API_KEY = "env(OPENAI_API_KEY)"  # Load from system environment
```

Or use a `.env.local` file (add to `.gitignore`):
```bash
# .env.local (not committed to git)
OPENAI_API_KEY=sk-proj-...
```

### **2. Use Different Values for Dev vs Prod**

```toml
# Local Development - Test keys, lower limits
[edge_runtime.secrets]
OPENAI_API_KEY = "sk-test-..."
OPENAI_MAX_TOKENS = "2000"  # Lower for faster testing
```

```bash
# Production - Live keys, full limits
OPENAI_API_KEY=sk-live-...
OPENAI_MAX_TOKENS=3500  # Full production capacity
```

### **3. Validate Environment Variables**

In your Edge Function:

```typescript
// Check required environment variables
const openaiApiKey = Deno.env.get('OPENAI_API_KEY')
if (!openaiApiKey) {
  throw new Error('OPENAI_API_KEY not configured')
}

// Provide defaults for optional variables
const model = Deno.env.get('OPENAI_AUDIO_MODEL') || 'gpt-4o-mini-audio-preview'
const maxTokens = parseInt(Deno.env.get('OPENAI_MAX_TOKENS') || '3500')
```

---

## 🔄 **Updating Configuration**

### **Local Development**

1. Edit `supabase/config.toml`
2. Restart Supabase:
   ```bash
   supabase stop
   supabase start
   ```

### **Production**

#### **Option 1: Supabase Dashboard**
- Update secrets in dashboard
- Changes apply immediately
- No redeployment needed

#### **Option 2: CLI**
```bash
# Update a secret
supabase secrets set OPENAI_AUDIO_MODEL=gpt-4o-audio-preview

# Changes apply immediately
```

---

## 📊 **All Available Configuration Variables**

### **OpenAI Settings**

| Variable | Default | Description |
|----------|---------|-------------|
| `OPENAI_API_KEY` | (required) | Your OpenAI API key |
| `OPENAI_AUDIO_MODEL` | `gpt-4o-mini-audio-preview` | AI model to use |
| `OPENAI_MAX_TOKENS` | `3500` | Maximum response length |
| `OPENAI_TTS_VOICE` | `alloy` | Voice for audio output |
| `OPENAI_AUDIO_FORMAT` | `wav` | Audio format (wav/mp3) |

### **Voice Options**

- `alloy` - Neutral, balanced
- `echo` - Clear, professional
- `fable` - Warm, storytelling
- `onyx` - Deep, authoritative
- `nova` - Energetic, young
- `shimmer` - Soft, calming

### **Stripe Settings**

| Variable | Environment | Description |
|----------|-------------|-------------|
| `STRIPE_SECRET_KEY` | Both | Stripe API secret key |
| `STRIPE_PUBLISHABLE_KEY` | Both | Stripe publishable key |
| `STRIPE_SUCCESS_URL` | Both | Redirect after success |
| `STRIPE_CANCEL_URL` | Both | Redirect after cancel |

---

## 🧪 **Testing Configuration**

### **1. Check Local Configuration**

```bash
# Start Supabase locally
supabase start

# Test your Edge Function
curl -i --location --request POST 'http://127.0.0.1:54321/functions/v1/chat-with-audio' \
  --header 'Authorization: Bearer YOUR_ANON_KEY' \
  --header 'Content-Type: application/json' \
  --data '{"messages":[],"systemPrompt":"Test","language":"en"}'
```

### **2. Check Production Configuration**

```bash
# List secrets (names only)
supabase secrets list

# Test deployed function
curl -i --location --request POST 'https://YOUR_PROJECT.supabase.co/functions/v1/chat-with-audio' \
  --header 'Authorization: Bearer YOUR_ANON_KEY' \
  --header 'Content-Type: application/json' \
  --data '{"messages":[],"systemPrompt":"Test","language":"en"}'
```

---

## 🐛 **Troubleshooting**

### **"Environment variable not found"**

**Problem:** Edge Function can't find `OPENAI_API_KEY`

**Solution:**
1. Check `supabase/config.toml` for local dev
2. Check Supabase Dashboard → Secrets for production
3. Restart local Supabase: `supabase stop && supabase start`

### **"Invalid API key"**

**Problem:** API key is wrong or expired

**Solution:**
1. Get new key from [OpenAI Platform](https://platform.openai.com/api-keys)
2. Update in config:
   ```bash
   supabase secrets set OPENAI_API_KEY=sk-new-key-...
   ```

### **"Model not found"**

**Problem:** Model name is incorrect

**Solution:**
Use exact model name:
```bash
supabase secrets set OPENAI_AUDIO_MODEL=gpt-4o-mini-audio-preview
```

---

## 📚 **Configuration Templates**

### **Development Environment**

```toml
# supabase/config.toml
[edge_runtime.secrets]
# Cost-effective settings for development
OPENAI_API_KEY = "sk-..."
OPENAI_AUDIO_MODEL = "gpt-4o-mini-audio-preview"  # Cheaper model
OPENAI_MAX_TOKENS = "2000"  # Lower for faster testing
OPENAI_TTS_VOICE = "alloy"
OPENAI_AUDIO_FORMAT = "wav"
STRIPE_SECRET_KEY = "sk_test_..."  # Test mode
```

### **Production Environment**

```bash
# Supabase Dashboard → Secrets
OPENAI_API_KEY=sk-...
OPENAI_AUDIO_MODEL=gpt-4o-mini-audio-preview  # or gpt-4o-audio-preview for premium
OPENAI_MAX_TOKENS=3500  # Full capacity
OPENAI_TTS_VOICE=alloy
OPENAI_AUDIO_FORMAT=wav
STRIPE_SECRET_KEY=sk_live_...  # Live mode
```

---

## ✅ **Quick Setup Checklist**

### **Local Development**

- [ ] Edit `supabase/config.toml`
- [ ] Add `[edge_runtime.secrets]` section
- [ ] Add `OPENAI_API_KEY`
- [ ] Add other optional variables
- [ ] Run `supabase stop && supabase start`
- [ ] Test your Edge Function

### **Production Deployment**

- [ ] Go to Supabase Dashboard
- [ ] Navigate to Edge Functions → Secrets
- [ ] Add `OPENAI_API_KEY`
- [ ] Add `OPENAI_AUDIO_MODEL` (or use default)
- [ ] Add `OPENAI_MAX_TOKENS` (or use default)
- [ ] Add other optional variables
- [ ] Deploy Edge Function: `npx supabase functions deploy chat-with-audio`
- [ ] Test production function

---

## 🎯 **Summary**

**Three configuration locations:**

1. **`supabase/functions/deno.json`** - Deno compiler settings ✅ Already configured
2. **`supabase/config.toml`** - Local development secrets ✅ Configure here
3. **Supabase Dashboard Secrets** - Production secrets ✅ Configure online

**Most important variables:**
- `OPENAI_API_KEY` (required)
- `OPENAI_AUDIO_MODEL` (defaults to `gpt-4o-mini-audio-preview`)
- `OPENAI_MAX_TOKENS` (defaults to `3500`)

**Configuration is complete and working!** 🚀

