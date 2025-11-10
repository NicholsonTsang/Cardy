<template>
  <div class="space-y-6">
    <!-- Header -->
    <div class="text-center">
      <h3 class="text-lg font-semibold text-slate-900 mb-2">{{ $t('batches.qr_codes_and_access') }}</h3>
      <p class="text-slate-600">{{ $t('batches.generate_qr_codes') }}</p>
    </div>
    
    <!-- Loading State -->
    <div v-if="loading" class="flex items-center justify-center py-12">
      <i class="pi pi-spin pi-spinner text-4xl text-blue-600"></i>
    </div>
    
    <!-- No Batches State -->
    <div v-else-if="!batches.length" class="text-center py-12">
      <div class="w-20 h-20 bg-slate-100 rounded-full flex items-center justify-center mx-auto mb-4">
        <i class="pi pi-qrcode text-3xl text-slate-400"></i>
      </div>
      <h4 class="text-lg font-medium text-slate-900 mb-2">{{ $t('batches.no_batches_found') }}</h4>
      <p class="text-slate-600">{{ $t('batches.create_batch_for_qr') }}</p>
    </div>
    
    <!-- QR Code Generator -->
    <div v-else class="space-y-6">
      <!-- Batch Selector -->
      <div class="bg-white rounded-xl shadow-lg border border-slate-200 p-6">
        <h4 class="font-semibold text-slate-900 mb-4">{{ $t('batches.select_card_batch') }}</h4>
        <Dropdown 
          v-model="selectedBatch"
          :options="availableBatches"
          optionLabel="display_name"
          optionValue="id"
          :placeholder="$t('batches.choose_batch_to_generate')"
          class="w-full"
          @change="onBatchChange"
        />
        <p class="text-sm text-slate-500 mt-2">{{ $t('batches.only_paid_batches') }}</p>
      </div>
      
      <!-- QR Code Display -->
      <div v-if="selectedBatch && selectedBatchData" class="bg-white rounded-xl shadow-lg border border-slate-200 p-3 sm:p-4 lg:p-6">
        <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3 sm:gap-4 mb-4 sm:mb-6">
          <h4 class="font-semibold text-base sm:text-lg text-slate-900">{{ $t('batches.qr_codes_and_urls') }}</h4>
          <div class="flex flex-col sm:flex-row gap-2 sm:gap-2">
            <Button 
              :label="$t('batches.download_all_qr')" 
              icon="pi pi-download"
              @click="downloadAllQRCodes"
              severity="info"
              size="small"
              class="text-xs sm:text-sm w-full sm:w-auto"
            />
            <Button 
              :label="$t('batches.download_csv')" 
              icon="pi pi-file-excel"
              @click="downloadCSV"
              severity="info"
              size="small"
              class="text-xs sm:text-sm w-full sm:w-auto"
            />
          </div>
        </div>
        
        <!-- Batch Info -->
        <div class="bg-slate-50 rounded-lg p-4 mb-6">
          <div class="grid grid-cols-1 sm:grid-cols-3 gap-4">
            <div>
              <label class="text-sm font-medium text-slate-600">{{ $t('batches.batch_name') }}</label>
              <p class="font-semibold text-slate-900">{{ selectedBatchData.batch_name }}</p>
            </div>
            <div>
              <label class="text-sm font-medium text-slate-600">{{ $t('batches.total_cards') }}</label>
              <p class="font-semibold text-slate-900">{{ selectedBatchData.cards_count }}</p>
            </div>
            <div>
              <label class="text-sm font-medium text-slate-600">{{ $t('batches.active_cards') }}</label>
              <p class="font-semibold text-slate-900">{{ issuedCards.filter(card => card.active).length }}</p>
            </div>
          </div>
        </div>
        
        <!-- QR Code Grid -->
        <div v-if="issuedCards.length" class="space-y-4">
          <div class="flex items-center justify-between">
            <h5 class="font-medium text-slate-900">{{ $t('batches.individual_qr_codes') }}</h5>
            <div class="flex items-center gap-2">
              <label class="text-sm text-slate-600">{{ $t('batches.show') }}</label>
              <Dropdown 
                v-model="displayFilter"
                :options="filterOptions"
                optionLabel="label"
                optionValue="value"
                class="w-32"
              />
            </div>
          </div>
          
          <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4 max-h-96 overflow-y-auto">
            <div 
              v-for="(card, index) in filteredCards" 
              :key="card.id"
              class="border border-slate-200 rounded-lg p-4"
            >
              <div class="text-center">
                <!-- QR Code -->
                <div class="bg-white p-3 rounded-lg border border-slate-100 mb-3 inline-block">
                  <QrCode :value="getCardURL(card.id)" :size="120" />
                </div>
                
                <!-- Card Info -->
                <div class="space-y-2">
                  <div class="text-sm font-medium text-slate-900">Card #{{ index + 1 }}</div>
                  <div class="text-xs text-slate-600 break-all">{{ card.id }}</div>
                  <div class="flex items-center justify-center gap-2">
                    <span :class="card.active ? 'text-green-600' : 'text-yellow-600'" class="text-xs font-medium">
                      {{ card.active ? $t('common.active') : $t('common.inactive') }}
                    </span>
                  </div>
                  
                  <!-- Actions -->
                  <div class="flex gap-1 justify-center mt-2">
                    <Button 
                      icon="pi pi-copy"
                      @click="copyURL(card.id)"
                      severity="info"
                      size="small"
                      text
                      v-tooltip="$t('batches.copy_url')"
                    />
                    <Button 
                      icon="pi pi-download"
                      @click="downloadSingleQR(card.id, index + 1)"
                      severity="info"
                      size="small"
                      text
                      v-tooltip="$t('batches.download_qr')"
                    />
                    <Button 
                      icon="pi pi-external-link"
                      @click="openCard(card.id)"
                      severity="info"
                      size="small"
                      text
                      v-tooltip="$t('batches.open_card')"
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

For support, contact your CardStudio administrator.
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