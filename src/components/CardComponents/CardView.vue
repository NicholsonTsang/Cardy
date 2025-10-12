<template>
    <div class="space-y-6">
        <!-- Action Bar -->
        <div class="flex justify-between items-center" v-if="cardProp">
            <div class="flex items-center gap-3">
                <!-- Remove the publishing tag -->
            </div>
            <div class="flex gap-3">
                <Button 
                    :label="$t('dashboard.edit_card')" 
                    icon="pi pi-pencil" 
                    @click="handleEdit" 
                    severity="info" 
                    class="px-4 py-2 shadow-lg hover:shadow-xl transition-shadow"
                />
                <Button 
                    :label="$t('common.delete')" 
                    icon="pi pi-trash" 
                    @click="handleRequestDelete" 
                    severity="danger" 
                    outlined
                    class="px-4 py-2"
                />
            </div>
        </div>

        <!-- Card Content -->
        <div v-if="cardProp" class="space-y-6">
            <!-- Main Card Info - Two Column Layout -->
            <div class="bg-white rounded-xl shadow-lg border border-slate-200 overflow-hidden">
                <div class="p-6">
                    <div class="grid grid-cols-1 xl:grid-cols-3 gap-6">
                        <!-- Artwork Display -->
                        <div class="xl:col-span-1">
                            <div class="bg-slate-50 rounded-xl p-6">
                                <h3 class="text-lg font-semibold text-slate-900 mb-4 flex items-center gap-2">
                                    <i class="pi pi-image text-blue-600"></i>
                                    {{ $t('dashboard.card_artwork') }}
                                </h3>
                                <div class="card-artwork-container relative">
                                    <!-- Display the already-cropped image_url directly, no need to re-apply crop parameters -->
                                    <img
                                        v-if="displayImageForView"
                                        :src="displayImageForView"
                                        alt="Card Artwork"
                                        class="w-full h-full object-cover rounded-lg border border-slate-200 shadow-md"
                                    />
                                    <img
                                        v-else
                                        :src="cardPlaceholder"
                                        alt="Card Artwork Placeholder"
                                        class="w-full h-full object-cover rounded-lg border border-slate-200 shadow-md"
                                    />
                                    <div v-if="!displayImageForView" 
                                         class="absolute inset-0 flex items-center justify-center bg-slate-100 rounded-lg">
                                        <div class="text-center text-slate-400">
                                            <i class="pi pi-image text-3xl mb-3"></i>
                                            <p class="text-sm font-medium">{{ $t('dashboard.no_artwork_uploaded') }}</p>
                                        </div>
                                    </div>
                                    
                                    <!-- Mock QR Code Overlay -->
                                    <div 
                                        v-if="cardProp && cardProp.qr_code_position"
                                        class="absolute w-12 h-12 bg-white border-2 border-slate-300 rounded-lg shadow-lg flex items-center justify-center"
                                        :class="getQrCodePositionClass(cardProp.qr_code_position)"
                                    >
                                        <div class="w-8 h-8 bg-slate-800 rounded-sm flex items-center justify-center">
                                            <i class="pi pi-qrcode text-white text-xs"></i>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <!-- Details Display -->
                        <div class="xl:col-span-2 space-y-6">
                            <!-- Basic Info -->
                            <div class="bg-slate-50 rounded-xl p-6">
                                <div class="flex items-center justify-between mb-4">
                                    <h3 class="text-lg font-semibold text-slate-900 flex items-center gap-2">
                                        <i class="pi pi-info-circle text-blue-600"></i>
                                        {{ $t('dashboard.basic_information') }}
                                    </h3>
                                    <!-- Language Preview Selector -->
                                    <Dropdown
                                        v-if="availableTranslations.length > 0"
                                        v-model="selectedPreviewLanguage"
                                        :options="languageOptions"
                                        optionLabel="label"
                                        optionValue="value"
                                        :placeholder="$t('translation.previewLanguage')"
                                        class="w-48"
                                        size="small"
                                    >
                                        <template #value="slotProps">
                                            <div v-if="slotProps.value" class="flex items-center gap-2">
                                                <span>{{ getLanguageFlag(slotProps.value) }}</span>
                                                <span class="text-sm">{{ getLanguageName(slotProps.value) }}</span>
                                            </div>
                                            <span v-else class="text-sm">{{ slotProps.placeholder }}</span>
                                        </template>
                                        <template #option="slotProps">
                                            <div class="flex items-center gap-2">
                                                <span>{{ getLanguageFlag(slotProps.option.value) }}</span>
                                                <span>{{ slotProps.option.label }}</span>
                                            </div>
                                        </template>
                                    </Dropdown>
                                </div>
                                <div class="space-y-4">
                                    <div>
                                        <h4 class="text-sm font-medium text-slate-700 mb-2">{{ $t('dashboard.card_name') }}</h4>
                                        <p class="text-base text-slate-900 font-medium">{{ displayedCardName }}</p>
                                    </div>

                                    <div v-if="displayedCardDescription">
                                        <h4 class="text-sm font-medium text-slate-700 mb-2">{{ $t('common.description') }}</h4>
                                        <div 
                                            class="text-sm text-slate-600 leading-relaxed prose prose-sm max-w-none prose-slate"
                                            v-html="renderMarkdown(displayedCardDescription)"
                                        ></div>
                                    </div>
                                </div>
                            </div>

                            <!-- Technical Details -->
                            <div class="bg-slate-50 rounded-xl p-6">
                                <h3 class="text-lg font-semibold text-slate-900 mb-4 flex items-center gap-2">
                                    <i class="pi pi-cog text-blue-600"></i>
                                    {{ $t('dashboard.configuration') }}
                                </h3>
                                <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                                    <div class="bg-white rounded-lg p-4 border border-slate-200">
                                        <h4 class="text-sm font-medium text-slate-700 mb-2 flex items-center gap-2">
                                            <i class="pi pi-qrcode text-slate-500"></i>
                                            {{ $t('dashboard.qr_code_position') }}
                                        </h4>
                                        <p class="text-sm text-slate-600">{{ displayQrCodePositionForView || $t('dashboard.not_set') }}</p>
                                    </div>
                                </div>
                            </div>

                            <!-- AI Configuration -->
                            <div v-if="cardProp.conversation_ai_enabled" 
                                 class="bg-gradient-to-r from-blue-50 to-purple-50 rounded-xl p-6 border border-blue-200">
                                <h3 class="text-lg font-semibold text-blue-900 mb-4 flex items-center gap-2">
                                    <i class="pi pi-comments text-blue-600"></i>
                                    {{ $t('dashboard.ai_assistance_configuration') }}
                                </h3>
                                
                                <!-- AI Instruction -->
                                <div v-if="cardProp.ai_instruction" class="mb-4">
                                    <h4 class="text-sm font-medium text-blue-800 mb-2 flex items-center gap-2">
                                        <i class="pi pi-user text-blue-600"></i>
                                        {{ $t('dashboard.ai_instruction_role') }}
                                    </h4>
                                    <div class="bg-white rounded-lg p-4 border border-blue-200">
                                        <p class="text-sm text-blue-800 whitespace-pre-wrap leading-relaxed">{{ cardProp.ai_instruction }}</p>
                                    </div>
                                </div>

                                <!-- AI Knowledge Base -->
                                <div v-if="cardProp.ai_knowledge_base" class="mb-4">
                                    <h4 class="text-sm font-medium text-blue-800 mb-2 flex items-center gap-2">
                                        <i class="pi pi-book text-blue-600"></i>
                                        {{ $t('dashboard.ai_knowledge_base') }}
                                    </h4>
                                    <div class="bg-white rounded-lg p-4 border border-blue-200">
                                        <p class="text-sm text-blue-800 whitespace-pre-wrap leading-relaxed">{{ cardProp.ai_knowledge_base }}</p>
                                    </div>
                                </div>

                                <!-- Info Note -->
                                <div class="mt-3 p-3 bg-blue-100 rounded-lg">
                                    <p class="text-xs text-blue-800 flex items-center gap-2">
                                        <i class="pi pi-info-circle"></i>
                                        <span>{{ $t('dashboard.ai_enabled_note') }}</span>
                                    </p>
                                </div>
                            </div>

                            <!-- Metadata -->
                            <div class="bg-slate-50 rounded-xl p-6">
                                <h3 class="text-lg font-semibold text-slate-900 mb-4 flex items-center gap-2">
                                    <i class="pi pi-calendar text-blue-600"></i>
                                    {{ $t('dashboard.metadata') }}
                                </h3>
                                <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                                    <div v-if="cardProp.created_at" class="bg-white rounded-lg p-4 border border-slate-200">
                                        <h4 class="text-sm font-medium text-slate-700 mb-2">{{ $t('dashboard.created') }}</h4>
                                        <p class="text-sm text-slate-600">{{ formatDate(cardProp.created_at) }}</p>
                                    </div>

                                    <div v-if="cardProp.updated_at" class="bg-white rounded-lg p-4 border border-slate-200">
                                        <h4 class="text-sm font-medium text-slate-700 mb-2">{{ $t('dashboard.last_updated') }}</h4>
                                        <p class="text-sm text-slate-600">{{ formatDate(cardProp.updated_at) }}</p>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Multi-Language Translation Section - Full Width -->
            <CardTranslationSection :card-id="cardProp.id" />
        </div>

        <!-- Edit Dialog -->
        <MyDialog
            v-model="showEditDialog"
            :header="$t('dashboard.edit_card')"
            :confirmHandle="handleSaveEdit"
            :confirmLabel="$t('dashboard.save_changes')"
            confirmSeverity="primary"
            :cancelLabel="$t('common.cancel')"
            :successMessage="$t('dashboard.card_updated')"
            :errorMessage="$t('messages.operation_failed')"
            @cancel="handleCancelEdit"
            @hide="handleDialogHide"
            style="width: 90vw; max-width: 1200px;"
        >
            <CardCreateEditForm 
                ref="editFormRef"
                :cardProp="cardProp" 
                :isEditMode="true"
                :isInDialog="true"
            />
        </MyDialog>
    </div>
</template>

<script setup>
import { computed, ref, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import Button from 'primevue/button';
import Tag from 'primevue/tag';
import Dropdown from 'primevue/dropdown';
import MyDialog from '@/components/MyDialog.vue';
import CardCreateEditForm from './CardCreateEditForm.vue';
import CardTranslationSection from '@/components/Card/CardTranslationSection.vue';
import cardPlaceholder from '@/assets/images/card-placeholder.svg';
import { getCardAspectRatio } from '@/utils/cardConfig';
import { marked } from 'marked';
import { SUPPORTED_LANGUAGES } from '@/stores/translation';

const { t } = useI18n();

const props = defineProps({
    cardProp: {
        type: Object,
        default: null
    },
    updateCardFn: {
        type: Function,
        default: null
    }
});

const emit = defineEmits(['edit', 'delete-requested', 'update-card']);

const showEditDialog = ref(false);
const editFormRef = ref(null);
const isLoading = ref(false);

// Language preview state
const selectedPreviewLanguage = ref(null);

// Parse translations from card
const availableTranslations = computed(() => {
    if (!props.cardProp?.translations) return [];
    return Object.keys(props.cardProp.translations);
});

// Generate language options for dropdown
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

// Get displayed card name (original or translated)
const displayedCardName = computed(() => {
    if (!selectedPreviewLanguage.value || !props.cardProp?.translations?.[selectedPreviewLanguage.value]) {
        return props.cardProp?.name || t('dashboard.untitled_card');
    }
    return props.cardProp.translations[selectedPreviewLanguage.value]?.name || props.cardProp?.name;
});

// Get displayed card description (original or translated)
const displayedCardDescription = computed(() => {
    if (!selectedPreviewLanguage.value || !props.cardProp?.translations?.[selectedPreviewLanguage.value]) {
        return props.cardProp?.description || '';
    }
    return props.cardProp.translations[selectedPreviewLanguage.value]?.description || props.cardProp?.description || '';
});

// Helper functions for language display
const getLanguageName = (langCode) => {
    return SUPPORTED_LANGUAGES[langCode] || langCode;
};

const getLanguageFlag = (langCode) => {
    const flagMap = {
        en: '🇬🇧',
        'zh-Hant': '🇹🇼',
        'zh-Hans': '🇨🇳',
        ja: '🇯🇵',
        ko: '🇰🇷',
        es: '🇪🇸',
        fr: '🇫🇷',
        ru: '🇷🇺',
        ar: '🇸🇦',
        th: '🇹🇭',
    };
    return flagMap[langCode] || '🌐';
};

const displayImageForView = computed(() => {
    if (props.cardProp && props.cardProp.image_url) {
        return props.cardProp.image_url;
    }
    return null;
});

const displayQrCodePositionForView = computed(() => {
    if (!props.cardProp || !props.cardProp.qr_code_position) return null;
    
    const positions = {
        'TL': t('dashboard.top_left'),
        'TR': t('dashboard.top_right'),
        'BL': t('dashboard.bottom_left'),
        'BR': t('dashboard.bottom_right')
    };
    
    return positions[props.cardProp.qr_code_position] || props.cardProp.qr_code_position;
});

const handleEdit = () => {
    showEditDialog.value = true;
};

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
    // Reset form when dialog is hidden
    if (editFormRef.value) {
        editFormRef.value.initializeForm();
    }
};

const handleRequestDelete = () => {
    if (props.cardProp && props.cardProp.id) {
        emit('delete-requested', props.cardProp.id);
    }
};

const formatDate = (dateString) => {
    return new Date(dateString).toLocaleDateString('en-US', {
        year: 'numeric',
        month: 'long',
        day: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
    });
};

const getQrCodePositionClass = (position) => {
    const classes = {
        'TL': 'top-2 left-2',
        'TR': 'top-2 right-2',
        'BL': 'bottom-2 left-2',
        'BR': 'bottom-2 right-2'
    };
    return classes[position] || 'bottom-2 right-2'; // Default to bottom-right
};

// Render markdown to HTML
const renderMarkdown = (markdown) => {
    if (!markdown) return '';
    
    // Configure marked for security and styling
    marked.setOptions({
        breaks: true,
        gfm: true,
        sanitize: false // We trust our own content, but you might want to sanitize in production
    });
    
    return marked(markdown);
};

// Set up CSS custom property for aspect ratio
onMounted(() => {
    const aspectRatio = getCardAspectRatio();
    document.documentElement.style.setProperty('--card-aspect-ratio', aspectRatio);
});
</script>

<style scoped>
/* Responsive container with configurable aspect ratio */
.card-artwork-container {
    aspect-ratio: var(--card-aspect-ratio, 2/3);
    width: 100%;
    max-width: 240px; /* Constrain maximum width */
    margin: 0 auto;
}

/* Component-specific styles */
.card-artwork-container img {
    transition: all 0.2s ease-in-out;
}

.card-artwork-container:hover img {
    transform: scale(1.02);
}

/* Markdown prose styling */
.prose {
    color: #64748b;
    max-width: none;
}

.prose h1, .prose h2, .prose h3, .prose h4, .prose h5, .prose h6 {
    color: #334155;
    font-weight: 600;
    margin-top: 0.75em;
    margin-bottom: 0.5em;
}

.prose h1 { font-size: 1.25em; }
.prose h2 { font-size: 1.125em; }
.prose h3 { font-size: 1em; }
.prose h4, .prose h5, .prose h6 { font-size: 0.875em; }

.prose p {
    margin-top: 0.5em;
    margin-bottom: 0.5em;
}

.prose strong {
    font-weight: 600;
    color: #1e293b;
}

.prose em {
    font-style: italic;
}

.prose ul, .prose ol {
    margin-top: 0.5em;
    margin-bottom: 0.5em;
    padding-left: 1.25em;
}

.prose ul {
    list-style-type: disc;
}

.prose ol {
    list-style-type: decimal;
}

.prose li {
    margin-top: 0.25em;
    margin-bottom: 0.25em;
}

.prose blockquote {
    border-left: 3px solid #cbd5e1;
    padding-left: 1em;
    margin: 0.75em 0;
    font-style: italic;
    color: #64748b;
}

.prose code {
    background-color: #f1f5f9;
    padding: 0.125em 0.25em;
    border-radius: 0.25rem;
    font-size: 0.875em;
    color: #dc2626;
    font-family: ui-monospace, SFMono-Regular, Monaco, Consolas, "Liberation Mono", "Courier New", monospace;
}

.prose pre {
    background-color: #f8fafc;
    border: 1px solid #e2e8f0;
    border-radius: 0.5rem;
    padding: 1em;
    overflow-x: auto;
    margin: 0.75em 0;
}

.prose pre code {
    background-color: transparent;
    padding: 0;
    color: #334155;
}

.prose a {
    color: #3b82f6;
    text-decoration: underline;
}

.prose a:hover {
    color: #1d4ed8;
}
</style>