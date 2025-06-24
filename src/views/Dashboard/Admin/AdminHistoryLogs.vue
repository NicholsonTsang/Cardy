<template>
  <div class="space-y-6">
    <!-- Page Header with Stats -->
    <div class="bg-white rounded-xl shadow-sm border border-slate-200 p-6">
      <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 mb-6">
        <div>
          <h1 class="text-2xl font-bold text-slate-900">System History & Logs</h1>
          <p class="text-slate-600 mt-1">Track and analyze all administrative actions and feedback</p>
        </div>
        <div class="flex items-center gap-3">
          <Button 
            icon="pi pi-refresh" 
            label="Refresh" 
            severity="secondary"
            outlined
            @click="refreshData"
            :loading="isLoading"
          />
          <Button 
            icon="pi pi-file-export" 
            label="Export CSV" 
            severity="info"
            @click="exportData"
          />
        </div>
      </div>

      <!-- Quick Stats -->
      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        <div class="bg-slate-50 rounded-lg p-4">
          <div class="text-sm font-medium text-slate-600">Total Actions Today</div>
          <div class="text-2xl font-bold text-slate-900 mt-1">{{ stats.todayActions }}</div>
          <div class="text-xs text-slate-500 mt-1">
            <i class="pi" :class="stats.actionsTrend > 0 ? 'pi-arrow-up text-green-600' : 'pi-arrow-down text-red-600'"></i>
            {{ Math.abs(stats.actionsTrend) }}% from yesterday
          </div>
        </div>
        <div class="bg-slate-50 rounded-lg p-4">
          <div class="text-sm font-medium text-slate-600">Active Admins</div>
          <div class="text-2xl font-bold text-slate-900 mt-1">{{ stats.activeAdmins }}</div>
          <div class="text-xs text-slate-500 mt-1">Last 24 hours</div>
        </div>
        <div class="bg-slate-50 rounded-lg p-4">
          <div class="text-sm font-medium text-slate-600">Pending Reviews</div>
          <div class="text-2xl font-bold text-slate-900 mt-1">{{ stats.pendingReviews }}</div>
          <div class="text-xs text-slate-500 mt-1">Require attention</div>
        </div>
        <div class="bg-slate-50 rounded-lg p-4">
          <div class="text-sm font-medium text-slate-600">System Changes</div>
          <div class="text-2xl font-bold text-slate-900 mt-1">{{ stats.systemChanges }}</div>
          <div class="text-xs text-slate-500 mt-1">Last 7 days</div>
        </div>
      </div>
    </div>

    <!-- Main Content -->
    <div class="bg-white rounded-xl shadow-lg border border-slate-200">
      <!-- Unified Search and Filters -->
      <div class="p-6 border-b border-slate-200">
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
          <span class="p-float-label">
            <InputText
              v-model="filters.searchQuery"
              class="w-full"
              @input="debouncedSearch"
            />
            <label>Search All Fields</label>
          </span>
          <span class="p-float-label">
            <Calendar
              v-model="filters.dateRange"
              selectionMode="range"
              :showIcon="true"
              class="w-full"
              @date-select="handleDateChange"
            />
            <label>Date Range</label>
          </span>
          <span class="p-float-label">
            <MultiSelect
              v-model="filters.types"
              :options="typeOptions"
              optionLabel="label"
              :maxSelectedLabels="2"
              class="w-full"
              @change="handleTypeChange"
            />
            <label>Filter by Type</label>
          </span>
          <div class="flex items-end gap-2">
            <Button
              icon="pi pi-filter"
              label="More Filters"
              text
              @click="showAdvancedFilters = true"
            />
            <Button
              icon="pi pi-filter-slash"
              text
              severity="danger"
              v-tooltip="'Clear All Filters'"
              @click="clearAllFilters"
            />
          </div>
        </div>
      </div>

      <!-- Activity Timeline -->
      <div class="p-6">
        <DataView
          :value="combinedActivities"
          :layout="layout"
          :loading="isLoading"
          :paginator="true"
          :rows="10"
          :sortField="sortField"
          :sortOrder="sortOrder"
          class="p-dataview-sm"
        >
          <template #header>
            <div class="flex justify-between items-center">
              <div class="flex items-center gap-4">
                <h3 class="text-lg font-semibold text-slate-900">Activity Timeline</h3>
                <div class="flex items-center gap-2">
                  <Tag 
                    v-for="filter in activeFilters" 
                    :key="filter.key"
                    :value="filter.label"
                    severity="info"
                    class="text-xs"
                  >
                    <template #icon>
                      <i class="pi pi-times cursor-pointer" @click="removeFilter(filter.key)"></i>
                    </template>
                  </Tag>
                </div>
              </div>
              <div class="flex items-center gap-2">
                <Button
                  icon="pi pi-list"
                  text
                  :class="{ 'text-primary': layout === 'list' }"
                  @click="layout = 'list'"
                  v-tooltip="'List View'"
                />
                <Button
                  icon="pi pi-th-large"
                  text
                  :class="{ 'text-primary': layout === 'grid' }"
                  @click="layout = 'grid'"
                  v-tooltip="'Grid View'"
                />
              </div>
            </div>
          </template>

          <!-- List Layout -->
          <template #list="slotProps">
            <div 
              v-if="slotProps.data"
              class="flex items-start gap-4 p-4 hover:bg-slate-50 border-b border-slate-200 cursor-pointer"
              @click="viewDetails(slotProps.data)"
            >
              <div class="flex-none">
                <div 
                  class="w-10 h-10 rounded-full flex items-center justify-center"
                  :class="getActivityIconClass(slotProps.data)"
                >
                  <i class="pi" :class="getActivityIcon(slotProps.data)"></i>
                </div>
              </div>
              <div class="flex-grow min-w-0">
                <div class="flex items-center gap-2">
                  <span class="font-medium text-slate-900">{{ slotProps.data.admin_email || 'Unknown Admin' }}</span>
                  <Tag :value="slotProps.data.type || 'unknown'" :severity="getActivitySeverity(slotProps.data)" />
                  <span class="text-slate-500 text-sm">{{ formatTimeAgo(slotProps.data.created_at) }}</span>
                </div>
                <p class="text-slate-700 mt-1 line-clamp-2">{{ getActivitySummary(slotProps.data) }}</p>
                <div class="flex items-center gap-2 mt-2">
                  <span v-if="slotProps.data.target_user_email" class="text-sm text-slate-600">
                    <i class="pi pi-user mr-1"></i>{{ slotProps.data.target_user_email }}
                  </span>
                  <span v-if="slotProps.data.version_number" class="text-sm text-slate-600">
                    <i class="pi pi-code-branch mr-1"></i>v{{ slotProps.data.version_number }}
                  </span>
                </div>
              </div>
              <div class="flex-none">
                <Button
                  icon="pi pi-ellipsis-v"
                  text
                  @click.stop="showActivityMenu($event, slotProps.data)"
                />
              </div>
            </div>
          </template>

          <!-- Grid Layout -->
          <template #grid="slotProps">
            <div class="col-12 sm:col-6 lg:col-4 xl:col-3 p-2">
              <div 
                v-if="slotProps.data"
                class="bg-white rounded-lg border border-slate-200 shadow-sm hover:shadow-md transition-shadow cursor-pointer"
                @click="viewDetails(slotProps.data)"
              >
                <div class="p-4">
                  <div class="flex items-center justify-between mb-3">
                    <div 
                      class="w-8 h-8 rounded-full flex items-center justify-center"
                      :class="getActivityIconClass(slotProps.data)"
                    >
                      <i class="pi" :class="getActivityIcon(slotProps.data)"></i>
                    </div>
                    <Tag :value="slotProps.data.type || 'unknown'" :severity="getActivitySeverity(slotProps.data)" />
                  </div>
                  <h4 class="font-medium text-slate-900 mb-1">{{ slotProps.data.admin_email || 'Unknown Admin' }}</h4>
                  <p class="text-slate-700 text-sm line-clamp-3 mb-3">{{ getActivitySummary(slotProps.data) }}</p>
                  <div class="flex items-center justify-between text-sm text-slate-500">
                    <span>{{ formatTimeAgo(slotProps.data.created_at) }}</span>
                    <Button
                      icon="pi pi-ellipsis-v"
                      text
                      @click.stop="showActivityMenu($event, slotProps.data)"
                    />
                  </div>
                </div>
              </div>
            </div>
          </template>
        </DataView>
      </div>
    </div>

    <!-- Advanced Filters Dialog -->
    <Dialog
      v-model:visible="showAdvancedFilters"
      header="Advanced Filters"
      :modal="true"
      :style="{ width: '500px' }"
    >
      <div class="space-y-4">
        <div>
          <label class="block text-sm font-medium text-slate-700 mb-1">Admin Users</label>
          <MultiSelect
            v-model="advancedFilters.adminUsers"
            :options="adminUsers"
            optionLabel="email"
            placeholder="Select admins"
            class="w-full"
          />
        </div>
        <div>
          <label class="block text-sm font-medium text-slate-700 mb-1">Target Users</label>
          <MultiSelect
            v-model="advancedFilters.targetUsers"
            :options="targetUsers"
            optionLabel="email"
            placeholder="Select users"
            class="w-full"
          />
        </div>
        <div>
          <label class="block text-sm font-medium text-slate-700 mb-1">Action Types</label>
          <div class="grid grid-cols-2 gap-2">
            <div v-for="type in actionTypes" :key="type.value" class="flex items-center">
              <Checkbox
                v-model="advancedFilters.actionTypes"
                :value="type.value"
                :binary="false"
              />
              <label class="ml-2 text-sm text-slate-600">{{ type.label }}</label>
            </div>
          </div>
        </div>
      </div>
      <template #footer>
        <Button label="Apply Filters" @click="applyAdvancedFilters" />
        <Button label="Reset" text @click="resetAdvancedFilters" />
      </template>
    </Dialog>

    <!-- Details Dialog -->
    <Dialog
      v-model:visible="showDetailsDialog"
      :header="detailsDialogTitle"
      :modal="true"
      :style="{ width: '600px' }"
      :maximizable="true"
    >
      <div class="space-y-6" v-if="selectedItem">
        <!-- Header Info -->
        <div class="flex items-center justify-between">
          <div class="flex items-center gap-3">
            <div 
              class="w-10 h-10 rounded-full flex items-center justify-center"
              :class="getActivityIconClass(selectedItem)"
            >
              <i class="pi" :class="getActivityIcon(selectedItem)"></i>
            </div>
            <div>
              <h3 class="font-medium text-slate-900">{{ selectedItem.admin_email || 'Unknown Admin' }}</h3>
              <p class="text-sm text-slate-500">{{ formatDate(selectedItem.created_at) }}</p>
            </div>
          </div>
          <Tag :value="selectedItem.type || 'unknown'" :severity="getActivitySeverity(selectedItem)" />
        </div>

        <!-- Content -->
        <div class="space-y-4">
          <!-- Common Fields -->
          <div v-if="selectedItem.target_user_email" class="bg-slate-50 rounded-lg p-4">
            <h4 class="text-sm font-medium text-slate-700 mb-1">Target User</h4>
            <div class="flex items-center gap-2">
              <i class="pi pi-user text-slate-400"></i>
              <span>{{ selectedItem.target_user_email }}</span>
            </div>
          </div>

          <!-- Type-specific Content -->
          <template v-if="selectedItem.type === 'audit'">
            <div>
              <h4 class="text-sm font-medium text-slate-700 mb-2">Changes</h4>
              <div class="grid grid-cols-2 gap-4">
                <div class="bg-red-50 rounded-lg p-4">
                  <div class="text-xs font-medium text-red-800 mb-2">Previous Values</div>
                  <pre class="text-sm text-red-900 whitespace-pre-wrap">{{ formatJSON(selectedItem.old_values) }}</pre>
                </div>
                <div class="bg-green-50 rounded-lg p-4">
                  <div class="text-xs font-medium text-green-800 mb-2">New Values</div>
                  <pre class="text-sm text-green-900 whitespace-pre-wrap">{{ formatJSON(selectedItem.new_values) }}</pre>
                </div>
              </div>
            </div>
          </template>

          <template v-else>
            <div>
              <h4 class="text-sm font-medium text-slate-700 mb-2">Feedback Content</h4>
              <div class="bg-slate-50 rounded-lg p-4">
                <p class="whitespace-pre-wrap">{{ selectedItem.content || 'No content available' }}</p>
              </div>
            </div>
            <div v-if="selectedItem.version_number && selectedItem.version_number > 1">
              <h4 class="text-sm font-medium text-slate-700 mb-2">Version History</h4>
              <Timeline :value="selectedItem.history || []" class="w-full">
                <template #content="slotProps">
                  <div class="text-sm" v-if="slotProps.item">
                    <div class="font-medium">Version {{ slotProps.item.version_number || 1 }}</div>
                    <div class="text-slate-500">{{ formatDate(slotProps.item.created_at) }}</div>
                    <div class="mt-1">{{ slotProps.item.content || 'No content' }}</div>
                  </div>
                </template>
              </Timeline>
            </div>
          </template>

          <!-- Additional Context -->
          <div v-if="selectedItem.action_details || selectedItem.action_context">
            <h4 class="text-sm font-medium text-slate-700 mb-2">Additional Context</h4>
            <div class="bg-slate-50 rounded-lg p-4">
              <pre class="text-sm text-slate-700 whitespace-pre-wrap">{{ formatJSON(selectedItem.action_details || selectedItem.action_context) }}</pre>
            </div>
          </div>
        </div>
      </div>
    </Dialog>

    <!-- Context Menu -->
    <ContextMenu ref="contextMenu" :model="contextMenuItems" />
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useAdminFeedbackStore, useAdminDashboardStore, useAdminVerificationsStore } from '@/stores/admin'
import { useToast } from 'primevue/usetoast'
import Button from 'primevue/button'
import DataView from 'primevue/dataview'
import Dialog from 'primevue/dialog'
import Tag from 'primevue/tag'
import MultiSelect from 'primevue/multiselect'
import Calendar from 'primevue/calendar'
import InputText from 'primevue/inputtext'
import Checkbox from 'primevue/checkbox'
import Timeline from 'primevue/timeline'
import ContextMenu from 'primevue/contextmenu'

const feedbackStore = useAdminFeedbackStore()
const dashboardStore = useAdminDashboardStore()
const verificationsStore = useAdminVerificationsStore()
const toast = useToast()
const contextMenu = ref()

// UI State
const isLoading = ref(false)
const layout = ref('list')
const showDetailsDialog = ref(false)
const showAdvancedFilters = ref(false)
const selectedItem = ref(null)
const sortField = ref('created_at')
const sortOrder = ref(-1)

// Data
const stats = ref({
  todayActions: 0,
  actionsTrend: 0,
  activeAdmins: 0,
  pendingReviews: 0,
  systemChanges: 0
})

const combinedActivities = ref([])
const adminUsers = ref([])
const targetUsers = ref([])

// Filters
const filters = ref({
  searchQuery: '',
  dateRange: null,
  types: []
})

const advancedFilters = ref({
  adminUsers: [],
  targetUsers: [],
  actionTypes: []
})

// Options
const typeOptions = [
  { label: 'Audit Logs', value: 'audit' },
  { label: 'Role Changes', value: 'role_change' },
  { label: 'Verifications', value: 'verification' },
  { label: 'Print Requests', value: 'print_request' },
  { label: 'System Changes', value: 'system' },
  { label: 'Feedback', value: 'feedback' }
]

const actionTypes = [
  { label: 'Role Changes', value: 'ROLE_CHANGE' },
  { label: 'Verification Review', value: 'VERIFICATION_REVIEW' },
  { label: 'Manual Verification', value: 'MANUAL_VERIFICATION' },
  { label: 'Print Request Update', value: 'PRINT_REQUEST_UPDATE' },
  { label: 'System Configuration', value: 'SYSTEM_CONFIG' },
  { label: 'Batch Management', value: 'BATCH_MANAGEMENT' }
]

// Context Menu
const contextMenuItems = computed(() => [
  {
    label: 'View Details',
    icon: 'pi pi-eye',
    command: () => viewDetails(selectedItem.value)
  },
  {
    label: 'Copy ID',
    icon: 'pi pi-copy',
    command: () => copyToClipboard(selectedItem.value.id)
  },
  {
    label: 'Export Entry',
    icon: 'pi pi-download',
    command: () => exportSingleEntry(selectedItem.value)
  },
  {
    separator: true
  },
  {
    label: 'View Related',
    icon: 'pi pi-link',
    command: () => loadRelatedActivities(selectedItem.value)
  }
])

// Computed
const detailsDialogTitle = computed(() => {
  if (!selectedItem.value) return ''
  return selectedItem.value.type === 'audit' ? 'Audit Log Details' : 'Feedback Details'
})

const activeFilters = computed(() => {
  const active = []
  if (filters.value.searchQuery) {
    active.push({ key: 'search', label: `Search: ${filters.value.searchQuery}` })
  }
  if (filters.value.dateRange) {
    active.push({ key: 'date', label: 'Date Range Active' })
  }
  filters.value.types.forEach(type => {
    active.push({ key: `type_${type}`, label: typeOptions.find(t => t.value === type)?.label })
  })
  return active
})

// Methods
const refreshData = async () => {
  isLoading.value = true
  try {
    await Promise.all([
      loadActivities(),
      loadStats(),
      loadUsers()
    ])
  } catch (error) {
    console.error('Error refreshing data:', error)
  } finally {
    isLoading.value = false
  }
}

const loadActivities = async () => {
  const [auditLogs, feedbackHistory] = await Promise.all([
    feedbackStore.getAdminAuditLogs({
      action_type: advancedFilters.value.actionTypes.length ? advancedFilters.value.actionTypes[0] : null,
      admin_user_id: advancedFilters.value.adminUsers.length ? advancedFilters.value.adminUsers[0].user_id : null,
      target_user_id: advancedFilters.value.targetUsers.length ? advancedFilters.value.targetUsers[0].user_id : null,
      start_date: filters.value.dateRange?.[0],
      end_date: filters.value.dateRange?.[1]
    }).catch(error => {
      console.error('Error fetching audit logs:', error)
      return []
    }),
    feedbackStore.getAdminFeedbackHistory({
      target_entity_type: filters.value.types.includes('feedback') ? 'feedback' : null,
      target_entity_id: null,
      feedback_type: null
    }).catch(error => {
      console.error('Error fetching feedback history:', error)
      return []
    })
  ])

  // Combine and format activities
  combinedActivities.value = [
    ...auditLogs.map(log => ({ ...log, type: 'audit' })),
    ...feedbackHistory.map(feedback => ({ ...feedback, type: 'feedback' }))
  ].sort((a, b) => new Date(b.created_at) - new Date(a.created_at))
}

const loadStats = async () => {
  try {
    const dashboardStats = await dashboardStore.fetchDashboardStats()
    stats.value = {
      todayActions: dashboardStats?.today_actions || 0,
      actionsTrend: dashboardStats?.actions_trend || 0,
      activeAdmins: dashboardStats?.active_admins || 0,
      pendingReviews: dashboardStats?.pending_verifications || 0,
      systemChanges: dashboardStats?.system_changes || 0
    }
  } catch (error) {
    console.error('Error loading dashboard stats:', error)
    stats.value = {
      todayActions: 0,
      actionsTrend: 0,
      activeAdmins: 0,
      pendingReviews: 0,
      systemChanges: 0
    }
  }
}

const loadUsers = async () => {
  try {
    const users = await verificationsStore.loadUsersWithDetails()
    adminUsers.value = users.filter(u => u.role === 'admin')
    targetUsers.value = users
  } catch (error) {
    console.error('Error loading users:', error)
    adminUsers.value = []
    targetUsers.value = []
  }
}

const handleDateChange = () => {
  refreshData()
}

const handleTypeChange = () => {
  refreshData()
}

const clearAllFilters = () => {
  filters.value = {
    searchQuery: '',
    dateRange: null,
    types: []
  }
  advancedFilters.value = {
    adminUsers: [],
    targetUsers: [],
    actionTypes: []
  }
  refreshData()
}

const removeFilter = (key) => {
  if (key === 'search') {
    filters.value.searchQuery = ''
  } else if (key === 'date') {
    filters.value.dateRange = null
  } else if (key.startsWith('type_')) {
    const type = key.replace('type_', '')
    filters.value.types = filters.value.types.filter(t => t !== type)
  }
  refreshData()
}

const viewDetails = (item) => {
  if (!item) {
    console.warn('No item provided to viewDetails')
    return
  }
  selectedItem.value = item
  showDetailsDialog.value = true
}

const showActivityMenu = (event, item) => {
  if (!item) {
    console.warn('No item provided to showActivityMenu')
    return
  }
  selectedItem.value = item
  contextMenu.value.show(event)
}

const formatTimeAgo = (date) => {
  if (!date) return 'Unknown time'
  
  const now = new Date()
  const past = new Date(date)
  const diffMs = now - past
  const diffSecs = Math.floor(diffMs / 1000)
  const diffMins = Math.floor(diffSecs / 60)
  const diffHours = Math.floor(diffMins / 60)
  const diffDays = Math.floor(diffHours / 24)
  const diffMonths = Math.floor(diffDays / 30)
  const diffYears = Math.floor(diffDays / 365)

  if (diffSecs < 60) {
    return 'just now'
  } else if (diffMins < 60) {
    return `${diffMins} ${diffMins === 1 ? 'minute' : 'minutes'} ago`
  } else if (diffHours < 24) {
    return `${diffHours} ${diffHours === 1 ? 'hour' : 'hours'} ago`
  } else if (diffDays < 30) {
    return `${diffDays} ${diffDays === 1 ? 'day' : 'days'} ago`
  } else if (diffMonths < 12) {
    return `${diffMonths} ${diffMonths === 1 ? 'month' : 'months'} ago`
  } else {
    return `${diffYears} ${diffYears === 1 ? 'year' : 'years'} ago`
  }
}

const formatDate = (dateString) => {
  if (!dateString) return 'Unknown date'
  
  const date = new Date(dateString)
  const options = {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
    hour12: true
  }
  return new Intl.DateTimeFormat('en-US', options).format(date)
}

const formatJSON = (json) => {
  try {
    return JSON.stringify(json, null, 2)
  } catch {
    return 'Invalid JSON'
  }
}

const getActivitySeverity = (activity) => {
  if (!activity) return 'secondary'
  
  if (activity.type === 'audit') {
    const severities = {
      'ROLE_CHANGE': 'warning',
      'VERIFICATION_REVIEW': 'info',
      'MANUAL_VERIFICATION': 'success',
      'PRINT_REQUEST_UPDATE': 'info',
      'SYSTEM_CONFIG': 'danger',
      'BATCH_MANAGEMENT': 'warning'
    }
    return severities[activity.action_type] || 'secondary'
  }
  
  const severities = {
    'verification_feedback': 'info',
    'print_notes': 'success',
    'role_change_reason': 'warning'
  }
  return severities[activity.feedback_type] || 'secondary'
}

const getActivityIcon = (activity) => {
  if (!activity) return 'pi-info-circle'
  
  if (activity.type === 'audit') {
    const icons = {
      'ROLE_CHANGE': 'pi-users',
      'VERIFICATION_REVIEW': 'pi-check-circle',
      'MANUAL_VERIFICATION': 'pi-shield',
      'PRINT_REQUEST_UPDATE': 'pi-print',
      'SYSTEM_CONFIG': 'pi-cog',
      'BATCH_MANAGEMENT': 'pi-box'
    }
    return icons[activity.action_type] || 'pi-info-circle'
  }
  
  const icons = {
    'verification_feedback': 'pi-comment',
    'print_notes': 'pi-file-edit',
    'role_change_reason': 'pi-user-edit'
  }
  return icons[activity.feedback_type] || 'pi-comment'
}

const getActivityIconClass = (activity) => {
  if (!activity) return 'bg-slate-500 text-white'
  
  const baseClasses = 'text-white'
  if (activity.type === 'audit') {
    const classes = {
      'ROLE_CHANGE': 'bg-yellow-500',
      'VERIFICATION_REVIEW': 'bg-blue-500',
      'MANUAL_VERIFICATION': 'bg-green-500',
      'PRINT_REQUEST_UPDATE': 'bg-purple-500',
      'SYSTEM_CONFIG': 'bg-red-500',
      'BATCH_MANAGEMENT': 'bg-orange-500'
    }
    return `${baseClasses} ${classes[activity.action_type] || 'bg-slate-500'}`
  }
  
  const classes = {
    'verification_feedback': 'bg-blue-500',
    'print_notes': 'bg-green-500',
    'role_change_reason': 'bg-yellow-500'
  }
  return `${baseClasses} ${classes[activity.feedback_type] || 'bg-slate-500'}`
}

const getActivitySummary = (activity) => {
  if (!activity) return 'No activity data'
  
  if (activity.type === 'audit') {
    return activity.reason || 'No reason provided'
  }
  return activity.content || 'No content available'
}

const copyToClipboard = async (text) => {
  try {
    await navigator.clipboard.writeText(text)
    toast.add({
      severity: 'success',
      summary: 'Copied',
      detail: 'ID copied to clipboard',
      life: 2000
    })
  } catch (error) {
    console.error('Failed to copy:', error)
  }
}

const exportSingleEntry = (item) => {
  // Implementation for exporting a single entry
  console.log('Exporting entry:', item)
}

const loadRelatedActivities = (item) => {
  if (!item) {
    console.warn('No item provided to loadRelatedActivities')
    return
  }
  filters.value.searchQuery = item.target_user_email || item.admin_email || ''
  refreshData()
}

const exportData = () => {
  // Implementation for exporting all filtered data to CSV
  console.log('Exporting all data')
}

// Search debouncing
let searchTimeout = null
const debouncedSearch = () => {
  clearTimeout(searchTimeout)
  searchTimeout = setTimeout(() => {
    refreshData()
  }, 300)
}

onMounted(() => {
  refreshData()
})
</script>

<style scoped>
:deep(.p-dataview .p-dataview-content) {
  background: transparent;
  border: none;
  padding: 0;
}

:deep(.p-float-label) {
  display: block;
}

:deep(.p-float-label label) {
  background: white;
}

:deep(.p-tag) {
  font-size: 0.75rem;
}

:deep(.p-button) {
  font-size: 0.875rem;
}

:deep(.p-timeline) {
  margin: 0;
  padding: 0;
}

:deep(.p-timeline .p-timeline-event-content) {
  line-height: 1.2;
}

:deep(.p-contextmenu) {
  font-size: 0.875rem;
}

.line-clamp-2 {
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

.line-clamp-3 {
  display: -webkit-box;
  -webkit-line-clamp: 3;
  -webkit-box-orient: vertical;
  overflow: hidden;
}
</style> 