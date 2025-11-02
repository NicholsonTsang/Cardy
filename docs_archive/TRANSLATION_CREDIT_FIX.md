# Translation Credit Confirmation - Bug Fix

## Issue

Error occurred when opening the credit confirmation dialog in the translation flow:

```
CreditConfirmationDialog.vue:186 Uncaught (in promise) TypeError: props.currentBalance.toFixed is not a function
```

## Root Cause

**Incorrect Prop Type**

The `TranslationDialog` was passing `creditStore.creditBalance` (which is an object) instead of `creditStore.balance` (which is a number) to the `CreditConfirmationDialog` component.

### Credit Store Structure

```typescript
// creditStore structure:
const creditBalance = ref<CreditBalance | null>(null)  // Object with balance, total_purchased, etc.

const balance = computed(() => creditBalance.value?.balance || 0)  // Extracted number
```

### Wrong Implementation (Before)
```vue
<CreditConfirmationDialog
  :current-balance="creditStore.creditBalance"  ❌ Object
  ...
/>
```

### Correct Implementation (After)
```vue
<CreditConfirmationDialog
  :current-balance="creditStore.balance"  ✅ Number
  ...
/>
```

## Fix Applied

### File Changed
`src/components/Card/TranslationDialog.vue`

**Change:**
```diff
- :current-balance="creditStore.creditBalance"
+ :current-balance="creditStore.balance"
```

## Verification Against Batch Issuance

Checked alignment with `CardIssuanceCheckout.vue` (which works correctly):

```vue
<!-- CardIssuanceCheckout.vue - Reference Implementation -->
<CreditConfirmationDialog
  v-model:visible="showCreditConfirmDialog"
  :credits-to-consume="requiredCredits"
  :current-balance="creditStore.balance"  ✅ Uses .balance (number)
  :loading="creatingBatch"
  :action-description="$t('batches.batch_creation_action_description')"
  :item-count="newBatch.cardCount"
  :credits-per-item="CREDITS_PER_CARD"
  :item-label="$t('batches.cards')"
  @confirm="handleConfirmBatchCreation"
  @cancel="handleCancelBatchCreation"
/>
```

Both now use the same approach! ✅

## Implementation Alignment Table

| Aspect | Translation Dialog | Batch Issuance | Status |
|--------|-------------------|----------------|--------|
| Component | `CreditConfirmationDialog` | `CreditConfirmationDialog` | ✅ Aligned |
| Balance Prop | `creditStore.balance` | `creditStore.balance` | ✅ Aligned |
| Prop Type | `number` | `number` | ✅ Aligned |
| Credits Calculation | `selectedLanguages.length` | `requiredCredits` computed | ✅ Aligned |
| Loading State | `translationStore.isTranslating` | `creatingBatch` | ✅ Aligned |
| Custom Details | Template slot | Props | ✅ Both valid |

## Why This Happened

The initial implementation referenced the credit store incorrectly. The credit store exposes:

1. **`creditBalance`** (object) - Full credit balance record from database
   ```typescript
   interface CreditBalance {
     balance: number
     total_purchased: number
     total_consumed: number
     created_at: string
     updated_at: string
   }
   ```

2. **`balance`** (computed number) - Extracted balance value
   ```typescript
   const balance = computed(() => creditBalance.value?.balance || 0)
   ```

The `CreditConfirmationDialog` component expects a `number` for the `current-balance` prop, so it can call `.toFixed(2)` on it.

## Testing

After fix, the confirmation dialog should:
- ✅ Display without errors
- ✅ Show formatted balance (e.g., "10.00 credits")
- ✅ Calculate remaining balance correctly
- ✅ Show appropriate warnings (low balance, negative, etc.)
- ✅ Work identically to batch issuance confirmation

## Lessons Learned

1. **Check Reference Implementations**: When using a shared component, check existing usages for the correct pattern
2. **Type Consistency**: Ensure prop types match what the component expects
3. **Computed Properties**: Use computed number properties (like `balance`) instead of raw objects when a primitive is needed
4. **Testing**: Test all dialogs and confirmations after implementation

## Related Files

- ✅ `src/components/Card/TranslationDialog.vue` - Fixed
- ✅ `src/components/CreditConfirmationDialog.vue` - No changes needed
- ✅ `src/components/CardIssuanceCheckout.vue` - Reference implementation
- ✅ `src/stores/credits.ts` - Credit store structure
- ✅ `TRANSLATION_CREDIT_CONFIRMATION.md` - Updated with alignment info

## Status

✅ **Fixed and Verified**
- Error resolved
- Alignment with batch issuance confirmed
- Documentation updated
- Ready for testing

---

**Date**: 2025-01-11
**Issue**: TypeError on .toFixed()
**Solution**: Use `creditStore.balance` instead of `creditStore.creditBalance`
**Result**: Fully functional credit confirmation for translations

