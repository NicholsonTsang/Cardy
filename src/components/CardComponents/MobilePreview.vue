<template>
    <div class="space-y-6">
        <!-- Preview Header -->
        <div class="flex items-center justify-between">
            <div>
                <h3 class="text-lg font-semibold text-slate-900 flex items-center gap-2">
                    <i class="pi pi-mobile text-blue-600"></i>
                    {{ $t('dashboard.mobile_preview') }}
                </h3>
                <p class="text-sm text-slate-600 mt-1">{{ $t('dashboard.mobile_preview_description') }}</p>
            </div>
        </div>

        <!-- Preview Content -->
        <div class="bg-white rounded-xl shadow-lg border border-slate-200 overflow-hidden">
            <!-- Loading State -->
            <div v-if="isLoading" class="flex flex-col items-center justify-center py-12">
                <ProgressSpinner strokeWidth="3" animationDuration=".8s" class="w-8 h-8 text-blue-600"/>
                <p class="mt-3 text-sm text-slate-600">{{ $t('dashboard.loading_mobile_preview') }}</p>
            </div>

            <!-- Error State -->
            <div v-else-if="error" class="flex flex-col items-center justify-center py-12 px-6 text-center">
                <div class="w-12 h-12 bg-red-100 rounded-full flex items-center justify-center mb-3">
                    <i class="pi pi-exclamation-triangle text-xl text-red-500"></i>
                </div>
                <h4 class="text-sm font-medium text-red-600 mb-2">{{ $t('dashboard.preview_unavailable') }}</h4>
                <p class="text-xs text-slate-600 mb-4">{{ error }}</p>
                <Button 
                    :label="$t('dashboard.retry')" 
                    icon="pi pi-refresh" 
                    @click="loadPreview" 
                    size="small"
                    outlined
                />
            </div>


            <!-- Mobile Preview -->
            <div v-else class="preview-wrapper">
                <VueDevice 
                    device="iphone-14-pro" 
                    color="black"
                    :showHome="false"
                    :showBtns="true"
                    class="device-simulator"
                >
                    <div class="device-content">
                        <iframe
                            :src="previewUrl"
                            :key="previewUrl"
                            @load="handleIframeLoad"
                            @error="handleIframeError"
                            sandbox="allow-scripts allow-same-origin allow-popups"
                            frameborder="0"
                            class="mobile-iframe"
                        ></iframe>
                        
                        <!-- Loading -->
                        <div v-if="iframeLoading" class="mobile-loading">
                            <ProgressSpinner strokeWidth="3" animationDuration=".8s" class="w-10 h-10 text-blue-600"/>
                            <p class="loading-text">{{ $t('dashboard.loading_mobile_preview') }}</p>
                        </div>
                    </div>
                </VueDevice>
                
                <!-- Preview Info -->
                <div class="preview-info">
                    <p class="info-text">{{ $t('dashboard.live_preview') }}</p>
                </div>
            </div>
        </div>
    </div>
</template>

<script setup>
import { ref, computed, watch, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { supabase } from '@/lib/supabase';
import Button from 'primevue/button';
import ProgressSpinner from 'primevue/progressspinner';
import { VueDevice } from 'vue-devices';

const { t } = useI18n();

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
            error.value = t('dashboard.preview_access_denied');
            return;
        }
        
        // Preview URL is already set via computed property
        iframeLoading.value = true;
        
    } catch (err) {
        console.error('Error loading preview:', err);
        error.value = err.message || t('dashboard.failed_load_preview');
    } finally {
        isLoading.value = false;
    }
};

const handleIframeLoad = () => {
    iframeLoading.value = false;
};

const handleIframeError = () => {
    iframeLoading.value = false;
    error.value = t('dashboard.failed_load_preview_content');
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
/* Wrapper */
.preview-wrapper {
    padding: 1.5rem;
    display: flex;
    flex-direction: column;
    align-items: center;
}

/* Device Simulator Container */
.device-simulator {
    max-width: 380px;
    width: 100%;
    margin: 0 auto;
}

/* Device Content Wrapper */
.device-content {
    position: relative;
    width: 100%;
    height: 100%;
    background: linear-gradient(180deg, #0f172a 0%, #1e3a8a 50%, #312e81 100%);
    overflow: hidden;
    border-radius: inherit;
}

/* Iframe */
.mobile-iframe {
    position: absolute;
    top: 44px;
    left: 0;
    right: 0;
    bottom: 0;
    width: 100%;
    height: calc(100% - 44px);
    border: none;
    background: transparent;
    border-radius: 0 0 inherit inherit;
    overflow: hidden;
}

/* Loading State */
.mobile-loading {
    position: absolute;
    top: 44px;
    left: 0;
    right: 0;
    bottom: 0;
    background: linear-gradient(135deg, #f8fafc, #f1f5f9);
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    gap: 1rem;
    z-index: 10;
}

.loading-text {
    font-size: 0.875rem;
    font-weight: 500;
    color: #64748b;
}

/* Preview Info */
.preview-info {
    margin-top: 1.5rem;
    text-align: center;
}

.info-text {
    font-size: 0.8125rem;
    color: #64748b;
}

/* Responsive */
@media (max-width: 640px) {
    .device-simulator {
        max-width: 340px;
    }
}

@media (max-width: 480px) {
    .preview-wrapper {
        padding: 1rem;
    }
    
    .device-simulator {
        max-width: 300px;
    }
}

@media (max-width: 360px) {
    .device-simulator {
        max-width: 280px;
    }
}
</style> 