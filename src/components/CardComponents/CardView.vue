<template>
    <div class="xl:grid xl:grid-cols-[1fr_auto] gap-4">
        <!-- Left Column: Configuration -->
        <div class="flex flex-col gap-4 min-w-0">

        <!-- Project Overview Card -->
        <div v-if="cardProp" class="rounded-2xl bg-white border border-slate-200 shadow-sm overflow-hidden">
            <!-- Header: Icon + Title + Badge + Actions -->
            <div class="p-4">
                <div class="flex items-start gap-3">
                    <!-- Project Icon -->
                    <div class="w-10 h-10 rounded-xl flex items-center justify-center shrink-0 bg-gradient-to-br from-cyan-500 to-cyan-600">
                        <i class="pi pi-qrcode text-lg text-white"></i>
                    </div>

                    <!-- Title + Badge + Description -->
                    <div class="flex-1 min-w-0">
                        <div class="flex items-center gap-2 flex-wrap">
                            <h1 class="text-lg font-bold text-slate-900 m-0 truncate">{{ displayedCardName }}</h1>
                            <span class="inline-flex items-center px-2 py-0.5 rounded-full text-[11px] font-medium bg-slate-100 text-slate-500 shrink-0">
                                {{ getContentModeLabel(cardProp.content_mode) }}
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

            <!-- Metadata Footer -->
            <div class="px-4 py-2.5 border-t border-slate-100 bg-slate-50/50">
                <div class="flex items-center gap-x-4 gap-y-1 flex-wrap text-xs text-slate-500 ml-[3.25rem]">
                    <span>{{ getLanguageFlag(cardProp.original_language) }} {{ getLanguageName(cardProp.original_language) }}</span>
                    <span class="text-slate-300">|</span>
                    <span>{{ cardProp.total_sessions || 0 }} <span class="text-slate-400">/ {{ cardProp.max_sessions || '∞' }}</span> {{ $t('dashboard.total_sessions').toLowerCase() }}</span>
                    <span class="text-slate-300">|</span>
                    <span>{{ translatedCount }} {{ $t('dashboard.translations').toLowerCase() }}</span>
                    <span class="text-slate-300">|</span>
                    <span>{{ formatDate(cardProp.created_at) }}</span>
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

        <!-- Main Content (single-column flow) -->
        <template v-if="cardProp">

            <!-- Content Prompt (shown when no content items) -->
            <div
                v-if="contentCount === 0"
                class="flex items-center gap-3 px-4 py-3 bg-amber-50 border border-amber-200 rounded-xl cursor-pointer hover:bg-amber-100 transition-colors"
                @click="emit('navigate-tab', '1')"
            >
                <i class="pi pi-list text-amber-500"></i>
                <span class="text-sm text-amber-700 flex-1">{{ $t('dashboard.no_content_hint') }}</span>
                <i class="pi pi-arrow-right text-xs text-amber-400"></i>
            </div>

        </template>

        <!-- Theme & Appearance Section -->
        <template v-if="cardProp">
            <div class="bg-white border border-slate-200 rounded-xl overflow-hidden">
                <div class="flex items-center gap-3 px-4 py-3 border-b border-slate-100">
                    <div class="w-8 h-8 rounded-lg bg-gradient-to-br from-violet-100 to-indigo-100 flex items-center justify-center shrink-0">
                        <i class="pi pi-palette text-sm text-violet-600"></i>
                    </div>
                    <div class="flex-1 min-w-0">
                        <h3 class="text-sm font-semibold text-slate-800 m-0">{{ $t('dashboard.theme_appearance') }}</h3>
                        <p class="text-xs text-slate-400 m-0">{{ $t('dashboard.customize_theme') }}</p>
                    </div>
                    <button
                        type="button"
                        @click="editSection = 'theme'; showEditDialog = true"
                        class="flex items-center justify-center w-8 h-7 rounded-md text-slate-400 hover:text-slate-700 hover:bg-slate-100 transition-all"
                        v-tooltip.bottom="$t('dashboard.configure')"
                    >
                        <i class="pi pi-pencil text-xs"></i>
                    </button>
                </div>
                <!-- Theme preview strip -->
                <div class="px-4 py-3">
                    <div v-if="cardProp.metadata?.theme && Object.keys(cardProp.metadata.theme).length > 0"
                         class="flex items-center gap-3">
                        <div class="flex gap-1.5">
                            <div v-for="(color, key) in cardProp.metadata.theme" :key="key"
                                 class="w-7 h-7 rounded-full border border-slate-200 shadow-sm"
                                 :style="{ backgroundColor: color }"
                                 v-tooltip.bottom="key">
                            </div>
                        </div>
                        <span class="text-xs text-slate-500">{{ $t('dashboard.customize_theme') }}</span>
                    </div>
                    <div v-else class="flex items-center gap-2">
                        <i class="pi pi-info-circle text-xs text-slate-300"></i>
                        <span class="text-xs text-slate-400">{{ $t('dashboard.theme_default_hint') }}</span>
                    </div>
                </div>
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
import { getLanguageFlag, getLanguageName, formatDate } from '@/utils/formatters';

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
const editSection = ref(null); // 'details' | 'theme'

const editFormSections = computed(() => {
    if (editSection.value === 'details') return ['details'];
    if (editSection.value === 'theme') return ['theme'];
    return ['details', 'theme'];
});

const editDialogHeader = computed(() => {
    if (editSection.value === 'details') return t('dashboard.project_details');
    if (editSection.value === 'theme') return t('dashboard.theme_appearance');
    return t('dashboard.edit_card');
});

const editDialogStyle = computed(() => 'width: 90vw; max-width: 68rem;');

// Translation count for metadata footer (read from store)
const translatedCount = computed(() => {
    return translationStore.upToDateLanguages.length + translationStore.outdatedLanguages.length;
});

// Card name/description (no translation preview in General tab — moved to AI & Translations tab)
const displayedCardName = computed(() => props.cardProp?.name || t('dashboard.untitled_card'));
const displayedCardDescription = computed(() => props.cardProp?.description || '');


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

