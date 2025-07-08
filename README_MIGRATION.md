# Database Migration Instructions

## Migration: Cleanup Batch Payments Table

This migration removes unused fields from the `batch_payments` table and adjusts constraints for Stripe Checkout integration.

### Changes:
1. Removed unused columns:
   - `stripe_client_secret` (only for old Stripe Elements)
   - `stripe_customer_id` (not being used)
   - `completed_at` (using `payment_completed_at` in card_batches instead)

2. Made `stripe_payment_intent_id` nullable (required for Stripe test mode)
3. Made `stripe_checkout_session_id` required (primary identifier)

### To Apply Migration:

#### Option 1: Full Database Reset (Recommended for Development)
```bash
supabase db reset
```

#### Option 2: Apply Migration Only
```bash
# Local development
psql "$(supabase status -o env | grep DATABASE_URL | cut -d'=' -f2-)" -f sql/migrations/001_cleanup_batch_payments.sql

# Then update stored procedures
psql "$(supabase status -o env | grep DATABASE_URL | cut -d'=' -f2-)" -f sql/storeproc/server-side/execute_server_side.sql
```

#### Option 3: Via Supabase Dashboard
1. Go to SQL Editor in Supabase Dashboard
2. Run the migration script from `sql/migrations/001_cleanup_batch_payments.sql`
3. Then run the server-side stored procedures from `sql/storeproc/server-side/execute_server_side.sql`

### Edge Function Updates:
The `create-checkout-session` Edge Function has been updated to handle null `payment_intent_id` in test mode by using the checkout session ID as a fallback.

### Removed Legacy Functions:
- Deleted unused Edge Functions: `create-payment-intent`, `confirm-payment`, `test-stripe`, `exec-sql`
- These were part of the old Stripe Elements integration and are no longer needed