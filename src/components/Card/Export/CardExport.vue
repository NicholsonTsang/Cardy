<template>
  <div class="card-export">
    <!-- Header Section -->
    <div class="export-header">
      <div class="header-content">
        <div class="icon-section">
          <div class="export-icon">
            <i class="pi pi-download"></i>
          </div>
        </div>
        <div class="text-section">
          <h3 class="export-title">{{ $t('export.export_card_data') }}</h3>
          <p class="export-description">
            {{ $t('export.export_description') }}
          </p>
        </div>
      </div>
    </div>

    <!-- Card Information Display -->
    <div class="card-info-display">
      <div class="card-preview">
        <div class="card-visual">
          <div class="card-image-container">
            <!-- Digital Access: Show QR icon -->
            <div v-if="props.card.billing_type === 'digital'" class="card-placeholder digital-access">
              <i class="pi pi-qrcode"></i>
              <span class="digital-label">{{ $t('export.digital_access') }}</span>
            </div>
            <!-- Physical Card: Show image -->
            <img 
              v-else-if="props.card.image_url"
              :src="props.card.image_url"
              :alt="props.card.name"
              class="card-image"
            />
            <div v-else class="card-placeholder">
              <i class="pi pi-id-card"></i>
            </div>
          </div>
        </div>
        
        <div class="card-details">
          <h3 class="card-name">{{ props.card.name }}</h3>
          <p class="card-description" v-if="props.card.description">
            {{ props.card.description }}
          </p>
          
          <div class="card-stats">
            <div class="stat-item">
              <div class="stat-icon">
                <i class="pi pi-list"></i>
              </div>
              <div class="stat-content">
                <span class="stat-number">{{ contentCount }}</span>
                <span class="stat-label">{{ $t('export.content_items') }}</span>
              </div>
            </div>
            
            <div class="stat-item" v-if="contentWithImages > 0">
              <div class="stat-icon">
                <i class="pi pi-image"></i>
              </div>
              <div class="stat-content">
                <span class="stat-number">{{ contentWithImages }}</span>
                <span class="stat-label">{{ $t('export.with_images') }}</span>
              </div>
            </div>
            
            <div class="stat-item" v-if="props.card.conversation_ai_enabled">
              <div class="stat-icon">
                <i class="pi pi-comment"></i>
              </div>
              <div class="stat-content">
                <span class="stat-label">{{ $t('export.ai_enabled') }}</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Export Summary -->
    <div class="export-summary">
      <div class="summary-grid">
        <div class="summary-item">
          <i class="pi pi-id-card summary-icon"></i>
          <div class="summary-details">
            <span class="summary-label">{{ $t('export.card_information') }}</span>
            <span class="summary-value">{{ $t('export.one_card') }}</span>
          </div>
        </div>
        <div class="summary-item">
          <i class="pi pi-list summary-icon"></i>
          <div class="summary-details">
            <span class="summary-label">{{ $t('export.content_items') }}</span>
            <span class="summary-value">{{ $t('export.items_count', { count: contentCount }) }}</span>
          </div>
        </div>
        <div class="summary-item" v-if="contentWithImages > 0">
          <i class="pi pi-image summary-icon"></i>
          <div class="summary-details">
            <span class="summary-label">{{ $t('export.items_with_images') }}</span>
            <span class="summary-value">{{ contentWithImages }}</span>
          </div>
        </div>
      </div>
    </div>

    <!-- Export Actions -->
    <div class="export-actions">
      <Button 
        :label="exportButtonLabel"
        icon="pi pi-download"
        @click="exportCard"
        :loading="exporting"
        :disabled="!canExport"
        class="export-button bg-blue-600 hover:bg-blue-700 text-white border-0"
        size="large"
      />
      
      <div class="action-hint">
        <i class="pi pi-info-circle"></i>
        <span>{{ $t('export.excel_download_hint') }}</span>
      </div>
    </div>

    <!-- Export Progress -->
    <div v-if="exporting" class="export-progress">
      <div class="progress-content">
        <ProgressSpinner size="small" />
        <div class="progress-details">
          <span class="progress-text">{{ exportStatus }}</span>
          <div class="progress-steps">
            <div class="step" :class="{ active: currentStep >= 1, completed: currentStep > 1 }">
              <i class="pi pi-database"></i>
              <span>{{ $t('export.loading_data') }}</span>
            </div>
            <div class="step" :class="{ active: currentStep >= 2, completed: currentStep > 2 }">
              <i class="pi pi-image"></i>
              <span>{{ $t('export.processing_images') }}</span>
            </div>
            <div class="step" :class="{ active: currentStep >= 3, completed: currentStep > 3 }">
              <i class="pi pi-file-excel"></i>
              <span>{{ $t('export.creating_excel') }}</span>
            </div>
            <div class="step" :class="{ active: currentStep >= 4 }">
              <i class="pi pi-download"></i>
              <span>{{ $t('export.downloading') }}</span>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Export Results -->
    <div v-if="lastExport" class="export-results">
      <div class="results-header">
        <div class="results-icon success">
          <i class="pi pi-check-circle"></i>
        </div>
        <div class="results-content">
          <h4 class="results-title">{{ $t('export.export_completed_successfully') }}</h4>
          <p class="results-summary">{{ lastExport.message }}</p>
        </div>
      </div>
      
      <div class="results-details">
        <div class="detail-grid">
          <div class="detail-item">
            <span class="detail-label">{{ $t('export.file_name') }}</span>
            <span class="detail-value">{{ lastExport.filename }}</span>
          </div>
          <div class="detail-item">
            <span class="detail-label">{{ $t('export.file_size') }}</span>
            <span class="detail-value">{{ formatFileSize(lastExport.fileSize) }}</span>
          </div>
          <div class="detail-item">
            <span class="detail-label">{{ $t('export.export_time') }}</span>
            <span class="detail-value">{{ formatExportTime(lastExport.timestamp) }}</span>
          </div>
          <div class="detail-item" v-if="lastExport.imageCount > 0">
            <span class="detail-label">{{ $t('export.images_embedded') }}</span>
            <span class="detail-value">{{ lastExport.imageCount }}</span>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useToast } from 'primevue/usetoast'
import { useI18n } from 'vue-i18n'
import { supabase } from '@/lib/supabase'
import { exportCardToExcel } from '@/utils/excelHandler'
import Button from 'primevue/button'
import ProgressSpinner from 'primevue/progressspinner'

const { t } = useI18n()

const props = defineProps({
  card: {
    type: Object,
    required: true
  }
})

const emit = defineEmits(['exported', 'cancel'])
const toast = useToast()

// Export state
const exporting = ref(false)
const exportStatus = ref('')
const currentStep = ref(0)
// Remove includeContent since we always export content
const contentCount = ref(0)
const contentWithImages = ref(0)
const lastExport = ref(null)

// Computed properties
const exportButtonLabel = computed(() => {
  if (exporting.value) return t('export.exporting')
  return `${t('common.export')} ${props.card.name || t('common.card')}`
})

const canExport = computed(() => {
  return props.card && props.card.id && !exporting.value
})

// Load content statistics on mount
onMounted(async () => {
  await loadContentStats()
})

async function loadContentStats() {
  try {
    const { data, error } = await supabase
      .rpc('get_card_content_items', { p_card_id: props.card.id })
    
    if (error) throw error
    
    const items = data || []
    contentCount.value = items.length
    contentWithImages.value = items.filter(item => 
      item.image_url
    ).length
    
  } catch (error) {
    console.error('Error loading content stats:', error)
    contentCount.value = 0
    contentWithImages.value = 0
  }
}

async function exportCard() {
  if (!canExport.value) return
  
  exporting.value = true
  currentStep.value = 1
  exportStatus.value = 'Loading card data...'
  
  try {
    // Step 1: Use card data from props
    const card = props.card
    
    // Step 2: Fetch content items (always included)
    currentStep.value = 2
    exportStatus.value = 'Loading content items...'
    
    const { data: contentData, error: contentError } = await supabase
      .rpc('get_card_content_items', { p_card_id: props.card.id })
    
    if (contentError) throw contentError
    const contentItems = contentData || []
    
    // Process images
    if (contentItems.some(item => item.image_url)) {
      exportStatus.value = 'Processing images...'
      await new Promise(resolve => setTimeout(resolve, 500)) // Small delay for UI feedback
    }
    
    // Step 3: Generate Excel file
    currentStep.value = 3
    exportStatus.value = 'Creating Excel file with embedded images...'
    
    const exportOptions = {
      includeContent: true
    }
    
    const buffer = await exportCardToExcel(card, contentItems, exportOptions)
    
    // Step 4: Download file
    currentStep.value = 4
    exportStatus.value = 'Downloading file...'
    
    // Generate filename
    const timestamp = new Date().toISOString().split('T')[0]
    const cardName = card.name || 'card'
    const safeName = cardName.replace(/[^a-z0-9]/gi, '_')
    const filename = `${safeName}_export_${timestamp}.xlsx`
    
    // Create and download blob
    const blob = new Blob([buffer], { 
      type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' 
    })
    const url = window.URL.createObjectURL(blob)
    const link = document.createElement('a')
    link.href = url
    link.download = filename
    link.click()
    window.URL.revokeObjectURL(url)
    
    // Calculate statistics
    const imageCount = contentItems.reduce((count, item) => 
      count + (item.image_url ? 1 : 0), 0
    )
    
    // Update last export info
    lastExport.value = {
      filename,
      fileSize: buffer.byteLength,
      timestamp: Date.now(),
      imageCount,
      message: `Successfully exported "${cardName}" with ${contentItems.length} content items${imageCount > 0 ? ` and ${imageCount} embedded images` : ''}`
    }
    
    // Success notification
    toast.add({
      severity: 'success',
      summary: t('export.export_complete'),
      detail: lastExport.value.message,
      life: 5000
    })
    
  } catch (error) {
    console.error('Export error:', error)
    toast.add({
      severity: 'error',
      summary: t('export.export_failed'),
      detail: error.message || t('export.failed_to_export_card_data'),
      life: 5000
    })
  } finally {
    exporting.value = false
    currentStep.value = 0
    exportStatus.value = ''
  }
}

function formatFileSize(bytes) {
  if (bytes === 0) return '0 Bytes'
  const k = 1024
  const sizes = ['Bytes', 'KB', 'MB', 'GB']
  const i = Math.floor(Math.log(bytes) / Math.log(k))
  return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i]
}

function formatExportTime(timestamp) {
  return new Date(timestamp).toLocaleString()
}
</script>

<style scoped>
.card-export {
  @apply space-y-6;
}

.export-header {
  @apply bg-gradient-to-r from-slate-50 to-slate-100 rounded-xl p-6 border border-slate-200;
}

.header-content {
  @apply flex items-start gap-4;
}

.export-icon {
  @apply w-12 h-12 bg-blue-600 rounded-full flex items-center justify-center text-white text-xl flex-shrink-0;
}

.export-title {
  @apply text-xl font-semibold text-slate-900 mb-1;
}

.export-description {
  @apply text-slate-600 text-sm leading-relaxed;
}

.export-features {
  @apply bg-white border border-slate-200 rounded-lg p-6;
}

.features-title {
  @apply text-lg font-semibold text-slate-900 mb-4;
}

.feature-list {
  @apply grid grid-cols-1 sm:grid-cols-2 gap-3;
}

.feature-item {
  @apply flex items-center gap-3 text-sm text-slate-700;
}

.feature-icon {
  @apply text-lg text-blue-600 flex-shrink-0;
}

.export-summary {
  @apply bg-slate-50 border border-slate-200 rounded-lg p-4;
}

.summary-content {
  @apply text-center;
}

.summary-stats {
  @apply flex items-center justify-center gap-3 text-sm text-slate-600;
}

.stat-item {
  @apply flex items-center gap-2;
}

.stat-separator {
  @apply text-slate-400;
}

.export-actions {
  @apply text-center space-y-4;
}

.export-button {
  @apply px-8 py-3 text-lg font-semibold;
}

.cancel-button {
  @apply text-slate-600 hover:text-slate-800;
}

.action-hint {
  @apply flex items-center justify-center gap-2 text-sm text-slate-600;
}

.export-progress {
  @apply bg-blue-50 border border-blue-200 rounded-lg p-6;
}

.progress-content {
  @apply flex items-start gap-4;
}

.progress-details {
  @apply flex-1;
}

.progress-text {
  @apply text-lg font-semibold text-blue-900 mb-4;
}

.progress-steps {
  @apply flex gap-4;
}

.step {
  @apply flex flex-col items-center gap-2 text-xs text-slate-400 transition-colors;
}

.step.active {
  @apply text-blue-600;
}

.step.completed {
  @apply text-blue-800;
}

.step i {
  @apply text-lg;
}

.export-results {
  @apply bg-white border border-slate-200 rounded-lg p-6 space-y-4;
}

.results-header {
  @apply flex items-start gap-4;
}

.results-icon {
  @apply w-12 h-12 rounded-full flex items-center justify-center text-xl flex-shrink-0;
}

.results-icon.success {
  @apply bg-blue-100 text-blue-600;
}

.results-title {
  @apply text-lg font-semibold text-slate-900 mb-1;
}

.results-summary {
  @apply text-slate-600;
}

.results-details {
  @apply bg-slate-50 rounded-lg p-4;
}

.detail-grid {
  @apply grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4;
}

.detail-item {
  @apply text-center;
}

.detail-label {
  @apply block text-xs text-slate-600 mb-1;
}

.detail-value {
  @apply block text-sm font-semibold text-slate-900;
}

/* Card Information Display Styles */
.card-info-display {
  @apply bg-white border border-slate-200 rounded-lg p-6;
}

.card-preview {
  @apply flex items-start gap-6;
}

.card-visual {
  @apply flex-shrink-0;
}

.card-image-container {
  @apply w-24 h-36 bg-slate-100 rounded-lg overflow-hidden border border-slate-200 flex items-center justify-center;
}

.card-image {
  @apply w-full h-full object-cover;
}

.card-placeholder {
  @apply text-slate-400 text-2xl flex flex-col items-center justify-center;
}

.card-placeholder.digital-access {
  @apply bg-gradient-to-br from-cyan-50 to-cyan-100 text-cyan-500;
}

.digital-label {
  @apply text-xs font-medium mt-1;
}

.card-details {
  @apply flex-1 min-w-0;
}

.card-name {
  @apply text-lg font-semibold text-slate-900 mb-2;
}

.card-description {
  @apply text-slate-600 text-sm mb-4 leading-relaxed;
}

.card-stats {
  @apply flex flex-wrap gap-4;
}

.stat-item {
  @apply flex items-center gap-2;
}

.stat-icon {
  @apply w-8 h-8 bg-blue-100 rounded-full flex items-center justify-center text-blue-600 text-sm flex-shrink-0;
}

.stat-content {
  @apply flex flex-col;
}

.stat-number {
  @apply text-lg font-semibold text-slate-900;
}

.stat-label {
  @apply text-xs text-slate-600 font-medium;
}

.summary-grid {
  @apply grid grid-cols-1 sm:grid-cols-3 gap-4;
}

.summary-item {
  @apply flex items-center gap-3 p-3 bg-white rounded-lg border border-slate-200;
}

.summary-icon {
  @apply text-lg text-blue-600 flex-shrink-0;
}

.summary-details {
  @apply flex flex-col;
}

.summary-label {
  @apply text-xs text-slate-600 font-medium;
}

.summary-value {
  @apply text-sm font-semibold text-slate-900;
}

/* Clean dialog styling */
.card-export {
  @apply text-slate-900;
}
</style>