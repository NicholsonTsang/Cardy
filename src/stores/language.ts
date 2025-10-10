import { defineStore } from 'pinia'
import { ref } from 'vue'

export interface Language {
  code: string
  name: string
  flag: string
}

export const useLanguageStore = defineStore('language', () => {
  // Available languages
  const languages: Language[] = [
    { code: 'en', name: 'English', flag: '🇺🇸' },
    { code: 'zh-HK', name: '廣東話', flag: '🇭🇰' },
    { code: 'zh-CN', name: '普通话', flag: '🇨🇳' },
    { code: 'ja', name: '日本語', flag: '🇯🇵' },
    { code: 'ko', name: '한국어', flag: '🇰🇷' },
    { code: 'th', name: 'ภาษาไทย', flag: '🇹🇭' },
    { code: 'es', name: 'Español', flag: '🇪🇸' },
    { code: 'fr', name: 'Français', flag: '🇫🇷' },
    { code: 'ru', name: 'Русский', flag: '🇷🇺' },
    { code: 'ar', name: 'العربية', flag: '🇸🇦' }
  ]

  // Selected language (default to English)
  const selectedLanguage = ref<Language>(languages[0])

  // Set language
  function setLanguage(language: Language) {
    selectedLanguage.value = language
    console.log('🌍 Global language changed to:', language.code, language.name)
  }

  // Get language by code
  function getLanguageByCode(code: string): Language | undefined {
    return languages.find(lang => lang.code === code)
  }

  return {
    languages,
    selectedLanguage,
    setLanguage,
    getLanguageByCode
  }
})

