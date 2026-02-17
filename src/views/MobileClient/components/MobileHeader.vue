<template>
  <header class="mobile-header" role="banner">
    <!-- Back Button (optional) -->
    <button
      v-if="showBackButton"
      @click="handleBack"
      class="back-button"
      :aria-label="$t('common.back')"
    >
      <i class="pi pi-arrow-left" aria-hidden="true" />
    </button>
    <!-- Spacer when no back button to maintain layout -->
    <div v-else class="back-button-spacer" aria-hidden="true"></div>

    <div class="header-content">
      <h1 class="header-title">{{ title }}</h1>
      <p v-if="subtitle" class="header-subtitle">{{ subtitle }}</p>
    </div>
    <div class="language-controls" role="toolbar" :aria-label="$t('mobile.language_selection')">
      <ChineseVoiceSelector />
      <UnifiedLanguageModal
        v-model="showLanguageModal"
        :show-trigger="true"
        :track-selection="true"
        @select="handleLanguageSelect"
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
  showBackButton?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  showBackButton: true
})

const emit = defineEmits<{
  back: []
}>()

const showLanguageModal = ref(false)

function handleBack() {
  emit('back')
}

function handleLanguageSelect() {
  // Language is already updated in the store by UnifiedLanguageModal
  // Just close the modal
  showLanguageModal.value = false
}
</script>

<style scoped>
.mobile-header {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  z-index: 50;
  background: linear-gradient(to bottom, rgba(0, 0, 0, 0.5), rgba(0, 0, 0, 0.3));
  backdrop-filter: blur(16px);
  -webkit-backdrop-filter: blur(16px);
  border-bottom: 1px solid rgba(255, 255, 255, 0.08);
  padding: 0.875rem 1.25rem; /* Slightly reduced vertical */
  padding-top: max(0.875rem, env(safe-area-inset-top)); /* Account for notch */
  display: flex;
  align-items: center;
  gap: 0.875rem;
  -webkit-text-size-adjust: 100%; /* Prevent text scaling */
  box-shadow: 0 4px 24px rgba(0, 0, 0, 0.15);
}

.back-button {
  width: 2.5rem;
  height: 2.5rem;
  min-width: 44px; /* iOS recommended touch target */
  min-height: 44px;
  border-radius: 0.75rem;
  background: rgba(255, 255, 255, 0.1);
  border: 1px solid rgba(255, 255, 255, 0.1);
  color: white;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
  flex-shrink: 0;
  touch-action: manipulation; /* Disable double-tap zoom */
  -webkit-tap-highlight-color: transparent;
}

.back-button i {
  font-size: 1rem;
  transition: transform 0.2s;
}

.back-button:active {
  transform: scale(0.92);
  background: rgba(255, 255, 255, 0.2);
  border-color: rgba(255, 255, 255, 0.2);
}

.back-button:active i {
  transform: translateX(-2px);
}

.back-button:focus-visible {
  outline: 2px solid #60a5fa;
  outline-offset: 2px;
}

.back-button-spacer {
  width: 2.75rem;
  height: 2.75rem;
  min-width: 44px;
  min-height: 44px;
  flex-shrink: 0;
  /* Invisible spacer to maintain layout when back button is hidden */
}

.header-content {
  flex: 1;
  min-width: 0;
}

.header-title {
  font-size: 1rem;
  font-weight: 700;
  color: white;
  margin: 0;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  letter-spacing: -0.01em;
}

.header-subtitle {
  font-size: 0.75rem;
  color: rgba(255, 255, 255, 0.75); /* WCAG AA: improved from 0.6 for contrast */
  margin: 0;
  margin-top: 0.125rem;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  font-weight: 500;
}

.language-controls {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  flex-shrink: 0;
}
</style>