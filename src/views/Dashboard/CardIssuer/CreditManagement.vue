<template>
  <PageWrapper :title="$t('credits.title')" :description="$t('credits.description')">
    <template #actions>
      <Button 
        @click="showPurchaseDialog = true" 
        icon="pi pi-plus" 
        :label="$t('credits.purchaseCredits')"
        severity="primary"
        class="w-full sm:w-auto"
        raised
      />
    </template>

    <div class="space-y-6">

      <!-- Balance Overview Cards -->
      <div class="grid grid-cols-1 md:grid-cols-3 gap-4 sm:gap-6">
        <!-- Current Balance -->
        <div class="bg-white rounded-2xl shadow-sm border border-slate-200 p-5 sm:p-6 relative overflow-hidden group hover:shadow-md transition-all">
          <div class="absolute top-0 right-0 p-4 opacity-10 group-hover:opacity-20 transition-opacity">
            <i class="pi pi-wallet text-5xl sm:text-6xl text-blue-500"></i>
          </div>
          <div class="relative z-10">
            <div class="text-xs sm:text-sm font-medium text-slate-500 uppercase tracking-wide mb-1">{{ $t('credits.currentBalance') }}</div>
            <div class="text-2xl sm:text-3xl font-bold text-slate-900 mb-2">${{ creditStore.formattedBalance }}</div>
            <div class="text-sm text-slate-600 flex items-center gap-1">
              <i class="pi pi-check-circle text-emerald-500"></i>
              {{ $t('credits.availableCredits') }}
            </div>

            <!-- Low Balance Warning -->
            <div v-if="parseFloat(creditStore.formattedBalance) < 50" class="mt-3 inline-flex items-center gap-2 px-3 py-1 rounded-full bg-amber-50 text-amber-700 text-xs font-medium border border-amber-100">
              <i class="pi pi-exclamation-triangle"></i>
              {{ $t('credits.lowBalance') }}
            </div>
          </div>
        </div>

        <!-- Total Purchased -->
        <div class="bg-white rounded-2xl shadow-sm border border-slate-200 p-5 sm:p-6 relative overflow-hidden group hover:shadow-md transition-all">
          <div class="absolute top-0 right-0 p-4 opacity-10 group-hover:opacity-20 transition-opacity">
            <i class="pi pi-arrow-circle-up text-5xl sm:text-6xl text-emerald-500"></i>
          </div>
          <div class="relative z-10">
            <div class="text-xs sm:text-sm font-medium text-slate-500 uppercase tracking-wide mb-1">{{ $t('credits.totalPurchased') }}</div>
            <div class="text-2xl sm:text-3xl font-bold text-slate-900 mb-2">${{ statistics?.total_purchased?.toFixed(2) || '0.00' }}</div>
            <div class="text-sm text-slate-600">
              <span class="font-medium text-emerald-600">+${{ statistics?.monthly_purchases?.toFixed(2) || '0.00' }}</span> {{ $t('credits.thisMonth') }}
            </div>
          </div>
        </div>

        <!-- Total Consumed -->
        <div class="bg-white rounded-2xl shadow-sm border border-slate-200 p-5 sm:p-6 relative overflow-hidden group hover:shadow-md transition-all">
          <div class="absolute top-0 right-0 p-4 opacity-10 group-hover:opacity-20 transition-opacity">
            <i class="pi pi-arrow-circle-down text-5xl sm:text-6xl text-orange-500"></i>
          </div>
          <div class="relative z-10">
            <div class="text-xs sm:text-sm font-medium text-slate-500 uppercase tracking-wide mb-1">{{ $t('credits.totalConsumed') }}</div>
            <div class="text-2xl sm:text-3xl font-bold text-slate-900 mb-2">${{ statistics?.total_consumed?.toFixed(2) || '0.00' }}</div>
            <div class="text-sm text-slate-600">
              <span class="font-medium text-orange-600">-${{ statistics?.monthly_consumption?.toFixed(2) || '0.00' }}</span> {{ $t('credits.thisMonth') }}
            </div>
          </div>
        </div>
      </div>

      <!-- History Tables -->
      <div class="bg-white rounded-2xl shadow-sm border border-slate-200 flex flex-col overflow-hidden">
        <Tabs :value="activeTab" @update:value="(value) => activeTab = String(value)" class="flex-1 flex flex-col">
          <TabList class="flex-shrink-0 border-b border-slate-200 bg-white px-2 sm:px-4 overflow-x-auto scrollbar-hide">
            <Tab value="0" class="flex items-center gap-1.5 sm:gap-2 px-3 sm:px-6 py-3 sm:py-4 font-medium text-slate-600 data-[p-active=true]:text-blue-600 data-[p-active=true]:border-b-2 data-[p-active=true]:border-blue-600 transition-all whitespace-nowrap text-sm sm:text-base">
              <i class="pi pi-list text-sm"></i>
              <span class="hidden sm:inline">{{ $t('credits.recentTransactions') }}</span>
              <span class="sm:hidden">{{ $t('credits.recent') }}</span>
            </Tab>
            <Tab value="1" class="flex items-center gap-1.5 sm:gap-2 px-3 sm:px-6 py-3 sm:py-4 font-medium text-slate-600 data-[p-active=true]:text-blue-600 data-[p-active=true]:border-b-2 data-[p-active=true]:border-blue-600 transition-all whitespace-nowrap text-sm sm:text-base">
              <i class="pi pi-shopping-cart text-sm"></i>
              <span class="hidden sm:inline">{{ $t('credits.purchaseHistory') }}</span>
              <span class="sm:hidden">{{ $t('credits.purchases') }}</span>
            </Tab>
            <Tab value="2" class="flex items-center gap-1.5 sm:gap-2 px-3 sm:px-6 py-3 sm:py-4 font-medium text-slate-600 data-[p-active=true]:text-blue-600 data-[p-active=true]:border-b-2 data-[p-active=true]:border-blue-600 transition-all whitespace-nowrap text-sm sm:text-base">
              <i class="pi pi-chart-pie text-sm"></i>
              <span class="hidden sm:inline">{{ $t('credits.consumptionHistory') }}</span>
              <span class="sm:hidden">{{ $t('credits.usage') }}</span>
            </Tab>
          </TabList>
          
          <TabPanels class="flex-1 bg-slate-50/50 p-0">
            <!-- Transactions Tab -->
            <TabPanel value="0" class="p-0">
              <DataTable
                :value="creditStore.transactions"
                :loading="creditStore.loading"
                paginator
                :rows="10"
                :rowsPerPageOptions="[10, 20, 50]"
                :showGridlines="false"
                stripedRows
                scrollable
                scrollHeight="flex"
                class="p-datatable-sm border-0"
              >
                <template #empty>
                  <div class="text-center py-16">
                    <div class="w-16 h-16 bg-slate-100 rounded-full flex items-center justify-center mx-auto mb-4">
                      <i class="pi pi-inbox text-2xl text-slate-400"></i>
                    </div>
                    <p class="text-lg font-medium text-slate-900">{{ $t('messages.no_data_available') }}</p>
                    <p class="text-slate-500 text-sm mt-1">{{ $t('credits.noTransactionsFound') }}</p>
                  </div>
                </template>
                
                <Column field="created_at" :header="$t('common.date')" sortable style="width: 180px">
                  <template #body="{ data }">
                    <div class="flex flex-col">
                      <span class="text-sm font-medium text-slate-700">{{ formatDate(data.created_at) }}</span>
                      <span class="text-xs text-slate-500">{{ formatTime(data.created_at) }}</span>
                    </div>
                  </template>
                </Column>
                
                <Column field="type" :header="$t('common.type')" sortable style="width: 140px">
                  <template #body="{ data }">
                    <Tag 
                      :severity="getTransactionTypeSeverity(data.type)" 
                      :value="$t(`credits.type.${data.type}`)"
                      rounded
                      class="px-3"
                    />
                  </template>
                </Column>
                
                <Column field="description" :header="$t('common.description')" style="min-width: 200px">
                  <template #body="{ data }">
                    <span class="text-sm text-slate-600">{{ data.description || '-' }}</span>
                  </template>
                </Column>
                
                <Column field="amount" :header="$t('credits.amount')" sortable style="width: 130px">
                  <template #body="{ data }">
                    <div class="font-bold font-mono" :class="getAmountColor(data)">
                      {{ formatTransactionAmount(data) }}
                    </div>
                  </template>
                </Column>

                <Column field="balance_after" :header="$t('credits.balanceAfter')" sortable style="width: 120px">
                  <template #body="{ data }">
                    <span class="text-sm font-medium text-slate-600">${{ data.balance_after.toFixed(2) }}</span>
                  </template>
                </Column>
              </DataTable>
            </TabPanel>

            <!-- Purchases Tab -->
            <TabPanel value="1" class="p-0">
              <DataTable 
                :value="creditStore.purchases" 
                :loading="creditStore.loading"
                paginator 
                :rows="10" 
                stripedRows
                class="p-datatable-sm border-0"
              >
                <template #empty>
                  <div class="text-center py-16">
                    <div class="w-16 h-16 bg-slate-100 rounded-full flex items-center justify-center mx-auto mb-4">
                      <i class="pi pi-shopping-cart text-2xl text-slate-400"></i>
                    </div>
                    <p class="text-lg font-medium text-slate-900 mb-2">{{ $t('credits.noPurchasesYet') }}</p>
                    <Button :label="$t('credits.purchaseCredits')" icon="pi pi-plus" size="small" @click="showPurchaseDialog = true" />
                  </div>
                </template>
                
                <Column field="created_at" :header="$t('common.date')" sortable>
                  <template #body="{ data }">
                    <span class="text-sm text-slate-700">{{ formatDate(data.created_at) }}</span>
                  </template>
                </Column>
                
                <Column field="credits_amount" :header="$t('credits.creditsAmount')" sortable>
                  <template #body="{ data }">
                    <div class="flex items-center gap-2">
                      <i class="pi pi-wallet text-slate-400"></i>
                      <span class="font-bold text-slate-800">${{ data.credits_amount.toFixed(2) }}</span>
                    </div>
                  </template>
                </Column>
                
                <Column field="amount_usd" :header="$t('credits.amountUSD')" sortable>
                  <template #body="{ data }">
                    <span class="text-sm font-medium text-slate-600">${{ data.amount_usd.toFixed(2) }}</span>
                  </template>
                </Column>
                
                <Column field="status" :header="$t('common.status')" sortable>
                  <template #body="{ data }">
                    <Tag :severity="getPurchaseStatusSeverity(data.status)" :value="$t(`credits.status.${data.status}`)" rounded />
                  </template>
                </Column>
                
                <Column :header="$t('credits.receipt')" style="width: 100px">
                  <template #body="{ data }">
                    <Button 
                      v-if="data.receipt_url" 
                      icon="pi pi-external-link" 
                      text 
                      rounded
                      size="small"
                      @click="openReceipt(data.receipt_url)"
                      v-tooltip.top="$t('credits.viewReceipt')"
                    />
                  </template>
                </Column>
              </DataTable>
            </TabPanel>

            <!-- Consumption Tab -->
            <TabPanel value="2" class="p-0">
              <DataTable 
                :value="creditStore.consumptions" 
                :loading="creditStore.loading"
                paginator 
                :rows="10" 
                stripedRows
                class="p-datatable-sm border-0"
              >
                <template #empty>
                  <div class="text-center py-16">
                    <div class="w-16 h-16 bg-slate-100 rounded-full flex items-center justify-center mx-auto mb-4">
                      <i class="pi pi-chart-pie text-2xl text-slate-400"></i>
                    </div>
                    <p class="text-lg font-medium text-slate-900">{{ $t('credits.noUsageRecords') }}</p>
                  </div>
                </template>
                
                <Column field="created_at" :header="$t('common.date')" sortable>
                  <template #body="{ data }">
                    <span class="text-sm text-slate-700">{{ formatDate(data.created_at) }}</span>
                  </template>
                </Column>
                
                <Column field="consumption_type" :header="$t('common.type')" sortable>
                  <template #body="{ data }">
                    <div class="flex items-center gap-2">
                      <div class="w-8 h-8 rounded-lg flex items-center justify-center" :class="getConsumptionTypeBg(data.consumption_type)">
                        <i :class="['pi text-sm', getConsumptionTypeIcon(data.consumption_type), getConsumptionTypeText(data.consumption_type)]"></i>
                      </div>
                      <span class="text-sm font-medium text-slate-700">{{ getConsumptionTypeLabel(data.consumption_type) }}</span>
                    </div>
                  </template>
                </Column>
                
                <Column field="quantity" :header="$t('common.quantity')" sortable>
                  <template #body="{ data }">
                    <span class="text-sm text-slate-600">
                      {{ data.quantity }} {{ getQuantityUnit(data.consumption_type) }}
                    </span>
                  </template>
                </Column>
                
                <Column field="total_credits" :header="$t('credits.totalCredits')" sortable>
                  <template #body="{ data }">
                    <span class="font-bold text-slate-700">${{ data.total_credits.toFixed(2) }}</span>
                  </template>
                </Column>
                
                <Column field="description" :header="$t('common.description')">
                  <template #body="{ data }">
                    <span class="text-sm text-slate-500">{{ data.description || '-' }}</span>
                  </template>
                </Column>
              </DataTable>
            </TabPanel>
          </TabPanels>
        </Tabs>
      </div>
    </div>
  </PageWrapper>

  <!-- Purchase Dialog -->
  <Dialog 
    v-model:visible="showPurchaseDialog" 
    modal 
    :header="$t('credits.purchaseCredits')"
    :style="{ width: '90vw', maxWidth: '600px' }"
    :draggable="false"
    class="p-0"
  >
    <div class="p-6">
      
      <!-- Info Banner -->
      <div class="mb-6 bg-blue-50 rounded-lg p-4 border border-blue-100 flex items-start gap-3">
        <i class="pi pi-info-circle text-blue-500 mt-0.5"></i>
        <div class="text-sm text-blue-900">
          <p class="font-semibold mb-1">{{ $t('credits.whatAreCreditsFor') }}</p>
          <ul class="list-disc pl-4 space-y-1 text-blue-800">
            <li><strong>{{ $t('credits.overageAccess') }}:</strong> {{ $t('credits.overageAccessDesc') }}</li>
          </ul>
        </div>
      </div>

      <!-- Quick Select -->
      <div class="mb-6">
        <label class="block text-sm font-medium text-slate-700 mb-3">{{ $t('credits.selectAmount') }}</label>
        <div class="grid grid-cols-3 gap-3">
          <button
            v-for="amount in creditAmounts"
            :key="amount"
            @click="selectAmount(amount)"
            class="relative p-4 rounded-xl border-2 transition-all duration-200 flex flex-col items-center justify-center gap-1 group"
            :class="selectedAmount === amount ? 'border-blue-500 bg-blue-50' : 'border-slate-200 hover:border-slate-300 hover:bg-slate-50'"
          >
            <span class="text-2xl font-bold" :class="selectedAmount === amount ? 'text-blue-700' : 'text-slate-700'">{{ amount }}</span>
            <span class="text-xs" :class="selectedAmount === amount ? 'text-blue-500' : 'text-slate-500'">{{ $t('common.credits') }}</span>
            <span class="text-xs font-semibold mt-1" :class="selectedAmount === amount ? 'text-blue-600' : 'text-emerald-600'">${{ amount }}</span>
            
            <div v-if="selectedAmount === amount" class="absolute top-2 right-2">
              <i class="pi pi-check-circle text-blue-500"></i>
            </div>
          </button>
        </div>
      </div>

      <!-- Custom Amount -->
      <div class="mb-8">
        <div class="relative">
          <Divider align="center" class="my-4">
            <span class="text-xs font-medium text-slate-400 uppercase tracking-wider">{{ $t('credits.orCustomAmount') }}</span>
          </Divider>
        </div>
        <div class="flex gap-2">
          <InputNumber 
            v-model="customAmount" 
            mode="currency" 
            currency="USD" 
            locale="en-US"
            :placeholder="$t('common.enter_amount')" 
            class="flex-1"
            :min="10"
            :max="10000"
            @input="handleCustomAmountInput"
          />
        </div>
      </div>

      <!-- Total & Action -->
      <div class="bg-slate-50 rounded-xl p-4 flex items-center justify-between border border-slate-100">
        <div>
          <div class="text-sm text-slate-500">{{ $t('credits.totalToPay') }}</div>
          <div class="text-2xl font-bold text-slate-900">${{ selectedAmount || 0 }}.00</div>
        </div>
        <Button 
          :label="purchaseLoading ? $t('credits.processing') : $t('credits.proceedToPayment')" 
          icon="pi pi-arrow-right" 
          iconPos="right"
          :loading="purchaseLoading"
          :disabled="!selectedAmount || purchaseLoading"
          @click="proceedToPayment"
          size="large"
        />
      </div>
    </div>
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
import Divider from 'primevue/divider'
import PageWrapper from '@/components/Layout/PageWrapper.vue'
import { formatDate } from '@/utils/formatters'

const { t } = useI18n()
const toast = useToast()
const creditStore = useCreditStore()

const activeTab = ref('0')
const showPurchaseDialog = ref(false)
const selectedAmount = ref(0)
const customAmount = ref<number | null>(null)
const purchaseLoading = ref(false)

const creditAmounts = [50, 100, 200, 500, 1000]

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

function formatTime(dateString: string) {
  return new Date(dateString).toLocaleTimeString(undefined, {
    hour: '2-digit',
    minute: '2-digit'
  })
}

function getAmountColor(data: { type: string; amount: number }) {
  if (data.type === 'purchase') return 'text-emerald-600'
  if (data.type === 'refund') return 'text-amber-600'
  return 'text-red-500'
}

function formatTransactionAmount(data: { type: string; amount: number }) {
  const absAmount = Math.abs(data.amount)
  if (data.type === 'purchase') return `+$${absAmount.toFixed(2)}`
  if (data.type === 'refund') return `-$${absAmount.toFixed(2)}`
  return `-$${absAmount.toFixed(2)}`
}

function getTransactionTypeSeverity(type: string) {
  switch (type) {
    case 'purchase': return 'success'
    case 'consumption': return 'danger'
    case 'refund': return 'warn'
    default: return 'secondary'
  }
}

function getPurchaseStatusSeverity(status: string) {
  switch (status) {
    case 'completed': return 'success'
    case 'pending': return 'warn'
    case 'failed': return 'danger'
    default: return 'secondary'
  }
}

function getConsumptionTypeLabel(type: string) {
  const key = `credits.consumptionType.${type}`
  const translated = t(key)
  return translated !== key ? translated : type || t('common.unknown')
}

function getConsumptionTypeIcon(type: string) {
  switch(type) {
    case 'subscription_overage_batch': return 'pi-users'
    case 'translation': return 'pi-language'
    case 'digital_scan': return 'pi-qrcode'
    case 'single_card': return 'pi-credit-card'
    default: return 'pi-circle'
  }
}

function getConsumptionTypeBg(type: string) {
  switch(type) {
    case 'subscription_overage_batch': return 'bg-amber-100'
    case 'translation': return 'bg-blue-100'
    case 'digital_scan': return 'bg-cyan-100'
    case 'single_card': return 'bg-indigo-100'
    default: return 'bg-slate-100'
  }
}

function getConsumptionTypeText(type: string) {
  switch(type) {
    case 'subscription_overage_batch': return 'text-amber-600'
    case 'translation': return 'text-blue-600'
    case 'digital_scan': return 'text-cyan-600'
    case 'single_card': return 'text-indigo-600'
    default: return 'text-slate-600'
  }
}

function getQuantityUnit(type: string) {
  switch(type) {
    case 'subscription_overage_batch': return t('credits.unit.access')
    case 'translation': return t('credits.unit.languages')
    case 'digital_scan': return t('credits.unit.scans')
    case 'single_card': return t('credits.unit.cards')
    default: return t('credits.unit.units')
  }
}

function selectAmount(amount: number | null) {
  if (amount && amount >= 10) {
    selectedAmount.value = amount
    // If selecting from quick buttons, clear custom input
    if (creditAmounts.includes(amount)) {
      customAmount.value = null
    }
  }
}

function handleCustomAmountInput(event: { value: number | string | undefined | null }) {
  const value = typeof event.value === 'number' ? event.value : null
  selectAmount(value)
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
    showPurchaseDialog.value = false
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
/* Hide scrollbar for horizontal tab scroll */
.scrollbar-hide {
  -ms-overflow-style: none;
  scrollbar-width: none;
}
.scrollbar-hide::-webkit-scrollbar {
  display: none;
}
</style>