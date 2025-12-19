<template>
  <div class="content-detail" :class="{ 'has-ai': card.conversation_ai_enabled }">
    <!-- Main Content -->
    <div class="main-content">
      <!-- Hero Image -->
      <div class="hero-image">
        <!-- Display the already-cropped image_url directly from API -->
        <img
          v-if="content.content_item_image_url"
          :src="content.content_item_image_url"
          :alt="content.content_item_name"
          class="image"
          crossorigin="anonymous"
        />
        <div v-else class="image-placeholder">
          <i class="pi pi-image" />
        </div>
      </div>

      <!-- Content Info -->
      <div class="content-info">
        <h2 class="content-title">{{ content.content_item_name }}</h2>
        
        <!-- Description - show full content -->
        <div 
          class="content-description"
          v-html="renderMarkdown(content.content_item_content || '')"
        ></div>
      </div>
    </div>

    <!-- Sub Items -->
    <div v-if="subItems.length > 0" class="sub-items">
      <h3 class="sub-items-title">{{ $t('mobile.related_content') }}</h3>
      <div class="sub-items-list">
        <div 
          v-for="subItem in subItems" 
          :key="subItem.content_item_id"
          @click="handleSelect(subItem)"
          class="sub-item-card"
        >
          <!-- Thumbnail -->
          <div class="sub-item-image">
            <!-- Display the already-cropped image_url directly from API -->
            <img
              v-if="subItem.content_item_image_url"
              :src="subItem.content_item_image_url"
              :alt="subItem.content_item_name"
              class="thumbnail"
              crossorigin="anonymous"
            />
            <div v-else class="thumbnail-placeholder">
              <i class="pi pi-file" />
            </div>
          </div>
          
          <!-- Info -->
          <div class="sub-item-info">
            <h4 class="sub-item-title">{{ subItem.content_item_name }}</h4>
            <p class="sub-item-description">{{ subItem.content_item_content }}</p>
          </div>
        </div>
      </div>
    </div>
    
    <!-- Note: Card-Level Assistant is NOT shown on ContentDetail page 
         because the contextual "Ask about this item" button is more relevant here.
         Users can access general assistant from Card Overview or Content List pages. -->
    
    <!-- Fixed AI Assistant at bottom - Content Item Mode -->
    <div v-if="card.conversation_ai_enabled" class="ai-section-fixed">
      <MobileAIAssistant 
        :content-item-name="content.content_item_name"
        :content-item-content="content.content_item_content || ''"
        :content-item-knowledge-base="content.content_item_ai_knowledge_base || ''"
        :parent-content-name="parentItem?.content_item_name"
        :parent-content-description="parentItem?.content_item_content"
        :parent-content-knowledge-base="parentKnowledgeBase"
        :card-data="cardDataForAssistant"
      />
    </div>
  </div>
</template>

<script setup lang="ts">
import { onMounted, computed } from 'vue'
import { useI18n } from 'vue-i18n'
import { MobileAIAssistant } from './AIAssistant'
import { getContentAspectRatio } from '@/utils/cardConfig'
import { renderMarkdown } from '@/utils/markdownRenderer'

const { t } = useI18n()


interface ContentItem {
  content_item_id: string
  content_item_parent_id: string | null
  content_item_name: string
  content_item_content?: string       // Full content (optional for optimized loading)
  content_preview?: string            // Truncated preview (optimized)
  content_length?: number             // Full content length (optimized)
  content_item_image_url: string
  content_item_ai_knowledge_base?: string
  content_item_ai_metadata?: string
  content_item_sort_order: number
  crop_parameters?: any
}

interface CardData {
  card_name: string
  card_description: string
  card_image_url: string
  conversation_ai_enabled: boolean
  ai_instruction: string
  ai_knowledge_base: string
  is_activated: boolean
}

interface Props {
  content: ContentItem
  subItems: ContentItem[]
  card: CardData
  parentItem?: ContentItem | null // For sub-items, this is the parent content item
}

const props = defineProps<Props>()

// Compute parent knowledge base (empty if this is a top-level item)
const parentKnowledgeBase = computed(() => {
  return props.parentItem?.content_item_ai_knowledge_base || ''
})
const emit = defineEmits<{
  select: [item: ContentItem]
}>()

// Prepare card data for AI Assistant (matching CardData interface)
const cardDataForAssistant = computed(() => ({
  card_name: props.card.card_name,
  card_description: props.card.card_description,
  card_image_url: props.card.card_image_url,
  conversation_ai_enabled: props.card.conversation_ai_enabled,
  ai_instruction: props.card.ai_instruction,
  ai_knowledge_base: props.card.ai_knowledge_base,
  is_activated: props.card.is_activated
}))

function handleSelect(item: ContentItem) {
  emit('select', item)
}

// Set up CSS custom property for content aspect ratio
onMounted(() => {
  const aspectRatio = getContentAspectRatio()
  document.documentElement.style.setProperty('--content-aspect-ratio', aspectRatio)
})
</script>

<style scoped>
.content-detail {
  padding-top: calc(5rem + env(safe-area-inset-top)); /* Account for header + notch */
  padding-left: max(1.25rem, env(safe-area-inset-left));
  padding-right: max(1.25rem, env(safe-area-inset-right));
  padding-bottom: max(2rem, env(safe-area-inset-bottom));
  min-height: 100vh;
  min-height: var(--viewport-height, 100vh); /* Dynamic viewport */
  min-height: 100dvh;
  -webkit-text-size-adjust: 100%; /* Prevent text scaling */
}

/* Extra bottom padding when AI assistant is present (fixed at bottom) */
.content-detail.has-ai {
  padding-bottom: calc(5rem + max(1rem, env(safe-area-inset-bottom)));
}

/* Main Content */
.main-content {
  margin-bottom: 2rem;
}

/* Hero Image */
.hero-image {
  aspect-ratio: var(--content-aspect-ratio, 4/3);
  overflow: hidden;
  margin-top: 1rem; /* Breathing room from header */
  margin-bottom: 1.25rem;
  background-color: white;
  position: relative;
  border-bottom: 1px solid rgba(255, 255, 255, 0.15);
  border-radius: 1.25rem; /* Match glass morphism design */
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
}

.image {
  width: 100%;
  height: 100%;
  object-fit: contain;
}

.image-placeholder {
  width: 100%;
  height: 100%;
  background: linear-gradient(135deg, rgba(59, 130, 246, 0.2), rgba(147, 51, 234, 0.2));
  display: flex;
  align-items: center;
  justify-content: center;
  color: rgba(255, 255, 255, 0.4);
  font-size: 3rem;
}

/* Content Info */
.content-info {
  background: rgba(255, 255, 255, 0.05);
  backdrop-filter: blur(12px);
  -webkit-backdrop-filter: blur(12px);
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 1.25rem;
  padding: 1.25rem;
}

.content-title {
  font-size: 1.5rem;
  font-weight: 800;
  color: white;
  margin: 0;
  margin-bottom: 1rem;
  word-break: break-word;
  line-height: 1.2;
}

.content-description {
  font-size: 1rem; /* 16px base */
  color: rgba(255, 255, 255, 0.9);
  line-height: 1.7;
  margin: 0;
  word-break: break-word;
}

.content-description :deep(p) {
  margin: 0 0 0.5rem 0;
}

.content-description :deep(h1),
.content-description :deep(h2),
.content-description :deep(h3),
.content-description :deep(h4) {
  color: white;
  margin: 0.75rem 0 0.5rem 0;
}

.content-description :deep(ul),
.content-description :deep(ol) {
  margin: 0.5rem 0;
  padding-left: 1.5rem;
}

.content-description :deep(a) {
  color: #60a5fa;
  text-decoration: underline;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
  text-overflow: ellipsis;
  word-break: break-word;
}

/* Fixed AI Section at bottom */
.ai-section-fixed {
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

/* Sub Items */
.sub-items {
  margin-top: 2.5rem;
}

.sub-items-title {
  font-size: 1rem;
  font-weight: 700;
  color: rgba(255, 255, 255, 0.9);
  margin: 0;
  margin-bottom: 1rem;
  padding-left: 0.5rem;
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.sub-items-title::before {
  content: '';
  width: 4px;
  height: 18px;
  background: linear-gradient(to bottom, #3b82f6, #8b5cf6);
  border-radius: 2px;
}

.sub-items-list {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}

/* Sub Item Card */
.sub-item-card {
  display: flex;
  gap: 0.875rem;
  background: rgba(255, 255, 255, 0.06);
  backdrop-filter: blur(12px);
  -webkit-backdrop-filter: blur(12px);
  border: 1px solid rgba(255, 255, 255, 0.08);
  border-radius: 1rem;
  padding: 1rem;
  cursor: pointer;
  transition: all 0.25s cubic-bezier(0.4, 0, 0.2, 1);
  min-height: 52px; /* Increased touch target */
  touch-action: manipulation; /* Disable double-tap zoom */
  -webkit-tap-highlight-color: transparent;
  position: relative;
  overflow: hidden;
}

.sub-item-card::before {
  content: '';
  position: absolute;
  inset: 0;
  background: linear-gradient(135deg, rgba(59, 130, 246, 0.1), rgba(147, 51, 234, 0.05));
  opacity: 0;
  transition: opacity 0.25s;
}

.sub-item-card:active {
  transform: scale(0.98);
  background: rgba(255, 255, 255, 0.1);
  border-color: rgba(255, 255, 255, 0.15);
}

.sub-item-card:active::before {
  opacity: 1;
}

/* Sub Item Image */
.sub-item-image {
  width: 5rem;
  height: 5rem;
  flex-shrink: 0;
  border-radius: 0.75rem;
  overflow: hidden;
  background-color: black;
  border: 1px solid rgba(255, 255, 255, 0.1);
}

.thumbnail {
  width: 100%;
  height: 100%;
  object-fit: contain;
}

.thumbnail-placeholder {
  width: 100%;
  height: 100%;
  background: rgba(255, 255, 255, 0.1);
  display: flex;
  align-items: center;
  justify-content: center;
  color: rgba(255, 255, 255, 0.4);
}

/* Sub Item Info */
.sub-item-info {
  flex: 1;
  min-width: 0;
  display: flex;
  flex-direction: column;
  justify-content: center;
}

.sub-item-title {
  font-size: 1rem; /* 16px */
  font-weight: 600;
  color: white;
  margin: 0;
  margin-bottom: 0.375rem;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.sub-item-description {
  font-size: 0.875rem; /* 14px */
  color: rgba(255, 255, 255, 0.7);
  margin: 0;
  margin-bottom: 0.5rem;
  overflow: hidden;
  text-overflow: ellipsis;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  line-height: 1.4;
}


/* Responsive */
@media (min-width: 640px) {
  .content-title {
    font-size: 1.5rem;
  }
  
  .content-description {
    font-size: 1rem;
  }
  
  .sub-items-title {
    font-size: 1.25rem;
  }
}
</style>