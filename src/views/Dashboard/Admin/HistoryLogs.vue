<template>
  <PageWrapper :title="$t('admin.view_history_logs')" :description="$t('admin.all_admin_actions')">
    <template #actions>
      <Button 
        icon="pi pi-refresh" 
        :label="$t('admin.refresh_data')" 
        severity="secondary"
        outlined
        @click="refreshData"
        :loading="isLoadingActivity"
      />
      <Button 
        icon="pi pi-file-export" 
        :label="$t('admin.export_csv')" 
        severity="secondary"
        outlined
        @click="exportData"
      />
    </template>

    <div class="space-y-6">
      <!-- Recent Activity -->
      <div class="bg-white rounded-xl shadow-lg border border-slate-200 p-6">
        <div class="flex items-center justify-between mb-6">
          <h2 class="text-xl font-bold text-slate-900">{{ $t('admin.recent_activity') }}</h2>
          <Button 
            icon="pi pi-refresh" 
            text 
            @click="refreshData" 
            :loading="isLoadingActivity" 
            class="text-blue-600 hover:bg-blue-50"
          />
        </div>

        <!-- Activity Filters -->
        <div class="mb-6 space-y-4">
          <!-- Search Bar -->
          <div class="flex gap-2">
            <IconField iconPosition="left" class="flex-1">
              <InputIcon>
                <i class="pi pi-search" />
              </InputIcon>
              <InputText
                v-model="activityFilters.searchQuery"
                :placeholder="$t('admin.search_by_email')"
                class="w-full"
                @keyup.enter="onFilterChange"
              />
            </IconField>
            <Button
              :label="$t('common.search')"
              icon="pi pi-search"
              @click="onFilterChange"
              :loading="isLoadingActivity"
            />
          </div>

          <!-- Other Filters -->
          <div class="grid grid-cols-1 md:grid-cols-4 gap-4">
            <Dropdown
              v-model="activityFilters.type"
              :options="activityTypes"
              optionLabel="label"
              optionValue="value"
              :placeholder="$t('admin.filter_by_type')"
              class="w-full"
              @change="onFilterChange"
            />
            <Calendar
              v-model="activityFilters.startDate"
              :placeholder="$t('admin.start_date')"
              :showTime="true"
              :maxDate="activityFilters.endDate || new Date()"
              class="w-full"
              @date-select="onFilterChange"
            />
            <Calendar
              v-model="activityFilters.endDate"
              :placeholder="$t('admin.end_date')"
              :showTime="true"
              :minDate="activityFilters.startDate"
              :maxDate="new Date()"
              class="w-full"
              @date-select="onFilterChange"
            />
            <Button
              :label="$t('admin.clear_filters')"
              icon="pi pi-times"
              text
              @click="clearFilters"
              class="text-slate-600 hover:bg-slate-50"
            />
          </div>
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
              {{ $t('admin.no_activities_found') }}
            </div>
            <div v-for="activity in recentActivity" :key="activity.id" class="py-3">
              <div class="flex items-start gap-3">
                <div class="flex-shrink-0">
                  <div :class="[
                    'w-8 h-8 rounded-full flex items-center justify-center',
                    // User Management
                    activity.action_type === 'USER_REGISTRATION' ? 'bg-green-100 text-green-600' :
                    activity.action_type === 'ROLE_CHANGE' ? 'bg-red-100 text-red-600' :
                    activity.action_type === 'SUBSCRIPTION_CHANGE' ? 'bg-purple-100 text-purple-600' :
                    // Card Management
                    activity.action_type === 'CARD_CREATION' ? 'bg-blue-100 text-blue-600' :
                    activity.action_type === 'CARD_UPDATE' ? 'bg-amber-100 text-amber-600' :
                    activity.action_type === 'CARD_DELETION' ? 'bg-red-100 text-red-600' :
                    activity.action_type === 'CARD_ACTIVATION' ? 'bg-lime-100 text-lime-600' :
                    activity.action_type === 'CARD_GENERATION' ? 'bg-purple-100 text-purple-600' :
                    // Content Management
                    activity.action_type === 'CONTENT_ITEM_CREATION' ? 'bg-sky-100 text-sky-600' :
                    activity.action_type === 'CONTENT_ITEM_UPDATE' ? 'bg-yellow-100 text-yellow-600' :
                    activity.action_type === 'CONTENT_ITEM_DELETION' ? 'bg-rose-100 text-rose-600' :
                    activity.action_type === 'CONTENT_ITEM_REORDER' ? 'bg-amber-100 text-amber-600' :
                    // Batch Management
                    activity.action_type === 'BATCH_ISSUANCE' ? 'bg-indigo-100 text-indigo-600' :
                    activity.action_type === 'BATCH_STATUS_CHANGE' ? 'bg-orange-100 text-orange-600' :
                    activity.action_type === 'FREE_BATCH_ISSUANCE' ? 'bg-violet-100 text-violet-600' :
                    // Credit Management
                    activity.action_type === 'CREDIT_ADJUSTMENT' ? 'bg-amber-100 text-amber-600' :
                    activity.action_type === 'CREDIT_PURCHASE' ? 'bg-green-100 text-green-600' :
                    activity.action_type === 'CREDIT_CONSUMPTION' ? 'bg-pink-100 text-pink-600' :
                    // Print Requests
                    activity.action_type === 'PRINT_REQUEST_SUBMISSION' ? 'bg-blue-100 text-blue-600' :
                    activity.action_type === 'PRINT_REQUEST_UPDATE' ? 'bg-blue-100 text-blue-600' :
                    activity.action_type === 'PRINT_REQUEST_WITHDRAWAL' ? 'bg-gray-100 text-gray-600' :
                    // Legacy
                    activity.action_type === 'PAYMENT_WAIVER' ? 'bg-yellow-100 text-yellow-600' :
                    'bg-slate-100 text-slate-600'
                  ]">
                    <i :class="[
                      'text-sm',
                      // User Management
                      activity.action_type === 'USER_REGISTRATION' ? 'pi pi-user-plus' :
                      activity.action_type === 'ROLE_CHANGE' ? 'pi pi-users' :
                      activity.action_type === 'SUBSCRIPTION_CHANGE' ? 'pi pi-credit-card' :
                      // Card Management
                      activity.action_type === 'CARD_CREATION' ? 'pi pi-plus-circle' :
                      activity.action_type === 'CARD_UPDATE' ? 'pi pi-pencil' :
                      activity.action_type === 'CARD_DELETION' ? 'pi pi-trash' :
                      activity.action_type === 'CARD_ACTIVATION' ? 'pi pi-check' :
                      activity.action_type === 'CARD_GENERATION' ? 'pi pi-cog' :
                      // Content Management
                      activity.action_type === 'CONTENT_ITEM_CREATION' ? 'pi pi-file-plus' :
                      activity.action_type === 'CONTENT_ITEM_UPDATE' ? 'pi pi-file-edit' :
                      activity.action_type === 'CONTENT_ITEM_DELETION' ? 'pi pi-file-minus' :
                      activity.action_type === 'CONTENT_ITEM_REORDER' ? 'pi pi-sort-alt' :
                      // Batch Management
                      activity.action_type === 'BATCH_ISSUANCE' ? 'pi pi-box' :
                      activity.action_type === 'BATCH_STATUS_CHANGE' ? 'pi pi-refresh' :
                      activity.action_type === 'FREE_BATCH_ISSUANCE' ? 'pi pi-gift' :
                      // Credit Management
                      activity.action_type === 'CREDIT_ADJUSTMENT' ? 'pi pi-dollar' :
                      activity.action_type === 'CREDIT_PURCHASE' ? 'pi pi-shopping-cart' :
                      activity.action_type === 'CREDIT_CONSUMPTION' ? 'pi pi-wallet' :
                      // Print Requests
                      activity.action_type === 'PRINT_REQUEST_SUBMISSION' ? 'pi pi-send' :
                      activity.action_type === 'PRINT_REQUEST_UPDATE' ? 'pi pi-print' :
                      activity.action_type === 'PRINT_REQUEST_WITHDRAWAL' ? 'pi pi-times-circle' :
                      // Legacy
                      activity.action_type === 'PAYMENT_WAIVER' ? 'pi pi-credit-card' :
                      'pi pi-history'
                    ]"></i>
                  </div>
                </div>
                <div class="flex-1 min-w-0">
                  <p class="text-sm text-slate-900">{{ activity.description }}</p>
                  <div class="mt-1 flex items-center gap-2 text-xs text-slate-500">
                    <span>{{ $t('admin.operation_user') }}: {{ activity.admin_email }}</span>
                    <span v-if="activity.target_user_email">• {{ $t('admin.user_email') }}: {{ activity.target_user_email }}</span>
                    <span>•</span>
                    <time :datetime="activity.created_at">
                      {{ formatDateTime(activity.created_at) }}
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
              @page="onPageChange"
            />
          </div>
        </template>
      </div>
    </div>
  </PageWrapper>
</template>

<script setup>
import { ref, onMounted, computed, onUnmounted } from 'vue'
import { useI18n } from 'vue-i18n'
import { useToast } from 'primevue/usetoast'
import { useAuditLogStore, ACTION_TYPES } from '@/stores/admin/auditLog'
import PageWrapper from '@/components/Layout/PageWrapper.vue'

// PrimeVue Components
import Button from 'primevue/button'
import Dropdown from 'primevue/dropdown'
import Calendar from 'primevue/calendar'
import Paginator from 'primevue/paginator'
import InputText from 'primevue/inputtext'
import IconField from 'primevue/iconfield'
import InputIcon from 'primevue/inputicon'
import { formatDateTime } from '@/utils/formatters'

const { t } = useI18n()
const toast = useToast()
const auditLogStore = useAuditLogStore()

// Activity filters and pagination
const activityFilters = ref({
  searchQuery: '', // Search by email or operation text
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

const activityTypes = computed(() => [
  { label: t('admin.activity_types.all_activities'), value: null },
  // User Management
  { label: t('admin.activity_types.user_registration'), value: ACTION_TYPES.USER_REGISTRATION },
  { label: t('admin.activity_types.role_changes'), value: ACTION_TYPES.ROLE_CHANGE },
  { label: t('admin.activity_types.subscription_changes'), value: ACTION_TYPES.SUBSCRIPTION_CHANGE },
  // Card Management
  { label: t('admin.activity_types.card_creation'), value: ACTION_TYPES.CARD_CREATION },
  { label: t('admin.activity_types.card_updates'), value: ACTION_TYPES.CARD_UPDATE },
  { label: t('admin.activity_types.card_deletions'), value: ACTION_TYPES.CARD_DELETION },
  { label: t('admin.activity_types.card_activations'), value: ACTION_TYPES.CARD_ACTIVATION },
  { label: t('admin.activity_types.card_generation'), value: ACTION_TYPES.CARD_GENERATION },
  // Content Management
  { label: t('admin.activity_types.content_item_creation'), value: ACTION_TYPES.CONTENT_ITEM_CREATION },
  { label: t('admin.activity_types.content_item_updates'), value: ACTION_TYPES.CONTENT_ITEM_UPDATE },
  { label: t('admin.activity_types.content_item_deletions'), value: ACTION_TYPES.CONTENT_ITEM_DELETION },
  { label: t('admin.activity_types.content_item_reorder'), value: ACTION_TYPES.CONTENT_ITEM_REORDER },
  // Batch Management
  { label: t('admin.activity_types.batch_issuance'), value: ACTION_TYPES.BATCH_ISSUANCE },
  { label: t('admin.activity_types.batch_status_changes'), value: ACTION_TYPES.BATCH_STATUS_CHANGE },
  { label: t('admin.activity_types.free_batch_issuance'), value: ACTION_TYPES.FREE_BATCH_ISSUANCE },
  // Credit Management
  { label: t('admin.activity_types.credit_adjustments'), value: ACTION_TYPES.CREDIT_ADJUSTMENT },
  { label: t('admin.activity_types.credit_purchases'), value: ACTION_TYPES.CREDIT_PURCHASE },
  { label: t('admin.activity_types.credit_consumption'), value: ACTION_TYPES.CREDIT_CONSUMPTION },
  // Print Requests
  { label: t('admin.activity_types.print_request_submissions'), value: ACTION_TYPES.PRINT_REQUEST_SUBMISSION },
  { label: t('admin.activity_types.print_request_updates'), value: ACTION_TYPES.PRINT_REQUEST_UPDATE },
  { label: t('admin.activity_types.print_request_withdrawals'), value: ACTION_TYPES.PRINT_REQUEST_WITHDRAWAL }
])

const recentActivity = ref([])
const isLoadingActivity = ref(false)

// Add computed property for pagination first value
const paginationFirst = computed({
  get: () => (activityPagination.value.page - 1) * activityPagination.value.limit,
  set: (value) => {
    activityPagination.value.page = Math.floor(value / activityPagination.value.limit) + 1
  }
})

// Handle page change events (including rows per page change)
const onPageChange = (event) => {
  // event = { page, first, rows, pageCount }
  activityPagination.value.limit = event.rows
  activityPagination.value.page = event.page + 1 // PrimeVue uses 0-based page index
  loadActivity()
}

// Load activity with filters and pagination
const loadActivity = async () => {
  isLoadingActivity.value = true
  try {
    const data = await auditLogStore.fetchAuditLogs({
      search_query: activityFilters.value.searchQuery || null,
      action_type: activityFilters.value.type,
      admin_user_id: activityFilters.value.adminUserId,
      target_user_id: activityFilters.value.targetUserId,
      start_date: activityFilters.value.startDate,
      end_date: activityFilters.value.endDate
    }, activityPagination.value.limit, (activityPagination.value.page - 1) * activityPagination.value.limit)

    recentActivity.value = data || []

    // Get total count
    const count = await auditLogStore.fetchAuditLogsCount({
      search_query: activityFilters.value.searchQuery || null,
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
      summary: t('common.error'),
      detail: t('messages.failed_to_load_activity_data'),
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

// Refresh data
const refreshData = async () => {
  await loadActivity()
}

// Clear all filters
const clearFilters = () => {
  activityFilters.value.searchQuery = ''
  activityFilters.value.type = null
  activityFilters.value.startDate = null
  activityFilters.value.endDate = null
  onFilterChange()
}

// Export data functionality
const exportData = async () => {
  try {
    // Get all activity data without pagination
    const allData = await auditLogStore.fetchAuditLogs({
      search_query: activityFilters.value.searchQuery || null,
      action_type: activityFilters.value.type,
      admin_user_id: activityFilters.value.adminUserId,
      target_user_id: activityFilters.value.targetUserId,
      start_date: activityFilters.value.startDate,
      end_date: activityFilters.value.endDate
    }, 10000, 0) // Large limit to get all data

    if (!allData || allData.length === 0) {
      toast.add({
        severity: 'warn',
        summary: t('common.no_data'),
        detail: t('messages.no_activities_to_export'),
        life: 3000
      })
      return
    }

    // Convert to CSV
    const headers = ['Date/Time', 'Admin', 'Action Type', 'Description', 'Target User']
    const csvContent = [
      headers.join(','),
      ...allData.map(activity => [
        formatDateTime(activity.created_at),
        activity.admin_email || '',
        activity.action_type || '',
        `"${(activity.description || '').replace(/"/g, '""')}"`,
        activity.target_user_email || ''
      ].join(','))
    ].join('\n')

    // Download file
    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' })
    const link = document.createElement('a')
    const url = URL.createObjectURL(blob)
    link.setAttribute('href', url)
    link.setAttribute('download', `history-logs-${new Date().toISOString().split('T')[0]}.csv`)
    link.style.visibility = 'hidden'
    document.body.appendChild(link)
    link.click()
    document.body.removeChild(link)

    toast.add({
      severity: 'success',
      summary: t('messages.export_complete'),
      detail: t('messages.history_logs_exported'),
      life: 3000
    })

  } catch (error) {
    console.error('Error exporting data:', error)
    toast.add({
      severity: 'error',
      summary: t('messages.export_failed'),
      detail: t('messages.failed_to_export_history_logs'),
      life: 5000
    })
  }
}

// Auto-refresh every 5 minutes
let refreshInterval
onMounted(async () => {
  await loadActivity()
  refreshInterval = setInterval(loadActivity, 5 * 60 * 1000)
})

onUnmounted(() => {
  if (refreshInterval) {
    clearInterval(refreshInterval)
  }
})
</script>

<style scoped>
/* Component-specific styles */
:deep(.p-paginator) {
  background: none;
  border: none;
}
</style>