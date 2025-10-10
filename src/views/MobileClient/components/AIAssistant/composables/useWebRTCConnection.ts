import { ref, computed } from 'vue'
import { supabase } from '@/lib/supabase'

export function useWebRTCConnection() {
  // Connection state
  const pc = ref<RTCPeerConnection | null>(null)
  const dc = ref<RTCDataChannel | null>(null)
  const isConnected = ref(false)
  const status = ref<'disconnected' | 'connecting' | 'connected' | 'error'>('disconnected')
  const error = ref<string | null>(null)
  
  // Audio state
  const isSpeaking = ref(false)
  const mediaStream = ref<MediaStream | null>(null)
  
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
  
  // Get ephemeral token from Edge Function
  async function getEphemeralToken(language: string) {
    try {
      const { data, error: fnError } = await supabase.functions.invoke('openai-realtime-token', {
        body: {
          sessionConfig: {
            voice: voiceMap[language] || 'alloy'
          }
        }
      })
      
      if (fnError) throw fnError
      if (!data.success) throw new Error(data.error)
      
      return data.client_secret
    } catch (err: any) {
      console.error('Failed to get ephemeral token:', err)
      throw err
    }
  }
  
  // Initialize WebRTC connection
  async function connect(language: string, instructions: string): Promise<void> {
    status.value = 'connecting'
    error.value = null
    
    try {
      // Get ephemeral token
      const ephemeralToken = await getEphemeralToken(language)
      console.log('🔑 Got ephemeral token')
      
      // Request microphone access
      mediaStream.value = await navigator.mediaDevices.getUserMedia({
        audio: {
          echoCancellation: true,
          noiseSuppression: true,
          autoGainControl: true
        }
      })
      
      // Create peer connection
      pc.value = new RTCPeerConnection({
        iceServers: [
          { urls: 'stun:stun.l.google.com:19302' }
        ]
      })
      
      // Add audio track
      const audioTrack = mediaStream.value.getAudioTracks()[0]
      pc.value.addTrack(audioTrack, mediaStream.value)
      
      // Create data channel for text/events
      dc.value = pc.value.createDataChannel('oai-events', {
        ordered: true
      })
      
      // Set up data channel handlers
      dc.value.onopen = () => {
        console.log('✅ Data channel opened')
        isConnected.value = true
        status.value = 'connected'
        
        // Send session configuration
        sendMessage({
          type: 'session.update',
          session: {
            type: 'realtime',
            instructions,
            input_audio_transcription: { model: 'whisper-1' },
            turn_detection: { type: 'server_vad' },
            voice: voiceMap[language] || 'alloy'
          }
        })
      }
      
      dc.value.onmessage = (event) => {
        handleDataChannelMessage(event.data)
      }
      
      dc.value.onclose = () => {
        console.log('🔌 Data channel closed')
        cleanup()
      }
      
      dc.value.onerror = (event) => {
        console.error('❌ Data channel error:', event)
        error.value = 'Connection error'
        status.value = 'error'
      }
      
      // Handle incoming audio
      pc.value.ontrack = (event) => {
        console.log('🎵 Received audio track')
        const audio = new Audio()
        audio.srcObject = event.streams[0]
        audio.autoplay = true
        
        // Track speaking state
        const audioContext = new AudioContext()
        const source = audioContext.createMediaStreamSource(event.streams[0])
        const analyser = audioContext.createAnalyser()
        source.connect(analyser)
        
        const dataArray = new Uint8Array(analyser.frequencyBinCount)
        const checkAudio = () => {
          analyser.getByteFrequencyData(dataArray)
          const average = dataArray.reduce((a, b) => a + b) / dataArray.length
          isSpeaking.value = average > 30
          if (isConnected.value) {
            requestAnimationFrame(checkAudio)
          }
        }
        checkAudio()
      }
      
      // Create offer
      const offer = await pc.value.createOffer()
      await pc.value.setLocalDescription(offer)
      
      // Send offer to OpenAI
      const response = await fetch('https://api.openai.com/v1/realtime', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${ephemeralToken}`,
          'Content-Type': 'application/sdp'
        },
        body: offer.sdp
      })
      
      if (!response.ok) {
        throw new Error(`OpenAI connection failed: ${response.statusText}`)
      }
      
      // Set remote description
      const answer = await response.text()
      await pc.value.setRemoteDescription({
        type: 'answer',
        sdp: answer
      })
      
      console.log('✅ WebRTC connection established')
      
    } catch (err: any) {
      console.error('Connection failed:', err)
      error.value = err.message
      status.value = 'error'
      cleanup()
      throw err
    }
  }
  
  // Handle incoming data channel messages
  function handleDataChannelMessage(data: string) {
    try {
      const message = JSON.parse(data)
      
      // Handle different message types
      switch (message.type) {
        case 'session.created':
        case 'session.updated':
          console.log('📋 Session event:', message.type)
          break
          
        case 'response.audio_transcript.delta':
          console.log('📝 Transcript:', message.delta)
          // Emit transcript event for UI
          break
          
        case 'error':
          console.error('❌ OpenAI error:', message.error)
          error.value = message.error?.message || 'Unknown error'
          break
          
        default:
          console.log('📨 Message:', message.type)
      }
    } catch (err) {
      console.error('Failed to parse message:', err)
    }
  }
  
  // Send message through data channel
  function sendMessage(message: any) {
    if (dc.value?.readyState === 'open') {
      dc.value.send(JSON.stringify(message))
    } else {
      console.warn('Data channel not ready')
    }
  }
  
  // Send text input
  function sendText(text: string) {
    sendMessage({
      type: 'conversation.item.create',
      item: {
        type: 'message',
        role: 'user',
        content: [
          {
            type: 'input_text',
            text
          }
        ]
      }
    })
    
    // Trigger response
    sendMessage({
      type: 'response.create'
    })
  }
  
  // Interrupt current response
  function interrupt() {
    sendMessage({
      type: 'response.cancel'
    })
  }
  
  // Disconnect and cleanup
  function disconnect() {
    console.log('🔌 Disconnecting...')
    cleanup()
  }
  
  // Cleanup resources
  function cleanup() {
    // Close data channel
    if (dc.value) {
      dc.value.close()
      dc.value = null
    }
    
    // Close peer connection
    if (pc.value) {
      pc.value.close()
      pc.value = null
    }
    
    // Stop media stream
    if (mediaStream.value) {
      mediaStream.value.getTracks().forEach(track => track.stop())
      mediaStream.value = null
    }
    
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
    interrupt,
    sendText
  }
}
