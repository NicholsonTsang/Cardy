<template>
  <PageWrapper title="Batch Management" description="View and manage all card batches">
    <template #actions>
      <Button 
        icon="pi pi-refresh" 
        label="Refresh" 
        @click="refreshData"
        :loading="batchesStore.isLoadingAllBatches"
        severity="secondary"
        outlined
      />
    </template>

    <div class="space-y-6">

    <!-- All Batches -->
    <div class="bg-white rounded-xl shadow-soft border border-slate-200 overflow-hidden">
      <div class="px-6 py-4 border-b border-slate-200">
        <h2 class="text-lg font-semibold text-slate-900">All Batches</h2>
        <p class="text-sm text-slate-600 mt-1">View and manage all card batches</p>
      </div>

      <DataTable 
        :value="batchesStore.allBatches" 
        :loading="batchesStore.isLoadingAllBatches"
        paginator 
        :rows="25"
        dataKey="id"
        showGridlines
        stripedRows
      >
        <template #header>
          <div class="flex flex-col gap-4">
            <div class="flex justify-between items-center">
              <span class="text-sm text-slate-600">
                Total: {{ batchesStore.allBatches.length }} batches
              </span>
            </div>
            
            <!-- Filters -->
            <div class="flex flex-wrap gap-3 items-center">
              <div class="flex items-center gap-2">
                <label class="text-sm text-slate-700 font-medium">Email Search:</label>
                <InputText 
                  v-model="emailSearch"
                  placeholder="Search by user email..."
                  class="w-64"
                  @input="applyFilters"
                />
              </div>
              
              <div class="flex items-center gap-2">
                <label class="text-sm text-slate-700 font-medium">Payment Status:</label>
                <Select 
                  v-model="paymentStatusFilter"
                  :options="paymentStatusOptions"
                  optionLabel="label"
                  optionValue="value"
                  placeholder="All Statuses"
                  class="w-40"
                  showClear
                  @change="applyFilters"
                />
              </div>
              
              <Button 
                icon="pi pi-times"
                label="Clear Filters"
                @click="clearFilters"
                size="small"
                severity="secondary"
                outlined
                v-if="hasActiveFilters"
              />
            </div>
          </div>
        </template>

        <Column field="batch_number" header="Batch #" sortable>
          <template #body="{ data }">
            <span class="font-mono text-sm font-medium text-slate-900">
              #{{ data.batch_number.toString().padStart(6, '0') }}
            </span>
          </template>
        </Column>

        <Column field="user_email" header="User Email" sortable>
          <template #body="{ data }">
            <span class="text-slate-900">{{ data.user_email }}</span>
          </template>
        </Column>
        
        <Column field="payment_status" header="Payment Status" sortable>
          <template #body="{ data }">
            <Tag
              :value="data.payment_status"
              :severity="getPaymentStatusSeverity(data.payment_status)"
              class="text-xs"
            />
          </template>
        </Column>

        <Column field="cards_count" header="Card Count" sortable>
          <template #body="{ data }">
            <span class="font-medium text-slate-900">{{ data.cards_count }}</span>
          </template>
        </Column>

        <Column field="created_at" header="Created At" sortable>
          <template #body="{ data }">
            <span class="text-sm text-slate-600">
              {{ formatDate(data.created_at) }}
            </span>
          </template>
        </Column>

        <template #empty>
          <div class="text-center py-8">
            <i class="pi pi-inbox text-4xl text-slate-400 mb-4"></i>
            <p class="text-lg font-medium text-slate-900 mb-2">No Batches Found</p>
            <p class="text-slate-600">No batches match your current filters.</p>
          </div>
        </template>
      </DataTable>
    </div>
    </div>
  </PageWrapper>
</template>

<script setup>
import { ref, onMounted, computed } from 'vue';
import { useToast } from 'primevue/usetoast';
import { useAdminBatchesStore } from '@/stores/admin';

// PrimeVue Components
import Button from 'primevue/button';
import DataTable from 'primevue/datatable';
import Column from 'primevue/column';
import InputText from 'primevue/inputtext';
import Select from 'primevue/select';
import Tag from 'primevue/tag';
import PageWrapper from '@/components/Layout/PageWrapper.vue';

const toast = useToast();
const batchesStore = useAdminBatchesStore();

// Filter state
const emailSearch = ref('');
const paymentStatusFilter = ref(null);

// Filter options
const paymentStatusOptions = ref([
  { label: 'Pending', value: 'PENDING' },
  { label: 'Paid', value: 'PAID' },
  { label: 'Admin Issued', value: 'FREE' }
]);

// Computed for active filters
const hasActiveFilters = computed(() => {
  return emailSearch.value.trim() !== '' || paymentStatusFilter.value;
});

// Methods
const applyFilters = async () => {
  try {
    await batchesStore.fetchAllBatches(
      emailSearch.value.trim() || undefined,
      paymentStatusFilter.value || undefined
    );
  } catch (error) {
    toast.add({
      severity: 'error',
      summary: 'Error',
      detail: 'Failed to apply filters',
      life: 3000
    });
  }
};

const clearFilters = async () => {
  emailSearch.value = '';
  paymentStatusFilter.value = null;
  await applyFilters();
};

const refreshData = async () => {
  await applyFilters();
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

const getPaymentStatusSeverity = (status) => {
  switch (status) {
    case 'PENDING': return 'warning';
    case 'PAID': return 'success';
    case 'FREE': return 'success'; // Admin-issued batches
    default: return 'secondary';
  }
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