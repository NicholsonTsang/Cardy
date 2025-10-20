<template>
  <div class="dashboard-language-selector">
    <!-- Language Button -->
    <button 
      @click="showModal = true" 
      class="language-button"
      :title="$t('common.select_language')"
    >
      <span class="language-flag">{{ languageStore.selectedLanguage.flag }}</span>
      <span class="language-name">{{ languageStore.selectedLanguage.name }}</span>
      <i class="pi pi-chevron-down language-icon"></i>
    </button>

    <!-- Language Selection Modal -->
    <Teleport to="body">
      <Transition name="modal">
        <div v-if="showModal" class="modal-overlay" @click="showModal = false">
          <div class="modal-content" @click.stop>
            <div class="modal-header">
              <div class="header-indicator"></div>
              <h2>{{ $t('common.select_language') }}</h2>
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
                <i v-if="languageStore.selectedLanguage.code === lang.code" class="pi pi-check checkmark" />
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
import { useDashboardLanguageStore } from '@/stores/language'
import type { Language } from '@/stores/language'

const languageStore = useDashboardLanguageStore()
const showModal = ref(false)

function selectLanguage(language: Language) {
  languageStore.setLanguage(language)
  showModal.value = false
}
</script>

<style scoped>
.dashboard-language-selector {
  position: relative;
}

/* Language Button */
.language-button {
  display: flex;
  align-items: center;
  gap: 0.375rem;
  padding: 0.375rem 0.625rem;
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  color: #334155;
  cursor: pointer;
  transition: all 0.2s;
  font-size: 0.875rem;
  font-weight: 500;
}

@media (min-width: 640px) {
  .language-button {
    gap: 0.5rem;
    padding: 0.5rem 0.875rem;
  }
}

.language-button:hover {
  background: #f1f5f9;
  border-color: #cbd5e1;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05);
}

.language-button:active {
  transform: scale(0.98);
}

.language-flag {
  font-size: 1rem;
  line-height: 1;
}

@media (min-width: 640px) {
  .language-flag {
    font-size: 1.125rem;
  }
}

.language-name {
  font-weight: 600;
  font-size: 0.75rem;
  color: #475569;
  white-space: nowrap;
}

@media (min-width: 640px) {
  .language-name {
    font-size: 0.8125rem;
  }
}

.language-icon {
  font-size: 0.625rem;
  color: #94a3b8;
  transition: transform 0.2s;
}

.language-button:hover .language-icon {
  color: #64748b;
}

/* Modal Overlay */
.modal-overlay {
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.5);
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
  max-width: 600px;
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
  position: relative;
}

.header-indicator {
  display: none;
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
  grid-template-columns: repeat(3, 1fr);
  gap: 1rem;
  max-height: calc(80vh - 120px);
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

.language-option .checkmark {
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

/* Mobile - Bottom Sheet */
@media (max-width: 767px) {
  .modal-overlay {
    align-items: flex-end;
    padding: 0;
  }
  
  .modal-content {
    border-radius: 20px 20px 0 0;
    max-width: 100%;
    max-height: 85vh;
  }
  
  .header-indicator {
    display: block;
    position: absolute;
    top: 0.75rem;
    left: 50%;
    transform: translateX(-50%);
    width: 40px;
    height: 4px;
    background: #d1d5db;
    border-radius: 2px;
  }
  
  .modal-header h2,
  .close-button {
    margin-top: 0.5rem;
  }
  
  .language-grid {
    grid-template-columns: repeat(2, 1fr);
  }
  
  .modal-enter-from .modal-content,
  .modal-leave-to .modal-content {
    transform: translateY(100%);
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

/* Focus styles */
.language-button:focus-visible,
.close-button:focus-visible,
.language-option:focus-visible {
  outline: 2px solid #3b82f6;
  outline-offset: 2px;
}
</style>

