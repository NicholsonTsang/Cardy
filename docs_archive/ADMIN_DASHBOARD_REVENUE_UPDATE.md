# Admin Dashboard Revenue Metrics Update

## Overview
Updated the admin dashboard revenue calculation to reflect the new credit-based payment system instead of legacy batch payments.

## Problem
The admin dashboard's "Revenue Analytics" section was displaying revenue from the old `batch_payments` table (legacy direct Stripe checkout per batch), which doesn't reflect the current credit-based system where:
1. Users purchase credits via Stripe (`credit_purchases` table)
2. Credits are consumed for batch issuance and translations (`credit_transactions` table)

## Solution
Updated the `admin_get_system_stats_enhanced()` stored procedure to calculate revenue from completed credit purchases instead of batch payments.

### Changes Made

**File: `sql/storeproc/client-side/11_admin_functions.sql`**

**Before (lines 293-296):**
```sql
-- Revenue metrics
(SELECT COALESCE(SUM(amount_cents), 0) FROM batch_payments WHERE payment_status = 'succeeded' AND created_at >= CURRENT_DATE) as daily_revenue_cents,
(SELECT COALESCE(SUM(amount_cents), 0) FROM batch_payments WHERE payment_status = 'succeeded' AND created_at >= CURRENT_DATE - INTERVAL '7 days') as weekly_revenue_cents,
(SELECT COALESCE(SUM(amount_cents), 0) FROM batch_payments WHERE payment_status = 'succeeded' AND created_at >= CURRENT_DATE - INTERVAL '30 days') as monthly_revenue_cents,
(SELECT COALESCE(SUM(amount_cents), 0) FROM batch_payments WHERE payment_status = 'succeeded') as total_revenue_cents,
```

**After:**
```sql
-- Revenue metrics (based on credit purchases, not legacy batch payments)
-- Note: amount_usd is in dollars, so multiply by 100 to get cents for consistency with old system
(SELECT COALESCE(SUM(amount_usd * 100), 0)::BIGINT FROM credit_purchases WHERE status = 'completed' AND created_at >= CURRENT_DATE) as daily_revenue_cents,
(SELECT COALESCE(SUM(amount_usd * 100), 0)::BIGINT FROM credit_purchases WHERE status = 'completed' AND created_at >= CURRENT_DATE - INTERVAL '7 days') as weekly_revenue_cents,
(SELECT COALESCE(SUM(amount_usd * 100), 0)::BIGINT FROM credit_purchases WHERE status = 'completed' AND created_at >= CURRENT_DATE - INTERVAL '30 days') as monthly_revenue_cents,
(SELECT COALESCE(SUM(amount_usd * 100), 0)::BIGINT FROM credit_purchases WHERE status = 'completed') as total_revenue_cents,
```

### Key Differences

1. **Source Table**: Changed from `batch_payments` to `credit_purchases`
2. **Status Field**: Changed from `payment_status = 'succeeded'` to `status = 'completed'`
3. **Amount Field**: Changed from `amount_cents` to `amount_usd * 100`
   - `batch_payments.amount_cents`: Stored in cents (integer)
   - `credit_purchases.amount_usd`: Stored in dollars (decimal), multiply by 100 to convert to cents
4. **Type Casting**: Added `::BIGINT` to ensure proper type matching with the function's RETURNS TABLE definition

## Deployment Instructions

### Option 1: Quick Deployment (Recommended)
Execute the single deployment file in Supabase Dashboard > SQL Editor:
```bash
# File: DEPLOY_ADMIN_DASHBOARD_REVENUE_FIX.sql
```

### Option 2: Full Deployment
If you're deploying all stored procedures:
```bash
# 1. Regenerate combined file (already done)
./scripts/combine-storeproc.sh

# 2. Execute in Supabase Dashboard > SQL Editor
# - sql/all_stored_procedures.sql
```

## Testing

### 1. Verify Function Creation
```sql
SELECT proname, pronargs, proretset 
FROM pg_proc 
WHERE proname = 'admin_get_system_stats_enhanced';
```

### 2. Check Credit Purchases Data
```sql
SELECT 
    COUNT(*) as total_purchases,
    COUNT(*) FILTER (WHERE status = 'completed') as completed_purchases,
    COALESCE(SUM(amount_usd) FILTER (WHERE status = 'completed'), 0) as total_revenue_usd
FROM credit_purchases;
```

### 3. Test the Dashboard
1. Log in as admin user
2. Navigate to Admin Dashboard (`/cms/admin`)
3. Check "Revenue Analytics" section shows correct values
4. Verify daily/weekly/monthly revenue matches credit purchase totals

## Impact

### Frontend
- ✅ **No changes required** - The dashboard store (`useAdminDashboardStore`) already calls the updated stored procedure
- ✅ **UI unchanged** - The `AdminDashboard.vue` component displays data in the same format

### Backend
- ✅ **Stored procedure updated** - Revenue now reflects actual credit purchases
- ✅ **Data accuracy improved** - Revenue matches the current business model

### Data Migration
- ✅ **No data migration needed** - This is a calculation change only
- ✅ **Historical data preserved** - Both `batch_payments` and `credit_purchases` tables remain intact

## Revenue Calculation Logic

### Credit-Based System (Current)
```
Daily Revenue = SUM(credit_purchases.amount_usd * 100) 
                WHERE status = 'completed' 
                AND created_at >= TODAY
```

**Example:**
- User purchases 100 credits for $100 USD
- Revenue recorded: 100 * 100 = 10,000 cents ($100.00)

### Legacy Batch Payment (Deprecated)
```
Daily Revenue = SUM(batch_payments.amount_cents) 
                WHERE payment_status = 'succeeded' 
                AND created_at >= TODAY
```

**Example:**
- User pays $200 for 100-card batch (2 credits/card × 100 cards)
- Revenue recorded: 20,000 cents ($200.00)

## Notes

1. **Backward Compatibility**: The `batch_payments` table is still used for legacy batches but not for revenue calculation
2. **Credit Pricing**: 1 credit = $1 USD (enforced at application level)
3. **Revenue Sources**:
   - Credit purchases (primary revenue source)
   - Batch issuance consumes credits (not direct revenue)
   - Translation services consume credits (not direct revenue)
4. **Data Format**: Revenue values stored as cents (BIGINT) for consistency with existing dashboard display logic

## Related Files
- `sql/storeproc/client-side/11_admin_functions.sql` - Source function
- `sql/all_stored_procedures.sql` - Generated combined file
- `src/stores/admin/dashboard.ts` - Dashboard store (no changes needed)
- `src/views/Dashboard/Admin/AdminDashboard.vue` - Admin dashboard UI (no changes needed)
- `DEPLOY_ADMIN_DASHBOARD_REVENUE_FIX.sql` - Deployment file

## References
- Credit System Documentation: See CLAUDE.md section "Payments & Credits"
- Credit Purchase Flow: `supabase/functions/create-credit-checkout-session/`
- Credit Webhook Handler: `supabase/functions/stripe-credit-webhook/`


