# Billing & Subscription System

This document covers the subscription tiers, session-based pricing, Stripe integration, and credit system.

## Subscription Tiers

### Tier Comparison

| Feature | Free | Starter | Premium |
|---------|------|---------|---------|
| **Price** | $0/month | $40/month | $280/month |
| **Projects** | 3 | 5 | 35 |
| **Session Budget** | 50 sessions | $40/month | $280/month |
| **AI Session Cost** | N/A | $0.05 | $0.04 |
| **Non-AI Session Cost** | N/A | $0.025 | $0.02 |
| **Included AI Sessions** | 50 total | ~800 | ~7,000 |
| **Included Non-AI Sessions** | 50 total | ~1,600 | ~14,000 |
| **Translations** | No | 2 languages | Unlimited |
| **Overage Purchase** | No | Yes | Yes |
| **Branding** | FunTell | FunTell | White label |

### Session-Based Pricing Model

Paid tiers use a **budget-based** model rather than fixed session counts:

1. User has monthly USD budget ($40 Starter, $280 Premium)
2. Each visitor session deducts from budget based on project type:
   - **AI-enabled projects**: Higher cost per session
   - **Non-AI projects**: Lower cost per session
3. When budget exhausted, auto top-up available

**Example (Premium):**
- Budget: $280/month
- Mix: 3,500 AI sessions ($0.04 × 3,500 = $140) + 7,000 non-AI sessions ($0.02 × 7,000 = $140)
- Total: $280 consumed

## Configuration

### Backend Configuration

Located at `backend-server/src/config/subscription.ts`:

```typescript
export const SubscriptionConfig = {
  free: {
    experienceLimit: 3,
    monthlySessionLimit: 50,
    translationsEnabled: false,
  },
  starter: {
    monthlyFeeUsd: 40,
    experienceLimit: 5,
    aiEnabledSessionCostUsd: 0.05,
    aiDisabledSessionCostUsd: 0.025,
    monthlyBudgetUsd: 40,
    translationsEnabled: true,
    maxLanguages: 2,
  },
  premium: {
    monthlyFeeUsd: 280,
    experienceLimit: 35,
    aiEnabledSessionCostUsd: 0.04,
    aiDisabledSessionCostUsd: 0.02,
    monthlyBudgetUsd: 280,
    translationsEnabled: true,
    maxLanguages: -1, // Unlimited
  },
  overage: {
    creditsPerBatch: 5, // $5 per top-up
  },
};
```

### Environment Variable Overrides

All values can be overridden via environment variables:

```env
# Free tier
FREE_TIER_EXPERIENCE_LIMIT=3
FREE_TIER_MONTHLY_SESSION_LIMIT=50

# Starter tier
STARTER_MONTHLY_FEE_USD=40
STARTER_EXPERIENCE_LIMIT=5
STARTER_AI_ENABLED_SESSION_COST_USD=0.05
STARTER_AI_DISABLED_SESSION_COST_USD=0.025
STARTER_MONTHLY_BUDGET_USD=40

# Premium tier
PREMIUM_MONTHLY_FEE_USD=280
PREMIUM_EXPERIENCE_LIMIT=35
PREMIUM_AI_ENABLED_SESSION_COST_USD=0.04
PREMIUM_AI_DISABLED_SESSION_COST_USD=0.02
PREMIUM_MONTHLY_BUDGET_USD=280

# Overage
OVERAGE_CREDITS_PER_BATCH=5

# Session tracking
SESSION_EXPIRATION_SECONDS=1800
SESSION_DEDUP_WINDOW_SECONDS=300
```

## Session Tracking

### Architecture

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  Mobile Client  │────▶│  Backend API    │────▶│  Upstash Redis  │
│  (Visitor)      │     │  (Express)      │     │  (Source of     │
└─────────────────┘     └─────────────────┘     │   Truth)        │
                               │                └─────────────────┘
                               │
                               ▼
                        ┌─────────────────┐
                        │   PostgreSQL    │
                        │  (Metadata &    │
                        │   Audit Logs)   │
                        └─────────────────┘
```

### Redis Keys

| Key Pattern | Purpose | TTL |
|-------------|---------|-----|
| `budget:user:{userId}:month:{YYYY-MM}` | Remaining budget (USD cents) | End of month |
| `session:dedup:{sessionId}:{cardId}` | Prevent duplicate billing | 5 minutes |
| `tier:user:{userId}` | Cached tier for fast lookup | 1 hour |

### Session Flow

1. Visitor scans QR code
2. Backend receives request with `sessionId` (from cookie/fingerprint)
3. Check dedup key - if exists, skip billing
4. Determine session cost based on project AI setting and user tier
5. Decrement user budget atomically in Redis
6. If budget exhausted and overage enabled, consume from purchased credits
7. Log session to PostgreSQL for analytics

### Deduplication

Sessions are deduplicated within a 5-minute window:

```typescript
const dedupKey = `session:dedup:${sessionId}:${cardId}`
const isNew = await redis.setnx(dedupKey, '1')
if (isNew) {
  await redis.expire(dedupKey, 300) // 5 min TTL
  // Bill the session
}
```

## Stripe Integration

### Webhook Events

Handled at `POST /api/webhooks/stripe`:

| Event | Action |
|-------|--------|
| `checkout.session.completed` | Create/update subscription, process credit purchase |
| `customer.subscription.updated` | Sync tier changes, handle upgrades/downgrades |
| `customer.subscription.deleted` | Revert to free tier |
| `invoice.paid` | Reset monthly budget, log payment |
| `invoice.payment_failed` | Mark subscription at risk |

### Subscription Lifecycle

**New Subscription:**
```
User → Checkout → Stripe → Webhook → Create subscription record → Set Redis tier
```

**Upgrade (Starter → Premium):**
```
User → Checkout → Stripe cancels old immediately → New sub starts → Webhook updates tier
```

**Downgrade (Premium → Starter):**
```
User → Checkout → Old sub set to cancel at period end → New sub starts with trial
→ User keeps Premium until period end → Then switches to Starter
```

**Cancellation:**
```
User → Cancel → Set cancel_at_period_end → User keeps access until period end
→ Webhook on period end → Revert to free tier
```

### Stored Procedures

Server-side procedures for billing (backend only):

| Procedure | Purpose |
|-----------|---------|
| `get_subscription_by_user_server` | Fetch user's subscription |
| `cancel_subscription_server` | Update cancellation status |
| `update_subscription_cancel_status_server` | Reactivate subscription |
| `get_subscription_stripe_customer_server` | Get Stripe customer ID |

## Credit/Overage System

### How Credits Work

1. User purchases credits via Stripe one-time payment
2. Credits stored in `credit_purchases` table
3. When monthly budget exhausted, system checks for available credits
4. Credits consumed in $5 batches (configurable)

### Credit Purchase Flow

```typescript
// Backend creates Stripe checkout
const session = await stripe.checkout.sessions.create({
  mode: 'payment', // One-time, not subscription
  line_items: [{
    price_data: {
      currency: 'usd',
      product_data: { name: 'FunTell Credits' },
      unit_amount: amount * 100 // cents
    },
    quantity: 1
  }],
  metadata: {
    user_id: userId,
    type: 'credit_purchase',
    credit_amount: amount.toString()
  }
})
```

### Credit Consumption

When budget runs out:

```typescript
// Check for available credits
const { data: credits } = await supabase.rpc('get_available_credits_server', {
  p_user_id: userId
})

if (credits >= sessionCost) {
  // Consume credits
  await supabase.rpc('consume_credits_server', {
    p_user_id: userId,
    p_amount: sessionCost
  })
}
```

## Frontend Store

The `useSubscriptionStore` (`src/stores/subscription.ts`) manages:

- Subscription state and tier
- Usage statistics
- Checkout flows
- Cancellation/reactivation

### Key Computed Properties

```typescript
const tier = computed(() => subscription.value?.tier ?? 'free')
const isPaid = computed(() => tier.value === 'starter' || tier.value === 'premium')
const canTranslate = computed(() => subscription.value?.features?.translations_enabled)
const canBuyOverage = computed(() => isPaid.value)
const monthlyAccessRemaining = computed(() => subscription.value?.monthly_access_remaining ?? 0)
```

### Key Actions

```typescript
// Fetch subscription details
await subscriptionStore.fetchSubscription()

// Create checkout for subscription
const { url } = await subscriptionStore.createCheckout('premium')
window.location.href = url

// Cancel subscription
await subscriptionStore.cancelSubscription(immediate: false)

// Buy credits
const { url } = await subscriptionStore.buyCredits(50)
window.location.href = url
```

## Usage Analytics

### Daily Stats Endpoint

`GET /api/subscriptions/daily-stats?days=30` returns:

```json
{
  "period": { "start": "2024-01-01", "end": "2024-01-30", "days": 30 },
  "data": [
    {
      "date": "2024-01-15",
      "total": 150,
      "ai_sessions": 80,
      "non_ai_sessions": 70,
      "ai_cost_usd": 3.20,
      "non_ai_cost_usd": 1.40
    }
  ],
  "summary": {
    "total_access": 4500,
    "ai_sessions": 2000,
    "non_ai_sessions": 2500,
    "total_cost_usd": 130.00
  }
}
```

### Flush Before Query

Access logs are buffered in Redis for performance. Before fetching stats:

```typescript
await flushAccessLogBuffer() // Flush to PostgreSQL
const stats = await getStatsFromDatabase()
```

## Testing Billing

### Test Cards (Stripe Test Mode)

| Card Number | Behavior |
|-------------|----------|
| 4242424242424242 | Successful payment |
| 4000000000000341 | Attaches, fails on charge |
| 4000000000009995 | Insufficient funds |

### Webhook Testing

```bash
# Forward webhooks locally
stripe listen --forward-to localhost:3001/api/webhooks/stripe

# Trigger test events
stripe trigger checkout.session.completed
```
