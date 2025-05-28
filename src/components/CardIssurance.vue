<template>
  <div class="space-y-6">
    <!-- Statistics Cards -->
    <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
      <div class="bg-white rounded-xl shadow-lg border border-slate-200 p-6">
        <div class="flex items-center justify-between">
          <div>
            <h3 class="text-sm font-medium text-slate-600 mb-2">Total Issued</h3>
            <p class="text-3xl font-bold text-slate-900">{{ stats.total_issued }}</p>
          </div>
          <div class="p-4 bg-gradient-to-r from-blue-500 to-indigo-500 rounded-xl">
            <i class="pi pi-credit-card text-white text-2xl"></i>
          </div>
        </div>
      </div>

      <div class="bg-white rounded-xl shadow-lg border border-slate-200 p-6">
        <div class="flex items-center justify-between">
          <div>
            <h3 class="text-sm font-medium text-slate-600 mb-2">Activation Rate</h3>
            <p class="text-3xl font-bold text-slate-900">{{ stats.activation_rate }}%</p>
            <p class="text-sm text-green-600 mt-1">{{ stats.total_activated }} active</p>
          </div>
          <div class="p-4 bg-gradient-to-r from-green-500 to-emerald-500 rounded-xl">
            <i class="pi pi-check-circle text-white text-2xl"></i>
          </div>
        </div>
      </div>

      <div class="bg-white rounded-xl shadow-lg border border-slate-200 p-6">
        <div class="flex items-center justify-between">
          <div>
            <h3 class="text-sm font-medium text-slate-600 mb-2">Batches</h3>
            <p class="text-3xl font-bold text-slate-900">{{ stats.total_batches }}</p>
          </div>
          <div class="p-4 bg-gradient-to-r from-purple-500 to-violet-500 rounded-xl">
            <i class="pi pi-box text-white text-2xl"></i>
          </div>
        </div>
      </div>
    </div>

    <!-- Actions Bar -->
    <div class="flex justify-between items-center">
      <div>
        <h2 class="text-xl font-semibold text-slate-900">Card Operations</h2>
        <p class="text-slate-600 mt-1">Issue new batches and manage existing ones</p>
      </div>
      <Button 
        icon="pi pi-plus" 
        label="Issue New Batch" 
        severity="primary"
        class="px-4 py-2 shadow-lg hover:shadow-xl transition-shadow"
        @click="showIssueBatchDialog = true" 
      />
    </div>

    <!-- Batches DataTable -->
    <div class="bg-white rounded-xl shadow-lg border border-slate-200 overflow-hidden">
      <div class="p-6 border-b border-slate-200 bg-gradient-to-r from-slate-50 to-slate-100">
        <h3 class="text-lg font-semibold text-slate-900">Card Batches</h3>
      </div>
      <div class="p-6">
        <DataTable 
          :value="batches" 
          :loading="isLoading"
          responsiveLayout="scroll"
          emptyMessage="No batches created yet for this card design."
          class="border-0"
          v-model:expandedRows="expandedBatchRows"
          dataKey="id"
        >
          <Column :expander="true" headerStyle="width: 3rem" />
          <Column field="batch_name" header="Batch Name" sortable>
            <template #body="{ data }">
              <span class="font-semibold">{{ data.batch_name }}</span>
            </template>
          </Column>
          <Column field="cards_count" header="Cards Issued" sortable></Column>
          <Column field="active_cards_count" header="Cards Active" sortable></Column>
          <Column field="is_disabled" header="Status" sortable>
            <template #body="{ data }">
              <Tag :value="data.is_disabled ? 'Disabled' : 'Enabled'" 
                   :severity="data.is_disabled ? 'danger' : 'success'" />
            </template>
          </Column>
          <Column field="created_at" header="Created" sortable>
            <template #body="{ data }">
              {{ formatDate(data.created_at) }}
            </template>
          </Column>
          <Column header="Actions" style="min-width:12rem">
            <template #body="{ data }">
              <div class="flex gap-2">
                <Button 
                  :icon="data.is_disabled ? 'pi pi-check-circle' : 'pi pi-times-circle'" 
                  :label="data.is_disabled ? 'Enable' : 'Disable'"
                  :severity="data.is_disabled ? 'success' : 'warning'" 
                  outlined
                  size="small"
                  class="p-2"
                  @click="confirmToggleBatchStatus(data)"
                  v-tooltip.top="data.is_disabled ? 'Enable Batch' : 'Disable Batch'"
                />
                <Button 
                  icon="pi pi-print" 
                  label="Print"
                  severity="info" 
                  outlined
                  size="small"
                  class="p-2"
                  @click="openRequestPrintDialog(data)"
                  :disabled="data.is_disabled || hasActivePrintRequest(data.id)"
                  v-tooltip.top="data.is_disabled ? 'Batch is disabled' : (hasActivePrintRequest(data.id) ? 'Print request active' : 'Request Printing')"
                />
              </div>
            </template>
          </Column>
          <template #expansion="{ data: batch }">
            <div class="p-4 bg-slate-50 border-t border-slate-200">
              <h4 class="text-md font-semibold text-slate-800 mb-3">Print Requests for {{ batch.batch_name }}</h4>
              <div v-if="isLoadingPrintRequestsForBatch(batch.id)" class="text-center py-4">
                <i class="pi pi-spin pi-spinner" style="font-size: 2rem"></i>
                <p>Loading print requests...</p>
              </div>
              <div v-else-if="getPrintRequestsFor(batch.id) && getPrintRequestsFor(batch.id).length > 0">
                <ul class="space-y-2">
                  <li v-for="pr in getPrintRequestsFor(batch.id)" :key="pr.id" class="p-3 bg-white rounded-lg shadow border border-slate-200">
                    <div class="flex justify-between items-center">
                      <span class="font-medium text-slate-700">Status: 
                        <Tag :value="pr.status" :severity="getPrintRequestStatusSeverity(pr.status)" class="ml-1" />
                      </span>
                       <span class="text-xs text-slate-500">Requested: {{ formatDate(pr.requested_at) }}</span>
                    </div>
                    <p class="text-sm text-slate-600 mt-1" v-if="pr.shipping_address">Shipping to: {{ pr.shipping_address }}</p>
                    <p class="text-sm text-slate-500 mt-1" v-if="pr.admin_notes">Admin Notes: {{ pr.admin_notes }}</p>
                     <p class="text-sm text-slate-500 mt-1" v-if="pr.payment_details">Payment: {{ pr.payment_details }}</p>
                  </li>
                </ul>
              </div>
              <div v-else class="text-center py-4 text-slate-500">
                No print requests found for this batch.
              </div>
            </div>
          </template>
        </DataTable>
      </div>
    </div>

    <!-- Request Print Dialog -->
    <MyDialog
      v-model="showRequestPrintDialog"
      header="Request Card Printing"
      :confirmHandle="handleRequestPrint"
      confirmLabel="Submit Request"
      confirmSeverity="success"
      successMessage="Print request submitted successfully!"
      errorMessage="Failed to submit print request"
      @hide="onPrintDialogHide"
      style="width: 90vw; max-width: 500px;"
    >
      <div class="space-y-4" v-if="selectedBatchForPrinting">
        <p class="text-sm text-slate-700">
          You are about to request printing for <strong>{{ selectedBatchForPrinting.batch_name }}</strong> ({{ selectedBatchForPrinting.cards_count }} cards).
          The cost is <strong>$2 USD per card</strong>, totaling approximately <strong>${{ selectedBatchForPrinting.cards_count * 2 }} USD</strong>.
        </p>
        <p class="text-sm text-slate-600">
          After submission, our team will contact you via email with payment instructions and to confirm your shipping address.
        </p>
        <div>
          <label class="block text-sm font-medium text-slate-700 mb-2">Preferred Shipping Address</label>
          <Textarea 
            v-model="printRequestForm.shippingAddress" 
            rows="3"
            class="w-full px-4 py-3 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors resize-none"
            placeholder="Enter your preferred shipping address..."
            autoResize
            :class="{ 'border-red-300 focus:ring-red-500 focus:border-red-500': !printRequestForm.shippingAddress.trim() && printRequestForm.submitted }"
          />
          <small v-if="!printRequestForm.shippingAddress.trim() && printRequestForm.submitted" class="p-error">Shipping address is required.</small>
        </div>
      </div>
    </MyDialog>

    <!-- Issued Cards DataTable -->
    <div class="bg-white rounded-xl shadow-lg border border-slate-200 overflow-hidden">
      <div class="p-6 border-b border-slate-200 bg-gradient-to-r from-slate-50 to-slate-100">
        <h3 class="text-lg font-semibold text-slate-900">Individual Issued Cards</h3>
      </div>
      
      <div class="p-6">
        <DataTable 
          v-model:filters="filters"
          :value="issuedCards" 
          :loading="isLoading"
          :paginator="true" 
          :rows="20"
          :rowsPerPageOptions="[15, 20, 30, 50]"
          stripedRows
          responsiveLayout="scroll"
          emptyMessage="No cards issued yet for this design."
          class="border-0"
          dataKey="id"
          filterDisplay="menu"
          :globalFilterFields="['id', 'activation_code', 'batch_name']"
        >
          <template #header>
            <div class="flex flex-col sm:flex-row gap-4 justify-between items-start sm:items-center mb-4">
              <div class="flex flex-col sm:flex-row gap-3 flex-1">
                <!-- Global Search -->
                <div class="flex-1 min-w-0">
                  <IconField>
                    <InputIcon>
                      <i class="pi pi-search" />
                    </InputIcon>
                    <InputText 
                      v-model="filters['global'].value" 
                      placeholder="Search Card ID, Activation Code, or Batch..." 
                      class="w-full"
                    />
                  </IconField>
                </div>
                
                <!-- Batch Filter -->
                <div class="min-w-[200px]">
                  <Select 
                    v-model="filters['batch_name'].value"
                    :options="[{ label: 'All Batches', value: null }, ...batchOptions]"
                    optionLabel="label"
                    optionValue="value"
                    placeholder="Filter by Batch"
                    class="w-full"
                    showClear
                  />
                </div>
                
                <!-- Status Filter -->
                <div class="min-w-[150px]">
                  <Select 
                    v-model="filters['active'].value"
                    :options="statusOptions"
                    optionLabel="label"
                    optionValue="value"
                    placeholder="Filter by Status"
                    class="w-full"
                    showClear
                  />
                </div>
              </div>
              
              <!-- Clear Filters Button -->
              <Button 
                type="button" 
                icon="pi pi-filter-slash" 
                label="Clear" 
                outlined 
                @click="clearFilters()"
                class="flex-shrink-0"
              />
            </div>
          </template>
          
          <template #empty> 
            <div class="text-center py-8">
              <i class="pi pi-search text-4xl text-slate-300 mb-4"></i>
              <p class="text-slate-500">No cards found matching your criteria.</p>
            </div>
          </template>

          <Column field="id" header="Card ID" sortable>
            <template #body="{ data }">
              <code class="bg-slate-100 px-3 py-1 rounded-lg text-sm font-mono text-slate-700">
                {{ data.id.substring(0, 8) }}...
              </code>
            </template>
          </Column>
          
          <Column field="activation_code" header="Activation Code" sortable>
            <template #body="{ data }">
              <code class="bg-slate-100 px-3 py-1 rounded-lg text-sm font-mono text-slate-700">
                {{ data.activation_code.substring(0, 8) }}...
              </code>
            </template>
          </Column>
          
          <Column field="active" header="Status" sortable>
            <template #body="{ data }">
              <Tag 
                :value="data.active ? 'Active' : 'Pending'" 
                :severity="data.active ? 'success' : 'warning'"
                class="px-3 py-1"
              />
            </template>
          </Column>

          <Column field="batch_name" header="Batch" sortable>
            <template #body="{ data }">
              <span class="text-sm font-medium text-slate-900">{{ data.batch_name }}</span>
              <Tag v-if="data.batch_is_disabled" value="Disabled" severity="danger" class="ml-2 px-2 py-0.5 text-xs"/>
            </template>
          </Column>

          <Column field="created_at" header="Created" sortable>
            <template #body="{ data }">
              <span class="text-sm text-slate-600">{{ formatDate(data.issue_at) }}</span>
            </template>
          </Column>

          <Column field="activated_at" header="Activated" sortable>
            <template #body="{ data }">
              <span v-if="data.active_at" class="text-sm text-slate-600">
                {{ formatDate(data.active_at) }}
              </span>
              <span v-else class="text-sm text-slate-400">Not activated</span>
            </template>
          </Column>

          <Column header="Actions" :exportable="false" style="min-width:8rem">
            <template #body="{ data }">
              <div class="flex gap-2">
                <Button 
                  icon="pi pi-eye" 
                  severity="info" 
                  outlined
                  size="small"
                  class="p-2"
                  @click="viewCard(data)" 
                  v-tooltip.top="'View Details'"
                />
                <Button 
                  icon="pi pi-trash" 
                  severity="danger" 
                  outlined
                  size="small"
                  class="p-2"
                  @click="confirmDeleteCard(data)" 
                  v-tooltip.top="'Delete'"
                  :disabled="data.active || data.batch_is_disabled"
                />
              </div>
            </template>
          </Column>
        </DataTable>
      </div>
    </div>

    <!-- Issue Batch Dialog -->
    <MyDialog
      v-model="showIssueBatchDialog"
      header="Issue New Batch"
      :confirmHandle="handleIssueBatch"
      confirmLabel="Issue Batch"
      confirmSeverity="success"
      successMessage="Batch issued successfully!"
      errorMessage="Failed to issue batch"
      @hide="onIssueBatchDialogHide"
      style="width: 90vw; max-width: 600px;"
    >
      <div class="space-y-6">
        <div>
          <label class="block text-sm font-medium text-slate-700 mb-2">Number of Cards</label>
          <InputNumber 
            v-model="batchForm.quantity" 
            :min="1" 
            :max="1000"
            class="w-full"
            placeholder="Enter number of cards to issue"
          />
           <small v-if="batchForm.errors.quantity" class="p-error">{{ batchForm.errors.quantity }}</small>
        </div>
        
        <div>
          <label class="block text-sm font-medium text-slate-700 mb-2">Description (Optional)</label>
          <Textarea 
            v-model="batchForm.description" 
            rows="3"
            class="w-full px-4 py-3 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors resize-none"
            placeholder="Describe this batch... (e.g., purpose, event)"
            autoResize
          />
        </div>
      </div>
    </MyDialog>

    <!-- Card Details Dialog -->
    <MyDialog
      v-model="showCardDetailsDialog"
      header="Card Details"
      :showConfirm="false"
      cancelLabel="Close"
      @hide="selectedCard = null"
      style="width: 90vw; max-width: 800px;"
    >
      <div v-if="selectedCard" class="space-y-6">
        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div class="space-y-4">
            <div>
              <h4 class="text-sm font-medium text-slate-700 mb-2">Card ID</h4>
              <code class="bg-slate-100 px-3 py-2 rounded-lg text-sm font-mono text-slate-700 block break-all">
                {{ selectedCard.id }}
              </code>
            </div>
            
            <div>
              <h4 class="text-sm font-medium text-slate-700 mb-2">Activation Code</h4>
              <code class="bg-slate-100 px-3 py-2 rounded-lg text-sm font-mono text-slate-700 block break-all">
                {{ selectedCard.activation_code }}
              </code>
            </div>
            
            <div>
              <h4 class="text-sm font-medium text-slate-700 mb-2">Status</h4>
              <Tag 
                :value="selectedCard.active ? 'Active' : 'Pending'" 
                :severity="selectedCard.active ? 'success' : 'warning'"
                class="px-3 py-1"
              />
            </div>

            <div>
              <h4 class="text-sm font-medium text-slate-700 mb-2">Batch</h4>
              <p class="text-sm text-slate-900">{{ selectedCard.batch_name }}</p>
              <Tag v-if="selectedCard.batch_is_disabled" value="Disabled" severity="danger" class="mt-1 px-2 py-0.5 text-xs"/>
            </div>

          </div>
          
          <div class="space-y-4">
            <div>
              <h4 class="text-sm font-medium text-slate-700 mb-2">Created (Issued)</h4>
              <p class="text-sm text-slate-600">{{ formatDate(selectedCard.issue_at) }}</p>
            </div>
            
            <div v-if="selectedCard.active_at">
              <h4 class="text-sm font-medium text-slate-700 mb-2">Activated</h4>
              <p class="text-sm text-slate-600">{{ formatDate(selectedCard.active_at) }}</p>
            </div>

            <!-- QR Code Section -->
            <div class="mt-4 p-4 border border-slate-200 rounded-lg bg-slate-50">
                <h4 class="text-sm font-medium text-slate-700 mb-3 text-center">Scan to Activate & View</h4>
                <div class="flex justify-center">
                    <qrcode-vue 
                        :value="selectedCardActivationUrl" 
                        :size="200" 
                        level="H" 
                        render-as="svg"
                        v-if="selectedCardActivationUrl"
                    />
                </div>
                <input 
                    type="text" 
                    :value="selectedCardActivationUrl" 
                    readonly 
                    class="mt-3 w-full text-xs p-2 border border-slate-300 rounded bg-slate-100 cursor-pointer focus:outline-none focus:ring-1 focus:ring-blue-500"
                    @click="copyToClipboard(selectedCardActivationUrl)"
                    title="Click to copy URL"
                />
                 <p v-if="copied" class="text-xs text-green-600 text-center mt-1">Copied to clipboard!</p>
            </div>
          </div>
        </div>
      </div>
    </MyDialog>

    <!-- Delete Confirmation Dialog -->
    <ConfirmDialog group="deleteCardConfirmation"></ConfirmDialog>
    <ConfirmDialog group="toggleBatchConfirmation"></ConfirmDialog>
    <ConfirmDialog group="requestPrintConfirmation"></ConfirmDialog>
  </div>
</template>

<script setup>
import { ref, onMounted, computed, watch } from 'vue';
import { useToast } from 'primevue/usetoast';
import { useConfirm } from 'primevue/useconfirm';
import { useIssuedCardStore, PrintRequestStatus } from '@/stores/issuedCard';
import QrcodeVue from 'qrcode.vue';
import { FilterMatchMode } from '@primevue/core/api';

// PrimeVue Components
import Card from 'primevue/card';
import Button from 'primevue/button';
import DataTable from 'primevue/datatable';
import Column from 'primevue/column';
import Tag from 'primevue/tag';
import Badge from 'primevue/badge';
import InputNumber from 'primevue/inputnumber';
import InputText from 'primevue/inputtext';
import Textarea from 'primevue/textarea';
import Dialog from 'primevue/dialog';
import ConfirmDialog from 'primevue/confirmdialog';
import MyDialog from './MyDialog.vue';
import Select from 'primevue/select';
import IconField from 'primevue/iconfield';
import InputIcon from 'primevue/inputicon';

// Props
const props = defineProps({
  cardId: {
    type: String,
    required: true 
  }
});

// Store and composables
const issuedCardStore = useIssuedCardStore();
const toast = useToast();
const confirm = useConfirm();

// Reactive data
const showIssueBatchDialog = ref(false);
const showCardDetailsDialog = ref(false);
const selectedCard = ref(null);
const batchForm = ref({
  quantity: 10,
  description: '',
  errors: {
    quantity: ''
  }
});
const copied = ref(false);

// Filters for Individual Issued Cards table
const filters = ref({
  global: { value: null, matchMode: FilterMatchMode.CONTAINS },
  id: { value: null, matchMode: FilterMatchMode.CONTAINS },
  batch_name: { value: null, matchMode: FilterMatchMode.EQUALS },
  active: { value: null, matchMode: FilterMatchMode.EQUALS }
});

// For Batch Management Table
const expandedBatchRows = ref([]);
const showRequestPrintDialog = ref(false);
const selectedBatchForPrinting = ref(null);
const printRequestForm = ref({
  shippingAddress: '',
  submitted: false, // To track if form submission was attempted for validation
});
const isLoadingPrintRequests = ref(false);

// Computed properties
const isLoading = computed(() => issuedCardStore.isLoading);
const issuedCards = computed(() => issuedCardStore.issuedCards);
const batches = computed(() => issuedCardStore.batches);
const stats = computed(() => issuedCardStore.stats);
const printRequestsForBatchMap = computed(() => issuedCardStore.printRequestsForBatch);

const selectedCardActivationUrl = computed(() => {
  if (selectedCard.value && selectedCard.value.id && selectedCard.value.activation_code) {
    return `https://app.cardy.com/issuedcard/${selectedCard.value.id}/${selectedCard.value.activation_code}`;
  }
  return '';
});

// Computed properties for filter options
const batchOptions = computed(() => {
  const uniqueBatches = [...new Set(issuedCards.value.map(card => card.batch_name))];
  return uniqueBatches.map(batch => ({ label: batch, value: batch }));
});

const statusOptions = computed(() => [
  { label: 'All', value: null },
  { label: 'Active', value: true },
  { label: 'Pending', value: false }
]);

const getPrintRequestsFor = (batchId) => {
  return printRequestsForBatchMap.value[batchId] || [];
};

const hasActivePrintRequest = (batchId) => {
  const requests = getPrintRequestsFor(batchId);
  return requests.some(pr => ![PrintRequestStatus.COMPLETED, PrintRequestStatus.CANCELLED].includes(pr.status));
};

const isLoadingPrintRequestsForBatch = (batchId) => {
    // This is a simplified check; ideally, track loading per batch
    return isLoadingPrintRequests.value; 
};

// Format date helper
const formatDate = (dateString) => {
  if (!dateString) return '-';
  return new Date(dateString).toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  });
};

// Clear filters function
const clearFilters = () => {
  filters.value = {
    global: { value: null, matchMode: FilterMatchMode.CONTAINS },
    id: { value: null, matchMode: FilterMatchMode.CONTAINS },
    batch_name: { value: null, matchMode: FilterMatchMode.EQUALS },
    active: { value: null, matchMode: FilterMatchMode.EQUALS }
  };
};

// Validate batch form
const validateBatchForm = () => {
  batchForm.value.errors = { quantity: '' };
  let isValid = true;

  if (!batchForm.value.quantity || batchForm.value.quantity < 1) {
    batchForm.value.errors.quantity = 'Quantity must be at least 1';
    isValid = false;
  } else if (batchForm.value.quantity > 1000) {
    batchForm.value.errors.quantity = 'Quantity cannot exceed 1000';
    isValid = false;
  }

  return isValid;
};

// Handle issue batch
const handleIssueBatch = async () => {
  if (!validateBatchForm()) {
    if (!batchForm.value.errors.quantity && batchForm.value.quantity && (batchForm.value.quantity < 1 || batchForm.value.quantity > 1000)) {
        batchForm.value.errors.quantity = 'Quantity must be between 1 and 1000.';
    }
    return Promise.reject('Validation failed');
  }

  if (!props.cardId) {
    toast.add({ 
      severity: 'error', 
      summary: 'Error', 
      detail: 'No card selected for batch issuance.', 
      life: 3000 
    });
    return Promise.reject('No card selected');
  }

  try {
    await issuedCardStore.issueBatch(props.cardId, batchForm.value.quantity);
    
    toast.add({ 
      severity: 'success', 
      summary: 'Success', 
      detail: `Batch with ${batchForm.value.quantity} cards issued successfully!`, 
      life: 3000 
    });

    await issuedCardStore.loadCardData(props.cardId);
    
    batchForm.value.quantity = 10;
    batchForm.value.description = '';
    return Promise.resolve();
  } catch (error) {
    console.error('Error issuing batch:', error);
    const errorMessage = error.message || 'Failed to issue card batch';
    toast.add({ 
      severity: 'error', 
      summary: 'Error Issuing Batch', 
      detail: errorMessage, 
      life: 5000 
    });
    return Promise.reject(errorMessage);
  }
};

// Activate a card
const activateCard = async (card) => {
  try {
    await issuedCardStore.activateCard(card.id, card.activation_code);
    
    toast.add({ 
      severity: 'success', 
      summary: 'Success', 
      detail: 'Card activated successfully', 
      life: 3000 
    });

    await issuedCardStore.loadCardData(props.cardId);
  } catch (error) {
    console.error('Error activating card:', error);
    toast.add({ 
      severity: 'error', 
      summary: 'Error', 
      detail: 'Failed to activate card', 
      life: 3000 
    });
  }
};

// Delete a single card
const deleteCard = async (card) => {
  try {
    await issuedCardStore.deleteIssuedCard(card.id);
    
    toast.add({ 
      severity: 'success', 
      summary: 'Success', 
      detail: 'Card deleted successfully', 
      life: 3000 
    });

    await issuedCardStore.loadCardData(props.cardId);
  } catch (error) {
    console.error('Error deleting card:', error);
    toast.add({ 
      severity: 'error', 
      summary: 'Error', 
      detail: 'Failed to delete card', 
      life: 3000 
    });
  }
};

// View card details
const viewCard = (card) => {
  selectedCard.value = card;
  showCardDetailsDialog.value = true;
};

// Confirm delete card
const confirmDeleteCard = (card) => {
  confirm.require({
    group: 'deleteCardConfirmation',
    message: `Are you sure you want to delete card "${card.id.substring(0, 8)}..."? This action cannot be undone.`,
    header: 'Confirm Card Deletion',
    icon: 'pi pi-exclamation-triangle',
    acceptLabel: 'Delete',
    rejectLabel: 'Cancel',
    acceptClass: 'p-button-danger',
    accept: async () => {
      await deleteCard(card);
    },
    reject: () => {
      toast.add({ 
        severity: 'info', 
        summary: 'Cancelled', 
        detail: 'Card deletion cancelled', 
        life: 2000 
      });
    }
  });
};

// Dialog hide handlers
const onIssueBatchDialogHide = () => {
  batchForm.value.quantity = 10;
  batchForm.value.description = '';
  batchForm.value.errors = { quantity: '' };
  showIssueBatchDialog.value = false;
};

const onCardDetailsDialogHide = () => {
    selectedCard.value = null;
    copied.value = false;
    showCardDetailsDialog.value = false; 
}

const copyToClipboard = async (text) => {
  try {
    await navigator.clipboard.writeText(text);
    copied.value = true;
    setTimeout(() => { copied.value = false; }, 2000);
    toast.add({ severity: 'success', summary: 'Copied', detail: 'Activation URL copied to clipboard', life: 2000 });
  } catch (err) {
    console.error('Failed to copy: ', err);
    toast.add({ severity: 'error', summary: 'Copy Failed', detail: 'Could not copy URL', life: 2000 });
  }
};

// Batch Management Functions
const confirmToggleBatchStatus = (batch) => {
  const action = batch.is_disabled ? 'Enable' : 'Disable';
  let message = `Are you sure you want to ${action.toLowerCase()} batch "${batch.batch_name}"?`;
  if (!batch.is_disabled) { // If attempting to disable
      message += ` This will prevent new cards from this batch from being activated if they aren't already.`;
  }

  confirm.require({
    group: 'toggleBatchConfirmation',
    message: message,
    header: `${action} Batch`,
    icon: batch.is_disabled ? 'pi pi-check-circle' : 'pi pi-exclamation-triangle',
    acceptLabel: action,
    rejectLabel: 'Cancel',
    acceptClass: batch.is_disabled ? 'p-button-success' : 'p-button-warning',
    accept: async () => {
      try {
        await issuedCardStore.toggleBatchDisabledStatus(batch.id, !batch.is_disabled, props.cardId);
        toast.add({ severity: 'success', summary: 'Success', detail: `Batch ${batch.batch_name} ${action.toLowerCase()}d successfully.`, life: 3000 });
        // Data should reload via store's fetchCardBatches call if toggleBatchDisabledStatus is set up correctly.
        // If not, manually call: await issuedCardStore.loadCardData(props.cardId);
      } catch (error) {
        console.error(`Error ${action.toLowerCase()}ing batch:`, error);
        toast.add({ severity: 'error', summary: 'Error', detail: error.message || `Failed to ${action.toLowerCase()} batch.`, life: 3000 });
      }
    }
  });
};

const openRequestPrintDialog = (batch) => {
  if (batch.is_disabled || hasActivePrintRequest(batch.id)) {
    toast.add({ severity: 'warn', summary: 'Cannot Request Print', detail: batch.is_disabled ? 'Batch is disabled.' : 'An active print request already exists.', life: 3000 });
    return;
  }
  selectedBatchForPrinting.value = batch;
  printRequestForm.value.shippingAddress = ''; // Reset form
  printRequestForm.value.submitted = false;
  showRequestPrintDialog.value = true;
};

const handleRequestPrint = async () => {
  printRequestForm.value.submitted = true;
  if (!printRequestForm.value.shippingAddress.trim()) {
    return Promise.reject('Shipping address is required.');
  }
  if (!selectedBatchForPrinting.value) return Promise.reject('No batch selected.');

  try {
    await issuedCardStore.requestPrintForBatch(selectedBatchForPrinting.value.id, printRequestForm.value.shippingAddress);
    toast.add({ severity: 'success', summary: 'Success', detail: 'Print request submitted.', life: 3000 });
    // The store action fetchPrintRequestsForBatch should update the data.
    // Optionally, call loadCardData if a full refresh is desired or if specific batch data isn't updating.
    // await issuedCardStore.loadCardData(props.cardId); // To ensure full consistency
    return Promise.resolve();
  } catch (error) {
    console.error('Error requesting print:', error);
    toast.add({ severity: 'error', summary: 'Error', detail: error.message || 'Failed to submit print request.', life: 3000 });
    return Promise.reject(error.message || 'Failed to submit print request.');
  }
};

const onPrintDialogHide = () => {
  showRequestPrintDialog.value = false;
  selectedBatchForPrinting.value = null;
  printRequestForm.value.shippingAddress = '';
  printRequestForm.value.submitted = false;
};

const getPrintRequestStatusSeverity = (status) => {
  switch (status) {
    case PrintRequestStatus.SUBMITTED: return 'info';
    case PrintRequestStatus.PAYMENT_PENDING: return 'warning';
    case PrintRequestStatus.PROCESSING: return 'contrast';
    case PrintRequestStatus.SHIPPED: return 'primary';
    case PrintRequestStatus.COMPLETED: return 'success';
    case PrintRequestStatus.CANCELLED: return 'danger';
    default: return 'secondary';
  }
};

// Fetch print requests when a batch row is expanded
watch(expandedBatchRows, async (newExpandedRows, oldExpandedRows) => {
  if (!newExpandedRows) return;
  
  // Find newly expanded rows
  const newlyExpandedBatch = newExpandedRows.find(row => 
    !(oldExpandedRows && oldExpandedRows.some(oldRow => oldRow.id === row.id))
  );

  if (newlyExpandedBatch && newlyExpandedBatch.id) {
    // Check if data already exists or is fresh enough
    const existingRequests = getPrintRequestsFor(newlyExpandedBatch.id);
    if (!existingRequests || existingRequests.length === 0) { // Or add a timestamp check for freshness
        isLoadingPrintRequests.value = true;
        try {
            await issuedCardStore.fetchPrintRequestsForBatch(newlyExpandedBatch.id);
        } catch (error) {
            console.error('Failed to fetch print requests for batch:', newlyExpandedBatch.id, error);
            toast.add({ severity: 'error', summary: 'Load Error', detail: 'Could not load print requests.', life: 3000 });
        } finally {
            isLoadingPrintRequests.value = false;
        }
    }
  }
});

// Initialize component
onMounted(() => {
  if (props.cardId) {
    issuedCardStore.loadCardData(props.cardId);
  }
});
</script>

<style scoped>
/* Ultra compact DataTable styling */
:deep(.p-datatable-sm) {
  font-size: 0.75rem;
  line-height: 1.2;
}

:deep(.p-datatable-sm .p-datatable-thead > tr > th) {
  padding: 0.25rem 0.375rem;
  font-size: 0.75rem;
  font-weight: 500;
}

:deep(.p-datatable-sm .p-datatable-tbody > tr > td) {
  padding: 0.25rem 0.375rem;
  font-size: 0.75rem;
}

:deep(.p-paginator) {
  padding: 0.375rem;
  font-size: 0.75rem;
}

:deep(.p-card .p-card-content) {
  padding: 0;
}

:deep(.p-button) {
  font-size: 0.75rem;
}

:deep(.p-tag) {
  font-size: 0.75rem;
  padding: 0.125rem 0.375rem;
}

:deep(.p-badge) {
  font-size: 0.75rem;
  min-width: 1.25rem;
  height: 1.25rem;
}
</style>