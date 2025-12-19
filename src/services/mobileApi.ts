/**
 * Mobile API Service
 * 
 * Handles communication with the Express backend for mobile card access.
 * Provides caching and rate limiting benefits.
 */

// Get backend URL from environment
const BACKEND_URL = import.meta.env.VITE_BACKEND_URL || 'http://localhost:8080';

/**
 * Card content response from the API
 */
export interface MobileCardResponse {
  success: boolean;
  data?: {
    card: {
      name: string;
      description: string;
      imageUrl: string | null;
      cropParameters: any;
      conversationAiEnabled: boolean;
      aiInstruction: string | null;
      aiKnowledgeBase: string | null;
      aiWelcomeGeneral: string | null;
      aiWelcomeItem: string | null;
      originalLanguage: string;
      hasTranslation: boolean;
      availableLanguages: string[];
      contentMode: string;
      isGrouped: boolean;
      groupDisplay: string;
      billingType: string;
      maxScans: number | null;
      currentScans: number;
      dailyScanLimit: number | null;
      dailyScans: number;
      scanLimitReached: boolean;
      dailyLimitExceeded: boolean;
      creditsInsufficient: boolean;
      accessDisabled?: boolean;
    };
    contentItems: Array<{
      id: string;
      parentId: string | null;
      name: string;
      content: string | null;
      imageUrl: string | null;
      aiKnowledgeBase: string | null;
      sortOrder: number;
      cropParameters: any;
    }>;
    isActivated?: boolean;
    isPreview?: boolean;
  };
  cached?: boolean;
  deduplicated?: boolean;
  error?: string;
  message?: string;
  accessDisabled?: boolean;
}

/**
 * Get or create a visitor hash for scan deduplication
 */
export function getVisitorHash(): string {
  const storageKey = 'visitor_hash';
  let hash = localStorage.getItem(storageKey);
  
  if (!hash) {
    // Generate a random hash
    hash = 'vh_' + Math.random().toString(36).substring(2, 15) + 
           Math.random().toString(36).substring(2, 15);
    localStorage.setItem(storageKey, hash);
  }
  
  return hash;
}

/**
 * Fetch digital card content by access token
 * Uses Express backend with Redis caching
 */
export async function fetchDigitalCardContent(
  accessToken: string,
  language: string = 'en'
): Promise<MobileCardResponse> {
  try {
    const visitorHash = getVisitorHash();
    const url = `${BACKEND_URL}/api/mobile/card/digital/${encodeURIComponent(accessToken)}?language=${encodeURIComponent(language)}&visitorHash=${encodeURIComponent(visitorHash)}`;
    
    const response = await fetch(url, {
      method: 'GET',
      headers: {
        'Content-Type': 'application/json',
      },
    });
    
    if (!response.ok) {
      const errorData = await response.json().catch(() => ({}));
      
      // Handle specific error cases
      if (response.status === 404) {
        return {
          success: false,
          error: 'Card not found',
          message: errorData.message || 'Invalid or expired access token',
        };
      }
      
      if (response.status === 403) {
        return {
          success: false,
          error: 'Access disabled',
          message: errorData.message || 'This card is currently unavailable',
          accessDisabled: true,
        };
      }
      
      if (response.status === 429) {
        return {
          success: false,
          error: 'Rate limit exceeded',
          message: errorData.message || 'Too many requests. Please try again later.',
        };
      }
      
      return {
        success: false,
        error: errorData.error || 'Failed to fetch card',
        message: errorData.message || 'An error occurred',
      };
    }
    
    const data = await response.json();
    return data;
    
  } catch (error: any) {
    console.error('[MobileAPI] Digital card fetch error:', error);
    return {
      success: false,
      error: 'Network error',
      message: error.message || 'Failed to connect to server',
    };
  }
}

/**
 * Fetch physical card content by issue card ID
 * Uses Express backend with Redis caching
 */
export async function fetchPhysicalCardContent(
  issueCardId: string,
  language: string = 'en'
): Promise<MobileCardResponse> {
  try {
    const url = `${BACKEND_URL}/api/mobile/card/physical/${encodeURIComponent(issueCardId)}?language=${encodeURIComponent(language)}`;
    
    const response = await fetch(url, {
      method: 'GET',
      headers: {
        'Content-Type': 'application/json',
      },
    });
    
    if (!response.ok) {
      const errorData = await response.json().catch(() => ({}));
      
      if (response.status === 404) {
        return {
          success: false,
          error: 'Card not found',
          message: errorData.message || 'Invalid issue card ID',
        };
      }
      
      if (response.status === 429) {
        return {
          success: false,
          error: 'Rate limit exceeded',
          message: errorData.message || 'Too many requests. Please try again later.',
        };
      }
      
      return {
        success: false,
        error: errorData.error || 'Failed to fetch card',
        message: errorData.message || 'An error occurred',
      };
    }
    
    const data = await response.json();
    return data;
    
  } catch (error: any) {
    console.error('[MobileAPI] Physical card fetch error:', error);
    return {
      success: false,
      error: 'Network error',
      message: error.message || 'Failed to connect to server',
    };
  }
}

/**
 * Check if a string is a valid UUID
 */
export function isValidUUID(str: string): boolean {
  const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
  return uuidRegex.test(str);
}

/**
 * Determine card type from ID/token and fetch content accordingly
 */
export async function fetchCardContent(
  cardIdOrToken: string,
  language: string = 'en'
): Promise<MobileCardResponse> {
  // If it's a UUID, try physical card first
  if (isValidUUID(cardIdOrToken)) {
    const physicalResult = await fetchPhysicalCardContent(cardIdOrToken, language);
    if (physicalResult.success) {
      return physicalResult;
    }
  }
  
  // Otherwise, try as digital access token
  return fetchDigitalCardContent(cardIdOrToken, language);
}

/**
 * Transform API response to the format expected by PublicCardView
 */
export function transformCardResponse(response: MobileCardResponse): any {
  if (!response.success || !response.data) {
    return null;
  }
  
  const { card, contentItems } = response.data;
  
  // Transform to match the existing Supabase RPC response format
  return {
    cardData: {
      card_name: card.name,
      card_description: card.description,
      card_image_url: card.imageUrl,
      card_crop_parameters: card.cropParameters,
      card_conversation_ai_enabled: card.conversationAiEnabled,
      card_ai_instruction: card.aiInstruction,
      card_ai_knowledge_base: card.aiKnowledgeBase,
      card_ai_welcome_general: card.aiWelcomeGeneral,
      card_ai_welcome_item: card.aiWelcomeItem,
      card_original_language: card.originalLanguage,
      card_has_translation: card.hasTranslation,
      card_available_languages: card.availableLanguages,
      card_content_mode: card.contentMode,
      card_is_grouped: card.isGrouped,
      card_group_display: card.groupDisplay,
      card_billing_type: card.billingType,
      card_max_scans: card.maxScans,
      card_current_scans: card.currentScans,
      card_daily_scan_limit: card.dailyScanLimit,
      card_daily_scans: card.dailyScans,
      card_scan_limit_reached: card.scanLimitReached,
      card_daily_limit_exceeded: card.dailyLimitExceeded,
      card_credits_insufficient: card.creditsInsufficient,
      card_access_disabled: card.accessDisabled || false,
      is_activated: response.data.isActivated ?? true,
      is_preview: response.data.isPreview ?? false,
    },
    contentItems: contentItems.map(item => ({
      content_item_id: item.id,
      content_item_parent_id: item.parentId,
      content_item_name: item.name,
      content_item_content: item.content,
      content_item_image_url: item.imageUrl,
      content_item_ai_knowledge_base: item.aiKnowledgeBase,
      content_item_sort_order: item.sortOrder,
      crop_parameters: item.cropParameters,
    })),
  };
}

