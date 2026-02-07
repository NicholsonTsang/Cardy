<template>
    <!-- Compact mode: minimal phone frame for sidebar -->
    <div v-if="compact" class="flex flex-col items-center gap-3" style="width: 240px;">
        <div v-if="isLoading" class="flex flex-col items-center justify-center py-8">
            <ProgressSpinner strokeWidth="3" animationDuration=".8s" class="w-6 h-6"/>
        </div>
        <div v-else-if="accessError" class="flex flex-col items-center justify-center py-6 px-4 text-center">
            <i class="pi pi-exclamation-triangle text-red-400 text-lg mb-2"></i>
            <p class="text-xs text-slate-500 mb-2">{{ accessError }}</p>
            <Button
                :label="$t('dashboard.retry')"
                icon="pi pi-refresh"
                @click="loadPreview"
                size="small"
                text
            />
        </div>
        <PhoneIframePreview
            v-else
            :src="previewUrl"
            :iframeKey="previewUrl"
            :width="240"
            :title="cardProp?.name || 'Mobile Preview'"
            :loadingText="$t('dashboard.loading_mobile_preview')"
            :errorText="$t('dashboard.failed_load_preview_content')"
            :retryText="$t('dashboard.retry')"
            @error="handleIframeError"
        />
        <div class="flex items-center gap-1.5">
            <span class="text-[11px] text-slate-400 uppercase tracking-wide font-medium">{{ $t('dashboard.preview') }}</span>
            <Button
                icon="pi pi-refresh"
                size="small"
                severity="secondary"
                text
                @click="loadPreview"
                :loading="isLoading"
                v-tooltip.bottom="$t('dashboard.refresh_preview')"
                class="!w-6 !h-6"
            />
        </div>
    </div>

    <!-- Full mode: original layout with header + card wrapper -->
    <div v-else class="space-y-6">
        <!-- Preview Header with Explanation -->
        <div class="bg-gradient-to-r from-emerald-50 to-teal-50 rounded-xl p-4 border border-emerald-200">
            <div class="flex items-start gap-3">
                <div class="p-2 bg-emerald-100 rounded-lg flex-shrink-0">
                    <i class="pi pi-mobile text-emerald-600"></i>
                </div>
                <div class="flex-1">
                    <h3 class="text-base font-semibold text-emerald-900">{{ $t('dashboard.mobile_preview') }}</h3>
                    <p class="text-sm text-emerald-700 mt-1">{{ $t('dashboard.mobile_preview_explanation') }}</p>
                    <div class="flex items-center gap-2 mt-2">
                        <i class="pi pi-info-circle text-emerald-500 text-xs"></i>
                        <span class="text-xs text-emerald-600">{{ $t('dashboard.preview_auto_refresh_hint') }}</span>
                    </div>
                </div>
                <Button
                    icon="pi pi-refresh"
                    size="small"
                    severity="secondary"
                    outlined
                    @click="loadPreview"
                    :loading="isLoading"
                    v-tooltip.left="$t('dashboard.refresh_preview')"
                    class="flex-shrink-0"
                />
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
import { ref, computed, watch } from 'vue';
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
    },
    compact: {
        type: Boolean,
        default: false
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

// Watch for card changes (immediate: true handles initial mount)
watch(
    () => props.cardProp?.id,
    (newCardId) => {
        if (newCardId) {
            loadPreview();
        }
    },
    { immediate: true }
);
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
