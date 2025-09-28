<template>
  <div class="content-detail">
    <!-- Main Content -->
    <div class="main-content">
      <!-- Hero Image -->
      <div class="hero-image">
        <CroppedImageDisplay
          v-if="content.content_item_image_url"
          :imageSrc="content.content_item_image_url"
          :cropParameters="content.crop_parameters"
          :alt="content.content_item_name"
          imageClass="image"
          :previewSize="400"
        />
        <div v-else class="image-placeholder">
          <i class="pi pi-image" />
        </div>
      </div>

      <!-- Content Info -->
      <div class="content-info">
        <h2 class="content-title">{{ content.content_item_name }}</h2>
        <p class="content-description">{{ content.content_item_content }}</p>
        
        <!-- AI Assistant Button -->
        <div v-if="card.conversation_ai_enabled" class="ai-section">
          <MobileAIAssistant 
            :content-item-name="content.content_item_name"
            :content-item-content="content.content_item_content"
            :ai-metadata="content.content_item_ai_metadata || ''"
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
            <CroppedImageDisplay
              v-if="subItem.content_item_image_url"
              :imageSrc="subItem.content_item_image_url"
              :cropParameters="subItem.crop_parameters"
              :alt="subItem.content_item_name"
              imageClass="thumbnail"
              :previewSize="120"
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
import { onMounted } from 'vue'
import MobileAIAssistant from './MobileAIAssistant.vue'
import CroppedImageDisplay from '@/components/CroppedImageDisplay.vue'
import { getContentAspectRatio } from '@/utils/cardConfig'

interface ContentItem {
  content_item_id: string
  content_item_parent_id: string | null
  content_item_name: string
  content_item_content: string
  content_item_image_url: string
  content_item_ai_metadata: string
  content_item_sort_order: number
  crop_parameters?: any
}

interface CardData {
  card_name: string
  card_description: string
  card_image_url: string
  conversation_ai_enabled: boolean
  ai_prompt: string
  is_activated: boolean
}

interface Props {
  content: ContentItem
  subItems: ContentItem[]
  card: CardData
}

defineProps<Props>()
const emit = defineEmits<{
  select: [item: ContentItem]
}>()

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
  padding-top: 5rem;
  padding-bottom: 2rem;
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
  margin-bottom: 1.5rem;
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
  padding: 0 1.5rem;
  background: rgba(255, 255, 255, 0.05);
  backdrop-filter: blur(8px);
  -webkit-backdrop-filter: blur(8px);
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 1rem;
  padding: 1.5rem;
  margin: 0 1rem;
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
  white-space: pre-wrap;
  word-break: break-word;
}

.ai-section {
  margin-top: 1rem;
}

/* Sub Items */
.sub-items {
  padding: 0 1rem;
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