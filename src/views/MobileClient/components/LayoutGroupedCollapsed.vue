<template>
  <div
    class="layout-grouped-collapsed"
    :class="{ 'has-header': hasHeader, 'has-ai': card.conversation_ai_enabled }"
    role="navigation"
    :aria-label="t('mobile.filterByCategory')"
  >
    <!-- Collapsed Grouped Content: Categories shown as navigable items -->
    <div class="categories-container">
      <!-- Render categories based on layout style -->
      <template v-if="layoutStyle === 'grid'">
        <!-- Grid layout for categories -->
        <div class="categories-grid" role="list">
          <button
            v-for="(category, index) in items"
            :key="category.content_item_id"
            @click="handleCategoryClick(category)"
            class="category-card category-card-grid"
            :class="{ 'no-image': !category.content_item_image_url }"
            :style="{ animationDelay: `${Math.min(index * 0.05, 0.4)}s` }"
            role="listitem"
            :aria-label="`${category.content_item_name} - ${getChildCount(category.content_item_id)} ${t('mobile.items')}`"
          >
            <div v-if="category.content_item_image_url" class="category-image">
              <img :src="category.content_item_image_url" :alt="category.content_item_name" crossorigin="anonymous" loading="lazy" />
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
        <div class="categories-cards" role="list">
          <button
            v-for="(category, index) in items"
            :key="category.content_item_id"
            @click="handleCategoryClick(category)"
            class="category-card category-card-full"
            :class="{ 'no-image': !category.content_item_image_url }"
            :style="{ animationDelay: `${Math.min(index * 0.05, 0.4)}s` }"
            role="listitem"
            :aria-label="`${category.content_item_name} - ${getChildCount(category.content_item_id)} ${t('mobile.items')}`"
          >
            <div v-if="category.content_item_image_url" class="category-image-large">
              <img :src="category.content_item_image_url" :alt="category.content_item_name" crossorigin="anonymous" loading="lazy" />
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
        <div class="categories-list" role="list">
          <button
            v-for="(category, index) in items"
            :key="category.content_item_id"
            @click="handleCategoryClick(category)"
            class="category-card category-card-list"
            :style="{ animationDelay: `${Math.min(index * 0.05, 0.4)}s` }"
            role="listitem"
            :aria-label="`${category.content_item_name} - ${getChildCount(category.content_item_id)} ${t('mobile.items')}`"
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
    <div v-if="card.conversation_ai_enabled" class="ai-section" role="complementary" :aria-label="t('mobile.ask_ai')">
      <button @click="openAssistant" class="ai-browse-badge" :aria-label="t('mobile.open_ai_assistant')">
        <span class="ai-badge-icon" aria-hidden="true">&#10024;</span>
        <span class="ai-badge-text">{{ $t('mobile.tap_to_chat_with_ai') }}</span>
        <i class="pi pi-chevron-right ai-badge-arrow" aria-hidden="true" />
      </button>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { useI18n } from 'vue-i18n'
import { CardLevelAssistant } from './AIAssistant'
import { truncateText } from '@/utils/formatters'
import { buildContentDirectory } from './AIAssistant/utils/promptBuilder'

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
  content_directory: props.allItems.length > 0 ? buildContentDirectory(props.items, props.allItems) : undefined,
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
  padding: 1.5rem 1rem;
  padding-top: calc(1.5rem + env(safe-area-inset-top));
  padding-bottom: max(2rem, env(safe-area-inset-bottom));
  /* Extend background to fill container when content is short */
  background: transparent;
}

.layout-grouped-collapsed.has-header {
  /* Fixed header (4.5rem) + search bar (3.75rem) + gaps (0.75rem) + safe area */
  padding-top: calc(9rem + env(safe-area-inset-top));
}

/* Extra bottom padding when AI assistant is present (fixed at bottom) */
.layout-grouped-collapsed.has-ai {
  padding-bottom: calc(5rem + max(1rem, env(safe-area-inset-bottom)));
}

.categories-container {
  flex: 1;
}

/* Staggered entrance animation for category cards */
@keyframes categoryEnter {
  from {
    opacity: 0;
    transform: translateY(8px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

/* List Layout */
.categories-list {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.category-card-list {
  display: flex;
  align-items: center;
  gap: 0.875rem;
  width: 100%;
  padding: 0.875rem 1rem;
  background: rgba(255, 255, 255, 0.07);
  backdrop-filter: blur(12px);
  -webkit-backdrop-filter: blur(12px);
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 1rem;
  color: white;
  text-align: left;
  cursor: pointer;
  transition: background-color 0.2s, transform 0.15s, border-color 0.2s;
  -webkit-tap-highlight-color: transparent;
  touch-action: manipulation;
  min-height: 64px;
  animation: categoryEnter 0.35s ease-out both;
}

.category-card-list:active {
  background: rgba(255, 255, 255, 0.14);
  transform: scale(0.98);
  border-color: rgba(255, 255, 255, 0.18);
}

.category-card-list:focus-visible {
  outline: 2px solid #60a5fa;
  outline-offset: 2px;
}

.category-icon {
  width: 48px;
  height: 48px;
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
  background: rgba(255, 255, 255, 0.07);
  backdrop-filter: blur(12px);
  -webkit-backdrop-filter: blur(12px);
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 1rem;
  color: white;
  text-align: left;
  cursor: pointer;
  transition: background-color 0.2s, transform 0.15s, border-color 0.2s;
  -webkit-tap-highlight-color: transparent;
  touch-action: manipulation;
  overflow: hidden;
  position: relative;
  animation: categoryEnter 0.35s ease-out both;
}

.category-card-grid:active {
  background: rgba(255, 255, 255, 0.14);
  transform: scale(0.97);
  border-color: rgba(255, 255, 255, 0.18);
}

.category-card-grid:focus-visible {
  outline: 2px solid #60a5fa;
  outline-offset: 2px;
}

.category-image {
  width: 100%;
  aspect-ratio: 4/3;
  overflow: hidden;
  background: rgba(255, 255, 255, 0.06);
}

.category-image img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  transition: transform 0.3s ease;
}

.category-card-grid:active .category-image img {
  transform: scale(1.05);
}

.category-card-grid .category-info {
  padding: 0.875rem 1rem;
  width: 100%;
}

/* No-image grid cards - content-only layout */
.category-card-grid.no-image {
  justify-content: center;
  align-items: center;
  padding: 1.25rem 1rem;
  min-height: 140px;
}

.category-card-grid.no-image .category-info {
  padding: 0;
  text-align: center;
}

.category-card-grid.no-image .category-arrow {
  top: 0.625rem;
  right: 0.625rem;
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
  gap: 0.75rem;
}

.category-card-full {
  display: flex;
  align-items: center;
  gap: 1rem;
  width: 100%;
  padding: 0;
  background: rgba(255, 255, 255, 0.07);
  backdrop-filter: blur(12px);
  -webkit-backdrop-filter: blur(12px);
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 1rem;
  color: white;
  text-align: left;
  cursor: pointer;
  transition: background-color 0.2s, transform 0.15s, border-color 0.2s;
  -webkit-tap-highlight-color: transparent;
  touch-action: manipulation;
  overflow: hidden;
  animation: categoryEnter 0.35s ease-out both;
}

.category-card-full:active {
  background: rgba(255, 255, 255, 0.14);
  transform: scale(0.98);
  border-color: rgba(255, 255, 255, 0.18);
}

.category-card-full:focus-visible {
  outline: 2px solid #60a5fa;
  outline-offset: 2px;
}

.category-image-large {
  width: 120px;
  height: 100px;
  flex-shrink: 0;
  overflow: hidden;
  background: rgba(255, 255, 255, 0.06);
}

.category-image-large img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  transition: transform 0.3s ease;
}

.category-card-full:active .category-image-large img {
  transform: scale(1.05);
}

.category-content {
  flex: 1;
  padding: 1rem 0;
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
  min-width: 0;
}

/* No-image full cards - adjust content padding */
.category-card-full.no-image .category-content {
  padding: 1rem 1rem 1rem 1.25rem;
}

.category-name-large {
  font-size: 1.0625rem;
  font-weight: 600;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.category-preview {
  font-size: 0.8125rem;
  color: rgba(255, 255, 255, 0.55);
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
  line-height: 1.4;
}

.category-arrow-large {
  padding-right: 1rem;
  color: rgba(255, 255, 255, 0.35);
  font-size: 0.875rem;
  flex-shrink: 0;
  transition: transform 0.2s, color 0.2s;
}

.category-card-full:active .category-arrow-large {
  transform: translateX(2px);
  color: rgba(255, 255, 255, 0.5);
}

/* Common Info Styles */
.category-info {
  flex: 1;
  min-width: 0;
  display: flex;
  flex-direction: column;
  gap: 0.125rem;
}

.category-name {
  font-size: 0.9375rem;
  font-weight: 600;
  line-height: 1.3;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

.category-count {
  font-size: 0.8125rem;
  color: rgba(255, 255, 255, 0.5);
}

.category-arrow {
  color: rgba(255, 255, 255, 0.35);
  font-size: 0.75rem;
  flex-shrink: 0;
  transition: transform 0.2s, color 0.2s;
}

.category-card-list:active .category-arrow {
  transform: translateX(2px);
  color: rgba(255, 255, 255, 0.5);
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
  padding: 1rem 1rem;
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

