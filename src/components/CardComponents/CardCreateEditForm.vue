<template>
    <div class="space-y-6">
        <!-- Action Buttons - Only show in standalone edit mode -->
        <div class="flex justify-end gap-3 mb-6" v-if="isEditMode && !isInDialog">
            <Button 
                label="Cancel" 
                icon="pi pi-times" 
                severity="secondary" 
                outlined
                class="px-4 py-2"
                @click="handleCancel" 
            />
            <Button 
                label="Save Changes" 
                icon="pi pi-save" 
                class="px-4 py-2 shadow-lg hover:shadow-xl transition-shadow bg-blue-600 hover:bg-blue-700 text-white border-0"
                :disabled="!isFormValid"
                :loading="loading"
                @click="handleSave" 
            />
        </div>
            
        <div class="grid grid-cols-1 xl:grid-cols-3 gap-6">
            <!-- Artwork Section -->
            <div class="xl:col-span-1">
                <div class="bg-white rounded-xl shadow-lg border border-slate-200 p-6">
                    <h3 class="text-lg font-semibold text-slate-900 mb-6 flex items-center gap-2">
                        <i class="pi pi-image text-blue-600"></i>
                        Card Artwork
                    </h3>
                    
                    <!-- Single-Column Layout -->
                    <div class="space-y-6">
                        <!-- Image Preview Section (Only when image exists) -->
                        <div v-if="previewImage">
                            <div
                                class="card-artwork-container border-2 border-solid border-blue-400 bg-blue-50/30 rounded-xl transition-all duration-200"
                            >
                                <!-- Image with QR Overlay Container -->
                                <div class="relative w-full h-full">
                                    <img
                                        :src="previewImage"
                                        alt="Card Artwork Preview"
                                        class="object-contain h-full w-full rounded-lg shadow-md" 
                                    />
                                    
                                    <!-- Mock QR Code Overlay -->
                                    <div 
                                        v-if="formData.qr_code_position"
                                        class="absolute w-12 h-12 bg-white border-2 border-slate-300 rounded-lg shadow-lg flex items-center justify-center transition-all duration-300"
                                        :class="getQrCodePositionClass(formData.qr_code_position)"
                                    >
                                        <div class="w-8 h-8 bg-slate-800 rounded-sm flex items-center justify-center">
                                            <i class="pi pi-qrcode text-white text-xs"></i>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                        
                        <!-- Upload/Actions Section -->
                        <div class="space-y-4">
                            <!-- Image Requirements Info -->
                            <div v-if="!previewImage" class="p-3 bg-blue-100 rounded-lg">
                                <p class="text-xs text-blue-800 flex items-start gap-2">
                                    <i class="pi pi-info-circle mt-0.5 flex-shrink-0"></i>
                                    <span><strong>Image Requirements:</strong> Upload JPG or PNG files up to 5MB. For best results, use images with a 2:3 aspect ratio (e.g., 800×1200px). You can crop and adjust your image after uploading.</span>
                                </p>
                            </div>
                            
                            <!-- Upload Interface or Action Buttons -->
                            <div>
                                <!-- Upload Drop Zone (LinkedIn Style) - Only when no image -->
                                <div 
                                    v-if="!previewImage"
                                    class="upload-drop-zone"
                                    @dragover.prevent="handleDragOver"
                                    @dragleave.prevent="handleDragLeave"
                                    @drop.prevent="handleDrop"
                                    :class="{ 'drag-active': isDragActive }"
                                >
                                    <div class="upload-content">
                                        <div class="upload-icon-container">
                                            <i class="pi pi-camera upload-icon"></i>
                                        </div>
                                        <h4 class="upload-title">Add a photo</h4>
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
                                            label="Upload photo"
                                            icon="pi pi-upload"
                                            @click="triggerFileInput"
                                            class="upload-trigger-button"
                                            severity="info"
                                        />
                                    </div>
                                </div>
                                
                                <!-- Action Buttons - Only when image exists -->
                                <div v-else class="image-actions-only">
                                    <div class="image-actions">
                                        <Button 
                                            label="Change photo"
                                            icon="pi pi-image"
                                            @click="triggerFileInput"
                                            severity="secondary"
                                            outlined
                                            size="small"
                                            class="action-button"
                                        />
                                        <Button 
                                            label="Edit crop"
                                            icon="pi pi-crop"
                                            @click="handleReCrop"
                                            severity="info"
                                            outlined
                                            size="small"
                                            class="action-button"
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
                            
                            <!-- QR Code Position -->
                            <div class="p-4 bg-slate-50 border border-slate-200 rounded-lg">
                                <h4 class="font-medium text-slate-900 mb-3 flex items-center gap-2">
                                    <i class="pi pi-qrcode text-slate-600"></i>
                                    QR Code Settings
                                </h4>
                                <div>
                                    <label for="qr_code_position" class="block text-sm font-medium text-slate-700 mb-2">Position on Card</label>
                                    <Dropdown 
                                        id="qr_code_position"
                                        v-model="formData.qr_code_position" 
                                        :options="qrCodePositions" 
                                        optionLabel="name" 
                                        optionValue="code" 
                                        placeholder="Select position" 
                                        class="w-full"
                                    />
                                    <p class="text-xs text-slate-500 mt-2 flex items-center gap-1">
                                        <i class="pi pi-eye text-xs"></i>
                                        Preview updates in real-time
                                    </p>
                                </div>
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
                            Card Details
                        </h3>
                        
                        <div class="space-y-4">
                            <div>
                                <label for="cardName" class="block text-sm font-medium text-slate-700 mb-2">Card Name *</label>
                                <InputText 
                                    id="cardName" 
                                    type="text" 
                                    v-model="formData.name" 
                                    class="w-full px-4 py-3 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors"
                                    :class="{ 'border-red-300 focus:ring-red-500 focus:border-red-500': !formData.name.trim() && showValidation }"
                                    placeholder="Enter a descriptive card name"
                                />
                                <p v-if="!formData.name.trim() && showValidation" class="text-sm text-red-600 mt-1">Card name is required</p>
                            </div>

                            <div>
                                <label for="cardDescription" class="block text-sm font-medium text-slate-700 mb-2">
                                    Card Description 
                                    <span class="text-xs text-slate-500 font-normal">(Markdown supported)</span>
                                </label>
                                <div class="border border-slate-300 rounded-lg overflow-hidden">
                                    <MdEditor 
                                        v-model="formData.description"
                                        :toolbars="markdownToolbars"
                                        :preview="true"
                                        :htmlPreview="true"
                                        :codeTheme="'atom'"
                                        :previewTheme="'default'"
                                        placeholder="Describe your card's purpose and content using Markdown..."
                                        :style="{ height: '200px' }"
                                    />
                                </div>
                            </div>

                        </div>
                    </div>
                    
                    <!-- AI Configuration Section -->
                    <div class="p-4 border border-slate-200 rounded-lg">
                        <h4 class="font-medium text-slate-900 mb-3 flex items-center gap-2">
                            <i class="pi pi-brain text-blue-600"></i>
                            AI Assistant Configuration
                        </h4>
                        
                        <!-- AI Toggle -->
                        <div class="flex items-center gap-3 p-4 bg-slate-50 rounded-lg border border-slate-200 mb-4">
                            <ToggleSwitch v-model="formData.conversation_ai_enabled" inputId="ai_enabled" />
                            <div class="flex-1">
                                <label for="ai_enabled" class="block text-sm font-medium text-slate-700">Enable AI Assistant</label>
                                <p class="text-xs text-slate-500">Allow visitors to ask questions about your card content</p>
                            </div>
                            <i class="pi pi-info-circle text-slate-400 cursor-help" 
                               v-tooltip="'AI assistant helps visitors interact with your card content'"></i>
                        </div>

                        <!-- AI Instructions Field (shown when AI is enabled) -->
                        <div v-if="formData.conversation_ai_enabled" class="bg-gradient-to-r from-blue-50 to-indigo-50 border border-blue-200 rounded-lg p-4">
                            <label class="block text-sm font-medium text-blue-900 mb-2 flex items-center gap-2">
                                <i class="pi pi-lightbulb"></i>
                                AI Assistance Instructions
                            </label>
                            <Textarea 
                                v-model="formData.ai_prompt" 
                                rows="4" 
                                class="w-full px-4 py-3 border border-blue-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors resize-none bg-white" 
                                placeholder="Provide instructions for the AI assistant when helping visitors with questions about content items in this card. For example: 'You are an expert travel guide. Help visitors plan their adventures and understand safety requirements.'"
                                autoResize
                            />
                            <div class="mt-3 p-3 bg-blue-100 rounded-lg">
                                <p class="text-xs text-blue-800 flex items-start gap-2">
                                    <i class="pi pi-info-circle mt-0.5 flex-shrink-0"></i>
                                    <span><strong>Instructions:</strong> These instructions will guide the AI when answering questions about any content item in this card. The AI will use these instructions along with the content item's description and metadata to provide helpful responses.</span>
                                </p>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- Image Crop Dialog -->
        <MyDialog
            v-model="showCropDialog"
            header="Crop Image"
            :style="{ width: '90vw', maxWidth: '900px' }"
            :closable="false"
            :showConfirm="true"
            :showCancel="true"
            confirmLabel="Apply"
            cancelLabel="Cancel"
            :confirmHandle="handleCropConfirm"
            @cancel="handleCropCancelled"
        >
            <ImageCropper
                v-if="imageToCrop"
                :imageSrc="imageToCrop"
                :aspectRatio="getCardAspectRatioNumber()"
                :aspectRatioDisplay="getCardAspectRatioDisplay()"
                :cropParameters="cropParameters"
                ref="imageCropperRef"
            />
        </MyDialog>
    </div>
</template>

<script setup>
import { ref, reactive, onMounted, watch, computed, nextTick } from 'vue';
import Button from 'primevue/button';
import InputText from 'primevue/inputtext';
import Textarea from 'primevue/textarea';
import Dropdown from 'primevue/dropdown';
import ToggleSwitch from 'primevue/toggleswitch';
import { processImage } from '@/utils/imageUtils.js';
import { 
    getCardAspectRatio, 
    getCardAspectRatioNumber, 
    getCardAspectRatioDisplay, 
    imageNeedsCropping, 
    getImageDimensions 
} from '@/utils/cardConfig';
import { generateCropPreview } from '@/utils/cropUtils';
import ImageCropper from '@/components/ImageCropper.vue';
import MyDialog from '@/components/MyDialog.vue';
import { MdEditor } from 'md-editor-v3';
import 'md-editor-v3/lib/style.css';

const props = defineProps({
    cardProp: {
        type: Object,
        default: null
    },
    isEditMode: {
        type: Boolean,
        default: false
    },
    isInDialog: {
        type: Boolean,
        default: false
    },
    loading: {
        type: Boolean,
        default: false
    }
});

const emit = defineEmits(['save', 'cancel']);

const formData = reactive({
    id: null,
    name: '',
    description: '',
    qr_code_position: 'BR',
    ai_prompt: '',
    conversation_ai_enabled: false,
    cropParameters: null
});

const previewImage = ref(null);
const imageFile = ref(null); // Original uploaded file (raw)
const croppedImageFile = ref(null); // Cropped image file
const showCropDialog = ref(false);
const imageToCrop = ref(null);
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

const qrCodePositions = ref([
    { name: 'Top Left', code: 'TL' },
    { name: 'Top Right', code: 'TR' },
    { name: 'Bottom Left', code: 'BL' },
    { name: 'Bottom Right', code: 'BR' }
]);

const showValidation = ref(false);

const isFormValid = computed(() => {
    return formData.name.trim().length > 0;
});

// Initialize form data from props
onMounted(() => {
    initializeForm();
    
    // Set up CSS custom property for aspect ratio
    const aspectRatio = getCardAspectRatio();
    document.documentElement.style.setProperty('--card-aspect-ratio', aspectRatio);
});

// Watch for changes in cardProp to update form
watch(() => props.cardProp, (newVal) => {
    if (newVal) {
        initializeForm();
    }
}, { deep: true });

const initializeForm = () => {
    if (props.cardProp) {
        formData.id = props.cardProp.id;
        formData.name = props.cardProp.name || '';
        formData.description = props.cardProp.description || '';
        formData.qr_code_position = props.cardProp.qr_code_position || 'BR';
        formData.ai_prompt = props.cardProp.ai_prompt || '';
        formData.conversation_ai_enabled = props.cardProp.conversation_ai_enabled || false;
        formData.cropParameters = props.cardProp.cropParameters || props.cardProp.crop_parameters || null;
        
        // Set crop parameters if they exist
        if (formData.cropParameters) {
            cropParameters.value = formData.cropParameters;
        }
        
        // For edit mode: Simply display the already-cropped image_url
        // The image_url is the final cropped result, no need to re-generate preview
        if (props.cardProp.image_url) {
            previewImage.value = props.cardProp.image_url;
        } else {
            previewImage.value = null;
        }
        
        // Reset imageFile when initializing from existing card
        imageFile.value = null;
    } else {
        resetForm();
    }
};

const resetForm = () => {
    formData.id = null;
    formData.name = '';
    formData.description = '';
    formData.qr_code_position = 'BR';
    formData.ai_prompt = '';
    formData.conversation_ai_enabled = false;
    formData.cropParameters = null;
    previewImage.value = null;
    imageFile.value = null;
    croppedImageFile.value = null;
    
    // Clean up crop-related variables
    showCropDialog.value = false;
    imageToCrop.value = null;
    cropParameters.value = null;
};

const handleImageUpload = async (event) => {
    const file = event.files[0];
    if (!file) return;

    try {
        // Store the original image file
        imageFile.value = file;
        
        // Get image dimensions to check if cropping is needed
        const dimensions = await getImageDimensions(file);
        const needsCropping = imageNeedsCropping(dimensions.width, dimensions.height);
        
        if (needsCropping) {
            // Store original file and show crop dialog
            imageFile.value = file;
            const reader = new FileReader();
            reader.onload = (e) => {
                imageToCrop.value = e.target.result;
                showCropDialog.value = true;
            };
            reader.readAsDataURL(file);
        } else {
            // Image aspect ratio is correct, use directly
            await processImageDirectly(file);
        }
    } catch (error) {
        console.error("Failed to process image:", error);
    }
};

const processImageDirectly = async (file) => {
    // Store the file object for later upload
    imageFile.value = file;

    // Create a preview URL
    const reader = new FileReader();
    reader.onload = (e) => {
        previewImage.value = e.target.result;
    };
    reader.readAsDataURL(file);
};

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
                formData.cropParameters = cropParams;
                
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
    
    // Close crop dialog
    showCropDialog.value = false;
    
    // Clean up
    imageToCrop.value = null;
};

const handleCropCancelled = () => {
    // Close crop dialog and clean up
    showCropDialog.value = false;
    imageToCrop.value = null;
    imageFile.value = null;
    croppedImageFile.value = null;
};

// Re-crop existing image
const handleReCrop = () => {
    // Priority: imageFile (new upload) > original_image_url (saved) > image_url (fallback for old data)
    const originalImage = imageFile.value || props.cardProp?.original_image_url || props.cardProp?.image_url;
    
    if (originalImage) {
        // Use the original image file or URL
        const imageSrc = imageFile.value ? URL.createObjectURL(imageFile.value) : originalImage;
        imageToCrop.value = imageSrc;
        
        // Set existing crop parameters to restore previous crop state
        if (formData.cropParameters || props.cardProp?.crop_parameters) {
            cropParameters.value = formData.cropParameters || props.cardProp.crop_parameters;
        } else {
            cropParameters.value = null; // Start with fresh crop
        }
        
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
        // You might want to add a toast notification here
        console.error('File size exceeds 5MB limit');
        return;
    }
    
    // Store the file
    imageFile.value = file;
    
    // Create preview URL
    const previewUrl = URL.createObjectURL(file);
    
    // LinkedIn-style: Immediately open crop dialog after upload
    imageToCrop.value = previewUrl;
    cropParameters.value = null; // Start fresh
    showCropDialog.value = true;
};


const getPayload = () => {
    const payload = { ...formData };
    
    // Ensure QR code position is valid
    if (!['TL', 'TR', 'BL', 'BR'].includes(payload.qr_code_position)) {
        payload.qr_code_position = 'BR'; // Default to Bottom Right if invalid
    }
    
    // Add original image file if it exists
    if (imageFile.value) {
        payload.imageFile = imageFile.value;
    }
    
    // Add cropped image file if it exists
    if (croppedImageFile.value) {
        payload.croppedImageFile = croppedImageFile.value;
    }
    
    // Add image URLs from props if available and no new image is being uploaded
    if (!imageFile.value && props.cardProp) {
        if (props.cardProp.image_url) {
            payload.image_url = props.cardProp.image_url;
        }
        if (props.cardProp.original_image_url) {
            payload.original_image_url = props.cardProp.original_image_url;
        }
    }
    
    // Add crop parameters if they exist
    if (cropParameters.value) {
        payload.cropParameters = cropParameters.value;
    }
    
    return payload;
};

const handleSave = () => {
    showValidation.value = true;
    if (isFormValid.value) {
        emit('save', getPayload());
        showValidation.value = false;
    }
};

const handleCancel = () => {
    emit('cancel');
    initializeForm(); // Reset form to original values
};

const getQrCodePositionClass = (position) => {
    switch (position) {
        case 'TL':
            return 'qr-position-tl';
        case 'TR':
            return 'qr-position-tr';
        case 'BL':
            return 'qr-position-bl';
        case 'BR':
            return 'qr-position-br';
        default:
            return 'qr-position-br'; // Default to bottom-right
    }
};

defineExpose({
    resetForm,
    getPayload,
    initializeForm
});
</script>

<style scoped>
/* Responsive container with configurable aspect ratio */
.card-artwork-container {
    aspect-ratio: var(--card-aspect-ratio, 2/3);
    width: 100%;
    max-width: 300px; /* Increased from 240px for better preview */
    margin: 0 auto;
    position: relative;
    transition: all 0.3s ease;
}

/* Component-specific styles */
.card-artwork-container img {
    /* object-fit is set in the template (object-contain) */
    transition: all 0.2s ease-in-out;
}

.card-artwork-container:hover img {
    transform: scale(1.01); /* Reduced from 1.02 for subtler effect */
}

.qr-position-tl { top: 8px; left: 8px; }
.qr-position-tr { top: 8px; right: 8px; }
.qr-position-bl { bottom: 8px; left: 8px; }
.qr-position-br { bottom: 8px; right: 8px; }

/* LinkedIn-Style Upload Drop Zone */
.upload-drop-zone {
    border: 2px dashed #cbd5e1;
    border-radius: 12px;
    padding: 40px 20px;
    text-align: center;
    background: #fefefe;
    transition: all 0.3s ease;
    cursor: pointer;
    position: relative;
    overflow: hidden;
}

.upload-drop-zone:hover {
    border-color: #3b82f6;
    background: #f8faff;
    transform: translateY(-2px);
    box-shadow: 0 8px 25px rgba(59, 130, 246, 0.15);
}

.upload-drop-zone.drag-active {
    border-color: #2563eb;
    background: #eff6ff;
    transform: scale(1.02);
    box-shadow: 0 12px 30px rgba(59, 130, 246, 0.25);
}

.upload-content {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 16px;
}

.upload-icon-container {
    width: 64px;
    height: 64px;
    background: linear-gradient(135deg, #e0f2fe 0%, #b3e5fc 100%);
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
    margin-bottom: 8px;
}

.upload-icon {
    font-size: 28px;
    color: #0277bd;
}

.upload-title {
    font-size: 18px;
    font-weight: 600;
    color: #1e293b;
    margin: 0;
}

.upload-subtitle {
    font-size: 14px;
    color: #64748b;
    margin: 0;
}

.upload-trigger-button {
    margin-top: 8px;
    padding: 10px 20px;
    font-weight: 500;
}

/* Action Buttons Container (when image exists) */
.image-actions-only {
    display: flex;
    flex-direction: column;
    gap: 12px;
}

/* LinkedIn-Style Action Buttons */
.image-actions {
    display: flex;
    gap: 8px;
    flex-wrap: wrap;
    justify-content: center;
}

.action-button {
    font-weight: 500;
    border-radius: 6px;
    transition: all 0.2s ease;
    min-width: 100px;
}

.action-button:hover {
    transform: translateY(-1px);
    box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);
}

</style>
