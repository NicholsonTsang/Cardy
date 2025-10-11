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
            <div class="p-6 border-b border-slate-200 bg-white">
                <div class="flex items-center justify-between">
                    <div>
                        <h2 class="text-xl font-semibold text-slate-900">{{ selectedCard.name }}</h2>
                        <p class="text-slate-600 mt-1">{{ t('dashboard.manage_card_subtitle') }}</p>
                    </div>
                    <div>
                        <Button 
                            :label="t('common.export')" 
                            icon="pi pi-download" 
                            @click="showExportDialog = true"
                            class="export-button bg-blue-600 hover:bg-blue-700 text-white border-0"
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
                <TabList class="flex-shrink-0 border-b border-slate-200 bg-white px-6">
                    <Tab v-for="(tab, index) in tabs" :key="index" :value="index.toString()" 
                         class="px-4 py-3 font-medium text-sm text-slate-600 hover:text-slate-900 transition-colors">
                        <i :class="tab.icon" class="mr-2"></i>
                        {{ tab.label }}
                    </Tab>
                </TabList>
                <TabPanels class="flex-1 overflow-hidden bg-slate-50">
                    <TabPanel v-for="(tab, index) in tabs" :value="index.toString()" class="h-full">
                        <div class="h-full overflow-y-auto p-6">
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
                            />
                            <!-- QR & Access Tab -->
                            <CardAccessQR 
                                v-if="index === 3" 
                                :cardId="selectedCard.id"
                                :cardName="selectedCard.name"
                                :selectedBatchId="selectedBatchId"
                                @batch-changed="$emit('batch-changed', $event)"
                                :key="selectedCard.id + '-access-qr'" 
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

// Export dialog state
const showExportDialog = ref(false);

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
</style>