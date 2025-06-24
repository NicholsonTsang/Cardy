<template>
  <div class="space-y-4">
    <!-- Page Header -->
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
      <div>
        <h1 class="text-2xl font-bold text-slate-900">Admin Dashboard</h1>
        <p class="text-slate-600 mt-1">System overview and management</p>
      </div>
      <div class="flex items-center gap-3">
        <Button 
          icon="pi pi-refresh" 
          label="Refresh Data" 
          outlined
          @click="refreshData"
          :loading="isLoading"
        />
      </div>
    </div>


    <!-- Quick Stats Overview -->
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
      <template v-if="isLoadingStats">
        <div v-for="i in 4" :key="i" class="bg-white rounded-xl shadow-sm p-4 border border-slate-200 animate-pulse">
          <div class="h-20"></div>
        </div>
      </template>
      <template v-else>
        <div class="bg-white rounded-xl shadow-sm p-4 border border-slate-200">
          <div class="flex items-center justify-between">
            <div>
              <p class="text-sm text-slate-600">Pending Verifications</p>
              <h3 class="text-2xl font-semibold text-slate-900">{{ stats.pending_verifications }}</h3>
              <div class="mt-1 flex items-center gap-2">
                <div class="text-xs text-slate-500">Progress:</div>
                <div class="flex-1 h-1 bg-slate-100 rounded-full overflow-hidden">
                  <div class="h-full bg-blue-500 rounded-full" :style="{ width: verificationProgress + '%' }"></div>
                </div>
                <div class="text-xs text-slate-500">{{ verificationProgress }}%</div>
              </div>
            </div>
            <div class="w-10 h-10 rounded-lg bg-blue-50 flex items-center justify-center">
              <i class="pi pi-shield text-blue-600 text-lg"></i>
            </div>
          </div>
          <div class="mt-2">
            <router-link :to="{ name: 'adminverifications' }" class="text-sm text-blue-600 hover:text-blue-700">
              Review Requests →
            </router-link>
          </div>
        </div>

        <div class="bg-white rounded-xl shadow-sm p-4 border border-slate-200">
          <div class="flex items-center justify-between">
            <div>
              <p class="text-sm text-slate-600">Print Requests</p>
              <h3 class="text-2xl font-semibold text-slate-900">{{ stats.active_print_requests }}</h3>
              <div class="mt-1 flex items-center gap-1 text-xs text-slate-500">
                <span class="text-blue-600">{{ stats.pending_print_requests }} pending</span> •
                <span class="text-green-600">{{ stats.completed_print_requests }} completed</span>
              </div>
            </div>
            <div class="w-10 h-10 rounded-lg bg-green-50 flex items-center justify-center">
              <i class="pi pi-print text-green-600 text-lg"></i>
            </div>
          </div>
          <div class="mt-2">
            <router-link :to="{ name: 'adminprintrequests' }" class="text-sm text-green-600 hover:text-green-700">
              Process Requests →
            </router-link>
          </div>
        </div>

        <div class="bg-white rounded-xl shadow-sm p-4 border border-slate-200">
          <div class="flex items-center justify-between">
            <div>
              <p class="text-sm text-slate-600">Batch Payments</p>
              <h3 class="text-2xl font-semibold text-slate-900">{{ stats.pending_payment_batches }}</h3>
              <div class="mt-1 flex items-center gap-2">
                <div class="text-xs text-slate-500">Processed:</div>
                <div class="flex-1 h-1 bg-slate-100 rounded-full overflow-hidden">
                  <div class="h-full bg-yellow-500 rounded-full" :style="{ width: paymentProgress + '%' }"></div>
                </div>
                <div class="text-xs text-slate-500">{{ paymentProgress }}%</div>
              </div>
            </div>
            <div class="w-10 h-10 rounded-lg bg-yellow-50 flex items-center justify-center">
              <i class="pi pi-credit-card text-yellow-600 text-lg"></i>
            </div>
          </div>
          <div class="mt-2">
            <router-link :to="{ name: 'adminbatches' }" class="text-sm text-yellow-600 hover:text-yellow-700">
              Review Payments →
            </router-link>
          </div>
        </div>

        <div class="bg-white rounded-xl shadow-sm p-4 border border-slate-200">
          <div class="flex items-center justify-between">
            <div>
              <p class="text-sm text-slate-600">Revenue Overview</p>
              <h3 class="text-2xl font-semibold text-slate-900">{{ totalRevenue }}</h3>
              <div class="mt-1 text-xs text-slate-500">
                <span class="text-yellow-600">{{ totalWaived }}</span> in waived fees
              </div>
            </div>
            <div class="w-10 h-10 rounded-lg bg-purple-50 flex items-center justify-center">
              <i class="pi pi-dollar text-purple-600 text-lg"></i>
            </div>
          </div>
          <div class="mt-2">
            <router-link :to="{ name: 'adminhistorylogs' }" class="text-sm text-purple-600 hover:text-purple-700">
              View Details →
            </router-link>
          </div>
        </div>
      </template>
    </div>

    <!-- System Overview -->
    <div class="bg-white rounded-xl shadow-sm border border-slate-200 p-4">
      <h2 class="text-lg font-semibold text-slate-900 mb-4">System Overview</h2>
      <div class="grid grid-cols-2 md:grid-cols-4 gap-4">
        <template v-if="isLoadingStats">
          <div v-for="i in 4" :key="i" class="animate-pulse">
            <div class="h-4 bg-slate-200 rounded w-20 mb-2"></div>
            <div class="h-6 bg-slate-200 rounded w-12"></div>
          </div>
        </template>
        <template v-else>
          <div>
            <p class="text-sm text-slate-600">Total Users</p>
            <p class="text-xl font-semibold text-slate-900">{{ stats.total_users }}</p>
          </div>
          <div>
            <p class="text-sm text-slate-600">Card Designs</p>
            <p class="text-xl font-semibold text-slate-900">{{ stats.total_card_designs }}</p>
          </div>
          <div>
            <p class="text-sm text-slate-600">Issued Cards</p>
            <p class="text-xl font-semibold text-slate-900">{{ stats.total_issued_cards }}</p>
          </div>
          <div>
            <p class="text-sm text-slate-600">Activated Cards</p>
            <p class="text-xl font-semibold text-slate-900">{{ stats.total_activated_cards }}</p>
          </div>
        </template>
      </div>
    </div>

    <!-- Recent Activity -->
    <div class="bg-white rounded-xl shadow-sm border border-slate-200 p-4">
      <div class="flex items-center justify-between mb-4">
        <h2 class="text-lg font-semibold text-slate-900">Recent Activity</h2>
        <Button icon="pi pi-refresh" text @click="refreshData" :loading="isLoadingActivity" />
      </div>

      <!-- Activity Filters -->
      <div class="mb-4 grid grid-cols-1 md:grid-cols-4 gap-4">
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
                  activity.action_type === 'PRINT_REQUEST_UPDATE' ? 'bg-green-100 text-green-600' :
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
</template>

<script setup>
import { ref, onMounted, computed, onUnmounted } from 'vue'
import { useRouter } from 'vue-router'
import { useAdminDashboardStore, useAdminFeedbackStore } from '@/stores/admin'
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
  pending_verifications: 0,
  active_print_requests: 0,
  pending_payment_batches: 0,
  total_revenue_cents: 0,
  total_waived_amount_cents: 0,
  total_users: 0,
  total_card_designs: 0,
  total_issued_cards: 0,
  total_activated_cards: 0,
  approved_verifications: 0,
  rejected_verifications: 0,
  pending_print_requests: 0,
  completed_print_requests: 0,
  total_batches: 0,
  paid_batches: 0,
  unpaid_batches: 0,
  waived_batches: 0
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
  { label: 'Verifications', value: 'VERIFICATION_UPDATE' },
  { label: 'Print Requests', value: 'PRINT_REQUEST_UPDATE' },
  { label: 'Batch Payments', value: 'BATCH_PAYMENT_UPDATE' },
  { label: 'Card Activations', value: 'CARD_ACTIVATION' },
  { label: 'Role Changes', value: 'ROLE_CHANGE' },
  { label: 'System Updates', value: 'SYSTEM_UPDATE' }
]

const recentActivity = ref([])
const isLoadingActivity = ref(false)

// Add computed properties for derived stats
const verificationProgress = computed(() => {
  const total = stats.value.pending_verifications + stats.value.approved_verifications + stats.value.rejected_verifications
  return total > 0 ? Math.round((stats.value.approved_verifications / total) * 100) : 0
})

const paymentProgress = computed(() => {
  const total = stats.value.total_batches
  return total > 0 ? Math.round((stats.value.paid_batches / total) * 100) : 0
})

const totalRevenue = computed(() => {
  const cents = stats.value.total_revenue_cents || 0
  return `$${(cents / 100).toFixed(2)}`
})

const totalWaived = computed(() => {
  const cents = stats.value.total_waived_amount_cents || 0
  return `$${(cents / 100).toFixed(2)}`
})

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
</style> 