<template>
    <div 
        class="group relative p-4 rounded-xl border cursor-pointer transition-all duration-200 hover:shadow-lg hover:-translate-y-0.5"
        :class="{ 
            'bg-blue-50 border-blue-300 shadow-md ring-2 ring-blue-200': isSelected && !multiSelectMode,
            'bg-white hover:bg-slate-50/80 border-slate-200 hover:border-slate-300': !isSelected && !isChecked,
            'bg-indigo-50 border-indigo-300 ring-2 ring-indigo-200': isChecked
        }"
        @click="handleClick"
    >
        <!-- Multi-select checkbox overlay -->
        <div 
            v-if="multiSelectMode" 
            class="absolute top-3 left-3 z-10" 
            @click.stop="toggleCheck"
        >
            <div 
                class="w-5 h-5 rounded-full border-2 flex items-center justify-center transition-all cursor-pointer shadow-sm bg-white"
                :class="isChecked 
                    ? 'bg-indigo-600 border-indigo-600 scale-110' 
                    : 'border-slate-300 hover:border-indigo-400'"
            >
                <i v-if="isChecked" class="pi pi-check text-white text-[10px]"></i>
            </div>
        </div>

        <!-- Main Content -->
        <div class="flex gap-3">
            <!-- Thumbnail -->
            <div 
                class="flex-shrink-0 w-14 h-14 rounded-lg overflow-hidden border-2 flex items-center justify-center shadow-sm"
                :class="card.billing_type === 'digital' 
                    ? 'bg-gradient-to-br from-sky-100 to-blue-100 border-sky-200' 
                    : 'bg-slate-100 border-slate-200'"
            >
                <i v-if="card.billing_type === 'digital'" class="pi pi-qrcode text-sky-600 text-2xl"></i>
                <img
                    v-else
                    :src="displayImage"
                    :alt="card.name"
                    class="w-full h-full object-cover"
                />
            </div>
            
            <!-- Info -->
            <div class="flex-1 min-w-0 flex flex-col justify-center">
                <!-- Title Row -->
                <div class="flex items-start gap-2">
                    <h3 class="font-semibold text-slate-800 leading-tight group-hover:text-blue-600 transition-colors line-clamp-2">
                        {{ card.name }}
                    </h3>
                    <!-- Template indicator (small star) -->
                    <span 
                        v-if="card.is_template"
                        class="flex-shrink-0 text-amber-500 text-sm"
                        :title="card.template_slug ? `Template: ${card.template_slug}` : 'Linked to Template'"
                    >
                        ⭐
                    </span>
                </div>
                
                <!-- Meta Row: Compact inline info -->
                <div class="flex items-center gap-1.5 mt-1 text-[11px] font-medium text-slate-500">
                    <span :class="card.billing_type === 'digital' ? 'text-sky-600' : 'text-emerald-600'">
                        {{ card.billing_type === 'digital' ? 'Digital' : 'Physical' }}
                    </span>
                    <span class="text-slate-300">·</span>
                    <span :class="contentModeColor">
                        {{ contentModeLabel }}
                    </span>
                    <span v-if="card.is_grouped" class="text-slate-300">·</span>
                    <span v-if="card.is_grouped" class="text-violet-600">Grouped</span>
                </div>
                
                <!-- Date Row -->
                <div class="text-[10px] text-slate-400 mt-1">
                    {{ formatDate(card.created_at) }}
                </div>
            </div>
        </div>

        <!-- Selection Indicator -->
        <div v-if="isSelected && !multiSelectMode" class="absolute top-3 right-3">
            <div class="w-2 h-2 bg-blue-500 rounded-full"></div>
        </div>
    </div>
</template>

<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import cardPlaceholder from '@/assets/images/card-placeholder.jpg';

const { t } = useI18n();

const props = defineProps({
    card: {
        type: Object,
        required: true
    },
    isSelected: {
        type: Boolean,
        default: false
    },
    multiSelectMode: {
        type: Boolean,
        default: false
    },
    isChecked: {
        type: Boolean,
        default: false
    }
});

const emit = defineEmits(['select', 'toggle-check']);

function handleClick() {
    if (props.multiSelectMode) {
        toggleCheck();
    } else {
        emit('select');
    }
}

function toggleCheck() {
    emit('toggle-check', props.card.id);
}

const displayImage = computed(() => {
    return props.card.image_url 
        ? props.card.image_url 
        : cardPlaceholder;
});

// Content mode display
const contentModeLabels = {
    single: 'Single',
    list: 'List',
    grid: 'Grid',
    cards: 'Cards'
};

const contentModeColors = {
    single: 'text-purple-600',
    list: 'text-blue-600',
    grid: 'text-amber-600',
    cards: 'text-rose-600'
};

const contentModeLabel = computed(() => {
    const mode = props.card.content_mode || 'list';
    return contentModeLabels[mode] || 'List';
});

const contentModeColor = computed(() => {
    const mode = props.card.content_mode || 'list';
    return contentModeColors[mode] || 'text-blue-600';
});

const formatDate = (dateString) => {
    if (!dateString) return '';
    const date = new Date(dateString);
    return date.toLocaleDateString('en-US', {
        month: 'short',
        day: 'numeric'
    });
};
</script>

<style scoped>
.line-clamp-2 {
    display: -webkit-box;
    -webkit-line-clamp: 2;
    -webkit-box-orient: vertical;
    overflow: hidden;
    line-clamp: 2;
}
</style>
