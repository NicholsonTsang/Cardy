<template>
    <div class="flex flex-col gap-4">

        <!-- Translation Management -->
        <div class="rounded-xl border border-slate-200 bg-white overflow-hidden">
            <!-- Header -->
            <div class="flex items-center gap-2 px-4 py-3 border-b border-slate-200 bg-slate-50/80">
                <i class="pi pi-language text-sm text-slate-500"></i>
                <span class="text-sm font-medium text-slate-700 truncate">{{ $t('translation.sectionTitle') }}</span>
                <span v-if="translatedCount > 0"
                    class="shrink-0 px-2 py-0.5 rounded-full text-[0.6875rem] font-medium bg-blue-100 text-blue-700"
                >{{ translatedCount }}/{{ totalLanguagesCount - 1 }}</span>
                <span v-else
                    class="shrink-0 px-2 py-0.5 rounded-full text-[0.6875rem] font-medium bg-slate-100 text-slate-500"
                >{{ $t('translation.none') }}</span>
                <div class="flex-1"></div>
                <button
                    v-if="canTranslate"
                    type="button"
                    @click="openTranslationDialog('translate')"
                    class="flex items-center justify-center w-8 h-7 rounded-md text-slate-400 hover:text-blue-600 hover:bg-blue-50 transition-all"
                    v-tooltip.bottom="$t('translation.dialog.addTranslations')"
                >
                    <i class="pi pi-plus text-xs"></i>
                </button>
                <button
                    v-if="canTranslate"
                    type="button"
                    @click="openTranslationDialog('manage')"
                    class="flex items-center justify-center w-8 h-7 rounded-md text-slate-400 hover:text-slate-700 hover:bg-slate-100 transition-all"
                    v-tooltip.bottom="$t('translation.manage')"
                >
                    <i class="pi pi-cog text-xs"></i>
                </button>
            </div>

            <!-- Content -->
            <div class="p-3 space-y-2">
                <!-- Preview dropdown (shown when translations exist) -->
                <div v-if="translatedCount > 0" class="flex items-center gap-2">
                    <span class="text-xs text-slate-500 shrink-0">{{ $t('translation.preview') }}:</span>
                    <Select
                        v-model="selectedPreviewLanguage"
                        :options="languageOptions"
                        optionLabel="label"
                        optionValue="value"
                        class="flex-1 language-selector-compact"
                    >
                        <template #value="slotProps">
                            <div v-if="slotProps.value" class="flex items-center gap-1.5 text-xs">
                                <span>{{ getLanguageFlag(slotProps.value) }}</span>
                                <span>{{ getLanguageName(slotProps.value) }}</span>
                            </div>
                            <div v-else class="flex items-center gap-1.5 text-xs">
                                <span>{{ getLanguageFlag(cardProp?.original_language || 'en') }}</span>
                                <span>{{ $t('translation.original') }}</span>
                            </div>
                        </template>
                        <template #option="slotProps">
                            <div class="flex items-center gap-1.5 text-[0.8125rem]">
                                <span>{{ getLanguageFlag(slotProps.option.value) }}</span>
                                <span>{{ slotProps.option.label }}</span>
                            </div>
                        </template>
                    </Select>
                </div>

                <!-- Language Status List -->
                <div v-if="allLanguageStatuses.length > 0" class="space-y-0.5">
                    <div
                        v-for="lang in displayedLanguages"
                        :key="lang.language"
                        class="flex items-center gap-2 py-1.5 px-2 rounded-md hover:bg-slate-50 transition-colors"
                    >
                        <!-- Flag + Name -->
                        <span class="text-sm shrink-0">{{ getLanguageFlag(lang.language) }}</span>
                        <span class="text-xs font-medium text-slate-700 truncate flex-1 min-w-0">{{ lang.language_name }}</span>

                        <!-- Status indicators -->
                        <template v-if="lang.status === 'original'">
                            <span class="text-[11px] text-slate-400 shrink-0">({{ $t('translation.original') }})</span>
                        </template>
                        <template v-else-if="lang.status === 'up_to_date'">
                            <i class="pi pi-check text-[10px] text-emerald-600 shrink-0"></i>
                            <span class="text-[11px] text-emerald-700 shrink-0">{{ $t('translation.status.up_to_date') }}</span>
                            <span v-if="lang.translated_at" class="text-[10px] text-slate-400 shrink-0">{{ formatRelativeTime(lang.translated_at) }}</span>
                        </template>
                        <template v-else-if="lang.status === 'outdated'">
                            <i class="pi pi-exclamation-circle text-[10px] text-amber-600 shrink-0"></i>
                            <span class="text-[11px] text-amber-700 shrink-0">{{ $t('translation.status.outdated') }}</span>
                            <span v-if="lang.translated_at" class="text-[10px] text-slate-400 shrink-0">{{ formatRelativeTime(lang.translated_at) }}</span>
                            <button
                                v-if="canTranslate"
                                @click="openTranslationDialog('translate', [lang.language])"
                                class="px-1.5 py-0.5 rounded text-[10px] font-medium bg-amber-100 text-amber-700 hover:bg-amber-200 transition-colors shrink-0"
                            >
                                <i class="pi pi-refresh text-[8px] mr-0.5"></i>{{ $t('translation.actions.update') }}
                            </button>
                        </template>
                        <template v-else>
                            <span class="text-[11px] text-slate-400 shrink-0">{{ $t('translation.status.not_translated') }}</span>
                        </template>
                    </div>

                    <!-- Show all / Show less toggle -->
                    <button
                        v-if="allLanguageStatuses.length > 5"
                        @click="showAllLanguages = !showAllLanguages"
                        class="w-full text-center py-1.5 text-xs text-blue-600 hover:text-blue-700 hover:bg-blue-50 rounded-md transition-colors"
                    >
                        {{ showAllLanguages ? $t('translation.showLess') : $t('translation.showAllLanguages', { count: allLanguageStatuses.length }) }}
                    </button>
                </div>

                <!-- Outdated Warning Banner -->
                <div v-if="outdatedCount > 0 && canTranslate"
                    class="flex items-center gap-3 py-2 px-3 bg-amber-50 border border-amber-200 rounded-lg"
                >
                    <i class="pi pi-exclamation-triangle text-amber-500 text-xs shrink-0"></i>
                    <span class="text-xs text-amber-800 flex-1">{{ $t('translation.outdatedWarning', { count: outdatedCount }) }}</span>
                    <button
                        @click="openTranslationDialog('translate', translationStore.outdatedLanguages.map(l => l.language))"
                        class="px-2.5 py-1 rounded-md text-[11px] font-medium bg-amber-200 text-amber-800 hover:bg-amber-300 transition-colors shrink-0"
                    >
                        {{ $t('translation.updateAll') }}
                    </button>
                </div>

                <!-- Empty state: no translations + can translate -->
                <div v-if="translatedCount === 0 && canTranslate"
                    class="flex items-center gap-3 py-2.5 px-3 bg-slate-50 border border-slate-200 rounded-lg cursor-pointer hover:border-slate-300 transition-colors"
                    @click="openTranslationDialog('translate')"
                >
                    <i class="pi pi-plus-circle text-slate-400 text-xs shrink-0"></i>
                    <span class="text-xs text-slate-600 flex-1">{{ $t('dashboard.translation_hint') }}</span>
                    <i class="pi pi-arrow-right text-[10px] text-slate-400"></i>
                </div>

                <!-- Subscription guard: can't translate -->
                <div v-if="!canTranslate"
                    class="flex items-center gap-3 py-2.5 px-3 bg-slate-50 border border-slate-200 rounded-lg"
                >
                    <i class="pi pi-lock text-slate-400 text-xs shrink-0"></i>
                    <span class="text-xs text-slate-500 flex-1">{{ $t('subscription.upgrade_for_translations') }}</span>
                </div>
            </div>
        </div>

        <!-- AI Configuration -->
        <div class="rounded-xl border border-slate-200 bg-white overflow-hidden">
            <!-- Header -->
            <div class="flex items-center gap-2 px-4 py-3 border-b border-slate-200 bg-slate-50/80">
                <i :class="['pi pi-sparkles text-sm', cardProp.conversation_ai_enabled ? 'text-blue-500' : 'text-slate-400']"></i>
                <span class="text-sm font-medium text-slate-700 truncate">{{ $t('dashboard.ai_assistance_configuration') }}</span>
                <span :class="[
                    'shrink-0 px-2 py-0.5 rounded-full text-[0.6875rem] font-medium',
                    cardProp.conversation_ai_enabled
                        ? 'bg-emerald-100 text-emerald-700'
                        : 'bg-slate-100 text-slate-500'
                ]">
                    {{ cardProp.conversation_ai_enabled ? $t('common.enabled') : $t('common.disabled') }}
                </span>
                <div class="flex-1"></div>
                <button
                    v-if="cardProp.conversation_ai_enabled || hasAiData"
                    type="button"
                    @click="editSection = 'ai'; showEditDialog = true"
                    class="flex items-center justify-center w-8 h-7 rounded-md text-slate-400 hover:text-slate-700 hover:bg-slate-100 transition-all"
                    v-tooltip.bottom="$t('dashboard.configure')"
                >
                    <i class="pi pi-pencil text-xs"></i>
                </button>
            </div>

            <!-- Enabled: cost info + expandable previews -->
            <template v-if="cardProp.conversation_ai_enabled">
                <div class="p-3 space-y-2">
                    <!-- Cost info -->
                    <div class="flex items-center gap-3 py-2 px-3 bg-amber-50 border border-amber-200 rounded-lg">
                        <i class="pi pi-bolt text-amber-500 text-xs shrink-0"></i>
                        <div class="flex-1 min-w-0">
                            <span class="text-xs text-amber-800">{{ $t('dashboard.ai_cost_notice_short') }}</span>
                        </div>
                        <div class="flex items-baseline gap-1 shrink-0">
                            <span class="text-sm font-semibold text-slate-800">${{ aiSessionCost }}</span>
                            <span class="text-[0.6rem] text-slate-500 uppercase">{{ $t('dashboard.per_session') }}</span>
                        </div>
                    </div>
                    <!-- AI Instruction -->
                    <div v-if="cardProp.ai_instruction"
                        class="py-2 px-3 bg-slate-50 border border-slate-200 rounded-lg text-xs cursor-pointer hover:border-slate-300 transition-colors"
                        @click="toggleAiSection('instruction')"
                    >
                        <div class="flex items-center gap-2 min-w-0">
                            <i class="pi pi-user text-slate-400 text-xs shrink-0"></i>
                            <span class="text-slate-700 font-medium truncate">{{ $t('dashboard.ai_instruction_role') }}</span>
                            <div class="flex-1"></div>
                            <i :class="['pi text-[10px] text-slate-400 shrink-0 transition-transform', expandedAiSections.instruction ? 'pi-chevron-up' : 'pi-chevron-down']"></i>
                        </div>
                        <p v-if="expandedAiSections.instruction" class="text-slate-500 mt-2 whitespace-pre-line leading-relaxed line-clamp-6">{{ cardProp.ai_instruction }}</p>
                        <p v-else class="text-slate-400 mt-1.5 italic truncate">{{ truncateText(cardProp.ai_instruction, 80) }}</p>
                    </div>
                    <!-- AI Knowledge Base -->
                    <div v-if="cardProp.ai_knowledge_base"
                        class="py-2 px-3 bg-slate-50 border border-slate-200 rounded-lg text-xs cursor-pointer hover:border-slate-300 transition-colors"
                        @click="toggleAiSection('knowledge')"
                    >
                        <div class="flex items-center gap-2 min-w-0">
                            <i class="pi pi-book text-slate-400 text-xs shrink-0"></i>
                            <span class="text-slate-700 font-medium truncate">{{ $t('dashboard.ai_knowledge_base') }}</span>
                            <div class="flex-1"></div>
                            <i :class="['pi text-[10px] text-slate-400 shrink-0 transition-transform', expandedAiSections.knowledge ? 'pi-chevron-up' : 'pi-chevron-down']"></i>
                        </div>
                        <p v-if="expandedAiSections.knowledge" class="text-slate-500 mt-2 whitespace-pre-line leading-relaxed line-clamp-6">{{ cardProp.ai_knowledge_base }}</p>
                        <p v-else class="text-slate-400 mt-1.5 italic truncate">{{ truncateText(cardProp.ai_knowledge_base, 80) }}</p>
                    </div>
                    <!-- General Welcome Message -->
                    <div v-if="cardProp.ai_welcome_general"
                        class="py-2 px-3 bg-slate-50 border border-slate-200 rounded-lg text-xs cursor-pointer hover:border-slate-300 transition-colors"
                        @click="toggleAiSection('welcomeGeneral')"
                    >
                        <div class="flex items-center gap-2 min-w-0">
                            <i class="pi pi-comment text-slate-400 text-xs shrink-0"></i>
                            <span class="text-slate-700 font-medium truncate">{{ $t('dashboard.ai_welcome_general') }}</span>
                            <div class="flex-1"></div>
                            <i :class="['pi text-[10px] text-slate-400 shrink-0 transition-transform', expandedAiSections.welcomeGeneral ? 'pi-chevron-up' : 'pi-chevron-down']"></i>
                        </div>
                        <p v-if="expandedAiSections.welcomeGeneral" class="text-slate-500 mt-2 whitespace-pre-line leading-relaxed">{{ cardProp.ai_welcome_general }}</p>
                        <p v-else class="text-slate-400 mt-1.5 italic truncate">{{ truncateText(cardProp.ai_welcome_general, 80) }}</p>
                    </div>
                    <!-- Item Welcome Message -->
                    <div v-if="cardProp.ai_welcome_item"
                        class="py-2 px-3 bg-slate-50 border border-slate-200 rounded-lg text-xs cursor-pointer hover:border-slate-300 transition-colors"
                        @click="toggleAiSection('welcomeItem')"
                    >
                        <div class="flex items-center gap-2 min-w-0">
                            <i class="pi pi-comments text-slate-400 text-xs shrink-0"></i>
                            <span class="text-slate-700 font-medium truncate">{{ $t('dashboard.ai_welcome_item') }}</span>
                            <div class="flex-1"></div>
                            <i :class="['pi text-[10px] text-slate-400 shrink-0 transition-transform', expandedAiSections.welcomeItem ? 'pi-chevron-up' : 'pi-chevron-down']"></i>
                        </div>
                        <p v-if="expandedAiSections.welcomeItem" class="text-slate-500 mt-2 whitespace-pre-line leading-relaxed">{{ cardProp.ai_welcome_item }}</p>
                        <p v-else class="text-slate-400 mt-1.5 italic truncate">{{ truncateText(cardProp.ai_welcome_item, 80) }}</p>
                    </div>
                </div>
            </template>

            <!-- Disabled: preserved data notice or empty state -->
            <template v-else>
                <div v-if="hasAiData" class="p-3">
                    <div class="flex items-center gap-3 py-2.5 px-3 bg-slate-50 border border-slate-200 rounded-lg">
                        <i class="pi pi-save text-slate-400 text-xs shrink-0"></i>
                        <div class="flex-1 min-w-0 flex flex-col gap-0.5">
                            <span class="text-xs font-medium text-slate-700">{{ $t('dashboard.ai_data_preserved_title') }}</span>
                            <span class="text-[0.6875rem] text-slate-500 truncate">{{ $t('dashboard.ai_data_preserved_view_message') }}</span>
                        </div>
                    </div>
                </div>
                <div v-else class="flex flex-col items-center text-center py-6 px-4 gap-3">
                    <div class="w-12 h-12 rounded-full bg-slate-100 flex items-center justify-center">
                        <i class="pi pi-sparkles text-xl text-slate-300"></i>
                    </div>
                    <div>
                        <p class="text-sm font-medium text-slate-600 m-0">{{ $t('dashboard.ai_empty_title') }}</p>
                        <p class="text-xs text-slate-400 m-0 mt-1 max-w-xs">{{ $t('dashboard.enable_ai_to_configure') }}</p>
                    </div>
                    <Button
                        :label="$t('dashboard.enable_and_configure')"
                        icon="pi pi-sparkles"
                        size="small"
                        outlined
                        @click="editSection = 'ai'; showEditDialog = true"
                    />
                </div>
            </template>
        </div>

        <!-- Translation Dialog -->
        <TranslationDialog
            v-model:visible="showTranslationDialog"
            :card-id="cardProp.id"
            :available-languages="availableLanguagesForDialog"
            :initial-mode="translationDialogMode"
            :pre-selected-languages="preSelectedLanguages"
            @translated="handleTranslationSuccess"
        />

        <!-- Edit Dialog (AI section) -->
        <MyDialog
            v-model="showEditDialog"
            :header="editDialogHeader"
            :confirmHandle="handleSaveEdit"
            :confirmLabel="$t('dashboard.save_changes')"
            confirmSeverity="primary"
            :cancelLabel="$t('common.cancel')"
            :successMessage="$t('dashboard.card_updated')"
            :errorMessage="$t('messages.operation_failed')"
            @cancel="handleCancelEdit"
            @hide="handleDialogHide"
            :style="editDialogStyle"
        >
            <CardCreateEditForm
                ref="editFormRef"
                :cardProp="cardProp"
                :isEditMode="true"
                :isInDialog="true"
                :sections="editFormSections"
            />
        </MyDialog>

    </div>
</template>

<script setup>
import { computed, ref, onMounted, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import Button from 'primevue/button';
import Select from 'primevue/select';
import MyDialog from '@/components/MyDialog.vue';
import CardCreateEditForm from './CardCreateEditForm.vue';
import TranslationDialog from '@/components/Card/TranslationDialog.vue';
import { useTranslationStore, SUPPORTED_LANGUAGES } from '@/stores/translation';
import { useSubscriptionStore } from '@/stores/subscription';
import { useAuthStore } from '@/stores/auth';
import { getLanguageFlag, getLanguageName } from '@/utils/formatters';
import { SubscriptionConfig } from '@/config/subscription';

const { t } = useI18n();

const aiSessionCost = SubscriptionConfig.premium.aiEnabledSessionCostUsd;
const translationStore = useTranslationStore();
const subscriptionStore = useSubscriptionStore();
const authStore = useAuthStore();

const props = defineProps({
    cardProp: {
        type: Object,
        required: true
    },
    updateCardFn: {
        type: Function,
        required: true
    },
});

const emit = defineEmits(['update-card']);

// Edit dialog state
const showEditDialog = ref(false);
const editSection = ref('ai');
const editFormRef = ref(null);

// Translation dialog state
const showTranslationDialog = ref(false);
const translationDialogMode = ref('translate');
const preSelectedLanguages = ref([]);
const showAllLanguages = ref(false);
const selectedPreviewLanguage = ref(null);

// AI expandable section state
const expandedAiSections = ref({
    instruction: true,
    knowledge: true,
    welcomeGeneral: true,
    welcomeItem: true
});

// Edit dialog config (AI only in this tab)
const editFormSections = computed(() => ['ai']);

const editDialogHeader = computed(() => t('dashboard.ai_assistant_configuration'));

const editDialogStyle = computed(() => 'width: 90vw; max-width: 68rem;');

// Translation computed
const isAdmin = computed(() => authStore.getUserRole() === 'admin');
const canTranslate = computed(() => isAdmin.value || subscriptionStore.canTranslate);

const translatedCount = computed(() => {
    return translationStore.upToDateLanguages.length + translationStore.outdatedLanguages.length;
});

const outdatedCount = computed(() => {
    return translationStore.outdatedLanguages.length;
});

const totalLanguagesCount = computed(() => {
    return Object.keys(SUPPORTED_LANGUAGES).length;
});

const allLanguageStatuses = computed(() => {
    const statuses = Object.values(translationStore.translationStatus);
    if (statuses.length === 0) return [];

    const statusOrder = { original: 0, up_to_date: 1, outdated: 2, not_translated: 3 };
    return [...statuses].sort((a, b) => {
        const orderA = statusOrder[a.status] ?? 4;
        const orderB = statusOrder[b.status] ?? 4;
        if (orderA !== orderB) return orderA - orderB;
        return a.language_name.localeCompare(b.language_name);
    });
});

const displayedLanguages = computed(() => {
    return showAllLanguages.value ? allLanguageStatuses.value : allLanguageStatuses.value.slice(0, 5);
});

const availableLanguagesForDialog = computed(() => {
    return Object.values(translationStore.translationStatus).filter(
        (status) => status.status !== 'original'
    );
});

const availableTranslations = computed(() => {
    if (!props.cardProp?.translations) return [];
    return Object.keys(props.cardProp.translations);
});

const languageOptions = computed(() => {
    const originalLanguage = props.cardProp?.original_language || 'en';
    const options = [
        {
            label: `${getLanguageName(originalLanguage)} (${t('translation.original')})`,
            value: null
        }
    ];

    availableTranslations.value.forEach(langCode => {
        options.push({
            label: getLanguageName(langCode),
            value: langCode
        });
    });

    return options;
});

// AI computed
const hasAiData = computed(() => {
    return !!(props.cardProp?.ai_instruction?.trim() ||
              props.cardProp?.ai_knowledge_base?.trim() ||
              props.cardProp?.ai_welcome_general?.trim() ||
              props.cardProp?.ai_welcome_item?.trim());
});

// Translation methods
const openTranslationDialog = (mode, preSelected = []) => {
    translationDialogMode.value = mode;
    preSelectedLanguages.value = preSelected;
    showTranslationDialog.value = true;
};

const handleTranslationSuccess = async () => {
    if (props.cardProp?.id) {
        await translationStore.fetchTranslationStatus(props.cardProp.id);
    }
};

const formatRelativeTime = (dateString) => {
    if (!dateString) return '';
    const now = Date.now();
    const date = new Date(dateString).getTime();
    const diffMs = now - date;
    const diffMin = Math.floor(diffMs / 60000);
    if (diffMin < 1) return t('common.just_now');
    if (diffMin < 60) return `${diffMin}m`;
    const diffHr = Math.floor(diffMin / 60);
    if (diffHr < 24) return `${diffHr}h`;
    const diffDay = Math.floor(diffHr / 24);
    if (diffDay < 30) return `${diffDay}d`;
    const diffMo = Math.floor(diffDay / 30);
    if (diffMo < 12) return `${diffMo}mo`;
    const diffYr = Math.floor(diffDay / 365);
    return `${diffYr}y`;
};

// AI methods
function toggleAiSection(section) {
    expandedAiSections.value[section] = !expandedAiSections.value[section];
}

const truncateText = (text, maxLength) => {
    if (!text) return '';
    const plainText = text.replace(/[#*_`~\[\]()]/g, '').replace(/\n/g, ' ');
    if (plainText.length <= maxLength) return plainText;
    return plainText.substring(0, maxLength) + '...';
};

// Edit dialog handlers
const handleSaveEdit = async () => {
    if (editFormRef.value) {
        const payload = editFormRef.value.getPayload();
        await props.updateCardFn(payload);
        await translationStore.fetchTranslationStatus(props.cardProp.id);
    }
};

const handleCancelEdit = () => {
    showEditDialog.value = false;
    if (editFormRef.value) {
        editFormRef.value.initializeForm();
    }
};

const handleDialogHide = () => {
    if (editFormRef.value) {
        editFormRef.value.initializeForm();
    }
    editSection.value = 'ai';
};

// Lifecycle
onMounted(async () => {
    if (props.cardProp?.id) {
        await translationStore.fetchTranslationStatus(props.cardProp.id);
    }
    await subscriptionStore.fetchSubscription();
});

watch(() => props.cardProp?.id, async (newId) => {
    if (newId) {
        showAllLanguages.value = false;
        selectedPreviewLanguage.value = null;
        await translationStore.fetchTranslationStatus(newId);
    }
});
</script>

<style scoped>
/* PrimeVue Dropdown override for compact language selector */
.language-selector-compact {
    border: none !important;
    background: transparent !important;
    padding: 0 !important;
    min-width: auto !important;
}

.language-selector-compact :deep(.p-dropdown-label) {
    padding: 0.25rem 0.5rem;
    font-size: 0.8125rem;
    background: white;
    border: 1px solid #e2e8f0;
    border-radius: 0.25rem;
}

.language-selector-compact :deep(.p-dropdown-trigger) {
    width: 1.5rem;
    padding: 0;
}
</style>
