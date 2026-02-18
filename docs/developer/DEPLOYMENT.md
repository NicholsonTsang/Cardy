# Deployment Guide

This guide covers everything needed to deploy FunTell from scratch — prerequisites, database setup, backend (Google Cloud Run), and frontend (static hosting).

## Overview

| Component | Technology | Where it runs |
|-----------|-----------|---------------|
| **Backend API** | Express.js (Node 18) | Google Cloud Run |
| **Frontend** | Vue 3 (Vite SPA) | Vercel / Netlify / Firebase / any CDN |
| **Database** | Supabase PostgreSQL | Supabase cloud |
| **Cache** | Upstash Redis | Upstash cloud |
| **Auth** | Supabase Auth | Supabase cloud |
| **Payments** | Stripe | Stripe cloud |

---

## Prerequisites

### Accounts Required

| Service | Sign-up URL | What it provides |
|---------|------------|-----------------|
| **Supabase** | supabase.com | Database + Auth |
| **Google Cloud** | console.cloud.google.com | Cloud Run (backend hosting) + Gemini API |
| **OpenAI** | platform.openai.com | Voice TTS + Realtime API |
| **Stripe** | dashboard.stripe.com | Payments + Subscriptions |
| **Upstash** | console.upstash.com | Redis (session tracking) |

### Tools Required

```bash
# Check you have everything:
node --version   # 18+
npm --version    # 9+
gcloud --version # Google Cloud CLI
curl --version
```

Install Google Cloud CLI: https://cloud.google.com/sdk/docs/install

### Clone the Repository

```bash
git clone <repository-url>
cd Cardy
```

---

## Step 1 — Environment Variables

Run the interactive setup script to create both `.env` files:

```bash
./scripts/setup-env.sh
```

This guides you through every variable — Supabase, OpenAI, Gemini, Stripe, Redis, and all pricing tiers. See the prompts for where to find each value.

**Flag options:**

| Flag | Effect |
|------|--------|
| (none) | Interactive setup for both backend and frontend `.env` |
| `--backend` | Backend `.env` only (`backend-server/.env`) |
| `--frontend` | Frontend `.env` only (`.env`) |

> **Security:** Never commit `.env` files to git. They are listed in `.gitignore`.

### Key Variables Summary

**Backend** (`backend-server/.env`):

| Variable | Where to find |
|----------|--------------|
| `SUPABASE_URL` | Supabase Dashboard → Project Settings → API |
| `SUPABASE_SERVICE_ROLE_KEY` | Supabase Dashboard → Project Settings → API |
| `OPENAI_API_KEY` | platform.openai.com → API Keys |
| `GOOGLE_APPLICATION_CREDENTIALS` | Path to GCP service account JSON (see Step 1a) |
| `STRIPE_SECRET_KEY` | Stripe Dashboard → Developers → API Keys |
| `STRIPE_WEBHOOK_SECRET` | Stripe Dashboard → Webhooks (created in Step 4) |
| `STRIPE_STARTER_PRICE_ID` | Stripe Dashboard → Products (created in Step 1b) |
| `STRIPE_PREMIUM_PRICE_ID` | Stripe Dashboard → Products |
| `STRIPE_ENTERPRISE_PRICE_ID` | Stripe Dashboard → Products |
| `UPSTASH_REDIS_REST_URL` | Upstash Console → Redis Database |
| `UPSTASH_REDIS_REST_TOKEN` | Upstash Console → Redis Database |

**Frontend** (`.env`):

| Variable | Notes |
|----------|-------|
| `VITE_BACKEND_URL` | Cloud Run URL (available after Step 3) — update after backend deploy |
| `VITE_SUPABASE_URL` | Same Supabase project URL |
| `VITE_SUPABASE_ANON_KEY` | Supabase anon/public key (not service role) |
| `VITE_STRIPE_PUBLISHABLE_KEY` | Stripe publishable key (`pk_live_...` or `pk_test_...`) |

### Step 1a — Google Gemini Service Account

Gemini is used for AI chat and content translation.

1. Open [Google Cloud Console](https://console.cloud.google.com)
2. Create or select a project
3. Enable the **Generative Language API**: APIs & Services → Enable APIs → search "Generative Language"
4. Create a service account: IAM & Admin → Service Accounts → Create
   - Role: **Vertex AI User** (or **Generative Language API User**)
5. Download the JSON key
6. Place the file in `backend-server/` (e.g., `backend-server/gemini-service-account.json`)
7. Set `GOOGLE_APPLICATION_CREDENTIALS=gemini-service-account.json` in `backend-server/.env`

> **Cloud Run note:** The JSON file is only used locally. In Cloud Run, set up Application Default Credentials (ADC) via Workload Identity instead of uploading the JSON file. The deploy script automatically skips `GOOGLE_APPLICATION_CREDENTIALS` when building the Cloud Run environment.

### Step 1b — Stripe Products & Prices

Create three recurring subscription products in Stripe Dashboard → Products:

| Product | Price | Billing |
|---------|-------|---------|
| FunTell Starter | $40.00 | Monthly |
| FunTell Premium | $280.00 | Monthly |
| FunTell Enterprise | $1,000.00 | Monthly |

Copy the price IDs (format: `price_xxxx`) into your `backend-server/.env`.

---

## Step 2 — Database Setup

Database schema is deployed **manually** via the Supabase Dashboard SQL Editor.

Apply the SQL files **in this exact order**:

| Order | File | Purpose |
|-------|------|---------|
| 1 | `sql/schema.sql` | Tables, enums, indexes |
| 2 | `sql/triggers.sql` | Automatic triggers |
| 3 | `sql/policy.sql` | Row-Level Security policies |
| 4 | `sql/storage_policies.sql` | Storage bucket policies |
| 5 | `sql/all_stored_procedures.sql` | All stored procedures (generated) |

### How to Apply

1. Open [Supabase Dashboard](https://supabase.com/dashboard)
2. Select your project
3. Go to **SQL Editor** (left sidebar)
4. For each file: open it, copy the contents, paste into SQL Editor, click **Run**

### Supabase Auth Setup

After applying the schema:

1. Go to **Authentication → URL Configuration**
2. Set **Site URL** to your frontend domain (e.g., `https://funtell.ai`)
3. Add redirect URLs for local development: `http://localhost:5173`

### Storage Buckets

The schema creates required storage buckets. Verify in Supabase Dashboard → Storage:
- `userfiles` — user-uploaded files

---

## Step 3 — Backend Deployment (Google Cloud Run)

```bash
./scripts/deploy-cloud-run.sh
```

The script will prompt for:
- **GCP Project ID** — from Google Cloud Console
- **Region** — e.g., `us-central1`, `asia-east1`
- **CORS origins** — your frontend domain(s), e.g., `https://funtell.ai`

It will then:
1. Enable required GCP APIs (`Cloud Run`, `Container Registry`, `Cloud Build`)
2. Build a Docker container image via Cloud Build
3. Deploy to Cloud Run (512Mi RAM, 0–10 instances, port 8080)
4. Run a health check at `/health`
5. Print the service URL

**After deployment**, copy the service URL and update your frontend `.env`:
```bash
VITE_BACKEND_URL=https://funtell-backend-xxxx.a.run.app
```

### Cloud Run Configuration

| Setting | Value |
|---------|-------|
| Service name | `funtell-backend` |
| Port | `8080` |
| Memory | `512Mi` |
| CPU | `1` |
| Min instances | `0` (scales to zero) |
| Max instances | `10` |
| Timeout | `300s` |

### Google Gemini in Cloud Run

Cloud Run uses **Application Default Credentials (ADC)** — no JSON key file needed. Grant the Cloud Run service account the **Generative Language API User** role:

```bash
gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
  --member="serviceAccount:YOUR_COMPUTE_SA@developer.gserviceaccount.com" \
  --role="roles/aiplatform.user"
```

### Useful Commands

```bash
# View real-time logs
gcloud run services logs tail funtell-backend --region us-central1

# Redeploy after code changes
./scripts/deploy-cloud-run.sh

# View in Cloud Console
https://console.cloud.google.com/run
```

---

## Step 4 — Stripe Webhook

Register the backend webhook so Stripe events reach your server.

1. Open [Stripe Dashboard → Webhooks](https://dashboard.stripe.com/webhooks)
2. Click **Add endpoint**
3. **Endpoint URL:** `https://<your-cloud-run-url>/api/webhooks/stripe`
4. **Events to listen for:**
   - `checkout.session.completed`
   - `customer.subscription.updated`
   - `customer.subscription.deleted`
   - `invoice.paid`
   - `invoice.payment_failed`
5. Copy the **Signing secret** (`whsec_...`) and set it as `STRIPE_WEBHOOK_SECRET` in `backend-server/.env`
6. Redeploy the backend so it picks up the new secret: `./scripts/deploy-cloud-run.sh`

### Local Webhook Testing

```bash
# Install Stripe CLI: https://stripe.com/docs/stripe-cli
stripe listen --forward-to localhost:8080/api/webhooks/stripe

# Trigger test events
stripe trigger checkout.session.completed
stripe trigger customer.subscription.updated
stripe trigger invoice.paid
```

---

## Step 5 — Frontend Deployment

Build the frontend:

```bash
npm run build
```

The output is in `dist/`. Deploy to any static host:

### Vercel (Recommended)

```bash
npm i -g vercel
vercel --prod
```

Or connect your Git repository to Vercel for automatic deployments.

**Vercel environment variables:** Add all `VITE_*` variables from `.env` in the Vercel project settings.

### Netlify

```bash
npm i -g netlify-cli
netlify deploy --prod --dir dist
```

Add `VITE_*` variables in Netlify → Site Settings → Environment Variables.

### Firebase Hosting

```bash
npm i -g firebase-tools
firebase login
firebase init hosting    # Set public dir to: dist
firebase deploy --only hosting
```

### SPA Routing

All static hosts need to serve `index.html` for all routes (Vue Router uses HTML5 history mode):

**Netlify** — create `public/_redirects`:
```
/*  /index.html  200
```

**Vercel** — create `vercel.json`:
```json
{
  "rewrites": [{ "source": "/(.*)", "destination": "/index.html" }]
}
```

**Firebase** — add to `firebase.json`:
```json
{
  "hosting": {
    "rewrites": [{ "source": "**", "destination": "/index.html" }]
  }
}
```

---

## All-in-One Script

For a guided end-to-end deployment:

```bash
./scripts/deploy.sh
```

This script:
1. Runs all pre-flight checks (tools, `.env` files, required keys)
2. Reminds you to apply database SQL
3. Calls `deploy-cloud-run.sh` for the backend
4. Builds the frontend
5. Runs a health check
6. Prints the post-deploy checklist

**Flag options:**

| Flag | Effect |
|------|--------|
| (none) | Full deployment (backend + frontend) |
| `--backend` | Backend only |
| `--frontend` | Frontend build only |
| `--check` | Pre-flight checks only, no deployment |

---

## Post-Deploy Verification

### Health Check

```bash
curl https://<your-cloud-run-url>/health
# Expected: {"status":"healthy",...}
```

### Functional Smoke Tests

1. **Auth** — Open the frontend, sign up, verify email arrives
2. **Project creation** — Create a project, add content
3. **QR code** — Scan from a mobile device, verify content loads
4. **AI chat** — Test the AI assistant on the mobile client
5. **Payments** — Use a Stripe test card (`4242 4242 4242 4242`) to test checkout

### Stripe Test Cards

| Card Number | Behavior |
|-------------|----------|
| `4242 4242 4242 4242` | Successful payment |
| `4000 0000 0000 0341` | Attaches but fails on charge |
| `4000 0000 0000 9995` | Insufficient funds |

---

## Updating After Code Changes

### Backend Update

```bash
./scripts/deploy-cloud-run.sh
```

### Frontend Update

```bash
npm run build
# Re-upload dist/ to your static host (or push to Git for auto-deploy)
```

### Stored Procedure Update

1. Edit files in `sql/storeproc/`
2. Regenerate: `./scripts/combine-storeproc.sh`
3. Apply in Supabase Dashboard SQL Editor

---

## Troubleshooting

### Backend won't start

```bash
# Check logs
gcloud run services logs tail funtell-backend --region us-central1
```

Common causes:
- Missing env var (check the required keys list above)
- Bad Supabase connection (verify `SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY`)
- Redis connection error (verify Upstash credentials)

### Health check fails

The service may still be starting — wait 30 seconds and retry:
```bash
curl https://<url>/health
```

### CORS errors in browser

Update `ALLOWED_ORIGINS` in `backend-server/.env` to include your frontend domain:
```
ALLOWED_ORIGINS=https://funtell.ai,https://www.funtell.ai
```
Then redeploy: `./scripts/deploy-cloud-run.sh`

### Stripe webhooks not firing

- Verify the endpoint URL is correct in Stripe Dashboard
- Check `STRIPE_WEBHOOK_SECRET` matches the signing secret in Stripe
- Test locally: `stripe listen --forward-to localhost:8080/api/webhooks/stripe`
- View webhook delivery attempts in Stripe Dashboard → Webhooks → your endpoint

### Gemini / AI not working

- Verify `GOOGLE_APPLICATION_CREDENTIALS` points to a valid JSON file (local) or ADC is configured (Cloud Run)
- Check the Generative Language API is enabled in Google Cloud Console
- Verify the service account has the required IAM role

### Supabase stored procedure errors

- Check parameter names match exactly (prefix `p_`)
- Verify the procedure was deployed (SQL Editor → browse functions)
- Check RLS policies if getting permission errors

---

## Development Environment

For local development (no Cloud Run):

```bash
# Set up .env files
./scripts/setup-env.sh
# Answer "n" to "Is this a production deployment?"

# Start backend (Terminal 1)
cd backend-server && npm run dev

# Start frontend (Terminal 2)
npm run dev
```

Frontend: `http://localhost:5173`
Backend: `http://localhost:8080`

See [Development Workflow](DEVELOPMENT_WORKFLOW.md) for more details.
