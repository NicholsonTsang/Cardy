<template>
  <div class="chat-container">
    <!-- Messages -->
    <div ref="messagesContainer" class="messages-container">
      <MessageBubble
        v-for="(message, index) in messages"
        :key="message.id"
        :message="message"
        :is-playing="currentPlayingMessageId === message.id"
        :show-audio-hint="showAudioHint(message)"
        @play-audio="$emit('play-audio', message)"
      />
      
      <!-- Loading Indicator (only if not streaming) -->
      <div v-if="isLoading && !hasStreaming" class="message assistant">
        <div class="message-avatar">
          <i class="pi pi-sparkles" />
        </div>
        <div class="message-content">
          <div class="message-bubble loading-bubble">
            <div class="typing-indicator">
              <span></span>
              <span></span>
              <span></span>
            </div>
            <p v-if="loadingStatus" class="loading-status">{{ loadingStatus }}</p>
          </div>
        </div>
      </div>
      
      <!-- Clear Chat Button (after messages) -->
      <div v-if="messages.length > 1" class="clear-chat-wrapper">
        <button 
          @click="$emit('clear-chat')"
          class="clear-chat-button"
        >
          <i class="pi pi-refresh" />
          <span>{{ $t('mobile.clear_chat') }}</span>
        </button>
      </div>
    </div>

    <!-- Error Message -->
    <div v-if="error" class="error-banner">
      <i class="pi pi-exclamation-triangle" />
      <p>{{ error }}</p>
      <button @click="$emit('clear-chat')" class="error-dismiss">
        <i class="pi pi-times" />
      </button>
    </div>

    <!-- Input Area -->
    <div ref="inputAreaRef" class="input-area">
      <div class="input-container">
        <!-- Text Mode -->
        <template v-if="inputMode === 'text'">
          <button 
            @click="$emit('toggle-input-mode')" 
            class="input-mode-button"
            :title="$t('mobile.switch_to_voice')"
          >
            <i class="pi pi-microphone" />
          </button>
          
          <div class="text-input-wrapper">
            <input 
              v-model="textInput"
              type="text"
              :placeholder="$t('mobile.type_message')"
              class="text-input"
              @keypress.enter="handleSendText"
              :disabled="isLoading"
            />
          </div>
          
          <button 
            @click="handleSendText"
            class="send-button"
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
import { ref, computed, watch, nextTick, onMounted, onUnmounted } from 'vue'
import MessageBubble from './MessageBubble.vue'
import VoiceInputButton from './VoiceInputButton.vue'
import type { Message } from '../types'

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
  (e: 'clear-chat'): void
}>()

const textInput = ref('')
const messagesContainer = ref<HTMLDivElement | null>(null)
const inputAreaRef = ref<HTMLDivElement | null>(null)

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

// Auto-scroll to bottom when messages change
async function scrollToBottom() {
  await nextTick()
  if (messagesContainer.value) {
    messagesContainer.value.scrollTop = messagesContainer.value.scrollHeight
  }
}

// Scroll to bottom when messages change
watch(() => props.messages.length, scrollToBottom)

// Scroll when keyboard appears (visual viewport changes)
function handleViewportResize() {
  // Small delay to let layout settle
  setTimeout(scrollToBottom, 100)
}

onMounted(() => {
  if (typeof window !== 'undefined' && window.visualViewport) {
    window.visualViewport.addEventListener('resize', handleViewportResize)
  }
})

onUnmounted(() => {
  if (typeof window !== 'undefined' && window.visualViewport) {
    window.visualViewport.removeEventListener('resize', handleViewportResize)
  }
})
</script>

<style scoped>
.chat-container {
  display: flex;
  flex-direction: column;
  height: 100%;
  background: #0f172a;
  min-height: 0;
}

.messages-container {
  flex: 1 1 auto;
  overflow-y: auto;
  overflow-x: hidden;
  padding: 1.25rem;
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
  -webkit-overflow-scrolling: touch;
  overscroll-behavior: contain;
  min-height: 0;
  /* Custom scrollbar for dark theme */
  scrollbar-width: thin;
  scrollbar-color: rgba(255, 255, 255, 0.15) transparent;
}

.messages-container::-webkit-scrollbar {
  width: 6px;
}

.messages-container::-webkit-scrollbar-track {
  background: transparent;
}

.messages-container::-webkit-scrollbar-thumb {
  background: rgba(255, 255, 255, 0.15);
  border-radius: 3px;
}

.messages-container::-webkit-scrollbar-thumb:hover {
  background: rgba(255, 255, 255, 0.25);
}

/* Loading Indicator */
.message {
  display: flex;
  gap: 0.625rem;
  animation: messageIn 0.25s ease-out;
}

@keyframes messageIn {
  from {
    opacity: 0;
    transform: translateY(8px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.message.assistant {
  align-items: flex-start;
}

.message-avatar {
  width: 32px;
  height: 32px;
  border-radius: 10px;
  background: linear-gradient(135deg, #8b5cf6 0%, #6366f1 100%);
  color: white;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  font-size: 0.875rem;
  box-shadow: 0 2px 8px rgba(139, 92, 246, 0.3);
}

.message-content {
  flex: 1;
  max-width: 80%;
}

.message-bubble {
  padding: 0.875rem 1rem;
  border-radius: 16px;
  border-top-left-radius: 4px;
}

.loading-bubble {
  background: rgba(255, 255, 255, 0.08);
  border: 1px solid rgba(255, 255, 255, 0.1);
}

.typing-indicator {
  display: flex;
  gap: 4px;
  padding: 4px 0;
}

.typing-indicator span {
  width: 8px;
  height: 8px;
  background: rgba(255, 255, 255, 0.4);
  border-radius: 50%;
  animation: typingBounce 1.4s ease-in-out infinite;
}

.typing-indicator span:nth-child(2) {
  animation-delay: 0.15s;
}

.typing-indicator span:nth-child(3) {
  animation-delay: 0.3s;
}

@keyframes typingBounce {
  0%, 60%, 100% {
    transform: translateY(0);
    opacity: 0.4;
  }
  30% {
    transform: translateY(-8px);
    opacity: 1;
  }
}

.loading-status {
  margin: 0.5rem 0 0 0;
  font-size: 0.8125rem;
  color: rgba(255, 255, 255, 0.5);
}

/* Clear Chat Button */
.clear-chat-wrapper {
  display: flex;
  justify-content: center;
  margin-top: 1rem;
  padding-top: 1rem;
  border-top: 1px solid rgba(255, 255, 255, 0.06);
}

.clear-chat-button {
  display: inline-flex;
  align-items: center;
  gap: 0.375rem;
  padding: 0.5rem 0.875rem;
  background: rgba(255, 255, 255, 0.05);
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 8px;
  color: rgba(255, 255, 255, 0.5);
  font-size: 0.8125rem;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s;
}

.clear-chat-button:hover {
  background: rgba(239, 68, 68, 0.15);
  border-color: rgba(239, 68, 68, 0.3);
  color: #fca5a5;
}

.clear-chat-button i {
  font-size: 0.75rem;
}

/* Error Banner */
.error-banner {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  padding: 0.75rem 1rem;
  margin: 0 1rem 0.75rem;
  background: rgba(239, 68, 68, 0.15);
  border: 1px solid rgba(239, 68, 68, 0.3);
  border-radius: 12px;
  color: #fca5a5;
  animation: slideDown 0.2s ease-out;
}

@keyframes slideDown {
  from {
    opacity: 0;
    transform: translateY(-8px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.error-banner i {
  font-size: 1rem;
  color: #f87171;
}

.error-banner p {
  margin: 0;
  flex: 1;
  font-size: 0.875rem;
}

.error-dismiss {
  background: none;
  border: none;
  color: rgba(255, 255, 255, 0.5);
  cursor: pointer;
  padding: 0.25rem;
  font-size: 0.875rem;
  transition: color 0.2s;
}

.error-dismiss:hover {
  color: white;
}

/* Input Area */
.input-area {
  padding: 1rem;
  background: linear-gradient(180deg, #1e293b 0%, #0f172a 100%);
  border-top: 1px solid rgba(255, 255, 255, 0.08);
  flex-shrink: 0;
  flex-grow: 0;
  position: relative;
  z-index: 10;
}

.input-container {
  display: flex;
  gap: 0.625rem;
  align-items: center;
  padding: 0.375rem;
  background: rgba(255, 255, 255, 0.03);
  border-radius: 16px;
  border: 1px solid rgba(255, 255, 255, 0.06);
}

.text-input-wrapper {
  flex: 1;
  position: relative;
}

.text-input {
  width: 100%;
  padding: 0.75rem 1rem;
  background: transparent;
  border: none;
  border-radius: 12px;
  font-size: 16px; /* Minimum 16px to prevent iOS zoom */
  color: white;
  outline: none;
  transition: all 0.2s;
}

.text-input::placeholder {
  color: rgba(255, 255, 255, 0.35);
}

.text-input:focus {
  background: rgba(255, 255, 255, 0.04);
}

.text-input:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.input-mode-button {
  width: 44px;
  height: 44px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: rgba(255, 255, 255, 0.05);
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 12px;
  color: rgba(255, 255, 255, 0.5);
  font-size: 1.125rem;
  cursor: pointer;
  transition: all 0.25s cubic-bezier(0.4, 0, 0.2, 1);
  flex-shrink: 0;
}

.input-mode-button:hover {
  background: rgba(139, 92, 246, 0.15);
  border-color: rgba(139, 92, 246, 0.3);
  color: #c4b5fd;
  transform: scale(1.05);
}

.input-mode-button:active {
  transform: scale(0.95);
}

.send-button {
  width: 44px;
  height: 44px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: linear-gradient(135deg, #6366f1 0%, #8b5cf6 100%);
  border: none;
  border-radius: 12px;
  color: white;
  font-size: 1rem;
  cursor: pointer;
  transition: all 0.25s cubic-bezier(0.4, 0, 0.2, 1);
  flex-shrink: 0;
  box-shadow: 
    0 4px 12px rgba(99, 102, 241, 0.35),
    inset 0 1px 0 rgba(255, 255, 255, 0.2);
  position: relative;
  overflow: hidden;
}

.send-button::before {
  content: '';
  position: absolute;
  inset: 0;
  background: linear-gradient(135deg, rgba(255, 255, 255, 0.15) 0%, transparent 50%);
  opacity: 0;
  transition: opacity 0.25s;
}

.send-button:hover:not(:disabled) {
  background: linear-gradient(135deg, #4f46e5 0%, #7c3aed 100%);
  transform: translateY(-2px) scale(1.02);
  box-shadow: 
    0 8px 20px rgba(99, 102, 241, 0.45),
    inset 0 1px 0 rgba(255, 255, 255, 0.25);
}

.send-button:hover:not(:disabled)::before {
  opacity: 1;
}

.send-button:active:not(:disabled) {
  transform: translateY(0) scale(0.98);
  box-shadow: 0 2px 8px rgba(99, 102, 241, 0.3);
}

.send-button:disabled {
  opacity: 0.35;
  cursor: not-allowed;
  box-shadow: none;
  background: rgba(99, 102, 241, 0.3);
}

/* Mobile Optimizations */
@media (max-width: 640px) {
  .chat-container {
    max-height: 100%;
  }
  
  .messages-container {
    padding: 1rem;
    /* Add subtle gradient at edges to indicate scrollability */
    mask-image: linear-gradient(
      to bottom,
      transparent 0%,
      black 2%,
      black 98%,
      transparent 100%
    );
    -webkit-mask-image: linear-gradient(
      to bottom,
      transparent 0%,
      black 2%,
      black 98%,
      transparent 100%
    );
  }
  
  .input-area {
    padding: 0.75rem;
    padding-bottom: max(0.75rem, env(safe-area-inset-bottom));
    position: sticky;
    bottom: 0;
    box-shadow: 0 -8px 24px rgba(0, 0, 0, 0.3);
  }
  
  .input-container {
    gap: 0.5rem;
    padding: 0.25rem;
  }
  
  .text-input {
    padding: 0.625rem 0.875rem;
    min-height: 44px;
  }
  
  .input-mode-button,
  .send-button {
    width: 44px;
    height: 44px;
  }
}
</style>
