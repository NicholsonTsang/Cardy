# 🧪 Test Relay Server Integration

## Quick Integration Test

Follow these steps to verify the relay server works with your frontend:

---

## ✅ Step 1: Start Relay Server

```bash
cd openai-relay-server

# Install dependencies (first time only)
npm install

# Create .env file
cp .env.example .env

# Edit .env - add your OpenAI API key:
nano .env
```

Add this to `.env`:
```bash
OPENAI_API_KEY=sk-your-openai-key-here
PORT=8080
NODE_ENV=development
ALLOWED_ORIGINS=http://localhost:5173,http://localhost:3000
```

Start the server:
```bash
npm run dev
```

You should see:
```
🚀 OpenAI Realtime API Relay Server
=====================================
📡 Server listening on port 8080
🌍 Environment: development
🔑 OpenAI API key: ✅ Configured
🌐 Allowed origins: http://localhost:5173, http://localhost:3000

Available endpoints:
  GET  http://localhost:8080/health
  POST http://localhost:8080/offer
```

---

## ✅ Step 2: Test Relay Health

In a **new terminal**, run:

```bash
curl http://localhost:8080/health
```

**Expected response:**
```json
{
  "status": "healthy",
  "timestamp": "2025-10-28T...",
  "uptime": 5.123,
  "version": "1.0.0"
}
```

✅ If you see this, the relay server is running!

---

## ✅ Step 3: Run Test Suite

Still in the relay server directory:

```bash
cd openai-relay-server
./test-relay.sh
```

**Expected output:**
```
🧪 Testing OpenAI Relay Server
================================
Target: http://localhost:8080

Test 1: Health endpoint...
✅ PASS - Health endpoint returned 200 OK
   Response: {"status":"healthy",...}

Test 2: 404 on invalid endpoint...
✅ PASS - Invalid endpoint returned 404

Test 3: POST /offer validation...
✅ PASS - Missing SDP returns 400 Bad Request

Test 4: CORS headers...
✅ PASS - CORS headers present

================================
🎉 All tests passed!
```

✅ If all tests pass, the relay server is working correctly!

---

## ✅ Step 4: Connect Frontend

In your **main project directory** (not in openai-relay-server):

```bash
# Add relay URL to frontend config
echo "VITE_OPENAI_RELAY_URL=http://localhost:8080" >> .env.local

# Restart frontend development server
npm run dev
```

---

## ✅ Step 5: Test in Browser

1. **Open browser**: http://localhost:5173

2. **Navigate to a card** with AI Assistant enabled

3. **Open Browser DevTools** (F12) → Console tab

4. **Click the phone icon** (📞) to test Realtime Mode

5. **Check console logs** - you should see:

```
🔑 Got ephemeral token
🎯 Using Realtime model: gpt-realtime-mini-2025-10-06
🌐 Connecting through relay server: http://localhost:8080
✅ Data channel opened
✅ WebRTC connection established through relay
```

6. **If you see ✅ "WebRTC connection established through relay"** → Integration working! 🎉

---

## 🔍 What to Look For

### ✅ Success Indicators

**In Relay Server Terminal:**
```
📡 Relaying WebRTC offer to OpenAI (model: gpt-realtime-mini-2025-10-06)
✅ Successfully relayed offer (234ms)
```

**In Browser Console:**
```
🌐 Connecting through relay server: http://localhost:8080
✅ WebRTC connection established through relay
```

**In Browser UI:**
- Phone icon changes to red (connected)
- "Connected" status appears
- AI greeting plays
- You can speak and get responses

### ❌ Error Indicators

**If you see this:**
```
❌ Relay server required. Please configure VITE_OPENAI_RELAY_URL
```
**Fix**: Make sure `VITE_OPENAI_RELAY_URL=http://localhost:8080` is in `.env.local`

**If you see this:**
```
Failed to fetch
```
**Fix**: Make sure relay server is running (`npm run dev` in openai-relay-server)

**If you see this:**
```
Not allowed by CORS
```
**Fix**: Add `http://localhost:5173` to `ALLOWED_ORIGINS` in relay server `.env`

---

## 🎯 Integration Verification Checklist

Run through this checklist to verify everything works:

- [ ] Relay server starts without errors
- [ ] Health endpoint returns 200 OK
- [ ] Test suite passes all 4 tests
- [ ] Frontend has `VITE_OPENAI_RELAY_URL` in `.env.local`
- [ ] Browser console shows "Connecting through relay server"
- [ ] Browser console shows "WebRTC connection established"
- [ ] Phone icon turns red (connected)
- [ ] AI greeting plays automatically
- [ ] Can speak and get voice responses
- [ ] No CORS errors in console
- [ ] Relay server logs show successful relays

If all items are checked ✅ → **Integration complete!**

---

## 🚀 Next Steps

### For Development
You're all set! The relay server and frontend are working together.

**To use it:**
1. Start relay: `cd openai-relay-server && npm run dev`
2. Start frontend: `npm run dev`
3. Test Realtime Mode in browser

### For Production
Follow the deployment guide: `openai-relay-server/DEPLOYMENT_SSH.md`

---

## 📊 Data Flow Visualization

Here's what happens when you click the phone icon:

```
┌─────────────────────────────────────────────────────────────┐
│ 1. Browser creates WebRTC offer                             │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────┐
│ 2. POST http://localhost:8080/offer                         │
│    { sdp: "v=0...", model: "gpt-realtime...", token: "..." }│
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────┐
│ 3. Relay validates and forwards to OpenAI                   │
│    POST https://api.openai.com/v1/realtime?model=...        │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────┐
│ 4. OpenAI returns SDP answer                                │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────┐
│ 5. Relay returns to browser                                 │
│    { sdp: "v=0...", relayed: true, duration: 234 }          │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────┐
│ 6. Browser establishes WebRTC connection                    │
│    ✅ Connected! Audio streaming begins.                    │
└─────────────────────────────────────────────────────────────┘
```

---

## 💡 Alternative: Use Chat Mode

If relay setup feels like too much for local development:

1. **Just use Chat Mode** (no relay needed!)
2. Click **chat icon** (💬) instead of phone icon
3. Tap microphone button to use voice
4. Works perfectly without any relay server!

**Chat Mode is perfect for:**
- Local development
- Testing AI interactions
- Educational content
- Cost-conscious deployments

---

## 📚 More Info

- **Integration details**: `INTEGRATION_VERIFICATION.md`
- **Complete solution**: `REALTIME_API_COMPLETE_SOLUTION.md`
- **Why relay needed**: `REALTIME_CORS_RELAY_REQUIREMENT.md`
- **Deployment guide**: `openai-relay-server/DEPLOYMENT_SSH.md`

---

## ✅ Summary

**Integration verified if:**
- ✅ Relay server starts
- ✅ Health check passes
- ✅ Test suite passes
- ✅ Browser connects successfully
- ✅ Voice conversations work

**The relay server is fully integrated with the frontend and ready to use!** 🚀

