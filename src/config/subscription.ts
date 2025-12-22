/**
 * Subscription Configuration
 * Centralized business parameters for the subscription system
 * Values are loaded from environment variables with defaults
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
  // Free tier limits (limited for trial)
  free: {
    experienceLimit: parseInt(import.meta.env.VITE_FREE_TIER_EXPERIENCE_LIMIT || '3'),
    monthlySessionLimit: parseInt(import.meta.env.VITE_FREE_TIER_MONTHLY_SESSION_LIMIT || '50'),
    translationsEnabled: false,
  },
  
  // Premium tier limits and pricing
  premium: {
    // Monthly subscription fee
    monthlyFeeUsd: parseFloat(import.meta.env.VITE_PREMIUM_MONTHLY_FEE_USD || '30'),
    experienceLimit: parseInt(import.meta.env.VITE_PREMIUM_EXPERIENCE_LIMIT || '15'),
    translationsEnabled: true,
    
    // Session-based pricing (per user session)
    aiEnabledSessionCostUsd: parseFloat(import.meta.env.VITE_AI_ENABLED_SESSION_COST_USD || '0.05'),
    aiDisabledSessionCostUsd: parseFloat(import.meta.env.VITE_AI_DISABLED_SESSION_COST_USD || '0.025'),
    
    // Monthly budget included with subscription
    monthlyBudgetUsd: parseFloat(import.meta.env.VITE_PREMIUM_MONTHLY_BUDGET_USD || '30'),
  },
  
  // Overage/Top-up configuration
  overage: {
    creditsPerBatch: parseInt(import.meta.env.VITE_OVERAGE_CREDITS_PER_BATCH || '5'),
  },
  
  // Calculated values (for backward compatibility and display)
  get calculated() {
    const aiEnabledSessions = Math.floor(this.premium.monthlyBudgetUsd / this.premium.aiEnabledSessionCostUsd);
    const aiDisabledSessions = Math.floor(this.premium.monthlyBudgetUsd / this.premium.aiDisabledSessionCostUsd);
    return {
      // Default sessions included with premium subscription
      defaultAiEnabledSessions: aiEnabledSessions, // 600 @ $30/$0.05
      defaultAiDisabledSessions: aiDisabledSessions, // 1200 @ $30/$0.025
      // Sessions per overage batch
      aiEnabledSessionsPerBatch: Math.floor(this.overage.creditsPerBatch / this.premium.aiEnabledSessionCostUsd), // 100
      aiDisabledSessionsPerBatch: Math.floor(this.overage.creditsPerBatch / this.premium.aiDisabledSessionCostUsd), // 200
    };
  },
};

// Session type for display purposes
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
 * Calculate sessions from budget
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
 * Get calculated values for display
 */
function getCalculatedValues() {
  const { premium, overage } = SubscriptionConfig;
  
  return {
    defaultAiEnabledSessions: Math.floor(premium.monthlyBudgetUsd / premium.aiEnabledSessionCostUsd), // 600
    defaultAiDisabledSessions: Math.floor(premium.monthlyBudgetUsd / premium.aiDisabledSessionCostUsd), // 1200
    aiEnabledSessionsPerBatch: Math.floor(overage.creditsPerBatch / premium.aiEnabledSessionCostUsd), // 100
    aiDisabledSessionsPerBatch: Math.floor(overage.creditsPerBatch / premium.aiDisabledSessionCostUsd), // 200
  };
}

/**
 * Get subscription tier details
 */
export function getTierDetails(tier: 'free' | 'premium') {
  const calc = getCalculatedValues();
  
  if (tier === 'premium') {
    return {
      tier: 'premium',
      experienceLimit: SubscriptionConfig.premium.experienceLimit,
      monthlyBudgetUsd: SubscriptionConfig.premium.monthlyBudgetUsd,
      aiEnabledSessionCost: SubscriptionConfig.premium.aiEnabledSessionCostUsd,
      aiDisabledSessionCost: SubscriptionConfig.premium.aiDisabledSessionCostUsd,
      defaultAiEnabledSessions: calc.defaultAiEnabledSessions,
      defaultAiDisabledSessions: calc.defaultAiDisabledSessions,
      translationsEnabled: SubscriptionConfig.premium.translationsEnabled,
      monthlyFeeUsd: SubscriptionConfig.premium.monthlyFeeUsd,
      overage: {
        creditsPerBatch: SubscriptionConfig.overage.creditsPerBatch,
        aiEnabledSessionsPerBatch: calc.aiEnabledSessionsPerBatch,
        aiDisabledSessionsPerBatch: calc.aiDisabledSessionsPerBatch,
      },
    };
  }
  
  return {
    tier: 'free',
    experienceLimit: SubscriptionConfig.free.experienceLimit,
    monthlySessionLimit: SubscriptionConfig.free.monthlySessionLimit,
    translationsEnabled: SubscriptionConfig.free.translationsEnabled,
    monthlyFeeUsd: 0,
    overage: null,
  };
}

/**
 * Get formatted pricing info for display
 */
export function getPricingDisplay() {
  const calc = getCalculatedValues();
  const { free, premium, overage } = SubscriptionConfig;
  
  return {
    free: {
      name: 'Free',
      price: '$0',
      priceSubtext: 'forever',
      features: [
        `Up to ${free.experienceLimit} projects`,
        `${free.monthlySessionLimit} monthly sessions`,
        'No multi-language translations',
        'No overage purchase'
      ],
      limitations: [
        'Limited projects',
        'Limited monthly sessions',
        'No translations'
      ]
    },
    premium: {
      name: 'Premium',
      price: `$${premium.monthlyFeeUsd}`,
      priceSubtext: '/month',
      features: [
        `Up to ${premium.experienceLimit} projects`,
        `$${premium.monthlyBudgetUsd} monthly session budget`,
        `AI projects: ${calc.defaultAiEnabledSessions} sessions included`,
        `Non-AI projects: ${calc.defaultAiDisabledSessions} sessions included`,
        `Auto top-up: $${overage.creditsPerBatch} for extra sessions`,
        'Multi-language translations'
      ],
      highlights: [
        'Best for growing businesses',
        'Pay-per-session model',
        'Automatic top-up when needed',
        'Full translation support'
      ],
      sessionCosts: {
        aiEnabled: premium.aiEnabledSessionCostUsd,
        aiDisabled: premium.aiDisabledSessionCostUsd,
      },
      overage: {
        creditsPerBatch: overage.creditsPerBatch,
        aiEnabledSessionsPerBatch: calc.aiEnabledSessionsPerBatch,
        aiDisabledSessionsPerBatch: calc.aiDisabledSessionsPerBatch,
      }
    }
  };
}

export default SubscriptionConfig;
