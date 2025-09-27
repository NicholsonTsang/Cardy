<template>
  <div class="content-list">
    <div class="content-grid">
      <div 
        v-for="item in items" 
        :key="item.content_item_id"
        @click="handleSelect(item)"
        class="content-card"
      >
        <!-- Image -->
        <div class="card-image">
          <img 
            v-if="item.content_item_image_url"
            :src="item.content_item_image_url" 
            :alt="item.content_item_name"
            class="image"
          />
          <div v-else class="image-placeholder">
            <i class="pi pi-image" />
          </div>
          
          <!-- Sub-items Badge -->
          <div v-if="getSubItemsCount(item) > 0" class="badge">
            {{ getSubItemsCount(item) }} items
          </div>
        </div>

        <!-- Content -->
        <div class="card-content">
          <h3 class="item-title">{{ item.content_item_name }}</h3>
          <p class="item-description">{{ item.content_item_content }}</p>
          
          <div class="card-footer">
            <span class="explore-hint">
              <i class="pi pi-arrow-right" />
              Tap to explore
            </span>
            <span v-if="cardAiEnabled" class="ai-badge">
              <i class="pi pi-microphone" />
              AI Chat
            </span>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { onMounted } from 'vue'
import { getContentAspectRatio } from '@/utils/cardConfig'

interface ContentItem {
  content_item_id: string
  content_item_parent_id: string | null
  content_item_name: string
  content_item_content: string
  content_item_image_url: string
  content_item_ai_metadata: string
  content_item_sort_order: number
}

interface Props {
  items: ContentItem[]
  cardAiEnabled: boolean
  allItems?: ContentItem[]
}

const props = defineProps<Props>()
const emit = defineEmits<{
  select: [item: ContentItem]
}>()

function getSubItemsCount(item: ContentItem): number {
  if (!props.allItems) return 0
  return props.allItems.filter(
    subItem => subItem.content_item_parent_id === item.content_item_id
  ).length
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
.content-list {
  padding: 5rem 1rem 2rem;
  min-height: 100vh;
}

.content-grid {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

/* Content Card */
.content-card {
  background: rgba(255, 255, 255, 0.1);
  backdrop-filter: blur(8px);
  -webkit-backdrop-filter: blur(8px);
  border: 1px solid rgba(255, 255, 255, 0.2);
  border-radius: 1rem;
  overflow: hidden;
  cursor: pointer;
  transition: all 0.2s;
}

.content-card:active {
  transform: scale(0.98);
  background: rgba(255, 255, 255, 0.15);
}

/* Card Image */
.card-image {
  position: relative;
  aspect-ratio: var(--content-aspect-ratio, 4/3);
  overflow: hidden;
  background-color: black;
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
  font-size: 2rem;
}

.badge {
  position: absolute;
  top: 0.75rem;
  right: 0.75rem;
  background: rgba(59, 130, 246, 0.8);
  backdrop-filter: blur(4px);
  padding: 0.25rem 0.75rem;
  border-radius: 9999px;
  font-size: 0.75rem;
  color: white;
  font-weight: 500;
}

/* Card Content */
.card-content {
  padding: 1rem;
}

.item-title {
  font-size: 1rem;
  font-weight: 600;
  color: white;
  margin: 0;
  margin-bottom: 0.5rem;
  overflow: hidden;
  text-overflow: ellipsis;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  word-break: break-word;
}

.item-description {
  font-size: 0.875rem;
  color: rgba(255, 255, 255, 0.7);
  margin: 0;
  margin-bottom: 0.75rem;
  overflow: hidden;
  text-overflow: ellipsis;
  display: -webkit-box;
  -webkit-line-clamp: 3;
  -webkit-box-orient: vertical;
  line-height: 1.5;
  word-break: break-word;
}

/* Card Footer */
.card-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 0.75rem;
}

.explore-hint {
  display: flex;
  align-items: center;
  gap: 0.25rem;
  color: rgba(255, 255, 255, 0.5);
}

.ai-badge {
  display: flex;
  align-items: center;
  gap: 0.25rem;
  color: #60a5fa;
}

/* Responsive */
@media (min-width: 640px) {
  .content-list {
    padding: 5rem 1.5rem 2rem;
  }
  
  .content-grid {
    gap: 1.5rem;
  }
  
  .item-title {
    font-size: 1.125rem;
  }
}
</style>