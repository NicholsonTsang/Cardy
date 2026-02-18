<template>
    <PageWrapper :showHeader="false">
        <div class="space-y-3 sm:space-y-4 lg:space-y-6">
            <!-- Add Card Dialog (Wizard) -->
            <MyDialog
                v-model="showAddCardDialog"
                modal
                :header="$t('dashboard.create_new_card')"
                :showConfirm="false"
                :showCancel="false"
                :style="{ width: '90vw', maxWidth: '52rem' }"
                @hide="onDialogHide"
            >
                <CardCreateWizard
                    ref="cardCreateEditRef"
                    @submit="handleWizardSubmit"
                    @cancel="showAddCardDialog = false"
                />
            </MyDialog>

            <!-- Delete Confirmation Dialog -->
            <ConfirmDialog group="deleteCardConfirmation"></ConfirmDialog>

            <div class="flex flex-col lg:flex-row gap-4 lg:gap-6 lg:h-[calc(100vh-140px)]">
                <!-- Card List Panel - Fixed width sidebar -->
                <!-- On mobile: hidden when a card is selected (show detail instead) -->
                <div
                    class="w-full lg:w-[320px] lg:flex-shrink-0 lg:h-full"
                    :class="{ 'hidden lg:block': selectedCardId && isMobileView }"
                >
                    <CardListPanel
                        ref="cardListPanelRef"
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
                        :projectCount="subscriptionStore.projectCount"
                        :projectLimit="isAdmin ? 0 : subscriptionStore.projectLimit"
                        @create-card="handleCreateCardClick"
                        @select-card="handleSelectCard"
                        @clear-filters="clearFilters"
                        @page-change="handlePageChange"
                        @delete-cards="handleBulkDelete"
                        @export-cards="handleBulkExport"
                    />
                </div>

                <!-- Card Detail Panel - Takes remaining space -->
                <!-- On mobile: hidden when no card is selected -->
                <div
                    class="flex-1 min-w-0 lg:h-full"
                    :class="{ 'hidden lg:block': !selectedCardId && isMobileView }"
                >
                    <!-- Mobile back button -->
                    <div v-if="selectedCardId && isMobileView" class="mb-3 lg:hidden">
                        <button
                            @click="handleMobileBack"
                            class="flex items-center gap-2 px-3 py-2.5 rounded-lg text-sm font-medium text-slate-600 hover:text-slate-900 hover:bg-slate-100 transition-colors min-h-[44px]"
                        >
                            <i class="pi pi-arrow-left text-sm"></i>
                            {{ $t('common.back') }}
                        </button>
                    </div>
                    <CardDetailPanel
                        :selectedCard="selectedCardObject"
                        :hasCards="cards.length > 0"
                        :loading="isLoading"
                        :updateCardFn="handleCardUpdate"
                        v-model:activeTab="activeTabString"
                        @update-card="handleCardUpdate"
                        @delete-card="triggerDeleteConfirmation"
                        @card-imported="handleCardImported"
                        @create-card="handleCreateCardClick"
                        @open-import="cardListPanelRef?.openImportDialog()"
                        @open-template="cardListPanelRef?.openTemplateDialog()"
                    />
                </div>
            </div>
        </div>
    </PageWrapper>
</template>

<script setup>
import { ref, onMounted, onUnmounted, computed, watch } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useCardStore } from '@/stores/card.js';
import { useErrorHandler } from '@/utils/errorHandler.js';
import { storeToRefs } from 'pinia';
import ConfirmDialog from 'primevue/confirmdialog';
import { useConfirm } from "primevue/useconfirm";
import { useToast } from "primevue/usetoast";
import MyDialog from '@/components/MyDialog.vue';
import PageWrapper from '@/components/Layout/PageWrapper.vue';
import CardCreateWizard from '@/components/CardComponents/CardCreateWizard.vue';
import CardListPanel from '@/components/Card/CardListPanel.vue';
import CardDetailPanel from '@/components/Card/CardDetailPanel.vue';
import { useI18n } from 'vue-i18n';
import { exportProject, exportMultipleProjects } from '@/utils/projectArchive';
import { useContentItemStore } from '@/stores/contentItem';
import { useSubscriptionStore } from '@/stores/subscription';
import { useAuthStore } from '@/stores/auth';

// Stores and composables
const { t } = useI18n();
const cardStore = useCardStore();
const contentItemStore = useContentItemStore();
const subscriptionStore = useSubscriptionStore();
const authStore = useAuthStore();

// Admin check - admins have no project limits
const isAdmin = computed(() => authStore.getUserRole() === 'admin');
const { cards, isLoading } = storeToRefs(cardStore);
const { handleError, handleAsyncError } = useErrorHandler();
const confirm = useConfirm();
const toast = useToast();
const route = useRoute();
const router = useRouter();

// Component state
const search = ref('');
const debouncedSearch = ref('');
let searchDebounceTimer = null;
watch(search, (val) => {
    clearTimeout(searchDebounceTimer);
    searchDebounceTimer = setTimeout(() => { debouncedSearch.value = val; }, 250);
});
const selectedCardId = ref(null);
const showAddCardDialog = ref(false);
const cardCreateEditRef = ref(null);
const activeTab = ref(0);
const cardListPanelRef = ref(null);

// Filters and pagination
const selectedYear = ref(null);
const selectedMonth = ref(null);
const currentPage = ref(1);
const itemsPerPage = ref(10);

// Mobile responsive - detect viewport width (debounced)
const windowWidth = ref(window.innerWidth);
const isMobileView = computed(() => windowWidth.value < 1024); // matches lg breakpoint

let resizeTimer = null;
const handleResize = () => {
    clearTimeout(resizeTimer);
    resizeTimer = setTimeout(() => { windowWidth.value = window.innerWidth; }, 150);
};
onMounted(() => { window.addEventListener('resize', handleResize); });
onUnmounted(() => {
    window.removeEventListener('resize', handleResize);
    clearTimeout(resizeTimer);
    clearTimeout(searchDebounceTimer);
});

const handleMobileBack = () => {
    selectedCardId.value = null;
    router.replace({ name: route.name, query: {} });
};

// Computed properties
const selectedCardObject = computed(() => {
    if (selectedCardId.value === null || !cards.value) {
        return null;
    }
    return cards.value.find(card => card.id === selectedCardId.value) || null;
});

const filteredCards = computed(() => {
    let tempCards = cards.value || [];

    // Filter by search text (uses debounced value to avoid recompute on every keystroke)
    if (debouncedSearch.value) {
        const query = debouncedSearch.value.toLowerCase();
        tempCards = tempCards.filter(card =>
            card.name.toLowerCase().includes(query) ||
            (card.description && card.description.toLowerCase().includes(query))
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

// Reset pagination when filters change
watch([debouncedSearch, selectedYear, selectedMonth], () => {
    currentPage.value = 1;
});

// Watch card list length + selectedCardId to detect if selected card was removed
// Avoids deep watching the entire cards array on every property change
watch([selectedCardId, () => cards.value?.length], () => {
    if (selectedCardId.value !== null && (!cards.value || !cards.value.find(card => card.id === selectedCardId.value))) {
        selectedCardId.value = null;
        if (route.query.cardId || route.query.tab) {
            router.replace({ name: route.name, query: {} });
        }
    }
});

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
    // Reset to General tab (tab 0) when switching cards
    activeTab.value = 0;
    updateURL(cardId, 0);
};

const handlePageChange = (event) => {
    currentPage.value = Math.floor(event.first / itemsPerPage.value) + 1;
};

const clearFilters = () => {
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
    const tabNames = ['general', 'content', 'ai-translations', 'qr-access'];
    return tabNames[tabIndex] || 'general';
};

const getTabIndex = (tabName) => {
    const tabNames = ['general', 'content', 'ai-translations', 'qr-access'];
    // Handle legacy URL values from old tab layouts
    if (tabName === 'control-settings') return 3;
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

// Check if user can create new experience based on subscription tier
// Admins have no project limits
const handleCreateCardClick = async () => {
    // Admins bypass all limits
    if (isAdmin.value) {
        showAddCardDialog.value = true;
        return;
    }
    
    // Fetch latest subscription status
    await subscriptionStore.fetchSubscription();
    
    if (!subscriptionStore.canCreateProject) {
        toast.add({
            severity: 'warn',
            summary: t('subscription.limit_reached'),
            detail: t('subscription.upgrade_to_create_more', {
                limit: subscriptionStore.projectLimit,
                current: subscriptionStore.projectCount
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

const handleWizardSubmit = async (payload) => {
    await handleAsyncError(async () => {
        const newCardId = await cardStore.addCard(payload);
        await cardStore.fetchCards();

        // Refresh subscription count
        subscriptionStore.fetchSubscription();

        // Auto-select the newly created card
        if (newCardId) {
            selectedCardId.value = newCardId;
            activeTab.value = 0;
        }

        showAddCardDialog.value = false;
    }, 'creating card');
};

const onDialogHide = () => {
    if (cardCreateEditRef.value && typeof cardCreateEditRef.value.resetForm === 'function') {
        cardCreateEditRef.value.resetForm();
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

const triggerDeleteConfirmation = (cardId) => {
    const cardToDelete = cards.value.find(card => card.id === cardId);
    if (!cardToDelete) {
        handleError(t('messages.operation_failed'), 'deleting card');
        return;
    }

    // Build confirmation message with template warning if applicable
    let confirmMessage = t('dashboard.confirm_delete_card_message', { name: cardToDelete.name });
    if (cardToDelete.is_template) {
        confirmMessage += '\n\n' + t('dashboard.delete_template_warning');
    }

    confirm.require({
        group: 'deleteCardConfirmation',
        message: confirmMessage,
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
        
        // Export as ZIP archive(s)
        const timestamp = new Date().toISOString().split('T')[0];
        let blob;
        let filename;

        if (singleFile && exportData.length > 1) {
            // Multiple cards in one ZIP
            blob = await exportMultipleProjects(exportData);
            filename = `cards_export_${timestamp}.zip`;
        } else if (exportData.length === 1) {
            // Single card
            const result = await exportProject(exportData[0].card, exportData[0].contentItems);
            blob = result.blob;
            const safeName = (exportData[0].card.name || 'card').replace(/[^a-z0-9]/gi, '_');
            filename = `${safeName}_export_${timestamp}.zip`;
        } else {
            // Multiple separate files — export as single bundle ZIP
            blob = await exportMultipleProjects(exportData);
            filename = `cards_export_${timestamp}.zip`;
        }

        const url = window.URL.createObjectURL(blob);
        const link = document.createElement('a');
        link.href = url;
        link.download = filename;
        link.click();
        window.URL.revokeObjectURL(url);
        
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