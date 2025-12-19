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
            <div class="header-info">
              <i :class="headerIconClass" class="header-icon" />
              <div>
                <h3 class="header-title">{{ headerTitle }}</h3>
                <p class="header-subtitle">{{ headerSubtitle }}</p>
              </div>
            </div>
            <div class="header-actions">
              <!-- Mode Switch Button -->
              <button 
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

          <!-- Language Indicator -->
          <div class="language-indicator">
            <div class="language-badge">
              <i class="pi pi-globe" />
              <span class="language-flag">{{ languageStore.selectedLanguage.flag }}</span>
              <span class="language-text">
                {{ indicatorPrefix }} <strong>{{ indicatorLanguage }}</strong>
              </span>
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

const props = defineProps<{
  isOpen: boolean
  showLanguageSelection: boolean
  conversationMode: ConversationMode
  inputMode?: 'text' | 'voice'
  contentItemName?: string // For content-item mode
  assistantMode?: AssistantMode // 'card-level' or 'content-item'
  title?: string // Custom title for card-level mode
}>()

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

const headerIconClass = computed(() => 
  isCardLevel.value ? 'pi pi-comments' : 'pi pi-info-circle'
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

const visualViewportHeight = ref<number | null>(null)

// Computed properties for language indicator
const isVoiceMode = computed(() => {
  return props.conversationMode === 'realtime' || props.inputMode === 'voice'
})

const indicatorPrefix = computed(() => {
  // Use "Speak in" for voice/realtime, "Chat in" for text
  return isVoiceMode.value ? t('mobile.speak_in') : t('mobile.chat_in')
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
    visualViewportHeight.value = height
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
  background: rgba(0, 0, 0, 0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 9999;
  padding: 1rem;
  animation: fadeIn 0.2s ease-out;
}

@keyframes fadeIn {
  from {
    opacity: 0;
  }
  to {
    opacity: 1;
  }
}

.modal-content {
  background: white;
  border-radius: 16px;
  width: 100%;
  max-width: 600px;
  max-height: 90vh;
  display: flex;
  flex-direction: column;
  box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04);
  animation: slideUp 0.3s ease-out;
  overflow: hidden;
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

.modal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1.25rem 1.5rem;
  border-bottom: 1px solid #e5e7eb;
  background: white;
}

/* Card-Level Assistant Header (Blue-Purple gradient) */
.modal-header.header-card-level {
  background: linear-gradient(135deg, #eff6ff 0%, #f3e8ff 100%);
  border-bottom-color: #c7d2fe;
}

.modal-header.header-card-level .header-icon {
  color: #7c3aed;
}

/* Content-Item Assistant Header (Emerald-Cyan gradient) */
.modal-header.header-content-item {
  background: linear-gradient(135deg, #ecfdf5 0%, #ecfeff 100%);
  border-bottom-color: #a7f3d0;
}

.modal-header.header-content-item .header-icon {
  color: #059669;
}

.header-info {
  display: flex;
  align-items: center;
  gap: 0.75rem;
}

.header-icon {
  font-size: 1.5rem;
  color: #3b82f6;
}

.header-title {
  margin: 0;
  font-size: 1.125rem;
  font-weight: 600;
  color: #1f2937;
}

.header-subtitle {
  margin: 0;
  font-size: 0.875rem;
  color: #6b7280;
  max-width: 180px;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

/* Language Indicator */
.language-indicator {
  padding: 0.75rem 1.5rem;
  background: linear-gradient(135deg, #eff6ff 0%, #f3f0ff 100%);
  border-bottom: 1px solid #e5e7eb;
}

.language-badge {
  display: inline-flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.5rem 0.875rem;
  background: white;
  border-radius: 12px;
  box-shadow: 0 2px 8px rgba(59, 130, 246, 0.1);
  font-size: 0.875rem;
  color: #374151;
  transition: all 0.2s ease;
}

.language-badge:hover {
  box-shadow: 0 4px 12px rgba(59, 130, 246, 0.15);
  transform: translateY(-1px);
}

.language-badge .pi-globe {
  color: #3b82f6;
  font-size: 1rem;
}

.language-flag {
  font-size: 1.25rem;
  line-height: 1;
}

.language-text {
  color: #6b7280;
}

.language-text strong {
  color: #1f2937;
  font-weight: 600;
}

.header-actions {
  display: flex;
  gap: 0.5rem;
  flex-shrink: 0;
}

.action-button {
  width: 36px;
  height: 36px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: #f3f4f6;
  border: none;
  border-radius: 8px;
  color: #6b7280;
  font-size: 1.125rem;
  cursor: pointer;
  transition: all 0.2s;
  flex-shrink: 0;
}

.action-button:hover {
  background: #e5e7eb;
  color: #374151;
}

.action-button.active {
  background: #dbeafe;
  color: #3b82f6;
}

.action-button.close-button:hover {
  background: #fee2e2;
  color: #dc2626;
}

.modal-body {
  flex: 1;
  overflow: hidden;
  display: flex;
  flex-direction: column;
  min-height: 0;
}

@media (max-width: 640px) {
  .modal-overlay {
    padding: 0;
    align-items: stretch;
    /* Prevent overscroll/bounce on iOS */
    overflow: hidden;
    touch-action: none;
  }
  
  .modal-content {
    max-width: 100%;
    max-height: none;
    border-radius: 0;
    /* Use visual viewport height to adapt to keyboard */
    height: var(--visual-viewport-height, var(--viewport-height, 100vh));
    min-height: -webkit-fill-available; /* iOS Safari fallback */
    /* Enable internal scrolling */
    touch-action: pan-y;
    -webkit-overflow-scrolling: touch;
    /* Smooth transition when keyboard appears */
    transition: height 0.3s ease-out;
  }
  
  .modal-header {
    /* Ensure header doesn't get hidden by notch */
    padding-top: max(1.25rem, env(safe-area-inset-top));
    flex-shrink: 0; /* Never compress header */
  }
  
  .modal-body {
    /* Account for iPhone home indicator */
    padding-bottom: env(safe-area-inset-bottom);
    /* Allow body to shrink when keyboard appears */
    flex: 1 1 auto;
    min-height: 0;
  }
}
</style>

