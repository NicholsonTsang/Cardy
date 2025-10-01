import { defineStore } from 'pinia';
import { ref } from 'vue';
import { supabase } from '@/lib/supabase';
import { v4 as uuidv4 } from 'uuid';

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
    ai_metadata: string;
    sort_order: number;
    created_at: string;
    updated_at: string;
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
    aiMetadata?: string;
    // card_id and parent_id are passed as separate params to createContentItem
}

// Get storage bucket name from environment variable
const USER_FILES_BUCKET = import.meta.env.VITE_SUPABASE_USER_FILES_BUCKET as string;

if (!USER_FILES_BUCKET) {
  console.warn('Supabase user files bucket name (VITE_SUPABASE_USER_FILES_BUCKET) not provided in .env. Uploads may fail.');
}

export const useContentItemStore = defineStore('contentItem', () => {
  const contentItems = ref<ContentItem[]>([]);
  const isLoading = ref(false);
  const error = ref<string | null>(null);

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
          p_ai_metadata: itemData.aiMetadata || '',
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
          p_ai_metadata: itemData.aiMetadata || '',
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

  return {
    contentItems,
    isLoading,
    error,
    getContentItems,
    getContentItemById,
    createContentItem,
    updateContentItem,
    deleteContentItem,
    uploadContentItemImage,
    updateContentItemOrder
  };
}); 