<template>
    <div>
        <!-- Action Buttons -->
        <div class="flex justify-end gap-2 mb-2" v-if="isEditMode">
            <Button 
                label="Cancel" 
                icon="pi pi-times" 
                severity="secondary" 
                @click="handleCancel" 
            />
            <Button 
                label="Save Changes" 
                icon="pi pi-save" 
                severity="success"
                @click="handleSave" 
            />
        </div>
            
        <div class="2xl:flex">
            <!-- Artwork Section -->
            <div class="mb-6 2xl:mb-0 2xl:mr-8">
                <div class="font-semibold mb-2">Card Artwork</div>
                <div class="w-60"> 
                    <div
                        class="h-90 border border-gray-300 rounded-md p-2 relative mb-4"
                        :class="{ 'border-dashed': !previewImage }"
                    >
                        <img
                            :src="previewImage || cardPlaceholder"
                            alt="Card Artwork Preview"
                            class="object-cover h-full w-full rounded" 
                        />
                        <div v-if="!previewImage" class="absolute inset-0 flex items-center justify-center text-gray-500 text-center p-2">
                            Click below to upload
                        </div>
                    </div>
                    <FileUpload
                        mode="basic"
                        name="artworkUpload"
                        accept="image/*"
                        :maxFileSize="1000000"
                        chooseLabel="Upload Artwork"
                        chooseIcon="pi pi-upload"
                        @select="handleImageUpload"
                        :auto="false"
                        customUpload
                        class="w-full p-button-primary"
                    />
                </div>
            </div>
            
            <!-- Form Fields Section -->
            <div class="w-full">
                <div class="mb-4">
                    <label for="cardName" class="font-semibold block mb-1">Card Name</label>
                    <InputText id="cardName" type="text" v-model="formData.name" class="w-full"/>
                </div>

                <div class="mb-4">
                    <label for="cardDescription" class="font-semibold block mb-1">Card Description</label>
                    <Textarea id="cardDescription" v-model="formData.description" rows="5" class="w-full"/>
                </div>

                <div class="mb-4">
                    <label for="qrCodePosition" class="font-semibold block mb-1">QR Code Position</label>
                    <Dropdown 
                        id="qrCodePosition"
                        v-model="formData.qrCodePosition" 
                        :options="qrCodePositions" 
                        optionLabel="name" 
                        optionValue="code" 
                        placeholder="Select QR code position" 
                        class="w-full" 
                    />
                </div>
                
                <div class="flex items-center mb-4 mt-6">
                    <ToggleSwitch v-model="formData.conversationAiEnabled" inputId="conversationAiEnabled" />
                    <label for="conversationAiEnabled" class="ml-2 font-semibold">Enable Conversation AI</label>
                </div>

                <div class="mb-4" v-if="formData.conversationAiEnabled">
                    <label for="aiPrompt" class="font-semibold block mb-1">AI Prompt</label>
                    <Textarea 
                        id="aiPrompt" 
                        v-model="formData.aiPrompt" 
                        rows="5" 
                        class="w-full"
                        placeholder="Enter instructions for the AI when responding to users about this card"
                    />
                </div>

                <div class="flex items-center mb-6">
                    <ToggleSwitch v-model="formData.published" inputId="published" />
                    <label for="published" class="ml-2 font-semibold">Published</label>
                </div>
            </div>
        </div>
    </div>
</template>

<script setup>
import { ref, reactive, onMounted, watch } from 'vue';
import Button from 'primevue/button';
import InputText from 'primevue/inputtext';
import Textarea from 'primevue/textarea';
import Dropdown from 'primevue/dropdown';
import ToggleSwitch from 'primevue/toggleswitch';
import FileUpload from 'primevue/fileupload';
import cardPlaceholder from '@/assets/images/card-placeholder.svg';

const props = defineProps({
    cardProp: {
        type: Object,
        default: null
    },
    isEditMode: {
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
    emit('save', getPayload());
};

const handleCancel = () => {
    emit('cancel');
    initializeForm(); // Reset form to original values
};

defineExpose({
    resetForm,
    getPayload
});
</script>

<style scoped>
.h-90 {
    height: 22.5rem;
}
.w-60 {
    width: 15rem;
}
.p-fileupload-basic .p-button {
    width: 100%;
    justify-content: center;
}
</style>
