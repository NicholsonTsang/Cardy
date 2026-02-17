<template>
    <div class="space-y-3 sm:space-y-4">
        <!-- Header: Type Badge + Language Selector -->
        <div class="flex justify-between items-center pb-3 border-b border-slate-200">
            <span class="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium bg-slate-100 text-slate-700">
                <i :class="['pi', itemTypeBadge.icon, 'mr-1.5 text-xs']"></i>
                {{ itemTypeBadge.label }}
            </span>
            <!-- Language Preview Selector -->
            <Select
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
            </Select>
        </div>

        <!-- ========== LIST MODE: Link Preview ========== -->
        <div v-if="contentMode === 'list' && !effectiveIsGrouped" class="space-y-4">
            <div class="bg-slate-50 rounded-xl p-4 sm:p-6 border border-slate-200">
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
        </div>

        <!-- ========== ALL OTHER MODES ========== -->
        <div v-else class="flex flex-col gap-4">
            <!-- Category Header (grouped parent only) -->
            <div v-if="isCategory" class="bg-slate-50 rounded-xl p-4 sm:p-6 border border-slate-200">
                <h3 class="text-lg font-semibold text-slate-900">{{ displayedItemName }}</h3>
                <p class="text-sm text-slate-500 mt-1">{{ t('content.category_description') }}</p>
            </div>

            <!-- Normal Item Content -->
            <template v-else>
                <!-- Image Section -->
                <div v-if="hasImage" class="bg-slate-50 rounded-xl p-4 border border-slate-200">
                    <h4 class="text-sm font-semibold text-slate-700 mb-3 flex items-center gap-2">
                        <i class="pi pi-image text-slate-500"></i>
                        {{ t('content.content_image') }}
                    </h4>
                    <div class="content-image-container max-w-md mx-auto border border-slate-200 rounded-xl bg-white overflow-hidden"
                         :style="contentMode === 'cards' ? 'aspect-ratio: 16/9' : ''">
                        <img
                            :src="contentItem?.imageUrl || contentItem?.image_url"
                            alt="Item Image"
                            :class="contentMode === 'cards' ? 'object-cover' : 'object-contain'"
                            class="h-full w-full"
                        />
                    </div>
                </div>
                <div v-else-if="contentMode !== 'single' && contentMode !== 'list'" class="bg-slate-50 rounded-xl p-4 border border-slate-200">
                    <h4 class="text-sm font-semibold text-slate-700 mb-3 flex items-center gap-2">
                        <i class="pi pi-image text-slate-500"></i>
                        {{ t('content.content_image') }}
                    </h4>
                    <div class="content-image-container max-w-md mx-auto border border-slate-200 border-dashed rounded-xl bg-slate-50 flex items-center justify-center"
                         :style="contentMode === 'cards' ? 'aspect-ratio: 16/9' : ''">
                        <div class="text-center">
                            <i class="pi pi-image text-3xl text-slate-300"></i>
                            <p class="text-xs text-slate-400 mt-2">{{ t('content.needs_photo') }}</p>
                        </div>
                    </div>
                </div>

                <!-- Details: Name + Description -->
                <div class="bg-white rounded-xl border border-slate-200 p-4">
                    <div class="space-y-4">
                        <!-- Single mode: inline name + full content -->
                        <template v-if="contentMode === 'single'">
                            <h3 class="text-lg font-semibold text-slate-900">{{ displayedItemName }}</h3>
                            <div class="bg-slate-50 rounded-lg p-4 border border-slate-200 prose prose-sm max-w-none">
                                <div v-if="displayedItemContent" v-html="renderMarkdown(displayedItemContent)" class="text-sm text-slate-700"></div>
                                <p v-else class="text-sm text-slate-400 italic">{{ t('content.no_description_provided') }}</p>
                            </div>
                        </template>

                        <!-- Other modes: labeled name + description -->
                        <template v-else>
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
                        </template>
                    </div>
                </div>
            </template>
        </div>

        <!-- AI Context (single instance for all modes) -->
        <div v-if="cardAiEnabled && contentItem?.ai_knowledge_base" class="bg-blue-50/50 rounded-xl p-4 border border-blue-100">
            <h4 class="text-sm font-semibold text-blue-900 mb-2 flex items-center gap-2">
                <i class="pi pi-sparkles text-blue-600"></i>
                {{ t('content.ai_knowledge_base') }}
            </h4>
            <p class="text-sm text-blue-800 whitespace-pre-wrap">{{ contentItem.ai_knowledge_base }}</p>
        </div>
    </div>
</template>

<script setup>
import { computed, ref, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import Select from 'primevue/select';
import { getContentAspectRatio } from '@/utils/cardConfig';
import { renderMarkdown } from '@/utils/markdownRenderer';
import { getLanguageFlag } from '@/utils/formatters';
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
const effectiveIsGrouped = computed(() => props.isGrouped);

// Is this a category header (grouped parent)?
const isCategory = computed(() => effectiveIsGrouped.value && !props.contentItem?.parent_id);

// Does this item have an image?
const hasImage = computed(() => !!(props.contentItem?.imageUrl || props.contentItem?.image_url));

// Single badge computed replacing 4 separate switch-statement computeds
const itemTypeBadge = computed(() => {
    const mode = props.contentMode;
    if (effectiveIsGrouped.value) {
        return props.contentItem?.parent_id
            ? { icon: 'pi-box', label: t('content.item') }
            : { icon: 'pi-folder', label: t('content.category') };
    }
    switch (mode) {
        case 'single': return { icon: 'pi-file', label: t('content.page_content') };
        case 'list': return { icon: 'pi-link', label: t('content.list_item') };
        case 'grid': return { icon: 'pi-image', label: t('content.gallery_item') };
        case 'cards': return { icon: 'pi-clone', label: t('content.card_item') };
        default: return { icon: 'pi-file', label: t('content.content_item') };
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
