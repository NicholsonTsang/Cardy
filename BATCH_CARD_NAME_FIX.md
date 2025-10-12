# Batch Issuance Card Name Missing in Consumption History - Fix

## Problem
When viewing credit consumption history in the Credit Management page, batch issuance records don't show the card name in the "Card" column. The column displays "-" instead of the card name, making it difficult to identify which card a batch was issued for.

**Affected Views:**
- Card Issuer Credit Management (`/cms/credits` → Consumptions tab)
- Admin Credit Management (Admin dashboard → Credit Management → Consumptions)

## Root Cause
The `consume_credits_for_batch` stored procedure was **not storing the `card_id`** when creating credit consumption records.

### What Was Happening:
1. User creates batch → Credits consumed ✅
2. Consumption record created in `credit_consumptions` table ✅
3. **BUT**: `card_id` field was NULL ❌
4. UI tries to display card name via LEFT JOIN with `cards` table
5. **Result**: No card name found, displays "-" ❌

### Database Flow:
```
consume_credits_for_batch(batch_id, card_count)
  ↓
INSERT INTO credit_consumptions
  user_id: ✅ (from auth.uid())
  batch_id: ✅ (from parameter)
  card_id: ❌ NULL (MISSING!)
  consumption_type: ✅ 'batch_issuance'
  ...
  ↓
get_credit_consumptions() 
  SELECT ... LEFT JOIN cards c ON c.id = cc.card_id
  ↓
card_id IS NULL → card_name returns NULL → UI shows "-"
```

## Solution
Modified `consume_credits_for_batch` to:
1. Get `card_id` from the `card_batches` table
2. Include `card_id` in the consumption record INSERT

### Changes Made

**File**: `sql/storeproc/client-side/credit_management.sql`

**Before (lines 216-267):**
```sql
CREATE OR REPLACE FUNCTION consume_credits_for_batch(
    p_batch_id UUID,
    p_card_count INTEGER
)
RETURNS JSONB AS $$
DECLARE
    v_user_id UUID;
    v_credits_per_card DECIMAL := 2.00;
    v_total_credits DECIMAL;
    v_current_balance DECIMAL;
    v_new_balance DECIMAL;
    v_consumption_id UUID;
    v_transaction_id UUID;
BEGIN
    -- ... balance checks ...

    -- ❌ Record consumption WITHOUT card_id
    INSERT INTO credit_consumptions (
        user_id, batch_id, consumption_type, quantity, 
        credits_per_unit, total_credits, description
    ) VALUES (
        v_user_id, p_batch_id, 'batch_issuance', p_card_count,
        v_credits_per_card, v_total_credits,
        format('Batch issuance: %s cards', p_card_count)
    ) RETURNING id INTO v_consumption_id;
```

**After:**
```sql
CREATE OR REPLACE FUNCTION consume_credits_for_batch(
    p_batch_id UUID,
    p_card_count INTEGER
)
RETURNS JSONB AS $$
DECLARE
    v_user_id UUID;
    v_card_id UUID;  -- ✅ NEW: Added card_id variable
    v_credits_per_card DECIMAL := 2.00;
    v_total_credits DECIMAL;
    v_current_balance DECIMAL;
    v_new_balance DECIMAL;
    v_consumption_id UUID;
    v_transaction_id UUID;
BEGIN
    -- ... user auth ...

    -- ✅ NEW: Get card_id from the batch
    SELECT card_id INTO v_card_id
    FROM card_batches
    WHERE id = p_batch_id;

    IF v_card_id IS NULL THEN
        RAISE EXCEPTION 'Batch not found: %', p_batch_id;
    END IF;

    -- ... balance checks ...

    -- ✅ Record consumption WITH card_id
    INSERT INTO credit_consumptions (
        user_id, card_id, batch_id, consumption_type, quantity, 
        credits_per_unit, total_credits, description
    ) VALUES (
        v_user_id, v_card_id, p_batch_id, 'batch_issuance', p_card_count,
        v_credits_per_card, v_total_credits,
        format('Batch issuance: %s cards', p_card_count)
    ) RETURNING id INTO v_consumption_id;
```

## Files Modified
1. ✅ `sql/storeproc/client-side/credit_management.sql` - Updated function
2. ✅ `sql/all_stored_procedures.sql` - Regenerated combined file
3. ✅ `DEPLOY_BATCH_CARD_NAME_FIX.sql` - Deployment script

## Deployment

### Steps:
1. Open Supabase Dashboard → SQL Editor
2. Create new query
3. Copy contents of `DEPLOY_BATCH_CARD_NAME_FIX.sql`
4. Click "Run"
5. Verify no errors

### Verification Query:
After deployment, run this to verify:
```sql
SELECT 
    cc.created_at,
    cc.consumption_type,
    c.name AS card_name,
    b.batch_name,
    cc.quantity,
    cc.total_credits
FROM credit_consumptions cc
LEFT JOIN cards c ON c.id = cc.card_id
LEFT JOIN card_batches b ON b.id = cc.batch_id
WHERE cc.consumption_type = 'batch_issuance'
ORDER BY cc.created_at DESC
LIMIT 10;
```

**Expected Result**: 
- ✅ `card_name` column should show card names for NEW batch issuances
- ❌ Old batch issuances (before fix) will still show NULL (this is expected)

## Impact on Existing Data

### Old Records (Before Fix):
- ❌ `card_id` is NULL
- ❌ Card name will continue to show "-"
- ⚠️ **Cannot be retroactively fixed** (batch issuance is a one-time event, we don't know which card old batches belonged to without manual investigation)

### New Records (After Fix):
- ✅ `card_id` will be stored
- ✅ Card name will display correctly in consumption history
- ✅ Both Card Issuer and Admin views will show card names

## Testing Checklist

### After Deployment:
- [ ] Deploy `DEPLOY_BATCH_CARD_NAME_FIX.sql` to Supabase
- [ ] Run verification query (see above)
- [ ] Verify no errors in Supabase logs

### User Testing:
- [ ] Create a new batch for a card
- [ ] Consume credits for batch issuance
- [ ] Go to Credit Management → Consumptions tab
- [ ] **Verify**: Card name appears in the Card column for the new batch
- [ ] Admin: Check Admin Credit Management → Consumptions
- [ ] **Verify**: Card name appears for the new batch

### Edge Cases:
- [ ] Create batch with special characters in card name
- [ ] Create multiple batches for same card
- [ ] Verify each batch shows correct card name
- [ ] Translation consumptions should still work (different consumption type)

## UI Display

### Before Fix:
```
Date                | Type            | Card | Batch           | Quantity | Credits
2025-01-15 10:30   | Batch Issuance  | -    | Batch #1       | 50       | 100.00
2025-01-14 09:15   | Batch Issuance  | -    | Batch #2       | 30       | 60.00
```

### After Fix (New Records):
```
Date                | Type            | Card               | Batch           | Quantity | Credits
2025-01-15 10:30   | Batch Issuance  | Museum Tour Card   | Batch #1       | 50       | 100.00
2025-01-14 09:15   | Batch Issuance  | Art Gallery Pass   | Batch #2       | 30       | 60.00
```

## Related Code

### Frontend (No Changes Needed):
- `src/views/Dashboard/CardIssuer/CreditManagement.vue` - Already expects `card_name`
- `src/views/Dashboard/Admin/AdminCreditManagement.vue` - Already expects `card_name`

### Backend:
- `sql/storeproc/client-side/credit_management.sql` - ✅ Fixed
  - `consume_credits_for_batch()` - Now includes card_id
  - `get_credit_consumptions()` - Already joins with cards table
- `sql/storeproc/client-side/admin_credit_management.sql` - No changes needed
  - `admin_get_credit_consumptions()` - Already joins with cards table

## Why This Issue Wasn't Caught Earlier

1. **Translation Feature Worked**: Translation consumption stored `card_id` correctly via metadata
2. **Batch ID Was Stored**: Batch name displayed correctly, masking the card name issue
3. **Different Code Paths**: Batch issuance used different INSERT logic than translations
4. **Frontend Graceful Fallback**: UI showed "-" instead of breaking

## Benefits of Fix

1. ✅ **Better Auditing**: Admins and users can see which card each batch belongs to
2. ✅ **Improved UX**: No more guessing which card a batch was issued for
3. ✅ **Consistent Data**: Batch issuance records now match translation records (both have card_id)
4. ✅ **Future-Proof**: Any new features relying on card_id in consumption records will work
5. ✅ **No Breaking Changes**: Existing functionality continues to work

## Conclusion

This fix ensures that future batch issuances will correctly store and display the card name in consumption history. The fix is backward-compatible and doesn't affect existing batch issuance functionality - it simply adds the missing `card_id` link.

**Important Note**: This fix only affects NEW batch issuances created after deployment. Old batch issuance records will continue to show "-" for the card name, as their `card_id` was not stored at the time of creation.

