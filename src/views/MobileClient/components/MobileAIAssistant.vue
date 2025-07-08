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
import { sendOpenAIRealtimeRequest } from '@/utils/http'

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
  { code: 'English', name: 'English', flag: '🇺🇸' },
  { code: '廣東話', name: '廣東話 (Cantonese)', flag: '🇭🇰' },
  { code: '普通话', name: '普通话 (Mandarin)', flag: '🇨🇳' },
  { code: 'Español', name: 'Español (Spanish)', flag: '🇪🇸' },
  { code: 'Français', name: 'Français (French)', flag: '🇫🇷' },
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
const storedInstructions = ref<string>('')

// WebRTC
const audioElement = ref<HTMLAudioElement | null>(null)
const stream = ref<MediaStream | null>(null)
const peerConnection = ref<RTCPeerConnection | null>(null)
const dataChannel = ref<RTCDataChannel | null>(null)

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
  
  // User gesture available - perfect time to initialize audio
  await initAudioContext()
  await requestMicrophone()
  
  // Try to unlock audio on user gesture (important for iOS)
  if (audioElement.value) {
    try {
      const playPromise = audioElement.value.play()
      if (playPromise) {
        await playPromise.catch(() => {
          // Silent fail - this is expected when no src is set
        })
        audioElement.value.pause()
      }
    } catch (err) {
      // Expected when no audio source
    }
  }
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
    if (stream.value) {
      stream.value.getTracks().forEach(track => track.stop())
    }
    stream.value = await navigator.mediaDevices.getUserMedia({ audio: true })
    isMicReady.value = true
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
    ;(audioElement.value as any).playsInline = true
    audioElement.value.muted = false
    audioElement.value.volume = 1.0
    audioElement.value.setAttribute('playsinline', 'true')
    audioElement.value.setAttribute('webkit-playsinline', 'true')
    
    // Add event listeners for debugging
    audioElement.value.addEventListener('loadstart', () => console.log('Audio: loadstart'))
    audioElement.value.addEventListener('canplay', () => console.log('Audio: canplay'))
    audioElement.value.addEventListener('play', () => console.log('Audio: play'))
    audioElement.value.addEventListener('pause', () => console.log('Audio: pause'))
    audioElement.value.addEventListener('error', (e) => console.error('Audio error:', e))
  }
  
  // Initialize audio context for mobile
  if (window.AudioContext || (window as any).webkitAudioContext) {
    const AudioContext = window.AudioContext || (window as any).webkitAudioContext
    const context = new AudioContext()
    if (context.state === 'suspended') {
      await context.resume()
      console.log('Audio context resumed during init')
    }
    console.log('Audio context state:', context.state)
  }
}

async function startVoiceChat() {
  // Critical: This function is called from user interaction - perfect for audio unlock
  console.log('🎯 Starting voice chat from user interaction')
  
  // Unlock audio playback (non-blocking for desktop browsers)
  if (audioElement.value) {
    console.log('🔍 Attempting audio unlock (non-blocking)...')
    try {
      // Try to play with timeout to avoid hanging
      const playPromise = audioElement.value.play()
      if (playPromise) {
        // Don't wait for play promise - it might hang on empty audio element
        playPromise
          .then(() => {
            console.log('✅ Audio unlocked successfully')
            audioElement.value?.pause()
          })
          .catch((err) => {
            console.log('ℹ️ Audio unlock failed (expected):', err.message)
          })
      }
    } catch (err) {
      console.log('ℹ️ Audio unlock attempt failed (expected):', err)
    }
  }
  
  // Continue with connection immediately
  console.log('▶️ Proceeding to connect...')
  await connect()
}

async function connect() {
  console.log('🔍 Checking isConnecting:', isConnecting.value)
  if (isConnecting.value || isConnected.value) {
    console.log('⚠️ Already connecting or connected, skipping...')
    return
  }
  
  console.log('🚀 Starting connect() function')
  error.value = null
  isConnecting.value = true

  try {
    console.log('🎤 Checking microphone stream...')
    if (!stream.value || !isMicReady.value) {
      console.log('📋 Requesting microphone permission...')
      await requestMicrophone()
      if (!stream.value) {
        throw new Error("Failed to acquire microphone stream")
      }
    }
    console.log('✅ Microphone stream ready')

    // Prepare comprehensive instructions
    const instructions = `You are an AI assistant for the content item "${props.contentItemName}" within the digital card "${props.cardData.card_name}".

Your role: Provide helpful information about this specific content item to museum/exhibition visitors.

Content Details:
- Item Name: ${props.contentItemName}
- Item Description: ${props.contentItemContent}

${props.aiMetadata ? `Additional Knowledge: ${props.aiMetadata}` : ''}

${props.cardData.ai_prompt ? `Special Instructions: ${props.cardData.ai_prompt}` : ''}

Communication Guidelines:
- Speak ONLY in ${selectedLanguage.value.code}
- Be conversational and friendly
- Focus specifically on this content item
- Provide engaging and educational responses
- Keep responses concise but informative

Begin the conversation by greeting the visitor and asking how you can help them learn about "${props.contentItemName}".`

    // Store instructions for session updates
    storedInstructions.value = instructions

    console.log('🔑 Getting ephemeral token from Supabase...')
    console.log('📋 Instructions prepared:', instructions.substring(0, 200) + '...')
    const { data: tokenData, error: tokenError } = await supabase
      .functions
      .invoke('get-openai-ephemeral-token', {
        body: {
          instructions: instructions,
          language: selectedLanguage.value.code
        }
      })
    
    console.log('📡 Supabase function response:', { data: tokenData, error: tokenError })
    
    if (tokenError) {
      console.error('❌ Supabase function error:', tokenError)
      throw new Error(`Token error: ${tokenError.message || tokenError}`)
    }
    
    if (!tokenData || !tokenData.client_secret || !tokenData.client_secret.value) {
      console.error('❌ Invalid token response:', tokenData)
      throw new Error('Invalid ephemeral token response from server')
    }
    
    const ephemeralToken = tokenData.client_secret.value
    console.log('✅ Ephemeral token acquired, length:', ephemeralToken.length)

    // Create peer connection with proper config
    peerConnection.value = new RTCPeerConnection({
      iceServers: [{ urls: 'stun:stun.l.google.com:19302' }]
    })
    
    // Create data channel BEFORE adding tracks
    dataChannel.value = peerConnection.value.createDataChannel('oai-events')
    setupDataChannel()
    
    // Handle incoming audio track from OpenAI
    peerConnection.value.ontrack = async (event) => {
      console.log('Received audio track from OpenAI:', event)
      const remoteStream = event.streams[0]
      
      if (audioElement.value && remoteStream) {
        console.log('Setting audio source to remote stream')
        audioElement.value.srcObject = remoteStream
        
        // Critical: Wait for audio to be ready before playing
        audioElement.value.onloadedmetadata = async () => {
          try {
            console.log('Audio metadata loaded, attempting playback')
            await audioElement.value!.play()
            console.log('✅ Audio playback started successfully')
          } catch (playError) {
            console.warn('⚠️ Audio autoplay blocked:', playError)
            
            // Fallback: play on next user interaction
            const enableAudioOnInteraction = async () => {
              try {
                if (audioElement.value && audioElement.value.paused) {
                  await audioElement.value.play()
                  console.log('✅ Audio enabled after user interaction')
                }
              } catch (err) {
                console.warn('Audio play on interaction failed:', err)
              }
              // Clean up listeners
              document.removeEventListener('touchstart', enableAudioOnInteraction)
              document.removeEventListener('click', enableAudioOnInteraction)
            }
            
            document.addEventListener('touchstart', enableAudioOnInteraction, { once: true })
            document.addEventListener('click', enableAudioOnInteraction, { once: true })
          }
        }
      }
    }

    // Add local audio track
    console.log('Adding local audio track...')
    const audioTracks = stream.value.getAudioTracks()
    if (audioTracks.length > 0) {
      peerConnection.value.addTrack(audioTracks[0], stream.value)
      console.log('Local audio track added')
    } else {
      throw new Error('No audio tracks available')
    }

    // Create and set local SDP offer
    console.log('Creating WebRTC offer...')
    const offer = await peerConnection.value.createOffer({
      offerToReceiveAudio: true,
      offerToReceiveVideo: false
    })
    await peerConnection.value.setLocalDescription(offer)
    console.log('Local description set')

    // Send SDP offer to OpenAI via Supabase proxy (instructions already sent with token)
    console.log('Sending SDP offer to OpenAI...')
    const result = await sendOpenAIRealtimeRequest(
      'gpt-4o-realtime-preview-2025-06-03',
      offer.sdp!,
      ephemeralToken,
      instructions
    )

    if (!result.success) {
      console.error('OpenAI request failed:', result)
      throw new Error(result.error || 'Connection to OpenAI failed')
    }

    console.log('Received SDP answer from OpenAI')
    
    // Set remote description with OpenAI's answer
    const remoteDescription = {
      type: 'answer' as RTCSdpType,
      sdp: result.data
    }
    
    await peerConnection.value.setRemoteDescription(remoteDescription)
    console.log('✅ WebRTC connection established with OpenAI')

    // Monitor connection state
    peerConnection.value.onconnectionstatechange = () => {
      console.log('🔗 Connection state:', peerConnection.value?.connectionState)
      if (peerConnection.value?.connectionState === 'failed') {
        console.error('❌ WebRTC connection failed')
        error.value = 'Connection to AI failed. Please try again.'
        isConnected.value = false
      }
    }

    peerConnection.value.oniceconnectionstatechange = () => {
      console.log('🧊 ICE connection state:', peerConnection.value?.iceConnectionState)
    }

    isConnected.value = true
    
    // Send initial session configuration after connection
    setTimeout(() => {
      if (dataChannel.value?.readyState === 'open') {
        console.log('📡 Sending initial session update...')
        updateSession()
      } else {
        console.warn('⚠️ Data channel not ready for session update')
      }
    }, 1000)

  } catch (err: any) {
    console.error('❌ DETAILED CONNECTION ERROR:')
    console.error('Error object:', err)
    console.error('Error message:', err.message)
    console.error('Error stack:', err.stack)
    console.error('Error type:', typeof err)
    console.error('Error name:', err.name)
    
    error.value = err.message || 'Failed to connect to AI assistant'
    
    // Cleanup on error
    console.log('🧹 Cleaning up after error...')
    if (peerConnection.value) {
      peerConnection.value.close()
      peerConnection.value = null
      console.log('🗑️ Closed peer connection')
    }
    if (dataChannel.value) {
      dataChannel.value.close()
      dataChannel.value = null
      console.log('🗑️ Closed data channel')
    }
  } finally {
    console.log('🏁 Connect function finished, setting isConnecting to false')
    isConnecting.value = false
  }
}

function disconnect() {
  if (peerConnection.value) {
    peerConnection.value.close()
    peerConnection.value = null
  }
  if (dataChannel.value) {
    dataChannel.value.close()
    dataChannel.value = null
  }
  isConnected.value = false
  isListening.value = false
  isSpeaking.value = false
  storedInstructions.value = ''
}

function setupDataChannel() {
  if (!dataChannel.value) return

  dataChannel.value.addEventListener('open', () => {
    console.log('✅ Data channel opened - ready for communication')
    
    // Send initial greeting to start the conversation
    setTimeout(() => {
      if (dataChannel.value?.readyState === 'open') {
        console.log('🎬 Triggering initial AI greeting...')
        
        // Create an initial response to get AI to speak first
        const initialResponse = {
          type: 'response.create',
          response: {
            modalities: ['audio', 'text']
          }
        }
        
        dataChannel.value.send(JSON.stringify(initialResponse))
        console.log('📤 Sent initial response request')
      }
    }, 500)
  })

  dataChannel.value.addEventListener('message', (event) => {
    try {
      const realtimeEvent = JSON.parse(event.data)
      console.log('📩 Received event:', realtimeEvent.type)
      handleRealtimeEvent(realtimeEvent)
    } catch (err) {
      console.error('Error parsing WebRTC event:', err)
    }
  })

  dataChannel.value.addEventListener('error', (event) => {
    console.error('❌ Data channel error:', event)
  })

  dataChannel.value.addEventListener('close', () => {
    console.log('Data channel closed')
    isConnected.value = false
  })
}

function handleRealtimeEvent(event: any) {
  console.log(`📩 Event received: ${event.type}`, event)
  
  switch (event.type) {
    case 'session.created':
      console.log('✅ Session created successfully:', event.session)
      break
    case 'session.updated':
      console.log('✅ Session updated successfully:', event.session)
      break
    case 'input_audio_buffer.speech_started':
      console.log('🎤 User started speaking')
      isListening.value = true
      break
    case 'input_audio_buffer.speech_stopped':
      console.log('🤫 User stopped speaking')
      isListening.value = false
      break
    case 'response.created':
      console.log('🤖 AI response created:', event.response)
      isSpeaking.value = true
      break
    case 'response.audio.delta':
      console.log('🔊 Receiving audio chunk, length:', event.delta?.length || 0)
      // Audio is handled via WebRTC stream, this is just for logging
      break
    case 'response.audio_transcript.delta':
      console.log('📝 AI transcript delta:', event.delta)
      break
    case 'response.audio.done':
      console.log('🎵 AI audio complete')
      break
    case 'response.audio_transcript.done':
      console.log('📄 AI transcript complete:', event.transcript)
      break
    case 'response.done':
      console.log('✅ AI response complete:', event.response)
      
      // Check if response failed
      if (event.response.status === 'failed') {
        console.error('❌ AI response FAILED!')
        console.error('Status details:', event.response.status_details)
        console.error('Full response:', event.response)
        error.value = `AI response failed: ${event.response.status_details?.error?.message || 'Unknown error'}`
      }
      
      isSpeaking.value = false
      break
    case 'conversation.item.created':
      console.log('💬 Conversation item created:', event.item)
      break
    case 'error':
      console.error('❌ OpenAI error:', event)
      error.value = event.error?.message || event.message || 'OpenAI error occurred'
      break
    case 'rate_limits.updated':
      console.log('📊 Rate limits updated:', event.rate_limits)
      break
    default:
      console.log(`📝 Unhandled event: ${event.type}`, event)
  }
}

function updateSession() {
  if (!dataChannel.value || dataChannel.value.readyState !== 'open') {
    console.warn('Cannot update session - data channel not ready')
    return
  }

  const sessionUpdate = {
    type: 'session.update',
    session: {
      modalities: ['audio', 'text'],
      voice: 'alloy',
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
      instructions: storedInstructions.value || `You are an AI assistant. Respond ONLY in ${selectedLanguage.value.code}.`
    }
  }

  console.log('Sending session update with preserved instructions')
  console.log('Instructions length:', storedInstructions.value.length)
  dataChannel.value.send(JSON.stringify(sessionUpdate))
}

async function testAudio() {
  console.log('🔧 Testing audio playback...')
  
  if (!audioElement.value) {
    console.error('❌ No audio element available')
    return
  }
  
  console.log('📊 Audio element state:', {
    paused: audioElement.value.paused,
    muted: audioElement.value.muted,
    volume: audioElement.value.volume,
    srcObject: !!audioElement.value.srcObject,
    readyState: audioElement.value.readyState,
    currentTime: audioElement.value.currentTime
  })
  
  if (audioElement.value.srcObject) {
    try {
      // Ensure audio context is active
      if (window.AudioContext || (window as any).webkitAudioContext) {
        const AudioContext = window.AudioContext || (window as any).webkitAudioContext
        const context = new AudioContext()
        if (context.state === 'suspended') {
          await context.resume()
          console.log('🔓 Audio context resumed for test')
        }
      }
      
      audioElement.value.muted = false
      audioElement.value.volume = 1.0
      await audioElement.value.play()
      console.log('✅ Audio test: playback successful!')
      
      // Test for 2 seconds then pause
      setTimeout(() => {
        if (audioElement.value && !audioElement.value.paused) {
          audioElement.value.pause()
          console.log('⏸️ Audio test complete')
        }
      }, 2000)
      
    } catch (err) {
      console.error('❌ Audio test failed:', err)
      error.value = 'Audio playback test failed. Check browser permissions.'
    }
  } else {
    console.warn('⚠️ No audio source available for testing - connect to AI first')
    error.value = 'No audio stream available. Please connect to AI first.'
  }
}


// Cleanup
onBeforeUnmount(() => {
  console.log('🧹 Cleaning up AI assistant component')
  
  if (isConnected.value) {
    disconnect()
  }
  
  if (stream.value) {
    stream.value.getTracks().forEach(track => {
      track.stop()
      console.log('🛑 Stopped audio track')
    })
    stream.value = null
  }
  
  if (audioElement.value) {
    audioElement.value.srcObject = null
    audioElement.value = null
  }
  
  // Restore body overflow
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
  max-width: 12rem;
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
  font-size: 0.625rem;
  margin-bottom: 1rem;
  line-height: 1.3;
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
}

.status-info {
  display: flex;
  align-items: center;
  gap: 0.75rem;
}

.mic-icon {
  width: 2.5rem;
  height: 2.5rem;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.2s;
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
  font-size: 0.875rem;
  line-height: 1.4;
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