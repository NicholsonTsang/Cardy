<template>
    <div class="card-view-container">
        <!-- Hero Header with Card Identity -->
        <div v-if="cardProp" class="card-hero" :class="cardProp.billing_type === 'digital' ? 'hero-digital' : 'hero-physical'">
            <div class="hero-content">
                <div class="hero-left">
                    <!-- Access Mode Icon -->
                    <div class="hero-icon" :class="cardProp.billing_type === 'digital' ? 'icon-digital' : 'icon-physical'">
                        <i :class="cardProp.billing_type === 'digital' ? 'pi pi-qrcode' : 'pi pi-credit-card'"></i>
                    </div>
                    <div class="hero-info">
                        <div class="hero-badges">
                            <span class="badge" :class="cardProp.billing_type === 'digital' ? 'badge-digital' : 'badge-physical'">
                                {{ cardProp.billing_type === 'digital' ? $t('dashboard.digital_access') : $t('dashboard.physical_card') }}
                            </span>
                            <span class="badge badge-mode">
                                {{ getContentModeLabel(cardProp.content_mode) }}
                            </span>
                            <span v-if="cardProp.is_grouped" class="badge badge-grouped">
                                {{ $t('dashboard.badge_grouped') }}
                            </span>
                            <span v-else class="badge badge-flat">
                                {{ $t('dashboard.badge_flat') }}
                            </span>
                        </div>
                        <h1 class="hero-title">{{ displayedCardName }}</h1>
                        <p v-if="displayedCardDescription" class="hero-description">
                            {{ truncateText(displayedCardDescription, 120) }}
                        </p>
                    </div>
                </div>
                <div class="hero-actions">
                    <Button 
                        :label="$t('dashboard.edit_card')" 
                        icon="pi pi-pencil" 
                        @click="handleEdit" 
                        class="btn-edit"
                    />
                    <Button 
                        icon="pi pi-trash" 
                        @click="handleRequestDelete" 
                        severity="danger" 
                        outlined
                        class="btn-delete"
                        v-tooltip.bottom="$t('common.delete')"
                    />
                </div>
            </div>
        </div>

        <!-- Main Content Grid -->
        <div v-if="cardProp" class="content-grid">
            <!-- Left Column: Card Preview & Quick Stats -->
            <div class="left-column">
                <!-- Card Preview -->
                <div v-if="cardProp.billing_type !== 'digital'" class="card-preview-section">
                    <div class="section-header">
                        <i class="pi pi-image"></i>
                        <span>{{ $t('dashboard.card_artwork') }}</span>
                    </div>
                    <div class="card-preview-wrapper">
                        <div class="card-artwork-container">
                            <img
                                v-if="displayImageForView"
                                :src="displayImageForView"
                                alt="Card Artwork"
                                class="card-image"
                            />
                            <div v-else class="card-placeholder">
                                <i class="pi pi-image"></i>
                                <span>{{ $t('dashboard.no_artwork_uploaded') }}</span>
                            </div>
                            <!-- QR Code Overlay -->
                            <div 
                                v-if="cardProp.qr_code_position"
                                class="qr-overlay"
                                :class="getQrCodePositionClass(cardProp.qr_code_position)"
                            >
                                <i class="pi pi-qrcode"></i>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Quick Stats -->
                <div class="quick-stats-section">
                    <div class="section-header">
                        <i class="pi pi-chart-line"></i>
                        <span>{{ $t('dashboard.quick_stats') }}</span>
                    </div>
                    <div class="stats-grid">
                        <!-- Scan Stats for Digital -->
                        <div v-if="cardProp.billing_type === 'digital'" class="stat-card stat-scans">
                            <div class="stat-icon">
                                <i class="pi pi-eye"></i>
                            </div>
                            <div class="stat-info">
                                <span class="stat-value">{{ cardProp.current_scans || 0 }}</span>
                                <span class="stat-label">{{ $t('dashboard.total_scans') }}</span>
                            </div>
                            <div class="stat-limit">
                                / {{ cardProp.max_scans || '∞' }}
                            </div>
                        </div>

                        <!-- AI Status -->
                        <div class="stat-card" :class="cardProp.conversation_ai_enabled ? 'stat-ai-on' : 'stat-ai-off'">
                            <div class="stat-icon">
                                <i class="pi pi-comments"></i>
                            </div>
                            <div class="stat-info">
                                <span class="stat-value">{{ cardProp.conversation_ai_enabled ? $t('common.enabled') : $t('common.disabled') }}</span>
                                <span class="stat-label">{{ $t('dashboard.ai_assistant') }}</span>
                            </div>
                        </div>

                        <!-- Translations -->
                        <div class="stat-card stat-translations">
                            <div class="stat-icon">
                                <i class="pi pi-globe"></i>
                            </div>
                            <div class="stat-info">
                                <span class="stat-value">{{ availableTranslations.length }}</span>
                                <span class="stat-label">{{ $t('dashboard.translations') }}</span>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Metadata -->
                <div class="metadata-section">
                    <div class="section-header">
                        <i class="pi pi-clock"></i>
                        <span>{{ $t('dashboard.timeline') }}</span>
                    </div>
                    <div class="timeline">
                        <div class="timeline-item">
                            <div class="timeline-dot"></div>
                            <div class="timeline-content">
                                <span class="timeline-label">{{ $t('dashboard.created') }}</span>
                                <span class="timeline-value">{{ formatDate(cardProp.created_at) }}</span>
                            </div>
                        </div>
                        <div class="timeline-item">
                            <div class="timeline-dot dot-active"></div>
                            <div class="timeline-content">
                                <span class="timeline-label">{{ $t('dashboard.last_updated') }}</span>
                                <span class="timeline-value">{{ formatDate(cardProp.updated_at) }}</span>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Right Column: Details -->
            <div class="right-column">
                <!-- Content Details with Language Preview -->
                <div class="details-section">
                    <div class="section-header">
                        <div class="header-left">
                            <i class="pi pi-file-edit"></i>
                            <span>{{ $t('dashboard.content_details') }}</span>
                        </div>
                        <!-- Language Preview Selector -->
                        <Dropdown
                            v-if="availableTranslations.length > 0"
                            v-model="selectedPreviewLanguage"
                            :options="languageOptions"
                            optionLabel="label"
                            optionValue="value"
                            :placeholder="$t('translation.previewLanguage')"
                            class="language-selector"
                            size="small"
                        >
                            <template #value="slotProps">
                                <div v-if="slotProps.value" class="flex items-center gap-2">
                                    <span>{{ getLanguageFlag(slotProps.value) }}</span>
                                    <span>{{ getLanguageName(slotProps.value) }}</span>
                                </div>
                                <div v-else class="flex items-center gap-2">
                                    <span>{{ getLanguageFlag(cardProp?.original_language || 'en') }}</span>
                                    <span>{{ $t('translation.original') }}</span>
                                </div>
                            </template>
                            <template #option="slotProps">
                                <div class="flex items-center gap-2">
                                    <span>{{ getLanguageFlag(slotProps.option.value) }}</span>
                                    <span>{{ slotProps.option.label }}</span>
                                </div>
                            </template>
                        </Dropdown>
                    </div>
                    
                    <div class="details-content">
                        <div class="detail-item">
                            <label>{{ $t('dashboard.card_name') }}</label>
                            <p class="detail-value detail-name">{{ displayedCardName }}</p>
                        </div>
                        <div v-if="displayedCardDescription" class="detail-item">
                            <label>{{ $t('common.description') }}</label>
                            <div 
                                class="detail-value prose-content"
                                v-html="renderMarkdown(displayedCardDescription)"
                            ></div>
                        </div>
                    </div>
                </div>

                <!-- Configuration -->
                <div class="config-section">
                    <div class="section-header">
                        <i class="pi pi-sliders-h"></i>
                        <span>{{ $t('dashboard.configuration') }}</span>
                    </div>
                    <div class="config-grid">
                        <div class="config-item">
                            <i :class="cardProp.billing_type === 'digital' ? 'pi pi-qrcode' : 'pi pi-credit-card'"></i>
                            <div class="config-info">
                                <span class="config-label">{{ $t('dashboard.access_mode') }}</span>
                                <span class="config-value">{{ cardProp.billing_type === 'digital' ? $t('dashboard.digital_access') : $t('dashboard.physical_card') }}</span>
                            </div>
                        </div>
                        <div class="config-item">
                            <i :class="getContentModeIcon(cardProp.content_mode)"></i>
                            <div class="config-info">
                                <span class="config-label">{{ $t('dashboard.content_mode') }}</span>
                                <span class="config-value">{{ getContentModeLabel(cardProp.content_mode) }}</span>
                            </div>
                        </div>
                        <div class="config-item">
                            <i :class="cardProp.is_grouped ? 'pi pi-folder' : 'pi pi-list'"></i>
                            <div class="config-info">
                                <span class="config-label">{{ $t('dashboard.grouping') }}</span>
                                <span class="config-value">{{ cardProp.is_grouped ? $t('dashboard.badge_grouped') : $t('dashboard.badge_flat') }}</span>
                            </div>
                        </div>
                        <div v-if="cardProp.billing_type !== 'digital'" class="config-item">
                            <i class="pi pi-qrcode"></i>
                            <div class="config-info">
                                <span class="config-label">{{ $t('dashboard.qr_code_position') }}</span>
                                <span class="config-value">{{ displayQrCodePositionForView || $t('dashboard.not_set') }}</span>
                            </div>
                        </div>
                        <div class="config-item">
                            <i class="pi pi-globe"></i>
                            <div class="config-info">
                                <span class="config-label">{{ $t('dashboard.original_language') }}</span>
                                <span class="config-value">{{ getLanguageFlag(cardProp.original_language) }} {{ getLanguageName(cardProp.original_language) }}</span>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- AI Configuration -->
                <div v-if="cardProp.conversation_ai_enabled" class="ai-section">
                    <div class="section-header">
                        <i class="pi pi-sparkles"></i>
                        <span>{{ $t('dashboard.ai_assistance_configuration') }}</span>
                        <span class="ai-badge">{{ $t('common.enabled') }}</span>
                    </div>
                    <div class="ai-content">
                        <div v-if="cardProp.ai_instruction" class="ai-item">
                            <label>
                                <i class="pi pi-user"></i>
                                {{ $t('dashboard.ai_instruction_role') }}
                            </label>
                            <p>{{ cardProp.ai_instruction }}</p>
                        </div>
                        <div v-if="cardProp.ai_knowledge_base" class="ai-item">
                            <label>
                                <i class="pi pi-book"></i>
                                {{ $t('dashboard.ai_knowledge_base') }}
                            </label>
                            <p>{{ cardProp.ai_knowledge_base }}</p>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- Translation Section -->
        <div v-if="cardProp" class="translation-section">
            <CardTranslationSection ref="translationSectionRef" :card-id="cardProp.id" />
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
import { renderMarkdown } from '@/utils/markdownRenderer';
import { SUPPORTED_LANGUAGES, useTranslationStore } from '@/stores/translation';

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
    }
});

const emit = defineEmits(['edit', 'delete-requested', 'update-card']);

const showEditDialog = ref(false);
const editFormRef = ref(null);
const translationSectionRef = ref(null);
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

const truncateText = (text, maxLength) => {
    if (!text) return '';
    // Strip markdown for preview
    const plainText = text.replace(/[#*_`~\[\]()]/g, '').replace(/\n/g, ' ');
    if (plainText.length <= maxLength) return plainText;
    return plainText.substring(0, maxLength) + '...';
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
        
        // Refresh translation section to show updated original_language and status
        if (translationSectionRef.value) {
            translationSectionRef.value.loadTranslationStatus();
        }
        
        // Refetch translation status (card content changed)
        await translationStore.fetchTranslationStatus(props.cardProp.id);
        
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

const getContentModeIcon = (mode) => {
    const modeIcons = {
        'single': 'pi pi-file',
        'list': 'pi pi-list',
        'grid': 'pi pi-th-large',
        'cards': 'pi pi-id-card'
    };
    return modeIcons[mode] || 'pi pi-list';
};

// Set up CSS custom property for aspect ratio
onMounted(() => {
    const aspectRatio = getCardAspectRatio();
    document.documentElement.style.setProperty('--card-aspect-ratio', aspectRatio);
});
</script>

<style scoped>
/* ===== Main Container ===== */
.card-view-container {
    display: flex;
    flex-direction: column;
    gap: 1.5rem;
}

/* ===== Hero Header ===== */
.card-hero {
    border-radius: 1rem;
    padding: 1.25rem;
    background: linear-gradient(135deg, #f8fafc 0%, #f1f5f9 100%);
    border: 1px solid #e2e8f0;
}

.card-hero.hero-physical {
    background: linear-gradient(135deg, #faf5ff 0%, #f3e8ff 100%);
    border-color: #e9d5ff;
}

.card-hero.hero-digital {
    background: linear-gradient(135deg, #ecfeff 0%, #cffafe 100%);
    border-color: #a5f3fc;
}

.hero-content {
    display: flex;
    align-items: flex-start;
    justify-content: space-between;
    gap: 1rem;
    flex-wrap: wrap;
}

.hero-left {
    display: flex;
    align-items: flex-start;
    gap: 1rem;
    flex: 1;
    min-width: 0;
}

.hero-icon {
    width: 3.5rem;
    height: 3.5rem;
    border-radius: 0.875rem;
    display: flex;
    align-items: center;
    justify-content: center;
    flex-shrink: 0;
}

.hero-icon.icon-physical {
    background: linear-gradient(135deg, #a855f7 0%, #7c3aed 100%);
    box-shadow: 0 4px 12px rgba(168, 85, 247, 0.3);
}

.hero-icon.icon-digital {
    background: linear-gradient(135deg, #06b6d4 0%, #0891b2 100%);
    box-shadow: 0 4px 12px rgba(6, 182, 212, 0.3);
}

.hero-icon i {
    font-size: 1.5rem;
    color: white;
}

.hero-info {
    flex: 1;
    min-width: 0;
}

.hero-badges {
    display: flex;
    flex-wrap: wrap;
    gap: 0.5rem;
    margin-bottom: 0.5rem;
}

.badge {
    display: inline-flex;
    align-items: center;
    padding: 0.25rem 0.625rem;
    border-radius: 9999px;
    font-size: 0.75rem;
    font-weight: 500;
}

.badge-physical {
    background: #f3e8ff;
    color: #7c3aed;
}

.badge-digital {
    background: #cffafe;
    color: #0891b2;
}

.badge-mode {
    background: #dbeafe;
    color: #2563eb;
}

.badge-grouped {
    background: #f3e8ff;
    color: #7c3aed;
}

.badge-flat {
    background: #f1f5f9;
    color: #64748b;
}

.hero-title {
    font-size: 1.375rem;
    font-weight: 700;
    color: #0f172a;
    margin: 0 0 0.25rem 0;
    line-height: 1.3;
}

.hero-description {
    font-size: 0.875rem;
    color: #64748b;
    margin: 0;
    line-height: 1.5;
}

.hero-actions {
    display: flex;
    gap: 0.5rem;
    flex-shrink: 0;
}

.btn-edit {
    background: linear-gradient(135deg, #3b82f6 0%, #2563eb 100%) !important;
    border: none !important;
    box-shadow: 0 2px 8px rgba(59, 130, 246, 0.3);
    transition: all 0.2s ease;
}

.btn-edit:hover {
    transform: translateY(-1px);
    box-shadow: 0 4px 12px rgba(59, 130, 246, 0.4);
}

.btn-delete {
    width: 2.5rem !important;
    padding: 0 !important;
}

/* ===== Content Grid ===== */
.content-grid {
    display: grid;
    grid-template-columns: 1fr;
    gap: 1.5rem;
}

@media (min-width: 1024px) {
    .content-grid {
        grid-template-columns: 320px 1fr;
    }
}

/* ===== Left Column ===== */
.left-column {
    display: flex;
    flex-direction: column;
    gap: 1rem;
}

/* ===== Section Headers ===== */
.section-header {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    padding-bottom: 0.75rem;
    border-bottom: 1px solid #e2e8f0;
    margin-bottom: 1rem;
    font-weight: 600;
    font-size: 0.875rem;
    color: #334155;
}

.section-header i {
    color: #3b82f6;
    font-size: 1rem;
}

.section-header .header-left {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    flex: 1;
}

/* ===== Card Preview Section ===== */
.card-preview-section {
    background: white;
    border-radius: 1rem;
    padding: 1rem;
    border: 1px solid #e2e8f0;
    box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05);
}

.card-preview-wrapper {
    display: flex;
    justify-content: center;
}

.card-artwork-container {
    position: relative;
    aspect-ratio: var(--card-aspect-ratio, 2/3);
    width: 100%;
    max-width: 200px;
    border-radius: 0.75rem;
    overflow: hidden;
    box-shadow: 0 4px 16px rgba(0, 0, 0, 0.1);
}

.card-image {
    width: 100%;
    height: 100%;
    object-fit: cover;
    transition: transform 0.3s ease;
}

.card-artwork-container:hover .card-image {
    transform: scale(1.03);
}

.card-placeholder {
    width: 100%;
    height: 100%;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    background: linear-gradient(135deg, #f1f5f9 0%, #e2e8f0 100%);
    color: #94a3b8;
    gap: 0.5rem;
}

.card-placeholder i {
    font-size: 2rem;
}

.card-placeholder span {
    font-size: 0.75rem;
}

.qr-overlay {
    position: absolute;
    width: 2.5rem;
    height: 2.5rem;
    background: white;
    border-radius: 0.5rem;
    display: flex;
    align-items: center;
    justify-content: center;
    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.15);
}

.qr-overlay i {
    font-size: 1.25rem;
    color: #1e293b;
}

.qr-overlay.top-2.left-2 { top: 0.5rem; left: 0.5rem; }
.qr-overlay.top-2.right-2 { top: 0.5rem; right: 0.5rem; }
.qr-overlay.bottom-2.left-2 { bottom: 0.5rem; left: 0.5rem; }
.qr-overlay.bottom-2.right-2 { bottom: 0.5rem; right: 0.5rem; }

/* ===== Quick Stats Section ===== */
.quick-stats-section {
    background: white;
    border-radius: 1rem;
    padding: 1rem;
    border: 1px solid #e2e8f0;
    box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05);
}

.stats-grid {
    display: flex;
    flex-direction: column;
    gap: 0.75rem;
}

.stat-card {
    display: flex;
    align-items: center;
    gap: 0.75rem;
    padding: 0.75rem;
    border-radius: 0.75rem;
    background: #f8fafc;
    border: 1px solid #e2e8f0;
}

.stat-card.stat-scans {
    background: linear-gradient(135deg, #ecfeff 0%, #cffafe 100%);
    border-color: #a5f3fc;
}

.stat-card.stat-ai-on {
    background: linear-gradient(135deg, #f0fdf4 0%, #dcfce7 100%);
    border-color: #bbf7d0;
}

.stat-card.stat-ai-off {
    background: #f8fafc;
}

.stat-card.stat-translations {
    background: linear-gradient(135deg, #fef3c7 0%, #fde68a 100%);
    border-color: #fcd34d;
}

.stat-icon {
    width: 2.25rem;
    height: 2.25rem;
    border-radius: 0.5rem;
    display: flex;
    align-items: center;
    justify-content: center;
    background: white;
    box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
}

.stat-icon i {
    font-size: 1rem;
    color: #3b82f6;
}

.stat-info {
    flex: 1;
    display: flex;
    flex-direction: column;
}

.stat-value {
    font-size: 1rem;
    font-weight: 700;
    color: #0f172a;
}

.stat-label {
    font-size: 0.75rem;
    color: #64748b;
}

.stat-limit {
    font-size: 0.875rem;
    font-weight: 500;
    color: #94a3b8;
}

/* ===== Metadata Section ===== */
.metadata-section {
    background: white;
    border-radius: 1rem;
    padding: 1rem;
    border: 1px solid #e2e8f0;
    box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05);
}

.timeline {
    display: flex;
    flex-direction: column;
    gap: 1rem;
    padding-left: 0.5rem;
}

.timeline-item {
    display: flex;
    align-items: flex-start;
    gap: 0.75rem;
    position: relative;
}

.timeline-item:not(:last-child)::after {
    content: '';
    position: absolute;
    left: 4px;
    top: 1.25rem;
    width: 1px;
    height: calc(100% + 0.5rem);
    background: #e2e8f0;
}

.timeline-dot {
    width: 9px;
    height: 9px;
    border-radius: 50%;
    background: #cbd5e1;
    flex-shrink: 0;
    margin-top: 0.375rem;
}

.timeline-dot.dot-active {
    background: #3b82f6;
    box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.2);
}

.timeline-content {
    display: flex;
    flex-direction: column;
    gap: 0.125rem;
}

.timeline-label {
    font-size: 0.75rem;
    color: #64748b;
}

.timeline-value {
    font-size: 0.8125rem;
    color: #334155;
    font-weight: 500;
}

/* ===== Right Column ===== */
.right-column {
    display: flex;
    flex-direction: column;
    gap: 1rem;
}

/* ===== Details Section ===== */
.details-section {
    background: white;
    border-radius: 1rem;
    padding: 1.25rem;
    border: 1px solid #e2e8f0;
    box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05);
}

.language-selector {
    min-width: 140px;
}

.details-content {
    display: flex;
    flex-direction: column;
    gap: 1.25rem;
}

.detail-item {
    display: flex;
    flex-direction: column;
    gap: 0.375rem;
}

.detail-item label {
    font-size: 0.75rem;
    font-weight: 600;
    color: #64748b;
    text-transform: uppercase;
    letter-spacing: 0.025em;
}

.detail-value {
    font-size: 0.9375rem;
    color: #1e293b;
    line-height: 1.6;
}

.detail-name {
    font-size: 1.125rem;
    font-weight: 600;
}

/* ===== Config Section ===== */
.config-section {
    background: white;
    border-radius: 1rem;
    padding: 1.25rem;
    border: 1px solid #e2e8f0;
    box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05);
}

.config-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
    gap: 0.75rem;
}

.config-item {
    display: flex;
    align-items: center;
    gap: 0.75rem;
    padding: 0.875rem;
    border-radius: 0.75rem;
    background: #f8fafc;
    border: 1px solid #e2e8f0;
    transition: all 0.2s ease;
}

.config-item:hover {
    background: #f1f5f9;
    border-color: #cbd5e1;
}

.config-item > i {
    font-size: 1.125rem;
    color: #64748b;
    width: 1.5rem;
    text-align: center;
}

.config-info {
    display: flex;
    flex-direction: column;
    gap: 0.125rem;
}

.config-label {
    font-size: 0.6875rem;
    color: #94a3b8;
    text-transform: uppercase;
    letter-spacing: 0.05em;
}

.config-value {
    font-size: 0.875rem;
    color: #334155;
    font-weight: 500;
}

/* ===== AI Section ===== */
.ai-section {
    background: linear-gradient(135deg, #eff6ff 0%, #f5f3ff 100%);
    border-radius: 1rem;
    padding: 1.25rem;
    border: 1px solid #c7d2fe;
    box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05);
}

.ai-section .section-header {
    border-bottom-color: #c7d2fe;
}

.ai-section .section-header i {
    color: #7c3aed;
}

.ai-badge {
    margin-left: auto;
    padding: 0.25rem 0.5rem;
    border-radius: 9999px;
    background: #22c55e;
    color: white;
    font-size: 0.6875rem;
    font-weight: 600;
    text-transform: uppercase;
}

.ai-content {
    display: flex;
    flex-direction: column;
    gap: 1rem;
}

.ai-item {
    display: flex;
    flex-direction: column;
    gap: 0.5rem;
}

.ai-item label {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    font-size: 0.8125rem;
    font-weight: 600;
    color: #4c1d95;
}

.ai-item label i {
    font-size: 0.875rem;
}

.ai-item p {
    font-size: 0.875rem;
    color: #5b21b6;
    background: white;
    padding: 0.875rem;
    border-radius: 0.5rem;
    border: 1px solid #c7d2fe;
    line-height: 1.6;
    white-space: pre-wrap;
    margin: 0;
}

/* ===== Translation Section ===== */
.translation-section {
    margin-top: 0.5rem;
}

/* ===== Prose Content ===== */
.prose-content {
    color: #475569;
}

.prose-content :deep(h1),
.prose-content :deep(h2),
.prose-content :deep(h3),
.prose-content :deep(h4),
.prose-content :deep(h5),
.prose-content :deep(h6) {
    color: #1e293b;
    font-weight: 600;
    margin-top: 0.75em;
    margin-bottom: 0.5em;
}

.prose-content :deep(h1) { font-size: 1.25em; }
.prose-content :deep(h2) { font-size: 1.125em; }
.prose-content :deep(h3) { font-size: 1em; }

.prose-content :deep(p) {
    margin-top: 0.5em;
    margin-bottom: 0.5em;
}

.prose-content :deep(strong) {
    font-weight: 600;
    color: #1e293b;
}

.prose-content :deep(ul),
.prose-content :deep(ol) {
    margin: 0.5em 0;
    padding-left: 1.25em;
}

.prose-content :deep(ul) { list-style-type: disc; }
.prose-content :deep(ol) { list-style-type: decimal; }

.prose-content :deep(li) {
    margin: 0.25em 0;
}

.prose-content :deep(blockquote) {
    border-left: 3px solid #cbd5e1;
    padding-left: 1em;
    margin: 0.75em 0;
    font-style: italic;
    color: #64748b;
}

.prose-content :deep(code) {
    background: #f1f5f9;
    padding: 0.125em 0.25em;
    border-radius: 0.25rem;
    font-size: 0.875em;
    color: #dc2626;
}

.prose-content :deep(a) {
    color: #3b82f6;
    text-decoration: underline;
}

.prose-content :deep(a:hover) {
    color: #1d4ed8;
}

/* ===== Responsive ===== */
@media (max-width: 640px) {
    .card-hero {
        padding: 1rem;
    }
    
    .hero-icon {
        width: 2.75rem;
        height: 2.75rem;
    }
    
    .hero-icon i {
        font-size: 1.25rem;
    }
    
    .hero-title {
        font-size: 1.125rem;
    }
    
    .hero-actions {
        width: 100%;
        justify-content: flex-end;
    }
    
    .config-grid {
        grid-template-columns: 1fr;
    }
}
</style>