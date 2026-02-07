import { defineStore } from 'pinia'
import { ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { setLocale } from '@/i18n'
import { 
  saveLanguagePreference, 
  isValidLanguage,
  extractLanguageFromPath,
  DEFAULT_LANGUAGE
} from '@/router/languageRouting'
import type { LanguageCode } from '@/stores/translation'

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

// Available languages for dashboard (only English and Traditional Chinese for experience creators/admins)
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
  
  
  // Try to find exact match first
  for (const browserLang of browserLanguages) {
    const normalizedBrowserLang = normalizeBrowserLanguage(browserLang)
    const exactMatch = availableLanguages.find(
      lang => lang.code.toLowerCase() === normalizedBrowserLang.toLowerCase()
    )
    if (exactMatch) {
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
 * URL Language Routing:
 * - Language is read from URL parameter (/:lang/c/:id)
 * - When user changes language, URL is updated
 * - If URL has valid language, it takes precedence
 */
export const useMobileLanguageStore = defineStore('mobileLanguage', () => {
  // Get initial language from URL or fallback
  function getInitialLanguage(): Language {
    // First, check URL for language parameter
    const urlLang = extractLanguageFromPath(window.location.pathname)
    if (urlLang) {
      const langObj = AVAILABLE_LANGUAGES.find(lang => lang.code === urlLang)
      if (langObj) {
        console.log('📱 Mobile client loaded language from URL:', urlLang)
        return langObj
      }
    }
    
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
  
  // Sync i18n locale on store initialization
  const initialLocale = initialLanguage.code === 'zh-Hans' ? 'zh-Hans' : 
                        initialLanguage.code === 'zh-Hant' ? 'zh-Hant' : 
                        initialLanguage.code
  setLocale(initialLocale)
  console.log('📱 Mobile client i18n synced to:', initialLocale)
  
  // Chinese voice preference
  const chineseVoice = ref<ChineseVoice>(
    initialLanguage.code === 'zh-Hant' ? 'cantonese' : 'mandarin'
  )

  // Helper function to check if language is Chinese
  function isChinese(languageCode: string): boolean {
    return languageCode === 'zh-Hans' || languageCode === 'zh-Hant'
  }

  // Set language, update i18n locale
  // NOTE: URL updates are handled by Vue Router in PublicCardView.vue watcher
  // to avoid conflicts between replaceState and router.replace
  function setLanguage(language: Language, options: { updateI18n?: boolean } = {}) {
    const { updateI18n = true } = options
    
    selectedLanguage.value = language
    console.log('📱 Mobile Client language changed to:', language.code, language.name)
    
    // Set default voice preference based on language
    if (language.code === 'zh-Hans') {
      chineseVoice.value = 'mandarin'
    } else if (language.code === 'zh-Hant') {
      chineseVoice.value = 'cantonese'
    }
    
    // Save preference
    saveLanguagePreference(language.code as LanguageCode)
    
    // Update i18n locale
    if (updateI18n) {
      setLocale(language.code)
      console.log('📱 i18n locale updated to:', language.code)
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
  
  // Sync language from URL parameter (called by router or components)
  function syncFromUrl(langCode: string) {
    if (langCode !== selectedLanguage.value.code) {
      const langObj = AVAILABLE_LANGUAGES.find(lang => lang.code === langCode)
      if (langObj) {
        setLanguage(langObj)
      }
    }
  }
  
  // Get voice-aware language code (for AI systems)
  function getVoiceAwareLanguageCode(): string {
    const code = selectedLanguage.value.code
    if (isChinese(code)) {
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
    getVoiceAwareLanguageCode,
    syncFromUrl
  }
})

/**
 * Dashboard Language Store
 * For experience creators managing their experiences in CMS
 * Used in: Dashboard, Card Management, Admin Panel
 * Supports: English and Traditional Chinese only
 * 
 * URL Language Routing:
 * - Language is read from URL parameter (/:lang/cms/...)
 * - When user changes language, URL is updated
 * - Only dashboard-supported languages (en, zh-Hant) are allowed
 */
export const useDashboardLanguageStore = defineStore('dashboardLanguage', () => {
  // Get initial language from URL or fallback
  function getInitialLanguage(): Language {
    // First, check URL for language parameter
    const urlLang = extractLanguageFromPath(window.location.pathname)
    if (urlLang && DASHBOARD_LANGUAGES.find(lang => lang.code === urlLang)) {
      const langObj = DASHBOARD_LANGUAGES.find(lang => lang.code === urlLang)
      if (langObj) {
        console.log('🖥️ Dashboard loaded language from URL:', urlLang)
        return langObj
      }
    }
    
    // Check saved preference
    const savedLocale = localStorage.getItem('userLocale')
    if (savedLocale) {
      const savedLang = DASHBOARD_LANGUAGES.find(lang => lang.code === savedLocale)
      if (savedLang) {
        console.log('🖥️ Dashboard loaded saved language:', savedLocale)
        return savedLang
      }
    }
    
    // Detect browser language (only from dashboard languages)
    const detected = detectBrowserLanguage(DASHBOARD_LANGUAGES)
    setLocale(detected.code)
    console.log('🖥️ Dashboard initialized with browser language:', detected.code)
    return detected
  }

  const initialLanguage = getInitialLanguage()
  const selectedLanguage = ref<Language>(initialLanguage)

  // Set language, update i18n locale
  // NOTE: URL updates are handled by Vue Router in components
  // to avoid conflicts between replaceState and router.replace
  function setLanguage(language: Language, options: { updateI18n?: boolean } = {}) {
    const { updateI18n = true } = options
    
    selectedLanguage.value = language
    console.log('🖥️ Dashboard language changed to:', language.code, language.name)
    
    // Save preference
    saveLanguagePreference(language.code as LanguageCode)
    
    // Update i18n locale
    if (updateI18n) {
      const localeMap: Record<string, string> = {
        'en': 'en',
        'zh-Hans': 'zh-Hans',
        'zh-Hant': 'zh-Hant',
        'zh-HK': 'zh-Hant',
        'zh-CN': 'zh-Hans',
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
  
  // Sync language from URL parameter
  function syncFromUrl(langCode: string) {
    // Only sync if it's a valid dashboard language
    if (DASHBOARD_LANGUAGES.find(lang => lang.code === langCode)) {
      if (langCode !== selectedLanguage.value.code) {
        const langObj = DASHBOARD_LANGUAGES.find(lang => lang.code === langCode)
        if (langObj) {
          setLanguage(langObj)
        }
      }
    }
  }

  return {
    languages: DASHBOARD_LANGUAGES,
    selectedLanguage,
    setLanguage,
    getLanguageByCode,
    syncFromUrl
  }
})

/**
 * @deprecated Use useMobileLanguageStore or useDashboardLanguageStore instead
 * Legacy store for backward compatibility
 */
export const useLanguageStore = useMobileLanguageStore

