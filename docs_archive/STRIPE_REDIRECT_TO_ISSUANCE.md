# Stripe Redirect to Card Issuance Page

## Overview

Updated Stripe payment redirect URLs to return users directly to the specific card's issuance page after payment completion or cancellation, providing a seamless user experience.

## Problem

Previously, after completing or canceling a Stripe payment for batch issuance:
- Users were redirected to the generic "My Cards" page
- Had to manually navigate back to the specific card
- Had to manually open the issuance tab
- Lost context and required extra clicks

## Solution

Automatically redirect users to the card's issuance page with the correct card selected and issuance tab open.

### URL Format

```
http://localhost:5173/cms/mycards?cardId={card_id}&tab=issuance
```

**Production**:
```
https://app.cardy.com/cms/mycards?cardId={card_id}&tab=issuance
```

### Parameters

- **`cardId`**: UUID of the card being issued
- **`tab=issuance`**: Opens the issuance tab automatically

## Implementation

### File: `src/utils/stripeCheckout.js`

**Before**:
```javascript
// Get return URLs from environment variables
const successUrl = import.meta.env.VITE_STRIPE_SUCCESS_URL
const cancelUrl = import.meta.env.VITE_STRIPE_CANCEL_URL

// Create checkout session via Edge Function
const { data, error } = await supabase.functions.invoke('create-checkout-session', {
  body: {
    cardCount,
    batchId,
    successUrl,
    cancelUrl,
    metadata
  }
})
```

**After**:
```javascript
// Build return URLs with cardId and tab parameters
const baseSuccessUrl = import.meta.env.VITE_STRIPE_SUCCESS_URL || `${window.location.origin}/cms/mycards`
const baseCancelUrl = import.meta.env.VITE_STRIPE_CANCEL_URL || `${window.location.origin}/cms/mycards`

// Add cardId and tab=issuance parameters if card_id is in metadata
const cardId = metadata.card_id
const successUrl = cardId 
  ? `${baseSuccessUrl}${baseSuccessUrl.includes('?') ? '&' : '?'}cardId=${cardId}&tab=issuance`
  : baseSuccessUrl

const cancelUrl = cardId
  ? `${baseCancelUrl}${baseCancelUrl.includes('?') ? '&' : '?'}cardId=${cardId}&tab=issuance`
  : baseCancelUrl

// Create checkout session via Edge Function
const { data, error } = await supabase.functions.invoke('create-checkout-session', {
  body: {
    cardCount,
    batchId,
    successUrl,
    cancelUrl,
    metadata
  }
})
```

## How It Works

### 1. Batch Creation Flow

```javascript
// CardIssuanceCheckout.vue
const handlePayment = async (formData) => {
  await createCheckoutSession(formData.cardCount, 'pending-batch', {
    card_id: props.cardId,  // ← Card ID included in metadata
    is_pending_batch: true
  })
}
```

### 2. URL Construction

```javascript
// stripeCheckout.js
const cardId = metadata.card_id  // Extract from metadata

// Build success URL
const successUrl = cardId 
  ? `${baseSuccessUrl}?cardId=${cardId}&tab=issuance`
  : baseSuccessUrl

// Build cancel URL  
const cancelUrl = cardId
  ? `${baseCancelUrl}?cardId=${cardId}&tab=issuance`
  : baseCancelUrl
```

### 3. Query Parameter Handling

The code checks if the base URL already contains query parameters:

```javascript
baseSuccessUrl.includes('?') ? '&' : '?'
```

**Examples**:

| Base URL | cardId | Result |
|----------|--------|--------|
| `http://localhost:5173/cms/mycards` | `abc123` | `http://localhost:5173/cms/mycards?cardId=abc123&tab=issuance` |
| `http://localhost:5173/cms/mycards?foo=bar` | `abc123` | `http://localhost:5173/cms/mycards?foo=bar&cardId=abc123&tab=issuance` |

### 4. Stripe Redirect

Stripe uses these URLs for post-payment redirect:

```javascript
// Edge Function creates Stripe session with:
success_url: `${successUrl}&session_id={CHECKOUT_SESSION_ID}`
cancel_url: `${cancelUrl}&canceled=true`
```

**Final URLs**:
- **Success**: `http://localhost:5173/cms/mycards?cardId=abc123&tab=issuance&session_id=cs_...`
- **Cancel**: `http://localhost:5173/cms/mycards?cardId=abc123&tab=issuance&canceled=true`

## User Experience Flow

### Before (Multiple Steps)

```
1. User on Card Issuance page
2. Click "Issue New Batch"
3. Redirected to Stripe checkout
4. Complete payment
5. ❌ Redirected to "My Cards" (generic list)
6. ❌ Find and click on the card
7. ❌ Click "Issuance" tab
8. ✅ View new batch
```

**Total**: 8 steps, 3 manual actions after payment

### After (Seamless)

```
1. User on Card Issuance page
2. Click "Issue New Batch"
3. Redirected to Stripe checkout
4. Complete payment
5. ✅ Automatically back to Card Issuance page
6. ✅ Issuance tab already open
7. ✅ View new batch immediately
```

**Total**: 5 steps, 0 manual actions after payment

## Environment Variables

### Development (`.env.local`)

```bash
VITE_STRIPE_SUCCESS_URL=http://localhost:5173/cms/mycards
VITE_STRIPE_CANCEL_URL=http://localhost:5173/cms/mycards
```

### Production (`.env.production`)

```bash
VITE_STRIPE_SUCCESS_URL=https://app.cardy.com/cms/mycards
VITE_STRIPE_CANCEL_URL=https://app.cardy.com/cms/mycards
```

**Note**: The code automatically appends `?cardId={id}&tab=issuance` to these base URLs.

## Fallback Behavior

If `VITE_STRIPE_SUCCESS_URL` or `VITE_STRIPE_CANCEL_URL` are not set:

```javascript
const baseSuccessUrl = import.meta.env.VITE_STRIPE_SUCCESS_URL || `${window.location.origin}/cms/mycards`
```

The code falls back to the current origin + `/cms/mycards`, ensuring the redirect always works even without environment variables configured.

## Edge Cases Handled

### 1. No Card ID in Metadata

If `metadata.card_id` is missing:
```javascript
const successUrl = cardId 
  ? `${baseSuccessUrl}?cardId=${cardId}&tab=issuance`
  : baseSuccessUrl  // ← Falls back to base URL
```

**Result**: Redirects to generic My Cards page (graceful degradation)

### 2. Existing Query Parameters

If base URL already has query parameters:
```javascript
baseSuccessUrl.includes('?') ? '&' : '?'
```

**Example**: 
- Base: `http://localhost:5173/cms/mycards?debug=true`
- Result: `http://localhost:5173/cms/mycards?debug=true&cardId=abc123&tab=issuance`

### 3. Non-Batch Payments

For existing batch payments (not pending):
```javascript
// Edge Function handles this
success_url: metadata.is_pending_batch 
  ? `${successUrl}&session_id={CHECKOUT_SESSION_ID}`
  : `${successUrl}&session_id={CHECKOUT_SESSION_ID}&batch_id=${batchId}`
```

## Frontend URL Handling

The My Cards page should handle these query parameters:

```javascript
// Example implementation (MyCards.vue or similar)
onMounted(() => {
  const urlParams = new URLSearchParams(window.location.search)
  const cardId = urlParams.get('cardId')
  const tab = urlParams.get('tab')
  const sessionId = urlParams.get('session_id')
  const canceled = urlParams.get('canceled')

  if (cardId && tab === 'issuance') {
    // Open specific card with issuance tab
    openCardIssuancePage(cardId)
    
    if (sessionId) {
      // Show success message
      toast.add({
        severity: 'success',
        summary: 'Payment Successful',
        detail: 'Your batch is being generated...',
        life: 5000
      })
    } else if (canceled) {
      // Show cancellation message
      toast.add({
        severity: 'info',
        summary: 'Payment Canceled',
        detail: 'You can try again when ready.',
        life: 5000
      })
    }
  }
})
```

## Testing

### Test Cases

1. **New Batch Creation**
   - Navigate to card issuance page
   - Create new batch
   - Complete Stripe payment
   - ✅ Should redirect to card issuance page with tab open
   - ✅ URL should contain `cardId` and `tab=issuance`

2. **Payment Cancellation**
   - Navigate to card issuance page
   - Create new batch
   - Cancel Stripe payment
   - ✅ Should redirect to card issuance page with tab open
   - ✅ URL should contain `cardId`, `tab=issuance`, and `canceled=true`

3. **Multiple Cards**
   - Create batches for different cards
   - Each should redirect to its specific card page
   - ✅ Verify correct card is opened each time

4. **Direct Navigation**
   - Test URL: `http://localhost:5173/cms/mycards?cardId=abc123&tab=issuance`
   - ✅ Should open the specific card with issuance tab

### Manual Testing

```bash
# 1. Start dev server
npm run dev

# 2. Navigate to card issuance page
# http://localhost:5173/cms/mycards?cardId=YOUR_CARD_ID&tab=issuance

# 3. Create new batch
# - Click "Issue New Batch"
# - Enter quantity
# - Click "Create Batch & Pay"

# 4. Use Stripe test card
# 4242 4242 4242 4242
# Any future expiry date
# Any 3-digit CVC

# 5. Complete or cancel payment

# 6. Verify redirect
# - Should return to card issuance page
# - Correct card should be selected
# - Issuance tab should be open
```

## Benefits

### 1. Better UX ✅
- No manual navigation needed after payment
- Context preserved throughout payment flow
- Immediate access to new batch information

### 2. Time Savings ✅
- 3 fewer clicks per batch issuance
- Faster workflow for frequent users
- Reduced friction in payment process

### 3. Clearer Intent ✅
- User stays in the context of the specific card
- Reduces confusion about where to find the new batch
- Smooth transition from payment to confirmation

### 4. Professional Feel ✅
- Polished user experience
- Comparable to modern SaaS platforms
- Builds user confidence

## Related Files

- **`src/utils/stripeCheckout.js`** - URL construction logic
- **`src/components/CardIssuanceCheckout.vue`** - Passes card_id in metadata
- **`supabase/functions/create-checkout-session/index.ts`** - Edge Function (uses URLs as-is)
- **`.env.local`** - Development environment base URLs
- **`.env.production`** - Production environment base URLs

## Future Enhancements

### Potential Improvements

1. **Batch Status Highlighting**
   - Highlight newly created batch in the list
   - Auto-scroll to new batch
   - Show "NEW" badge

2. **Success Animation**
   - Confetti or celebration animation on successful payment
   - Progress indicator showing batch generation

3. **Deep Linking**
   - Support bookmark-able URLs for specific card issuance pages
   - Share-able links for team collaboration

4. **Analytics Tracking**
   - Track conversion rates from issuance page
   - Measure payment completion vs cancellation
   - Identify friction points

## Status

✅ **IMPLEMENTED** - Stripe redirects now include `cardId` and `tab=issuance` parameters, providing seamless navigation back to the specific card's issuance page after payment.

