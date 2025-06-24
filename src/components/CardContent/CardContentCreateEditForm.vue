<template>
    <div class="space-y-6">
        <div class="flex flex-col gap-6">
            <!-- Image Section -->
            <div class="w-full">
                <div class="bg-white rounded-xl shadow-lg border border-slate-200 p-6">
                    <h3 class="text-lg font-semibold text-slate-900 mb-4 flex items-center gap-2">
                        <i class="pi pi-image text-blue-600"></i>
                        {{ itemTypeLabel }} Image
                    </h3>
                    <div class="w-full">
                        <div class="aspect-video max-w-md mx-auto border-2 border-dashed border-slate-300 rounded-xl p-4 relative mb-4 transition-all duration-200 hover:border-blue-400 hover:bg-blue-50/50"
                            :class="{ 
                                'border-solid border-blue-400 bg-blue-50/30': previewImage,
                                'bg-slate-50': !previewImage 
                            }">
                            <img 
                                :src="previewImage || cardPlaceholder" 
                                :alt="`${itemTypeLabel} Preview`"
                                class="object-cover h-full w-full rounded-lg shadow-md" 
                            />
                            <div v-if="!previewImage"
                                class="absolute inset-0 flex items-center justify-center text-slate-500 text-center p-4">
                                <div>
                                    <i class="pi pi-image text-3xl mb-3 opacity-50"></i>
                                    <span class="text-sm font-medium">Upload image</span>
                                    <span class="text-xs text-slate-400 mt-1 block">Drag & drop or click</span>
                                </div>
                            </div>
                        </div>
                        <FileUpload 
                            mode="basic" 
                            name="imageUpload" 
                            accept="image/*" 
                            :maxFileSize="5000000"
                            chooseLabel="Upload Image" 
                            chooseIcon="pi pi-upload" 
                            @select="handleImageUpload" 
                            :auto="false"
                            customUpload 
                            class="w-full" 
                            severity="info"
                        />
                        <p class="text-xs text-slate-500 mt-2 flex items-center gap-1">
                            <i class="pi pi-info-circle"></i>
                            Max: 5MB
                        </p>
                    </div>
                </div>
            </div>

            <!-- Form Fields Section -->
            <div class="w-full">
                <div class="bg-white rounded-xl shadow-lg border border-slate-200 p-6 space-y-6">
                    <div>
                        <h3 class="text-lg font-semibold text-slate-900 mb-4 flex items-center gap-2">
                            <i class="pi pi-cog text-blue-600"></i>
                            {{ itemTypeLabel }} Details
                        </h3>
                        
                        <div class="space-y-4">
                            <div>
                                <label class="block text-sm font-medium text-slate-700 mb-2">Name *</label>
                                <InputText 
                                    v-model="formData.name" 
                                    class="w-full px-4 py-3 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors" 
                                    :placeholder="`Enter ${itemTypeLabel.toLowerCase()} name`"
                                    :class="{ 'border-red-300 focus:ring-red-500 focus:border-red-500': !formData.name.trim() }"
                                />
                                <p v-if="!formData.name.trim()" class="text-sm text-red-600 mt-1">Name is required</p>
                            </div>

                            <div>
                                <label class="block text-sm font-medium text-slate-700 mb-2">Description</label>
                                <Textarea 
                                    v-model="formData.description" 
                                    rows="3" 
                                    class="w-full px-4 py-3 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors resize-none" 
                                    :placeholder="getDescriptionPlaceholder()"
                                    autoResize
                                />
                            </div>
                        </div>
                    </div>

                    <!-- AI Metadata Section (shown only if card has AI enabled) -->
                    <div v-if="cardAiEnabled" class="border-t border-slate-200 pt-6">
                        <div class="bg-gradient-to-r from-amber-50 to-orange-50 border border-amber-200 rounded-lg p-4">
                            <label class="block text-sm font-medium text-amber-900 mb-2 flex items-center gap-2">
                                <i class="pi pi-database"></i>
                                AI Metadata
                            </label>
                            <Textarea 
                                v-model="formData.aiMetadata" 
                                rows="4" 
                                class="w-full px-4 py-3 border border-amber-300 rounded-lg focus:ring-2 focus:ring-amber-500 focus:border-amber-500 transition-colors resize-none bg-white" 
                                :placeholder="getAiMetadataPlaceholder()"
                                autoResize
                            />
                            <div class="mt-3 p-3 bg-amber-100 rounded-lg">
                                <p class="text-xs text-amber-800 flex items-start gap-2">
                                    <i class="pi pi-lightbulb mt-0.5 flex-shrink-0"></i>
                                    <span><strong>Tip:</strong> Provide additional knowledge data about this {{ itemTypeLabel.toLowerCase() }}. Include facts, specifications, historical details, or other information that will help the AI provide accurate and detailed responses to visitor questions.</span>
                                </p>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</template>

<script setup>
import { ref, watch, computed, defineProps, defineEmits, defineExpose } from 'vue';
import FileUpload from 'primevue/fileupload';
import Button from 'primevue/button';
import Textarea from 'primevue/textarea';
import InputText from 'primevue/inputtext';
import cardPlaceholder from '@/assets/images/card-placeholder.svg';

const props = defineProps({
    contentItem: {
        type: Object,
        default: null
    },
    mode: {
        type: String,
        default: 'create' // 'create' or 'edit'
    },
    loading: {
        type: Boolean,
        default: false
    },
    parentId: {
        type: String,
        default: null
    },
    cardAiEnabled: {
        type: Boolean,
        default: false
    }
});

const emit = defineEmits(['save', 'cancel']);

// Determine the item type label based on whether it has a parent
const itemTypeLabel = computed(() => {
    return props.parentId ? 'Sub-item' : 'Content Item';
});

// Generate appropriate placeholder text for description
const getDescriptionPlaceholder = () => {
    if (props.parentId) {
        return 'Describe this sub-item, its significance, details, and any interesting information visitors should know...';
    } else {
        return 'Describe this content item, its context, significance, and what visitors can expect to learn...';
    }
};

// Generate appropriate placeholder text for AI metadata
const getAiMetadataPlaceholder = () => {
    if (props.parentId) {
        return 'Provide additional knowledge data about this sub-item. Include facts, specifications, historical details, or other information that will help the AI provide accurate and detailed responses to visitor questions...';
    } else {
        return 'Provide additional knowledge data about this content item. Include facts, specifications, historical details, or other information that will help the AI provide accurate and detailed responses to visitor questions...';
    }
};

const formData = ref({
    id: null,
    name: '',
    description: '',
    imageUrl: null,
    aiMetadata: ''
});

const previewImage = ref(null);
const imageFile = ref(null);
const originalData = ref(null);

// Initialize form data when contentItem changes
watch(() => props.contentItem, (newVal) => {
    if (newVal && typeof newVal === 'object') {
        formData.value = {
            id: newVal.id,
            name: newVal.name || '',
            description: newVal.description || newVal.content || '',
            imageUrl: newVal.imageUrl || (newVal.image_urls && newVal.image_urls.length > 0 ? newVal.image_urls[0] : null),
            aiMetadata: newVal.aiMetadata || newVal.ai_metadata || ''
        };
        originalData.value = { ...formData.value };
        previewImage.value = formData.value.imageUrl;
    }
}, { immediate: true });

const handleImageUpload = (event) => {
    const file = event.files[0];
    if (file) {
        imageFile.value = file;
        
        // Create a preview URL
        const reader = new FileReader();
        reader.onload = (e) => {
            previewImage.value = e.target.result;
        };
        reader.readAsDataURL(file);
    }
};

const handleSave = () => {
    if (!formData.value.name.trim()) {
        return;
    }
    
    emit('save', {
        formData: formData.value,
        imageFile: imageFile.value
    });
};

const handleCancel = () => {
    if (props.mode === 'edit' && originalData.value) {
        // Restore original data
        formData.value = { ...originalData.value };
        previewImage.value = originalData.value.imageUrl;
        imageFile.value = null;
    } else {
        // Reset form for create mode
        resetForm();
    }
    emit('cancel');
};

const getFormData = () => {
    return {
        formData: formData.value,
        imageFile: imageFile.value
    };
};

const resetForm = () => {
    formData.value = {
        id: null,
        name: '',
        description: '',
        imageUrl: null,
        aiMetadata: ''
    };
    previewImage.value = null;
    imageFile.value = null;
    originalData.value = null;
};

// Expose methods to parent component
defineExpose({
    getFormData,
    resetForm
});
</script>

<style scoped>
.aspect-video {
    aspect-ratio: 16 / 9;
}

/* Override PrimeVue component font sizes */
:deep(.p-inputtext) {
    font-size: 0.75rem;
    line-height: 1.2;
}

:deep(.p-textarea) {
    font-size: 0.75rem;
    line-height: 1.2;
}

:deep(.p-fileupload-basic .p-button) {
    font-size: 0.75rem;
    padding: 0.25rem 0.5rem;
}
</style> 