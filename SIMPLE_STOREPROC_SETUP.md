# 🚀 Simple Stored Procedures Setup

## Quick Setup (3 Steps)

### 1. Set Database URL
```bash
# For local Supabase
export DATABASE_URL="postgresql://postgres:postgres@localhost:54322/postgres"

# For remote Supabase  
export DATABASE_URL="your_supabase_connection_string"
```

### 2. Run Deploy Script
```bash
cd /Users/user/CodeRepos/cardy/cardy-cms
./scripts/deploy-all-storeproc.sh
```

### 3. That's it! ✅

## Manual Deploy (if script fails)

```bash
# Deploy all client-side procedures
psql "$DATABASE_URL" -f sql/storeproc/*.sql

# Deploy server-side procedures
psql "$DATABASE_URL" -f sql/storeproc/server-side/*.sql
```

## Test Activation

```bash
# Quick test - replace with your card ID
psql "$DATABASE_URL" -c "SELECT * FROM get_public_card_content('your-issue-card-id');"
```

## Files That Get Deployed

**Client-side** (in `sql/storeproc/`):
- All `.sql` files for Vue app to call

**Server-side** (in `sql/storeproc/server-side/`):
- `05_payment_management.sql` - Stripe payment functions

## Troubleshooting

**Connection error?**
```bash
# Test connection
psql "$DATABASE_URL" -c "SELECT 1;"
```

**Which procedures exist?**
```bash
# List all functions
psql "$DATABASE_URL" -c "\df"
```