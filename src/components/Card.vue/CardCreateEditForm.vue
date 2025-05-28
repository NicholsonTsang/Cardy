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
                            class="aspect-[3/4] border-2 border-dashed border-slate-300 rounded-xl p-4 relative mb-4 transition-all duration-200 hover:border-blue-400 hover:bg-blue-50/50"
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
                                    <label for="qrCodePosition" class="block text-sm font-medium text-slate-700 mb-2">QR Code Position</label>
                                    <Dropdown 
                                        id="qrCodePosition"
                                        v-model="formData.qrCodePosition" 
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
                        <div class="flex items-center gap-3 p-4 bg-gradient-to-r from-blue-50 to-indigo-50 rounded-lg border border-blue-200 mb-4">
                            <ToggleSwitch v-model="formData.conversationAiEnabled" inputId="conversationAiEnabled" />
                            <div class="flex-1">
                                <label for="conversationAiEnabled" class="block text-sm font-medium text-blue-900 flex items-center gap-2">
                                    <i class="pi pi-robot"></i>
                                    Enable AI Assistant
                                </label>
                                <p class="text-xs text-blue-700">Allow AI-powered conversations about this card</p>
                            </div>
                            <i class="pi pi-info-circle text-blue-400 cursor-help" 
                               v-tooltip="'AI will help users learn about this card through conversations'"></i>
                        </div>

                        <div v-if="formData.conversationAiEnabled" class="bg-gradient-to-r from-amber-50 to-orange-50 rounded-lg border border-amber-200 p-4">
                            <label for="aiPrompt" class="block text-sm font-medium text-amber-900 mb-2 flex items-center gap-2">
                                <i class="pi pi-microphone"></i>
                                AI Conversation Instructions
                            </label>
                            <Textarea 
                                id="aiPrompt" 
                                v-model="formData.aiPrompt" 
                                rows="4" 
                                class="w-full px-4 py-3 border border-amber-300 rounded-lg focus:ring-2 focus:ring-amber-500 focus:border-amber-500 transition-colors resize-none bg-white"
                                placeholder="Provide detailed instructions for the AI when users ask about this card. Be specific about the card's purpose, key features, and how the AI should respond to questions..."
                                autoResize
                            />
                            <div class="mt-3 p-3 bg-amber-100 rounded-lg">
                                <p class="text-xs text-amber-800 flex items-start gap-2">
                                    <i class="pi pi-lightbulb mt-0.5 flex-shrink-0"></i>
                                    <span><strong>Tip:</strong> Be specific about the card's purpose, historical context, and key features. The AI will use this to provide engaging and informative responses to visitor questions.</span>
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
    qrCodePosition: 'BR',
    conversationAiEnabled: false,
    aiPrompt: '',
    published: false
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
        formData.qrCodePosition = props.cardProp.qr_code_position || 'BR';
        formData.conversationAiEnabled = props.cardProp.conversation_ai_enabled || false;
        formData.aiPrompt = props.cardProp.ai_prompt || '';
        formData.published = props.cardProp.published || false;
        
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
    formData.qrCodePosition = 'BR';
    formData.conversationAiEnabled = false;
    formData.aiPrompt = '';
    formData.published = false;
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
    if (!['TL', 'TR', 'BL', 'BR'].includes(payload.qrCodePosition)) {
        payload.qrCodePosition = 'BR'; // Default to Bottom Right if invalid
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

defineExpose({
    resetForm,
    getPayload,
    initializeForm
});
</script>

<style scoped>
.aspect-\[3\/4\] {
    aspect-ratio: 3 / 4;
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
