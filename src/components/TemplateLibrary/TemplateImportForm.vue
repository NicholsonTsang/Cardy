<template>
  <div class="import-form">
    <!-- Template Summary -->
    <div class="template-summary">
      <div class="summary-icon">
        <i :class="getModeIcon(template.content_mode)"></i>
      </div>
      <div class="summary-info">
        <h4>{{ template.name }}</h4>
        <p>{{ template.item_count }} {{ $t('templates.content_items') }}</p>
      </div>
    </div>

    <!-- Form -->
    <form @submit.prevent="handleImport" class="form-content">
      <!-- Custom Name -->
      <div class="form-field">
        <label for="customName">{{ $t('templates.custom_name') }}</label>
        <InputText 
          id="customName"
          v-model="customName"
          :placeholder="template.name"
          class="w-full"
        />
        <small class="field-hint">{{ $t('templates.custom_name_hint') }}</small>
      </div>

      <!-- Billing Type -->
      <div class="form-field">
        <label>{{ $t('templates.billing_type') }}</label>
        <div class="billing-options">
          <div 
            class="billing-option"
            :class="{ selected: selectedBillingType === 'physical' }"
            @click="selectedBillingType = 'physical'"
          >
            <i class="pi pi-id-card"></i>
            <span class="option-label">{{ $t('templates.billing_physical') }}</span>
            <span class="option-description">{{ $t('templates.billing_physical_desc') }}</span>
          </div>
          <div 
            class="billing-option"
            :class="{ selected: selectedBillingType === 'digital' }"
            @click="selectedBillingType = 'digital'"
          >
            <i class="pi pi-qrcode"></i>
            <span class="option-label">{{ $t('templates.billing_digital') }}</span>
            <span class="option-description">{{ $t('templates.billing_digital_desc') }}</span>
          </div>
        </div>
      </div>

      <!-- Actions -->
      <div class="form-actions">
        <Button 
          type="button"
          :label="$t('common.cancel')"
          text
          @click="$emit('cancel')"
          :disabled="isImporting"
        />
        <Button 
          type="submit"
          :label="isImporting ? $t('templates.importing') : $t('templates.create_from_template')"
          icon="pi pi-check"
          :loading="isImporting"
          class="bg-indigo-600 hover:bg-indigo-700 text-white border-0"
        />
      </div>
    </form>

    <!-- Error Message -->
    <Message v-if="errorMessage" severity="error" :closable="true" @close="errorMessage = ''">
      {{ errorMessage }}
    </Message>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { useI18n } from 'vue-i18n'
import { useTemplateLibraryStore, type ContentTemplate } from '@/stores/templateLibrary'
import { useSubscriptionStore } from '@/stores/subscription'
import InputText from 'primevue/inputtext'
import Button from 'primevue/button'
import Message from 'primevue/message'

const { t } = useI18n()
const templateStore = useTemplateLibraryStore()
const subscriptionStore = useSubscriptionStore()

const props = defineProps<{
  template: ContentTemplate
}>()

const emit = defineEmits<{
  imported: [result: { cardId: string }]
  cancel: []
}>()

// Form state
const customName = ref('')
const selectedBillingType = ref<'physical' | 'digital'>(props.template.billing_type as 'physical' | 'digital' || 'digital')
const isImporting = ref(false)
const errorMessage = ref('')

function getModeIcon(mode: string): string {
  const icons: Record<string, string> = {
    single: 'pi pi-file',
    list: 'pi pi-list',
    grid: 'pi pi-th-large',
    cards: 'pi pi-clone'
  }
  return icons[mode] || 'pi pi-file'
}

async function handleImport() {
  isImporting.value = true
  errorMessage.value = ''

  try {
    // Check subscription limit before importing
    await subscriptionStore.fetchSubscription()
    
    if (!subscriptionStore.canCreateExperience) {
      errorMessage.value = t('subscription.upgrade_to_create_more', {
        limit: subscriptionStore.experienceLimit,
        current: subscriptionStore.experienceCount
      })
      isImporting.value = false
      return
    }
    
    const result = await templateStore.importTemplate(
      props.template.id,
      customName.value || undefined,
      selectedBillingType.value
    )

    if (result.success && result.card_id) {
      emit('imported', { cardId: result.card_id })
    } else {
      errorMessage.value = result.message || t('templates.import_failed')
    }
  } catch (error: any) {
    errorMessage.value = error.message || t('templates.import_failed')
  } finally {
    isImporting.value = false
  }
}
</script>

<style scoped>
.import-form {
  @apply space-y-6;
}

.template-summary {
  @apply flex items-center gap-4 p-4 bg-slate-50 rounded-lg;
}

.summary-icon {
  @apply w-12 h-12 bg-indigo-100 rounded-lg flex items-center justify-center text-indigo-600 text-xl;
}

.summary-info h4 {
  @apply font-semibold text-slate-900;
}

.summary-info p {
  @apply text-sm text-slate-500;
}

.form-content {
  @apply space-y-5;
}

.form-field {
  @apply space-y-2;
}

.form-field label {
  @apply block text-sm font-medium text-slate-700;
}

.field-hint {
  @apply text-xs text-slate-500;
}

.billing-options {
  @apply grid grid-cols-2 gap-3;
}

.billing-option {
  @apply p-4 border-2 border-slate-200 rounded-lg cursor-pointer transition-all text-center hover:border-indigo-300;
}

.billing-option.selected {
  @apply border-indigo-500 bg-indigo-50;
}

.billing-option i {
  @apply text-2xl text-slate-400 mb-2 block;
}

.billing-option.selected i {
  @apply text-indigo-600;
}

.option-label {
  @apply block font-medium text-slate-700;
}

.billing-option.selected .option-label {
  @apply text-indigo-700;
}

.option-description {
  @apply block text-xs text-slate-500 mt-1;
}

.form-actions {
  @apply flex justify-end gap-3 pt-4 border-t border-slate-200;
}

/* Mobile responsive */
@media (max-width: 480px) {
  .billing-options {
    @apply grid-cols-1;
  }
}
</style>

