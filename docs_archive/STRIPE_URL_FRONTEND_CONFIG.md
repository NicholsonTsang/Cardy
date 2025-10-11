# Stripe Return URLs - Frontend Configuration Implementation

## ✅ Implementation Complete

The Stripe return URLs are now configured in the **frontend** and passed to the Edge Function as parameters.

## What Was Changed

### 1. Environment Variables Added

#### `.env` (Development)
```bash
VITE_STRIPE_SUCCESS_URL=http://localhost:5173/cms/mycards
VITE_STRIPE_CANCEL_URL=http://localhost:5173/cms/mycards
```

#### `.env.production` (Production)
```bash
VITE_STRIPE_SUCCESS_URL=https://cardstudio.org/cms/mycards
VITE_STRIPE_CANCEL_URL=https://cardstudio.org/cms/mycards
```

### 2. Frontend Updated (`src/utils/stripeCheckout.js`)

**Before:**
```javascript
const { data, error } = await supabase.functions.invoke('create-checkout-session', {
  body: {
    cardCount,
    batchId,
    metadata
  }
})
```

**After:**
```javascript
// Get return URLs from environment variables
const successUrl = import.meta.env.VITE_STRIPE_SUCCESS_URL
const cancelUrl = import.meta.env.VITE_STRIPE_CANCEL_URL

const { data, error } = await supabase.functions.invoke('create-checkout-session', {
  body: {
    cardCount,
    batchId,
    successUrl,  // NEW: Pass from frontend
    cancelUrl,   // NEW: Pass from frontend
    metadata
  }
})
```

### 3. Edge Function Updated (`create-checkout-session/index.ts`)

**Added URL Validation:**
```typescript
const isValidUrl = (url: string): boolean => {
  try {
    const urlObj = new URL(url)
    // Allow http for localhost, https for everything else
    const isLocalhost = urlObj.hostname === 'localhost' || urlObj.hostname === '127.0.0.1'
    return (urlObj.protocol === 'https:') || (isLocalhost && urlObj.protocol === 'http:')
  } catch {
    return false
  }
}
```

**Priority Chain:**
```typescript
const successBaseUrl = (successUrl && isValidUrl(successUrl) ? successUrl : null)
  || Deno.env.get('STRIPE_SUCCESS_URL')      // Fallback to Edge Function secret
  || req.headers.get('origin')                // Fallback to origin header
  || 'http://localhost:5173/cms/mycards'      // Final fallback
```

**Smart Query Parameter Handling:**
```typescript
success_url: successBaseUrl.includes('?')
  ? `${successBaseUrl}&session_id={CHECKOUT_SESSION_ID}&batch_id=${batchId}`
  : `${successBaseUrl}?session_id={CHECKOUT_SESSION_ID}&batch_id=${batchId}`
```

### 4. Edge Function Deployed

- **Version:** 20
- **Status:** ✅ ACTIVE
- **Deploy Time:** Just now

## How It Works

```
┌─────────────────────────────────┐
│  Frontend (.env)                │
│  VITE_STRIPE_SUCCESS_URL        │
│  VITE_STRIPE_CANCEL_URL         │
└────────────┬────────────────────┘
             │ Passes to
             ↓
┌─────────────────────────────────┐
│  Edge Function                  │
│  1. Validates URL format        │
│  2. Checks HTTPS (or localhost) │
│  3. Uses validated URL          │
│  4. Falls back if invalid       │
└────────────┬────────────────────┘
             │ Creates
             ↓
┌─────────────────────────────────┐
│  Stripe Checkout Session        │
│  success_url: validated URL     │
│  cancel_url: validated URL      │
└─────────────────────────────────┘
```

## Security Features

### ✅ Basic URL Validation
- Checks URL format is valid
- Requires HTTPS (except localhost)
- Rejects malformed URLs

### ⚠️ No Domain Whitelist
Per your request, domain whitelisting is **NOT** implemented to maintain flexibility.

**Trade-off accepted:**
- 🟢 More flexible - can change domains without code updates
- 🟡 Less secure - allows any valid HTTPS URL
- 🟡 Risk accepted by user choice

### ✅ Multiple Fallback Layers
1. Frontend parameter (validated)
2. Edge Function environment variable
3. Origin header
4. Localhost fallback

## Configuration

### To Change Return URLs

#### Development
1. Edit `.env`:
   ```bash
   VITE_STRIPE_SUCCESS_URL=http://localhost:5173/your-new-path
   VITE_STRIPE_CANCEL_URL=http://localhost:5173/your-cancel-path
   ```
2. Restart dev server: `npm run dev`

#### Production
1. Edit `.env.production`:
   ```bash
   VITE_STRIPE_SUCCESS_URL=https://cardstudio.org/your-new-path
   VITE_STRIPE_CANCEL_URL=https://cardstudio.org/your-cancel-path
   ```
2. Rebuild and redeploy: `npm run build:production`

### No Edge Function Changes Needed
Once deployed, the Edge Function automatically uses the frontend URLs. No need to:
- ❌ Update Supabase Dashboard
- ❌ Redeploy Edge Function
- ❌ Configure secrets

## Testing

### Test Locally
1. Start dev server: `npm run dev`
2. Navigate to a card: http://localhost:5173/cms/mycards
3. Create a new batch and click "Issue Batch"
4. Should redirect to Stripe with test mode
5. Complete or cancel payment
6. Should redirect back to: `http://localhost:5173/cms/mycards`

### Test Production
1. Deploy frontend to production
2. Navigate to: https://cardstudio.org/cms/mycards
3. Create a batch and initiate payment
4. Complete payment
5. Should redirect to: `https://cardstudio.org/cms/mycards?session_id=...`

## Verification

Check that it's working:

```javascript
// In browser console after initiating payment
// Check the request to Edge Function
console.log('Success URL:', import.meta.env.VITE_STRIPE_SUCCESS_URL)
console.log('Cancel URL:', import.meta.env.VITE_STRIPE_CANCEL_URL)
```

## Advantages

### ✅ Easy to Change
- Update `.env` file
- Restart dev server
- No Edge Function redeployment needed

### ✅ Environment-Specific
- Different URLs for dev/staging/production
- Managed in standard `.env` files
- Follows Vite conventions

### ✅ Code-Based
- Version controlled
- Part of regular deployment
- No manual dashboard configuration

### ✅ Flexible
- Can use any valid HTTPS URL
- Supports query parameters in base URL
- Works with subdomains

## Disadvantages

### ⚠️ Client-Side Configurable
- Users can modify in browser dev tools
- Potential for redirect to unexpected URLs
- Requires trust in validation logic

### ⚠️ Less Secure Than Server-Only
- More attack surface
- Relies on validation being correct
- No domain whitelist by design

## Monitoring

To track where users are being redirected:

```typescript
// In Edge Function, add logging:
console.log('Redirecting to:', {
  success: successBaseUrl,
  cancel: cancelBaseUrl,
  source: successUrl ? 'frontend' : 'fallback'
})
```

## Rollback

If you need to revert to Edge Function secrets only:

1. Remove from frontend:
   ```javascript
   // stripeCheckout.js - remove these lines
   const successUrl = import.meta.env.VITE_STRIPE_SUCCESS_URL
   const cancelUrl = import.meta.env.VITE_STRIPE_CANCEL_URL
   ```

2. Update Edge Function:
   ```typescript
   const successBaseUrl = Deno.env.get('STRIPE_SUCCESS_URL') || 'http://localhost:5173/cms/mycards'
   const cancelBaseUrl = Deno.env.get('STRIPE_CANCEL_URL') || 'http://localhost:5173/cms/mycards'
   ```

3. Configure in Supabase Dashboard

## Files Modified

- ✅ `.env` - Added VITE_STRIPE_SUCCESS_URL and VITE_STRIPE_CANCEL_URL
- ✅ `.env.production` - Added production URLs
- ✅ `src/utils/stripeCheckout.js` - Passes URLs to Edge Function
- ✅ `supabase/functions/create-checkout-session/index.ts` - Accepts and validates URLs
- ✅ Edge Function deployed - Version 20

## Support

If you need to add more security:
1. Add domain whitelist in Edge Function
2. Implement signed URLs
3. Add rate limiting
4. See `STRIPE_URL_PARAMETER_ANALYSIS.md` for details

