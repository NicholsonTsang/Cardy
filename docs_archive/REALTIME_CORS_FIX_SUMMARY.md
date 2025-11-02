# Realtime API CORS Error - Fix Summary

## Problem Identified

User encountered CORS error when trying to use Realtime voice call mode:
```
Access to fetch at 'https://api.openai.com/v1/realtime' from origin 'http://localhost:5173' 
has been blocked by CORS policy: No 'Access-Control-Allow-Origin' header present
```

## Root Cause

The WebRTC connection code was calling `https://api.openai.com/v1/realtime` **without the required `model` query parameter**. OpenAI's Realtime API requires the model to be specified when using ephemeral tokens:
- ❌ Wrong: `https://api.openai.com/v1/realtime`
- ✅ Correct: `https://api.openai.com/v1/realtime?model=gpt-realtime-mini-2025-10-06`

## Fix Applied

### 1. Updated WebRTC Connection Logic

**File**: `src/views/MobileClient/components/AIAssistant/composables/useWebRTCConnection.ts`

Added model parameter to the API URL:
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

### 2. Added Environment Variable Configuration

**File**: `.env.example`

```env
# OpenAI Realtime Model (must match Supabase Edge Function setting)
VITE_OPENAI_REALTIME_MODEL=gpt-realtime-mini-2025-10-06
```

### 3. Updated Documentation

**Files Updated**:
- `CLAUDE.md` - Added to Common Issues section
- `REALTIME_CORS_FIX.md` - Comprehensive fix documentation

## User Action Required

### Create/Update `.env.local`

1. **Copy from example** (if `.env.local` doesn't exist):
   ```bash
   cp .env.example .env.local
   ```

2. **Add Realtime model** to `.env.local`:
   ```env
   VITE_OPENAI_REALTIME_MODEL=gpt-realtime-mini-2025-10-06
   ```

3. **Restart dev server**:
   ```bash
   npm run dev
   ```

### Important Notes

⚠️ **Model Consistency**: The model in frontend (`VITE_OPENAI_REALTIME_MODEL`) must match the model in Supabase Edge Function (`OPENAI_REALTIME_MODEL` secret).

**Default Models**:
- Frontend fallback: `gpt-realtime-mini-2025-10-06`
- Backend default: `gpt-realtime-mini-2025-10-06`

Both are now configured to use the same model for consistency.

## Testing Checklist

### 1. Verify Environment Setup
- [ ] `.env.local` file exists
- [ ] Contains `VITE_OPENAI_REALTIME_MODEL=gpt-realtime-mini-2025-10-06`
- [ ] Dev server restarted after adding variable

### 2. Test Realtime Connection
- [ ] Open mobile AI assistant
- [ ] Click phone icon to switch to "Live Call" mode
- [ ] Click "Connect" button
- [ ] Check browser console for success logs:
  - `🔑 Got ephemeral token`
  - `🎯 Using Realtime model: gpt-realtime-mini-2025-10-06`
  - `✅ Data channel opened`
  - `✅ WebRTC connection established`

### 3. Verify Fix
- [ ] NO CORS errors in console
- [ ] Connection establishes within 2-3 seconds
- [ ] Waveform animation appears when speaking
- [ ] AI responds with voice
- [ ] Transcripts show in real-time

## Files Modified

1. `src/views/MobileClient/components/AIAssistant/composables/useWebRTCConnection.ts`
   - Added model parameter retrieval from environment
   - Updated API URL to include `?model=` query parameter
   - Added debug console log

2. `.env.example`
   - Added `VITE_OPENAI_REALTIME_MODEL` configuration

3. `CLAUDE.md`
   - Added Realtime CORS error to Common Issues section

4. Documentation
   - Created `REALTIME_CORS_FIX.md` with comprehensive details
   - Created this summary document

## Why This Fix Works

1. **Ephemeral tokens are model-specific**: OpenAI's Realtime API generates tokens tied to a specific model
2. **Model parameter is required**: The API endpoint needs to know which model's session to connect to
3. **CORS preflight check fails without model**: Missing parameter causes API to reject the preflight OPTIONS request
4. **Model consistency ensures compatibility**: Frontend and backend must use the same model for the ephemeral token to work

## Related Documentation

- Full fix guide: `REALTIME_CORS_FIX.md`
- Realtime implementation: `docs_archive/REALTIME_AUDIO_FULL_IMPLEMENTATION.md`
- Edge Functions config: `docs_archive/EDGE_FUNCTIONS_CONFIG.md`
- OpenAI Realtime API: https://platform.openai.com/docs/guides/realtime

## Production Deployment

When deploying to production:

1. **Set environment variable** in hosting platform:
   ```
   VITE_OPENAI_REALTIME_MODEL=gpt-realtime-mini-2025-10-06
   ```

2. **Verify Supabase Edge Function secret**:
   ```bash
   npx supabase secrets list
   ```
   
3. **Ensure models match**:
   - Frontend: `VITE_OPENAI_REALTIME_MODEL`
   - Backend: `OPENAI_REALTIME_MODEL`

4. **Test after deployment** with checklist above

## Next Steps

1. **Test the fix immediately** following the testing checklist
2. **Report any remaining issues** if connection still fails
3. **Update production env vars** when deploying to production

