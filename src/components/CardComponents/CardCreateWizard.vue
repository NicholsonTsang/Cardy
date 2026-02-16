<template>
    <div class="space-y-5">
        <!-- Project Name -->
        <div>
            <label for="createCardName" class="block text-sm font-medium text-slate-700 mb-1.5">
                {{ $t('dashboard.qr_name') }}
                <span class="text-red-500">*</span>
            </label>
            <InputText
                id="createCardName"
                type="text"
                v-model="formData.name"
                class="w-full"
                :class="{ 'p-invalid': !formData.name.trim() && showValidation }"
                :placeholder="$t('dashboard.enter_qr_name')"
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

const emit = defineEmits(['submit', 'cancel']);
const { t } = useI18n();

// State
const isCreating = ref(false);
const showValidation = ref(false);

// Form data with sensible defaults
const formData = reactive({
    name: '',
    description: '',
    original_language: 'en',
    billing_type: 'digital',
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
        default_daily_session_limit: formData.default_daily_session_limit,
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
    formData.billing_type = 'digital';
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
