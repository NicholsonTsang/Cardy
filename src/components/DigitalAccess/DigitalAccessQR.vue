<template>
  <div class="space-y-6">
    <!-- Header -->
    <div class="text-center">
      <h3 class="text-lg font-semibold text-slate-900 mb-2">{{ $t('digital_access.qr_code') }}</h3>
      <p class="text-slate-600 text-sm">{{ $t('digital_access.qr_code_description') }}</p>
    </div>

    <!-- Access Control Card -->
    <div class="bg-white rounded-xl shadow-lg border border-slate-200 overflow-hidden">
      <div class="p-4 border-b border-slate-200 bg-gradient-to-r from-slate-50 to-slate-100">
        <div class="flex items-center justify-between">
          <div class="flex items-center gap-3">
            <div 
              class="p-2 rounded-lg"
              :class="isAccessEnabled ? 'bg-gradient-to-r from-emerald-500 to-teal-500' : 'bg-gradient-to-r from-slate-400 to-slate-500'"
            >
              <i :class="isAccessEnabled ? 'pi pi-lock-open' : 'pi pi-lock'" class="text-white"></i>
            </div>
            <div>
              <h4 class="font-semibold text-slate-900">{{ $t('digital_access.access_control') }}</h4>
              <p class="text-xs text-slate-500">{{ $t('digital_access.access_control_desc') }}</p>
            </div>
          </div>
          <div class="flex items-center gap-4">
            <span 
              class="text-sm font-medium"
              :class="isAccessEnabled ? 'text-emerald-600' : 'text-slate-500'"
            >
              {{ isAccessEnabled ? $t('digital_access.access_enabled') : $t('digital_access.access_disabled') }}
            </span>
            <ToggleSwitch 
              v-if="!readOnly"
              :modelValue="isAccessEnabled" 
              @update:modelValue="handleToggleAccess"
              :disabled="isTogglingAccess"
            />
          </div>
        </div>
      </div>
    </div>

    <!-- Main QR Card -->
    <div 
      class="bg-white rounded-xl shadow-lg border overflow-hidden transition-all duration-300"
      :class="isAccessEnabled ? 'border-slate-200' : 'border-red-200 opacity-75'"
    >
      <!-- Header -->
      <div 
        class="p-4 border-b"
        :class="isAccessEnabled 
          ? 'border-slate-200 bg-gradient-to-r from-slate-50 to-slate-100' 
          : 'border-red-200 bg-gradient-to-r from-red-50 to-orange-50'"
      >
        <div class="flex items-center justify-between">
          <div class="flex items-center gap-3">
            <div 
              class="p-2 rounded-lg"
              :class="isAccessEnabled 
                ? 'bg-gradient-to-r from-blue-500 to-purple-500' 
                : 'bg-gradient-to-r from-red-400 to-orange-400'"
            >
              <i class="pi pi-qrcode text-white"></i>
            </div>
            <div>
              <h4 class="font-semibold text-slate-900">{{ cardName }}</h4>
              <p class="text-xs text-slate-500">{{ $t('digital_access.content_name') }}</p>
            </div>
          </div>
          <!-- Refresh QR Button (hidden in read-only mode) -->
          <Button 
            v-if="!readOnly"
            :label="$t('digital_access.refresh_qr')"
            icon="pi pi-refresh"
            severity="warning"
            outlined
            size="small"
            @click="handleRefreshToken"
            :loading="isRefreshing"
            v-tooltip.left="$t('digital_access.refresh_qr_tooltip')"
          />
        </div>
      </div>
      
      <!-- Access Disabled Warning -->
      <div v-if="!isAccessEnabled" class="px-6 pt-4">
        <div class="flex items-center gap-3 p-3 bg-red-50 border border-red-200 rounded-lg">
          <i class="pi pi-exclamation-triangle text-red-600"></i>
          <p class="text-sm text-red-700">{{ $t('digital_access.qr_disabled_warning') }}</p>
        </div>
      </div>
      
      <div class="p-6 lg:p-8">
        <div class="flex flex-col lg:flex-row items-center gap-8">
          <!-- QR Code Display -->
          <div class="flex-shrink-0">
            <div class="relative group">
              <!-- Decorative rings with hover effect -->
              <div 
                class="absolute -inset-4 rounded-3xl transition-all duration-300"
                :class="isAccessEnabled 
                  ? 'bg-gradient-to-r from-blue-500/10 to-purple-500/10 group-hover:from-blue-500/20 group-hover:to-purple-500/20' 
                  : 'bg-gradient-to-r from-slate-300/20 to-slate-400/20'"
              ></div>
              <div 
                class="absolute -inset-2 rounded-2xl"
                :class="isAccessEnabled 
                  ? 'bg-gradient-to-r from-blue-500/5 to-purple-500/5' 
                  : 'bg-gradient-to-r from-slate-300/10 to-slate-400/10'"
              ></div>
              <!-- QR Code -->
              <div 
                class="relative bg-white p-5 rounded-xl border-2 shadow-lg transition-all duration-300"
                :class="isAccessEnabled 
                  ? 'border-slate-200 group-hover:shadow-xl group-hover:border-blue-200' 
                  : 'border-slate-300 grayscale'"
              >
                <QrCode :value="accessUrl" :size="200" level="M" />
                <!-- Disabled Overlay -->
                <div 
                  v-if="!isAccessEnabled" 
                  class="absolute inset-0 bg-white/60 flex items-center justify-center rounded-xl"
                >
                  <div class="text-center">
                    <i class="pi pi-lock text-4xl text-slate-400 mb-2"></i>
                    <p class="text-sm font-medium text-slate-500">{{ $t('digital_access.disabled') }}</p>
                  </div>
                </div>
              </div>
            </div>
          </div>
          
          <!-- QR Code Info & Actions -->
          <div class="flex-1 w-full text-center lg:text-left space-y-5">
            <!-- URL Display -->
            <div>
              <label class="text-xs font-medium text-slate-500 uppercase tracking-wider">{{ $t('digital_access.access_url') }}</label>
              <div class="mt-2 flex items-center gap-2 bg-slate-50 rounded-lg p-3 border border-slate-200">
                <code class="flex-1 text-sm text-slate-700 break-all font-mono">{{ accessUrl }}</code>
                <Button 
                  icon="pi pi-copy"
                  severity="secondary"
                  text
                  rounded
                  size="small"
                  @click="copyUrl"
                  v-tooltip.top="$t('common.copy')"
                  :disabled="!isAccessEnabled"
                />
              </div>
            </div>
            
            <!-- Action Buttons -->
            <div class="flex flex-wrap gap-3 justify-center lg:justify-start">
              <Button 
                :label="$t('digital_access.download_qr')"
                icon="pi pi-download"
                @click="downloadQrCode"
                class="bg-gradient-to-r from-blue-600 to-purple-600 hover:from-blue-700 hover:to-purple-700 border-0"
                :disabled="!isAccessEnabled"
              />
              <Button 
                :label="$t('digital_access.open_preview')"
                icon="pi pi-external-link"
                severity="secondary"
                outlined
                @click="openPreview"
                :disabled="!isAccessEnabled"
              />
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Usage Stats -->
    <div class="bg-white rounded-xl shadow-lg border border-slate-200 overflow-hidden">
      <div class="p-4 border-b border-slate-100 bg-slate-50/50">
        <div class="grid grid-cols-3 gap-4">
          <div class="text-center">
            <div class="flex items-center justify-center gap-2 mb-1">
              <i class="pi pi-eye text-blue-600 text-sm"></i>
              <span class="text-xs font-medium text-slate-500 uppercase tracking-wider">{{ $t('digital_access.total_scans') }}</span>
            </div>
            <p class="text-2xl font-bold text-slate-900">{{ formatNumber(card.current_scans || 0) }}</p>
            <p v-if="card.max_scans" class="text-xs text-slate-400 mt-0.5">/ {{ formatNumber(card.max_scans) }}</p>
          </div>
          <div class="text-center border-x border-slate-200">
            <div class="flex items-center justify-center gap-2 mb-1">
              <i class="pi pi-calendar text-purple-600 text-sm"></i>
              <span class="text-xs font-medium text-slate-500 uppercase tracking-wider">{{ $t('digital_access.today_scans') }}</span>
            </div>
            <p class="text-2xl font-bold text-slate-900">{{ card.daily_scans || 0 }}</p>
            <p v-if="card.daily_scan_limit" class="text-xs text-slate-400 mt-0.5">/ {{ card.daily_scan_limit }}</p>
          </div>
          <div class="text-center">
            <div class="flex items-center justify-center gap-2 mb-1">
              <i class="pi pi-check-circle text-emerald-600 text-sm"></i>
              <span class="text-xs font-medium text-slate-500 uppercase tracking-wider">{{ $t('common.status') }}</span>
            </div>
            <p class="text-2xl font-bold" :class="isCardActive ? 'text-emerald-600' : 'text-red-600'">
              {{ isCardActive ? $t('common.active') : $t('common.inactive') }}
            </p>
          </div>
        </div>
      </div>
    </div>

    <!-- Tips Card (hidden in read-only mode) -->
    <div v-if="!readOnly" class="bg-gradient-to-r from-blue-50 to-purple-50 rounded-xl border border-blue-200 p-5">
      <div class="flex items-start gap-4">
        <div class="p-2 bg-gradient-to-r from-blue-500 to-purple-500 rounded-lg flex-shrink-0">
          <i class="pi pi-lightbulb text-white"></i>
        </div>
        <div>
          <h4 class="font-semibold text-slate-900 mb-2">{{ $t('digital_access.qr_tips_title') }}</h4>
          <ul class="space-y-1.5 text-sm text-slate-700">
            <li class="flex items-start gap-2">
              <i class="pi pi-check text-blue-600 text-xs mt-1"></i>
              <span>{{ $t('digital_access.qr_tip_1') }}</span>
            </li>
            <li class="flex items-start gap-2">
              <i class="pi pi-check text-blue-600 text-xs mt-1"></i>
              <span>{{ $t('digital_access.qr_tip_2') }}</span>
            </li>
            <li class="flex items-start gap-2">
              <i class="pi pi-check text-blue-600 text-xs mt-1"></i>
              <span>{{ $t('digital_access.qr_tip_3') }}</span>
            </li>
            <li class="flex items-start gap-2">
              <i class="pi pi-check text-blue-600 text-xs mt-1"></i>
              <span>{{ $t('digital_access.qr_tip_refresh') }}</span>
            </li>
          </ul>
        </div>
      </div>
    </div>

    <!-- Refresh Confirmation Dialog -->
    <Dialog 
      v-model:visible="showRefreshDialog" 
      :header="$t('digital_access.refresh_qr_confirm_title')"
      :style="{ width: '450px' }"
      :modal="true"
      :closable="true"
    >
      <div class="flex items-start gap-4">
        <div class="p-3 bg-amber-100 rounded-full flex-shrink-0">
          <i class="pi pi-exclamation-triangle text-amber-600 text-xl"></i>
        </div>
        <div>
          <p class="text-slate-700 mb-3">{{ $t('digital_access.refresh_qr_confirm_message') }}</p>
          <ul class="text-sm text-slate-600 space-y-1 list-disc list-inside">
            <li>{{ $t('digital_access.refresh_qr_warning_1') }}</li>
            <li>{{ $t('digital_access.refresh_qr_warning_2') }}</li>
          </ul>
        </div>
      </div>
      <template #footer>
        <Button 
          :label="$t('common.cancel')" 
          severity="secondary" 
          outlined
          @click="showRefreshDialog = false" 
        />
        <Button 
          :label="$t('digital_access.refresh_qr_confirm')" 
          severity="warning"
          icon="pi pi-refresh"
          @click="confirmRefreshToken" 
          :loading="isRefreshing"
        />
      </template>
    </Dialog>
  </div>
</template>

<script setup lang="ts">
import { computed, ref } from 'vue'
import { useToast } from 'primevue/usetoast'
import { useI18n } from 'vue-i18n'
import { useCardStore, type Card } from '@/stores/card'
import Button from 'primevue/button'
import Dialog from 'primevue/dialog'
import ToggleSwitch from 'primevue/toggleswitch'
import QrCode from 'qrcode.vue'
import * as QRCodeLib from 'qrcode'

const { t } = useI18n()
const toast = useToast()
const cardStore = useCardStore()

const props = withDefaults(defineProps<{
  card: Card
  cardName: string
  readOnly?: boolean
}>(), {
  readOnly: false
})

const emit = defineEmits<{
  (e: 'updated', card: Card): void
}>()

// State
const isTogglingAccess = ref(false)
const isRefreshing = ref(false)
const showRefreshDialog = ref(false)

// Computed
const accessUrl = computed(() => {
  // Use access_token for the URL instead of card.id
  return `${window.location.origin}/c/${props.card.access_token}`
})

const isAccessEnabled = computed(() => {
  return props.card.is_access_enabled ?? true
})

const isCardActive = computed(() => {
  // A digital card is active if it has not exceeded total scans and access is enabled
  if (!isAccessEnabled.value) return false
  if (props.card.max_scans && (props.card.current_scans || 0) >= props.card.max_scans) {
    return false
  }
  return true
})

// Methods
function formatNumber(num: number): string {
  if (num >= 1000000) return (num / 1000000).toFixed(1) + 'M'
  if (num >= 1000) return (num / 1000).toFixed(1) + 'K'
  return num.toLocaleString()
}

async function handleToggleAccess(newValue: boolean) {
  isTogglingAccess.value = true
  
  try {
    const success = await cardStore.toggleCardAccess(props.card.id, newValue)
    
    if (success) {
      toast.add({
        severity: 'success',
        summary: t('common.success'),
        detail: newValue 
          ? t('digital_access.access_enabled_success') 
          : t('digital_access.access_disabled_success'),
        life: 3000
      })
      
      emit('updated', {
        ...props.card,
        is_access_enabled: newValue
      })
    }
  } catch (err: any) {
    toast.add({
      severity: 'error',
      summary: t('common.error'),
      detail: err.message || t('digital_access.toggle_failed'),
      life: 5000
    })
  } finally {
    isTogglingAccess.value = false
  }
}

function handleRefreshToken() {
  showRefreshDialog.value = true
}

async function confirmRefreshToken() {
  isRefreshing.value = true
  
  try {
    const newToken = await cardStore.regenerateAccessToken(props.card.id)
    
    if (newToken) {
      showRefreshDialog.value = false
      
      toast.add({
        severity: 'success',
        summary: t('common.success'),
        detail: t('digital_access.token_refreshed'),
        life: 3000
      })
      
      emit('updated', {
        ...props.card,
        access_token: newToken
      })
    }
  } catch (err: any) {
    toast.add({
      severity: 'error',
      summary: t('common.error'),
      detail: err.message || t('digital_access.refresh_failed'),
      life: 5000
    })
  } finally {
    isRefreshing.value = false
  }
}

async function copyUrl() {
  try {
    await navigator.clipboard.writeText(accessUrl.value)
    toast.add({
      severity: 'success',
      summary: t('common.copied'),
      detail: t('digital_access.url_copied'),
      life: 2000
    })
  } catch (err) {
    toast.add({
      severity: 'error',
      summary: t('common.error'),
      detail: t('digital_access.copy_failed'),
      life: 3000
    })
  }
}

async function downloadQrCode() {
  try {
    const qrDataURL = await QRCodeLib.toDataURL(accessUrl.value, { 
      width: 512,
      margin: 2,
      errorCorrectionLevel: 'M'
    })
    
    const link = document.createElement('a')
    link.href = qrDataURL
    link.download = `${props.cardName || 'digital-access'}_qr.png`
    document.body.appendChild(link)
    link.click()
    document.body.removeChild(link)
    
    toast.add({
      severity: 'success',
      summary: t('common.success'),
      detail: t('digital_access.qr_downloaded'),
      life: 2000
    })
  } catch (err) {
    toast.add({
      severity: 'error',
      summary: t('common.error'),
      detail: t('digital_access.download_failed'),
      life: 3000
    })
  }
}

function openPreview() {
  window.open(accessUrl.value, '_blank')
}
</script>

<style scoped>
/* No custom styles - using Tailwind */
</style>
