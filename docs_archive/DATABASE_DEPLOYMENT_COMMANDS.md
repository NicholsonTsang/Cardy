# Database Deployment Commands

## 🚨 Current Issue
The `create_pending_batch_payment` function is missing from your database. You need to deploy the new stored procedures.

## 📋 Quick Deployment Steps

### **Option 1: Deploy All Stored Procedures (Recommended)**
```bash
# Deploy all stored procedures at once
psql -U your_username -d your_database_name -f sql/all_stored_procedures.sql
```

### **Option 2: Deploy Individual Files**
```bash
# Deploy schema changes first
psql -U your_username -d your_database_name -f sql/schema.sql

# Deploy server-side payment functions
psql -U your_username -d your_database_name -f sql/storeproc/server-side/05_payment_management.sql

# Deploy client-side payment functions  
psql -U your_username -d your_database_name -f sql/storeproc/client-side/05_payment_management_client.sql
```

### **Option 3: Deploy via Supabase CLI (if using Supabase)**
```bash
# Apply migrations
npx supabase db push

# Or reset and apply all
npx supabase db reset
```

## 🔍 Verify Deployment

After running the deployment, verify the function exists:

```sql
-- Check if function exists
SELECT 
    routine_name, 
    routine_type,
    specific_name
FROM information_schema.routines 
WHERE routine_name = 'create_pending_batch_payment'
AND routine_schema = 'public';

-- Check function signature
\df create_pending_batch_payment
```

Expected output should show:
```
 routine_name                | routine_type | specific_name
 create_pending_batch_payment| FUNCTION     | create_pending_batch_payment_...
```

## 🎯 What Should Happen

After successful deployment:
1. ✅ `create_pending_batch_payment` function will exist in database
2. ✅ `confirm_pending_batch_payment` function will exist in database  
3. ✅ `get_pending_batch_payment_info` function will exist in database
4. ✅ `batch_payments` table will have new columns (`card_id`, `batch_name`, `cards_count`)
5. ✅ Edge Functions will be able to call these functions successfully

## ⚠️ Important Notes

- **Replace `your_username` and `your_database_name`** with your actual database credentials
- **Run these commands from the project root directory** (`/Users/user/CodeRepos/cardy/cardy-cms`)
- **The functions MUST be deployed before testing the payment flow**
- **Schema changes are included in the deployment files**

## 🚀 Test After Deployment

Once deployed, try the payment flow again:
1. Go to card issuance page
2. Click "Pay & Issue"
3. The Edge Function should successfully create a pending payment record
4. Complete payment in Stripe
5. Batch should be created automatically

The error `"Could not find the function public.create_pending_batch_payment"` will disappear once the function is properly deployed to your database.
