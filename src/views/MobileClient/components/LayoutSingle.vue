<template>
  <div class="layout-single" :class="{ 'has-header': hasHeader }">
    <!-- Single Content Item - Full Page Display -->
    <div v-if="item" class="single-content">
      <!-- Image (if exists) -->
      <div v-if="item.content_item_image_url" class="content-image">
        <img
          :src="item.content_item_image_url"
          :alt="item.content_item_name"
          crossorigin="anonymous"
        />
      </div>
      
      <!-- Title -->
      <h1 class="content-title">{{ item.content_item_name }}</h1>
      
      <!-- Content/Description -->
      <div 
        v-if="item.content_item_content" 
        class="content-body markdown-content"
        v-html="renderedContent"
      ></div>
    </div>

    <!-- Empty State -->
    <div v-else class="empty-state">
      <i class="pi pi-file" />
      <p>{{ $t('mobile.no_content') }}</p>
    </div>

    <!-- AI Assistant (if enabled) -->
    <div v-if="card.conversation_ai_enabled" class="ai-section">
      <MobileAIAssistant 
        :content-item-name="item?.content_item_name || card.card_name"
        :content-item-content="item?.content_item_content || ''"
        :content-item-knowledge-base="item?.content_item_ai_knowledge_base || ''"
        :parent-content-knowledge-base="card.ai_knowledge_base || ''"
        :card-data="card"
      />
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { useI18n } from 'vue-i18n'
import { renderMarkdown } from '@/utils/markdownRenderer'
import { MobileAIAssistant } from './AIAssistant'

const { t } = useI18n()

interface ContentItem {
  content_item_id: string
  content_item_name: string
  content_item_content: string
  content_item_image_url: string
  content_item_ai_knowledge_base: string
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
  item: ContentItem | null
  availableLanguages?: string[]
  hasHeader?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  hasHeader: false
})

// Render markdown content
const renderedContent = computed(() => {
  if (!props.item?.content_item_content) return ''
  return renderMarkdown(props.item.content_item_content)
})
</script>

<style scoped>
.layout-single {
  min-height: 100vh;
  min-height: 100dvh;
  display: flex;
  flex-direction: column;
  padding: 1.5rem 1.25rem;
  padding-top: calc(1.5rem + env(safe-area-inset-top));
  padding-bottom: max(2rem, env(safe-area-inset-bottom));
}

.layout-single.has-header {
  padding-top: calc(6.5rem + env(safe-area-inset-top));
}

.single-content {
  flex: 1;
  animation: fadeIn 0.5s ease-out;
}

@keyframes fadeIn {
  from { opacity: 0; transform: translateY(10px); }
  to { opacity: 1; transform: translateY(0); }
}

.content-image {
  width: 100%;
  max-height: 300px;
  border-radius: 1rem;
  overflow: hidden;
  margin-bottom: 1.5rem;
}

.content-image img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.content-title {
  font-size: 1.5rem;
  font-weight: 700;
  color: white;
  margin: 0 0 1rem 0;
  line-height: 1.3;
}

.content-body {
  font-size: 1rem;
  color: rgba(255, 255, 255, 0.85);
  line-height: 1.7;
}

.content-body :deep(p) {
  margin-bottom: 1rem;
}

.content-body :deep(a) {
  color: #60a5fa;
  text-decoration: underline;
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
  margin-top: 2rem;
  width: 100%;
  max-width: 400px;
  margin-left: auto;
  margin-right: auto;
}
</style>

