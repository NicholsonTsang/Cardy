# Language Selector UI Update - November 2025

## Overview
Updated the mobile client's header bar language selector to display the full language name instead of the ISO language code. This improves clarity for users, especially since the language names are native (e.g., "简体中文", "日本語") and easier to recognize than codes like "ZH-HANS" or "JA".

## Changes
- **Component**: `src/views/MobileClient/components/UnifiedLanguageModal.vue`
- **Logic**: Replaced `languageStore.selectedLanguage.code.toUpperCase()` with `languageStore.selectedLanguage.name`.
- **Styling**:
  - Renamed `.language-code` to `.language-name`
  - Removed `text-transform: uppercase`
  - Increased font size from `0.75rem` (12px) to `0.875rem` (14px) for better readability of complex characters (Chinese, Japanese, etc.)

## Visual Impact
- **Before**: 🇺🇸 EN
- **After**: 🇺🇸 English

- **Before**: 🇨🇳 ZH-HANS
- **After**: 🇨🇳 简体中文

This change applies specifically to the mobile client header (`MobileHeader.vue`) which uses `UnifiedLanguageModal` with the default trigger slot.

