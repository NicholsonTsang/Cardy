# Language Indicator Dynamic Update (Nov 2025)

## Overview
Updated the AI Assistant language indicator to be context-aware, showing appropriate text based on input mode (Text vs Voice) and language (Chinese dialects).

## Changes

### 1. Context-Aware Language Text
- **Text Mode**: Displays the **Written Language Name** (e.g., "Traditional Chinese").
  - Prefix: "Chat in" (English) / "請用" (Chinese).
- **Voice Mode** (Realtime/Voice Input): Displays the **Spoken Dialect Name** for Chinese (e.g., "Cantonese" 廣東話 / "Mandarin" 普通話).
  - Prefix: "Speak in" (English) / "請用" (Chinese).
- **Other Languages**: Defaults to the language name (e.g., "English", "日本語").

### 2. UI Component Updates
- **`AIAssistantModal.vue`**:
  - Added `inputMode` prop.
  - Added computed properties `isVoiceMode`, `indicatorPrefix`, and `indicatorLanguage`.
  - Integrated `CHINESE_VOICE_OPTIONS` to fetch native dialect names.
- **`MobileAIAssistant.vue`**:
  - Passed `inputMode` state to `AIAssistantModal`.

### 3. Localization Updates
- **New Keys**:
  - `mobile.chat_in`: "Chat in" (English), "請用" (Traditional/Simplified Chinese).
- **Fixes**:
  - Added missing `mobile.speak_in` key to `zh-Hans.json`.

## Verification
- Verified correct dialect display for Chinese in voice mode.
- Verified correct written language display for Chinese in text mode.
- Verified consistent behavior for non-Chinese languages.

