# Realtime API - Beta to GA Migration

## 🎯 Issue Root Cause

The connection was failing with `server_error` because the code was using the **old beta API structure**, but OpenAI has moved to the **GA (General Availability) API** with breaking changes.

### Error Timeline

```
1. session.created ✅
2. session.update (beta format) ❌
3. OpenAI server_error ❌
4. Connection closed
```

---

## 🔄 Key Changes: Beta → GA

### 1. Session Type Required

**Beta:**
```javascript
{
  type: 'session.update',
  session: {
    model: 'gpt-4o-realtime-preview-2024-12-17',
    // ...
  }
}
```

**GA (Required):**
```javascript
{
  type: 'session.update',
  session: {
    type: 'realtime',  // ✅ REQUIRED!
    model: 'gpt-realtime',
    // ...
  }
}
```

### 2. Audio Configuration Structure

**Beta (Flat):**
```javascript
{
  input_audio_format: 'pcm16',
  output_audio_format: 'pcm16',
  voice: 'alloy'
}
```

**GA (Nested):**
```javascript
{
  audio: {
    input: {
      format: {
        type: 'audio/pcm',
        rate: 24000
      },
      turn_detection: {
        type: 'semantic_vad'
      }
    },
    output: {
      format: {
        type: 'audio/pcm'
      },
      voice: 'alloy'
    }
  }
}
```

### 3. Event Names Changed

| Beta Event | GA Event |
|---|---|
| `response.audio.delta` | `response.output_audio.delta` |
| `response.audio_transcript.delta` | `response.output_audio_transcript.delta` |
| `response.text.delta` | `response.output_text.delta` |

### 4. Other Field Changes

| Beta | GA |
|---|---|
| `max_response_output_tokens` | `max_output_tokens` |
| `modalities` | `output_modalities` |

---

## ✅ What Was Fixed

### File 1: `supabase/functions/openai-realtime-relay/index.ts`

**Updated TypeScript Interface:**
```typescript
interface RealtimeSessionConfig {
  type: string  // 'realtime' for speech-to-speech
  model?: string
  output_modalities?: string[]
  audio?: {
    input?: {
      format?: { type: string, rate: number }
      turn_detection?: { type: string }
    }
    output?: {
      format?: { type: string }
      voice?: string
    }
  }
  instructions?: string
  temperature?: number
  max_output_tokens?: number  // Renamed from max_response_output_tokens
}
```

**Updated Session Config:**
```typescript
const sessionConfig: RealtimeSessionConfig = {
  type: 'realtime',  // ✅ Required for GA API
  model: model,
  output_modalities: ['audio'],  // ✅ Lock to audio output
  audio: {
    input: {
      format: {
        type: 'audio/pcm',
        rate: 24000
      },
      turn_detection: {
        type: 'semantic_vad'  // Voice Activity Detection
      }
    },
    output: {
      format: {
        type: 'audio/pcm'
      },
      voice: voice
    }
  },
  instructions: instructions,
  temperature: temperature,
  max_output_tokens: maxTokens  // ✅ Renamed
}
```

### File 2: `src/views/MobileClient/components/MobileAIAssistant.vue`

**Updated Event Handlers:**

```typescript
// OLD (Beta)
if (data.type === 'response.audio.delta' && data.delta) {
  realtimeConnection.playRealtimeAudio(data.delta)
}

// NEW (GA)
if (data.type === 'response.output_audio.delta' && data.delta) {
  realtimeConnection.playRealtimeAudio(data.delta)
}
```

```typescript
// OLD (Beta)
if (data.type === 'response.audio_transcript.delta' && data.delta) {
  // ...
}

// NEW (GA)
if (data.type === 'response.output_audio_transcript.delta' && data.delta) {
  // ...
}
```

---

## 🚀 Deployment Steps

### Step 1: Deploy Edge Function

The Edge Function needs to be redeployed to use the new GA API structure:

```bash
cd ~/Cardy

# Deploy the updated Edge Function
npx supabase functions deploy openai-realtime-relay
```

**Verify deployment:**
- Check Supabase Dashboard → Edge Functions
- Look for successful deployment message
- Verify no deployment errors

### Step 2: Restart Frontend

```bash
# Stop current dev server (Ctrl+C)
# Then restart
npm run dev
```

### Step 3: Update Model to Mini (Optional but Recommended)

In **Supabase Dashboard → Edge Functions → Secrets**:

```
OPENAI_REALTIME_MODEL=gpt-realtime-mini-2025-10-06
```

Or use the CLI:
```bash
npx supabase secrets set OPENAI_REALTIME_MODEL=gpt-realtime-mini-2025-10-06
```

---

## 🧪 Testing

### Expected Behavior

**Console (Frontend):**
```
🔄 Connecting via relay server: ws://47.237.173.62:8080/realtime?model=...
✅ Relay connection established
⏳ Waiting for OpenAI session...
📦 Converted binary Blob to text
📨 WebSocket message: session.created
✅ OpenAI session established!
📤 Sending session configuration
📨 WebSocket message: session.updated ✅ (No error!)
🎙️ Starting audio transmission...
✅ Audio processing chain established
📨 WebSocket message: input_audio_buffer.speech_started
📨 WebSocket message: response.output_audio.delta ✅ (New event name!)
🔊 Playing audio...
```

**Relay Server Logs:**
```
[INFO] New client connection: session-xxxxx
[INFO] Authentication successful: session-xxxxx { 
  model: 'gpt-realtime-mini-2025-10-06' ✅
}
[INFO] Connecting to OpenAI: session-xxxxx
[INFO] Connected to OpenAI: session-xxxxx
[DEBUG] OpenAI → Client: { type: 'session.created' }
[DEBUG] Client → OpenAI: { type: 'session.update' }
[DEBUG] OpenAI → Client: { type: 'session.updated' } ✅ (No error!)
[DEBUG] Client → OpenAI: { type: 'input_audio_buffer.append' }
[DEBUG] OpenAI → Client: { type: 'response.output_audio.delta' }
```

**No more `server_error`!** ✅

### What to Look For

✅ **Success Indicators:**
- `session.updated` event (not `error`)
- Connection stays open
- Audio streaming works
- Transcript appears in UI
- No server errors in logs

❌ **Failure Indicators:**
- `server_error` after `session.update`
- Connection closes immediately
- "OpenAI connection not ready" warnings
- Empty or missing audio

---

## 📊 Beta vs GA API Comparison

### Session Update Structure

**Beta:**
```json
{
  "type": "session.update",
  "session": {
    "model": "gpt-4o-realtime-preview-2024-12-17",
    "voice": "alloy",
    "instructions": "You are helpful...",
    "input_audio_format": "pcm16",
    "output_audio_format": "pcm16",
    "temperature": 0.8,
    "max_response_output_tokens": 4096
  }
}
```

**GA:**
```json
{
  "type": "session.update",
  "session": {
    "type": "realtime",
    "model": "gpt-realtime",
    "output_modalities": ["audio"],
    "audio": {
      "input": {
        "format": { "type": "audio/pcm", "rate": 24000 },
        "turn_detection": { "type": "semantic_vad" }
      },
      "output": {
        "format": { "type": "audio/pcm" },
        "voice": "alloy"
      }
    },
    "instructions": "You are helpful...",
    "temperature": 0.8,
    "max_output_tokens": 4096
  }
}
```

---

## 🔍 Troubleshooting

### Issue: Still Getting `server_error`

**Check:**
1. Did you deploy the Edge Function? (`npx supabase functions deploy openai-realtime-relay`)
2. Did you restart the frontend? (`npm run dev`)
3. Check relay logs for the actual session.update being sent

### Issue: Events Not Being Received

**Check:**
1. Are you using the new event names? (`response.output_audio.delta`)
2. Check browser console for event types
3. Look for typos in event handlers

### Issue: Using Wrong Model

**Check:**
1. Relay logs show which model is being used
2. Update `OPENAI_REALTIME_MODEL` in Supabase secrets
3. Should be: `gpt-realtime-mini-2025-10-06` (cost-optimized)

---

## 📚 References

- [OpenAI Realtime API Docs](https://platform.openai.com/docs/guides/realtime)
- [Beta to GA Migration Guide](https://platform.openai.com/docs/guides/realtime#beta-to-ga-migration)
- [WebSocket Connection Guide](https://platform.openai.com/docs/guides/realtime-websocket)
- [Session Events API Reference](https://platform.openai.com/docs/api-reference/realtime_client_events/session/update)

---

## ✅ Summary

**Issue:** Using beta API structure causing `server_error`  
**Cause:** OpenAI moved to GA API with breaking changes  
**Fix:** Updated session config and event names to GA format  
**Status:** ✅ Fixed (pending deployment)  
**Next Steps:** Deploy Edge Function, restart frontend, test  

The connection should now work correctly with the GA API! 🎉

