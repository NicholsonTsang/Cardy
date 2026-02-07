import { computed } from 'vue'

/**
 * Composable for managing physical card feature visibility.
 *
 * When VITE_ENABLE_PHYSICAL_CARDS is set to 'false', all physical card
 * related features will be hidden throughout the application:
 * - Landing page: physical card demo mode, physical card pricing
 * - Admin dashboard: batch management, print requests, physical card stats
 * - Card creation: physical card option in access mode selector
 * - Card detail: issuance tab
 */
export function usePhysicalCards() {
  /**
   * Whether physical card features are enabled.
   * Defaults to true if not specified (backward compatible).
   */
  const isPhysicalCardsEnabled = computed(() => {
    const envValue = import.meta.env.VITE_ENABLE_PHYSICAL_CARDS
    // Default to true if not set, only disable when explicitly set to 'false'
    return envValue !== 'false'
  })

  /**
   * Check if a specific card is a physical card based on billing_type.
   */
  const isPhysicalCard = (billingType: string | undefined | null) => {
    return billingType === 'physical'
  }

  /**
   * Get the default billing type based on feature flag.
   * Returns 'digital' when physical cards are disabled.
   */
  const getDefaultBillingType = computed(() => {
    return isPhysicalCardsEnabled.value ? 'physical' : 'digital'
  })

  return {
    isPhysicalCardsEnabled,
    isPhysicalCard,
    getDefaultBillingType
  }
}
