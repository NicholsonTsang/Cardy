<template>
    <div class="space-y-6">
        <!-- Action Bar -->
        <div class="flex justify-between items-center" v-if="cardProp">
            <div class="flex items-center gap-3">
                <!-- Remove the publishing tag -->
            </div>
            <div class="flex gap-3">
                <Button 
                    label="Edit Card" 
                    icon="pi pi-pencil" 
                    @click="handleEdit" 
                    severity="info" 
                    class="px-4 py-2 shadow-lg hover:shadow-xl transition-shadow"
                />
                <Button 
                    label="Delete" 
                    icon="pi pi-trash" 
                    @click="handleRequestDelete" 
                    severity="danger" 
                    outlined
                    class="px-4 py-2"
                />
            </div>
        </div>

        <!-- Card Content -->
        <div v-if="cardProp" class="bg-white rounded-xl shadow-lg border border-slate-200 overflow-hidden">
            <div class="p-6">
                <div class="grid grid-cols-1 xl:grid-cols-3 gap-6">
                    <!-- Artwork Display -->
                    <div class="xl:col-span-1">
                        <div class="bg-slate-50 rounded-xl p-6">
                            <h3 class="text-lg font-semibold text-slate-900 mb-4 flex items-center gap-2">
                                <i class="pi pi-image text-blue-600"></i>
                                Card Artwork
                            </h3>
                            <div class="card-artwork-container relative">
                                <img
                                    :src="displayImageForView || cardPlaceholder"
                                    alt="Card Artwork"
                                    class="w-full h-full object-cover rounded-lg border border-slate-200 shadow-md"
                                />
                                <div v-if="!displayImageForView" 
                                     class="absolute inset-0 flex items-center justify-center bg-slate-100 rounded-lg">
                                    <div class="text-center text-slate-400">
                                        <i class="pi pi-image text-3xl mb-3"></i>
                                        <p class="text-sm font-medium">No artwork uploaded</p>
                                    </div>
                                </div>
                                
                                <!-- Mock QR Code Overlay -->
                                <div 
                                    v-if="cardProp && cardProp.qr_code_position"
                                    class="absolute w-12 h-12 bg-white border-2 border-slate-300 rounded-lg shadow-lg flex items-center justify-center"
                                    :class="getQrCodePositionClass(cardProp.qr_code_position)"
                                >
                                    <div class="w-8 h-8 bg-slate-800 rounded-sm flex items-center justify-center">
                                        <i class="pi pi-qrcode text-white text-xs"></i>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- Details Display -->
                    <div class="xl:col-span-2 space-y-6">
                        <!-- Basic Info -->
                        <div class="bg-slate-50 rounded-xl p-6">
                            <h3 class="text-lg font-semibold text-slate-900 mb-4 flex items-center gap-2">
                                <i class="pi pi-info-circle text-blue-600"></i>
                                Basic Information
                            </h3>
                            <div class="space-y-4">
                                <div>
                                    <h4 class="text-sm font-medium text-slate-700 mb-2">Card Name</h4>
                                    <p class="text-base text-slate-900 font-medium">{{ cardProp.name || 'Untitled Card' }}</p>
                                </div>

                                <div v-if="cardProp.description">
                                    <h4 class="text-sm font-medium text-slate-700 mb-2">Description</h4>
                                    <p class="text-sm text-slate-600 whitespace-pre-wrap leading-relaxed">{{ cardProp.description }}</p>
                                </div>
                            </div>
                        </div>

                        <!-- Technical Details -->
                        <div class="bg-slate-50 rounded-xl p-6">
                            <h3 class="text-lg font-semibold text-slate-900 mb-4 flex items-center gap-2">
                                <i class="pi pi-cog text-blue-600"></i>
                                Configuration
                            </h3>
                            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                                <div class="bg-white rounded-lg p-4 border border-slate-200">
                                    <h4 class="text-sm font-medium text-slate-700 mb-2 flex items-center gap-2">
                                        <i class="pi pi-qrcode text-slate-500"></i>
                                        QR Code Position
                                    </h4>
                                    <p class="text-sm text-slate-600">{{ displayQrCodePositionForView || 'Not set' }}</p>
                                </div>
                            </div>
                        </div>

                        <!-- AI Configuration -->
                        <div v-if="cardProp.ai_prompt" 
                             class="bg-gradient-to-r from-amber-50 to-orange-50 rounded-xl p-6 border border-amber-200">
                            <h3 class="text-lg font-semibold text-amber-900 mb-4 flex items-center gap-2">
                                <i class="pi pi-microphone text-amber-600"></i>
                                AI Assistance Instructions
                            </h3>
                            <div class="bg-white rounded-lg p-4 border border-amber-200">
                                <p class="text-sm text-amber-800 whitespace-pre-wrap leading-relaxed">{{ cardProp.ai_prompt }}</p>
                            </div>
                            <div class="mt-3 p-3 bg-amber-100 rounded-lg">
                                <p class="text-xs text-amber-800 flex items-center gap-2">
                                    <i class="pi pi-info-circle"></i>
                                    <span>These instructions guide AI assistance for content items in this card.</span>
                                </p>
                            </div>
                        </div>

                        <!-- Metadata -->
                        <div class="bg-slate-50 rounded-xl p-6">
                            <h3 class="text-lg font-semibold text-slate-900 mb-4 flex items-center gap-2">
                                <i class="pi pi-calendar text-blue-600"></i>
                                Metadata
                            </h3>
                            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                                <div v-if="cardProp.created_at" class="bg-white rounded-lg p-4 border border-slate-200">
                                    <h4 class="text-sm font-medium text-slate-700 mb-2">Created</h4>
                                    <p class="text-sm text-slate-600">{{ formatDate(cardProp.created_at) }}</p>
                                </div>

                                <div v-if="cardProp.updated_at" class="bg-white rounded-lg p-4 border border-slate-200">
                                    <h4 class="text-sm font-medium text-slate-700 mb-2">Last Updated</h4>
                                    <p class="text-sm text-slate-600">{{ formatDate(cardProp.updated_at) }}</p>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- Edit Dialog -->
        <MyDialog
            v-model="showEditDialog"
            header="Edit Card"
            :confirmHandle="handleSaveEdit"
            confirmLabel="Save Changes"
            confirmSeverity="success"
            cancelLabel="Cancel"
            successMessage="Card updated successfully"
            errorMessage="Failed to update card"
            @cancel="handleCancelEdit"
            @hide="handleDialogHide"
            style="width: 90vw; max-width: 1200px;"
        >
            <CardCreateEditForm 
                ref="editFormRef"
                :cardProp="cardProp" 
                :isEditMode="true"
                :isInDialog="true"
            />
        </MyDialog>
    </div>
</template>

<script setup>
import { computed, ref } from 'vue';
import Button from 'primevue/button';
import Tag from 'primevue/tag';
import MyDialog from '@/components/MyDialog.vue';
import CardCreateEditForm from './CardCreateEditForm.vue';
import cardPlaceholder from '@/assets/images/card-placeholder.svg';

const props = defineProps({
    cardProp: {
        type: Object,
        default: null
    }
});

const emit = defineEmits(['edit', 'delete-requested', 'update-card']);

const showEditDialog = ref(false);
const editFormRef = ref(null);
const isLoading = ref(false);

const displayImageForView = computed(() => {
    if (props.cardProp && props.cardProp.image_urls && props.cardProp.image_urls.length > 0) {
        return props.cardProp.image_urls[0];
    }
    return null;
});

const displayQrCodePositionForView = computed(() => {
    if (!props.cardProp || !props.cardProp.qr_code_position) return null;
    
    const positions = {
        'TL': 'Top Left',
        'TR': 'Top Right',
        'BL': 'Bottom Left',
        'BR': 'Bottom Right'
    };
    
    return positions[props.cardProp.qr_code_position] || props.cardProp.qr_code_position;
});

const handleEdit = () => {
    showEditDialog.value = true;
};

const handleSaveEdit = async () => {
    if (editFormRef.value) {
        isLoading.value = true;
        try {
            const payload = editFormRef.value.getPayload();
            await emit('update-card', payload);
            showEditDialog.value = false;
        } catch (error) {
            // Error will be handled by MyDialog's toast
            throw error;
        } finally {
            isLoading.value = false;
        }
    }
};

const handleCancelEdit = () => {
    showEditDialog.value = false;
    // Reset form to original values when canceling
    if (editFormRef.value) {
        editFormRef.value.initializeForm();
    }
};

const handleDialogHide = () => {
    // Reset form when dialog is hidden
    if (editFormRef.value) {
        editFormRef.value.initializeForm();
    }
};

const handleRequestDelete = () => {
    if (props.cardProp && props.cardProp.id) {
        emit('delete-requested', props.cardProp.id);
    }
};

const formatDate = (dateString) => {
    return new Date(dateString).toLocaleDateString('en-US', {
        year: 'numeric',
        month: 'long',
        day: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
    });
};

const getQrCodePositionClass = (position) => {
    const classes = {
        'TL': 'top-2 left-2',
        'TR': 'top-2 right-2',
        'BL': 'bottom-2 left-2',
        'BR': 'bottom-2 right-2'
    };
    return classes[position] || 'bottom-2 right-2'; // Default to bottom-right
};
</script>

<style scoped>
/* Fixed height container with 2:3 aspect ratio (card standard) */
.card-artwork-container {
    height: 360px; /* 240 * 1.5 = 360px for 2:3 ratio */
    width: 240px;   /* Base width */
    aspect-ratio: 2/3;
    margin: 0 auto;
}

/* Responsive adjustments for smaller screens */
@media (max-width: 640px) {
    .card-artwork-container {
        height: 315px; /* 210 * 1.5 = 315px for 2:3 ratio */
        width: 210px;
    }
}

@media (max-width: 480px) {
    .card-artwork-container {
        height: 270px; /* 180 * 1.5 = 270px for 2:3 ratio */
        width: 180px;
    }
}

/* Component-specific styles */
.card-artwork-container img {
    transition: all 0.2s ease-in-out;
}

.card-artwork-container:hover img {
    transform: scale(1.02);
}
</style>