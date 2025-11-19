# AI Assistant Internationalization Update - November 2025

## Overview
Fixed an issue where the AI Assistant's default welcome message and ending/warning messages remained in English even after the user selected a different language. These messages are now fully internationalized using the `vue-i18n` system.

## Changes

### 1. Internationalized Messages
Moved hardcoded strings from `MobileAIAssistant.vue` to i18n locale files (`en.json`, `zh-Hant.json`, `zh-Hans.json`).

**New Keys Added:**
- `mobile.welcome_message`: The initial greeting from the AI.
- `mobile.welcome_message_cantonese`: Specialized greeting for Cantonese (used when voice preference is Cantonese).
- `mobile.welcome_message_mandarin`: Specialized greeting for Mandarin (used when voice preference is Mandarin).
- `mobile.call_ended_message`: The message displayed when a realtime call ends.
- `mobile.ask_ai_assistant`: The text on the main "Ask AI Assistant" button.

### 2. Component Logic Updates
Updated `src/views/MobileClient/components/AIAssistant/MobileAIAssistant.vue`:
- Replaced the static `welcomeMessages` object with a reactive `welcomeText` computed property.
- Implemented smart logic to select the correct welcome message dialect (Cantonese vs. Mandarin) based on the user's voice preference in `languageStore`.
- Updated `disconnectRealtime` to use `t('mobile.call_ended_message')`.
- Updated the trigger button to use `$t('mobile.ask_ai_assistant')`.

### 3. Locale Files Updated
- **English (`en.json`)**: Added standard English messages.
- **Traditional Chinese (`zh-Hant.json`)**: Added Traditional Chinese messages with Cantonese default and Mandarin variant.
- **Simplified Chinese (`zh-Hans.json`)**: Added Simplified Chinese messages with Mandarin default and Cantonese variant.

## Visual Impact
- **Welcome Message**: Now appears in the user's selected language immediately upon opening the AI assistant.
- **Call Ended Message**: "Call ended..." is now translated.
- **Button Text**: "Ask AI Assistant" is now translated.

This ensures a consistent language experience throughout the AI interaction lifecycle.

