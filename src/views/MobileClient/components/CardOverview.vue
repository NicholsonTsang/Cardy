<template>
  <div class="card-overview" :class="{ 'digital-mode': isDigitalAccess }">
    <!-- Hero Section with Card (Physical cards only) -->
    <div v-if="!isDigitalAccess" class="hero-section">
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

    <!-- Welcome Section (Digital access - Visual effects only) -->
    <div v-else class="welcome-section">
      <!-- Immersive Background -->
      <div class="immersive-bg">
        <!-- Animated gradient layers -->
        <div class="gradient-layer gradient-1"></div>
        <div class="gradient-layer gradient-2"></div>
        <div class="gradient-layer gradient-3"></div>
        
        <!-- 3D Grid floor with perspective -->
        <div class="perspective-grid"></div>
        
        <!-- Floating particles -->
        <div class="particles">
          <div class="particle particle-1"></div>
          <div class="particle particle-2"></div>
          <div class="particle particle-3"></div>
          <div class="particle particle-4"></div>
          <div class="particle particle-5"></div>
          <div class="particle particle-6"></div>
          <div class="particle particle-7"></div>
          <div class="particle particle-8"></div>
        </div>
      </div>

      <!-- Centered Icon with animations -->
      <div class="welcome-visual">
        <div class="welcome-icon-container">
          <div class="icon-glow-ring"></div>
          <div class="icon-glow-ring icon-glow-ring-2"></div>
          <div class="icon-glow-ring icon-glow-ring-3"></div>
          <div class="icon-main">
            <i class="pi pi-compass" />
          </div>
          <div class="icon-pulse-wave"></div>
          <div class="icon-pulse-wave icon-pulse-wave-2"></div>
        </div>
      </div>
    </div>
    
    <!-- Info Panel -->
    <div class="info-panel" :class="{ 'digital-panel': isDigitalAccess }">
      <div class="panel-inner">
        <!-- Language Selection Row - Shows scope of language selection -->
        <div class="language-row">
          <span class="language-label">{{ t('mobile.view_in') }}</span>
          <button @click="showLanguageSelector = true" class="language-chip" :title="t('mobile.select_language')">
            <span class="language-chip-flag">{{ languageStore.selectedLanguage.flag }}</span>
            <span class="language-chip-text">{{ languageStore.selectedLanguage.name }}</span>
            <i class="pi pi-chevron-down language-chip-icon"></i>
          </button>
        </div>
        
        <!-- Card Title (Both modes now) -->
        <h1 class="card-title">{{ card.card_name }}</h1>
        
        <!-- Description (Both modes now) -->
        <div v-if="renderedDescription" class="description-wrapper">
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
        
        <!-- AI Indicator - Now tappable to open assistant -->
        <button 
          v-if="card.conversation_ai_enabled" 
          @click="openAIAssistant"
          class="ai-indicator-button"
        >
          <div class="ai-indicator-content">
            <div class="ai-indicator-icon">
              <i class="pi pi-sparkles" />
            </div>
            <div class="ai-indicator-text">
              <span class="ai-indicator-title">{{ t('mobile.ai_voice_guide') }}</span>
              <span class="ai-indicator-subtitle">{{ t('mobile.tap_to_chat_with_ai') }}</span>
            </div>
          </div>
          <i class="pi pi-chevron-right ai-indicator-arrow" />
        </button>
      </div>
    </div>
    
    <!-- Card Level AI Assistant (hidden button, triggered programmatically) -->
    <CardLevelAssistant
      v-if="card.conversation_ai_enabled"
      ref="cardLevelAssistantRef"
      :card-data="cardDataForAssistant"
      :show-button="false"
    />
    
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
import { CardLevelAssistant } from './AIAssistant'

const { t } = useI18n()
const languageStore = useMobileLanguageStore()
const showLanguageSelector = ref(false)
const cardLevelAssistantRef = ref<InstanceType<typeof CardLevelAssistant> | null>(null)

interface Props {
  card: {
    card_name: string
    card_description: string
    card_image_url: string
    crop_parameters?: any
    conversation_ai_enabled: boolean
    ai_instruction?: string
    ai_knowledge_base?: string
    ai_welcome_general?: string
    ai_welcome_item?: string
    is_activated: boolean
    billing_type?: 'physical' | 'digital'
    has_translation?: boolean // TRUE if card has translations available
  }
  availableLanguages?: string[] // Languages available for this card
}

const props = defineProps<Props>()

// Check if this is digital access mode
const isDigitalAccess = computed(() => props.card.billing_type === 'digital')
const emit = defineEmits<{
  explore: []
}>()

// Card data formatted for AI assistant
const cardDataForAssistant = computed(() => ({
  card_name: props.card.card_name,
  card_description: props.card.card_description,
  card_image_url: props.card.card_image_url,
  conversation_ai_enabled: props.card.conversation_ai_enabled,
  ai_instruction: props.card.ai_instruction || '',
  ai_knowledge_base: props.card.ai_knowledge_base || '',
  ai_welcome_general: props.card.ai_welcome_general || '',
  ai_welcome_item: props.card.ai_welcome_item || '',
  is_activated: props.card.is_activated
}))

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

// Open AI assistant
function openAIAssistant() {
  cardLevelAssistantRef.value?.openModal()
}

// Set up CSS custom property for card aspect ratio
onMounted(() => {
  const aspectRatio = getCardAspectRatio()
  document.documentElement.style.setProperty('--card-aspect-ratio', aspectRatio)
})
</script>

<style scoped>
/* Base Container - Fill parent flex container */
.card-overview {
  /* Fill parent container */
  flex: 1;
  display: flex;
  flex-direction: column;
  min-height: 0; /* Allow flex shrinking */
  /* Dark background to prevent flash during view transitions */
  background: linear-gradient(to bottom right, #0f172a, #1e3a8a, #4338ca);
  position: relative;
  overflow: hidden;
  isolation: isolate;
  -webkit-text-size-adjust: 100%; /* Prevent text size adjustment */
  touch-action: manipulation; /* Disable double-tap zoom */
}

/* Digital mode - no special handling needed, parent container handles sizing */
.card-overview.digital-mode {
  /* Same as base, parent container handles fixed height */
}

/* Hero Section (Physical cards) */
.hero-section {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 2rem 1.25rem 1.5rem;
  padding-top: calc(2rem + env(safe-area-inset-top));
  position: relative;
  min-height: 0;
}

/* ============================================== */
/* Welcome Section (Digital - Dynamic Hero) */
/* ============================================== */

.welcome-section {
  /* Dynamic height - fills remaining space after info panel */
  flex: 1 1 auto;
  min-height: 120px; /* Minimum to keep icon visible */
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 0.75rem 1.5rem 0.5rem;
  padding-top: calc(0.5rem + env(safe-area-inset-top));
  position: relative;
  overflow: visible;
}

/* Immersive Background */
.immersive-bg {
  position: absolute;
  inset: 0;
  pointer-events: none;
  overflow: hidden;
}

/* Animated Gradient Layers */
.gradient-layer {
  position: absolute;
  inset: 0;
}

.gradient-1 {
  background: radial-gradient(ellipse 150% 100% at 50% 0%, rgba(99, 102, 241, 0.4) 0%, transparent 60%);
  animation: gradientPulse1 8s ease-in-out infinite;
}

.gradient-2 {
  background: radial-gradient(ellipse 100% 80% at 100% 100%, rgba(139, 92, 246, 0.3) 0%, transparent 50%);
  animation: gradientPulse2 10s ease-in-out infinite;
}

.gradient-3 {
  background: radial-gradient(ellipse 80% 60% at 0% 50%, rgba(59, 130, 246, 0.25) 0%, transparent 50%);
  animation: gradientPulse3 12s ease-in-out infinite;
}

@keyframes gradientPulse1 {
  0%, 100% { opacity: 0.8; transform: scale(1); }
  50% { opacity: 1; transform: scale(1.1); }
}

@keyframes gradientPulse2 {
  0%, 100% { opacity: 0.6; transform: translateX(0); }
  50% { opacity: 0.9; transform: translateX(-20px); }
}

@keyframes gradientPulse3 {
  0%, 100% { opacity: 0.5; transform: translateY(0); }
  50% { opacity: 0.8; transform: translateY(20px); }
}

/* 3D Perspective Grid */
.perspective-grid {
  position: absolute;
  bottom: 0;
  left: -100%;
  right: -100%;
  height: 50%;
  background: 
    linear-gradient(90deg, rgba(99, 102, 241, 0.08) 1px, transparent 1px),
    linear-gradient(0deg, rgba(99, 102, 241, 0.08) 1px, transparent 1px);
  background-size: 50px 50px;
  transform: perspective(500px) rotateX(65deg);
  transform-origin: bottom center;
  mask-image: linear-gradient(to top, rgba(0,0,0,0.6) 0%, transparent 70%);
  -webkit-mask-image: linear-gradient(to top, rgba(0,0,0,0.6) 0%, transparent 70%);
  animation: gridMove 20s linear infinite;
}

@keyframes gridMove {
  from { background-position: 0 0, 0 0; }
  to { background-position: 50px 50px, 50px 50px; }
}

/* Floating Particles */
.particles {
  position: absolute;
  inset: 0;
}

.particle {
  position: absolute;
  width: 4px;
  height: 4px;
  background: rgba(255, 255, 255, 0.6);
  border-radius: 50%;
  box-shadow: 0 0 10px rgba(99, 102, 241, 0.5);
  animation: particleFloat 15s ease-in-out infinite;
}

.particle-1 { top: 10%; left: 10%; animation-delay: 0s; }
.particle-2 { top: 20%; right: 15%; animation-delay: -2s; width: 3px; height: 3px; }
.particle-3 { top: 40%; left: 5%; animation-delay: -4s; }
.particle-4 { top: 60%; right: 10%; animation-delay: -6s; width: 5px; height: 5px; }
.particle-5 { top: 30%; left: 30%; animation-delay: -8s; width: 2px; height: 2px; }
.particle-6 { top: 70%; left: 20%; animation-delay: -10s; }
.particle-7 { top: 15%; right: 30%; animation-delay: -12s; width: 3px; height: 3px; }
.particle-8 { top: 50%; right: 25%; animation-delay: -14s; }

@keyframes particleFloat {
  0%, 100% {
    transform: translate(0, 0) scale(1);
    opacity: 0.4;
  }
  25% {
    transform: translate(30px, -40px) scale(1.2);
    opacity: 0.8;
  }
  50% {
    transform: translate(-20px, -60px) scale(0.8);
    opacity: 0.6;
  }
  75% {
    transform: translate(20px, -30px) scale(1.1);
    opacity: 0.9;
  }
}

/* Centered Visual Container */
.welcome-visual {
  position: relative;
  z-index: 10;
  display: flex;
  align-items: center;
  justify-content: center;
  animation: contentFadeUp 0.8s ease-out;
}

@keyframes contentFadeUp {
  from {
    opacity: 0;
    transform: translateY(40px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

/* Icon Container - Compact */
.welcome-icon-container {
  position: relative;
  width: 80px;
  height: 80px;
}

.icon-glow-ring {
  position: absolute;
  inset: -10px;
  border: 1.5px solid rgba(99, 102, 241, 0.4);
  border-radius: 50%;
  animation: ringPulse 3s ease-in-out infinite;
}

.icon-glow-ring-2 {
  inset: -24px;
  border-color: rgba(139, 92, 246, 0.25);
  animation-delay: -1s;
}

.icon-glow-ring-3 {
  inset: -38px;
  border-color: rgba(99, 102, 241, 0.15);
  animation-delay: -2s;
}

@keyframes ringPulse {
  0%, 100% {
    transform: scale(1);
    opacity: 0.5;
  }
  50% {
    transform: scale(1.1);
    opacity: 0.8;
  }
}

.icon-main {
  position: absolute;
  inset: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  background: linear-gradient(135deg, rgba(99, 102, 241, 0.3), rgba(139, 92, 246, 0.2));
  border: 2px solid rgba(255, 255, 255, 0.25);
  border-radius: 50%;
  backdrop-filter: blur(10px);
  -webkit-backdrop-filter: blur(10px);
  box-shadow: 
    0 10px 40px rgba(99, 102, 241, 0.4),
    inset 0 1px 0 rgba(255, 255, 255, 0.2);
}

.icon-main i {
  font-size: 2rem;
  color: white;
  text-shadow: 0 0 30px rgba(255, 255, 255, 0.6);
}

.icon-pulse-wave {
  position: absolute;
  inset: 0;
  border-radius: 50%;
  border: 2px solid rgba(99, 102, 241, 0.5);
  animation: pulseWave 2.5s ease-out infinite;
}

.icon-pulse-wave-2 {
  animation-delay: -1.25s;
  border-color: rgba(139, 92, 246, 0.4);
}

@keyframes pulseWave {
  0% {
    transform: scale(1);
    opacity: 0.6;
  }
  100% {
    transform: scale(2.5);
    opacity: 0;
  }
}

/* Digital mode panel adjustments */
.digital-panel {
  border-top-left-radius: 1.5rem;
  border-top-right-radius: 1.5rem;
  background: linear-gradient(180deg, rgba(15, 23, 42, 0.98) 0%, rgba(30, 41, 59, 0.98) 100%);
  box-shadow: 0 -10px 40px rgba(0, 0, 0, 0.3);
}

/* Digital mode specific overrides */
.digital-mode {
  background: linear-gradient(180deg, #0f172a 0%, #1e1b4b 50%, #312e81 100%);
}

/* Responsive adjustments */
@media (min-width: 640px) {
  .icon-platform {
    width: 160px;
    height: 160px;
  }
  
  .icon-cube {
    inset: 40px;
  }
  
  .cube-face {
    width: 80px;
    height: 80px;
  }
  
  .cube-front,
  .cube-back {
    transform: translateZ(40px);
  }
  
  .cube-front i {
    font-size: 2.5rem;
  }
  
  .cube-left {
    transform: rotateY(-90deg) translateZ(40px);
  }
  
  .cube-right {
    transform: rotateY(90deg) translateZ(40px);
  }
  
  .cube-top {
    transform: rotateX(90deg) translateZ(40px);
  }
  
  .cube-bottom {
    transform: rotateX(-90deg) translateZ(40px);
  }
  
  .welcome-title-3d {
    font-size: 2rem;
  }
  
  .glass-content {
    font-size: 1rem;
  }
  
  .content-card {
    padding: 2rem;
    max-width: 420px;
  }
}

/* Reduce motion for accessibility */
@media (prefers-reduced-motion: reduce) {
  .floating-cube,
  .floating-prism,
  .glow-sphere,
  .light-beam,
  .platform-ring,
  .icon-cube,
  .icon-glow {
    animation: none;
  }
  
  .welcome-content-3d {
    animation: none;
  }
  
  .grid-floor {
    display: none;
  }
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
  border-radius: 1.5rem;
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

/* Info Panel - Takes only needed space, hero fills the rest */
.info-panel {
  flex: 0 0 auto; /* Don't grow - take only needed space */
  display: flex;
  flex-direction: column;
  background: linear-gradient(180deg, rgba(15, 23, 42, 0.98) 0%, rgba(30, 58, 138, 0.95) 100%);
  border-top: 1px solid rgba(255, 255, 255, 0.15);
  padding: 1.25rem 1.125rem 1.25rem;
  padding-bottom: max(1.25rem, calc(env(safe-area-inset-bottom) + 0.625rem)); /* Account for home indicator */
  animation: slideUp 0.5s ease-out 0.2s both;
  z-index: 2;
  border-top-left-radius: 1.5rem;
  border-top-right-radius: 1.5rem;
}

/* Digital mode - no special handling needed */
.digital-mode .info-panel {
  /* Info panel takes only needed space, hero section fills the rest */
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
  gap: 0.625rem; /* More compact gap for more screen space */
  width: 100%;
}

/* Language Selection Row */
.language-row {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 0.5rem;
  margin-bottom: 0.5rem;
}

.language-label {
  color: rgba(255, 255, 255, 0.6);
  font-size: 0.875rem;
  font-weight: 500;
  letter-spacing: 0.02em;
}

/* Language Selection Chip */
.language-chip {
  display: inline-flex;
  align-items: center;
  gap: 0.375rem;
  padding: 0.375rem 0.75rem;
  background: rgba(255, 255, 255, 0.1);
  border: 1px solid rgba(255, 255, 255, 0.2);
  border-radius: 9999px;
  color: white;
  font-size: 0.875rem;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s ease;
  backdrop-filter: blur(8px);
  -webkit-backdrop-filter: blur(8px);
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
  font-size: 0.625rem;
  opacity: 0.7;
  margin-left: 0.125rem;
}

.language-chip-text {
  color: rgba(255, 255, 255, 0.95);
  letter-spacing: 0.01em;
}

.language-chip-flag {
  font-size: 1rem;
  line-height: 1;
}

/* Card Title - Compact with 2-line max */
.card-title {
  font-size: 1.25rem;
  font-weight: 700;
  color: white;
  margin: 0;
  line-height: 1.3;
  text-align: center;
  letter-spacing: -0.01em;
  /* Limit to 2 lines with ellipsis */
  display: -webkit-box;
  -webkit-line-clamp: 2;
  line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
  text-overflow: ellipsis;
  flex-shrink: 0; /* Don't shrink title */
}

/* Description - Scrollable with max height */
.description-wrapper {
  max-height: 20vh; /* Cap description height */
  overflow-y: auto;
  -webkit-overflow-scrolling: touch;
}

.card-description {
  font-size: 15px; /* Slightly smaller for compact mobile view */
  color: rgba(255, 255, 255, 0.88);
  line-height: 1.6; /* Increased for better readability */
  letter-spacing: 0.01em; /* Slight letter-spacing for clarity */
  margin: 0;
  text-align: center;
  word-break: break-word;
}

/* Markdown Content Styling - Optimized for mobile readability */
.markdown-content :deep(p) {
  margin: 0 0 0.75em 0; /* Use em for consistent spacing relative to font-size */
}

.markdown-content :deep(p:last-child) {
  margin-bottom: 0;
}

.markdown-content :deep(strong) {
  font-weight: 600; /* Semi-bold for better contrast without being too heavy */
  color: rgba(255, 255, 255, 0.95);
}

.markdown-content :deep(em) {
  font-style: italic;
  color: rgba(255, 255, 255, 0.9);
}

.markdown-content :deep(a) {
  color: #93c5fd;
  text-decoration: underline;
  text-underline-offset: 2px; /* Better underline positioning */
  word-break: break-word;
}

.markdown-content :deep(ul),
.markdown-content :deep(ol) {
  margin: 0.625em 0;
  padding-left: 1.25em; /* Tighter indent for mobile */
  text-align: left;
}

.markdown-content :deep(li) {
  margin: 0.375em 0; /* Slightly more spacing between items */
  line-height: 1.5;
}

.markdown-content :deep(li::marker) {
  color: rgba(255, 255, 255, 0.6);
}

.markdown-content :deep(h1),
.markdown-content :deep(h2),
.markdown-content :deep(h3) {
  font-weight: 600;
  color: rgba(255, 255, 255, 0.95);
  margin: 0.875em 0 0.5em 0;
  line-height: 1.3;
}

.markdown-content :deep(h1) {
  font-size: 1.125rem;
}

.markdown-content :deep(h2) {
  font-size: 1.0625rem;
}

.markdown-content :deep(h3) {
  font-size: 1rem;
}

.markdown-content :deep(code) {
  background: rgba(255, 255, 255, 0.12);
  padding: 0.15em 0.35em;
  border-radius: 4px;
  font-family: 'SF Mono', 'Menlo', 'Monaco', 'Courier New', monospace;
  font-size: 0.9em; /* Relative to parent */
}

.markdown-content :deep(blockquote) {
  border-left: 3px solid rgba(139, 92, 246, 0.5); /* Purple accent */
  padding-left: 0.875em;
  margin: 0.75em 0;
  font-style: italic;
  color: rgba(255, 255, 255, 0.8);
}

/* Horizontal rule */
.markdown-content :deep(hr) {
  border: none;
  border-top: 1px solid rgba(255, 255, 255, 0.15);
  margin: 1em 0;
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

/* Action Button - Condensed for more screen space */
.action-button {
  position: relative;
  width: 100%;
  padding: 0.875rem;
  border: none;
  border-radius: 0.875rem;
  color: white;
  font-size: 1rem;
  font-weight: 600;
  overflow: hidden;
  cursor: pointer;
  transition: all 0.3s ease;
  box-shadow: 
    0 0 0 1px rgba(255, 255, 255, 0.1),
    0 6px 12px rgba(0, 0, 0, 0.2);
  -webkit-tap-highlight-color: transparent;
  touch-action: manipulation;
  flex-shrink: 0;
  min-height: 48px; /* Maintain touch target */
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

/* AI Indicator Button - Condensed */
.ai-indicator-button {
  display: flex;
  align-items: center;
  justify-content: space-between;
  width: 100%;
  padding: 0.625rem 0.875rem;
  background: linear-gradient(135deg, rgba(139, 92, 246, 0.15) 0%, rgba(59, 130, 246, 0.15) 100%);
  border: 1px solid rgba(139, 92, 246, 0.3);
  border-radius: 0.875rem;
  cursor: pointer;
  transition: all 0.2s ease;
  -webkit-tap-highlight-color: transparent;
  touch-action: manipulation;
  flex-shrink: 0;
  min-height: 52px; /* Maintain touch target */
}

.ai-indicator-button:hover {
  background: linear-gradient(135deg, rgba(139, 92, 246, 0.2) 0%, rgba(59, 130, 246, 0.2) 100%);
  border-color: rgba(139, 92, 246, 0.4);
  transform: translateY(-1px);
}

.ai-indicator-button:active {
  transform: scale(0.98);
}

.ai-indicator-content {
  display: flex;
  align-items: center;
  gap: 0.75rem;
}

.ai-indicator-icon {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 32px;
  height: 32px;
  background: linear-gradient(135deg, #8b5cf6 0%, #6366f1 100%);
  border-radius: 8px;
  box-shadow: 0 2px 6px rgba(139, 92, 246, 0.3);
}

.ai-indicator-icon i {
  color: white;
  font-size: 1rem;
}

.ai-indicator-text {
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  gap: 0.0625rem;
}

.ai-indicator-title {
  color: white;
  font-size: 0.875rem;
  font-weight: 600;
  line-height: 1.2;
}

.ai-indicator-subtitle {
  color: rgba(255, 255, 255, 0.65);
  font-size: 0.75rem;
  font-weight: 400;
}

.ai-indicator-arrow {
  color: rgba(255, 255, 255, 0.5);
  font-size: 0.875rem;
  transition: transform 0.2s ease;
}

.ai-indicator-button:hover .ai-indicator-arrow {
  transform: translateX(2px);
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
    font-size: 16px; /* Slightly larger on bigger screens */
    line-height: 1.65;
  }
  
  .description-wrapper {
    max-height: 25vh; /* More room on larger screens */
  }
  
  .info-panel {
    padding: 2rem 2rem 2.5rem;
  }
  
  .language-label {
    font-size: 0.9375rem;
  }
  
  .language-chip {
    padding: 0.5rem 1rem;
    font-size: 0.9375rem;
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