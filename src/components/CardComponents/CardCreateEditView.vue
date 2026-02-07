<template>
    <div>
        <CardView 
            v-if="currentMode === 'view'" 
            :cardProp="cardProp" 
            :updateCardFn="updateCardFn"
            @delete-requested="handleDeleteRequested"
            @update-card="handleUpdateCard"
        />
        <CardCreateEditForm 
            v-else 
            ref="formRef"
            :cardProp="cardProp" 
            :isEditMode="currentMode === 'edit'"
            :loading="loading"
            @save="handleSave"
            @cancel="handleCancel"
        />
    </div>
</template>

<script setup>
import { ref, watch } from 'vue';
import CardView from './CardView.vue';
import CardCreateEditForm from './CardCreateEditForm.vue';

const props = defineProps({
    cardProp: {
        type: Object,
        default: null
    },
    modeProp: {
        type: String,
        default: 'view',
        validator: (value) => ['view', 'create', 'edit'].includes(value)
    },
    loading: {
        type: Boolean,
        default: false
    },
    updateCardFn: {
        type: Function,
        default: null
    }
});

const emit = defineEmits(['create-card', 'update-card', 'cancel-edit', 'request-delete-card']);

const currentMode = ref(props.modeProp);
const formRef = ref(null);

// Watch for changes in modeProp
watch(() => props.modeProp, (newVal) => {
    currentMode.value = newVal;
});

const handleSave = (payload) => {
    if (currentMode.value === 'create') {
        emit('create-card', payload);
    } else {
        emit('update-card', payload);
    }
    
    if (currentMode.value === 'edit') {
        currentMode.value = 'view';
    }
};

const handleUpdateCard = (payload) => {
    emit('update-card', payload);
};

const handleCancel = () => {
    if (currentMode.value === 'edit') {
        currentMode.value = 'view';
    }
    emit('cancel-edit');
};

const handleDeleteRequested = (cardId) => {
    emit('request-delete-card', cardId);
};

// Public methods exposed to parent components
const resetFormForCreate = () => {
    currentMode.value = 'create';
    if (formRef.value) {
        formRef.value.resetForm();
    }
};

const getPayload = () => {
    if (formRef.value) {
        return formRef.value.getPayload();
    }
    return {};
};

defineExpose({
    resetFormForCreate,
    getPayload
});
</script>

<style scoped>
/* Component-specific styles - styles now handled by global theme */
</style>
