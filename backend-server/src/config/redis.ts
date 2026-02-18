/**
 * Upstash Redis Configuration
 * 
 * Provides Redis client for caching and rate limiting.
 * Uses Upstash's REST-based Redis which works great with serverless/Cloud Run.
 */

import { Redis } from '@upstash/redis';
import { Ratelimit } from '@upstash/ratelimit';

// Redis client singleton
let redisClient: Redis | null = null;
let ratelimit: Ratelimit | null = null;

/**
 * Get or create Redis client
 */
export function getRedisClient(): Redis | null {
  if (redisClient) return redisClient;
  
  const url = process.env.UPSTASH_REDIS_REST_URL;
  const token = process.env.UPSTASH_REDIS_REST_TOKEN;
  
  if (!url || !token) {
    console.warn('[Redis] UPSTASH_REDIS_REST_URL or UPSTASH_REDIS_REST_TOKEN not configured');
    console.warn('[Redis] Caching and Redis-based rate limiting will be disabled');
    return null;
  }
  
  try {
    redisClient = new Redis({
      url,
      token,
    });
    console.log('[Redis] Connected to Upstash Redis');
    return redisClient;
  } catch (error) {
    console.error('[Redis] Failed to connect:', error);
    return null;
  }
}

/**
 * Check if Redis is configured and available
 */
export function isRedisConfigured(): boolean {
  return getRedisClient() !== null;
}

/**
 * Get the Redis client directly (for advanced usage)
 * Returns null if not configured
 */
export const redis = {
  get: async (key: string) => {
    const client = getRedisClient();
    if (!client) return null;
    return client.get(key);
  },
  set: async (key: string, value: string, options?: { ex?: number }) => {
    const client = getRedisClient();
    if (!client) return null;
    if (options?.ex) {
      return client.set(key, value, { ex: options.ex });
    }
    return client.set(key, value);
  },
  incr: async (key: string) => {
    const client = getRedisClient();
    if (!client) return -1;
    return client.incr(key);
  },
  incrby: async (key: string, increment: number) => {
    const client = getRedisClient();
    if (!client) return -1;
    return client.incrby(key, increment);
  },
  decr: async (key: string) => {
    const client = getRedisClient();
    if (!client) return -1;
    return client.decr(key);
  },
  incrbyfloat: async (key: string, increment: number) => {
    const client = getRedisClient();
    if (!client) return null;
    return client.incrbyfloat(key, increment);
  },
  expire: async (key: string, seconds: number) => {
    const client = getRedisClient();
    if (!client) return false;
    return client.expire(key, seconds);
  },
  del: async (key: string) => {
    const client = getRedisClient();
    if (!client) return 0;
    return client.del(key);
  },
  keys: async (pattern: string) => {
    const client = getRedisClient();
    if (!client) return [];
    return client.keys(pattern);
  },
  // List operations for buffering
  lpush: async (key: string, value: string) => {
    const client = getRedisClient();
    if (!client) return 0;
    return client.lpush(key, value);
  },
  lrange: async (key: string, start: number, stop: number) => {
    const client = getRedisClient();
    if (!client) return [];
    return client.lrange(key, start, stop);
  },
  ltrim: async (key: string, start: number, stop: number) => {
    const client = getRedisClient();
    if (!client) return 'OK';
    return client.ltrim(key, start, stop);
  },
  rename: async (key: string, newKey: string) => {
    const client = getRedisClient();
    if (!client) return 'OK';
    return client.rename(key, newKey);
  }
};

/**
 * Get or create rate limiter
 * Uses sliding window algorithm for smooth rate limiting
 */
export function getRateLimiter(): Ratelimit | null {
  if (ratelimit) return ratelimit;
  
  const client = getRedisClient();
  if (!client) return null;
  
  try {
    // Mobile API rate limit: 60 requests per minute per IP
    ratelimit = new Ratelimit({
      redis: client,
      limiter: Ratelimit.slidingWindow(60, '1 m'),
      analytics: true,
      prefix: 'ratelimit:mobile',
    });
    console.log('[Redis] Rate limiter initialized (60 req/min per IP)');
    return ratelimit;
  } catch (error) {
    console.error('[Redis] Failed to create rate limiter:', error);
    return null;
  }
}

/**
 * Cache key generators
 */
export const CacheKeys = {
  // Card content cache key (includes language)
  cardContent: (accessToken: string, language: string) => 
    `card:content:${accessToken}:${language}`,
  
  // Scan deduplication key (visitor-specific)
  scanDedup: (cardId: string, visitorHash: string) => 
    `scan:dedup:${cardId}:${visitorHash}`,
};

/**
 * Cache TTL values (in seconds)
 */
export const CacheTTL = {
  // Card content: 5 minutes (default, configurable)
  cardContent: parseInt(process.env.CACHE_CARD_CONTENT_TTL || '300', 10),
  
  // Scan deduplication: 30 minutes (configurable)
  // Matches session deduplication window for consistency
  scanDedup: parseInt(process.env.SCAN_DEDUP_WINDOW_SECONDS || '1800', 10),
};

/**
 * Generic cache get with type safety
 */
export async function cacheGet<T>(key: string): Promise<T | null> {
  const client = getRedisClient();
  if (!client) return null;
  
  try {
    const data = await client.get<T>(key);
    return data;
  } catch (error) {
    console.error(`[Redis] Cache get error for key ${key}:`, error);
    return null;
  }
}

/**
 * Generic cache set with TTL
 */
export async function cacheSet<T>(key: string, value: T, ttlSeconds: number): Promise<boolean> {
  const client = getRedisClient();
  if (!client) return false;
  
  try {
    await client.set(key, value, { ex: ttlSeconds });
    return true;
  } catch (error) {
    console.error(`[Redis] Cache set error for key ${key}:`, error);
    return false;
  }
}

/**
 * Check if key exists (for deduplication)
 */
export async function cacheExists(key: string): Promise<boolean> {
  const client = getRedisClient();
  if (!client) return false;
  
  try {
    const exists = await client.exists(key);
    return exists === 1;
  } catch (error) {
    console.error(`[Redis] Cache exists error for key ${key}:`, error);
    return false;
  }
}

/**
 * Set key with NX (only if not exists) - for deduplication
 */
export async function cacheSetNX(key: string, value: string, ttlSeconds: number): Promise<boolean> {
  const client = getRedisClient();
  if (!client) return false;
  
  try {
    const result = await client.set(key, value, { ex: ttlSeconds, nx: true });
    return result === 'OK';
  } catch (error) {
    console.error(`[Redis] Cache setNX error for key ${key}:`, error);
    return false;
  }
}

/**
 * Delete cache key (for invalidation)
 */
export async function cacheDelete(key: string): Promise<boolean> {
  const client = getRedisClient();
  if (!client) return false;
  
  try {
    await client.del(key);
    return true;
  } catch (error) {
    console.error(`[Redis] Cache delete error for key ${key}:`, error);
    return false;
  }
}

/**
 * Delete all keys matching a pattern (for bulk invalidation)
 * Use sparingly - SCAN can be slow with many keys
 */
export async function cacheDeletePattern(pattern: string): Promise<number> {
  const client = getRedisClient();
  if (!client) return 0;
  
  try {
    // Use keys command for simplicity (pattern matching)
    // Note: For very large datasets, consider using SCAN with iteration
    const keys = await client.keys(pattern);
    
    if (keys && keys.length > 0) {
      await client.del(...keys);
      return keys.length;
    }
    
    return 0;
  } catch (error) {
    console.error(`[Redis] Cache delete pattern error for ${pattern}:`, error);
    return 0;
  }
}

