<template>
  <div class="bg-white rounded-xl shadow-lg border border-slate-200 flex flex-col overflow-hidden">
    <!-- Header -->
    <div class="p-4 border-b border-slate-200 bg-white">
      <div class="flex items-center justify-between mb-3">
        <h1 class="text-2xl font-bold text-slate-900">User Cards</h1>
        <Tag :value="`${filteredCards.length}`" severity="info" />
      </div>
      <p class="text-slate-600 -mt-2 mb-4 text-sm">View user's card designs (read-only).</p>
      
      <!-- Search -->
      <IconField>
        <InputIcon class="pi pi-search" />
        <InputText
          v-model="searchQuery"
          placeholder="Search cards..."
          class="w-full"
        />
      </IconField>
    </div>

    <!-- Empty State -->
    <div v-if="cards.length === 0" class="flex-1 flex flex-col justify-center p-4 text-center min-h-[400px]">
      <div class="flex flex-col items-center space-y-3">
        <i class="pi pi-inbox text-5xl text-slate-300"></i>
        <h3 class="text-lg font-medium text-slate-700">No Cards Found</h3>
        <p class="text-slate-500 text-sm">This user has not created any cards yet.</p>
      </div>
    </div>

    <!-- Cards List -->
    <div v-else class="flex-1 flex flex-col overflow-hidden">
      <!-- Loading State -->
      <div v-if="isLoading" class="p-4 space-y-3">
        <div v-for="i in 3" :key="i" class="animate-pulse bg-slate-200 h-24 rounded-lg"></div>
      </div>

      <!-- Cards -->
      <div v-else-if="paginatedCards.length > 0" class="flex-1 overflow-y-auto p-4 space-y-2">
        <div
          v-for="card in paginatedCards"
          :key="card.id"
          @click="$emit('select-card', card.id)"
          :class="[
            'p-3 rounded-lg border-2 cursor-pointer transition-all duration-200',
            selectedCardId === card.id
              ? 'border-blue-500 bg-blue-50'
              : 'border-slate-200 hover:border-slate-300 hover:bg-slate-50'
          ]"
        >
          <div class="flex gap-3">
            <div
              v-if="card.image_url"
              class="w-16 h-24 flex-shrink-0 rounded-lg overflow-hidden bg-slate-100"
              style="aspect-ratio: 2/3;"
            >
              <img :src="card.image_url" :alt="card.name" class="w-full h-full object-cover" />
            </div>
            <div v-else class="w-16 h-24 flex-shrink-0 rounded-lg bg-slate-200 flex items-center justify-center" style="aspect-ratio: 2/3;">
              <i class="pi pi-id-card text-slate-400 text-xl"></i>
            </div>
            <div class="flex-1 min-w-0">
              <p class="font-semibold text-slate-900 truncate">{{ card.name }}</p>
              <p v-if="card.description" class="text-xs text-slate-600 line-clamp-2">
                {{ card.description }}
              </p>
              <p class="text-xs text-slate-500 mt-1">
                Created {{ formatDate(card.created_at) }}
              </p>
            </div>
          </div>
        </div>
      </div>

      <!-- No Results -->
      <div v-else class="flex-1 flex items-center justify-center p-8">
        <div class="text-center">
          <i class="pi pi-search text-4xl text-slate-300 mb-3"></i>
          <p class="text-slate-500">No cards match your search</p>
        </div>
      </div>

      <!-- Pagination -->
      <div v-if="filteredCards.length > itemsPerPage" class="border-t border-slate-200 p-2">
        <Paginator
          :first="first"
          :rows="itemsPerPage"
          :totalRecords="filteredCards.length"
          @page="handlePageChange"
        />
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import InputText from 'primevue/inputtext'
import IconField from 'primevue/iconfield'
import InputIcon from 'primevue/inputicon'
import Tag from 'primevue/tag'
import Paginator from 'primevue/paginator'

interface Card {
  id: string
  name: string
  description: string | null
  image_url: string | null
  created_at: string
}

interface Props {
  cards: Card[]
  selectedCardId: string | null
  isLoading?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  isLoading: false
})

const emit = defineEmits<{
  (e: 'select-card', cardId: string): void
}>()

// Component state
const searchQuery = ref('')
const first = ref(0)
const itemsPerPage = ref(10)

// Computed
const filteredCards = computed(() => {
  if (!searchQuery.value) return props.cards
  const query = searchQuery.value.toLowerCase()
  return props.cards.filter(card =>
    card.name.toLowerCase().includes(query) ||
    (card.description && card.description.toLowerCase().includes(query))
  )
})

const paginatedCards = computed(() => {
  const start = first.value
  const end = start + itemsPerPage.value
  return filteredCards.value.slice(start, end)
})

// Methods
const handlePageChange = (event: any) => {
  first.value = event.first
}

const formatDate = (dateString: string) => {
  return new Date(dateString).toLocaleDateString('en-US', {
    month: 'short',
    day: 'numeric',
    year: 'numeric'
  })
}

// Watchers
watch(searchQuery, () => {
  first.value = 0
})
</script>

<style scoped>
.line-clamp-2 {
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}
</style>

