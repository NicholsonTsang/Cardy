<template>
  <div class="card-level-assistant" :class="{ 'floating-mode': showButton }">
    <!-- Enhanced Floating AI Button with attention animation -->
    <div v-if="showButton" class="floating-button-container">
      <!-- Pulsing ring effect to draw attention -->
      <div class="attention-ring"></div>
      <div class="attention-ring attention-ring-2"></div>
      
      <button 
        @click="openModal" 
        class="floating-ai-button" 
        :title="$t('mobile.general_assistant')"
      >
        <span class="button-icon">
          <i class="pi pi-sparkles" />
        </span>
        <span class="button-label">{{ $t('mobile.ask_ai') }}</span>
      </button>
    </div>

    <!-- Modal -->
    <AIAssistantModal
      :is-open="isModalOpen"
      :show-language-selection="false"
      :conversation-mode="conversationMode"
      :input-mode="inputMode"
      :assistant-mode="'card-level'"
      :title="cardData.card_name"
      @close="closeModal"
      @toggle-mode="toggleConversationMode"
    >
      <!-- Chat Completion Mode -->
      <ChatInterface
        v-if="conversationMode === 'chat-completion'"
        :messages="messages"
        :is-loading="chatCompletion.isLoading.value"
        :error="chatCompletion.error.value"
        :loading-status="loadingStatus"
        :input-mode="inputMode"
        :is-recording="voiceRecording.isRecording.value"
        :recording-duration="voiceRecording.recordingDuration.value"
        :is-cancel-zone="voiceRecording.isCancelZone.value"
        :waveform-data="voiceRecording.waveformData.value"
        :current-playing-message-id="chatCompletion.currentPlayingMessageId.value"
        :first-audio-played="firstAudioPlayed"
        @send-text="sendTextMessage"
        @toggle-input-mode="toggleInputMode"
        @start-recording="startVoiceRecording"
        @stop-recording="stopVoiceRecording"
        @cancel-recording="cancelVoiceRecording"
        @update-cancel-zone="voiceRecording.isCancelZone.value = $event"
        @play-audio="playMessageAudio"
        @clear-chat="clearChat"
      />

      <!-- Realtime Mode -->
      <RealtimeInterface
        v-else-if="conversationMode === 'realtime'"
        :is-connected="realtimeConnection.isConnected.value"
        :is-speaking="realtimeConnection.isSpeaking.value"
        :status="realtimeConnection.status.value"
        :status-text="realtimeStatusText"
        :error="connectionError"
        :messages="messages"
        @connect="connectRealtime"
        @disconnect="disconnectRealtime"
      />
    </AIAssistantModal>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onUnmounted } from 'vue'
import { useI18n } from 'vue-i18n'
import AIAssistantModal from './components/AIAssistantModal.vue'
import ChatInterface from './components/ChatInterface.vue'
import RealtimeInterface from './components/RealtimeInterface.vue'
import { useWebRTCConnection } from './composables/useWebRTCConnection'
import { useChatCompletion } from './composables/useChatCompletion'
import { useVoiceRecording } from './composables/useVoiceRecording'
import { useCostSafeguards } from './composables/useCostSafeguards'
import { useInactivityTimer } from './composables/useInactivityTimer'
import { useMobileLanguageStore } from '@/stores/language'
import { buildCardLevelPrompt } from './utils/promptBuilder'
import type { Message, ConversationMode, CardData } from './types'

interface Props {
  cardData: CardData
  showButton?: boolean // If false, only renders modal (can be triggered externally)
}

const props = withDefaults(defineProps<Props>(), {
  showButton: true
})

// Expose openModal for external triggering
defineExpose({
  openModal
})
const languageStore = useMobileLanguageStore()
const { t } = useI18n()

// ============================================================================
// COMPOSABLES
// ============================================================================

const chatCompletion = useChatCompletion()
const voiceRecording = useVoiceRecording()
const realtimeConnection = useWebRTCConnection()

// ============================================================================
// STATE
// ============================================================================

const isModalOpen = ref(false)
const conversationMode = ref<ConversationMode>('chat-completion')
const messages = ref<Message[]>([])
const inputMode = ref<'text' | 'voice'>('text')
const loadingStatus = ref('')
const firstAudioPlayed = ref(false)
const connectionError = ref<string | null>(null)

// ============================================================================
// COMPUTED - Card-Level System Instructions
// ============================================================================

const systemInstructions = computed(() => {
  return buildCardLevelPrompt({
    assistantName: 'AI Assistant',
    cardName: props.cardData.card_name,
    cardDescription: props.cardData.card_description,
    languageName: languageStore.selectedLanguage.name,
    languageCode: languageStore.selectedLanguage.code,
    chineseVoice: languageStore.chineseVoice as 'mandarin' | 'cantonese' | undefined,
    knowledgeBase: props.cardData.ai_knowledge_base,
    customInstruction: props.cardData.ai_instruction
  })
})

const welcomeText = computed(() => {
  const langCode = languageStore.selectedLanguage.code
  const voice = languageStore.chineseVoice
  const params = { name: props.cardData.card_name }
  
  // Check for custom welcome message from card settings first
  if (props.cardData.ai_welcome_general) {
    return props.cardData.ai_welcome_general
  }
  
  // Fall back to default i18n messages
  // Special handling for Chinese dialects
  if (languageStore.isChinese(langCode)) {
    if (voice === 'cantonese') {
      if (langCode === 'zh-Hans') {
        return t('mobile.card_assistant_welcome_cantonese', params, t('mobile.card_assistant_welcome', params))
      }
      return t('mobile.card_assistant_welcome', params)
    } else {
      if (langCode === 'zh-Hant') {
        return t('mobile.card_assistant_welcome_mandarin', params, t('mobile.card_assistant_welcome', params))
      }
      return t('mobile.card_assistant_welcome', params)
    }
  }
  
  return t('mobile.card_assistant_welcome', params)
})

// Computed property for realtime status text
const realtimeStatusText = computed(() => {
  switch (realtimeConnection.status.value) {
    case 'connecting':
      return 'Connecting...'
    case 'connected':
      return 'Connected'
    case 'error':
      return 'Connection error'
    default:
      return 'Disconnected'
  }
})

// ============================================================================
// COST SAFEGUARDS & INACTIVITY TIMER
// ============================================================================

const inactivityTimer = useInactivityTimer(300000, () => {
  if (realtimeConnection.isConnected.value) {
    disconnectRealtime()
  }
})

const costSafeguards = useCostSafeguards(
  realtimeConnection.isConnected,
  () => disconnectRealtime()
)

// ============================================================================
// MODAL METHODS
// ============================================================================

function openModal() {
  isModalOpen.value = true
  document.body.style.overflow = 'hidden'
  messages.value = []
  firstAudioPlayed.value = false
  connectionError.value = null
  
  messages.value = [{
    id: Date.now().toString(),
    role: 'assistant',
    content: welcomeText.value,
    timestamp: new Date()
  }]
}

function closeModal() {
  isModalOpen.value = false
  document.body.style.overflow = ''
  messages.value = []
  firstAudioPlayed.value = false
  conversationMode.value = 'chat-completion'
  
  if (realtimeConnection.isConnected.value) {
    disconnectRealtime()
  }
  
  if (voiceRecording.isRecording.value) {
    voiceRecording.cancelRecording()
  }
}

function toggleConversationMode() {
  if (conversationMode.value === 'chat-completion') {
    conversationMode.value = 'realtime'
    messages.value = []
    connectionError.value = null
  } else {
    conversationMode.value = 'chat-completion'
    if (realtimeConnection.isConnected.value) {
      disconnectRealtime()
    }
    connectionError.value = null
    messages.value = [{
      id: Date.now().toString(),
      role: 'assistant',
      content: welcomeText.value,
      timestamp: new Date()
    }]
  }
}

function clearChat() {
  messages.value = [{
    id: Date.now().toString(),
    role: 'assistant',
    content: welcomeText.value,
    timestamp: new Date()
  }]
  firstAudioPlayed.value = false
  if (voiceRecording.isRecording.value) {
    voiceRecording.cancelRecording()
  }
}

// ============================================================================
// CHAT COMPLETION METHODS
// ============================================================================

function toggleInputMode() {
  inputMode.value = inputMode.value === 'text' ? 'voice' : 'text'
}

async function sendTextMessage(text: string) {
  if (!text.trim()) return
  
  messages.value.push({
    id: Date.now().toString(),
    role: 'user',
    content: text,
    timestamp: new Date()
  })

  const streamingMessageId = (Date.now() + 1).toString()
  messages.value.push({
    id: streamingMessageId,
    role: 'assistant',
    content: '',
    timestamp: new Date(),
    isStreaming: true
  })
  
  chatCompletion.streamingMessageId.value = streamingMessageId
  loadingStatus.value = 'Generating response...'
  
  try {
    const result = await chatCompletion.getAIResponse(
      messages.value.filter(m => !m.isStreaming),
      systemInstructions.value,
      (content) => {
        const message = messages.value.find(m => m.id === streamingMessageId)
        if (message) {
          message.content = content
        }
      }
    )
    
    const message = messages.value.find(m => m.id === streamingMessageId)
    if (message) {
      message.isStreaming = false
      message.content = result.content
    }
  } catch (err) {
    const message = messages.value.find(m => m.id === streamingMessageId)
    if (message) {
      message.isStreaming = false
      message.content = 'Sorry, I encountered an error. Please try again.'
    }
  } finally {
    loadingStatus.value = ''
    chatCompletion.streamingMessageId.value = null
  }
}

async function startVoiceRecording() {
  try {
    await voiceRecording.startRecording()
  } catch (err) {
    console.error('Failed to start recording:', err)
  }
}

async function stopVoiceRecording() {
  const audioBlob = await voiceRecording.stopRecording()
  if (!audioBlob) return
  
  loadingStatus.value = 'Transcribing voice...'
  
  try {
    const result = await chatCompletion.getAIResponseWithVoice(
      audioBlob,
      messages.value,
      systemInstructions.value,
      languageStore.getVoiceAwareLanguageCode()
    )
    
    messages.value.push({
      id: Date.now().toString(),
      role: 'user',
      content: result.userTranscription,
      timestamp: new Date(),
      audio: { data: '', format: 'wav' }
    })
    
    messages.value.push({
      id: (Date.now() + 1).toString(),
      role: 'assistant',
      content: result.textContent,
      timestamp: new Date()
    })
  } catch (err) {
    console.error('Voice processing error:', err)
    chatCompletion.error.value = 'Failed to process voice input'
  } finally {
    loadingStatus.value = ''
  }
}

function cancelVoiceRecording() {
  voiceRecording.cancelRecording()
}

async function playMessageAudio(message: Message) {
  firstAudioPlayed.value = true
  await chatCompletion.playMessageAudio(message, languageStore.getVoiceAwareLanguageCode())
}

// ============================================================================
// REALTIME METHODS
// ============================================================================

async function connectRealtime() {
  const voiceAwareCode = languageStore.getVoiceAwareLanguageCode()
  connectionError.value = null
  
  try {
    realtimeConnection.onUserTranscript((text: string) => {
      messages.value.push({
        id: Date.now().toString(),
        role: 'user',
        content: text,
        timestamp: new Date()
      })
    })
    
    realtimeConnection.onAssistantTranscript((text: string) => {
      messages.value.push({
        id: Date.now().toString(),
        role: 'assistant',
        content: text,
        timestamp: new Date()
      })
    })
    
    // Pass custom welcome message (ai_welcome_general) for voice greeting if configured
    await realtimeConnection.connect(
      voiceAwareCode,
      systemInstructions.value,
      props.cardData.ai_welcome_general || undefined
    )
    
    inactivityTimer.startTimer()
    costSafeguards.addSafeguards()
    connectionError.value = null
  } catch (err: any) {
    console.error('❌ Realtime connection error:', err)
    
    if (err.message?.includes('Backend server required') || err.message?.includes('VITE_BACKEND_URL')) {
      connectionError.value = 'Realtime voice mode requires backend server. Please use Chat Mode instead.'
    } else if (err.message?.includes('microphone') || err.message?.includes('getUserMedia')) {
      connectionError.value = 'Microphone access denied. Please allow microphone permissions.'
    } else if (err.message?.includes('network') || err.message?.includes('fetch')) {
      connectionError.value = 'Network error. Please check your internet connection.'
    } else if (err.message) {
      connectionError.value = `Connection failed: ${err.message}`
    } else {
      connectionError.value = 'Failed to start live call. Please try Chat Mode instead.'
    }
    
    await realtimeConnection.disconnect()
  }
}

function disconnectRealtime() {
  realtimeConnection.disconnect()
  costSafeguards.removeSafeguards()
  inactivityTimer.clearTimer()
  
  if (messages.value.length > 0) {
    messages.value.push({
      id: Date.now().toString(),
      role: 'assistant',
      content: t('mobile.call_ended_message'),
      timestamp: new Date()
    })
  }
}

// ============================================================================
// LIFECYCLE HOOKS
// ============================================================================

onUnmounted(() => {
  realtimeConnection.destroyVisibilityListener()
})
</script>

<style scoped>
/* Non-floating mode: no positioning, just contains modal */
.card-level-assistant {
  /* Default: no special positioning */
}

/* Floating mode: fixed position button */
.card-level-assistant.floating-mode {
  position: fixed;
  bottom: calc(1.5rem + env(safe-area-inset-bottom));
  right: 1.25rem;
  z-index: 100;
}

/* Container for button + attention effects */
.floating-button-container {
  position: relative;
  display: flex;
  align-items: center;
  animation: slideInUp 0.5s ease-out;
}

@keyframes slideInUp {
  from {
    opacity: 0;
    transform: translateY(20px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

/* Attention-grabbing pulsing rings */
.attention-ring {
  position: absolute;
  left: 0;
  top: 50%;
  transform: translateY(-50%);
  width: 44px;
  height: 44px;
  border-radius: 50%;
  border: 2px solid rgba(139, 92, 246, 0.5);
  animation: attentionPulse 2.5s ease-out infinite;
  pointer-events: none;
}

.attention-ring-2 {
  animation-delay: 1.25s;
}

@keyframes attentionPulse {
  0% {
    transform: translateY(-50%) scale(1);
    opacity: 0.6;
  }
  100% {
    transform: translateY(-50%) scale(1.8);
    opacity: 0;
  }
}

/* Enhanced floating button with gradient and label */
.floating-ai-button {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.75rem 1rem 0.75rem 0.875rem;
  background: linear-gradient(135deg, #8b5cf6 0%, #6366f1 50%, #3b82f6 100%);
  backdrop-filter: blur(12px);
  -webkit-backdrop-filter: blur(12px);
  color: white;
  border: 1px solid rgba(255, 255, 255, 0.25);
  border-radius: 24px;
  cursor: pointer;
  transition: all 0.3s ease;
  box-shadow: 
    0 4px 15px rgba(139, 92, 246, 0.4),
    0 2px 6px rgba(0, 0, 0, 0.15),
    inset 0 1px 0 rgba(255, 255, 255, 0.2);
  -webkit-tap-highlight-color: transparent;
  touch-action: manipulation;
}

.floating-ai-button:hover {
  transform: translateY(-2px);
  box-shadow: 
    0 6px 20px rgba(139, 92, 246, 0.5),
    0 4px 10px rgba(0, 0, 0, 0.2),
    inset 0 1px 0 rgba(255, 255, 255, 0.25);
}

.floating-ai-button:active {
  transform: scale(0.95);
  box-shadow: 
    0 2px 10px rgba(139, 92, 246, 0.3),
    0 1px 4px rgba(0, 0, 0, 0.1);
}

.button-icon {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 28px;
  height: 28px;
  background: rgba(255, 255, 255, 0.2);
  border-radius: 50%;
}

.button-icon i {
  font-size: 1rem;
}

.button-label {
  font-size: 0.9375rem;
  font-weight: 600;
  letter-spacing: 0.01em;
  white-space: nowrap;
}

/* Responsive - hide label on very small screens */
@media (max-width: 360px) {
  .floating-ai-button {
    padding: 0.75rem;
    border-radius: 50%;
  }
  
  .button-label {
    display: none;
  }
  
  .button-icon {
    width: 24px;
    height: 24px;
  }
}
</style>

