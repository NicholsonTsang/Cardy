<template>
    <div>
        <div class="mb-2 flex justify-end gap-2" v-if="cardProp">
            <Button label="Edit Card" icon="pi pi-pencil" @click="handleEdit" severity="info" size="small"/>
            <Button label="Delete Card" icon="pi pi-trash" @click="handleRequestDelete" severity="danger" size="small"/>
        </div>

        <div v-if="cardProp" class="p-4 border border-gray-200 rounded-lg flex flex-col 2xl:flex-row">
            <!-- Artwork Display -->
            <div class="mb-4 mr-8">
                <div class="font-semibold mb-2 text-gray-700">Card Artwork</div>
                <img
                    :src="displayImageForView"
                    alt="Card Artwork"
                    class="w-60 h-auto object-cover rounded-md border border-gray-300 aspect-[3/4]"
                />
            </div>

            <!-- Details Display -->
            <div>
                <div class="mb-4">
                    <div class="font-semibold text-gray-700">Card Name</div>
                    <p class="text-gray-600">{{ cardProp.name || 'N/A' }}</p>
                </div>

                <div class="mb-4">
                    <div class="font-semibold text-gray-700">Description</div>
                    <p class="text-gray-600 whitespace-pre-wrap">{{ cardProp.description || 'No description provided.' }}</p>
                </div>

                <div class="mb-4">
                    <div class="font-semibold text-gray-700">QR Code Position</div>
                    <p class="text-gray-600">{{ displayQrCodePositionForView || 'N/A' }}</p>
                </div>
                
                <div class="mb-4">
                    <div class="font-semibold text-gray-700">Conversation AI Enabled</div>
                    <p class="text-gray-600">{{ cardProp.conversation_ai_enabled ? 'Yes' : 'No' }}</p>
                </div>

                <div class="mb-4" v-if="cardProp.conversation_ai_enabled">
                    <div class="font-semibold text-gray-700">AI Prompt</div>
                    <p class="text-gray-600 whitespace-pre-wrap">{{ cardProp.ai_prompt || 'No AI prompt provided.' }}</p>
                </div>

                <div class="mb-4">
                    <div class="font-semibold text-gray-700">Published</div>
                    <p class="text-gray-600">{{ cardProp.published ? 'Yes' : 'No' }}</p>
                </div>

                <div v-if="cardProp.created_at" class="mb-4">
                    <div class="font-semibold text-gray-700">Created</div>
                    <p class="text-gray-600">{{ new Date(cardProp.created_at).toLocaleString() }}</p>
                </div>

                <div v-if="cardProp.updated_at" class="mb-4">
                    <div class="font-semibold text-gray-700">Last Updated</div>
                    <p class="text-gray-600">{{ new Date(cardProp.updated_at).toLocaleString() }}</p>
                </div>
            </div>
        </div>
    </div>
</template>

<script setup>
import { computed } from 'vue';
import Button from 'primevue/button';

const props = defineProps({
    cardProp: {
        type: Object,
        default: null
    }
});

const emit = defineEmits(['edit', 'delete-requested']);

const displayImageForView = computed(() => {
    if (props.cardProp && props.cardProp.image_urls && props.cardProp.image_urls.length > 0) {
        return props.cardProp.image_urls[0];
    }
    return null;
});

const displayQrCodePositionForView = computed(() => {
    if (!props.cardProp || !props.cardProp.qr_code_position) return null;
    
    const positions = {
        'TL': 'Top Left',
        'TR': 'Top Right',
        'BL': 'Bottom Left',
        'BR': 'Bottom Right'
    };
    
    return positions[props.cardProp.qr_code_position] || props.cardProp.qr_code_position;
});

const handleEdit = () => {
    emit('edit');
};

const handleRequestDelete = () => {
    if (props.cardProp && props.cardProp.id) {
        emit('delete-requested', props.cardProp.id);
    }
};
</script>

<style scoped>
.aspect-\[3\/4\] {
    aspect-ratio: 3 / 4;
}
.w-60 {
    width: 15rem;
}
</style>
