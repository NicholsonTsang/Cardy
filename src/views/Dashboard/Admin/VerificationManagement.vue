<template>
  <PageWrapper title="Verification Management" description="Review and manage user verification submissions">
    <template #actions>
      <Button 
        icon="pi pi-refresh" 
        label="Refresh" 
        severity="secondary"
        outlined
        @click="refreshData"
        :loading="verificationsStore.isLoadingVerifications"
      />
    </template>
    
    <div class="space-y-6">

    <!-- Filters -->
    <div class="bg-white rounded-xl shadow-soft border border-slate-200 p-6">
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
              @input="applyFilters"
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
            @change="applyFilters"
            showClear
          />
        </div>
        
        <!-- Date Range Filter -->
        <div>
          <Calendar 
            v-model="dateRange"
            selectionMode="range"
            dateFormat="mm/dd/yy"
            placeholder="Date Range"
            class="w-full"
            showIcon
            @date-select="applyFilters"
          />
        </div>
        
        <!-- Clear Filters -->
        <div class="flex items-center">
          <Button 
            v-if="hasActiveFilters"
            label="Clear Filters"
            icon="pi pi-times"
            severity="secondary"
            size="small"
            outlined
            @click="clearFilters"
          />
        </div>
      </div>
    </div>

    <!-- Verifications Table -->
    <div class="bg-white rounded-xl shadow-soft border border-slate-200 overflow-hidden">
      <DataTable 
        :value="verificationsStore.allVerifications" 
        :loading="verificationsStore.isLoadingVerifications"
        :paginator="true" 
        :rows="20"
        :rowsPerPageOptions="[10, 20, 50]"
        responsiveLayout="scroll"
        class="border-0"
        dataKey="user_id"
      >
        <template #empty>
          <div class="text-center py-8">
            <i class="pi pi-inbox text-4xl text-slate-400 mb-4"></i>
            <p class="text-lg font-medium text-slate-900 mb-2">No Verifications Found</p>
            <p class="text-slate-600">No verifications match your current filters.</p>
          </div>
        </template>
        
        <template #header>
          <div class="flex justify-between items-center">
            <span class="text-lg font-semibold text-slate-900">
              Verification Submissions ({{ verificationsStore.allVerifications.length }})
            </span>
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
                severity="secondary" 
                size="small"
                outlined
                @click="viewDetails(data)"
                title="View Details"
              />
              <Button 
                icon="pi pi-check" 
                severity="success" 
                size="small"
                outlined
                @click="openReviewDialog(data)"
                v-if="data.verification_status === 'PENDING_REVIEW'"
                title="Review"
              />
            </div>
          </template>
        </Column>
      </DataTable>
    </div>

    <!-- Review Dialog -->
    <MyDialog 
      v-model="showReviewDialog" 
      header="Review Verification"
      :confirmHandle="handleReview"
      :confirmLabel="reviewAction === 'APPROVED' ? 'Approve' : 'Reject'"
      :confirmSeverity="reviewAction === 'APPROVED' ? 'success' : 'danger'"
      successMessage="Verification reviewed successfully"
      errorMessage="Failed to review verification"
      style="width: 90vw; max-width: 600px;"
    >
      <div class="space-y-6" v-if="selectedVerification">
        <!-- User Information -->
        <div class="bg-slate-50 rounded-lg p-4">
          <h4 class="font-semibold text-slate-900 mb-3">User Information</h4>
          <div class="space-y-2 text-sm">
            <div class="flex justify-between">
              <span class="text-slate-600">Email:</span>
              <span class="font-medium text-slate-900">{{ selectedVerification.user_email }}</span>
            </div>
            <div class="flex justify-between">
              <span class="text-slate-600">Public Name:</span>
              <span class="font-medium text-slate-900">{{ selectedVerification.public_name || '-' }}</span>
            </div>
            <div class="flex justify-between">
              <span class="text-slate-600">Full Legal Name:</span>
              <span class="font-medium text-slate-900">{{ selectedVerification.full_name }}</span>
            </div>
            <div class="flex justify-between">
              <span class="text-slate-600">Company:</span>
              <span class="font-medium text-slate-900">{{ selectedVerification.company_name || '-' }}</span>
            </div>
            <div class="flex justify-between">
              <span class="text-slate-600">Submitted:</span>
              <span class="font-medium text-slate-900">{{ formatDate(selectedVerification.updated_at) }}</span>
            </div>
          </div>
        </div>

        <!-- Documents -->
        <div>
          <h4 class="font-semibold text-slate-900 mb-3">Supporting Documents</h4>
          <div v-if="selectedVerification.supporting_documents?.length > 0" class="space-y-2">
            <div 
              v-for="(doc, index) in selectedVerification.supporting_documents" 
              :key="index"
              class="flex items-center gap-2 p-3 bg-slate-50 rounded-lg"
            >
              <i class="pi pi-file text-slate-500"></i>
              <a 
                :href="doc" 
                target="_blank" 
                class="text-sm text-blue-600 hover:text-blue-800 underline flex-1 truncate"
              >
                Document {{ index + 1 }}
              </a>
            </div>
          </div>
          <div v-else class="text-sm text-slate-500">
            No documents provided
          </div>
        </div>

        <!-- Review Action -->
        <div>
          <h4 class="font-semibold text-slate-900 mb-3">Review Decision</h4>
          <div class="flex gap-3 mb-4">
            <Button 
              :label="'Approve'"
              icon="pi pi-check"
              :severity="reviewAction === 'APPROVED' ? 'success' : 'secondary'"
              :outlined="reviewAction !== 'APPROVED'"
              @click="reviewAction = 'APPROVED'"
            />
            <Button 
              :label="'Reject'"
              icon="pi pi-times"
              :severity="reviewAction === 'REJECTED' ? 'danger' : 'secondary'"
              :outlined="reviewAction !== 'REJECTED'"
              @click="reviewAction = 'REJECTED'"
            />
          </div>
          
          <div>
            <label class="block text-sm font-medium text-slate-700 mb-2">
              Review Feedback (Optional)
            </label>
            <Textarea 
              v-model="reviewFeedback"
              rows="4"
              placeholder="Provide feedback for the user..."
              class="w-full"
            />
          </div>
        </div>
      </div>
    </MyDialog>

    </div>
  </PageWrapper>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useToast } from 'primevue/usetoast'
import { useAdminDashboardStore, useAdminVerificationsStore } from '@/stores/admin'

// PrimeVue Components
import Button from 'primevue/button'
import Tag from 'primevue/tag'
import Select from 'primevue/select'
import InputText from 'primevue/inputtext'
import DataTable from 'primevue/datatable'
import Column from 'primevue/column'
import IconField from 'primevue/iconfield'
import InputIcon from 'primevue/inputicon'
import MyDialog from '@/components/MyDialog.vue'
import Calendar from 'primevue/calendar'
import Textarea from 'primevue/textarea'
import PageWrapper from '@/components/Layout/PageWrapper.vue'

const router = useRouter()
const toast = useToast()
const dashboardStore = useAdminDashboardStore()
const verificationsStore = useAdminVerificationsStore()

// State
const selectedStatus = ref(null)
const searchQuery = ref('')
const dateRange = ref(null)
const showReviewDialog = ref(false)
const selectedVerification = ref(null)
const reviewAction = ref('APPROVED')
const reviewFeedback = ref('')

// Filter options
const statusOptions = [
  { label: 'All Statuses', value: null },
  { label: 'Pending Review', value: 'PENDING_REVIEW' },
  { label: 'Approved', value: 'APPROVED' },
  { label: 'Rejected', value: 'REJECTED' }
]

// Computed
const hasActiveFilters = computed(() => {
  return !!(searchQuery.value || selectedStatus.value || dateRange.value)
})

// Methods
const applyFilters = async () => {
  try {
    await verificationsStore.fetchAllVerifications(
      selectedStatus.value,
      searchQuery.value.trim() || undefined,
      dateRange.value?.[0] || undefined,
      dateRange.value?.[1] || undefined
    )
  } catch (error) {
    toast.add({
      severity: 'error',
      summary: 'Error',
      detail: 'Failed to fetch verifications',
      life: 3000
    })
  }
}

const clearFilters = async () => {
  searchQuery.value = ''
  selectedStatus.value = null
  dateRange.value = null
  await applyFilters()
}

const refreshData = async () => {
  await applyFilters()
  await dashboardStore.fetchDashboardStats()
}

const viewDetails = (verification) => {
  router.push(`/dashboard/admin/verifications/${verification.user_id}`)
}

const openReviewDialog = (verification) => {
  selectedVerification.value = verification
  reviewAction.value = 'APPROVED'
  reviewFeedback.value = ''
  showReviewDialog.value = true
}

const handleReview = async () => {
  await verificationsStore.reviewVerification(
    selectedVerification.value.user_id,
    reviewAction.value,
    reviewFeedback.value || null
  )
  await refreshData()
  showReviewDialog.value = false
  selectedVerification.value = null
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
    case 'APPROVED': return 'success'
    case 'REJECTED': return 'danger'
    case 'PENDING_REVIEW': return 'warning'
    default: return 'secondary'
  }
}

// Lifecycle
onMounted(async () => {
  await refreshData()
})
</script>

<style scoped>
/* Component-specific styles */
:deep(.p-datatable .p-datatable-tbody > tr:hover) {
  background-color: #f8fafc;
}
</style>