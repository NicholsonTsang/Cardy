# AI Assistant Revamp: Using Native Audio in Chat Completions API

## ✅ Key Discovery
The **Chat Completions API with `gpt-4o-audio-preview` model** natively supports:
- ✅ **Audio input** (direct speech-to-text)
- ✅ **Audio output** (direct text-to-speech)
- ✅ **Text input/output** (standard chat)
- ✅ **Mixed modalities** (any combination)

## Simplified Architecture

### **Single Edge Function Needed**: `chat-with-audio`

```typescript
POST /chat-with-audio
Body: {
  messages: [
    { role: "system", content: "..." },
    { role: "user", content: "...", audio?: base64 },  // Can send text OR audio
    { role: "assistant", content: "..." }
  ],
  modalities: ["text", "audio"],  // Request both text and audio response
  audio: {
    voice: "alloy",
    format: "wav"
  }
}

Response: {
  message: {
    role: "assistant",
    content: "text response",
    audio: "base64_audio_data"  // Direct audio response!
  }
}
```

### **No Separate APIs Needed!**
- ❌ No separate Whisper API call
- ❌ No separate TTS API call  
- ✅ Single unified endpoint handles everything

## Updated Implementation

### **1. Frontend Flow**

#### **Text Input**
```typescript
sendTextMessage() {
  const message = { role: "user", content: textInput }
  await chatWithAudio(messages, modalities: ["text"])
}
```

#### **Voice Input**
```typescript
async sendVoiceMessage(audioBlob: Blob) {
  // Convert blob to base64
  const audioBase64 = await blobToBase64(audioBlob)
  
  const message = { 
    role: "user", 
    audio: { data: audioBase64, format: "wav" }
  }
  
  // Request BOTH text (for display) and audio (for playback)
  await chatWithAudio(messages, modalities: ["text", "audio"])
}
```

### **2. Edge Function Implementation**

**File**: `supabase/functions/chat-with-audio/index.ts`

```typescript
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { corsHeaders } from '../_shared/cors.ts'

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { messages, modalities, systemPrompt, language } = await req.json()

    // Build messages with system prompt
    const fullMessages = [
      { role: 'system', content: systemPrompt },
      ...messages
    ]

    // Call OpenAI Chat Completions with audio support
    const response = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${Deno.env.get('OPENAI_API_KEY')}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: 'gpt-4o-audio-preview',
        modalities: modalities || ['text', 'audio'],
        audio: { voice: 'alloy', format: 'wav' },
        messages: fullMessages,
        max_tokens: 500,
        temperature: 0.7
      })
    })

    const data = await response.json()
    
    if (!response.ok) {
      throw new Error(data.error?.message || 'OpenAI API error')
    }

    return new Response(
      JSON.stringify({
        message: data.choices[0].message,
        usage: data.usage
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('Chat error:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
```

### **3. Frontend Component Updates**

**Key Changes in `MobileAIAssistant.vue`:**

```typescript
// Send voice message
async function sendVoiceMessage(audioBlob: Blob) {
  const audioBase64 = await blobToBase64(audioBlob)
  
  const userMessage = {
    id: Date.now().toString(),
    role: 'user',
    audio: { data: audioBase64, format: 'wav' },
    timestamp: new Date()
  }
  
  messages.value.push(userMessage)
  isLoading.value = true
  
  try {
    const { data } = await supabase.functions.invoke('chat-with-audio', {
      body: {
        messages: messages.value,
        modalities: ['text', 'audio'],  // Get both!
        systemPrompt: systemInstructions.value,
        language: selectedLanguage.value.code
      }
    })
    
    // Add assistant message with BOTH text and audio
    messages.value.push({
      id: Date.now().toString(),
      role: 'assistant',
      content: data.message.content,  // Text for display
      audio: data.message.audio,      // Audio for playback
      timestamp: new Date()
    })
    
    // Play audio response
    if (data.message.audio) {
      await playAudioFromBase64(data.message.audio.data)
    }
    
  } catch (err) {
    error.value = err.message
  } finally {
    isLoading.value = false
  }
}

// Helper: Convert Blob to Base64
async function blobToBase64(blob: Blob): Promise<string> {
  return new Promise((resolve, reject) => {
    const reader = new FileReader()
    reader.onloadend = () => {
      const base64 = reader.result as string
      // Remove data URL prefix
      resolve(base64.split(',')[1])
    }
    reader.onerror = reject
    reader.readAsDataURL(blob)
  })
}

// Helper: Play audio from base64
async function playAudioFromBase64(base64Audio: string) {
  const audioBlob = base64ToBlob(base64Audio, 'audio/wav')
  const audioUrl = URL.createObjectURL(audioBlob)
  
  if (audioPlayer.value) {
    audioPlayer.value.src = audioUrl
    await audioPlayer.value.play()
  }
}

// Helper: Convert base64 to Blob
function base64ToBlob(base64: string, mimeType: string): Blob {
  const byteCharacters = atob(base64)
  const byteNumbers = new Array(byteCharacters.length)
  for (let i = 0; i < byteCharacters.length; i++) {
    byteNumbers[i] = byteCharacters.charCodeAt(i)
  }
  const byteArray = new Uint8Array(byteNumbers)
  return new Blob([byteArray], { type: mimeType })
}
```

### **4. Message Structure Update**

```typescript
interface Message {
  id: string
  role: 'user' | 'assistant'
  content?: string           // Text content (for display)
  audio?: {                  // Audio content (native format)
    data: string             // Base64 encoded
    format: 'wav' | 'mp3'
    transcript?: string      // Optional transcription from API
  }
  timestamp: Date
}
```

### **5. API Parameters**

According to your provided docs, here are the key parameters:

```typescript
{
  model: "gpt-4o-audio-preview",
  
  // Modalities - what types of output you want
  modalities: ["text", "audio"],  // Can request both!
  
  // Audio configuration
  audio: {
    voice: "alloy" | "echo" | "fable" | "onyx" | "nova" | "shimmer",
    format: "wav" | "mp3" | "flac" | "opus" | "pcm16"
  },
  
  // Messages can include audio input
  messages: [
    {
      role: "user",
      content: [
        { type: "text", text: "..." },
        { type: "input_audio", input_audio: { data: "base64", format: "wav" } }
      ]
    }
  ]
}
```

### **6. Benefits of This Approach**

✅ **Single API call** - No separate Whisper/TTS calls
✅ **Lower latency** - Integrated processing
✅ **Better quality** - Optimized for voice conversations
✅ **Simpler code** - One Edge Function instead of three
✅ **Cost effective** - Unified billing
✅ **Conversation continuity** - Audio context maintained
✅ **Native transcription** - API returns text transcription of audio input
✅ **Model consistency** - Same model handles understanding and generation

### **7. Updated Environment Variables**

```bash
# OpenAI
OPENAI_API_KEY=sk-...
OPENAI_AUDIO_MODEL=gpt-4o-audio-preview

# Audio Configuration
OPENAI_TTS_VOICE=alloy  # alloy, echo, fable, onyx, nova, shimmer
OPENAI_AUDIO_FORMAT=wav
```

### **8. Implementation Checklist**

- [ ] Create single `chat-with-audio` Edge Function
- [ ] Update `MobileAIAssistant.vue`:
  - [ ] Add base64 conversion utilities
  - [ ] Update `sendVoiceMessage()` to send audio in message
  - [ ] Handle audio response from API
  - [ ] Display text transcription for audio messages
- [ ] Test voice recording → base64 conversion
- [ ] Test API with audio input
- [ ] Test audio playback from response
- [ ] Test text-only mode still works
- [ ] Deploy and monitor

### **9. Example API Request/Response**

**Request:**
```json
{
  "model": "gpt-4o-audio-preview",
  "modalities": ["text", "audio"],
  "audio": { "voice": "alloy", "format": "wav" },
  "messages": [
    {
      "role": "system",
      "content": "You are a helpful museum guide."
    },
    {
      "role": "user",
      "content": [
        {
          "type": "input_audio",
          "input_audio": {
            "data": "base64_encoded_audio...",
            "format": "wav"
          }
        }
      ]
    }
  ]
}
```

**Response:**
```json
{
  "id": "chatcmpl-123",
  "choices": [{
    "message": {
      "role": "assistant",
      "content": "This artifact dates back to...",  // Text transcription
      "audio": {
        "id": "audio_123",
        "data": "base64_encoded_response_audio...",
        "transcript": "This artifact dates back to..."  // Same as content
      }
    }
  }],
  "usage": {
    "prompt_tokens": 150,
    "completion_tokens": 75,
    "total_tokens": 225
  }
}
```

---

## Conclusion

**This is MUCH simpler than the original plan!**

Instead of:
- ❌ 3 separate Edge Functions
- ❌ 3 separate API calls per voice interaction
- ❌ Complex audio file management

We only need:
- ✅ 1 Edge Function
- ✅ 1 API call per interaction
- ✅ Direct base64 audio handling

The native audio support in `gpt-4o-audio-preview` makes this a clean, unified solution! 🎉

