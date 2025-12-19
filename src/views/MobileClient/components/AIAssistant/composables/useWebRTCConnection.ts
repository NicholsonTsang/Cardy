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
  // customWelcome: Optional custom welcome message from card settings (ai_welcome_general/ai_welcome_item)
  async function connect(language: string, instructions: string, customWelcome?: string): Promise<void> {
    // Prevent duplicate connections
    if (isConnected.value || status.value === 'connecting') {
      console.warn('⚠️ Connection already active or in progress, ignoring duplicate connect request')
      return
    }
    
    // Clean up any existing connection first
    if (pc.value || dc.value || mediaStream.value) {
      cleanup()
    }
    
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
        
        // Map language codes to Whisper language codes (ISO-639-1)
        // Whisper expects 2-letter codes for accurate transcription
        const whisperLanguageMap: Record<string, string> = {
          'en': 'en',
          'zh-Hans-mandarin': 'zh',  // Chinese (Mandarin or Cantonese, any script)
          'zh-Hans-cantonese': 'zh',
          'zh-Hant-mandarin': 'zh',
          'zh-Hant-cantonese': 'zh',
          'zh-Hans': 'zh',
          'zh-Hant': 'zh',
          'ja': 'ja',
          'ko': 'ko',
          'th': 'th',
          'es': 'es',
          'fr': 'fr',
          'ru': 'ru',
          'ar': 'ar'
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
              model: 'whisper-1',
              language: whisperLanguageMap[language] || 'en'  // Tell Whisper which language to expect
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
        
        // Send session configuration with context
        sendMessage(sessionConfig)
        
        // Trigger AI's proactive greeting after session is configured
        // Custom welcome provides context/hints for what to suggest; AI generates natural greeting
        setTimeout(() => {
          let greetingInstructions: string
          
          if (customWelcome) {
            // Custom welcome provides guidance - AI generates natural greeting informed by it
            greetingInstructions = `CRITICAL: Respond ONLY in ${languageNames[language] || 'English'}. DO NOT use any other language.

PROACTIVE GREETING INSTRUCTIONS:
The experience creator has provided this welcome message as guidance for what to mention:
"${customWelcome}"

Use this as REFERENCE to understand:
- The tone and personality they want
- What specific topics or features to highlight
- What questions or options to suggest to users

NOW generate your own natural, spoken greeting that:
1. Warmly welcomes the user in a friendly tone
2. Briefly introduces yourself based on the context
3. Suggests 2-3 SPECIFIC things they can ask about (inspired by the welcome message above)
4. Ends with an inviting question

Keep it concise (2-3 sentences), natural for voice, and make sure users clearly understand what they can ask you about!`
          } else {
            // No custom welcome - generate proactive greeting from knowledge base
            greetingInstructions = `CRITICAL: Respond ONLY in ${languageNames[language] || 'English'}. DO NOT use any other language.

PROACTIVE GREETING INSTRUCTIONS:
1. Warmly greet the user in a friendly, enthusiastic tone
2. Briefly introduce yourself as their personal guide
3. IMPORTANT: Proactively suggest 2-3 SPECIFIC things they can ask you about, based on your knowledge. For example:
   - If you know about an artist: "You can ask me about the artist's life, their techniques, or what inspired this work"
   - If you know about a restaurant: "I can tell you about our signature dishes, chef recommendations, or dietary accommodations"
   - If you know about an exhibit: "Feel free to ask about the history, the artifacts, or interesting stories behind what you're seeing"
   - If you know about a location: "I can share opening hours, nearby attractions, or insider tips"
4. End with an inviting question like "What interests you most?" or "What would you like to know?"

Keep it concise (2-3 sentences max) but make sure to give CONCRETE examples of what you can help with based on your knowledge base. Users don't know what information you have - show them!`
          }
          
          const greetingConfig = {
            type: 'response.create',
            response: {
              modalities: ['text', 'audio'],
              instructions: greetingInstructions
            }
          }
          
          sendMessage(greetingConfig)
        }, 500)
      }
      
      dc.value.onmessage = (event) => {
        handleDataChannelMessage(event.data)
      }
      
      dc.value.onclose = () => {
        cleanup()
      }
      
      dc.value.onerror = (event) => {
        console.error('❌ Data channel error:', event)
        error.value = 'Connection error'
        status.value = 'error'
      }
      
      // Handle incoming audio
      pc.value.ontrack = (event) => {
        // CRITICAL FIX: Prevent multiple audio elements from being created
        // On mobile, ontrack can fire multiple times due to ICE reconnections
        // This causes the AI to restart speaking from the beginning
        if (audioElement.value && audioElement.value.srcObject === event.streams[0]) {
          return
        }
        
        // Clean up existing audio element and analyser before creating new ones
        if (audioElement.value) {
          audioElement.value.pause()
          audioElement.value.srcObject = null
        }
        
        if (audioAnalyser.value) {
          try {
            audioAnalyser.value.context.close()
          } catch (err) {
            console.warn('Error closing audio context:', err)
          }
          audioAnalyser.value = null
        }
        
        // Create new audio element
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
      
      // Use backend server to proxy the WebRTC connection
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
      
      // Handle different message types
      switch (message.type) {
        case 'session.created':
        case 'session.updated':
          break
          
        case 'conversation.item.input_audio_transcription.completed':
          // User's speech transcript
          if (message.transcript && onUserTranscriptCallback) {
            onUserTranscriptCallback(message.transcript)
          }
          break
          
        case 'response.audio_transcript.delta':
          // AI response transcript (streaming)
          if (message.delta) {
            currentAssistantTranscript += message.delta
          }
          break
          
        case 'response.audio_transcript.done':
          // AI response complete
          if (currentAssistantTranscript && onAssistantTranscriptCallback) {
            onAssistantTranscriptCallback(currentAssistantTranscript)
            currentAssistantTranscript = ''
          }
          break
          
        case 'response.done':
          // Response fully completed - fallback if no audio_transcript.done
          if (currentAssistantTranscript && onAssistantTranscriptCallback) {
            onAssistantTranscriptCallback(currentAssistantTranscript)
            currentAssistantTranscript = ''
          }
          break
          
        case 'error':
          console.error('❌ OpenAI error:', message.error)
          error.value = message.error?.message || 'Unknown error'
          break
          
        default:
          // Unhandled message type
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
    cleanup()
  }
  
  // Cleanup resources
  function cleanup() {
    // Clean up audio element - CRITICAL: Proper order to prevent audio glitches/noises
    if (audioElement.value) {
      try {
        // Step 1: Mute immediately to prevent any audio glitches
        audioElement.value.muted = true
        audioElement.value.volume = 0
        
        // Step 2: Pause playback
        audioElement.value.pause()
        
        // Step 3: Remove the stream
        if (audioElement.value.srcObject) {
          const stream = audioElement.value.srcObject as MediaStream
          stream.getTracks().forEach(track => track.stop())
        }
        audioElement.value.srcObject = null
        
        // Step 4: Remove event listeners (if any were added)
        audioElement.value.onended = null
        audioElement.value.onerror = null
        
        // Step 5: Nullify reference
        audioElement.value = null
      } catch (err) {
        console.warn('⚠️ Error cleaning up audio element:', err)
        audioElement.value = null
      }
    }
    
    // Clean up audio analyser
    if (audioAnalyser.value) {
      try {
        // Disconnect analyser node before closing context
        audioAnalyser.value.analyser.disconnect()
        audioAnalyser.value.context.close()
      } catch (err) {
        console.warn('⚠️ Error closing audio context:', err)
      }
      audioAnalyser.value = null
    }
    
    // Close data channel
    if (dc.value) {
      try {
        if (dc.value.readyState === 'open') {
          dc.value.close()
        }
      } catch (err) {
        console.warn('⚠️ Error closing data channel:', err)
      }
      dc.value = null
    }
    
    // Close peer connection
    if (pc.value) {
      try {
        pc.value.close()
      } catch (err) {
        console.warn('⚠️ Error closing peer connection:', err)
      }
      pc.value = null
    }
    
    // Stop media stream (microphone)
    if (mediaStream.value) {
      try {
        mediaStream.value.getTracks().forEach(track => {
          track.stop()
        })
      } catch (err) {
        console.warn('⚠️ Error stopping media stream:', err)
      }
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
  
  // Handle page visibility changes (mobile browser going to background)
  function handleVisibilityChange() {
    if (document.hidden && isConnected.value) {
      disconnect()
    }
  }
  
  // Set up visibility listener
  if (typeof document !== 'undefined') {
    document.addEventListener('visibilitychange', handleVisibilityChange)
  }
  
  // Cleanup visibility listener
  function destroyVisibilityListener() {
    if (typeof document !== 'undefined') {
      document.removeEventListener('visibilitychange', handleVisibilityChange)
    }
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
    onAssistantTranscript,
    destroyVisibilityListener  // Expose for cleanup when composable is unmounted
  }
}
