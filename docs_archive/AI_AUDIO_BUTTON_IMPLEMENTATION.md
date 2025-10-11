# AI Audio Button Implementation

## Overview
Implemented an on-demand audio playback system with caching for AI assistant responses. Users can click a speaker button to generate and play TTS audio, with subsequent clicks playing cached audio instantly.

## Key Features

### 1. **Manual Audio Playback**
- AI responses now display text immediately without auto-playing audio
- Users control when to hear the audio by clicking the speaker button
- Reduces unnecessary TTS API calls and gives users full control

### 2. **Audio Caching with Language Awareness**
- TTS audio is generated once and cached in the message object
- Subsequent plays use the cached audio URL (no additional API calls)
- **Language tracking**: Audio is tagged with the language it was generated in
- **Smart regeneration**: If user switches language, audio is automatically regenerated
- Old audio URLs are properly cleaned up with `URL.revokeObjectURL()`
- Significant cost savings for repeated listens in the same language

### 3. **Visual Feedback**
- **Volume-off icon** (`pi-volume-off`): Audio not yet generated
- **Spinner icon** (`pi-spin pi-spinner`): Audio generation in progress
- **Volume-up icon** (`pi-volume-up`): Audio currently playing
- Button animates with pulse effect while playing
- Hover effects for better UX

### 4. **Smart State Management**
- Only one audio can play at a time
- Clicking the same button while playing stops the audio
- Clicking another button stops the current audio and plays the new one
- Loading state prevents multiple simultaneous requests

## Implementation Details

### Message Interface Updates
```typescript
interface Message {
  id: string
  role: 'user' | 'assistant'
  content?: string
  timestamp: Date
  isStreaming?: boolean
  audioUrl?: string       // NEW: Cached audio URL
  audioLoading?: boolean  // NEW: Audio generation in progress
  language?: string       // NEW: Language code when audio was generated
}
```

### New State Variables
```typescript
const currentPlayingMessageId = ref<string | null>(null)  // Track which message is playing
```

### Core Functions

#### `playMessageAudio(message: Message)`
- Triggered by button click
- Stops currently playing audio if different message
- Toggles pause/play for the same message
- Calls `generateAndPlayTTS()` with message ID

#### `generateAndPlayTTS(text: string, messageId: string)`
- Checks if audio is cached AND language matches current selection
- If cached and language matches: plays immediately via `playAudioUrl()`
- If language changed: cleans up old audio URL and regenerates
- If not cached:
  1. Sets `audioLoading = true`
  2. Calls `generate-tts-audio` Edge Function with current language
  3. Creates object URL from blob
  4. Caches URL in `message.audioUrl` and language in `message.language`
  5. Sets `audioLoading = false`
  6. Plays audio via `playAudioUrl()`

#### `playAudioUrl(audioUrl: string, messageId: string)`
- Sets `currentPlayingMessageId`
- Loads audio URL into `audioPlayer.value`
- Plays audio with promise handling
- Clears `currentPlayingMessageId` on end/error

### UI Component
```vue
<div class="message-content">
  <div class="message-bubble">
    <!-- Message text content -->
    <p v-if="message.content !== undefined" class="message-text">
      {{ message.content }}
    </p>
  </div>
  
  <!-- Audio button appears outside the bubble, on next line -->
  <button 
    v-if="message.role === 'assistant' && message.content && !message.isStreaming"
    @click="playMessageAudio(message)"
    class="audio-play-button"
    :class="{ 
      'playing': currentPlayingMessageId === message.id, 
      'loading': message.audioLoading 
    }"
    :disabled="message.audioLoading"
    :title="message.audioLoading ? 'Generating audio...' : 
           currentPlayingMessageId === message.id ? 'Playing...' : 'Play audio'"
  >
    <i v-if="message.audioLoading" class="pi pi-spin pi-spinner" />
    <i v-else-if="currentPlayingMessageId === message.id" class="pi pi-volume-up" />
    <i v-else class="pi pi-volume-off" />
  </button>
  
  <span class="message-time">{{ formatTime(message.timestamp) }}</span>
</div>
```

### Styling
```css
/* Message structure */
.message-content {
  max-width: 70%;
  display: flex;
  flex-direction: column;
  gap: 0.5rem;  /* Space between bubble and button */
}

.message-bubble {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
}

/* Audio play button - appears outside bubble */
.audio-play-button {
  background: rgba(16, 185, 129, 0.08);
  border: 1px solid rgba(16, 185, 129, 0.2);
  padding: 0.5rem;
  cursor: pointer;
  color: #10b981;
  transition: all 0.2s ease;
  border-radius: 0.5rem;
  width: 2.25rem;
  height: 2.25rem;
  align-self: flex-start;
  flex-shrink: 0;
}

.audio-play-button:hover:not(:disabled) {
  background: rgba(16, 185, 129, 0.1);
  transform: scale(1.05);
}

.audio-play-button.playing {
  color: #059669;
  background: rgba(16, 185, 129, 0.15);
  animation: pulse 2s ease-in-out infinite;
}

.audio-play-button.loading {
  color: #9ca3af;
  cursor: not-allowed;
}
```

## Removed Auto-Play Logic

### Before (Voice Input)
```typescript
// Add assistant message
addAssistantMessage(textContent)

// Auto-generate and play TTS
loadingStatus.value = 'Generating audio...'
generateAndPlayTTS(textContent).catch(err => {
  console.error('TTS generation failed (non-blocking):', err)
})
```

### After (Voice Input)
```typescript
// Add assistant message
addAssistantMessage(textContent)

// Don't auto-generate audio - let user click button to play
```

## Benefits

### 1. **Cost Optimization**
- TTS API called only when user wants audio
- Cached audio eliminates redundant API calls (in same language)
- Smart regeneration only when language changes
- Estimated 60-80% reduction in TTS costs for single-language sessions

### 2. **User Control**
- Users decide when to hear audio
- Can replay audio without regenerating
- Better for browsing history or quiet environments

### 3. **Performance**
- Faster response times (text appears immediately)
- No blocking while generating audio
- Smooth playback from cache

### 4. **UX Improvements**
- Clear visual indicators for audio state
- Intuitive button behavior (play/pause/stop)
- No unexpected audio in public spaces

## Testing Checklist

- [ ] Click speaker button on new assistant message → audio generates and plays
- [ ] Click speaker button again (same language) → audio plays from cache (instant)
- [ ] Switch language and click speaker button → audio regenerates in new language
- [ ] Click speaker button while playing → audio stops
- [ ] Click different message's button → previous audio stops, new audio plays
- [ ] Loading spinner shows during generation
- [ ] Volume icons change based on state
- [ ] Button hover effects work correctly
- [ ] Button appears outside message bubble, on next line
- [ ] Audio caching persists for session duration (per language)
- [ ] Works with both text input and voice input responses
- [ ] Old audio URLs are properly cleaned up when language changes

## Edge Function Used
- **`generate-tts-audio`**: Generates TTS audio from text using OpenAI TTS API
- **Input**: `{ text, language, voice }`
- **Output**: Audio blob (WAV format)

## Future Enhancements
1. Persist cached audio to localStorage for longer sessions
2. Add download button for audio files
3. Implement audio speed control (0.5x, 1x, 1.5x, 2x)
4. Add waveform visualization while playing
5. Auto-generate audio in background for better perceived performance

## Related Files
- `/src/views/MobileClient/components/MobileAIAssistant.vue`
- `/supabase/functions/generate-tts-audio/index.ts`
- `/supabase/functions/chat-with-audio/index.ts`

---

**Implementation Date**: January 2025  
**Status**: ✅ Complete and Ready to Test

