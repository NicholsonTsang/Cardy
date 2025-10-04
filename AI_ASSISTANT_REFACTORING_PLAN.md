# AI Assistant Component Refactoring Plan

## 🎯 Goal

Break down the large `MobileAIAssistant.vue` (2764 lines) into smaller, maintainable components organized in a dedicated folder structure.

---

## 📁 Proposed Folder Structure

```
src/views/MobileClient/components/AIAssistant/
├── index.vue                          # Main container (orchestrator)
├── LanguageSelector.vue               # Language selection screen ✅ Created
├── ChatCompletionMode.vue             # Chat interface (text + voice)
├── RealtimeMode.vue                   # Real-time audio interface
├── composables/
│   ├── useAIChat.ts                   # Chat completion logic
│   ├── useRealtimeAudio.ts            # Realtime WebSocket logic
│   ├── useVoiceRecording.ts           # Voice recording utilities
│   └── useAudioPlayback.ts            # TTS audio playback
└── components/
    ├── MessageList.vue                # Chat messages display
    ├── MessageBubble.vue              # Individual message
    ├── ChatInput.vue                  # Text/voice input area
    ├── RealtimeAvatar.vue             # Animated AI avatar
    └── WaveformVisualizer.vue         # Audio waveform

```

---

## 📦 Component Breakdown

### 1. **index.vue** (Main Container) ~150 lines
**Responsibility**: Orchestration and state management

**Contains**:
- Modal overlay and structure
- Language selection state
- Conversation mode toggle
- Component routing (language → chat/realtime)

**Props**:
```typescript
defineProps<{
  contentItemName: string
  aiPrompt: string
  aiMetadata: string
}>()
```

**State**:
```typescript
const isModalOpen = ref(false)
const showLanguageSelection = ref(true)
const selectedLanguage = ref<Language | null>(null)
const conversationMode = ref<'chat-completion' | 'realtime'>('chat-completion')
```

---

### 2. **LanguageSelector.vue** ~100 lines ✅
**Responsibility**: Language selection UI

**Events**:
```typescript
emit('select', language)
emit('close')
```

**Status**: ✅ Already created

---

### 3. **ChatCompletionMode.vue** ~400 lines
**Responsibility**: Chat interface with text and voice input

**Contains**:
- MessageList component
- ChatInput component
- Streaming text handling
- Voice recording UI
- Audio playback buttons

**Props**:
```typescript
defineProps<{
  language: Language
  systemInstructions: string
  contentItemName: string
}>()
```

**Composables**:
- `useAIChat()` - Chat logic
- `useVoiceRecording()` - Recording logic
- `useAudioPlayback()` - TTS logic

---

### 4. **RealtimeMode.vue** ~300 lines
**Responsibility**: Real-time audio conversation UI

**Contains**:
- RealtimeAvatar component
- WaveformVisualizer component
- Status banner
- Connection controls
- Live transcript

**Props**:
```typescript
defineProps<{
  language: Language
  systemInstructions: string
  contentItemName: string
}>()
```

**Composables**:
- `useRealtimeAudio()` - WebSocket and audio streaming

---

### 5. **MessageList.vue** ~100 lines
**Responsibility**: Display list of messages

**Props**:
```typescript
defineProps<{
  messages: Message[]
  isLoading: boolean
  currentPlayingMessageId: string | null
}>()
```

**Events**:
```typescript
emit('playAudio', messageId)
```

---

### 6. **MessageBubble.vue** ~80 lines
**Responsibility**: Individual message rendering

**Props**:
```typescript
defineProps<{
  message: Message
  isPlaying: boolean
  isAudioLoading: boolean
}>()
```

**Features**:
- Role-based styling (user/assistant)
- Streaming cursor
- Audio playback button
- Voice indicator

---

### 7. **ChatInput.vue** ~200 lines
**Responsibility**: Text and voice input

**Props**:
```typescript
defineProps<{
  inputMode: 'text' | 'voice'
  isRecording: boolean
  isLoading: boolean
  recordingDuration: string
  isCancelZone: boolean
}>()
```

**Events**:
```typescript
emit('sendText', text)
emit('sendVoice', audioData)
emit('toggleMode')
emit('cancelRecording')
```

---

### 8. **RealtimeAvatar.vue** ~150 lines
**Responsibility**: Animated AI avatar for realtime

**Props**:
```typescript
defineProps<{
  status: 'disconnected' | 'connecting' | 'connected'
  isSpeaking: boolean
  showWaveform: boolean
}>()
```

**Features**:
- Pulsing animations
- Ripple effects
- State-based colors

---

### 9. **WaveformVisualizer.vue** ~100 lines
**Responsibility**: Audio waveform visualization

**Props**:
```typescript
defineProps<{
  analyserNode: AnalyserNode | null
  isActive: boolean
}>()
```

**Features**:
- Real-time frequency analysis
- 20 animated bars
- Staggered animations

---

## 🔧 Composables

### **useAIChat.ts** ~300 lines
**Responsibility**: Chat completion API integration

**Exports**:
```typescript
export function useAIChat(language: Ref<Language>, systemInstructions: Ref<string>) {
  const messages = ref<Message[]>([])
  const isLoading = ref(false)
  const error = ref<string | null>(null)
  
  const sendTextMessage = async (text: string) => { ... }
  const sendVoiceMessage = async (audioData: AudioData) => { ... }
  const playMessageAudio = async (messageId: string) => { ... }
  
  return {
    messages,
    isLoading,
    error,
    sendTextMessage,
    sendVoiceMessage,
    playMessageAudio
  }
}
```

---

### **useRealtimeAudio.ts** ~400 lines
**Responsibility**: WebSocket and real-time audio streaming

**Exports**:
```typescript
export function useRealtimeAudio(
  language: Ref<Language>,
  systemInstructions: Ref<string>,
  contentItemName: string
) {
  const isConnected = ref(false)
  const isSpeaking = ref(false)
  const status = ref<RealtimeStatus>('disconnected')
  const messages = ref<Message[]>([])
  const error = ref<string | null>(null)
  
  const connect = async () => { ... }
  const disconnect = () => { ... }
  
  return {
    isConnected,
    isSpeaking,
    status,
    messages,
    error,
    connect,
    disconnect
  }
}
```

---

### **useVoiceRecording.ts** ~200 lines
**Responsibility**: Microphone recording utilities

**Exports**:
```typescript
export function useVoiceRecording() {
  const isRecording = ref(false)
  const recordingDuration = ref('0:00')
  const audioData = ref<AudioData | null>(null)
  
  const startRecording = async () => { ... }
  const stopRecording = () => { ... }
  const cancelRecording = () => { ... }
  
  return {
    isRecording,
    recordingDuration,
    audioData,
    startRecording,
    stopRecording,
    cancelRecording
  }
}
```

---

### **useAudioPlayback.ts** ~150 lines
**Responsibility**: TTS audio generation and playback

**Exports**:
```typescript
export function useAudioPlayback(language: Ref<Language>) {
  const currentPlayingMessageId = ref<string | null>(null)
  const audioCache = new Map<string, string>()
  
  const generateAndPlayTTS = async (text: string, messageId: string) => { ... }
  const playAudio = (audioUrl: string, messageId: string) => { ... }
  const stopAudio = () => { ... }
  
  return {
    currentPlayingMessageId,
    generateAndPlayTTS,
    playAudio,
    stopAudio
  }
}
```

---

## 🎯 Migration Strategy

### Phase 1: Create Folder Structure ✅
```bash
mkdir -p src/views/MobileClient/components/AIAssistant/{composables,components}
```

### Phase 2: Extract Composables
1. Create `useAIChat.ts`
2. Create `useRealtimeAudio.ts`
3. Create `useVoiceRecording.ts`
4. Create `useAudioPlayback.ts`

### Phase 3: Extract Child Components
1. Create `MessageList.vue` and `MessageBubble.vue`
2. Create `ChatInput.vue`
3. Create `RealtimeAvatar.vue` and `WaveformVisualizer.vue`

### Phase 4: Create Mode Components
1. Create `ChatCompletionMode.vue` (uses composables + child components)
2. Create `RealtimeMode.vue` (uses composables + child components)

### Phase 5: Create Main Container
1. Create `AIAssistant/index.vue`
2. Import all mode components
3. Handle orchestration

### Phase 6: Update Imports
1. Update `MobileClient` views to import from `AIAssistant/index.vue`
2. Delete old `MobileAIAssistant.vue`

### Phase 7: Testing
1. Test chat-completion mode
2. Test realtime mode
3. Test mode switching
4. Test language selection

---

## 📊 Size Comparison

| File | Before | After | Reduction |
|------|--------|-------|-----------|
| **MobileAIAssistant.vue** | 2764 lines | 0 lines | -100% |
| **index.vue** | - | ~150 lines | New |
| **LanguageSelector.vue** | - | ~100 lines | New |
| **ChatCompletionMode.vue** | - | ~400 lines | New |
| **RealtimeMode.vue** | - | ~300 lines | New |
| **Composables (4 files)** | - | ~1050 lines | New |
| **Child Components (5 files)** | - | ~630 lines | New |
| **Total** | 2764 lines | 2630 lines | Similar, but modular |

**Key Benefits**:
- ✅ Each file < 400 lines (maintainable)
- ✅ Clear separation of concerns
- ✅ Reusable composables
- ✅ Testable units
- ✅ Easier to navigate

---

## 🔄 Backward Compatibility

### Ensure Same API
The new `AIAssistant/index.vue` must have the same props:

```vue
<AIAssistant
  :content-item-name="contentItem.name"
  :ai-prompt="card.ai_prompt"
  :ai-metadata="contentItem.ai_metadata"
/>
```

### Same Events
- Button click opens modal
- Modal can be closed
- All existing functionality works

---

## 🧪 Testing Checklist

### Chat Completion Mode
- [ ] Language selection works
- [ ] Text input and send
- [ ] Voice recording (hold-to-talk)
- [ ] Streaming text responses
- [ ] TTS audio playback
- [ ] Audio caching works
- [ ] Mode switching to realtime

### Realtime Mode
- [ ] Connection establishes
- [ ] Microphone access requested
- [ ] Audio streams to OpenAI
- [ ] AI audio plays back
- [ ] Live transcript updates
- [ ] Waveform animates
- [ ] Disconnect cleans up
- [ ] Mode switching to chat

### General
- [ ] No console errors
- [ ] No linter errors
- [ ] Performance unchanged
- [ ] Mobile responsive

---

## 🎯 Benefits of Refactoring

### 1. **Maintainability**
- Easier to find and fix bugs
- Each component has single responsibility
- Clearer code organization

### 2. **Reusability**
- Composables can be used in other components
- Child components are generic
- Logic decoupled from UI

### 3. **Testability**
- Unit test individual composables
- Component tests for UI components
- Integration tests for modes

### 4. **Developer Experience**
- Faster file loading in IDE
- Easier code navigation
- Better TypeScript inference
- Clearer git diffs

### 5. **Team Collaboration**
- Multiple developers can work on different parts
- Merge conflicts reduced
- Code review easier

---

## 📝 Implementation Notes

### Keep Existing Functionality
- All features must continue to work
- No breaking changes to parent components
- Maintain same CSS classes for styling

### Use Composition API
- Leverage `<script setup>` throughout
- Use composables for logic
- Props and emits with TypeScript

### Maintain Styling
- Extract common styles to parent
- Component-specific styles in scoped `<style>`
- Reuse existing CSS classes where possible

### Handle State Properly
- Use `provide/inject` for deep sharing
- Props down, events up
- Composables for cross-cutting concerns

---

## 🚀 Timeline

| Phase | Time Estimate |
|-------|---------------|
| Phase 1: Folder Structure | 5 min ✅ |
| Phase 2: Extract Composables | 2-3 hours |
| Phase 3: Extract Child Components | 2-3 hours |
| Phase 4: Create Mode Components | 1-2 hours |
| Phase 5: Create Main Container | 1 hour |
| Phase 6: Update Imports | 30 min |
| Phase 7: Testing | 1-2 hours |
| **Total** | **8-12 hours** |

---

## ⚠️ Risks & Mitigations

### Risk: Breaking Existing Functionality
**Mitigation**: Thorough testing, keep old file as backup

### Risk: Performance Degradation
**Mitigation**: Benchmark before/after, optimize if needed

### Risk: Increased Complexity
**Mitigation**: Clear documentation, consistent patterns

---

## 🎉 Success Criteria

- ✅ All existing functionality works
- ✅ No linter errors
- ✅ All components < 400 lines
- ✅ Clear, documented code
- ✅ Improved developer experience

---

**Status**: 📋 Plan Complete  
**Next**: Implement Phase 2 (Extract Composables)  
**Priority**: Medium (quality of life improvement)

