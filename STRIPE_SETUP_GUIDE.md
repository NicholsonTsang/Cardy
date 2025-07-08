# Stripe Portal Setup Guide for Cardy CMS

## Required Stripe Configuration

### 1. Get API Keys
1. Go to [Stripe Dashboard](https://dashboard.stripe.com)
2. Navigate to **Developers → API Keys**
3. Copy the **Publishable key** (starts with `pk_test_`)
4. Copy the **Secret key** (starts with `sk_test_`)

### 2. Set Environment Variables
Add to your `.env` file:
```bash
VITE_STRIPE_PUBLISHABLE_KEY=pk_test_your_key_here
STRIPE_SECRET_KEY=sk_test_your_key_here
```

### 3. Configure Webhooks (Critical)
1. Go to **Developers → Webhooks**
2. Click **"Add endpoint"**
3. Set endpoint URL: `https://your-supabase-project.supabase.co/functions/v1/stripe-webhook`
4. Select these events:
   - `checkout.session.completed`
   - `payment_intent.succeeded` 
   - `payment_intent.payment_failed`
5. Copy the **Webhook signing secret** (starts with `whsec_`)

### 4. Business Information (Required for Live Mode)
1. Go to **Settings → Business settings**
2. Fill in:
   - Business type
   - Business address
   - Tax ID (if applicable)
   - Business description

### 5. Payout Settings
1. Go to **Settings → Payouts**
2. Add bank account details
3. Set payout schedule

### 6. Test Your Integration

#### Test Card Numbers:
- **Success**: `4242424242424242`
- **Decline**: `4000000000000002`
- **Require Authentication**: `4000002500003155`

#### Test Flow:
1. Create a card design
2. Issue a batch
3. Use test card numbers
4. Verify payment completion
5. Check webhook delivery

### 7. Supabase Setup
Add Stripe secret to Supabase:
```bash
supabase secrets set STRIPE_SECRET_KEY=sk_test_your_key_here
supabase secrets set STRIPE_WEBHOOK_SECRET=whsec_your_webhook_secret_here
```

Deploy Edge Functions:
```bash
supabase functions deploy create-checkout-session
supabase functions deploy handle-checkout-success
```

### 8. Common Issues & Solutions

#### "Something went wrong" Error:
- Check Stripe API keys are correct
- Verify webhook endpoint is accessible
- Check Supabase Edge Function logs
- Ensure minimum amount ($0.50) is met

#### 401 Unauthorized:
- Verify `STRIPE_SECRET_KEY` is set in Supabase secrets
- Check API key permissions

#### CSP Font Errors:
- Add `https://js.stripe.com` to font-src CSP policy
- For Supabase hosting, this is usually automatic

### 9. Going Live

When ready for production:
1. Switch to live API keys (`pk_live_` and `sk_live_`)
2. Update webhook endpoint URL
3. Complete business verification
4. Test with real card (small amount)
5. Monitor initial transactions

### 10. Monitoring

Check these in Stripe Dashboard:
- **Payments** - Transaction history
- **Logs** - API request logs  
- **Webhooks** - Delivery status
- **Disputes** - Customer chargebacks