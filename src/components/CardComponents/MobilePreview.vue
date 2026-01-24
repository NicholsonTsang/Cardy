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
            <!-- Initial Loading State -->
            <div v-if="isLoading" class="flex flex-col items-center justify-center py-12">
                <ProgressSpinner strokeWidth="3" animationDuration=".8s" class="w-8 h-8 text-blue-600"/>
                <p class="mt-3 text-sm text-slate-600">{{ $t('dashboard.loading_mobile_preview') }}</p>
            </div>

            <!-- Access Error State -->
            <div v-else-if="accessError" class="flex flex-col items-center justify-center py-12 px-6 text-center">
                <div class="w-12 h-12 bg-red-100 rounded-full flex items-center justify-center mb-3">
                    <i class="pi pi-exclamation-triangle text-xl text-red-500"></i>
                </div>
                <h4 class="text-sm font-medium text-red-600 mb-2">{{ $t('dashboard.preview_unavailable') }}</h4>
                <p class="text-xs text-slate-600 mb-4">{{ accessError }}</p>
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
                <PhoneIframePreview
                    :src="previewUrl"
                    :iframeKey="previewUrl"
                    :title="cardProp?.name || 'Mobile Preview'"
                    :loadingText="$t('dashboard.loading_mobile_preview')"
                    :errorText="$t('dashboard.failed_load_preview_content')"
                    :retryText="$t('dashboard.retry')"
                    @error="handleIframeError"
                />
                
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
import PhoneIframePreview from '@/components/common/PhoneIframePreview.vue';

const { t } = useI18n();

const props = defineProps({
    cardProp: {
        type: Object,
        required: true
    }
});

const isLoading = ref(false);
const accessError = ref(null);

const previewUrl = computed(() => {
    if (!props.cardProp?.id) return null;
    const baseUrl = window.location.origin;
    return `${baseUrl}/preview/${props.cardProp.id}`;
});

const loadPreview = async () => {
    if (!props.cardProp?.id) return;
    
    isLoading.value = true;
    accessError.value = null;
    
    try {
        const { data: previewData, error: previewError } = await supabase.rpc('get_card_preview_access', {
            p_card_id: props.cardProp.id
        });
        
        if (previewError) {
            throw new Error(previewError.message);
        }
        
        if (!previewData || previewData.length === 0) {
            accessError.value = t('dashboard.preview_access_denied');
            return;
        }
        
    } catch (err) {
        console.error('Error loading preview:', err);
        accessError.value = err.message || t('dashboard.failed_load_preview');
    } finally {
        isLoading.value = false;
    }
};

const handleIframeError = () => {
    accessError.value = t('dashboard.failed_load_preview_content');
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
.preview-wrapper {
    padding: 1.5rem;
    display: flex;
    flex-direction: column;
    align-items: center;
}

.preview-info {
    margin-top: 1.5rem;
    text-align: center;
}

.info-text {
    font-size: 0.8125rem;
    color: #64748b;
}

@media (max-width: 480px) {
    .preview-wrapper {
        padding: 1rem;
    }
}
</style>
