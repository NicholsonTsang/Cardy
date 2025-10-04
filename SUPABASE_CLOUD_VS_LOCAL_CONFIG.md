# Supabase Cloud vs Local Configuration Guide

## 🎯 Overview

The `supabase/config.toml` file contains configurations for **LOCAL DEVELOPMENT ONLY**. When using **Supabase Cloud**, most of these settings are ignored or managed through the Supabase Dashboard.

---

## 📊 Configuration Applicability Matrix

### **For Supabase Cloud** (What You're Using)

| Section | Applicable? | How to Configure |
|---------|------------|------------------|
| **`[edge_runtime.secrets]`** | ❌ **NO** | Use Supabase Dashboard → Edge Functions → Secrets |
| `[api]` | ❌ No | Managed by Supabase Cloud |
| `[db]` | ❌ No | Managed by Supabase Cloud |
| `[realtime]` | ❌ No | Managed by Supabase Cloud |
| `[studio]` | ❌ No | Managed by Supabase Cloud |
| `[inbucket]` | ❌ No | Not available in Cloud |
| `[storage]` | ❌ No | Configure in Dashboard → Storage |
| `[auth]` | ❌ No | Configure in Dashboard → Authentication |
| `[analytics]` | ❌ No | Managed by Supabase Cloud |

### **For Local Development** (Using `supabase start`)

| Section | Applicable? | Purpose |
|---------|------------|---------|
| **`[edge_runtime.secrets]`** | ✅ **YES** | Local Edge Function secrets |
| `[api]` | ✅ Yes | Local API server configuration |
| `[db]` | ✅ Yes | Local PostgreSQL database |
| `[realtime]` | ✅ Yes | Local Realtime server |
| `[studio]` | ✅ Yes | Local Supabase Studio |
| `[inbucket]` | ✅ Yes | Local email testing |
| `[storage]` | ✅ Yes | Local file storage |
| `[auth]` | ✅ Yes | Local authentication |
| `[analytics]` | ✅ Yes | Local analytics |

---

## 🚨 **IMPORTANT: For Supabase Cloud**

### **✅ What You SHOULD Do**

**1. Configure Edge Function Secrets via Dashboard or CLI**

**Via Supabase Dashboard:**
1. Go to [Supabase Dashboard](https://supabase.com/dashboard)
2. Select your project
3. Navigate to **Edge Functions** → **Secrets**
4. Click **Add Secret**
5. Add:
   - `STRIPE_SECRET_KEY`
   - `OPENAI_API_KEY`
   - Other optional secrets

**Via Supabase CLI (Recommended):**
```bash
# Set secrets for your cloud project
supabase secrets set STRIPE_SECRET_KEY=sk_live_...
supabase secrets set OPENAI_API_KEY=sk-d6xbooVgVWS0uIv3Cf6090465bE24c979bF5Dd596f7c7a04

# Optional secrets
supabase secrets set OPENAI_AUDIO_MODEL=gpt-4o-mini-audio-preview
supabase secrets set OPENAI_MAX_TOKENS=3500
supabase secrets set OPENAI_TTS_VOICE=alloy
supabase secrets set OPENAI_AUDIO_FORMAT=wav

# Verify secrets are set
supabase secrets list
```

**Or use the interactive script:**
```bash
./scripts/setup-production-secrets.sh
```

---

### **❌ What You Should NOT Do**

**DON'T rely on `[edge_runtime.secrets]` in `config.toml` for Supabase Cloud!**

❌ **This section is ONLY for local development:**
```toml
[edge_runtime.secrets]
STRIPE_SECRET_KEY = "sk_test_..."
OPENAI_API_KEY = "sk-d6xboo..."
```

**Why?**
- `config.toml` is NOT deployed to Supabase Cloud
- Secrets in `config.toml` are ONLY used by `supabase start` (local Docker containers)
- Cloud environment reads secrets from Supabase Dashboard/CLI configuration

---

## 🔄 **Complete Configuration Workflow**

### **Scenario 1: Supabase Cloud Only** (Your Current Situation)

**What to configure:**
1. ✅ **Edge Function Secrets** → Supabase Dashboard or CLI
2. ✅ **Frontend Environment Variables** → `.env.production`
3. ✅ **Database** → Supabase Dashboard SQL Editor
4. ✅ **Storage Buckets** → Supabase Dashboard Storage
5. ✅ **Auth Settings** → Supabase Dashboard Authentication

**What to ignore:**
- ❌ `config.toml` (except for reference or if you plan to test locally later)

**Commands:**
```bash
# Configure cloud secrets
supabase secrets set STRIPE_SECRET_KEY=sk_live_...
supabase secrets set OPENAI_API_KEY=sk-...

# Deploy Edge Functions
./scripts/deploy-edge-functions.sh

# Deploy database changes
# (Copy schema.sql and all_stored_procedures.sql to Dashboard SQL Editor)
```

---

### **Scenario 2: Local Development + Cloud Deployment**

**Local Development:**
1. ✅ Configure `config.toml` → `[edge_runtime.secrets]`
2. ✅ Configure `.env.local` → Frontend variables
3. ✅ Run `supabase start` → Starts local Supabase
4. ✅ Test locally with `npm run dev`

**Cloud Deployment:**
1. ✅ Configure Supabase Dashboard → Edge Function Secrets
2. ✅ Configure `.env.production` → Frontend variables
3. ✅ Deploy Edge Functions → `./scripts/deploy-edge-functions.sh`
4. ✅ Deploy database → Dashboard SQL Editor
5. ✅ Build frontend → `npm run build:production`

---

## 📋 **Recommended Configuration Strategy**

### **For Your Current Setup (Cloud Only)**

**Step 1: Set Cloud Secrets**
```bash
# Option A: Use interactive script
./scripts/setup-production-secrets.sh

# Option B: Manual CLI
supabase secrets set STRIPE_SECRET_KEY=sk_live_...
supabase secrets set OPENAI_API_KEY=sk-d6xboo...
```

**Step 2: Deploy Edge Functions**
```bash
./scripts/deploy-edge-functions.sh
```

**Step 3: Configure Frontend**
Update `.env.production`:
```bash
VITE_STRIPE_PUBLISHABLE_KEY=pk_live_...
VITE_STRIPE_SUCCESS_URL=https://your-production-url.com/cms/mycards
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=your-anon-key
```

**Step 4: You're Done!**
- `config.toml` is NOT used by Supabase Cloud
- Keep it for reference or future local development

---

### **If You Want to Test Locally (Optional)**

**Only if you want to run `supabase start` for local testing:**

**Step 1: Configure `config.toml`**
```toml
[edge_runtime.secrets]
# Use TEST keys for local development
STRIPE_SECRET_KEY = "sk_test_..."
OPENAI_API_KEY = "sk-..."  # Your API key
OPENAI_AUDIO_MODEL = "gpt-4o-mini-audio-preview"
OPENAI_MAX_TOKENS = "2000"
```

**Step 2: Start Local Supabase**
```bash
supabase start
```

**Step 3: Test Locally**
```bash
npm run dev
```

---

## 🔐 **Security Considerations**

### **⚠️ IMPORTANT: API Keys in config.toml**

**Your current `config.toml` contains:**
```toml
OPENAI_API_KEY = "sk-d6xbooVgVWS0uIv3Cf6090465bE24c979bF5Dd596f7c7a04"
```

**Security Concerns:**
1. ✅ **Good News:** This file is typically `.gitignore`'d, so it won't be committed
2. ⚠️ **Be Careful:** Make sure `config.toml` is NOT committed to Git
3. 🔒 **Best Practice:** Use environment variables instead

**Verify `.gitignore`:**
```bash
# Check if config.toml is ignored
git check-ignore supabase/config.toml

# If NOT ignored, add it
echo "supabase/config.toml" >> .gitignore
```

**Better Approach:**
```toml
[edge_runtime.secrets]
# Reference environment variables instead of hardcoding
OPENAI_API_KEY = "env(OPENAI_API_KEY)"
STRIPE_SECRET_KEY = "env(STRIPE_SECRET_KEY)"
```

Then set in your shell:
```bash
export OPENAI_API_KEY="sk-d6xboo..."
export STRIPE_SECRET_KEY="sk_test_..."
```

---

## 📖 **Configuration Reference**

### **What config.toml Controls (Local Only)**

| Setting | Local | Cloud | Notes |
|---------|-------|-------|-------|
| API Port | ✅ | ❌ | Cloud uses its own ports |
| DB Port | ✅ | ❌ | Cloud manages database |
| Storage Limits | ✅ | ❌ | Cloud: Configure in Dashboard |
| Auth Settings | ✅ | ❌ | Cloud: Configure in Dashboard |
| Email Testing | ✅ | ❌ | Cloud: Uses real email providers |
| Edge Function Secrets | ✅ | ❌ | Cloud: Use Dashboard/CLI |

### **What You Configure in Supabase Dashboard (Cloud)**

**Project Settings:**
- Database (connection strings, pooling)
- API (URL, keys)
- Authentication (providers, templates)
- Storage (buckets, policies)
- Edge Functions (deployments, logs)

**Secrets (for Edge Functions):**
- Navigate to: **Edge Functions** → **Secrets**
- Add all required secrets
- Secrets are encrypted and secure

---

## 🎯 **Quick Decision Tree**

**Are you using Supabase Cloud (not local)?**
- ✅ **YES** → Ignore most of `config.toml`, use Dashboard/CLI for secrets
- ❌ **NO** → Use `config.toml` for local development

**Do you want to test locally?**
- ✅ **YES** → Configure `config.toml` with test keys
- ❌ **NO** → You can leave `config.toml` as-is (it won't affect cloud)

**Where are your Edge Functions deployed?**
- ☁️ **Cloud** → Use `supabase secrets set` or Dashboard
- 🏠 **Local** → Use `config.toml` → `[edge_runtime.secrets]`

---

## ✅ **Summary for Your Situation**

**Since you're using Supabase Cloud:**

### **DO THIS:**
```bash
# 1. Set cloud secrets via CLI
supabase secrets set STRIPE_SECRET_KEY=sk_live_...
supabase secrets set OPENAI_API_KEY=sk-d6xboo...

# 2. Deploy Edge Functions
./scripts/deploy-edge-functions.sh

# 3. Verify
supabase secrets list
```

### **DON'T WORRY ABOUT:**
- ❌ Most settings in `config.toml` (they're for local development only)
- ❌ Ports, database settings, API settings in `config.toml`
- ❌ The `[edge_runtime.secrets]` section in `config.toml` for cloud deployment

### **KEEP config.toml FOR:**
- 📚 Reference documentation
- 🔧 Future local development (if needed)
- 📋 Team onboarding (shows what secrets are needed)

---

## 📚 **Related Documentation**

- `EDGE_FUNCTIONS_CONFIG.md` - Complete Edge Functions reference (cloud & local)
- `CONFIGURATION_CENTRALIZATION.md` - Configuration overview
- `CLAUDE.md` - Main project documentation
- [Supabase CLI Reference](https://supabase.com/docs/reference/cli)
- [Supabase Local Development](https://supabase.com/docs/guides/local-development)

---

## 🎉 **Final Answer**

**Q: Are the config in config.toml applicable for Supabase Cloud?**

**A: NO, most settings in `config.toml` are for LOCAL DEVELOPMENT ONLY.**

**For Supabase Cloud, you should:**
1. Use **Supabase Dashboard** or **CLI** to configure secrets
2. Configure **Edge Function secrets** via `supabase secrets set`
3. Use **`.env.production`** for frontend environment variables
4. Keep `config.toml` for reference or future local testing

**The `config.toml` file is designed for `supabase start` (local Docker containers), not for Supabase Cloud deployment!**

