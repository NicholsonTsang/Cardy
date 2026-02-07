<template>
    <div class="space-y-5">
        <!-- Access Type (only if physical cards enabled) -->
        <div v-if="isPhysicalCardsEnabled">
            <label class="block text-sm font-medium text-slate-700 mb-2">{{ $t('dashboard.access_mode') }}</label>
            <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
                <!-- Physical Card Option -->
                <button
                    type="button"
                    @click="formData.billing_type = 'physical'"
                    class="p-3.5 rounded-xl border-2 transition-all cursor-pointer w-full text-left"
                    :class="formData.billing_type === 'physical'
                        ? 'border-purple-400 bg-purple-50/50 shadow-sm'
                        : 'border-slate-200 bg-white hover:border-slate-300 hover:bg-slate-50'"
                >
                    <div class="flex items-start gap-3">
                        <div class="w-10 h-10 rounded-lg flex items-center justify-center flex-shrink-0 transition-colors"
                             :class="formData.billing_type === 'physical' ? 'bg-purple-100' : 'bg-slate-100'">
                            <i class="pi pi-credit-card" :class="formData.billing_type === 'physical' ? 'text-purple-600' : 'text-slate-400'"></i>
                        </div>
                        <div class="flex-1 min-w-0">
                            <span class="font-semibold text-sm" :class="formData.billing_type === 'physical' ? 'text-purple-900' : 'text-slate-700'">
                                {{ $t('dashboard.physical_card') }}
                            </span>
                            <p class="text-xs text-slate-500 mt-1 line-clamp-2">{{ $t('dashboard.physical_card_full_desc') }}</p>
                        </div>
                    </div>
                </button>

                <!-- Digital Access Option -->
                <button
                    type="button"
                    @click="formData.billing_type = 'digital'"
                    class="p-3.5 rounded-xl border-2 transition-all cursor-pointer w-full text-left"
                    :class="formData.billing_type === 'digital'
                        ? 'border-cyan-400 bg-cyan-50/50 shadow-sm'
                        : 'border-slate-200 bg-white hover:border-slate-300 hover:bg-slate-50'"
                >
                    <div class="flex items-start gap-3">
                        <div class="w-10 h-10 rounded-lg flex items-center justify-center flex-shrink-0 transition-colors"
                             :class="formData.billing_type === 'digital' ? 'bg-cyan-100' : 'bg-slate-100'">
                            <i class="pi pi-qrcode" :class="formData.billing_type === 'digital' ? 'text-cyan-600' : 'text-slate-400'"></i>
                        </div>
                        <div class="flex-1 min-w-0">
                            <span class="font-semibold text-sm" :class="formData.billing_type === 'digital' ? 'text-cyan-900' : 'text-slate-700'">
                                {{ $t('dashboard.digital_access') }}
                            </span>
                            <p class="text-xs text-slate-500 mt-1 line-clamp-2">{{ $t('dashboard.digital_access_full_desc') }}</p>
                        </div>
                    </div>
                </button>
            </div>
        </div>

        <!-- Project Name -->
        <div>
            <label for="createCardName" class="block text-sm font-medium text-slate-700 mb-1.5">
                {{ formData.billing_type === 'digital' ? $t('dashboard.qr_name') : $t('dashboard.card_name') }}
                <span class="text-red-500">*</span>
            </label>
            <InputText
                id="createCardName"
                type="text"
                v-model="formData.name"
                class="w-full"
                :class="{ 'p-invalid': !formData.name.trim() && showValidation }"
                :placeholder="formData.billing_type === 'digital' ? $t('dashboard.enter_qr_name') : $t('dashboard.enter_card_name')"
                @keydown.enter="handleCreate"
            />
            <p v-if="!formData.name.trim() && showValidation" class="text-xs text-red-500 mt-1">{{ $t('dashboard.card_name_required') }}</p>
        </div>

        <!-- Original Language -->
        <div>
            <label for="createLanguage" class="block text-sm font-medium text-slate-700 mb-1.5">
                {{ $t('dashboard.originalLanguage') }}
            </label>
            <Dropdown
                id="createLanguage"
                v-model="formData.original_language"
                :options="languageOptions"
                optionLabel="label"
                optionValue="value"
                :placeholder="$t('dashboard.selectLanguage')"
                class="w-full"
            >
                <template #value="slotProps">
                    <div v-if="slotProps.value" class="flex items-center gap-2">
                        <span>{{ getLanguageFlag(slotProps.value) }}</span>
                        <span>{{ SUPPORTED_LANGUAGES[slotProps.value] }}</span>
                    </div>
                    <span v-else>{{ slotProps.placeholder }}</span>
                </template>
                <template #option="slotProps">
                    <div class="flex items-center gap-2">
                        <span>{{ slotProps.option.flag }}</span>
                        <span>{{ slotProps.option.label }}</span>
                    </div>
                </template>
            </Dropdown>
        </div>

        <!-- Footer -->
        <div class="flex items-center justify-between pt-4 border-t border-slate-200">
            <Button
                :label="$t('common.cancel')"
                severity="secondary"
                text
                size="small"
                @click="$emit('cancel')"
            />
            <Button
                :label="$t('dashboard.wizard_create_now')"
                icon="pi pi-plus"
                size="small"
                severity="primary"
                :loading="isCreating"
                :disabled="isCreating"
                @click="handleCreate"
            />
        </div>
    </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import Button from 'primevue/button';
import InputText from 'primevue/inputtext';
import Dropdown from 'primevue/dropdown';
import { SUPPORTED_LANGUAGES } from '@/stores/translation';
import { getLanguageFlag } from '@/utils/formatters';
import { usePhysicalCards } from '@/composables/usePhysicalCards';

const emit = defineEmits(['submit', 'cancel']);
const { t } = useI18n();
const { isPhysicalCardsEnabled, getDefaultBillingType } = usePhysicalCards();

// State
const isCreating = ref(false);
const showValidation = ref(false);

// Form data with sensible defaults
const formData = reactive({
    name: '',
    description: '',
    original_language: 'en',
    billing_type: getDefaultBillingType.value,
    content_mode: 'list',
    is_grouped: false,
    group_display: 'expanded',
    conversation_ai_enabled: false,
    ai_instruction: '',
    ai_knowledge_base: '',
    ai_welcome_general: '',
    ai_welcome_item: '',
    qr_code_position: 'BR',
    default_daily_session_limit: 500,
    cropParameters: null as any,
    max_sessions: null as number | null,
});

// Language options
const languageOptions = computed(() => {
    return Object.entries(SUPPORTED_LANGUAGES).map(([code, name]) => ({
        value: code,
        label: name,
        flag: getLanguageFlag(code)
    }));
});

// Submit
const handleCreate = () => {
    showValidation.value = true;
    if (!formData.name.trim()) return;

    isCreating.value = true;
    const payload = {
        ...formData,
        default_daily_session_limit: formData.billing_type === 'digital' ? formData.default_daily_session_limit : null,
    };
    emit('submit', payload);
};

// Reset
const resetForm = () => {
    showValidation.value = false;
    isCreating.value = false;
    formData.name = '';
    formData.description = '';
    formData.original_language = 'en';
    formData.billing_type = getDefaultBillingType.value;
    formData.content_mode = 'list';
    formData.is_grouped = false;
    formData.group_display = 'expanded';
    formData.conversation_ai_enabled = false;
    formData.ai_instruction = '';
    formData.ai_knowledge_base = '';
    formData.ai_welcome_general = '';
    formData.ai_welcome_item = '';
    formData.qr_code_position = 'BR';
    formData.default_daily_session_limit = 500;
    formData.cropParameters = null;
    formData.max_sessions = null;
};

defineExpose({ resetForm });
</script>
