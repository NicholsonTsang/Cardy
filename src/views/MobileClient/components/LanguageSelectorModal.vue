<template>
  <!-- Language Selection Modal -->
  <Teleport to="body">
    <Transition name="modal">
      <div class="modal-overlay" @click="$emit('close')">
        <div class="modal-content" @click.stop>
          <div class="modal-header">
            <h2>{{ $t('mobile.select_language') }}</h2>
            <button @click="$emit('close')" class="close-button">
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
                disabled: !isLanguageAvailable(lang.code)
              }"
              :disabled="!isLanguageAvailable(lang.code)"
            >
              <span class="flag" :class="{ 'opacity-30': !isLanguageAvailable(lang.code) }">{{ lang.flag }}</span>
              <span class="name">{{ lang.name }}</span>
              <i v-if="languageStore.selectedLanguage.code === lang.code" class="pi pi-check" />
              <i v-if="!isLanguageAvailable(lang.code)" class="pi pi-lock disabled-icon" />
            </button>
          </div>
        </div>
      </div>
    </Transition>
  </Teleport>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { useMobileLanguageStore } from '@/stores/language'
import type { Language } from '@/stores/language'

interface Props {
  availableLanguages?: string[] // Language codes available for this card
}

const props = defineProps<Props>()
const languageStore = useMobileLanguageStore()

const emit = defineEmits<{
  select: [language: Language]
  close: []
}>()

// Check if a language is available for this card
const isLanguageAvailable = (langCode: string) => {
  if (!props.availableLanguages || props.availableLanguages.length === 0) {
    return true // If no restriction, all languages available
  }
  return props.availableLanguages.includes(langCode)
}

function selectLanguage(language: Language) {
  // Don't allow selection of unavailable languages
  if (!isLanguageAvailable(language.code)) {
    return
  }
  
  // Mark that user has manually selected a language
  // This prevents the app from resetting to card's original language
  sessionStorage.setItem('userSelectedLanguage', 'true')
  
  languageStore.setLanguage(language)
  emit('select', language)
  emit('close')
}
</script>

<style scoped>
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
}

.modal-content {
  background: white;
  border-radius: 16px;
  width: 100%;
  max-width: 500px;
  max-height: 80vh;
  overflow: hidden;
  display: flex;
  flex-direction: column;
  box-shadow: 0 20px 50px rgba(0, 0, 0, 0.3);
}

.modal-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 1.5rem;
  border-bottom: 1px solid #e5e7eb;
  background: #f9fafb;
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
  grid-template-columns: repeat(auto-fill, minmax(140px, 1fr));
  gap: 1rem;
  max-height: calc(80vh - 100px);
  overflow-y: auto;
  background: #f9fafb;
}

.language-option {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 0.5rem;
  padding: 1.25rem 1rem;
  border: 2px solid #e5e7eb;
  border-radius: 12px;
  background: white;
  cursor: pointer;
  transition: all 0.2s;
  position: relative;
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

.language-option.disabled {
  opacity: 0.5;
  cursor: not-allowed;
  background: #f3f4f6;
}

.language-option.disabled:hover {
  border-color: #e5e7eb;
  background: #f3f4f6;
  transform: none;
  box-shadow: none;
}

.disabled-icon {
  position: absolute;
  top: 0.5rem;
  right: 0.5rem;
  color: #9ca3af;
  font-size: 0.875rem;
}

.language-option .flag {
  font-size: 2.5rem;
  line-height: 1;
  filter: drop-shadow(0 2px 4px rgba(0, 0, 0, 0.1));
}

.language-option .name {
  font-size: 0.875rem;
  font-weight: 600;
  color: #1f2937;
  text-align: center;
  line-height: 1.3;
}

.language-option .pi-check {
  position: absolute;
  top: 0.5rem;
  right: 0.5rem;
  color: #3b82f6;
  font-size: 1rem;
  font-weight: bold;
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
  }
  
  .modal-content {
    border-radius: 20px 20px 0 0;
    max-height: 90vh;
    align-self: flex-end;
    width: 100%;
  }
  
  .language-grid {
    grid-template-columns: repeat(2, 1fr);
    padding: 1rem;
  }
  
  .language-option {
    padding: 1rem 0.75rem;
  }
  
  .language-option .flag {
    font-size: 2rem;
  }
  
  .modal-enter-from .modal-content,
  .modal-leave-to .modal-content {
    transform: translateY(100%);
  }
}

@media (min-width: 640px) {
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
  .language-option {
    transition: none;
  }
  
  .language-option:hover {
    transform: none;
  }
}
</style>

