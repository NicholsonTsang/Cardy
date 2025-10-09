import { ref, computed } from 'vue'
import { supabase } from '@/lib/supabase'

export interface RealtimeConnectionState {
  isConnected: boolean
  isSpeaking: boolean
  status: 'disconnected' | 'connecting' | 'connected' | 'error'
  error: string | null
}

export interface SessionConfig {
  type: 'realtime' | 'transcription'
  model: string
  output_modalities?: string[]
  audio?: {
    input?: {
      format?: {
        type: string
        rate?: number
      }
      turn_detection?: {
        type: string
        threshold?: number
        prefix_padding_ms?: number
        silence_duration_ms?: number
      }
    }
    output?: {
      format?: {
        type: string
      }
      voice?: string
    }
  }
  instructions?: string
  temperature?: number
  max_response_output_tokens?: number
}

export function useRealtimeConnection() {
  // State
  const realtimeWebSocket = ref<WebSocket | null>(null)
  const realtimeMediaStream = ref<MediaStream | null>(null)
  const realtimeAudioContext = ref<AudioContext | null>(null)
  const realtimeAnalyser = ref<AnalyserNode | null>(null)
  const realtimeWaveformData = ref<Uint8Array | null>(null)
  const realtimeWaveformAnimationFrame = ref<number | null>(null)
  const realtimeAudioPlayer = ref<AudioContext | null>(null)
  const realtimeActiveSources = ref<AudioBufferSourceNode[]>([])
  const realtimeAudioSource = ref<MediaStreamAudioSourceNode | null>(null)
  const realtimeAudioProcessor = ref<ScriptProcessorNode | null>(null)
  // Queue realtime audio chunks to avoid overlapping playback
  const realtimeAudioQueue = ref<Float32Array[]>([])
  const isProcessingAudioQueue = ref(false)
  // Interrupt control
  const lastInterruptAt = ref(0)
  const SPEECH_INTERRUPT_COOLDOWN_MS = 1200
  const SPEECH_INTERRUPT_THRESHOLD = 0.03 // Adjust if needed
  
  const isRealtimeConnected = ref(false)
  const isRealtimeSpeaking = ref(false)
  const realtimeStatus = ref<'disconnected' | 'connecting' | 'connected' | 'error'>('disconnected')
  const realtimeError = ref<string | null>(null)

  // Computed
  const connectionState = computed<RealtimeConnectionState>(() => ({
    isConnected: isRealtimeConnected.value,
    isSpeaking: isRealtimeSpeaking.value,
    status: realtimeStatus.value,
    error: realtimeError.value
  }))

  const statusText = computed(() => {
    switch (realtimeStatus.value) {
      case 'connecting':
        return 'Connecting...'
      case 'connected':
        return isRealtimeSpeaking.value ? 'AI Speaking' : 'Ready to chat'
      case 'error':
        return 'Connection error'
      default:
        return 'Disconnected'
    }
  })

  // Methods
  async function getEphemeralToken(language: string, systemPrompt: string, contentItemName: string) {
    // OPEN PROXY MODE: No token needed - relay server uses its own API key
    // Return complete dummy data structure to maintain API compatibility
    
    const voiceMap: Record<string, string> = {
      'en': 'alloy',
      'zh-HK': 'nova',
      'zh-CN': 'nova',
      'ja': 'shimmer',
      'ko': 'shimmer',
      'es': 'echo',
      'fr': 'fable',
      'ru': 'onyx',
      'ar': 'onyx',
      'th': 'shimmer'
    }
    
    const tokenData = {
      success: true,
      token: 'relay-proxy-mode',
      model: 'gpt-realtime-mini-2025-10-06',
      sessionConfig: {
        type: 'realtime',  // Required for GA API
        model: 'gpt-realtime-mini-2025-10-06',
        output_modalities: ['audio', 'text'],  // GA API: "output_modalities" not "modalities"
        audio: {  // GA API: nested audio configuration
          input: {
            format: {
              type: 'audio/pcm',
              rate: 24000
            },
            turn_detection: {
              type: 'semantic_vad',
              threshold: 0.5,
              prefix_padding_ms: 300,
              silence_duration_ms: 500
            }
          },
          output: {
            format: {
              type: 'audio/pcm'
            },
            voice: voiceMap[language] || 'alloy'  // GA API: voice in audio.output
          }
        },
        instructions: `${systemPrompt}\n\nYou are speaking with someone interested in: ${contentItemName}. Provide engaging, natural conversation.`,
        temperature: 0.8,
        max_response_output_tokens: 4096
      }
    }
    
    console.log('🔑 Generated token data (open proxy mode):', {
      hasModel: !!tokenData.model,
      hasSessionConfig: !!tokenData.sessionConfig,
      model: tokenData.model
    })
    
    return tokenData
  }

  async function requestMicrophone() {
    realtimeMediaStream.value = await navigator.mediaDevices.getUserMedia({
      audio: {
        echoCancellation: true,
        noiseSuppression: true,
        autoGainControl: true,
        sampleRate: 24000
      }
    })
    return realtimeMediaStream.value
  }

  function createAudioContexts() {
    realtimeAudioContext.value = new AudioContext({ sampleRate: 24000 })
    const source = realtimeAudioContext.value.createMediaStreamSource(realtimeMediaStream.value!)
    realtimeAnalyser.value = realtimeAudioContext.value.createAnalyser()
    realtimeAnalyser.value.fftSize = 64
    source.connect(realtimeAnalyser.value)
    realtimeWaveformData.value = new Uint8Array(realtimeAnalyser.value.frequencyBinCount)
    
    realtimeAudioPlayer.value = new AudioContext({ sampleRate: 24000 })
  }

  function createWebSocket(model: string, _token: string) {
    // OPEN PROXY MODE: Connect to relay server without token authentication
    const relayUrl = import.meta.env.VITE_OPENAI_RELAY_URL
    
    if (!relayUrl) {
      throw new Error('VITE_OPENAI_RELAY_URL is not configured. Relay server is required in open proxy mode.')
    }
    
    // Connect to relay server (token is handled server-side)
    const wsUrl = `${relayUrl}/realtime?model=${encodeURIComponent(model)}`
    console.log('🔄 Connecting via relay server (open proxy mode):', wsUrl)
    
    // Simple WebSocket connection - no authentication protocols needed
    realtimeWebSocket.value = new WebSocket(wsUrl, ['realtime'])
    return realtimeWebSocket.value
  }

  function playRealtimeAudio(base64Audio: string) {
    if (!realtimeAudioPlayer.value) {
      console.warn('⚠️ playRealtimeAudio called but audio player not initialized')
      return
    }

    try {
      // Decode base64 to PCM16
      const binaryString = atob(base64Audio)
      const bytes = new Uint8Array(binaryString.length)
      for (let i = 0; i < binaryString.length; i++) {
        bytes[i] = binaryString.charCodeAt(i)
      }

      // Convert PCM16 to Float32 and enqueue
      const pcm16 = new Int16Array(bytes.buffer)
      const float32 = new Float32Array(pcm16.length)
      for (let i = 0; i < pcm16.length; i++) {
        float32[i] = pcm16[i] / 32768.0
      }

      realtimeAudioQueue.value.push(float32)
      // Start processing the queue if not already doing so
      processAudioQueue()
    } catch (err) {
      console.error('Failed to enqueue audio:', err)
    }
  }

  function processAudioQueue() {
    if (!realtimeAudioPlayer.value) return
    if (isProcessingAudioQueue.value) return
    if (realtimeAudioQueue.value.length === 0) return

    isProcessingAudioQueue.value = true
    const float32 = realtimeAudioQueue.value.shift()!

    // Create audio buffer
    const audioBuffer = realtimeAudioPlayer.value.createBuffer(1, float32.length, 24000)
    audioBuffer.getChannelData(0).set(float32)

    // Play audio
    const source = realtimeAudioPlayer.value.createBufferSource()
    source.buffer = audioBuffer
    source.connect(realtimeAudioPlayer.value.destination)

    // Track this source and clean up when done
    realtimeActiveSources.value.push(source)
    console.log(`🔊 Playing audio chunk (queue: ${realtimeAudioQueue.value.length}, active: ${realtimeActiveSources.value.length})`)

    source.onended = () => {
      const index = realtimeActiveSources.value.indexOf(source)
      if (index > -1) {
        realtimeActiveSources.value.splice(index, 1)
      }
      console.log(`🔇 Audio chunk finished (queue: ${realtimeAudioQueue.value.length}, active: ${realtimeActiveSources.value.length})`)
      if (realtimeActiveSources.value.length === 0) {
        isRealtimeSpeaking.value = false
      }
      isProcessingAudioQueue.value = false
      // Continue with next chunk, if any
      processAudioQueue()
    }

    source.start()
    isRealtimeSpeaking.value = true
  }

  function cancelCurrentResponse() {
    if (realtimeWebSocket.value && realtimeWebSocket.value.readyState === WebSocket.OPEN) {
      try {
        realtimeWebSocket.value.send(JSON.stringify({ type: 'response.cancel' }))
        console.log('🛑 Sent response.cancel to interrupt AI speech')
      } catch (err) {
        console.warn('Failed to send response.cancel:', err)
      }
    }
    // Stop all active audio sources immediately
    if (realtimeActiveSources.value.length > 0) {
      realtimeActiveSources.value.forEach(source => {
        try { source.stop(); source.disconnect() } catch {}
      })
      realtimeActiveSources.value = []
    }
    // Clear queued audio
    realtimeAudioQueue.value = []
    isProcessingAudioQueue.value = false
    isRealtimeSpeaking.value = false
  }

  function startSendingAudio() {
    if (!realtimeMediaStream.value || !realtimeAudioContext.value || !realtimeWebSocket.value) return
    
    // CRITICAL: Clean up any existing audio processing chain first
    if (realtimeAudioProcessor.value) {
      console.log('🧹 Cleaning up existing audio processor before creating new one')
      try {
        realtimeAudioProcessor.value.disconnect()
        realtimeAudioProcessor.value.onaudioprocess = null
      } catch (err) {
        console.warn('Error disconnecting old processor:', err)
      }
      realtimeAudioProcessor.value = null
    }
    
    if (realtimeAudioSource.value) {
      try {
        realtimeAudioSource.value.disconnect()
      } catch (err) {
        console.warn('Error disconnecting old source:', err)
      }
      realtimeAudioSource.value = null
    }
    
    console.log('🎙️ Starting audio transmission...')
    
    // Create MediaStreamSource and ScriptProcessor for audio capture
    realtimeAudioSource.value = realtimeAudioContext.value.createMediaStreamSource(realtimeMediaStream.value)
    realtimeAudioProcessor.value = realtimeAudioContext.value.createScriptProcessor(4096, 1, 1)
    
    realtimeAudioProcessor.value.onaudioprocess = (event) => {
      if (!isRealtimeConnected.value || !realtimeWebSocket.value || realtimeWebSocket.value.readyState !== WebSocket.OPEN) {
        return
      }
      
      // Get audio data
      const inputData = event.inputBuffer.getChannelData(0)

      // Detect speech energy (simple RMS)
      let sumSquares = 0
      for (let i = 0; i < inputData.length; i++) {
        const s = inputData[i]
        sumSquares += s * s
      }
      const rms = Math.sqrt(sumSquares / inputData.length)

      // If AI is speaking and user starts speaking above threshold, interrupt
      const now = Date.now()
      if (
        isRealtimeSpeaking.value &&
        rms > SPEECH_INTERRUPT_THRESHOLD &&
        (now - lastInterruptAt.value) > SPEECH_INTERRUPT_COOLDOWN_MS
      ) {
        console.log(`🛑 Barge-in detected (rms=${rms.toFixed(4)}). Interrupting current response.`)
        cancelCurrentResponse()
        lastInterruptAt.value = now
      }
      
      // Convert to PCM16
      const pcm16 = new Int16Array(inputData.length)
      for (let i = 0; i < inputData.length; i++) {
        const s = Math.max(-1, Math.min(1, inputData[i]))
        pcm16[i] = s < 0 ? s * 0x8000 : s * 0x7FFF
      }
      
      // Convert to base64
      const base64Audio = btoa(String.fromCharCode.apply(null, Array.from(new Uint8Array(pcm16.buffer))))
      
      // Send to OpenAI
      realtimeWebSocket.value!.send(JSON.stringify({
        type: 'input_audio_buffer.append',
        audio: base64Audio
      }))
    }
    
    realtimeAudioSource.value.connect(realtimeAudioProcessor.value)
    realtimeAudioProcessor.value.connect(realtimeAudioContext.value.destination)
    
    console.log('✅ Audio processing chain established')
  }

  function disconnect() {
    console.log('🔌 Disconnecting realtime...')
    
    // CRITICAL: Stop audio processing chain FIRST
    if (realtimeAudioProcessor.value) {
      console.log('🛑 Stopping audio processor...')
      try {
        realtimeAudioProcessor.value.disconnect()
        realtimeAudioProcessor.value.onaudioprocess = null
      } catch (err) {
        console.warn('Error stopping processor:', err)
      }
      realtimeAudioProcessor.value = null
    }
    
    if (realtimeAudioSource.value) {
      console.log('🛑 Disconnecting audio source...')
      try {
        realtimeAudioSource.value.disconnect()
      } catch (err) {
        console.warn('Error disconnecting source:', err)
      }
      realtimeAudioSource.value = null
    }
    
    // Stop all active audio sources
    if (realtimeActiveSources.value.length > 0) {
      console.log(`🔇 Stopping ${realtimeActiveSources.value.length} active audio sources...`)
      realtimeActiveSources.value.forEach(source => {
        try {
          source.stop()
          source.disconnect()
        } catch (err) {
          // Already stopped
        }
      })
      realtimeActiveSources.value = []
    }
    
    // Stop waveform animation
    if (realtimeWaveformAnimationFrame.value) {
      cancelAnimationFrame(realtimeWaveformAnimationFrame.value)
      realtimeWaveformAnimationFrame.value = null
    }
    
    // Close WebSocket
    if (realtimeWebSocket.value) {
      realtimeWebSocket.value.close()
      realtimeWebSocket.value = null
    }
    
    // Stop media stream
    if (realtimeMediaStream.value) {
      realtimeMediaStream.value.getTracks().forEach(track => track.stop())
      realtimeMediaStream.value = null
    }
    
    // Close audio contexts
    if (realtimeAudioContext.value) {
      realtimeAudioContext.value.close()
      realtimeAudioContext.value = null
    }
    
    if (realtimeAudioPlayer.value) {
      realtimeAudioPlayer.value.close()
      realtimeAudioPlayer.value = null
    }
    
    // Reset state
    isRealtimeConnected.value = false
    isRealtimeSpeaking.value = false
    realtimeStatus.value = 'disconnected'
    realtimeAnalyser.value = null
    realtimeWaveformData.value = null
    // Clear any queued audio
    realtimeAudioQueue.value = []
    isProcessingAudioQueue.value = false
  }

  return {
    // State
    realtimeWebSocket,
    realtimeMediaStream,
    realtimeAudioContext,
    realtimeAnalyser,
    realtimeWaveformData,
    realtimeWaveformAnimationFrame,
    realtimeAudioPlayer,
    realtimeActiveSources,
    isRealtimeConnected,
    isRealtimeSpeaking,
    realtimeStatus,
    realtimeError,
    
    // Computed
    connectionState,
    statusText,
    
    // Methods
    getEphemeralToken,
    requestMicrophone,
    createAudioContexts,
    createWebSocket,
    playRealtimeAudio,
    startSendingAudio,
    disconnect
  }
}

