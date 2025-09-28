<template>
    <div class="cropped-image-display">
        <img 
            v-if="displayImage"
            :src="displayImage"
            :alt="alt"
            :class="imageClass"
            @load="onImageLoad"
            @error="onImageError"
        />
        <div 
            v-else-if="showPlaceholder"
            :class="placeholderClass"
        >
            <i class="pi pi-image text-2xl opacity-50"></i>
            <span class="text-sm text-gray-500 mt-2">{{ placeholderText }}</span>
        </div>
    </div>
</template>

<script setup>
import { ref, computed, watch, onMounted } from 'vue';
import { generateCroppedImage, generateCropPreview } from '@/utils/cropUtils';

const props = defineProps({
    imageSrc: {
        type: String,
        required: true
    },
    cropParameters: {
        type: Object,
        default: null
    },
    alt: {
        type: String,
        default: 'Cropped image'
    },
    imageClass: {
        type: String,
        default: 'w-full h-full object-cover'
    },
    placeholderClass: {
        type: String,
        default: 'flex flex-col items-center justify-center text-gray-400 p-4'
    },
    placeholderText: {
        type: String,
        default: 'No image'
    },
    showPlaceholder: {
        type: Boolean,
        default: true
    },
    previewSize: {
        type: Number,
        default: 300
    }
});

const displayImage = ref(null);
const isLoading = ref(false);
const hasError = ref(false);

// Generate the display image based on crop parameters
const generateDisplayImage = async () => {
    if (!props.imageSrc) {
        displayImage.value = null;
        return;
    }

    if (!props.cropParameters) {
        // No crop parameters, use original image
        displayImage.value = props.imageSrc;
        return;
    }

    try {
        isLoading.value = true;
        hasError.value = false;
        
        // Generate cropped preview
        const croppedImage = await generateCropPreview(
            props.imageSrc, 
            props.cropParameters, 
            props.previewSize
        );
        
        if (croppedImage) {
            displayImage.value = croppedImage;
        } else {
            console.warn('Failed to generate cropped image, using original');
            displayImage.value = props.imageSrc;
        }
    } catch (error) {
        console.error('Error generating cropped image:', error);
        hasError.value = true;
        // Fallback to original image
        displayImage.value = props.imageSrc;
    } finally {
        isLoading.value = false;
    }
};

// Watch for changes in props
watch([() => props.imageSrc, () => props.cropParameters], () => {
    generateDisplayImage();
}, { immediate: true });

// Event handlers
const onImageLoad = () => {
    // Image loaded successfully
};

const onImageError = () => {
    console.error('Failed to load image:', props.imageSrc);
    hasError.value = true;
};

// Expose methods for parent components
defineExpose({
    generateDisplayImage,
    isLoading: computed(() => isLoading.value),
    hasError: computed(() => hasError.value)
});
</script>

<style scoped>
.cropped-image-display {
    position: relative;
    width: 100%;
    height: 100%;
}

.cropped-image-display img {
    transition: opacity 0.3s ease;
}

.cropped-image-display img[src=""] {
    opacity: 0;
}
</style>
