<template>
    <div class="bg-white rounded-xl shadow-lg border border-slate-200 flex flex-col overflow-y-auto h-full">
        <!-- Empty State: No cards at all → rich onboarding -->
        <div v-if="!selectedCard && !props.hasCards" class="flex flex-col items-center px-8 py-10 w-full">
            <!-- Header -->
            <div class="text-center mb-6">
                <div class="w-14 h-14 bg-gradient-to-br from-blue-500 to-indigo-600 rounded-2xl flex items-center justify-center mx-auto mb-4 shadow-lg">
                    <i class="pi pi-sparkles text-xl text-white"></i>
                </div>
                <h2 class="text-2xl font-bold text-slate-900 mb-2">{{ $t('dashboard.empty_welcome_title') }}</h2>
                <p class="text-slate-500 text-sm max-w-md mx-auto">{{ $t('dashboard.empty_welcome_subtitle') }}</p>
            </div>

            <!-- 3 Action Cards -->
            <div class="grid grid-cols-1 sm:grid-cols-3 gap-4 w-full max-w-2xl mb-6">
                <!-- Create from scratch -->
                <button
                    @click="emit('create-card')"
                    class="group flex flex-col items-center text-center p-5 rounded-xl border-2 border-blue-200 bg-blue-50 hover:bg-blue-100 hover:border-blue-400 transition-all duration-200 cursor-pointer"
                >
                    <div class="w-11 h-11 bg-blue-500 rounded-xl flex items-center justify-center mb-3 group-hover:scale-110 transition-transform shadow-md">
                        <i class="pi pi-plus text-lg text-white"></i>
                    </div>
                    <span class="font-semibold text-slate-900 text-sm mb-1">{{ $t('dashboard.empty_action_create') }}</span>
                    <span class="text-xs text-slate-500">{{ $t('dashboard.empty_action_create_desc') }}</span>
                </button>

                <!-- Import project -->
                <button
                    @click="emit('open-import')"
                    class="group flex flex-col items-center text-center p-5 rounded-xl border-2 border-slate-200 bg-white hover:bg-slate-50 hover:border-slate-400 transition-all duration-200 cursor-pointer"
                >
                    <div class="w-11 h-11 bg-slate-700 rounded-xl flex items-center justify-center mb-3 group-hover:scale-110 transition-transform shadow-md">
                        <i class="pi pi-upload text-lg text-white"></i>
                    </div>
                    <span class="font-semibold text-slate-900 text-sm mb-1">{{ $t('dashboard.empty_action_import') }}</span>
                    <span class="text-xs text-slate-500">{{ $t('dashboard.empty_action_import_desc') }}</span>
                </button>

                <!-- Start from template -->
                <button
                    @click="emit('open-template')"
                    class="group flex flex-col items-center text-center p-5 rounded-xl border-2 border-violet-200 bg-violet-50 hover:bg-violet-100 hover:border-violet-400 transition-all duration-200 cursor-pointer"
                >
                    <div class="w-11 h-11 bg-violet-500 rounded-xl flex items-center justify-center mb-3 group-hover:scale-110 transition-transform shadow-md">
                        <i class="pi pi-copy text-lg text-white"></i>
                    </div>
                    <span class="font-semibold text-slate-900 text-sm mb-1">{{ $t('dashboard.empty_action_template') }}</span>
                    <span class="text-xs text-slate-500">{{ $t('dashboard.empty_action_template_desc') }}</span>
                </button>
            </div>

            <!-- Use case suggestions -->
            <div class="w-full max-w-2xl">
                <p class="text-xs font-semibold text-slate-400 uppercase tracking-wider text-center mb-3">{{ $t('dashboard.empty_suggestions_title') }}</p>
                <div class="grid grid-cols-2 sm:grid-cols-4 gap-2">
                    <button
                        v-for="suggestion in useCaseSuggestions"
                        :key="suggestion.key"
                        @click="emit('create-card')"
                        class="flex items-center gap-2 px-3 py-2.5 rounded-lg border border-slate-200 bg-white hover:bg-slate-50 hover:border-slate-300 transition-all text-left group"
                    >
                        <span class="text-base">{{ suggestion.emoji }}</span>
                        <span class="text-xs text-slate-600 group-hover:text-slate-900 font-medium leading-tight">{{ $t(suggestion.key) }}</span>
                    </button>
                </div>
            </div>
        </div>

        <!-- Empty State: Has cards but none selected -->
        <div v-else-if="!selectedCard && props.hasCards" class="flex items-center justify-center flex-1 p-6">
            <div class="text-center">
                <div class="w-16 h-16 bg-slate-100 rounded-full flex items-center justify-center mx-auto mb-4">
                    <i class="pi pi-arrow-left text-2xl text-slate-400"></i>
                </div>
                <h3 class="text-lg font-medium text-slate-900 mb-2">{{ $t('dashboard.select_a_card') }}</h3>
                <p class="text-sm text-slate-500">{{ $t('dashboard.choose_card_to_view') }}</p>
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
            :style="{ width: '90vw', maxWidth: '42rem' }"
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
    'card-imported',
    'create-card',
    'open-import',
    'open-template',
]);

const useCaseSuggestions = [
    { key: 'dashboard.suggestion_restaurant', emoji: '🍽️' },
    { key: 'dashboard.suggestion_museum', emoji: '🏛️' },
    { key: 'dashboard.suggestion_product', emoji: '📦' },
    { key: 'dashboard.suggestion_event', emoji: '🎉' },
    { key: 'dashboard.suggestion_portfolio', emoji: '🎨' },
    { key: 'dashboard.suggestion_education', emoji: '📚' },
    { key: 'dashboard.suggestion_hotel', emoji: '🏨' },
    { key: 'dashboard.suggestion_linkinbio', emoji: '🔗' },
];

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