<template>
  <div class="space-y-6">
    <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
      <!-- Card Image -->
      <div>
        <label class="block text-sm font-medium text-slate-700 mb-2">Card Image</label>
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
            <p class="text-slate-500 text-sm">No image</p>
          </div>
        </div>
      </div>

      <!-- Card Details -->
      <div class="space-y-4">
        <div>
          <label class="block text-sm font-medium text-slate-700 mb-1">Card Name</label>
          <p class="text-base font-semibold text-slate-900">{{ card.name }}</p>
        </div>

        <div>
          <label class="block text-sm font-medium text-slate-700 mb-1">Description</label>
          <p class="text-sm text-slate-600">{{ card.description || 'No description' }}</p>
        </div>

        <div class="grid grid-cols-2 gap-4">
          <div>
            <label class="block text-sm font-medium text-slate-700 mb-1">QR Position</label>
            <Tag :value="card.qr_code_position" severity="info" />
          </div>

          <div>
            <label class="block text-sm font-medium text-slate-700 mb-1">AI Enabled</label>
            <Tag
              :value="card.conversation_ai_enabled ? 'Yes' : 'No'"
              :severity="card.conversation_ai_enabled ? 'success' : 'secondary'"
            />
          </div>
        </div>

        <div v-if="card.ai_instruction" class="space-y-3">
          <div>
            <label class="block text-sm font-medium text-blue-700 mb-1 flex items-center gap-2">
              <i class="pi pi-user text-xs"></i>
              AI Instruction (Role & Guidelines)
            </label>
            <div class="p-3 bg-blue-50 rounded border border-blue-200 text-sm text-slate-700 whitespace-pre-wrap">
              {{ card.ai_instruction }}
            </div>
          </div>
        </div>

        <div v-if="card.ai_knowledge_base">
          <label class="block text-sm font-medium text-amber-700 mb-1 flex items-center gap-2">
            <i class="pi pi-database text-xs"></i>
            AI Knowledge Base
          </label>
          <div class="p-3 bg-amber-50 rounded border border-amber-200 text-sm text-slate-700 whitespace-pre-wrap max-h-48 overflow-y-auto">
            {{ card.ai_knowledge_base }}
          </div>
        </div>

        <div class="grid grid-cols-2 gap-4 text-xs text-slate-500 pt-4 border-t border-slate-200">
          <div>
            <span class="font-medium">Created:</span><br />
            {{ formatDateTime(card.created_at) }}
          </div>
          <div>
            <span class="font-medium">Updated:</span><br />
            {{ formatDateTime(card.updated_at) }}
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import Tag from 'primevue/tag'

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

