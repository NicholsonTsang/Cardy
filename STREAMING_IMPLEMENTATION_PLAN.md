# AI Assistant Streaming Implementation Plan

## 🎯 **Goal**

Reduce wait time by streaming text responses, showing words as they're generated instead of waiting for the complete response.

---

## 📊 **Current vs Proposed**

### **Current Behavior**
```
User asks question
↓
[Wait 5-10 seconds] ⏳
↓
Complete text appears
↓
Audio plays
```

### **Proposed Behavior**
```
User asks question
↓
[Text starts appearing immediately] ⚡
"Babylon was"
"Babylon was one of"
"Babylon was one of the greatest"
↓
[Text continues streaming]
↓
[Complete text shown]
↓
[Audio plays if requested]
```

---

## 🔧 **Implementation Approach**

### **Option 1: Dual-Mode Streaming** (Recommended)

**Text Mode (Streaming):**
- User types message
- Request text-only, enable streaming
- Show text as it generates
- NO audio

**Voice Mode (Non-Streaming):**
- User speaks
- Request text + audio
- Wait for complete response
- Show text + play audio

### **Option 2: Text Stream + Post-Audio**

- Always stream text first
- If audio requested, make second API call for TTS
- More complex, higher cost

---

## 📝 **Implementation Details**

### **1. Backend: Add Streaming Edge Function**

**New file:** `supabase/functions/chat-with-audio-stream/index.ts`

```typescript
serve(async (req) => {
  const { messages, systemPrompt, language } = await req.json()

  const openaiResponse = await fetch('https://api.openai.com/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${openaiApiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model: 'gpt-4o',  // Use standard model for text-only
      messages: fullMessages,
      stream: true,  // Enable streaming
      max_tokens: parseInt(Deno.env.get('OPENAI_MAX_TOKENS') || '3500'),
      temperature: 0.7
    })
  })

  // Return streaming response
  return new Response(openaiResponse.body, {
    headers: {
      ...corsHeaders,
      'Content-Type': 'text/event-stream',
      'Cache-Control': 'no-cache',
      'Connection': 'keep-alive'
    }
  })
})
```

### **2. Frontend: Handle Streaming**

**Update `MobileAIAssistant.vue`:**

```typescript
async function getAIResponseStreaming(userInput: string) {
  isLoading.value = true
  error.value = null

  // Add user message
  addUserMessage(userInput)

  // Create empty assistant message
  const assistantMessageId = Date.now().toString()
  messages.value.push({
    id: assistantMessageId,
    role: 'assistant',
    content: '',
    timestamp: new Date()
  })

  try {
    // Call streaming endpoint
    const response = await fetch(`${supabaseUrl}/functions/v1/chat-with-audio-stream`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${supabaseAnonKey}`
      },
      body: JSON.stringify({
        messages: conversationMessages,
        systemPrompt: systemInstructions.value,
        language: selectedLanguage.value.code
      })
    })

    const reader = response.body?.getReader()
    const decoder = new TextDecoder()

    let accumulatedText = ''

    while (true) {
      const { done, value } = await reader!.read()
      if (done) break

      const chunk = decoder.decode(value)
      const lines = chunk.split('\n')

      for (const line of lines) {
        if (line.startsWith('data: ')) {
          const data = line.slice(6)
          if (data === '[DONE]') continue

          try {
            const parsed = JSON.parse(data)
            const content = parsed.choices[0]?.delta?.content
            
            if (content) {
              accumulatedText += content
              
              // Update message in real-time
              const msgIndex = messages.value.findIndex(m => m.id === assistantMessageId)
              if (msgIndex !== -1) {
                messages.value[msgIndex].content = accumulatedText
              }
              
              scrollToBottom()
            }
          } catch (e) {
            // Skip invalid JSON
          }
        }
      }
    }

  } catch (err: any) {
    console.error('Streaming error:', err)
    error.value = err.message
  } finally {
    isLoading.value = false
  }
}
```

### **3. Conditional Routing**

```typescript
async function sendTextMessage() {
  if (!textInput.value.trim()) return

  const message = textInput.value.trim()
  textInput.value = ''

  // Use streaming for text input
  await getAIResponseStreaming(message)
}

async function sendVoiceMessage() {
  // Use non-streaming for voice (needs audio output)
  await getAIResponseWithVoice(voiceInput)
}
```

---

## ⚡ **Performance Comparison**

### **Without Streaming (Current)**
```
Time to first text:     5-10 seconds
Time to complete text:  5-10 seconds
User waiting:          ████████████████████ (entire time)
```

### **With Streaming (Proposed)**
```
Time to first text:     0.5-1 second  ⚡
Time to complete text:  5-10 seconds
User waiting:          ██ (much less!)
User engagement:       ████████████████████ (reading as it types)
```

**Perceived performance improvement: 80-90%!**

---

## 💰 **Cost Impact**

### **No Additional Cost**
- Streaming uses the same tokens
- Same API pricing
- Just different delivery method

**Benefit:** Better UX at no extra cost!

---

## 🎤 **Audio Handling**

### **Text Mode**
```
[Streaming text] ⚡
No audio needed
Fast and responsive
```

### **Voice Mode**
```
User speaks → Transcribe
↓
[Wait for complete response] ⏳
↓
Show text + Play audio 🔊
```

**Trade-off:** Voice mode still needs to wait for audio generation, but text mode is instant!

---

## 🎨 **UI Updates**

### **Streaming Indicator**

```vue
<div class="message assistant streaming">
  <div class="message-content">
    {{ messageContent }}
    <span v-if="isStreaming" class="cursor-blink">|</span>
  </div>
</div>
```

```css
.cursor-blink {
  animation: blink 1s infinite;
}

@keyframes blink {
  0%, 100% { opacity: 1; }
  50% { opacity: 0; }
}
```

---

## 🚀 **Rollout Plan**

### **Phase 1: Text Streaming** ✅ (Recommended for immediate implementation)
1. Create `chat-with-audio-stream` Edge Function
2. Update frontend to handle Server-Sent Events (SSE)
3. Add conditional routing (text → stream, voice → non-stream)
4. Deploy and test

### **Phase 2: Enhanced Voice UX** (Future)
1. Show transcription of user's voice input (using Whisper API)
2. Stream AI's text response
3. Generate audio in background
4. Play audio when ready

---

## 🎯 **Alternative: Simplified Streaming**

If you want to keep it simple and implement streaming faster:

### **Text-Only Streaming (No Audio)**

```typescript
// Simple approach: Disable audio for text mode
async function sendTextMessage() {
  // Stream text-only, no audio
  await getAIResponseStreaming(message, audioEnabled: false)
}

// User can toggle audio on/off
const audioOutputEnabled = ref(true)
```

**Pros:**
- ✅ Much simpler to implement
- ✅ Instant text feedback
- ✅ Users can choose audio on/off

**Cons:**
- ❌ Voice input still requires waiting for audio

---

## 📋 **Files to Create/Modify**

### **New Files**
1. `supabase/functions/chat-with-audio-stream/index.ts` - Streaming Edge Function
2. `STREAMING_IMPLEMENTATION.md` - Documentation

### **Modified Files**
1. `src/views/MobileClient/components/MobileAIAssistant.vue` - Add streaming handler
2. `src/stores/publicCard.ts` - Add streaming function (if needed)

---

## 🧪 **Testing Checklist**

- [ ] Text message streams correctly
- [ ] Voice message still works (non-streaming)
- [ ] Streaming stops cleanly
- [ ] Error handling works
- [ ] Network interruption handled
- [ ] Multiple rapid messages handled
- [ ] Auto-scroll works during streaming
- [ ] Mobile device tested
- [ ] Different network speeds tested

---

## ✅ **Recommendation**

**Implement Phase 1 (Text Streaming) now:**

1. **Quick win:** Massive UX improvement
2. **Low complexity:** Well-established pattern
3. **No extra cost:** Same API usage
4. **Backwards compatible:** Voice mode unchanged

**Expected result:**
- Text responses feel instant ⚡
- Voice responses work as before
- Users much happier with perceived speed!

---

## 🎬 **Next Steps**

Would you like me to:
1. ✅ **Implement text streaming** (Phase 1) - Recommended!
2. Plan Phase 2 (enhanced voice UX)
3. Create a simpler text-only streaming version
4. Something else?

Let me know and I'll implement it! 🚀

