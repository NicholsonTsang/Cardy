<template>
  <Dialog 
    v-model:visible="isVisible" 
    modal 
    :header="$t('batches.confirm_credit_usage')" 
    :style="{ width: '500px' }"
    class="standardized-dialog"
    appendTo="body"
    @update:visible="handleVisibilityChange"
  >
    <div class="space-y-6">
      <!-- Warning Banner -->
      <div class="bg-orange-50 border-2 border-orange-300 rounded-lg p-4">
        <div class="flex items-start gap-3">
          <i class="pi pi-exclamation-triangle text-orange-600 text-2xl mt-1"></i>
          <div>
            <h4 class="font-semibold text-orange-900 mb-2">{{ $t('batches.credit_confirmation_warning') }}</h4>
            <p class="text-sm text-orange-800">
              {{ $t('batches.credit_usage_irreversible') }}
            </p>
          </div>
        </div>
      </div>

      <!-- Action Description (if provided) -->
      <div v-if="actionDescription" class="bg-slate-50 rounded-lg p-4 border border-slate-200">
        <h4 class="font-medium text-slate-900 mb-2">{{ $t('common.action') }}</h4>
        <p class="text-slate-700">{{ actionDescription }}</p>
      </div>

      <!-- Credit Usage Summary -->
      <div class="bg-slate-50 rounded-lg p-4 border border-slate-200">
        <h4 class="font-medium text-slate-900 mb-3">{{ $t('batches.credit_usage_summary') }}</h4>
        <div class="space-y-3">
          <!-- Custom Details Slot -->
          <slot name="details">
            <!-- Default details if no slot provided -->
            <div v-if="itemCount && creditsPerItem" class="space-y-3">
              <div class="flex justify-between items-center">
                <span class="text-slate-600">{{ itemLabel }}:</span>
                <span class="font-semibold text-slate-900">{{ itemCount }}</span>
              </div>
              <div class="flex justify-between items-center">
                <span class="text-slate-600">{{ $t('batches.credits_per_card') }}:</span>
                <span class="font-semibold text-slate-900">{{ creditsPerItem }} {{ $t('batches.credits') }}</span>
              </div>
            </div>
          </slot>
          
          <!-- Total Credits (always shown) -->
          <div class="border-t border-slate-300 pt-3 flex justify-between items-center">
            <span class="text-slate-700 font-medium">{{ $t('batches.total_credits_to_consume') }}:</span>
            <span class="text-xl font-bold text-orange-600">{{ creditsToConsume }} {{ $t('batches.credits') }}</span>
          </div>
        </div>
      </div>

      <!-- Balance Information -->
      <div class="bg-blue-50 rounded-lg p-4 border border-blue-200">
        <h4 class="font-medium text-blue-900 mb-3">{{ $t('batches.balance_after_consumption') }}</h4>
        <div class="space-y-2">
          <div class="flex justify-between items-center">
            <span class="text-blue-700">{{ $t('batches.current_balance') }}:</span>
            <span class="font-semibold text-blue-900">{{ formattedCurrentBalance }} {{ $t('batches.credits') }}</span>
          </div>
          <div class="flex justify-between items-center">
            <span class="text-blue-700">{{ $t('batches.after_consumption') }}:</span>
            <span class="font-semibold text-blue-900" :class="remainingBalanceClass">
              {{ formattedRemainingBalance }} {{ $t('batches.credits') }}
            </span>
          </div>
        </div>
      </div>

      <!-- Low Balance Warning -->
      <div v-if="showLowBalanceWarning" class="bg-yellow-50 border border-yellow-300 rounded-lg p-3">
        <div class="flex items-center gap-2">
          <i class="pi pi-info-circle text-yellow-600"></i>
          <span class="text-sm text-yellow-800">
            {{ $t('batches.low_balance_warning') }}
          </span>
        </div>
      </div>

      <!-- Confirmation Question -->
      <div class="text-center text-slate-700 font-medium">
        {{ confirmationQuestion || $t('batches.are_you_sure_proceed') }}
      </div>
    </div>

    <template #footer>
      <div class="flex gap-3 justify-end">
        <Button 
          :label="cancelLabel || $t('common.cancel')" 
          icon="pi pi-times"
          outlined 
          @click="handleCancel"
          :disabled="loading"
          class="border-slate-600 text-slate-600 hover:bg-slate-50"
        />
        <Button 
          :label="confirmLabel || $t('batches.confirm_and_create')" 
          icon="pi pi-check"
          @click="handleConfirm"
          :loading="loading"
          severity="warning"
          class="bg-gradient-to-r from-orange-500 to-orange-600 hover:from-orange-600 hover:to-orange-700 border-0"
        />
      </div>
    </template>
  </Dialog>
</template>

<script setup>
import { computed, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import Dialog from 'primevue/dialog'
import Button from 'primevue/button'

const { t } = useI18n()

// Props
const props = defineProps({
  visible: {
    type: Boolean,
    required: true
  },
  creditsToConsume: {
    type: Number,
    required: true
  },
  currentBalance: {
    type: Number,
    required: true
  },
  loading: {
    type: Boolean,
    default: false
  },
  actionDescription: {
    type: String,
    default: ''
  },
  confirmationQuestion: {
    type: String,
    default: ''
  },
  confirmLabel: {
    type: String,
    default: ''
  },
  cancelLabel: {
    type: String,
    default: ''
  },
  // Optional props for default details display
  itemCount: {
    type: Number,
    default: null
  },
  creditsPerItem: {
    type: Number,
    default: null
  },
  itemLabel: {
    type: String,
    default: 'Items'
  },
  lowBalanceThreshold: {
    type: Number,
    default: 20 // Warn if remaining balance < 20 credits
  }
})

// Emits
const emit = defineEmits(['update:visible', 'confirm', 'cancel'])

// Local state for v-model
const isVisible = computed({
  get: () => props.visible,
  set: (value) => emit('update:visible', value)
})

// Computed
const formattedCurrentBalance = computed(() => {
  return props.currentBalance.toFixed(2)
})

const remainingBalance = computed(() => {
  return props.currentBalance - props.creditsToConsume
})

const formattedRemainingBalance = computed(() => {
  return remainingBalance.value.toFixed(2)
})

const remainingBalanceClass = computed(() => {
  if (remainingBalance.value < 0) {
    return 'text-red-600 font-bold'
  } else if (remainingBalance.value < props.lowBalanceThreshold) {
    return 'text-orange-600 font-semibold'
  }
  return 'text-blue-900'
})

const showLowBalanceWarning = computed(() => {
  return remainingBalance.value >= 0 && remainingBalance.value < props.lowBalanceThreshold
})

// Methods
const handleConfirm = () => {
  emit('confirm')
}

const handleCancel = () => {
  emit('cancel')
}

const handleVisibilityChange = (value) => {
  if (!value) {
    emit('cancel')
  }
}
</script>

<style scoped>
/* Component-specific styles if needed */
</style>

