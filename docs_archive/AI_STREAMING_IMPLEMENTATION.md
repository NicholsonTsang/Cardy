# AI Assistant Streaming Implementation

## 🎯 Overview

Implementing Server-Sent Events (SSE) streaming for the AI assistant to provide faster, more responsive user experience with progressive text rendering.

---

## 📋 Implementation Plan

### **Phase 1: Text-Only Streaming** ✅ (Recommended)

**For text input → text output:**
- ✅ Use OpenAI streaming with `stream: true`
- ✅ Implement SSE in Edge Function
- ✅ Progressive message rendering in frontend
- ⚡ Immediate feedback as AI generates response

**Benefits:**
- Fast response start (first token in ~200-500ms)
- Better perceived performance
- User sees thinking in real-time
- Lower perceived latency

---

### **Phase 2: Audio Handling** (Current Non-Streaming)

**For voice input → text + audio output:**
- ❌ OpenAI Chat Completions API does NOT support streaming with audio
- ✅ Keep current non-streaming approach for voice
- 💡 Hybrid solution: stream text, buffer audio

**Limitation:**
- `gpt-4o-audio-preview` with `audio` modality doesn't support streaming
- Must wait for complete response to get audio

---

## 🔧 Architecture

### **Streaming Flow (Text Input):**

```
User Types → Frontend → Edge Function → OpenAI (stream) 
                                            ↓
Frontend ← SSE Stream ← Edge Function ← Chunks
  ↓
Progressive Text Rendering
```

### **Non-Streaming Flow (Voice Input):**

```
User Speaks → Frontend → Edge Function → OpenAI (no stream)
                                            ↓
Frontend ← Complete Response ← Edge Function ← Full Audio + Text
  ↓
Display Text + Play Audio
```

---

## 💻 Implementation Code

### **1. Update Edge Function (`chat-with-audio/index.ts`)**

Add streaming support for text-only requests:

```typescript
serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { 
      messages, 
      systemPrompt, 
      language, 
      modalities = ['text', 'audio'],
      voiceInput,
      stream = false  // NEW: Support streaming parameter
    }: RequestBody = await req.json()

    // ... existing setup code ...

    const requestBody: any = {
      model: Deno.env.get('OPENAI_AUDIO_MODEL') || 'gpt-4o-mini-audio-preview',
      modalities: outputModalities,
      messages: fullMessages,
      max_tokens: parseInt(Deno.env.get('OPENAI_MAX_TOKENS') || '3500'),
      temperature: 0.7,
      stream: stream  // NEW: Enable streaming
    }

    // Only include audio config if audio is in output modalities
    if (outputModalities.includes('audio')) {
      requestBody.audio = { 
        voice: Deno.env.get('OPENAI_TTS_VOICE') || 'alloy',
        format: Deno.env.get('OPENAI_AUDIO_FORMAT') || 'wav'
      }
      requestBody.stream = false  // Force non-streaming for audio
    }

    const openaiResponse = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${openaiApiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(requestBody)
    })

    if (!openaiResponse.ok) {
      const errorText = await openaiResponse.text()
      console.error('OpenAI API error:', errorText)
      throw new Error(`OpenAI API error: ${openaiResponse.status}`)
    }

    // Handle streaming response
    if (stream && !outputModalities.includes('audio')) {
      // Set up SSE headers
      const headers = {
        ...corsHeaders,
        'Content-Type': 'text/event-stream',
        'Cache-Control': 'no-cache',
        'Connection': 'keep-alive',
      }

      const reader = openaiResponse.body?.getReader()
      const decoder = new TextDecoder()

      // Create a readable stream for SSE
      const readableStream = new ReadableStream({
        async start(controller) {
          try {
            let buffer = ''
            
            while (true) {
              const { done, value } = await reader!.read()
              
              if (done) {
                // Send final event
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
                      // Send content chunk to client
                      const event = `data: ${JSON.stringify({ content })}\n\n`
                      controller.enqueue(new TextEncoder().encode(event))
                    }
                  } catch (e) {
                    // Skip invalid JSON
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

      return new Response(readableStream, { headers })
    }

    // Handle non-streaming response (existing code)
    const data = await openaiResponse.json()
    // ... rest of existing non-streaming code ...
    
  } catch (error: any) {
    console.error('Error:', error)
    return new Response(
      JSON.stringify({ 
        success: false, 
        error: error.message 
      }),
      { 
        status: 500, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )
  }
})
```

---

### **2. Update Frontend (`MobileAIAssistant.vue`)**

Add SSE handling for streamed responses:

```typescript
async function getAIResponse(textMessage: string) {
  isLoading.value = true
  error.value = null

  // Add user message
  addUserMessage(textMessage)
  textInput.value = ''

  // Add placeholder for assistant message
  const assistantMessageId = Date.now().toString()
  messages.value.push({
    id: assistantMessageId,
    role: 'assistant',
    content: '',
    timestamp: new Date(),
    isStreaming: true  // Mark as streaming
  })

  try {
    // Prepare conversation history
    const conversationMessages = messages.value
      .filter(msg => msg.content && !msg.isStreaming)
      .map(msg => ({
        role: msg.role,
        content: msg.content
      }))

    // Call Edge Function with streaming
    const response = await fetch(
      `${supabase.supabaseUrl}/functions/v1/chat-with-audio`,
      {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${supabase.supabaseKey}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          messages: conversationMessages,
          systemPrompt: systemInstructions.value,
          language: selectedLanguage.value.code,
          modalities: ['text'],  // Text only for streaming
          stream: true  // Enable streaming
        })
      }
    )

    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`)
    }

    // Handle SSE stream
    const reader = response.body?.getReader()
    const decoder = new TextDecoder()
    let fullContent = ''

    if (reader) {
      while (true) {
        const { done, value } = await reader.read()
        
        if (done) break

        const chunk = decoder.decode(value)
        const lines = chunk.split('\n\n')

        for (const line of lines) {
          if (line.startsWith('data: ')) {
            const data = line.slice(6)
            
            if (data === '[DONE]') continue

            try {
              const parsed = JSON.parse(data)
              if (parsed.content) {
                fullContent += parsed.content
                
                // Update the streaming message
                const msgIndex = messages.value.findIndex(m => m.id === assistantMessageId)
                if (msgIndex !== -1) {
                  messages.value[msgIndex].content = fullContent
                }
                
                // Auto-scroll as content arrives
                await scrollToBottom()
              }
            } catch (e) {
              // Skip invalid JSON
            }
          }
        }
      }
    }

    // Mark streaming as complete
    const msgIndex = messages.value.findIndex(m => m.id === assistantMessageId)
    if (msgIndex !== -1) {
      messages.value[msgIndex].isStreaming = false
    }

  } catch (err: any) {
    console.error('AI response error:', err)
    error.value = err.message || 'Failed to get AI response'
    
    // Remove failed streaming message
    const msgIndex = messages.value.findIndex(m => m.id === assistantMessageId)
    if (msgIndex !== -1) {
      messages.value.splice(msgIndex, 1)
    }
  } finally {
    isLoading.value = false
  }
}

// Voice input remains non-streaming (unchanged)
async function getAIResponseWithVoice(voiceInput: { data: string, format: string }) {
  // ... existing non-streaming voice code ...
}
```

---

### **3. Add Streaming Visual Indicator**

Update the message component to show streaming cursor:

```vue
<template>
  <!-- ... existing template ... -->
  
  <div class="message" :class="message.role">
    <div class="message-avatar">
      <i :class="message.role === 'user' ? 'pi pi-user' : 'pi pi-sparkles'"></i>
    </div>
    <div class="message-content">
      <p class="message-text">
        {{ message.content }}
        <!-- Streaming cursor -->
        <span v-if="message.isStreaming" class="streaming-cursor">▊</span>
      </p>
      <span class="message-time">{{ formatTime(message.timestamp) }}</span>
    </div>
  </div>
</template>

<style scoped>
/* Streaming cursor animation */
.streaming-cursor {
  display: inline-block;
  animation: blink 1s step-start infinite;
  margin-left: 2px;
}

@keyframes blink {
  50% {
    opacity: 0;
  }
}
</style>
```

---

## 📊 Performance Comparison

### **Before (Non-Streaming):**
```
User sends → Wait 2-5s → Complete response appears
Time to first byte: 2-5s
Total time: 2-5s
User perception: Slow, waiting
```

### **After (Streaming):**
```
User sends → First words (200-500ms) → Words appear progressively
Time to first token: 200-500ms
Total time: 2-5s (same)
User perception: Fast, engaging
```

---

## 🎯 Hybrid Strategy (Recommended)

### **Text Input → Streaming** ⚡
- Fast perceived response
- Progressive rendering
- Better UX

### **Voice Input → Non-Streaming** 🎵
- Audio playback requires complete response
- Still fast enough (~2-3s)
- Voice UX is different

---

## 🚀 Implementation Steps

1. ✅ Update Edge Function to support `stream` parameter
2. ✅ Implement SSE streaming response
3. ✅ Update frontend to handle streamed text
4. ✅ Add streaming visual indicator (cursor)
5. ✅ Keep voice input non-streaming
6. ✅ Test both flows

---

## 🐛 Considerations

### **Limitations:**
- ❌ Audio responses can't be streamed
- ⚠️ Streaming uses more bandwidth (many small chunks)
- ⚠️ Network interruptions need handling

### **Solutions:**
- ✅ Only stream text-only responses
- ✅ Implement retry logic
- ✅ Fall back to non-streaming on error

---

## 📝 Testing Plan

1. **Text Input:** Should see streaming cursor and progressive text
2. **Voice Input:** Should see complete response after processing
3. **Network Issues:** Should gracefully fall back
4. **Audio Toggle:** Voice output should still work

---

## ✅ Summary

**Approach:**
- ⚡ Stream text-only responses for better UX
- 🎵 Keep voice responses non-streaming (API limitation)
- 🔄 Hybrid solution for best of both worlds

**User Experience:**
- Faster perceived response time
- More engaging interaction
- Progressive content display
- Audio playback when needed

**Implementation:**
- Edge Function: Add SSE streaming support
- Frontend: Handle streamed chunks
- Backward compatible with existing voice flow

