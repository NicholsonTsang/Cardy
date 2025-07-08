<template>
  <div class="space-y-6">
    <!-- Header -->
    <div class="text-center">
      <h3 class="text-lg font-semibold text-slate-900 mb-2">QR Codes & Access URLs</h3>
      <p class="text-slate-600">Generate QR codes and shareable URLs for your issued cards</p>
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
      <h4 class="text-lg font-medium text-slate-900 mb-2">No Card Batches Found</h4>
      <p class="text-slate-600 mb-4">Create and issue card batches first to generate QR codes</p>
      <Button 
        label="Go to Card Issuance" 
        @click="$emit('switch-to-tab', 2)"
        class="bg-gradient-to-r from-blue-600 to-purple-600 hover:from-blue-700 hover:to-purple-700 border-0"
      />
    </div>

    <!-- QR Code Generator -->
    <div v-else class="space-y-6">
      <!-- Batch Selector -->
      <div class="bg-white rounded-xl shadow-lg border border-slate-200 p-6">
        <h4 class="font-semibold text-slate-900 mb-4">Select Card Batch</h4>
        <Dropdown 
          v-model="selectedBatch"
          :options="availableBatches"
          optionLabel="display_name"
          optionValue="id"
          placeholder="Choose a batch to generate QR codes"
          class="w-full"
          @change="onBatchChange"
        />
        <p class="text-sm text-slate-500 mt-2">Only paid batches with generated cards are available for QR code generation</p>
      </div>

      <!-- QR Code Display -->
      <div v-if="selectedBatch && selectedBatchData" class="bg-white rounded-xl shadow-lg border border-slate-200 p-6">
        <div class="flex items-center justify-between mb-6">
          <h4 class="font-semibold text-slate-900">QR Codes & URLs</h4>
          <div class="flex gap-2">
            <Button 
              label="Download All QR Codes" 
              icon="pi pi-download"
              @click="downloadAllQRCodes"
              outlined
              class="border-blue-600 text-blue-600 hover:bg-blue-50"
            />
            <Button 
              label="Download CSV" 
              icon="pi pi-file-excel"
              @click="downloadCSV"
              outlined
              class="border-green-600 text-green-600 hover:bg-green-50"
            />
          </div>
        </div>

        <!-- Batch Info -->
        <div class="bg-slate-50 rounded-lg p-4 mb-6">
          <div class="grid grid-cols-1 sm:grid-cols-3 gap-4">
            <div>
              <label class="text-sm font-medium text-slate-600">Batch Name</label>
              <p class="font-semibold text-slate-900">{{ selectedBatchData.batch_name }}</p>
            </div>
            <div>
              <label class="text-sm font-medium text-slate-600">Total Cards</label>
              <p class="font-semibold text-slate-900">{{ selectedBatchData.cards_count }}</p>
            </div>
            <div>
              <label class="text-sm font-medium text-slate-600">Active Cards</label>
              <p class="font-semibold text-slate-900">{{ issuedCards.filter(card => card.active).length }}</p>
            </div>
          </div>
        </div>

        <!-- QR Code Grid -->
        <div v-if="issuedCards.length" class="space-y-4">
          <div class="flex items-center justify-between">
            <h5 class="font-medium text-slate-900">Individual QR Codes</h5>
            <div class="flex items-center gap-2">
              <label class="text-sm text-slate-600">Show:</label>
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
                      {{ card.active ? 'Active' : 'Inactive' }}
                    </span>
                  </div>
                  
                  <!-- Actions -->
                  <div class="flex gap-1 justify-center mt-2">
                    <Button 
                      icon="pi pi-copy"
                      @click="copyURL(card.id)"
                      size="small"
                      outlined
                      class="border-blue-600 text-blue-600 hover:bg-blue-50"
                      v-tooltip="'Copy URL'"
                    />
                    <Button 
                      icon="pi pi-download"
                      @click="downloadSingleQR(card.id, index + 1)"
                      size="small"
                      outlined
                      class="border-green-600 text-green-600 hover:bg-green-50"
                      v-tooltip="'Download QR'"
                    />
                    <Button 
                      icon="pi pi-external-link"
                      @click="openCard(card.id)"
                      size="small"
                      outlined
                      class="border-purple-600 text-purple-600 hover:bg-purple-50"
                      v-tooltip="'Open Card'"
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
import { ref, computed, onMounted } from 'vue'
import { useToast } from 'primevue/usetoast'
import Button from 'primevue/button'
import Dropdown from 'primevue/dropdown'
import QrCode from 'qrcode.vue'
import * as QRCodeLib from 'qrcode'
import { supabase } from '@/lib/supabase'

const props = defineProps({
  cardId: {
    type: String,
    required: true
  },
  cardName: {
    type: String,
    required: true
  }
})

const emit = defineEmits(['switch-to-tab'])

const toast = useToast()

// State
const loading = ref(true)
const batches = ref([])
const issuedCards = ref([])
const selectedBatch = ref(null)
const displayFilter = ref('all')

// Filter options
const filterOptions = [
  { label: 'All Cards', value: 'all' },
  { label: 'Active Only', value: 'active' },
  { label: 'Inactive Only', value: 'inactive' }
]

// Computed
const availableBatches = computed(() => {
  return batches.value
    .filter(batch => batch.payment_completed && batch.cards_generated)
    .map(batch => ({
      ...batch,
      display_name: `${batch.batch_name} (${batch.cards_count} cards)`
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
      summary: 'Error',
      detail: 'Failed to load card batches',
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
      summary: 'Error',
      detail: 'Failed to load issued cards',
      life: 5000
    })
  }
}

const onBatchChange = async () => {
  if (selectedBatch.value) {
    await loadIssuedCards(selectedBatch.value)
  }
}

const copyURL = async (issueCardId) => {
  try {
    const url = getCardURL(issueCardId)
    await navigator.clipboard.writeText(url)
    toast.add({
      severity: 'success',
      summary: 'Copied!',
      detail: 'URL copied to clipboard',
      life: 3000
    })
  } catch (err) {
    toast.add({
      severity: 'error',
      summary: 'Copy Failed',
      detail: 'Could not copy URL to clipboard',
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
    
    toast.add({
      severity: 'success',
      summary: 'Downloaded',
      detail: `QR code for Card #${cardNumber} downloaded`,
      life: 3000
    })
  } catch (err) {
    toast.add({
      severity: 'error',
      summary: 'Download Failed',
      detail: 'Could not generate QR code',
      life: 3000
    })
  }
}

const downloadAllQRCodes = async () => {
  // Implementation for downloading all QR codes as a ZIP file
  toast.add({
    severity: 'info',
    summary: 'Feature Coming Soon',
    detail: 'Bulk QR code download will be available soon',
    life: 3000
  })
}

const downloadCSV = () => {
  try {
    const headers = ['Card Number', 'Issue Card ID', 'Status', 'QR Code URL', 'Access URL']
    const rows = issuedCards.value.map((card, index) => [
      index + 1,
      card.id,
      card.active ? 'Active' : 'Inactive',
      getCardURL(card.id),
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
    
    toast.add({
      severity: 'success',
      summary: 'Downloaded',
      detail: `CSV with ${issuedCards.value.length} card URLs downloaded`,
      life: 3000
    })
  } catch (err) {
    toast.add({
      severity: 'error',
      summary: 'Download Failed',
      detail: 'Could not generate CSV file',
      life: 3000
    })
  }
}

// Lifecycle
onMounted(async () => {
  try {
    await loadBatches()
    
    // Auto-select first available batch if exists
    if (availableBatches.value.length > 0) {
      selectedBatch.value = availableBatches.value[0].id
      await onBatchChange()
    }
  } finally {
    loading.value = false
  }
})
</script>

<style scoped>
/* Custom styles if needed */
</style>