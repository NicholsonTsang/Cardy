<template>
  <div
    class="layout-list"
    :class="{ 'has-header': hasHeader, 'has-ai': card.conversation_ai_enabled }"
    ref="scrollContainer"
    @scroll="handleScroll"
    role="main"
    :aria-label="$t('mobile.explore_content')"
  >
    <!-- Simple Vertical List -->
    <div class="list-container" role="list">
      <button
        v-for="(item, index) in items"
        :key="item.content_item_id"
        @click="handleItemClick(item)"
        class="list-item"
        :style="{ animationDelay: `${Math.min(index * 0.04, 0.4)}s` }"
        role="listitem"
        :aria-label="item.content_item_name"
      >
        <div v-if="item.content_item_image_url" class="item-image">
          <img
            :src="item.content_item_image_url"
            :alt="item.content_item_name"
            crossorigin="anonymous"
            loading="lazy"
          />
        </div>
        <div v-else class="item-icon">
          <i :class="getIconForItem(item)" />
        </div>
        <div class="item-info">
          <span class="item-name">{{ item.content_item_name }}</span>
          <span v-if="getItemPreview(item)" class="item-preview">
            {{ truncateText(getItemPreview(item), 80) }}
          </span>
        </div>
        <div class="item-arrow-wrapper">
          <i class="pi pi-chevron-right item-arrow" />
        </div>
      </button>

      <!-- Loading More Indicator -->
      <div v-if="isLoadingMore" class="loading-more">
        <i class="pi pi-spin pi-spinner" />
        <span>{{ $t('mobile.loading_more') }}</span>
      </div>

      <!-- End of List Indicator -->
      <div v-else-if="!hasMore && items.length > 0" class="end-of-list">
        <div class="end-of-list-line"></div>
        <span>{{ $t('mobile.end_of_list') }}</span>
        <div class="end-of-list-line"></div>
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
    <div v-if="card.conversation_ai_enabled" class="ai-section" role="complementary" :aria-label="$t('mobile.ask_ai')">
      <button @click="openAssistant" class="ai-browse-badge" :aria-label="$t('mobile.open_ai_assistant')">
        <span class="ai-badge-icon" aria-hidden="true">&#10024;</span>
        <span class="ai-badge-text">{{ $t('mobile.tap_to_chat_with_ai') }}</span>
        <i class="pi pi-chevron-right ai-badge-arrow" aria-hidden="true" />
      </button>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { CardLevelAssistant } from './AIAssistant'
import { buildContentDirectory } from './AIAssistant/utils/promptBuilder'
import { getInfiniteScrollThreshold } from '@/utils/paginationConfig'
import { truncateText } from '@/utils/formatters'

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
    card_id?: string
    card_name: string
    card_description: string
    card_image_url: string
    conversation_ai_enabled: boolean
    realtime_voice_enabled?: boolean
    ai_instruction?: string
    ai_knowledge_base?: string
    ai_welcome_general?: string
    ai_welcome_item?: string
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
  card_id: props.card.card_id,
  card_name: props.card.card_name,
  card_description: props.card.card_description,
  card_image_url: props.card.card_image_url,
  conversation_ai_enabled: props.card.conversation_ai_enabled,
  realtime_voice_enabled: props.card.realtime_voice_enabled,
  ai_instruction: props.card.ai_instruction || '',
  ai_knowledge_base: props.card.ai_knowledge_base || '',
  ai_welcome_general: props.card.ai_welcome_general || '',
  ai_welcome_item: props.card.ai_welcome_item || '',
  content_directory: props.items.length > 0 ? buildContentDirectory(props.items) : undefined,
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
  /* Fill parent flex container */
  flex: 1;
  display: flex;
  flex-direction: column;
  min-height: 0; /* Allow flex shrinking */
  padding: 1.5rem 1rem;
  padding-top: calc(1.5rem + env(safe-area-inset-top));
  padding-bottom: max(2rem, env(safe-area-inset-bottom));
  /* Extend background to fill container when content is short */
  background: transparent;
}

.layout-list.has-header {
  /* Fixed header (4.5rem) + search bar (3.75rem) + gaps (0.75rem) + safe area */
  padding-top: calc(9rem + env(safe-area-inset-top));
}

/* Extra bottom padding when AI assistant is present (fixed at bottom) */
.layout-list.has-ai {
  padding-bottom: calc(5rem + max(1rem, env(safe-area-inset-bottom)));
}

.list-container {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

/* Staggered entrance animation for list items */
@keyframes listItemEnter {
  from {
    opacity: 0;
    transform: translateY(8px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.list-item {
  display: flex;
  align-items: center;
  gap: 0.875rem;
  width: 100%;
  padding: 0.875rem 1rem;
  background: var(--theme-surface, rgba(255, 255, 255, 0.07));
  backdrop-filter: blur(12px);
  -webkit-backdrop-filter: blur(12px);
  border: 1px solid rgba(var(--theme-text-rgb), 0.1);
  border-radius: 1rem;
  color: rgba(var(--theme-text-rgb), 1);
  text-align: left;
  cursor: pointer;
  transition: background-color 0.2s, transform 0.15s, border-color 0.2s;
  -webkit-tap-highlight-color: transparent;
  touch-action: manipulation;
  min-height: 64px;
  /* Staggered entrance */
  animation: listItemEnter 0.35s ease-out both;
}

.list-item:active {
  background: rgba(var(--theme-text-rgb), 0.14);
  transform: scale(0.98);
  border-color: rgba(var(--theme-text-rgb), 0.18);
}

.list-item:focus-visible {
  outline: 2px solid var(--theme-primary, #6366f1);
  outline-offset: 2px;
}

.item-image {
  width: 52px;
  height: 52px;
  border-radius: 0.75rem;
  overflow: hidden;
  flex-shrink: 0;
  background: rgba(var(--theme-text-rgb), 0.06);
}

.item-image img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  transition: transform 0.3s ease;
}

.list-item:active .item-image img {
  transform: scale(1.05);
}

.item-icon {
  width: 52px;
  height: 52px;
  border-radius: 0.75rem;
  background: rgba(var(--theme-primary-rgb, 99, 102, 241), 0.15);
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
  background: linear-gradient(135deg, rgba(var(--theme-text-rgb), 0.1), transparent);
  opacity: 0;
  transition: opacity 0.2s;
}

.list-item:active .item-icon::before {
  opacity: 1;
}

.item-icon i {
  font-size: 1.25rem;
  color: rgba(var(--theme-text-rgb), 0.85);
}

.item-info {
  flex: 1;
  min-width: 0;
  display: flex;
  flex-direction: column;
  gap: 0.1875rem;
}

.item-name {
  font-size: 0.9375rem;
  font-weight: 600;
  line-height: 1.3;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

.item-preview {
  font-size: 0.8125rem;
  color: rgba(var(--theme-text-rgb), 0.55);
  line-height: 1.4;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

/* Chevron arrow with wrapper for better touch area */
.item-arrow-wrapper {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 1.5rem;
  flex-shrink: 0;
}

.item-arrow {
  color: rgba(var(--theme-text-rgb), 0.35);
  font-size: 0.75rem;
  transition: transform 0.2s, color 0.2s;
}

.list-item:active .item-arrow {
  transform: translateX(2px);
  color: rgba(var(--theme-text-rgb), 0.5);
}

.empty-state {
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  color: rgba(var(--theme-text-rgb), 0.5);
  gap: 1rem;
}

.empty-state i {
  font-size: 3rem;
}

/* Fixed AI Section at bottom - delayed fade-in to prevent transition flash */
.ai-section {
  position: fixed;
  bottom: 0;
  left: 0;
  right: 0;
  padding: 1rem 1rem;
  padding-bottom: max(1rem, env(safe-area-inset-bottom));
  background: linear-gradient(to top, rgba(var(--theme-bg-rgb, 15, 23, 42), 0.95) 0%, rgba(var(--theme-bg-rgb, 15, 23, 42), 0.8) 70%, transparent 100%);
  backdrop-filter: blur(12px);
  -webkit-backdrop-filter: blur(12px);
  z-index: 100;
  /* Delayed fade-in to sync with page transition */
  animation: aiSectionFadeIn 0.3s ease-out 0.35s both;
}

@keyframes aiSectionFadeIn {
  from {
    opacity: 0;
    transform: translateY(20px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

/* AI Browse Badge - General Assistant trigger */
.ai-browse-badge {
  display: flex;
  align-items: center;
  gap: 0.625rem;
  width: 100%;
  max-width: 400px;
  margin: 0 auto;
  padding: 0.75rem 1rem;
  background: rgba(var(--theme-primary-rgb, 99, 102, 241), 0.2);
  border: 1px solid rgba(var(--theme-primary-rgb, 99, 102, 241), 0.4);
  border-radius: 0.875rem;
  color: rgba(var(--theme-text-rgb), 1);
  font-size: 0.875rem;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.3s ease;
  -webkit-tap-highlight-color: transparent;
  touch-action: manipulation;
  box-shadow: 0 4px 10px rgba(var(--theme-primary-rgb, 99, 102, 241), 0.2);
  min-height: 48px;
}

.ai-browse-badge:hover {
  background: rgba(var(--theme-primary-rgb, 99, 102, 241), 0.3);
  border-color: rgba(var(--theme-primary-rgb, 99, 102, 241), 0.5);
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
  color: rgba(var(--theme-text-rgb), 0.6);
  font-size: 0.875rem;
}

.loading-more i {
  font-size: 1rem;
  color: rgba(var(--theme-primary-rgb, 99, 102, 241), 0.8);
}

/* End of List Indicator */
.end-of-list {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 0.75rem;
  padding: 1.25rem 1rem;
  color: rgba(var(--theme-text-rgb), 0.35);
  font-size: 0.75rem;
  font-weight: 500;
  letter-spacing: 0.02em;
}

.end-of-list-line {
  flex: 1;
  max-width: 3rem;
  height: 1px;
  background: linear-gradient(to right, transparent, rgba(var(--theme-text-rgb), 0.15), transparent);
}
</style>

