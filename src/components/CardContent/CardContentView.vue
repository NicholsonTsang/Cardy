<template>
    <div class="space-y-3 sm:space-y-4 lg:space-y-6">
        <!-- Header Badge -->
        <div class="flex justify-between items-center pb-3 sm:pb-4 border-b" :class="headerBorderClass">
            <div class="flex items-center gap-2 sm:gap-3">
                <span class="inline-flex items-center px-2.5 sm:px-3 py-1 rounded-full text-xs sm:text-sm font-medium" :class="badgeClass">
                    <i :class="['pi', badgeIcon, 'mr-1.5 text-xs']"></i>
                    {{ badgeLabel }}
                </span>
            </div>
            <!-- Language Preview Selector -->
            <Dropdown
                v-if="availableTranslations.length > 0"
                v-model="selectedPreviewLanguage"
                :options="languageOptions"
                optionLabel="label"
                optionValue="value"
                :placeholder="t('translation.previewLanguage')"
                class="w-full sm:w-48"
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
        
        <!-- ========== SINGLE MODE: Full Page Content ========== -->
        <div v-if="contentMode === 'single'" class="space-y-4">
            <!-- Full Content Preview -->
            <div class="bg-gradient-to-r from-purple-50 to-slate-50 rounded-xl p-4 sm:p-6 border border-purple-200">
                <h3 class="text-lg font-semibold text-slate-900 mb-3">{{ displayedItemName }}</h3>
                <div class="bg-white rounded-lg p-4 border border-purple-200 prose prose-sm max-w-none">
                    <div v-if="displayedItemContent" v-html="renderMarkdown(displayedItemContent)" class="text-sm text-slate-700"></div>
                    <p v-else class="text-sm text-slate-400 italic">{{ t('content.no_description_provided') }}</p>
                </div>
            </div>

            <!-- AI Context -->
            <div v-if="cardAiEnabled && contentItem?.ai_knowledge_base" class="bg-gradient-to-r from-blue-50 to-indigo-50 rounded-xl p-4 border border-blue-200">
                <h4 class="text-sm font-semibold text-blue-900 mb-2 flex items-center gap-2">
                    <i class="pi pi-sparkles text-blue-600"></i>
                    {{ t('content.ai_knowledge_base') }}
                </h4>
                <p class="text-sm text-blue-800 whitespace-pre-wrap">{{ contentItem.ai_knowledge_base }}</p>
            </div>
        </div>

        <!-- ========== GROUPED MODE: Category or Item Details ========== -->
        <!-- Triggered when is_grouped is true -->
        <div v-else-if="effectiveIsGrouped" class="flex flex-col gap-4">
            <!-- Category View -->
            <template v-if="!contentItem?.parent_id">
                <div class="bg-gradient-to-r from-orange-50 to-slate-50 rounded-xl p-4 sm:p-6 border border-orange-200">
                    <h3 class="text-lg font-semibold text-slate-900">{{ displayedItemName }}</h3>
                    <p class="text-sm text-slate-500 mt-1">{{ t('content.category_description') }}</p>
                </div>
            </template>

            <!-- Item View (sub-item in grouped mode) -->
            <template v-else>
                <!-- Item Image -->
                <div v-if="contentItem?.imageUrl || contentItem?.image_url" class="bg-amber-50 rounded-xl p-4 border border-amber-200">
                    <h4 class="text-sm font-semibold text-amber-900 mb-3 flex items-center gap-2">
                        <i class="pi pi-image text-amber-600"></i>
                        {{ t('content.content_image') }}
                    </h4>
                    <div class="content-image-container max-w-md mx-auto border border-amber-300 rounded-xl bg-white overflow-hidden">
                        <img :src="contentItem?.imageUrl || contentItem?.image_url" alt="Item Image" class="object-contain h-full w-full" />
                    </div>
                </div>

                <!-- Item Details -->
                <div class="bg-white rounded-xl shadow-lg border border-amber-200 p-4">
                    <div class="space-y-4">
                        <div>
                            <h4 class="text-xs font-medium text-slate-500 mb-1">{{ t('common.name') }}</h4>
                            <p class="text-lg font-semibold text-slate-900">{{ displayedItemName }}</p>
                        </div>
                        <div>
                            <h4 class="text-xs font-medium text-slate-500 mb-1">{{ t('content.description') }}</h4>
                            <div class="bg-slate-50 rounded-lg p-3 border border-slate-200 prose prose-sm max-w-none">
                                <div v-if="displayedItemContent" v-html="renderMarkdown(displayedItemContent)" class="text-sm text-slate-700"></div>
                                <p v-else class="text-sm text-slate-400 italic">{{ t('content.no_description_provided') }}</p>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- AI Context -->
                <div v-if="cardAiEnabled && contentItem?.ai_knowledge_base" class="bg-gradient-to-r from-blue-50 to-indigo-50 rounded-xl p-4 border border-blue-200">
                    <h4 class="text-sm font-semibold text-blue-900 mb-2 flex items-center gap-2">
                        <i class="pi pi-sparkles text-blue-600"></i>
                        {{ t('content.ai_knowledge_base') }}
                    </h4>
                    <p class="text-sm text-blue-800 whitespace-pre-wrap">{{ contentItem.ai_knowledge_base }}</p>
                </div>
            </template>
        </div>

        <!-- ========== LIST MODE: Link/List Item Details ========== -->
        <div v-else-if="contentMode === 'list'" class="space-y-4">
            <!-- Link Preview Card -->
            <div class="bg-gradient-to-r from-blue-50 to-slate-50 rounded-xl p-4 sm:p-6 border border-blue-200">
                <h3 class="text-lg font-semibold text-slate-900 flex items-center gap-2">
                    <i :class="['pi', getLinkIcon(displayedItemContent), 'text-blue-600']"></i>
                    {{ displayedItemName }}
                </h3>
                <a 
                    v-if="displayedItemContent" 
                    :href="displayedItemContent" 
                    target="_blank" 
                    rel="noopener noreferrer"
                    class="text-sm text-blue-600 hover:text-blue-800 flex items-center gap-1 mt-2 truncate"
                >
                    <i class="pi pi-external-link text-xs"></i>
                    {{ displayedItemContent }}
                </a>
                <p v-else class="text-sm text-slate-400 italic mt-2">{{ t('content.no_url') }}</p>
            </div>

            <!-- AI Context -->
            <div v-if="cardAiEnabled && contentItem?.ai_knowledge_base" class="bg-gradient-to-r from-blue-50 to-indigo-50 rounded-xl p-4 border border-blue-200">
                <h4 class="text-sm font-semibold text-blue-900 mb-2 flex items-center gap-2">
                    <i class="pi pi-sparkles text-blue-600"></i>
                    {{ t('content.ai_knowledge_base') }}
                </h4>
                <p class="text-sm text-blue-800">{{ contentItem.ai_knowledge_base }}</p>
            </div>
        </div>

        <!-- ========== GRID MODE: Gallery Item Details ========== -->
        <div v-else-if="contentMode === 'grid'" class="flex flex-col gap-4">
            <!-- Image -->
            <div class="bg-green-50 rounded-xl p-4 border border-green-200">
                <h4 class="text-sm font-semibold text-green-900 mb-3 flex items-center gap-2">
                    <i class="pi pi-image text-green-600"></i>
                    {{ t('content.content_image') }}
                </h4>
                <div class="content-image-container max-w-md mx-auto border border-green-300 rounded-xl bg-white overflow-hidden">
                    <img 
                        v-if="contentItem?.imageUrl || contentItem?.image_url"
                        :src="contentItem?.imageUrl || contentItem?.image_url"
                        alt="Item Image"
                        class="object-contain h-full w-full" 
                    />
                    <div v-else class="h-full flex items-center justify-center bg-green-50">
                        <div class="text-center">
                            <i class="pi pi-image text-4xl text-green-300"></i>
                            <p class="text-sm text-green-400 mt-2">{{ t('content.needs_photo') }}</p>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Details -->
            <div class="bg-white rounded-xl shadow-lg border border-green-200 p-4">
                <div class="space-y-4">
                    <div>
                        <h4 class="text-xs font-medium text-slate-500 mb-1">{{ t('common.name') }}</h4>
                        <p class="text-lg font-semibold text-slate-900">{{ displayedItemName }}</p>
                    </div>
                    <div>
                        <h4 class="text-xs font-medium text-slate-500 mb-1">{{ t('content.description') }}</h4>
                        <div class="bg-slate-50 rounded-lg p-3 border border-slate-200 prose prose-sm max-w-none">
                            <div v-if="displayedItemContent" v-html="renderMarkdown(displayedItemContent)" class="text-sm text-slate-700"></div>
                            <p v-else class="text-sm text-slate-400 italic">{{ t('content.no_description_provided') }}</p>
                        </div>
                    </div>
                </div>
            </div>

            <!-- AI Context -->
            <div v-if="cardAiEnabled && contentItem?.ai_knowledge_base" class="bg-gradient-to-r from-blue-50 to-indigo-50 rounded-xl p-4 border border-blue-200">
                <h4 class="text-sm font-semibold text-blue-900 mb-2 flex items-center gap-2">
                    <i class="pi pi-sparkles text-blue-600"></i>
                    {{ t('content.ai_knowledge_base') }}
                </h4>
                <p class="text-sm text-blue-800 whitespace-pre-wrap">{{ contentItem.ai_knowledge_base }}</p>
            </div>
        </div>

        <!-- ========== CARDS MODE: Card Item Details ========== -->
        <!-- Triggered when content_mode is 'cards' -->
        <div v-else-if="normalizedMode === 'cards'" class="flex flex-col gap-4">
            <!-- Card Image (16:9) -->
            <div class="bg-cyan-50 rounded-xl p-4 border border-cyan-200">
                <h4 class="text-sm font-semibold text-cyan-900 mb-3 flex items-center gap-2">
                    <i class="pi pi-image text-cyan-600"></i>
                    {{ t('content.content_image') }}
                </h4>
                <div class="max-w-md mx-auto border border-cyan-300 rounded-xl bg-white overflow-hidden" style="aspect-ratio: 16/9">
                    <img 
                        v-if="contentItem?.imageUrl || contentItem?.image_url"
                        :src="contentItem?.imageUrl || contentItem?.image_url"
                        alt="Card Image"
                        class="object-cover h-full w-full" 
                    />
                    <div v-else class="h-full flex items-center justify-center bg-cyan-50">
                        <div class="text-center">
                            <i class="pi pi-image text-4xl text-cyan-300"></i>
                            <p class="text-sm text-cyan-400 mt-2">{{ t('content.needs_photo') }}</p>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Details -->
            <div class="bg-white rounded-xl shadow-lg border border-cyan-200 p-4">
                <div class="space-y-4">
                    <div>
                        <h4 class="text-xs font-medium text-slate-500 mb-1">{{ t('common.name') }}</h4>
                        <p class="text-lg font-semibold text-slate-900">{{ displayedItemName }}</p>
                    </div>
                    <div>
                        <h4 class="text-xs font-medium text-slate-500 mb-1">{{ t('content.description') }}</h4>
                        <div class="bg-slate-50 rounded-lg p-3 border border-slate-200 prose prose-sm max-w-none">
                            <div v-if="displayedItemContent" v-html="renderMarkdown(displayedItemContent)" class="text-sm text-slate-700"></div>
                            <p v-else class="text-sm text-slate-400 italic">{{ t('content.no_description_provided') }}</p>
                        </div>
                    </div>
                </div>
            </div>

            <!-- AI Context -->
            <div v-if="cardAiEnabled && contentItem?.ai_knowledge_base" class="bg-gradient-to-r from-blue-50 to-indigo-50 rounded-xl p-4 border border-blue-200">
                <h4 class="text-sm font-semibold text-blue-900 mb-2 flex items-center gap-2">
                    <i class="pi pi-sparkles text-blue-600"></i>
                    {{ t('content.ai_knowledge_base') }}
                </h4>
                <p class="text-sm text-blue-800 whitespace-pre-wrap">{{ contentItem.ai_knowledge_base }}</p>
            </div>
        </div>

        <!-- ========== DEFAULT MODE: Generic Content Item ========== -->
        <div v-else class="flex flex-col gap-4">
            <!-- Image Section -->
            <div class="bg-slate-50 rounded-xl p-4">
                <h4 class="text-sm font-semibold text-slate-900 mb-3 flex items-center gap-2">
                    <i class="pi pi-image text-blue-600"></i>
                    {{ contentItem?.parent_id ? t('content.sub_item_image') : t('content.content_image') }}
                </h4>
                <div class="content-image-container max-w-md mx-auto border border-slate-300 rounded-xl bg-white">
                    <img 
                        v-if="contentItem?.imageUrl || contentItem?.image_url"
                        :src="contentItem?.imageUrl || contentItem?.image_url"
                        alt="Content Item Image"
                        class="object-contain h-full w-full rounded-lg shadow-md" 
                    />
                    <img v-else :src="cardPlaceholder" alt="Placeholder" class="object-contain h-full w-full rounded-lg shadow-md" />
                </div>
            </div>

            <!-- Details -->
            <div class="bg-white rounded-xl shadow-lg border border-slate-200 p-4">
                <div class="space-y-4">
                    <div>
                        <h4 class="text-xs font-medium text-slate-500 mb-1">{{ t('common.name') }}</h4>
                        <p class="text-lg font-semibold text-slate-900">{{ displayedItemName }}</p>
                    </div>
                    <div>
                        <h4 class="text-xs font-medium text-slate-500 mb-1">{{ t('content.description') }}</h4>
                        <div class="bg-slate-50 rounded-lg p-3 border border-slate-200 prose prose-sm max-w-none">
                            <div v-if="displayedItemContent" v-html="renderMarkdown(displayedItemContent)" class="text-sm text-slate-700"></div>
                            <p v-else class="text-sm text-slate-400 italic">{{ t('content.no_description_provided') }}</p>
                        </div>
                    </div>
                </div>
            </div>

            <!-- AI Knowledge Base -->
            <div v-if="cardAiEnabled && contentItem?.ai_knowledge_base" class="bg-gradient-to-r from-blue-50 to-indigo-50 rounded-xl p-4 border border-blue-200">
                <h4 class="text-sm font-semibold text-blue-900 mb-2 flex items-center gap-2">
                    <i class="pi pi-database text-blue-600"></i>
                    {{ t('dashboard.ai_knowledge_base') }}
                </h4>
                <p class="text-sm text-blue-800 whitespace-pre-wrap">{{ contentItem.ai_knowledge_base }}</p>
            </div>
        </div>
    </div>
</template>

<script setup>
import { computed, ref, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import Dropdown from 'primevue/dropdown';
import cardPlaceholder from '@/assets/images/card-placeholder.svg';
import { getContentAspectRatio } from '@/utils/cardConfig';
import { renderMarkdown } from '@/utils/markdownRenderer';
import { SUPPORTED_LANGUAGES } from '@/stores/translation';

const { t } = useI18n();

const props = defineProps({
    contentItem: {
        type: Object,
        default: null
    },
    cardAiEnabled: {
        type: Boolean,
        default: false
    },
    contentMode: {
        type: String,
        default: 'list',
        validator: (value) => ['single', 'list', 'grid', 'cards'].includes(value)
    },
    isGrouped: {
        type: Boolean,
        default: false
    }
});

// Language preview state
const selectedPreviewLanguage = ref(null);

// Effective grouped state
const effectiveIsGrouped = computed(() => {
    return props.isGrouped;
});

// Content mode
const normalizedMode = computed(() => {
    return props.contentMode;
});

// Mode-specific styling
const headerBorderClass = computed(() => {
    const mode = normalizedMode.value;
    switch (mode) {
        case 'single': return 'border-purple-200';
        case 'list': 
            if (effectiveIsGrouped.value) {
                return props.contentItem?.parent_id ? 'border-amber-200' : 'border-orange-200';
            }
            return 'border-blue-200';
        case 'grid': return 'border-green-200';
        case 'cards': return 'border-cyan-200';
        default: return 'border-slate-200';
    }
});

const badgeClass = computed(() => {
    const mode = normalizedMode.value;
    switch (mode) {
        case 'single': return 'bg-purple-100 text-purple-700';
        case 'list':
            if (effectiveIsGrouped.value) {
                return props.contentItem?.parent_id ? 'bg-amber-100 text-amber-700' : 'bg-orange-100 text-orange-700';
            }
            return 'bg-blue-100 text-blue-700';
        case 'grid': return 'bg-green-100 text-green-700';
        case 'cards': return 'bg-cyan-100 text-cyan-700';
        default: return 'bg-slate-100 text-slate-700';
    }
});

const badgeIcon = computed(() => {
    const mode = normalizedMode.value;
    switch (mode) {
        case 'single': return 'pi-file';
        case 'list':
            if (effectiveIsGrouped.value) {
                return props.contentItem?.parent_id ? 'pi-box' : 'pi-folder';
            }
            return 'pi-link';
        case 'grid': return 'pi-image';
        case 'cards': return 'pi-clone';
        default: return 'pi-file';
    }
});

const badgeLabel = computed(() => {
    const mode = normalizedMode.value;
    switch (mode) {
        case 'single': return t('content.page_content');
        case 'list':
            if (effectiveIsGrouped.value) {
                return props.contentItem?.parent_id ? t('content.item') : t('content.category');
            }
            return t('content.list_item');
        case 'grid': return t('content.gallery_item');
        case 'cards': return t('content.card_item');
        default: return props.contentItem?.parent_id ? t('content.sub_item') : t('content.content_item');
    }
});

// Helper function to detect link type and return appropriate icon
const getLinkIcon = (url) => {
    if (!url) return 'pi-link';
    const urlLower = url.toLowerCase();
    if (urlLower.includes('instagram')) return 'pi-instagram';
    if (urlLower.includes('facebook')) return 'pi-facebook';
    if (urlLower.includes('twitter') || urlLower.includes('x.com')) return 'pi-twitter';
    if (urlLower.includes('linkedin')) return 'pi-linkedin';
    if (urlLower.includes('youtube')) return 'pi-youtube';
    if (urlLower.includes('github')) return 'pi-github';
    if (urlLower.includes('whatsapp') || urlLower.includes('wa.me')) return 'pi-whatsapp';
    if (urlLower.includes('telegram') || urlLower.includes('t.me')) return 'pi-telegram';
    if (urlLower.includes('mailto:')) return 'pi-envelope';
    if (urlLower.includes('tel:')) return 'pi-phone';
    return 'pi-external-link';
};

// Parse translations from content item
const availableTranslations = computed(() => {
    if (!props.contentItem?.translations) return [];
    return Object.keys(props.contentItem.translations);
});

// Generate language options for dropdown
const languageOptions = computed(() => {
    const options = [{ label: t('translation.original'), value: null }];
    availableTranslations.value.forEach(langCode => {
        options.push({ label: getLanguageName(langCode), value: langCode });
    });
    return options;
});

// Get displayed content item name (original or translated)
const displayedItemName = computed(() => {
    if (!selectedPreviewLanguage.value || !props.contentItem?.translations?.[selectedPreviewLanguage.value]) {
        return props.contentItem?.name || t('content.no_name_provided');
    }
    return props.contentItem.translations[selectedPreviewLanguage.value]?.name || props.contentItem?.name;
});

// Get displayed content item content (original or translated)
const displayedItemContent = computed(() => {
    const fallback = props.contentItem?.description || props.contentItem?.content || '';
    if (!selectedPreviewLanguage.value || !props.contentItem?.translations?.[selectedPreviewLanguage.value]) {
        return fallback;
    }
    return props.contentItem.translations[selectedPreviewLanguage.value]?.content || fallback;
});

// Helper functions for language display
const getLanguageName = (langCode) => SUPPORTED_LANGUAGES[langCode] || langCode;

const getLanguageFlag = (langCode) => {
    const flagMap = {
        en: '🇬🇧', 'zh-Hant': '🇹🇼', 'zh-Hans': '🇨🇳', ja: '🇯🇵', ko: '🇰🇷',
        es: '🇪🇸', fr: '🇫🇷', ru: '🇷🇺', ar: '🇸🇦', th: '🇹🇭',
    };
    return flagMap[langCode] || '🌐';
};

// Set up CSS custom property for content aspect ratio
onMounted(() => {
    const aspectRatio = getContentAspectRatio();
    document.documentElement.style.setProperty('--content-aspect-ratio', aspectRatio);
});
</script>

<style scoped>
.content-image-container {
    aspect-ratio: var(--content-aspect-ratio, 4/3);
    width: 100%;
    background-color: white;
}

.prose :deep(a) {
    color: #3b82f6 !important;
    text-decoration: underline;
}

.prose :deep(a:hover) {
    color: #1d4ed8 !important;
}
</style>
