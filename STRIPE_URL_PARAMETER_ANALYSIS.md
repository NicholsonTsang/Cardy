# Stripe Return URL: Frontend Parameter vs Edge Function Secret

## Question
Can we pass Stripe success/cancel URLs from the frontend to the Edge Function as parameters instead of using Edge Function secrets? What are the security concerns?

## Short Answer
✅ **YES, it's technically possible**  
⚠️ **BUT there are security trade-offs to consider**

## Analysis

### Current Implementation (Edge Function Secret)

```typescript
// Edge Function
const successBaseUrl = Deno.env.get('STRIPE_SUCCESS_URL') 
  || req.headers.get('origin') 
  || 'http://localhost:5173'
```

**Security Level:** ✅ High

### Alternative Implementation (Frontend Parameter)

```javascript
// Frontend
const successUrl = `${window.location.origin}/cms/mycards`
await supabase.functions.invoke('create-checkout-session', {
  body: {
    cardCount,
    batchId,
    successUrl,  // NEW
    cancelUrl,   // NEW
    metadata
  }
})

// Edge Function
const successBaseUrl = successUrl || Deno.env.get('STRIPE_SUCCESS_URL')
```

**Security Level:** ⚠️ Medium (with validation)

## Security Concerns

### 1. **Open Redirect Vulnerability** ❌ HIGH RISK

**Attack Scenario:**
```javascript
// Malicious user modifies frontend code
const successUrl = 'https://malicious-site.com/steal-session'
await supabase.functions.invoke('create-checkout-session', {
  body: {
    successUrl: 'https://evil.com?session_id=', // Attacker controls this
    ...
  }
})
```

**Result:** After payment, user redirects to attacker's site with `session_id` in URL
- Attacker can steal the session ID
- Attacker can complete the payment flow on behalf of user
- Potential financial fraud

### 2. **Phishing Attacks** ❌ MEDIUM RISK

**Attack Scenario:**
- Attacker creates fake checkout flow
- Sets `successUrl` to phishing site that looks like your app
- User completes payment on real Stripe
- Gets redirected to fake site asking for additional "verification"
- User enters sensitive information on fake site

### 3. **Session Hijacking** ❌ MEDIUM RISK

**Attack Scenario:**
- Attacker intercepts the return URL with session_id
- Uses the session_id to access payment information
- Potentially cancels or modifies the payment

### 4. **Data Leakage** ⚠️ LOW RISK

**Attack Scenario:**
- User redirected to third-party analytics or tracking site
- Session ID and payment details exposed in referrer headers
- Privacy violation, not direct security breach

## Mitigation Strategies

If you still want to allow frontend parameters, implement **ALL** of these:

### 1. **Whitelist Validation** ✅ REQUIRED

```typescript
// Edge Function
const ALLOWED_DOMAINS = [
  'https://cardstudio.org',
  'https://app.cardstudio.org',
  'http://localhost:5173',
  'http://localhost:3000'
]

function validateReturnUrl(url: string): boolean {
  try {
    const urlObj = new URL(url)
    return ALLOWED_DOMAINS.some(domain => url.startsWith(domain))
  } catch {
    return false
  }
}

const successBaseUrl = successUrl && validateReturnUrl(successUrl)
  ? successUrl
  : Deno.env.get('STRIPE_SUCCESS_URL')
```

### 2. **Path Validation** ✅ REQUIRED

```typescript
// Only allow specific paths
const ALLOWED_PATHS = [
  '/cms/mycards',
  '/dashboard/payments',
  '/checkout/success'
]

function validateReturnUrl(url: string): boolean {
  try {
    const urlObj = new URL(url)
    const isAllowedDomain = ALLOWED_DOMAINS.some(d => url.startsWith(d))
    const isAllowedPath = ALLOWED_PATHS.some(p => urlObj.pathname === p)
    return isAllowedDomain && isAllowedPath
  } catch {
    return false
  }
}
```

### 3. **Signed URLs** ✅ RECOMMENDED

```typescript
// Frontend
import crypto from 'crypto'

const successUrl = '/cms/mycards'
const timestamp = Date.now()
const signature = crypto
  .createHmac('sha256', VITE_URL_SIGNING_SECRET)
  .update(`${successUrl}:${timestamp}`)
  .digest('hex')

await supabase.functions.invoke('create-checkout-session', {
  body: {
    successUrl,
    urlSignature: signature,
    urlTimestamp: timestamp
  }
})

// Edge Function
function verifyUrlSignature(url: string, signature: string, timestamp: number): boolean {
  // Check timestamp is recent (within 5 minutes)
  if (Date.now() - timestamp > 300000) return false
  
  const expectedSignature = crypto
    .createHmac('sha256', Deno.env.get('URL_SIGNING_SECRET'))
    .update(`${url}:${timestamp}`)
    .digest('hex')
  
  return signature === expectedSignature
}
```

### 4. **Rate Limiting** ✅ RECOMMENDED

```typescript
// Limit requests per user per hour
const MAX_CHECKOUT_SESSIONS_PER_HOUR = 10

async function checkRateLimit(userId: string): Promise<boolean> {
  // Implementation using Redis or Supabase table
  const count = await getRecentCheckoutCount(userId)
  return count < MAX_CHECKOUT_SESSIONS_PER_HOUR
}
```

## Comparison Table

| Aspect | Edge Function Secret | Frontend Parameter |
|--------|---------------------|-------------------|
| **Security** | ✅ High | ⚠️ Medium (with validation) |
| **Flexibility** | ❌ Low | ✅ High |
| **Configuration** | ⚠️ Requires dashboard | ✅ Code-based |
| **Attack Surface** | ✅ Minimal | ⚠️ Increased |
| **Implementation** | ✅ Simple | ⚠️ Complex |
| **Maintenance** | ⚠️ Manual updates | ✅ Automatic |
| **Multi-domain** | ❌ One per env | ✅ Dynamic |

## Recommendations

### 🎯 For Your Use Case (Single Domain)

**KEEP using Edge Function secrets** because:
1. You only have one domain: `cardstudio.org`
2. You don't need dynamic redirects
3. Simpler and more secure
4. Less attack surface

### 🎯 When to Use Frontend Parameters

**Only if you have these requirements:**
1. Multiple subdomains (e.g., `app1.cardy.com`, `app2.cardy.com`)
2. White-label solution (different clients, different domains)
3. Testing different redirect flows without redeployment
4. A/B testing different success pages

### 🎯 Hybrid Approach (Best of Both)

```typescript
// Edge Function
const successBaseUrl = (() => {
  // Priority 1: Validate frontend parameter (if provided and valid)
  if (successUrl && validateReturnUrl(successUrl)) {
    return successUrl
  }
  
  // Priority 2: Environment variable (trusted)
  if (Deno.env.get('STRIPE_SUCCESS_URL')) {
    return Deno.env.get('STRIPE_SUCCESS_URL')
  }
  
  // Priority 3: Origin header (moderate trust)
  const origin = req.headers.get('origin')
  if (origin && validateReturnUrl(origin)) {
    return `${origin}/cms/mycards`
  }
  
  // Priority 4: Fallback
  return 'http://localhost:5173/cms/mycards'
})()
```

## Current Implementation Analysis

Your current code already uses a hybrid approach:

```typescript
const successBaseUrl = Deno.env.get('STRIPE_SUCCESS_URL') 
  || req.headers.get('origin')  // ⚠️ This is actually passing from frontend!
  || 'http://localhost:5173'
```

**Security Status:**
- ⚠️ **MEDIUM RISK** - Already accepting origin header from frontend
- ✅ **No validation** on the origin header currently
- ⚠️ **Potential vulnerability** to open redirect attacks

## Immediate Recommendations

### Option 1: Strengthen Current Implementation ✅ RECOMMENDED

```typescript
const ALLOWED_ORIGINS = [
  'https://cardstudio.org',
  'http://localhost:5173'
]

function validateOrigin(origin: string | null): string | null {
  if (!origin) return null
  return ALLOWED_ORIGINS.includes(origin) ? origin : null
}

const successBaseUrl = Deno.env.get('STRIPE_SUCCESS_URL')
  || validateOrigin(req.headers.get('origin'))
  || 'http://localhost:5173'
```

### Option 2: Remove Origin Fallback ✅ MOST SECURE

```typescript
const successBaseUrl = Deno.env.get('STRIPE_SUCCESS_URL') || 'http://localhost:5173'
const cancelBaseUrl = Deno.env.get('STRIPE_CANCEL_URL') || 'http://localhost:5173'

if (!Deno.env.get('STRIPE_SUCCESS_URL')) {
  throw new Error('STRIPE_SUCCESS_URL environment variable is required')
}
```

## Conclusion

**For your application:**
1. ✅ **Keep using Edge Function secrets** - simplest and most secure
2. ⚠️ **Add validation** to the current origin header fallback
3. ❌ **Don't add explicit frontend parameters** unless you have a specific need

The current implementation is good, but needs validation on the origin header to prevent open redirect vulnerabilities.

## Implementation Steps (If You Want Frontend Parameters)

See `STRIPE_URL_FRONTEND_PARAMS_IMPLEMENTATION.md` for detailed code examples.

