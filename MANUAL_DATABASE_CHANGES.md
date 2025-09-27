# Manual Database Changes for Payment-First Flow

## ✅ Schema and Stored Procedure Changes Applied

I've updated the schema and stored procedure files directly. You'll need to manually apply these changes to your database.

## 📋 Database Changes Required

### 1. **Schema Changes (Apply to `batch_payments` table)**

```sql
-- Add new columns for pending batch payments
ALTER TABLE batch_payments 
ADD COLUMN IF NOT EXISTS card_id UUID REFERENCES cards(id) ON DELETE CASCADE,
ADD COLUMN IF NOT EXISTS batch_name TEXT,
ADD COLUMN IF NOT EXISTS cards_count INTEGER;

-- Make batch_id nullable (if not already)
ALTER TABLE batch_payments 
ALTER COLUMN batch_id DROP NOT NULL;

-- Add constraint to ensure data integrity
ALTER TABLE batch_payments
ADD CONSTRAINT batch_payments_batch_or_pending_check 
CHECK (
    (batch_id IS NOT NULL) OR 
    (card_id IS NOT NULL AND batch_name IS NOT NULL AND cards_count IS NOT NULL)
);

-- Create new indexes for performance
CREATE INDEX IF NOT EXISTS idx_batch_payments_card_id ON batch_payments(card_id);
CREATE INDEX IF NOT EXISTS idx_batch_payments_pending ON batch_payments(card_id, user_id) WHERE batch_id IS NULL;
```

### 2. **New Stored Procedures (Server-Side)**

```sql
-- Create payment record for pending batch (payment-first flow)
CREATE OR REPLACE FUNCTION create_pending_batch_payment(
    p_card_id UUID,
    p_stripe_payment_intent_id TEXT,
    p_stripe_checkout_session_id TEXT,
    p_amount_cents INTEGER,
    p_cards_count INTEGER,
    p_batch_name TEXT,
    p_metadata JSONB DEFAULT '{}'::jsonb
) RETURNS UUID LANGUAGE plpgsql SECURITY DEFINER AS $$
-- [Full function body is in sql/storeproc/server-side/05_payment_management.sql]
$$;

-- Confirm pending batch payment and create batch (payment-first flow)
CREATE OR REPLACE FUNCTION confirm_pending_batch_payment(
    p_stripe_checkout_session_id TEXT,
    p_payment_method TEXT DEFAULT NULL
) RETURNS UUID LANGUAGE plpgsql SECURITY DEFINER AS $$
-- [Full function body is in sql/storeproc/server-side/05_payment_management.sql]
$$;
```

### 3. **New Stored Procedures (Client-Side)**

```sql
-- Get pending batch payment information by session ID (Used by frontend for payment-first flow)
CREATE OR REPLACE FUNCTION get_pending_batch_payment_info(p_session_id TEXT)
RETURNS TABLE (
    payment_id UUID,
    card_id UUID,
    stripe_checkout_session_id TEXT,
    stripe_payment_intent_id TEXT,
    amount_cents INTEGER,
    currency TEXT,
    payment_status TEXT,
    payment_method TEXT,
    batch_name TEXT,
    cards_count INTEGER,
    failure_reason TEXT,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ
) LANGUAGE plpgsql SECURITY DEFINER AS $$
-- [Full function body is in sql/storeproc/client-side/05_payment_management_client.sql]
$$;
```

## 🚀 Recommended Application Steps

### **Step 1: Apply Schema Changes**
```bash
# Connect to your database and run:
psql -U your_user -d your_database

# Apply the ALTER TABLE commands above
```

### **Step 2: Deploy Stored Procedures**
```bash
# Apply the server-side stored procedures
psql -U your_user -d your_database -f sql/storeproc/server-side/05_payment_management.sql

# Apply the client-side stored procedures  
psql -U your_user -d your_database -f sql/storeproc/client-side/05_payment_management_client.sql

# Or apply all stored procedures at once
psql -U your_user -d your_database -f sql/all_stored_procedures.sql
```

### **Step 3: Deploy Edge Functions**
```bash
# Deploy the updated Edge Functions
npx supabase functions deploy create-checkout-session --use-api
npx supabase functions deploy handle-checkout-success --use-api
```

### **Step 4: Test the Flow**
1. Upload a card design
2. Click "Pay & Issue" 
3. Complete payment in Stripe
4. Verify batch is created automatically
5. Verify cards are generated

## 📁 Files Modified

### **Schema Files:**
- ✅ `sql/schema.sql` - Updated `batch_payments` table definition
- ✅ `sql/all_stored_procedures.sql` - Added new server-side functions

### **Stored Procedure Files:**
- ✅ `sql/storeproc/server-side/05_payment_management.sql` - Added pending batch functions
- ✅ `sql/storeproc/client-side/05_payment_management_client.sql` - Added client function

### **Edge Function Files:**
- ✅ `supabase/functions/create-checkout-session/index.ts` - Uses new pending payment functions
- ✅ `supabase/functions/handle-checkout-success/index.ts` - Creates batches from pending payments

### **Frontend Files:**
- ✅ `src/components/CardIssuanceCheckout.vue` - Simplified batch creation logic

## 🎯 Expected Results After Deployment

✅ **Payment-First Flow**: Payment → Batch Creation → Card Generation (secure)  
✅ **Backward Compatibility**: Old batch-first flow still works  
✅ **404 Edge Function Error**: Resolved  
✅ **Data Integrity**: No orphaned records or partial states  
✅ **Audit Trail**: Complete logging of all operations

## 🔍 Database Schema Summary

The `batch_payments` table now supports two modes:

**Existing Batch Payments** (Old Flow):
- `batch_id`: NOT NULL (references existing batch)
- `card_id`: NULL
- `batch_name`: NULL  
- `cards_count`: NULL

**Pending Batch Payments** (New Flow):
- `batch_id`: NULL (no batch exists yet)
- `card_id`: NOT NULL (references card)
- `batch_name`: NOT NULL (intended batch name)
- `cards_count`: NOT NULL (number of cards)

The constraint ensures exactly one of these modes is used per payment record.
