/**
 * Subscription Configuration
 * Centralized business parameters for the subscription system
 * Values are loaded from environment variables with defaults
 */

export const SubscriptionConfig = {
  // Free tier limits
  free: {
    experienceLimit: parseInt(import.meta.env.VITE_FREE_TIER_EXPERIENCE_LIMIT || '3'),
    monthlyAccessLimit: parseInt(import.meta.env.VITE_FREE_TIER_MONTHLY_ACCESS_LIMIT || '50'),
    translationsEnabled: false,
  },
  
  // Premium tier limits and pricing
  premium: {
    monthlyFeeUsd: parseFloat(import.meta.env.VITE_PREMIUM_MONTHLY_FEE_USD || '50'),
    monthlyAccessLimit: parseInt(import.meta.env.VITE_PREMIUM_MONTHLY_ACCESS_LIMIT || '3000'),
    experienceLimit: parseInt(import.meta.env.VITE_PREMIUM_EXPERIENCE_LIMIT || '15'),
    translationsEnabled: true,
  },
  
  // Overage batch pricing (Premium users only)
  // When premium users exceed their limit, they can purchase additional access in batches
  overage: {
    creditsPerBatch: parseInt(import.meta.env.VITE_OVERAGE_CREDITS_PER_BATCH || '5'),
    accessPerBatch: parseInt(import.meta.env.VITE_OVERAGE_ACCESS_PER_BATCH || '100'),
  },
};

/**
 * Get subscription tier details
 */
export function getTierDetails(tier: 'free' | 'premium') {
  if (tier === 'premium') {
    return {
      tier: 'premium',
      experienceLimit: SubscriptionConfig.premium.experienceLimit,
      monthlyAccessLimit: SubscriptionConfig.premium.monthlyAccessLimit,
      translationsEnabled: SubscriptionConfig.premium.translationsEnabled,
      monthlyFeeUsd: SubscriptionConfig.premium.monthlyFeeUsd,
      overage: {
        creditsPerBatch: SubscriptionConfig.overage.creditsPerBatch,
        accessPerBatch: SubscriptionConfig.overage.accessPerBatch,
      },
    };
  }
  
  return {
    tier: 'free',
    experienceLimit: SubscriptionConfig.free.experienceLimit,
    monthlyAccessLimit: SubscriptionConfig.free.monthlyAccessLimit,
    translationsEnabled: SubscriptionConfig.free.translationsEnabled,
    monthlyFeeUsd: 0,
    overage: null, // Free tier cannot buy overage
  };
}

/**
 * Get formatted pricing info for display
 */
export function getPricingDisplay() {
  const costPerAccess = SubscriptionConfig.overage.creditsPerBatch / SubscriptionConfig.overage.accessPerBatch;
  
  return {
    free: {
      name: 'Free',
      price: '$0',
      priceSubtext: 'forever',
      features: [
        `Up to ${SubscriptionConfig.free.experienceLimit} projects`,
        `${SubscriptionConfig.free.monthlyAccessLimit} monthly visits`,
        'No multi-language translations',
        'No overage purchase'
      ],
      limitations: [
        'Limited experiences',
        'Limited monthly access',
        'No translations'
      ]
    },
    premium: {
      name: 'Premium',
      price: `$${SubscriptionConfig.premium.monthlyFeeUsd}`,
      priceSubtext: '/month',
      features: [
        `Up to ${SubscriptionConfig.premium.experienceLimit} projects`,
        `${SubscriptionConfig.premium.monthlyAccessLimit.toLocaleString()} monthly visits`,
        `${SubscriptionConfig.overage.creditsPerBatch} credits per ${SubscriptionConfig.overage.accessPerBatch} extra visits`,
        'Multi-language translations'
      ],
      highlights: [
        'Best for growing businesses',
        'Pooled monthly access',
        'Buy extra access in batches',
        'Full translation support'
      ],
      overage: {
        creditsPerBatch: SubscriptionConfig.overage.creditsPerBatch,
        accessPerBatch: SubscriptionConfig.overage.accessPerBatch,
        costPerAccess: costPerAccess,
      }
    }
  };
}

export default SubscriptionConfig;

