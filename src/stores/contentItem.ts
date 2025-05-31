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
    image_urls: string[] | null;
    conversation_ai_enabled: boolean;
    ai_prompt: string;
    sort_order: number;
    created_at: string;
    updated_at: string;
}

export interface ContentItemFormData {
    name: string;
    description?: string; // Map to content
    imageUrl?: string | null;
    imageFile?: File | null;
    image_urls?: string[];
    conversationAiEnabled?: boolean;
    aiPrompt?: string;
    // card_id and parent_id are passed as separate params to createContentItem
}

// Get storage bucket name from environment variable
const USER_FILES_BUCKET = import.meta.env.VITE_SUPABASE_USER_FILES_BUCKET as string;

if (!USER_FILES_BUCKET) {
  console.warn('Supabase user files bucket name (VITE_SUPABASE_USER_FILES_BUCKET) not provided in .env. Uploads may fail.');
}

export const useContentItemStore = defineStore('contentItem', () => {
  const contentItems = ref<ContentItem[]>([]);
  const loading = ref(false);
  const error = ref<string | null>(null);

  const getContentItems = async (cardId: string): Promise<ContentItem[]> => {
    try {
      loading.value = true;
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
      loading.value = false;
    }
  };

  const getContentItemById = async (contentItemId: string): Promise<ContentItem | null> => {
    try {
      loading.value = true;
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
      loading.value = false;
    }
  };

  const createContentItem = async (cardId: string, itemData: ContentItemFormData, parentId: string | null = null): Promise<string | null> => {
    try {
      loading.value = true;
      error.value = null;

      let finalImageUrls: string[] = itemData.image_urls || [];
      if (itemData.imageFile) {
        const uploadedUrl = await uploadContentItemImage(itemData.imageFile, cardId);
        if (uploadedUrl) {
            finalImageUrls = [uploadedUrl];
        } else {
            throw new Error('Image upload failed for content item.');
        }
      } else if (itemData.imageUrl) { // If imageUrl is provided directly (and no file)
        finalImageUrls = [itemData.imageUrl];
      }
      
      const { data, error: err } = await supabase
        .rpc('create_content_item', {
          p_card_id: cardId,
          p_parent_id: parentId,
          p_name: itemData.name,
          p_content: itemData.description || '',
          p_image_urls: finalImageUrls,
          p_conversation_ai_enabled: itemData.conversationAiEnabled || false,
          p_ai_prompt: itemData.aiPrompt || ''
        });
      
      if (err) throw err;
      
      return data; // Expecting the new content item ID
    } catch (err: any) {
      console.error('Error creating content item:', err);
      error.value = err.message || 'An unknown error occurred';
      return null;
    } finally {
      loading.value = false;
    }
  };

  const updateContentItem = async (contentItemId: string, itemData: ContentItemFormData, cardId: string): Promise<boolean> => {
    try {
      loading.value = true;
      error.value = null;

      let finalImageUrls: string[] | null = itemData.image_urls || null;
       if (itemData.imageFile) {
        const uploadedUrl = await uploadContentItemImage(itemData.imageFile, cardId); // Pass cardId for path
        if (uploadedUrl) {
            finalImageUrls = [uploadedUrl];
        } else {
            throw new Error('Image upload failed during update.');
        }
      } else if (itemData.imageUrl) {
        finalImageUrls = [itemData.imageUrl];
      }
      
      const { data, error: err } = await supabase
        .rpc('update_content_item', {
          p_content_item_id: contentItemId,
          p_name: itemData.name,
          p_content: itemData.description || '',
          p_image_urls: finalImageUrls, // Can be null to remove images
          p_conversation_ai_enabled: itemData.conversationAiEnabled,
          p_ai_prompt: itemData.aiPrompt || ''
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
      loading.value = false;
    }
  };

  const deleteContentItem = async (contentItemId: string, cardId: string): Promise<boolean> => {
    try {
      loading.value = true;
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
      loading.value = false;
    }
  };

  // cardId is passed to construct user-specific path
  const uploadContentItemImage = async (file: File, cardIdForPath: string): Promise<string | null> => {
    try {
      loading.value = true;
      error.value = null;
      
      const { data: { user } } = await supabase.auth.getUser();
      if (!user || !user.id) {
        throw new Error('User not authenticated for image upload.');
      }

      const fileExt = file.name.split('.').pop();
      const fileName = `${uuidv4()}.${fileExt}`;
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
      loading.value = false;
    }
  };

  const updateContentItemOrder = async (contentItemId: string, newSortOrder: number): Promise<boolean> => {
    try {
      loading.value = true;
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
      loading.value = false;
    }
  };

  return {
    contentItems,
    loading,
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