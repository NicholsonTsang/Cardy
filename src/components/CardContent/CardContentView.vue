<template>
    <div class="space-y-6">
        <div class="flex justify-between items-center pb-4 border-b border-slate-200">
            <div class="flex items-center gap-3">
                <span class="inline-flex items-center px-3 py-1 bg-slate-100 rounded-full text-sm font-medium text-slate-700">
                    {{ contentItem?.parent_id ? 'Sub-item' : 'Content Item' }}
                </span>
            </div>
        </div>
        
        <div class="flex flex-col gap-6">
            <!-- Image Section -->
            <div class="w-full">
                <div class="bg-slate-50 rounded-xl p-6">
                    <h3 class="text-lg font-semibold text-slate-900 mb-4 flex items-center gap-2">
                        <i class="pi pi-image text-blue-600"></i>
                        {{ contentItem?.parent_id ? 'Sub-item' : 'Content' }} Image
                    </h3>
                    <div class="content-image-container max-w-md mx-auto border border-slate-300 rounded-xl bg-white">
                        <CroppedImageDisplay
                            v-if="contentItem?.imageUrl || contentItem?.image_url"
                            :imageSrc="contentItem?.imageUrl || contentItem?.image_url"
                            :cropParameters="contentItem?.crop_parameters"
                            alt="Content Item Image"
                            imageClass="object-contain h-full w-full rounded-lg shadow-md"
                            :previewSize="400"
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
                        Basic Information
                    </h3>
                    <div class="space-y-4">
                        <div>
                            <h4 class="text-sm font-medium text-slate-700 mb-2">Name</h4>
                            <p class="text-base text-slate-900 font-medium">{{ contentItem?.name || 'No name provided' }}</p>
                        </div>

                        <div>
                            <h4 class="text-sm font-medium text-slate-700 mb-2">Description</h4>
                            <div class="bg-slate-50 rounded-lg p-4 border border-slate-200">
                                <p class="text-sm text-slate-700 whitespace-pre-wrap leading-relaxed">
                                    {{ contentItem?.description || contentItem?.content || 'No description provided' }}
                                </p>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- AI Metadata -->
                <div v-if="contentItem?.ai_metadata" 
                     class="bg-gradient-to-r from-amber-50 to-orange-50 rounded-xl p-6 border border-amber-200">
                    <h3 class="text-lg font-semibold text-amber-900 mb-4 flex items-center gap-2">
                        <i class="pi pi-database text-amber-600"></i>
                        AI Metadata
                    </h3>
                    <div class="bg-white rounded-lg p-4 border border-amber-200">
                        <p class="text-sm text-amber-800 whitespace-pre-wrap leading-relaxed">
                            {{ contentItem.ai_metadata }}
                        </p>
                    </div>
                    <div class="mt-3 p-3 bg-amber-100 rounded-lg">
                        <p class="text-xs text-amber-800 flex items-start gap-2">
                            <i class="pi pi-info-circle mt-0.5 flex-shrink-0"></i>
                            <span>This additional knowledge data helps the AI provide more accurate and detailed responses about this content item.</span>
                        </p>
                    </div>
                </div>
            </div>
        </div>
    </div>
</template>

<script setup>
import { onMounted } from 'vue';
import Button from 'primevue/button';
import CroppedImageDisplay from '@/components/CroppedImageDisplay.vue';
import cardPlaceholder from '@/assets/images/card-placeholder.svg';
import { getContentAspectRatio } from '@/utils/cardConfig';

defineProps({
    contentItem: {
        type: Object,
        default: null
    }
});

defineEmits(['edit']);

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