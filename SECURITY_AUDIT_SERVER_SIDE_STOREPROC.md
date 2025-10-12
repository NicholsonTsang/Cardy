# 🔒 Security Audit: Server-Side Stored Procedures

**Date**: 2025-10-11  
**Scope**: Server-side stored procedures and Edge Function integrations  
**Status**: ⚠️ **CRITICAL ISSUES FOUND**

---

## Executive Summary

✅ **GOOD**: Translation system properly secured  
❌ **CRITICAL**: Credit purchase completion has security vulnerabilities  
⚠️ **WARNING**: Webhook uses direct table access instead of stored procedures  

---

## 1. Translation Management (`translation_management.sql`)

### ✅ Security Status: **SECURE**

#### Function: `store_card_translations()`

**Parameters**:
```sql
p_user_id UUID,              -- Explicit user ID ✅
p_card_id UUID,              -- Target card
p_target_languages TEXT[],   -- Languages to translate
p_card_translations JSONB,   -- Translated content
p_content_items_translations JSONB,
p_credit_cost DECIMAL        -- Credits to consume
```

**Security Features**:
- ✅ **Authorization Check**: Validates card ownership before any action
  ```sql
  SELECT user_id INTO v_card_owner FROM cards WHERE id = p_card_id;
  IF v_card_owner != p_user_id THEN
    RAISE EXCEPTION 'Unauthorized: Card does not belong to user';
  END IF;
  ```

- ✅ **Credit Balance Check**: Verifies sufficient credits before operation
  ```sql
  SELECT check_credit_balance(p_credit_cost, p_user_id) INTO v_current_balance;
  ```

- ✅ **Atomic Operations**: All operations in single transaction
  - Update card translations
  - Update content item translations
  - Consume credits
  - Log to translation_history
  - All rolled back if any step fails

- ✅ **Proper Permissions**: 
  ```sql
  GRANT EXECUTE ON FUNCTION store_card_translations(...) TO service_role;
  ```

- ✅ **SQL Injection Protected**: All parameters properly typed (UUID, TEXT[], JSONB, DECIMAL)

- ✅ **Audit Trail**: Records to `translation_history` with metadata

**Edge Function Integration** (`translate-card-content/index.ts`):
```typescript
// 1. Validates JWT token
const { data: { user }, error } = await supabaseAdmin.auth.getUser(token);

// 2. Passes explicit user ID
await supabaseAdmin.rpc('store_card_translations', {
  p_user_id: user.id,  // ✅ Explicit parameter
  p_card_id: cardId,
  p_target_languages: targetLanguages,
  ...
});
```

**Verdict**: ✅ **NO ISSUES FOUND**

---

## 2. Credit Purchase Completion (`credit_purchase_completion.sql`)

### ❌ Security Status: **CRITICAL VULNERABILITIES**

#### Function: `complete_credit_purchase()`

**Parameters**:
```sql
p_stripe_session_id VARCHAR,       -- ❌ NO USER ID!
p_stripe_payment_intent_id VARCHAR,
p_receipt_url TEXT,
p_payment_method JSONB
```

**🚨 CRITICAL ISSUE #1: Missing User Validation**

The function does NOT accept `p_user_id` parameter and relies solely on:
```sql
SELECT id, user_id, credits_amount
FROM credit_purchases
WHERE stripe_session_id = p_stripe_session_id
  AND status = 'pending';
```

**Attack Vector**:
1. Attacker creates credit purchase with stripe_session_id = 'FAKE_SESSION'
2. Attacker calls webhook with same session ID
3. System grants credits without actual payment!

**Why This is Dangerous**:
- ❌ No verification that Stripe actually processed payment
- ❌ No verification of payment amount
- ❌ Webhook signature verification only happens in Edge Function
- ❌ If Edge Function is bypassed, anyone can call this

**🚨 CRITICAL ISSUE #2: Race Condition**

```sql
SELECT balance INTO v_current_balance
FROM user_credits
WHERE user_id = v_user_id
FOR UPDATE;  -- ✅ Lock is good, but...
```

**Problem**: Between when `credit_purchases` is queried and `user_credits` is locked, another transaction could:
1. Complete the same purchase
2. Grant duplicate credits
3. This transaction would succeed because there's no check for `status = 'completed'`

**🚨 CRITICAL ISSUE #3: No Amount Validation**

The function trusts `credits_amount` from database without:
- ❌ Verifying against Stripe payment amount
- ❌ Checking if amount matches expected value
- ❌ Preventing amount tampering

**Recommended Fixes**:

```sql
CREATE OR REPLACE FUNCTION complete_credit_purchase(
    p_user_id UUID,  -- ✅ ADD THIS
    p_stripe_session_id VARCHAR,
    p_stripe_payment_intent_id VARCHAR,
    p_amount_paid_cents INTEGER,  -- ✅ ADD THIS
    p_receipt_url TEXT DEFAULT NULL,
    p_payment_method JSONB DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
    v_purchase_id UUID;
    v_user_id_from_db UUID;
    v_credits_amount DECIMAL;
    v_expected_amount_cents INTEGER;
    v_current_balance DECIMAL;
    v_new_balance DECIMAL;
    v_transaction_id UUID;
BEGIN
    -- ✅ Lock the purchase record first
    SELECT id, user_id, credits_amount, status
    INTO v_purchase_id, v_user_id_from_db, v_credits_amount, v_purchase_status
    FROM credit_purchases
    WHERE stripe_session_id = p_stripe_session_id
    FOR UPDATE;  -- ✅ Prevent race conditions

    IF v_purchase_id IS NULL THEN
        RAISE EXCEPTION 'Credit purchase not found: %', p_stripe_session_id;
    END IF;

    -- ✅ Verify user ID matches
    IF v_user_id_from_db != p_user_id THEN
        RAISE EXCEPTION 'User ID mismatch. Expected: %, Provided: %', 
            v_user_id_from_db, p_user_id;
    END IF;

    -- ✅ Check if already processed
    IF v_purchase_status != 'pending' THEN
        RAISE EXCEPTION 'Purchase already processed with status: %', v_purchase_status;
    END IF;

    -- ✅ Verify payment amount (1 credit = $1 = 100 cents)
    v_expected_amount_cents := (v_credits_amount * 100)::INTEGER;
    IF p_amount_paid_cents != v_expected_amount_cents THEN
        RAISE EXCEPTION 'Amount mismatch. Expected: % cents, Paid: % cents', 
            v_expected_amount_cents, p_amount_paid_cents;
    END IF;

    -- Rest of function...
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION complete_credit_purchase(UUID, VARCHAR, VARCHAR, INTEGER, TEXT, JSONB) TO service_role;
```

**Edge Function Fix** (`stripe-credit-webhook/index.ts`):

```typescript
const { data: result, error } = await supabase.rpc('complete_credit_purchase', {
  p_user_id: userId,  // ✅ Add user ID
  p_stripe_session_id: session.id,
  p_stripe_payment_intent_id: paymentIntent?.id || null,
  p_amount_paid_cents: session.amount_total,  // ✅ Verify amount
  p_receipt_url: receiptUrl,
  p_payment_method: { type: paymentIntent?.payment_method_types?.[0] || 'card' }
});
```

---

## 3. Refund Credit Purchase (`refund_credit_purchase()`)

### ⚠️ Security Status: **MEDIUM RISK**

**Parameters**:
```sql
p_purchase_id UUID,        -- ❌ No user ID!
p_refund_amount DECIMAL,
p_reason TEXT
```

**Issues**:

1. **❌ No User Authorization Check**
   ```sql
   SELECT user_id, credits_amount, status
   INTO v_user_id, v_credits_amount, v_purchase_status
   FROM credit_purchases
   WHERE id = p_purchase_id;
   ```
   
   **Problem**: Anyone with service_role access can refund any user's purchase!

2. **⚠️ Partial Fix Needed**:
   ```sql
   -- Current
   IF v_current_balance < p_refund_amount THEN
     RAISE EXCEPTION 'Insufficient credits for refund...';
   END IF;
   ```
   
   **Good**: Prevents negative balance  
   **Missing**: Should also check if refund amount > original purchase amount

**Recommended Fix**:

```sql
CREATE OR REPLACE FUNCTION refund_credit_purchase(
    p_user_id UUID,  -- ✅ ADD THIS
    p_purchase_id UUID,
    p_refund_amount DECIMAL,
    p_reason TEXT DEFAULT 'Customer requested refund'
)
RETURNS JSONB AS $$
DECLARE
    v_user_id_from_db UUID;
    v_credits_amount DECIMAL;
    v_purchase_status VARCHAR;
BEGIN
    -- Lock and verify purchase
    SELECT user_id, credits_amount, status
    INTO v_user_id_from_db, v_credits_amount, v_purchase_status
    FROM credit_purchases
    WHERE id = p_purchase_id
    FOR UPDATE;

    IF v_user_id_from_db IS NULL THEN
        RAISE EXCEPTION 'Credit purchase not found: %', p_purchase_id;
    END IF;

    -- ✅ Verify user authorization
    IF v_user_id_from_db != p_user_id THEN
        RAISE EXCEPTION 'User ID mismatch. Expected: %, Provided: %', 
            v_user_id_from_db, p_user_id;
    END IF;

    -- Rest of function...
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

---

## 4. Webhook Security (`stripe-credit-webhook/index.ts`)

### ⚠️ Security Status: **NEEDS IMPROVEMENT**

**Current Implementation**:

```typescript
// ✅ Good: Verifies webhook signature
const signature = req.headers.get('stripe-signature');
event = await stripe.webhooks.constructEventAsync(body, signature, webhookSecret);

// ❌ Bad: Direct table access
const { data: purchases, error: findError } = await supabase
  .from('credit_purchases')  // ❌ Direct table access!
  .select('id, credits_amount')
  .eq('stripe_payment_intent_id', charge.payment_intent)
  .single();

// ⚠️ Calls stored procedure but without proper validation
await supabase.rpc('complete_credit_purchase', {
  p_stripe_session_id: session.id,  // ❌ No user ID!
  // ❌ No amount verification!
});
```

**Issues**:

1. **❌ Inconsistent Pattern**: Uses direct table access (`supabase.from()`) instead of stored procedures
2. **❌ Missing User Context**: Doesn't extract user ID from session metadata
3. **❌ No Amount Verification**: Doesn't verify payment amount matches expected
4. **⚠️ Race Condition Possible**: Multiple webhooks could trigger duplicate processing

**Recommended Fix**:

```typescript
case 'checkout.session.completed': {
  const session = event.data.object as Stripe.Checkout.Session;
  
  if (session.metadata?.type !== 'credit_purchase') {
    return new Response(JSON.stringify({ received: true }), { status: 200 });
  }

  const fullSession = await stripe.checkout.sessions.retrieve(session.id, {
    expand: ['payment_intent', 'line_items']
  });

  const paymentIntent = fullSession.payment_intent as Stripe.PaymentIntent;
  const receiptUrl = paymentIntent?.charges?.data?.[0]?.receipt_url || null;
  
  // ✅ Extract user ID from session metadata
  const userId = session.metadata?.user_id;
  if (!userId) {
    throw new Error('User ID not found in session metadata');
  }

  // ✅ Verify amount
  const amountPaidCents = session.amount_total;
  
  // ✅ Call stored procedure with full validation
  const { error } = await supabase.rpc('complete_credit_purchase', {
    p_user_id: userId,
    p_stripe_session_id: session.id,
    p_stripe_payment_intent_id: paymentIntent?.id || null,
    p_amount_paid_cents: amountPaidCents,
    p_receipt_url: receiptUrl,
    p_payment_method: {
      type: paymentIntent?.payment_method_types?.[0] || 'card'
    }
  });

  if (error) {
    console.error('Error completing credit purchase:', error);
    throw error;
  }
  break;
}
```

---

## 5. Payment Management (`05_payment_management.sql`)

### ✅ Security Status: **MOSTLY SECURE**

**Functions Reviewed**:
- `create_batch_checkout_payment()` ✅
- `get_batch_for_checkout()` ✅
- `get_existing_batch_payment()` ✅
- `confirm_batch_payment_by_session()` ✅
- `create_pending_batch_payment()` ✅
- `confirm_pending_batch_payment()` ✅

**Security Features**:
- ✅ All functions use `auth.uid()` for authorization
- ✅ Proper ownership verification
- ✅ Amount validation against expected values
- ✅ Duplicate payment prevention
- ✅ `FOR UPDATE` locks on critical operations
- ✅ `SECURITY DEFINER` with proper validation

**No critical issues found** - these are client-side procedures called with user JWT.

---

## Summary of Security Issues

| Function | Severity | Issue | Status |
|----------|----------|-------|--------|
| `store_card_translations()` | ✅ None | Properly secured | Pass |
| `complete_credit_purchase()` | 🚨 Critical | Missing user ID validation | **Fix Required** |
| `complete_credit_purchase()` | 🚨 Critical | No amount verification | **Fix Required** |
| `complete_credit_purchase()` | 🚨 Critical | Race condition possible | **Fix Required** |
| `refund_credit_purchase()` | ⚠️ Medium | No user authorization | **Fix Required** |
| `stripe-credit-webhook` | ⚠️ Medium | Direct table access | **Fix Required** |
| `stripe-credit-webhook` | ⚠️ Medium | Missing validation | **Fix Required** |
| Payment Management | ✅ None | Properly secured | Pass |

---

## Recommendations

### Immediate Actions (Critical)

1. **Fix `complete_credit_purchase()`**:
   - Add `p_user_id` parameter
   - Add `p_amount_paid_cents` parameter
   - Add user ID validation
   - Add amount verification
   - Add status check before processing

2. **Fix `stripe-credit-webhook`**:
   - Extract user ID from session metadata
   - Verify payment amount
   - Remove direct table access
   - Use updated stored procedure

3. **Fix `refund_credit_purchase()`**:
   - Add `p_user_id` parameter
   - Add user authorization check
   - Add FOR UPDATE lock

### Best Practices to Follow

✅ **DO**:
- Accept explicit `p_user_id` for all server-side functions
- Validate user authorization against database records
- Verify payment amounts match expected values
- Use `FOR UPDATE` locks for critical operations
- Add status checks to prevent duplicate processing
- Use stored procedures consistently (no direct table access)
- Log all operations with metadata

❌ **DON'T**:
- Trust parameters without validation
- Skip amount verification
- Allow race conditions
- Use direct table access from Edge Functions
- Process payments without user verification
- Skip duplicate payment checks

---

## Testing Checklist

After fixes are deployed:

- [ ] Test translation with valid user
- [ ] Test translation with wrong user (should fail)
- [ ] Test translation with insufficient credits (should fail)
- [ ] Test credit purchase completion
- [ ] Test duplicate purchase prevention
- [ ] Test amount mismatch detection
- [ ] Test refund with valid user
- [ ] Test refund with wrong user (should fail)
- [ ] Test webhook with valid signature
- [ ] Test webhook with invalid signature (should fail)
- [ ] Test race condition scenarios

---

## Files Requiring Updates

1. ✅ `/sql/storeproc/server-side/translation_management.sql` - No changes needed
2. ❌ `/sql/storeproc/server-side/credit_purchase_completion.sql` - **REQUIRES FIX**
3. ❌ `/supabase/functions/stripe-credit-webhook/index.ts` - **REQUIRES FIX**
4. ❌ Create deployment script: `DEPLOY_CREDIT_SECURITY_FIX.sql`

---

**Audited by**: Claude AI  
**Next Review**: After security fixes are deployed

