import { defineStore } from 'pinia';
import { ref } from 'vue';
import { supabase } from '@/lib/supabase';
import { v4 as uuidv4 } from 'uuid';

// Get storage bucket name from environment variable
const CARD_STORAGE_BUCKET = import.meta.env.VITE_SUPABASE_CARD_STORAGE_BUCKET as string;

if (!CARD_STORAGE_BUCKET) {
  console.warn('Supabase storage bucket name not provided in .env, using default "cards"');
}

export const useCardStore = defineStore('card', () => {
    const cards = ref([]);
    const isLoading = ref(false);
    const error = ref(null);

    // Fetch all cards for the current user
    const fetchCards = async () => {
        isLoading.value = true;
        error.value = null;
        
        try {
            const { data, error: err } = await supabase
                .rpc('get_user_cards');
                
            if (err) throw err;
            
            cards.value = data || [];
        } catch (err) {
            console.error('Error fetching cards:', err);
            error.value = err.message;
        } finally {
            isLoading.value = false;
        }
    };

    // Add a new card
    const addCard = async (cardData) => {
        isLoading.value = true;
        error.value = null;
        
        try {
            const { data: user } = await supabase.auth.getUser();
            
            if (!user?.user?.id) {
                throw new Error('User not authenticated');
            }
            
            // Upload image first if provided
            let imageUrls = [];
            
            if (cardData.imageFile) {
                const fileExt = cardData.imageFile.name.split('.').pop();
                const fileName = `${uuidv4()}.${fileExt}`;
                const filePath = `card-images/${user.user.id}/${fileName}`;
                
                console.log('Uploading image to:', filePath);
                const { error: uploadError } = await supabase.storage
                    .from(CARD_STORAGE_BUCKET || 'cards')
                    .upload(filePath, cardData.imageFile);
                    
                if (uploadError) throw uploadError;
                console.log('Image uploaded successfully');

                // Get public URL for the uploaded image
                const { data: { publicUrl } } = supabase.storage
                    .from(CARD_STORAGE_BUCKET || 'cards')
                    .getPublicUrl(filePath);
                    
                imageUrls = [publicUrl];
                console.log('Image URL:', publicUrl);
            }
            
            // Create card in database
            const { data, error: createError } = await supabase
                .rpc('create_card', {
                    p_name: cardData.name,
                    p_description: cardData.description,
                    p_image_urls: imageUrls,
                    p_conversation_ai_enabled: cardData.conversationAiEnabled,
                    p_ai_prompt: cardData.aiPrompt || '',
                    p_published: cardData.published || false,
                    p_qr_code_position: cardData.qrCodePosition || 'BR'
                });
                
            if (createError) throw createError;
            
            // Return the newly created card
            return data;
        } catch (err) {
            console.error('Error adding card:', err);
            error.value = err.message;
            throw err;
        } finally {
            isLoading.value = false;
        }
    };

    // Get card by ID
    const getCardById = async (cardId) => {
        isLoading.value = true;
        error.value = null;
        
        try {
            const { data, error: err } = await supabase
                .rpc('get_card_by_id', { 
                    p_card_id: cardId 
                });
                
            if (err) throw err;
            
            return data;
        } catch (err) {
            console.error('Error fetching card details:', err);
            error.value = err.message;
            return null;
        } finally {
            isLoading.value = false;
        }
    };

    // Update an existing card
    const updateCard = async (cardId, updateData) => {
        isLoading.value = true;
        error.value = null;
        
        try {
            // Handle image upload if there's a new image
            if (updateData && updateData.imageFile) {
                const { data: user } = await supabase.auth.getUser();
                const fileExt = updateData.imageFile.name.split('.').pop();
                const fileName = `${uuidv4()}.${fileExt}`;
                const filePath = `card-images/${user.user.id}/${fileName}`;
                
                const { error: uploadError } = await supabase.storage
                    .from(CARD_STORAGE_BUCKET || 'cards')
                    .upload(filePath, updateData.imageFile);
                    
                if (uploadError) throw uploadError;
                
                // Get public URL
                const { data: { publicUrl } } = supabase.storage
                    .from(CARD_STORAGE_BUCKET || 'cards')
                    .getPublicUrl(filePath);
                
                // Add to image URLs
                updateData.image_urls = [publicUrl];
            }
            
            // Create a clean payload without the file object
            const payload = {
                p_card_id: cardId,
                p_name: updateData.name,
                p_description: updateData.description,
                p_image_urls: updateData.image_urls || null,
                p_conversation_ai_enabled: updateData.conversationAiEnabled,
                p_ai_prompt: updateData.aiPrompt || '',
                p_published: updateData.published,
                p_qr_code_position: updateData.qrCodePosition
            };
            
            const { data, error: updateError } = await supabase
                .rpc('update_card', payload);
                
            if (updateError) throw updateError;
            
            // Refresh the cards list
            await fetchCards();
            
            return data;
        } catch (err) {
            console.error('Error updating card:', err);
            error.value = err.message;
            throw err;
        } finally {
            isLoading.value = false;
        }
    };

    // Delete a card
    const deleteCard = async (cardId) => {
        isLoading.value = true;
        error.value = null;
        
        try {
            const { data, error: deleteError } = await supabase
                .rpc('delete_card', {
                    p_card_id: cardId
                });
                
            if (deleteError) throw deleteError;
            
            // Remove from local state
            cards.value = cards.value.filter(card => card.id !== cardId);
            
            return true;
        } catch (err) {
            console.error('Error deleting card:', err);
            error.value = err.message;
            return false;
        } finally {
            isLoading.value = false;
        }
    };

    return {
        cards,
        isLoading,
        error,
        fetchCards,
        addCard,
        getCardById,
        updateCard,
        deleteCard
    };
});
