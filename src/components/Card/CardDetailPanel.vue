<template>
    <div class="bg-white rounded-xl shadow-lg border border-slate-200 flex flex-col overflow-hidden">
        <!-- Empty State -->
        <div v-if="!selectedCard" class="flex-1 flex items-center justify-center p-8">
            <div class="text-center">
                <div class="w-20 h-20 bg-slate-100 rounded-full flex items-center justify-center mx-auto mb-4">
                    <i class="pi pi-id-card text-3xl text-slate-400"></i>
                </div>
                <h3 class="text-xl font-medium text-slate-900 mb-2">
                    {{ emptyStateTitle }}
                </h3>
                <p class="text-slate-500">
                    {{ emptyStateMessage }}
                </p>
            </div>
        </div>

        <!-- Card Details -->
        <div v-else class="flex-1 flex flex-col">
            <!-- Card Header -->
            <div class="p-3 sm:p-4 lg:p-6 border-b border-slate-200 bg-white">
                <div class="flex items-center justify-between gap-2">
                    <div class="min-w-0 flex-1">
                        <h2 class="text-base sm:text-lg lg:text-xl font-semibold text-slate-900 truncate">{{ selectedCard.name }}</h2>
                        <p class="text-xs sm:text-sm lg:text-base text-slate-600 mt-0.5 sm:mt-1">{{ t('dashboard.manage_card_subtitle') }}</p>
                    </div>
                    <div class="flex-shrink-0">
                        <Button 
                            :label="t('common.export')" 
                            icon="pi pi-download" 
                            @click="showExportDialog = true"
                            class="export-button bg-blue-600 hover:bg-blue-700 text-white border-0 text-xs sm:text-sm"
                            size="small"
                        />
                    </div>
                </div>
            </div>

            <!-- Export Dialog -->
            <Dialog 
                v-model:visible="showExportDialog"
                modal 
                :header="t('common.export_card_data')"
                :style="{ width: '40rem' }"
                :breakpoints="{ '1199px': '75vw', '575px': '90vw' }"
                class="export-dialog standardized-dialog"
            >
                <CardExport 
                    :card="selectedCard"
                    @exported="handleExportComplete"
                    @cancel="handleExportCancel"
                />
            </Dialog>

            <!-- Tabs -->
            <Tabs :value="activeTab" @update:value="$emit('update:activeTab', $event)" class="flex-1 flex flex-col">
                <TabList class="flex-shrink-0 border-b border-slate-200 bg-white px-1 sm:px-3 lg:px-6 overflow-x-auto scrollbar-hide">
                    <Tab v-for="(tab, index) in tabs" :key="index" :value="index.toString()" 
                         class="px-1.5 sm:px-3 lg:px-4 py-2 sm:py-2.5 lg:py-3 font-medium text-xs sm:text-sm text-slate-600 hover:text-slate-900 transition-colors whitespace-nowrap flex-shrink-0">
                        <i :class="tab.icon" class="mr-0.5 sm:mr-1 lg:mr-2 text-xs sm:text-sm"></i>
                        <span class="hidden sm:inline">{{ tab.label }}</span>
                        <span class="sm:hidden">{{ tab.label.split(' ')[0] }}</span>
                    </Tab>
                </TabList>
                <TabPanels class="flex-1 overflow-hidden bg-slate-50">
                    <TabPanel v-for="(tab, index) in tabs" :value="index.toString()" class="h-full">
                        <div class="h-full overflow-y-auto px-0 py-2 sm:p-3 lg:p-4 xl:p-6">
                            <!-- General Tab -->
                            <CardGeneral 
                                v-if="index === 0"
                                :cardProp="selectedCard"
                                :loading="loading"
                                :updateCardFn="updateCardFn"
                                @update-card="$emit('update-card', $event)"
                                @cancel-edit="$emit('cancel-edit')"
                                @delete-card-requested="$emit('delete-card', $event)"
                            />
                            <!-- Content Tab -->
                            <CardContent 
                                v-if="index === 1" 
                                :cardId="selectedCard.id" 
                                :cardAiEnabled="selectedCard.conversation_ai_enabled" 
                                :key="selectedCard.id + '-content'" 
                            />
                            <!-- Issuance Tab -->
                            <CardIssuanceCheckout 
                                v-if="index === 2" 
                                :cardId="selectedCard.id" 
                                :key="selectedCard.id + '-issurance'"
                                @batch-created="handleBatchCreated"
                            />
                            <!-- QR & Access Tab -->
                            <CardAccessQR 
                                v-if="index === 3"
                                :cardId="selectedCard.id"
                                :cardName="selectedCard.name"
                                :selectedBatchId="selectedBatchId"
                                @batch-changed="$emit('batch-changed', $event)"
                                :key="`${selectedCard.id}-access-qr-${accessQRRefreshKey}`" 
                            />
                            <!-- Preview Tab -->
                            <MobilePreview 
                                v-if="index === 4" 
                                :cardProp="selectedCard" 
                                :key="`${selectedCard.id}-mobile-preview-${mobilePreviewRefreshKey}`"
                            />
                        </div>
                    </TabPanel>
                </TabPanels>
            </Tabs>
        </div>
    </div>
</template>

<script setup>
import { computed, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import Tabs from 'primevue/tabs';
import TabList from 'primevue/tablist';
import Tab from 'primevue/tab';
import TabPanels from 'primevue/tabpanels';
import TabPanel from 'primevue/tabpanel';
import Button from 'primevue/button';
import Dialog from 'primevue/dialog';
import CardGeneral from '@/components/CardComponents/Card.vue';
import CardContent from '@/components/CardContent/CardContent.vue';
import CardIssuanceCheckout from '@/components/CardIssuanceCheckout.vue';
import CardAccessQR from '@/components/CardComponents/CardAccessQR.vue';
import MobilePreview from '@/components/CardComponents/MobilePreview.vue';
import CardExport from '@/components/Card/Export/CardExport.vue';

const { t } = useI18n();

const props = defineProps({
    selectedCard: {
        type: Object,
        default: null
    },
    activeTab: {
        type: String,
        default: '0'
    },
    hasCards: {
        type: Boolean,
        default: false
    },
    loading: {
        type: Boolean,
        default: false
    },
    updateCardFn: {
        type: Function,
        default: null
    },
    selectedBatchId: {
        type: String,
        default: null
    }
});

const emit = defineEmits([
    'batch-changed',
    'update:activeTab',
    'update-card',
    'cancel-edit',
    'delete-card',
    'card-imported'
]);

// Handle card import event
function handleCardImported() {
    emit('card-imported');
}

// Handle export completion
function handleExportComplete() {
    showExportDialog.value = false;
}

// Handle export cancellation
function handleExportCancel() {
    showExportDialog.value = false;
}

// Counter to force MobilePreview refresh when tab is clicked
const mobilePreviewRefreshKey = ref(0);

// Counter to force CardAccessQR refresh when batch is created
const accessQRRefreshKey = ref(0);

// Export dialog state
const showExportDialog = ref(false);

// Handle batch created event from CardIssuanceCheckout
const handleBatchCreated = async (batchId) => {
    // Increment key to force CardAccessQR to remount with fresh data
    accessQRRefreshKey.value++;
};

const tabs = computed(() => [
    { label: t('dashboard.general'), icon: 'pi pi-cog' },
    { label: t('dashboard.content'), icon: 'pi pi-list' },
    { label: t('dashboard.card_issuance'), icon: 'pi pi-credit-card' },
    { label: t('dashboard.qr_access'), icon: 'pi pi-qrcode' },
    { label: t('dashboard.mobile_preview'), icon: 'pi pi-mobile' }
]);

const emptyStateTitle = computed(() => {
    return props.hasCards ? t('dashboard.select_a_card') : t('dashboard.no_cards_yet');
});

const emptyStateMessage = computed(() => {
    return props.hasCards 
        ? t('dashboard.choose_card_to_view') 
        : t('dashboard.create_first_card_instruction');
});

// Watch for tab changes and refresh MobilePreview when preview tab (index 4) is activated
watch(() => props.activeTab, (newTab, oldTab) => {
    if (newTab === '4') {
        // Increment the refresh key to force MobilePreview component to re-mount
        mobilePreviewRefreshKey.value += 1;
    }
});
</script>

<style scoped>
/* Custom export dialog styles */
:deep(.export-dialog .p-dialog-content) {
  padding: 0;
}

/* Hide scrollbar for TabList while maintaining scroll functionality */
.scrollbar-hide {
  -ms-overflow-style: none;  /* IE and Edge */
  scrollbar-width: none;  /* Firefox */
}

.scrollbar-hide::-webkit-scrollbar {
  display: none;  /* Chrome, Safari and Opera */
}

/* Ensure tabs container allows horizontal scrolling */
:deep(.p-tablist) {
  display: flex;
  flex-wrap: nowrap;
}
</style>