<template>
    <div class="space-y-6">
        <!-- Action Bar -->
        <div class="flex justify-between items-center" v-if="cardProp">
            <div class="flex items-center gap-3">
                <Tag 
                    :value="cardProp.published ? 'Published' : 'Draft'" 
                    :severity="cardProp.published ? 'success' : 'warning'"
                    icon="pi pi-circle-fill"
                    class="px-3 py-1"
                />
                <Tag 
                    v-if="cardProp.conversation_ai_enabled" 
                    value="AI Enabled" 
                    severity="info"
                    icon="pi pi-robot"
                    class="px-3 py-1"
                />
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
                            <div class="relative">
                                <img
                                    :src="displayImageForView || cardPlaceholder"
                                    alt="Card Artwork"
                                    class="w-full h-auto object-cover rounded-lg border border-slate-200 aspect-[3/4] shadow-md"
                                />
                                <div v-if="!displayImageForView" 
                                     class="absolute inset-0 flex items-center justify-center bg-slate-100 rounded-lg">
                                    <div class="text-center text-slate-400">
                                        <i class="pi pi-image text-3xl mb-3"></i>
                                        <p class="text-sm font-medium">No artwork uploaded</p>
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
                                
                                <div class="bg-white rounded-lg p-4 border border-slate-200">
                                    <h4 class="text-sm font-medium text-slate-700 mb-2 flex items-center gap-2">
                                        <i class="pi pi-robot text-slate-500"></i>
                                        AI Assistant
                                    </h4>
                                    <div class="flex items-center gap-2">
                                        <span class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium"
                                              :class="cardProp.conversation_ai_enabled ? 'bg-green-100 text-green-800' : 'bg-slate-100 text-slate-600'">
                                            <i :class="cardProp.conversation_ai_enabled ? 'pi pi-check' : 'pi pi-times'" class="mr-1"></i>
                                            {{ cardProp.conversation_ai_enabled ? 'Enabled' : 'Disabled' }}
                                        </span>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <!-- AI Configuration -->
                        <div v-if="cardProp.conversation_ai_enabled && cardProp.ai_prompt" 
                             class="bg-gradient-to-r from-amber-50 to-orange-50 rounded-xl p-6 border border-amber-200">
                            <h3 class="text-lg font-semibold text-amber-900 mb-4 flex items-center gap-2">
                                <i class="pi pi-microphone text-amber-600"></i>
                                AI Instructions
                            </h3>
                            <div class="bg-white rounded-lg p-4 border border-amber-200">
                                <p class="text-sm text-amber-800 whitespace-pre-wrap leading-relaxed">{{ cardProp.ai_prompt }}</p>
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
</script>

<style scoped>
.aspect-\[3\/4\] {
    aspect-ratio: 3 / 4;
}

/* Override PrimeVue component font sizes */
:deep(.p-tag) {
    font-size: 0.75rem;
    padding: 0.125rem 0.375rem;
}

:deep(.p-button) {
    font-size: 0.75rem;
}
</style>
