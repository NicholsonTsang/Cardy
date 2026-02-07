<template>
  <div class="space-y-6">
    <!-- Section Header with Explanation -->
    <div class="bg-gradient-to-r from-slate-50 to-slate-100 rounded-xl p-4 border border-slate-200">
      <div class="flex items-start gap-3">
        <div class="p-2 bg-slate-200 rounded-lg flex-shrink-0">
          <i class="pi pi-sliders-h text-slate-600"></i>
        </div>
        <div>
          <h3 class="text-base font-semibold text-slate-900">{{ $t('digital_access.control_settings_title') }}</h3>
          <p class="text-sm text-slate-600 mt-1">{{ $t('digital_access.control_settings_description') }}</p>
        </div>
      </div>
    </div>

    <!-- Statistics Cards -->
    <div class="grid grid-cols-1 md:grid-cols-3 gap-4 lg:gap-6">
      <!-- Total Sessions Card (Analytics) -->
      <div class="bg-white rounded-xl shadow-lg border border-slate-200 p-5 hover:shadow-xl transition-shadow">
        <div class="flex items-center justify-between mb-3">
          <h3 class="text-sm font-medium text-slate-600">{{ $t('digital_access.total_sessions') }}</h3>
          <div class="p-2.5 bg-gradient-to-r from-blue-500 to-indigo-500 rounded-lg" v-tooltip.top="$t('digital_access.total_sessions_tooltip')">
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

    <!-- Session Window Information Card -->
    <div class="bg-gradient-to-r from-blue-50 to-indigo-50 rounded-xl shadow-md border border-blue-200 overflow-hidden">
      <div class="p-5">
        <div class="flex items-start gap-4">
          <!-- Icon -->
          <div class="flex-shrink-0 p-3 bg-gradient-to-br from-blue-500 to-indigo-600 rounded-xl shadow-md">
            <i class="pi pi-clock text-white text-xl"></i>
          </div>

          <!-- Content -->
          <div class="flex-1 min-w-0">
            <h3 class="text-lg font-bold text-slate-900 mb-2">{{ $t('digital_access.session_window_title') }}</h3>
            <p class="text-sm text-slate-700 leading-relaxed mb-3">
              {{ $t('digital_access.session_window_description') }}
            </p>

            <!-- Key Points -->
            <div class="space-y-2">
              <div class="flex items-start gap-2">
                <i class="pi pi-check-circle text-blue-600 text-sm mt-0.5 flex-shrink-0"></i>
                <p class="text-sm text-slate-600">{{ $t('digital_access.session_window_benefit_1') }}</p>
              </div>
              <div class="flex items-start gap-2">
                <i class="pi pi-check-circle text-blue-600 text-sm mt-0.5 flex-shrink-0"></i>
                <p class="text-sm text-slate-600">{{ $t('digital_access.session_window_benefit_2') }}</p>
              </div>
              <div class="flex items-start gap-2">
                <i class="pi pi-check-circle text-blue-600 text-sm mt-0.5 flex-shrink-0"></i>
                <p class="text-sm text-slate-600">{{ $t('digital_access.session_window_benefit_3') }}</p>
              </div>
            </div>

            <!-- Duration Badge -->
            <div class="mt-4 inline-flex items-center gap-2 px-4 py-2 bg-white/80 backdrop-blur-sm rounded-full border border-blue-200 shadow-sm">
              <i class="pi pi-stopwatch text-blue-600"></i>
              <span class="text-sm font-semibold text-blue-900">{{ $t('digital_access.session_window_duration') }}</span>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Default Daily Session Limit Settings Card -->
    <div class="bg-white rounded-xl shadow-lg border border-slate-200 overflow-hidden">
      <!-- Header -->
      <div class="p-4 border-b border-slate-200 bg-slate-50">
        <div class="flex items-center gap-3">
          <div class="p-2 bg-gradient-to-r from-purple-500 to-violet-500 rounded-lg">
            <i class="pi pi-shield text-white"></i>
          </div>
          <div>
            <h3 class="font-semibold text-slate-900">{{ $t('digital_access.default_daily_limit') }}</h3>
            <p class="text-xs text-slate-500">{{ $t('digital_access.default_daily_limit_hint') }}</p>
          </div>
        </div>
      </div>

      <!-- Content - Always visible controls -->
      <div class="p-4 space-y-4">
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

        <!-- Info hint -->
        <p class="text-xs text-slate-500 text-center">
          <i class="pi pi-info-circle text-xs mr-1"></i>
          {{ $t('digital_access.default_limit_info') }}
        </p>

        <!-- Action buttons - only shown when value has changed -->
        <div v-if="hasUnsavedChanges" class="flex gap-2 pt-3 border-t border-slate-200">
          <Button
            :label="$t('common.cancel')"
            severity="secondary"
            outlined
            size="small"
            class="flex-1"
            @click="resetDailyLimit"
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
import { formatNumber } from '@/utils/formatters'

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

// State
const isSavingDaily = ref(false)

// Form values - initialized from props
const dailyLimit = ref<number>(props.card.default_daily_session_limit ?? 500)
const hasDailyLimit = ref(props.card.default_daily_session_limit != null)

// Detect unsaved changes
const hasUnsavedChanges = computed(() => {
  const currentValue = hasDailyLimit.value ? dailyLimit.value : null
  return currentValue !== (props.card.default_daily_session_limit ?? null)
})

// Methods
function navigateToSubscription() {
  router.push('/cms/subscription')
}

function resetDailyLimit() {
  if (props.card.default_daily_session_limit == null) {
    hasDailyLimit.value = false
    dailyLimit.value = 500
  } else {
    hasDailyLimit.value = true
    dailyLimit.value = props.card.default_daily_session_limit
  }
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

// Sync form values when card prop changes (e.g. after save)
watch(() => props.card.default_daily_session_limit, (newVal) => {
  if (newVal == null) {
    hasDailyLimit.value = false
    dailyLimit.value = 500
  } else {
    hasDailyLimit.value = true
    dailyLimit.value = newVal
  }
})

// Set sensible default when toggle is enabled
watch(hasDailyLimit, (enabled) => {
  if (enabled && !dailyLimit.value) {
    dailyLimit.value = 500
  }
})
</script>
