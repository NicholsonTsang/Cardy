<template>
  <div class="mobile-card-container" :class="{ 'digital-mode': isDigitalMode, 'card-overview-view': isCardView }">
    <!-- Loading State -->
    <div v-if="isLoading" class="loading-container">
      <ProgressSpinner class="spinner" />
      <p class="loading-text">{{ $t('mobile.loading_card') }}</p>
    </div>

    <!-- Error State -->
    <div v-else-if="error" class="error-container">
      <i class="pi pi-exclamation-triangle error-icon" />
      <h2 class="error-title">{{ $t('mobile.card_not_found') }}</h2>
      <p class="error-message">{{ error }}</p>
      <Button 
        :label="$t('common.try_again')" 
        @click="handleRetry" 
        class="retry-button"
      />
    </div>

    <!-- Credits Insufficient State (for digital cards) -->
    <div v-else-if="cardData?.credits_insufficient" class="error-container credits-insufficient-container">
      <div class="error-icon-wrapper credits-icon">
        <i class="pi pi-wallet" />
      </div>
      <h2 class="error-title">{{ $t('mobile.credits_insufficient') }}</h2>
      <p class="error-message">{{ $t('mobile.credits_insufficient_message') }}</p>
      <p class="error-hint">{{ $t('mobile.try_again_later') }}</p>
    </div>

    <!-- Monthly Limit Exceeded State (for digital cards) -->
    <div v-else-if="cardData?.monthly_limit_exceeded" class="error-container monthly-limit-container">
      <div class="error-icon-wrapper monthly-limit-icon">
        <i class="pi pi-clock" />
      </div>
      <h2 class="error-title">{{ $t('mobile.monthly_limit_exceeded') }}</h2>
      <p class="error-message">{{ $t('mobile.monthly_limit_message') }}</p>
    </div>

    <!-- Daily Limit Exceeded State (for digital cards - creator protection) -->
    <div v-else-if="cardData?.daily_limit_exceeded" class="error-container daily-limit-container">
      <div class="error-icon-wrapper daily-limit-icon">
        <i class="pi pi-calendar" />
      </div>
      <h2 class="error-title">{{ $t('mobile.daily_limit_exceeded') }}</h2>
      <p class="error-message">{{ $t('mobile.daily_limit_message') }}</p>
      <p class="error-hint">{{ $t('mobile.try_again_tomorrow') }}</p>
    </div>

    <!-- Scan Limit Reached State (for digital cards - total limit) -->
    <div v-else-if="cardData?.scan_limit_reached" class="error-container scan-limit-container">
      <div class="error-icon-wrapper scan-limit-icon">
        <i class="pi pi-ban" />
      </div>
      <h2 class="error-title">{{ $t('mobile.scan_limit_reached') }}</h2>
      <p class="error-message">{{ $t('mobile.scan_limit_message') }}</p>
    </div>

    <!-- Access Disabled State (for digital cards) -->
    <div v-else-if="cardData?.access_disabled" class="error-container access-disabled-container">
      <div class="error-icon-wrapper access-disabled-icon">
        <i class="pi pi-lock" />
      </div>
      <h2 class="error-title">{{ $t('mobile.access_disabled') }}</h2>
      <p class="error-message">{{ $t('mobile.access_disabled_message') }}</p>
    </div>

    <!-- Main Content -->
    <div v-else-if="cardData && !cardData.scan_limit_reached && !cardData.monthly_limit_exceeded && !cardData.daily_limit_exceeded && !cardData.credits_insufficient && !cardData.access_disabled" class="content-wrapper">
      <!-- Navigation Header (show when not on overview page) -->
      <MobileHeader 
        v-if="!isCardView"
        :title="headerTitle"
        :subtitle="cardData.card_name"
        :show-back-button="true"
        @back="handleNavigation"
      />

      <!-- Dynamic View Container (no transition to prevent flash) -->
      <!-- Card/Welcome Overview (both physical and digital) -->
      <CardOverview 
        v-if="isCardView"
        :card="cardData"
        :available-languages="availableLanguages"
        @explore="openContentList"
      />

      <!-- Smart Content Renderer (Auto-detects layout based on content_mode) -->
      <SmartContentRenderer 
        v-else-if="isContentListView"
        :items="topLevelContent"
        :card-ai-enabled="cardData.conversation_ai_enabled"
        :all-items="contentItems"
        :card="cardData"
        :available-languages="availableLanguages"
        :has-header="true"
        @select="selectContent"
      />

      <!-- Content Detail -->
      <ContentDetail 
        v-else-if="isContentDetailView && selectedContent"
        :content="selectedContent"
        :sub-items="subContent"
        :card="cardData"
        :parent-item="parentOfSelected || null"
        @select="selectContent"
      />
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted, watch, watchEffect } from 'vue'
import { useRoute } from 'vue-router'
import { useI18n } from 'vue-i18n'
import { supabase } from '@/lib/supabase'
import { useMobileLanguageStore } from '@/stores/language'
import ProgressSpinner from 'primevue/progressspinner'
import Button from 'primevue/button'

// Mobile API service for backend caching
import { fetchCardContent, transformCardResponse } from '@/services/mobileApi'

const { t } = useI18n()
const mobileLanguageStore = useMobileLanguageStore()

// Child Components
import MobileHeader from './components/MobileHeader.vue'
import CardOverview from './components/CardOverview.vue'
import SmartContentRenderer from './components/SmartContentRenderer.vue'
import ContentDetail from './components/ContentDetail.vue'

// Types
interface CardData {
  card_name: string
  card_description: string
  card_image_url: string
  crop_parameters?: any
  conversation_ai_enabled: boolean
  ai_instruction: string
  ai_knowledge_base: string
  ai_prompt: string  // For backward compatibility with AI Assistant
  ai_welcome_general?: string // Custom AI welcome message for general assistant
  ai_welcome_item?: string // Custom AI welcome message for item assistant
  is_activated: boolean
  is_preview?: boolean
  content_mode?: 'single' | 'grid' | 'list' | 'cards' // Content rendering mode (new: 4 layouts)
  is_grouped?: boolean // Whether content is organized into categories
  group_display?: 'expanded' | 'collapsed' // How grouped items display
  billing_type?: 'physical' | 'digital' // Billing model
  max_scans?: number | null // Total scan limit for digital
  current_scans?: number // Current total scan count
  daily_scan_limit?: number | null // Daily scan limit for digital
  daily_scans?: number // Today's scan count
  scan_limit_reached?: boolean // TRUE if digital card has reached total limit
  monthly_limit_exceeded?: boolean // TRUE if monthly subscription access limit exceeded
  daily_limit_exceeded?: boolean // TRUE if daily access limit reached (creator protection)
  credits_insufficient?: boolean // TRUE if card owner has insufficient credits
  access_disabled?: boolean // TRUE if digital card access has been disabled by owner
  has_translation?: boolean // TRUE if card has translations available
}

interface ContentItem {
  content_item_id: string
  content_item_parent_id: string | null
  content_item_name: string
  content_item_content?: string       // Full content (optional for optimized loading)
  content_preview?: string            // Truncated preview (optimized)
  content_length?: number             // Full content length (optimized)
  content_item_image_url: string
  content_item_ai_knowledge_base?: string
  content_item_ai_metadata?: string
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
const availableLanguages = ref<string[]>([]) // Languages available for this card
const currentView = ref<ViewType>('card')
const selectedContent = ref<ContentItem | null>(null)
const navigationStack = ref<Array<{ view: ViewType; content: ContentItem | null }>>([])

// Check if we're in preview mode
const isPreviewMode = computed(() => route.meta.isPreviewMode === true)

// Computed
const isCardView = computed(() => currentView.value === 'card')
const isContentListView = computed(() => currentView.value === 'content-list')
const isContentDetailView = computed(() => currentView.value === 'content-detail')
const isDigitalMode = computed(() => cardData.value?.billing_type === 'digital')

const headerTitle = computed(() => {
  if (isContentListView.value) return t('mobile.explore_content')
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

    let data: any[] | null = null
    let fetchError: any = null

    if (isPreviewMode.value) {
      // Preview mode - use direct Supabase RPC (requires authentication)
      const cardId = route.params.card_id as string
      
      const result = await supabase.rpc('get_card_preview_content', {
        p_card_id: cardId,
        p_language: mobileLanguageStore.selectedLanguage.code
      })
      
      data = result.data
      fetchError = result.error
      
      if (fetchError) throw fetchError
      if (!data || data.length === 0) {
        throw new Error('Card not found or invalid card ID')
      }
    } else {
      // Public mode - use Express backend API (with Redis caching)
      const cardIdOrToken = route.params.issue_card_id as string
      const language = mobileLanguageStore.selectedLanguage.code
      
      console.log('📱 Fetching card via Express API:', cardIdOrToken)
      const response = await fetchCardContent(cardIdOrToken, language)
      
      if (!response.success) {
        // Handle specific error cases
        if (response.accessDisabled) {
          cardData.value = {
            card_name: '',
            card_description: '',
            card_image_url: '',
            conversation_ai_enabled: false,
            ai_instruction: '',
            ai_knowledge_base: '',
            ai_prompt: '',
            is_activated: false,
            access_disabled: true
          } as CardData
          return
        }
        
        throw new Error(response.message || response.error || 'Card not found')
      }
      
      // Log cache/dedup status for debugging
      if (response.cached) console.log('📦 Response from cache')
      if (response.deduplicated) console.log('🔄 Access deduplicated (no credit charged)')
      
      // Transform API response to Supabase RPC format
      const transformed = transformCardResponse(response)
      if (!transformed) {
        throw new Error('Failed to process card data')
      }
      
      // Convert transformed data to array format (matching Supabase RPC)
      const firstRow = transformed.cardData
      
      if (transformed.contentItems.length > 0) {
        // Merge card data with each content item (same format as Supabase RPC)
        data = transformed.contentItems.map((item: any) => ({
          ...firstRow,
          ...item
        }))
      } else {
        // No content items - just use card data with null content_item_id
        data = [{
          ...firstRow,
          content_item_id: null
        }]
      }
    }

    if (!data || data.length === 0) {
      throw new Error('Card not found or invalid card ID')
    }

    // Process card data (same logic for both modes)
    const firstRow = data[0]
    
    // Check for access disabled (digital cards)
    if (firstRow.card_access_disabled) {
      cardData.value = {
        card_name: '',
        card_description: '',
        card_image_url: '',
        conversation_ai_enabled: false,
        ai_instruction: '',
        ai_knowledge_base: '',
        ai_prompt: '',
        is_activated: false,
        access_disabled: true
      } as CardData
      return
    }

    cardData.value = {
      card_name: firstRow.card_name,
      card_description: firstRow.card_description,
      card_image_url: firstRow.card_image_url,
      crop_parameters: firstRow.card_crop_parameters,
      conversation_ai_enabled: firstRow.card_conversation_ai_enabled,
      ai_instruction: firstRow.card_ai_instruction,
      ai_knowledge_base: firstRow.card_ai_knowledge_base,
      ai_prompt: firstRow.card_ai_instruction, // For backward compatibility with AI Assistant
      ai_welcome_general: firstRow.card_ai_welcome_general || '', // Custom AI welcome message
      ai_welcome_item: firstRow.card_ai_welcome_item || '', // Custom AI welcome message for items
      is_activated: isPreviewMode.value ? true : firstRow.is_activated, // Always activated in preview mode
      is_preview: isPreviewMode.value || firstRow.is_preview || false,
      content_mode: (firstRow.card_content_mode || 'list') as 'single' | 'grid' | 'list' | 'cards',
      is_grouped: firstRow.card_is_grouped || false,
      group_display: firstRow.card_group_display || 'expanded', // How grouped items display
      billing_type: firstRow.card_billing_type || 'physical', // Billing model
      max_scans: firstRow.card_max_scans,
      current_scans: firstRow.card_current_scans,
      daily_scan_limit: firstRow.card_daily_scan_limit,
      daily_scans: firstRow.card_daily_scans,
      scan_limit_reached: firstRow.card_scan_limit_reached || false,
      monthly_limit_exceeded: firstRow.card_monthly_limit_exceeded || false,
      credits_insufficient: firstRow.card_credits_insufficient || false,
      has_translation: firstRow.card_has_translation || false
    }

    // Extract available languages for this card
    availableLanguages.value = firstRow.card_available_languages || [firstRow.card_original_language || 'en']

    // Set mobile client language to card's original language on first load
    // (unless user has already manually selected a language for this session)
    const cardOriginalLang = firstRow.card_original_language || 'en'
    const hasUserSelectedLanguage = sessionStorage.getItem('userSelectedLanguage') === 'true'
    
    if (!hasUserSelectedLanguage) {
      // Check if we need to switch to card's original language
      if (mobileLanguageStore.selectedLanguage.code !== cardOriginalLang) {
        const originalLanguage = mobileLanguageStore.getLanguageByCode(cardOriginalLang)
        if (originalLanguage) {
          console.log('📱 Setting mobile language to card original language:', cardOriginalLang)
          // Set isFirstLoad to false BEFORE setting language to prevent double-fetch
          isFirstLoad.value = false
          mobileLanguageStore.setLanguage(originalLanguage)
          // This will trigger the watcher and re-fetch with correct language
          return // Exit early, watcher will re-fetch with correct language
        }
      } else {
        // Language already matches, mark as loaded
        isFirstLoad.value = false
      }
    } else {
      // User has manually selected language, mark as loaded
      isFirstLoad.value = false
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

// Track if this is the first load
const isFirstLoad = ref(true)

// Lifecycle
onMounted(() => {
  fetchCardData()
  
  // Set dark background for mobile client (prevents white flash in browser chrome)
  // Must set on all layers: html, body, #app (mount point), and .app-root (Vue wrapper)
  const darkBg = '#0f172a'
  document.body.style.setProperty('background-color', darkBg, 'important')
  document.documentElement.style.setProperty('background-color', darkBg, 'important')
  
  // Override #app background (mount point in index.html)
  const appElement = document.getElementById('app')
  if (appElement) {
    appElement.style.setProperty('background-color', darkBg, 'important')
  }
  
  // Override .app-root background (Vue template wrapper with bg-slate-50)
  const appRoot = document.querySelector('.app-root') as HTMLElement
  if (appRoot) {
    appRoot.style.setProperty('background-color', darkBg, 'important')
  }
  
  // Update theme-color meta tag for mobile browser chrome
  const metaThemeColor = document.querySelector('meta[name="theme-color"]')
  if (metaThemeColor) {
    metaThemeColor.setAttribute('content', darkBg)
  }
})

// Prevent body scroll when in digital mode overview (no scrolling needed)
watchEffect(() => {
  const shouldLockScroll = isDigitalMode.value && isCardView.value
  if (shouldLockScroll) {
    document.body.style.overflow = 'hidden'
    document.documentElement.style.overflow = 'hidden'
  } else {
    document.body.style.overflow = ''
    document.documentElement.style.overflow = ''
  }
})

// Cleanup on unmount
onUnmounted(() => {
  document.body.style.overflow = ''
  document.documentElement.style.overflow = ''
  
  // Reset background color when leaving mobile client
  document.body.style.removeProperty('background-color')
  document.documentElement.style.removeProperty('background-color')
  
  // Reset #app background
  const appElement = document.getElementById('app')
  if (appElement) {
    appElement.style.removeProperty('background-color')
  }
  
  // Reset .app-root background
  const appRoot = document.querySelector('.app-root') as HTMLElement
  if (appRoot) {
    appRoot.style.removeProperty('background-color')
  }
  
  // Reset theme-color to default brand blue
  const metaThemeColor = document.querySelector('meta[name="theme-color"]')
  if (metaThemeColor) {
    metaThemeColor.setAttribute('content', '#3B82F6') 
  }
})

// Watch for language changes and reload content
watch(() => mobileLanguageStore.selectedLanguage.code, async () => {
  console.log('📱 Language changed to:', mobileLanguageStore.selectedLanguage.code)
  
  // Store the currently selected content ID to restore selection after reload
  const currentContentId = selectedContent.value?.content_item_id
  
  // Re-fetch data with new language
  await fetchCardData()
  
  // If user was viewing a content detail, update selectedContent to the refreshed version
  if (currentContentId && contentItems.value.length > 0) {
    const updatedContent = contentItems.value.find(item => item.content_item_id === currentContentId)
    if (updatedContent) {
      selectedContent.value = updatedContent
    }
  }
})
</script>

<style scoped>
/* Base Container */
.mobile-card-container {
  min-height: 100vh;
  min-height: var(--viewport-height, 100vh); /* Use dynamic viewport height */
  min-height: 100dvh;
  position: relative;
  overflow: hidden;
  -webkit-text-size-adjust: 100%; /* Prevent text size adjustment */
  touch-action: manipulation; /* Disable double-tap zoom */
  /* No background here - it's on the fixed ::before pseudo-element */
}

/* Fixed gradient background layer - prevents rubber-band from shifting the background */
.mobile-card-container::before {
  content: '';
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: linear-gradient(to bottom right, #0f172a, #1e3a8a, #4338ca);
  z-index: -1; /* Behind all content but visible */
  pointer-events: none; /* Don't interfere with touch events */
}

/* Digital mode on card overview only: Fill entire viewport */
.mobile-card-container.digital-mode.card-overview-view {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  height: auto;
  min-height: auto;
  max-height: none;
  overflow: hidden;
}

/* Digital mode on other pages: Allow scrolling */
.mobile-card-container.digital-mode:not(.card-overview-view) {
  overflow-y: auto;
  -webkit-overflow-scrolling: touch;
}

/* Loading State */
.loading-container {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  min-height: 100vh;
  min-height: var(--viewport-height, 100vh); /* Use dynamic viewport height */
  min-height: 100dvh;
  gap: 1.5rem;
}

.loading-container::before {
  content: '';
  position: absolute;
  width: 120px;
  height: 120px;
  border-radius: 50%;
  background: radial-gradient(circle, rgba(59, 130, 246, 0.2) 0%, transparent 70%);
  animation: pulse-glow 2s ease-in-out infinite;
}

@keyframes pulse-glow {
  0%, 100% { transform: scale(1); opacity: 0.5; }
  50% { transform: scale(1.5); opacity: 0.8; }
}

.spinner {
  width: 3.5rem;
  height: 3.5rem;
  position: relative;
  z-index: 1;
}

.loading-text {
  color: rgba(255, 255, 255, 0.9);
  font-size: 1rem;
  font-weight: 500;
  letter-spacing: 0.02em;
}

/* Error State */
.error-container {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  min-height: 100vh;
  min-height: var(--viewport-height, 100vh); /* Use dynamic viewport height */
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

/* Error Icon Wrapper */
.error-icon-wrapper {
  width: 100px;
  height: 100px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  margin-bottom: 1.5rem;
  position: relative;
}

.error-icon-wrapper i {
  font-size: 2.5rem;
  color: white;
}

.error-icon-wrapper::before {
  content: '';
  position: absolute;
  inset: -8px;
  border-radius: 50%;
  border: 2px solid rgba(255, 255, 255, 0.2);
  animation: pulse-ring 2s ease-out infinite;
}

@keyframes pulse-ring {
  0% { transform: scale(1); opacity: 1; }
  100% { transform: scale(1.3); opacity: 0; }
}

/* Credits Insufficient */
.credits-insufficient-container {
  background: linear-gradient(135deg, #1e3a5f 0%, #0f172a 100%);
}

.credits-icon {
  background: linear-gradient(135deg, #f59e0b 0%, #d97706 100%);
  box-shadow: 0 8px 32px rgba(245, 158, 11, 0.3);
}

/* Monthly Limit Exceeded */
.monthly-limit-container {
  background: linear-gradient(135deg, #312e81 0%, #1e1b4b 100%);
}

.monthly-limit-icon {
  background: linear-gradient(135deg, #8b5cf6 0%, #7c3aed 100%);
  box-shadow: 0 8px 32px rgba(139, 92, 246, 0.3);
}

/* Daily Limit Exceeded (creator protection) */
.daily-limit-container {
  background: linear-gradient(135deg, #1e3a5f 0%, #0f172a 100%);
}

.daily-limit-icon {
  background: linear-gradient(135deg, #3b82f6 0%, #2563eb 100%);
  box-shadow: 0 8px 32px rgba(59, 130, 246, 0.3);
}

.countdown-hint {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  background: rgba(255, 255, 255, 0.1);
  padding: 0.75rem 1.25rem;
  border-radius: 2rem;
  margin-top: 0.5rem;
}

.countdown-hint i {
  color: #8b5cf6;
}

.countdown-hint span {
  color: #e2e8f0;
  font-size: 0.9rem;
}

/* Scan Limit Reached */
.scan-limit-container {
  background: linear-gradient(135deg, #7f1d1d 0%, #450a0a 100%);
}

.scan-limit-icon {
  background: linear-gradient(135deg, #ef4444 0%, #dc2626 100%);
  box-shadow: 0 8px 32px rgba(239, 68, 68, 0.3);
}

/* Access Disabled */
.access-disabled-container {
  background: linear-gradient(135deg, #374151 0%, #1f2937 100%);
}

.access-disabled-icon {
  background: linear-gradient(135deg, #6b7280 0%, #4b5563 100%);
  box-shadow: 0 8px 32px rgba(107, 114, 128, 0.3);
}

.error-hint {
  color: #94a3b8;
  font-size: 0.875rem;
  margin-top: 0.5rem;
}

/* Content Wrapper */
.content-wrapper {
  position: relative;
  min-height: 100vh;
  min-height: var(--viewport-height, 100vh); /* Use dynamic viewport height */
  min-height: 100dvh;
  /* Dark background to prevent flash during view transitions */
  background: linear-gradient(to bottom right, #0f172a, #1e3a8a, #4338ca);
}

/* Digital mode card overview content wrapper */
.digital-mode.card-overview-view .content-wrapper {
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  height: auto;
  min-height: auto;
  max-height: none;
  overflow: hidden;
  display: flex;
  flex-direction: column;
  /* Dark background to prevent flash during view transitions */
  background: linear-gradient(to bottom right, #0f172a, #1e3a8a, #4338ca);
}

/* Digital mode other pages content wrapper - allow scrolling */
.digital-mode:not(.card-overview-view) .content-wrapper {
  overflow-y: auto;
  -webkit-overflow-scrolling: touch;
}

/* Global Mobile Optimizations */
@media (max-width: 640px) {
  * {
    -webkit-tap-highlight-color: transparent;
  }
  
  button {
    min-height: 44px; /* iOS recommended touch target */
    min-width: 44px;
    touch-action: manipulation; /* Disable double-tap zoom on buttons */
  }
}
</style>