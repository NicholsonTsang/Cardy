import { watch, onMounted } from 'vue'
import { useI18n } from 'vue-i18n'
import { useRoute } from 'vue-router'

interface SEOConfig {
  title?: string
  description?: string
  keywords?: string
  image?: string
  url?: string
  type?: string
  locale?: string
}

// Supported languages for SEO
const SUPPORTED_LANGUAGES = ['en', 'zh-Hant', 'zh-Hans', 'ja', 'ko', 'es', 'fr', 'ru', 'ar', 'th'] as const
type SupportedLanguage = typeof SUPPORTED_LANGUAGES[number]

// Language to OpenGraph locale mapping
const ogLocaleMap: Record<SupportedLanguage, string> = {
  'en': 'en_US',
  'zh-Hant': 'zh_TW',
  'zh-Hans': 'zh_CN',
  'ja': 'ja_JP',
  'ko': 'ko_KR',
  'es': 'es_ES',
  'fr': 'fr_FR',
  'ru': 'ru_RU',
  'ar': 'ar_SA',
  'th': 'th_TH'
}

// Language to ISO 639-1/BCP 47 code mapping for hreflang
const hreflangMap: Record<SupportedLanguage, string> = {
  'en': 'en',
  'zh-Hant': 'zh-Hant',
  'zh-Hans': 'zh-Hans',
  'ja': 'ja',
  'ko': 'ko',
  'es': 'es',
  'fr': 'fr',
  'ru': 'ru',
  'ar': 'ar',
  'th': 'th'
}

// Language to HTML lang attribute mapping
const htmlLangMap: Record<SupportedLanguage, string> = {
  'en': 'en',
  'zh-Hant': 'zh-Hant',
  'zh-Hans': 'zh-Hans',
  'ja': 'ja',
  'ko': 'ko',
  'es': 'es',
  'fr': 'fr',
  'ru': 'ru',
  'ar': 'ar',
  'th': 'th'
}

// Language names in their native language (for structured data)
const languageNames: Record<SupportedLanguage, string> = {
  'en': 'English',
  'zh-Hant': '繁體中文',
  'zh-Hans': '简体中文',
  'ja': '日本語',
  'ko': '한국어',
  'es': 'Español',
  'fr': 'Français',
  'ru': 'Русский',
  'ar': 'العربية',
  'th': 'ภาษาไทย'
}

export function useSEO() {
  const { t, tm, locale } = useI18n()
  const route = useRoute()

  const baseUrl = import.meta.env.VITE_APP_URL || 'https://funtell.ai'

  // Update HTML lang attribute and direction
  const updateHtmlLang = (lang: string) => {
    const htmlLang = htmlLangMap[lang as SupportedLanguage] || lang
    document.documentElement.lang = htmlLang
    
    // Set direction for RTL languages
    if (lang === 'ar') {
      document.documentElement.setAttribute('dir', 'rtl')
    } else {
      document.documentElement.setAttribute('dir', 'ltr')
    }
  }

  // Set or update a meta tag
  const setMetaTag = (name: string, content: string, property = false) => {
    if (!content) return
    
    const attribute = property ? 'property' : 'name'
    let meta = document.querySelector(`meta[${attribute}="${name}"]`)
    
    if (!meta) {
      meta = document.createElement('meta')
      meta.setAttribute(attribute, name)
      document.head.appendChild(meta)
    }
    
    meta.setAttribute('content', content)
  }

  // Remove a meta tag
  const removeMetaTag = (name: string, property = false) => {
    const attribute = property ? 'property' : 'name'
    const meta = document.querySelector(`meta[${attribute}="${name}"]`)
    if (meta) meta.remove()
  }

  // Set or update a link tag
  const setLinkTag = (rel: string, href: string, hreflang?: string) => {
    const selector = hreflang 
      ? `link[rel="${rel}"][hreflang="${hreflang}"]`
      : `link[rel="${rel}"]:not([hreflang])`
    
    let link = document.querySelector(selector)
    
    if (!link) {
      link = document.createElement('link')
      link.setAttribute('rel', rel)
      if (hreflang) link.setAttribute('hreflang', hreflang)
      document.head.appendChild(link)
    }
    
    link.setAttribute('href', href)
  }

  // Remove existing hreflang tags
  const removeHrefLangTags = () => {
    document.querySelectorAll('link[rel="alternate"][hreflang]').forEach(el => el.remove())
  }

  // Remove existing og:locale:alternate tags
  const removeOgLocaleAlternates = () => {
    document.querySelectorAll('meta[property^="og:locale:alternate"]').forEach(el => el.remove())
  }

  // Add hreflang tags for all languages
  const addHrefLangTags = (currentPath: string) => {
    removeHrefLangTags()
    
    // Clean path (remove any existing lang parameter)
    const cleanPath = currentPath.split('?')[0]
    const existingParams = new URLSearchParams(currentPath.split('?')[1] || '')
    existingParams.delete('lang')
    const paramString = existingParams.toString()
    const basePathWithParams = cleanPath + (paramString ? `?${paramString}` : '')
    
    // Add hreflang for each supported language
    SUPPORTED_LANGUAGES.forEach(lang => {
      const separator = basePathWithParams.includes('?') ? '&' : '?'
      const url = `${baseUrl}${basePathWithParams}${separator}lang=${lang}`
      setLinkTag('alternate', url, hreflangMap[lang])
    })
    
    // Add x-default pointing to English version
    const xDefaultUrl = `${baseUrl}${cleanPath}`
    setLinkTag('alternate', xDefaultUrl, 'x-default')
  }

  // Add og:locale:alternate for all other languages
  const addOgLocaleAlternates = (currentLocale: string) => {
    removeOgLocaleAlternates()
    
    SUPPORTED_LANGUAGES.forEach(lang => {
      if (lang !== currentLocale) {
        setMetaTag(`og:locale:alternate`, ogLocaleMap[lang], true)
      }
    })
  }

  // Update all SEO tags
  const updateSEO = (config?: SEOConfig) => {
    const currentLocale = locale.value as SupportedLanguage
    const ogLocale = ogLocaleMap[currentLocale] || 'en_US'
    
    // Get SEO content from i18n or use config
    const title = config?.title || t('seo.title', 'FunTell - Turn Any Information into an AI-Powered Content Experience')
    const description = config?.description || t('seo.description', 'Create AI-powered, multilingual content experiences for products, education, storytelling, and more. Share via QR code - no app required.')
    const keywords = config?.keywords || t('seo.keywords', '')
    const image = config?.image || `${baseUrl}/logo.png`
    const currentUrl = config?.url || `${baseUrl}${route.path}`
    const type = config?.type || 'website'

    // Update document title
    document.title = title

    // Update HTML lang attribute
    updateHtmlLang(currentLocale)

    // Primary Meta Tags
    setMetaTag('title', title)
    setMetaTag('description', description)
    if (keywords) setMetaTag('keywords', keywords)
    setMetaTag('language', t('seo.language', 'English'))
    setMetaTag('author', 'FunTell')
    setMetaTag('robots', 'index, follow')

    // Open Graph / Facebook
    setMetaTag('og:type', type, true)
    setMetaTag('og:url', currentUrl, true)
    setMetaTag('og:title', title, true)
    setMetaTag('og:description', description, true)
    setMetaTag('og:image', image, true)
    setMetaTag('og:image:width', '1200', true)
    setMetaTag('og:image:height', '630', true)
    setMetaTag('og:site_name', 'FunTell', true)
    setMetaTag('og:locale', ogLocale, true)

    // Add alternate locales for Open Graph
    addOgLocaleAlternates(currentLocale)

    // Twitter Card
    setMetaTag('twitter:card', 'summary_large_image')
    setMetaTag('twitter:url', currentUrl)
    setMetaTag('twitter:title', title)
    setMetaTag('twitter:description', description)
    setMetaTag('twitter:image', image)
    setMetaTag('twitter:site', '@funtell_ai')

    // Canonical URL (without language parameter for default)
    const canonicalUrl = currentLocale === 'en' ? `${baseUrl}${route.path}` : currentUrl
    setLinkTag('canonical', canonicalUrl)

    // hreflang tags for international targeting
    addHrefLangTags(route.fullPath)

    // Update JSON-LD structured data
    updateStructuredData(currentLocale)
  }

  // Update structured data based on locale
  const updateStructuredData = (lang: SupportedLanguage) => {
    // Remove existing structured data
    document.querySelectorAll('script[type="application/ld+json"]').forEach(el => el.remove())
    
    // Get features array safely
    const features = tm('seo.features') as any
    const featuresArray = Array.isArray(features) ? features : [
      "AI voice conversations",
      "Multi-language support in 10+ languages",
      "QR code instant access",
      "No app download required"
    ]

    // Organization structured data
    const organizationData = {
      "@context": "https://schema.org",
      "@type": "Organization",
      "name": "FunTell",
      "url": baseUrl,
      "logo": `${baseUrl}/logo.png`,
      "sameAs": [],
      "contactPoint": {
        "@type": "ContactPoint",
        "contactType": "customer service",
        "availableLanguage": SUPPORTED_LANGUAGES.map(l => languageNames[l])
      }
    }

    // Software Application structured data
    const softwareData = {
      "@context": "https://schema.org",
      "@type": "SoftwareApplication",
      "name": "FunTell",
      "applicationCategory": "BusinessApplication",
      "description": t('seo.structured_description', 'AI-powered platform that turns any information into multilingual, interactive content experiences shared via QR codes'),
      "inLanguage": hreflangMap[lang],
      "operatingSystem": "Web",
      "offers": {
        "@type": "AggregateOffer",
        "lowPrice": "0",
        "highPrice": "50",
        "priceCurrency": "USD",
        "offerCount": "2",
        "offers": [
          {
            "@type": "Offer",
            "name": "Free Tier",
            "price": "0",
            "priceCurrency": "USD",
            "description": "Up to 3 projects, 50 monthly access"
          },
          {
            "@type": "Offer",
            "name": "Premium",
            "price": "50",
            "priceCurrency": "USD",
            "priceSpecification": {
              "@type": "UnitPriceSpecification",
              "price": "50",
              "priceCurrency": "USD",
              "billingDuration": "P1M"
            },
            "description": "Up to 35 projects, session-based budget, unlimited translations"
          }
        ]
      },
      "featureList": featuresArray,
      "audience": {
        "@type": "Audience",
        "audienceType": t('seo.audience', 'Businesses, Educators, Creators, Product Teams, Storytellers')
      },
      "availableLanguage": SUPPORTED_LANGUAGES.map(l => ({
        "@type": "Language",
        "name": languageNames[l],
        "alternateName": l
      }))
    }

    // WebSite structured data with SearchAction
    const websiteData = {
      "@context": "https://schema.org",
      "@type": "WebSite",
      "name": "FunTell",
      "url": baseUrl,
      "inLanguage": SUPPORTED_LANGUAGES.map(l => hreflangMap[l]),
      "potentialAction": {
        "@type": "SearchAction",
        "target": {
          "@type": "EntryPoint",
          "urlTemplate": `${baseUrl}/search?q={search_term_string}`
        },
        "query-input": "required name=search_term_string"
      }
    }

    // BreadcrumbList for landing page
    const breadcrumbData = {
      "@context": "https://schema.org",
      "@type": "BreadcrumbList",
      "itemListElement": [
        {
          "@type": "ListItem",
          "position": 1,
          "name": "Home",
          "item": baseUrl
        }
      ]
    }

    // Create and append script elements
    const createScript = (data: object) => {
      const script = document.createElement('script')
      script.type = 'application/ld+json'
      script.textContent = JSON.stringify(data)
      document.head.appendChild(script)
    }

    createScript(organizationData)
    createScript(softwareData)
    createScript(websiteData)
    createScript(breadcrumbData)
  }

  // Watch for locale changes
  watch(locale, () => {
    updateSEO()
  })

  // Watch for route changes
  watch(() => route.fullPath, () => {
    updateSEO()
  })

  // Initialize on mount
  onMounted(() => {
    updateSEO()
  })

  return {
    updateSEO,
    updateHtmlLang,
    addHrefLangTags,
    SUPPORTED_LANGUAGES
  }
}
