<template>
  <div class="page-wrapper">
    <!-- Page Header -->
    <div v-if="showHeader" class="page-header">
      <div class="max-w-7xl mx-auto px-3 sm:px-4 lg:px-8 py-4 sm:py-6">
        <div class="flex items-center justify-between">
          <div>
            <h1 v-if="title" class="text-xl sm:text-2xl font-bold text-slate-900">{{ title }}</h1>
            <p v-if="description" class="text-sm sm:text-base text-slate-600 mt-1">{{ description }}</p>
          </div>
          <div v-if="$slots.actions" class="flex items-center space-x-2 sm:space-x-3">
            <slot name="actions" />
          </div>
        </div>
      </div>
    </div>

    <!-- Page Content -->
    <div class="page-content">
      <div class="max-w-7xl mx-auto px-3 sm:px-4 lg:px-8 py-4 sm:py-6">
        <slot />
      </div>
    </div>
  </div>
</template>

<script setup>
defineProps({
  title: {
    type: String,
    default: ''
  },
  description: {
    type: String,
    default: ''
  },
  showHeader: {
    type: Boolean,
    default: true
  }
})
</script>

<style scoped>
.page-wrapper {
  @apply min-h-screen;
}

.page-header {
  @apply bg-white border-b border-slate-200;
}

.page-content {
  @apply bg-slate-50 flex-1;
}
</style>