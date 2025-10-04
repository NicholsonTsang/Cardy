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
                class="mode-switch-button"
                :class="{ 'active': conversationMode === 'realtime' }"
                :title="conversationMode === 'realtime' ? 'Switch to Chat' : 'Switch to Live Call'"
              >
                <i :class="conversationMode === 'realtime' ? 'pi pi-comments' : 'pi pi-phone'" />
              </button>
              <button @click="$emit('close')" class="close-button">
                <i class="pi pi-times" />
              </button>
            </div>
          </div>

          <!-- Content -->
          <slot />
        </template>
      </div>
    </div>
  </Teleport>
</template>

<script setup lang="ts">
import LanguageSelector from './LanguageSelector.vue'
import type { ConversationMode, Language } from '../types'

defineProps<{
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
}

.mode-switch-button,
.close-button {
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
}

.mode-switch-button:hover,
.close-button:hover {
  background: #e5e7eb;
  color: #374151;
}

.mode-switch-button.active {
  background: #dbeafe;
  color: #3b82f6;
}

@media (max-width: 640px) {
  .modal-overlay {
    padding: 0;
  }
  
  .modal-content {
    max-width: 100%;
    max-height: 100vh;
    border-radius: 0;
    height: 100vh;
  }
}
</style>

