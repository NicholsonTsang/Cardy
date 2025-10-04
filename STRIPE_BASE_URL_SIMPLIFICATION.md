# Stripe Base URL Simplification

## 📋 Overview

Simplified the Stripe checkout redirect URL configuration to **only use the base URL from the frontend**, removing environment variable fallbacks and origin header detection.

---

## 🔄 Changes Made

### **1. Edge Function (`create-checkout-session/index.ts`)**

**Before:**
```typescript
// Complex priority system with multiple fallbacks
const successBaseUrl = (successUrl && isValidUrl(successUrl) ? successUrl : null)
  || Deno.env.get('STRIPE_SUCCESS_URL')
  || `${req.headers.get('origin')}/cms/mycards`
  || 'http://localhost:5173/cms/mycards'
  
const cancelBaseUrl = (cancelUrl && isValidUrl(cancelUrl) ? cancelUrl : null)
  || Deno.env.get('STRIPE_CANCEL_URL')
  || `${req.headers.get('origin')}/cms/mycards`
  || 'http://localhost:5173/cms/mycards'
```

**After:**
```typescript
// Simple: Only use baseUrl from frontend
const successBaseUrl = baseUrl
const cancelBaseUrl = baseUrl
```

**Request Body:**
- **Removed:** `successUrl`, `cancelUrl` (separate URLs)
- **Added:** `baseUrl` (single URL for both success and cancel)
- **Validation:** Now validates that `baseUrl` is provided and valid

### **2. Frontend (`src/utils/stripeCheckout.js`)**

**Before:**
```javascript
// Separate URLs for success and cancel
const baseSuccessUrl = import.meta.env.VITE_STRIPE_SUCCESS_URL || `${window.location.origin}/cms/mycards`
const baseCancelUrl = import.meta.env.VITE_STRIPE_CANCEL_URL || `${window.location.origin}/cms/mycards`

const successUrl = cardId 
  ? `${baseSuccessUrl}${baseSuccessUrl.includes('?') ? '&' : '?'}cardId=${cardId}&tab=issuance`
  : baseSuccessUrl

const cancelUrl = cardId
  ? `${baseCancelUrl}${baseCancelUrl.includes('?') ? '&' : '?'}cardId=${cardId}&tab=issuance`
  : baseCancelUrl

await supabase.functions.invoke('create-checkout-session', {
  body: {
    cardCount,
    batchId,
    successUrl,
    cancelUrl,
    metadata
  }
})
```

**After:**
```javascript
// Single base URL for both success and cancel
const baseUrl = import.meta.env.VITE_STRIPE_SUCCESS_URL || `${window.location.origin}/cms/mycards`

await supabase.functions.invoke('create-checkout-session', {
  body: {
    cardCount,
    batchId,
    baseUrl,
    metadata
  }
})
```

### **3. Configuration (`supabase/config.toml`)**

**Before:**
```toml
[edge_runtime.secrets]
# Stripe Return URLs for local development
STRIPE_SUCCESS_URL = "http://localhost:5173/cms/mycards"
STRIPE_CANCEL_URL = "http://localhost:5173/cms/mycards"
```

**After:**
```toml
[edge_runtime.secrets]
# Note: Stripe return URLs are now passed from the frontend via baseUrl parameter
# No need to configure STRIPE_SUCCESS_URL or STRIPE_CANCEL_URL here anymore
```

---

## ✅ Benefits

### **1. Simplified Architecture**
- **Single source of truth**: Frontend controls the redirect URL
- **No environment variable dependencies** in the Edge Function
- **No origin header detection** or localhost fallbacks

### **2. Better Security**
- **Explicit control**: Frontend must provide a valid URL
- **No automatic fallbacks** that could lead to unexpected redirects
- **Validation required**: Edge Function validates the URL before use

### **3. Easier Configuration**
- **Frontend only**: Configure `VITE_STRIPE_SUCCESS_URL` in `.env` files
- **No backend secrets needed** for Stripe return URLs
- **Less duplication**: One URL serves both success and cancel

### **4. Clearer Intent**
- **baseUrl parameter** clearly indicates it's the base for redirects
- **Edge Function appends** query parameters (cardId, batchId, tab, success/canceled)
- **Consistent behavior** across environments

---

## 🔧 Configuration

### **Frontend Environment Variables**

**Development (`.env.local`):**
```bash
VITE_STRIPE_SUCCESS_URL=http://localhost:5173/cms/mycards
```

**Production (`.env.production`):**
```bash
VITE_STRIPE_SUCCESS_URL=https://app.cardy.com/cms/mycards
```

### **Backend Environment Variables**

**No longer needed!** ✅

The Edge Function no longer reads:
- ~~`STRIPE_SUCCESS_URL`~~
- ~~`STRIPE_CANCEL_URL`~~

---

## 🎯 How It Works

### **1. Frontend Flow**

```javascript
// User initiates checkout
createCheckoutSession(10, 'batch-uuid-123', { card_id: 'card-uuid-456' })

// Frontend builds baseUrl
const baseUrl = "http://localhost:5173/cms/mycards"

// Frontend calls Edge Function
await supabase.functions.invoke('create-checkout-session', {
  body: {
    cardCount: 10,
    batchId: 'batch-uuid-123',
    baseUrl: "http://localhost:5173/cms/mycards",  // <-- Single URL
    metadata: { card_id: 'card-uuid-456' }
  }
})
```

### **2. Edge Function Processing**

```typescript
// Validate baseUrl is provided
if (!baseUrl || !isValidUrl(baseUrl)) {
  return new Response(
    JSON.stringify({ error: 'Invalid or missing baseUrl' }),
    { status: 400, headers: corsHeaders }
  )
}

// Use baseUrl for both success and cancel
const successBaseUrl = baseUrl
const cancelBaseUrl = baseUrl

// Edge Function appends query parameters
const checkoutSession = await stripe.checkout.sessions.create({
  success_url: `${successBaseUrl}?cardId=${cardId}&batchId=${batchId}&tab=issuance&session_id={CHECKOUT_SESSION_ID}`,
  cancel_url: `${cancelBaseUrl}?cardId=${cardId}&batchId=${batchId}&tab=issuance&canceled=true`,
  // ... other Stripe config
})
```

### **3. Redirect URLs Generated**

**Success:**
```
http://localhost:5173/cms/mycards?cardId=card-uuid-456&batchId=batch-uuid-123&tab=issuance&session_id=cs_test_...
```

**Cancel:**
```
http://localhost:5173/cms/mycards?cardId=card-uuid-456&batchId=batch-uuid-123&tab=issuance&canceled=true
```

---

## 🧪 Testing

### **1. Test Local Development**

```bash
# Ensure VITE_STRIPE_SUCCESS_URL is set in .env.local
VITE_STRIPE_SUCCESS_URL=http://localhost:5173/cms/mycards

# Run the app
npm run dev

# Create a batch and proceed to checkout
# Verify the redirect URL after payment success/cancel
```

### **2. Test Production**

```bash
# Ensure VITE_STRIPE_SUCCESS_URL is set in .env.production
VITE_STRIPE_SUCCESS_URL=https://app.cardy.com/cms/mycards

# Build and deploy
npm run build:production
```

### **3. Test Error Handling**

```javascript
// Test missing baseUrl
await supabase.functions.invoke('create-checkout-session', {
  body: {
    cardCount: 10,
    batchId: 'batch-uuid-123',
    // baseUrl: missing!
    metadata: {}
  }
})
// Expected: 400 error - "Invalid or missing baseUrl"

// Test invalid baseUrl
await supabase.functions.invoke('create-checkout-session', {
  body: {
    cardCount: 10,
    batchId: 'batch-uuid-123',
    baseUrl: "not-a-valid-url",
    metadata: {}
  }
})
// Expected: 400 error - "Invalid or missing baseUrl"
```

---

## 📝 Migration Checklist

### **Backend (Edge Function)**
- [x] Update request body parsing to accept `baseUrl` instead of `successUrl` and `cancelUrl`
- [x] Add validation for `baseUrl`
- [x] Remove environment variable fallbacks (`STRIPE_SUCCESS_URL`, `STRIPE_CANCEL_URL`)
- [x] Remove origin header detection
- [x] Remove localhost fallback
- [x] Simplify URL construction to use `baseUrl` directly

### **Frontend**
- [x] Update `stripeCheckout.js` to pass `baseUrl` instead of `successUrl` and `cancelUrl`
- [x] Simplify URL building logic (single URL for both success and cancel)
- [x] Remove `VITE_STRIPE_CANCEL_URL` references (use same as success URL)

### **Configuration**
- [x] Update `supabase/config.toml` to remove `STRIPE_CANCEL_URL`
- [x] Add documentation note about frontend-only configuration
- [x] Update `.env` files to only use `VITE_STRIPE_SUCCESS_URL`

### **Documentation**
- [x] Create this migration guide
- [x] Update `DENO_CONFIGURATION_GUIDE.md` if needed
- [x] Update `CLAUDE.md` with new Stripe configuration pattern

---

## 🎉 Summary

**Old Way:**
- 4 potential sources for URLs (frontend, env vars, origin header, localhost)
- Complex fallback logic
- Separate success and cancel URLs
- Configuration in both frontend and backend

**New Way:**
- 1 source: Frontend `baseUrl` parameter
- Simple, explicit validation
- Single base URL for both success and cancel
- Configuration in frontend only

**Result:** Cleaner, more secure, easier to maintain! ✅

