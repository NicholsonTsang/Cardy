<template>
    <div class="bg-gradient-to-r from-blue-50 to-indigo-50 border border-blue-200 rounded-lg p-4">
        <label class="flex items-center gap-2 text-sm font-medium text-blue-900 mb-2">
            <i class="pi pi-sparkles"></i>
            {{ label }}
            <span class="text-xs text-blue-600 ml-auto">{{ wordCount }}/500 {{ $t('dashboard.words') }}</span>
        </label>
        <Textarea 
            :modelValue="modelValue"
            @update:modelValue="$emit('update:modelValue', $event)"
            rows="4" 
            class="w-full px-4 py-3 border border-blue-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors resize-none bg-white" 
            :class="{ 'border-red-500': wordCount > 500 }"
            :placeholder="placeholder"
            autoResize
        />
        <div v-if="hint" class="mt-2 p-2 bg-blue-50 border border-blue-100 rounded">
            <p class="text-xs text-blue-700 flex items-start gap-1">
                <i class="pi pi-info-circle mt-0.5 flex-shrink-0"></i>
                <span>{{ hint }}</span>
            </p>
        </div>
    </div>
</template>

<script setup>
import { computed } from 'vue';
import Textarea from 'primevue/textarea';

const props = defineProps({
    modelValue: {
        type: String,
        default: ''
    },
    label: {
        type: String,
        required: true
    },
    placeholder: {
        type: String,
        default: ''
    },
    hint: {
        type: String,
        default: ''
    }
});

defineEmits(['update:modelValue']);

const wordCount = computed(() => {
    return (props.modelValue || '').trim().split(/\s+/).filter(word => word.length > 0).length;
});
</script>

