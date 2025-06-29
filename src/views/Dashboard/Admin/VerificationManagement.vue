<template>
  <div class="space-y-6">
    <!-- Page Header -->
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
      <div>
        <h1 class="text-2xl font-bold text-slate-900">Verification Management</h1>
        <p class="text-slate-600 mt-1">Review and manage user verification submissions</p>
      </div>
      <div class="flex items-center gap-3">
        <Button 
          icon="pi pi-refresh" 
          label="Refresh" 
          outlined
          @click="refreshData"
          :loading="verificationsStore.isLoadingVerifications"
        />
      </div>
    </div>

    <!-- Enhanced Filters and Search -->
    <div class="bg-white rounded-xl shadow-lg border border-slate-200 p-6">
      <h3 class="text-lg font-semibold text-slate-900 mb-4">Filters & Search</h3>
      <div class="grid grid-cols-1 md:grid-cols-6 gap-4">
        <!-- Search -->
        <div class="md:col-span-2">
          <IconField>
            <InputIcon class="pi pi-search" />
            <InputText 
              v-model="searchQuery"
              placeholder="Search by name, email, company..."
              class="w-full"
              @input="debouncedSearch"
            />
          </IconField>
        </div>
        
        <!-- Status Filter -->
        <div>
          <Select 
            v-model="selectedStatus" 
            :options="statusOptions"
            optionLabel="label"
            optionValue="value"
            placeholder="Verification Status"
            class="w-full"
            @change="onStatusFilterChange"
            showClear
          />
        </div>
        
        <!-- Date Range Filter -->
        <div>
          <Calendar 
            v-model="dateRange"
            selectionMode="range"
            :manualInput="false"
            placeholder="Date Range"
            class="w-full"
            @date-select="filterByDateRange"
            showIcon
            dateFormat="mm/dd/yy"
          />
        </div>
        
        <!-- Document Count Filter -->
        <div>
          <Select 
            v-model="selectedDocumentFilter"
            :options="documentFilterOptions"
            optionLabel="label"
            optionValue="value"
            placeholder="Documents"
            class="w-full"
            @change="filterVerifications"
            showClear
          />
        </div>
        
        <!-- Sort By -->
        <div>
          <Select 
            v-model="selectedSortBy"
            :options="sortOptions"
            optionLabel="label"
            optionValue="value"
            placeholder="Sort By"
            class="w-full"
            @change="sortVerifications"
          />
        </div>
      </div>
      
      <!-- Filter Summary -->
      <div class="flex justify-between items-center mt-4">
        <div class="flex items-center gap-4">
          <p class="text-sm text-slate-600">
            Showing {{ filteredVerifications.length }} of {{ allVerifications.length }} verifications
          </p>
          <div v-if="hasActiveFilters" class="flex gap-2">
            <Tag 
              v-if="searchQuery" 
              :value="`Search: ${searchQuery}`" 
              severity="info" 
              class="text-xs"
            />
            <Tag 
              v-if="selectedStatus" 
              :value="`Status: ${selectedStatus}`" 
              severity="secondary" 
              class="text-xs"
            />
            <Tag 
              v-if="dateRange && dateRange.length === 2" 
              value="Date Range Applied" 
              severity="success" 
              class="text-xs"
            />
            <Tag 
              v-if="selectedDocumentFilter" 
              :value="`Docs: ${getDocumentFilterLabel(selectedDocumentFilter)}`" 
              severity="warning" 
              class="text-xs"
            />
          </div>
        </div>
        <Button 
          v-if="hasActiveFilters"
          label="Clear All Filters" 
          icon="pi pi-times"
          text
          @click="clearAllFilters"
          size="small"
        />
      </div>
    </div>

    <!-- Statistics Cards -->
    <div class="grid grid-cols-1 md:grid-cols-4 gap-6">
      <div class="bg-white rounded-xl shadow-lg border border-slate-200 p-6">
        <div class="flex items-center justify-between">
          <div>
            <h3 class="text-sm font-medium text-slate-600 mb-2">Pending Review</h3>
            <p class="text-3xl font-bold text-amber-600">{{ getFilteredStatusCount('PENDING_REVIEW') }}</p>
            <p class="text-xs text-slate-500 mt-1">{{ stats.pendingVerifications?.length || 0 }} total</p>
          </div>
          <div class="p-4 bg-gradient-to-r from-amber-500 to-orange-500 rounded-xl">
            <i class="pi pi-clock text-white text-2xl"></i>
          </div>
        </div>
      </div>

      <div class="bg-white rounded-xl shadow-lg border border-slate-200 p-6">
        <div class="flex items-center justify-between">
          <div>
            <h3 class="text-sm font-medium text-slate-600 mb-2">Approved</h3>
            <p class="text-3xl font-bold text-green-600">{{ getFilteredStatusCount('APPROVED') }}</p>
            <p class="text-xs text-slate-500 mt-1">{{ stats.approved_verifications || 0 }} total</p>
          </div>
          <div class="p-4 bg-gradient-to-r from-green-500 to-emerald-500 rounded-xl">
            <i class="pi pi-check-circle text-white text-2xl"></i>
          </div>
        </div>
      </div>

      <div class="bg-white rounded-xl shadow-lg border border-slate-200 p-6">
        <div class="flex items-center justify-between">
          <div>
            <h3 class="text-sm font-medium text-slate-600 mb-2">Rejected</h3>
            <p class="text-3xl font-bold text-red-600">{{ getFilteredStatusCount('REJECTED') }}</p>
            <p class="text-xs text-slate-500 mt-1">{{ stats.rejected_verifications || 0 }} total</p>
          </div>
          <div class="p-4 bg-gradient-to-r from-red-500 to-rose-500 rounded-xl">
            <i class="pi pi-times-circle text-white text-2xl"></i>
          </div>
        </div>
      </div>

      <div class="bg-white rounded-xl shadow-lg border border-slate-200 p-6">
        <div class="flex items-center justify-between">
          <div>
            <h3 class="text-sm font-medium text-slate-600 mb-2">Avg. Review Time</h3>
            <p class="text-3xl font-bold text-slate-900">{{ averageReviewTime }}</p>
            <p class="text-xs text-slate-500 mt-1">days</p>
          </div>
          <div class="p-4 bg-gradient-to-r from-blue-500 to-indigo-500 rounded-xl">
            <i class="pi pi-chart-line text-white text-2xl"></i>
          </div>
        </div>
      </div>
    </div>

    <!-- Verification Table -->
    <div class="bg-white rounded-xl shadow-lg border border-slate-200 overflow-hidden">
      <div class="p-6 border-b border-slate-200 bg-gradient-to-r from-slate-50 to-slate-100">
        <div class="flex items-center justify-between">
          <h3 class="text-lg font-semibold text-slate-900">All Verifications</h3>
          <div class="flex items-center gap-3">
            <Select 
              v-model="selectedStatus" 
              :options="statusOptions"
              optionLabel="label"
              optionValue="value"
              placeholder="Filter by Status"
              @change="onStatusFilterChange"
              class="w-48"
            />
          </div>
        </div>
      </div>
      
      <div class="p-6">
        <DataTable 
          :value="displayedVerifications" 
          :loading="verificationsStore.isLoadingVerifications"
          :paginator="true" 
          :rows="20"
          :rowsPerPageOptions="[10, 20, 50]"
          responsiveLayout="scroll"
          class="border-0"
          dataKey="user_id"
          :globalFilterFields="['user_email', 'public_name', 'full_name', 'company_name']"
        >
          <template #empty>
            <EmptyState 
              v-bind="currentEmptyStateConfig"
              @action="handleEmptyStateAction"
            />
          </template>
          <template #header>
            <div class="flex justify-between items-center">
              <span class="text-lg font-semibold text-slate-900">
                Verification Submissions ({{ displayedVerifications.length }})
              </span>
              <IconField>
                <InputIcon>
                  <i class="pi pi-search" />
                </InputIcon>
                <InputText 
                  v-model="filters['global'].value" 
                  placeholder="Search verifications..." 
                />
              </IconField>
            </div>
          </template>

          <Column field="user_email" header="User" sortable style="min-width:200px">
            <template #body="{ data }">
              <div>
                <div class="font-medium text-slate-900">{{ data.public_name || 'Unnamed User' }}</div>
                <div class="text-sm text-slate-600">{{ data.user_email }}</div>
                <div v-if="data.company_name" class="text-xs text-slate-500">{{ data.company_name }}</div>
              </div>
            </template>
          </Column>

          <Column field="full_name" header="Legal Name" sortable>
            <template #body="{ data }">
              <span class="text-sm text-slate-900">{{ data.full_name }}</span>
            </template>
          </Column>

          <Column field="verification_status" header="Status" sortable>
            <template #body="{ data }">
              <Tag 
                :value="data.verification_status" 
                :severity="getVerificationSeverity(data.verification_status)"
                class="px-3 py-1"
              />
            </template>
          </Column>

          <Column field="supporting_documents" header="Documents">
            <template #body="{ data }">
              <div class="flex items-center gap-2">
                <i class="pi pi-file text-slate-500"></i>
                <span class="text-sm text-slate-600">
                  {{ data.supporting_documents?.length || 0 }} files
                </span>
              </div>
            </template>
          </Column>

          <Column field="updated_at" header="Last Updated" sortable>
            <template #body="{ data }">
              <span class="text-sm text-slate-600">{{ formatDate(data.updated_at) }}</span>
            </template>
          </Column>

          <Column field="verified_at" header="Verified Date" sortable>
            <template #body="{ data }">
              <span class="text-sm text-slate-600">
                {{ data.verified_at ? formatDate(data.verified_at) : '-' }}
              </span>
            </template>
          </Column>

          <Column header="Actions" :exportable="false" style="min-width:120px">
            <template #body="{ data }">
              <div class="flex gap-2">
                <Button 
                  icon="pi pi-eye" 
                  severity="info" 
                  outlined
                  size="small"
                  @click="openVerificationReview(data)" 
                  v-tooltip.top="'View & Review'"
                />
                <Button 
                  v-if="data.verification_status === 'PENDING_REVIEW'"
                  icon="pi pi-check" 
                  severity="success" 
                  outlined
                  size="small"
                  @click="quickApprove(data)" 
                  v-tooltip.top="'Quick Approve'"
                />
                <Button 
                  v-if="data.verification_status === 'PENDING_REVIEW'"
                  icon="pi pi-times" 
                  severity="danger" 
                  outlined
                  size="small"
                  @click="quickReject(data)" 
                  v-tooltip.top="'Quick Reject'"
                />
              </div>
            </template>
          </Column>
        </DataTable>
      </div>
    </div>

    <!-- Verification Review Dialog -->
    <MyDialog
      v-model="showVerificationDialog"
      header="Review Verification"
      :confirmHandle="handleVerificationReview"
      :confirmLabel="reviewAction === 'APPROVED' ? 'Approve Verification' : 'Reject Verification'"
      :confirmSeverity="reviewAction === 'APPROVED' ? 'success' : 'danger'"
      successMessage="Verification reviewed successfully"
      errorMessage="Failed to review verification"
      @hide="closeVerificationDialog"
      style="width: 95vw; max-width: 900px; max-height: 90vh;"
    >
      <div v-if="selectedVerification" class="space-y-6">
        <!-- User Information -->
        <div class="bg-slate-50 rounded-lg p-6">
          <h4 class="text-lg font-semibold text-slate-900 mb-4 flex items-center gap-2">
            <i class="pi pi-user text-blue-600"></i>
            User Information
          </h4>
          <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div class="space-y-4">
              <div>
                <label class="text-sm font-medium text-slate-700">Email Address</label>
                <p class="text-sm text-slate-900 mt-1 font-mono bg-white px-3 py-2 rounded border border-slate-200">
                  {{ selectedVerification.user_email }}
                </p>
              </div>
              <div>
                <label class="text-sm font-medium text-slate-700">Public Display Name</label>
                <p class="text-sm text-slate-900 mt-1 bg-white px-3 py-2 rounded border border-slate-200">
                  {{ selectedVerification.public_name || 'Not provided' }}
                </p>
              </div>
              <div>
                <label class="text-sm font-medium text-slate-700">Legal Full Name</label>
                <p class="text-sm text-slate-900 mt-1 bg-white px-3 py-2 rounded border border-slate-200">
                  {{ selectedVerification.full_name || 'Not provided' }}
                </p>
              </div>
            </div>
            <div class="space-y-4">
              <div>
                <label class="text-sm font-medium text-slate-700">Company/Organization</label>
                <p class="text-sm text-slate-900 mt-1 bg-white px-3 py-2 rounded border border-slate-200">
                  {{ selectedVerification.company_name || 'Not provided' }}
                </p>
              </div>
              <div>
                <label class="text-sm font-medium text-slate-700">Current Status</label>
                <div class="mt-1">
                  <Tag 
                    :value="selectedVerification.verification_status" 
                    :severity="getVerificationSeverity(selectedVerification.verification_status)"
                    class="px-3 py-1"
                  />
                </div>
              </div>
              <div>
                <label class="text-sm font-medium text-slate-700">Submission Date</label>
                <p class="text-sm text-slate-900 mt-1 bg-white px-3 py-2 rounded border border-slate-200">
                  {{ formatDate(selectedVerification.updated_at) }}
                </p>
              </div>
            </div>
          </div>
          <div class="mt-4">
            <label class="text-sm font-medium text-slate-700">Bio Description</label>
            <p class="text-sm text-slate-900 mt-1 bg-white px-3 py-2 rounded border border-slate-200 whitespace-pre-wrap">
              {{ selectedVerification.bio || 'Not provided' }}
            </p>
          </div>
        </div>

        <!-- Supporting Documents -->
        <div v-if="selectedVerification.supporting_documents?.length" class="bg-blue-50 rounded-lg p-6">
          <h4 class="text-lg font-semibold text-slate-900 mb-4 flex items-center gap-2">
            <i class="pi pi-file text-blue-600"></i>
            Supporting Documents ({{ selectedVerification.supporting_documents.length }})
          </h4>
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div 
              v-for="(doc, index) in selectedVerification.supporting_documents" 
              :key="index"
              class="flex items-center justify-between p-4 bg-white rounded-lg border border-blue-200 hover:border-blue-300 transition-colors"
            >
              <div class="flex items-center gap-3">
                <div class="w-10 h-10 bg-blue-100 rounded-lg flex items-center justify-center">
                  <i class="pi pi-file-pdf text-blue-600"></i>
                </div>
                <div>
                  <p class="text-sm font-medium text-slate-900">{{ getDocumentName(doc) }}</p>
                  <p class="text-xs text-slate-500">Document {{ index + 1 }}</p>
                </div>
              </div>
              <Button 
                label="View" 
                icon="pi pi-external-link"
                size="small"
                outlined
                @click="viewDocument(doc)"
              />
            </div>
          </div>
        </div>

        <!-- Previous Admin Feedback -->
        <div v-if="selectedVerification.admin_feedback" class="bg-amber-50 rounded-lg p-6">
          <h4 class="text-lg font-semibold text-slate-900 mb-4 flex items-center gap-2">
            <i class="pi pi-comment text-amber-600"></i>
            Previous Admin Feedback
          </h4>
          <p class="text-sm text-amber-900 bg-white px-4 py-3 rounded border border-amber-200 whitespace-pre-wrap">
            {{ selectedVerification.admin_feedback }}
          </p>
        </div>

        <!-- Review Decision -->
        <div class="bg-slate-50 rounded-lg p-6">
          <h4 class="text-lg font-semibold text-slate-900 mb-4 flex items-center gap-2">
            <i class="pi pi-gavel text-red-600"></i>
            Admin Review Decision
          </h4>
          
          <div class="flex gap-4 mb-6">
            <Button 
              label="Approve Verification" 
              icon="pi pi-check"
              severity="success"
              size="large"
              :outlined="reviewAction !== 'APPROVED'"
              @click="reviewAction = 'APPROVED'"
              class="flex-1"
            />
            <Button 
              label="Reject Verification" 
              icon="pi pi-times"
              severity="danger"
              size="large"
              :outlined="reviewAction !== 'REJECTED'"
              @click="reviewAction = 'REJECTED'"
              class="flex-1"
            />
          </div>
          
          <div>
            <label class="block text-sm font-medium text-slate-700 mb-2">
              Admin Feedback
              <span v-if="reviewAction === 'REJECTED'" class="text-red-600">*</span>
            </label>
            <Textarea 
              v-model="reviewFeedback" 
              rows="6"
              class="w-full"
              :placeholder="reviewAction === 'APPROVED' 
                ? 'Optional: Add notes about the approval. This will be visible to the user.' 
                : 'Required: Explain why this verification was rejected. Be specific about what needs to be corrected.'"
            />
            <p class="text-xs text-slate-500 mt-2">
              This feedback will be shared with the user via email notification.
            </p>
          </div>
        </div>
      </div>
    </MyDialog>

    <!-- Quick Action Confirmation Dialogs -->
    <ConfirmDialog group="quickApprove"></ConfirmDialog>
    <ConfirmDialog group="quickReject"></ConfirmDialog>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, watch } from 'vue'
import { useRouter } from 'vue-router'
import { useAdminVerificationsStore, useAdminFeedbackStore, useAdminDashboardStore } from '@/stores/admin'
import { useToast } from 'primevue/usetoast'
import Button from 'primevue/button'
import DataView from 'primevue/dataview'
import Dialog from 'primevue/dialog'
import Tag from 'primevue/tag'
import Textarea from 'primevue/textarea'
import Dropdown from 'primevue/dropdown'
import Select from 'primevue/select'
import InputText from 'primevue/inputtext'
import Skeleton from 'primevue/skeleton'
import ConfirmDialog from 'primevue/confirmdialog'
import { useConfirm } from 'primevue/useconfirm'
import { FilterMatchMode } from '@primevue/core/api'
import DataTable from 'primevue/datatable'
import Column from 'primevue/column'
import IconField from 'primevue/iconfield'
import InputIcon from 'primevue/inputicon'
import MyDialog from '@/components/MyDialog.vue'
import Calendar from 'primevue/calendar'
import EmptyState from '@/components/EmptyState.vue'
import { getEmptyStateConfig, determineEmptyScenario } from '@/utils/emptyStateConfigs.js'

const router = useRouter()
const verificationsStore = useAdminVerificationsStore()
const feedbackStore = useAdminFeedbackStore()
const dashboardStore = useAdminDashboardStore()
const toast = useToast()
const confirm = useConfirm()

// Reactive data
const showVerificationDialog = ref(false)
const selectedVerification = ref(null)
const selectedStatus = ref(null)
const reviewAction = ref('APPROVED')
const reviewFeedback = ref('')

// Enhanced filtering data
const searchQuery = ref('')
const dateRange = ref(null)
const selectedDocumentFilter = ref(null)
const selectedSortBy = ref(null)
const allVerifications = ref([])
const filteredVerifications = ref([])

// Debounced search
let searchTimeout = null
const debouncedSearch = () => {
  clearTimeout(searchTimeout)
  searchTimeout = setTimeout(() => {
    filterVerifications()
  }, 300)
}

const filters = ref({
  global: { value: null, matchMode: FilterMatchMode.CONTAINS }
})

// Computed
const stats = computed(() => dashboardStore.dashboardStats || {})

const statusOptions = [
  { label: 'All Statuses', value: null },
  { label: 'Pending Review', value: 'PENDING_REVIEW' },
  { label: 'Approved', value: 'APPROVED' },
  { label: 'Rejected', value: 'REJECTED' }
]

const documentFilterOptions = [
  { label: 'All Documents', value: null },
  { label: 'No Documents', value: 'none' },
  { label: '1 Document', value: '1' },
  { label: '2+ Documents', value: '2+' },
  { label: '3+ Documents', value: '3+' }
]

const sortOptions = [
  { label: 'Newest First', value: 'newest' },
  { label: 'Oldest First', value: 'oldest' },
  { label: 'Name A-Z', value: 'name_asc' },
  { label: 'Name Z-A', value: 'name_desc' },
  { label: 'Status', value: 'status' }
]

const hasActiveFilters = computed(() => {
  return !!(
    searchQuery.value || 
    selectedStatus.value || 
    (dateRange.value && dateRange.value.length === 2) ||
    selectedDocumentFilter.value ||
    selectedSortBy.value
  )
})

const averageReviewTime = computed(() => {
  const processedVerifications = allVerifications.value.filter(v => 
    v.verification_status !== 'PENDING_REVIEW' && v.verified_at
  )
  
  if (processedVerifications.length === 0) return '0'
  
  const totalDays = processedVerifications.reduce((sum, v) => {
    const submittedDate = new Date(v.updated_at)
    const reviewedDate = new Date(v.verified_at)
    const diffDays = Math.abs((reviewedDate - submittedDate) / (1000 * 60 * 60 * 24))
    return sum + diffDays
  }, 0)
  
  return Math.round(totalDays / processedVerifications.length)
})

const displayedVerifications = computed(() => {
  return filteredVerifications.value
})

// Empty state configuration
const currentEmptyStateConfig = computed(() => {
  const scenario = determineEmptyScenario(
    displayedVerifications.value,
    verificationsStore.isLoadingVerifications,
    false, // hasError - could be extended with error handling
    hasActiveFilters.value
  )
  
  if (!scenario) return null
  
  return getEmptyStateConfig('verifications', scenario)
})

// Enhanced filtering methods
const filterVerifications = () => {
  let filtered = [...allVerifications.value]
  
  // Text search
  if (searchQuery.value) {
    const query = searchQuery.value.toLowerCase()
    filtered = filtered.filter(v => 
      (v.user_email && v.user_email.toLowerCase().includes(query)) ||
      (v.public_name && v.public_name.toLowerCase().includes(query)) ||
      (v.full_name && v.full_name.toLowerCase().includes(query)) ||
      (v.company_name && v.company_name.toLowerCase().includes(query))
    )
  }
  
  // Status filter
  if (selectedStatus.value) {
    filtered = filtered.filter(v => v.verification_status === selectedStatus.value)
  }
  
  // Date range filter
  if (dateRange.value && dateRange.value.length === 2) {
    const [startDate, endDate] = dateRange.value
    filtered = filtered.filter(v => {
      const verificationDate = new Date(v.updated_at)
      return verificationDate >= startDate && verificationDate <= endDate
    })
  }
  
  // Document count filter
  if (selectedDocumentFilter.value) {
    filtered = filtered.filter(v => {
      const docCount = v.supporting_documents?.length || 0
      switch (selectedDocumentFilter.value) {
        case 'none': return docCount === 0
        case '1': return docCount === 1
        case '2+': return docCount >= 2
        case '3+': return docCount >= 3
        default: return true
      }
    })
  }
  
  // Sort results
  if (selectedSortBy.value) {
    filtered = sortVerificationData(filtered, selectedSortBy.value)
  }
  
  filteredVerifications.value = filtered
}

const sortVerificationData = (data, sortBy) => {
  return [...data].sort((a, b) => {
    switch (sortBy) {
      case 'newest':
        return new Date(b.updated_at) - new Date(a.updated_at)
      case 'oldest':
        return new Date(a.updated_at) - new Date(b.updated_at)
      case 'name_asc':
        return (a.public_name || '').localeCompare(b.public_name || '')
      case 'name_desc':
        return (b.public_name || '').localeCompare(a.public_name || '')
      case 'status':
        return a.verification_status.localeCompare(b.verification_status)
      default:
        return 0
    }
  })
}

const sortVerifications = () => {
  filterVerifications()
}

const filterByDateRange = () => {
  filterVerifications()
}

const clearAllFilters = () => {
  searchQuery.value = ''
  selectedStatus.value = null
  dateRange.value = null
  selectedDocumentFilter.value = null
  selectedSortBy.value = null
  filterVerifications()
}

const getFilteredStatusCount = (status) => {
  return filteredVerifications.value.filter(v => v.verification_status === status).length
}

const getDocumentFilterLabel = (value) => {
  const option = documentFilterOptions.find(o => o.value === value)
  return option ? option.label : value
}

// Methods
const refreshData = async () => {
  await Promise.all([
    verificationsStore.fetchAllVerifications(),
    dashboardStore.fetchDashboardStats()
  ])
  allVerifications.value = verificationsStore.allVerifications
  filterVerifications()
}

const handleEmptyStateAction = () => {
  if (hasActiveFilters.value) {
    clearAllFilters()
  }
}

const onStatusFilterChange = async () => {
  filterVerifications()
}

const formatDate = (dateString) => {
  return new Date(dateString).toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  })
}

const getVerificationSeverity = (status) => {
  switch (status) {
    case 'PENDING_REVIEW': return 'warning'
    case 'APPROVED': return 'success'
    case 'REJECTED': return 'danger'
    default: return 'secondary'
  }
}

const getDocumentName = (url) => {
  try {
    const urlParts = url.split('/')
    return urlParts[urlParts.length - 1] || 'Document'
  } catch {
    return 'Document'
  }
}

const viewDocument = (documentUrl) => {
  window.open(documentUrl, '_blank')
}

const openVerificationReview = (verification) => {
  selectedVerification.value = verification
  reviewAction.value = verification.verification_status === 'REJECTED' ? 'REJECTED' : 'APPROVED'
  reviewFeedback.value = verification.admin_feedback || ''
  showVerificationDialog.value = true
}

const closeVerificationDialog = () => {
  selectedVerification.value = null
  reviewAction.value = 'APPROVED'
  reviewFeedback.value = ''
  showVerificationDialog.value = false
}

const handleVerificationReview = async () => {
  if (!selectedVerification.value) return Promise.reject('No verification selected')
  
  if (reviewAction.value === 'REJECTED' && !reviewFeedback.value.trim()) {
    return Promise.reject('Feedback is required when rejecting a verification')
  }

  try {
    await verificationsStore.reviewVerification(
      selectedVerification.value.user_id,
      reviewAction.value,
      reviewFeedback.value.trim() || (reviewAction.value === 'APPROVED' ? 'Verification approved by admin' : '')
    )
    
    await refreshData()
    return Promise.resolve()
  } catch (error) {
    return Promise.reject(error.message || 'Failed to review verification')
  }
}

const quickApprove = (verification) => {
  confirm.require({
    group: 'quickApprove',
    message: `Are you sure you want to approve the verification for ${verification.user_email}?`,
    header: 'Quick Approve Verification',
    icon: 'pi pi-check-circle',
    acceptLabel: 'Approve',
    rejectLabel: 'Cancel',
    acceptClass: 'p-button-success',
    accept: async () => {
      try {
        await verificationsStore.reviewVerification(
          verification.user_id,
          'APPROVED',
          'Verification approved by admin'
        )
        toast.add({ 
          severity: 'success', 
          summary: 'Approved', 
          detail: `Verification for ${verification.user_email} approved successfully`, 
          life: 3000 
        })
        await refreshData()
      } catch (error) {
        toast.add({ 
          severity: 'error', 
          summary: 'Error', 
          detail: 'Failed to approve verification', 
          life: 3000 
        })
      }
    }
  })
}

const quickReject = (verification) => {
  confirm.require({
    group: 'quickReject',
    message: `Are you sure you want to reject the verification for ${verification.user_email}? You'll need to provide feedback in the detailed review.`,
    header: 'Quick Reject - Feedback Required',
    icon: 'pi pi-exclamation-triangle',
    acceptLabel: 'Open Detailed Review',
    rejectLabel: 'Cancel',
    acceptClass: 'p-button-warning',
    accept: () => {
      openVerificationReview(verification)
      reviewAction.value = 'REJECTED'
    }
  })
}

// Initialize data on mount
onMounted(async () => {
  await refreshData()
})
</script>

<style scoped>
/* Component-specific styles - global table theme now handles standard styling */

/* Dialog max height handling */
:deep(.p-dialog-content) {
  max-height: 70vh;
  overflow-y: auto;
}
</style> 