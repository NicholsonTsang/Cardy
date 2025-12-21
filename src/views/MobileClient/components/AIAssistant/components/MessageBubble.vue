<template>
  <div class="message" :class="message.role">
    <!-- Avatar -->
    <div 
      class="message-avatar" 
      :class="{ 'streaming': message.isStreaming && message.role === 'assistant' }"
    >
      <i :class="message.role === 'user' ? 'pi pi-user' : 'pi pi-sparkles'" />
    </div>
    
    <!-- Message Content -->
    <div class="message-content">
      <div class="message-bubble">
        <!-- Text content -->
        <p v-if="message.content !== undefined" class="message-text">
          {{ message.content }}
          <span v-if="message.isStreaming" class="streaming-cursor"></span>
        </p>
        
        <!-- Voice indicator for user messages -->
        <div v-if="message.audio && message.role === 'user'" class="voice-indicator">
          <i class="pi pi-microphone" />
          <span>{{ $t('common.voice_message') }}</span>
        </div>
      </div>
      
      <!-- Audio playback for assistant messages -->
      <div v-if="message.role === 'assistant' && message.content && !message.isStreaming" class="audio-controls">
        <button 
          @click="$emit('play-audio', message)"
          class="audio-button"
          :class="{ 'playing': isPlaying, 'loading': message.audioLoading }"
          :disabled="message.audioLoading"
        >
          <i v-if="message.audioLoading" class="pi pi-spin pi-spinner" />
          <i v-else-if="isPlaying" class="pi pi-volume-up" />
          <i v-else class="pi pi-volume-off" />
        </button>
        
        <!-- Audio hint for first message -->
        <span v-if="showAudioHint" class="audio-hint">
          <i class="pi pi-info-circle" />
          Tap to hear
        </span>
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
  gap: 0.625rem;
  animation: messageSlideIn 0.25s ease-out;
}

@keyframes messageSlideIn {
  from {
    opacity: 0;
    transform: translateY(8px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.message.user {
  flex-direction: row-reverse;
}

/* Avatar */
.message-avatar {
  width: 32px;
  height: 32px;
  border-radius: 10px;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  font-size: 0.875rem;
  color: white;
  transition: all 0.3s ease;
}

/* Assistant Avatar - Purple gradient */
.message.assistant .message-avatar {
  background: linear-gradient(135deg, #8b5cf6 0%, #6366f1 100%);
  box-shadow: 0 2px 8px rgba(139, 92, 246, 0.3);
}

/* User Avatar - Blue gradient */
.message.user .message-avatar {
  background: linear-gradient(135deg, #3b82f6 0%, #2563eb 100%);
  box-shadow: 0 2px 8px rgba(59, 130, 246, 0.3);
}

/* Streaming pulse animation */
.message-avatar.streaming {
  animation: avatarPulse 2s ease-in-out infinite;
}

@keyframes avatarPulse {
  0%, 100% {
    box-shadow: 0 2px 8px rgba(139, 92, 246, 0.3);
  }
  50% {
    box-shadow: 0 2px 16px rgba(139, 92, 246, 0.5);
  }
}

/* Message Content */
.message-content {
  flex: 1;
  max-width: 80%;
  display: flex;
  flex-direction: column;
  gap: 0.375rem;
}

.message.user .message-content {
  align-items: flex-end;
}

/* Message Bubble */
.message-bubble {
  padding: 0.875rem 1rem;
  border-radius: 18px;
  position: relative;
  transition: all 0.2s ease;
}

/* Assistant Bubble - Enhanced Glass morphism effect */
.message.assistant .message-bubble {
  background: linear-gradient(
    135deg,
    rgba(255, 255, 255, 0.1) 0%,
    rgba(255, 255, 255, 0.05) 100%
  );
  border: 1px solid rgba(255, 255, 255, 0.12);
  border-top-left-radius: 6px;
  backdrop-filter: blur(12px);
  -webkit-backdrop-filter: blur(12px);
  box-shadow: 
    0 4px 24px rgba(0, 0, 0, 0.15),
    inset 0 1px 0 rgba(255, 255, 255, 0.1);
}

.message.assistant .message-bubble:hover {
  background: linear-gradient(
    135deg,
    rgba(255, 255, 255, 0.12) 0%,
    rgba(255, 255, 255, 0.06) 100%
  );
  border-color: rgba(255, 255, 255, 0.15);
}

/* User Bubble - Gradient with glow */
.message.user .message-bubble {
  background: linear-gradient(135deg, #3b82f6 0%, #6366f1 50%, #8b5cf6 100%);
  border-top-right-radius: 6px;
  box-shadow: 
    0 4px 20px rgba(99, 102, 241, 0.35),
    inset 0 1px 0 rgba(255, 255, 255, 0.15);
}

/* Text */
.message-text {
  margin: 0;
  line-height: 1.55;
  word-wrap: break-word;
  white-space: pre-wrap;
}

.message.assistant .message-text {
  color: rgba(255, 255, 255, 0.92);
}

.message.user .message-text {
  color: white;
}

/* Streaming Cursor */
.streaming-cursor {
  display: inline-block;
  width: 2px;
  height: 1.1em;
  background: rgba(255, 255, 255, 0.7);
  margin-left: 2px;
  vertical-align: text-bottom;
  animation: cursorBlink 0.8s ease-in-out infinite;
}

@keyframes cursorBlink {
  0%, 50% { opacity: 1; }
  51%, 100% { opacity: 0; }
}

/* Voice Indicator (User messages) */
.voice-indicator {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  color: rgba(255, 255, 255, 0.85);
  font-size: 0.8125rem;
}

.voice-indicator i {
  font-size: 0.75rem;
}

/* Audio Controls */
.audio-controls {
  display: flex;
  align-items: center;
  gap: 0.625rem;
  padding-left: 0.25rem;
  margin-top: 0.25rem;
}

.audio-button {
  width: 34px;
  height: 34px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: linear-gradient(135deg, rgba(139, 92, 246, 0.15) 0%, rgba(99, 102, 241, 0.15) 100%);
  border: 1px solid rgba(139, 92, 246, 0.25);
  border-radius: 10px;
  color: rgba(167, 139, 250, 0.8);
  font-size: 1rem;
  cursor: pointer;
  transition: all 0.25s cubic-bezier(0.4, 0, 0.2, 1);
  position: relative;
  overflow: hidden;
}

.audio-button::before {
  content: '';
  position: absolute;
  inset: 0;
  background: linear-gradient(135deg, rgba(139, 92, 246, 0.3) 0%, rgba(99, 102, 241, 0.3) 100%);
  opacity: 0;
  transition: opacity 0.25s;
}

.audio-button:hover:not(:disabled) {
  background: linear-gradient(135deg, rgba(139, 92, 246, 0.25) 0%, rgba(99, 102, 241, 0.25) 100%);
  border-color: rgba(139, 92, 246, 0.5);
  color: #c4b5fd;
  transform: scale(1.08);
  box-shadow: 0 4px 16px rgba(139, 92, 246, 0.3);
}

.audio-button:hover:not(:disabled)::before {
  opacity: 1;
}

.audio-button:active:not(:disabled) {
  transform: scale(0.95);
}

.audio-button:disabled {
  opacity: 0.4;
  cursor: not-allowed;
}

.audio-button.playing {
  background: linear-gradient(135deg, rgba(139, 92, 246, 0.35) 0%, rgba(99, 102, 241, 0.35) 100%);
  border-color: rgba(139, 92, 246, 0.6);
  color: #c4b5fd;
  animation: playingPulse 1.5s ease-in-out infinite;
  box-shadow: 0 0 20px rgba(139, 92, 246, 0.4);
}

@keyframes playingPulse {
  0%, 100% { 
    box-shadow: 0 0 20px rgba(139, 92, 246, 0.4);
    transform: scale(1);
  }
  50% { 
    box-shadow: 0 0 28px rgba(139, 92, 246, 0.6);
    transform: scale(1.05);
  }
}

.audio-button.loading {
  opacity: 0.6;
}

.audio-button.loading i {
  animation: spin 1s linear infinite;
}

@keyframes spin {
  from { transform: rotate(0deg); }
  to { transform: rotate(360deg); }
}

.audio-hint {
  display: flex;
  align-items: center;
  gap: 0.375rem;
  font-size: 0.75rem;
  color: rgba(167, 139, 250, 0.7);
  font-weight: 500;
  animation: hintPulse 2s ease-in-out infinite;
  padding: 0.25rem 0.5rem;
  background: rgba(139, 92, 246, 0.1);
  border-radius: 6px;
}

.audio-hint i {
  font-size: 0.6875rem;
}

@keyframes hintPulse {
  0%, 100% { opacity: 0.7; }
  50% { opacity: 1; }
}

/* Mobile Optimizations */
@media (max-width: 640px) {
  .message-content {
    max-width: 85%;
  }
  
  .message-bubble {
    padding: 0.75rem 0.875rem;
  }
  
  .message-text {
    font-size: 0.9375rem;
  }
}
</style>
