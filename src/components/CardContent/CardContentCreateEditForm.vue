<template>
    <div class="space-y-6">
        <div class="grid grid-cols-1 xl:grid-cols-3 gap-6">
            <!-- Image Section -->
            <div class="xl:col-span-1">
                <div class="bg-white rounded-xl shadow-lg border border-slate-200 p-6">
                    <h3 class="text-lg font-semibold text-slate-900 mb-6 flex items-center gap-2">
                        <i class="pi pi-image text-blue-600"></i>
                        {{ itemTypeLabel }} Image
                    </h3>
                    
                    <!-- Single-Column Layout -->
                    <div class="space-y-6">
                        <!-- Requirements, Actions Section -->
                        <div class="space-y-4">
                            <!-- Image Requirements Info -->
                            <div class="p-3 bg-blue-100 rounded-lg">
                                <p class="text-xs text-blue-800 flex items-start gap-2">
                                    <i class="pi pi-info-circle mt-0.5 flex-shrink-0"></i>
                                    <span><strong>Image Requirements:</strong> Upload JPG or PNG files up to 5MB. Recommended aspect ratio: {{ getContentAspectRatioDisplay() }} for optimal display. You can crop and adjust your image after uploading.</span>
                                </p>
                            </div>
                        
                            <!-- Combined Upload/Preview Area -->
                            <div 
                                v-if="!previewImage"
                                class="upload-drop-zone-content"
                                @dragover.prevent="handleDragOver"
                                @dragleave.prevent="handleDragLeave"
                                @drop.prevent="handleDrop"
                                :class="{ 'drag-active': isDragActive }"
                            >
                                <div class="upload-content">
                                    <div class="upload-icon-container">
                                        <i class="pi pi-image upload-icon"></i>
                                    </div>
                                    <h4 class="upload-title">Add {{ parentId ? 'sub-item' : 'content' }} image</h4>
                                    <p class="upload-subtitle">Drag and drop or click to upload</p>
                                
                                    <!-- Hidden File Input -->
                                    <input 
                                        ref="fileInputRef"
                                        type="file" 
                                        accept="image/*"
                                        @change="handleFileSelect"
                                        class="hidden"
                                    />
                                    
                                    <Button 
                                        label="Upload image"
                                        icon="pi pi-upload"
                                        @click="triggerFileInput"
                                        class="upload-trigger-button"
                                        severity="info"
                                        size="small"
                                    />
                                </div>
                            </div>
                            
                            <!-- Image Preview with Actions -->
                            <div v-else class="space-y-4">
                                <div class="content-image-container-compact border-2 border-solid border-blue-400 bg-white rounded-xl relative">
                                    <img 
                                        :src="previewImage" 
                                        :alt="`${itemTypeLabel} Preview`"
                                        class="object-contain h-full w-full rounded-lg shadow-md" 
                                    />
                                </div>
                                
                                <div class="image-actions-content">
                                    <Button 
                                        label="Change image"
                                        icon="pi pi-image"
                                        @click="triggerFileInput"
                                        severity="secondary"
                                        outlined
                                        size="small"
                                        class="action-button-content"
                                    />
                                    <Button 
                                        label="Edit crop"
                                        icon="pi pi-crop"
                                        @click="handleReCrop"
                                        severity="info"
                                        outlined
                                        size="small"
                                        class="action-button-content"
                                    />
                                </div>
                                
                                <!-- Hidden File Input for Change Photo -->
                                <input 
                                    ref="fileInputRef"
                                    type="file" 
                                    accept="image/*"
                                    @change="handleFileSelect"
                                    class="hidden"
                                />
                            </div>
                        </div>
                    </div>
                </div>
            </div>
            
            <!-- Form Fields Section -->
            <div class="xl:col-span-2">
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
                                    class="w-full" 
                                    :placeholder="`Enter ${itemTypeLabel.toLowerCase()} name`"
                                    :class="{ 'p-invalid': !formData.name.trim() }"
                                />
                                <small v-if="!formData.name.trim()" class="p-error">Name is required</small>
                            </div>

                            <div>
                                <label class="block text-sm font-medium text-slate-700 mb-2">Description (Markdown)</label>
                                <MdEditor 
                                    v-model="formData.description"
                                    language="en-US"
                                    :toolbars="markdownToolbars"
                                    :placeholder="getDescriptionPlaceholder()"
                                    style="height: 300px;"
                                />
                            </div>
                        </div>
                    </div>

                    <!-- AI Knowledge Base Section (shown only if card has AI enabled) -->
                    <div v-if="cardAiEnabled" class="border-t border-slate-200 pt-6">
                        <div class="bg-gradient-to-r from-blue-50 to-indigo-50 border border-blue-200 rounded-lg p-4">
                            <label class="flex items-center gap-2 text-sm font-medium text-blue-900 mb-2">
                                <i class="pi pi-database"></i>
                                AI Knowledge Base
                                <span class="text-xs text-blue-600 ml-auto">{{ aiKnowledgeBaseWordCount }}/500 words</span>
                            </label>
                            <Textarea 
                                v-model="formData.aiKnowledgeBase" 
                                rows="5" 
                                class="w-full px-4 py-3 border border-blue-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors resize-none bg-white" 
                                :class="{ 'border-red-500': aiKnowledgeBaseWordCount > 500 }"
                                :placeholder="getAiKnowledgePlaceholder()"
                                autoResize
                            />
                            <div class="mt-3 p-3 bg-blue-50 border border-blue-200 rounded-lg">
                                <p class="text-xs text-blue-800 flex items-start gap-2">
                                    <i class="pi pi-info-circle mt-0.5 flex-shrink-0"></i>
                                    <span><strong>Purpose:</strong> Provide content-specific knowledge for this {{ itemTypeLabel.toLowerCase() }}. Include facts, specifications, historical details, or contextual information that helps the AI answer visitor questions accurately (max 500 words).</span>
                                </p>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <!-- Image Cropping Dialog -->
    <MyDialog 
        v-model="showCropDialog"
        modal
        :header="`Crop ${itemTypeLabel} Image`"
        :style="{ width: '90vw', maxWidth: '800px' }"
        :closable="false"
        :showConfirm="true"
        :showCancel="true"
        confirmLabel="Apply"
        cancelLabel="Cancel"
        :confirmHandle="handleCropConfirm"
        @cancel="handleCropCancelled"
    >
        <ImageCropper
            v-if="showCropDialog && cropImageSrc"
            :imageSrc="cropImageSrc"
            :aspectRatio="getContentAspectRatioNumber()"
            :aspectRatioDisplay="getContentAspectRatioDisplay()"
            :cropParameters="cropParameters"
            ref="imageCropperRef"
        />
    </MyDialog>
</template>

<script setup>
import { ref, watch, computed, onMounted, nextTick, defineProps, defineEmits, defineExpose } from 'vue';
import Button from 'primevue/button';
import Textarea from 'primevue/textarea';
import InputText from 'primevue/inputtext';
import MyDialog from '@/components/MyDialog.vue';
import ImageCropper from '@/components/ImageCropper.vue';
import cardPlaceholder from '@/assets/images/card-placeholder.svg';
import { getContentAspectRatioNumber, getContentAspectRatioDisplay, getContentAspectRatio } from '@/utils/cardConfig';
import { MdEditor } from 'md-editor-v3';
import 'md-editor-v3/lib/style.css';
import { generateCropPreview } from '@/utils/cropUtils';

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
    },
    cardId: {
        type: String,
        required: true
    }
});

const emit = defineEmits(['cancel']);

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

// Generate appropriate placeholder text for AI knowledge base
const getAiKnowledgePlaceholder = () => {
    if (props.parentId) {
        return 'Provide content-specific knowledge for this sub-item. Include facts, specifications, historical details, or contextual information...';
    } else {
        return 'Provide content-specific knowledge for this content item. Include facts, specifications, historical details, or contextual information...';
    }
};

const formData = ref({
    id: null,
    name: '',
    description: '',
    imageUrl: null,
    originalImageUrl: null,
    aiKnowledgeBase: '',
    cropParameters: null
});

// Word count computed property
const aiKnowledgeBaseWordCount = computed(() => {
    return (formData.value.aiKnowledgeBase || '').trim().split(/\s+/).filter(word => word.length > 0).length;
});

const previewImage = ref(null);
const imageFile = ref(null); // Original uploaded file (raw)
const croppedImageFile = ref(null); // Cropped image file
const originalData = ref(null);

// Cropping state
const showCropDialog = ref(false);
const cropImageSrc = ref(null);
const imageCropperRef = ref(null);
const cropParameters = ref(null);

// LinkedIn-style upload variables
const isDragActive = ref(false);
const fileInputRef = ref(null);

// Markdown editor configuration
const markdownToolbars = ref([
    'bold',
    'underline',
    'italic',
    '-',
    'title',
    'strikeThrough',
    'sub',
    'sup',
    'quote',
    'unorderedList',
    'orderedList',
    '-',
    'codeRow',
    'code',
    'link',
    'table',
    '-',
    'revoke',
    'next',
    'save',
    '=',
    'pageFullscreen',
    'fullscreen',
    'preview',
    'htmlPreview',
    'catalog'
]);

// Initialize form data when contentItem changes
watch(() => props.contentItem, (newVal) => {
    if (newVal && typeof newVal === 'object') {
        formData.value = {
            id: newVal.id,
            name: newVal.name || '',
            description: newVal.description || newVal.content || '',
            imageUrl: newVal.imageUrl || newVal.image_url || null,
            originalImageUrl: newVal.originalImageUrl || newVal.original_image_url || null,
            aiKnowledgeBase: newVal.aiKnowledgeBase || newVal.ai_knowledge_base || '',
            cropParameters: newVal.cropParameters || newVal.crop_parameters || null
        };
        originalData.value = { ...formData.value };
        
        // Set crop parameters if they exist
        if (formData.value.cropParameters) {
            cropParameters.value = formData.value.cropParameters;
        }
        
        // For edit mode: Simply display the already-cropped imageUrl
        // The imageUrl is the final cropped result, no need to re-generate preview
        previewImage.value = formData.value.imageUrl;
    }
}, { immediate: true });

const handleImageUpload = (event) => {
    const file = event.files[0];
    if (file) {
        // Store the original image file
        imageFile.value = file;
        
        // Create a preview URL for cropping
        const reader = new FileReader();
        reader.onload = (e) => {
            cropImageSrc.value = e.target.result;
            showCropDialog.value = true;
        };
        reader.readAsDataURL(file);
    }
};

// Re-crop existing image
const handleReCrop = () => {
    // Priority: imageFile (new upload) > originalImageUrl (saved) > imageUrl (fallback for old data)
    const originalImage = imageFile.value || formData.value.originalImageUrl || formData.value.imageUrl;
    
    if (originalImage) {
        // Use the original image file or URL
        const imageSrc = imageFile.value ? URL.createObjectURL(imageFile.value) : originalImage;
        cropImageSrc.value = imageSrc;
        
        // Set the existing crop parameters to restore previous crop state
        cropParameters.value = formData.value.cropParameters || null;
        showCropDialog.value = true;
    } else {
        console.warn('No original image available for re-cropping');
    }
};

// LinkedIn-style upload functions
const triggerFileInput = () => {
    fileInputRef.value?.click();
};

const handleFileSelect = (event) => {
    const file = event.target.files[0];
    if (file) {
        processImageFile(file);
    }
};

const handleDragOver = (event) => {
    event.preventDefault();
    isDragActive.value = true;
};

const handleDragLeave = (event) => {
    event.preventDefault();
    isDragActive.value = false;
};

const handleDrop = (event) => {
    event.preventDefault();
    isDragActive.value = false;
    
    const files = event.dataTransfer.files;
    if (files.length > 0) {
        const file = files[0];
        if (file.type.startsWith('image/')) {
            processImageFile(file);
        }
    }
};

// Process image file (LinkedIn flow: immediate cropping)
const processImageFile = (file) => {
    // Validate file size (5MB)
    if (file.size > 5000000) {
        console.error('File size exceeds 5MB limit');
        return;
    }
    
    // Store the file
    imageFile.value = file;
    
    // Create preview URL
    const previewUrl = URL.createObjectURL(file);
    
    // LinkedIn-style: Immediately open crop dialog after upload
    cropImageSrc.value = previewUrl;
    cropParameters.value = null; // Start fresh
    showCropDialog.value = true;
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
    // Ensure crop parameters are included in form data
    formData.value.cropParameters = cropParameters.value;
    
    return {
        formData: formData.value,
        imageFile: imageFile.value, // Original uploaded file
        croppedImageFile: croppedImageFile.value, // Cropped image file
        cropParameters: cropParameters.value
    };
};

const resetForm = () => {
    formData.value = {
        id: null,
        name: '',
        description: '',
        imageUrl: null,
        originalImageUrl: null,
        aiKnowledgeBase: '',
        cropParameters: null
    };
    previewImage.value = null;
    imageFile.value = null;
    croppedImageFile.value = null;
    originalData.value = null;
    showCropDialog.value = false;
    cropImageSrc.value = null;
    cropParameters.value = null;
};

// Cropping event handlers
const handleCropConfirm = async () => {
    // Wait for the component to be mounted
    await nextTick();
    
    if (imageCropperRef.value) {
        try {
            // Get both crop parameters AND cropped image
            const cropParams = imageCropperRef.value.getCropParameters();
            const croppedDataURL = imageCropperRef.value.getCroppedImage();
            
            if (cropParams && croppedDataURL) {
                // Store the crop parameters
                cropParameters.value = cropParams;
                
                // Convert cropped dataURL to File
                const arr = croppedDataURL.split(',');
                const mime = arr[0].match(/:(.*?);/)[1];
                const bstr = atob(arr[1]);
                let n = bstr.length;
                const u8arr = new Uint8Array(n);
                while (n--) {
                    u8arr[n] = bstr.charCodeAt(n);
                }
                croppedImageFile.value = new File([u8arr], 'cropped-image.jpg', { type: mime });
                
                // Use cropped image for preview
                previewImage.value = croppedDataURL;
                
                console.log('Crop applied - parameters and cropped file saved');
            } else {
                console.error('Failed to get crop parameters or cropped image');
            }
        } catch (error) {
            console.error('Error generating crop:', error);
        }
    } else {
        console.error('ImageCropper ref not available');
    }
    
    // Close the cropping dialog
    showCropDialog.value = false;
    cropImageSrc.value = null;
};

const handleCropCancelled = () => {
    // Close the cropping dialog without updating the image
    showCropDialog.value = false;
    cropImageSrc.value = null;
};

// Set up CSS custom property for content aspect ratio
onMounted(() => {
    const aspectRatio = getContentAspectRatio();
    document.documentElement.style.setProperty('--content-aspect-ratio', aspectRatio);
});

// Expose methods to parent component
defineExpose({
    getFormData,
    resetForm
});
</script>

<style scoped>
/* Content image container with configurable aspect ratio */
.content-image-container {
    aspect-ratio: var(--content-aspect-ratio, 4/3);
    width: 100%;
    background-color: white;
}

/* Compact container for sub-items */
.content-image-container-compact {
    aspect-ratio: var(--content-aspect-ratio, 4/3);
    width: 100%;
    max-width: 300px;
    margin: 0 auto;
    background-color: white;
}

/* LinkedIn-Style Upload Drop Zone for Content */
.upload-drop-zone-content {
    border: 2px dashed #cbd5e1;
    border-radius: 8px;
    padding: 24px 16px;
    text-align: center;
    background: #fefefe;
    transition: all 0.3s ease;
    cursor: pointer;
    position: relative;
    overflow: hidden;
}

.upload-drop-zone-content:hover {
    border-color: #3b82f6;
    background: #f8faff;
    transform: translateY(-1px);
    box-shadow: 0 4px 12px rgba(59, 130, 246, 0.1);
}

.upload-drop-zone-content.drag-active {
    border-color: #2563eb;
    background: #eff6ff;
    transform: scale(1.01);
    box-shadow: 0 6px 20px rgba(59, 130, 246, 0.2);
}

.upload-content {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 12px;
}

.upload-icon-container {
    width: 48px;
    height: 48px;
    background: linear-gradient(135deg, #e0f2fe 0%, #b3e5fc 100%);
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
    margin-bottom: 4px;
}

.upload-icon {
    font-size: 20px;
    color: #0277bd;
}

.upload-title {
    font-size: 14px;
    font-weight: 600;
    color: #1e293b;
    margin: 0;
}

.upload-subtitle {
    font-size: 12px;
    color: #64748b;
    margin: 0;
}

.upload-trigger-button {
    margin-top: 4px;
    padding: 6px 12px;
    font-weight: 500;
}


/* LinkedIn-Style Action Buttons for Content */
.image-actions-content {
    display: flex;
    gap: 6px;
    flex-wrap: wrap;
    justify-content: center;
}

.action-button-content {
    font-weight: 500;
    border-radius: 4px;
    transition: all 0.2s ease;
    min-width: 80px;
}

.action-button-content:hover {
    transform: translateY(-1px);
    box-shadow: 0 2px 6px rgba(0, 0, 0, 0.1);
}

</style> 