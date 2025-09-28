import { defineStore } from 'pinia';
import { ref } from 'vue';
import { supabase } from '@/lib/supabase';
import { v4 as uuidv4 } from 'uuid';

// Define interfaces for Card data
export interface Card {
    id: string;
    user_id: string;
    name: string;
    description: string;
    qr_code_position: string;
    image_url: string | null;
    conversation_ai_enabled: boolean;
    ai_prompt: string;
    created_at: string;
    updated_at: string;
    // Add other fields from get_user_cards if necessary
}

export interface CardFormData {
    name: string;
    description: string;
    imageFile?: File | null;
    image_url?: string;
    cropParameters?: any; // JSON object containing crop parameters for dynamic image cropping
    conversation_ai_enabled: boolean;
    ai_prompt: string;
    qr_code_position: string;
    id?: string; // Optional for updates
}

// Get storage bucket name from environment variable
const USER_FILES_BUCKET = import.meta.env.VITE_SUPABASE_USER_FILES_BUCKET as string;

if (!USER_FILES_BUCKET) {
  console.warn('Supabase user files bucket name (VITE_SUPABASE_USER_FILES_BUCKET) not provided in .env. Uploads may fail.');
}

export const useCardStore = defineStore('card', () => {
    const cards = ref<Card[]>([]);
    const isLoading = ref(false);
    const error = ref<string | null>(null);

    // Fetch all cards for the current user
    const fetchCards = async () => {
        isLoading.value = true;
        error.value = null;
        
        try {
            const { data, error: err } = await supabase
                .rpc('get_user_cards');
                
            if (err) throw err;
            
            cards.value = data as Card[] || [];
        } catch (err: any) {
            console.error('Error fetching cards:', err);
            error.value = err.message || 'An unknown error occurred';
        } finally {
            isLoading.value = false;
        }
    };

    // Add a new card
    const addCard = async (cardData: CardFormData) => {
        isLoading.value = true;
        error.value = null;
        
        // Validate required fields
        if (!cardData.name?.trim()) {
            const errorMsg = 'Card name is required';
            error.value = errorMsg;
            throw new Error(errorMsg);
        }
        if (!cardData.description?.trim()) {
            const errorMsg = 'Card description is required';
            error.value = errorMsg;
            throw new Error(errorMsg);
        }
        
        try {
            const { data: { user } } = await supabase.auth.getUser(); // Destructure user directly
            
            if (!user || !user.id) { // Check user and user.id
                throw new Error('User not authenticated');
            }
            
            let imageUrl: string | null = null; // Explicitly type imageUrl
            
            if (cardData.imageFile) {
                const fileExt = cardData.imageFile.name.split('.').pop();
                const fileName = `${uuidv4()}.${fileExt}`;
                // Updated filePath to include user.id
                const filePath = `${user.id}/card-images/${fileName}`;
                
                console.log('Uploading image to:', filePath);
                const { error: uploadError } = await supabase.storage
                    .from(USER_FILES_BUCKET)
                    .upload(filePath, cardData.imageFile);
                    
                if (uploadError) throw uploadError;
                console.log('Image uploaded successfully');

                const { data: { publicUrl } } = supabase.storage
                    .from(USER_FILES_BUCKET)
                    .getPublicUrl(filePath);
                    
                if (publicUrl) {
                    imageUrl = publicUrl;
                }
                console.log('Image URL:', publicUrl);
            }
            
            const { data, error: createError } = await supabase
                .rpc('create_card', {
                    p_name: cardData.name,
                    p_description: cardData.description,
                    p_image_url: imageUrl,
                    p_crop_parameters: cardData.cropParameters || null,
                    p_conversation_ai_enabled: cardData.conversation_ai_enabled,
                    p_ai_prompt: cardData.ai_prompt,
                    p_qr_code_position: cardData.qr_code_position
                });
                
            if (createError) throw createError;
            
            return data; // Assuming data is the new card ID or object
        } catch (err: any) {
            console.error('Error adding card:', err);
            error.value = err.message || 'An unknown error occurred';
            throw err;
        } finally {
            isLoading.value = false;
        }
    };

    const getCardById = async (cardId: string): Promise<Card | null> => {
        isLoading.value = true;
        error.value = null;
        
        try {
            const { data, error: err } = await supabase
                .rpc('get_card_by_id', { 
                    p_card_id: cardId 
                });
                
            if (err) throw err;
            
            return data ? data[0] as Card : null; // Assuming RPC returns an array
        } catch (err: any) {
            console.error('Error fetching card details:', err);
            error.value = err.message || 'An unknown error occurred';
            return null;
        } finally {
            isLoading.value = false;
        }
    };

    const updateCard = async (cardId: string, updateData: CardFormData) => {
        isLoading.value = true;
        error.value = null;
        
        try {
            if (updateData.imageFile) {
                const { data: { user } } = await supabase.auth.getUser();
                 if (!user || !user.id) { 
                    throw new Error('User not authenticated for image upload');
                }
                const fileExt = updateData.imageFile.name.split('.').pop();
                const fileName = `${uuidv4()}.${fileExt}`;
                 // Updated filePath to include user.id
                const filePath = `${user.id}/card-images/${fileName}`;
                
                const { error: uploadError } = await supabase.storage
                    .from(USER_FILES_BUCKET)
                    .upload(filePath, updateData.imageFile);
                    
                if (uploadError) throw uploadError;
                
                const { data: { publicUrl } } = supabase.storage
                    .from(USER_FILES_BUCKET)
                    .getPublicUrl(filePath);
                
                if (publicUrl) {
                    updateData.image_url = publicUrl; // Ensure image_url is part of CardFormData
                } else {
                    updateData.image_url = updateData.image_url || undefined; // Keep existing or initialize
                }
            }
            
            const payload = {
                p_card_id: cardId,
                p_name: updateData.name,
                p_description: updateData.description,
                p_image_url: updateData.image_url || null,
                p_crop_parameters: updateData.cropParameters || null,
                p_conversation_ai_enabled: updateData.conversation_ai_enabled,
                p_ai_prompt: updateData.ai_prompt,
                p_qr_code_position: updateData.qr_code_position
            };
            
            const { data, error: updateError } = await supabase
                .rpc('update_card', payload);
                
            if (updateError) throw updateError;
            
            await fetchCards();
            
            return data;
        } catch (err: any) {
            console.error('Error updating card:', err);
            error.value = err.message || 'An unknown error occurred';
            throw err;
        } finally {
            isLoading.value = false;
        }
    };

    const deleteCard = async (cardId: string): Promise<boolean> => {
        isLoading.value = true;
        error.value = null;
        
        try {
            const { error: deleteError } = await supabase // Removed `data` as it's not used
                .rpc('delete_card', {
                    p_card_id: cardId
                });
                
            if (deleteError) throw deleteError;
            
            cards.value = cards.value.filter(card => card.id !== cardId);
            
            return true;
        } catch (err: any) {
            console.error('Error deleting card:', err);
            error.value = err.message || 'An unknown error occurred';
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
