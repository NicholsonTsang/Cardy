<template>
  <div class="realtime-container">
    <!-- Error Warning -->
    <div v-if="error" class="connection-error">
      <div class="error-icon-wrapper">
        <i class="pi pi-exclamation-triangle"></i>
      </div>
      <div class="error-content">
        <h4>{{ $t('common.connection_failed') }}</h4>
        <p>{{ error }}</p>
      </div>
    </div>

    <!-- Main Content -->
    <div class="realtime-content">
      <!-- Avatar Section -->
      <div class="avatar-section">
        <div class="avatar-container" :class="avatarState">
          <!-- Main avatar with glow effect -->
          <div class="avatar-core">
            <i class="pi pi-sparkles" />
          </div>
        </div>
        
        <!-- Status -->
        <div class="status-badge" :class="statusBadgeClass">
          <span class="status-dot"></span>
          <span class="status-text">{{ statusText }}</span>
        </div>
      </div>

      <!-- Transcript -->
      <div ref="transcriptContainer" class="transcript-section">
        <div v-if="messages.length === 0" class="transcript-empty">
          <i class="pi pi-comments" />
          <p>{{ $t('mobile.transcript_appears_here') }}</p>
        </div>
        <div v-else class="transcript-messages">
          <div 
            v-for="message in messages" 
            :key="message.id" 
            class="transcript-message" 
            :class="message.role"
          >
            <span class="message-role">{{ message.role === 'user' ? $t('mobile.you') : $t('mobile.ai') }}</span>
            <span class="message-text">{{ message.content }}</span>
          </div>
        </div>
      </div>
    </div>

    <!-- Controls -->
    <div class="realtime-controls">
      <!-- Connect Button -->
      <button 
        v-if="!isConnected"
        @click="$emit('connect')"
        class="call-button connect"
        :disabled="status === 'connecting'"
      >
        <div class="button-icon">
          <i class="pi pi-phone" />
        </div>
        <span>{{ status === 'connecting' ? $t('mobile.connecting') : $t('mobile.start_live_call') }}</span>
      </button>

      <!-- Disconnect Button -->
      <button 
        v-else
        @click="$emit('disconnect')"
        class="call-button disconnect"
      >
        <div class="button-icon">
          <i class="pi pi-phone" style="transform: rotate(135deg);" />
        </div>
        <span>{{ $t('mobile.end_call') }}</span>
      </button>
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

// Computed avatar state
const avatarState = computed(() => ({
  'speaking': props.isSpeaking,
  'listening': props.isConnected && !props.isSpeaking,
  'connecting': props.status === 'connecting',
  'idle': props.status === 'disconnected'
}))

// Computed status badge class
const statusBadgeClass = computed(() => ({
  'connected': props.isConnected,
  'connecting': props.status === 'connecting',
  'speaking': props.isSpeaking
}))

// Status text
const statusText = computed(() => {
  if (props.status === 'disconnected') return t('mobile.ready_to_connect')
  if (props.status === 'connecting') return t('mobile.connecting')
  if (props.isSpeaking) return t('mobile.ai_speaking')
  if (props.isConnected) return t('mobile.listening')
  return ''
})

// Scroll during streaming
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
  background: 
    radial-gradient(ellipse at 50% 0%, rgba(139, 92, 246, 0.15) 0%, transparent 50%),
    linear-gradient(180deg, #0f172a 0%, #1e1b4b 50%, #0f172a 100%);
  position: relative;
}

/* Ambient background effect - contained in its own layer */
.realtime-container::before {
  content: '';
  position: absolute;
  inset: 0;
  background: 
    radial-gradient(circle at 30% 20%, rgba(99, 102, 241, 0.08) 0%, transparent 40%),
    radial-gradient(circle at 70% 80%, rgba(139, 92, 246, 0.08) 0%, transparent 40%);
  animation: ambientMove 20s ease-in-out infinite;
  pointer-events: none;
  z-index: 0;
}

@keyframes ambientMove {
  0%, 100% { opacity: 0.8; }
  50% { opacity: 1; }
}

/* Error */
.connection-error {
  display: flex;
  gap: 0.75rem;
  margin: 0.75rem 1rem;
  padding: 0.875rem 1rem;
  background: rgba(239, 68, 68, 0.15);
  border: 1px solid rgba(239, 68, 68, 0.3);
  border-radius: 12px;
  animation: slideDown 0.25s ease-out;
}

@keyframes slideDown {
  from { opacity: 0; transform: translateY(-8px); }
  to { opacity: 1; transform: translateY(0); }
}

.error-icon-wrapper {
  width: 32px;
  height: 32px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: rgba(239, 68, 68, 0.2);
  border-radius: 8px;
  flex-shrink: 0;
}

.error-icon-wrapper i {
  font-size: 1rem;
  color: #fca5a5;
}

.error-content {
  flex: 1;
  min-width: 0;
}

.error-content h4 {
  margin: 0 0 0.125rem 0;
  font-size: 0.875rem;
  font-weight: 600;
  color: #fca5a5;
}

.error-content p {
  margin: 0;
  font-size: 0.8125rem;
  line-height: 1.4;
  color: rgba(252, 165, 165, 0.7);
}

/* Main Content */
.realtime-content {
  flex: 1;
  display: flex;
  flex-direction: column;
  padding: 1rem 1rem 1rem;
  gap: 1rem;
  overflow: visible;
  position: relative;
  z-index: 1;
}

/* Avatar Section */
.avatar-section {
  display: flex;
  flex-direction: column;
  align-items: center;
  flex: 1;
  justify-content: center;
  min-height: 140px;
  padding: 1rem 0;
  position: relative;
  z-index: 1;
}

.avatar-container {
  position: relative;
  display: flex;
  align-items: center;
  justify-content: center;
}

/* Core avatar */
.avatar-core {
  width: 80px;
  height: 80px;
  border-radius: 50%;
  background: linear-gradient(135deg, #8b5cf6 0%, #6366f1 100%);
  display: flex;
  align-items: center;
  justify-content: center;
  box-shadow: 
    0 0 30px rgba(139, 92, 246, 0.4),
    0 4px 20px rgba(0, 0, 0, 0.25),
    inset 0 -2px 8px rgba(0, 0, 0, 0.2),
    inset 0 2px 8px rgba(255, 255, 255, 0.15);
  transition: all 0.4s cubic-bezier(0.4, 0, 0.2, 1);
  position: relative;
  animation: idleGlow 3s ease-in-out infinite;
}

.avatar-core::before {
  content: '';
  position: absolute;
  inset: -4px;
  border-radius: 50%;
  background: linear-gradient(135deg, rgba(139, 92, 246, 0.3), rgba(99, 102, 241, 0.3));
  z-index: -1;
  opacity: 0.6;
  animation: borderGlow 3s ease-in-out infinite;
}

.avatar-core::after {
  content: '';
  position: absolute;
  top: 6px;
  left: 50%;
  transform: translateX(-50%);
  width: 45%;
  height: 18%;
  background: linear-gradient(180deg, rgba(255, 255, 255, 0.35) 0%, transparent 100%);
  border-radius: 50%;
}

@keyframes idleGlow {
  0%, 100% { 
    box-shadow: 
      0 0 30px rgba(139, 92, 246, 0.4),
      0 4px 20px rgba(0, 0, 0, 0.25),
      inset 0 -2px 8px rgba(0, 0, 0, 0.2),
      inset 0 2px 8px rgba(255, 255, 255, 0.15);
  }
  50% { 
    box-shadow: 
      0 0 45px rgba(139, 92, 246, 0.5),
      0 4px 20px rgba(0, 0, 0, 0.25),
      inset 0 -2px 8px rgba(0, 0, 0, 0.2),
      inset 0 2px 8px rgba(255, 255, 255, 0.15);
  }
}

@keyframes borderGlow {
  0%, 100% { opacity: 0.5; transform: scale(1); }
  50% { opacity: 0.8; transform: scale(1.02); }
}

/* Avatar states */
.avatar-container.idle .avatar-core {
  background: linear-gradient(135deg, #64748b 0%, #475569 100%);
  box-shadow: 
    0 0 20px rgba(100, 116, 139, 0.3),
    0 4px 16px rgba(0, 0, 0, 0.25),
    inset 0 -2px 8px rgba(0, 0, 0, 0.2),
    inset 0 2px 8px rgba(255, 255, 255, 0.1);
  animation: none;
}

.avatar-container.idle .avatar-core::before {
  background: linear-gradient(135deg, rgba(100, 116, 139, 0.2), rgba(71, 85, 105, 0.2));
  animation: none;
}

.avatar-container.listening .avatar-core {
  background: linear-gradient(135deg, #3b82f6 0%, #2563eb 100%);
  animation: listeningGlow 2s ease-in-out infinite;
}

.avatar-container.listening .avatar-core::before {
  background: linear-gradient(135deg, rgba(59, 130, 246, 0.4), rgba(37, 99, 235, 0.4));
  animation: borderGlow 2s ease-in-out infinite;
}

@keyframes listeningGlow {
  0%, 100% { 
    box-shadow: 
      0 0 35px rgba(59, 130, 246, 0.5),
      0 4px 20px rgba(0, 0, 0, 0.25),
      inset 0 -2px 8px rgba(0, 0, 0, 0.2),
      inset 0 2px 8px rgba(255, 255, 255, 0.15);
  }
  50% { 
    box-shadow: 
      0 0 50px rgba(59, 130, 246, 0.6),
      0 4px 20px rgba(0, 0, 0, 0.25),
      inset 0 -2px 8px rgba(0, 0, 0, 0.2),
      inset 0 2px 8px rgba(255, 255, 255, 0.15);
  }
}

.avatar-container.speaking .avatar-core {
  animation: speakingPulse 0.6s ease-in-out infinite;
}

.avatar-container.speaking .avatar-core::before {
  animation: speakingBorder 0.6s ease-in-out infinite;
}

@keyframes speakingPulse {
  0%, 100% { 
    transform: scale(1);
    box-shadow: 
      0 0 40px rgba(139, 92, 246, 0.5),
      0 4px 20px rgba(0, 0, 0, 0.25),
      inset 0 -2px 8px rgba(0, 0, 0, 0.2),
      inset 0 2px 8px rgba(255, 255, 255, 0.15);
  }
  50% { 
    transform: scale(1.06);
    box-shadow: 
      0 0 55px rgba(139, 92, 246, 0.65),
      0 4px 20px rgba(0, 0, 0, 0.25),
      inset 0 -2px 8px rgba(0, 0, 0, 0.2),
      inset 0 2px 8px rgba(255, 255, 255, 0.15);
  }
}

@keyframes speakingBorder {
  0%, 100% { opacity: 0.6; transform: scale(1); }
  50% { opacity: 1; transform: scale(1.08); }
}

.avatar-container.connecting .avatar-core {
  background: linear-gradient(135deg, #fbbf24 0%, #f59e0b 100%);
  animation: connectingPulse 1s ease-in-out infinite;
}

.avatar-container.connecting .avatar-core::before {
  background: linear-gradient(135deg, rgba(251, 191, 36, 0.4), rgba(245, 158, 11, 0.4));
  animation: connectingBorder 1s ease-in-out infinite;
}

@keyframes connectingPulse {
  0%, 100% { 
    opacity: 1;
    box-shadow: 
      0 0 30px rgba(251, 191, 36, 0.4),
      0 4px 20px rgba(0, 0, 0, 0.25),
      inset 0 -2px 8px rgba(0, 0, 0, 0.2),
      inset 0 2px 8px rgba(255, 255, 255, 0.15);
  }
  50% { 
    opacity: 0.85;
    box-shadow: 
      0 0 45px rgba(251, 191, 36, 0.5),
      0 4px 20px rgba(0, 0, 0, 0.25),
      inset 0 -2px 8px rgba(0, 0, 0, 0.2),
      inset 0 2px 8px rgba(255, 255, 255, 0.15);
  }
}

@keyframes connectingBorder {
  0%, 100% { opacity: 0.5; }
  50% { opacity: 0.8; }
}

.avatar-core i {
  font-size: 2rem;
  color: white;
  filter: drop-shadow(0 2px 4px rgba(0, 0, 0, 0.2));
}

/* Status Badge */
.status-badge {
  display: inline-flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.5rem 1rem;
  background: linear-gradient(
    135deg,
    rgba(255, 255, 255, 0.08) 0%,
    rgba(255, 255, 255, 0.04) 100%
  );
  backdrop-filter: blur(12px);
  -webkit-backdrop-filter: blur(12px);
  border: 1px solid rgba(255, 255, 255, 0.12);
  border-radius: 20px;
  margin-top: 1rem;
  box-shadow: 
    0 4px 12px rgba(0, 0, 0, 0.12),
    inset 0 1px 0 rgba(255, 255, 255, 0.08);
  transition: all 0.3s ease;
}

.status-dot {
  width: 10px;
  height: 10px;
  border-radius: 50%;
  background: rgba(148, 163, 184, 0.5);
  transition: all 0.3s ease;
}

.status-badge.connected .status-dot {
  background: #22c55e;
  box-shadow: 
    0 0 12px rgba(34, 197, 94, 0.6),
    0 0 24px rgba(34, 197, 94, 0.3);
}

.status-badge.connecting .status-dot {
  background: #fbbf24;
  box-shadow: 0 0 12px rgba(251, 191, 36, 0.5);
  animation: dotBlink 0.8s ease-in-out infinite;
}

.status-badge.speaking .status-dot {
  background: #a78bfa;
  box-shadow: 
    0 0 12px rgba(167, 139, 250, 0.6),
    0 0 24px rgba(167, 139, 250, 0.3);
  animation: dotPulse 0.6s ease-in-out infinite;
}

@keyframes dotBlink {
  0%, 100% { 
    opacity: 1;
    transform: scale(1);
  }
  50% { 
    opacity: 0.4;
    transform: scale(0.9);
  }
}

@keyframes dotPulse {
  0%, 100% { 
    transform: scale(1);
    box-shadow: 
      0 0 12px rgba(167, 139, 250, 0.6),
      0 0 24px rgba(167, 139, 250, 0.3);
  }
  50% { 
    transform: scale(1.2);
    box-shadow: 
      0 0 16px rgba(167, 139, 250, 0.8),
      0 0 32px rgba(167, 139, 250, 0.4);
  }
}

.status-text {
  font-size: 0.875rem;
  font-weight: 600;
  color: rgba(255, 255, 255, 0.85);
  letter-spacing: 0.01em;
}

/* Transcript */
.transcript-section {
  flex: 1;
  background: linear-gradient(
    135deg,
    rgba(255, 255, 255, 0.06) 0%,
    rgba(255, 255, 255, 0.02) 100%
  );
  backdrop-filter: blur(8px);
  -webkit-backdrop-filter: blur(8px);
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 16px;
  padding: 1rem;
  overflow-y: auto;
  min-height: 80px;
  max-height: 35vh;
  box-shadow: 
    0 4px 16px rgba(0, 0, 0, 0.12),
    inset 0 1px 0 rgba(255, 255, 255, 0.06);
  position: relative;
  z-index: 1;
}

.transcript-empty {
  display: flex;
  flex-direction: row;
  align-items: center;
  justify-content: center;
  height: 100%;
  min-height: 60px;
  color: rgba(255, 255, 255, 0.4);
  text-align: center;
  gap: 0.5rem;
}

.transcript-empty i {
  font-size: 1.25rem;
  opacity: 0.7;
}

.transcript-empty p {
  margin: 0;
  font-size: 0.8125rem;
  font-weight: 500;
}

.transcript-messages {
  display: flex;
  flex-direction: column;
  gap: 0.625rem;
}

.transcript-message {
  display: flex;
  gap: 0.5rem;
  padding: 0.625rem 0.875rem;
  border-radius: 12px;
  font-size: 0.8125rem;
  line-height: 1.45;
  animation: messageIn 0.25s ease-out;
}

@keyframes messageIn {
  from { 
    opacity: 0; 
    transform: translateY(8px) scale(0.98);
  }
  to { 
    opacity: 1; 
    transform: translateY(0) scale(1);
  }
}

.transcript-message.user {
  background: linear-gradient(
    135deg,
    rgba(59, 130, 246, 0.2) 0%,
    rgba(59, 130, 246, 0.1) 100%
  );
  border: 1px solid rgba(59, 130, 246, 0.25);
  box-shadow: 0 2px 8px rgba(59, 130, 246, 0.1);
}

.transcript-message.assistant {
  background: linear-gradient(
    135deg,
    rgba(139, 92, 246, 0.18) 0%,
    rgba(139, 92, 246, 0.08) 100%
  );
  border: 1px solid rgba(139, 92, 246, 0.2);
  box-shadow: 0 2px 8px rgba(139, 92, 246, 0.1);
}

.message-role {
  font-weight: 700;
  flex-shrink: 0;
  text-transform: uppercase;
  font-size: 0.75rem;
  letter-spacing: 0.03em;
}

.transcript-message.user .message-role {
  color: #60a5fa;
}

.transcript-message.assistant .message-role {
  color: #a78bfa;
}

.message-text {
  color: rgba(255, 255, 255, 0.9);
}

/* Controls */
.realtime-controls {
  padding: 1rem;
  background: linear-gradient(180deg, rgba(15, 23, 42, 0.8) 0%, rgba(15, 23, 42, 0.95) 100%);
  border-top: 1px solid rgba(255, 255, 255, 0.08);
  flex-shrink: 0;
  position: relative;
  z-index: 1;
}

.call-button {
  width: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 0.625rem;
  padding: 0.875rem 1.25rem;
  border: none;
  border-radius: 14px;
  font-size: 0.9375rem;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.25s cubic-bezier(0.4, 0, 0.2, 1);
  color: white;
  position: relative;
  overflow: hidden;
  min-height: 48px;
}

.call-button::before {
  content: '';
  position: absolute;
  inset: 0;
  background: linear-gradient(135deg, rgba(255, 255, 255, 0.15) 0%, transparent 50%);
  opacity: 0;
  transition: opacity 0.25s;
}

.call-button.connect {
  background: linear-gradient(135deg, #22c55e 0%, #16a34a 100%);
  box-shadow: 
    0 4px 20px rgba(34, 197, 94, 0.35),
    inset 0 1px 0 rgba(255, 255, 255, 0.2);
}

.call-button.connect:hover:not(:disabled) {
  background: linear-gradient(135deg, #16a34a 0%, #15803d 100%);
  transform: translateY(-2px) scale(1.01);
  box-shadow: 
    0 8px 28px rgba(34, 197, 94, 0.45),
    0 0 30px rgba(34, 197, 94, 0.2);
}

.call-button.connect:hover::before {
  opacity: 1;
}

.call-button.connect:active:not(:disabled) {
  transform: translateY(0) scale(0.98);
}

.call-button.connect:disabled {
  opacity: 0.5;
  cursor: not-allowed;
  box-shadow: none;
}

.call-button.disconnect {
  background: linear-gradient(135deg, #ef4444 0%, #dc2626 100%);
  box-shadow: 
    0 4px 20px rgba(239, 68, 68, 0.35),
    inset 0 1px 0 rgba(255, 255, 255, 0.2);
}

.call-button.disconnect:hover {
  background: linear-gradient(135deg, #dc2626 0%, #b91c1c 100%);
  transform: translateY(-2px) scale(1.01);
  box-shadow: 
    0 8px 28px rgba(239, 68, 68, 0.45),
    0 0 30px rgba(239, 68, 68, 0.2);
}

.call-button.disconnect:hover::before {
  opacity: 1;
}

.call-button.disconnect:active {
  transform: translateY(0) scale(0.98);
}

.button-icon {
  width: 24px;
  height: 24px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.button-icon i {
  font-size: 1.125rem;
}

/* Mobile */
@media (max-width: 640px) {
  .realtime-content {
    padding: 0.75rem;
    gap: 0.75rem;
  }
  
  .realtime-controls {
    padding: 0.875rem;
    padding-bottom: max(0.875rem, env(safe-area-inset-bottom));
  }
  
  .avatar-section {
    min-height: 120px;
    padding: 1rem 0;
  }
  
  .avatar-core {
    width: 72px;
    height: 72px;
  }
  
  .avatar-core::before {
    inset: -3px;
  }
  
  .avatar-core i {
    font-size: 1.75rem;
  }
  
  .transcript-section {
    border-radius: 14px;
    padding: 0.875rem;
    min-height: 70px;
    max-height: 30vh;
  }
  
  .status-badge {
    padding: 0.4375rem 0.875rem;
    margin-top: 0.75rem;
  }
  
  .status-text {
    font-size: 0.8125rem;
  }
  
  .status-dot {
    width: 8px;
    height: 8px;
  }
}
</style>
