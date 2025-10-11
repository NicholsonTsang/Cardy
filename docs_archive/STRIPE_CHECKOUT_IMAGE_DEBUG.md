# Stripe Checkout Image Debugging Guide

## Issue Report

When issuing a new batch, the cropped card image may not be appearing in the Stripe checkout page.

## Expected Behavior

When a user creates a new batch for a card:
1. The system should fetch the card's `image_url` (the cropped image)
2. Pass it to Stripe's checkout session
3. Display the card image in the Stripe checkout page

## Code Flow Analysis

### 1. Frontend - Creating Batch

**File**: `src/components/CardIssuanceCheckout.vue`

```javascript
// Lines 1033-1066
const createBatch = async () => {
  const formData = {
    cardCount: newBatch.value.cardCount
  }
  
  // Initiate payment without creating batch first
  await handlePayment(formData)
}

// Lines 1068-1090
const handlePayment = async (formData) => {
  await createCheckoutSession(formData.cardCount, 'pending-batch', {
    card_id: props.cardId,  // ← Card ID is passed here
    is_pending_batch: true
  })
}
```

### 2. Frontend - Stripe Checkout Utility

**File**: `src/utils/stripeCheckout.js`

```javascript
// Lines 29-58
export const createCheckoutSession = async (cardCount, batchId, metadata = {}) => {
  const { data, error } = await supabase.functions.invoke('create-checkout-session', {
    body: {
      cardCount,
      batchId,
      successUrl,
      cancelUrl,
      metadata  // ← Contains { card_id, is_pending_batch: true }
    }
  })
}
```

### 3. Edge Function - Fetching Card Data

**File**: `supabase/functions/create-checkout-session/index.ts`

```typescript
// Lines 80-112
if (metadata.is_pending_batch) {
  // Get card info for pending batch
  const { data: cardData, error: cardError } = await supabaseClient
    .rpc('get_card_by_id', {
      p_card_id: metadata.card_id  // ← Fetching card by ID
    })

  const card = cardData["0"] || cardData
  
  // Debug log (NEW)
  console.log('Card data for checkout:', {
    cardId: metadata.card_id,
    cardName: card.name,
    imageUrl: card.image_url,  // ← Should be the cropped image
    hasImage: !!card.image_url
  })
  
  batch = {
    card_name: card.name || 'CardStudio Experience',
    card_image_url: card.image_url,  // ← Assigning to batch
    batch_name: 'Auto-generated Batch'
  }
}
```

### 4. Edge Function - Creating Stripe Session

**File**: `supabase/functions/create-checkout-session/index.ts`

```typescript
// Lines 157-175
// Debug log (NEW)
console.log('Creating Stripe checkout with product data:', {
  productName: `Digital Cards - ${batch.card_name || 'CardStudio Experience'}`,
  description: `${cardCount} cards for ${batch.card_name}`,
  imageUrl: batch.card_image_url,  // ← Should be the cropped image URL
  fallbackImage: 'https://images.unsplash.com/...'
})

const checkoutSession = await stripe.checkout.sessions.create({
  payment_method_types: ['card'],
  mode: 'payment',
  line_items: [{
    price_data: {
      currency: 'usd',
      product_data: {
        name: `Digital Cards - ${batch.card_name || 'CardStudio Experience'}`,
        description: `${cardCount} cards for ${batch.card_name}`,
        images: [batch.card_image_url || 'https://images.unsplash.com/...']
        //      ↑ This should contain the cropped image URL
      },
      unit_amount: pricePerCard,
    },
    quantity: cardCount,
  }],
  ...
})
```

### 5. Database - get_card_by_id Function

**File**: `sql/storeproc/client-side/02_card_management.sql`

```sql
-- Lines 121-151
CREATE OR REPLACE FUNCTION get_card_by_id(p_card_id UUID)
RETURNS TABLE (
    id UUID,
    user_id UUID,
    name TEXT,
    description TEXT,
    qr_code_position TEXT,
    image_url TEXT,  -- ← Returns the cropped image URL
    conversation_ai_enabled BOOLEAN,
    ai_prompt TEXT,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ
) LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.id, 
        c.user_id,
        c.name, 
        c.description, 
        c.qr_code_position::TEXT,
        c.image_url,  -- ← From cards table
        c.conversation_ai_enabled,
        c.ai_prompt,
        c.created_at, 
        c.updated_at
    FROM cards c
    WHERE c.id = p_card_id;
END;
$$;
```

## Debugging Steps

### Step 1: Deploy Updated Edge Function

```bash
# Deploy the Edge Function with debug logs
supabase functions deploy create-checkout-session
```

### Step 2: Test Batch Creation

1. Go to a card's issuance page
2. Click "Issue New Batch"
3. Enter card count (e.g., 50)
4. Click "Create Batch & Pay"

### Step 3: Check Edge Function Logs

```bash
# View real-time logs
supabase functions logs create-checkout-session --follow

# Or view recent logs
supabase functions logs create-checkout-session
```

### Step 4: Verify Debug Output

Look for two console logs:

**Log 1 - Card Data**:
```json
{
  "cardId": "uuid-here",
  "cardName": "Your Card Name",
  "imageUrl": "https://your-supabase-project.supabase.co/storage/v1/object/public/userfiles/...",
  "hasImage": true
}
```

**Log 2 - Stripe Product Data**:
```json
{
  "productName": "Digital Cards - Your Card Name",
  "description": "50 cards for Your Card Name",
  "imageUrl": "https://your-supabase-project.supabase.co/storage/v1/object/public/userfiles/...",
  "fallbackImage": "https://images.unsplash.com/..."
}
```

### Step 5: Check Stripe Dashboard

1. Go to Stripe Dashboard → Products
2. Find the most recent product
3. Verify the image is displayed

## Possible Issues & Solutions

### Issue 1: `image_url` is `null` in logs

**Possible Causes**:
- Card doesn't have an image uploaded
- Card's `image_url` field is not set in database
- Recent card creation didn't save the cropped image

**Solution**:
1. Check database directly:
   ```sql
   SELECT id, name, image_url, original_image_url 
   FROM cards 
   WHERE id = 'your-card-id';
   ```
2. If `image_url` is null, re-edit the card and re-upload/crop the image

### Issue 2: `image_url` is present but Stripe shows fallback

**Possible Causes**:
- Image URL is not publicly accessible
- Image URL format is incorrect
- Stripe can't fetch the image (CORS, 404, etc.)

**Solution**:
1. Test the image URL directly in browser
2. Check Supabase storage bucket permissions
3. Verify the image URL format matches: `https://[project].supabase.co/storage/v1/object/public/userfiles/...`

### Issue 3: Image URL is correct but doesn't show in Stripe

**Possible Causes**:
- Stripe's image caching
- Image URL requires authentication
- Image format not supported by Stripe

**Solution**:
1. Ensure storage bucket is public
2. Check image format (JPEG/PNG preferred)
3. Verify image dimensions (Stripe recommends 1000×1000 minimum)
4. Try a different image

### Issue 4: Edge Function returns error

**Possible Causes**:
- `get_card_by_id` returns no data
- User doesn't have permission to access card
- RLS policy blocking access

**Solution**:
1. Check Edge Function error logs
2. Verify user is authenticated
3. Check RLS policies on `cards` table
4. Ensure `card_id` in metadata is correct

## Stripe Image Requirements

Stripe has specific requirements for product images:

### Format
- **Supported**: JPEG, PNG, GIF, SVG
- **Recommended**: JPEG or PNG
- **Max file size**: 5 MB

### Dimensions
- **Minimum**: 1000×1000 pixels (recommended)
- **Aspect ratio**: 1:1 (square) works best
- **Our cards**: 2:3 ratio (may appear letterboxed)

### URL Requirements
- Must be publicly accessible (no authentication)
- HTTPS required (HTTP not allowed)
- No redirects (direct URL to image file)
- Must be accessible from Stripe's servers

## Expected Behavior After Fix

### With Valid Image URL
```
┌─────────────────────────────────────┐
│ Stripe Checkout Page                │
├─────────────────────────────────────┤
│ ┌─────────────────────────────────┐ │
│ │                                  │ │
│ │   [Your Card Image]              │ │
│ │   (Cropped version from          │ │
│ │    cards.image_url)              │ │
│ │                                  │ │
│ └─────────────────────────────────┘ │
│                                      │
│ Digital Cards - Card Name            │
│ 50 cards for Card Name               │
│ $100.00                              │
│                                      │
│ [Pay Now Button]                     │
└─────────────────────────────────────┘
```

### With Fallback Image
```
┌─────────────────────────────────────┐
│ Stripe Checkout Page                │
├─────────────────────────────────────┤
│ ┌─────────────────────────────────┐ │
│ │                                  │ │
│ │   [Generic Card Image]           │ │
│ │   (Unsplash fallback)            │ │
│ │                                  │ │
│ └─────────────────────────────────┘ │
│                                      │
│ Digital Cards - Card Name            │
│ 50 cards for Card Name               │
│ $100.00                              │
│                                      │
│ [Pay Now Button]                     │
└─────────────────────────────────────┘
```

## Testing Checklist

- [ ] Deploy updated Edge Function
- [ ] Create new batch with card that has image
- [ ] Check Edge Function logs for card data
- [ ] Check Edge Function logs for Stripe product data
- [ ] Verify image URL is present in logs
- [ ] Verify image URL is publicly accessible
- [ ] Complete payment flow
- [ ] Check Stripe Dashboard for product image
- [ ] Test with card without image (should show fallback)
- [ ] Test with different image formats

## Additional Notes

### Image Storage Location

Cards store images in Supabase Storage:
- **Bucket**: `userfiles`
- **Path**: `cards/{user_id}/{filename}`
- **Accessibility**: Public (required for Stripe)

### Dual Image System

Cards maintain two images:
- **`image_url`**: Cropped/processed image (used in Stripe checkout)
- **`original_image_url`**: Raw uploaded image (used for re-cropping)

For Stripe checkout, we always use `image_url` (the cropped version) as it's the final, polished image that represents the card product.

## Status

✅ **Debug logs added** to Edge Function  
📋 **Ready for deployment** and testing  
🔍 **Awaiting** user to deploy and verify logs  

## Next Steps

1. Deploy the updated Edge Function
2. Test batch creation
3. Check logs for debug output
4. Report findings based on logs
5. Apply appropriate fix based on root cause

