/**
 * Mobile Client Routes
 * 
 * Handles public card access for mobile clients with:
 * - Redis caching for card content
 * - Session-based billing (Cloudflare session tracking)
 * - Upstash rate limiting
 * - Session deduplication
 * - Credit consumption for overage
 * 
 * NEW SESSION-BASED BILLING:
 * - AI-enabled projects: $0.05 per user session
 * - AI-disabled projects: $0.025 per user session
 * - Premium monthly budget: $30 (= 600 AI sessions OR 1200 non-AI sessions)
 * - Auto top-up: $5 = 100 AI sessions OR 200 non-AI sessions
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
  checkSessionAllowed,
  recordSession,
  logAccess,
  checkTokenDailyLimit,
  checkTokenMonthlyLimit,
  recordTokenDailyAccess,
  recordTokenMonthlyAccess,
  invalidateTokenDailyLimit,
  invalidateCardAiEnabled,
  updateTokenSessionCounters,
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
    conversationAiEnabled: boolean; // Primary field: enables AI voice assistant in frontend
    realtimeVoiceEnabled: boolean; // Whether realtime voice conversations are enabled
    aiEnabled: boolean; // Alias for billing (same value as conversationAiEnabled, kept for backward compatibility)
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
    // Token-specific session data
    tokenId: string;
    tokenName: string;
    totalSessions: number;
    dailySessionLimit: number | null;
    monthlySessionLimit: number | null;
    dailyVoiceLimit: number | null;
    monthlyVoiceLimit: number | null;
    dailySessions: number;
    monthlySessions: number;
    // Access status flags (billing is per-user subscription, not per-project)
    budgetExhausted: boolean;
    dailyLimitExceeded: boolean;
    monthlyLimitExceeded: boolean;
    creditsInsufficient: boolean;
    accessDisabled?: boolean;
    // Session billing info
    sessionCost: number;
    isNewSession: boolean;
    subscriptionTier?: string;
    metadata?: Record<string, any>;
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
 * Extract session ID from request
 * 
 * Priority for session identification:
 * 1. CF-Connecting-IP + User-Agent hash (device fingerprint via Cloudflare)
 * 2. X-Session-Id header (if client provides)
 * 3. Client visitorHash query param (localStorage-based)
 * 4. Generated from request fingerprint (fallback)
 * 
 * Cloudflare Setup Requirements:
 * - Route traffic through Cloudflare (DNS proxy enabled)
 * - Cloudflare automatically adds CF-Connecting-IP header
 * - For enhanced session tracking, enable "Bot Fight Mode" in Dashboard
 * 
 * Session Expiration:
 * - Sessions are deduplicated within SESSION_DEDUP_WINDOW_SECONDS (default: 30 min)
 * - Same visitor accessing same card within window = same session (no charge)
 * 
 * @see https://developers.cloudflare.com/fundamentals/reference/http-request-headers/
 */
function getSessionId(req: Request): string {
  const crypto = require('crypto');
  
  // 1. Cloudflare connecting IP + User-Agent (most reliable when behind Cloudflare)
  const cfConnectingIp = req.headers['cf-connecting-ip'] as string;
  if (cfConnectingIp) {
    const userAgent = req.headers['user-agent'] || 'unknown';
    const fingerprint = `${cfConnectingIp}:${userAgent}`.substring(0, 100);
    const hash = crypto.createHash('md5').update(fingerprint).digest('hex').substring(0, 16);
    return `cf-${hash}`;
  }
  
  // 2. Supabase Anonymous Auth session ID (from query param or header)
  // Format: anon-{first 16 chars of user UUID}
  const visitorHash = req.query.visitorHash as string;
  if (visitorHash?.startsWith('anon-')) {
    return visitorHash; // Already a valid Supabase anonymous session ID
  }
  
  // 3. X-Forwarded-For (if behind other proxies/load balancers)
  const xForwardedFor = req.headers['x-forwarded-for'] as string;
  if (xForwardedFor) {
    const clientIp = xForwardedFor.split(',')[0].trim();
    const userAgent = req.headers['user-agent'] || 'unknown';
    const fingerprint = `${clientIp}:${userAgent}`.substring(0, 100);
    const hash = crypto.createHash('md5').update(fingerprint).digest('hex').substring(0, 16);
    return `xff-${hash}`;
  }
  
  // Custom session header from client
  const customSessionId = req.headers['x-session-id'] as string;
  if (customSessionId) return customSessionId;
  
  // Generate from visitor fingerprint
  return generateVisitorHash(req);
}

/**
 * Generate a visitor hash from request headers
 * Used for session deduplication when no session ID is provided
 */
function generateVisitorHash(req: Request): string {
  const ip = req.ip || req.socket.remoteAddress || '';
  const userAgent = req.headers['user-agent'] || '';
  const acceptLanguage = req.headers['accept-language'] || '';
  
  const combined = `${ip}:${userAgent}:${acceptLanguage}`;
  let hash = 0;
  for (let i = 0; i < combined.length; i++) {
    const char = combined.charCodeAt(i);
    hash = ((hash << 5) - hash) + char;
    hash = hash & hash;
  }
  return `visitor-${Math.abs(hash).toString(36)}`;
}

/**
 * GET /api/mobile/card/digital/:accessToken
 * 
 * Get digital card content by access token.
 * Uses Redis caching with session-based billing.
 */
router.get('/card/digital/:accessToken', async (req: Request, res: Response) => {
  try {
    const { accessToken } = req.params;
    const language = (req.query.language as string) || 'en';
    const sessionId = getSessionId(req);
    
    if (!accessToken) {
      return res.status(400).json({ error: 'Access token is required' });
    }
    
    const supabase = supabaseAdmin;
    
    // Step 1: Try to get card metadata from cache or DB
    const cacheKey = CacheKeys.cardContent(accessToken, language);
    let cachedContent = await cacheGet<CardContentResponse>(cacheKey);
    
    // Step 2: Check deduplication - is this the same session?
    const dedupKey = CacheKeys.scanDedup(accessToken, sessionId);
    const isExistingSession = !(await cacheSetNX(dedupKey, '1', CacheTTL.scanDedup));
    
    // Step 3: If cache hit AND existing session, return cached content immediately
    if (cachedContent && isExistingSession) {
      console.log(`[Mobile] Cache HIT + existing session for ${accessToken}`);
      return res.json({
        success: true,
        data: {
          ...cachedContent,
          card: {
            ...cachedContent.card,
            isNewSession: false,
          }
        },
        cached: true,
        deduplicated: true,
      });
    }
    
    // Step 4: Fetch card basic info via stored procedure
    const startTime = Date.now();
    const { data: cardRows, error: cardError } = await supabase.rpc(
      'get_card_by_access_token_server',
      { p_access_token: accessToken }
    );
    const queryTime = Date.now() - startTime;
    
    const cardInfo = cardRows?.[0];
    
    if (cardError || !cardInfo) {
      console.error(`[Mobile] Card lookup failed for ${accessToken} (${queryTime}ms):`, {
        error: cardError,
        hasData: !!cardRows,
        rowCount: cardRows?.length || 0,
        firstRow: cardInfo
      });
      return res.status(404).json({ 
        error: 'Card not found',
        message: 'Invalid or expired access token'
      });
    }
    
    console.log(`[Mobile] Card found for ${accessToken}: ${cardInfo.id}, token: ${cardInfo.token_id} (${queryTime}ms, template: ${cardInfo.is_template})`);

    // Step 5: Check if this specific QR code (token) is enabled
    if (!cardInfo.token_is_enabled) {
      return res.status(403).json({
        error: 'Access disabled',
        message: 'This QR code is currently disabled',
        accessDisabled: true,
      });
    }
    
    // Step 6: Handle session-based access tracking
    let sessionResult = { 
      allowed: true, 
      isNewSession: !isExistingSession,
      sessionCost: 0,
      tier: 'free' as 'free' | 'starter' | 'premium',
      isAiEnabled: false,
      budgetRemaining: 0,
      needsOverage: false,
      reason: null as string | null,
    };
    let budgetExhausted = false;
    let dailyLimitExceeded = false;
    let monthlyLimitExceeded = false;
    let creditsInsufficient = false;
    
    // Skip usage tracking for template demo cards
    const isTemplateCard = cardInfo.is_template === true;
    
    if (isTemplateCard) {
      console.log(`[Mobile] Template demo access for ${accessToken} - skipping usage tracking`);
      sessionResult.reason = 'Template demo access (no billing)';
    }
    
    if (!isExistingSession && !isTemplateCard) {
      // Step 6a: Check DAILY limit first (per-token protection)
      const dailyCheck = await checkTokenDailyLimit(
        cardInfo.token_id,
        cardInfo.token_daily_session_limit
      );

      if (!dailyCheck.allowed) {
        dailyLimitExceeded = true;
        sessionResult.allowed = false;
        sessionResult.reason = dailyCheck.reason;
        console.log(`[Mobile] Access denied (daily limit) for token ${cardInfo.token_id}: ${dailyCheck.currentSessions}/${dailyCheck.dailyLimit}`);
      }

      // Step 6b: Check MONTHLY limit (per-token protection)
      if (!dailyLimitExceeded) {
        const monthlyCheck = await checkTokenMonthlyLimit(
          cardInfo.token_id,
          cardInfo.token_monthly_session_limit
        );

        if (!monthlyCheck.allowed) {
          monthlyLimitExceeded = true;
          sessionResult.allowed = false;
          sessionResult.reason = monthlyCheck.reason;
          console.log(`[Mobile] Access denied (monthly limit) for token ${cardInfo.token_id}: ${monthlyCheck.currentSessions}/${monthlyCheck.dailyLimit}`);
        }
      }

      if (!dailyLimitExceeded && !monthlyLimitExceeded) {
        // Step 6c: Check session allowance and handle billing
        const sessionCheck = await checkSessionAllowed(
          cardInfo.user_id,
          cardInfo.id,
          sessionId,
          false // not owner access
        );
        
        sessionResult = {
          ...sessionCheck,
          reason: sessionCheck.reason
        };
        
        if (sessionCheck.allowed) {
          // Record the session (handles billing)
          const recordResult = await recordSession(
            cardInfo.user_id,
            cardInfo.id,
            sessionId,
            sessionCheck
          );
          
          if (recordResult.allowed) {
            // Record token-level daily and monthly access after successful session
            await recordTokenDailyAccess(cardInfo.token_id);
            await recordTokenMonthlyAccess(cardInfo.token_id);
            
            // Update DB counters for display (async, non-blocking)
            updateTokenSessionCounters(cardInfo.token_id)
              .catch(err => console.error('[Mobile] Failed to update token counters:', err));
            
            console.log(`[Mobile] Session recorded for token ${cardInfo.token_id}: ${sessionCheck.reason}`);
          } else {
            sessionResult.allowed = false;
            sessionResult.reason = recordResult.reason;
            creditsInsufficient = true;
            console.log(`[Mobile] Session recording failed for ${accessToken}: ${recordResult.reason}`);
          }
        } else if (sessionCheck.needsOverage) {
          // Budget exhausted and no credits
          budgetExhausted = true;
          creditsInsufficient = true;
          console.log(`[Mobile] Access denied (budget/credits) for ${accessToken}: ${sessionCheck.reason}`);
        } else {
          // Other denial reason (e.g., free tier limit)
          budgetExhausted = true;
          console.log(`[Mobile] Access denied (limit) for ${accessToken}: ${sessionCheck.reason}`);
        }
        
        // Log access (async, non-blocking) with session-based billing info
        logAccess(
          cardInfo.id,
          sessionId,
          cardInfo.user_id,
          sessionCheck.tier,
          false, // not owner access
          sessionCheck.needsOverage && sessionResult.allowed,
          sessionResult.allowed && sessionCheck.needsOverage,
          sessionId, // session ID
          sessionCheck.sessionCost, // session cost
          sessionCheck.isAiEnabled // AI enabled status
        ).catch(err => console.error('[Mobile] Failed to log access:', err));
      }
    }
    
    // Step 7: Fetch full card content (from cache or DB)
    let content: CardContentResponse;
    
    if (cachedContent) {
      content = cachedContent;
      // Update status fields with token-specific data
      content.card.budgetExhausted = budgetExhausted;
      content.card.dailyLimitExceeded = dailyLimitExceeded;
      content.card.monthlyLimitExceeded = monthlyLimitExceeded;
      content.card.creditsInsufficient = creditsInsufficient;
      content.card.tokenId = cardInfo.token_id;
      content.card.tokenName = cardInfo.token_name;
      content.card.totalSessions = cardInfo.token_total_sessions;
      content.card.dailySessions = cardInfo.token_daily_sessions;
      content.card.monthlySessions = cardInfo.token_monthly_sessions;
      content.card.dailySessionLimit = cardInfo.token_daily_session_limit;
      content.card.monthlySessionLimit = cardInfo.token_monthly_session_limit;
      content.card.dailyVoiceLimit = cardInfo.token_daily_voice_limit ?? null;
      content.card.monthlyVoiceLimit = cardInfo.token_monthly_voice_limit ?? null;
      content.card.sessionCost = sessionResult.sessionCost;
      content.card.isNewSession = sessionResult.isNewSession;
      content.card.aiEnabled = sessionResult.isAiEnabled;
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
      const hasTranslation = Object.keys(translations).length > 0;
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
          realtimeVoiceEnabled: cardData.realtime_voice_enabled ?? false,
          aiEnabled: cardData.conversation_ai_enabled ?? false,
          aiInstruction: langData.ai_instruction || cardData.ai_instruction,
          aiKnowledgeBase: langData.ai_knowledge_base || cardData.ai_knowledge_base,
          aiWelcomeGeneral: langData.ai_welcome_general || cardData.ai_welcome_general,
          aiWelcomeItem: langData.ai_welcome_item || cardData.ai_welcome_item,
          originalLanguage: cardData.original_language,
          hasTranslation,
          availableLanguages,
          contentMode: cardData.content_mode || 'list',
          isGrouped: cardData.is_grouped || false,
          groupDisplay: cardData.group_display || 'expanded',
          billingType: cardData.billing_type || 'digital',
          // Token-specific session data
          tokenId: cardInfo.token_id,
          tokenName: cardInfo.token_name,
          totalSessions: cardInfo.token_total_sessions || 0,
          dailySessionLimit: cardInfo.token_daily_session_limit,
          monthlySessionLimit: cardInfo.token_monthly_session_limit,
          dailyVoiceLimit: cardInfo.token_daily_voice_limit ?? null,
          monthlyVoiceLimit: cardInfo.token_monthly_voice_limit ?? null,
          dailySessions: cardInfo.token_daily_sessions ?? 0,
          monthlySessions: cardInfo.token_monthly_sessions ?? 0,
          budgetExhausted,
          dailyLimitExceeded,
          monthlyLimitExceeded,
          creditsInsufficient,
          sessionCost: sessionResult.sessionCost,
          isNewSession: sessionResult.isNewSession,
          subscriptionTier: cardData.subscription_tier,
          metadata: cardData.metadata || {},
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
          budgetExhausted: false,
          dailyLimitExceeded: false,
          monthlyLimitExceeded: false,
          creditsInsufficient: false,
          sessionCost: 0,
          isNewSession: false,
          // Token stats will be updated from cardInfo on each request
          totalSessions: 0,
          dailySessions: 0,
          monthlySessions: 0,
        },
      };
      await cacheSet(cacheKey, contentToCache, CacheTTL.cardContent);
    }
    
    return res.json({
      success: true,
      data: content,
      cached: !!cachedContent,
      deduplicated: isExistingSession,
      session: {
        isNew: sessionResult.isNewSession,
        cost: sessionResult.sessionCost,
        tier: sessionResult.tier,
        isAiEnabled: sessionResult.isAiEnabled,
      }
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
 * POST /api/mobile/card/:cardId/invalidate-cache
 * 
 * Invalidate card content cache, daily limit cache, and AI-enabled cache.
 */
router.post('/card/:cardId/invalidate-cache', async (req: Request, res: Response) => {
  try {
    const { cardId } = req.params;
    const { accessToken, tokenId } = req.body;
    
    const { cacheDeletePattern } = await import('../config/redis');
    
    let deletedCount = 0;
    
    if (accessToken) {
      deletedCount += await cacheDeletePattern(`card:content:${accessToken}:*`);
    }
    
    if (tokenId) {
      // Invalidate token-specific daily limit cache
      await invalidateTokenDailyLimit(tokenId);
      console.log(`[Mobile] Invalidated caches for token ${tokenId.slice(0, 8)}...`);
    }
    
    if (cardId) {
      // Invalidate AI-enabled cache (for billing rate changes)
      await invalidateCardAiEnabled(cardId);
      console.log(`[Mobile] Invalidated AI cache for card ${cardId.slice(0, 8)}...`);
    }
    
    return res.json({
      success: true,
      message: `Invalidated ${deletedCount} content cache entries and settings caches`,
    });
    
  } catch (error) {
    console.error('[Mobile] Cache invalidation error:', error);
    return res.status(500).json({ error: 'Failed to invalidate cache' });
  }
});

export default router;
