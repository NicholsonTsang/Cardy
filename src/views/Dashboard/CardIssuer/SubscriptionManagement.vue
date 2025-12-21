<script setup lang="ts">
import { onMounted, computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute, useRouter } from 'vue-router';
import { useSubscriptionStore, type DailyAccessData } from '@/stores/subscription';
import { useCreditStore } from '@/stores/credits';
import { useToast } from 'primevue/usetoast';
import Card from 'primevue/card';
import Button from 'primevue/button';
import ProgressBar from 'primevue/progressbar';
import Tag from 'primevue/tag';
import Divider from 'primevue/divider';
import ConfirmDialog from 'primevue/confirmdialog';
import { useConfirm } from 'primevue/useconfirm';
import Select from 'primevue/select';

const { t } = useI18n();
const route = useRoute();
const router = useRouter(); // Initialize router
const toast = useToast();
const confirm = useConfirm();
const subscriptionStore = useSubscriptionStore();
const creditStore = useCreditStore(); // Initialize credit store

// Chart state
const chartDays = ref(30);
const chartDaysOptions = computed(() => [
  { label: t('subscription.chart.last_7_days'), value: 7 },
  { label: t('subscription.chart.last_14_days'), value: 14 },
  { label: t('subscription.chart.last_30_days'), value: 30 }
]);

// Interactive chart state
const hoveredDay = ref<DailyAccessData | null>(null);
const tooltipStyle = ref({ top: '0px', left: '0px' });

function showTooltip(day: DailyAccessData, event: MouseEvent) {
  hoveredDay.value = day;
  const target = event.currentTarget as HTMLElement;
  const rect = target.getBoundingClientRect();
  const parentRect = target.parentElement?.parentElement?.getBoundingClientRect();
  
  if (parentRect) {
    // Position relative to the chart container
    tooltipStyle.value = {
      top: '-45px', // Fixed height above bar
      left: `${(target.offsetLeft + target.offsetWidth / 2)}px` // Centered on bar
    };
  }
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
  
  if (success === 'true') {
    if (type === 'subscription') {
      toast.add({
        severity: 'success',
        summary: t('subscription.messages.welcome_premium'),
        detail: t('subscription.messages.subscription_active'),
        life: 5000
      });
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
  
  // Fetch subscription data
  await subscriptionStore.fetchSubscription();
  
  // Fetch credit balance
  await creditStore.fetchCreditBalance();
  
  // Fetch daily stats for chart
  await subscriptionStore.fetchDailyStats(chartDays.value);
});

// Reload chart when days change
async function reloadChart() {
  await subscriptionStore.fetchDailyStats(chartDays.value);
}

// Computed
const isPremium = computed(() => subscriptionStore.isPremium);
const subscription = computed(() => subscriptionStore.subscription);
const loading = computed(() => subscriptionStore.loading || creditStore.loading);
const config = computed(() => subscriptionStore.config);
const creditBalance = computed(() => creditStore.balance); // Added credit balance

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

const experienceUsagePercent = computed(() => {
  const used = subscriptionStore.experienceCount;
  const limit = subscriptionStore.experienceLimit;
  if (!limit) return 0;
  return Math.min(100, Math.round((used / limit) * 100));
});

const periodEndFormatted = computed(() => {
  const date = subscriptionStore.periodEndDate;
  if (!date) return null;
  return date.toLocaleDateString('en-US', { 
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

function formatChartDay(dateStr: string) {
  const date = new Date(dateStr);
  return date.toLocaleDateString(undefined, { day: 'numeric' });
}

// Actions
async function upgradeToPremium() {
  const result = await subscriptionStore.createCheckout();
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

function confirmCancel() {
  confirm.require({
    message: t('subscription.messages.confirm_cancel'),
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
      detail: t('subscription.messages.will_continue'),
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
      <div v-if="isPremium" class="flex gap-2">
        <Tag v-if="subscriptionStore.isScheduledForCancellation" severity="warning" :value="$t('subscription.status.cancellation_scheduled')" icon="pi pi-exclamation-circle" rounded />
        <Tag v-else severity="success" :value="$t('subscription.status.premium_active')" icon="pi pi-check-circle" rounded />
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
      <div v-if="!isPremium" class="space-y-8">
        
        <!-- Usage Stats (Compact) -->
        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div class="bg-white p-5 rounded-xl shadow-sm border border-slate-100">
            <div class="flex justify-between items-center mb-3">
              <span class="text-slate-600 font-medium">{{ $t('subscription.usage.experiences') }}</span>
              <span class="text-slate-800 font-bold">{{ subscriptionStore.experienceCount }} / {{ subscriptionStore.experienceLimit }}</span>
            </div>
            <ProgressBar :value="experienceUsagePercent" :showValue="false" class="h-2" :class="experienceUsagePercent >= 100 ? 'progress-danger' : ''" />
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
        <div class="grid grid-cols-1 lg:grid-cols-2 gap-8 items-start">
          
          <!-- Current Free Plan -->
          <div class="bg-white rounded-2xl p-6 border border-slate-200 shadow-sm relative overflow-hidden">
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
            <ul class="space-y-4 text-sm">
              <li class="flex items-center gap-3">
                <i class="pi pi-check text-slate-600"></i>
                <span class="text-slate-700">{{ $t('subscription.features.experience_limit', { limit: config.free.experienceLimit }) }}</span>
              </li>
              <li class="flex items-center gap-3">
                <i class="pi pi-check text-slate-600"></i>
                <span class="text-slate-700"><strong>{{ config.free.monthlyAccessLimit }}</strong> {{ $t('subscription.usage.monthly_access') }}</span>
              </li>
              <li class="flex items-center gap-3 opacity-50">
                <i class="pi pi-times text-slate-400"></i>
                <span class="text-slate-500">{{ $t('subscription.features.no_translations') }}</span>
              </li>
              <li class="flex items-center gap-3 opacity-50">
                <i class="pi pi-times text-slate-400"></i>
                <span class="text-slate-500">{{ $t('subscription.features.no_overage') }}</span>
              </li>
            </ul>
          </div>
          
          <!-- Premium Plan -->
          <div class="bg-gradient-to-b from-slate-900 to-slate-800 rounded-2xl p-6 shadow-xl relative overflow-hidden text-white transform hover:scale-[1.02] transition-transform duration-300">
            <div class="absolute top-0 right-0 p-0">
              <div class="bg-gradient-to-r from-amber-400 to-orange-500 text-white text-xs font-bold px-3 py-1 rounded-bl-xl shadow-lg uppercase">{{ $t('subscription.recommended') }}</div>
            </div>
            <div class="mb-6">
              <div class="w-12 h-12 rounded-xl bg-white/10 flex items-center justify-center mb-4 backdrop-blur-sm">
                <i class="pi pi-star-fill text-xl text-amber-400"></i>
              </div>
              <h2 class="text-2xl font-bold text-white">{{ $t('subscription.premium_plan') }}</h2>
              <div class="text-3xl font-extrabold text-white mt-2">${{ config.premium.monthlyFeeUsd }} <span class="text-base font-normal text-slate-400">/mo</span></div>
            </div>
            <ul class="space-y-4 text-sm mb-8">
              <li class="flex items-center gap-3">
                <div class="bg-emerald-500/20 p-1 rounded-full"><i class="pi pi-check text-emerald-400 text-xs"></i></div>
                <span class="text-slate-100">{{ $t('subscription.features.unlimited_experiences', { limit: config.premium.experienceLimit }) }}</span>
              </li>
              <li class="flex items-center gap-3">
                <div class="bg-emerald-500/20 p-1 rounded-full"><i class="pi pi-check text-emerald-400 text-xs"></i></div>
                <span class="text-slate-100"><strong>{{ config.premium.monthlyAccessLimit.toLocaleString() }}</strong> {{ $t('subscription.usage.monthly_access') }} ({{ $t('subscription.usage.monthly_pool_info') }})</span>
              </li>
              <li class="flex items-center gap-3">
                <div class="bg-emerald-500/20 p-1 rounded-full"><i class="pi pi-check text-emerald-400 text-xs"></i></div>
                <span class="text-slate-100">{{ $t('subscription.features.translations') }}</span>
              </li>
              <li class="flex items-center gap-3">
                <div class="bg-emerald-500/20 p-1 rounded-full"><i class="pi pi-check text-emerald-400 text-xs"></i></div>
                <span class="text-slate-100">{{ $t('subscription.features.overage') }}</span>
              </li>
            </ul>
            <Button 
              :label="$t('subscription.upgrade')" 
              class="w-full bg-white text-slate-900 border-0 hover:bg-slate-100 font-bold"
              @click="upgradeToPremium"
              :loading="loading"
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
                  @mouseenter="(e) => showTooltip(day, e)"
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
      
      <!-- ============ PREMIUM USER VIEW ============ -->
      <div v-else class="space-y-8">
        
        <div class="grid grid-cols-1 xl:grid-cols-2 gap-8">
          <!-- Left Col: Plan & Usage -->
          <div class="space-y-8">
            <!-- Premium Plan Status -->
            <div class="bg-white rounded-2xl shadow-sm border border-slate-200 p-6">
              <div class="flex justify-between items-start mb-6">
                <div class="flex items-center gap-4">
                  <div class="w-14 h-14 rounded-2xl bg-gradient-to-br from-amber-400 to-amber-600 flex items-center justify-center shadow-md">
                    <i class="pi pi-star-fill text-2xl text-white"></i>
                  </div>
                  <div>
                    <h2 class="text-xl font-bold text-slate-800">{{ $t('subscription.premium_plan') }}</h2>
                    <div class="text-sm text-slate-500 mt-1" v-if="periodEndFormatted">
                      <span v-if="subscriptionStore.isScheduledForCancellation" class="text-amber-600 font-medium">{{ $t('subscription.billing.access_until') }} {{ periodEndFormatted }}</span>
                      <span v-else>{{ $t('subscription.billing.next_billing') }} {{ periodEndFormatted }}</span>
                    </div>
                  </div>
                </div>
                <div class="text-right">
                  <div class="text-2xl font-bold text-slate-800">${{ config.premium.monthlyFeeUsd }}</div>
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
                    :loading="loading" 
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
            </div>
            
            <!-- Usage Cards -->
            <div class="bg-white rounded-2xl shadow-sm border border-slate-200 p-6">
              <h3 class="text-lg font-bold text-slate-800 mb-6 flex items-center gap-2">
                <i class="pi pi-chart-pie text-blue-500"></i> {{ $t('subscription.usage.title') }}
              </h3>
              
              <div class="space-y-6">
                <!-- Monthly Access -->
                <div>
                  <div class="flex justify-between items-end mb-2">
                    <div>
                      <div class="text-sm font-medium text-slate-600">{{ $t('subscription.usage.monthly_access') }}</div>
                      <div class="text-2xl font-bold text-slate-800">{{ subscriptionStore.monthlyAccessUsed.toLocaleString() }} <span class="text-sm font-normal text-slate-400">/ {{ subscriptionStore.monthlyAccessLimit.toLocaleString() }}</span></div>
                    </div>
                    <div class="text-right">
                      <div class="text-sm font-bold" :class="usagePercent > 90 ? 'text-amber-600' : 'text-blue-600'">{{ usagePercent }}%</div>
                    </div>
                  </div>
                  <ProgressBar :value="usagePercent" :showValue="false" class="h-3 rounded-full bg-slate-100" :class="usagePercent > 90 ? 'progress-warning' : ''" />
                  
                  <div v-if="subscriptionStore.monthlyAccessRemaining !== null && subscriptionStore.monthlyAccessRemaining < 500" class="mt-3 bg-amber-50 text-amber-800 text-sm p-3 rounded-lg flex items-center gap-2">
                    <i class="pi pi-exclamation-triangle"></i>
                    <span>{{ $t('subscription.usage.running_low') }}</span>
                  </div>
                </div>
                
                <!-- Experiences -->
                <div>
                  <div class="flex justify-between items-end mb-2">
                    <div>
                      <div class="text-sm font-medium text-slate-600">{{ $t('subscription.usage.experiences') }}</div>
                      <div class="text-2xl font-bold text-slate-800">{{ subscriptionStore.experienceCount }} <span class="text-sm font-normal text-slate-400">/ {{ subscriptionStore.experienceLimit }}</span></div>
                    </div>
                    <div class="text-right">
                      <div class="text-sm font-bold" :class="experienceUsagePercent >= 100 ? 'text-amber-600' : 'text-emerald-600'">{{ experienceUsagePercent }}%</div>
                    </div>
                  </div>
                  <ProgressBar :value="experienceUsagePercent" :showValue="false" class="h-3 rounded-full bg-slate-100" :class="experienceUsagePercent >= 100 ? 'progress-warning' : 'progress-success'" />
                </div>
              </div>
              
              <!-- Buy Credits CTA -->
              <div class="mt-8 pt-6 border-t border-slate-100">
                <div class="flex items-center justify-between">
                  <div>
                    <div class="font-bold text-slate-800">{{ $t('subscription.overage_cta.need_more') }}</div>
                    <div class="text-sm text-slate-500">
                      {{ $t('subscription.overage_cta.balance') }} <span class="font-bold text-amber-600">{{ creditBalance }} {{ $t('subscription.credits') }}</span>
                      <span class="mx-2 text-slate-300">|</span>
                      {{ $t('subscription.overage_cta.buy_visits', { count: config.overage.accessPerBatch, credits: config.overage.creditsPerBatch }) }}
                    </div>
                  </div>
                  <Button 
                    :label="$t('subscription.buy_credits')" 
                    icon="pi pi-plus" 
                    severity="warning" 
                    @click="buyCredits" 
                    :loading="loading" 
                    size="small"
                  />
                </div>
              </div>
            </div>
          </div>
          
          <!-- Right Col: Daily Chart -->
          <div class="bg-white rounded-2xl shadow-sm border border-slate-200 p-6 flex flex-col h-full">
            <div class="flex items-center justify-between mb-6">
              <div>
                <h3 class="text-lg font-bold text-slate-800">{{ $t('subscription.traffic.title') }}</h3>
                <p class="text-sm text-slate-500">{{ $t('subscription.traffic.subtitle') }}</p>
              </div>
              <Select v-model="chartDays" :options="chartDaysOptions" optionLabel="label" optionValue="value" class="w-36 text-sm" @change="reloadChart" />
            </div>
            
                <!-- Summary Stats Grid -->
                <div v-if="chartSummary" class="grid grid-cols-3 gap-4 mb-8">
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
                
                <!-- Chart -->
                <div class="flex-1 min-h-[300px] relative">
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
                          @mouseenter="(e) => showTooltip(day, e)"
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