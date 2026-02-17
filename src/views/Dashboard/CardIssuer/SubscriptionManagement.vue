<script setup lang="ts">
import { onMounted, computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute, useRouter } from 'vue-router';
import { useSubscriptionStore, type DailyAccessData } from '@/stores/subscription';
import { useCreditStore } from '@/stores/credits';
import { useVoiceCreditStore } from '@/stores/voiceCredits';
import { useToast } from 'primevue/usetoast';
import Card from 'primevue/card';
import Button from 'primevue/button';
import ProgressBar from 'primevue/progressbar';
import Tag from 'primevue/tag';
import Divider from 'primevue/divider';
import ConfirmDialog from 'primevue/confirmdialog';
import { useConfirm } from 'primevue/useconfirm';
import Select from 'primevue/select';
import CreditConfirmationDialog from '@/components/CreditConfirmationDialog.vue';

const { t } = useI18n();
const route = useRoute();
const router = useRouter();
const toast = useToast();
const confirm = useConfirm();
const subscriptionStore = useSubscriptionStore();
const creditStore = useCreditStore();
const voiceCreditStore = useVoiceCreditStore();

// Voice credit confirmation dialog state
const showVoiceCreditConfirmDialog = ref(false);
const voicePurchaseLoading = ref(false);
const selectedVoicePackages = ref(1);

const totalVoiceCredits = computed(() => selectedVoicePackages.value * voiceCreditStore.packageSize);
const totalVoiceCost = computed(() => selectedVoicePackages.value * voiceCreditStore.packagePriceUsd);

function handleVoiceQtyInput(event: Event) {
  const value = parseInt((event.target as HTMLInputElement).value);
  if (!isNaN(value) && value >= 1 && value <= 10) {
    selectedVoicePackages.value = value;
  } else {
    (event.target as HTMLInputElement).value = String(selectedVoicePackages.value);
  }
}

// Chart state
const chartDays = ref(30);
const chartDaysOptions = computed(() => [
  { label: t('subscription.chart.last_7_days'), value: 7 },
  { label: t('subscription.chart.last_14_days'), value: 14 },
  { label: t('subscription.chart.last_30_days'), value: 30 }
]);

// Interactive chart state
const hoveredDay = ref<DailyAccessData | null>(null);

function showTooltip(day: DailyAccessData) {
  hoveredDay.value = day;
}

function hideTooltip() {
  hoveredDay.value = null;
}

// Check for payment success/cancel on mount
onMounted(async () => {
  // Check URL params for Stripe redirect
  const success = route.query.success;
  const canceled = route.query.canceled;
  const type = route.query.type;
  const switchedFrom = route.query.switched_from as string | undefined;
  const subscribedTier = route.query.tier as string | undefined;

  if (success === 'true') {
    if (type === 'subscription') {
      // Check if this was a tier switch
      if (switchedFrom) {
        // Use tier param from URL, or infer from switchedFrom for backward compat
        const toTier = subscribedTier || (switchedFrom === 'starter' ? 'premium' : 'starter');

        const switchedMessageKey = toTier === 'enterprise'
          ? 'subscription.messages.subscription_switched_to_enterprise'
          : toTier === 'premium'
            ? 'subscription.messages.subscription_switched_to_premium'
            : 'subscription.messages.subscription_switched_to_starter';

        toast.add({
          severity: 'success',
          summary: t('subscription.messages.subscription_switched'),
          detail: t(switchedMessageKey),
          life: 5000
        });
      } else {
        // Regular new subscription - use tier param to show correct welcome message
        const welcomeKey = subscribedTier === 'enterprise'
          ? 'subscription.messages.welcome_enterprise'
          : subscribedTier === 'starter'
            ? 'subscription.messages.welcome_starter'
            : 'subscription.messages.welcome_premium';
        const activeKey = subscribedTier === 'enterprise'
          ? 'subscription.messages.subscription_active_enterprise'
          : subscribedTier === 'starter'
            ? 'subscription.messages.subscription_active_starter'
            : 'subscription.messages.subscription_active';

        toast.add({
          severity: 'success',
          summary: t(welcomeKey),
          detail: t(activeKey),
          life: 5000
        });
      }
    }
    // Clean URL
    window.history.replaceState({}, '', route.path);
  } else if (canceled === 'true') {
    toast.add({
      severity: 'info',
      summary: t('subscription.messages.payment_canceled'),
      detail: t('subscription.messages.no_charges'),
      life: 3000
    });
    window.history.replaceState({}, '', route.path);
  }
  
  // Fetch all data in parallel (independent API calls)
  await Promise.all([
    subscriptionStore.fetchSubscription(),
    creditStore.fetchCreditBalance(),
    voiceCreditStore.fetchBalance(),
    subscriptionStore.fetchDailyStats(chartDays.value)
  ]);
});

// Reload chart when days change
async function reloadChart() {
  await subscriptionStore.fetchDailyStats(chartDays.value);
}

// Computed
const isPaid = computed(() => subscriptionStore.isPaid);
const isStarter = computed(() => subscriptionStore.isStarter);
const isPremium = computed(() => subscriptionStore.isPremium);
const isEnterprise = computed(() => subscriptionStore.isEnterprise);
const subscription = computed(() => subscriptionStore.subscription);
const loading = computed(() => subscriptionStore.loading || creditStore.loading);
const actionLoading = computed(() => subscriptionStore.actionLoading);
const config = computed(() => subscriptionStore.config);
// Pricing variables for translations
const pricingVars = computed(() => ({
  monthlyBudget: config.value.premium.monthlyBudgetUsd,
  topupCost: config.value.overage.creditsPerBatch,
  aiCost: config.value.premium.aiEnabledSessionCostUsd,
  nonAiCost: config.value.premium.aiDisabledSessionCostUsd,
  aiSessions: config.value.calculated.defaultAiEnabledSessions,
  nonAiSessions: config.value.calculated.defaultAiDisabledSessions,
  projectLimit: config.value.premium.projectLimit,
  monthlyFee: config.value.premium.monthlyFeeUsd,
}));

const starterPricingVars = computed(() => ({
  monthlyBudget: config.value.starter.monthlyBudgetUsd,
  topupCost: config.value.overage.creditsPerBatch,
  aiCost: config.value.starter.aiEnabledSessionCostUsd,
  nonAiCost: config.value.starter.aiDisabledSessionCostUsd,
  aiSessions: config.value.calculated.starterDefaultAiEnabledSessions,
  nonAiSessions: config.value.calculated.starterDefaultAiDisabledSessions,
  projectLimit: config.value.starter.projectLimit,
  monthlyFee: config.value.starter.monthlyFeeUsd,
}));

const enterprisePricingVars = computed(() => ({
  monthlyBudget: config.value.enterprise.monthlyBudgetUsd,
  topupCost: config.value.overage.creditsPerBatch,
  aiCost: config.value.enterprise.aiEnabledSessionCostUsd,
  nonAiCost: config.value.enterprise.aiDisabledSessionCostUsd,
  aiSessions: config.value.calculated.enterpriseDefaultAiEnabledSessions,
  nonAiSessions: config.value.calculated.enterpriseDefaultAiDisabledSessions,
  projectLimit: config.value.enterprise.projectLimit,
  monthlyFee: config.value.enterprise.monthlyFeeUsd,
}));

// Calculate session rate savings (Premium vs Starter)
const sessionRateSavings = computed(() => {
  const starterAiCost = config.value.starter.aiEnabledSessionCostUsd;
  const premiumAiCost = config.value.premium.aiEnabledSessionCostUsd;
  if (starterAiCost === 0) return 0;
  return Math.round(((starterAiCost - premiumAiCost) / starterAiCost) * 100);
});

// Budget spend tracking for paid users
const currentBudget = computed(() => {
  if (isEnterprise.value) return config.value.enterprise.monthlyBudgetUsd;
  if (isStarter.value) return config.value.starter.monthlyBudgetUsd;
  if (isPremium.value) return config.value.premium.monthlyBudgetUsd;
  return 0;
});

const currentSpend = computed(() => {
  return chartSummary.value?.total_cost_usd || 0;
});

const budgetPercent = computed(() => {
  if (!currentBudget.value) return 0;
  return Math.min(100, Math.round((currentSpend.value / currentBudget.value) * 100));
});

const usagePercent = computed(() => {
  const used = subscriptionStore.monthlyAccessUsed;
  const limit = subscriptionStore.monthlyAccessLimit;
  if (!limit) return 0;
  return Math.min(100, Math.round((used / limit) * 100));
});

// Navigate to credit management page
function buyCredits() {
  router.push('/cms/credits');
}

const projectUsagePercent = computed(() => {
  const used = subscriptionStore.projectCount;
  const limit = subscriptionStore.projectLimit;
  if (!limit) return 0;
  return Math.min(100, Math.round((used / limit) * 100));
});

const periodEndFormatted = computed(() => {
  const date = subscriptionStore.periodEndDate;
  if (!date) return null;
  return date.toLocaleDateString(undefined, {
    year: 'numeric',
    month: 'long',
    day: 'numeric'
  });
});

// Chart computed properties
const dailyStats = computed(() => subscriptionStore.dailyStats);
const chartData = computed(() => dailyStats.value?.data || []);
const chartSummary = computed(() => dailyStats.value?.summary);
const maxDailyAccess = computed(() => {
  if (!chartData.value.length) return 10; // Default min height
  const max = Math.max(...chartData.value.map(d => d.total));
  return max < 10 ? 10 : max; // Ensure chart doesn't look flat for low numbers
});

// Format date for chart labels
function formatChartDate(dateStr: string) {
  const date = new Date(dateStr);
  return date.toLocaleDateString(undefined, { month: 'short', day: 'numeric' });
}

// Actions
async function upgradeToPremium(tier: 'starter' | 'premium' | 'enterprise' = 'premium') {
  // If called without arguments from template (event object), default to premium
  if (typeof tier !== 'string') tier = 'premium';
  
  const result = await subscriptionStore.createCheckout(tier);
  if (result?.url) {
    window.location.href = result.url;
  } else {
    toast.add({
      severity: 'error',
      summary: t('common.error'),
      detail: subscriptionStore.error || t('subscription.messages.checkout_failed'),
      life: 5000
    });
  }
}

// Helper: get localized tier name for parameterized messages
const currentTierName = computed(() => {
  if (isEnterprise.value) return t('subscription.enterprise_plan');
  if (isStarter.value) return t('subscription.starter_plan');
  return t('subscription.premium_plan');
});

function confirmCancel() {
  confirm.require({
    message: t('subscription.messages.confirm_cancel', { tier: currentTierName.value }),
    header: t('subscription.cancel'),
    icon: 'pi pi-exclamation-triangle',
    acceptClass: 'p-button-danger',
    accept: async () => {
      const success = await subscriptionStore.cancelSubscription(false);
      if (success) {
        toast.add({
          severity: 'success',
          summary: t('subscription.messages.subscription_canceled'),
          detail: t('subscription.messages.will_end'),
          life: 5000
        });
      } else {
        toast.add({
          severity: 'error',
          summary: t('common.error'),
          detail: subscriptionStore.error || t('subscription.messages.cancel_failed'),
          life: 5000
        });
      }
    }
  });
}

async function reactivate() {
  const success = await subscriptionStore.reactivateSubscription();
  if (success) {
    toast.add({
      severity: 'success',
      summary: t('subscription.messages.subscription_reactivated'),
      detail: t('subscription.messages.will_continue', { tier: currentTierName.value }),
      life: 3000
    });
  } else {
    toast.add({
      severity: 'error',
      summary: t('common.error'),
      detail: subscriptionStore.error || t('subscription.messages.reactivate_failed'),
      life: 5000
    });
  }
}

async function confirmVoiceCreditPurchase() {
  voicePurchaseLoading.value = true
  try {
    const success = await voiceCreditStore.purchaseCredits(selectedVoicePackages.value)
    if (success) {
      showVoiceCreditConfirmDialog.value = false
      toast.add({
        severity: 'success',
        summary: t('common.success'),
        detail: t('subscription.voice_credits_purchase_success'),
        life: 3000
      })
      // Refresh general credit balance since credits were deducted
      await creditStore.fetchCreditBalance()
    } else {
      toast.add({
        severity: 'error',
        summary: t('common.error'),
        detail: voiceCreditStore.error || t('subscription.voice_credits_purchase_error'),
        life: 5000
      })
    }
  } catch (error: any) {
    toast.add({
      severity: 'error',
      summary: t('common.error'),
      detail: error.message || t('subscription.voice_credits_purchase_error'),
      life: 5000
    })
  } finally {
    voicePurchaseLoading.value = false
  }
}

async function openPortal() {
  const url = await subscriptionStore.openBillingPortal();
  if (url) {
    window.location.href = url;
  } else {
    toast.add({
      severity: 'error',
      summary: t('common.error'),
      detail: t('subscription.messages.portal_failed'),
      life: 5000
    });
  }
}

</script>

<template>
  <div class="max-w-6xl mx-auto p-4 sm:p-6 space-y-8">
    <ConfirmDialog />
    
    <!-- Page Header -->
    <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
      <div>
        <h1 class="text-2xl sm:text-3xl font-bold text-slate-800 tracking-tight">{{ $t('plan.title') }}</h1>
        <p class="text-slate-500 mt-1">{{ $t('plan.description') }}</p>
      </div>
      <div v-if="isPaid" class="flex gap-2 flex-wrap">
        <Tag v-if="subscriptionStore.isDowngrading" severity="info" :value="$t('subscription.status.downgrading', { tier: subscriptionStore.scheduledTier })" icon="pi pi-arrow-down" rounded />
        <Tag v-else-if="subscriptionStore.isCancelingToFree" severity="warning" :value="$t('subscription.status.cancellation_scheduled')" icon="pi pi-exclamation-circle" rounded />
        <Tag v-else severity="success" :value="subscriptionStore.isEnterprise ? $t('subscription.status.enterprise_active') : isStarter ? $t('subscription.status.starter_active') : $t('subscription.status.premium_active')" icon="pi pi-check-circle" rounded />
      </div>
    </div>
    
    <!-- Loading State -->
    <div v-if="loading && !subscription" class="flex flex-col items-center justify-center py-20 bg-white rounded-xl shadow-sm border border-slate-100">
      <i class="pi pi-spin pi-spinner text-4xl text-blue-500 mb-4"></i>
      <p class="text-slate-500">{{ $t('subscription.status.loading_details') }}</p>
    </div>
    
    <!-- Main Content -->
    <div v-else class="space-y-8">
      
      <!-- ============ FREE USER VIEW ============ -->
      <div v-if="!isPaid" class="space-y-8">
        
        <!-- Usage Stats (Compact) -->
        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div class="bg-white p-5 rounded-xl shadow-sm border border-slate-100">
            <div class="flex justify-between items-center mb-3">
              <span class="text-slate-600 font-medium">{{ $t('subscription.usage.experiences') }}</span>
              <span class="text-slate-800 font-bold">{{ subscriptionStore.projectCount }} / {{ subscriptionStore.projectLimit }}</span>
            </div>
            <ProgressBar :value="projectUsagePercent" :showValue="false" class="h-2" :class="projectUsagePercent >= 100 ? 'progress-danger' : ''" />
          </div>
          <div class="bg-white p-5 rounded-xl shadow-sm border border-slate-100">
            <div class="flex justify-between items-center mb-3">
              <span class="text-slate-600 font-medium">{{ $t('subscription.usage.monthly_access') }}</span>
              <span class="text-slate-800 font-bold">{{ subscriptionStore.monthlyAccessUsed }} / {{ subscriptionStore.monthlyAccessLimit }}</span>
            </div>
            <ProgressBar :value="usagePercent" :showValue="false" class="h-2" :class="usagePercent >= 100 ? 'progress-danger' : ''" />
          </div>
        </div>

        <!-- Plan Comparison -->
        <div class="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-6 items-start">
          
          <!-- Current Free Plan -->
          <div class="bg-white rounded-2xl p-6 border border-slate-200 shadow-sm relative overflow-hidden h-full flex flex-col">
            <div class="absolute top-0 right-0 p-4">
              <Tag :value="$t('subscription.current_plan')" severity="secondary" rounded />
            </div>
            <div class="mb-6">
              <div class="w-12 h-12 rounded-xl bg-slate-100 flex items-center justify-center mb-4">
                <i class="pi pi-user text-xl text-slate-500"></i>
              </div>
              <h2 class="text-2xl font-bold text-slate-800">{{ $t('subscription.free_plan') }}</h2>
              <div class="text-3xl font-extrabold text-slate-900 mt-2">$0 <span class="text-base font-normal text-slate-500">/mo</span></div>
            </div>
            <ul class="space-y-4 text-sm flex-1">
              <li class="flex items-center gap-3">
                <i class="pi pi-check text-slate-600"></i>
                <span class="text-slate-700">{{ $t('subscription.features.project_limit', { limit: config.free.projectLimit }) }}</span>
              </li>
              <li class="flex items-center gap-3">
                <i class="pi pi-check text-slate-600"></i>
                <span class="text-slate-700">{{ $t('subscription.features.monthly_pool', { count: config.free.monthlySessionLimit }) }}</span>
              </li>
              <li class="flex items-center gap-3">
                <i class="pi pi-check text-slate-600"></i>
                <span class="text-slate-700">{{ $t('subscription.features.ai_assistant_included') }}</span>
              </li>
              <li class="flex items-center gap-3 opacity-50">
                <i class="pi pi-times text-slate-400"></i>
                <span class="text-slate-500">{{ $t('subscription.features.no_translations') }}</span>
              </li>
              <li class="flex items-center gap-3 opacity-50">
                <i class="pi pi-times text-slate-400"></i>
                <span class="text-slate-500">{{ $t('subscription.features.no_overage') }}</span>
              </li>
              <li class="flex items-center gap-3">
                <i class="pi pi-check text-slate-600"></i>
                <span class="text-slate-700">{{ $t('subscription.features.branding_included') }}</span>
              </li>
            </ul>
          </div>

          <!-- Starter Plan (Upgrade Option) -->
          <div class="bg-white rounded-2xl p-6 border border-emerald-200 shadow-sm relative overflow-hidden h-full flex flex-col hover:border-emerald-400 hover:shadow-md transition-all duration-300">
            <div class="mb-6">
              <div class="w-12 h-12 rounded-xl bg-emerald-50 flex items-center justify-center mb-4">
                <i class="pi pi-bolt text-xl text-emerald-500"></i>
              </div>
              <h2 class="text-2xl font-bold text-slate-800">{{ $t('subscription.starter_plan') }}</h2>
              <div class="text-3xl font-extrabold text-slate-900 mt-2">${{ config.starter.monthlyFeeUsd }} <span class="text-base font-normal text-slate-500">/mo</span></div>
            </div>
            <ul class="space-y-3 text-sm mb-8 flex-1">
              <li class="flex items-center gap-3">
                <div class="bg-emerald-100 p-1 rounded-full"><i class="pi pi-check text-emerald-600 text-xs"></i></div>
                <span class="text-slate-700">{{ $t('subscription.features.starter_projects', { limit: config.starter.projectLimit }) }}</span>
              </li>
              <li class="flex items-start gap-3">
                <div class="bg-emerald-100 p-1 rounded-full mt-0.5"><i class="pi pi-check text-emerald-600 text-xs"></i></div>
                <div>
                  <div class="text-slate-700 font-medium"><strong>${{ config.starter.monthlyBudgetUsd }}</strong> {{ $t('subscription.usage.monthly_budget') }}</div>
                  <div class="text-xs text-slate-500 mt-1">{{ $t('subscription.features.estimated_sessions', { ai: starterPricingVars.aiSessions, nonAi: starterPricingVars.nonAiSessions }) }}</div>
                  <div class="text-xs text-slate-400 mt-0.5">{{ $t('subscription.features.session_cost_breakdown', { aiCost: config.starter.aiEnabledSessionCostUsd, nonAiCost: config.starter.aiDisabledSessionCostUsd }) }}</div>
                </div>
              </li>
              <li class="flex items-center gap-3">
                <div class="bg-emerald-100 p-1 rounded-full"><i class="pi pi-check text-emerald-600 text-xs"></i></div>
                <span class="text-slate-700">{{ $t('subscription.features.ai_assistant_included') }}</span>
              </li>
              <li class="flex items-center gap-3">
                <div class="bg-emerald-100 p-1 rounded-full"><i class="pi pi-check text-emerald-600 text-xs"></i></div>
                <span class="text-slate-700">{{ $t('subscription.features.starter_translations', { count: config.starter.maxLanguages }) }}</span>
              </li>
              <li class="flex items-start gap-3">
                <div class="bg-emerald-100 p-1 rounded-full mt-0.5"><i class="pi pi-check text-emerald-600 text-xs"></i></div>
                <div>
                  <div class="text-slate-700">{{ $t('subscription.features.overage_available') }}</div>
                  <div class="text-xs text-slate-400 mt-0.5">{{ $t('subscription.features.overage', { cost: config.overage.creditsPerBatch, sessions: config.calculated.starterAiDisabledSessionsPerBatch }) }}</div>
                </div>
              </li>
              <li class="flex items-center gap-3">
                <div class="bg-emerald-100 p-1 rounded-full"><i class="pi pi-check text-emerald-600 text-xs"></i></div>
                <span class="text-slate-700">{{ $t('subscription.features.branding_included') }}</span>
              </li>
            </ul>
            <Button
              :label="$t('subscription.upgrade')"
              class="w-full bg-emerald-500 text-white border-0 hover:bg-emerald-600 font-bold"
              @click="upgradeToPremium('starter')"
              :loading="actionLoading"
            />
          </div>
          
          <!-- Premium Plan (Upgrade Option) -->
          <div class="bg-gradient-to-b from-slate-900 to-slate-800 rounded-2xl p-6 shadow-xl relative overflow-hidden text-white transform hover:scale-[1.02] transition-transform duration-300 h-full flex flex-col">
            <div class="absolute top-0 right-0 p-0">
              <div class="bg-gradient-to-r from-amber-400 to-orange-500 text-white text-xs font-bold px-3 py-1 rounded-bl-xl shadow-lg uppercase">{{ $t('subscription.best_value') }}</div>
            </div>
            <div class="mb-6">
              <div class="w-12 h-12 rounded-xl bg-white/10 flex items-center justify-center mb-4 backdrop-blur-sm">
                <i class="pi pi-star-fill text-xl text-amber-400"></i>
              </div>
              <h2 class="text-2xl font-bold text-white">{{ $t('subscription.premium_plan') }}</h2>
              <div class="text-3xl font-extrabold text-white mt-2">${{ config.premium.monthlyFeeUsd }} <span class="text-base font-normal text-slate-400">/mo</span></div>
            </div>
            <ul class="space-y-3 text-sm mb-8 flex-1">
              <li class="flex items-center gap-3">
                <div class="bg-emerald-500/20 p-1 rounded-full"><i class="pi pi-check text-emerald-400 text-xs"></i></div>
                <span class="text-slate-100">{{ $t('subscription.features.unlimited_projects', { limit: config.premium.projectLimit }) }}</span>
              </li>
              <li class="flex items-start gap-3">
                <div class="bg-emerald-500/20 p-1 rounded-full mt-0.5"><i class="pi pi-check text-emerald-400 text-xs"></i></div>
                <div>
                  <div class="text-slate-100 font-medium"><strong>${{ config.premium.monthlyBudgetUsd }}</strong> {{ $t('subscription.usage.monthly_budget') }}</div>
                  <div class="text-xs text-slate-400 mt-1">{{ $t('subscription.features.estimated_sessions', { ai: pricingVars.aiSessions, nonAi: pricingVars.nonAiSessions }) }}</div>
                  <div class="text-xs text-slate-500 mt-0.5">{{ $t('subscription.features.session_cost_breakdown', { aiCost: config.premium.aiEnabledSessionCostUsd, nonAiCost: config.premium.aiDisabledSessionCostUsd }) }}</div>
                </div>
              </li>
              <li class="flex items-center gap-3">
                <div class="bg-amber-500/20 p-1 rounded-full"><i class="pi pi-bolt text-amber-400 text-xs"></i></div>
                <span class="text-amber-300">{{ $t('subscription.features.session_rate_savings', { percent: sessionRateSavings }) }}</span>
              </li>
              <li class="flex items-center gap-3">
                <div class="bg-emerald-500/20 p-1 rounded-full"><i class="pi pi-check text-emerald-400 text-xs"></i></div>
                <span class="text-slate-100">{{ $t('subscription.features.ai_assistant_included') }}</span>
              </li>
              <li class="flex items-center gap-3">
                <div class="bg-emerald-500/20 p-1 rounded-full"><i class="pi pi-check text-emerald-400 text-xs"></i></div>
                <span class="text-slate-100">{{ $t('subscription.features.unlimited_translations') }}</span>
              </li>
              <li class="flex items-start gap-3">
                <div class="bg-emerald-500/20 p-1 rounded-full mt-0.5"><i class="pi pi-check text-emerald-400 text-xs"></i></div>
                <div>
                  <div class="text-slate-100">{{ $t('subscription.features.overage_available') }}</div>
                  <div class="text-xs text-slate-500 mt-0.5">{{ $t('subscription.features.overage', { cost: config.overage.creditsPerBatch, sessions: config.calculated.aiDisabledSessionsPerBatch }) }}</div>
                </div>
              </li>
              <li class="flex items-center gap-3">
                <div class="bg-emerald-500/20 p-1 rounded-full"><i class="pi pi-check text-emerald-400 text-xs"></i></div>
                <span class="text-slate-100">{{ $t('subscription.features.white_label') }}</span>
              </li>
            </ul>
            <Button
              :label="$t('subscription.upgrade_to_premium')"
              class="w-full bg-gradient-to-r from-amber-400 to-orange-500 text-slate-900 border-0 hover:from-amber-500 hover:to-orange-600 font-bold"
              @click="() => upgradeToPremium('premium')"
              :loading="actionLoading"
            />
          </div>

          <!-- Enterprise Plan (Upgrade Option) -->
          <div class="bg-white rounded-2xl p-6 border border-violet-200 shadow-sm relative overflow-hidden h-full flex flex-col hover:border-violet-400 hover:shadow-md transition-all duration-300">
            <div class="mb-6">
              <div class="w-12 h-12 rounded-xl bg-violet-50 flex items-center justify-center mb-4">
                <i class="pi pi-building text-xl text-violet-500"></i>
              </div>
              <h2 class="text-2xl font-bold text-slate-800">{{ $t('subscription.enterprise_plan') }}</h2>
              <div class="text-3xl font-extrabold text-slate-900 mt-2">${{ config.enterprise.monthlyFeeUsd }} <span class="text-base font-normal text-slate-500">/mo</span></div>
            </div>
            <ul class="space-y-3 text-sm mb-8 flex-1">
              <li class="flex items-center gap-3">
                <div class="bg-violet-100 p-1 rounded-full"><i class="pi pi-check text-violet-600 text-xs"></i></div>
                <span class="text-slate-700">{{ $t('subscription.features.enterprise_projects', { limit: config.enterprise.projectLimit }) }}</span>
              </li>
              <li class="flex items-start gap-3">
                <div class="bg-violet-100 p-1 rounded-full mt-0.5"><i class="pi pi-check text-violet-600 text-xs"></i></div>
                <div>
                  <div class="text-slate-700 font-medium"><strong>${{ config.enterprise.monthlyBudgetUsd }}</strong> {{ $t('subscription.usage.monthly_budget') }}</div>
                  <div class="text-xs text-slate-500 mt-1">{{ $t('subscription.features.estimated_sessions', { ai: enterprisePricingVars.aiSessions, nonAi: enterprisePricingVars.nonAiSessions }) }}</div>
                  <div class="text-xs text-slate-400 mt-0.5">{{ $t('subscription.features.session_cost_breakdown', { aiCost: config.enterprise.aiEnabledSessionCostUsd, nonAiCost: config.enterprise.aiDisabledSessionCostUsd }) }}</div>
                </div>
              </li>
              <li class="flex items-center gap-3">
                <div class="bg-violet-100 p-1 rounded-full"><i class="pi pi-bolt text-violet-600 text-xs"></i></div>
                <span class="text-violet-700 font-medium">{{ $t('subscription.features.lowest_session_rates') }}</span>
              </li>
              <li class="flex items-center gap-3">
                <div class="bg-violet-100 p-1 rounded-full"><i class="pi pi-check text-violet-600 text-xs"></i></div>
                <span class="text-slate-700">{{ $t('subscription.features.ai_assistant_included') }}</span>
              </li>
              <li class="flex items-center gap-3">
                <div class="bg-violet-100 p-1 rounded-full"><i class="pi pi-check text-violet-600 text-xs"></i></div>
                <span class="text-slate-700">{{ $t('subscription.features.unlimited_translations') }}</span>
              </li>
              <li class="flex items-start gap-3">
                <div class="bg-violet-100 p-1 rounded-full mt-0.5"><i class="pi pi-check text-violet-600 text-xs"></i></div>
                <div>
                  <div class="text-slate-700">{{ $t('subscription.features.overage_available') }}</div>
                  <div class="text-xs text-slate-400 mt-0.5">{{ $t('subscription.features.overage', { cost: config.overage.creditsPerBatch, sessions: config.calculated.enterpriseAiDisabledSessionsPerBatch }) }}</div>
                </div>
              </li>
              <li class="flex items-center gap-3">
                <div class="bg-violet-100 p-1 rounded-full"><i class="pi pi-check text-violet-600 text-xs"></i></div>
                <span class="text-slate-700">{{ $t('subscription.features.white_label') }}</span>
              </li>
              <li class="flex items-center gap-3">
                <div class="bg-violet-100 p-1 rounded-full"><i class="pi pi-check text-violet-600 text-xs"></i></div>
                <span class="text-slate-700">{{ $t('subscription.features.custom_domain') }}</span>
              </li>
            </ul>
            <Button
              :label="$t('subscription.upgrade_to_enterprise')"
              class="w-full bg-gradient-to-r from-violet-500 to-purple-600 text-white border-0 hover:from-violet-600 hover:to-purple-700 font-bold"
              @click="() => upgradeToPremium('enterprise')"
              :loading="actionLoading"
            />
          </div>

        </div>
        
        <!-- Daily Access Chart Card -->
        <Card class="shadow-sm border-0 rounded-xl overflow-hidden">
          <template #title>
            <div class="flex items-center justify-between px-2 pt-2">
              <div class="flex items-center gap-2">
                <i class="pi pi-chart-line text-slate-400"></i>
                <span class="font-semibold text-slate-700">{{ $t('subscription.chart.daily_access') }}</span>
              </div>
              <Select v-model="chartDays" :options="chartDaysOptions" optionLabel="label" optionValue="value" class="w-36 text-sm" @change="reloadChart" />
            </div>
          </template>
          <template #content>
            <div v-if="chartSummary" class="flex gap-8 mb-8 px-2 border-b border-slate-100 pb-6">
              <div>
                <div class="text-2xl font-bold text-slate-800">{{ chartSummary.total_access.toLocaleString() }}</div>
                <div class="text-xs font-medium text-slate-500 uppercase tracking-wide">{{ $t('subscription.chart.total_access') }}</div>
              </div>
              <div>
                <div class="text-2xl font-bold text-slate-800">{{ chartSummary.average_daily }}</div>
                <div class="text-xs font-medium text-slate-500 uppercase tracking-wide">{{ $t('subscription.chart.avg_day') }}</div>
              </div>
              <div>
                <div class="text-2xl font-bold text-amber-500">{{ chartSummary.total_overage }}</div>
                <div class="text-xs font-medium text-slate-500 uppercase tracking-wide">{{ $t('subscription.traffic.overage') }}</div>
              </div>
            </div>
            
            <div v-if="chartData.length" class="chart-wrapper h-64 relative mt-4">
              <!-- Y-axis grid lines -->
              <div class="absolute inset-0 flex flex-col justify-between text-xs text-slate-300 pointer-events-none">
                <div class="border-b border-slate-100 w-full h-0 relative"><span class="absolute -top-2.5 right-full pr-2">{{ maxDailyAccess }}</span></div>
                <div class="border-b border-slate-100 w-full h-0 relative"><span class="absolute -top-2.5 right-full pr-2">{{ Math.round(maxDailyAccess / 2) }}</span></div>
                <div class="border-b border-slate-100 w-full h-0 relative"><span class="absolute -top-2.5 right-full pr-2">0</span></div>
              </div>
              
              <div class="flex items-end h-full gap-1 pt-2 pb-6 pl-8 relative z-10">
                <div 
                  v-for="day in chartData" 
                  :key="day.date" 
                  class="flex-1 flex flex-col justify-end h-full relative group"
                  @mouseenter="showTooltip(day)"
                  @mouseleave="hideTooltip"
                >
                  <!-- Bar Container -->
                  <div class="w-full flex flex-col justify-end bg-slate-50/50 rounded-t-sm h-full overflow-hidden relative transition-all duration-300 group-hover:bg-slate-100">
                    <!-- Overage Bar -->
                    <div 
                      v-if="day.overage > 0"
                      class="w-full bg-amber-400"
                      :style="{ height: `${(day.overage / maxDailyAccess) * 100}%` }"
                    ></div>
                    <!-- Included Bar -->
                    <div 
                      class="w-full bg-blue-500 transition-all duration-300 group-hover:bg-blue-600"
                      :style="{ height: `${(day.included / maxDailyAccess) * 100}%` }"
                    ></div>
                  </div>
                  
                  <!-- Tooltip -->
                  <div 
                    v-if="hoveredDay === day"
                    class="absolute bottom-full left-1/2 -translate-x-1/2 mb-2 z-20 pointer-events-none"
                  >
                    <div class="bg-slate-900 text-white text-xs rounded-lg py-2 px-3 shadow-xl whitespace-nowrap text-center">
                      <div class="font-bold border-b border-slate-700 pb-1 mb-1">{{ formatChartDate(day.date) }}</div>
                      <div class="flex justify-between gap-3"><span class="text-slate-300">{{ $t('subscription.traffic.total') }}:</span> <span>{{ day.total }}</span></div>
                      <div v-if="day.ai_sessions > 0" class="flex justify-between gap-3 text-blue-400"><span>{{ $t('subscription.traffic.ai_short') }}:</span> <span>{{ day.ai_sessions }}</span></div>
                      <div v-if="day.non_ai_sessions > 0" class="flex justify-between gap-3 text-slate-400"><span>{{ $t('subscription.traffic.non_ai_short') }}:</span> <span>{{ day.non_ai_sessions }}</span></div>
                      <div v-if="day.overage > 0" class="flex justify-between gap-3 text-amber-400"><span>{{ $t('subscription.traffic.overage') }}:</span> <span>{{ day.overage }}</span></div>
                    </div>
                    <div class="w-0 h-0 border-l-[6px] border-l-transparent border-r-[6px] border-r-transparent border-t-[6px] border-t-slate-900 mx-auto"></div>
                  </div>
                </div>
              </div>
              
              <!-- X-axis Labels -->
              <div class="absolute bottom-0 left-8 right-0 flex justify-between text-[10px] text-slate-400 pt-2 border-t border-slate-200">
                <span>{{ formatChartDate(chartData[0].date) }}</span>
                <span>{{ formatChartDate(chartData[chartData.length - 1].date) }}</span>
              </div>
            </div>
            
            <div v-else class="text-center py-16 text-slate-400">
              <i class="pi pi-chart-bar text-4xl mb-3 opacity-20"></i>
              <p>{{ $t('subscription.traffic.no_data') }}</p>
            </div>
          </template>
        </Card>
      </div>
      
      <!-- ============ PAID USER VIEW (Starter & Premium) ============ -->
      <div v-else class="space-y-8">
        
        <div class="grid grid-cols-1 xl:grid-cols-2 gap-8 items-start">
          <!-- Left Col: Plan & Usage -->
          <div class="space-y-8">
            <!-- Paid Plan Status -->
            <div class="bg-white rounded-2xl shadow-sm border border-slate-200 p-6">
              <div class="flex justify-between items-start mb-6">
                <div class="flex items-center gap-4">
                  <div
                    class="w-14 h-14 rounded-2xl flex items-center justify-center shadow-md"
                    :class="isEnterprise ? 'bg-gradient-to-br from-violet-500 to-purple-700' : isStarter ? 'bg-gradient-to-br from-emerald-400 to-cyan-600' : 'bg-gradient-to-br from-amber-400 to-amber-600'"
                  >
                    <i class="pi text-2xl text-white" :class="isEnterprise ? 'pi-building' : isStarter ? 'pi-sparkles' : 'pi-star-fill'"></i>
                  </div>
                  <div>
                    <h2 class="text-xl font-bold text-slate-800">{{ isEnterprise ? $t('subscription.enterprise_plan') : isStarter ? $t('subscription.starter_plan') : $t('subscription.premium_plan') }}</h2>
                    <div class="text-sm text-slate-500 mt-1" v-if="periodEndFormatted">
                      <span v-if="subscriptionStore.isScheduledForCancellation" class="text-amber-600 font-medium">{{ $t('subscription.billing.access_until') }} {{ periodEndFormatted }}</span>
                      <span v-else>{{ $t('subscription.billing.next_billing') }} {{ periodEndFormatted }}</span>
                    </div>
                  </div>
                </div>
                <div class="text-right">
                  <div class="text-2xl font-bold text-slate-800">${{ subscriptionStore.monthlyFee }}</div>
                  <div class="text-xs text-slate-500 uppercase font-bold tracking-wider">{{ $t('common.per_month') }}</div>
                </div>
              </div>
              
              <div class="flex flex-wrap gap-3 pt-4 border-t border-slate-100">
                <template v-if="subscriptionStore.isScheduledForCancellation">
                  <Button
                    :label="$t('subscription.reactivate')"
                    icon="pi pi-refresh"
                    severity="success"
                    @click="reactivate"
                    :loading="actionLoading"
                    class="flex-1 sm:flex-none"
                  />
                </template>
                <template v-else>
                  <Button 
                    :label="$t('subscription.manage_billing')" 
                    icon="pi pi-credit-card" 
                    severity="secondary" 
                    outlined 
                    @click="openPortal" 
                    class="flex-1 sm:flex-none"
                  />
                  <!-- Upgrade Button for Starter/Premium -->
                  <Button
                    v-if="isStarter"
                    :label="$t('subscription.upgrade_to_premium')"
                    icon="pi pi-arrow-up"
                    class="flex-1 sm:flex-none bg-gradient-to-r from-amber-500 to-orange-500 border-0 hover:from-amber-600 hover:to-orange-600"
                    @click="() => upgradeToPremium('premium')"
                  />
                  <Button
                    v-if="isStarter || isPremium"
                    :label="$t('subscription.upgrade_to_enterprise')"
                    icon="pi pi-arrow-up"
                    class="flex-1 sm:flex-none bg-gradient-to-r from-violet-500 to-purple-600 border-0 hover:from-violet-600 hover:to-purple-700 text-white"
                    @click="() => upgradeToPremium('enterprise')"
                  />
                  <Button 
                    :label="$t('common.cancel')" 
                    icon="pi pi-times" 
                    severity="danger" 
                    text 
                    @click="confirmCancel" 
                    class="flex-1 sm:flex-none"
                  />
                </template>
              </div>

              <!-- Plan Features Recap -->
              <div class="mt-6 pt-6 border-t border-slate-100 grid grid-cols-1 sm:grid-cols-2 gap-4 text-sm">
                <div class="flex items-start gap-3">
                  <div class="bg-blue-50 p-1.5 rounded-full mt-0.5"><i class="pi pi-wallet text-blue-500 text-xs"></i></div>
                  <div>
                    <div class="text-slate-700 font-medium">{{ $t('subscription.usage.monthly_budget_title') }}</div>
                    <div class="text-slate-500 text-xs mt-0.5">${{ isEnterprise ? config.enterprise.monthlyBudgetUsd : isStarter ? config.starter.monthlyBudgetUsd : config.premium.monthlyBudgetUsd }} / {{ $t('common.month') }}</div>
                  </div>
                </div>
                <div class="flex items-start gap-3">
                  <div class="bg-purple-50 p-1.5 rounded-full mt-0.5"><i class="pi pi-tags text-purple-500 text-xs"></i></div>
                  <div>
                    <div class="text-slate-700 font-medium">{{ $t('subscription.features.session_cost_breakdown', {
                      aiCost: isEnterprise ? config.enterprise.aiEnabledSessionCostUsd : isStarter ? config.starter.aiEnabledSessionCostUsd : config.premium.aiEnabledSessionCostUsd,
                      nonAiCost: isEnterprise ? config.enterprise.aiDisabledSessionCostUsd : isStarter ? config.starter.aiDisabledSessionCostUsd : config.premium.aiDisabledSessionCostUsd
                    }) }}</div>
                    <div class="text-slate-500 text-xs mt-0.5">{{ $t('subscription.features.estimated_sessions', {
                      ai: isEnterprise ? Math.floor(config.enterprise.monthlyBudgetUsd / config.enterprise.aiEnabledSessionCostUsd) : isStarter ? starterPricingVars.aiSessions : pricingVars.aiSessions,
                      nonAi: isEnterprise ? Math.floor(config.enterprise.monthlyBudgetUsd / config.enterprise.aiDisabledSessionCostUsd) : isStarter ? starterPricingVars.nonAiSessions : pricingVars.nonAiSessions
                    }) }}</div>
                  </div>
                </div>
                <div class="flex items-start gap-3">
                  <div class="bg-emerald-50 p-1.5 rounded-full mt-0.5"><i class="pi pi-globe text-emerald-500 text-xs"></i></div>
                  <div>
                    <div class="text-slate-700 font-medium">{{ $t('subscription.features.translations') }}</div>
                    <div class="text-slate-500 text-xs mt-0.5">{{ isStarter ? $t('subscription.features.starter_translations', { count: config.starter.maxLanguages }) : $t('subscription.features.unlimited_translations') }}</div>
                  </div>
                </div>
                <div class="flex items-start gap-3">
                  <div class="bg-amber-50 p-1.5 rounded-full mt-0.5"><i class="pi pi-star text-amber-500 text-xs"></i></div>
                  <div>
                    <div class="text-slate-700 font-medium">{{ isStarter ? $t('subscription.features.branding_included') : (isEnterprise || isPremium) ? $t('subscription.features.white_label') : '' }}</div>
                    <div class="text-slate-500 text-xs mt-0.5">FunTell</div>
                  </div>
                </div>
              </div>
            </div>
            
            <!-- Usage Cards -->
            <div class="bg-white rounded-2xl shadow-sm border border-slate-200 p-6">
              <h3 class="text-lg font-bold text-slate-800 mb-6 flex items-center gap-2">
                <i class="pi pi-chart-pie text-blue-500"></i> {{ $t('subscription.usage.title') }}
              </h3>
              
              <div class="space-y-6">
                <!-- Monthly Budget (Paid users) -->
                <div>
                  <div class="flex justify-between items-end mb-2">
                    <div>
                      <div class="text-sm font-medium text-slate-600">{{ $t('subscription.usage.monthly_budget_title') }}</div>
                      <div class="text-2xl font-bold text-slate-800">
                        ${{ currentSpend.toFixed(2) }} 
                        <span class="text-sm font-normal text-slate-400">/ ${{ currentBudget }}</span>
                      </div>
                    </div>
                    <div class="text-right">
                      <div class="text-sm font-bold" :class="budgetPercent > 90 ? 'text-amber-600' : 'text-blue-600'">{{ budgetPercent }}%</div>
                    </div>
                  </div>
                  <ProgressBar :value="budgetPercent" :showValue="false" class="h-3 rounded-full bg-slate-100" :class="budgetPercent > 90 ? 'progress-warning' : ''" />
                  
                  <!-- Session breakdown -->
                  <div class="mt-4 grid grid-cols-2 gap-3">
                    <div class="bg-blue-50 rounded-lg p-3">
                      <div class="flex items-center gap-2 mb-1">
                        <i class="pi pi-microphone text-blue-500 text-sm"></i>
                        <span class="text-xs font-medium text-blue-700">{{ $t('subscription.usage.ai_spend') }}</span>
                      </div>
                      <div class="text-lg font-bold text-blue-800">${{ (chartSummary?.ai_cost_usd || 0).toFixed(2) }}</div>
                      <div class="text-xs text-blue-600">{{ chartSummary?.ai_sessions || 0 }} sessions @ ${{ subscriptionStore.aiEnabledSessionCost }}</div>
                    </div>
                    <div class="bg-slate-50 rounded-lg p-3">
                      <div class="flex items-center gap-2 mb-1">
                        <i class="pi pi-file text-slate-500 text-sm"></i>
                        <span class="text-xs font-medium text-slate-700">{{ $t('subscription.usage.non_ai_spend') }}</span>
                      </div>
                      <div class="text-lg font-bold text-slate-800">${{ (chartSummary?.non_ai_cost_usd || 0).toFixed(2) }}</div>
                      <div class="text-xs text-slate-600">{{ chartSummary?.non_ai_sessions || 0 }} sessions @ ${{ subscriptionStore.aiDisabledSessionCost }}</div>
                    </div>
                  </div>
                  
                  <div v-if="budgetPercent > 80" class="mt-4 bg-amber-50 text-amber-800 text-sm p-3 rounded-lg flex items-center gap-2">
                    <i class="pi pi-exclamation-triangle"></i>
                    <span>{{ $t('subscription.usage.running_low') }}</span>
                  </div>
                </div>
                
                <Divider />
                
                <!-- Experiences -->
                <div>
                  <div class="flex justify-between items-end mb-2">
                    <div>
                      <div class="text-sm font-medium text-slate-600">{{ $t('subscription.usage.experiences') }}</div>
                      <div class="text-2xl font-bold text-slate-800">{{ subscriptionStore.projectCount }} <span class="text-sm font-normal text-slate-400">/ {{ subscriptionStore.projectLimit }}</span></div>
                    </div>
                    <div class="text-right">
                      <div class="text-sm font-bold" :class="projectUsagePercent >= 100 ? 'text-amber-600' : 'text-emerald-600'">{{ projectUsagePercent }}%</div>
                    </div>
                  </div>
                  <ProgressBar :value="projectUsagePercent" :showValue="false" class="h-3 rounded-full bg-slate-100" :class="projectUsagePercent >= 100 ? 'progress-warning' : 'progress-success'" />
                </div>
              </div>
              
              <!-- Buy Credits CTA -->
              <div class="mt-8 pt-6 border-t border-slate-100">
                <div class="flex items-center justify-between">
                  <div>
                    <div class="font-bold text-slate-800">{{ $t('subscription.overage_cta.need_more') }}</div>
                    <div class="text-sm text-slate-500">
                      {{ $t('subscription.overage_cta.balance') }} <span class="font-bold text-amber-600">${{ creditStore.balance.toFixed(2) }} {{ $t('subscription.credits') }}</span>
                      <span class="mx-2 text-slate-300">|</span>
                      {{ $t('subscription.overage_cta.buy_visits', { count: subscriptionStore.overageAccessPerBatch, credits: subscriptionStore.overageCreditsPerBatch }) }}
                    </div>
                  </div>
                  <Button
                    :label="$t('subscription.buy_credits')"
                    icon="pi pi-plus"
                    severity="warning"
                    @click="buyCredits"
                    :loading="actionLoading"
                    size="small"
                  />
                </div>
              </div>

              <!-- Voice Credits -->
              <div class="mt-6 pt-6 border-t border-slate-100">
                <div class="flex items-center justify-between">
                  <div class="flex items-center gap-3">
                    <div class="w-9 h-9 rounded-lg bg-indigo-100 flex items-center justify-center">
                      <i class="pi pi-phone text-indigo-600 text-sm"></i>
                    </div>
                    <div>
                      <div class="font-bold text-slate-800">{{ $t('subscription.voice_credits') }}</div>
                      <div class="text-sm text-slate-500">
                        <span class="font-bold" :class="voiceCreditStore.hasCredits ? 'text-indigo-600' : 'text-red-500'">{{ voiceCreditStore.balance }}</span>
                        {{ $t('subscription.voice_credits_remaining') }}
                      </div>
                    </div>
                  </div>
                  <Button
                    :label="$t('subscription.buy_voice_credits')"
                    icon="pi pi-plus"
                    severity="help"
                    @click="selectedVoicePackages = 1; showVoiceCreditConfirmDialog = true"
                    size="small"
                  />
                </div>
              </div>
            </div>
          </div>
          
          <!-- Right Col: Daily Chart -->
          <div class="bg-white rounded-2xl shadow-sm border border-slate-200 p-6">
            <div class="flex items-center justify-between mb-6">
              <div>
                <h3 class="text-lg font-bold text-slate-800">{{ $t('subscription.traffic.title') }}</h3>
                <p class="text-sm text-slate-500">{{ $t('subscription.traffic.subtitle') }}</p>
              </div>
              <Select v-model="chartDays" :options="chartDaysOptions" optionLabel="label" optionValue="value" class="w-36 text-sm" @change="reloadChart" />
            </div>
            
                <!-- Summary Stats Grid -->
                <div v-if="chartSummary" class="grid grid-cols-3 gap-4 mb-4">
                  <div class="bg-slate-50 rounded-xl p-4 text-center">
                    <div class="text-xs font-bold text-slate-400 uppercase tracking-wider mb-1">{{ $t('subscription.traffic.total') }}</div>
                    <div class="text-xl font-bold text-slate-800">{{ chartSummary.total_access.toLocaleString() }}</div>
                  </div>
                  <div class="bg-slate-50 rounded-xl p-4 text-center">
                    <div class="text-xs font-bold text-slate-400 uppercase tracking-wider mb-1">{{ $t('subscription.traffic.peak') }}</div>
                    <div class="text-xl font-bold text-purple-600">{{ chartSummary.peak_count.toLocaleString() }}</div>
                  </div>
                  <div class="bg-slate-50 rounded-xl p-4 text-center">
                    <div class="text-xs font-bold text-slate-400 uppercase tracking-wider mb-1">{{ $t('subscription.traffic.overage') }}</div>
                    <div class="text-xl font-bold text-amber-600">{{ chartSummary.total_overage.toLocaleString() }}</div>
                  </div>
                </div>
                
                <!-- AI vs Non-AI Session Breakdown -->
                <div v-if="chartSummary && (chartSummary.ai_sessions > 0 || chartSummary.non_ai_sessions > 0)" class="grid grid-cols-2 gap-4 mb-8">
                  <div class="bg-blue-50 rounded-xl p-4">
                    <div class="flex items-center gap-2 mb-2">
                      <i class="pi pi-microphone text-blue-600"></i>
                      <span class="text-xs font-bold text-blue-600 uppercase tracking-wider">{{ $t('subscription.traffic.ai_sessions') }}</span>
                    </div>
                    <div class="text-xl font-bold text-blue-700">{{ chartSummary.ai_sessions.toLocaleString() }}</div>
                    <div class="text-sm text-blue-600">${{ chartSummary.ai_cost_usd?.toFixed(2) || '0.00' }}</div>
                  </div>
                  <div class="bg-slate-100 rounded-xl p-4">
                    <div class="flex items-center gap-2 mb-2">
                      <i class="pi pi-file text-slate-500"></i>
                      <span class="text-xs font-bold text-slate-500 uppercase tracking-wider">{{ $t('subscription.traffic.non_ai_sessions') }}</span>
                    </div>
                    <div class="text-xl font-bold text-slate-700">{{ chartSummary.non_ai_sessions.toLocaleString() }}</div>
                    <div class="text-sm text-slate-500">${{ chartSummary.non_ai_cost_usd?.toFixed(2) || '0.00' }}</div>
                  </div>
                </div>
                
                <!-- Chart -->
                <div class="h-[250px] relative">
                  <div v-if="chartData.length" class="absolute inset-0 flex flex-col">
                    <!-- Grid -->
                    <div class="flex-1 relative border-l border-b border-slate-200 ml-8 mb-6">
                      <!-- Y Axis Labels -->
                      <div class="absolute -left-8 top-0 text-xs text-slate-400 w-6 text-right">{{ maxDailyAccess }}</div>
                      <div class="absolute -left-8 top-1/2 -translate-y-1/2 text-xs text-slate-400 w-6 text-right">{{ Math.round(maxDailyAccess / 2) }}</div>
                      <div class="absolute -left-8 bottom-0 text-xs text-slate-400 w-6 text-right">0</div>
                      
                      <!-- Grid Lines -->
                      <div class="absolute top-0 left-0 right-0 h-px bg-slate-100"></div>
                      <div class="absolute top-1/2 left-0 right-0 h-px bg-slate-100 -translate-y-1/2"></div>
                      
                      <!-- Bars -->
                      <div class="absolute inset-0 flex items-end justify-between px-2 pt-4">
                        <div 
                          v-for="day in chartData" 
                          :key="day.date" 
                          class="h-full flex-1 flex items-end justify-center px-[2px] group relative"
                          @mouseenter="showTooltip(day)"
                          @mouseleave="hideTooltip"
                        >
                          <div class="w-full max-w-[24px] bg-slate-100 rounded-t-sm flex flex-col justify-end h-full relative transition-all duration-200 group-hover:bg-slate-200 overflow-hidden">
                            <!-- Overage -->
                            <div v-if="day.overage > 0" class="w-full bg-amber-400 shrink-0" :style="{ height: `${(day.overage / maxDailyAccess) * 100}%` }"></div>
                            <!-- Included -->
                            <div class="w-full bg-blue-500 shrink-0 transition-all duration-300 group-hover:bg-blue-600" :style="{ height: `${(day.included / maxDailyAccess) * 100}%` }"></div>
                          </div>
                          
                          <!-- Floating Tooltip -->
                          <div v-if="hoveredDay === day" class="absolute bottom-full mb-2 left-1/2 -translate-x-1/2 z-50 pointer-events-none">
                            <div class="bg-slate-800 text-white text-xs rounded-lg py-2 px-3 shadow-xl whitespace-nowrap">
                              <div class="font-bold border-b border-slate-600 pb-1 mb-1">{{ formatChartDate(day.date) }}</div>
                              <div class="flex justify-between gap-4"><span>{{ $t('subscription.traffic.total') }}:</span> <strong>{{ day.total }}</strong></div>
                              <div v-if="day.ai_sessions > 0" class="flex justify-between gap-4 text-blue-300"><span>{{ $t('subscription.traffic.ai_short') }}:</span> <strong>{{ day.ai_sessions }}</strong></div>
                              <div v-if="day.non_ai_sessions > 0" class="flex justify-between gap-4 text-slate-300"><span>{{ $t('subscription.traffic.non_ai_short') }}:</span> <strong>{{ day.non_ai_sessions }}</strong></div>
                              <div v-if="day.overage > 0" class="flex justify-between gap-4 text-amber-300"><span>{{ $t('subscription.traffic.overage') }}:</span> <strong>{{ day.overage }}</strong></div>
                            </div>
                            <div class="w-2 h-2 bg-slate-800 rotate-45 mx-auto -mt-1"></div>
                          </div>
                        </div>
                      </div>
                    </div>
                    
                    <!-- X Axis Labels (Adaptive) -->
                    <div class="ml-8 flex justify-between text-xs text-slate-400">
                      <span>{{ formatChartDate(chartData[0].date) }}</span>
                      <span class="hidden sm:inline">{{ formatChartDate(chartData[Math.floor(chartData.length / 2)].date) }}</span>
                      <span>{{ formatChartDate(chartData[chartData.length - 1].date) }}</span>
                    </div>
                  </div>
                  
                  <div v-else class="flex flex-col items-center justify-center h-full text-slate-400">
                    <i class="pi pi-chart-bar text-4xl mb-4 opacity-20"></i>
                    <p>{{ $t('subscription.traffic.no_data') }}</p>
                  </div>
                </div>
          </div>
        </div>
        
      </div>
      
    </div>
  </div>

  <!-- Voice Credit Purchase Confirmation Dialog -->
  <CreditConfirmationDialog
    :visible="showVoiceCreditConfirmDialog"
    @update:visible="showVoiceCreditConfirmDialog = $event"
    :creditsToConsume="totalVoiceCost"
    :currentBalance="creditStore.balance"
    :loading="voicePurchaseLoading"
    :confirmLabel="$t('subscription.buy_voice_credits')"
    :confirmationQuestion="$t('subscription.voice_credits_confirm_question')"
    @confirm="confirmVoiceCreditPurchase"
    @cancel="showVoiceCreditConfirmDialog = false"
  >
    <template #embedded-content>
      <!-- Package Card with Quantity Stepper -->
      <div class="bg-gradient-to-br from-indigo-50 to-slate-50 rounded-xl p-5 border border-indigo-200">
        <div class="flex items-center gap-3 mb-4">
          <div class="w-9 h-9 rounded-lg bg-indigo-100 flex items-center justify-center">
            <i class="pi pi-phone text-indigo-600"></i>
          </div>
          <div>
            <div class="font-semibold text-slate-900">{{ $t('subscription.voice_credits') }}</div>
            <div class="text-xs text-slate-500">{{ $t('subscription.voice_package_info', { size: voiceCreditStore.packageSize, price: voiceCreditStore.packagePriceUsd }) }}</div>
          </div>
        </div>

        <!-- Quantity Stepper -->
        <div class="flex items-center justify-between bg-white rounded-lg p-3 border border-slate-200">
          <span class="text-sm font-medium text-slate-700">{{ $t('subscription.voice_select_package') }}</span>
          <div class="flex items-center gap-1">
            <button
              @click="selectedVoicePackages = Math.max(1, selectedVoicePackages - 1)"
              :disabled="selectedVoicePackages <= 1"
              class="w-8 h-8 rounded-lg flex items-center justify-center text-lg font-bold transition-all"
              :class="selectedVoicePackages <= 1
                ? 'bg-slate-100 text-slate-300 cursor-not-allowed'
                : 'bg-slate-100 text-slate-600 hover:bg-slate-200 active:bg-slate-300'"
            >
              −
            </button>
            <input
              type="number"
              :value="selectedVoicePackages"
              @change="handleVoiceQtyInput($event)"
              min="1"
              max="10"
              class="w-12 h-8 text-center text-lg font-bold text-indigo-700 border-0 bg-transparent focus:outline-none focus:ring-0 [appearance:textfield] [&::-webkit-outer-spin-button]:appearance-none [&::-webkit-inner-spin-button]:appearance-none"
            />
            <button
              @click="selectedVoicePackages = Math.min(10, selectedVoicePackages + 1)"
              :disabled="selectedVoicePackages >= 10"
              class="w-8 h-8 rounded-lg flex items-center justify-center text-lg font-bold transition-all"
              :class="selectedVoicePackages >= 10
                ? 'bg-slate-100 text-slate-300 cursor-not-allowed'
                : 'bg-indigo-100 text-indigo-600 hover:bg-indigo-200 active:bg-indigo-300'"
            >
              +
            </button>
          </div>
        </div>

        <!-- Computed Result -->
        <div class="mt-3 flex items-center justify-between text-sm">
          <span class="text-slate-600">{{ totalVoiceCredits }} {{ $t('subscription.voice_credits_balance') }}</span>
          <span class="text-lg font-bold text-indigo-700">${{ totalVoiceCost.toFixed(2) }}</span>
        </div>
      </div>

      <!-- Balance Impact -->
      <div class="rounded-xl border border-slate-200 overflow-hidden">
        <div class="flex">
          <div class="flex-1 p-3 text-center border-r border-slate-200">
            <div class="text-xs text-slate-500 mb-1">{{ $t('batches.current_balance') }}</div>
            <div class="text-base font-bold text-slate-900">${{ creditStore.balance.toFixed(2) }}</div>
          </div>
          <div class="flex-none px-3 flex items-center text-slate-400">
            <i class="pi pi-arrow-right text-xs"></i>
          </div>
          <div class="flex-1 p-3 text-center">
            <div class="text-xs text-slate-500 mb-1">{{ $t('batches.after_consumption') }}</div>
            <div class="text-base font-bold" :class="creditStore.balance - totalVoiceCost < 0 ? 'text-red-600' : creditStore.balance - totalVoiceCost < 20 ? 'text-orange-600' : 'text-green-600'">
              ${{ (creditStore.balance - totalVoiceCost).toFixed(2) }}
            </div>
          </div>
        </div>
      </div>

      <!-- Insufficient / Low Balance Warning -->
      <div v-if="creditStore.balance - totalVoiceCost < 0" class="bg-red-50 border border-red-300 rounded-lg p-3">
        <div class="flex items-center gap-2">
          <i class="pi pi-exclamation-circle text-red-600"></i>
          <span class="text-sm text-red-800">{{ $t('subscription.voice_insufficient_balance') }}</span>
        </div>
      </div>
      <div v-else-if="creditStore.balance - totalVoiceCost < 20" class="bg-yellow-50 border border-yellow-300 rounded-lg p-3">
        <div class="flex items-center gap-2">
          <i class="pi pi-info-circle text-yellow-600"></i>
          <span class="text-sm text-yellow-800">{{ $t('batches.low_balance_warning') }}</span>
        </div>
      </div>
    </template>
  </CreditConfirmationDialog>
</template>

<style scoped>
:deep(.p-progressbar) {
  background-color: #f1f5f9;
}
:deep(.progress-warning .p-progressbar-value) {
  background: #f59e0b;
}
:deep(.progress-danger .p-progressbar-value) {
  background: #ef4444;
}
:deep(.progress-success .p-progressbar-value) {
  background: #10b981;
}
</style>