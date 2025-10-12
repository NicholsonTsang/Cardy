# OpenAI Realtime API CORS Error Fix

## Problem

When trying to connect to OpenAI's Realtime API (live voice call mode), the following error occurred:

```
Access to fetch at 'https://api.openai.com/v1/realtime' from origin 'http://localhost:5173' 
has been blocked by CORS policy: Response to preflight request doesn't pass access control check: 
No 'Access-Control-Allow-Origin' header is present on the requested resource.
```

## Root Cause

The WebRTC connection code was making a fetch request to `https://api.openai.com/v1/realtime` **without the required `model` parameter**. When using ephemeral tokens with OpenAI's Realtime API, you must include the model in the URL as a query parameter.

**Before (Incorrect)**:
```typescript
const response = await fetch('https://api.openai.com/v1/realtime', {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${ephemeralToken}`,
    'Content-Type': 'application/sdp'
  },
  body: offer.sdp
})
```

**After (Correct)**:
```typescript
const model = import.meta.env.VITE_OPENAI_REALTIME_MODEL || 'gpt-realtime-mini-2025-10-06'
const response = await fetch(`https://api.openai.com/v1/realtime?model=${model}`, {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${ephemeralToken}`,
    'Content-Type': 'application/sdp'
  },
  body: offer.sdp
})
```

## Why the Model Parameter is Required

According to OpenAI's Realtime API documentation:
- Ephemeral tokens are model-specific
- The frontend must specify which model to use when establishing the WebRTC connection
- The model parameter must match what was used when generating the ephemeral token

Without the model parameter:
1. The API doesn't know which model session to connect to
2. The preflight CORS request fails
3. The connection is blocked

## Fix Details

### 1. Updated WebRTC Connection Code

**File**: `src/views/MobileClient/components/AIAssistant/composables/useWebRTCConnection.ts`

Changes at line ~206:
- Added model parameter retrieval from environment variable
- Added model to the Realtime API URL as query parameter
- Added console log for debugging

```typescript
// Get model from environment (must match what was used for ephemeral token)
const model = import.meta.env.VITE_OPENAI_REALTIME_MODEL || 'gpt-realtime-mini-2025-10-06'
console.log('🎯 Using Realtime model:', model)

// Send offer to OpenAI (with model parameter required for ephemeral tokens)
const response = await fetch(`https://api.openai.com/v1/realtime?model=${model}`, {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${ephemeralToken}`,
    'Content-Type': 'application/sdp'
  },
  body: offer.sdp
})
```

### 2. Added Environment Variable

**File**: `.env.example`

Added new configuration:
```env
# OpenAI Realtime Model (must match Supabase Edge Function setting)
VITE_OPENAI_REALTIME_MODEL=gpt-4o-realtime-preview-2024-10-01
```

**Important**: The model specified in the frontend **must match** the model configured in the Supabase Edge Function (`openai-realtime-token`).

## Setup Instructions

### For Local Development

1. **Create `.env.local`** (if it doesn't exist):
   ```bash
   cp .env.example .env.local
   ```

2. **Add the Realtime model** to `.env.local`:
   ```env
   VITE_OPENAI_REALTIME_MODEL=gpt-realtime-mini-2025-10-06
   ```

3. **Restart your dev server**:
   ```bash
   npm run dev
   ```

### For Production

1. **Set environment variable** in your hosting platform (Vercel, Netlify, etc.):
   ```
   VITE_OPENAI_REALTIME_MODEL=gpt-realtime-mini-2025-10-06
   ```

2. **Ensure Supabase Edge Function uses the same model**:
   - Check `supabase/functions/openai-realtime-token/index.ts`
   - The `OPENAI_REALTIME_MODEL` secret in Supabase should match
   - Default: `gpt-realtime-mini-2025-10-06` (backend)
   - If different from frontend, update one to match the other

## Model Compatibility

**Available Realtime Models** (as of 2025):
- `gpt-4o-realtime-preview-2024-10-01` - Older model
- `gpt-realtime-mini-2025-10-06` - Current model (default, recommended)

**Important**: 
- Both frontend (`VITE_OPENAI_REALTIME_MODEL`) and backend (`OPENAI_REALTIME_MODEL` in Supabase secrets) must use the **same model**
- The ephemeral token is model-specific and won't work if models mismatch

## Testing

1. **Test Realtime Connection**:
   - Open the mobile AI assistant
   - Click the phone icon to switch to "Live Call" mode
   - Click "Connect" button
   - Check browser console for:
     - `🔑 Got ephemeral token`
     - `🎯 Using Realtime model: gpt-realtime-mini-2025-10-06`
     - `✅ Data channel opened`
     - `✅ WebRTC connection established`

2. **Verify No CORS Errors**:
   - Open browser DevTools → Console
   - Should see NO errors about CORS or `ERR_CONNECTION_CLOSED`
   - Connection should establish within 2-3 seconds

3. **Test Voice Call**:
   - Speak into microphone
   - Should see waveform animation
   - Should receive AI voice response
   - Transcripts should appear in real-time

## Troubleshooting

### Still Getting CORS Errors?

1. **Check model parameter**:
   - Look for console log: `🎯 Using Realtime model: ...`
   - Verify it's not `undefined`

2. **Verify environment variable**:
   ```bash
   # Check if .env.local exists
   cat .env.local | grep VITE_OPENAI_REALTIME_MODEL
   ```

3. **Restart dev server** after changing `.env.local`:
   ```bash
   npm run dev
   ```

4. **Check Supabase Edge Function**:
   - The backend model might be different
   - View Supabase secrets: `npx supabase secrets list`
   - Update to match frontend

### Connection Fails After Model Parameter Fix?

If CORS is fixed but connection still fails:

1. **Invalid API Key**: Check Supabase `OPENAI_API_KEY` secret
2. **Model Mismatch**: Frontend and backend models don't match
3. **Expired Token**: Ephemeral tokens expire quickly (60 seconds)
4. **Network Issues**: Try using the relay server if in blocked region

## Related Files

- `src/views/MobileClient/components/AIAssistant/composables/useWebRTCConnection.ts` - WebRTC connection logic
- `supabase/functions/openai-realtime-token/index.ts` - Ephemeral token generation
- `.env.example` - Environment variable template
- `.env.local` - Local environment variables (create from example)

## References

- [OpenAI Realtime API Documentation](https://platform.openai.com/docs/guides/realtime)
- [WebRTC Connection Flow](docs_archive/REALTIME_AUDIO_FULL_IMPLEMENTATION.md)
- [Ephemeral Token Usage](docs_archive/EDGE_FUNCTIONS_CONFIG.md)

