<template>
  <PageWrapper :title="$t('admin.print_request_management')" :description="$t('admin.print_request_management_desc')">
    <template #actions>
      <Button 
        icon="pi pi-refresh" 
        :label="$t('common.refresh')" 
        severity="secondary"
        outlined
        @click="refreshData"
        :loading="printRequestsStore.isLoadingPrintRequests"
      />
    </template>

    <div class="space-y-6">

    <!-- Filters -->
    <div class="bg-white rounded-xl shadow-soft border border-slate-200 p-6">
      <h3 class="text-lg font-semibold text-slate-900 mb-4">{{ $t('admin.filters_search') }}</h3>
      <div class="grid grid-cols-1 md:grid-cols-5 gap-4">
        <!-- Search -->
        <div class="md:col-span-2">
          <IconField>
            <InputIcon class="pi pi-search" />
            <InputText 
              v-model="searchQuery"
              :placeholder="$t('admin.search_by_user_card_batch')"
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
            :placeholder="$t('admin.request_status')"
            class="w-full"
            @change="applyFilters"
            showClear
          />
        </div>
        
        <!-- Clear Filters -->
        <div class="flex items-center">
          <Button 
            v-if="hasActiveFilters"
            :label="$t('admin.clear_filters')"
            icon="pi pi-times"
            severity="secondary"
            size="small"
            outlined
            @click="clearFilters"
          />
        </div>
      </div>
    </div>

    <!-- Print Requests Table -->
    <div class="bg-white rounded-xl shadow-soft border border-slate-200 overflow-hidden">
      <DataTable 
        :value="printRequestsStore.printRequests" 
        :loading="printRequestsStore.isLoadingPrintRequests"
        :paginator="true" 
        :rows="20"
        :rowsPerPageOptions="[10, 20, 50]"
        responsiveLayout="scroll"
        showGridlines
        stripedRows
        class="border-0"
        dataKey="id"
      >
        <template #empty>
          <div class="text-center py-12">
            <i class="pi pi-inbox text-6xl text-slate-400 mb-4"></i>
            <p class="text-lg font-medium text-slate-900 mb-2">{{ $t('admin.no_requests_found') }}</p>
            <p class="text-slate-600">{{ $t('admin.no_requests_match_filters') }}</p>
          </div>
        </template>
        <template #loading>
          <div class="flex items-center justify-center py-12">
            <ProgressSpinner style="width: 50px; height: 50px" strokeWidth="4" />
          </div>
        </template>
        
        <template #header>
          <div class="flex justify-between items-center">
            <span class="text-lg font-semibold text-slate-900">
              {{ $t('admin.print_requests') }} ({{ printRequestsStore.printRequests.length }})
            </span>
          </div>
        </template>

        <Column field="user_email" :header="$t('admin.user')" sortable style="min-width:200px">
          <template #body="{ data }">
            <div>
              <div class="font-medium text-slate-900">{{ data.user_public_name || $t('admin.unnamed_user') }}</div>
              <div class="text-sm text-slate-600">{{ data.user_email }}</div>
            </div>
          </template>
        </Column>

        <Column field="card_name" :header="$t('admin.card')" sortable>
          <template #body="{ data }">
            <div>
              <div class="font-medium text-slate-900">{{ data.card_name }}</div>
              <div class="text-sm text-slate-600">{{ data.batch_name }}</div>
            </div>
          </template>
        </Column>

        <Column field="cards_count" :header="$t('batches.cards_count')" sortable>
          <template #body="{ data }">
            <div class="text-center">
              <span class="font-medium text-slate-900">{{ data.cards_count }}</span>
            </div>
          </template>
        </Column>

        <Column field="status" :header="$t('common.status')" sortable>
          <template #body="{ data }">
            <Tag 
              :value="data.status" 
              :severity="getPrintStatusSeverity(data.status)"
              class="px-3 py-1"
            />
          </template>
        </Column>

        <Column field="shipping_address" :header="$t('admin.shipping_address')" style="min-width:250px">
          <template #body="{ data }">
            <div class="text-sm text-slate-600 max-w-xs truncate" :title="data.shipping_address">
              {{ data.shipping_address }}
            </div>
          </template>
        </Column>

        <Column field="requested_at" :header="$t('admin.requested_at')" sortable>
          <template #body="{ data }">
            <span class="text-sm text-slate-600">{{ formatDate(data.requested_at) }}</span>
          </template>
        </Column>

        <Column :header="$t('common.actions')" :exportable="false" style="min-width:120px">
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
              <Select
                v-model="data.status"
                :options="statusUpdateOptions"
                optionLabel="label"
                optionValue="value"
                placeholder="Update Status"
                size="small"
                @change="updateStatus(data.id, $event.value)"
                :disabled="data.status === 'COMPLETED' || data.status === 'CANCELLED'"
              />
            </div>
          </template>
        </Column>
      </DataTable>
    </div>

    <!-- Details Dialog -->
    <Dialog
      v-model:visible="showDetailsDialog"
      :header="$t('admin.print_request_details')"
      :style="{ width: '90vw', maxWidth: '800px' }"
      :modal="true"
    >
      <div v-if="selectedRequest" class="space-y-6">
        <!-- User Information -->
        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div>
            <h4 class="font-semibold text-slate-900 mb-3">{{ $t('admin.user_information') }}</h4>
            <div class="space-y-2 text-sm">
              <div class="flex justify-between">
                <span class="text-slate-600">{{ $t('common.name') }}:</span>
                <span class="font-medium text-slate-900">{{ selectedRequest.user_public_name || '-' }}</span>
              </div>
              <div class="flex justify-between">
                <span class="text-slate-600">{{ $t('common.email') }}:</span>
                <span class="font-medium text-slate-900">{{ selectedRequest.user_email }}</span>
              </div>
              <div class="flex justify-between">
                <span class="text-slate-600">{{ $t('admin.contact_email') }}:</span>
                <span class="font-medium text-slate-900">{{ selectedRequest.contact_email || '-' }}</span>
              </div>
              <div class="flex justify-between">
                <span class="text-slate-600">{{ $t('admin.whatsapp') }}:</span>
                <span class="font-medium text-slate-900">{{ selectedRequest.contact_whatsapp || '-' }}</span>
              </div>
            </div>
          </div>
          
          <div>
            <h4 class="font-semibold text-slate-900 mb-3">{{ $t('admin.request_details') }}</h4>
            <div class="space-y-2 text-sm">
              <div class="flex justify-between">
                <span class="text-slate-600">{{ $t('admin.card') }}:</span>
                <span class="font-medium text-slate-900">{{ selectedRequest.card_name }}</span>
              </div>
              <div class="flex justify-between">
                <span class="text-slate-600">{{ $t('batches.batch') }}:</span>
                <span class="font-medium text-slate-900">{{ selectedRequest.batch_name }}</span>
              </div>
              <div class="flex justify-between">
                <span class="text-slate-600">{{ $t('batches.cards_count') }}:</span>
                <span class="font-medium text-slate-900">{{ selectedRequest.cards_count }}</span>
              </div>
              <div class="flex justify-between">
                <span class="text-slate-600">{{ $t('common.status') }}:</span>
                <Tag 
                  :value="selectedRequest.status" 
                  :severity="getPrintStatusSeverity(selectedRequest.status)"
                />
              </div>
              <div class="flex justify-between">
                <span class="text-slate-600">{{ $t('admin.requested_at') }}:</span>
                <span class="font-medium text-slate-900">{{ formatDate(selectedRequest.requested_at) }}</span>
              </div>
            </div>
          </div>
        </div>

        <!-- Shipping Address -->
        <div>
          <h4 class="font-semibold text-slate-900 mb-3">{{ $t('admin.shipping_address') }}</h4>
          <div class="bg-slate-50 rounded-lg p-4">
            <pre class="text-sm text-slate-800 whitespace-pre-wrap">{{ selectedRequest.shipping_address }}</pre>
          </div>
        </div>
      </div>

      <template #footer>
        <Button 
          :label="$t('common.close')" 
          severity="secondary" 
          @click="showDetailsDialog = false" 
        />
      </template>
    </Dialog>

    </div>
  </PageWrapper>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useI18n } from 'vue-i18n'
import { useToast } from 'primevue/usetoast'
import { useAdminPrintRequestsStore, useAdminDashboardStore } from '@/stores/admin'

const { t } = useI18n()

// PrimeVue Components
import Button from 'primevue/button'
import Tag from 'primevue/tag'
import Select from 'primevue/select'
import InputText from 'primevue/inputtext'
import DataTable from 'primevue/datatable'
import Column from 'primevue/column'
import IconField from 'primevue/iconfield'
import InputIcon from 'primevue/inputicon'
import Dialog from 'primevue/dialog'
import ProgressSpinner from 'primevue/progressspinner'
import PageWrapper from '@/components/Layout/PageWrapper.vue'

const toast = useToast()
const printRequestsStore = useAdminPrintRequestsStore()
const dashboardStore = useAdminDashboardStore()

// State
const selectedStatus = ref(null)
const searchQuery = ref('')
const showDetailsDialog = ref(false)
const selectedRequest = ref(null)

// Filter options
const statusOptions = computed(() => [
  { label: t('admin.all_statuses'), value: null },
  { label: t('print.submitted'), value: 'SUBMITTED' },
  { label: t('print.payment_pending'), value: 'PAYMENT_PENDING' },
  { label: t('print.in_production'), value: 'PROCESSING' },
  { label: t('print.shipped'), value: 'SHIPPED' },
  { label: t('print.delivered'), value: 'COMPLETED' },
  { label: t('print.cancelled'), value: 'CANCELLED' }
])

const statusUpdateOptions = computed(() => [
  { label: t('print.submitted'), value: 'SUBMITTED' },
  { label: t('print.payment_pending'), value: 'PAYMENT_PENDING' },
  { label: t('print.in_production'), value: 'PROCESSING' },
  { label: t('print.shipped'), value: 'SHIPPED' },
  { label: t('print.delivered'), value: 'COMPLETED' },
  { label: t('print.cancelled'), value: 'CANCELLED' }
])

// Computed
const hasActiveFilters = computed(() => {
  return !!(searchQuery.value || selectedStatus.value)
})

// Methods
const applyFilters = async () => {
  try {
    await printRequestsStore.fetchAllPrintRequests(
      selectedStatus.value,
      searchQuery.value.trim() || undefined
    )
  } catch (error) {
    toast.add({
      severity: 'error',
      summary: t('common.error'),
      detail: t('admin.failed_to_load_requests'),
      life: 3000
    })
  }
}

const clearFilters = async () => {
  searchQuery.value = ''
  selectedStatus.value = null
  await applyFilters()
}

const refreshData = async () => {
  await applyFilters()
  await dashboardStore.fetchDashboardStats()
}

const viewDetails = (request) => {
  selectedRequest.value = request
  showDetailsDialog.value = true
}

const updateStatus = async (requestId, newStatus) => {
  try {
    await printRequestsStore.updatePrintRequestStatus(requestId, newStatus)
    toast.add({
      severity: 'success',
      summary: t('common.success'),
      detail: t('admin.status_updated_successfully'),
      life: 3000
    })
    await refreshData()
  } catch (error) {
    toast.add({
      severity: 'error',
      summary: t('common.error'),
      detail: t('admin.failed_to_update_status'),
      life: 3000
    })
  }
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

const getPrintStatusSeverity = (status) => {
  switch (status) {
    case 'COMPLETED': return 'success'
    case 'CANCELLED': return 'danger'
    case 'PROCESSING': return 'info'
    case 'SHIPPED': return 'warning'
    case 'SUBMITTED': return 'secondary'
    case 'PAYMENT_PENDING': return 'contrast'
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