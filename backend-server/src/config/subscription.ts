/**
 * Subscription Configuration
 * Centralized business parameters for the subscription system
 * All values can be overridden via environment variables
 */

export const SubscriptionConfig = {
  // Free tier limits
  free: {
    experienceLimit: parseInt(process.env.FREE_TIER_EXPERIENCE_LIMIT || '3'),
    monthlyAccessLimit: parseInt(process.env.FREE_TIER_MONTHLY_ACCESS_LIMIT || '50'),
    translationsEnabled: false,
  },
  
  // Premium tier limits and pricing
  premium: {
    monthlyFeeUsd: parseFloat(process.env.PREMIUM_MONTHLY_FEE_USD || '50'),
    monthlyAccessLimit: parseInt(process.env.PREMIUM_MONTHLY_ACCESS_LIMIT || '3000'),
    experienceLimit: parseInt(process.env.PREMIUM_EXPERIENCE_LIMIT || '15'),
    translationsEnabled: true,
  },
  
  // Overage batch configuration
  // When premium users exceed their limit, they can buy batches of additional access
  overage: {
    creditsPerBatch: parseInt(process.env.OVERAGE_CREDITS_PER_BATCH || '5'),     // Credits charged
    accessPerBatch: parseInt(process.env.OVERAGE_ACCESS_PER_BATCH || '100'),     // Access granted
  },
  
  // Stripe configuration
  stripe: {
    premiumPriceId: process.env.STRIPE_PREMIUM_PRICE_ID || '',
  }
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
 * Get all pricing info for frontend display
 */
export function getPricingInfo() {
  return {
    free: {
      name: 'Free',
      price: 0,
      experienceLimit: SubscriptionConfig.free.experienceLimit,
      monthlyAccessLimit: SubscriptionConfig.free.monthlyAccessLimit,
      translationsEnabled: false,
      canBuyOverage: false,
      features: [
        `Up to ${SubscriptionConfig.free.experienceLimit} experiences`,
        `${SubscriptionConfig.free.monthlyAccessLimit} monthly access`,
        'No translations',
        'No overage purchase'
      ]
    },
    premium: {
      name: 'Premium',
      price: SubscriptionConfig.premium.monthlyFeeUsd,
      experienceLimit: SubscriptionConfig.premium.experienceLimit,
      monthlyAccessLimit: SubscriptionConfig.premium.monthlyAccessLimit,
      overage: {
        creditsPerBatch: SubscriptionConfig.overage.creditsPerBatch,
        accessPerBatch: SubscriptionConfig.overage.accessPerBatch,
        costPerAccess: SubscriptionConfig.overage.creditsPerBatch / SubscriptionConfig.overage.accessPerBatch,
      },
      translationsEnabled: true,
      canBuyOverage: true,
      features: [
        `Up to ${SubscriptionConfig.premium.experienceLimit} experiences`,
        `${SubscriptionConfig.premium.monthlyAccessLimit.toLocaleString()} monthly access`,
        `${SubscriptionConfig.overage.creditsPerBatch} credits per ${SubscriptionConfig.overage.accessPerBatch} extra access`,
        'Multi-language translations'
      ]
    }
  };
}

export default SubscriptionConfig;

