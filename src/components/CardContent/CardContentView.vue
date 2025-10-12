<template>
    <div class="space-y-6">
        <div class="flex justify-between items-center pb-4 border-b border-slate-200">
            <div class="flex items-center gap-3">
                <span class="inline-flex items-center px-3 py-1 bg-slate-100 rounded-full text-sm font-medium text-slate-700">
                    {{ contentItem?.parent_id ? t('content.sub_item') : t('content.content_item') }}
                </span>
            </div>
        </div>
        
        <div class="flex flex-col gap-6">
            <!-- Image Section -->
            <div class="w-full">
                <div class="bg-slate-50 rounded-xl p-6">
                    <h3 class="text-lg font-semibold text-slate-900 mb-4 flex items-center gap-2">
                        <i class="pi pi-image text-blue-600"></i>
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
            <div class="w-full space-y-6">
                <!-- Basic Information -->
                <div class="bg-white rounded-xl shadow-lg border border-slate-200 p-6">
                    <div class="flex items-center justify-between mb-4">
                        <h3 class="text-lg font-semibold text-slate-900 flex items-center gap-2">
                            <i class="pi pi-info-circle text-blue-600"></i>
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
                            <h4 class="text-sm font-medium text-slate-700 mb-2">{{ t('common.name') }}</h4>
                            <p class="text-base text-slate-900 font-medium">{{ displayedItemName }}</p>
                        </div>

                        <div>
                            <h4 class="text-sm font-medium text-slate-700 mb-2">{{ t('content.description') }}</h4>
                            <div class="bg-slate-50 rounded-lg p-4 border border-slate-200 prose prose-sm max-w-none">
                                <div 
                                    v-if="displayedItemContent"
                                    v-html="renderMarkdown(displayedItemContent)"
                                    class="text-sm text-slate-700 leading-relaxed"
                                ></div>
                                <p v-else class="text-sm text-slate-500 italic">{{ t('content.no_description_provided') }}</p>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- AI Knowledge Base -->
                <div v-if="cardAiEnabled && contentItem?.ai_knowledge_base" 
                     class="bg-gradient-to-r from-blue-50 to-indigo-50 rounded-xl p-6 border border-blue-200">
                    <h3 class="text-lg font-semibold text-blue-900 mb-4 flex items-center gap-2">
                        <i class="pi pi-database text-blue-600"></i>
                        {{ t('dashboard.ai_knowledge_base') }}
                    </h3>
                    <div class="bg-white rounded-lg p-4 border border-blue-200">
                        <p class="text-sm text-blue-800 whitespace-pre-wrap leading-relaxed">
                            {{ contentItem.ai_knowledge_base }}
                        </p>
                    </div>
                    <div class="mt-3 p-3 bg-blue-100 rounded-lg">
                        <p class="text-xs text-blue-800 flex items-start gap-2">
                            <i class="pi pi-info-circle mt-0.5 flex-shrink-0"></i>
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
import { marked } from 'marked';
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

// Markdown rendering helper
const renderMarkdown = (text) => {
    if (!text) return '';
    return marked(text);
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
</style> 