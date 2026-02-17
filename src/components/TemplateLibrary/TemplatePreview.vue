<template>
  <div class="template-preview">
    <!-- Template Info -->
    <div class="preview-header">
      <div class="preview-thumbnail">
        <img 
          v-if="template.thumbnail_url" 
          :src="template.thumbnail_url" 
          :alt="template.name"
          class="thumbnail-image"
        />
        <div v-else class="thumbnail-placeholder">
          <i :class="getModeIcon(template.content_mode)" class="text-4xl"></i>
        </div>
      </div>
      
      <div class="preview-info">
        <p class="preview-description">{{ template.description }}</p>
        
        <!-- Tags -->
        <div class="preview-tags">
          <Tag v-if="template.venue_type" :value="formatVenueType(template.venue_type)" severity="secondary" />
          <Tag :value="getModeLabel(template.content_mode)" :severity="getModeSeverity(template.content_mode)" />
          <Tag v-if="template.is_grouped" :value="$t('templates.grouped')" severity="info" />
        </div>
      </div>
    </div>

    <!-- Content Structure Preview -->
    <div class="structure-section">
      <h4 class="section-title">
        <i class="pi pi-sitemap"></i>
        {{ $t('templates.content_structure') }}
      </h4>
      
      <div class="structure-preview">
        <!-- AI Config Preview -->
        <div v-if="template.ai_instruction" class="card-template-preview">
          <div class="template-field">
            <span class="field-label">{{ $t('templates.ai_instruction') }}:</span>
            <span class="field-value">{{ truncate(template.ai_instruction, 100) }}</span>
          </div>
        </div>
        <div v-if="template.ai_welcome_general" class="card-template-preview">
          <div class="template-field">
            <span class="field-label">{{ $t('templates.ai_welcome') }}:</span>
            <span class="field-value">{{ truncate(template.ai_welcome_general, 100) }}</span>
          </div>
        </div>

        <!-- Content Items Structure -->
        <div class="content-items-preview">
          <div class="items-header">
            <i class="pi pi-list"></i>
            <span>{{ template.item_count }} {{ $t('templates.content_items') }}</span>
          </div>
          
          <div v-if="contentStructure.length > 0" class="items-tree">
            <div 
              v-for="(item, index) in contentStructure.slice(0, 5)"
              :key="index"
              class="tree-item"
              :class="{ 'is-child': item.isChild }"
            >
              <i :class="item.isChild ? 'pi pi-angle-right' : 'pi pi-folder'"></i>
              <span>{{ item.name }}</span>
              <span v-if="item.childCount" class="child-count">({{ item.childCount }} {{ $t('templates.sub_items') }})</span>
            </div>
            <div v-if="contentStructure.length > 5" class="more-items">
              <i class="pi pi-ellipsis-h"></i>
              +{{ contentStructure.length - 5 }} {{ $t('templates.more_items') }}
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- AI Configuration -->
    <div v-if="hasAIConfig" class="ai-section">
      <h4 class="section-title">
        <i class="pi pi-sparkles"></i>
        {{ $t('templates.ai_configuration') }}
      </h4>
      <div class="ai-badges">
        <div v-if="template.conversation_ai_enabled !== false" class="ai-badge enabled">
          <i class="pi pi-check-circle"></i>
          {{ $t('templates.ai_enabled') }}
        </div>
        <div v-if="template.ai_knowledge_base" class="ai-badge">
          <i class="pi pi-book"></i>
          {{ $t('templates.has_knowledge_base') }}
        </div>
      </div>
    </div>

    <!-- Actions -->
    <div class="preview-actions">
      <Button 
        :label="$t('templates.use_template')"
        icon="pi pi-download"
        class="w-full bg-indigo-600 hover:bg-indigo-700 text-white border-0"
        @click="$emit('import', template)"
      />
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { useI18n } from 'vue-i18n'
import type { ContentTemplateDetails, ContentItemData } from '@/stores/templateLibrary'
import Tag from 'primevue/tag'
import Button from 'primevue/button'

const { t } = useI18n()

const props = defineProps<{
  template: ContentTemplateDetails
}>()

defineEmits<{
  import: [template: ContentTemplateDetails]
}>()

const contentStructure = computed(() => {
  if (!props.template.content_items) return []
  
  const items: Array<{ name: string; isChild: boolean; childCount?: number }> = []
  const contentItems = props.template.content_items as ContentItemData[]
  
  // Group by parent
  const parents = contentItems.filter(item => !item.parent_id)
  const children = contentItems.filter(item => item.parent_id)
  
  for (const parent of parents) {
    const childCount = children.filter(c => c.parent_id === parent.id).length
    items.push({ name: parent.name, isChild: false, childCount })
  }
  
  return items
})

const hasAIConfig = computed(() => {
  return props.template.conversation_ai_enabled || 
         props.template.ai_instruction || 
         props.template.ai_knowledge_base
})

function truncate(text: string, maxLength: number): string {
  if (!text) return ''
  return text.length > maxLength ? text.slice(0, maxLength) + '...' : text
}

function formatVenueType(type: string): string {
  return type.charAt(0).toUpperCase() + type.slice(1).replace(/_/g, ' ')
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

function getModeSeverity(mode: string): string {
  const severities: Record<string, string> = {
    single: 'success',
    list: 'info',
    grid: 'warn',
    cards: 'secondary'
  }
  return severities[mode] || 'secondary'
}
</script>

<style scoped>
.template-preview {
  @apply space-y-6;
}

.preview-header {
  @apply flex gap-4;
}

.preview-thumbnail {
  @apply w-32 h-32 bg-slate-100 rounded-lg overflow-hidden flex-shrink-0;
}

.thumbnail-image {
  @apply w-full h-full object-cover;
}

.thumbnail-placeholder {
  @apply w-full h-full flex items-center justify-center text-slate-400;
}

.preview-info {
  @apply flex-1 space-y-3;
}

.preview-description {
  @apply text-slate-600 text-sm leading-relaxed;
}

.preview-tags {
  @apply flex flex-wrap gap-2;
}

.structure-section,
.ai-section {
  @apply bg-slate-50 rounded-lg p-4;
}

.section-title {
  @apply flex items-center gap-2 text-sm font-semibold text-slate-900 mb-3;
}

.structure-preview {
  @apply space-y-4;
}

.card-template-preview {
  @apply space-y-2 text-sm;
}

.template-field {
  @apply flex flex-col gap-1;
}

.field-label {
  @apply text-slate-500 text-xs font-medium;
}

.field-value {
  @apply text-slate-700;
}

.content-items-preview {
  @apply bg-white rounded border border-slate-200 p-3;
}

.items-header {
  @apply flex items-center gap-2 text-sm font-medium text-slate-700 mb-2;
}

.items-tree {
  @apply space-y-1;
}

.tree-item {
  @apply flex items-center gap-2 text-sm text-slate-600 py-1 px-2 rounded;
}

.tree-item.is-child {
  @apply ml-4 text-slate-500;
}

.child-count {
  @apply text-xs text-slate-400;
}

.more-items {
  @apply flex items-center gap-2 text-xs text-slate-400 py-1 px-2;
}

.ai-badges {
  @apply flex flex-wrap gap-2;
}

.ai-badge {
  @apply inline-flex items-center gap-1 px-3 py-1 bg-white rounded-full text-sm text-slate-600 border border-slate-200;
}

.ai-badge.enabled {
  @apply bg-emerald-50 text-emerald-700 border-emerald-200;
}

.preview-actions {
  @apply pt-4 border-t border-slate-200;
}

/* Mobile responsive */
@media (max-width: 640px) {
  .preview-header {
    @apply flex-col;
  }
  
  .preview-thumbnail {
    @apply w-full h-40;
  }
}
</style>
