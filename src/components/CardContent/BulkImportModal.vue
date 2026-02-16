<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import { useToast } from 'primevue/usetoast'
import Papa from 'papaparse'
import * as XLSX from 'xlsx'
import PDialog from 'primevue/dialog'
import Button from 'primevue/button'
import Select from 'primevue/select'
import ProgressBar from 'primevue/progressbar'
import DataTable from 'primevue/datatable'
import Column from 'primevue/column'
import FileUploadZone from '@/components/shared/FileUploadZone.vue'
import { supabase } from '@/lib/supabase'

// --------------- Types ---------------
interface ColumnMapping {
  csvColumn: string
  field: string
}

interface ImportError {
  row: number
  field: string
  message: string
}

interface ImportSummary {
  total: number
  succeeded: number
  failed: number
  errors: ImportError[]
}

// --------------- Props & Emits ---------------
const props = defineProps<{
  visible: boolean
  cardId: string
  isGrouped: boolean
  categories: Array<{ id: string; name: string }>
}>()

const emit = defineEmits<{
  'update:visible': [value: boolean]
  'import-complete': []
}>()

// --------------- Composables ---------------
const { t } = useI18n()
const toast = useToast()

// --------------- Constants ---------------
const BATCH_SIZE = 100

const TARGET_FIELDS = computed(() => [
  { label: t('bulk_import.field_skip'), value: '__skip__' },
  { label: t('bulk_import.field_title'), value: 'name', required: true },
  { label: t('bulk_import.field_content'), value: 'content' },
  { label: t('bulk_import.field_image_url'), value: 'image_url' },
  { label: t('bulk_import.field_ai_knowledge'), value: 'ai_knowledge_base' },
])

// --------------- State ---------------
type Step = 'upload' | 'mapping' | 'preview' | 'importing' | 'summary'
const currentStep = ref<Step>('upload')

// Upload state
const uploadZoneRef = ref<InstanceType<typeof FileUploadZone> | null>(null)
const rawData = ref<string[][]>([])
const headers = ref<string[]>([])
const fileName = ref('')

// Mapping state
const columnMappings = ref<ColumnMapping[]>([])
const selectedCategoryId = ref<string | null>(null)

// Preview state
const PREVIEW_ROWS = 10

// Import state
const importProgress = ref(0)
const importSummary = ref<ImportSummary | null>(null)

// --------------- Computed ---------------
const dialogVisible = computed({
  get: () => props.visible,
  set: (value: boolean) => emit('update:visible', value)
})

const previewRows = computed(() => {
  if (rawData.value.length === 0 || columnMappings.value.length === 0) return []

  const mappedFields = columnMappings.value.filter(m => m.field !== '__skip__')
  if (mappedFields.length === 0) return []

  // rawData[0] is the header row, data starts from [1]
  const dataRows = rawData.value.slice(1, PREVIEW_ROWS + 1)

  return dataRows.map((row, rowIndex) => {
    const obj: Record<string, string> = { __row: String(rowIndex + 2) }
    mappedFields.forEach(mapping => {
      const colIndex = headers.value.indexOf(mapping.csvColumn)
      if (colIndex >= 0) {
        obj[mapping.field] = row[colIndex] || ''
      }
    })
    return obj
  })
})

const previewColumns = computed(() => {
  return columnMappings.value
    .filter(m => m.field !== '__skip__')
    .map(m => ({
      field: m.field,
      header: TARGET_FIELDS.value.find(f => f.value === m.field)?.label || m.field
    }))
})

const hasNameMapping = computed(() => {
  return columnMappings.value.some(m => m.field === 'name')
})

const totalDataRows = computed(() => {
  // rawData[0] is the header, rest is data
  return Math.max(0, rawData.value.length - 1)
})

const validationErrors = computed((): string[] => {
  const errors: string[] = []
  if (!hasNameMapping.value) {
    errors.push(t('bulk_import.error_name_required'))
  }
  // Check for duplicate field mappings (excluding __skip__)
  const mappedFields = columnMappings.value
    .map(m => m.field)
    .filter(f => f !== '__skip__')
  const duplicates = mappedFields.filter((f, i) => mappedFields.indexOf(f) !== i)
  if (duplicates.length > 0) {
    errors.push(t('bulk_import.error_duplicate_mapping'))
  }
  return errors
})

const canProceedToPreview = computed(() => {
  return hasNameMapping.value && validationErrors.value.length === 0
})

const stepTitle = computed(() => {
  switch (currentStep.value) {
    case 'upload': return t('bulk_import.step_upload')
    case 'mapping': return t('bulk_import.step_mapping')
    case 'preview': return t('bulk_import.step_preview')
    case 'importing': return t('bulk_import.step_importing')
    case 'summary': return t('bulk_import.step_summary')
    default: return ''
  }
})

// --------------- Methods ---------------

// Download template
function downloadTemplate() {
  const templateData = [
    ['title', 'content', 'image_url', 'ai_knowledge_base'],
    ['Example Item 1', 'This is the content for item 1', 'https://example.com/image1.jpg', 'Additional context for AI'],
    ['Example Item 2', 'This is the content for item 2', '', 'More AI knowledge'],
    ['Example Item 3', 'This is the content for item 3', 'https://example.com/image3.jpg', ''],
  ]

  // Create Excel workbook
  const wb = XLSX.utils.book_new()
  const ws = XLSX.utils.aoa_to_sheet(templateData)

  // Set column widths
  ws['!cols'] = [
    { wch: 20 }, // title
    { wch: 40 }, // content
    { wch: 30 }, // image_url
    { wch: 30 }, // ai_knowledge_base
  ]

  XLSX.utils.book_append_sheet(wb, ws, 'Template')

  // Download as Excel file
  XLSX.writeFile(wb, 'bulk_import_template.xlsx')

  toast.add({
    severity: 'success',
    summary: t('bulk_import.template_downloaded'),
    detail: t('bulk_import.template_downloaded_detail'),
    life: 3000
  })
}

// File Parsing (CSV and Excel)
function handleFileSelected(file: File) {
  fileName.value = file.name
  const fileExt = file.name.split('.').pop()?.toLowerCase()

  if (fileExt === 'csv') {
    // Parse CSV with PapaParse
    Papa.parse(file, {
      complete: (results) => {
        if (results.errors.length > 0) {
          toast.add({
            severity: 'error',
            summary: t('bulk_import.parse_error'),
            detail: results.errors[0].message,
            life: 5000
          })
          return
        }

        processData(results.data as string[][])
      },
      skipEmptyLines: true,
      encoding: 'UTF-8'
    })
  } else if (fileExt === 'xlsx' || fileExt === 'xls') {
    // Parse Excel with SheetJS
    const reader = new FileReader()
    reader.onload = (e) => {
      try {
        const data = new Uint8Array(e.target?.result as ArrayBuffer)
        const workbook = XLSX.read(data, { type: 'array' })

        // Get first sheet
        const firstSheetName = workbook.SheetNames[0]
        const worksheet = workbook.Sheets[firstSheetName]

        // Convert to array of arrays
        const jsonData = XLSX.utils.sheet_to_json(worksheet, { header: 1 }) as string[][]

        processData(jsonData)
      } catch (error) {
        toast.add({
          severity: 'error',
          summary: t('bulk_import.parse_error'),
          detail: error instanceof Error ? error.message : 'Failed to parse Excel file',
          life: 5000
        })
      }
    }
    reader.readAsArrayBuffer(file)
  } else {
    toast.add({
      severity: 'error',
      summary: t('bulk_import.invalid_file_type'),
      detail: t('bulk_import.invalid_file_type_detail'),
      life: 5000
    })
  }
}

function processData(data: string[][]) {
  // Filter out completely empty rows
  const filteredData = data.filter(row =>
    row.some(cell => cell && String(cell).trim() !== '')
  )

  if (filteredData.length < 2) {
    toast.add({
      severity: 'warn',
      summary: t('bulk_import.no_data'),
      detail: t('bulk_import.no_data_detail'),
      life: 5000
    })
    return
  }

  rawData.value = filteredData.map(row => row.map(cell => String(cell || '')))
  headers.value = filteredData[0].map(h => String(h).trim())

  // Auto-map columns based on common names
  autoMapColumns()
  currentStep.value = 'mapping'
}

function autoMapColumns() {
  const fieldAliases: Record<string, string[]> = {
    name: ['title', 'name', 'item name', 'content name', 'product name', 'item_name', 'content_item_name', 'heading'],
    content: ['content', 'description', 'body', 'text', 'detail', 'details', 'content_item_content', 'desc'],
    image_url: ['image', 'image_url', 'photo', 'picture', 'img', 'thumbnail', 'content_item_image_url', 'url_image'],
    ai_knowledge_base: ['ai_knowledge', 'ai_knowledge_base', 'knowledge', 'ai_context', 'context', 'ai knowledge'],
  }

  columnMappings.value = headers.value.map(header => {
    const headerLower = header.toLowerCase().trim()

    // Find matching field
    let matchedField = '__skip__'
    for (const [field, aliases] of Object.entries(fieldAliases)) {
      if (aliases.some(alias => headerLower === alias || headerLower.includes(alias))) {
        matchedField = field
        break
      }
    }

    return {
      csvColumn: header,
      field: matchedField
    }
  })
}

function handleFileRemoved() {
  resetState()
}

function handleUploadError(message: string) {
  toast.add({
    severity: 'error',
    summary: t('common.error'),
    detail: message,
    life: 5000
  })
}

// Navigation
function goToPreview() {
  if (!canProceedToPreview.value) return
  currentStep.value = 'preview'
}

function goBackToMapping() {
  currentStep.value = 'mapping'
}

function goBackToUpload() {
  resetState()
  currentStep.value = 'upload'
}

// Import execution
async function startImport() {
  currentStep.value = 'importing'
  importProgress.value = 0

  const mappedFields = columnMappings.value.filter(m => m.field !== '__skip__')
  const dataRows = rawData.value.slice(1) // Skip header row

  const items: Array<Record<string, string>> = []
  const errors: ImportError[] = []

  // Build item objects from mapped data
  dataRows.forEach((row, rowIndex) => {
    const item: Record<string, string> = {}
    let hasName = false

    mappedFields.forEach(mapping => {
      const colIndex = headers.value.indexOf(mapping.csvColumn)
      if (colIndex >= 0) {
        const value = (row[colIndex] || '').trim()
        if (mapping.field === 'name') {
          if (!value) {
            errors.push({
              row: rowIndex + 2, // +2 for header row and 1-based index
              field: 'name',
              message: t('bulk_import.error_empty_name')
            })
            return
          }
          hasName = true
        }
        item[mapping.field] = value
      }
    })

    if (hasName) {
      items.push(item)
    }
  })

  if (items.length === 0) {
    importSummary.value = {
      total: dataRows.length,
      succeeded: 0,
      failed: dataRows.length,
      errors
    }
    currentStep.value = 'summary'
    return
  }

  // Process in batches
  let succeeded = 0
  let failed = 0
  const totalBatches = Math.ceil(items.length / BATCH_SIZE)

  for (let batchIndex = 0; batchIndex < totalBatches; batchIndex++) {
    const batchStart = batchIndex * BATCH_SIZE
    const batchEnd = Math.min(batchStart + BATCH_SIZE, items.length)
    const batchItems = items.slice(batchStart, batchEnd)

    // Format items for the RPC call
    const rpcItems = batchItems.map(item => ({
      name: item.name,
      content: item.content || '',
      image_url: item.image_url || null,
      ai_knowledge_base: item.ai_knowledge_base || '',
      parent_id: (props.isGrouped && selectedCategoryId.value) ? selectedCategoryId.value : null
    }))

    try {
      const { data, error } = await supabase.rpc('bulk_create_content_items', {
        p_card_id: props.cardId,
        p_items: rpcItems
      })

      if (error) {
        throw error
      }

      if (data?.success) {
        succeeded += data.count || batchItems.length
      } else {
        failed += batchItems.length
        errors.push({
          row: batchStart + 2,
          field: '',
          message: t('bulk_import.error_batch_failed', { start: batchStart + 1, end: batchEnd })
        })
      }
    } catch (err: any) {
      failed += batchItems.length
      errors.push({
        row: batchStart + 2,
        field: '',
        message: err.message || t('bulk_import.error_batch_failed', { start: batchStart + 1, end: batchEnd })
      })
    }

    // Update progress
    importProgress.value = Math.round(((batchIndex + 1) / totalBatches) * 100)
  }

  importSummary.value = {
    total: dataRows.length,
    succeeded,
    failed: failed + errors.filter(e => e.field === 'name').length,
    errors
  }

  currentStep.value = 'summary'
}

function handleClose() {
  if (currentStep.value === 'summary' && importSummary.value && importSummary.value.succeeded > 0) {
    emit('import-complete')
  }
  dialogVisible.value = false
}

function handleImportAnother() {
  resetState()
  currentStep.value = 'upload'
}

function resetState() {
  rawData.value = []
  headers.value = []
  fileName.value = ''
  columnMappings.value = []
  selectedCategoryId.value = null
  importProgress.value = 0
  importSummary.value = null
  currentStep.value = 'upload'
}

// Reset state when dialog closes
watch(dialogVisible, (newVal) => {
  if (!newVal) {
    // Small delay to allow close animation
    setTimeout(() => resetState(), 300)
  }
})
</script>

<template>
  <PDialog
    v-model:visible="dialogVisible"
    modal
    :header="stepTitle"
    :draggable="false"
    :closable="currentStep !== 'importing'"
    class="w-full mx-4 md:w-4/5 lg:w-3/4 xl:w-2/3 2xl:w-1/2"
    @hide="handleClose"
  >
    <div class="max-h-[70vh] overflow-y-auto">
      <!-- Step Indicator -->
      <div class="flex items-center gap-2 mb-4 px-1">
        <div
          v-for="(step, index) in ['upload', 'mapping', 'preview', 'importing', 'summary']"
          :key="step"
          class="flex items-center gap-2"
        >
          <div
            class="w-7 h-7 rounded-full flex items-center justify-center text-xs font-semibold transition-all"
            :class="{
              'bg-blue-600 text-white': currentStep === step,
              'bg-emerald-500 text-white': ['upload', 'mapping', 'preview', 'importing', 'summary'].indexOf(currentStep) > index,
              'bg-slate-200 text-slate-500': ['upload', 'mapping', 'preview', 'importing', 'summary'].indexOf(currentStep) < index
            }"
          >
            <i v-if="['upload', 'mapping', 'preview', 'importing', 'summary'].indexOf(currentStep) > index" class="pi pi-check text-[10px]"></i>
            <span v-else>{{ index + 1 }}</span>
          </div>
          <div
            v-if="index < 4"
            class="w-6 sm:w-10 h-0.5 transition-all"
            :class="{
              'bg-emerald-500': ['upload', 'mapping', 'preview', 'importing', 'summary'].indexOf(currentStep) > index,
              'bg-slate-200': ['upload', 'mapping', 'preview', 'importing', 'summary'].indexOf(currentStep) <= index
            }"
          ></div>
        </div>
      </div>

      <!-- ========== STEP 1: Upload ========== -->
      <div v-if="currentStep === 'upload'" class="space-y-4">
        <p class="text-sm text-slate-600">
          {{ t('bulk_import.upload_description') }}
        </p>

        <FileUploadZone
          ref="uploadZoneRef"
          accept=".csv,.xlsx,.xls"
          :max-size-m-b="25"
          :multiple="false"
          drop-icon="pi pi-file-import"
          file-icon="pi pi-file"
          :drop-title="t('bulk_import.drop_csv_here')"
          :drop-subtitle="t('bulk_import.or_click_to_browse')"
          :requirements="[
            t('bulk_import.req_csv_format'),
            t('bulk_import.req_first_row_headers'),
            t('bulk_import.req_title_required'),
            t('bulk_import.req_max_size')
          ]"
          @file-selected="handleFileSelected"
          @file-removed="handleFileRemoved"
          @error="handleUploadError"
        />

        <!-- Download Template -->
        <div class="flex items-center justify-between gap-3 px-4 py-3 bg-blue-50 border border-blue-200 rounded-lg">
          <div class="flex items-center gap-2 text-sm text-blue-700">
            <i class="pi pi-info-circle"></i>
            <span>{{ t('bulk_import.template_hint') }}</span>
          </div>
          <Button
            :label="t('bulk_import.download_template')"
            icon="pi pi-download"
            size="small"
            outlined
            severity="secondary"
            @click="downloadTemplate"
          />
        </div>
      </div>

      <!-- ========== STEP 2: Column Mapping ========== -->
      <div v-if="currentStep === 'mapping'" class="space-y-4">
        <div class="flex items-center gap-2 mb-2">
          <i class="pi pi-file text-slate-400"></i>
          <span class="text-sm font-medium text-slate-700">{{ fileName }}</span>
          <span class="text-xs text-slate-400">({{ totalDataRows }} {{ t('bulk_import.rows') }})</span>
        </div>

        <p class="text-sm text-slate-600">
          {{ t('bulk_import.mapping_description') }}
        </p>

        <!-- Column Mapping Table -->
        <div class="border border-slate-200 rounded-lg overflow-hidden">
          <div
            v-for="(mapping, index) in columnMappings"
            :key="index"
            class="flex items-center gap-3 px-4 py-3 border-b border-slate-100 last:border-b-0"
            :class="{ 'bg-blue-50/40': mapping.field !== '__skip__' }"
          >
            <!-- CSV Column Name -->
            <div class="flex-1 min-w-0">
              <div class="flex items-center gap-2">
                <i class="pi pi-table text-xs text-slate-400"></i>
                <span class="text-sm font-medium text-slate-800 truncate">{{ mapping.csvColumn }}</span>
              </div>
              <div class="text-xs text-slate-400 mt-0.5 truncate pl-5">
                {{ rawData[1]?.[index] || '—' }}
              </div>
            </div>

            <!-- Arrow -->
            <i class="pi pi-arrow-right text-xs text-slate-300 flex-shrink-0"></i>

            <!-- Target Field Select -->
            <div class="w-48 flex-shrink-0">
              <Select
                v-model="mapping.field"
                :options="TARGET_FIELDS"
                optionLabel="label"
                optionValue="value"
                class="w-full"
                size="small"
              />
            </div>

            <!-- Required Badge -->
            <span
              v-if="mapping.field === 'name'"
              class="text-[10px] font-semibold uppercase tracking-wide text-emerald-700 bg-emerald-100 px-1.5 py-0.5 rounded flex-shrink-0"
            >
              {{ t('bulk_import.required') }}
            </span>
          </div>
        </div>

        <!-- Category Selection (for grouped mode) -->
        <div v-if="isGrouped && categories.length > 0" class="border border-slate-200 rounded-lg p-4">
          <div class="flex items-center gap-2 mb-2">
            <i class="pi pi-folder text-sm text-orange-500"></i>
            <span class="text-sm font-medium text-slate-700">{{ t('bulk_import.select_category') }}</span>
          </div>
          <p class="text-xs text-slate-500 mb-3">{{ t('bulk_import.select_category_desc') }}</p>
          <Select
            v-model="selectedCategoryId"
            :options="categories"
            optionLabel="name"
            optionValue="id"
            :placeholder="t('bulk_import.choose_category')"
            class="w-full"
            size="small"
          />
        </div>

        <!-- Validation Errors -->
        <div v-if="validationErrors.length > 0" class="bg-red-50 border border-red-200 rounded-lg p-3">
          <div class="flex items-center gap-2 text-sm font-medium text-red-700 mb-1">
            <i class="pi pi-exclamation-triangle text-xs"></i>
            {{ t('bulk_import.validation_errors') }}
          </div>
          <ul class="text-xs text-red-600 space-y-1 pl-5 list-disc">
            <li v-for="(err, i) in validationErrors" :key="i">{{ err }}</li>
          </ul>
        </div>
      </div>

      <!-- ========== STEP 3: Preview ========== -->
      <div v-if="currentStep === 'preview'" class="space-y-4">
        <div class="flex items-center justify-between">
          <p class="text-sm text-slate-600">
            {{ t('bulk_import.preview_description', { count: totalDataRows, showing: Math.min(PREVIEW_ROWS, totalDataRows) }) }}
          </p>
          <span class="text-xs text-slate-400 bg-slate-100 px-2 py-1 rounded">
            {{ totalDataRows }} {{ t('bulk_import.total_rows') }}
          </span>
        </div>

        <!-- Preview Table -->
        <DataTable
          :value="previewRows"
          :rows="PREVIEW_ROWS"
          class="text-sm"
          size="small"
          stripedRows
          scrollable
          scrollHeight="400px"
        >
          <Column field="__row" :header="t('bulk_import.row_number')" style="width: 60px" frozen>
            <template #body="{ data }">
              <span class="text-xs text-slate-400">{{ data.__row }}</span>
            </template>
          </Column>
          <Column
            v-for="col in previewColumns"
            :key="col.field"
            :field="col.field"
            :header="col.header"
            style="min-width: 150px"
          >
            <template #body="{ data }">
              <span class="text-sm text-slate-700 line-clamp-2">{{ data[col.field] || '—' }}</span>
            </template>
          </Column>
        </DataTable>

        <!-- Category info -->
        <div v-if="isGrouped && selectedCategoryId" class="flex items-center gap-2 text-sm text-slate-600 bg-orange-50 rounded-lg px-3 py-2">
          <i class="pi pi-folder text-orange-500 text-xs"></i>
          {{ t('bulk_import.importing_to_category', { category: categories.find(c => c.id === selectedCategoryId)?.name || '' }) }}
        </div>
      </div>

      <!-- ========== STEP 4: Importing ========== -->
      <div v-if="currentStep === 'importing'" class="space-y-6 py-8">
        <div class="text-center">
          <i class="pi pi-spin pi-spinner text-3xl text-blue-500 mb-4"></i>
          <h3 class="text-lg font-medium text-slate-800 mb-2">{{ t('bulk_import.importing_items') }}</h3>
          <p class="text-sm text-slate-500">{{ t('bulk_import.please_wait') }}</p>
        </div>
        <ProgressBar :value="importProgress" class="h-3" />
        <p class="text-center text-sm text-slate-500">{{ importProgress }}%</p>
      </div>

      <!-- ========== STEP 5: Summary ========== -->
      <div v-if="currentStep === 'summary' && importSummary" class="space-y-4">
        <!-- Success/Error Header -->
        <div
          class="rounded-lg p-4 text-center"
          :class="importSummary.failed === 0 ? 'bg-emerald-50' : 'bg-amber-50'"
        >
          <i
            class="text-3xl mb-2"
            :class="importSummary.failed === 0 ? 'pi pi-check-circle text-emerald-500' : 'pi pi-exclamation-triangle text-amber-500'"
          ></i>
          <h3 class="text-lg font-medium mb-1"
            :class="importSummary.failed === 0 ? 'text-emerald-800' : 'text-amber-800'"
          >
            {{ importSummary.failed === 0 ? t('bulk_import.import_successful') : t('bulk_import.import_partial') }}
          </h3>
          <p class="text-sm" :class="importSummary.failed === 0 ? 'text-emerald-600' : 'text-amber-600'">
            {{ t('bulk_import.summary_detail', { succeeded: importSummary.succeeded, total: importSummary.total }) }}
          </p>
        </div>

        <!-- Stats Grid -->
        <div class="grid grid-cols-3 gap-3">
          <div class="bg-slate-50 rounded-lg p-3 text-center">
            <div class="text-2xl font-bold text-slate-800">{{ importSummary.total }}</div>
            <div class="text-xs text-slate-500">{{ t('bulk_import.stat_total') }}</div>
          </div>
          <div class="bg-emerald-50 rounded-lg p-3 text-center">
            <div class="text-2xl font-bold text-emerald-600">{{ importSummary.succeeded }}</div>
            <div class="text-xs text-emerald-600">{{ t('bulk_import.stat_succeeded') }}</div>
          </div>
          <div class="bg-red-50 rounded-lg p-3 text-center">
            <div class="text-2xl font-bold text-red-600">{{ importSummary.failed }}</div>
            <div class="text-xs text-red-600">{{ t('bulk_import.stat_failed') }}</div>
          </div>
        </div>

        <!-- Error Details -->
        <div v-if="importSummary.errors.length > 0" class="border border-red-200 rounded-lg overflow-hidden">
          <div class="bg-red-50 px-4 py-2 border-b border-red-200">
            <span class="text-sm font-medium text-red-700">
              <i class="pi pi-exclamation-triangle mr-1"></i>
              {{ t('bulk_import.error_details') }} ({{ importSummary.errors.length }})
            </span>
          </div>
          <div class="max-h-48 overflow-y-auto">
            <div
              v-for="(error, index) in importSummary.errors"
              :key="index"
              class="flex items-start gap-3 px-4 py-2 border-b border-red-100 last:border-b-0 text-sm"
            >
              <span class="text-xs text-red-400 font-mono flex-shrink-0">
                {{ t('bulk_import.row_label') }} {{ error.row }}
              </span>
              <span class="text-red-700">{{ error.message }}</span>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Footer -->
    <template #footer>
      <div class="flex justify-between w-full">
        <!-- Left side: Back buttons -->
        <div>
          <Button
            v-if="currentStep === 'mapping'"
            :label="t('common.back')"
            icon="pi pi-arrow-left"
            severity="secondary"
            text
            @click="goBackToUpload"
          />
          <Button
            v-if="currentStep === 'preview'"
            :label="t('common.back')"
            icon="pi pi-arrow-left"
            severity="secondary"
            text
            @click="goBackToMapping"
          />
        </div>

        <!-- Right side: Action buttons -->
        <div class="flex gap-2">
          <!-- Upload step: Cancel -->
          <Button
            v-if="currentStep === 'upload'"
            :label="t('common.cancel')"
            severity="secondary"
            text
            @click="dialogVisible = false"
          />

          <!-- Mapping step: Next -->
          <Button
            v-if="currentStep === 'mapping'"
            :label="t('bulk_import.preview_data')"
            icon="pi pi-eye"
            :disabled="!canProceedToPreview"
            @click="goToPreview"
          />

          <!-- Preview step: Start Import -->
          <Button
            v-if="currentStep === 'preview'"
            :label="t('bulk_import.start_import', { count: totalDataRows })"
            icon="pi pi-upload"
            severity="success"
            @click="startImport"
          />

          <!-- Summary step: Import Another / Close -->
          <Button
            v-if="currentStep === 'summary'"
            :label="t('bulk_import.import_another')"
            icon="pi pi-plus"
            severity="secondary"
            outlined
            @click="handleImportAnother"
          />
          <Button
            v-if="currentStep === 'summary'"
            :label="t('common.close')"
            icon="pi pi-check"
            @click="handleClose"
          />
        </div>
      </div>
    </template>
  </PDialog>
</template>
