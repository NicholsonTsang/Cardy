/**
 * Subscription Configuration
 * Centralized business parameters for the subscription system
 * Values are loaded from environment variables with defaults
 * 
 * NEW PRICING MODEL (Session-Based):
 * - Premium subscription: $280/month
 * - Starter subscription: $40/month
 * - Session costs vary by tier
 * - Auto top-up: $5 credit
 * 
 * User sessions are tracked via Cloudflare with expiration limits.
 * Redis is used for real-time session counting to reduce database load.
 */

export const SubscriptionConfig = {
  // Free tier limits (limited for trial)
  free: {
    projectLimit: parseInt(import.meta.env.VITE_FREE_TIER_PROJECT_LIMIT || '3'),
    monthlySessionLimit: parseInt(import.meta.env.VITE_FREE_TIER_MONTHLY_SESSION_LIMIT || '50'),
    translationsEnabled: false,
  },
  
  // Starter tier limits and pricing
  starter: {
    monthlyFeeUsd: parseFloat(import.meta.env.VITE_STARTER_MONTHLY_FEE_USD || '40'),
    projectLimit: parseInt(import.meta.env.VITE_STARTER_PROJECT_LIMIT || '5'),
    translationsEnabled: true,
    maxLanguages: 2,
    
    // Session-based pricing (per user session)
    aiEnabledSessionCostUsd: parseFloat(import.meta.env.VITE_STARTER_AI_ENABLED_SESSION_COST_USD || '0.05'),
    aiDisabledSessionCostUsd: parseFloat(import.meta.env.VITE_STARTER_AI_DISABLED_SESSION_COST_USD || '0.025'),
    
    // Monthly budget included with subscription
    monthlyBudgetUsd: parseFloat(import.meta.env.VITE_STARTER_MONTHLY_BUDGET_USD || '40'),
  },

  // Premium tier limits and pricing
  premium: {
    // Monthly subscription fee
    monthlyFeeUsd: parseFloat(import.meta.env.VITE_PREMIUM_MONTHLY_FEE_USD || '280'),
    projectLimit: parseInt(import.meta.env.VITE_PREMIUM_PROJECT_LIMIT || '35'),
    translationsEnabled: true,
    maxLanguages: -1, // Unlimited
    
    // Session-based pricing (per user session)
    aiEnabledSessionCostUsd: parseFloat(import.meta.env.VITE_PREMIUM_AI_ENABLED_SESSION_COST_USD || '0.04'),
    aiDisabledSessionCostUsd: parseFloat(import.meta.env.VITE_PREMIUM_AI_DISABLED_SESSION_COST_USD || '0.02'),
    
    // Monthly budget included with subscription
    monthlyBudgetUsd: parseFloat(import.meta.env.VITE_PREMIUM_MONTHLY_BUDGET_USD || '280'),
  },
  
  // Enterprise tier limits and pricing
  enterprise: {
    monthlyFeeUsd: parseFloat(import.meta.env.VITE_ENTERPRISE_MONTHLY_FEE_USD || '1000'),
    projectLimit: parseInt(import.meta.env.VITE_ENTERPRISE_PROJECT_LIMIT || '100'),
    translationsEnabled: true,
    maxLanguages: -1, // Unlimited

    // Session-based pricing (lowest rates)
    aiEnabledSessionCostUsd: parseFloat(import.meta.env.VITE_ENTERPRISE_AI_ENABLED_SESSION_COST_USD || '0.02'),
    aiDisabledSessionCostUsd: parseFloat(import.meta.env.VITE_ENTERPRISE_AI_DISABLED_SESSION_COST_USD || '0.01'),

    monthlyBudgetUsd: parseFloat(import.meta.env.VITE_ENTERPRISE_MONTHLY_BUDGET_USD || '1000'),
  },

  // Overage/Top-up configuration
  overage: {
    creditsPerBatch: parseInt(import.meta.env.VITE_OVERAGE_CREDITS_PER_BATCH || '5'),
  },
  
  // Calculated values (for backward compatibility and display)
  get calculated() {
    const aiEnabledSessions = Math.floor(this.premium.monthlyBudgetUsd / this.premium.aiEnabledSessionCostUsd);
    const aiDisabledSessions = Math.floor(this.premium.monthlyBudgetUsd / this.premium.aiDisabledSessionCostUsd);

    const starterAiEnabledSessions = Math.floor(this.starter.monthlyBudgetUsd / this.starter.aiEnabledSessionCostUsd);
    const starterAiDisabledSessions = Math.floor(this.starter.monthlyBudgetUsd / this.starter.aiDisabledSessionCostUsd);

    const enterpriseAiEnabledSessions = Math.floor(this.enterprise.monthlyBudgetUsd / this.enterprise.aiEnabledSessionCostUsd);
    const enterpriseAiDisabledSessions = Math.floor(this.enterprise.monthlyBudgetUsd / this.enterprise.aiDisabledSessionCostUsd);

    return {
      // Default sessions included with premium subscription
      defaultAiEnabledSessions: aiEnabledSessions,
      defaultAiDisabledSessions: aiDisabledSessions,
      // Sessions per overage batch (Premium)
      aiEnabledSessionsPerBatch: Math.floor(this.overage.creditsPerBatch / this.premium.aiEnabledSessionCostUsd),
      aiDisabledSessionsPerBatch: Math.floor(this.overage.creditsPerBatch / this.premium.aiDisabledSessionCostUsd),

      // Starter values
      starterDefaultAiEnabledSessions: starterAiEnabledSessions,
      starterDefaultAiDisabledSessions: starterAiDisabledSessions,
      starterAiEnabledSessionsPerBatch: Math.floor(this.overage.creditsPerBatch / this.starter.aiEnabledSessionCostUsd),
      starterAiDisabledSessionsPerBatch: Math.floor(this.overage.creditsPerBatch / this.starter.aiDisabledSessionCostUsd),

      // Enterprise values
      enterpriseDefaultAiEnabledSessions: enterpriseAiEnabledSessions,
      enterpriseDefaultAiDisabledSessions: enterpriseAiDisabledSessions,
      enterpriseAiEnabledSessionsPerBatch: Math.floor(this.overage.creditsPerBatch / this.enterprise.aiEnabledSessionCostUsd),
      enterpriseAiDisabledSessionsPerBatch: Math.floor(this.overage.creditsPerBatch / this.enterprise.aiDisabledSessionCostUsd),
    };
  },
};

// Session type for display purposes
export type SessionType = 'ai_enabled' | 'ai_disabled';

/**
 * Get session cost based on AI enabled status and tier
 */
export function getSessionCost(isAiEnabled: boolean, tier: 'free' | 'starter' | 'premium' | 'enterprise' = 'premium'): number {
  if (tier === 'starter') {
    return isAiEnabled
      ? SubscriptionConfig.starter.aiEnabledSessionCostUsd
      : SubscriptionConfig.starter.aiDisabledSessionCostUsd;
  }
  if (tier === 'enterprise') {
    return isAiEnabled
      ? SubscriptionConfig.enterprise.aiEnabledSessionCostUsd
      : SubscriptionConfig.enterprise.aiDisabledSessionCostUsd;
  }
  return isAiEnabled
    ? SubscriptionConfig.premium.aiEnabledSessionCostUsd
    : SubscriptionConfig.premium.aiDisabledSessionCostUsd;
}

/**
 * Calculate sessions from budget
 */
export function calculateSessionsFromBudget(budgetUsd: number, isAiEnabled: boolean, tier: 'free' | 'starter' | 'premium' | 'enterprise' = 'premium'): number {
  const costPerSession = getSessionCost(isAiEnabled, tier);
  return Math.floor(budgetUsd / costPerSession);
}

/**
 * Calculate budget consumed from sessions
 */
export function calculateBudgetFromSessions(sessions: number, isAiEnabled: boolean, tier: 'free' | 'starter' | 'premium' | 'enterprise' = 'premium'): number {
  const costPerSession = getSessionCost(isAiEnabled, tier);
  return sessions * costPerSession;
}

/**
 * Get calculated values for display
 */
function getCalculatedValues() {
  const { starter, premium, enterprise, overage } = SubscriptionConfig;

  return {
    // Premium
    premiumAiEnabledSessions: Math.floor(premium.monthlyBudgetUsd / premium.aiEnabledSessionCostUsd),
    premiumAiDisabledSessions: Math.floor(premium.monthlyBudgetUsd / premium.aiDisabledSessionCostUsd),
    premiumAiEnabledSessionsPerBatch: Math.floor(overage.creditsPerBatch / premium.aiEnabledSessionCostUsd),
    premiumAiDisabledSessionsPerBatch: Math.floor(overage.creditsPerBatch / premium.aiDisabledSessionCostUsd),

    // Starter
    starterAiEnabledSessions: Math.floor(starter.monthlyBudgetUsd / starter.aiEnabledSessionCostUsd),
    starterAiDisabledSessions: Math.floor(starter.monthlyBudgetUsd / starter.aiDisabledSessionCostUsd),
    starterAiEnabledSessionsPerBatch: Math.floor(overage.creditsPerBatch / starter.aiEnabledSessionCostUsd),
    starterAiDisabledSessionsPerBatch: Math.floor(overage.creditsPerBatch / starter.aiDisabledSessionCostUsd),

    // Enterprise
    enterpriseAiEnabledSessions: Math.floor(enterprise.monthlyBudgetUsd / enterprise.aiEnabledSessionCostUsd),
    enterpriseAiDisabledSessions: Math.floor(enterprise.monthlyBudgetUsd / enterprise.aiDisabledSessionCostUsd),
    enterpriseAiEnabledSessionsPerBatch: Math.floor(overage.creditsPerBatch / enterprise.aiEnabledSessionCostUsd),
    enterpriseAiDisabledSessionsPerBatch: Math.floor(overage.creditsPerBatch / enterprise.aiDisabledSessionCostUsd),
  };
}

/**
 * Get subscription tier details
 */
export function getTierDetails(tier: 'free' | 'starter' | 'premium' | 'enterprise') {
  const calc = getCalculatedValues();

  if (tier === 'enterprise') {
    return {
      tier: 'enterprise',
      projectLimit: SubscriptionConfig.enterprise.projectLimit,
      monthlyBudgetUsd: SubscriptionConfig.enterprise.monthlyBudgetUsd,
      aiEnabledSessionCost: SubscriptionConfig.enterprise.aiEnabledSessionCostUsd,
      aiDisabledSessionCost: SubscriptionConfig.enterprise.aiDisabledSessionCostUsd,
      defaultAiEnabledSessions: calc.enterpriseAiEnabledSessions,
      defaultAiDisabledSessions: calc.enterpriseAiDisabledSessions,
      translationsEnabled: SubscriptionConfig.enterprise.translationsEnabled,
      maxLanguages: SubscriptionConfig.enterprise.maxLanguages,
      monthlyFeeUsd: SubscriptionConfig.enterprise.monthlyFeeUsd,
      overage: {
        creditsPerBatch: SubscriptionConfig.overage.creditsPerBatch,
        aiEnabledSessionsPerBatch: calc.enterpriseAiEnabledSessionsPerBatch,
        aiDisabledSessionsPerBatch: calc.enterpriseAiDisabledSessionsPerBatch,
      },
    };
  }

  if (tier === 'premium') {
    return {
      tier: 'premium',
      projectLimit: SubscriptionConfig.premium.projectLimit,
      monthlyBudgetUsd: SubscriptionConfig.premium.monthlyBudgetUsd,
      aiEnabledSessionCost: SubscriptionConfig.premium.aiEnabledSessionCostUsd,
      aiDisabledSessionCost: SubscriptionConfig.premium.aiDisabledSessionCostUsd,
      defaultAiEnabledSessions: calc.premiumAiEnabledSessions,
      defaultAiDisabledSessions: calc.premiumAiDisabledSessions,
      translationsEnabled: SubscriptionConfig.premium.translationsEnabled,
      maxLanguages: SubscriptionConfig.premium.maxLanguages,
      monthlyFeeUsd: SubscriptionConfig.premium.monthlyFeeUsd,
      overage: {
        creditsPerBatch: SubscriptionConfig.overage.creditsPerBatch,
        aiEnabledSessionsPerBatch: calc.premiumAiEnabledSessionsPerBatch,
        aiDisabledSessionsPerBatch: calc.premiumAiDisabledSessionsPerBatch,
      },
    };
  }

  if (tier === 'starter') {
    return {
      tier: 'starter',
      projectLimit: SubscriptionConfig.starter.projectLimit,
      monthlyBudgetUsd: SubscriptionConfig.starter.monthlyBudgetUsd,
      aiEnabledSessionCost: SubscriptionConfig.starter.aiEnabledSessionCostUsd,
      aiDisabledSessionCost: SubscriptionConfig.starter.aiDisabledSessionCostUsd,
      defaultAiEnabledSessions: calc.starterAiEnabledSessions,
      defaultAiDisabledSessions: calc.starterAiDisabledSessions,
      translationsEnabled: SubscriptionConfig.starter.translationsEnabled,
      maxLanguages: SubscriptionConfig.starter.maxLanguages,
      monthlyFeeUsd: SubscriptionConfig.starter.monthlyFeeUsd,
      overage: {
        creditsPerBatch: SubscriptionConfig.overage.creditsPerBatch,
        aiEnabledSessionsPerBatch: calc.starterAiEnabledSessionsPerBatch,
        aiDisabledSessionsPerBatch: calc.starterAiDisabledSessionsPerBatch,
      },
    };
  }
  
  return {
    tier: 'free',
    projectLimit: SubscriptionConfig.free.projectLimit,
    monthlySessionLimit: SubscriptionConfig.free.monthlySessionLimit,
    translationsEnabled: SubscriptionConfig.free.translationsEnabled,
    maxLanguages: 0,
    monthlyFeeUsd: 0,
    overage: null,
  };
}

/**
 * Get formatted pricing info for display
 */
export function getPricingDisplay() {
  const calc = getCalculatedValues();
  const { free, starter, premium, enterprise, overage } = SubscriptionConfig;

  return {
    free: {
      name: 'Free',
      price: '$0',
      priceSubtext: 'forever',
      features: [
        `Up to ${free.projectLimit} projects`,
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
    starter: {
      name: 'Starter',
      price: `$${starter.monthlyFeeUsd}`,
      priceSubtext: '/month',
      features: [
        `Up to ${starter.projectLimit} projects`,
        `$${starter.monthlyBudgetUsd} monthly session budget`,
        `AI projects: ${calc.starterAiEnabledSessions} sessions included`,
        `Non-AI projects: ${calc.starterAiDisabledSessions} sessions included`,
        `Max ${starter.maxLanguages} languages`,
        'Powered by FunTell branding'
      ],
      highlights: [
        'Great for getting started',
        'Pay-per-session model',
        'Automatic top-up when needed',
        'Translation support'
      ],
      sessionCosts: {
        aiEnabled: starter.aiEnabledSessionCostUsd,
        aiDisabled: starter.aiDisabledSessionCostUsd,
      },
      overage: {
        creditsPerBatch: overage.creditsPerBatch,
        aiEnabledSessionsPerBatch: calc.starterAiEnabledSessionsPerBatch,
        aiDisabledSessionsPerBatch: calc.starterAiDisabledSessionsPerBatch,
      }
    },
    premium: {
      name: 'Premium',
      price: `$${premium.monthlyFeeUsd}`,
      priceSubtext: '/month',
      features: [
        `Up to ${premium.projectLimit} projects`,
        `$${premium.monthlyBudgetUsd} monthly session budget`,
        `AI projects: ${calc.premiumAiEnabledSessions} sessions included`,
        `Non-AI projects: ${calc.premiumAiDisabledSessions} sessions included`,
        `Unlimited languages`,
        'White label (No branding)'
      ],
      highlights: [
        'Best for growing businesses',
        'Cheaper session rates',
        'Automatic top-up when needed',
        'Full white label'
      ],
      sessionCosts: {
        aiEnabled: premium.aiEnabledSessionCostUsd,
        aiDisabled: premium.aiDisabledSessionCostUsd,
      },
      overage: {
        creditsPerBatch: overage.creditsPerBatch,
        aiEnabledSessionsPerBatch: calc.premiumAiEnabledSessionsPerBatch,
        aiDisabledSessionsPerBatch: calc.premiumAiDisabledSessionsPerBatch,
      }
    },
    enterprise: {
      name: 'Enterprise',
      price: `$${enterprise.monthlyFeeUsd}`,
      priceSubtext: '/month',
      features: [
        `Up to ${enterprise.projectLimit} projects`,
        `$${enterprise.monthlyBudgetUsd} monthly session budget`,
        `AI projects: ${calc.enterpriseAiEnabledSessions} sessions included`,
        `Non-AI projects: ${calc.enterpriseAiDisabledSessions} sessions included`,
        'Unlimited languages',
        'White label (No branding)',
        'Custom domain (Coming soon)'
      ],
      highlights: [
        'Best for high-volume operations',
        'Lowest session rates',
        'Automatic top-up when needed',
        'Full white label',
        'Custom domain (Coming soon)'
      ],
      sessionCosts: {
        aiEnabled: enterprise.aiEnabledSessionCostUsd,
        aiDisabled: enterprise.aiDisabledSessionCostUsd,
      },
      overage: {
        creditsPerBatch: overage.creditsPerBatch,
        aiEnabledSessionsPerBatch: calc.enterpriseAiEnabledSessionsPerBatch,
        aiDisabledSessionsPerBatch: calc.enterpriseAiDisabledSessionsPerBatch,
      }
    }
  };
}

export default SubscriptionConfig;