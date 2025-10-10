# Voice Configuration for 10 Languages

## 📋 Summary

This document defines the optimal voice selections for each supported language across three OpenAI APIs:
1. **Text-to-Speech (TTS)** - `tts-1` model with 6 voices
2. **Speech-to-Text (STT)** - Whisper model (language-agnostic)
3. **Realtime API** - WebRTC with 10 voices

---

## 🎤 Supported Voices by API

### **TTS API Voices** (`tts-1` model)
Available voices: `alloy`, `echo`, `fable`, `onyx`, `nova`, `shimmer`

| Voice | Gender | Characteristics | Best For |
|-------|--------|-----------------|----------|
| `alloy` | Neutral | Balanced, versatile | General use, English |
| `echo` | Male | Clear, professional | Business, formal |
| `fable` | Male | British accent, storytelling | European languages |
| `onyx` | Male | Deep, authoritative | Professional content |
| `nova` | Female | Warm, energetic | Asian languages, friendly |
| `shimmer` | Female | Soft, upbeat | Calming, educational |

### **Realtime API Voices**
Available voices: `alloy`, `ash`, `ballad`, `coral`, `echo`, `sage`, `shimmer`, `verse`, `marin`, `cedar`

| Voice | Gender | Characteristics | Best For |
|-------|--------|-----------------|----------|
| `alloy` | Neutral | Balanced, versatile | General use, English |
| `ash` | Female | Clear, professional | Business applications |
| `ballad` | Female | Warm, conversational | European languages |
| `coral` | Female | Friendly, energetic | Asian languages |
| `echo` | Male | Clear, authoritative | Professional content |
| `sage` | Male | Deep, calm | Formal languages |
| `shimmer` | Female | Soft, calming | Educational content |
| `verse` | Female | Young, upbeat | Casual conversation |
| `marin` | Male | Natural, friendly | General conversation |
| `cedar` | Male | Warm, reassuring | Customer service |

### **STT (Whisper) API**
- **Model**: `whisper-1` (language-agnostic)
- **Capability**: Automatically detects and transcribes 57+ languages
- **No voice selection needed** - input is user's voice

---

## 🌍 Voice Configuration by Language

### **1. 🇺🇸 English (en)**

| API | Voice | Reasoning |
|-----|-------|-----------|
| **TTS** | `alloy` | Neutral, widely accepted, versatile for all English speakers |
| **STT** | `whisper-1` | Auto-detects English accents (US, UK, Australian, etc.) |
| **Realtime** | `alloy` | Consistent with TTS, natural conversational tone |

**Alternative Options:**
- `echo` (male, professional)
- `shimmer` (female, friendly)

---

### **2. 🇭🇰 Cantonese (zh-HK)**

| API | Voice | Reasoning |
|-----|-------|-----------|
| **TTS** | `nova` | Female, warm and energetic - suits Cantonese tone patterns |
| **STT** | `whisper-1` | Excellent Cantonese recognition (Hong Kong accent) |
| **Realtime** | `coral` | Female, friendly - natural for conversational Cantonese |

**Alternative Options:**
- `shimmer` (softer, calming tone)
- `verse` (younger, more upbeat)

**Note:** OpenAI TTS/Realtime speaks Cantonese phonetically using Mandarin pronunciation. For authentic Cantonese pronunciation, consider Azure Speech Services or Google Cloud TTS.

---

### **3. 🇨🇳 Mandarin (zh-CN)**

| API | Voice | Reasoning |
|-----|-------|-----------|
| **TTS** | `nova` | Female, clear pronunciation for tonal language |
| **STT** | `whisper-1` | Excellent Mandarin recognition (China, Taiwan accents) |
| **Realtime** | `coral` | Female, natural for Mandarin conversations |

**Alternative Options:**
- `shimmer` (softer, educational tone)
- `alloy` (neutral, professional)

**Note:** Works well for both Simplified and Traditional Chinese text.

---

### **4. 🇯🇵 Japanese (ja)**

| API | Voice | Reasoning |
|-----|-------|-----------|
| **TTS** | `shimmer` | Female, soft tone suits Japanese politeness culture |
| **STT** | `whisper-1` | Excellent Japanese recognition (Tokyo, Kansai accents) |
| **Realtime** | `shimmer` | Consistent soft tone, culturally appropriate |

**Alternative Options:**
- `nova` (more energetic)
- `ballad` (warmer, conversational)

**Cultural Note:** Female voices are culturally preferred for customer service and educational content in Japan.

---

### **5. 🇰🇷 Korean (ko)**

| API | Voice | Reasoning |
|-----|-------|-----------|
| **TTS** | `nova` | Female, energetic - suits Korean speaking patterns |
| **STT** | `whisper-1` | Excellent Korean recognition (Seoul, Busan accents) |
| **Realtime** | `coral` | Female, friendly - natural for Korean conversations |

**Alternative Options:**
- `shimmer` (softer, more formal)
- `verse` (younger, casual)

**Cultural Note:** Female voices are commonly used in Korean customer service and navigation systems.

---

### **6. 🇹🇭 Thai (th)**

| API | Voice | Reasoning |
|-----|-------|-----------|
| **TTS** | `shimmer` | Female, soft and calming - culturally appropriate for Thai |
| **STT** | `whisper-1` | Good Thai recognition (Central Thai, Isaan accents) |
| **Realtime** | `shimmer` | Consistent soft tone, culturally respectful |

**Alternative Options:**
- `nova` (more energetic)
- `coral` (friendlier)

**Cultural Note:** Thai culture values politeness and gentle communication styles.

---

### **7. 🇪🇸 Spanish (es)**

| API | Voice | Reasoning |
|-----|-------|-----------|
| **TTS** | `echo` | Male, clear - works for both Spain and Latin America |
| **STT** | `whisper-1` | Excellent Spanish recognition (Spain, Mexico, Argentina accents) |
| **Realtime** | `echo` | Consistent clear tone, authoritative and professional |

**Alternative Options:**
- `fable` (British-accented English, but works for European Spanish)
- `marin` (male, natural and friendly)
- `nova` (female alternative)

**Regional Note:** Voice works for all Spanish-speaking regions (Spain, Mexico, Argentina, etc.)

---

### **8. 🇫🇷 French (fr)**

| API | Voice | Reasoning |
|-----|-------|-----------|
| **TTS** | `fable` | Male, warm storytelling tone - suits French elegance |
| **STT** | `whisper-1` | Excellent French recognition (France, Quebec, Belgian accents) |
| **Realtime** | `ballad` | Female, warm and conversational - natural for French |

**Alternative Options:**
- `shimmer` (female, softer)
- `sage` (male, more formal)

**Cultural Note:** French audiences appreciate elegant, clear pronunciation.

---

### **9. 🇷🇺 Russian (ru)**

| API | Voice | Reasoning |
|-----|-------|-----------|
| **TTS** | `onyx` | Male, deep and authoritative - suits Russian language gravitas |
| **STT** | `whisper-1` | Good Russian recognition (Moscow, St. Petersburg accents) |
| **Realtime** | `sage` | Male, deep and calm - culturally appropriate |

**Alternative Options:**
- `echo` (male, clearer)
- `cedar` (male, warmer)

**Cultural Note:** Russian culture values authoritative, clear communication.

---

### **10. 🇸🇦 Arabic (ar)**

| API | Voice | Reasoning |
|-----|-------|-----------|
| **TTS** | `onyx` | Male, authoritative - culturally appropriate for Arabic |
| **STT** | `whisper-1` | Good Arabic recognition (MSA, Egyptian, Gulf accents) |
| **Realtime** | `sage` | Male, calm and respectful - culturally appropriate |

**Alternative Options:**
- `echo` (male, clearer)
- `cedar` (male, warmer)

**Cultural Note:** Male voices are culturally preferred for professional and educational content in Arabic-speaking regions.

---

## 📊 Voice Selection Summary Table

| Language | TTS Voice | Realtime Voice | Gender | Rationale |
|----------|-----------|----------------|--------|-----------|
| 🇺🇸 English | `alloy` | `alloy` | Neutral | Universal, versatile |
| 🇭🇰 Cantonese | `nova` | `coral` | Female | Energetic, tonal clarity |
| 🇨🇳 Mandarin | `nova` | `coral` | Female | Clear tones, natural |
| 🇯🇵 Japanese | `shimmer` | `shimmer` | Female | Soft, culturally appropriate |
| 🇰🇷 Korean | `nova` | `coral` | Female | Energetic, natural flow |
| 🇹🇭 Thai | `shimmer` | `shimmer` | Female | Soft, respectful |
| 🇪🇸 Spanish | `echo` | `echo` | Male | Clear, professional |
| 🇫🇷 French | `fable` | `ballad` | Mixed | Elegant, conversational |
| 🇷🇺 Russian | `onyx` | `sage` | Male | Authoritative, gravitas |
| 🇸🇦 Arabic | `onyx` | `sage` | Male | Professional, respectful |

**STT (Whisper):** All languages use `whisper-1` (auto-detection)

---

## 🔧 Implementation Code

### **TTS Voice Map (useChatCompletion.ts)**

```typescript
const voiceMap: Record<string, string> = {
  'en': 'alloy',      // English - Neutral, versatile
  'zh-HK': 'nova',    // Cantonese - Female, energetic
  'zh-CN': 'nova',    // Mandarin - Female, clear tones
  'ja': 'shimmer',    // Japanese - Female, soft
  'ko': 'nova',       // Korean - Female, energetic
  'th': 'shimmer',    // Thai - Female, calming
  'es': 'echo',       // Spanish - Male, clear
  'fr': 'fable',      // French - Male, warm
  'ru': 'onyx',       // Russian - Male, authoritative
  'ar': 'onyx'        // Arabic - Male, professional
}
```

### **Realtime API Voice Map (useWebRTCConnection.ts)**

```typescript
const voiceMap: Record<string, string> = {
  'en': 'alloy',      // English - Neutral, versatile
  'zh-HK': 'coral',   // Cantonese - Female, friendly
  'zh-CN': 'coral',   // Mandarin - Female, natural
  'ja': 'shimmer',    // Japanese - Female, soft
  'ko': 'coral',      // Korean - Female, conversational
  'th': 'shimmer',    // Thai - Female, calming
  'es': 'echo',       // Spanish - Male, clear
  'fr': 'ballad',     // French - Female, warm
  'ru': 'sage',       // Russian - Male, calm
  'ar': 'sage'        // Arabic - Male, respectful
}
```

### **STT Configuration (Edge Function)**

```typescript
// Whisper automatically detects language - no configuration needed
const whisperModel = 'whisper-1'

// For audio-model mode (gpt-4o-mini-audio-preview)
const audioModel = Deno.env.get('OPENAI_AUDIO_MODEL') || 'gpt-4o-mini-audio-preview'
```

---

## 🎯 Key Design Principles

### **1. Cultural Appropriateness**
- **Asian Languages**: Female voices preferred (softer, more polite)
- **Middle Eastern Languages**: Male voices preferred (more authoritative)
- **European Languages**: Mixed based on language characteristics

### **2. Consistency**
- TTS and Realtime voices should have similar characteristics
- Maintain consistent gender within language (when possible)

### **3. Tonal Languages**
- **Cantonese, Mandarin, Thai**: Female voices provide clearer tonal differentiation
- **Japanese, Korean**: Female voices align with cultural preferences

### **4. Professional Languages**
- **Russian, Arabic, Spanish**: Male voices convey authority and professionalism

### **5. Fallback Strategy**
- If voice not available, fall back to `alloy` (TTS) or `alloy` (Realtime)
- Always works, neutral for all languages

---

## 🚀 Deployment Configuration

### **Edge Function Secrets (Supabase)**

```bash
# TTS Configuration
OPENAI_TTS_MODEL=tts-1
OPENAI_TTS_VOICE=alloy  # Default fallback

# Realtime Configuration (for Edge Function token generation)
OPENAI_REALTIME_MODEL=gpt-4o-mini-realtime-preview-2024-12-17
OPENAI_REALTIME_VOICE=alloy  # Default fallback
```

### **Frontend Configuration (.env)**

```bash
# No voice configuration needed in frontend
# Voices are dynamically selected based on language
```

---

## 📈 Voice Quality Considerations

### **TTS Models**
- **`tts-1`**: Fast, cost-effective (recommended for production)
- **`tts-1-hd`**: Higher quality, slower, more expensive

### **Realtime Models**
- **`gpt-4o-mini-realtime-preview-2024-12-17`**: Cost-effective, good quality
- **`gpt-4o-realtime-preview-2024-12-17`**: Premium quality, more expensive

### **STT Models**
- **`whisper-1`**: High accuracy, supports 57+ languages
- **`gpt-4o-mini-audio-preview`**: Alternative with integrated AI response

---

## 🔍 Testing Recommendations

### **Per-Language Testing**
1. Test each language with assigned voice
2. Verify pronunciation quality
3. Check cultural appropriateness
4. Gather user feedback

### **A/B Testing**
- Test alternative voices with subset of users
- Measure engagement and satisfaction
- Adjust based on feedback

### **Regional Variations**
- Test accents (e.g., Mexican vs. Spain Spanish)
- Adjust voice selection if needed
- Consider regional preferences

---

## 📝 Notes

### **Voice Availability**
- TTS API: 6 voices (limited but consistent)
- Realtime API: 10 voices (more options, better matching)

### **Language Support**
- All 10 languages are well-supported by Whisper STT
- OpenAI TTS/Realtime may have varying quality by language
- Consider native TTS services for critical applications (Azure, Google Cloud)

### **Future Enhancements**
- User preference selection (let users choose voice)
- Regional voice variants
- Custom voice training (enterprise)
- Multi-voice conversations

---

## 🎬 Conclusion

This configuration provides culturally appropriate, high-quality voice experiences across all 10 supported languages. The voice selections balance:
- **Cultural appropriateness**
- **Audio quality**
- **User expectations**
- **API limitations**

Regular testing and user feedback will help refine these selections over time.

