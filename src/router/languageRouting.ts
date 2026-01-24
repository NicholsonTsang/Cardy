/**
 * Language Routing Configuration
 * Handles URL-based language routing with browser language detection
 */

import { SUPPORTED_LANGUAGES } from '@/stores/translation'
import type { LanguageCode } from '@/stores/translation'

// Supported URL language codes (must match SUPPORTED_LANGUAGES keys)
export const URL_SUPPORTED_LANGUAGES = Object.keys(SUPPORTED_LANGUAGES) as LanguageCode[]

// Default language for fallback
export const DEFAULT_LANGUAGE: LanguageCode = 'en'

// Dashboard-only languages (limited to EN and zh-Hant for creators)
export const DASHBOARD_LANGUAGES: LanguageCode[] = ['en', 'zh-Hant']

// Routes that should NOT have language prefix (static/utility routes)
export const LANGUAGE_EXCLUDED_ROUTES = [
  '/api',
  '/auth/callback',
  '/health',
]

/**
 * Normalize browser language code to our supported format
 * Maps variations like 'zh-CN', 'zh-TW', 'zh-HK' to our standard codes
 */
export function normalizeBrowserLanguage(browserLang: string): LanguageCode {
  const lang = browserLang.toLowerCase()
  
  const languageMap: Record<string, LanguageCode> = {
    // Chinese variants
    'zh': 'zh-Hans',
    'zh-cn': 'zh-Hans',
    'zh-sg': 'zh-Hans',
    'zh-tw': 'zh-Hant',
    'zh-hk': 'zh-Hant',
    'zh-mo': 'zh-Hant',
    // Direct mappings for supported languages
    'en': 'en',
    'en-us': 'en',
    'en-gb': 'en',
    'ja': 'ja',
    'ja-jp': 'ja',
    'ko': 'ko',
    'ko-kr': 'ko',
    'es': 'es',
    'es-es': 'es',
    'es-mx': 'es',
    'fr': 'fr',
    'fr-fr': 'fr',
    'fr-ca': 'fr',
    'ru': 'ru',
    'ru-ru': 'ru',
    'ar': 'ar',
    'ar-sa': 'ar',
    'ar-ae': 'ar',
    'th': 'th',
    'th-th': 'th',
  }
  
  // Check exact match first
  if (languageMap[lang]) {
    return languageMap[lang]
  }
  
  // Check base language (e.g., 'en-AU' -> 'en')
  const baseLang = lang.split('-')[0]
  if (URL_SUPPORTED_LANGUAGES.includes(baseLang as LanguageCode)) {
    return baseLang as LanguageCode
  }
  
  // Check if any supported language starts with the base
  const partialMatch = URL_SUPPORTED_LANGUAGES.find(
    supported => supported.toLowerCase().startsWith(baseLang)
  )
  if (partialMatch) {
    return partialMatch
  }
  
  return DEFAULT_LANGUAGE
}

/**
 * Detect the best language from browser preferences
 * @param availableLanguages - Optional subset of languages to match against
 * @returns The best matching language code
 */
export function detectBrowserLanguage(availableLanguages?: LanguageCode[]): LanguageCode {
  const targetLanguages = availableLanguages || URL_SUPPORTED_LANGUAGES
  const browserLanguages = navigator.languages || [navigator.language]
  
  console.log('🌐 Browser languages:', browserLanguages)
  
  for (const browserLang of browserLanguages) {
    const normalized = normalizeBrowserLanguage(browserLang)
    if (targetLanguages.includes(normalized)) {
      console.log('✅ Language match found:', normalized)
      return normalized
    }
  }
  
  console.log('ℹ️ No language match, defaulting to:', DEFAULT_LANGUAGE)
  return DEFAULT_LANGUAGE
}

/**
 * Check if a language code is valid
 * @param lang - The language code to validate
 * @param dashboardOnly - If true, only validate against dashboard languages
 */
export function isValidLanguage(lang: string | undefined, dashboardOnly = false): lang is LanguageCode {
  if (!lang) return false
  const validLanguages = dashboardOnly ? DASHBOARD_LANGUAGES : URL_SUPPORTED_LANGUAGES
  return validLanguages.includes(lang as LanguageCode)
}

/**
 * Extract language from URL path
 * @param path - The URL path (e.g., '/en/cms/projects')
 * @returns The language code if found and valid, undefined otherwise
 */
export function extractLanguageFromPath(path: string): LanguageCode | undefined {
  const segments = path.split('/').filter(Boolean)
  if (segments.length === 0) return undefined
  
  const firstSegment = segments[0]
  if (isValidLanguage(firstSegment)) {
    return firstSegment
  }
  
  return undefined
}

/**
 * Remove language prefix from path
 * @param path - The URL path (e.g., '/en/cms/projects')
 * @returns The path without language prefix (e.g., '/cms/projects')
 */
export function removeLanguageFromPath(path: string): string {
  const lang = extractLanguageFromPath(path)
  if (!lang) return path
  
  const segments = path.split('/').filter(Boolean)
  segments.shift() // Remove the language segment
  return '/' + segments.join('/')
}

/**
 * Add language prefix to path
 * @param path - The URL path (e.g., '/cms/projects')
 * @param lang - The language code
 * @returns The path with language prefix (e.g., '/en/cms/projects')
 */
export function addLanguageToPath(path: string, lang: LanguageCode): string {
  // Don't add language to excluded routes
  for (const excluded of LANGUAGE_EXCLUDED_ROUTES) {
    if (path.startsWith(excluded)) {
      return path
    }
  }
  
  // Don't double-add language
  const existingLang = extractLanguageFromPath(path)
  if (existingLang) {
    if (existingLang === lang) return path
    // Replace existing language
    return '/' + lang + removeLanguageFromPath(path)
  }
  
  return '/' + lang + path
}

/**
 * Build a full URL with language for mobile client public card view
 * @param accessToken - The card access token
 * @param lang - The language code
 * @returns Full URL with language (e.g., 'https://example.com/en/c/abc123')
 */
export function buildCardUrl(accessToken: string, lang: LanguageCode): string {
  return `${window.location.origin}/${lang}/c/${accessToken}`
}

/**
 * Get saved language preference from localStorage
 * Falls back to browser detection if no saved preference
 * @param dashboardOnly - If true, only return dashboard languages
 */
export function getSavedLanguage(dashboardOnly = false): LanguageCode {
  const savedLocale = localStorage.getItem('userLocale')
  if (savedLocale && isValidLanguage(savedLocale, dashboardOnly)) {
    return savedLocale as LanguageCode
  }
  
  const detected = detectBrowserLanguage(dashboardOnly ? DASHBOARD_LANGUAGES : undefined)
  return detected
}

/**
 * Save language preference to localStorage
 */
export function saveLanguagePreference(lang: LanguageCode): void {
  localStorage.setItem('userLocale', lang)
}

