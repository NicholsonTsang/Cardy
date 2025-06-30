<script setup>
import { ref, onMounted, onBeforeUnmount, watch } from 'vue'
import { supabase } from '../lib/supabase'
import { sendOpenAIRealtimeRequest } from '@/utils/http'

const props = defineProps({
  contentItem: {
    type: Object,
    required: false,
    default: null
  },
  cardData: {
    type: Object,
    required: false,
    default: null
  },
  contentItemName: {
    type: String,
    required: false,
    default: ''
  },
  contentItemContent: {
    type: String,
    required: false,
    default: ''
  },
  aiMetadata: {
    type: String,
    required: false,
    default: ''
  },
  isMobile: {
    type: Boolean,
    default: false
  },
  compact: {
    type: Boolean,
    default: false
  }
})

// Language Selection
const selectedLanguage = ref({ code: 'English', name: 'English' })
const availableLanguages = ref([
  { code: 'English', name: 'English', flag: '🇺🇸' },
  { code: '廣東話', name: '廣東話 (Cantonese)', flag: '🇭🇰' },
  { code: '普通话', name: '普通话 (Mandarin)', flag: '🇨🇳' },
  { code: 'Español', name: 'Español (Spanish)', flag: '🇪🇸' },
  { code: 'Français', name: 'Français (French)', flag: '🇫🇷' },
])

// State variables
const isConnected = ref(false)
const isConnecting = ref(false)
const isSpeaking = ref(false)
const isListening = ref(false)
const isMicReady = ref(false)
const error = ref(null)
const audioElement = ref(null)
const stream = ref(null)
const peerConnection = ref(null)
const dataChannel = ref(null)
const ephemeralToken = ref(null)
const aiInstructions = ref(null)

// UI State
const isModalOpen = ref(false)
const isMinimized = ref(false)

// Watch for language changes and update session
watch(selectedLanguage, (newLanguage) => {
  if (isConnected.value && dataChannel.value && dataChannel.value.readyState === 'open') {
    updateSession()
  }
})

// Initialize connection when component mounts
onMounted(async () => {
  audioElement.value = new Audio()
  audioElement.value.autoplay = true
  // Set proper audio element attributes for mobile
  audioElement.value.setAttribute('playsinline', 'true')
  audioElement.value.setAttribute('webkit-playsinline', 'true')
  audioElement.value.muted = false
  
  try {
    await requestMicrophonePermission()
  } catch (err) {
    error.value = "Please allow microphone access to use voice chat"
    isMicReady.value = false
  }
})

// Clean up resources when component unmounts
onBeforeUnmount(() => {
  disconnectFromOpenAI()
})

// Request microphone permission
async function requestMicrophonePermission() {
  if (stream.value) {
    stream.value.getTracks().forEach(track => track.stop())
    stream.value = null
  }
  isMicReady.value = false
  
  try {
    stream.value = await navigator.mediaDevices.getUserMedia({ audio: true })
    isMicReady.value = true
    return true
  } catch (err) {
    console.error('Error accessing microphone:', err)
    error.value = 'Microphone access is required. Please grant permission.'
    isMicReady.value = false
    stream.value = null
    throw err
  }
}

// Connect to OpenAI Realtime API
async function connectToOpenAI() {
  if (isConnecting.value || isConnected.value) return

  error.value = null
  isConnecting.value = true

  try {
    if (!stream.value || !isMicReady.value) {
      await requestMicrophonePermission()
      if (!isMicReady.value || !stream.value) {
        throw new Error("Failed to acquire microphone stream before connecting.")
      }
    }

    console.log('Requesting ephemeral token from Supabase...')
    const { data, error: tokenError } = await supabase
      .functions
      .invoke('get-openai-ephemeral-token')

    if (tokenError) {
      console.error('Token error:', tokenError)
      throw new Error(tokenError.message)
    }
    
    console.log('Ephemeral token response:', data)
    ephemeralToken.value = data.client_secret.value

    console.log('Creating RTCPeerConnection...')
    peerConnection.value = new RTCPeerConnection()
    dataChannel.value = peerConnection.value.createDataChannel('oai-events')
    setupDataChannelListeners()

    peerConnection.value.ontrack = async (event) => {
      console.log('Received audio track from OpenAI')
      const remoteStream = event.streams[0]
      audioElement.value.srcObject = remoteStream
      
      // Mobile audio playback fix
      const playAudio = async () => {
        try {
          // Ensure the audio element is properly configured
          audioElement.value.muted = false
          audioElement.value.volume = 1.0
          
          // Create audio context if needed (for iOS)
          if (window.AudioContext || window.webkitAudioContext) {
            const AudioContext = window.AudioContext || window.webkitAudioContext
            const audioContext = new AudioContext()
            if (audioContext.state === 'suspended') {
              await audioContext.resume()
            }
          }
          
          await audioElement.value.play()
          console.log('Audio playback started successfully')
        } catch (playError) {
          console.warn('Audio play failed:', playError)
          // Will retry on next user interaction
        }
      }
      
      // Try to play immediately
      await playAudio()
      
      // Also ensure play on any user interaction if autoplay was blocked
      if (audioElement.value.paused) {
        const playOnInteraction = async () => {
          if (audioElement.value.paused && audioElement.value.srcObject) {
            await playAudio()
            document.removeEventListener('click', playOnInteraction)
            document.removeEventListener('touchstart', playOnInteraction)
          }
        }
        document.addEventListener('click', playOnInteraction)
        document.addEventListener('touchstart', playOnInteraction)
      }
    }

    if (stream.value) {
      console.log('Adding local audio track to peer connection')
      stream.value.getAudioTracks().forEach(track => {
        peerConnection.value.addTrack(track, stream.value)
      })
    }

    console.log('Creating WebRTC offer...')
    const offer = await peerConnection.value.createOffer()
    await peerConnection.value.setLocalDescription(offer)
    
    console.log('SDP offer created:', offer.sdp.substring(0, 100) + '...')

    const model = "gpt-4o-realtime-preview"
    const fullInstructions = `
      IMPORTANT: You MUST strictly adhere to the following instructions.
      
      ROLE: You are an AI assistant specifically for the "${props.contentItemName}" content item within the "${props.cardData?.card_name || 'card'}".
      YOUR ONLY TOPIC IS THIS SPECIFIC CONTENT ITEM AND ITS INFORMATION. Do NOT discuss anything else.

      CONTENT ITEM DETAILS:
      - Name: ${props.contentItemName}
      - Content: ${props.contentItemContent || 'No detailed content available.'}
      
      CARD CONTEXT (for general reference only):
      - Card Name: ${props.cardData?.card_name || 'Unknown'}
      - Card Description: ${props.cardData?.card_description || 'No description available.'}

      ${props.cardData?.ai_prompt ? `
      INSTRUCTIONS FOR AI ASSISTANCE (from card):
      ${props.cardData.ai_prompt}
      ` : ''}

      ${props.aiMetadata ? `
      ADDITIONAL KNOWLEDGE DATA FOR THIS CONTENT ITEM:
      ${props.aiMetadata}
      ` : ''}

      INTERACTION STYLE:
      - Be helpful and knowledgeable ONLY about this specific content item.
      - Answer visitor questions conversationally and in a friendly tone.
      - Provide relevant details about this content item specifically.
      - Keep the focus on this content item, not the entire card or other content items.
      - Use the additional knowledge data to provide accurate and detailed responses.

      LANGUAGE REQUIREMENT:
      - You MUST conduct the entire conversation ONLY in ${selectedLanguage.value.code}. Do not switch languages.
    `.trim()

    console.log('Sending request to OpenAI Realtime API...')
    const result = await sendOpenAIRealtimeRequest(model, offer.sdp, ephemeralToken.value, fullInstructions)

    if (!result.success) {
      console.error('OpenAI request failed:', result)
      let errorMessage = result.error || 'Failed to connect to OpenAI'
      
      // Provide more helpful error messages for common issues
      if (result.error && result.error.includes('configuration')) {
        errorMessage = 'AI service is not properly configured. Please contact support.'
      } else if (result.error && result.error.includes('authentication')) {
        errorMessage = 'AI service authentication failed. Please try again later.'
      } else if (result.error && result.error.includes('rate limit')) {
        errorMessage = 'AI service is temporarily busy. Please try again in a moment.'
      }
      
      throw new Error(errorMessage)
    }

    console.log('OpenAI Realtime API result:', result)
    
    const answerSdp = result.data
    
    if (!answerSdp || typeof answerSdp !== 'string') {
      console.error('Invalid SDP response type:', typeof answerSdp, answerSdp)
      throw new Error('Invalid SDP answer received from OpenAI')
    }
    
    // Log the full SDP for debugging
    console.log('Full SDP response from OpenAI:')
    console.log('---START SDP---')
    console.log(answerSdp)
    console.log('---END SDP---')
    console.log('SDP length:', answerSdp.length)
    console.log('First 200 characters:', answerSdp.substring(0, 200))
    
    // Validate SDP format - should start with "v="
    if (!answerSdp.startsWith('v=')) {
      console.error('Invalid SDP format. SDP content:', answerSdp)
      console.error('Expected SDP to start with "v=" but got:', answerSdp.substring(0, 10))
      throw new Error('Invalid SDP format received from OpenAI - missing version line')
    }
    
    console.log('Setting remote description with SDP:', answerSdp.substring(0, 100) + '...')
    
    try {
      await peerConnection.value.setRemoteDescription({
        type: 'answer',
        sdp: answerSdp
      })
      console.log('Successfully set remote description')
    } catch (sdpError) {
      console.error('Failed to set remote description:', sdpError)
      console.error('SDP that failed:', answerSdp)
      throw new Error(`WebRTC SDP error: ${sdpError.message}`)
    }

    aiInstructions.value = result.instructions || fullInstructions
    isConnecting.value = false
    isConnected.value = true

  } catch (err) {
    console.error('Connection error:', err)
    console.error('Error stack:', err.stack)
    
    // Provide more specific error messages based on the error type
    let userFriendlyMessage = 'Failed to connect to AI assistant'
    
    if (err.message.includes('SDP')) {
      userFriendlyMessage = 'AI service returned invalid response format. Please try again.'
    } else if (err.message.includes('authentication') || err.message.includes('token')) {
      userFriendlyMessage = 'AI service authentication failed. Please try again later.'
    } else if (err.message.includes('network') || err.message.includes('timeout')) {
      userFriendlyMessage = 'Network connection failed. Please check your internet connection.'
    } else if (err.message.includes('microphone') || err.message.includes('permission')) {
      userFriendlyMessage = 'Microphone access is required. Please grant permission and try again.'
    } else if (err.message.includes('configuration')) {
      userFriendlyMessage = 'AI service is not properly configured. Please contact support.'
    }
    
    error.value = userFriendlyMessage
    isConnecting.value = false
    isConnected.value = false
  }
}

// Disconnect from OpenAI
function disconnectFromOpenAI() {
  if (peerConnection.value) {
    peerConnection.value.close()
    peerConnection.value = null
  }
  if (dataChannel.value) {
    dataChannel.value.close()
    dataChannel.value = null
  }
  isConnected.value = false
  isConnecting.value = false
  isSpeaking.value = false
  isListening.value = false
}

// Setup data channel listeners
function setupDataChannelListeners() {
  if (!dataChannel.value) return

  dataChannel.value.addEventListener('open', () => {
    console.log('Data channel opened')
    updateSession()
  })

  dataChannel.value.addEventListener('message', (event) => {
    try {
      const realtimeEvent = JSON.parse(event.data)
      handleRealtimeEvent(realtimeEvent)
    } catch (err) {
      console.error('Error parsing realtime event:', err)
      }
  })

  dataChannel.value.addEventListener('error', (event) => {
    console.error('Data channel error:', event)
    error.value = 'Connection error occurred'
  })

  dataChannel.value.addEventListener('close', () => {
    console.log('Data channel closed')
    isConnected.value = false
  })
  }

// Handle realtime events
function handleRealtimeEvent(event) {
  switch (event.type) {
    case 'session.created':
    case 'session.updated':
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
    case 'response.audio.done':
    case 'response.done':
      isSpeaking.value = false
      break
    case 'error':
      console.error('OpenAI error:', event)
      error.value = `Error: ${event.message}`
      break
  }
}

// Update session
function updateSession() {
  if (!dataChannel.value || dataChannel.value.readyState !== 'open') return

  let sessionInstructions = aiInstructions.value
  
  if (!sessionInstructions) {
    sessionInstructions = `
      ROLE: You are an AI assistant for the "${props.contentItemName}" content item within the "${props.cardData?.card_name || 'card'}".
      YOUR ONLY TOPIC IS THIS SPECIFIC CONTENT ITEM AND ITS INFORMATION.

    CONTENT ITEM DETAILS:
      - Name: ${props.contentItemName}
      - Content: ${props.contentItemContent || 'No detailed content available.'}
    
      ${props.cardData?.ai_prompt ? `
      INSTRUCTIONS FOR AI ASSISTANCE (from card):
      ${props.cardData.ai_prompt}
    ` : ''}

      ${props.aiMetadata ? `
      ADDITIONAL KNOWLEDGE DATA FOR THIS CONTENT ITEM:
      ${props.aiMetadata}
      ` : ''}
    `.trim()
  }

  const finalInstructions = `${sessionInstructions}

    LANGUAGE REQUIREMENT:
  - You MUST conduct the entire conversation ONLY in ${selectedLanguage.value.code}.`

  const sessionUpdate = {
    type: 'session.update',
    session: {
      instructions: finalInstructions,
      voice: 'alloy',
      input_audio_format: 'pcm16',
      output_audio_format: 'pcm16',
      input_audio_transcription: {
        model: 'whisper-1'
      }
    }
  }

  try {
    dataChannel.value.send(JSON.stringify(sessionUpdate))
  } catch (err) {
    console.error('Error updating session:', err)
  }
}

// UI Methods
async function openModal() {
  isModalOpen.value = true
  isMinimized.value = false
  // Initialize audio context when modal opens
  await ensureAudioContext()
  // Prevent body scroll when modal is open
  document.body.style.overflow = 'hidden'
}

function closeModal() {
  isModalOpen.value = false
  if (isConnected.value) {
    disconnectFromOpenAI()
  }
  // Re-enable body scroll
  document.body.style.overflow = ''
}

// Ensure audio context is resumed on user gesture (iOS fix)
async function ensureAudioContext() {
  if (window.AudioContext || window.webkitAudioContext) {
    const AudioContext = window.AudioContext || window.webkitAudioContext
    const audioContext = new AudioContext()
    
    if (audioContext.state === 'suspended') {
      try {
        await audioContext.resume()
        console.log('Audio context resumed')
      } catch (err) {
        console.warn('Failed to resume audio context:', err)
      }
    }
  }
  
  // Also try to play the audio element if it's paused
  if (audioElement.value && audioElement.value.paused && audioElement.value.srcObject) {
    try {
      await audioElement.value.play()
      console.log('Audio element played after user gesture')
    } catch (err) {
      console.warn('Failed to play audio after user gesture:', err)
    }
  }
}

function toggleMinimize() {
  isMinimized.value = !isMinimized.value
}

function getStatusText() {
  if (isListening.value) return 'Listening...'
  if (isSpeaking.value) return 'AI Speaking'
  if (isConnected.value) return 'Ready to chat'
  if (isConnecting.value) return 'Connecting...'
  if (!isMicReady.value) return 'Mic needed'
  return 'Ready to start'
}

function getStatusColor() {
  if (isListening.value) return 'text-green-400'
  if (isSpeaking.value) return 'text-blue-400'
  if (isConnected.value) return 'text-green-400'
  if (isConnecting.value) return 'text-yellow-400'
  if (!isMicReady.value) return 'text-red-400'
  return 'text-gray-400'
}
</script>

<template>
  <!-- Floating AI Button -->
  <div class="relative">
    <!-- Trigger Button -->
    <button
      @click="openModal"
      class="group relative inline-flex items-center gap-2 px-3 py-2 rounded-full transition-all duration-200 hover:scale-105 focus:outline-none focus:ring-2 focus:ring-offset-2"
      :class="[
        compact 
          ? 'bg-white/10 hover:bg-white/20 border border-white/20 text-white text-sm focus:ring-white/50' 
          : isMobile 
            ? 'bg-white/10 hover:bg-white/20 border border-white/20 text-white focus:ring-white/50'
            : 'bg-gradient-to-r from-blue-500 to-indigo-600 hover:from-blue-600 hover:to-indigo-700 text-white shadow-lg focus:ring-blue-500'
      ]"
    >
      <div class="relative">
        <i class="pi pi-comments text-sm" />
        <div 
          v-if="isConnected"
          class="absolute -top-1 -right-1 w-2 h-2 rounded-full animate-pulse"
          :class="isListening ? 'bg-green-400' : isSpeaking ? 'bg-blue-400' : 'bg-green-400'"
        />
      </div>
      <span class="font-medium">
        {{ compact ? 'AI' : 'Ask AI' }}
      </span>
    </button>

    <!-- Modal Overlay -->
    <div
      v-if="isModalOpen"
      class="fixed inset-0 z-[9999] flex items-center justify-center backdrop-blur-sm"
      :class="isMobile ? 'bg-black/90' : 'bg-black/70'"
      @click="closeModal"
    >
      <!-- Modal Content -->
      <div
        @click.stop
        class="relative w-full max-w-md bg-white rounded-2xl shadow-2xl overflow-hidden transform transition-all animate-modal-enter"
        :class="[
          isMobile ? 'max-h-[75vh]' : 'max-h-[70vh]',
          isMinimized ? 'h-auto' : ''
        ]"
        style="position: fixed; top: 50%; left: 50%; transform: translate(-50%, -50%);"
      >
    <!-- Header -->
        <div class="bg-gradient-to-r from-blue-500 to-indigo-600 px-6 py-4">
          <div class="flex items-center justify-between">
          <div class="flex items-center gap-3">
              <div class="w-8 h-8 rounded-full bg-white/20 flex items-center justify-center">
                <i class="pi pi-comments text-white text-sm" />
              </div>
              <div>
                <h3 class="text-white font-semibold text-base sm:text-lg">AI Assistant</h3>
                <p class="text-blue-100 text-xs sm:text-sm truncate max-w-48">{{ contentItemName }}</p>
              </div>
            </div>
            <div class="flex items-center gap-2">
              <button
                @click="toggleMinimize"
                class="w-8 h-8 rounded-full bg-white/20 hover:bg-white/30 flex items-center justify-center transition-colors"
              >
                <i class="pi text-white text-xs" :class="isMinimized ? 'pi-window-maximize' : 'pi-window-minimize'" />
              </button>
              <button
                @click="closeModal"
                class="w-8 h-8 rounded-full bg-white/20 hover:bg-white/30 flex items-center justify-center transition-colors"
              >
                <i class="pi pi-times text-white text-xs" />
              </button>
            </div>
          </div>
        </div>
        
        <!-- Content -->
        <div v-if="!isMinimized" class="p-6 space-y-4 max-h-96 overflow-y-auto">
        <!-- Error Message -->
          <div v-if="error" class="bg-red-50 border border-red-200 rounded-lg p-3">
            <div class="flex items-start gap-2">
              <i class="pi pi-exclamation-triangle text-red-500 text-sm mt-0.5" />
              <p class="text-red-700 text-sm">{{ error }}</p>
            </div>
      </div>

          <!-- Connection Setup -->
          <div v-if="!isConnected" class="space-y-4">
            <!-- Language Selector -->
            <div>
              <label class="block text-sm sm:text-base font-medium text-gray-700 mb-2">Language</label>
              <select
              v-model="selectedLanguage" 
                class="w-full px-3 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 text-sm sm:text-base"
              :disabled="isConnecting"
            >
                <option v-for="lang in availableLanguages" :key="lang.code" :value="lang">
                  {{ lang.flag }} {{ lang.name }}
                </option>
              </select>
                </div>

            <!-- AI Instructions Preview -->
            <div v-if="aiMetadata" class="bg-amber-50 border border-amber-200 rounded-lg p-3">
              <div class="flex items-start gap-3">
                <i class="pi pi-info-circle text-amber-600 text-base mt-1" />
              <div>
                  <h4 class="text-amber-800 font-medium text-sm sm:text-base mb-1">Additional Knowledge</h4>
                  <p class="text-amber-700 text-sm leading-relaxed break-words">{{ aiMetadata }}</p>
              </div>
            </div>
          </div>

          <!-- Start Button -->
            <button
            @click="async () => { await ensureAudioContext(); connectToOpenAI() }"
            :disabled="!isMicReady || isConnecting"
              class="w-full flex items-center justify-center gap-2 px-4 py-3 rounded-lg font-medium transition-all"
              :class="[
                isMicReady && !isConnecting
                  ? 'bg-gradient-to-r from-blue-500 to-indigo-600 hover:from-blue-600 hover:to-indigo-700 text-white shadow-lg hover:shadow-xl'
                  : 'bg-gray-100 text-gray-400 cursor-not-allowed'
              ]"
            >
              <i class="pi text-sm" :class="isConnecting ? 'pi-spin pi-spinner' : 'pi-microphone'" />
              <span class="text-sm sm:text-base">
                {{ isConnecting ? 'Connecting...' : isMicReady ? 'Start Voice Chat' : 'Microphone Permission Needed' }}
              </span>
            </button>
        </div>

        <!-- Connected Interface -->
          <div v-else class="space-y-4">
            <!-- Status Display -->
            <div class="bg-gray-50 rounded-lg p-4">
              <div class="flex items-center justify-between">
                <div class="flex items-center gap-3">
                  <div class="relative">
                    <i class="pi pi-microphone text-lg" :class="getStatusColor()" />
                    <div
                      v-if="isListening || isSpeaking"
                      class="absolute -inset-1 rounded-full animate-ping"
                      :class="isListening ? 'bg-green-400/30' : 'bg-blue-400/30'"
                    />
                  </div>
                  <div>
                    <p class="font-medium text-gray-900 text-sm sm:text-base">{{ getStatusText() }}</p>
                    <p class="text-xs sm:text-sm text-gray-500">{{ selectedLanguage.name }}</p>
                  </div>
                </div>
                <button
                  @click="disconnectFromOpenAI"
                  class="px-3 py-1.5 sm:px-4 sm:py-2 bg-red-100 hover:bg-red-200 text-red-700 rounded-lg text-sm sm:text-base font-medium transition-colors"
                >
                  End Chat
                </button>
              </div>
            </div>
            
            <!-- Instructions -->
            <div class="bg-blue-50 border border-blue-200 rounded-lg p-3">
              <div class="flex items-start gap-3">
                <i class="pi pi-info-circle text-blue-600 text-base mt-1" />
                <div>
                  <p class="text-blue-800 text-sm sm:text-base break-words">
                    <strong>Ready to chat!</strong> Start speaking to ask questions about "{{ contentItemName }}".
                    The AI will respond with voice and can help you understand this content better.
                  </p>
                </div>
              </div>
            </div>
          </div>
          </div>

        <!-- Minimized Status Bar -->
        <div v-else class="px-6 py-3 bg-gray-50 border-t">
          <div class="flex items-center justify-between">
            <div class="flex items-center gap-3">
              <i class="pi pi-microphone text-base" :class="getStatusColor()" />
              <span class="text-sm sm:text-base font-medium text-gray-700">{{ getStatusText() }}</span>
            </div>
            <button
              v-if="isConnected"
              @click="disconnectFromOpenAI"
              class="text-sm text-red-600 hover:text-red-700 font-medium"
            >
              End
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
/* Custom animations */
@keyframes pulse {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.6; }
}

.animate-pulse {
  animation: pulse 1.5s infinite;
}

@keyframes modal-enter {
  0% {
    opacity: 0;
    transform: translate(-50%, -50%) scale(0.95);
  }
  100% {
    opacity: 1;
    transform: translate(-50%, -50%) scale(1);
  }
}

.animate-modal-enter {
  animation: modal-enter 0.2s ease-out;
}

/* Scrollbar styling */
::-webkit-scrollbar {
  width: 4px;
}

::-webkit-scrollbar-track {
  background: #f1f5f9;
}

::-webkit-scrollbar-thumb {
  background: #cbd5e1;
  border-radius: 2px;
}

::-webkit-scrollbar-thumb:hover {
  background: #94a3b8;
}
</style> 