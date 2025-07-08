<template>
    <div class="space-y-6">
        <!-- Preview Header -->
        <div class="flex items-center justify-between">
            <div>
                <h3 class="text-lg font-semibold text-slate-900 flex items-center gap-2">
                    <i class="pi pi-mobile text-blue-600"></i>
                    Mobile Preview
                </h3>
                <p class="text-sm text-slate-600 mt-1">See how your card will appear to visitors on mobile devices</p>
            </div>
        </div>

        <!-- Preview Content -->
        <div class="bg-white rounded-xl shadow-lg border border-slate-200 overflow-hidden">
            <!-- Loading State -->
            <div v-if="isLoading" class="flex flex-col items-center justify-center py-12">
                <ProgressSpinner strokeWidth="3" animationDuration=".8s" class="w-8 h-8 text-blue-600"/>
                <p class="mt-3 text-sm text-slate-600">Loading mobile preview...</p>
            </div>

            <!-- Error State -->
            <div v-else-if="error" class="flex flex-col items-center justify-center py-12 px-6 text-center">
                <div class="w-12 h-12 bg-red-100 rounded-full flex items-center justify-center mb-3">
                    <i class="pi pi-exclamation-triangle text-xl text-red-500"></i>
                </div>
                <h4 class="text-sm font-medium text-red-600 mb-2">Preview Unavailable</h4>
                <p class="text-xs text-slate-600 mb-4">{{ error }}</p>
                <Button 
                    label="Retry" 
                    icon="pi pi-refresh" 
                    @click="loadPreview" 
                    size="small"
                    outlined
                />
            </div>


            <!-- Mobile Frame with Iframe -->
            <div v-else class="p-6">
                <div class="mx-auto iphone-container">
                    <!-- iPhone 17 Device Frame -->
                    <div class="relative bg-slate-900 rounded-[3rem] p-1 shadow-2xl iphone-frame">
                        <!-- Dynamic Island -->
                        <div class="absolute top-2 left-1/2 transform -translate-x-1/2 w-28 h-7 bg-black rounded-2xl z-10"></div>
                        
                        <!-- Screen -->
                        <div class="bg-white rounded-[2.5rem] overflow-hidden relative iphone-screen">
                            <!-- Status Bar -->
                            <div class="bg-white px-8 py-3 flex justify-between items-center text-sm font-medium text-slate-900">
                                <span>9:41</span>
                                <div class="flex items-center gap-1">
                                    <div class="flex gap-1">
                                        <div class="w-1 h-1 bg-slate-900 rounded-full"></div>
                                        <div class="w-1 h-1 bg-slate-900 rounded-full"></div>
                                        <div class="w-1 h-1 bg-slate-400 rounded-full"></div>
                                    </div>
                                    <i class="pi pi-wifi text-slate-900 ml-1"></i>
                                    <div class="w-6 h-3 border border-slate-900 rounded-sm relative ml-1">
                                        <div class="w-4 h-1.5 bg-green-500 rounded-sm absolute top-0.5 left-0.5"></div>
                                    </div>
                                </div>
                            </div>
                            
                            <!-- Iframe Container -->
                            <div class="relative iphone-content">
                                <iframe
                                    :src="previewUrl"
                                    class="w-full h-full border-0"
                                    :key="previewUrl"
                                    @load="handleIframeLoad"
                                    @error="handleIframeError"
                                    sandbox="allow-scripts allow-same-origin"
                                    loading="lazy"
                                ></iframe>
                                
                                <!-- Iframe Loading Overlay -->
                                <div v-if="iframeLoading" class="absolute inset-0 bg-white flex items-center justify-center">
                                    <ProgressSpinner strokeWidth="3" animationDuration=".8s" class="w-6 h-6 text-blue-600"/>
                                </div>
                            </div>
                        </div>
                        
                        <!-- Home Indicator -->
                        <div class="absolute bottom-2 left-1/2 transform -translate-x-1/2 w-32 h-1 bg-white rounded-full opacity-60"></div>
                    </div>
                    
                    <!-- Preview Info -->
                    <div class="mt-4 text-center">
                        <p class="text-xs text-slate-500">iPhone 17 Pro Simulation</p>
                        <p class="text-xs text-slate-500">Live preview of your mobile card experience</p>
                        <div v-if="sampleCard" class="mt-2 text-xs text-slate-400">
                            <span v-if="sampleCard.preview_mode" 
                                  class="inline-flex items-center gap-1 px-2 py-1 bg-blue-100 text-blue-700 rounded-full">
                                <i class="pi pi-eye text-xs"></i>
                                Preview Mode
                            </span>
                            <span v-else>
                                Using sample card: {{ sampleCard.issue_card_id.substring(0, 8) }}...
                            </span>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</template>

<script setup>
import { ref, computed, watch, onMounted } from 'vue';
import { supabase } from '@/lib/supabase';
import Button from 'primevue/button';
import ProgressSpinner from 'primevue/progressspinner';

const props = defineProps({
    cardProp: {
        type: Object,
        required: true
    }
});

const isLoading = ref(false);
const iframeLoading = ref(true);
const error = ref(null);
const sampleCard = ref(null);

const previewUrl = computed(() => {
    if (!props.cardProp?.id) return null;
    const baseUrl = window.location.origin;
    // Always use preview route for the mobile preview
    const url = `${baseUrl}/preview/${props.cardProp.id}`;
    console.log('Preview URL:', url);
    return url;
});

const loadPreview = async () => {
    if (!props.cardProp?.id) return;
    
    isLoading.value = true;
    error.value = null;
    
    try {
        // Verify preview access (optional - checks if user owns the card)
        const { data: previewData, error: previewError } = await supabase.rpc('get_card_preview_access', {
            p_card_id: props.cardProp.id
        });
        
        if (previewError) {
            throw new Error(previewError.message);
        }
        
        if (!previewData || previewData.length === 0) {
            error.value = 'Preview access denied. You can only preview your own cards.';
            return;
        }
        
        // Preview URL is already set via computed property
        iframeLoading.value = true;
        
    } catch (err) {
        console.error('Error loading preview:', err);
        error.value = err.message || 'Failed to load mobile preview';
    } finally {
        isLoading.value = false;
    }
};

const handleIframeLoad = () => {
    iframeLoading.value = false;
};

const handleIframeError = () => {
    iframeLoading.value = false;
    error.value = 'Failed to load mobile preview content';
};

// Watch for card changes
watch(
    () => props.cardProp?.id,
    (newCardId) => {
        if (newCardId) {
            loadPreview();
        }
    },
    { immediate: true }
);

onMounted(() => {
    if (props.cardProp?.id) {
        loadPreview();
    }
});
</script>

<style scoped>
/* Ensure iframe scales properly */
iframe {
    transform-origin: top left;
}

/* iPhone 17 Dimensions and Styling */
.iphone-container {
    max-width: 320px; /* Slightly increased iPhone 17 Pro width scale */
}

.iphone-frame {
    width: 100%;
    /* iPhone 17 Pro aspect ratio: 19.5:9 (approximately 2.17:1) */
    aspect-ratio: 9 / 19.5;
    max-width: 320px;
    max-height: 693px; /* Increased proportionally: 320 * (19.5/9) ≈ 693 */
    margin: 0 auto;
}

.iphone-screen {
    width: 100%;
    height: 100%;
    /* Account for the frame padding */
}

.iphone-content {
    /* Subtract status bar height from total */
    height: calc(100% - 3.5rem);
    min-height: 600px; /* Increased proportionally */
}

/* Responsive adjustments for iPhone 17 */
@media (max-width: 480px) {
    .iphone-container {
        max-width: 280px;
    }
    
    .iphone-frame {
        max-width: 280px;
        max-height: 607px;
    }
    
    .iphone-content {
        min-height: 520px;
    }
}

@media (max-width: 360px) {
    .iphone-container {
        max-width: 240px;
    }
    
    .iphone-frame {
        max-width: 240px;
        max-height: 520px;
    }
    
    .iphone-content {
        min-height: 450px;
    }
}

/* Custom scrollbar for mobile frame */
.mobile-frame::-webkit-scrollbar {
    width: 2px;
}

.mobile-frame::-webkit-scrollbar-track {
    background: #f1f5f9;
}

.mobile-frame::-webkit-scrollbar-thumb {
    background: #cbd5e1;
    border-radius: 1px;
}
</style> 