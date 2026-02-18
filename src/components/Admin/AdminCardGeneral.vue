<template>
  <div class="space-y-6">
    <!-- Hero Header with Gradient -->
    <div class="rounded-xl p-4 sm:p-6 bg-gradient-to-r from-cyan-500 to-blue-600">
      <div class="flex items-center gap-4">
        <div class="w-14 h-14 rounded-xl flex items-center justify-center shadow-lg bg-white/20">
          <i class="pi pi-qrcode text-2xl text-white"></i>
        </div>
        <div class="flex-1 min-w-0">
          <h2 class="text-xl font-bold text-white truncate">{{ card.name }}</h2>
          <div class="flex items-center gap-2 mt-1 flex-wrap">
            <span class="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-medium bg-white/20 text-white">
              {{ $t('dashboard.digital_access') }}
            </span>
            <span class="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-medium bg-white/20 text-white">
              <i :class="getContentModeIcon(card.content_mode)" class="text-[10px]"></i>
              {{ getContentModeLabel(card.content_mode) }}
            </span>
          </div>
        </div>
      </div>
    </div>

    <!-- Quick Stats Row -->
    <div class="grid grid-cols-2 sm:grid-cols-4 gap-3">
      <!-- Total Scans -->
      <div class="bg-white rounded-lg border border-slate-200 p-3 hover:shadow-md transition-shadow">
        <div class="flex items-center gap-2">
          <div class="w-8 h-8 rounded-lg bg-cyan-100 flex items-center justify-center flex-shrink-0">
            <i class="pi pi-eye text-cyan-600 text-sm"></i>
          </div>
          <div class="min-w-0">
            <p class="text-xs text-slate-500 truncate">{{ $t('admin.total_sessions') }}</p>
            <p class="text-lg font-bold text-slate-900">{{ (card.total_sessions || 0).toLocaleString() }}</p>
          </div>
        </div>
      </div>
      <!-- Daily Scans -->
      <div class="bg-white rounded-lg border border-slate-200 p-3 hover:shadow-md transition-shadow">
        <div class="flex items-center gap-2">
          <div class="w-8 h-8 rounded-lg bg-blue-100 flex items-center justify-center flex-shrink-0">
            <i class="pi pi-calendar text-blue-600 text-sm"></i>
          </div>
          <div class="min-w-0">
            <p class="text-xs text-slate-500 truncate">{{ $t('admin.today_sessions') }}</p>
            <p class="text-lg font-bold text-slate-900">{{ (card.daily_sessions || 0).toLocaleString() }}</p>
          </div>
        </div>
      </div>
      <!-- Monthly Sessions -->
      <div class="bg-white rounded-lg border border-slate-200 p-3 hover:shadow-md transition-shadow">
        <div class="flex items-center gap-2">
          <div class="w-8 h-8 rounded-lg bg-purple-100 flex items-center justify-center flex-shrink-0">
            <i class="pi pi-calendar-plus text-purple-600 text-sm"></i>
          </div>
          <div class="min-w-0">
            <p class="text-xs text-slate-500 truncate">{{ $t('admin.monthly_sessions') }}</p>
            <p class="text-lg font-bold text-slate-900">
              {{ (card.monthly_sessions || 0).toLocaleString() }}
            </p>
          </div>
        </div>
      </div>
      <!-- QR Codes -->
      <div class="bg-white rounded-lg border border-slate-200 p-3 hover:shadow-md transition-shadow">
        <div class="flex items-center gap-2">
          <div class="w-8 h-8 rounded-lg bg-amber-100 flex items-center justify-center flex-shrink-0">
            <i class="pi pi-qrcode text-amber-600 text-sm"></i>
          </div>
          <div class="min-w-0">
            <p class="text-xs text-slate-500 truncate">{{ $t('admin.qr_codes') }}</p>
            <p class="text-lg font-bold text-slate-900">
              {{ card.active_qr_codes || 0 }} / {{ card.total_qr_codes || 0 }}
            </p>
          </div>
        </div>
      </div>
    </div>

    <div>
      <!-- Card Details -->
      <div>
        <div class="bg-white rounded-xl border border-slate-200 p-4 space-y-4">
          <div>
            <label class="block text-xs font-medium text-slate-500 mb-1">{{ $t('common.description') }}</label>
            <p class="text-sm text-slate-700">{{ card.description || $t('dashboard.no_description') }}</p>
          </div>

          <div class="grid grid-cols-2 sm:grid-cols-3 gap-4 pt-3 border-t border-slate-100">
            <div>
              <label class="block text-xs font-medium text-slate-500 mb-1">{{ $t('dashboard.qr_position') }}</label>
              <span class="inline-flex items-center px-2 py-1 rounded bg-slate-100 text-slate-700 text-sm font-medium">
                {{ card.qr_code_position }}
              </span>
            </div>

            <div>
              <label class="block text-xs font-medium text-slate-500 mb-1">{{ $t('dashboard.ai_enabled') }}</label>
              <span 
                class="inline-flex items-center gap-1 px-2 py-1 rounded text-sm font-medium"
                :class="card.conversation_ai_enabled ? 'bg-green-100 text-green-700' : 'bg-slate-100 text-slate-500'"
              >
                <i :class="card.conversation_ai_enabled ? 'pi pi-check-circle' : 'pi pi-minus-circle'" class="text-xs"></i>
                {{ card.conversation_ai_enabled ? $t('common.yes') : $t('common.no') }}
              </span>
            </div>

            <div>
              <label class="block text-xs font-medium text-slate-500 mb-1">{{ $t('dashboard.access_mode') }}</label>
              <span class="inline-flex items-center gap-1 px-2 py-1 rounded text-sm font-medium bg-cyan-100 text-cyan-700">
                <i class="pi pi-qrcode text-xs"></i>
                {{ $t('dashboard.digital_access') }}
              </span>
            </div>
          </div>

          <!-- AI Configuration -->
          <div v-if="card.ai_instruction || card.ai_knowledge_base || card.ai_welcome_general || card.ai_welcome_item" class="pt-3 border-t border-slate-100 space-y-3">
            <div v-if="card.ai_instruction">
              <label class="block text-xs font-medium text-blue-600 mb-1 flex items-center gap-1">
                <i class="pi pi-user text-[10px]"></i>
                {{ $t('dashboard.ai_instruction') }}
              </label>
              <div class="p-3 bg-blue-50 rounded-lg border border-blue-100 text-sm text-slate-700 whitespace-pre-wrap max-h-32 overflow-y-auto">
                {{ card.ai_instruction }}
              </div>
            </div>

            <div v-if="card.ai_knowledge_base">
              <label class="block text-xs font-medium text-amber-600 mb-1 flex items-center gap-1">
                <i class="pi pi-database text-[10px]"></i>
                {{ $t('dashboard.ai_knowledge_base') }}
              </label>
              <div class="p-3 bg-amber-50 rounded-lg border border-amber-100 text-sm text-slate-700 whitespace-pre-wrap max-h-32 overflow-y-auto">
                {{ card.ai_knowledge_base }}
              </div>
            </div>

            <div v-if="card.ai_welcome_general">
              <label class="block text-xs font-medium text-purple-600 mb-1 flex items-center gap-1">
                <i class="pi pi-comments text-[10px]"></i>
                {{ $t('dashboard.ai_welcome_general') }}
              </label>
              <div class="p-3 bg-purple-50 rounded-lg border border-purple-100 text-sm text-slate-700 whitespace-pre-wrap max-h-32 overflow-y-auto">
                {{ card.ai_welcome_general }}
              </div>
            </div>

            <div v-if="card.ai_welcome_item">
              <label class="block text-xs font-medium text-teal-600 mb-1 flex items-center gap-1">
                <i class="pi pi-comment text-[10px]"></i>
                {{ $t('dashboard.ai_welcome_item') }}
              </label>
              <div class="p-3 bg-teal-50 rounded-lg border border-teal-100 text-sm text-slate-700 whitespace-pre-wrap max-h-32 overflow-y-auto">
                {{ card.ai_welcome_item }}
              </div>
            </div>
          </div>

          <!-- Translation & Language Info -->
          <div v-if="card.original_language || hasTranslations" class="pt-3 border-t border-slate-100 space-y-2">
            <div class="flex items-center gap-3 flex-wrap">
              <div v-if="card.original_language">
                <label class="block text-xs font-medium text-slate-500 mb-1">{{ $t('dashboard.original_language') }}</label>
                <span class="inline-flex items-center gap-1 px-2 py-1 rounded bg-slate-100 text-slate-700 text-sm font-medium">
                  <i class="pi pi-globe text-xs"></i>
                  {{ card.original_language }}
                </span>
              </div>
              <div v-if="hasTranslations">
                <label class="block text-xs font-medium text-slate-500 mb-1">{{ $t('dashboard.translations') }}</label>
                <div class="flex flex-wrap gap-1">
                  <span 
                    v-for="lang in translatedLanguages" 
                    :key="lang"
                    class="inline-flex items-center px-2 py-0.5 rounded bg-green-100 text-green-700 text-xs font-medium"
                  >
                    {{ lang }}
                  </span>
                </div>
              </div>
            </div>
          </div>

          <!-- Timestamps -->
          <div class="grid grid-cols-2 gap-4 text-xs text-slate-400 pt-3 border-t border-slate-100">
            <div>
              <span class="font-medium text-slate-500">{{ $t('common.created_at') }}</span>
              <p class="mt-0.5">{{ formatDateTime(card.created_at) }}</p>
            </div>
            <div>
              <span class="font-medium text-slate-500">{{ $t('common.updated_at') }}</span>
              <p class="mt-0.5">{{ formatDateTime(card.updated_at) }}</p>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { useI18n } from 'vue-i18n'
import { formatDateTime } from '@/utils/formatters'

const { t } = useI18n()

interface Card {
  id: string
  name: string
  description: string | null
  conversation_ai_enabled: boolean
  ai_instruction: string | null
  ai_knowledge_base: string | null
  ai_welcome_general: string | null
  ai_welcome_item: string | null
  qr_code_position: string
  content_mode: 'single' | 'grid' | 'list' | 'cards'
  is_grouped: boolean
  group_display: 'expanded' | 'collapsed'
  total_sessions: number
  monthly_sessions: number
  daily_sessions: number
  active_qr_codes: number
  total_qr_codes: number
  translations?: Record<string, any>
  original_language?: string
  created_at: string
  updated_at: string
}

const props = defineProps<{
  card: Card
}>()

// Computed
const hasTranslations = computed(() => {
  return props.card.translations && Object.keys(props.card.translations).length > 0
})

const translatedLanguages = computed(() => {
  if (!props.card.translations) return []
  return Object.keys(props.card.translations)
})


const getContentModeLabel = (mode: string) => {
  const labels: Record<string, string> = {
    'single': t('dashboard.mode_single'),
    'list': t('dashboard.mode_list'),
    'grid': t('dashboard.mode_grid'),
    'cards': t('dashboard.mode_cards')
  }
  return labels[mode] || mode
}

const getContentModeIcon = (mode: string) => {
  const icons: Record<string, string> = {
    'single': 'pi pi-file',
    'list': 'pi pi-list',
    'grid': 'pi pi-th-large',
    'cards': 'pi pi-id-card'
  }
  return icons[mode] || 'pi pi-list'
}
</script>

