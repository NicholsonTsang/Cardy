<template>
    <div class="bg-white rounded-xl shadow-lg border border-slate-200 flex flex-col overflow-hidden"> 
        <!-- Header -->
        <div class="p-3 sm:p-4 border-b border-slate-200 bg-white">
            <!-- Normal Mode Header -->
            <div v-if="!multiSelectMode">
                <div class="flex items-start justify-between gap-2 mb-2">
                    <div>
                        <h1 class="text-lg sm:text-xl font-bold text-slate-900 leading-tight">{{ $t('dashboard.card_designs') }}</h1>
                        <div v-if="experienceLimit > 0" class="flex items-center gap-2 mt-1">
                            <div class="inline-flex items-center gap-1.5 px-2 py-0.5 bg-slate-100 border border-slate-200 rounded text-[10px] sm:text-xs font-medium text-slate-600" :class="{'text-amber-700 bg-amber-50 border-amber-200': experienceCount >= experienceLimit}">
                                <i class="pi pi-id-card text-[10px]"></i>
                                <span>{{ experienceCount }} / {{ experienceLimit }}</span>
                            </div>
                        </div>
                    </div>
                    <div class="flex items-center gap-1 shrink-0">
                        <Button 
                            v-if="cards.length > 0"
                            icon="pi pi-check-square"
                            @click="enterMultiSelectMode"
                            rounded
                            text
                            size="small"
                            :aria-label="$t('dashboard.multi_select')"
                            v-tooltip.top="$t('dashboard.multi_select')"
                        />
                        <Button 
                            icon="pi pi-plus" 
                            @click="$emit('create-card')" 
                            rounded
                            text
                            size="small"
                            :aria-label="$t('dashboard.create_new_card')"
                            v-tooltip.top="$t('dashboard.create_new_card')"
                            class="w-8 h-8"
                        />
                    </div>
                </div>
                
                <!-- Search -->
                <IconField class="mt-3">
                    <InputIcon class="pi pi-search" />
                    <InputText 
                        class="w-full text-sm" 
                        :model-value="searchQuery" 
                        @update:model-value="$emit('update:searchQuery', $event)"
                        :placeholder="$t('dashboard.search_cards')" 
                    />
                </IconField>
                
                <!-- Import & Template Buttons -->
                <div class="mt-3 sm:mt-4 space-y-2">
                    <div class="relative">
                        <Button 
                            :label="$t('templates.browse_templates')"
                            icon="pi pi-book"
                            @click="openTemplateLibrary"
                            class="w-full bg-gradient-to-r from-emerald-600 to-blue-600 hover:from-emerald-700 hover:to-blue-700 text-white border-0 font-semibold shadow-sm"
                        />
                        <!-- NEW Badge -->
                        <div class="absolute -top-1 -right-1 bg-yellow-400 text-yellow-900 text-xs px-1.5 py-0.5 rounded-full font-bold text-[10px] leading-tight">
                            {{ $t('common.new') }}
                        </div>
                    </div>
                    <Button 
                        :label="$t('dashboard.import_cards')"
                        icon="pi pi-upload"
                        @click="openRegularImport"
                        class="w-full bg-blue-600 hover:bg-blue-700 text-white border-0"
                    />
                </div>
            </div>
            
            <!-- Multi-Select Mode Header -->
            <div v-else class="select-mode-header">
                <div class="flex items-center justify-between">
                    <div class="flex items-center gap-3">
                        <button 
                            @click="exitMultiSelectMode"
                            class="w-8 h-8 flex items-center justify-center rounded-full hover:bg-slate-100 transition-colors"
                        >
                            <i class="pi pi-arrow-left text-slate-600"></i>
                        </button>
                        <div>
                            <h2 class="text-lg font-semibold text-slate-900">
                                {{ selectedCards.size > 0 ? $t('dashboard.n_selected', { count: selectedCards.size }) : $t('dashboard.select_cards') }}
                            </h2>
                            <p class="text-xs text-slate-500">{{ $t('dashboard.tap_to_select') }}</p>
                        </div>
                    </div>
                    <div class="flex items-center gap-1">
                        <button
                            @click="toggleSelectAll(!allSelected)"
                            class="text-xs font-medium text-blue-600 hover:text-blue-700 px-2 py-1 rounded hover:bg-blue-50 transition-colors"
                        >
                            {{ allSelected ? $t('dashboard.deselect_all') : $t('dashboard.select_all') }}
                        </button>
                    </div>
                </div>
            </div>
            
            <!-- Import Dialog -->
            <Dialog 
                v-model:visible="showImportDialog"
                modal 
                :header="$t('dashboard.import_cards')"
                :style="{ width: '90vw', maxWidth: '50rem' }"
                :breakpoints="{ '1199px': '85vw', '768px': '95vw', '575px': '98vw' }"
                class="import-dialog standardized-dialog"
            >
                <CardBulkImport mode="regular" @imported="handleImportComplete" />
            </Dialog>
            
            <!-- Template Library Dialog -->
            <Dialog 
                v-model:visible="showTemplateDialog"
                modal 
                :header="$t('templates.library_title')"
                :style="{ width: '95vw', maxWidth: '80rem' }"
                :breakpoints="{ '1199px': '95vw', '768px': '98vw' }"
                class="template-library-dialog standardized-dialog"
            >
                <TemplateLibrary @imported="handleTemplateImport" :dialog-mode="true" />
            </Dialog>
            <!-- Export Options Dialog -->
            <Dialog 
                v-model:visible="showExportOptions"
                :header="$t('dashboard.export_options')"
                :style="{ width: '25rem' }"
                modal
                class="export-options-dialog"
            >
                <div class="export-options-content">
                    <p class="export-count">{{ $t('dashboard.exporting_n_cards', { count: selectedCards.size }) }}</p>
                    
                    <div class="export-option" @click="doExport(true)">
                        <div class="option-icon bg-blue-100 text-blue-600">
                            <i class="pi pi-file"></i>
                        </div>
                        <div class="option-details">
                            <h4>{{ $t('dashboard.export_single_file') }}</h4>
                            <p>{{ $t('dashboard.export_single_file_desc') }}</p>
                        </div>
                        <i class="pi pi-chevron-right text-slate-400"></i>
                    </div>
                    
                    <div class="export-option" @click="doExport(false)">
                        <div class="option-icon bg-emerald-100 text-emerald-600">
                            <i class="pi pi-folder"></i>
                        </div>
                        <div class="option-details">
                            <h4>{{ $t('dashboard.export_separate_files') }}</h4>
                            <p>{{ $t('dashboard.export_separate_files_desc') }}</p>
                        </div>
                        <i class="pi pi-chevron-right text-slate-400"></i>
                    </div>
                </div>
            </Dialog>
            
            <!-- Filters (hidden in multi-select mode) -->
            <div v-if="!multiSelectMode" class="mt-3 space-y-2">
                <!-- Date Filters -->
                <div class="grid grid-cols-2 gap-2">
                    <Dropdown 
                        :model-value="selectedYear"
                        @update:model-value="$emit('update:selectedYear', $event)"
                        :options="yearOptions" 
                        optionLabel="label" 
                        optionValue="value"
                        :placeholder="$t('dashboard.year')"
                        showClear
                        class="w-full text-sm"
                    />
                    <Dropdown 
                        :model-value="selectedMonth"
                        @update:model-value="$emit('update:selectedMonth', $event)"
                        :options="monthOptions" 
                        optionLabel="label" 
                        optionValue="value"
                        :placeholder="$t('dashboard.month')"
                        showClear
                        :disabled="!selectedYear" 
                        class="w-full text-sm"
                    />
                </div>
                <!-- Translation Filter -->
                <Dropdown 
                    :model-value="translationFilter"
                    @update:model-value="$emit('update:translationFilter', $event)"
                    :options="translationFilterOptions" 
                    optionLabel="label" 
                    optionValue="value"
                    :placeholder="$t('dashboard.filter_translations')"
                    class="w-full text-sm"
                />
            </div>
            <Button 
                v-if="hasActiveFilters && !multiSelectMode"
                :label="$t('dashboard.clear_filters')"
                icon="pi pi-times"
                @click="$emit('clear-filters')"
                text
                size="small"
                class="w-full mt-2 text-blue-600"
            />
        </div>

        <!-- Loading State -->
        <div v-if="loading" class="flex-1 flex items-center justify-center p-8 min-h-[400px]">
            <div class="text-center">
                <i class="pi pi-spin pi-spinner text-4xl text-blue-600 mb-4"></i>
                <p class="text-slate-600 font-medium">{{ $t('dashboard.loading_cards') }}</p>
            </div>
        </div>

        <!-- Optimized Empty State -->
        <div v-else-if="cards.length === 0 && !searchQuery" class="flex-1 flex flex-col justify-center p-3 sm:p-4 text-center min-h-[400px]">
            <!-- Compact Header -->
            <div class="w-14 h-14 sm:w-16 sm:h-16 bg-slate-100 rounded-full flex items-center justify-center mx-auto mb-3 sm:mb-4">
                <i class="pi pi-id-card text-xl sm:text-2xl text-slate-400"></i>
            </div>
            <h3 class="text-lg sm:text-xl font-semibold text-slate-900 mb-2">{{ $t('dashboard.no_cards_yet') }}</h3>
            <p class="text-sm sm:text-base text-slate-500 mb-6 sm:mb-8">{{ $t('dashboard.start_creating') }}</p>
            
            <!-- Primary Action -->
            <div class="mb-4 sm:mb-6">
                <Button 
                    :label="$t('dashboard.create_new_card')"
                    icon="pi pi-plus"
                    @click="$emit('create-card')"
                    class="bg-blue-600 hover:bg-blue-700 text-white border-0 px-6 sm:px-8 py-2.5 sm:py-3 text-base sm:text-lg font-semibold shadow-lg hover:shadow-xl transition-all"
                />
            </div>
            
        </div>

        <!-- No Search Results -->
        <div v-if="filteredCards.length === 0 && searchQuery" class="flex-1 flex flex-col items-center justify-center p-6 sm:p-8 text-center">
            <div class="w-14 h-14 sm:w-16 sm:h-16 bg-slate-100 rounded-full flex items-center justify-center mb-3 sm:mb-4">
                <i class="pi pi-search-slash text-xl sm:text-2xl text-slate-400"></i>
            </div>
            <h3 class="text-base sm:text-lg font-medium text-slate-900 mb-2">{{ $t('dashboard.no_results_found') }}</h3>
            <p class="text-sm sm:text-base text-slate-500 mb-4">{{ $t('dashboard.no_cards_match_search') }}</p>
        </div>

        <!-- Cards List -->
        <div v-else-if="cards.length > 0" class="flex-1 overflow-y-auto">
            <div class="p-2 sm:p-2 space-y-2">
                <CardListItem
                    v-for="card in paginatedCards" 
                    :key="card.id"
                    :card="card"
                    :isSelected="selectedCardId === card.id"
                    :multiSelectMode="multiSelectMode"
                    :isChecked="selectedCards.has(card.id)"
                    @select="$emit('select-card', card.id)"
                    @toggle-check="toggleCardSelection"
                />
            </div>
            
            <!-- Floating Action Bar (Multi-select mode) - inside scroll container -->
            <Transition name="slide-up">
                <div v-if="multiSelectMode && selectedCards.size > 0" class="floating-action-bar-container">
                    <div class="floating-action-bar">
                <button 
                    @click="showExportOptions = true"
                    class="action-btn action-btn-primary"
                >
                    <i class="pi pi-download"></i>
                    <span>{{ $t('common.export') }}</span>
                </button>
                        <button 
                            @click="confirmDeleteSelected"
                            class="action-btn action-btn-danger"
                        >
                            <i class="pi pi-trash"></i>
                            <span>{{ $t('common.delete') }}</span>
                        </button>
                    </div>
                </div>
            </Transition>
        </div>
        
        <!-- Paginator (always visible, outside scroll area) -->
        <div v-if="totalRecords > itemsPerPage" class="p-2 border-t border-slate-200 bg-white flex-shrink-0">
            <Paginator 
                :rows="itemsPerPage" 
                :totalRecords="totalRecords" 
                :first="(currentPage - 1) * itemsPerPage"
                @page="$emit('page-change', $event)"
                template="FirstPageLink PrevPageLink CurrentPageReport NextPageLink LastPageLink"
                class="text-sm"
            />
        </div>
    </div>
</template>

<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useConfirm } from 'primevue/useconfirm';
import { useToast } from 'primevue/usetoast';
import Button from 'primevue/button';
import IconField from 'primevue/iconfield';
import InputIcon from 'primevue/inputicon';
import InputText from 'primevue/inputtext';
import Dropdown from 'primevue/dropdown';
import Paginator from 'primevue/paginator';
import Dialog from 'primevue/dialog';
import CardListItem from './CardListItem.vue';
import CardBulkImport from './Import/CardBulkImport.vue';
import { TemplateLibrary } from '@/components/TemplateLibrary';

const { t } = useI18n();
const confirm = useConfirm();
const toast = useToast();

const props = defineProps({
    cards: {
        type: Array,
        required: true
    },
    filteredCards: {
        type: Array,
        required: true
    },
    selectedCardId: {
        type: [String, Number],
        default: null
    },
    searchQuery: {
        type: String,
        default: ''
    },
    selectedYear: {
        type: [String, Number],
        default: null
    },
    selectedMonth: {
        type: [String, Number],
        default: null
    },
    translationFilter: {
        type: String,
        default: null
    },
    currentPage: {
        type: Number,
        default: 1
    },
    itemsPerPage: {
        type: Number,
        default: 10
    },
    loading: {
        type: Boolean,
        default: false
    },
    experienceCount: {
        type: Number,
        default: 0
    },
    experienceLimit: {
        type: Number,
        default: 0
    }
});

const emit = defineEmits([
    'create-card',
    'select-card',
    'update:searchQuery',
    'update:selectedYear',
    'update:selectedMonth',
    'update:translationFilter',
    'clear-filters',
    'page-change',
    'cards-imported',
    'delete-cards',
    'export-cards'
]);

// Translation filter options
const translationFilterOptions = computed(() => [
    { label: t('dashboard.filter_all'), value: null },
    { label: t('dashboard.filter_with_translations'), value: 'with' },
    { label: t('dashboard.filter_without_translations'), value: 'without' }
]);

// Check if any filter is active
const hasActiveFilters = computed(() => {
    return props.selectedYear !== null || props.selectedMonth !== null || props.translationFilter !== null;
});

// Dialog state
const showImportDialog = ref(false);
const showTemplateDialog = ref(false);
const showExportOptions = ref(false);

// Multi-select state
const multiSelectMode = ref(false);
const selectedCards = ref(new Set());

// Computed for select all (checks all filtered cards, not just current page)
const allSelected = computed(() => {
    if (props.filteredCards.length === 0) return false;
    return props.filteredCards.every(card => selectedCards.value.has(card.id));
});

// Multi-select functions
function enterMultiSelectMode() {
    multiSelectMode.value = true;
    selectedCards.value = new Set();
}

function exitMultiSelectMode() {
    multiSelectMode.value = false;
    selectedCards.value = new Set();
}

function toggleCardSelection(cardId) {
    const newSet = new Set(selectedCards.value);
    if (newSet.has(cardId)) {
        newSet.delete(cardId);
    } else {
        newSet.add(cardId);
    }
    selectedCards.value = newSet;
}

function toggleSelectAll(checked) {
    if (checked) {
        // Select all filtered cards (across all pages)
        const newSet = new Set();
        props.filteredCards.forEach(card => newSet.add(card.id));
        selectedCards.value = newSet;
    } else {
        // Deselect all
        selectedCards.value = new Set();
    }
}

function confirmDeleteSelected() {
    const count = selectedCards.value.size;
    confirm.require({
        group: 'deleteCardConfirmation',
        message: t('dashboard.delete_cards_confirm', { count }),
        header: t('dashboard.delete_cards'),
        icon: 'pi pi-exclamation-triangle',
        acceptClass: 'p-button-danger',
        accept: () => {
            const cardIds = Array.from(selectedCards.value);
            emit('delete-cards', cardIds);
            exitMultiSelectMode();
        }
    });
}

function doExport(singleFile) {
    showExportOptions.value = false;
    const cardIds = Array.from(selectedCards.value);
    const cardsToExport = props.cards.filter(card => cardIds.includes(card.id));
    emit('export-cards', { cards: cardsToExport, singleFile });
}

// Handle opening dialogs
function openTemplateLibrary() {
    showTemplateDialog.value = true;
}

function openRegularImport() {
    showImportDialog.value = true;
}

// Handle import completion
function handleImportComplete(results) {
    showImportDialog.value = false;
    emit('cards-imported', results);
}

// Handle template import completion
function handleTemplateImport(results) {
    showTemplateDialog.value = false;
    emit('cards-imported', results);
}

// Computed properties
const paginatedCards = computed(() => {
    const start = (props.currentPage - 1) * props.itemsPerPage;
    const end = start + props.itemsPerPage;
    return props.filteredCards.slice(start, end);
});

const totalRecords = computed(() => props.filteredCards.length);

const yearOptions = computed(() => {
    const years = new Set();
    props.cards.forEach(card => {
        if (card.created_at) {
            years.add(new Date(card.created_at).getFullYear());
        }
    });
    return Array.from(years)
        .sort((a, b) => b - a)
        .map(year => ({ label: year.toString(), value: year }));
});

const monthOptions = computed(() => {
    return [
        { label: t('common.january'), value: 0 },
        { label: t('common.february'), value: 1 },
        { label: t('common.march'), value: 2 },
        { label: t('common.april'), value: 3 },
        { label: t('common.may'), value: 4 },
        { label: t('common.june'), value: 5 },
        { label: t('common.july'), value: 6 },
        { label: t('common.august'), value: 7 },
        { label: t('common.september'), value: 8 },
        { label: t('common.october'), value: 9 },
        { label: t('common.november'), value: 10 },
        { label: t('common.december'), value: 11 }
    ];
});
</script>

<style scoped>
/* Component uses global theme styles */

/* Select mode header */
.select-mode-header {
  @apply py-1;
}

/* Floating action bar */
.floating-action-bar-container {
  @apply sticky bottom-0 py-3 flex justify-center;
  background: linear-gradient(to top, rgba(255,255,255,0.95) 0%, rgba(255,255,255,0.8) 70%, transparent 100%);
}

.floating-action-bar {
  @apply flex items-center gap-2 px-2 py-2 bg-slate-900 rounded-full shadow-xl;
}

.action-btn {
  @apply flex items-center gap-2 px-4 py-2 rounded-full text-sm font-medium transition-all;
}

.action-btn i {
  @apply text-sm;
}

.action-btn-primary {
  @apply bg-blue-500 text-white hover:bg-blue-600;
}

.action-btn-danger {
  @apply bg-red-500 text-white hover:bg-red-600;
}

/* Slide up animation */
.slide-up-enter-active,
.slide-up-leave-active {
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
}

.slide-up-enter-from,
.slide-up-leave-to {
  transform: translateY(100%);
  opacity: 0;
}

/* Custom import dialog styles */
:deep(.import-dialog .p-dialog-content) {
  padding: 0;
}

/* Export options dialog */
.export-options-content {
  @apply space-y-3;
}

.export-count {
  @apply text-sm text-slate-600 mb-4;
}

.export-option {
  @apply flex items-center gap-3 p-3 rounded-lg border border-slate-200 cursor-pointer transition-all hover:border-blue-300 hover:bg-blue-50;
}

.option-icon {
  @apply w-10 h-10 rounded-lg flex items-center justify-center flex-shrink-0;
}

.option-icon i {
  @apply text-lg;
}

.option-details {
  @apply flex-1 min-w-0;
}

.option-details h4 {
  @apply font-medium text-slate-900 text-sm;
}

.option-details p {
  @apply text-xs text-slate-500 mt-0.5;
}

/* Mobile responsive */
@media (max-width: 640px) {
  .floating-action-bar {
    @apply bottom-3 gap-1.5 px-1.5 py-1.5;
  }
  
  .action-btn {
    @apply px-3 py-1.5 text-xs gap-1.5;
  }
}
</style>