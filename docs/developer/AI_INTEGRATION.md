# AI Integration Guide

This document covers the AI-powered features: chat, text-to-speech, and real-time voice conversations.

## Overview

FunTell uses OpenAI for AI features:

| Feature | Model | Purpose |
|---------|-------|---------|
| Chat | GPT-4o-mini | Text conversations with visitors |
| TTS | tts-1 | Convert AI responses to audio |
| Realtime | gpt-realtime-mini | Live voice conversations |

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     Mobile Client                                │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐  │
│  │  Text Chat   │  │    TTS       │  │   Realtime Voice     │  │
│  │  Component   │  │   Playback   │  │   (WebRTC)           │  │
│  └──────┬───────┘  └──────┬───────┘  └──────────┬───────────┘  │
└─────────┼─────────────────┼─────────────────────┼──────────────┘
          │                 │                     │
          ▼                 ▼                     ▼
┌─────────────────────────────────────────────────────────────────┐
│                     Backend API                                  │
│  /api/ai/chat/stream    /api/ai/generate-tts   /api/ai/realtime │
└─────────────────────────────────────────────────────────────────┘
          │                 │                     │
          ▼                 ▼                     ▼
┌─────────────────────────────────────────────────────────────────┐
│                       OpenAI API                                 │
│  Chat Completions API    Audio Speech API     Realtime API      │
└─────────────────────────────────────────────────────────────────┘
```

## AI Assistants

Each project can have two AI assistants:

| Assistant | Trigger | Context |
|-----------|---------|---------|
| **General** | Overview page, floating button | Card-level knowledge |
| **Item** | Content detail page | Item-specific knowledge |

### Configuration (per Card)

Stored in `cards` table:

| Field | Max Length | Purpose |
|-------|------------|---------|
| `ai_instruction` | 100 words | AI role, personality, restrictions |
| `ai_knowledge_base` | 2000 words | Domain knowledge, facts |
| `ai_welcome_general` | — | Welcome message for General assistant |
| `ai_welcome_item` | — | Welcome for Item assistant (`{name}` placeholder) |

### Example Configuration

```
AI Instruction:
You are a friendly museum guide for the Natural History Museum.
Speak in a conversational tone. Focus on facts about exhibits.
Never discuss topics outside the museum.

AI Knowledge Base:
The Natural History Museum was founded in 1869...
Our dinosaur collection includes a T-Rex skeleton from Montana...
Opening hours: 9am-5pm daily, closed Mondays...
```

## Chat Streaming

### Endpoint

`POST /api/ai/chat/stream`

### Request

```json
{
  "messages": [
    { "role": "user", "content": "Tell me about the T-Rex" }
  ],
  "systemPrompt": "You are a museum guide...",
  "language": "en"
}
```

### Response (SSE Stream)

```
data: {"content": "The"}
data: {"content": " T-Rex"}
data: {"content": " skeleton"}
data: {"content": " in our"}
data: {"content": " collection..."}
data: [DONE]
```

### Backend Implementation

```typescript
// ai.routes.ts
router.post('/chat/stream', optionalAuth, async (req, res) => {
  // Set SSE headers
  res.setHeader('Content-Type', 'text/event-stream')
  res.setHeader('Cache-Control', 'no-cache')
  res.setHeader('Connection', 'keep-alive')

  // Build messages with system prompt
  const fullMessages = [
    { role: 'system', content: systemPrompt },
    ...validMessages
  ]

  // Stream from OpenAI
  const response = await fetch('https://api.openai.com/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${OPENAI_API_KEY}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model: 'gpt-4o-mini',
      messages: fullMessages,
      max_tokens: 3500,
      stream: true
    })
  })

  // Forward chunks to client
  const reader = response.body.getReader()
  while (true) {
    const { done, value } = await reader.read()
    if (done) break
    // Parse and forward content chunks
    res.write(`data: ${JSON.stringify({ content })}\n\n`)
  }
  res.write('data: [DONE]\n\n')
  res.end()
})
```

### Frontend Consumption

```typescript
// In component
const response = await fetch(`${backendUrl}/api/ai/chat/stream`, {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ messages, systemPrompt })
})

const reader = response.body.getReader()
const decoder = new TextDecoder()

while (true) {
  const { done, value } = await reader.read()
  if (done) break

  const chunk = decoder.decode(value)
  const lines = chunk.split('\n')

  for (const line of lines) {
    if (line.startsWith('data: ') && line !== 'data: [DONE]') {
      const { content } = JSON.parse(line.slice(6))
      // Append to displayed message
      displayedMessage += content
    }
  }
}
```

## Text-to-Speech

### Endpoint

`POST /api/ai/generate-tts`

### Request

```json
{
  "text": "Welcome to the Natural History Museum!",
  "voice": "alloy",
  "language": "en"
}
```

### Available Voices

| Voice | Character |
|-------|-----------|
| `alloy` | Neutral, balanced |
| `echo` | Warm, conversational |
| `fable` | Expressive, narrative |
| `onyx` | Deep, authoritative |
| `nova` | Friendly, upbeat |
| `shimmer` | Soft, gentle |

### Response

Binary audio data (MP3 or WAV based on config).

### Frontend Usage

```typescript
const response = await fetch(`${backendUrl}/api/ai/generate-tts`, {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ text, voice: 'alloy' })
})

const audioBlob = await response.blob()
const audioUrl = URL.createObjectURL(audioBlob)
const audio = new Audio(audioUrl)
audio.play()
```

## Realtime Voice (WebRTC)

### Overview

Real-time voice conversations use OpenAI's Realtime API with WebRTC for low-latency bidirectional audio.

### Flow

1. Frontend requests ephemeral token from backend
2. Backend generates token via OpenAI Realtime API
3. Frontend establishes WebRTC connection directly with OpenAI
4. Audio streams bidirectionally (user ↔ OpenAI)

### Token Endpoint

`POST /api/ai/realtime-token`

### Request

```json
{
  "sessionConfig": {
    "voice": "alloy"
  }
}
```

### Response

```json
{
  "success": true,
  "client_secret": "eph_abc123...",
  "expires_at": 1704067200
}
```

### Backend Implementation

```typescript
router.post('/realtime-token', optionalAuth, async (req, res) => {
  const { sessionConfig } = req.body

  const response = await fetch('https://api.openai.com/v1/realtime/sessions', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${OPENAI_API_KEY}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model: 'gpt-realtime-mini-2025-12-15',
      voice: sessionConfig?.voice || 'alloy',
    }),
  })

  const data = await response.json()

  return res.json({
    success: true,
    client_secret: data.client_secret.value,
    expires_at: data.client_secret.expires_at,
  })
})
```

### Frontend WebRTC Setup

```typescript
// 1. Get ephemeral token
const { client_secret } = await fetch('/api/ai/realtime-token', {
  method: 'POST',
  body: JSON.stringify({ sessionConfig: { voice: 'alloy' } })
}).then(r => r.json())

// 2. Create peer connection
const pc = new RTCPeerConnection()

// 3. Add local audio track
const stream = await navigator.mediaDevices.getUserMedia({ audio: true })
stream.getTracks().forEach(track => pc.addTrack(track, stream))

// 4. Create and set local offer
const offer = await pc.createOffer()
await pc.setLocalDescription(offer)

// 5. Exchange SDP with OpenAI
const response = await fetch('https://api.openai.com/v1/realtime?model=gpt-realtime-mini', {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${client_secret}`,
    'Content-Type': 'application/sdp'
  },
  body: offer.sdp
})

// 6. Set remote description
const answer = await response.text()
await pc.setRemoteDescription({ type: 'answer', sdp: answer })

// 7. Handle incoming audio
pc.ontrack = (event) => {
  const audioElement = new Audio()
  audioElement.srcObject = event.streams[0]
  audioElement.play()
}
```

## Environment Variables

```env
# OpenAI API
OPENAI_API_KEY=sk-...

# Chat model
OPENAI_TEXT_MODEL=gpt-4o-mini
OPENAI_MAX_TOKENS=3500

# TTS model
OPENAI_TTS_MODEL=tts-1
OPENAI_TTS_VOICE=alloy
OPENAI_AUDIO_FORMAT=wav

# Realtime model
OPENAI_REALTIME_MODEL=gpt-realtime-mini-2025-12-15
```

## Cost Considerations

### Per-Request Costs (Approximate)

| Feature | Cost |
|---------|------|
| Chat (GPT-4o-mini) | ~$0.001-0.005 per conversation |
| TTS | ~$0.015 per 1,000 characters |
| Realtime | ~$0.06 per minute |

### Session Billing

AI features affect session billing:

- **AI-enabled project**: $0.04-0.05 per session
- **Non-AI project**: $0.02-0.025 per session

The `conversation_ai_enabled` flag on cards determines which rate applies.

## Performance Optimizations (v2.0.0)

The AI system has been optimized to reduce costs and improve performance:

### Prompt Caching

**How it works:**
- OpenAI automatically caches static system prompts
- First message pays full input token cost
- Subsequent messages get ~50% discount on cached prompt tokens

**Implementation:**
- Backend structures messages with system prompt first
- Frontend prevents unnecessary prompt rebuilding
- Prompts only regenerate when data actually changes

**Cost Impact:**
```
10,000 conversations/month (5 messages each):
- Without caching: $3.95/month in prompt tokens
- With caching:    $2.35/month (40% savings)
```

### Prompt Versioning

All system prompts include version tracking:

```
[v2.0.0] # ROLE
You are the personal AI guide...
```

**Benefits:**
- Easier debugging of AI behavior changes
- A/B testing capability
- Clear audit trail in logs

### Welcome Message Truncation

Custom welcome messages are automatically truncated in Realtime mode:

```typescript
// Prevents 30+ second voice greetings
const MAX_WELCOME_LENGTH = 200 // ~15 seconds spoken
if (customWelcome.length > MAX_WELCOME_LENGTH) {
  customWelcome = customWelcome.substring(0, 200) + '...'
}
```

### Frontend Optimization

System prompts use selective rebuilding:

```typescript
// ❌ Before: Rebuilt on every render
const prompt = computed(() => buildPrompt({...}))

// ✅ After: Only rebuilds when dependencies change
const prompt = ref('')
watch([language, cardData, instructions], () => {
  prompt.value = buildPrompt({...})
})
```

**Impact:** ~90% reduction in prompt rebuilds, ~10% CPU savings

## Error Handling

### Common Errors

| Error | Cause | Solution |
|-------|-------|----------|
| 401 | Invalid API key | Check `OPENAI_API_KEY` |
| 429 | Rate limited | Implement backoff, upgrade plan |
| 500 | OpenAI service error | Retry with exponential backoff |

### Frontend Error Handling

```typescript
try {
  const response = await fetch('/api/ai/chat/stream', { ... })

  if (!response.ok) {
    if (response.status === 429) {
      showToast('Too many requests. Please wait.')
    } else {
      showToast('AI service unavailable. Please try again.')
    }
    return
  }

  // Process stream...
} catch (error) {
  showToast('Network error. Check your connection.')
}
```

## Translations in AI Context

AI responses respect the user's language preference:

1. System prompt includes language instruction
2. Knowledge base can have translations in `cards.translations` JSONB
3. AI responds in the requested language

```typescript
const systemPrompt = `
${card.ai_instruction}

Respond in ${language === 'zh-Hant' ? 'Traditional Chinese' : 'English'}.

Knowledge:
${getTranslatedKnowledge(card, language)}
`
```
