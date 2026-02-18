<template>
  <div class="content-list" role="main" :aria-label="t('mobile.explore_content')">
    <div class="content-grid" role="list">
      <div
        v-for="item in items"
        :key="item.content_item_id"
        role="listitem"
        class="content-card"
        :class="{ 'no-image': !item.content_item_image_url }"
        :aria-label="item.content_item_name"
      >
        <!-- Image (only shown if exists) -->
        <div
          v-if="item.content_item_image_url"
          class="card-image"
          @click="handleSelect(item)"
        >
          <img
            :src="item.content_item_image_url"
            :alt="item.content_item_name"
            class="image"
            crossorigin="anonymous"
          />

          <!-- Sub-items Badge -->
          <div v-if="getSubItemsCount(item) > 0" class="badge">
            {{ getSubItemsCount(item) }} {{ $t('mobile.items') }}
          </div>
        </div>

        <!-- Content -->
        <div class="card-content" @click="handleSelect(item)">
          <!-- Sub-items Badge for no-image cards -->
          <div v-if="!item.content_item_image_url && getSubItemsCount(item) > 0" class="badge-inline">
            {{ getSubItemsCount(item) }} {{ $t('mobile.items') }}
          </div>
          <h3 class="item-title">{{ item.content_item_name }}</h3>
          <p class="item-description">{{ item.content_item_content }}</p>
        </div>

        <!-- Card Actions -->
        <div class="card-actions" role="toolbar" :aria-label="t('common.actions')">
          <button
            class="card-action-btn"
            :aria-label="isFavorite(item.content_item_id) ? t('mobile.removeFromFavorites') : t('mobile.addToFavorites')"
            @click.stop="toggleFavorite(item.content_item_id)"
          >
            <i :class="isFavorite(item.content_item_id) ? 'pi pi-heart-fill' : 'pi pi-heart'" />
          </button>
          <button
            class="card-action-btn"
            :aria-label="t('mobile.share')"
            :disabled="isSharing"
            @click.stop="handleShareItem(item)"
          >
            <i class="pi pi-share-alt" />
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { onMounted, computed } from 'vue'
import { useRoute } from 'vue-router'
import { useI18n } from 'vue-i18n'
import { getContentAspectRatio } from '@/utils/cardConfig'
import { useShare } from '@/composables/useShare'
import { useFavorites } from '@/composables/useFavorites'

const { t } = useI18n()
const route = useRoute()

// Share composable
const { share, buildContentShareData, isSharing } = useShare()

// Favorites composable
const cardId = computed(() => route.params.card_id as string)
const { isFavorite, toggleFavorite } = useFavorites({ cardId: cardId.value })

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

function handleShareItem(item: ContentItem) {
  const lang = route.params.lang as string
  const shareData = buildContentShareData(
    cardId.value,
    item.content_item_id,
    item.content_item_name,
    item.content_item_content || null,
    lang
  )
  share(shareData)
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
  background: var(--theme-surface, rgba(255, 255, 255, 0.07));
  backdrop-filter: blur(12px);
  -webkit-backdrop-filter: blur(12px);
  border: 1px solid rgba(var(--theme-text-rgb), 0.15);
  border-radius: 1.25rem;
  overflow: hidden;
  cursor: pointer;
  transition: all 0.2s;
  touch-action: manipulation; /* Disable double-tap zoom */
  -webkit-tap-highlight-color: transparent;
}

.content-card:active {
  transform: scale(0.98);
  background: rgba(var(--theme-text-rgb), 0.14);
}

/* Card Image */
.card-image {
  position: relative;
  aspect-ratio: var(--content-aspect-ratio, 4/3);
  overflow: hidden;
  background-color: var(--theme-surface, rgba(255, 255, 255, 0.07));
  border-bottom: 1px solid rgba(var(--theme-text-rgb), 0.1);
}

.image {
  width: 100%;
  height: 100%;
  object-fit: contain;
}

.badge {
  position: absolute;
  top: 1rem;
  right: 1rem;
  background: rgba(var(--theme-primary-rgb, 99, 102, 241), 0.9);
  backdrop-filter: blur(8px);
  padding: 0.375rem 0.875rem;
  border-radius: 9999px;
  font-size: 0.75rem;
  color: rgba(var(--theme-text-rgb), 1);
  font-weight: 600;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.2);
}

/* Inline badge for cards without images */
.badge-inline {
  display: inline-block;
  background: rgba(var(--theme-primary-rgb, 99, 102, 241), 0.2);
  border: 1px solid rgba(var(--theme-primary-rgb, 99, 102, 241), 0.4);
  padding: 0.25rem 0.625rem;
  border-radius: 9999px;
  font-size: 0.6875rem;
  color: rgba(var(--theme-text-rgb), 0.9);
  font-weight: 600;
  margin-bottom: 0.5rem;
}

/* No-image card state - increase content padding */
.content-card.no-image .card-content {
  padding: 1.5rem 1.25rem;
}

/* Card Content */
.card-content {
  padding: 1.25rem;
}

.item-title {
  font-size: 1.125rem;
  font-weight: 700;
  color: var(--theme-text, #ffffff);
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
  color: rgba(var(--theme-text-rgb), 0.8);
  margin: 0;
  overflow: hidden;
  text-overflow: ellipsis;
  display: -webkit-box;
  -webkit-line-clamp: 3;
  -webkit-box-orient: vertical;
  line-height: 1.5;
  word-break: break-word;
}

/* Card Actions */
.card-actions {
  display: flex;
  gap: 0.25rem;
  padding: 0 1.25rem 1rem;
  justify-content: flex-end;
}

.card-action-btn {
  width: 2.25rem;
  height: 2.25rem;
  min-width: 44px;
  min-height: 44px;
  border-radius: 50%;
  background: rgba(var(--theme-text-rgb), 0.08);
  border: 1px solid rgba(var(--theme-text-rgb), 0.1);
  color: rgba(var(--theme-text-rgb), 0.7);
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: all 0.2s ease;
  -webkit-tap-highlight-color: transparent;
  touch-action: manipulation;
}

.card-action-btn:active {
  transform: scale(0.9);
  background: rgba(var(--theme-text-rgb), 0.15);
}

.card-action-btn:focus-visible {
  outline: 2px solid var(--theme-primary, #6366f1);
  outline-offset: 2px;
}

.card-action-btn i {
  font-size: 1rem;
}

/* Filled heart state */
.card-action-btn .pi-heart-fill {
  color: #f87171;
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