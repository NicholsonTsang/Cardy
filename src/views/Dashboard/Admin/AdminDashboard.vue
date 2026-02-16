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

            <!-- Premium Users -->
            <div class="bg-white rounded-lg sm:rounded-xl shadow-lg border border-slate-200 p-3 sm:p-4 hover:shadow-xl transition-all duration-200">
              <div class="flex items-start justify-between gap-2">
                <div class="min-w-0 flex-1">
                  <p class="text-[10px] sm:text-xs font-medium text-slate-600 mb-1 truncate leading-tight">{{ $t('admin.premium_users') }}</p>
                  <h3 class="text-base sm:text-lg md:text-xl font-bold text-slate-900 truncate">{{ stats.total_premium_users }}</h3>
                </div>
                <div class="w-7 h-7 sm:w-8 sm:h-8 rounded-md sm:rounded-lg bg-gradient-to-br from-amber-500 to-amber-600 flex items-center justify-center shadow-md sm:shadow-lg flex-shrink-0">
                  <i class="pi pi-star text-white text-xs sm:text-sm"></i>
                </div>
              </div>
              <div class="mt-1.5 sm:mt-2">
                <span class="text-[10px] sm:text-xs text-slate-500 truncate block">{{ stats.active_subscriptions }} {{ $t('admin.active_subs') }}</span>
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

            <!-- Estimated MRR -->
            <div class="bg-white rounded-xl shadow-lg border border-slate-200 p-4 hover:shadow-xl transition-shadow duration-200">
              <div class="flex items-center justify-between">
                <div class="min-w-0 flex-1">
                  <p class="text-xs font-medium text-slate-600 mb-1 truncate">{{ $t('admin.estimated_mrr') }}</p>
                  <h3 class="text-lg font-bold text-slate-900 truncate">{{ formatRevenue(stats.estimated_mrr_cents) }}</h3>
                </div>
                <div class="w-8 h-8 rounded-lg bg-gradient-to-br from-pink-500 to-pink-600 flex items-center justify-center shadow-lg flex-shrink-0 ml-2">
                  <i class="pi pi-wallet text-white text-sm"></i>
                </div>
              </div>
              <div class="mt-2">
                <span class="text-xs text-slate-500">{{ $t('admin.recurring_revenue') }}</span>
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

      <!-- Access Mode Distribution Section -->
      <div>
        <h2 class="text-lg font-semibold text-slate-900 mb-4 flex items-center gap-2">
          <i class="pi pi-th-large text-blue-600"></i>
          {{ $t('admin.access_mode_distribution') }}
        </h2>
        <div class="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-4">
          <template v-if="isLoadingStats">
            <div v-for="i in 3" :key="i" class="bg-white rounded-xl shadow-lg p-4 border border-slate-200 animate-pulse">
              <div class="h-20"></div>
            </div>
          </template>
          <template v-else>
            <!-- Digital Access Cards -->
            <div class="bg-white rounded-xl shadow-lg border border-slate-200 p-4 hover:shadow-xl transition-shadow duration-200">
              <div class="flex items-center justify-between">
                <div class="min-w-0 flex-1">
                  <p class="text-xs font-medium text-slate-600 mb-1 truncate">{{ $t('admin.digital_access_cards') }}</p>
                  <h3 class="text-lg font-bold text-slate-900">{{ stats.digital_cards_count }}</h3>
                </div>
                <div class="w-8 h-8 rounded-lg bg-gradient-to-br from-cyan-500 to-cyan-600 flex items-center justify-center shadow-lg flex-shrink-0 ml-2">
                  <i class="pi pi-qrcode text-white text-sm"></i>
                </div>
              </div>
              <div class="mt-2">
                <span class="text-xs text-slate-500">{{ $t('admin.per_scan_billing') }}</span>
              </div>
            </div>

          </template>
        </div>
      </div>

      <!-- Digital Access Analytics Section (NEW) -->
      <div>
        <h2 class="text-lg font-semibold text-slate-900 mb-4 flex items-center gap-2">
          <i class="pi pi-eye text-blue-600"></i>
          {{ $t('admin.digital_access_analytics') }}
        </h2>
        <div class="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-4 gap-4">
          <template v-if="isLoadingStats">
            <div v-for="i in 4" :key="i" class="bg-white rounded-xl shadow-lg p-4 border border-slate-200 animate-pulse">
              <div class="h-20"></div>
            </div>
          </template>
          <template v-else>
            <!-- Total Digital Scans -->
            <div class="bg-white rounded-xl shadow-lg border border-slate-200 p-4 hover:shadow-xl transition-shadow duration-200">
              <div class="flex items-center justify-between">
                <div class="min-w-0 flex-1">
                  <p class="text-xs font-medium text-slate-600 mb-1 truncate">{{ $t('admin.total_digital_scans') }}</p>
                  <h3 class="text-lg font-bold text-slate-900">{{ stats.total_digital_scans.toLocaleString() }}</h3>
                </div>
                <div class="w-8 h-8 rounded-lg bg-gradient-to-br from-purple-500 to-purple-600 flex items-center justify-center shadow-lg flex-shrink-0 ml-2">
                  <i class="pi pi-eye text-white text-sm"></i>
                </div>
              </div>
              <div class="mt-2">
                <span class="text-xs text-slate-500">{{ $t('admin.all_time') }}</span>
              </div>
            </div>

            <!-- Daily Digital Scans -->
            <div class="bg-white rounded-xl shadow-lg border border-slate-200 p-4 hover:shadow-xl transition-shadow duration-200">
              <div class="flex items-center justify-between">
                <div class="min-w-0 flex-1">
                  <p class="text-xs font-medium text-slate-600 mb-1 truncate">{{ $t('admin.daily_digital_scans') }}</p>
                  <h3 class="text-lg font-bold text-slate-900">{{ stats.daily_digital_scans.toLocaleString() }}</h3>
                </div>
                <div class="w-8 h-8 rounded-lg bg-gradient-to-br from-sky-500 to-sky-600 flex items-center justify-center shadow-lg flex-shrink-0 ml-2">
                  <i class="pi pi-calendar text-white text-sm"></i>
                </div>
              </div>
              <div class="mt-2">
                <span class="text-xs text-slate-500">{{ $t('admin.today') }}</span>
              </div>
            </div>

            <!-- Monthly Digital Scans -->
            <div class="bg-white rounded-xl shadow-lg border border-slate-200 p-4 hover:shadow-xl transition-shadow duration-200">
              <div class="flex items-center justify-between">
                <div class="min-w-0 flex-1">
                  <p class="text-xs font-medium text-slate-600 mb-1 truncate">{{ $t('admin.monthly_digital_scans') }}</p>
                  <h3 class="text-lg font-bold text-slate-900">{{ stats.monthly_digital_scans.toLocaleString() }}</h3>
                </div>
                <div class="w-8 h-8 rounded-lg bg-gradient-to-br from-violet-500 to-violet-600 flex items-center justify-center shadow-lg flex-shrink-0 ml-2">
                  <i class="pi pi-chart-bar text-white text-sm"></i>
                </div>
              </div>
              <div class="mt-2">
                <span class="text-xs text-slate-500">{{ $t('admin.last_30_days') }}</span>
              </div>
            </div>

            <!-- Monthly Logged Access -->
            <div class="bg-white rounded-xl shadow-lg border border-slate-200 p-4 hover:shadow-xl transition-shadow duration-200">
              <div class="flex items-center justify-between">
                <div class="min-w-0 flex-1">
                  <p class="text-xs font-medium text-slate-600 mb-1 truncate">{{ $t('admin.logged_access') }}</p>
                  <h3 class="text-lg font-bold text-slate-900">{{ stats.monthly_total_accesses.toLocaleString() }}</h3>
                </div>
                <div class="w-8 h-8 rounded-lg bg-gradient-to-br from-blue-500 to-blue-600 flex items-center justify-center shadow-lg flex-shrink-0 ml-2">
                  <i class="pi pi-check-circle text-white text-sm"></i>
                </div>
              </div>
              <div class="mt-2">
                <span class="text-xs text-slate-500">{{ $t('admin.this_month') }}</span>
              </div>
            </div>

            <!-- Overage Access -->
            <div class="bg-white rounded-xl shadow-lg border border-slate-200 p-4 hover:shadow-xl transition-shadow duration-200">
              <div class="flex items-center justify-between">
                <div class="min-w-0 flex-1">
                  <p class="text-xs font-medium text-slate-600 mb-1 truncate">{{ $t('admin.overage_access') }}</p>
                  <h3 class="text-lg font-bold text-slate-900">{{ stats.monthly_overage_accesses.toLocaleString() }}</h3>
                </div>
                <div class="w-8 h-8 rounded-lg bg-gradient-to-br from-red-500 to-red-600 flex items-center justify-center shadow-lg flex-shrink-0 ml-2">
                  <i class="pi pi-exclamation-circle text-white text-sm"></i>
                </div>
              </div>
              <div class="mt-2">
                <span class="text-xs text-slate-500">{{ $t('admin.this_month') }}</span>
              </div>
            </div>

            <!-- Digital Credits Consumed -->
            <div class="bg-white rounded-xl shadow-lg border border-slate-200 p-4 hover:shadow-xl transition-shadow duration-200">
              <div class="flex items-center justify-between">
                <div class="min-w-0 flex-1">
                  <p class="text-xs font-medium text-slate-600 mb-1 truncate">{{ $t('admin.digital_credits_consumed') }}</p>
                  <h3 class="text-lg font-bold text-slate-900">{{ stats.digital_credits_consumed.toFixed(2) }}</h3>
                </div>
                <div class="w-8 h-8 rounded-lg bg-gradient-to-br from-amber-500 to-amber-600 flex items-center justify-center shadow-lg flex-shrink-0 ml-2">
                  <i class="pi pi-dollar text-white text-sm"></i>
                </div>
              </div>
              <div class="mt-2">
                <span class="text-xs text-slate-500">{{ $t('admin.all_time') }}</span>
              </div>
            </div>
          </template>
        </div>
      </div>

      <!-- Content Mode Distribution Section (NEW) -->
      <div>
        <h2 class="text-lg font-semibold text-slate-900 mb-4 flex items-center gap-2">
          <i class="pi pi-objects-column text-blue-600"></i>
          {{ $t('admin.content_mode_distribution') }}
        </h2>
        <div class="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-5 gap-4">
          <template v-if="isLoadingStats">
            <div v-for="i in 5" :key="i" class="bg-white rounded-xl shadow-lg p-4 border border-slate-200 animate-pulse">
              <div class="h-20"></div>
            </div>
          </template>
          <template v-else>
            <!-- Single Mode -->
            <div class="bg-white rounded-xl shadow-lg border border-slate-200 p-4 hover:shadow-xl transition-shadow duration-200">
              <div class="flex items-center justify-between">
                <div class="min-w-0 flex-1">
                  <p class="text-xs font-medium text-slate-600 mb-1 truncate">{{ $t('dashboard.mode_single') }}</p>
                  <h3 class="text-lg font-bold text-slate-900">{{ stats.content_mode_single }}</h3>
                </div>
                <div class="w-8 h-8 rounded-lg bg-gradient-to-br from-purple-500 to-purple-600 flex items-center justify-center shadow-lg flex-shrink-0 ml-2">
                  <i class="pi pi-file text-white text-sm"></i>
                </div>
              </div>
            </div>

            <!-- Cards Mode -->
            <div class="bg-white rounded-xl shadow-lg border border-slate-200 p-4 hover:shadow-xl transition-shadow duration-200">
              <div class="flex items-center justify-between">
                <div class="min-w-0 flex-1">
                  <p class="text-xs font-medium text-slate-600 mb-1 truncate">{{ $t('dashboard.mode_cards') }}</p>
                  <h3 class="text-lg font-bold text-slate-900">{{ stats.content_mode_cards }}</h3>
                </div>
                <div class="w-8 h-8 rounded-lg bg-gradient-to-br from-orange-500 to-orange-600 flex items-center justify-center shadow-lg flex-shrink-0 ml-2">
                  <i class="pi pi-id-card text-white text-sm"></i>
                </div>
              </div>
            </div>

            <!-- List Mode -->
            <div class="bg-white rounded-xl shadow-lg border border-slate-200 p-4 hover:shadow-xl transition-shadow duration-200">
              <div class="flex items-center justify-between">
                <div class="min-w-0 flex-1">
                  <p class="text-xs font-medium text-slate-600 mb-1 truncate">{{ $t('dashboard.mode_list') }}</p>
                  <h3 class="text-lg font-bold text-slate-900">{{ stats.content_mode_list }}</h3>
                </div>
                <div class="w-8 h-8 rounded-lg bg-gradient-to-br from-blue-500 to-blue-600 flex items-center justify-center shadow-lg flex-shrink-0 ml-2">
                  <i class="pi pi-list text-white text-sm"></i>
                </div>
              </div>
            </div>

            <!-- Grid Mode -->
            <div class="bg-white rounded-xl shadow-lg border border-slate-200 p-4 hover:shadow-xl transition-shadow duration-200">
              <div class="flex items-center justify-between">
                <div class="min-w-0 flex-1">
                  <p class="text-xs font-medium text-slate-600 mb-1 truncate">{{ $t('dashboard.mode_grid') }}</p>
                  <h3 class="text-lg font-bold text-slate-900">{{ stats.content_mode_grid }}</h3>
                </div>
                <div class="w-8 h-8 rounded-lg bg-gradient-to-br from-green-500 to-green-600 flex items-center justify-center shadow-lg flex-shrink-0 ml-2">
                  <i class="pi pi-th-large text-white text-sm"></i>
                </div>
              </div>
            </div>

            <!-- Grouped Experiences -->
            <div class="bg-white rounded-xl shadow-lg border border-slate-200 p-4 hover:shadow-xl transition-shadow duration-200">
              <div class="flex items-center justify-between">
                <div class="min-w-0 flex-1">
                  <p class="text-xs font-medium text-slate-600 mb-1 truncate">{{ $t('dashboard.is_grouped') }}</p>
                  <h3 class="text-lg font-bold text-slate-900">{{ stats.is_grouped_count }}</h3>
                </div>
                <div class="w-8 h-8 rounded-lg bg-gradient-to-br from-cyan-500 to-cyan-600 flex items-center justify-center shadow-lg flex-shrink-0 ml-2">
                  <i class="pi pi-folder text-white text-sm"></i>
                </div>
              </div>
            </div>
          </template>
        </div>
      </div>
    </div>
  </PageWrapper>
</template>

<script setup>
import { onMounted, computed, onUnmounted } from 'vue'
import { useAdminDashboardStore } from '@/stores/admin'
import PageWrapper from '@/components/Layout/PageWrapper.vue'
import { useToast } from 'primevue/usetoast'
import Button from 'primevue/button'
import { useI18n } from 'vue-i18n'

const dashboardStore = useAdminDashboardStore()
const toast = useToast()
const { t } = useI18n()

// Use dashboard store state directly
const stats = computed(() => dashboardStore.dashboardStats || {
  total_users: 0,
  total_cards: 0,
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
  // Access Mode metrics
  digital_cards_count: 0,
  // Digital Access metrics
  total_digital_scans: 0,
  daily_digital_scans: 0,
  weekly_digital_scans: 0,
  monthly_digital_scans: 0,
  digital_credits_consumed: 0,
  // Content Mode distribution (matches schema: single, list, grid, cards)
  content_mode_single: 0,
  content_mode_list: 0,
  content_mode_grid: 0,
  content_mode_cards: 0,
  is_grouped_count: 0,
  // Subscription metrics (3 tiers: free, starter, premium)
  total_free_users: 0,
  total_starter_users: 0,
  total_premium_users: 0,
  active_subscriptions: 0,
  estimated_mrr_cents: 0,
  // Access Log metrics
  monthly_total_accesses: 0,
  monthly_overage_accesses: 0,
  // QR Code metrics (Multi-QR system)
  total_qr_codes: 0,
  active_qr_codes: 0
})

// Use dashboard store loading states
const isLoading = computed(() => dashboardStore.isLoading)
const isLoadingStats = computed(() => dashboardStore.isLoadingStats)

// Function to format revenue
const formatRevenue = (cents) => {
  return `$${((cents || 0) / 100).toFixed(2)}`
}

// Load dashboard data from store
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