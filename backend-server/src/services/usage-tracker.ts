/**
 * Redis-First Usage Tracking Service
 * 
 * Redis (Upstash) is the SINGLE SOURCE OF TRUTH for usage tracking.
 * No background sync to PostgreSQL - Redis has persistence (AOF, multi-replica).
 * 
 * PostgreSQL is only hit when:
 * - First access of the month (to get tier info, then cached in Redis)
 * - Overage purchase (1 DB call per 100 extra access)
 * - Access logging (async, non-blocking)
 */

import { redis, isRedisConfigured } from '../config/redis';
import { supabaseAdmin } from '../config/supabase';
import { SubscriptionConfig } from '../config/subscription';

// Redis key patterns - Monthly (subscription billing)
const USAGE_KEY = (userId: string, month: string) => `access:user:${userId}:month:${month}`;
const TIER_KEY = (userId: string) => `access:user:${userId}:tier`;
const LIMIT_KEY = (userId: string) => `access:user:${userId}:limit`;

// Redis key patterns - Daily (per-card creator protection)
const DAILY_SCANS_KEY = (cardId: string, date: string) => `access:card:${cardId}:date:${date}:scans`;
const DAILY_LIMIT_KEY = (cardId: string) => `access:card:${cardId}:daily_limit`;

// Cache TTL (35 days to cover month + buffer)
const CACHE_TTL = 35 * 24 * 60 * 60;

// Daily limit cache TTL (2 days - covers today + buffer for timezone edge cases)
const DAILY_CACHE_TTL = 2 * 24 * 60 * 60;

// Threshold for checking PostgreSQL (90% of limit)
const LIMIT_CHECK_THRESHOLD = 0.9;

// Overage batch configuration (from SubscriptionConfig)
// Using getter functions to ensure we get current config values
const getOverageCreditsPerBatch = () => SubscriptionConfig.overage.creditsPerBatch;
const getOverageAccessPerBatch = () => SubscriptionConfig.overage.accessPerBatch;

interface UsageCheckResult {
  allowed: boolean;
  currentUsage: number;
  limit: number;
  tier: 'free' | 'premium';
  isOverage: boolean;
  needsDbCheck: boolean;
  reason: string;
}

interface OverageResult {
  allowed: boolean;
  creditDeducted: boolean;
  creditsCharged?: number;
  accessGranted?: number;
  newBalance?: number;
  newLimit?: number;
  reason: string;
}

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

// ============================================================================
// DAILY ACCESS LIMIT (Per-Card Creator Protection)
// ============================================================================
// Purpose: Protect creators from unexpected traffic spikes
// - Tracked per card, per day in Redis
// - Configurable limit per card (daily_scan_limit in cards table)
// - Resets automatically each day (new Redis key per date)
// - NULL limit = unlimited (no daily restriction)
// ============================================================================

interface DailyLimitCheckResult {
  allowed: boolean;
  currentScans: number;
  dailyLimit: number | null; // NULL = unlimited
  reason: string;
}

/**
 * Get card's daily scan limit from Redis cache or DB
 * Returns NULL if no daily limit is set (unlimited)
 */
async function getCardDailyLimit(cardId: string): Promise<number | null> {
  if (!isRedisConfigured()) {
    // Fallback: get from database
    return getDailyLimitFromDb(cardId);
  }

  const cachedLimit = await redis.get(DAILY_LIMIT_KEY(cardId));
  
  if (cachedLimit !== null) {
    // "null" string means unlimited (we cached that there's no limit)
    if (cachedLimit === 'null') return null;
    return parseInt(cachedLimit as string, 10);
  }

  // Not in cache - fetch from database and cache
  const dbLimit = await getDailyLimitFromDb(cardId);
  
  // Cache the limit (store "null" string for unlimited)
  await redis.set(
    DAILY_LIMIT_KEY(cardId), 
    dbLimit === null ? 'null' : dbLimit.toString(), 
    { ex: DAILY_CACHE_TTL }
  );

  return dbLimit;
}

/**
 * Get daily limit from database
 */
async function getDailyLimitFromDb(cardId: string): Promise<number | null> {
  const { data, error } = await supabaseAdmin
    .from('cards')
    .select('daily_scan_limit')
    .eq('id', cardId)
    .single();

  if (error || !data) {
    console.warn(`[UsageTracker] Failed to get daily limit for card ${cardId}:`, error);
    return null; // Default to unlimited on error
  }

  return data.daily_scan_limit;
}

/**
 * Get current daily scan count from Redis
 */
async function getCurrentDailyScans(cardId: string): Promise<number> {
  if (!isRedisConfigured()) return 0;

  const date = getCurrentDate();
  const countResult = await redis.get(DAILY_SCANS_KEY(cardId, date));
  const count = countResult as string | null;
  return count ? parseInt(count, 10) : 0;
}

/**
 * Increment daily scan counter in Redis
 * Returns the new count after increment
 */
async function incrementDailyScans(cardId: string): Promise<number> {
  if (!isRedisConfigured()) return 0;

  const date = getCurrentDate();
  const key = DAILY_SCANS_KEY(cardId, date);

  // Atomic increment
  const newCount = await redis.incr(key);
  
  // Set TTL on first access of the day
  if (newCount === 1) {
    await redis.expire(key, DAILY_CACHE_TTL);
  }

  return newCount;
}

/**
 * Decrement daily scan counter (used when access is denied after increment)
 */
async function decrementDailyScans(cardId: string): Promise<void> {
  if (!isRedisConfigured()) return;

  const date = getCurrentDate();
  await redis.decr(DAILY_SCANS_KEY(cardId, date));
}

/**
 * Check if card has reached daily scan limit (Redis-first)
 * 
 * This is a PRE-CHECK that should be called BEFORE monthly usage check.
 * Returns immediately if daily limit exceeded - no need to count against monthly.
 * 
 * @param cardId - The card being accessed
 * @returns DailyLimitCheckResult with allowed status and current counts
 */
export async function checkDailyLimit(cardId: string): Promise<DailyLimitCheckResult> {
  const isDebug = process.env.DEBUG_USAGE === 'true';

  // If Redis not configured, allow access (can't enforce limits)
  if (!isRedisConfigured()) {
    return {
      allowed: true,
      currentScans: 0,
      dailyLimit: null,
      reason: 'Redis not configured - daily limit not enforced'
    };
  }

  try {
    // Get card's daily limit (from cache or DB)
    const dailyLimit = await getCardDailyLimit(cardId);

    // No daily limit configured = unlimited
    if (dailyLimit === null) {
      if (isDebug) console.log(`[UsageTracker] Card ${cardId.slice(0, 8)}... has no daily limit`);
      return {
        allowed: true,
        currentScans: 0,
        dailyLimit: null,
        reason: 'No daily limit configured'
      };
    }

    // Get current daily scan count
    const currentScans = await getCurrentDailyScans(cardId);
    
    if (isDebug) console.log(`[UsageTracker] Card ${cardId.slice(0, 8)}... daily scans: ${currentScans}/${dailyLimit}`);

    // Check if within limit
    if (currentScans < dailyLimit) {
      return {
        allowed: true,
        currentScans,
        dailyLimit,
        reason: 'Within daily limit'
      };
    }

    // Daily limit reached
    console.log(`[UsageTracker] ❌ Daily limit reached for card ${cardId.slice(0, 8)}...: ${currentScans}/${dailyLimit}`);
    return {
      allowed: false,
      currentScans,
      dailyLimit,
      reason: `Daily access limit reached (${dailyLimit}/day). Please try again tomorrow.`
    };
  } catch (error) {
    console.error('[UsageTracker] Daily limit check error:', error);
    // Allow access on error (fail open for better UX)
    return {
      allowed: true,
      currentScans: 0,
      dailyLimit: null,
      reason: 'Error checking daily limit - allowing access'
    };
  }
}

/**
 * Increment daily scan counter after successful access
 * Should be called AFTER access is confirmed allowed
 */
export async function recordDailyAccess(cardId: string): Promise<number> {
  return incrementDailyScans(cardId);
}

/**
 * Rollback daily scan counter if access ultimately denied
 * Call this if monthly limit check fails after daily check passed
 */
export async function rollbackDailyAccess(cardId: string): Promise<void> {
  await decrementDailyScans(cardId);
}

/**
 * Invalidate card's cached daily limit (call when card settings change)
 */
export async function invalidateCardDailyLimit(cardId: string): Promise<void> {
  if (!isRedisConfigured()) return;
  await redis.del(DAILY_LIMIT_KEY(cardId));
}

/**
 * Get daily access stats for a card (for display purposes)
 */
export async function getDailyAccessStats(cardId: string): Promise<{
  dailyLimit: number | null;
  currentScans: number;
  remaining: number | null; // NULL if unlimited
}> {
  const dailyLimit = await getCardDailyLimit(cardId);
  const currentScans = await getCurrentDailyScans(cardId);

  return {
    dailyLimit,
    currentScans,
    remaining: dailyLimit === null ? null : Math.max(0, dailyLimit - currentScans)
  };
}

/**
 * Get or initialize user's subscription info in Redis
 */
async function getOrInitUserInfo(userId: string): Promise<{ tier: 'free' | 'premium'; limit: number }> {
  if (!isRedisConfigured()) {
    // Fallback: get from database
    return getSubscriptionFromDb(userId);
  }

  const [tierResult, limitResult] = await Promise.all([
    redis.get(TIER_KEY(userId)),
    redis.get(LIMIT_KEY(userId))
  ]);

  const tierStr = tierResult as string | null;
  const limitStr = limitResult as string | null;

  if (tierStr && limitStr) {
    return {
      tier: tierStr as 'free' | 'premium',
      limit: parseInt(limitStr, 10)
    };
  }

  // Not in cache - fetch from database and cache
  const dbInfo = await getSubscriptionFromDb(userId);
  
  // Cache the info
  await Promise.all([
    redis.set(TIER_KEY(userId), dbInfo.tier, { ex: CACHE_TTL }),
    redis.set(LIMIT_KEY(userId), dbInfo.limit.toString(), { ex: CACHE_TTL })
  ]);

  return dbInfo;
}

/**
 * Get subscription info from PostgreSQL via stored procedure
 */
async function getSubscriptionFromDb(userId: string): Promise<{ tier: 'free' | 'premium'; limit: number }> {
  const { data: rows, error } = await supabaseAdmin.rpc(
    'get_subscription_by_user_server',
    { p_user_id: userId }
  );

  const data = rows?.[0];

  if (error || !data) {
    // No subscription - return free tier defaults
    return {
      tier: 'free',
      limit: SubscriptionConfig.free.monthlyAccessLimit
    };
  }

  const tier = data.tier as 'free' | 'premium';
  const limit = tier === 'premium' 
    ? SubscriptionConfig.premium.monthlyAccessLimit 
    : SubscriptionConfig.free.monthlyAccessLimit;

  return { tier, limit };
}

/**
 * Increment usage counter in Redis
 * Returns the new count after increment
 */
async function incrementUsage(userId: string): Promise<number> {
  const month = getCurrentMonth();
  const key = USAGE_KEY(userId, month);

  if (!isRedisConfigured()) {
    // Fallback: return -1 to trigger DB check
    return -1;
  }

  // Atomic increment
  const newCount = await redis.incr(key);
  
  // Set TTL on first access
  if (newCount === 1) {
    await redis.expire(key, CACHE_TTL);
  }

  return newCount;
}

/**
 * Get current usage count from Redis
 */
async function getCurrentUsage(userId: string): Promise<number> {
  if (!isRedisConfigured()) {
    return -1;
  }

  const month = getCurrentMonth();
  const countResult = await redis.get(USAGE_KEY(userId, month));
  const count = countResult as string | null;
  return count ? parseInt(count, 10) : 0;
}

/**
 * Check if user can access (Redis-first)
 * Only hits PostgreSQL when necessary
 */
export async function checkAndIncrementUsage(
  userId: string,
  _cardId: string,
  _visitorHash: string,
  isOwnerAccess: boolean = false
): Promise<UsageCheckResult> {
  const isDebug = process.env.DEBUG_USAGE === 'true';
  
  // Owner access is always free
  if (isOwnerAccess) {
    if (isDebug) console.log(`[UsageTracker] Owner access for user ${userId.slice(0, 8)}... - FREE`);
    return {
      allowed: true,
      currentUsage: 0,
      limit: 0,
      tier: 'free',
      isOverage: false,
      needsDbCheck: false,
      reason: 'Owner access (free)'
    };
  }

  // If Redis not configured, fall back to DB
  if (!isRedisConfigured()) {
    console.warn('[UsageTracker] Redis not configured - falling back to DB');
    return {
      allowed: true, // Will be checked by DB
      currentUsage: 0,
      limit: 0,
      tier: 'free',
      isOverage: false,
      needsDbCheck: true,
      reason: 'Redis not configured - using DB'
    };
  }

  try {
    // Get user's tier and limit from Redis (or DB if not cached)
    const { tier, limit } = await getOrInitUserInfo(userId);
    if (isDebug) console.log(`[UsageTracker] User ${userId.slice(0, 8)}... tier=${tier} limit=${limit}`);

    // Increment usage counter
    const currentUsage = await incrementUsage(userId);
    if (isDebug) console.log(`[UsageTracker] User ${userId.slice(0, 8)}... usage: ${currentUsage}/${limit}`);

    // Check if within limit
    if (currentUsage <= limit) {
      // Check if approaching limit (need to verify with DB)
      const needsDbCheck = currentUsage >= Math.floor(limit * LIMIT_CHECK_THRESHOLD);
      
      if (isDebug) console.log(`[UsageTracker] ✅ Access allowed: ${currentUsage}/${limit} (${Math.round(currentUsage/limit*100)}%)`);
      return {
        allowed: true,
        currentUsage,
        limit,
        tier,
        isOverage: false,
        needsDbCheck,
        reason: needsDbCheck ? 'Approaching limit - verify with DB' : 'Within limit'
      };
    }

    // Over limit
    if (tier === 'premium') {
      // Premium can use overage credits - need DB check
      if (isDebug) console.log(`[UsageTracker] ⚠️  Premium over limit: ${currentUsage}/${limit} - checking overage`);
      return {
        allowed: false, // Will be determined by overage check
        currentUsage,
        limit,
        tier,
        isOverage: true,
        needsDbCheck: true,
        reason: 'Over limit - checking overage credits'
      };
    } else {
      // Free tier - deny access
      // Decrement the counter since access is denied
      await redis.decr(USAGE_KEY(userId, getCurrentMonth()));
      
      console.log(`[UsageTracker] ❌ Free tier limit reached for user ${userId.slice(0, 8)}...: ${currentUsage-1}/${limit}`);
      return {
        allowed: false,
        currentUsage: currentUsage - 1,
        limit,
        tier,
        isOverage: false,
        needsDbCheck: false,
        reason: `Monthly limit reached (${limit}/month for free tier). Upgrade to Premium for more access.`
      };
    }
  } catch (error) {
    console.error('[UsageTracker] Redis error:', error);
    // Fallback to DB on error
    return {
      allowed: true,
      currentUsage: 0,
      limit: 0,
      tier: 'free',
      isOverage: false,
      needsDbCheck: true,
      reason: 'Redis error - falling back to DB'
    };
  }
}

/**
 * Process overage for premium users using BATCH approach
 * 
 * When user exceeds limit:
 * 1. Check if they have >= OVERAGE_CREDITS_PER_BATCH (5) credits
 * 2. If yes, deduct credits and extend limit by OVERAGE_ACCESS_PER_BATCH (100)
 * 3. Next 100 accesses are Redis-only (no DB hit!)
 * 
 * Benefits:
 * - 1 DB hit per 100 overage accesses (instead of 100 DB hits)
 * - Simpler billing model
 * - Better performance during traffic spikes
 * 
 * Note: The DB writes (user_credits, credit_consumptions, credit_transactions)
 * are NOT in a single transaction. This is acceptable because:
 * - This only runs ~1 per 100 overage accesses (rare)
 * - If partially fails, the worst case is incomplete logging
 * - For full ACID guarantees, consider migrating to a stored procedure
 */
export async function processOverage(
  userId: string,
  cardId: string,
  _visitorHash: string,
  _overageRate: number // Kept for API compatibility, but not used in batch model
): Promise<OverageResult> {
  try {
    // Check credit balance
    const creditsRequired = getOverageCreditsPerBatch();
    const accessToGrant = getOverageAccessPerBatch();

    // Use atomic stored procedure for credit deduction
    // This handles: balance check, deduction, consumption log, transaction log
    const { data: result, error } = await supabaseAdmin.rpc(
      'deduct_overage_credits_server',
      {
        p_user_id: userId,
        p_card_id: cardId,
        p_credits_amount: creditsRequired,
        p_access_granted: accessToGrant
      }
    );

    if (error) {
      console.error('[UsageTracker] Overage credit deduction failed:', error);
      // Decrement Redis counter since access denied
      if (isRedisConfigured()) {
        await redis.decr(USAGE_KEY(userId, getCurrentMonth()));
      }
      return {
        allowed: false,
        creditDeducted: false,
        reason: 'Failed to process overage credits'
      };
    }

    // Check if stored procedure returned failure (insufficient credits)
    if (!result?.success) {
      // Decrement Redis counter since access denied
      if (isRedisConfigured()) {
        await redis.decr(USAGE_KEY(userId, getCurrentMonth()));
      }
      
      return {
        allowed: false,
        creditDeducted: false,
        reason: `Monthly limit exceeded. Need ${creditsRequired} credits to unlock ${accessToGrant} more accesses. Current balance: ${result?.current_balance?.toFixed(2) || '0.00'}`
      };
    }

    const newBalance = result.balance_after;

    // Extend the limit in Redis by the batch amount
    // This means next 100 accesses won't hit the database!
    if (isRedisConfigured()) {
      const currentLimit = await redis.get(LIMIT_KEY(userId));
      const limitNum = currentLimit ? parseInt(currentLimit as string, 10) : SubscriptionConfig.premium.monthlyAccessLimit;
      const newLimit = limitNum + accessToGrant;
      
      await redis.set(LIMIT_KEY(userId), newLimit.toString(), { ex: CACHE_TTL });
      
      console.log(`[UsageTracker] Extended limit for user ${userId}: ${limitNum} → ${newLimit} (+${accessToGrant})`);
      
      return {
        allowed: true,
        creditDeducted: true,
        creditsCharged: creditsRequired,
        accessGranted: accessToGrant,
        newBalance,
        newLimit,
        reason: `Purchased ${accessToGrant} additional access for ${creditsRequired} credits`
      };
    }

    return {
      allowed: true,
      creditDeducted: true,
      creditsCharged: creditsRequired,
      accessGranted: accessToGrant,
      newBalance,
      reason: `Purchased ${accessToGrant} additional access for ${creditsRequired} credits`
    };
  } catch (error: any) {
    console.error('[UsageTracker] Overage processing error:', error);
    
    // Decrement Redis counter on error
    if (isRedisConfigured()) {
      await redis.decr(USAGE_KEY(userId, getCurrentMonth()));
    }
    
    return {
      allowed: false,
      creditDeducted: false,
      reason: 'Error processing overage'
    };
  }
}

// Redis key for access log buffer
const ACCESS_LOG_BUFFER = 'access_log_buffer';
const ACCESS_LOG_COUNTER = 'access_log_counter';
const FLUSH_THRESHOLD = 100; // Auto-flush after 100 entries

/**
 * Log access to Redis buffer (instant, no DB hit)
 * Auto-flushes to DB when buffer reaches FLUSH_THRESHOLD entries
 */
export async function logAccess(
  cardId: string,
  visitorHash: string,
  ownerId: string,
  tier: string,
  isOwnerAccess: boolean,
  wasOverage: boolean,
  creditCharged: boolean
): Promise<void> {
  if (!isRedisConfigured()) {
    // Fallback to direct DB if Redis not available
    await logAccessToDb(cardId, visitorHash, ownerId, tier, isOwnerAccess, wasOverage, creditCharged);
    return;
  }

  try {
    // Buffer log entry in Redis (instant)
    const logEntry = JSON.stringify({
      card_id: cardId,
      visitor_hash: visitorHash,
      card_owner_id: ownerId,
      subscription_tier: tier,
      is_owner_access: isOwnerAccess,
      was_overage: wasOverage,
      credit_charged: creditCharged,
      accessed_at: new Date().toISOString()
    });
    
    await redis.lpush(ACCESS_LOG_BUFFER, logEntry);
    
    // Increment counter and check if we should auto-flush
    const count = await redis.incr(ACCESS_LOG_COUNTER);
    
    if (count >= FLUSH_THRESHOLD) {
      // Reset counter and flush in background (don't block response)
      await redis.set(ACCESS_LOG_COUNTER, '0');
      flushAccessLogBuffer().catch(err => 
        console.error('[UsageTracker] Background flush failed:', err)
      );
    }
  } catch (error) {
    console.error('[UsageTracker] Failed to buffer access log:', error);
  }
}

/**
 * Direct DB logging (used as fallback or for immediate logging needs)
 */
async function logAccessToDb(
  cardId: string,
  visitorHash: string,
  ownerId: string,
  tier: string,
  isOwnerAccess: boolean,
  wasOverage: boolean,
  creditCharged: boolean
): Promise<void> {
  try {
    await supabaseAdmin.rpc('insert_access_log_server', {
      p_card_id: cardId,
      p_visitor_hash: visitorHash,
      p_card_owner_id: ownerId,
      p_subscription_tier: tier,
      p_is_owner_access: isOwnerAccess,
      p_was_overage: wasOverage,
      p_credit_charged: creditCharged
    });
  } catch (error) {
    console.error('[UsageTracker] Failed to log access to DB:', error);
  }
}

/**
 * Flush buffered access logs to database
 * Call this before fetching daily stats, or periodically via cron
 */
export async function flushAccessLogBuffer(): Promise<number> {
  if (!isRedisConfigured()) return 0;

  try {
    // Rename key to handle concurrency safely (prevent data loss if new logs come in during flush)
    // If new logs arrive during processing, they will start a new list at the original key
    const processingKey = `${ACCESS_LOG_BUFFER}:processing:${Date.now()}`;
    
    try {
      await redis.rename(ACCESS_LOG_BUFFER, processingKey);
    } catch (e) {
      // Key likely doesn't exist (empty buffer), just return
      return 0;
    }

    // Get all buffered entries from the renamed key
    const entries = await redis.lrange(processingKey, 0, -1);
    
    if (!entries || entries.length === 0) {
      // Should not happen after successful rename, but good safety
      await redis.del(processingKey);
      return 0;
    }

    console.log(`[UsageTracker] Flushing ${entries.length} access log entries to DB...`);

    // Insert in batches
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
          p_credit_charged: log.credit_charged
        });
        flushed++;
      } catch (err) {
        console.error('[UsageTracker] Failed to flush log entry:', err);
      }
    }

    // Clear the temporary processing key
    await redis.del(processingKey);
    
    // Reset the counter (approximate is fine)
    await redis.set(ACCESS_LOG_COUNTER, '0');
    
    console.log(`[UsageTracker] Flushed ${flushed}/${entries.length} access log entries`);
    return flushed;
  } catch (error) {
    console.error('[UsageTracker] Failed to flush access log buffer:', error);
    return 0;
  }
}

/**
 * Invalidate user's cached tier/limit (call when subscription changes)
 */
export async function invalidateUserCache(userId: string): Promise<void> {
  if (!isRedisConfigured()) return;

  await Promise.all([
    redis.del(TIER_KEY(userId)),
    redis.del(LIMIT_KEY(userId))
  ]);
}

/**
 * Get usage stats for a user (Redis-first)
 */
export async function getUsageStats(userId: string): Promise<{
  tier: string;
  limit: number;
  used: number;
  remaining: number;
}> {
  const { tier, limit } = await getOrInitUserInfo(userId);
  const used = await getCurrentUsage(userId);
  
  // If Redis not available, fallback to 0 (assume fresh start)
  if (used === -1) {
    return {
      tier,
      limit,
      used: 0,
      remaining: limit
    };
  }

  return {
    tier,
    limit,
    used,
    remaining: Math.max(0, limit - used)
  };
}

/**
 * Reset user's monthly usage (called when subscription period starts)
 */
export async function resetUsage(userId: string): Promise<void> {
  if (!isRedisConfigured()) return;

  const month = getCurrentMonth();
  
  // Reset usage counter to 0
  await redis.set(USAGE_KEY(userId, month), '0', { ex: CACHE_TTL });
  
  // Reset limit back to base (remove any overage extensions)
  await redis.del(LIMIT_KEY(userId));
  
  console.log(`[UsageTracker] Reset usage for user ${userId} for month ${month}`);
}

/**
 * Update user's tier in Redis (called when subscription changes)
 */
export async function updateUserTier(userId: string, newTier: 'free' | 'premium'): Promise<void> {
  if (!isRedisConfigured()) return;

  const newLimit = newTier === 'premium' 
    ? SubscriptionConfig.premium.monthlyAccessLimit 
    : SubscriptionConfig.free.monthlyAccessLimit;

  await Promise.all([
    redis.set(TIER_KEY(userId), newTier, { ex: CACHE_TTL }),
    redis.set(LIMIT_KEY(userId), newLimit.toString(), { ex: CACHE_TTL })
  ]);

  console.log(`[UsageTracker] Updated tier for user ${userId}: ${newTier} (limit: ${newLimit})`);
}

