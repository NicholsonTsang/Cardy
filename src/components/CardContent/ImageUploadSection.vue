<template>
    <div class="space-y-4">
        <!-- Upload Drop Zone (when no image) -->
        <div 
            v-if="!previewImage"
            class="upload-drop-zone-content"
            @dragover.prevent="$emit('dragover', $event)"
            @dragleave.prevent="$emit('dragleave', $event)"
            @drop.prevent="$emit('drop', $event)"
            :class="{ 'drag-active': isDragActive }"
        >
            <div class="upload-content">
                <div class="upload-icon-container">
                    <i class="pi pi-image upload-icon"></i>
                </div>
                <h4 class="upload-title">{{ uploadTitle }}</h4>
                <p class="upload-subtitle">{{ $t('dashboard.drag_drop_upload') }}</p>
                
                <Button 
                    :label="$t('dashboard.upload_photo')"
                    icon="pi pi-upload"
                    @click="$emit('upload')"
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
                    alt="Preview"
                    class="object-contain h-full w-full rounded-lg shadow-md" 
                />
            </div>
            
            <div class="image-actions-content">
                <Button 
                    :label="$t('dashboard.change_photo')"
                    icon="pi pi-image"
                    @click="$emit('upload')"
                    severity="secondary"
                    outlined
                    size="small"
                    class="action-button-content"
                />
                <Button 
                    :label="$t('dashboard.crop_image')"
                    icon="pi pi-expand"
                    @click="$emit('crop')"
                    severity="info"
                    outlined
                    size="small"
                    class="action-button-content"
                />
                <Button 
                    v-if="isCropped"
                    :label="$t('dashboard.undo_crop')"
                    icon="pi pi-undo"
                    @click="$emit('undo-crop')"
                    severity="warning"
                    outlined
                    size="small"
                    class="action-button-content"
                />
            </div>
        </div>

        <!-- Aspect Ratio Info -->
        <div v-if="aspectRatioDisplay" class="p-2 bg-slate-50 rounded-lg">
            <p class="text-xs text-slate-500 flex items-center gap-1">
                <i class="pi pi-info-circle"></i>
                {{ $t('dashboard.recommended_ratio') }}: {{ aspectRatioDisplay }}
            </p>
        </div>
    </div>
</template>

<script setup>
import Button from 'primevue/button';

defineProps({
    previewImage: String,
    isDragActive: Boolean,
    isCropped: Boolean,
    uploadTitle: String,
    aspectRatioDisplay: String
});

defineEmits(['dragover', 'dragleave', 'drop', 'upload', 'crop', 'undo-crop']);
</script>

<style scoped>
.upload-drop-zone-content {
    border: 2px dashed #d1d5db;
    border-radius: 1rem;
    padding: 2rem;
    text-align: center;
    transition: all 0.2s ease;
    background: linear-gradient(135deg, #f8fafc 0%, #f1f5f9 100%);
    cursor: pointer;
}

.upload-drop-zone-content:hover,
.upload-drop-zone-content.drag-active {
    border-color: #3b82f6;
    background: linear-gradient(135deg, #eff6ff 0%, #dbeafe 100%);
}

.upload-content {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 0.75rem;
}

.upload-icon-container {
    width: 3rem;
    height: 3rem;
    background: #e0e7ff;
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
}

.upload-icon {
    font-size: 1.25rem;
    color: #4f46e5;
}

.upload-title {
    font-size: 0.875rem;
    font-weight: 600;
    color: #1e293b;
    margin: 0;
}

.upload-subtitle {
    font-size: 0.75rem;
    color: #64748b;
    margin: 0;
}

.upload-trigger-button {
    margin-top: 0.5rem;
}

.content-image-container-compact {
    aspect-ratio: 4/3;
    overflow: hidden;
    display: flex;
    align-items: center;
    justify-content: center;
}

.image-actions-content {
    display: flex;
    flex-wrap: wrap;
    gap: 0.5rem;
}

.action-button-content {
    flex: 1;
    min-width: fit-content;
}
</style>

