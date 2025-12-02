<template>
  <div class="layout-inline" :class="{ 'has-header': hasHeader }">
    <!-- Full-Width Cards (One per row) -->
    <div class="cards-container">
      <button
        v-for="item in items"
        :key="item.content_item_id"
        @click="handleItemClick(item)"
        class="inline-card"
      >
        <!-- Card Image (full width) -->
        <div class="card-image">
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
        
        <!-- Card Info -->
        <div class="card-info">
          <span class="card-name">{{ item.content_item_name }}</span>
          <span v-if="item.content_item_content" class="card-preview">
            {{ truncateText(item.content_item_content, 100) }}
          </span>
          <div class="card-action">
            <span class="action-text">{{ $t('mobile.view_details') }}</span>
            <i class="pi pi-arrow-right action-icon" />
          </div>
        </div>
      </button>
    </div>

    <!-- Empty State -->
    <div v-if="items.length === 0" class="empty-state">
      <i class="pi pi-inbox" />
      <p>{{ $t('mobile.no_items') }}</p>
    </div>

    <!-- AI Assistant (if enabled) -->
    <div v-if="card.conversation_ai_enabled" class="ai-section">
      <MobileAIAssistant 
        :content-item-name="card.card_name"
        :content-item-content="card.card_description"
        :content-item-knowledge-base="card.ai_knowledge_base || ''"
        :parent-content-knowledge-base="''"
        :card-data="card"
      />
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { useI18n } from 'vue-i18n'
import { MobileAIAssistant } from './AIAssistant'

const { t } = useI18n()

interface ContentItem {
  content_item_id: string
  content_item_parent_id: string | null
  content_item_name: string
  content_item_content: string
  content_item_image_url: string
  content_item_ai_knowledge_base: string
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

function truncateText(text: string, maxLength: number): string {
  if (!text) return ''
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
.layout-inline {
  min-height: 100vh;
  min-height: 100dvh;
  display: flex;
  flex-direction: column;
  padding: 1.5rem 1.25rem;
  padding-top: calc(1.5rem + env(safe-area-inset-top));
  padding-bottom: max(2rem, env(safe-area-inset-bottom));
}

.layout-inline.has-header {
  padding-top: calc(6.5rem + env(safe-area-inset-top));
}

.cards-container {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.inline-card {
  width: 100%;
  display: flex;
  flex-direction: column;
  background: rgba(255, 255, 255, 0.08);
  backdrop-filter: blur(12px);
  -webkit-backdrop-filter: blur(12px);
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 1.25rem;
  overflow: hidden;
  cursor: pointer;
  transition: all 0.2s;
  -webkit-tap-highlight-color: transparent;
  text-align: left;
}

.inline-card:active {
  background: rgba(255, 255, 255, 0.15);
  transform: scale(0.98);
}

.card-image {
  aspect-ratio: 16/9;
  width: 100%;
  background: rgba(255, 255, 255, 0.05);
}

.card-image img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.image-placeholder {
  width: 100%;
  height: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  color: rgba(255, 255, 255, 0.3);
}

.image-placeholder i {
  font-size: 2.5rem;
}

.card-info {
  padding: 1rem 1.25rem;
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.card-name {
  font-size: 1.125rem;
  font-weight: 600;
  color: white;
  line-height: 1.3;
}

.card-preview {
  font-size: 0.875rem;
  color: rgba(255, 255, 255, 0.6);
  line-height: 1.5;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

.card-action {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  margin-top: 0.5rem;
  color: rgba(255, 255, 255, 0.5);
  font-size: 0.8125rem;
}

.action-icon {
  font-size: 0.75rem;
  transition: transform 0.2s;
}

.inline-card:hover .action-icon {
  transform: translateX(4px);
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

.ai-section {
  margin-top: 1.5rem;
  width: 100%;
  max-width: 400px;
  margin-left: auto;
  margin-right: auto;
}
</style>
