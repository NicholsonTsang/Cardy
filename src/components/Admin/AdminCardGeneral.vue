<template>
  <div class="space-y-6">
    <!-- Access Mode Badge -->
    <div class="flex items-center gap-2">
      <span 
        class="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full text-sm font-medium"
        :class="card.billing_type === 'digital' 
          ? 'bg-cyan-100 text-cyan-800 border border-cyan-200' 
          : 'bg-purple-100 text-purple-800 border border-purple-200'"
      >
        <i :class="card.billing_type === 'digital' ? 'pi pi-qrcode' : 'pi pi-credit-card'" class="text-xs"></i>
        {{ card.billing_type === 'digital' ? 'Digital Access' : 'Physical Card' }}
      </span>
      <span 
        v-if="card.content_mode"
        class="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full text-sm font-medium bg-blue-100 text-blue-800 border border-blue-200"
      >
        {{ card.content_mode }}
      </span>
    </div>

    <div class="grid grid-cols-1 gap-6" :class="{ 'md:grid-cols-2': card.billing_type !== 'digital' }">
      <!-- Card Image - Only for Physical Cards -->
      <div v-if="card.billing_type !== 'digital'">
        <label class="block text-sm font-medium text-slate-700 mb-2">{{ $t('dashboard.card_image') }}</label>
        <div v-if="card.image_url" class="relative" style="aspect-ratio: 2/3; max-width: 300px;">
          <img
            :src="card.image_url"
            :alt="card.name"
            class="w-full h-full object-cover rounded-lg border border-slate-300 shadow-sm"
          />
        </div>
        <div v-else class="aspect-[2/3] max-w-[300px] bg-slate-100 rounded-lg border-2 border-dashed border-slate-300 flex items-center justify-center">
          <div class="text-center">
            <i class="pi pi-image text-4xl text-slate-400 mb-2"></i>
            <p class="text-slate-500 text-sm">{{ $t('dashboard.no_image') }}</p>
          </div>
        </div>
      </div>

      <!-- Card Details -->
      <div class="space-y-4">
        <div>
          <label class="block text-sm font-medium text-slate-700 mb-1">{{ $t('dashboard.card_name') }}</label>
          <p class="text-base font-semibold text-slate-900">{{ card.name }}</p>
        </div>

        <div>
          <label class="block text-sm font-medium text-slate-700 mb-1">{{ $t('common.description') }}</label>
          <p class="text-sm text-slate-600">{{ card.description || $t('dashboard.no_description') }}</p>
        </div>

        <div class="grid grid-cols-2 gap-4">
          <div>
            <label class="block text-sm font-medium text-slate-700 mb-1">{{ $t('dashboard.qr_position') }}</label>
            <Tag :value="card.qr_code_position" severity="info" />
          </div>

          <div>
            <label class="block text-sm font-medium text-slate-700 mb-1">{{ $t('dashboard.ai_enabled') }}</label>
            <Tag
              :value="card.conversation_ai_enabled ? $t('common.yes') : $t('common.no')"
              :severity="card.conversation_ai_enabled ? 'success' : 'secondary'"
            />
          </div>
        </div>

        <div v-if="card.ai_instruction" class="space-y-3">
          <div>
            <label class="block text-sm font-medium text-blue-700 mb-1 flex items-center gap-2">
              <i class="pi pi-user text-xs"></i>
              {{ $t('dashboard.ai_instruction') }}
            </label>
            <div class="p-3 bg-blue-50 rounded border border-blue-200 text-sm text-slate-700 whitespace-pre-wrap">
              {{ card.ai_instruction }}
            </div>
          </div>
        </div>

        <div v-if="card.ai_knowledge_base">
          <label class="block text-sm font-medium text-amber-700 mb-1 flex items-center gap-2">
            <i class="pi pi-database text-xs"></i>
            {{ $t('dashboard.ai_knowledge_base') }}
          </label>
          <div class="p-3 bg-amber-50 rounded border border-amber-200 text-sm text-slate-700 whitespace-pre-wrap max-h-48 overflow-y-auto">
            {{ card.ai_knowledge_base }}
          </div>
        </div>

        <div class="grid grid-cols-2 gap-4 text-xs text-slate-500 pt-4 border-t border-slate-200">
          <div>
            <span class="font-medium">{{ $t('common.created_at') }}:</span><br />
            {{ formatDateTime(card.created_at) }}
          </div>
          <div>
            <span class="font-medium">{{ $t('common.updated_at') }}:</span><br />
            {{ formatDateTime(card.updated_at) }}
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { useI18n } from 'vue-i18n'
import Tag from 'primevue/tag'

const { t } = useI18n()

interface Card {
  id: string
  name: string
  description: string | null
  image_url: string | null
  conversation_ai_enabled: boolean
  ai_instruction: string | null
  ai_knowledge_base: string | null
  qr_code_position: string
  created_at: string
  updated_at: string
}

defineProps<{
  card: Card
}>()

const formatDateTime = (dateString: string) => {
  return new Date(dateString).toLocaleString('en-US', {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  })
}
</script>

