<template>
  <div class="space-y-6">
    <!-- Section Header with Explanation -->
    <div class="bg-gradient-to-r from-blue-50 to-indigo-50 rounded-xl p-4 border border-blue-200">
      <div class="flex items-start gap-3">
        <div class="p-2 bg-blue-100 rounded-lg flex-shrink-0">
          <i class="pi pi-qrcode text-blue-600"></i>
        </div>
        <div class="flex-1">
          <h3 class="text-base font-semibold text-blue-900">{{ $t('digital_access.qr_access_title') }}</h3>
          <p class="text-sm text-blue-700 mt-1">{{ $t('digital_access.qr_access_explanation') }}</p>
        </div>
      </div>
    </div>

    <!-- Header with Add Button -->
    <div class="flex items-center justify-between">
      <div>
        <h3 class="text-lg font-semibold text-slate-900">{{ $t('digital_access.qr_codes_title') }}</h3>
        <p class="text-slate-600 text-sm">{{ $t('digital_access.qr_codes_description') }}</p>
      </div>
      <div class="flex items-center gap-2">
        <Button
          :label="$t('digital_access.view_subscription')"
          icon="pi pi-sparkles"
          size="small"
          severity="secondary"
          outlined
          @click="navigateToSubscription"
        />
        <Button
          v-if="!readOnly"
          :label="$t('digital_access.add_qr_code')"
          icon="pi pi-plus"
          size="small"
          class="bg-gradient-to-r from-blue-600 to-purple-600 hover:from-blue-700 hover:to-purple-700 border-0"
          @click="openAddDialog"
          v-tooltip.left="$t('digital_access.add_qr_tooltip')"
        />
      </div>
    </div>

    <!-- Monthly Stats Summary -->
    <div class="bg-gradient-to-r from-slate-900 via-slate-800 to-slate-900 rounded-xl shadow-lg p-5 text-white">
      <div class="flex items-center gap-2 mb-3">
        <i class="pi pi-calendar text-emerald-400"></i>
        <h4 class="text-sm font-medium text-slate-400 uppercase tracking-wider">{{ $t('digital_access.monthly_summary') }}</h4>
      </div>
      <div class="grid grid-cols-2 md:grid-cols-4 gap-4">
        <div class="text-center">
          <p class="text-2xl font-bold text-white">{{ monthlyStats?.totalMonthlySessions || 0 }}</p>
          <p class="text-xs text-slate-400">{{ $t('digital_access.this_month') }}</p>
        </div>
        <div class="text-center">
          <p class="text-2xl font-bold text-white">{{ monthlyStats?.totalDailySessions || 0 }}</p>
          <p class="text-xs text-slate-400">{{ $t('digital_access.today') }}</p>
        </div>
        <div class="text-center">
          <p class="text-2xl font-bold text-white">{{ monthlyStats?.totalAllTimeSessions || 0 }}</p>
          <p class="text-xs text-slate-400">{{ $t('digital_access.all_time') }}</p>
        </div>
        <div class="text-center">
          <p class="text-2xl font-bold text-emerald-400">{{ monthlyStats?.activeQrCodes || 0 }}</p>
          <p class="text-xs text-slate-400">{{ $t('digital_access.active_qr_codes') }} / {{ monthlyStats?.totalQrCodes || 0 }}</p>
        </div>
      </div>
      <div class="mt-3 text-xs text-slate-500 text-center">
        {{ $t('digital_access.billing_period') }}: {{ formatDate(monthlyStats?.monthStart) }} - {{ formatDate(monthlyStats?.monthEnd) }}
      </div>
    </div>

    <!-- Loading State -->
    <div v-if="isLoading" class="flex items-center justify-center py-12">
      <ProgressSpinner />
    </div>

    <!-- QR Codes List -->
    <div v-else-if="accessTokens.length > 0" class="space-y-4">
      <div 
        v-for="token in accessTokens" 
        :key="token.id"
        class="bg-white rounded-xl shadow-lg border overflow-hidden transition-all duration-200"
        :class="token.is_enabled ? 'border-slate-200 hover:border-blue-200' : 'border-slate-300 opacity-75'"
      >
        <!-- Token Header -->
        <div 
          class="p-4 border-b flex items-center justify-between cursor-pointer"
          :class="token.is_enabled ? 'bg-slate-50 border-slate-200' : 'bg-slate-100 border-slate-300'"
          @click="toggleTokenExpanded(token.id)"
        >
          <div class="flex items-center gap-3">
            <div 
              class="p-2 rounded-lg"
              :class="token.is_enabled 
                ? 'bg-gradient-to-r from-blue-500 to-purple-500' 
                : 'bg-slate-400'"
            >
              <i class="pi pi-qrcode text-white"></i>
            </div>
            <div>
              <h4 class="font-semibold text-slate-900">{{ token.name }}</h4>
              <p class="text-xs text-slate-500">
                {{ $t('digital_access.monthly') }}: {{ token.monthly_sessions || 0 }} · 
                {{ $t('digital_access.today') }}: {{ token.daily_sessions || 0 }}
                <span v-if="token.daily_session_limit"> / {{ token.daily_session_limit }}</span>
              </p>
            </div>
          </div>
          <div class="flex items-center gap-3">
            <span 
              class="text-sm font-medium px-2 py-1 rounded-full"
              :class="token.is_enabled 
                ? 'bg-emerald-100 text-emerald-700' 
                : 'bg-slate-200 text-slate-600'"
            >
              {{ token.is_enabled ? $t('common.active') : $t('common.inactive') }}
            </span>
            <i 
              class="pi transition-transform duration-200"
              :class="expandedTokenIds.has(token.id) ? 'pi-chevron-up' : 'pi-chevron-down'"
            ></i>
          </div>
        </div>

        <!-- Expanded Content -->
        <div v-if="expandedTokenIds.has(token.id)" class="p-6">
          <div class="flex flex-col lg:flex-row items-center gap-8">
            <!-- QR Code Display -->
            <div class="flex-shrink-0">
              <div class="relative group">
                <div 
                  class="relative bg-white p-4 rounded-xl border-2 shadow-lg"
                  :class="token.is_enabled ? 'border-slate-200' : 'border-slate-300 grayscale'"
                >
                  <QrCode :value="getAccessUrl(token.access_token)" :size="160" level="M" />
                  <div 
                    v-if="!token.is_enabled" 
                    class="absolute inset-0 bg-white/60 flex items-center justify-center rounded-xl"
                  >
                    <i class="pi pi-lock text-3xl text-slate-400"></i>
                  </div>
                </div>
              </div>
            </div>

            <!-- Token Info & Actions -->
            <div class="flex-1 w-full space-y-4">
              <!-- URL Display -->
              <div>
                <label class="text-xs font-medium text-slate-500 uppercase tracking-wider">{{ $t('digital_access.access_url') }}</label>
                <div class="mt-1 flex items-center gap-2 bg-slate-50 rounded-lg p-2 border border-slate-200">
                  <code class="flex-1 text-xs text-slate-700 break-all font-mono">{{ getAccessUrl(token.access_token) }}</code>
                  <Button 
                    icon="pi pi-copy"
                    severity="secondary"
                    text
                    rounded
                    size="small"
                    @click="copyUrl(token.access_token)"
                    :disabled="!token.is_enabled"
                  />
                </div>
              </div>

              <!-- Stats -->
              <div class="grid grid-cols-3 gap-2 text-center">
                <div class="bg-slate-50 rounded-lg p-2">
                  <p class="text-lg font-bold text-slate-900">{{ token.total_sessions || 0 }}</p>
                  <p class="text-xs text-slate-500">{{ $t('digital_access.total') }}</p>
                </div>
                <div class="bg-slate-50 rounded-lg p-2">
                  <p class="text-lg font-bold text-slate-900">{{ token.monthly_sessions || 0 }}
                    <span v-if="token.monthly_session_limit" class="text-xs font-normal text-slate-400">/ {{ token.monthly_session_limit }}</span>
                  </p>
                  <p class="text-xs text-slate-500">{{ $t('digital_access.monthly') }}</p>
                </div>
                <div class="bg-slate-50 rounded-lg p-2">
                  <p class="text-lg font-bold text-slate-900">{{ token.daily_sessions || 0 }}
                    <span v-if="token.daily_session_limit" class="text-xs font-normal text-slate-400">/ {{ token.daily_session_limit }}</span>
                  </p>
                  <p class="text-xs text-slate-500">{{ $t('digital_access.daily') }}</p>
                </div>
              </div>

              <!-- Voice Limits (always shown) -->
              <div class="flex flex-wrap gap-2">
                <!-- Daily voice limit -->
                <div
                  class="flex items-center gap-1 text-xs rounded-full px-3 py-1 transition-opacity"
                  :class="token.daily_voice_limit && card.conversation_ai_enabled
                    ? 'bg-purple-50 text-purple-700'
                    : 'bg-slate-100 text-slate-400'"
                >
                  <i class="pi pi-microphone text-xs"></i>
                  <span>
                    {{ $t('digital_access.daily') }}:
                    <template v-if="token.daily_voice_limit">{{ formatVoiceTime(token.daily_voice_limit) }}</template>
                    <template v-else>∞</template>
                  </span>
                </div>
                <!-- Monthly voice limit -->
                <div
                  class="flex items-center gap-1 text-xs rounded-full px-3 py-1 transition-opacity"
                  :class="token.monthly_voice_limit && card.conversation_ai_enabled
                    ? 'bg-purple-50 text-purple-700'
                    : 'bg-slate-100 text-slate-400'"
                >
                  <i class="pi pi-microphone text-xs"></i>
                  <span>
                    {{ $t('digital_access.monthly') }}:
                    <template v-if="token.monthly_voice_limit">{{ formatVoiceTime(token.monthly_voice_limit) }}</template>
                    <template v-else>∞</template>
                  </span>
                </div>
              </div>

              <!-- Actions -->
              <div v-if="!readOnly" class="flex flex-wrap items-center gap-2">
                <Button
                  :label="$t('digital_access.download_qr')"
                  icon="pi pi-download"
                  size="small"
                  @click="downloadQrCode(token)"
                  :disabled="!token.is_enabled"
                />
                <Button
                  :icon="token.is_enabled ? 'pi pi-pause' : 'pi pi-play'"
                  :severity="token.is_enabled ? 'warning' : 'success'"
                  outlined
                  size="small"
                  @click="toggleTokenEnabled(token)"
                  :loading="togglingTokenId === token.id"
                  v-tooltip="token.is_enabled ? $t('digital_access.disable') : $t('digital_access.enable')"
                />
                <Button
                  icon="pi pi-ellipsis-v"
                  severity="secondary"
                  text
                  rounded
                  size="small"
                  @click="toggleOverflowMenu($event, token)"
                  v-tooltip="$t('common.more_actions')"
                />
                <Menu :ref="(el) => setOverflowMenuRef(token.id, el)" :model="getOverflowMenuItems(token)" :popup="true" />
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Empty State -->
    <div v-else class="text-center py-12 bg-slate-50 rounded-xl border border-dashed border-slate-300">
      <i class="pi pi-qrcode text-4xl text-slate-400 mb-3"></i>
      <p class="text-slate-600">{{ $t('digital_access.no_qr_codes') }}</p>
      <Button 
        v-if="!readOnly"
        :label="$t('digital_access.create_first_qr')"
        icon="pi pi-plus"
        size="small"
        class="mt-4"
        @click="openAddDialog"
      />
    </div>

    <!-- Add/Edit Dialog -->
    <Dialog
      v-model:visible="showAddDialog"
      :header="editingToken ? $t('digital_access.edit_qr_code') : $t('digital_access.add_qr_code')"
      :style="{ width: '90vw', maxWidth: '52rem' }"
      :modal="true"
    >
      <div class="space-y-4">
        <!-- Name -->
        <div>
          <label class="block text-sm font-medium text-slate-700 mb-1">{{ $t('digital_access.qr_name') }}</label>
          <InputText
            v-model="formData.name"
            class="w-full"
            :placeholder="$t('digital_access.qr_name_placeholder')"
          />
          <p class="text-xs text-slate-500 mt-1">{{ $t('digital_access.qr_name_hint') }}</p>
        </div>

        <!-- Session Limits section -->
        <div class="border border-slate-200 rounded-lg overflow-hidden">
          <div class="bg-slate-50 px-3 py-2 border-b border-slate-200">
            <p class="text-xs font-semibold text-slate-600 uppercase tracking-wider">{{ $t('digital_access.session_limits') }}</p>
          </div>
          <div class="p-3 space-y-3">
            <!-- Daily session limit -->
            <div>
              <div class="flex items-center justify-between">
                <span class="text-sm font-medium text-slate-700">{{ $t('digital_access.enable_daily_limit') }}</span>
                <ToggleSwitch v-model="formData.hasDailyLimit" />
              </div>
              <div v-if="formData.hasDailyLimit" class="mt-2">
                <InputNumber
                  v-model="formData.daily_session_limit"
                  :min="1"
                  :max="100000"
                  showButtons
                  class="w-full"
                />
                <p class="text-xs text-slate-500 mt-1">{{ $t('digital_access.daily_limit_hint') }}</p>
              </div>
            </div>

            <!-- Monthly session limit -->
            <div class="pt-2 border-t border-slate-100">
              <div class="flex items-center justify-between">
                <span class="text-sm font-medium text-slate-700">{{ $t('digital_access.enable_monthly_session_limit') }}</span>
                <ToggleSwitch v-model="formData.hasMonthlySessionLimit" />
              </div>
              <div v-if="formData.hasMonthlySessionLimit" class="mt-2">
                <InputNumber
                  v-model="formData.monthly_session_limit"
                  :min="1"
                  :max="1000000"
                  showButtons
                  class="w-full"
                />
                <p class="text-xs text-slate-500 mt-1">{{ $t('digital_access.monthly_session_limit_hint') }}</p>
              </div>
            </div>
          </div>
        </div>

        <!-- Voice Limits section -->
        <div class="border border-slate-200 rounded-lg overflow-hidden">
          <div class="bg-slate-50 px-3 py-2 border-b border-slate-200">
            <p class="text-xs font-semibold text-slate-600 uppercase tracking-wider">{{ $t('digital_access.voice_limits') }}</p>
          </div>
          <div class="p-3 space-y-3">
            <!-- Daily voice limit -->
            <div>
              <div class="flex items-center justify-between">
                <span class="text-sm font-medium text-slate-700">{{ $t('digital_access.enable_daily_voice_limit') }}</span>
                <ToggleSwitch v-model="formData.hasDailyVoiceLimit" />
              </div>
              <div v-if="formData.hasDailyVoiceLimit" class="mt-2">
                <InputNumber
                  v-model="formData.daily_voice_limit"
                  :min="60"
                  :max="86400"
                  :step="60"
                  showButtons
                  class="w-full"
                />
                <p class="text-xs text-slate-500 mt-1">{{ $t('digital_access.daily_voice_limit_hint') }}</p>
              </div>
            </div>

            <!-- Monthly voice limit -->
            <div class="pt-2 border-t border-slate-100">
              <div class="flex items-center justify-between">
                <span class="text-sm font-medium text-slate-700">{{ $t('digital_access.enable_monthly_voice_limit') }}</span>
                <ToggleSwitch v-model="formData.hasMonthlyVoiceLimit" />
              </div>
              <div v-if="formData.hasMonthlyVoiceLimit" class="mt-2">
                <InputNumber
                  v-model="formData.monthly_voice_limit"
                  :min="60"
                  :max="2592000"
                  :step="60"
                  showButtons
                  class="w-full"
                />
                <p class="text-xs text-slate-500 mt-1">{{ $t('digital_access.monthly_voice_limit_hint') }}</p>
              </div>
            </div>
          </div>
        </div>
      </div>

      <template #footer>
        <Button
          :label="$t('common.cancel')"
          severity="secondary"
          outlined
          @click="closeDialog"
        />
        <Button
          :label="editingToken ? $t('common.save') : $t('common.create')"
          icon="pi pi-check"
          @click="saveToken"
          :loading="isSaving"
        />
      </template>
    </Dialog>

    <!-- Delete Confirmation Dialog -->
    <Dialog 
      v-model:visible="showDeleteDialog" 
      :header="$t('digital_access.delete_qr_confirm_title')"
      :style="{ width: '90vw', maxWidth: '36rem' }"
      :modal="true"
    >
      <div class="flex items-start gap-4">
        <div class="p-3 bg-red-100 rounded-full flex-shrink-0">
          <i class="pi pi-exclamation-triangle text-red-600 text-xl"></i>
        </div>
        <div>
          <p class="text-slate-700 mb-2">{{ $t('digital_access.delete_qr_confirm_message') }}</p>
          <p class="text-sm text-slate-600 font-medium">"{{ deletingToken?.name }}"</p>
        </div>
      </div>
      <template #footer>
        <Button 
          :label="$t('common.cancel')" 
          severity="secondary" 
          outlined
          @click="showDeleteDialog = false" 
        />
        <Button 
          :label="$t('common.delete')"
          severity="danger"
          icon="pi pi-trash"
          @click="deleteToken" 
          :loading="isDeleting"
        />
      </template>
    </Dialog>

    <!-- Refresh Confirmation Dialog -->
    <Dialog 
      v-model:visible="showRefreshDialog" 
      :header="$t('digital_access.refresh_qr_confirm_title')"
      :style="{ width: '90vw', maxWidth: '36rem' }"
      :modal="true"
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
          :loading="refreshingTokenId !== null"
        />
      </template>
    </Dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, watch } from 'vue'
import { useRouter } from 'vue-router'
import { useToast } from 'primevue/usetoast'
import { useI18n } from 'vue-i18n'
import { useCardStore, type Card, type AccessToken } from '@/stores/card'
import Button from 'primevue/button'
import Dialog from 'primevue/dialog'
import InputText from 'primevue/inputtext'
import InputNumber from 'primevue/inputnumber'
import ToggleSwitch from 'primevue/toggleswitch'
import Menu from 'primevue/menu'
import ProgressSpinner from 'primevue/progressspinner'
import QrCode from 'qrcode.vue'
import * as QRCodeLib from 'qrcode'
import { formatDate } from '@/utils/formatters'

const { t } = useI18n()
const toast = useToast()
const router = useRouter()
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

// Utility: format seconds into "Xh Ym" or "Ym" or "Xs"
function formatVoiceTime(seconds: number): string {
  if (seconds < 60) return `${seconds}s`
  const h = Math.floor(seconds / 3600)
  const m = Math.floor((seconds % 3600) / 60)
  if (h > 0 && m > 0) return `${h}h ${m}m`
  if (h > 0) return `${h}h`
  return `${m}m`
}

// Env-var defaults for new QR code form
const defaultDailySessionLimit = Number(import.meta.env.VITE_DIGITAL_ACCESS_DEFAULT_DAILY_LIMIT) || 500
const defaultDailyVoiceLimit = Number(import.meta.env.VITE_DIGITAL_ACCESS_DEFAULT_DAILY_VOICE_LIMIT) || null

function navigateToSubscription() {
  router.push('/cms/subscription')
}

// State
const isLoading = ref(false)
const accessTokens = ref<AccessToken[]>([])
const expandedTokenIds = ref<Set<string>>(new Set())
const monthlyStats = ref<{
  monthStart: string
  monthEnd: string
  totalMonthlySessions: number
  totalDailySessions: number
  totalAllTimeSessions: number
  activeQrCodes: number
  totalQrCodes: number
} | null>(null)

// Dialog states
const showAddDialog = ref(false)
const showDeleteDialog = ref(false)
const showRefreshDialog = ref(false)
const editingToken = ref<AccessToken | null>(null)
const deletingToken = ref<AccessToken | null>(null)
const refreshingToken = ref<AccessToken | null>(null)

// Loading states
const isSaving = ref(false)
const isDeleting = ref(false)
const togglingTokenId = ref<string | null>(null)
const refreshingTokenId = ref<string | null>(null)

// Form data
const formData = ref({
  name: '',
  daily_session_limit: defaultDailySessionLimit,
  hasDailyLimit: defaultDailySessionLimit != null,
  monthly_session_limit: 5000,
  hasMonthlySessionLimit: false,
  daily_voice_limit: defaultDailyVoiceLimit ?? 3600,
  hasDailyVoiceLimit: defaultDailyVoiceLimit != null,
  monthly_voice_limit: 36000,
  hasMonthlyVoiceLimit: false
})

// Load data
async function loadData() {
  isLoading.value = true
  try {
    const [tokens, stats] = await Promise.all([
      cardStore.fetchAccessTokens(props.card.id),
      cardStore.getCardMonthlyStats(props.card.id)
    ])
    accessTokens.value = tokens
    monthlyStats.value = stats

    // Expand all tokens by default
    expandedTokenIds.value = new Set(tokens.map((t: AccessToken) => t.id))
  } catch (err) {
    console.error('Error loading access tokens:', err)
  } finally {
    isLoading.value = false
  }
}

onMounted(loadData)

// Watch for card changes
watch(() => props.card.id, loadData)

// Methods
function getAccessUrl(token: string): string {
  return `${window.location.origin}/c/${token}`
}

function toggleTokenExpanded(tokenId: string) {
  if (expandedTokenIds.value.has(tokenId)) {
    expandedTokenIds.value.delete(tokenId)
  } else {
    expandedTokenIds.value.add(tokenId)
  }
  // Trigger reactivity (Set mutations aren't tracked automatically)
  expandedTokenIds.value = new Set(expandedTokenIds.value)
}

// Overflow menu
const overflowMenuRefs = ref<Record<string, any>>({})

function setOverflowMenuRef(tokenId: string, el: any) {
  if (el) overflowMenuRefs.value[tokenId] = el
  else delete overflowMenuRefs.value[tokenId]
}

function toggleOverflowMenu(event: Event, token: AccessToken) {
  overflowMenuRefs.value[token.id]?.toggle(event)
  // Store token ref for menu item actions
  currentMenuToken.value = token
}

const currentMenuToken = ref<AccessToken | null>(null)

function getOverflowMenuItems(token: AccessToken) {
  return [
    {
      label: t('digital_access.open_preview'),
      icon: 'pi pi-external-link',
      disabled: !token.is_enabled,
      command: () => openPreview(token.access_token)
    },
    {
      label: t('common.edit'),
      icon: 'pi pi-pencil',
      command: () => editToken(token)
    },
    {
      label: t('digital_access.refresh_qr_tooltip'),
      icon: 'pi pi-refresh',
      command: () => refreshToken(token)
    },
    { separator: true },
    {
      label: t('common.delete'),
      icon: 'pi pi-trash',
      disabled: accessTokens.value.length <= 1,
      class: 'text-red-600',
      command: () => confirmDeleteToken(token)
    }
  ]
}

async function copyUrl(token: string) {
  try {
    await navigator.clipboard.writeText(getAccessUrl(token))
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

async function downloadQrCode(token: AccessToken) {
  try {
    const qrDataURL = await QRCodeLib.toDataURL(getAccessUrl(token.access_token), { 
      width: 512,
      margin: 2,
      errorCorrectionLevel: 'M'
    })
    
    const link = document.createElement('a')
    link.href = qrDataURL
    link.download = `${token.name || 'qr-code'}_qr.png`
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

function openPreview(token: string) {
  window.open(getAccessUrl(token), '_blank')
}

async function toggleTokenEnabled(token: AccessToken) {
  togglingTokenId.value = token.id
  try {
    await cardStore.toggleAccessToken(token.id, props.card.id, !token.is_enabled)
    await loadData()
    
    toast.add({
      severity: 'success',
      summary: t('common.success'),
      detail: token.is_enabled 
        ? t('digital_access.qr_disabled') 
        : t('digital_access.qr_enabled'),
      life: 3000
    })
  } catch (err: any) {
    toast.add({
      severity: 'error',
      summary: t('common.error'),
      detail: err.message || t('digital_access.toggle_failed'),
      life: 5000
    })
  } finally {
    togglingTokenId.value = null
  }
}

function editToken(token: AccessToken) {
  editingToken.value = token
  formData.value = {
    name: token.name,
    daily_session_limit: token.daily_session_limit || 500,
    hasDailyLimit: token.daily_session_limit !== null,
    monthly_session_limit: token.monthly_session_limit || 5000,
    hasMonthlySessionLimit: token.monthly_session_limit !== null,
    daily_voice_limit: token.daily_voice_limit || 3600,
    hasDailyVoiceLimit: token.daily_voice_limit !== null,
    monthly_voice_limit: token.monthly_voice_limit || 36000,
    hasMonthlyVoiceLimit: token.monthly_voice_limit !== null
  }
  showAddDialog.value = true
}

function openAddDialog() {
  editingToken.value = null
  formData.value = {
    name: '',
    daily_session_limit: defaultDailySessionLimit,
    hasDailyLimit: defaultDailySessionLimit != null,
    monthly_session_limit: 5000,
    hasMonthlySessionLimit: false,
    daily_voice_limit: defaultDailyVoiceLimit ?? 3600,
    hasDailyVoiceLimit: defaultDailyVoiceLimit != null,
    monthly_voice_limit: 36000,
    hasMonthlyVoiceLimit: false
  }
  showAddDialog.value = true
}

function closeDialog() {
  showAddDialog.value = false
  editingToken.value = null
  formData.value = {
    name: '',
    daily_session_limit: defaultDailySessionLimit,
    hasDailyLimit: defaultDailySessionLimit != null,
    monthly_session_limit: 5000,
    hasMonthlySessionLimit: false,
    daily_voice_limit: defaultDailyVoiceLimit ?? 3600,
    hasDailyVoiceLimit: defaultDailyVoiceLimit != null,
    monthly_voice_limit: 36000,
    hasMonthlyVoiceLimit: false
  }
}

async function saveToken() {
  if (!formData.value.name.trim()) {
    toast.add({
      severity: 'warn',
      summary: t('common.warning'),
      detail: t('digital_access.name_required'),
      life: 3000
    })
    return
  }

  isSaving.value = true
  try {
    const dailySessionLimit = formData.value.hasDailyLimit ? formData.value.daily_session_limit : null
    const monthlySessionLimit = formData.value.hasMonthlySessionLimit ? formData.value.monthly_session_limit : null
    const dailyVoiceLimit = formData.value.hasDailyVoiceLimit ? formData.value.daily_voice_limit : null
    const monthlyVoiceLimit = formData.value.hasMonthlyVoiceLimit ? formData.value.monthly_voice_limit : null

    if (editingToken.value) {
      // Update existing
      await cardStore.updateAccessToken(editingToken.value.id, props.card.id, {
        name: formData.value.name,
        daily_session_limit: dailySessionLimit,
        monthly_session_limit: monthlySessionLimit,
        daily_voice_limit: dailyVoiceLimit,
        monthly_voice_limit: monthlyVoiceLimit
      })
    } else {
      // Create new
      await cardStore.createAccessToken(props.card.id, {
        name: formData.value.name,
        daily_session_limit: dailySessionLimit,
        monthly_session_limit: monthlySessionLimit,
        daily_voice_limit: dailyVoiceLimit,
        monthly_voice_limit: monthlyVoiceLimit
      })
    }
    
    await loadData()
    closeDialog()
    
    toast.add({
      severity: 'success',
      summary: t('common.success'),
      detail: editingToken.value 
        ? t('digital_access.qr_updated') 
        : t('digital_access.qr_created'),
      life: 3000
    })
  } catch (err: any) {
    toast.add({
      severity: 'error',
      summary: t('common.error'),
      detail: err.message || t('digital_access.save_failed'),
      life: 5000
    })
  } finally {
    isSaving.value = false
  }
}

function confirmDeleteToken(token: AccessToken) {
  deletingToken.value = token
  showDeleteDialog.value = true
}

async function deleteToken() {
  if (!deletingToken.value) return
  
  isDeleting.value = true
  try {
    await cardStore.deleteAccessToken(deletingToken.value.id, props.card.id)
    await loadData()
    showDeleteDialog.value = false
    deletingToken.value = null
    
    toast.add({
      severity: 'success',
      summary: t('common.success'),
      detail: t('digital_access.qr_deleted'),
      life: 3000
    })
  } catch (err: any) {
    toast.add({
      severity: 'error',
      summary: t('common.error'),
      detail: err.message || t('digital_access.delete_failed'),
      life: 5000
    })
  } finally {
    isDeleting.value = false
  }
}

function refreshToken(token: AccessToken) {
  refreshingToken.value = token
  showRefreshDialog.value = true
}

async function confirmRefreshToken() {
  if (!refreshingToken.value) return
  
  refreshingTokenId.value = refreshingToken.value.id
  try {
    await cardStore.refreshAccessToken(refreshingToken.value.id, props.card.id)
    await loadData()
    showRefreshDialog.value = false
    refreshingToken.value = null
    
    toast.add({
      severity: 'success',
      summary: t('common.success'),
      detail: t('digital_access.token_refreshed'),
      life: 3000
    })
  } catch (err: any) {
    toast.add({
      severity: 'error',
      summary: t('common.error'),
      detail: err.message || t('digital_access.refresh_failed'),
      life: 5000
    })
  } finally {
    refreshingTokenId.value = null
  }
}
</script>
