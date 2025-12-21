<template>
  <div class="smart-content-renderer">
    <template v-if="card">
      <!-- SINGLE Mode: One full-page content item -->
      <LayoutSingle 
        v-if="detectedLayout === 'single'"
        :card="card"
        :item="singleItem"
        :available-languages="availableLanguages"
        :has-header="hasHeader"
      />

      <!-- GROUPED Mode: Categories with sub-items (when is_grouped is true) -->
      <!-- Used for: list+grouped, grid+grouped, cards+grouped with expanded display -->
      <LayoutGrouped 
        v-else-if="isGrouped && groupDisplay === 'expanded'"
        :card="card"
        :items="parentItems"
        :all-items="allItems || items"
        :available-languages="availableLanguages"
        :has-header="hasHeader"
        :layout-style="detectedLayout"
        @select="handleSelect"
      />

      <!-- COLLAPSED GROUPED Mode: Categories that navigate to children -->
      <!-- Used for: list+grouped, grid+grouped, cards+grouped with collapsed display -->
      <LayoutGroupedCollapsed 
        v-else-if="isGrouped && groupDisplay === 'collapsed'"
        :card="card"
        :items="parentItems"
        :all-items="allItems || items"
        :available-languages="availableLanguages"
        :has-header="hasHeader"
        :layout-style="detectedLayout"
        @select="handleSelect"
      />

      <!-- LIST Mode: Simple vertical list (flat, no grouping) -->
      <LayoutList 
        v-else-if="detectedLayout === 'list'"
        :card="card"
        :items="flatLayoutItems"
        :available-languages="availableLanguages"
        :has-header="hasHeader"
        :has-more="hasMore"
        :is-loading-more="isLoadingMore"
        :total-count="totalCount"
        @select="handleSelect"
        @load-more="handleLoadMore"
      />

      <!-- GRID Mode: 2-column visual grid (flat, no grouping) -->
      <LayoutGrid 
        v-else-if="detectedLayout === 'grid'"
        :card="card"
        :items="flatLayoutItems"
        :all-items="allItems || items"
        :available-languages="availableLanguages"
        :has-header="hasHeader"
        @select="handleSelect"
      />

      <!-- CARDS Mode: Full-width cards (flat, no grouping) -->
      <LayoutInline 
        v-else
        :card="card"
        :items="flatLayoutItems"
        :all-items="allItems || items"
        :available-languages="availableLanguages"
        :has-header="hasHeader"
        @select="handleSelect"
      />
      
      <!-- Note: Floating AI button removed - users access AI from Card Overview 
           or contextually from Content Detail pages -->
    </template>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted } from 'vue'
import { getContentAspectRatio } from '@/utils/cardConfig'
import LayoutSingle from './LayoutSingle.vue'
import LayoutGrouped from './LayoutGrouped.vue'
import LayoutGroupedCollapsed from './LayoutGroupedCollapsed.vue'
import LayoutList from './LayoutList.vue'
import LayoutGrid from './LayoutGrid.vue'
import LayoutInline from './LayoutInline.vue'

interface ContentItem {
  content_item_id: string
  content_item_parent_id: string | null
  content_item_name: string
  content_item_content?: string       // Full content (legacy, optional)
  content_preview?: string            // Truncated preview (optimized)
  content_length?: number             // Full content length (optimized)
  content_item_image_url: string
  content_item_ai_knowledge_base?: string
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
    ai_welcome_general?: string
    ai_welcome_item?: string
    is_activated: boolean
  content_mode?: 'single' | 'grid' | 'list' | 'cards'
  is_grouped?: boolean
  group_display?: 'expanded' | 'collapsed'
}

interface Props {
  items: ContentItem[]
  cardAiEnabled: boolean
  allItems?: ContentItem[]
  card?: CardData
  availableLanguages?: string[]
  hasHeader?: boolean
  // Pagination props (optional - for optimized loading)
  hasMore?: boolean
  isLoadingMore?: boolean
  totalCount?: number
}

const props = withDefaults(defineProps<Props>(), {
  hasMore: false,
  isLoadingMore: false,
  totalCount: 0
})
const emit = defineEmits<{
  select: [item: ContentItem]
  loadMore: []
}>()

// Get all items (props.items may be pre-filtered, use allItems for full picture)
const allItemsSource = computed(() => props.allItems || props.items)

// Get parent items (top-level, no parent_id)
const parentItems = computed(() => {
  return props.items.filter(item => !item.content_item_parent_id)
    .sort((a, b) => a.content_item_sort_order - b.content_item_sort_order)
})

// Get all child items (items with a parent_id) from allItems source
const allChildItems = computed(() => {
  return allItemsSource.value.filter(item => item.content_item_parent_id !== null)
    .sort((a, b) => a.content_item_sort_order - b.content_item_sort_order)
})

// Check if content has a parent-child hierarchy
const hasHierarchy = computed(() => {
  return allChildItems.value.length > 0
})

// Get items for flat layouts (list, grid, cards when is_grouped=false)
// If content has hierarchy but is_grouped=false, show only children (the actual content)
// If no hierarchy, show all items as-is
const flatLayoutItems = computed(() => {
  if (hasHierarchy.value && !isGrouped.value) {
    // Has hierarchy but not grouped mode - show only leaf items (children)
    // Parents are just categories, not actual content to display
    return allChildItems.value
  }
  // No hierarchy - show items as passed (they're all leaf items)
  return props.items
})

// Get single item for single mode
const singleItem = computed(() => {
  return parentItems.value[0] || null
})

/**
 * Layout Detection Logic
 * 
 * 4 Content Modes with Grouping Options:
 * - single: 1 parent item, displayed as full page (no grouping)
 * - grid: N items displayed in 2-column grid
 * - list: N items displayed as vertical list
 * - cards: N items displayed as full-width cards
 * 
 * Grouping (for grid, list, cards):
 * - is_grouped: true = content organized into categories (parent/child)
 * - group_display: 'expanded' = children shown inline, 'collapsed' = navigate to see children
 */
const detectedLayout = computed<'single' | 'grid' | 'list' | 'cards'>(() => {
  // Use explicit content_mode from CMS if available
  if (props.card?.content_mode) {
    return props.card.content_mode
  }
  
  // Fallback: Heuristic detection
  const hasSubItems = props.allItems?.some(item => item.content_item_parent_id !== null) || false
  
  // If only 1 parent item -> single
  if (parentItems.value.length === 1 && !hasSubItems) {
    return 'single'
  }
  
  // Default to list
  return 'list'
})

// Check if content is grouped
const isGrouped = computed(() => {
  return props.card?.is_grouped || false
})

// Get group display mode
const groupDisplay = computed(() => {
  return props.card?.group_display || 'expanded'
})

function handleSelect(item: ContentItem) {
  emit('select', item)
}

function handleLoadMore() {
  emit('loadMore')
}

// Set up CSS custom property for content aspect ratio
onMounted(() => {
  const aspectRatio = getContentAspectRatio()
  document.documentElement.style.setProperty('--content-aspect-ratio', aspectRatio)
})
</script>

<style scoped>
.smart-content-renderer {
  /* Fill parent flex container */
  flex: 1;
  display: flex;
  flex-direction: column;
  min-height: 0; /* Allow flex shrinking */
}
</style>
