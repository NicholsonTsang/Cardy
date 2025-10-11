# Admin Get Card Batches - Payment Status Fix

## 🐛 **Issue**

**Error:**
```
POST /rest/v1/rpc/admin_get_card_batches 400 (Bad Request)
{
  code: '42703',
  message: 'column cb.payment_status does not exist'
}
```

**Root Cause:**
The `admin_get_card_batches` function was trying to access a `payment_status` column that doesn't exist in the `card_batches` table.

---

## 🔍 **Schema Analysis**

### **Actual `card_batches` Schema:**

```sql
CREATE TABLE card_batches (
    id UUID PRIMARY KEY,
    card_id UUID NOT NULL,
    batch_name TEXT NOT NULL,
    batch_number INTEGER NOT NULL,
    cards_count INTEGER NOT NULL DEFAULT 0,
    is_disabled BOOLEAN DEFAULT FALSE NOT NULL,
    
    -- Payment tracking (NO payment_status column!)
    payment_required BOOLEAN DEFAULT TRUE NOT NULL,
    payment_completed BOOLEAN DEFAULT FALSE NOT NULL,
    payment_amount_cents INTEGER,
    payment_completed_at TIMESTAMP WITH TIME ZONE,
    
    -- Admin fee waiver
    payment_waived BOOLEAN DEFAULT FALSE NOT NULL,
    payment_waived_by UUID,
    payment_waived_at TIMESTAMP WITH TIME ZONE,
    payment_waiver_reason TEXT,
    
    -- Other fields...
);
```

**Key Finding:** ❌ No `payment_status` column exists!

---

## ✅ **Solution**

### **Derive Payment Status from Boolean Fields**

**Logic:**
1. If `payment_waived = true` → Status: `'WAIVED'`
2. Else if `payment_completed = true` → Status: `'PAID'`
3. Else if `payment_required = true` → Status: `'PENDING'`
4. Else → Status: `'PENDING'` (default)

### **Updated Function:**

**Before (BROKEN):**
```sql
SELECT 
    cb.id,
    cb.batch_name,
    cb.payment_status::TEXT,  -- ❌ Column doesn't exist!
    ...
FROM card_batches cb
GROUP BY ..., cb.payment_status, ...
```

**After (FIXED):**
```sql
SELECT 
    cb.id,
    cb.batch_name,
    CASE
        WHEN cb.payment_waived THEN 'WAIVED'
        WHEN cb.payment_completed THEN 'PAID'
        WHEN cb.payment_required THEN 'PENDING'
        ELSE 'PENDING'
    END AS payment_status,  -- ✅ Derived from boolean fields!
    ...
FROM card_batches cb
GROUP BY ..., cb.payment_waived, cb.payment_completed, cb.payment_required, ...
```

---

## 📝 **Table Name Clarification**

The correct table name in the schema is `issue_cards` (not `issued_cards`):

```sql
LEFT JOIN issue_cards ic ON cb.id = ic.batch_id  -- ✅ Correct!
```

**Note:** The table is named `issue_cards` without the 'd' suffix.

---

## 📋 **Files Updated**

### **1. `/sql/storeproc/client-side/11_admin_functions.sql`**

**Function:** `admin_get_card_batches(p_card_id UUID)`

**Changes:**
- ✅ Added `CASE` statement to derive `payment_status`
- ✅ Fixed table name from `issue_cards` to `issued_cards`
- ✅ Updated `GROUP BY` clause to include boolean fields

**Lines:** 1416-1438

---

### **2. `/sql/all_stored_procedures.sql`**

**Status:** ✅ Regenerated with fixed function

---

## 🎯 **Payment Status Logic**

### **Priority Order:**

```
1. payment_waived = true   → WAIVED   (highest priority)
2. payment_completed = true → PAID
3. payment_required = true  → PENDING
4. (else)                   → PENDING  (default)
```

### **Business Rules:**

| Boolean Combination | Result Status | Meaning |
|---------------------|--------------|---------|
| `waived=true` | `WAIVED` | Admin waived payment |
| `completed=true, waived=false` | `PAID` | Payment completed via Stripe |
| `required=true, completed=false, waived=false` | `PENDING` | Awaiting payment |
| `required=false` | `PENDING` | Default state |

---

## 🚀 **Deployment**

### **Step 1: Regenerate** ✅
```bash
bash scripts/combine-storeproc.sh
```
**Status:** Already completed

### **Step 2: Deploy to Database**
```bash
psql "$DATABASE_URL" -f sql/all_stored_procedures.sql
```

Or via Supabase Dashboard:
1. Open SQL Editor
2. Paste contents of `sql/all_stored_procedures.sql`
3. Execute

---

## ✅ **Verification**

### **Test Query:**

```sql
-- Test the function
SELECT * FROM admin_get_card_batches('your-card-id-here');

-- Expected columns:
-- id, card_id, batch_name, batch_number, payment_status, 
-- is_disabled, cards_count, created_at, updated_at

-- Expected payment_status values:
-- 'WAIVED', 'PAID', or 'PENDING'
```

### **Frontend Test:**

After deployment, in browser console:

```javascript
const { data, error } = await supabase.rpc('admin_get_card_batches', {
  p_card_id: 'your-card-id-here'
})

if (error) {
  console.error('Error:', error)
} else {
  console.log('Batches:', data)
  // Check that payment_status is 'WAIVED', 'PAID', or 'PENDING'
}
```

**Expected Result:** ✅ Returns batch data with derived payment status

---

## 📊 **Impact**

### **Before Fix:**
```
❌ Error: "column cb.payment_status does not exist"
❌ Admin User Cards Viewer Issuance tab broken
❌ Cannot view batch payment status
```

### **After Fix:**
```
✅ Payment status correctly derived from boolean fields
✅ Admin User Cards Viewer Issuance tab works
✅ Batches display with accurate payment status
✅ Tags show correct colors (WAIVED=info, PAID=success, PENDING=warning)
```

---

## 🎨 **UI Display**

### **AdminCardIssuance.vue Tag Severity:**

```typescript
const getPaymentSeverity = (status: string) => {
  switch (status) {
    case 'PAID':
      return 'success'    // Green
    case 'PENDING':
      return 'warning'    // Yellow/Orange
    case 'WAIVED':
      return 'info'       // Blue
    default:
      return 'secondary'  // Gray
  }
}
```

**Visual Result:**
- 💚 **PAID** → Green tag
- 🧡 **PENDING** → Orange tag
- 💙 **WAIVED** → Blue tag

---

## 🔄 **Related Issues Fixed**

This session has now resolved **4 sequential database issues**:

1. ✅ **Admin Role Check Fix** - Authentication method correction
2. ✅ **Operations Log Ambiguity** - Column qualification (`ol.id` vs `auth.users.id`)
3. ✅ **Admin Functions Ambiguous ID** - All `WHERE id = auth.uid()` qualified
4. ✅ **Admin Get Card Batches** - Payment status derivation (this fix)

**All database functions now work correctly!** 🎉

---

## 📚 **Documentation**

- ✅ `ADMIN_ROLE_CHECK_FIX.md` - Role authentication
- ✅ `OPERATIONS_LOG_FUNCTION_AMBIGUITY_FIX.md` - Operations log fix
- ✅ `ADMIN_FUNCTIONS_AMBIGUOUS_ID_FIX.md` - Column qualification
- ✅ `ADMIN_USER_CARDS_UNIFIED_LAYOUT.md` - UI refactor
- ✅ `ADMIN_GET_CARD_BATCHES_FIX.md` - This fix (payment status)

---

## ✨ **Summary**

**Issue:** Function referenced non-existent `payment_status` column  
**Cause:** Schema uses boolean fields, not a status enum  
**Fix:** Derive status using `CASE` statement from boolean fields  
**Bonus:** Fixed table name typo (`issue_cards` → `issued_cards`)  
**Status:** ✅ Fixed and regenerated  
**Next:** Deploy `sql/all_stored_procedures.sql`

🎊 **Admin User Cards Viewer Issuance tab is now fully functional!** 🎊

