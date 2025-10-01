<template>
  <div class="card-overview">
    <!-- Background Image -->
    <div class="background-image">
      <!-- Display the already-cropped image_url directly from API -->
      <img
        v-if="card.card_image_url"
        :src="card.card_image_url"
        :alt="card.card_name"
        class="image"
      />
      <div class="gradient-overlay" />
    </div>
    
    <!-- Content -->
    <div class="content">
      <div class="card-info">
        <h1 class="card-title">{{ card.card_name }}</h1>
        
        <!-- Scrollable Description -->
        <div class="description-container">
          <p class="card-description">{{ card.card_description }}</p>
        </div>
        
        <!-- Activation Status -->
        <div class="status-badge" :class="card.is_activated ? 'active' : 'pending'">
          <i class="pi" :class="card.is_activated ? 'pi-check-circle' : 'pi-clock'" />
          <span>{{ card.is_activated ? 'Card Activated' : 'Just Activated' }}</span>
        </div>
      </div>

      <!-- Explore Button -->
      <button @click="handleExplore" class="explore-button">
        <i class="pi pi-compass" />
        <span>Explore Content</span>
      </button>
    </div>
  </div>
</template>

<script setup lang="ts">
interface Props {
  card: {
    card_name: string
    card_description: string
    card_image_url: string
    crop_parameters?: any
    conversation_ai_enabled: boolean
    ai_prompt: string
    is_activated: boolean
  }
}

defineProps<Props>()
const emit = defineEmits<{
  explore: []
}>()

function handleExplore() {
  emit('explore')
}
</script>

<style scoped>
.card-overview {
  position: relative;
  height: 100vh;
  height: 100dvh;
  display: flex;
  flex-direction: column;
}

/* Background */
.background-image {
  position: absolute;
  inset: 0;
  overflow: hidden;
}

.image {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.gradient-overlay {
  position: absolute;
  inset: 0;
  background: linear-gradient(
    to bottom,
    transparent 0%,
    rgba(0, 0, 0, 0.3) 50%,
    rgba(0, 0, 0, 0.8) 100%
  );
}

/* Content */
.content {
  position: relative;
  z-index: 10;
  flex: 1;
  display: flex;
  flex-direction: column;
  justify-content: flex-end;
  padding: 1.5rem;
  padding-bottom: 2rem;
}

.card-info {
  text-align: center;
  margin-bottom: 2rem;
}

.card-title {
  font-size: 1.75rem;
  font-weight: bold;
  color: white;
  margin: 0;
  margin-bottom: 1rem;
  line-height: 1.2;
}

/* Scrollable Description */
.description-container {
  max-height: 10rem;
  overflow-y: auto;
  margin-bottom: 1rem;
  padding: 0 0.5rem;
}

.card-description {
  font-size: 0.875rem;
  color: rgba(255, 255, 255, 0.9);
  line-height: 1.6;
  margin: 0;
  word-break: break-word;
  overflow-wrap: break-word;
}

/* Custom Scrollbar */
.description-container::-webkit-scrollbar {
  width: 4px;
}

.description-container::-webkit-scrollbar-track {
  background: rgba(255, 255, 255, 0.1);
  border-radius: 2px;
}

.description-container::-webkit-scrollbar-thumb {
  background: rgba(255, 255, 255, 0.3);
  border-radius: 2px;
}

/* Status Badge */
.status-badge {
  display: inline-flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.5rem 1rem;
  border-radius: 9999px;
  font-size: 0.75rem;
  font-weight: 500;
  border: 1px solid;
}

.status-badge.active {
  background: rgba(34, 197, 94, 0.2);
  border-color: rgba(34, 197, 94, 0.3);
  color: #86efac;
}

.status-badge.pending {
  background: rgba(251, 191, 36, 0.2);
  border-color: rgba(251, 191, 36, 0.3);
  color: #fde047;
}

/* Explore Button */
.explore-button {
  width: 100%;
  padding: 1rem;
  background: rgba(255, 255, 255, 0.1);
  backdrop-filter: blur(8px);
  -webkit-backdrop-filter: blur(8px);
  border: 1px solid rgba(255, 255, 255, 0.2);
  border-radius: 0.75rem;
  color: white;
  font-size: 1rem;
  font-weight: 600;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 0.5rem;
  transition: all 0.2s;
}

.explore-button:active {
  transform: scale(0.98);
  background: rgba(255, 255, 255, 0.2);
}

/* Responsive */
@media (min-width: 640px) {
  .card-title {
    font-size: 2rem;
  }
  
  .card-description {
    font-size: 1rem;
  }
  
  .description-container {
    max-height: 12rem;
  }
}
</style>