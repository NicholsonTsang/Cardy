# AI Assistant Revamp: Realtime API → Chat Completions API

## Overview
Complete architectural redesign of MobileAIAssistant from OpenAI Realtime API (WebRTC) to Chat Completions API with separate audio processing.

## Key Changes

### 1. **UI/UX Transformation**
- **From**: Simple voice-only modal with status indicators
- **To**: Full chat interface with message history
- **Features**:
  - Message bubbles (user vs assistant)
  - Typing indicators
  - Timestamp display
  - Scrollable chat history
  - Language selector
  - Dual input modes (text/voice toggle)

### 2. **Input Methods**
- **Text Input**: Standard text field with Enter key support
- **Voice Input**: Hold-to-record button
  - Visual recording indicator
  - Automatic transcription via Whisper API
  - Seamless switch between modes

### 3. **Architecture**

#### **Frontend** (`MobileAIAssistant.vue`)
```typescript
// State Management
- messages: Message[]  // Chat history
- inputMode: 'text' | 'voice'
- isRecording: boolean
- isLoading: boolean

// Core Functions
- sendTextMessage()     // Direct text input
- startRecording()      // Capture audio
- stopRecording()       // Process audio
- processVoiceInput()   // Transcribe + get response
- getAIResponse()       // Call Chat Completions
```

#### **Backend Edge Functions**

**1. `transcribe-audio` (New)**
```typescript
// Input: Audio blob (WebM/MP3/WAV)
// Process: Call OpenAI Whisper API
// Output: Transcribed text

POST /transcribe-audio
Body: FormData {
  file: Blob,
  model: 'whisper-1',
  language: string
}
Response: { text: string }
```

**2. `chat-completion` (New)**
```typescript
// Input: Conversation history + system prompt
// Process: Call OpenAI Chat Completions API
// Output: Text response + optional audio

POST /chat-completion
Body: {
  messages: Array<{role, content}>,
  language: string,
  outputMode: 'text' | 'voice'
}
Response: {
  response: string,
  audioUrl?: string  // TTS audio if outputMode='voice'
}
```

**3. `text-to-speech` (New)**
```typescript
// Input: Text to convert
// Process: Call OpenAI TTS API
// Output: Audio URL

POST /text-to-speech
Body: {
  text: string,
  voice: 'alloy' | 'echo' | 'fable' | 'onyx' | 'nova' | 'shimmer',
  language: string
}
Response: { audioUrl: string }
```

### 4. **API Integration**

#### **OpenAI Chat Completions API**
```typescript
POST https://api.openai.com/v1/chat/completions
Headers: {
  "Authorization": "Bearer sk-...",
  "Content-Type": "application/json"
}
Body: {
  model: "gpt-4o",
  messages: [
    { role: "system", content: systemInstructions },
    { role: "user", content: "..." },
    { role: "assistant", content: "..." },
    ...
  ],
  temperature: 0.7,
  max_tokens: 500
}
```

#### **OpenAI Whisper API (Transcription)**
```typescript
POST https://api.openai.com/v1/audio/transcriptions
Headers: {
  "Authorization": "Bearer sk-...",
}
Body: FormData {
  file: audio.webm,
  model: "whisper-1",
  language: "en" // or "yue", "cmn", etc.
}
```

#### **OpenAI TTS API**
```typescript
POST https://api.openai.com/v1/audio/speech
Headers: {
  "Authorization": "Bearer sk-...",
  "Content-Type": "application/json"
}
Body: {
  model: "tts-1",
  voice: "alloy",
  input: "Text to convert to speech"
}
```

### 5. **Data Flow**

#### **Text Input Flow**
```
User types → Send button → 
  Add to messages → 
  Call chat-completion Edge Function → 
  Display response → 
  Auto-scroll
```

#### **Voice Input Flow**
```
User holds button → Start recording → 
  MediaRecorder captures audio → 
  User releases → Stop recording → 
  Convert to Blob → 
  Call transcribe-audio → 
  Get text → Add to messages → 
  Call chat-completion (outputMode='voice') → 
  Get text + audio URL → 
  Display text + Play audio → 
  Auto-scroll
```

### 6. **Message Structure**
```typescript
interface Message {
  id: string              // Unique identifier
  role: 'user' | 'assistant'
  content: string         // Text content
  timestamp: Date
  audioUrl?: string       // Optional audio for voice responses
}
```

### 7. **System Prompt**
```typescript
const systemInstructions = `
You are an AI assistant for "${contentItemName}" 
within the card "${cardName}".

Content Details:
- Item Name: ${contentItemName}
- Description: ${contentItemContent}
- Additional Info: ${aiMetadata}

Guidelines:
- Speak ONLY in ${selectedLanguage}
- Be conversational and friendly
- Focus on this specific item
- Keep responses concise (2-3 sentences for chat)
- Redirect off-topic questions

Special Instructions: ${cardData.ai_prompt}
`
```

### 8. **Environment Variables**
```bash
# Already Existing
OPENAI_API_KEY=sk-...

# Model Configuration
OPENAI_CHAT_MODEL=gpt-4o
OPENAI_WHISPER_MODEL=whisper-1
OPENAI_TTS_MODEL=tts-1
OPENAI_TTS_VOICE=alloy
```

### 9. **Supabase Edge Functions File Structure**
```
supabase/functions/
├── transcribe-audio/
│   └── index.ts         # New: Whisper API integration
├── chat-completion/
│   └── index.ts         # New: Chat Completions API
├── text-to-speech/
│   └── index.ts         # New: TTS API
├── get-openai-ephemeral-token/
│   └── index.ts         # Old: Can be deprecated
├── openai-realtime-proxy/
│   └── index.ts         # Old: Can be deprecated
└── _shared/
    └── cors.ts          # Existing: CORS headers
```

### 10. **Cost Optimization**
- **Chat Completions**: More cost-effective than Realtime API
- **Pay-per-use**: Only charged for actual messages
- **Model flexibility**: Can use gpt-4o-mini for cheaper responses
- **TTS optional**: Only generate audio when voice output is needed

### 11. **Benefits Over Realtime API**
1. ✅ **Persistent chat history** - Users can review past messages
2. ✅ **Dual input modes** - Text and voice, user's choice
3. ✅ **No WebRTC complexity** - Simpler architecture
4. ✅ **Better error handling** - Granular control over each step
5. ✅ **More cost-effective** - Pay only for what you use
6. ✅ **Model flexibility** - Easy to switch models
7. ✅ **Better mobile support** - No WebRTC audio issues
8. ✅ **Offline-friendly** - Can implement message queuing
9. ✅ **Accessibility** - Text mode for users who can't/don't want voice
10. ✅ **Message editing** - Can add edit/retry functionality later

### 12. **Migration Checklist**
- [ ] Create new Edge Functions:
  - [ ] `transcribe-audio`
  - [ ] `chat-completion`
  - [ ] `text-to-speech`
- [ ] Update `MobileAIAssistant.vue` component
- [ ] Remove old dependencies:
  - [ ] WebRTC peer connection code
  - [ ] Realtime API token generation
  - [ ] SDP offer/answer handling
- [ ] Test voice recording on mobile
- [ ] Test audio playback on mobile
- [ ] Test language switching
- [ ] Test error handling
- [ ] Update environment variables
- [ ] Deploy Edge Functions
- [ ] Monitor costs and performance

### 13. **Testing Strategy**
1. **Unit Tests**: Edge Functions independently
2. **Integration Tests**: Full conversation flow
3. **Mobile Tests**: iOS Safari + Android Chrome
4. **Language Tests**: All 5 supported languages
5. **Load Tests**: Multiple concurrent conversations
6. **Error Tests**: Network failures, API errors, permission denials

### 14. **Future Enhancements**
- [ ] Message reactions/feedback
- [ ] Copy message to clipboard
- [ ] Share conversation
- [ ] Voice selection (multiple TTS voices)
- [ ] Conversation export
- [ ] Multi-turn context window management
- [ ] Streaming responses for faster UX
- [ ] Message retry/regenerate
- [ ] Conversation branching
- [ ] Analytics dashboard

---

## Next Steps
1. Create the three new Edge Functions
2. Update the frontend component
3. Test thoroughly on mobile devices
4. Deploy and monitor

