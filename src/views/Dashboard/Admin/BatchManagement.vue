<template>
  <PageWrapper title="Batch Payment Management" description="Manage card batch payments and fee waivers">
    <template #actions>
      <Button 
        icon="pi pi-refresh" 
        label="Refresh" 
        @click="refreshData"
        :loading="batchesStore.isLoadingBatches"
        severity="secondary"
        outlined
      />
    </template>

    <div class="space-y-6">

    <!-- Statistics Cards -->
    <div class="grid grid-cols-1 md:grid-cols-4 gap-6">
      <div class="bg-white rounded-xl shadow-soft border border-slate-200 p-6 hover:shadow-medium transition-shadow duration-200">
        <div class="flex items-center justify-between">
          <div>
            <h3 class="text-sm font-medium text-slate-600 mb-2">Pending Payment</h3>
            <p class="text-3xl font-bold text-orange-600">{{ dashboardStore.dashboardStats?.pending_payment_batches || 0 }}</p>
          </div>
          <div class="p-4 bg-gradient-to-r from-orange-500 to-amber-500 rounded-xl">
            <i class="pi pi-clock text-white text-2xl"></i>
          </div>
        </div>
      </div>

      <div class="bg-white rounded-xl shadow-soft border border-slate-200 p-6 hover:shadow-medium transition-shadow duration-200">
        <div class="flex items-center justify-between">
          <div>
            <h3 class="text-sm font-medium text-slate-600 mb-2">Paid Batches</h3>
            <p class="text-3xl font-bold text-blue-600">{{ dashboardStore.dashboardStats?.paid_batches || 0 }}</p>
          </div>
          <div class="p-4 bg-gradient-to-r from-blue-500 to-blue-600 rounded-xl">
            <i class="pi pi-check text-white text-2xl"></i>
          </div>
        </div>
      </div>

      <div class="bg-white rounded-xl shadow-soft border border-slate-200 p-6 hover:shadow-medium transition-shadow duration-200">
        <div class="flex items-center justify-between">
          <div>
            <h3 class="text-sm font-medium text-slate-600 mb-2">Waived Batches</h3>
            <p class="text-3xl font-bold text-blue-600">{{ dashboardStore.dashboardStats?.waived_batches || 0 }}</p>
          </div>
          <div class="p-4 bg-gradient-to-r from-blue-500 to-indigo-500 rounded-xl">
            <i class="pi pi-gift text-white text-2xl"></i>
          </div>
        </div>
      </div>

      <div class="bg-white rounded-xl shadow-soft border border-slate-200 p-6 hover:shadow-medium transition-shadow duration-200">
        <div class="flex items-center justify-between">
          <div>
            <h3 class="text-sm font-medium text-slate-600 mb-2">Total Revenue</h3>
            <p class="text-3xl font-bold text-slate-900">${{ formatCurrency(dashboardStore.dashboardStats?.total_revenue_cents || 0) }}</p>
          </div>
          <div class="p-4 bg-gradient-to-r from-slate-500 to-slate-600 rounded-xl">
            <i class="pi pi-dollar text-white text-2xl"></i>
          </div>
        </div>
      </div>
    </div>

    <!-- Batches Requiring Attention -->
    <div class="bg-white rounded-xl shadow-soft border border-slate-200 overflow-hidden">
      <div class="px-6 py-4 border-b border-slate-200">
        <h2 class="text-lg font-semibold text-slate-900">Batches Requiring Payment</h2>
        <p class="text-sm text-slate-600 mt-1">Unpaid batches that may need fee waiver</p>
      </div>

      <DataTable 
        :value="batchesStore.batchesRequiringAttention" 
        :loading="batchesStore.isLoadingBatches"
        paginator 
        :rows="10"
        dataKey="id"
        :filters="filters"
        filterDisplay="menu"
        :globalFilterFields="['user_email', 'card_name', 'batch_name']"
        showGridlines
        stripedRows
      >
        <template #header>
          <div class="flex justify-between items-center">
            <span class="text-sm text-slate-600">
              Total: {{ batchesStore.batchesRequiringAttention.length }} batches
            </span>
            <IconField iconPosition="left">
              <InputIcon class="pi pi-search" />
              <InputText 
                v-model="filters['global'].value" 
                placeholder="Search batches..." 
                class="w-64"
              />
            </IconField>
          </div>
        </template>

        <Column field="user_email" header="User" sortable>
          <template #body="{ data }">
            <div>
              <p class="font-medium text-slate-900">{{ data.user_email }}</p>
              <p class="text-sm text-slate-600">{{ data.created_by }}</p>
            </div>
          </template>
        </Column>

        <Column field="card_name" header="Card" sortable>
          <template #body="{ data }">
            <div>
              <p class="font-medium text-slate-900">{{ data.card_name }}</p>
              <p class="text-sm text-slate-600">{{ data.batch_name }}</p>
            </div>
          </template>
        </Column>

        <Column field="cards_count" header="Cards" sortable>
          <template #body="{ data }">
            <div class="text-center">
              <p class="font-medium text-slate-900">{{ data.cards_count }}</p>
              <p class="text-xs text-slate-500">cards</p>
            </div>
          </template>
        </Column>

        <Column field="payment_amount_cents" header="Amount" sortable>
          <template #body="{ data }">
            <div class="text-center">
              <p class="font-medium text-slate-900">${{ formatCurrency(data.payment_amount_cents) }}</p>
              <p class="text-xs text-slate-500">${{ (data.payment_amount_cents / data.cards_count / 100).toFixed(2) }}/card</p>
            </div>
          </template>
        </Column>

        <Column field="created_at" header="Created" sortable>
          <template #body="{ data }">
            <div class="text-sm text-slate-600">
              {{ formatDate(data.created_at) }}
            </div>
          </template>
        </Column>

        <Column header="Actions" :exportable="false" style="min-width: 12rem">
          <template #body="{ data }">
            <div class="flex gap-2">
              <Button 
                icon="pi pi-gift" 
                label="Waive Fee"
                @click="openWaiverDialog(data)"
                size="small"
                severity="primary"
                outlined
              />
              <Button 
                icon="pi pi-eye" 
                @click="viewBatchDetails(data)"
                size="small"
                severity="secondary"
                outlined
              />
            </div>
          </template>
        </Column>

        <template #empty>
          <div class="text-center py-8">
            <i class="pi pi-check-circle text-4xl text-blue-500 mb-4"></i>
            <p class="text-lg font-medium text-slate-900 mb-2">All Caught Up!</p>
            <p class="text-slate-600">No batches require payment attention at this time.</p>
          </div>
        </template>
      </DataTable>
    </div>

    <!-- Fee Waiver Dialog -->
    <MyDialog
      v-model="showWaiverDialog"
      header="Waive Batch Payment Fee"
      :confirmHandle="handleWaivePayment"
      confirmLabel="Waive Payment"
      confirmSeverity="primary"
      cancelLabel="Cancel"
      successMessage="Payment fee waived successfully"
      errorMessage="Failed to waive payment fee"
      @hide="onWaiverDialogHide"
      style="width: 90vw; max-width: 600px;"
    >
      <div class="space-y-6" v-if="selectedBatch">
        <!-- Batch Details -->
        <div class="bg-slate-50 rounded-lg p-6 border border-slate-200">
          <h4 class="font-semibold text-slate-900 mb-3">Batch Details</h4>
          <div class="grid grid-cols-2 gap-4 text-sm">
            <div>
              <span class="text-slate-600">User:</span>
              <span class="ml-2 font-medium">{{ selectedBatch.user_email }}</span>
            </div>
            <div>
              <span class="text-slate-600">Card:</span>
              <span class="ml-2 font-medium">{{ selectedBatch.card_name }}</span>
            </div>
            <div>
              <span class="text-slate-600">Batch:</span>
              <span class="ml-2 font-medium">{{ selectedBatch.batch_name }}</span>
            </div>
            <div>
              <span class="text-slate-600">Cards:</span>
              <span class="ml-2 font-medium">{{ selectedBatch.cards_count }}</span>
            </div>
            <div>
              <span class="text-slate-600">Amount:</span>
              <span class="ml-2 font-medium text-red-600">${{ formatCurrency(selectedBatch.payment_amount_cents) }}</span>
            </div>
            <div>
              <span class="text-slate-600">Created:</span>
              <span class="ml-2 font-medium">{{ formatDate(selectedBatch.created_at) }}</span>
            </div>
          </div>
        </div>

        <!-- Waiver Reason -->
        <div>
          <label for="waiver-reason" class="block text-sm font-medium text-slate-700 mb-2">
            Reason for Waiving Payment Fee <span class="text-red-500">*</span>
          </label>
          <Textarea 
            id="waiver-reason"
            v-model="waiverForm.reason"
            placeholder="Please provide a detailed reason for waiving the payment fee..."
            rows="4"
            class="w-full"
            :class="{ 'p-invalid': waiverForm.errors.reason }"
          />
          <small v-if="waiverForm.errors.reason" class="p-error">
            {{ waiverForm.errors.reason }}
          </small>
        </div>

        <!-- Warning -->
        <div class="bg-amber-50 border border-amber-200 rounded-lg p-4">
          <div class="flex items-start gap-3">
            <i class="pi pi-exclamation-triangle text-amber-600 text-lg"></i>
            <div>
              <h5 class="font-medium text-amber-900 mb-1">Important Notice</h5>
              <p class="text-sm text-amber-800">
                Waiving the payment fee will immediately generate {{ selectedBatch.cards_count }} cards for this batch. 
                This action cannot be undone and will be logged in the audit trail.
              </p>
            </div>
          </div>
        </div>
      </div>
    </MyDialog>
    </div>
  </PageWrapper>
</template>

<script setup>
import { ref, onMounted, computed } from 'vue';
import { useToast } from 'primevue/usetoast';
import { useAdminBatchesStore, useAdminDashboardStore } from '@/stores/admin';
import { FilterMatchMode } from '@primevue/core/api';

// PrimeVue Components
import Button from 'primevue/button';
import DataTable from 'primevue/datatable';
import Column from 'primevue/column';
import InputText from 'primevue/inputtext';
import IconField from 'primevue/iconfield';
import InputIcon from 'primevue/inputicon';
import Textarea from 'primevue/textarea';
import MyDialog from '@/components/MyDialog.vue';
import PageWrapper from '@/components/Layout/PageWrapper.vue';

const toast = useToast();
const batchesStore = useAdminBatchesStore();
const dashboardStore = useAdminDashboardStore();

// State
const showWaiverDialog = ref(false);
const selectedBatch = ref(null);
const waiverForm = ref({
  reason: '',
  errors: { reason: '' }
});

// Filters
const filters = ref({
  global: { value: null, matchMode: FilterMatchMode.CONTAINS }
});

// Methods
const refreshData = async () => {
  try {
    await Promise.all([
      batchesStore.fetchBatchesRequiringAttention(),
      dashboardStore.fetchDashboardStats()
    ]);
  } catch (error) {
    toast.add({
      severity: 'error',
      summary: 'Error',
      detail: 'Failed to refresh data',
      life: 3000
    });
  }
};

const openWaiverDialog = (batch) => {
  selectedBatch.value = batch;
  waiverForm.value.reason = '';
  waiverForm.value.errors.reason = '';
  showWaiverDialog.value = true;
};

const validateWaiverForm = () => {
  waiverForm.value.errors.reason = '';
  
  if (!waiverForm.value.reason.trim()) {
    waiverForm.value.errors.reason = 'Waiver reason is required';
    return false;
  }
  
  if (waiverForm.value.reason.trim().length < 10) {
    waiverForm.value.errors.reason = 'Please provide a more detailed reason (minimum 10 characters)';
    return false;
  }
  
  return true;
};

const handleWaivePayment = async () => {
  if (!validateWaiverForm()) {
    throw new Error('Please correct the form errors');
  }
  
  await batchesStore.waiveBatchPayment(selectedBatch.value.id, waiverForm.value.reason);
  
  // Refresh dashboard stats
  await dashboardStore.fetchDashboardStats();
};

const onWaiverDialogHide = () => {
  selectedBatch.value = null;
  waiverForm.value.reason = '';
  waiverForm.value.errors.reason = '';
};

const viewBatchDetails = (batch) => {
  // TODO: Implement batch details view
  toast.add({
    severity: 'info',
    summary: 'Coming Soon',
    detail: 'Batch details view will be implemented soon',
    life: 3000
  });
};

const formatCurrency = (cents) => {
  return (cents / 100).toFixed(2);
};

const formatDate = (dateString) => {
  return new Date(dateString).toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  });
};

// Lifecycle
onMounted(async () => {
  await refreshData();
});
</script>

<style scoped>
/* Component-specific styles - global table theme now handles standard styling */

:deep(.p-datatable .p-datatable-tbody > tr:hover) {
  background-color: #f8fafc;
}
</style> 