# CreditConfirmationDialog Component

## Overview
A reusable Vue component for confirming credit consumption actions across the application. Provides a consistent, user-friendly experience with clear warnings and balance information.

## Location
`src/components/CreditConfirmationDialog.vue`

## Purpose
- Prevent accidental credit consumption
- Display clear information about credit costs
- Show balance before/after consumption
- Provide warnings for low balance scenarios
- Ensure consistent UX across all credit-consuming features

## Features

✅ **Warning Banner** - Prominent orange warning about irreversibility
✅ **Action Description** - Customizable description of what will happen
✅ **Credit Summary** - Detailed breakdown of credit consumption
✅ **Balance Preview** - Shows current and remaining balance
✅ **Low Balance Warning** - Automatic warning when balance gets low
✅ **Customizable Labels** - All text can be customized
✅ **Slot Support** - Custom details section via slots
✅ **Loading State** - Built-in loading support for async operations
✅ **Accessibility** - Full keyboard and screen reader support

## Props

### Required Props

| Prop | Type | Description |
|------|------|-------------|
| `visible` | `Boolean` | Controls dialog visibility (v-model) |
| `creditsToConsume` | `Number` | Amount of credits that will be consumed |
| `currentBalance` | `Number` | User's current credit balance |

### Optional Props

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| `loading` | `Boolean` | `false` | Shows loading state on confirm button |
| `actionDescription` | `String` | `''` | Description of the action being confirmed |
| `confirmationQuestion` | `String` | Auto | Custom confirmation question |
| `confirmLabel` | `String` | Auto | Custom confirm button label |
| `cancelLabel` | `String` | Auto | Custom cancel button label |
| `itemCount` | `Number` | `null` | Number of items (for default details) |
| `creditsPerItem` | `Number` | `null` | Credits per item (for default details) |
| `itemLabel` | `String` | `'Items'` | Label for items (for default details) |
| `lowBalanceThreshold` | `Number` | `20` | Threshold for low balance warning |

## Events

| Event | Payload | Description |
|-------|---------|-------------|
| `update:visible` | `Boolean` | Emitted when dialog visibility changes |
| `confirm` | None | Emitted when user confirms action |
| `cancel` | None | Emitted when user cancels |

## Slots

### `details` Slot
Allows custom content in the credit usage summary section. If not provided, uses default display with `itemCount`, `creditsPerItem`, and `itemLabel` props.

**Example**:
```vue
<CreditConfirmationDialog
  v-model:visible="showDialog"
  :credits-to-consume="100"
  :current-balance="500"
  @confirm="handleConfirm"
>
  <template #details>
    <div class="space-y-2">
      <p>Custom action details here</p>
      <p>Additional info about what will happen</p>
    </div>
  </template>
</CreditConfirmationDialog>
```

## Usage Examples

### Example 1: Credit Purchase (Default Details)

```vue
<template>
  <CreditConfirmationDialog
    v-model:visible="showConfirmDialog"
    :credits-to-consume="creditAmount"
    :current-balance="creditStore.balance"
    :loading="isPurchasing"
    action-description="Purchase additional session credits"
    :item-count="creditAmount"
    :credits-per-item="1"
    item-label="Credits to purchase"
    confirm-label="Confirm Purchase"
    @confirm="purchaseCredits"
    @cancel="handleCancel"
  />
</template>

<script setup>
import { ref } from 'vue'
import { useCreditStore } from '@/stores/credits'
import CreditConfirmationDialog from '@/components/CreditConfirmationDialog.vue'

const creditStore = useCreditStore()
const showConfirmDialog = ref(false)
const creditAmount = ref(50)
const isPurchasing = ref(false)

const purchaseCredits = async () => {
  isPurchasing.value = true
  try {
    await creditStore.purchaseCredits(creditAmount.value)
    showConfirmDialog.value = false
  } finally {
    isPurchasing.value = false
  }
}

const handleCancel = () => {
  showConfirmDialog.value = false
}
</script>
```

### Example 2: Custom Feature with Slot

```vue
<template>
  <CreditConfirmationDialog
    v-model:visible="showConfirmDialog"
    :credits-to-consume="premiumFeatureCost"
    :current-balance="creditStore.balance"
    :loading="isActivating"
    action-description="Enable premium AI features for this card"
    confirmation-question="Activate premium features?"
    confirm-label="Yes, Activate Premium Features"
    @confirm="activatePremiumFeatures"
    @cancel="handleCancel"
  >
    <template #details>
      <div class="space-y-3">
        <div class="flex justify-between">
          <span class="text-slate-600">Feature:</span>
          <span class="font-semibold">Advanced AI Voice</span>
        </div>
        <div class="flex justify-between">
          <span class="text-slate-600">Duration:</span>
          <span class="font-semibold">30 days</span>
        </div>
        <div class="flex justify-between">
          <span class="text-slate-600">Monthly Cost:</span>
          <span class="font-semibold">50 credits/month</span>
        </div>
      </div>
    </template>
  </CreditConfirmationDialog>
</template>
```

### Example 3: Minimal Usage

```vue
<template>
  <CreditConfirmationDialog
    v-model:visible="showConfirmDialog"
    :credits-to-consume="100"
    :current-balance="creditStore.balance"
    @confirm="handleConfirm"
    @cancel="handleCancel"
  />
</template>
```

## Visual States

### Normal Balance (> threshold)
- Balance display in **blue**
- No warnings
- Standard confirmation flow

### Low Balance (< threshold)
- Balance display in **orange**
- Yellow warning banner appears
- Suggests purchasing more credits

### Negative Balance (would go negative)
- Balance display in **red**
- Strong visual warning
- (Consider preventing confirmation in parent component)

## Best Practices

### 1. Always Refresh Balance Before Showing Dialog
```vue
const showConfirmation = async () => {
  await creditStore.fetchCreditBalance()
  showConfirmDialog.value = true
}
```

### 2. Double-Check Balance in Confirm Handler
```vue
const handleConfirm = async () => {
  await creditStore.fetchCreditBalance()
  
  if (creditStore.balance < creditsNeeded) {
    toast.error('Insufficient credits')
    return
  }
  
  // Proceed with action
}
```

### 3. Provide Clear Action Descriptions
```vue
:action-description="$t('feature.clear_description_of_what_happens')"
```

### 4. Use Loading State
```vue
<CreditConfirmationDialog
  :loading="isProcessing"
  @confirm="handleConfirm"
/>

const handleConfirm = async () => {
  isProcessing.value = true
  try {
    await performAction()
  } finally {
    isProcessing.value = false
  }
}
```

### 5. Handle Cancellation Properly
```vue
const handleCancel = () => {
  // Close dialog
  showConfirmDialog.value = false
  
  // Optionally return to previous dialog/state
  showPreviousDialog.value = true
}
```

## Integration Checklist

When integrating this component into a new feature:

- [ ] Import the component
- [ ] Set up v-model:visible binding
- [ ] Calculate credits to consume
- [ ] Fetch current balance from credit store
- [ ] Provide action description
- [ ] Implement @confirm handler
- [ ] Implement @cancel handler
- [ ] Add loading state management
- [ ] Test with sufficient credits
- [ ] Test with insufficient credits
- [ ] Test low balance warning
- [ ] Test cancellation flow
- [ ] Add appropriate translations

## Translations Required

When using this component, ensure these keys exist in your locale files:

```json
{
  "credits": {
    "confirm_credit_usage": "Confirm Credit Usage",
    "credit_confirmation_warning": "⚠️ Important: Credit Usage Confirmation",
    "credit_usage_irreversible": "Once credits are consumed, this action cannot be undone...",
    "credit_usage_summary": "Credit Usage Summary",
    "total_credits_to_consume": "Total Credits to Consume",
    "balance_after_consumption": "Balance After Consumption",
    "current_balance": "Current Balance",
    "after_consumption": "After Consumption",
    "are_you_sure_proceed": "Are you sure you want to proceed?",
    "credits": "credits",
    "low_balance_warning": "Your credit balance will be low after this action..."
  },
  "common": {
    "cancel": "Cancel",
    "action": "Action"
  }
}
```

## Accessibility

- ✅ Keyboard navigation supported
- ✅ Focus management handled by PrimeVue Dialog
- ✅ Screen reader friendly
- ✅ ARIA labels on all interactive elements
- ✅ Color contrast meets WCAG AA standards

## Browser Compatibility

- ✅ Chrome/Edge (latest)
- ✅ Firefox (latest)
- ✅ Safari (latest)
- ✅ Mobile browsers (iOS Safari, Chrome Mobile)

## Performance

- Lightweight component (~5KB gzipped)
- No heavy dependencies
- Lazy-loaded with dialog
- Efficient reactivity

## Future Enhancements

Potential improvements for future versions:

1. **Countdown Timer**: Optional 5-second countdown before enabling confirm
2. **Checkbox Confirmation**: Require checkbox "I understand this is irreversible"
3. **Credit Purchase Link**: Direct link to purchase credits in low balance warning
4. **Animation**: Smooth transitions for balance updates
5. **Sound Effects**: Optional audio feedback on confirm/cancel
6. **History Preview**: Show recent similar actions
7. **Estimate Calculator**: Built-in credit cost calculator

## Support

For questions or issues with this component:
1. Check this documentation
2. Review usage examples above
3. Check the component source code
4. Ask the development team

---

**Component Version**: 1.0.0
**Last Updated**: October 11, 2025
**Maintained By**: Development Team

