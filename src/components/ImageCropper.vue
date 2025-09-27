<template>
    <div class="image-cropper">
        <!-- Aspect Ratio Info -->
        <div class="aspect-ratio-info">{{ aspectRatioDisplay }} aspect ratio</div>

        <!-- Square Crop Container -->
        <div ref="cropContainerRef" class="crop-container">
            <!-- Image -->
            <img 
                ref="imageRef"
                :src="imageSrc"
                alt="Image to crop"
                class="crop-image"
                :style="imageTransform"
                @mousedown="startDrag"
                @touchstart="startDrag"
                draggable="false"
            />
            
            <!-- Crop Overlay -->
            <div class="crop-overlay">
                <!-- Dark areas outside crop frame -->
                <div class="overlay-top" :style="overlayStyles.top"></div>
                <div class="overlay-bottom" :style="overlayStyles.bottom"></div>
                <div class="overlay-left" :style="overlayStyles.left"></div>
                <div class="overlay-right" :style="overlayStyles.right"></div>
                
                <!-- Crop frame border -->
                <div class="crop-frame" :style="cropFrameStyles">
                    <div class="crop-frame-border"></div>
                </div>
            </div>
        </div>

        <!-- Zoom Control -->
        <div class="zoom-section">
            <div class="zoom-controls">
                <button @click="zoomOut" class="zoom-button">
                    <i class="pi pi-minus"></i>
                </button>
                <div class="zoom-slider-container">
                    <input 
                        type="range" 
                        v-model="zoom"
                        :min="minZoom"
                        :max="maxZoom"
                        :step="0.01"
                        class="zoom-slider"
                        @input="handleZoomChange"
                    />
                </div>
                <button @click="zoomIn" class="zoom-button">
                    <i class="pi pi-plus"></i>
                </button>
            </div>
            <div class="zoom-info">
                Drag to reposition • {{ Math.round(zoom * 100) }}% zoom
            </div>
        </div>
    </div>
</template>

<script setup>
import { ref, computed, onMounted, nextTick } from 'vue';

const props = defineProps({
    imageSrc: {
        type: String,
        required: true
    },
    aspectRatio: {
        type: Number,
        required: true
    },
    aspectRatioDisplay: {
        type: String,
        default: '2:3'
    }
});

const emit = defineEmits(['crop-applied', 'crop-cancelled']);

// Refs
const imageRef = ref(null);
const cropContainerRef = ref(null);

// State
const zoom = ref(1);
const imagePosition = ref({ x: 0, y: 0 });
const isDragging = ref(false);
const dragStart = ref({ x: 0, y: 0 });

// Image and container dimensions
const imageNaturalSize = ref({ width: 0, height: 0 });
const containerSize = ref(400); // Square container
const cropFrameDimensions = ref({ width: 200, height: 200 });

// Zoom constraints
const minZoom = ref(1);
const maxZoom = ref(3);

// Computed properties
const imageTransform = computed(() => {
    return {
        transform: `translate(${imagePosition.value.x}px, ${imagePosition.value.y}px) scale(${zoom.value})`,
        transformOrigin: 'center center'
    };
});

const cropFrameStyles = computed(() => {
    const frameWidth = cropFrameDimensions.value.width;
    const frameHeight = cropFrameDimensions.value.height;
    const containerWidth = containerSize.value;
    const containerHeight = containerSize.value;
    
    return {
        width: `${frameWidth}px`,
        height: `${frameHeight}px`,
        left: `${(containerWidth - frameWidth) / 2}px`,
        top: `${(containerHeight - frameHeight) / 2}px`
    };
});

const overlayStyles = computed(() => {
    const frameWidth = cropFrameDimensions.value.width;
    const frameHeight = cropFrameDimensions.value.height;
    const containerWidth = containerSize.value;
    const containerHeight = containerSize.value;
    
    const frameLeft = (containerWidth - frameWidth) / 2;
    const frameTop = (containerHeight - frameHeight) / 2;
    
    return {
        top: {
            top: '0px',
            left: '0px',
            width: '100%',
            height: `${frameTop}px`
        },
        bottom: {
            top: `${frameTop + frameHeight}px`,
            left: '0px',
            width: '100%',
            height: `${containerHeight - frameTop - frameHeight}px`
        },
        left: {
            top: `${frameTop}px`,
            left: '0px',
            width: `${frameLeft}px`,
            height: `${frameHeight}px`
        },
        right: {
            top: `${frameTop}px`,
            left: `${frameLeft + frameWidth}px`,
            width: `${containerWidth - frameLeft - frameWidth}px`,
            height: `${frameHeight}px`
        }
    };
});

// Functions
const calculateOptimalSize = () => {
    if (!imageRef.value || !imageNaturalSize.value.width) {
        return;
    }
    
    const naturalWidth = imageNaturalSize.value.width;
    const naturalHeight = imageNaturalSize.value.height;
    const imageAspectRatio = naturalWidth / naturalHeight;
    
    // Validate aspect ratio prop
    if (typeof props.aspectRatio !== 'number' || props.aspectRatio <= 0) {
        console.error('Invalid aspect ratio:', props.aspectRatio);
        return;
    }
    
    // Calculate crop frame size based on aspect ratio
    const padding = 60;
    const maxFrameSize = containerSize.value - padding;
    
    let frameWidth, frameHeight;
    
    if (props.aspectRatio >= 1) {
        // Landscape or square
        frameWidth = Math.min(maxFrameSize, 300);
        frameHeight = frameWidth / props.aspectRatio;
    } else {
        // Portrait
        frameHeight = Math.min(maxFrameSize, 300);
        frameWidth = frameHeight * props.aspectRatio;
    }
    
    // Ensure minimum frame size
    frameWidth = Math.max(frameWidth, 150);
    frameHeight = Math.max(frameHeight, 150 / props.aspectRatio);
    
    cropFrameDimensions.value = { width: frameWidth, height: frameHeight };
    
    // Calculate minimum zoom to fill crop frame
    const scaleToFillFrame = Math.max(
        frameWidth / naturalWidth,
        frameHeight / naturalHeight
    );
    
    minZoom.value = Math.max(0.5, scaleToFillFrame);
    maxZoom.value = Math.max(3, minZoom.value * 2);
    zoom.value = Math.max(1, minZoom.value);
    
    // Center image
    imagePosition.value = { x: 0, y: 0 };
};

// Drag functionality
const startDrag = (event) => {
    isDragging.value = true;
    const clientX = event.clientX || (event.touches?.[0]?.clientX);
    const clientY = event.clientY || (event.touches?.[0]?.clientY);
    
    if (!clientX || !clientY) return;
    
    dragStart.value = {
        x: clientX - imagePosition.value.x,
        y: clientY - imagePosition.value.y
    };
    
    document.addEventListener('mousemove', handleDrag);
    document.addEventListener('mouseup', stopDrag);
    document.addEventListener('touchmove', handleDrag, { passive: false });
    document.addEventListener('touchend', stopDrag);
    
    event.preventDefault();
    event.stopPropagation();
};

const handleDrag = (event) => {
    if (!isDragging.value) return;
    
    event.preventDefault();
    event.stopPropagation();
    
    const clientX = event.clientX || (event.touches?.[0]?.clientX);
    const clientY = event.clientY || (event.touches?.[0]?.clientY);
    
    if (!clientX || !clientY) return;
    
    // Calculate new position
    const newX = clientX - dragStart.value.x;
    const newY = clientY - dragStart.value.y;
    
    // Apply constraints to keep image within reasonable bounds
    const containerWidth = containerSize.value;
    const containerHeight = containerSize.value;
    const frameWidth = cropFrameDimensions.value.width;
    const frameHeight = cropFrameDimensions.value.height;
    
    // Calculate image bounds with zoom applied
    const naturalWidth = imageNaturalSize.value.width;
    const naturalHeight = imageNaturalSize.value.height;
    const imageAspectRatio = naturalWidth / naturalHeight;
    
    let displayedImageWidth, displayedImageHeight;
    if (imageAspectRatio > 1) {
        displayedImageWidth = containerWidth;
        displayedImageHeight = containerWidth / imageAspectRatio;
    } else {
        displayedImageHeight = containerHeight;
        displayedImageWidth = containerHeight * imageAspectRatio;
    }
    
    const scaledDisplayWidth = displayedImageWidth * zoom.value;
    const scaledDisplayHeight = displayedImageHeight * zoom.value;
    
    // Calculate bounds to keep crop frame filled
    const minX = (containerWidth - scaledDisplayWidth) / 2 - (containerWidth - frameWidth) / 2;
    const maxX = (containerWidth - scaledDisplayWidth) / 2 + (containerWidth - frameWidth) / 2;
    const minY = (containerHeight - scaledDisplayHeight) / 2 - (containerHeight - frameHeight) / 2;
    const maxY = (containerHeight - scaledDisplayHeight) / 2 + (containerHeight - frameHeight) / 2;
    
    imagePosition.value = {
        x: Math.max(minX, Math.min(maxX, newX)),
        y: Math.max(minY, Math.min(maxY, newY))
    };
};

const stopDrag = () => {
    isDragging.value = false;
    document.removeEventListener('mousemove', handleDrag);
    document.removeEventListener('mouseup', stopDrag);
    document.removeEventListener('touchmove', handleDrag);
    document.removeEventListener('touchend', stopDrag);
};

// Zoom functionality
const zoomIn = () => {
    zoom.value = Math.min(maxZoom.value, zoom.value + 0.1);
};

const zoomOut = () => {
    zoom.value = Math.max(minZoom.value, zoom.value - 0.1);
};

const handleZoomChange = (event) => {
    const newZoom = parseFloat(event.target.value);
    zoom.value = Math.max(minZoom.value, Math.min(maxZoom.value, newZoom));
};

// Crop processing
const getCroppedImage = () => {
    if (!imageRef.value) return null;
    
    const canvas = document.createElement('canvas');
    const ctx = canvas.getContext('2d');
    
    // Get crop frame position and size
    const frameWidth = cropFrameDimensions.value.width;
    const frameHeight = cropFrameDimensions.value.height;
    const containerWidth = containerSize.value;
    const containerHeight = containerSize.value;
    
    const frameLeft = (containerWidth - frameWidth) / 2;
    const frameTop = (containerHeight - frameHeight) / 2;
    
    // Get the actual displayed image dimensions (with object-fit: contain)
    const naturalWidth = imageNaturalSize.value.width;
    const naturalHeight = imageNaturalSize.value.height;
    const imageAspectRatio = naturalWidth / naturalHeight;
    
    // Calculate how object-fit: contain displays the image
    let displayedImageWidth, displayedImageHeight;
    let imageDisplayLeft, imageDisplayTop;
    
    if (imageAspectRatio > 1) {
        // Image is wider - fits by width
        displayedImageWidth = containerWidth;
        displayedImageHeight = containerWidth / imageAspectRatio;
        imageDisplayLeft = 0;
        imageDisplayTop = (containerHeight - displayedImageHeight) / 2;
    } else {
        // Image is taller - fits by height
        displayedImageHeight = containerHeight;
        displayedImageWidth = containerHeight * imageAspectRatio;
        imageDisplayLeft = (containerWidth - displayedImageWidth) / 2;
        imageDisplayTop = 0;
    }
    
    // Apply zoom and position to the displayed image
    const scaledDisplayWidth = displayedImageWidth * zoom.value;
    const scaledDisplayHeight = displayedImageHeight * zoom.value;
    
    const finalImageLeft = imageDisplayLeft + (displayedImageWidth - scaledDisplayWidth) / 2 + imagePosition.value.x;
    const finalImageTop = imageDisplayTop + (displayedImageHeight - scaledDisplayHeight) / 2 + imagePosition.value.y;
    
    // Calculate crop coordinates relative to the scaled displayed image
    const cropLeft = frameLeft - finalImageLeft;
    const cropTop = frameTop - finalImageTop;
    
    // Convert back to natural image coordinates
    const scaleToNatural = naturalWidth / scaledDisplayWidth;
    const sourceX = cropLeft * scaleToNatural;
    const sourceY = cropTop * scaleToNatural;
    const sourceWidth = frameWidth * scaleToNatural;
    const sourceHeight = frameHeight * scaleToNatural;
    
    // Set canvas size to target aspect ratio
    const outputSize = 800;
    let canvasWidth, canvasHeight;
    if (props.aspectRatio >= 1) {
        canvasWidth = outputSize;
        canvasHeight = outputSize / props.aspectRatio;
    } else {
        canvasHeight = outputSize;
        canvasWidth = outputSize * props.aspectRatio;
    }
    
    canvas.width = canvasWidth;
    canvas.height = canvasHeight;
    
    // Clamp source coordinates to image bounds
    const clampedSourceX = Math.max(0, Math.min(sourceX, naturalWidth));
    const clampedSourceY = Math.max(0, Math.min(sourceY, naturalHeight));
    const clampedSourceWidth = Math.min(sourceWidth, naturalWidth - clampedSourceX);
    const clampedSourceHeight = Math.min(sourceHeight, naturalHeight - clampedSourceY);
    
    // Draw cropped image
    try {
        ctx.fillStyle = '#ffffff';
        ctx.fillRect(0, 0, canvasWidth, canvasHeight);
        
        ctx.drawImage(
            imageRef.value,
            clampedSourceX,
            clampedSourceY,
            clampedSourceWidth,
            clampedSourceHeight,
            0, 0, canvasWidth, canvasHeight
        );
        
        return canvas.toDataURL('image/jpeg', 0.9);
    } catch (error) {
        console.error('Error creating cropped image:', error);
        return null;
    }
};

// Event handlers
const handleApply = () => {
    const croppedDataURL = getCroppedImage();
    if (croppedDataURL) {
        // Convert to File
        const arr = croppedDataURL.split(',');
        const mime = arr[0].match(/:(.*?);/)[1];
        const bstr = atob(arr[1]);
        let n = bstr.length;
        const u8arr = new Uint8Array(n);
        while (n--) {
            u8arr[n] = bstr.charCodeAt(n);
        }
        const file = new File([u8arr], 'cropped-image.jpg', { type: mime });
        
        emit('crop-applied', {
            file: file,
            dataURL: croppedDataURL
        });
    } else {
        console.error('Failed to generate cropped image');
    }
};

const handleCancel = () => {
    emit('crop-cancelled');
};

// Image initialization
const initializeImage = () => {
    if (!imageRef.value) return;
    
    const img = imageRef.value;
    
    const handleLoad = () => {
        imageNaturalSize.value = {
            width: img.naturalWidth,
            height: img.naturalHeight
        };
        
        calculateOptimalSize();
    };
    
    if (img.complete && img.naturalWidth > 0) {
        handleLoad();
    } else {
        img.onload = handleLoad;
        img.onerror = () => {
            console.error('Image failed to load');
        };
    }
};

// Lifecycle
onMounted(() => {
    console.log('ImageCropper mounted, getCroppedImage available:', typeof getCroppedImage);
    nextTick(() => {
        initializeImage();
    });
});

// Expose methods to parent component
defineExpose({
    getCroppedImage
});
</script>

<style scoped>
/* Main container */
.image-cropper {
    max-width: 500px;
    margin: 0 auto;
}

/* Aspect Ratio Info */
.aspect-ratio-info {
    font-size: 14px;
    color: #6b7280;
    text-align: center;
    margin-bottom: 16px;
}

/* Square crop container */
.crop-container {
    position: relative;
    width: 400px;
    height: 400px;
    margin: 0 auto 24px;
    border-radius: 8px;
    overflow: hidden;
    border: 1px solid #e5e7eb;
    background: #ffffff;
}

/* Image */
.crop-image {
    display: block;
    width: 100%;
    height: 100%;
    object-fit: contain;
    cursor: grab;
    user-select: none;
    transition: transform 0.1s ease;
    position: relative;
    z-index: 1;
    pointer-events: auto;
}

.crop-image:active {
    cursor: grabbing;
}

/* Crop overlay */
.crop-overlay {
    position: absolute;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    pointer-events: none;
    z-index: 2;
}

.overlay-top,
.overlay-bottom,
.overlay-left,
.overlay-right {
    position: absolute;
    background: rgba(0, 0, 0, 0.5);
    pointer-events: none;
}

/* Crop frame */
.crop-frame {
    position: absolute;
    border: 2px solid #ffffff;
    box-shadow: 0 0 0 1px rgba(0, 0, 0, 0.3), 0 2px 8px rgba(0, 0, 0, 0.15);
    pointer-events: none;
}

.crop-frame-border {
    position: absolute;
    top: -1px;
    left: -1px;
    right: -1px;
    bottom: -1px;
    border: 1px solid rgba(255, 255, 255, 0.8);
}

/* Zoom section */
.zoom-section {
    margin-bottom: 24px;
}

.zoom-controls {
    display: flex;
    align-items: center;
    gap: 16px;
    margin-bottom: 8px;
}

.zoom-button {
    width: 32px;
    height: 32px;
    border: 1px solid #d1d5db;
    background: #ffffff;
    border-radius: 6px;
    display: flex;
    align-items: center;
    justify-content: center;
    cursor: pointer;
    color: #6b7280;
    transition: all 0.15s ease;
}

.zoom-button:hover {
    background: #f3f4f6;
    border-color: #9ca3af;
}

.zoom-slider-container {
    flex: 1;
}

.zoom-slider {
    width: 100%;
    height: 6px;
    background: #e5e7eb;
    border-radius: 3px;
    outline: none;
    appearance: none;
    cursor: pointer;
}

.zoom-slider::-webkit-slider-thumb {
    appearance: none;
    width: 20px;
    height: 20px;
    background: #3b82f6;
    border-radius: 50%;
    cursor: pointer;
    border: 2px solid #ffffff;
    box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
    transition: transform 0.15s ease;
}

.zoom-slider::-webkit-slider-thumb:hover {
    transform: scale(1.1);
}

.zoom-slider::-moz-range-thumb {
    width: 20px;
    height: 20px;
    background: #3b82f6;
    border-radius: 50%;
    cursor: pointer;
    border: 2px solid #ffffff;
    box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
}

.zoom-info {
    text-align: center;
    font-size: 14px;
    color: #6b7280;
}

</style>