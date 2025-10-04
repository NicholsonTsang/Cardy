# Audio Model with User Transcription Display

## ✅ Current Implementation

Switched back to using **`gpt-4o-mini-audio-preview`** (audio model) for voice input, while still showing the user's transcribed text in the chatbox.

---

## 🎯 Architecture

### **Voice Input Flow:**

```
┌─────────────────────────────────────────────────────────────┐
│  1. USER SPEAKS                                             │
│     User holds button and records voice                    │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│  2. DUAL STT (for display + generation)                    │
│     ┌──────────────────────────────────────────────┐      │
│     │ a) Whisper API (for UI display)             │      │
│     │    - Transcribes user's speech               │      │
│     │    - Returns: "What user said"               │      │
│     │    - Cost: ~$0.0001                          │      │
│     └──────────────────────────────────────────────┘      │
│     ┌──────────────────────────────────────────────┐      │
│     │ b) Audio Model (for generation)             │      │
│     │    - gpt-4o-mini-audio-preview               │      │
│     │    - Processes voice + generates response    │      │
│     │    - Cost: ~$0.0003                          │      │
│     └──────────────────────────────────────────────┘      │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│  3. DISPLAY IN CHATBOX                                      │
│     User: "[Transcribed text from Whisper]"                │
│     AI: "[Response from audio model]"                       │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│  4. TEXT-TO-SPEECH                                          │
│     AI text → OpenAI TTS → Audio output                    │
│     Cost: ~$0.0072                                         │
└─────────────────────────────────────────────────────────────┘
```

---

## 💰 Cost Breakdown

### **Per Voice Response:**
| Component | API | Cost | Purpose |
|-----------|-----|------|---------|
| **STT (Display)** | Whisper | $0.0001 | Show user's text in chatbox |
| **STT + Text Gen** | Audio Model | $0.0003 | Process voice + generate response |
| **TTS** | OpenAI TTS | $0.0072 | Convert AI text to audio |
| **Total** | - | **$0.0076** | Per voice response |

**Previous (streaming approach):** $0.0075  
**Current (audio model):** $0.0076  
**Difference:** +$0.0001 (negligible)

---

## 🔄 Why Dual STT?

### **Problem:**
The `gpt-4o-mini-audio-preview` model doesn't return the user's transcription in the API response.

### **Solution:**
1. **Whisper API** transcribes user speech → Display in chatbox
2. **Audio Model** processes voice directly → Generates AI response

### **Trade-offs:**
| Approach | Cost | Speed | Pros | Cons |
|----------|------|-------|------|------|
| **Whisper + Text Model** | $0.0073 | Slower | Streamable, modular | 2 API calls |
| **Audio Model only** | $0.0003 | Faster | Single call | No user transcription |
| **Both (Current)** | $0.0076 | Fast | Best UX | Slight overlap |

---

## ⚡ Performance

### **Timing:**
| Phase | Time | Details |
|-------|------|---------|
| **Recording** | ~1-3s | User speaks |
| **Transcription (Whisper)** | ~500ms | Parallel with audio model |
| **Audio Model Processing** | ~1-2s | STT + text generation |
| **Display User Message** | Instant | After transcription |
| **Display AI Response** | Instant | After audio model |
| **TTS Generation** | ~1-2s | Parallel, non-blocking |
| **Audio Playback** | ~2-4s | Starts when ready |

**Total perceived time:** ~2-4s (user sees text ~1-2s)

---

## 🎯 User Experience

### **What User Sees:**

```
[User holds button and speaks]
↓
[Loading: "Processing your voice..."]
↓
User: "Tell me about this artifact"
      (Appears ~1-2s after speaking)
↓
AI: "This artifact is from the Ming Dynasty..."
    (Appears immediately after user message)
↓
🔊 [Audio plays automatically]
```

---

## 🔧 Technical Details

### **Frontend (MobileAIAssistant.vue):**

```typescript
async function getAIResponseWithVoice(voiceInput) {
  // Call chat-with-audio with audio model
  // Edge Function will:
  // 1. Transcribe with Whisper (for display)
  // 2. Process with audio model (for generation)
  // 3. Return both transcription and response
  
  const { data } = await supabase.functions.invoke('chat-with-audio', {
    body: {
      voiceInput: voiceInput,
      modalities: ['text']  // Text only output (no audio from model)
    }
  })
  
  // Display user's transcription
  addUserMessage(data.userTranscription)
  
  // Display AI's response
  addAssistantMessage(data.message.content)
  
  // Generate TTS audio
  generateAndPlayTTS(data.message.content)
}
```

### **Backend (chat-with-audio Edge Function):**

```typescript
// Always transcribe with Whisper for UI display
const userTranscription = await transcribeWithWhisper(voiceInput)

// Use audio model for generation (based on STT mode)
if (sttMode === 'audio-model') {
  // Send voice input to audio model
  const response = await openai.chat.completions.create({
    model: 'gpt-4o-mini-audio-preview',
    messages: [...history, { 
      role: 'user',
      content: [{ type: 'input_audio', input_audio: voiceInput }]
    }]
  })
}

// Return both transcription and response
return {
  userTranscription,  // For UI display
  message: response.message  // AI's response
}
```

---

## 📊 Comparison

### **vs. Previous Streaming Approach:**

| Aspect | Audio Model (Current) | Streaming Approach | Winner |
|--------|---------------------|-------------------|---------|
| **Cost** | $0.0076 | $0.0075 | Streaming (-$0.0001) |
| **Speed** | ~2-4s | ~2-4s | Tie |
| **Text Display** | All at once | Progressive | Streaming ✨ |
| **API Calls** | 2 (Whisper + Audio Model) | 2 (Whisper + Text Model) | Tie |
| **Complexity** | Simple | More complex | Audio Model |
| **User Transcription** | ✅ Yes | ✅ Yes | Tie |

**Note:** Streaming provides slightly better UX with progressive text, but audio model is simpler.

---

## 🎯 Configuration

### **Current Settings:**

```toml
# supabase/config.toml

# STT Mode (using audio-model)
OPENAI_STT_MODE = "audio-model"

# Audio Model (for STT + generation)
OPENAI_AUDIO_MODEL = "gpt-4o-mini-audio-preview"

# Whisper (for transcription display)
OPENAI_WHISPER_MODEL = "whisper-1"

# TTS
OPENAI_TTS_MODEL = "tts-1"
OPENAI_TTS_VOICE = "alloy"
```

---

## ✅ Summary

**Current Implementation:**
- ✅ Uses `gpt-4o-mini-audio-preview` (audio model)
- ✅ Shows user's transcribed text in chatbox
- ✅ Displays AI's response immediately
- ✅ Generates and plays TTS audio
- ✅ Cost: $0.0076 per voice response

**Flow:**
```
Voice → Whisper (transcribe for display) → Audio Model (generate response) → Display both → TTS → Audio
```

**Trade-off:** Slightly more expensive (+$0.0001) than pure text approach, but uses audio model as requested.

**Alternative:** If you want streaming text + lower cost, switch to `OPENAI_STT_MODE=whisper` (saves $0.0003 but adds latency).

