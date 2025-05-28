<template>
    <div class="space-y-6">
        <!-- Page Header -->
        <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
            <div>
                <h1 class="text-2xl font-bold text-slate-900">Card Designs</h1>
                <p class="text-slate-600 mt-1">Create and manage your card templates</p>
            </div>
            <Button 
                icon="pi pi-plus" 
                label="Create New Card" 
                severity="primary" 
                @click="showAddCardDialog = true" 
                class="shadow-lg hover:shadow-xl transition-shadow"
            />
        </div>
        
        <!-- Add Card Dialog -->
        <MyDialog 
            v-model="showAddCardDialog"
            modal
            header="Create New Card"
            :confirmHandle="handleAddCard"
            confirmLabel="Create Card"
            confirmSeverity="success"
            successMessage="Card created successfully!"
            errorMessage="Failed to create card"
            @hide="onDialogHide"
        >
            <CardCreateEditView ref="cardCreateEditRef" modeProp="create" />
        </MyDialog>

        <!-- PrimeVue ConfirmDialog for delete confirmation -->
        <ConfirmDialog group="deleteCardConfirmation"></ConfirmDialog>

        <div class="grid grid-cols-1 xl:grid-cols-4 gap-6 min-h-[calc(100vh-200px)]">
            <!-- Card Designs List -->
            <div class="xl:col-span-1 bg-white rounded-xl shadow-lg border border-slate-200 flex flex-col overflow-hidden"> 
                <div class="p-4 border-b border-slate-200 bg-gradient-to-r from-slate-50 to-slate-100">
                    <div class="flex items-center justify-between mb-3">
                        <h2 class="text-lg font-semibold text-slate-900">Your Cards</h2>
                        <span class="bg-blue-100 text-blue-800 text-xs font-medium px-2.5 py-0.5 rounded-full">
                            {{ cards.length }}
                        </span>
                    </div>
                    
                    <!-- Search -->
                    <IconField>
                        <InputIcon class="pi pi-search" />
                        <InputText 
                            class="w-full" 
                            v-model="search" 
                            placeholder="Search cards..." 
                        />
                    </IconField>
                    
                    <!-- Date Filters -->
                    <div class="mt-3 grid grid-cols-2 gap-2">
                        <Dropdown 
                            v-model="selectedYear"
                            :options="yearOptions" 
                            optionLabel="label" 
                            optionValue="value"
                            placeholder="Year"
                            showClear
                            class="w-full text-sm"
                        />
                        <Dropdown 
                            v-model="selectedMonth"
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
                        @click="clearDateFilters"
                        text
                        size="small"
                        class="w-full mt-2 text-blue-600"
                    />
                </div>

                <!-- Empty State -->
                <div v-if="cards.length === 0" class="flex-1 flex flex-col items-center justify-center p-8 text-center">
                    <div class="w-16 h-16 bg-slate-100 rounded-full flex items-center justify-center mb-4">
                        <i class="pi pi-id-card text-2xl text-slate-400"></i>
                    </div>
                    <h3 class="text-lg font-medium text-slate-900 mb-2">No Cards Yet</h3>
                    <p class="text-slate-500 mb-4">Create your first card design to get started</p>
                    <Button 
                        icon="pi pi-plus" 
                        label="Create Card"
                        @click="showAddCardDialog = true"
                    />
                </div>

                <!-- Cards List -->
                <div v-if="cards.length > 0" class="flex-1 overflow-y-auto">
                    <div class="p-2 space-y-2">
                        <div 
                            v-for="(card, index) in paginatedCards" 
                            :key="card.id" 
                            class="group relative p-4 rounded-lg border border-slate-200 cursor-pointer transition-all duration-200 hover:shadow-md hover:border-blue-300"
                            :class="{ 
                                'bg-blue-50 border-blue-300 shadow-md': selectedCard === cards.findIndex(c => c.id === card.id),
                                'bg-white hover:bg-slate-50': selectedCard !== cards.findIndex(c => c.id === card.id)
                            }"
                            @click="setSelectedCardById(card.id)"
                        >
                            <div class="flex items-start gap-3">
                                <!-- Card Thumbnail -->
                                <div class="flex-shrink-0 w-12 h-16 bg-slate-100 rounded-lg overflow-hidden border border-slate-200">
                                    <img
                                        :src="card.image_urls && card.image_urls.length > 0 ? card.image_urls[0] : cardPlaceholder"
                                        :alt="card.name"
                                        class="w-full h-full object-cover"
                                    />
                                </div>
                                
                                <!-- Card Info -->
                                <div class="flex-1 min-w-0">
                                    <h3 class="font-medium text-slate-900 truncate group-hover:text-blue-600 transition-colors">
                                        {{ card.name }}
                                    </h3>
                                    <p class="text-sm text-slate-500 mt-1">
                                        Created {{ formatDate(card.created_at) }}
                                    </p>
                                    <div class="flex items-center gap-2 mt-2">
                                        <Tag 
                                            :value="card.published ? 'Published' : 'Draft'" 
                                            :severity="card.published ? 'success' : 'info'" 
                                            class="px-2 py-0.5"
                                        />
                                    </div>
                                </div>
                            </div>
                            
                            <!-- Selection Indicator -->
                            <div v-if="selectedCard === cards.findIndex(c => c.id === card.id)" class="absolute top-2 right-2">
                                <div class="w-3 h-3 bg-blue-500 rounded-full"></div>
                            </div>
                        </div>
                    </div>
                    <!-- Paginator -->
                    <div v-if="totalFilteredRecords > itemsPerPage" class="p-2 border-t border-slate-200">
                        <Paginator 
                            :rows="itemsPerPage" 
                            :totalRecords="totalFilteredRecords" 
                            :first="currentPageFirstRecord"
                            @page="onPageChange"
                            template="FirstPageLink PrevPageLink CurrentPageReport NextPageLink LastPageLink"
                            class="text-sm"
                        />
                    </div>
                </div>
            </div>

            <!-- Card Details Preview -->
            <div class="xl:col-span-3 bg-white rounded-xl shadow-lg border border-slate-200 flex flex-col overflow-hidden">
                <!-- Empty State -->
                <div v-if="selectedCard === null" class="flex-1 flex items-center justify-center">
                    <div class="text-center">
                        <div class="w-20 h-20 bg-slate-100 rounded-full flex items-center justify-center mx-auto mb-4">
                            <i class="pi pi-id-card text-3xl text-slate-400"></i>
                        </div>
                        <h3 class="text-xl font-medium text-slate-900 mb-2">Select a Card Design</h3>
                        <p class="text-slate-500">Choose a card from the list to view and edit its details</p>
                    </div>
                </div>

                <!-- Card Details -->
                <div v-else class="flex-1 flex flex-col">
                    <!-- Card Header -->
                    <div class="p-6 border-b border-slate-200 bg-gradient-to-r from-slate-50 to-slate-100">
                        <div class="flex items-center justify-between">
                            <div>
                                <h2 class="text-xl font-semibold text-slate-900">{{ cards[selectedCard].name }}</h2>
                                <p class="text-slate-600 mt-1">Manage your card design and content</p>
                            </div>
                            <div class="flex items-center gap-2">
                                <span class="inline-flex items-center px-3 py-1 rounded-full text-sm font-medium bg-green-100 text-green-800">
                                    <i class="pi pi-check-circle mr-1"></i>
                                    Active
                                </span>
                            </div>
                        </div>
                    </div>

                    <!-- Tabs -->
                    <Tabs value="0" class="flex-1 flex flex-col">
                        <TabList class="flex-shrink-0 border-b border-slate-200 bg-white px-6">
                            <Tab v-for="(tabLabel, index) in tabs" :key="index" :value="index.toString()" 
                                 class="px-4 py-3 font-medium text-slate-600 hover:text-slate-900 transition-colors">
                                <i :class="getTabIcon(index)" class="mr-2"></i>
                                {{ tabLabel }}
                            </Tab>
                        </TabList>
                        <TabPanels class="flex-1 overflow-hidden">
                            <TabPanel v-for="(tabLabel, index) in tabs" :value="index.toString()" class="h-full">
                                <div class="h-full overflow-y-auto p-6">
                                    <CardGeneral 
                                        v-if="index === 0"
                                        :cardProp="cards[selectedCard]"
                                        @update-card="handleCardUpdateFromGeneral"
                                        @cancel-edit="handleCardCancelFromGeneral"
                                        @delete-card-requested="triggerDeleteConfirmation"
                                    />
                                    <CardContent v-if="index === 1" :cardId="cards[selectedCard].id" :key="cards[selectedCard].id + '-content'" />
                                    <CardIssurance v-if="index === 2" :cardId="cards[selectedCard].id" :key="cards[selectedCard].id + '-issurance'" />
                                </div>
                            </TabPanel>
                        </TabPanels>
                    </Tabs>
                </div>
            </div>
        </div>
    </div>
</template>

<script setup>
import Button from 'primevue/button';
import IconField from 'primevue/iconfield';
import InputIcon from 'primevue/inputicon';
import InputText from 'primevue/inputtext';
import { ref, onMounted, computed, watch } from 'vue';
import cardPlaceholder from '@/assets/images/card-placeholder.jpg';
import Tabs from 'primevue/tabs';
import TabList from 'primevue/tablist';
import Tab from 'primevue/tab';
import TabPanels from 'primevue/tabpanels';
import TabPanel from 'primevue/tabpanel';
import CardGeneral from '@/components/Card.vue/Card.vue';
import CardContent from '@/components/CardContent/CardContent.vue';
import CardIssurance from '@/components/CardIssurance.vue';
import MyDialog from '@/components/MyDialog.vue';
import CardCreateEditView from '@/components/Card.vue/CardCreateEditView.vue';
import { useCardStore } from '@/stores/card';
import { storeToRefs } from 'pinia';
import ConfirmDialog from 'primevue/confirmdialog';
import { useConfirm } from "primevue/useconfirm";
import { useToast } from "primevue/usetoast";
import Dropdown from 'primevue/dropdown';
import Paginator from 'primevue/paginator';
import Tag from 'primevue/tag';

const cardStore = useCardStore();
const { cards } = storeToRefs(cardStore);
const confirm = useConfirm();
const toast = useToast();

const search = ref('');
const selectedCard = ref(null);
const showAddCardDialog = ref(false);
const cardCreateEditRef = ref(null);

// Date Filters
const selectedYear = ref(null);
const selectedMonth = ref(null);

// Pagination
const currentPageFirstRecord = ref(0); // PrimeVue Paginator uses 'first' for the index of the first record
const itemsPerPage = ref(5);

const yearOptions = computed(() => {
    if (!cards.value || cards.value.length === 0) return [];
    const years = new Set(cards.value.map(card => new Date(card.created_at).getFullYear()));
    return Array.from(years).sort((a, b) => b - a).map(year => ({ label: year.toString(), value: year }));
});

const monthOptions = computed(() => {
    if (!cards.value || cards.value.length === 0) return [];
    const months = new Set();
    cards.value.forEach(card => {
        if (!selectedYear.value || new Date(card.created_at).getFullYear() === selectedYear.value) {
            months.add(new Date(card.created_at).getMonth());
        }
    });
    return Array.from(months).sort((a, b) => a - b).map(month => ({ 
        label: new Date(0, month).toLocaleString('default', { month: 'long' }), 
        value: month 
    }));
});

// Computed property for filtered cards (before pagination)
const filteredCards = computed(() => {
    let tempCards = cards.value;

    // Filter by search text
    if (search.value) {
        tempCards = tempCards.filter(card => 
            card.name.toLowerCase().includes(search.value.toLowerCase())
        );
    }

    // Filter by year
    if (selectedYear.value !== null) {
        tempCards = tempCards.filter(card => new Date(card.created_at).getFullYear() === selectedYear.value);
    }

    // Filter by month
    if (selectedMonth.value !== null) {
        tempCards = tempCards.filter(card => new Date(card.created_at).getMonth() === selectedMonth.value);
    }
    // When filters change, reset to the first page
    // Vue's reactivity might make direct assignment tricky here, 
    // consider watching filteredCards.length and resetting currentPageFirstRecord if it changes
    // For now, we'll rely on the user to navigate back if needed, or implement a watcher later.
    return tempCards;
});

const totalFilteredRecords = computed(() => filteredCards.value.length);

const paginatedCards = computed(() => {
    const start = currentPageFirstRecord.value;
    const end = start + itemsPerPage.value;
    return filteredCards.value.slice(start, end);
});

// Watch for filter changes to reset pagination
watch([search, selectedYear, selectedMonth], () => {
    currentPageFirstRecord.value = 0;
});

const onPageChange = (event) => {
    currentPageFirstRecord.value = event.first;
    // itemsPerPage.value = event.rows; // If you want to allow changing items per page via paginator
};

// Fetch cards when component mounts
onMounted(async () => {
    await cardStore.fetchCards();
});

const setSelectedCardById = (cardId) => {
    selectedCard.value = cards.value.findIndex(card => card.id === cardId);
}

const formatDate = (dateString) => {
    return new Date(dateString).toLocaleDateString('en-US', {
        year: 'numeric',
        month: 'short',
        day: 'numeric'
    });
};

const getTabIcon = (index) => {
    const icons = ['pi pi-cog', 'pi pi-file-edit', 'pi pi-send'];
    return icons[index] || 'pi pi-circle';
};

const clearDateFilters = () => {
    selectedYear.value = null;
    selectedMonth.value = null;
};

const handleAddCard = async () => {
    if (!cardCreateEditRef.value) {
        console.error("CardCreateEditView reference is not available.");
        return Promise.reject("Form component not ready.");
    }
    try {
        const payload = cardCreateEditRef.value.getPayload();
        if (!payload.name) {
            toast.add({ severity: 'warn', summary: 'Validation Error', detail: 'Card name is required.', life: 3000 });
            return Promise.reject("Card name is required.");
        }
        
        await cardStore.addCard(payload);
        await cardStore.fetchCards();
        return Promise.resolve(); 
    } catch (error) {
        console.error("Failed to add card:", error);
        return Promise.reject(typeof error === 'string' ? error : (error.message || 'Failed to create card'));
    }
};

const onDialogHide = () => {
    if (cardCreateEditRef.value && typeof cardCreateEditRef.value.resetFormForCreate === 'function') {
        cardCreateEditRef.value.resetFormForCreate();
    }
};

const handleCardUpdateFromGeneral = async (payload) => {
    try {
        const cardId = cards.value[selectedCard.value].id;
        await cardStore.updateCard(cardId, payload);
        await cardStore.fetchCards();
        toast.add({ severity: 'success', summary: 'Updated', detail: `Card "${payload.name}" updated successfully.`, life: 3000 });
    } catch (error) {
        console.error('Failed to update card:', error);
        toast.add({ severity: 'error', summary: 'Error', detail: 'Failed to update card.', life: 3000 });
    }
};

const handleCardCancelFromGeneral = () => {
    // Handle cancel edit if needed
};

const tabs = ref(['General', 'Content', 'Issuance']);

const triggerDeleteConfirmation = (cardId) => {
    const cardToDelete = cards.value.find(card => card.id === cardId);
    if (!cardToDelete) {
        toast.add({ severity: 'error', summary: 'Error', detail: 'Card not found for deletion.', life: 3000 });
        return;
    }

    confirm.require({
        group: 'deleteCardConfirmation',
        message: `Are you sure you want to delete the card "${cardToDelete.name}"? This action cannot be undone.`,
        header: 'Confirm Deletion',
        icon: 'pi pi-exclamation-triangle',
        acceptLabel: 'Delete',
        rejectLabel: 'Cancel',
        acceptClass: 'p-button-danger',
        accept: async () => {
            try {
                await cardStore.deleteCard(cardId);
                toast.add({ severity: 'success', summary: 'Deleted', detail: `Card "${cardToDelete.name}" deleted successfully.`, life: 3000 });
                await cardStore.fetchCards();
                if (selectedCard.value === cards.value.findIndex(c => c.id === cardId)) {
                    selectedCard.value = null;
                }
            } catch (error) {
                console.error('Failed to delete card:', error);
                toast.add({ severity: 'error', summary: 'Error', detail: 'Failed to delete card.', life: 3000 });
            }
        },
        reject: () => {
            toast.add({ severity: 'info', summary: 'Cancelled', detail: 'Deletion cancelled.', life: 3000 });
        }
    });
};
</script>

<style scoped>
/* Custom tab styling */
:deep(.p-tabs-nav) {
    background: transparent;
    border: none;
}

:deep(.p-tabs-tab) {
    background: transparent;
    border: none;
    border-bottom: 2px solid transparent;
}

:deep(.p-tabs-tab:hover) {
    background: rgba(59, 130, 246, 0.05);
}

:deep(.p-tabs-tab[aria-selected="true"]) {
    background: transparent;
    border-bottom-color: #3b82f6;
    color: #3b82f6;
}

/* Smooth transitions */
.group {
    transition: all 0.2s ease-in-out;
}
</style>
