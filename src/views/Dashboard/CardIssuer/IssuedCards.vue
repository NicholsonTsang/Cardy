<template>
    <div class="space-y-6">
        <!-- Page Header -->
        <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
            <div>
                <h1 class="text-2xl font-bold text-slate-900">All Issued Cards</h1>
                <p class="text-slate-600 mt-1">Overview and management of all your issued cards across all designs</p>
            </div>
            <div class="flex items-center gap-3">
                <Button 
                    icon="pi pi-refresh" 
                    label="Refresh" 
                    outlined
                    @click="refreshData"
                    :loading="isLoadingUserData"
                />
                <router-link to="/cms/mycards">
            <Button 
                icon="pi pi-plus" 
                        label="Issue New Cards" 
                severity="primary" 
                class="shadow-lg hover:shadow-xl transition-shadow"
            />
                </router-link>
            </div>
        </div>

        <!-- Enhanced Stats Cards -->
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
            <div class="bg-white rounded-xl shadow-lg border border-slate-200 p-6">
                <div class="flex items-center justify-between">
                    <div>
                        <h3 class="text-sm font-medium text-slate-600 mb-2">Total Cards</h3>
                        <p class="text-3xl font-bold text-slate-900">{{ userStats.total_cards }}</p>
                        <p class="text-sm text-slate-500 mt-1">Card Designs</p>
                    </div>
                    <div class="p-4 bg-gradient-to-r from-indigo-500 to-purple-500 rounded-xl">
                        <i class="pi pi-id-card text-white text-2xl"></i>
                    </div>
                </div>
            </div>
            
            <div class="bg-white rounded-xl shadow-lg border border-slate-200 p-6">
                <div class="flex items-center justify-between">
                    <div>
                        <h3 class="text-sm font-medium text-slate-600 mb-2">Total Issued</h3>
                        <p class="text-3xl font-bold text-slate-900">{{ userStats.total_issued }}</p>
                        <p class="text-sm text-slate-500 mt-1">Issued Cards</p>
                    </div>
                    <div class="p-4 bg-gradient-to-r from-blue-500 to-indigo-500 rounded-xl">
                        <i class="pi pi-send text-white text-2xl"></i>
                    </div>
                </div>
            </div>
            
            <div class="bg-white rounded-xl shadow-lg border border-slate-200 p-6">
                <div class="flex items-center justify-between">
                    <div>
                        <h3 class="text-sm font-medium text-slate-600 mb-2">Active Cards</h3>
                        <p class="text-3xl font-bold text-slate-900">{{ userStats.total_activated }}</p>
                        <p class="text-sm text-green-600 mt-1">{{ userStats.activation_rate }}% activation rate</p>
                    </div>
                    <div class="p-4 bg-gradient-to-r from-green-500 to-emerald-500 rounded-xl">
                        <i class="pi pi-check-circle text-white text-2xl"></i>
                    </div>
                </div>
            </div>
            
            <div class="bg-white rounded-xl shadow-lg border border-slate-200 p-6">
                <div class="flex items-center justify-between">
                    <div>
                        <h3 class="text-sm font-medium text-slate-600 mb-2">Pending Cards</h3>
                        <p class="text-3xl font-bold text-slate-900">{{ userStats.pending_cards }}</p>
                        <p class="text-sm text-amber-600 mt-1">Awaiting activation</p>
                    </div>
                    <div class="p-4 bg-gradient-to-r from-amber-500 to-yellow-500 rounded-xl">
                        <i class="pi pi-clock text-white text-2xl"></i>
                    </div>
                </div>
            </div>
        </div>

        <!-- Secondary Stats -->
        <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
            <div class="bg-white rounded-xl shadow-lg border border-slate-200 p-6">
                <div class="flex items-center justify-between">
                    <div>
                        <h3 class="text-sm font-medium text-slate-600 mb-2">Total Batches</h3>
                        <p class="text-2xl font-bold text-slate-900">{{ userStats.total_batches }}</p>
                    </div>
                    <div class="p-3 bg-slate-100 rounded-lg">
                        <i class="pi pi-box text-slate-600 text-xl"></i>
                    </div>
                </div>
            </div>

            <div class="bg-white rounded-xl shadow-lg border border-slate-200 p-6">
                <div class="flex items-center justify-between">
                    <div>
                        <h3 class="text-sm font-medium text-slate-600 mb-2">Disabled Batches</h3>
                        <p class="text-2xl font-bold text-slate-900">{{ userStats.disabled_batches }}</p>
                    </div>
                    <div class="p-3 bg-red-100 rounded-lg">
                        <i class="pi pi-ban text-red-600 text-xl"></i>
                    </div>
                </div>
            </div>
            
            <div class="bg-white rounded-xl shadow-lg border border-slate-200 p-6">
                <div class="flex items-center justify-between">
                    <div>
                        <h3 class="text-sm font-medium text-slate-600 mb-2">Active Print Requests</h3>
                        <p class="text-2xl font-bold text-slate-900">{{ userStats.active_print_requests }}</p>
                    </div>
                    <div class="p-3 bg-blue-100 rounded-lg">
                        <i class="pi pi-print text-blue-600 text-xl"></i>
                    </div>
                </div>
            </div>
        </div>

        <!-- Content Tabs -->
        <Tabs value="0" class="bg-white rounded-xl shadow-lg border border-slate-200 overflow-hidden">
            <TabList class="flex-shrink-0 border-b border-slate-200 bg-slate-50 px-6">
                <Tab value="0" class="px-4 py-3 font-medium text-slate-600 hover:text-slate-900 transition-colors">
                    <i class="pi pi-send mr-2"></i>
                    All Issued Cards ({{ userIssuedCards.length }})
                </Tab>
                <Tab value="1" class="px-4 py-3 font-medium text-slate-600 hover:text-slate-900 transition-colors">
                    <i class="pi pi-box mr-2"></i>
                    Batches ({{ userBatches.length }})
                </Tab>
                <Tab value="2" class="px-4 py-3 font-medium text-slate-600 hover:text-slate-900 transition-colors">
                    <i class="pi pi-history mr-2"></i>
                    Recent Activity
                </Tab>
            </TabList>

            <TabPanels>
                <!-- All Issued Cards Tab -->
                <TabPanel value="0">
                    <div class="p-6">
                        <DataTable 
                            v-model:filters="cardFilters"
                            :value="userIssuedCards" 
                            :loading="isLoadingUserData"
                            :paginator="true" 
                            :rows="20"
                            :rowsPerPageOptions="[20, 50, 100]"
                            stripedRows
                            responsiveLayout="scroll"
                            class="border-0"
                            dataKey="id"
                            filterDisplay="menu"
                            :globalFilterFields="['id', 'card_name', 'batch_name']"
                        >
                            <template #empty>
                                <EmptyState 
                                    v-bind="issuedCardsEmptyStateConfig"
                                    @action="handleIssuedCardsEmptyAction"
                                />
                            </template>
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
                                                    v-model="cardFilters['global'].value" 
                                                    placeholder="Search Card ID, Card Name, or Batch..." 
                                                    class="w-full"
                                                />
                                            </IconField>
                                        </div>
                                        
                                        <!-- Card Filter -->
                                        <div class="min-w-[200px]">
                                            <Select 
                                                v-model="cardFilters['card_name'].value"
                                                :options="[{ label: 'All Cards', value: null }, ...cardOptions]"
                                                optionLabel="label"
                                                optionValue="value"
                                                placeholder="Filter by Card"
                                                class="w-full"
                                                showClear
                                            />
                                        </div>
                                        
                                        <!-- Status Filter -->
                                        <div class="min-w-[150px]">
                                            <Select 
                                                v-model="cardFilters['active'].value"
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
                                        @click="clearCardFilters()"
                                        class="flex-shrink-0"
                                    />
                                </div>
                            </template>

                            <Column field="card_name" header="Card Design" sortable>
                                <template #body="{ data }">
                                    <div class="flex items-center gap-3">
                                        <img 
                                            :src="data.card_image_urls && data.card_image_urls.length > 0 ? data.card_image_urls[0] : cardPlaceholder"
                                            :alt="data.card_name"
                                            class="w-8 h-12 object-cover rounded border border-slate-200"
                                        />
                                        <div>
                                            <p class="font-medium text-slate-900">{{ data.card_name }}</p>
                                            <p class="text-xs text-slate-500">{{ data.card_id.substring(0, 8) }}...</p>
                                        </div>
                                    </div>
                                </template>
                            </Column>
                            
                            <Column field="id" header="Issue ID" sortable>
                                <template #body="{ data }">
                                    <code class="bg-slate-100 px-2 py-1 rounded text-xs font-mono text-slate-700">
                                        {{ data.id.substring(0, 8) }}...
                                    </code>
                                </template>
                            </Column>
                            
                            
                            <Column field="active" header="Status" sortable>
                                <template #body="{ data }">
                                    <Tag 
                                        :value="data.active ? 'Active' : 'Pending'" 
                                        :severity="data.active ? 'success' : 'warning'"
                                        class="px-2 py-1"
                                    />
                                </template>
                            </Column>

                            <Column field="batch_name" header="Batch" sortable>
                                <template #body="{ data }">
                                    <span class="text-sm font-medium text-slate-900">{{ data.batch_name }}</span>
                                    <Tag v-if="data.batch_is_disabled" value="Disabled" severity="danger" class="ml-2 px-2 py-0.5 text-xs"/>
                                </template>
                            </Column>

                            <Column field="issue_at" header="Issued" sortable>
                                <template #body="{ data }">
                                    <span class="text-sm text-slate-600">{{ formatDate(data.issue_at) }}</span>
                                </template>
                            </Column>

                            <Column field="active_at" header="Activated" sortable>
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
                                            @click="viewCardDetails(data)" 
                                            title="View Details"
                                        />
                                        <Button 
                                            icon="pi pi-external-link" 
                                            severity="success" 
                                            outlined
                                            size="small"
                                            @click="goToCardDesign(data.card_id)"
                                            title="Manage Card Design"
                                        />
                                    </div>
                                </template>
                            </Column>
                        </DataTable>
                    </div>
                </TabPanel>

                <!-- Batches Tab -->
                <TabPanel value="1">
                    <div class="p-6">
                        <DataTable 
                            v-model:filters="batchFilters"
                            :value="filteredBatches" 
                            :loading="isLoadingUserData"
                            :paginator="true" 
                            :rows="15"
                            :rowsPerPageOptions="[15, 30, 50]"
                            stripedRows
                            responsiveLayout="scroll"
                            class="border-0"
                            dataKey="id"
                            filterDisplay="menu"
                            :globalFilterFields="['batch_name', 'card_name']"
                        >
                            <template #empty>
                                <EmptyState 
                                    v-bind="batchesEmptyStateConfig"
                                    @action="handleBatchesEmptyAction"
                                />
                            </template>
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
                                                    v-model="batchFilters['global'].value" 
                                                    placeholder="Search Batch or Card Name..." 
                                                    class="w-full"
                                                />
                                            </IconField>
                                        </div>
                                        
                                        <!-- Status Filter -->
                                        <div class="min-w-[150px]">
                                            <Select 
                                                v-model="batchFilters['is_disabled'].value"
                                                :options="batchStatusOptions"
                                                optionLabel="label"
                                                optionValue="value"
                                                placeholder="Filter by Status"
                                                class="w-full"
                                                showClear
                                            />
                                        </div>
                                        
                                        <!-- Payment Filter -->
                                        <div class="min-w-[180px]">
                                            <Select 
                                                v-model="selectedPaymentFilter"
                                                :options="paymentStatusOptions"
                                                optionLabel="label"
                                                optionValue="value"
                                                placeholder="Filter by Payment"
                                                class="w-full"
                                                showClear
                                            />
                                        </div>
                                    </div>
                                    
                                    <Button 
                                        type="button" 
                                        icon="pi pi-filter-slash" 
                                        label="Clear" 
                                        outlined 
                                        @click="clearBatchFilters()"
                                        class="flex-shrink-0"
                                    />
                                </div>
                            </template>

                            <Column field="card_name" header="Card Design" sortable>
                                <template #body="{ data }">
                                    <div class="flex items-center gap-2">
                                        <span class="font-medium text-slate-900">{{ data.card_name }}</span>
                                    </div>
                                </template>
                            </Column>

                            <Column field="batch_name" header="Batch Name" sortable>
                                <template #body="{ data }">
                                    <span class="font-semibold">{{ data.batch_name }}</span>
                                </template>
                            </Column>

                            <Column field="cards_count" header="Total Cards" sortable></Column>
                            <Column field="active_cards_count" header="Active Cards" sortable></Column>

                            <!-- Payment Status Column -->
                            <Column field="payment_completed" header="Payment" sortable>
                                <template #body="{ data }">
                                    <div class="flex items-center gap-2">
                                        <Tag 
                                            v-if="data.payment_completed" 
                                            value="Paid" 
                                            severity="success" 
                                            icon="pi pi-check-circle"
                                            class="text-xs"
                                        />
                                        <Tag 
                                            v-else-if="data.payment_waived" 
                                            value="Fee Waived" 
                                            severity="success" 
                                            icon="pi pi-gift"
                                            class="text-xs"
                                        />
                                        <Tag 
                                            v-else-if="data.payment_required" 
                                            value="Payment Required" 
                                            severity="warning" 
                                            icon="pi pi-exclamation-triangle"
                                            class="text-xs"
                                        />
                                        <Tag 
                                            v-else 
                                            value="No Payment Required" 
                                            severity="info" 
                                            icon="pi pi-info-circle"
                                            class="text-xs"
                                        />
                                        <span v-if="data.payment_amount_cents" class="text-xs text-slate-600">
                                            ({{ formatAmount(data.payment_amount_cents) }})
                                        </span>
                                    </div>
                                </template>
                            </Column>

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

                            <Column header="Actions" style="min-width:8rem">
                                <template #body="{ data }">
                                    <Button 
                                        icon="pi pi-external-link" 
                                        severity="info" 
                                        outlined
                                        size="small"
                                        @click="goToCardDesign(data.card_id)"
                                        title="Manage in Card Design"
                                    />
                                </template>
                            </Column>
                        </DataTable>
                    </div>
                </TabPanel>

                <!-- Recent Activity Tab -->
                <TabPanel value="2">
                    <div class="p-6">
                        <div class="space-y-4">
                            <div v-if="recentActivity.length === 0 && !isLoadingUserData" 
                                 class="text-center py-8 text-slate-500">
                                <i class="pi pi-history text-4xl mb-4"></i>
                                <p>No recent activity</p>
                            </div>

                            <div v-for="activity in recentActivity" :key="`${activity.activity_type}-${activity.activity_date}`"
                                 class="bg-slate-50 rounded-lg p-4 border border-slate-200">
                                <div class="flex items-center justify-between">
                                    <div class="flex items-center gap-3">
                                        <div class="flex-shrink-0">
                                            <i :class="getActivityIcon(activity.activity_type)" 
                                               class="text-lg"
                                               :style="{ color: getActivityColor(activity.activity_type) }"></i>
                                        </div>
                                        <div>
                                            <p class="font-medium text-slate-900">{{ activity.description }}</p>
                                            <p class="text-sm text-slate-600">
                                                {{ activity.card_name }} • {{ activity.batch_name }}
                                            </p>
                                        </div>
                                    </div>
                                    <div class="text-right">
                                        <p class="text-sm text-slate-500">{{ formatDate(activity.activity_date) }}</p>
                                        <p v-if="activity.count > 1" class="text-xs text-slate-400">{{ activity.count }} cards</p>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </TabPanel>
            </TabPanels>
        </Tabs>

        <!-- Card Details Dialog -->
        <MyDialog
            v-model="showCardDetailsDialog"
            header="Card Details"
            :showConfirm="false"
            cancelLabel="Close"
            @hide="selectedCardForDetails = null"
            style="width: 90vw; max-width: 800px;"
        >
            <div v-if="selectedCardForDetails" class="space-y-6">
                <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                    <div class="space-y-4">
                        <div>
                            <h4 class="text-sm font-medium text-slate-700 mb-2">Card Design</h4>
                            <div class="flex items-center gap-3">
                                <img 
                                    :src="selectedCardForDetails.card_image_urls && selectedCardForDetails.card_image_urls.length > 0 ? selectedCardForDetails.card_image_urls[0] : cardPlaceholder"
                                    :alt="selectedCardForDetails.card_name"
                                    class="w-12 h-16 object-cover rounded border border-slate-200"
                                />
                                <div>
                                    <p class="font-medium text-slate-900">{{ selectedCardForDetails.card_name }}</p>
                                    <p class="text-sm text-slate-500">{{ selectedCardForDetails.card_id.substring(0, 8) }}...</p>
                                </div>
                            </div>
                        </div>
                        
                        <div>
                            <h4 class="text-sm font-medium text-slate-700 mb-2">Issue ID</h4>
                            <code class="bg-slate-100 px-3 py-2 rounded-lg text-sm font-mono text-slate-700 block break-all">
                                {{ selectedCardForDetails.id }}
                            </code>
                        </div>
                        
                        
                        <div>
                            <h4 class="text-sm font-medium text-slate-700 mb-2">Status</h4>
                            <Tag 
                                :value="selectedCardForDetails.active ? 'Active' : 'Pending'" 
                                :severity="selectedCardForDetails.active ? 'success' : 'warning'"
                                class="px-3 py-1"
                            />
                        </div>

                        <div>
                            <h4 class="text-sm font-medium text-slate-700 mb-2">Batch</h4>
                            <p class="text-sm text-slate-900">{{ selectedCardForDetails.batch_name }}</p>
                            <Tag v-if="selectedCardForDetails.batch_is_disabled" value="Disabled" severity="danger" class="mt-1 px-2 py-0.5 text-xs"/>
                        </div>
                    </div>
                    
                    <div class="space-y-4">
                        <div>
                            <h4 class="text-sm font-medium text-slate-700 mb-2">Issued</h4>
                            <p class="text-sm text-slate-600">{{ formatDate(selectedCardForDetails.issue_at) }}</p>
                        </div>
                        
                        <div v-if="selectedCardForDetails.active_at">
                            <h4 class="text-sm font-medium text-slate-700 mb-2">Activated</h4>
                            <p class="text-sm text-slate-600">{{ formatDate(selectedCardForDetails.active_at) }}</p>
                        </div>

                        <!-- QR Code Section -->
                        <div class="mt-4 p-4 border border-slate-200 rounded-lg bg-slate-50">
                            <h4 class="text-sm font-medium text-slate-700 mb-3 text-center">Scan to Activate & View</h4>
                            <div class="flex justify-center">
                                <qrcode-vue 
                                    :value="getCardUrl(selectedCardForDetails)" 
                                    :size="200" 
                                    level="H" 
                                    render-as="svg"
                                />
                            </div>
                            <input 
                                type="text" 
                                :value="getCardUrl(selectedCardForDetails)" 
                                readonly 
                                class="mt-3 w-full text-xs p-2 border border-slate-300 rounded bg-slate-100 cursor-pointer focus:outline-none focus:ring-1 focus:ring-blue-500"
                                @click="copyToClipboard(getCardUrl(selectedCardForDetails))"
                                title="Click to copy URL"
                            />
                            <p v-if="copied" class="text-xs text-green-600 text-center mt-1">Copied to clipboard!</p>
                        </div>
                    </div>
                </div>
            </div>
        </MyDialog>
    </div>
</template>

<script setup>
import { ref, onMounted, computed } from 'vue'
import { useRouter } from 'vue-router'
import { useIssuedCardStore } from '@/stores/issuedCard'
import { FilterMatchMode } from '@primevue/core/api'
import QrcodeVue from 'qrcode.vue'
import { useToast } from 'primevue/usetoast'
import { formatAmount } from '@/utils/stripeCheckout'

// PrimeVue Components
import Button from 'primevue/button'
import DataTable from 'primevue/datatable'
import Column from 'primevue/column'
import Tag from 'primevue/tag'
import IconField from 'primevue/iconfield'
import InputIcon from 'primevue/inputicon'
import InputText from 'primevue/inputtext'
import Select from 'primevue/select'
import Tabs from 'primevue/tabs'
import TabList from 'primevue/tablist'
import Tab from 'primevue/tab'
import TabPanels from 'primevue/tabpanels'
import TabPanel from 'primevue/tabpanel'
import MyDialog from '@/components/MyDialog.vue'
import EmptyState from '@/components/EmptyState.vue'
import { getEmptyStateConfig, determineEmptyScenario } from '@/utils/emptyStateConfigs.js'

// Placeholder image
import cardPlaceholder from '@/assets/images/card-placeholder.svg'

const router = useRouter()
const toast = useToast()
const store = useIssuedCardStore()

// Reactive data
const showCardDetailsDialog = ref(false)
const selectedCardForDetails = ref(null)
const copied = ref(false)

// Computed from store
const userIssuedCards = computed(() => store.userIssuedCards)
const userBatches = computed(() => store.userBatches)
const userStats = computed(() => store.userStats)
const recentActivity = computed(() => store.recentActivity)
const isLoadingUserData = computed(() => store.isLoadingUserData)

// Filters for cards table
const cardFilters = ref({
  global: { value: null, matchMode: FilterMatchMode.CONTAINS },
  card_name: { value: null, matchMode: FilterMatchMode.EQUALS },
  active: { value: null, matchMode: FilterMatchMode.EQUALS }
})

// Filters for batches table
const batchFilters = ref({
  global: { value: null, matchMode: FilterMatchMode.CONTAINS },
  is_disabled: { value: null, matchMode: FilterMatchMode.EQUALS }
})

// Separate payment filter (not part of DataTable filters)
const selectedPaymentFilter = ref(null)

// Filter options
const cardOptions = computed(() => {
  const uniqueCards = [...new Set(userIssuedCards.value.map(card => card.card_name))]
  return uniqueCards.map(cardName => ({ label: cardName, value: cardName }))
})

const statusOptions = computed(() => [
  { label: 'All', value: null },
  { label: 'Active', value: true },
  { label: 'Pending', value: false }
])

const batchStatusOptions = computed(() => [
  { label: 'All', value: null },
  { label: 'Enabled', value: false },
  { label: 'Disabled', value: true }
])

const paymentStatusOptions = computed(() => [
  { label: 'All Payments', value: null },
  { label: 'Paid', value: 'paid' },
  { label: 'Fee Waived', value: 'waived' },
  { label: 'Payment Required', value: 'required' },
  { label: 'No Payment Required', value: 'not_required' }
])

// Filtered batches for display
const filteredBatches = computed(() => {
  let filtered = [...userBatches.value]
  
  // Apply payment status filter
  const paymentFilter = selectedPaymentFilter.value
  if (paymentFilter) {
    filtered = filtered.filter(batch => {
      if (batch.payment_completed) return paymentFilter === 'paid'
      if (batch.payment_waived) return paymentFilter === 'waived'
      if (batch.payment_required) return paymentFilter === 'required'
      return paymentFilter === 'not_required'
    })
  }
  
  // Apply other filters (DataTable will handle global and is_disabled filters)
  return filtered
})

// Helper to check if card filters are active
const hasActiveCardFilters = computed(() => {
  return !!(
    cardFilters.value.global?.value || 
    cardFilters.value.card_name?.value || 
    cardFilters.value.active?.value
  )
})

// Helper to check if batch filters are active
const hasActiveBatchFilters = computed(() => {
  return !!(
    batchFilters.value.global?.value || 
    batchFilters.value.is_disabled?.value || 
    selectedPaymentFilter.value
  )
})

// Empty state configuration for issued cards
const issuedCardsEmptyStateConfig = computed(() => {
  const scenario = determineEmptyScenario(
    userIssuedCards.value,
    isLoadingUserData.value,
    false, // hasError - could be extended with error handling
    hasActiveCardFilters.value
  )
  
  if (!scenario) return null
  
  return getEmptyStateConfig('issuedCards', scenario)
})

// Empty state configuration for batches
const batchesEmptyStateConfig = computed(() => {
  const scenario = determineEmptyScenario(
    filteredBatches.value,
    isLoadingUserData.value,
    false, // hasError - could be extended with error handling
    hasActiveBatchFilters.value
  )
  
  if (!scenario) return null
  
  return getEmptyStateConfig('cardBatches', scenario)
})

// Methods
const formatDate = (dateString) => {
  if (!dateString) return '-'
  return new Date(dateString).toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  })
}

const clearCardFilters = () => {
  cardFilters.value = {
    global: { value: null, matchMode: FilterMatchMode.CONTAINS },
    card_name: { value: null, matchMode: FilterMatchMode.EQUALS },
    active: { value: null, matchMode: FilterMatchMode.EQUALS }
  }
}

const clearBatchFilters = () => {
  batchFilters.value = {
    global: { value: null, matchMode: FilterMatchMode.CONTAINS },
    is_disabled: { value: null, matchMode: FilterMatchMode.EQUALS }
  }
  selectedPaymentFilter.value = null
}

// Handle empty state actions
const handleIssuedCardsEmptyAction = () => {
  if (hasActiveCardFilters.value) {
    clearCardFilters()
  } else {
    // Navigate to card creation
    router.push('/cms/mycards')
  }
}

const handleBatchesEmptyAction = () => {
  if (hasActiveBatchFilters.value) {
    clearBatchFilters()
  } else {
    // Navigate to card creation to issue new batches
    router.push('/cms/mycards')
  }
}

const viewCardDetails = (card) => {
  selectedCardForDetails.value = card
  showCardDetailsDialog.value = true
}

const goToCardDesign = (cardId) => {
  router.push({ name: 'mycards', query: { cardId } })
}

const getCardUrl = (card) => {
  // Always use origin without any path for public card URLs
  const baseUrl = window.location.origin
  return `${baseUrl}/c/${card.id}`
}

const copyToClipboard = async (text) => {
  try {
    await navigator.clipboard.writeText(text)
    copied.value = true
    setTimeout(() => { copied.value = false }, 2000)
    toast.add({ severity: 'success', summary: 'Copied', detail: 'Activation URL copied to clipboard', life: 2000 })
  } catch (err) {
    console.error('Failed to copy: ', err)
    toast.add({ severity: 'error', summary: 'Copy Failed', detail: 'Could not copy URL', life: 2000 })
  }
}

const getActivityIcon = (activityType) => {
  switch (activityType) {
    case 'batch_created': return 'pi pi-box'
    case 'card_activated': return 'pi pi-check-circle'
    case 'print_requested': return 'pi pi-print'
    default: return 'pi pi-circle'
  }
}

const getActivityColor = (activityType) => {
  switch (activityType) {
    case 'batch_created': return '#6366f1'
    case 'card_activated': return '#10b981'
    case 'print_requested': return '#3b82f6'
    default: return '#64748b'
  }
}

const refreshData = async () => {
  try {
    await store.loadUserData()
    toast.add({ 
      severity: 'success', 
      summary: 'Refreshed', 
      detail: 'Data updated successfully', 
      life: 2000 
    })
  } catch (error) {
    console.error('Error refreshing data:', error)
    toast.add({ 
      severity: 'error', 
      summary: 'Error', 
      detail: 'Failed to refresh data', 
      life: 3000 
    })
  }
}

// Initialize data
onMounted(async () => {
  await store.loadUserData()
})
</script>

<style scoped>
/* Custom tab styling */
:deep(.p-tabs-nav) {
    background: transparent;
    border: none;
}

:deep(.p-tabs-tab) {
    background: transparent;
    border: none;
    border-bottom: 2px solid transparent;
}

:deep(.p-tabs-tab:hover) {
    background: rgba(59, 130, 246, 0.05);
}

:deep(.p-tabs-tab[aria-selected="true"]) {
    background: transparent;
    border-bottom-color: #3b82f6;
    color: #3b82f6;
}

/* Compact DataTable styling */
/* Component-specific styles - global table theme now handles standard styling */
</style>