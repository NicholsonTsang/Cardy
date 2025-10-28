<template>
  <div class="realtime-container">
    <!-- Connection Status Banner -->
    <div class="realtime-status-banner" :class="`status-${status}`">
      <div class="status-indicator">
        <div class="status-dot"></div>
        <span class="status-text">{{ statusText }}</span>
      </div>
    </div>
    
    <!-- Error Warning (separate, more visible) -->
    <div v-if="error" class="connection-error-warning">
      <div class="error-icon">
        <i class="pi pi-exclamation-triangle"></i>
      </div>
      <div class="error-content">
        <h4 class="error-title">Connection Failed</h4>
        <p class="error-message">{{ error }}</p>
      </div>
    </div>

    <!-- Main Realtime UI -->
    <div class="realtime-content">
      <!-- AI Avatar with Waveform -->
      <div class="realtime-avatar-section">
        <div class="realtime-avatar" :class="{ 
          'speaking': isSpeaking,
          'listening': isConnected && !isSpeaking,
          'connecting': status === 'connecting'
        }">
          <div class="avatar-circle">
            <i class="pi pi-sparkles avatar-icon" />
          </div>
          
          <!-- Waveform Visualization -->
          <div v-if="isConnected" class="waveform-container">
            <div class="waveform-bars">
              <div v-for="i in 20" :key="i" class="waveform-bar" 
                   :style="{ animationDelay: `${i * 0.05}s` }"></div>
            </div>
          </div>
        </div>
        
        <!-- Status Text -->
        <div class="realtime-status-text">
          <h3 v-if="status === 'disconnected'">{{ $t('mobile.ready_to_connect') }}</h3>
          <h3 v-else-if="status === 'connecting'">{{ $t('mobile.connecting') }}</h3>
          <h3 v-else-if="isSpeaking">{{ $t('mobile.ai_speaking') }}</h3>
          <h3 v-else-if="isConnected">{{ $t('mobile.listening') }}</h3>
        </div>
      </div>

      <!-- Live Transcript -->
      <div ref="transcriptContainer" class="realtime-transcript">
        <div v-if="messages.length === 0" class="transcript-placeholder">
          <p>{{ $t('mobile.transcript_appears_here') }}</p>
        </div>
        <div v-else class="transcript-messages">
          <div v-for="message in messages" :key="message.id" 
               class="transcript-message" :class="message.role">
            <span class="transcript-role">{{ message.role === 'user' ? $t('mobile.you') : $t('mobile.ai') }}:</span>
            <span class="transcript-content">{{ message.content }}</span>
          </div>
        </div>
      </div>
    </div>

    <!-- Realtime Controls -->
    <div class="realtime-controls">
      <!-- Connect Button -->
      <button 
        v-if="!isConnected"
        @click="$emit('connect')"
        class="realtime-connect-button"
        :disabled="status === 'connecting'"
      >
        <i class="pi pi-phone" />
        <span>{{ status === 'connecting' ? $t('mobile.connecting') : $t('mobile.start_live_call') }}</span>
      </button>

      <!-- Talk Controls (when connected) -->
      <div v-else class="realtime-talk-controls">
        <button 
          @click="$emit('disconnect')"
          class="realtime-disconnect-button"
        >
          <i class="pi pi-phone" style="transform: rotate(135deg);" />
          <span>{{ $t('mobile.end_call') }}</span>
        </button>
        
        <div class="realtime-mode-info">
          <i class="pi pi-info-circle" />
          <span>{{ $t('mobile.speak_naturally') }}</span>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, watch, nextTick, computed } from 'vue'
import { useI18n } from 'vue-i18n'
import type { Message } from '../types'

const { t } = useI18n()

const props = defineProps<{
  isConnected: boolean
  isSpeaking: boolean
  status: 'disconnected' | 'connecting' | 'connected' | 'error'
  statusText: string
  error?: string | null
  messages: Message[]
}>()

defineEmits<{
  (e: 'connect'): void
  (e: 'disconnect'): void
}>()

const transcriptContainer = ref<HTMLDivElement | null>(null)

// Scroll during streaming (not just on message creation)
const streamingProgressKey = computed(() => {
  return props.messages
    .filter(m => m.isStreaming)
    .map(m => `${m.id}:${(m.content || '').length}`)
    .join('|')
})

watch(streamingProgressKey, async () => {
  await nextTick()
  if (transcriptContainer.value) {
    transcriptContainer.value.scrollTop = transcriptContainer.value.scrollHeight
  }
})
</script>

<style scoped>
.realtime-container {
  display: flex;
  flex-direction: column;
  height: 100%;
  background: linear-gradient(180deg, #f9fafb 0%, #ffffff 100%);
}

.realtime-status-banner {
  padding: 0.75rem 1.5rem;
  background: #f3f4f6;
  border-bottom: 1px solid #e5e7eb;
}

.realtime-status-banner.status-connected {
  background: #dcfce7;
  border-bottom-color: #86efac;
}

.realtime-status-banner.status-connecting {
  background: #fef3c7;
  border-bottom-color: #fde047;
}

.realtime-status-banner.status-error {
  background: #fee2e2;
  border-bottom-color: #fca5a5;
}

.status-indicator {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  justify-content: center;
}

.status-dot {
  width: 10px;
  height: 10px;
  border-radius: 50%;
  background: #9ca3af;
}

.status-connected .status-dot {
  background: #22c55e;
  animation: pulse 2s ease-in-out infinite;
}

.status-connecting .status-dot {
  background: #f59e0b;
  animation: pulse 1s ease-in-out infinite;
}

.status-error .status-dot {
  background: #ef4444;
}

@keyframes pulse {
  0%, 100% {
    opacity: 1;
  }
  50% {
    opacity: 0.5;
  }
}

.status-text {
  font-size: 0.875rem;
  font-weight: 600;
  color: #374151;
}

/* Connection Error Warning */
.connection-error-warning {
  display: flex;
  gap: 1rem;
  margin: 1rem 1.5rem;
  padding: 1rem 1.25rem;
  background: #fee2e2;
  border: 2px solid #fca5a5;
  border-radius: 12px;
  box-shadow: 0 4px 6px -1px rgba(239, 68, 68, 0.1);
  animation: slideDown 0.3s ease-out;
}

@keyframes slideDown {
  from {
    opacity: 0;
    transform: translateY(-10px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.error-icon {
  flex-shrink: 0;
  width: 40px;
  height: 40px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: #fef2f2;
  border-radius: 50%;
}

.error-icon i {
  font-size: 1.5rem;
  color: #dc2626;
}

.error-content {
  flex: 1;
  min-width: 0;
}

.error-title {
  margin: 0 0 0.25rem 0;
  font-size: 1rem;
  font-weight: 600;
  color: #991b1b;
}

.error-message {
  margin: 0;
  font-size: 0.875rem;
  line-height: 1.5;
  color: #7f1d1d;
}

.realtime-content {
  flex: 1;
  display: flex;
  flex-direction: column;
  padding: 2rem 1.5rem;
  overflow-y: auto;
  overflow-x: hidden;
  -webkit-overflow-scrolling: touch; /* Smooth scrolling on iOS */
  overscroll-behavior: contain; /* Prevent pull-to-refresh */
}

.realtime-avatar-section {
  text-align: center;
  margin-bottom: 2rem;
}

.realtime-avatar {
  position: relative;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  margin-bottom: 1rem;
}

.avatar-circle {
  width: 120px;
  height: 120px;
  border-radius: 50%;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  display: flex;
  align-items: center;
  justify-content: center;
  position: relative;
  z-index: 2;
  box-shadow: 0 10px 25px rgba(102, 126, 234, 0.3);
}

.realtime-avatar.connecting .avatar-circle {
  animation: pulse 2s ease-in-out infinite;
}

.realtime-avatar.listening .avatar-circle {
  box-shadow: 0 0 0 0 rgba(59, 130, 246, 0.7);
  animation: ripple 2s ease-out infinite;
}

@keyframes ripple {
  0% {
    box-shadow: 0 0 0 0 rgba(59, 130, 246, 0.7);
  }
  100% {
    box-shadow: 0 0 0 40px rgba(59, 130, 246, 0);
  }
}

.avatar-icon {
  font-size: 3rem;
  color: white;
}

.waveform-container {
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  width: 200px;
  height: 200px;
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1;
}

.waveform-bars {
  display: flex;
  align-items: center;
  gap: 4px;
  height: 60px;
}

.waveform-bar {
  width: 3px;
  height: 20%;
  background: linear-gradient(to top, #3b82f6, #8b5cf6);
  border-radius: 2px;
  animation: waveform 1s ease-in-out infinite;
}

.realtime-avatar.speaking .waveform-bar {
  animation: waveformActive 0.5s ease-in-out infinite;
}

@keyframes waveform {
  0%, 100% {
    height: 20%;
  }
  50% {
    height: 40%;
  }
}

@keyframes waveformActive {
  0%, 100% {
    height: 30%;
  }
  50% {
    height: 80%;
  }
}

.realtime-status-text h3 {
  font-size: 1.5rem;
  font-weight: 600;
  color: #1f2937;
  margin: 0;
}

.realtime-transcript {
  flex: 1;
  background: white;
  border-radius: 12px;
  padding: 1.5rem;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
  overflow-y: auto;
  max-height: 300px;
}

.transcript-placeholder {
  text-align: center;
  color: #9ca3af;
  padding: 2rem;
}

.transcript-messages {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}

.transcript-message {
  display: flex;
  gap: 0.5rem;
  padding: 0.5rem;
  border-radius: 6px;
  font-size: 0.9375rem;
  line-height: 1.5;
}

.transcript-message.user {
  background: #eff6ff;
}

.transcript-message.assistant {
  background: #f3f4f6;
}

.transcript-role {
  font-weight: 600;
  color: #374151;
  flex-shrink: 0;
}

.transcript-content {
  color: #4b5563;
}

.realtime-controls {
  padding: 1.5rem;
  background: white;
  border-top: 1px solid #e5e7eb;
  flex-shrink: 0; /* Prevent controls from being compressed */
}

.realtime-connect-button {
  width: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 0.75rem;
  padding: 1rem 1.5rem;
  background: linear-gradient(135deg, #22c55e 0%, #16a34a 100%);
  color: white;
  border: none;
  border-radius: 12px;
  font-size: 1.125rem;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
}

.realtime-connect-button:hover:not(:disabled) {
  background: linear-gradient(135deg, #16a34a 0%, #15803d 100%);
  transform: translateY(-1px);
  box-shadow: 0 4px 6px -1px rgba(34, 197, 94, 0.3);
}

.realtime-connect-button:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.realtime-talk-controls {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.realtime-disconnect-button {
  width: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 0.75rem;
  padding: 1rem 1.5rem;
  background: linear-gradient(135deg, #ef4444 0%, #dc2626 100%);
  color: white;
  border: none;
  border-radius: 12px;
  font-size: 1.125rem;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
}

.realtime-disconnect-button:hover {
  background: linear-gradient(135deg, #dc2626 0%, #b91c1c 100%);
  transform: translateY(-1px);
  box-shadow: 0 4px 6px -1px rgba(239, 68, 68, 0.3);
}

.realtime-mode-info {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 0.5rem;
  padding: 0.75rem;
  background: #f9fafb;
  border-radius: 8px;
  font-size: 0.875rem;
  color: #6b7280;
}

@media (max-width: 640px) {
  .realtime-content {
    padding: 1.5rem 1rem;
  }
  
  .realtime-controls {
    /* Account for iPhone home indicator */
    padding-bottom: max(1.5rem, env(safe-area-inset-bottom));
  }
  
  .avatar-circle {
    width: 100px;
    height: 100px;
  }
  
  .avatar-icon {
    font-size: 2.5rem;
  }
  
  .waveform-container {
    width: 160px;
    height: 160px;
  }
}
</style>

