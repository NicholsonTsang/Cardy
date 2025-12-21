<template>
  <div class="layout-grouped-collapsed" :class="{ 'has-header': hasHeader, 'has-ai': card.conversation_ai_enabled }">
    <!-- Collapsed Grouped Content: Categories shown as navigable items -->
    <div class="categories-container">
      <!-- Render categories based on layout style -->
      <template v-if="layoutStyle === 'grid'">
        <!-- Grid layout for categories -->
        <div class="categories-grid">
          <button
            v-for="category in items" 
            :key="category.content_item_id"
            @click="handleCategoryClick(category)"
            class="category-card category-card-grid"
          >
            <div v-if="category.content_item_image_url" class="category-image">
              <img :src="category.content_item_image_url" :alt="category.content_item_name" crossorigin="anonymous" />
            </div>
            <div v-else class="category-placeholder">
              <i class="pi pi-folder" />
            </div>
            <div class="category-info">
              <span class="category-name">{{ category.content_item_name }}</span>
              <span class="category-count">{{ getChildCount(category.content_item_id) }} {{ $t('mobile.items') }}</span>
            </div>
            <i class="pi pi-chevron-right category-arrow" />
          </button>
        </div>
      </template>

      <template v-else-if="layoutStyle === 'cards'">
        <!-- Full-width card layout for categories -->
        <div class="categories-cards">
          <button
            v-for="category in items" 
            :key="category.content_item_id"
            @click="handleCategoryClick(category)"
            class="category-card category-card-full"
          >
            <div v-if="category.content_item_image_url" class="category-image-large">
              <img :src="category.content_item_image_url" :alt="category.content_item_name" crossorigin="anonymous" />
            </div>
            <div class="category-content">
              <span class="category-name-large">{{ category.content_item_name }}</span>
              <span v-if="category.content_item_content" class="category-preview">
                {{ truncateText(category.content_item_content, 100) }}
              </span>
              <span class="category-count">{{ getChildCount(category.content_item_id) }} {{ $t('mobile.items') }}</span>
            </div>
            <i class="pi pi-chevron-right category-arrow-large" />
          </button>
        </div>
      </template>

      <template v-else>
        <!-- Default list layout for categories -->
        <div class="categories-list">
          <button
            v-for="category in items" 
            :key="category.content_item_id"
            @click="handleCategoryClick(category)"
            class="category-card category-card-list"
          >
            <div class="category-icon">
              <i class="pi pi-folder" />
            </div>
            <div class="category-info">
              <span class="category-name">{{ category.content_item_name }}</span>
              <span class="category-count">{{ getChildCount(category.content_item_id) }} {{ $t('mobile.items') }}</span>
            </div>
            <i class="pi pi-chevron-right category-arrow" />
          </button>
        </div>
      </template>
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
  layoutStyle?: 'list' | 'grid' | 'cards'
}

const props = withDefaults(defineProps<Props>(), {
  hasHeader: false,
  layoutStyle: 'list'
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

// Get count of child items for a category
function getChildCount(parentId: string): number {
  return (props.allItems || []).filter(item => item.content_item_parent_id === parentId).length
}

function truncateText(text: string, maxLength: number): string {
  if (!text) return ''
  const plainText = text.replace(/<[^>]*>/g, '').replace(/[#*_`]/g, '')
  return plainText.length > maxLength 
    ? plainText.slice(0, maxLength) + '...'
    : plainText
}

function handleCategoryClick(category: ContentItem) {
  // Emit select with the category - parent component will navigate to show children
  emit('select', category)
}
</script>

<style scoped>
.layout-grouped-collapsed {
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

.layout-grouped-collapsed.has-header {
  padding-top: calc(6.5rem + env(safe-area-inset-top));
}

/* Extra bottom padding when AI assistant is present (fixed at bottom) */
.layout-grouped-collapsed.has-ai {
  padding-bottom: calc(5rem + max(1rem, env(safe-area-inset-bottom)));
}

.categories-container {
  flex: 1;
}

/* List Layout */
.categories-list {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}

.category-card-list {
  display: flex;
  align-items: center;
  gap: 1rem;
  width: 100%;
  padding: 1rem 1.25rem;
  background: rgba(255, 255, 255, 0.06);
  backdrop-filter: blur(12px);
  -webkit-backdrop-filter: blur(12px);
  border: 1px solid rgba(255, 255, 255, 0.08);
  border-radius: 1rem;
  color: white;
  text-align: left;
  cursor: pointer;
  transition: all 0.25s cubic-bezier(0.4, 0, 0.2, 1);
  -webkit-tap-highlight-color: transparent;
}

.category-card-list:active {
  background: rgba(255, 255, 255, 0.12);
  transform: scale(0.98);
}

.category-icon {
  width: 44px;
  height: 44px;
  border-radius: 0.75rem;
  background: linear-gradient(135deg, rgba(59, 130, 246, 0.2), rgba(139, 92, 246, 0.2));
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.category-icon i {
  font-size: 1.25rem;
  color: rgba(255, 255, 255, 0.8);
}

/* Grid Layout */
.categories-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 0.75rem;
}

.category-card-grid {
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  width: 100%;
  padding: 0;
  background: rgba(255, 255, 255, 0.06);
  backdrop-filter: blur(12px);
  -webkit-backdrop-filter: blur(12px);
  border: 1px solid rgba(255, 255, 255, 0.08);
  border-radius: 1rem;
  color: white;
  text-align: left;
  cursor: pointer;
  transition: all 0.25s cubic-bezier(0.4, 0, 0.2, 1);
  -webkit-tap-highlight-color: transparent;
  overflow: hidden;
  position: relative;
}

.category-card-grid:active {
  background: rgba(255, 255, 255, 0.12);
  transform: scale(0.98);
}

.category-image {
  width: 100%;
  aspect-ratio: 4/3;
  overflow: hidden;
  background: rgba(255, 255, 255, 0.1);
}

.category-image img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.category-placeholder {
  width: 100%;
  aspect-ratio: 4/3;
  background: linear-gradient(135deg, rgba(59, 130, 246, 0.15), rgba(139, 92, 246, 0.15));
  display: flex;
  align-items: center;
  justify-content: center;
}

.category-placeholder i {
  font-size: 2rem;
  color: rgba(255, 255, 255, 0.4);
}

.category-card-grid .category-info {
  padding: 0.875rem 1rem;
  width: 100%;
}

.category-card-grid .category-arrow {
  position: absolute;
  top: 0.75rem;
  right: 0.75rem;
  background: rgba(0, 0, 0, 0.5);
  border-radius: 50%;
  width: 24px;
  height: 24px;
  display: flex;
  align-items: center;
  justify-content: center;
}

/* Full Card Layout */
.categories-cards {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.category-card-full {
  display: flex;
  align-items: center;
  gap: 1rem;
  width: 100%;
  padding: 0;
  background: rgba(255, 255, 255, 0.06);
  backdrop-filter: blur(12px);
  -webkit-backdrop-filter: blur(12px);
  border: 1px solid rgba(255, 255, 255, 0.08);
  border-radius: 1rem;
  color: white;
  text-align: left;
  cursor: pointer;
  transition: all 0.25s cubic-bezier(0.4, 0, 0.2, 1);
  -webkit-tap-highlight-color: transparent;
  overflow: hidden;
}

.category-card-full:active {
  background: rgba(255, 255, 255, 0.12);
  transform: scale(0.98);
}

.category-image-large {
  width: 120px;
  height: 100px;
  flex-shrink: 0;
  overflow: hidden;
  background: rgba(255, 255, 255, 0.1);
}

.category-image-large img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.category-content {
  flex: 1;
  padding: 1rem 0;
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
  min-width: 0;
}

.category-name-large {
  font-size: 1.125rem;
  font-weight: 600;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.category-preview {
  font-size: 0.875rem;
  color: rgba(255, 255, 255, 0.6);
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

.category-arrow-large {
  padding-right: 1rem;
  color: rgba(255, 255, 255, 0.4);
  font-size: 1rem;
  flex-shrink: 0;
}

/* Common Info Styles */
.category-info {
  flex: 1;
  min-width: 0;
  display: flex;
  flex-direction: column;
}

.category-name {
  font-size: 1rem;
  font-weight: 600;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.category-count {
  font-size: 0.8125rem;
  color: rgba(255, 255, 255, 0.5);
  margin-top: 0.125rem;
}

.category-arrow {
  color: rgba(255, 255, 255, 0.3);
  font-size: 0.875rem;
  flex-shrink: 0;
}

/* Empty State */
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
</style>

