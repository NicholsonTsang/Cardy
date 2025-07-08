# Server-Side Stored Procedures

This folder contains stored procedures that are primarily called by server-side operations like Edge Functions and should be deployed to the Supabase server.

## Files in this folder:

### `05_payment_management.sql`
- **Purpose**: Stripe Checkout processing functions for Edge Functions
- **Called by**: Edge Functions (`create-checkout-session`, `handle-checkout-success`)
- **Functions**:
  - `create_batch_checkout_payment()` - Create payment record for Stripe Checkout sessions
  - `confirm_batch_payment_by_session()` - Confirm payment by checkout session ID


## Deployment

### Production Deployment
```bash
# Deploy to production Supabase instance
psql "your_production_database_url" -f sql/storeproc/server-side/execute_server_side.sql
```

### Local Development
```bash
# Deploy to local Supabase instance
psql "$(supabase status -o env | grep DATABASE_URL | cut -d'=' -f2-)" -f sql/storeproc/server-side/execute_server_side.sql
```

### Via Supabase Dashboard
1. Go to your Supabase project dashboard
2. Navigate to **SQL Editor**
3. Copy and paste the contents of `execute_server_side.sql`
4. Click **Run**

## Important Notes

⚠️ **Server-side functions must be deployed before Edge Functions that depend on them**

⚠️ **These functions handle sensitive operations like payments and should be thoroughly tested**

⚠️ **Always deploy to staging environment first before production**