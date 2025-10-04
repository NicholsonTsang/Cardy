// Streaming version of chat-with-audio for text-only responses
import { corsHeaders } from '../_shared/cors.ts'

Deno.serve(async (req) => {
  // Handle CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { 
      messages, 
      systemPrompt, 
      language 
    } = await req.json()

    console.log('Streaming chat request:', {
      messageCount: messages.length,
      language
    })

    // Get OpenAI API key
    const openaiApiKey = Deno.env.get('OPENAI_API_KEY')
    if (!openaiApiKey) {
      throw new Error('OPENAI_API_KEY not configured')
    }

    // Build messages array with system prompt
    const fullMessages = [
      { role: 'system', content: systemPrompt },
      ...messages
    ]

    // Call OpenAI with streaming enabled (use text-capable model)
    const openaiResponse = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${openaiApiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        // IMPORTANT: audio-preview models do not support streaming in chat/completions
        model: Deno.env.get('OPENAI_TEXT_MODEL') || 'gpt-4o-mini',
        messages: fullMessages,
        max_tokens: parseInt(Deno.env.get('OPENAI_MAX_TOKENS') || '3500'),
        temperature: 0.7,
        stream: true  // Enable streaming
      })
    })

    if (!openaiResponse.ok) {
      const errorText = await openaiResponse.text()
      console.error('OpenAI API error:', errorText)
      throw new Error(`OpenAI API error: ${openaiResponse.status}`)
    }

    // Set up SSE headers
    const headers = {
      ...corsHeaders,
      'Content-Type': 'text/event-stream',
      'Cache-Control': 'no-cache',
      'Connection': 'keep-alive',
    }

    // Stream the response
    const reader = openaiResponse.body?.getReader()
    const decoder = new TextDecoder()

    const stream = new ReadableStream({
      async start(controller) {
        try {
          let buffer = ''
          
          while (true) {
            const { done, value } = await reader!.read()
            
            if (done) {
              // Send completion event
              controller.enqueue(new TextEncoder().encode('data: [DONE]\n\n'))
              controller.close()
              break
            }

            buffer += decoder.decode(value, { stream: true })
            const lines = buffer.split('\n')
            buffer = lines.pop() || ''

            for (const line of lines) {
              if (line.startsWith('data: ')) {
                const data = line.slice(6)
                
                if (data === '[DONE]') continue
                
                try {
                  const parsed = JSON.parse(data)
                  const content = parsed.choices[0]?.delta?.content
                  
                  if (content) {
                    // Forward content chunk to client
                    const event = `data: ${JSON.stringify({ content })}\n\n`
                    controller.enqueue(new TextEncoder().encode(event))
                  }
                } catch (e) {
                  // Skip invalid JSON
                  console.error('Parse error:', e)
                }
              }
            }
          }
        } catch (error) {
          console.error('Stream error:', error)
          controller.error(error)
        }
      }
    })

    return new Response(stream, { headers })

  } catch (error: any) {
    console.error('Error:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { 
        status: 500, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )
  }
})

