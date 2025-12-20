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
          <!-- Display the already-cropped image_url directly from API -->
          <img
            v-if="item.content_item_image_url"
            :src="item.content_item_image_url"
            :alt="item.content_item_name"
            class="image"
            crossorigin="anonymous"
          />
          <div v-else class="image-placeholder">
            <i class="pi pi-image" />
          </div>
          
          <!-- Sub-items Badge -->
          <div v-if="getSubItemsCount(item) > 0" class="badge">
            {{ getSubItemsCount(item) }} {{ $t('mobile.items') }}
          </div>
        </div>

        <!-- Content -->
        <div class="card-content">
          <h3 class="item-title">{{ item.content_item_name }}</h3>
          <p class="item-description">{{ item.content_item_content }}</p>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { onMounted } from 'vue'
import { useI18n } from 'vue-i18n'
import { getContentAspectRatio } from '@/utils/cardConfig'

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
  /* Fill parent flex container */
  flex: 1;
  display: flex;
  flex-direction: column;
  min-height: 0; /* Allow flex shrinking */
  padding-top: calc(5rem + env(safe-area-inset-top)); /* Account for header + notch */
  padding-left: max(1.25rem, env(safe-area-inset-left));
  padding-right: max(1.25rem, env(safe-area-inset-right));
  padding-bottom: max(2rem, env(safe-area-inset-bottom));
  -webkit-text-size-adjust: 100%; /* Prevent text scaling */
  /* Extend background to fill container when content is short */
  background: transparent;
}

.content-grid {
  display: flex;
  flex-direction: column;
  gap: 1.25rem;
}

/* Content Card */
.content-card {
  background: rgba(255, 255, 255, 0.1);
  backdrop-filter: blur(12px);
  -webkit-backdrop-filter: blur(12px);
  border: 1px solid rgba(255, 255, 255, 0.2);
  border-radius: 1.25rem;
  overflow: hidden;
  cursor: pointer;
  transition: all 0.2s;
  touch-action: manipulation; /* Disable double-tap zoom */
  -webkit-tap-highlight-color: transparent;
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
  background-color: white;
  border-bottom: 1px solid rgba(255, 255, 255, 0.1);
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
  top: 1rem;
  right: 1rem;
  background: rgba(59, 130, 246, 0.9);
  backdrop-filter: blur(8px);
  padding: 0.375rem 0.875rem;
  border-radius: 9999px;
  font-size: 0.75rem;
  color: white;
  font-weight: 600;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.2);
}

/* Card Content */
.card-content {
  padding: 1.25rem;
}

.item-title {
  font-size: 1.125rem;
  font-weight: 700;
  color: white;
  margin: 0;
  margin-bottom: 0.5rem;
  overflow: hidden;
  text-overflow: ellipsis;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  word-break: break-word;
  line-height: 1.3;
}

.item-description {
  font-size: 0.9375rem; /* 15px */
  color: rgba(255, 255, 255, 0.8);
  margin: 0;
  margin-bottom: 1rem;
  overflow: hidden;
  text-overflow: ellipsis;
  display: -webkit-box;
  -webkit-line-clamp: 3;
  -webkit-box-orient: vertical;
  line-height: 1.5;
  word-break: break-word;
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