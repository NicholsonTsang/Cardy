import { defineStore } from 'pinia';
import { ref } from 'vue';
import { supabase } from '@/lib/supabase';
import { getPageSize, getPreviewLength } from '@/utils/paginationConfig';

// Full content item (for detail view)
export interface PublicContentItem {
    content_item_id: string;
    content_item_parent_id: string | null;
    content_item_name: string;
    content_item_content: string;
    content_item_image_url: string | null;
    content_item_ai_knowledge_base: string;
    content_item_sort_order: number;
}

// Content item preview (for list view - truncated content)
export interface PublicContentItemPreview {
    content_item_id: string;
    content_item_parent_id: string | null;
    content_item_name: string;
    content_preview: string;        // Truncated content
    content_length: number;         // Full content length
    content_item_image_url: string | null;
    content_item_sort_order: number;
    crop_parameters?: any;
    total_count: number;
}

// Full content item detail (for lazy loading)
export interface PublicContentItemFull {
    content_item_id: string;
    content_item_parent_id: string | null;
    content_item_name: string;
    content_item_content: string;
    content_item_image_url: string | null;
    content_item_ai_knowledge_base: string;
    content_item_sort_order: number;
    crop_parameters?: any;
    parent_name: string | null;
    prev_item_id: string | null;
    next_item_id: string | null;
}

// Card info only (no content items)
export interface PublicCardInfo {
    card_name: string;
    card_description: string;
    card_image_url: string | null;
    card_crop_parameters?: any;
    card_conversation_ai_enabled: boolean;
    card_ai_instruction: string;
    card_ai_knowledge_base: string;
    card_ai_welcome_general: string;
    card_ai_welcome_item: string;
    card_original_language: string;
    card_has_translation: boolean;
    card_available_languages: string[];
    card_content_mode: string;
    card_is_grouped: boolean;
    card_group_display: string;
    card_billing_type: string;
    card_max_scans: number | null;
    card_current_scans: number;
    card_daily_scan_limit: number | null;
    card_daily_scans: number;
    card_scan_limit_reached: boolean;
    card_monthly_limit_exceeded: boolean;
    card_credits_insufficient: boolean;
    card_id: string;
    content_item_count: number;
    is_activated: boolean;
}

// Full card data (backward compatible - includes all content items)
export interface PublicCardData {
    card_name: string;
    card_description: string;
    card_image_url: string | null;
    card_conversation_ai_enabled: boolean;
    card_ai_instruction: string;
    card_ai_knowledge_base: string;
    card_original_language: string;
    card_has_translation: boolean;
    content_items: PublicContentItem[];
    is_activated: boolean;
}

// Pagination state
export interface PaginationState {
    page: number;
    limit: number;
    totalCount: number;
    hasMore: boolean;
}

// Define a type for the raw RPC response item
interface RawRpcResponseItem {
    card_name: string;
    card_description: string;
    card_image_url: string | null;
    card_conversation_ai_enabled: boolean;
    card_ai_instruction: string;
    card_ai_knowledge_base: string;
    card_original_language: string;
    card_has_translation: boolean;
    content_item_id: string | null; // Can be null if card has no content
    content_item_parent_id: string | null;
    content_item_name: string | null;
    content_item_content: string | null;
    content_item_image_url: string | null;
    content_item_ai_knowledge_base: string | null;
    content_item_sort_order: number | null;
    is_activated: boolean;
}

export const usePublicCardStore = defineStore('publicCard', () => {
    // Legacy state (backward compatible)
    const cardData = ref<PublicCardData | null>(null);
    
    // New optimized state
    const cardInfo = ref<PublicCardInfo | null>(null);
    const contentItemPreviews = ref<PublicContentItemPreview[]>([]);
    const currentContentItem = ref<PublicContentItemFull | null>(null);
    
    const isLoading = ref(false);
    const isLoadingMore = ref(false);
    const error = ref<string | null>(null);
    
    // Pagination state
    const pagination = ref<PaginationState>({
        page: 1,
        limit: getPageSize(),
        totalCount: 0,
        hasMore: true
    });

    // Reset pagination state
    const resetPagination = () => {
        pagination.value = { page: 1, limit: getPageSize(), totalCount: 0, hasMore: true };
        contentItemPreviews.value = [];
    };

    // =================================================================
    // LEGACY METHOD (backward compatible - loads ALL content at once)
    // =================================================================
    const fetchPublicCard = async (issueCardId: string, language: string = 'en') => {
        isLoading.value = true;
        error.value = null;
        cardData.value = null;

        try {
            const { data, error: rpcError } = await supabase.rpc('get_public_card_content', {
                p_issue_card_id: issueCardId,
                p_language: language
            });

            if (rpcError) {
                console.error('Error fetching public card content:', rpcError);
                throw new Error(rpcError.message || 'Failed to load card content.');
            }

            const rpcData = data as RawRpcResponseItem[]; // Type assertion

            if (!rpcData || rpcData.length === 0) {
                if (data && data.length > 0 && data[0].card_name && data[0].content_item_id === null) {
                    cardData.value = {
                        card_name: data[0].card_name,
                        card_description: data[0].card_description,
                        card_image_url: data[0].card_image_url,
                        card_conversation_ai_enabled: data[0].card_conversation_ai_enabled,
                        card_ai_instruction: data[0].card_ai_instruction,
                        card_ai_knowledge_base: data[0].card_ai_knowledge_base,
                        card_original_language: data[0].card_original_language || 'en',
                        card_has_translation: data[0].card_has_translation || false,
                        is_activated: data[0].is_activated,
                        content_items: [],
                    };
                    return;
                }
                throw new Error('Card not found or activation failed. Please check the URL.');
            }

            // Process the flat data into a structured format
            const firstRecord = rpcData[0];
            const contentItems: PublicContentItem[] = rpcData
                .filter((item: RawRpcResponseItem) => item.content_item_id !== null)
                .map((item: RawRpcResponseItem) => ({
                    content_item_id: item.content_item_id!,
                    content_item_parent_id: item.content_item_parent_id,
                    content_item_name: item.content_item_name!,
                    content_item_content: item.content_item_content!,
                    content_item_image_url: item.content_item_image_url,
                    content_item_ai_knowledge_base: item.content_item_ai_knowledge_base!,
                    content_item_sort_order: item.content_item_sort_order!,
                }));
            
            contentItems.sort((a, b) => {
                if (a.content_item_parent_id === null && b.content_item_parent_id !== null) return -1;
                if (a.content_item_parent_id !== null && b.content_item_parent_id === null) return 1;
                return a.content_item_sort_order - b.content_item_sort_order;
            });

            cardData.value = {
                card_name: firstRecord.card_name,
                card_description: firstRecord.card_description,
                card_image_url: firstRecord.card_image_url,
                card_conversation_ai_enabled: firstRecord.card_conversation_ai_enabled,
                card_ai_instruction: firstRecord.card_ai_instruction,
                card_ai_knowledge_base: firstRecord.card_ai_knowledge_base,
                card_original_language: firstRecord.card_original_language || 'en',
                card_has_translation: firstRecord.card_has_translation || false,
                is_activated: firstRecord.is_activated,
                content_items: contentItems,
            };

        } catch (err: any) {
            console.error('Error in fetchPublicCard:', err);
            error.value = err.message || 'An unexpected error occurred.';
            cardData.value = null;
        } finally {
            isLoading.value = false;
        }
    };

    // =================================================================
    // OPTIMIZED METHODS (pagination & lazy loading)
    // =================================================================

    /**
     * Fetch card info only (no content items) - minimal payload ~5KB
     * Use this for initial card load
     * Note: Credit rate is now hardcoded in the stored procedure for security
     */
    const fetchCardInfo = async (
        issueCardId: string, 
        language: string = 'en'
    ): Promise<PublicCardInfo | null> => {
        isLoading.value = true;
        error.value = null;
        cardInfo.value = null;

        try {
            const { data, error: rpcError } = await supabase.rpc('get_public_card_info', {
                p_issue_card_id: issueCardId,
                p_language: language
            });

            if (rpcError) {
                console.error('Error fetching card info:', rpcError);
                throw new Error(rpcError.message || 'Failed to load card info.');
            }

            if (!data || data.length === 0) {
                throw new Error('Card not found. Please check the URL.');
            }

            cardInfo.value = data[0] as PublicCardInfo;
            
            // Update pagination total count
            pagination.value.totalCount = cardInfo.value.content_item_count;
            pagination.value.hasMore = cardInfo.value.content_item_count > 0;
            
            return cardInfo.value;
        } catch (err: any) {
            console.error('Error in fetchCardInfo:', err);
            error.value = err.message || 'An unexpected error occurred.';
            return null;
        } finally {
            isLoading.value = false;
        }
    };

    /**
     * Fetch paginated content items with preview (truncated content)
     * Use for list views - reduces payload by ~90%
     */
    const fetchContentItemsPaginated = async (
        cardId: string,
        language: string = 'en',
        page: number = 1,
        limit: number = getPageSize(),
        previewLength: number = getPreviewLength(),
        append: boolean = false
    ): Promise<PublicContentItemPreview[]> => {
        if (append) {
            isLoadingMore.value = true;
        } else {
            isLoading.value = true;
        }
        
        try {
            const offset = (page - 1) * limit;
            
            const { data, error: rpcError } = await supabase.rpc('get_public_content_items_paginated', {
                p_card_id: cardId,
                p_language: language,
                p_limit: limit,
                p_offset: offset,
                p_preview_length: previewLength
            });

            if (rpcError) {
                console.error('Error fetching paginated content:', rpcError);
                throw new Error(rpcError.message || 'Failed to load content items.');
            }

            const items = data as PublicContentItemPreview[] || [];
            const totalCount = items.length > 0 ? items[0].total_count : 0;

            // Update pagination state
            pagination.value = {
                page,
                limit,
                totalCount,
                hasMore: offset + items.length < totalCount
            };

            // Append or replace
            if (append) {
                contentItemPreviews.value = [...contentItemPreviews.value, ...items];
            } else {
                contentItemPreviews.value = items;
            }

            return items;
        } catch (err: any) {
            console.error('Error in fetchContentItemsPaginated:', err);
            error.value = err.message || 'An unexpected error occurred.';
            return [];
        } finally {
            isLoading.value = false;
            isLoadingMore.value = false;
        }
    };

    /**
     * Load more content items (infinite scroll)
     */
    const loadMoreContentItems = async (
        cardId: string,
        language: string = 'en',
        previewLength: number = getPreviewLength()
    ): Promise<PublicContentItemPreview[]> => {
        if (!pagination.value.hasMore || isLoadingMore.value) {
            return [];
        }

        const nextPage = pagination.value.page + 1;
        return fetchContentItemsPaginated(cardId, language, nextPage, pagination.value.limit, previewLength, true);
    };

    /**
     * Fetch FULL content item details (for detail view / lazy loading)
     * Call when user taps on an item to see full content
     */
    const fetchContentItemFull = async (
        contentItemId: string,
        language: string = 'en'
    ): Promise<PublicContentItemFull | null> => {
        isLoading.value = true;
        error.value = null;

        try {
            const { data, error: rpcError } = await supabase.rpc('get_public_content_item_full', {
                p_content_item_id: contentItemId,
                p_language: language
            });

            if (rpcError) {
                console.error('Error fetching content item full:', rpcError);
                throw new Error(rpcError.message || 'Failed to load content item.');
            }

            if (!data || data.length === 0) {
                throw new Error('Content item not found.');
            }

            currentContentItem.value = data[0] as PublicContentItemFull;
            return currentContentItem.value;
        } catch (err: any) {
            console.error('Error in fetchContentItemFull:', err);
            error.value = err.message || 'An unexpected error occurred.';
            return null;
        } finally {
            isLoading.value = false;
        }
    };

    /**
     * Clear current content item (when navigating away from detail view)
     */
    const clearCurrentContentItem = () => {
        currentContentItem.value = null;
    };

    /**
     * Clear all state
     */
    const clearAll = () => {
        cardData.value = null;
        cardInfo.value = null;
        contentItemPreviews.value = [];
        currentContentItem.value = null;
        error.value = null;
        resetPagination();
    };

    return {
        // Legacy state & methods (backward compatible)
        cardData,
        fetchPublicCard,
        
        // Optimized state
        cardInfo,
        contentItemPreviews,
        currentContentItem,
        pagination,
        
        // Loading states
        isLoading,
        isLoadingMore,
        error,
        
        // Optimized methods
        fetchCardInfo,
        fetchContentItemsPaginated,
        loadMoreContentItems,
        fetchContentItemFull,
        
        // Utility methods
        resetPagination,
        clearCurrentContentItem,
        clearAll
    };
});
