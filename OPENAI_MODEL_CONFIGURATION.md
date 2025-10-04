# OpenAI Model Configuration Guide

## 🎛️ **Configurable Audio Model**

The AI assistant model is now **fully configurable** via environment variables, with **`gpt-4o-mini-audio-preview`** as the cost-effective default!

---

## 📋 **Current Configuration**

### **Environment Variable**
```bash
OPENAI_AUDIO_MODEL=gpt-4o-mini-audio-preview
```

### **Default Value**
If not configured, defaults to **`gpt-4o-mini-audio-preview`** (most cost-effective)

### **Code Implementation**
```typescript
model: Deno.env.get('OPENAI_AUDIO_MODEL') || 'gpt-4o-mini-audio-preview'
```

---

## 🔧 **How to Change the Model**

### **Via Supabase Dashboard** (Recommended)

1. Go to [Supabase Dashboard](https://supabase.com/dashboard)
2. Select your project
3. Navigate to **Edge Functions** → **chat-with-audio**
4. Click **Secrets** tab
5. Add/Update secret:
   - **Name:** `OPENAI_AUDIO_MODEL`
   - **Value:** Your desired model (see options below)
6. Save

**No redeployment needed!** Changes take effect immediately.

---

### **Via Supabase CLI** (For local development)

```bash
supabase secrets set OPENAI_AUDIO_MODEL=gpt-4o-audio-preview
```

Or update `supabase/config.toml`:
```toml
[functions.chat-with-audio]
environment = { 
  OPENAI_AUDIO_MODEL = "gpt-4o-mini-audio-preview",
  OPENAI_MAX_TOKENS = "3500"
}
```

---

## 🎯 **Available Models**

### **1. gpt-4o-mini-audio-preview** ✅ (Default - Cost-Effective)

**When to use:**
- Development and testing
- Budget-conscious deployments
- Most museum Q&A scenarios
- Standard educational content

**Specs:**
- ✅ Audio input/output
- ✅ Text input/output
- ✅ Multi-language support
- ✅ Good quality responses
- ✅ **Most affordable**

**Pricing:** (Estimated based on GPT-4o-mini patterns)
- Input: ~$0.15 per 1M tokens
- Output: ~$0.60 per 1M tokens
- **~60% cheaper** than gpt-4o-audio-preview

---

### **2. gpt-4o-audio-preview** (High Quality)

**When to use:**
- Production environments
- Premium user experiences
- Complex historical explanations
- High-quality audio required

**Specs:**
- ✅ Audio input/output
- ✅ Text input/output
- ✅ Multi-language support
- ✅ **Best quality responses**
- ✅ More detailed explanations

**Pricing:**
- Input: $2.50 per 1M tokens
- Output: $10.00 per 1M tokens
- Audio Output: $100.00 per 1M tokens

---

### **3. gpt-4o-audio-preview-2025-06-03** (Latest Stable)

**When to use:**
- Need specific version stability
- Production deployments
- Similar to gpt-4o-audio-preview

**Note:** Version-pinned for consistency

---

### **4. gpt-realtime** (Future - Real-time Streaming)

**When to use:**
- Real-time conversational experiences
- Requires Realtime API (different implementation)
- Extremely low latency needed (<400ms)

**Note:** Requires code changes, not a drop-in replacement

---

## 📊 **Model Comparison**

| Feature | gpt-4o-mini-audio | gpt-4o-audio | gpt-realtime |
|---------|-------------------|--------------|--------------|
| **Audio Input** | ✅ | ✅ | ✅ |
| **Audio Output** | ✅ | ✅ | ✅ |
| **Streaming** | ❌ | ❌ | ✅ |
| **Quality** | Good | Excellent | Excellent |
| **Latency** | 5-10s | 5-10s | 0.2-0.4s |
| **Cost (Audio)** | 💰 Low | 💰💰 Medium | 💰💰💰 High |
| **Best For** | Budget | Quality | Real-time |

---

## 💰 **Cost Analysis**

### **Scenario: 1000 Voice Interactions/Day**
**Assumptions:**
- Average response: 500 tokens
- Audio output included

#### **With gpt-4o-mini-audio-preview** (Default) ✅
```
Input:  1000 × 200 tokens × $0.15/1M = $0.03
Output: 1000 × 500 tokens × $0.60/1M = $0.30
Audio:  1000 × 500 tokens × $40/1M  = $20.00 (estimated)
───────────────────────────────────────────────
Total: ~$20.33/day = ~$610/month
```

#### **With gpt-4o-audio-preview**
```
Input:  1000 × 200 tokens × $2.50/1M = $0.50
Output: 1000 × 500 tokens × $10.00/1M = $5.00
Audio:  1000 × 500 tokens × $100/1M  = $50.00
───────────────────────────────────────────────
Total: ~$55.50/day = ~$1,665/month
```

**Savings with mini:** ~$1,055/month (63% cheaper!) 💰

---

## 🎯 **Recommended Configurations**

### **Development** 🔧
```bash
OPENAI_AUDIO_MODEL=gpt-4o-mini-audio-preview  # Default, cost-effective
OPENAI_MAX_TOKENS=2000  # Lower for faster testing
```

### **Staging** 🧪
```bash
OPENAI_AUDIO_MODEL=gpt-4o-mini-audio-preview  # Test with production model
OPENAI_MAX_TOKENS=3500  # Production settings
```

### **Production (Budget)** 💰
```bash
OPENAI_AUDIO_MODEL=gpt-4o-mini-audio-preview  # Cost-optimized
OPENAI_MAX_TOKENS=3500  # Full responses
```

### **Production (Premium)** ⭐
```bash
OPENAI_AUDIO_MODEL=gpt-4o-audio-preview  # Best quality
OPENAI_MAX_TOKENS=3500  # Full responses
```

---

## 🔄 **Switching Models**

### **No Code Changes Required!**

You can switch models anytime by updating the environment variable:

```bash
# Switch to premium model
supabase secrets set OPENAI_AUDIO_MODEL=gpt-4o-audio-preview

# Switch back to mini
supabase secrets set OPENAI_AUDIO_MODEL=gpt-4o-mini-audio-preview

# Use specific version
supabase secrets set OPENAI_AUDIO_MODEL=gpt-4o-audio-preview-2025-06-03
```

**Changes apply immediately** - no redeployment needed!

---

## 🎤 **Quality Comparison**

### **User Question:** "Tell me about the Hanging Gardens of Babylon"

#### **gpt-4o-mini-audio-preview Response:**
> "The Hanging Gardens of Babylon were one of the Seven Wonders of the Ancient World, reportedly built by King Nebuchadnezzar II for his wife. While their exact location and existence are debated by historians, they are described as a remarkable feat of engineering with terraced gardens rising above the ground."

**Quality:** ✅ Good, accurate, clear
**Length:** Moderate detail
**Audio:** Natural, clear voice

---

#### **gpt-4o-audio-preview Response:**
> "The Hanging Gardens of Babylon stand as one of the most legendary and enigmatic of the Seven Wonders of the Ancient World. According to historical accounts, they were commissioned by King Nebuchadnezzar II around 600 BCE, allegedly as a romantic gesture to please his wife, Amytis of Media, who longed for the green hills and valleys of her homeland.
>
> These gardens were described as a spectacular architectural marvel featuring an ascending series of tiered gardens containing a wide variety of trees, shrubs, and vines. The engineering required to irrigate these elevated gardens in the arid Mesopotamian climate would have been extraordinary, possibly using a sophisticated system of chain pumps or screw-type water-lifting devices.
>
> What makes these gardens particularly fascinating is the ongoing archaeological mystery surrounding them. Despite extensive excavations in Babylon, no definitive physical evidence has been found..."

**Quality:** ✅ Excellent, highly detailed, engaging
**Length:** Comprehensive explanation
**Audio:** Very natural, expressive voice

---

### **When Quality Matters:**
- Premium museum experiences
- Detailed historical content
- High-end exhibitions
- Educational programs

### **When mini is Sufficient:**
- General Q&A
- Quick facts
- Budget constraints
- High-volume usage

---

## 🧪 **Testing Recommendations**

### **A/B Testing**

1. **Set up two environments:**
   - Environment A: `gpt-4o-mini-audio-preview`
   - Environment B: `gpt-4o-audio-preview`

2. **Test metrics:**
   - User satisfaction scores
   - Response quality ratings
   - Engagement time
   - Cost per interaction

3. **Determine ROI:**
   - Is 3x cost worth quality improvement?
   - What do users actually prefer?
   - Does it increase engagement?

---

## 📈 **Scaling Strategy**

### **Phase 1: Start with Mini** (Current)
```
Use: gpt-4o-mini-audio-preview
Goal: Validate product-market fit
Cost: Minimal (~$600/month for 1000 daily users)
```

### **Phase 2: Test Premium**
```
Use: gpt-4o-audio-preview for 10% of users
Goal: Measure quality difference
Cost: Slight increase (~$700/month)
```

### **Phase 3: Optimize**
```
Use: Mini for simple questions
Use: Premium for detailed explanations
Goal: Balance cost vs quality
Cost: Optimized based on usage patterns
```

---

## 🎛️ **All Configurable Variables**

```bash
# Model Selection
OPENAI_AUDIO_MODEL=gpt-4o-mini-audio-preview  # ← Default

# Response Length
OPENAI_MAX_TOKENS=3500

# Voice Settings
OPENAI_TTS_VOICE=alloy
OPENAI_AUDIO_FORMAT=wav

# Authentication
OPENAI_API_KEY=sk-...
```

---

## 📋 **Quick Reference**

### **Change to Premium Model**
```bash
supabase secrets set OPENAI_AUDIO_MODEL=gpt-4o-audio-preview
```

### **Change to Cost-Effective Model**
```bash
supabase secrets set OPENAI_AUDIO_MODEL=gpt-4o-mini-audio-preview
```

### **Check Current Setting**
```bash
supabase secrets list
```

---

## ✅ **Summary**

**Default Model:** `gpt-4o-mini-audio-preview` ✅
- Cost-effective
- Good quality
- Perfect for most use cases
- Easily upgradeable

**Configuration:** Via environment variable
- No code changes needed
- Switch anytime
- Instant effect

**Recommendation:** Start with mini, upgrade if needed!

---

## 🎯 **Next Steps**

1. ✅ **Keep default** (gpt-4o-mini-audio-preview) for now
2. ✅ **Monitor user feedback** and response quality
3. ✅ **Track costs** as usage grows
4. ✅ **Test premium model** when budget allows
5. ✅ **Optimize** based on real data

**Your app is now cost-optimized and ready to scale!** 🚀

