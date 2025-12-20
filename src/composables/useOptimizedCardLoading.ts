/**
 * useOptimizedCardLoading
 * 
 * Composable for optimized card loading with pagination and lazy loading.
 * Reduces initial payload from ~2MB to ~5KB for cards with many content items.
 * 
 * Features:
 * - Card info only on initial load
 * - Paginated content items for list view
 * - Full content item details on demand (lazy loading)
 * - Infinite scroll support
 * - Backward compatible with existing code
 * 
 * Configuration via .env:
 * - VITE_CONTENT_PAGE_SIZE: Items per page (default: 20)
 * - VITE_CONTENT_PREVIEW_LENGTH: Preview chars (default: 200)
 * - VITE_LARGE_CARD_THRESHOLD: Use pagination above this (default: 50)
 * - VITE_INFINITE_SCROLL_THRESHOLD: Scroll trigger distance (default: 200px)
 */

import { ref, computed } from 'vue'
import { supabase } from '@/lib/supabase'
import { 
  getPageSize, 
  getPreviewLength, 
  getLargeCardThreshold,
  getInfiniteScrollThreshold 
} from '@/utils/paginationConfig'

// Types
export interface OptimizedCardInfo {
  card_name: string
  card_description: string
  card_image_url: string | null
  card_crop_parameters?: any
  card_conversation_ai_enabled: boolean
  card_ai_instruction: string
  card_ai_knowledge_base: string
  card_ai_welcome_general: string
  card_ai_welcome_item: string
  card_original_language: string
  card_has_translation: boolean
  card_available_languages: string[]
  card_content_mode: string
  card_is_grouped: boolean
  card_group_display: string
  card_billing_type: string
  card_max_scans: number | null
  card_current_scans: number
  card_daily_scan_limit: number | null
  card_daily_scans: number
  card_scan_limit_reached: boolean
  card_monthly_limit_exceeded: boolean
  card_credits_insufficient: boolean
  card_id: string
  content_item_count: number
  is_activated: boolean
}

export interface ContentItemPreview {
  content_item_id: string
  content_item_parent_id: string | null
  content_item_name: string
  content_preview: string
  content_length: number
  content_item_image_url: string | null
  content_item_sort_order: number
  crop_parameters?: any
  total_count: number
}

export interface ContentItemFull {
  content_item_id: string
  content_item_parent_id: string | null
  content_item_name: string
  content_item_content: string
  content_item_image_url: string | null
  content_item_ai_knowledge_base: string
  content_item_sort_order: number
  crop_parameters?: any
  parent_name: string | null
  prev_item_id: string | null
  next_item_id: string | null
}

export interface PaginationState {
  page: number
  limit: number
  totalCount: number
  hasMore: boolean
}

// Configuration (from .env with fallback defaults)
const DEFAULT_PAGE_SIZE = getPageSize()
const DEFAULT_PREVIEW_LENGTH = getPreviewLength()
const LARGE_CARD_THRESHOLD = getLargeCardThreshold()
const SCROLL_THRESHOLD = getInfiniteScrollThreshold()

export function useOptimizedCardLoading() {
  // State
  const cardInfo = ref<OptimizedCardInfo | null>(null)
  const contentPreviews = ref<ContentItemPreview[]>([])
  const currentItem = ref<ContentItemFull | null>(null)
  const isLoading = ref(false)
  const isLoadingMore = ref(false)
  const error = ref<string | null>(null)
  
  // Pagination
  const pagination = ref<PaginationState>({
    page: 1,
    limit: DEFAULT_PAGE_SIZE,
    totalCount: 0,
    hasMore: true
  })

  // Computed
  const shouldUsePagination = computed(() => {
    return (cardInfo.value?.content_item_count || 0) > LARGE_CARD_THRESHOLD
  })

  const isLargeCard = computed(() => shouldUsePagination.value)

  // =================================================================
  // Card Info Loading (initial load - minimal payload)
  // =================================================================
  
  /**
   * Fetch card info only (no content items)
   * Use for initial card load - reduces payload from ~2MB to ~5KB
   * Note: Credit rate is now hardcoded in the stored procedure for security
   */
  async function fetchCardInfo(
    issueCardId: string,
    language: string = 'en'
  ): Promise<OptimizedCardInfo | null> {
    isLoading.value = true
    error.value = null

    try {
      const { data, error: rpcError } = await supabase.rpc('get_public_card_info', {
        p_issue_card_id: issueCardId,
        p_language: language
      })

      if (rpcError) throw new Error(rpcError.message)
      if (!data || data.length === 0) {
        throw new Error('Card not found')
      }

      cardInfo.value = data[0] as OptimizedCardInfo
      pagination.value.totalCount = cardInfo.value.content_item_count
      pagination.value.hasMore = cardInfo.value.content_item_count > 0

      return cardInfo.value
    } catch (err: any) {
      console.error('Error fetching card info:', err)
      error.value = err.message
      return null
    } finally {
      isLoading.value = false
    }
  }

  // =================================================================
  // Paginated Content Loading (for list views)
  // =================================================================

  /**
   * Fetch paginated content items with preview
   */
  async function fetchContentPreviews(
    cardId: string,
    language: string = 'en',
    page: number = 1,
    limit: number = DEFAULT_PAGE_SIZE,
    previewLength: number = DEFAULT_PREVIEW_LENGTH,
    append: boolean = false
  ): Promise<ContentItemPreview[]> {
    if (append) {
      isLoadingMore.value = true
    } else {
      isLoading.value = true
    }

    try {
      const offset = (page - 1) * limit

      const { data, error: rpcError } = await supabase.rpc('get_public_content_items_paginated', {
        p_card_id: cardId,
        p_language: language,
        p_limit: limit,
        p_offset: offset,
        p_preview_length: previewLength
      })

      if (rpcError) throw new Error(rpcError.message)

      const items = (data || []) as ContentItemPreview[]
      const totalCount = items.length > 0 ? items[0].total_count : 0

      // Update pagination
      pagination.value = {
        page,
        limit,
        totalCount,
        hasMore: offset + items.length < totalCount
      }

      // Append or replace
      if (append) {
        contentPreviews.value = [...contentPreviews.value, ...items]
      } else {
        contentPreviews.value = items
      }

      return items
    } catch (err: any) {
      console.error('Error fetching content previews:', err)
      error.value = err.message
      return []
    } finally {
      isLoading.value = false
      isLoadingMore.value = false
    }
  }

  /**
   * Load more content items (infinite scroll)
   */
  async function loadMore(
    cardId: string,
    language: string = 'en'
  ): Promise<ContentItemPreview[]> {
    if (!pagination.value.hasMore || isLoadingMore.value) {
      return []
    }

    const nextPage = pagination.value.page + 1
    return fetchContentPreviews(cardId, language, nextPage, pagination.value.limit, DEFAULT_PREVIEW_LENGTH, true)
  }

  // =================================================================
  // Full Content Item Loading (lazy loading for detail view)
  // =================================================================

  /**
   * Fetch full content item details
   * Call when user taps on an item to see full content
   */
  async function fetchItemFull(
    contentItemId: string,
    language: string = 'en'
  ): Promise<ContentItemFull | null> {
    isLoading.value = true

    try {
      const { data, error: rpcError } = await supabase.rpc('get_public_content_item_full', {
        p_content_item_id: contentItemId,
        p_language: language
      })

      if (rpcError) throw new Error(rpcError.message)
      if (!data || data.length === 0) {
        throw new Error('Content item not found')
      }

      currentItem.value = data[0] as ContentItemFull
      return currentItem.value
    } catch (err: any) {
      console.error('Error fetching item full:', err)
      error.value = err.message
      return null
    } finally {
      isLoading.value = false
    }
  }

  // =================================================================
  // Utility Methods
  // =================================================================

  function reset() {
    cardInfo.value = null
    contentPreviews.value = []
    currentItem.value = null
    error.value = null
    pagination.value = {
      page: 1,
      limit: DEFAULT_PAGE_SIZE,
      totalCount: 0,
      hasMore: true
    }
  }

  function resetContentPreviews() {
    contentPreviews.value = []
    pagination.value = {
      ...pagination.value,
      page: 1,
      hasMore: true
    }
  }

  function clearCurrentItem() {
    currentItem.value = null
  }

  // =================================================================
  // Infinite Scroll Handler
  // =================================================================

  /**
   * Create an infinite scroll handler for use with scroll containers
   * @param cardId Card ID to load more items for
   * @param language Current language
   * @param threshold Distance from bottom to trigger load (in pixels) - uses env config if not specified
   */
  function createScrollHandler(
    cardId: string,
    language: string = 'en',
    threshold: number = SCROLL_THRESHOLD
  ) {
    return async (event: Event) => {
      const target = event.target as HTMLElement
      if (!target) return

      const { scrollTop, scrollHeight, clientHeight } = target
      const distanceFromBottom = scrollHeight - scrollTop - clientHeight

      if (distanceFromBottom < threshold && pagination.value.hasMore && !isLoadingMore.value) {
        await loadMore(cardId, language)
      }
    }
  }

  return {
    // State
    cardInfo,
    contentPreviews,
    currentItem,
    pagination,
    isLoading,
    isLoadingMore,
    error,
    
    // Computed
    shouldUsePagination,
    isLargeCard,
    
    // Methods
    fetchCardInfo,
    fetchContentPreviews,
    loadMore,
    fetchItemFull,
    
    // Utilities
    reset,
    resetContentPreviews,
    clearCurrentItem,
    createScrollHandler
  }
}

