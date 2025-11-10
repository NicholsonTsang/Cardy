<template>
    <div class="space-y-3 sm:space-y-4 lg:space-y-6">
        <div class="flex justify-between items-center pb-3 sm:pb-4 border-b border-slate-200">
            <div class="flex items-center gap-2 sm:gap-3">
                <span class="inline-flex items-center px-2.5 sm:px-3 py-1 bg-slate-100 rounded-full text-xs sm:text-sm font-medium text-slate-700">
                    {{ contentItem?.parent_id ? t('content.sub_item') : t('content.content_item') }}
                </span>
            </div>
        </div>
        
        <div class="flex flex-col gap-3 sm:gap-4 lg:gap-6">
            <!-- Image Section -->
            <div class="w-full">
                <div class="bg-slate-50 rounded-xl p-3 sm:p-4 lg:p-6">
                    <h3 class="text-base sm:text-lg font-semibold text-slate-900 mb-3 sm:mb-4 flex items-center gap-2">
                        <i class="pi pi-image text-blue-600 text-sm sm:text-base"></i>
                        {{ contentItem?.parent_id ? t('content.sub_item_image') : t('content.content_image') }}
                    </h3>
                    <div class="content-image-container max-w-md mx-auto border border-slate-300 rounded-xl bg-white">
                        <!-- Display the already-cropped image_url directly, no need to re-apply crop parameters -->
                        <img 
                            v-if="contentItem?.imageUrl || contentItem?.image_url"
                            :src="contentItem?.imageUrl || contentItem?.image_url"
                            alt="Content Item Image"
                            class="object-contain h-full w-full rounded-lg shadow-md" 
                        />
                        <img 
                            v-else
                            :src="cardPlaceholder" 
                            alt="Content Item Image"
                            class="object-contain h-full w-full rounded-lg shadow-md" 
                        />
                    </div>
                </div>
            </div>

            <!-- Content Details Section -->
            <div class="w-full space-y-3 sm:space-y-4 lg:space-y-6">
                <!-- Basic Information -->
                <div class="bg-white rounded-xl shadow-lg border border-slate-200 p-3 sm:p-4 lg:p-6">
                    <div class="flex items-center justify-between mb-3 sm:mb-4 flex-wrap gap-2">
                        <h3 class="text-base sm:text-lg font-semibold text-slate-900 flex items-center gap-2">
                            <i class="pi pi-info-circle text-blue-600 text-sm sm:text-base"></i>
                            {{ t('content.basic_information') }}
                        </h3>
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
                    <div class="space-y-3 sm:space-y-4">
                        <div>
                            <h4 class="text-xs sm:text-sm font-medium text-slate-700 mb-1.5 sm:mb-2">{{ t('common.name') }}</h4>
                            <p class="text-sm sm:text-base text-slate-900 font-medium">{{ displayedItemName }}</p>
                        </div>

                        <div>
                            <h4 class="text-xs sm:text-sm font-medium text-slate-700 mb-1.5 sm:mb-2">{{ t('content.description') }}</h4>
                            <div class="bg-slate-50 rounded-lg p-3 sm:p-4 border border-slate-200 prose prose-sm max-w-none">
                                <div 
                                    v-if="displayedItemContent"
                                    v-html="renderMarkdown(displayedItemContent)"
                                    class="text-xs sm:text-sm text-slate-700 leading-relaxed"
                                ></div>
                                <p v-else class="text-xs sm:text-sm text-slate-500 italic">{{ t('content.no_description_provided') }}</p>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- AI Knowledge Base -->
                <div v-if="cardAiEnabled && contentItem?.ai_knowledge_base" 
                     class="bg-gradient-to-r from-blue-50 to-indigo-50 rounded-xl p-3 sm:p-4 lg:p-6 border border-blue-200">
                    <h3 class="text-base sm:text-lg font-semibold text-blue-900 mb-3 sm:mb-4 flex items-center gap-2">
                        <i class="pi pi-database text-blue-600 text-sm sm:text-base"></i>
                        {{ t('dashboard.ai_knowledge_base') }}
                    </h3>
                    <div class="bg-white rounded-lg p-3 sm:p-4 border border-blue-200">
                        <p class="text-xs sm:text-sm text-blue-800 whitespace-pre-wrap leading-relaxed">
                            {{ contentItem.ai_knowledge_base }}
                        </p>
                    </div>
                    <div class="mt-2 sm:mt-3 p-2.5 sm:p-3 bg-blue-100 rounded-lg">
                        <p class="text-xs text-blue-800 flex items-start gap-2">
                            <i class="pi pi-info-circle mt-0.5 flex-shrink-0 text-xs"></i>
                            <span>{{ t('content.ai_knowledge_info', { type: contentItem?.parent_id ? t('content.sub_item') : t('content.content_item') }) }}</span>
                        </p>
                    </div>
                </div>
            </div>
        </div>
    </div>
</template>

<script setup>
import { computed, ref, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import Button from 'primevue/button';
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
    }
});

defineEmits(['edit']);

// Language preview state
const selectedPreviewLanguage = ref(null);

// Parse translations from content item
const availableTranslations = computed(() => {
    if (!props.contentItem?.translations) return [];
    return Object.keys(props.contentItem.translations);
});

// Generate language options for dropdown (using card's original language as reference)
const languageOptions = computed(() => {
    const options = [
        {
            label: `${t('translation.original')}`,
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
    // In content_items, translated content is stored in 'content' field
    return props.contentItem.translations[selectedPreviewLanguage.value]?.content || fallback;
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

// Set up CSS custom property for content aspect ratio
onMounted(() => {
    const aspectRatio = getContentAspectRatio();
    document.documentElement.style.setProperty('--content-aspect-ratio', aspectRatio);
});
</script>

<style scoped>
/* Content image container with configurable aspect ratio */
.content-image-container {
    aspect-ratio: var(--content-aspect-ratio, 4/3);
    width: 100%;
    background-color: white;
}

/* Markdown prose link styling - 2 line truncation */
.prose :deep(a) {
    color: #3b82f6 !important;
    text-decoration: underline;
    display: -webkit-box;
    -webkit-line-clamp: 2;
    line-clamp: 2;
    -webkit-box-orient: vertical;
    overflow: hidden;
    text-overflow: ellipsis;
    word-break: break-word;
}

.prose :deep(a:hover) {
    color: #1d4ed8 !important;
}
</style> 