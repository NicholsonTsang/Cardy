<template>
  <div class="ai-assistant">
    <!-- AI Button -->
    <button @click="openModal" class="ai-button">
      <i class="pi pi-comments" />
      <span>Ask AI Assistant</span>
    </button>

    <!-- Modal -->
    <Teleport to="body">
      <div v-if="isModalOpen" class="modal-overlay" @click="closeModal">
        <div class="modal-content" @click.stop>
          <!-- Header -->
          <div class="modal-header">
            <div class="header-info">
              <i class="pi pi-comments header-icon" />
              <div>
                <h3 class="header-title">AI Assistant</h3>
                <p class="header-subtitle">{{ contentItemName }}</p>
              </div>
            </div>
            <button @click="closeModal" class="close-button">
              <i class="pi pi-times" />
            </button>
          </div>

          <!-- Chat Container -->
          <div class="chat-container">
            <!-- Messages -->
            <div ref="messagesContainer" class="messages-container">
              <div 
                v-for="message in messages" 
                :key="message.id"
                class="message"
                :class="message.role"
              >
                <div class="message-avatar">
                  <i :class="message.role === 'user' ? 'pi pi-user' : 'pi pi-sparkles'" />
                </div>
                <div class="message-content">
                  <p v-if="message.content" class="message-text">{{ message.content }}</p>
                  <div v-if="message.audio && message.role === 'user'" class="audio-indicator">
                    <i class="pi pi-microphone" />
                    <span>Voice message</span>
                  </div>
                  <span class="message-time">{{ formatTime(message.timestamp) }}</span>
                </div>
              </div>

              <!-- Typing Indicator -->
              <div v-if="isLoading" class="message assistant">
                <div class="message-avatar">
                  <i class="pi pi-sparkles" />
                </div>
                <div class="message-content">
                  <div class="typing-indicator">
                    <span></span>
                    <span></span>
                    <span></span>
                  </div>
                </div>
              </div>

              <!-- Error Message -->
              <div v-if="error" class="error-banner">
                <i class="pi pi-exclamation-triangle" />
                <p>{{ error }}</p>
              </div>
            </div>

            <!-- Input Area -->
            <div class="input-area">
              <!-- Language Selector -->
              <div class="language-selector">
                <select v-model="selectedLanguage" class="language-dropdown">
                  <option v-for="lang in languages" :key="lang.code" :value="lang">
                    {{ lang.flag }} {{ lang.name }}
                  </option>
                </select>
              </div>

              <!-- Input Container -->
              <div class="input-container">
                <!-- Text Input -->
                <input 
                  v-if="inputMode === 'text'"
                  v-model="textInput"
                  type="text"
                  placeholder="Type your message..."
                  class="text-input"
                  @keypress.enter="sendTextMessage"
                  :disabled="isLoading"
                />

                <!-- Voice Recording Status -->
                <div v-else class="voice-status">
                  <div class="voice-indicator" :class="{ recording: isRecording }">
                    <i class="pi pi-microphone" />
                  </div>
                  <span v-if="isRecording" class="recording-text">Recording... Release to send</span>
                  <span v-else class="recording-text">Hold to record</span>
                </div>

                <!-- Input Mode Toggle -->
                <button 
                  @click="toggleInputMode" 
                  class="mode-toggle"
                  :title="inputMode === 'text' ? 'Switch to voice input' : 'Switch to text input'"
                >
                  <i :class="inputMode === 'text' ? 'pi pi-microphone' : 'pi pi-keyboard'" />
                </button>

                <!-- Send/Record Button -->
                <button 
                  v-if="inputMode === 'text'"
                  @click="sendTextMessage"
                  class="send-button"
                  :disabled="!textInput.trim() || isLoading"
                >
                  <i class="pi pi-send" />
                </button>
                <button 
                  v-else
                  @mousedown="startRecording"
                  @mouseup="stopRecording"
                  @touchstart.prevent="startRecording"
                  @touchend.prevent="stopRecording"
                  class="record-button"
                  :class="{ recording: isRecording }"
                  :disabled="isLoading"
                >
                  <i :class="isRecording ? 'pi pi-stop-circle' : 'pi pi-microphone'" />
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </Teleport>

    <!-- Hidden audio element for playback -->
    <audio ref="audioPlayer" style="display: none;"></audio>
  </div>
</template>

<script setup lang="ts">
import { ref, onBeforeUnmount, nextTick, computed } from 'vue'
import { supabase } from '@/lib/supabase'

interface Props {
  contentItemName: string
  contentItemContent: string
  aiMetadata: string
  cardData: {
    card_name: string
    card_description: string
    ai_prompt?: string
  }
}

const props = defineProps<Props>()

interface Message {
  id: string
  role: 'user' | 'assistant'
  content?: string
  audio?: {
    data: string
    format: string
  }
  timestamp: Date
}

// Languages
const languages = [
  { code: 'en', name: 'English', flag: '🇺🇸' },
  { code: 'yue', name: '廣東話', flag: '🇭🇰' },
  { code: 'cmn', name: '普通话', flag: '🇨🇳' },
  { code: 'es', name: 'Español', flag: '🇪🇸' },
  { code: 'fr', name: 'Français', flag: '🇫🇷' },
]

// State
const isModalOpen = ref(false)
const selectedLanguage = ref(languages[0])
const messages = ref<Message[]>([])
const textInput = ref('')
const inputMode = ref<'text' | 'voice'>('text')
const isRecording = ref(false)
const isLoading = ref(false)
const error = ref<string | null>(null)

// Audio
const audioPlayer = ref<HTMLAudioElement | null>(null)
const mediaRecorder = ref<MediaRecorder | null>(null)
const audioChunks = ref<Blob[]>([])
const messagesContainer = ref<HTMLElement | null>(null)

// System Instructions
const systemInstructions = computed(() => {
  const languageName = selectedLanguage.value.name
  
  return `You are an AI assistant for the content item "${props.contentItemName}" within the digital card "${props.cardData.card_name}".

Your role: Provide helpful information about this specific content item to museum/exhibition visitors.

Content Details:
- Item Name: ${props.contentItemName}
- Item Description: ${props.contentItemContent}

${props.aiMetadata ? `Additional Knowledge: ${props.aiMetadata}` : ''}

${props.cardData.ai_prompt ? `Special Instructions: ${props.cardData.ai_prompt}` : ''}

Communication Guidelines:
- Speak ONLY in ${languageName}
- Be conversational and friendly
- Focus specifically on this content item
- Provide engaging and educational responses
- Keep responses concise but informative (2-3 sentences max for chat)
- If asked about other topics, politely redirect to this content item

Remember: You are here to enhance the visitor's understanding of "${props.contentItemName}".`
})

// Methods
function openModal() {
  isModalOpen.value = true
  document.body.style.overflow = 'hidden'
  
  // Send initial greeting if first time
  if (messages.value.length === 0) {
    addAssistantMessage(`Hello! I'm here to help you learn about "${props.contentItemName}". What would you like to know?`)
  }
}

function closeModal() {
  isModalOpen.value = false
  document.body.style.overflow = ''
  if (isRecording.value) {
    stopRecording()
  }
}

function toggleInputMode() {
  inputMode.value = inputMode.value === 'text' ? 'voice' : 'text'
}

async function sendTextMessage() {
  if (!textInput.value.trim() || isLoading.value) return

  const userMessage = textInput.value.trim()
  textInput.value = ''

  // Add user message to chat
  addUserMessage(userMessage)

  // Get AI response (text only)
  await getAIResponse(userMessage)
}

async function startRecording() {
  if (isLoading.value || isRecording.value) return

  try {
    const stream = await navigator.mediaDevices.getUserMedia({ audio: true })
    
    // Use MP3 if available, fallback to webm
    const mimeType = MediaRecorder.isTypeSupported('audio/mp3') 
      ? 'audio/mp3' 
      : MediaRecorder.isTypeSupported('audio/webm')
      ? 'audio/webm'
      : 'audio/ogg'
    
    mediaRecorder.value = new MediaRecorder(stream, { mimeType })
    audioChunks.value = []

    mediaRecorder.value.ondataavailable = (event) => {
      if (event.data.size > 0) {
        audioChunks.value.push(event.data)
      }
    }

    mediaRecorder.value.onstop = async () => {
      const audioBlob = new Blob(audioChunks.value, { type: mimeType })
      await processVoiceInput(audioBlob)
      
      // Stop all tracks
      stream.getTracks().forEach(track => track.stop())
    }

    mediaRecorder.value.start()
    isRecording.value = true
    console.log('Started recording with', mimeType)
    
  } catch (err: any) {
    console.error('Microphone error:', err)
    error.value = 'Microphone access is required for voice input'
  }
}

function stopRecording() {
  if (mediaRecorder.value && isRecording.value) {
    mediaRecorder.value.stop()
    isRecording.value = false
    console.log('Stopped recording')
  }
}

async function processVoiceInput(audioBlob: Blob) {
  isLoading.value = true
  error.value = null

  try {
    console.log('Processing voice input, blob size:', audioBlob.size, 'type:', audioBlob.type)
    
    // Convert audio blob to base64
    const audioBase64 = await blobToBase64(audioBlob)
    const audioFormat = audioBlob.type.includes('mp3') ? 'mp3' : audioBlob.type.includes('webm') ? 'webm' : 'ogg'
    
    console.log('Audio converted to base64, format:', audioFormat, 'length:', audioBase64.length)
    
    // Add user message indicator (will be replaced with transcription)
    const tempMessageId = Date.now().toString()
    messages.value.push({
      id: tempMessageId,
      role: 'user',
      content: '[Processing voice message...]',
      audio: { data: audioBase64, format: audioFormat },
      timestamp: new Date()
    })
    scrollToBottom()

    // Get AI response with voice input
    await getAIResponseWithVoice({
      data: audioBase64,
      format: audioFormat
    })

    // Remove temp message as it will be replaced with the actual response
    messages.value = messages.value.filter(m => m.id !== tempMessageId)

  } catch (err: any) {
    console.error('Voice processing error:', err)
    error.value = err.message || 'Failed to process voice input'
  } finally {
    isLoading.value = false
  }
}

async function getAIResponse(userInput: string) {
  isLoading.value = true
  error.value = null

  try {
    console.log('Getting AI response for text input:', userInput.substring(0, 50))
    
    // Prepare conversation history (only content, no audio)
    const conversationMessages = messages.value
      .filter(msg => msg.content)  // Only messages with text content
      .map(msg => ({
        role: msg.role,
        content: msg.content
      }))

    console.log('Conversation history:', conversationMessages.length, 'messages')

    // Call Edge Function
    const { data, error: funcError } = await supabase.functions.invoke('chat-with-audio', {
      body: {
        messages: conversationMessages,
        systemPrompt: systemInstructions.value,
        language: selectedLanguage.value.code,
        modalities: ['text']  // Text only for text input
      }
    })

    if (funcError) throw funcError
    if (!data.success) throw new Error(data.error)

    console.log('Received AI response:', data.message.content.substring(0, 50))

    // Add assistant message
    addAssistantMessage(data.message.content)

  } catch (err: any) {
    console.error('AI response error:', err)
    error.value = err.message || 'Failed to get AI response'
  } finally {
    isLoading.value = false
  }
}

async function getAIResponseWithVoice(voiceInput: { data: string, format: string }) {
  isLoading.value = true
  error.value = null

  try {
    console.log('Getting AI response for voice input')
    
    // Prepare conversation history (text only, no audio)
    const conversationMessages = messages.value
      .filter(msg => msg.content && !msg.content.includes('[Processing voice message...]'))
      .map(msg => ({
        role: msg.role,
        content: msg.content
      }))

    console.log('Sending voice input to Edge Function...')

    // Call Edge Function with voice input
    const { data, error: funcError } = await supabase.functions.invoke('chat-with-audio', {
      body: {
        messages: conversationMessages,
        systemPrompt: systemInstructions.value,
        language: selectedLanguage.value.code,
        modalities: ['text', 'audio'],  // Request both text and audio
        voiceInput: voiceInput
      }
    })

    if (funcError) throw funcError
    if (!data.success) throw new Error(data.error)

    console.log('Received AI response with audio:', {
      hasContent: !!data.message.content,
      hasAudio: !!data.message.audio
    })

    // Add user message with transcription
    if (data.message.audio?.transcript) {
      addUserMessage(data.message.audio.transcript)
    }

    // Add assistant message
    addAssistantMessage(data.message.content)

    // Play audio response if available
    if (data.message.audio?.data) {
      console.log('Playing audio response...')
      await playAudioFromBase64(data.message.audio.data, 'wav')
    }

  } catch (err: any) {
    console.error('AI voice response error:', err)
    error.value = err.message || 'Failed to get AI response'
  } finally {
    isLoading.value = false
  }
}

// Helper: Convert Blob to Base64
async function blobToBase64(blob: Blob): Promise<string> {
  return new Promise((resolve, reject) => {
    const reader = new FileReader()
    reader.onloadend = () => {
      const base64 = reader.result as string
      // Remove data URL prefix (data:audio/webm;base64,)
      const base64Data = base64.split(',')[1]
      resolve(base64Data)
    }
    reader.onerror = reject
    reader.readAsDataURL(blob)
  })
}

// Helper: Play audio from base64
async function playAudioFromBase64(base64Audio: string, format: string) {
  try {
    const audioBlob = base64ToBlob(base64Audio, `audio/${format}`)
    const audioUrl = URL.createObjectURL(audioBlob)
    
    if (audioPlayer.value) {
      audioPlayer.value.src = audioUrl
      await audioPlayer.value.play()
      
      // Clean up URL after playback
      audioPlayer.value.onended = () => {
        URL.revokeObjectURL(audioUrl)
      }
    }
  } catch (err) {
    console.error('Audio playback error:', err)
  }
}

// Helper: Convert base64 to Blob
function base64ToBlob(base64: string, mimeType: string): Blob {
  const byteCharacters = atob(base64)
  const byteNumbers = new Array(byteCharacters.length)
  for (let i = 0; i < byteCharacters.length; i++) {
    byteNumbers[i] = byteCharacters.charCodeAt(i)
  }
  const byteArray = new Uint8Array(byteNumbers)
  return new Blob([byteArray], { type: mimeType })
}

function addUserMessage(content: string) {
  messages.value.push({
    id: Date.now().toString(),
    role: 'user',
    content,
    timestamp: new Date()
  })
  scrollToBottom()
}

function addAssistantMessage(content: string) {
  messages.value.push({
    id: Date.now().toString(),
    role: 'assistant',
    content,
    timestamp: new Date()
  })
  scrollToBottom()
}

async function scrollToBottom() {
  await nextTick()
  if (messagesContainer.value) {
    messagesContainer.value.scrollTop = messagesContainer.value.scrollHeight
  }
}

function formatTime(date: Date): string {
  return date.toLocaleTimeString('en-US', { 
    hour: 'numeric', 
    minute: '2-digit',
    hour12: true 
  })
}

// Cleanup
onBeforeUnmount(() => {
  if (isRecording.value) {
    stopRecording()
  }
  document.body.style.overflow = ''
})
</script>

<style scoped>
/* AI Button */
.ai-button {
  position: relative;
  width: 100%;
  padding: 0.875rem 1.25rem;
  background: linear-gradient(135deg, #3b82f6, #6366f1);
  border: none;
  border-radius: 0.75rem;
  color: white;
  font-size: 0.875rem;
  font-weight: 600;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 0.5rem;
  transition: all 0.2s;
  box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1);
}

.ai-button:active {
  transform: scale(0.98);
}

/* Modal */
.modal-overlay {
  position: fixed;
  inset: 0;
  z-index: 9999;
  background: rgba(0, 0, 0, 0.85);
  backdrop-filter: blur(4px);
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 1rem;
}

.modal-content {
  width: 100%;
  max-width: 28rem;
  max-height: 90vh;
  background: white;
  border-radius: 1rem;
  overflow: hidden;
  display: flex;
  flex-direction: column;
  animation: slideUp 0.3s ease-out;
}

/* Modal Header */
.modal-header {
  background: linear-gradient(135deg, #3b82f6, #6366f1);
  padding: 1rem;
  display: flex;
  align-items: center;
  justify-content: space-between;
  flex-shrink: 0;
}

.header-info {
  display: flex;
  align-items: center;
  gap: 0.75rem;
}

.header-icon {
  width: 2rem;
  height: 2rem;
  background: rgba(255, 255, 255, 0.2);
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  color: white;
}

.header-title {
  font-size: 1rem;
  font-weight: 600;
  color: white;
  margin: 0;
}

.header-subtitle {
  font-size: 0.75rem;
  color: rgba(255, 255, 255, 0.8);
  margin: 0;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  max-width: 14rem;
}

.close-button {
  width: 2rem;
  height: 2rem;
  background: rgba(255, 255, 255, 0.2);
  border: none;
  border-radius: 50%;
  color: white;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.2s;
}

.close-button:active {
  background: rgba(255, 255, 255, 0.3);
}

/* Chat Container */
.chat-container {
  display: flex;
  flex-direction: column;
  flex: 1;
  min-height: 0;
}

/* Messages Container */
.messages-container {
  flex: 1;
  overflow-y: auto;
  padding: 1rem;
  display: flex;
  flex-direction: column;
  gap: 1rem;
  background: #f9fafb;
}

/* Message */
.message {
  display: flex;
  gap: 0.75rem;
  animation: messageSlide 0.3s ease-out;
}

.message.user {
  flex-direction: row-reverse;
}

.message-avatar {
  width: 2rem;
  height: 2rem;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  font-size: 0.875rem;
}

.message.user .message-avatar {
  background: linear-gradient(135deg, #3b82f6, #6366f1);
  color: white;
}

.message.assistant .message-avatar {
  background: linear-gradient(135deg, #10b981, #059669);
  color: white;
}

.message-content {
  max-width: 70%;
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
}

.message.user .message-content {
  align-items: flex-end;
}

.message-text {
  background: white;
  padding: 0.75rem 1rem;
  border-radius: 1rem;
  font-size: 0.875rem;
  line-height: 1.5;
  color: #111827;
  margin: 0;
  box-shadow: 0 1px 2px rgba(0, 0, 0, 0.05);
  word-wrap: break-word;
}

.message.user .message-text {
  background: linear-gradient(135deg, #3b82f6, #6366f1);
  color: white;
  border-bottom-right-radius: 0.25rem;
}

.message.assistant .message-text {
  border-bottom-left-radius: 0.25rem;
}

.audio-indicator {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.5rem 0.75rem;
  background: rgba(59, 130, 246, 0.1);
  border-radius: 0.5rem;
  font-size: 0.75rem;
  color: #3b82f6;
}

.message-time {
  font-size: 0.625rem;
  color: #9ca3af;
  padding: 0 0.5rem;
}

/* Typing Indicator */
.typing-indicator {
  display: flex;
  gap: 0.25rem;
  padding: 0.75rem 1rem;
  background: white;
  border-radius: 1rem;
  border-bottom-left-radius: 0.25rem;
}

.typing-indicator span {
  width: 0.5rem;
  height: 0.5rem;
  background: #9ca3af;
  border-radius: 50%;
  animation: typing 1.4s infinite;
}

.typing-indicator span:nth-child(2) {
  animation-delay: 0.2s;
}

.typing-indicator span:nth-child(3) {
  animation-delay: 0.4s;
}

/* Error Banner */
.error-banner {
  background: #fee2e2;
  border: 1px solid #fecaca;
  border-radius: 0.5rem;
  padding: 0.75rem;
  display: flex;
  align-items: center;
  gap: 0.5rem;
  color: #991b1b;
  font-size: 0.75rem;
}

/* Input Area */
.input-area {
  background: white;
  border-top: 1px solid #e5e7eb;
  padding: 1rem;
  flex-shrink: 0;
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}

.language-selector {
  display: flex;
  justify-content: center;
}

.language-dropdown {
  padding: 0.5rem 0.75rem;
  border: 1px solid #d1d5db;
  border-radius: 0.5rem;
  font-size: 0.75rem;
  background: white;
  color: #374151;
}

.input-container {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.text-input {
  flex: 1;
  padding: 0.75rem 1rem;
  border: 1px solid #d1d5db;
  border-radius: 1.5rem;
  font-size: 0.875rem;
  outline: none;
  transition: border-color 0.2s;
}

.text-input:focus {
  border-color: #3b82f6;
}

.text-input:disabled {
  background: #f3f4f6;
  color: #9ca3af;
}

.voice-status {
  flex: 1;
  display: flex;
  align-items: center;
  gap: 0.75rem;
  padding: 0.75rem 1rem;
  background: #f3f4f6;
  border-radius: 1.5rem;
}

.voice-indicator {
  width: 2rem;
  height: 2rem;
  border-radius: 50%;
  background: #d1d5db;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #6b7280;
  transition: all 0.2s;
}

.voice-indicator.recording {
  background: #ef4444;
  color: white;
  animation: pulse 1s infinite;
}

.recording-text {
  font-size: 0.875rem;
  color: #6b7280;
  font-weight: 500;
}

.mode-toggle {
  width: 2.5rem;
  height: 2.5rem;
  border-radius: 50%;
  background: #f3f4f6;
  border: none;
  color: #6b7280;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.2s;
  flex-shrink: 0;
}

.mode-toggle:active {
  background: #e5e7eb;
}

.send-button,
.record-button {
  width: 2.5rem;
  height: 2.5rem;
  border-radius: 50%;
  background: linear-gradient(135deg, #3b82f6, #6366f1);
  border: none;
  color: white;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.2s;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
  flex-shrink: 0;
}

.send-button:disabled,
.record-button:disabled {
  background: #e5e7eb;
  color: #9ca3af;
}

.send-button:active:not(:disabled),
.record-button:active:not(:disabled) {
  transform: scale(0.95);
}

.record-button.recording {
  background: #ef4444;
  animation: pulse 1s infinite;
}

/* Animations */
@keyframes slideUp {
  from {
    opacity: 0;
    transform: translateY(1rem);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

@keyframes messageSlide {
  from {
    opacity: 0;
    transform: translateY(0.5rem);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

@keyframes typing {
  0%, 60%, 100% {
    transform: translateY(0);
  }
  30% {
    transform: translateY(-0.5rem);
  }
}

@keyframes pulse {
  0%, 100% {
    opacity: 1;
    transform: scale(1);
  }
  50% {
    opacity: 0.8;
    transform: scale(1.05);
  }
}
</style>

