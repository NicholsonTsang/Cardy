# AI Assistant Modes - Feature Comparison

## 🎯 Overview

CardStudio's AI Assistant offers **two conversation modes**, each optimized for different use cases and cost profiles.

---

## 📊 Mode Comparison Table

| Feature | Chat Completion | Real-Time Audio |
|---------|----------------|-----------------|
| **Status** | ✅ **Live** | 🎨 **UI Complete** |
| **API** | Chat Completions | Realtime API |
| **Technology** | REST + SSE | WebRTC |
| **Model** | `gpt-4o-mini` | `gpt-4o-mini-realtime-preview` |
| **Input** | Text + Voice (transcribed) | Live audio stream |
| **Output** | Text + TTS (on-demand) | Live audio stream |
| **Latency** | ~2-3s (voice) / <1s (text) | <500ms (target) |
| **Cost per Conv** | ~$0.01 (10 exchanges) | ~$0.06/minute |
| **Cost Factor** | 1x (baseline) | ~6x higher |
| **Best For** | Default, cost-effective | Premium, natural |
| **Languages** | 10 languages | 10 languages |
| **Transcript** | Full chat history | Live transcript |
| **Audio Caching** | ✅ Yes (language-aware) | ❌ No (live only) |
| **Streaming** | ✅ Text streaming (SSE) | ✅ Audio streaming (WebRTC) |
| **Offline Support** | ✅ Text history preserved | ❌ Must be connected |

---

## 🎨 Visual Comparison

### Chat Completion Mode

```
┌────────────────────────────────────┐
│ 💬 AI Assistant │ Ming Vase  📞 × │  ← Header with mode switcher
├────────────────────────────────────┤
│                                    │
│  ┌────────────────────────────┐   │
│  │ You: What is this vase?    │   │  ← User message (blue)
│  └────────────────────────────┘   │
│                                    │
│  ┌────────────────────────────┐   │
│  │ AI: This is a Ming Dynasty │   │  ← AI message (green)
│  │ vase from the 15th century.│   │
│  │ [🔊 Tap to hear]           │   │  ← Audio playback button
│  └────────────────────────────┘   │
│                                    │
│  ┌────────────────────────────┐   │
│  │ You: Tell me more about... │   │
│  └────────────────────────────┘   │
│                                    │
│  ┌────────────────────────────┐   │
│  │ AI: [Streaming...]         │   │  ← Streaming response
│  └────────────────────────────┘   │
│                                    │
├────────────────────────────────────┤
│ [Type a message...]                │  ← Text input
│                 [🎤] [Send]        │  ← Voice/Send buttons
└────────────────────────────────────┘
```

**Key Features**:
- Traditional chat interface
- Text and voice input options
- Streaming text responses
- Optional audio playback (TTS)
- Full message history
- Easy to copy/share text

---

### Real-Time Audio Mode

```
┌────────────────────────────────────┐
│ 💬 AI Assistant │ Ming Vase  💬 × │  ← Header (chat icon = in realtime)
├────────────────────────────────────┤
│ ● Listening                        │  ← Status banner (green)
├────────────────────────────────────┤
│                                    │
│          ▁▂▃▅▇▅▃▂▁▂▃▅             │  ← Waveform visualization
│            ┌─────────┐             │
│         ▁▂ │   🤖    │ ▂▁         │  ← AI Avatar (pulsing)
│            └─────────┘             │
│          ▁▂▃▅▇▅▃▂▁▂▃▅             │
│                                    │
│         "Listening..."             │  ← Status text
│                                    │
│      ┌──────────────────┐         │
│      │ You: What is this│         │  ← Live transcript
│      │      vase?        │         │
│      │                  │         │
│      │ AI: This is a    │         │
│      │     Ming Dynasty │         │
│      │     vase from... │         │
│      └──────────────────┘         │
│                                    │
├────────────────────────────────────┤
│        [ 📞 End Call ]             │  ← Red disconnect button
│  ℹ️ Speak naturally - AI will     │
│     respond in real-time           │
└────────────────────────────────────┘
```

**Key Features**:
- Phone call-like experience
- Continuous audio streaming
- Visual feedback (waveform, avatar)
- Live transcript (for reference)
- Natural turn-taking
- Low latency responses

---

## 🎯 Use Case Recommendations

### Choose **Chat Completion** For:
- ✅ **Cost-sensitive deployments** - Museums with high visitor volume
- ✅ **Text-first interactions** - Users who prefer reading over listening
- ✅ **Reference documentation** - Need full text history to copy/share
- ✅ **Noisy environments** - Hard to hear audio clearly
- ✅ **Accessibility** - Users who can't use voice or audio
- ✅ **Default experience** - Most visitors will use this

**Example Scenario**:
> "A visitor at a busy museum wants to learn about an artifact. They prefer to read at their own pace and might want to copy information to share with friends. They take their time composing questions."

---

### Choose **Real-Time Audio** For:
- ✅ **Premium experiences** - VIP tours, special exhibitions
- ✅ **Natural conversations** - Visitors who prefer speaking over typing
- ✅ **Guided tours** - Walking tours where reading is inconvenient
- ✅ **Hands-free use** - Users holding items or walking
- ✅ **Engagement** - More immersive, personal feel
- ✅ **Language practice** - Pronunciation and conversational practice

**Example Scenario**:
> "A visitor on a walking tour wants to ask quick questions about multiple exhibits while moving. They want immediate, natural responses without looking at their phone screen constantly."

---

## 💰 Cost Analysis

### Chat Completion Mode

**Per Conversation** (10 exchanges):
- **Text generation**: ~$0.005 (gpt-4o-mini)
- **STT (Whisper)**: ~$0.002 (if voice input)
- **TTS**: ~$0.003 (only if audio played)
- **Total**: **~$0.01 per conversation**

**At Scale** (1,000 visitors/day):
- **Daily cost**: $10/day
- **Monthly cost**: $300/month
- **Annual cost**: $3,650/year

---

### Real-Time Audio Mode

**Per Conversation** (5 minutes average):
- **Realtime API**: $0.06/min input + $0.24/min output
- **Average**: ~$0.90 per 5-minute conversation
- **Total**: **~$0.90 per conversation**

**At Scale** (1,000 visitors/day):
- **Daily cost**: $900/day (if all use realtime)
- **Monthly cost**: $27,000/month
- **Annual cost**: $328,500/year

---

### Hybrid Strategy (Recommended)

**Assume**:
- 80% use Chat Completion (800 visitors/day)
- 20% use Real-Time Audio (200 visitors/day)

**Daily Costs**:
- Chat: 800 × $0.01 = $8/day
- Realtime: 200 × $0.90 = $180/day
- **Total**: **$188/day**

**Annual Cost**: ~$68,620/year

**Savings vs. All Realtime**: $259,880/year (79% reduction)

---

## 🎨 User Experience Comparison

| Aspect | Chat Completion | Real-Time Audio |
|--------|----------------|-----------------|
| **Feel** | Traditional chatbot | Phone call |
| **Speed (Perceived)** | Fast (streaming text) | Very fast (instant audio) |
| **Effort** | Low (type or quick voice) | Very low (just speak) |
| **Engagement** | Moderate | High |
| **Privacy** | High (text only) | Lower (always listening) |
| **Multitasking** | Easy (can read later) | Hard (must listen now) |
| **Reference** | Excellent (full history) | Good (transcript) |
| **Immersion** | Moderate | Very high |

---

## 🔄 Mode Switching

Users can seamlessly switch between modes:

**Chat → Realtime**:
1. Click phone icon (📞)
2. Chat history cleared (fresh start)
3. Real-time UI appears

**Realtime → Chat**:
1. Click chat icon (💬)
2. Disconnects real-time session
3. Chat UI appears (fresh start)

**Design Choice**: No history transfer between modes to avoid confusion.

---

## 📱 Technical Architecture Differences

### Chat Completion Mode

```
User Device
    ↓ (Text or Audio)
Frontend
    ↓ (REST call)
Edge Function: chat-with-audio
    ↓ (If voice: Whisper API for STT)
    ↓ (Chat Completions API)
    ← (Text response, SSE stream)
Frontend
    ↓ (Optional: TTS request)
Edge Function: generate-tts-audio
    ↓ (TTS API)
    ← (Audio blob)
Frontend (plays audio)
```

**Pros**:
- Simple REST architecture
- Easy to debug and monitor
- Works on all devices
- No special permissions needed (except mic for voice input)

**Cons**:
- Higher latency for voice (STT → AI → TTS)
- Multiple API calls for voice conversations

---

### Real-Time Audio Mode

```
User Device (Microphone)
    ↓ (Audio stream, WebRTC)
Frontend (RTCPeerConnection)
    ↓ (SDP offer/answer)
Edge Function: openai-realtime-relay
    ↓ (WebRTC relay)
OpenAI Realtime API
    ↓ (Bi-directional audio stream)
    ← (AI audio response)
Frontend (Speaker)
```

**Pros**:
- Very low latency (<500ms)
- Natural conversation flow
- Single connection for entire session
- Automatic turn-taking

**Cons**:
- More complex (WebRTC)
- Requires microphone permission
- Must be connected (no offline)
- Harder to debug
- Higher costs

---

## 🎯 Recommendation Strategy

### 🥇 **Default**: Chat Completion
- Start all users in this mode
- Lower costs
- Broader compatibility
- Easier to use for most visitors

### ⭐ **Offer**: Real-Time Audio as Upgrade
- Show phone icon prominently
- Tooltip: "Try Live Voice Chat"
- After 2-3 chat exchanges, suggest: "Want to try live voice?"
- Market as "premium" or "immersive" experience

### 📊 **Analytics to Track**:
- % of users who switch to realtime
- Average session duration in each mode
- Cost per user by mode
- User satisfaction by mode
- Completion rate (finished conversation)

---

## 🚀 Rollout Plan

### Phase 1: Soft Launch (Weeks 1-2)
- Deploy both modes
- Default to chat-completion
- No proactive promotion of realtime mode
- Monitor usage and costs

### Phase 2: Controlled Testing (Weeks 3-4)
- Show realtime option to 10% of users
- A/B test engagement metrics
- Gather feedback

### Phase 3: Full Rollout (Week 5+)
- Make realtime option visible to all users
- Implement cost controls if needed:
  - Time limits per session (e.g., 5 minutes)
  - Daily usage caps
  - Fallback to chat if quota exceeded

---

## 🎉 Summary

### Chat Completion Mode
- **Status**: ✅ Live and fully functional
- **Cost**: Low (~$0.01 per conversation)
- **UX**: Traditional, familiar chat interface
- **Use**: Default mode, broad appeal

### Real-Time Audio Mode
- **Status**: 🎨 UI complete, backend pending
- **Cost**: Higher (~$0.90 per conversation)
- **UX**: Premium, immersive voice experience
- **Use**: Optional upgrade, special use cases

**Both modes leverage the same AI capabilities** (context-awareness, multi-language, exhibit knowledge) - they just differ in interaction style and cost.

---

**Questions?**
- **UI Review**: See `REALTIME_MODE_UI_IMPLEMENTATION.md`
- **Demo Guide**: See `REALTIME_MODE_DEMO_GUIDE.md`
- **Backend Plan**: See `REALTIME_AUDIO_IMPLEMENTATION_PLAN.md`

**Ready to demo the new realtime UI!** 🎬✨

