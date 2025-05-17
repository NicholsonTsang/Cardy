<template>
    <CardCreateEditView
        :cardProp="card"
        modeProp="view"
        @create-card="handleCreateCard"
        @update-card="handleUpdateCard"
        @cancel-edit="handleCancelEdit"
        @request-delete-card="handleDeleteCardRequested"
    />
</template>

<script setup>
import CardCreateEditView from './CardCreateEditView.vue';

const props = defineProps({
    card: {
        type: Object,
        default: () => null // Allow null if no card is selected/available
    }
});

const emit = defineEmits(['create-card', 'update-card', 'cancel-edit', 'delete-card-requested']);

// Re-emit events from CardCreateEditView so parent components can listen to them
const handleCreateCard = (payload) => {
    emit('create-card', payload);
};

const handleUpdateCard = (payload) => {
    emit('update-card', payload);
};

const handleCancelEdit = () => {
    emit('cancel-edit');
};

const handleDeleteCardRequested = (cardId) => {
    emit('delete-card-requested', cardId);
};
</script>

<style scoped>
/* Styles for CardGeneral itself, if any, can go here. */
/* The aspect-ratio style is now in CardCreateEditView's view mode */
</style>
