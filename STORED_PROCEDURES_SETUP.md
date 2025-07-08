# 🗄️ Stored Procedures Setup Guide

This guide shows how to deploy all stored procedures to your Supabase database.

## 📋 Prerequisites

### 1. Install PostgreSQL Client Tools
```bash
# macOS (with Homebrew)
brew install postgresql

# Ubuntu/Debian
sudo apt-get install postgresql-client

# Windows (with Chocolatey)
choco install postgresql
```

### 2. Get Your Database URL

#### For Local Supabase:
```bash
# Start local Supabase
supabase start

# Get local database URL
supabase status
# Look for "DB URL" in the output
export DATABASE_URL="postgresql://postgres:postgres@localhost:54322/postgres"
```

#### For Remote Supabase:
1. Go to your [Supabase Dashboard](https://app.supabase.com)
2. Navigate to **Settings** → **Database**
3. Copy the **Connection string** under "Connection pooling"
4. Replace `[YOUR-PASSWORD]` with your actual database password

```bash
export DATABASE_URL="postgresql://postgres.[PROJECT-REF]:[YOUR-PASSWORD]@aws-0-[region].pooler.supabase.com:5432/postgres"
```

### 3. Test Database Connection
```bash
psql "$DATABASE_URL" -c "SELECT version();"
```

## 🚀 Deployment Methods

### Method 1: Automated Script (Recommended)

#### Quick Deploy:
```bash
# Navigate to project root
cd /path/to/cardy-cms

# Make script executable (if not already)
chmod +x scripts/deploy-storeproc.sh

# Deploy all stored procedures
./scripts/deploy-storeproc.sh
```

#### Deploy with Verification:
```bash
# Deploy and verify functions exist
./scripts/deploy-storeproc.sh --verify
```

### Method 2: Manual Deployment

Deploy stored procedures in the correct order:

```bash
# Navigate to project root
cd /path/to/cardy-cms

# Deploy each file in order
psql "$DATABASE_URL" -f sql/storeproc/01_card_management.sql
psql "$DATABASE_URL" -f sql/storeproc/02_content_management.sql
psql "$DATABASE_URL" -f sql/storeproc/03_user_management.sql
psql "$DATABASE_URL" -f sql/storeproc/04_batch_management.sql
psql "$DATABASE_URL" -f sql/storeproc/05_payment_management.sql
psql "$DATABASE_URL" -f sql/storeproc/06_print_requests.sql
psql "$DATABASE_URL" -f sql/storeproc/07_public_access.sql
psql "$DATABASE_URL" -f sql/storeproc/08_admin_batch_operations.sql
psql "$DATABASE_URL" -f sql/storeproc/09_user_analytics.sql
psql "$DATABASE_URL" -f sql/storeproc/10_admin_user_management.sql
psql "$DATABASE_URL" -f sql/storeproc/11_admin_functions.sql
```

### Method 3: Supabase CLI (Local Only)

```bash
# Reset and apply all migrations
supabase db reset --local

# Or apply specific files
supabase db push --local
```

## ✅ Verification

### 1. List All Custom Functions
```bash
psql "$DATABASE_URL" -c "
SELECT proname as function_name, pronargs as num_args 
FROM pg_proc 
WHERE pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public') 
  AND prokind = 'f' 
ORDER BY proname;"
```

### 2. Test Key Functions
```bash
# Test card management
psql "$DATABASE_URL" -c "SELECT 'get_card_by_id exists' WHERE EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'get_card_by_id');"

# Test batch management
psql "$DATABASE_URL" -c "SELECT 'issue_card_batch exists' WHERE EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'issue_card_batch');"

# Test public access
psql "$DATABASE_URL" -c "SELECT 'get_public_card_content exists' WHERE EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'get_public_card_content');"
```

### 3. Test with Sample Data
```bash
# Create a test card and try functions (replace with actual IDs)
psql "$DATABASE_URL" -c "SELECT * FROM get_card_by_id('your-card-id');"
```

## 🔧 Troubleshooting

### Common Issues:

#### 1. **Connection Refused**
```bash
# Check if DATABASE_URL is correct
echo $DATABASE_URL

# Test basic connection
psql "$DATABASE_URL" -c "SELECT 1;"
```

#### 2. **Permission Denied**
```bash
# For local Supabase, make sure it's running
supabase status

# For remote Supabase, check your password
psql "$DATABASE_URL" -c "SELECT current_user;"
```

#### 3. **Function Dependencies**
If you get dependency errors, make sure files are executed in the correct order:
1. Card management → Content management → User management
2. Batch management → Payment management → Print requests
3. Public access → Admin functions → User analytics

#### 4. **SSL Issues (Remote Supabase)**
If you get SSL errors, add `?sslmode=require` to your DATABASE_URL:
```bash
export DATABASE_URL="your-connection-string?sslmode=require"
```

### Debug Individual Files:
```bash
# Test single file with verbose output
psql "$DATABASE_URL" -f sql/storeproc/07_public_access.sql -v ON_ERROR_STOP=1 -a
```

### View Deployment Logs:
```bash
# Run with detailed output
./scripts/deploy-storeproc.sh 2>&1 | tee deployment.log
```

## 📁 File Structure

```
sql/
├── storeproc/
│   ├── 01_card_management.sql      # Card CRUD operations
│   ├── 02_content_management.sql   # Content items management
│   ├── 03_user_management.sql      # User profiles & verification
│   ├── 04_batch_management.sql     # Card batches & issuance
│   ├── 05_payment_management.sql   # Stripe payment handling
│   ├── 06_print_requests.sql       # Physical card printing
│   ├── 07_public_access.sql        # Public card access (activation)
│   ├── 08_admin_batch_operations.sql # Admin batch operations
│   ├── 09_user_analytics.sql       # User statistics & analytics
│   ├── 10_admin_user_management.sql # Admin user management
│   └── 11_admin_functions.sql      # General admin functions
├── migrations/
│   └── 007_remove_activation_codes.sql # Schema migration
└── scripts/
    └── deploy-storeproc.sh         # Deployment script
```

## 🎯 Quick Commands Reference

```bash
# Full deployment
./scripts/deploy-storeproc.sh

# Deploy with verification
./scripts/deploy-storeproc.sh --verify

# Test activation function
psql "$DATABASE_URL" -c "SELECT * FROM get_public_card_content('your-issue-card-id');"

# Check function exists
psql "$DATABASE_URL" -c "SELECT proname FROM pg_proc WHERE proname = 'get_public_card_content';"

# View function definition
psql "$DATABASE_URL" -c "\df+ get_public_card_content"
```

## 🔄 Re-deployment

To update stored procedures after changes:

```bash
# Method 1: Re-run the script
./scripts/deploy-storeproc.sh

# Method 2: Deploy specific file
psql "$DATABASE_URL" -f sql/storeproc/07_public_access.sql

# Method 3: Full reset (local only)
supabase db reset --local
```

---

## 🎉 Success!

After successful deployment, your Cardy CMS will have all stored procedures ready for:
- ✅ Card management and content
- ✅ User authentication and verification  
- ✅ Batch creation and payment processing
- ✅ Public card access with automatic activation
- ✅ Admin functions and analytics
- ✅ Print request management

The activation issue should now be resolved with the updated `get_public_card_content()` function!