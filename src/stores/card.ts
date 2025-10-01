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
    image_url: string | null; // Cropped/processed image for display
    original_image_url: string | null; // Original uploaded image (raw, uncropped)
    crop_parameters?: any; // JSON object containing crop parameters
    conversation_ai_enabled: boolean;
    ai_prompt: string;
    created_at: string;
    updated_at: string;
}

export interface CardFormData {
    name: string;
    description: string;
    imageFile?: File | null; // New uploaded file (raw)
    croppedImageFile?: File | null; // Cropped version of the image
    image_url?: string; // Cropped image URL
    original_image_url?: string; // Original image URL
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
            const { data: { user } } = await supabase.auth.getUser();
            
            if (!user || !user.id) {
                throw new Error('User not authenticated');
            }
            
            let originalImageUrl: string | null = null;
            let croppedImageUrl: string | null = null;
            
            // Upload original image if provided
            if (cardData.imageFile) {
                const fileExt = cardData.imageFile.name.split('.').pop();
                const originalFileName = `${uuidv4()}_original.${fileExt}`;
                const originalFilePath = `${user.id}/card-images/${originalFileName}`;
                
                console.log('Uploading original image to:', originalFilePath);
                const { error: uploadError } = await supabase.storage
                    .from(USER_FILES_BUCKET)
                    .upload(originalFilePath, cardData.imageFile);
                    
                if (uploadError) throw uploadError;
                console.log('Original image uploaded successfully');

                const { data: { publicUrl } } = supabase.storage
                    .from(USER_FILES_BUCKET)
                    .getPublicUrl(originalFilePath);
                    
                if (publicUrl) {
                    originalImageUrl = publicUrl;
                }
                console.log('Original image URL:', publicUrl);
            }
            
            // Upload cropped image if provided
            if (cardData.croppedImageFile) {
                const fileExt = cardData.croppedImageFile.name.split('.').pop();
                const croppedFileName = `${uuidv4()}_cropped.${fileExt}`;
                const croppedFilePath = `${user.id}/card-images/${croppedFileName}`;
                
                console.log('Uploading cropped image to:', croppedFilePath);
                const { error: uploadError } = await supabase.storage
                    .from(USER_FILES_BUCKET)
                    .upload(croppedFilePath, cardData.croppedImageFile);
                    
                if (uploadError) throw uploadError;
                console.log('Cropped image uploaded successfully');

                const { data: { publicUrl } } = supabase.storage
                    .from(USER_FILES_BUCKET)
                    .getPublicUrl(croppedFilePath);
                    
                if (publicUrl) {
                    croppedImageUrl = publicUrl;
                }
                console.log('Cropped image URL:', publicUrl);
            }
            
            const { data, error: createError } = await supabase
                .rpc('create_card', {
                    p_name: cardData.name,
                    p_description: cardData.description,
                    p_image_url: croppedImageUrl,
                    p_original_image_url: originalImageUrl,
                    p_crop_parameters: cardData.cropParameters || null,
                    p_conversation_ai_enabled: cardData.conversation_ai_enabled,
                    p_ai_prompt: cardData.ai_prompt,
                    p_qr_code_position: cardData.qr_code_position
                });
                
            if (createError) throw createError;
            
            return data;
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
            const { data: { user } } = await supabase.auth.getUser();
            if (!user || !user.id) { 
                throw new Error('User not authenticated for image upload');
            }
            
            let originalImageUrl: string | undefined = updateData.original_image_url;
            let croppedImageUrl: string | undefined = updateData.image_url;
            
            // Upload new original image if provided
            if (updateData.imageFile) {
                const fileExt = updateData.imageFile.name.split('.').pop();
                const originalFileName = `${uuidv4()}_original.${fileExt}`;
                const originalFilePath = `${user.id}/card-images/${originalFileName}`;
                
                const { error: uploadError } = await supabase.storage
                    .from(USER_FILES_BUCKET)
                    .upload(originalFilePath, updateData.imageFile);
                    
                if (uploadError) throw uploadError;
                
                const { data: { publicUrl } } = supabase.storage
                    .from(USER_FILES_BUCKET)
                    .getPublicUrl(originalFilePath);
                
                if (publicUrl) {
                    originalImageUrl = publicUrl;
                }
            }
            
            // Upload new cropped image if provided
            if (updateData.croppedImageFile) {
                const fileExt = updateData.croppedImageFile.name.split('.').pop();
                const croppedFileName = `${uuidv4()}_cropped.${fileExt}`;
                const croppedFilePath = `${user.id}/card-images/${croppedFileName}`;
                
                const { error: uploadError } = await supabase.storage
                    .from(USER_FILES_BUCKET)
                    .upload(croppedFilePath, updateData.croppedImageFile);
                    
                if (uploadError) throw uploadError;
                
                const { data: { publicUrl } } = supabase.storage
                    .from(USER_FILES_BUCKET)
                    .getPublicUrl(croppedFilePath);
                
                if (publicUrl) {
                    croppedImageUrl = publicUrl;
                }
            }
            
            const payload = {
                p_card_id: cardId,
                p_name: updateData.name,
                p_description: updateData.description,
                p_image_url: croppedImageUrl || null,
                p_original_image_url: originalImageUrl || null,
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
