<template>
  <div 
    class="template-card" 
    :class="{ 'featured': template.is_featured }"
    @click="$emit('preview', template)"
  >
    <!-- Card Content Row -->
    <div class="card-row">
      <!-- Icon/Avatar -->
      <div class="card-icon-wrapper">
        <div class="card-icon" :class="getIconBgClass(template.content_mode)">
          <img 
            v-if="template.thumbnail_url" 
            :src="template.thumbnail_url" 
            :alt="template.name"
            class="icon-image"
          />
          <i v-else :class="getModeIcon(template.content_mode)" class="icon-fallback"></i>
        </div>
        <!-- Mode Badge -->
        <div class="mode-badge" :class="getModeBadgeClass(template.content_mode)">
          <i :class="getModeSmallIcon(template.content_mode)"></i>
        </div>
      </div>

      <!-- Title & Type -->
      <div class="card-header">
        <h3 class="card-title">{{ template.name }}</h3>
        <span class="card-type">{{ getModeLabel(template.content_mode).toUpperCase() }}</span>
      </div>
    </div>

    <!-- Description -->
    <p class="card-description">{{ truncate(template.description, 150) }}</p>

    <!-- Featured Star -->
    <div v-if="template.is_featured" class="featured-star">
      <i class="pi pi-star-fill"></i>
    </div>
  </div>
</template>

<script setup lang="ts">
import { useI18n } from 'vue-i18n'
import type { ContentTemplate } from '@/stores/templateLibrary'

const { t } = useI18n()

defineProps<{
  template: ContentTemplate
}>()

defineEmits<{
  preview: [template: ContentTemplate]
  import: [template: ContentTemplate]
}>()

function truncate(text: string, maxLength: number): string {
  if (!text) return ''
  return text.length > maxLength ? text.slice(0, maxLength) + '...' : text
}

function getModeLabel(mode: string): string {
  const labels: Record<string, string> = {
    single: t('templates.mode_single'),
    list: t('templates.mode_list'),
    grid: t('templates.mode_grid'),
    cards: t('templates.mode_cards')
  }
  return labels[mode] || mode
}

function getModeIcon(mode: string): string {
  const icons: Record<string, string> = {
    single: 'pi pi-file',
    list: 'pi pi-list',
    grid: 'pi pi-th-large',
    cards: 'pi pi-clone'
  }
  return icons[mode] || 'pi pi-file'
}

function getModeSmallIcon(mode: string): string {
  const icons: Record<string, string> = {
    single: 'pi pi-file',
    list: 'pi pi-bars',
    grid: 'pi pi-th-large',
    cards: 'pi pi-clone'
  }
  return icons[mode] || 'pi pi-file'
}

function getIconBgClass(mode: string): string {
  const classes: Record<string, string> = {
    single: 'bg-emerald-100',
    list: 'bg-blue-100',
    grid: 'bg-amber-100',
    cards: 'bg-purple-100'
  }
  return classes[mode] || 'bg-slate-100'
}

function getModeBadgeClass(mode: string): string {
  const classes: Record<string, string> = {
    single: 'bg-emerald-500',
    list: 'bg-blue-500',
    grid: 'bg-amber-500',
    cards: 'bg-purple-500'
  }
  return classes[mode] || 'bg-slate-500'
}
</script>

<style scoped>
.template-card {
  @apply relative bg-white rounded-xl p-5 cursor-pointer transition-all duration-200;
  @apply hover:shadow-md hover:border-blue-200;
  border: 1px solid #e8ecf4;
}

.template-card.featured {
  @apply border-blue-200 bg-blue-50/30;
}

/* Card Row - Icon + Header */
.card-row {
  @apply flex items-start gap-4 mb-4;
}

/* Icon Wrapper */
.card-icon-wrapper {
  @apply relative flex-shrink-0;
}

.card-icon {
  @apply w-14 h-14 rounded-xl flex items-center justify-center overflow-hidden;
}

.icon-image {
  @apply w-full h-full object-cover;
}

.icon-fallback {
  @apply text-2xl text-slate-500;
}

/* Mode Badge - small circle at bottom-right of icon */
.mode-badge {
  @apply absolute -bottom-1 -right-1 w-5 h-5 rounded-full flex items-center justify-center text-white text-xs;
}

.mode-badge i {
  @apply text-[10px];
}

/* Card Header */
.card-header {
  @apply flex-1 min-w-0;
}

.card-title {
  @apply font-semibold text-slate-900 text-base leading-tight mb-1;
  @apply overflow-hidden text-ellipsis whitespace-nowrap;
}

.card-type {
  @apply text-xs font-medium text-slate-400 tracking-wide;
}

/* Description */
.card-description {
  @apply text-sm text-slate-600 leading-relaxed;
  display: -webkit-box;
  -webkit-line-clamp: 3;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

/* Featured Star */
.featured-star {
  @apply absolute top-4 right-4 text-amber-400;
}

/* Mobile responsive */
@media (max-width: 640px) {
  .template-card {
    @apply p-4;
  }
  
  .card-icon {
    @apply w-12 h-12;
  }
  
  .icon-fallback {
    @apply text-xl;
  }
  
  .card-description {
    -webkit-line-clamp: 2;
  }
}
</style>

