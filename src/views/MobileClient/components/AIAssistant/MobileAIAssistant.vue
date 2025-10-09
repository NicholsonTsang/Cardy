<template>
  <div class="ai-assistant-container">
    <!-- Language Selection (shown when disconnected) -->
    <div v-if="!isConnected" class="language-selection">
      <h3>{{ $t('mobile.select_language') }}</h3>
      <div class="language-grid">
        <button
          v-for="lang in languages"
          :key="lang.code"
          @click="selectedLanguage = lang"
          :class="{ active: selectedLanguage?.code === lang.code }"
          class="language-btn"
        >
          <span class="flag">{{ lang.flag }}</span>
          <span class="name">{{ lang.name }}</span>
        </button>
      </div>
      
      <button
        v-if="selectedLanguage"
        @click="startConversation"
        :disabled="isConnecting"
        class="start-btn"
      >
        {{ isConnecting ? $t('mobile.connecting') : $t('mobile.start_conversation') }}
      </button>
    </div>
    
    <!-- Conversation Interface (shown when connected) -->
    <div v-else class="conversation-interface">
      <!-- Header -->
      <div class="header">
        <div class="status">
          <span class="status-dot" :class="status"></span>
          <span>{{ statusText }}</span>
        </div>
        <button @click="endConversation" class="end-btn">
          {{ $t('mobile.end_call') }}
        </button>
      </div>
      
      <!-- Messages -->
      <div class="messages" ref="messagesContainer">
        <div
          v-for="message in messages"
          :key="message.id"
          :class="['message', message.role]"
        >
          <div class="content">{{ message.content }}</div>
        </div>
      </div>
      
      <!-- Audio Indicator -->
      <div v-if="isSpeaking" class="speaking-indicator">
        <span class="pulse"></span>
        <span>{{ $t('mobile.ai_speaking') }}</span>
      </div>
      
      <!-- Error Display -->
      <div v-if="error" class="error-message">
        {{ error }}
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onUnmounted, nextTick } from 'vue'
import { useI18n } from 'vue-i18n'
import { useRealtimeConnection } from './composables/useRealtimeConnection'
import { useCostSafeguards } from './composables/useCostSafeguards'
import { useInactivityTimer } from './composables/useInactivityTimer'

// Props
interface Props {
  contentItemName: string
  contentItemContent: string
  contentItemKnowledgeBase: string
  parentContentKnowledgeBase: string
  cardData: {
    card_name: string
    card_description: string
    ai_instruction?: string
    ai_knowledge_base?: string
  }
}

const props = defineProps<Props>()
const { t } = useI18n()

// Language configuration
const languages = [
  { code: 'en', name: 'English', flag: '🇬🇧' },
  { code: 'zh-HK', name: '廣東話', flag: '🇭🇰' },
  { code: 'zh-CN', name: '普通话', flag: '🇨🇳' },
  { code: 'ja', name: '日本語', flag: '🇯🇵' },
  { code: 'ko', name: '한국어', flag: '🇰🇷' },
  { code: 'es', name: 'Español', flag: '🇪🇸' },
  { code: 'fr', name: 'Français', flag: '🇫🇷' },
  { code: 'ru', name: 'Русский', flag: '🇷🇺' },
  { code: 'ar', name: 'العربية', flag: '🇸🇦' },
  { code: 'th', name: 'ไทย', flag: '🇹🇭' }
]

// State
const selectedLanguage = ref<typeof languages[0] | null>(null)
const messages = ref<Array<{ id: string; role: 'user' | 'assistant'; content: string }>>([])
const messagesContainer = ref<HTMLElement>()

// Realtime connection
const realtime = useRealtimeConnection()
const { isConnected, status, error, isSpeaking, connect, disconnect, interrupt } = realtime

// Cost safeguards
const costSafeguards = useCostSafeguards(isConnected, disconnect)

// Inactivity timer (60 seconds)
const inactivityTimer = useInactivityTimer(60000, disconnect)

// Computed
const isConnecting = computed(() => status.value === 'connecting')

const statusText = computed(() => {
  switch (status.value) {
    case 'connecting': return t('mobile.connecting')
    case 'connected': return t('mobile.connected')
    case 'error': return t('mobile.connection_error')
    default: return t('mobile.disconnected')
  }
})

// Build system instructions
const systemInstructions = computed(() => {
  const aiInstruction = props.cardData.ai_instruction || 
    `You are an AI assistant for the digital card "${props.cardData.card_name}".`
  
  const knowledgeBase = [
    props.cardData.ai_knowledge_base,
    props.parentContentKnowledgeBase,
    props.contentItemKnowledgeBase
  ].filter(Boolean).join('\n\n')
  
  return `${aiInstruction}

Your role: Provide helpful information about this specific content item to museum/exhibition visitors.

Content Details:
- Item Name: ${props.contentItemName}
- Item Description: ${props.contentItemContent}

${knowledgeBase ? `Additional Knowledge:\n${knowledgeBase}` : ''}

Communication Guidelines:
- Speak ONLY in ${selectedLanguage.value?.name || 'English'}
- Be conversational and friendly
- Focus specifically on this content item
- Provide engaging and educational responses
- Keep responses concise but informative (2-3 sentences max)
- If asked about other topics, politely redirect to this content item

Remember: You are here to enhance the visitor's understanding of "${props.contentItemName}".`
})

// Start conversation
async function startConversation() {
  if (!selectedLanguage.value) return
  
  try {
    // Connect to realtime API
    const ws = await connect(
      selectedLanguage.value.code,
      systemInstructions.value
    )
    
    // Set up message handlers
    ws.onmessage = async (event) => {
      try {
        const data = typeof event.data === 'string' 
          ? JSON.parse(event.data)
          : JSON.parse(await event.data.text())
        
        // Handle transcripts
        if (data.type === 'response.output_audio_transcript.delta' && data.delta) {
          updateAssistantMessage(data.delta)
        }
        
        if (data.type === 'conversation.item.input_audio_transcription.completed' && data.transcript) {
          addUserMessage(data.transcript)
        }
        
        // Reset inactivity timer on any activity
        inactivityTimer.resetTimer()
      } catch (err) {
        console.error('Message handling error:', err)
      }
    }
    
    // Start inactivity timer
    inactivityTimer.startTimer()
    
    // Add welcome message
    addAssistantMessage(t('mobile.welcome_message', { name: props.contentItemName }))
    
  } catch (err) {
    console.error('Failed to start conversation:', err)
  }
}

// End conversation
function endConversation() {
  disconnect()
  inactivityTimer.stopTimer()
  messages.value = []
  selectedLanguage.value = null
}

// Message management
function addUserMessage(content: string) {
  messages.value.push({
    id: Date.now().toString(),
    role: 'user',
    content
  })
  scrollToBottom()
}

function addAssistantMessage(content: string) {
  messages.value.push({
    id: Date.now().toString(),
    role: 'assistant',
    content
  })
  scrollToBottom()
}

function updateAssistantMessage(delta: string) {
  const lastMessage = messages.value[messages.value.length - 1]
  if (!lastMessage || lastMessage.role !== 'assistant') {
    addAssistantMessage(delta)
  } else {
    lastMessage.content += delta
  }
  scrollToBottom()
}

function scrollToBottom() {
  nextTick(() => {
    if (messagesContainer.value) {
      messagesContainer.value.scrollTop = messagesContainer.value.scrollHeight
    }
  })
}

// Cleanup on unmount
onUnmounted(() => {
  disconnect()
  inactivityTimer.stopTimer()
})
</script>

<style scoped>
.ai-assistant-container {
  position: fixed;
  inset: 0;
  background: white;
  display: flex;
  flex-direction: column;
  z-index: 9999;
}

/* Language Selection */
.language-selection {
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 2rem;
}

.language-selection h3 {
  margin-bottom: 2rem;
  font-size: 1.5rem;
  color: #333;
}

.language-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(120px, 1fr));
  gap: 1rem;
  width: 100%;
  max-width: 600px;
  margin-bottom: 2rem;
}

.language-btn {
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 1rem;
  border: 2px solid #e0e0e0;
  border-radius: 12px;
  background: white;
  cursor: pointer;
  transition: all 0.2s;
}

.language-btn:hover {
  border-color: #3b82f6;
  transform: translateY(-2px);
}

.language-btn.active {
  border-color: #3b82f6;
  background: #eff6ff;
}

.language-btn .flag {
  font-size: 2rem;
  margin-bottom: 0.5rem;
}

.language-btn .name {
  font-size: 0.875rem;
  color: #666;
}

.start-btn {
  padding: 1rem 3rem;
  font-size: 1.125rem;
  font-weight: 600;
  color: white;
  background: #3b82f6;
  border: none;
  border-radius: 50px;
  cursor: pointer;
  transition: all 0.2s;
}

.start-btn:hover:not(:disabled) {
  background: #2563eb;
  transform: scale(1.05);
}

.start-btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

/* Conversation Interface */
.conversation-interface {
  flex: 1;
  display: flex;
  flex-direction: column;
}

.header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1rem;
  background: #f8f9fa;
  border-bottom: 1px solid #e0e0e0;
}

.status {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.status-dot {
  width: 10px;
  height: 10px;
  border-radius: 50%;
  background: #ccc;
}

.status-dot.connected {
  background: #10b981;
  animation: pulse 2s infinite;
}

.status-dot.connecting {
  background: #f59e0b;
  animation: pulse 1s infinite;
}

.status-dot.error {
  background: #ef4444;
}

.end-btn {
  padding: 0.5rem 1rem;
  color: white;
  background: #ef4444;
  border: none;
  border-radius: 6px;
  cursor: pointer;
  font-weight: 500;
}

.end-btn:hover {
  background: #dc2626;
}

.messages {
  flex: 1;
  overflow-y: auto;
  padding: 1rem;
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.message {
  max-width: 80%;
  padding: 0.75rem 1rem;
  border-radius: 12px;
  word-wrap: break-word;
}

.message.user {
  align-self: flex-end;
  background: #3b82f6;
  color: white;
}

.message.assistant {
  align-self: flex-start;
  background: #f3f4f6;
  color: #333;
}

.speaking-indicator {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 0.5rem;
  padding: 1rem;
  background: #eff6ff;
  border-top: 1px solid #e0e0e0;
}

.pulse {
  width: 12px;
  height: 12px;
  border-radius: 50%;
  background: #3b82f6;
  animation: pulse 1s infinite;
}

.error-message {
  padding: 1rem;
  background: #fef2f2;
  color: #dc2626;
  border-top: 1px solid #fecaca;
}

@keyframes pulse {
  0%, 100% {
    opacity: 1;
  }
  50% {
    opacity: 0.5;
  }
}
</style>
