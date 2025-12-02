<template>
  <div class="layout-grouped" :class="{ 'has-header': hasHeader }">
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
  items: ContentItem[] // Parent items (categories)
  allItems: ContentItem[] // All items including children
  availableLanguages?: string[]
  hasHeader?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  hasHeader: false
})

const emit = defineEmits<{
  select: [item: ContentItem]
}>()

// Get child items for a category
function getChildItems(parentId: string): ContentItem[] {
  return (props.allItems || [])
    .filter(item => item.content_item_parent_id === parentId)
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
  min-height: 100vh;
  min-height: 100dvh;
  display: flex;
  flex-direction: column;
  padding: 1.5rem 1.25rem;
  padding-top: calc(1.5rem + env(safe-area-inset-top));
  padding-bottom: max(2rem, env(safe-area-inset-bottom));
}

.layout-grouped.has-header {
  padding-top: calc(6.5rem + env(safe-area-inset-top));
}

.categories-container {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
}

.category-section {
  animation: fadeIn 0.5s ease-out;
}

.category-title {
  font-size: 0.875rem;
  font-weight: 600;
  color: rgba(255, 255, 255, 0.6);
  text-transform: uppercase;
  letter-spacing: 0.05em;
  margin: 0 0 0.75rem 0;
  padding-bottom: 0.5rem;
  border-bottom: 1px solid rgba(255, 255, 255, 0.1);
}

.category-items {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.item-button {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  width: 100%;
  padding: 0.875rem 1rem;
  background: rgba(255, 255, 255, 0.08);
  backdrop-filter: blur(12px);
  -webkit-backdrop-filter: blur(12px);
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 0.75rem;
  color: white;
  text-align: left;
  cursor: pointer;
  transition: all 0.2s;
  -webkit-tap-highlight-color: transparent;
}

.item-button:active {
  background: rgba(255, 255, 255, 0.15);
  transform: scale(0.98);
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

.ai-section {
  margin-top: 1.5rem;
  width: 100%;
  max-width: 400px;
  margin-left: auto;
  margin-right: auto;
}
</style>

