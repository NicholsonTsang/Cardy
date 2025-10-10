<template>
  <div class="language-selector">
    <!-- Language Button in Header -->
    <button @click="showModal = true" class="language-button" :title="$t('mobile.select_language')">
      <span class="language-flag">{{ languageStore.selectedLanguage.flag }}</span>
      <span class="language-code">{{ languageStore.selectedLanguage.code.toUpperCase() }}</span>
    </button>

    <!-- Language Selection Modal -->
    <Teleport to="body">
      <Transition name="modal">
        <div v-if="showModal" class="modal-overlay" @click="showModal = false">
          <div class="modal-content" @click.stop>
            <div class="modal-header">
              <h2>{{ $t('mobile.select_language') }}</h2>
              <button @click="showModal = false" class="close-button">
                <i class="pi pi-times" />
              </button>
            </div>

            <div class="language-grid">
              <button
                v-for="lang in languageStore.languages"
                :key="lang.code"
                @click="selectLanguage(lang)"
                class="language-option"
                :class="{ active: languageStore.selectedLanguage.code === lang.code }"
              >
                <span class="flag">{{ lang.flag }}</span>
                <span class="name">{{ lang.name }}</span>
                <i v-if="languageStore.selectedLanguage.code === lang.code" class="pi pi-check" />
              </button>
            </div>
          </div>
        </div>
      </Transition>
    </Teleport>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { useMobileLanguageStore } from '@/stores/language'
import type { Language } from '@/stores/language'

const languageStore = useMobileLanguageStore()
const showModal = ref(false)

function selectLanguage(language: Language) {
  languageStore.setLanguage(language)
  showModal.value = false
}
</script>

<style scoped>
.language-selector {
  position: relative;
}

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
}

.language-button:hover {
  background: rgba(255, 255, 255, 0.2);
  border-color: rgba(255, 255, 255, 0.3);
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
  align-items: flex-end;
  justify-content: center;
  z-index: 9999;
  backdrop-filter: blur(4px);
  -webkit-backdrop-filter: blur(4px);
}

.modal-content {
  background: white;
  border-radius: 20px 20px 0 0;
  width: 100%;
  max-width: 100%;
  max-height: 85vh;
  overflow: hidden;
  display: flex;
  flex-direction: column;
  box-shadow: 0 -10px 40px rgba(0, 0, 0, 0.3);
}

.modal-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 1.25rem 1.5rem;
  border-bottom: 1px solid #e5e7eb;
  background: #f9fafb;
  position: relative;
}

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
  margin: 0;
  margin-top: 0.5rem;
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
  margin-top: 0.5rem;
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
  grid-template-columns: repeat(2, 1fr);
  gap: 1rem;
  max-height: calc(85vh - 120px);
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
  transform: translateY(100%);
}

/* Desktop - Center Modal */
@media (min-width: 768px) {
  .modal-overlay {
    align-items: center;
    padding: 1rem;
  }
  
  .modal-content {
    border-radius: 16px;
    max-width: 600px;
    max-height: 80vh;
    box-shadow: 0 20px 50px rgba(0, 0, 0, 0.3);
  }
  
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
  
  .modal-enter-from .modal-content,
  .modal-leave-to .modal-content {
    transform: scale(0.9) translateY(20px);
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

