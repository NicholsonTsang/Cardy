<template>
  <div class="voice-selector">
    <button @click="showModal = true" class="voice-button" v-if="languageStore.isChinese(languageStore.selectedLanguage.code)">
      <i class="pi pi-volume-up" />
      <span class="voice-label">{{ currentVoiceLabel }}</span>
    </button>

    <!-- Voice Selection Modal -->
    <Teleport to="body">
      <Transition name="modal">
        <div v-if="showModal" class="modal-overlay" @click="showModal = false">
          <div class="modal-content" @click.stop>
            <div class="modal-header">
              <h2>{{ $t('mobile.select_chinese_voice') }}</h2>
              <button @click="showModal = false" class="close-button">
                <i class="pi pi-times" />
              </button>
            </div>

            <div class="voice-info">
              <p>{{ $t('mobile.chinese_voice_description') }}</p>
            </div>

            <div class="voice-options">
              <button
                v-for="option in languageStore.chineseVoiceOptions"
                :key="option.value"
                @click="selectVoice(option.value)"
                class="voice-option"
                :class="{ active: languageStore.chineseVoice === option.value }"
              >
                <div class="voice-option-content">
                  <div class="voice-names">
                    <span class="voice-name">{{ option.name }}</span>
                    <span class="voice-native">{{ option.nativeName }}</span>
                  </div>
                  <p class="voice-description">{{ option.description }}</p>
                </div>
                <i v-if="languageStore.chineseVoice === option.value" class="pi pi-check" />
              </button>
            </div>
          </div>
        </div>
      </Transition>
    </Teleport>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { useMobileLanguageStore } from '@/stores/language'
import type { ChineseVoice } from '@/stores/language'

const languageStore = useMobileLanguageStore()
const showModal = ref(false)

const currentVoiceLabel = computed(() => {
  const option = languageStore.chineseVoiceOptions.find(opt => opt.value === languageStore.chineseVoice)
  return option ? option.nativeName : ''
})

function selectVoice(voice: ChineseVoice) {
  languageStore.setChineseVoice(voice)
  showModal.value = false
}
</script>

<style scoped>
.voice-selector {
  position: relative;
}

.voice-button {
  display: flex;
  align-items: center;
  gap: 0.375rem;
  padding: 0.375rem 0.625rem;
  background: rgba(255, 255, 255, 0.1);
  border: 1px solid rgba(255, 255, 255, 0.2);
  border-radius: 6px;
  color: white;
  cursor: pointer;
  transition: all 0.2s;
  font-size: 0.8125rem;
}

.voice-button:hover {
  background: rgba(255, 255, 255, 0.2);
  border-color: rgba(255, 255, 255, 0.3);
}

.voice-button i {
  font-size: 0.875rem;
}

.voice-label {
  font-weight: 500;
  font-size: 0.75rem;
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
  max-height: 70vh;
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
  font-size: 1.125rem;
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

/* Voice Info */
.voice-info {
  padding: 1rem 1.5rem;
  background: #eff6ff;
  border-bottom: 1px solid #dbeafe;
}

.voice-info p {
  margin: 0;
  font-size: 0.875rem;
  color: #1e40af;
  line-height: 1.5;
}

/* Voice Options */
.voice-options {
  padding: 1.5rem;
  display: flex;
  flex-direction: column;
  gap: 0.875rem;
  overflow-y: auto;
}

.voice-option {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 1rem;
  padding: 1.25rem;
  border: 2px solid #e5e7eb;
  border-radius: 12px;
  background: white;
  cursor: pointer;
  transition: all 0.2s;
  position: relative;
  text-align: left;
}

.voice-option:hover {
  border-color: #3b82f6;
  background: #eff6ff;
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(59, 130, 246, 0.15);
}

.voice-option:active {
  transform: translateY(0);
}

.voice-option.active {
  border-color: #3b82f6;
  background: linear-gradient(135deg, #eff6ff, #dbeafe);
}

.voice-option-content {
  flex: 1;
}

.voice-names {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  margin-bottom: 0.375rem;
}

.voice-name {
  font-size: 1rem;
  font-weight: 600;
  color: #1f2937;
}

.voice-native {
  font-size: 0.9375rem;
  font-weight: 600;
  color: #4b5563;
}

.voice-description {
  margin: 0;
  font-size: 0.8125rem;
  color: #6b7280;
  line-height: 1.4;
}

.voice-option .pi-check {
  color: #3b82f6;
  font-size: 1.25rem;
  font-weight: bold;
  flex-shrink: 0;
}

/* Scrollbar Styling */
.voice-options::-webkit-scrollbar {
  width: 8px;
}

.voice-options::-webkit-scrollbar-track {
  background: #f3f4f6;
  border-radius: 4px;
}

.voice-options::-webkit-scrollbar-thumb {
  background: #d1d5db;
  border-radius: 4px;
}

.voice-options::-webkit-scrollbar-thumb:hover {
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
    max-width: 500px;
    max-height: 70vh;
    box-shadow: 0 20px 50px rgba(0, 0, 0, 0.3);
  }
  
  .modal-header::before {
    display: none;
  }
  
  .modal-header h2,
  .close-button {
    margin-top: 0;
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
  .voice-option {
    transition: none;
  }
  
  .voice-option:hover {
    transform: none;
  }
}
</style>

