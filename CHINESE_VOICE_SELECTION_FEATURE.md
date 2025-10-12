# Chinese Voice Selection Feature - Implementation Complete

## Overview

Implemented **independent selection of Chinese text script and voice dialect** for the mobile client AI assistant. Users can now choose:
- **Text Script**: Simplified Chinese (简体) or Traditional Chinese (繁體)
- **Voice Dialect**: Mandarin (普通話) or Cantonese (廣東話)

This separation allows for all four combinations:
1. Simplified + Mandarin
2. Simplified + Cantonese  
3. Traditional + Mandarin
4. Traditional + Cantonese

## Problem Solved

**Previous System** conflated text and voice:
- `zh-HK` = Traditional text + Cantonese voice (fixed)
- `zh-CN` = Simplified text + Mandarin voice (fixed)

**New System** separates concerns:
- Text language selected via language selector
- Voice dialect selected via new Chinese voice selector (only shown when Chinese is selected)

## Implementation Details

### 1. Language Store Updates

**File**: `src/stores/language.ts`

**Changes**:
- Updated `AVAILABLE_LANGUAGES` to use proper Chinese language codes:
  - `zh-Hans` (Simplified Chinese) instead of `zh-CN`
  - `zh-Hant` (Traditional Chinese) instead of `zh-HK`
- Added `ChineseVoice` type: `'mandarin' | 'cantonese'`
- Added `chineseVoice` state with smart defaults:
  - `zh-Hans` → defaults to Mandarin
  - `zh-Hant` → defaults to Cantonese
- Added `isChinese()` helper function
- Added `getVoiceAwareLanguageCode()` function:
  - Returns combined code like `zh-Hans-mandarin` or `zh-Hant-cantonese`
  - Used by AI systems to determine both text and voice

### 2. Chinese Voice Selector Component

**File**: `src/views/MobileClient/components/ChineseVoiceSelector.vue`

**Features**:
- Appears in mobile header **only when Chinese language is selected**
- Shows current voice preference (`普通話` or `廣東話`)
- Opens modal with voice options:
  - **Mandarin** (普通話): Standard Chinese (Mainland, Taiwan, Singapore)
  - **Cantonese** (廣東話): Spoken in Hong Kong, Macau, Guangdong
- Smooth animations and mobile-optimized design
- Accessible on desktop (centered modal) and mobile (bottom sheet)

### 3. Mobile Header Integration

**File**: `src/views/MobileClient/components/MobileHeader.vue`

**Changes**:
- Added `ChineseVoiceSelector` component
- Grouped language and voice selectors in `.language-controls` div
- Voice selector automatically hidden for non-Chinese languages

### 4. Voice Map Updates

**Files**:
- `src/views/MobileClient/components/AIAssistant/composables/useWebRTCConnection.ts`
- `src/views/MobileClient/components/AIAssistant/composables/useChatCompletion.ts`

**Changes**:
- Updated voice maps to support combined language codes:
  ```typescript
  const voiceMap: Record<string, string> = {
    'en': 'alloy',
    'zh-Hans-mandarin': 'nova',   // Simplified + Mandarin
    'zh-Hans-cantonese': 'nova',  // Simplified + Cantonese
    'zh-Hant-mandarin': 'nova',   // Traditional + Mandarin
    'zh-Hant-cantonese': 'nova',  // Traditional + Cantonese
    'zh-Hans': 'nova',            // Fallback
    'zh-Hant': 'nova',            // Fallback
    // ... other languages
  }
  ```
- Added language name mappings for Realtime API instructions
- Both TTS and Realtime API now respect voice preference

### 5. AI Instructions Update

**File**: `src/views/MobileClient/components/AIAssistant/MobileAIAssistant.vue`

**Changes**:
- System instructions now check `isChinese()` and use `chineseVoice` preference
- Mandarin instructions: "You MUST speak in MANDARIN (普通話), NOT Cantonese"
- Cantonese instructions: "You MUST speak in CANTONESE (廣東話), NOT Mandarin"
- Welcome messages support all four combinations with proper fallback

**Example**:
```typescript
if (languageStore.isChinese(languageCode)) {
  if (languageStore.chineseVoice === 'cantonese') {
    languageNote = 'You MUST speak in CANTONESE (廣東話)...'
  } else {
    languageNote = 'You MUST speak in MANDARIN (普通話)...'
  }
}
```

### 6. Voice-Aware Language Code Usage

All AI function calls now use `languageStore.getVoiceAwareLanguageCode()`:
- `chatCompletion.getAIResponseWithVoice()` - Voice input transcription
- `chatCompletion.playMessageAudio()` - TTS playback
- `realtimeConnection.connect()` - Live voice call connection

### 7. Internationalization

**Files**:
- `src/i18n/locales/en.json`
- `src/i18n/locales/zh-Hant.json`

**Added Keys**:
```json
{
  "mobile": {
    "select_chinese_voice": "Select Chinese Voice",
    "chinese_voice_description": "Choose which Chinese dialect to use for AI voice responses"
  }
}
```

## User Experience Flow

### Scenario 1: Hong Kong User (Traditional + Cantonese)

1. **Select Language**: Tap language button → Select `繁體中文` (Traditional Chinese)
   - System auto-sets voice to Cantonese (default for Traditional)
   - Voice button appears showing `廣東話`
2. **Confirm/Change Voice** (optional): Tap voice button → Confirm Cantonese is selected
3. **Use AI**: All voice responses use Cantonese dialect with Traditional Chinese text

### Scenario 2: Mainland User (Simplified + Mandarin)

1. **Select Language**: Tap language button → Select `简体中文` (Simplified Chinese)
   - System auto-sets voice to Mandarin (default for Simplified)
   - Voice button appears showing `普通話`
2. **Use AI**: All voice responses use Mandarin dialect with Simplified Chinese text

### Scenario 3: Taiwan User (Traditional + Mandarin)

1. **Select Language**: Tap language button → Select `繁體中文` (Traditional Chinese)
   - System auto-sets voice to Cantonese (default)
2. **Change Voice**: Tap voice button → Select `普通話` (Mandarin)
   - Voice switches to Mandarin while keeping Traditional text
3. **Use AI**: Voice responses use Mandarin dialect with Traditional Chinese text

## Technical Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     Mobile Client UI Layer                       │
├─────────────────────────────────────────────────────────────────┤
│  MobileHeader                                                   │
│  ├─ LanguageSelector ────► Select Text: zh-Hans / zh-Hant     │
│  └─ ChineseVoiceSelector ► Select Voice: Mandarin / Cantonese  │
└──────────────────────────┬──────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Language Store (Pinia)                        │
├─────────────────────────────────────────────────────────────────┤
│  State:                                                          │
│  - selectedLanguage: { code: 'zh-Hans', name: '简体中文', ... }│
│  - chineseVoice: 'mandarin' | 'cantonese'                      │
│                                                                  │
│  Computed:                                                       │
│  - getVoiceAwareLanguageCode() → 'zh-Hans-mandarin'            │
└──────────────────────────┬──────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│                    AI Assistant Components                       │
├─────────────────────────────────────────────────────────────────┤
│  MobileAIAssistant                                              │
│  ├─ System Instructions ──► Based on voice preference          │
│  ├─ Welcome Message ──────► Language + dialect specific        │
│  └─ Function Calls:                                             │
│      ├─ chatCompletion.getAIResponseWithVoice(voiceAwareCode) │
│      ├─ chatCompletion.playMessageAudio(voiceAwareCode)       │
│      └─ realtimeConnection.connect(voiceAwareCode)            │
└──────────────────────────┬──────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Voice Maps (Composables)                      │
├─────────────────────────────────────────────────────────────────┤
│  useChatCompletion.ts     │  useWebRTCConnection.ts            │
│  ├─ TTS Voice Map         │  ├─ Realtime Voice Map             │
│  │  'zh-Hans-mandarin': 'nova'  'zh-Hans-mandarin': 'coral'   │
│  │  'zh-Hans-cantonese': 'nova' 'zh-Hans-cantonese': 'coral'  │
│  │  'zh-Hant-mandarin': 'nova'  'zh-Hant-mandarin': 'coral'   │
│  │  'zh-Hant-cantonese': 'nova' 'zh-Hant-cantonese': 'coral'  │
│  └─ Language Instructions │  └─ Session Configuration          │
└─────────────────────────────────────────────────────────────────┘
```

## Files Modified

### Core Files:
1. `src/stores/language.ts` - Language store with voice preference
2. `src/views/MobileClient/components/ChineseVoiceSelector.vue` - NEW component
3. `src/views/MobileClient/components/MobileHeader.vue` - Integrated voice selector
4. `src/views/MobileClient/components/AIAssistant/MobileAIAssistant.vue` - Voice-aware AI calls
5. `src/views/MobileClient/components/AIAssistant/composables/useChatCompletion.ts` - Updated voice maps
6. `src/views/MobileClient/components/AIAssistant/composables/useWebRTCConnection.ts` - Updated voice maps

### i18n Files:
7. `src/i18n/locales/en.json` - Added voice selection keys
8. `src/i18n/locales/zh-Hant.json` - Added voice selection keys

### Documentation:
9. `REALTIME_CORS_FIX.md` - OpenAI Realtime API fix (from previous issue)
10. `CLAUDE.md` - Updated with Chinese voice selection feature

## Testing Checklist

### Text Language Selection:
- [ ] Select `简体中文` (Simplified) → UI shows Simplified text
- [ ] Select `繁體中文` (Traditional) → UI shows Traditional text
- [ ] Non-Chinese languages → Voice selector hidden

### Voice Selection:
- [ ] Select Simplified → Voice button shows `普通話` (Mandarin) by default
- [ ] Select Traditional → Voice button shows `廣東話` (Cantonese) by default
- [ ] Tap voice button → Modal opens with two options
- [ ] Select Mandarin → Button updates to `普通話`
- [ ] Select Cantonese → Button updates to `廣東話`

### AI Integration:
- [ ] Chat Mode (Text + TTS):
  - Traditional + Mandarin → AI speaks Mandarin, shows Traditional text
  - Simplified + Cantonese → AI speaks Cantonese, shows Simplified text
- [ ] Realtime Mode (Live Voice):
  - Traditional + Mandarin → Live call uses Mandarin dialect
  - Simplified + Cantonese → Live call uses Cantonese dialect
- [ ] Voice Input (STT):
  - Mandarin speech → Transcribed correctly
  - Cantonese speech → Transcribed correctly

### Edge Cases:
- [ ] Change language mid-conversation → Voice resets to default
- [ ] Change voice mid-conversation → AI adapts to new dialect
- [ ] Refresh page → Settings persist (if implemented with localStorage)
- [ ] Switch between modes → Voice preference maintained

## Known Limitations

1. **OpenAI Voice Models**: Currently using same OpenAI voice ('nova' for TTS, 'coral' for Realtime) for both Mandarin and Cantonese. The dialect difference is enforced through system instructions, not different voice models.

2. **Persistence**: Voice preference is stored in Pinia state but not persisted to localStorage. Refreshing the page resets to defaults.

3. **Fallback Behavior**: If a voice-aware language code (`zh-Hans-mandarin`) is not found in voice map, falls back to base code (`zh-Hans`).

4. **i18n Coverage**: Only English and Traditional Chinese have full translations. Other language files are placeholders.

## Future Enhancements

1. **LocalStorage Persistence**: Save voice preference to persist across page reloads
2. **Native Voice Models**: Use different OpenAI voices specifically trained for Mandarin vs Cantonese (when available)
3. **Voice Preview**: Add audio samples in the voice selection modal
4. **Quick Toggle**: Add small toggle button for quick Mandarin/Cantonese switching
5. **Analytics**: Track which voice preferences are most popular
6. **User Profile**: Save language + voice preference in user profile for returning visitors

## Deployment Notes

### Frontend:
- No environment variable changes needed
- All changes are in Vue components and stores
- Build and deploy as usual: `npm run build`

### Backend:
- No database changes required
- No Edge Function updates needed
- Existing AI infrastructure supports the new language codes

### Testing in Production:
1. Deploy frontend build
2. Test with real Chinese-speaking users for dialect accuracy
3. Monitor AI response quality across different combinations
4. Gather user feedback on voice selector UX

## Success Metrics

1. **User Satisfaction**: Feedback from Chinese-speaking users on dialect accuracy
2. **Usage Patterns**: Track which text+voice combinations are most popular
3. **Error Rates**: Monitor for increased transcription/TTS errors
4. **Conversion**: Check if feature increases AI assistant usage among Chinese users

## Related Documentation

- `REALTIME_CORS_FIX.md` - OpenAI Realtime API CORS fix
- `AI_CHAT_INPUT_BAR_FIX.md` - Chat interface fixes
- `docs_archive/REALTIME_AUDIO_FULL_IMPLEMENTATION.md` - Realtime mode implementation
- `docs_archive/AI_TEXT_TTS_IMPLEMENTATION.md` - TTS implementation

## Contact & Support

For questions or issues related to this feature:
- Check `CLAUDE.md` for full system documentation
- Review `src/stores/language.ts` for language handling logic
- Test with `console.log` statements in `MobileAIAssistant.vue` (lines 398-403)

