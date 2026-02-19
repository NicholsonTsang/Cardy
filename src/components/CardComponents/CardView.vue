<template>
    <div class="xl:grid xl:grid-cols-[1fr_auto] gap-4">
        <!-- Left Column: Configuration -->
        <div class="flex flex-col gap-4 min-w-0">

        <!-- Project Overview Card -->
        <div v-if="cardProp" class="rounded-2xl bg-white border border-slate-200 shadow-sm overflow-hidden">
            <!-- Header: Icon + Title + Badge + Actions -->
            <div class="p-4">
                <div class="flex items-start gap-3">
                    <!-- Project Icon / Cover Image -->
                    <div class="w-12 h-12 rounded-xl flex items-center justify-center shrink-0 overflow-hidden"
                         :class="cardProp.image_url ? '' : 'bg-gradient-to-br from-cyan-500 to-cyan-600'">
                        <img v-if="cardProp.image_url" :src="cardProp.image_url" class="w-full h-full object-cover" />
                        <i v-else class="pi pi-qrcode text-xl text-white"></i>
                    </div>

                    <!-- Title + Badge + Description -->
                    <div class="flex-1 min-w-0">
                        <div class="flex items-center gap-2 flex-wrap">
                            <h1 class="text-lg font-bold text-slate-900 m-0 truncate">{{ displayedCardName }}</h1>
                            <span class="inline-flex items-center px-2 py-0.5 rounded-full text-[11px] font-medium bg-slate-100 text-slate-600 shrink-0">
                                {{ getContentModeLabel(cardProp.content_mode) }}
                            </span>
                            <span v-if="cardProp.conversation_ai_enabled" class="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[11px] font-medium bg-blue-50 text-blue-600 shrink-0">
                                <i class="pi pi-sparkles text-[10px]"></i> AI
                            </span>
                            <!-- Action buttons (right-aligned) -->
                            <div class="ml-auto flex items-center gap-0.5 sm:gap-1 shrink-0 flex-wrap justify-end">
                                <Button
                                    icon="pi pi-pencil"
                                    @click="editSection = 'details'; showEditDialog = true"
                                    severity="secondary"
                                    text
                                    size="small"
                                    v-tooltip.bottom="$t('dashboard.edit_project_details')"
                                />
                                <Button
                                    icon="pi pi-mobile"
                                    @click="emit('show-preview')"
                                    severity="secondary"
                                    text
                                    size="small"
                                    v-tooltip.bottom="$t('dashboard.preview')"
                                />
                                <Button
                                    icon="pi pi-copy"
                                    @click="showDuplicateDialog = true"
                                    severity="secondary"
                                    text
                                    size="small"
                                    v-tooltip.bottom="$t('dashboard.duplicate_card')"
                                />
                                <Button
                                    icon="pi pi-download"
                                    @click="showExportDialog = true"
                                    severity="secondary"
                                    text
                                    size="small"
                                    v-tooltip.bottom="$t('common.export')"
                                />
                                <Button
                                    icon="pi pi-trash"
                                    @click="handleRequestDelete"
                                    severity="danger"
                                    text
                                    size="small"
                                    v-tooltip.bottom="$t('common.delete')"
                                />
                            </div>
                        </div>
                        <p v-if="displayedCardDescription" class="text-sm text-slate-500 m-0 mt-1 leading-normal line-clamp-2">
                            {{ truncateText(displayedCardDescription, 200) }}
                        </p>
                        <p v-else
                            class="text-sm text-slate-400 italic m-0 mt-1 cursor-pointer hover:text-slate-500 transition-colors"
                            @click="editSection = 'details'; showEditDialog = true">
                            {{ $t('dashboard.add_description_hint') }}
                        </p>
                    </div>
                </div>
            </div>

            <!-- Stats row -->
            <div class="grid grid-cols-4 divide-x divide-slate-100 border-t border-slate-100">
                <div class="px-3 py-2.5 text-center">
                    <p class="text-base font-bold text-slate-900 m-0 leading-none">{{ formatNumber(cardProp.total_sessions || 0) }}</p>
                    <p class="text-[11px] text-slate-400 m-0 mt-0.5">{{ $t('dashboard.total_sessions') }}</p>
                </div>
                <div class="px-3 py-2.5 text-center">
                    <p class="text-base font-bold text-slate-900 m-0 leading-none">{{ formatNumber(cardProp.monthly_sessions || 0) }}</p>
                    <p class="text-[11px] text-slate-400 m-0 mt-0.5">{{ $t('dashboard.this_month') }}</p>
                </div>
                <div class="px-3 py-2.5 text-center">
                    <p class="text-base font-bold m-0 leading-none" :class="contentCount > 0 ? 'text-slate-900' : 'text-amber-500'">{{ contentCount }}</p>
                    <p class="text-[11px] text-slate-400 m-0 mt-0.5">{{ $t('dashboard.content_items') }}</p>
                </div>
                <div class="px-3 py-2.5 text-center">
                    <p class="text-base font-bold text-slate-900 m-0 leading-none">{{ cardProp.active_qr_codes || 0 }}</p>
                    <p class="text-[11px] text-slate-400 m-0 mt-0.5">{{ $t('dashboard.active_qr_codes') }}</p>
                </div>
            </div>

            <!-- Metadata Footer -->
            <div class="px-4 py-2 border-t border-slate-100 bg-slate-50/50">
                <div class="flex items-center gap-x-3 gap-y-1 flex-wrap text-xs text-slate-400">
                    <span class="flex items-center gap-1">
                        <i class="pi pi-globe text-[10px]"></i>
                        {{ getLanguageFlag(cardProp.original_language) }} {{ getLanguageName(cardProp.original_language) }}
                    </span>
                    <span class="text-slate-200">·</span>
                    <span class="flex items-center gap-1">
                        <i class="pi pi-language text-[10px]"></i>
                        {{ translatedCount }} {{ $t('dashboard.translations').toLowerCase() }}
                    </span>
                    <span class="text-slate-200">·</span>
                    <span class="flex items-center gap-1">
                        <i class="pi pi-calendar text-[10px]"></i>
                        {{ formatDate(cardProp.created_at) }}
                    </span>
                </div>
            </div>
        </div>

        <!-- Export Dialog -->
        <Dialog
            v-model:visible="showExportDialog"
            modal
            :header="$t('common.export_card_data')"
            :style="{ width: '90vw', maxWidth: '52rem' }"
            class="standardized-dialog"
        >
            <CardExport
                :card="cardProp"
                @exported="showExportDialog = false"
                @cancel="showExportDialog = false"
            />
        </Dialog>

        <!-- Duplicate Card Dialog -->
        <DuplicateCardDialog
            v-model:visible="showDuplicateDialog"
            :card="cardProp ? { id: cardProp.id, name: cardProp.name } : null"
            @duplicated="handleDuplicated"
        />

        <!-- Setup Checklist / Quick Nav -->
        <template v-if="cardProp">
            <div class="bg-white border border-slate-200 rounded-xl overflow-hidden">
                <div class="px-4 py-3 border-b border-slate-100 flex items-center gap-2">
                    <i class="pi pi-check-circle text-sm text-slate-400"></i>
                    <h3 class="text-sm font-semibold text-slate-700 m-0">{{ $t('dashboard.setup_checklist') }}</h3>
                    <span class="ml-auto text-xs text-slate-400">{{ completedSteps }}/{{ totalSteps }} {{ $t('common.complete') }}</span>
                </div>
                <div class="divide-y divide-slate-50">
                    <!-- Step 1: Content -->
                    <button
                        class="w-full flex items-center gap-3 px-4 py-3 hover:bg-slate-50 transition-colors text-left group"
                        @click="emit('navigate-tab', '1')"
                    >
                        <div class="w-7 h-7 rounded-full flex items-center justify-center shrink-0 transition-all"
                             :class="contentCount > 0 ? 'bg-emerald-100' : 'bg-amber-100'">
                            <i class="text-xs" :class="contentCount > 0 ? 'pi pi-check text-emerald-600' : 'pi pi-list text-amber-600'"></i>
                        </div>
                        <div class="flex-1 min-w-0">
                            <p class="text-sm font-medium m-0" :class="contentCount > 0 ? 'text-slate-700' : 'text-slate-800'">{{ $t('dashboard.content') }}</p>
                            <p class="text-xs m-0" :class="contentCount > 0 ? 'text-emerald-600' : 'text-amber-600'">
                                {{ contentCount > 0 ? `${contentCount} ${$t('dashboard.content_items').toLowerCase()}` : $t('dashboard.no_content_hint') }}
                            </p>
                        </div>
                        <i class="pi pi-chevron-right text-xs text-slate-300 group-hover:text-slate-500 transition-colors"></i>
                    </button>

                    <!-- Step 2: AI -->
                    <button
                        class="w-full flex items-center gap-3 px-4 py-3 hover:bg-slate-50 transition-colors text-left group"
                        @click="emit('navigate-tab', '2')"
                    >
                        <div class="w-7 h-7 rounded-full flex items-center justify-center shrink-0 transition-all"
                             :class="cardProp.conversation_ai_enabled ? 'bg-emerald-100' : 'bg-slate-100'">
                            <i class="text-xs" :class="cardProp.conversation_ai_enabled ? 'pi pi-check text-emerald-600' : 'pi pi-sparkles text-slate-400'"></i>
                        </div>
                        <div class="flex-1 min-w-0">
                            <p class="text-sm font-medium text-slate-700 m-0">{{ $t('dashboard.ai_translations') }}</p>
                            <p class="text-xs m-0" :class="cardProp.conversation_ai_enabled ? 'text-emerald-600' : 'text-slate-400'">
                                {{ cardProp.conversation_ai_enabled ? $t('dashboard.ai_enabled') : $t('dashboard.ai_disabled') }}
                                <template v-if="translatedCount > 0"> · {{ translatedCount }} {{ $t('dashboard.translations').toLowerCase() }}</template>
                            </p>
                        </div>
                        <i class="pi pi-chevron-right text-xs text-slate-300 group-hover:text-slate-500 transition-colors"></i>
                    </button>

                    <!-- Step 3: QR Codes -->
                    <button
                        class="w-full flex items-center gap-3 px-4 py-3 hover:bg-slate-50 transition-colors text-left group"
                        @click="emit('navigate-tab', '3')"
                    >
                        <div class="w-7 h-7 rounded-full flex items-center justify-center shrink-0 transition-all"
                             :class="(cardProp.active_qr_codes || 0) > 0 ? 'bg-emerald-100' : 'bg-slate-100'">
                            <i class="text-xs" :class="(cardProp.active_qr_codes || 0) > 0 ? 'pi pi-check text-emerald-600' : 'pi pi-qrcode text-slate-400'"></i>
                        </div>
                        <div class="flex-1 min-w-0">
                            <p class="text-sm font-medium text-slate-700 m-0">{{ $t('dashboard.qr_access') }}</p>
                            <p class="text-xs text-slate-400 m-0">
                                {{ cardProp.active_qr_codes || 0 }} {{ $t('dashboard.active_qr_codes').toLowerCase() }}
                                <template v-if="(cardProp.total_qr_codes || 0) > 1"> · {{ cardProp.total_qr_codes }} total</template>
                            </p>
                        </div>
                        <i class="pi pi-chevron-right text-xs text-slate-300 group-hover:text-slate-500 transition-colors"></i>
                    </button>

                </div>
            </div>
        </template>

        <!-- Project Settings Summary -->
        <template v-if="cardProp">
            <div class="bg-white border border-slate-200 rounded-xl overflow-hidden">
                <div class="px-4 py-3 border-b border-slate-100 flex items-center justify-between gap-2">
                    <div class="flex items-center gap-2">
                        <i class="pi pi-sliders-h text-sm text-slate-400"></i>
                        <h3 class="text-sm font-semibold text-slate-700 m-0">{{ $t('dashboard.project_details') }}</h3>
                    </div>
                    <button
                        type="button"
                        @click="editSection = 'details'; showEditDialog = true"
                        class="flex items-center justify-center w-7 h-7 rounded-md text-slate-400 hover:text-slate-700 hover:bg-slate-100 transition-all"
                        v-tooltip.bottom="$t('dashboard.edit_project_details')"
                    >
                        <i class="pi pi-pencil text-xs"></i>
                    </button>
                </div>
                <div class="grid grid-cols-2 sm:grid-cols-3 gap-0 divide-y divide-slate-50">
                    <div class="px-4 py-3">
                        <p class="text-[11px] text-slate-400 uppercase tracking-wide m-0 mb-0.5">{{ $t('dashboard.content_mode') }}</p>
                        <p class="text-sm font-medium text-slate-700 m-0">{{ getContentModeLabel(cardProp.content_mode) }}</p>
                    </div>
                    <div class="px-4 py-3">
                        <p class="text-[11px] text-slate-400 uppercase tracking-wide m-0 mb-0.5">{{ $t('dashboard.language') }}</p>
                        <p class="text-sm font-medium text-slate-700 m-0">{{ getLanguageFlag(cardProp.original_language) }} {{ getLanguageName(cardProp.original_language) }}</p>
                    </div>
                    <div class="px-4 py-3">
                        <p class="text-[11px] text-slate-400 uppercase tracking-wide m-0 mb-0.5">{{ $t('dashboard.grouping_title') }}</p>
                        <p class="text-sm font-medium text-slate-700 m-0">{{ cardProp.is_grouped ? $t('dashboard.grouped') : $t('dashboard.ungrouped') }}</p>
                    </div>
                    <div class="px-4 py-3">
                        <p class="text-[11px] text-slate-400 uppercase tracking-wide m-0 mb-0.5">{{ $t('dashboard.ai_enabled') }}</p>
                        <p class="text-sm font-medium m-0" :class="cardProp.conversation_ai_enabled ? 'text-blue-600' : 'text-slate-400'">
                            <i class="pi text-xs mr-1" :class="cardProp.conversation_ai_enabled ? 'pi-check-circle' : 'pi-times-circle'"></i>
                            {{ cardProp.conversation_ai_enabled ? $t('common.yes') : $t('common.no') }}
                        </p>
                    </div>
                    <div class="px-4 py-3">
                        <p class="text-[11px] text-slate-400 uppercase tracking-wide m-0 mb-0.5">{{ $t('dashboard.voice') }}</p>
                        <p class="text-sm font-medium m-0" :class="cardProp.realtime_voice_enabled ? 'text-blue-600' : 'text-slate-400'">
                            <i class="pi text-xs mr-1" :class="cardProp.realtime_voice_enabled ? 'pi-check-circle' : 'pi-times-circle'"></i>
                            {{ cardProp.realtime_voice_enabled ? $t('common.yes') : $t('common.no') }}
                        </p>
                    </div>
                    <div class="px-4 py-3">
                        <p class="text-[11px] text-slate-400 uppercase tracking-wide m-0 mb-0.5">{{ $t('dashboard.created') }}</p>
                        <p class="text-sm font-medium text-slate-700 m-0">{{ formatDate(cardProp.created_at) }}</p>
                    </div>
                </div>
                <!-- Theme row — full width, tappable, navigates to Theme tab -->
                <button
                    type="button"
                    class="w-full flex items-center gap-3 px-4 py-3 border-t border-slate-50 hover:bg-slate-50 transition-colors text-left group"
                    @click="emit('navigate-tab', '4')"
                >
                    <i class="pi pi-palette text-xs text-slate-400 shrink-0"></i>
                    <div class="flex-1 min-w-0">
                        <p class="text-[11px] text-slate-400 uppercase tracking-wide m-0 mb-0.5">{{ $t('dashboard.theme_appearance') }}</p>
                        <div class="flex items-center gap-1.5">
                            <template v-if="cardProp.metadata?.theme && Object.keys(cardProp.metadata.theme).length > 0">
                                <span v-for="(color, key) in cardProp.metadata.theme" :key="key"
                                      class="inline-block w-3 h-3 rounded-full border border-slate-200 shrink-0"
                                      :style="{ backgroundColor: color }">
                                </span>
                                <span class="text-xs text-slate-600 font-medium">{{ $t('dashboard.customize_theme') }}</span>
                            </template>
                            <template v-else>
                                <span class="text-xs text-slate-400">{{ $t('dashboard.theme_default') }}</span>
                            </template>
                        </div>
                    </div>
                    <i class="pi pi-chevron-right text-xs text-slate-300 group-hover:text-slate-500 transition-colors shrink-0"></i>
                </button>
            </div>
        </template>

        </div><!-- end Left Column -->

        <!-- Right Column: Compact Mobile Preview (xl: only) -->
        <div v-if="cardProp" class="hidden xl:block">
            <div class="sticky top-4">
                <MobilePreview compact :cardProp="cardProp" />
            </div>
        </div>

        <!-- Edit Dialog (dynamic based on editSection) -->
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
import Dialog from 'primevue/dialog';
import MyDialog from '@/components/MyDialog.vue';
import CardExport from '@/components/Card/Export/CardExport.vue';
import DuplicateCardDialog from '@/components/Card/DuplicateCardDialog.vue';
import CardCreateEditForm from './CardCreateEditForm.vue';
import MobilePreview from './MobilePreview.vue';
import { useTranslationStore } from '@/stores/translation';
import { getLanguageFlag, getLanguageName, formatDate, formatNumber } from '@/utils/formatters';

const { t } = useI18n();

const translationStore = useTranslationStore();

const props = defineProps({
    cardProp: {
        type: Object,
        default: null
    },
    updateCardFn: {
        type: Function,
        default: null
    },
    contentCount: {
        type: Number,
        default: 0
    },
});

const emit = defineEmits(['edit', 'delete-requested', 'update-card', 'show-preview', 'navigate-tab']);

const showEditDialog = ref(false);
const showExportDialog = ref(false);
const showDuplicateDialog = ref(false);
const editFormRef = ref(null);

// Dynamic edit section for contextual dialogs
const editSection = ref(null); // 'details' only now (theme moved to own tab)

const editFormSections = computed(() => {
    return ['details'];
});

const editDialogHeader = computed(() => {
    return t('dashboard.project_details');
});

const editDialogStyle = computed(() => 'width: 90vw; max-width: 52rem;');

// Translation count for metadata footer (read from store)
const translatedCount = computed(() => {
    return translationStore.upToDateLanguages.length + translationStore.outdatedLanguages.length;
});

// Card name/description (no translation preview in General tab — moved to AI & Translations tab)
const displayedCardName = computed(() => props.cardProp?.name || t('dashboard.untitled_card'));
const displayedCardDescription = computed(() => props.cardProp?.description || '');

// Setup checklist computed helpers
const totalSteps = 3;
const completedSteps = computed(() => {
    let count = 0;
    if (props.contentCount > 0) count++;
    if (props.cardProp?.conversation_ai_enabled) count++;
    if ((props.cardProp?.active_qr_codes || 0) > 0) count++;
    return count;
});


const handleSaveEdit = async () => {
    if (editFormRef.value) {
        const payload = editFormRef.value.getPayload();

        if (props.updateCardFn) {
            // Use the passed update function for proper async handling
            await props.updateCardFn(payload);
        } else {
            // Fallback to emit (but this won't work properly with MyDialog)
            await emit('update-card', payload);
        }

        // Don't manually close dialog - MyDialog will close it automatically after success
    }
};

const handleCancelEdit = () => {
    showEditDialog.value = false;
    // Reset form to original values when canceling
    if (editFormRef.value) {
        editFormRef.value.initializeForm();
    }
};

const handleDialogHide = () => {
    // Reset form and edit section when dialog is hidden
    if (editFormRef.value) {
        editFormRef.value.initializeForm();
    }
    editSection.value = null;
};

const handleRequestDelete = () => {
    if (props.cardProp && props.cardProp.id) {
        emit('delete-requested', props.cardProp.id);
    }
};

// Handle successful card duplication
const handleDuplicated = (newCardId) => {
    showDuplicateDialog.value = false;
    // The card store already refreshed, and the parent (MyCards) will react
    // to the updated cards list. We emit navigate-tab to stay on general tab.
};


const truncateText = (text, maxLength) => {
    if (!text) return '';
    const plainText = text.replace(/[#*_`~\[\]()]/g, '').replace(/\n/g, ' ');
    if (plainText.length <= maxLength) return plainText;
    return plainText.substring(0, maxLength) + '...';
};

// Content mode helper functions
const getContentModeLabel = (mode) => {
    const modeLabels = {
        'single': t('dashboard.mode_single'),
        'list': t('dashboard.mode_list'),
        'grid': t('dashboard.mode_grid'),
        'cards': t('dashboard.mode_cards')
    };
    return modeLabels[mode] || t('dashboard.mode_list');
};

// Fetch translation status so metadata footer count stays current
onMounted(async () => {
    if (props.cardProp?.id) {
        await translationStore.fetchTranslationStatus(props.cardProp.id);
    }
});

watch(() => props.cardProp?.id, async (newId) => {
    if (newId) {
        await translationStore.fetchTranslationStatus(newId);
    }
});

</script>

