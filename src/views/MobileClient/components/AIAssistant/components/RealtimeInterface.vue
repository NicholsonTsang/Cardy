<template>
  <div class="realtime-container">
    <!-- Error Warning (only show for actual connection failures) -->
    <div v-if="error" class="connection-error-warning">
      <div class="error-icon">
        <i class="pi pi-exclamation-triangle"></i>
      </div>
      <div class="error-content">
        <h4 class="error-title">{{ $t('common.connection_failed') }}</h4>
        <p class="error-message">{{ error }}</p>
      </div>
    </div>

    <!-- Main Realtime UI -->
    <div class="realtime-content">
      <!-- AI Avatar with Waveform -->
      <div class="realtime-avatar-section">
        <!-- Avatar Circle -->
        <div class="realtime-avatar" :class="{ 
          'speaking': isSpeaking,
          'listening': isConnected && !isSpeaking,
          'connecting': status === 'connecting'
        }">
          <div class="avatar-circle">
            <i class="pi pi-sparkles avatar-icon" />
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

/* Connection Error Warning */
.connection-error-warning {
  display: flex;
  gap: 0.75rem;
  margin: 0.75rem 1rem;
  padding: 0.75rem 1rem;
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
  width: 32px;
  height: 32px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: #fef2f2;
  border-radius: 50%;
}

.error-icon i {
  font-size: 1.125rem;
  color: #dc2626;
}

.error-content {
  flex: 1;
  min-width: 0;
}

.error-title {
  margin: 0 0 0.125rem 0;
  font-size: 0.875rem;
  font-weight: 600;
  color: #991b1b;
}

.error-message {
  margin: 0;
  font-size: 0.8125rem;
  line-height: 1.4;
  color: #7f1d1d;
}

.realtime-content {
  flex: 1;
  display: flex;
  flex-direction: column;
  padding: 0.75rem 1rem;
  overflow-y: auto;
  overflow-x: hidden;
  -webkit-overflow-scrolling: touch; /* Smooth scrolling on iOS */
  overscroll-behavior: contain; /* Prevent pull-to-refresh */
}

.realtime-avatar-section {
  text-align: center;
  margin-bottom: 1rem;
}

.realtime-avatar {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  margin-top: 10px;
  margin-bottom: 0.5rem;
}

.avatar-circle {
  width: 90px;
  height: 90px;
  border-radius: 50%;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  display: flex;
  align-items: center;
  justify-content: center;
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
  font-size: 2.25rem;
  color: white;
}

.realtime-status-text h3 {
  font-size: 1.125rem;
  font-weight: 600;
  color: #1f2937;
  margin: 0.5rem 0 0 0;
}

.realtime-transcript {
  flex: 1;
  background: white;
  border-radius: 12px;
  padding: 1rem;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
  overflow-y: auto;
  min-height: 150px; /* Ensure minimum readable height */
}

.transcript-placeholder {
  text-align: center;
  color: #9ca3af;
  padding: 1rem;
}

.transcript-messages {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.transcript-message {
  display: flex;
  gap: 0.5rem;
  padding: 0.5rem;
  border-radius: 6px;
  font-size: 0.875rem;
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
  padding: 1rem;
  background: white;
  border-top: 1px solid #e5e7eb;
  flex-shrink: 0; /* Prevent controls from being compressed */
}

.realtime-connect-button {
  width: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 0.5rem;
  padding: 0.875rem 1.25rem;
  background: linear-gradient(135deg, #22c55e 0%, #16a34a 100%);
  color: white;
  border: none;
  border-radius: 12px;
  font-size: 1rem;
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

.realtime-disconnect-button {
  width: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 0.5rem;
  padding: 0.875rem 1.25rem;
  background: linear-gradient(135deg, #ef4444 0%, #dc2626 100%);
  color: white;
  border: none;
  border-radius: 12px;
  font-size: 1rem;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
}

.realtime-disconnect-button:hover {
  background: linear-gradient(135deg, #dc2626 0%, #b91c1c 100%);
  transform: translateY(-1px);
  box-shadow: 0 4px 6px -1px rgba(239, 68, 68, 0.3);
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

