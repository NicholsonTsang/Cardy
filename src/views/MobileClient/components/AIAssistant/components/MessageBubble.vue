<template>
  <div class="message" :class="message.role">
    <div 
      class="message-avatar" 
      :class="{ 'message-avatar-pulse': message.isStreaming && message.role === 'assistant' }"
    >
      <i :class="message.role === 'user' ? 'pi pi-user' : 'pi pi-sparkles'" />
    </div>
    
    <div class="message-content">
      <div class="message-bubble">
        <!-- Text content -->
        <p v-if="message.content !== undefined" class="message-text">
          {{ message.content }}
          <span v-if="message.isStreaming" class="streaming-cursor">▊</span>
        </p>
        
        <!-- Voice indicator for user messages -->
        <div v-if="message.audio && message.role === 'user'" class="audio-indicator">
          <i class="pi pi-microphone" />
          <span>Voice message</span>
        </div>
        
        <!-- Audio playback button for assistant messages -->
        <div v-if="message.role === 'assistant' && message.content && !message.isStreaming" class="audio-section">
          <button 
            @click="$emit('play-audio', message)"
            class="audio-play-button"
            :class="{ 'playing': isPlaying, 'loading': message.audioLoading }"
            :disabled="message.audioLoading"
            :title="message.audioLoading ? 'Generating audio...' : isPlaying ? 'Playing...' : 'Play audio'"
          >
            <i v-if="message.audioLoading" class="pi pi-spin pi-spinner" />
            <i v-else-if="isPlaying" class="pi pi-volume-up" />
            <i v-else class="pi pi-volume-off" />
          </button>
          
          <!-- Audio hint for first message -->
          <span v-if="showAudioHint" class="audio-hint">
            Tap to hear
          </span>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import type { Message } from '../types'

const props = defineProps<{
  message: Message
  isPlaying: boolean
  showAudioHint: boolean
}>()

defineEmits<{
  (e: 'play-audio', message: Message): void
}>()
</script>

<style scoped>
.message {
  display: flex;
  gap: 0.75rem;
  margin-bottom: 1rem;
  animation: fadeIn 0.2s ease-in-out;
}

@keyframes fadeIn {
  from {
    opacity: 0;
    transform: translateY(10px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.message.user {
  flex-direction: row-reverse;
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

.user .message-avatar {
  background: linear-gradient(135deg, #3b82f6 0%, #2563eb 100%);
}

.message-content {
  flex: 1;
  max-width: 75%;
}

.message-bubble {
  display: flex;
  flex-direction: column;
  gap: 0.35rem;
  padding: 0.875rem 1rem;
  border-radius: 16px;
  background: white;
  box-shadow: 0 1px 2px rgba(0, 0, 0, 0.05);
}

.user .message-bubble {
  background: linear-gradient(135deg, #3b82f6 0%, #2563eb 100%);
  color: white;
  margin-left: auto;
}

.message-text {
  margin: 0;
  line-height: 1.5;
  word-wrap: break-word;
}

.streaming-cursor {
  display: inline-block;
  animation: blink 1s step-start infinite;
  margin-left: 2px;
}

@keyframes blink {
  50% {
    opacity: 0;
  }
}

.audio-indicator {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  color: white;
  font-size: 0.875rem;
  opacity: 0.9;
}

.audio-section {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  margin-top: 0.25rem;
}

.audio-play-button {
  background: none;
  border: none;
  color: #6b7280;
  cursor: pointer;
  font-size: 1.25rem;
  transition: all 0.2s;
  padding: 0;
  display: flex;
  align-items: center;
}

.audio-play-button:hover:not(:disabled) {
  color: #3b82f6;
  transform: scale(1.1);
}

.audio-play-button:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.audio-play-button.playing {
  color: #3b82f6;
}

.audio-play-button.loading {
  opacity: 0.6;
}

.audio-hint {
  font-size: 0.75rem;
  color: #9ca3af;
  font-style: italic;
  animation: fadeInHint 0.5s ease-in-out;
}

@keyframes fadeInHint {
  from {
    opacity: 0;
  }
  to {
    opacity: 1;
  }
}

@media (max-width: 640px) {
  .message-content {
    max-width: 85%;
  }
}
</style>

