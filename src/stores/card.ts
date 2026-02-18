import { defineStore } from 'pinia';
import { ref } from 'vue';
import { supabase } from '@/lib/supabase';
import { v4 as uuidv4 } from 'uuid';

// Content mode types
export type ContentMode = 'single' | 'grid' | 'list' | 'cards';
export type GroupDisplay = 'expanded' | 'collapsed';

// Access Token interface (Multiple QR codes per project)
export interface AccessToken {
    id: string;
    card_id: string;
    name: string; // Display name (e.g., "Front Entrance", "Table 5")
    access_token: string; // 12-char URL-safe token
    is_enabled: boolean; // Toggle to enable/disable this specific QR code
    daily_session_limit: number | null; // Daily session limit (NULL = unlimited)
    monthly_session_limit: number | null; // Monthly session limit (NULL = unlimited)
    daily_voice_limit: number | null; // Daily voice time limit in seconds (NULL = unlimited)
    monthly_voice_limit: number | null; // Monthly voice time limit in seconds (NULL = unlimited)
    total_sessions: number; // All-time sessions for this QR code
    daily_sessions: number; // Today's session count
    monthly_sessions: number; // Current month's session count
    last_session_date: string | null; // Date of last session
    current_month: string | null; // Month being tracked (1st of month)
    created_at: string;
    updated_at: string;
}

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
    realtime_voice_enabled: boolean; // Per-project toggle for realtime voice conversations
    ai_instruction: string; // AI role and guidelines (max 100 words)
    ai_knowledge_base: string; // Background knowledge for AI (max 2000 words)
    ai_welcome_general: string; // Custom welcome message for General AI Assistant (card-level)
    ai_welcome_item: string; // Custom welcome message for Content Item AI Assistant
    translations?: Record<string, any>; // JSONB translations by language code
    original_language?: string; // Original language code (e.g., 'en')
    content_hash?: string; // MD5 hash for detecting content changes
    last_content_update?: string; // Timestamp of last content update
    content_mode: ContentMode; // Content rendering mode: single, grid, list, cards
    is_grouped: boolean; // Whether content is organized into categories
    group_display: GroupDisplay; // How grouped items display: expanded or collapsed
    billing_type: 'digital'; // Billing model: per-session subscription
    default_daily_session_limit: number | null; // Default daily limit for new QR codes (NULL = unlimited)
    default_daily_voice_limit: number | null; // Default daily voice call limit in seconds for new QR codes (NULL = unlimited)
    metadata?: Record<string, any>; // Extensible JSONB metadata for future features
    // Computed from access_tokens (aggregated stats)
    total_sessions: number; // Sum of all tokens' all-time sessions
    monthly_sessions: number; // Sum of all tokens' monthly sessions
    daily_sessions: number; // Sum of today's sessions across all tokens
    active_qr_codes: number; // Count of enabled QR codes
    total_qr_codes: number; // Total QR codes for this project
    // Access tokens array (populated by fetchAccessTokens)
    access_tokens?: AccessToken[];
    created_at: string;
    updated_at: string;
    // Template library fields (returned by get_user_cards)
    is_template?: boolean; // Whether this card is linked to a content template
    template_slug?: string | null; // Template slug if is_template is true
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
    realtime_voice_enabled?: boolean; // Per-project toggle for realtime voice conversations
    ai_instruction: string; // AI role and guidelines (max 100 words)
    ai_knowledge_base: string; // Background knowledge for AI (max 2000 words)
    ai_welcome_general?: string; // Custom welcome message for General AI Assistant
    ai_welcome_item?: string; // Custom welcome message for Content Item AI Assistant
    qr_code_position: string;
    original_language?: string; // Original language code (e.g., 'en')
    content_mode?: ContentMode; // Content rendering mode
    is_grouped?: boolean; // Whether content is organized into categories
    group_display?: GroupDisplay; // How grouped items display
    billing_type?: 'digital'; // Billing model
    default_daily_session_limit?: number | null; // Default daily limit for new QR codes (default: 500)
    default_daily_voice_limit?: number | null; // Default daily voice call limit in seconds for new QR codes (NULL = unlimited)
    metadata?: Record<string, any>; // Extensible JSONB metadata
    id?: string; // Optional for updates
}

// Access Token form data for creating/updating
export interface AccessTokenFormData {
    name: string;
    daily_session_limit?: number | null; // NULL = unlimited
    monthly_session_limit?: number | null; // NULL = unlimited
    daily_voice_limit?: number | null; // NULL = unlimited, in seconds
    monthly_voice_limit?: number | null; // NULL = unlimited, in seconds
    is_enabled?: boolean;
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
                
                const { error: uploadError } = await supabase.storage
                    .from(USER_FILES_BUCKET)
                    .upload(originalFilePath, cardData.imageFile);
                    
                if (uploadError) throw uploadError;

                const { data: { publicUrl } } = supabase.storage
                    .from(USER_FILES_BUCKET)
                    .getPublicUrl(originalFilePath);
                    
                if (publicUrl) {
                    originalImageUrl = publicUrl;
                }
            }
            
            // Upload cropped image if provided
            if (cardData.croppedImageFile) {
                const fileExt = cardData.croppedImageFile.name.split('.').pop();
                const croppedFileName = `${uuidv4()}_cropped.${fileExt}`;
                const croppedFilePath = `${user.id}/card-images/${croppedFileName}`;
                
                const { error: uploadError } = await supabase.storage
                    .from(USER_FILES_BUCKET)
                    .upload(croppedFilePath, cardData.croppedImageFile);
                    
                if (uploadError) throw uploadError;

                const { data: { publicUrl } } = supabase.storage
                    .from(USER_FILES_BUCKET)
                    .getPublicUrl(croppedFilePath);
                    
                if (publicUrl) {
                    croppedImageUrl = publicUrl;
                }
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
                    p_realtime_voice_enabled: cardData.realtime_voice_enabled || false,
                    p_ai_instruction: cardData.ai_instruction,
                    p_ai_knowledge_base: cardData.ai_knowledge_base,
                    p_ai_welcome_general: cardData.ai_welcome_general || '',
                    p_ai_welcome_item: cardData.ai_welcome_item || '',
                    p_qr_code_position: cardData.qr_code_position,
                    p_original_language: cardData.original_language || 'en',
                    p_content_mode: cardData.content_mode || 'list',
                    p_is_grouped: cardData.is_grouped || false,
                    p_group_display: cardData.group_display || 'expanded',
                    p_billing_type: cardData.billing_type || 'digital',
                    p_default_daily_session_limit: cardData.default_daily_session_limit ?? defaultDailyLimit,
                    p_metadata: cardData.metadata || {}
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
                p_realtime_voice_enabled: updateData.realtime_voice_enabled ?? null,
                p_ai_instruction: updateData.ai_instruction,
                p_ai_knowledge_base: updateData.ai_knowledge_base,
                p_ai_welcome_general: updateData.ai_welcome_general || null,
                p_ai_welcome_item: updateData.ai_welcome_item || null,
                p_qr_code_position: updateData.qr_code_position,
                p_original_language: updateData.original_language || 'en',
                p_content_mode: updateData.content_mode || null,
                p_is_grouped: updateData.is_grouped ?? null,
                p_group_display: updateData.group_display || null,
                p_billing_type: updateData.billing_type || null,
                p_default_daily_session_limit: updateData.default_daily_session_limit || null,
                // -1 signals "no change"; null means "set to unlimited"; a positive number sets the limit
                p_default_daily_voice_limit: updateData.default_daily_voice_limit === undefined ? -1 : (updateData.default_daily_voice_limit ?? null),
                p_metadata: updateData.metadata || null
            };
            
            const { data, error: updateError } = await supabase
                .rpc('update_card', payload);
                
            if (updateError) throw updateError;
            
            // Invalidate backend caches after successful update
            // This is critical for default_daily_session_limit and theme changes to take effect immediately
            try {
                const backendUrl = import.meta.env.VITE_BACKEND_URL || 'http://localhost:8080';
                const existingCard = cards.value.find(c => c.id === cardId);
                let tokens = existingCard?.access_tokens;

                // If tokens aren't loaded yet, fetch them now so we can invalidate all cache entries
                if (!tokens || tokens.length === 0) {
                    const { data: fetchedTokens } = await supabase.rpc('get_card_access_tokens', { p_card_id: cardId });
                    tokens = fetchedTokens || [];
                }

                // Invalidate cache for all access tokens (each token has its own cache key)
                await Promise.all((tokens || []).map((token: AccessToken) =>
                    fetch(`${backendUrl}/api/mobile/card/${cardId}/invalidate-cache`, {
                        method: 'POST',
                        headers: { 'Content-Type': 'application/json' },
                        body: JSON.stringify({ accessToken: token.access_token, tokenId: token.id })
                    }).catch(() => {}) // Non-critical per token
                ));
            } catch (cacheErr) {
                // Non-critical - log but don't fail the update
                console.warn('[CardStore] Failed to invalidate cache:', cacheErr);
            }
            
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

    // ========================================================================
    // ACCESS TOKEN MANAGEMENT (Multiple QR codes per project)
    // ========================================================================

    // Fetch all access tokens for a card
    const fetchAccessTokens = async (cardId: string): Promise<AccessToken[]> => {
        try {
            const { data, error: fetchError } = await supabase
                .rpc('get_card_access_tokens', { p_card_id: cardId });
            
            if (fetchError) throw fetchError;
            
            const tokens = data as AccessToken[] || [];
            
            // Update local card state with tokens and computed stats
            const card = cards.value.find(c => c.id === cardId);
            if (card) {
                card.access_tokens = tokens;
                // Compute aggregate values from tokens
                card.total_sessions = tokens.reduce((sum, t) => sum + (t.total_sessions || 0), 0);
                card.monthly_sessions = tokens.reduce((sum, t) => sum + (t.monthly_sessions || 0), 0);
                card.daily_sessions = tokens.reduce((sum, t) => sum + (t.daily_sessions || 0), 0);
                card.active_qr_codes = tokens.filter(t => t.is_enabled).length;
                card.total_qr_codes = tokens.length;
            }
            
            return tokens;
        } catch (err: any) {
            console.error('Error fetching access tokens:', err);
            error.value = err.message || 'Failed to fetch access tokens';
            return [];
        }
    };

    // Create a new access token (QR code) for a card
    const createAccessToken = async (
        cardId: string, 
        tokenData: AccessTokenFormData
    ): Promise<AccessToken | null> => {
        isLoading.value = true;
        error.value = null;
        
        try {
            const { data, error: createError } = await supabase
                .rpc('create_access_token', {
                    p_card_id: cardId,
                    p_name: tokenData.name || 'Default',
                    p_daily_session_limit: tokenData.daily_session_limit ?? null,
                    p_monthly_session_limit: tokenData.monthly_session_limit ?? null,
                    p_daily_voice_limit: tokenData.daily_voice_limit ?? null,
                    p_monthly_voice_limit: tokenData.monthly_voice_limit ?? null
                });

            if (createError) throw createError;

            if (data?.success) {
                // Refresh tokens list
                await fetchAccessTokens(cardId);

                // Return the new token info
                return {
                    id: data.token_id,
                    card_id: cardId,
                    name: data.name,
                    access_token: data.access_token,
                    is_enabled: true,
                    daily_session_limit: tokenData.daily_session_limit ?? null,
                    monthly_session_limit: tokenData.monthly_session_limit ?? null,
                    daily_voice_limit: tokenData.daily_voice_limit ?? null,
                    monthly_voice_limit: tokenData.monthly_voice_limit ?? null,
                    total_sessions: 0,
                    daily_sessions: 0,
                    monthly_sessions: 0,
                    last_session_date: null,
                    current_month: null,
                    created_at: new Date().toISOString(),
                    updated_at: new Date().toISOString()
                };
            }
            
            return null;
        } catch (err: any) {
            console.error('Error creating access token:', err);
            error.value = err.message || 'Failed to create access token';
            return null;
        } finally {
            isLoading.value = false;
        }
    };

    // Update an access token's settings
    const updateAccessToken = async (
        tokenId: string,
        cardId: string,
        updates: Partial<AccessTokenFormData>
    ): Promise<boolean> => {
        isLoading.value = true;
        error.value = null;
        
        try {
            const { data, error: updateError } = await supabase
                .rpc('update_access_token', {
                    p_token_id: tokenId,
                    p_name: updates.name ?? null,
                    p_is_enabled: updates.is_enabled ?? null,
                    p_daily_session_limit: updates.daily_session_limit === undefined
                        ? null
                        : (updates.daily_session_limit === null ? -1 : updates.daily_session_limit),
                    p_monthly_session_limit: updates.monthly_session_limit === undefined
                        ? null
                        : (updates.monthly_session_limit === null ? -1 : updates.monthly_session_limit),
                    p_daily_voice_limit: updates.daily_voice_limit === undefined
                        ? null
                        : (updates.daily_voice_limit === null ? -1 : updates.daily_voice_limit),
                    p_monthly_voice_limit: updates.monthly_voice_limit === undefined
                        ? null
                        : (updates.monthly_voice_limit === null ? -1 : updates.monthly_voice_limit)
                });
            
            if (updateError) throw updateError;
            
            if (data?.success) {
                // Refresh tokens list
                await fetchAccessTokens(cardId);
                return true;
            }
            
            return false;
        } catch (err: any) {
            console.error('Error updating access token:', err);
            error.value = err.message || 'Failed to update access token';
            return false;
        } finally {
            isLoading.value = false;
        }
    };

    // Delete an access token
    const deleteAccessToken = async (tokenId: string, cardId: string): Promise<boolean> => {
        isLoading.value = true;
        error.value = null;
        
        try {
            const { data, error: deleteError } = await supabase
                .rpc('delete_access_token', { p_token_id: tokenId });
            
            if (deleteError) throw deleteError;
            
            if (data?.success) {
                // Refresh tokens list
                await fetchAccessTokens(cardId);
                return true;
            }
            
            return false;
        } catch (err: any) {
            console.error('Error deleting access token:', err);
            error.value = err.message || 'Failed to delete access token';
            return false;
        } finally {
            isLoading.value = false;
        }
    };

    // Refresh (regenerate) a specific access token
    const refreshAccessToken = async (tokenId: string, cardId: string): Promise<string | null> => {
        isLoading.value = true;
        error.value = null;
        
        try {
            const { data, error: refreshError } = await supabase
                .rpc('refresh_access_token', { p_token_id: tokenId });
            
            if (refreshError) throw refreshError;
            
            if (data?.success) {
                // Refresh tokens list
                await fetchAccessTokens(cardId);
                return data.access_token;
            }
            
            return null;
        } catch (err: any) {
            console.error('Error refreshing access token:', err);
            error.value = err.message || 'Failed to refresh access token';
            return null;
        } finally {
            isLoading.value = false;
        }
    };

    // Toggle a specific access token's enabled state
    const toggleAccessToken = async (
        tokenId: string, 
        cardId: string, 
        isEnabled: boolean
    ): Promise<boolean> => {
        return updateAccessToken(tokenId, cardId, { is_enabled: isEnabled });
    };

    // Get monthly stats for a card (aggregated across all tokens)
    const getCardMonthlyStats = async (cardId: string): Promise<{
        monthStart: string;
        monthEnd: string;
        totalMonthlySessions: number;
        totalDailySessions: number;
        totalAllTimeSessions: number;
        activeQrCodes: number;
        totalQrCodes: number;
    } | null> => {
        try {
            const { data, error: statsError } = await supabase
                .rpc('get_card_monthly_stats', { p_card_id: cardId });
            
            if (statsError) throw statsError;
            
            return {
                monthStart: data.month_start,
                monthEnd: data.month_end,
                totalMonthlySessions: data.total_monthly_sessions,
                totalDailySessions: data.total_daily_sessions,
                totalAllTimeSessions: data.total_all_time_sessions,
                activeQrCodes: data.active_qr_codes,
                totalQrCodes: data.total_qr_codes
            };
        } catch (err: any) {
            console.error('Error getting monthly stats:', err);
            error.value = err.message || 'Failed to get monthly stats';
            return null;
        }
    };

    // Duplication progress tracking
    const isDuplicating = ref(false);
    const duplicateProgress = ref(0); // 0-100

    /**
     * Duplicate a card with all its content items.
     * Uses get_card_with_content to fetch original, then creates a new card
     * and uses bulk_create_content_items to clone content.
     */
    const duplicateCard = async (cardId: string, newName: string): Promise<string | null> => {
        isDuplicating.value = true;
        duplicateProgress.value = 0;
        error.value = null;

        try {
            // Step 1: Fetch original card with all content (20%)
            duplicateProgress.value = 10;
            const { data: cardData, error: fetchError } = await supabase
                .rpc('get_card_with_content', { p_card_id: cardId });

            if (fetchError) throw fetchError;
            if (!cardData || cardData.length === 0) throw new Error('Card not found');

            const original = cardData[0];
            duplicateProgress.value = 30;

            // Step 2: Create new card with cloned metadata (50%)
            const { data: newCardId, error: createError } = await supabase
                .rpc('create_card', {
                    p_name: newName,
                    p_description: original.card_description || '',
                    p_image_url: original.card_image_url,
                    p_original_image_url: original.card_original_image_url,
                    p_crop_parameters: original.card_crop_parameters || null,
                    p_conversation_ai_enabled: original.card_conversation_ai_enabled,
                    p_realtime_voice_enabled: original.card_realtime_voice_enabled || false,
                    p_ai_instruction: original.card_ai_instruction || '',
                    p_ai_knowledge_base: original.card_ai_knowledge_base || '',
                    p_ai_welcome_general: original.card_ai_welcome_general || '',
                    p_ai_welcome_item: original.card_ai_welcome_item || '',
                    p_qr_code_position: original.card_qr_code_position || 'bottom-right',
                    p_original_language: original.card_original_language || 'en',
                    p_content_mode: original.card_content_mode || 'list',
                    p_is_grouped: original.card_is_grouped || false,
                    p_group_display: original.card_group_display || 'expanded',
                    p_billing_type: original.card_billing_type || 'digital',
                    p_default_daily_session_limit: original.card_default_daily_session_limit || null,
                    p_metadata: original.card_metadata || {}
                });

            if (createError) throw createError;
            if (!newCardId) throw new Error('Failed to create duplicate card');

            duplicateProgress.value = 60;

            // Step 3: Clone content items if any (90%)
            const contentItems = original.content_items;
            if (contentItems && Array.isArray(contentItems) && contentItems.length > 0) {
                // Build a mapping of old parent IDs to new ones for hierarchical content
                // First, create parent items (items with no parent_id)
                const parentItems = contentItems.filter((item: any) => !item.parent_id);
                const childItems = contentItems.filter((item: any) => item.parent_id);

                if (parentItems.length > 0) {
                    // Create parents first
                    const parentPayload = parentItems.map((item: any) => ({
                        name: item.name || '',
                        content: item.content || '',
                        parent_id: null,
                        image_url: item.image_url || null,
                        ai_knowledge_base: item.ai_knowledge_base || '',
                        sort_order: item.sort_order || 0
                    }));

                    const { data: parentResult, error: parentError } = await supabase
                        .rpc('bulk_create_content_items', {
                            p_card_id: newCardId,
                            p_items: parentPayload
                        });

                    if (parentError) throw parentError;

                    duplicateProgress.value = 75;

                    // Map old parent IDs to new parent IDs
                    if (childItems.length > 0 && parentResult?.items) {
                        const parentIdMap: Record<string, string> = {};
                        parentItems.forEach((oldParent: any, index: number) => {
                            if (parentResult.items[index]) {
                                parentIdMap[oldParent.id] = parentResult.items[index].id;
                            }
                        });

                        // Create children with mapped parent IDs
                        const childPayload = childItems.map((item: any) => ({
                            name: item.name || '',
                            content: item.content || '',
                            parent_id: parentIdMap[item.parent_id] || null,
                            image_url: item.image_url || null,
                            ai_knowledge_base: item.ai_knowledge_base || '',
                            sort_order: item.sort_order || 0
                        }));

                        const { error: childError } = await supabase
                            .rpc('bulk_create_content_items', {
                                p_card_id: newCardId,
                                p_items: childPayload
                            });

                        if (childError) throw childError;
                    }
                } else {
                    // All items are top-level (no hierarchy)
                    const itemPayload = contentItems.map((item: any) => ({
                        name: item.name || '',
                        content: item.content || '',
                        parent_id: null,
                        image_url: item.image_url || null,
                        ai_knowledge_base: item.ai_knowledge_base || '',
                        sort_order: item.sort_order || 0
                    }));

                    const { error: bulkError } = await supabase
                        .rpc('bulk_create_content_items', {
                            p_card_id: newCardId,
                            p_items: itemPayload
                        });

                    if (bulkError) throw bulkError;
                }
            }

            duplicateProgress.value = 95;

            // Step 4: Refresh cards list (100%)
            await fetchCards();
            duplicateProgress.value = 100;

            return newCardId;
        } catch (err: any) {
            console.error('Error duplicating card:', err);
            error.value = err.message || 'Failed to duplicate card';
            return null;
        } finally {
            isDuplicating.value = false;
            // Reset progress after a short delay for UI
            setTimeout(() => { duplicateProgress.value = 0; }, 500);
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
        // Card duplication
        isDuplicating,
        duplicateProgress,
        duplicateCard,
        // Access token management (per-QR-code operations)
        fetchAccessTokens,
        createAccessToken,
        updateAccessToken,
        deleteAccessToken,
        refreshAccessToken,
        toggleAccessToken,
        getCardMonthlyStats
    };
});
