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
      :show-language-selection="showLanguageSelection"
      :conversation-mode="conversationMode"
      :content-item-name="contentItemName"
      @close="closeModal"
      @select-language="selectLanguage"
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
      />

      <!-- Realtime Mode -->
      <RealtimeInterface
        v-else-if="conversationMode === 'realtime'"
        :is-connected="realtimeConnection.isConnected.value"
        :is-speaking="realtimeConnection.isSpeaking.value"
        :status="realtimeConnection.status.value"
        :status-text="realtimeStatusText"
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
import type { Message, Language, ConversationMode, AIAssistantProps } from './types'

const props = defineProps<AIAssistantProps>()

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
const showLanguageSelection = ref(true)
const selectedLanguage = ref<Language | null>(null)
const conversationMode = ref<ConversationMode>('chat-completion')
const messages = ref<Message[]>([])
const inputMode = ref<'text' | 'voice'>('text')
const loadingStatus = ref('')
const firstAudioPlayed = ref(false)

// ============================================================================
// COMPUTED
// ============================================================================

const systemInstructions = computed(() => {
  const languageName = selectedLanguage.value?.name || 'English'
  const languageCode = selectedLanguage.value?.code || 'en'
  
  // Language-specific emphasis
  let languageNote = ''
  if (languageCode === 'zh-HK') {
    languageNote = '\n⚠️ CRITICAL: You MUST speak in CANTONESE (廣東話), NOT Mandarin. Use Cantonese vocabulary, grammar, and expressions.'
  } else if (languageCode === 'zh-CN') {
    languageNote = '\n⚠️ CRITICAL: You MUST speak in MANDARIN (普通話), NOT Cantonese. Use Mandarin vocabulary, grammar, and expressions.'
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

${props.cardData.ai_prompt ? `Special Instructions from the Card Creator:
${props.cardData.ai_prompt}` : ''}

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
  'zh-HK': `你好！我係「${props.contentItemName}」嘅AI助手。有咩想知都可以問我！`,
  'zh-CN': `你好！我是「${props.contentItemName}」的AI助手。有什么想知道的都可以问我！`,
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
  switch (realtimeConnection.status) {
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
  showLanguageSelection.value = true
  selectedLanguage.value = null
  messages.value = []
  firstAudioPlayed.value = false
}

function closeModal() {
  isModalOpen.value = false
  document.body.style.overflow = ''
  showLanguageSelection.value = true
  selectedLanguage.value = null
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

function selectLanguage(language: Language) {
  selectedLanguage.value = language
  showLanguageSelection.value = false
    
    // Add welcome message
  const welcomeText = welcomeMessages[language.code] || welcomeMessages['en']
  messages.value = [{
    id: Date.now().toString(),
    role: 'assistant',
    content: welcomeText,
    timestamp: new Date()
  }]
}

function toggleConversationMode() {
  if (conversationMode.value === 'chat-completion') {
    conversationMode.value = 'realtime'
    messages.value = [] // Clear messages
  } else {
    conversationMode.value = 'chat-completion'
    if (realtimeConnection.isConnected.value) {
      disconnectRealtime()
    }
    // Add welcome message back
    const welcomeText = welcomeMessages[selectedLanguage.value?.code || 'en'] || welcomeMessages['en']
    messages.value = [{
      id: Date.now().toString(),
      role: 'assistant',
      content: welcomeText,
      timestamp: new Date()
    }]
  }
}

// ============================================================================
// CHAT COMPLETION METHODS
// ============================================================================

function toggleInputMode() {
  inputMode.value = inputMode.value === 'text' ? 'voice' : 'text'
}

async function sendTextMessage(text: string) {
  if (!text.trim() || !selectedLanguage.value) return
  
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
  if (!audioBlob || !selectedLanguage.value) return
  
  loadingStatus.value = 'Transcribing voice...'
  
  try {
    const result = await chatCompletion.getAIResponseWithVoice(
      audioBlob,
      messages.value,
      systemInstructions.value,
      selectedLanguage.value.code
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
  if (!selectedLanguage.value) return
  
  firstAudioPlayed.value = true
  await chatCompletion.playMessageAudio(message, selectedLanguage.value.code)
}

// ============================================================================
// REALTIME METHODS
// ============================================================================

async function connectRealtime() {
  if (!selectedLanguage.value) return
  
  console.log('🚀 ========== CONNECTING TO REALTIME API ==========')
  console.log('🌍 Selected Language Object:', selectedLanguage.value)
  console.log('🔤 Language Code:', selectedLanguage.value.code)
  console.log('📛 Language Name:', selectedLanguage.value.name)
  console.log('📋 System Instructions Preview (first 500 chars):')
  console.log(systemInstructions.value.substring(0, 500) + '...')
  console.log('🚀 ===============================================')
  
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
      selectedLanguage.value.code,
      systemInstructions.value
    )
    
    // Start inactivity timer
    inactivityTimer.startTimer()
    
    // Cost safeguards
    costSafeguards.addSafeguards()
  } catch (err: any) {
    console.error('❌ Realtime connection error:', err)
    await realtimeConnection.disconnect()
  }
}

function disconnectRealtime() {
  console.log('Disconnecting realtime...')
  realtimeConnection.disconnect()
  costSafeguards.removeSafeguards()
  inactivityTimer.stopTimer()
  
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

