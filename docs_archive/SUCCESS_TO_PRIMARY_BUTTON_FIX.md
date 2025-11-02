# Button Severity Change: Success → Primary

## Issue
Green buttons (`severity="success"`) in the dashboard didn't align with the overall color scheme. The user wanted all action buttons to be blue (`severity="primary"`) for consistency.

## Solution
Changed all Button components from `severity="success"` to `severity="primary"`.

## Files Modified

### 1. `/src/views/Dashboard/CardIssuer/CreditManagement.vue`

#### Change 1: Purchase Credits Header Button (Line 8)
**Before:**
```vue
<Button 
  @click="showPurchaseDialog = true" 
  icon="pi pi-wallet" 
  :label="$t('credits.purchaseCredits')"
  severity="success"  <!-- ❌ Green button -->
  size="large"
/>
```

**After:**
```vue
<Button 
  @click="showPurchaseDialog = true" 
  icon="pi pi-wallet" 
  :label="$t('credits.purchaseCredits')"
  severity="primary"  <!-- ✅ Blue button -->
  size="large"
/>
```

#### Change 2: Proceed to Payment Button (Line 445)
**Before:**
```vue
<Button 
  :label="$t('credits.proceedToPayment')" 
  @click="proceedToPayment" 
  :disabled="!selectedAmount || purchaseLoading"
  :loading="purchaseLoading"
  icon="pi pi-arrow-right"
  iconPos="right"
  size="large"
  severity="success"  <!-- ❌ Green button -->
/>
```

**After:**
```vue
<Button 
  :label="$t('credits.proceedToPayment')" 
  @click="proceedToPayment" 
  :disabled="!selectedAmount || purchaseLoading"
  :loading="purchaseLoading"
  icon="pi pi-arrow-right"
  iconPos="right"
  size="large"
  severity="primary"  <!-- ✅ Blue button -->
/>
```

### 2. `/src/views/Dashboard/Admin/AdminCreditManagement.vue`

#### Change 3: View Purchases Action Button (Line 196)
**Before:**
```vue
<Button
  icon="pi pi-shopping-cart"
  size="small"
  rounded
  outlined
  severity="success"  <!-- ❌ Green button -->
  @click="viewUserPurchases(data)"
  v-tooltip.top="'View Purchases'"
  class="action-btn"
/>
```

**After:**
```vue
<Button
  icon="pi pi-shopping-cart"
  size="small"
  rounded
  outlined
  severity="primary"  <!-- ✅ Blue button -->
  @click="viewUserPurchases(data)"
  v-tooltip.top="'View Purchases'"
  class="action-btn"
/>
```

## What Was NOT Changed

The following components still use `severity="success"` (green) because they are **status indicators**, not action buttons:

### Chips (Amount Indicators) - Keep Green ✅
- Credit balance chips in Admin Credit Management
- Credit amount chips in purchase history
- Price chips in purchase dialog

**Rationale**: Green for currency/credit amounts is a universal convention indicating positive value.

### Tags (Status Indicators) - Keep Green ✅
- "Issued" status tags in Batch Issuance
- Translated language tags in Translation Dialog

**Rationale**: Green indicates successful completion or positive status.

### Messages (Feedback) - Keep Green ✅
- Success messages in SignIn page
- Success messages in ResetPassword page

**Rationale**: Green for success feedback is a universal UX convention.

## PrimeVue Severity System Reference

| Severity | Color | Use Case |
|----------|-------|----------|
| `primary` | 🔵 Blue | Primary action buttons |
| `success` | 🟢 Green | Success states, positive indicators |
| `info` | 🔵 Blue | Informational states |
| `warn` | 🟠 Orange | Warning states |
| `danger` | 🔴 Red | Danger states, negative values |
| `secondary` | ⚪ Gray | Secondary actions |

## Result

### Before Fix:
- ❌ Mix of green and blue buttons across dashboard
- ❌ Green stood out too much for primary actions
- ❌ Inconsistent with other dashboard pages (MyCards, etc.)

### After Fix:
- ✅ All action buttons are now blue (`severity="primary"`)
- ✅ Consistent color scheme across entire dashboard
- ✅ Green reserved for semantic indicators (status, amounts)
- ✅ Matches the blue gradient theme used in MyCards and other pages

## Testing Checklist

- [x] Changed 3 Button components to `severity="primary"`
- [x] No linter errors introduced (existing CSS warnings are pre-existing)
- [ ] Verify Purchase Credits button is now blue
- [ ] Verify Proceed to Payment button is now blue
- [ ] Verify Admin View Purchases button is now blue
- [ ] Verify status chips/tags remain green (appropriate)
- [ ] Test button hover and active states
- [ ] Check button appearance on different screen sizes

## Visual Impact

**Credit Management Page:**
- Header "Purchase Credits" button: Green → Blue ✨
- Purchase dialog "Proceed to Payment" button: Green → Blue ✨

**Admin Credit Management Page:**
- User table "View Purchases" action button: Green → Blue ✨

**Maintained Green (Semantic):**
- Balance/credit amount chips: Still green (appropriate)
- Status tags: Still green (appropriate)
- Success messages: Still green (appropriate)

## Conclusion

All action buttons now use `severity="primary"` (blue) for consistency with the dashboard theme, while semantic indicators (chips, tags, messages) appropriately retain `severity="success"` (green) where it conveys meaning.

This creates a cohesive visual hierarchy where:
- **Blue** = Actions you can take
- **Green** = Positive values/states
- **Red** = Negative values/warnings

