import { defineStore } from 'pinia';
import { ref } from 'vue';
import { supabase } from '@/lib/supabase';

export interface PublicContentItem {
    content_item_id: string;
    content_item_parent_id: string | null;
    content_item_name: string;
    content_item_content: string;
    content_item_image_url: string | null;
    content_item_ai_knowledge_base: string;
    content_item_sort_order: number;
}

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
    const cardData = ref<PublicCardData | null>(null);
    const isLoading = ref(false);
    const error = ref<string | null>(null);

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

    return {
        cardData,
        isLoading,
        error,
        fetchPublicCard,
    };
}); 