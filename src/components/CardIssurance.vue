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

    <!-- Batches DataTable -->
    <div class="bg-white rounded-xl shadow-lg border border-slate-200 overflow-hidden">
      <div class="p-6 border-b border-slate-200 bg-gradient-to-r from-slate-50 to-slate-100">
        <h3 class="text-lg font-semibold text-slate-900">Card Batches</h3>
      </div>
      <div class="p-6">
        <DataTable 
          :value="batches" 
          :loading="isLoading"
          class="border-0"
          :paginator="batches.length > 10"
          :rows="10"
          :rowsPerPageOptions="[5, 10, 20]"
          paginatorTemplate="RowsPerPageDropdown FirstPageLink PrevPageLink CurrentPageReport NextPageLink LastPageLink"
          currentPageReportTemplate="{first} to {last} of {totalRecords}"
          responsiveLayout="scroll"
          :globalFilterFields="['batch_name', 'batch_number']"
          :filters="filters"
          filterDisplay="menu"
        >
          <template #empty>
            <EmptyState 
              v-bind="emptyStateConfig"
              @action="handleEmptyStateAction"
            />
          </template>
          <template #header>
            <div class="flex justify-end">
              <Button 
                label="Issue New Batch" 
                icon="pi pi-plus" 
                @click="showIssueBatchDialog = true"
                v-tooltip.top="'Create a new batch of cards'"
              />
            </div>
          </template>

          <Column field="batch_name" header="Batch" sortable style="min-width:12rem">
            <template #body="{ data }">
              <div>
                <div class="font-medium text-slate-900">{{ data.batch_name }}</div>
                <div class="text-xs text-slate-500">#{{ data.batch_number }}</div>
              </div>
            </template>
          </Column>

          <Column field="cards_count" header="Cards" sortable style="min-width:8rem">
            <template #body="{ data }">
              <div class="text-center">
                <div class="font-medium text-slate-900">{{ data.cards_count }}</div>
                <div class="text-xs text-slate-500">{{ data.active_cards_count }} active</div>
              </div>
            </template>
          </Column>

          <Column field="payment_status" header="Payment" sortable style="min-width:10rem">
            <template #body="{ data }">
              <div class="flex flex-col gap-1">
                <Tag 
                  v-if="data.payment_completed" 
                  value="PAID" 
                  severity="success" 
                  class="px-2 py-1 text-xs"
                />
                <Tag 
                  v-else-if="data.payment_waived" 
                  value="WAIVED" 
                  severity="info" 
                  class="px-2 py-1 text-xs"
                />
                <Tag 
                  v-else 
                  value="PENDING" 
                  severity="warning" 
                  class="px-2 py-1 text-xs"
                />
                <div v-if="isPaymentSettled(data)" class="text-xs text-slate-500">
                  ${{ (data.cards_count * 2).toFixed(2) }}
                </div>
              </div>
            </template>
          </Column>

          <Column field="print_status" header="Print Status" style="min-width:12rem">
            <template #body="{ data }">
              <div v-if="isLoading" class="flex items-center gap-2">
                <i class="pi pi-spin pi-spinner text-slate-400 text-xs"></i>
                <span class="text-xs text-slate-500">Loading...</span>
              </div>
              <PrintRequestStatusDisplay 
                v-else
                :batch="data" 
                :print-requests="getPrintRequestsFor(data.id)"
                @request-print="openRequestPrintDialog(data)"
                @withdraw-request="confirmWithdrawPrintRequest"
              />
            </template>
          </Column>

          <Column field="created_at" header="Created" sortable style="min-width:10rem">
            <template #body="{ data }">
              <span class="text-sm text-slate-600">{{ formatDate(data.created_at) }}</span>
            </template>
          </Column>

          <Column header="Actions" :exportable="false" style="min-width:12rem">
            <template #body="{ data }">
              <div class="flex gap-2">
                <!-- Only show print request if payment is settled and no active request -->
                <Button 
                  v-if="isPaymentSettled(data) && !data.is_disabled && !hasActivePrintRequest(data.id)"
                  label="Print Request" 
                  icon="pi pi-print" 
                  severity="info" 
                  size="small"
                  @click="openRequestPrintDialog(data)"
                  v-tooltip.top="'Request printing for this batch'"
                />
                
                <!-- Payment required button - only show if payment not settled -->
                <Button 
                  v-if="!isPaymentSettled(data) && data.payment_required"
                  label="Complete Payment" 
                  icon="pi pi-credit-card" 
                  severity="warning" 
                  size="small"
                  @click="resumePayment(data)"
                  v-tooltip.top="'Complete payment to generate cards'"
                />
                
                <Button 
                  :label="data.is_disabled ? 'Enable' : 'Disable'"
                  :icon="data.is_disabled ? 'pi pi-check' : 'pi pi-times'" 
                  :severity="data.is_disabled ? 'success' : 'warning'" 
                  outlined
                  size="small"
                  @click="confirmToggleBatchStatus(data)"
                  :disabled="!isPaymentSettled(data) && data.payment_required"
                  v-tooltip.top="isPaymentSettled(data) ? (data.is_disabled ? 'Enable batch' : 'Disable batch') : 'Payment required before managing batch'"
                />
              </div>
            </template>
          </Column>
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
      :showToasts="true"
      @hide="onPrintDialogHide"
      style="width: 90vw; max-width: 500px;"
    >
      <div class="space-y-4" v-if="selectedBatchForPrinting">
        <p class="text-sm text-slate-700">
          You are about to request printing for <strong>{{ selectedBatchForPrinting.batch_name }}</strong> ({{ selectedBatchForPrinting.cards_count }} cards).
        </p>
        <div class="bg-blue-50 p-4 rounded-lg border border-blue-200">
          <div class="flex items-start gap-3">
            <i class="pi pi-info-circle text-blue-600 text-lg mt-0.5"></i>
            <div>
              <h4 class="font-semibold text-blue-900 mb-2">Physical Printing & Shipping Service</h4>
              <p class="text-sm text-blue-800 mb-3">
                Your batch payment already covers both digital card generation and physical printing. 
                This request initiates the printing and shipping process for your already-paid cards.
              </p>
              <p class="text-sm text-blue-800 mb-3">
                Our team will handle the printing and contact you with shipping details.
              </p>
              <div class="text-xs text-blue-700 bg-blue-100 p-2 rounded">
                <strong>Note:</strong> No additional payment required - your ${{ (selectedBatchForPrinting.cards_count * 2).toFixed(2) }} batch payment covers everything!
              </div>
            </div>
          </div>
        </div>

        <div class="bg-slate-50 p-3 rounded-lg border border-slate-200">
          <div class="flex items-start gap-2">
            <i class="pi pi-info-circle text-slate-600 text-sm mt-0.5"></i>
            <div class="text-xs text-slate-600">
              <p class="mb-1"><strong>Withdrawal Policy:</strong> You can withdraw print requests that are in "SUBMITTED" status.</p>
              <p>Once processing begins, withdrawal is no longer possible. Contact support if you need assistance.</p>
            </div>
          </div>
        </div>

        <!-- Shipping Address Selection -->
        <div class="space-y-4">
            <div class="flex items-center justify-between">
                <label class="block text-sm font-medium text-slate-700">
                    Select Shipping Address <span class="text-red-500">*</span>
                </label>
                <Button
                    label="Manage Addresses"
                    icon="pi pi-cog"
                    severity="secondary"
                    size="small"
                    outlined
                    @click="printRequestData.showAddressDialog = true"
                    class="text-xs"
                />
            </div>
            
            <!-- Show address selection only if addresses exist -->
            <div v-if="hasAddresses">
                <Select
                    v-model="printRequestData.selectedAddressId"
                    :options="sortedAddresses"
                    optionLabel="label"
                    optionValue="id"
                    placeholder="Choose shipping address"
                    class="w-full"
                    :class="{ 'border-red-300': printRequestForm.submitted && !printRequestData.selectedAddressId }"
                >
                    <template #option="{ option }">
                        <div class="flex flex-col py-2">
                            <div class="flex items-center justify-between mb-1">
                                <span class="font-medium text-slate-800">{{ option.label }}</span>
                                <div class="flex items-center gap-2">
                                    <Tag v-if="option.is_default" value="Default" severity="success" class="text-xs" />
                                    <i class="pi pi-map-marker text-slate-400 text-xs"></i>
                                </div>
                            </div>
                            <div class="text-sm text-slate-600">
                                <div>{{ option.recipient_name }}</div>
                                <div>{{ option.address_line1 }}</div>
                                <div>{{ option.city }}, {{ option.state_province }} {{ option.postal_code }}</div>
                            </div>
                        </div>
                    </template>
                    <template #value="{ value }">
                        <div v-if="value" class="flex items-center justify-between w-full">
                            <div class="flex items-center gap-2">
                                <i class="pi pi-map-marker text-slate-500"></i>
                                <span class="font-medium">{{ sortedAddresses.find(addr => addr.id === value)?.label }}</span>
                            </div>
                            <Tag v-if="sortedAddresses.find(addr => addr.id === value)?.is_default" 
                                 value="Default" severity="success" class="text-xs" />
                        </div>
                    </template>
                </Select>
                
                <small v-if="printRequestForm.submitted && !printRequestData.selectedAddressId"
                       class="text-red-500 text-xs flex items-center gap-1 mt-2">
                    <i class="pi pi-exclamation-circle"></i>
                    Please select a shipping address.
                </small>
            </div>

            <!-- No addresses state -->
            <div v-else class="text-center py-12">
                <div class="w-16 h-16 mx-auto bg-gradient-to-r from-slate-100 to-slate-200 rounded-full flex items-center justify-center mb-4">
                    <i class="pi pi-map-marker text-2xl text-slate-400"></i>
                </div>
                <h4 class="font-medium text-slate-800 mb-2">No addresses yet</h4>
                <p class="text-sm text-slate-600 max-w-sm mx-auto">
                    Click "Add Address" above to create your first shipping address for card printing services.
                </p>
            </div>
        </div>
      </div>
    </MyDialog>

    <!-- Shipping Address Management Dialog -->
    <Dialog
        v-model:visible="printRequestData.showAddressDialog"
        header="Manage Shipping Addresses"
        modal
        style="width: 55rem"
        class="mx-4"
        :breakpoints="{ '1199px': '75vw', '575px': '90vw' }"
    >
        <div class="space-y-6">
            <!-- Header with Add Button -->
            <div class="flex items-center justify-between pb-4 border-b border-slate-200">
                <div>
                    <h4 class="font-semibold text-slate-800 text-lg">Your Shipping Addresses</h4>
                    <p class="text-sm text-slate-600 mt-1">Manage your delivery addresses for card printing</p>
                </div>
                <Button
                    label="Add Address"
                    icon="pi pi-plus"
                    size="small"
                    @click="addressStore.startEdit()"
                    :disabled="addressStore.loading"
                    class="bg-blue-600 hover:bg-blue-700 border-blue-600 hover:border-blue-700"
                />
            </div>

            <!-- Existing Addresses -->
            <div v-if="hasAddresses" class="space-y-4">
                <div
                    v-for="address in sortedAddresses"
                    :key="address.id"
                    class="group relative border border-slate-200 rounded-xl p-5 hover:border-slate-300 hover:shadow-md transition-all duration-200"
                    :class="{ 
                        'border-blue-300 bg-gradient-to-r from-blue-50 to-indigo-50 shadow-sm': address.is_default,
                        'bg-white hover:bg-slate-50': !address.is_default 
                    }"
                >
                    <!-- Default Badge -->
                    <div v-if="address.is_default" class="absolute -top-2 -right-2">
                        <div class="bg-gradient-to-r from-blue-500 to-indigo-500 text-white px-3 py-1 rounded-full text-xs font-medium shadow-lg">
                            <i class="pi pi-star mr-1"></i>
                            Default
                        </div>
                    </div>

                    <div class="flex items-start justify-between">
                        <div class="flex-1 pr-4">
                            <!-- Address Header -->
                            <div class="flex items-center gap-3 mb-3">
                                <div class="w-10 h-10 rounded-full bg-gradient-to-r from-slate-100 to-slate-200 flex items-center justify-center">
                                    <i class="pi pi-map-marker text-slate-600"></i>
                                </div>
                                <div>
                                    <h5 class="font-semibold text-slate-800 text-lg">{{ address.label }}</h5>
                                    <p class="text-sm text-slate-500">{{ address.recipient_name }}</p>
                                </div>
                            </div>
                            
                            <!-- Address Details -->
                            <div class="ml-13 space-y-1">
                                <p class="text-sm text-slate-700 leading-relaxed">
                                    <span class="block">{{ address.address_line1 }}</span>
                                    <span v-if="address.address_line2" class="block">{{ address.address_line2 }}</span>
                                    <span class="block">{{ address.city }}, {{ address.state_province }} {{ address.postal_code }}</span>
                                    <span class="block font-medium">{{ address.country }}</span>
                                </p>
                                <p v-if="address.phone" class="text-sm text-slate-600 flex items-center gap-1 mt-2">
                                    <i class="pi pi-phone text-xs"></i>
                                    {{ address.phone }}
                                </p>
                            </div>
                        </div>

                        <!-- Action Buttons -->
                        <div class="flex flex-col gap-2 opacity-100 group-hover:opacity-100 transition-opacity">
                            <!-- Set Default Button -->
                            <Button
                                v-if="!address.is_default"
                                icon="pi pi-star"
                                severity="secondary"
                                size="small"
                                outlined
                                @click="addressStore.setDefault(address.id)"
                                v-tooltip.left="'Set as default'"
                                class="w-10 h-10 p-0 hover:bg-yellow-50 hover:border-yellow-300 hover:text-yellow-600"
                                :loading="addressStore.loading"
                            />
                            
                            <!-- Edit Button -->
                            <Button
                                icon="pi pi-pencil"
                                severity="secondary"
                                size="small"
                                outlined
                                @click="addressStore.startEdit(address.id)"
                                v-tooltip.left="'Edit address'"
                                class="w-10 h-10 p-0 hover:bg-blue-50 hover:border-blue-300 hover:text-blue-600"
                                :loading="addressStore.loading"
                            />
                            
                            <!-- Delete Button -->
                            <Button
                                icon="pi pi-trash"
                                severity="danger"
                                size="small"
                                outlined
                                @click="confirmDeleteAddress(address)"
                                v-tooltip.left="'Delete address'"
                                class="w-10 h-10 p-0 hover:bg-red-50 hover:border-red-300 hover:text-red-600"
                                :loading="addressStore.loading"
                            />
                        </div>
                    </div>
                </div>
            </div>

            <!-- Empty State -->
            <div v-else class="text-center py-12">
                <div class="w-16 h-16 mx-auto bg-gradient-to-r from-slate-100 to-slate-200 rounded-full flex items-center justify-center mb-4">
                    <i class="pi pi-map-marker text-2xl text-slate-400"></i>
                </div>
                <h4 class="font-medium text-slate-800 mb-2">No addresses yet</h4>
                <p class="text-sm text-slate-600 max-w-sm mx-auto">
                    Click "Add Address" above to create your first shipping address for card printing services.
                </p>
            </div>
        </div>

        <template #footer>
            <div class="flex justify-between items-center">
                <div class="text-sm text-slate-500">
                    {{ hasAddresses ? `${sortedAddresses.length} address${sortedAddresses.length !== 1 ? 'es' : ''}` : '' }}
                </div>
                <Button
                    label="Close"
                    severity="secondary"
                    @click="printRequestData.showAddressDialog = false"
                    outlined
                />
            </div>
        </template>
    </Dialog>

    <!-- Address Form Dialog -->
    <Dialog
        v-model:visible="addressStore.isEditMode"
        :header="addressStore.editingAddressId ? 'Edit Address' : 'Add New Address'"
        modal
        style="width: 40rem"
        class="mx-4"
    >
        <AddressForm
            :address-id="addressStore.editingAddressId"
            @saved="onAddressSaved"
            @cancelled="addressStore.cancelEdit"
        />
    </Dialog>

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
      confirmLabel="Continue to Payment"
      confirmSeverity="primary"
      successMessage="Batch created! Proceeding to payment..."
      errorMessage="Failed to create batch"
      :showToasts="true"
      @hide="onIssueBatchDialogHide"
      style="width: 90vw; max-width: 600px;"
    >
      <div class="space-y-6">
        <div class="bg-blue-50 p-4 rounded-lg border border-blue-200">
          <div class="flex items-start gap-3">
            <i class="pi pi-info-circle text-blue-600 text-lg mt-0.5"></i>
            <div>
              <h4 class="font-semibold text-blue-900 mb-2">Payment Required</h4>
              <p class="text-sm text-blue-800">
                Card issuance requires payment of <strong>$2 USD per card</strong> before cards are generated.
                After payment confirmation, your cards will be immediately available for distribution.
              </p>
            </div>
          </div>
        </div>

        <div>
          <label class="block text-sm font-medium text-slate-700 mb-2">Number of Cards</label>
          <InputNumber 
            v-model="batchForm.quantity" 
            :min="1" 
            :max="1000"
            class="w-full"
            placeholder="Enter number of cards to issue"
            @update:modelValue="updateCostCalculation"
          />
           <small v-if="batchForm.errors.quantity" class="p-error">{{ batchForm.errors.quantity }}</small>
        </div>

        <!-- Cost Summary -->
        <div v-if="batchForm.quantity > 0" class="bg-slate-50 p-4 rounded-lg border border-slate-200">
          <h4 class="font-semibold text-slate-900 mb-3">Cost Summary</h4>
          <div class="space-y-2 text-sm">
            <div class="flex justify-between">
              <span class="text-slate-600">{{ batchForm.quantity }} cards × $2.00 USD</span>
              <span class="font-medium">{{ costCalculation.totalFormatted }}</span>
            </div>
            <div class="border-t border-slate-300 pt-2 mt-2">
              <div class="flex justify-between font-semibold">
                <span>Total</span>
                <span class="text-blue-600">{{ costCalculation.totalFormatted }}</span>
              </div>
            </div>
          </div>
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

    <!-- Payment Dialog -->
    <MyDialog
      v-model="showPaymentDialog"
      header="Complete Payment"
      :showConfirm="false"
      :showCancel="false"
      @hide="onPaymentDialogHide"
      style="width: 90vw; max-width: 500px;"
    >
      <div class="space-y-6" v-if="pendingBatch">
        <!-- Payment Summary -->
        <div class="bg-slate-50 p-4 rounded-lg border border-slate-200">
          <h4 class="font-semibold text-slate-900 mb-3">Payment Details</h4>
          <div class="space-y-2 text-sm">
            <div class="flex justify-between">
              <span class="text-slate-600">Batch:</span>
              <span class="font-medium">{{ pendingBatch.batch_name }}</span>
            </div>
            <div class="flex justify-between">
              <span class="text-slate-600">Cards:</span>
              <span class="font-medium">{{ pendingBatch.cards_count }}</span>
            </div>
            <div class="flex justify-between">
              <span class="text-slate-600">Amount:</span>
              <span class="font-medium text-blue-600">{{ formatAmount(pendingBatch.payment_amount_cents) }}</span>
            </div>
          </div>
        </div>

        <!-- Payment Form -->
        <div>
          <label class="block text-sm font-medium text-slate-700 mb-3">Payment Information</label>
          <div id="stripe-payment-element" class="mb-4"></div>
        </div>

        <!-- Payment Status -->
        <div v-if="paymentStatus.processing" class="text-center py-4">
          <div class="inline-flex items-center gap-2 text-blue-600">
            <i class="pi pi-spin pi-spinner"></i>
            <span>Processing payment...</span>
          </div>
        </div>

        <div v-if="paymentStatus.error" class="bg-red-50 p-4 rounded-lg border border-red-200">
          <div class="flex items-start gap-3">
            <i class="pi pi-exclamation-triangle text-red-600 text-lg mt-0.5"></i>
            <div>
              <h4 class="font-semibold text-red-900 mb-1">Payment Failed</h4>
              <p class="text-sm text-red-800">{{ paymentStatus.error }}</p>
            </div>
          </div>
        </div>

        <!-- Action Buttons -->
        <div class="flex gap-3 pt-4">
          <Button 
            label="Pay Now" 
            icon="pi pi-credit-card"
            severity="primary"
            class="flex-1"
            :loading="paymentStatus.processing"
            :disabled="!stripePaymentElement || paymentStatus.processing"
            @click="handlePayment"
          />
          <Button 
            label="Cancel" 
            severity="secondary"
            outlined
            :disabled="paymentStatus.processing"
            @click="cancelPayment"
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
    <ConfirmDialog group="toggleBatchConfirmation"></ConfirmDialog>
    <ConfirmDialog group="requestPrintConfirmation"></ConfirmDialog>
    <ConfirmDialog group="deleteIssuedCardConfirmation"></ConfirmDialog>
    <ConfirmDialog group="deleteAddressConfirmation"></ConfirmDialog>
    <ConfirmDialog group="withdrawPrintRequestConfirmation"></ConfirmDialog>

    <!-- New section for print request statistics -->
    <div class="mb-6">
      <h3 class="text-lg font-semibold text-slate-900 mb-4 flex items-center gap-2">
        <i class="pi pi-box text-blue-600"></i>
        Card Batches & Print Requests
      </h3>
      
      <!-- Print Request Summary -->
      <div class="grid grid-cols-1 md:grid-cols-4 gap-4 mb-6">
        <div class="bg-gradient-to-r from-blue-50 to-indigo-50 border border-blue-200 rounded-lg p-4">
          <div class="flex items-center justify-between">
            <div>
              <p class="text-sm font-medium text-blue-900">Total Batches</p>
              <p class="text-2xl font-bold text-blue-700">{{ batches.length }}</p>
            </div>
            <i class="pi pi-box text-blue-600 text-2xl"></i>
          </div>
        </div>
        
        <div class="bg-gradient-to-r from-green-50 to-emerald-50 border border-green-200 rounded-lg p-4">
          <div class="flex items-center justify-between">
            <div>
              <p class="text-sm font-medium text-green-900">Active Requests</p>
              <p class="text-2xl font-bold text-green-700">{{ activePrintRequestsCount }}</p>
            </div>
            <i class="pi pi-print text-green-600 text-2xl"></i>
          </div>
        </div>
        
        <div class="bg-gradient-to-r from-purple-50 to-violet-50 border border-purple-200 rounded-lg p-4">
          <div class="flex items-center justify-between">
            <div>
              <p class="text-sm font-medium text-purple-900">Completed</p>
              <p class="text-2xl font-bold text-purple-700">{{ completedPrintRequestsCount }}</p>
            </div>
            <i class="pi pi-check-circle text-purple-600 text-2xl"></i>
          </div>
        </div>
        
        <div class="bg-gradient-to-r from-amber-50 to-yellow-50 border border-amber-200 rounded-lg p-4">
          <div class="flex items-center justify-between">
            <div>
              <p class="text-sm font-medium text-amber-900">Available</p>
              <p class="text-2xl font-bold text-amber-700">{{ availableForPrintCount }}</p>
            </div>
            <i class="pi pi-plus-circle text-amber-600 text-2xl"></i>
          </div>
        </div>
      </div>

      <!-- Batch Management Table -->
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, computed, watch, onUnmounted } from 'vue';
import { useToast } from 'primevue/usetoast';
import { useConfirm } from 'primevue/useconfirm';
import { useIssuedCardStore, PrintRequestStatus } from '@/stores/issuedCard';
import QrcodeVue from 'qrcode.vue';
import { FilterMatchMode } from '@primevue/core/api';
import { getStripe, createBatchPaymentIntent, confirmBatchPayment, formatAmount, calculateBatchCost } from '@/utils/stripe';
import { useCardStore } from '@/stores/card';
import { useShippingAddressStore } from '@/stores/shippingAddress';

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
import AddressForm from './AddressForm.vue';
import PrintRequestStatusDisplay from './PrintRequestStatusDisplay.vue';
import EmptyState from './EmptyState.vue';
import { getEmptyStateConfig } from '@/utils/emptyStateConfigs.js';

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
const cardStore = useCardStore();
const addressStore = useShippingAddressStore();

// Reactive data
const showIssueBatchDialog = ref(false);
const showPaymentDialog = ref(false);
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

// Payment-related state
const pendingBatch = ref(null);
const stripePaymentElement = ref(null);
const stripeElements = ref(null);
const currentPaymentIntent = ref(null);
const paymentStatus = ref({
  processing: false,
  error: null,
  success: false
});

// Cost calculation
const costCalculation = ref(calculateBatchCost(10));

// Update cost calculation when quantity changes
const updateCostCalculation = () => {
  if (batchForm.value.quantity > 0) {
    costCalculation.value = calculateBatchCost(batchForm.value.quantity);
  }
};

// Filters for Individual Issued Cards table
const filters = ref({
  global: { value: null, matchMode: FilterMatchMode.CONTAINS },
  id: { value: null, matchMode: FilterMatchMode.CONTAINS },
  batch_name: { value: null, matchMode: FilterMatchMode.EQUALS },
  active: { value: null, matchMode: FilterMatchMode.EQUALS }
});

// For Batch Management Table
const showRequestPrintDialog = ref(false);
const selectedBatchForPrinting = ref(null);
const printRequestForm = ref({
  shippingAddress: '',
  submitted: false, // To track if form submission was attempted for validation
});

// Print request data
const printRequestData = ref({
    batchId: '',
    selectedAddressId: '', // Changed from manual address to address selection
    showAddressDialog: false
});

// Computed properties
const isLoading = computed(() => issuedCardStore.isLoading);
const issuedCards = computed(() => issuedCardStore.issuedCards);
const batches = computed(() => issuedCardStore.batches);
const stats = computed(() => issuedCardStore.stats);
const printRequestsForBatchMap = computed(() => issuedCardStore.printRequestsForBatch);

// Get current card data from cardStore
const currentCard = computed(() => {
  return cardStore.cards.find(card => card.id === props.cardId) || null;
});

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

// Empty state configuration for card batches
const emptyStateConfig = computed(() => {
  return getEmptyStateConfig('cardBatches', 'noData', {
    buttonLabel: 'Issue New Batch',
    buttonIcon: 'pi pi-send'
  });
});

const statusOptions = computed(() => [
  { label: 'All', value: null },
  { label: 'Active', value: true },
  { label: 'Pending', value: false }
]);

const getPrintRequestsFor = (batchId) => {
  return printRequestsForBatchMap.value[batchId] || [];
};

// Computed properties for print request statistics
const activePrintRequestsCount = computed(() => {
  return batches.value.reduce((count, batch) => {
    const requests = getPrintRequestsFor(batch.id);
    const activeRequests = requests.filter(pr => !['COMPLETED', 'CANCELLED'].includes(pr.status));
    return count + activeRequests.length;
  }, 0);
});

const completedPrintRequestsCount = computed(() => {
  return batches.value.reduce((count, batch) => {
    const requests = getPrintRequestsFor(batch.id);
    const completedRequests = requests.filter(pr => pr.status === 'COMPLETED');
    return count + completedRequests.length;
  }, 0);
});

const availableForPrintCount = computed(() => {
  return batches.value.filter(batch => 
    isPaymentSettled(batch) && 
    !batch.is_disabled && 
    !hasActivePrintRequest(batch.id)
  ).length;
});

const hasActivePrintRequest = (batchId) => {
  const requests = getPrintRequestsFor(batchId);
  return requests.some(pr => ![PrintRequestStatus.COMPLETED, PrintRequestStatus.CANCELLED].includes(pr.status));
};

// Helper function to check if payment is settled (completed or waived)
const isPaymentSettled = (batch) => {
  return batch.payment_completed || batch.payment_waived;
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

// Handle empty state action
const handleEmptyStateAction = () => {
  showIssueBatchDialog.value = true;
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

// Handle issue batch - now creates batch and proceeds to payment
const handleIssueBatch = async () => {
  if (!validateBatchForm()) {
    if (!batchForm.value.errors.quantity && batchForm.value.quantity && (batchForm.value.quantity < 1 || batchForm.value.quantity > 1000)) {
        batchForm.value.errors.quantity = 'Quantity must be between 1 and 1000.';
    }
    throw new Error('Validation failed');
  }

  if (!props.cardId) {
    throw new Error('No card selected for batch issuance.');
  }

  try {
    // Create batch (without cards - they'll be created after payment)
    const batchId = await issuedCardStore.issueBatch(props.cardId, batchForm.value.quantity);
    
    // Fetch the created batch details
    await issuedCardStore.loadCardData(props.cardId);
    const createdBatch = Array.isArray(batches.value) ? batches.value.find(b => b.id === batchId) : null;
    
    if (!createdBatch) {
      throw new Error('Failed to retrieve created batch details');
    }
    
    pendingBatch.value = createdBatch;
    
    // Close batch dialog and open payment dialog
    showIssueBatchDialog.value = false;
    showPaymentDialog.value = true;
    
    // Initialize payment
    await initializePayment();
    
  } catch (error) {
    console.error('Error creating batch:', error);
    const errorMessage = error.message || 'Failed to create card batch';
    throw new Error(errorMessage);
  }
};

// Initialize Stripe payment
const initializePayment = async () => {
  if (!pendingBatch.value) return;
  
  try {
    paymentStatus.value.processing = true;
    paymentStatus.value.error = null;
    
    // Create payment intent
    const paymentIntent = await createBatchPaymentIntent(
      pendingBatch.value.cards_count,
      {
        batch_id: pendingBatch.value.id,
        card_id: props.cardId
      }
    );
    
    currentPaymentIntent.value = paymentIntent;
    
    // Store payment intent in database
    await issuedCardStore.createBatchPaymentIntent(
      pendingBatch.value.id,
      paymentIntent.id,
      paymentIntent.client_secret,
      paymentIntent.amount
    );
    
    // Initialize Stripe Elements
    const stripe = getStripe();
    stripeElements.value = stripe.elements();
    
    // Create and mount payment element
    stripePaymentElement.value = stripeElements.value.create('payment');
    
    // Wait for DOM to update
    await new Promise(resolve => setTimeout(resolve, 100));
    
    stripePaymentElement.value.mount('#stripe-payment-element');
    
    stripePaymentElement.value.on('ready', () => {
      paymentStatus.value.processing = false;
    });
    
  } catch (error) {
    console.error('Error initializing payment:', error);
    paymentStatus.value.error = error.message || 'Failed to initialize payment';
    paymentStatus.value.processing = false;
  }
};

// Handle payment submission
const handlePayment = async () => {
  if (!currentPaymentIntent.value || !stripePaymentElement.value) {
    paymentStatus.value.error = 'Payment not properly initialized';
    return;
  }

  paymentStatus.value.processing = true;
  paymentStatus.value.error = null;
  
  try {
    // Confirm payment with Stripe
    const result = await confirmBatchPayment(currentPaymentIntent.value.client_secret);
    
    if (result.error) {
      // Payment failed
      await issuedCardStore.handleFailedBatchPayment(
        currentPaymentIntent.value.id,
        result.error.message
      );
      
      paymentStatus.value.error = result.error.message;
      paymentStatus.value.processing = false;
      return;
    }
    
    // Payment succeeded - confirm in database and create cards
    await issuedCardStore.confirmBatchPayment(
      currentPaymentIntent.value.id,
      result.paymentIntent.payment_method?.card?.brand || 'card'
    );
    
    // Refresh data
    await issuedCardStore.loadCardData(props.cardId);
    
    toast.add({ 
      severity: 'success', 
      summary: 'Payment Successful', 
      detail: `Batch created with ${pendingBatch.value.cards_count} cards!`, 
      life: 5000 
    });

    // Close payment dialog
    showPaymentDialog.value = false;
    resetPaymentState();
    
    // Reset batch form
    batchForm.value.quantity = 10;
    batchForm.value.description = '';
    updateCostCalculation();
    
  } catch (error) {
    console.error('Error processing payment:', error);
    paymentStatus.value.error = error.message || 'Payment processing failed';
  } finally {
    paymentStatus.value.processing = false;
  }
};

// Cancel payment
const cancelPayment = () => {
  showPaymentDialog.value = false;
  resetPaymentState();
  
    toast.add({ 
    severity: 'info', 
    summary: 'Payment Cancelled', 
    detail: 'Batch creation was cancelled. No payment was processed.', 
    life: 3000 
    });
};

// Reset payment state
const resetPaymentState = () => {
  if (stripePaymentElement.value) {
    stripePaymentElement.value.unmount();
    stripePaymentElement.value = null;
  }
  stripeElements.value = null;
  currentPaymentIntent.value = null;
  pendingBatch.value = null;
  paymentStatus.value = {
    processing: false,
    error: null,
    success: false
  };
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
    group: 'deleteIssuedCardConfirmation',
    message: `Are you sure you want to delete issued card record ID "${card.id.substring(0, 8)}..."? This refers to a single instance of an issued card, not the card design itself. This action cannot be undone.`,
    header: 'Confirm Issued Card Deletion',
    icon: 'pi pi-exclamation-triangle',
    acceptLabel: 'Delete Issued Card',
    rejectLabel: 'Cancel',
    acceptClass: 'p-button-danger',
    accept: async () => {
      try {
        await issuedCardStore.deleteIssuedCard(card.id, props.cardId);
        toast.add({ severity: 'success', summary: 'Deleted', detail: `Issued card record deleted successfully.`, life: 3000 });
        // No need to call fetchIssuedCards here as deleteIssuedCard should update the store reactively
        // or it should be handled by a watcher if necessary.
      } catch (error) {
        console.error('Failed to delete issued card:', error);
        toast.add({ severity: 'error', summary: 'Error', detail: 'Failed to delete issued card.', life: 3000 });
      }
    },
    reject: () => {
      toast.add({ severity: 'info', summary: 'Cancelled', detail: 'Issued card deletion cancelled.', life: 3000 });
    }
  });
};

// Dialog hide handlers
const onIssueBatchDialogHide = () => {
  batchForm.value.quantity = 10;
  batchForm.value.description = '';
  batchForm.value.errors = { quantity: '' };
  updateCostCalculation();
  showIssueBatchDialog.value = false;
};

const onPaymentDialogHide = () => {
  resetPaymentState();
  showPaymentDialog.value = false;
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

const openRequestPrintDialog = async (batch) => {
    if (batch.is_disabled || hasActivePrintRequest(batch.id)) {
        toast.add({ 
            severity: 'warn', 
            summary: 'Cannot Request Print', 
            detail: batch.is_disabled ? 'Batch is disabled.' : 'An active print request already exists.', 
            life: 3000 
        });
        return;
    }

    // Load shipping addresses first
    await addressStore.fetchAddresses();

    selectedBatchForPrinting.value = batch;
    printRequestForm.value.shippingAddress = ''; // Reset form
    printRequestForm.value.submitted = false;
    
    // Auto-select default address if available
    autoSelectDefaultAddress();
    
    // Always show the print dialog first
    showRequestPrintDialog.value = true;
};

const handleRequestPrint = async () => {
    printRequestForm.value.submitted = true;
    
    // Validate address selection
    if (!printRequestData.value.selectedAddressId) {
        toast.add({
            severity: 'error',
            summary: 'Address Required',
            detail: 'Please select a shipping address.',
            life: 3000
        });
        return false;
    }
    
    if (!selectedBatchForPrinting.value) {
        return false;
    }
    
    try {
        // Get formatted address for the request
        const formattedAddress = await addressStore.getFormattedAddress(printRequestData.value.selectedAddressId);
        
        await issuedCardStore.requestPrintForBatch(selectedBatchForPrinting.value.id, formattedAddress);
        
        // The store action fetchPrintRequestsForBatch should update the data.
        return true;
    } catch (error) {
        console.error('Error requesting print:', error);
        throw new Error(error.message || 'Failed to submit print request.');
    }
};

const onPrintDialogHide = () => {
  showRequestPrintDialog.value = false;
  selectedBatchForPrinting.value = null;
  printRequestForm.value.shippingAddress = '';
  printRequestForm.value.submitted = false;
};

const confirmWithdrawPrintRequest = (printRequest, batch) => {
  confirm.require({
    group: 'withdrawPrintRequestConfirmation',
    message: `Are you sure you want to withdraw the print request for "${batch.batch_name}"? This action cannot be undone and you'll need to submit a new request if you want to print these cards later.`,
    header: 'Withdraw Print Request',
    icon: 'pi pi-exclamation-triangle',
    acceptLabel: 'Withdraw Request',
    rejectLabel: 'Keep Request',
    acceptClass: 'p-button-danger',
    accept: async () => {
      try {
        await issuedCardStore.withdrawPrintRequest(printRequest.id, 'Withdrawn by card issuer');
        
        // Refresh print requests for this batch
        await issuedCardStore.fetchPrintRequestsForBatch(batch.id);
        
        toast.add({ 
          severity: 'success', 
          summary: 'Request Withdrawn', 
          detail: `Print request for ${batch.batch_name} has been withdrawn successfully.`, 
          life: 5000 
        });
      } catch (error) {
        console.error('Failed to withdraw print request:', error);
        toast.add({ 
          severity: 'error', 
          summary: 'Withdrawal Failed', 
          detail: error.message || 'Failed to withdraw print request.', 
          life: 5000 
        });
      }
    },
    reject: () => {
      toast.add({ 
        severity: 'info', 
        summary: 'Withdrawal Cancelled', 
        detail: 'Print request withdrawal was cancelled.', 
        life: 3000 
      });
    }
  });
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

// Resume payment for an existing batch
const resumePayment = async (batch) => {
  try {
    // Check if payment is already settled (completed or waived)
    if (isPaymentSettled(batch)) {
      const settlementType = batch.payment_completed ? 'paid for' : 'waived by admin';
      toast.add({ 
        severity: 'info', 
        summary: 'Payment Already Settled', 
        detail: `This batch has already been ${settlementType}.`, 
        life: 3000 
      });
      return;
    }
    
    // Check if batch already has payment info
    const paymentInfo = await issuedCardStore.getBatchPaymentInfo(batch.id);
    
    if (paymentInfo && paymentInfo.payment_status === 'succeeded') {
      toast.add({ 
        severity: 'info', 
        summary: 'Already Paid', 
        detail: 'This batch has already been paid for.', 
        life: 3000 
      });
      return;
    }
    
    // Set as pending batch and open payment dialog
    pendingBatch.value = batch;
    showPaymentDialog.value = true;
    
    if (paymentInfo && paymentInfo.payment_status === 'pending') {
      // Use existing payment intent
      currentPaymentIntent.value = {
        id: paymentInfo.stripe_payment_intent_id,
        client_secret: paymentInfo.stripe_client_secret,
        amount: paymentInfo.amount_cents
      };
      
      // Initialize Stripe Elements with existing intent
      const stripe = getStripe();
      stripeElements.value = stripe.elements();
      stripePaymentElement.value = stripeElements.value.create('payment');
      
      await new Promise(resolve => setTimeout(resolve, 100));
      stripePaymentElement.value.mount('#stripe-payment-element');
      
    } else {
      // Create new payment intent
      await initializePayment();
    }
    
  } catch (error) {
    console.error('Error resuming payment:', error);
    toast.add({ 
      severity: 'error', 
      summary: 'Error', 
      detail: error.message || 'Failed to resume payment process', 
      life: 3000 
    });
  }
};

// Computed properties for address management
const hasAddresses = computed(() => addressStore.hasAddresses);
const defaultAddress = computed(() => addressStore.defaultAddress);
const sortedAddresses = computed(() => addressStore.sortedAddresses);

// Auto-select default address if available
const autoSelectDefaultAddress = () => {
    if (defaultAddress.value) {
        printRequestData.value.selectedAddressId = defaultAddress.value.id;
    }
};

// Address management functions
const confirmDeleteAddress = (address) => {
    confirm.require({
        group: 'deleteAddressConfirmation',
        message: `Are you sure you want to delete "${address.label}"?`,
        header: 'Delete Shipping Address',
        icon: 'pi pi-exclamation-triangle',
        rejectProps: {
            label: 'Cancel',
            severity: 'secondary',
            outlined: true
        },
        acceptProps: {
            label: 'Delete',
            severity: 'danger'
        },
        accept: async () => {
            try {
                await addressStore.deleteAddress(address.id);
                // Auto-select default address after deletion
                autoSelectDefaultAddress();
                toast.add({
                    severity: 'success',
                    summary: 'Address Deleted',
                    detail: `"${address.label}" has been removed from your addresses.`,
                    life: 3000
                });
            } catch (error) {
                // Error handling is done in the store, but we can add a fallback
                console.error('Failed to delete address:', error);
            }
        }
    });
};

const onAddressSaved = async () => {
    // Refresh addresses and auto-select default
    await addressStore.fetchAddresses();
    autoSelectDefaultAddress();
    
    // Close address dialog if no addresses were available before
    if (hasAddresses.value && printRequestData.value.showAddressDialog) {
        printRequestData.value.showAddressDialog = false;
    }
};

// Lifecycle hooks
onMounted(async () => {
    await Promise.all([
        issuedCardStore.loadCardData(props.cardId),
        addressStore.fetchAddresses()
    ]);
    autoSelectDefaultAddress();
});

onUnmounted(() => {
  // Clean up Stripe elements
  resetPaymentState();
});
</script>

<style scoped>
/* Component-specific styles - global table theme now handles standard styling */
:deep(.p-card .p-card-content) {
  padding: 0;
}

/* Custom badge sizing for this component */
:deep(.p-badge) {
  min-width: 1.25rem;
  height: 1.25rem;
}

/* Stripe payment specific styles */
.stripe-elements {
  transition: all 0.2s ease-in-out;
}
</style>