<template>
  <PageWrapper title="Print Request Management" description="Manage physical card printing for paid batches">
    <template #actions>
      <Button 
        icon="pi pi-refresh" 
        label="Refresh" 
        severity="secondary"
        outlined
        @click="refreshData"
        :loading="printRequestsStore.isLoadingPrintRequests"
      />
      <Button 
        icon="pi pi-download" 
        label="Export CSV" 
        severity="secondary"
        outlined
        @click="exportToCsv"
      />
    </template>

    <div class="space-y-6">

    <!-- Enhanced Filters and Search -->
    <div class="bg-white rounded-xl shadow-soft border border-slate-200 p-6">
      <h3 class="text-lg font-semibold text-slate-900 mb-4">Filters & Search</h3>
      <div class="grid grid-cols-1 md:grid-cols-6 gap-4">
        <!-- Search -->
        <div class="md:col-span-2">
          <IconField>
            <InputIcon class="pi pi-search" />
            <InputText 
              v-model="searchQuery"
              placeholder="Search by user, card name, batch..."
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
            placeholder="Request Status"
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
        
        <!-- Batch Size Filter -->
        <div>
          <Select 
            v-model="selectedBatchSizeFilter"
            :options="batchSizeFilterOptions"
            optionLabel="label"
            optionValue="value"
            placeholder="Batch Size"
            class="w-full"
            @change="filterPrintRequests"
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
            @change="sortPrintRequests"
          />
        </div>
      </div>
      
      <!-- Filter Summary -->
      <div class="flex justify-between items-center mt-4">
        <div class="flex items-center gap-4">
          <p class="text-sm text-slate-600">
            Showing {{ filteredPrintRequests.length }} of {{ allPrintRequests.length }} print requests
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
              severity="info" 
              class="text-xs"
            />
            <Tag 
              v-if="selectedBatchSizeFilter" 
              :value="`Size: ${getBatchSizeFilterLabel(selectedBatchSizeFilter)}`" 
              severity="warning" 
              class="text-xs"
            />
          </div>
        </div>
        <Button 
          v-if="hasActiveFilters"
          label="Clear All Filters" 
          icon="pi pi-times"
          severity="secondary"
          text
          @click="clearAllFilters"
          size="small"
        />
      </div>
    </div>

    <!-- Statistics Cards with filtered counts -->
    <div class="grid grid-cols-1 md:grid-cols-5 gap-6">
      <div class="bg-white rounded-xl shadow-soft border border-slate-200 p-6 hover:shadow-medium transition-shadow duration-200">
        <div class="flex items-center justify-between">
          <div>
            <h3 class="text-sm font-medium text-slate-600 mb-2">Submitted</h3>
            <p class="text-3xl font-bold text-blue-600">{{ getFilteredStatusCount('SUBMITTED') }}</p>
            <p class="text-xs text-slate-500 mt-1">{{ getStatusCount('SUBMITTED') }} total</p>
          </div>
          <div class="p-3 bg-gradient-to-r from-blue-500 to-indigo-500 rounded-lg">
            <i class="pi pi-inbox text-white text-xl"></i>
          </div>
        </div>
      </div>

      <div class="bg-white rounded-xl shadow-soft border border-slate-200 p-6 hover:shadow-medium transition-shadow duration-200">
        <div class="flex items-center justify-between">
          <div>
            <h3 class="text-sm font-medium text-slate-600 mb-2">Processing</h3>
            <p class="text-3xl font-bold text-purple-600">{{ getFilteredStatusCount('PROCESSING') }}</p>
            <p class="text-xs text-slate-500 mt-1">{{ getStatusCount('PROCESSING') }} total</p>
          </div>
          <div class="p-3 bg-gradient-to-r from-purple-500 to-violet-500 rounded-lg">
            <i class="pi pi-cog text-white text-xl"></i>
          </div>
        </div>
      </div>

      <div class="bg-white rounded-xl shadow-soft border border-slate-200 p-6 hover:shadow-medium transition-shadow duration-200">
        <div class="flex items-center justify-between">
          <div>
            <h3 class="text-sm font-medium text-slate-600 mb-2">Shipping</h3>
            <p class="text-3xl font-bold text-indigo-600">{{ getFilteredStatusCount('SHIPPING') }}</p>
            <p class="text-xs text-slate-500 mt-1">{{ getStatusCount('SHIPPING') }} total</p>
          </div>
          <div class="p-3 bg-gradient-to-r from-indigo-500 to-blue-500 rounded-lg">
            <i class="pi pi-send text-white text-xl"></i>
          </div>
        </div>
      </div>

      <div class="bg-white rounded-xl shadow-soft border border-slate-200 p-6 hover:shadow-medium transition-shadow duration-200">
        <div class="flex items-center justify-between">
          <div>
            <h3 class="text-sm font-medium text-slate-600 mb-2">Completed</h3>
            <p class="text-3xl font-bold text-blue-600">{{ getFilteredStatusCount('COMPLETED') }}</p>
            <p class="text-xs text-slate-500 mt-1">{{ getStatusCount('COMPLETED') }} total</p>
          </div>
          <div class="p-3 bg-gradient-to-r from-blue-500 to-blue-600 rounded-lg">
            <i class="pi pi-check-circle text-white text-xl"></i>
          </div>
        </div>
      </div>

      <div class="bg-white rounded-xl shadow-soft border border-slate-200 p-6 hover:shadow-medium transition-shadow duration-200">
        <div class="flex items-center justify-between">
          <div>
            <h3 class="text-sm font-medium text-slate-600 mb-2">Cancelled</h3>
            <p class="text-3xl font-bold text-red-600">{{ getFilteredStatusCount('CANCELLED') }}</p>
            <p class="text-xs text-slate-500 mt-1">{{ getStatusCount('CANCELLED') }} total</p>
          </div>
          <div class="p-3 bg-gradient-to-r from-red-500 to-rose-500 rounded-lg">
            <i class="pi pi-times-circle text-white text-xl"></i>
          </div>
        </div>
      </div>
    </div>

    <!-- Print Requests Table -->
    <div class="bg-white rounded-xl shadow-soft border border-slate-200 overflow-hidden">
      <div class="p-6 border-b border-slate-200 bg-gradient-to-r from-slate-50 to-slate-100">
        <div class="flex items-center justify-between">
          <h3 class="text-lg font-semibold text-slate-900">All Print Requests</h3>
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
          :value="displayedPrintRequests" 
          :loading="printRequestsStore.isLoadingPrintRequests"
          :paginator="true" 
          :rows="20"
          :rowsPerPageOptions="[10, 20, 50]"
          responsiveLayout="scroll"
          class="border-0"
          dataKey="id"
          :globalFilterFields="['user_email', 'user_public_name', 'card_name', 'batch_name']"
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
                Print Requests ({{ displayedPrintRequests.length }})
              </span>
              <IconField>
                <InputIcon>
                  <i class="pi pi-search" />
                </InputIcon>
                <InputText 
                  v-model="filters['global'].value" 
                  placeholder="Search requests..." 
                />
              </IconField>
            </div>
          </template>

          <Column field="user_email" header="User" sortable style="min-width:200px">
            <template #body="{ data }">
              <div>
                <div class="font-medium text-slate-900">{{ data.user_public_name || 'Unnamed User' }}</div>
                <div class="text-sm text-slate-600">{{ data.user_email }}</div>
              </div>
            </template>
          </Column>

          <Column field="card_name" header="Card Design" sortable>
            <template #body="{ data }">
              <span class="text-sm font-medium text-slate-900">{{ data.card_name }}</span>
            </template>
          </Column>

          <Column field="batch_name" header="Batch" sortable>
            <template #body="{ data }">
              <div>
                <div class="text-sm font-medium text-slate-900">{{ data.batch_name }}</div>
                <div class="text-xs text-slate-500">{{ data.cards_count }} cards</div>
              </div>
            </template>
          </Column>

          <Column field="status" header="Status" sortable>
            <template #body="{ data }">
              <Tag 
                :value="data.status" 
                :severity="getPrintRequestSeverity(data.status)"
                class="px-3 py-1"
              />
            </template>
          </Column>

          <Column header="Contact Info" style="min-width:180px">
            <template #body="{ data }">
              <div class="space-y-1">
                <div v-if="data.contact_email" class="flex items-center gap-1 text-xs">
                  <i class="pi pi-envelope text-slate-500"></i>
                  <a :href="`mailto:${data.contact_email}`" 
                     class="text-blue-600 hover:text-blue-800 truncate max-w-[120px]" 
                     :title="data.contact_email">
                    {{ data.contact_email }}
                  </a>
                </div>
                <div v-if="data.contact_whatsapp" class="flex items-center gap-1 text-xs">
                  <i class="pi pi-whatsapp text-green-500"></i>
                  <a :href="`https://wa.me/${data.contact_whatsapp.replace('+', '')}`" 
                     target="_blank"
                     class="text-green-600 hover:text-green-800"
                     :title="data.contact_whatsapp">
                    {{ data.contact_whatsapp }}
                  </a>
                </div>
                <span v-if="!data.contact_email && !data.contact_whatsapp" class="text-xs text-slate-400">
                  No contact info
                </span>
              </div>
            </template>
          </Column>

          <Column field="requested_at" header="Requested" sortable>
            <template #body="{ data }">
              <span class="text-sm text-slate-600">{{ formatDate(data.requested_at) }}</span>
            </template>
          </Column>

          <Column field="updated_at" header="Last Updated" sortable>
            <template #body="{ data }">
              <span class="text-sm text-slate-600">{{ formatDate(data.updated_at) }}</span>
            </template>
          </Column>

          <Column header="Actions" :exportable="false" style="min-width:160px">
            <template #body="{ data }">
              <div class="flex gap-2">
                <Button 
                  icon="pi pi-eye" 
                  severity="secondary" 
                  outlined
                  size="small"
                  @click="openPrintRequestDetails(data)" 
                  v-tooltip.top="'View Details'"
                />
                <Button 
                  icon="pi pi-cog" 
                  severity="primary" 
                  outlined
                  size="small"
                  @click="openPrintRequestManagement(data)" 
                  v-tooltip.top="'Manage Status'"
                />
                <Button 
                  v-if="['SUBMITTED'].includes(data.status)"
                  icon="pi pi-arrow-right" 
                  severity="primary" 
                  outlined
                  size="small"
                  @click="quickAdvanceStatus(data)" 
                  v-tooltip.top="'Advance to Processing'"
                />
              </div>
            </template>
          </Column>
        </DataTable>
      </div>
    </div>

    <!-- Print Request Details Dialog -->
    <Dialog
      v-model:visible="showDetailsDialog"
      header="Print Request Details"
      style="width: 90vw; max-width: 800px;"
      :modal="true"
      :closable="true"
    >
      <div v-if="selectedPrintRequest" class="space-y-6">
        <!-- Request Information -->
        <div class="bg-slate-50 rounded-lg p-6 border border-slate-200">
          <h4 class="text-lg font-semibold text-slate-900 mb-4 flex items-center gap-2">
            <i class="pi pi-info-circle text-blue-600"></i>
            Request Information
          </h4>
          <div class="mb-4 p-3 bg-blue-50 border border-blue-200 rounded-lg">
            <div class="flex items-center gap-2 text-blue-800">
              <i class="pi pi-check-circle"></i>
              <span class="text-sm font-medium">Batch Payment Completed</span>
            </div>
            <p class="text-xs text-blue-700 mt-1">This print request is for a paid batch. Cards have been generated and are ready for printing.</p>
          </div>
          <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div class="space-y-3">
              <div>
                <label class="text-sm font-medium text-slate-700">Request ID</label>
                <p class="text-sm text-slate-900 mt-1 font-mono">{{ selectedPrintRequest.id }}</p>
              </div>
              <div>
                <label class="text-sm font-medium text-slate-700">Card Design</label>
                <p class="text-sm text-slate-900 mt-1">{{ selectedPrintRequest.card_name }}</p>
              </div>
              <div>
                <label class="text-sm font-medium text-slate-700">Batch</label>
                <p class="text-sm text-slate-900 mt-1">{{ selectedPrintRequest.batch_name }} (#{{ selectedPrintRequest.batch_number }})</p>
              </div>
              <div>
                <label class="text-sm font-medium text-slate-700">Cards Count</label>
                <p class="text-sm text-slate-900 mt-1">{{ selectedPrintRequest.cards_count }} cards</p>
              </div>
            </div>
            <div class="space-y-3">
              <div>
                <label class="text-sm font-medium text-slate-700">User</label>
                <p class="text-sm text-slate-900 mt-1">{{ selectedPrintRequest.user_public_name || selectedPrintRequest.user_email }}</p>
              </div>
              <div>
                <label class="text-sm font-medium text-slate-700">Current Status</label>
                <div class="mt-1">
                  <Tag 
                    :value="selectedPrintRequest.status" 
                    :severity="getPrintRequestSeverity(selectedPrintRequest.status)"
                    class="px-3 py-1"
                  />
                </div>
              </div>
              <div>
                <label class="text-sm font-medium text-slate-700">Requested Date</label>
                <p class="text-sm text-slate-900 mt-1">{{ formatDate(selectedPrintRequest.requested_at) }}</p>
              </div>
              <div>
                <label class="text-sm font-medium text-slate-700">Last Updated</label>
                <p class="text-sm text-slate-900 mt-1">{{ formatDate(selectedPrintRequest.updated_at) }}</p>
              </div>
            </div>
          </div>
        </div>

        <!-- Contact Information -->
        <div v-if="selectedPrintRequest.contact_email || selectedPrintRequest.contact_whatsapp" class="bg-purple-50 rounded-lg p-6 border border-purple-200">
          <h4 class="text-lg font-semibold text-slate-900 mb-4 flex items-center gap-2">
            <i class="pi pi-phone text-purple-600"></i>
            Contact Information
          </h4>
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div v-if="selectedPrintRequest.contact_email">
              <label class="text-sm font-medium text-slate-700">Email Address</label>
              <div class="bg-white rounded border border-purple-200 p-3 mt-1">
                <a :href="`mailto:${selectedPrintRequest.contact_email}`" 
                   class="text-purple-700 hover:text-purple-900 underline break-all">
                  {{ selectedPrintRequest.contact_email }}
                </a>
              </div>
            </div>
            <div v-if="selectedPrintRequest.contact_whatsapp">
              <label class="text-sm font-medium text-slate-700">WhatsApp Number</label>
              <div class="bg-white rounded border border-purple-200 p-3 mt-1">
                <a :href="`https://wa.me/${selectedPrintRequest.contact_whatsapp.replace('+', '')}`" 
                   target="_blank"
                   class="text-purple-700 hover:text-purple-900 underline">
                  {{ selectedPrintRequest.contact_whatsapp }}
                </a>
              </div>
            </div>
          </div>
        </div>

        <!-- Shipping Address -->
        <div class="bg-blue-50 rounded-lg p-6 border border-blue-200">
          <h4 class="text-lg font-semibold text-slate-900 mb-4 flex items-center gap-2">
            <i class="pi pi-map-marker text-blue-600"></i>
            Shipping Address
          </h4>
          <div class="bg-white rounded border border-blue-200 p-4">
            <pre class="text-sm text-slate-900 whitespace-pre-wrap font-sans">{{ selectedPrintRequest.shipping_address }}</pre>
          </div>
        </div>

        <!-- Admin Notes -->
        <div v-if="selectedPrintRequest.admin_notes" class="bg-amber-50 rounded-lg p-6 border border-amber-200">
          <h4 class="text-lg font-semibold text-slate-900 mb-4 flex items-center gap-2">
            <i class="pi pi-comment text-amber-600"></i>
            Admin Notes
            <Tag v-if="selectedPrintRequest.status === 'CANCELLED' && selectedPrintRequest.admin_notes?.includes('Withdrawn by card issuer')" 
                 value="USER WITHDRAWN" 
                 severity="danger" 
                 class="ml-2" />
          </h4>
          <div class="bg-white rounded border border-amber-200 p-4">
            <pre class="text-sm text-slate-900 whitespace-pre-wrap font-sans">{{ selectedPrintRequest.admin_notes }}</pre>
          </div>
        </div>
      </div>
    </Dialog>

    <!-- Print Request Management Dialog -->
    <MyDialog
      v-model="showManagementDialog"
      header="Manage Print Request"
      :confirmHandle="handlePrintRequestUpdate"
      confirmLabel="Update Status"
      confirmSeverity="primary"
      successMessage="Print request updated successfully"
      errorMessage="Failed to update print request"
      @hide="closeManagementDialog"
      style="width: 90vw; max-width: 700px;"
    >
      <div v-if="selectedPrintRequest" class="space-y-6">
        <!-- Current Status -->
        <div class="bg-slate-50 rounded-lg p-4 border border-slate-200">
          <div class="flex items-center justify-between">
            <div>
              <h4 class="font-medium text-slate-900">{{ selectedPrintRequest.card_name }}</h4>
              <p class="text-sm text-slate-600">{{ selectedPrintRequest.user_email }} • {{ selectedPrintRequest.cards_count }} cards</p>
            </div>
            <Tag 
              :value="selectedPrintRequest.status" 
              :severity="getPrintRequestSeverity(selectedPrintRequest.status)"
              class="px-3 py-1"
            />
          </div>
        </div>

        <!-- Status Update -->
        <div>
          <label class="block text-sm font-medium text-slate-700 mb-2">New Status</label>
          <Select 
            v-model="newPrintStatus" 
            :options="printStatusOptions"
            optionLabel="label"
            optionValue="value"
            class="w-full"
          />
        </div>

        <!-- Admin Notes -->
        <div>
          <label class="block text-sm font-medium text-slate-700 mb-2">Admin Notes</label>
          <Textarea 
            v-model="printAdminNotes" 
            rows="4"
            class="w-full"
            placeholder="Add notes about this status update. This will be included in the notification to the user."
          />
        </div>

        <!-- Tracking Information -->
        <div v-if="newPrintStatus === 'SHIPPING'">
          <label class="block text-sm font-medium text-slate-700 mb-2">Tracking Information</label>
          <InputText 
            v-model="trackingNumber" 
            class="w-full"
            placeholder="Enter tracking number or shipping reference"
          />
        </div>
      </div>
    </MyDialog>

      <!-- Quick Status Advance Confirmation -->
      <ConfirmDialog group="quickAdvance"></ConfirmDialog>
    </div>
  </PageWrapper>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useAdminPrintRequestsStore } from '@/stores/admin'
import { useConfirm } from 'primevue/useconfirm'
import { useToast } from 'primevue/usetoast'
import { FilterMatchMode } from '@primevue/core/api'
import Button from 'primevue/button'
import DataTable from 'primevue/datatable'
import Column from 'primevue/column'
import Tag from 'primevue/tag'
import InputText from 'primevue/inputtext'
import Textarea from 'primevue/textarea'
import Select from 'primevue/select'
import IconField from 'primevue/iconfield'
import InputIcon from 'primevue/inputicon'
import Dialog from 'primevue/dialog'
import ConfirmDialog from 'primevue/confirmdialog'
import MyDialog from '@/components/MyDialog.vue'
import Calendar from 'primevue/calendar'
import EmptyState from '@/components/EmptyState.vue'
import { getEmptyStateConfig, determineEmptyScenario } from '@/utils/emptyStateConfigs.js'
import PageWrapper from '@/components/Layout/PageWrapper.vue'

const printRequestsStore = useAdminPrintRequestsStore()
const confirm = useConfirm()
const toast = useToast()

// Reactive data
const showDetailsDialog = ref(false)
const showManagementDialog = ref(false)
const selectedPrintRequest = ref(null)
const selectedStatus = ref(null)
const newPrintStatus = ref('')
const printAdminNotes = ref('')
const trackingNumber = ref('')

// Enhanced filtering data
const searchQuery = ref('')
const dateRange = ref(null)
const selectedBatchSizeFilter = ref(null)
const selectedSortBy = ref(null)
const allPrintRequests = ref([])
const filteredPrintRequests = ref([])

// Debounced search
let searchTimeout = null
const debouncedSearch = () => {
  clearTimeout(searchTimeout)
  searchTimeout = setTimeout(() => {
    filterPrintRequests()
  }, 300)
}

const filters = ref({
  global: { value: null, matchMode: FilterMatchMode.CONTAINS }
})

// Computed
const statusOptions = [
  { label: 'All Statuses', value: null },
  { label: 'Submitted', value: 'SUBMITTED' },
  { label: 'Processing', value: 'PROCESSING' },
  { label: 'Shipping', value: 'SHIPPING' },
  { label: 'Completed', value: 'COMPLETED' },
  { label: 'Cancelled', value: 'CANCELLED' }
]

const batchSizeFilterOptions = [
  { label: 'All Sizes', value: null },
  { label: 'Small (1-25)', value: 'small' },
  { label: 'Medium (26-100)', value: 'medium' },
  { label: 'Large (101-500)', value: 'large' },
  { label: 'XL (500+)', value: 'xl' }
]

const sortOptions = [
  { label: 'Newest First', value: 'newest' },
  { label: 'Oldest First', value: 'oldest' },
  { label: 'Card Name A-Z', value: 'card_name_asc' },
  { label: 'User Name A-Z', value: 'user_name_asc' },
  { label: 'Batch Size (Large)', value: 'batch_size_desc' },
  { label: 'Batch Size (Small)', value: 'batch_size_asc' },
  { label: 'Status', value: 'status' }
]

const printStatusOptions = [
  { label: 'Submitted', value: 'SUBMITTED' },
  { label: 'Processing', value: 'PROCESSING' },
  { label: 'Shipping', value: 'SHIPPING' },
  { label: 'Completed', value: 'COMPLETED' },
  { label: 'Cancelled', value: 'CANCELLED' }
]

const hasActiveFilters = computed(() => {
  return !!(
    searchQuery.value || 
    selectedStatus.value || 
    (dateRange.value && dateRange.value.length === 2) ||
    selectedBatchSizeFilter.value ||
    selectedSortBy.value
  )
})

const displayedPrintRequests = computed(() => {
  return filteredPrintRequests.value
})

// Empty state configuration
const currentEmptyStateConfig = computed(() => {
  const scenario = determineEmptyScenario(
    displayedPrintRequests.value,
    printRequestsStore.isLoadingPrintRequests,
    false, // hasError - could be extended with error handling
    hasActiveFilters.value
  )
  
  if (!scenario) return null
  
  return getEmptyStateConfig('printRequests', scenario)
})

// Methods
const refreshData = async () => {
  await printRequestsStore.fetchAllPrintRequests()
  allPrintRequests.value = printRequestsStore.printRequests
  filterPrintRequests()
}

const handleEmptyStateAction = () => {
  if (hasActiveFilters.value) {
    clearAllFilters()
  }
}

const onStatusFilterChange = async () => {
  filterPrintRequests()
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

const getPrintRequestSeverity = (status) => {
  switch (status) {
    case 'SUBMITTED': return 'info'
    case 'PROCESSING': return 'primary'
    case 'SHIPPING': return 'contrast'
    case 'COMPLETED': return 'success'
    case 'CANCELLED': return 'danger'
    default: return 'secondary'
  }
}

const getStatusCount = (status) => {
  return allPrintRequests.value.filter(pr => pr.status === status).length
}

const openPrintRequestDetails = (request) => {
  selectedPrintRequest.value = request
  showDetailsDialog.value = true
}

const openPrintRequestManagement = (request) => {
  selectedPrintRequest.value = request
  newPrintStatus.value = request.status
  printAdminNotes.value = request.admin_notes || ''
  trackingNumber.value = ''
  showManagementDialog.value = true
}

const closeManagementDialog = () => {
  selectedPrintRequest.value = null
  newPrintStatus.value = ''
  printAdminNotes.value = ''
  trackingNumber.value = ''
  showManagementDialog.value = false
}

const handlePrintRequestUpdate = async () => {
  if (!selectedPrintRequest.value || !newPrintStatus.value) {
    throw new Error('Status is required')
  }

  let notes = printAdminNotes.value.trim()
  
  // Add tracking information to notes if provided
  if (newPrintStatus.value === 'SHIPPING' && trackingNumber.value.trim()) {
    const trackingNote = `\n\nTracking: ${trackingNumber.value.trim()}`
    notes = notes ? notes + trackingNote : trackingNote.trim()
  }

  await printRequestsStore.updatePrintRequestStatus(
    selectedPrintRequest.value.id,
    newPrintStatus.value,
    notes || undefined
  )
  
  await refreshData()
  showManagementDialog.value = false
}

const quickAdvanceStatus = (request) => {
  const nextStatus = getNextStatus(request.status)
  if (!nextStatus) return
  
  confirm.require({
    group: 'quickAdvance',
    message: `Advance "${request.card_name}" from ${request.status} to ${nextStatus}?`,
    header: 'Quick Status Advance',
    icon: 'pi pi-arrow-right',
    acceptLabel: 'Advance',
    rejectLabel: 'Cancel',
    acceptClass: 'p-button-success p-button-sm',
    rejectClass: 'p-button-outlined p-button-sm',
    accept: async () => {
      try {
        await printRequestsStore.updatePrintRequestStatus(
          request.id,
          nextStatus,
          `Status advanced to ${nextStatus} by admin`,
          undefined
        )
        
        toast.add({ 
          severity: 'success', 
          summary: 'Status Updated', 
          detail: `Print request advanced to ${nextStatus}`, 
          life: 3000 
        })
        
        await refreshData()
      } catch (error) {
        toast.add({ 
          severity: 'error', 
          summary: 'Error', 
          detail: 'Failed to update status', 
          life: 3000 
        })
      }
    }
  })
}

const getNextStatus = (currentStatus) => {
  const statusFlow = {
    'SUBMITTED': 'PROCESSING'
  }
  return statusFlow[currentStatus] || null
}

const exportToCsv = () => {
  const headers = [
    'Request ID', 'User Email', 'User Name', 'Card Name', 'Batch Name', 
    'Cards Count', 'Status', 'Contact Email', 'Contact WhatsApp', 
    'Requested Date', 'Last Updated', 'Admin Notes'
  ]
  
  const csvContent = [
    headers.join(','),
    ...printRequestsStore.printRequests.map(request => [
      request.id,
      request.user_email,
      request.user_public_name || '',
      request.card_name,
      request.batch_name,
      request.cards_count,
      request.status,
      request.contact_email || '',
      request.contact_whatsapp || '',
      formatDate(request.requested_at),
      formatDate(request.updated_at),
      (request.admin_notes || '').replace(/,/g, ';')
    ].join(','))
  ].join('\n')
  
  const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' })
  const link = document.createElement('a')
  const url = URL.createObjectURL(blob)
  link.setAttribute('href', url)
  link.setAttribute('download', `print-requests-${new Date().toISOString().split('T')[0]}.csv`)
  link.style.visibility = 'hidden'
  document.body.appendChild(link)
  link.click()
  document.body.removeChild(link)
  URL.revokeObjectURL(url)
  
  toast.add({ 
    severity: 'success', 
    summary: 'Export Complete', 
    detail: 'Print requests exported to CSV', 
    life: 3000 
  })
}

// Enhanced filtering methods
const filterPrintRequests = () => {
  let filtered = [...allPrintRequests.value]
  
  // Text search
  if (searchQuery.value) {
    const query = searchQuery.value.toLowerCase()
    filtered = filtered.filter(pr => 
      (pr.user_email && pr.user_email.toLowerCase().includes(query)) ||
      (pr.user_public_name && pr.user_public_name.toLowerCase().includes(query)) ||
      (pr.card_name && pr.card_name.toLowerCase().includes(query)) ||
      (pr.batch_name && pr.batch_name.toLowerCase().includes(query)) ||
      (pr.admin_notes && pr.admin_notes.toLowerCase().includes(query))
    )
  }
  
  // Status filter
  if (selectedStatus.value) {
    filtered = filtered.filter(pr => pr.status === selectedStatus.value)
  }
  
  // Date range filter
  if (dateRange.value && dateRange.value.length === 2) {
    const [startDate, endDate] = dateRange.value
    filtered = filtered.filter(pr => {
      const requestDate = new Date(pr.requested_at)
      return requestDate >= startDate && requestDate <= endDate
    })
  }
  
  // Batch size filter
  if (selectedBatchSizeFilter.value) {
    filtered = filtered.filter(pr => {
      const cardCount = pr.cards_count || 0
      switch (selectedBatchSizeFilter.value) {
        case 'small': return cardCount >= 1 && cardCount <= 25
        case 'medium': return cardCount >= 26 && cardCount <= 100
        case 'large': return cardCount >= 101 && cardCount <= 500
        case 'xl': return cardCount > 500
        default: return true
      }
    })
  }
  
  // Sort results
  if (selectedSortBy.value) {
    filtered = sortPrintRequestData(filtered, selectedSortBy.value)
  }
  
  filteredPrintRequests.value = filtered
}

const sortPrintRequestData = (data, sortBy) => {
  return [...data].sort((a, b) => {
    switch (sortBy) {
      case 'newest':
        return new Date(b.requested_at) - new Date(a.requested_at)
      case 'oldest':
        return new Date(a.requested_at) - new Date(b.requested_at)
      case 'card_name_asc':
        return (a.card_name || '').localeCompare(b.card_name || '')
      case 'user_name_asc':
        return (a.user_public_name || '').localeCompare(b.user_public_name || '')
      case 'batch_size_desc':
        return (b.cards_count || 0) - (a.cards_count || 0)
      case 'batch_size_asc':
        return (a.cards_count || 0) - (b.cards_count || 0)
      case 'status':
        return a.status.localeCompare(b.status)
      default:
        return 0
    }
  })
}

const sortPrintRequests = () => {
  filterPrintRequests()
}

const filterByDateRange = () => {
  filterPrintRequests()
}

const clearAllFilters = () => {
  searchQuery.value = ''
  selectedStatus.value = null
  dateRange.value = null
  selectedBatchSizeFilter.value = null
  selectedSortBy.value = null
  filterPrintRequests()
}

const getFilteredStatusCount = (status) => {
  return filteredPrintRequests.value.filter(pr => pr.status === status).length
}

const getBatchSizeFilterLabel = (value) => {
  const option = batchSizeFilterOptions.find(o => o.value === value)
  return option ? option.label : value
}

// Initialize
onMounted(async () => {
  await refreshData()
})
</script>

<style scoped>
/* Component-specific styles - global table theme now handles standard styling */

/* Pre-formatted text styling */
pre {
  font-family: inherit;
  margin: 0;
}
</style> 