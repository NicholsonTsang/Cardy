<template>
  <div class="layout-grouped" :class="{ 'has-header': hasHeader, 'has-ai': card.conversation_ai_enabled, 'has-categories': hasCategories }">
    <!-- Grouped Content: Categories with sub-items -->
    <div class="categories-container">
      <div 
        v-for="category in items" 
        :key="category.content_item_id"
        class="category-section"
      >
        <!-- Category Header (Parent Item as title, no description) -->
        <h2 class="category-title">{{ category.content_item_name }}</h2>
        
        <!-- Category Items (Children) -->
        <div class="category-items">
          <button
            v-for="item in getChildItems(category.content_item_id)"
            :key="item.content_item_id"
            @click="handleItemClick(item)"
            class="item-button"
          >
            <div v-if="item.content_item_image_url" class="item-image">
              <img :src="item.content_item_image_url" :alt="item.content_item_name" crossorigin="anonymous" />
            </div>
            <div class="item-info">
              <span class="item-name">{{ item.content_item_name }}</span>
              <span v-if="item.content_item_content" class="item-preview">
                {{ truncateText(item.content_item_content, 60) }}
              </span>
            </div>
            <i class="pi pi-chevron-right item-arrow" />
          </button>
        </div>
      </div>
    </div>

    <!-- Empty State -->
    <div v-if="items.length === 0" class="empty-state">
      <i class="pi pi-folder" />
      <p>{{ $t('mobile.no_categories') }}</p>
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
import { useI18n } from 'vue-i18n'
import { CardLevelAssistant } from './AIAssistant'

const { t } = useI18n()

// Card Level Assistant ref
const cardAssistantRef = ref<InstanceType<typeof CardLevelAssistant> | null>(null)

interface ContentItem {
  content_item_id: string
  content_item_parent_id: string | null
  content_item_name: string
  content_item_content?: string       // Full content (optional for optimized loading)
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
    ai_welcome_general?: string
    ai_welcome_item?: string
    is_activated: boolean
  }
  items: ContentItem[] // Parent items (categories)
  allItems: ContentItem[] // All items including children
  availableLanguages?: string[]
  hasHeader?: boolean
  hasCategories?: boolean // Whether category chips are shown above this layout
  matchingChildIds?: Set<string> // When search is active, only show matching children
}

const props = withDefaults(defineProps<Props>(), {
  hasHeader: false,
  hasCategories: false,
  matchingChildIds: undefined
})

const emit = defineEmits<{
  select: [item: ContentItem]
}>()

// Card data formatted for General AI assistant
const cardDataForAssistant = computed(() => ({
  card_name: props.card.card_name,
  card_description: props.card.card_description,
  card_image_url: props.card.card_image_url,
  conversation_ai_enabled: props.card.conversation_ai_enabled,
  ai_instruction: props.card.ai_instruction || '',
  ai_knowledge_base: props.card.ai_knowledge_base || '',
  ai_welcome_general: props.card.ai_welcome_general || '',
  ai_welcome_item: props.card.ai_welcome_item || '',
  is_activated: props.card.is_activated
}))

// Open the General Assistant
function openAssistant() {
  cardAssistantRef.value?.openModal()
}

// Get child items for a category
// When matchingChildIds is provided (search active), only show matching children
function getChildItems(parentId: string): ContentItem[] {
  return (props.allItems || [])
    .filter(item => {
      if (item.content_item_parent_id !== parentId) return false
      if (props.matchingChildIds && props.matchingChildIds.size > 0) {
        return props.matchingChildIds.has(item.content_item_id)
      }
      return true
    })
    .sort((a, b) => a.content_item_sort_order - b.content_item_sort_order)
}

function truncateText(text: string, maxLength: number): string {
  if (!text) return ''
  // Strip HTML/markdown
  const plainText = text.replace(/<[^>]*>/g, '').replace(/[#*_`]/g, '')
  return plainText.length > maxLength 
    ? plainText.slice(0, maxLength) + '...'
    : plainText
}

function handleItemClick(item: ContentItem) {
  emit('select', item)
}
</script>

<style scoped>
.layout-grouped {
  /* Fill parent flex container */
  flex: 1;
  display: flex;
  flex-direction: column;
  min-height: 0; /* Allow flex shrinking */
  padding: 1.5rem 1.25rem;
  padding-top: calc(1.5rem + env(safe-area-inset-top));
  padding-bottom: max(2rem, env(safe-area-inset-bottom));
  /* Extend background to fill container when content is short */
  background: transparent;
}

.layout-grouped.has-header {
  /* Fixed header (4.5rem) + search bar (3.75rem) + gaps (0.75rem) + safe area */
  padding-top: calc(9rem + env(safe-area-inset-top));
}

.layout-grouped.has-header.has-categories {
  /* Add extra space for category filter chips (~3.5rem) + result count indicator (~1rem) */
  padding-top: calc(13.5rem + env(safe-area-inset-top));
}

.layout-grouped.has-categories:not(.has-header) {
  /* Category chips without header */
  padding-top: calc(5rem + env(safe-area-inset-top));
}

/* Extra bottom padding when AI assistant is present (fixed at bottom) */
.layout-grouped.has-ai {
  padding-bottom: calc(5rem + max(1rem, env(safe-area-inset-bottom)));
}

.categories-container {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
}

.category-section {
  animation: fadeIn 0.5s ease-out;
  background: rgba(255, 255, 255, 0.03);
  border-radius: 1rem;
  padding: 1rem;
  border: 1px solid rgba(255, 255, 255, 0.05);
}

@keyframes fadeIn {
  from { opacity: 0; transform: translateY(10px); }
  to { opacity: 1; transform: translateY(0); }
}

.category-title {
  font-size: 0.8125rem;
  font-weight: 700;
  color: rgba(255, 255, 255, 0.5);
  text-transform: uppercase;
  letter-spacing: 0.08em;
  margin: 0 0 0.875rem 0;
  padding-bottom: 0.625rem;
  border-bottom: 1px solid rgba(255, 255, 255, 0.08);
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.category-title::before {
  content: '';
  width: 4px;
  height: 16px;
  background: linear-gradient(to bottom, #3b82f6, #8b5cf6);
  border-radius: 2px;
}

.category-items {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.item-button {
  display: flex;
  align-items: center;
  gap: 0.875rem;
  width: 100%;
  padding: 0.875rem 1rem;
  background: rgba(255, 255, 255, 0.06);
  backdrop-filter: blur(12px);
  -webkit-backdrop-filter: blur(12px);
  border: 1px solid rgba(255, 255, 255, 0.08);
  border-radius: 0.875rem;
  color: white;
  text-align: left;
  cursor: pointer;
  transition: all 0.25s cubic-bezier(0.4, 0, 0.2, 1);
  -webkit-tap-highlight-color: transparent;
  position: relative;
  overflow: hidden;
}

.item-button::before {
  content: '';
  position: absolute;
  left: 0;
  top: 0;
  bottom: 0;
  width: 0;
  background: linear-gradient(90deg, rgba(59, 130, 246, 0.15), transparent);
  transition: width 0.3s;
}

.item-button:active {
  background: rgba(255, 255, 255, 0.12);
  transform: scale(0.98);
  border-color: rgba(255, 255, 255, 0.15);
}

.item-button:active::before {
  width: 100%;
}

.item-image {
  width: 40px;
  height: 40px;
  border-radius: 0.5rem;
  overflow: hidden;
  flex-shrink: 0;
  background: rgba(255, 255, 255, 0.1);
}

.item-image img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.item-info {
  flex: 1;
  min-width: 0;
  display: flex;
  flex-direction: column;
}

.item-name {
  font-size: 1rem;
  font-weight: 500;
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
  margin-top: 0.125rem;
}

.item-arrow {
  color: rgba(255, 255, 255, 0.3);
  font-size: 0.75rem;
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

/* Fixed AI Section at bottom - delayed fade-in to prevent transition flash */
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
  background: linear-gradient(135deg, rgba(139, 92, 246, 0.25) 0%, rgba(59, 130, 246, 0.25) 100%);
  border: 1px solid rgba(139, 92, 246, 0.4);
  border-radius: 0.875rem;
  color: white;
  font-size: 0.875rem;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.3s ease;
  -webkit-tap-highlight-color: transparent;
  touch-action: manipulation;
  box-shadow: 0 4px 10px rgba(139, 92, 246, 0.2);
  min-height: 48px;
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
</style>

