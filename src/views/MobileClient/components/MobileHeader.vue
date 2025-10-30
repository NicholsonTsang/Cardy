<template>
  <header class="mobile-header">
    <button @click="handleBack" class="back-button">
      <i class="pi pi-arrow-left" />
    </button>
    <div class="header-content">
      <h1 class="header-title">{{ title }}</h1>
      <p v-if="subtitle" class="header-subtitle">{{ subtitle }}</p>
    </div>
    <div class="language-controls">
      <ChineseVoiceSelector />
      <UnifiedLanguageModal 
        v-model="showLanguageModal"
        :show-trigger="true"
        :track-selection="false"
      />
    </div>
  </header>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import UnifiedLanguageModal from './UnifiedLanguageModal.vue'
import ChineseVoiceSelector from './ChineseVoiceSelector.vue'

interface Props {
  title: string
  subtitle?: string
}

defineProps<Props>()
const emit = defineEmits<{
  back: []
}>()

const showLanguageModal = ref(false)

function handleBack() {
  emit('back')
}
</script>

<style scoped>
.mobile-header {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  z-index: 50;
  background: rgba(0, 0, 0, 0.3);
  backdrop-filter: blur(12px);
  -webkit-backdrop-filter: blur(12px);
  border-bottom: 1px solid rgba(255, 255, 255, 0.1);
  padding: 1rem;
  padding-top: max(1rem, env(safe-area-inset-top)); /* Account for notch */
  display: flex;
  align-items: center;
  gap: 0.75rem;
  -webkit-text-size-adjust: 100%; /* Prevent text scaling */
}

.back-button {
  width: 2.5rem;
  height: 2.5rem;
  min-width: 44px; /* iOS recommended touch target */
  min-height: 44px;
  border-radius: 50%;
  background: rgba(255, 255, 255, 0.1);
  border: none;
  color: white;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.2s;
  flex-shrink: 0;
  touch-action: manipulation; /* Disable double-tap zoom */
  -webkit-tap-highlight-color: transparent;
}

.back-button:active {
  transform: scale(0.95);
  background: rgba(255, 255, 255, 0.2);
}

.header-content {
  flex: 1;
  min-width: 0;
}

.header-title {
  font-size: 1rem;
  font-weight: 600;
  color: white;
  margin: 0;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.header-subtitle {
  font-size: 14px; /* Slightly smaller but not triggering zoom (non-interactive) */
  color: rgba(255, 255, 255, 0.7);
  margin: 0;
  margin-top: 0.125rem;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.language-controls {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  flex-shrink: 0;
}
</style>