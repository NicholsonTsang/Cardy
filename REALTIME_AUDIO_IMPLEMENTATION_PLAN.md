# Real-Time Audio Chat Implementation Plan

## 🎯 Overview

Implement a third conversation mode using **GPT-4o-mini-realtime-preview** for real-time audio conversations, similar to ChatGPT's voice mode.

## 📊 Three Conversation Modes

| Mode | Technology | Input | Output | Use Case |
|------|-----------|-------|--------|----------|
| **Chat Completion** | Chat Completions API | Text + Voice (transcribed) | Text + TTS | Current default mode |
| **Realtime** | Realtime API + WebRTC | Live Audio Stream | Live Audio Stream | Natural voice conversations |

## 🎨 UI/UX Design (ChatGPT-style)

### Mode Switching
- **Phone Icon** in header (top-right area)
- Toggles between chat completion and realtime modes
- Icon changes: 📞 (chat mode) ↔️ 💬 (realtime mode)

### Realtime Conversation UI

```
┌─────────────────────────────────┐
│ 💬 AI Assistant  │ Ming Vase  │
│                   📞  ×         │
├─────────────────────────────────┤
│                                 │
│         [Connection UI]         │
│                                 │
│    ┌───────────────────────┐   │
│    │                       │   │
│    │   🎤 AI Assistant     │   │
│    │                       │   │
│    │   [Waveform Visual]   │   │
│    │   ▁▂▃▅▇▅▃▂▁▂▃▅▇       │   │
│    │                       │   │
│    │   Status: Listening   │   │
│    │                       │   │
│    └───────────────────────┘   │
│                                 │
│    [Transcript appears here]   │
│                                 │
├─────────────────────────────────┤
│         [  Tap to Talk  ]       │
│         or                      │
│      [ Hold Conversation ]      │
└─────────────────────────────────┘
```

### States & Visual Feedback

1. **Disconnected**
   - Gray circle with microphone icon
   - "Tap to Connect" button
   - Status: "Not connected"

2. **Connecting**
   - Pulsing blue circle
   - "Connecting..." text
   - Loading indicator

3. **Connected - Idle**
   - Steady green circle
   - "Tap to talk" or "Hold to talk continuously"
   - Status: "Ready"

4. **User Speaking**
   - Pulsing blue circle with waveform
   - Visual volume indicator
   - Status: "Listening..."

5. **AI Speaking**
   - Pulsing green circle with waveform
   - AI voice visualization
   - Status: "AI responding..."

6. **Thinking**
   - Animated spinner
   - Status: "Thinking..."

## 🔧 Technical Architecture

### Frontend Components

#### 1. **Mode State Management**
```typescript
type ConversationMode = 'chat-completion' | 'realtime'

const conversationMode = ref<ConversationMode>('chat-completion')
const isRealtimeConnected = ref(false)
const isRealtimeSpeaking = ref(false)
const realtimeStatus = ref<string>('disconnected')
```

#### 2. **WebRTC Connection**
```typescript
const peerConnection = ref<RTCPeerConnection | null>(null)
const dataChannel = ref<RTCDataChannel | null>(null)
const audioElement = ref<HTMLAudioElement | null>(null)
```

#### 3. **Audio Stream Handling**
```typescript
// Get user's microphone
const getUserMedia = async () => {
  return await navigator.mediaDevices.getUserMedia({
    audio: {
      echoCancellation: true,
      noiseSuppression: true,
      autoGainControl: true
    }
  })
}

// Add to peer connection
peerConnection.addTrack(track, stream)
```

### Backend (Edge Function)

#### New Function: `openai-realtime-relay`

**Purpose**: Proxy WebRTC connections between client and OpenAI Realtime API

**Flow**:
```
Client (WebRTC) 
  ↕️
Edge Function (Relay)
  ↕️
OpenAI Realtime API (WebRTC)
```

**Implementation**:
```typescript
// supabase/functions/openai-realtime-relay/index.ts
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'

serve(async (req) => {
  if (req.method === 'POST') {
    // Get ephemeral token
    const token = await getEphemeralToken()
    
    // Relay SDP offer/answer
    const { sdp } = await req.json()
    
    // Forward to OpenAI
    const response = await fetch('https://api.openai.com/v1/realtime', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/sdp'
      },
      body: sdp
    })
    
    return new Response(await response.text(), {
      headers: { 'Content-Type': 'application/sdp' }
    })
  }
})
```

## 🎮 User Interaction Patterns

### Pattern 1: Push-to-Talk (Default)
```
1. User taps "Tap to Talk" button
2. Connection established
3. User speaks
4. User releases button
5. AI processes and responds
6. Cycle repeats
```

### Pattern 2: Continuous Conversation
```
1. User toggles "Hold Conversation" mode
2. Connection stays active
3. Voice activity detection (VAD) triggers:
   - User speaks → AI listens
   - User stops → AI responds
   - AI speaks → User listens
4. Natural turn-taking
```

## 📝 Implementation Checklist

### Phase 1: UI Setup ✅
- [x] Add conversation mode state
- [x] Add phone icon button in header
- [ ] Create realtime conversation UI component
- [ ] Add waveform visualization
- [ ] Add status indicators

### Phase 2: WebRTC Setup
- [ ] Implement getUserMedia for microphone access
- [ ] Create RTCPeerConnection
- [ ] Set up data channel for signaling
- [ ] Handle ICE candidates

### Phase 3: OpenAI Integration
- [ ] Create `openai-realtime-relay` Edge Function
- [ ] Implement SDP offer/answer exchange
- [ ] Handle ephemeral token generation
- [ ] Configure realtime session (model, voice, etc.)

### Phase 4: Audio Handling
- [ ] Stream user audio to peer connection
- [ ] Receive and play AI audio response
- [ ] Implement waveform visualization
- [ ] Add volume level indicators

### Phase 5: State Management
- [ ] Connection lifecycle (connect, disconnect, reconnect)
- [ ] Error handling and recovery
- [ ] Turn-taking logic
- [ ] Transcript display

### Phase 6: UX Polish
- [ ] Smooth animations for state transitions
- [ ] Haptic feedback (mobile)
- [ ] Audio quality indicators
- [ ] Latency display (optional)

## 🎨 Visual Design Specifications

### Colors
- **Disconnected**: `#9ca3af` (gray-400)
- **Connecting**: `#3b82f6` (blue-500) with pulse
- **Connected (Idle)**: `#10b981` (green-500)
- **User Speaking**: `#3b82f6` (blue-500) with pulse
- **AI Speaking**: `#10b981` (green-500) with pulse
- **Error**: `#ef4444` (red-500)

### Animations
- **Pulse**: 1.5s ease-in-out infinite
- **Waveform**: Real-time frequency data visualization
- **Status Change**: 0.3s ease-in-out transition

### Typography
- **Status Text**: 0.875rem, medium weight
- **Transcript**: 0.875rem, regular weight
- **Button Labels**: 0.875rem, semibold

## 🔒 Security Considerations

1. **Ephemeral Tokens**: Generate short-lived tokens for each session
2. **Microphone Permission**: Request only when needed
3. **Secure WebRTC**: Use DTLS-SRTP for encryption
4. **Rate Limiting**: Implement on Edge Function
5. **Session Timeouts**: Auto-disconnect after inactivity

## 📊 Configuration

### Environment Variables

```toml
# supabase/config.toml
[edge_runtime.secrets]
OPENAI_API_KEY = "sk-proj-..."
OPENAI_REALTIME_MODEL = "gpt-4o-mini-realtime-preview"
OPENAI_REALTIME_VOICE = "alloy"
OPENAI_REALTIME_INSTRUCTIONS = "You are a helpful AI assistant..."
```

### Frontend Config
```typescript
const REALTIME_CONFIG = {
  model: 'gpt-4o-mini-realtime-preview',
  voice: 'alloy',
  temperature: 0.8,
  max_tokens: 1000,
  vadThreshold: 0.5, // Voice activity detection
  turnDetection: 'server_vad' // or 'client_vad'
}
```

## 🧪 Testing Strategy

### Unit Tests
- WebRTC connection lifecycle
- Audio stream handling
- State transitions

### Integration Tests
- End-to-end conversation flow
- Mode switching
- Error recovery

### User Testing
- Natural conversation feel
- Latency perception
- Audio quality
- UI intuitiveness

## 📈 Success Metrics

- **Connection Time**: < 2 seconds
- **Latency**: < 500ms (user speaks → AI responds)
- **Audio Quality**: Clear, no distortion
- **Reliability**: > 99% connection success rate
- **User Satisfaction**: Natural conversation feel

## 🚀 Deployment

1. Deploy Edge Function: `npx supabase functions deploy openai-realtime-relay`
2. Set secrets: `./scripts/setup-production-secrets.sh`
3. Test in staging
4. Deploy frontend
5. Monitor metrics

---

**Status**: 🔄 In Progress
**Next**: Implement realtime UI component

