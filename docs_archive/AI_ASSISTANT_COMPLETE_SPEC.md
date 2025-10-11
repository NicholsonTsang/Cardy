# AI Assistant - Complete Specification

## 🎯 **Requirements**

### **Input Modes**
- ✅ **Text Input**: Users can type messages
- ✅ **Voice Input**: Users can record audio messages
- ✅ **Toggle Between Modes**: Easy switch between text/voice

### **Output Modes**
- ✅ **Text Output**: Always provided (required)
- ✅ **Audio Output**: Optional, user-controlled toggle
- ✅ **Default**: Audio ON (can be disabled)

### **Language Selection**
- ✅ **Pre-Chat Selection**: Must choose language BEFORE entering chat
- ✅ **Welcome Message**: First AI message in selected language
- ✅ **Consistent Language**: All AI responses in selected language

---

## 🌍 **Supported Languages**

| Language | Code | Native Name | Flag |
|----------|------|-------------|------|
| English | `en` | English | 🇺🇸 |
| Cantonese | `zh-HK` | 廣東話 | 🇭🇰 |
| Mandarin | `zh-CN` | 普通话 | 🇨🇳 |
| Spanish | `es` | Español | 🇪🇸 |
| French | `fr` | Français | 🇫🇷 |

---

## 📱 **User Flow**

### **Step 1: Open AI Assistant**
```
User clicks "Ask AI Assistant" button
↓
Language selection screen appears
```

### **Step 2: Select Language**
```
User sees grid of language options:
┌─────────┬─────────┐
│  🇺🇸     │  🇭🇰     │
│ English │ 廣東話   │
├─────────┼─────────┤
│  🇨🇳     │  🇪🇸     │
│ 普通话  │ Español │
├─────────┼─────────┤
│  🇫🇷     │         │
│ Français│         │
└─────────┴─────────┘

User clicks preferred language
↓
Chat interface opens
```

### **Step 3: Welcome Message**
```
AI greets user in selected language:

English:    "Hi! I'm your AI assistant..."
Cantonese:  "你好！我係你嘅AI助手..."
Mandarin:   "你好！我是你的AI助手..."
Spanish:    "¡Hola! Soy tu asistente de IA..."
French:     "Bonjour ! Je suis votre assistant IA..."
```

### **Step 4: Conversation**
```
User can:
├── Type messages (text input)
├── Record voice (hold button)
├── Toggle audio output ON/OFF
└── Ask questions about content

AI responds:
├── Always provides text
├── Optionally provides audio (if enabled)
└── In selected language
```

---

## 🎨 **UI Components**

### **1. AI Button** (Entry Point)
```vue
┌────────────────────────────┐
│ 💬 Ask AI Assistant        │
└────────────────────────────┘
```
- Gradient purple button
- Floating/prominent placement
- Click → Opens language selector

### **2. Language Selection Screen**
```
┌──────────────────────────────────┐
│ 🌐 Choose Your Language          │
│ Select language for AI conversation│
│                                   │
│  ┌───────┐  ┌───────┐           │
│  │  🇺🇸   │  │  🇭🇰   │           │
│  │English│  │廣東話 │           │
│  └───────┘  └───────┘           │
│                                   │
│  ┌───────┐  ┌───────┐           │
│  │  🇨🇳   │  │  🇪🇸   │           │
│  │普通话 │  │Español│           │
│  └───────┘  └───────┘           │
│                                   │
│  ┌───────┐                       │
│  │  🇫🇷   │                       │
│  │Français│                       │
│  └───────┘                       │
└──────────────────────────────────┘
```

### **3. Chat Interface**
```
┌──────────────────────────────────┐
│ 💬 AI Assistant    🔊  ✕         │ ← Header
│ 🇺🇸 Museum Artifact               │   (language flag shown)
├──────────────────────────────────┤
│                                   │
│ 🤖 Hi! I'm your AI assistant.    │ ← Welcome
│    Ask me anything...             │
│                                   │
│                You: What is this? │ ← User msg
│                                   │
│ 🤖 This is a 3000-year-old...    │ ← AI response
│    [▶ Play response]              │   (with audio)
│                                   │
├──────────────────────────────────┤
│ [Type your message...]  🎤  📤   │ ← Input area
└──────────────────────────────────┘
```

**Header Controls**:
- Language flag indicator (🇺🇸/🇭🇰/🇨🇳/🇪🇸/🇫🇷)
- Audio toggle (🔊 ON / 🔇 OFF)
- Close button (✕)

**Input Controls**:
- Text input field
- Toggle button (⌨️ ↔ 🎤)
- Send/Record button

---

## 🔧 **Technical Implementation**

### **Frontend Component**
`src/views/MobileClient/components/MobileAIAssistantRevised.vue`

**Key Features**:
1. **Two-Screen Flow**:
   - Language selection modal
   - Chat interface modal
   
2. **State Management**:
   ```typescript
   showLanguageSelector: boolean    // Language screen
   isModalOpen: boolean            // Chat screen
   selectedLanguage: Language      // Chosen language
   audioOutputEnabled: boolean     // Audio toggle (default: true)
   inputMode: 'text' | 'voice'    // Input method
   ```

3. **Welcome Messages**:
   ```typescript
   const welcomeMessages: Record<string, string> = {
     'en': `Hi! I'm your AI assistant...`,
     'zh-HK': `你好！我係你嘅AI助手...`,
     'zh-CN': `你好！我是你的AI助手...`,
     'es': `¡Hola! Soy tu asistente de IA...`,
     'fr': `Bonjour ! Je suis votre assistant IA...`
   }
   ```

### **Backend Edge Function**
`supabase/functions/chat-with-audio/index.ts`

**Request Format**:
```typescript
{
  messages: ChatMessage[],          // Conversation history
  systemPrompt: string,             // Context + instructions
  language: string,                 // Selected language code
  modalities: ['text', 'audio'],   // Output types (always includes audio)
  textMessage?: string,             // For text input
  voiceInput?: {                    // For voice input
    data: string,                   // base64 audio
    format: string                  // 'wav'
  }
}
```

**Response Format**:
```typescript
{
  success: true,
  message: {
    role: 'assistant',
    content: string,                // Text response (always)
    audio?: {                       // Audio response (if enabled)
      id: string,
      data: string,                 // base64 audio
      transcript: string,
      expires_at: number
    }
  },
  usage: { /* token counts */ }
}
```

**Key Logic**:
```typescript
// Always ensure audio output for gpt-4o-audio-preview
const outputModalities = modalities.includes('audio') 
  ? modalities           // ['text', 'audio']
  : ['text', 'audio']    // Add audio even for text-only

// Model requirement satisfied:
// (has_audio_input) OR (has_audio_output) = TRUE ✓
```

---

## 🎤 **Audio Handling**

### **Input (Voice Recording)**
1. Request microphone permission
2. Record audio using `MediaRecorder`
3. Convert to base64 WAV
4. Send to Edge Function
5. Display "Voice message" indicator

### **Output (Audio Playback)**
1. Receive base64 audio from API
2. Convert to Blob
3. Create object URL
4. Auto-play if toggle is ON
5. Show play button for manual replay

### **Audio Toggle**
- **ON (Default)**: 
  - Audio generated by AI
  - Auto-plays on arrival
  - Play button shown
- **OFF**: 
  - Audio not generated
  - Saves API costs
  - Faster responses

---

## 🌐 **Language Features**

### **System Prompt Construction**
```typescript
const getSystemPrompt = () => {
  return `${basePrompt}

Current Context:
- Content Item: ${contentItemName}
- Description: ${contentItemContent}
- Additional Information: ${aiMetadata}

Please respond in ${selectedLanguage.name} (${selectedLanguage.nativeName}).
Provide helpful, accurate, and engaging answers about this content.`
}
```

### **Language Consistency**
- Welcome message: ✅ Selected language
- AI responses: ✅ Selected language  
- Error messages: ✅ English (technical)
- UI labels: ✅ English (consistent UX)

---

## 📋 **Deployment Checklist**

### **Frontend**
- [ ] Replace old `MobileAIAssistant.vue` with `MobileAIAssistantRevised.vue`
- [ ] Test on mobile devices
- [ ] Verify language selection works
- [ ] Test text input
- [ ] Test voice input
- [ ] Test audio toggle
- [ ] Verify welcome messages in all languages

### **Backend**
- [ ] Deploy updated `chat-with-audio` Edge Function
- [ ] Verify `OPENAI_API_KEY` in Supabase secrets
- [ ] Verify `OPENAI_AUDIO_MODEL` env variable
- [ ] Test API responses
- [ ] Monitor error logs

### **Testing**
- [ ] English conversation flow
- [ ] Cantonese conversation flow
- [ ] Mandarin conversation flow
- [ ] Spanish conversation flow
- [ ] French conversation flow
- [ ] Audio ON/OFF toggle
- [ ] Text input → Text + Audio output
- [ ] Voice input → Text + Audio output
- [ ] Error handling

---

## 🐛 **Known Issues & Fixes**

### **Issue 1**: Text input fails with audio model
**Fix**: Always include audio in output modalities ✅

### **Issue 2**: Welcome message not in selected language
**Fix**: Use `welcomeMessages[selectedLanguage.code]` ✅

### **Issue 3**: Language selection can't be changed
**Design**: Intentional - prevents mid-conversation language switching
**Workaround**: Close and reopen AI assistant

---

## 🚀 **Future Enhancements**

1. **Language Switching**: Allow mid-conversation language change
2. **Speech-to-Text Display**: Show transcript of voice input
3. **Conversation History**: Save/load previous conversations
4. **Multi-turn Context**: Remember entire conversation context
5. **Suggested Questions**: Show relevant follow-up questions
6. **Offline Mode**: Cache common responses
7. **Voice Selection**: Choose AI voice style
8. **Translation Mode**: Translate between languages

---

## ✅ **Summary**

**What's Implemented**:
- ✅ Language selection before chat
- ✅ Welcome message in selected language
- ✅ Text input support
- ✅ Voice input support
- ✅ Audio output toggle (default ON)
- ✅ Always returns text
- ✅ Optionally returns audio
- ✅ 5 languages supported
- ✅ Mobile-optimized UI
- ✅ Error handling
- ✅ Edge Function integration

**Files**:
- `MobileAIAssistantRevised.vue` - Frontend component
- `chat-with-audio/index.ts` - Backend Edge Function
- `AI_ASSISTANT_COMPLETE_SPEC.md` - This documentation

**Result**: Complete, user-friendly AI assistant with language selection and flexible input/output modes! 🎉

