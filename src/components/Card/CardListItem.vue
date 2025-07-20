<template>
    <div 
        class="group relative p-4 rounded-lg border border-slate-200 cursor-pointer transition-all duration-200 hover:shadow-md hover:border-blue-300"
        :class="{ 
            'bg-blue-50 border-blue-300 shadow-md': isSelected,
            'bg-white hover:bg-slate-50': !isSelected
        }"
        @click="$emit('select')"
    >
        <div class="flex items-start gap-3">
            <!-- Card Thumbnail -->
            <div class="flex-shrink-0 w-12 h-16 bg-slate-100 rounded-lg overflow-hidden border border-slate-200">
                <img
                    :src="displayImage"
                    :alt="card.name"
                    class="w-full h-full object-cover"
                />
            </div>
            
            <!-- Card Info -->
            <div class="flex-1 min-w-0">
                <h3 class="font-medium text-slate-900 truncate group-hover:text-blue-600 transition-colors">
                    {{ card.name }}
                </h3>
                <p class="text-sm text-slate-500 mt-1">
                    Created {{ formatDate(card.created_at) }}
                </p>
                <div v-if="card.description" class="text-xs text-slate-400 mt-1 line-clamp-2">
                    {{ card.description }}
                </div>
            </div>
        </div>
        
        <!-- Selection Indicator -->
        <div v-if="isSelected" class="absolute top-2 right-2">
            <div class="w-3 h-3 bg-blue-500 rounded-full"></div>
        </div>
    </div>
</template>

<script setup>
import { computed } from 'vue';
import cardPlaceholder from '@/assets/images/card-placeholder.jpg';

const props = defineProps({
    card: {
        type: Object,
        required: true
    },
    isSelected: {
        type: Boolean,
        default: false
    }
});

const emit = defineEmits(['select']);

const displayImage = computed(() => {
    return props.card.image_url 
        ? props.card.image_url 
        : cardPlaceholder;
});

const formatDate = (dateString) => {
    if (!dateString) return 'Unknown';
    const date = new Date(dateString);
    return date.toLocaleDateString('en-US', {
        month: 'short',
        day: 'numeric',
        year: 'numeric'
    });
};
</script>

<style scoped>
.line-clamp-2 {
    display: -webkit-box;
    -webkit-line-clamp: 2;
    -webkit-box-orient: vertical;
    overflow: hidden;
}
</style>