/**
 * Redis-First Session Tracking Service
 * 
 * NEW SESSION-BASED BILLING MODEL:
 * - AI-enabled projects: $0.05 per user session
 * - AI-disabled projects: $0.025 per user session
 * - Premium monthly budget: $30 (= 600 AI sessions OR 1200 non-AI sessions)
 * - Auto top-up: $5 = 100 AI sessions OR 200 non-AI sessions
 * 
 * Redis (Upstash) is the SINGLE SOURCE OF TRUTH for session tracking.
 * Sessions are identified via Cloudflare session ID or visitor fingerprint.
 * 
 * PostgreSQL is only hit when:
 * - First session of the month (to get tier info, then cached in Redis)
 * - Overage purchase (1 DB call per $5 top-up)
 * - Session logging (async, non-blocking)
 */

import { redis, isRedisConfigured } from '../config/redis';
import { supabaseAdmin } from '../config/supabase';
import { SubscriptionConfig, getSessionCost, calculateSessionsFromBudget } from '../config/subscription';

// ============================================================================
// REDIS KEY PATTERNS
// ============================================================================

// Session tracking keys
const SESSION_DEDUP_KEY = (sessionId: string, cardId: string) => `session:dedup:${sessionId}:${cardId}`;

// User budget tracking keys (monthly)
// BUDGET_KEY stores AVAILABLE budget (source of truth), decrements on each access
const BUDGET_KEY = (userId: string, month: string) => `budget:user:${userId}:month:${month}`;
const AI_SESSIONS_KEY = (userId: string, month: string) => `sessions:ai:${userId}:month:${month}`;
const NON_AI_SESSIONS_KEY = (userId: string, month: string) => `sessions:nonai:${userId}:month:${month}`;

// User info cache keys
const TIER_KEY = (userId: string) => `user:tier:${userId}`;
const CARD_AI_ENABLED_KEY = (cardId: string) => `card:ai_enabled:${cardId}`;

// Daily limit keys (per-card creator protection)
const DAILY_SCANS_KEY = (cardId: string, date: string) => `access:card:${cardId}:date:${date}:scans`;
const DAILY_LIMIT_KEY = (cardId: string) => `access:card:${cardId}:daily_limit`;

// Cache TTLs
const CACHE_TTL = 35 * 24 * 60 * 60; // 35 days (covers month + buffer)
const DEDUP_TTL = SubscriptionConfig.session.dedupWindowSeconds; // 5 minutes default
const DAILY_CACHE_TTL = 2 * 24 * 60 * 60; // 2 days

// ============================================================================
// TYPES
// ============================================================================

interface SessionCheckResult {
  allowed: boolean;
  isNewSession: boolean;
  sessionCost: number;
  tier: 'free' | 'premium';
  isAiEnabled: boolean;
  budgetRemaining: number;
  needsOverage: boolean;
  reason: string;
}

interface SessionRecordResult {
  allowed: boolean;
  sessionId: string | null;
  creditDeducted: boolean;
  creditsCharged?: number;
  newBudget?: number;
  reason: string;
}

interface DailyLimitCheckResult {
  allowed: boolean;
  currentScans: number;
  dailyLimit: number | null;
  reason: string;
}

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

/**
 * Get current month key (YYYY-MM)
 */
function getCurrentMonth(): string {
  const now = new Date();
  return `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`;
}

/**
 * Get current date key (YYYY-MM-DD)
 */
function getCurrentDate(): string {
  const now = new Date();
  return `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-${String(now.getDate()).padStart(2, '0')}`;
}

/**
 * Get card's AI-enabled status (cached)
 */
async function getCardAiEnabled(cardId: string): Promise<boolean> {
  if (!isRedisConfigured()) {
    return getCardAiEnabledFromDb(cardId);
  }

  const cached = await redis.get(CARD_AI_ENABLED_KEY(cardId));
  if (cached !== null) {
    return cached === 'true';
  }

  const isAiEnabled = await getCardAiEnabledFromDb(cardId);
  await redis.set(CARD_AI_ENABLED_KEY(cardId), isAiEnabled.toString(), { ex: CACHE_TTL });
  return isAiEnabled;
}

/**
 * Get card's AI-enabled status from database via stored procedure
 */
async function getCardAiEnabledFromDb(cardId: string): Promise<boolean> {
  const { data, error } = await supabaseAdmin.rpc('get_card_ai_status_server', {
    p_card_id: cardId
  });

  if (error) {
    console.warn(`[SessionTracker] Failed to get ai_enabled for card ${cardId}:`, error);
    return false;
  }

  return data ?? false;
}

/**
 * Get or initialize user's subscription info in Redis
 * Redis tracks AVAILABLE budget (remaining), not consumed
 */
async function getOrInitUserInfo(userId: string): Promise<{ 
  tier: 'free' | 'premium'; 
  budgetAvailable: number;  // Available budget (source of truth in Redis)
}> {
  const month = getCurrentMonth();
  
  if (!isRedisConfigured()) {
    return getSubscriptionFromDb(userId);
  }

  const [tierResult, budgetResult] = await Promise.all([
    redis.get(TIER_KEY(userId)),
    redis.get(BUDGET_KEY(userId, month))  // Available budget
  ]);

  const tierStr = tierResult as string | null;
  const budgetStr = budgetResult as string | null;

  if (tierStr && budgetStr !== null) {
    return {
      tier: tierStr as 'free' | 'premium',
      budgetAvailable: parseFloat(budgetStr || '0')
    };
  }

  // Not in cache - fetch tier from database, initialize budget from config
  const dbInfo = await getSubscriptionFromDb(userId);
  
  // Cache the info
  await Promise.all([
    redis.set(TIER_KEY(userId), dbInfo.tier, { ex: CACHE_TTL }),
    redis.set(BUDGET_KEY(userId, month), dbInfo.budgetAvailable.toString(), { ex: CACHE_TTL })
  ]);

  return dbInfo;
}

/**
 * Get subscription tier from PostgreSQL, initialize budget from config
 * All pricing values come from environment variables
 */
async function getSubscriptionFromDb(userId: string): Promise<{
  tier: 'free' | 'premium';
  budgetAvailable: number;
}> {
  const { data: rows, error } = await supabaseAdmin.rpc(
    'get_subscription_by_user_server',
    { p_user_id: userId }
  );

  const data = rows?.[0];

  if (error || !data) {
    // No subscription - return free tier defaults
    return {
      tier: 'free',
      budgetAvailable: 0
    };
  }

  const tier = data.tier as 'free' | 'premium';
  // Initialize available budget from config (all pricing from env vars)
  const budgetAvailable = tier === 'premium' 
    ? SubscriptionConfig.premium.monthlyBudgetUsd
    : 0;

  return { 
    tier, 
    budgetAvailable
  };
}

// ============================================================================
// DAILY ACCESS LIMIT (Per-Card Creator Protection)
// ============================================================================

/**
 * Get card's daily scan limit from Redis cache or DB
 */
async function getCardDailyLimit(cardId: string): Promise<number | null> {
  if (!isRedisConfigured()) {
    return getDailyLimitFromDb(cardId);
  }

  const cachedLimit = await redis.get(DAILY_LIMIT_KEY(cardId));
  
  if (cachedLimit !== null) {
    if (cachedLimit === 'null') return null;
    return parseInt(cachedLimit as string, 10);
  }

  const dbLimit = await getDailyLimitFromDb(cardId);
  await redis.set(
    DAILY_LIMIT_KEY(cardId), 
    dbLimit === null ? 'null' : dbLimit.toString(), 
    { ex: DAILY_CACHE_TTL }
  );

  return dbLimit;
}

/**
 * Get daily limit from database via stored procedure
 */
async function getDailyLimitFromDb(cardId: string): Promise<number | null> {
  const { data, error } = await supabaseAdmin.rpc('get_card_daily_limit_server', {
    p_card_id: cardId
  });

  if (error) {
    console.warn(`[SessionTracker] Failed to get daily limit for card ${cardId}:`, error);
    return null;
  }

  return data; // NULL means unlimited
}

/**
 * Get current daily scan count from Redis
 */
async function getCurrentDailyScans(cardId: string): Promise<number> {
  if (!isRedisConfigured()) return 0;
  const date = getCurrentDate();
  const count = await redis.get(DAILY_SCANS_KEY(cardId, date));
  return count ? parseInt(count as string, 10) : 0;
}

/**
 * Check if card has reached daily scan limit
 */
export async function checkDailyLimit(cardId: string): Promise<DailyLimitCheckResult> {
  const isDebug = process.env.DEBUG_USAGE === 'true';

  if (!isRedisConfigured()) {
    return { allowed: true, currentScans: 0, dailyLimit: null, reason: 'Redis not configured' };
  }

  try {
    const dailyLimit = await getCardDailyLimit(cardId);
    if (dailyLimit === null) {
      return { allowed: true, currentScans: 0, dailyLimit: null, reason: 'No daily limit configured' };
    }

    const currentScans = await getCurrentDailyScans(cardId);
    
    if (isDebug) console.log(`[SessionTracker] Card ${cardId.slice(0, 8)}... daily: ${currentScans}/${dailyLimit}`);

    if (currentScans < dailyLimit) {
      return { allowed: true, currentScans, dailyLimit, reason: 'Within daily limit' };
    }

    console.log(`[SessionTracker] ❌ Daily limit reached for card ${cardId.slice(0, 8)}...: ${currentScans}/${dailyLimit}`);
    return {
      allowed: false,
      currentScans,
      dailyLimit,
      reason: `Daily access limit reached (${dailyLimit}/day). Please try again tomorrow.`
    };
  } catch (error) {
    console.error('[SessionTracker] Daily limit check error:', error);
    return { allowed: true, currentScans: 0, dailyLimit: null, reason: 'Error checking - allowing access' };
  }
}

/**
 * Record daily access
 */
export async function recordDailyAccess(cardId: string): Promise<number> {
  if (!isRedisConfigured()) return 0;

  const date = getCurrentDate();
  const key = DAILY_SCANS_KEY(cardId, date);
  const newCount = await redis.incr(key);
  
  if (newCount === 1) {
    await redis.expire(key, DAILY_CACHE_TTL);
  }

  return newCount;
}

/**
 * Rollback daily access if session ultimately denied
 */
export async function rollbackDailyAccess(cardId: string): Promise<void> {
  if (!isRedisConfigured()) return;
  const date = getCurrentDate();
  await redis.decr(DAILY_SCANS_KEY(cardId, date));
}

/**
 * Invalidate card's cached daily limit
 */
export async function invalidateCardDailyLimit(cardId: string): Promise<void> {
  if (!isRedisConfigured()) return;
  await redis.del(DAILY_LIMIT_KEY(cardId));
}

/**
 * Invalidate card's cached AI-enabled status
 */
export async function invalidateCardAiEnabled(cardId: string): Promise<void> {
  if (!isRedisConfigured()) return;
  await redis.del(CARD_AI_ENABLED_KEY(cardId));
}

// ============================================================================
// SESSION-BASED BILLING (Main Functions)
// ============================================================================

/**
 * Check if a new session is allowed and get billing info
 * This is a fast Redis-first check
 */
export async function checkSessionAllowed(
  userId: string,
  cardId: string,
  sessionId: string,
  isOwnerAccess: boolean = false
): Promise<SessionCheckResult> {
  const isDebug = process.env.DEBUG_USAGE === 'true';
  
  // Owner access is always free
  if (isOwnerAccess) {
    if (isDebug) console.log(`[SessionTracker] Owner access for ${cardId.slice(0, 8)}... - FREE`);
    return {
      allowed: true,
      isNewSession: false,
      sessionCost: 0,
      tier: 'free',
      isAiEnabled: false,
      budgetRemaining: 0,
      needsOverage: false,
      reason: 'Owner access (free)'
    };
  }

  if (!isRedisConfigured()) {
    console.warn('[SessionTracker] Redis not configured - falling back to DB');
    return {
      allowed: true,
      isNewSession: true,
      sessionCost: 0,
      tier: 'free',
      isAiEnabled: false,
      budgetRemaining: 0,
      needsOverage: false,
      reason: 'Redis not configured - using DB'
    };
  }

  try {
    // Check if this is a duplicate session (within dedup window)
    const dedupKey = SESSION_DEDUP_KEY(sessionId, cardId);
    const isExistingSession = await redis.get(dedupKey);
    
    if (isExistingSession) {
      if (isDebug) console.log(`[SessionTracker] Existing session for ${cardId.slice(0, 8)}...`);
      return {
        allowed: true,
        isNewSession: false,
        sessionCost: 0,
        tier: 'free',
        isAiEnabled: false,
        budgetRemaining: 0,
        needsOverage: false,
        reason: 'Existing session (no charge)'
      };
    }

    // Get card's AI-enabled status and calculate session cost (from env vars)
    const isAiEnabled = await getCardAiEnabled(cardId);
    const sessionCost = getSessionCost(isAiEnabled);
    
    // Get user's tier and available budget (Redis is source of truth)
    const { tier, budgetAvailable } = await getOrInitUserInfo(userId);
    const budgetRemaining = budgetAvailable;
    
    if (isDebug) {
      console.log(`[SessionTracker] User ${userId.slice(0, 8)}... tier=${tier} budgetAvailable=$${budgetAvailable}`);
      console.log(`[SessionTracker] Card ${cardId.slice(0, 8)}... aiEnabled=${isAiEnabled} cost=$${sessionCost}`);
    }

    // Free tier check
    if (tier === 'free') {
      const month = getCurrentMonth();
      const aiSessions = parseInt(await redis.get(AI_SESSIONS_KEY(userId, month)) as string || '0', 10);
      const nonAiSessions = parseInt(await redis.get(NON_AI_SESSIONS_KEY(userId, month)) as string || '0', 10);
      const totalSessions = aiSessions + nonAiSessions;
      
      if (totalSessions >= SubscriptionConfig.free.monthlySessionLimit) {
        console.log(`[SessionTracker] ❌ Free tier limit reached for ${userId.slice(0, 8)}...: ${totalSessions}/50`);
        return {
          allowed: false,
          isNewSession: true,
          sessionCost,
          tier,
          isAiEnabled,
          budgetRemaining: 0,
          needsOverage: false,
          reason: 'Free tier monthly session limit reached. Upgrade to Premium for more sessions.'
        };
      }
      
      return {
        allowed: true,
        isNewSession: true,
        sessionCost,
        tier,
        isAiEnabled,
        budgetRemaining: 0,
        needsOverage: false,
        reason: 'Free tier - session allowed'
      };
    }

    // Premium tier check
    if (budgetRemaining >= sessionCost) {
      if (isDebug) console.log(`[SessionTracker] ✅ Budget available: $${budgetRemaining.toFixed(2)} >= $${sessionCost}`);
      return {
        allowed: true,
        isNewSession: true,
        sessionCost,
        tier,
        isAiEnabled,
        budgetRemaining,
        needsOverage: false,
        reason: 'Within budget'
      };
    }

    // Budget exhausted - check for overage capability
    if (isDebug) console.log(`[SessionTracker] ⚠️ Budget exhausted: $${budgetRemaining.toFixed(2)} < $${sessionCost} - checking overage`);
    
    return {
      allowed: true, // Will be confirmed in processSessionOverage
      isNewSession: true,
      sessionCost,
      tier,
      isAiEnabled,
      budgetRemaining,
      needsOverage: true,
      reason: 'Budget exhausted - overage required'
    };
  } catch (error) {
    console.error('[SessionTracker] Session check error:', error);
    return {
      allowed: true,
      isNewSession: true,
      sessionCost: 0,
      tier: 'free',
      isAiEnabled: false,
      budgetRemaining: 0,
      needsOverage: false,
      reason: 'Error - allowing access'
    };
  }
}

/**
 * Record a new session and handle billing
 * Call this after checkSessionAllowed confirms the session is new and allowed
 */
export async function recordSession(
  userId: string,
  cardId: string,
  sessionId: string,
  sessionCheck: SessionCheckResult
): Promise<SessionRecordResult> {
  const isDebug = process.env.DEBUG_USAGE === 'true';
  const month = getCurrentMonth();

  if (!sessionCheck.isNewSession) {
    return { allowed: true, sessionId: null, creditDeducted: false, reason: 'Existing session' };
  }

  if (!isRedisConfigured()) {
    // Fallback to database
    const { data, error } = await supabaseAdmin.rpc('record_user_session_server', {
      p_session_id: sessionId,
      p_card_id: cardId
    });
    
    if (error || !data?.success) {
      return { allowed: false, sessionId: null, creditDeducted: false, reason: data?.reason || 'DB error' };
    }
    
    return { 
      allowed: true, 
      sessionId: data.session_id, 
      creditDeducted: data.was_overage,
      reason: data.reason 
    };
  }

  try {
    // Handle overage if needed
    if (sessionCheck.needsOverage && sessionCheck.tier === 'premium') {
      const overageResult = await processSessionOverage(userId, sessionCheck.sessionCost);
      
      if (!overageResult.allowed) {
        return {
          allowed: false,
          sessionId: null,
          creditDeducted: false,
          reason: overageResult.reason
        };
      }
    }

    // Record the session in Redis (dedup key)
    const dedupKey = SESSION_DEDUP_KEY(sessionId, cardId);
    await redis.set(dedupKey, '1', { ex: DEDUP_TTL });

    // Atomically decrement available budget using INCRBYFLOAT
    const budgetKey = BUDGET_KEY(userId, month);
    const newBudget = await redis.incrbyfloat(budgetKey, -sessionCheck.sessionCost);
    
    // Ensure budget doesn't go below 0 (race condition protection)
    if (newBudget !== null && newBudget < 0) {
      // Correct the overshoot
      await redis.incrbyfloat(budgetKey, -newBudget); // Add back the negative to make it 0
    }
    
    // Increment session counters
    if (sessionCheck.isAiEnabled) {
      await redis.incr(AI_SESSIONS_KEY(userId, month));
    } else {
      await redis.incr(NON_AI_SESSIONS_KEY(userId, month));
    }

    if (isDebug) {
      console.log(`[SessionTracker] ✅ Session recorded: card=${cardId.slice(0, 8)}... cost=$${sessionCheck.sessionCost}`);
    }

    return {
      allowed: true,
      sessionId,
      creditDeducted: sessionCheck.needsOverage,
      creditsCharged: sessionCheck.needsOverage ? SubscriptionConfig.overage.creditsPerBatch : 0,
      reason: sessionCheck.needsOverage ? 'Session recorded with overage' : 'Session recorded'
    };
  } catch (error) {
    console.error('[SessionTracker] Record session error:', error);
    return {
      allowed: false,
      sessionId: null,
      creditDeducted: false,
      reason: 'Error recording session'
    };
  }
}

/**
 * Process overage for premium users
 * Deducts credits from user wallet and adds to Redis available budget
 */
async function processSessionOverage(
  userId: string,
  _sessionCost: number // Reserved for future per-session calculations
): Promise<{ allowed: boolean; newBudget?: number; reason: string }> {
  const month = getCurrentMonth();
  const creditsNeeded = SubscriptionConfig.overage.creditsPerBatch; // From env (default $5)

  try {
    // Call stored procedure for atomic credit deduction (only deducts, doesn't touch DB budget)
    const { data, error } = await supabaseAdmin.rpc('deduct_overage_credits_server', {
      p_user_id: userId,
      p_card_id: null, // Not card-specific for session overage
      p_credits_amount: creditsNeeded,
      p_access_granted: 0 // Legacy parameter
    });

    if (error) {
      console.error('[SessionTracker] Overage deduction failed:', error);
      return { allowed: false, reason: 'Failed to process overage credits' };
    }

    if (!data?.success) {
      return {
        allowed: false,
        reason: `Insufficient credits for top-up. Need $${creditsNeeded}, have $${data?.current_balance?.toFixed(2) || '0'}`
      };
    }

    // Atomically add credits to available budget in Redis (source of truth)
    const budgetKey = BUDGET_KEY(userId, month);
    const newBudget = await redis.incrbyfloat(budgetKey, creditsNeeded);
    
    // Ensure TTL is set (in case key was new)
    await redis.expire(budgetKey, CACHE_TTL);

    console.log(`[SessionTracker] ✅ Overage processed: $${creditsNeeded} added to available budget for ${userId.slice(0, 8)}...`);

    return {
      allowed: true,
      newBudget: newBudget ?? undefined,
      reason: `Auto top-up: $${creditsNeeded} added to budget`
    };
  } catch (error) {
    console.error('[SessionTracker] Overage processing error:', error);
    return { allowed: false, reason: 'Error processing overage' };
  }
}

// ============================================================================
// LEGACY COMPATIBILITY FUNCTIONS
// ============================================================================
// These maintain backward compatibility with existing code

/**
 * @deprecated Use checkSessionAllowed and recordSession instead
 */
export async function checkAndIncrementUsage(
  userId: string,
  cardId: string,
  visitorHash: string,
  isOwnerAccess: boolean = false
): Promise<{
  allowed: boolean;
  currentUsage: number;
  limit: number;
  tier: 'free' | 'premium';
  isOverage: boolean;
  needsDbCheck: boolean;
  reason: string;
}> {
  const sessionCheck = await checkSessionAllowed(userId, cardId, visitorHash, isOwnerAccess);
  
  // Convert to legacy format using available budget
  const month = getCurrentMonth();
  const budgetKey = BUDGET_KEY(userId, month);
  const budgetAvailable = isRedisConfigured() 
    ? parseFloat(await redis.get(budgetKey) as string || '0') 
    : 0;
  
  const totalBudget = sessionCheck.tier === 'premium' 
    ? SubscriptionConfig.premium.monthlyBudgetUsd 
    : 0;
  const budgetUsed = totalBudget - budgetAvailable;
  
  return {
    allowed: sessionCheck.allowed,
    currentUsage: Math.floor(budgetUsed / sessionCheck.sessionCost), // Convert budget to session count
    limit: calculateSessionsFromBudget(
      sessionCheck.tier === 'premium' ? SubscriptionConfig.premium.monthlyBudgetUsd : 50,
      sessionCheck.isAiEnabled
    ),
    tier: sessionCheck.tier,
    isOverage: sessionCheck.needsOverage,
    needsDbCheck: false,
    reason: sessionCheck.reason
  };
}

/**
 * @deprecated Use recordSession instead
 */
export async function processOverage(
  userId: string,
  cardId: string,
  _visitorHash: string,
  _overageRate: number
): Promise<{
  allowed: boolean;
  creditDeducted: boolean;
  creditsCharged?: number;
  accessGranted?: number;
  newBalance?: number;
  newLimit?: number;
  reason: string;
}> {
  const isAiEnabled = await getCardAiEnabled(cardId);
  const sessionCost = getSessionCost(isAiEnabled);
  const result = await processSessionOverage(userId, sessionCost);
  
  return {
    allowed: result.allowed,
    creditDeducted: result.allowed,
    creditsCharged: result.allowed ? SubscriptionConfig.overage.creditsPerBatch : 0,
    accessGranted: result.allowed 
      ? (isAiEnabled 
          ? SubscriptionConfig.overage.aiEnabledSessionsPerBatch 
          : SubscriptionConfig.overage.aiDisabledSessionsPerBatch)
      : 0,
    newBalance: undefined, // Not tracked in new model
    newLimit: result.newBudget ? calculateSessionsFromBudget(result.newBudget, isAiEnabled) : undefined,
    reason: result.reason
  };
}

// ============================================================================
// ACCESS LOGGING
// ============================================================================

const ACCESS_LOG_BUFFER = 'access_log_buffer';
const ACCESS_LOG_COUNTER = 'access_log_counter';
const FLUSH_THRESHOLD = 100;

/**
 * Log access to Redis buffer (instant, no DB hit)
 * Session-based billing fields are automatically populated
 */
export async function logAccess(
  cardId: string,
  visitorHash: string,
  ownerId: string,
  tier: string,
  isOwnerAccess: boolean,
  wasOverage: boolean,
  creditCharged: boolean,
  sessionId?: string,
  sessionCostUsd?: number,
  isAiEnabled?: boolean
): Promise<void> {
  // Determine AI-enabled and cost if not provided
  const effectiveIsAiEnabled = isAiEnabled ?? await getCardAiEnabled(cardId);
  const effectiveCost = sessionCostUsd ?? (isOwnerAccess ? 0 : getSessionCost(effectiveIsAiEnabled));
  const effectiveSessionId = sessionId || visitorHash;

  if (!isRedisConfigured()) {
    await logAccessToDb(
      cardId, visitorHash, ownerId, tier, isOwnerAccess, wasOverage, creditCharged,
      effectiveSessionId, effectiveCost, effectiveIsAiEnabled
    );
    return;
  }

  try {
    const logEntry = JSON.stringify({
      card_id: cardId,
      visitor_hash: visitorHash,
      card_owner_id: ownerId,
      subscription_tier: tier,
      is_owner_access: isOwnerAccess,
      was_overage: wasOverage,
      credit_charged: creditCharged,
      session_id: effectiveSessionId,
      session_cost_usd: effectiveCost,
      is_ai_enabled: effectiveIsAiEnabled,
      accessed_at: new Date().toISOString()
    });
    
    await redis.lpush(ACCESS_LOG_BUFFER, logEntry);
    
    const count = await redis.incr(ACCESS_LOG_COUNTER);
    
    if (count >= FLUSH_THRESHOLD) {
      await redis.set(ACCESS_LOG_COUNTER, '0');
      flushAccessLogBuffer().catch(err => 
        console.error('[SessionTracker] Background flush failed:', err)
      );
    }
  } catch (error) {
    console.error('[SessionTracker] Failed to buffer access log:', error);
  }
}

/**
 * Direct DB logging via stored procedure (with session-based billing fields)
 */
async function logAccessToDb(
  cardId: string,
  visitorHash: string,
  ownerId: string,
  tier: string,
  isOwnerAccess: boolean,
  wasOverage: boolean,
  creditCharged: boolean,
  sessionId?: string,
  sessionCostUsd?: number,
  isAiEnabled?: boolean
): Promise<void> {
  try {
    await supabaseAdmin.rpc('insert_access_log_server', {
      p_card_id: cardId,
      p_visitor_hash: visitorHash,
      p_card_owner_id: ownerId,
      p_subscription_tier: tier,
      p_is_owner_access: isOwnerAccess,
      p_was_overage: wasOverage,
      p_credit_charged: creditCharged,
      p_session_id: sessionId || visitorHash,
      p_session_cost_usd: sessionCostUsd || 0,
      p_is_ai_enabled: isAiEnabled || false
    });
  } catch (error) {
    console.error('[SessionTracker] Failed to log access to DB:', error);
  }
}

/**
 * Flush buffered access logs to database
 */
export async function flushAccessLogBuffer(): Promise<number> {
  if (!isRedisConfigured()) return 0;

  try {
    const processingKey = `${ACCESS_LOG_BUFFER}:processing:${Date.now()}`;
    
    try {
      await redis.rename(ACCESS_LOG_BUFFER, processingKey);
    } catch (e) {
      return 0;
    }

    const entries = await redis.lrange(processingKey, 0, -1);
    
    if (!entries || entries.length === 0) {
      await redis.del(processingKey);
      return 0;
    }

    console.log(`[SessionTracker] Flushing ${entries.length} access log entries to DB...`);

    let flushed = 0;
    for (const entry of entries) {
      try {
        const log = JSON.parse(entry as string);
        await supabaseAdmin.rpc('insert_access_log_server', {
          p_card_id: log.card_id,
          p_visitor_hash: log.visitor_hash,
          p_card_owner_id: log.card_owner_id,
          p_subscription_tier: log.subscription_tier,
          p_is_owner_access: log.is_owner_access,
          p_was_overage: log.was_overage,
          p_credit_charged: log.credit_charged,
          // Session-based billing fields
          p_session_id: log.session_id || log.visitor_hash,
          p_session_cost_usd: log.session_cost_usd || 0,
          p_is_ai_enabled: log.is_ai_enabled || false
        });
        flushed++;
      } catch (err) {
        console.error('[SessionTracker] Failed to flush log entry:', err);
      }
    }

    await redis.del(processingKey);
    await redis.set(ACCESS_LOG_COUNTER, '0');
    
    console.log(`[SessionTracker] Flushed ${flushed}/${entries.length} access log entries`);
    return flushed;
  } catch (error) {
    console.error('[SessionTracker] Failed to flush access log buffer:', error);
    return 0;
  }
}

// ============================================================================
// USER CACHE MANAGEMENT
// ============================================================================

/**
 * Invalidate user's cached tier/budget (call when subscription changes)
 */
export async function invalidateUserCache(userId: string): Promise<void> {
  if (!isRedisConfigured()) return;

  const month = getCurrentMonth();
  await Promise.all([
    redis.del(TIER_KEY(userId)),
    redis.del(BUDGET_KEY(userId, month))
  ]);
}

/**
 * Get usage stats for a user (for display)
 */
export async function getUsageStats(userId: string): Promise<{
  tier: string;
  monthlyBudget: number;
  budgetConsumed: number;
  budgetRemaining: number;
  aiSessionsUsed: number;
  nonAiSessionsUsed: number;
}> {
  const { tier, budgetAvailable } = await getOrInitUserInfo(userId);
  const month = getCurrentMonth();
  
  // Total budget from config
  const monthlyBudget = tier === 'premium' 
    ? SubscriptionConfig.premium.monthlyBudgetUsd 
    : 0;
  const budgetConsumed = Math.max(0, monthlyBudget - budgetAvailable);
  
  let aiSessions = 0;
  let nonAiSessions = 0;
  
  if (isRedisConfigured()) {
    aiSessions = parseInt(await redis.get(AI_SESSIONS_KEY(userId, month)) as string || '0', 10);
    nonAiSessions = parseInt(await redis.get(NON_AI_SESSIONS_KEY(userId, month)) as string || '0', 10);
  }

  return {
    tier,
    monthlyBudget,
    budgetConsumed,
    budgetRemaining: budgetAvailable,
    aiSessionsUsed: aiSessions,
    nonAiSessionsUsed: nonAiSessions
  };
}

/**
 * Reset user's monthly usage (called when subscription period starts)
 * Sets available budget to full monthly budget from config
 */
export async function resetUsage(userId: string): Promise<void> {
  if (!isRedisConfigured()) return;

  const month = getCurrentMonth();
  const { tier } = await getSubscriptionFromDb(userId);
  
  // Set available budget to full monthly budget (from config)
  const fullBudget = tier === 'premium' 
    ? SubscriptionConfig.premium.monthlyBudgetUsd 
    : 0;
  
  await Promise.all([
    redis.set(BUDGET_KEY(userId, month), fullBudget.toString(), { ex: CACHE_TTL }),
    redis.set(AI_SESSIONS_KEY(userId, month), '0', { ex: CACHE_TTL }),
    redis.set(NON_AI_SESSIONS_KEY(userId, month), '0', { ex: CACHE_TTL })
  ]);
  
  console.log(`[SessionTracker] Reset usage for user ${userId} for month ${month}, budget set to $${fullBudget}`);
}

/**
 * Update user's tier in Redis (called when subscription changes)
 */
export async function updateUserTier(userId: string, newTier: 'free' | 'premium'): Promise<void> {
  if (!isRedisConfigured()) return;

  const month = getCurrentMonth();
  const newBudget = newTier === 'premium' 
    ? SubscriptionConfig.premium.monthlyBudgetUsd 
    : 0;

  await Promise.all([
    redis.set(TIER_KEY(userId), newTier, { ex: CACHE_TTL }),
    redis.set(BUDGET_KEY(userId, month), newBudget.toString(), { ex: CACHE_TTL })
  ]);

  console.log(`[SessionTracker] Updated tier for user ${userId}: ${newTier} (budget: $${newBudget})`);
}

/**
 * Get daily access stats for a card (for display purposes)
 */
export async function getDailyAccessStats(cardId: string): Promise<{
  dailyLimit: number | null;
  currentScans: number;
  remaining: number | null;
}> {
  const dailyLimit = await getCardDailyLimit(cardId);
  const currentScans = await getCurrentDailyScans(cardId);

  return {
    dailyLimit,
    currentScans,
    remaining: dailyLimit === null ? null : Math.max(0, dailyLimit - currentScans)
  };
}
