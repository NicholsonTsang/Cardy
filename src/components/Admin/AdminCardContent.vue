<template>
  <div>
    <!-- Loading State -->
    <div v-if="isLoading" class="space-y-4">
      <div v-for="i in 3" :key="i" class="animate-pulse bg-slate-200 h-24 rounded-lg"></div>
    </div>

    <!-- Empty State -->
    <div v-else-if="content.length === 0" class="text-center py-12">
      <i class="pi pi-inbox text-5xl text-slate-300 mb-3"></i>
      <h3 class="text-lg font-medium text-slate-700 mb-2">No Content Items</h3>
      <p class="text-slate-500">This card has no content items yet.</p>
    </div>

    <!-- Content Items -->
    <div v-else class="space-y-4">
      <div
        v-for="item in parentContentItems"
        :key="item.id"
        class="border border-slate-200 rounded-lg overflow-hidden"
      >
        <!-- Parent Item -->
        <div class="p-4 bg-slate-50">
          <div class="flex items-start gap-4">
            <div
              v-if="item.image_url"
              class="w-24 h-18 flex-shrink-0 rounded-lg overflow-hidden"
              style="aspect-ratio: 4/3;"
            >
              <img :src="item.image_url" :alt="item.name" class="w-full h-full object-cover" />
            </div>
            <div v-else class="w-24 h-18 flex-shrink-0 rounded-lg bg-slate-200 flex items-center justify-center" style="aspect-ratio: 4/3;">
              <i class="pi pi-image text-slate-400"></i>
            </div>
            <div class="flex-1">
              <h4 class="font-semibold text-slate-900 mb-2">{{ item.name }}</h4>
              <p v-if="item.content" class="text-sm text-slate-600 whitespace-pre-wrap">
                {{ item.content }}
              </p>
              <div v-if="item.ai_metadata" class="mt-3 bg-gradient-to-r from-amber-50 to-orange-50 rounded-lg p-3 border border-amber-200">
                <div class="flex items-center gap-2 mb-2">
                  <i class="pi pi-database text-amber-600 text-xs"></i>
                  <span class="text-xs font-medium text-amber-900">AI Metadata</span>
                </div>
                <p class="text-xs text-amber-800 whitespace-pre-wrap leading-relaxed">
                  {{ item.ai_metadata }}
                </p>
              </div>
            </div>
          </div>
        </div>

        <!-- Sub Items -->
        <div v-if="getSubItems(item.id).length > 0" class="border-t border-slate-200">
          <div
            v-for="subItem in getSubItems(item.id)"
            :key="subItem.id"
            class="p-4 border-b border-slate-100 last:border-b-0 bg-white"
          >
            <div class="flex items-start gap-3 pl-4">
              <i class="pi pi-angle-right text-slate-400 mt-1 flex-shrink-0"></i>
              <div
                v-if="subItem.image_url"
                class="w-20 h-15 flex-shrink-0 rounded overflow-hidden"
                style="aspect-ratio: 4/3;"
              >
                <img :src="subItem.image_url" :alt="subItem.name" class="w-full h-full object-cover" />
              </div>
              <div v-else class="w-20 h-15 flex-shrink-0 rounded bg-slate-100 flex items-center justify-center" style="aspect-ratio: 4/3;">
                <i class="pi pi-image text-slate-300 text-sm"></i>
              </div>
              <div class="flex-1">
                <h5 class="font-medium text-slate-800 mb-1">{{ subItem.name }}</h5>
                <p v-if="subItem.content" class="text-sm text-slate-600 whitespace-pre-wrap">
                  {{ subItem.content }}
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import Tag from 'primevue/tag'

interface ContentItem {
  id: string
  name: string
  content: string | null
  image_url: string | null
  parent_id: string | null
  ai_metadata: string | null
}

interface Props {
  cardId: string
  content: ContentItem[]
  isLoading: boolean
}

const props = defineProps<Props>()

const parentContentItems = computed(() => {
  return props.content.filter(item => !item.parent_id)
})

const getSubItems = (parentId: string) => {
  return props.content.filter(item => item.parent_id === parentId)
}
</script>

