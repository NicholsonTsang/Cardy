# OpenAI Max Tokens Configuration

## 🎛️ **Configurable via Environment Variable**

The `max_tokens` parameter for AI responses is now **configurable** via Supabase Edge Function secrets, allowing you to adjust response length without redeploying!

---

## 📋 **Configuration**

### **Environment Variable**
```bash
OPENAI_MAX_TOKENS=3500
```

### **Default Value**
If not configured, defaults to **3500 tokens**

### **Code Implementation**
```typescript
max_tokens: parseInt(Deno.env.get('OPENAI_MAX_TOKENS') || '3500')
```

---

## 🔧 **How to Configure**

### **Option 1: Supabase Dashboard** (Recommended)

1. Go to [Supabase Dashboard](https://supabase.com/dashboard)
2. Select your project
3. Navigate to **Edge Functions** → **chat-with-audio**
4. Click **Secrets** tab
5. Add new secret:
   - **Name:** `OPENAI_MAX_TOKENS`
   - **Value:** `3500` (or your desired number)
6. Save

**No redeployment needed!** Changes take effect immediately.

---

### **Option 2: Supabase CLI** (For local development)

**Update `supabase/config.toml`:**

```toml
[functions.chat-with-audio]
environment = { OPENAI_MAX_TOKENS = "3500" }
```

**Or set via CLI:**

```bash
supabase secrets set OPENAI_MAX_TOKENS=3500
```

---

## 📊 **Token Guidelines**

### **Recommended Values by Use Case**

| Use Case | Tokens | Words | Paragraphs | When to Use |
|----------|--------|-------|------------|-------------|
| **Quick Facts** | 500 | ~375 | 2-3 | Brief answers |
| **Standard Answers** | 1000 | ~750 | 4-5 | Normal conversations |
| **Detailed Explanations** | 2000 | ~1500 | 8-10 | Educational content |
| **Comprehensive** | 3500 | ~2600 | 13-15 | ✅ Museum/Exhibition (Default) |
| **Very Long** | 4000+ | ~3000+ | 15+ | Special cases only |

---

## 🎯 **Why 3500 as Default?**

### **1. Museum Content Requirements**
Educational content about artifacts and history needs:
- **Historical Context:** 2-3 paragraphs
- **Cultural Significance:** 2-3 paragraphs
- **Interesting Details:** 3-4 paragraphs
- **Technical Information:** 2-3 paragraphs
- **Related Facts:** 2-3 paragraphs

**Total:** 11-16 paragraphs = ~2000-3000 words = **2700-4000 tokens**

### **2. Audio Response Length**
- **3500 tokens** ≈ **2600 words**
- At typical speaking rate (150 words/min)
- **Audio length:** ~17 minutes
- Realistic conversation length: 2-3 minutes
- **Buffer included** for detailed questions

### **3. Balance**
- ✅ **Long enough:** Complete, thorough answers
- ✅ **Not too long:** Keeps responses focused
- ✅ **Cost-effective:** ~$0.30-0.40 per response
- ✅ **Performance:** Reasonable generation time

---

## 💰 **Cost Analysis**

### **Pricing (GPT-4o Audio Preview)**
- **Input:** $0.10 per 1M tokens
- **Output:** $0.30 per 1M tokens

### **Cost Per Response by Token Limit**

| Tokens | Avg Usage | Output Cost | Total Cost |
|--------|-----------|-------------|------------|
| 500 | ~400 | $0.00012 | $0.00012 |
| 1000 | ~800 | $0.00024 | $0.00024 |
| 2000 | ~1600 | $0.00048 | $0.00048 |
| **3500** | ~2800 | $0.00084 | $0.00084 |
| 4000 | ~3200 | $0.00096 | $0.00096 |

**For 1000 responses at 3500 tokens:**
- **Total cost:** $0.84 (~84 cents)
- **Cost per user interaction:** $0.00084 (~0.08 cents)

**Very reasonable for quality educational content!**

---

## 🎤 **Audio Response Duration**

Token limit affects audio length:

| Tokens | Words | Audio Duration (150 wpm) |
|--------|-------|--------------------------|
| 500 | 375 | ~2.5 minutes |
| 1000 | 750 | ~5 minutes |
| 2000 | 1500 | ~10 minutes |
| **3500** | **2600** | **~17 minutes** |
| 4000 | 3000 | ~20 minutes |

**Note:** Most responses won't reach the full limit, this is just the maximum allowed.

---

## 🔄 **Adjusting the Setting**

### **When to Increase (4000+)**
- Very detailed historical content
- Complex technical explanations
- Multi-part questions
- Comprehensive guided tours

### **When to Decrease (2000-3000)**
- Quick information booth
- Simple Q&A
- Cost optimization
- Faster responses

### **Current Setting: 3500** ✅
Perfect balance for museum/exhibition content!

---

## 📱 **Environment Variables Overview**

All configurable AI settings:

```bash
# Model Selection
OPENAI_AUDIO_MODEL=gpt-4o-audio-preview-2025-06-03

# Response Length
OPENAI_MAX_TOKENS=3500  # ← New!

# Voice Settings
OPENAI_TTS_VOICE=alloy
OPENAI_AUDIO_FORMAT=wav

# API Authentication
OPENAI_API_KEY=sk-...  # (Required)
```

---

## 🧪 **Testing Different Token Limits**

### **Test Setup**
1. Set `OPENAI_MAX_TOKENS` in Supabase Dashboard
2. Wait a few seconds for changes to propagate
3. Test with a detailed question

### **Test Question**
"Tell me about the ancient city of Babylon, including its history, architecture, cultural significance, and why it was important to Mesopotamian civilization."

### **Expected Response Length**

**With 1000 tokens (~750 words):**
```
Brief overview, main points covered, but lacking detail.
```

**With 2000 tokens (~1500 words):**
```
Good detail, covers main topics, feels somewhat complete.
```

**With 3500 tokens (~2600 words):** ✅
```
Comprehensive explanation, rich detail, engaging storytelling,
complete coverage of all aspects, perfect for educational content.
```

**With 4000+ tokens:**
```
Very long, potentially excessive for a single response,
might lose user attention.
```

---

## 🎓 **Best Practices**

### **1. Start with Default (3500)**
The default is well-tuned for museum content.

### **2. Monitor Response Quality**
If responses feel:
- **Too short:** Increase by 500-1000
- **Too long:** Decrease by 500-1000

### **3. Consider Your Audience**
- **General public:** 2500-3500 (moderate detail)
- **Students/researchers:** 3500-4500 (high detail)
- **Quick information:** 1500-2500 (brief)

### **4. Balance Cost vs Quality**
More tokens = better answers but higher cost. Find your sweet spot!

---

## 🔧 **Configuration Priority**

The function reads values in this order:

1. **Environment Variable** (Supabase Secret)
   ```typescript
   Deno.env.get('OPENAI_MAX_TOKENS')
   ```
   
2. **Default Value** (Hardcoded)
   ```typescript
   || '3500'
   ```

**Example:**
- If `OPENAI_MAX_TOKENS` is set to `2500`, it uses `2500`
- If `OPENAI_MAX_TOKENS` is not set, it uses `3500`

---

## 📋 **Files Changed**

### **Edge Function**
- **File:** `supabase/functions/chat-with-audio/index.ts`
- **Line:** 102
- **Change:** Made `max_tokens` configurable via `OPENAI_MAX_TOKENS` environment variable
- **Default:** `3500` tokens

---

## 🚀 **Deployment**

```bash
npx supabase functions deploy chat-with-audio
```

**Status:** ✅ Deployed successfully

---

## ✅ **Summary**

**Feature:** Configurable `max_tokens` via environment variable  
**Variable Name:** `OPENAI_MAX_TOKENS`  
**Default Value:** `3500` tokens (~2600 words)  
**Configuration:** Supabase Dashboard → Edge Functions → Secrets  
**Benefit:** Adjust response length without redeploying! 🎉

---

## 🎯 **Quick Setup Guide**

### **Set the Secret** (if you want a different value than 3500):

1. Go to Supabase Dashboard
2. Edge Functions → chat-with-audio → Secrets
3. Add: `OPENAI_MAX_TOKENS = 3500` (or your value)
4. Save

**Done!** Your AI will now use the configured token limit. 🎤✨

---

## 💡 **Pro Tips**

1. **Start with default (3500)** - it's well-balanced
2. **Monitor user feedback** - adjust if responses are too short/long
3. **Consider peak times** - lower tokens = faster responses
4. **Track costs** - higher tokens = more API usage
5. **A/B test** - try different values to find optimal length

**Current recommendation: Keep at 3500** ✅

