import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { useAuthStore } from './auth'

const backendUrl = import.meta.env.VITE_BACKEND_URL || 'http://localhost:8080'

export const useVoiceCreditStore = defineStore('voiceCredits', () => {
  const authStore = useAuthStore()

  // State
  const balance = ref(0)
  const loading = ref(false)
  const error = ref<string | null>(null)

  // Computed
  const hasCredits = computed(() => balance.value > 0)

  // Config from env
  const packageSize = parseInt(import.meta.env.VITE_VOICE_CREDIT_PACKAGE_SIZE || '35')
  const packagePriceUsd = parseFloat(import.meta.env.VITE_VOICE_CREDIT_PACKAGE_PRICE_USD || '5')

  // Fetch voice credit balance from backend
  async function fetchBalance() {
    if (!authStore.session?.access_token) return

    loading.value = true
    error.value = null
    try {
      const response = await fetch(`${backendUrl}/api/subscriptions/voice-credits`, {
        headers: {
          'Authorization': `Bearer ${authStore.session.access_token}`
        }
      })

      if (!response.ok) {
        throw new Error('Failed to fetch voice credit balance')
      }

      const data = await response.json()
      balance.value = data.balance || 0
    } catch (err: any) {
      error.value = err.message
      console.error('Error fetching voice credit balance:', err)
    } finally {
      loading.value = false
    }
  }

  // Purchase voice credits using credit balance (instant deduction)
  // quantity = number of packages (1 package = packageSize voice credits at packagePriceUsd each)
  async function purchaseCredits(quantity: number = 1): Promise<boolean> {
    if (!authStore.session?.access_token) {
      error.value = 'Authentication required'
      return false
    }

    loading.value = true
    error.value = null
    try {
      const response = await fetch(`${backendUrl}/api/payments/purchase-voice-credits`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${authStore.session.access_token}`
        },
        body: JSON.stringify({ quantity })
      })

      if (!response.ok) {
        const errData = await response.json().catch(() => ({}))
        throw new Error(errData.message || 'Failed to purchase voice credits')
      }

      const data = await response.json()
      if (data.success) {
        balance.value = data.voice_balance_after ?? balance.value
      } else {
        throw new Error(data.error || 'Insufficient credits')
      }
      return true
    } catch (err: any) {
      error.value = err.message
      console.error('Error purchasing voice credits:', err)
      return false
    } finally {
      loading.value = false
    }
  }

  // Clear store
  function clearStore() {
    balance.value = 0
    error.value = null
  }

  return {
    // State
    balance,
    loading,
    error,

    // Computed
    hasCredits,

    // Config
    packageSize,
    packagePriceUsd,

    // Actions
    fetchBalance,
    purchaseCredits,
    clearStore
  }
})
