<template>
  <div 
    class="layout-list" 
    :class="{ 'has-header': hasHeader, 'has-ai': card.conversation_ai_enabled }"
    ref="scrollContainer"
    @scroll="handleScroll"
  >
    <!-- Simple Vertical List -->
    <div class="list-container">
      <button
        v-for="item in items"
        :key="item.content_item_id"
        @click="handleItemClick(item)"
        class="list-item"
      >
        <div v-if="item.content_item_image_url" class="item-image">
          <img :src="item.content_item_image_url" :alt="item.content_item_name" crossorigin="anonymous" />
        </div>
        <div v-else class="item-icon">
          <i :class="getIconForItem(item)" />
        </div>
        <div class="item-info">
          <span class="item-name">{{ item.content_item_name }}</span>
          <span v-if="getItemPreview(item)" class="item-preview">
            {{ truncateText(getItemPreview(item), 60) }}
          </span>
        </div>
        <i class="pi pi-chevron-right item-arrow" />
      </button>
      
      <!-- Loading More Indicator -->
      <div v-if="isLoadingMore" class="loading-more">
        <i class="pi pi-spin pi-spinner" />
        <span>{{ $t('mobile.loading_more') }}</span>
      </div>
      
      <!-- End of List Indicator -->
      <div v-else-if="!hasMore && items.length > 0" class="end-of-list">
        <span>{{ $t('mobile.end_of_list') }}</span>
      </div>
    </div>

    <!-- Empty State -->
    <div v-if="items.length === 0 && !isLoadingMore" class="empty-state">
      <i class="pi pi-list" />
      <p>{{ $t('mobile.no_items') }}</p>
    </div>

    <!-- General AI Assistant (if enabled) - For navigation/browsing questions -->
    <CardLevelAssistant
      v-if="card.conversation_ai_enabled"
      :card-data="cardDataForAssistant"
      :show-button="false"
      ref="cardAssistantRef"
    />
    
    <!-- AI Badge at bottom for easy access -->
    <div v-if="card.conversation_ai_enabled" class="ai-section">
      <button @click="openAssistant" class="ai-browse-badge">
        <span class="ai-badge-icon">✨</span>
        <span class="ai-badge-text">{{ $t('mobile.tap_to_chat_with_ai') }}</span>
        <i class="pi pi-chevron-right ai-badge-arrow" />
      </button>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { CardLevelAssistant } from './AIAssistant'
import { getInfiniteScrollThreshold } from '@/utils/paginationConfig'

interface ContentItem {
  content_item_id: string
  content_item_parent_id: string | null
  content_item_name: string
  content_item_content?: string       // Full content (legacy)
  content_preview?: string            // Truncated preview (optimized)
  content_length?: number             // Full content length (optimized)
  content_item_image_url: string
  content_item_ai_knowledge_base?: string
  content_item_sort_order: number
}

interface Props {
  card: {
    card_name: string
    card_description: string
    card_image_url: string
    conversation_ai_enabled: boolean
    ai_instruction?: string
    ai_knowledge_base?: string
    is_activated: boolean
  }
  items: ContentItem[]
  availableLanguages?: string[]
  hasHeader?: boolean
  // Pagination props (optional - for optimized loading)
  hasMore?: boolean
  isLoadingMore?: boolean
  totalCount?: number
}

const props = withDefaults(defineProps<Props>(), {
  hasHeader: false,
  hasMore: false,
  isLoadingMore: false,
  totalCount: 0
})

const emit = defineEmits<{
  select: [item: ContentItem]
  loadMore: []
}>()

// Scroll container ref
const scrollContainer = ref<HTMLElement | null>(null)

// Card Level Assistant ref
const cardAssistantRef = ref<InstanceType<typeof CardLevelAssistant> | null>(null)

// Card data formatted for General AI assistant
const cardDataForAssistant = computed(() => ({
  card_name: props.card.card_name,
  card_description: props.card.card_description,
  card_image_url: props.card.card_image_url,
  conversation_ai_enabled: props.card.conversation_ai_enabled,
  ai_instruction: props.card.ai_instruction || '',
  ai_knowledge_base: props.card.ai_knowledge_base || '',
  is_activated: props.card.is_activated
}))

// Open the General Assistant
function openAssistant() {
  cardAssistantRef.value?.openModal()
}

// Scroll threshold for infinite scroll (pixels from bottom) - from env config
const SCROLL_THRESHOLD = getInfiniteScrollThreshold()

// Get item preview text (supports both legacy and optimized data)
function getItemPreview(item: ContentItem): string {
  return item.content_preview || item.content_item_content || ''
}

function truncateText(text: string, maxLength: number): string {
  if (!text) return ''
  const plainText = text.replace(/<[^>]*>/g, '').replace(/[#*_`]/g, '')
  return plainText.length > maxLength 
    ? plainText.slice(0, maxLength) + '...'
    : plainText
}

// Handle scroll for infinite loading
function handleScroll(event: Event) {
  if (!props.hasMore || props.isLoadingMore) return
  
  const target = event.target as HTMLElement
  if (!target) return
  
  const { scrollTop, scrollHeight, clientHeight } = target
  const distanceFromBottom = scrollHeight - scrollTop - clientHeight
  
  if (distanceFromBottom < SCROLL_THRESHOLD) {
    emit('loadMore')
  }
}

// Smart icon detection based on content
function getIconForItem(item: ContentItem): string {
  const content = (item.content_item_content || '').toLowerCase()
  const name = item.content_item_name.toLowerCase()
  
  // URL patterns
  if (content.includes('instagram') || name.includes('instagram')) return 'pi pi-instagram'
  if (content.includes('youtube') || name.includes('youtube')) return 'pi pi-youtube'
  if (content.includes('twitter') || name.includes('twitter')) return 'pi pi-twitter'
  if (content.includes('facebook') || name.includes('facebook')) return 'pi pi-facebook'
  if (content.includes('linkedin') || name.includes('linkedin')) return 'pi pi-linkedin'
  if (content.includes('github') || name.includes('github')) return 'pi pi-github'
  if (content.includes('tiktok') || name.includes('tiktok')) return 'pi pi-tiktok'
  if (content.includes('mailto:') || content.includes('@')) return 'pi pi-envelope'
  if (content.includes('tel:') || content.includes('phone')) return 'pi pi-phone'
  if (content.includes('http') || content.includes('www')) return 'pi pi-external-link'
  
  return 'pi pi-file'
}

function handleItemClick(item: ContentItem) {
  // Check if content is a URL
  const content = item.content_item_content || ''
  const urlMatch = content.match(/https?:\/\/[^\s<>"]+/)
  
  if (urlMatch) {
    window.open(urlMatch[0], '_blank', 'noopener,noreferrer')
  } else {
    emit('select', item)
  }
}
</script>

<style scoped>
.layout-list {
  min-height: 100vh;
  min-height: 100dvh;
  display: flex;
  flex-direction: column;
  padding: 1.5rem 1.25rem;
  padding-top: calc(1.5rem + env(safe-area-inset-top));
  padding-bottom: max(2rem, env(safe-area-inset-bottom));
}

.layout-list.has-header {
  padding-top: calc(6.5rem + env(safe-area-inset-top));
}

/* Extra bottom padding when AI assistant is present (fixed at bottom) */
.layout-list.has-ai {
  padding-bottom: calc(5rem + max(1rem, env(safe-area-inset-bottom)));
}

.list-container {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 0.625rem;
}

.list-item {
  display: flex;
  align-items: center;
  gap: 0.875rem;
  width: 100%;
  padding: 1rem 1.125rem;
  background: rgba(255, 255, 255, 0.08);
  backdrop-filter: blur(12px);
  -webkit-backdrop-filter: blur(12px);
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 0.875rem;
  color: white;
  text-align: left;
  cursor: pointer;
  transition: all 0.2s;
  -webkit-tap-highlight-color: transparent;
  min-height: 60px;
}

.list-item:active {
  background: rgba(255, 255, 255, 0.15);
  transform: scale(0.98);
}

.item-image {
  width: 44px;
  height: 44px;
  border-radius: 0.625rem;
  overflow: hidden;
  flex-shrink: 0;
  background: rgba(255, 255, 255, 0.1);
}

.item-image img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.item-icon {
  width: 44px;
  height: 44px;
  border-radius: 0.625rem;
  background: linear-gradient(135deg, rgba(59, 130, 246, 0.2), rgba(147, 51, 234, 0.2));
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  position: relative;
  overflow: hidden;
}

.item-icon::before {
  content: '';
  position: absolute;
  inset: 0;
  background: linear-gradient(135deg, rgba(255, 255, 255, 0.1), transparent);
  opacity: 0;
  transition: opacity 0.2s;
}

.list-item:active .item-icon::before {
  opacity: 1;
}

.item-icon i {
  font-size: 1.25rem;
  color: rgba(255, 255, 255, 0.9);
}

.item-info {
  flex: 1;
  min-width: 0;
  display: flex;
  flex-direction: column;
}

.item-name {
  font-size: 1rem;
  font-weight: 600;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.item-preview {
  font-size: 0.8125rem;
  color: rgba(255, 255, 255, 0.5);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  margin-top: 0.25rem;
}

.item-arrow {
  color: rgba(255, 255, 255, 0.3);
  font-size: 0.875rem;
  flex-shrink: 0;
}

.empty-state {
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  color: rgba(255, 255, 255, 0.5);
  gap: 1rem;
}

.empty-state i {
  font-size: 3rem;
}

/* Fixed AI Section at bottom */
.ai-section {
  position: fixed;
  bottom: 0;
  left: 0;
  right: 0;
  padding: 1rem 1.25rem;
  padding-bottom: max(1rem, env(safe-area-inset-bottom));
  background: linear-gradient(to top, rgba(15, 23, 42, 0.95) 0%, rgba(15, 23, 42, 0.8) 70%, transparent 100%);
  backdrop-filter: blur(12px);
  -webkit-backdrop-filter: blur(12px);
  z-index: 100;
}

/* AI Browse Badge - General Assistant trigger */
.ai-browse-badge {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  width: 100%;
  max-width: 400px;
  margin: 0 auto;
  padding: 0.875rem 1.125rem;
  background: linear-gradient(135deg, rgba(139, 92, 246, 0.25) 0%, rgba(59, 130, 246, 0.25) 100%);
  border: 1px solid rgba(139, 92, 246, 0.4);
  border-radius: 1rem;
  color: white;
  font-size: 0.9375rem;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.3s ease;
  -webkit-tap-highlight-color: transparent;
  touch-action: manipulation;
  box-shadow: 0 4px 12px rgba(139, 92, 246, 0.2);
}

.ai-browse-badge:hover {
  background: linear-gradient(135deg, rgba(139, 92, 246, 0.35) 0%, rgba(59, 130, 246, 0.35) 100%);
  border-color: rgba(139, 92, 246, 0.5);
}

.ai-browse-badge:active {
  transform: scale(0.98);
}

.ai-browse-badge .ai-badge-icon {
  font-size: 1.125rem;
}

.ai-browse-badge .ai-badge-text {
  flex: 1;
  text-align: left;
  font-weight: 600;
}

.ai-browse-badge .ai-badge-arrow {
  font-size: 0.875rem;
  opacity: 0.6;
  transition: transform 0.2s ease;
}

.ai-browse-badge:hover .ai-badge-arrow {
  transform: translateX(3px);
  opacity: 0.9;
}

/* Loading More Indicator */
.loading-more {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 0.5rem;
  padding: 1.5rem;
  color: rgba(255, 255, 255, 0.6);
  font-size: 0.875rem;
}

.loading-more i {
  font-size: 1rem;
}

/* End of List Indicator */
.end-of-list {
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 1rem;
  color: rgba(255, 255, 255, 0.4);
  font-size: 0.75rem;
}
</style>

