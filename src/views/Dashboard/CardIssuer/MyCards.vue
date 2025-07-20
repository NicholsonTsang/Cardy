<template>
    <PageWrapper title="My Cards" description="Manage your card designs, content, and issuance.">
        <div class="space-y-6">
            <!-- Add Card Dialog -->
            <MyDialog 
                v-model="showAddCardDialog"
                modal
                header="Create New Card"
                :confirmHandle="handleAddCard"
                confirmLabel="Create Card"
                confirmClass="bg-blue-600 hover:bg-blue-700 text-white border-0"
                successMessage="Card created successfully!"
                errorMessage="Failed to create card"
                :showToasts="true"
                @hide="onDialogHide"
            >
                <CardCreateEditView ref="cardCreateEditRef" modeProp="create" />
            </MyDialog>

            <!-- Delete Confirmation Dialog -->
            <ConfirmDialog group="deleteCardConfirmation"></ConfirmDialog>

            <div class="grid grid-cols-1 lg:grid-cols-4 gap-6 min-h-[calc(100vh-200px)]">
                <!-- Card List Panel -->
                <div class="lg:col-span-1">
                    <CardListPanel
                        :cards="cards"
                        @cards-imported="handleBulkImport"
                        :filteredCards="filteredCards"
                        :selectedCardId="selectedCardId"
                        v-model:searchQuery="search"
                        v-model:selectedYear="selectedYear"
                        v-model:selectedMonth="selectedMonth"
                        :currentPage="currentPage"
                        :itemsPerPage="itemsPerPage"
                        @create-card="showAddCardDialog = true"
                        @select-card="handleSelectCard"
                        @clear-date-filters="clearDateFilters"
                        @page-change="handlePageChange"
                    />
                </div>

                <!-- Card Detail Panel -->
                <div class="lg:col-span-3">
                    <CardDetailPanel
                        :selectedCard="selectedCardObject"
                        :hasCards="cards.length > 0"
                        :loading="isLoading"
                        :updateCardFn="handleCardUpdate"
                        v-model:activeTab="activeTabString"
                        @update-card="handleCardUpdate"
                        @cancel-edit="handleCardCancel"
                        @delete-card="triggerDeleteConfirmation"
                        @card-imported="handleCardImported"
                    />
                </div>
            </div>
        </div>
    </PageWrapper>
</template>

<script setup>
import { ref, onMounted, computed, watch } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useCardStore } from '@/stores/card.js';
import { useErrorHandler } from '@/utils/errorHandler.js';
import { storeToRefs } from 'pinia';
import ConfirmDialog from 'primevue/confirmdialog';
import { useConfirm } from "primevue/useconfirm";
import { useToast } from "primevue/usetoast";
import MyDialog from '@/components/MyDialog.vue';
import PageWrapper from '@/components/Layout/PageWrapper.vue';
import CardCreateEditView from '@/components/CardComponents/CardCreateEditView.vue';
import CardListPanel from '@/components/Card/CardListPanel.vue';
import CardDetailPanel from '@/components/Card/CardDetailPanel.vue';
import Button from 'primevue/button';

// Stores and composables
const cardStore = useCardStore();
const { cards, isLoading } = storeToRefs(cardStore);
const { handleError, handleAsyncError } = useErrorHandler();
const confirm = useConfirm();
const toast = useToast();
const route = useRoute();
const router = useRouter();

// Component state
const search = ref('');
const selectedCardId = ref(null);
const showAddCardDialog = ref(false);
const cardCreateEditRef = ref(null);
const activeTab = ref(0);

// Filters and pagination
const selectedYear = ref(null);
const selectedMonth = ref(null);
const currentPage = ref(1);
const itemsPerPage = ref(5);

// Computed properties
const selectedCardObject = computed(() => {
    if (selectedCardId.value === null || !cards.value) {
        return null;
    }
    return cards.value.find(card => card.id === selectedCardId.value) || null;
});

const filteredCards = computed(() => {
    let tempCards = cards.value || [];

    // Filter by search text
    if (search.value) {
        tempCards = tempCards.filter(card => 
            card.name.toLowerCase().includes(search.value.toLowerCase()) ||
            (card.description && card.description.toLowerCase().includes(search.value.toLowerCase()))
        );
    }

    // Filter by year
    if (selectedYear.value !== null) {
        tempCards = tempCards.filter(card => 
            new Date(card.created_at).getFullYear() === selectedYear.value
        );
    }

    // Filter by month
    if (selectedMonth.value !== null) {
        tempCards = tempCards.filter(card => 
            new Date(card.created_at).getMonth() === selectedMonth.value
        );
    }

    return tempCards;
});

const activeTabString = computed({
    get: () => activeTab.value.toString(),
    set: (value) => {
        const tabIndex = parseInt(value);
        activeTab.value = tabIndex;
        updateURL(null, tabIndex);
    }
});

// Watchers
watch([search, selectedYear, selectedMonth], () => {
    currentPage.value = 1;
});

watch([selectedCardId, cards], () => {
    if (selectedCardId.value !== null && (!cards.value || !cards.value.find(card => card.id === selectedCardId.value))) {
        selectedCardId.value = null;
        if (route.query.cardId || route.query.tab) {
            router.replace({ name: route.name, query: {} });
        }
    }
}, { deep: true });

watch(
    () => route.query,
    (newQuery, oldQuery) => {
        if (newQuery.cardId !== oldQuery.cardId || newQuery.tab !== oldQuery.tab) {
            initializeFromURL();
        }
    }
);

watch(
    () => cards.value.length,
    (newLength) => {
        if (newLength > 0) {
            initializeFromURL();
        }
    }
);

// Methods
const handleSelectCard = (cardId) => {
    selectedCardId.value = cardId;
    updateURL(cardId, activeTab.value);
};

const handlePageChange = (event) => {
    currentPage.value = Math.floor(event.first / itemsPerPage.value) + 1;
};

const clearDateFilters = () => {
    selectedYear.value = null;
    selectedMonth.value = null;
};

const updateURL = (cardId = null, tab = 0) => {
    const currentCardId = cardId || (selectedCardId.value !== null ? selectedCardId.value : null);
    const query = {};
    
    if (currentCardId) {
        query.cardId = currentCardId;
    }
    
    if (tab > 0) {
        query.tab = getTabName(tab);
    }
    
    if (route.query.cardId !== query.cardId || route.query.tab !== query.tab) {
        router.replace({ 
            name: route.name, 
            query: query 
        });
    }
};

const getTabName = (tabIndex) => {
    const tabNames = ['general', 'content', 'issuance', 'access', 'preview', 'import-export'];
    return tabNames[tabIndex] || 'general';
};

const getTabIndex = (tabName) => {
    const tabNames = ['general', 'content', 'issuance', 'access', 'preview', 'import-export'];
    const index = tabNames.indexOf(tabName);
    return index !== -1 ? index : 0;
};

const initializeFromURL = () => {
    if (route.query.tab) {
        activeTab.value = getTabIndex(route.query.tab);
    }
    
    if (route.query.cardId && cards.value.length > 0) {
        const cardIndex = cards.value.findIndex(card => card.id === route.query.cardId);
        if (cardIndex !== -1) {
            selectedCardId.value = cards.value[cardIndex].id;
        } else {
            if (route.query.cardId) {
                router.replace({ name: route.name, query: {} });
            }
        }
    }
};

const handleAddCard = async () => {
    if (!cardCreateEditRef.value) {
        throw new Error("Form component not ready.");
    }
    
    const payload = cardCreateEditRef.value.getPayload();
    if (!payload.name) {
        throw new Error('Card name is required.');
    }
    
    await handleAsyncError(async () => {
        await cardStore.addCard(payload);
        await cardStore.fetchCards();
        toast.add({ 
            severity: 'success', 
            summary: 'Success', 
            detail: `Card "${payload.name}" created successfully.`,
            life: 3000 
        });
    }, 'creating card');
};

const onDialogHide = () => {
    if (cardCreateEditRef.value && typeof cardCreateEditRef.value.resetFormForCreate === 'function') {
        cardCreateEditRef.value.resetFormForCreate();
    }
};

const handleCardUpdate = async (payload) => {
    if (!selectedCardObject.value) return;
    
    await handleAsyncError(async () => {
        await cardStore.updateCard(selectedCardObject.value.id, payload);
        await cardStore.fetchCards();
        toast.add({ 
            severity: 'success', 
            summary: 'Updated', 
            detail: `Card "${payload.name}" updated successfully.`,
            life: 3000 
        });
    }, 'updating card');
};

const handleCardCancel = () => {
    // Handle cancel edit if needed
};

const triggerDeleteConfirmation = (cardId) => {
    const cardToDelete = cards.value.find(card => card.id === cardId);
    if (!cardToDelete) {
        handleError('Card not found for deletion.', 'deleting card');
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
            await handleAsyncError(async () => {
                await cardStore.deleteCard(cardId);
                toast.add({ 
                    severity: 'success', 
                    summary: 'Deleted', 
                    detail: `Card "${cardToDelete.name}" deleted successfully.`,
                    life: 3000 
                });
                await cardStore.fetchCards();
                
                if (selectedCardId.value === cardId) {
                    selectedCardId.value = null;
                    router.replace({ name: route.name, query: {} });
                }
            }, 'deleting card');
        },
        reject: () => {
            toast.add({ 
                severity: 'info', 
                summary: 'Cancelled', 
                detail: 'Deletion cancelled.',
                life: 3000 
            });
        }
    });
};

// Import/Export handlers
const handleBulkImport = async () => {
    try {
        await cardStore.fetchCards();
        toast.add({
            severity: 'success',
            summary: 'Import Complete',
            detail: 'Cards imported successfully. Refreshing list...',
            life: 5000
        });
    } catch (error) {
        handleError(error, 'refreshing cards after import');
    }
};

const handleCardImported = async () => {
    try {
        await cardStore.fetchCards();
        toast.add({
            severity: 'success',
            summary: 'Import Complete',
            detail: 'Card data imported successfully.',
            life: 3000
        });
    } catch (error) {
        handleError(error, 'refreshing card after import');
    }
};

// Lifecycle
onMounted(async () => {
    await handleAsyncError(async () => {
        await cardStore.fetchCards();
        initializeFromURL();
    }, 'loading cards');
});
</script>

<style scoped>
/* Global theme styles are applied automatically */
</style>