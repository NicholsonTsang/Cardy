import { defineStore } from 'pinia'
import { ref } from 'vue'
import { setLocale } from '@/i18n'

export interface Language {
  code: string
  name: string
  flag: string
}

// Chinese voice preferences (for mobile client only)
export type ChineseVoice = 'mandarin' | 'cantonese'

export interface ChineseVoiceOption {
  value: ChineseVoice
  name: string
  nativeName: string
  description: string
}

export const CHINESE_VOICE_OPTIONS: ChineseVoiceOption[] = [
  { 
    value: 'mandarin', 
    name: 'Mandarin', 
    nativeName: '普通話',
    description: 'Standard Chinese (Mainland, Taiwan, Singapore)'
  },
  { 
    value: 'cantonese', 
    name: 'Cantonese', 
    nativeName: '廣東話',
    description: 'Spoken in Hong Kong, Macau, Guangdong'
  }
]

// Available languages (shared by both stores)
export const AVAILABLE_LANGUAGES: Language[] = [
  { code: 'en', name: 'English', flag: '🇺🇸' },
  { code: 'zh-Hans', name: '简体中文', flag: '🇨🇳' },  // Simplified Chinese
  { code: 'zh-Hant', name: '繁體中文', flag: '🇭🇰' },  // Traditional Chinese
  { code: 'ja', name: '日本語', flag: '🇯🇵' },
  { code: 'ko', name: '한국어', flag: '🇰🇷' },
  { code: 'th', name: 'ภาษาไทย', flag: '🇹🇭' },
  { code: 'es', name: 'Español', flag: '🇪🇸' },
  { code: 'fr', name: 'Français', flag: '🇫🇷' },
  { code: 'ru', name: 'Русский', flag: '🇷🇺' },
  { code: 'ar', name: 'العربية', flag: '🇸🇦' }
]

/**
 * Mobile Client Language Store
 * For end-users viewing cards (QR code scanners)
 * Used in: Card Overview, Content Detail, AI Assistant
 */
export const useMobileLanguageStore = defineStore('mobileLanguage', () => {
  // Selected language (default to English)
  const selectedLanguage = ref<Language>(AVAILABLE_LANGUAGES[0])
  
  // Chinese voice preference (only relevant for Chinese languages)
  // Default to Mandarin for simplified, Cantonese for traditional
  const chineseVoice = ref<ChineseVoice>('mandarin')

  // Helper function to check if language is Chinese
  function isChinese(languageCode: string): boolean {
    return languageCode === 'zh-Hans' || languageCode === 'zh-Hant'
  }

  // Set language and update i18n locale
  function setLanguage(language: Language, updateI18n = true) {
    selectedLanguage.value = language
    console.log('📱 Mobile Client language changed to:', language.code, language.name)
    
    // Set default voice preference based on language
    if (language.code === 'zh-Hans') {
      chineseVoice.value = 'mandarin'  // Simplified typically uses Mandarin
    } else if (language.code === 'zh-Hant') {
      chineseVoice.value = 'cantonese' // Traditional typically uses Cantonese
    }
    
    // Update i18n locale if requested
    if (updateI18n) {
      const locale = language.code === 'zh-Hans' ? 'zh-Hans' : 
                     language.code === 'zh-Hant' ? 'zh-Hant' : 
                     language.code
      setLocale(locale)
      console.log('📱 i18n locale updated to:', locale)
    }
  }

  // Set Chinese voice preference
  function setChineseVoice(voice: ChineseVoice) {
    chineseVoice.value = voice
    console.log('📱 Chinese voice changed to:', voice)
  }

  // Get language by code
  function getLanguageByCode(code: string): Language | undefined {
    return AVAILABLE_LANGUAGES.find(lang => lang.code === code)
  }
  
  // Get voice-aware language code (for AI systems)
  // Returns a code that represents both text and voice preference
  function getVoiceAwareLanguageCode(): string {
    const code = selectedLanguage.value.code
    if (isChinese(code)) {
      // Return code that indicates both text script and voice dialect
      return `${code}-${chineseVoice.value}`
    }
    return code
  }

  return {
    languages: AVAILABLE_LANGUAGES,
    selectedLanguage,
    chineseVoice,
    chineseVoiceOptions: CHINESE_VOICE_OPTIONS,
    setLanguage,
    setChineseVoice,
    getLanguageByCode,
    isChinese,
    getVoiceAwareLanguageCode
  }
})

/**
 * Dashboard Language Store
 * For card issuers managing their cards in CMS
 * Used in: Dashboard, Card Management, Admin Panel
 */
export const useDashboardLanguageStore = defineStore('dashboardLanguage', () => {
  // Selected language (default to English)
  const selectedLanguage = ref<Language>(AVAILABLE_LANGUAGES[0])

  // Set language and update i18n locale
  function setLanguage(language: Language, updateI18n = true) {
    selectedLanguage.value = language
    console.log('🖥️ Dashboard language changed to:', language.code, language.name)
    
    // Update i18n locale if requested
    if (updateI18n) {
      // Map our language codes to i18n locale codes
      const localeMap: Record<string, string> = {
        'en': 'en',
        'zh-Hans': 'zh-Hans',  // Simplified Chinese
        'zh-Hant': 'zh-Hant',  // Traditional Chinese
        'zh-HK': 'zh-Hant',    // Legacy mapping for backward compatibility
        'zh-CN': 'zh-Hans',    // Legacy mapping for backward compatibility
        'ja': 'ja',
        'ko': 'ko',
        'th': 'th',
        'es': 'es',
        'fr': 'fr',
        'ru': 'ru',
        'ar': 'ar'
      }
      const locale = localeMap[language.code] || 'en'
      setLocale(locale)
      console.log('🖥️ i18n locale updated to:', locale)
    }
  }

  // Get language by code
  function getLanguageByCode(code: string): Language | undefined {
    return AVAILABLE_LANGUAGES.find(lang => lang.code === code)
  }

  return {
    languages: AVAILABLE_LANGUAGES,
    selectedLanguage,
    setLanguage,
    getLanguageByCode
  }
})

/**
 * @deprecated Use useMobileLanguageStore or useDashboardLanguageStore instead
 * Legacy store for backward compatibility
 */
export const useLanguageStore = useMobileLanguageStore

