<template>
    <div>
        <CardView 
            v-if="currentMode === 'view'" 
            :cardProp="cardProp" 
            @edit="switchToEditMode"
            @delete-requested="handleDeleteRequested"
        />
        <CardCreateEditForm 
            v-else 
            ref="formRef"
            :cardProp="cardProp" 
            :isEditMode="currentMode === 'edit'"
            @save="handleSave"
            @cancel="handleCancel"
        />
    </div>
</template>

<script setup>
import { ref, onMounted, watch } from 'vue';
import CardView from './Card.vue/CardView.vue';
import CardCreateEditForm from './Card.vue/CardCreateEditForm.vue';

const props = defineProps({
    cardProp: {
        type: Object,
        default: null
    },
    modeProp: {
        type: String,
        default: 'view',
        validator: (value) => ['view', 'create', 'edit'].includes(value)
    }
});

const emit = defineEmits(['create-card', 'update-card', 'cancel-edit', 'request-delete-card']);

const currentMode = ref(props.modeProp);
const formRef = ref(null);

// Watch for changes in modeProp
watch(() => props.modeProp, (newVal) => {
    currentMode.value = newVal;
});

onMounted(() => {
    currentMode.value = props.modeProp;
});

const switchToEditMode = () => {
    currentMode.value = 'edit';
};

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
/* Ensure consistent height for image preview area */
.h-90 { /* You might need to define this class if not already in Tailwind config or global styles */
    height: 22.5rem; /* Example: 90 * 0.25rem if your spacing unit is 0.25rem */
}
.w-60 {
    width: 15rem;
}
/* Optional: Customize FileUpload button appearance if needed */
.p-fileupload-basic .p-button {
    width: 100%;
    justify-content: center;
}
.aspect-\[3\/4\] { /* Added from CardGeneral */
    aspect-ratio: 3 / 4;
}

.view-section {
    display: flex;
    flex-direction: column;

    @container (min-width: 100px) {
        flex-direction: row;
    }
}

</style>
