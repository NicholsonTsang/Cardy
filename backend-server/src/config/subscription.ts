/**
 * Subscription Configuration
 * Centralized business parameters for the subscription system
 * All values can be overridden via environment variables
 * 
 * THREE-TIER PRICING MODEL (Session-Based):
 * 
 * FREE:
 * - 3 projects, 50 sessions/month, no translations
 * 
 * STARTER ($40/month):
 * - 5 projects, $40 session budget
 * - AI sessions: $0.05 (~800 included), Non-AI: $0.025 (~1600 included)
 * - Max 2 translation languages
 * - "Powered by FunTell" branding
 * 
 * PREMIUM ($280/month):
 * - 35 projects, $280 session budget
 * - AI sessions: $0.04 (~7000 included), Non-AI: $0.02 (~14000 included)
 * - Unlimited translation languages
 * - White label (no branding)
 * 
 * Auto top-up: $5 credit when budget runs out
 */

export const SubscriptionConfig = {
  // Free tier limits (no access to premium features, limited for trial)
  free: {
    experienceLimit: parseInt(process.env.FREE_TIER_EXPERIENCE_LIMIT || '3'),
    // Free tier: limited sessions for trial purposes
    monthlySessionLimit: parseInt(process.env.FREE_TIER_MONTHLY_SESSION_LIMIT || '50'),
    translationsEnabled: false,
  },
  
  // Starter tier limits and pricing
  starter: {
    monthlyFeeUsd: parseFloat(process.env.STARTER_MONTHLY_FEE_USD || '40'),
    experienceLimit: parseInt(process.env.STARTER_EXPERIENCE_LIMIT || '5'),
    translationsEnabled: true,
    maxLanguages: 2, // Max 2 languages based on user select
    
    // Session-based pricing
    aiEnabledSessionCostUsd: parseFloat(process.env.STARTER_AI_ENABLED_SESSION_COST_USD || '0.05'),
    aiDisabledSessionCostUsd: parseFloat(process.env.STARTER_AI_DISABLED_SESSION_COST_USD || '0.025'),
    
    monthlyBudgetUsd: parseFloat(process.env.STARTER_MONTHLY_BUDGET_USD || '40'),
    
    get defaultAiEnabledSessions() {
      return Math.floor(this.monthlyBudgetUsd / this.aiEnabledSessionCostUsd);
    },
    get defaultAiDisabledSessions() {
      return Math.floor(this.monthlyBudgetUsd / this.aiDisabledSessionCostUsd);
    },
  },

  // Premium tier limits and pricing
  premium: {
    // Monthly subscription fee
    monthlyFeeUsd: parseFloat(process.env.PREMIUM_MONTHLY_FEE_USD || '280'),
    experienceLimit: parseInt(process.env.PREMIUM_EXPERIENCE_LIMIT || '35'),
    translationsEnabled: true,
    maxLanguages: -1, // Unlimited
    
    // Session-based pricing (per user session)
    aiEnabledSessionCostUsd: parseFloat(process.env.PREMIUM_AI_ENABLED_SESSION_COST_USD || '0.04'),
    aiDisabledSessionCostUsd: parseFloat(process.env.PREMIUM_AI_DISABLED_SESSION_COST_USD || '0.02'),
    
    // Monthly session allowance included with subscription
    monthlyBudgetUsd: parseFloat(process.env.PREMIUM_MONTHLY_BUDGET_USD || '280'),
    
    // Calculated default limits (for backward compatibility)
    get defaultAiEnabledSessions() {
      return Math.floor(this.monthlyBudgetUsd / this.aiEnabledSessionCostUsd);
    },
    get defaultAiDisabledSessions() {
      return Math.floor(this.monthlyBudgetUsd / this.aiDisabledSessionCostUsd);
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
    // Fixed at 30 minutes to balance visitor experience and platform revenue
    dedupWindowSeconds: parseInt(process.env.SESSION_DEDUP_WINDOW_SECONDS || '1800'),
  },
  
  // Stripe configuration
  stripe: {
    starterPriceId: process.env.STRIPE_STARTER_PRICE_ID || '',
    premiumPriceId: process.env.STRIPE_PREMIUM_PRICE_ID || '',
    creditPriceId: process.env.STRIPE_CREDIT_PRICE_ID || '',
  }
};

// Session cost types for billing
export type SessionType = 'ai_enabled' | 'ai_disabled';

/**
 * Get session cost based on AI enabled status and tier
 */
export function getSessionCost(isAiEnabled: boolean, tier: 'free' | 'starter' | 'premium' = 'premium'): number {
  if (tier === 'starter') {
    return isAiEnabled 
      ? SubscriptionConfig.starter.aiEnabledSessionCostUsd 
      : SubscriptionConfig.starter.aiDisabledSessionCostUsd;
  }
  // Premium (default)
  return isAiEnabled 
    ? SubscriptionConfig.premium.aiEnabledSessionCostUsd 
    : SubscriptionConfig.premium.aiDisabledSessionCostUsd;
}

/**
 * Calculate sessions remaining from budget
 */
export function calculateSessionsFromBudget(budgetUsd: number, isAiEnabled: boolean, tier: 'free' | 'starter' | 'premium' = 'premium'): number {
  const costPerSession = getSessionCost(isAiEnabled, tier);
  return Math.floor(budgetUsd / costPerSession);
}

/**
 * Calculate budget consumed from sessions
 */
export function calculateBudgetFromSessions(sessions: number, isAiEnabled: boolean, tier: 'free' | 'starter' | 'premium' = 'premium'): number {
  const costPerSession = getSessionCost(isAiEnabled, tier);
  return sessions * costPerSession;
}

/**
 * Get subscription tier details
 */
export function getTierDetails(tier: 'free' | 'starter' | 'premium') {
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
      maxLanguages: SubscriptionConfig.premium.maxLanguages,
      monthlyFeeUsd: SubscriptionConfig.premium.monthlyFeeUsd,
      overage: {
        creditsPerBatch: SubscriptionConfig.overage.creditsPerBatch,
        aiEnabledSessionsPerBatch: SubscriptionConfig.overage.aiEnabledSessionsPerBatch,
        aiDisabledSessionsPerBatch: SubscriptionConfig.overage.aiDisabledSessionsPerBatch,
      },
    };
  }
  
  if (tier === 'starter') {
    return {
      tier: 'starter',
      experienceLimit: SubscriptionConfig.starter.experienceLimit,
      monthlyBudgetUsd: SubscriptionConfig.starter.monthlyBudgetUsd,
      aiEnabledSessionCost: SubscriptionConfig.starter.aiEnabledSessionCostUsd,
      aiDisabledSessionCost: SubscriptionConfig.starter.aiDisabledSessionCostUsd,
      defaultAiEnabledSessions: SubscriptionConfig.starter.defaultAiEnabledSessions,
      defaultAiDisabledSessions: SubscriptionConfig.starter.defaultAiDisabledSessions,
      translationsEnabled: SubscriptionConfig.starter.translationsEnabled,
      maxLanguages: SubscriptionConfig.starter.maxLanguages,
      monthlyFeeUsd: SubscriptionConfig.starter.monthlyFeeUsd,
      overage: {
        creditsPerBatch: SubscriptionConfig.overage.creditsPerBatch,
        aiEnabledSessionsPerBatch: Math.floor(SubscriptionConfig.overage.creditsPerBatch / SubscriptionConfig.starter.aiEnabledSessionCostUsd),
        aiDisabledSessionsPerBatch: Math.floor(SubscriptionConfig.overage.creditsPerBatch / SubscriptionConfig.starter.aiDisabledSessionCostUsd),
      },
    };
  }
  
  return {
    tier: 'free',
    experienceLimit: SubscriptionConfig.free.experienceLimit,
    monthlySessionLimit: SubscriptionConfig.free.monthlySessionLimit,
    translationsEnabled: SubscriptionConfig.free.translationsEnabled,
    maxLanguages: 0,
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
    starter: {
      name: 'Starter',
      price: SubscriptionConfig.starter.monthlyFeeUsd,
      experienceLimit: SubscriptionConfig.starter.experienceLimit,
      monthlyBudgetUsd: SubscriptionConfig.starter.monthlyBudgetUsd,
      sessionCosts: {
        aiEnabled: SubscriptionConfig.starter.aiEnabledSessionCostUsd,
        aiDisabled: SubscriptionConfig.starter.aiDisabledSessionCostUsd,
      },
      defaultSessions: {
        aiEnabled: SubscriptionConfig.starter.defaultAiEnabledSessions,
        aiDisabled: SubscriptionConfig.starter.defaultAiDisabledSessions,
      },
      overage: {
        creditsPerBatch: SubscriptionConfig.overage.creditsPerBatch,
        aiEnabledSessionsPerBatch: Math.floor(SubscriptionConfig.overage.creditsPerBatch / SubscriptionConfig.starter.aiEnabledSessionCostUsd),
        aiDisabledSessionsPerBatch: Math.floor(SubscriptionConfig.overage.creditsPerBatch / SubscriptionConfig.starter.aiDisabledSessionCostUsd),
      },
      translationsEnabled: true,
      maxLanguages: SubscriptionConfig.starter.maxLanguages,
      canBuyOverage: true,
      features: [
        `Up to ${SubscriptionConfig.starter.experienceLimit} projects`,
        `$${SubscriptionConfig.starter.monthlyBudgetUsd} monthly session budget`,
        `AI projects: $${SubscriptionConfig.starter.aiEnabledSessionCostUsd}/session (${SubscriptionConfig.starter.defaultAiEnabledSessions} included)`,
        `Non-AI projects: $${SubscriptionConfig.starter.aiDisabledSessionCostUsd}/session (${SubscriptionConfig.starter.defaultAiDisabledSessions} included)`,
        `Max ${SubscriptionConfig.starter.maxLanguages} languages`,
        'Powered by FunTell branding'
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
      maxLanguages: -1,
      canBuyOverage: true,
      features: [
        `Up to ${SubscriptionConfig.premium.experienceLimit} projects`,
        `$${SubscriptionConfig.premium.monthlyBudgetUsd} monthly session budget`,
        `AI projects: $${SubscriptionConfig.premium.aiEnabledSessionCostUsd}/session (${SubscriptionConfig.premium.defaultAiEnabledSessions} included)`,
        `Non-AI projects: $${SubscriptionConfig.premium.aiDisabledSessionCostUsd}/session (${SubscriptionConfig.premium.defaultAiDisabledSessions} included)`,
        `Auto top-up: $${SubscriptionConfig.overage.creditsPerBatch} = ${SubscriptionConfig.overage.aiEnabledSessionsPerBatch} AI sessions`,
        'Unlimited translations',
        'White label (No branding)'
      ]
    }
  };
}

export const VOICE_CREDIT_CONFIG = {
  PACKAGE_SIZE: parseInt(process.env.VOICE_CREDIT_PACKAGE_SIZE || '35'),
  PACKAGE_PRICE_USD: parseFloat(process.env.VOICE_CREDIT_PACKAGE_PRICE_USD || '5'),
  HARD_LIMIT_SECONDS: parseInt(process.env.VOICE_CALL_HARD_LIMIT_SECONDS || '180'),
}

export default SubscriptionConfig;
