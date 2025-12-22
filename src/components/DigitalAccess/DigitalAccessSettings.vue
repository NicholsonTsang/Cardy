<template>
  <div class="space-y-6">
    <!-- Statistics Cards with Progress -->
    <div class="grid grid-cols-1 md:grid-cols-3 gap-4 lg:gap-6">
      <!-- Total Scans Card -->
      <div class="bg-white rounded-xl shadow-lg border border-slate-200 p-5 hover:shadow-xl transition-shadow">
        <div class="flex items-center justify-between mb-3">
          <h3 class="text-sm font-medium text-slate-600">{{ $t('digital_access.total_scans') }}</h3>
          <div class="p-2.5 bg-gradient-to-r from-blue-500 to-indigo-500 rounded-lg">
            <i class="pi pi-eye text-white text-lg"></i>
          </div>
        </div>
        <p class="text-2xl lg:text-3xl font-bold text-slate-900">
          {{ formatNumber(card.current_scans || 0) }}
          <span v-if="card.max_scans" class="text-base lg:text-lg font-normal text-slate-400">/ {{ formatNumber(card.max_scans) }}</span>
        </p>
        <!-- Progress bar -->
        <div v-if="card.max_scans" class="mt-3">
          <div class="h-2 bg-slate-100 rounded-full overflow-hidden">
            <div 
              class="h-full rounded-full transition-all duration-500"
              :class="totalUsagePercent >= 90 ? 'bg-red-500' : totalUsagePercent >= 75 ? 'bg-amber-500' : 'bg-blue-500'"
              :style="{ width: totalUsagePercent + '%' }"
            ></div>
          </div>
          <p class="text-xs text-slate-500 mt-1.5">{{ totalUsagePercent.toFixed(0) }}% {{ $t('digital_access.used') }}</p>
        </div>
        <p v-else class="text-xs text-green-600 mt-2 flex items-center gap-1">
          <i class="pi pi-infinity text-xs"></i>
          {{ $t('digital_access.no_limit_set') }}
        </p>
      </div>

      <!-- Today's Scans Card -->
      <div class="bg-white rounded-xl shadow-lg border border-slate-200 p-5 hover:shadow-xl transition-shadow">
        <div class="flex items-center justify-between mb-3">
          <h3 class="text-sm font-medium text-slate-600">{{ $t('digital_access.today_scans') }}</h3>
          <div class="p-2.5 bg-gradient-to-r from-purple-500 to-violet-500 rounded-lg">
            <i class="pi pi-calendar text-white text-lg"></i>
          </div>
        </div>
        <p class="text-2xl lg:text-3xl font-bold text-slate-900">
          {{ card.daily_scans || 0 }}
          <span v-if="card.daily_scan_limit" class="text-base lg:text-lg font-normal text-slate-400">/ {{ card.daily_scan_limit }}</span>
        </p>
        <!-- Progress bar -->
        <div v-if="card.daily_scan_limit" class="mt-3">
          <div class="h-2 bg-slate-100 rounded-full overflow-hidden">
            <div 
              class="h-full rounded-full transition-all duration-500"
              :class="dailyUsagePercent >= 90 ? 'bg-red-500' : dailyUsagePercent >= 75 ? 'bg-amber-500' : 'bg-purple-500'"
              :style="{ width: dailyUsagePercent + '%' }"
            ></div>
          </div>
          <p class="text-xs text-slate-500 mt-1.5">{{ dailyUsagePercent.toFixed(0) }}% {{ $t('digital_access.used') }}</p>
        </div>
        <p v-else class="text-xs text-green-600 mt-2 flex items-center gap-1">
          <i class="pi pi-infinity text-xs"></i>
          {{ $t('digital_access.no_limit_set') }}
        </p>
        
        <!-- AI Status Indicator -->
        <div class="mt-3 pt-3 border-t border-slate-100">
          <div v-if="card.conversation_ai_enabled" class="flex items-center gap-2 text-xs text-blue-600">
            <i class="pi pi-microphone"></i>
            <span>{{ $t('digital_access.ai_enabled_status') }}</span>
          </div>
          <div v-else class="flex items-center gap-2 text-xs text-slate-500">
            <i class="pi pi-file"></i>
            <span>{{ $t('digital_access.ai_disabled_status') }}</span>
          </div>
        </div>
      </div>

      <!-- Credit Balance Card -->
      <div class="relative overflow-hidden bg-gradient-to-br from-slate-900 via-slate-800 to-slate-900 rounded-xl shadow-lg p-5 text-white hover:shadow-xl transition-shadow">
        <!-- Decorative elements -->
        <div class="absolute top-0 right-0 w-32 h-32 bg-gradient-to-br from-emerald-500/20 to-transparent rounded-full -translate-y-1/2 translate-x-1/2"></div>
        <div class="absolute bottom-0 left-0 w-24 h-24 bg-gradient-to-tr from-teal-500/10 to-transparent rounded-full translate-y-1/2 -translate-x-1/2"></div>
        
        <!-- Content -->
        <div class="relative">
          <div class="flex items-center gap-2 mb-2">
            <i class="pi pi-wallet text-emerald-400 text-sm"></i>
            <h3 class="text-xs font-medium text-slate-400 uppercase tracking-wider">{{ $t('digital_access.your_balance') }}</h3>
          </div>
          
          <div class="flex items-baseline gap-1.5">
            <p class="text-3xl lg:text-4xl font-bold bg-gradient-to-r from-white to-slate-200 bg-clip-text text-transparent">
              {{ creditBalance.toFixed(2) }}
            </p>
            <span class="text-sm font-medium text-slate-400">{{ $t('common.credits') }}</span>
          </div>
          
          <div class="mt-4 pt-3 border-t border-slate-700/50 flex items-center justify-between gap-2">
            <div v-if="estimatedRunway > 0" class="flex items-center gap-1.5">
              <div class="w-1.5 h-1.5 rounded-full bg-emerald-400 animate-pulse"></div>
              <p class="text-xs text-slate-400">
                <span class="text-emerald-400 font-semibold">~{{ formatNumber(estimatedRunway) }}</span> {{ $t('digital_access.scans_remaining') }}
              </p>
            </div>
            <div v-else></div>
            <Button 
              :label="$t('digital_access.top_up')" 
              icon="pi pi-plus"
              size="small"
              class="bg-emerald-500 hover:bg-emerald-600 border-0 text-xs font-semibold px-3"
              @click="navigateToCredits"
            />
          </div>
        </div>
      </div>
    </div>

    <!-- Warning Banners -->
    <div v-if="showLowCreditWarning" class="flex items-center gap-4 p-4 bg-amber-50 rounded-xl border border-amber-200">
      <div class="p-2 bg-amber-500 rounded-lg flex-shrink-0">
        <i class="pi pi-exclamation-triangle text-white"></i>
      </div>
      <div class="flex-1 min-w-0">
        <p class="font-semibold text-slate-900 text-sm">{{ $t('digital_access.low_credits_warning') }}</p>
        <p class="text-xs text-slate-600 mt-0.5">{{ $t('digital_access.low_credits_warning_desc') }}</p>
      </div>
      <Button 
        :label="$t('digital_access.top_up')" 
        size="small"
        class="bg-amber-500 hover:bg-amber-600 border-0 flex-shrink-0"
        @click="navigateToCredits"
      />
    </div>

    <div v-if="showTotalLimitWarning && !showLowCreditWarning" class="flex items-center gap-4 p-4 bg-red-50 rounded-xl border border-red-200">
      <div class="p-2 bg-red-500 rounded-lg flex-shrink-0">
        <i class="pi pi-exclamation-circle text-white"></i>
      </div>
      <div class="flex-1 min-w-0">
        <p class="font-semibold text-slate-900 text-sm">{{ $t('digital_access.approaching_limit') }}</p>
        <p class="text-xs text-slate-600 mt-0.5">{{ $t('digital_access.approaching_limit_desc', { percent: totalUsagePercent.toFixed(0) }) }}</p>
      </div>
    </div>

    <!-- Settings Cards -->
    <div class="grid grid-cols-1 lg:grid-cols-2 gap-4 lg:gap-6">
      <!-- Total Access Limit Card -->
      <div 
        class="bg-white rounded-xl shadow-lg border overflow-hidden transition-all duration-200"
        :class="isEditingTotal ? 'border-blue-300 ring-2 ring-blue-100' : 'border-slate-200 hover:border-slate-300'"
      >
        <!-- Header -->
        <div 
          class="p-4 border-b flex items-center justify-between cursor-pointer group"
          :class="isEditingTotal ? 'bg-blue-50 border-blue-200' : 'bg-slate-50 border-slate-200 hover:bg-slate-100'"
          @click="!isEditingTotal && startEditTotal()"
        >
          <div class="flex items-center gap-3">
            <div class="p-2 bg-gradient-to-r from-blue-500 to-indigo-500 rounded-lg">
              <i class="pi pi-shield text-white"></i>
            </div>
            <div>
              <h3 class="font-semibold text-slate-900">{{ $t('digital_access.total_limit') }}</h3>
              <p class="text-xs text-slate-500">{{ $t('digital_access.total_limit_hint') }}</p>
            </div>
          </div>
          <i 
            v-if="!isEditingTotal" 
            class="pi pi-pencil text-slate-400 group-hover:text-blue-500 transition-colors"
          ></i>
        </div>
        
        <!-- Content -->
        <div class="p-4">
          <!-- View Mode -->
          <div v-if="!isEditingTotal" class="text-center py-2">
            <div v-if="card.max_scans">
              <p class="text-3xl font-bold text-slate-900">{{ formatNumber(card.max_scans) }}</p>
              <p class="text-sm text-slate-500 mt-1">{{ $t('digital_access.total_scans_allowed') }}</p>
              <div class="mt-3 inline-flex items-center gap-2 px-3 py-1.5 bg-blue-50 rounded-full text-sm text-blue-700">
                <i class="pi pi-chart-line text-xs"></i>
                {{ formatNumber(card.max_scans - (card.current_scans || 0)) }} {{ $t('digital_access.remaining') }}
              </div>
            </div>
            <div v-else class="py-4">
              <div class="inline-flex items-center gap-2 px-4 py-2 bg-green-50 rounded-full">
                <i class="pi pi-infinity text-green-600"></i>
                <span class="font-medium text-green-700">{{ $t('digital_access.unlimited_access') }}</span>
              </div>
            </div>
          </div>
          
          <!-- Edit Mode -->
          <div v-else class="space-y-4">
            <div class="flex items-center justify-between p-3 bg-slate-50 rounded-lg">
              <span class="text-sm font-medium text-slate-700">{{ $t('digital_access.enable_total_limit') }}</span>
              <ToggleSwitch v-model="hasTotalLimit" />
            </div>
            
            <div v-if="hasTotalLimit" class="flex flex-col items-center gap-2">
              <InputNumber 
                v-model="totalLimit"
                :min="Math.max(1, (card.current_scans || 0) + 1)"
                :max="10000000"
                :step="1000"
                showButtons
                buttonLayout="horizontal"
                class="w-full max-w-[220px]"
              />
              <span class="text-xs text-slate-500">{{ $t('digital_access.total_scans_allowed') }}</span>
              <div v-if="totalLimit > (card.current_scans || 0)" class="text-xs text-blue-600">
                {{ formatNumber(totalLimit - (card.current_scans || 0)) }} {{ $t('digital_access.remaining') }}
              </div>
            </div>
            
            <div v-else class="text-center py-2">
              <div class="inline-flex items-center gap-2 px-4 py-2 bg-green-50 rounded-full">
                <i class="pi pi-infinity text-green-600"></i>
                <span class="font-medium text-green-700">{{ $t('digital_access.unlimited_access') }}</span>
              </div>
            </div>
            
            <!-- Action buttons -->
            <div class="flex gap-2 pt-3 border-t border-slate-200">
              <Button 
                :label="$t('common.cancel')"
                severity="secondary"
                outlined
                size="small"
                class="flex-1"
                @click="cancelEditTotal"
              />
              <Button 
                :label="$t('common.save')"
                :loading="isSavingTotal"
                icon="pi pi-check"
                size="small"
                class="flex-1"
                @click="saveTotalLimit"
              />
            </div>
          </div>
        </div>
      </div>

      <!-- Daily Limit Card -->
      <div 
        class="bg-white rounded-xl shadow-lg border overflow-hidden transition-all duration-200"
        :class="isEditingDaily ? 'border-purple-300 ring-2 ring-purple-100' : 'border-slate-200 hover:border-slate-300'"
      >
        <!-- Header -->
        <div 
          class="p-4 border-b flex items-center justify-between cursor-pointer group"
          :class="isEditingDaily ? 'bg-purple-50 border-purple-200' : 'bg-slate-50 border-slate-200 hover:bg-slate-100'"
          @click="!isEditingDaily && startEditDaily()"
        >
          <div class="flex items-center gap-3">
            <div class="p-2 bg-gradient-to-r from-purple-500 to-violet-500 rounded-lg">
              <i class="pi pi-clock text-white"></i>
            </div>
            <div>
              <h3 class="font-semibold text-slate-900">{{ $t('digital_access.daily_limit') }}</h3>
              <p class="text-xs text-slate-500">{{ $t('digital_access.set_daily_limit_hint') }}</p>
            </div>
          </div>
          <i 
            v-if="!isEditingDaily" 
            class="pi pi-pencil text-slate-400 group-hover:text-purple-500 transition-colors"
          ></i>
        </div>
        
        <!-- Content -->
        <div class="p-4">
          <!-- View Mode -->
          <div v-if="!isEditingDaily" class="text-center py-2">
            <div v-if="card.daily_scan_limit">
              <p class="text-3xl font-bold text-slate-900">{{ formatNumber(card.daily_scan_limit) }}</p>
              <p class="text-sm text-slate-500 mt-1">{{ $t('digital_access.scans_per_day') }}</p>
              <div class="mt-3 inline-flex items-center gap-2 px-3 py-1.5 bg-purple-50 rounded-full text-sm text-purple-700">
                <i class="pi pi-calculator text-xs"></i>
                {{ $t('digital_access.max_daily_cost') }}: {{ (card.daily_scan_limit * creditRate).toFixed(2) }} {{ $t('common.credits') }}
              </div>
            </div>
            <div v-else class="py-4">
              <div class="inline-flex items-center gap-2 px-4 py-2 bg-green-50 rounded-full">
                <i class="pi pi-infinity text-green-600"></i>
                <span class="font-medium text-green-700">{{ $t('digital_access.unlimited_daily') }}</span>
              </div>
            </div>
          </div>
          
          <!-- Edit Mode -->
          <div v-else class="space-y-4">
            <div class="flex items-center justify-between p-3 bg-slate-50 rounded-lg">
              <span class="text-sm font-medium text-slate-700">{{ $t('digital_access.enable_daily_limit') }}</span>
              <ToggleSwitch v-model="hasDailyLimit" />
            </div>
            
            <div v-if="hasDailyLimit" class="flex flex-col items-center gap-2">
              <InputNumber 
                v-model="dailyLimit"
                :min="1"
                :max="100000"
                :step="100"
                showButtons
                buttonLayout="horizontal"
                class="w-full max-w-[220px]"
              />
              <span class="text-xs text-slate-500">{{ $t('digital_access.scans_per_day') }}</span>
              <div class="text-xs text-purple-600">
                {{ $t('digital_access.max_daily_cost') }}: {{ (dailyLimit * creditRate).toFixed(2) }} {{ $t('common.credits') }}
              </div>
            </div>
            
            <div v-else class="text-center py-2">
              <div class="inline-flex items-center gap-2 px-4 py-2 bg-green-50 rounded-full">
                <i class="pi pi-infinity text-green-600"></i>
                <span class="font-medium text-green-700">{{ $t('digital_access.unlimited_daily') }}</span>
              </div>
            </div>
            
            <!-- Action buttons -->
            <div class="flex gap-2 pt-3 border-t border-slate-200">
              <Button 
                :label="$t('common.cancel')"
                severity="secondary"
                outlined
                size="small"
                class="flex-1"
                @click="cancelEditDaily"
              />
              <Button 
                :label="$t('common.save')"
                :loading="isSavingDaily"
                icon="pi pi-check"
                size="small"
                class="flex-1"
                @click="saveDailyLimit"
              />
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue'
import { useRouter } from 'vue-router'
import { useToast } from 'primevue/usetoast'
import { useI18n } from 'vue-i18n'
import { useCreditStore } from '@/stores/credits'
import { useCardStore, type Card } from '@/stores/card'
import Button from 'primevue/button'
import InputNumber from 'primevue/inputnumber'
import ToggleSwitch from 'primevue/toggleswitch'

const { t } = useI18n()
const toast = useToast()
const router = useRouter()
const creditStore = useCreditStore()
const cardStore = useCardStore()

// Props
const props = defineProps<{
  card: Card
}>()

// Emit
const emit = defineEmits<{
  (e: 'updated', card: Card): void
}>()

// Edit mode states
const isEditingTotal = ref(false)
const isEditingDaily = ref(false)
const isSavingTotal = ref(false)
const isSavingDaily = ref(false)

// Form values
const totalLimit = ref<number>(10000)
const dailyLimit = ref<number>(500)
const hasTotalLimit = ref(false)
const hasDailyLimit = ref(true)

// Get credit rate from env
const creditRate = Number(import.meta.env.VITE_DIGITAL_ACCESS_CREDIT_RATE) || 0.03

// Computed
const creditBalance = computed(() => creditStore.balance || 0)

const totalUsagePercent = computed(() => {
  if (!props.card.max_scans) return 0
  return Math.min(100, ((props.card.current_scans || 0) / props.card.max_scans) * 100)
})

const dailyUsagePercent = computed(() => {
  if (!props.card.daily_scan_limit) return 0
  return Math.min(100, ((props.card.daily_scans || 0) / props.card.daily_scan_limit) * 100)
})

const showLowCreditWarning = computed(() => {
  const limit = props.card.daily_scan_limit || 500
  const maxDailyCost = limit * creditRate
  return creditBalance.value < maxDailyCost && creditBalance.value > 0
})

const showTotalLimitWarning = computed(() => {
  return props.card.max_scans && totalUsagePercent.value >= 80
})

const estimatedRunway = computed(() => {
  if (creditBalance.value <= 0 || creditRate <= 0) return 0
  return Math.floor(creditBalance.value / creditRate)
})

// Methods
function formatNumber(num: number): string {
  if (num >= 1000000) return (num / 1000000).toFixed(1) + 'M'
  if (num >= 1000) return (num / 1000).toFixed(1) + 'K'
  return num.toLocaleString()
}

function navigateToCredits() {
  router.push('/cms/credits')
}

// Total Limit edit functions
function startEditTotal() {
  if (props.card.max_scans === null || props.card.max_scans === undefined) {
    hasTotalLimit.value = false
    totalLimit.value = 10000
  } else {
    hasTotalLimit.value = true
    totalLimit.value = props.card.max_scans
  }
  isEditingTotal.value = true
}

function cancelEditTotal() {
  isEditingTotal.value = false
}

async function saveTotalLimit() {
  isSavingTotal.value = true
  
  try {
    const newTotalLimit = hasTotalLimit.value ? totalLimit.value : null
    
    await cardStore.updateCard(props.card.id, {
      name: props.card.name,
      description: props.card.description,
      conversation_ai_enabled: props.card.conversation_ai_enabled,
      ai_instruction: props.card.ai_instruction,
      ai_knowledge_base: props.card.ai_knowledge_base,
      qr_code_position: props.card.qr_code_position,
      billing_type: props.card.billing_type,
      content_mode: props.card.content_mode,
      max_scans: newTotalLimit,
      daily_scan_limit: props.card.daily_scan_limit
    })
    
    toast.add({
      severity: 'success',
      summary: t('common.success'),
      detail: t('digital_access.settings_saved'),
      life: 3000
    })
    
    emit('updated', {
      ...props.card,
      max_scans: newTotalLimit
    })
    
    isEditingTotal.value = false
    
  } catch (err: any) {
    console.error('Error saving total limit:', err)
    toast.add({
      severity: 'error',
      summary: t('common.error'),
      detail: err.message || t('digital_access.settings_save_error'),
      life: 5000
    })
  } finally {
    isSavingTotal.value = false
  }
}

// Daily Limit edit functions
function startEditDaily() {
  if (props.card.daily_scan_limit === null || props.card.daily_scan_limit === undefined) {
    hasDailyLimit.value = false
    dailyLimit.value = 500
  } else {
    hasDailyLimit.value = true
    dailyLimit.value = props.card.daily_scan_limit
  }
  isEditingDaily.value = true
}

function cancelEditDaily() {
  isEditingDaily.value = false
}

async function saveDailyLimit() {
  isSavingDaily.value = true
  
  try {
    const newDailyLimit = hasDailyLimit.value ? dailyLimit.value : null
    
    await cardStore.updateCard(props.card.id, {
      name: props.card.name,
      description: props.card.description,
      conversation_ai_enabled: props.card.conversation_ai_enabled,
      ai_instruction: props.card.ai_instruction,
      ai_knowledge_base: props.card.ai_knowledge_base,
      qr_code_position: props.card.qr_code_position,
      billing_type: props.card.billing_type,
      content_mode: props.card.content_mode,
      max_scans: props.card.max_scans,
      daily_scan_limit: newDailyLimit
    })
    
    toast.add({
      severity: 'success',
      summary: t('common.success'),
      detail: t('digital_access.settings_saved'),
      life: 3000
    })
    
    emit('updated', {
      ...props.card,
      daily_scan_limit: newDailyLimit
    })
    
    isEditingDaily.value = false
    
  } catch (err: any) {
    console.error('Error saving daily limit:', err)
    toast.add({
      severity: 'error',
      summary: t('common.error'),
      detail: err.message || t('digital_access.settings_save_error'),
      life: 5000
    })
  } finally {
    isSavingDaily.value = false
  }
}

// Initialize
onMounted(async () => {
  await creditStore.fetchCreditBalance()
})

// Watch toggles to set sensible defaults
watch(hasTotalLimit, (enabled) => {
  if (enabled && !totalLimit.value) {
    totalLimit.value = 10000
  }
})

watch(hasDailyLimit, (enabled) => {
  if (enabled && !dailyLimit.value) {
    dailyLimit.value = 500
  }
})
</script>

<style scoped>
/* No PrimeVue overrides - using default PrimeVue styling */
</style>
