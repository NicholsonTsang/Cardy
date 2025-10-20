<template>
  <PageWrapper :title="$t('credits.title')" :description="$t('credits.description')">
    <template #actions>
      <Button 
        @click="showPurchaseDialog = true" 
        icon="pi pi-wallet" 
        :label="$t('credits.purchaseCredits')"
        severity="primary"
        size="large"
      />
    </template>

    <div class="space-y-6">

      <!-- Balance Overview Cards -->
      <div class="grid grid-cols-1 lg:grid-cols-3 gap-4">
        <!-- Current Balance -->
        <div class="bg-white rounded-xl shadow-lg border border-slate-200 p-4 hover:shadow-xl transition-all duration-200">
          <div class="flex items-start gap-4">
            <div class="w-12 h-12 rounded-lg bg-gradient-to-br from-blue-500 to-blue-600 flex items-center justify-center shadow-lg flex-shrink-0">
              <i class="pi pi-wallet text-white text-xl"></i>
            </div>
            <div class="flex-1 min-w-0">
              <p class="text-xs font-medium text-slate-600 mb-1 truncate">{{ $t('credits.currentBalance') }}</p>
              <h3 class="text-2xl font-bold text-slate-900 truncate">{{ creditStore.formattedBalance }}</h3>
              <div class="mt-1">
                <span class="text-xs text-slate-500 truncate block">{{ $t('credits.availableCredits') }}</span>
              </div>
              
              <!-- Low Balance Warning -->
              <Message 
                v-if="parseFloat(creditStore.formattedBalance) < 50" 
                severity="warn" 
                :closable="false"
                class="mt-2"
              >
                <span class="text-xs">Low balance</span>
              </Message>
            </div>
          </div>
        </div>

        <!-- Total Purchased -->
        <div class="bg-white rounded-xl shadow-lg border border-slate-200 p-4 hover:shadow-xl transition-all duration-200">
          <div class="flex items-start gap-4">
            <div class="w-12 h-12 rounded-lg bg-gradient-to-br from-green-500 to-green-600 flex items-center justify-center shadow-lg flex-shrink-0">
              <i class="pi pi-arrow-up text-white text-xl"></i>
            </div>
            <div class="flex-1 min-w-0">
              <p class="text-xs font-medium text-slate-600 mb-1 truncate">{{ $t('credits.totalPurchased') }}</p>
              <h3 class="text-2xl font-bold text-slate-900 truncate">{{ statistics?.total_purchased?.toFixed(2) || '0.00' }}</h3>
              <div class="mt-1">
                <span class="text-xs text-slate-500 truncate block">
                  {{ $t('credits.monthlyPurchases') }}: 
                  <span class="font-semibold">{{ statistics?.monthly_purchases?.toFixed(2) || '0.00' }}</span>
                </span>
              </div>
            </div>
          </div>
        </div>

        <!-- Total Consumed -->
        <div class="bg-white rounded-xl shadow-lg border border-slate-200 p-4 hover:shadow-xl transition-all duration-200">
          <div class="flex items-start gap-4">
            <div class="w-12 h-12 rounded-lg bg-gradient-to-br from-orange-500 to-orange-600 flex items-center justify-center shadow-lg flex-shrink-0">
              <i class="pi pi-arrow-down text-white text-xl"></i>
            </div>
            <div class="flex-1 min-w-0">
              <p class="text-xs font-medium text-slate-600 mb-1 truncate">{{ $t('credits.totalConsumed') }}</p>
              <h3 class="text-2xl font-bold text-slate-900 truncate">{{ statistics?.total_consumed?.toFixed(2) || '0.00' }}</h3>
              <div class="mt-1">
                <span class="text-xs text-slate-500 truncate block">
                  {{ $t('credits.monthlyConsumption') }}: 
                  <span class="font-semibold">{{ statistics?.monthly_consumption?.toFixed(2) || '0.00' }}</span>
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- History Tables -->
      <div class="bg-white rounded-xl shadow-lg border border-slate-200 flex flex-col overflow-hidden">
        <Tabs :value="activeTab" @update:value="(value) => activeTab = String(value)" class="flex-1 flex flex-col">
          <TabList class="flex-shrink-0 border-b border-slate-200 bg-white px-6">
            <Tab value="0" class="px-4 py-3 font-medium text-sm text-slate-600 hover:text-slate-900 transition-colors">
              <i class="pi pi-list mr-2"></i>
              {{ $t('credits.recentTransactions') }}
              <Chip v-if="creditStore.transactions?.length" :label="String(creditStore.transactions.length)" class="ml-2" />
            </Tab>
            <Tab value="1" class="px-4 py-3 font-medium text-sm text-slate-600 hover:text-slate-900 transition-colors">
              <i class="pi pi-shopping-cart mr-2"></i>
              {{ $t('credits.purchaseHistory') }}
              <Chip v-if="creditStore.purchases?.length" :label="String(creditStore.purchases.length)" class="ml-2" />
            </Tab>
            <Tab value="2" class="px-4 py-3 font-medium text-sm text-slate-600 hover:text-slate-900 transition-colors">
              <i class="pi pi-chart-line mr-2"></i>
              {{ $t('credits.consumptionHistory') }}
              <Chip v-if="creditStore.consumptions?.length" :label="String(creditStore.consumptions.length)" class="ml-2" />
            </Tab>
          </TabList>
          <TabPanels class="flex-1 overflow-hidden bg-slate-50">
            <TabPanel value="0" class="h-full">
              <div class="h-full overflow-y-auto p-6">
                <DataTable 
                  :value="creditStore.transactions" 
                  :loading="creditStore.loading"
                  paginator 
                  :rows="10" 
                  :rowsPerPageOptions="[10, 20, 50]"
                  showGridlines
                  responsiveLayout="scroll"
                >
                  <template #empty>
                    <div class="text-center py-12">
                      <i class="pi pi-inbox text-6xl text-slate-400 mb-4"></i>
                      <p class="text-lg font-medium text-slate-900 mb-2">{{ $t('messages.no_data_available') }}</p>
                      <p class="text-slate-600">Transactions will appear here once you make a purchase or use credits</p>
                    </div>
                  </template>
                  <template #loading>
                    <div class="flex items-center justify-center py-12">
                      <ProgressSpinner style="width: 50px; height: 50px" strokeWidth="4" />
                    </div>
                  </template>
                  
                  <Column field="created_at" :header="$t('common.date')" sortable style="min-width: 180px">
                    <template #body="{ data }">
                      <span class="text-sm text-slate-600">{{ formatDate(data.created_at) }}</span>
                    </template>
                  </Column>
                  <Column field="type" :header="$t('common.type')" sortable style="min-width: 140px">
                    <template #body="{ data }">
                      <Tag 
                        :severity="getTransactionTypeSeverity(data.type)" 
                        :value="$t(`credits.type.${data.type}`)"
                        :icon="getTransactionTypeIcon(data.type)"
                      />
                    </template>
                  </Column>
                  <Column field="amount" :header="$t('credits.amount')" sortable style="min-width: 130px">
                    <template #body="{ data }">
                      <div class="flex items-center gap-2 font-semibold text-base">
                        <i 
                          :class="[
                            'pi',
                            data.type === 'purchase' ? 'pi-plus-circle text-green-600' : 'pi-minus-circle text-red-600'
                          ]"
                        ></i>
                        <span :class="data.type === 'purchase' ? 'text-green-600' : 'text-red-600'">
                          {{ data.type === 'purchase' ? '+' : '-' }}{{ data.amount.toFixed(2) }}
                        </span>
                      </div>
                    </template>
                  </Column>
                  <Column field="balance_after" :header="$t('credits.balanceAfter')" sortable style="min-width: 140px">
                    <template #body="{ data }">
                      <Chip :label="data.balance_after.toFixed(2)" icon="pi pi-wallet" />
                    </template>
                  </Column>
                  <Column field="description" :header="$t('common.description')" style="min-width: 250px">
                    <template #body="{ data }">
                      <span class="text-slate-600">{{ data.description || '-' }}</span>
                    </template>
                  </Column>
                </DataTable>
              </div>
            </TabPanel>

            <TabPanel value="1" class="h-full">
              <div class="h-full overflow-y-auto p-6">
                <DataTable 
                  :value="creditStore.purchases" 
                  :loading="creditStore.loading"
                  paginator 
                  :rows="10" 
                  :rowsPerPageOptions="[10, 20, 50]"
                  showGridlines
                  responsiveLayout="scroll"
                >
                  <template #empty>
                    <div class="text-center py-12">
                      <i class="pi pi-shopping-bag text-6xl text-slate-400 mb-4"></i>
                      <p class="text-lg font-medium text-slate-900 mb-2">{{ $t('messages.no_data_available') }}</p>
                      <p class="text-slate-600 mb-4">Your purchase history will appear here</p>
                      <Button 
                        :label="$t('credits.purchaseCredits')" 
                        icon="pi pi-plus" 
                        @click="showPurchaseDialog = true"
                      />
                    </div>
                  </template>
                  
                  <Column field="created_at" :header="$t('common.date')" sortable style="min-width: 180px">
                    <template #body="{ data }">
                      <span class="text-sm text-slate-600">{{ formatDate(data.created_at) }}</span>
                    </template>
                  </Column>
                  <Column field="credits_amount" :header="$t('credits.creditsAmount')" sortable style="min-width: 140px">
                    <template #body="{ data }">
                      <Chip :label="data.credits_amount.toFixed(2)" icon="pi pi-bolt" severity="success" />
                    </template>
                  </Column>
                  <Column field="amount_usd" :header="$t('credits.amountUSD')" sortable style="min-width: 130px">
                    <template #body="{ data }">
                      <div class="flex items-center gap-2 font-semibold text-base">
                        <i class="pi pi-dollar text-green-600"></i>
                        <span>${{ data.amount_usd.toFixed(2) }}</span>
                      </div>
                    </template>
                  </Column>
                  <Column field="status" :header="$t('common.status')" sortable style="min-width: 130px">
                    <template #body="{ data }">
                      <Tag 
                        :severity="getPurchaseStatusSeverity(data.status)" 
                        :value="$t(`credits.status.${data.status}`)"
                        :icon="getPurchaseStatusIcon(data.status)"
                      />
                    </template>
                  </Column>
                  <Column field="receipt_url" :header="$t('credits.receipt')" style="min-width: 120px">
                    <template #body="{ data }">
                      <Button 
                        v-if="data.receipt_url" 
                        icon="pi pi-file-pdf" 
                        label="Receipt"
                        text 
                        size="small"
                        severity="secondary"
                        @click="openReceipt(data.receipt_url)"
                      />
                      <span v-else class="text-slate-400 text-sm">-</span>
                    </template>
                  </Column>
                  <Column field="completed_at" :header="$t('credits.completedAt')" sortable style="min-width: 180px">
                    <template #body="{ data }">
                      <span v-if="data.completed_at" class="text-sm text-slate-600">
                        {{ formatDate(data.completed_at) }}
                      </span>
                      <span v-else class="text-slate-400">-</span>
                    </template>
                  </Column>
                </DataTable>
              </div>
            </TabPanel>

            <TabPanel value="2" class="h-full">
              <div class="h-full overflow-y-auto p-6">
                <DataTable 
                  :value="creditStore.consumptions" 
                  :loading="creditStore.loading"
                  paginator 
                  :rows="10" 
                  :rowsPerPageOptions="[10, 20, 50]"
                  showGridlines
                  responsiveLayout="scroll"
                >
                  <template #empty>
                    <div class="text-center py-12">
                      <i class="pi pi-chart-bar text-6xl text-slate-400 mb-4"></i>
                      <p class="text-lg font-medium text-slate-900 mb-2">{{ $t('messages.no_data_available') }}</p>
                      <p class="text-slate-600">Credit consumption records will appear here after issuing batches or translating cards</p>
                    </div>
                  </template>
                  
                  <Column field="created_at" :header="$t('common.date')" sortable style="min-width: 180px">
                    <template #body="{ data }">
                      <span class="text-sm text-slate-600">{{ formatDate(data.created_at) }}</span>
                    </template>
                  </Column>
                  <Column field="consumption_type" :header="$t('common.type')" sortable style="min-width: 180px">
                    <template #body="{ data }">
                      <Tag 
                        :value="getConsumptionTypeLabel(data.consumption_type)" 
                        :icon="getConsumptionTypeIcon(data.consumption_type)" 
                        :severity="getConsumptionTypeSeverity(data.consumption_type)" 
                      />
                    </template>
                  </Column>
                  <Column field="card_name" :header="$t('common.card')" style="min-width: 200px">
                    <template #body="{ data }">
                      <div class="flex items-center gap-2">
                        <i class="pi pi-id-card text-blue-500"></i>
                        <span class="font-medium text-slate-900">{{ data.card_name || '-' }}</span>
                      </div>
                    </template>
                  </Column>
                  <Column field="batch_name" :header="$t('batch.batch')" style="min-width: 200px">
                    <template #body="{ data }">
                      <span class="text-slate-600">{{ data.batch_name || '-' }}</span>
                    </template>
                  </Column>
                  <Column field="quantity" :header="$t('common.quantity')" sortable style="min-width: 140px">
                    <template #body="{ data }">
                      <Chip 
                        :label="`${data.quantity} ${getQuantityUnit(data.consumption_type)}`" 
                        icon="pi pi-hashtag" 
                      />
                    </template>
                  </Column>
                  <Column field="total_credits" :header="$t('credits.totalCredits')" sortable style="min-width: 140px">
                    <template #body="{ data }">
                      <div class="flex items-center gap-2 font-semibold text-base text-red-600">
                        <i class="pi pi-minus-circle"></i>
                        <span>{{ data.total_credits.toFixed(2) }}</span>
                      </div>
                    </template>
                  </Column>
                  <Column field="description" :header="$t('common.description')" style="min-width: 250px">
                    <template #body="{ data }">
                      <span class="text-slate-600">{{ data.description || '-' }}</span>
                    </template>
                  </Column>
                </DataTable>
              </div>
            </TabPanel>
          </TabPanels>
        </Tabs>
      </div>
    </div>
  </PageWrapper>

  <!-- Enhanced Purchase Credits Dialog -->
    <Dialog 
      v-model:visible="showPurchaseDialog" 
      modal 
      :closable="!purchaseLoading"
      :style="{ width: '600px' }"
      class="purchase-dialog"
    >
      <template #header>
        <div class="flex items-center gap-3">
          <div class="p-3 bg-green-50 rounded-full">
            <i class="pi pi-wallet text-2xl text-green-600"></i>
          </div>
          <div>
            <h3 class="text-xl font-bold text-slate-900">{{ $t('credits.purchaseCredits') }}</h3>
            <p class="text-sm text-slate-500 mt-1">1 Credit = $1 USD</p>
          </div>
        </div>
      </template>

      <div class="space-y-6 py-4">
        <!-- Popular Amounts -->
        <div>
          <label class="block text-sm font-semibold text-slate-700 mb-4">
            {{ $t('credits.selectAmount') }}
          </label>
          <div class="grid grid-cols-3 gap-3">
            <div
              v-for="amount in creditAmounts"
              :key="amount"
              @click="selectAmount(amount)"
              :class="[
                'credit-amount-card',
                { 'selected': selectedAmount === amount }
              ]"
            >
              <div class="flex flex-col items-center justify-center h-full">
                <div class="text-2xl font-bold mb-1">{{ amount }}</div>
                <div class="text-xs text-slate-500 mb-2">{{ $t('credits.credits') }}</div>
                <Chip :label="`$${amount}`" size="small" severity="success" />
              </div>
            </div>
          </div>
        </div>

        <Divider>
          <span class="text-slate-400 text-sm">{{ $t('common.or') }}</span>
        </Divider>

        <!-- Custom Amount -->
        <div>
          <label class="block text-sm font-semibold text-slate-700 mb-3">
            {{ $t('credits.customAmount') }}
          </label>
          <div class="flex gap-3">
            <InputNumber 
              v-model="customAmount" 
              :min="10" 
              :max="10000"
              :step="10"
              :placeholder="$t('credits.enterAmount')"
              class="flex-1"
              size="large"
              prefix="$"
            />
            <Button
              :label="$t('common.use')"
              :disabled="!customAmount || customAmount < 10"
              @click="selectAmount(customAmount)"
              icon="pi pi-check"
              size="large"
            />
          </div>
          <small class="text-slate-500 mt-2 block">Minimum 10 credits, Maximum 10,000 credits</small>
        </div>

        <!-- Summary Card -->
        <Transition name="slide-fade">
          <div v-if="selectedAmount" class="summary-card">
            <div class="flex items-center justify-between mb-4">
              <span class="text-slate-600">{{ $t('credits.youWillReceive') }}</span>
              <div class="flex items-center gap-2">
                <i class="pi pi-bolt text-yellow-500 text-xl"></i>
                <span class="text-2xl font-bold text-slate-900">{{ selectedAmount }}</span>
                <span class="text-slate-500">{{ $t('credits.credits') }}</span>
              </div>
            </div>
            <Divider />
            <div class="flex items-center justify-between">
              <span class="text-lg font-semibold text-slate-900">{{ $t('credits.totalToPay') }}</span>
              <span class="text-3xl font-bold text-blue-600">${{ selectedAmount }}.00</span>
            </div>
            <div class="mt-4 p-3 bg-blue-50 rounded-lg flex items-start gap-3">
              <i class="pi pi-shield text-blue-600 mt-0.5 flex-shrink-0"></i>
              <p class="text-sm text-blue-800 leading-relaxed">
                <strong>Secure Payment:</strong> All transactions are processed through Stripe, a trusted third-party payment gateway used by millions worldwide. Your payment information is encrypted and never stored on our servers.
              </p>
            </div>
          </div>
        </Transition>
      </div>

      <template #footer>
        <div class="flex justify-between items-center w-full">
          <Button 
            :label="$t('common.cancel')" 
            @click="closePurchaseDialog" 
            text 
            size="large"
            :disabled="purchaseLoading"
          />
          <Button 
            :label="$t('credits.proceedToPayment')" 
            @click="proceedToPayment" 
            :disabled="!selectedAmount || purchaseLoading"
            :loading="purchaseLoading"
            icon="pi pi-arrow-right"
            iconPos="right"
            size="large"
            severity="primary"
          />
        </div>
      </template>
    </Dialog>
</template>

<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { useI18n } from 'vue-i18n'
import { useCreditStore } from '@/stores/credits'
import { useToast } from 'primevue/usetoast'
import { createCreditPurchaseCheckout } from '@/utils/stripeCheckout'
import Button from 'primevue/button'
import DataTable from 'primevue/datatable'
import Column from 'primevue/column'
import Tabs from 'primevue/tabs'
import TabList from 'primevue/tablist'
import Tab from 'primevue/tab'
import TabPanels from 'primevue/tabpanels'
import TabPanel from 'primevue/tabpanel'
import Dialog from 'primevue/dialog'
import Tag from 'primevue/tag'
import InputNumber from 'primevue/inputnumber'
import Message from 'primevue/message'
import Chip from 'primevue/chip'
import Divider from 'primevue/divider'
import ProgressSpinner from 'primevue/progressspinner'
import PageWrapper from '@/components/Layout/PageWrapper.vue'

const { t } = useI18n()
const toast = useToast()
const creditStore = useCreditStore()

const activeTab = ref('0')
const showPurchaseDialog = ref(false)
const selectedAmount = ref(0)
const customAmount = ref<number | null>(null)
const purchaseLoading = ref(false)

const creditAmounts = [50, 100, 200, 500, 1000, 2000]

const statistics = computed(() => creditStore.statistics)

onMounted(async () => {
  await Promise.all([
    creditStore.fetchCreditBalance(),
    creditStore.fetchCreditStatistics(),
    creditStore.fetchTransactions(),
    creditStore.fetchPurchases(),
    creditStore.fetchConsumptions()
  ])
})

function formatDate(dateString: string) {
  return new Date(dateString).toLocaleDateString(undefined, {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  })
}

function getTransactionTypeSeverity(type: string) {
  switch (type) {
    case 'purchase': return 'success'
    case 'consumption': return 'danger'
    case 'refund': return 'warn'
    case 'adjustment': return 'info'
    default: return undefined
  }
}

function getTransactionTypeIcon(type: string) {
  switch (type) {
    case 'purchase': return 'pi-shopping-cart'
    case 'consumption': return 'pi-arrow-down'
    case 'refund': return 'pi-replay'
    case 'adjustment': return 'pi-wrench'
    default: return 'pi-circle'
  }
}

function getPurchaseStatusSeverity(status: string) {
  switch (status) {
    case 'completed': return 'success'
    case 'pending': return 'warn'
    case 'failed': return 'danger'
    case 'refunded': return 'info'
    default: return undefined
  }
}

function getPurchaseStatusIcon(status: string) {
  switch (status) {
    case 'completed': return 'pi-check-circle'
    case 'pending': return 'pi-clock'
    case 'failed': return 'pi-times-circle'
    case 'refunded': return 'pi-replay'
    default: return 'pi-circle'
  }
}

function getConsumptionTypeLabel(type: string) {
  const { t } = useI18n()
  const key = `credits.consumptionType.${type}`
  // Try to get translation, fallback to type or 'Unknown'
  return t(key, type || 'Unknown')
}

function getConsumptionTypeIcon(type: string) {
  switch (type) {
    case 'batch_issuance': return 'pi-box'
    case 'translation': return 'pi-language'
    case 'single_card': return 'pi-id-card'
    default: return 'pi-circle'
  }
}

function getConsumptionTypeSeverity(type: string) {
  switch (type) {
    case 'batch_issuance': return 'info'
    case 'translation': return 'success'
    case 'single_card': return 'warn'
    default: return undefined
  }
}

function getQuantityUnit(type: string) {
  switch (type) {
    case 'batch_issuance': return 'cards'
    case 'translation': return 'languages'
    case 'single_card': return 'card'
    default: return 'units'
  }
}

function selectAmount(amount: number | null) {
  if (amount && amount >= 10) {
    selectedAmount.value = amount
    customAmount.value = null
  }
}

function closePurchaseDialog() {
  showPurchaseDialog.value = false
  selectedAmount.value = 0
  customAmount.value = null
}

function openReceipt(url: string) {
  window.open(url, '_blank')
}

async function proceedToPayment() {
  if (!selectedAmount.value) return

  purchaseLoading.value = true
  try {
    await createCreditPurchaseCheckout(selectedAmount.value, selectedAmount.value)
    toast.add({
      severity: 'info',
      summary: t('credits.redirectingToPayment'),
      detail: t('credits.redirectingToPaymentDetail'),
      life: 3000
    })
    closePurchaseDialog()
  } catch (error: any) {
    toast.add({
      severity: 'error',
      summary: t('common.error'),
      detail: error.message || t('credits.purchaseError'),
      life: 5000
    })
  } finally {
    purchaseLoading.value = false
  }
}
</script>

<style scoped>
/* Purchase Dialog */
.credit-amount-card {
  @apply p-4 border-2 rounded-lg cursor-pointer transition-all duration-200;
  @apply border-slate-200 hover:border-blue-400 hover:bg-blue-50;
  @apply flex items-center justify-center;
  min-height: 120px;
}

.credit-amount-card.selected {
  @apply border-blue-600 bg-blue-50;
  box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.2);
}

.credit-amount-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
}

.summary-card {
  @apply p-6 rounded-lg border-2 border-blue-200 bg-gradient-to-br from-blue-50 to-slate-50;
  animation: slideIn 0.3s ease-out;
}

/* Animations */
@keyframes slideIn {
  from {
    opacity: 0;
    transform: translateY(-10px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.slide-fade-enter-active {
  transition: all 0.3s ease-out;
}

.slide-fade-leave-active {
  transition: all 0.2s ease-in;
}

.slide-fade-enter-from {
  transform: translateY(-10px);
  opacity: 0;
}

.slide-fade-leave-to {
  transform: translateY(10px);
  opacity: 0;
}

/* Responsive Design */
@media (max-width: 768px) {
  .credit-amount-card {
    min-height: 100px;
  }
}

/* Empty State Styling */
.text-center {
  @apply flex flex-col items-center;
}
</style>
