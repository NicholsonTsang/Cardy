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

// Available languages for mobile client (all 10 languages for visitors worldwide)
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

// Available languages for dashboard (only English and Traditional Chinese for card issuers/admins)
export const DASHBOARD_LANGUAGES: Language[] = [
  { code: 'en', name: 'English', flag: '🇺🇸' },
  { code: 'zh-Hant', name: '繁體中文', flag: '🇭🇰' }   // Traditional Chinese
]

/**
 * Detect browser language and map to supported language
 * Returns the best matching language or English as fallback
 * @param availableLanguages - List of languages to match against (defaults to all languages)
 */
export function detectBrowserLanguage(availableLanguages: Language[] = AVAILABLE_LANGUAGES): Language {
  // Get browser languages in order of preference
  const browserLanguages = navigator.languages || [navigator.language]
  
  console.log('🌐 Browser languages:', browserLanguages)
  
  // Try to find exact match first
  for (const browserLang of browserLanguages) {
    const normalizedBrowserLang = normalizeBrowserLanguage(browserLang)
    const exactMatch = availableLanguages.find(
      lang => lang.code.toLowerCase() === normalizedBrowserLang.toLowerCase()
    )
    if (exactMatch) {
      console.log('✅ Exact language match found:', exactMatch.code, exactMatch.name)
      return exactMatch
    }
  }
  
  // Try to find partial match (e.g., 'zh' matches 'zh-Hans' or 'zh-Hant')
  for (const browserLang of browserLanguages) {
    const baseLang = browserLang.toLowerCase().split('-')[0]
    const partialMatch = availableLanguages.find(
      lang => lang.code.toLowerCase().startsWith(baseLang)
    )
    if (partialMatch) {
      console.log('✅ Partial language match found:', partialMatch.code, partialMatch.name)
      return partialMatch
    }
  }
  
  // Default to English (first language in the list)
  console.log('ℹ️ No language match found, defaulting to English')
  return availableLanguages[0]
}

/**
 * Normalize browser language codes to our supported format
 */
function normalizeBrowserLanguage(browserLang: string): string {
  const lang = browserLang.toLowerCase()
  
  // Map browser language codes to our format
  const languageMap: Record<string, string> = {
    'zh': 'zh-Hans',        // Generic Chinese → Simplified
    'zh-cn': 'zh-Hans',     // Mainland China → Simplified
    'zh-sg': 'zh-Hans',     // Singapore → Simplified
    'zh-tw': 'zh-Hant',     // Taiwan → Traditional
    'zh-hk': 'zh-Hant',     // Hong Kong → Traditional
    'zh-mo': 'zh-Hant',     // Macau → Traditional
  }
  
  return languageMap[lang] || browserLang
}

/**
 * Mobile Client Language Store
 * For end-users viewing cards (QR code scanners)
 * Used in: Card Overview, Content Detail, AI Assistant
 * 
 * NOTE: Unlike dashboard, mobile client defaults to card's original language
 * (set by PublicCardView), NOT browser language. This ensures visitors see
 * content in the language intended by the card creator.
 */
export const useMobileLanguageStore = defineStore('mobileLanguage', () => {
  // Get initial language: saved preference > English default
  // (Card's original language will be set by PublicCardView after loading)
  function getInitialLanguage(): Language {
    // Check if user manually selected a language in this session
    const userSelectedLanguage = sessionStorage.getItem('userSelectedLanguage') === 'true'
    
    if (userSelectedLanguage) {
      const savedLocale = localStorage.getItem('userLocale')
      if (savedLocale) {
        const savedLang = AVAILABLE_LANGUAGES.find(lang => lang.code === savedLocale)
        if (savedLang) {
          console.log('📱 Mobile client loaded user-selected language:', savedLocale)
          return savedLang
        }
      }
    }
    
    // Default to English - card will set original language after loading
    console.log('📱 Mobile client initialized with English (will be set to card original language)')
    return AVAILABLE_LANGUAGES[0] // English
  }

  const initialLanguage = getInitialLanguage()
  const selectedLanguage = ref<Language>(initialLanguage)
  
  // Chinese voice preference (only relevant for Chinese languages)
  // Default to Mandarin for simplified, Cantonese for traditional
  const chineseVoice = ref<ChineseVoice>(
    initialLanguage.code === 'zh-Hant' ? 'cantonese' : 'mandarin'
  )

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
 * Supports: English and Traditional Chinese only
 */
export const useDashboardLanguageStore = defineStore('dashboardLanguage', () => {
  // Get initial language: saved preference > browser detection > English fallback
  function getInitialLanguage(): Language {
    const savedLocale = localStorage.getItem('userLocale')
    if (savedLocale) {
      const savedLang = DASHBOARD_LANGUAGES.find(lang => lang.code === savedLocale)
      if (savedLang) {
        console.log('🖥️ Dashboard loaded saved language:', savedLocale)
        return savedLang
      }
    }
    
    // No saved preference, detect browser language (only from dashboard languages)
    const detected = detectBrowserLanguage(DASHBOARD_LANGUAGES)
    setLocale(detected.code)
    console.log('🖥️ Dashboard initialized with browser language:', detected.code)
    return detected
  }

  const initialLanguage = getInitialLanguage()
  const selectedLanguage = ref<Language>(initialLanguage)

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
      }
      const locale = localeMap[language.code] || 'en'
      setLocale(locale)
      console.log('🖥️ i18n locale updated to:', locale)
    }
  }

  // Get language by code
  function getLanguageByCode(code: string): Language | undefined {
    return DASHBOARD_LANGUAGES.find(lang => lang.code === code)
  }

  return {
    languages: DASHBOARD_LANGUAGES,
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

