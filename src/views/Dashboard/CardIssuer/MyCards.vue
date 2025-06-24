<template>
    <div class="space-y-6">
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
            :showToasts="true"
            @hide="onDialogHide"
        >
            <CardCreateEditView ref="cardCreateEditRef" modeProp="create" />
        </MyDialog>

        <!-- PrimeVue ConfirmDialog for delete confirmation -->
        <ConfirmDialog group="deleteCardConfirmation"></ConfirmDialog>

        <div class="grid grid-cols-1 lg:grid-cols-4 gap-6 min-h-[calc(100vh-200px)]">
            <!-- Card Designs List -->
            <div class="lg:col-span-1 bg-white rounded-xl shadow-lg border border-slate-200 flex flex-col overflow-hidden"> 
                <div class="p-4 border-b border-slate-200 bg-white">
                    <div class="flex items-center justify-between mb-3">
                        <h1 class="text-2xl font-bold text-slate-900">Card Designs</h1>
                        <Button 
                            icon="pi pi-plus" 
                            @click="showAddCardDialog = true" 
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
                <div v-if="cards.length === 0 && !search" class="flex-1 flex flex-col items-center justify-center p-8 text-center">
                    <div class="w-16 h-16 bg-slate-100 rounded-full flex items-center justify-center mb-4">
                        <i class="pi pi-id-card text-2xl text-slate-400"></i>
                    </div>
                    <h3 class="text-lg font-medium text-slate-900 mb-2">No Cards Yet</h3>
                    <p class="text-slate-500 mb-4">Click the '+' button above to create one.</p>
                </div>

                <!-- No Search Results -->
                 <div v-if="filteredCards.length === 0 && search" class="flex-1 flex flex-col items-center justify-center p-8 text-center">
                    <div class="w-16 h-16 bg-slate-100 rounded-full flex items-center justify-center mb-4">
                        <i class="pi pi-search-slash text-2xl text-slate-400"></i>
                    </div>
                    <h3 class="text-lg font-medium text-slate-900 mb-2">No Results Found</h3>
                    <p class="text-slate-500 mb-4">No cards match your search criteria.</p>
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
            <div class="lg:col-span-3 bg-white rounded-xl shadow-lg border border-slate-200 flex flex-col overflow-hidden">
                <!-- NEW: Unified empty state for the details pane. It shows if no card is selected. -->
                <div v-if="selectedCard === null" class="flex-1 flex items-center justify-center p-8">
                    <div class="text-center">
                        <div class="w-20 h-20 bg-slate-100 rounded-full flex items-center justify-center mx-auto mb-4">
                            <i class="pi pi-id-card text-3xl text-slate-400"></i>
                        </div>
                        <h3 class="text-xl font-medium text-slate-900 mb-2">
                            {{ cards.length === 0 ? 'No Card Designs' : 'Select a Card Design' }}
                        </h3>
                        <p class="text-slate-500">
                            {{ cards.length === 0 ? 'Create your first card design by clicking the '+' button' : 'Choose a card from the list to view its details' }}
                        </p>
                    </div>
                </div>

                <!-- Card Details - now safely rendered only when a card is selected -->
                <div v-else class="flex-1 flex flex-col">
                    <!-- Card Header -->
                    <div class="p-6 border-b border-slate-200 bg-white">
                        <div class="flex items-center justify-between">
                            <div>
                                <h2 class="text-xl font-semibold text-slate-900">{{ cards[selectedCard].name }}</h2>
                                <p class="text-slate-600 mt-1">Manage your card design, content, and issuance.</p>
                            </div>
                            <div class="flex items-center gap-2">
                                 <Tag 
                                    :value="cards[selectedCard].published ? 'Published' : 'Draft'" 
                                    :severity="cards[selectedCard].published ? 'success' : 'info'" 
                                />
                            </div>
                        </div>
                    </div>

                    <!-- Tabs -->
                    <Tabs :value="activeTabString" @update:value="handleTabChange" class="flex-1 flex flex-col">
                        <TabList class="flex-shrink-0 border-b border-slate-200 bg-white px-6">
                            <Tab v-for="(tabLabel, index) in tabs" :key="index" :value="index.toString()" 
                                 class="px-4 py-3 font-medium text-sm text-slate-600 hover:text-slate-900 transition-colors">
                                <i :class="getTabIcon(index)" class="mr-2"></i>
                                {{ tabLabel }}
                            </Tab>
                        </TabList>
                        <TabPanels class="flex-1 overflow-hidden bg-slate-50">
                            <TabPanel v-for="(tabLabel, index) in tabs" :value="index.toString()" class="h-full">
                                <div class="h-full overflow-y-auto p-6">
                                    <CardGeneral 
                                        v-if="index === 0"
                                        :cardProp="cards[selectedCard]"
                                        @update-card="handleCardUpdateFromGeneral(cards[selectedCard].id, $event)"
                                        @cancel-edit="handleCardCancelFromGeneral"
                                        @delete-card-requested="triggerDeleteConfirmation"
                                    />
                                    <CardContent v-if="index === 1" :cardId="cards[selectedCard].id" :cardAiEnabled="cards[selectedCard].conversation_ai_enabled" :key="cards[selectedCard].id + '-content'" />
                                    <CardIssurance v-if="index === 2" :cardId="cards[selectedCard].id" :key="cards[selectedCard].id + '-issurance'" />
                                    <MobilePreview 
                                        v-if="index === 3" 
                                        :cardProp="cards[selectedCard]" 
                                        :key="cards[selectedCard].id + '-mobile-preview'"
                                        @publish-card="handlePublishCard"
                                        @switch-to-issuance="handleSwitchToIssuance"
                                    />
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
import { useRoute, useRouter } from 'vue-router';
import cardPlaceholder from '@/assets/images/card-placeholder.jpg';
import Tabs from 'primevue/tabs';
import TabList from 'primevue/tablist';
import Tab from 'primevue/tab';
import TabPanels from 'primevue/tabpanels';
import TabPanel from 'primevue/tabpanel';
import CardGeneral from '@/components/Card.vue/Card.vue';
import CardContent from '@/components/CardContent/CardContent.vue';
import CardIssurance from '@/components/CardIssurance.vue';
import MobilePreview from '@/components/Card.vue/MobilePreview.vue';
import MyDialog from '@/components/MyDialog.vue';
import CardCreateEditView from '@/components/Card.vue/CardCreateEditView.vue';
import { useCardStore } from '@/stores/card.js';
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
const route = useRoute();
const router = useRouter();

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

// Watch for route changes (browser back/forward)
watch(
    () => route.query,
    (newQuery, oldQuery) => {
        if (newQuery.cardId !== oldQuery.cardId || newQuery.tab !== oldQuery.tab) {
            initializeFromURL();
        }
    }
);

// Watch for cards being loaded to initialize from URL
watch(
    () => cards.value.length,
    (newLength) => {
        if (newLength > 0) {
            initializeFromURL();
        }
    }
);

const onPageChange = (event) => {
    currentPageFirstRecord.value = event.first;
    // itemsPerPage.value = event.rows; // If you want to allow changing items per page via paginator
};

// Fetch cards when component mounts
onMounted(async () => {
    await cardStore.fetchCards();
    initializeFromURL();
});

const setSelectedCardById = (cardId) => {
    const cardIndex = cards.value.findIndex(card => card.id === cardId);
    if (cardIndex !== -1) {
        selectedCard.value = cardIndex;
        // Update URL to reflect the selected card
        updateURL(cardId, activeTab.value);
    }
};

// Update URL with card and tab parameters
const updateURL = (cardId = null, tab = 0) => {
    const currentCardId = cardId || (selectedCard.value !== null ? cards.value[selectedCard.value]?.id : null);
    const query = {};
    
    if (currentCardId) {
        query.cardId = currentCardId;
    }
    
    if (tab > 0) {
        query.tab = getTabName(tab);
    }
    
    // Only update if the URL would actually change
    if (route.query.cardId !== query.cardId || route.query.tab !== query.tab) {
        router.replace({ 
            name: route.name, 
            query: query 
        });
    }
};

// Convert tab index to tab name for URL
const getTabName = (tabIndex) => {
    const tabNames = ['general', 'content', 'issuance', 'preview'];
    return tabNames[tabIndex] || 'general';
};

// Convert tab name from URL to tab index
const getTabIndex = (tabName) => {
    const tabNames = ['general', 'content', 'issuance', 'preview'];
    const index = tabNames.indexOf(tabName);
    return index !== -1 ? index : 0;
};

// Handle tab changes and update URL
const handleTabChange = (value) => {
    const tabIndex = parseInt(value);
    activeTab.value = tabIndex;
    updateURL(null, tabIndex);
};

// Initialize from URL parameters
const initializeFromURL = () => {
    // Initialize tab from URL
    if (route.query.tab) {
        activeTab.value = getTabIndex(route.query.tab);
    }
    
    // Initialize selected card from URL
    if (route.query.cardId && cards.value.length > 0) {
        const cardIndex = cards.value.findIndex(card => card.id === route.query.cardId);
        if (cardIndex !== -1) {
            selectedCard.value = cardIndex;
        } else {
            // Card ID in URL doesn't exist, clear it
            if (route.query.cardId) {
                router.replace({ name: route.name, query: {} });
            }
        }
    }
};

const formatDate = (dateString) => {
    return new Date(dateString).toLocaleDateString('en-US', {
        year: 'numeric',
        month: 'short',
        day: 'numeric'
    });
};

const getTabIcon = (index) => {
    const icons = ['pi pi-cog', 'pi pi-file-edit', 'pi pi-send', 'pi pi-mobile'];
    return icons[index] || 'pi pi-circle';
};

const clearDateFilters = () => {
    selectedYear.value = null;
    selectedMonth.value = null;
};

const handleAddCard = async () => {
    if (!cardCreateEditRef.value) {
        console.error("CardCreateEditView reference is not available.");
        throw new Error("Form component not ready.");
    }
    try {
        const payload = cardCreateEditRef.value.getPayload();
        if (!payload.name) {
            throw new Error('Card name is required.');
        }
        
        await cardStore.addCard(payload);
        await cardStore.fetchCards();
    } catch (error) {
        console.error("Failed to add card:", error);
        throw new Error(typeof error === 'string' ? error : (error.message || 'Failed to create card'));
    }
};

const onDialogHide = () => {
    if (cardCreateEditRef.value && typeof cardCreateEditRef.value.resetFormForCreate === 'function') {
        cardCreateEditRef.value.resetFormForCreate();
    }
};

const handleCardUpdateFromGeneral = async (cardId, payload) => {
    try {
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

const tabs = ref(['General', 'Content', 'Issuance', 'Mobile Preview']);

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
                
                // If the deleted card was selected, clear selection and URL
                if (selectedCard.value !== null && cards.value[selectedCard.value]?.id === cardId) {
                    selectedCard.value = null;
                    router.replace({ name: route.name, query: {} });
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

const activeTab = ref(0);

// Computed property to convert activeTab to string for PrimeVue Tabs
const activeTabString = computed(() => activeTab.value.toString());

// Helper function to navigate to a specific card and tab
const navigateToCard = (cardId, tabName = 'general') => {
    const cardIndex = cards.value.findIndex(card => card.id === cardId);
    if (cardIndex !== -1) {
        selectedCard.value = cardIndex;
        activeTab.value = getTabIndex(tabName);
        updateURL(cardId, activeTab.value);
    }
};

const handlePublishCard = async () => {
    if (selectedCard.value !== null) {
        try {
            const cardId = cards.value[selectedCard.value].id;
            await cardStore.updateCard(cardId, { published: true });
            await cardStore.fetchCards();
            toast.add({ 
                severity: 'success', 
                summary: 'Published', 
                detail: 'Card published successfully! Mobile preview is now available.', 
                life: 3000 
            });
        } catch (error) {
            console.error('Failed to publish card:', error);
            toast.add({ 
                severity: 'error', 
                summary: 'Error', 
                detail: 'Failed to publish card.', 
                life: 3000 
            });
        }
    }
};

const handleSwitchToIssuance = () => {
    activeTab.value = 2;
    updateURL(null, activeTab.value);
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
