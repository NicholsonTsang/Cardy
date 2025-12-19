import { defineStore } from 'pinia';
import { ref } from 'vue';
import { supabase } from '@/lib/supabase';
import { v4 as uuidv4 } from 'uuid';
import { getPageSize, getPreviewLength } from '@/utils/paginationConfig';

// Interfaces for ContentItem data
export interface ContentItem {
    id: string;
    card_id: string;
    parent_id: string | null;
    name: string;
    content: string;
    image_url: string | null; // Cropped/processed image for display
    original_image_url: string | null; // Original uploaded image (raw, uncropped)
    crop_parameters?: any; // JSON object containing crop parameters
    ai_knowledge_base: string; // Content-specific knowledge for AI (max 500 words)
    sort_order: number;
    created_at: string;
    updated_at: string;
}

// Paginated content item with preview (for list views)
export interface ContentItemPreview {
    id: string;
    card_id: string;
    parent_id: string | null;
    name: string;
    content_preview: string;      // Truncated content
    content_length: number;       // Full content length
    image_url: string | null;
    ai_knowledge_base_length: number;
    sort_order: number;
    created_at: string;
    total_count: number;          // Total items for pagination
}

// Pagination state
export interface PaginationState {
    page: number;
    limit: number;
    totalCount: number;
    hasMore: boolean;
}

export interface ContentItemFormData {
    name: string;
    description?: string; // Map to content
    imageUrl?: string | null;
    imageFile?: File | null; // New uploaded file (raw)
    croppedImageFile?: File | null; // Cropped version of the image
    image_url?: string; // Cropped image URL
    original_image_url?: string; // Original image URL
    cropParameters?: any; // JSON object containing crop parameters for dynamic image cropping
    aiKnowledgeBase?: string; // Content-specific knowledge for AI (max 500 words)
    // card_id and parent_id are passed as separate params to createContentItem
}

// Get storage bucket name from environment variable
const USER_FILES_BUCKET = import.meta.env.VITE_SUPABASE_USER_FILES_BUCKET as string;

if (!USER_FILES_BUCKET) {
  console.warn('Supabase user files bucket name (VITE_SUPABASE_USER_FILES_BUCKET) not provided in .env. Uploads may fail.');
}

export const useContentItemStore = defineStore('contentItem', () => {
  const contentItems = ref<ContentItem[]>([]);
  const contentItemPreviews = ref<ContentItemPreview[]>([]);
  const isLoading = ref(false);
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

  // Get ALL content items (existing - for backward compatibility)
  const getContentItems = async (cardId: string): Promise<ContentItem[]> => {
    try {
      isLoading.value = true;
      error.value = null;
      
      const { data, error: err } = await supabase
        .rpc('get_card_content_items', { p_card_id: cardId });
      
      if (err) throw err;
      
      contentItems.value = data as ContentItem[] || [];
      return contentItems.value;
    } catch (err: any) {
      console.error('Error fetching content items:', err);
      error.value = err.message || 'An unknown error occurred';
      return [];
    } finally {
      isLoading.value = false;
    }
  };

  const getContentItemById = async (contentItemId: string): Promise<ContentItem | null> => {
    try {
      isLoading.value = true;
      error.value = null;
      
      const { data, error: err } = await supabase
        .rpc('get_content_item_by_id', { p_content_item_id: contentItemId });
      
      if (err) throw err;
      
      return data?.[0] as ContentItem || null;
    } catch (err: any) {
      console.error('Error fetching content item:', err);
      error.value = err.message || 'An unknown error occurred';
      return null;
    } finally {
      isLoading.value = false;
    }
  };

  // =================================================================
  // PAGINATION & LAZY LOADING METHODS
  // =================================================================

  /**
   * Get paginated content items with preview (truncated content)
   * For list views - reduces payload by ~90%
   */
  const getContentItemsPaginated = async (
    cardId: string,
    page: number = 1,
    limit: number = getPageSize(),
    previewLength: number = getPreviewLength(),
    append: boolean = false
  ): Promise<ContentItemPreview[]> => {
    try {
      isLoading.value = true;
      error.value = null;
      
      const offset = (page - 1) * limit;
      
      const { data, error: err } = await supabase
        .rpc('get_card_content_items_paginated', {
          p_card_id: cardId,
          p_limit: limit,
          p_offset: offset,
          p_preview_length: previewLength
        });
      
      if (err) throw err;
      
      const items = data as ContentItemPreview[] || [];
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
      console.error('Error fetching paginated content items:', err);
      error.value = err.message || 'An unknown error occurred';
      return [];
    } finally {
      isLoading.value = false;
    }
  };

  /**
   * Load more content items (infinite scroll)
   */
  const loadMoreContentItems = async (
    cardId: string,
    previewLength: number = getPreviewLength()
  ): Promise<ContentItemPreview[]> => {
    if (!pagination.value.hasMore || isLoading.value) {
      return [];
    }
    
    const nextPage = pagination.value.page + 1;
    return getContentItemsPaginated(cardId, nextPage, pagination.value.limit, previewLength, true);
  };

  /**
   * Get FULL content item details (for detail view / lazy loading)
   * Call when user taps on an item to see full content
   */
  const getContentItemFull = async (contentItemId: string): Promise<ContentItem | null> => {
    try {
      isLoading.value = true;
      error.value = null;
      
      const { data, error: err } = await supabase
        .rpc('get_content_item_full', { p_content_item_id: contentItemId });
      
      if (err) throw err;
      
      return data?.[0] as ContentItem || null;
    } catch (err: any) {
      console.error('Error fetching full content item:', err);
      error.value = err.message || 'An unknown error occurred';
      return null;
    } finally {
      isLoading.value = false;
    }
  };

  /**
   * Get content items count for a card
   */
  const getContentItemsCount = async (cardId: string): Promise<{
    total_count: number;
    parent_count: number;
    child_count: number;
  } | null> => {
    try {
      const { data, error: err } = await supabase
        .rpc('get_content_items_count', { p_card_id: cardId });
      
      if (err) throw err;
      
      return data?.[0] || null;
    } catch (err: any) {
      console.error('Error fetching content items count:', err);
      return null;
    }
  };

  const createContentItem = async (cardId: string, itemData: ContentItemFormData, parentId: string | null = null): Promise<string | null> => {
    try {
      isLoading.value = true;
      error.value = null;

      let originalImageUrl: string | null = null;
      let croppedImageUrl: string | null = itemData.image_url || null;
      
      // Upload original image if provided
      if (itemData.imageFile) {
        const uploadedUrl = await uploadContentItemImage(itemData.imageFile, cardId, 'original');
        if (uploadedUrl) {
            originalImageUrl = uploadedUrl;
        } else {
            throw new Error('Original image upload failed for content item.');
        }
      }
      
      // Upload cropped image if provided
      if (itemData.croppedImageFile) {
        const uploadedUrl = await uploadContentItemImage(itemData.croppedImageFile, cardId, 'cropped');
        if (uploadedUrl) {
            croppedImageUrl = uploadedUrl;
        } else {
            throw new Error('Cropped image upload failed for content item.');
        }
      } else if (itemData.imageUrl) { // If imageUrl is provided directly (and no file)
        croppedImageUrl = itemData.imageUrl;
      }
      
      const { data, error: err } = await supabase
        .rpc('create_content_item', {
          p_card_id: cardId,
          p_name: itemData.name,
          p_parent_id: parentId,
          p_content: itemData.description || '',
          p_image_url: croppedImageUrl,
          p_original_image_url: originalImageUrl,
          p_crop_parameters: itemData.cropParameters || null,
          p_ai_knowledge_base: itemData.aiKnowledgeBase || '',
        });
      
      if (err) throw err;
      
      return data; // Expecting the new content item ID
    } catch (err: any) {
      console.error('Error creating content item:', err);
      error.value = err.message || 'An unknown error occurred';
      return null;
    } finally {
      isLoading.value = false;
    }
  };

  const updateContentItem = async (contentItemId: string, itemData: ContentItemFormData, cardId: string): Promise<boolean> => {
    try {
      isLoading.value = true;
      error.value = null;

      let originalImageUrl: string | undefined = itemData.original_image_url || undefined;
      let croppedImageUrl: string | undefined = itemData.image_url || undefined;
      
      // Upload new original image if provided
      if (itemData.imageFile) {
        const uploadedUrl = await uploadContentItemImage(itemData.imageFile, cardId, 'original');
        if (uploadedUrl) {
            originalImageUrl = uploadedUrl;
        } else {
            throw new Error('Original image upload failed during update.');
        }
      }
      
      // Upload new cropped image if provided
      if (itemData.croppedImageFile) {
        const uploadedUrl = await uploadContentItemImage(itemData.croppedImageFile, cardId, 'cropped');
        if (uploadedUrl) {
            croppedImageUrl = uploadedUrl;
        } else {
            throw new Error('Cropped image upload failed during update.');
        }
      } else if (itemData.imageUrl) {
        croppedImageUrl = itemData.imageUrl;
      }
      
      const { data, error: err } = await supabase
        .rpc('update_content_item', {
          p_content_item_id: contentItemId,
          p_name: itemData.name,
          p_content: itemData.description || '',
          p_image_url: croppedImageUrl || null,
          p_original_image_url: originalImageUrl || null,
          p_crop_parameters: itemData.cropParameters || null,
          p_ai_knowledge_base: itemData.aiKnowledgeBase || '',
        });
      
      if (err) throw err;
      
      if (cardId) {
        await getContentItems(cardId);
      }
      
      return data; // Expecting boolean success
    } catch (err: any) {
      console.error('Error updating content item:', err);
      error.value = err.message || 'An unknown error occurred';
      return false;
    } finally {
      isLoading.value = false;
    }
  };

  const deleteContentItem = async (contentItemId: string, cardId: string): Promise<boolean> => {
    try {
      isLoading.value = true;
      error.value = null;
      
      const { data, error: err } = await supabase
        .rpc('delete_content_item', { p_content_item_id: contentItemId });
      
      if (err) throw err;
      await getContentItems(cardId);
      return data; // Expecting boolean success
    } catch (err: any) {
      console.error('Error deleting content item:', err);
      error.value = err.message || 'An unknown error occurred';
      return false;
    } finally {
      isLoading.value = false;
    }
  };

  // cardId is passed to construct user-specific path
  // imageType: 'original' or 'cropped' to differentiate file naming
  const uploadContentItemImage = async (file: File, cardIdForPath: string, imageType: 'original' | 'cropped' = 'cropped'): Promise<string | null> => {
    try {
      isLoading.value = true;
      error.value = null;
      
      const { data: { user } } = await supabase.auth.getUser();
      if (!user || !user.id) {
        throw new Error('User not authenticated for image upload.');
      }

      const fileExt = file.name.split('.').pop();
      const fileName = `${uuidv4()}_${imageType}.${fileExt}`;
      // Path structure: user_id/card_id/content-item-images/fileName.ext
      const filePath = `${user.id}/${cardIdForPath}/content-item-images/${fileName}`;
      
      const { error: uploadError } = await supabase.storage
        .from(USER_FILES_BUCKET) // Use the unified bucket name
        .upload(filePath, file);
      
      if (uploadError) throw uploadError;
      
      const { data: { publicUrl } } = supabase.storage
        .from(USER_FILES_BUCKET) // Use the unified bucket name
        .getPublicUrl(filePath);
      
      return publicUrl;
    } catch (err: any) {
      console.error('Error uploading image:', err);
      error.value = err.message || 'An unknown error occurred';
      return null;
    } finally {
      isLoading.value = false;
    }
  };

  const updateContentItemOrder = async (contentItemId: string, newSortOrder: number): Promise<boolean> => {
    try {
      isLoading.value = true;
      error.value = null;
      
      const { data, error: err } = await supabase
        .rpc('update_content_item_order', { 
          p_content_item_id: contentItemId,
          p_new_sort_order: newSortOrder
        });
      
      if (err) throw err;
      return data; // Expecting boolean success
    } catch (err: any) {
      console.error('Error updating content item order:', err);
      error.value = err.message || 'An unknown error occurred';
      return false;
    } finally {
      isLoading.value = false;
    }
  };

  // Migration response interface
  interface MigrationResult {
    success: boolean;
    message: string;
    category_id?: string | null;
    items_moved?: number;
    categories_removed?: number;
  }

  // Move item response interface
  interface MoveItemResult {
    success: boolean;
    message: string;
    item_id: string;
    old_parent_id: string | null;
    new_parent_id: string | null;
    new_sort_order: number;
  }

  // Migrate content from flat mode to grouped mode
  // Creates a default category and moves all top-level items under it
  const migrateToGrouped = async (cardId: string, defaultCategoryName: string = 'Default Category'): Promise<MigrationResult | null> => {
    try {
      isLoading.value = true;
      error.value = null;
      
      const { data, error: err } = await supabase
        .rpc('migrate_content_to_grouped', { 
          p_card_id: cardId,
          p_default_category_name: defaultCategoryName
        });
      
      if (err) throw err;
      
      // Refresh content items after migration
      await getContentItems(cardId);
      
      return data as MigrationResult;
    } catch (err: any) {
      console.error('Error migrating to grouped mode:', err);
      error.value = err.message || 'An unknown error occurred';
      return null;
    } finally {
      isLoading.value = false;
    }
  };

  // Migrate content from grouped mode to flat mode
  // Moves all child items to top level, optionally removes empty categories
  const migrateToFlat = async (cardId: string, removeEmptyCategories: boolean = true): Promise<MigrationResult | null> => {
    try {
      isLoading.value = true;
      error.value = null;
      
      const { data, error: err } = await supabase
        .rpc('migrate_content_to_flat', { 
          p_card_id: cardId,
          p_remove_empty_categories: removeEmptyCategories
        });
      
      if (err) throw err;
      
      // Refresh content items after migration
      await getContentItems(cardId);
      
      return data as MigrationResult;
    } catch (err: any) {
      console.error('Error migrating to flat mode:', err);
      error.value = err.message || 'An unknown error occurred';
      return null;
    } finally {
      isLoading.value = false;
    }
  };

  // Move a content item to a different parent (for cross-parent drag & drop)
  const moveItemToParent = async (
    contentItemId: string, 
    newParentId: string | null, 
    newSortOrder?: number,
    cardId?: string
  ): Promise<MoveItemResult | null> => {
    try {
      isLoading.value = true;
      error.value = null;
      
      const { data, error: err } = await supabase
        .rpc('move_content_item_to_parent', { 
          p_content_item_id: contentItemId,
          p_new_parent_id: newParentId,
          p_new_sort_order: newSortOrder || null
        });
      
      if (err) throw err;
      
      // Refresh content items after move if cardId provided
      if (cardId) {
        await getContentItems(cardId);
      }
      
      return data as MoveItemResult;
    } catch (err: any) {
      console.error('Error moving content item:', err);
      error.value = err.message || 'An unknown error occurred';
      return null;
    } finally {
      isLoading.value = false;
    }
  };

  return {
    // State
    contentItems,
    contentItemPreviews,
    isLoading,
    error,
    pagination,
    
    // Full data methods (backward compatible)
    getContentItems,
    getContentItemById,
    createContentItem,
    updateContentItem,
    deleteContentItem,
    uploadContentItemImage,
    updateContentItemOrder,
    
    // Pagination & lazy loading methods
    resetPagination,
    getContentItemsPaginated,
    loadMoreContentItems,
    getContentItemFull,
    getContentItemsCount,
    
    // Migration methods
    migrateToGrouped,
    migrateToFlat,
    moveItemToParent
  };
}); 