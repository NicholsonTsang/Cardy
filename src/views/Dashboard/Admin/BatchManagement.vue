<template>
  <PageWrapper 
    :title="$t('admin.physical_card_management')" 
    :description="$t('admin.physical_card_management_desc')"
  >
    <template #actions>
      <Button 
        icon="pi pi-refresh" 
        :label="$t('admin.refresh_data')" 
        @click="refreshData"
        :loading="isRefreshing"
        severity="secondary"
        outlined
      />
    </template>

    <div class="space-y-6">
      <!-- Physical Cards Only Notice -->
      <div class="bg-gradient-to-r from-amber-50 to-orange-50 border border-amber-200 rounded-xl p-4 flex items-center gap-3">
        <div class="w-10 h-10 rounded-lg bg-amber-100 flex items-center justify-center flex-shrink-0">
          <i class="pi pi-credit-card text-amber-600 text-lg"></i>
        </div>
        <div>
          <p class="text-sm font-medium text-amber-900">{{ $t('admin.physical_cards_only') }}</p>
          <p class="text-xs text-amber-700">{{ $t('admin.physical_card_management_notice') }}</p>
        </div>
      </div>

      <!-- Tabbed Interface -->
      <div class="bg-white rounded-xl shadow-lg border border-slate-200 overflow-hidden">
        <Tabs v-model:value="activeTab">
          <TabList class="border-b border-slate-200 bg-slate-50 px-4">
            <Tab value="all-batches" class="flex items-center gap-2">
              <i class="pi pi-box"></i>
              {{ $t('batches.all_batches') }}
            </Tab>
            <Tab value="print-requests" class="flex items-center gap-2">
              <i class="pi pi-print"></i>
              {{ $t('admin.print_requests') }}
              <span 
                v-if="pendingPrintRequestsCount > 0" 
                class="ml-1 px-2 py-0.5 text-xs font-medium bg-red-100 text-red-700 rounded-full"
              >
                {{ pendingPrintRequestsCount }}
              </span>
            </Tab>
            <Tab value="issue-batch" class="flex items-center gap-2">
              <i class="pi pi-gift"></i>
              {{ $t('admin.issue_free_batch') }}
            </Tab>
          </TabList>

          <TabPanels>
            <!-- All Batches Tab -->
            <TabPanel value="all-batches">
              <div class="p-6">
                <DataTable 
                  :value="batchesStore.allBatches" 
                  :loading="batchesStore.isLoadingAllBatches"
                  paginator 
                  :rows="10"
                  :rowsPerPageOptions="[10, 20, 50]"
                  dataKey="id"
                  showGridlines
                  responsiveLayout="scroll"
                >
                  <template #header>
                    <div class="flex flex-col gap-4">
                      <div class="flex justify-between items-center">
                        <span class="text-sm text-slate-600">
                          {{ $t('common.total') }}: {{ batchesStore.allBatches.length }}
                        </span>
                      </div>
                      
                      <!-- Filters -->
                      <div class="flex flex-wrap gap-3 items-center">
                        <div class="flex items-center gap-2">
                          <label class="text-sm text-slate-700 font-medium">{{ $t('admin.search_by_email') }}</label>
                          <InputText 
                            v-model="emailSearch"
                            :placeholder="$t('admin.search_by_email')"
                            class="w-64"
                            @input="applyBatchFilters"
                          />
                        </div>
                        
                        <div class="flex items-center gap-2">
                          <label class="text-sm text-slate-700 font-medium">{{ $t('batches.payment_status') }}</label>
                          <Select 
                            v-model="paymentStatusFilter"
                            :options="paymentStatusOptions"
                            optionLabel="label"
                            optionValue="value"
                            :placeholder="$t('admin.all_statuses')"
                            class="w-40"
                            showClear
                            @change="applyBatchFilters"
                          />
                        </div>
                        
                        <Button 
                          icon="pi pi-times"
                          :label="$t('admin.clear_filters')"
                          @click="clearBatchFilters"
                          size="small"
                          severity="secondary"
                          outlined
                          v-if="hasBatchFilters"
                        />
                      </div>
                    </div>
                  </template>

                  <Column field="batch_number" :header="$t('batches.batch_number')" sortable style="min-width: 140px">
                    <template #body="{ data }">
                      <span class="font-mono text-sm font-medium text-slate-900">
                        #{{ data.batch_number.toString().padStart(6, '0') }}
                      </span>
                    </template>
                  </Column>

                  <Column field="user_email" :header="$t('admin.user_email')" sortable style="min-width: 250px">
                    <template #body="{ data }">
                      <span class="font-medium text-slate-900">{{ data.user_email }}</span>
                    </template>
                  </Column>
                  
                  <Column field="payment_status" :header="$t('batches.payment_status')" sortable style="min-width: 140px">
                    <template #body="{ data }">
                      <Tag
                        :value="getPaymentStatusLabel(data.payment_status)"
                        :severity="getPaymentStatusSeverity(data.payment_status)"
                      />
                    </template>
                  </Column>

                  <Column field="cards_count" :header="$t('batches.total_cards')" sortable style="min-width: 130px">
                    <template #body="{ data }">
                      <span class="font-medium text-slate-900">{{ data.cards_count }}</span>
                    </template>
                  </Column>

                  <Column field="created_at" :header="$t('dashboard.created')" sortable style="min-width: 180px">
                    <template #body="{ data }">
                      <span class="text-sm text-slate-600">
                        {{ formatDate(data.created_at) }}
                      </span>
                    </template>
                  </Column>

                  <template #empty>
                    <div class="text-center py-12">
                      <i class="pi pi-inbox text-6xl text-slate-400 mb-4"></i>
                      <p class="text-lg font-medium text-slate-900 mb-2">{{ $t('batches.no_batches_found') }}</p>
                      <p class="text-slate-600">{{ $t('admin.no_batches_match_filters') }}</p>
                    </div>
                  </template>
                  <template #loading>
                    <div class="flex items-center justify-center py-12">
                      <ProgressSpinner style="width: 50px; height: 50px" strokeWidth="4" />
                    </div>
                  </template>
                </DataTable>
              </div>
            </TabPanel>

            <!-- Print Requests Tab -->
            <TabPanel value="print-requests">
              <div class="p-6 space-y-4">
                <!-- Print Filters -->
                <div class="flex flex-wrap gap-3 items-center">
                  <div class="flex items-center gap-2">
                    <IconField>
                      <InputIcon class="pi pi-search" />
                      <InputText 
                        v-model="printSearchQuery"
                        :placeholder="$t('admin.search_by_user_card_batch')"
                        class="w-64"
                        @input="applyPrintFilters"
                      />
                    </IconField>
                  </div>
                  
                  <div class="flex items-center gap-2">
                    <Select 
                      v-model="printStatusFilter" 
                      :options="printStatusOptions"
                      optionLabel="label"
                      optionValue="value"
                      :placeholder="$t('admin.request_status')"
                      class="w-44"
                      @change="applyPrintFilters"
                      showClear
                    />
                  </div>
                  
                  <Button 
                    v-if="hasPrintFilters"
                    :label="$t('admin.clear_filters')"
                    icon="pi pi-times"
                    severity="secondary"
                    size="small"
                    outlined
                    @click="clearPrintFilters"
                  />
                </div>

                <!-- Print Requests Table -->
                <DataTable 
                  :value="printRequestsStore.printRequests" 
                  :loading="printRequestsStore.isLoadingPrintRequests"
                  :paginator="true" 
                  :rows="10"
                  :rowsPerPageOptions="[10, 20, 50]"
                  responsiveLayout="scroll"
                  showGridlines
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
                      <span class="text-sm text-slate-600">
                        {{ $t('common.total') }}: {{ printRequestsStore.printRequests.length }}
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
                        :value="getPrintStatusLabel(data.status)" 
                        :severity="getPrintStatusSeverity(data.status)"
                      />
                    </template>
                  </Column>

                  <Column field="shipping_address" :header="$t('admin.shipping_address')" style="min-width:200px">
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

                  <Column :header="$t('common.actions')" :exportable="false" style="min-width:140px">
                    <template #body="{ data }">
                      <div class="flex gap-2">
                        <Button 
                          icon="pi pi-eye" 
                          severity="secondary" 
                          size="small"
                          outlined
                          @click="viewPrintDetails(data)"
                          :title="$t('common.view')"
                        />
                        <Select
                          v-model="data.status"
                          :options="printStatusUpdateOptions"
                          optionLabel="label"
                          optionValue="value"
                          :placeholder="$t('admin.update_status')"
                          size="small"
                          @change="updatePrintStatus(data.id, $event.value)"
                          :disabled="data.status === 'COMPLETED' || data.status === 'CANCELLED'"
                        />
                      </div>
                    </template>
                  </Column>
                </DataTable>
              </div>
            </TabPanel>

            <!-- Issue Free Batch Tab -->
            <TabPanel value="issue-batch">
              <div class="p-6">
                <div class="max-w-3xl mx-auto">
                  <!-- Instructions Card -->
                  <div class="bg-blue-50 border border-blue-200 rounded-xl p-5 mb-6">
                    <div class="flex items-start gap-3">
                      <i class="pi pi-info-circle text-blue-600 text-xl mt-0.5"></i>
                      <div>
                        <h3 class="text-base font-semibold text-blue-900 mb-1">{{ $t('admin.about_free_batch_issuance') }}</h3>
                        <p class="text-sm text-blue-800 leading-relaxed">
                          {{ $t('admin.about_free_batch_text') }}
                        </p>
                      </div>
                    </div>
                  </div>

                  <!-- Issuance Form -->
                  <form @submit.prevent="handleSubmit" class="space-y-5">
                    <!-- User Email Search -->
                    <div class="space-y-2">
                      <label class="block text-sm font-medium text-slate-700">
                        {{ $t('common.email') }} <span class="text-red-500">*</span>
                      </label>
                      <div class="flex gap-3">
                        <InputText 
                          v-model="form.userEmail"
                          :placeholder="$t('admin.enter_user_email_address')"
                          class="flex-1"
                          :class="{ 'p-invalid': errors.userEmail }"
                          @input="handleUserEmailChange"
                        />
                        <Button 
                          icon="pi pi-search" 
                          :label="$t('admin.search_user')"
                          @click="searchUser"
                          :loading="isSearchingUser"
                          :disabled="!form.userEmail || isSearchingUser"
                          severity="secondary"
                          outlined
                        />
                      </div>
                      <small v-if="errors.userEmail" class="text-red-500">{{ errors.userEmail }}</small>
                      
                      <!-- User Info Display -->
                      <div v-if="selectedUser" class="mt-3 p-4 bg-green-50 border border-green-200 rounded-lg">
                        <div class="flex items-center gap-3">
                          <i class="pi pi-check-circle text-green-600 text-xl"></i>
                          <div class="flex-1">
                            <p class="text-sm font-medium text-green-900">{{ $t('admin.user_found') }}</p>
                            <p class="text-sm text-green-700">{{ selectedUser.email }}</p>
                            <p class="text-xs text-green-600 mt-1">
                              {{ selectedUser.cards_count || 0 }} {{ $t('admin.cards_created') }}
                            </p>
                          </div>
                        </div>
                      </div>
                    </div>

                    <!-- Card Selection -->
                    <div class="space-y-2">
                      <label class="block text-sm font-medium text-slate-700">
                        {{ $t('admin.select_card') }} <span class="text-red-500">*</span>
                      </label>
                      <Select 
                        v-model="form.cardId"
                        :options="physicalUserCards"
                        optionLabel="card_name"
                        optionValue="id"
                        :placeholder="$t('admin.select_card_to_issue')"
                        class="w-full"
                        :disabled="!selectedUser || isLoadingCards"
                        :loading="isLoadingCards"
                        :class="{ 'p-invalid': errors.cardId }"
                        showClear
                      >
                        <template #option="{ option }">
                          <div class="flex items-center justify-between w-full">
                            <span>{{ option.card_name }}</span>
                            <Tag :value="`${option.batches_count || 0} ${$t('batches.batches')}`" severity="secondary" class="text-xs" />
                          </div>
                        </template>
                        <template #empty>
                          <div class="p-3 text-center text-sm text-slate-500">
                            {{ $t('admin.no_physical_cards_available') }}
                          </div>
                        </template>
                      </Select>
                      <small v-if="errors.cardId" class="text-red-500">{{ errors.cardId }}</small>
                      <small v-else class="text-slate-500">
                        {{ selectedUser ? $t('admin.choose_which_card_physical_only') : $t('admin.search_user_first') }}
                      </small>
                    </div>

                    <!-- Cards Count -->
                    <div class="space-y-2">
                      <label class="block text-sm font-medium text-slate-700">
                        {{ $t('admin.batch_quantity') }} <span class="text-red-500">*</span>
                      </label>
                      <InputNumber 
                        v-model="form.cardsCount"
                        :min="1"
                        :max="10000"
                        :step="1"
                        showButtons
                        buttonLayout="horizontal"
                        :placeholder="$t('admin.enter_batch_quantity')"
                        class="w-full max-w-xs"
                        :class="{ 'p-invalid': errors.cardsCount }"
                      />
                      <small v-if="errors.cardsCount" class="text-red-500">{{ errors.cardsCount }}</small>
                      <small v-else class="text-slate-500">
                        {{ $t('admin.min_1_max_10000') }}
                        <span v-if="form.cardsCount > 0" class="font-medium text-slate-700">
                          ({{ $t('admin.regular_cost') }}: ${{ (form.cardsCount * 2).toLocaleString() }})
                        </span>
                      </small>
                    </div>

                    <!-- Reason -->
                    <div class="space-y-2">
                      <label class="block text-sm font-medium text-slate-700">
                        {{ $t('admin.issuance_reason') }} <span class="text-red-500">*</span>
                      </label>
                      <Textarea 
                        v-model="form.reason"
                        rows="3"
                        :placeholder="$t('admin.explain_why_issuing')"
                        class="w-full"
                        :class="{ 'p-invalid': errors.reason }"
                      />
                      <small v-if="errors.reason" class="text-red-500">{{ errors.reason }}</small>
                    </div>

                    <!-- Summary Card -->
                    <div v-if="isFormComplete" class="p-4 bg-slate-50 border border-slate-200 rounded-lg">
                      <h4 class="text-sm font-semibold text-slate-900 mb-3">{{ $t('admin.issuance_summary') }}</h4>
                      <div class="space-y-2 text-sm">
                        <div class="flex justify-between">
                          <span class="text-slate-600">{{ $t('admin.user') }}:</span>
                          <span class="font-medium text-slate-900">{{ form.userEmail }}</span>
                        </div>
                        <div class="flex justify-between">
                          <span class="text-slate-600">{{ $t('admin.card') }}:</span>
                          <span class="font-medium text-slate-900">{{ selectedCardName }}</span>
                        </div>
                        <div class="flex justify-between">
                          <span class="text-slate-600">{{ $t('admin.cards_count') }}:</span>
                          <span class="font-medium text-slate-900">{{ form.cardsCount }}</span>
                        </div>
                        <div class="flex justify-between pt-2 border-t border-slate-300">
                          <span class="text-slate-600">{{ $t('admin.regular_cost') }}:</span>
                          <span class="font-semibold text-slate-900 line-through">${{ (form.cardsCount * 2).toLocaleString() }}</span>
                        </div>
                        <div class="flex justify-between">
                          <span class="text-green-600 font-medium">{{ $t('admin.free_issuance') }}:</span>
                          <span class="font-semibold text-green-600">$0.00</span>
                        </div>
                      </div>
                    </div>

                    <!-- Action Buttons -->
                    <div class="flex justify-end gap-3 pt-4 border-t border-slate-200">
                      <Button 
                        :label="$t('common.cancel')" 
                        severity="secondary"
                        outlined
                        @click="resetForm"
                        :disabled="isSubmitting"
                      />
                      <Button 
                        type="submit"
                        :label="$t('admin.issue_free_batch_button')"
                        icon="pi pi-check"
                        :loading="isSubmitting"
                        :disabled="!isFormComplete || isSubmitting"
                      />
                    </div>
                  </form>

                  <!-- Recent Issuances -->
                  <div v-if="recentIssuances.length > 0" class="mt-8 border-t border-slate-200 pt-6">
                    <h3 class="text-base font-semibold text-slate-900 mb-4">{{ $t('admin.recent_free_batch_issuances') }}</h3>
                    <div class="space-y-3">
                      <div 
                        v-for="issuance in recentIssuances" 
                        :key="issuance.id"
                        class="flex items-center justify-between p-3 bg-green-50 border border-green-200 rounded-lg"
                      >
                        <div class="flex items-center gap-3">
                          <i class="pi pi-check-circle text-green-600"></i>
                          <div>
                            <p class="text-sm font-medium text-slate-900">{{ issuance.cardsCount }} {{ $t('card.cards_text') }}</p>
                            <p class="text-xs text-slate-600">{{ issuance.userEmail }}</p>
                          </div>
                        </div>
                        <span class="text-xs text-slate-500">{{ formatTimeAgo(issuance.timestamp) }}</span>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </TabPanel>
          </TabPanels>
        </Tabs>
      </div>
    </div>

    <!-- Print Request Details Dialog -->
    <Dialog
      v-model:visible="showPrintDetailsDialog"
      :header="$t('admin.print_request_details')"
      :style="{ width: '90vw', maxWidth: '800px' }"
      :modal="true"
    >
      <div v-if="selectedPrintRequest" class="space-y-6">
        <!-- User Information -->
        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div>
            <h4 class="font-semibold text-slate-900 mb-3">{{ $t('admin.user_information') }}</h4>
            <div class="space-y-2 text-sm">
              <div class="flex justify-between">
                <span class="text-slate-600">{{ $t('common.name') }}:</span>
                <span class="font-medium text-slate-900">{{ selectedPrintRequest.user_public_name || '-' }}</span>
              </div>
              <div class="flex justify-between">
                <span class="text-slate-600">{{ $t('common.email') }}:</span>
                <span class="font-medium text-slate-900">{{ selectedPrintRequest.user_email }}</span>
              </div>
              <div class="flex justify-between">
                <span class="text-slate-600">{{ $t('admin.contact_email') }}:</span>
                <span class="font-medium text-slate-900">{{ selectedPrintRequest.contact_email || '-' }}</span>
              </div>
              <div class="flex justify-between">
                <span class="text-slate-600">{{ $t('admin.whatsapp') }}:</span>
                <span class="font-medium text-slate-900">{{ selectedPrintRequest.contact_whatsapp || '-' }}</span>
              </div>
            </div>
          </div>
          
          <div>
            <h4 class="font-semibold text-slate-900 mb-3">{{ $t('admin.request_details') }}</h4>
            <div class="space-y-2 text-sm">
              <div class="flex justify-between">
                <span class="text-slate-600">{{ $t('admin.card') }}:</span>
                <span class="font-medium text-slate-900">{{ selectedPrintRequest.card_name }}</span>
              </div>
              <div class="flex justify-between">
                <span class="text-slate-600">{{ $t('batches.batch') }}:</span>
                <span class="font-medium text-slate-900">{{ selectedPrintRequest.batch_name }}</span>
              </div>
              <div class="flex justify-between">
                <span class="text-slate-600">{{ $t('batches.cards_count') }}:</span>
                <span class="font-medium text-slate-900">{{ selectedPrintRequest.cards_count }}</span>
              </div>
              <div class="flex justify-between">
                <span class="text-slate-600">{{ $t('common.status') }}:</span>
                <Tag 
                  :value="getPrintStatusLabel(selectedPrintRequest.status)" 
                  :severity="getPrintStatusSeverity(selectedPrintRequest.status)"
                />
              </div>
              <div class="flex justify-between">
                <span class="text-slate-600">{{ $t('admin.requested_at') }}:</span>
                <span class="font-medium text-slate-900">{{ formatDate(selectedPrintRequest.requested_at) }}</span>
              </div>
            </div>
          </div>
        </div>

        <!-- Shipping Address -->
        <div>
          <h4 class="font-semibold text-slate-900 mb-3">{{ $t('admin.shipping_address') }}</h4>
          <div class="bg-slate-50 rounded-lg p-4">
            <pre class="text-sm text-slate-800 whitespace-pre-wrap">{{ selectedPrintRequest.shipping_address }}</pre>
          </div>
        </div>

        <!-- Admin Feedbacks History -->
        <div v-if="selectedPrintRequestFeedbacks.length > 0">
          <h4 class="font-semibold text-slate-900 mb-3">{{ $t('admin.admin_feedbacks') }}</h4>
          <div class="space-y-2">
            <div 
              v-for="feedback in selectedPrintRequestFeedbacks" 
              :key="feedback.id"
              class="bg-amber-50 rounded-lg p-3 border border-amber-200"
            >
              <div class="flex items-center justify-between mb-1">
                <span class="text-xs text-amber-700 font-medium">{{ feedback.admin_email }}</span>
                <div class="flex items-center gap-2">
                  <Tag 
                    v-if="feedback.is_internal" 
                    :value="$t('admin.internal_note')" 
                    severity="secondary" 
                    class="text-xs"
                  />
                  <span class="text-xs text-slate-500">{{ formatDate(feedback.created_at) }}</span>
                </div>
              </div>
              <pre class="text-sm text-slate-800 whitespace-pre-wrap">{{ feedback.message }}</pre>
            </div>
          </div>
        </div>
      </div>

      <template #footer>
        <Button 
          :label="$t('common.close')" 
          severity="secondary" 
          @click="showPrintDetailsDialog = false" 
        />
      </template>
    </Dialog>
  </PageWrapper>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useI18n } from 'vue-i18n'
import { useToast } from 'primevue/usetoast'
import { supabase } from '@/lib/supabase'
import { useAdminBatchesStore, useAdminPrintRequestsStore, useAdminDashboardStore } from '@/stores/admin'

// PrimeVue Components
import Button from 'primevue/button'
import DataTable from 'primevue/datatable'
import Column from 'primevue/column'
import InputText from 'primevue/inputtext'
import InputNumber from 'primevue/inputnumber'
import Textarea from 'primevue/textarea'
import Select from 'primevue/select'
import Tag from 'primevue/tag'
import ProgressSpinner from 'primevue/progressspinner'
import Tabs from 'primevue/tabs'
import TabList from 'primevue/tablist'
import Tab from 'primevue/tab'
import TabPanels from 'primevue/tabpanels'
import TabPanel from 'primevue/tabpanel'
import IconField from 'primevue/iconfield'
import InputIcon from 'primevue/inputicon'
import Dialog from 'primevue/dialog'
import PageWrapper from '@/components/Layout/PageWrapper.vue'

const { t } = useI18n()
const toast = useToast()
const batchesStore = useAdminBatchesStore()
const printRequestsStore = useAdminPrintRequestsStore()
const dashboardStore = useAdminDashboardStore()

// Tab state
const activeTab = ref('all-batches')
const isRefreshing = ref(false)

// ========== All Batches Tab State ==========
const emailSearch = ref('')
const paymentStatusFilter = ref(null)

const paymentStatusOptions = computed(() => [
  { label: t('batches.paid'), value: 'PAID' },
  { label: t('batches.admin_issued'), value: 'FREE' }
])

const hasBatchFilters = computed(() => {
  return emailSearch.value.trim() !== '' || paymentStatusFilter.value
})

// ========== Print Requests Tab State ==========
const printSearchQuery = ref('')
const printStatusFilter = ref(null)
const showPrintDetailsDialog = ref(false)
const selectedPrintRequest = ref(null)
const selectedPrintRequestFeedbacks = ref([])

const printStatusOptions = computed(() => [
  { label: t('admin.all_statuses'), value: null },
  { label: t('print.submitted'), value: 'SUBMITTED' },
  { label: t('print.in_production'), value: 'PROCESSING' },
  { label: t('print.shipped'), value: 'SHIPPED' },
  { label: t('print.delivered'), value: 'COMPLETED' },
  { label: t('print.cancelled'), value: 'CANCELLED' }
])

const printStatusUpdateOptions = computed(() => [
  { label: t('print.submitted'), value: 'SUBMITTED' },
  { label: t('print.in_production'), value: 'PROCESSING' },
  { label: t('print.shipped'), value: 'SHIPPED' },
  { label: t('print.delivered'), value: 'COMPLETED' },
  { label: t('print.cancelled'), value: 'CANCELLED' }
])

const hasPrintFilters = computed(() => {
  return !!(printSearchQuery.value || printStatusFilter.value)
})

const pendingPrintRequestsCount = computed(() => {
  return printRequestsStore.printRequests.filter(r => 
    r.status === 'SUBMITTED' || r.status === 'PROCESSING'
  ).length
})

// ========== Issue Batch Tab State ==========
const form = ref({
  userEmail: '',
  cardId: null,
  cardsCount: 100,
  reason: ''
})

const errors = ref({
  userEmail: '',
  cardId: '',
  cardsCount: '',
  reason: ''
})

const selectedUser = ref(null)
const userCards = ref([])
const isSearchingUser = ref(false)
const isLoadingCards = ref(false)
const isSubmitting = ref(false)
const recentIssuances = ref([])

// Filter to only show physical cards (batches are only for physical cards)
const physicalUserCards = computed(() => {
  return userCards.value.filter(card => card.billing_type === 'physical')
})

const isFormComplete = computed(() => {
  return (
    selectedUser.value &&
    form.value.cardId &&
    form.value.cardsCount > 0 &&
    form.value.cardsCount <= 10000 &&
    form.value.reason.trim()
  )
})

const selectedCardName = computed(() => {
  if (!form.value.cardId) return ''
  const card = userCards.value.find(c => c.id === form.value.cardId)
  return card ? card.card_name : ''
})

// ========== All Batches Methods ==========
const applyBatchFilters = async () => {
  try {
    await batchesStore.fetchAllBatches(
      emailSearch.value.trim() || undefined,
      paymentStatusFilter.value || undefined
    )
  } catch (error) {
    toast.add({
      severity: 'error',
      summary: t('common.error'),
      detail: t('batches.failed_to_apply_filters'),
      life: 3000
    })
  }
}

const clearBatchFilters = async () => {
  emailSearch.value = ''
  paymentStatusFilter.value = null
  await applyBatchFilters()
}

// ========== Print Requests Methods ==========
const applyPrintFilters = async () => {
  try {
    await printRequestsStore.fetchAllPrintRequests(
      printStatusFilter.value,
      printSearchQuery.value.trim() || undefined
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

const clearPrintFilters = async () => {
  printSearchQuery.value = ''
  printStatusFilter.value = null
  await applyPrintFilters()
}

const viewPrintDetails = async (request) => {
  selectedPrintRequest.value = request
  selectedPrintRequestFeedbacks.value = []
  showPrintDetailsDialog.value = true
  
  // Fetch feedbacks for this print request
  try {
    const feedbacks = await printRequestsStore.fetchPrintRequestFeedbacks(request.id)
    selectedPrintRequestFeedbacks.value = feedbacks
  } catch (error) {
    console.warn('Could not load feedbacks:', error)
  }
}

const updatePrintStatus = async (requestId, newStatus) => {
  try {
    await printRequestsStore.updatePrintRequestStatus(requestId, newStatus)
    toast.add({
      severity: 'success',
      summary: t('common.success'),
      detail: t('admin.status_updated_successfully'),
      life: 3000
    })
    await applyPrintFilters()
  } catch (error) {
    toast.add({
      severity: 'error',
      summary: t('common.error'),
      detail: t('admin.failed_to_update_status'),
      life: 3000
    })
  }
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

const getPrintStatusLabel = (status) => {
  switch (status) {
    case 'SUBMITTED': return t('print.submitted')
    case 'PROCESSING': return t('print.in_production')
    case 'SHIPPED': return t('print.shipped')
    case 'COMPLETED': return t('print.delivered')
    case 'CANCELLED': return t('print.cancelled')
    default: return status
  }
}

// ========== Common Methods ==========
const refreshData = async () => {
  isRefreshing.value = true
  try {
    await Promise.all([
      applyBatchFilters(),
      applyPrintFilters(),
      dashboardStore.fetchDashboardStats()
    ])
  } finally {
    isRefreshing.value = false
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

const getPaymentStatusSeverity = (status) => {
  switch (status) {
    case 'PAID': return 'success'
    case 'FREE': return 'info'
    default: return 'secondary'
  }
}

const getPaymentStatusLabel = (status) => {
  switch (status) {
    case 'PAID': return t('batches.paid')
    case 'FREE': return t('batches.admin_issued')
    default: return status
  }
}

// ========== Issue Batch Methods ==========
const handleUserEmailChange = () => {
  errors.value.userEmail = ''
  selectedUser.value = null
  userCards.value = []
  form.value.cardId = null
}

const searchUser = async () => {
  if (!form.value.userEmail.trim()) {
    errors.value.userEmail = t('common.required')
    return
  }

  isSearchingUser.value = true
  errors.value.userEmail = ''

  try {
    const { data, error } = await supabase.rpc('admin_get_user_by_email', {
      p_email: form.value.userEmail.trim()
    })

    if (error) throw error

    if (data && data.length > 0) {
      selectedUser.value = data[0]
      await loadUserCards()
    } else {
      errors.value.userEmail = t('admin.user_not_found')
    }
  } catch (error) {
    console.error('Error searching user:', error)
    errors.value.userEmail = error.message || t('admin.failed_to_search_user')
    toast.add({
      severity: 'error',
      summary: t('admin.search_failed'),
      detail: error.message || t('admin.failed_to_search_user'),
      life: 5000
    })
  } finally {
    isSearchingUser.value = false
  }
}

const loadUserCards = async () => {
  if (!selectedUser.value) return

  isLoadingCards.value = true
  errors.value.cardId = ''

  try {
    const { data, error } = await supabase.rpc('admin_get_user_cards', {
      p_user_id: selectedUser.value.user_id
    })

    if (error) throw error

    userCards.value = data || []

    // Filter and check for physical cards
    if (physicalUserCards.value.length === 0) {
      errors.value.cardId = t('admin.user_has_no_physical_cards')
    }
  } catch (error) {
    console.error('Error loading user cards:', error)
    errors.value.cardId = t('admin.failed_to_load_user_cards')
    toast.add({
      severity: 'error',
      summary: t('common.error'),
      detail: t('admin.failed_to_load_user_cards'),
      life: 5000
    })
  } finally {
    isLoadingCards.value = false
  }
}

const validateForm = () => {
  let isValid = true
  errors.value = {
    userEmail: '',
    cardId: '',
    cardsCount: '',
    reason: ''
  }

  if (!selectedUser.value) {
    errors.value.userEmail = t('admin.please_search_select_user')
    isValid = false
  }

  if (!form.value.cardId) {
    errors.value.cardId = t('admin.please_select_card')
    isValid = false
  }

  if (!form.value.cardsCount || form.value.cardsCount < 1) {
    errors.value.cardsCount = t('admin.at_least_1_card')
    isValid = false
  } else if (form.value.cardsCount > 10000) {
    errors.value.cardsCount = t('admin.max_10000_cards')
    isValid = false
  }

  if (!form.value.reason.trim()) {
    errors.value.reason = t('common.required')
    isValid = false
  } else if (form.value.reason.trim().length < 10) {
    errors.value.reason = t('admin.reason_min_10_chars')
    isValid = false
  }

  return isValid
}

const handleSubmit = async () => {
  if (!validateForm()) return

  isSubmitting.value = true

  try {
    const batchId = await batchesStore.issueBatch(
      form.value.userEmail.trim(),
      form.value.cardId,
      form.value.cardsCount,
      form.value.reason.trim()
    )

    // Add to recent issuances
    recentIssuances.value.unshift({
      id: batchId,
      userEmail: form.value.userEmail,
      cardsCount: form.value.cardsCount,
      timestamp: new Date()
    })

    // Keep only last 5
    if (recentIssuances.value.length > 5) {
      recentIssuances.value = recentIssuances.value.slice(0, 5)
    }

    toast.add({
      severity: 'success',
      summary: t('common.success'),
      detail: t('admin.batch_issued_successfully'),
      life: 5000
    })

    // Refresh batches list
    await applyBatchFilters()

    // Reset form
    resetForm()
  } catch (error) {
    console.error('Error issuing batch:', error)
    toast.add({
      severity: 'error',
      summary: t('common.error'),
      detail: error.message || t('admin.failed_to_issue_batch'),
      life: 5000
    })
  } finally {
    isSubmitting.value = false
  }
}

const resetForm = () => {
  form.value = {
    userEmail: '',
    cardId: null,
    cardsCount: 100,
    reason: ''
  }
  errors.value = {
    userEmail: '',
    cardId: '',
    cardsCount: '',
    reason: ''
  }
  selectedUser.value = null
  userCards.value = []
}

const formatTimeAgo = (date) => {
  const now = new Date()
  const past = new Date(date)
  const diffMs = now - past
  const diffMins = Math.floor(diffMs / (60 * 1000))
  const diffHours = Math.floor(diffMs / (60 * 60 * 1000))

  if (diffMins < 1) return t('common.just_now')
  if (diffMins < 60) return t('common.minutes_ago', { count: diffMins })
  if (diffHours < 24) return t('common.hours_ago', { count: diffHours })
  return past.toLocaleDateString()
}

// Lifecycle
onMounted(async () => {
  await refreshData()
})
</script>

<style scoped>
:deep(.p-datatable .p-datatable-tbody > tr:hover) {
  background-color: #f8fafc;
}
</style>
