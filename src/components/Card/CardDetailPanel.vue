<template>
    <div class="bg-white rounded-xl shadow-lg border border-slate-200 flex flex-col overflow-hidden">
        <!-- Empty State -->
        <div v-if="!selectedCard" class="flex items-center justify-center p-6 py-8">
            <div class="text-center">
                <div class="w-16 h-16 bg-slate-100 rounded-full flex items-center justify-center mx-auto mb-4">
                    <i class="pi pi-id-card text-2xl text-slate-400"></i>
                </div>
                <h3 class="text-lg font-medium text-slate-900 mb-2">
                    {{ emptyStateTitle }}
                </h3>
                <p class="text-sm text-slate-500">
                    {{ emptyStateMessage }}
                </p>
            </div>
        </div>

        <!-- Card Details -->
        <div v-else class="flex-1 flex flex-col">
            <!-- Tabs with Step Indicators -->
            <Tabs :value="activeTab" @update:value="$emit('update:activeTab', $event)" class="flex-1 flex flex-col">
                <TabList class="flex-shrink-0 border-b border-slate-200 bg-white px-1 sm:px-3 lg:px-6 overflow-x-auto scrollbar-hide">
                    <Tab v-for="(tab, index) in tabs" :key="index" :value="index.toString()"
                         class="px-2 sm:px-3 lg:px-4 py-3 sm:py-2.5 lg:py-3 font-medium text-xs sm:text-sm text-slate-600 hover:text-slate-900 transition-colors whitespace-nowrap flex-shrink-0 min-h-[44px] flex items-center"
                         v-tooltip.bottom="tab.hint">
                        <i :class="tab.icon" class="mr-0.5 sm:mr-1 lg:mr-2 text-xs sm:text-sm"></i>
                        <span class="hidden sm:inline">{{ tab.label }}</span>
                        <span class="sm:hidden">{{ tab.label.split(' ')[0] }}</span>
                        <!-- Action needed indicator when no content items -->
                        <span v-if="index === 1 && contentCount === 0" class="ml-1 w-2 h-2 bg-amber-500 rounded-full animate-pulse"></span>
                    </Tab>
                </TabList>
                <TabPanels class="flex-1 overflow-hidden bg-slate-50">
                    <TabPanel v-for="(tab, index) in tabs" :key="tab.label" :value="index.toString()" class="h-full">
                        <div class="h-full overflow-y-auto px-0 py-2 sm:p-3 lg:p-4 xl:p-6">
                            <!-- General Tab -->
                            <CardView
                                v-if="getTabComponent(index) === 'general'"
                                :cardProp="selectedCard"
                                :updateCardFn="updateCardFn"
                                :contentCount="contentCount"
                                @update-card="$emit('update-card', $event)"
                                @delete-requested="$emit('delete-card', $event)"
                                @navigate-tab="$emit('update:activeTab', $event)"
                                @show-preview="showPreviewDialog = true"
                            />
                            <!-- Content Tab -->
                            <CardContent
                                v-if="getTabComponent(index) === 'content' && selectedCard"
                                :cardId="selectedCard.id"
                                :card="selectedCard"
                                :cardAiEnabled="selectedCard.conversation_ai_enabled"
                                :contentMode="selectedCard.content_mode || 'list'"
                                :isGrouped="selectedCard.is_grouped || false"
                                :groupDisplay="selectedCard.group_display || 'expanded'"
                                :key="selectedCard.id + '-content'"
                                @update-card="$emit('update-card', $event)"
                            />
                            <!-- QR & Access Tab -->
                            <DigitalAccessQR
                                v-if="getTabComponent(index) === 'qr' && selectedCard"
                                :card="selectedCard"
                                :cardName="selectedCard.name"
                                :key="`${selectedCard.id}-digital-qr`"
                                @updated="handleDigitalAccessUpdated"
                            />
                        </div>
                    </TabPanel>
                </TabPanels>
            </Tabs>
        </div>
        <!-- Preview Dialog -->
        <Dialog
            v-model:visible="showPreviewDialog"
            modal
            :header="t('dashboard.mobile_preview')"
            :style="{ width: '28rem' }"
            :breakpoints="{ '768px': '90vw' }"
            :dismissableMask="true"
            class="standardized-dialog"
        >
            <MobilePreview
                v-if="showPreviewDialog && selectedCard"
                :cardProp="selectedCard"
                :key="`${selectedCard?.id}-preview-dialog`"
            />
        </Dialog>
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
import Dialog from 'primevue/dialog';
import CardView from '@/components/CardComponents/CardView.vue';
import CardContent from '@/components/CardContent/CardContent.vue';
import DigitalAccessQR from '@/components/DigitalAccess/DigitalAccessQR.vue';
import MobilePreview from '@/components/CardComponents/MobilePreview.vue';
import { useContentItemStore } from '@/stores/contentItem';

const { t } = useI18n();
const contentItemStore = useContentItemStore();

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
});

const emit = defineEmits([
    'update:activeTab',
    'update-card',
    'delete-card',
    'card-imported'
]);

// Handle card import event
function handleCardImported() {
    emit('card-imported');
}

// Preview dialog state
const showPreviewDialog = ref(false);

// Tab configuration
// Each tab includes a hint for tooltips to help users understand the workflow
const tabs = computed(() => {
    const baseTabs = [
        {
            label: t('dashboard.general'),
            icon: 'pi pi-cog',
            hint: t('dashboard.tab_hint_general')
        },
        {
            label: t('dashboard.content'),
            icon: 'pi pi-list',
            hint: t('dashboard.tab_hint_content')
        }
    ];

    // QR & Access tab
    baseTabs.push({
        label: t('dashboard.qr_access'),
        icon: 'pi pi-qrcode',
        hint: t('dashboard.tab_hint_qr')
    });

    return baseTabs;
});

// Map tab index to component type: [General, Content, QR & Access]
const getTabComponent = (index) => {
    if (index === 0) return 'general';
    if (index === 1) return 'content';
    if (index === 2) return 'qr';
    return null;
};

// Handle digital access settings update
const handleDigitalAccessUpdated = (updatedCard) => {
    emit('update-card', updatedCard);
};

const emptyStateTitle = computed(() => {
    return props.hasCards ? t('dashboard.select_a_card') : t('dashboard.no_cards_yet');
});

const emptyStateMessage = computed(() => {
    return props.hasCards
        ? t('dashboard.choose_card_to_view')
        : t('dashboard.create_first_card_instruction');
});

// Content count for setup guide
const contentCount = ref(0);
let lastContentCountCardId = null;
let contentCountDirty = false;

const fetchContentCount = async (cardId) => {
    try {
        const result = await contentItemStore.getContentItemsCount(cardId);
        contentCount.value = result?.total_count ?? 0;
        lastContentCountCardId = cardId;
        contentCountDirty = false;
    } catch {
        contentCount.value = 0;
    }
};

// Fetch content count when card changes
watch(() => props.selectedCard?.id, (newId) => {
    if (newId) {
        fetchContentCount(newId);
    } else {
        contentCount.value = 0;
        lastContentCountCardId = null;
    }
}, { immediate: true });

// Mark dirty when leaving General tab (user may edit content on other tabs)
// Only re-fetch when returning to General tab if we left it
watch(() => props.activeTab, (newTab, oldTab) => {
    if (oldTab === '0' && newTab !== '0') {
        contentCountDirty = true;
    }
    if (newTab === '0' && contentCountDirty && props.selectedCard?.id) {
        fetchContentCount(props.selectedCard.id);
    }
});


</script>

<style scoped>
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