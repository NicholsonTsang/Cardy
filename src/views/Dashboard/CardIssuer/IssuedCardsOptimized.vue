<template>
    <div class="min-h-screen bg-gradient-to-br from-slate-50 to-slate-100">
        <!-- Enhanced Header with Action Bar -->
        <div class="bg-white border-b border-slate-200 shadow-sm">
            <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
                <div class="flex flex-col lg:flex-row lg:items-center lg:justify-between py-6 gap-4">
                    <div class="flex-1">
                        <div class="flex items-center gap-3 mb-2">
                            <div class="p-2 bg-gradient-to-br from-blue-500 to-indigo-600 rounded-lg">
                                <i class="pi pi-send text-white text-xl"></i>
                            </div>
                            <div>
                                <h1 class="text-2xl font-bold text-slate-900">Issued Cards Hub</h1>
                                <p class="text-slate-600">Monitor performance, manage batches, and track activations</p>
                            </div>
                        </div>
                    </div>
                    
                    <div class="flex items-center gap-3">
                        <Button 
                            icon="pi pi-refresh" 
                            label="Refresh" 
                            outlined
                            @click="refreshAllData"
                            :loading="isLoadingUserData"
                            class="flex-shrink-0"
                        />
                        <Button 
                            icon="pi pi-download" 
                            label="Export" 
                            outlined
                            @click="exportData"
                            class="hidden sm:flex flex-shrink-0"
                        />
                        <router-link to="/cms/mycards">
                            <Button 
                                icon="pi pi-plus" 
                                label="Issue New Cards" 
                                severity="primary" 
                                class="shadow-lg hover:shadow-xl transition-all hover:scale-105"
                            />
                        </router-link>
                    </div>
                </div>
            </div>
        </div>

        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
            <!-- Business Intelligence Dashboard -->
            <div class="mb-8">
                <div class="flex items-center justify-between mb-6">
                    <h2 class="text-lg font-semibold text-slate-900">Performance Overview</h2>
                    <div class="flex items-center gap-2">
                        <span class="text-sm text-slate-500">Last updated:</span>
                        <span class="text-sm font-medium text-slate-700">{{ lastUpdated }}</span>
                    </div>
                </div>

                <!-- Enhanced Metrics Grid -->
                <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
                    <!-- Total Cards Metric -->
                    <div class="bg-white rounded-xl shadow-sm border border-slate-200 p-6 hover:shadow-md transition-shadow">
                        <div class="flex items-center justify-between">
                            <div class="flex-1">
                                <div class="flex items-center gap-2 mb-2">
                                    <h3 class="text-sm font-medium text-slate-600">Card Designs</h3>
                                    <i class="pi pi-info-circle text-slate-400 text-xs cursor-help" 
                                       v-tooltip="'Total unique card designs you have created'"></i>
                                </div>
                                <p class="text-3xl font-bold text-slate-900 mb-1">{{ userStats.total_cards }}</p>
                                <div class="flex items-center gap-1 text-xs">
                                    <span class="text-slate-500">Active designs</span>
                                </div>
                            </div>
                            <div class="w-12 h-12 bg-gradient-to-br from-indigo-100 to-purple-100 rounded-lg flex items-center justify-center">
                                <i class="pi pi-id-card text-indigo-600 text-xl"></i>
                            </div>
                        </div>
                    </div>

                    <!-- Total Issued Metric -->
                    <div class="bg-white rounded-xl shadow-sm border border-slate-200 p-6 hover:shadow-md transition-shadow">
                        <div class="flex items-center justify-between">
                            <div class="flex-1">
                                <div class="flex items-center gap-2 mb-2">
                                    <h3 class="text-sm font-medium text-slate-600">Total Issued</h3>
                                    <i class="pi pi-info-circle text-slate-400 text-xs cursor-help" 
                                       v-tooltip="'Total cards issued across all batches'"></i>
                                </div>
                                <p class="text-3xl font-bold text-slate-900 mb-1">{{ userStats.total_issued.toLocaleString() }}</p>
                                <div class="flex items-center gap-1 text-xs">
                                    <i class="pi pi-arrow-up text-green-500"></i>
                                    <span class="text-green-600 font-medium">{{ recentIssuedGrowth }}%</span>
                                    <span class="text-slate-500">vs last month</span>
                                </div>
                            </div>
                            <div class="w-12 h-12 bg-gradient-to-br from-blue-100 to-indigo-100 rounded-lg flex items-center justify-center">
                                <i class="pi pi-send text-blue-600 text-xl"></i>
                            </div>
                        </div>
                    </div>

                    <!-- Activation Rate Metric -->
                    <div class="bg-white rounded-xl shadow-sm border border-slate-200 p-6 hover:shadow-md transition-shadow">
                        <div class="flex items-center justify-between">
                            <div class="flex-1">
                                <div class="flex items-center gap-2 mb-2">
                                    <h3 class="text-sm font-medium text-slate-600">Activation Rate</h3>
                                    <i class="pi pi-info-circle text-slate-400 text-xs cursor-help" 
                                       v-tooltip="'Percentage of issued cards that have been activated'"></i>
                                </div>
                                <div class="flex items-baseline gap-2">
                                    <p class="text-3xl font-bold text-slate-900">{{ userStats.activation_rate.toFixed(1) }}%</p>
                                    <span class="text-sm text-slate-500">of {{ userStats.total_issued }}</span>
                                </div>
                                <div class="w-full bg-slate-200 rounded-full h-2 mt-2">
                                    <div class="bg-gradient-to-r from-green-500 to-emerald-500 h-2 rounded-full transition-all duration-500"
                                         :style="{ width: `${Math.min(userStats.activation_rate, 100)}%` }"></div>
                                </div>
                            </div>
                            <div class="w-12 h-12 bg-gradient-to-br from-green-100 to-emerald-100 rounded-lg flex items-center justify-center">
                                <i class="pi pi-check-circle text-green-600 text-xl"></i>
                            </div>
                        </div>
                    </div>

                    <!-- Active Batches Metric -->
                    <div class="bg-white rounded-xl shadow-sm border border-slate-200 p-6 hover:shadow-md transition-shadow">
                        <div class="flex items-center justify-between">
                            <div class="flex-1">
                                <div class="flex items-center gap-2 mb-2">
                                    <h3 class="text-sm font-medium text-slate-600">Active Batches</h3>
                                    <i class="pi pi-info-circle text-slate-400 text-xs cursor-help" 
                                       v-tooltip="'Card batches currently available for activation'"></i>
                                </div>
                                <p class="text-3xl font-bold text-slate-900 mb-1">{{ activeBatchesCount }}</p>
                                <div class="flex items-center gap-1 text-xs">
                                    <span class="text-slate-500">{{ userStats.disabled_batches }} disabled</span>
                                </div>
                            </div>
                            <div class="w-12 h-12 bg-gradient-to-br from-orange-100 to-amber-100 rounded-lg flex items-center justify-center">
                                <i class="pi pi-box text-orange-600 text-xl"></i>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Main Content Area with Master-Detail Layout -->
            <div class="grid grid-cols-1 xl:grid-cols-12 gap-8">
                <!-- Left Panel: Batch List (Master) -->
                <div class="xl:col-span-5">
                    <div class="bg-white rounded-xl shadow-sm border border-slate-200">
                        <div class="p-6 border-b border-slate-200">
                            <div class="flex items-center justify-between mb-4">
                                <h3 class="text-lg font-semibold text-slate-900">Batch Performance</h3>
                                <div class="flex items-center gap-2">
                                    <Button 
                                        icon="pi pi-sort-amount-down" 
                                        text 
                                        @click="toggleSortOrder"
                                        v-tooltip="'Sort by performance'"
                                        class="p-2"
                                    />
                                    <Button 
                                        icon="pi pi-filter" 
                                        text 
                                        @click="showFilters = !showFilters"
                                        :class="{ 'bg-blue-50 text-blue-600': showFilters }"
                                        class="p-2"
                                    />
                                </div>
                            </div>

                            <!-- Quick Filters -->
                            <div v-if="showFilters" class="mb-4 p-4 bg-slate-50 rounded-lg">
                                <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
                                    <Select 
                                        v-model="selectedStatusFilter"
                                        :options="statusFilterOptions"
                                        optionLabel="label"
                                        optionValue="value"
                                        placeholder="Filter by Status"
                                        showClear
                                        class="w-full"
                                    />
                                    <Select 
                                        v-model="selectedPerformanceFilter"
                                        :options="performanceFilterOptions"
                                        optionLabel="label"
                                        optionValue="value"
                                        placeholder="Performance Level"
                                        showClear
                                        class="w-full"
                                    />
                                </div>
                            </div>

                            <!-- Search -->
                            <IconField>
                                <InputIcon>
                                    <i class="pi pi-search" />
                                </InputIcon>
                                <InputText 
                                    v-model="searchQuery" 
                                    placeholder="Search batches or card names..." 
                                    class="w-full"
                                />
                            </IconField>
                        </div>

                        <!-- Batch List -->
                        <div class="divide-y divide-slate-200 max-h-[600px] overflow-y-auto">
                            <div 
                                v-for="batch in filteredBatches" 
                                :key="batch.id"
                                @click="selectedBatch = batch"
                                :class="[
                                    'p-4 cursor-pointer transition-all hover:bg-slate-50',
                                    selectedBatch?.id === batch.id ? 'bg-blue-50 border-r-4 border-blue-500' : ''
                                ]"
                            >
                                <div class="flex items-start justify-between">
                                    <div class="flex-1 min-w-0">
                                        <div class="flex items-center gap-2 mb-2">
                                            <h4 class="font-medium text-slate-900 truncate">{{ batch.batch_name }}</h4>
                                            <Tag 
                                                :value="getPerformanceLevel(batch.activation_rate)"
                                                :severity="getPerformanceSeverity(batch.activation_rate)"
                                                class="text-xs"
                                            />
                                        </div>
                                        <p class="text-sm text-slate-600 truncate mb-1">{{ batch.card_name }}</p>
                                        <div class="flex items-center gap-4 text-xs text-slate-500">
                                            <span>{{ batch.active_cards_count }}/{{ batch.cards_count }} active</span>
                                            <span>{{ batch.activation_rate.toFixed(1) }}%</span>
                                        </div>
                                    </div>
                                    <div class="flex flex-col items-end gap-1">
                                        <div class="text-right">
                                            <div class="text-xs text-slate-500 mb-1">Last 7 days</div>
                                            <div class="flex items-center gap-1">
                                                <i class="pi pi-arrow-up text-green-500 text-xs"></i>
                                                <span class="text-sm font-medium text-slate-900">{{ batch.recent_activations_7d }}</span>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                                
                                <!-- Progress Bar -->
                                <div class="mt-3">
                                    <div class="w-full bg-slate-200 rounded-full h-1.5">
                                        <div 
                                            class="h-1.5 rounded-full transition-all duration-500"
                                            :class="getProgressBarColor(batch.activation_rate)"
                                            :style="{ width: `${Math.min(batch.activation_rate, 100)}%` }"
                                        ></div>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <div v-if="filteredBatches.length === 0" class="p-8 text-center">
                            <i class="pi pi-inbox text-slate-400 text-3xl mb-3"></i>
                            <p class="text-slate-500">No batches match your filters</p>
                        </div>
                    </div>
                </div>

                <!-- Right Panel: Detailed Analytics (Detail) -->
                <div class="xl:col-span-7">
                    <div v-if="selectedBatch" class="space-y-6">
                        <!-- Batch Detail Header -->
                        <div class="bg-white rounded-xl shadow-sm border border-slate-200 p-6">
                            <div class="flex items-start justify-between mb-4">
                                <div class="flex-1">
                                    <div class="flex items-center gap-3 mb-2">
                                        <h3 class="text-xl font-bold text-slate-900">{{ selectedBatch.batch_name }}</h3>
                                        <Tag 
                                            :value="selectedBatch.is_disabled ? 'Disabled' : 'Active'"
                                            :severity="selectedBatch.is_disabled ? 'danger' : 'success'"
                                        />
                                        <Tag 
                                            v-if="selectedBatch.has_print_requests"
                                            value="Print Requested"
                                            severity="info"
                                            icon="pi pi-print"
                                        />
                                    </div>
                                    <p class="text-slate-600 mb-3">{{ selectedBatch.card_name }}</p>
                                    <div class="grid grid-cols-2 sm:grid-cols-4 gap-4 text-sm">
                                        <div>
                                            <span class="text-slate-500">Created:</span>
                                            <div class="font-medium">{{ formatDate(selectedBatch.created_at) }}</div>
                                        </div>
                                        <div>
                                            <span class="text-slate-500">Total Cards:</span>
                                            <div class="font-medium">{{ selectedBatch.cards_count }}</div>
                                        </div>
                                        <div>
                                            <span class="text-slate-500">Activated:</span>
                                            <div class="font-medium">{{ selectedBatch.active_cards_count }}</div>
                                        </div>
                                        <div>
                                            <span class="text-slate-500">Rate:</span>
                                            <div class="font-medium">{{ selectedBatch.activation_rate.toFixed(1) }}%</div>
                                        </div>
                                    </div>
                                </div>
                                <Dropdown 
                                    v-model="selectedBatchAction"
                                    :options="batchActionOptions"
                                    optionLabel="label"
                                    placeholder="Actions"
                                    @change="handleBatchAction"
                                    class="ml-4"
                                />
                            </div>
                        </div>

                        <!-- Activation Timeline -->
                        <div class="bg-white rounded-xl shadow-sm border border-slate-200 p-6">
                            <h4 class="text-lg font-semibold text-slate-900 mb-4">Activation Timeline</h4>
                            <div class="grid grid-cols-1 sm:grid-cols-3 gap-6">
                                <div class="text-center p-4 bg-slate-50 rounded-lg">
                                    <div class="text-2xl font-bold text-slate-900 mb-1">{{ selectedBatch.recent_activations_7d }}</div>
                                    <div class="text-sm text-slate-600">Last 7 days</div>
                                </div>
                                <div class="text-center p-4 bg-slate-50 rounded-lg">
                                    <div class="text-2xl font-bold text-slate-900 mb-1">{{ selectedBatch.recent_activations_30d }}</div>
                                    <div class="text-sm text-slate-600">Last 30 days</div>
                                </div>
                                <div class="text-center p-4 bg-slate-50 rounded-lg">
                                    <div class="text-2xl font-bold text-slate-900 mb-1">
                                        {{ selectedBatch.avg_activation_time_hours ? selectedBatch.avg_activation_time_hours.toFixed(1) + 'h' : 'N/A' }}
                                    </div>
                                    <div class="text-sm text-slate-600">Avg. activation time</div>
                                </div>
                            </div>
                        </div>

                        <!-- Payment Information -->
                        <div v-if="selectedBatch.payment_amount_cents" class="bg-white rounded-xl shadow-sm border border-slate-200 p-6">
                            <h4 class="text-lg font-semibold text-slate-900 mb-4">Payment Information</h4>
                            <div class="grid grid-cols-1 sm:grid-cols-2 gap-6">
                                <div>
                                    <span class="text-slate-500 text-sm">Amount:</span>
                                    <div class="text-xl font-bold text-slate-900">
                                        ${{ (selectedBatch.payment_amount_cents / 100).toFixed(2) }}
                                    </div>
                                </div>
                                <div>
                                    <span class="text-slate-500 text-sm">Status:</span>
                                    <div class="flex items-center gap-2 mt-1">
                                        <Tag 
                                            :value="selectedBatch.payment_completed ? 'Paid' : 'Pending'"
                                            :severity="selectedBatch.payment_completed ? 'success' : 'warning'"
                                        />
                                    </div>
                                </div>
                            </div>
                        </div>

                        <!-- Quick Actions -->
                        <div class="bg-white rounded-xl shadow-sm border border-slate-200 p-6">
                            <h4 class="text-lg font-semibold text-slate-900 mb-4">Quick Actions</h4>
                            <div class="flex flex-wrap gap-3">
                                <Button 
                                    label="View Cards" 
                                    icon="pi pi-eye"
                                    outlined
                                    @click="viewBatchCards(selectedBatch)"
                                />
                                <Button 
                                    label="Export Data" 
                                    icon="pi pi-download"
                                    outlined
                                    @click="exportBatchData(selectedBatch)"
                                />
                                <Button 
                                    v-if="!selectedBatch.has_print_requests"
                                    label="Request Print" 
                                    icon="pi pi-print"
                                    outlined
                                    @click="requestPrint(selectedBatch)"
                                />
                                <Button 
                                    :label="selectedBatch.is_disabled ? 'Enable Batch' : 'Disable Batch'"
                                    :icon="selectedBatch.is_disabled ? 'pi pi-play' : 'pi pi-pause'"
                                    :severity="selectedBatch.is_disabled ? 'success' : 'secondary'"
                                    outlined
                                    @click="toggleBatchStatus(selectedBatch)"
                                />
                            </div>
                        </div>
                    </div>

                    <!-- Empty State -->
                    <div v-else class="bg-white rounded-xl shadow-sm border border-slate-200 p-12 text-center">
                        <i class="pi pi-arrow-left text-slate-400 text-4xl mb-4"></i>
                        <h3 class="text-lg font-semibold text-slate-900 mb-2">Select a Batch</h3>
                        <p class="text-slate-600">Choose a batch from the left panel to view detailed analytics and manage settings.</p>
                    </div>
                </div>
            </div>
        </div>

        <!-- Loading Overlay -->
        <div v-if="isLoadingUserData" class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
            <div class="bg-white rounded-lg p-6 flex items-center gap-3">
                <ProgressSpinner style="width:30px;height:30px" strokeWidth="4" />
                <span class="text-slate-700">Loading analytics...</span>
            </div>
        </div>
    </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue';
import { useIssuedCardStore } from '@/stores/issuedCard';
import type { UserCardBatch } from '@/stores/issuedCard';

// PrimeVue Components
import Button from 'primevue/button';
import Select from 'primevue/select';
import InputText from 'primevue/inputtext';
import InputIcon from 'primevue/inputicon';
import IconField from 'primevue/iconfield';
import Tag from 'primevue/tag';
import Dropdown from 'primevue/dropdown';
import ProgressSpinner from 'primevue/progressspinner';

// Define BatchAnalytics type locally since it's not exported from the store
interface BatchAnalytics extends UserCardBatch {
  activation_rate: number;
  performance_level: string;
  recent_activations_7d: number;
  recent_activations_30d: number;
  avg_activation_time_hours: number | null;
  has_print_requests: boolean;
}

// Store
const issuedCardStore = useIssuedCardStore();

// Reactive data
const selectedBatch = ref<BatchAnalytics | null>(null);
const searchQuery = ref('');
const showFilters = ref(false);
const selectedStatusFilter = ref(null);
const selectedPerformanceFilter = ref(null);
const selectedBatchAction = ref(null);

// Computed properties
const batchAnalytics = computed(() => {
  // Transform userBatches to include analytics data
  return issuedCardStore.userBatches.map(batch => ({
    ...batch,
    activation_rate: batch.cards_count > 0 ? (batch.active_cards_count / batch.cards_count) * 100 : 0,
    performance_level: getPerformanceLevel(batch.cards_count > 0 ? (batch.active_cards_count / batch.cards_count) * 100 : 0),
    recent_activations_7d: Math.floor(Math.random() * 10), // Mock data - replace with real analytics
    recent_activations_30d: Math.floor(Math.random() * 50), // Mock data - replace with real analytics
    avg_activation_time_hours: Math.random() * 24, // Mock data - replace with real analytics
    has_print_requests: (batch.print_requests && batch.print_requests.length > 0) || false
  }));
});

const { 
    userStats, 
    isLoadingUserData 
} = issuedCardStore;

const lastUpdated = computed(() => {
    return new Date().toLocaleTimeString();
});

const recentIssuedGrowth = computed(() => {
    // Mock calculation - in real app, compare with previous period
    return Math.floor(Math.random() * 20) + 5;
});

const activeBatchesCount = computed(() => {
    return userStats.total_batches - userStats.disabled_batches;
});

const filteredBatches = computed(() => {
    let filtered = [...batchAnalytics.value];
    
    // Apply search filter
    if (searchQuery.value) {
        const query = searchQuery.value.toLowerCase();
        filtered = filtered.filter(batch => 
            batch.batch_name.toLowerCase().includes(query) ||
            batch.card_name.toLowerCase().includes(query)
        );
    }
    
    // Apply status filter
    if (selectedStatusFilter.value !== null) {
        filtered = filtered.filter(batch => {
            if (selectedStatusFilter.value === 'active') return !batch.is_disabled;
            if (selectedStatusFilter.value === 'disabled') return batch.is_disabled;
            if (selectedStatusFilter.value === 'paid') return batch.payment_completed;
            if (selectedStatusFilter.value === 'unpaid') return !batch.payment_completed;
            return true;
        });
    }
    
    // Apply performance filter
    if (selectedPerformanceFilter.value !== null) {
        filtered = filtered.filter(batch => {
            const rate = batch.activation_rate;
            if (selectedPerformanceFilter.value === 'high') return rate >= 80;
            if (selectedPerformanceFilter.value === 'medium') return rate >= 50 && rate < 80;
            if (selectedPerformanceFilter.value === 'low') return rate < 50;
            return true;
        });
    }
    
    return filtered;
});

// Filter options
const statusFilterOptions = [
    { label: 'Active Batches', value: 'active' },
    { label: 'Disabled Batches', value: 'disabled' },
    { label: 'Paid Batches', value: 'paid' },
    { label: 'Unpaid Batches', value: 'unpaid' }
];

const performanceFilterOptions = [
    { label: 'High Performance (80%+)', value: 'high' },
    { label: 'Medium Performance (50-79%)', value: 'medium' },
    { label: 'Low Performance (<50%)', value: 'low' }
];

const batchActionOptions = [
    { label: 'View Individual Cards', value: 'view_cards' },
    { label: 'Export Batch Data', value: 'export' },
    { label: 'Request Physical Print', value: 'print' },
    { label: 'Disable/Enable Batch', value: 'toggle_status' },
    { label: 'Generate New Cards', value: 'generate' }
];

// Methods
const refreshAllData = async () => {
    await issuedCardStore.loadUserData();
};

const getPerformanceLevel = (rate: number) => {
    if (rate >= 80) return 'Excellent';
    if (rate >= 60) return 'Good';
    if (rate >= 40) return 'Fair';
    return 'Poor';
};

const getPerformanceSeverity = (rate: number) => {
    if (rate >= 80) return 'success';
    if (rate >= 60) return 'info';
    if (rate >= 40) return 'warning';
    return 'danger';
};

const getProgressBarColor = (rate: number) => {
    if (rate >= 80) return 'bg-gradient-to-r from-green-500 to-emerald-500';
    if (rate >= 60) return 'bg-gradient-to-r from-blue-500 to-indigo-500';
    if (rate >= 40) return 'bg-gradient-to-r from-yellow-500 to-orange-500';
    return 'bg-gradient-to-r from-red-500 to-pink-500';
};

const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString();
};

const toggleSortOrder = () => {
    batchAnalytics.value.sort((a: BatchAnalytics, b: BatchAnalytics) => b.activation_rate - a.activation_rate);
};

const handleBatchAction = (event: any) => {
    const action = event.value;
    if (!selectedBatch.value) return;
    
    switch (action) {
        case 'view_cards':
            viewBatchCards(selectedBatch.value);
            break;
        case 'export':
            exportBatchData(selectedBatch.value);
            break;
        case 'print':
            requestPrint(selectedBatch.value);
            break;
        case 'toggle_status':
            toggleBatchStatus(selectedBatch.value);
            break;
        case 'generate':
            generateNewCards(selectedBatch.value);
            break;
    }
    selectedBatchAction.value = null;
};

const viewBatchCards = (batch: BatchAnalytics) => {
    // Navigate to individual cards view
    console.log('View cards for batch:', batch.id);
};

const exportBatchData = (batch: BatchAnalytics) => {
    // Export batch analytics
    console.log('Export data for batch:', batch.id);
};

const exportData = () => {
    // Export all data
    console.log('Export all data');
};

const requestPrint = (batch: BatchAnalytics) => {
    // Request physical printing
    console.log('Request print for batch:', batch.id);
};

const toggleBatchStatus = async (batch: BatchAnalytics) => {
    try {
        await issuedCardStore.toggleBatchDisabledStatus(batch.id, !batch.is_disabled);
        await refreshAllData();
    } catch (error) {
        console.error('Error toggling batch status:', error);
    }
};

const generateNewCards = (batch: BatchAnalytics) => {
    // Generate additional cards for batch
    console.log('Generate new cards for batch:', batch.id);
};

// Lifecycle
onMounted(async () => {
    await refreshAllData();
    // Auto-select first batch if available
    if (batchAnalytics.value.length > 0) {
        selectedBatch.value = batchAnalytics.value[0];
    }
});

// Watch for batch changes to auto-select first when filtered
watch(filteredBatches, (newBatches) => {
    if (newBatches.length > 0 && !selectedBatch.value) {
        selectedBatch.value = newBatches[0];
    }
});
</script>