<template>
    <div>
        <!-- VIEW MODE -->
        <div v-if="currentMode === 'view'">
            <div class="mb-2 flex justify-end gap-2" v-if="cardProp">
                <Button label="Edit Card" icon="pi pi-pencil" @click="switchToEditMode" severity="info" />
                <Button label="Delete Card" icon="pi pi-trash" @click="handleRequestDelete" severity="danger" />
            </div>

            <div v-if="cardProp" class="p-4 border border-gray-200 rounded-lg flex flex-col 2xl:flex-row">
                <!-- Artwork Display -->
                <div class="mb-4 mr-8">
                        <div class="font-semibold mb-2 text-gray-700">Card Artwork</div>
                        <img
                            :src="displayImageForView"
                            alt="Card Artwork"
                            class="w-60 h-auto object-cover rounded-md border border-gray-300 aspect-[3/4]"
                        />
                    </div>

                    <!-- Details Display -->
                    <div>
                        <div class="mb-4">
                            <div class="font-semibold text-gray-700">Card Name</div>
                            <p class="text-gray-600">{{ cardProp.name || 'N/A' }}</p>
                        </div>

                        <div class="mb-4">
                            <div class="font-semibold text-gray-700">Description</div>
                            <p class="text-gray-600 whitespace-pre-wrap">{{ cardProp.description || 'No description provided.' }}</p>
                        </div>

                        <div class="mb-4">
                            <div class="font-semibold text-gray-700">QR Code Position</div>
                            <p class="text-gray-600">{{ displayQrCodePositionForView || 'N/A' }}</p>
                        </div>
                        
                        <div class="mb-4">
                            <div class="font-semibold text-gray-700">Conversation AI Enabled</div>
                            <p class="text-gray-600">{{ cardProp.conversation_ai_enabled ? 'Yes' : 'No' }}</p>
                        </div>

                        <div class="mb-4">
                            <div class="font-semibold text-gray-700">Published</div>
                            <p class="text-gray-600">{{ cardProp.published ? 'Yes' : 'No' }}</p>
                        </div>

                        <div v-if="cardProp.created_at" class="mb-4">
                            <div class="font-semibold text-gray-700">Created At</div>
                            <p class="text-gray-600">{{ new Date(cardProp.created_at).toLocaleString() }}</p>
                        </div>

                        <div v-if="cardProp.updated_at" class="mb-4">
                            <div class="font-semibold text-gray-700">Last Updated</div>
                            <p class="text-gray-600">{{ new Date(cardProp.updated_at).toLocaleString() }}</p>
                        </div>
                    </div>
            </div>
            <div v-else class="p-4 text-gray-500">No card data to display.</div>
        </div>

        <!-- CREATE OR EDIT MODE -->
        <div v-else>
            <!-- Action Buttons -->
            <div class="flex justify-end gap-2 mb-2">
                    <Button 
                        v-if="currentMode === 'edit'" 
                        label="Cancel" 
                        icon="pi pi-times" 
                        severity="secondary" 
                        @click="handleCancelEdit" 
                    />
                    <Button 
                        v-if="currentMode === 'edit'" 
                        label="Save Changes" 
                        icon="pi pi-save" 
                        severity="success"
                        @click="handleUpdate" 
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
                    <Select 
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

                <div class="flex items-center mb-6">
                    <ToggleSwitch v-model="formData.published" inputId="published" />
                    <label for="published" class="ml-2 font-semibold">Published</label>
                </div>
            </div>
                </div>
            
        </div>
    </div>
</template>

<script setup>
import { ref, reactive, watch, onMounted, computed } from 'vue';
import InputText from 'primevue/inputtext';
import Textarea from 'primevue/textarea';
import ToggleSwitch from 'primevue/toggleswitch';
import Select from 'primevue/select';
import FileUpload from 'primevue/fileupload';
import Button from 'primevue/button';
import cardPlaceholder from '@/assets/images/card-placeholder.jpg';
import { processImage } from '@/utils/imageUtils'; // Adjust path if needed

const props = defineProps({
    modeProp: {
        type: String,
        default: 'create', // 'create', 'edit', 'view'
        validator: (value) => ['create', 'edit', 'view'].includes(value)
    },
    cardProp: {
        type: Object,
        default: () => null
    }
});

const emit = defineEmits(['create-card', 'update-card', 'cancel-edit', 'request-delete-card']);

const currentMode = ref(props.modeProp);
const imageFile = ref(null); // Stores the File object for new uploads
const previewImage = ref(null); // Stores the URL for image preview

// Reactive form data object
const formData = reactive({
    id: null, // Important for updates
    name: '',
    description: '',
    qrCodePosition: 'BR', // Default QR position
    conversationAiEnabled: false,
    published: false,
    // image_urls will be handled separately for preview and upload
});

// To store a deep copy of the original card data for cancellation in edit mode
let originalCardDataForEdit = null; 

const qrCodePositions = ref([
    { name: 'Top Left', code: 'TL' },
    { name: 'Top Right', code: 'TR' },
    { name: 'Bottom Left', code: 'BL' },
    { name: 'Bottom Right', code: 'BR' }
]);

// For View Mode Display
const qrCodePositionMap = {
    'TL': 'Top Left',
    'TR': 'Top Right',
    'BL': 'Bottom Left',
    'BR': 'Bottom Right'
};

const displayImageForView = computed(() => {
    return props.cardProp?.image_urls && props.cardProp.image_urls.length > 0
        ? props.cardProp.image_urls[0]
        : cardPlaceholder;
});

const displayQrCodePositionForView = computed(() => {
    return props.cardProp?.qr_code_position
        ? qrCodePositionMap[props.cardProp.qr_code_position] || props.cardProp.qr_code_position
        : 'N/A';
});

const initializeForm = () => {
    if ((props.modeProp === 'edit' || props.modeProp === 'view') && props.cardProp) {
        formData.id = props.cardProp.id;
        formData.name = props.cardProp.name || '';
        formData.description = props.cardProp.description || '';
        formData.qrCodePosition = props.cardProp.qr_code_position || 'BR';
        formData.conversationAiEnabled = props.cardProp.conversation_ai_enabled || false;
        formData.published = props.cardProp.published || false;
        
        if (props.cardProp.image_urls && props.cardProp.image_urls.length > 0) {
            previewImage.value = props.cardProp.image_urls[0];
        } else {
            previewImage.value = null;
        }
        imageFile.value = null; // Reset any staged file

        // Store original data for potential cancellation in edit mode
        if (props.modeProp === 'edit') {
            originalCardDataForEdit = JSON.parse(JSON.stringify(props.cardProp)); // Deep copy
        }

    } else { // Create mode or no cardProp
        formData.id = null;
        formData.name = '';
        formData.description = '';
        formData.qrCodePosition = 'BR';
        formData.conversationAiEnabled = false;
        formData.published = false;
        previewImage.value = null;
        imageFile.value = null;
        originalCardDataForEdit = null;
    }
};

onMounted(() => {
    currentMode.value = props.modeProp;
    initializeForm();
});

watch(() => props.modeProp, (newMode) => {
    currentMode.value = newMode;
    initializeForm(); // Re-initialize form when mode changes externally
});

watch(() => props.cardProp, (newCard) => {
    initializeForm(); // Re-initialize form if card data changes externally
}, { deep: true });


const handleImageUpload = async (event) => {
    const originalFile = event.files[0];
    if (!originalFile) return;

    try {
        // Process the image, default 500KB limit
        const processedFile = await processImage(originalFile);
        // Or with a custom limit, e.g., 300KB
        // const processedFile = await processImage(originalFile, 300);
        // Or with custom options
        // const processedFile = await processImage(originalFile, 500, { maxWidthOrHeight: 1024 });


        imageFile.value = processedFile; // This is now the potentially compressed file

        if (processedFile) {
            const reader = new FileReader();
            reader.onload = (e) => {
                previewImage.value = e.target.result;
            };
            reader.readAsDataURL(processedFile);
        }
    } catch (error) {
        console.error("Failed to process image:", error);
        // Handle error, e.g., show a toast message to the user
        // You might want to set imageFile.value = originalFile or null depending on desired behavior
        toast.add({ severity: 'error', summary: 'Image Error', detail: 'Could not process image. Please try a different one.', life: 3000 });

        // Fallback to previewing the original file if processing failed but you still want to show something
        // This part depends on how you want to handle the UX on error
        if (originalFile) {
             const reader = new FileReader();
             reader.onload = (e) => {
                 previewImage.value = e.target.result;
             };
             reader.readAsDataURL(originalFile);
             imageFile.value = originalFile; // Or null if you don't want to use the unprocessed large file
        }
    }
};

const getPayload = () => {
    const payload = { ...formData };
    if (imageFile.value) {
        payload.imageFile = imageFile.value;
    }
    // Delete id from payload if it's a create operation, as it's null
    if (currentMode.value === 'create' && payload.id === null) {
        delete payload.id;
    }
    return payload;
};

const switchToEditMode = () => {
    currentMode.value = 'edit';
    initializeForm(); // Ensure form is populated with current cardProp for editing
};

const handleUpdate = () => {
    emit('update-card', getPayload());
    // Parent component should handle success/failure. On success, parent might switch mode to 'view'.
    // For now, let's assume parent handles mode switch.
    // Or, we can switch to view mode here optimistically or upon successful emit callback.
    // currentMode.value = 'view'; // Example: switch to view after emitting
};

const handleCancelEdit = () => {
    if (originalCardDataForEdit) {
        // Restore form data from the original deep copy
        formData.id = originalCardDataForEdit.id;
        formData.name = originalCardDataForEdit.name || '';
        formData.description = originalCardDataForEdit.description || '';
        formData.qrCodePosition = originalCardDataForEdit.qr_code_position || 'BR';
        formData.conversationAiEnabled = originalCardDataForEdit.conversation_ai_enabled || false;
        formData.published = originalCardDataForEdit.published || false;
        
        if (originalCardDataForEdit.image_urls && originalCardDataForEdit.image_urls.length > 0) {
            previewImage.value = originalCardDataForEdit.image_urls[0];
        } else {
            previewImage.value = null;
        }
        imageFile.value = null; // Clear any staged file
    }
    currentMode.value = 'view';
    emit('cancel-edit');
};

const handleRequestDelete = () => {
    if (props.cardProp && props.cardProp.id) {
        emit('request-delete-card', props.cardProp.id);
    }
};

// Expose methods if needed by parent, though emits are preferred for actions
// defineExpose({ getFormData: getPayload });

// Public method to reset the form, e.g., after successful creation by parent
const resetFormForCreate = () => {
    formData.id = null;
    formData.name = '';
    formData.description = '';
    formData.qrCodePosition = 'BR';
    formData.conversationAiEnabled = false;
    formData.published = false;
    previewImage.value = null;
    imageFile.value = null;
    originalCardDataForEdit = null;
    currentMode.value = 'create'; // Ensure mode is also reset if called externally
};

defineExpose({
    resetFormForCreate,
    getPayload
});

</script>

<style scoped>
/* Ensure consistent height for image preview area */
.h-90 { /* You might need to define this class if not already in Tailwind config or global styles */
    height: 22.5rem; /* Example: 90 * 0.25rem if your spacing unit is 0.25rem */
}
.w-60 {
    width: 15rem;
}
/* Optional: Customize FileUpload button appearance if needed */
.p-fileupload-basic .p-button {
    width: 100%;
    justify-content: center;
}
.aspect-\[3\/4\] { /* Added from CardGeneral */
    aspect-ratio: 3 / 4;
}

.view-section {
    display: flex;
    flex-direction: column;

    @container (min-width: 100px) {
        flex-direction: row;
    }
}

</style>
