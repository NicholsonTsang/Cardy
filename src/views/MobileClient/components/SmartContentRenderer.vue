<template>
  <div class="smart-content-renderer">
    <template v-if="card">
      <!-- SINGLE Mode: One full-page content item (no search/filter) -->
      <LayoutSingle
        v-if="detectedLayout === 'single'"
        :card="card"
        :item="singleItem"
        :available-languages="availableLanguages"
        :has-header="hasHeader"
      />

      <template v-else>
        <!-- Search, Filter & Sort Bar (for multi-item layouts) -->
        <div
          v-if="showSearchBar"
          class="search-filter-bar"
          :class="{ 'has-header': hasHeader }"
          role="search"
          :aria-label="t('mobile.searchPlaceholder')"
        >
          <!-- Search Input -->
          <div class="search-input-wrapper">
            <i class="pi pi-search search-icon" aria-hidden="true" />
            <input
              v-model="searchQuery"
              type="search"
              class="search-input"
              :placeholder="t('mobile.searchPlaceholder')"
              :aria-label="t('mobile.searchPlaceholder')"
              autocomplete="off"
              enterkeyhint="search"
            />
            <button
              v-if="searchQuery"
              class="search-clear-btn"
              :aria-label="t('mobile.clearFilters')"
              @click="searchQuery = ''"
            >
              <i class="pi pi-times" aria-hidden="true" />
            </button>
          </div>

          <!-- Sort Dropdown -->
          <div class="sort-wrapper">
            <button
              class="sort-btn"
              :aria-label="t('mobile.sortBy')"
              :aria-expanded="showSortMenu"
              @click="showSortMenu = !showSortMenu"
            >
              <i class="pi pi-sort-alt" aria-hidden="true" />
            </button>
            <!-- Sort Menu -->
            <div v-if="showSortMenu" class="sort-menu" role="listbox" :aria-label="t('mobile.sortBy')">
              <button
                v-for="option in sortOptions"
                :key="option.value"
                class="sort-option"
                :class="{ 'active': sortOption === option.value }"
                role="option"
                :aria-selected="sortOption === option.value"
                @click="handleSortSelect(option.value)"
              >
                {{ option.label }}
              </button>
            </div>
          </div>
        </div>

        <!-- Category Filter Chips (horizontal scroll) -->
        <!-- Only show in grouped expanded mode (not in collapsed or flat layouts) -->
        <div
          v-if="showSearchBar && hasCategories && isGrouped && groupDisplay === 'expanded'"
          class="category-chips-wrapper"
          :class="{ 'has-header': hasHeader }"
          role="tablist"
          :aria-label="t('mobile.filterByCategory')"
        >
          <div class="category-chips-scroll">
            <button
              class="category-chip"
              :class="{ 'active': selectedCategory === null }"
              role="tab"
              :aria-selected="selectedCategory === null"
              @click="setCategory(null)"
            >
              {{ t('mobile.allCategories') }}
            </button>
            <button
              v-for="cat in categories"
              :key="cat.id"
              class="category-chip"
              :class="{ 'active': selectedCategory === cat.id }"
              role="tab"
              :aria-selected="selectedCategory === cat.id"
              @click="setCategory(cat.id)"
            >
              {{ cat.name }}
            </button>
          </div>
        </div>

        <!-- Result count (only when search text is active, not for category/sort changes) -->
        <div
          v-if="debouncedQuery && !noResults"
          class="result-count"
          :class="{
            'has-header': hasHeader,
            'has-categories': hasCategories && isGrouped && groupDisplay === 'expanded'
          }"
          aria-live="polite"
        >
          {{ resultCount }} / {{ totalItemCount }}
        </div>

        <!-- No Results State -->
        <div
          v-if="noResults"
          class="no-results"
          :class="{ 'has-header': hasHeader }"
          role="status"
          aria-live="polite"
        >
          <i class="pi pi-search no-results-icon" aria-hidden="true" />
          <p class="no-results-title">{{ t('mobile.noResults') }}</p>
          <p class="no-results-desc">{{ t('mobile.noResultsDesc') }}</p>
          <button class="clear-filters-btn" @click="clearFilters">
            {{ t('mobile.clearFilters') }}
          </button>
        </div>

        <!-- Layout Components (with filtered items) -->
        <template v-if="!noResults">
          <!-- GROUPED Mode: Categories with sub-items -->
          <LayoutGrouped
            v-if="isGrouped && groupDisplay === 'expanded'"
            :card="card"
            :items="displayParentItems"
            :all-items="allItems || items"
            :available-languages="availableLanguages"
            :has-header="hasHeader"
            :has-categories="hasCategories && showSearchBar"
            :layout-style="detectedLayout"
            :matching-child-ids="hasActiveFilters ? matchingChildIds : undefined"
            @select="handleSelect"
          />

          <!-- COLLAPSED GROUPED Mode: Categories that navigate to children -->
          <LayoutGroupedCollapsed
            v-else-if="isGrouped && groupDisplay === 'collapsed'"
            :card="card"
            :items="displayParentItems"
            :all-items="allItems || items"
            :available-languages="availableLanguages"
            :has-header="hasHeader"
            :layout-style="detectedLayout"
            @select="handleSelect"
          />

          <!-- LIST Mode: Simple vertical list -->
          <LayoutList
            v-else-if="detectedLayout === 'list'"
            :card="card"
            :items="displayFlatItems"
            :available-languages="availableLanguages"
            :has-header="hasHeader"
            :has-more="hasMore"
            :is-loading-more="isLoadingMore"
            :total-count="totalCount"
            @select="handleSelect"
            @load-more="handleLoadMore"
          />

          <!-- GRID Mode: 2-column visual grid -->
          <LayoutGrid
            v-else-if="detectedLayout === 'grid'"
            :card="card"
            :items="displayFlatItems"
            :all-items="allItems || items"
            :available-languages="availableLanguages"
            :has-header="hasHeader"
            @select="handleSelect"
          />

          <!-- CARDS Mode: Full-width cards -->
          <LayoutInline
            v-else
            :card="card"
            :items="displayFlatItems"
            :all-items="allItems || items"
            :available-languages="availableLanguages"
            :has-header="hasHeader"
            @select="handleSelect"
          />
        </template>
      </template>

      <!-- Note: Floating AI button removed - users access AI from Card Overview
           or contextually from Content Detail pages -->
    </template>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, watch, onMounted } from 'vue'
import { useI18n } from 'vue-i18n'
import { getContentAspectRatio } from '@/utils/cardConfig'
import { useContentSearch, type SortOption } from '@/composables/useContentSearch'
import LayoutSingle from './LayoutSingle.vue'
import LayoutGrouped from './LayoutGrouped.vue'
import LayoutGroupedCollapsed from './LayoutGroupedCollapsed.vue'
import LayoutList from './LayoutList.vue'
import LayoutGrid from './LayoutGrid.vue'
import LayoutInline from './LayoutInline.vue'

const { t } = useI18n()

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

// Sort menu visibility
const showSortMenu = ref(false)

// Sort options for dropdown
const sortOptions = computed(() => [
  { value: 'default' as SortOption, label: t('mobile.sortDefault') },
  { value: 'az' as SortOption, label: t('mobile.sortAZ') },
  { value: 'za' as SortOption, label: t('mobile.sortZA') },
  { value: 'newest' as SortOption, label: t('mobile.sortNewest') },
  { value: 'oldest' as SortOption, label: t('mobile.sortOldest') }
])

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
// Bug #8 fix: Show ALL items in flat mode, not just children
const flatLayoutItems = computed(() => {
  // In flat mode (is_grouped=false), show all items regardless of hierarchy
  // This ensures parent items with content aren't orphaned
  if (!isGrouped.value && hasHierarchy.value) {
    // Show all items (parents + children) sorted by sort_order
    return allItemsSource.value
      .sort((a, b) => a.content_item_sort_order - b.content_item_sort_order)
  }
  return props.items
})

// Get single item for single mode
const singleItem = computed(() => {
  return parentItems.value[0] || null
})

// Layout Detection
const detectedLayout = computed<'single' | 'grid' | 'list' | 'cards'>(() => {
  if (props.card?.content_mode) {
    return props.card.content_mode
  }
  const hasSubItems = props.allItems?.some(item => item.content_item_parent_id !== null) || false
  if (parentItems.value.length === 1 && !hasSubItems) {
    return 'single'
  }
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

// Only show the search bar for multi-item layouts with more than 1 item
const showSearchBar = computed(() => {
  if (detectedLayout.value === 'single') return false
  const sourceItems = isGrouped.value ? parentItems.value : flatLayoutItems.value
  return sourceItems.length > 1
})

// Initialize content search composable
// For grouped content, search across parent items; for flat, search across flat items
const {
  searchQuery,
  debouncedQuery,
  selectedCategory,
  sortOption,
  categories,
  hasCategories,
  filteredItems,
  matchingChildIds,
  resultCount,
  totalCount: totalItemCount,
  hasActiveFilters,
  noResults,
  clearFilters,
  setCategory,
  setSort
} = useContentSearch({
  items: () => isGrouped.value ? parentItems.value : flatLayoutItems.value,
  allItems: () => allItemsSource.value
})

// Display items - use filtered items when search is active, otherwise original items
const displayFlatItems = computed(() => {
  if (hasActiveFilters.value) {
    return filteredItems.value
  }
  return flatLayoutItems.value
})

const displayParentItems = computed(() => {
  if (hasActiveFilters.value) {
    return filteredItems.value
  }
  return parentItems.value
})

function handleSortSelect(option: SortOption) {
  setSort(option)
  showSortMenu.value = false
}

function handleSelect(item: ContentItem) {
  emit('select', item)
}

function handleLoadMore() {
  emit('loadMore')
}

// Close sort menu when clicking outside
function handleClickOutside(event: MouseEvent) {
  const target = event.target as HTMLElement
  if (!target.closest('.sort-wrapper')) {
    showSortMenu.value = false
  }
}

// Clear filters when card changes (Bug #4 fix)
watch(() => props.card, () => {
  clearFilters()
}, { deep: false })

// Reset sort to default when category filter changes (Bug #6 fix)
watch(selectedCategory, (newVal, oldVal) => {
  // Only reset if category actually changed (not initial load)
  if (oldVal !== undefined && newVal !== oldVal && sortOption.value !== 'default') {
    setSort('default')
  }
})

// Set up CSS custom property for content aspect ratio
onMounted(() => {
  const aspectRatio = getContentAspectRatio()
  document.documentElement.style.setProperty('--content-aspect-ratio', aspectRatio)
  document.addEventListener('click', handleClickOutside)
})
</script>

<style scoped>
.smart-content-renderer {
  /* Fill parent flex container */
  flex: 1;
  display: flex;
  flex-direction: column;
  min-height: 0; /* Allow flex shrinking */
  /* Dark background to prevent flash during view transitions */
  background: linear-gradient(to bottom right, var(--theme-bg, #0f172a), var(--theme-gradient-mid, #1e3a8a), var(--theme-gradient-end, #4338ca));
}

/* Search/Filter Bar - fixed below header */
.search-filter-bar {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  z-index: 45;
  padding: 0.75rem 1rem;
  padding-top: max(0.75rem, env(safe-area-inset-top));
  background: linear-gradient(to bottom, rgba(0, 0, 0, 0.5), rgba(0, 0, 0, 0.35));
  backdrop-filter: blur(24px);
  -webkit-backdrop-filter: blur(24px);
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.search-filter-bar.has-header {
  top: 0;
  /* Position below the MobileHeader (~4.5rem + safe area) */
  padding-top: calc(4.5rem + max(0.75rem, env(safe-area-inset-top)));
}

/* Search Input */
.search-input-wrapper {
  flex: 1;
  position: relative;
  display: flex;
  align-items: center;
}

.search-icon {
  position: absolute;
  left: 0.875rem;
  color: rgba(255, 255, 255, 0.45);
  font-size: 0.875rem;
  pointer-events: none;
  transition: color 0.2s;
}

/* Highlight search icon when input is focused */
.search-input:focus ~ .search-icon,
.search-input-wrapper:focus-within .search-icon {
  color: rgba(96, 165, 250, 0.8);
}

.search-input {
  width: 100%;
  padding: 0.625rem 2.25rem 0.625rem 2.5rem;
  background: var(--theme-surface, rgba(255, 255, 255, 0.07));
  border: 1px solid rgba(255, 255, 255, 0.12);
  border-radius: 0.875rem;
  color: white;
  font-size: 0.875rem;
  outline: none;
  transition: border-color 0.2s, background-color 0.2s, box-shadow 0.2s;
  -webkit-appearance: none;
  min-height: 44px;
}

.search-input::placeholder {
  color: rgba(255, 255, 255, 0.35);
}

.search-input:focus {
  border-color: rgba(96, 165, 250, 0.45);
  background: rgba(255, 255, 255, 0.1);
  box-shadow: 0 0 0 3px rgba(96, 165, 250, 0.1);
}

.search-clear-btn {
  position: absolute;
  right: 0.375rem;
  width: 1.75rem;
  height: 1.75rem;
  border-radius: 50%;
  background: rgba(255, 255, 255, 0.12);
  border: none;
  color: rgba(255, 255, 255, 0.6);
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: background-color 0.2s, transform 0.15s;
  -webkit-tap-highlight-color: transparent;
  touch-action: manipulation;
  /* Extend tap area without enlarging visual size */
  min-width: 44px;
  min-height: 44px;
}

.search-clear-btn:active {
  background: rgba(255, 255, 255, 0.25);
  transform: scale(0.9);
}

.search-clear-btn i {
  font-size: 0.6875rem;
}

/* Sort Button & Menu */
.sort-wrapper {
  position: relative;
}

.sort-btn {
  width: 2.75rem;
  height: 2.75rem;
  min-width: 44px;
  min-height: 44px;
  border-radius: 0.875rem;
  background: rgba(255, 255, 255, 0.08);
  border: 1px solid rgba(255, 255, 255, 0.12);
  color: rgba(255, 255, 255, 0.6);
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: all 0.2s;
  -webkit-tap-highlight-color: transparent;
  touch-action: manipulation;
}

.sort-btn:active {
  background: rgba(255, 255, 255, 0.18);
  transform: scale(0.93);
}

.sort-btn:focus-visible {
  outline: 2px solid #60a5fa;
  outline-offset: 2px;
}

.sort-btn i {
  font-size: 1rem;
}

@keyframes sortMenuEnter {
  from {
    opacity: 0;
    transform: translateY(-4px) scale(0.97);
  }
  to {
    opacity: 1;
    transform: translateY(0) scale(1);
  }
}

.sort-menu {
  position: absolute;
  top: calc(100% + 0.5rem);
  right: 0;
  min-width: 170px;
  background: rgba(30, 41, 59, 0.96);
  backdrop-filter: blur(20px);
  -webkit-backdrop-filter: blur(20px);
  border: 1px solid rgba(255, 255, 255, 0.12);
  border-radius: 0.875rem;
  overflow: hidden;
  box-shadow: 0 8px 32px rgba(0, 0, 0, 0.4);
  z-index: 50;
  animation: sortMenuEnter 0.18s ease-out;
}

.sort-option {
  display: flex;
  align-items: center;
  width: 100%;
  padding: 0.75rem 1rem;
  background: transparent;
  border: none;
  color: rgba(255, 255, 255, 0.75);
  font-size: 0.875rem;
  text-align: left;
  cursor: pointer;
  transition: background-color 0.15s, color 0.15s;
  min-height: 44px;
}

.sort-option:active {
  background: rgba(96, 165, 250, 0.15);
}

.sort-option.active {
  background: rgba(96, 165, 250, 0.15);
  color: #93c5fd;
  font-weight: 600;
}

.sort-option:focus-visible {
  outline: 2px solid #60a5fa;
  outline-offset: -2px;
}

/* Category Filter Chips - Bug #12 fix: Better positioning for notched devices */
.category-chips-wrapper {
  position: fixed;
  left: 0;
  right: 0;
  z-index: 44;
  /* Overlap upward into search bar area to eliminate gap (search bar is z-45, clips above) */
  top: calc(3.75rem - 0.25rem);
  padding-top: calc(0.75rem + max(0.25rem, env(safe-area-inset-top)));
  padding-bottom: 0.5rem;
  padding-left: 0;
  padding-right: 0;
  background: linear-gradient(to bottom, rgba(0, 0, 0, 0.35), rgba(0, 0, 0, 0.2));
  backdrop-filter: blur(24px);
  -webkit-backdrop-filter: blur(24px);
}

.category-chips-wrapper.has-header {
  /* Overlap upward into search bar area to eliminate gap */
  top: calc(4.5rem + 3.75rem - 0.25rem);
}

.category-chips-scroll {
  display: flex;
  gap: 0.5rem;
  overflow-x: auto;
  padding: 0 1rem;
  scrollbar-width: none;
  -ms-overflow-style: none;
  -webkit-overflow-scrolling: touch;
}

.category-chips-scroll::-webkit-scrollbar {
  display: none;
}

.category-chip {
  flex-shrink: 0;
  padding: 0.5rem 1rem;
  border-radius: 9999px;
  background: rgba(255, 255, 255, 0.06);
  border: 1px solid rgba(255, 255, 255, 0.12);
  color: rgba(255, 255, 255, 0.65);
  font-size: 0.8125rem;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s;
  white-space: nowrap;
  -webkit-tap-highlight-color: transparent;
  touch-action: manipulation;
  min-height: 40px;
  display: flex;
  align-items: center;
}

.category-chip:active {
  transform: scale(0.95);
}

.category-chip.active {
  background: rgba(96, 165, 250, 0.2);
  border-color: rgba(96, 165, 250, 0.4);
  color: #bfdbfe;
  font-weight: 600;
}

.category-chip:focus-visible {
  outline: 2px solid #60a5fa;
  outline-offset: 2px;
}

/* Result Count - Bug #12 fix: Consistent positioning */
.result-count {
  position: fixed;
  left: 0;
  right: 0;
  z-index: 43;
  top: calc(3.75rem + 0.75rem);
  padding: 0.25rem 1rem 0.375rem;
  padding-top: max(0.25rem, env(safe-area-inset-top));
  color: rgba(255, 255, 255, 0.45);
  font-size: 0.75rem;
  font-weight: 500;
}

.result-count.has-header {
  top: calc(4.5rem + 3.75rem + 0.75rem);
}

.result-count.has-categories {
  /* Shift down when category chips are also visible (~3.5rem: 0.5rem pad + 2.5rem chip + 0.5rem pad) */
  top: calc(3.75rem + 0.75rem + 3.5rem);
}

.result-count.has-header.has-categories {
  top: calc(4.5rem + 3.75rem + 0.75rem + 3.5rem);
}

/* No Results State */
@keyframes noResultsFadeIn {
  from {
    opacity: 0;
    transform: translateY(12px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.no-results {
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 3rem 2rem;
  padding-top: calc(10rem + env(safe-area-inset-top));
  text-align: center;
  animation: noResultsFadeIn 0.3s ease-out;
}

.no-results.has-header {
  padding-top: calc(14rem + env(safe-area-inset-top));
}

.no-results-icon {
  font-size: 2.5rem;
  color: rgba(255, 255, 255, 0.2);
  margin-bottom: 1.25rem;
}

.no-results-title {
  font-size: 1.0625rem;
  font-weight: 600;
  color: rgba(255, 255, 255, 0.8);
  margin: 0 0 0.375rem 0;
}

.no-results-desc {
  font-size: 0.875rem;
  color: rgba(255, 255, 255, 0.45);
  margin: 0 0 1.5rem 0;
  line-height: 1.5;
  max-width: 280px;
}

.clear-filters-btn {
  padding: 0.625rem 1.5rem;
  border-radius: 0.875rem;
  background: rgba(96, 165, 250, 0.15);
  border: 1px solid rgba(96, 165, 250, 0.3);
  color: #bfdbfe;
  font-size: 0.875rem;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s;
  -webkit-tap-highlight-color: transparent;
  touch-action: manipulation;
  min-height: 44px;
}

.clear-filters-btn:active {
  background: rgba(96, 165, 250, 0.25);
  transform: scale(0.97);
}

.clear-filters-btn:focus-visible {
  outline: 2px solid #60a5fa;
  outline-offset: 2px;
}
</style>
