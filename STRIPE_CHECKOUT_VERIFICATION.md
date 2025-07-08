# Stripe Checkout Integration Verification

## Current Status Check

### 1. Environment Variables ❌
```bash
# Current (placeholder values):
VITE_STRIPE_PUBLISHABLE_KEY=pk_test_51234567890abcdef
STRIPE_SECRET_KEY=sk_test_51234567890abcdef

# You need real keys from: https://dashboard.stripe.com/test/apikeys
```

### 2. Edge Functions Status ✅
- ✅ `create-checkout-session` - Deployed
- ✅ `handle-checkout-success` - Deployed
- ❌ `confirm-payment` - Deleted (old, unused)
- ❌ `create-payment-intent` - Deleted (old, unused)

## Verification Steps

### Step 1: Update Stripe Keys

1. Get your real Stripe test keys:
   ```bash
   # Go to: https://dashboard.stripe.com/test/apikeys
   # Copy both keys
   ```

2. Update `.env`:
   ```bash
   VITE_STRIPE_PUBLISHABLE_KEY=pk_test_your_real_key
   STRIPE_SECRET_KEY=sk_test_your_real_key
   ```

3. Set Stripe secret in Supabase:
   ```bash
   supabase secrets set STRIPE_SECRET_KEY=sk_test_your_real_key
   ```

### Step 2: Test Edge Functions

1. Test Stripe connection:
   ```bash
   # Deploy test function
   supabase functions deploy test-stripe
   
   # Test it
   curl -X POST https://mzgusshseqxrdrkvamrg.supabase.co/functions/v1/test-stripe \
     -H "Authorization: Bearer YOUR_ANON_KEY" \
     -H "Content-Type: application/json"
   ```

2. Test checkout session creation:
   ```bash
   curl -X POST https://mzgusshseqxrdrkvamrg.supabase.co/functions/v1/create-checkout-session \
     -H "Authorization: Bearer YOUR_ANON_KEY" \
     -H "Content-Type: application/json" \
     -d '{
       "cardCount": 10,
       "batchId": "test-batch-id",
       "metadata": {"test": true}
     }'
   ```

### Step 3: Configure Stripe Webhook

1. Go to Stripe Dashboard → Developers → Webhooks
2. Add endpoint:
   ```
   URL: https://mzgusshseqxrdrkvamrg.supabase.co/functions/v1/stripe-webhook
   Events: 
   - checkout.session.completed
   - payment_intent.succeeded
   - payment_intent.payment_failed
   ```
3. Copy webhook signing secret
4. Set in Supabase:
   ```bash
   supabase secrets set STRIPE_WEBHOOK_SECRET=whsec_your_webhook_secret
   ```

### Step 4: Test Complete Flow

1. **Start Dev Server**:
   ```bash
   npm run dev
   ```

2. **Create Test Scenario**:
   - Login as card issuer
   - Create a card design
   - Go to Issuance tab
   - Click "Issue New Batch"
   - Enter batch details
   - Click "Issue & Pay"

3. **Test Payment**:
   - Should redirect to Stripe Checkout
   - Use test card: `4242 4242 4242 4242`
   - Complete payment
   - Should redirect back to your app

### Step 5: Verify Database Updates

Check if these happen after successful payment:
- [ ] `batch_payments` table has new record with status 'completed'
- [ ] `card_batches` has `payment_completed` = true
- [ ] `issue_cards` table has new cards generated
- [ ] Redirect URL contains success parameters

## Test Cards for Different Scenarios

| Scenario | Card Number | Description |
|----------|-------------|-------------|
| Success | 4242 4242 4242 4242 | Always succeeds |
| Decline | 4000 0000 0000 0002 | Always declines |
| Authentication | 4000 0025 0000 3155 | Requires 3D Secure |
| Insufficient Funds | 4000 0000 0000 9995 | Declines with insufficient funds |

## Common Issues & Solutions

### Issue: "Something went wrong"
**Causes**:
- Invalid/placeholder Stripe keys
- Edge function not deployed
- CORS issues

**Fix**:
1. Update Stripe keys in `.env`
2. Redeploy Edge functions
3. Check browser console for errors

### Issue: 401 Unauthorized
**Causes**:
- Missing `STRIPE_SECRET_KEY` in Supabase secrets
- Invalid API key

**Fix**:
```bash
supabase secrets set STRIPE_SECRET_KEY=sk_test_your_key
supabase functions deploy create-checkout-session
```

### Issue: Webhook not receiving events
**Causes**:
- Webhook not configured in Stripe
- Wrong endpoint URL
- Missing webhook secret

**Fix**:
1. Configure webhook in Stripe Dashboard
2. Verify endpoint URL
3. Set webhook secret in Supabase

## Monitoring & Logs

### Check Edge Function Logs:
```bash
supabase functions logs create-checkout-session
supabase functions logs handle-checkout-success
```

### Check Stripe Logs:
1. Go to Stripe Dashboard → Developers → Logs
2. Filter by:
   - API requests
   - Webhook attempts
   - Errors only

### Check Database:
```sql
-- Check recent payments
SELECT * FROM batch_payments 
ORDER BY created_at DESC 
LIMIT 10;

-- Check batch status
SELECT id, batch_name, payment_completed, payment_completed_at 
FROM card_batches 
WHERE created_by = auth.uid() 
ORDER BY created_at DESC;

-- Check generated cards
SELECT COUNT(*) 
FROM issue_cards ic
JOIN card_batches cb ON ic.batch_id = cb.id
WHERE cb.payment_completed = true;
```

## Success Indicators

✅ **Working Correctly When**:
- Clicking "Issue & Pay" redirects to Stripe Checkout
- Test payment completes successfully
- User redirected back to app with success message
- Batch shows as "Paid" in the UI
- Cards are generated in database
- Can view issued cards in the system

## Next Steps After Verification

1. **Test with different amounts**: Try 1 card, 50 cards, 100 cards
2. **Test error scenarios**: Cancel payment, use declining card
3. **Check mobile experience**: Test on phone/tablet
4. **Review analytics**: Check Stripe Dashboard for insights
5. **Set up monitoring**: Configure alerts for failed payments