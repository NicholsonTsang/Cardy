# Environment Variables Configuration Guide

## Understanding the Two Environments

Your application has **TWO separate runtime environments** that require different configuration approaches:

```
┌─────────────────────────────────────┐
│  FRONTEND (Vue + Vite)              │
│  Runtime: Browser                   │
│  Config File: .env                  │
│  Prefix Required: VITE_*            │
└─────────────────────────────────────┘
              ↓ calls
┌─────────────────────────────────────┐
│  EDGE FUNCTIONS (Deno)              │
│  Runtime: Supabase Servers          │
│  Config: config.toml / Dashboard    │
│  Prefix: None required              │
└─────────────────────────────────────┘
```

## Frontend Environment Variables (.env file)

### Location
- Development: `.env`
- Production: `.env.production`

### Rules
✅ **Must have `VITE_` prefix** to be accessible
✅ Available in browser via `import.meta.env.VITE_*`
❌ **Cannot** be accessed by Edge Functions

### Current Frontend Variables

```bash
# Supabase Connection
VITE_SUPABASE_URL=https://mzgusshseqxrdrkvamrg.supabase.co
VITE_SUPABASE_ANON_KEY=eyJhbGci...
VITE_SUPABASE_USER_FILES_BUCKET=userfiles

# Stripe (Frontend)
VITE_STRIPE_PUBLISHABLE_KEY=pk_test_...

# Application URLs
VITE_DEFAULT_CARD_IMAGE_URL=https://images.unsplash.com/...
VITE_APP_BASE_URL=https://cardstudio.org/cms
VITE_SAMPLE_QR_URL=https://cardstudio.org/c/...

# Business Configuration
VITE_CARD_PRICE_CENTS=200
VITE_DEFAULT_CURRENCY=USD
VITE_CONTACT_EMAIL=support@cardy.com
VITE_CONTACT_WHATSAPP_URL=https://wa.me/1234567890
VITE_CONTACT_PHONE=+852 55992159

# OpenAI (Frontend)
VITE_OPENAI_MODEL=gpt-4o-realtime-preview-2025-06-03

# Card Aspect Ratios
VITE_CARD_ASPECT_RATIO_WIDTH=2
VITE_CARD_ASPECT_RATIO_HEIGHT=3
VITE_CONTENT_ASPECT_RATIO_WIDTH=4
VITE_CONTENT_ASPECT_RATIO_HEIGHT=3
```

## Edge Function Environment Variables

### Location
- **Local Development:** `supabase/config.toml` under `[edge_runtime.secrets]`
- **Production:** Supabase Dashboard → Project Settings → Edge Functions → Environment Variables

### Rules
✅ Available to Edge Functions via `Deno.env.get('VARIABLE_NAME')`
✅ **No prefix required**
❌ **Cannot** be accessed by frontend
❌ **Not** read from `.env` file

### Current Edge Function Variables

#### Local (supabase/config.toml)
```toml
[edge_runtime.secrets]
STRIPE_SUCCESS_URL = "http://localhost:5173/cms/mycards"
STRIPE_CANCEL_URL = "http://localhost:5173/cms/mycards"
```

#### Production (Supabase Dashboard) - ⚠️ NEEDS SETUP
```
STRIPE_SUCCESS_URL = https://cardstudio.org/cms/mycards
STRIPE_CANCEL_URL = https://cardstudio.org/cms/mycards
STRIPE_SECRET_KEY = sk_live_...  (if not already set)
OPENAI_API_KEY = sk-...  (if not already set)
```

## Variables That Exist in BOTH Environments

Some variables need to be configured in **both places** because they're used by both frontend and backend:

| Variable | Frontend (.env) | Edge Function | Why Both? |
|----------|----------------|---------------|-----------|
| Stripe Key | `VITE_STRIPE_PUBLISHABLE_KEY` | `STRIPE_SECRET_KEY` | Frontend: payment UI<br>Backend: API calls |
| OpenAI | `VITE_OPENAI_MODEL` | `OPENAI_API_KEY` | Frontend: displays model<br>Backend: API calls |

## Common Mistakes ❌

### ❌ WRONG: Adding Edge Function vars to .env
```bash
# These WON'T WORK in .env - Edge Functions can't read it!
STRIPE_SUCCESS_URL=http://localhost:5173/cms/mycards
STRIPE_CANCEL_URL=http://localhost:5173/cms/mycards
```

### ✅ CORRECT: Add to config.toml
```toml
[edge_runtime.secrets]
STRIPE_SUCCESS_URL = "http://localhost:5173/cms/mycards"
STRIPE_CANCEL_URL = "http://localhost:5173/cms/mycards"
```

### ❌ WRONG: Using frontend var without VITE_ prefix
```bash
# This won't be available in browser!
APP_BASE_URL=https://cardstudio.org
```

### ✅ CORRECT: Use VITE_ prefix
```bash
VITE_APP_BASE_URL=https://cardstudio.org
```

## How to Add New Variables

### For Frontend (Browser)
1. Add to `.env` with `VITE_` prefix
2. Add to `.env.production` with same value (or different for prod)
3. Access in code: `import.meta.env.VITE_YOUR_VAR`
4. Restart dev server for changes to take effect

### For Edge Functions (Backend)
1. **Local:** Add to `supabase/config.toml` under `[edge_runtime.secrets]`
2. **Production:** Add via Supabase Dashboard
3. Access in code: `Deno.env.get('YOUR_VAR')`
4. Redeploy Edge Function if already deployed

## Current Configuration Status

| Component | Configuration File | Status |
|-----------|-------------------|--------|
| Frontend Local | `.env` | ✅ Complete |
| Frontend Production | `.env.production` | ✅ Complete |
| Edge Functions Local | `supabase/config.toml` | ✅ Complete |
| Edge Functions Production | Supabase Dashboard | ⚠️ **Needs Setup** |

## Next Steps

### Required: Setup Production Edge Function Variables

1. Go to: https://supabase.com/dashboard
2. Select your project
3. Navigate: **Project Settings** → **Edge Functions** → **Environment Variables**
4. Add these variables:
   - `STRIPE_SUCCESS_URL` = `https://cardstudio.org/cms/mycards`
   - `STRIPE_CANCEL_URL` = `https://cardstudio.org/cms/mycards`
   - Verify `STRIPE_SECRET_KEY` is set (for production payments)
   - Verify `OPENAI_API_KEY` is set (for AI features)

## Testing Your Configuration

### Frontend Variables
```bash
# Start dev server
npm run dev

# Check in browser console
console.log(import.meta.env.VITE_APP_BASE_URL)
// Should output: https://cardstudio.org/cms
```

### Edge Function Variables
```bash
# Test locally
npx supabase start
npx supabase functions serve

# Check logs for variable access
# Variables from config.toml should be available
```

## Troubleshooting

### Frontend variable is undefined
- ✅ Check it has `VITE_` prefix
- ✅ Restart dev server (`npm run dev`)
- ✅ Check variable exists in `.env`

### Edge Function variable is undefined
- ✅ Check it's in `config.toml` for local
- ✅ Check it's in Supabase Dashboard for production
- ✅ Redeploy Edge Function
- ✅ Check variable name matches exactly (case-sensitive)

## Related Documentation
- Vite Environment Variables: https://vitejs.dev/guide/env-and-mode.html
- Supabase Edge Functions Secrets: https://supabase.com/docs/guides/functions/secrets

