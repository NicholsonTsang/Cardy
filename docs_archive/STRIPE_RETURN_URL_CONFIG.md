# Stripe Return URL Configuration

## Overview
This document explains how to configure Stripe payment return URLs using environment variables for both development and production environments.

## Required Environment Variables

These environment variables need to be configured in **Supabase** for Edge Functions (not in your `.env` file).

### For Local Development
Add to `supabase/config.toml`:
```toml
[edge_runtime.secrets]
STRIPE_SUCCESS_URL = "http://localhost:5173/cms/mycards"
STRIPE_CANCEL_URL = "http://localhost:5173/cms/mycards"
```

### For Production (Supabase Dashboard)
Add these via Supabase Dashboard → Project Settings → Edge Functions → Environment Variables:
```
STRIPE_SUCCESS_URL = https://cardstudio.org/cms/mycards
STRIPE_CANCEL_URL = https://cardstudio.org/cms/mycards
```

## How It Works

### 1. Environment Variables in Edge Function
The `create-checkout-session` Edge Function uses these environment variables to set the Stripe checkout session return URLs:

```typescript
const successBaseUrl = Deno.env.get('STRIPE_SUCCESS_URL') || req.headers.get('origin') || 'http://localhost:5173'
const cancelBaseUrl = Deno.env.get('STRIPE_CANCEL_URL') || req.headers.get('origin') || 'http://localhost:5173'
```

### 2. Fallback Behavior
The system has a three-tier fallback:
1. **Environment variable** (preferred) - Uses `STRIPE_SUCCESS_URL` / `STRIPE_CANCEL_URL`
2. **Origin header** - Falls back to the request's origin header
3. **Localhost** - Final fallback to `http://localhost:5173`

### 3. URL Parameters
The return URLs automatically include query parameters:

**Success URL:**
```
{STRIPE_SUCCESS_URL}?session_id={CHECKOUT_SESSION_ID}&batch_id={batchId}
```

**Cancel URL:**
```
{STRIPE_CANCEL_URL}?canceled=true&batch_id={batchId}
```

## Setup Instructions

### Step 1: Configure Local Development Environment
1. Open `supabase/config.toml`
2. Add or update the `[edge_runtime.secrets]` section:
   ```toml
   [edge_runtime.secrets]
   STRIPE_SUCCESS_URL = "http://localhost:5173/cms/mycards"
   STRIPE_CANCEL_URL = "http://localhost:5173/cms/mycards"
   ```
3. Restart your local Supabase instance:
   ```bash
   npx supabase stop
   npx supabase start
   ```

### Step 2: Configure Production Environment
1. Go to [Supabase Dashboard](https://supabase.com/dashboard)
2. Select your project
3. Navigate to: **Project Settings** → **Edge Functions** → **Environment Variables**
4. Add two new environment variables:
   - **Name:** `STRIPE_SUCCESS_URL`  
     **Value:** `https://cardstudio.org/cms/mycards`
   - **Name:** `STRIPE_CANCEL_URL`  
     **Value:** `https://cardstudio.org/cms/mycards`
5. Click **Save**

### Step 3: Verify Edge Function is Deployed
The Edge Function has already been deployed (version 19). To redeploy if needed:
```bash
npx supabase functions deploy create-checkout-session
```

### Step 4: Test the Payment Flow
1. Create a new batch and initiate payment
2. Verify you're redirected to Stripe checkout
3. Complete or cancel payment
4. Confirm you're redirected back to the correct URL

## Benefits

✅ **Environment-specific URLs** - Different URLs for dev/prod
✅ **Easy configuration** - Single place to manage return URLs
✅ **Flexible deployment** - Works across different hosting environments
✅ **Secure** - No hardcoded URLs in source code
✅ **Backwards compatible** - Fallback to origin header if env vars not set

## Troubleshooting

### Issue: Redirected to wrong URL after payment
**Solution:** Check that environment variables are set correctly in Supabase project settings

### Issue: Getting localhost URL in production
**Solution:** Ensure `STRIPE_SUCCESS_URL` and `STRIPE_CANCEL_URL` are set in your production environment

### Issue: Environment variables not working
**Solution:** 
1. Verify variables are set in Supabase Dashboard → Project Settings → Edge Functions → Environment Variables
2. Redeploy the Edge Function after setting variables
3. Check that variable names match exactly (case-sensitive)

## Related Files
- `/supabase/functions/create-checkout-session/index.ts` - Edge Function implementation
- `.env` - Development environment configuration
- `.env.production` - Production environment configuration
- `/src/components/CardIssuanceCheckout.vue` - Frontend payment handling

