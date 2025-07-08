<template>
  <div class="space-y-6">
    <!-- Statistics Cards -->
    <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
      <div class="bg-white rounded-xl shadow-lg border border-slate-200 p-6">
        <div class="flex items-center justify-between">
          <div>
            <h3 class="text-sm font-medium text-slate-600 mb-2">Total Issued</h3>
            <p class="text-3xl font-bold text-slate-900">{{ stats.total_issued }}</p>
          </div>
          <div class="p-4 bg-gradient-to-r from-blue-500 to-indigo-500 rounded-xl">
            <i class="pi pi-credit-card text-white text-2xl"></i>
          </div>
        </div>
      </div>

      <div class="bg-white rounded-xl shadow-lg border border-slate-200 p-6">
        <div class="flex items-center justify-between">
          <div>
            <h3 class="text-sm font-medium text-slate-600 mb-2">Activation Rate</h3>
            <p class="text-3xl font-bold text-slate-900">{{ stats.activation_rate }}%</p>
            <p class="text-sm text-green-600 mt-1">{{ stats.total_activated }} active</p>
          </div>
          <div class="p-4 bg-gradient-to-r from-green-500 to-emerald-500 rounded-xl">
            <i class="pi pi-check-circle text-white text-2xl"></i>
          </div>
        </div>
      </div>

      <div class="bg-white rounded-xl shadow-lg border border-slate-200 p-6">
        <div class="flex items-center justify-between">
          <div>
            <h3 class="text-sm font-medium text-slate-600 mb-2">Batches</h3>
            <p class="text-3xl font-bold text-slate-900">{{ stats.total_batches }}</p>
          </div>
          <div class="p-4 bg-gradient-to-r from-purple-500 to-violet-500 rounded-xl">
            <i class="pi pi-box text-white text-2xl"></i>
          </div>
        </div>
      </div>
    </div>

    <!-- Batches DataTable -->
    <div class="bg-white rounded-xl shadow-lg border border-slate-200 overflow-hidden">
      <div class="p-6 border-b border-slate-200 bg-gradient-to-r from-slate-50 to-slate-100">
        <div class="flex justify-between items-center">
          <h3 class="text-lg font-semibold text-slate-900">Card Batches</h3>
          <Button 
            label="Issue New Batch" 
            icon="pi pi-plus"
            @click="showCreateBatchDialog = true"
            class="bg-gradient-to-r from-blue-600 to-purple-600 hover:from-blue-700 hover:to-purple-700 border-0"
          />
        </div>
      </div>
      <div class="p-6">
        <DataTable 
          :value="batches" 
          :loading="loadingBatches"
          :paginator="true" 
          :rows="10"
          :rowsPerPageOptions="[10, 25, 50]"
          responsiveLayout="scroll"
          paginatorTemplate="RowsPerPageDropdown FirstPageLink PrevPageLink CurrentPageReport NextPageLink LastPageLink"
          currentPageReportTemplate="{first} to {last} of {totalRecords}"
          class="w-full"
        >
          <Column field="batch_name" header="Batch Name" :sortable="true">
            <template #body="{ data }">
              <div class="font-medium text-slate-900">{{ data.batch_name }}</div>
            </template>
          </Column>

          <Column field="cards_count" header="Cards" :sortable="true">
            <template #body="{ data }">
              <div class="text-center">
                <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
                  {{ data.cards_count }} cards
                </span>
              </div>
            </template>
          </Column>

          <Column field="payment_status" header="Payment" :sortable="true">
            <template #body="{ data }">
              <div class="text-center">
                <span :class="getPaymentStatusClass(data.payment_status)">
                  {{ formatPaymentStatus(data.payment_status) }}
                </span>
              </div>
            </template>
          </Column>

          <Column field="total_amount" header="Amount" :sortable="true">
            <template #body="{ data }">
              <div class="text-right font-medium text-slate-900">
                ${{ (data.total_amount / 100).toFixed(2) }}
              </div>
            </template>
          </Column>

          <Column field="created_at" header="Created" :sortable="true">
            <template #body="{ data }">
              <div class="text-sm text-slate-600">
                {{ formatDate(data.created_at) }}
              </div>
            </template>
          </Column>

          <Column header="Actions">
            <template #body="{ data }">
              <div class="flex gap-2">
                <Button 
                  v-if="data.payment_status === 'pending'"
                  label="Pay Now" 
                  size="small"
                  @click="handlePayment(data)"
                  :loading="data.id === processingBatchId"
                  class="bg-gradient-to-r from-green-600 to-emerald-600 hover:from-green-700 hover:to-emerald-700 border-0"
                />
                <Button 
                  v-if="data.payment_status === 'completed'"
                  label="View Cards" 
                  size="small"
                  outlined
                  @click="viewBatchCards(data)"
                  class="border-blue-600 text-blue-600 hover:bg-blue-50"
                />
                <Button 
                  label="Details" 
                  size="small"
                  outlined
                  @click="viewBatchDetails(data)"
                  class="border-slate-600 text-slate-600 hover:bg-slate-50"
                />
              </div>
            </template>
          </Column>
        </DataTable>
      </div>
    </div>

    <!-- Create Batch Dialog -->
    <Dialog 
      v-model:visible="showCreateBatchDialog" 
      modal 
      header="Issue New Card Batch" 
      style="width: 500px"
    >
      <div class="space-y-6">
        <div>
          <label class="block text-sm font-medium text-slate-700 mb-2">Number of Cards</label>
          <InputNumber 
            v-model="newBatch.cardCount"
            :min="1"
            :max="1000"
            placeholder="Enter number of cards"
            class="w-full"
          />
          <small class="text-slate-500 mt-1">
            Cost: ${{ ((newBatch.cardCount || 0) * 2).toFixed(2) }} ($2.00 per card)
          </small>
        </div>

        <div>
          <label class="block text-sm font-medium text-slate-700 mb-2">Card Design</label>
          <div v-if="currentCard" class="flex items-center gap-3 p-3 border border-slate-200 rounded-lg bg-slate-50">
            <img 
              :src="currentCard.image_url || defaultImageUrl" 
              :alt="currentCard.title"
              class="w-12 h-16 object-cover rounded border border-slate-200"
            />
            <div>
              <div class="font-medium text-slate-900">{{ currentCard.title }}</div>
              <div class="text-sm text-slate-600">{{ currentCard.description }}</div>
            </div>
          </div>
          <div v-else class="p-3 border border-slate-200 rounded-lg bg-slate-50 text-slate-500">
            Loading card information...
          </div>
        </div>

        <div class="bg-blue-50 border border-blue-200 rounded-lg p-4">
          <h4 class="font-medium text-blue-900 mb-2">What happens next?</h4>
          <ul class="text-sm text-blue-800 space-y-1">
            <li>• Batch will be created automatically (name: "batch-{{ stats.total_batches + 1 }}")</li>
            <li>• You'll be redirected to Stripe Checkout for secure payment</li>
            <li>• Cards will be generated automatically after successful payment</li>
            <li>• You can then distribute QR codes to your visitors</li>
          </ul>
        </div>
      </div>

      <template #footer>
        <div class="flex gap-3 justify-end">
          <Button 
            label="Cancel" 
            outlined 
            @click="showCreateBatchDialog = false"
          />
          <Button 
            label="Issue & Pay" 
            @click="createBatch"
            :loading="creatingBatch"
            :disabled="!newBatch.cardCount || !currentCard"
            class="bg-gradient-to-r from-blue-600 to-purple-600 hover:from-blue-700 hover:to-purple-700 border-0"
          />
        </div>
      </template>
    </Dialog>

    <!-- Success Message -->
    <div v-if="showSuccessMessage" class="fixed inset-0 z-50 flex items-center justify-center bg-black bg-opacity-50">
      <div class="bg-white rounded-xl shadow-2xl p-8 max-w-md mx-4">
        <div class="text-center">
          <div class="w-16 h-16 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-4">
            <i class="pi pi-check text-green-600 text-2xl"></i>
          </div>
          <h3 class="text-xl font-semibold text-slate-900 mb-2">Payment Successful!</h3>
          <p class="text-slate-600 mb-6">
            Your cards have been generated and are ready for distribution.
          </p>
          <Button 
            label="View Cards" 
            @click="closeSuccessMessage"
            class="bg-gradient-to-r from-blue-600 to-purple-600 hover:from-blue-700 hover:to-purple-700 border-0"
          />
        </div>
      </div>
    </div>

    <!-- Batch Details Dialog -->
    <Dialog 
      v-model:visible="showBatchDetailsDialog" 
      modal 
      header="Batch Details" 
      style="width: 600px"
    >
      <div v-if="loadingBatchDetails" class="flex items-center justify-center py-12">
        <i class="pi pi-spin pi-spinner text-4xl text-blue-600"></i>
      </div>
      <div v-else-if="selectedBatch" class="space-y-6">
        <!-- Batch Info -->
        <div class="grid grid-cols-2 gap-4">
          <div>
            <label class="text-sm font-medium text-slate-600">Batch Name</label>
            <p class="text-lg font-semibold text-slate-900">{{ selectedBatch.batch_name }}</p>
          </div>
          <div>
            <label class="text-sm font-medium text-slate-600">Batch Number</label>
            <p class="text-lg font-semibold text-slate-900">#{{ selectedBatch.batch_number }}</p>
          </div>
        </div>

        <!-- Cards Info -->
        <div class="grid grid-cols-2 gap-4">
          <div>
            <label class="text-sm font-medium text-slate-600">Total Cards</label>
            <p class="text-lg font-semibold text-slate-900">{{ selectedBatch.cards_count }}</p>
          </div>
          <div>
            <label class="text-sm font-medium text-slate-600">Active Cards</label>
            <p class="text-lg font-semibold text-slate-900">{{ selectedBatch.active_cards_count || 0 }}</p>
          </div>
        </div>

        <!-- Payment Info -->
        <div class="bg-slate-50 rounded-lg p-4">
          <h4 class="font-medium text-slate-900 mb-3">Payment Information</h4>
          <div class="grid grid-cols-2 gap-4">
            <div>
              <label class="text-sm text-slate-600">Status</label>
              <p class="mt-1">
                <span :class="getPaymentStatusClass(selectedBatch.payment_status)">
                  {{ formatPaymentStatus(selectedBatch.payment_status) }}
                </span>
              </p>
            </div>
            <div>
              <label class="text-sm text-slate-600">Amount</label>
              <p class="font-semibold text-slate-900">${{ (selectedBatch.total_amount / 100).toFixed(2) }}</p>
            </div>
            <div v-if="selectedBatch.payment_completed_at">
              <label class="text-sm text-slate-600">Paid At</label>
              <p class="text-slate-900">{{ formatDate(selectedBatch.payment_completed_at) }}</p>
            </div>
            <div v-if="selectedBatch.payment_waived">
              <label class="text-sm text-slate-600">Payment Waived</label>
              <p class="text-slate-900">Yes - {{ selectedBatch.payment_waiver_reason }}</p>
            </div>
          </div>
        </div>

        <!-- Cards Generation Status -->
        <div class="bg-slate-50 rounded-lg p-4">
          <h4 class="font-medium text-slate-900 mb-3">Cards Generation</h4>
          <div class="grid grid-cols-2 gap-4">
            <div>
              <label class="text-sm text-slate-600">Generated</label>
              <p class="font-semibold">
                <span :class="selectedBatch.cards_generated ? 'text-green-700' : 'text-yellow-700'">
                  {{ selectedBatch.cards_generated ? 'Yes' : 'No' }}
                </span>
              </p>
            </div>
            <div v-if="selectedBatch.cards_generated_at">
              <label class="text-sm text-slate-600">Generated At</label>
              <p class="text-slate-900">{{ formatDate(selectedBatch.cards_generated_at) }}</p>
            </div>
          </div>
        </div>

        <!-- Timestamps -->
        <div class="bg-slate-50 rounded-lg p-4">
          <h4 class="font-medium text-slate-900 mb-3">Timestamps</h4>
          <div class="grid grid-cols-2 gap-4">
            <div>
              <label class="text-sm text-slate-600">Created At</label>
              <p class="text-slate-900">{{ formatDate(selectedBatch.created_at) }}</p>
            </div>
            <div>
              <label class="text-sm text-slate-600">Updated At</label>
              <p class="text-slate-900">{{ formatDate(selectedBatch.updated_at) }}</p>
            </div>
          </div>
        </div>

        <!-- Status Info -->
        <div v-if="selectedBatch.is_disabled" class="bg-red-50 border border-red-200 rounded-lg p-4">
          <div class="flex items-center gap-2">
            <i class="pi pi-exclamation-triangle text-red-600"></i>
            <span class="font-medium text-red-900">This batch is disabled</span>
          </div>
        </div>

        <!-- Actions -->
        <div v-if="selectedBatch.payment_status === 'pending'" class="bg-blue-50 border border-blue-200 rounded-lg p-4">
          <h4 class="font-medium text-blue-900 mb-3">Actions Required</h4>
          <Button 
            label="Complete Payment" 
            icon="pi pi-credit-card"
            @click="handlePaymentFromDetails()"
            class="bg-gradient-to-r from-green-600 to-emerald-600 hover:from-green-700 hover:to-emerald-700 border-0"
          />
        </div>
      </div>

      <template #footer>
        <div class="flex gap-3 justify-end">
          <Button 
            label="Close" 
            outlined 
            @click="showBatchDetailsDialog = false"
          />
          <Button 
            v-if="selectedBatch?.payment_status === 'completed' && selectedBatch?.cards_generated"
            label="View Cards" 
            icon="pi pi-eye"
            @click="viewBatchCards(selectedBatch)"
            class="bg-gradient-to-r from-blue-600 to-purple-600 hover:from-blue-700 hover:to-purple-700 border-0"
          />
          <Button 
            v-if="selectedBatch?.payment_status === 'completed' && selectedBatch?.cards_generated"
            label="Download Codes" 
            icon="pi pi-download"
            @click="downloadBatchCodes(selectedBatch)"
            outlined
            class="border-blue-600 text-blue-600 hover:bg-blue-50"
          />
        </div>
      </template>
    </Dialog>
  </div>
</template>

<script setup>
import { ref, onMounted, computed } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import DataTable from 'primevue/datatable'
import Column from 'primevue/column'
import Button from 'primevue/button'
import Dialog from 'primevue/dialog'
import InputText from 'primevue/inputtext'
import InputNumber from 'primevue/inputnumber'
import { useToast } from 'primevue/usetoast'
import { supabase } from '@/lib/supabase'
import { createCheckoutSession, handleCheckoutSuccess, getBatchPaymentStatus } from '@/utils/stripeCheckout.js'

const router = useRouter()
const route = useRoute()
const toast = useToast()

// Props
const props = defineProps({
  cardId: {
    type: String,
    required: true
  }
})

// State
const batches = ref([])
const stats = ref({
  total_issued: 0,
  total_activated: 0,
  activation_rate: 0,
  total_batches: 0
})
const currentCard = ref(null)
const loadingBatches = ref(false)
const creatingBatch = ref(false)
const processingBatchId = ref(null)
const showCreateBatchDialog = ref(false)
const showSuccessMessage = ref(false)
const showBatchDetailsDialog = ref(false)
const selectedBatch = ref(null)
const loadingBatchDetails = ref(false)

// New batch form
const newBatch = ref({
  cardCount: 50
})

// Default image
const defaultImageUrl = import.meta.env.VITE_DEFAULT_CARD_IMAGE_URL || 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=600&q=80'

// Methods
const loadData = async () => {
  await Promise.all([
    loadBatches(),
    loadStats(),
    loadCurrentCard()
  ])
}

const loadBatches = async () => {
  try {
    loadingBatches.value = true
    
    const { data, error } = await supabase.rpc('get_card_batches', {
      p_card_id: props.cardId
    })

    if (error) throw error

    // Process batches with payment info
    batches.value = (data || []).map(batch => ({
      ...batch,
      payment_status: batch.payment_completed ? 'completed' : 
                     batch.payment_waived ? 'waived' : 
                     batch.payment_required ? 'pending' : 'not_required',
      total_amount: batch.payment_amount_cents || (batch.cards_count * 200)
    }))

  } catch (error) {
    console.error('Error loading batches:', error)
    toast.add({
      severity: 'error',
      summary: 'Error',
      detail: 'Failed to load batches',
      life: 5000
    })
  } finally {
    loadingBatches.value = false
  }
}

const loadStats = async () => {
  try {
    const { data, error } = await supabase.rpc('get_card_issuance_stats', {
      p_card_id: props.cardId
    })
    
    if (error) throw error

    if (data && data.length > 0) {
      const statsData = data[0]
      stats.value = {
        total_issued: statsData.total_issued || 0,
        total_activated: statsData.total_activated || 0,
        activation_rate: Math.round(statsData.activation_rate || 0),
        total_batches: statsData.total_batches || 0
      }
    } else {
      stats.value = {
        total_issued: 0,
        total_activated: 0,
        activation_rate: 0,
        total_batches: 0
      }
    }

  } catch (error) {
    console.error('Error loading stats:', error)
  }
}

const loadCurrentCard = async () => {
  try {
    const { data, error } = await supabase.rpc('get_card_by_id', {
      p_card_id: props.cardId
    })

    if (error) throw error
    
    // Transform data to match expected structure
    currentCard.value = {
      ...data,
      title: data.name, // Map name to title for compatibility
      image_url: data.image_urls?.[0] || null // Use first image if available
    }

  } catch (error) {
    console.error('Error loading current card:', error)
    toast.add({
      severity: 'error',
      summary: 'Error',
      detail: 'Failed to load card information',
      life: 5000
    })
  }
}

const createBatch = async () => {
  try {
    creatingBatch.value = true

    // Create batch using stored procedure
    const { data: batchId, error: batchError } = await supabase.rpc('issue_card_batch', {
      p_card_id: props.cardId,
      p_quantity: newBatch.value.cardCount
    })

    if (batchError) throw batchError

    // Create a batch object for payment processing
    const batch = {
      id: batchId,
      batch_name: newBatch.value.name,
      cards_count: newBatch.value.cardCount
    }

    // Close dialog
    showCreateBatchDialog.value = false
    
    // Reset form
    newBatch.value = {
      name: '',
      cardCount: 50
    }

    // Initiate payment
    await handlePayment(batch)

  } catch (error) {
    console.error('Error creating batch:', error)
    toast.add({
      severity: 'error',
      summary: 'Error',
      detail: error.message || 'Failed to create batch',
      life: 5000
    })
  } finally {
    creatingBatch.value = false
  }
}

const handlePayment = async (batch) => {
  try {
    processingBatchId.value = batch.id

    // Create checkout session and redirect to Stripe
    await createCheckoutSession(batch.cards_count, batch.id, {
      batch_name: batch.batch_name
    })

  } catch (error) {
    console.error('Payment error:', error)
    toast.add({
      severity: 'error',
      summary: 'Payment Error',
      detail: error.message || 'Failed to initiate payment',
      life: 5000
    })
  } finally {
    processingBatchId.value = null
  }
}

const viewBatchCards = (batch) => {
  router.push(`/cms/issuedcards?batch_id=${batch.id}`)
}

const viewBatchDetails = async (batch) => {
  selectedBatch.value = batch
  showBatchDetailsDialog.value = true
  loadingBatchDetails.value = true
  
  // Load additional batch details if needed
  try {
    // Get issued cards count for this batch
    const { data: issuedCards, error } = await supabase.rpc('get_issued_cards_with_batch', {
      p_card_id: props.cardId
    })
    
    if (!error && issuedCards) {
      const batchCards = issuedCards.filter(card => card.batch_id === batch.id)
      selectedBatch.value = {
        ...selectedBatch.value,
        issued_cards_count: batchCards.length,
        active_cards_count: batchCards.filter(card => card.active).length
      }
    }
  } catch (error) {
    console.error('Error loading batch details:', error)
  } finally {
    loadingBatchDetails.value = false
  }
}

const handlePaymentFromDetails = () => {
  showBatchDetailsDialog.value = false
  handlePayment(selectedBatch.value)
}

const downloadBatchCodes = async (batch) => {
  try {
    // Get all issued cards for this batch
    const { data: issuedCards, error } = await supabase.rpc('get_issued_cards_with_batch', {
      p_card_id: props.cardId
    })
    
    if (error) throw error
    
    const batchCards = issuedCards.filter(card => card.batch_id === batch.id)
    
    // Create CSV content
    const headers = ['Card Number', 'Issue Card ID', 'Status', 'QR Code URL']
    const rows = batchCards.map((card, index) => [
      index + 1,
      card.id,
      card.active ? 'Active' : 'Inactive',
      `${window.location.origin}/c/${card.id}`
    ])
    
    const csvContent = [
      headers.join(','),
      ...rows.map(row => row.join(','))
    ].join('\n')
    
    // Download CSV
    const blob = new Blob([csvContent], { type: 'text/csv' })
    const url = window.URL.createObjectURL(blob)
    const a = document.createElement('a')
    a.href = url
    a.download = `${currentCard.value?.title || 'cards'}_${batch.batch_name}_codes.csv`
    document.body.appendChild(a)
    a.click()
    document.body.removeChild(a)
    window.URL.revokeObjectURL(url)
    
    toast.add({
      severity: 'success',
      summary: 'Download Started',
      detail: `Downloaded ${batchCards.length} card access codes`,
      life: 3000
    })
    
  } catch (error) {
    console.error('Error downloading codes:', error)
    toast.add({
      severity: 'error',
      summary: 'Download Failed',
      detail: 'Failed to download activation codes',
      life: 5000
    })
  }
}

const closeSuccessMessage = () => {
  showSuccessMessage.value = false
  loadData() // Refresh data
}

// Payment status helpers
const getPaymentStatusClass = (status) => {
  const classes = {
    pending: 'inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-yellow-100 text-yellow-800',
    completed: 'inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800',
    succeeded: 'inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800',
    failed: 'inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-red-100 text-red-800',
    canceled: 'inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-gray-100 text-gray-800'
  }
  return classes[status] || classes.pending
}

const formatPaymentStatus = (status) => {
  const statuses = {
    pending: 'Pending',
    completed: 'Paid',
    succeeded: 'Paid',
    failed: 'Failed',
    canceled: 'Canceled'
  }
  return statuses[status] || 'Unknown'
}

const formatDate = (dateString) => {
  return new Date(dateString).toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  })
}

// Handle checkout success on page load
const handlePageLoad = async () => {
  const sessionId = route.query.session_id
  const batchId = route.query.batch_id
  const canceled = route.query.canceled

  if (canceled) {
    toast.add({
      severity: 'warn',
      summary: 'Payment Canceled',
      detail: 'Payment was canceled. You can retry payment anytime.',
      life: 5000
    })
    // Clean URL
    router.replace('/cms/mycards')
    return
  }

  if (sessionId && batchId) {
    try {
      // Process successful payment
      await handleCheckoutSuccess(sessionId)
      
      // Show success message
      showSuccessMessage.value = true
      
      // Clean URL
      router.replace('/cms/mycards')
      
    } catch (error) {
      console.error('Error processing checkout success:', error)
      toast.add({
        severity: 'error',
        summary: 'Payment Processing Error',
        detail: 'Payment was successful but there was an issue processing it. Please contact support.',
        life: 10000
      })
    }
  }
}

// Lifecycle
onMounted(async () => {
  await handlePageLoad()
  await loadData()
})
</script>

<style scoped>
/* Custom styles for better UX */
.p-datatable {
  border-radius: 0;
}

.p-datatable .p-datatable-thead > tr > th {
  background: #f8fafc;
  border: none;
  color: #475569;
  font-weight: 600;
  font-size: 0.875rem;
}

.p-datatable .p-datatable-tbody > tr {
  border: none;
}

.p-datatable .p-datatable-tbody > tr > td {
  border: none;
  border-bottom: 1px solid #e2e8f0;
}

.p-datatable .p-datatable-tbody > tr:hover {
  background: #f8fafc;
}
</style>