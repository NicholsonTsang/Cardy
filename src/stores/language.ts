import { defineStore } from 'pinia'
import { ref } from 'vue'
import { setLocale } from '@/i18n'

export interface Language {
  code: string
  name: string
  flag: string
}

// Available languages (shared by both stores)
export const AVAILABLE_LANGUAGES: Language[] = [
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

/**
 * Mobile Client Language Store
 * For end-users viewing cards (QR code scanners)
 * Used in: Card Overview, Content Detail, AI Assistant
 */
export const useMobileLanguageStore = defineStore('mobileLanguage', () => {
  // Selected language (default to English)
  const selectedLanguage = ref<Language>(AVAILABLE_LANGUAGES[0])

  // Set language and update i18n locale
  function setLanguage(language: Language, updateI18n = true) {
    selectedLanguage.value = language
    console.log('📱 Mobile Client language changed to:', language.code, language.name)
    
    // Update i18n locale if requested
    if (updateI18n) {
      // Map our language codes to i18n locale codes
      const localeMap: Record<string, string> = {
        'en': 'en',
        'zh-HK': 'zh-Hant',
        'zh-CN': 'zh-Hans',
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
      console.log('📱 i18n locale updated to:', locale)
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
        'zh-HK': 'zh-Hant',
        'zh-CN': 'zh-Hans',
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

