<template>
    <div class="text-center py-8">
        <div class="w-16 h-16 bg-slate-100 rounded-full flex items-center justify-center mb-4 mx-auto">
            <i :class="iconClass" class="text-2xl text-slate-400"></i>
        </div>
        <h3 class="text-lg font-medium text-slate-900 mb-2">{{ title }}</h3>
        <p class="text-slate-500 mb-4">{{ description }}</p>
        
        <!-- Optional Call-to-Action Button -->
        <Button 
            v-if="showButton && buttonLabel"
            :icon="buttonIcon"
            :label="buttonLabel"
            :severity="buttonSeverity"
            :outlined="buttonOutlined"
            @click="$emit('action')"
            class="mt-2"
        />
        
        <!-- Optional Secondary Action -->
        <div v-if="secondaryAction" class="mt-3">
            <Button 
                :label="secondaryAction.label"
                :icon="secondaryAction.icon"
                text
                size="small"
                @click="$emit('secondary-action')"
            />
        </div>
    </div>
</template>

<script setup>
import Button from 'primevue/button';
import { computed } from 'vue';

const props = defineProps({
    // Icon configuration
    icon: {
        type: String,
        default: 'pi pi-inbox'
    },
    
    // Content
    title: {
        type: String,
        required: true
    },
    description: {
        type: String,
        required: true
    },
    
    // Primary action button
    buttonLabel: {
        type: String,
        default: null
    },
    buttonIcon: {
        type: String,
        default: 'pi pi-plus'
    },
    buttonSeverity: {
        type: String,
        default: 'primary'
    },
    buttonOutlined: {
        type: Boolean,
        default: false
    },
    showButton: {
        type: Boolean,
        default: true
    },
    
    // Secondary action
    secondaryAction: {
        type: Object,
        default: null
        // Expected format: { label: 'Action', icon: 'pi pi-icon' }
    },
    
    // State-specific styling
    variant: {
        type: String,
        default: 'default',
        validator: (value) => ['default', 'positive', 'search', 'error'].includes(value)
    }
});

const emit = defineEmits(['action', 'secondary-action']);

const iconClass = computed(() => {
    // Add variant-specific styling
    const baseClass = props.icon;
    
    switch (props.variant) {
        case 'positive':
            return `${baseClass.replace('text-slate-400', '')} text-green-500`;
        case 'search':
            return `${baseClass.replace('text-slate-400', '')} text-slate-300`;
        case 'error':
            return `${baseClass.replace('text-slate-400', '')} text-red-400`;
        default:
            return baseClass;
    }
});
</script>

<style scoped>
/* Component uses global theme styles */
</style>