import { ref, computed, type Ref } from 'vue'

export function useRealtimeConnection() {
  // WebSocket and audio state
  const ws = ref<WebSocket | null>(null)
  const mediaStream = ref<MediaStream | null>(null)
  const audioContext = ref<AudioContext | null>(null)
  const audioProcessor = ref<ScriptProcessorNode | null>(null)
  const audioPlayer = ref<AudioContext | null>(null)
  
  // Connection state
  const isConnected = ref(false)
  const status = ref<'disconnected' | 'connecting' | 'connected' | 'error'>('disconnected')
  const error = ref<string | null>(null)
  
  // Audio state
  const isSpeaking = ref(false)
  const audioQueue: Float32Array[] = []
  const activeSources: AudioBufferSourceNode[] = []
  
  // Voice configuration by language
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
  
  // Get session configuration for OpenAI
  function getSessionConfig(language: string, instructions: string) {
    const session = {
      type: 'realtime', // Add type for session.update
      output_modalities: ['audio'], // audio implies transcript as well
      instructions,
      audio: {
        input: {
          format: {
            type: 'audio/pcm',
            rate: 24000
          },
          turn_detection: {
            type: 'server_vad',
            threshold: 0.5,
            prefix_padding_ms: 300,
            silence_duration_ms: 200
          }
        },
        output: {
          format: {
            type: 'audio/pcm',
            rate: 24000
          },
          voice: voiceMap[language] || 'alloy'
        }
      }
    }

    return {
      model: null, // Will be fetched from server
      session
    }
  }
  
  // Connect to relay server
  async function connect(language: string, instructions: string): Promise<WebSocket> {
    const relayUrl = import.meta.env.VITE_OPENAI_RELAY_URL
    if (!relayUrl) {
      throw new Error('VITE_OPENAI_RELAY_URL not configured')
    }
    
    status.value = 'connecting'
    error.value = null
    
    try {
      // Request microphone access
      mediaStream.value = await navigator.mediaDevices.getUserMedia({
        audio: {
          echoCancellation: true,
          noiseSuppression: true,
          sampleRate: 24000
        }
      })
      
      // Create audio contexts
      audioContext.value = new AudioContext({ sampleRate: 24000 })
      audioPlayer.value = new AudioContext({ sampleRate: 24000 })
      
      // Build session config (exclude model from session.update)
      const { session } = getSessionConfig(language, instructions)
      
      // Connect to relay server without model parameter (server uses .env config)
      ws.value = new WebSocket(`${relayUrl}/realtime`, ['realtime'])
      
      // Set up WebSocket handlers
      ws.value.onopen = () => {
        console.log('✅ Connected to relay server')
        isConnected.value = true
        status.value = 'connected'
      }
      
      ws.value.onmessage = async (event) => {
        try {
          const data = typeof event.data === 'string' 
            ? JSON.parse(event.data)
            : JSON.parse(await event.data.text())
          
          // Send session config after connection (do not include model/type)
          if (data.type === 'session.created') {
            console.log('📤 Sending session configuration')
            ws.value!.send(JSON.stringify({
              type: 'session.update',
              session
            }))
          }
          
          // Start audio after session is configured
          if (data.type === 'session.updated') {
            console.log('🎙️ Starting audio stream')
            startAudioStream()
          }
          
          // Handle audio output
          if (data.type === 'response.output_audio.delta' && data.delta) {
            playAudio(data.delta)
          }
          
          // Handle errors
          if (data.type === 'error') {
            console.error('❌ OpenAI error:', data.error)
            error.value = data.error?.message || 'Unknown error'
          }
        } catch (err) {
          console.error('Message parse error:', err)
        }
      }
      
      ws.value.onerror = (event) => {
        console.error('❌ WebSocket error:', event)
        error.value = 'Connection error'
        status.value = 'error'
      }
      
      ws.value.onclose = () => {
        console.log('🔌 WebSocket closed')
        cleanup()
      }
      
      return ws.value
      
    } catch (err: any) {
      console.error('Connection failed:', err)
      error.value = err.message
      status.value = 'error'
      cleanup()
      throw err
    }
  }
  
  // Start sending audio to OpenAI
  function startAudioStream() {
    if (!mediaStream.value || !audioContext.value || !ws.value) return
    
    const source = audioContext.value.createMediaStreamSource(mediaStream.value)
    audioProcessor.value = audioContext.value.createScriptProcessor(4096, 1, 1)
    
    audioProcessor.value.onaudioprocess = (event) => {
      if (!isConnected.value || ws.value?.readyState !== WebSocket.OPEN) return
      
      const inputData = event.inputBuffer.getChannelData(0)
      
      // Convert Float32 to PCM16
      const pcm16 = new Int16Array(inputData.length)
      for (let i = 0; i < inputData.length; i++) {
        const s = Math.max(-1, Math.min(1, inputData[i]))
        pcm16[i] = s < 0 ? s * 0x8000 : s * 0x7FFF
      }
      
      // Convert to base64 and send
      const base64Audio = btoa(String.fromCharCode(...new Uint8Array(pcm16.buffer)))
      ws.value!.send(JSON.stringify({
        type: 'input_audio_buffer.append',
        audio: base64Audio
      }))
    }
    
    source.connect(audioProcessor.value)
    audioProcessor.value.connect(audioContext.value.destination)
  }
  
  // Play audio from OpenAI
  function playAudio(base64Audio: string) {
    if (!audioPlayer.value) return
    
    try {
      // Decode base64 to PCM16
      const binaryString = atob(base64Audio)
      const bytes = new Uint8Array(binaryString.length)
      for (let i = 0; i < binaryString.length; i++) {
        bytes[i] = binaryString.charCodeAt(i)
      }
      
      // Convert PCM16 to Float32
      const pcm16 = new Int16Array(bytes.buffer)
      const float32 = new Float32Array(pcm16.length)
      for (let i = 0; i < pcm16.length; i++) {
        float32[i] = pcm16[i] / 32768.0
      }
      
      // Queue audio for playback
      audioQueue.push(float32)
      if (!isSpeaking.value) {
        processAudioQueue()
      }
    } catch (err) {
      console.error('Audio playback error:', err)
    }
  }
  
  // Process queued audio chunks
  async function processAudioQueue() {
    if (audioQueue.length === 0 || !audioPlayer.value) {
      isSpeaking.value = false
      return
    }
    
    isSpeaking.value = true
    const audioData = audioQueue.shift()!
    
    const buffer = audioPlayer.value.createBuffer(1, audioData.length, 24000)
    buffer.getChannelData(0).set(audioData)
    
    const source = audioPlayer.value.createBufferSource()
    source.buffer = buffer
    source.connect(audioPlayer.value.destination)
    
    source.onended = () => {
      const index = activeSources.indexOf(source)
      if (index > -1) activeSources.splice(index, 1)
      processAudioQueue()
    }
    
    activeSources.push(source)
    source.start()
  }
  
  // Interrupt current response
  function interrupt() {
    if (ws.value?.readyState === WebSocket.OPEN) {
      ws.value.send(JSON.stringify({ type: 'response.cancel' }))
    }
    
    // Stop all active audio
    activeSources.forEach(source => {
      try { 
        source.stop()
        source.disconnect()
      } catch {}
    })
    activeSources.length = 0
    audioQueue.length = 0
    isSpeaking.value = false
  }
  
  // Disconnect and cleanup
  function disconnect() {
    console.log('🔌 Disconnecting...')
    
    if (ws.value) {
      ws.value.close()
      ws.value = null
    }
    
    cleanup()
  }
  
  // Cleanup resources
  function cleanup() {
    // Stop audio processing
    if (audioProcessor.value) {
      audioProcessor.value.disconnect()
      audioProcessor.value = null
    }
    
    // Close audio contexts
    if (audioContext.value) {
      audioContext.value.close()
      audioContext.value = null
    }
    
    if (audioPlayer.value) {
      audioPlayer.value.close()
      audioPlayer.value = null
    }
    
    // Stop media stream
    if (mediaStream.value) {
      mediaStream.value.getTracks().forEach(track => track.stop())
      mediaStream.value = null
    }
    
    // Clear audio
    activeSources.forEach(source => {
      try { source.stop() } catch {}
    })
    activeSources.length = 0
    audioQueue.length = 0
    
    // Reset state
    isConnected.value = false
    isSpeaking.value = false
    status.value = 'disconnected'
  }
  
  return {
    // State
    isConnected,
    status,
    error,
    isSpeaking,
    
    // Methods
    connect,
    disconnect,
    interrupt
  }
}
