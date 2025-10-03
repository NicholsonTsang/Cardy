<template>
  <PageWrapper 
    title="Issue Free Batch" 
    description="Issue a free batch of cards to any user"
  >
    <div class="max-w-4xl mx-auto">
      <!-- Instructions Card -->
      <div class="bg-blue-50 border border-blue-200 rounded-xl p-6 mb-6">
        <div class="flex items-start gap-3">
          <i class="pi pi-info-circle text-blue-600 text-xl mt-1"></i>
          <div>
            <h3 class="text-lg font-semibold text-blue-900 mb-2">About Free Batch Issuance</h3>
            <p class="text-sm text-blue-800 leading-relaxed">
              This feature allows you to issue a free batch of cards to any user without requiring payment. 
              The batch will be created immediately with cards generated and ready for use. 
              This is useful for promotional purposes, partnership agreements, or customer support resolutions.
            </p>
          </div>
        </div>
      </div>

      <!-- Issuance Form -->
      <div class="bg-white rounded-xl shadow-soft border border-slate-200 overflow-hidden">
        <div class="px-6 py-4 border-b border-slate-200">
          <h2 class="text-lg font-semibold text-slate-900">Batch Configuration</h2>
          <p class="text-sm text-slate-600 mt-1">Fill in the details to issue a free batch</p>
        </div>

        <form @submit.prevent="handleSubmit" class="p-6 space-y-6">
          <!-- User Email Search -->
          <div class="space-y-2">
            <label class="block text-sm font-medium text-slate-700">
              User Email <span class="text-red-500">*</span>
            </label>
            <div class="flex gap-3">
              <InputText 
                v-model="form.userEmail"
                placeholder="Enter user email address"
                class="flex-1"
                :class="{ 'p-invalid': errors.userEmail }"
                @input="handleUserEmailChange"
              />
              <Button 
                icon="pi pi-search" 
                label="Search User"
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
                  <p class="text-sm font-medium text-green-900">User Found</p>
                  <p class="text-sm text-green-700">{{ selectedUser.email }}</p>
                  <p class="text-xs text-green-600 mt-1">
                    {{ selectedUser.cards_count || 0 }} cards created
                  </p>
                </div>
              </div>
            </div>
          </div>

          <!-- Card Selection -->
          <div class="space-y-2">
            <label class="block text-sm font-medium text-slate-700">
              Select Card <span class="text-red-500">*</span>
            </label>
            <Select 
              v-model="form.cardId"
              :options="userCards"
              optionLabel="card_name"
              optionValue="id"
              placeholder="Select a card to issue batch for"
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
              {{ selectedUser ? 'Choose which card to create the batch for' : 'Search for a user first' }}
            </small>
          </div>

          <!-- Batch Name Info -->
          <div class="space-y-2">
            <label class="block text-sm font-medium text-slate-700">
              Batch Name
            </label>
            <div class="p-3 bg-slate-50 border border-slate-200 rounded-lg">
              <p class="text-sm text-slate-600">
                <i class="pi pi-info-circle text-slate-500 mr-2"></i>
                Batch name will be auto-generated as <span class="font-mono font-medium text-slate-900">"Batch #[number] - Issued by Admin"</span>
              </p>
            </div>
          </div>

          <!-- Cards Count -->
          <div class="space-y-2">
            <label class="block text-sm font-medium text-slate-700">
              Number of Cards <span class="text-red-500">*</span>
            </label>
            <InputNumber 
              v-model="form.cardsCount"
              :min="1"
              :max="10000"
              :step="1"
              showButtons
              placeholder="Enter number of cards"
              class="w-full"
              :class="{ 'p-invalid': errors.cardsCount }"
              inputClass="w-full"
            />
            <small v-if="errors.cardsCount" class="text-red-500">{{ errors.cardsCount }}</small>
            <small v-else class="text-slate-500">
              Between 1 and 10,000 cards. 
              <span v-if="form.cardsCount > 0" class="font-medium text-slate-700">
                (Regular cost: ${{ (form.cardsCount * 2).toLocaleString() }})
              </span>
            </small>
          </div>

          <!-- Reason -->
          <div class="space-y-2">
            <label class="block text-sm font-medium text-slate-700">
              Reason for Free Issuance <span class="text-red-500">*</span>
            </label>
            <Textarea 
              v-model="form.reason"
              rows="4"
              placeholder="e.g., Partnership agreement, Promotional campaign, Customer support resolution"
              class="w-full"
              :class="{ 'p-invalid': errors.reason }"
            />
            <small v-if="errors.reason" class="text-red-500">{{ errors.reason }}</small>
            <small v-else class="text-slate-500">Explain why this batch is being issued for free</small>
          </div>

          <!-- Summary Card -->
          <div v-if="isFormComplete" class="p-4 bg-slate-50 border border-slate-200 rounded-lg">
            <h4 class="text-sm font-semibold text-slate-900 mb-3">Issuance Summary</h4>
            <div class="space-y-2 text-sm">
              <div class="flex justify-between">
                <span class="text-slate-600">User:</span>
                <span class="font-medium text-slate-900">{{ form.userEmail }}</span>
              </div>
              <div class="flex justify-between">
                <span class="text-slate-600">Card:</span>
                <span class="font-medium text-slate-900">{{ selectedCardName }}</span>
              </div>
              <div class="flex justify-between">
                <span class="text-slate-600">Batch Name:</span>
                <span class="font-mono text-sm text-slate-900">Auto-generated</span>
              </div>
              <div class="flex justify-between">
                <span class="text-slate-600">Cards Count:</span>
                <span class="font-medium text-slate-900">{{ form.cardsCount }}</span>
              </div>
              <div class="flex justify-between pt-2 border-t border-slate-300">
                <span class="text-slate-600">Regular Cost:</span>
                <span class="font-semibold text-slate-900">${{ (form.cardsCount * 2).toLocaleString() }}</span>
              </div>
              <div class="flex justify-between">
                <span class="text-green-600 font-medium">Free Issuance:</span>
                <span class="font-semibold text-green-600">$0.00</span>
              </div>
            </div>
          </div>

          <!-- Action Buttons -->
          <div class="flex justify-end gap-3 pt-4 border-t border-slate-200">
            <Button 
              label="Cancel" 
              severity="secondary"
              outlined
              @click="handleCancel"
              :disabled="isSubmitting"
            />
            <Button 
              type="submit"
              label="Issue Free Batch"
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
          <h2 class="text-lg font-semibold text-slate-900">Recent Free Batch Issuances</h2>
          <p class="text-sm text-slate-600 mt-1">Latest batches issued in this session</p>
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
                    {{ issuance.cardsCount }} cards issued to {{ issuance.userEmail }}
                  </p>
                  <p class="text-xs text-slate-500 mt-1">{{ formatTimeAgo(issuance.timestamp) }}</p>
                </div>
              </div>
              <Tag value="Issued" severity="success" />
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
      toast.add({
        severity: 'success',
        summary: 'User Found',
        detail: `Found user: ${data[0].email}`,
        life: 3000
      })
    } else {
      errors.value.userEmail = 'User not found'
      toast.add({
        severity: 'warn',
        summary: 'User Not Found',
        detail: 'No user found with this email address',
        life: 3000
      })
    }
  } catch (error) {
    console.error('Error searching user:', error)
    errors.value.userEmail = error.message || 'Failed to search user'
    toast.add({
      severity: 'error',
      summary: 'Search Failed',
      detail: error.message || 'Failed to search for user',
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
      toast.add({
        severity: 'warn',
        summary: 'No Cards Found',
        detail: 'This user has not created any cards yet',
        life: 3000
      })
    }
  } catch (error) {
    console.error('Error loading user cards:', error)
    errors.value.cardId = 'Failed to load cards'
    toast.add({
      severity: 'error',
      summary: 'Error',
      detail: 'Failed to load user cards',
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
    toast.add({
      severity: 'warn',
      summary: 'Validation Error',
      detail: 'Please fill in all required fields correctly',
      life: 3000
    })
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
      summary: 'Batch Issued Successfully',
      detail: `${form.value.cardsCount} cards issued to ${form.value.userEmail}`,
      life: 5000
    })

    // Reset form
    resetForm()
  } catch (error) {
    console.error('Error issuing batch:', error)
    toast.add({
      severity: 'error',
      summary: 'Issuance Failed',
      detail: error.message || 'Failed to issue batch',
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

