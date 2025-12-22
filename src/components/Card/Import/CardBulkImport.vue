<template>
  <div class="card-bulk-import">
    <!-- Header Section -->
    <div class="import-header">
      <div class="header-content">
        <div class="icon-section">
          <div class="import-icon">
            <i class="pi pi-upload"></i>
          </div>
        </div>
        <div class="text-section">
          <h3 class="import-title">{{ $t('import.bulk_import_cards') }}</h3>
          <p class="import-description">{{ $t('import.bulk_import_desc') }}</p>
        </div>
      </div>
    </div>

    <!-- Regular Import Content -->
    <div class="regular-import-content">
      <!-- Quick Actions -->
      <div class="quick-actions">
        <div class="action-grid">
          <div class="action-item template-action">
            <Button 
              :label="$t('import.download_template')"
              icon="pi pi-download"
              @click="downloadTemplate"
              class="template-button bg-blue-600 hover:bg-blue-700 text-white border-0"
            />
            <span class="action-desc">{{ $t('import.template_desc') }}</span>
          </div>
          
          <div class="action-item import-action">
            <Button 
              :label="$t('import.choose_excel_file')"
              icon="pi pi-file-excel"
              @click="triggerFileInput"
              :disabled="importing"
              class="import-button bg-blue-600 hover:bg-blue-700 text-white border-0"
            />
            <span class="action-desc">{{ $t('import.upload_excel_desc') }}</span>
          </div>
        </div>
      </div>
    </div>

    <!-- Inline Feedback Messages -->
    <div v-if="feedbackMessage" class="inline-feedback" :class="`feedback-${feedbackMessage.severity}`">
      <div class="feedback-content">
        <div class="feedback-icon">
          <i :class="getFeedbackIcon(feedbackMessage.severity)"></i>
        </div>
        <div class="feedback-text">
          <h4 class="feedback-title">{{ feedbackMessage.summary }}</h4>
          <p class="feedback-detail">{{ feedbackMessage.detail }}</p>
        </div>
        <Button 
          icon="pi pi-times" 
          @click="clearFeedback"
          class="p-button-text p-button-sm feedback-close"
          v-tooltip="$t('common.close')"
        />
      </div>
    </div>

    <!-- File Upload Area (Shared Component) -->
    <FileUploadZone
      ref="uploadZone"
      accept=".xlsx,.xls"
      :max-size-m-b="25"
      :multiple="true"
      :drop-title="$t('import.drop_excel_here')"
      :drop-subtitle="$t('import.or_click_to_browse_multiple')"
      :requirements="[
        $t('import.req_excel_with_images'),
        $t('import.req_max_size'),
        $t('import.req_multiple_files'),
        $t('import.req_images_extracted')
      ]"
      :status-text="importPreview ? $t('import.analysis_complete') : undefined"
      @file-selected="processFile"
      @files-selected="processMultipleFiles"
      @file-removed="handleFileRemoved"
      @error="handleUploadError"
    />

    <!-- Import Preview -->
    <div v-if="importPreview" class="import-preview">
      <div class="preview-header">
        <h4 class="preview-title">
          <i class="pi pi-eye preview-icon"></i>
          {{ $t('import.import_preview') }}
        </h4>
        <div class="preview-stats">
          <span class="stat-item">
            <i class="pi pi-id-card text-blue-600"></i>
            {{ totalCardsCount }} {{ totalCardsCount === 1 ? $t('import.card') : $t('import.cards') }}
          </span>
          <span class="stat-item">
            <i class="pi pi-list text-blue-600"></i>
            {{ totalContentItemsCount }} {{ $t('import.content_items') }}
          </span>
          <span class="stat-item">
            <i class="pi pi-image text-purple-600"></i>
            {{ extractedImageCount }} {{ $t('import.embedded_images') }}
          </span>
        </div>
      </div>
      
      <!-- Multi-card Navigation -->
      <div v-if="hasMultipleCards" class="card-navigation">
        <button 
          @click="prevCard" 
          :disabled="currentCardIndex === 0"
          class="nav-btn"
        >
          <i class="pi pi-chevron-left"></i>
        </button>
        <div class="nav-indicator">
          <span class="nav-current">{{ currentCardIndex + 1 }}</span>
          <span class="nav-separator">/</span>
          <span class="nav-total">{{ totalCardsCount }}</span>
          <span class="nav-label">{{ currentCardData?.cardData?.name || $t('import.unnamed_card') }}</span>
        </div>
        <button 
          @click="nextCard" 
          :disabled="currentCardIndex >= totalCardsCount - 1"
          class="nav-btn"
        >
          <i class="pi pi-chevron-right"></i>
        </button>
      </div>
      
      <!-- Validation Issues -->
      <div v-if="importPreview.errors.length > 0" class="validation-errors">
        <h5 class="errors-title">
          <i class="pi pi-times-circle"></i>
          {{ $t('import.validation_errors') }}
        </h5>
        <div class="errors-list">
          <div 
            v-for="(error, index) in importPreview.errors.slice(0, 5)" 
            :key="index"
            class="error-item"
          >
            <i class="pi pi-times-circle error-icon"></i>
            <span class="error-text">{{ error }}</span>
          </div>
          <div v-if="importPreview.errors.length > 5" class="more-errors">
            +{{ importPreview.errors.length - 5 }} {{ $t('import.more_errors') }}
          </div>
        </div>
      </div>
      
      <div v-if="importPreview.warnings.length > 0" class="validation-warnings">
        <h5 class="warnings-title">
          <i class="pi pi-exclamation-triangle"></i>
          {{ $t('import.validation_warnings') }}
        </h5>
        <div class="warnings-list">
          <div 
            v-for="(warning, index) in importPreview.warnings.slice(0, 3)" 
            :key="index"
            class="warning-item"
          >
            <i class="pi pi-exclamation-circle warning-icon"></i>
            <span class="warning-text">{{ warning }}</span>
          </div>
          <div v-if="importPreview.warnings.length > 3" class="more-warnings">
            +{{ importPreview.warnings.length - 3 }} {{ $t('import.more_warnings') }}
          </div>
        </div>
      </div>
      
      <!-- Card Preview -->
      <div v-if="currentCardData?.cardData" class="card-preview">
        <h5 class="preview-section-title">
          <i class="pi pi-id-card"></i>
          {{ $t('import.import_preview_card_info') }}
        </h5>
        <div class="card-preview-content">
          <div class="card-preview-header">
            <!-- Card Image -->
            <div class="card-image-preview">
              <img 
                v-if="getCardImageUrl()"
                :src="getCardImageUrl()"
                :alt="currentCardData.cardData.name || $t('import.card_image')"
                class="card-preview-image"
              />
              <div v-else class="card-image-placeholder">
                <i class="pi pi-id-card text-2xl text-slate-400"></i>
              </div>
            </div>
            
            <!-- Card Details -->
            <div class="card-details">
              <div class="preview-field">
                <span class="field-label">{{ $t('common.name') }}:</span>
                <span class="field-value">{{ currentCardData.cardData.name || $t('import.unnamed_card') }}</span>
              </div>
              <div class="preview-field">
                <span class="field-label">{{ $t('common.description') }}:</span>
                <span class="field-value">{{ truncateText(currentCardData.cardData.description, 100) }}</span>
              </div>
              <!-- Card Settings Badges -->
              <div class="card-settings-badges">
                <span class="settings-badge badge-mode">
                  <i :class="getContentModeIcon(currentCardData.cardData.content_mode)"></i>
                  {{ getContentModeLabel(currentCardData.cardData.content_mode) }}
                </span>
                <span v-if="currentCardData.cardData.is_grouped" class="settings-badge badge-grouped">
                  <i class="pi pi-sitemap"></i>
                  {{ $t('templates.grouped') }}
                </span>
                <span class="settings-badge badge-billing">
                  <i :class="currentCardData.cardData.billing_type === 'digital' ? 'pi pi-qrcode' : 'pi pi-id-card'"></i>
                  {{ currentCardData.cardData.billing_type === 'digital' ? $t('templates.billing_digital') : $t('templates.billing_physical') }}
                </span>
                <span v-if="currentCardData.cardData.original_language && currentCardData.cardData.original_language !== 'en'" class="settings-badge badge-language">
                  {{ getLanguageFlag(currentCardData.cardData.original_language) }}
                  {{ currentCardData.cardData.original_language }}
                </span>
                <span v-if="currentCardData.cardData.conversation_ai_enabled" class="settings-badge badge-ai">
                  <i class="pi pi-sparkles"></i>
                  {{ $t('import.ai_enabled') }}
                </span>
              </div>
              <!-- Translation badges -->
              <div v-if="cardTranslationLanguages.length > 0" class="card-translation-badges">
                <span class="settings-badge badge-translation">
                  <i class="pi pi-language"></i>
                  {{ $t('templates.translations_included') }}
                </span>
                <span 
                  v-for="lang in cardTranslationLanguages.slice(0, 4)" 
                  :key="lang" 
                  class="settings-badge badge-translation-lang"
                >
                  {{ getLanguageFlag(lang) }} {{ lang }}
                </span>
                <span v-if="cardTranslationLanguages.length > 4" class="settings-badge badge-translation-more">
                  +{{ cardTranslationLanguages.length - 4 }}
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>
      
      <!-- Content Preview -->
      <div v-if="currentContentItems.length > 0" class="content-preview">
        <h5 class="preview-section-title">
          <i class="pi pi-list"></i>
          {{ $t('import.import_preview_content_structure', { count: currentContentItems.length }) }}
        </h5>
        
        <!-- Hierarchical Content Preview -->
        <div class="hierarchical-content-preview">
          <div 
            v-for="(item, index) in organizedContentItems" 
            :key="item.name"
            class="preview-content-group"
          >
            <!-- Layer 1 Item -->
            <div class="preview-parent-item">
              <div class="preview-item-header">
                <!-- Expand/Collapse Icon -->
                <i 
                  :class="expandedItems[index] ? 'pi pi-angle-down' : 'pi pi-angle-right'"
                  class="expand-icon"
                  @click="expandedItems[index] = !expandedItems[index]"
                  v-if="item.children && item.children.length > 0"
                ></i>
                <div v-else class="expand-icon-placeholder"></div>
                
                <!-- Thumbnail -->
                <div class="preview-thumbnail">
                  <img 
                    v-if="getItemImageUrl(item, index)"
                    :src="getItemImageUrl(item, index)"
                    :alt="item.name"
                    class="preview-image"
                  />
                  <i class="pi pi-image text-slate-400" v-else-if="item.has_images"></i>
                  <i class="pi pi-file text-slate-400" v-else></i>
                </div>
                
                <!-- Item Info -->
                <div class="preview-item-info">
                  <div class="preview-item-name">{{ item.name }}</div>
                  <div class="preview-item-meta">
                    <span class="layer-badge layer-1">{{ $t('import.layer_1') }}</span>
                    <span v-if="item.children && item.children.length > 0" class="children-count">
                      {{ $t('content.sub_items_count', { count: item.children.length }) }}
                    </span>
                    <span v-if="item.has_images" class="image-badge">
                      <i class="pi pi-image"></i>
                      {{ item.image_count }}
                    </span>
                  </div>
                </div>
              </div>
              
              <!-- Content preview -->
              <div class="preview-item-content">{{ truncateText(item.content, 100) }}</div>
            </div>
            
            <!-- Layer 2 Items (Sub-items) -->
            <Transition name="expand">
              <div v-if="expandedItems[index] && item.children && item.children.length > 0" class="preview-children">
                <div 
                  v-for="(child, childIndex) in item.children.slice(0, 5)" 
                  :key="child.name"
                  class="preview-child-item"
                >
                  <div class="preview-item-header">
                    <!-- Indent indicator -->
                    <div class="child-indent"></div>
                    
                    <!-- Thumbnail -->
                    <div class="preview-thumbnail preview-thumbnail-small">
                      <img 
                        v-if="getChildImageUrl(child, index, childIndex)"
                        :src="getChildImageUrl(child, index, childIndex)"
                        :alt="child.name"
                        class="preview-image"
                      />
                      <i class="pi pi-image text-slate-400" v-else-if="child.has_images"></i>
                      <i class="pi pi-file text-slate-400" v-else></i>
                    </div>
                    
                    <!-- Item Info -->
                    <div class="preview-item-info">
                      <div class="preview-item-name">{{ child.name }}</div>
                      <div class="preview-item-meta">
                        <span class="layer-badge layer-2">{{ $t('import.layer_2') }}</span>
                        <span class="sub-item-index">{{ $t('content.sub_item_index', { index: childIndex + 1 }) }}</span>
                        <span v-if="child.has_images" class="image-badge">
                          <i class="pi pi-image"></i>
                          {{ child.image_count }}
                        </span>
                      </div>
                    </div>
                  </div>
                  
                  <!-- Content preview -->
                  <div class="preview-item-content preview-child-content">{{ truncateText(child.content, 80) }}</div>
                </div>
                
                <!-- Show more indicator if there are more children -->
                <div v-if="item.children.length > 5" class="more-children">
                  <i class="pi pi-ellipsis-h"></i>
                  +{{ item.children.length - 5 }} {{ $t('import.more_sub_items') }}
                </div>
              </div>
            </Transition>
          </div>
        </div>
      </div>
      
      <!-- Preview Actions -->
      <div class="preview-actions">
        <Button 
          :label="$t('common.cancel')"
          icon="pi pi-times"
          @click="cancelImport"
          class="cancel-button text-blue-600 hover:text-blue-800 border-0 bg-transparent"
        />
        <Button 
          :label="confirmButtonLabel"
          icon="pi pi-check"
          @click="executeImport"
          :disabled="!canExecuteImport"
          :loading="importing"
          class="confirm-button bg-blue-600 hover:bg-blue-700 text-white border-0 disabled:bg-slate-400"
        />
      </div>
    </div>

    <!-- Import Progress -->
    <div v-if="importing" class="import-progress">
      <div class="progress-header">
        <h4 class="progress-title">{{ $t('import.importing_data') }}</h4>
        <span class="progress-percent">{{ importProgressPercent }}%</span>
      </div>
      <ProgressBar :value="importProgressPercent" class="progress-bar" />
      <div class="progress-status">
        <span class="status-text">{{ importStatus }}</span>
      </div>
    </div>

    <!-- Import Results -->
    <div v-if="importResults" class="import-results">
      <div class="results-header">
        <div class="results-icon" :class="{ 
          'success': importResults.success, 
          'error': !importResults.success 
        }">
          <i :class="importResults.success ? 'pi pi-check-circle' : 'pi pi-times-circle'"></i>
        </div>
        <div class="results-content">
          <h4 class="results-title">
            {{ importResults.success ? $t('import.import_completed') : $t('import.import_failed') }}
          </h4>
          <p class="results-summary">{{ importResults.message }}</p>
        </div>
      </div>
      
      <div v-if="importResults.success && importResults.details" class="results-details">
        <div class="detail-grid">
          <div class="detail-item">
            <span class="detail-label">{{ $t('import.cards_created') }}</span>
            <span class="detail-value success">{{ importResults.details.cardsCreated || 0 }}</span>
          </div>
          <div class="detail-item">
            <span class="detail-label">{{ $t('import.content_items_created') }}</span>
            <span class="detail-value success">{{ importResults.details.contentCreated || 0 }}</span>
          </div>
          <div class="detail-item">
            <span class="detail-label">{{ $t('import.images_processed') }}</span>
            <span class="detail-value info">{{ importResults.details.imagesProcessed || 0 }}</span>
          </div>
          <div class="detail-item" v-if="importResults.details.warnings">
            <span class="detail-label">{{ $t('import.warnings') }}</span>
            <span class="detail-value warning">{{ importResults.details.warnings }}</span>
          </div>
        </div>
      </div>
      
      <div class="results-actions">
        <Button 
          :label="$t('import.import_another_file')"
          icon="pi pi-plus"
          @click="resetImport"
          class="reset-button text-blue-600 hover:text-blue-800 border-0 bg-transparent"
        />
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onUnmounted } from 'vue'
import { useI18n } from 'vue-i18n'
import { useToast } from 'primevue/usetoast'
import { useRouter } from 'vue-router'
import { generateImportTemplate, importExcelToCardData } from '@/utils/excelHandler'
import { applyCropParametersToImage, parseCropParameters } from '@/utils/imageCropUtils'
import { getCardAspectRatio, getContentAspectRatio } from '@/utils/cardConfig'
import { supabase } from '@/lib/supabase'
import { useSubscriptionStore } from '@/stores/subscription'
import { SUPPORTED_LANGUAGES } from '@/stores/translation'
import Button from 'primevue/button'
import ProgressBar from 'primevue/progressbar'
import { Transition } from 'vue'
import FileUploadZone from '@/components/shared/FileUploadZone.vue'

const emit = defineEmits(['imported'])
const toast = useToast()
const router = useRouter()
const { t } = useI18n()
const subscriptionStore = useSubscriptionStore()

// Refs
const uploadZone = ref(null)

// State
const importing = ref(false)
const importPreview = ref(null)
const importResults = ref(null)
const importStatus = ref('')
const importProgress = ref(0)
const feedbackMessage = ref(null) // Inline feedback message state
const expandedItems = ref([])
const currentCardIndex = ref(0) // For navigating multiple cards
const createdImageUrls = ref(new Set())

// Computed
const importProgressPercent = computed(() => Math.round(importProgress.value))

const confirmButtonLabel = computed(() => {
  if (importing.value) return t('import.importing')
  if (!importPreview.value) return t('import.confirm_import')
  const errors = importPreview.value.errors.length
  const warnings = importPreview.value.warnings.length
  
  if (errors > 0) return t('import.cannot_import_with_errors', { errors })
  if (warnings > 0) return t('import.import_with_warnings', { warnings })
  return t('import.confirm_import')
})

const canExecuteImport = computed(() => {
  return importPreview.value && 
    importPreview.value.isValid &&
    (importPreview.value.cardData || importPreview.value.contentItems.length > 0 || (importPreview.value.cards && importPreview.value.cards.length > 0)) &&
    !importing.value
})

// Multi-card computed properties
const hasMultipleCards = computed(() => {
  return importPreview.value?.cards && importPreview.value.cards.length > 1
})

const totalCardsCount = computed(() => {
  if (!importPreview.value) return 0
  return importPreview.value.cards?.length || (importPreview.value.cardData ? 1 : 0)
})

const totalContentItemsCount = computed(() => {
  if (!importPreview.value) return 0
  if (importPreview.value.cards && importPreview.value.cards.length > 0) {
    return importPreview.value.cards.reduce((sum, c) => sum + (c.contentItems?.length || 0), 0)
  }
  return importPreview.value.contentItems?.length || 0
})

const currentCardData = computed(() => {
  if (!importPreview.value) return null
  if (importPreview.value.cards && importPreview.value.cards.length > 0) {
    return importPreview.value.cards[currentCardIndex.value]
  }
  // Fallback for single card format
  return {
    cardData: importPreview.value.cardData,
    contentItems: importPreview.value.contentItems,
    images: importPreview.value.images
  }
})

const currentContentItems = computed(() => {
  return currentCardData.value?.contentItems || []
})

// Computed for extracted image count (used in processFile feedback)
const extractedImageCount = computed(() => {
  if (!importPreview.value) return 0
  
  let count = 0
  if (importPreview.value.cards && importPreview.value.cards.length > 0) {
    importPreview.value.cards.forEach(card => {
      if (card.images) {
        card.images.forEach(images => {
          count += Array.isArray(images) ? images.length : 1
        })
      }
    })
  } else if (importPreview.value.images) {
    importPreview.value.images.forEach(images => {
      count += Array.isArray(images) ? images.length : 1
    })
  }
  return count
})

// Computed for card translation languages
const cardTranslationLanguages = computed(() => {
  const cardData = currentCardData.value?.cardData
  if (!cardData || !cardData.translations_json) return []
  
  try {
    const translations = typeof cardData.translations_json === 'string' 
      ? JSON.parse(cardData.translations_json) 
      : cardData.translations_json
    return Object.keys(translations)
  } catch (e) {
    return []
  }
})

const organizedContentItems = computed(() => {
  const items = currentContentItems.value
  if (!items || items.length === 0) return []
  
  // Group items by layer
  const layer1Items = items.filter(item => item.layer === 'Layer 1')
  const layer2Items = items.filter(item => item.layer === 'Layer 2')
  
  // Create hierarchical structure
  const organized = layer1Items.map(parent => {
    const children = layer2Items.filter(child => {
      // Match by parent_item name or parent_reference
      return child.parent_item === parent.name || 
             child.parent_reference === parent.name
    })
    
    return {
      ...parent,
      children: children
    }
  })
  
  // Initialize expanded state
  if (expandedItems.value.length !== organized.length) {
    expandedItems.value = new Array(organized.length).fill(true) // Expand all by default
  }
  
  return organized
})

// Feedback Helper Functions
function showFeedback(severity, summary, detail, autoDismiss = true) {
  feedbackMessage.value = { severity, summary, detail }
  
  // Auto-dismiss after delay for non-error messages
  if (autoDismiss && severity !== 'error') {
    setTimeout(() => {
      feedbackMessage.value = null
    }, severity === 'success' ? 4000 : 6000)
  }
}

function clearFeedback() {
  feedbackMessage.value = null
}

function getFeedbackIcon(severity) {
  const icons = {
    success: 'pi pi-check-circle',
    info: 'pi pi-info-circle',
    warn: 'pi pi-exclamation-triangle',
    error: 'pi pi-times-circle'
  }
  return icons[severity] || 'pi pi-info-circle'
}

// Handle file removed from upload zone
function handleFileRemoved() {
  importPreview.value = null
  importResults.value = null
  expandedItems.value = []
  currentCardIndex.value = 0
}

// Multi-card navigation
function prevCard() {
  if (currentCardIndex.value > 0) {
    currentCardIndex.value--
    expandedItems.value = []
  }
}

function nextCard() {
  if (currentCardIndex.value < totalCardsCount.value - 1) {
    currentCardIndex.value++
    expandedItems.value = []
  }
}

// Handle upload error from shared component
function handleUploadError(message) {
  showFeedback('error', t('import.invalid_file_type'), message, false)
}

// Trigger file input on shared component
function triggerFileInput() {
  uploadZone.value?.triggerFileInput()
}

// Remove file using shared component
function removeFile() {
  // Clean up object URLs
  createdImageUrls.value.forEach(url => URL.revokeObjectURL(url))
  createdImageUrls.value.clear()
  
  uploadZone.value?.removeFile()
  handleFileRemoved()
}

async function downloadTemplate() {
  try {
    const buffer = await generateImportTemplate()
    
    const filename = `FunTell_Import_Template_${new Date().toISOString().split('T')[0]}.xlsx`
    const blob = new Blob([buffer], { 
      type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' 
    })
    const url = window.URL.createObjectURL(blob)
    const link = document.createElement('a')
    link.href = url
    link.download = filename
    link.click()
    window.URL.revokeObjectURL(url)
    
    showFeedback('success', t('import.template_downloaded'), 
      t('import.template_downloaded_desc'), 
      true)
  } catch (error) {
    console.error('Template download error:', error)
    showFeedback('error', t('messages.download_failed'), 
      t('import.failed_generate_template'), 
      false)
  }
}

// Process file - called when file is selected via shared component or example file
async function processFile(file) {
  // Analyze file
  try {
    importStatus.value = t('import.analyzing_excel_extracting')
    const preview = await importExcelToCardData(file)
    importPreview.value = preview
    
    if (preview.isValid) {
      const messageKey = extractedImageCount.value > 0 ? 'import.file_analyzed_desc_with_images' : 'import.file_analyzed_desc';
      showFeedback('success', t('import.file_analyzed'), 
        t(messageKey, { count: preview.contentItems.length, images: extractedImageCount.value }), 
        true)
    } else {
      showFeedback('warn', t('import.validation_issues'), 
        t('import.validation_issues_desc', { errors: preview.errors.length }), 
        false)
    }
  } catch (error) {
    console.error('File analysis error:', error)
    showFeedback('error', t('import.file_analysis_failed'), 
      error.message || t('import.failed_analyze_uploaded_file'), 
      false)
    removeFile()
  }
}

// Process multiple files - called when multiple files are selected
async function processMultipleFiles(files) {
  try {
    importStatus.value = t('import.analyzing_multiple_files', { count: files.length })
    const preview = await importExcelToCardData(files)
    importPreview.value = preview
    
    const totalCards = preview.cards?.length || 0
    const totalItems = preview.cards?.reduce((sum, c) => sum + (c.contentItems?.length || 0), 0) || 0
    
    if (preview.isValid) {
      showFeedback('success', t('import.files_analyzed'), 
        t('import.files_analyzed_desc', { cards: totalCards, items: totalItems }), 
        true)
    } else {
      showFeedback('warn', t('import.validation_issues'), 
        t('import.validation_issues_desc', { errors: preview.errors.length }), 
        false)
    }
  } catch (error) {
    console.error('Multiple files analysis error:', error)
    showFeedback('error', t('import.file_analysis_failed'), 
      error.message || t('import.failed_analyze_uploaded_file'), 
      false)
    removeFile()
  }
}

function cancelImport() {
  importPreview.value = null
  importResults.value = null
}

async function executeImport() {
  if (!importPreview.value || !canExecuteImport.value) return
  
  // Check subscription limit before importing
  await subscriptionStore.fetchSubscription()
  
  // Calculate how many cards will be created
  const cardsToCreate = importPreview.value.cards?.length || (importPreview.value.cardData ? 1 : 0)
  const currentCount = subscriptionStore.experienceCount
  const limit = subscriptionStore.experienceLimit
  
  // Check if import would exceed limit
  if (currentCount + cardsToCreate > limit) {
    const canCreate = limit - currentCount
    showFeedback(
      'warn',
      t('subscription.limit_reached'),
      t('subscription.bulk_import_limit', {
        limit: limit,
        current: currentCount,
        importing: cardsToCreate,
        canCreate: Math.max(0, canCreate)
      }),
      false
    )
    
    // Offer to navigate to subscription page
    toast.add({
      severity: 'info',
      summary: t('subscription.upgrade_available'),
      detail: t('subscription.upgrade_to_create_more', { limit, current: currentCount }),
      life: 8000
    })
    return
  }
  
  importing.value = true
  importProgress.value = 0
  importStatus.value = t('import.starting_import')
  
  try {
    // Simulate progress updates
    const progressInterval = setInterval(() => {
      if (importProgress.value < 90) {
        importProgress.value += Math.random() * 15
        updateImportStatus()
      }
    }, 300)
    
    // Execute the actual import
    const result = await importDataToDatabase(importPreview.value)
    
    clearInterval(progressInterval)
    importProgress.value = 100
    importStatus.value = t('import.import_completed')
    
    importResults.value = result
    importPreview.value = null
    
    // Emit event to refresh parent
    emit('imported', result)
    
    showFeedback(
      result.success ? 'success' : 'warn',
      result.success ? t('import.import_successful') : t('import.import_completed_with_issues'),
      result.message,
      true
    )
    
  } catch (error) {
    console.error('Import error:', error)
    importResults.value = {
      success: false,
      message: error.message || t('import.failed_unknown_error'),
      details: { errors: 1 }
    }
    
    showFeedback('error', t('import.import_failed'), 
      error.message || t('import.failed_import_data'), 
      false)
  } finally {
    importing.value = false
  }
}

async function uploadImageToSupabase(imageData, folder) {
  try {
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) {
      throw new Error('User not authenticated')
    }

    // Create a blob from the image buffer
    const blob = new Blob([imageData.buffer], { type: `image/${imageData.extension}` })
    
    // Generate unique filename
    const fileName = `${Date.now()}_${Math.random().toString(36).substring(7)}.${imageData.extension}`
    const filePath = `${user.id}/${folder}/${fileName}`
    
    // Upload to Supabase storage
    const { data, error } = await supabase.storage
      .from('userfiles')
      .upload(filePath, blob, {
        contentType: `image/${imageData.extension}`,
        upsert: false
      })
    
    if (error) {
      throw error
    }
    
    // Get public URL
    const { data: { publicUrl } } = supabase.storage
      .from('userfiles')
      .getPublicUrl(filePath)
    
    return publicUrl
  } catch (error) {
    console.error('Error uploading image:', error)
    throw error
  }
}

async function importDataToDatabase(importData) {
  const results = {
    cardsCreated: 0,
    contentCreated: 0,
    imagesProcessed: 0,
    warnings: 0,
    errors: []
  };

  try {
    // Import card data
    if (importData.cardData) {
      // Handle card image if it exists
      let cardImageUrl = null;
      let cardOriginalImageUrl = null;
      let cardCropParams = null;
      
      if (importData.images && importData.images.has('card_image')) {
        const cardImages = importData.images.get('card_image');
        if (cardImages && cardImages.length > 0) {
          const originalImageFile = cardImages[0];
          
          // Parse crop parameters from imported data
          const cropParamsJson = importData.cardData.crop_parameters_json;
          const parsedCropParams = parseCropParameters(cropParamsJson);
          
          if (parsedCropParams) {
            // Has crop parameters - generate cropped image
            try {
              importStatus.value = 'Applying crop parameters to card image...';
              const cardAspectRatio = getCardAspectRatio();
              const croppedImageFile = await applyCropParametersToImage(
                originalImageFile,
                parsedCropParams,
                cardAspectRatio
              );
              
              // Upload both images
              importStatus.value = 'Uploading original card image...';
              cardOriginalImageUrl = await uploadImageToSupabase(originalImageFile, 'card-images');
              importStatus.value = 'Uploading cropped card image...';
              cardImageUrl = await uploadImageToSupabase(croppedImageFile, 'card-images');
              cardCropParams = parsedCropParams;
              results.imagesProcessed += 2;
              
              console.log('✓ Card image cropped and uploaded successfully');
            } catch (cropError) {
              console.warn('Failed to apply crop parameters:', cropError);
              results.errors.push(`Failed to apply crop to card image: ${cropError.message}`);
              // Fallback: use original as both
              try {
                cardImageUrl = await uploadImageToSupabase(originalImageFile, 'card-images');
                cardOriginalImageUrl = cardImageUrl;
                results.imagesProcessed++;
              } catch (uploadError) {
                results.errors.push(`Failed to upload card image: ${uploadError.message}`);
              }
            }
          } else {
            // No crop parameters - use original for both
            try {
              importStatus.value = 'Uploading card image...';
              cardImageUrl = await uploadImageToSupabase(originalImageFile, 'card-images');
              cardOriginalImageUrl = cardImageUrl;
              results.imagesProcessed++;
            } catch (imgError) {
              results.errors.push(`Failed to upload card image: ${imgError.message}`);
            }
          }
        }
      }

      // Validate and sanitize QR code position
      const validQrPositions = ['TL', 'TR', 'BL', 'BR'];
      let qrPosition = importData.cardData.qr_code_position || 'BR';
      if (!validQrPositions.includes(qrPosition)) {
        console.warn(`Invalid QR position '${qrPosition}', defaulting to 'BR'`);
        qrPosition = 'BR';
        results.warnings++;
      }

      importStatus.value = 'Creating card...';
      
      // Parse translations JSON if provided (for 1-step import)
      let translationsData = null;
      if (importData.cardData.translations_json) {
        try {
          translationsData = JSON.parse(importData.cardData.translations_json);
        } catch (e) {
          console.warn('Failed to parse card translations JSON:', e);
        }
      }
      
      // Validate content_mode
      // 'cards' is legacy DB value, 'inline' is the modern UI term (maps to 'cards' in DB)
      const validContentModes = ['single', 'list', 'grid', 'cards', 'grouped', 'inline'];
      let contentMode = importData.cardData.content_mode || 'list';
      if (!validContentModes.includes(contentMode)) {
        console.warn(`Invalid content_mode '${contentMode}', defaulting to 'list'`);
        contentMode = 'list';
        results.warnings++;
      } else if (contentMode === 'inline') {
        // Map 'inline' to 'cards' for DB storage (schema constraint)
        contentMode = 'cards';
      }
      
      // Validate group_display
      const validGroupDisplays = ['expanded', 'collapsed'];
      let groupDisplay = importData.cardData.group_display || 'expanded';
      if (!validGroupDisplays.includes(groupDisplay)) {
        console.warn(`Invalid group_display '${groupDisplay}', defaulting to 'expanded'`);
        groupDisplay = 'expanded';
        results.warnings++;
      }
      
      // Validate billing_type
      const validBillingTypes = ['physical', 'digital'];
      let billingType = importData.cardData.billing_type || 'physical';
      if (!validBillingTypes.includes(billingType)) {
        console.warn(`Invalid billing_type '${billingType}', defaulting to 'physical'`);
        billingType = 'physical';
        results.warnings++;
      }
      
      // 1-STEP IMPORT: Pass ALL fields to create_card (19 data columns)
      const { data, error } = await supabase.rpc('create_card', {
        p_name: importData.cardData.name,
        p_description: importData.cardData.description || '',
        p_ai_instruction: importData.cardData.ai_instruction || '',
        p_ai_knowledge_base: importData.cardData.ai_knowledge_base || '',
        p_ai_welcome_general: importData.cardData.ai_welcome_general || '',
        p_ai_welcome_item: importData.cardData.ai_welcome_item || '',
        p_conversation_ai_enabled: importData.cardData.conversation_ai_enabled,
        p_qr_code_position: qrPosition,
        p_image_url: cardImageUrl,
        p_original_image_url: cardOriginalImageUrl,
        p_crop_parameters: cardCropParams,
        p_original_language: importData.cardData.original_language || 'en',
        p_content_hash: importData.cardData.content_hash || null,  // Preserve original hash
        p_translations: translationsData,  // Import with translations (hashes already match!)
        p_content_mode: contentMode,
        p_is_grouped: importData.cardData.is_grouped || false,
        p_group_display: groupDisplay,
        p_billing_type: billingType,
        p_max_scans: importData.cardData.max_scans ?? null,
        p_daily_scan_limit: importData.cardData.daily_scan_limit ?? 500
      })
      
      if (error) throw error
      
      const cardId = data; // data is directly the UUID
      results.cardsCreated = 1;
      
      // No need for hash recalculation! Translations imported with matching hashes ✅
      
      // Import content items
      if (importData.contentItems.length > 0) {
        const parentMap = new Map();
        const layer1Items = importData.contentItems.filter(item => item.layer === 'Layer 1');
        const layer2Items = importData.contentItems.filter(item => item.layer === 'Layer 2');

        // Process Layer 1 items first
        for (const item of layer1Items) {
          try {
            // Handle content item image if it exists
            let contentImageUrl = null;
            let contentOriginalImageUrl = null;
            let contentCropParams = null;
            
            if (item.has_images && importData.images) {
              const itemKey = `item_${importData.contentItems.indexOf(item) + 5}`; // Row number in Excel
              const itemImages = importData.images.get(itemKey);
              if (itemImages && itemImages.length > 0) {
                const originalImageFile = itemImages[0];
                
                // Parse crop parameters
                const cropParamsJson = item.crop_parameters_json;
                const parsedCropParams = parseCropParameters(cropParamsJson);
                
                if (parsedCropParams) {
                  // Has crop parameters - generate cropped image
                  try {
                    importStatus.value = t('import.cropping_image', { name: item.name });
                    const contentAspectRatio = getContentAspectRatio();
                    const croppedImageFile = await applyCropParametersToImage(
                      originalImageFile,
                      parsedCropParams,
                      contentAspectRatio
                    );
                    
                    // Upload both images
                    contentOriginalImageUrl = await uploadImageToSupabase(originalImageFile, 'content-item-images');
                    contentImageUrl = await uploadImageToSupabase(croppedImageFile, 'content-item-images');
                    contentCropParams = parsedCropParams;
                    results.imagesProcessed += 2;
                  } catch (cropError) {
                    console.warn(`Failed to crop image for "${item.name}":`, cropError);
                    results.errors.push(`Failed to crop image for "${item.name}": ${cropError.message}`);
                    // Fallback
                    try {
                      contentImageUrl = await uploadImageToSupabase(originalImageFile, 'content-item-images');
                      contentOriginalImageUrl = contentImageUrl;
                      results.imagesProcessed++;
                    } catch (uploadError) {
                      results.errors.push(`Failed to upload image for "${item.name}": ${uploadError.message}`);
                    }
                  }
                } else {
                  // No crop parameters
                  try {
                    contentImageUrl = await uploadImageToSupabase(originalImageFile, 'content-item-images');
                    contentOriginalImageUrl = contentImageUrl;
                    results.imagesProcessed++;
                  } catch (imgError) {
                    results.errors.push(`Failed to upload image for "${item.name}": ${imgError.message}`);
                  }
                }
              }
            }

            // Parse translations for 1-step import
            let itemTranslations = null;
            if (item.translations_json) {
              try {
                itemTranslations = JSON.parse(item.translations_json);
              } catch (e) {
                console.warn(`Failed to parse translations for "${item.name}":`, e);
              }
            }
            
            importStatus.value = t('import.creating_content_item', { name: item.name });
            // 1-STEP IMPORT: Pass translations and hash directly
            const { data: contentData, error: contentError } = await supabase.rpc('create_content_item', {
              p_card_id: cardId,
              p_parent_id: null,
              p_name: item.name,
              p_content: item.content,
              p_ai_knowledge_base: item.ai_knowledge_base || '',
              p_image_url: contentImageUrl,
              p_original_image_url: contentOriginalImageUrl,
              p_crop_parameters: contentCropParams,
              p_content_hash: item.content_hash || null,  // Preserve original hash
              p_translations: itemTranslations  // Import with translations (hashes already match!)
            });
            
            if (contentError) throw contentError;

            const newItemId = contentData; // data is directly the UUID
            parentMap.set(item.name, newItemId);
            results.contentCreated++;
            
            // No need for hash recalculation! Translations imported with matching hashes ✅
            
          } catch (err) {
            results.errors.push(`Content item "${item.name}": ${err.message}`);
          }
        }

        // Process Layer 2 items
        for (const item of layer2Items) {
          try {
            const parentId = parentMap.get(item.parent_item) || null;
            if (!parentId) {
              results.warnings++;
              results.errors.push(`Parent item "${item.parent_item}" not found for "${item.name}". Skipping.`);
              continue;
            }

            // Handle content item image if it exists
            let contentImageUrl = null;
            let contentOriginalImageUrl = null;
            let contentCropParams = null;
            
            if (item.has_images && importData.images) {
              const itemKey = `item_${importData.contentItems.indexOf(item) + 5}`; // Row number in Excel
              const itemImages = importData.images.get(itemKey);
              if (itemImages && itemImages.length > 0) {
                const originalImageFile = itemImages[0];
                
                // Parse crop parameters
                const cropParamsJson = item.crop_parameters_json;
                const parsedCropParams = parseCropParameters(cropParamsJson);
                
                if (parsedCropParams) {
                  // Has crop parameters - generate cropped image
                  try {
                    importStatus.value = t('import.cropping_image', { name: item.name });
                    const contentAspectRatio = getContentAspectRatio();
                    const croppedImageFile = await applyCropParametersToImage(
                      originalImageFile,
                      parsedCropParams,
                      contentAspectRatio
                    );
                    
                    // Upload both images
                    contentOriginalImageUrl = await uploadImageToSupabase(originalImageFile, 'content-item-images');
                    contentImageUrl = await uploadImageToSupabase(croppedImageFile, 'content-item-images');
                    contentCropParams = parsedCropParams;
                    results.imagesProcessed += 2;
                  } catch (cropError) {
                    console.warn(`Failed to crop image for "${item.name}":`, cropError);
                    results.errors.push(`Failed to crop image for "${item.name}": ${cropError.message}`);
                    // Fallback
                    try {
                      contentImageUrl = await uploadImageToSupabase(originalImageFile, 'content-item-images');
                      contentOriginalImageUrl = contentImageUrl;
                      results.imagesProcessed++;
                    } catch (uploadError) {
                      results.errors.push(`Failed to upload image for "${item.name}": ${uploadError.message}`);
                    }
                  }
                } else {
                  // No crop parameters
                  try {
                    contentImageUrl = await uploadImageToSupabase(originalImageFile, 'content-item-images');
                    contentOriginalImageUrl = contentImageUrl;
                    results.imagesProcessed++;
                  } catch (imgError) {
                    results.errors.push(`Failed to upload image for "${item.name}": ${imgError.message}`);
                  }
                }
              }
            }

            // Parse translations for 1-step import
            let subItemTranslations = null;
            if (item.translations_json) {
              try {
                subItemTranslations = JSON.parse(item.translations_json);
              } catch (e) {
                console.warn(`Failed to parse translations for "${item.name}":`, e);
              }
            }
            
            importStatus.value = t('import.creating_sub_item', { name: item.name });
            // 1-STEP IMPORT: Pass translations and hash directly
            const { data: subItemData, error: contentError } = await supabase.rpc('create_content_item', {
              p_card_id: cardId,
              p_parent_id: parentId,
              p_name: item.name,
              p_content: item.content,
              p_ai_knowledge_base: item.ai_knowledge_base || '',
              p_image_url: contentImageUrl,
              p_original_image_url: contentOriginalImageUrl,
              p_crop_parameters: contentCropParams,
              p_content_hash: item.content_hash || null,  // Preserve original hash
              p_translations: subItemTranslations  // Import with translations (hashes already match!)
            });
            
            if (contentError) throw contentError;
            
            const subItemId = subItemData; // data is directly the UUID
            results.contentCreated++;
            
            // No need for hash recalculation! Translations imported with matching hashes ✅

          } catch (err) {
            results.errors.push(`Content item "${item.name}": ${err.message}`);
          }
        }
      }
      
      // CRITICAL: Recalculate all translation hashes to sync with newly created card
      // When importing, translations contain hashes from the OLD card
      // We need to update them to match the NEW card's content hashes
      try {
        importStatus.value = 'Synchronizing translation hashes...';
        const { error: hashError } = await supabase.rpc('recalculate_all_translation_hashes', {
          p_card_id: cardId
        });
        
        if (hashError) {
          console.warn('Failed to recalculate translation hashes:', hashError);
          results.warnings++;
          results.errors.push(`Warning: Translation freshness may not be accurate. Please re-translate if needed.`);
        } else {
          console.log('✓ Translation hashes synchronized successfully');
        }
      } catch (hashRecalcError) {
        console.warn('Failed to recalculate translation hashes:', hashRecalcError);
        results.warnings++;
      }
    }
    
    // Calculate warnings
    results.warnings = importData.warnings.length
    
    const success = results.errors.length === 0
    const message = success 
      ? `Successfully imported ${results.cardsCreated} card and ${results.contentCreated} content items${results.imagesProcessed > 0 ? ` with ${results.imagesProcessed} images` : ''}`
      : `Import completed with ${results.errors.length} errors`
    
    return {
      success,
      message,
      details: results
    }
    
  } catch (error) {
    throw new Error(`Database import failed: ${error.message}`)
  }
}

function updateImportStatus() {
  const statuses = [
    t('import.status_validating'),
    t('import.status_creating_card'),
    t('import.status_processing_content'),
    t('import.status_handling_images'),
    t('import.status_updating_relationships'),
    t('import.status_finalizing')
  ]
  const statusIndex = Math.floor((importProgress.value / 100) * statuses.length)
  importStatus.value = statuses[Math.min(statusIndex, statuses.length - 1)]
}

function resetImport() {
  removeFile()
  importResults.value = null
  expandedItems.value = []
}

// Clean up object URLs when component is unmounted
onUnmounted(() => {
  createdImageUrls.value.forEach(url => URL.revokeObjectURL(url))
  createdImageUrls.value.clear()
})

function formatFileSize(bytes) {
  if (bytes === 0) return '0 Bytes'
  const k = 1024
  const sizes = ['Bytes', 'KB', 'MB', 'GB']
  const i = Math.floor(Math.log(bytes) / Math.log(k))
  return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i]
}

function truncateText(text, maxLength) {
  if (!text) return ''
  if (text.length <= maxLength) return text
  return text.substring(0, maxLength) + '...'
}

function getContentModeIcon(mode) {
  const icons = {
    single: 'pi pi-file',
    list: 'pi pi-list',
    grid: 'pi pi-th-large',
    cards: 'pi pi-clone',
    inline: 'pi pi-bars'
  }
  return icons[mode] || 'pi pi-file'
}

function getContentModeLabel(mode) {
  const labels = {
    single: t('templates.mode_single'),
    list: t('templates.mode_list'),
    grid: t('templates.mode_grid'),
    cards: t('templates.mode_cards'),
    inline: t('templates.mode_inline')
  }
  return labels[mode] || mode
}

// Language flags - aligned with SUPPORTED_LANGUAGES from translation store
// Language flags - aligned with SUPPORTED_LANGUAGES from translation store
const LANGUAGE_FLAGS = {
  'en': '🇺🇸',
  'zh-Hant': '🇭🇰',
  'zh-Hans': '🇨🇳',
  'ja': '🇯🇵',
  'ko': '🇰🇷',
  'es': '🇪🇸',
  'fr': '🇫🇷',
  'ru': '🇷🇺',
  'ar': '🇸🇦',
  'th': '🇹🇭'
}

function getLanguageFlag(lang) {
  return LANGUAGE_FLAGS[lang] || '🌐'
}

// Function to get card image URL
function getCardImageUrl() {
  const cardData = currentCardData.value
  if (!cardData || !cardData.images) return null
  
  const cardImages = cardData.images.get('card_image')
  if (cardImages && cardImages.length > 0) {
    const imageData = cardImages[0]
    const blob = new Blob([imageData.buffer], { type: `image/${imageData.extension}` })
    const url = URL.createObjectURL(blob)
    createdImageUrls.value.add(url)
    return url
  }
  return null
}

// Function to get content item image URL
function getItemImageUrl(item, parentIndex) {
  const cardData = currentCardData.value
  if (!cardData || !cardData.images || !item.has_images) return null
  
  // Calculate the actual row number in Excel for this item
  const layer1Items = currentContentItems.value.filter(i => i.layer === 'Layer 1')
  const itemIndex = layer1Items.findIndex(i => i.name === item.name)
  const excelRowNum = 5 + itemIndex // Excel data starts at row 5
  
  const itemKey = `item_${excelRowNum}`
  const itemImages = cardData.images.get(itemKey)
  if (itemImages && itemImages.length > 0) {
    const imageData = itemImages[0]
    const blob = new Blob([imageData.buffer], { type: `image/${imageData.extension}` })
    const url = URL.createObjectURL(blob)
    createdImageUrls.value.add(url)
    return url
  }
  return null
}

// Function to get child item image URL
function getChildImageUrl(child, parentIndex, childIndex) {
  if (!importPreview.value || !importPreview.value.images || !child.has_images) return null
  
  // Find the actual index of this child in the full content items array
  const allItems = importPreview.value.contentItems
  const childItemIndex = allItems.findIndex(i => i.name === child.name)
  const excelRowNum = 5 + childItemIndex // Excel data starts at row 5
  
  const itemKey = `item_${excelRowNum}`
  const itemImages = importPreview.value.images.get(itemKey)
  if (itemImages && itemImages.length > 0) {
    const imageData = itemImages[0]
    const blob = new Blob([imageData.buffer], { type: `image/${imageData.extension}` })
    const url = URL.createObjectURL(blob)
    createdImageUrls.value.add(url)
    return url
  }
  return null
}
</script>

<style scoped>
.card-bulk-import {
  @apply space-y-6;
}

.import-header {
  @apply bg-gradient-to-r from-slate-50 to-slate-100 rounded-xl p-6 border border-slate-200;
}

.header-content {
  @apply flex items-start gap-4;
}

.import-icon {
  @apply w-12 h-12 bg-blue-600 rounded-full flex items-center justify-center text-white text-xl flex-shrink-0;
}

.import-title {
  @apply text-xl font-semibold text-slate-900 mb-1;
}

.import-description {
  @apply text-slate-600 text-sm leading-relaxed;
}

/* Inline Feedback Styles */
.inline-feedback {
  @apply rounded-lg p-4 mb-6 border-l-4 animate-fadeIn;
}

.feedback-success {
  @apply bg-emerald-50 border-emerald-500;
}

.feedback-info {
  @apply bg-blue-50 border-blue-500;
}

.feedback-warn {
  @apply bg-amber-50 border-amber-500;
}

.feedback-error {
  @apply bg-red-50 border-red-500;
}

.feedback-content {
  @apply flex items-start gap-3;
}

.feedback-icon {
  @apply flex-shrink-0 text-2xl mt-0.5;
}

.feedback-success .feedback-icon {
  @apply text-emerald-600;
}

.feedback-info .feedback-icon {
  @apply text-blue-600;
}

.feedback-warn .feedback-icon {
  @apply text-amber-600;
}

.feedback-error .feedback-icon {
  @apply text-red-600;
}

.feedback-text {
  @apply flex-1;
}

.feedback-title {
  @apply font-semibold text-base mb-1;
}

.feedback-success .feedback-title {
  @apply text-emerald-900;
}

.feedback-info .feedback-title {
  @apply text-blue-900;
}

.feedback-warn .feedback-title {
  @apply text-amber-900;
}

.feedback-error .feedback-title {
  @apply text-red-900;
}

.feedback-detail {
  @apply text-sm leading-relaxed;
}

.feedback-success .feedback-detail {
  @apply text-emerald-700;
}

.feedback-info .feedback-detail {
  @apply text-blue-700;
}

.feedback-warn .feedback-detail {
  @apply text-amber-700;
}

.feedback-error .feedback-detail {
  @apply text-red-700;
}

.feedback-close {
  @apply flex-shrink-0 mt-1;
}

@keyframes fadeIn {
  from {
    opacity: 0;
    transform: translateY(-10px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.animate-fadeIn {
  animation: fadeIn 0.3s ease-out;
}

.regular-import-content {
  @apply space-y-6;
}

.quick-actions {
  @apply bg-white border border-slate-200 rounded-lg p-4;
}

.action-grid {
  @apply grid grid-cols-1 sm:grid-cols-2 gap-4;
}

.action-item {
  @apply text-center space-y-2;
}

.template-button {
  @apply w-full;
}

.import-button {
  @apply w-full;
}

.action-desc {
  @apply text-xs text-slate-500 block;
}

.import-preview {
  @apply bg-white border border-slate-200 rounded-lg p-6 space-y-4;
}

.preview-header {
  @apply flex items-center justify-between;
}

.preview-title {
  @apply flex items-center gap-2 text-lg font-semibold text-slate-900;
}

.preview-icon {
  @apply text-blue-500;
}

.preview-stats {
  @apply flex gap-4;
}

.stat-item {
  @apply flex items-center gap-1 text-sm font-medium;
}

/* Card Navigation */
.card-navigation {
  @apply flex items-center justify-center gap-3 py-3 px-4 bg-slate-100 rounded-lg my-4;
}

.nav-btn {
  @apply w-8 h-8 flex items-center justify-center rounded-full bg-white border border-slate-200 text-slate-600 hover:bg-blue-50 hover:border-blue-300 hover:text-blue-600 transition-all disabled:opacity-40 disabled:cursor-not-allowed disabled:hover:bg-white disabled:hover:border-slate-200 disabled:hover:text-slate-600;
}

.nav-indicator {
  @apply flex items-center gap-2;
}

.nav-current {
  @apply text-lg font-bold text-blue-600;
}

.nav-separator {
  @apply text-slate-400;
}

.nav-total {
  @apply text-lg font-medium text-slate-600;
}

.nav-label {
  @apply text-sm text-slate-500 max-w-32 truncate ml-2;
}

.validation-errors {
  @apply bg-red-50 border border-red-200 rounded-lg p-4;
}

.errors-title {
  @apply flex items-center gap-2 text-sm font-semibold text-red-800 mb-3;
}

.errors-list {
  @apply space-y-2;
}

.error-item {
  @apply flex items-start gap-2 text-sm;
}

.error-icon {
  @apply text-red-600 mt-0.5 flex-shrink-0;
}

.error-text {
  @apply text-red-800;
}

.more-errors {
  @apply text-xs text-red-700 font-medium;
}

.validation-warnings {
  @apply bg-yellow-50 border border-yellow-200 rounded-lg p-4;
}

.warnings-title {
  @apply flex items-center gap-2 text-sm font-semibold text-yellow-800 mb-3;
}

.warnings-list {
  @apply space-y-2;
}

.warning-item {
  @apply flex items-start gap-2 text-sm;
}

.warning-icon {
  @apply text-yellow-600 mt-0.5 flex-shrink-0;
}

.warning-text {
  @apply text-yellow-800;
}

.more-warnings {
  @apply text-xs text-yellow-700 font-medium;
}

.card-preview, .content-preview {
  @apply bg-slate-50 rounded-lg p-4;
}

.card-preview-header {
  @apply flex gap-4;
}

.card-image-preview {
  @apply flex-shrink-0;
}

.card-preview-image {
  @apply w-16 h-24 object-cover rounded-lg border border-slate-200;
}

.card-image-placeholder {
  @apply w-16 h-24 bg-slate-100 rounded-lg border border-slate-200 flex items-center justify-center;
}

.card-details {
  @apply flex-1 min-w-0;
}

.card-settings-badges {
  @apply flex flex-wrap gap-2 mt-3;
}

.settings-badge {
  @apply inline-flex items-center gap-1 px-2 py-1 rounded-full text-xs font-medium;
}

.badge-mode {
  @apply bg-blue-100 text-blue-700;
}

.badge-grouped {
  @apply bg-purple-100 text-purple-700;
}

.badge-billing {
  @apply bg-slate-100 text-slate-700;
}

.badge-language {
  @apply bg-amber-100 text-amber-700;
}

.badge-ai {
  @apply bg-emerald-100 text-emerald-700;
}

.card-translation-badges {
  @apply flex flex-wrap gap-2 mt-2;
}

.badge-translation {
  @apply bg-green-100 text-green-700;
}

.badge-translation-lang {
  @apply bg-green-50 text-green-600 text-xs;
}

.badge-translation-more {
  @apply bg-green-100 text-green-700 text-xs;
}

/* Mobile responsive styles */
@media (max-width: 768px) {
  .card-bulk-import {
    @apply space-y-4;
  }
  
  .action-grid {
    @apply grid-cols-1 gap-3;
  }
  
  .import-preview {
    @apply p-4 space-y-3;
  }
  
  .preview-header {
    @apply flex-col gap-3 items-start;
  }
  
  .preview-stats {
    @apply flex-wrap gap-2;
  }
  
  .card-preview-header {
    @apply flex-col gap-3;
  }
  
  .card-image-preview {
    @apply self-center;
  }
  
  .preview-item-header {
    @apply gap-2;
  }
  
  .preview-item-content {
    @apply ml-10 text-xs;
  }
  
  .preview-child-content {
    @apply ml-6 text-xs;
  }
  
  .preview-thumbnail {
    @apply w-8 h-8;
  }
  
  .preview-thumbnail-small {
    @apply w-6 h-6;
  }
  
  .hierarchical-content-preview {
    @apply space-y-2;
  }
  
  .preview-parent-item {
    @apply p-3;
  }
  
  .preview-child-item {
    @apply p-2;
  }
  
  .preview-actions {
    @apply flex-col gap-3;
  }
  
  .detail-grid {
    @apply grid-cols-2 gap-3;
  }
  
  .import-header {
    @apply p-4;
  }
  
  .header-content {
    @apply gap-3;
  }
  
  .import-title {
    @apply text-lg;
  }
  
  .import-description {
    @apply text-xs;
  }
  
  /* Mobile responsive styles for Try Example section */
  .try-example-section {
    @apply p-4 space-y-3;
  }
  
  .example-title {
    @apply text-xl;
  }
  
  .example-description {
    @apply text-sm;
  }
  
  .example-button {
    @apply px-6 py-3 text-base;
  }
  
  .example-features {
    @apply flex-col gap-2;
  }
  
  .feature-item {
    @apply px-2 py-1 text-xs;
  }
}

.hierarchical-content-preview {
  @apply space-y-3;
}

.preview-content-group {
  @apply bg-white rounded-lg border border-slate-200 overflow-hidden;
}

.preview-parent-item {
  @apply p-4;
}

.preview-child-item {
  @apply p-3 bg-slate-50;
}

.preview-item-header {
  @apply flex items-center gap-3 mb-2;
}

.expand-icon {
  @apply text-slate-600 cursor-pointer hover:text-blue-600 transition-colors w-4 flex-shrink-0;
}

.expand-icon-placeholder {
  @apply w-4 flex-shrink-0;
}

.preview-thumbnail {
  @apply w-10 h-10 bg-slate-100 rounded-lg border border-slate-200 flex items-center justify-center text-slate-400 flex-shrink-0 overflow-hidden;
}

.preview-thumbnail-small {
  @apply w-8 h-8;
}

.preview-image {
  @apply w-full h-full object-cover;
}

.preview-item-info {
  @apply flex-1 min-w-0;
}

.preview-item-name {
  @apply font-medium text-slate-900 truncate;
}

.preview-item-meta {
  @apply flex items-center gap-2 mt-1 text-sm;
}

.preview-item-content {
  @apply text-sm text-slate-600 ml-16;
}

.preview-child-content {
  @apply ml-12;
}

.preview-children {
  @apply border-t border-slate-200 space-y-0;
}

.child-indent {
  @apply w-6 flex-shrink-0;
}

.children-count {
  @apply text-slate-500;
}

.sub-item-index {
  @apply text-slate-500;
}

.more-children {
  @apply p-3 text-center text-sm text-slate-500 bg-slate-50 border-t border-slate-200 flex items-center justify-center gap-2;
}

/* Expand animation */
.expand-enter-active,
.expand-leave-active {
  @apply transition-all duration-300 ease-in-out overflow-hidden;
}

.expand-enter-from,
.expand-leave-to {
  @apply opacity-0 max-h-0;
}

.expand-enter-to,
.expand-leave-from {
  @apply opacity-100 max-h-96;
}

.preview-section-title {
  @apply flex items-center gap-2 text-sm font-semibold text-slate-900 mb-3;
}

.card-preview-content {
  @apply space-y-2;
}

.preview-field {
  @apply flex gap-2 text-sm;
}

.field-label {
  @apply font-medium text-slate-600 min-w-0 flex-shrink-0;
}

.field-value {
  @apply text-slate-900;
}

.layer-badge {
  @apply px-2 py-1 rounded-full text-xs font-medium;
}

.layer-badge.layer-1 {
  @apply bg-blue-100 text-blue-700;
}

.layer-badge.layer-2 {
  @apply bg-purple-100 text-purple-700;
}

.image-badge {
  @apply px-2 py-1 bg-slate-100 text-slate-700 rounded-full text-xs font-medium flex items-center gap-1;
}

.preview-actions {
  @apply flex justify-end gap-3 pt-4 border-t border-slate-200;
}


.import-progress {
  @apply bg-blue-50 border border-blue-200 rounded-lg p-6 space-y-4;
}

.progress-header {
  @apply flex justify-between items-center;
}

.progress-title {
  @apply text-lg font-semibold text-blue-900;
}

.progress-percent {
  @apply text-sm font-medium text-blue-700;
}

.progress-bar {
  @apply h-3;
}

.progress-status {
  @apply text-center;
}

.status-text {
  @apply text-sm text-blue-700 font-medium;
}

.import-results {
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

.results-icon.error {
  @apply bg-red-100 text-red-600;
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
  @apply grid grid-cols-2 sm:grid-cols-4 gap-4;
}

.detail-item {
  @apply text-center;
}

.detail-label {
  @apply block text-xs text-slate-600 mb-1;
}

.detail-value {
  @apply block text-lg font-bold;
}

.detail-value.success {
  @apply text-blue-600;
}

.detail-value.info {
  @apply text-blue-600;
}

.detail-value.warning {
  @apply text-yellow-600;
}

.results-actions {
  @apply text-center pt-4 border-t border-slate-200;
}


.hidden {
  @apply sr-only;
}

/* PrimeVue overrides */
:deep(.p-progressbar) {
  @apply bg-blue-100;
}

:deep(.p-progressbar .p-progressbar-value) {
  @apply bg-blue-500;
}
</style>