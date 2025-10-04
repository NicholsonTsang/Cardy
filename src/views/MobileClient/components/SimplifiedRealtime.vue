<template>
  <div class="ai-assistant">
    <!-- AI Button -->
    <button @click="openModal" class="ai-button">
      <i class="pi pi-comments" />
      <span>Ask AI Assistant</span>
      <div v-if="isConnected" class="status-dot" />
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

          <!-- Body -->
          <div class="modal-body">
            <!-- Error Message -->
            <div v-if="error" class="error-message">
              <i class="pi pi-exclamation-triangle" />
              <p>{{ error }}</p>
            </div>

            <!-- Not Connected -->
            <div v-if="!isConnected && !isConnecting" class="setup-section">
              <!-- Language Selection -->
              <div class="form-group">
                <label>Language</label>
                <select v-model="selectedLanguage" class="language-select">
                  <option v-for="lang in languages" :key="lang.code" :value="lang">
                    {{ lang.flag }} {{ lang.name }}
                  </option>
                </select>
              </div>

              <!-- Start Button -->
              <button 
                @click="startVoiceChat" 
                :disabled="!isMicReady || isConnecting"
                class="start-button"
                :class="{ disabled: !isMicReady || isConnecting }"
              >
                <i class="pi pi-microphone" />
                <span>{{ isMicReady ? 'Start Voice Chat' : 'Microphone Required' }}</span>
              </button>
            </div>

            <!-- Connecting -->
            <div v-else-if="isConnecting" class="connecting-section">
              <div class="spinner" />
              <p>Connecting to AI...</p>
            </div>

            <!-- Connected -->
            <div v-else class="connected-section">
              <div class="status-card">
                <div class="status-info">
                  <div class="mic-icon" :class="statusClass">
                    <i class="pi pi-microphone" />
                  </div>
                  <div>
                    <p class="status-text">{{ statusText }}</p>
                    <p class="language-text">{{ selectedLanguage.name }}</p>
                  </div>
                </div>
                <button @click="disconnect" class="end-button">
                  End Chat
                </button>
              </div>

              <div class="instructions">
                <i class="pi pi-info-circle" />
                <p>Start speaking to ask questions about "{{ contentItemName }}". The AI will respond with voice.</p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </Teleport>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, onBeforeUnmount, computed } from 'vue'
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

// Languages
const languages = [
  { code: 'en', name: 'English', flag: '🇺🇸' },
  { code: 'zh-HK', name: '廣東話 (Cantonese)', flag: '🇭🇰' },
  { code: 'zh-CN', name: '普通话 (Mandarin)', flag: '🇨🇳' },
  { code: 'es', name: 'Español (Spanish)', flag: '🇪🇸' },
  { code: 'fr', name: 'Français (French)', flag: '🇫🇷' },
  { code: 'ja', name: '日本語 (Japanese)', flag: '🇯🇵' },
  { code: 'ko', name: '한국어 (Korean)', flag: '🇰🇷' },
  { code: 'ru', name: 'Русский (Russian)', flag: '🇷🇺' },
  { code: 'ar', name: 'العربية (Arabic)', flag: '🇸🇦' },
  { code: 'th', name: 'ไทย (Thai)', flag: '🇹🇭' },
]

// State
const isModalOpen = ref(false)
const selectedLanguage = ref(languages[0])
const isConnected = ref(false)
const isConnecting = ref(false)
const isMicReady = ref(false)
const isListening = ref(false)
const isSpeaking = ref(false)
const error = ref<string | null>(null)

// WebSocket & Audio
const ws = ref<WebSocket | null>(null)
const mediaStream = ref<MediaStream | null>(null)
const audioContext = ref<AudioContext | null>(null)
const audioElement = ref<HTMLAudioElement | null>(null)

// Computed
const statusText = computed(() => {
  if (isListening.value) return 'Listening...'
  if (isSpeaking.value) return 'AI Speaking'
  return 'Ready to chat'
})

const statusClass = computed(() => {
  if (isListening.value) return 'listening'
  if (isSpeaking.value) return 'speaking'
  return 'ready'
})

// Methods
async function openModal() {
  isModalOpen.value = true
  document.body.style.overflow = 'hidden'
  
  // Initialize audio on user gesture
  await initAudioContext()
  await requestMicrophone()
}

function closeModal() {
  isModalOpen.value = false
  document.body.style.overflow = ''
  if (isConnected.value) {
    disconnect()
  }
}

async function requestMicrophone() {
  try {
    if (mediaStream.value) {
      mediaStream.value.getTracks().forEach(track => track.stop())
    }
    mediaStream.value = await navigator.mediaDevices.getUserMedia({ 
      audio: {
        sampleRate: 24000,
        channelCount: 1,
        echoCancellation: true,
        noiseSuppression: true
      } 
    })
    isMicReady.value = true
    console.log('✅ Microphone ready')
  } catch (err) {
    console.error('Microphone error:', err)
    error.value = 'Microphone access is required for voice chat'
    isMicReady.value = false
  }
}

async function initAudioContext() {
  if (!audioElement.value) {
    audioElement.value = new Audio()
    audioElement.value.autoplay = true
    audioElement.value.playsInline = true
    audioElement.value.muted = false
    audioElement.value.volume = 1.0
  }
  
  // Initialize AudioContext for processing
  const AudioContextClass = window.AudioContext || (window as any).webkitAudioContext
  if (AudioContextClass && !audioContext.value) {
    audioContext.value = new AudioContextClass({ sampleRate: 24000 })
    if (audioContext.value.state === 'suspended') {
      await audioContext.value.resume()
    }
    console.log('✅ Audio context initialized:', audioContext.value.state)
  }
}

async function startVoiceChat() {
  console.log('🎯 Starting voice chat')
  await connect()
}

async function connect() {
  if (isConnecting.value || isConnected.value) return
  
  error.value = null
  isConnecting.value = true

  try {
    // Ensure microphone is ready
    if (!mediaStream.value || !isMicReady.value) {
      await requestMicrophone()
      if (!mediaStream.value) {
        throw new Error("Failed to acquire microphone stream")
      }
    }

    // Build system prompt
    const systemPrompt = `You are an AI assistant for "${props.contentItemName}" at ${props.cardData.card_name}.

Content Details:
- Name: ${props.contentItemName}
- Description: ${props.contentItemContent}
${props.aiMetadata ? `- Additional Info: ${props.aiMetadata}` : ''}
${props.cardData.ai_prompt ? `\nSpecial Instructions: ${props.cardData.ai_prompt}` : ''}

Be conversational, friendly, and educational. Answer questions about this content item.`

    // Get ephemeral token and session config
    console.log('🔑 Getting ephemeral token...')
    const { data: sessionData, error: sessionError } = await supabase.functions.invoke(
      'openai-realtime-relay',
      {
        body: {
          language: selectedLanguage.value.code,
          systemPrompt: systemPrompt,
          contentItemName: props.contentItemName
        }
      }
    )

    if (sessionError) throw sessionError
    if (!sessionData?.ephemeral_token) {
      throw new Error('Failed to get ephemeral token')
    }

    console.log('✅ Token received, connecting to OpenAI...')

    // Connect to OpenAI Realtime API via WebSocket
    const model = sessionData.session_config?.model || 'gpt-4o-realtime-preview-2024-12-17'
    const wsUrl = `wss://api.openai.com/v1/realtime?model=${model}`
    
    ws.value = new WebSocket(wsUrl, [
      'realtime',
      `openai-insecure-api-key.${sessionData.ephemeral_token}`,
      'openai-beta.realtime-v1'
    ])

    // Setup WebSocket handlers
    setupWebSocketHandlers(sessionData.session_config)

  } catch (err: any) {
    console.error('❌ Connection error:', err)
    error.value = err.message || 'Failed to connect to AI assistant'
    cleanup()
  } finally {
    isConnecting.value = false
  }
}

function setupWebSocketHandlers(sessionConfig: any) {
  if (!ws.value) return

  ws.value.onopen = () => {
    console.log('🔌 WebSocket connected')
    
    // Send session configuration
    ws.value?.send(JSON.stringify({
      type: 'session.update',
      session: {
        modalities: ['audio', 'text'],
        voice: sessionConfig.voice || 'alloy',
        instructions: sessionConfig.instructions,
        input_audio_format: 'pcm16',
        output_audio_format: 'pcm16',
        input_audio_transcription: {
          model: 'whisper-1'
        },
        turn_detection: {
          type: 'server_vad',
          threshold: 0.5,
          prefix_padding_ms: 300,
          silence_duration_ms: 500
        },
        temperature: sessionConfig.temperature || 0.8,
        max_response_output_tokens: sessionConfig.max_response_output_tokens || 4096
      }
    }))

    isConnected.value = true
    startAudioStreaming()
  }

  ws.value.onmessage = (event) => {
    try {
      const message = JSON.parse(event.data)
      handleRealtimeEvent(message)
    } catch (err) {
      console.error('Error parsing WebSocket message:', err)
    }
  }

  ws.value.onerror = (error) => {
    console.error('❌ WebSocket error:', error)
    error.value = 'Connection error occurred'
  }

  ws.value.onclose = () => {
    console.log('🔌 WebSocket closed')
    isConnected.value = false
    cleanup()
  }
}

function startAudioStreaming() {
  if (!mediaStream.value || !audioContext.value || !ws.value) return

  const source = audioContext.value.createMediaStreamSource(mediaStream.value)
  const processor = audioContext.value.createScriptProcessor(4096, 1, 1)

  processor.onaudioprocess = (e) => {
    if (ws.value?.readyState !== WebSocket.OPEN) return

    const inputData = e.inputBuffer.getChannelData(0)
    const pcm16 = convertFloat32ToPCM16(inputData)
    const base64Audio = arrayBufferToBase64(pcm16)

    // Send audio to OpenAI
    ws.value.send(JSON.stringify({
      type: 'input_audio_buffer.append',
      audio: base64Audio
    }))
  }

  source.connect(processor)
  processor.connect(audioContext.value.destination)
  
  console.log('🎤 Audio streaming started')
}

function handleRealtimeEvent(event: any) {
  console.log(`📩 ${event.type}`)

  switch (event.type) {
    case 'session.created':
    case 'session.updated':
      console.log('✅ Session configured')
      break
      
    case 'input_audio_buffer.speech_started':
      isListening.value = true
      break
      
    case 'input_audio_buffer.speech_stopped':
      isListening.value = false
      break
      
    case 'response.created':
      isSpeaking.value = true
      break
      
    case 'response.audio.delta':
      // Play audio chunk
      if (event.delta) {
        playAudioChunk(event.delta)
      }
      break
      
    case 'response.audio.done':
    case 'response.done':
      isSpeaking.value = false
      break
      
    case 'error':
      console.error('❌ OpenAI error:', event)
      error.value = event.error?.message || 'An error occurred'
      break
  }
}

function playAudioChunk(base64Audio: string) {
  if (!audioContext.value) return

  try {
    const pcm16 = base64ToArrayBuffer(base64Audio)
    const float32 = convertPCM16ToFloat32(new Int16Array(pcm16))
    
    const audioBuffer = audioContext.value.createBuffer(1, float32.length, 24000)
    audioBuffer.getChannelData(0).set(float32)
    
    const source = audioContext.value.createBufferSource()
    source.buffer = audioBuffer
    source.connect(audioContext.value.destination)
    source.start()
  } catch (err) {
    console.error('Error playing audio chunk:', err)
  }
}

function disconnect() {
  console.log('🔌 Disconnecting...')
  if (ws.value) {
    ws.value.close()
    ws.value = null
  }
  cleanup()
}

function cleanup() {
  isConnected.value = false
  isListening.value = false
  isSpeaking.value = false
  
  if (mediaStream.value) {
    mediaStream.value.getTracks().forEach(track => track.stop())
  }
  
  if (audioContext.value && audioContext.value.state !== 'closed') {
    audioContext.value.close()
    audioContext.value = null
  }
}

// Audio conversion utilities
function convertFloat32ToPCM16(float32Array: Float32Array): ArrayBuffer {
  const pcm16 = new Int16Array(float32Array.length)
  for (let i = 0; i < float32Array.length; i++) {
    const s = Math.max(-1, Math.min(1, float32Array[i]))
    pcm16[i] = s < 0 ? s * 0x8000 : s * 0x7FFF
  }
  return pcm16.buffer
}

function convertPCM16ToFloat32(pcm16Array: Int16Array): Float32Array {
  const float32 = new Float32Array(pcm16Array.length)
  for (let i = 0; i < pcm16Array.length; i++) {
    float32[i] = pcm16Array[i] / (pcm16Array[i] < 0 ? 0x8000 : 0x7FFF)
  }
  return float32
}

function arrayBufferToBase64(buffer: ArrayBuffer): string {
  const bytes = new Uint8Array(buffer)
  let binary = ''
  for (let i = 0; i < bytes.byteLength; i++) {
    binary += String.fromCharCode(bytes[i])
  }
  return btoa(binary)
}

function base64ToArrayBuffer(base64: string): ArrayBuffer {
  const binaryString = atob(base64)
  const bytes = new Uint8Array(binaryString.length)
  for (let i = 0; i < binaryString.length; i++) {
    bytes[i] = binaryString.charCodeAt(i)
  }
  return bytes.buffer
}

// Lifecycle
onBeforeUnmount(() => {
  disconnect()
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
  cursor: pointer;
}

.ai-button:active {
  transform: scale(0.98);
}

.status-dot {
  position: absolute;
  top: 0.5rem;
  right: 0.5rem;
  width: 0.5rem;
  height: 0.5rem;
  background: #10b981;
  border-radius: 50%;
  animation: pulse 2s infinite;
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
  max-width: 24rem;
  background: white;
  border-radius: 1rem;
  overflow: hidden;
  animation: slideUp 0.3s ease-out;
}

/* Modal Header */
.modal-header {
  background: linear-gradient(135deg, #3b82f6, #6366f1);
  padding: 1rem;
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.header-info {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  flex: 1;
  min-width: 0;
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
  flex-shrink: 0;
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
  cursor: pointer;
  flex-shrink: 0;
}

.close-button:active {
  background: rgba(255, 255, 255, 0.3);
}

/* Modal Body */
.modal-body {
  padding: 1.5rem;
  max-height: 60vh;
  overflow-y: auto;
}

/* Error Message */
.error-message {
  background: #fee2e2;
  border: 1px solid #fecaca;
  border-radius: 0.5rem;
  padding: 0.75rem;
  display: flex;
  align-items: start;
  gap: 0.5rem;
  color: #991b1b;
  font-size: 0.75rem;
  margin-bottom: 1rem;
  line-height: 1.4;
}

/* Setup Section */
.setup-section {
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
}

.form-group {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.form-group label {
  font-size: 0.875rem;
  font-weight: 500;
  color: #374151;
}

.language-select {
  width: 100%;
  padding: 0.75rem;
  border: 1px solid #d1d5db;
  border-radius: 0.5rem;
  font-size: 0.875rem;
  background: white;
  cursor: pointer;
}

.start-button {
  width: 100%;
  padding: 0.875rem;
  background: linear-gradient(135deg, #3b82f6, #6366f1);
  border: none;
  border-radius: 0.5rem;
  color: white;
  font-size: 0.875rem;
  font-weight: 600;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 0.5rem;
  transition: all 0.2s;
  cursor: pointer;
}

.start-button.disabled {
  background: #e5e7eb;
  color: #9ca3af;
  cursor: not-allowed;
}

/* Connecting Section */
.connecting-section {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 1rem;
  padding: 2rem 0;
}

.spinner {
  width: 3rem;
  height: 3rem;
  border: 3px solid #e5e7eb;
  border-top-color: #3b82f6;
  border-radius: 50%;
  animation: spin 1s linear infinite;
}

/* Connected Section */
.connected-section {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.status-card {
  background: #f3f4f6;
  border-radius: 0.5rem;
  padding: 1rem;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 0.75rem;
}

.status-info {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  flex: 1;
  min-width: 0;
}

.mic-icon {
  width: 2.5rem;
  height: 2.5rem;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.2s;
  flex-shrink: 0;
}

.mic-icon.ready {
  background: #d1fae5;
  color: #10b981;
}

.mic-icon.listening {
  background: #dbeafe;
  color: #3b82f6;
  animation: pulse 1.5s infinite;
}

.mic-icon.speaking {
  background: #e0e7ff;
  color: #6366f1;
  animation: pulse 1s infinite;
}

.status-text {
  font-size: 0.875rem;
  font-weight: 600;
  color: #111827;
  margin: 0;
}

.language-text {
  font-size: 0.75rem;
  color: #6b7280;
  margin: 0;
}

.end-button {
  padding: 0.5rem 1rem;
  background: #fee2e2;
  border: none;
  border-radius: 0.375rem;
  color: #991b1b;
  font-size: 0.875rem;
  font-weight: 500;
  transition: all 0.2s;
  cursor: pointer;
  flex-shrink: 0;
}

.end-button:active {
  background: #fecaca;
}

.instructions {
  background: #dbeafe;
  border: 1px solid #bfdbfe;
  border-radius: 0.5rem;
  padding: 0.75rem;
  display: flex;
  align-items: start;
  gap: 0.5rem;
  color: #1e40af;
  font-size: 0.8rem;
  line-height: 1.5;
}

.instructions i {
  flex-shrink: 0;
  margin-top: 0.1rem;
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

@keyframes spin {
  to {
    transform: rotate(360deg);
  }
}

@keyframes pulse {
  0%, 100% {
    opacity: 1;
  }
  50% {
    opacity: 0.6;
  }
}
</style>

