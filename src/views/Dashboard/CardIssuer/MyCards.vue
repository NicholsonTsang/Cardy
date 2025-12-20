<template>
    <PageWrapper :title="$t('dashboard.my_cards')" :description="$t('dashboard.manage_cards_description')">
        <div class="space-y-3 sm:space-y-4 lg:space-y-6">
            <!-- Add Card Dialog -->
            <MyDialog 
                v-model="showAddCardDialog"
                modal
                :header="$t('dashboard.create_new_card')"
                :confirmHandle="handleAddCard"
                :confirmLabel="$t('dashboard.create_card')"
                confirmClass="bg-blue-600 hover:bg-blue-700 text-white border-0"
                :successMessage="$t('dashboard.card_created')"
                :errorMessage="$t('messages.operation_failed')"
                :showToasts="false"
                @hide="onDialogHide"
            >
                <CardCreateEditView ref="cardCreateEditRef" modeProp="create" />
            </MyDialog>

            <!-- Delete Confirmation Dialog -->
            <ConfirmDialog group="deleteCardConfirmation"></ConfirmDialog>

            <div class="grid grid-cols-1 lg:grid-cols-4 gap-4 lg:gap-6 min-h-[calc(100vh-200px)]">
                <!-- Card List Panel -->
                <div class="lg:col-span-1">
                    <CardListPanel
                        :cards="cards"
                        :loading="isLoading"
                        @cards-imported="handleBulkImport"
                        :filteredCards="filteredCards"
                        :selectedCardId="selectedCardId"
                        v-model:searchQuery="search"
                        v-model:selectedYear="selectedYear"
                        v-model:selectedMonth="selectedMonth"
                        :currentPage="currentPage"
                        :itemsPerPage="itemsPerPage"
                        :experienceCount="subscriptionStore.experienceCount"
                        :experienceLimit="subscriptionStore.experienceLimit"
                        @create-card="handleCreateCardClick"
                        @select-card="handleSelectCard"
                        @clear-date-filters="clearDateFilters"
                        @page-change="handlePageChange"
                        @delete-cards="handleBulkDelete"
                        @export-cards="handleBulkExport"
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
                        :selectedBatchId="selectedBatchId"
                        @update-card="handleCardUpdate"
                        @cancel-edit="handleCardCancel"
                        @delete-card="triggerDeleteConfirmation"
                        @card-imported="handleCardImported"
                        @batch-changed="handleBatchChange"
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
import { useI18n } from 'vue-i18n';
import { exportCardsToExcel } from '@/utils/excelHandler.js';
import { useContentItemStore } from '@/stores/contentItem';
import { useSubscriptionStore } from '@/stores/subscription';

// Stores and composables
const { t } = useI18n();
const cardStore = useCardStore();
const contentItemStore = useContentItemStore();
const subscriptionStore = useSubscriptionStore();
const { cards, isLoading } = storeToRefs(cardStore);
const { handleError, handleAsyncError } = useErrorHandler();
const confirm = useConfirm();
const toast = useToast();
const route = useRoute();
const router = useRouter();

// Component state
const search = ref('');
const selectedCardId = ref(null);
const selectedBatchId = ref(null);
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
        updateURL(null, tabIndex, null);
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
        if (newQuery.cardId !== oldQuery.cardId || newQuery.tab !== oldQuery.tab || newQuery.batchId !== oldQuery.batchId) {
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
    // Clear batch selection when switching cards
    selectedBatchId.value = null;
    // Reset to General tab (tab 0) when switching cards
    activeTab.value = 0;
    updateURL(cardId, 0, null);
};

const handleBatchChange = (batchId) => {
    selectedBatchId.value = batchId;
    updateURL(null, activeTab.value, batchId);
};

const handlePageChange = (event) => {
    currentPage.value = Math.floor(event.first / itemsPerPage.value) + 1;
};

const clearDateFilters = () => {
    selectedYear.value = null;
    selectedMonth.value = null;
};

const updateURL = (cardId = null, tab = 0, batchId = null) => {
    const currentCardId = cardId || (selectedCardId.value !== null ? selectedCardId.value : null);
    const currentBatchId = batchId !== null ? batchId : selectedBatchId.value;
    const query = {};
    
    if (currentCardId) {
        query.cardId = currentCardId;
    }
    
    if (tab > 0) {
        query.tab = getTabName(tab);
    }
    
    // Only include batchId if we're on the access tab
    if (currentBatchId && tab === 3) {
        query.batchId = currentBatchId;
    }
    
    if (route.query.cardId !== query.cardId || route.query.tab !== query.tab || route.query.batchId !== query.batchId) {
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
    
    // Initialize batchId from URL if on access tab
    if (route.query.batchId && activeTab.value === 3) {
        selectedBatchId.value = route.query.batchId;
    }
};

// Check if user can create new experience based on subscription tier
const handleCreateCardClick = async () => {
    // Fetch latest subscription status
    await subscriptionStore.fetchSubscription();
    
    if (!subscriptionStore.canCreateExperience) {
        toast.add({
            severity: 'warn',
            summary: t('subscription.limit_reached'),
            detail: t('subscription.upgrade_to_create_more', {
                limit: subscriptionStore.experienceLimit,
                current: subscriptionStore.experienceCount
            }),
            life: 5000
        });
        
        // Offer to navigate to subscription page
        confirm.require({
            message: t('subscription.upgrade_prompt'),
            header: t('subscription.free_tier_limit'),
            icon: 'pi pi-star',
            acceptLabel: t('subscription.view_plans'),
            rejectLabel: t('common.cancel'),
            accept: () => router.push('/cms/subscription')
        });
        return;
    }
    
    showAddCardDialog.value = true;
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
        const newCardId = await cardStore.addCard(payload);
        await cardStore.fetchCards();
        
        // Refresh subscription count
        subscriptionStore.fetchSubscription();
        
        // Auto-select the newly created card
        if (newCardId) {
            selectedCardId.value = newCardId;
            activeTab.value = 0; // Switch to first tab (General)
        }
        
        // Success feedback provided by UI update and dialog close
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
        // Success feedback provided by UI update and dialog close
    }, 'updating card');
};

const handleCardCancel = () => {
    // Handle cancel edit if needed
};

const triggerDeleteConfirmation = (cardId) => {
    const cardToDelete = cards.value.find(card => card.id === cardId);
    if (!cardToDelete) {
        handleError(t('messages.operation_failed'), 'deleting card');
        return;
    }

    confirm.require({
        group: 'deleteCardConfirmation',
        message: t('dashboard.confirm_delete_card_message', { name: cardToDelete.name }),
        header: t('dashboard.confirm_deletion'),
        icon: 'pi pi-exclamation-triangle',
        acceptLabel: t('dashboard.delete_card'),
        rejectLabel: t('common.cancel'),
        acceptClass: 'p-button-danger',
        accept: async () => {
            await handleAsyncError(async () => {
                await cardStore.deleteCard(cardId);
                await cardStore.fetchCards();
                // Success feedback provided by visual removal from list
                
                if (selectedCardId.value === cardId) {
                    selectedCardId.value = null;
                    router.replace({ name: route.name, query: {} });
                }
            }, 'deleting card');
        },
        reject: () => {
            // No toast needed - user actively cancelled
        }
    });
};

// Import/Export handlers
const handleBulkImport = async (importResults) => {
    try {
        const cardsBefore = cards.value.length;
        await cardStore.fetchCards();
        
        // Auto-select the newly imported card if one was created
        if (importResults?.success && cards.value.length > cardsBefore) {
            // Get the most recently created card (likely the imported one)
            const sortedCards = [...cards.value].sort((a, b) => new Date(b.created_at) - new Date(a.created_at));
            if (sortedCards.length > 0) {
                selectedCardId.value = sortedCards[0].id;
                // Show helpful toast to guide user
                toast.add({
                    severity: 'success',
                    summary: t('messages.import_complete'),
                    detail: t('messages.import_complete_message'),
                    life: 6000
                });
            }
        }
        // Success feedback provided by updated card list
    } catch (error) {
        handleError(error, 'refreshing cards after import');
    }
};

const handleCardImported = async () => {
    try {
        await cardStore.fetchCards();
        // Success feedback provided by updated card list
    } catch (error) {
        handleError(error, 'refreshing card after import');
    }
};

// Bulk operations handlers
const handleBulkDelete = async (cardIds) => {
    const count = cardIds.length;
    let successCount = 0;
    let failCount = 0;
    
    for (const cardId of cardIds) {
        try {
            await cardStore.deleteCard(cardId);
            successCount++;
            
            // Clear selection if deleted card was selected
            if (selectedCardId.value === cardId) {
                selectedCardId.value = null;
            }
        } catch (error) {
            failCount++;
            console.error(`Failed to delete card ${cardId}:`, error);
        }
    }
    
    await cardStore.fetchCards();
    
    if (successCount > 0) {
        toast.add({
            severity: failCount > 0 ? 'warn' : 'success',
            summary: t('dashboard.cards_deleted', { count: successCount }),
            detail: failCount > 0 ? t('dashboard.some_cards_failed', { count: failCount }) : undefined,
            life: 4000
        });
    } else {
        toast.add({
            severity: 'error',
            summary: t('common.error'),
            detail: t('messages.operation_failed'),
            life: 4000
        });
    }
    
    // Clear URL params if selected card was deleted
    if (!selectedCardId.value) {
        router.replace({ name: route.name, query: {} });
    }
};

const handleBulkExport = async ({ cards: cardsToExport, singleFile }) => {
    const count = cardsToExport.length;
    
    try {
        toast.add({
            severity: 'info',
            summary: t('dashboard.exporting_cards', { count }),
            life: 2000
        });
        
        // For each card, fetch its content items
        const exportData = [];
        for (const card of cardsToExport) {
            // Fetch content items for this card
            const contentItems = await contentItemStore.getContentItems(card.id);
            
            exportData.push({
                card,
                contentItems: contentItems || []
            });
        }
        
        // Export with chosen option
        await exportCardsToExcel(exportData, {
            singleFile,
            filename: `cards_export_${new Date().toISOString().split('T')[0]}.xlsx`
        });
        
        toast.add({
            severity: 'success',
            summary: t('dashboard.cards_exported', { count }),
            life: 4000
        });
    } catch (error) {
        handleError(error, 'exporting cards');
    }
};

// Lifecycle
onMounted(async () => {
    await handleAsyncError(async () => {
        await Promise.all([
            cardStore.fetchCards(),
            subscriptionStore.fetchSubscription()
        ]);
        initializeFromURL();
    }, 'loading cards');
});
</script>

<style scoped>
/* Global theme styles are applied automatically */
</style>