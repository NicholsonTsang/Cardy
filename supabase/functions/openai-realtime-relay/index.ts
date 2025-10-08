import { corsHeaders } from '../_shared/cors.ts'

interface RealtimeSessionConfig {
  model?: string
  voice?: string
  instructions?: string
  input_audio_format?: string
  output_audio_format?: string
  temperature?: number
  max_response_output_tokens?: number
}

interface CreateSessionRequest {
  language?: string
  systemPrompt?: string
  systemInstructions?: string  // Accept both parameter names for consistency
  contentItemName?: string
}

/**
 * OpenAI Realtime Relay Edge Function
 * 
 * Generates ephemeral tokens and provides session configuration
 * for OpenAI Realtime API connections.
 * 
 * Note: The actual WebRTC connection is established directly between
 * the client and OpenAI. This function only provides the token and config.
 */
Deno.serve(async (req: Request) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders })
  }

  try {
    const openaiApiKey = Deno.env.get('OPENAI_API_KEY')
    if (!openaiApiKey) {
      throw new Error('OPENAI_API_KEY not configured')
    }

    // Get configuration from environment
    const model = Deno.env.get('OPENAI_REALTIME_MODEL') || 'gpt-4o-mini-realtime-preview-2024-12-17'
    const voice = Deno.env.get('OPENAI_REALTIME_VOICE') || 'alloy'
    const temperature = parseFloat(Deno.env.get('OPENAI_REALTIME_TEMPERATURE') || '0.8')
    const maxTokens = parseInt(Deno.env.get('OPENAI_REALTIME_MAX_TOKENS') || '4096')

    // Parse request body
    const body = await req.json() as CreateSessionRequest
    const { language = 'en', systemPrompt, systemInstructions, contentItemName } = body

    console.log('Creating realtime session:', { 
      model, 
      voice, 
      language,
      contentItemName: contentItemName || 'N/A',
      hasSystemPrompt: !!(systemPrompt || systemInstructions)
    })

    // Build system instructions (accept both parameter names)
    const defaultInstructions = `You are a helpful AI assistant for a museum or exhibition. 
Provide detailed, engaging explanations about exhibits and artifacts. 
Use natural, conversational language suitable for voice interaction.`
    
    let instructions = systemPrompt || systemInstructions || defaultInstructions

    if (contentItemName) {
      instructions += `\n\nYou are currently discussing: ${contentItemName}`
    }

    // Map language codes to full names for better AI understanding
    const languageMap: Record<string, string> = {
      'en': 'English',
      'zh-HK': 'Cantonese',
      'zh-CN': 'Mandarin Chinese',
      'ja': 'Japanese',
      'ko': 'Korean',
      'es': 'Spanish',
      'fr': 'French',
      'ru': 'Russian',
      'ar': 'Arabic',
      'th': 'Thai'
    }

    const languageName = languageMap[language] || 'English'
    instructions += `\n\nIMPORTANT: Respond in ${languageName}. All your responses must be in ${languageName}.`

    // Generate ephemeral token
    console.log('Generating ephemeral token...')
    const tokenResponse = await fetch('https://api.openai.com/v1/realtime/sessions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${openaiApiKey}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        model: model,
        voice: voice
      })
    })

    if (!tokenResponse.ok) {
      const errorText = await tokenResponse.text()
      console.error('Token generation failed:', tokenResponse.status, errorText)
      throw new Error(`Failed to generate token: ${tokenResponse.status} ${errorText}`)
    }

    const tokenData = await tokenResponse.json()
    console.log('✅ Ephemeral token generated successfully')

    // Return session configuration
    const sessionConfig: RealtimeSessionConfig = {
      model: model,
      voice: voice,
      instructions: instructions,
      input_audio_format: 'pcm16',  // 16-bit PCM for better compatibility
      output_audio_format: 'pcm16',
      temperature: temperature,
      max_response_output_tokens: maxTokens
    }

    return new Response(
      JSON.stringify({
        success: true,
        ephemeral_token: tokenData.client_secret.value,
        session_config: sessionConfig,
        expires_at: tokenData.client_secret.expires_at
      }),
      {
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json'
        }
      }
    )

  } catch (error: any) {
    console.error('❌ Realtime relay error:', error)
    return new Response(
      JSON.stringify({
        success: false,
        error: error.message || 'Failed to create realtime session'
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

