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
  tier: 'free' | 'premium';
  status: string;
  is_premium: boolean;
  
  // Stripe info
  stripe_subscription_id: string | null;
  current_period_start: string | null;
  current_period_end: string | null;
  cancel_at_period_end: boolean;
  
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
  };
}

export const useSubscriptionStore = defineStore('subscription', () => {
  const authStore = useAuthStore();
  
  // State
  const subscription = ref<SubscriptionDetails | null>(null);
  const usage = ref<UsageStats | null>(null);
  const dailyStats = ref<DailyStats | null>(null);
  const loading = ref(false);
  const error = ref<string | null>(null);
  
  // Computed
  const isPremium = computed(() => subscription.value?.is_premium ?? false);
  const tier = computed(() => subscription.value?.tier ?? 'free');
  const canTranslate = computed(() => subscription.value?.features?.translations_enabled ?? false);
  const canCreateExperience = computed(() => {
    if (!subscription.value) return true; // Allow by default if not loaded
    const limit = subscription.value.experience_limit ?? 
      (subscription.value.is_premium ? SubscriptionConfig.premium.experienceLimit : SubscriptionConfig.free.experienceLimit);
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
    return isPremium.value 
      ? SubscriptionConfig.premium.monthlyAccessLimit 
      : SubscriptionConfig.free.monthlyAccessLimit;
  });
  const monthlyAccessRemaining = computed(() => subscription.value?.monthly_access_remaining ?? 0);
  const canBuyOverage = computed(() => isPremium.value); // Only premium can buy overage credits
  const overageCreditsPerBatch = computed(() => SubscriptionConfig.overage.creditsPerBatch);
  const overageAccessPerBatch = computed(() => SubscriptionConfig.overage.accessPerBatch);
  const monthlyFee = computed(() => SubscriptionConfig.premium.monthlyFeeUsd);
  
  const isScheduledForCancellation = computed(() => subscription.value?.cancel_at_period_end ?? false);
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
  
  async function createCheckout(): Promise<{ url: string } | null> {
    if (!authStore.session?.access_token) return null;
    
    loading.value = true;
    error.value = null;
    
    try {
      const baseUrl = `${window.location.origin}/cms/subscription`;
      
      const response = await fetch(`${backendUrl}/api/subscriptions/create-checkout`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${authStore.session.access_token}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({ baseUrl })
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
      loading.value = false;
    }
  }
  
  async function cancelSubscription(immediate: boolean = false): Promise<boolean> {
    if (!authStore.session?.access_token) return false;
    
    loading.value = true;
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
      loading.value = false;
    }
  }
  
  async function reactivateSubscription(): Promise<boolean> {
    if (!authStore.session?.access_token) return false;
    
    loading.value = true;
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
      loading.value = false;
    }
  }
  
  async function openBillingPortal(): Promise<string | null> {
    if (!authStore.session?.access_token) return null;
    
    loading.value = true;
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
      loading.value = false;
    }
  }
  
  async function buyCredits(amount: number): Promise<{ url: string } | null> {
    if (!authStore.session?.access_token) return null;
    
    loading.value = true;
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
      loading.value = false;
    }
  }
  
  function reset() {
    subscription.value = null;
    usage.value = null;
    dailyStats.value = null;
    loading.value = false;
    error.value = null;
  }
  
  return {
    // State
    subscription,
    usage,
    dailyStats,
    loading,
    error,
    
    // Computed
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
    isScheduledForCancellation,
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

