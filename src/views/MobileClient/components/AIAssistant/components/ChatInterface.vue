<template>
  <div class="chat-container">
    <!-- Messages -->
    <div ref="messagesContainer" class="messages-container">
      <MessageBubble
        v-for="message in messages"
        :key="message.id"
        :message="message"
        :is-playing="currentPlayingMessageId === message.id"
        :show-audio-hint="showAudioHint(message)"
        @play-audio="$emit('play-audio', message)"
      />
      
      <!-- Loading Indicator (only if not streaming) -->
      <div v-if="isLoading && !hasStreaming" class="message assistant">
        <div class="message-avatar message-avatar-pulse">
          <i class="pi pi-sparkles" />
        </div>
        <div class="message-content">
          <div class="message-bubble">
            <div class="typing-dots">
              <span></span>
              <span></span>
              <span></span>
            </div>
            <p v-if="loadingStatus" class="loading-status">{{ loadingStatus }}</p>
          </div>
        </div>
      </div>
    </div>

    <!-- Error Message -->
    <div v-if="error" class="error-banner">
      <i class="pi pi-exclamation-triangle" />
      <p>{{ error }}</p>
    </div>

    <!-- Input Area -->
    <div class="input-area">
      <div class="input-container">
        <!-- Text Mode -->
        <template v-if="inputMode === 'text'">
          <button 
            @click="$emit('toggle-input-mode')" 
            class="input-icon-button"
            :title="$t('mobile.switch_to_voice')"
          >
            <i class="pi pi-microphone" />
          </button>
          
          <input 
            v-model="textInput"
            type="text"
            :placeholder="$t('mobile.type_message')"
            class="text-input"
            @keypress.enter="handleSendText"
            :disabled="isLoading"
          />
          
          <button 
            @click="handleSendText"
            class="input-icon-button send-icon"
            :disabled="!textInput.trim() || isLoading"
          >
            <i class="pi pi-send" />
          </button>
        </template>

        <!-- Voice Mode -->
        <template v-else>
          <VoiceInputButton
            :is-recording="isRecording"
            :recording-duration="recordingDuration"
            :is-cancel-zone="isCancelZone"
            :waveform-data="waveformData"
            :disabled="isLoading"
            @start-recording="$emit('start-recording')"
            @stop-recording="$emit('stop-recording')"
            @cancel-recording="$emit('cancel-recording')"
            @toggle-mode="$emit('toggle-input-mode')"
            @update-cancel-zone="$emit('update-cancel-zone', $event)"
          />
        </template>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, watch, nextTick } from 'vue'
import { useI18n } from 'vue-i18n'
import MessageBubble from './MessageBubble.vue'
import VoiceInputButton from './VoiceInputButton.vue'
import type { Message } from '../types'

const { t } = useI18n()

const props = defineProps<{
  messages: Message[]
  isLoading: boolean
  error: string | null
  loadingStatus: string
  inputMode: 'text' | 'voice'
  isRecording: boolean
  recordingDuration: number
  isCancelZone: boolean
  waveformData: Uint8Array | null
  currentPlayingMessageId: string | null
  firstAudioPlayed: boolean
}>()

const emit = defineEmits<{
  (e: 'send-text', text: string): void
  (e: 'toggle-input-mode'): void
  (e: 'start-recording'): void
  (e: 'stop-recording'): void
  (e: 'cancel-recording'): void
  (e: 'update-cancel-zone', value: boolean): void
  (e: 'play-audio', message: Message): void
}>()

const textInput = ref('')
const messagesContainer = ref<HTMLDivElement | null>(null)

const hasStreaming = computed(() => 
  props.messages.some(m => m.isStreaming)
)

function showAudioHint(message: Message): boolean {
  return !props.firstAudioPlayed && 
         message.role === 'assistant' && 
         props.messages.indexOf(message) === 1 && // First AI response
         !message.isStreaming
}

function handleSendText() {
  const text = textInput.value.trim()
  if (text && !props.isLoading) {
    emit('send-text', text)
    textInput.value = ''
  }
}

// Auto-scroll to bottom
watch(() => props.messages.length, async () => {
  await nextTick()
  if (messagesContainer.value) {
    messagesContainer.value.scrollTop = messagesContainer.value.scrollHeight
  }
})
</script>

<style scoped>
.chat-container {
  display: flex;
  flex-direction: column;
  height: 100%;
  background: #f9fafb;
}

.messages-container {
  flex: 1;
  overflow-y: auto;
  padding: 1.5rem;
  display: flex;
  flex-direction: column;
}

.error-banner {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  padding: 1rem;
  background: #fef2f2;
  border: 1px solid #fecaca;
  border-radius: 8px;
  color: #991b1b;
  margin: 0 1rem 1rem;
}

.input-area {
  padding: 1rem;
  background: white;
  border-top: 1px solid #e5e7eb;
}

.input-container {
  display: flex;
  gap: 0.75rem;
  align-items: center;
}

.text-input {
  flex: 1;
  padding: 0.875rem 1rem;
  border: 2px solid #e5e7eb;
  border-radius: 12px;
  font-size: 1rem;
  outline: none;
  transition: border-color 0.2s;
}

.text-input:focus {
  border-color: #3b82f6;
}

.text-input:disabled {
  background: #f3f4f6;
  cursor: not-allowed;
}

.input-icon-button {
  width: 48px;
  height: 48px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: white;
  border: 2px solid #e5e7eb;
  border-radius: 12px;
  color: #6b7280;
  font-size: 1.25rem;
  cursor: pointer;
  transition: all 0.2s;
  flex-shrink: 0;
}

.input-icon-button:hover:not(:disabled) {
  background: #f9fafb;
  border-color: #3b82f6;
  color: #3b82f6;
}

.input-icon-button:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.input-icon-button.send-icon:not(:disabled) {
  background: linear-gradient(135deg, #3b82f6 0%, #2563eb 100%);
  color: white;
  border-color: transparent;
}

.input-icon-button.send-icon:hover:not(:disabled) {
  background: linear-gradient(135deg, #2563eb 0%, #1d4ed8 100%);
}

/* Loading Indicator Styles (for non-streaming) */
.message {
  display: flex;
  gap: 0.75rem;
  margin-bottom: 1rem;
}

.message-avatar {
  width: 32px;
  height: 32px;
  border-radius: 50%;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  font-size: 0.875rem;
}

.message-avatar-pulse {
  animation: pulse 1.5s ease-in-out infinite;
}

@keyframes pulse {
  0%, 100% {
    transform: scale(1);
    opacity: 1;
  }
  50% {
    transform: scale(1.05);
    opacity: 0.9;
  }
}

.message-content {
  flex: 1;
  max-width: 75%;
}

.message-bubble {
  padding: 0.875rem 1rem;
  border-radius: 16px;
  background: white;
  box-shadow: 0 1px 2px rgba(0, 0, 0, 0.05);
}

.typing-dots {
  display: flex;
  gap: 0.5rem;
  margin-bottom: 0.5rem;
}

.typing-dots span {
  width: 8px;
  height: 8px;
  background: #9ca3af;
  border-radius: 50%;
  animation: typingDots 1.4s ease-in-out infinite;
}

.typing-dots span:nth-child(2) {
  animation-delay: 0.2s;
}

.typing-dots span:nth-child(3) {
  animation-delay: 0.4s;
}

@keyframes typingDots {
  0%, 60%, 100% {
    transform: translateY(0);
    opacity: 0.7;
  }
  30% {
    transform: translateY(-10px);
    opacity: 1;
  }
}

.loading-status {
  margin: 0;
  font-size: 0.875rem;
  color: #6b7280;
}

@media (max-width: 640px) {
  .messages-container {
    padding: 1rem;
  }
  
  .input-area {
    padding: 0.75rem;
  }
}
</style>

