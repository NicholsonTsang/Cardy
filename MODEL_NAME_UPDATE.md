# Model Name Update - gpt-realtime-mini-2025-10-06

## Date: 2025-10-09

## Overview

Updated the OpenAI Realtime API model name from the preview version to the GA (Generally Available) model.

---

## Changes Made

### ❌ Old Model Name (Preview):
```
gpt-4o-mini-realtime-preview-2024-12-17
```

### ✅ New Model Name (GA):
```
gpt-realtime-mini-2025-10-06
```

---

## Files Updated

### 1. Frontend Composable
**File:** `src/views/MobileClient/components/AIAssistant/composables/useRealtimeConnection.ts`

**Changes:**
- Line 107: Updated `model` field
- Line 110: Updated `sessionConfig.model` field

```typescript
const tokenData = {
  success: true,
  token: 'relay-proxy-mode',
  model: 'gpt-realtime-mini-2025-10-06',  // ✅ Updated
  sessionConfig: {
    type: 'realtime',
    model: 'gpt-realtime-mini-2025-10-06',  // ✅ Updated
    // ... rest of config
  }
}
```

### 2. Relay Server
**File:** `openai-relay-server/src/index.ts`

**Changes:**
- Line 151: Updated default model in `parseWebSocketAuth` function

```typescript
function parseWebSocketAuth(req: IncomingMessage): { model: string } {
  const url = new URL(req.url || '', `http://${req.headers.host}`)
  const model = url.searchParams.get('model') || 'gpt-realtime-mini-2025-10-06'  // ✅ Updated
  return { model }
}
```

### 3. Configuration Example
**File:** `supabase/config.toml.example`

**Changes:**
- Line 335: Updated `OPENAI_REALTIME_MODEL` configuration
- Line 341: Updated legacy model comment

```toml
# OpenAI Realtime API Configuration (for real-time audio mode)
# Use mini model for cost-effective real-time conversations
OPENAI_REALTIME_MODEL = "gpt-realtime-mini-2025-10-06"  # ✅ Updated
OPENAI_REALTIME_VOICE = "alloy"
OPENAI_REALTIME_TEMPERATURE = "0.8"
OPENAI_REALTIME_MAX_TOKENS = "4096"
```

---

## Edge Function (Already Correct)

**File:** `supabase/functions/openai-realtime-relay/index.ts`

**Status:** ✅ Already using correct model name

```typescript
const model = Deno.env.get('OPENAI_REALTIME_MODEL') || 'gpt-realtime-mini-2025-10-06'
```

The Edge Function was already configured with the correct model name.

---

## Model Naming Convention

### OpenAI's Naming Convention for GA Models:

**Realtime Models:**
- ✅ `gpt-realtime-mini-2025-10-06` - Mini model (cost-effective)
- ✅ `gpt-realtime-standard-2025-10-06` - Standard model (more capable)

**Preview Models (Deprecated):**
- ❌ `gpt-4o-mini-realtime-preview-2024-12-17` - Old preview
- ❌ `gpt-4o-realtime-preview-2024-12-17` - Old preview

---

## Impact

### Before:
- ❌ Using preview model from December 2024
- ❌ Model name includes "preview" indicating beta status
- ❌ Inconsistent with GA API conventions

### After:
- ✅ Using GA model from October 2025
- ✅ Official production model name
- ✅ Consistent with OpenAI's current naming scheme
- ✅ Future-proof for production use

---

## Testing Checklist

After this update, verify:

- [ ] Frontend compiles without errors
- [ ] Relay server builds successfully (`npm run build`)
- [ ] WebSocket connection establishes
- [ ] Model name appears correctly in logs
- [ ] Audio streaming works properly
- [ ] Session configuration is accepted by OpenAI
- [ ] No "invalid model" errors in console

---

## Deployment Steps

### 1. Frontend
```bash
npm run build:production
```

### 2. Relay Server
```bash
cd openai-relay-server
docker-compose build
docker-compose up -d
```

### 3. Edge Functions (if not using open proxy)
```bash
npx supabase functions deploy openai-realtime-relay
```

### 4. Configuration
If using local config file:
```bash
cp supabase/config.toml.example supabase/config.toml
# Edit OPENAI_REALTIME_MODEL if needed
```

---

## Environment Variables

No environment variable changes needed for open proxy mode, but for reference:

```bash
# Optional: Can override model in environment
OPENAI_REALTIME_MODEL=gpt-realtime-mini-2025-10-06
```

---

## Cost Implications

The `gpt-realtime-mini` model is cost-effective compared to the standard model:

**Approximate Pricing:**
- `gpt-realtime-mini-2025-10-06`: Lower cost per token
- `gpt-realtime-standard-2025-10-06`: Higher cost, more capable

Always check [OpenAI pricing page](https://openai.com/pricing) for current rates.

---

## References

- [OpenAI Realtime API Documentation](https://platform.openai.com/docs/guides/realtime)
- [OpenAI Models Documentation](https://platform.openai.com/docs/models)
- [GA API Migration Guide](https://platform.openai.com/docs/guides/realtime#beta-to-ga-migration)

---

## Summary

All references to the old preview model have been updated to the GA model `gpt-realtime-mini-2025-10-06`. This ensures:

✅ **Compatibility** with the latest OpenAI API  
✅ **Production-ready** model naming  
✅ **Consistent** across all codebase files  
✅ **Future-proof** for long-term use

**Status: COMPLETE** ✅

