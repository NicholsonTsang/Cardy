<template>
  <div class="template-library" :class="{ 'dialog-mode': dialogMode }">
    <!-- Header -->
    <div class="library-header">
      <h1 class="header-title">{{ $t('templates.explore_templates') }}</h1>
      <p class="header-description">{{ $t('templates.explore_description') }}</p>
    </div>

    <!-- Category Tabs + Language + Search Row -->
    <div class="filter-bar">
      <div class="category-tabs">
        <button 
          class="category-tab"
          :class="{ active: selectedVenueType === null }"
          @click="selectVenueType(null)"
        >
          <i class="pi pi-thumbs-up"></i>
          {{ $t('templates.recommended') }}
        </button>
        <button 
          v-for="vt in venueTypes"
          :key="vt.venue_type"
          class="category-tab"
          :class="{ active: selectedVenueType === vt.venue_type }"
          @click="selectVenueType(vt.venue_type)"
        >
          {{ formatVenueType(vt.venue_type) }}
        </button>
      </div>
      
      <div class="filter-right">
        <!-- Language Selector -->
        <Dropdown
          v-model="selectedLanguage"
          :options="languageOptions"
          optionLabel="label"
          optionValue="value"
          :placeholder="$t('templates.browse_language')"
          class="language-dropdown"
        >
          <template #value="slotProps">
            <div v-if="slotProps.value" class="lang-value">
              <span>{{ getLanguageFlag(slotProps.value) }}</span>
              <span>{{ getLanguageName(slotProps.value) }}</span>
            </div>
            <span v-else>{{ $t('templates.browse_language') }}</span>
          </template>
          <template #option="slotProps">
            <div class="lang-option">
              <span>{{ getLanguageFlag(slotProps.option.value) }}</span>
              <span>{{ slotProps.option.label }}</span>
            </div>
          </template>
        </Dropdown>
        
        <div class="search-box">
          <i class="pi pi-search search-icon"></i>
          <input 
            type="text"
            v-model="searchQuery" 
            :placeholder="$t('common.search')"
            @keyup.enter="handleSearch"
            class="search-input"
          />
        </div>
      </div>
    </div>

    <!-- Loading State -->
    <div v-if="isLoading" class="loading-state">
      <ProgressSpinner strokeWidth="4" />
    </div>

    <!-- Empty State -->
    <div v-else-if="templates.length === 0" class="empty-state">
      <div class="empty-icon">
        <i class="pi pi-folder-open"></i>
      </div>
      <h3>{{ $t('templates.no_templates') }}</h3>
      <p>{{ $t('templates.no_templates_description') }}</p>
    </div>

    <!-- Template Grid - 2 columns -->
    <div v-else class="template-grid">
      <TemplateCard 
        v-for="template in templates"
        :key="template.id"
        :template="template"
        @preview="openPreview"
        @import="openImportDialog"
      />
    </div>

    <!-- Preview Dialog -->
    <Dialog 
      v-model:visible="showPreviewDialog" 
      :header="selectedTemplate?.name"
      :modal="true"
      :style="{ width: '50rem', maxWidth: '95vw' }"
      :dismissableMask="true"
    >
      <TemplatePreview 
        v-if="selectedTemplate"
        :template="selectedTemplate"
        @import="openImportDialog"
      />
    </Dialog>

    <!-- Import Dialog -->
    <Dialog 
      v-model:visible="showImportDialog" 
      :header="$t('templates.import_template')"
      :modal="true"
      :style="{ width: '30rem', maxWidth: '95vw' }"
    >
      <TemplateImportForm 
        v-if="templateToImport"
        :template="templateToImport"
        :default-language="selectedLanguage"
        @imported="handleImported"
        @cancel="showImportDialog = false"
      />
    </Dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, watch, onMounted, computed } from 'vue'
import { useI18n } from 'vue-i18n'
import { useRouter } from 'vue-router'
import { useTemplateLibraryStore, type ContentTemplate, type ContentTemplateDetails } from '@/stores/templateLibrary'
import { storeToRefs } from 'pinia'

import Dialog from 'primevue/dialog'
import Dropdown from 'primevue/dropdown'
import ProgressSpinner from 'primevue/progressspinner'

import TemplateCard from './TemplateCard.vue'
import TemplatePreview from './TemplatePreview.vue'
import TemplateImportForm from './TemplateImportForm.vue'

// Props
const props = defineProps<{
  dialogMode?: boolean
}>()

// Emits
const emit = defineEmits<{
  imported: [result: { cardId: string }]
}>()

const { t, locale } = useI18n()
const router = useRouter()
const templateStore = useTemplateLibraryStore()
const { templates, venueTypes, isLoading } = storeToRefs(templateStore)

// Local state
const searchQuery = ref('')
const selectedVenueType = ref<string | null>(null)
const selectedLanguage = ref<string | null>(null)  // Will be initialized to user's locale
const showPreviewDialog = ref(false)
const showImportDialog = ref(false)
const selectedTemplate = ref<ContentTemplateDetails | null>(null)
const templateToImport = ref<ContentTemplate | null>(null)

// Language options for dropdown
const supportedLanguages = [
  { code: 'en', name: 'English', flag: '🇺🇸' },
  { code: 'zh-Hant', name: '繁體中文', flag: '🇭🇰' },
  { code: 'zh-Hans', name: '简体中文', flag: '🇨🇳' },
  { code: 'ja', name: '日本語', flag: '🇯🇵' },
  { code: 'ko', name: '한국어', flag: '🇰🇷' },
  { code: 'es', name: 'Español', flag: '🇪🇸' },
  { code: 'fr', name: 'Français', flag: '🇫🇷' },
  { code: 'de', name: 'Deutsch', flag: '🇩🇪' },
  { code: 'it', name: 'Italiano', flag: '🇮🇹' },
  { code: 'pt', name: 'Português', flag: '🇧🇷' },
  { code: 'ar', name: 'العربية', flag: '🇸🇦' }
]

const languageOptions = computed(() => {
  return supportedLanguages.map(lang => ({
    value: lang.code,
    label: lang.name
  }))
})

function getLanguageFlag(code: string): string {
  const lang = supportedLanguages.find(l => l.code === code)
  return lang?.flag || '🌐'
}

function getLanguageName(code: string): string {
  const lang = supportedLanguages.find(l => l.code === code)
  return lang?.name || code
}

// Helpers
function formatVenueType(type: string): string {
  return type.charAt(0).toUpperCase() + type.slice(1).replace(/_/g, ' ')
}

// Actions
function selectVenueType(type: string | null) {
  selectedVenueType.value = type
  fetchTemplates()
}

async function fetchTemplates() {
  templateStore.filterVenueType = selectedVenueType.value
  templateStore.filterContentMode = null
  templateStore.searchQuery = searchQuery.value
  templateStore.previewLanguage = selectedLanguage.value
  await templateStore.fetchTemplates(selectedLanguage.value || undefined)
}

function handleSearch() {
  fetchTemplates()
}

// Watch language changes
watch(selectedLanguage, () => {
  fetchTemplates()
})

async function openPreview(template: ContentTemplate) {
  await templateStore.fetchTemplateDetails(template.id)
  selectedTemplate.value = templateStore.selectedTemplate
  showPreviewDialog.value = true
}

function openImportDialog(template: ContentTemplate) {
  templateToImport.value = template
  showImportDialog.value = true
  showPreviewDialog.value = false
}

function handleImported(result: { cardId: string }) {
  showImportDialog.value = false
  templateToImport.value = null
  
  if (props.dialogMode) {
    emit('imported', result)
  } else {
    router.push(`/cms/projects?card=${result.cardId}`)
  }
}

// Watch search for debounced fetch
watch(searchQuery, () => {
  fetchTemplates()
})

// Initial load
onMounted(async () => {
  // Initialize language to user's website locale
  selectedLanguage.value = locale.value
  await templateStore.fetchVenueTypes()
  await fetchTemplates()
})
</script>

<style scoped>
.template-library {
  @apply bg-slate-100 min-h-screen p-6 space-y-6;
}

/* Header */
.library-header {
  @apply mb-2;
}

.header-title {
  @apply text-2xl font-bold text-blue-600 mb-2;
}

.header-description {
  @apply text-slate-600 text-base;
}

/* Filter Bar */
.filter-bar {
  @apply flex items-center justify-between gap-4 flex-wrap mb-6;
}

.category-tabs {
  @apply flex items-center gap-1 flex-wrap;
}

.category-tab {
  @apply px-4 py-2 text-sm font-medium text-slate-600 rounded-lg transition-all;
  @apply hover:bg-white hover:text-blue-600;
}

.category-tab.active {
  @apply text-blue-600 bg-white shadow-sm;
}

.category-tab i {
  @apply mr-1;
}

/* Filter Right - Language + Search */
.filter-right {
  @apply flex items-center gap-3;
}

/* Language Dropdown */
.language-dropdown {
  @apply min-w-[140px];
}

.lang-value, .lang-option {
  @apply flex items-center gap-2;
}

/* Search Box */
.search-box {
  @apply relative;
}

.search-icon {
  @apply absolute left-3 top-1/2 -translate-y-1/2 text-slate-400;
}

.search-input {
  @apply pl-10 pr-4 py-2 bg-white border-0 rounded-lg text-sm text-slate-700 w-48;
  @apply placeholder:text-slate-400 focus:outline-none focus:ring-2 focus:ring-blue-200;
}

/* Loading State */
.loading-state {
  @apply flex items-center justify-center py-20;
}

/* Empty State */
.empty-state {
  @apply flex flex-col items-center justify-center py-20 text-center bg-white rounded-xl;
}

.empty-icon {
  @apply w-16 h-16 bg-slate-100 rounded-full flex items-center justify-center text-slate-400 text-3xl mb-4;
}

.empty-state h3 {
  @apply text-lg font-semibold text-slate-900 mb-2;
}

.empty-state p {
  @apply text-slate-500 max-w-md;
}

/* Template Grid - 2 columns like reference */
.template-grid {
  @apply grid grid-cols-1 lg:grid-cols-2 gap-4;
}

/* Dialog mode - more compact */
.template-library.dialog-mode {
  @apply bg-transparent p-0 min-h-0 space-y-4;
}

.template-library.dialog-mode .library-header {
  @apply hidden;
}

.template-library.dialog-mode .filter-bar {
  @apply mb-4;
}

.template-library.dialog-mode .category-tabs {
  @apply overflow-x-auto pb-2 -mb-2;
}

.template-library.dialog-mode .template-grid {
  @apply max-h-[50vh] overflow-y-auto pr-2;
}

/* Mobile responsive */
@media (max-width: 768px) {
  .template-library {
    @apply p-4;
  }

  .filter-bar {
    @apply flex-col items-start gap-3;
  }

  .category-tabs {
    @apply overflow-x-auto w-full pb-2;
    scrollbar-width: none;
    -ms-overflow-style: none;
  }

  .category-tabs::-webkit-scrollbar {
    display: none;
  }

  .filter-right {
    @apply w-full flex-col items-stretch;
  }

  .language-dropdown {
    @apply w-full;
  }

  .search-box {
    @apply w-full;
  }

  .search-input {
    @apply w-full;
  }

  .template-grid {
    @apply grid-cols-1;
  }

  .template-library.dialog-mode .template-grid {
    @apply max-h-[40vh];
  }
}
</style>

