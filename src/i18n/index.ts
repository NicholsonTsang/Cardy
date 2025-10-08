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

// Get saved locale from localStorage or default to English
const savedLocale = localStorage.getItem('userLocale') || 'en'

const i18n = createI18n({
  legacy: false, // Use Composition API mode
  locale: savedLocale,
  fallbackLocale: 'en',
  messages: {
    en,
    'zh-Hant': zhHant,
    'zh-Hans': zhHans,
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

// Helper function to change locale
export function setLocale(locale: string) {
  i18n.global.locale.value = locale
  localStorage.setItem('userLocale', locale)
  
  // Set document direction for RTL languages
  if (locale === 'ar') {
    document.documentElement.setAttribute('dir', 'rtl')
    document.documentElement.setAttribute('lang', locale)
  } else {
    document.documentElement.setAttribute('dir', 'ltr')
    document.documentElement.setAttribute('lang', locale)
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

