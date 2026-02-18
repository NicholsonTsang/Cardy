<template>
    <div class="phone-preview-container">
        <PhoneSimulator :width="phoneWidth" :aspectRatio="phoneAspectRatio" class="phone-preview-device">
            <div class="phone-screen-content">
                <!-- Placeholder State -->
                <div v-if="showPlaceholder" class="phone-placeholder">
                    <div class="placeholder-icon">
                        <i :class="placeholderIcon"></i>
                    </div>
                    <p class="placeholder-text">{{ placeholderText }}</p>
                </div>
                
                <!-- Iframe (renders behind loading if loading) -->
                <div v-if="src && !showPlaceholder" class="phone-iframe-wrapper">
                    <iframe
                        :src="src"
                        :key="iframeKey"
                        :title="title"
                        @load="handleIframeLoad"
                        @error="handleIframeError"
                        :sandbox="sandbox"
                        frameborder="0"
                        class="phone-iframe"
                        :style="iframeStyle"
                        loading="lazy"
                    ></iframe>
                </div>
                
                <!-- Loading Overlay -->
                <div v-if="src && !showPlaceholder && loading && !hasError" class="phone-loading">
                    <ProgressSpinner strokeWidth="3" animationDuration=".8s" class="w-8 h-8 sm:w-10 sm:h-10"/>
                </div>
                
                <!-- Error State -->
                <div v-if="hasError" class="phone-placeholder phone-error">
                    <div class="placeholder-icon error">
                        <i class="pi pi-exclamation-triangle"></i>
                    </div>
                    <p class="placeholder-text">{{ errorText }}</p>
                    <button v-if="showRetry" @click="handleRetry" class="retry-button">
                        {{ retryText }}
                    </button>
                </div>
            </div>
        </PhoneSimulator>
    </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue';
import ProgressSpinner from 'primevue/progressspinner';
import PhoneSimulator from '@/components/common/PhoneSimulator.vue';

const props = defineProps({
    // Iframe source URL
    src: {
        type: String,
        default: null
    },
    // Key for forcing iframe refresh
    iframeKey: {
        type: [String, Number],
        default: ''
    },
    // Accessibility title
    title: {
        type: String,
        default: 'Mobile Preview'
    },
    // Sandbox attributes
    sandbox: {
        type: String,
        default: 'allow-scripts allow-same-origin allow-popups'
    },
    // Placeholder state
    showPlaceholder: {
        type: Boolean,
        default: false
    },
    placeholderText: {
        type: String,
        default: 'Select content to preview'
    },
    placeholderIcon: {
        type: String,
        default: 'pi pi-mobile text-xl sm:text-2xl text-slate-400'
    },
    // Loading state
    loadingText: {
        type: String,
        default: 'Loading...'
    },
    // Error state
    errorText: {
        type: String,
        default: 'Failed to load preview'
    },
    showRetry: {
        type: Boolean,
        default: true
    },
    retryText: {
        type: String,
        default: 'Retry'
    },
    // Theme: 'light' or 'dark'
    theme: {
        type: String,
        default: 'light'
    },
    // Fixed width override (bypasses responsive calculation)
    width: {
        type: Number,
        default: null
    }
});

const emit = defineEmits(['load', 'error', 'retry']);

// Internal state
const loading = ref(true);
const hasError = ref(false);

// Responsive phone dimensions
const windowWidth = ref(typeof window !== 'undefined' ? window.innerWidth : 1024);
const phoneAspectRatio = '9 / 16';
const phoneAspectValue = 16 / 9;

const phoneWidth = computed(() => {
    if (props.width) return props.width;
    if (windowWidth.value < 380) return 240;
    if (windowWidth.value < 480) return 260;
    if (windowWidth.value < 640) return 280;
    return 320;
});

const handleResize = () => {
    windowWidth.value = window.innerWidth;
};

// Calculate phone screen dimensions
const phoneBorder = computed(() => phoneWidth.value * 0.025);
const screenWidth = computed(() => phoneWidth.value - (phoneBorder.value * 2));
const screenHeight = computed(() => {
    const phoneHeight = phoneWidth.value * phoneAspectValue;
    return phoneHeight - (phoneBorder.value * 2);
});

// Calculate iframe scale (cover mode)
const iframeScale = computed(() => {
    const targetWidth = 375;
    const targetHeight = 667;
    const scaleX = screenWidth.value / targetWidth;
    const scaleY = screenHeight.value / targetHeight;
    return Math.max(scaleX, scaleY);
});

const iframeStyle = computed(() => ({
    transform: `translate(-50%, -50%) scale(${iframeScale.value})`
}));

// Event handlers
const handleIframeLoad = () => {
    loading.value = false;
    hasError.value = false;
    emit('load');
};

const handleIframeError = () => {
    loading.value = false;
    hasError.value = true;
    emit('error');
};

const handleRetry = () => {
    loading.value = true;
    hasError.value = false;
    emit('retry');
};

// Reset loading state when src changes
const resetState = () => {
    loading.value = true;
    hasError.value = false;
};

// Watch for src changes (exposed for parent to call)
defineExpose({ resetState });

onMounted(() => {
    window.addEventListener('resize', handleResize);
});

onUnmounted(() => {
    window.removeEventListener('resize', handleResize);
});
</script>

<style scoped>
.phone-preview-container {
    display: flex;
    justify-content: center;
}

.phone-screen-content {
    position: relative;
    width: 100%;
    height: 100%;
    background: #0f172a;
    overflow: hidden;
}

/* Iframe wrapper */
.phone-iframe-wrapper {
    position: absolute;
    inset: 0;
    overflow: hidden;
}

.phone-iframe {
    position: absolute;
    top: 50%;
    left: 50%;
    width: 375px;
    height: 667px;
    border: none;
    background: #0f172a;
    transform-origin: center center;
}

/* Placeholder State */
.phone-placeholder {
    position: absolute;
    inset: 0;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    background: #0f172a;
    padding: 1rem;
}

.placeholder-icon {
    width: 3rem;
    height: 3rem;
    border-radius: 0.75rem;
    background: rgba(255, 255, 255, 0.08);
    display: flex;
    align-items: center;
    justify-content: center;
    margin-bottom: 0.75rem;
    color: rgba(255, 255, 255, 0.5);
}

@media (min-width: 640px) {
    .placeholder-icon {
        width: 4rem;
        height: 4rem;
        border-radius: 1rem;
        margin-bottom: 1rem;
    }
}

.placeholder-icon.error {
    background: rgba(239, 68, 68, 0.15);
}

.placeholder-icon.error i {
    color: #f87171;
}

.placeholder-text {
    color: rgba(255, 255, 255, 0.55);
    font-weight: 500;
    font-size: 0.875rem;
    text-align: center;
}

@media (min-width: 640px) {
    .placeholder-text {
        font-size: 1rem;
    }
}

/* Loading State */
.phone-loading {
    position: absolute;
    inset: 0;
    background: #0f172a;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    gap: 0.75rem;
    z-index: 10;
}

.phone-loading::before {
    content: '';
    position: absolute;
    width: 80px;
    height: 80px;
    border-radius: 50%;
    background: radial-gradient(circle, rgba(99, 102, 241, 0.2) 0%, transparent 70%);
    animation: phone-loading-glow 2s ease-in-out infinite;
}

@keyframes phone-loading-glow {
    0%, 100% { transform: scale(1); opacity: 0.5; }
    50% { transform: scale(1.6); opacity: 0.85; }
}

/* Ensure spinner and text sit above the glow pseudo-element */
.phone-loading :deep(.p-progressspinner) {
    position: relative;
    z-index: 1;
}

.loading-text {
    color: rgba(255, 255, 255, 0.7);
    font-size: 0.875rem;
    font-weight: 500;
    letter-spacing: 0.02em;
    position: relative;
    z-index: 1;
}

@media (min-width: 640px) {
    .loading-text {
        font-size: 1rem;
    }
}

/* Error State */
.phone-error .placeholder-text {
    margin-bottom: 0.75rem;
}

.retry-button {
    padding: 0.5rem 1rem;
    background: rgba(99, 102, 241, 0.25);
    color: rgba(255, 255, 255, 0.9);
    font-size: 0.875rem;
    font-weight: 500;
    border-radius: 0.5rem;
    border: 1px solid rgba(99, 102, 241, 0.4);
    cursor: pointer;
    transition: background-color 0.2s;
}

.retry-button:hover {
    background: rgba(99, 102, 241, 0.35);
}
</style>

