/**
 * useShare Composable
 *
 * Provides content sharing functionality using Web Share API with clipboard fallback.
 * Part of P0 mobile client features from Platform Optimization Roadmap.
 */

import { ref } from 'vue'
import { useToast } from 'primevue/usetoast'
import { useI18n } from 'vue-i18n'

export interface ShareData {
  title: string
  text: string
  url: string
}

export function useShare() {
  const toast = useToast()
  const { t } = useI18n()
  const isSharing = ref(false)

  /**
   * Truncate text to specified length with ellipsis
   */
  function truncate(text: string, maxLength: number): string {
    if (!text || text.length <= maxLength) return text
    return text.substring(0, maxLength) + '...'
  }

  /**
   * Check if Web Share API is supported
   */
  function isWebShareSupported(): boolean {
    return typeof navigator !== 'undefined' && 'share' in navigator
  }

  /**
   * Share content using Web Share API or clipboard fallback
   */
  async function share(data: ShareData): Promise<boolean> {
    if (isSharing.value) return false

    isSharing.value = true

    try {
      if (isWebShareSupported()) {
        // Use native Web Share API
        await navigator.share(data)

        toast.add({
          severity: 'success',
          summary: t('mobile.shareSuccess'),
          detail: t('mobile.shareSuccessDetail'),
          life: 3000
        })

        // Track sharing event (if analytics is available)
        if (typeof window !== 'undefined' && (window as any).trackEvent) {
          (window as any).trackEvent('content_shared', { method: 'native' })
        }

        return true
      } else {
        // Fallback to clipboard
        await navigator.clipboard.writeText(data.url)

        toast.add({
          severity: 'success',
          summary: t('mobile.linkCopied'),
          detail: t('mobile.linkCopiedDetail'),
          life: 3000
        })

        // Track sharing event
        if (typeof window !== 'undefined' && (window as any).trackEvent) {
          (window as any).trackEvent('content_shared', { method: 'clipboard' })
        }

        return true
      }
    } catch (error: any) {
      // User cancelled or error occurred
      if (error.name !== 'AbortError') {
        console.error('Share failed:', error)

        toast.add({
          severity: 'error',
          summary: t('mobile.shareFailed'),
          detail: error.message || t('mobile.shareFailedDetail'),
          life: 5000
        })
      }

      return false
    } finally {
      isSharing.value = false
    }
  }

  /**
   * Build share data for a content item
   */
  function buildContentShareData(
    cardId: string,
    itemId: string,
    itemName: string,
    itemContent: string | null,
    language: string
  ): ShareData {
    const baseUrl = window.location.origin
    const url = `${baseUrl}/${language}/c/${cardId}/item/${itemId}`

    return {
      title: itemName,
      text: truncate(itemContent || itemName, 120),
      url
    }
  }

  /**
   * Build share data for a card
   */
  function buildCardShareData(
    cardId: string,
    cardName: string,
    cardDescription: string,
    language: string
  ): ShareData {
    const baseUrl = window.location.origin
    const url = `${baseUrl}/${language}/c/${cardId}`

    return {
      title: cardName,
      text: truncate(cardDescription || cardName, 120),
      url
    }
  }

  return {
    isSharing,
    isWebShareSupported: isWebShareSupported(),
    share,
    buildContentShareData,
    buildCardShareData,
    truncate
  }
}
