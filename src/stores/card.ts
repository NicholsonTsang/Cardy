import { defineStore } from 'pinia';
import { ref } from 'vue';
import { supabase } from '@/lib/supabase';
import { v4 as uuidv4 } from 'uuid';

// Content mode types
export type ContentMode = 'single' | 'grid' | 'list' | 'cards';
export type GroupDisplay = 'expanded' | 'collapsed';

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
    ai_instruction: string; // AI role and guidelines (max 100 words)
    ai_knowledge_base: string; // Background knowledge for AI (max 2000 words)
    translations?: Record<string, any>; // JSONB translations by language code
    original_language?: string; // Original language code (e.g., 'en')
    content_hash?: string; // MD5 hash for detecting content changes
    last_content_update?: string; // Timestamp of last content update
    content_mode: ContentMode; // Content rendering mode: single, grid, list, cards
    is_grouped: boolean; // Whether content is organized into categories
    group_display: GroupDisplay; // How grouped items display: expanded or collapsed
    billing_type: 'physical' | 'digital'; // Billing model: physical = per-card, digital = per-scan
    max_scans: number | null; // NULL for physical (unlimited), Integer for digital (total limit)
    current_scans: number; // Current total scan count (for digital)
    daily_scan_limit: number | null; // Daily scan limit for digital access (NULL = unlimited)
    daily_scans: number; // Today's scan count (for digital)
    is_access_enabled: boolean; // Toggle to enable/disable QR code access (for digital cards)
    access_token: string; // Unique token for access URL (can be regenerated)
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
    ai_instruction: string; // AI role and guidelines (max 100 words)
    ai_knowledge_base: string; // Background knowledge for AI (max 2000 words)
    qr_code_position: string;
    original_language?: string; // Original language code (e.g., 'en')
    content_mode?: ContentMode; // Content rendering mode
    is_grouped?: boolean; // Whether content is organized into categories
    group_display?: GroupDisplay; // How grouped items display
    billing_type?: 'physical' | 'digital'; // Billing model
    max_scans?: number | null; // Total scan limit for digital cards
    daily_scan_limit?: number | null; // Daily scan limit for digital cards (default: 500)
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
        // Description is optional (especially for digital access modes)
        
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
            
            // Get default daily limit from env
            const defaultDailyLimit = Number(import.meta.env.VITE_DIGITAL_ACCESS_DEFAULT_DAILY_LIMIT) || 500;
            
            const { data, error: createError } = await supabase
                .rpc('create_card', {
                    p_name: cardData.name,
                    p_description: cardData.description,
                    p_image_url: croppedImageUrl,
                    p_original_image_url: originalImageUrl,
                    p_crop_parameters: cardData.cropParameters || null,
                    p_conversation_ai_enabled: cardData.conversation_ai_enabled,
                    p_ai_instruction: cardData.ai_instruction,
                    p_ai_knowledge_base: cardData.ai_knowledge_base,
                    p_qr_code_position: cardData.qr_code_position,
                    p_original_language: cardData.original_language || 'en',
                    p_content_mode: cardData.content_mode || 'list',
                    p_is_grouped: cardData.is_grouped || false,
                    p_group_display: cardData.group_display || 'expanded',
                    p_billing_type: cardData.billing_type || 'physical',
                    p_max_scans: cardData.billing_type === 'digital' ? (cardData.max_scans || null) : null,
                    p_daily_scan_limit: cardData.billing_type === 'digital' ? (cardData.daily_scan_limit ?? defaultDailyLimit) : null
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
                p_ai_instruction: updateData.ai_instruction,
                p_ai_knowledge_base: updateData.ai_knowledge_base,
                p_qr_code_position: updateData.qr_code_position,
                p_original_language: updateData.original_language || 'en',
                p_content_mode: updateData.content_mode || null,
                p_is_grouped: updateData.is_grouped ?? null,
                p_group_display: updateData.group_display || null,
                p_billing_type: updateData.billing_type || null,
                p_max_scans: updateData.billing_type === 'digital' ? (updateData.max_scans || null) : null,
                p_daily_scan_limit: updateData.billing_type === 'digital' ? (updateData.daily_scan_limit || null) : null
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

    // Toggle access enabled/disabled for a digital card
    const toggleCardAccess = async (cardId: string, isEnabled: boolean): Promise<boolean> => {
        isLoading.value = true;
        error.value = null;
        
        try {
            const { error: toggleError } = await supabase
                .rpc('toggle_card_access', {
                    p_card_id: cardId,
                    p_is_enabled: isEnabled
                });
                
            if (toggleError) throw toggleError;
            
            // Update local state
            const card = cards.value.find(c => c.id === cardId);
            if (card) {
                card.is_access_enabled = isEnabled;
            }
            
            return true;
        } catch (err: any) {
            console.error('Error toggling card access:', err);
            error.value = err.message || 'An unknown error occurred';
            return false;
        } finally {
            isLoading.value = false;
        }
    };

    // Regenerate access token for a digital card (invalidates old QR codes)
    const regenerateAccessToken = async (cardId: string): Promise<string | null> => {
        isLoading.value = true;
        error.value = null;
        
        try {
            const { data, error: regenError } = await supabase
                .rpc('regenerate_access_token', {
                    p_card_id: cardId
                });
                
            if (regenError) throw regenError;
            
            // Update local state
            const card = cards.value.find(c => c.id === cardId);
            if (card && data) {
                card.access_token = data;
            }
            
            return data;
        } catch (err: any) {
            console.error('Error regenerating access token:', err);
            error.value = err.message || 'An unknown error occurred';
            return null;
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
        deleteCard,
        toggleCardAccess,
        regenerateAccessToken
    };
});
