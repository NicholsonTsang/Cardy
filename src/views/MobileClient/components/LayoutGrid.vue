<template>
  <div class="layout-grid" :class="{ 'has-header': hasHeader, 'has-ai': card.conversation_ai_enabled }">
    <!-- 2-Column Grid -->
    <div class="grid-container">
      <button
        v-for="item in items"
        :key="item.content_item_id"
        @click="handleItemClick(item)"
        class="grid-item"
      >
        <div class="item-image">
          <img 
            v-if="item.content_item_image_url"
            :src="item.content_item_image_url" 
            :alt="item.content_item_name" 
            crossorigin="anonymous"
          />
          <div v-else class="image-placeholder">
            <i class="pi pi-image" />
          </div>
        </div>
        <div class="item-info">
          <span class="item-name">{{ item.content_item_name }}</span>
          <span v-if="item.content_item_content" class="item-preview">
            {{ truncateText(item.content_item_content, 40) }}
          </span>
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
.layout-grid {
  min-height: 100vh;
  min-height: 100dvh;
  display: flex;
  flex-direction: column;
  padding: 1.5rem 1.25rem;
  padding-top: calc(1.5rem + env(safe-area-inset-top));
  padding-bottom: max(2rem, env(safe-area-inset-bottom));
}

.layout-grid.has-header {
  padding-top: calc(6.5rem + env(safe-area-inset-top));
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
  background: rgba(255, 255, 255, 0.08);
  backdrop-filter: blur(12px);
  -webkit-backdrop-filter: blur(12px);
  border: 1px solid rgba(255, 255, 255, 0.1);
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
  background: rgba(255, 255, 255, 0.15);
  transform: scale(0.96);
  border-color: rgba(255, 255, 255, 0.2);
}

.grid-item:active::after {
  opacity: 1;
}

.item-image {
  aspect-ratio: 1;
  width: 100%;
  background: linear-gradient(135deg, rgba(59, 130, 246, 0.1), rgba(147, 51, 234, 0.1));
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

.image-placeholder {
  width: 100%;
  height: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  color: rgba(255, 255, 255, 0.4);
  background: linear-gradient(135deg, rgba(59, 130, 246, 0.15), rgba(147, 51, 234, 0.15));
}

.image-placeholder i {
  font-size: 2rem;
}

.item-info {
  padding: 0.75rem 0.625rem;
  text-align: center;
  background: linear-gradient(to top, rgba(0, 0, 0, 0.1), transparent);
  display: flex;
  flex-direction: column;
  min-height: 3.5rem; /* Consistent height even without preview */
}

.item-name {
  font-size: 0.875rem;
  font-weight: 600;
  color: white;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
  line-height: 1.3;
}

.item-preview {
  font-size: 0.75rem;
  color: rgba(255, 255, 255, 0.55);
  margin-top: 0.25rem;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  line-height: 1.4;
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
</style>

