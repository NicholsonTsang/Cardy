// Edge Function: generate-tts-audio
// Generates audio from text using OpenAI TTS API

Deno.serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response(null, {
      status: 204,
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'POST, OPTIONS',
        'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
      },
    })
  }

  try {
    // Parse request body
    const { text, voice, language } = await req.json()

    if (!text || typeof text !== 'string') {
      return new Response(
        JSON.stringify({ error: 'Text is required and must be a string' }),
        { 
          status: 400,
          headers: { 
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
          }
        }
      )
    }

    // Get OpenAI API key
    const openaiApiKey = Deno.env.get('OPENAI_API_KEY')
    if (!openaiApiKey) {
      console.error('OPENAI_API_KEY not configured')
      return new Response(
        JSON.stringify({ error: 'OpenAI API key not configured' }),
        { 
          status: 500,
          headers: { 
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
          }
        }
      )
    }

    // Get configuration from environment (with defaults)
    const ttsModel = Deno.env.get('OPENAI_TTS_MODEL') || 'tts-1'
    const ttsVoice = voice || Deno.env.get('OPENAI_TTS_VOICE') || 'alloy'
    const ttsFormat = Deno.env.get('OPENAI_AUDIO_FORMAT') || 'wav'

    console.log('Generating TTS audio:', {
      textLength: text.length,
      model: ttsModel,
      voice: ttsVoice,
      format: ttsFormat,
      language: language || 'auto'
    })

    // Call OpenAI TTS API
    const ttsResponse = await fetch('https://api.openai.com/v1/audio/speech', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${openaiApiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: ttsModel,
        voice: ttsVoice,
        input: text,
        response_format: ttsFormat,
      }),
    })

    if (!ttsResponse.ok) {
      const errorText = await ttsResponse.text()
      console.error('OpenAI TTS API error:', errorText)
      return new Response(
        JSON.stringify({ 
          error: 'Failed to generate audio',
          details: errorText 
        }),
        { 
          status: ttsResponse.status,
          headers: { 
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
          }
        }
      )
    }

    // Get audio as array buffer
    const audioData = await ttsResponse.arrayBuffer()

    console.log('TTS audio generated successfully:', {
      audioSize: audioData.byteLength,
      format: ttsFormat
    })

    // Return audio data
    return new Response(audioData, {
      status: 200,
      headers: {
        'Content-Type': `audio/${ttsFormat}`,
        'Access-Control-Allow-Origin': '*',
        'Cache-Control': 'public, max-age=3600', // Cache for 1 hour
      },
    })

  } catch (error) {
    console.error('Error in generate-tts-audio:', error)
    return new Response(
      JSON.stringify({ 
        error: 'Internal server error',
        message: error.message 
      }),
      { 
        status: 500,
        headers: { 
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*'
        }
      }
    )
  }
})

