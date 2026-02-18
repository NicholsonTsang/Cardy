<template>
  <div class="admin-template-import">
    <!-- Upload Section -->
    <div v-if="!previewData" class="upload-section">
      <div class="upload-info">
        <h3>{{ $t('templates.admin.zip_import_title') }}</h3>
        <p class="text-slate-600">{{ $t('templates.admin.import_card_export_description') }}</p>
      </div>

      <div
        class="upload-dropzone"
        :class="{ 'dragover': isDragging }"
        @dragover.prevent="isDragging = true"
        @dragleave.prevent="isDragging = false"
        @drop.prevent="handleDrop"
        @click="triggerFileInput"
      >
        <input
          ref="fileInput"
          type="file"
          accept=".zip"
          class="hidden"
          @change="handleFileSelect"
          multiple
        />
        <i class="pi pi-cloud-upload text-4xl text-slate-400 mb-3"></i>
        <p class="font-medium text-slate-700">{{ $t('templates.admin.drop_file_here') }}</p>
        <p class="text-sm text-slate-500">{{ $t('templates.admin.or_click_to_browse') }}</p>
        <p class="text-xs text-slate-400 mt-2">.zip</p>
      </div>

      <!-- Error Message -->
      <div v-if="errorMessage" class="error-message">
        <i class="pi pi-exclamation-circle"></i>
        <span>{{ errorMessage }}</span>
      </div>
    </div>

    <!-- Preview Section -->
    <div v-else class="preview-section">
      <div class="preview-header">
        <h3>{{ $t('templates.admin.preview') }}</h3>
        <p class="text-slate-600">
          {{ previewData.length }} {{ $t('templates.admin.templates') }}
          <span v-if="validTemplates.length !== previewData.length" class="text-amber-600">
            ({{ validTemplates.length }} {{ $t('templates.admin.valid') }})
          </span>
        </p>
      </div>

      <!-- Preview Table -->
      <DataTable
        :value="previewData"
        class="preview-table"
        responsiveLayout="scroll"
        :paginator="previewData.length > 10"
        :rows="10"
      >
        <Column field="name" :header="$t('templates.admin.name')" style="min-width: 200px">
          <template #body="{ data }">
            <div class="flex items-center gap-2">
              <span>{{ data.name }}</span>
              <Tag v-if="data.error" value="Invalid" severity="danger" class="text-xs" />
            </div>
          </template>
        </Column>

        <Column field="slug" :header="$t('templates.admin.slug')" style="min-width: 150px">
          <template #body="{ data }">
            <span class="text-slate-600 text-sm font-mono">{{ data.slug }}</span>
          </template>
        </Column>

        <Column field="scenario_category" :header="$t('templates.admin.scenario_category')" style="width: 140px">
          <template #body="{ data }">
            <div v-if="data.scenario_category" class="flex items-center gap-2">
              <Tag :value="data.scenario_category" severity="secondary" class="capitalize" />
            </div>
            <span v-else class="text-slate-400">—</span>
          </template>
        </Column>

        <Column field="content_mode" :header="$t('templates.admin.content_mode')" style="width: 120px">
          <template #body="{ data }">
            <Tag :value="formatContentMode(data.content_mode)" :severity="getModeSeverity(data.content_mode)" />
          </template>
        </Column>

        <Column field="is_grouped" :header="$t('templates.admin.grouped')" style="width: 80px">
          <template #body="{ data }">
            <i :class="data.is_grouped ? 'pi pi-check text-green-500' : 'pi pi-minus text-slate-300'"></i>
          </template>
        </Column>

        <Column field="item_count" :header="$t('templates.admin.items')" style="width: 80px">
            <template #body="{ data }">
                <div class="text-center">{{ data.item_count }}</div>
            </template>
        </Column>

        <Column field="original_language" header="Language" style="width: 100px">
          <template #body="{ data }">
            <span class="language-badge">
              {{ getLanguageFlag(data.original_language) }}
              {{ data.original_language }}
            </span>
          </template>
        </Column>

        <Column header="Translations" style="min-width: 150px">
          <template #body="{ data }">
            <div v-if="data.translation_languages.length > 0" class="translation-badges">
              <span
                v-for="lang in data.translation_languages.slice(0, 3)"
                :key="lang"
                class="translation-lang-badge"
              >
                {{ getLanguageFlag(lang) }} {{ lang }}
              </span>
              <span v-if="data.translation_languages.length > 3" class="translation-more-badge">
                +{{ data.translation_languages.length - 3 }}
              </span>
            </div>
            <span v-else class="text-slate-400 text-sm">—</span>
          </template>
        </Column>

        <Column :header="$t('templates.admin.status')" style="width: 100px">
          <template #body="{ data }">
            <Tag
              :value="data.error ? $t('templates.admin.invalid') : $t('templates.admin.valid')"
              :severity="data.error ? 'danger' : 'success'"
            />
          </template>
        </Column>
      </DataTable>

      <!-- Validation Errors -->
      <div v-if="invalidTemplates.length > 0" class="validation-errors">
        <h4><i class="pi pi-exclamation-triangle"></i> {{ $t('templates.admin.validation_errors') }}</h4>
        <ul>
          <li v-for="(item, index) in invalidTemplates" :key="index">
            <strong>{{ item.name }}:</strong> {{ item.error }}
          </li>
        </ul>
      </div>

      <!-- Action Buttons -->
      <div class="action-buttons">
        <Button
          :label="$t('common.cancel')"
          text
          @click="resetImport"
        />
        <Button
          :label="isImporting ? $t('templates.admin.importing') : $t('templates.admin.import_all')"
          icon="pi pi-download"
          :disabled="validTemplates.length === 0 || isImporting"
          :loading="isImporting"
          class="bg-blue-600 hover:bg-blue-700 text-white border-0"
          @click="handleBulkImport"
        />
      </div>
    </div>

    <!-- Import Progress -->
    <div v-if="isImporting" class="import-progress">
      <ProgressBar :value="importProgress" :showValue="true" />
      <p class="text-center text-sm text-slate-600 mt-2">
        {{ $t('templates.admin.importing_template') }} {{ currentImportIndex + 1 }} / {{ validTemplates.length }}
      </p>
    </div>

    <!-- Import Results -->
    <Dialog
      v-model:visible="showResults"
      :header="$t('templates.admin.import_complete')"
      :style="{ width: '90vw', maxWidth: '42rem' }"
      :modal="true"
    >
      <div class="results-content">
        <div v-if="importResults.failed === 0" class="success-message">
          <i class="pi pi-check-circle text-green-500 text-4xl mb-3"></i>
          <p class="font-medium">{{ $t('templates.admin.all_templates_imported') }}</p>
          <p class="text-sm text-slate-600">{{ importResults.created }} {{ $t('templates.admin.created') }}</p>
        </div>

        <div v-else class="partial-message">
          <i class="pi pi-exclamation-triangle text-amber-500 text-4xl mb-3"></i>
          <p class="font-medium">{{ $t('templates.admin.some_templates_failed') }}</p>
          <div class="results-stats">
            <span class="text-green-600">{{ importResults.created }} {{ $t('templates.admin.created') }}</span>
            <span class="text-red-600">{{ importResults.failed }} {{ $t('templates.admin.failed') }}</span>
          </div>

          <div v-if="importResults.errors.length > 0" class="failed-list">
            <p class="text-sm font-medium text-slate-700 mb-2">{{ $t('templates.admin.failed_items') }}</p>
            <ul>
              <li v-for="(err, index) in importResults.errors" :key="index" class="text-sm text-red-600">
                {{ err }}
              </li>
            </ul>
          </div>
        </div>
      </div>

      <template #footer>
        <Button
          :label="$t('templates.admin.import_another')"
          text
          @click="resetAndClose"
        />
        <Button
          :label="$t('common.done')"
          class="bg-blue-600 hover:bg-blue-700 text-white border-0"
          @click="finishImport"
        />
      </template>
    </Dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { useI18n } from 'vue-i18n'
import { useToast } from 'primevue/usetoast'
import { useTemplateLibraryStore } from '@/stores/templateLibrary'
import { getLanguageFlag } from '@/utils/formatters'
import { importProject } from '@/utils/projectArchive'
import type { ImportedCard } from '@/utils/projectArchive'

import Button from 'primevue/button'
import DataTable from 'primevue/datatable'
import Column from 'primevue/column'
import Tag from 'primevue/tag'
import ProgressBar from 'primevue/progressbar'
import Dialog from 'primevue/dialog'

interface PreviewTemplate {
  name: string
  slug: string
  description: string
  scenario_category: string | null
  content_mode: string
  is_grouped: boolean
  group_display: string
  billing_type: string
  original_language: string
  item_count: number
  translation_languages: string[]
  cardData: ImportedCard
  error?: string
}

const emit = defineEmits<{
  imported: []
}>()

const { t } = useI18n()
const toast = useToast()
const templateStore = useTemplateLibraryStore()

// State
const fileInput = ref<HTMLInputElement | null>(null)
const isDragging = ref(false)
const errorMessage = ref('')
const previewData = ref<PreviewTemplate[] | null>(null)
const isImporting = ref(false)
const currentImportIndex = ref(0)
const showResults = ref(false)
const importResults = ref({
  created: 0,
  failed: 0,
  errors: [] as string[]
})

// Computed
const validTemplates = computed(() => {
  if (!previewData.value) return []
  return previewData.value.filter(t => !t.error)
})

const invalidTemplates = computed(() => {
  if (!previewData.value) return []
  return previewData.value.filter(t => t.error)
})

const importProgress = computed(() => {
  if (!validTemplates.value.length) return 0
  return Math.round((currentImportIndex.value / validTemplates.value.length) * 100)
})

// Methods
function triggerFileInput() {
  fileInput.value?.click()
}

function handleDrop(event: DragEvent) {
  isDragging.value = false
  const files = event.dataTransfer?.files
  if (files?.length) {
    processFiles(Array.from(files))
  }
}

function handleFileSelect(event: Event) {
  const target = event.target as HTMLInputElement
  if (target.files?.length) {
    processFiles(Array.from(target.files))
  }
}

async function processFiles(files: File[]) {
  errorMessage.value = ''

  const validFiles = files.filter(f => f.name.endsWith('.zip'))

  if (validFiles.length === 0) {
    errorMessage.value = t('templates.admin.invalid_file_type')
    return
  }

  try {
    const result = await importProject(validFiles)

    if (result.cards.length === 0) {
      errorMessage.value = result.errors.join('; ') || t('templates.admin.invalid_card_export_format')
      return
    }

    const allPreviews: PreviewTemplate[] = []

    for (const imported of result.cards) {
      const preview = convertToPreviewTemplate(imported)
      allPreviews.push(preview)
    }

    if (allPreviews.length > 0) {
      previewData.value = allPreviews
    }
  } catch (e: any) {
    console.error('Error processing files:', e)
    errorMessage.value = t('templates.admin.parse_error')
  }
}

function convertToPreviewTemplate(imported: ImportedCard): PreviewTemplate {
  const card = imported.card
  const slug = generateSlug(card.name || 'untitled')

  let error: string | undefined
  if (!card.name) {
    error = 'Missing card name'
  }

  const translationLanguages = card.translations ? Object.keys(card.translations) : []

  return {
    name: card.name || 'Untitled',
    slug,
    description: card.description || '',
    scenario_category: null, // Admin can set after import
    content_mode: card.content_mode || 'list',
    is_grouped: card.is_grouped || false,
    group_display: card.group_display || 'expanded',
    billing_type: card.billing_type || 'digital',
    original_language: card.original_language || 'en',
    item_count: imported.contentItems.length,
    translation_languages: translationLanguages,
    cardData: imported,
    error
  }
}

function generateSlug(name: string): string {
  return name
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-|-$/g, '')
    .substring(0, 50)
}

function formatContentMode(mode: string): string {
  if (!mode) return 'List'
  const map: Record<string, string> = {
    'single': 'Single Item',
    'list': 'List View',
    'grid': 'Grid View',
    'cards': 'Cards View',
  }
  return map[mode] || mode.charAt(0).toUpperCase() + mode.slice(1)
}

function getModeSeverity(mode: string): string {
  const severities: Record<string, string> = {
    single: 'success',
    list: 'info',
    grid: 'warning',
    cards: 'help',
  }
  return severities[mode] || 'secondary'
}

async function handleBulkImport() {
  if (validTemplates.value.length === 0) return

  isImporting.value = true
  currentImportIndex.value = 0
  importResults.value = { created: 0, failed: 0, errors: [] }

  try {
    for (let i = 0; i < validTemplates.value.length; i++) {
      currentImportIndex.value = i
      const template = validTemplates.value[i]

      try {
        // Build card data object matching what bulkImportTemplate expects
        const imported = template.cardData
        const cardWithItems = {
          name: imported.card.name,
          description: imported.card.description,
          content_mode: imported.card.content_mode,
          is_grouped: imported.card.is_grouped,
          group_display: imported.card.group_display,
          billing_type: imported.card.billing_type,
          original_language: imported.card.original_language,
          conversation_ai_enabled: imported.card.conversation_ai_enabled,
          ai_instruction: imported.card.ai_instruction,
          ai_knowledge_base: imported.card.ai_knowledge_base,
          ai_welcome_general: imported.card.ai_welcome_general,
          ai_welcome_item: imported.card.ai_welcome_item,
          qr_code_position: imported.card.qr_code_position,
          translations_json: imported.card.translations ? JSON.stringify(imported.card.translations) : null,
          content_hash: imported.card.content_hash,
          contentItems: imported.contentItems.map(item => ({
            name: item.name,
            content: item.content,
            ai_knowledge_base: item.ai_knowledge_base,
            sort_order: item.sort_order,
            layer: item.parent_name === null ? 'Layer 1' : 'Layer 2',
            parent_item: item.parent_name,
            translations_json: item.translations ? JSON.stringify(item.translations) : null,
            content_hash: item.content_hash,
          })),
        }

        const result = await templateStore.bulkImportTemplate(
          cardWithItems,
          template.slug,
          template.scenario_category
        )

        if (result.success) {
          importResults.value.created++
        } else {
          importResults.value.failed++
          importResults.value.errors.push(`${template.name}: ${result.message}`)
        }
      } catch (e: any) {
        importResults.value.failed++
        importResults.value.errors.push(`${template.name}: ${e.message}`)
      }
    }
  } finally {
    isImporting.value = false
    showResults.value = true
  }
}

function resetImport() {
  previewData.value = null
  errorMessage.value = ''
  if (fileInput.value) {
    fileInput.value.value = ''
  }
}

function resetAndClose() {
  showResults.value = false
  resetImport()
}

function finishImport() {
  showResults.value = false
  resetImport()
  emit('imported')
}
</script>

<style scoped>
.admin-template-import { @apply space-y-6; }
.upload-section { @apply space-y-4; }
.upload-info h3 { @apply font-semibold text-slate-900 mb-1; }
.upload-dropzone { @apply flex flex-col items-center justify-center p-12 border-2 border-dashed border-slate-300 rounded-xl bg-slate-50 cursor-pointer transition-all; }
.upload-dropzone:hover, .upload-dropzone.dragover { @apply border-blue-400 bg-blue-50; }
.error-message { @apply flex items-center gap-2 p-3 bg-red-50 border border-red-200 rounded-lg text-red-700 text-sm; }
.preview-section { @apply space-y-4; }
.preview-header h3 { @apply font-semibold text-slate-900; }
.preview-table { @apply border border-slate-200 rounded-lg overflow-hidden; }
.validation-errors { @apply p-4 bg-amber-50 border border-amber-200 rounded-lg; }
.validation-errors h4 { @apply flex items-center gap-2 font-medium text-amber-800 mb-2; }
.validation-errors ul { @apply list-disc list-inside text-sm text-amber-700 space-y-1; }
.action-buttons { @apply flex justify-end gap-3 pt-4 border-t border-slate-200; }
.import-progress { @apply p-4 bg-slate-50 rounded-lg; }
.results-content { @apply text-center py-4; }
.success-message, .partial-message { @apply flex flex-col items-center; }
.results-stats { @apply flex gap-4 mt-2 text-sm; }
.failed-list { @apply mt-4 p-3 bg-red-50 rounded-lg text-left max-h-32 overflow-y-auto; }
.failed-list ul { @apply list-disc list-inside; }
.language-badge { @apply inline-flex items-center gap-1 px-2 py-1 bg-amber-50 text-amber-700 rounded-full text-xs font-medium; }
.translation-badges { @apply flex flex-wrap gap-1; }
.translation-lang-badge { @apply inline-flex items-center gap-1 px-2 py-0.5 bg-green-50 text-green-700 rounded-full text-xs; }
.translation-more-badge { @apply inline-flex items-center px-2 py-0.5 bg-green-100 text-green-700 rounded-full text-xs font-medium; }
</style>
