<template>
  <div class="space-y-6">
    <!-- Statistics Cards -->
    <div class="grid grid-cols-1 md:grid-cols-3 gap-4 lg:gap-6">
      <!-- Total Sessions Card (Analytics) -->
      <div class="bg-white rounded-xl shadow-lg border border-slate-200 p-5 hover:shadow-xl transition-shadow">
        <div class="flex items-center justify-between mb-3">
          <h3 class="text-sm font-medium text-slate-600">{{ $t('digital_access.total_sessions') }}</h3>
          <div class="p-2.5 bg-gradient-to-r from-blue-500 to-indigo-500 rounded-lg">
            <i class="pi pi-chart-line text-white text-lg"></i>
          </div>
        </div>
        <p class="text-2xl lg:text-3xl font-bold text-slate-900">
          {{ formatNumber(card.total_sessions || 0) }}
        </p>
        <p class="text-xs text-slate-500 mt-2">{{ $t('digital_access.all_time_sessions') }}</p>
      </div>

      <!-- Today's Sessions Card (Aggregated across all QR codes) -->
      <div class="bg-white rounded-xl shadow-lg border border-slate-200 p-5 hover:shadow-xl transition-shadow">
        <div class="flex items-center justify-between mb-3">
          <h3 class="text-sm font-medium text-slate-600">{{ $t('digital_access.today_sessions') }}</h3>
          <div class="p-2.5 bg-gradient-to-r from-purple-500 to-violet-500 rounded-lg">
            <i class="pi pi-calendar text-white text-lg"></i>
          </div>
        </div>
        <p class="text-2xl lg:text-3xl font-bold text-slate-900">
          {{ card.daily_sessions || 0 }}
        </p>
        <p class="text-xs text-slate-500 mt-2">{{ $t('digital_access.daily_protection_info') }}</p>
        
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

      <!-- Subscription Status Card -->
      <div class="relative overflow-hidden bg-gradient-to-br from-slate-900 via-slate-800 to-slate-900 rounded-xl shadow-lg p-5 text-white hover:shadow-xl transition-shadow">
        <!-- Decorative elements -->
        <div class="absolute top-0 right-0 w-32 h-32 bg-gradient-to-br from-emerald-500/20 to-transparent rounded-full -translate-y-1/2 translate-x-1/2"></div>
        <div class="absolute bottom-0 left-0 w-24 h-24 bg-gradient-to-tr from-teal-500/10 to-transparent rounded-full translate-y-1/2 -translate-x-1/2"></div>
        
        <!-- Content -->
        <div class="relative">
          <div class="flex items-center gap-2 mb-2">
            <i class="pi pi-sparkles text-emerald-400 text-sm"></i>
            <h3 class="text-xs font-medium text-slate-400 uppercase tracking-wider">{{ $t('digital_access.billing_model') }}</h3>
          </div>
          
          <div class="flex items-baseline gap-1.5 mb-2">
            <p class="text-xl lg:text-2xl font-bold bg-gradient-to-r from-white to-slate-200 bg-clip-text text-transparent">
              {{ $t('digital_access.subscription_billing') }}
            </p>
          </div>
          
          <p class="text-xs text-slate-400 mb-4">
            {{ $t('digital_access.subscription_billing_desc') }}
          </p>
          
          <div class="pt-3 border-t border-slate-700/50">
            <Button 
              :label="$t('digital_access.view_subscription')" 
              icon="pi pi-external-link"
              size="small"
              class="bg-emerald-500 hover:bg-emerald-600 border-0 text-xs font-semibold px-3"
              @click="navigateToSubscription"
            />
          </div>
        </div>
      </div>
    </div>

    <!-- Default Daily Session Limit Settings Card -->
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
            <i class="pi pi-shield text-white"></i>
            </div>
            <div>
              <h3 class="font-semibold text-slate-900">{{ $t('digital_access.default_daily_limit') }}</h3>
            <p class="text-xs text-slate-500">{{ $t('digital_access.default_daily_limit_hint') }}</p>
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
          <div v-if="card.default_daily_session_limit">
            <p class="text-3xl font-bold text-slate-900">{{ formatNumber(card.default_daily_session_limit) }}</p>
            <p class="text-sm text-slate-500 mt-1">{{ $t('digital_access.sessions_per_day') }}</p>
              <div class="mt-3 inline-flex items-center gap-2 px-3 py-1.5 bg-purple-50 rounded-full text-sm text-purple-700">
              <i class="pi pi-info-circle text-xs"></i>
              {{ $t('digital_access.default_limit_info') }}
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
            <span class="text-xs text-slate-500">{{ $t('digital_access.sessions_per_day') }}</span>
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
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import { useRouter } from 'vue-router'
import { useToast } from 'primevue/usetoast'
import { useI18n } from 'vue-i18n'
import { useCardStore, type Card } from '@/stores/card'
import Button from 'primevue/button'
import InputNumber from 'primevue/inputnumber'
import ToggleSwitch from 'primevue/toggleswitch'

const { t } = useI18n()
const toast = useToast()
const router = useRouter()
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
const isEditingDaily = ref(false)
const isSavingDaily = ref(false)

// Form values
const dailyLimit = ref<number>(500)
const hasDailyLimit = ref(true)

// Computed
const dailyUsagePercent = computed(() => {
  if (!props.card.default_daily_session_limit) return 0
  return Math.min(100, ((props.card.daily_sessions || 0) / props.card.default_daily_session_limit) * 100)
})

// Methods
function formatNumber(num: number): string {
  if (num >= 1000000) return (num / 1000000).toFixed(1) + 'M'
  if (num >= 1000) return (num / 1000).toFixed(1) + 'K'
  return num.toLocaleString()
}

function navigateToSubscription() {
  router.push('/cms/subscription')
}

// Daily Limit edit functions
function startEditDaily() {
  if (props.card.default_daily_session_limit === null || props.card.default_daily_session_limit === undefined) {
    hasDailyLimit.value = false
    dailyLimit.value = 500
  } else {
    hasDailyLimit.value = true
    dailyLimit.value = props.card.default_daily_session_limit
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
      default_daily_session_limit: newDailyLimit
    })
    
    toast.add({
      severity: 'success',
      summary: t('common.success'),
      detail: t('digital_access.settings_saved'),
      life: 3000
    })
    
    emit('updated', {
      ...props.card,
      default_daily_session_limit: newDailyLimit
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

// Watch toggle to set sensible defaults
watch(hasDailyLimit, (enabled) => {
  if (enabled && !dailyLimit.value) {
    dailyLimit.value = 500
  }
})
</script>

<style scoped>
/* No PrimeVue overrides - using default PrimeVue styling */
</style>
