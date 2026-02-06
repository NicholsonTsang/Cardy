<template>
  <div class="ai-assistant">
    <!-- AI Badge - Context-aware text based on content mode -->
    <button @click="openModal" class="ai-badge">
      <span class="ai-badge-icon">✨</span>
      <span class="ai-badge-text">{{ badgeText }}</span>
      <i class="pi pi-chevron-right ai-badge-arrow" />
    </button>

    <!-- Modal -->
    <AIAssistantModal
      :is-open="isModalOpen"
      :show-language-selection="false"
      :conversation-mode="conversationMode"
      :input-mode="inputMode"
      :content-item-name="contentItemName"
      :assistant-mode="'content-item'"
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
import { ref, computed, watch, onMounted, nextTick, onUnmounted, inject } from 'vue'
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
import { buildContentItemPrompt } from './utils/promptBuilder'
import type { Message, ConversationMode, CardData } from './types'

// Content Mode types (includes 'detail' for item detail view)
type ContentMode = 'single' | 'list' | 'grid' | 'cards' | 'detail'

// Content Item Assistant Props
interface Props {
  contentItemName: string
  contentItemContent: string
  contentItemKnowledgeBase: string
  parentContentName?: string
  parentContentDescription?: string
  parentContentKnowledgeBase?: string
  cardData: CardData
  contentMode?: ContentMode // The current content display mode
  itemCount?: number // Number of items (for list/grid modes)
  categoryCount?: number // Number of categories (for grouped mode)
}

const props = withDefaults(defineProps<Props>(), {
  contentMode: 'detail',
  itemCount: 0,
  categoryCount: 0
})
const languageStore = useMobileLanguageStore()
const { t } = useI18n()

// ============================================================================
// COMPOSABLES
// ============================================================================

const chatCompletion = useChatCompletion()
const voiceRecording = useVoiceRecording()
const realtimeConnection = useWebRTCConnection()

// Route-level disconnect registry
const aiDisconnectRegistry = inject<{
  registerDisconnect: (cb: () => void) => void
  unregisterDisconnect: (cb: () => void) => void
}>('aiDisconnectRegistry', null as any)

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

// Badge text based on content mode
const badgeText = computed(() => {
  switch (props.contentMode) {
    case 'single':
      return t('mobile.ai_ask_about_content')
    case 'list':
      return t('mobile.ai_find_items')
    case 'grid':
      return t('mobile.ai_explore_gallery')
    case 'cards':
      return t('mobile.ai_explore_featured')
    case 'detail':
    default:
      return t('mobile.ask_about_item')
  }
})

// Mode-specific context description
const modeContext = computed(() => {
  switch (props.contentMode) {
    case 'single':
      return `This is a single-page article/content. Help the visitor understand and explore this content in depth.`
    case 'list':
      return `This is a list of ${props.itemCount || 'multiple'} items. Help visitors discover items and understand what's available.`
    case 'grid':
      return `This is a visual gallery with ${props.itemCount || 'multiple'} items. Help visitors explore the visual content and find specific items.`
    case 'cards':
      return `These are featured items displayed as cards. Help visitors learn about the featured content and make recommendations.`
    case 'detail':
    default:
      return `This is a detailed view of a specific item. Provide in-depth information about this particular item.`
  }
})

// OPTIMIZATION: Use ref instead of computed to prevent rebuilding on every render
// Same optimization as CardLevelAssistant - enables prompt caching and reduces CPU usage
const systemInstructions = ref('')

// Build prompt once on mount
onMounted(() => {
  systemInstructions.value = buildContentItemPrompt({
    cardName: props.cardData.card_name,
    cardDescription: props.cardData.card_description,
    languageName: languageStore.selectedLanguage.name,
    languageCode: languageStore.selectedLanguage.code,
    chineseVoice: languageStore.chineseVoice as 'mandarin' | 'cantonese' | undefined,
    knowledgeBase: props.cardData.ai_knowledge_base,
    customInstruction: props.cardData.ai_instruction,
    contentItemName: props.contentItemName,
    contentItemContent: props.contentItemContent,
    contentItemKnowledge: props.contentItemKnowledgeBase,
    parentContext: props.parentContentName ? {
      name: props.parentContentName,
      description: props.parentContentDescription,
      knowledge: props.parentContentKnowledgeBase
    } : undefined,
    modeContext: modeContext.value
  })
})

// Rebuild only when actual dependencies change
watch(
  [
    () => languageStore.selectedLanguage.code,
    () => languageStore.chineseVoice,
    () => props.cardData.card_name,
    () => props.cardData.card_description,
    () => props.cardData.ai_knowledge_base,
    () => props.cardData.ai_instruction,
    () => props.contentItemName,
    () => props.contentItemContent,
    () => props.contentItemKnowledgeBase,
    () => props.parentContentName,
    () => props.parentContentDescription,
    () => props.parentContentKnowledgeBase,
    () => modeContext.value
  ],
  () => {
    systemInstructions.value = buildContentItemPrompt({
      cardName: props.cardData.card_name,
      cardDescription: props.cardData.card_description,
      languageName: languageStore.selectedLanguage.name,
      languageCode: languageStore.selectedLanguage.code,
      chineseVoice: languageStore.chineseVoice as 'mandarin' | 'cantonese' | undefined,
      knowledgeBase: props.cardData.ai_knowledge_base,
      customInstruction: props.cardData.ai_instruction,
      contentItemName: props.contentItemName,
      contentItemContent: props.contentItemContent,
      contentItemKnowledge: props.contentItemKnowledgeBase,
      parentContext: props.parentContentName ? {
        name: props.parentContentName,
        description: props.parentContentDescription,
        knowledge: props.parentContentKnowledgeBase
      } : undefined,
      modeContext: modeContext.value
    })
  }
)

// Mode-specific welcome message key
// Propagate runtime errors from WebRTC composable to UI
watch(
  () => realtimeConnection.error.value,
  (err) => {
    if (err && isModalOpen.value && conversationMode.value === 'realtime') {
      connectionError.value = err
    }
  }
)

const welcomeKey = computed(() => {
  switch (props.contentMode) {
    case 'single':
      return 'mobile.ai_welcome_single'
    case 'list':
      return 'mobile.ai_welcome_list'
    case 'grid':
      return 'mobile.ai_welcome_grid'
    case 'cards':
      return 'mobile.ai_welcome_cards'
    case 'detail':
    default:
      return 'mobile.ai_welcome_detail'
  }
})

const welcomeText = computed(() => {
  const params = { 
    name: props.contentItemName,
    count: props.itemCount || props.categoryCount || 0
  }
  
  // Check for custom welcome message from card settings
  // For 'detail' mode (specific item), use ai_welcome_item if set
  // For list/navigation modes, use ai_welcome_general if set (card-level)
  if (props.contentMode === 'detail' && props.cardData.ai_welcome_item) {
    // Replace {name} placeholder with actual item name
    return props.cardData.ai_welcome_item.replace(/{name}/g, props.contentItemName)
  }
  
  // For list views (single, grouped, list, grid, inline), check if custom general welcome exists
  if (props.contentMode !== 'detail' && props.cardData.ai_welcome_general) {
    return props.cardData.ai_welcome_general
  }
  
  // Fall back to default i18n messages
  return t(welcomeKey.value, params)
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

useCostSafeguards(
  realtimeConnection.isConnected,
  realtimeConnection.status,
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
  
  // Add welcome message using reactive computed property
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
    messages.value = [] // Clear messages
    connectionError.value = null // Clear errors when switching
  } else {
    conversationMode.value = 'chat-completion'
    if (realtimeConnection.isConnected.value) {
      disconnectRealtime()
    }
    connectionError.value = null // Clear errors
    // Add welcome message back
    messages.value = [{
      id: Date.now().toString(),
      role: 'assistant',
      content: welcomeText.value,
      timestamp: new Date()
    }]
  }
}

function clearChat() {
  // Clear messages and reset to welcome message
  messages.value = [{
    id: Date.now().toString(),
    role: 'assistant',
    content: welcomeText.value,
    timestamp: new Date()
  }]
  
  // Reset audio state
  firstAudioPlayed.value = false
  
  // Stop any ongoing recording
  if (voiceRecording.isRecording.value) {
    voiceRecording.cancelRecording()
  }
  
  // Chat cleared
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
    })
    
    realtimeConnection.onAssistantTranscript((text: string) => {
      // Add assistant message to chat
      messages.value.push({
        id: Date.now().toString(),
        role: 'assistant',
        content: text,
        timestamp: new Date()
      })
    })
    
    // Connect via WebRTC
    // Pass custom welcome message (ai_welcome_item with {name} replaced) for voice greeting if configured
    let customWelcome: string | undefined
    if (props.cardData.ai_welcome_item) {
      customWelcome = props.cardData.ai_welcome_item.replace(/{name}/g, props.contentItemName)
    }
    
    await realtimeConnection.connect(
      voiceAwareCode,
      systemInstructions.value,
      customWelcome
    )
    
    // Start inactivity timer
    inactivityTimer.startTimer()

    // Clear error on success
    connectionError.value = null
  } catch (err: any) {
    console.error('❌ Realtime connection error:', err)
    
    // Set error message for display
    if (err.message?.includes('Backend server required') || err.message?.includes('VITE_BACKEND_URL')) {
      connectionError.value = 'Realtime voice mode requires backend server. Please use Chat Mode instead (text or voice recording).'
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
  realtimeConnection.disconnect()
  inactivityTimer.clearTimer()
  
  // Add goodbye message
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

// Register with route-level disconnect registry
if (aiDisconnectRegistry) {
  aiDisconnectRegistry.registerDisconnect(disconnectRealtime)

  onUnmounted(() => {
    aiDisconnectRegistry.unregisterDisconnect(disconnectRealtime)
  })
}
</script>

<style scoped>
.ai-assistant {
  position: relative;
}

/* AI Badge - Consistent purple gradient style */
.ai-badge {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  width: 100%;
  max-width: 400px;
  margin: 0 auto;
  padding: 0.875rem 1.125rem;
  background: linear-gradient(135deg, rgba(139, 92, 246, 0.25) 0%, rgba(59, 130, 246, 0.25) 100%);
  border: 1px solid rgba(139, 92, 246, 0.4);
  border-radius: 1rem;
  color: white;
  font-size: 0.9375rem;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.3s ease;
  -webkit-tap-highlight-color: transparent;
  touch-action: manipulation;
  position: relative;
  overflow: hidden;
  box-shadow: 0 4px 12px rgba(139, 92, 246, 0.2);
}

/* Shimmer effect */
.ai-badge::before {
  content: '';
  position: absolute;
  top: 0;
  left: -100%;
  width: 100%;
  height: 100%;
  background: linear-gradient(
    90deg,
    transparent 0%,
    rgba(255, 255, 255, 0.1) 50%,
    transparent 100%
  );
  animation: shimmer 3s ease-in-out infinite;
}

@keyframes shimmer {
  0% {
    left: -100%;
  }
  100% {
    left: 100%;
  }
}

.ai-badge:hover {
  background: linear-gradient(135deg, rgba(139, 92, 246, 0.35) 0%, rgba(59, 130, 246, 0.35) 100%);
  border-color: rgba(139, 92, 246, 0.5);
}

.ai-badge:active {
  transform: scale(0.98);
}

.ai-badge-icon {
  font-size: 1.125rem;
}

.ai-badge-text {
  flex: 1;
  text-align: left;
  font-weight: 600;
  letter-spacing: 0.01em;
}

.ai-badge-arrow {
  font-size: 0.875rem;
  opacity: 0.6;
  transition: transform 0.2s ease;
}

.ai-badge:hover .ai-badge-arrow,
.ai-badge:active .ai-badge-arrow {
  transform: translateX(3px);
  opacity: 0.9;
}
</style>

