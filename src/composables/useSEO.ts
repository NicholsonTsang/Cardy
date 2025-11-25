import { watch } from 'vue'
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

// Language to locale mapping for Open Graph
const localeMap: Record<string, string> = {
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

// Language to ISO code mapping
const isoLangMap: Record<string, string> = {
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

export function useSEO() {
  const { t, locale } = useI18n()
  const route = useRoute()

  const baseUrl = import.meta.env.VITE_APP_URL || 'https://cardstudio.org'

  // Update HTML lang attribute
  const updateHtmlLang = (lang: string) => {
    document.documentElement.lang = isoLangMap[lang] || lang
  }

  // Set or update a meta tag
  const setMetaTag = (name: string, content: string, property = false) => {
    const attribute = property ? 'property' : 'name'
    let meta = document.querySelector(`meta[${attribute}="${name}"]`)
    
    if (!meta) {
      meta = document.createElement('meta')
      meta.setAttribute(attribute, name)
      document.head.appendChild(meta)
    }
    
    meta.setAttribute('content', content)
  }

  // Set or update a link tag
  const setLinkTag = (rel: string, href: string, hreflang?: string) => {
    const selector = hreflang 
      ? `link[rel="${rel}"][hreflang="${hreflang}"]`
      : `link[rel="${rel}"]`
    
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

  // Add hreflang tags for all languages
  const addHrefLangTags = (currentPath: string) => {
    removeHrefLangTags()
    
    // Add hreflang for each supported language
    Object.keys(isoLangMap).forEach(lang => {
      const url = `${baseUrl}${currentPath}${currentPath.includes('?') ? '&' : '?'}lang=${lang}`
      setLinkTag('alternate', url, isoLangMap[lang])
    })
    
    // Add x-default for default language
    const defaultUrl = `${baseUrl}${currentPath}`
    setLinkTag('alternate', defaultUrl, 'x-default')
  }

  // Update all SEO tags
  const updateSEO = (config?: SEOConfig) => {
    const currentLocale = locale.value
    const ogLocale = localeMap[currentLocale] || 'en_US'
    
    // Get SEO content from i18n or use config
    const title = config?.title || t('seo.title')
    const description = config?.description || t('seo.description')
    const keywords = config?.keywords || t('seo.keywords')
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
    setMetaTag('keywords', keywords)
    setMetaTag('language', t('seo.language'))

    // Open Graph / Facebook
    setMetaTag('og:type', type, true)
    setMetaTag('og:url', currentUrl, true)
    setMetaTag('og:title', title, true)
    setMetaTag('og:description', description, true)
    setMetaTag('og:image', image, true)
    setMetaTag('og:site_name', 'CardStudio', true)
    setMetaTag('og:locale', ogLocale, true)

    // Add alternate locales
    Object.entries(localeMap).forEach(([lang, ogLoc]) => {
      if (lang !== currentLocale) {
        const altMetaName = `og:locale:alternate-${lang}`
        setMetaTag(altMetaName, ogLoc, true)
      }
    })

    // Twitter Card
    setMetaTag('twitter:card', 'summary_large_image')
    setMetaTag('twitter:url', currentUrl)
    setMetaTag('twitter:title', title)
    setMetaTag('twitter:description', description)
    setMetaTag('twitter:image', image)

    // Canonical URL
    setLinkTag('canonical', currentUrl)

    // hreflang tags
    addHrefLangTags(route.path)

    // Update JSON-LD structured data
    updateStructuredData(currentLocale)
  }

  // Update structured data based on locale
  const updateStructuredData = (lang: string) => {
    const existingScript = document.querySelector('script[type="application/ld+json"]')
    
    const structuredData = {
      "@context": "https://schema.org",
      "@type": "SoftwareApplication",
      "name": "CardStudio",
      "applicationCategory": "BusinessApplication",
      "description": t('seo.structured_description'),
      "inLanguage": isoLangMap[lang],
      "operatingSystem": "Web",
      "offers": {
        "@type": "Offer",
        "price": "2.00",
        "priceCurrency": "USD",
        "priceSpecification": {
          "@type": "UnitPriceSpecification",
          "price": "2.00",
          "priceCurrency": "USD",
          "referenceQuantity": {
            "@type": "QuantitativeValue",
            "value": "1",
            "unitText": "card"
          }
        }
      },
      "featureList": t('seo.features', { returnObjects: true }),
      "audience": {
        "@type": "Audience",
        "audienceType": t('seo.audience')
      }
    }

    if (existingScript) {
      existingScript.textContent = JSON.stringify(structuredData, null, 2)
    } else {
      const script = document.createElement('script')
      script.type = 'application/ld+json'
      script.textContent = JSON.stringify(structuredData, null, 2)
      document.head.appendChild(script)
    }
  }

  // Watch for locale changes
  watch(locale, () => {
    updateSEO()
  })

  // Watch for route changes
  watch(() => route.path, () => {
    updateSEO()
  })

  return {
    updateSEO,
    updateHtmlLang,
    addHrefLangTags
  }
}

