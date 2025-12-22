/**
 * Subscription Configuration
 * Centralized business parameters for the subscription system
 * All values can be overridden via environment variables
 * 
 * NEW PRICING MODEL (Session-Based):
 * - Premium subscription: $30/month
 * - AI-enabled project access: $0.05 per user session
 * - AI-disabled project access: $0.025 per user session
 * - Default monthly allowance: 600 AI-enabled OR 1200 AI-disabled sessions (= $30 value)
 * - Auto top-up: $5 credit = 100 AI-enabled OR 200 AI-disabled sessions
 * 
 * User sessions are tracked via Cloudflare with expiration limits.
 * Redis is used for real-time session counting to reduce database load.
 */

export const SubscriptionConfig = {
  // Free tier limits (no access to premium features, limited for trial)
  free: {
    experienceLimit: parseInt(process.env.FREE_TIER_EXPERIENCE_LIMIT || '3'),
    // Free tier: limited sessions for trial purposes
    monthlySessionLimit: parseInt(process.env.FREE_TIER_MONTHLY_SESSION_LIMIT || '50'),
    translationsEnabled: false,
  },
  
  // Premium tier limits and pricing
  premium: {
    // Monthly subscription fee
    monthlyFeeUsd: parseFloat(process.env.PREMIUM_MONTHLY_FEE_USD || '30'),
    experienceLimit: parseInt(process.env.PREMIUM_EXPERIENCE_LIMIT || '15'),
    translationsEnabled: true,
    
    // Session-based pricing (per user session)
    aiEnabledSessionCostUsd: parseFloat(process.env.AI_ENABLED_SESSION_COST_USD || '0.05'),
    aiDisabledSessionCostUsd: parseFloat(process.env.AI_DISABLED_SESSION_COST_USD || '0.025'),
    
    // Monthly session allowance included with $30 subscription
    // 600 AI-enabled sessions @ $0.05 = $30 OR 1200 AI-disabled sessions @ $0.025 = $30
    monthlyBudgetUsd: parseFloat(process.env.PREMIUM_MONTHLY_BUDGET_USD || '30'),
    
    // Calculated default limits (for backward compatibility)
    get defaultAiEnabledSessions() {
      return Math.floor(this.monthlyBudgetUsd / this.aiEnabledSessionCostUsd); // 600
    },
    get defaultAiDisabledSessions() {
      return Math.floor(this.monthlyBudgetUsd / this.aiDisabledSessionCostUsd); // 1200
    },
  },
  
  // Overage/Top-up configuration
  // When budget is exhausted, auto top-up with credits
  overage: {
    // Credits per top-up batch (= USD value)
    creditsPerBatch: parseInt(process.env.OVERAGE_CREDITS_PER_BATCH || '5'),     // $5 per top-up
    
    // Sessions granted per top-up (based on session type)
    // $5 / $0.05 = 100 AI-enabled sessions
    // $5 / $0.025 = 200 AI-disabled sessions
    get aiEnabledSessionsPerBatch() {
      return Math.floor(this.creditsPerBatch / SubscriptionConfig.premium.aiEnabledSessionCostUsd); // 100
    },
    get aiDisabledSessionsPerBatch() {
      return Math.floor(this.creditsPerBatch / SubscriptionConfig.premium.aiDisabledSessionCostUsd); // 200
    },
  },
  
  // Session tracking configuration
  session: {
    // Session expiration time in seconds (via Cloudflare)
    // Default: 30 minutes of inactivity
    expirationSeconds: parseInt(process.env.SESSION_EXPIRATION_SECONDS || '1800'),
    
    // Redis key TTL for session tracking (1 day buffer beyond month)
    redisTtlSeconds: parseInt(process.env.SESSION_REDIS_TTL_SECONDS || String(35 * 24 * 60 * 60)),
    
    // Deduplication window for same visitor (prevents rapid refresh abuse)
    dedupWindowSeconds: parseInt(process.env.SESSION_DEDUP_WINDOW_SECONDS || '300'),
  },
  
  // Stripe configuration
  stripe: {
    premiumPriceId: process.env.STRIPE_PREMIUM_PRICE_ID || '',
    creditPriceId: process.env.STRIPE_CREDIT_PRICE_ID || '',
  }
};

// Session cost types for billing
export type SessionType = 'ai_enabled' | 'ai_disabled';

/**
 * Get session cost based on AI enabled status
 */
export function getSessionCost(isAiEnabled: boolean): number {
  return isAiEnabled 
    ? SubscriptionConfig.premium.aiEnabledSessionCostUsd 
    : SubscriptionConfig.premium.aiDisabledSessionCostUsd;
}

/**
 * Calculate sessions remaining from budget
 */
export function calculateSessionsFromBudget(budgetUsd: number, isAiEnabled: boolean): number {
  const costPerSession = getSessionCost(isAiEnabled);
  return Math.floor(budgetUsd / costPerSession);
}

/**
 * Calculate budget consumed from sessions
 */
export function calculateBudgetFromSessions(sessions: number, isAiEnabled: boolean): number {
  const costPerSession = getSessionCost(isAiEnabled);
  return sessions * costPerSession;
}

/**
 * Get subscription tier details
 */
export function getTierDetails(tier: 'free' | 'premium') {
  if (tier === 'premium') {
    return {
      tier: 'premium',
      experienceLimit: SubscriptionConfig.premium.experienceLimit,
      monthlyBudgetUsd: SubscriptionConfig.premium.monthlyBudgetUsd,
      aiEnabledSessionCost: SubscriptionConfig.premium.aiEnabledSessionCostUsd,
      aiDisabledSessionCost: SubscriptionConfig.premium.aiDisabledSessionCostUsd,
      defaultAiEnabledSessions: SubscriptionConfig.premium.defaultAiEnabledSessions,
      defaultAiDisabledSessions: SubscriptionConfig.premium.defaultAiDisabledSessions,
      translationsEnabled: SubscriptionConfig.premium.translationsEnabled,
      monthlyFeeUsd: SubscriptionConfig.premium.monthlyFeeUsd,
      overage: {
        creditsPerBatch: SubscriptionConfig.overage.creditsPerBatch,
        aiEnabledSessionsPerBatch: SubscriptionConfig.overage.aiEnabledSessionsPerBatch,
        aiDisabledSessionsPerBatch: SubscriptionConfig.overage.aiDisabledSessionsPerBatch,
      },
    };
  }
  
  return {
    tier: 'free',
    experienceLimit: SubscriptionConfig.free.experienceLimit,
    monthlySessionLimit: SubscriptionConfig.free.monthlySessionLimit,
    translationsEnabled: SubscriptionConfig.free.translationsEnabled,
    monthlyFeeUsd: 0,
    overage: null, // Free tier cannot buy overage
  };
}

/**
 * Get all pricing info for frontend display
 */
export function getPricingInfo() {
  return {
    free: {
      name: 'Free',
      price: 0,
      experienceLimit: SubscriptionConfig.free.experienceLimit,
      monthlySessionLimit: SubscriptionConfig.free.monthlySessionLimit,
      translationsEnabled: false,
      canBuyOverage: false,
      features: [
        `Up to ${SubscriptionConfig.free.experienceLimit} projects`,
        `${SubscriptionConfig.free.monthlySessionLimit} monthly sessions`,
        'No translations',
        'No overage purchase'
      ]
    },
    premium: {
      name: 'Premium',
      price: SubscriptionConfig.premium.monthlyFeeUsd,
      experienceLimit: SubscriptionConfig.premium.experienceLimit,
      monthlyBudgetUsd: SubscriptionConfig.premium.monthlyBudgetUsd,
      sessionCosts: {
        aiEnabled: SubscriptionConfig.premium.aiEnabledSessionCostUsd,
        aiDisabled: SubscriptionConfig.premium.aiDisabledSessionCostUsd,
      },
      defaultSessions: {
        aiEnabled: SubscriptionConfig.premium.defaultAiEnabledSessions,
        aiDisabled: SubscriptionConfig.premium.defaultAiDisabledSessions,
      },
      overage: {
        creditsPerBatch: SubscriptionConfig.overage.creditsPerBatch,
        aiEnabledSessionsPerBatch: SubscriptionConfig.overage.aiEnabledSessionsPerBatch,
        aiDisabledSessionsPerBatch: SubscriptionConfig.overage.aiDisabledSessionsPerBatch,
      },
      translationsEnabled: true,
      canBuyOverage: true,
      features: [
        `Up to ${SubscriptionConfig.premium.experienceLimit} projects`,
        `$${SubscriptionConfig.premium.monthlyBudgetUsd} monthly session budget`,
        `AI projects: $${SubscriptionConfig.premium.aiEnabledSessionCostUsd}/session (${SubscriptionConfig.premium.defaultAiEnabledSessions} included)`,
        `Non-AI projects: $${SubscriptionConfig.premium.aiDisabledSessionCostUsd}/session (${SubscriptionConfig.premium.defaultAiDisabledSessions} included)`,
        `Auto top-up: $${SubscriptionConfig.overage.creditsPerBatch} = ${SubscriptionConfig.overage.aiEnabledSessionsPerBatch} AI sessions`,
        'Multi-language translations'
      ]
    }
  };
}

export default SubscriptionConfig;
