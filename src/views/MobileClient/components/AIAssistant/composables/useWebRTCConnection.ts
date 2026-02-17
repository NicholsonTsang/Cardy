import { ref, computed } from 'vue'
import { supabase } from '@/lib/supabase'
import { buildRealtimeGreetingInstructions } from '../utils/promptBuilder'

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

  // Voice billing state
  const hardLimitSeconds = ref(0)
  const remainingCredits = ref(0)
  const voiceSessionId = ref<string | null>(null)
  const voiceCallStartTime = ref<number | null>(null)

  // Transcript callbacks
  let onUserTranscriptCallback: ((text: string) => void) | null = null
  let onAssistantTranscriptCallback: ((text: string) => void) | null = null

  // Generation counter to prevent stale audio check loops from ICE reconnections
  let audioCheckGeneration = 0

  // Greeting state (moved to composable scope so it's accessible in message handler)
  let greetingInfo: { language: string; customWelcome?: string; isItemMode: boolean } | null = null
  let greetingSent = false

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
  // cardId is required for voice billing (credit deduction happens server-side)
  async function getEphemeralToken(language: string, cardId?: string) {
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
          cardId,
          sessionConfig: {
            voice: voiceMap[language] || 'alloy'
          }
        })
      })

      if (!response.ok) {
        const errorData = await response.json().catch(() => ({ error: 'Unknown error' }))
        // Surface specific billing errors for the UI to handle
        if (response.status === 402) {
          throw new Error('NO_VOICE_CREDITS')
        }
        if (response.status === 403) {
          throw new Error('VOICE_NOT_ENABLED')
        }
        throw new Error(errorData.error || 'Failed to get ephemeral token')
      }

      const data = await response.json()
      if (!data.success) throw new Error(data.error)

      // Store billing info from response
      if (data.hardLimitSeconds) {
        hardLimitSeconds.value = data.hardLimitSeconds
      }
      if (data.remainingCredits !== undefined) {
        remainingCredits.value = data.remainingCredits
      }
      if (data.sessionId) {
        voiceSessionId.value = data.sessionId
      }

      return data.client_secret
    } catch (err: any) {
      console.error('Failed to get ephemeral token:', err)
      throw err
    }
  }
  
  // Initialize WebRTC connection
  // customWelcome: Optional custom welcome message from card settings (ai_welcome_general/ai_welcome_item)
  // cardId: Required for voice billing - credit deduction happens at connection time
  async function connect(language: string, instructions: string, customWelcome?: string, cardId?: string): Promise<void> {
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
      
      // Get ephemeral token (also deducts voice credit server-side)
      const ephemeralToken = await getEphemeralToken(language, cardId)
      voiceCallStartTime.value = Date.now()

      // Request microphone access
      console.log('🎤 Requesting microphone access...')
      try {
        mediaStream.value = await navigator.mediaDevices.getUserMedia({
          audio: {
            echoCancellation: true,
            noiseSuppression: true,
            autoGainControl: true,
            sampleRate: 24000  // OpenAI Realtime API expects 24kHz
          }
        })
        console.log('✅ Microphone access granted')

        // Log audio track info for debugging
        const audioTracks = mediaStream.value.getAudioTracks()
        if (audioTracks.length > 0) {
          const track = audioTracks[0]
          console.log('🎤 Audio track:', {
            label: track.label,
            enabled: track.enabled,
            muted: track.muted,
            settings: track.getSettings()
          })
        }
      } catch (err: any) {
        console.error('❌ Microphone access denied:', err)
        throw new Error('Microphone access required for voice conversation. Please allow microphone permission in your browser settings.')
      }
      
      // Create peer connection
      console.log('🔗 Creating peer connection...')
      pc.value = new RTCPeerConnection({
        iceServers: [
          { urls: 'stun:stun.l.google.com:19302' }
        ]
      })

      // Monitor ICE connection state for debugging
      pc.value.oniceconnectionstatechange = () => {
        console.log('🔗 ICE connection state:', pc.value?.iceConnectionState)
        if (pc.value?.iceConnectionState === 'failed') {
          console.error('❌ ICE connection failed - audio may not flow')
        }
      }

      // Monitor connection state
      pc.value.onconnectionstatechange = () => {
        console.log('🔗 Connection state:', pc.value?.connectionState)
      }

      // Add audio track
      const audioTrack = mediaStream.value.getAudioTracks()[0]
      console.log('📤 Adding audio track to peer connection...')
      const sender = pc.value.addTrack(audioTrack, mediaStream.value)
      console.log('✅ Audio track added:', {
        trackId: audioTrack.id,
        senderId: sender.track?.id,
        enabled: sender.track?.enabled,
        muted: sender.track?.muted
      })

      // Verify the sender is actually sending
      if (sender.track) {
        console.log('📤 Audio sender ready:', {
          readyState: sender.track.readyState,
          enabled: sender.track.enabled
        })
      }

      // Create data channel for text/events
      dc.value = pc.value.createDataChannel('oai-events', {
        ordered: true
      })

      // Set up data channel handlers
      dc.value.onopen = () => {
        isConnected.value = true
        status.value = 'connected'

        console.log('✅ Data channel opened, configuring session...')

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

        // Store greeting info to be sent after session.updated confirmation
        greetingInfo = {
          language: languageNames[language] || 'English',
          customWelcome,
          isItemMode: false // will be passed from caller if needed
        }
        greetingSent = false // Reset flag for new connection
        console.log('💾 Greeting info stored:', greetingInfo)

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
              threshold: parseFloat(import.meta.env.VITE_REALTIME_VAD_THRESHOLD) || 0.5,           // Lower = more sensitive (range: 0.0-1.0, default: 0.5 for better detection)
              prefix_padding_ms: parseInt(import.meta.env.VITE_REALTIME_VAD_PREFIX_PADDING) || 300, // Audio before speech detection (default: 300ms)
              silence_duration_ms: parseInt(import.meta.env.VITE_REALTIME_VAD_SILENCE_DURATION) || 800 // Silence required before ending turn (default: 800ms)
            },
            temperature: 0.8,
            max_response_output_tokens: 4096
          }
        }

        // Send session configuration
        console.log('📤 Sending session configuration...')
        console.log('🎙️ VAD settings:', sessionConfig.session.turn_detection)
        sendMessage(sessionConfig)

        // Greeting will be triggered after receiving session.updated confirmation
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
        console.log('🔊 Setting up audio playback...')
        audioElement.value = new Audio()
        audioElement.value.srcObject = event.streams[0]
        audioElement.value.autoplay = true

        // CRITICAL: Explicitly play the audio (autoplay alone may not work)
        audioElement.value.play().then(() => {
          console.log('✅ Audio playback started successfully')
        }).catch((err) => {
          console.error('❌ Audio playback failed:', err)
          // Try again - sometimes first attempt fails on mobile
          setTimeout(() => {
            audioElement.value?.play().catch(e => console.error('Retry failed:', e))
          }, 100)
        })

        // Track speaking state
        const audioContext = new AudioContext()

        // CRITICAL: Resume AudioContext if suspended (required on many browsers)
        if (audioContext.state === 'suspended') {
          console.log('⚠️ AudioContext suspended, resuming...')
          audioContext.resume().then(() => {
            console.log('✅ AudioContext resumed')
          })
        }

        const source = audioContext.createMediaStreamSource(event.streams[0])
        const analyser = audioContext.createAnalyser()
        source.connect(analyser)

        // Store analyser for cleanup
        audioAnalyser.value = { context: audioContext, analyser }

        console.log('🔊 Audio output connected, AudioContext state:', audioContext.state)

        // Increment generation to invalidate any previous audio check loops
        const currentGeneration = ++audioCheckGeneration

        const dataArray = new Uint8Array(analyser.frequencyBinCount)
        const checkAudio = () => {
          // Stop if generation has changed (new ontrack fired) or disconnected
          if (audioCheckGeneration !== currentGeneration || !isConnected.value) {
            return
          }
          analyser.getByteFrequencyData(dataArray)
          const average = dataArray.reduce((a, b) => a + b) / dataArray.length
          isSpeaking.value = average > 30
          requestAnimationFrame(checkAudio)
        }
        checkAudio()
      }
      
      // Create offer
      const offer = await pc.value.createOffer()
      await pc.value.setLocalDescription(offer)

      // Use backend server to proxy the WebRTC connection
      // Note: Backend determines the model from its environment config
      const response = await fetch(`${backendUrl}/offer`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          sdp: offer.sdp,
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

      console.log('✅ WebRTC connection established')
      console.log('📊 Connection details:', {
        iceConnectionState: pc.value.iceConnectionState,
        connectionState: pc.value.connectionState,
        signalingState: pc.value.signalingState,
        senders: pc.value.getSenders().length,
        receivers: pc.value.getReceivers().length
      })

      // Verify audio is being sent
      const senders = pc.value.getSenders()
      senders.forEach((sender, index) => {
        if (sender.track?.kind === 'audio') {
          console.log(`📤 Audio sender ${index}:`, {
            enabled: sender.track.enabled,
            muted: sender.track.muted,
            readyState: sender.track.readyState
          })
        }
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
          console.log('✅ Session created')
          break

        case 'session.updated':
          console.log('✅ Session updated, sending AI greeting...')
          console.log('🔍 Greeting state check:', {
            greetingSent,
            hasGreetingInfo: !!greetingInfo,
            greetingInfo
          })

          // FIX: Send greeting AFTER session is fully configured
          // This ensures the AI speaks first to guide the user
          if (!greetingSent && greetingInfo) {
            console.log('📤 Triggering AI greeting...')

            const greetingInstructions = buildRealtimeGreetingInstructions(
              greetingInfo.language,
              greetingInfo.customWelcome,
              greetingInfo.isItemMode
            )

            console.log('📝 Greeting instructions:', greetingInstructions.substring(0, 100) + '...')

            const greetingConfig = {
              type: 'response.create',
              response: {
                modalities: ['text', 'audio'],
                instructions: greetingInstructions
              }
            }

            sendMessage(greetingConfig)
            greetingSent = true
            console.log('✅ Greeting message sent')
          } else {
            console.warn('⚠️ Skipping greeting:', {
              reason: greetingSent ? 'Already sent' : 'No greeting info',
              greetingSent,
              greetingInfo
            })
          }
          break
          
        case 'conversation.item.input_audio_transcription.completed':
          // User's speech transcript
          console.log('🎤 User speech transcribed:', message.transcript)
          if (message.transcript && onUserTranscriptCallback) {
            onUserTranscriptCallback(message.transcript)
          }
          break

        case 'input_audio_buffer.speech_started':
          console.log('🎤 Speech detected - user started speaking', message)
          break

        case 'input_audio_buffer.speech_stopped':
          console.log('🎤 Speech stopped - processing...', message)
          break

        case 'input_audio_buffer.committed':
          console.log('🎤 Audio buffer committed', message)
          break

        case 'conversation.item.created':
          console.log('💬 Conversation item created:', message.item?.type)
          break
          
        case 'response.audio_transcript.delta':
          // AI response transcript (streaming)
          if (message.delta) {
            currentAssistantTranscript += message.delta
          }
          break

        case 'response.audio_transcript.done':
          // AI response complete
          console.log('🤖 AI response complete:', currentAssistantTranscript)
          if (currentAssistantTranscript && onAssistantTranscriptCallback) {
            onAssistantTranscriptCallback(currentAssistantTranscript)
            currentAssistantTranscript = ''
          }
          break

        case 'response.done':
          // Response fully completed - fallback if no audio_transcript.done
          console.log('✅ Response done')
          if (currentAssistantTranscript && onAssistantTranscriptCallback) {
            onAssistantTranscriptCallback(currentAssistantTranscript)
            currentAssistantTranscript = ''
          }
          break

        case 'response.created':
          console.log('🤖 AI response started')
          break

        case 'response.output_item.added':
          console.log('🤖 AI output item added')
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
  
  // Report voice call end to backend for duration logging
  // Uses sendBeacon for reliability (works during page unload)
  function reportCallEnd(cardId?: string) {
    if (!voiceSessionId.value || !voiceCallStartTime.value) return

    const durationSeconds = Math.round((Date.now() - voiceCallStartTime.value) / 1000)
    const backendUrl = import.meta.env.VITE_BACKEND_URL

    if (!backendUrl) return

    const payload = JSON.stringify({
      cardId: cardId || '',
      sessionId: voiceSessionId.value,
      durationSeconds
    })

    // Use sendBeacon for reliability during page unload
    const sent = navigator.sendBeacon(
      `${backendUrl}/api/ai/realtime-end`,
      new Blob([payload], { type: 'application/json' })
    )

    if (!sent) {
      // Fallback to fetch (fire-and-forget)
      fetch(`${backendUrl}/api/ai/realtime-end`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: payload
      }).catch(() => {})
    }

    console.log(`📊 Voice call ended: ${durationSeconds}s, session ${voiceSessionId.value}`)
  }

  // Disconnect and cleanup
  function disconnect(cardId?: string) {
    reportCallEnd(cardId)
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

    // Reset callbacks and greeting state to prevent stale closures on reconnect
    onUserTranscriptCallback = null
    onAssistantTranscriptCallback = null
    greetingInfo = null
    greetingSent = false

    // Reset billing state
    voiceSessionId.value = null
    voiceCallStartTime.value = null
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

    // Voice billing state
    hardLimitSeconds,
    remainingCredits,
    voiceSessionId,

    // Methods
    connect,
    disconnect,
    interrupt,
    sendText,
    onUserTranscript,
    onAssistantTranscript,
    reportCallEnd
  }
}
