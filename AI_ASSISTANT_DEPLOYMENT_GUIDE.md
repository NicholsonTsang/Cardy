# AI Assistant Deployment Guide

## ✅ Completed Implementation

### **1. Edge Function Created**
- **File**: `supabase/functions/chat-with-audio/index.ts`
- **Functionality**: Unified endpoint for Chat Completions with native audio support
- **Model**: `gpt-4o-audio-preview`

### **2. Frontend Component Created**
- **File**: `src/views/MobileClient/components/MobileAIAssistant.vue`
- **Features**:
  - ✅ Chat interface with message history
  - ✅ Text input with Enter key support
  - ✅ Voice input (hold-to-record button)
  - ✅ Dual input mode toggle (text/voice)
  - ✅ Language selector (5 languages)
  - ✅ Typing indicators
  - ✅ Error handling
  - ✅ Audio playback for voice responses
  - ✅ Base64 audio conversion utilities

### **3. Environment Variables Updated**
- **Files**: `.env` and `.env.production`
- **New variables**:
  ```bash
  OPENAI_AUDIO_MODEL=gpt-4o-audio-preview
  OPENAI_TTS_VOICE=alloy
  OPENAI_AUDIO_FORMAT=wav
  ```

---

## 🚀 Deployment Steps

### **Step 1: Deploy Edge Function**

```bash
# Navigate to project directory
cd /Users/nicholsontsang/coding/Cardy

# Deploy the new Edge Function
supabase functions deploy chat-with-audio
```

### **Step 2: Set Edge Function Secrets**

You need to set the `OPENAI_API_KEY` secret in Supabase Dashboard:

**Option A: Via Supabase Dashboard (Recommended)**
1. Go to https://supabase.com/dashboard
2. Select your project
3. Navigate to **Edge Functions** → **Manage secrets**
4. Add/Update secrets:
   - `OPENAI_API_KEY`: Your OpenAI API key
   - `OPENAI_AUDIO_MODEL`: `gpt-4o-audio-preview`
   - `OPENAI_TTS_VOICE`: `alloy` (or `echo`, `fable`, `onyx`, `nova`, `shimmer`)
   - `OPENAI_AUDIO_FORMAT`: `wav`

**Option B: Via CLI (Local Testing)**
Update `supabase/config.toml`:
```toml
[edge_runtime.secrets]
OPENAI_API_KEY = "sk-..."
OPENAI_AUDIO_MODEL = "gpt-4o-audio-preview"
OPENAI_TTS_VOICE = "alloy"
OPENAI_AUDIO_FORMAT = "wav"
```

### **Step 3: Build and Deploy Frontend**

```bash
# Build for production
npm run build:production

# Or for development
npm run build
```

### **Step 4: Test Locally First**

```bash
# Start Supabase locally
supabase start

# Start dev server
npm run dev

# Test the AI assistant:
# 1. Navigate to a card with content
# 2. Click "Ask AI Assistant"
# 3. Try text input
# 4. Try voice input (hold the record button)
```

---

## 🧪 Testing Checklist

### **Text Input Testing**
- [ ] Open AI Assistant modal
- [ ] Type a message and press Enter
- [ ] Verify message appears in chat
- [ ] Verify AI response appears
- [ ] Check response is in selected language
- [ ] Test error handling (disconnect internet)

### **Voice Input Testing**
- [ ] Switch to voice mode (microphone icon)
- [ ] Hold record button
- [ ] Speak a question
- [ ] Release button
- [ ] Verify "Processing voice message..." appears
- [ ] Verify transcription appears as user message
- [ ] Verify AI text response appears
- [ ] Verify AI audio plays automatically
- [ ] Check audio quality and language

### **Language Testing**
Test all 5 languages:
- [ ] English 🇺🇸
- [ ] 廣東話 (Cantonese) 🇭🇰
- [ ] 普通话 (Mandarin) 🇨🇳
- [ ] Español (Spanish) 🇪🇸
- [ ] Français (French) 🇫🇷

### **Mobile Testing**
- [ ] iOS Safari - Text input
- [ ] iOS Safari - Voice input
- [ ] iOS Safari - Audio playback
- [ ] Android Chrome - Text input
- [ ] Android Chrome - Voice input
- [ ] Android Chrome - Audio playback

### **Edge Cases**
- [ ] Empty message handling
- [ ] Very long messages
- [ ] Rapid message sending
- [ ] Modal close during loading
- [ ] Network errors
- [ ] Microphone permission denied
- [ ] Audio playback errors

---

## 🐛 Troubleshooting

### **Issue: "OPENAI_API_KEY not configured"**
**Solution**: Set the secret in Supabase Dashboard (Edge Functions → Manage secrets)

### **Issue: "Failed to transcribe audio"**
**Possible causes**:
1. Audio format not supported
2. Audio file too large
3. Network error

**Solution**: Check Edge Function logs:
```bash
supabase functions logs chat-with-audio --tail
```

### **Issue: "Microphone access denied"**
**Solution**: 
- Check browser permissions
- Ensure HTTPS (microphone requires secure context)
- Test on actual device (not simulator)

### **Issue: "Audio won't play"**
**Possible causes**:
1. Browser autoplay policy
2. Audio format not supported
3. CORS issues

**Solution**:
- Check browser console for errors
- Try user gesture to unlock audio
- Verify audio format is `wav`

### **Issue: Voice responses not working**
**Check**:
1. `modalities: ['text', 'audio']` is set in request
2. Edge Function is receiving `voiceInput` parameter
3. OpenAI API response includes `audio` field
4. Base64 audio data is valid

**Debug**:
```bash
# Check Edge Function logs
supabase functions logs chat-with-audio --tail

# Check frontend console
# Look for: "Received AI response with audio"
```

---

## 📊 Monitoring

### **Edge Function Logs**
```bash
# View real-time logs
supabase functions logs chat-with-audio --tail

# View specific timeframe
supabase functions logs chat-with-audio --since 1h
```

### **Key Metrics to Monitor**
- Request count
- Error rate
- Average response time
- Token usage (input + output)
- Audio transcription accuracy

### **OpenAI API Usage**
Monitor your OpenAI API usage at: https://platform.openai.com/usage

**Expected costs**:
- `gpt-4o-audio-preview`: ~$100/1M input tokens, ~$200/1M output tokens
- Audio input: Charged per audio token
- Audio output: Charged per audio token

---

## 🔄 Migration from Old Realtime API

### **What to Remove (Optional)**
Old files that can be deprecated:
- `supabase/functions/get-openai-ephemeral-token/` (no longer needed)
- `supabase/functions/openai-realtime-proxy/` (no longer needed)
- `src/utils/http.js` → `sendOpenAIRealtimeRequest()` function (if only used for AI)

### **What to Keep**
Keep the old Realtime API setup if you want to:
- Maintain backward compatibility
- A/B test both approaches
- Gradually migrate users

---

## 📝 Next Steps

### **Immediate**
1. Deploy Edge Function to production
2. Set API keys in Supabase secrets
3. Test on mobile devices
4. Monitor logs and costs

### **Future Enhancements**
- [ ] Add streaming responses for faster UX
- [ ] Implement conversation export
- [ ] Add message reactions/feedback
- [ ] Support multiple voice options
- [ ] Add conversation analytics
- [ ] Implement message editing/regeneration
- [ ] Add voice activity detection for auto-stop
- [ ] Support file uploads (images) in chat
- [ ] Add conversation branching
- [ ] Implement rate limiting

---

## 📚 API Documentation References

- **OpenAI Chat Completions API**: https://platform.openai.com/docs/api-reference/chat
- **OpenAI Audio Guide**: https://platform.openai.com/docs/guides/audio
- **Supabase Edge Functions**: https://supabase.com/docs/guides/functions
- **Web Audio API**: https://developer.mozilla.org/en-US/docs/Web/API/Web_Audio_API
- **MediaRecorder API**: https://developer.mozilla.org/en-US/docs/Web/API/MediaRecorder

---

## ✨ Summary

You now have a complete AI assistant with:
- ✅ Text and voice input
- ✅ Multi-language support
- ✅ Native audio transcription and synthesis
- ✅ Clean chat interface
- ✅ Persistent conversation history
- ✅ Professional error handling
- ✅ Mobile-optimized design

**Total implementation**: 1 Edge Function + 1 Vue component + Environment config

**Much simpler than the original Realtime API approach!** 🎉

