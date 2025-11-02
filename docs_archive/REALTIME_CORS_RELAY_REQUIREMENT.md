# OpenAI Realtime API - Relay Server Requirement

## Problem

When trying to use the OpenAI Realtime API (WebRTC voice mode) from a browser, you'll encounter a CORS error:

```
Access to fetch at 'https://api.openai.com/v1/realtime?model=...' from origin 'http://localhost:5173' 
has been blocked by CORS policy: Response to preflight request doesn't pass access control check: 
No 'Access-Control-Allow-Origin' header is present on the requested resource.
```

## Why This Happens

OpenAI's Realtime API **does not support direct browser connections** due to CORS (Cross-Origin Resource Sharing) restrictions. Even with ephemeral tokens, the browser cannot make the HTTP POST request needed for WebRTC SDP (Session Description Protocol) exchange because:

1. The browser sends a **preflight OPTIONS request** before the actual POST
2. OpenAI's API does not respond with CORS headers for browser requests
3. The browser blocks the connection for security reasons

This is by design - OpenAI wants to prevent API key exposure and enforce server-side security.

## Solutions

### Option 1: Use Chat Mode (Recommended for Local Development)

**The easiest solution** is to use Chat Mode instead of Realtime Mode:

1. Click the chat icon (not the phone icon) in the AI Assistant
2. You can still use voice by tapping the microphone button
3. Chat Mode uses:
   - **Whisper API** for speech-to-text (STT)
   - **GPT-4o mini** for text generation
   - **TTS API** for text-to-speech

**Advantages:**
- ✅ Works out of the box, no setup required
- ✅ No CORS issues
- ✅ Supports both text and voice input
- ✅ More cost-effective (~$0.01 per conversation)
- ✅ Better for long-form content

**When to use:**
- Local development
- Testing AI interactions
- Educational/informational content
- Cost-conscious deployments

### Option 2: Set Up Relay Server (Required for Realtime Mode)

To use Realtime Mode (live voice calls), you **must** deploy a relay server that proxies WebRTC connections to OpenAI.

#### Step 1: Set Up Relay Server

The relay server code is in the `openai-relay-server/` directory. Quick options:

**A. Local Development (Quick Test)**
```bash
cd openai-relay-server
npm install
npm run dev
```

**B. Deploy to Railway (Recommended)**
```bash
cd openai-relay-server
# Install Railway CLI
npm install -g @railway/cli

# Login and deploy
railway login
railway init
railway up
```

**C. Other Deployment Options**
- DigitalOcean App Platform
- AWS ECS + ALB
- Google Cloud Run
- Any VPS with Docker

See `openai-relay-server/README.md` for detailed deployment instructions.

#### Step 2: Configure Environment Variable

After deploying the relay server, add its URL to your `.env.local`:

```bash
# For local relay
VITE_OPENAI_RELAY_URL=http://localhost:8080

# For production relay
VITE_OPENAI_RELAY_URL=https://your-relay.railway.app
```

#### Step 3: Restart Development Server

```bash
npm run dev
```

Now Realtime Mode will work! The frontend will connect through your relay server instead of directly to OpenAI.

## Comparison: Chat Mode vs Realtime Mode

| Feature | Chat Mode | Realtime Mode |
|---------|-----------|---------------|
| **Setup** | None required | Relay server required |
| **Latency** | 2-3 seconds | <1 second |
| **Cost** | ~$0.01/conversation | ~$0.60/5-min session |
| **Voice Quality** | Natural TTS | Natural realtime |
| **Use Case** | Information, education | Conversations, live guidance |
| **Interruption** | Not supported | Bidirectional, natural |
| **Works Locally** | ✅ Yes | ❌ Requires relay |

## Architecture Diagrams

### Chat Mode (Works Without Relay)
```
┌─────────┐     ┌──────────────┐     ┌────────────┐
│ Browser │────>│ Edge Function│────>│ OpenAI API │
│         │<────│ (Supabase)   │<────│  (Whisper, │
└─────────┘     └──────────────┘     │   GPT, TTS)│
                                     └────────────┘
```

### Realtime Mode (Requires Relay)
```
┌─────────┐     ┌──────────────┐     ┌────────────┐
│ Browser │────>│ Relay Server │────>│ OpenAI API │
│         │<────│  (WebRTC     │<────│ (Realtime) │
└─────────┘     │   Proxy)     │     └────────────┘
                └──────────────┘
                     ↑
                     │ Deployed on
                     │ Railway/AWS/GCP
```

## Error Messages

If you see any of these errors, you need either Chat Mode or a relay server:

```
❌ "Relay server required. Please configure VITE_OPENAI_RELAY_URL"
❌ "Access to fetch at 'https://api.openai.com/v1/realtime' ... blocked by CORS"
❌ "Connection blocked. Please use Chat Mode instead"
❌ "Realtime voice mode requires additional setup"
```

## Recommended Approach

1. **For Local Development**: Use **Chat Mode** - it works perfectly without any setup
2. **For Production (if needed)**: Deploy a relay server for Realtime Mode

Most use cases work great with Chat Mode! Realtime Mode is only needed for:
- Natural conversation interruptions
- Ultra-low latency requirements (<1 second)
- Real-time bidirectional voice dialogue

## Technical Details

### Why Can't We Fix the CORS Issue?

You cannot "fix" the CORS issue because:
1. CORS headers are controlled by **OpenAI's servers**, not your code
2. OpenAI intentionally blocks browser requests for security
3. Browser CORS policies cannot be bypassed (by design)

The only solutions are:
- Use server-side requests (Edge Functions for Chat Mode)
- Use a proxy/relay server (for Realtime Mode)

### What Does the Relay Server Do?

The relay server:
1. Accepts WebRTC connection requests from browsers
2. Forwards the SDP offer to OpenAI on the server side (no CORS)
3. Returns the SDP answer to the browser
4. Proxies all subsequent WebRTC messages bidirectionally

It's a transparent proxy that doesn't process or store any data.

## Quick Reference

| Scenario | Solution | Command |
|----------|----------|---------|
| Local dev, want voice | **Use Chat Mode** | Click chat icon, tap mic button |
| Need low latency | **Deploy relay** | See `openai-relay-server/QUICKSTART.md` |
| Production ready | **Deploy relay** | Use Railway/AWS/GCP |
| CORS error | **Switch to Chat Mode** | Or deploy relay server |

## Files Changed

This fix involved:

1. **`src/views/MobileClient/components/AIAssistant/composables/useWebRTCConnection.ts`**
   - Added relay server requirement check
   - Clear error message when relay not configured
   - Support for `VITE_OPENAI_RELAY_URL` environment variable

2. **`src/views/MobileClient/components/AIAssistant/MobileAIAssistant.vue`**
   - Enhanced error handling for relay/CORS errors
   - User-friendly messages suggesting Chat Mode

3. **`.env.example`**
   - Added `VITE_OPENAI_RELAY_URL` with documentation

4. **`env.d.ts`**
   - Added TypeScript definition for `VITE_OPENAI_RELAY_URL`

## Next Steps

1. **If you want Realtime Mode**: Follow Option 2 above to deploy a relay server
2. **If Chat Mode is enough**: You're done! Just use the chat icon instead of phone icon
3. **For production**: Evaluate if you need Realtime Mode's benefits vs its costs

## References

- Relay server code: `openai-relay-server/`
- Relay setup guide: `openai-relay-server/QUICKSTART.md`
- Full documentation: `docs_archive/OPENAI_RELAY_SERVER_SETUP.md`
- OpenAI Realtime API: https://platform.openai.com/docs/guides/realtime

