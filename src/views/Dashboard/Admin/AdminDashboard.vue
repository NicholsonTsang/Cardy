<template>
  <PageWrapper title="Admin Dashboard" description="System overview and management">
    <template #actions>
      <Button 
        icon="pi pi-refresh" 
        label="Refresh Data" 
        severity="secondary"
        outlined
        @click="refreshData"
        :loading="isLoading"
        class="text-blue-600 border-blue-600 hover:bg-blue-50"
      />
    </template>
    
    <div class="space-y-8">
      <!-- User Management Section -->
      <div>
        <h2 class="text-lg font-semibold text-slate-900 mb-4 flex items-center gap-2">
          <i class="pi pi-users text-blue-600"></i>
          User Management
        </h2>
        <div class="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-4">
          <template v-if="isLoadingStats">
            <div v-for="i in 6" :key="i" class="bg-white rounded-xl shadow-lg p-4 border border-slate-200 animate-pulse">
              <div class="h-20"></div>
            </div>
          </template>
          <template v-else>
            <!-- Total Users -->
            <div class="bg-white rounded-xl shadow-lg border border-slate-200 p-4 hover:shadow-xl transition-shadow duration-200">
              <div class="flex items-center justify-between">
                <div class="min-w-0 flex-1">
                  <p class="text-xs font-medium text-slate-600 mb-1 truncate">Total Users</p>
                  <h3 class="text-lg font-bold text-slate-900">{{ stats.total_users }}</h3>
                </div>
                <div class="w-8 h-8 rounded-lg bg-gradient-to-br from-blue-500 to-blue-600 flex items-center justify-center shadow-lg flex-shrink-0 ml-2">
                  <i class="pi pi-users text-white text-sm"></i>
                </div>
              </div>
              <div class="mt-2">
                <span class="text-xs text-slate-500">All registered</span>
              </div>
            </div>

            <!-- Verified Users -->
            <div class="bg-white rounded-xl shadow-lg border border-slate-200 p-4 hover:shadow-xl transition-shadow duration-200">
              <div class="flex items-center justify-between">
                <div class="min-w-0 flex-1">
                  <p class="text-xs font-medium text-slate-600 mb-1 truncate">Verified Users</p>
                  <h3 class="text-lg font-bold text-slate-900">{{ stats.total_verified_users }}</h3>
                </div>
                <div class="w-8 h-8 rounded-lg bg-gradient-to-br from-green-500 to-green-600 flex items-center justify-center shadow-lg flex-shrink-0 ml-2">
                  <i class="pi pi-verified text-white text-sm"></i>
                </div>
              </div>
              <div class="mt-2">
                <span class="text-xs text-slate-500">{{ verificationRate }}% verified</span>
              </div>
            </div>

            <!-- Pending Verifications -->
            <div class="bg-white rounded-xl shadow-lg border border-slate-200 p-4 hover:shadow-xl transition-shadow duration-200">
              <div class="flex items-center justify-between">
                <div class="min-w-0 flex-1">
                  <p class="text-xs font-medium text-slate-600 mb-1 truncate">Pending Verifications</p>
                  <h3 class="text-lg font-bold text-slate-900">{{ stats.pending_verifications }}</h3>
                </div>
                <div class="w-8 h-8 rounded-lg bg-gradient-to-br from-orange-500 to-orange-600 flex items-center justify-center shadow-lg flex-shrink-0 ml-2">
                  <i class="pi pi-clock text-white text-sm"></i>
                </div>
              </div>
              <div class="mt-2">
                <router-link :to="{ name: 'adminverifications' }" class="inline-flex items-center text-xs font-medium text-orange-600 hover:text-orange-700 transition-colors">
                  Review
                  <i class="pi pi-arrow-right ml-1 text-xs"></i>
                </router-link>
              </div>
            </div>

            <!-- Daily New Users -->
            <div class="bg-white rounded-xl shadow-lg border border-slate-200 p-4 hover:shadow-xl transition-shadow duration-200">
              <div class="flex items-center justify-between">
                <div class="min-w-0 flex-1">
                  <p class="text-xs font-medium text-slate-600 mb-1 truncate">Daily New Users</p>
                  <h3 class="text-lg font-bold text-slate-900">{{ stats.daily_new_users }}</h3>
                </div>
                <div class="w-8 h-8 rounded-lg bg-gradient-to-br from-cyan-500 to-cyan-600 flex items-center justify-center shadow-lg flex-shrink-0 ml-2">
                  <i class="pi pi-user-plus text-white text-sm"></i>
                </div>
              </div>
              <div class="mt-2">
                <span class="text-xs text-slate-500">Today</span>
              </div>
            </div>

            <!-- Weekly New Users -->
            <div class="bg-white rounded-xl shadow-lg border border-slate-200 p-4 hover:shadow-xl transition-shadow duration-200">
              <div class="flex items-center justify-between">
                <div class="min-w-0 flex-1">
                  <p class="text-xs font-medium text-slate-600 mb-1 truncate">Weekly New Users</p>
                  <h3 class="text-lg font-bold text-slate-900">{{ stats.weekly_new_users }}</h3>
                </div>
                <div class="w-8 h-8 rounded-lg bg-gradient-to-br from-sky-500 to-sky-600 flex items-center justify-center shadow-lg flex-shrink-0 ml-2">
                  <i class="pi pi-calendar-plus text-white text-sm"></i>
                </div>
              </div>
              <div class="mt-2">
                <span class="text-xs text-slate-500">Last 7 days</span>
              </div>
            </div>

            <!-- Monthly New Users -->
            <div class="bg-white rounded-xl shadow-lg border border-slate-200 p-4 hover:shadow-xl transition-shadow duration-200">
              <div class="flex items-center justify-between">
                <div class="min-w-0 flex-1">
                  <p class="text-xs font-medium text-slate-600 mb-1 truncate">Monthly New Users</p>
                  <h3 class="text-lg font-bold text-slate-900">{{ stats.monthly_new_users }}</h3>
                </div>
                <div class="w-8 h-8 rounded-lg bg-gradient-to-br from-violet-500 to-violet-600 flex items-center justify-center shadow-lg flex-shrink-0 ml-2">
                  <i class="pi pi-user-edit text-white text-sm"></i>
                </div>
              </div>
              <div class="mt-2">
                <span class="text-xs text-slate-500">Last 30 days</span>
              </div>
            </div>
          </template>
        </div>
      </div>

      <!-- Print Request Management Section -->
      <div>
        <h2 class="text-lg font-semibold text-slate-900 mb-4 flex items-center gap-2">
          <i class="pi pi-print text-blue-600"></i>
          Print Request Pipeline
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
                  <p class="text-xs font-medium text-slate-600 mb-1 truncate">Print Submitted</p>
                  <h3 class="text-lg font-bold text-slate-900">{{ stats.print_requests_submitted }}</h3>
                </div>
                <div class="w-8 h-8 rounded-lg bg-gradient-to-br from-orange-500 to-orange-600 flex items-center justify-center shadow-lg flex-shrink-0 ml-2">
                  <i class="pi pi-send text-white text-sm"></i>
                </div>
              </div>
              <div class="mt-2">
                <router-link :to="{ name: 'adminprintrequests' }" class="inline-flex items-center text-xs font-medium text-orange-600 hover:text-orange-700 transition-colors">
                  Process
                  <i class="pi pi-arrow-right ml-1 text-xs"></i>
                </router-link>
              </div>
            </div>

            <!-- Print Requests Processing -->
            <div class="bg-white rounded-xl shadow-lg border border-slate-200 p-4 hover:shadow-xl transition-shadow duration-200">
              <div class="flex items-center justify-between">
                <div class="min-w-0 flex-1">
                  <p class="text-xs font-medium text-slate-600 mb-1 truncate">Print Processing</p>
                  <h3 class="text-lg font-bold text-slate-900">{{ stats.print_requests_processing }}</h3>
                </div>
                <div class="w-8 h-8 rounded-lg bg-gradient-to-br from-blue-500 to-blue-600 flex items-center justify-center shadow-lg flex-shrink-0 ml-2">
                  <i class="pi pi-cog text-white text-sm"></i>
                </div>
              </div>
              <div class="mt-2">
                <router-link :to="{ name: 'adminprintrequests' }" class="inline-flex items-center text-xs font-medium text-blue-600 hover:text-blue-700 transition-colors">
                  Track
                  <i class="pi pi-arrow-right ml-1 text-xs"></i>
                </router-link>
              </div>
            </div>

            <!-- Print Requests Shipping -->
            <div class="bg-white rounded-xl shadow-lg border border-slate-200 p-4 hover:shadow-xl transition-shadow duration-200">
              <div class="flex items-center justify-between">
                <div class="min-w-0 flex-1">
                  <p class="text-xs font-medium text-slate-600 mb-1 truncate">Print Shipping</p>
                  <h3 class="text-lg font-bold text-slate-900">{{ stats.print_requests_shipping }}</h3>
                </div>
                <div class="w-8 h-8 rounded-lg bg-gradient-to-br from-green-500 to-green-600 flex items-center justify-center shadow-lg flex-shrink-0 ml-2">
                  <i class="pi pi-truck text-white text-sm"></i>
                </div>
              </div>
              <div class="mt-2">
                <router-link :to="{ name: 'adminprintrequests' }" class="inline-flex items-center text-xs font-medium text-green-600 hover:text-green-700 transition-colors">
                  Monitor
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
          Revenue Analytics
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
                  <p class="text-xs font-medium text-slate-600 mb-1 truncate">Daily Revenue</p>
                  <h3 class="text-lg font-bold text-slate-900 truncate">{{ formatRevenue(stats.daily_revenue_cents) }}</h3>
                </div>
                <div class="w-8 h-8 rounded-lg bg-gradient-to-br from-emerald-500 to-emerald-600 flex items-center justify-center shadow-lg flex-shrink-0 ml-2">
                  <i class="pi pi-calendar text-white text-sm"></i>
                </div>
              </div>
              <div class="mt-2">
                <span class="text-xs text-slate-500">Today</span>
              </div>
            </div>

            <!-- Weekly Revenue -->
            <div class="bg-white rounded-xl shadow-lg border border-slate-200 p-4 hover:shadow-xl transition-shadow duration-200">
              <div class="flex items-center justify-between">
                <div class="min-w-0 flex-1">
                  <p class="text-xs font-medium text-slate-600 mb-1 truncate">Weekly Revenue</p>
                  <h3 class="text-lg font-bold text-slate-900 truncate">{{ formatRevenue(stats.weekly_revenue_cents) }}</h3>
                </div>
                <div class="w-8 h-8 rounded-lg bg-gradient-to-br from-purple-500 to-purple-600 flex items-center justify-center shadow-lg flex-shrink-0 ml-2">
                  <i class="pi pi-chart-line text-white text-sm"></i>
                </div>
              </div>
              <div class="mt-2">
                <span class="text-xs text-slate-500">Last 7 days</span>
              </div>
            </div>

            <!-- Monthly Revenue -->
            <div class="bg-white rounded-xl shadow-lg border border-slate-200 p-4 hover:shadow-xl transition-shadow duration-200">
              <div class="flex items-center justify-between">
                <div class="min-w-0 flex-1">
                  <p class="text-xs font-medium text-slate-600 mb-1 truncate">Monthly Revenue</p>
                  <h3 class="text-lg font-bold text-slate-900 truncate">{{ formatRevenue(stats.monthly_revenue_cents) }}</h3>
                </div>
                <div class="w-8 h-8 rounded-lg bg-gradient-to-br from-indigo-500 to-indigo-600 flex items-center justify-center shadow-lg flex-shrink-0 ml-2">
                  <i class="pi pi-dollar text-white text-sm"></i>
                </div>
              </div>
              <div class="mt-2">
                <span class="text-xs text-slate-500">Last 30 days</span>
              </div>
            </div>
          </template>
        </div>
      </div>

      <!-- Card Design Growth Section -->
      <div>
        <h2 class="text-lg font-semibold text-slate-900 mb-4 flex items-center gap-2">
          <i class="pi pi-id-card text-blue-600"></i>
          Card Design Growth
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
                  <p class="text-xs font-medium text-slate-600 mb-1 truncate">Daily New Cards</p>
                  <h3 class="text-lg font-bold text-slate-900">{{ stats.daily_new_cards }}</h3>
                </div>
                <div class="w-8 h-8 rounded-lg bg-gradient-to-br from-rose-500 to-rose-600 flex items-center justify-center shadow-lg flex-shrink-0 ml-2">
                  <i class="pi pi-id-card text-white text-sm"></i>
                </div>
              </div>
              <div class="mt-2">
                <span class="text-xs text-slate-500">Today</span>
              </div>
            </div>

            <!-- Weekly New Cards -->
            <div class="bg-white rounded-xl shadow-lg border border-slate-200 p-4 hover:shadow-xl transition-shadow duration-200">
              <div class="flex items-center justify-between">
                <div class="min-w-0 flex-1">
                  <p class="text-xs font-medium text-slate-600 mb-1 truncate">Weekly New Cards</p>
                  <h3 class="text-lg font-bold text-slate-900">{{ stats.weekly_new_cards }}</h3>
                </div>
                <div class="w-8 h-8 rounded-lg bg-gradient-to-br from-pink-500 to-pink-600 flex items-center justify-center shadow-lg flex-shrink-0 ml-2">
                  <i class="pi pi-credit-card text-white text-sm"></i>
                </div>
              </div>
              <div class="mt-2">
                <span class="text-xs text-slate-500">Last 7 days</span>
              </div>
            </div>

            <!-- Monthly New Cards -->
            <div class="bg-white rounded-xl shadow-lg border border-slate-200 p-4 hover:shadow-xl transition-shadow duration-200">
              <div class="flex items-center justify-between">
                <div class="min-w-0 flex-1">
                  <p class="text-xs font-medium text-slate-600 mb-1 truncate">Monthly New Cards</p>
                  <h3 class="text-lg font-bold text-slate-900">{{ stats.monthly_new_cards }}</h3>
                </div>
                <div class="w-8 h-8 rounded-lg bg-gradient-to-br from-amber-500 to-amber-600 flex items-center justify-center shadow-lg flex-shrink-0 ml-2">
                  <i class="pi pi-clone text-white text-sm"></i>
                </div>
              </div>
              <div class="mt-2">
                <span class="text-xs text-slate-500">Last 30 days</span>
              </div>
            </div>
          </template>
        </div>
      </div>

      <!-- Card Issuance Trends Section -->
      <div>
        <h2 class="text-lg font-semibold text-slate-900 mb-4 flex items-center gap-2">
          <i class="pi pi-share-alt text-blue-600"></i>
          Card Issuance Trends
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
                  <p class="text-xs font-medium text-slate-600 mb-1 truncate">Daily Issued Cards</p>
                  <h3 class="text-lg font-bold text-slate-900">{{ stats.daily_issued_cards }}</h3>
                </div>
                <div class="w-8 h-8 rounded-lg bg-gradient-to-br from-teal-500 to-teal-600 flex items-center justify-center shadow-lg flex-shrink-0 ml-2">
                  <i class="pi pi-send text-white text-sm"></i>
                </div>
              </div>
              <div class="mt-2">
                <span class="text-xs text-slate-500">Today</span>
              </div>
            </div>

            <!-- Weekly Issued Cards -->
            <div class="bg-white rounded-xl shadow-lg border border-slate-200 p-4 hover:shadow-xl transition-shadow duration-200">
              <div class="flex items-center justify-between">
                <div class="min-w-0 flex-1">
                  <p class="text-xs font-medium text-slate-600 mb-1 truncate">Weekly Issued Cards</p>
                  <h3 class="text-lg font-bold text-slate-900">{{ stats.weekly_issued_cards }}</h3>
                </div>
                <div class="w-8 h-8 rounded-lg bg-gradient-to-br from-cyan-500 to-cyan-600 flex items-center justify-center shadow-lg flex-shrink-0 ml-2">
                  <i class="pi pi-share-alt text-white text-sm"></i>
                </div>
              </div>
              <div class="mt-2">
                <span class="text-xs text-slate-500">Last 7 days</span>
              </div>
            </div>

            <!-- Monthly Issued Cards -->
            <div class="bg-white rounded-xl shadow-lg border border-slate-200 p-4 hover:shadow-xl transition-shadow duration-200">
              <div class="flex items-center justify-between">
                <div class="min-w-0 flex-1">
                  <p class="text-xs font-medium text-slate-600 mb-1 truncate">Monthly Issued Cards</p>
                  <h3 class="text-lg font-bold text-slate-900">{{ stats.monthly_issued_cards }}</h3>
                </div>
                <div class="w-8 h-8 rounded-lg bg-gradient-to-br from-blue-500 to-blue-600 flex items-center justify-center shadow-lg flex-shrink-0 ml-2">
                  <i class="pi pi-bolt text-white text-sm"></i>
                </div>
              </div>
              <div class="mt-2">
                <span class="text-xs text-slate-500">Last 30 days</span>
              </div>
            </div>
          </template>
        </div>
      </div>

      <!-- Recent Activity -->
      <div class="bg-white rounded-xl shadow-lg border border-slate-200 p-6">
        <div class="flex items-center justify-between mb-6">
          <h2 class="text-xl font-bold text-slate-900">Recent Activity</h2>
          <Button 
            icon="pi pi-refresh" 
            text 
            @click="refreshData" 
            :loading="isLoadingActivity" 
            class="text-blue-600 hover:bg-blue-50"
          />
        </div>

        <!-- Activity Filters -->
        <div class="mb-6 grid grid-cols-1 md:grid-cols-4 gap-4">
          <Dropdown
            v-model="activityFilters.type"
            :options="activityTypes"
            optionLabel="label"
            optionValue="value"
            placeholder="Filter by type"
            class="w-full"
            @change="onFilterChange"
          />
          <Calendar
            v-model="activityFilters.startDate"
            placeholder="Start date"
            :showTime="true"
            :maxDate="activityFilters.endDate || new Date()"
            class="w-full"
            @date-select="onFilterChange"
          />
          <Calendar
            v-model="activityFilters.endDate"
            placeholder="End date"
            :showTime="true"
            :minDate="activityFilters.startDate"
            :maxDate="new Date()"
            class="w-full"
            @date-select="onFilterChange"
          />
          <Button
            label="Clear Filters"
            text
            @click="() => {
              activityFilters.type = null;
              activityFilters.startDate = null;
              activityFilters.endDate = null;
              onFilterChange();
            }"
            class="text-slate-600 hover:bg-slate-50"
          />
        </div>

        <!-- Activity List -->
        <template v-if="isLoadingActivity">
          <div v-for="i in activityPagination.limit" :key="i" class="animate-pulse mb-4">
            <div class="h-12 bg-slate-100 rounded"></div>
          </div>
        </template>
        <template v-else>
          <div class="divide-y divide-slate-200">
            <div v-if="!recentActivity.length" class="p-4 text-center text-slate-500">
              No activities found
            </div>
            <div v-for="activity in recentActivity" :key="activity.id" class="py-3">
              <div class="flex items-start gap-3">
                <div class="flex-shrink-0">
                  <div :class="[
                    'w-8 h-8 rounded-full flex items-center justify-center',
                    activity.action_type === 'VERIFICATION_UPDATE' ? 'bg-blue-100 text-blue-600' :
                    activity.action_type === 'PRINT_REQUEST_UPDATE' ? 'bg-blue-100 text-blue-600' :
                    activity.action_type === 'BATCH_PAYMENT_UPDATE' ? 'bg-yellow-100 text-yellow-600' :
                    activity.action_type === 'CARD_ACTIVATION' ? 'bg-purple-100 text-purple-600' :
                    activity.action_type === 'ROLE_CHANGE' ? 'bg-red-100 text-red-600' :
                    'bg-slate-100 text-slate-600'
                  ]">
                    <i :class="[
                      'text-sm',
                      activity.action_type === 'VERIFICATION_UPDATE' ? 'pi pi-shield' :
                      activity.action_type === 'PRINT_REQUEST_UPDATE' ? 'pi pi-print' :
                      activity.action_type === 'BATCH_PAYMENT_UPDATE' ? 'pi pi-credit-card' :
                      activity.action_type === 'CARD_ACTIVATION' ? 'pi pi-check-circle' :
                      activity.action_type === 'ROLE_CHANGE' ? 'pi pi-users' :
                      'pi pi-history'
                    ]"></i>
                  </div>
                </div>
                <div class="flex-1 min-w-0">
                  <p class="text-sm text-slate-900">{{ activity.reason }}</p>
                  <div class="mt-1 flex items-center gap-2 text-xs text-slate-500">
                    <span>By {{ activity.admin_email }}</span>
                    <span v-if="activity.target_user_email">• For {{ activity.target_user_email }}</span>
                    <span>•</span>
                    <time :datetime="activity.created_at">
                      {{ formatDate(activity.created_at) }}
                    </time>
                  </div>
                  <div v-if="activity.action_details || activity.old_values || activity.new_values" class="mt-2 text-xs">
                    <div v-if="activity.action_details" class="text-slate-600">
                      <div v-for="(value, key) in activity.action_details" :key="key">
                        <span class="font-medium">{{ key }}:</span> {{ value }}
                      </div>
                    </div>
                    <div v-if="activity.old_values && activity.new_values" class="mt-1 text-slate-500">
                      <div v-for="(newVal, key) in activity.new_values" :key="key" v-show="activity.old_values[key] !== newVal">
                        <span class="font-medium">{{ key }}:</span>
                        <span class="line-through mr-1">{{ activity.old_values[key] }}</span>
                        <span>→ {{ newVal }}</span>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- Pagination -->
          <div class="mt-4 flex justify-center">
            <Paginator
              v-model:first="paginationFirst"
              :rows="activityPagination.limit"
              :totalRecords="activityPagination.total"
              :rowsPerPageOptions="[10, 20, 50]"
              @rowsChange="(e) => {
                activityPagination.limit = e.rows;
                loadActivity();
              }"
            />
          </div>
        </template>
      </div>
    </div>
  </PageWrapper>
</template>

<script setup>
import { ref, onMounted, computed, onUnmounted } from 'vue'
import { useRouter } from 'vue-router'
import { useAdminDashboardStore, useAdminFeedbackStore } from '@/stores/admin'
import PageWrapper from '@/components/Layout/PageWrapper.vue'
import { supabase } from '@/lib/supabase'
import { useToast } from 'primevue/usetoast'
import Button from 'primevue/button'
import Dropdown from 'primevue/dropdown'
import Calendar from 'primevue/calendar'
import Paginator from 'primevue/paginator'

const dashboardStore = useAdminDashboardStore()
const feedbackStore = useAdminFeedbackStore()
const router = useRouter()
const toast = useToast()

// Use dashboard store state directly
const stats = computed(() => dashboardStore.dashboardStats || {
  total_users: 0,
  total_verified_users: 0,
  total_cards: 0,
  total_batches: 0,
  total_issued_cards: 0,
  total_activated_cards: 0,
  pending_verifications: 0,
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
const verificationRate = computed(() => {
  const total = stats.value.total_users
  const verified = stats.value.total_verified_users
  return total > 0 ? Math.round((verified / total) * 100) : 0
})

// Use dashboard store loading states
const isLoading = computed(() => dashboardStore.isLoading)
const isLoadingStats = computed(() => dashboardStore.isLoadingStats)

// Activity filters and pagination
const activityFilters = ref({
  type: null, // null means all types
  startDate: null,
  endDate: null,
  adminUserId: null,
  targetUserId: null
})

const activityPagination = ref({
  page: 1,
  limit: 10,
  total: 0
})

const activityTypes = [
  { label: 'All Activities', value: null },
  { label: 'User Registration', value: 'USER_REGISTRATION' },
  { label: 'Verification Reviews', value: 'VERIFICATION_REVIEW' },
  { label: 'Manual Verifications', value: 'MANUAL_VERIFICATION' },
  { label: 'Verification Resets', value: 'VERIFICATION_RESET' },
  { label: 'Role Changes', value: 'ROLE_CHANGE' },
  { label: 'Card Management', value: 'CARD_CREATION,CARD_UPDATE,CARD_DELETION' },
  { label: 'Batch Management', value: 'BATCH_STATUS_CHANGE,CARD_GENERATION' },
  { label: 'Print Requests', value: 'PRINT_REQUEST_STATUS_UPDATE,PRINT_REQUEST_WITHDRAWAL' },
  { label: 'Payment Management', value: 'PAYMENT_WAIVER,PAYMENT_CREATION,PAYMENT_CONFIRMATION' }
]

const recentActivity = ref([])
const isLoadingActivity = ref(false)

// Function to format revenue
const formatRevenue = (cents) => {
  return `$${((cents || 0) / 100).toFixed(2)}`
}

// Add computed property for pagination first value
const paginationFirst = computed({
  get: () => (activityPagination.value.page - 1) * activityPagination.value.limit,
  set: (value) => {
    activityPagination.value.page = Math.floor(value / activityPagination.value.limit) + 1
    loadActivity()
  }
})

// Load activity with filters and pagination using feedback store
const loadActivity = async () => {
  isLoadingActivity.value = true
  try {
    const data = await feedbackStore.getAdminAuditLogs({
      action_type: activityFilters.value.type,
      admin_user_id: activityFilters.value.adminUserId,
      target_user_id: activityFilters.value.targetUserId,
      start_date: activityFilters.value.startDate,
      end_date: activityFilters.value.endDate,
      limit: activityPagination.value.limit,
      offset: (activityPagination.value.page - 1) * activityPagination.value.limit
    })

    recentActivity.value = data || []

    // Get total count using feedback store
    const count = await feedbackStore.getAdminAuditLogsCount({
      action_type: activityFilters.value.type,
      admin_user_id: activityFilters.value.adminUserId,
      target_user_id: activityFilters.value.targetUserId,
      start_date: activityFilters.value.startDate,
      end_date: activityFilters.value.endDate
    })

    activityPagination.value.total = count || 0

  } catch (error) {
    console.error('Error loading activity:', error)
    toast.add({
      severity: 'error',
      summary: 'Error',
      detail: 'Failed to load activity data',
      life: 5000
    })
  } finally {
    isLoadingActivity.value = false
  }
}

// Handle filter changes
const onFilterChange = () => {
  activityPagination.value.page = 1 // Reset to first page
  loadActivity()
}

// Format date for display
const formatDate = (date) => {
  return new Date(date).toLocaleString('en-US', {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  })
}

// Update the loadDashboardData function to use dashboard store
const loadDashboardData = async () => {
  try {
    // Use dashboard store to load dashboard data
    await Promise.all([
      dashboardStore.fetchDashboardStats(),
      loadActivity()
    ])
  } catch (error) {
    console.error('Error loading dashboard data:', error)
    toast.add({
      severity: 'error',
      summary: 'Error',
      detail: 'Failed to load dashboard data. Please try again.',
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

function reviewVerification(request) {
  // This would now use the verifications store if needed
  router.push({ name: 'adminverifications' })
}

function handleBatch(batch) {
  router.push({ 
    name: 'adminbatches',
    query: { batch: batch.id }
  })
}

function getActivityColor(activity) {
  return feedbackStore.getActionTypeColor(activity.action_type)
}

function getActivityIcon(activity) {
  const icons = {
    'ROLE_CHANGE': 'pi-users',
    'VERIFICATION_REVIEW': 'pi-check-circle',
    'MANUAL_VERIFICATION': 'pi-shield',
    'PRINT_REQUEST_UPDATE': 'pi-print',
    'SYSTEM_CONFIG': 'pi-cog',
    'BATCH_MANAGEMENT': 'pi-credit-card'
  }
  return icons[activity.action_type] || 'pi-info-circle'
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