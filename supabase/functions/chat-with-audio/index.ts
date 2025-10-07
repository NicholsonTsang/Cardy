// Use Deno's built-in serve
import { corsHeaders } from '../_shared/cors.ts'

const serve = Deno.serve

interface ChatMessage {
  role: 'system' | 'user' | 'assistant'
  content?: string | Array<{
    type: 'text' | 'input_audio'
    text?: string
    input_audio?: {
      data: string
      format: string
    }
  }>
  audio?: {
    data: string
    format: string
  }
}

interface RequestBody {
  messages: ChatMessage[]
  systemPrompt?: string
  systemInstructions?: string  // Accept both parameter names
  language: string
  modalities?: ('text' | 'audio')[]
  textMessage?: string  // For text-only input
  voiceInput?: {
    data: string  // base64 audio
    format: string
  }
  transcribeOnly?: boolean  // If true, only return transcription without generating response
}

serve(async (req) => {
  // Handle CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { 
      messages, 
      systemPrompt,
      systemInstructions, // Accept both parameter names
      language, 
      modalities = ['text', 'audio'],
      voiceInput,
      transcribeOnly = false
    }: RequestBody = await req.json()

    console.log('Chat with audio request:', {
      messageCount: messages?.length || 0,
      language,
      modalities,
      hasVoiceInput: !!voiceInput,
      transcribeOnly,
      hasSystemPrompt: !!(systemPrompt || systemInstructions)
    })

    // Validate messages
    if (!messages || !Array.isArray(messages)) {
      throw new Error('Messages array is required')
    }

    // Filter out any messages with null/undefined/empty content
    const validMessages = messages.filter(msg => {
      if (!msg) return false
      // Allow messages with content arrays (for audio input)
      if (Array.isArray(msg.content)) return msg.content.length > 0
      // Filter out null/undefined/empty string content
      return msg.content != null && msg.content !== ''
    })

    console.log(`Filtered messages: ${messages.length} → ${validMessages.length} valid`)

    // Get OpenAI API key
    const openaiApiKey = Deno.env.get('OPENAI_API_KEY')
    if (!openaiApiKey) {
      throw new Error('OPENAI_API_KEY not configured')
    }

    // Get STT mode and models (configurable)
    const sttMode = Deno.env.get('OPENAI_STT_MODE') || 'audio-model'
    const audioModel = Deno.env.get('OPENAI_AUDIO_MODEL') || 'gpt-4o-mini-audio-preview'
    const whisperModel = Deno.env.get('OPENAI_WHISPER_MODEL') || 'whisper-1'
    const textModel = Deno.env.get('OPENAI_TEXT_MODEL') || 'gpt-4o-mini'

    // Build messages array with system prompt (accept both parameter names)
    const systemMessage = systemPrompt || systemInstructions || 'You are a helpful AI assistant for museum and exhibition visitors.'
    
    const fullMessages: ChatMessage[] = [
      { role: 'system', content: systemMessage }
    ]

    // Add conversation history (already filtered)
    validMessages.forEach(msg => {
      fullMessages.push(msg)
    })

    // Handle voice input based on STT mode
    let userTranscription = ''
    
    if (voiceInput) {
      console.log('STT Mode:', sttMode)
      
      // Always get transcription for display in UI (lightweight Whisper call)
      console.log('Getting user transcription via Whisper for UI display...')
      console.log('Voice input format:', voiceInput.format)
      console.log('Voice input data length:', voiceInput.data.length)
      
      try {
        const audioBuffer = Uint8Array.from(atob(voiceInput.data), c => c.charCodeAt(0))
        console.log('Audio buffer size:', audioBuffer.length)
        
        const audioBlob = new Blob([audioBuffer], { type: `audio/${voiceInput.format}` })
        console.log('Audio blob created, size:', audioBlob.size, 'type:', audioBlob.type)
        
        const formData = new FormData()
        formData.append('file', audioBlob, `audio.${voiceInput.format}`)
        formData.append('model', 'whisper-1')
        
        // Convert language code to ISO-639-1 format for Whisper API
        if (language) {
          let whisperLanguage = language
          // Map language codes to ISO-639-1 format
          const languageMap: Record<string, string> = {
            'zh-HK': 'zh',  // Cantonese → Chinese
            'zh-CN': 'zh',  // Mandarin → Chinese
            'zh-hk': 'zh',  // Cantonese (lowercase) → Chinese
            'zh-cn': 'zh',  // Mandarin (lowercase) → Chinese
            'en': 'en',     // English
            'ja': 'ja',     // Japanese
            'ko': 'ko',     // Korean
            'es': 'es',     // Spanish
            'fr': 'fr',     // French
            'ru': 'ru',     // Russian
            'ar': 'ar',     // Arabic
            'th': 'th',     // Thai
          }
          
          whisperLanguage = languageMap[language] || language.split('-')[0]
          formData.append('language', whisperLanguage)
          console.log('Original language:', language, '→ Whisper language:', whisperLanguage)
        }
        
        console.log('Calling Whisper API...')
        const whisperResponse = await fetch('https://api.openai.com/v1/audio/transcriptions', {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${openaiApiKey}`,
          },
          body: formData
        })
        
        console.log('Whisper response status:', whisperResponse.status)
        
        if (whisperResponse.ok) {
          const whisperData = await whisperResponse.json()
          userTranscription = whisperData.text
          console.log('✅ User transcription SUCCESS:', userTranscription)
          console.log('✅ Transcription length:', userTranscription.length)
        } else {
          const errorText = await whisperResponse.text()
          console.error('❌ Whisper transcription failed:', whisperResponse.status, errorText)
          // Set a more descriptive error message
          userTranscription = `[Transcription failed: ${whisperResponse.status}]`
        }
      } catch (err: any) {
        console.error('❌ Failed to get transcription - Exception:', err)
        console.error('❌ Error message:', err.message)
        console.error('❌ Error stack:', err.stack)
        // Set a descriptive error message
        userTranscription = `[Transcription error: ${err.message}]`
      }
      
      console.log('Final userTranscription:', userTranscription || '[EMPTY]')
      console.log('userTranscription will be sent to frontend as:', JSON.stringify(userTranscription))
      
      if (sttMode === 'whisper') {
        // Mode 1: Use Whisper for both display and generation (already have transcription)
        console.log('Using Whisper STT mode - adding transcription to messages')
        
        fullMessages.push({
          role: 'user',
          content: userTranscription || '[Voice input]'
        })
        
      } else {
        // Mode 2: Use Audio Model for generation (but keep transcription for display)
        console.log('Using Audio Model STT mode - sending audio input')
        
        fullMessages.push({
          role: 'user',
          content: [
            {
              type: 'input_audio',
              input_audio: {
                data: voiceInput.data,
                format: voiceInput.format
              }
            }
          ]
        })
      }
    }

    // If transcribeOnly mode, return just the transcription without calling OpenAI
    if (transcribeOnly && voiceInput) {
      console.log('Transcribe-only mode: returning transcription without generating response')
      return new Response(
        JSON.stringify({
          success: true,
          userTranscription: userTranscription || '[Voice input]',
          transcribeOnly: true
        }),
        { 
          headers: { 
            ...corsHeaders, 
            'Content-Type': 'application/json' 
          } 
        }
      )
    }

    console.log('Calling OpenAI Chat Completions API...')
    console.log('Total messages:', fullMessages.length)
    console.log('Requested modalities:', modalities)

    // Choose model based on STT mode and voice input
    let modelToUse = textModel
    if (sttMode === 'audio-model' && voiceInput) {
      modelToUse = audioModel
      // Ensure audio modality is included for audio model
      if (!modalities.includes('audio')) {
        modalities.push('audio')
      }
    }
    
    console.log('Using model:', modelToUse)
    console.log('Output modalities:', modalities)

    // Determine output modalities based on STT mode and request
    const outputModalities = sttMode === 'audio-model' && voiceInput 
      ? (modalities.includes('audio') ? modalities : ['text', 'audio']) 
      : ['text']

    // Build request body
    const requestBody: any = {
      model: modelToUse,
      modalities: outputModalities,
      messages: fullMessages,
      max_tokens: parseInt(Deno.env.get('OPENAI_MAX_TOKENS') || '3500'),
      temperature: 0.7
    }

    // Only include audio config if audio is in output modalities
    if (outputModalities.includes('audio')) {
      requestBody.audio = { 
        voice: Deno.env.get('OPENAI_TTS_VOICE') || 'alloy',
        format: Deno.env.get('OPENAI_AUDIO_FORMAT') || 'wav'
      }
    }

    console.log('Request body:', JSON.stringify(requestBody, null, 2))

    // Call OpenAI Chat Completions API with audio support
    const openaiResponse = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${openaiApiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(requestBody)
    })

    const responseData = await openaiResponse.json()
    
    console.log('OpenAI response status:', openaiResponse.status)
    
    if (!openaiResponse.ok) {
      console.error('OpenAI API error:', responseData)
      throw new Error(responseData.error?.message || 'OpenAI API request failed')
    }

    const assistantMessage = responseData.choices[0].message
    
    console.log('=== OpenAI Response Debug ===')
    console.log('Full response data:', JSON.stringify(responseData, null, 2))
    console.log('Assistant message:', JSON.stringify(assistantMessage, null, 2))
    console.log('Content type:', typeof assistantMessage.content)
    console.log('Content value:', assistantMessage.content)
    console.log('Is array?:', Array.isArray(assistantMessage.content))
    
    // Extract text content from the response
    let textContent = ''
    
    if (!assistantMessage.content) {
      console.warn('No content in assistant message!')
      // When audio is generated, content is null and text is in audio.transcript
      if (assistantMessage.audio?.transcript) {
        console.log('Using audio transcript as text content')
        textContent = assistantMessage.audio.transcript
      } else {
        // Check if there's text in refusal or other fields
        textContent = assistantMessage.refusal || ''
      }
    } else if (typeof assistantMessage.content === 'string') {
      console.log('Content is string')
      textContent = assistantMessage.content
    } else if (Array.isArray(assistantMessage.content)) {
      console.log('Content is array, length:', assistantMessage.content.length)
      console.log('Array items:', JSON.stringify(assistantMessage.content, null, 2))
      
      // Try to find text content
      const textPart = assistantMessage.content.find((part: any) => part.type === 'text')
      console.log('Found text part:', textPart)
      textContent = textPart?.text || ''
    } else if (typeof assistantMessage.content === 'object') {
      console.log('Content is object (not array)')
      // Handle case where content is an object with text property
      textContent = (assistantMessage.content as any).text || ''
    }
    
    console.log('Final extracted text content:', textContent)
    console.log('Text content length:', textContent.length)
    console.log('Text preview (first 200 chars):', textContent?.substring(0, 200))
    console.log('=== End Debug ===')

    // Return the assistant's message with user transcription
    return new Response(
      JSON.stringify({
        success: true,
        message: {
          role: 'assistant',
          content: textContent,  // Always return string, not array
          audio: assistantMessage.audio ? {
            id: assistantMessage.audio.id,
            data: assistantMessage.audio.data,
            transcript: assistantMessage.audio.transcript,
            expires_at: assistantMessage.audio.expires_at
          } : null
        },
        userTranscription: userTranscription || '[Voice input]',  // Always return transcription for UI
        usage: responseData.usage
      }),
      { 
        headers: { 
          ...corsHeaders, 
          'Content-Type': 'application/json' 
        } 
      }
    )

  } catch (error: any) {
    console.error('Chat with audio error:', error)
    
    return new Response(
      JSON.stringify({ 
        success: false,
        error: error.message || 'An error occurred processing your request'
      }),
      { 
        status: 500, 
        headers: { 
          ...corsHeaders, 
          'Content-Type': 'application/json' 
        } 
      }
    )
  }
})

