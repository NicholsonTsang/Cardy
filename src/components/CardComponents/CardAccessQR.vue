<template>
  <div class="space-y-6">
    <!-- Header -->
    <div class="text-center">
      <h3 class="text-lg font-semibold text-slate-900 mb-2">{{ $t('batches.qr_codes_and_access') }}</h3>
      <p class="text-slate-600 text-sm">{{ $t('batches.generate_qr_codes') }}</p>
    </div>
    
    <!-- Loading State -->
    <div v-if="loading" class="flex flex-col items-center justify-center py-12">
      <div class="relative">
        <div class="w-16 h-16 rounded-full bg-blue-100 animate-pulse"></div>
        <i class="pi pi-spin pi-spinner text-3xl text-blue-600 absolute inset-0 flex items-center justify-center"></i>
      </div>
      <p class="text-slate-500 mt-4">{{ $t('common.loading') }}...</p>
    </div>
    
    <!-- No Batches State -->
    <div v-else-if="!batches.length" class="bg-white rounded-xl shadow-lg border border-slate-200 p-8 text-center">
      <div class="w-20 h-20 bg-gradient-to-br from-slate-100 to-slate-200 rounded-full flex items-center justify-center mx-auto mb-4">
        <i class="pi pi-qrcode text-3xl text-slate-400"></i>
      </div>
      <h4 class="text-lg font-semibold text-slate-900 mb-2">{{ $t('batches.no_batches_found') }}</h4>
      <p class="text-slate-500 text-sm max-w-sm mx-auto">{{ $t('batches.create_batch_for_qr') }}</p>
    </div>
    
    <!-- QR Code Generator -->
    <div v-else class="space-y-6">
      <!-- Batch Selector Card -->
      <div class="bg-white rounded-xl shadow-lg border border-slate-200 overflow-hidden">
        <div class="p-4 border-b border-slate-200 bg-gradient-to-r from-slate-50 to-slate-100">
          <div class="flex items-center gap-3">
            <div class="p-2 bg-gradient-to-r from-blue-500 to-purple-500 rounded-lg">
              <i class="pi pi-box text-white"></i>
            </div>
            <div>
              <h4 class="font-semibold text-slate-900">{{ $t('batches.select_card_batch') }}</h4>
              <p class="text-xs text-slate-500">{{ $t('batches.only_paid_batches') }}</p>
            </div>
          </div>
        </div>
        <div class="p-4">
          <Dropdown 
            v-model="selectedBatch"
            :options="availableBatches"
            optionLabel="display_name"
            optionValue="id"
            :placeholder="$t('batches.choose_batch_to_generate')"
            class="w-full"
            @change="onBatchChange"
          />
        </div>
      </div>
      
      <!-- QR Code Display -->
      <div v-if="selectedBatch && selectedBatchData" class="bg-white rounded-xl shadow-lg border border-slate-200 overflow-hidden">
        <!-- Header with Actions -->
        <div class="p-4 border-b border-slate-200 bg-gradient-to-r from-slate-50 to-slate-100">
          <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
            <div class="flex items-center gap-3">
              <div class="p-2 bg-gradient-to-r from-blue-500 to-indigo-500 rounded-lg">
                <i class="pi pi-qrcode text-white"></i>
              </div>
              <div>
                <h4 class="font-semibold text-slate-900">{{ $t('batches.qr_codes_and_urls') }}</h4>
                <p class="text-xs text-slate-500">{{ selectedBatchData.batch_name }}</p>
              </div>
            </div>
            <div class="flex flex-wrap gap-2">
              <Button 
                :label="$t('batches.download_all_qr')" 
                icon="pi pi-download"
                @click="downloadAllQRCodes"
                size="small"
                class="bg-gradient-to-r from-blue-600 to-purple-600 hover:from-blue-700 hover:to-purple-700 border-0"
              />
              <Button 
                :label="$t('batches.download_csv')" 
                icon="pi pi-file-excel"
                @click="downloadCSV"
                severity="secondary"
                outlined
                size="small"
              />
            </div>
          </div>
        </div>
        
        <!-- Batch Stats -->
        <div class="p-4 border-b border-slate-100 bg-slate-50/50">
          <div class="grid grid-cols-3 gap-4">
            <div class="text-center">
              <div class="flex items-center justify-center gap-2 mb-1">
                <i class="pi pi-credit-card text-blue-600 text-sm"></i>
                <span class="text-xs font-medium text-slate-500 uppercase tracking-wider">{{ $t('batches.total_cards') }}</span>
              </div>
              <p class="text-2xl font-bold text-slate-900">{{ selectedBatchData.cards_count }}</p>
            </div>
            <div class="text-center border-x border-slate-200">
              <div class="flex items-center justify-center gap-2 mb-1">
                <i class="pi pi-check-circle text-green-600 text-sm"></i>
                <span class="text-xs font-medium text-slate-500 uppercase tracking-wider">{{ $t('batches.active_cards') }}</span>
              </div>
              <p class="text-2xl font-bold text-green-600">{{ issuedCards.filter(card => card.active).length }}</p>
            </div>
            <div class="text-center">
              <div class="flex items-center justify-center gap-2 mb-1">
                <i class="pi pi-clock text-yellow-600 text-sm"></i>
                <span class="text-xs font-medium text-slate-500 uppercase tracking-wider">{{ $t('common.inactive') }}</span>
              </div>
              <p class="text-2xl font-bold text-yellow-600">{{ issuedCards.filter(card => !card.active).length }}</p>
            </div>
          </div>
        </div>
        
        <!-- QR Code Grid -->
        <div v-if="issuedCards.length" class="p-4">
          <div class="flex items-center justify-between mb-4">
            <h5 class="font-medium text-slate-900 flex items-center gap-2">
              <i class="pi pi-th-large text-slate-400"></i>
              {{ $t('batches.individual_qr_codes') }}
            </h5>
            <div class="flex items-center gap-2">
              <label class="text-xs text-slate-500">{{ $t('batches.show') }}:</label>
              <Dropdown 
                v-model="displayFilter"
                :options="filterOptions"
                optionLabel="label"
                optionValue="value"
                class="w-32"
              />
            </div>
          </div>
          
          <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4 max-h-[480px] overflow-y-auto pr-1">
            <div 
              v-for="(card, index) in filteredCards" 
              :key="card.id"
              class="group bg-white border border-slate-200 rounded-xl p-4 hover:border-blue-300 hover:shadow-md transition-all duration-200"
            >
              <div class="text-center">
                <!-- QR Code with hover effect -->
                <div class="relative inline-block mb-3">
                  <div class="absolute -inset-1 bg-gradient-to-r from-blue-500/20 to-purple-500/20 rounded-xl opacity-0 group-hover:opacity-100 transition-opacity"></div>
                  <div class="relative bg-white p-3 rounded-lg border border-slate-200 shadow-sm">
                    <QrCode :value="getCardURL(card.id)" :size="120" />
                  </div>
                </div>
                
                <!-- Card Info -->
                <div class="space-y-2">
                  <div class="flex items-center justify-center gap-2">
                    <span class="text-sm font-semibold text-slate-900">{{ $t('common.card_prefix') }}{{ index + 1 }}</span>
                    <span 
                      :class="card.active 
                        ? 'bg-green-100 text-green-700' 
                        : 'bg-yellow-100 text-yellow-700'"
                      class="text-xs font-medium px-2 py-0.5 rounded-full"
                    >
                      {{ card.active ? $t('common.active') : $t('common.inactive') }}
                    </span>
                  </div>
                  <div class="text-xs text-slate-400 font-mono truncate max-w-[180px] mx-auto" :title="card.id">
                    {{ card.id.substring(0, 8) }}...
                  </div>
                  
                  <!-- Actions -->
                  <div class="flex gap-1 justify-center pt-2">
                    <Button 
                      icon="pi pi-copy"
                      @click="copyURL(card.id)"
                      severity="secondary"
                      size="small"
                      text
                      rounded
                      v-tooltip.top="$t('batches.copy_url')"
                    />
                    <Button 
                      icon="pi pi-download"
                      @click="downloadSingleQR(card.id, index + 1)"
                      severity="secondary"
                      size="small"
                      text
                      rounded
                      v-tooltip.top="$t('batches.download_qr')"
                    />
                    <Button 
                      icon="pi pi-external-link"
                      @click="openCard(card.id)"
                      severity="secondary"
                      size="small"
                      text
                      rounded
                      v-tooltip.top="$t('batches.open_card')"
                    />
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import { useToast } from 'primevue/usetoast'
import Button from 'primevue/button'
import Dropdown from 'primevue/dropdown'
import QrCode from 'qrcode.vue'
import * as QRCodeLib from 'qrcode'
import JSZip from 'jszip'
import { supabase } from '@/lib/supabase'

const { t } = useI18n()

const props = defineProps({
  cardId: {
    type: String,
    required: true
  },
  cardName: {
    type: String,
    required: true
  },
  selectedBatchId: {
    type: String,
    default: null
  }
})

const emit = defineEmits(['batch-changed'])

const toast = useToast()

// State
const loading = ref(true)
const batches = ref([])
const issuedCards = ref([])
const selectedBatch = ref(null)
const displayFilter = ref('all')

// Filter options
const filterOptions = computed(() => [
  { label: t('batches.all_cards'), value: 'all' },
  { label: t('batches.active_only'), value: 'active' },
  { label: t('batches.inactive_only'), value: 'inactive' }
])

// Computed
const availableBatches = computed(() => {
  return batches.value
    .filter(batch => {
      // Include batches that are either paid, waived, or admin-issued
      const isPaymentComplete = batch.payment_completed || batch.payment_waived || !batch.payment_required
      return isPaymentComplete && batch.cards_generated
    })
    .map(batch => ({
      ...batch,
      display_name: `${batch.batch_name} (${batch.cards_count} ${t('batches.cards').toLowerCase()})`
    }))
})

const selectedBatchData = computed(() => {
  return batches.value.find(batch => batch.id === selectedBatch.value)
})

const filteredCards = computed(() => {
  if (displayFilter.value === 'active') {
    return issuedCards.value.filter(card => card.active)
  } else if (displayFilter.value === 'inactive') {
    return issuedCards.value.filter(card => !card.active)
  }
  return issuedCards.value
})

// Methods
const getCardURL = (issueCardId) => {
  return `${window.location.origin}/c/${issueCardId}`
}

const loadBatches = async () => {
  try {
    const { data, error } = await supabase.rpc('get_card_batches', {
      p_card_id: props.cardId
    })
    
    if (error) throw error
    batches.value = data || []
  } catch (err) {
    console.error('Error loading batches:', err)
    toast.add({
      severity: 'error',
      summary: t('messages.operation_failed'),
      detail: t('batches.failed_to_load_batches'),
      life: 5000
    })
  }
}

const loadIssuedCards = async (batchId) => {
  try {
    const { data, error } = await supabase.rpc('get_issued_cards_with_batch', {
      p_card_id: props.cardId
    })
    
    if (error) throw error
    
    issuedCards.value = (data || []).filter(card => card.batch_id === batchId)
  } catch (err) {
    console.error('Error loading issued cards:', err)
    toast.add({
      severity: 'error',
      summary: t('messages.operation_failed'),
      detail: t('batches.failed_to_load_issued_cards'),
      life: 5000
    })
  }
}

const onBatchChange = async () => {
  if (selectedBatch.value) {
    await loadIssuedCards(selectedBatch.value)
    // Emit the batch change event to update URL
    emit('batch-changed', selectedBatch.value)
  }
}

const copyURL = async (issueCardId) => {
  try {
    const url = getCardURL(issueCardId)
    await navigator.clipboard.writeText(url)
    // Copy success - no toast needed for micro-interaction
  } catch (err) {
    toast.add({
      severity: 'error',
      summary: t('messages.copy_failed'),
      detail: t('messages.could_not_copy_url'),
      life: 3000
    })
  }
}

const openCard = (issueCardId) => {
  const url = getCardURL(issueCardId)
  window.open(url, '_blank')
}

const downloadSingleQR = async (issueCardId, cardNumber) => {
  try {
    const url = getCardURL(issueCardId)
    const qrDataURL = await QRCodeLib.toDataURL(url, { width: 512 })
    
    const link = document.createElement('a')
    link.href = qrDataURL
    link.download = `${props.cardName}_card_${cardNumber}_qr.png`
    document.body.appendChild(link)
    link.click()
    document.body.removeChild(link)
    // Browser shows download notification - no toast needed
  } catch (err) {
    toast.add({
      severity: 'error',
      summary: t('messages.download_failed'),
      detail: t('messages.could_not_generate_qr'),
      life: 3000
    })
  }
}

const downloadAllQRCodes = async () => {
  if (!filteredCards.value.length) {
    toast.add({
      severity: 'warn',
      summary: t('messages.no_cards'),
      detail: t('batches.no_cards_to_download'),
      life: 3000
    })
    return
  }

  try {
    toast.add({
      severity: 'info',
      summary: t('batches.generating_qr_codes'),
      detail: t('batches.please_wait_generating', { count: filteredCards.value.length }),
      life: 3000
    })

    const zip = new JSZip()
    const qrFolder = zip.folder('qr_codes')
    
    // Generate QR codes for all filtered cards
    for (let i = 0; i < filteredCards.value.length; i++) {
      const card = filteredCards.value[i]
      const cardNumber = i + 1
      const url = getCardURL(card.id)
      
      // Generate QR code as data URL (browser-compatible)
      const qrDataURL = await QRCodeLib.toDataURL(url, { 
        width: 512,
        margin: 2,
        errorCorrectionLevel: 'M'
      })
      
      // Convert data URL to Blob
      const response = await fetch(qrDataURL)
      const blob = await response.blob()
      
      // Add to ZIP with card number and status
      const fileName = `card_${String(cardNumber).padStart(3, '0')}_${card.active ? 'active' : 'inactive'}.png`
      qrFolder.file(fileName, blob)
    }
    
    // Generate README with card information
    const readmeContent = generateReadmeContent()
    zip.file('README.txt', readmeContent)
    
    // Generate the ZIP file
    const zipBlob = await zip.generateAsync({ type: 'blob' })
    
    // Trigger download
    const link = document.createElement('a')
    link.href = window.URL.createObjectURL(zipBlob)
    const timestamp = new Date().toISOString().split('T')[0]
    link.download = `${props.cardName}_${selectedBatchData.value?.batch_name || 'batch'}_qr_codes_${timestamp}.zip`
    document.body.appendChild(link)
    link.click()
    document.body.removeChild(link)
    window.URL.revokeObjectURL(link.href)
    
    toast.add({
      severity: 'success',
      summary: t('messages.download_complete'),
      detail: t('batches.qr_codes_downloaded', { count: filteredCards.value.length }),
      life: 3000
    })
  } catch (err) {
    console.error('Error generating QR codes ZIP:', err)
    toast.add({
      severity: 'error',
      summary: t('messages.download_failed'),
      detail: t('batches.failed_to_generate_qr_zip'),
      life: 5000
    })
  }
}

const generateReadmeContent = () => {
  const batch = selectedBatchData.value
  const cards = filteredCards.value
  
  return `${props.cardName} - QR Codes
${'='.repeat(50)}

Batch Information:
- Batch Name: ${batch.batch_name}
- Total Cards: ${cards.length}
- Active Cards: ${cards.filter(c => c.active).length}
- Inactive Cards: ${cards.filter(c => !c.active).length}
- Generated: ${new Date().toLocaleString()}

QR Code Files:
${cards.map((card, i) => {
  const num = String(i + 1).padStart(3, '0')
  const status = card.active ? 'Active' : 'Inactive'
  const url = getCardURL(card.id)
  return `- card_${num}_${card.active ? 'active' : 'inactive'}.png
  Card ID: ${card.id}
  Status: ${status}
  URL: ${url}`
}).join('\n\n')}

${'='.repeat(50)}
How to Use:
1. Each QR code file is named with its card number and status
2. Scan any QR code to access the digital card
3. Active cards are immediately accessible
4. Inactive cards can be activated via admin panel

For support, contact your ExperienceQR administrator.
`
}

const downloadCSV = () => {
  try {
    const headers = [
      t('batches.csv_card_number'),
      t('batches.csv_issue_card_id'),
      t('batches.csv_status'),
      t('batches.csv_card_url')
    ]
    const rows = issuedCards.value.map((card, index) => [
      index + 1,
      card.id,
      card.active ? t('common.active') : t('common.inactive'),
      getCardURL(card.id)
    ])
    
    const csvContent = [
      headers.join(','),
      ...rows.map(row => row.map(field => `"${field}"`).join(','))
    ].join('\n')
    
    const blob = new Blob([csvContent], { type: 'text/csv' })
    const url = window.URL.createObjectURL(blob)
    const link = document.createElement('a')
    link.href = url
    link.download = `${props.cardName}_${selectedBatchData.value?.batch_name || 'batch'}_qr_codes.csv`
    document.body.appendChild(link)
    link.click()
    document.body.removeChild(link)
    window.URL.revokeObjectURL(url)
    // Browser shows download notification - no toast needed
  } catch (err) {
    toast.add({
      severity: 'error',
      summary: t('messages.download_failed'),
      detail: t('messages.could_not_generate_csv'),
      life: 3000
    })
  }
}

// Watchers
watch(() => props.selectedBatchId, async (newBatchId) => {
  // Update selected batch when prop changes from parent (URL change)
  if (newBatchId && selectedBatch.value !== newBatchId) {
    // Reload batches first to ensure new batch is available (e.g., when navigating from Issue tab)
    await loadBatches()
    
    const batchExists = availableBatches.value.some(b => b.id === newBatchId)
    if (batchExists) {
      selectedBatch.value = newBatchId
      await loadIssuedCards(newBatchId)
    }
  }
})

// Lifecycle
onMounted(async () => {
  try {
    await loadBatches()
    
    // Priority 1: Use selectedBatchId from URL if provided and valid
    if (props.selectedBatchId && availableBatches.value.some(b => b.id === props.selectedBatchId)) {
      selectedBatch.value = props.selectedBatchId
      await loadIssuedCards(props.selectedBatchId)
    }
    // Priority 2: Auto-select first available batch if exists and no URL param
    else if (availableBatches.value.length > 0) {
      selectedBatch.value = availableBatches.value[0].id
      await loadIssuedCards(selectedBatch.value)
      // Emit to update URL with first batch
      emit('batch-changed', selectedBatch.value)
    }
  } finally {
    loading.value = false
  }
})

// Expose methods for parent component to call if needed
defineExpose({
  loadBatches,
  refreshData: async () => {
    await loadBatches()
    // If a batch is already selected, reload its cards too
    if (selectedBatch.value) {
      await loadIssuedCards(selectedBatch.value)
    }
  }
})
</script>

<style scoped>
/* Custom styles if needed */
</style>