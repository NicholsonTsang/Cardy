/**
 * Rate Limiting Middleware
 * 
 * Uses Upstash Redis for distributed rate limiting.
 * Falls back to in-memory rate limiting if Redis is unavailable.
 */

import { Request, Response, NextFunction } from 'express';
import { getRateLimiter } from '../config/redis';
import rateLimit from 'express-rate-limit';

/**
 * Get client identifier for rate limiting
 * Uses X-Forwarded-For header if behind a proxy, otherwise uses IP
 */
function getClientIdentifier(req: Request): string {
  // Check for forwarded IP (from Cloud Run, load balancers, etc.)
  const forwarded = req.headers['x-forwarded-for'];
  if (forwarded) {
    // Get the first IP in the chain (original client)
    const ips = Array.isArray(forwarded) ? forwarded[0] : forwarded.split(',')[0];
    return ips.trim();
  }
  
  // Fallback to direct connection IP
  return req.ip || req.socket.remoteAddress || 'unknown';
}

/**
 * Redis-based rate limiting middleware for mobile API
 * 60 requests per minute per IP
 */
export async function redisRateLimit(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  const limiter = getRateLimiter();
  
  // If Redis is not available, skip rate limiting (fallback middleware will handle it)
  if (!limiter) {
    return next();
  }
  
  const identifier = getClientIdentifier(req);
  
  try {
    const result = await limiter.limit(identifier);
    
    // Set rate limit headers
    res.setHeader('X-RateLimit-Limit', result.limit);
    res.setHeader('X-RateLimit-Remaining', result.remaining);
    res.setHeader('X-RateLimit-Reset', result.reset);
    
    if (!result.success) {
      const retryAfter = Math.ceil((result.reset - Date.now()) / 1000);
      res.setHeader('Retry-After', retryAfter);
      
      res.status(429).json({
        error: 'Too Many Requests',
        message: 'Rate limit exceeded. Please try again later.',
        retryAfter,
      });
      return;
    }
    
    next();
  } catch (error) {
    console.error('[RateLimit] Redis error:', error);
    // On Redis error, allow the request through (fail open)
    next();
  }
}

/**
 * Fallback in-memory rate limiter
 * Used when Redis is not available
 */
export const fallbackRateLimit = rateLimit({
  windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS || '60000', 10), // 1 minute
  max: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS || '60', 10), // 60 requests
  message: {
    error: 'Too Many Requests',
    message: 'Rate limit exceeded. Please try again later.',
  },
  standardHeaders: true,
  legacyHeaders: false,
  keyGenerator: getClientIdentifier,
});

/**
 * Combined rate limiting middleware
 * Tries Redis first, falls back to in-memory if unavailable
 */
export function combinedRateLimit(
  req: Request,
  res: Response,
  next: NextFunction
): void {
  const limiter = getRateLimiter();
  
  if (limiter) {
    // Use Redis-based rate limiting
    redisRateLimit(req, res, next);
  } else {
    // Fallback to in-memory rate limiting
    fallbackRateLimit(req, res, next);
  }
}

/**
 * Strict rate limiter for sensitive endpoints
 * 10 requests per minute per IP
 */
export async function strictRateLimit(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  const limiter = getRateLimiter();
  
  if (!limiter) {
    // Fallback: use express-rate-limit with stricter settings
    const strictFallback = rateLimit({
      windowMs: 60000,
      max: 10,
      message: {
        error: 'Too Many Requests',
        message: 'Rate limit exceeded for this endpoint.',
      },
      keyGenerator: getClientIdentifier,
    });
    return strictFallback(req, res, next);
  }
  
  const identifier = `strict:${getClientIdentifier(req)}`;
  
  try {
    // Create a stricter limiter for this request
    const { Ratelimit } = await import('@upstash/ratelimit');
    const { getRedisClient } = await import('../config/redis');
    
    const client = getRedisClient();
    if (!client) {
      return next();
    }
    
    const strictLimiter = new Ratelimit({
      redis: client,
      limiter: Ratelimit.slidingWindow(10, '1 m'),
      prefix: 'ratelimit:strict',
    });
    
    const result = await strictLimiter.limit(identifier);
    
    res.setHeader('X-RateLimit-Limit', result.limit);
    res.setHeader('X-RateLimit-Remaining', result.remaining);
    res.setHeader('X-RateLimit-Reset', result.reset);
    
    if (!result.success) {
      const retryAfter = Math.ceil((result.reset - Date.now()) / 1000);
      res.setHeader('Retry-After', retryAfter);
      
      res.status(429).json({
        error: 'Too Many Requests',
        message: 'Rate limit exceeded for this endpoint.',
        retryAfter,
      });
      return;
    }
    
    next();
  } catch (error) {
    console.error('[StrictRateLimit] Error:', error);
    next();
  }
}

