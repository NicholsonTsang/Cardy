<template>
  <div class="unified-language-selector">
    <!-- Optional Trigger Button (for header usage) -->
    <slot name="trigger" :open="openModal">
      <!-- Default trigger button (header style) -->
      <button 
        v-if="showTrigger"
        @click="openModal" 
        class="language-button" 
        :title="$t('mobile.select_language')"
      >
        <span class="language-flag">{{ languageStore.selectedLanguage.flag }}</span>
        <span class="language-code">{{ languageStore.selectedLanguage.code.toUpperCase() }}</span>
      </button>
    </slot>

    <!-- Language Selection Modal -->
    <Teleport to="body">
      <Transition name="modal">
        <div v-if="modelValue" class="modal-overlay" @click="closeModal">
          <div class="modal-content" @click.stop>
            <div class="modal-header">
              <h2>{{ $t('mobile.select_language') }}</h2>
              <button @click="closeModal" class="close-button">
                <i class="pi pi-times" />
              </button>
            </div>

            <div class="language-grid">
              <button
                v-for="lang in languageStore.languages"
                :key="lang.code"
                @click="selectLanguage(lang)"
                class="language-option"
                :class="{ 
                  active: languageStore.selectedLanguage.code === lang.code,
                  'has-translation': hasTranslation(lang.code)
                }"
              >
                <span class="flag">
                  {{ lang.flag }}
                </span>
                <span class="name">{{ lang.name }}</span>
                
                <!-- Active checkmark -->
                <i v-if="languageStore.selectedLanguage.code === lang.code" class="pi pi-check check-icon" />
                
                <!-- Translation status badge -->
                <span v-if="hasTranslation(lang.code)" class="translation-badge" :title="$t('mobile.translated_content_available')">
                  <i class="pi pi-language" />
                </span>
              </button>
            </div>
          </div>
        </div>
      </Transition>
    </Teleport>
  </div>
</template>

<script setup lang="ts">
import { watch, onUnmounted } from 'vue'
import { useMobileLanguageStore } from '@/stores/language'
import type { Language } from '@/stores/language'

interface Props {
  modelValue: boolean // v-model for open/close state
  availableLanguages?: string[] // Optional: restrict to certain languages
  showTrigger?: boolean // Show default trigger button (for header)
  trackSelection?: boolean // Track user selection in sessionStorage
}

const props = withDefaults(defineProps<Props>(), {
  showTrigger: false,
  trackSelection: true
})

const emit = defineEmits<{
  'update:modelValue': [value: boolean]
  select: [language: Language]
}>()

const languageStore = useMobileLanguageStore()

// Prevent body scroll when modal is open
watch(() => props.modelValue, (isOpen) => {
  if (typeof window === 'undefined') return
  
  if (isOpen) {
    // Store current scroll position
    const scrollY = window.scrollY
    document.body.style.position = 'fixed'
    document.body.style.top = `-${scrollY}px`
    document.body.style.left = '0'
    document.body.style.right = '0'
    document.body.style.width = '100%'
  } else {
    // Restore scroll position
    const scrollY = document.body.style.top
    document.body.style.position = ''
    document.body.style.top = ''
    document.body.style.left = ''
    document.body.style.right = ''
    document.body.style.width = ''
    if (scrollY) {
      window.scrollTo(0, parseInt(scrollY || '0') * -1)
    }
  }
})

// Cleanup on unmount
onUnmounted(() => {
  if (typeof window === 'undefined') return
  
  // Restore body scroll if component unmounts while modal is open
  if (props.modelValue) {
    const scrollY = document.body.style.top
    document.body.style.position = ''
    document.body.style.top = ''
    document.body.style.left = ''
    document.body.style.right = ''
    document.body.style.width = ''
    if (scrollY) {
      window.scrollTo(0, parseInt(scrollY || '0') * -1)
    }
  }
})

// Check if a language has translated content available
const hasTranslation = (langCode: string) => {
  if (!props.availableLanguages || props.availableLanguages.length === 0) {
    return false // No translations available
  }
  return props.availableLanguages.includes(langCode)
}

function openModal() {
  emit('update:modelValue', true)
}

function closeModal() {
  emit('update:modelValue', false)
}

function selectLanguage(language: Language) {
  // Allow selection of all languages (even without translations)
  // Users will see i18n text if no translation exists
  
  // Track user selection (prevents auto-reset to card's original language)
  if (props.trackSelection) {
    sessionStorage.setItem('userSelectedLanguage', 'true')
  }
  
  // Update language in store
  languageStore.setLanguage(language)
  
  // Emit events
  emit('select', language)
  closeModal()
}
</script>

<style scoped>
/* Component Container */
.unified-language-selector {
  position: relative;
}

/* Trigger Button (Header Style) */
.language-button {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.5rem 0.75rem;
  background: rgba(255, 255, 255, 0.1);
  border: 1px solid rgba(255, 255, 255, 0.2);
  border-radius: 8px;
  color: white;
  cursor: pointer;
  transition: all 0.2s;
  font-size: 0.875rem;
  min-height: 44px; /* iOS touch target */
  touch-action: manipulation;
  -webkit-tap-highlight-color: transparent;
}

.language-button:hover {
  background: rgba(255, 255, 255, 0.2);
  border-color: rgba(255, 255, 255, 0.3);
}

.language-button:active {
  transform: scale(0.98);
}

.language-flag {
  font-size: 1.25rem;
  line-height: 1;
}

.language-code {
  font-weight: 600;
  font-size: 0.75rem;
  text-transform: uppercase;
}

/* Modal Overlay */
.modal-overlay {
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.75);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 9999;
  padding: 1rem;
  backdrop-filter: blur(4px);
  -webkit-backdrop-filter: blur(4px);
  touch-action: none; /* Prevent background interaction */
  overflow: hidden; /* Prevent overflow scroll */
  overscroll-behavior: contain; /* Contain scroll within modal */
}

.modal-content {
  background: white;
  border-radius: 16px;
  width: 100%;
  max-width: 500px;
  max-height: 80vh;
  max-height: calc(var(--viewport-height, 100vh) * 0.8); /* Dynamic viewport */
  overflow: hidden;
  display: flex;
  flex-direction: column;
  box-shadow: 0 20px 50px rgba(0, 0, 0, 0.3);
  touch-action: pan-y; /* Allow vertical scrolling within modal */
  overscroll-behavior: contain; /* Prevent scroll chaining to body */
  isolation: isolate; /* Create stacking context */
}

.modal-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 1.5rem;
  border-bottom: 1px solid #e5e7eb;
  background: #f9fafb;
  flex-shrink: 0; /* Prevent header from shrinking */
}

.modal-header h2 {
  margin: 0;
  font-size: 1.25rem;
  font-weight: 600;
  color: #1f2937;
}

.close-button {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 32px;
  height: 32px;
  border: none;
  background: transparent;
  color: #6b7280;
  cursor: pointer;
  border-radius: 6px;
  transition: all 0.2s;
  touch-action: manipulation;
  -webkit-tap-highlight-color: transparent;
}

.close-button:hover {
  background: #e5e7eb;
  color: #1f2937;
}

.close-button:active {
  transform: scale(0.95);
}

/* Language Grid */
.language-grid {
  padding: 1.5rem;
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(160px, 1fr));
  gap: 1.25rem;
  max-height: calc(80vh - 100px);
  max-height: calc(var(--viewport-height, 100vh) * 0.8 - 100px); /* Dynamic viewport */
  overflow-y: auto;
  -webkit-overflow-scrolling: touch; /* Smooth iOS scrolling */
  overscroll-behavior: contain; /* Prevent pull-to-refresh */
  background: #f9fafb;
  flex: 1; /* Allow grid to take remaining space */
  min-height: 0; /* Important for flex children to scroll */
}

.language-option {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 0.625rem;
  padding: 1.5rem 1.25rem;
  border: 2px solid #e5e7eb;
  border-radius: 12px;
  background: white;
  cursor: pointer;
  transition: all 0.2s;
  position: relative;
  min-height: 100px; /* Increased minimum height */
  touch-action: manipulation; /* Disable double-tap zoom */
  -webkit-tap-highlight-color: transparent;
}

.language-option:hover {
  border-color: #3b82f6;
  background: #eff6ff;
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(59, 130, 246, 0.15);
}

.language-option:active {
  transform: translateY(0);
}

.language-option.active {
  border-color: #3b82f6;
  background: linear-gradient(135deg, #eff6ff, #dbeafe);
}

.language-option .flag {
  font-size: 3rem;
  line-height: 1;
  filter: drop-shadow(0 2px 4px rgba(0, 0, 0, 0.1));
  transition: opacity 0.2s;
}

.language-option .name {
  font-size: 16px; /* Minimum 16px to prevent iOS zoom */
  font-weight: 600;
  color: #1f2937;
  text-align: center;
  line-height: 1.3;
}

.check-icon {
  position: absolute;
  top: 0.5rem;
  right: 0.5rem;
  color: #3b82f6;
  font-size: 1rem;
  font-weight: bold;
}

.translation-badge {
  position: absolute;
  bottom: 0.5rem;
  right: 0.5rem;
  display: flex;
  align-items: center;
  justify-content: center;
  width: 22px;
  height: 22px;
  background: linear-gradient(135deg, #10b981, #059669);
  border-radius: 50%;
  color: white;
  font-size: 0.75rem;
  box-shadow: 0 2px 6px rgba(16, 185, 129, 0.3);
  transition: all 0.2s ease;
}

.language-option:hover .translation-badge {
  transform: scale(1.15);
  box-shadow: 0 3px 8px rgba(16, 185, 129, 0.4);
}

.translation-badge i {
  font-size: 0.7rem;
  font-weight: 600;
}

/* Scrollbar Styling */
.language-grid::-webkit-scrollbar {
  width: 8px;
}

.language-grid::-webkit-scrollbar-track {
  background: #f3f4f6;
  border-radius: 4px;
}

.language-grid::-webkit-scrollbar-thumb {
  background: #d1d5db;
  border-radius: 4px;
}

.language-grid::-webkit-scrollbar-thumb:hover {
  background: #9ca3af;
}

/* Modal Transition */
.modal-enter-active,
.modal-leave-active {
  transition: opacity 0.3s ease;
}

.modal-enter-from,
.modal-leave-to {
  opacity: 0;
}

.modal-enter-active .modal-content,
.modal-leave-active .modal-content {
  transition: transform 0.3s cubic-bezier(0.4, 0, 0.2, 1);
}

.modal-enter-from .modal-content,
.modal-leave-to .modal-content {
  transform: scale(0.9) translateY(20px);
}

/* Mobile Responsive */
@media (max-width: 640px) {
  .modal-overlay {
    padding: 0;
    align-items: flex-end;
  }
  
  .modal-content {
    border-radius: 20px 20px 0 0;
    max-height: 90vh;
    max-height: calc(var(--viewport-height, 100vh) * 0.9); /* Dynamic viewport */
    width: 100%;
    max-width: 100%;
  }
  
  .modal-header {
    position: relative;
    padding: 1.25rem 1.5rem;
  }
  
  /* Pull handle indicator for mobile */
  .modal-header::before {
    content: '';
    position: absolute;
    top: 0.75rem;
    left: 50%;
    transform: translateX(-50%);
    width: 40px;
    height: 4px;
    background: #d1d5db;
    border-radius: 2px;
  }
  
  .modal-header h2 {
    margin-top: 0.5rem;
  }
  
  .close-button {
    margin-top: 0.5rem;
  }
  
  .language-grid {
    grid-template-columns: repeat(2, 1fr);
    padding: 1rem;
    padding-bottom: max(1rem, env(safe-area-inset-bottom)); /* Safe area for home indicator */
    max-height: calc(90vh - 100px); /* Recalculate for mobile modal height */
    max-height: calc(var(--viewport-height, 100vh) * 0.9 - 100px); /* Dynamic viewport */
  }
  
  .language-option {
    padding: 1.25rem 1rem;
  }
  
  .language-option .flag {
    font-size: 2.5rem;
  }
  
  .modal-enter-from .modal-content,
  .modal-leave-to .modal-content {
    transform: translateY(100%);
  }
}

@media (min-width: 640px) and (max-width: 768px) {
  .language-grid {
    grid-template-columns: repeat(3, 1fr);
  }
}

@media (min-width: 768px) {
  /* Remove pull handle on desktop */
  .modal-header::before {
    display: none;
  }
  
  .modal-header h2,
  .close-button {
    margin-top: 0;
  }
  
  .language-grid {
    grid-template-columns: repeat(3, 1fr);
  }
}

/* Accessibility */
@media (prefers-reduced-motion: reduce) {
  .modal-enter-active,
  .modal-leave-active,
  .modal-enter-active .modal-content,
  .modal-leave-active .modal-content,
  .language-option,
  .language-button,
  .close-button {
    transition: none;
  }
  
  .language-option:hover {
    transform: none;
  }
}
</style>

