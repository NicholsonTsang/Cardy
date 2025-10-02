// Use Deno's built-in serve
import { corsHeaders } from '../_shared/cors.ts'

const serve = Deno.serve

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Only allow POST requests
    if (req.method !== 'POST') {
      return new Response(
        JSON.stringify({ error: 'Method not allowed' }),
        { 
          status: 405, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // Get the OpenAI API key from environment
    const openaiApiKey = Deno.env.get('OPENAI_API_KEY')
    if (!openaiApiKey) {
      console.error('OPENAI_API_KEY environment variable not set.')
      return new Response(
        JSON.stringify({ error: 'Server configuration error' }),
        { 
          status: 500, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // Parse the request body - just get what we need for the API call
    const { model, sdpOffer, ephemeralToken, instructions } = await req.json()

    if (!model || !sdpOffer || !ephemeralToken) {
      return new Response(
        JSON.stringify({ error: 'Missing required parameters: model, sdpOffer, ephemeralToken' }),
        { 
          status: 400, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    console.log(`Proxying request to OpenAI Realtime API with model: ${model}`)
    console.log('SDP Offer length:', sdpOffer?.length)
    console.log('SDP Offer preview:', sdpOffer?.substring(0, 100))
    console.log('Ephemeral token preview:', ephemeralToken?.substring(0, 20) + '...')

    // Make the request to OpenAI Realtime API with SDP offer
    const openaiResponse = await fetch(`https://api.openai.com/v1/realtime?model=${model}`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${ephemeralToken}`,
        'Content-Type': 'application/sdp'
      },
      body: sdpOffer
    })

    console.log('OpenAI API response status:', openaiResponse.status)
    console.log('OpenAI API response headers:', Object.fromEntries(openaiResponse.headers.entries()))

    if (!openaiResponse.ok) {
      const errorText = await openaiResponse.text()
      console.error(`OpenAI API error: ${openaiResponse.status} - ${errorText}`)
      
      return new Response(
        JSON.stringify({ 
          error: `OpenAI API error: ${openaiResponse.status}`,
          details: errorText
        }),
        { 
          status: openaiResponse.status, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // Get the SDP answer from OpenAI
    const sdpAnswer = await openaiResponse.text()
    
    console.log('Successfully received SDP answer from OpenAI')
    console.log('SDP Answer length:', sdpAnswer.length)
    console.log('SDP Answer preview:', sdpAnswer.substring(0, 100))
    console.log('SDP Answer starts with v=:', sdpAnswer.startsWith('v='))

    // Return the SDP answer and pass through the client's instructions
    return new Response(
      JSON.stringify({ 
        success: true,
        sdpAnswer: sdpAnswer,
        status: openaiResponse.status,
        instructions: instructions // Just pass through what the client sent
      }),
      { 
        status: 200, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )

  } catch (error) {
    console.error('Error in OpenAI Realtime proxy:', error)
    
    return new Response(
      JSON.stringify({ 
        error: 'Internal server error',
        details: error.message
      }),
      { 
        status: 500, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )
  }
}) 