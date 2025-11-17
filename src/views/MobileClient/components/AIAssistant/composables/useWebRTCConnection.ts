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
  const audioElement = ref<HTMLAudioElement | null>(null)
  const audioAnalyser = ref<{ context: AudioContext; analyser: AnalyserNode } | null>(null)
  
  // Transcript callbacks
  let onUserTranscriptCallback: ((text: string) => void) | null = null
  let onAssistantTranscriptCallback: ((text: string) => void) | null = null
  
  // Voice configuration by language (Realtime API)
  // Supported voices: 'alloy', 'ash', 'ballad', 'coral', 'echo', 'sage', 'shimmer', 'verse', 'marin', 'cedar'
  // For Chinese, voice is determined by voice preference (mandarin/cantonese), not text script
  const voiceMap: Record<string, string> = {
    'en': 'alloy',                // English - Neutral, versatile
    'zh-Hans-mandarin': 'coral',  // Simplified + Mandarin
    'zh-Hans-cantonese': 'coral', // Simplified + Cantonese (same voice, different language instructions)
    'zh-Hant-mandarin': 'coral',  // Traditional + Mandarin
    'zh-Hant-cantonese': 'coral', // Traditional + Cantonese
    'ja': 'shimmer',              // Japanese - Female, soft
    'ko': 'coral',                // Korean - Female, conversational
    'th': 'shimmer',              // Thai - Female, calming
    'es': 'echo',                 // Spanish - Male, clear
    'fr': 'ballad',               // French - Female, warm
    'ru': 'sage',                 // Russian - Male, calm
    'ar': 'sage'                  // Arabic - Male, respectful
  }
  
  // Get ephemeral token from Backend API
  async function getEphemeralToken(language: string) {
    try {
      const { data: { session } } = await supabase.auth.getSession()
      const token = session?.access_token || import.meta.env.VITE_SUPABASE_ANON_KEY

      const response = await fetch(`${import.meta.env.VITE_BACKEND_URL}/api/ai/realtime-token`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          sessionConfig: {
            voice: voiceMap[language] || 'alloy'
          }
        })
      })
      
      if (!response.ok) {
        const errorData = await response.json()
        throw new Error(errorData.error || 'Failed to get ephemeral token')
      }

      const data = await response.json()
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
      // IMPORTANT: OpenAI Realtime API with WebRTC requires a relay server for browser connections
      // The direct HTTP POST approach doesn't work due to CORS restrictions
      const backendUrl = import.meta.env.VITE_BACKEND_URL
      
      if (!backendUrl) {
        const errorMessage = [
          'OpenAI Realtime API requires backend server for browser connections.',
          'Direct connections are blocked by CORS policy.',
          '',
          'To fix this:',
          '1. Ensure backend server is running',
          '2. Add VITE_BACKEND_URL to your .env file',
          '',
          'For local development, you can use Chat Mode (text + TTS) instead,',
          'which works without a relay server.'
        ].join('\n')
        
        console.error('❌ ' + errorMessage)
        throw new Error('Backend server required. Please configure VITE_BACKEND_URL in your .env file.')
      }
      
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
        
        // Language name mapping for explicit instructions
        const languageNames: Record<string, string> = {
          'en': 'English',
          'zh-Hans-mandarin': 'Mandarin Chinese (普通話) - Simplified Script',
          'zh-Hans-cantonese': 'Cantonese (廣東話) - Simplified Script',
          'zh-Hant-mandarin': 'Mandarin Chinese (普通話) - Traditional Script',
          'zh-Hant-cantonese': 'Cantonese (廣東話) - Traditional Script',
          'zh-Hans': 'Chinese (Simplified)',  // Fallback
          'zh-Hant': 'Chinese (Traditional)', // Fallback
          'ja': 'Japanese (日本語)',
          'ko': 'Korean (한국어)',
          'th': 'Thai (ภาษาไทย)',
          'es': 'Spanish (Español)',
          'fr': 'French (Français)',
          'ru': 'Russian (Русский)',
          'ar': 'Arabic (العربية)'
        }
        
        // Prepare session configuration with language enforcement
        const sessionConfig = {
          type: 'session.update',
          session: {
            modalities: ['text', 'audio'],
            instructions: `LANGUAGE REQUIREMENT: You MUST respond ONLY in ${languageNames[language] || 'English'}. Never use any other language.\n\n${instructions}`,
            voice: voiceMap[language] || 'alloy',
            input_audio_format: 'pcm16',
            output_audio_format: 'pcm16',
            input_audio_transcription: { 
              model: 'whisper-1' 
            },
            turn_detection: { 
              type: 'server_vad',
              threshold: parseFloat(import.meta.env.VITE_REALTIME_VAD_THRESHOLD) || 0.65,           // Higher = less sensitive to noise (range: 0.0-1.0, default: 0.65)
              prefix_padding_ms: parseInt(import.meta.env.VITE_REALTIME_VAD_PREFIX_PADDING) || 300, // Audio before speech detection (default: 300ms)
              silence_duration_ms: parseInt(import.meta.env.VITE_REALTIME_VAD_SILENCE_DURATION) || 800 // Silence required before ending turn (default: 800ms)
            },
            temperature: 0.8,
            max_response_output_tokens: 4096
          }
        }
        
        // DEBUG: Print full session configuration
        console.log('🔧 ========== REALTIME API SESSION CONFIGURATION ==========')
        console.log('🌍 Selected Language:', language)
        console.log('🎤 Voice:', voiceMap[language] || 'alloy')
        console.log('📝 Full Instructions:')
        console.log(instructions)
        console.log('📦 Complete Session Config:', JSON.stringify(sessionConfig, null, 2))
        console.log('🔧 =======================================================')
        
        // Send session configuration with context
        sendMessage(sessionConfig)
        
        // Trigger AI's first greeting after session is configured
        setTimeout(() => {
          const greetingConfig = {
            type: 'response.create',
            response: {
              modalities: ['text', 'audio'],
              instructions: `CRITICAL: Respond ONLY in ${languageNames[language] || 'English'}. Greet the user warmly and briefly ask how you can help them understand the content better. Keep it natural and conversational. DO NOT use any other language.`
            }
          }
          
          console.log('👋 Triggering AI first greeting:', greetingConfig)
          sendMessage(greetingConfig)
        }, 500)
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
        
        // CRITICAL FIX: Prevent multiple audio elements from being created
        // On mobile, ontrack can fire multiple times due to ICE reconnections
        // This causes the AI to restart speaking from the beginning
        if (audioElement.value && audioElement.value.srcObject === event.streams[0]) {
          console.log('⚠️ Audio track already connected, skipping duplicate ontrack event')
          return
        }
        
        // Clean up existing audio element and analyser before creating new ones
        if (audioElement.value) {
          console.log('🧹 Cleaning up existing audio element before creating new one')
          audioElement.value.pause()
          audioElement.value.srcObject = null
        }
        
        if (audioAnalyser.value) {
          console.log('🧹 Cleaning up existing audio analyser')
          try {
            audioAnalyser.value.context.close()
          } catch (err) {
            console.warn('Error closing audio context:', err)
          }
          audioAnalyser.value = null
        }
        
        // Create new audio element
        console.log('✅ Creating new audio element for stream')
        audioElement.value = new Audio()
        audioElement.value.srcObject = event.streams[0]
        audioElement.value.autoplay = true
        
        // Track speaking state
        const audioContext = new AudioContext()
        const source = audioContext.createMediaStreamSource(event.streams[0])
        const analyser = audioContext.createAnalyser()
        source.connect(analyser)
        
        // Store analyser for cleanup
        audioAnalyser.value = { context: audioContext, analyser }
        
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
      
      // Get model from environment (must match what was used for ephemeral token)
      const model = import.meta.env.VITE_OPENAI_REALTIME_MODEL || 'gpt-realtime-mini-2025-10-06'
      console.log('🎯 Using Realtime model:', model)
      
      // Use backend server to proxy the WebRTC connection
      console.log('🌐 Connecting through backend server:', backendUrl)
      const response = await fetch(`${backendUrl}/offer`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          sdp: offer.sdp,
          model,
          token: ephemeralToken
        })
      })
      
      if (!response.ok) {
        const errorText = await response.text()
        throw new Error(`Relay server connection failed: ${response.statusText}. ${errorText}`)
      }
      
      // Get SDP answer from relay
      const responseData = await response.json()
      const answerSdp = responseData.sdp
      
      // Set remote description
      await pc.value.setRemoteDescription({
        type: 'answer',
        sdp: answerSdp
      })
      
      console.log('✅ WebRTC connection established through relay')
      
    } catch (err: any) {
      console.error('Connection failed:', err)
      error.value = err.message
      status.value = 'error'
      cleanup()
      throw err
    }
  }
  
  // Transcript state for accumulation
  let currentAssistantTranscript = ''
  
  // Handle incoming data channel messages
  function handleDataChannelMessage(data: string) {
    try {
      const message = JSON.parse(data)
      
      console.log('📨 Received message type:', message.type)
      
      // Handle different message types
      switch (message.type) {
        case 'session.created':
        case 'session.updated':
          console.log('📋 Session event:', message.type)
          break
          
        case 'conversation.item.input_audio_transcription.completed':
          // User's speech transcript
          if (message.transcript && onUserTranscriptCallback) {
            console.log('🎤 User said:', message.transcript)
            onUserTranscriptCallback(message.transcript)
          }
          break
          
        case 'response.audio_transcript.delta':
          // AI response transcript (streaming)
          if (message.delta) {
            console.log('📝 AI transcript delta:', message.delta)
            currentAssistantTranscript += message.delta
          }
          break
          
        case 'response.audio_transcript.done':
          // AI response complete
          if (currentAssistantTranscript && onAssistantTranscriptCallback) {
            console.log('✅ AI transcript complete:', currentAssistantTranscript)
            onAssistantTranscriptCallback(currentAssistantTranscript)
            currentAssistantTranscript = ''
          }
          break
          
        case 'response.done':
          // Response fully completed - fallback if no audio_transcript.done
          if (currentAssistantTranscript && onAssistantTranscriptCallback) {
            console.log('✅ AI response done:', currentAssistantTranscript)
            onAssistantTranscriptCallback(currentAssistantTranscript)
            currentAssistantTranscript = ''
          }
          break
          
        case 'error':
          console.error('❌ OpenAI error:', message.error)
          error.value = message.error?.message || 'Unknown error'
          break
          
        default:
          console.log('📨 Unhandled message:', message.type)
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
    // Clean up audio element
    if (audioElement.value) {
      console.log('🧹 Cleaning up audio element')
      audioElement.value.pause()
      audioElement.value.srcObject = null
      audioElement.value = null
    }
    
    // Clean up audio analyser
    if (audioAnalyser.value) {
      console.log('🧹 Cleaning up audio analyser')
      try {
        audioAnalyser.value.context.close()
      } catch (err) {
        console.warn('Error closing audio context:', err)
      }
      audioAnalyser.value = null
    }
    
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
    currentAssistantTranscript = ''
  }
  
  // Set transcript callbacks
  function onUserTranscript(callback: (text: string) => void) {
    onUserTranscriptCallback = callback
  }
  
  function onAssistantTranscript(callback: (text: string) => void) {
    onAssistantTranscriptCallback = callback
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
    sendText,
    onUserTranscript,
    onAssistantTranscript
  }
}
