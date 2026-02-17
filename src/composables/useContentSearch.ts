/**
 * useContentSearch Composable
 *
 * Provides search, category filtering, and sort functionality
 * for mobile client content items. Includes 300ms debounce on search input.
 */

import { ref, computed, watch } from 'vue'

export type SortOption = 'default' | 'az' | 'za' | 'newest' | 'oldest'

export interface ContentItemForSearch {
  content_item_id: string
  content_item_parent_id: string | null
  content_item_name: string
  content_item_content?: string
  content_preview?: string
  content_item_image_url: string
  content_item_sort_order: number
  [key: string]: any
}

export interface UseContentSearchOptions {
  /** All items to search/filter/sort */
  items: () => ContentItemForSearch[]
  /** All items including children (used for category extraction) */
  allItems?: () => ContentItemForSearch[]
}

export function useContentSearch(options: UseContentSearchOptions) {
  // State
  const searchQuery = ref('')
  const debouncedQuery = ref('')
  const selectedCategory = ref<string | null>(null)
  const sortOption = ref<SortOption>('default')

  // Debounce timer
  let debounceTimer: ReturnType<typeof setTimeout> | null = null

  // Watch search query with 300ms debounce
  watch(searchQuery, (newVal) => {
    if (debounceTimer) {
      clearTimeout(debounceTimer)
    }
    debounceTimer = setTimeout(() => {
      debouncedQuery.value = newVal.trim()
    }, 300)
  })

  /**
   * Extract unique category names from parent items.
   * Categories are top-level items that have children.
   * Bug #5 fix: Improved validation and edge case handling
   */
  const categories = computed(() => {
    const allItemsList = options.allItems ? options.allItems() : options.items()
    const itemsList = options.items()

    // Validate inputs
    if (!allItemsList || allItemsList.length === 0) return []
    if (!itemsList || itemsList.length === 0) return []

    // Find parent IDs that have children in the full item set
    const parentIdsWithChildren = new Set<string>()
    for (const item of allItemsList) {
      if (item.content_item_parent_id) {
        parentIdsWithChildren.add(item.content_item_parent_id)
      }
    }

    // Return parent items (from itemsList) that have children (in allItemsList)
    // This ensures we only show categories that exist in both sets
    return itemsList
      .filter(item =>
        item.content_item_id && // Validate ID exists
        parentIdsWithChildren.has(item.content_item_id) // Has children
      )
      .sort((a, b) => (a.content_item_sort_order || 0) - (b.content_item_sort_order || 0))
      .map(item => ({
        id: item.content_item_id,
        name: item.content_item_name || 'Untitled'
      }))
  })

  /**
   * Whether the content has categories (grouped structure)
   */
  const hasCategories = computed(() => categories.value.length > 0)

  /**
   * Filter items by search query
   */
  function matchesSearch(item: ContentItemForSearch): boolean {
    if (!debouncedQuery.value) return true

    const query = debouncedQuery.value.toLowerCase()
    const name = (item.content_item_name || '').toLowerCase()
    const content = (item.content_item_content || item.content_preview || '').toLowerCase()

    return name.includes(query) || content.includes(query)
  }

  /**
   * Filter items by selected category (parent ID)
   * Handles both parent items (categories themselves) and child items
   */
  function matchesCategory(item: ContentItemForSearch): boolean {
    if (!selectedCategory.value) return true

    // For parent items (categories): match if this IS the selected category
    if (item.content_item_parent_id === null) {
      return item.content_item_id === selectedCategory.value
    }

    // For child items: match if their parent is the selected category
    return item.content_item_parent_id === selectedCategory.value
  }

  /**
   * Sort items based on selected sort option
   * Bug #9 fix: Defensive sorting with fallbacks
   */
  function sortItems(items: ContentItemForSearch[]): ContentItemForSearch[] {
    if (!items || items.length === 0) return []

    const sorted = [...items]

    switch (sortOption.value) {
      case 'az':
        return sorted.sort((a, b) =>
          (a.content_item_name || '').localeCompare(b.content_item_name || '')
        )
      case 'za':
        return sorted.sort((a, b) =>
          (b.content_item_name || '').localeCompare(a.content_item_name || '')
        )
      case 'newest':
        // Reverse of default sort order (higher sort_order = newer)
        return sorted.sort((a, b) =>
          (b.content_item_sort_order || 0) - (a.content_item_sort_order || 0)
        )
      case 'oldest':
        return sorted.sort((a, b) =>
          (a.content_item_sort_order || 0) - (b.content_item_sort_order || 0)
        )
      case 'default':
      default:
        return sorted.sort((a, b) =>
          (a.content_item_sort_order || 0) - (b.content_item_sort_order || 0)
        )
    }
  }

  /**
   * When searching grouped content, build a set of child IDs that match the query.
   * This allows LayoutGrouped to show only matching children within each category.
   */
  const matchingChildIds = computed<Set<string>>(() => {
    const ids = new Set<string>()
    if (!debouncedQuery.value) return ids

    const allItems = options.allItems ? options.allItems() : []
    const query = debouncedQuery.value.toLowerCase()

    for (const item of allItems) {
      if (!item || !item.content_item_parent_id) continue
      const name = (item.content_item_name || '').toLowerCase()
      const content = (item.content_item_content || item.content_preview || '').toLowerCase()
      if (name.includes(query) || content.includes(query)) {
        ids.add(item.content_item_id)
      }
    }
    return ids
  })

  /**
   * Set of parent IDs whose children match the search query.
   * Used to include parent categories in results when their children match.
   */
  const parentIdsWithMatchingChildren = computed<Set<string>>(() => {
    const ids = new Set<string>()
    if (!debouncedQuery.value) return ids

    const allItems = options.allItems ? options.allItems() : []
    for (const item of allItems) {
      if (!item || !item.content_item_parent_id) continue
      if (matchingChildIds.value.has(item.content_item_id)) {
        ids.add(item.content_item_parent_id)
      }
    }
    return ids
  })

  /**
   * The fully filtered and sorted result set
   * Bug #9 fix: Defensive checks to prevent race conditions
   * Enhanced: For grouped content, also matches children and includes their parent categories
   */
  const filteredItems = computed(() => {
    const sourceItems = options.items()

    // Validate source items exist
    if (!sourceItems || sourceItems.length === 0) {
      return []
    }

    // Filter and sort in a single reactive computation
    const filtered = sourceItems.filter(item => {
      if (!item) return false
      if (!matchesCategory(item)) return false

      // Match if the item itself matches search
      if (matchesSearch(item)) return true

      // For parent items in grouped mode: also match if any children match the search
      if (item.content_item_parent_id === null && parentIdsWithMatchingChildren.value.has(item.content_item_id)) {
        return true
      }

      return false
    })

    return sortItems(filtered)
  })

  /**
   * Result count for display
   */
  const resultCount = computed(() => filteredItems.value.length)

  /**
   * Total items count (before filtering)
   */
  const totalCount = computed(() => options.items().length)

  /**
   * Whether any filters are active
   */
  const hasActiveFilters = computed(() => {
    return debouncedQuery.value !== '' || selectedCategory.value !== null || sortOption.value !== 'default'
  })

  /**
   * Whether the search returned no results
   */
  const noResults = computed(() => {
    return hasActiveFilters.value && resultCount.value === 0
  })

  /**
   * Clear all filters and search
   */
  function clearFilters() {
    searchQuery.value = ''
    debouncedQuery.value = ''
    selectedCategory.value = null
    sortOption.value = 'default'
  }

  /**
   * Set the selected category (null to clear)
   */
  function setCategory(categoryId: string | null) {
    selectedCategory.value = categoryId
  }

  /**
   * Set the sort option
   */
  function setSort(option: SortOption) {
    sortOption.value = option
  }

  return {
    // State
    searchQuery,
    debouncedQuery,
    selectedCategory,
    sortOption,

    // Computed
    categories,
    hasCategories,
    filteredItems,
    matchingChildIds,
    resultCount,
    totalCount,
    hasActiveFilters,
    noResults,

    // Methods
    clearFilters,
    setCategory,
    setSort
  }
}
