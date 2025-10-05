<template>
  <div class="mobile-card-container">
    <!-- Loading State -->
    <div v-if="isLoading" class="loading-container">
      <ProgressSpinner class="spinner" />
      <p class="loading-text">Loading card...</p>
    </div>

    <!-- Error State -->
    <div v-else-if="error" class="error-container">
      <i class="pi pi-exclamation-triangle error-icon" />
      <h2 class="error-title">Card Not Found</h2>
      <p class="error-message">{{ error }}</p>
      <Button 
        label="Try Again" 
        @click="handleRetry" 
        class="retry-button"
      />
    </div>

    <!-- Main Content -->
    <div v-else-if="cardData" class="content-wrapper">
      <!-- Navigation Header -->
      <MobileHeader 
        v-if="!isCardView"
        :title="headerTitle"
        :subtitle="cardData.card_name"
        @back="handleNavigation"
      />

      <!-- Dynamic View Container -->
      <transition name="view-transition" mode="out-in">
        <!-- Card Overview -->
        <CardOverview 
          v-if="isCardView"
          :card="cardData"
          @explore="openContentList"
        />

        <!-- Content List -->
        <ContentList 
          v-else-if="isContentListView"
          :items="topLevelContent"
          :card-ai-enabled="cardData.conversation_ai_enabled"
          :all-items="contentItems"
          @select="selectContent"
        />

        <!-- Content Detail -->
        <ContentDetail 
          v-else-if="isContentDetailView && selectedContent"
          :content="selectedContent"
          :sub-items="subContent"
          :card="cardData"
          :parent-item="parentOfSelected"
          @select="selectContent"
        />
      </transition>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import { supabase } from '@/lib/supabase'
import ProgressSpinner from 'primevue/progressspinner'
import Button from 'primevue/button'

// Child Components - We'll create these next
import MobileHeader from './components/MobileHeader.vue'
import CardOverview from './components/CardOverview.vue'
import ContentList from './components/ContentList.vue'
import ContentDetail from './components/ContentDetail.vue'

// Types
interface CardData {
  card_name: string
  card_description: string
  card_image_url: string
  crop_parameters?: any
  conversation_ai_enabled: boolean
  ai_prompt: string
  is_activated: boolean
  is_preview?: boolean
}

interface ContentItem {
  content_item_id: string
  content_item_parent_id: string | null
  content_item_name: string
  content_item_content: string
  content_item_image_url: string
  content_item_ai_metadata: string
  content_item_sort_order: number
  crop_parameters?: any
}

type ViewType = 'card' | 'content-list' | 'content-detail'

// Route
const route = useRoute()

// State
const isLoading = ref(true)
const error = ref<string | null>(null)
const cardData = ref<CardData | null>(null)
const contentItems = ref<ContentItem[]>([])
const currentView = ref<ViewType>('card')
const selectedContent = ref<ContentItem | null>(null)
const navigationStack = ref<Array<{ view: ViewType; content: ContentItem | null }>>([])

// Check if we're in preview mode
const isPreviewMode = computed(() => route.meta.isPreviewMode === true)

// Computed
const isCardView = computed(() => currentView.value === 'card')
const isContentListView = computed(() => currentView.value === 'content-list')
const isContentDetailView = computed(() => currentView.value === 'content-detail')

const headerTitle = computed(() => {
  if (isContentListView.value) return 'Explore Content'
  if (isContentDetailView.value && selectedContent.value) {
    return selectedContent.value.content_item_name
  }
  return ''
})

const topLevelContent = computed(() => 
  contentItems.value.filter(item => !item.content_item_parent_id)
)

const subContent = computed(() => {
  if (!selectedContent.value) return []
  return contentItems.value.filter(
    item => item.content_item_parent_id === selectedContent.value!.content_item_id
  )
})

// Find the parent of the currently selected content (null if it's a top-level item)
const parentOfSelected = computed(() => {
  if (!selectedContent.value || !selectedContent.value.content_item_parent_id) return null
  return contentItems.value.find(
    item => item.content_item_id === selectedContent.value!.content_item_parent_id
  ) || null
})

// Methods
async function fetchCardData() {
  try {
    isLoading.value = true
    error.value = null

    let data, fetchError

    if (isPreviewMode.value) {
      // Preview mode - use card ID and preview stored procedure
      const cardId = route.params.card_id as string
      
      const result = await supabase.rpc('get_card_preview_content', {
        p_card_id: cardId
      })
      
      data = result.data
      fetchError = result.error
    } else {
      // Normal mode - use issued card ID
      const issueCardId = route.params.issue_card_id as string

      const result = await supabase.rpc('get_public_card_content', {
        p_issue_card_id: issueCardId
      })
      
      data = result.data
      fetchError = result.error
    }

    if (fetchError) throw fetchError
    if (!data || data.length === 0) {
      throw new Error('Card not found or invalid card ID')
    }

    // Process card data
    const firstRow = data[0]
    cardData.value = {
      card_name: firstRow.card_name,
      card_description: firstRow.card_description,
      card_image_url: firstRow.card_image_url,
      crop_parameters: firstRow.card_crop_parameters,
      conversation_ai_enabled: firstRow.card_conversation_ai_enabled,
      ai_instruction: firstRow.card_ai_instruction,
      ai_knowledge_base: firstRow.card_ai_knowledge_base,
      is_activated: isPreviewMode.value ? true : firstRow.is_activated, // Always activated in preview mode
      is_preview: isPreviewMode.value || firstRow.is_preview || false
    }

    // Process content items
    contentItems.value = data
      .filter((item: any) => item.content_item_id !== null)
      .map((item: any) => ({
        content_item_id: item.content_item_id,
        content_item_parent_id: item.content_item_parent_id,
        content_item_name: item.content_item_name,
        content_item_content: item.content_item_content,
        content_item_image_url: item.content_item_image_url,
        content_item_ai_knowledge_base: item.content_item_ai_knowledge_base,
        content_item_sort_order: item.content_item_sort_order || 0,
        crop_parameters: item.crop_parameters
      }))
      .sort((a: ContentItem, b: ContentItem) => a.content_item_sort_order - b.content_item_sort_order)

  } catch (err: any) {
    console.error('Error fetching card data:', err)
    error.value = err.message || 'Failed to load card data'
  } finally {
    isLoading.value = false
  }
}

function openContentList() {
  pushNavigation()
  currentView.value = 'content-list'
}

function selectContent(item: ContentItem) {
  pushNavigation()
  selectedContent.value = item
  currentView.value = 'content-detail'
}

function pushNavigation() {
  navigationStack.value.push({
    view: currentView.value,
    content: selectedContent.value
  })
}

function handleNavigation() {
  if (navigationStack.value.length > 0) {
    const previousState = navigationStack.value.pop()!
    currentView.value = previousState.view
    selectedContent.value = previousState.content
  }
}

function handleRetry() {
  fetchCardData()
}

// Lifecycle
onMounted(() => {
  fetchCardData()
})
</script>

<style scoped>
/* Base Container */
.mobile-card-container {
  
  background: linear-gradient(to bottom right, #0f172a, #1e3a8a, #4338ca);
  position: relative;
  overflow: hidden;
}

/* Loading State */
.loading-container {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  min-height: 100vh;
  min-height: 100dvh;
  gap: 1rem;
}

.spinner {
  width: 3rem;
  height: 3rem;
}

.loading-text {
  color: white;
  font-size: 1.125rem;
}

/* Error State */
.error-container {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  min-height: 100vh;
  min-height: 100dvh;
  padding: 1.5rem;
  text-align: center;
}

.error-icon {
  font-size: 3rem;
  color: #f87171;
  margin-bottom: 1rem;
}

.error-title {
  color: white;
  font-size: 1.25rem;
  font-weight: bold;
  margin-bottom: 0.5rem;
}

.error-message {
  color: #d1d5db;
  font-size: 1rem;
  margin-bottom: 1rem;
}

.retry-button {
  background: transparent;
  border: 1px solid rgba(255, 255, 255, 0.3);
  color: white;
  padding: 0.75rem 1.5rem;
  font-size: 1rem;
}

/* Content Wrapper */
.content-wrapper {
  position: relative;
  min-height: 100vh;
  min-height: 100dvh;
}

/* View Transitions */
.view-transition-enter-active,
.view-transition-leave-active {
  transition: all 0.3s ease;
}

.view-transition-enter-from {
  opacity: 0;
  transform: translateX(20px);
}

.view-transition-leave-to {
  opacity: 0;
  transform: translateX(-20px);
}

/* Global Mobile Optimizations */
@media (max-width: 640px) {
  * {
    -webkit-tap-highlight-color: transparent;
  }
  
  button {
    min-height: 44px;
    min-width: 44px;
  }
}
</style>