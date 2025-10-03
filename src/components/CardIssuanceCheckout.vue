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
            <p class="text-sm text-blue-600 mt-1">{{ stats.total_activated }} active</p>
          </div>
          <div class="p-4 bg-gradient-to-r from-blue-500 to-blue-600 rounded-xl">
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

    <!-- Print Ready Banner -->
    <div v-if="readyToPrintBatches.length > 0" class="bg-gradient-to-r from-blue-50 to-purple-50 rounded-xl shadow-soft border border-blue-200 p-6">
      <div class="flex items-center gap-4">
        <div class="p-3 bg-gradient-to-r from-blue-500 to-purple-500 rounded-xl">
          <i class="pi pi-print text-white text-2xl"></i>
        </div>
        <div class="flex-1">
          <h3 class="text-lg font-semibold text-slate-900 mb-2">
            {{ readyToPrintBatches.length }} batch{{ readyToPrintBatches.length > 1 ? 'es' : '' }} ready for physical printing
          </h3>
          <div class="space-y-1">
            <p class="text-slate-700 text-sm font-medium">
              👉 To order physical cards:
            </p>
            <ol class="text-slate-600 text-sm ml-6 space-y-0.5">
              <li>1. Find your batch in the table below</li>
              <li>2. Look for the <span class="inline-flex items-center gap-1 px-2 py-0.5 bg-blue-100 text-blue-700 rounded text-xs font-medium"><i class="pi pi-print text-xs"></i> Print</span> button in the Actions column</li>
              <li>3. Click it to submit your print request</li>
            </ol>
          </div>
        </div>
      </div>
    </div>

    <!-- Batches DataTable -->
    <div class="bg-white rounded-xl shadow-lg border border-slate-200 overflow-hidden">
      <div class="p-6 border-b border-slate-200 bg-gradient-to-r from-slate-50 to-slate-100">
        <div class="flex justify-between items-center">
          <h3 class="text-lg font-semibold text-slate-900">Card Batches</h3>
          <Button 
            label="Issue New Batch" 
            icon="pi pi-plus"
            @click="showCreateBatchDialog = true"
            class="bg-gradient-to-r from-blue-600 to-purple-600 hover:from-blue-700 hover:to-purple-700 border-0"
          />
        </div>
      </div>
      <div class="p-6">
        <DataTable 
          :value="batches" 
          :loading="loadingBatches"
          :paginator="true" 
          :rows="10"
          :rowsPerPageOptions="[10, 25, 50]"
          responsiveLayout="scroll"
          paginatorTemplate="RowsPerPageDropdown FirstPageLink PrevPageLink CurrentPageReport NextPageLink LastPageLink"
          currentPageReportTemplate="{first} to {last} of {totalRecords}"
          class="w-full"
        >
          <Column field="batch_name" header="Batch" :sortable="true" style="min-width:160px">
            <template #body="{ data }">
              <div>
                <div class="text-sm font-medium text-slate-900 mb-1">{{ data.batch_name }}</div>
                
                <!-- Simple Progress Status -->
                <div class="text-xs text-slate-600">
                  {{ getBatchProgressText(data) }}
                </div>
              </div>
            </template>
          </Column>

          <Column field="cards_count" header="Cards" :sortable="true" style="width:100px">
            <template #body="{ data }">
              <div class="text-center">
                <span class="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
                  {{ data.cards_count }}
                </span>
              </div>
            </template>
          </Column>

          <Column field="payment_status" header="Payment" :sortable="true" style="width:120px">
            <template #body="{ data }">
              <div class="text-center">
                <span :class="getPaymentStatusClass(data.payment_status)">
                  {{ formatPaymentStatus(data.payment_status) }}
                </span>
              </div>
            </template>
          </Column>

          <Column field="total_amount" header="Amount" :sortable="true" style="width:100px">
            <template #body="{ data }">
              <div class="text-right text-sm font-medium" :class="data.payment_status === 'free' ? 'text-slate-600' : 'text-slate-900'">
                {{ data.payment_status === 'free' ? '-' : `$${(data.total_amount / 100).toFixed(2)}` }}
              </div>
            </template>
          </Column>

          <Column field="created_at" header="Created" :sortable="true" style="width:140px">
            <template #body="{ data }">
              <div class="text-xs text-slate-600">
                {{ formatDate(data.created_at) }}
              </div>
            </template>
          </Column>


          <Column header="Actions" style="width:180px">
            <template #body="{ data }">
              <div class="flex items-center gap-1">
                <!-- Primary Action: Print (for paid and admin-issued batches) -->
                <Button 
                  v-if="(data.payment_status === 'completed' || data.payment_status === 'free') && data.cards_generated && !data.has_print_request"
                  label="Print" 
                  icon="pi pi-print"
                  size="small"
                  @click="requestPrint(data)"
                  class="bg-gradient-to-r from-blue-600 to-purple-600 hover:from-blue-700 hover:to-purple-700 border-0 font-medium shadow-md hover:shadow-lg transition-all duration-200 animate-pulse"
                  v-tooltip.top="'Request physical cards'"
                />
                
                <!-- Color buttons first -->
                <Button 
                  v-if="(data.payment_status === 'completed' || data.payment_status === 'free') && data.cards_generated && data.has_print_request"
                  icon="pi pi-truck" 
                  size="small"
                  @click="viewPrintRequestDialog(data)"
                  :loading="loadingPrintStatusBatchId === data.id"
                  :class="[
                    'bg-gradient-to-r from-blue-500 to-blue-600 hover:from-blue-600 hover:to-blue-700 text-white border-0 shadow-md hover:shadow-lg transition-all duration-200',
                    data.print_request_status !== 'COMPLETED' ? 'animate-pulse' : ''
                  ]"
                  v-tooltip.top="'Print Status'"
                />
                
                <!-- Outlined buttons after -->
                <Button 
                  v-if="data.payment_status === 'completed' || data.payment_status === 'free'"
                  icon="pi pi-eye" 
                  size="small"
                  outlined
                  @click="viewBatchCards(data)"
                  class="border-blue-600 text-blue-600 hover:bg-blue-50"
                  v-tooltip.top="'View Cards'"
                />
                
                <!-- Details button always visible -->
                <Button 
                  icon="pi pi-ellipsis-v" 
                  size="small"
                  outlined
                  @click="viewBatchDetails(data)"
                  class="border-slate-600 text-slate-600 hover:bg-slate-50"
                  v-tooltip.top="'Details'"
                />
              </div>
            </template>
          </Column>
        </DataTable>
      </div>
    </div>

    <!-- Create Batch Dialog -->
    <Dialog 
      v-model:visible="showCreateBatchDialog" 
      modal 
      header="Issue New Card Batch" 
      :style="{ width: '500px' }"
      class="standardized-dialog"
      appendTo="body"
    >
      <div class="space-y-6">
        <div>
          <label class="block text-sm font-medium text-slate-700 mb-2">Number of Cards</label>
          <InputNumber 
            v-model="newBatch.cardCount"
            :min="1"
            :max="1000"
            placeholder="Enter number of cards"
            class="w-full"
          />
          <small class="text-slate-500 mt-1">
            Cost: ${{ ((newBatch.cardCount || 0) * 2).toFixed(2) }} ($2.00 per card)
          </small>
        </div>

        <div>
          <label class="block text-sm font-medium text-slate-700 mb-2">Card Design</label>
          <div v-if="currentCard" class="flex items-center gap-3 p-3 border border-slate-200 rounded-lg bg-slate-50">
            <div class="relative w-12 h-16 flex-shrink-0">
              <img 
                :src="currentCard.image_url || cardPlaceholder" 
                :alt="currentCard.title || 'Card design'"
                class="w-full h-full object-cover rounded border border-slate-200"
                @error="handleImageError"
                @load="handleImageLoad"
              />
              <div v-if="!currentCard.image_url" class="absolute inset-0 flex items-center justify-center bg-slate-100 rounded text-slate-400 text-xs">
                <i class="pi pi-image"></i>
              </div>
            </div>
            <div class="flex-1 min-w-0">
              <div class="font-medium text-slate-900 truncate">{{ currentCard.title || currentCard.name || 'Untitled Card' }}</div>
              <div class="text-sm text-slate-600 line-clamp-2">{{ currentCard.description || 'No description available' }}</div>
            </div>
          </div>
          <div v-else class="p-3 border border-slate-200 rounded-lg bg-slate-50 text-slate-500">
            Loading card information...
          </div>
        </div>

        <div class="bg-blue-50 border border-blue-200 rounded-lg p-4">
          <h4 class="font-medium text-blue-900 mb-2">What happens next?</h4>
          <ul class="text-sm text-blue-800 space-y-1">
            <li>• You'll be redirected to Stripe Checkout for secure payment</li>
            <li>• Batch will be created automatically after successful payment</li>
            <li>• Cards will be generated and ready for distribution</li>
            <li>• You can then distribute QR codes to your visitors</li>
          </ul>
        </div>
      </div>

      <template #footer>
        <div class="flex gap-3 justify-end">
          <Button 
            label="Cancel" 
            outlined 
            @click="showCreateBatchDialog = false"
          />
          <Button 
            label="Pay & Issue" 
            @click="createBatch"
            :loading="creatingBatch"
            :disabled="!newBatch.cardCount || !currentCard"
            class="bg-gradient-to-r from-blue-600 to-purple-600 hover:from-blue-700 hover:to-purple-700 border-0"
          />
        </div>
      </template>
    </Dialog>

    <!-- Success Message -->
    <div v-if="showSuccessMessage" class="fixed inset-0 z-50 flex items-center justify-center bg-black bg-opacity-50">
      <div class="bg-white rounded-xl shadow-2xl p-8 max-w-lg mx-4">
        <div class="text-center">
          <div class="w-16 h-16 bg-blue-100 rounded-full flex items-center justify-center mx-auto mb-4">
            <i class="pi pi-check text-blue-600 text-2xl"></i>
          </div>
          <h3 class="text-xl font-semibold text-slate-900 mb-2">Payment Successful!</h3>
          <p class="text-slate-600 mb-6">
            Your digital cards have been generated and are ready for distribution.
          </p>
          
          <!-- Next Steps -->
          <div class="bg-blue-50 border border-blue-200 rounded-lg p-4 mb-6 text-left">
            <h4 class="font-semibold text-blue-900 mb-3 flex items-center gap-2">
              <i class="pi pi-lightbulb text-blue-600"></i>
              What's Next?
            </h4>
            <div class="space-y-2 text-sm text-blue-800">
              <div class="flex items-center gap-2">
                <i class="pi pi-check text-blue-600"></i>
                <span>✓ Digital cards are live and scannable</span>
              </div>
              <div class="flex items-center gap-2">
                <i class="pi pi-print text-purple-600"></i>
                <span class="font-medium">Request physical card printing for visitors</span>
              </div>
              <div class="flex items-center gap-2">
                <i class="pi pi-share-alt text-blue-600"></i>
                <span>Download QR codes to share with your audience</span>
              </div>
            </div>
          </div>
          
          <div class="flex gap-3 justify-center">
            <Button 
              label="Request Print" 
              icon="pi pi-print"
              @click="handleSuccessPrintRequest"
              class="bg-gradient-to-r from-blue-600 to-purple-600 hover:from-blue-700 hover:to-purple-700 border-0 font-medium"
            />
            <Button 
              label="View Cards" 
              outlined
              @click="closeSuccessMessage"
              class="border-blue-600 text-blue-600 hover:bg-blue-50"
            />
          </div>
        </div>
      </div>
    </div>

    <!-- Batch Details Dialog -->
    <Dialog 
      v-model:visible="showBatchDetailsDialog" 
      modal 
      header="Batch Details" 
      :style="{ width: '600px' }"
      class="standardized-dialog"
      appendTo="body"
    >
      <div v-if="loadingBatchDetails" class="flex items-center justify-center py-12">
        <i class="pi pi-spin pi-spinner text-4xl text-blue-600"></i>
      </div>
      <div v-else-if="selectedBatch" class="space-y-6">
        <!-- Batch Info -->
        <div class="grid grid-cols-2 gap-4">
          <div>
            <label class="text-sm font-medium text-slate-600">Batch Name</label>
            <p class="text-lg font-semibold text-slate-900">{{ selectedBatch.batch_name }}</p>
          </div>
          <div>
            <label class="text-sm font-medium text-slate-600">Batch Number</label>
            <p class="text-lg font-semibold text-slate-900">#{{ selectedBatch.batch_number }}</p>
          </div>
        </div>

        <!-- Cards Info -->
        <div class="grid grid-cols-2 gap-4">
          <div>
            <label class="text-sm font-medium text-slate-600">Total Cards</label>
            <p class="text-lg font-semibold text-slate-900">{{ selectedBatch.cards_count }}</p>
          </div>
          <div>
            <label class="text-sm font-medium text-slate-600">Active Cards</label>
            <p class="text-lg font-semibold text-slate-900">{{ selectedBatch.active_cards_count || 0 }}</p>
          </div>
        </div>

        <!-- Payment Info -->
        <div class="bg-slate-50 rounded-lg p-4">
          <h4 class="font-medium text-slate-900 mb-3">Payment Information</h4>
          <div class="grid grid-cols-2 gap-4">
            <div>
              <label class="text-sm text-slate-600">Status</label>
              <p class="mt-1">
                <span :class="getPaymentStatusClass(selectedBatch.payment_status)">
                  {{ formatPaymentStatus(selectedBatch.payment_status) }}
                </span>
              </p>
            </div>
            <div v-if="selectedBatch.payment_status !== 'free'">
              <label class="text-sm text-slate-600">Amount</label>
              <p class="font-semibold text-slate-900">${{ (selectedBatch.total_amount / 100).toFixed(2) }}</p>
            </div>
            <div v-if="selectedBatch.payment_status === 'free'">
              <label class="text-sm text-slate-600">Amount</label>
              <p class="font-semibold text-slate-600">-</p>
            </div>
            <div v-if="selectedBatch.payment_completed_at">
              <label class="text-sm text-slate-600">Paid At</label>
              <p class="text-slate-900">{{ formatDate(selectedBatch.payment_completed_at) }}</p>
            </div>
            <div v-if="selectedBatch.payment_waived && selectedBatch.payment_status === 'free'">
              <label class="text-sm text-slate-600">Issued By</label>
              <p class="text-slate-900">Admin</p>
            </div>
            <div v-if="selectedBatch.payment_waiver_reason" class="col-span-2">
              <label class="text-sm text-slate-600">Reason</label>
              <p class="text-slate-900">{{ selectedBatch.payment_waiver_reason }}</p>
            </div>
          </div>
        </div>

        <!-- Cards Generation Status -->
        <div class="bg-slate-50 rounded-lg p-4">
          <h4 class="font-medium text-slate-900 mb-3">Cards Generation</h4>
          <div class="grid grid-cols-2 gap-4">
            <div>
              <label class="text-sm text-slate-600">Generated</label>
              <p class="font-semibold">
                <span :class="selectedBatch.cards_generated ? 'text-blue-700' : 'text-yellow-700'">
                  {{ selectedBatch.cards_generated ? 'Yes' : 'No' }}
                </span>
              </p>
            </div>
            <div v-if="selectedBatch.cards_generated_at">
              <label class="text-sm text-slate-600">Generated At</label>
              <p class="text-slate-900">{{ formatDate(selectedBatch.cards_generated_at) }}</p>
            </div>
          </div>
        </div>

        <!-- Timestamps -->
        <div class="bg-slate-50 rounded-lg p-4">
          <h4 class="font-medium text-slate-900 mb-3">Timestamps</h4>
          <div class="grid grid-cols-2 gap-4">
            <div>
              <label class="text-sm text-slate-600">Created At</label>
              <p class="text-slate-900">{{ formatDate(selectedBatch.created_at) }}</p>
            </div>
            <div>
              <label class="text-sm text-slate-600">Updated At</label>
              <p class="text-slate-900">{{ formatDate(selectedBatch.updated_at) }}</p>
            </div>
          </div>
        </div>

        <!-- Status Info -->
        <div v-if="selectedBatch.is_disabled" class="bg-red-50 border border-red-200 rounded-lg p-4">
          <div class="flex items-center gap-2">
            <i class="pi pi-exclamation-triangle text-red-600"></i>
            <span class="font-medium text-red-900">This batch is disabled</span>
          </div>
        </div>

        <!-- No pending payment sections needed in payment-first flow -->
      </div>

      <template #footer>
        <div class="flex gap-3 justify-between">
          <Button 
            label="Close" 
            outlined 
            @click="showBatchDetailsDialog = false"
            class="border-slate-600 text-slate-600 hover:bg-slate-50"
          />
          <div v-if="selectedBatch?.payment_status === 'completed' && selectedBatch?.cards_generated" class="flex gap-2">
            <Button 
              label="Download Codes" 
              icon="pi pi-download"
              @click="downloadBatchCodes(selectedBatch)"
              :loading="downloadingCodes"
              outlined
              size="small"
              class="border-blue-600 text-blue-600 hover:bg-blue-50"
            />
            <Button 
              label="View Cards" 
              icon="pi pi-eye"
              @click="viewBatchCards(selectedBatch)"
              outlined
              size="small"
              class="border-blue-600 text-blue-600 hover:bg-blue-50"
            />
          </div>
        </div>
      </template>
    </Dialog>

    <!-- Print Request Dialog -->
    <Dialog 
      v-model:visible="showPrintRequestDialog" 
      modal 
      header="Request Physical Card Printing" 
      :style="{ width: '600px' }"
      class="standardized-dialog"
      appendTo="body"
    >
      <div v-if="selectedBatchForPrint" class="space-y-6">
        <!-- Batch Info Summary -->
        <div class="bg-blue-50 rounded-lg p-4 border border-blue-200">
          <h4 class="font-semibold text-blue-900 mb-2 flex items-center gap-2">
            <i class="pi pi-info-circle"></i>
            Batch Information
          </h4>
          <div class="grid grid-cols-2 gap-4 text-sm">
            <div>
              <span class="text-blue-700 font-medium">Batch Name:</span>
              <p class="text-blue-900">{{ selectedBatchForPrint.batch_name }}</p>
            </div>
            <div>
              <span class="text-blue-700 font-medium">Cards Count:</span>
              <p class="text-blue-900">{{ selectedBatchForPrint.cards_count }} cards</p>
            </div>
            <div>
              <span class="text-blue-700 font-medium">Payment:</span>
              <p class="text-blue-900">✓ Completed</p>
            </div>
            <div>
              <span class="text-blue-700 font-medium">Digital Cards:</span>
              <p class="text-blue-900">✓ Generated</p>
            </div>
          </div>
        </div>

        <!-- Shipping Address -->
        <div>
          <label class="block text-sm font-medium text-slate-700 mb-2">
            Shipping Address <span class="text-red-500">*</span>
          </label>
          <Textarea 
            v-model="printRequestForm.shipping_address"
            rows="4"
            class="w-full"
            placeholder="Enter full shipping address including:&#10;- Full name&#10;- Street address&#10;- City, State/Province&#10;- Postal/ZIP code&#10;- Country"
            :class="{ 'p-invalid': printRequestForm.errors.shipping_address }"
          />
          <small v-if="printRequestForm.errors.shipping_address" class="p-error">
            {{ printRequestForm.errors.shipping_address }}
          </small>
        </div>

        <!-- Contact Information -->
        <div class="space-y-4">
          <h4 class="text-sm font-medium text-slate-700">Contact Information</h4>
          <p class="text-xs text-slate-600 mb-3">
            Please provide at least one contact method for updates about your print request.
          </p>
          
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <!-- Contact Email -->
            <div>
              <label class="block text-sm font-medium text-slate-700 mb-2">
                Email Address
              </label>
              <InputText 
                v-model="printRequestForm.contact_email"
                type="email"
                class="w-full"
                placeholder="Enter email for updates"
                :class="{ 'p-invalid': printRequestForm.errors.contact_email }"
              />
              <small v-if="printRequestForm.errors.contact_email" class="p-error">
                {{ printRequestForm.errors.contact_email }}
              </small>
            </div>

            <!-- WhatsApp Number -->
            <div>
              <label class="block text-sm font-medium text-slate-700 mb-2">
                WhatsApp Number
              </label>
              <InputText 
                v-model="printRequestForm.contact_whatsapp"
                type="tel"
                class="w-full"
                placeholder="+1 234 567 8900"
                :class="{ 'p-invalid': printRequestForm.errors.contact_whatsapp }"
              />
              <small v-if="printRequestForm.errors.contact_whatsapp" class="p-error">
                {{ printRequestForm.errors.contact_whatsapp }}
              </small>
              <small class="text-xs text-slate-500">Include country code (e.g., +1, +44, +852)</small>
            </div>
          </div>
        </div>

        <!-- Print Options Info -->
        <div class="bg-slate-50 rounded-lg p-4 border border-slate-200">
          <h4 class="font-semibold text-slate-900 mb-3 flex items-center gap-2">
            <i class="pi pi-print"></i>
            Print Specifications
          </h4>
          <div class="space-y-2 text-sm text-slate-700">
            <div class="flex items-center gap-2">
              <i class="pi pi-check text-blue-600"></i>
              <span>High-quality cardstock material</span>
            </div>
            <div class="flex items-center gap-2">
              <i class="pi pi-check text-blue-600"></i>
              <span>Full-color printing on both sides</span>
            </div>
            <div class="flex items-center gap-2">
              <i class="pi pi-check text-blue-600"></i>
              <span>QR codes printed for each card</span>
            </div>
            <div class="flex items-center gap-2">
              <i class="pi pi-check text-blue-600"></i>
              <span>Professional packaging and shipping</span>
            </div>
          </div>
        </div>

        <!-- Important Notice -->
        <div class="bg-amber-50 rounded-lg p-4 border border-amber-200">
          <div class="flex items-start gap-3">
            <i class="pi pi-exclamation-triangle text-amber-600 text-lg mt-0.5"></i>
            <div>
              <h5 class="font-medium text-amber-900 mb-1">Important Notice</h5>
              <p class="text-sm text-amber-800">
                This will submit a print request to our production team. Processing typically takes 3-5 business days, 
                plus shipping time. You'll receive tracking information once your order ships.
              </p>
            </div>
          </div>
        </div>
      </div>

      <template #footer>
        <div class="flex gap-3 justify-end">
          <Button 
            label="Cancel" 
            outlined 
            @click="closePrintRequestDialog"
          />
          <Button 
            label="Submit Print Request" 
            icon="pi pi-print"
            severity="primary"
            @click="submitPrintRequest"
            :loading="isSubmittingPrint"
          />
        </div>
      </template>
    </Dialog>

    <!-- Print Status Dialog -->
    <Dialog 
      v-model:visible="showPrintStatusDialog" 
      modal 
      header="Print Request Status" 
      :style="{ width: '600px' }"
      class="standardized-dialog"
      appendTo="body"
    >
      <div v-if="selectedPrintRequestData" class="space-y-6">
        <!-- Request Overview -->
        <div class="bg-slate-50 rounded-lg p-4 border border-slate-200">
          <h4 class="font-semibold text-slate-900 mb-3 flex items-center gap-2">
            <i class="pi pi-info-circle text-blue-600"></i>
            Print Request Details
          </h4>
          <div class="grid grid-cols-2 gap-4">
            <div>
              <label class="text-sm font-medium text-slate-700">Batch Name</label>
              <p class="text-sm text-slate-900 mt-1">{{ selectedPrintRequestData.batch_info?.batch_name }}</p>
            </div>
            <div>
              <label class="text-sm font-medium text-slate-700">Cards Count</label>
              <p class="text-sm text-slate-900 mt-1">
                {{ selectedPrintRequestData.cards_count || selectedPrintRequestData.batch_info?.cards_count || 'N/A' }} cards
              </p>
            </div>
            <div>
              <label class="text-sm font-medium text-slate-700">Request ID</label>
              <p class="text-xs text-slate-600 mt-1 font-mono">{{ selectedPrintRequestData.id }}</p>
            </div>
            <div>
              <label class="text-sm font-medium text-slate-700">Submitted</label>
              <p class="text-sm text-slate-900 mt-1">{{ formatDate(selectedPrintRequestData.requested_at) }}</p>
            </div>
          </div>
        </div>

        <!-- Print Request Progress Steps -->
        <div class="bg-gradient-to-r from-blue-50 to-purple-50 rounded-lg p-6 border border-blue-200">
          <h4 class="font-semibold text-slate-900 mb-4 flex items-center gap-2">
            <i class="pi pi-chart-line text-blue-600"></i>
            Print Request Progress
          </h4>
          
          <div class="space-y-4">
            <!-- Progress Steps -->
            <div class="flex items-center justify-between relative">
              <!-- Progress Line -->
              <div class="absolute top-4 left-4 right-4 h-0.5 bg-slate-300 z-0"></div>
              <div 
                class="absolute top-4 left-4 h-0.5 bg-blue-500 z-10 transition-all duration-500"
                :style="{ width: getPrintProgressWidth(selectedPrintRequestData.status) }"
              ></div>
              
              <!-- Step 1: SUBMITTED -->
              <div class="flex flex-col items-center z-20">
                <div 
                  class="w-8 h-8 rounded-full flex items-center justify-center text-white text-sm font-medium transition-all duration-300"
                  :class="getPrintStepStatusClass('SUBMITTED', selectedPrintRequestData.status)"
                >
                  <i v-if="isPrintStepCompleted('SUBMITTED', selectedPrintRequestData.status)" class="pi pi-check text-xs"></i>
                  <span v-else>1</span>
                </div>
                <span class="text-xs font-medium text-slate-700 mt-2 text-center">Submitted</span>
              </div>
              
              <!-- Step 2: PROCESSING -->
              <div class="flex flex-col items-center z-20">
                <div 
                  class="w-8 h-8 rounded-full flex items-center justify-center text-white text-sm font-medium transition-all duration-300"
                  :class="getPrintStepStatusClass('PROCESSING', selectedPrintRequestData.status)"
                >
                  <i v-if="isPrintStepCompleted('PROCESSING', selectedPrintRequestData.status)" class="pi pi-check text-xs"></i>
                  <span v-else>2</span>
                </div>
                <span class="text-xs font-medium text-slate-700 mt-2 text-center">Processing</span>
              </div>
              
              <!-- Step 3: SHIPPED -->
              <div class="flex flex-col items-center z-20">
                <div 
                  class="w-8 h-8 rounded-full flex items-center justify-center text-white text-sm font-medium transition-all duration-300"
                  :class="getPrintStepStatusClass('SHIPPED', selectedPrintRequestData.status)"
                >
                  <i v-if="isPrintStepCompleted('SHIPPED', selectedPrintRequestData.status)" class="pi pi-check text-xs"></i>
                  <span v-else>3</span>
                </div>
                <span class="text-xs font-medium text-slate-700 mt-2 text-center">Shipped</span>
              </div>
              
              <!-- Step 4: COMPLETED -->
              <div class="flex flex-col items-center z-20">
                <div 
                  class="w-8 h-8 rounded-full flex items-center justify-center text-white text-sm font-medium transition-all duration-300"
                  :class="getPrintStepStatusClass('COMPLETED', selectedPrintRequestData.status)"
                >
                  <i v-if="isPrintStepCompleted('COMPLETED', selectedPrintRequestData.status)" class="pi pi-check text-xs"></i>
                  <span v-else>4</span>
                </div>
                <span class="text-xs font-medium text-slate-700 mt-2 text-center">Completed</span>
              </div>
            </div>
            
            <!-- Current Status Description -->
            <div class="bg-white rounded-lg p-3 border border-slate-200">
              <div class="flex items-center justify-between">
                <div class="flex items-center gap-3">
                  <Tag 
                    :value="getPrintStatusLabel(selectedPrintRequestData.status)"
                    :severity="getPrintStatusSeverity(selectedPrintRequestData.status)"
                    class="px-3 py-1 text-sm"
                  />
                  <span class="text-sm text-slate-600">
                    {{ getPrintStatusDescription(selectedPrintRequestData.status) }}
                  </span>
                </div>
                <span class="text-xs text-slate-500">
                  Updated: {{ formatDate(selectedPrintRequestData.updated_at) }}
                </span>
              </div>
            </div>
          </div>
        </div>


        <!-- Shipping Address -->
        <div class="bg-green-50 rounded-lg p-4 border border-green-200">
          <h4 class="font-semibold text-green-900 mb-3 flex items-center gap-2">
            <i class="pi pi-map-marker text-green-600"></i>
            Shipping Address
          </h4>
          <div class="bg-white rounded border border-green-200 p-3">
            <pre class="text-sm text-slate-900 whitespace-pre-wrap font-sans">{{ selectedPrintRequestData.shipping_address }}</pre>
          </div>
        </div>

        <!-- Contact Information -->
        <div v-if="selectedPrintRequestData.contact_email || selectedPrintRequestData.contact_whatsapp" class="bg-purple-50 rounded-lg p-4 border border-purple-200">
          <h4 class="font-semibold text-purple-900 mb-3 flex items-center gap-2">
            <i class="pi pi-phone text-purple-600"></i>
            Contact Information
          </h4>
          <div class="grid grid-cols-1 md:grid-cols-2 gap-3">
            <div v-if="selectedPrintRequestData.contact_email">
              <label class="text-sm font-medium text-purple-700">Email</label>
              <p class="text-sm text-purple-900 mt-1">{{ selectedPrintRequestData.contact_email }}</p>
            </div>
            <div v-if="selectedPrintRequestData.contact_whatsapp">
              <label class="text-sm font-medium text-purple-700">WhatsApp</label>
              <p class="text-sm text-purple-900 mt-1">{{ selectedPrintRequestData.contact_whatsapp }}</p>
            </div>
          </div>
        </div>

        <!-- Admin Notes -->
        <div v-if="selectedPrintRequestData.admin_notes" class="bg-amber-50 rounded-lg p-4 border border-amber-200">
          <h4 class="font-semibold text-amber-900 mb-3 flex items-center gap-2">
            <i class="pi pi-comment text-amber-600"></i>
            Updates from CardStudio
          </h4>
          <div class="bg-white rounded border border-amber-200 p-3">
            <pre class="text-sm text-slate-900 whitespace-pre-wrap font-sans">{{ selectedPrintRequestData.admin_notes }}</pre>
          </div>
        </div>
      </div>

      <template #footer>
        <div class="flex gap-3 justify-end">
          <Button 
            label="Close" 
            outlined 
            @click="showPrintStatusDialog = false"
            class="border-slate-600 text-slate-600 hover:bg-slate-50"
          />
        </div>
      </template>
    </Dialog>
  </div>
</template>

<script setup>
import { ref, onMounted, computed } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import DataTable from 'primevue/datatable'
import Column from 'primevue/column'
import Button from 'primevue/button'
import Tag from 'primevue/tag'
import Dialog from 'primevue/dialog'
import InputText from 'primevue/inputtext'
import InputNumber from 'primevue/inputnumber'
import Textarea from 'primevue/textarea'
import { useToast } from 'primevue/usetoast'
import { supabase } from '@/lib/supabase'
import { createCheckoutSession, handleCheckoutSuccess } from '@/utils/stripeCheckout.js'

const router = useRouter()
const route = useRoute()
const toast = useToast()

// Props
const props = defineProps({
  cardId: {
    type: String,
    required: true
  }
})

// State
const batches = ref([])
const stats = ref({
  total_issued: 0,
  total_activated: 0,
  activation_rate: 0,
  total_batches: 0
})
const currentCard = ref(null)
const loadingBatches = ref(false)
const creatingBatch = ref(false)
const processingBatchId = ref(null)
const showCreateBatchDialog = ref(false)
const showSuccessMessage = ref(false)
const showBatchDetailsDialog = ref(false)
const selectedBatch = ref(null)
const loadingBatchDetails = ref(false)
const downloadingCodes = ref(false)
const loadingPrintStatusBatchId = ref(null)
const successfulBatch = ref(null) // Store batch info for success actions

// Print request state
const showPrintRequestDialog = ref(false)
const showPrintStatusDialog = ref(false)
const selectedBatchForPrint = ref(null)
const selectedPrintRequestData = ref(null)
const isSubmittingPrint = ref(false)
const printRequestForm = ref({
  shipping_address: '',
  contact_email: '',
  contact_whatsapp: '',
  errors: {
    shipping_address: '',
    contact_email: '',
    contact_whatsapp: ''
  }
})

// New batch form
const newBatch = ref({
  cardCount: 50
})

// Default placeholder image
import cardPlaceholder from '@/assets/images/card-placeholder.jpg'

// Computed
const readyToPrintBatches = computed(() => {
  return batches.value.filter(batch => 
    batch.payment_status === 'completed' && 
    batch.cards_generated && 
    !batch.has_print_request
  )
})

// Methods
const loadData = async () => {
  await Promise.all([
    loadBatches(),
    loadStats(),
    loadCurrentCard()
  ])
}

const loadBatches = async () => {
  try {
    loadingBatches.value = true
    
    // Load batch data
    const { data: batchData, error: batchError } = await supabase.rpc('get_card_batches', {
      p_card_id: props.cardId
    })

    if (batchError) throw batchError

    // Load print request status for each batch
    const batchesWithPrintStatus = await Promise.all(
      (batchData || []).map(async (batch) => {
        try {
          const { data: printRequests, error: printError } = await supabase.rpc('get_print_requests_for_batch', {
            p_batch_id: batch.id
          })
          
          // Get the latest print request status
          const latestPrintRequest = printRequests && printRequests.length > 0 
            ? printRequests.sort((a, b) => new Date(b.requested_at) - new Date(a.requested_at))[0]
            : null

          return {
            ...batch,
            // Determine payment status: admin-issued, waived, paid, or pending
            payment_status: !batch.payment_required ? 'free' : 
                           batch.payment_waived ? 'waived' : 
                           batch.payment_completed ? 'completed' : 'pending',
            total_amount: batch.payment_amount_cents || (batch.cards_count * 200),
            print_request_status: latestPrintRequest?.status || null,
            print_request_id: latestPrintRequest?.id || null,
            has_print_request: !!latestPrintRequest
          }
        } catch (printError) {
          console.warn('Error loading print status for batch:', batch.id, printError)
          return {
            ...batch,
            // Determine payment status: admin-issued, waived, paid, or pending
            payment_status: !batch.payment_required ? 'free' : 
                           batch.payment_waived ? 'waived' : 
                           batch.payment_completed ? 'completed' : 'pending',
            total_amount: batch.payment_amount_cents || (batch.cards_count * 200),
            print_request_status: null,
            print_request_id: null,
            has_print_request: false
          }
        }
      })
    )

    batches.value = batchesWithPrintStatus

  } catch (error) {
    console.error('Error loading batches:', error)
    toast.add({
      severity: 'error',
      summary: 'Error',
      detail: 'Failed to load batches',
      life: 5000
    })
  } finally {
    loadingBatches.value = false
  }
}

const loadStats = async () => {
  try {
    const { data, error } = await supabase.rpc('get_card_issuance_stats', {
      p_card_id: props.cardId
    })
    
    if (error) throw error

    if (data && data.length > 0) {
      const statsData = data[0]
      stats.value = {
        total_issued: statsData.total_issued || 0,
        total_activated: statsData.total_activated || 0,
        activation_rate: Math.round(statsData.activation_rate || 0),
        total_batches: statsData.total_batches || 0
      }
    } else {
      stats.value = {
        total_issued: 0,
        total_activated: 0,
        activation_rate: 0,
        total_batches: 0
      }
    }

  } catch (error) {
    console.error('Error loading stats:', error)
  }
}

const loadCurrentCard = async () => {
  try {
    const { data, error } = await supabase.rpc('get_card_by_id', {
      p_card_id: props.cardId
    })

    if (error) throw error
    
    console.log('Card data received:', data); // Debug log
    
    // Handle nested data structure - the actual card data is in data["0"]
    let cardData = data;
    if (data && typeof data === 'object' && data["0"]) {
      cardData = data["0"];
      console.log('Using nested card data:', cardData);
    }
    
    // Transform data to match expected structure
    currentCard.value = {
      ...cardData,
      title: cardData.name || cardData.title || 'Untitled Card', // Map name to title for compatibility
      image_url: cardData.image_url || null, // Use image if available
      description: cardData.description || ''
    }
    
    console.log('Transformed currentCard:', currentCard.value); // Debug log

  } catch (error) {
    console.error('Error loading current card:', error)
    toast.add({
      severity: 'error',
      summary: 'Error',
      detail: 'Failed to load card information',
      life: 5000
    })
  }
}

// Image handling functions
const handleImageError = (event) => {
  console.log('Image failed to load, using placeholder:', event.target.src);
  event.target.src = cardPlaceholder;
}

const handleImageLoad = (event) => {
  console.log('Image loaded successfully:', event.target.src);
}

const createBatch = async () => {
  try {
    creatingBatch.value = true

    // Payment-first flow: Edge Functions handle batch creation after payment success

    // Close dialog
    showCreateBatchDialog.value = false
    
    // Prepare form data BEFORE resetting
    const formData = {
      cardCount: newBatch.value.cardCount
    }

    // Initiate payment without creating batch first
    await handlePayment(formData)
    
    // Reset form AFTER payment initiation
    newBatch.value = {
      cardCount: 50
    }

  } catch (error) {
    console.error('Error initiating payment:', error)
    toast.add({
      severity: 'error',
      summary: 'Error',
      detail: error.message || 'Failed to initiate payment',
      life: 5000
    })
  } finally {
    creatingBatch.value = false
  }
}

const handlePayment = async (formData) => {
  try {
    processingBatchId.value = 'processing'

    // Payment-first flow: Create checkout session for new batch
    // Batch will be created only after successful payment
    await createCheckoutSession(formData.cardCount, 'pending-batch', {
      card_id: props.cardId,
      is_pending_batch: true // Flag to indicate batch creation is pending
    })

  } catch (error) {
    console.error('Payment error:', error)
    toast.add({
      severity: 'error',
      summary: 'Payment Error',
      detail: error.message || 'Failed to initiate payment',
      life: 5000
    })
  } finally {
    processingBatchId.value = null
  }
}

const viewBatchCards = (batch) => {
  router.push(`/cms/issuedcards?batch_id=${batch.id}`)
}

const viewBatchDetails = async (batch) => {
  selectedBatch.value = batch
  showBatchDetailsDialog.value = true
  loadingBatchDetails.value = true
  
  // Load additional batch details if needed
  try {
    // Get issued cards count for this batch
    const { data: issuedCards, error } = await supabase.rpc('get_issued_cards_with_batch', {
      p_card_id: props.cardId
    })
    
    if (!error && issuedCards) {
      const batchCards = issuedCards.filter(card => card.batch_id === batch.id)
      selectedBatch.value = {
        ...selectedBatch.value,
        issued_cards_count: batchCards.length,
        active_cards_count: batchCards.filter(card => card.active).length
      }
    }
  } catch (error) {
    console.error('Error loading batch details:', error)
  } finally {
    loadingBatchDetails.value = false
  }
}

// handlePaymentFromDetails removed - not needed in payment-first flow

const downloadBatchCodes = async (batch) => {
  try {
    downloadingCodes.value = true
    
    // Get all issued cards for this batch
    const { data: issuedCards, error } = await supabase.rpc('get_issued_cards_with_batch', {
      p_card_id: props.cardId
    })
    
    if (error) throw error
    
    const batchCards = issuedCards.filter(card => card.batch_id === batch.id)
    
    // Create CSV content
    const headers = ['Card Number', 'Issue Card ID', 'Status', 'QR Code URL']
    const rows = batchCards.map((card, index) => [
      index + 1,
      card.id,
      card.active ? 'Active' : 'Inactive',
      `${window.location.origin}/c/${card.id}`
    ])
    
    const csvContent = [
      headers.join(','),
      ...rows.map(row => row.join(','))
    ].join('\n')
    
    // Download CSV
    const blob = new Blob([csvContent], { type: 'text/csv' })
    const url = window.URL.createObjectURL(blob)
    const a = document.createElement('a')
    a.href = url
    a.download = `${currentCard.value?.title || 'cards'}_${batch.batch_name}_codes.csv`
    document.body.appendChild(a)
    a.click()
    document.body.removeChild(a)
    window.URL.revokeObjectURL(url)
    
    toast.add({
      severity: 'success',
      summary: 'Download Started',
      detail: `Downloaded ${batchCards.length} card access codes`,
      life: 3000
    })
    
  } catch (error) {
    console.error('Error downloading codes:', error)
    toast.add({
      severity: 'error',
      summary: 'Download Failed',
      detail: 'Failed to download activation codes',
      life: 5000
    })
  } finally {
    downloadingCodes.value = false
  }
}

const closeSuccessMessage = () => {
  showSuccessMessage.value = false
  successfulBatch.value = null
  loadData() // Refresh data
}

const handleSuccessPrintRequest = () => {
  if (successfulBatch.value) {
    showSuccessMessage.value = false
    requestPrint(successfulBatch.value)
  }
}

// Print request methods
const requestPrint = (batch) => {
  selectedBatchForPrint.value = batch
  printRequestForm.value.shipping_address = ''
  printRequestForm.value.contact_email = ''
  printRequestForm.value.contact_whatsapp = ''
  printRequestForm.value.errors.shipping_address = ''
  printRequestForm.value.errors.contact_email = ''
  printRequestForm.value.errors.contact_whatsapp = ''
  showPrintRequestDialog.value = true
}

const viewPrintRequest = async (batch) => {
  try {
    const { data: printRequests, error } = await supabase.rpc('get_print_requests_for_batch', {
      p_batch_id: batch.id
    })
    
    if (error) throw error
    
    if (printRequests && printRequests.length > 0) {
      const latestRequest = printRequests.sort((a, b) => new Date(b.requested_at) - new Date(a.requested_at))[0]
      
      toast.add({
        severity: 'info',
        summary: 'Print Request Status',
        detail: `Status: ${getPrintStatusLabel(latestRequest.status)}\nRequested: ${formatDate(latestRequest.requested_at)}`,
        life: 6000
      })
    }
  } catch (error) {
    console.error('Error loading print request details:', error)
    toast.add({
      severity: 'error',
      summary: 'Error',
      detail: 'Failed to load print request details',
      life: 5000
    })
  }
}

const viewPrintRequestDialog = async (batch) => {
  try {
    loadingPrintStatusBatchId.value = batch.id
    
    const { data: printRequests, error } = await supabase.rpc('get_print_requests_for_batch', {
      p_batch_id: batch.id
    })
    
    if (error) throw error
    
    if (printRequests && printRequests.length > 0) {
      const latestRequest = printRequests.sort((a, b) => new Date(b.requested_at) - new Date(a.requested_at))[0]
      console.log('Latest print request data:', latestRequest)
      console.log('Cards count from DB:', latestRequest.cards_count)
      selectedPrintRequestData.value = {
        ...latestRequest,
        batch_info: batch,
        // Fallback to batch.cards_count if not provided by DB
        cards_count: latestRequest.cards_count || batch.cards_count
      }
      console.log('Selected print request data:', selectedPrintRequestData.value)
      showPrintStatusDialog.value = true
    } else {
      toast.add({
        severity: 'warn',
        summary: 'No Print Request',
        detail: 'No print request found for this batch',
        life: 5000
      })
    }
  } catch (error) {
    console.error('Error loading print request details:', error)
    toast.add({
      severity: 'error',
      summary: 'Error',
      detail: 'Failed to load print request details',
      life: 5000
    })
  } finally {
    loadingPrintStatusBatchId.value = null
  }
}

const closePrintRequestDialog = () => {
  showPrintRequestDialog.value = false
  selectedBatchForPrint.value = null
  printRequestForm.value.shipping_address = ''
  printRequestForm.value.contact_email = ''
  printRequestForm.value.contact_whatsapp = ''
  printRequestForm.value.errors.shipping_address = ''
  printRequestForm.value.errors.contact_email = ''
  printRequestForm.value.errors.contact_whatsapp = ''
}

const validatePrintForm = () => {
  // Reset errors
  printRequestForm.value.errors.shipping_address = ''
  printRequestForm.value.errors.contact_email = ''
  printRequestForm.value.errors.contact_whatsapp = ''
  
  let isValid = true
  
  // Validate shipping address
  if (!printRequestForm.value.shipping_address.trim()) {
    printRequestForm.value.errors.shipping_address = 'Shipping address is required'
    isValid = false
  } else if (printRequestForm.value.shipping_address.trim().length < 20) {
    printRequestForm.value.errors.shipping_address = 'Please provide a complete shipping address'
    isValid = false
  }
  
  // Validate contact information - at least one is required
  const hasEmail = printRequestForm.value.contact_email.trim()
  const hasWhatsApp = printRequestForm.value.contact_whatsapp.trim()
  
  if (!hasEmail && !hasWhatsApp) {
    printRequestForm.value.errors.contact_email = 'Please provide at least one contact method'
    printRequestForm.value.errors.contact_whatsapp = 'Please provide at least one contact method'
    isValid = false
  }
  
  // Validate email format if provided
  if (hasEmail) {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
    if (!emailRegex.test(printRequestForm.value.contact_email.trim())) {
      printRequestForm.value.errors.contact_email = 'Please enter a valid email address'
      isValid = false
    }
  }
  
  // Validate WhatsApp format if provided
  if (hasWhatsApp) {
    const whatsappRegex = /^\+[1-9]\d{1,14}$/
    if (!whatsappRegex.test(printRequestForm.value.contact_whatsapp.trim())) {
      printRequestForm.value.errors.contact_whatsapp = 'Please enter a valid WhatsApp number with country code (e.g., +1234567890)'
      isValid = false
    }
  }
  
  return isValid
}

const submitPrintRequest = async () => {
  if (!validatePrintForm()) {
    return
  }
  
  try {
    isSubmittingPrint.value = true
    
    const { error } = await supabase.rpc('request_card_printing', {
      p_batch_id: selectedBatchForPrint.value.id,
      p_shipping_address: printRequestForm.value.shipping_address.trim(),
      p_contact_email: printRequestForm.value.contact_email.trim() || null,
      p_contact_whatsapp: printRequestForm.value.contact_whatsapp.trim() || null
    })
    
    if (error) throw error
    
    toast.add({
      severity: 'success',
      summary: 'Print Request Submitted',
      detail: `Print request submitted for ${selectedBatchForPrint.value.cards_count} cards. You'll receive updates via email.`,
      life: 6000
    })
    
    closePrintRequestDialog()
    loadData() // Refresh data to show updated status
    
  } catch (error) {
    console.error('Error submitting print request:', error)
    
    let errorMessage = 'Failed to submit print request'
    if (error.message.includes('already exists')) {
      errorMessage = 'A print request for this batch has already been submitted'
    } else if (error.message.includes('payment')) {
      errorMessage = 'Batch payment must be completed before requesting printing'
    } else if (error.message.includes('generated')) {
      errorMessage = 'Cards must be generated before requesting printing'
    }
    
    toast.add({
      severity: 'error',
      summary: 'Print Request Failed',
      detail: errorMessage,
      life: 5000
    })
  } finally {
    isSubmittingPrint.value = false
  }
}

// Payment status helpers
const getPaymentStatusClass = (status) => {
  const classes = {
    pending: 'inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-yellow-100 text-yellow-800',
    completed: 'inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800',
    succeeded: 'inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800',
    free: 'inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800',
    waived: 'inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-purple-100 text-purple-800',
    failed: 'inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-red-100 text-red-800',
    canceled: 'inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-gray-100 text-gray-800'
  }
  return classes[status] || classes.pending
}

const formatPaymentStatus = (status) => {
  const statuses = {
    pending: 'Pending',
    completed: 'Paid',
    succeeded: 'Paid',
    free: 'Admin Issued',
    waived: 'Waived',
    failed: 'Failed',
    canceled: 'Canceled'
  }
  return statuses[status] || 'Unknown'
}

const formatDate = (dateString) => {
  return new Date(dateString).toLocaleDateString('en-US', {
    month: 'short',
    day: 'numeric',
    year: 'numeric'
  })
}

// Print status helpers
const getPrintStatusLabel = (status) => {
  const labels = {
    SUBMITTED: 'Submitted',
    PAYMENT_PENDING: 'Payment Pending',
    PROCESSING: 'Processing', 
    SHIPPED: 'Shipped',
    COMPLETED: 'Delivered',
    CANCELLED: 'Cancelled'
  }
  return labels[status] || status
}

const getPrintStatusSeverity = (status) => {
  const severities = {
    SUBMITTED: 'info',           // Blue
    PAYMENT_PENDING: 'contrast', // Dark
    PROCESSING: 'warning',       // Orange/Yellow
    SHIPPED: 'primary',          // Purple/Blue
    COMPLETED: 'success',        // Green
    CANCELLED: 'danger'          // Red
  }
  return severities[status] || 'secondary'
}

// Print request progress bar helpers
const isPrintStepCompleted = (stepStatus, currentStatus) => {
  const statusOrder = ['SUBMITTED', 'PAYMENT_PENDING', 'PROCESSING', 'SHIPPED', 'COMPLETED']
  const stepIndex = statusOrder.indexOf(stepStatus)
  const currentIndex = statusOrder.indexOf(currentStatus)
  
  // Special handling for cancelled status
  if (currentStatus === 'CANCELLED') {
    return stepStatus === 'SUBMITTED' // Only submitted is completed for cancelled requests
  }
  
  return currentIndex >= stepIndex
}

const getPrintStepStatusClass = (stepStatus, currentStatus) => {
  if (currentStatus === 'CANCELLED') {
    if (stepStatus === 'SUBMITTED') return 'bg-blue-500'
    return 'bg-slate-400'
  }
  
  if (isPrintStepCompleted(stepStatus, currentStatus)) {
    return 'bg-blue-500'
  } else if (stepStatus === currentStatus) {
    return 'bg-purple-500 animate-pulse'
  } else {
    return 'bg-slate-400'
  }
}

const getPrintProgressWidth = (currentStatus) => {
  const statusOrder = ['SUBMITTED', 'PAYMENT_PENDING', 'PROCESSING', 'SHIPPED', 'COMPLETED']
  const currentIndex = statusOrder.indexOf(currentStatus)
  
  if (currentStatus === 'CANCELLED') {
    return '0%' // No progress for cancelled
  }
  
  if (currentIndex === -1) return '0%'
  
  // Calculate progress based on 5 steps
  const totalSteps = 5
  const percentage = (currentIndex / (totalSteps - 1)) * 100
  return `${Math.min(100, Math.max(0, percentage))}%`
}

const getPrintStatusDescription = (status) => {
  const descriptions = {
    SUBMITTED: 'Your print request has been received and is being reviewed.',
    PAYMENT_PENDING: 'Awaiting payment confirmation for print request.',
    PROCESSING: 'Your cards are being printed and prepared for shipping.',
    SHIPPED: 'Your cards have been shipped and are on their way to you.',
    COMPLETED: 'Your cards have been delivered successfully.',
    CANCELLED: 'This print request has been cancelled.'
  }
  return descriptions[status] || 'Status unknown'
}

// Batch progress helpers

const getBatchProgressText = (batch) => {
  // In payment-first flow, no batches should have pending payment status
  if (!batch.cards_generated) return 'Generating cards...'
  if (!batch.has_print_request) return 'Ready for print'
  return `Print: ${getPrintStatusLabel(batch.print_request_status)}`
}


// Handle checkout success on page load
const handlePageLoad = async () => {
  const sessionId = route.query.session_id
  const batchId = route.query.batch_id
  const canceled = route.query.canceled

  if (canceled) {
    toast.add({
      severity: 'warn',
      summary: 'Payment Canceled',
      detail: 'Payment was canceled. You can create a new batch anytime.',
      life: 5000
    })
    // Clean URL
    router.replace('/cms/mycards')
    return
  }

  if (sessionId) {
    try {
      // Process successful payment - Edge Function handles batch creation
      const result = await handleCheckoutSuccess(sessionId)
      console.log('Payment processed successfully:', result)
      
      // Load updated data to show the new batch
      await loadData()
      
      // Find the batch that was created
      let batch = null
      if (result && result.batchId) {
        batch = batches.value.find(b => b.id === result.batchId)
      } else {
        // Find most recent batch for this card as fallback
        const cardBatches = batches.value.filter(b => b.card_id === props.cardId)
        batch = cardBatches.sort((a, b) => new Date(b.created_at) - new Date(a.created_at))[0]
      }
      
      if (batch) {
        successfulBatch.value = batch
        console.log('Found successful batch:', batch.batch_name)
      }
      
      // Show success message
      showSuccessMessage.value = true
      
      // Clean URL
      router.replace('/cms/mycards')
      
    } catch (error) {
      console.error('Error processing checkout success:', error)
      toast.add({
        severity: 'error',
        summary: 'Payment Processing Error',
        detail: error.message || 'Payment was successful but there was an issue processing it. Please contact support.',
        life: 10000
      })
    }
  }
}

// Lifecycle
onMounted(async () => {
  await handlePageLoad()
  await loadData()
})
</script>

<style scoped>
/* Custom styles for better UX */
.p-datatable {
  border-radius: 0;
}

/* Line clamp utility for description text */
.line-clamp-2 {
  display: -webkit-box;
  -webkit-line-clamp: 2;
  line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

.p-datatable .p-datatable-thead > tr > th {
  background: #f8fafc;
  border: none;
  color: #475569;
  font-weight: 600;
  font-size: 0.875rem;
}

.p-datatable .p-datatable-tbody > tr {
  border: none;
}

.p-datatable .p-datatable-tbody > tr > td {
  border: none;
  border-bottom: 1px solid #e2e8f0;
}

.p-datatable .p-datatable-tbody > tr:hover {
  background: #f8fafc;
}
</style>