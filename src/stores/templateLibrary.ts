import { defineStore } from 'pinia';
import { ref, computed } from 'vue';
import { supabase } from '@/lib/supabase';
import { useAuthStore } from './auth';

// Template interfaces - templates link to actual cards records
export interface ContentTemplate {
    id: string;
    slug: string;
    card_id: string; // Links to actual card record
    name: string;
    description: string;
    venue_type: string | null;
    thumbnail_url: string | null;
    /**
     * NOTE: `cards` is a legacy value still present in some DB rows / exports.
     * UI should treat it as the modern "Inline" layout.
     */
    content_mode: 'single' | 'grouped' | 'list' | 'grid' | 'inline' | 'cards';
    is_grouped: boolean;
    group_display: 'expanded' | 'collapsed';
    billing_type: 'physical' | 'digital';
    // Default daily session limit for new QR codes
    default_daily_session_limit: number | null;
    original_language: string;
    qr_code_position: string;
    item_count: number;
    is_featured: boolean;
    created_at: string;
    // Translation info
    translation_languages: string[];
}

export interface ContentTemplateDetails extends ContentTemplate {
    conversation_ai_enabled: boolean;
    ai_instruction: string;
    ai_knowledge_base: string;
    ai_welcome_general: string;
    ai_welcome_item: string;
    content_items: ContentItemData[];
}

// Content item data from the actual content_items table
export interface ContentItemData {
    id: string;
    parent_id: string | null;
    name: string;
    content: string;
    image_url: string | null;
    original_image_url: string | null;
    ai_knowledge_base: string;
    sort_order: number;
}

export interface VenueTypeCount {
    venue_type: string;
    template_count: number;
}

export interface TemplateImportResult {
    success: boolean;
    card_id: string | null;
    message: string;
}

// Admin template with additional fields
export interface AdminContentTemplate extends ContentTemplate {
    is_active: boolean;
    sort_order: number;
    import_count: number;
    updated_at: string;
}

// Admin's card that could become a template
export interface AdminCardForTemplate {
    card_id: string;
    card_name: string;
    is_template: boolean;
    template_id: string | null;
    template_slug: string | null;
}

export const useTemplateLibraryStore = defineStore('templateLibrary', () => {
    const templates = ref<ContentTemplate[]>([]);
    const adminTemplates = ref<AdminContentTemplate[]>([]);
    const adminCards = ref<AdminCardForTemplate[]>([]);
    const venueTypes = ref<VenueTypeCount[]>([]);
    const selectedTemplate = ref<ContentTemplateDetails | null>(null);
    const isLoading = ref(false);
    const error = ref<string | null>(null);

    // Filters
    const filterVenueType = ref<string | null>(null);
    const filterContentMode = ref<string | null>(null);
    const searchQuery = ref<string>('');
    const featuredOnly = ref(false);
    const previewLanguage = ref<string | null>(null);  // Language to display templates in

    // Computed filtered templates
    const filteredTemplates = computed(() => {
        return templates.value;
    });

    // Fetch templates with optional filters
    const fetchTemplates = async (language?: string) => {
        isLoading.value = true;
        error.value = null;

        try {
            // Use provided language, or previewLanguage from store, or null for original
            const displayLanguage = language ?? previewLanguage.value;
            
            // Try with language parameter first (new stored procedure)
            let { data, error: err } = await supabase.rpc('list_content_templates', {
                p_venue_type: filterVenueType.value,
                p_content_mode: filterContentMode.value,
                p_search: searchQuery.value || null,
                p_featured_only: featuredOnly.value,
                p_language: displayLanguage || null
            });
            
            // If new signature fails (function not found with 5 params), fall back to old signature
            if (err && err.message?.includes('function')) {
                console.warn('New list_content_templates signature not available, using old signature');
                const fallbackResult = await supabase.rpc('list_content_templates', {
                    p_venue_type: filterVenueType.value,
                    p_content_mode: filterContentMode.value,
                    p_search: searchQuery.value || null,
                    p_featured_only: featuredOnly.value
                });
                data = fallbackResult.data;
                err = fallbackResult.error;
            }

            if (err) throw err;
            templates.value = data || [];
        } catch (err: any) {
            console.error('Error fetching templates:', err);
            error.value = err.message || 'Failed to fetch templates';
        } finally {
            isLoading.value = false;
        }
    };

    // Fetch single template details (includes content items)
    // language: If specified, returns content in that language (using translations if available)
    const fetchTemplateDetails = async (templateIdOrSlug: string, language?: string) => {
        isLoading.value = true;
        error.value = null;
        selectedTemplate.value = null;

        try {
            // Determine if it's a UUID or slug
            const isUuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(templateIdOrSlug);
            
            // Use provided language, or previewLanguage from store, or null for original
            const displayLanguage = language ?? previewLanguage.value;
            
            const { data, error: err } = await supabase.rpc('get_content_template', {
                p_template_id: isUuid ? templateIdOrSlug : null,
                p_slug: isUuid ? null : templateIdOrSlug,
                p_language: displayLanguage || null
            });

            if (err) throw err;
            if (data && data.length > 0) {
                selectedTemplate.value = data[0] as ContentTemplateDetails;
            }
        } catch (err: any) {
            console.error('Error fetching template details:', err);
            error.value = err.message || 'Failed to fetch template details';
        } finally {
            isLoading.value = false;
        }
    };

    // Fetch venue types for filter dropdown
    const fetchVenueTypes = async () => {
        try {
            const { data, error: err } = await supabase.rpc('get_template_venue_types');
            if (err) throw err;
            venueTypes.value = data || [];
        } catch (err: any) {
            console.error('Error fetching venue types:', err);
        }
    };

    // Import template to create a new card (copies the linked card and content items)
    // importLanguage: If specified, imports content in that language (using translations if available)
    const importTemplate = async (
        templateId: string, 
        customName?: string,
        billingType?: 'physical' | 'digital',
        importLanguage?: string  // Language code to import content in
    ): Promise<TemplateImportResult> => {
        isLoading.value = true;
        error.value = null;

        try {
            const authStore = useAuthStore();
            const userId = authStore.user?.id;

            if (!userId) {
                throw new Error('User not authenticated');
            }

            const { data, error: err } = await supabase.rpc('import_content_template', {
                p_user_id: userId,
                p_template_id: templateId,
                p_card_name: customName || null,
                p_billing_type: billingType || null,
                p_import_language: importLanguage || null
            });

            if (err) throw err;

            if (data && data.length > 0) {
                const result = data[0];
                return {
                    success: result.success,
                    card_id: result.card_id,
                    message: result.message
                };
            }

            return {
                success: false,
                card_id: null,
                message: 'No response from import function'
            };
        } catch (err: any) {
            console.error('Error importing template:', err);
            error.value = err.message || 'Failed to import template';
            return {
                success: false,
                card_id: null,
                message: err.message || 'Failed to import template'
            };
        } finally {
            isLoading.value = false;
        }
    };

    // Admin: Fetch all templates including inactive
    const adminFetchAllTemplates = async () => {
        isLoading.value = true;
        error.value = null;

        try {
            const authStore = useAuthStore();
            const userId = authStore.user?.id;

            if (!userId) {
                throw new Error('User not authenticated');
            }

            const { data, error: err } = await supabase.rpc('admin_list_all_templates', {
                p_admin_user_id: userId
            });

            if (err) throw err;
            adminTemplates.value = data || [];
        } catch (err: any) {
            console.error('Error fetching admin templates:', err);
            error.value = err.message || 'Failed to fetch templates';
        } finally {
            isLoading.value = false;
        }
    };

    // Admin: Fetch admin's cards that could be templates
    const adminFetchCards = async () => {
        try {
            const authStore = useAuthStore();
            const userId = authStore.user?.id;

            if (!userId) {
                throw new Error('User not authenticated');
            }

            const { data, error: err } = await supabase.rpc('get_admin_template_cards', {
                p_admin_user_id: userId
            });

            if (err) throw err;
            adminCards.value = data || [];
        } catch (err: any) {
            console.error('Error fetching admin cards:', err);
        }
    };

    // Admin: Create template from an existing card
    const createTemplateFromCard = async (
        cardId: string,
        slug: string,
        venueType?: string | null,
        isFeatured?: boolean,
        sortOrder?: number
    ): Promise<{ success: boolean; template_id: string | null; message: string }> => {
        try {
            const authStore = useAuthStore();
            const userId = authStore.user?.id;

            if (!userId) {
                throw new Error('User not authenticated');
            }

            const { data, error: err } = await supabase.rpc('create_template_from_card', {
                p_admin_user_id: userId,
                p_card_id: cardId,
                p_slug: slug,
                p_venue_type: venueType || null,
                p_is_featured: isFeatured || false,
                p_sort_order: sortOrder || 0
            });

            if (err) throw err;

            if (data && data.length > 0) {
                await adminFetchAllTemplates();
                return data[0];
            }

            return {
                success: false,
                template_id: null,
                message: 'No response from create function'
            };
        } catch (err: any) {
            console.error('Error creating template:', err);
            return {
                success: false,
                template_id: null,
                message: err.message || 'Failed to create template'
            };
        }
    };

    // Admin: Update template settings (not card content - use card edit for that)
    const updateTemplateSettings = async (
        templateId: string,
        settings: {
            slug?: string;
            venue_type?: string | null;
            is_featured?: boolean;
            is_active?: boolean;
            sort_order?: number;
        }
    ): Promise<{ success: boolean; message: string }> => {
        try {
            const authStore = useAuthStore();
            const userId = authStore.user?.id;

            if (!userId) {
                throw new Error('User not authenticated');
            }

            const { data, error: err } = await supabase.rpc('update_template_settings', {
                p_admin_user_id: userId,
                p_template_id: templateId,
                p_slug: settings.slug || null,
                p_venue_type: settings.venue_type,
                p_is_featured: settings.is_featured,
                p_is_active: settings.is_active,
                p_sort_order: settings.sort_order
            });

            if (err) throw err;

            if (data && data.length > 0) {
                await adminFetchAllTemplates();
                return data[0];
            }

            return { success: false, message: 'No response from update function' };
        } catch (err: any) {
            console.error('Error updating template settings:', err);
            return { success: false, message: err.message || 'Failed to update template' };
        }
    };

    // Admin: Delete template (optionally delete the linked card too)
    const deleteTemplate = async (
        templateId: string, 
        deleteCard: boolean = false
    ): Promise<{ success: boolean; message: string }> => {
        try {
            const authStore = useAuthStore();
            const userId = authStore.user?.id;

            if (!userId) {
                throw new Error('User not authenticated');
            }

            const { data, error: err } = await supabase.rpc('delete_content_template', {
                p_admin_user_id: userId,
                p_template_id: templateId,
                p_delete_card: deleteCard
            });

            if (err) throw err;

            if (data && data.length > 0) {
                await adminFetchAllTemplates();
                return data[0];
            }

            return { success: false, message: 'No response from delete function' };
        } catch (err: any) {
            console.error('Error deleting template:', err);
            return { success: false, message: err.message || 'Failed to delete template' };
        }
    };

    // Admin: Batch update template order (for drag-and-drop)
    const batchUpdateOrder = async (
        updates: Array<{ id: string; sort_order: number }>
    ): Promise<{ success: boolean; message: string; updated_count: number }> => {
        try {
            const authStore = useAuthStore();
            const userId = authStore.user?.id;

            if (!userId) {
                throw new Error('User not authenticated');
            }

            const { data, error: err } = await supabase.rpc('batch_update_template_order', {
                p_admin_user_id: userId,
                p_updates: updates
            });

            if (err) throw err;

            if (data && data.length > 0) {
                return data[0];
            }

            return { success: false, message: 'No response from batch update function', updated_count: 0 };
        } catch (err: any) {
            console.error('Error batch updating template order:', err);
            return { success: false, message: err.message || 'Failed to update order', updated_count: 0 };
        }
    };

    // Admin: Toggle template active status
    const toggleTemplateStatus = async (
        templateId: string, 
        isActive: boolean
    ): Promise<{ success: boolean; message: string }> => {
        try {
            const authStore = useAuthStore();
            const userId = authStore.user?.id;

            if (!userId) {
                throw new Error('User not authenticated');
            }

            const { data, error: err } = await supabase.rpc('toggle_template_status', {
                p_admin_user_id: userId,
                p_template_id: templateId,
                p_is_active: isActive
            });

            if (err) throw err;

            if (data && data.length > 0) {
                await adminFetchAllTemplates();
                return data[0];
            }

            return { success: false, message: 'No response from toggle function' };
        } catch (err: any) {
            console.error('Error toggling template status:', err);
            return { success: false, message: err.message || 'Failed to toggle template status' };
        }
    };

    // Clear filters
    const clearFilters = () => {
        filterVenueType.value = null;
        filterContentMode.value = null;
        searchQuery.value = '';
        featuredOnly.value = false;
        previewLanguage.value = null;
    };

    // Admin: Bulk import template from Excel card data
    // This creates a new card from the parsed data and then links it as a template
    const bulkImportTemplate = async (
        cardData: any,
        slug: string,
        venueType: string | null
    ): Promise<{ success: boolean; message: string; cardId?: string; templateId?: string }> => {
        try {
            const authStore = useAuthStore();
            const userId = authStore.user?.id;

            if (!userId) {
                throw new Error('User not authenticated');
            }

            // Parse translations from JSON string if present
            let cardTranslations = null;
            if (cardData.translations_json) {
                try {
                    cardTranslations = typeof cardData.translations_json === 'string'
                        ? JSON.parse(cardData.translations_json)
                        : cardData.translations_json;
                } catch (e) {
                    console.warn('Failed to parse card translations_json:', e);
                }
            }

            // Step 1: Create the card using existing stored procedure
            const { data: cardResult, error: cardError } = await supabase.rpc('create_card', {
                p_name: cardData.name || 'Imported Template',
                p_description: cardData.description || '',
                p_qr_code_position: cardData.qr_code_position || 'BR',
                p_image_url: cardData.image_url || null,
                p_original_image_url: cardData.original_image_url || null,
                p_crop_parameters: cardData.crop_parameters || null,
                p_conversation_ai_enabled: cardData.conversation_ai_enabled || false,
                p_ai_instruction: cardData.ai_instruction || '',
                p_ai_knowledge_base: cardData.ai_knowledge_base || '',
                p_ai_welcome_general: cardData.ai_welcome_general || '',
                p_ai_welcome_item: cardData.ai_welcome_item || '',
                p_content_mode: cardData.content_mode || 'list',
                p_is_grouped: cardData.is_grouped || false,
                p_group_display: cardData.group_display || 'expanded',
                p_billing_type: cardData.billing_type || 'digital',
                p_default_daily_session_limit: cardData.default_daily_session_limit || 500,
                p_original_language: cardData.original_language || 'en',
                p_translations: cardTranslations,
                p_content_hash: cardData.content_hash || null
            });

            if (cardError) {
                console.error('Error creating card:', cardError);
                throw new Error(cardError.message || 'Failed to create card');
            }

            const newCardId = cardResult;
            if (!newCardId) {
                throw new Error('Failed to create card - no ID returned');
            }

            // Step 2: Create content items if present
            if (cardData.contentItems && cardData.contentItems.length > 0) {
                // Excel parser returns items with 'layer' and 'parent_item' (name)
                // Layer 1 = parent/category items, Layer 2 = child items
                // Also handle direct parent_id format for backward compatibility
                
                const isLayer1 = (item: any) => {
                    if (item.layer) return item.layer === 'Layer 1';
                    return !item.parent_id && !item.parent_item;
                };
                
                const isLayer2 = (item: any) => {
                    if (item.layer) return item.layer === 'Layer 2';
                    return !!item.parent_id || !!item.parent_item;
                };
                
                let parentItems = cardData.contentItems.filter(isLayer1);
                let childItems = cardData.contentItems.filter(isLayer2);
                
                // Map item names to new IDs for parent reference
                const nameToIdMapping: Record<string, string> = {};
                const idMapping: Record<string, string> = {};

                console.log(`Initial: ${parentItems.length} parent items and ${childItems.length} child items`);
                console.log(`Card is_grouped: ${cardData.is_grouped}`);
                
                // FLAT MODE HANDLING: If card is not grouped and all items are Layer 1,
                // we need to create a default category and convert all items to Layer 2
                const isFlatMode = cardData.is_grouped === false;
                if (isFlatMode && parentItems.length > 0 && childItems.length === 0) {
                    console.log('Flat mode with only Layer 1 items - creating default category');
                    
                    // Create a default hidden category
                    const { data: defaultCategoryId, error: categoryError } = await supabase.rpc('create_content_item', {
                        p_card_id: newCardId,
                        p_parent_id: null,
                        p_name: 'Default Category',
                        p_content: '',
                        p_image_url: null,
                        p_original_image_url: null,
                        p_crop_parameters: null,
                        p_ai_knowledge_base: ''
                    });
                    
                    if (categoryError) {
                        console.error('Error creating default category:', categoryError);
                    } else if (defaultCategoryId) {
                        console.log(`Created default category: ${defaultCategoryId}`);
                        nameToIdMapping['Default Category'] = defaultCategoryId;
                        
                        // Convert all Layer 1 items to Layer 2 under the default category
                        childItems = parentItems.map(item => ({
                            ...item,
                            parent_item: 'Default Category'
                        }));
                        parentItems = []; // Clear parent items since we created the default category
                        
                        console.log(`Converted ${childItems.length} items to Layer 2 under default category`);
                    }
                }

                // Create parent items (Layer 1)
                for (const item of parentItems) {
                    // Handle Excel parser field names (crop_parameters_json, image_url)
                    const cropParams = item.crop_parameters_json || item.crop_parameters;
                    const imageUrl = item.image_url || null;
                    
                    // Parse item translations from JSON string if present
                    let itemTranslations = null;
                    if (item.translations_json) {
                        try {
                            itemTranslations = typeof item.translations_json === 'string'
                                ? JSON.parse(item.translations_json)
                                : item.translations_json;
                        } catch (e) {
                            console.warn(`Failed to parse translations for item ${item.name}:`, e);
                        }
                    }
                    
                    const { data: itemResult, error: itemError } = await supabase.rpc('create_content_item', {
                        p_card_id: newCardId,
                        p_parent_id: null,
                        p_name: item.name || 'Untitled',
                        p_content: item.content || '',
                        p_image_url: imageUrl,
                        p_original_image_url: item.original_image_url || null,
                        p_crop_parameters: cropParams && cropParams !== '' ? (typeof cropParams === 'string' ? JSON.parse(cropParams) : cropParams) : null,
                        p_ai_knowledge_base: item.ai_knowledge_base || '',
                        p_translations: itemTranslations,
                        p_content_hash: item.content_hash || null
                    });

                    if (!itemError && itemResult) {
                        // Map both by name and by id (if available)
                        nameToIdMapping[item.name] = itemResult;
                        if (item.id) {
                            idMapping[item.id] = itemResult;
                        }
                        console.log(`Created parent item: ${item.name} -> ${itemResult}`);
                    } else if (itemError) {
                        console.error(`Error creating parent item ${item.name}:`, itemError);
                    }
                }

                // Create child items (Layer 2) with mapped parent IDs
                for (const item of childItems) {
                    // Find parent ID from name mapping or direct ID
                    let parentId: string | null = null;
                    if (item.parent_item) {
                        parentId = nameToIdMapping[item.parent_item] || null;
                    } else if (item.parent_id) {
                        parentId = idMapping[item.parent_id] || nameToIdMapping[item.parent_id] || null;
                    }
                    
                    // Handle Excel parser field names (crop_parameters_json, image_url)
                    const cropParams = item.crop_parameters_json || item.crop_parameters;
                    const imageUrl = item.image_url || null;
                    
                    // Parse item translations from JSON string if present
                    let itemTranslations = null;
                    if (item.translations_json) {
                        try {
                            itemTranslations = typeof item.translations_json === 'string'
                                ? JSON.parse(item.translations_json)
                                : item.translations_json;
                        } catch (e) {
                            console.warn(`Failed to parse translations for item ${item.name}:`, e);
                        }
                    }
                    
                    const { data: itemResult, error: itemError } = await supabase.rpc('create_content_item', {
                        p_card_id: newCardId,
                        p_parent_id: parentId,
                        p_name: item.name || 'Untitled',
                        p_content: item.content || '',
                        p_image_url: imageUrl,
                        p_original_image_url: item.original_image_url || null,
                        p_crop_parameters: cropParams && cropParams !== '' ? (typeof cropParams === 'string' ? JSON.parse(cropParams) : cropParams) : null,
                        p_ai_knowledge_base: item.ai_knowledge_base || '',
                        p_translations: itemTranslations,
                        p_content_hash: item.content_hash || null
                    });

                    if (itemResult) {
                        console.log(`Created child item: ${item.name} under parent ${item.parent_item || item.parent_id}`);
                    } else if (itemError) {
                        console.error(`Error creating child item ${item.name}:`, itemError);
                    }
                }
            }

            // Step 3: Link as template
            const templateResult = await createTemplateFromCard(
                newCardId,
                slug,
                venueType,
                false, // not featured by default
                adminTemplates.value.length // add at end
            );

            if (!templateResult.success) {
                // Clean up the card if template creation failed
                await supabase.rpc('delete_card', { p_card_id: newCardId });
                throw new Error(templateResult.message || 'Failed to create template');
            }

            // Refresh templates list
            await adminFetchAllTemplates();
            await adminFetchCards();

            return { 
                success: true, 
                message: 'Template imported successfully',
                cardId: newCardId,
                templateId: templateResult.template_id || undefined
            };
        } catch (err: any) {
            console.error('Error bulk importing template:', err);
            return { success: false, message: err.message || 'Failed to import template' };
        }
    };

    return {
        // State
        templates,
        adminTemplates,
        adminCards,
        venueTypes,
        selectedTemplate,
        isLoading,
        error,
        
        // Filters
        filterVenueType,
        filterContentMode,
        searchQuery,
        featuredOnly,
        previewLanguage,
        
        // Computed
        filteredTemplates,
        
        // Actions
        fetchTemplates,
        fetchTemplateDetails,
        fetchVenueTypes,
        importTemplate,
        clearFilters,
        
        // Admin actions
        adminFetchAllTemplates,
        adminFetchCards,
        createTemplateFromCard,
        updateTemplateSettings,
        deleteTemplate,
        toggleTemplateStatus,
        batchUpdateOrder,
        bulkImportTemplate
    };
});
