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
                    <h3 class="text-lg font-semibold text-slate-900 mb-4 flex items-center gap-2">
                        <i class="pi pi-info-circle text-blue-600"></i>
                        {{ t('content.basic_information') }}
                    </h3>
                    <div class="space-y-4">
                        <div>
                            <h4 class="text-sm font-medium text-slate-700 mb-2">{{ t('common.name') }}</h4>
                            <p class="text-base text-slate-900 font-medium">{{ contentItem?.name || t('content.no_name_provided') }}</p>
                        </div>

                        <div>
                            <h4 class="text-sm font-medium text-slate-700 mb-2">{{ t('content.description') }}</h4>
                            <div class="bg-slate-50 rounded-lg p-4 border border-slate-200 prose prose-sm max-w-none">
                                <div 
                                    v-if="contentItem?.description || contentItem?.content"
                                    v-html="renderMarkdown(contentItem?.description || contentItem?.content)"
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
import { onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import Button from 'primevue/button';
import cardPlaceholder from '@/assets/images/card-placeholder.svg';
import { getContentAspectRatio } from '@/utils/cardConfig';
import { marked } from 'marked';

const { t } = useI18n();

defineProps({
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