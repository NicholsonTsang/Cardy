<template>
  <div class="layout-list" :class="{ 'has-header': hasHeader }">
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
          <span v-if="item.content_item_content" class="item-preview">
            {{ truncateText(item.content_item_content, 60) }}
          </span>
        </div>
        <i class="pi pi-chevron-right item-arrow" />
      </button>
    </div>

    <!-- Empty State -->
    <div v-if="items.length === 0" class="empty-state">
      <i class="pi pi-list" />
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
  background: rgba(255, 255, 255, 0.1);
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.item-icon i {
  font-size: 1.25rem;
  color: rgba(255, 255, 255, 0.7);
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

.ai-section {
  margin-top: 1.5rem;
  width: 100%;
  max-width: 400px;
  margin-left: auto;
  margin-right: auto;
}
</style>

