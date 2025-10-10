<template>
  <div class="language-selector">
    <!-- Language Button in Header -->
    <button @click="showModal = true" class="language-button" :title="$t('mobile.selectLanguage')">
      <span class="language-flag">{{ languageStore.selectedLanguage.flag }}</span>
      <span class="language-code">{{ languageStore.selectedLanguage.code.toUpperCase() }}</span>
    </button>

    <!-- Language Selection Modal -->
    <Teleport to="body">
      <Transition name="modal">
        <div v-if="showModal" class="modal-overlay" @click="showModal = false">
          <div class="modal-content" @click.stop>
            <div class="modal-header">
              <h2>{{ $t('mobile.selectLanguage') }}</h2>
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
import { useLanguageStore } from '@/stores/language'
import type { Language } from '@/stores/language'

const languageStore = useLanguageStore()
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
  align-items: center;
  justify-content: center;
  z-index: 9999;
  padding: 1rem;
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
}

.modal-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 1.5rem;
  border-bottom: 1px solid #e5e7eb;
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
  background: #f3f4f6;
  color: #1f2937;
}

/* Language Grid */
.language-grid {
  padding: 1rem;
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(140px, 1fr));
  gap: 0.75rem;
  max-height: calc(80vh - 100px);
  overflow-y: auto;
}

.language-option {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 0.5rem;
  padding: 1rem;
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
}

.language-option.active {
  border-color: #3b82f6;
  background: #eff6ff;
}

.language-option .flag {
  font-size: 2rem;
  line-height: 1;
}

.language-option .name {
  font-size: 0.875rem;
  font-weight: 500;
  color: #1f2937;
  text-align: center;
}

.language-option .pi-check {
  position: absolute;
  top: 0.5rem;
  right: 0.5rem;
  color: #3b82f6;
  font-size: 0.875rem;
}

/* Modal Transition */
.modal-enter-active,
.modal-leave-active {
  transition: opacity 0.3s;
}

.modal-enter-from,
.modal-leave-to {
  opacity: 0;
}

.modal-enter-active .modal-content,
.modal-leave-active .modal-content {
  transition: transform 0.3s;
}

.modal-enter-from .modal-content,
.modal-leave-to .modal-content {
  transform: scale(0.9);
}

/* Mobile Responsive */
@media (max-width: 640px) {
  .language-grid {
    grid-template-columns: repeat(2, 1fr);
  }
  
  .modal-content {
    max-height: 90vh;
  }
}
</style>

