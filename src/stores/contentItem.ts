import { defineStore } from 'pinia';
import { ref, computed } from 'vue';
import { supabase } from '@/lib/supabase';

export const useContentItemStore = defineStore('contentItem', () => {
  const contentItems = ref<any[]>([]);
  const loading = ref(false);
  const error = ref<string | null>(null);

  // Get all content items for a card
  const getContentItems = async (cardId: string) => {
    try {
      loading.value = true;
      error.value = null;
      
      const { data, error: err } = await supabase
        .rpc('get_card_content_items', { p_card_id: cardId });
      
      if (err) throw err;
      
      contentItems.value = data || [];
      return data;
    } catch (err: any) {
      console.error('Error fetching content items:', err);
      error.value = err.message;
      return [];
    } finally {
      loading.value = false;
    }
  };

  // Get a single content item by ID
  const getContentItemById = async (contentItemId: string) => {
    try {
      loading.value = true;
      error.value = null;
      
      const { data, error: err } = await supabase
        .rpc('get_content_item_by_id', { p_content_item_id: contentItemId });
      
      if (err) throw err;
      
      return data?.[0] || null;
    } catch (err: any) {
      console.error('Error fetching content item:', err);
      error.value = err.message;
      return null;
    } finally {
      loading.value = false;
    }
  };

  // Create a new content item
  const createContentItem = async (cardId: string, contentItem: any, parentId: string | null = null) => {
    try {
      loading.value = true;
      error.value = null;
      
      const { data, error: err } = await supabase
        .rpc('create_content_item', {
          p_card_id: cardId,
          p_parent_id: parentId,
          p_name: contentItem.name,
          p_content: contentItem.description || '',
          p_image_urls: contentItem.imageUrl ? [contentItem.imageUrl] : [],
          p_conversation_ai_enabled: contentItem.conversationAiEnabled || false,
          p_ai_prompt: contentItem.aiPrompt || ''
        });
      
      if (err) throw err;
      
      return data; // Return the created item ID
    } catch (err: any) {
      console.error('Error creating content item:', err);
      error.value = err.message;
      return null;
    } finally {
      loading.value = false;
    }
  };

  // Update an existing content item
  const updateContentItem = async (contentItemId: string, contentItem: any, cardId: string) => {
    try {
      loading.value = true;
      error.value = null;
      
      const { data, error: err } = await supabase
        .rpc('update_content_item', {
          p_content_item_id: contentItemId,
          p_name: contentItem.name,
          p_content: contentItem.description || '',
          p_image_urls: contentItem.imageUrl ? [contentItem.imageUrl] : null,
          p_conversation_ai_enabled: contentItem.conversationAiEnabled,
          p_ai_prompt: contentItem.aiPrompt || ''
        });
      
      if (err) throw err;
      
      // Refresh the content items list
      if (cardId) {
        await getContentItems(cardId);
      }
      
      return data;
    } catch (err: any) {
      console.error('Error updating content item:', err);
      error.value = err.message;
      return false;
    } finally {
      loading.value = false;
    }
  };

  // Delete a content item
  const deleteContentItem = async (contentItemId: string, cardId: string) => {
    try {
      loading.value = true;
      error.value = null;
      
      const { data, error: err } = await supabase
        .rpc('delete_content_item', { p_content_item_id: contentItemId });
      
      if (err) throw err;
      
      // Refresh the content items list
      await getContentItems(cardId);
      
      return data;
    } catch (err: any) {
      console.error('Error deleting content item:', err);
      error.value = err.message;
      return false;
    } finally {
      loading.value = false;
    }
  };

  // Upload image for content item
  const uploadContentItemImage = async (file: File) => {
    try {
      loading.value = true;
      error.value = null;
      
      // Generate a unique file name
      const fileExt = file.name.split('.').pop();
      const fileName = `${Math.random().toString(36).substring(2, 15)}_${Date.now()}.${fileExt}`;
      const filePath = `content-items/${fileName}`;
      
      // Upload the file to Supabase Storage
      const { data, error: uploadError } = await supabase.storage
        .from('images')
        .upload(filePath, file);
      
      if (uploadError) throw uploadError;
      
      // Get the public URL for the uploaded file
      const { data: { publicUrl } } = supabase.storage
        .from('images')
        .getPublicUrl(filePath);
      
      return publicUrl;
    } catch (err: any) {
      console.error('Error uploading image:', err);
      error.value = err.message;
      return null;
    } finally {
      loading.value = false;
    }
  };

  // Update content item order
  const updateContentItemOrder = async (contentItemId: string, newSortOrder: number) => {
    try {
      loading.value = true;
      error.value = null;
      
      const { data, error: err } = await supabase
        .rpc('update_content_item_order', { 
          p_content_item_id: contentItemId,
          p_new_sort_order: newSortOrder
        });
      
      if (err) throw err;
      
      return data;
    } catch (err: any) {
      console.error('Error updating content item order:', err);
      error.value = err.message;
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