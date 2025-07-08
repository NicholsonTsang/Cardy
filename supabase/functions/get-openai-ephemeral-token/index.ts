import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
// Import from the correct relative path
import { corsHeaders } from '../_shared/cors.ts'

console.log('Create Ephemeral Key function booting up...')

serve(async (req: Request) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    console.log('Handling OPTIONS request');
    return new Response('ok', { headers: corsHeaders })
  }

  console.log(`Received ${req.method} request`);

  try {
    // 1. Retrieve the main OpenAI API Key securely from secrets
    const openaiApiKey = Deno.env.get('OPENAI_API_KEY')
    if (!openaiApiKey) {
      console.error('OPENAI_API_KEY environment variable not set.')
      throw new Error('Server configuration error: OpenAI API Key missing.')
    }

    // 2. Get session parameters from request body (including instructions)
    let requestBody: any = {}
    try {
      requestBody = await req.json()
    } catch (e) {
      // No body provided, use defaults
      console.log('No request body provided, using defaults')
    }
    
    const { instructions, language = 'English' } = requestBody
    
    console.log('Instructions received:', instructions ? instructions.substring(0, 200) + '...' : 'None')
    console.log('Language received:', language)
    
    const sessionParams = {
      model: "gpt-4o-realtime-preview-2025-06-03", // Latest stable model version
      modalities: ["audio", "text"],
      voice: "alloy", // Default or from request
      input_audio_format: "pcm16",
      output_audio_format: "pcm16",
      input_audio_transcription: {
        model: "whisper-1"
      },
      turn_detection: {
        type: "server_vad",
        threshold: 0.5,
        prefix_padding_ms: 300,
        silence_duration_ms: 500
      },
      // Include instructions if provided
      ...(instructions && { instructions: instructions })
    }

    console.log(`Requesting ephemeral key from OpenAI API for model: ${sessionParams.model}...`);
    console.log('Session params being sent to OpenAI:', JSON.stringify(sessionParams, null, 2));

    // 3. Make the POST request to OpenAI's REST API
    const openaiResponse = await fetch("https://api.openai.com/v1/realtime/sessions", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${openaiApiKey}`,
        "Content-Type": "application/json",
        // OpenAI Beta header IS required for this REST endpoint based on examples
        "OpenAI-Beta": "realtime=v1",
      },
      body: JSON.stringify(sessionParams),
    });

    console.log(`OpenAI API response status: ${openaiResponse.status}`);

    // 4. Check if the request to OpenAI was successful
    if (!openaiResponse.ok) {
      const errorBody = await openaiResponse.text();
      console.error(`OpenAI API Error: ${openaiResponse.status} ${openaiResponse.statusText}`, errorBody);
      // Try to parse error body for more specific message
      let errorMessage = `Failed to create OpenAI session: ${openaiResponse.statusText}`;
      try {
        const parsedError = JSON.parse(errorBody);
        errorMessage = parsedError?.error?.message || errorMessage;
      } catch (_) {
        // Ignore if parsing fails, use original message
      }
      throw new Error(errorMessage);
    }

    // 5. Parse the JSON response from OpenAI
    const responseData = await openaiResponse.json();
    console.log("Successfully received ephemeral key details from OpenAI.");

    // 6. Return the full JSON response (containing client_secret) to the client
    return new Response(
      JSON.stringify(responseData),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    console.error("Error in Edge Function:", error);
    // Ensure CORS headers are included in error responses too
    return new Response(
        JSON.stringify({ error: error.message || 'An unexpected error occurred.' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
}) 