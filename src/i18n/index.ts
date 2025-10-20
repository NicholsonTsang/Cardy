import { createI18n } from 'vue-i18n'
import en from './locales/en.json'
import zhHant from './locales/zh-Hant.json'
import zhHans from './locales/zh-Hans.json'
import ja from './locales/ja.json'
import ko from './locales/ko.json'
import es from './locales/es.json'
import fr from './locales/fr.json'
import ru from './locales/ru.json'
import ar from './locales/ar.json'
import th from './locales/th.json'

/**
 * Detect browser language and return matching locale code
 */
function detectBrowserLocale(): string {
  const browserLanguages = navigator.languages || [navigator.language]
  const supportedLocales = ['en', 'zh-Hant', 'zh-Hans', 'ja', 'ko', 'th', 'es', 'fr', 'ru', 'ar']
  
  // Try exact match first
  for (const browserLang of browserLanguages) {
    const normalized = normalizeBrowserLocale(browserLang)
    if (supportedLocales.includes(normalized)) {
      console.log('🌐 Browser language detected:', normalized)
      return normalized
    }
  }
  
  // Try partial match (e.g., 'zh' → 'zh-Hans')
  for (const browserLang of browserLanguages) {
    const baseLang = browserLang.toLowerCase().split('-')[0]
    const match = supportedLocales.find(locale => locale.toLowerCase().startsWith(baseLang))
    if (match) {
      console.log('🌐 Browser language detected (partial match):', match)
      return match
    }
  }
  
  console.log('🌐 No browser language match, defaulting to English')
  return 'en'
}

/**
 * Normalize browser locale codes to our format
 */
function normalizeBrowserLocale(browserLang: string): string {
  const lang = browserLang.toLowerCase()
  const localeMap: Record<string, string> = {
    'zh': 'zh-Hans',
    'zh-cn': 'zh-Hans',
    'zh-sg': 'zh-Hans',
    'zh-tw': 'zh-Hant',
    'zh-hk': 'zh-Hant',
    'zh-mo': 'zh-Hant',
  }
  return localeMap[lang] || browserLang
}

// Get saved locale from localStorage, or detect browser language, or default to English
const rawSavedLocale = localStorage.getItem('userLocale') || detectBrowserLocale()

// Normalize legacy locale codes on init
function normalizeLocaleInit(locale: string): string {
  const localeMap: Record<string, string> = {
    'zh': 'zh-Hans',
    'zh-CN': 'zh-Hans',
    'zh-HK': 'zh-Hant',
    'zh-TW': 'zh-Hant',
    'zh-SG': 'zh-Hans',
  }
  return localeMap[locale] || locale
}

const savedLocale = normalizeLocaleInit(rawSavedLocale)

// Update localStorage if we normalized it
if (savedLocale !== rawSavedLocale) {
  localStorage.setItem('userLocale', savedLocale)
  console.log(`🔄 Migrated locale from '${rawSavedLocale}' to '${savedLocale}'`)
}

const i18n = createI18n({
  legacy: false, // Use Composition API mode
  locale: savedLocale,
  fallbackLocale: {
    'zh': ['zh-Hans', 'zh-Hant', 'en'],  // Fallback for legacy 'zh' locale
    'zh-CN': ['zh-Hans', 'en'],          // Legacy code fallback
    'zh-HK': ['zh-Hant', 'en'],          // Legacy code fallback
    'default': ['en']                    // Default fallback for all other locales
  },
  messages: {
    en,
    'zh-Hant': zhHant,
    'zh-Hans': zhHans,
    'zh': zhHans,        // Alias 'zh' to Simplified Chinese for compatibility
    'zh-CN': zhHans,     // Legacy locale alias
    'zh-HK': zhHant,     // Legacy locale alias
    ja,
    ko,
    es,
    fr,
    ru,
    ar,
    th
  },
  globalInjection: true,
  datetimeFormats: {
    en: {
      short: { year: 'numeric', month: 'short', day: 'numeric' },
      long: { year: 'numeric', month: 'long', day: 'numeric', weekday: 'long' }
    },
    'zh-Hant': {
      short: { year: 'numeric', month: 'short', day: 'numeric' },
      long: { year: 'numeric', month: 'long', day: 'numeric', weekday: 'long' }
    },
    'zh-Hans': {
      short: { year: 'numeric', month: 'short', day: 'numeric' },
      long: { year: 'numeric', month: 'long', day: 'numeric', weekday: 'long' }
    },
    'zh': {  // Legacy alias
      short: { year: 'numeric', month: 'short', day: 'numeric' },
      long: { year: 'numeric', month: 'long', day: 'numeric', weekday: 'long' }
    },
    'zh-CN': {  // Legacy alias
      short: { year: 'numeric', month: 'short', day: 'numeric' },
      long: { year: 'numeric', month: 'long', day: 'numeric', weekday: 'long' }
    },
    'zh-HK': {  // Legacy alias
      short: { year: 'numeric', month: 'short', day: 'numeric' },
      long: { year: 'numeric', month: 'long', day: 'numeric', weekday: 'long' }
    },
    ja: {
      short: { year: 'numeric', month: 'short', day: 'numeric' },
      long: { year: 'numeric', month: 'long', day: 'numeric', weekday: 'long' }
    },
    ko: {
      short: { year: 'numeric', month: 'short', day: 'numeric' },
      long: { year: 'numeric', month: 'long', day: 'numeric', weekday: 'long' }
    },
    es: {
      short: { year: 'numeric', month: 'short', day: 'numeric' },
      long: { year: 'numeric', month: 'long', day: 'numeric', weekday: 'long' }
    },
    fr: {
      short: { year: 'numeric', month: 'short', day: 'numeric' },
      long: { year: 'numeric', month: 'long', day: 'numeric', weekday: 'long' }
    },
    ru: {
      short: { year: 'numeric', month: 'short', day: 'numeric' },
      long: { year: 'numeric', month: 'long', day: 'numeric', weekday: 'long' }
    },
    ar: {
      short: { year: 'numeric', month: 'short', day: 'numeric' },
      long: { year: 'numeric', month: 'long', day: 'numeric', weekday: 'long' }
    },
    th: {
      short: { year: 'numeric', month: 'short', day: 'numeric' },
      long: { year: 'numeric', month: 'long', day: 'numeric', weekday: 'long' }
    }
  },
  numberFormats: {
    en: { currency: { style: 'currency', currency: 'USD' } },
    'zh-Hant': { currency: { style: 'currency', currency: 'HKD' } },
    'zh-Hans': { currency: { style: 'currency', currency: 'CNY' } },
    'zh': { currency: { style: 'currency', currency: 'CNY' } },      // Legacy alias
    'zh-CN': { currency: { style: 'currency', currency: 'CNY' } },   // Legacy alias
    'zh-HK': { currency: { style: 'currency', currency: 'HKD' } },   // Legacy alias
    ja: { currency: { style: 'currency', currency: 'JPY' } },
    ko: { currency: { style: 'currency', currency: 'KRW' } },
    es: { currency: { style: 'currency', currency: 'EUR' } },
    fr: { currency: { style: 'currency', currency: 'EUR' } },
    ru: { currency: { style: 'currency', currency: 'RUB' } },
    ar: { currency: { style: 'currency', currency: 'AED' } },
    th: { currency: { style: 'currency', currency: 'THB' } }
  }
})

export default i18n

// Helper function to normalize legacy locale codes
function normalizeLocale(locale: string): string {
  const localeMap: Record<string, string> = {
    'zh': 'zh-Hans',      // Generic Chinese → Simplified
    'zh-CN': 'zh-Hans',   // Mainland Chinese → Simplified
    'zh-HK': 'zh-Hant',   // Hong Kong Chinese → Traditional
    'zh-TW': 'zh-Hant',   // Taiwan Chinese → Traditional
    'zh-SG': 'zh-Hans',   // Singapore Chinese → Simplified
  }
  return localeMap[locale] || locale
}

// Helper function to change locale
export function setLocale(locale: string) {
  // Normalize legacy locale codes
  const normalizedLocale = normalizeLocale(locale)
  
  // Type assertion needed because normalizedLocale can include legacy codes
  i18n.global.locale.value = normalizedLocale as any
  localStorage.setItem('userLocale', normalizedLocale)
  
  // Set document direction for RTL languages
  if (normalizedLocale === 'ar') {
    document.documentElement.setAttribute('dir', 'rtl')
    document.documentElement.setAttribute('lang', normalizedLocale)
  } else {
    document.documentElement.setAttribute('dir', 'ltr')
    document.documentElement.setAttribute('lang', normalizedLocale)
  }
}

// Initialize direction on load
const currentLocale = i18n.global.locale.value
if (currentLocale === 'ar') {
  document.documentElement.setAttribute('dir', 'rtl')
} else {
  document.documentElement.setAttribute('dir', 'ltr')
}
document.documentElement.setAttribute('lang', currentLocale)

