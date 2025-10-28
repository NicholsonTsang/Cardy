<template>
  <Teleport to="body">
    <div v-if="isOpen" class="modal-overlay" @click="$emit('close')">
      <div class="modal-content" @click.stop>
        <!-- Language Selection Screen -->
        <LanguageSelector
          v-if="showLanguageSelection"
          @select="$emit('select-language', $event)"
          @close="$emit('close')"
        />

        <!-- Chat Interface (after language selection) -->
        <template v-else>
          <!-- Header -->
          <div class="modal-header">
            <div class="header-info">
              <i class="pi pi-comments header-icon" />
              <div>
                <h3 class="header-title">AI Assistant</h3>
                <p class="header-subtitle">{{ contentItemName }}</p>
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
import { watch, onMounted, onUnmounted, ref } from 'vue'
import LanguageSelector from './LanguageSelector.vue'
import type { ConversationMode, Language } from '../types'

const props = defineProps<{
  isOpen: boolean
  showLanguageSelection: boolean
  conversationMode: ConversationMode
  contentItemName: string
}>()

defineEmits<{
  (e: 'close'): void
  (e: 'select-language', language: Language): void
  (e: 'toggle-mode'): void
}>()

const visualViewportHeight = ref<number | null>(null)

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

