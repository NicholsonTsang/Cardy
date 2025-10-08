<template>
  <PageWrapper :title="$t('admin.admin_dashboard')" :description="$t('admin.system_overview')">
    <template #actions>
      <Button 
        icon="pi pi-refresh" 
        :label="$t('admin.refresh_data')" 
        severity="secondary"
        outlined
        @click="refreshData"
        :loading="isLoading"
        class="text-blue-600 border-blue-600 hover:bg-blue-50"
      />
    </template>
    
    <div class="space-y-8">
      <!-- Quick Actions Section -->
      <div class="bg-white rounded-xl shadow-lg border border-slate-200 p-6">
        <div class="flex items-center justify-between mb-6">
          <h2 class="text-xl font-bold text-slate-900">{{ $t('admin.quick_actions') }}</h2>
        </div>
        
        <div class="grid grid-cols-2 md:grid-cols-3 gap-4">
          <router-link :to="{ name: 'admin-print-requests' }" class="block">
            <div class="bg-gradient-to-r from-blue-50 to-blue-100 border border-blue-200 rounded-xl p-4 hover:from-blue-100 hover:to-blue-200 transition-colors">
              <div class="flex items-center gap-3">
                <div class="w-8 h-8 rounded-lg bg-blue-500 flex items-center justify-center">
                  <i class="pi pi-print text-white text-sm"></i>
                </div>
                <div>
                  <p class="text-sm font-medium text-blue-800">{{ $t('admin.manage_print_requests') }}</p>
                  <p class="text-xs text-blue-600">{{ stats.print_requests_submitted }} {{ $t('admin.submitted') }}</p>
                </div>
              </div>
            </div>
          </router-link>
          
          <router-link :to="{ name: 'admin-batches' }" class="block">
            <div class="bg-gradient-to-r from-purple-50 to-purple-100 border border-purple-200 rounded-xl p-4 hover:from-purple-100 hover:to-purple-200 transition-colors">
              <div class="flex items-center gap-3">
                <div class="w-8 h-8 rounded-lg bg-purple-500 flex items-center justify-center">
                  <i class="pi pi-box text-white text-sm"></i>
                </div>
                <div>
                  <p class="text-sm font-medium text-purple-800">{{ $t('admin.manage_batches') }}</p>
                  <p class="text-xs text-purple-600">{{ $t('admin.view_all_batches') }}</p>
                </div>
              </div>
            </div>
          </router-link>
          
          <router-link :to="{ name: 'admin-history-logs' }" class="block">
            <div class="bg-gradient-to-r from-slate-50 to-slate-100 border border-slate-200 rounded-xl p-4 hover:from-slate-100 hover:to-slate-200 transition-colors">
              <div class="flex items-center gap-3">
                <div class="w-8 h-8 rounded-lg bg-slate-500 flex items-center justify-center">
                  <i class="pi pi-history text-white text-sm"></i>
                </div>
                <div>
                  <p class="text-sm font-medium text-slate-800">{{ $t('admin.view_history_logs') }}</p>
                  <p class="text-xs text-slate-600">{{ $t('admin.all_admin_actions') }}</p>
                </div>
              </div>
            </div>
          </router-link>
        </div>
      </div>

      <!-- User Management Section -->
      <div>
        <h2 class="text-base sm:text-lg font-semibold text-slate-900 mb-3 sm:mb-4 flex items-center gap-2">
          <i class="pi pi-users text-blue-600 text-sm sm:text-base"></i>
          <span class="truncate">{{ $t('admin.user_management') }}</span>
        </h2>
        <div class="grid grid-cols-2 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 xl:grid-cols-6 gap-3 sm:gap-4">
          <template v-if="isLoadingStats">
            <div v-for="i in 6" :key="i" class="bg-white rounded-lg sm:rounded-xl shadow-lg p-3 sm:p-4 border border-slate-200 animate-pulse">
              <div class="h-16 sm:h-20"></div>
            </div>
          </template>
          <template v-else>
            <!-- Total Users -->
            <div class="bg-white rounded-lg sm:rounded-xl shadow-lg border border-slate-200 p-3 sm:p-4 hover:shadow-xl transition-all duration-200">
              <div class="flex items-start justify-between gap-2">
                <div class="min-w-0 flex-1">
                  <p class="text-[10px] sm:text-xs font-medium text-slate-600 mb-1 truncate leading-tight">{{ $t('admin.total_users') }}</p>
                  <h3 class="text-base sm:text-lg md:text-xl font-bold text-slate-900 truncate">{{ stats.total_users }}</h3>
                </div>
                <div class="w-7 h-7 sm:w-8 sm:h-8 rounded-md sm:rounded-lg bg-gradient-to-br from-blue-500 to-blue-600 flex items-center justify-center shadow-md sm:shadow-lg flex-shrink-0">
                  <i class="pi pi-users text-white text-xs sm:text-sm"></i>
                </div>
              </div>
              <div class="mt-1.5 sm:mt-2">
                <span class="text-[10px] sm:text-xs text-slate-500 truncate block">{{ $t('admin.all_registered') }}</span>
              </div>
            </div>

            <!-- Daily New Users -->
            <div class="bg-white rounded-lg sm:rounded-xl shadow-lg border border-slate-200 p-3 sm:p-4 hover:shadow-xl transition-all duration-200">
              <div class="flex items-start justify-between gap-2">
                <div class="min-w-0 flex-1">
                  <p class="text-[10px] sm:text-xs font-medium text-slate-600 mb-1 truncate leading-tight">{{ $t('admin.daily_new') }}</p>
                  <h3 class="text-base sm:text-lg md:text-xl font-bold text-slate-900 truncate">{{ stats.daily_new_users }}</h3>
                </div>
                <div class="w-7 h-7 sm:w-8 sm:h-8 rounded-md sm:rounded-lg bg-gradient-to-br from-cyan-500 to-cyan-600 flex items-center justify-center shadow-md sm:shadow-lg flex-shrink-0">
                  <i class="pi pi-user-plus text-white text-xs sm:text-sm"></i>
                </div>
              </div>
              <div class="mt-1.5 sm:mt-2">
                <span class="text-[10px] sm:text-xs text-slate-500 truncate block">{{ $t('admin.today') }}</span>
              </div>
            </div>

            <!-- Weekly New Users -->
            <div class="bg-white rounded-lg sm:rounded-xl shadow-lg border border-slate-200 p-3 sm:p-4 hover:shadow-xl transition-all duration-200">
              <div class="flex items-start justify-between gap-2">
                <div class="min-w-0 flex-1">
                  <p class="text-[10px] sm:text-xs font-medium text-slate-600 mb-1 truncate leading-tight">{{ $t('admin.weekly_new') }}</p>
                  <h3 class="text-base sm:text-lg md:text-xl font-bold text-slate-900 truncate">{{ stats.weekly_new_users }}</h3>
                </div>
                <div class="w-7 h-7 sm:w-8 sm:h-8 rounded-md sm:rounded-lg bg-gradient-to-br from-sky-500 to-sky-600 flex items-center justify-center shadow-md sm:shadow-lg flex-shrink-0">
                  <i class="pi pi-calendar-plus text-white text-xs sm:text-sm"></i>
                </div>
              </div>
              <div class="mt-1.5 sm:mt-2">
                <span class="text-[10px] sm:text-xs text-slate-500 truncate block">{{ $t('admin.last_7_days') }}</span>
              </div>
            </div>

            <!-- Monthly New Users -->
            <div class="bg-white rounded-lg sm:rounded-xl shadow-lg border border-slate-200 p-3 sm:p-4 hover:shadow-xl transition-all duration-200">
              <div class="flex items-start justify-between gap-2">
                <div class="min-w-0 flex-1">
                  <p class="text-[10px] sm:text-xs font-medium text-slate-600 mb-1 truncate leading-tight">{{ $t('admin.monthly_new') }}</p>
                  <h3 class="text-base sm:text-lg md:text-xl font-bold text-slate-900 truncate">{{ stats.monthly_new_users }}</h3>
                </div>
                <div class="w-7 h-7 sm:w-8 sm:h-8 rounded-md sm:rounded-lg bg-gradient-to-br from-violet-500 to-violet-600 flex items-center justify-center shadow-md sm:shadow-lg flex-shrink-0">
                  <i class="pi pi-user-edit text-white text-xs sm:text-sm"></i>
                </div>
              </div>
              <div class="mt-1.5 sm:mt-2">
                <span class="text-[10px] sm:text-xs text-slate-500 truncate block">{{ $t('admin.last_30_days') }}</span>
              </div>
            </div>
          </template>
        </div>
      </div>

      <!-- Print Request Management Section -->
      <div>
        <h2 class="text-lg font-semibold text-slate-900 mb-4 flex items-center gap-2">
          <i class="pi pi-print text-blue-600"></i>
          {{ $t('admin.print_request_pipeline') }}
        </h2>
        <div class="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-4">
          <template v-if="isLoadingStats">
            <div v-for="i in 3" :key="i" class="bg-white rounded-xl shadow-lg p-4 border border-slate-200 animate-pulse">
              <div class="h-20"></div>
            </div>
          </template>
          <template v-else>
            <!-- Print Requests Submitted -->
            <div class="bg-white rounded-xl shadow-lg border border-slate-200 p-4 hover:shadow-xl transition-shadow duration-200">
              <div class="flex items-center justify-between">
                <div class="min-w-0 flex-1">
                  <p class="text-xs font-medium text-slate-600 mb-1 truncate">{{ $t('admin.print_submitted') }}</p>
                  <h3 class="text-lg font-bold text-slate-900">{{ stats.print_requests_submitted }}</h3>
                </div>
                <div class="w-8 h-8 rounded-lg bg-gradient-to-br from-orange-500 to-orange-600 flex items-center justify-center shadow-lg flex-shrink-0 ml-2">
                  <i class="pi pi-send text-white text-sm"></i>
                </div>
              </div>
              <div class="mt-2">
                <router-link :to="{ name: 'admin-print-requests' }" class="inline-flex items-center text-xs font-medium text-orange-600 hover:text-orange-700 transition-colors">
                  {{ $t('admin.process') }}
                  <i class="pi pi-arrow-right ml-1 text-xs"></i>
                </router-link>
              </div>
            </div>

            <!-- Print Requests Processing -->
            <div class="bg-white rounded-xl shadow-lg border border-slate-200 p-4 hover:shadow-xl transition-shadow duration-200">
              <div class="flex items-center justify-between">
                <div class="min-w-0 flex-1">
                  <p class="text-xs font-medium text-slate-600 mb-1 truncate">{{ $t('admin.print_processing') }}</p>
                  <h3 class="text-lg font-bold text-slate-900">{{ stats.print_requests_processing }}</h3>
                </div>
                <div class="w-8 h-8 rounded-lg bg-gradient-to-br from-blue-500 to-blue-600 flex items-center justify-center shadow-lg flex-shrink-0 ml-2">
                  <i class="pi pi-cog text-white text-sm"></i>
                </div>
              </div>
              <div class="mt-2">
                <router-link :to="{ name: 'admin-print-requests' }" class="inline-flex items-center text-xs font-medium text-blue-600 hover:text-blue-700 transition-colors">
                  {{ $t('admin.track') }}
                  <i class="pi pi-arrow-right ml-1 text-xs"></i>
                </router-link>
              </div>
            </div>

            <!-- Print Requests Shipping -->
            <div class="bg-white rounded-xl shadow-lg border border-slate-200 p-4 hover:shadow-xl transition-shadow duration-200">
              <div class="flex items-center justify-between">
                <div class="min-w-0 flex-1">
                  <p class="text-xs font-medium text-slate-600 mb-1 truncate">{{ $t('admin.print_shipping') }}</p>
                  <h3 class="text-lg font-bold text-slate-900">{{ stats.print_requests_shipping }}</h3>
                </div>
                <div class="w-8 h-8 rounded-lg bg-gradient-to-br from-green-500 to-green-600 flex items-center justify-center shadow-lg flex-shrink-0 ml-2">
                  <i class="pi pi-truck text-white text-sm"></i>
                </div>
              </div>
              <div class="mt-2">
                <router-link :to="{ name: 'admin-print-requests' }" class="inline-flex items-center text-xs font-medium text-green-600 hover:text-green-700 transition-colors">
                  {{ $t('admin.monitor') }}
                  <i class="pi pi-arrow-right ml-1 text-xs"></i>
                </router-link>
              </div>
            </div>
          </template>
        </div>
      </div>

      <!-- Revenue Analytics Section -->
      <div>
        <h2 class="text-lg font-semibold text-slate-900 mb-4 flex items-center gap-2">
          <i class="pi pi-chart-line text-blue-600"></i>
          {{ $t('admin.revenue_analytics') }}
        </h2>
        <div class="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-4">
          <template v-if="isLoadingStats">
            <div v-for="i in 3" :key="i" class="bg-white rounded-xl shadow-lg p-4 border border-slate-200 animate-pulse">
              <div class="h-20"></div>
            </div>
          </template>
          <template v-else>
            <!-- Daily Revenue -->
            <div class="bg-white rounded-xl shadow-lg border border-slate-200 p-4 hover:shadow-xl transition-shadow duration-200">
              <div class="flex items-center justify-between">
                <div class="min-w-0 flex-1">
                  <p class="text-xs font-medium text-slate-600 mb-1 truncate">{{ $t('admin.daily_revenue') }}</p>
                  <h3 class="text-lg font-bold text-slate-900 truncate">{{ formatRevenue(stats.daily_revenue_cents) }}</h3>
                </div>
                <div class="w-8 h-8 rounded-lg bg-gradient-to-br from-emerald-500 to-emerald-600 flex items-center justify-center shadow-lg flex-shrink-0 ml-2">
                  <i class="pi pi-calendar text-white text-sm"></i>
                </div>
              </div>
              <div class="mt-2">
                <span class="text-xs text-slate-500">{{ $t('admin.today') }}</span>
              </div>
            </div>

            <!-- Weekly Revenue -->
            <div class="bg-white rounded-xl shadow-lg border border-slate-200 p-4 hover:shadow-xl transition-shadow duration-200">
              <div class="flex items-center justify-between">
                <div class="min-w-0 flex-1">
                  <p class="text-xs font-medium text-slate-600 mb-1 truncate">{{ $t('admin.weekly_revenue') }}</p>
                  <h3 class="text-lg font-bold text-slate-900 truncate">{{ formatRevenue(stats.weekly_revenue_cents) }}</h3>
                </div>
                <div class="w-8 h-8 rounded-lg bg-gradient-to-br from-purple-500 to-purple-600 flex items-center justify-center shadow-lg flex-shrink-0 ml-2">
                  <i class="pi pi-chart-line text-white text-sm"></i>
                </div>
              </div>
              <div class="mt-2">
                <span class="text-xs text-slate-500">{{ $t('admin.last_7_days') }}</span>
              </div>
            </div>

            <!-- Monthly Revenue -->
            <div class="bg-white rounded-xl shadow-lg border border-slate-200 p-4 hover:shadow-xl transition-shadow duration-200">
              <div class="flex items-center justify-between">
                <div class="min-w-0 flex-1">
                  <p class="text-xs font-medium text-slate-600 mb-1 truncate">{{ $t('admin.monthly_revenue') }}</p>
                  <h3 class="text-lg font-bold text-slate-900 truncate">{{ formatRevenue(stats.monthly_revenue_cents) }}</h3>
                </div>
                <div class="w-8 h-8 rounded-lg bg-gradient-to-br from-indigo-500 to-indigo-600 flex items-center justify-center shadow-lg flex-shrink-0 ml-2">
                  <i class="pi pi-dollar text-white text-sm"></i>
                </div>
              </div>
              <div class="mt-2">
                <span class="text-xs text-slate-500">{{ $t('admin.last_30_days') }}</span>
              </div>
            </div>
          </template>
        </div>
      </div>

      <!-- Card Design Growth Section -->
      <div>
        <h2 class="text-lg font-semibold text-slate-900 mb-4 flex items-center gap-2">
          <i class="pi pi-id-card text-blue-600"></i>
          {{ $t('admin.card_design_growth') }}
        </h2>
        <div class="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-4">
          <template v-if="isLoadingStats">
            <div v-for="i in 3" :key="i" class="bg-white rounded-xl shadow-lg p-4 border border-slate-200 animate-pulse">
              <div class="h-20"></div>
            </div>
          </template>
          <template v-else>
            <!-- Daily New Cards -->
            <div class="bg-white rounded-xl shadow-lg border border-slate-200 p-4 hover:shadow-xl transition-shadow duration-200">
              <div class="flex items-center justify-between">
                <div class="min-w-0 flex-1">
                  <p class="text-xs font-medium text-slate-600 mb-1 truncate">{{ $t('admin.daily_new_cards') }}</p>
                  <h3 class="text-lg font-bold text-slate-900">{{ stats.daily_new_cards }}</h3>
                </div>
                <div class="w-8 h-8 rounded-lg bg-gradient-to-br from-rose-500 to-rose-600 flex items-center justify-center shadow-lg flex-shrink-0 ml-2">
                  <i class="pi pi-id-card text-white text-sm"></i>
                </div>
              </div>
              <div class="mt-2">
                <span class="text-xs text-slate-500">{{ $t('admin.today') }}</span>
              </div>
            </div>

            <!-- Weekly New Cards -->
            <div class="bg-white rounded-xl shadow-lg border border-slate-200 p-4 hover:shadow-xl transition-shadow duration-200">
              <div class="flex items-center justify-between">
                <div class="min-w-0 flex-1">
                  <p class="text-xs font-medium text-slate-600 mb-1 truncate">{{ $t('admin.weekly_new_cards') }}</p>
                  <h3 class="text-lg font-bold text-slate-900">{{ stats.weekly_new_cards }}</h3>
                </div>
                <div class="w-8 h-8 rounded-lg bg-gradient-to-br from-pink-500 to-pink-600 flex items-center justify-center shadow-lg flex-shrink-0 ml-2">
                  <i class="pi pi-credit-card text-white text-sm"></i>
                </div>
              </div>
              <div class="mt-2">
                <span class="text-xs text-slate-500">{{ $t('admin.last_7_days') }}</span>
              </div>
            </div>

            <!-- Monthly New Cards -->
            <div class="bg-white rounded-xl shadow-lg border border-slate-200 p-4 hover:shadow-xl transition-shadow duration-200">
              <div class="flex items-center justify-between">
                <div class="min-w-0 flex-1">
                  <p class="text-xs font-medium text-slate-600 mb-1 truncate">{{ $t('admin.monthly_new_cards') }}</p>
                  <h3 class="text-lg font-bold text-slate-900">{{ stats.monthly_new_cards }}</h3>
                </div>
                <div class="w-8 h-8 rounded-lg bg-gradient-to-br from-amber-500 to-amber-600 flex items-center justify-center shadow-lg flex-shrink-0 ml-2">
                  <i class="pi pi-clone text-white text-sm"></i>
                </div>
              </div>
              <div class="mt-2">
                <span class="text-xs text-slate-500">{{ $t('admin.last_30_days') }}</span>
              </div>
            </div>
          </template>
        </div>
      </div>

      <!-- Card Issuance Trends Section -->
      <div>
        <h2 class="text-lg font-semibold text-slate-900 mb-4 flex items-center gap-2">
          <i class="pi pi-share-alt text-blue-600"></i>
          {{ $t('admin.card_issuance_trends') }}
        </h2>
        <div class="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-4">
          <template v-if="isLoadingStats">
            <div v-for="i in 3" :key="i" class="bg-white rounded-xl shadow-lg p-4 border border-slate-200 animate-pulse">
              <div class="h-20"></div>
            </div>
          </template>
          <template v-else>
            <!-- Daily Issued Cards -->
            <div class="bg-white rounded-xl shadow-lg border border-slate-200 p-4 hover:shadow-xl transition-shadow duration-200">
              <div class="flex items-center justify-between">
                <div class="min-w-0 flex-1">
                  <p class="text-xs font-medium text-slate-600 mb-1 truncate">{{ $t('admin.daily_issued_cards') }}</p>
                  <h3 class="text-lg font-bold text-slate-900">{{ stats.daily_issued_cards }}</h3>
                </div>
                <div class="w-8 h-8 rounded-lg bg-gradient-to-br from-teal-500 to-teal-600 flex items-center justify-center shadow-lg flex-shrink-0 ml-2">
                  <i class="pi pi-send text-white text-sm"></i>
                </div>
              </div>
              <div class="mt-2">
                <span class="text-xs text-slate-500">{{ $t('admin.today') }}</span>
              </div>
            </div>

            <!-- Weekly Issued Cards -->
            <div class="bg-white rounded-xl shadow-lg border border-slate-200 p-4 hover:shadow-xl transition-shadow duration-200">
              <div class="flex items-center justify-between">
                <div class="min-w-0 flex-1">
                  <p class="text-xs font-medium text-slate-600 mb-1 truncate">{{ $t('admin.weekly_issued_cards') }}</p>
                  <h3 class="text-lg font-bold text-slate-900">{{ stats.weekly_issued_cards }}</h3>
                </div>
                <div class="w-8 h-8 rounded-lg bg-gradient-to-br from-cyan-500 to-cyan-600 flex items center justify-center shadow-lg flex-shrink-0 ml-2">
                  <i class="pi pi-share-alt text-white text-sm"></i>
                </div>
              </div>
              <div class="mt-2">
                <span class="text-xs text-slate-500">{{ $t('admin.last_7_days') }}</span>
              </div>
            </div>

            <!-- Monthly Issued Cards -->
            <div class="bg-white rounded-xl shadow-lg border border-slate-200 p-4 hover:shadow-xl transition-shadow duration-200">
              <div class="flex items-center justify-between">
                <div class="min-w-0 flex-1">
                  <p class="text-xs font-medium text-slate-600 mb-1 truncate">{{ $t('admin.monthly_issued_cards') }}</p>
                  <h3 class="text-lg font-bold text-slate-900">{{ stats.monthly_issued_cards }}</h3>
                </div>
                <div class="w-8 h-8 rounded-lg bg-gradient-to-br from-blue-500 to-blue-600 flex items-center justify-center shadow-lg flex-shrink-0 ml-2">
                  <i class="pi pi-bolt text-white text-sm"></i>
                </div>
              </div>
              <div class="mt-2">
                <span class="text-xs text-slate-500">{{ $t('admin.last_30_days') }}</span>
              </div>
            </div>
          </template>
        </div>
      </div>
    </div>
  </PageWrapper>
</template>

<script setup>
import { ref, onMounted, computed, onUnmounted } from 'vue'
import { useRouter } from 'vue-router'
import { useAdminDashboardStore } from '@/stores/admin'
import PageWrapper from '@/components/Layout/PageWrapper.vue'
import { supabase } from '@/lib/supabase'
import { useToast } from 'primevue/usetoast'
import Button from 'primevue/button'
import { useI18n } from 'vue-i18n'

const dashboardStore = useAdminDashboardStore()
const router = useRouter()
const toast = useToast()
const { t } = useI18n()

// Use dashboard store state directly
const stats = computed(() => dashboardStore.dashboardStats || {
  total_users: 0,
  total_cards: 0,
  total_batches: 0,
  total_issued_cards: 0,
  total_activated_cards: 0,
  print_requests_submitted: 0,
  print_requests_processing: 0,
  print_requests_shipping: 0,
  daily_revenue_cents: 0,
  weekly_revenue_cents: 0,
  monthly_revenue_cents: 0,
  total_revenue_cents: 0,
  daily_new_users: 0,
  weekly_new_users: 0,
  monthly_new_users: 0,
  daily_new_cards: 0,
  weekly_new_cards: 0,
  monthly_new_cards: 0,
  daily_issued_cards: 0,
  weekly_issued_cards: 0,
  monthly_issued_cards: 0
})

// Computed property for verification rate

// Use dashboard store loading states
const isLoading = computed(() => dashboardStore.isLoading)
const isLoadingStats = computed(() => dashboardStore.isLoadingStats)

// Remove activity-related state since Recent Activity is now in History Logs page

// Function to format revenue
const formatRevenue = (cents) => {
  return `$${((cents || 0) / 100).toFixed(2)}`
}

// Remove activity loading functions since Recent Activity is now in History Logs page

// Update the loadDashboardData function to use dashboard store
const loadDashboardData = async () => {
  try {
    await dashboardStore.fetchDashboardStats()
  } catch (error) {
    console.error('Error loading dashboard data:', error)
    toast.add({
      severity: 'error',
      summary: t('messages.operation_failed'),
      detail: t('admin.failed_to_load_dashboard'),
      life: 5000
    })
  }
}

// Add auto-refresh every 5 minutes
let refreshInterval
onMounted(async () => {
  await loadDashboardData()
  refreshInterval = setInterval(loadDashboardData, 5 * 60 * 1000)
})

onUnmounted(() => {
  if (refreshInterval) {
    clearInterval(refreshInterval)
  }
})


function handleBatch(batch) {
  router.push({ 
    name: 'admin-batches',
    query: { batch: batch.id }
  })
}

function getActivityColor(activity) {
  // Simple color mapping without feedback store
  const colorMap = {
    'USER_ROLE_UPDATE': 'orange',
    'PRINT_REQUEST_STATUS_UPDATE': 'blue',
    'DEFAULT': 'slate'
  }
  return colorMap[activity.action_type] || colorMap['DEFAULT']
}

function getActivityIcon(activity) {
  const icons = {
    'USER_REGISTRATION': 'pi-user-plus',
    'CARD_CREATION': 'pi-plus-circle',
    'CARD_UPDATE': 'pi-pencil',
    'CARD_DELETION': 'pi-trash',
    'BATCH_STATUS_CHANGE': 'pi-refresh',
    'CARD_GENERATION': 'pi-cog',
    'VERIFICATION_REVIEW': 'pi-shield',
    'PRINT_REQUEST_UPDATE': 'pi-print',
    'PRINT_REQUEST_WITHDRAWAL': 'pi-times-circle',
    'ROLE_CHANGE': 'pi-users'
  }
  return icons[activity.action_type] || 'pi-history'
}

function formatTimeAgo(date) {
  const now = new Date()
  const past = new Date(date)
  const diffMs = now - past
  const diffMins = Math.floor(diffMs / (60 * 1000))
  const diffHours = Math.floor(diffMs / (60 * 60 * 1000))
  const diffDays = Math.floor(diffMs / (24 * 60 * 60 * 1000))

  if (diffMins < 60) return `${diffMins}m ago`
  if (diffHours < 24) return `${diffHours}h ago`
  return `${diffDays}d ago`
}

const refreshData = async () => {
  await loadDashboardData()
}
</script>

<style scoped>
/* Custom hover effects */
.hover\:bg-slate-50:hover {
  background-color: rgb(248 250 252);
}

/* Tag sizing */
:deep(.p-tag) {
  font-size: 0.75rem;
  padding: 0.125rem 0.375rem;
}

/* Button consistency */
:deep(.p-button) {
  font-size: 0.875rem;
}

.p-calendar {
  width: 100%;
}
.p-dropdown {
  width: 100%;
}

/* Ensure cards have minimum width and proper text truncation */
.metric-card {
  min-width: 180px;
}

@media (max-width: 640px) {
  .metric-card {
    min-width: 160px;
  }
}
</style>