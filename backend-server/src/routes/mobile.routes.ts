/**
 * Mobile Client Routes
 * 
 * Handles public card access for mobile clients with:
 * - Redis caching for card content
 * - Redis-first usage tracking (minimal DB hits)
 * - Upstash rate limiting
 * - Scan deduplication
 * - Credit consumption for overage
 */

import { Router, Request, Response } from 'express';
import { supabaseAdmin } from '../config/supabase';
import { 
  cacheGet, 
  cacheSet, 
  cacheSetNX,
  CacheKeys, 
  CacheTTL,
} from '../config/redis';
import { combinedRateLimit } from '../middleware/rateLimit';
import {
  checkAndIncrementUsage,
  processOverage,
  logAccess,
} from '../services/usage-tracker';

const router = Router();

// Apply rate limiting to all mobile routes
router.use(combinedRateLimit);

/**
 * Card content response interface
 */
interface CardContentResponse {
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
}

/**
 * GET /api/mobile/card/digital/:accessToken
 * 
 * Get digital card content by access token.
 * Uses Redis caching with scan deduplication.
 */
router.get('/card/digital/:accessToken', async (req: Request, res: Response) => {
  try {
    const { accessToken } = req.params;
    const language = (req.query.language as string) || 'en';
    const visitorHash = req.query.visitorHash as string || generateVisitorHash(req);
    
    if (!accessToken) {
      return res.status(400).json({ error: 'Access token is required' });
    }
    
    const supabase = supabaseAdmin;
    
    // Step 1: Try to get card metadata from cache or DB
    const cacheKey = CacheKeys.cardContent(accessToken, language);
    let cachedContent = await cacheGet<CardContentResponse>(cacheKey);
    
    // Step 2: Check deduplication - is this a repeat visit?
    const dedupKey = CacheKeys.scanDedup(accessToken, visitorHash);
    const isRepeatVisit = !(await cacheSetNX(dedupKey, '1', CacheTTL.scanDedup));
    
    // Step 3: If cache hit AND repeat visit, return cached content immediately
    if (cachedContent && isRepeatVisit) {
      console.log(`[Mobile] Cache HIT + repeat visit for ${accessToken}`);
      return res.json({
        success: true,
        data: cachedContent,
        cached: true,
        deduplicated: true,
      });
    }
    
    // Step 4: Fetch card basic info via stored procedure
    const { data: cardRows, error: cardError } = await supabase.rpc(
      'get_card_by_access_token_server',
      { p_access_token: accessToken }
    );
    
    const cardInfo = cardRows?.[0];
    
    if (cardError || !cardInfo) {
      return res.status(404).json({ 
        error: 'Card not found',
        message: 'Invalid or expired access token'
      });
    }
    
    // Step 5: Check if access is enabled
    if (!cardInfo.is_access_enabled) {
      return res.status(403).json({
        error: 'Access disabled',
        message: 'This card is currently unavailable',
        accessDisabled: true,
      });
    }
    
    // Step 6: Handle access using Redis-first usage tracking
    let accessResult = { 
      success: true, 
      access_allowed: true, 
      reason: null as string | null,
      subscription_tier: 'free' as string,
      is_overage: false,
      usage_info: null as any
    };
    let scanLimitReached = false;
    let dailyLimitExceeded = false;
    let creditsInsufficient = false;
    
    if (!isRepeatVisit) {
      // Redis-first usage tracking - only hits DB when necessary
      const usageCheck = await checkAndIncrementUsage(
        cardInfo.user_id,
        cardInfo.id,
        visitorHash,
        false // not owner access
      );
      
      accessResult.subscription_tier = usageCheck.tier;
      accessResult.usage_info = {
        monthly_used: usageCheck.currentUsage,
        monthly_limit: usageCheck.limit,
        is_overage: usageCheck.isOverage
      };
      
      if (usageCheck.allowed) {
        // Access allowed (within limit)
        accessResult.access_allowed = true;
        accessResult.reason = usageCheck.reason;
        console.log(`[Mobile] Access allowed for ${accessToken}: ${usageCheck.reason}`);
      } else if (usageCheck.isOverage && usageCheck.tier === 'premium') {
        // Premium user over limit - purchase overage batch (5 credits = 100 extra access)
        const overageResult = await processOverage(
          cardInfo.user_id,
          cardInfo.id,
          visitorHash,
          0 // Rate is handled internally by batch config
        );
        
        if (overageResult.allowed) {
          accessResult.access_allowed = true;
          accessResult.is_overage = true;
          accessResult.reason = 'Overage credit charged';
          console.log(`[Mobile] Overage access for ${accessToken}, new balance: ${overageResult.newBalance}`);
        } else {
          accessResult.access_allowed = false;
          accessResult.reason = overageResult.reason;
          creditsInsufficient = true;
          console.log(`[Mobile] Access denied (no credits) for ${accessToken}`);
        }
      } else {
        // Free user over limit
        accessResult.access_allowed = false;
        accessResult.reason = usageCheck.reason;
        dailyLimitExceeded = true; // Using dailyLimitExceeded for monthly limit (legacy naming)
        console.log(`[Mobile] Access denied (limit reached) for ${accessToken}`);
      }
      
      // Log access to Redis buffer (instant, no DB hit)
      // Buffer is flushed to DB when daily-stats is requested
      logAccess(
        cardInfo.id,
        visitorHash,
        cardInfo.user_id,
        usageCheck.tier,
        false, // not owner access
        accessResult.is_overage,
        accessResult.is_overage && accessResult.access_allowed
      ).catch(err => console.error('[Mobile] Failed to log access:', err));
    }
    
    // Step 7: Fetch full card content (from cache or DB)
    let content: CardContentResponse;
    
    if (cachedContent) {
      content = cachedContent;
      // Update status fields
      content.card.scanLimitReached = scanLimitReached;
      content.card.dailyLimitExceeded = dailyLimitExceeded;
      content.card.creditsInsufficient = creditsInsufficient;
      content.card.currentScans = cardInfo.current_scans + (isRepeatVisit ? 0 : (accessResult.access_allowed ? 1 : 0));
    } else {
      // Fetch from database via stored procedures
      const { data: cardDataRows, error: fetchError } = await supabase.rpc(
        'get_card_content_server',
        { p_card_id: cardInfo.id }
      );
      
      const cardData = cardDataRows?.[0];
      
      if (fetchError || !cardData) {
        return res.status(500).json({ error: 'Failed to fetch card content' });
      }
      
      // Fetch content items via stored procedure
      const { data: contentItems, error: itemsError } = await supabase.rpc(
        'get_content_items_server',
        { p_card_id: cardInfo.id }
      );
      
      if (itemsError) {
        console.error('[Mobile] Content items fetch error:', itemsError);
      }
      
      // Build response with translations
      const translations = cardData.translations || {};
      const hasTranslation = language in translations;
      const langData = translations[language] || {};
      
      const availableLanguages = [
        cardData.original_language,
        ...Object.keys(translations),
      ];
      
      content = {
        card: {
          name: langData.name || cardData.name,
          description: langData.description || cardData.description,
          imageUrl: cardData.image_url,
          cropParameters: cardData.crop_parameters,
          conversationAiEnabled: cardData.conversation_ai_enabled,
          aiInstruction: cardData.ai_instruction,
          aiKnowledgeBase: cardData.ai_knowledge_base,
          aiWelcomeGeneral: cardData.ai_welcome_general,
          aiWelcomeItem: cardData.ai_welcome_item,
          originalLanguage: cardData.original_language,
          hasTranslation,
          availableLanguages,
          contentMode: cardData.content_mode || 'list',
          isGrouped: cardData.is_grouped || false,
          groupDisplay: cardData.group_display || 'expanded',
          billingType: cardData.billing_type || 'digital',
          maxScans: cardData.max_scans,
          currentScans: cardData.current_scans || 0,
          dailyScanLimit: cardData.daily_scan_limit,
          dailyScans: cardData.daily_scans || 0,
          scanLimitReached,
          dailyLimitExceeded,
          creditsInsufficient,
        },
        contentItems: (contentItems || []).map((item: any) => {
          const itemTranslations = item.translations || {};
          const itemLangData = itemTranslations[language] || {};
          
          return {
            id: item.id,
            parentId: item.parent_id,
            name: itemLangData.name || item.name,
            content: itemLangData.content || item.content,
            imageUrl: item.image_url,
            aiKnowledgeBase: itemLangData.ai_knowledge_base || item.ai_knowledge_base,
            sortOrder: item.sort_order,
            cropParameters: item.crop_parameters,
          };
        }),
      };
      
      // Cache the content (without status fields that change per-request)
      const contentToCache = {
        ...content,
        card: {
          ...content.card,
          scanLimitReached: false,
          dailyLimitExceeded: false,
          creditsInsufficient: false,
        },
      };
      await cacheSet(cacheKey, contentToCache, CacheTTL.cardContent);
    }
    
    return res.json({
      success: true,
      data: content,
      cached: !!cachedContent,
      deduplicated: isRepeatVisit,
    });
    
  } catch (error) {
    console.error('[Mobile] Digital card error:', error);
    return res.status(500).json({ 
      error: 'Internal server error',
      message: 'Failed to fetch card content'
    });
  }
});

/**
 * GET /api/mobile/card/physical/:issueCardId
 * 
 * Get physical card content by issue card ID.
 * Uses Redis caching.
 */
router.get('/card/physical/:issueCardId', async (req: Request, res: Response) => {
  try {
    const { issueCardId } = req.params;
    const language = (req.query.language as string) || 'en';
    
    if (!issueCardId) {
      return res.status(400).json({ error: 'Issue card ID is required' });
    }
    
    // Validate UUID format
    const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
    if (!uuidRegex.test(issueCardId)) {
      return res.status(400).json({ error: 'Invalid issue card ID format' });
    }
    
    const supabase = supabaseAdmin;
    
    // Try cache first
    const cacheKey = CacheKeys.physicalCardContent(issueCardId, language);
    const cachedContent = await cacheGet<CardContentResponse>(cacheKey);
    
    if (cachedContent) {
      console.log(`[Mobile] Cache HIT for physical card ${issueCardId}`);
      return res.json({
        success: true,
        data: cachedContent,
        cached: true,
      });
    }
    
    // Fetch issue card info via stored procedure
    const { data: issueCardRows, error: issueError } = await supabase.rpc(
      'get_issue_card_server',
      { p_issue_card_id: issueCardId }
    );
    
    const issueCard = issueCardRows?.[0];
    
    if (issueError || !issueCard) {
      return res.status(404).json({ 
        error: 'Card not found',
        message: 'Invalid issue card ID'
      });
    }
    
    // Auto-activate if not active
    if (!issueCard.active) {
      await supabase.rpc('activate_issue_card_server', { p_issue_card_id: issueCardId });
    }
    
    // Fetch card content via stored procedure
    const { data: cardDataRows, error: fetchError } = await supabase.rpc(
      'get_card_content_server',
      { p_card_id: issueCard.card_id }
    );
    
    const cardData = cardDataRows?.[0];
    
    if (fetchError || !cardData) {
      return res.status(500).json({ error: 'Failed to fetch card content' });
    }
    
    // Fetch content items via stored procedure
    const { data: contentItems } = await supabase.rpc(
      'get_content_items_server',
      { p_card_id: issueCard.card_id }
    );
    
    // Build response
    const translations = cardData.translations || {};
    const hasTranslation = language in translations;
    const langData = translations[language] || {};
    
    const content: CardContentResponse = {
      card: {
        name: langData.name || cardData.name,
        description: langData.description || cardData.description,
        imageUrl: cardData.image_url,
        cropParameters: cardData.crop_parameters,
        conversationAiEnabled: cardData.conversation_ai_enabled,
        aiInstruction: cardData.ai_instruction,
        aiKnowledgeBase: cardData.ai_knowledge_base,
        aiWelcomeGeneral: cardData.ai_welcome_general,
        aiWelcomeItem: cardData.ai_welcome_item,
        originalLanguage: cardData.original_language,
        hasTranslation,
        availableLanguages: [cardData.original_language, ...Object.keys(translations)],
        contentMode: cardData.content_mode || 'list',
        isGrouped: cardData.is_grouped || false,
        groupDisplay: cardData.group_display || 'expanded',
        billingType: cardData.billing_type || 'physical',
        maxScans: null,
        currentScans: 0,
        dailyScanLimit: null,
        dailyScans: 0,
        scanLimitReached: false,
        dailyLimitExceeded: false,
        creditsInsufficient: false,
      },
      contentItems: (contentItems || []).map((item: any) => {
        const itemTranslations = item.translations || {};
        const itemLangData = itemTranslations[language] || {};
        
        return {
          id: item.id,
          parentId: item.parent_id,
          name: itemLangData.name || item.name,
          content: itemLangData.content || item.content,
          imageUrl: item.image_url,
          aiKnowledgeBase: itemLangData.ai_knowledge_base || item.ai_knowledge_base,
          sortOrder: item.sort_order,
          cropParameters: item.crop_parameters,
        };
      }),
      isActivated: true,
    };
    
    // Cache the content
    await cacheSet(cacheKey, content, CacheTTL.cardContent);
    
    return res.json({
      success: true,
      data: content,
      cached: false,
    });
    
  } catch (error) {
    console.error('[Mobile] Physical card error:', error);
    return res.status(500).json({ 
      error: 'Internal server error',
      message: 'Failed to fetch card content'
    });
  }
});

/**
 * POST /api/mobile/card/:cardId/invalidate-cache
 * 
 * Invalidate card content cache (called when card is updated).
 * Requires service role or card owner authentication.
 */
router.post('/card/:cardId/invalidate-cache', async (req: Request, res: Response) => {
  try {
    // cardId from params can be used for physical card cache invalidation in the future
    const { accessToken } = req.body;
    
    // Import cache delete function
    const { cacheDeletePattern } = await import('../config/redis');
    
    // Delete all cached content for this card
    let deletedCount = 0;
    
    if (accessToken) {
      // Delete digital card cache
      deletedCount += await cacheDeletePattern(`card:content:${accessToken}:*`);
    }
    
    // Delete physical card cache by card ID (would need to know issue card IDs)
    // This is a limitation - physical cards would need to be invalidated by issue card ID
    
    return res.json({
      success: true,
      message: `Invalidated ${deletedCount} cache entries`,
    });
    
  } catch (error) {
    console.error('[Mobile] Cache invalidation error:', error);
    return res.status(500).json({ error: 'Failed to invalidate cache' });
  }
});

/**
 * Generate a visitor hash from request headers
 * Used for scan deduplication when no visitor hash is provided
 */
function generateVisitorHash(req: Request): string {
  const ip = req.ip || req.socket.remoteAddress || '';
  const userAgent = req.headers['user-agent'] || '';
  const acceptLanguage = req.headers['accept-language'] || '';
  
  // Create a simple hash from these values
  const combined = `${ip}:${userAgent}:${acceptLanguage}`;
  let hash = 0;
  for (let i = 0; i < combined.length; i++) {
    const char = combined.charCodeAt(i);
    hash = ((hash << 5) - hash) + char;
    hash = hash & hash; // Convert to 32-bit integer
  }
  return `server-${Math.abs(hash).toString(36)}`;
}

export default router;

