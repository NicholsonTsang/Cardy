<template>
  <div class="ai-assistant">
    <!-- AI Button -->
    <button @click="openModal" class="ai-button">
      <i class="pi pi-comments" />
      <span>Ask AI Assistant</span>
        </button>

    <!-- Modal -->
    <AIAssistantModal
      :is-open="isModalOpen"
      :show-language-selection="false"
      :conversation-mode="conversationMode"
      :content-item-name="contentItemName"
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
import { ref, computed, watch, nextTick } from 'vue'
import AIAssistantModal from './components/AIAssistantModal.vue'
import ChatInterface from './components/ChatInterface.vue'
import RealtimeInterface from './components/RealtimeInterface.vue'
import { useWebRTCConnection } from './composables/useWebRTCConnection'
import { useChatCompletion } from './composables/useChatCompletion'
import { useVoiceRecording } from './composables/useVoiceRecording'
import { useCostSafeguards } from './composables/useCostSafeguards'
import { useInactivityTimer } from './composables/useInactivityTimer'
import { useMobileLanguageStore } from '@/stores/language'
import type { Message, ConversationMode, AIAssistantProps } from './types'

const props = defineProps<AIAssistantProps>()
const languageStore = useMobileLanguageStore()

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
// COMPUTED
// ============================================================================

const systemInstructions = computed(() => {
  const languageName = languageStore.selectedLanguage.name
  const languageCode = languageStore.selectedLanguage.code
  
  // Language-specific emphasis with voice preference for Chinese
  let languageNote = ''
  if (languageStore.isChinese(languageCode)) {
    if (languageStore.chineseVoice === 'cantonese') {
      languageNote = '\n⚠️ CRITICAL: You MUST speak in CANTONESE (廣東話), NOT Mandarin. Use Cantonese vocabulary, grammar, and expressions. Respond naturally as a native Cantonese speaker.'
    } else {
      languageNote = '\n⚠️ CRITICAL: You MUST speak in MANDARIN (普通話), NOT Cantonese. Use Mandarin vocabulary, grammar, and expressions. Respond naturally as a native Mandarin speaker.'
    }
  } else {
    languageNote = `\n⚠️ CRITICAL: You MUST speak EXCLUSIVELY in ${languageName}. Never use any other language.`
  }
  
  return `You are an AI assistant for the content item "${props.contentItemName}" within the digital card "${props.cardData.card_name}".

Your role: Provide helpful information about this specific content item to museum/exhibition visitors.

Content Details:
- Item Name: ${props.contentItemName}
- Item Description: ${props.contentItemContent}

${props.contentItemKnowledgeBase ? `Additional Knowledge about this item:
${props.contentItemKnowledgeBase}` : ''}

${props.parentContentKnowledgeBase ? `Parent Content Context (for broader understanding):
${props.parentContentKnowledgeBase}` : ''}

${props.cardData.ai_instruction ? `Special Instructions from the Card Creator:
${props.cardData.ai_instruction}` : ''}

Communication Guidelines:${languageNote}
- Be conversational and friendly
- Focus specifically on this content item
- Provide engaging and educational responses
- Keep responses concise but informative (2-3 sentences max for chat)
- If asked about other topics, politely redirect to this content item

Remember: You are here to enhance the visitor's understanding of "${props.contentItemName}".

You are speaking with someone interested in: ${props.contentItemName}. Provide engaging, natural conversation.`
})

const welcomeMessages: Record<string, string> = {
  'en': `Hi! I'm your AI assistant for "${props.contentItemName}". Feel free to ask me anything about this exhibit!`,
  'zh-Hans-cantonese': `你好！我係「${props.contentItemName}」嘅AI助手。有咩想知都可以问我！`,  // Simplified + Cantonese
  'zh-Hans-mandarin': `你好！我是「${props.contentItemName}」的AI助手。有什么想知道的都可以问我！`,  // Simplified + Mandarin
  'zh-Hant-cantonese': `你好！我係「${props.contentItemName}」嘅AI助手。有咩想知都可以問我！`,  // Traditional + Cantonese
  'zh-Hant-mandarin': `你好！我是「${props.contentItemName}」的AI助手。有什麼想知道的都可以問我！`,  // Traditional + Mandarin
  'zh-Hans': `你好！我是「${props.contentItemName}」的AI助手。有什么想知道的都可以问我！`,  // Fallback
  'zh-Hant': `你好！我是「${props.contentItemName}」的AI助手。有什麼想知道的都可以問我！`,  // Fallback
  'ja': `こんにちは！「${props.contentItemName}」のAIアシスタントです。この展示について何でも聞いてください！`,
  'ko': `안녕하세요! "${props.contentItemName}"의 AI 어시스턴트입니다. 이 전시에 대해 무엇이든 물어보세요!`,
  'es': `¡Hola! Soy tu asistente de IA para "${props.contentItemName}". ¡Pregúntame lo que quieras sobre esta exhibición!`,
  'fr': `Bonjour ! Je suis votre assistant IA pour "${props.contentItemName}". N'hésitez pas à me poser des questions sur cette exposition !`,
  'ru': `Привет! Я ваш AI-помощник для "${props.contentItemName}". Спрашивайте меня о чем угодно!`,
  'ar': `مرحبا! أنا مساعدك الذكي لـ "${props.contentItemName}". لا تتردد في طرح أي أسئلة!`,
  'th': `สวัสดี! ฉันเป็น AI ผู้ช่วยของ "${props.contentItemName}" ถามอะไรก็ได้เกี่ยวกับนิทรรศการนี้!`
}

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
  connectionError.value = null // Clear any previous errors
  
  // Add welcome message using voice-aware language code (with fallback)
  const voiceAwareCode = languageStore.getVoiceAwareLanguageCode()
  const welcomeText = welcomeMessages[voiceAwareCode] || 
                     welcomeMessages[languageStore.selectedLanguage.code] || 
                     welcomeMessages['en']
  messages.value = [{
    id: Date.now().toString(),
    role: 'assistant',
    content: welcomeText,
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
    messages.value = [] // Clear messages
    connectionError.value = null // Clear errors when switching
  } else {
    conversationMode.value = 'chat-completion'
    if (realtimeConnection.isConnected.value) {
      disconnectRealtime()
    }
    connectionError.value = null // Clear errors
    // Add welcome message back
    const voiceAwareCode = languageStore.getVoiceAwareLanguageCode()
    const welcomeText = welcomeMessages[voiceAwareCode] || 
                       welcomeMessages[languageStore.selectedLanguage.code] || 
                       welcomeMessages['en']
    messages.value = [{
      id: Date.now().toString(),
      role: 'assistant',
      content: welcomeText,
      timestamp: new Date()
    }]
  }
}

function clearChat() {
  // Clear messages and reset to welcome message
  const voiceAwareCode = languageStore.getVoiceAwareLanguageCode()
  const welcomeText = welcomeMessages[voiceAwareCode] || 
                     welcomeMessages[languageStore.selectedLanguage.code] || 
                     welcomeMessages['en']
  messages.value = [{
    id: Date.now().toString(),
    role: 'assistant',
    content: welcomeText,
    timestamp: new Date()
  }]
  
  // Reset audio state
  firstAudioPlayed.value = false
  
  // Stop any ongoing recording
  if (voiceRecording.isRecording.value) {
    voiceRecording.cancelRecording()
  }
  
  console.log('Chat cleared')
}

// ============================================================================
// CHAT COMPLETION METHODS
// ============================================================================

function toggleInputMode() {
  inputMode.value = inputMode.value === 'text' ? 'voice' : 'text'
}

async function sendTextMessage(text: string) {
  if (!text.trim()) return
  
  // Add user message
  messages.value.push({
    id: Date.now().toString(),
    role: 'user',
    content: text,
    timestamp: new Date()
  })

  // Create streaming assistant message
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
    
    // Finalize message
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
    
    // Add user message with transcription
    messages.value.push({
      id: Date.now().toString(),
      role: 'user',
      content: result.userTranscription,
      timestamp: new Date(),
      audio: { data: '', format: 'wav' }
    })
    
    // Add assistant message
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
  console.log('🚀 ========== CONNECTING TO REALTIME API ==========')
  console.log('🌍 Selected Language Object:', languageStore.selectedLanguage)
  console.log('🔤 Text Language Code:', languageStore.selectedLanguage.code)
  console.log('🎤 Voice-Aware Language Code:', voiceAwareCode)
  console.log('📛 Language Name:', languageStore.selectedLanguage.name)
  console.log('📋 System Instructions Preview (first 500 chars):')
  console.log(systemInstructions.value.substring(0, 500) + '...')
  console.log('🚀 ===============================================')
  
  // Clear any previous errors
  connectionError.value = null
  
  try {
    // Set up transcript callbacks before connecting
    realtimeConnection.onUserTranscript((text: string) => {
      // Add user message to chat
      messages.value.push({
        id: Date.now().toString(),
        role: 'user',
        content: text,
        timestamp: new Date()
      })
      console.log('💬 Added user message:', text)
    })
    
    realtimeConnection.onAssistantTranscript((text: string) => {
      // Add assistant message to chat
      messages.value.push({
        id: Date.now().toString(),
        role: 'assistant',
        content: text,
        timestamp: new Date()
      })
      console.log('💬 Added assistant message:', text)
    })
    
    // Connect via WebRTC
    await realtimeConnection.connect(
      voiceAwareCode,
      systemInstructions.value
    )
    
    // Start inactivity timer
    inactivityTimer.startTimer()
    
    // Cost safeguards
    costSafeguards.addSafeguards()
    
    // Clear error on success
    connectionError.value = null
  } catch (err: any) {
    console.error('❌ Realtime connection error:', err)
    
    // Set error message for display
    if (err.message?.includes('Relay server required') || err.message?.includes('VITE_OPENAI_RELAY_URL')) {
      connectionError.value = 'Realtime voice mode requires additional setup. Please use Chat Mode instead (text or voice recording).'
    } else if (err.message?.includes('microphone') || err.message?.includes('getUserMedia')) {
      connectionError.value = 'Microphone access denied. Please allow microphone permissions in your browser settings and try again.'
    } else if (err.message?.includes('network') || err.message?.includes('fetch')) {
      connectionError.value = 'Network error. Please check your internet connection and try again.'
    } else if (err.message?.includes('OpenAI')) {
      connectionError.value = 'Failed to connect to AI service. Please try again in a moment.'
    } else if (err.message?.includes('CORS')) {
      connectionError.value = 'Connection blocked. Please use Chat Mode instead (text or voice recording).'
    } else if (err.message) {
      connectionError.value = `Connection failed: ${err.message}`
    } else {
      connectionError.value = 'Failed to start live call. Please try Chat Mode instead.'
    }
    
    await realtimeConnection.disconnect()
  }
}

function disconnectRealtime() {
  console.log('Disconnecting realtime...')
  realtimeConnection.disconnect()
  costSafeguards.removeSafeguards()
  inactivityTimer.clearTimer()
  
  // Add goodbye message
  if (messages.value.length > 0) {
    messages.value.push({
      id: Date.now().toString(),
      role: 'assistant',
      content: 'Call ended. Switch back to chat mode or start a new call.',
      timestamp: new Date()
    })
  }
}
</script>

<style scoped>
.ai-assistant {
  position: relative;
}

.ai-button {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.75rem 1.25rem;
  background: linear-gradient(135deg, #3b82f6 0%, #2563eb 100%);
  color: white;
  border: none;
  border-radius: 12px;
  font-size: 1rem;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
  box-shadow: 0 4px 6px -1px rgba(59, 130, 246, 0.3);
}

.ai-button:hover {
  background: linear-gradient(135deg, #2563eb 0%, #1d4ed8 100%);
  transform: translateY(-2px);
  box-shadow: 0 6px 8px -1px rgba(59, 130, 246, 0.4);
}

.ai-button i {
  font-size: 1.25rem;
}
</style>

