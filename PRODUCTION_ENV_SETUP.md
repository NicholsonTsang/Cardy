# Production Environment Setup - Required Actions

## ⚠️ Action Required: Add Environment Variables to Supabase

The Stripe return URL environment variables need to be added to your **Production Supabase Project** via the Dashboard.

### Step-by-Step Instructions

#### 1. Access Supabase Dashboard
1. Go to: https://supabase.com/dashboard
2. Login with your account
3. Select project: **nicholsontsang1024@gmail.com's Project** (ID: `mzgusshseqxrdrkvamrg`)

#### 2. Navigate to Edge Function Settings
1. Click on **Project Settings** (gear icon in sidebar)
2. Select **Edge Functions** from the left menu
3. Scroll down to **Environment Variables** section

#### 3. Add the Following Environment Variables

Click **Add new variable** and enter each of these:

**Variable 1:**
- **Name:** `STRIPE_SUCCESS_URL`
- **Value:** `https://cardstudio.org/cms/mycards`
- **Description:** URL to redirect after successful Stripe payment

**Variable 2:**
- **Name:** `STRIPE_CANCEL_URL`
- **Value:** `https://cardstudio.org/cms/mycards`
- **Description:** URL to redirect if Stripe payment is canceled

#### 4. Save Changes
1. Click **Save** or **Apply** button
2. Wait for confirmation message

#### 5. Verify (Optional)
The Edge Function `create-checkout-session` (version 19) is already deployed and will automatically use these variables once they're set.

## What This Does

### Before (Current Behavior)
- Uses `req.headers.get('origin')` to determine return URL
- Might redirect to wrong URL depending on request origin
- Not configurable per environment

### After (New Behavior)
- Uses configured `STRIPE_SUCCESS_URL` and `STRIPE_CANCEL_URL`
- Consistent redirects regardless of request origin
- Different URLs for dev/staging/production

## Local Development

✅ **Already Configured** - Local environment variables are set in `supabase/config.toml`:
```toml
[edge_runtime.secrets]
STRIPE_SUCCESS_URL = "http://localhost:5173/cms/mycards"
STRIPE_CANCEL_URL = "http://localhost:5173/cms/mycards"
```

## Testing After Setup

1. Create a new batch from your production site
2. Click to initiate payment
3. Complete the Stripe checkout
4. **Verify:** You should be redirected to `https://cardstudio.org/cms/mycards?session_id=...`
5. If you cancel payment, verify redirect to `https://cardstudio.org/cms/mycards?canceled=true`

## Troubleshooting

### Issue: Still redirecting to wrong URL
**Solution:** 
1. Verify variables are saved in Supabase Dashboard
2. Variable names must match exactly (case-sensitive)
3. Try redeploying the Edge Function:
   ```bash
   npx supabase functions deploy create-checkout-session
   ```

### Issue: Getting localhost URL in production
**Solution:** The fallback chain is:
1. Environment variable (production Supabase)
2. Origin header (from request)
3. Localhost (last resort)

Make sure the environment variables are set correctly in production.

## Related Documentation
- Full details: `STRIPE_RETURN_URL_CONFIG.md`
- Edge Function: `supabase/functions/create-checkout-session/index.ts`

