/**
 * Subscription Store
 * Manages user subscription state and interactions with the subscription API
 */

import { defineStore } from 'pinia';
import { ref, computed } from 'vue';
import { useAuthStore } from './auth';
import { SubscriptionConfig, getTierDetails } from '@/config/subscription';

// Types
export interface SubscriptionFeatures {
  translations_enabled: boolean;
  can_buy_overage: boolean;
}

export interface SubscriptionPricing {
  monthly_fee_usd: number;
  monthly_access_limit: number;
  overage_rate_usd: number | null;
}

export interface SubscriptionDetails {
  tier: 'free' | 'starter' | 'premium';
  status: string;
  is_premium: boolean;
  
  // Stripe info
  stripe_subscription_id: string | null;
  current_period_start: string | null;
  current_period_end: string | null;
  cancel_at_period_end: boolean;
  scheduled_tier: 'free' | 'starter' | 'premium' | null;  // Tier to switch to after period ends (for downgrades)
  
  // Usage
  monthly_access_limit: number | null;
  monthly_access_used: number;
  monthly_access_remaining: number | null;
  
  // Experience limits
  experience_count: number;
  experience_limit: number | null;
  
  // Features
  features: SubscriptionFeatures;
  
  // Pricing
  pricing: SubscriptionPricing;
}

export interface UsageStats {
  tier: string;
  is_premium: boolean;
  experience_count: number;
  experience_limit: number | null;
  can_create_experience: boolean;
  monthly_access_used: number;
  monthly_access_limit: number | null;
  monthly_access_remaining: number | null;
  overage_rate: number;
  monthly_fee: number;
  current_period_start: string | null;
  current_period_end: string | null;
  features: SubscriptionFeatures;
  recent_access: any[];
}

export interface DailyAccessData {
  date: string;
  total: number;
  overage: number;
  included: number;
  // AI session breakdown (same card can have AI enabled/disabled at different times)
  ai_sessions: number;
  non_ai_sessions: number;
  ai_cost_usd: number;
  non_ai_cost_usd: number;
}

export interface DailyStats {
  period: {
    start: string;
    end: string;
    days: number;
  };
  data: DailyAccessData[];
  summary: {
    total_access: number;
    total_overage: number;
    total_included: number;
    average_daily: number;
    peak_day: string | null;
    peak_count: number;
    // AI session breakdown
    ai_sessions: number;
    non_ai_sessions: number;
    ai_cost_usd: number;
    non_ai_cost_usd: number;
    total_cost_usd: number;
  };
}

export const useSubscriptionStore = defineStore('subscription', () => {
  const authStore = useAuthStore();
  
  // State
  const subscription = ref<SubscriptionDetails | null>(null);
  const usage = ref<UsageStats | null>(null);
  const dailyStats = ref<DailyStats | null>(null);
  const loading = ref(false);       // Data fetching (subscription, usage, daily stats)
  const actionLoading = ref(false); // User-triggered actions (checkout, cancel, reactivate, portal, buy)
  const error = ref<string | null>(null);
  
  // Computed
  const tier = computed(() => subscription.value?.tier ?? 'free');
  const isPaid = computed(() => tier.value === 'starter' || tier.value === 'premium');
  const isStarter = computed(() => tier.value === 'starter');
  const isPremium = computed(() => tier.value === 'premium');
  
  const canTranslate = computed(() => subscription.value?.features?.translations_enabled ?? false);
  const canCreateExperience = computed(() => {
    if (!subscription.value) return true; // Allow by default if not loaded
    const limit = subscription.value.experience_limit ?? 
      (tier.value === 'premium' ? SubscriptionConfig.premium.experienceLimit : 
       tier.value === 'starter' ? SubscriptionConfig.starter.experienceLimit : 
       SubscriptionConfig.free.experienceLimit);
    return (subscription.value.experience_count ?? 0) < limit;
  });
  
  const experienceCount = computed(() => subscription.value?.experience_count ?? 0);
  const experienceLimit = computed(() => 
    subscription.value?.experience_limit ?? SubscriptionConfig.free.experienceLimit
  );
  const monthlyAccessUsed = computed(() => subscription.value?.monthly_access_used ?? 0);
  const monthlyAccessLimit = computed(() => {
    if (subscription.value?.monthly_access_limit) {
      return subscription.value.monthly_access_limit;
    }
    // Default based on tier
    if (tier.value === 'premium') return SubscriptionConfig.calculated.defaultAiEnabledSessions;
    if (tier.value === 'starter') return SubscriptionConfig.calculated.starterDefaultAiEnabledSessions;
    return SubscriptionConfig.free.monthlySessionLimit;
  });
  const monthlyAccessRemaining = computed(() => subscription.value?.monthly_access_remaining ?? 0);
  const canBuyOverage = computed(() => isPaid.value); // Starter and Premium can buy overage
  const overageCreditsPerBatch = computed(() => SubscriptionConfig.overage.creditsPerBatch);
  // Sessions per overage batch (using AI-enabled cost as reference)
  const overageAccessPerBatch = computed(() => {
    if (tier.value === 'starter') return Math.floor(SubscriptionConfig.overage.creditsPerBatch / SubscriptionConfig.starter.aiEnabledSessionCostUsd);
    return SubscriptionConfig.calculated.aiEnabledSessionsPerBatch;
  });
  const monthlyFee = computed(() => {
    if (tier.value === 'starter') return SubscriptionConfig.starter.monthlyFeeUsd;
    return SubscriptionConfig.premium.monthlyFeeUsd;
  });
  
  // New budget-based computed values
  const monthlyBudgetUsd = computed(() => {
    if (tier.value === 'starter') return SubscriptionConfig.starter.monthlyBudgetUsd;
    return SubscriptionConfig.premium.monthlyBudgetUsd;
  });
  const aiEnabledSessionCost = computed(() => {
    if (tier.value === 'starter') return SubscriptionConfig.starter.aiEnabledSessionCostUsd;
    return SubscriptionConfig.premium.aiEnabledSessionCostUsd;
  });
  const aiDisabledSessionCost = computed(() => {
    if (tier.value === 'starter') return SubscriptionConfig.starter.aiDisabledSessionCostUsd;
    return SubscriptionConfig.premium.aiDisabledSessionCostUsd;
  });
  
  const isScheduledForCancellation = computed(() => subscription.value?.cancel_at_period_end ?? false);
  const scheduledTier = computed(() => subscription.value?.scheduled_tier ?? null);
  const isDowngrading = computed(() => isScheduledForCancellation.value && scheduledTier.value && scheduledTier.value !== 'free');
  const isCancelingToFree = computed(() => isScheduledForCancellation.value && (!scheduledTier.value || scheduledTier.value === 'free'));
  const periodEndDate = computed(() => {
    if (!subscription.value?.current_period_end) return null;
    return new Date(subscription.value.current_period_end);
  });
  
  // Backend URL
  const backendUrl = import.meta.env.VITE_BACKEND_URL || 'http://localhost:8080';
  
  // Actions
  async function fetchSubscription() {
    if (!authStore.session?.access_token) return;
    
    loading.value = true;
    error.value = null;
    
    try {
      const response = await fetch(`${backendUrl}/api/subscriptions`, {
        headers: {
          'Authorization': `Bearer ${authStore.session.access_token}`,
          'Content-Type': 'application/json'
        }
      });
      
      if (!response.ok) {
        throw new Error('Failed to fetch subscription');
      }
      
      subscription.value = await response.json();
    } catch (err: any) {
      console.error('Error fetching subscription:', err);
      error.value = err.message;
    } finally {
      loading.value = false;
    }
  }
  
  async function fetchUsage() {
    if (!authStore.session?.access_token) return;
    
    loading.value = true;
    error.value = null;
    
    try {
      const response = await fetch(`${backendUrl}/api/subscriptions/usage`, {
        headers: {
          'Authorization': `Bearer ${authStore.session.access_token}`,
          'Content-Type': 'application/json'
        }
      });
      
      if (!response.ok) {
        throw new Error('Failed to fetch usage');
      }
      
      usage.value = await response.json();
    } catch (err: any) {
      console.error('Error fetching usage:', err);
      error.value = err.message;
    } finally {
      loading.value = false;
    }
  }
  
  async function fetchDailyStats(days: number = 30) {
    if (!authStore.session?.access_token) return;
    
    loading.value = true;
    error.value = null;
    
    try {
      const response = await fetch(`${backendUrl}/api/subscriptions/daily-stats?days=${days}`, {
        headers: {
          'Authorization': `Bearer ${authStore.session.access_token}`,
          'Content-Type': 'application/json'
        }
      });
      
      if (!response.ok) {
        throw new Error('Failed to fetch daily stats');
      }
      
      dailyStats.value = await response.json();
    } catch (err: any) {
      console.error('Error fetching daily stats:', err);
      error.value = err.message;
    } finally {
      loading.value = false;
    }
  }
  
  async function createCheckout(tier: 'starter' | 'premium' = 'premium'): Promise<{ url: string } | null> {
    if (!authStore.session?.access_token) return null;

    actionLoading.value = true;
    error.value = null;

    try {
      const baseUrl = `${window.location.origin}/cms/subscription`;

      const response = await fetch(`${backendUrl}/api/subscriptions/create-checkout`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${authStore.session.access_token}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({ baseUrl, tier })
      });

      if (!response.ok) {
        const data = await response.json();
        throw new Error(data.message || 'Failed to create checkout');
      }

      return await response.json();
    } catch (err: any) {
      console.error('Error creating checkout:', err);
      error.value = err.message;
      return null;
    } finally {
      actionLoading.value = false;
    }
  }
  
  async function cancelSubscription(immediate: boolean = false): Promise<boolean> {
    if (!authStore.session?.access_token) return false;

    actionLoading.value = true;
    error.value = null;

    try {
      const response = await fetch(`${backendUrl}/api/subscriptions/cancel`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${authStore.session.access_token}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({ immediate })
      });

      if (!response.ok) {
        const data = await response.json();
        throw new Error(data.message || 'Failed to cancel subscription');
      }

      // Refresh subscription data
      await fetchSubscription();
      return true;
    } catch (err: any) {
      console.error('Error canceling subscription:', err);
      error.value = err.message;
      return false;
    } finally {
      actionLoading.value = false;
    }
  }
  
  async function reactivateSubscription(): Promise<boolean> {
    if (!authStore.session?.access_token) return false;

    actionLoading.value = true;
    error.value = null;

    try {
      const response = await fetch(`${backendUrl}/api/subscriptions/reactivate`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${authStore.session.access_token}`,
          'Content-Type': 'application/json'
        }
      });

      if (!response.ok) {
        const data = await response.json();
        throw new Error(data.message || 'Failed to reactivate subscription');
      }

      // Refresh subscription data
      await fetchSubscription();
      return true;
    } catch (err: any) {
      console.error('Error reactivating subscription:', err);
      error.value = err.message;
      return false;
    } finally {
      actionLoading.value = false;
    }
  }
  
  async function openBillingPortal(): Promise<string | null> {
    if (!authStore.session?.access_token) return null;

    actionLoading.value = true;
    error.value = null;

    try {
      const returnUrl = `${window.location.origin}/cms/subscription`;

      const response = await fetch(`${backendUrl}/api/subscriptions/portal?returnUrl=${encodeURIComponent(returnUrl)}`, {
        headers: {
          'Authorization': `Bearer ${authStore.session.access_token}`,
          'Content-Type': 'application/json'
        }
      });

      if (!response.ok) {
        const data = await response.json();
        throw new Error(data.message || 'Failed to get portal URL');
      }

      const { url } = await response.json();
      return url;
    } catch (err: any) {
      console.error('Error getting portal URL:', err);
      error.value = err.message;
      return null;
    } finally {
      actionLoading.value = false;
    }
  }
  
  async function buyCredits(amount: number): Promise<{ url: string } | null> {
    if (!authStore.session?.access_token) return null;

    actionLoading.value = true;
    error.value = null;

    try {
      const baseUrl = `${window.location.origin}/cms/subscription`;

      const response = await fetch(`${backendUrl}/api/subscriptions/buy-credits`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${authStore.session.access_token}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({ amount, baseUrl })
      });

      if (!response.ok) {
        const data = await response.json();
        throw new Error(data.message || 'Failed to create credit checkout');
      }

      return await response.json();
    } catch (err: any) {
      console.error('Error buying credits:', err);
      error.value = err.message;
      return null;
    } finally {
      actionLoading.value = false;
    }
  }
  
  function reset() {
    subscription.value = null;
    usage.value = null;
    dailyStats.value = null;
    loading.value = false;
    actionLoading.value = false;
    error.value = null;
  }
  
  return {
    // State
    subscription,
    usage,
    dailyStats,
    loading,
    actionLoading,
    error,
    
    // Computed
    isPaid,
    isStarter,
    isPremium,
    tier,
    canTranslate,
    canCreateExperience,
    canBuyOverage,
    experienceCount,
    experienceLimit,
    monthlyAccessUsed,
    monthlyAccessLimit,
    monthlyAccessRemaining,
    overageCreditsPerBatch,
    overageAccessPerBatch,
    monthlyFee,
    monthlyBudgetUsd,
    aiEnabledSessionCost,
    aiDisabledSessionCost,
    isScheduledForCancellation,
    scheduledTier,
    isDowngrading,
    isCancelingToFree,
    periodEndDate,
    
    // Config (for display)
    config: SubscriptionConfig,
    
    // Actions
    fetchSubscription,
    fetchUsage,
    fetchDailyStats,
    createCheckout,
    cancelSubscription,
    reactivateSubscription,
    openBillingPortal,
    buyCredits,
    reset
  };
});

