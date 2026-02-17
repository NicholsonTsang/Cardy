import { supabase } from '@/lib/supabase'
import { useCreditStore } from '@/stores/credits'

/**
 * Create Stripe Checkout session for credit purchase and redirect to Stripe.
 * Backend returns the checkout URL directly - no need for Stripe.js on the client.
 */
export const createCreditPurchaseCheckout = async (creditAmount: number, metadata: Record<string, string> = {}) => {
  const { data: { session }, error: sessionError } = await supabase.auth.getSession()

  if (sessionError || !session) {
    throw new Error('Your session has expired. Please refresh the page and log in again.')
  }

  if (!creditAmount || creditAmount <= 0) {
    throw new Error('Invalid credit amount')
  }

  const baseUrl = import.meta.env.VITE_STRIPE_SUCCESS_URL || `${window.location.origin}/cms/credits`

  const response = await fetch(`${import.meta.env.VITE_BACKEND_URL}/api/payments/create-credit-checkout`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${session.access_token}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      creditAmount,
      amountUsd: creditAmount,
      baseUrl,
      metadata
    })
  })

  if (!response.ok) {
    const errorData = await response.json()
    throw new Error(errorData.message || errorData.error || 'Failed to create checkout session')
  }

  const data = await response.json()

  if (!data?.url) {
    throw new Error('No checkout URL returned from server')
  }

  // Redirect to Stripe-hosted checkout page directly
  window.location.href = data.url
}

/**
 * Handle successful credit purchase return from Stripe.
 * Credits are added automatically via webhook - this just refreshes the balance.
 */
export const handleCreditPurchaseSuccess = async (sessionId?: string) => {
  const creditStore = useCreditStore()
  await creditStore.fetchCreditBalance()

  return {
    success: true,
    message: 'Credit purchase processed successfully',
    sessionId
  }
}
