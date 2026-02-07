<template>
    <div
        class="relative rounded-lg border transition-all duration-200 overflow-hidden bg-white cursor-pointer"
        :class="itemClasses"
        @click="handleClick"
    >
        <div class="flex items-center gap-2.5 p-3">
            <!-- Multi-select checkbox -->
            <div
                v-if="multiSelectMode"
                class="flex-shrink-0 w-[18px] h-[18px] rounded-full border-2 flex items-center justify-center transition-all"
                :class="isChecked
                    ? 'bg-indigo-600 border-indigo-600'
                    : 'border-slate-300 hover:border-slate-400'"
                @click.stop="toggleCheck"
            >
                <i v-if="isChecked" class="pi pi-check text-white text-[8px]"></i>
            </div>

            <!-- Thumbnail -->
            <div
                class="flex-shrink-0 w-9 h-9 rounded-md overflow-hidden flex items-center justify-center"
                :class="card.billing_type === 'digital'
                    ? 'bg-sky-50'
                    : 'bg-slate-100'"
            >
                <i v-if="card.billing_type === 'digital'" class="pi pi-qrcode text-sky-500 text-sm"></i>
                <img v-else :src="displayImage" :alt="card.name" class="w-full h-full object-cover" />
            </div>

            <!-- Name -->
            <span class="flex-1 min-w-0 text-[13px] font-medium text-slate-800 line-clamp-2">
                {{ card.name }}
                <span v-if="card.is_template" class="text-amber-400 text-[11px] ml-0.5">&#11088;</span>
            </span>

            <!-- Relative date -->
            <span class="text-[11px] text-slate-400 flex-shrink-0 tabular-nums self-start mt-0.5">{{ relativeDate }}</span>
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

const itemClasses = computed(() => {
    if (props.isSelected && !props.multiSelectMode) {
        return 'border-blue-500 border-l-[3px] shadow-sm bg-blue-50/30';
    }
    if (props.isChecked) {
        return 'border-indigo-400 bg-indigo-50/30';
    }
    return 'border-slate-200 hover:border-slate-300 hover:shadow-sm';
});

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

const relativeDate = computed(() => {
    if (!props.card.created_at) return '';
    const now = Date.now();
    const created = new Date(props.card.created_at).getTime();
    const diffMs = now - created;
    const diffMin = Math.floor(diffMs / 60000);
    if (diffMin < 1) return t('common.just_now');
    if (diffMin < 60) return `${diffMin}m`;
    const diffHr = Math.floor(diffMin / 60);
    if (diffHr < 24) return `${diffHr}h`;
    const diffDay = Math.floor(diffHr / 24);
    if (diffDay < 30) return `${diffDay}d`;
    const diffMo = Math.floor(diffDay / 30);
    if (diffMo < 12) return `${diffMo}mo`;
    const diffYr = Math.floor(diffDay / 365);
    return `${diffYr}y`;
});
</script>
