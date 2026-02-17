<template>
  <div class="space-y-6 text-slate-900">
    <!-- Header Section -->
    <div class="bg-gradient-to-r from-slate-50 to-slate-100 rounded-xl p-6 border border-slate-200">
      <div class="flex items-start gap-4">
        <div>
          <div class="w-12 h-12 bg-blue-600 rounded-full flex items-center justify-center text-white text-xl flex-shrink-0">
            <i class="pi pi-download"></i>
          </div>
        </div>
        <div>
          <h3 class="text-xl font-semibold text-slate-900 mb-1">{{ $t('export.export_card_data') }}</h3>
          <p class="text-slate-600 text-sm leading-relaxed">
            {{ $t('export.export_description') }}
          </p>
        </div>
      </div>
    </div>

    <!-- Card Information Display -->
    <div class="bg-white border border-slate-200 rounded-lg p-6">
      <div class="flex items-start gap-6">
        <div class="flex-shrink-0">
          <div class="w-24 h-36 bg-slate-100 rounded-lg overflow-hidden border border-slate-200 flex items-center justify-center">
            <!-- Digital Access: Show QR icon -->
            <div v-if="props.card.billing_type === 'digital'" class="text-cyan-500 text-2xl flex flex-col items-center justify-center bg-gradient-to-br from-cyan-50 to-cyan-100 w-full h-full">
              <i class="pi pi-qrcode"></i>
              <span class="text-xs font-medium mt-1">{{ $t('export.digital_access') }}</span>
            </div>
            <!-- Card with image -->
            <img
              v-else-if="props.card.image_url"
              :src="props.card.image_url"
              :alt="props.card.name"
              class="w-full h-full object-cover"
            />
            <div v-else class="text-slate-400 text-2xl flex flex-col items-center justify-center">
              <i class="pi pi-id-card"></i>
            </div>
          </div>
        </div>

        <div class="flex-1 min-w-0">
          <h3 class="text-lg font-semibold text-slate-900 mb-2">{{ props.card.name }}</h3>
          <p v-if="props.card.description" class="text-slate-600 text-sm mb-4 leading-relaxed">
            {{ props.card.description }}
          </p>

          <div class="flex flex-wrap gap-4">
            <div class="flex items-center gap-2">
              <div class="w-8 h-8 bg-blue-100 rounded-full flex items-center justify-center text-blue-600 text-sm flex-shrink-0">
                <i class="pi pi-list"></i>
              </div>
              <div class="flex flex-col">
                <span class="text-lg font-semibold text-slate-900">{{ contentCount }}</span>
                <span class="text-xs text-slate-600 font-medium">{{ $t('export.content_items') }}</span>
              </div>
            </div>

            <div v-if="contentWithImages > 0" class="flex items-center gap-2">
              <div class="w-8 h-8 bg-blue-100 rounded-full flex items-center justify-center text-blue-600 text-sm flex-shrink-0">
                <i class="pi pi-image"></i>
              </div>
              <div class="flex flex-col">
                <span class="text-lg font-semibold text-slate-900">{{ contentWithImages }}</span>
                <span class="text-xs text-slate-600 font-medium">{{ $t('export.with_images') }}</span>
              </div>
            </div>

            <div v-if="props.card.conversation_ai_enabled" class="flex items-center gap-2">
              <div class="w-8 h-8 bg-blue-100 rounded-full flex items-center justify-center text-blue-600 text-sm flex-shrink-0">
                <i class="pi pi-comment"></i>
              </div>
              <div class="flex flex-col">
                <span class="text-xs text-slate-600 font-medium">{{ $t('export.ai_enabled') }}</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Export Summary -->
    <div class="bg-slate-50 border border-slate-200 rounded-lg p-4">
      <div class="grid grid-cols-1 sm:grid-cols-3 gap-4">
        <div class="flex items-center gap-3 p-3 bg-white rounded-lg border border-slate-200">
          <i class="pi pi-id-card text-lg text-blue-600 flex-shrink-0"></i>
          <div class="flex flex-col">
            <span class="text-xs text-slate-600 font-medium">{{ $t('export.card_information') }}</span>
            <span class="text-sm font-semibold text-slate-900">{{ $t('export.one_card') }}</span>
          </div>
        </div>
        <div class="flex items-center gap-3 p-3 bg-white rounded-lg border border-slate-200">
          <i class="pi pi-list text-lg text-blue-600 flex-shrink-0"></i>
          <div class="flex flex-col">
            <span class="text-xs text-slate-600 font-medium">{{ $t('export.content_items') }}</span>
            <span class="text-sm font-semibold text-slate-900">{{ $t('export.items_count', { count: contentCount }) }}</span>
          </div>
        </div>
        <div v-if="contentWithImages > 0" class="flex items-center gap-3 p-3 bg-white rounded-lg border border-slate-200">
          <i class="pi pi-image text-lg text-blue-600 flex-shrink-0"></i>
          <div class="flex flex-col">
            <span class="text-xs text-slate-600 font-medium">{{ $t('export.items_with_images') }}</span>
            <span class="text-sm font-semibold text-slate-900">{{ contentWithImages }}</span>
          </div>
        </div>
      </div>
    </div>

    <!-- Export Actions -->
    <div class="text-center space-y-4">
      <Button
        :label="exportButtonLabel"
        icon="pi pi-download"
        @click="exportCard"
        :loading="exporting"
        :disabled="!canExport"
        class="px-8 py-3 text-lg font-semibold bg-blue-600 hover:bg-blue-700 text-white border-0"
        size="large"
      />

      <div class="flex items-center justify-center gap-2 text-sm text-slate-600">
        <i class="pi pi-info-circle"></i>
        <span>{{ $t('export.excel_download_hint') }}</span>
      </div>
    </div>

    <!-- Export Progress -->
    <div v-if="exporting" class="bg-blue-50 border border-blue-200 rounded-lg p-6">
      <div class="flex items-start gap-4">
        <ProgressSpinner size="small" />
        <div class="flex-1">
          <span class="text-lg font-semibold text-blue-900 mb-4">{{ exportStatus }}</span>
          <div class="flex gap-4">
            <div
              class="flex flex-col items-center gap-2 text-xs transition-colors"
              :class="currentStep >= 1 ? (currentStep > 1 ? 'text-blue-800' : 'text-blue-600') : 'text-slate-400'"
            >
              <i class="pi pi-database text-lg"></i>
              <span>{{ $t('export.loading_data') }}</span>
            </div>
            <div
              class="flex flex-col items-center gap-2 text-xs transition-colors"
              :class="currentStep >= 2 ? (currentStep > 2 ? 'text-blue-800' : 'text-blue-600') : 'text-slate-400'"
            >
              <i class="pi pi-image text-lg"></i>
              <span>{{ $t('export.processing_images') }}</span>
            </div>
            <div
              class="flex flex-col items-center gap-2 text-xs transition-colors"
              :class="currentStep >= 3 ? (currentStep > 3 ? 'text-blue-800' : 'text-blue-600') : 'text-slate-400'"
            >
              <i class="pi pi-file text-lg"></i>
              <span>{{ $t('export.creating_archive') }}</span>
            </div>
            <div
              class="flex flex-col items-center gap-2 text-xs transition-colors"
              :class="currentStep >= 4 ? 'text-blue-600' : 'text-slate-400'"
            >
              <i class="pi pi-download text-lg"></i>
              <span>{{ $t('export.downloading') }}</span>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Export Results -->
    <div v-if="lastExport" class="bg-white border border-slate-200 rounded-lg p-6 space-y-4">
      <div class="flex items-start gap-4">
        <div class="w-12 h-12 rounded-full flex items-center justify-center text-xl flex-shrink-0 bg-blue-100 text-blue-600">
          <i class="pi pi-check-circle"></i>
        </div>
        <div>
          <h4 class="text-lg font-semibold text-slate-900 mb-1">{{ $t('export.export_completed_successfully') }}</h4>
          <p class="text-slate-600">{{ lastExport.message }}</p>
        </div>
      </div>

      <div class="bg-slate-50 rounded-lg p-4">
        <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
          <div class="text-center">
            <span class="block text-xs text-slate-600 mb-1">{{ $t('export.file_name') }}</span>
            <span class="block text-sm font-semibold text-slate-900">{{ lastExport.filename }}</span>
          </div>
          <div class="text-center">
            <span class="block text-xs text-slate-600 mb-1">{{ $t('export.file_size') }}</span>
            <span class="block text-sm font-semibold text-slate-900">{{ formatFileSize(lastExport.fileSize) }}</span>
          </div>
          <div class="text-center">
            <span class="block text-xs text-slate-600 mb-1">{{ $t('export.export_time') }}</span>
            <span class="block text-sm font-semibold text-slate-900">{{ formatExportTime(lastExport.timestamp) }}</span>
          </div>
          <div v-if="lastExport.imageCount > 0" class="text-center">
            <span class="block text-xs text-slate-600 mb-1">{{ $t('export.images_embedded') }}</span>
            <span class="block text-sm font-semibold text-slate-900">{{ lastExport.imageCount }}</span>
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
import { exportProject, estimateSize } from '@/utils/projectArchive'
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
    contentCount.value = 0
    contentWithImages.value = 0
    toast.add({
      severity: 'error',
      summary: t('common.error'),
      detail: t('export.failed_to_load_content'),
      life: 5000
    })
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

    // Check estimated size and warn if large
    const estimatedSizeBytes = estimateSize(card, contentItems)
    const estimatedSizeMB = estimatedSizeBytes / (1024 * 1024)
    const MAX_SIZE_WARNING_MB = 50

    if (estimatedSizeMB > MAX_SIZE_WARNING_MB) {
      toast.add({
        severity: 'warn',
        summary: t('export.large_export_warning'),
        detail: t('export.large_export_detail', { size: estimatedSizeMB.toFixed(1) }),
        life: 8000
      })
    }

    // Step 3: Create archive (fetches images at full quality)
    currentStep.value = 3
    exportStatus.value = 'Creating archive...'

    // Configure timeout based on estimated size (1 min per 10MB, min 2 min, max 10 min)
    const timeoutMs = Math.min(Math.max(120000, estimatedSizeMB * 6000), 600000)

    const { blob, imageCount, estimatedSize } = await exportProject(card, contentItems, {
      timeout: timeoutMs,
      compressionLevel: estimatedSizeMB > 100 ? 3 : 6 // Faster compression for very large exports
    })

    // Step 4: Download file
    currentStep.value = 4
    exportStatus.value = 'Downloading file...'

    const timestamp = new Date().toISOString().split('T')[0]
    const cardName = card.name || 'card'
    const safeName = cardName.replace(/[^a-z0-9]/gi, '_')
    const filename = `${safeName}_export_${timestamp}.zip`

    const url = window.URL.createObjectURL(blob)
    const link = document.createElement('a')
    link.href = url
    link.download = filename
    link.click()
    window.URL.revokeObjectURL(url)

    // Update last export info
    lastExport.value = {
      filename,
      fileSize: blob.size,
      timestamp: Date.now(),
      imageCount,
      message: `Successfully exported "${cardName}" with ${contentItems.length} content items${imageCount > 0 ? ` and ${imageCount} images` : ''}`
    }

    // Success notification
    toast.add({
      severity: 'success',
      summary: t('export.export_complete'),
      detail: lastExport.value.message,
      life: 5000
    })

  } catch (error) {
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
