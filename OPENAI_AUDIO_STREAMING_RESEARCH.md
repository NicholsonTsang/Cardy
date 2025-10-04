# OpenAI Audio Streaming - Model Capabilities Research

## 🔍 **Summary**

After researching OpenAI's current offerings, here's what supports audio streaming:

---

## 🎯 **OpenAI Realtime API** ✅ (True Streaming Audio)

### **Model**
- `gpt-4o-realtime-preview` (and newer `gpt-4o-realtime-preview-2025-06-03`)
- Specifically designed for **real-time voice conversations**

### **Key Features**
- ✅ **Bidirectional audio streaming** - Both input and output stream in real-time
- ✅ **WebRTC support** - Low-latency audio via WebRTC protocol
- ✅ **WebSocket support** - Alternative streaming protocol
- ✅ **Function calling** - Can call functions during conversation
- ✅ **Interruption handling** - User can interrupt AI mid-response
- ✅ **Voice Activity Detection (VAD)** - Automatically detects when user starts/stops speaking

### **Streaming Protocol**
```typescript
// WebSocket connection
const ws = new WebSocket('wss://api.openai.com/v1/realtime?model=gpt-4o-realtime-preview')

// Bidirectional streaming
ws.send(JSON.stringify({
  type: 'conversation.item.create',
  item: {
    type: 'message',
    role: 'user',
    content: [{ type: 'input_audio', audio: base64Audio }]
  }
}))

// Receive streaming audio chunks
ws.onmessage = (event) => {
  const response = JSON.parse(event.data)
  if (response.type === 'response.audio.delta') {
    // Play audio chunk immediately
    playAudioChunk(response.delta)
  }
}
```

### **Pricing**
- **Audio Input:** $100.00 per 1M tokens
- **Audio Output:** $200.00 per 1M tokens
- **Text Input:** $5.00 per 1M tokens
- **Text Output:** $20.00 per 1M tokens

**Note:** Significantly more expensive than standard Chat Completions!

---

## 📝 **Chat Completions API (gpt-4o-audio-preview)** ❌ (No Streaming for Audio)

### **Model**
- `gpt-4o-audio-preview` (current implementation in your codebase)
- `gpt-4o-audio-preview-2025-06-03`

### **Capabilities**
- ✅ Text input/output
- ✅ Audio input (voice → text)
- ✅ Audio output (text → voice)
- ❌ **No streaming when audio modality is requested**
- ✅ **Streaming available for text-only mode**

### **Limitation**
When you request audio output (`modalities: ['text', 'audio']`):
- Audio is generated **after** full text completion
- Response returns only when **everything is ready**
- Cannot stream text while audio is being generated

### **Workaround**
```typescript
// Option 1: Text streaming (no audio)
{
  model: 'gpt-4o',
  modalities: ['text'],
  stream: true  // ✅ Works!
}

// Option 2: Audio output (no streaming)
{
  model: 'gpt-4o-audio-preview',
  modalities: ['text', 'audio'],
  stream: false  // ❌ Must be false
}
```

---

## 🎤 **TTS API** ✅ (Output Streaming Only)

### **Endpoint**
```
POST https://api.openai.com/v1/audio/speech
```

### **Model**
- `tts-1` (standard quality, faster)
- `tts-1-hd` (high quality, slower)

### **Streaming Support**
```typescript
const response = await fetch('https://api.openai.com/v1/audio/speech', {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${apiKey}`,
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    model: 'tts-1',
    voice: 'alloy',
    input: 'Your text here',
    response_format: 'mp3'
  })
})

// Streaming audio response
const reader = response.body.getReader()
while (true) {
  const { done, value } = await reader.read()
  if (done) break
  // Play audio chunk
  playAudioChunk(value)
}
```

### **Limitation**
- Only generates audio from **complete text**
- Cannot stream text → audio conversion in real-time
- Must wait for full text before audio generation starts

---

## 📊 **Comparison Table**

| Feature | Realtime API | Chat (audio-preview) | TTS API | Chat (text-only) |
|---------|--------------|---------------------|---------|------------------|
| **Text Streaming** | ✅ | ❌ (with audio) | N/A | ✅ |
| **Audio Streaming** | ✅ | ❌ | ✅ (output only) | N/A |
| **Bidirectional** | ✅ | ❌ | ❌ | N/A |
| **Interruptions** | ✅ | ❌ | ❌ | N/A |
| **WebRTC** | ✅ | ❌ | ❌ | N/A |
| **Cost (Audio)** | 💰💰💰 High | 💰💰 Medium | 💰 Low | N/A |
| **Latency** | ~200ms | 5-10s | 2-5s | 0.5-2s |

---

## 🎯 **Recommendations for Your Use Case**

### **Current Implementation**
You're using `gpt-4o-audio-preview` via Chat Completions API:
- ❌ Cannot stream when audio is requested
- ✅ Can stream text-only responses

### **Option 1: Keep Current + Add Text Streaming** ✅ (Best Balance)

**For Text Input:**
```typescript
// Use standard gpt-4o with streaming
model: 'gpt-4o'
modalities: ['text']
stream: true
```

**For Voice Input:**
```typescript
// Use audio-preview (current)
model: 'gpt-4o-audio-preview'
modalities: ['text', 'audio']
stream: false
```

**Pros:**
- ✅ Immediate text feedback
- ✅ Voice input still works
- ✅ Moderate cost
- ✅ Easy to implement

**Cons:**
- ❌ Voice responses still have delay

---

### **Option 2: Migrate to Realtime API** ⚠️ (True Streaming, But Expensive)

**Implementation:**
```typescript
// WebSocket connection for real-time streaming
const ws = new WebSocket('wss://api.openai.com/v1/realtime')

// Stream audio in both directions
ws.send(audioChunk)  // User's voice
ws.onmessage = (e) => playAudio(e.data)  // AI's voice
```

**Pros:**
- ✅ True real-time streaming
- ✅ Low latency (~200ms)
- ✅ Can interrupt AI
- ✅ Best user experience

**Cons:**
- ❌ **20x more expensive** than Chat Completions
- ❌ Requires WebSocket infrastructure
- ❌ More complex error handling
- ❌ Different API patterns

---

### **Option 3: Hybrid Approach** 🎯 (Recommended)

**Text Mode:** Stream with `gpt-4o`
```typescript
{
  model: 'gpt-4o',
  stream: true,
  modalities: ['text']
}
```

**Voice Mode - Quick Responses:** Use Realtime API
```typescript
// For short Q&A
Use Realtime API (fast, interactive)
```

**Voice Mode - Long Responses:** Use audio-preview
```typescript
// For detailed explanations
Use gpt-4o-audio-preview (cheaper, complete)
```

**Pros:**
- ✅ Best UX for each scenario
- ✅ Cost-optimized
- ✅ Flexible

**Cons:**
- ❌ More complex implementation
- ❌ Two different code paths

---

## 💰 **Cost Analysis**

### **Scenario: Museum Visitor Q&A**
**Assumptions:**
- 1000 questions per day
- Average: 500 tokens response
- 50% text, 50% voice

### **Option 1: Current (audio-preview)**
```
Text: 500 questions × 500 tokens × $0.020/1K = $5.00
Voice: 500 questions × 500 tokens × $0.300/1K = $7.50
Total: $12.50/day = $375/month
```

### **Option 2: Realtime API**
```
Voice: 1000 questions × 500 tokens × $200/1M = $100.00
Total: $100/day = $3,000/month
```

### **Option 3: Hybrid (text stream + audio-preview)**
```
Text: 500 questions × 500 tokens × $0.020/1K = $5.00
Voice: 500 questions × 500 tokens × $0.300/1K = $7.50
Total: $12.50/day = $375/month
```

**Winner:** Option 1 or 3 (same cost, better UX with streaming)

---

## 🚀 **Recommended Implementation**

### **Phase 1: Text Streaming** (Immediate)
1. Create `chat-stream` Edge Function
2. Use `gpt-4o` with `stream: true` for text input
3. Keep `gpt-4o-audio-preview` for voice input
4. Users see instant text feedback for typed questions

### **Phase 2: Evaluate Realtime API** (Future)
1. Implement for specific high-value use cases
2. A/B test vs current approach
3. Monitor cost vs user satisfaction
4. Consider hybrid based on question complexity

---

## 📋 **Technical Specifications**

### **Realtime API WebSocket Events**

**Input Events:**
- `session.update` - Configure session
- `input_audio_buffer.append` - Send audio chunk
- `conversation.item.create` - Add message
- `response.create` - Request AI response

**Output Events:**
- `session.created` - Connection established
- `response.audio.delta` - Audio chunk received
- `response.text.delta` - Text chunk received
- `response.done` - Response complete

### **Audio Format Requirements**

**Realtime API:**
- Format: PCM16, 24kHz, mono
- Encoding: Base64
- Chunk size: ~100ms worth of audio

**Chat Completions (audio-preview):**
- Format: WAV or MP3
- Encoding: Base64
- Full audio only (no chunks)

---

## ✅ **Summary**

### **Models That Support Streaming:**

1. **Realtime API (`gpt-4o-realtime-preview`)** ✅
   - True bidirectional audio streaming
   - Expensive but best UX
   
2. **Chat Completions (`gpt-4o`)** ✅
   - Text-only streaming
   - No audio streaming
   
3. **TTS API** ✅
   - Output audio streaming only
   - Requires complete text input

### **Your Current Model (`gpt-4o-audio-preview`):** ❌
- No streaming support when audio is requested
- Can stream text if audio modality is excluded

---

## 🎯 **Final Recommendation**

**Implement Option 1 (Text Streaming + Keep Audio)**:

1. **Text input** → Use `gpt-4o` with streaming (instant feedback)
2. **Voice input** → Keep `gpt-4o-audio-preview` (current behavior)
3. **Best balance** of cost, complexity, and UX
4. **Easy to implement** - one new Edge Function

**Result:**
- ⚡ Text responses feel instant
- 🔊 Voice responses work as before
- 💰 No additional cost
- 🎉 Huge UX improvement for 50% of interactions

Should I proceed with implementing text streaming? 🚀

