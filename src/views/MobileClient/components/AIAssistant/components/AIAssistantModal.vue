<template>
  <Teleport to="body">
    <div v-if="isOpen" class="modal-overlay" @click="$emit('close')">
      <div class="modal-content" :class="assistantModeClass" @click.stop>
        <!-- Language Selection Screen -->
        <LanguageSelector
          v-if="showLanguageSelection"
          @select="$emit('select-language', $event)"
          @close="$emit('close')"
        />

        <!-- Chat Interface (after language selection) -->
        <template v-else>
          <!-- Header -->
          <div class="modal-header" :class="headerModeClass">
            <div class="header-left">
              <div class="header-avatar" :class="avatarModeClass">
                <i :class="headerIconClass" />
              </div>
              <div class="header-text">
                <h3 class="header-title">{{ headerTitle }}</h3>
                <p class="header-subtitle">{{ headerSubtitle }}</p>
              </div>
            </div>
            <div class="header-actions">
              <!-- Language Badge (compact) -->
              <div class="language-badge-compact" :title="indicatorLanguage">
                <span class="language-flag">{{ languageStore.selectedLanguage.flag }}</span>
              </div>
              <!-- Mode Switch Button (hidden when voice is not enabled) -->
              <button
                v-if="showVoiceToggle"
                @click="$emit('toggle-mode')"
                class="action-button"
                :class="{ 'active': conversationMode === 'realtime' }"
                :title="conversationMode === 'realtime' ? $t('mobile.switch_to_chat') : $t('mobile.switch_to_live_call')"
              >
                <i :class="conversationMode === 'realtime' ? 'pi pi-comments' : 'pi pi-phone'" />
              </button>
              <button @click="$emit('close')" class="action-button close-button">
                <i class="pi pi-times" />
              </button>
            </div>
          </div>

          <!-- Content -->
          <div class="modal-body">
            <slot />
          </div>
        </template>
      </div>
    </div>
  </Teleport>
</template>

<script setup lang="ts">
import { watch, onMounted, onUnmounted, ref, computed } from 'vue'
import { useI18n } from 'vue-i18n'
import LanguageSelector from './LanguageSelector.vue'
import { useMobileLanguageStore, CHINESE_VOICE_OPTIONS } from '@/stores/language'
import type { ConversationMode, Language, AssistantMode } from '../types'

const languageStore = useMobileLanguageStore()
const { t } = useI18n()

const props = withDefaults(defineProps<{
  isOpen: boolean
  showLanguageSelection: boolean
  conversationMode: ConversationMode
  inputMode?: 'text' | 'voice'
  contentItemName?: string // For content-item mode
  assistantMode?: AssistantMode // 'card-level' or 'content-item'
  title?: string // Custom title for card-level mode
  showVoiceToggle?: boolean // Whether to show the voice mode toggle button
}>(), {
  showVoiceToggle: true
})

// Computed properties for mode-based styling
const isCardLevel = computed(() => props.assistantMode === 'card-level')

const assistantModeClass = computed(() => ({
  'card-level-mode': isCardLevel.value,
  'content-item-mode': !isCardLevel.value
}))

const headerModeClass = computed(() => ({
  'header-card-level': isCardLevel.value,
  'header-content-item': !isCardLevel.value
}))

const avatarModeClass = computed(() => ({
  'avatar-card-level': isCardLevel.value,
  'avatar-content-item': !isCardLevel.value
}))

const headerIconClass = computed(() => 
  isCardLevel.value ? 'pi pi-sparkles' : 'pi pi-info-circle'
)

const headerTitle = computed(() => {
  if (isCardLevel.value) {
    return t('mobile.general_assistant')
  }
  return t('mobile.item_assistant')
})

const headerSubtitle = computed(() => {
  if (isCardLevel.value && props.title) {
    return props.title
  }
  return props.contentItemName || ''
})

defineEmits<{
  (e: 'close'): void
  (e: 'select-language', language: Language): void
  (e: 'toggle-mode'): void
}>()

// Computed properties for language indicator
const isVoiceMode = computed(() => {
  return props.conversationMode === 'realtime' || props.inputMode === 'voice'
})

const indicatorLanguage = computed(() => {
  const selectedLang = languageStore.selectedLanguage
  
  // For Chinese in Voice Mode, show dialect name (e.g., 廣東話, 普通話)
  if (isVoiceMode.value && languageStore.isChinese(selectedLang.code)) {
    const voiceOption = CHINESE_VOICE_OPTIONS.find(opt => opt.value === languageStore.chineseVoice)
    if (voiceOption) {
      return voiceOption.nativeName
    }
  }
  
  // Default: show language name (e.g., 繁體中文, English)
  return selectedLang.name
})

// Update modal height when keyboard appears/disappears
function updateVisualViewport() {
  if (typeof window === 'undefined') return
  
  // Use Visual Viewport API to get actual visible height (excluding keyboard)
  if (window.visualViewport) {
    const height = window.visualViewport.height
    document.documentElement.style.setProperty('--visual-viewport-height', `${height}px`)
  }
}

// Prevent body scroll when modal is open on mobile
watch(() => props.isOpen, (isOpen) => {
  if (typeof window === 'undefined') return
  
  if (isOpen) {
    // Store current scroll position
    const scrollY = window.scrollY
    document.body.style.position = 'fixed'
    document.body.style.top = `-${scrollY}px`
    document.body.style.width = '100%'
    
    // Initial viewport height setup
    updateVisualViewport()
  } else {
    // Restore scroll position
    const scrollY = document.body.style.top
    document.body.style.position = ''
    document.body.style.top = ''
    document.body.style.width = ''
    window.scrollTo(0, parseInt(scrollY || '0') * -1)
  }
})

// Listen for keyboard show/hide via Visual Viewport
onMounted(() => {
  if (typeof window !== 'undefined' && window.visualViewport) {
    window.visualViewport.addEventListener('resize', updateVisualViewport)
    window.visualViewport.addEventListener('scroll', updateVisualViewport)
    updateVisualViewport()
  }
})

onUnmounted(() => {
  if (typeof window !== 'undefined' && window.visualViewport) {
    window.visualViewport.removeEventListener('resize', updateVisualViewport)
    window.visualViewport.removeEventListener('scroll', updateVisualViewport)
  }
})
</script>

<style scoped>
.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(15, 23, 42, 0.75);
  backdrop-filter: blur(4px);
  -webkit-backdrop-filter: blur(4px);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 9999;
  padding: 1rem;
  animation: fadeIn 0.2s ease-out;
}

@keyframes fadeIn {
  from { opacity: 0; }
  to { opacity: 1; }
}

.modal-content {
  background: #1e293b;
  border-radius: 20px;
  width: 100%;
  max-width: 600px;
  max-height: 90vh;
  display: flex;
  flex-direction: column;
  box-shadow: 
    0 0 0 1px rgba(255, 255, 255, 0.1),
    0 25px 50px -12px rgba(0, 0, 0, 0.5);
  animation: slideUp 0.3s cubic-bezier(0.16, 1, 0.3, 1);
  overflow: hidden;
}

@keyframes slideUp {
  from {
    opacity: 0;
    transform: translateY(24px) scale(0.96);
  }
  to {
    opacity: 1;
    transform: translateY(0) scale(1);
  }
}

/* Header */
.modal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1rem 1.25rem;
  border-bottom: 1px solid rgba(255, 255, 255, 0.08);
  background: linear-gradient(180deg, rgba(255, 255, 255, 0.05) 0%, transparent 100%);
  position: relative;
}

.header-left {
  display: flex;
  align-items: center;
  gap: 0.875rem;
  min-width: 0;
  flex: 1;
}

.header-avatar {
  width: 44px;
  height: 44px;
  border-radius: 14px;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  font-size: 1.25rem;
  color: white;
  position: relative;
  animation: avatarGlow 3s ease-in-out infinite;
}

/* Card-Level Assistant (Purple-Indigo) */
.header-avatar.avatar-card-level {
  background: linear-gradient(135deg, #8b5cf6 0%, #6366f1 100%);
  box-shadow: 
    0 4px 16px rgba(139, 92, 246, 0.4),
    0 0 24px rgba(139, 92, 246, 0.2),
    inset 0 1px 0 rgba(255, 255, 255, 0.2);
}

/* Content-Item Assistant (Emerald-Teal) */
.header-avatar.avatar-content-item {
  background: linear-gradient(135deg, #10b981 0%, #14b8a6 100%);
  box-shadow: 
    0 4px 16px rgba(16, 185, 129, 0.4),
    0 0 24px rgba(16, 185, 129, 0.2),
    inset 0 1px 0 rgba(255, 255, 255, 0.2);
}

@keyframes avatarGlow {
  0%, 100% {
    filter: brightness(1);
    transform: scale(1);
  }
  50% {
    filter: brightness(1.1);
    transform: scale(1.02);
  }
}

.header-text {
  min-width: 0;
  flex: 1;
}

.header-title {
  margin: 0;
  font-size: 1rem;
  font-weight: 600;
  color: white;
  line-height: 1.3;
}

.header-subtitle {
  margin: 0;
  font-size: 0.8125rem;
  color: rgba(255, 255, 255, 0.6);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  max-width: 180px;
  line-height: 1.4;
}

.header-actions {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  flex-shrink: 0;
}

/* Compact Language Badge */
.language-badge-compact {
  width: 36px;
  height: 36px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: rgba(255, 255, 255, 0.08);
  border: 1px solid rgba(255, 255, 255, 0.12);
  border-radius: 10px;
  cursor: default;
  transition: all 0.2s;
}

.language-badge-compact .language-flag {
  font-size: 1.25rem;
  line-height: 1;
}

.action-button {
  width: 36px;
  height: 36px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: rgba(255, 255, 255, 0.08);
  border: 1px solid rgba(255, 255, 255, 0.12);
  border-radius: 10px;
  color: rgba(255, 255, 255, 0.7);
  font-size: 1rem;
  cursor: pointer;
  transition: all 0.2s;
  flex-shrink: 0;
}

.action-button:hover {
  background: rgba(255, 255, 255, 0.15);
  color: white;
}

.action-button.active {
  background: rgba(99, 102, 241, 0.3);
  border-color: rgba(99, 102, 241, 0.5);
  color: #a5b4fc;
}

.action-button.close-button:hover {
  background: rgba(239, 68, 68, 0.2);
  border-color: rgba(239, 68, 68, 0.4);
  color: #fca5a5;
}

.modal-body {
  flex: 1;
  overflow: hidden;
  display: flex;
  flex-direction: column;
  min-height: 0;
}

/* Mobile Full Screen */
@media (max-width: 640px) {
  .modal-overlay {
    padding: 0;
    align-items: stretch;
    overflow: hidden;
    touch-action: none;
  }
  
  .modal-content {
    max-width: 100%;
    max-height: none;
    border-radius: 0;
    height: var(--visual-viewport-height, var(--viewport-height, 100vh));
    min-height: -webkit-fill-available;
    touch-action: pan-y;
    -webkit-overflow-scrolling: touch;
    transition: height 0.3s ease-out;
  }
  
  .modal-header {
    padding-top: max(1rem, env(safe-area-inset-top));
    flex-shrink: 0;
  }
  
  .modal-body {
    padding-bottom: env(safe-area-inset-bottom);
    flex: 1 1 auto;
    min-height: 0;
  }
}
</style>
