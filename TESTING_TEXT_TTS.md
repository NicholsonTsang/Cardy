# Testing Guide: Text + TTS Implementation

## 🧪 Quick Testing Checklist

### **Before Testing:**
1. ✅ Edge Function deployed: `generate-tts-audio`
2. ✅ Frontend updated: `MobileAIAssistant.vue`
3. ✅ Configuration updated: `config.toml`
4. ⚠️ Production secrets set (if testing production)

---

## 🔍 Local Testing

### **1. Start Development Server**
```bash
npm run dev
```

### **2. Navigate to Mobile Client**
1. Go to `http://localhost:5173`
2. Click on any card (or create a test card)
3. View the card in mobile client
4. Navigate to a content item
5. Click "Ask AI Assistant" button

### **3. Test Text Input (Streaming)**
**Expected Behavior:**
- Type a question: "Tell me more about this exhibit"
- Press Enter or click Send
- Text should start appearing immediately (~1s)
- Text should stream progressively (word by word or chunk by chunk)
- No audio plays (text-only input)

**Success Criteria:**
- ✅ Text appears within 1-2s
- ✅ Text streams progressively
- ✅ Loading indicator disappears when done
- ✅ No errors in console

### **4. Test Voice Input (Text + TTS)**
**Expected Behavior:**
1. Switch to voice mode (microphone icon)
2. Hold "Hold to talk" button
3. Speak: "What is this artifact made of?"
4. Release button
5. See "Processing voice input..." (~1s)
6. Text appears (~1-2s total)
7. Audio starts playing (~2-4s total)

**Success Criteria:**
- ✅ Recording starts when button pressed
- ✅ Waveform shows during recording
- ✅ Text appears within 1-2s of release
- ✅ Audio plays shortly after text appears
- ✅ Text remains visible while audio plays
- ✅ No errors in console

**Key Check:** Text should appear BEFORE audio plays!

---

## 📊 Console Monitoring

### **Expected Console Logs (Voice Input):**

```javascript
// Step 1: Recording
"Starting recording..."
"Recording started successfully"

// Step 2: Processing
"Processing voice input, blob size: 12345, type: audio/webm"
"Converting audio from audio/webm to wav format"
"Audio converted to wav, new size: 67890"
"Audio ready for API, format: wav, base64 length: 91234"

// Step 3: Text Generation
"Getting AI response for voice input (Text + TTS approach)"
"Sending voice input to Edge Function for transcription + text generation..."
"Received text response:", {data}

// Step 4: TTS Generation (parallel)
"Generating TTS audio for text:", "This artifact is made of..."
"TTS audio generated, size: 45678"
```

### **No Errors Should Appear:**
- ❌ "TTS generation failed" - Check OpenAI API key
- ❌ "Failed to fetch" - Check Edge Function deployment
- ❌ "CORS error" - Check Edge Function CORS headers
- ❌ "Tainted canvas" - Should be fixed now

---

## 🎯 Performance Testing

### **Measure Response Times:**

Open browser DevTools → Network tab:

#### **Text Input:**
1. Send text message
2. Look for: `POST /functions/v1/chat-with-audio-stream`
3. **Target:** <2s for first chunk
4. **Target:** <3s for complete response

#### **Voice Input:**
1. Send voice message
2. Look for: 
   - `POST /functions/v1/chat-with-audio` (STT + text)
   - `POST /functions/v1/generate-tts-audio` (TTS)
3. **Target:** <2s for text
4. **Target:** <4s total for text + audio

---

## 💰 Cost Testing

### **Monitor OpenAI Dashboard:**

1. Go to https://platform.openai.com/usage
2. Track costs during testing session
3. **Expected cost per voice response:** ~$0.0075

**Cost Breakdown:**
- Text generation (STT + response): ~$0.0003
- TTS generation: ~$0.0072
- **Total:** ~$0.0075

**If costs are higher:**
- Check if using `gpt-4o` instead of `gpt-4o-mini`
- Check if using `tts-1-hd` instead of `tts-1`
- Check if using audio model instead of text model

---

## 🐛 Common Issues & Solutions

### **Issue 1: Text appears but no audio**
**Symptoms:** Text shows up, but no audio plays, console shows TTS error
**Cause:** TTS generation failed (non-blocking)
**Solutions:**
1. Check `OPENAI_API_KEY` is set
2. Check `OPENAI_TTS_MODEL` secret
3. Check OpenAI API status
4. Check browser audio permissions

**Note:** This is non-blocking by design - text should still work!

---

### **Issue 2: No text appears**
**Symptoms:** Loading forever, no text, error in console
**Cause:** Text generation failed (blocking)
**Solutions:**
1. Check Edge Function deployed: `chat-with-audio`
2. Check `OPENAI_API_KEY` is set
3. Check `OPENAI_AUDIO_MODEL` secret
4. Check OpenAI account status
5. Check browser console for error details

---

### **Issue 3: Slow response (>5s)**
**Symptoms:** Text takes >5s to appear
**Cause:** Wrong model or network issues
**Solutions:**
1. Verify using `gpt-4o-mini` (not `gpt-4o`)
2. Check `OPENAI_MAX_TOKENS` (should be 3500)
3. Check network connectivity
4. Check OpenAI API status

---

### **Issue 4: Audio format error**
**Symptoms:** "Invalid audio format" or garbled audio
**Cause:** Format mismatch
**Solutions:**
1. Verify `OPENAI_AUDIO_FORMAT=wav`
2. Check browser audio codec support
3. Try `mp3` format if `wav` fails

---

### **Issue 5: Recording doesn't start**
**Symptoms:** Button doesn't record, no waveform
**Cause:** Microphone permissions
**Solutions:**
1. Grant microphone permissions in browser
2. Use HTTPS (not HTTP) for testing
3. Check browser compatibility
4. Check console for permission errors

---

## ✅ Test Scenarios

### **Scenario 1: Basic Voice Interaction**
1. Open AI Assistant
2. Switch to voice mode
3. Hold button and say: "Hello, can you hear me?"
4. Release button
5. Verify text appears quickly
6. Verify audio plays

**Expected:** Full cycle <4s

---

### **Scenario 2: Long Response**
1. Ask a complex question (voice or text)
2. Example: "Can you explain the history and significance of this artifact in detail?"
3. Verify text streams/appears
4. For voice: verify audio plays

**Expected:** Text starts <2s, audio plays after text visible

---

### **Scenario 3: Multiple Conversations**
1. Send 5 messages in a row (mix of text and voice)
2. Verify each response is correct
3. Verify conversation context maintained
4. Monitor total cost in OpenAI dashboard

**Expected:** ~$0.0075 per voice response, ~$0.0001 per text response

---

### **Scenario 4: Error Recovery**
1. Disconnect internet
2. Try sending a message
3. Reconnect internet
4. Try sending another message

**Expected:** Error message shown, then recovers successfully

---

### **Scenario 5: Different Languages**
1. Select different language (e.g., Spanish)
2. Send voice message
3. Verify response in Spanish
4. Verify audio in Spanish

**Expected:** All responses in selected language

---

## 📊 Success Criteria Summary

### **Performance:**
- ✅ Text appears within 1-2s (voice input)
- ✅ Text streams within 1s (text input)
- ✅ Audio plays within 2-4s total (voice input)
- ✅ Total response time <4s (voice)
- ✅ Total response time <3s (text)

### **Cost:**
- ✅ Voice response: ~$0.0075
- ✅ Text response: ~$0.0001
- ✅ 7x cheaper than previous audio model

### **User Experience:**
- ✅ No blocking (text appears immediately)
- ✅ Audio failure doesn't break text display
- ✅ Smooth conversation flow
- ✅ Clear visual feedback
- ✅ Error messages are user-friendly

### **Technical:**
- ✅ No console errors
- ✅ No CORS errors
- ✅ No audio format errors
- ✅ Proper error handling
- ✅ Memory leaks cleaned up

---

## 🚀 Production Testing

### **Before Deploying to Production:**
1. Test all scenarios in local development
2. Verify costs in OpenAI dashboard
3. Test on multiple browsers (Chrome, Safari, Firefox)
4. Test on mobile devices
5. Test with different network speeds

### **After Deploying to Production:**
1. Deploy Edge Functions:
   ```bash
   npx supabase functions deploy generate-tts-audio
   npx supabase functions deploy chat-with-audio-stream
   ```

2. Set production secrets:
   ```bash
   ./scripts/setup-production-secrets.sh
   ```

3. Test production URL
4. Monitor costs for 24 hours
5. Gather user feedback

---

## 📈 Monitoring Metrics

### **Track These Metrics:**
1. **Response Times:**
   - Time to first text: <2s target
   - Total response time: <4s target

2. **Error Rates:**
   - STT failures: <1% target
   - TTS failures: <5% acceptable (non-blocking)
   - Text generation failures: <1% target

3. **Costs:**
   - Cost per voice response: ~$0.0075
   - Cost per text response: ~$0.0001
   - Monthly total: Track vs. budget

4. **User Engagement:**
   - Voice input usage rate
   - Audio replay rate
   - Conversation length
   - User satisfaction

---

## 🎉 Testing Complete!

Once all tests pass:
- ✅ Mark testing as complete
- ✅ Deploy to production
- ✅ Monitor for 1 week
- ✅ Gather user feedback
- ✅ Consider Phase 2 optimizations

**Expected Result:** 7x cost savings + faster responses + better UX! 🚀

