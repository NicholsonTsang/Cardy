# STT (Speech-to-Text) Configuration Guide

## 🎤 Overview

The AI assistant now supports **configurable STT (Speech-to-Text)** with two modes:

1. **Audio Model** (Default) - Uses `gpt-4o-mini-audio-preview` for STT + text generation
2. **Whisper** (Optional) - Uses separate Whisper API for STT, then text model for generation

---

## 🔧 Configuration

### **Environment Variable: `OPENAI_STT_MODE`**

Set this to choose your STT approach:

```bash
# Option 1: Audio Model (Default - Recommended)
OPENAI_STT_MODE=audio-model

# Option 2: Whisper API (Slightly cheaper)
OPENAI_STT_MODE=whisper
```

---

## 📊 Comparison: Audio Model vs Whisper

### **Option 1: Audio Model (Default)**

**Architecture:**
```
Voice Input → [gpt-4o-mini-audio-preview] → STT + Text Response
                                                    ↓
                                            [generate-tts-audio]
                                                    ↓
                                            Audio Output
```

**Characteristics:**
- ✅ Single API call for STT + text generation
- ✅ High-quality transcription
- ✅ Context-aware (understands audio nuances)
- ✅ Simpler architecture
- ❌ Slightly more expensive (~$0.0003)

**Cost Breakdown:**
- STT + Text Generation: ~$0.0003
- TTS: ~$0.0072
- **Total: ~$0.0075 per voice response**

---

### **Option 2: Whisper API**

**Architecture:**
```
Voice Input → [Whisper API] → Transcription
                                    ↓
                          [gpt-4o-mini] → Text Response
                                    ↓
                          [generate-tts-audio]
                                    ↓
                          Audio Output
```

**Characteristics:**
- ✅ Slightly cheaper (~$0.0001 for STT)
- ✅ Dedicated transcription model
- ✅ More modular (can swap STT providers)
- ❌ Two API calls (more latency)
- ❌ More complex architecture
- ❌ Slightly slower (~500ms more)

**Cost Breakdown:**
- STT (Whisper): ~$0.0001
- Text Generation: ~$0.0002
- TTS: ~$0.0072
- **Total: ~$0.0073 per voice response**

---

## 💰 Cost Comparison

| Component | Audio Model | Whisper Mode | Difference |
|-----------|-------------|--------------|------------|
| **STT** | Included | $0.0001 | - |
| **Text Gen** | $0.0003 | $0.0002 | -$0.0001 |
| **TTS** | $0.0072 | $0.0072 | $0 |
| **Total** | **$0.0075** | **$0.0073** | **-$0.0002** |

**Savings with Whisper:** $0.0002 per response (2.6% cheaper)

**Annual Savings (10k interactions/month):**
- Audio Model: $900/year
- Whisper Mode: $876/year
- **Savings: $24/year**

**Verdict:** Minimal savings, not worth the added complexity for most use cases.

---

## ⚡ Performance Comparison

| Metric | Audio Model | Whisper Mode | Winner |
|--------|-------------|--------------|---------|
| **API Calls** | 2 (STT+Text, TTS) | 3 (Whisper, Text, TTS) | Audio Model |
| **Latency** | ~2-4s total | ~2.5-4.5s total | Audio Model |
| **Time to Text** | ~1-2s | ~1.5-2.5s | Audio Model |
| **Reliability** | Single point | Two points | Audio Model |
| **Transcription Quality** | Excellent | Excellent | Tie |

**Winner: Audio Model** (simpler, faster, fewer failure points)

---

## 🎯 Recommendations

### **For Most Users: Use Audio Model (Default)** ✅

**Why:**
- ✅ Simpler architecture (fewer moving parts)
- ✅ Faster response time (~500ms faster)
- ✅ Single API call for STT + text
- ✅ Already optimized (7x cheaper than before)
- ✅ Cost difference is negligible ($24/year at 10k interactions)

**When to use:**
- Default for all production deployments
- When simplicity and speed matter
- When cost difference is insignificant

---

### **When to Consider Whisper Mode:** ⚠️

**Use cases:**
- Very high volume (>100k interactions/month) where $24/year becomes significant
- Need to swap STT providers in the future
- Experimenting with different STT models
- Specific transcription quality requirements

**Trade-offs:**
- ✅ Slightly cheaper ($0.0002 per response)
- ❌ More complex (two API calls)
- ❌ Slower (~500ms more latency)
- ❌ More failure points

---

## 🛠️ Configuration Steps

### **Local Development**

**1. Edit `supabase/config.toml`:**

```toml
# STT Configuration (Speech-to-Text for voice input)
# Options: "audio-model" (default) or "whisper"
OPENAI_STT_MODE = "audio-model"  # or "whisper"
OPENAI_AUDIO_MODEL = "gpt-4o-mini-audio-preview"
OPENAI_WHISPER_MODEL = "whisper-1"
```

**2. Restart local Supabase:**
```bash
supabase stop
supabase start
```

**3. Test:**
```bash
npm run dev
# Test voice input in AI Assistant
# Check console for "STT Mode: audio-model" or "STT Mode: whisper"
```

---

### **Production Deployment**

**1. Set via Supabase CLI:**

```bash
# Option 1: Audio Model (Default)
supabase secrets set OPENAI_STT_MODE=audio-model

# Option 2: Whisper API
supabase secrets set OPENAI_STT_MODE=whisper
```

**2. Set model configurations:**
```bash
supabase secrets set OPENAI_AUDIO_MODEL=gpt-4o-mini-audio-preview
supabase secrets set OPENAI_WHISPER_MODEL=whisper-1
supabase secrets set OPENAI_TEXT_MODEL=gpt-4o-mini
```

**3. Deploy Edge Function:**
```bash
npx supabase functions deploy chat-with-audio
```

**4. Test production:**
- Navigate to production mobile client
- Test voice input
- Check Supabase Edge Function logs for STT mode

---

### **Interactive Setup Script**

Use the setup script for easy configuration:

```bash
./scripts/setup-production-secrets.sh
```

The script will prompt you for:
- STT mode (audio-model or whisper)
- Audio model name
- Whisper model name
- Text model name
- TTS configuration

---

## 🧪 Testing

### **Verify STT Mode:**

**1. Send voice input in AI Assistant**

**2. Check browser console:**
```javascript
// You should see one of:
"STT Mode: audio-model"
// or
"STT Mode: whisper"
```

**3. Check Supabase Edge Function logs:**
```
# Audio Model mode:
"STT Mode: audio-model"
"Using Audio Model for STT..."
"Using model: gpt-4o-mini-audio-preview"

# Whisper mode:
"STT Mode: whisper"
"Using Whisper API for STT..."
"Whisper transcription: [your speech]"
"Using model: gpt-4o-mini"
```

---

### **Performance Testing:**

**Audio Model:**
- Expected time to text: ~1-2s
- Expected total time: ~2-4s

**Whisper Mode:**
- Expected time to text: ~1.5-2.5s
- Expected total time: ~2.5-4.5s

**If slower than expected:**
1. Check network connectivity
2. Check OpenAI API status
3. Verify model configurations
4. Monitor OpenAI dashboard for throttling

---

## 💡 Advanced Configuration

### **Custom Whisper Settings:**

```bash
# Use different Whisper model
OPENAI_WHISPER_MODEL=whisper-1

# Note: Only whisper-1 is currently available
# OpenAI may release whisper-2, whisper-large in the future
```

### **Custom Audio Model:**

```bash
# Use full-size audio model (better quality, higher cost)
OPENAI_AUDIO_MODEL=gpt-4o-audio-preview

# Note: This is ~2x more expensive
# Cost per response: ~$0.015 (vs $0.0075)
```

### **A/B Testing:**

To compare both modes:

1. **Split traffic between modes**
2. **Monitor metrics:**
   - Response time
   - Transcription accuracy
   - User satisfaction
   - Total cost
3. **Choose winner based on data**

---

## 📊 Monitoring

### **Key Metrics:**

**Cost Metrics:**
- Cost per voice response
- Total monthly STT cost
- STT cost vs TTS cost ratio

**Performance Metrics:**
- Time to transcription
- Time to text response
- Total response time
- API latency

**Quality Metrics:**
- Transcription accuracy
- User satisfaction
- Retry rate
- Error rate

---

## 🐛 Troubleshooting

### **Issue: "STT Mode not changing"**
**Cause:** Environment variable not set correctly
**Solution:**
1. Verify secret is set: `supabase secrets list`
2. Redeploy function: `npx supabase functions deploy chat-with-audio`
3. Check logs for "STT Mode: [mode]"

---

### **Issue: "Whisper API failed"**
**Cause:** Audio format or API issue
**Solution:**
1. Check audio format is supported (wav, mp3)
2. Verify OpenAI API key has Whisper access
3. Check OpenAI API status
4. Fall back to audio-model mode

---

### **Issue: "Higher costs than expected"**
**Cause:** Using wrong model or mode
**Solution:**
1. Verify using `gpt-4o-mini-audio-preview` (not `gpt-4o-audio-preview`)
2. Check STT mode: `supabase secrets list | grep STT_MODE`
3. Monitor OpenAI dashboard for actual usage

---

## 🎉 Summary

### **Default Configuration (Recommended):**

```toml
OPENAI_STT_MODE = "audio-model"
OPENAI_AUDIO_MODEL = "gpt-4o-mini-audio-preview"
OPENAI_TEXT_MODEL = "gpt-4o-mini"
OPENAI_TTS_MODEL = "tts-1"
```

**Why this is best:**
- ✅ Fastest response time
- ✅ Simplest architecture
- ✅ Fewest failure points
- ✅ Already 7x cheaper than before
- ✅ Cost difference with Whisper is negligible

**Cost:** ~$0.0075 per voice response  
**Performance:** Text in ~1-2s, audio in ~2-4s  
**Annual Cost (10k/month):** ~$900

---

### **Alternative Configuration (Whisper):**

```toml
OPENAI_STT_MODE = "whisper"
OPENAI_WHISPER_MODEL = "whisper-1"
OPENAI_TEXT_MODEL = "gpt-4o-mini"
OPENAI_TTS_MODEL = "tts-1"
```

**When to use:**
- Very high volume (>100k/month)
- Need modular STT architecture
- Want maximum cost optimization

**Cost:** ~$0.0073 per voice response (-2.6%)  
**Performance:** Text in ~1.5-2.5s, audio in ~2.5-4.5s  
**Annual Cost (10k/month):** ~$876 (saves $24/year)

---

## 🚀 Next Steps

1. ✅ Keep default `audio-model` mode for simplicity
2. ✅ Monitor costs and performance for 1 month
3. ⚠️ Consider Whisper mode only if volume is very high
4. ✅ Focus on user experience over micro-optimization

**Bottom Line:** The default audio-model configuration is already optimized (7x cheaper than before). Switching to Whisper saves only $24/year at 10k interactions, which is not worth the added complexity. 🎯

