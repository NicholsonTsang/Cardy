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
                severity="success"
                class="px-4 py-2 shadow-lg hover:shadow-xl transition-shadow"
                :disabled="!isFormValid"
                @click="handleSave" 
            />
        </div>
            
        <div class="grid grid-cols-1 xl:grid-cols-3 gap-6">
            <!-- Artwork Section -->
            <div class="xl:col-span-1">
                <div class="bg-white rounded-xl shadow-lg border border-slate-200 p-6">
                    <h3 class="text-lg font-semibold text-slate-900 mb-4 flex items-center gap-2">
                        <i class="pi pi-image text-blue-600"></i>
                        Card Artwork
                    </h3>
                    <div class="w-full"> 
                        <div
                            class="card-artwork-container border-2 border-dashed border-slate-300 rounded-xl p-4 relative mb-4 transition-all duration-200 hover:border-blue-400 hover:bg-blue-50/50"
                            :class="{ 
                                'border-solid border-blue-400 bg-blue-50/30': previewImage,
                                'bg-slate-50': !previewImage 
                            }"
                        >
                            <img
                                v-if="previewImage"
                                :src="previewImage"
                                alt="Card Artwork Preview"
                                class="object-cover h-full w-full rounded-lg shadow-md" 
                            />
                            <div v-else class="absolute inset-0 flex flex-col items-center justify-center text-slate-500 text-center p-4">
                                <i class="pi pi-image text-3xl mb-3 opacity-50"></i>
                                <span class="text-sm font-medium">Upload artwork</span>
                                <span class="text-xs text-slate-400 mt-1">Drag & drop or click to browse</span>
                            </div>
                            
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
                        <FileUpload
                            mode="basic"
                            name="artworkUpload"
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
                            Max: 5MB • Recommended ratio: 3:4
                        </p>
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
                                <label for="cardDescription" class="block text-sm font-medium text-slate-700 mb-2">Card Description</label>
                                <Textarea 
                                    id="cardDescription" 
                                    v-model="formData.description" 
                                    rows="3" 
                                    class="w-full px-4 py-3 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors resize-none"
                                    placeholder="Describe your card's purpose and content..."
                                    autoResize
                                />
                            </div>

                            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                                <div>
                                    <label for="qr_code_position" class="block text-sm font-medium text-slate-700 mb-2">QR Code Position</label>
                                    <Dropdown 
                                        id="qr_code_position"
                                        v-model="formData.qr_code_position" 
                                        :options="qrCodePositions" 
                                        optionLabel="name" 
                                        optionValue="code" 
                                        placeholder="Select position" 
                                        class="w-full"
                                    />
                                </div>
                                
                                <div class="flex items-center gap-3 p-4 bg-slate-50 rounded-lg border border-slate-200">
                                    <ToggleSwitch v-model="formData.published" inputId="published" />
                                    <div class="flex-1">
                                        <label for="published" class="block text-sm font-medium text-slate-700">Published</label>
                                        <p class="text-xs text-slate-500">Make this card visible to users</p>
                                    </div>
                                    <i class="pi pi-info-circle text-slate-400 cursor-help" 
                                       v-tooltip="'Published cards are visible to users'"></i>
                                </div>
                            </div>
                        </div>
                    </div>
                    
                    <!-- AI Configuration Section -->
                    <div class="border-t border-slate-200 pt-6">
                        <div class="flex items-center justify-between mb-4">
                            <div>
                                <h3 class="text-lg font-semibold text-slate-900 flex items-center gap-2">
                                    <i class="pi pi-robot text-blue-600"></i>
                                    AI Assistant Configuration
                                </h3>
                                <p class="text-sm text-slate-600 mt-1">Enable AI assistance for content item questions and provide instructions</p>
                            </div>
                            <ToggleSwitch 
                                v-model="formData.conversation_ai_enabled" 
                                class="ml-4"
                            />
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
    </div>
</template>

<script setup>
import { ref, reactive, onMounted, watch, computed } from 'vue';
import Button from 'primevue/button';
import InputText from 'primevue/inputtext';
import Textarea from 'primevue/textarea';
import Dropdown from 'primevue/dropdown';
import ToggleSwitch from 'primevue/toggleswitch';
import FileUpload from 'primevue/fileupload';
import { processImage } from '@/utils/imageUtils.js';

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
    }
});

const emit = defineEmits(['save', 'cancel']);

const formData = reactive({
    id: null,
    name: '',
    description: '',
    qr_code_position: 'BR',
    ai_prompt: '',
    published: false,
    conversation_ai_enabled: false
});

const previewImage = ref(null);
const imageFile = ref(null);

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
        formData.published = props.cardProp.published || false;
        formData.conversation_ai_enabled = props.cardProp.conversation_ai_enabled || false;
        
        // Set preview image if available
        if (props.cardProp.image_urls && props.cardProp.image_urls.length > 0) {
            previewImage.value = props.cardProp.image_urls[0];
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
    formData.published = false;
    formData.conversation_ai_enabled = false;
    previewImage.value = null;
    imageFile.value = null;
};

const handleImageUpload = async (event) => {
    const file = event.files[0];
    if (!file) return;

    try {
        // Store the file object for later upload
        imageFile.value = file;

        // Create a preview URL
        const reader = new FileReader();
        reader.onload = (e) => {
            previewImage.value = e.target.result;
        };
        reader.readAsDataURL(file);
    } catch (error) {
        console.error("Failed to process image:", error);
    }
};

const getPayload = () => {
    const payload = { ...formData };
    
    // Ensure QR code position is valid
    if (!['TL', 'TR', 'BL', 'BR'].includes(payload.qr_code_position)) {
        payload.qr_code_position = 'BR'; // Default to Bottom Right if invalid
    }
    
    // Only add imageFile if it exists
    if (imageFile.value) {
        payload.imageFile = imageFile.value;
    }
    
    // Add image_urls from props if available and no new image is being uploaded
    if (!imageFile.value && props.cardProp && props.cardProp.image_urls) {
        payload.image_urls = props.cardProp.image_urls;
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
            return 'left-2 top-2';
        case 'TR':
            return 'right-2 top-2';
        case 'BL':
            return 'left-2 bottom-2';
        case 'BR':
            return 'right-2 bottom-2';
        default:
            return 'right-2 bottom-2'; // Default to bottom-right
    }
};

defineExpose({
    resetForm,
    getPayload,
    initializeForm
});
</script>

<style scoped>
/* Fixed height container with 3:4 aspect ratio */
.card-artwork-container {
    height: 320px; /* 80 * 4 = 320px (h-80) */
    width: 240px;   /* 60 * 4 = 240px (w-60) */
    aspect-ratio: 3/4;
    margin: 0 auto;
}

/* Responsive adjustments for smaller screens */
@media (max-width: 640px) {
    .card-artwork-container {
        height: 280px; /* Slightly smaller on mobile */
        width: 210px;
    }
}

@media (max-width: 480px) {
    .card-artwork-container {
        height: 240px; /* Even smaller on very small screens */
        width: 180px;
    }
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

:deep(.p-dropdown) {
    font-size: 0.75rem;
}

:deep(.p-dropdown-label) {
    font-size: 0.75rem;
    padding: 0.25rem 0.5rem;
}

:deep(.p-fileupload-basic .p-button) {
    font-size: 0.75rem;
    padding: 0.25rem 0.5rem;
    width: 100%;
    justify-content: center;
}

:deep(.p-button) {
    font-size: 0.75rem;
}
</style>
