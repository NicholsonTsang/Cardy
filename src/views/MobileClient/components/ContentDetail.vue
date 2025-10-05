<template>
  <div class="content-detail">
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
        <div 
          class="content-description"
          v-html="renderMarkdown(content.content_item_content)"
        ></div>
        
        <!-- AI Assistant Button -->
        <div v-if="card.conversation_ai_enabled" class="ai-section">
          <MobileAIAssistant 
            :content-item-name="content.content_item_name"
            :content-item-content="content.content_item_content"
            :content-item-knowledge-base="content.content_item_ai_knowledge_base || ''"
            :parent-content-knowledge-base="parentKnowledgeBase"
            :card-data="card"
          />
        </div>
      </div>
    </div>

    <!-- Sub Items -->
    <div v-if="subItems.length > 0" class="sub-items">
      <h3 class="sub-items-title">Related Content</h3>
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
            
            <div class="sub-item-footer">
              <span class="explore-hint">
                <i class="pi pi-arrow-right" />
                Tap to explore
              </span>
              <span v-if="card.conversation_ai_enabled" class="ai-hint">
                <i class="pi pi-microphone" />
                AI
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { onMounted, computed } from 'vue'
import MobileAIAssistant from './MobileAIAssistant.vue'
import { getContentAspectRatio } from '@/utils/cardConfig'
import { marked } from 'marked'

interface ContentItem {
  content_item_id: string
  content_item_parent_id: string | null
  content_item_name: string
  content_item_content: string
  content_item_image_url: string
  content_item_ai_knowledge_base: string
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

// Markdown rendering helper
function renderMarkdown(text: string): string {
  if (!text) return ''
  return marked(text)
}

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
  padding: 5rem 1rem 2rem;
  min-height: 100vh;
}

/* Main Content */
.main-content {
  margin-bottom: 2rem;
}

/* Hero Image */
.hero-image {
  aspect-ratio: var(--content-aspect-ratio, 4/3);
  overflow: hidden;
  margin-bottom: 1rem;
  background-color: white;
  position: relative;
  border-bottom: 1px solid rgba(255, 255, 255, 0.15);
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
  backdrop-filter: blur(8px);
  -webkit-backdrop-filter: blur(8px);
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 1rem;
  padding: 1rem;
}

.content-title {
  font-size: 1.25rem;
  font-weight: bold;
  color: white;
  margin: 0;
  margin-bottom: 1rem;
  word-break: break-word;
}

.content-description {
  font-size: 0.875rem;
  color: rgba(255, 255, 255, 0.9);
  line-height: 1.6;
  margin: 0;
  margin-bottom: 1rem;
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
}

.ai-section {
  margin-top: 1rem;
}

/* Sub Items */
.sub-items {
  margin-top: 2rem;
}

.sub-items-title {
  font-size: 1.125rem;
  font-weight: 600;
  color: white;
  margin: 0;
  margin-bottom: 1rem;
}

.sub-items-list {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}

/* Sub Item Card */
.sub-item-card {
  display: flex;
  gap: 0.75rem;
  background: rgba(255, 255, 255, 0.05);
  backdrop-filter: blur(8px);
  -webkit-backdrop-filter: blur(8px);
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 0.75rem;
  padding: 0.75rem;
  cursor: pointer;
  transition: all 0.2s;
}

.sub-item-card:active {
  transform: scale(0.98);
  background: rgba(255, 255, 255, 0.1);
}

/* Sub Item Image */
.sub-item-image {
  width: 4.5rem;
  height: 4.5rem;
  flex-shrink: 0;
  border-radius: 0.5rem;
  overflow: hidden;
  background-color: black;
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
}

.sub-item-title {
  font-size: 0.875rem;
  font-weight: 600;
  color: white;
  margin: 0;
  margin-bottom: 0.25rem;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.sub-item-description {
  font-size: 0.75rem;
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

.sub-item-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 0.625rem;
}

.explore-hint {
  display: flex;
  align-items: center;
  gap: 0.25rem;
  color: rgba(255, 255, 255, 0.5);
}

.ai-hint {
  display: flex;
  align-items: center;
  gap: 0.25rem;
  color: #60a5fa;
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