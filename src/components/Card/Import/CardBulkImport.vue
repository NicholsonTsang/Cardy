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

    <!-- Upload Action -->
    <div class="regular-import-content">
      <div class="quick-actions">
        <div class="action-grid">
          <div class="action-item import-action">
            <Button
              :label="$t('import.choose_zip_file')"
              icon="pi pi-file-import"
              @click="triggerFileInput"
              :disabled="importing"
              class="import-button bg-blue-600 hover:bg-blue-700 text-white border-0"
            />
            <span class="action-desc">{{ $t('import.upload_zip_desc') }}</span>
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

    <!-- File Upload Area -->
    <FileUploadZone
      ref="uploadZone"
      accept=".zip"
      :max-size-m-b="50"
      :multiple="true"
      :drop-title="$t('import.drop_zip_here')"
      :drop-subtitle="$t('import.or_click_to_browse_multiple')"
      :requirements="[
        $t('import.req_zip_format'),
        $t('import.req_max_size_zip'),
        $t('import.req_multiple_files'),
        $t('import.req_images_included')
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
            {{ importPreview.cards.length }} {{ importPreview.cards.length === 1 ? $t('import.card') : $t('import.cards') }}
          </span>
          <span class="stat-item">
            <i class="pi pi-list text-blue-600"></i>
            {{ totalContentItemsCount }} {{ $t('import.content_items') }}
          </span>
          <span class="stat-item">
            <i class="pi pi-image text-purple-600"></i>
            {{ totalImageCount }} {{ $t('import.embedded_images') }}
          </span>
        </div>
      </div>

      <!-- Multi-card Navigation -->
      <div v-if="importPreview.cards.length > 1" class="card-navigation">
        <button @click="currentCardIndex = Math.max(0, currentCardIndex - 1)" :disabled="currentCardIndex === 0" class="nav-btn">
          <i class="pi pi-chevron-left"></i>
        </button>
        <div class="nav-indicator">
          <span class="nav-current">{{ currentCardIndex + 1 }}</span>
          <span class="nav-separator">/</span>
          <span class="nav-total">{{ importPreview.cards.length }}</span>
          <span class="nav-label">{{ currentImported?.card.name || $t('import.unnamed_card') }}</span>
        </div>
        <button @click="currentCardIndex = Math.min(importPreview.cards.length - 1, currentCardIndex + 1)" :disabled="currentCardIndex >= importPreview.cards.length - 1" class="nav-btn">
          <i class="pi pi-chevron-right"></i>
        </button>
      </div>

      <!-- Validation Issues -->
      <div v-if="importPreview.errors.length > 0" class="validation-errors">
        <h5 class="errors-title"><i class="pi pi-times-circle"></i> {{ $t('import.validation_errors') }}</h5>
        <div class="errors-list">
          <div v-for="(error, index) in importPreview.errors.slice(0, 5)" :key="index" class="error-item">
            <i class="pi pi-times-circle error-icon"></i>
            <span class="error-text">{{ error }}</span>
          </div>
          <div v-if="importPreview.errors.length > 5" class="more-errors">
            +{{ importPreview.errors.length - 5 }} {{ $t('import.more_errors') }}
          </div>
        </div>
      </div>

      <div v-if="importPreview.warnings.length > 0" class="validation-warnings">
        <h5 class="warnings-title"><i class="pi pi-exclamation-triangle"></i> {{ $t('import.validation_warnings') }}</h5>
        <div class="warnings-list">
          <div v-for="(warning, index) in importPreview.warnings.slice(0, 3)" :key="index" class="warning-item">
            <i class="pi pi-exclamation-circle warning-icon"></i>
            <span class="warning-text">{{ warning }}</span>
          </div>
          <div v-if="importPreview.warnings.length > 3" class="more-warnings">
            +{{ importPreview.warnings.length - 3 }} {{ $t('import.more_warnings') }}
          </div>
        </div>
      </div>

      <!-- Card Preview -->
      <div v-if="currentImported" class="card-preview">
        <h5 class="preview-section-title"><i class="pi pi-id-card"></i> {{ $t('import.import_preview_card_info') }}</h5>
        <div class="card-preview-content">
          <div class="card-preview-header">
            <div class="card-image-preview">
              <img v-if="getCardImageUrl()" :src="getCardImageUrl()!" :alt="currentImported.card.name" class="card-preview-image" />
              <div v-else class="card-image-placeholder"><i class="pi pi-id-card text-2xl text-slate-400"></i></div>
            </div>
            <div class="card-details">
              <div class="preview-field">
                <span class="field-label">{{ $t('common.name') }}:</span>
                <span class="field-value">{{ currentImported.card.name }}</span>
              </div>
              <div class="preview-field">
                <span class="field-label">{{ $t('common.description') }}:</span>
                <span class="field-value">{{ truncateText(currentImported.card.description, 100) }}</span>
              </div>
              <div class="card-settings-badges">
                <span class="settings-badge badge-mode">
                  <i :class="getContentModeIcon(currentImported.card.content_mode)"></i>
                  {{ getContentModeLabel(currentImported.card.content_mode) }}
                </span>
                <span v-if="currentImported.card.is_grouped" class="settings-badge badge-grouped">
                  <i class="pi pi-sitemap"></i> {{ $t('templates.grouped') }}
                </span>
                <span class="settings-badge badge-billing">
                  <i class="pi pi-qrcode"></i>
                  {{ $t('templates.billing_digital') }}
                </span>
                <span v-if="currentImported.card.original_language && currentImported.card.original_language !== 'en'" class="settings-badge badge-language">
                  {{ getLanguageFlag(currentImported.card.original_language) }}
                  {{ currentImported.card.original_language }}
                </span>
                <span v-if="currentImported.card.conversation_ai_enabled" class="settings-badge badge-ai">
                  <i class="pi pi-sparkles"></i> {{ $t('import.ai_enabled') }}
                </span>
              </div>
              <div v-if="cardTranslationLanguages.length > 0" class="card-translation-badges">
                <span class="settings-badge badge-translation"><i class="pi pi-language"></i> {{ $t('templates.translations_included') }}</span>
                <span v-for="lang in cardTranslationLanguages.slice(0, 4)" :key="lang" class="settings-badge badge-translation-lang">
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
      <div v-if="organizedContentItems.length > 0" class="content-preview">
        <h5 class="preview-section-title">
          <i class="pi pi-list"></i>
          {{ $t('import.import_preview_content_structure', { count: currentImported?.contentItems.length || 0 }) }}
        </h5>
        <div class="hierarchical-content-preview">
          <div v-for="(item, index) in organizedContentItems" :key="item.name" class="preview-content-group">
            <div class="preview-parent-item">
              <div class="preview-item-header">
                <i
                  v-if="item.children && item.children.length > 0"
                  :class="expandedItems[index] ? 'pi pi-angle-down' : 'pi pi-angle-right'"
                  class="expand-icon"
                  @click="expandedItems[index] = !expandedItems[index]"
                ></i>
                <div v-else class="expand-icon-placeholder"></div>
                <div class="preview-thumbnail">
                  <img v-if="getItemImageUrl(item)" :src="getItemImageUrl(item)!" :alt="item.name" class="preview-image" />
                  <i class="pi pi-file text-slate-400" v-else></i>
                </div>
                <div class="preview-item-info">
                  <div class="preview-item-name">{{ item.name }}</div>
                  <div class="preview-item-meta">
                    <span class="layer-badge layer-1">{{ $t('import.layer_1') }}</span>
                    <span v-if="item.children && item.children.length > 0" class="children-count">
                      {{ $t('content.sub_items_count', { count: item.children.length }) }}
                    </span>
                  </div>
                </div>
              </div>
              <div class="preview-item-content">{{ truncateText(item.content, 100) }}</div>
            </div>
            <Transition name="expand">
              <div v-if="expandedItems[index] && item.children && item.children.length > 0" class="preview-children">
                <div v-for="(child, childIndex) in item.children.slice(0, 5)" :key="child.name" class="preview-child-item">
                  <div class="preview-item-header">
                    <div class="child-indent"></div>
                    <div class="preview-thumbnail preview-thumbnail-small">
                      <img v-if="getItemImageUrl(child)" :src="getItemImageUrl(child)!" :alt="child.name" class="preview-image" />
                      <i class="pi pi-file text-slate-400" v-else></i>
                    </div>
                    <div class="preview-item-info">
                      <div class="preview-item-name">{{ child.name }}</div>
                      <div class="preview-item-meta">
                        <span class="layer-badge layer-2">{{ $t('import.layer_2') }}</span>
                        <span class="sub-item-index">{{ $t('content.sub_item_index', { index: childIndex + 1 }) }}</span>
                      </div>
                    </div>
                  </div>
                  <div class="preview-item-content preview-child-content">{{ truncateText(child.content, 80) }}</div>
                </div>
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
        <div class="results-icon" :class="{ 'success': importResults.success, 'error': !importResults.success }">
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

<script setup lang="ts">
import { ref, computed, onUnmounted } from 'vue'
import { useI18n } from 'vue-i18n'
import { useToast } from 'primevue/usetoast'
import { importProject } from '@/utils/projectArchive'
import type { ImportResult, ImportedCard, ArchiveContentItem } from '@/utils/projectArchive'
import { applyCropParametersToImage, isValidCropParameters } from '@/utils/imageCropUtils'
import { getCardAspectRatioNumber, getContentAspectRatioNumber } from '@/utils/cardConfig'
import { supabase } from '@/lib/supabase'
import { useSubscriptionStore } from '@/stores/subscription'
import { getLanguageFlag } from '@/utils/formatters'
import Button from 'primevue/button'
import ProgressBar from 'primevue/progressbar'
import { Transition } from 'vue'
import FileUploadZone from '@/components/shared/FileUploadZone.vue'

const emit = defineEmits(['imported'])
const toast = useToast()
const { t } = useI18n()
const subscriptionStore = useSubscriptionStore()

const uploadZone = ref<InstanceType<typeof FileUploadZone> | null>(null)
const importing = ref(false)
const importPreview = ref<ImportResult | null>(null)
const importResults = ref<{ success: boolean; message: string; details?: Record<string, unknown> } | null>(null)
const importStatus = ref('')
const importProgress = ref(0)
const feedbackMessage = ref<{ severity: string; summary: string; detail: string } | null>(null)
const expandedItems = ref<boolean[]>([])
const currentCardIndex = ref(0)
const createdImageUrls = ref(new Set<string>())

// ─── Computed ─────────────────────────────────────────────────

const importProgressPercent = computed(() => Math.round(importProgress.value))

const confirmButtonLabel = computed(() => {
  if (importing.value) return t('import.importing')
  if (!importPreview.value) return t('import.confirm_import')
  if (importPreview.value.errors.length > 0) return t('import.cannot_import_with_errors', { errors: importPreview.value.errors.length })
  if (importPreview.value.warnings.length > 0) return t('import.import_with_warnings', { warnings: importPreview.value.warnings.length })
  return t('import.confirm_import')
})

const canExecuteImport = computed(() => {
  return importPreview.value && importPreview.value.isValid && importPreview.value.cards.length > 0 && !importing.value
})

const currentImported = computed<ImportedCard | null>(() => {
  return importPreview.value?.cards[currentCardIndex.value] ?? null
})

const totalContentItemsCount = computed(() => {
  if (!importPreview.value) return 0
  return importPreview.value.cards.reduce((sum, c) => sum + c.contentItems.length, 0)
})

const totalImageCount = computed(() => {
  if (!importPreview.value) return 0
  return importPreview.value.cards.reduce((sum, c) => sum + c.images.size, 0)
})

const cardTranslationLanguages = computed(() => {
  const translations = currentImported.value?.card.translations
  if (!translations) return []
  return Object.keys(translations)
})

interface OrganizedItem extends ArchiveContentItem {
  children?: ArchiveContentItem[]
}

const organizedContentItems = computed<OrganizedItem[]>(() => {
  const items = currentImported.value?.contentItems || []
  if (items.length === 0) return []

  const categories = items.filter(i => i.parent_name === null)
  const children = items.filter(i => i.parent_name !== null)

  const organized = categories.map(parent => ({
    ...parent,
    children: children.filter(c => c.parent_name === parent.name),
  }))

  if (expandedItems.value.length !== organized.length) {
    expandedItems.value = new Array(organized.length).fill(true)
  }

  return organized
})

// ─── Feedback ─────────────────────────────────────────────────

function showFeedback(severity: string, summary: string, detail: string, autoDismiss = true) {
  feedbackMessage.value = { severity, summary, detail }
  if (autoDismiss && severity !== 'error') {
    setTimeout(() => { feedbackMessage.value = null }, severity === 'success' ? 4000 : 6000)
  }
}
function clearFeedback() { feedbackMessage.value = null }

function getFeedbackIcon(severity: string) {
  const icons: Record<string, string> = { success: 'pi pi-check-circle', info: 'pi pi-info-circle', warn: 'pi pi-exclamation-triangle', error: 'pi pi-times-circle' }
  return icons[severity] || 'pi pi-info-circle'
}

// ─── File handling ────────────────────────────────────────────

function handleFileRemoved() {
  importPreview.value = null
  importResults.value = null
  expandedItems.value = []
  currentCardIndex.value = 0
}

function handleUploadError(message: string) {
  showFeedback('error', t('import.invalid_file_type'), message, false)
}

function triggerFileInput() { uploadZone.value?.triggerFileInput() }

function removeFile() {
  createdImageUrls.value.forEach(url => URL.revokeObjectURL(url))
  createdImageUrls.value.clear()
  uploadZone.value?.removeFile()
  handleFileRemoved()
}

async function processFile(file: File) {
  try {
    importStatus.value = t('import.analyzing_archive')
    const preview = await importProject(file)
    importPreview.value = preview

    if (preview.isValid) {
      const itemCount = preview.cards.reduce((s, c) => s + c.contentItems.length, 0)
      const imgCount = preview.cards.reduce((s, c) => s + c.images.size, 0)
      showFeedback('success', t('import.file_analyzed'),
        imgCount > 0
          ? t('import.file_analyzed_desc_with_images', { count: itemCount, images: imgCount })
          : t('import.file_analyzed_desc', { count: itemCount }),
        true)
    } else {
      showFeedback('warn', t('import.validation_issues'),
        t('import.validation_issues_desc', { errors: preview.errors.length }), false)
    }
  } catch (error: any) {
    showFeedback('error', t('import.file_analysis_failed'), error.message || t('import.failed_analyze_uploaded_file'), false)
    removeFile()
  }
}

async function processMultipleFiles(files: File[]) {
  try {
    importStatus.value = t('import.analyzing_multiple_files', { count: files.length })
    const preview = await importProject(files)
    importPreview.value = preview

    const totalCards = preview.cards.length
    const totalItems = preview.cards.reduce((s, c) => s + c.contentItems.length, 0)

    if (preview.isValid) {
      showFeedback('success', t('import.files_analyzed'),
        t('import.files_analyzed_desc', { cards: totalCards, items: totalItems }), true)
    } else {
      showFeedback('warn', t('import.validation_issues'),
        t('import.validation_issues_desc', { errors: preview.errors.length }), false)
    }
  } catch (error: any) {
    showFeedback('error', t('import.file_analysis_failed'), error.message || t('import.failed_analyze_uploaded_file'), false)
    removeFile()
  }
}

function cancelImport() { importPreview.value = null; importResults.value = null }

// ─── Image helpers ────────────────────────────────────────────

function getCardImageUrl(): string | null {
  const card = currentImported.value
  if (!card?.card.image) return null
  const file = card.images.get(card.card.image)
  if (!file) return null
  const url = URL.createObjectURL(file)
  createdImageUrls.value.add(url)
  return url
}

function getItemImageUrl(item: ArchiveContentItem): string | null {
  if (!item.image || !currentImported.value) return null
  const file = currentImported.value.images.get(item.image)
  if (!file) return null
  const url = URL.createObjectURL(file)
  createdImageUrls.value.add(url)
  return url
}

// ─── Upload image to Supabase ─────────────────────────────────

async function uploadImageFile(file: File, folder: string): Promise<string> {
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) throw new Error('User not authenticated')

  const ext = file.name.split('.').pop() || 'jpg'
  const fileName = `${Date.now()}_${Math.random().toString(36).substring(7)}.${ext}`
  const filePath = `${user.id}/${folder}/${fileName}`

  const { error } = await supabase.storage
    .from('userfiles')
    .upload(filePath, file, { contentType: file.type || 'image/jpeg', upsert: false })
  if (error) throw error

  const { data: { publicUrl } } = supabase.storage.from('userfiles').getPublicUrl(filePath)
  return publicUrl
}

/**
 * Upload an image with optional crop.
 * Returns { imageUrl, originalImageUrl, cropParams }.
 */
async function uploadWithCrop(
  imageFile: File,
  cropParams: Record<string, unknown> | null,
  folder: string,
  aspectRatioNumber: number
): Promise<{ imageUrl: string; originalImageUrl: string; cropParams: Record<string, unknown> | null }> {
  if (cropParams && isValidCropParameters(cropParams)) {
    try {
      const croppedFile = await applyCropParametersToImage(imageFile, cropParams, aspectRatioNumber)
      const originalImageUrl = await uploadImageFile(imageFile, folder)
      const imageUrl = await uploadImageFile(croppedFile, folder)
      return { imageUrl, originalImageUrl, cropParams }
    } catch {
      // Fallback: use original for both
      const url = await uploadImageFile(imageFile, folder)
      return { imageUrl: url, originalImageUrl: url, cropParams: null }
    }
  }
  const url = await uploadImageFile(imageFile, folder)
  return { imageUrl: url, originalImageUrl: url, cropParams: null }
}

// ─── Execute import ───────────────────────────────────────────

async function executeImport() {
  if (!importPreview.value || !canExecuteImport.value) return

  // Check subscription limit
  await subscriptionStore.fetchSubscription()
  const cardsToCreate = importPreview.value.cards.length
  const currentCount = subscriptionStore.experienceCount
  const limit = subscriptionStore.experienceLimit

  if (currentCount + cardsToCreate > limit) {
    const canCreate = Math.max(0, limit - currentCount)
    showFeedback('warn', t('subscription.limit_reached'),
      t('subscription.bulk_import_limit', { limit, current: currentCount, importing: cardsToCreate, canCreate }), false)
    toast.add({
      severity: 'info',
      summary: t('subscription.upgrade_available'),
      detail: t('subscription.upgrade_to_create_more', { limit, current: currentCount }),
      life: 8000,
    })
    return
  }

  // Check for duplicate card names
  const { data: existingCards, error: cardsError } = await supabase.rpc('get_user_cards')
  if (cardsError) {
    showFeedback('error', t('import.import_failed'), cardsError.message, false)
    return
  }

  const existingCardNames = new Set((existingCards || []).map((c: any) => c.name.toLowerCase()))
  const duplicates = importPreview.value.cards.filter(c =>
    existingCardNames.has(c.card.name.toLowerCase())
  )

  if (duplicates.length > 0) {
    const duplicateNames = duplicates.map(c => c.card.name).join(', ')
    showFeedback('warn', t('import.duplicate_cards_detected'),
      t('import.duplicate_cards_detail', { names: duplicateNames, count: duplicates.length }), false)
    toast.add({
      severity: 'warn',
      summary: t('import.duplicate_cards_warning'),
      detail: t('import.duplicate_cards_will_be_renamed'),
      life: 8000,
    })
    // Auto-rename duplicates by appending timestamp
    duplicates.forEach(dup => {
      const timestamp = new Date().toISOString().slice(0, 19).replace(/[-:]/g, '').replace('T', '_')
      dup.card.name = `${dup.card.name} (${timestamp})`
    })
  }

  importing.value = true
  importProgress.value = 0
  importStatus.value = t('import.starting_import')

  const results = { cardsCreated: 0, contentCreated: 0, imagesProcessed: 0, warnings: 0, errors: [] as string[] }
  const allCards = importPreview.value.cards
  const totalSteps = allCards.reduce((s, c) => s + 1 + c.contentItems.length, 0)
  let completedSteps = 0

  function advanceProgress() {
    completedSteps++
    importProgress.value = Math.min(95, (completedSteps / totalSteps) * 100)
  }

  try {
    for (const imported of allCards) {
      try {
        // --- Card image ---
        let cardImageUrl: string | null = null
        let cardOriginalImageUrl: string | null = null
        let cardCropParams: Record<string, unknown> | null = null

        if (imported.card.image) {
          const imgFile = imported.images.get(imported.card.image)
          if (imgFile) {
            importStatus.value = t('import.uploading_card_image')
            const res = await uploadWithCrop(imgFile, imported.card.crop_parameters, 'card-images', getCardAspectRatioNumber())
            cardImageUrl = res.imageUrl
            cardOriginalImageUrl = res.originalImageUrl
            cardCropParams = res.cropParams
            results.imagesProcessed++
          }
        }

        // --- Create card ---
        importStatus.value = t('import.status_creating_card')

        const { data: cardId, error: cardErr } = await supabase.rpc('create_card', {
          p_name: imported.card.name,
          p_description: imported.card.description,
          p_ai_instruction: imported.card.ai_instruction,
          p_ai_knowledge_base: imported.card.ai_knowledge_base,
          p_ai_welcome_general: imported.card.ai_welcome_general,
          p_ai_welcome_item: imported.card.ai_welcome_item,
          p_conversation_ai_enabled: imported.card.conversation_ai_enabled,
          p_qr_code_position: imported.card.qr_code_position,
          p_image_url: cardImageUrl,
          p_original_image_url: cardOriginalImageUrl,
          p_crop_parameters: cardCropParams,
          p_original_language: imported.card.original_language,
          p_content_hash: imported.card.content_hash,
          p_translations: imported.card.translations,
          p_content_mode: imported.card.content_mode,
          p_is_grouped: imported.card.is_grouped,
          p_group_display: imported.card.group_display,
          p_billing_type: imported.card.billing_type,
          p_default_daily_session_limit: imported.card.default_daily_session_limit ?? 500,
          p_metadata: imported.card.metadata || {},
        })

        if (cardErr) throw cardErr
        results.cardsCreated++
        advanceProgress()

        // --- Content items ---
        const parentMap = new Map<string, string>() // name → created id
        const categories = imported.contentItems.filter(i => i.parent_name === null)
        const children = imported.contentItems.filter(i => i.parent_name !== null)

        // Create categories (L1) first
        for (const item of categories) {
          try {
            const { imageUrl, originalImageUrl, cropParams } = await processContentImage(item, imported, results)
            importStatus.value = t('import.creating_content_item', { name: item.name })

            const { data: itemId, error: itemErr } = await supabase.rpc('create_content_item', {
              p_card_id: cardId,
              p_parent_id: null,
              p_name: item.name,
              p_content: item.content,
              p_ai_knowledge_base: item.ai_knowledge_base,
              p_image_url: imageUrl,
              p_original_image_url: originalImageUrl,
              p_crop_parameters: cropParams,
              p_content_hash: item.content_hash,
              p_translations: item.translations,
            })

            if (itemErr) throw itemErr
            parentMap.set(item.name, itemId)
            results.contentCreated++
          } catch (err: any) {
            results.errors.push(`"${item.name}": ${err.message}`)
          }
          advanceProgress()
        }

        // Create children (L2)
        for (const item of children) {
          try {
            const parentId = parentMap.get(item.parent_name!) || null
            if (!parentId) {
              results.warnings++
              results.errors.push(`Parent "${item.parent_name}" not found for "${item.name}", skipping.`)
              advanceProgress()
              continue
            }

            const { imageUrl, originalImageUrl, cropParams } = await processContentImage(item, imported, results)
            importStatus.value = t('import.creating_sub_item', { name: item.name })

            const { error: itemErr } = await supabase.rpc('create_content_item', {
              p_card_id: cardId,
              p_parent_id: parentId,
              p_name: item.name,
              p_content: item.content,
              p_ai_knowledge_base: item.ai_knowledge_base,
              p_image_url: imageUrl,
              p_original_image_url: originalImageUrl,
              p_crop_parameters: cropParams,
              p_content_hash: item.content_hash,
              p_translations: item.translations,
            })

            if (itemErr) throw itemErr
            results.contentCreated++
          } catch (err: any) {
            results.errors.push(`"${item.name}": ${err.message}`)
          }
          advanceProgress()
        }

        // Recalculate translation hashes for the new card
        try {
          importStatus.value = t('import.status_finalizing')
          await supabase.rpc('recalculate_all_translation_hashes', { p_card_id: cardId })
        } catch {
          results.warnings++
        }
      } catch (err: any) {
        results.errors.push(`Card "${imported.card.name}": ${err.message}`)
      }
    }

    importProgress.value = 100
    importStatus.value = t('import.import_completed')
    results.warnings += importPreview.value.warnings.length

    const success = results.errors.length === 0
    importResults.value = {
      success,
      message: success
        ? `Successfully imported ${results.cardsCreated} card(s) and ${results.contentCreated} content items${results.imagesProcessed > 0 ? ` with ${results.imagesProcessed} images` : ''}`
        : `Import completed with ${results.errors.length} error(s)`,
      details: results,
    }

    importPreview.value = null
    emit('imported', importResults.value)

    showFeedback(
      success ? 'success' : 'warn',
      success ? t('import.import_successful') : t('import.import_completed_with_issues'),
      importResults.value!.message,
      true,
    )
  } catch (error: any) {
    importResults.value = { success: false, message: error.message || t('import.failed_unknown_error'), details: { errors: 1 } }
    showFeedback('error', t('import.import_failed'), error.message || t('import.failed_import_data'), false)
  } finally {
    importing.value = false
  }
}

async function processContentImage(
  item: ArchiveContentItem,
  imported: ImportedCard,
  results: { imagesProcessed: number; warnings: number; errors: string[] }
) {
  let imageUrl: string | null = null
  let originalImageUrl: string | null = null
  let cropParams: Record<string, unknown> | null = null

  if (item.image) {
    const imgFile = imported.images.get(item.image)
    if (imgFile) {
      try {
        const res = await uploadWithCrop(imgFile, item.crop_parameters, 'content-item-images', getContentAspectRatioNumber())
        imageUrl = res.imageUrl
        originalImageUrl = res.originalImageUrl
        cropParams = res.cropParams
        results.imagesProcessed++
      } catch (err: any) {
        results.warnings++
        results.errors.push(`Image upload failed for "${item.name}": ${err.message}`)
      }
    } else {
      results.warnings++
      results.errors.push(`Image file not found in archive for "${item.name}": ${item.image}`)
    }
  }

  return { imageUrl, originalImageUrl, cropParams }
}

// ─── Utilities ────────────────────────────────────────────────

function truncateText(text: string | undefined | null, maxLength: number) {
  if (!text) return ''
  return text.length <= maxLength ? text : text.substring(0, maxLength) + '...'
}

function getContentModeIcon(mode: string) {
  const icons: Record<string, string> = { single: 'pi pi-file', list: 'pi pi-list', grid: 'pi pi-th-large', cards: 'pi pi-clone' }
  return icons[mode] || 'pi pi-file'
}

function getContentModeLabel(mode: string) {
  const labels: Record<string, string> = {
    single: t('templates.mode_single'), list: t('templates.mode_list'),
    grid: t('templates.mode_grid'), cards: t('templates.mode_cards'),
  }
  return labels[mode] || mode
}

function resetImport() {
  removeFile()
  importResults.value = null
  expandedItems.value = []
}

onUnmounted(() => {
  createdImageUrls.value.forEach(url => URL.revokeObjectURL(url))
  createdImageUrls.value.clear()
})
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

.feedback-success { @apply bg-emerald-50 border-emerald-500; }
.feedback-info { @apply bg-blue-50 border-blue-500; }
.feedback-warn { @apply bg-amber-50 border-amber-500; }
.feedback-error { @apply bg-red-50 border-red-500; }

.feedback-content { @apply flex items-start gap-3; }
.feedback-icon { @apply flex-shrink-0 text-2xl mt-0.5; }
.feedback-success .feedback-icon { @apply text-emerald-600; }
.feedback-info .feedback-icon { @apply text-blue-600; }
.feedback-warn .feedback-icon { @apply text-amber-600; }
.feedback-error .feedback-icon { @apply text-red-600; }
.feedback-text { @apply flex-1; }
.feedback-title { @apply font-semibold text-base mb-1; }
.feedback-success .feedback-title { @apply text-emerald-900; }
.feedback-info .feedback-title { @apply text-blue-900; }
.feedback-warn .feedback-title { @apply text-amber-900; }
.feedback-error .feedback-title { @apply text-red-900; }
.feedback-detail { @apply text-sm leading-relaxed; }
.feedback-success .feedback-detail { @apply text-emerald-700; }
.feedback-info .feedback-detail { @apply text-blue-700; }
.feedback-warn .feedback-detail { @apply text-amber-700; }
.feedback-error .feedback-detail { @apply text-red-700; }
.feedback-close { @apply flex-shrink-0 mt-1; }

@keyframes fadeIn {
  from { opacity: 0; transform: translateY(-10px); }
  to { opacity: 1; transform: translateY(0); }
}
.animate-fadeIn { animation: fadeIn 0.3s ease-out; }

.regular-import-content { @apply space-y-6; }
.quick-actions { @apply bg-white border border-slate-200 rounded-lg p-4; }
.action-grid { @apply flex justify-center; }
.action-item { @apply text-center space-y-2; }
.import-button { @apply w-full; }
.action-desc { @apply text-xs text-slate-500 block; }

.import-preview { @apply bg-white border border-slate-200 rounded-lg p-6 space-y-4; }
.preview-header { @apply flex items-center justify-between; }
.preview-title { @apply flex items-center gap-2 text-lg font-semibold text-slate-900; }
.preview-icon { @apply text-blue-500; }
.preview-stats { @apply flex gap-4; }
.stat-item { @apply flex items-center gap-1 text-sm font-medium; }

.card-navigation { @apply flex items-center justify-center gap-3 py-3 px-4 bg-slate-100 rounded-lg my-4; }
.nav-btn { @apply w-8 h-8 flex items-center justify-center rounded-full bg-white border border-slate-200 text-slate-600 hover:bg-blue-50 hover:border-blue-300 hover:text-blue-600 transition-all disabled:opacity-40 disabled:cursor-not-allowed; }
.nav-indicator { @apply flex items-center gap-2; }
.nav-current { @apply text-lg font-bold text-blue-600; }
.nav-separator { @apply text-slate-400; }
.nav-total { @apply text-lg font-medium text-slate-600; }
.nav-label { @apply text-sm text-slate-500 max-w-32 truncate ml-2; }

.validation-errors { @apply bg-red-50 border border-red-200 rounded-lg p-4; }
.errors-title { @apply flex items-center gap-2 text-sm font-semibold text-red-800 mb-3; }
.errors-list { @apply space-y-2; }
.error-item { @apply flex items-start gap-2 text-sm; }
.error-icon { @apply text-red-600 mt-0.5 flex-shrink-0; }
.error-text { @apply text-red-800; }
.more-errors { @apply text-xs text-red-700 font-medium; }

.validation-warnings { @apply bg-yellow-50 border border-yellow-200 rounded-lg p-4; }
.warnings-title { @apply flex items-center gap-2 text-sm font-semibold text-yellow-800 mb-3; }
.warnings-list { @apply space-y-2; }
.warning-item { @apply flex items-start gap-2 text-sm; }
.warning-icon { @apply text-yellow-600 mt-0.5 flex-shrink-0; }
.warning-text { @apply text-yellow-800; }
.more-warnings { @apply text-xs text-yellow-700 font-medium; }

.card-preview, .content-preview { @apply bg-slate-50 rounded-lg p-4; }
.card-preview-header { @apply flex gap-4; }
.card-image-preview { @apply flex-shrink-0; }
.card-preview-image { @apply w-16 h-24 object-cover rounded-lg border border-slate-200; }
.card-image-placeholder { @apply w-16 h-24 bg-slate-100 rounded-lg border border-slate-200 flex items-center justify-center; }
.card-details { @apply flex-1 min-w-0; }
.card-settings-badges { @apply flex flex-wrap gap-2 mt-3; }
.settings-badge { @apply inline-flex items-center gap-1 px-2 py-1 rounded-full text-xs font-medium; }
.badge-mode { @apply bg-blue-100 text-blue-700; }
.badge-grouped { @apply bg-purple-100 text-purple-700; }
.badge-billing { @apply bg-slate-100 text-slate-700; }
.badge-language { @apply bg-amber-100 text-amber-700; }
.badge-ai { @apply bg-emerald-100 text-emerald-700; }
.card-translation-badges { @apply flex flex-wrap gap-2 mt-2; }
.badge-translation { @apply bg-green-100 text-green-700; }
.badge-translation-lang { @apply bg-green-50 text-green-600 text-xs; }
.badge-translation-more { @apply bg-green-100 text-green-700 text-xs; }

.hierarchical-content-preview { @apply space-y-3; }
.preview-content-group { @apply bg-white rounded-lg border border-slate-200 overflow-hidden; }
.preview-parent-item { @apply p-4; }
.preview-child-item { @apply p-3 bg-slate-50; }
.preview-item-header { @apply flex items-center gap-3 mb-2; }
.expand-icon { @apply text-slate-600 cursor-pointer hover:text-blue-600 transition-colors w-4 flex-shrink-0; }
.expand-icon-placeholder { @apply w-4 flex-shrink-0; }
.preview-thumbnail { @apply w-10 h-10 bg-slate-100 rounded-lg border border-slate-200 flex items-center justify-center text-slate-400 flex-shrink-0 overflow-hidden; }
.preview-thumbnail-small { @apply w-8 h-8; }
.preview-image { @apply w-full h-full object-cover; }
.preview-item-info { @apply flex-1 min-w-0; }
.preview-item-name { @apply font-medium text-slate-900 truncate; }
.preview-item-meta { @apply flex items-center gap-2 mt-1 text-sm; }
.preview-item-content { @apply text-sm text-slate-600 ml-16; }
.preview-child-content { @apply ml-12; }
.preview-children { @apply border-t border-slate-200 space-y-0; }
.child-indent { @apply w-6 flex-shrink-0; }
.children-count { @apply text-slate-500; }
.sub-item-index { @apply text-slate-500; }
.more-children { @apply p-3 text-center text-sm text-slate-500 bg-slate-50 border-t border-slate-200 flex items-center justify-center gap-2; }

.expand-enter-active, .expand-leave-active { @apply transition-all duration-300 ease-in-out overflow-hidden; }
.expand-enter-from, .expand-leave-to { @apply opacity-0 max-h-0; }
.expand-enter-to, .expand-leave-from { @apply opacity-100 max-h-96; }

.preview-section-title { @apply flex items-center gap-2 text-sm font-semibold text-slate-900 mb-3; }
.card-preview-content { @apply space-y-2; }
.preview-field { @apply flex gap-2 text-sm; }
.field-label { @apply font-medium text-slate-600 min-w-0 flex-shrink-0; }
.field-value { @apply text-slate-900; }
.layer-badge { @apply px-2 py-1 rounded-full text-xs font-medium; }
.layer-badge.layer-1 { @apply bg-blue-100 text-blue-700; }
.layer-badge.layer-2 { @apply bg-purple-100 text-purple-700; }
.preview-actions { @apply flex justify-end gap-3 pt-4 border-t border-slate-200; }

.import-progress { @apply bg-blue-50 border border-blue-200 rounded-lg p-6 space-y-4; }
.progress-header { @apply flex justify-between items-center; }
.progress-title { @apply text-lg font-semibold text-blue-900; }
.progress-percent { @apply text-sm font-medium text-blue-700; }
.progress-bar { @apply h-3; }
.progress-status { @apply text-center; }
.status-text { @apply text-sm text-blue-700 font-medium; }

.import-results { @apply bg-white border border-slate-200 rounded-lg p-6 space-y-4; }
.results-header { @apply flex items-start gap-4; }
.results-icon { @apply w-12 h-12 rounded-full flex items-center justify-center text-xl flex-shrink-0; }
.results-icon.success { @apply bg-blue-100 text-blue-600; }
.results-icon.error { @apply bg-red-100 text-red-600; }
.results-title { @apply text-lg font-semibold text-slate-900 mb-1; }
.results-summary { @apply text-slate-600; }
.results-details { @apply bg-slate-50 rounded-lg p-4; }
.detail-grid { @apply grid grid-cols-2 sm:grid-cols-4 gap-4; }
.detail-item { @apply text-center; }
.detail-label { @apply block text-xs text-slate-600 mb-1; }
.detail-value { @apply block text-lg font-bold; }
.detail-value.success { @apply text-blue-600; }
.detail-value.info { @apply text-blue-600; }
.detail-value.warning { @apply text-yellow-600; }
.results-actions { @apply text-center pt-4 border-t border-slate-200; }

/* Mobile responsive */
@media (max-width: 768px) {
  .card-bulk-import { @apply space-y-4; }
  .import-preview { @apply p-4 space-y-3; }
  .preview-header { @apply flex-col gap-3 items-start; }
  .preview-stats { @apply flex-wrap gap-2; }
  .card-preview-header { @apply flex-col gap-3; }
  .card-image-preview { @apply self-center; }
  .preview-item-content { @apply ml-10 text-xs; }
  .preview-child-content { @apply ml-6 text-xs; }
  .preview-thumbnail { @apply w-8 h-8; }
  .preview-thumbnail-small { @apply w-6 h-6; }
  .preview-actions { @apply flex-col gap-3; }
  .detail-grid { @apply grid-cols-2 gap-3; }
  .import-header { @apply p-4; }
  .header-content { @apply gap-3; }
  .import-title { @apply text-lg; }
  .import-description { @apply text-xs; }
}

:deep(.p-progressbar) { @apply bg-blue-100; }
:deep(.p-progressbar .p-progressbar-value) { @apply bg-blue-500; }
</style>
