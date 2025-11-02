# 🗑️ Legacy Batch Payment System Removal

## Investigation Results

The legacy batch payment system (direct Stripe checkout for batches) is **NOT being used**.

### Current System (Active) ✅
- **Credit-Based Batch Issuance**: `issue_card_batch_with_credits()`
- **Used by**: `CardIssuanceCheckout.vue`
- **Pattern**: User purchases credits first → Uses credits to issue batches
- **No Stripe redirect**: Instant batch creation

### Legacy System (Unused) ❌
- **Direct Stripe Checkout**: `create-checkout-session` Edge Function
- **Used by**: Nothing! (No references in frontend)
- **Pattern**: Create batch → Redirect to Stripe → Confirm payment
- **Status**: Deprecated, superseded by credit system

---

## Files to Delete

### 1. Edge Functions
- ❌ `/supabase/functions/create-checkout-session/index.ts`
- ❌ `/supabase/functions/handle-checkout-success/index.ts`

### 2. Stored Procedures
- ❌ `/sql/storeproc/client-side/06_payment_management.sql` (entire file)
- Functions being deleted:
  - `create_batch_checkout_payment()`
  - `get_batch_for_checkout()`
  - `get_existing_batch_payment()`
  - `confirm_batch_payment_by_session()`
  - `create_pending_batch_payment()`
  - `confirm_pending_batch_payment()`

### 3. Frontend Utility Functions
- ❌ `createCheckoutSession()` from `src/utils/stripeCheckout.js`
- ❌ `handleCheckoutSuccess()` from `src/utils/stripeCheckout.js`
- ❌ `calculatePaymentAmount()` - Not used
- ❌ `calculateBatchCost()` - Not used

### 4. Database Tables (Keep - used by credit system)
- ✅ KEEP `batch_payments` table (still referenced by webhook)
- ✅ KEEP `card_batches` table (core functionality)

---

## Verification of Non-Usage

### Checked Locations
```bash
# No frontend usage found
grep -r "createCheckoutSession\|handleCheckoutSuccess" src/
# Result: No matches

# Credit system is used instead
grep -r "issueBatchWithCredits" src/
# Result: Found in CardIssuanceCheckout.vue ✅
```

### Why It's Safe to Delete
1. ✅ Frontend doesn't call these Edge Functions
2. ✅ Credit-based system is fully functional
3. ✅ No migration needed (already migrated)
4. ✅ Documented in CLAUDE.md as "legacy"

---

## Files Being Deleted

Total files to delete: **5 files + code sections**

---

## Safety Check

**Before deletion, verify**:
- [ ] No production batches using payment_method = 'stripe_checkout'
- [ ] All recent batches use payment_method = 'credits'
- [ ] No pending Stripe sessions waiting for confirmation

