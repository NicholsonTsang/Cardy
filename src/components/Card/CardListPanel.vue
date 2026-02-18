<template>
    <div class="bg-white rounded-xl shadow-lg border border-slate-200 flex flex-col overflow-hidden h-full">
        <!-- Header bar -->
        <div class="px-3 sm:px-4 py-2.5 border-b border-slate-200 bg-slate-50/80">
            <div v-if="!multiSelectMode" class="flex items-center gap-2">
                <i class="pi pi-id-card text-sm text-slate-500"></i>
                <span class="text-sm font-medium text-slate-700 truncate">{{ $t('dashboard.my_cards') }}</span>
                <span v-if="projectLimit > 0"
                    class="text-xs whitespace-nowrap"
                    :class="projectCount >= projectLimit ? 'text-amber-600' : 'text-slate-400'"
                >{{ projectCount }}/{{ projectLimit }}</span>
                <div class="flex-1"></div>
                <button
                    type="button"
                    class="flex items-center justify-center w-8 h-7 rounded-md transition-all"
                    :class="hasActiveFilters || showFilters
                        ? 'text-blue-600 bg-blue-50'
                        : 'text-slate-400 hover:text-slate-700 hover:bg-slate-100'"
                    @click="showFilters = !showFilters"
                    v-tooltip.bottom="$t('common.filter')"
                >
                    <i class="pi pi-filter text-xs"></i>
                </button>
                <button
                    type="button"
                    class="flex items-center justify-center w-8 h-7 rounded-md text-slate-400 hover:text-slate-700 hover:bg-slate-100 transition-all"
                    @click="toggleMoreMenu"
                    v-tooltip.bottom="$t('common.more')"
                >
                    <i class="pi pi-ellipsis-v text-xs"></i>
                </button>
                <button
                    type="button"
                    class="flex items-center justify-center w-8 h-7 rounded-md text-slate-400 hover:text-blue-600 hover:bg-blue-50 transition-all"
                    @click="$emit('create-card')"
                    v-tooltip.bottom="$t('dashboard.create_new_card')"
                >
                    <i class="pi pi-plus text-sm"></i>
                </button>
            </div>
            <!-- Multi-Select Mode Header -->
            <div v-else class="flex items-center gap-2">
                <button @click="exitMultiSelectMode"
                    class="flex items-center justify-center w-7 h-7 rounded-md hover:bg-slate-100 transition-colors">
                    <i class="pi pi-arrow-left text-slate-600 text-sm"></i>
                </button>
                <span class="text-sm font-medium text-slate-700 truncate">
                    {{ selectedCards.size > 0 ? $t('dashboard.n_selected', { count: selectedCards.size }) : $t('dashboard.select_cards') }}
                </span>
                <div class="flex-1"></div>
                <button @click="toggleSelectAll(!allSelected)"
                    class="text-xs font-medium text-blue-600 hover:text-blue-700 px-2 py-1 rounded-md hover:bg-blue-50 transition-colors">
                    {{ allSelected ? $t('dashboard.deselect_all') : $t('dashboard.select_all') }}
                </button>
            </div>
        </div>

        <!-- More Menu Popover -->
        <Popover ref="moreMenu">
            <div class="w-48 py-1">
                <button
                    @click="openTemplateLibrary(); moreMenu.hide()"
                    class="w-full flex items-center gap-2.5 px-3 py-2 text-left text-sm text-slate-700 hover:bg-slate-50 transition-colors"
                >
                    <i class="pi pi-book text-emerald-600 text-xs"></i>
                    {{ $t('templates.browse_templates') }}
                </button>
                <button
                    @click="openRegularImport(); moreMenu.hide()"
                    class="w-full flex items-center gap-2.5 px-3 py-2 text-left text-sm text-slate-700 hover:bg-slate-50 transition-colors"
                >
                    <i class="pi pi-upload text-blue-600 text-xs"></i>
                    {{ $t('dashboard.import_cards') }}
                </button>
                <div v-if="cards.length > 0" class="border-t border-slate-100 my-1"></div>
                <button
                    v-if="cards.length > 0"
                    @click="enterMultiSelectMode(); moreMenu.hide()"
                    class="w-full flex items-center gap-2.5 px-3 py-2 text-left text-sm text-slate-700 hover:bg-slate-50 transition-colors"
                >
                    <i class="pi pi-check-square text-slate-500 text-xs"></i>
                    {{ $t('dashboard.multi_select') }}
                </button>
            </div>
        </Popover>

        <!-- Search + Filters (only when cards exist) -->
        <div v-if="cards.length > 0" class="px-3 py-2 border-b border-slate-100 space-y-2">
            <IconField class="w-full">
                <InputIcon class="pi pi-search" />
                <InputText
                    class="w-full text-sm"
                    :model-value="searchQuery"
                    @update:model-value="$emit('update:searchQuery', $event)"
                    :placeholder="$t('dashboard.search_cards')"
                />
            </IconField>
            <div v-if="showFilters" class="flex items-center gap-1.5">
                <Select
                    :model-value="selectedYear"
                    @update:model-value="$emit('update:selectedYear', $event)"
                    :options="yearOptions" optionLabel="label" optionValue="value"
                    :placeholder="$t('dashboard.year')" showClear
                    class="flex-1 min-w-0 text-xs" />
                <Select
                    :model-value="selectedMonth"
                    @update:model-value="$emit('update:selectedMonth', $event)"
                    :options="monthOptions" optionLabel="label" optionValue="value"
                    :placeholder="$t('dashboard.month')" showClear
                    :disabled="!selectedYear"
                    class="flex-1 min-w-0 text-xs" />
                <button v-if="hasActiveFilters"
                    @click="$emit('clear-filters')"
                    class="flex items-center justify-center w-7 h-7 rounded-md text-slate-400 hover:text-red-500 hover:bg-red-50 transition-all flex-shrink-0">
                    <i class="pi pi-times text-xs"></i>
                </button>
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
            <div class="space-y-3">
                <p class="text-sm text-slate-600 mb-4">{{ $t('dashboard.exporting_n_cards', { count: selectedCards.size }) }}</p>
                <div
                    class="flex items-center gap-3 p-3 rounded-lg border border-slate-200 cursor-pointer transition-all hover:border-blue-300 hover:bg-blue-50"
                    @click="doExport(true)"
                >
                    <div class="w-10 h-10 rounded-lg flex items-center justify-center flex-shrink-0 bg-blue-100 text-blue-600">
                        <i class="pi pi-file text-lg"></i>
                    </div>
                    <div class="flex-1 min-w-0">
                        <h4 class="font-medium text-slate-900 text-sm">{{ $t('dashboard.export_single_file') }}</h4>
                        <p class="text-xs text-slate-500 mt-0.5">{{ $t('dashboard.export_single_file_desc') }}</p>
                    </div>
                    <i class="pi pi-chevron-right text-slate-400"></i>
                </div>
                <div
                    class="flex items-center gap-3 p-3 rounded-lg border border-slate-200 cursor-pointer transition-all hover:border-blue-300 hover:bg-blue-50"
                    @click="doExport(false)"
                >
                    <div class="w-10 h-10 rounded-lg flex items-center justify-center flex-shrink-0 bg-emerald-100 text-emerald-600">
                        <i class="pi pi-folder text-lg"></i>
                    </div>
                    <div class="flex-1 min-w-0">
                        <h4 class="font-medium text-slate-900 text-sm">{{ $t('dashboard.export_separate_files') }}</h4>
                        <p class="text-xs text-slate-500 mt-0.5">{{ $t('dashboard.export_separate_files_desc') }}</p>
                    </div>
                    <i class="pi pi-chevron-right text-slate-400"></i>
                </div>
            </div>
        </Dialog>

        <!-- Loading State -->
        <div v-if="loading" class="flex items-center justify-center p-8 h-full min-h-[320px]">
            <div class="text-center">
                <i class="pi pi-spin pi-spinner text-3xl text-blue-600 mb-4"></i>
                <p class="text-sm text-slate-500">{{ $t('dashboard.loading_cards') }}</p>
            </div>
        </div>

        <!-- Empty State -->
        <div v-else-if="cards.length === 0 && !searchQuery" class="flex flex-col items-center justify-center p-6 py-12 text-center h-full min-h-[320px]">
            <div class="w-16 h-16 bg-slate-100 rounded-full flex items-center justify-center mx-auto mb-4">
                <i class="pi pi-id-card text-2xl text-slate-400"></i>
            </div>
            <h3 class="text-lg font-medium text-slate-900 mb-2">{{ $t('dashboard.no_cards_yet') }}</h3>
            <p class="text-sm text-slate-500 mb-6">{{ $t('dashboard.start_creating') }}</p>
            <Button
                :label="$t('dashboard.create_new_card')"
                icon="pi pi-plus"
                @click="$emit('create-card')"
                severity="primary"
            />
        </div>

        <!-- No Search Results -->
        <div v-else-if="filteredCards.length === 0 && searchQuery" class="flex flex-col items-center p-6 py-8 text-center">
            <div class="w-14 h-14 bg-slate-100 rounded-full flex items-center justify-center mb-3">
                <i class="pi pi-search text-xl text-slate-400"></i>
            </div>
            <h3 class="text-base font-medium text-slate-900 mb-1">{{ $t('dashboard.no_results_found') }}</h3>
            <p class="text-sm text-slate-500">{{ $t('dashboard.no_cards_match_search') }}</p>
        </div>

        <!-- Cards List -->
        <div v-else-if="cards.length > 0" class="flex-1 overflow-y-auto">
            <div class="space-y-1.5 p-2">
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

            <!-- Floating Action Bar (Multi-select mode) -->
            <Transition name="slide-up">
                <div v-if="multiSelectMode && selectedCards.size > 0" class="floating-action-bar-container">
                    <div class="floating-action-bar">
                        <button @click="showExportOptions = true" class="action-btn action-btn-primary">
                            <i class="pi pi-download"></i>
                            <span>{{ $t('common.export') }}</span>
                        </button>
                        <button @click="confirmDeleteSelected" class="action-btn action-btn-danger">
                            <i class="pi pi-trash"></i>
                            <span>{{ $t('common.delete') }}</span>
                        </button>
                    </div>
                </div>
            </Transition>
        </div>

        <!-- Paginator -->
        <div v-if="totalRecords > itemsPerPage" class="px-2 py-1.5 border-t border-slate-200 bg-white flex-shrink-0">
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
import Button from 'primevue/button';
import IconField from 'primevue/iconfield';
import InputIcon from 'primevue/inputicon';
import InputText from 'primevue/inputtext';
import Select from 'primevue/select';
import Paginator from 'primevue/paginator';
import Dialog from 'primevue/dialog';
import Popover from 'primevue/popover';
import CardListItem from './CardListItem.vue';
import CardBulkImport from './Import/CardBulkImport.vue';
import { TemplateLibrary } from '@/components/TemplateLibrary';

const { t } = useI18n();
const confirm = useConfirm();
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
    projectCount: {
        type: Number,
        default: 0
    },
    projectLimit: {
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
    'clear-filters',
    'page-change',
    'cards-imported',
    'delete-cards',
    'export-cards'
]);

// UI state
const showFilters = ref(false);
const showImportDialog = ref(false);
const showTemplateDialog = ref(false);
const showExportOptions = ref(false);
const moreMenu = ref(null);

// Multi-select state
const multiSelectMode = ref(false);
const selectedCards = ref(new Set());

// Computed
const hasActiveFilters = computed(() => {
    return props.selectedYear !== null || props.selectedMonth !== null;
});

const allSelected = computed(() => {
    if (props.filteredCards.length === 0) return false;
    return props.filteredCards.every(card => selectedCards.value.has(card.id));
});

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

// More menu
function toggleMoreMenu(event) {
    moreMenu.value.toggle(event);
}

// Dialogs
function openTemplateLibrary() {
    showTemplateDialog.value = true;
}

function openRegularImport() {
    showImportDialog.value = true;
}

function handleImportComplete(results) {
    showImportDialog.value = false;
    emit('cards-imported', results);
}

function handleTemplateImport(results) {
    showTemplateDialog.value = false;
    emit('cards-imported', results);
}

// Multi-select
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
        const newSet = new Set();
        props.filteredCards.forEach(card => newSet.add(card.id));
        selectedCards.value = newSet;
    } else {
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
</script>

<style scoped>
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

.slide-up-enter-active,
.slide-up-leave-active {
    transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
}

.slide-up-enter-from,
.slide-up-leave-to {
    transform: translateY(100%);
    opacity: 0;
}

:deep(.import-dialog .p-dialog-content) {
    padding: 0;
}

@media (max-width: 640px) {
    .floating-action-bar {
        @apply gap-1.5 px-1.5 py-1.5;
    }

    .action-btn {
        @apply px-3 py-1.5 text-xs gap-1.5;
    }
}
</style>
