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
  systemPrompt: string
  language: string
  modalities?: ('text' | 'audio')[]
  voiceInput?: {
    data: string  // base64 audio
    format: string
  }
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
      language, 
      modalities = ['text', 'audio'],
      voiceInput 
    }: RequestBody = await req.json()

    console.log('Chat with audio request:', {
      messageCount: messages.length,
      language,
      modalities,
      hasVoiceInput: !!voiceInput
    })

    // Get OpenAI API key
    const openaiApiKey = Deno.env.get('OPENAI_API_KEY')
    if (!openaiApiKey) {
      throw new Error('OPENAI_API_KEY not configured')
    }

    // Build messages array with system prompt
    const fullMessages: ChatMessage[] = [
      { role: 'system', content: systemPrompt }
    ]

    // Add conversation history
    messages.forEach(msg => {
      fullMessages.push(msg)
    })

    // If there's voice input, add it as the latest user message
    if (voiceInput) {
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

    console.log('Calling OpenAI Chat Completions API...')
    console.log('Total messages:', fullMessages.length)

    // Call OpenAI Chat Completions API with audio support
    const openaiResponse = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${openaiApiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: Deno.env.get('OPENAI_AUDIO_MODEL') || 'gpt-4o-audio-preview',
        modalities: modalities,
        audio: { 
          voice: Deno.env.get('OPENAI_TTS_VOICE') || 'alloy',
          format: Deno.env.get('OPENAI_AUDIO_FORMAT') || 'wav'
        },
        messages: fullMessages,
        max_tokens: 500,
        temperature: 0.7
      })
    })

    const responseData = await openaiResponse.json()
    
    console.log('OpenAI response status:', openaiResponse.status)
    
    if (!openaiResponse.ok) {
      console.error('OpenAI API error:', responseData)
      throw new Error(responseData.error?.message || 'OpenAI API request failed')
    }

    const assistantMessage = responseData.choices[0].message
    
    console.log('Assistant message:', {
      hasContent: !!assistantMessage.content,
      hasAudio: !!assistantMessage.audio,
      audioId: assistantMessage.audio?.id
    })

    // Return the assistant's message
    return new Response(
      JSON.stringify({
        success: true,
        message: {
          role: 'assistant',
          content: assistantMessage.content || '',
          audio: assistantMessage.audio ? {
            id: assistantMessage.audio.id,
            data: assistantMessage.audio.data,
            transcript: assistantMessage.audio.transcript,
            expires_at: assistantMessage.audio.expires_at
          } : null
        },
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

