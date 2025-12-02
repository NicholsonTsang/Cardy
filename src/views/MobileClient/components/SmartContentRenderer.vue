<template>
  <div class="smart-content-renderer">
    <!-- SINGLE Mode: One full-page content item -->
    <LayoutSingle 
      v-if="detectedLayout === 'single'"
      :card="card"
      :item="singleItem"
      :available-languages="availableLanguages"
      :has-header="hasHeader"
    />

    <!-- GROUPED Mode: Categories with sub-items -->
    <LayoutGrouped 
      v-else-if="detectedLayout === 'grouped'"
      :card="card"
      :items="parentItems"
      :all-items="allItems"
      :available-languages="availableLanguages"
      :has-header="hasHeader"
      @select="handleSelect"
    />

    <!-- LIST Mode: Simple vertical list -->
    <LayoutList 
      v-else-if="detectedLayout === 'list'"
      :card="card"
      :items="items"
      :available-languages="availableLanguages"
      :has-header="hasHeader"
      @select="handleSelect"
    />

    <!-- GRID Mode: 2-column visual grid -->
    <LayoutGrid 
      v-else-if="detectedLayout === 'grid'"
      :card="card"
      :items="items"
      :all-items="allItems"
      :available-languages="availableLanguages"
      :has-header="hasHeader"
      @select="handleSelect"
    />

    <!-- INLINE Mode: Horizontal scrollable cards -->
    <LayoutInline 
      v-else
      :card="card"
      :items="items"
      :all-items="allItems"
      :available-languages="availableLanguages"
      :has-header="hasHeader"
      @select="handleSelect"
    />
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted } from 'vue'
import { getContentAspectRatio } from '@/utils/cardConfig'
import LayoutSingle from './LayoutSingle.vue'
import LayoutGrouped from './LayoutGrouped.vue'
import LayoutList from './LayoutList.vue'
import LayoutGrid from './LayoutGrid.vue'
import LayoutInline from './LayoutInline.vue'

interface ContentItem {
  content_item_id: string
  content_item_parent_id: string | null
  content_item_name: string
  content_item_content: string
  content_item_image_url: string
  content_item_ai_knowledge_base: string
  content_item_ai_metadata?: string
  content_item_sort_order: number
  crop_parameters?: any
}

interface CardData {
  card_name: string
  card_description: string
  card_image_url: string
  crop_parameters?: any
  conversation_ai_enabled: boolean
  ai_instruction?: string
  ai_knowledge_base?: string
  is_activated: boolean
  content_mode?: 'single' | 'grouped' | 'list' | 'grid' | 'inline'
}

interface Props {
  items: ContentItem[]
  cardAiEnabled: boolean
  allItems?: ContentItem[]
  card?: CardData
  availableLanguages?: string[]
  hasHeader?: boolean
}

const props = defineProps<Props>()
const emit = defineEmits<{
  select: [item: ContentItem]
}>()

// Get parent items (top-level, no parent_id)
const parentItems = computed(() => {
  return props.items.filter(item => !item.content_item_parent_id)
    .sort((a, b) => a.content_item_sort_order - b.content_item_sort_order)
})

// Get single item for single mode
const singleItem = computed(() => {
  return parentItems.value[0] || null
})

/**
 * Layout Detection Logic
 * 
 * New 5 Content Modes:
 * - single: 1 parent item, displayed as full page
 * - grouped: N parents as category headers, N children listed below each
 * - list: N parents only, simple vertical list
 * - grid: N items displayed in 2-column grid
 * - inline: N items displayed as horizontal scrollable cards
 */
const detectedLayout = computed<'single' | 'grouped' | 'list' | 'grid' | 'inline'>(() => {
  // Priority 1: Use explicit content_mode from CMS if available
  if (props.card?.content_mode) {
    return props.card.content_mode
  }
  
  // Priority 2: Heuristic detection (fallback for legacy data)
  const hasSubItems = props.allItems?.some(item => item.content_item_parent_id !== null) || false
  
  // If only 1 parent item -> single
  if (parentItems.value.length === 1 && !hasSubItems) {
    return 'single'
  }
  
  // If has sub-items -> grouped
  if (hasSubItems) {
    return 'grouped'
  }
  
  // Default to list
  return 'list'
})

function handleSelect(item: ContentItem) {
  emit('select', item)
}

// Set up CSS custom property for content aspect ratio
onMounted(() => {
  const aspectRatio = getContentAspectRatio()
  document.documentElement.style.setProperty('--content-aspect-ratio', aspectRatio)
})
</script>

<style scoped>
.smart-content-renderer {
  min-height: 100vh;
  min-height: 100dvh;
}
</style>
