<template>
    <div class="bg-white rounded-xl shadow-lg border border-slate-200 flex flex-col overflow-hidden"> 
        <!-- Header -->
        <div class="p-4 border-b border-slate-200 bg-white">
            <div class="flex items-center justify-between mb-3">
                <h1 class="text-2xl font-bold text-slate-900">Card Designs</h1>
                <Button 
                    icon="pi pi-plus" 
                    @click="$emit('create-card')" 
                    rounded
                    text
                    aria-label="Create New Card"
                    v-tooltip.top="'Create New Card'"
                />
            </div>
            <p class="text-slate-600 -mt-2 mb-4 text-sm">Create and manage your templates.</p>
            
            <!-- Search -->
            <IconField>
                <InputIcon class="pi pi-search" />
                <InputText 
                    class="w-full" 
                    :model-value="searchQuery" 
                    @update:model-value="$emit('update:searchQuery', $event)"
                    placeholder="Search cards..." 
                />
            </IconField>
            
            <!-- Import & Example Buttons -->
            <div class="mt-4 space-y-2">
                <div class="relative">
                    <Button 
                        label="Try Example"
                        icon="pi pi-star"
                        @click="openExampleImport"
                        class="w-full bg-gradient-to-r from-emerald-600 to-blue-600 hover:from-emerald-700 hover:to-blue-700 text-white border-0 font-semibold shadow-sm"
                    />
                    <!-- NEW Badge -->
                    <div class="absolute -top-1 -right-1 bg-yellow-400 text-yellow-900 text-xs px-1.5 py-0.5 rounded-full font-bold text-[10px] leading-tight">
                        NEW
                    </div>
                </div>
                <Button 
                    label="Import Cards"
                    icon="pi pi-upload"
                    @click="openRegularImport"
                    class="w-full bg-blue-600 hover:bg-blue-700 text-white border-0"
                />
            </div>
            
            <!-- Import Dialog -->
            <Dialog 
                v-model:visible="showImportDialog"
                modal 
                :header="importDialogTitle"
                :style="{ width: '90vw', maxWidth: '50rem' }"
                :breakpoints="{ '1199px': '85vw', '768px': '95vw', '575px': '98vw' }"
                class="import-dialog standardized-dialog"
            >
                <CardBulkImport :mode="importMode" @imported="handleImportComplete" />
            </Dialog>
            
            <!-- Date Filters -->
            <div class="mt-3 grid grid-cols-2 gap-2">
                <Dropdown 
                    :model-value="selectedYear"
                    @update:model-value="$emit('update:selectedYear', $event)"
                    :options="yearOptions" 
                    optionLabel="label" 
                    optionValue="value"
                    placeholder="Year"
                    showClear
                    class="w-full text-sm"
                />
                <Dropdown 
                    :model-value="selectedMonth"
                    @update:model-value="$emit('update:selectedMonth', $event)"
                    :options="monthOptions" 
                    optionLabel="label" 
                    optionValue="value"
                    placeholder="Month"
                    showClear
                    :disabled="!selectedYear" 
                    class="w-full text-sm"
                />
            </div>
            <Button 
                v-if="selectedYear || selectedMonth"
                label="Clear Date Filters"
                icon="pi pi-times"
                @click="$emit('clear-date-filters')"
                text
                size="small"
                class="w-full mt-2 text-blue-600"
            />
        </div>

        <!-- Optimized Empty State -->
        <div v-if="cards.length === 0 && !searchQuery" class="flex-1 flex flex-col justify-center p-4 text-center min-h-[400px]">
            <!-- Compact Header -->
            <div class="w-16 h-16 bg-slate-100 rounded-full flex items-center justify-center mx-auto mb-4">
                <i class="pi pi-id-card text-2xl text-slate-400"></i>
            </div>
            <h3 class="text-xl font-semibold text-slate-900 mb-2">No Cards Yet</h3>
            <p class="text-slate-500 mb-8">Start by creating your first card design</p>
            
            <!-- Primary Action -->
            <div class="mb-6">
                <Button 
                    label="Create New Card"
                    icon="pi pi-plus"
                    @click="$emit('create-card')"
                    class="bg-blue-600 hover:bg-blue-700 text-white border-0 px-8 py-3 text-lg font-semibold shadow-lg hover:shadow-xl transition-all"
                />
            </div>
            
        </div>

        <!-- No Search Results -->
        <div v-if="filteredCards.length === 0 && searchQuery" class="flex-1 flex flex-col items-center justify-center p-8 text-center">
            <div class="w-16 h-16 bg-slate-100 rounded-full flex items-center justify-center mb-4">
                <i class="pi pi-search-slash text-2xl text-slate-400"></i>
            </div>
            <h3 class="text-lg font-medium text-slate-900 mb-2">No Results Found</h3>
            <p class="text-slate-500 mb-4">No cards match your search criteria.</p>
        </div>

        <!-- Cards List -->
        <div v-if="cards.length > 0" class="flex-1 overflow-y-auto">
            <div class="p-2 space-y-2">
                <CardListItem
                    v-for="card in paginatedCards" 
                    :key="card.id"
                    :card="card"
                    :isSelected="selectedCardId === card.id"
                    @select="$emit('select-card', card.id)"
                />
            </div>
            
            <!-- Paginator -->
            <div v-if="totalRecords > itemsPerPage" class="p-2 border-t border-slate-200">
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
    </div>
</template>

<script setup>
import { computed, ref } from 'vue';
import Button from 'primevue/button';
import IconField from 'primevue/iconfield';
import InputIcon from 'primevue/inputicon';
import InputText from 'primevue/inputtext';
import Dropdown from 'primevue/dropdown';
import Paginator from 'primevue/paginator';
import Dialog from 'primevue/dialog';
import CardListItem from './CardListItem.vue';
import CardBulkImport from './Import/CardBulkImport.vue';

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
    }
});

const emit = defineEmits([
    'create-card',
    'select-card',
    'update:searchQuery',
    'update:selectedYear',
    'update:selectedMonth',
    'clear-date-filters',
    'page-change',
    'cards-imported'
]);

// Dialog state
const showImportDialog = ref(false);
const importMode = ref('regular'); // 'regular' or 'example'

// Computed dialog title
const importDialogTitle = computed(() => {
    return importMode.value === 'example' ? 'Try Example Import' : 'Import Cards';
});

// Handle opening different import modes
function openExampleImport() {
    importMode.value = 'example';
    showImportDialog.value = true;
}

function openRegularImport() {
    importMode.value = 'regular';
    showImportDialog.value = true;
}

// Handle import completion
function handleImportComplete(results) {
    showImportDialog.value = false;
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
    const months = [
        { label: 'January', value: 0 },
        { label: 'February', value: 1 },
        { label: 'March', value: 2 },
        { label: 'April', value: 3 },
        { label: 'May', value: 4 },
        { label: 'June', value: 5 },
        { label: 'July', value: 6 },
        { label: 'August', value: 7 },
        { label: 'September', value: 8 },
        { label: 'October', value: 9 },
        { label: 'November', value: 10 },
        { label: 'December', value: 11 }
    ];
    return months;
});
</script>

<style scoped>
/* Component uses global theme styles */


/* Custom import dialog styles */
:deep(.import-dialog .p-dialog-content) {
  padding: 0;
}
</style>