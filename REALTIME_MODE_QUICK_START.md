# Real-Time Audio Mode - Quick Start Guide 🚀

## ⚡ Get Started in 5 Minutes

The real-time audio chat mode is ready to use! Follow these steps to start having live AI conversations.

---

## 📋 Prerequisites

✅ Already complete:
- Edge Function deployed (`openai-realtime-relay`)
- Frontend code integrated
- Configuration files updated

⚙️ Required:
- Valid OpenAI API key
- HTTPS enabled (required for microphone access)
- Modern browser (Chrome, Firefox, Edge)

---

## 🔧 Configuration Check

### 1. Verify Supabase Secrets

Check these secrets are set in your Supabase Dashboard:

```
Project Settings → Edge Functions → Secrets
```

Required:
- `OPENAI_API_KEY` - Your OpenAI API key

Optional (have defaults):
- `OPENAI_REALTIME_MODEL` - Default: `gpt-4o-realtime-preview-2024-12-17`
- `OPENAI_REALTIME_VOICE` - Default: `alloy`
- `OPENAI_REALTIME_TEMPERATURE` - Default: `0.8`
- `OPENAI_REALTIME_MAX_TOKENS` - Default: `4096`

---

## 🎬 How to Use

### Step 1: Open AI Assistant

1. Navigate to any card's content item
2. Click **"Ask AI Assistant"** button
3. Select your language (10 languages supported)

### Step 2: Switch to Realtime Mode

1. Look for the **phone icon** (📞) in the top-right corner
2. Click it to switch from chat mode to realtime mode
3. UI changes to show:
   - Large AI avatar
   - Status banner
   - "Start Live Call" button

### Step 3: Connect

1. Click **"Start Live Call"** (green button)
2. Grant microphone permission when prompted
3. Wait 2-3 seconds for connection
4. Status changes: Gray → Blue (connecting) → Green (connected)

### Step 4: Have a Conversation

1. **Speak naturally** into your microphone
2. Watch the live transcript update in real-time
3. AI responds with voice (< 500ms latency)
4. Animated waveform shows activity

### Step 5: Disconnect

1. Click **"End Call"** (red button)
2. Connection cleanly closes
3. Transcript remains for reference

### Step 6: Switch Back (Optional)

1. Click **chat icon** (💬) to return to chat mode
2. Continue with traditional text/voice chat

---

## 🎯 What to Expect

### Visual Feedback

- **Gray Avatar**: Not connected
- **Blue Pulsing Avatar**: Connecting...
- **Green Pulsing Avatar**: Connected! Listening...
- **Bright Green with Fast Pulse**: AI is speaking
- **Waveform Animation**: 20 bars animating around avatar

### Audio Quality

- **Clear Voice**: 24kHz PCM16 audio
- **Low Latency**: AI responds in < 500ms
- **Natural Conversation**: Smooth turn-taking

### Live Transcript

- **User** (blue): Your spoken words
- **AI** (green): AI's responses
- **Streaming**: Updates character-by-character

---

## 💡 Tips for Best Experience

### Do's ✅

- **Speak Clearly**: Normal conversational pace
- **Wait for AI**: Let AI finish before speaking
- **Use Headphones**: Prevents feedback loops
- **Good Microphone**: Quality mic = better transcription
- **Stable Internet**: WiFi or strong mobile signal

### Don'ts ❌

- **Don't Interrupt**: Wait for AI to finish
- **Don't Speak Too Fast**: Give AI time to process
- **Don't Use on Mobile Data**: Can be expensive
- **Don't Forget to Disconnect**: Close when done

---

## 🐛 Troubleshooting

### Issue: "Microphone permission denied"

**Solution**:
1. Click lock icon in browser address bar
2. Allow microphone access
3. Reload page
4. Try connecting again

### Issue: "Connection failed"

**Check**:
1. Valid OpenAI API key in Supabase secrets
2. HTTPS enabled (not HTTP)
3. Modern browser (Chrome/Firefox/Edge)
4. Network allows WebRTC connections

### Issue: "No audio output"

**Check**:
1. Speaker/headphones connected and working
2. Browser audio not muted
3. System volume not muted
4. Try playing other audio to test

### Issue: "Poor audio quality"

**Solutions**:
1. Use wired headphones (not Bluetooth)
2. Close other tabs using microphone
3. Move to quieter environment
4. Check internet connection speed

---

## 📊 Performance Expectations

| Metric | Expected Value |
|--------|---------------|
| **Connection Time** | 2-3 seconds |
| **Response Latency** | < 500ms |
| **Audio Quality** | 24kHz (clear) |
| **Transcript Accuracy** | High (95%+) |
| **Animation FPS** | 60fps (smooth) |
| **Browser Compatibility** | Chrome, Firefox, Edge |

---

## 💰 Cost Awareness

### Per Conversation

- **5 minutes**: ~$0.90 USD
- **Compared to chat mode**: 90x more expensive

### Why?

- OpenAI Realtime API pricing:
  - $0.06/min for input audio
  - $0.24/min for output audio
- High quality, low latency comes at a cost

### Recommendation

- Use chat-completion mode by default
- Offer realtime as premium/special feature
- Set session timeouts (e.g., 10 minutes)
- Monitor usage and costs

---

## 🌍 Supported Languages

The AI will respond in your selected language:

1. 🇺🇸 **English**
2. 🇭🇰 **廣東話** (Cantonese)
3. 🇨🇳 **普通话** (Mandarin)
4. 🇯🇵 **日本語** (Japanese)
5. 🇰🇷 **한국어** (Korean)
6. 🇪🇸 **Español** (Spanish)
7. 🇫🇷 **Français** (French)
8. 🇷🇺 **Русский** (Russian)
9. 🇸🇦 **العربية** (Arabic)
10. 🇹🇭 **ไทย** (Thai)

---

## 🔒 Privacy & Security

### What We Do

- ✅ Use ephemeral tokens (expire after 60 seconds)
- ✅ Direct WebRTC to OpenAI (no intermediate servers)
- ✅ DTLS-SRTP encryption for audio
- ✅ No API keys exposed to frontend
- ✅ Request microphone permission explicitly

### What You Should Know

- 🎙️ Microphone access required (user grants permission)
- 🔊 Audio streamed directly to OpenAI
- 📝 Transcripts stored locally (not saved to database)
- 🔒 HTTPS required (standard web security)

---

## 📱 Browser Compatibility

### ✅ Tested & Working

- **Chrome** (latest)
- **Firefox** (latest)
- **Edge** (latest)

### ⏳ Pending Testing

- **Safari** (desktop)
- **Safari** (iOS)
- **Chrome Mobile** (Android)

### ❌ Not Supported

- Internet Explorer
- Very old browsers (pre-2020)
- Browsers without WebRTC support

---

## 🎓 Example Conversations

### Museum Exhibit

**User**: "Tell me about this artifact"  
**AI**: 🔊 "This is a Ming Dynasty vase from the 15th century. It features..."

### Tourist Landmark

**User**: "What's the history of this building?"  
**AI**: 🔊 "This historic castle was built in 1204 and served as..."

### Art Gallery

**User**: "Who painted this?"  
**AI**: 🔊 "This painting was created by Vincent van Gogh in 1889..."

---

## 🆚 When to Use Realtime vs Chat

### Use **Realtime Mode** When:

- 👥 Walking tours (hands-free)
- 🎨 Immersive experiences desired
- 💬 Natural conversation flow preferred
- 🚶 Moving between exhibits
- 👂 Prefer listening over reading

### Use **Chat Mode** When:

- 💰 Cost-sensitive (90x cheaper)
- 📖 Want to save text for later
- 🔇 In noisy environments
- 📱 Limited data/bandwidth
- 📝 Need to copy/share information

---

## 🎉 You're Ready!

1. ✅ Configuration verified
2. ✅ Edge Function deployed
3. ✅ Frontend integrated
4. ✅ Know how to use it

**Now go try it out!** Click that phone icon and have your first live AI conversation! 🎙️

---

## 📚 Need More Info?

- **Technical Details**: See `REALTIME_AUDIO_FULL_IMPLEMENTATION.md`
- **Testing Guide**: See `REALTIME_MODE_DEMO_GUIDE.md`
- **Feature Comparison**: See `AI_MODES_COMPARISON.md`
- **Architecture**: See `REALTIME_AUDIO_IMPLEMENTATION_PLAN.md`

---

**Questions? Issues?** Check the troubleshooting section above or review the full documentation.

**Happy conversing! 🎤✨**

