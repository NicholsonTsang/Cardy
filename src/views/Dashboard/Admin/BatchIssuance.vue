<template>
  <PageWrapper 
    :title="$t('admin.issue_free_batch')" 
    :description="$t('admin.issue_free_batch_desc')"
  >
    <div class="max-w-4xl mx-auto">
      <!-- Instructions Card -->
      <div class="bg-blue-50 border border-blue-200 rounded-xl p-6 mb-6">
        <div class="flex items-start gap-3">
          <i class="pi pi-info-circle text-blue-600 text-xl mt-1"></i>
          <div>
            <h3 class="text-lg font-semibold text-blue-900 mb-2">{{ $t('admin.about_free_batch_issuance') }}</h3>
            <p class="text-sm text-blue-800 leading-relaxed">
              {{ $t('admin.about_free_batch_text') }}
            </p>
          </div>
        </div>
      </div>

      <!-- Issuance Form -->
      <div class="bg-white rounded-xl shadow-soft border border-slate-200 overflow-hidden">
        <div class="px-6 py-4 border-b border-slate-200">
          <h2 class="text-lg font-semibold text-slate-900">{{ $t('admin.batch_configuration') }}</h2>
          <p class="text-sm text-slate-600 mt-1">{{ $t('admin.fill_details_to_issue') }}</p>
        </div>

        <form @submit.prevent="handleSubmit" class="p-6 space-y-6">
          <!-- User Email Search -->
          <div class="space-y-2">
            <label class="block text-sm font-medium text-slate-700">
              {{ $t('common.email') }} <span class="text-red-500">*</span>
            </label>
            <div class="flex gap-3">
              <InputText 
                v-model="form.userEmail"
                :placeholder="$t('admin.enter_user_email_address')"
                class="flex-1"
                :class="{ 'p-invalid': errors.userEmail }"
                @input="handleUserEmailChange"
              />
              <Button 
                icon="pi pi-search" 
                :label="$t('admin.search_user')"
                @click="searchUser"
                :loading="isSearchingUser"
                :disabled="!form.userEmail || isSearchingUser"
                severity="secondary"
                outlined
              />
            </div>
            <small v-if="errors.userEmail" class="text-red-500">{{ errors.userEmail }}</small>
            
            <!-- User Info Display -->
            <div v-if="selectedUser" class="mt-3 p-4 bg-green-50 border border-green-200 rounded-lg">
              <div class="flex items-center gap-3">
                <i class="pi pi-check-circle text-green-600 text-xl"></i>
                <div class="flex-1">
                  <p class="text-sm font-medium text-green-900">{{ $t('admin.user_found') }}</p>
                  <p class="text-sm text-green-700">{{ selectedUser.email }}</p>
                  <p class="text-xs text-green-600 mt-1">
                    {{ selectedUser.cards_count || 0 }} {{ $t('admin.cards_created') }}
                  </p>
                </div>
              </div>
            </div>
          </div>

          <!-- Card Selection -->
          <div class="space-y-2">
            <label class="block text-sm font-medium text-slate-700">
              {{ $t('admin.select_card') }} <span class="text-red-500">*</span>
            </label>
            <Select 
              v-model="form.cardId"
              :options="userCards"
              optionLabel="card_name"
              optionValue="id"
              :placeholder="$t('admin.select_card_to_issue')"
              class="w-full"
              :disabled="!selectedUser || isLoadingCards"
              :loading="isLoadingCards"
              :class="{ 'p-invalid': errors.cardId }"
              showClear
            >
              <template #option="{ option }">
                <div class="flex items-center justify-between w-full">
                  <span>{{ option.card_name }}</span>
                  <Tag :value="`${option.batches_count || 0} batches`" severity="secondary" class="text-xs" />
                </div>
              </template>
            </Select>
            <small v-if="errors.cardId" class="text-red-500">{{ errors.cardId }}</small>
            <small v-else class="text-slate-500">
              {{ selectedUser ? $t('admin.choose_which_card') : $t('admin.search_user_first') }}
            </small>
          </div>

          <!-- Batch Name Info -->
          <div class="space-y-2">
            <label class="block text-sm font-medium text-slate-700">
              {{ $t('admin.batch_name') }}
            </label>
            <div class="p-3 bg-slate-50 border border-slate-200 rounded-lg">
              <p class="text-sm text-slate-600">
                <i class="pi pi-info-circle text-slate-500 mr-2"></i>
                {{ $t('admin.batch_name_auto_generated') }}
              </p>
            </div>
          </div>

          <!-- Cards Count -->
          <div class="space-y-2">
            <label class="block text-sm font-medium text-slate-700">
              {{ $t('admin.batch_quantity') }} <span class="text-red-500">*</span>
            </label>
            <InputNumber 
              v-model="form.cardsCount"
              :min="1"
              :max="10000"
              :step="1"
              showButtons
              :placeholder="$t('admin.enter_batch_quantity')"
              class="w-full"
              :class="{ 'p-invalid': errors.cardsCount }"
              inputClass="w-full"
            />
            <small v-if="errors.cardsCount" class="text-red-500">{{ errors.cardsCount }}</small>
            <small v-else class="text-slate-500">
              {{ $t('admin.min_1_max_1000') }}
              <span v-if="form.cardsCount > 0" class="font-medium text-slate-700">
                ({{ $t('admin.regular_cost') }}: ${{ (form.cardsCount * 2).toLocaleString() }})
              </span>
            </small>
          </div>

          <!-- Reason -->
          <div class="space-y-2">
            <label class="block text-sm font-medium text-slate-700">
              {{ $t('admin.issuance_reason') }} <span class="text-red-500">*</span>
            </label>
            <Textarea 
              v-model="form.reason"
              rows="4"
              :placeholder="$t('admin.explain_why_issuing')"
              class="w-full"
              :class="{ 'p-invalid': errors.reason }"
            />
            <small v-if="errors.reason" class="text-red-500">{{ errors.reason }}</small>
            <small v-else class="text-slate-500">{{ $t('admin.explain_why_issuing') }}</small>
          </div>

          <!-- Summary Card -->
          <div v-if="isFormComplete" class="p-4 bg-slate-50 border border-slate-200 rounded-lg">
            <h4 class="text-sm font-semibold text-slate-900 mb-3">{{ $t('admin.issuance_summary') }}</h4>
            <div class="space-y-2 text-sm">
              <div class="flex justify-between">
                <span class="text-slate-600">{{ $t('admin.user') }}:</span>
                <span class="font-medium text-slate-900">{{ form.userEmail }}</span>
              </div>
              <div class="flex justify-between">
                <span class="text-slate-600">{{ $t('admin.card') }}:</span>
                <span class="font-medium text-slate-900">{{ selectedCardName }}</span>
              </div>
              <div class="flex justify-between">
                <span class="text-slate-600">{{ $t('admin.batch_name') }}:</span>
                <span class="font-mono text-sm text-slate-900">{{ $t('admin.auto_generated') }}</span>
              </div>
              <div class="flex justify-between">
                <span class="text-slate-600">{{ $t('admin.cards_count') }}:</span>
                <span class="font-medium text-slate-900">{{ form.cardsCount }}</span>
              </div>
              <div class="flex justify-between pt-2 border-t border-slate-300">
                <span class="text-slate-600">{{ $t('admin.regular_cost') }}:</span>
                <span class="font-semibold text-slate-900">${{ (form.cardsCount * 2).toLocaleString() }}</span>
              </div>
              <div class="flex justify-between">
                <span class="text-green-600 font-medium">{{ $t('admin.free_issuance') }}:</span>
                <span class="font-semibold text-green-600">$0.00</span>
              </div>
            </div>
          </div>

          <!-- Action Buttons -->
          <div class="flex justify-end gap-3 pt-4 border-t border-slate-200">
            <Button 
              :label="$t('common.cancel')" 
              severity="secondary"
              outlined
              @click="handleCancel"
              :disabled="isSubmitting"
            />
            <Button 
              type="submit"
              :label="$t('admin.issue_free_batch_button')"
              icon="pi pi-check"
              :loading="isSubmitting"
              :disabled="!isFormComplete || isSubmitting"
            />
          </div>
        </form>
      </div>

      <!-- Recent Issuances -->
      <div v-if="recentIssuances.length > 0" class="mt-6 bg-white rounded-xl shadow-soft border border-slate-200 overflow-hidden">
        <div class="px-6 py-4 border-b border-slate-200">
          <h2 class="text-lg font-semibold text-slate-900">{{ $t('admin.recent_free_batch_issuances') }}</h2>
          <p class="text-sm text-slate-600 mt-1">{{ $t('admin.latest_batches_issued') }}</p>
        </div>
        <div class="p-6">
          <div class="space-y-3">
            <div 
              v-for="issuance in recentIssuances" 
              :key="issuance.id"
              class="flex items-center justify-between p-4 bg-green-50 border border-green-200 rounded-lg"
            >
              <div class="flex items-center gap-3">
                <i class="pi pi-check-circle text-green-600 text-xl"></i>
                <div>
                  <p class="text-sm font-medium text-slate-900">{{ issuance.batchName }}</p>
                  <p class="text-xs text-slate-600">
                    {{ issuance.cardsCount }} {{ $t('admin.cards_issued_to') }} {{ issuance.userEmail }}
                  </p>
                  <p class="text-xs text-slate-500 mt-1">{{ formatTimeAgo(issuance.timestamp) }}</p>
                </div>
              </div>
              <Tag :value="$t('admin.issued')" severity="success" />
            </div>
          </div>
        </div>
      </div>
    </div>
  </PageWrapper>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useToast } from 'primevue/usetoast'
import { useI18n } from 'vue-i18n'
import { supabase } from '@/lib/supabase'
import { useAdminBatchesStore } from '@/stores/admin'

// PrimeVue Components
import Button from 'primevue/button'
import InputText from 'primevue/inputtext'
import InputNumber from 'primevue/inputnumber'
import Textarea from 'primevue/textarea'
import Select from 'primevue/select'
import Tag from 'primevue/tag'
import PageWrapper from '@/components/Layout/PageWrapper.vue'

const router = useRouter()
const toast = useToast()
const { t } = useI18n()
const batchesStore = useAdminBatchesStore()

// State
const form = ref({
  userEmail: '',
  cardId: null,
  cardsCount: 100,
  reason: ''
})

const errors = ref({
  userEmail: '',
  cardId: '',
  cardsCount: '',
  reason: ''
})

const selectedUser = ref(null)
const userCards = ref([])
const isSearchingUser = ref(false)
const isLoadingCards = ref(false)
const isSubmitting = ref(false)
const recentIssuances = ref([])

// Computed
const isFormComplete = computed(() => {
  return (
    selectedUser.value &&
    form.value.cardId &&
    form.value.cardsCount > 0 &&
    form.value.cardsCount <= 10000 &&
    form.value.reason.trim()
  )
})

const selectedCardName = computed(() => {
  if (!form.value.cardId) return ''
  const card = userCards.value.find(c => c.id === form.value.cardId)
  return card ? card.card_name : ''
})

// Methods
const handleUserEmailChange = () => {
  errors.value.userEmail = ''
  selectedUser.value = null
  userCards.value = []
  form.value.cardId = null
}

const searchUser = async () => {
  if (!form.value.userEmail.trim()) {
    errors.value.userEmail = 'Email is required'
    return
  }

  isSearchingUser.value = true
  errors.value.userEmail = ''

  try {
    const { data, error } = await supabase.rpc('admin_get_user_by_email', {
      p_email: form.value.userEmail.trim()
    })

    if (error) throw error

    if (data && data.length > 0) {
      selectedUser.value = data[0]  // Get first result from array
      await loadUserCards()
      // UI shows user info - no toast needed
    } else {
      errors.value.userEmail = 'User not found'
      // Inline error is sufficient - no toast needed
    }
  } catch (error) {
    console.error('Error searching user:', error)
    errors.value.userEmail = error.message || 'Failed to search user'
    toast.add({
      severity: 'error',
      summary: t('admin.search_failed'),
      detail: error.message || t('admin.failed_to_search_user'),
      life: 5000
    })
  } finally {
    isSearchingUser.value = false
  }
}

const loadUserCards = async () => {
  if (!selectedUser.value) return

  console.log('loadUserCards - selectedUser:', selectedUser.value)
  console.log('loadUserCards - user_id:', selectedUser.value.user_id)

  isLoadingCards.value = true
  errors.value.cardId = ''

  try {
    const payload = { p_user_id: selectedUser.value.user_id }
    console.log('RPC payload:', payload)
    
    const { data, error } = await supabase.rpc('admin_get_user_cards', payload)

    if (error) throw error

    userCards.value = data || []

    if (userCards.value.length === 0) {
      errors.value.cardId = 'User has no cards'
      // Inline error + empty state is sufficient - no toast needed
    }
  } catch (error) {
    console.error('Error loading user cards:', error)
    errors.value.cardId = 'Failed to load cards'
    toast.add({
      severity: 'error',
      summary: t('common.error'),
      detail: t('admin.failed_to_load_user_cards'),
      life: 5000
    })
  } finally {
    isLoadingCards.value = false
  }
}

const validateForm = () => {
  let isValid = true
  errors.value = {
    userEmail: '',
    cardId: '',
    cardsCount: '',
    reason: ''
  }

  if (!selectedUser.value) {
    errors.value.userEmail = 'Please search and select a user'
    isValid = false
  }

  if (!form.value.cardId) {
    errors.value.cardId = 'Please select a card'
    isValid = false
  }

  if (!form.value.cardsCount || form.value.cardsCount < 1) {
    errors.value.cardsCount = 'At least 1 card is required'
    isValid = false
  } else if (form.value.cardsCount > 10000) {
    errors.value.cardsCount = 'Maximum 10,000 cards allowed'
    isValid = false
  }

  if (!form.value.reason.trim()) {
    errors.value.reason = 'Reason is required'
    isValid = false
  } else if (form.value.reason.trim().length < 10) {
    errors.value.reason = 'Reason must be at least 10 characters'
    isValid = false
  }

  return isValid
}

const handleSubmit = async () => {
  if (!validateForm()) {
    // Inline errors are already shown - no toast needed
    return
  }

  isSubmitting.value = true

  try {
    const batchId = await batchesStore.issueBatch(
      form.value.userEmail.trim(),
      form.value.cardId,
      form.value.cardsCount,
      form.value.reason.trim()
    )

    // Add to recent issuances
    recentIssuances.value.unshift({
      id: batchId,
      userEmail: form.value.userEmail,
      batchName: 'Auto-generated',
      cardsCount: form.value.cardsCount,
      timestamp: new Date()
    })

    toast.add({
      severity: 'success',
      summary: t('common.success'),
      detail: t('admin.batch_issued_successfully'),
      life: 5000
    })

    // Reset form
    resetForm()
  } catch (error) {
    console.error('Error issuing batch:', error)
    toast.add({
      severity: 'error',
      summary: t('common.error'),
      detail: error.message || t('admin.failed_to_issue_batch'),
      life: 5000
    })
  } finally {
    isSubmitting.value = false
  }
}

const resetForm = () => {
  form.value = {
    userEmail: '',
    cardId: null,
    cardsCount: 100,
    reason: ''
  }
  errors.value = {
    userEmail: '',
    cardId: '',
    cardsCount: '',
    reason: ''
  }
  selectedUser.value = null
  userCards.value = []
}

const handleCancel = () => {
  router.push('/cms/admin/batches')
}

const formatTimeAgo = (date) => {
  const now = new Date()
  const past = new Date(date)
  const diffMs = now - past
  const diffMins = Math.floor(diffMs / (60 * 1000))
  const diffHours = Math.floor(diffMs / (60 * 60 * 1000))

  if (diffMins < 1) return 'Just now'
  if (diffMins < 60) return `${diffMins}m ago`
  if (diffHours < 24) return `${diffHours}h ago`
  return past.toLocaleDateString()
}
</script>

<style scoped>
:deep(.p-inputnumber-input) {
  width: 100%;
}

:deep(.p-invalid) {
  border-color: #ef4444 !important;
}
</style>

