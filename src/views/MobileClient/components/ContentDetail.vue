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
            
            <div class="sub-item-footer">
              <span class="explore-hint">
                <i class="pi pi-arrow-right" />
                {{ $t('mobile.tap_to_explore') }}
              </span>
              <span v-if="card.conversation_ai_enabled" class="ai-hint">
                <i class="pi pi-microphone" />
                {{ $t('mobile.ai') }}
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
import { useI18n } from 'vue-i18n'
import { MobileAIAssistant } from './AIAssistant'
import { getContentAspectRatio } from '@/utils/cardConfig'
import { renderMarkdown } from '@/utils/markdownRenderer'

const { t } = useI18n()

interface ContentItem {
  content_item_id: string
  content_item_parent_id: string | null
  content_item_name: string
  content_item_content: string
  content_item_image_url: string
  content_item_ai_knowledge_base: string
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
  line-height: 1.6;
  margin: 0;
  margin-bottom: 1.25rem;
  word-break: break-word;
  
  /* Scrollable container with max height */
  max-height: 45vh; /* 45% of viewport - good balance for content visibility */
  max-height: calc(var(--viewport-height, 100vh) * 0.45); /* Use dynamic viewport if available */
  overflow-y: auto;
  overflow-x: hidden;
  
  /* Smooth scrolling with momentum on iOS */
  -webkit-overflow-scrolling: touch;
  overscroll-behavior-y: contain; /* Prevent overscroll bounce affecting parent */
  
  /* Consistent styling with CardOverview and ContentList */
  padding: 1rem;
  padding-bottom: 1.25rem; /* Optimized bottom padding */
  background: rgba(255, 255, 255, 0.1); /* Match other mobile components */
  backdrop-filter: blur(8px); /* Glass morphism effect like other components */
  -webkit-backdrop-filter: blur(8px);
  border: 1px solid rgba(255, 255, 255, 0.2); /* Match ContentList border */
  border-radius: 1rem; /* Match ContentList radius */
  
  /* Scroll indicator shadow - shows there's more content below */
  position: relative;
}

/* Fade indicator at bottom when content is scrollable */
.content-description::after {
  content: '';
  position: sticky;
  bottom: 0;
  left: 0;
  right: 0;
  height: 2rem;
  background: linear-gradient(
    to bottom, 
    transparent 0%, 
    rgba(30, 41, 59, 0.8) 60%,
    rgba(30, 41, 59, 0.95) 100%
  ); /* Darker gradient for better visibility with lighter background */
  pointer-events: none; /* Don't block scrolling */
  margin: 0 -1rem -2rem -1rem; /* Negate flow height to overlay */
  border-radius: 0 0 1rem 1rem; /* Match parent border-radius */
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

.ai-section {
  margin-top: 1rem;
}

/* Sub Items */
.sub-items {
  margin-top: 2.5rem;
}

.sub-items-title {
  font-size: 1.25rem;
  font-weight: 700;
  color: white;
  margin: 0;
  margin-bottom: 1rem;
  padding-left: 0.5rem;
}

.sub-items-list {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

/* Sub Item Card */
.sub-item-card {
  display: flex;
  gap: 1rem;
  background: rgba(255, 255, 255, 0.05);
  backdrop-filter: blur(12px);
  -webkit-backdrop-filter: blur(12px);
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 1rem;
  padding: 1rem;
  cursor: pointer;
  transition: all 0.2s;
  min-height: 52px; /* Increased touch target */
  touch-action: manipulation; /* Disable double-tap zoom */
  -webkit-tap-highlight-color: transparent;
}

.sub-item-card:active {
  transform: scale(0.98);
  background: rgba(255, 255, 255, 0.1);
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

.sub-item-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 0.75rem;
  margin-top: auto;
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