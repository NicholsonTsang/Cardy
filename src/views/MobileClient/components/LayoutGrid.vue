<template>
  <div
    class="layout-grid"
    :class="{ 'has-header': hasHeader, 'has-ai': card.conversation_ai_enabled }"
    role="main"
    :aria-label="t('mobile.explore_content')"
  >
    <!-- 2-Column Grid -->
    <div class="grid-container" role="list">
      <button
        v-for="item in items"
        :key="item.content_item_id"
        @click="handleItemClick(item)"
        class="grid-item"
        :class="{ 'no-image': !item.content_item_image_url }"
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
        <div class="item-info">
          <span class="item-name">{{ item.content_item_name }}</span>
          <span v-if="item.content_item_content" class="item-preview">
            {{ truncateText(item.content_item_content, 40) }}
          </span>
        </div>
        <!-- Favorite button overlaid -->
        <div
          class="grid-fav-btn"
          role="button"
          tabindex="0"
          :aria-label="isFavorite(item.content_item_id) ? t('mobile.removeFromFavorites') : t('mobile.addToFavorites')"
          @click.stop="toggleFavorite(item.content_item_id)"
          @keydown.enter.stop="toggleFavorite(item.content_item_id)"
          @keydown.space.stop="toggleFavorite(item.content_item_id)"
        >
          <i :class="isFavorite(item.content_item_id) ? 'pi pi-heart-fill' : 'pi pi-heart'" />
        </div>
      </button>
    </div>

    <!-- Empty State -->
    <div v-if="items.length === 0" class="empty-state">
      <i class="pi pi-th-large" />
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
import { useRoute } from 'vue-router'
import { useI18n } from 'vue-i18n'
import { CardLevelAssistant } from './AIAssistant'
import { buildContentDirectory } from './AIAssistant/utils/promptBuilder'
import { useFavorites } from '@/composables/useFavorites'
import { truncateText } from '@/utils/formatters'

const { t } = useI18n()
const route = useRoute()

// Favorites composable
const { isFavorite, toggleFavorite } = useFavorites({ cardId: (route.params.issue_card_id as string) || '' })

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
  items: ContentItem[]
  allItems?: ContentItem[]
  availableLanguages?: string[]
  hasHeader?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  hasHeader: false
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
  content_directory: props.items.length > 0 ? buildContentDirectory(props.items, props.allItems) : undefined,
  is_activated: props.card.is_activated
}))

// Open the General Assistant
function openAssistant() {
  cardAssistantRef.value?.openModal()
}

function handleItemClick(item: ContentItem) {
  emit('select', item)
}
</script>

<style scoped>
.layout-grid {
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

.layout-grid.has-header {
  /* Fixed header (4.5rem) + search bar (3.75rem) + gaps (0.75rem) + safe area */
  padding-top: calc(9rem + env(safe-area-inset-top));
}

/* Extra bottom padding when AI assistant is present (fixed at bottom) */
.layout-grid.has-ai {
  padding-bottom: calc(5rem + max(1rem, env(safe-area-inset-bottom)));
}

.grid-container {
  flex: 1;
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 0.875rem;
}

.grid-item {
  display: flex;
  flex-direction: column;
  background: var(--theme-surface, rgba(255, 255, 255, 0.07));
  backdrop-filter: blur(12px);
  -webkit-backdrop-filter: blur(12px);
  border: 1px solid rgba(var(--theme-text-rgb), 0.1);
  border-radius: 1rem;
  overflow: hidden;
  cursor: pointer;
  transition: all 0.25s cubic-bezier(0.4, 0, 0.2, 1);
  -webkit-tap-highlight-color: transparent;
  position: relative;
}

.grid-item::after {
  content: '';
  position: absolute;
  inset: 0;
  border-radius: 1rem;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.3);
  opacity: 0;
  transition: opacity 0.25s;
  pointer-events: none;
}

.grid-item:active {
  background: rgba(var(--theme-text-rgb), 0.15);
  transform: scale(0.96);
  border-color: rgba(var(--theme-text-rgb), 0.2);
}

.grid-item:focus-visible {
  outline: 2px solid var(--theme-primary, #6366f1);
  outline-offset: 2px;
}

.grid-item:active::after {
  opacity: 1;
}

.item-image {
  aspect-ratio: 1;
  width: 100%;
  background: rgba(var(--theme-primary-rgb, 99, 102, 241), 0.08);
  position: relative;
  overflow: hidden;
}

.item-image img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  transition: transform 0.3s ease;
}

.grid-item:active .item-image img {
  transform: scale(1.05);
}

.item-info {
  padding: 0.75rem 0.625rem;
  text-align: center;
  background: linear-gradient(to top, rgba(0, 0, 0, 0.1), transparent);
  display: flex;
  flex-direction: column;
  min-height: 3.5rem; /* Consistent height even without preview */
}

/* No-image grid items - show content-only card */
.grid-item.no-image {
  justify-content: center;
  align-items: center;
  padding: 1rem;
  min-height: 120px;
}

.grid-item.no-image .item-info {
  background: none;
  padding: 0;
  width: 100%;
  min-height: auto;
}

.item-name {
  font-size: 0.875rem;
  font-weight: 600;
  color: rgba(var(--theme-text-rgb), 1);
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
  line-height: 1.3;
}

.item-preview {
  font-size: 0.75rem;
  color: rgba(var(--theme-text-rgb), 0.7); /* WCAG AA: improved from 0.55 for contrast */
  margin-top: 0.25rem;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  line-height: 1.4;
}

/* Grid favorite button */
.grid-fav-btn {
  position: absolute;
  top: 0.5rem;
  right: 0.5rem;
  width: 2rem;
  height: 2rem;
  min-width: 44px;
  min-height: 44px;
  border-radius: 50%;
  background: rgba(0, 0, 0, 0.5);
  backdrop-filter: blur(8px);
  -webkit-backdrop-filter: blur(8px);
  border: 1px solid rgba(var(--theme-text-rgb), 0.15);
  color: rgba(var(--theme-text-rgb), 1);
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: all 0.2s ease;
  -webkit-tap-highlight-color: transparent;
  touch-action: manipulation;
  z-index: 2;
}

.grid-fav-btn:active {
  transform: scale(0.85);
}

.grid-fav-btn:focus-visible {
  outline: 2px solid var(--theme-primary, #6366f1);
  outline-offset: 2px;
}

.grid-fav-btn i {
  font-size: 0.875rem;
}

.grid-fav-btn .pi-heart-fill {
  color: #f87171;
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
  padding: 1rem 1.25rem;
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
</style>

