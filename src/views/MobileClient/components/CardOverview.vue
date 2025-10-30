<template>
  <div class="card-overview">
    <!-- Hero Section with Card -->
    <div class="hero-section">
      <!-- Card Spotlight -->
      <div class="card-spotlight">
        <div class="spotlight-glow"></div>
        <div class="card-wrapper">
          <div class="card-frame">
            <img
              v-if="card.card_image_url"
              :src="card.card_image_url"
              :alt="card.card_name"
              class="card-image"
              crossorigin="anonymous"
            />
            <div v-else class="card-placeholder">
              <i class="pi pi-image" />
            </div>
          </div>
        </div>
      </div>
    </div>
    
    <!-- Info Panel -->
    <div class="info-panel">
      <div class="panel-inner">
        <!-- Language Selection Chip -->
        <button @click="showLanguageSelector = true" class="language-chip" :title="t('mobile.select_language')">
          <span class="language-chip-icon">🌐</span>
          <span class="language-chip-text">{{ languageStore.selectedLanguage.name }}</span>
          <span class="language-chip-flag">{{ languageStore.selectedLanguage.flag }}</span>
        </button>
        
        <!-- Card Title -->
        <h1 class="card-title">{{ card.card_name }}</h1>
        
        <!-- Description -->
        <div class="description-wrapper">
          <div class="card-description markdown-content" v-html="renderedDescription"></div>
        </div>
        
        <!-- Action Button -->
        <button @click="handleExplore" class="action-button">
          <span class="button-label">
            <i class="pi pi-compass" />
            {{ t('mobile.explore_content') }}
          </span>
          <div class="button-bg"></div>
        </button>
        
        <!-- AI Indicator -->
        <div v-if="card.conversation_ai_enabled" class="ai-indicator">
          <i class="pi pi-microphone" />
          <span>{{ t('mobile.ai_voice_guide') }}</span>
        </div>
      </div>
    </div>
    
    <!-- Language Selector Modal -->
    <UnifiedLanguageModal
      v-model="showLanguageSelector"
      :available-languages="availableLanguages"
      :track-selection="true"
      @select="handleLanguageSelect"
    />
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useI18n } from 'vue-i18n'
import { renderMarkdown } from '@/utils/markdownRenderer'
import { getCardAspectRatio } from '@/utils/cardConfig'
import { useMobileLanguageStore } from '@/stores/language'
import UnifiedLanguageModal from './UnifiedLanguageModal.vue'

const { t } = useI18n()
const languageStore = useMobileLanguageStore()
const showLanguageSelector = ref(false)

interface Props {
  card: {
    card_name: string
    card_description: string
    card_image_url: string
    crop_parameters?: any
    conversation_ai_enabled: boolean
    ai_instruction?: string
    ai_knowledge_base?: string
    is_activated: boolean
  }
  availableLanguages?: string[] // Languages available for this card
}

const props = defineProps<Props>()
const emit = defineEmits<{
  explore: []
}>()

// Render markdown description
const renderedDescription = computed(() => {
  if (!props.card.card_description) return ''
  return renderMarkdown(props.card.card_description)
})

function handleExplore() {
  emit('explore')
}

function handleLanguageSelect() {
  showLanguageSelector.value = false
}

// Set up CSS custom property for card aspect ratio
onMounted(() => {
  const aspectRatio = getCardAspectRatio()
  document.documentElement.style.setProperty('--card-aspect-ratio', aspectRatio)
})
</script>

<style scoped>
/* Base Container */
.card-overview {
  min-height: 100vh;
  min-height: var(--viewport-height, 100vh); /* Use dynamic viewport height */
  min-height: 100dvh;
  display: flex;
  flex-direction: column;
  background: linear-gradient(180deg, #0f172a 0%, #1e3a8a 50%, #312e81 100%);
  position: relative;
  overflow: hidden;
  isolation: isolate;
  -webkit-text-size-adjust: 100%; /* Prevent text size adjustment */
  touch-action: manipulation; /* Disable double-tap zoom */
}

/* Hero Section */
.hero-section {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 1.5rem 1rem 1rem;
  position: relative;
  min-height: 0;
}

/* Card Spotlight */
.card-spotlight {
  position: relative;
  width: 100%;
  max-width: 380px;
  animation: fadeIn 0.6s ease-out;
}

@keyframes fadeIn {
  from {
    opacity: 0;
    transform: translateY(20px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.spotlight-glow {
  position: absolute;
  inset: -40%;
  background: radial-gradient(
    circle at center,
    rgba(59, 130, 246, 0.15) 0%,
    rgba(139, 92, 246, 0.1) 30%,
    transparent 70%
  );
  filter: blur(40px);
  animation: pulse 4s ease-in-out infinite;
  z-index: 0;
}

@keyframes pulse {
  0%, 100% {
    opacity: 0.5;
    transform: scale(1);
  }
  50% {
    opacity: 0.8;
    transform: scale(1.05);
  }
}

.card-wrapper {
  position: relative;
  z-index: 1;
}

/* Card Frame */
.card-frame {
  aspect-ratio: var(--card-aspect-ratio, 2/3);
  width: 100%;
  border-radius: 1.25rem;
  overflow: hidden;
  background: white;
  box-shadow: 
    0 0 0 1px rgba(255, 255, 255, 0.1),
    0 30px 60px -15px rgba(0, 0, 0, 0.5),
    0 20px 40px -10px rgba(59, 130, 246, 0.2);
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
  position: relative;
  z-index: 1;
}

.card-frame::before {
  content: '';
  position: absolute;
  inset: 0;
  background: linear-gradient(
    135deg,
    rgba(255, 255, 255, 0.1) 0%,
    transparent 50%,
    rgba(255, 255, 255, 0.05) 100%
  );
  pointer-events: none;
  z-index: 2;
}

.card-frame:active {
  transform: scale(0.98);
  box-shadow: 
    0 0 0 1px rgba(255, 255, 255, 0.1),
    0 20px 40px -10px rgba(0, 0, 0, 0.4),
    0 10px 20px -5px rgba(59, 130, 246, 0.2);
}

.card-image {
  width: 100%;
  height: 100%;
  object-fit: contain;
  display: block;
  background: white;
  position: relative;
  z-index: 1;
}

.card-placeholder {
  width: 100%;
  height: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  background: linear-gradient(135deg, #e0e7ff, #ddd6fe);
  color: rgba(99, 102, 241, 0.3);
  font-size: 4rem;
}

/* Info Panel */
.info-panel {
  flex-shrink: 0;
  background: linear-gradient(180deg, rgba(15, 23, 42, 0.95) 0%, rgba(30, 58, 138, 0.95) 100%);
  border-top: 1px solid rgba(255, 255, 255, 0.15);
  padding: 1.5rem 1rem 2rem;
  padding-bottom: max(2rem, env(safe-area-inset-bottom)); /* Account for home indicator */
  animation: slideUp 0.5s ease-out 0.2s both;
  z-index: 2;
}

@keyframes slideUp {
  from {
    opacity: 0;
    transform: translateY(20px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.panel-inner {
  max-width: 600px;
  margin: 0 auto;
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

/* Language Selection Chip */
.language-chip {
  display: inline-flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.5rem 1rem;
  background: rgba(255, 255, 255, 0.1);
  border: 1px solid rgba(255, 255, 255, 0.2);
  border-radius: 9999px;
  color: white;
  font-size: 16px; /* Minimum 16px to prevent iOS zoom */
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s ease;
  backdrop-filter: blur(8px);
  -webkit-backdrop-filter: blur(8px);
  margin: 0 auto 0.75rem;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
  -webkit-tap-highlight-color: transparent; /* Remove tap highlight */
}

.language-chip:hover {
  background: rgba(255, 255, 255, 0.15);
  border-color: rgba(255, 255, 255, 0.3);
  transform: translateY(-1px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
}

.language-chip:active {
  transform: translateY(0);
  box-shadow: 0 2px 6px rgba(0, 0, 0, 0.1);
}

.language-chip-icon {
  font-size: 1rem;
  opacity: 0.9;
}

.language-chip-text {
  color: rgba(255, 255, 255, 0.95);
  letter-spacing: 0.01em;
}

.language-chip-flag {
  font-size: 1.125rem;
  line-height: 1;
}

/* Card Title */
.card-title {
  font-size: 1.625rem;
  font-weight: 800;
  color: white;
  margin: 0;
  line-height: 1.25;
  text-align: center;
  letter-spacing: -0.01em;
}

/* Description */
.description-wrapper {
  max-height: 5.5rem;
  overflow-y: auto;
  -webkit-overflow-scrolling: touch;
}

.card-description {
  font-size: 16px; /* Minimum 16px to prevent iOS zoom */
  color: rgba(255, 255, 255, 0.85);
  line-height: 1.6;
  margin: 0;
  text-align: center;
  word-break: break-word;
}

/* Markdown Content Styling */
.markdown-content :deep(p) {
  margin: 0 0 0.75rem 0;
}

.markdown-content :deep(p:last-child) {
  margin-bottom: 0;
}

.markdown-content :deep(strong) {
  font-weight: 700;
  color: rgba(255, 255, 255, 0.95);
}

.markdown-content :deep(em) {
  font-style: italic;
}

.markdown-content :deep(a) {
  color: #93c5fd;
  text-decoration: underline;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
  text-overflow: ellipsis;
  word-break: break-word;
}

.markdown-content :deep(ul),
.markdown-content :deep(ol) {
  margin: 0.5rem 0;
  padding-left: 1.5rem;
  text-align: left;
}

.markdown-content :deep(li) {
  margin: 0.25rem 0;
}

.markdown-content :deep(h1),
.markdown-content :deep(h2),
.markdown-content :deep(h3) {
  font-weight: 700;
  color: rgba(255, 255, 255, 0.95);
  margin: 0.75rem 0 0.5rem 0;
}

.markdown-content :deep(h1) {
  font-size: 1.25rem;
}

.markdown-content :deep(h2) {
  font-size: 1.125rem;
}

.markdown-content :deep(h3) {
  font-size: 1rem;
}

.markdown-content :deep(code) {
  background: rgba(255, 255, 255, 0.1);
  padding: 0.125rem 0.25rem;
  border-radius: 0.25rem;
  font-family: 'Courier New', monospace;
  font-size: 0.875rem;
}

.markdown-content :deep(blockquote) {
  border-left: 3px solid rgba(255, 255, 255, 0.3);
  padding-left: 1rem;
  margin: 0.75rem 0;
  font-style: italic;
  color: rgba(255, 255, 255, 0.75);
}

/* Custom Scrollbar */
.description-wrapper::-webkit-scrollbar {
  width: 3px;
}

.description-wrapper::-webkit-scrollbar-track {
  background: rgba(255, 255, 255, 0.05);
  border-radius: 2px;
}

.description-wrapper::-webkit-scrollbar-thumb {
  background: rgba(255, 255, 255, 0.25);
  border-radius: 2px;
}

/* Action Button */
.action-button {
  position: relative;
  width: 100%;
  padding: 1.125rem;
  border: none;
  border-radius: 1rem;
  color: white;
  font-size: 17px; /* 17px for buttons is Apple's recommended size */
  font-weight: 700;
  overflow: hidden;
  cursor: pointer;
  transition: all 0.3s ease;
  box-shadow: 
    0 0 0 1px rgba(255, 255, 255, 0.1),
    0 8px 16px rgba(0, 0, 0, 0.2);
  -webkit-tap-highlight-color: transparent; /* Remove tap highlight */
  touch-action: manipulation; /* Disable double-tap zoom */
}

.button-label {
  position: relative;
  z-index: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 0.5rem;
}

.button-bg {
  position: absolute;
  inset: 0;
  background: linear-gradient(135deg, #3b82f6, #8b5cf6);
  transition: transform 0.3s ease;
}

.action-button:active {
  transform: scale(0.98);
  box-shadow: 
    0 0 0 1px rgba(255, 255, 255, 0.1),
    0 4px 8px rgba(0, 0, 0, 0.2);
}

.action-button:active .button-bg {
  transform: scale(1.05);
}

/* AI Indicator */
.ai-indicator {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 0.5rem;
  padding: 0.75rem;
  background: rgba(59, 130, 246, 0.12);
  border: 1px solid rgba(59, 130, 246, 0.3);
  border-radius: 0.75rem;
  color: #93c5fd;
  font-size: 16px; /* Minimum 16px to prevent iOS zoom */
  font-weight: 500;
}

.ai-indicator i {
  color: #60a5fa;
  font-size: 0.875rem;
}

/* Responsive */
@media (min-width: 640px) {
  .hero-section {
    padding: 3rem 2rem;
  }
  
  .card-spotlight {
    max-width: 420px;
  }
  
  .card-title {
    font-size: 1.875rem;
  }
  
  .card-description {
    font-size: 17px; /* Keep ≥16px on larger screens too */
  }
  
  .description-wrapper {
    max-height: 7rem;
  }
  
  .info-panel {
    padding: 2rem 2rem 2.5rem;
  }
  
  .language-chip {
    padding: 0.625rem 1.25rem;
    font-size: 16px; /* Keep ≥16px on larger screens */
  }
  
  .language-chip-icon {
    font-size: 1.125rem;
  }
  
  .language-chip-flag {
    font-size: 1.25rem;
  }
}

@media (min-width: 768px) {
  .card-spotlight {
    max-width: 480px;
  }
}

/* Accessibility */
@media (prefers-reduced-motion: reduce) {
  .card-spotlight,
  .info-panel {
    animation: none;
  }
  
  .spotlight-glow {
    animation: none;
    opacity: 0.5;
  }
  
  .language-chip:hover,
  .language-chip:active {
    transform: none;
  }
}

/* Focus styles for accessibility */
.language-chip:focus-visible {
  outline: 2px solid rgba(255, 255, 255, 0.6);
  outline-offset: 2px;
}
</style>