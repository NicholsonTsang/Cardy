<template>
    <div class="inline-flex items-center gap-1">
        <!-- Verified Badge -->
        <div v-if="isVerified" class="flex items-center gap-1">
            <i class="pi pi-verified text-blue-500" :class="iconSize" :title="title"></i>
            <span v-if="showLabel" class="text-xs font-medium text-blue-600">Verified</span>
        </div>
        
        <!-- Pending Badge -->
        <div v-else-if="isPending" class="flex items-center gap-1">
            <i class="pi pi-clock text-amber-500" :class="iconSize" title="Verification Pending"></i>
            <span v-if="showLabel" class="text-xs font-medium text-amber-600">Pending</span>
        </div>
        
        <!-- Rejected Badge -->
        <div v-else-if="isRejected" class="flex items-center gap-1">
            <i class="pi pi-times-circle text-red-500" :class="iconSize" title="Verification Rejected"></i>
            <span v-if="showLabel" class="text-xs font-medium text-red-600">Rejected</span>
        </div>
        
        <!-- No badge for unverified users unless showUnverified is true -->
        <div v-else-if="showUnverified" class="flex items-center gap-1">
            <i class="pi pi-user text-slate-400" :class="iconSize" title="Not Verified"></i>
            <span v-if="showLabel" class="text-xs font-medium text-slate-500">Unverified</span>
        </div>
    </div>
</template>

<script setup>
import { computed } from 'vue'

const props = defineProps({
    verificationStatus: {
        type: String,
        default: 'NOT_SUBMITTED',
        validator: (value) => ['NOT_SUBMITTED', 'PENDING_REVIEW', 'APPROVED', 'REJECTED'].includes(value)
    },
    verifiedAt: {
        type: String,
        default: null
    },
    showLabel: {
        type: Boolean,
        default: false
    },
    showUnverified: {
        type: Boolean,
        default: false
    },
    size: {
        type: String,
        default: 'medium',
        validator: (value) => ['small', 'medium', 'large'].includes(value)
    }
})

const isVerified = computed(() => {
    return props.verificationStatus === 'APPROVED' && props.verifiedAt
})

const isPending = computed(() => {
    return props.verificationStatus === 'PENDING_REVIEW'
})

const isRejected = computed(() => {
    return props.verificationStatus === 'REJECTED'
})

const iconSize = computed(() => {
    const sizes = {
        small: 'text-sm',
        medium: 'text-base',
        large: 'text-lg'
    }
    return sizes[props.size] || sizes.medium
})

const title = computed(() => {
    if (!isVerified.value) return 'Verified Account'
    
    const date = new Date(props.verifiedAt).toLocaleDateString('en-US', {
        year: 'numeric',
        month: 'long',
        day: 'numeric'
    })
    return `Verified on ${date}`
})
</script> 